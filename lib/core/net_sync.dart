/// Gerçek zamanlı çevrimiçi oyunlar için eşitleme: yetkili ev sahibi.
///
/// Ev sahibi (maçı kuran koltuk) oyunu kendi cihazında yürütür ve yalnızca
/// durum değişince, en çok saniyede 10 kez anlık durum ("S") yayınlar. Diğer oyuncular yalnızca girdi
/// ("I") gönderir: sürekli girdi (parmak konumu gibi) ve sıra numaralı
/// eylemler (kart oyna, "Yakala!" ...). Eylemler ev sahibinin anlık
/// durumunda onaylanana kadar her girdi mesajında yeniden gönderilir; böylece
/// kanal sırasız ya da kayıplı olsa da her eylem bir kez ve sırayla işlenir.
///
/// Kopma:
///  * Bir misafirden 2,5 sn girdi gelmezse ev sahibi o koltuğu yapay zekâya
///    verir; girdi yeniden gelince kontrol oyuncuya döner.
///  * Ev sahibinden 3 sn anlık durum gelmezse, ayakta kalan en küçük
///    koltuktaki misafir son anlık durumdan oyunu devralır ("dönem" bir
///    artar). Eski ev sahibi dönerse daha yüksek dönemi görüp misafir olur.
///
/// Geri dönüş: kanal dinlenmeye başlanınca son birkaç mesajı (kendi
/// gönderdiklerimiz dahil) bir kez verir. Uygulaması kapanıp açılan ev
/// sahibi kendi son anlık durumundan devam eder ([takeResume]).
///
/// Her mesaj kendinden öncekini kapsar (anlık durum tam durumdur; girdi
/// mesajı onaylanmamış bütün eylemleri taşır). Bu yüzden aktarım ara
/// mesajları atlayabilir: Firestore'da her koltuk birkaç belgelik bir halkanın
/// üzerine yazar (`online/live_ring.dart`), okuyan yalnızca son hâli görebilir.
///
/// Bu dosya saf Dart'tır; aktarım [send] ve [receive] ile dışarıdan bağlanır.
library;

import 'dart:math' as math;

/// Ev sahibinin anlık durumu.
class NetSnap {
  /// Yetki dönemi (devralmada bir artar).
  final int ep;

  /// Anlık durumu üreten koltuk.
  final int host;

  /// Ev sahibinin oyun saati (ms).
  final int t;

  /// Koltuk → işlenen eylem sayısı.
  final Map<int, int> acks;

  /// Şu an yapay zekânın oynadığı koltuklar (bit maskesi).
  final int bots;

  /// Oyunun kendi durumu ('|' içermez).
  final String payload;

  /// Bu cihazda alındığı an (ms).
  final int at;

  const NetSnap(this.ep, this.host, this.t, this.acks, this.bots, this.payload, this.at);

  bool isBot(int seat) => seat >= 0 && seat < 31 && (bots >> seat) & 1 == 1;
}

/// Bir cihazın eşitleme durumu. Zaman değerleri ms cinsindendir ve çağıran
/// tarafın tek düze saatinden gelir (ör. `Stopwatch`).
class NetSync {
  final int mySeat;
  final int seats;

  /// İnsan oyuncuların koltukları (diğerleri bot).
  final Set<int> humans;
  final void Function(String data) send;

  /// Anlık durumlar arasında en az süre (10 Hz).
  final int snapGapMs;

  /// Girdi mesajları arasında en az süre (10 Hz).
  final int inputGapMs;

  /// Değişiklik olmasa da gönderme aralığı (canlılık).
  final int keepAliveMs;
  final int snapKeepAliveMs;

  /// Ev sahibinden bu kadar ses gelmezse devral.
  final int hostTimeoutMs;

  /// Misafirden bu kadar ses gelmezse koltuğu yapay zekâya ver.
  final int idleMs;

