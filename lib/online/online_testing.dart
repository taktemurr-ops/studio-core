/// Çok istemcili çevrimiçi masa testleri için yardımcı (motor depolarının
/// testleri kullanır). Bellek içi sunucu ([MemoryServer]) Firestore düzeninin
/// ve kurallarının aynısını uygular; burada 2–4 istemci aynı masaya oturur,
/// her biri için oyun ekranının kullandığı [OnlineMatchLink] verilir.
/// Ağ benzetimi: [drop]/[back] (bağlantı kopar/gelir), [kill]/[resume]
/// (uygulama kapanıp açılır), [latency], sanal sunucu saati ([advance]).
library;

import 'online.dart';
import 'online_service.dart';

class OnlineTestTable {
  final MemoryServer server = MemoryServer();
  final List<MemoryBackend> backends = [];
  final List<OnlineMatch> matches = [];
  int _now = 1700000000000;

  OnlineTestTable._() {
    server.clock = () => _now;
  }

  /// [humans] istemci, [seats] koltuk; boş koltuklara bot oturur.
  /// [names]: oyuncu adları (ör. Arapça ad ile dil denemesi).
  static Future<OnlineTestTable> open({
    required String gameId,
    required int seats,
    int humans = 2,
    String version = '',
    List<String>? names,
  }) async {
    final t = OnlineTestTable._();
    for (var i = 0; i < humans; i++) {
      final b = MemoryBackend(t.server, 'oyuncu$i');
      final p = await b.signIn();
      if (names != null && i < names.length) p.name = names[i];
      t.backends.add(b);
    }
    final host = await t.backends.first.createMatch(gameId, seats, version: version);
    t.matches.add(host);
    for (var i = 1; i < humans; i++) {
      t.matches.add((await t.backends[i].joinByCode(host.code, version: version))!);
    }
    if (humans < seats) await host.fillWithBotsAndStart();
    return t;
  }

  int get seed => matches.first.seed;
  String get matchId => matches.first.id;

  /// Oyun ekranına verilecek bağlantı.
  OnlineMatchLink link(int i) => OnlineMatchLink(matches[i]);

  /// Sanal sunucu saatini ilerlet (kopma süresi: 45 sn).
  void advance(Duration d) => _now += d.inMilliseconds;

  /// İstemcinin ağı koptu (yazmaları sıraya girer, gelenler bekler).
  void drop(int i) => server.goOffline(backends[i].uid);

  /// Ağ geri geldi.
  Future<void> back(int i) => server.goOnline(backends[i].uid);

  /// Uygulama kapandı: kalp atışı durur (ekran testte kaldırılır).
  void kill(int i) => server.goOffline(backends[i].uid);

  /// Uygulama yeniden açıldı: sürmekte olan maça geri dönülür (geçmiş hamleler
  /// [OnlineMatch.history] ile yeniden oynanır).
  Future<OnlineMatchLink?> resume(int i) async {
    await server.goOnline(backends[i].uid);
    final m = await backends[i].rejoin(matchId);
    if (m == null) return null;
    matches[i] = m;
    return OnlineMatchLink(m);
  }

  set latency(Duration d) => server.latency = d;

  /// Sunucudaki maç durumu ve hamle günlüğü (sıra numarasıyla).
  MatchStatus get status => server.matches[matchId]!.status;
  int get winner => server.matches[matchId]!.winner;
  int get moveCount => server.matches[matchId]!.moves.length;
  List<String> get rejected => server.rejected;
}
