/// Gerçek zamanlı kanalın depolama düzeni: koltuk başına küçük belge halkası.
///
/// Eskiden her anlık durum / girdi yeni bir belgeydi ve hiç silinmiyordu
/// (masa başına saniyede ~15-27 yeni belge, sınırsız depolama). Şimdi:
///
///   matches/{id}/live/{koltuk}_{yuva}   yuva = 0..[kLiveRing]-1
///
/// Her koltuk kendi halkasındaki yuvaların sırayla üzerine yazar; böylece bir
/// maçta en çok `koltuk × kLiveRing` belge olur ve tek belgeye saniyede ~1
/// yazma düşer (Firestore'un belge başına sürekli yazma sınırı). Her belgede
/// artan `seq` vardır; okuyan her koltuk için yalnızca daha yeni `seq`'i
/// iletir. Ara yazmalar okunmadan ezilebilir: `core/net_sync.dart`
/// protokolünde her mesaj öncekini kapsadığı için bu güvenlidir.
///
/// Temizlik: her belgede `expireAt` (yazma anı + [kLiveTtl]) vardır;
/// Firestore TTL ilkesi (firebase/firestore.indexes.json → fieldOverrides,
/// `live.expireAt`, ttl: true; `firebase deploy --only firestore:indexes`
/// ile kurulur, elle: `gcloud firestore fields ttls update expireAt
/// --collection-group=live --enable-ttl`) terk edilmiş maçları siler
/// (Firestore süresi dolan belgeyi genelde 24 saat içinde siler). Maç bitince
/// istemci halkayı ayrıca kendisi siler.
library;

import 'dart:math' as math;

/// Koltuk başına halka uzunluğu (10 Hz'de belge başına ~1 yazma/sn).
const kLiveRing = 10;

/// Canlı belgelerin ömrü; her yazmada yenilenir.
const kLiveTtl = Duration(hours: 1);

/// Bir canlı belge.
class LiveDoc {
  final int seat;
  final int seq;
  final String data;
  final String by;
  final DateTime expireAt;
  const LiveDoc(this.seat, this.seq, this.data, this.by, this.expireAt);

  /// Belge kimliği: `{koltuk}_{yuva}`.
  static String idOf(int seat, int slot) => '${seat}_$slot';

  Map<String, Object> toMap() => {'seat': seat, 'seq': seq, 'd': data, 'by': by};

  /// Belge verisinden oku; bozuksa null.
  static LiveDoc? parse(Map<String, dynamic>? x, {DateTime? expireAt}) {
    if (x == null) return null;
    final seat = x['seat'], seq = x['seq'], d = x['d'], by = x['by'];
    if (seat is! num || seq is! num || d is! String || by is! String) return null;
    return LiveDoc(seat.toInt(), seq.toInt(), d, by, expireAt ?? DateTime.fromMillisecondsSinceEpoch(0));
  }
}

/// Yazan taraf: yuva ve sıra numarası verir.
class LiveWriter {
  final int ring;
  final Duration ttl;
  final Map<int, int> _next = {};
  int _seq = 0;

  LiveWriter({this.ring = kLiveRing, this.ttl = kLiveTtl});

  /// Bu yazıcıyla en az bir yazma yapıldı mı.
  bool get used => _next.isNotEmpty;

  /// Bu cihazın daha önce yazdığı en büyük sıra numarasını bildir
  /// (geri dönüşte halkadan okununca); sonraki yazmalar bunun üstünden sürer.
  void saw(int seq) => _seq = math.max(_seq, seq);

  /// Sıradaki yazma: (belge kimliği, belge). Sıra numarası duvar saatine
  /// dayanır, böylece uygulama yeniden açılsa da eski yazmaların üstünde kalır.
  (String, LiveDoc) next(int seat, String data, String by, DateTime now) {
    final slot = _next[seat] ?? 0;
    _next[seat] = (slot + 1) % ring;
    _seq = math.max(_seq + 1, now.millisecondsSinceEpoch);
    return (LiveDoc.idOf(seat, slot), LiveDoc(seat, _seq, data, by, now.add(ttl)));
  }
}

/// Okuyan taraf: belge değişikliklerinden iletilecek mesajları seçer.
///
/// İlk partide (dinlemeye başlayınca) halkadaki her şey, bu cihazın eski
/// mesajları dahil, sıra numarasına göre bir kez verilir (geri dönüş).
/// Sonra yalnızca diğer cihazların mesajları gelir. Bir koltuk için
/// görülenden eski ya da aynı sıra numaralı belge (geç gelen, tekrar) atlanır.
class LiveReader {
  final String me;
  final LiveWriter? writer;
  final Map<int, int> _last = {};
  bool _first = true;

  LiveReader(this.me, {this.writer});

  List<(int, String)> take(Iterable<LiveDoc> changed) {
    final docs = changed.toList()..sort((a, b) => a.seq.compareTo(b.seq));
    final out = <(int, String)>[];
    for (final d in docs) {
      final mine = d.by == me;
      if (mine) writer?.saw(d.seq);
      if (mine && !_first) continue;
      if (d.seq <= (_last[d.seat] ?? -1)) continue;
      _last[d.seat] = d.seq;
      out.add((d.seat, d.data));
    }
    _first = false;
    return out;
  }
}