  /// Maç başında henüz hiç ses gelmemiş koltuklar için bekleme.
  final int graceMs;

  /// Ara kare gecikmesi: misafir ekranı ev sahibinin bu kadar gerisinden çizer.
  final int delayMs;
  final int startMs;

  int ep = 0;
  late int host;

  static const _never = -1000000000;

  NetSync({
    required this.mySeat,
    required this.seats,
    required Set<int> humans,
    required this.send,
    int firstHost = 0,
    this.snapGapMs = 100,
    this.inputGapMs = 100,
    this.keepAliveMs = 1000,
    this.snapKeepAliveMs = 1000,
    this.hostTimeoutMs = 3000,
    this.idleMs = 2500,
    this.graceMs = 8000,
    this.delayMs = 160,
    this.startMs = 0,
  }) : humans = {...humans, mySeat} {
    host = firstHost;
  }

  bool get isHost => host == mySeat;

  // ---- ortak -------------------------------------------------------------------

  final Map<int, int> _heard = {};

  /// Koltuktan en son mesaj alınan an.
  int? heardAt(int seat) => _heard[seat];

  bool _alive(int seat, int now, int timeout) {
    if (seat == mySeat) return true;
    if (!humans.contains(seat)) return false;
    final h = _heard[seat];
    if (h == null) return now - startMs < graceMs;
    return now - h < timeout;
  }

  /// Koltuğu şu an bir insan mı oynuyor (bağlı). Botlar ve kopanlar false.
  bool live(int seat, int now) => _alive(seat, now, idleMs);

  /// Gelen mesajı işle ([seat]: gönderen koltuk).
  void receive(int seat, String data, int now) {
    if (seat < 0 || seat >= seats) return;
    if (seat != mySeat) _heard[seat] = now;
    if (data.startsWith('S|')) {
      final s = _parseSnap(seat, data, now);
      if (s != null) _onSnap(s, now);
    } else if (data.startsWith('I|')) {
      if (seat != mySeat) _onInput(seat, data);
    }
  }

  // ---- ev sahibi -----------------------------------------------------------------

  /// Koltuk → işlenen eylem sayısı.
  final Map<int, int> _done = {};

  /// Koltuk → sıraya alınmış (henüz işlenmemiş) eylemler.
  final Map<int, List<String>> _inbox = {};

  /// Ev sahibinin kendi eylemleri (ve devralmada bekleyen eylemlerimiz).
  final List<String> _local = [];
  final Map<int, List<double>> _axes = {};
  int _lastPubAt = _never;
  int _lastPubT = -1;

  /// Koltuğun son sürekli girdisi (yoksa null).
  List<double>? axesOf(int seat) => seat == mySeat ? _myAxes : _axes[seat];

  /// Sıradaki eylemler (koltuk, eylem); ev sahibi bunları oyuna uygular.
  List<(int, String)> takeActions() {
    final out = <(int, String)>[];
    if (!isHost) return out;
    for (final a in _local) {
      out.add((mySeat, a));
    }
    _local.clear();
    final keys = _inbox.keys.toList()..sort();
    for (final s in keys) {
      final q = _inbox[s]!;
      for (final a in q) {
        out.add((s, a));
      }
      _done[s] = (_done[s] ?? 0) + q.length;
      q.clear();
    }
    return out;
  }

  void _onInput(int seat, String data) {
    final p = data.split('|');
    if (p.length != 4) return;
    final base = int.tryParse(p[1]);
    if (base == null || base < 0) return;
    final acts = p[2].isEmpty ? const <String>[] : p[2].split('~');
    final q = _inbox.putIfAbsent(seat, () => []);
    var next = (_done[seat] ?? 0) + q.length;
    for (var i = 0; i < acts.length; i++) {
      final idx = base + i;
      if (idx < next) continue; // daha önce alındı
      if (idx > next) break; // arada eksik var: yeniden gönderilecek
      q.add(acts[i]);
      next++;
    }
    _axes[seat] = decodeNums(p[3]);
  }

  /// Anlık durum yayınla (sıklık sınırıyla). [changed] false ise yalnızca
  /// canlılık aralığında gönderilir. Gönderildiyse true.
  bool publish(int t, String payload, int now, {bool changed = true, bool force = false}) {
    if (!isHost) return false;
    final due = now - _lastPubAt >= snapGapMs;
    final alive = now - _lastPubAt >= snapKeepAliveMs;
    if (!force && !((due && changed) || alive)) return false;
    var bots = 0;
    for (var s = 0; s < seats && s < 31; s++) {
      if (!live(s, now)) bots |= 1 << s;
    }
    final acks = [for (final e in _done.entries) '${e.key}:${e.value}'].join(',');
    send('S|$ep|$t|$acks|$bots|$payload');
    _lastPubAt = now;
    _lastPubT = t;
    return true;
  }

  // ---- misafir --------------------------------------------------------------------

  final List<String> _pending = [];
  int _ackBase = 0;
  List<double> _myAxes = const [];
  String _sentAxes = '';
  int _lastInAt = _never;
  final List<NetSnap> _buf = [];
  NetSnap? _latest;
  int? _lastSnapAt;
  double? _offset;
  NetSnap? _resume;
  bool _demoted = false;

  /// Bu cihazın eylemi: ev sahibiysek hemen sıraya, değilse gönderilir.
  void act(String a) {
    if (isHost) {
      _local.add(a);
    } else {
      _pending.add(a);
    }
  }

  /// Onay bekleyen eylem sayısı.
  int get pending => _pending.length;

  /// Sürekli girdi (ör. [basılı, x, y, dokunma sayısı, ...]).
  void setAxes(List<double> v) => _myAxes = v;

  /// Misafir: gerekiyorsa girdi mesajı gönder.
  void pump(int now) {
    if (isHost) return;
    final axes = encodeNums(_myAxes);
    final want = _pending.isNotEmpty || axes != _sentAxes;
    if (!(want && now - _lastInAt >= inputGapMs) && now - _lastInAt < keepAliveMs) return;
    final acts = _pending.length > kMaxActsPerInput ? _pending.sublist(0, kMaxActsPerInput) : _pending;
    send('I|$_ackBase|${acts.join('~')}|$axes');
    _sentAxes = axes;
    _lastInAt = now;
  }

  /// En son alınan anlık durum.
  NetSnap? get latest => _latest;

  /// Son anlık durumun alındığı an (misafir; hiç gelmediyse null).
  int? get lastSnapAt => _lastSnapAt;

  NetSnap? _parseSnap(int seat, String data, int now) {
    final p = data.split('|');
    if (p.length < 6) return null;
    final e = int.tryParse(p[1]), t = int.tryParse(p[2]), bots = p[4].isEmpty ? 0 : int.tryParse(p[4]);
    if (e == null || t == null || bots == null) return null;
    final acks = <int, int>{};
    if (p[3].isNotEmpty) {
      for (final kv in p[3].split(',')) {
        final x = kv.split(':');
        if (x.length != 2) return null;
        final k = int.tryParse(x[0]), v = int.tryParse(x[1]);
        if (k == null || v == null) return null;
        acks[k] = v;
      }
    }
    return NetSnap(e, seat, t, acks, bots, p.sublist(5).join('|'), now);
  }

  /// Bu kaynağın yetkisi şimdikinden üstün ya da eşit mi.
  bool _accepts(int e, int seat) => e > ep || (e == ep && seat <= host);

  void _onSnap(NetSnap s, int now) {
    if (s.host == mySeat) {
      // Kendi eski anlık durumumuz (geri dönüş): ev sahibi kaldığı yerden sürer.
      if (s.ep > ep || (s.ep == ep && isHost && s.t > _lastPubT)) {
        ep = s.ep;
        host = mySeat;
        _lastPubT = s.t;
        _done
          ..clear()
          ..addAll(s.acks);
        _inbox.clear();
        _resume = s;
      }
      return;
    }
    if (!_accepts(s.ep, s.host)) return;
    final wasHost = isHost;
    if (s.ep != ep || s.host != host) {
      _buf.clear();
      _offset = null;
    }
    ep = s.ep;
    host = s.host;
    if (wasHost) {
      _demoted = true;
      // Kendi sıramızdaki işlenmemiş eylemler yeni ev sahibine gider.
      _pending.addAll(_local);
      _local.clear();
      _inbox.clear();
    }
    _lastSnapAt = now;
    final last = _buf.isEmpty ? null : _buf.last;
    if (last != null && s.t < last.t) return; // eski mesaj
    _buf.add(s);
    if (_buf.length > 12) _buf.removeAt(0);
    _latest = s;
    final est = (s.t - now).toDouble();
    final o = _offset;
    _offset = o == null || est > o ? est : o + (est - o) * 0.05;
    final ack = s.acks[mySeat] ?? 0;
    if (ack >= _ackBase) {
      final drop = math.min(ack - _ackBase, _pending.length);
      _pending.removeRange(0, drop);
      _ackBase = ack;
    } else {
      // Yeni ev sahibi daha eski bir durumdan sürdü: bekleyenler yeniden numaralanır.
      _ackBase = ack;
    }
  }

  /// Ara kare: ekranda gösterilecek iki anlık durum ve aradaki oran (0..1).
  (NetSnap, NetSnap, double)? frame(int now) {
    if (_buf.isEmpty) return null;
    final rt = now + (_offset ?? 0) - delayMs;
    if (rt <= _buf.first.t) return (_buf.first, _buf.first, 0);
    for (var i = 0; i + 1 < _buf.length; i++) {
      final a = _buf[i], b = _buf[i + 1];
      if (rt >= a.t && rt < b.t) {
        final span = b.t - a.t;
        return (a, b, span <= 0 ? 1.0 : ((rt - a.t) / span).clamp(0.0, 1.0));
      }
    }
    return (_buf.last, _buf.last, 0);
  }

  /// Ev sahibinin oyun saatinin bu cihazdaki tahmini (gösterim için).
  int hostTime(int now) => (now + (_offset ?? 0)).round();

  /// Ev sahibi sustuysa devral. Devralındıysa true: oyun [latest] durumundan
  /// sürer, bekleyen kendi eylemlerimiz [takeActions] ile gelir.
  bool checkTakeover(int now) {
    if (isHost) return false;
    final last = _lastSnapAt;
    final quiet = last == null ? now - startMs >= graceMs : now - last >= hostTimeoutMs;
    if (!quiet) return false;
    // Ayakta kalan en küçük misafir koltuğu devralır.
    for (var s = 0; s < seats; s++) {
      if (s == host || !humans.contains(s)) continue;
      if (s == mySeat) break;
      if (_alive(s, now, hostTimeoutMs)) return false;
    }
    final l = _latest;
    ep = math.max(ep, l?.ep ?? 0) + 1;
    host = mySeat;
    _done
      ..clear()
      ..addAll(l?.acks ?? const {});
    _done.remove(mySeat);
    _inbox.clear();
    _local.addAll(_pending);
    _pending.clear();
    _buf.clear();
    _offset = null;
    _lastPubAt = _never;
    return true;
  }

  /// Uygulaması kapanıp açılan ev sahibinin kaldığı anlık durum (bir kez).
  NetSnap? takeResume() {
    final r = _resume;
    _resume = null;
    return r;
  }

  /// Ev sahibiyken daha yetkili bir ev sahibi görüldü mü (bir kez true).
  bool takeDemoted() {
    final d = _demoted;
    _demoted = false;
    return d;
  }
}

/// Bir girdi mesajında en çok bu kadar eylem gider (kalanı onaydan sonra).
const kMaxActsPerInput = 32;

// ---- Bağlantı bildirimleri -----------------------------------------------------------

/// Ekranda gösterilecek bağlantı bildirimi (metinleri: `core/net_texts.dart`).
enum NetNote {
  none,

  /// Diğer oyuncular / ev sahibi bekleniyor.
  waiting,

  /// Ev sahibinden bir süredir ses yok.
  reconnecting,

  /// Ev sahibi düştü, oyunu bu cihaz sürdürüyor.
  nowHost,

  /// Ev sahibi değişti, oyun sürüyor.
  hostChanged,

  /// Bir oyuncunun bağlantısı koptu, yerine yapay zekâ oynuyor ([NetNotes.seat]).
  botPlaying,
}

/// [NetSync] durumundan ekran bildirimi üretir. Her karede [update] çağrılır.
class NetNotes {
  /// Kısa süreli bildirimlerin ekranda kalma süresi.
  final int flashMs;

  /// Ev sahibinden bu kadar ses gelmezse "yeniden bağlanıyor".
  final int quietMs;

  NetNotes({this.flashMs = 3000, this.quietMs = 1200});

  int? _host;
  int _ep = 0;
  NetNote _flash = NetNote.none;
  int _flashUntil = 0;
  NetNote note = NetNote.none;

  /// [NetNote.botPlaying] için koltuk.
  int seat = -1;

  NetNote update(NetSync s, int now) {
    final h = _host;
    if (h != null && (s.host != h || s.ep != _ep)) {
      _flash = s.isHost ? NetNote.nowHost : NetNote.hostChanged;
      _flashUntil = now + flashMs;
    }
    _host = s.host;
    _ep = s.ep;
    seat = -1;
    if (now < _flashUntil) return note = _flash;
    if (!s.isHost) {
      final at = s.lastSnapAt;
      if (at == null) return note = NetNote.waiting;
      if (now - at > quietMs) return note = NetNote.reconnecting;
      final l = s.latest;
      for (var i = 0; i < s.seats; i++) {
        if (i != s.mySeat && s.humans.contains(i) && (l?.isBot(i) ?? false)) {
          seat = i;
          return note = NetNote.botPlaying;
        }
      }
      return note = NetNote.none;
    }
    var waiting = false;
    for (var i = 0; i < s.seats; i++) {
      if (i == s.mySeat || !s.humans.contains(i)) continue;
      if (s.heardAt(i) == null && s.live(i, now)) {
        waiting = true;
      } else if (!s.live(i, now)) {
        seat = i;
        return note = NetNote.botPlaying;
      }
    }
    return note = waiting ? NetNote.waiting : NetNote.none;
  }
}

// ---- Sayı listesi yazımı -----------------------------------------------------------

/// Sayıları kısa yazar: tam sayılar tam, diğerleri en çok 2 basamak.
String encodeNums(List<num> v) {
  final b = StringBuffer();
  for (var i = 0; i < v.length; i++) {
    if (i > 0) b.write(',');
    final x = v[i];
    if (x is int) {
      b.write(x);
    } else if (!x.isFinite) {
      b.write(0);
    } else if (x == x.roundToDouble() && x.abs() < 1e15) {
      b.write(x.round());
    } else {
      var s = x.toStringAsFixed(2);
      while (s.endsWith('0')) {
        s = s.substring(0, s.length - 1);
      }
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
      if (s == '-0') s = '0';
      b.write(s);
    }
  }
  return b.toString();
}

List<double> decodeNums(String s) {
  if (s.isEmpty) return const [];
  return [for (final p in s.split(',')) double.tryParse(p) ?? 0];
}

List<int> decodeInts(String s) {
  if (s.isEmpty) return const [];
  return [for (final p in s.split(',')) (double.tryParse(p) ?? 0).round()];
}
