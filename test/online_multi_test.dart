// Çok istemcili çevrimiçi masa testleri (bellek içi arka uç, Firestore düzeni
// ve kurallarının aynısı). Her test 2–4 başsız istemciyle bir masa kurar, maçı
// sonuna kadar oynatır ve bütün istemcilerin aynı sonuca vardığını denetler:
// kopma → bot devralması → geri dönüş, uygulama kapanıp açılma, ev sahibinin
// ayrılması, eşzamanlı hamle, kural dışı (hileli) yazmalar, eskimiş masalar,
// gecikme, sürüm uyuşmazlığı, tr/ar.
//
// Sürücü, motorların masa görünümlerindeki döngünün (kart table_view,
// trick_view, masa board_view) aynısıdır: sıra kimdeyse onun hamlesi beklenir;
// sıra bu cihazdaysa oynanır; bot ya da kopan koltuğu ev sahibi oynar.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/turn_clock.dart';
import 'package:studio_core/core/net_sync.dart';
import 'package:studio_core/core/net_texts.dart';
import 'package:studio_core/online/online.dart';

/// Basit sıra tabanlı oyun: sırayla 1–3 eklenir, 31'e ulaşan kazanır.
class RaceState {
  final int seats;
  int total = 0, turn = 0, winner = -1, ply = 0;
  final List<String> log = [];
  RaceState(this.seats);
  bool get over => winner >= 0;
  void apply(int seat, int add) {
    assert(seat == turn);
    total += add;
    log.add('$seat:$add');
    ply++;
    if (total >= 31) {
      winner = seat;
    } else {
      turn = (turn + 1) % seats;
    }
  }

  static int choose(int seed, int ply, int seat) => 1 + (mixSeed(seed, ply, seat) % 3);
  static int mixSeed(int a, int b, int c) => ((a * 31 + b) * 131 + c * 7 + 17) & 0x7fffffff;
}

/// Bir istemci (oyun ekranı): motor görünümlerindeki `_advance` döngüsünün aynısı.
class Client {
  final MemoryBackend b;
  OnlineMatch m;
  late RaceState s;
  final List<(int, String)> inbox = [];
  StreamSubscription<(int, String)>? _sub;
  StreamSubscription<MoveRejected>? _rej;
  int resyncs = 0;

  /// Bu cihazdaki oyuncu kendi sırasında oynuyor mu (kapalıysa bekler).
  bool playing = true;
  bool _busy = false;

  Client(this.b, this.m) {
    _open();
  }

  void _open() {
    s = RaceState(m.size);
    inbox
      ..clear()
      ..addAll(m.history);
    _sub = m.moves.listen((e) {
      inbox.add(e);
      unawaited(step());
    });
    _rej = m.rejections.listen((_) => unawaited(resync()));
  }

  Future<void> close() async {
    await _sub?.cancel();
    await _rej?.cancel();
  }

  bool _isAi(int seat) => m.seats[seat].bot || m.dropped.contains(seat);

  Future<void> step() async {
    if (_busy) return;
    _busy = true;
    try {
      while (!s.over) {
        final seat = s.turn;
        final i = inbox.indexWhere((e) => e.$1 == seat);
        if (i >= 0) {
          final mv = inbox.removeAt(i);
          s.apply(seat, int.parse(mv.$2));
          continue;
        }
        if (seat == m.mySeat) {
          if (!playing) break;
          final add = RaceState.choose(m.seed, s.ply, seat);
          unawaited(m.send('$add'));
          s.apply(seat, add);
          continue;
        }
        if (_isAi(seat) && m.isHost) {
          final add = RaceState.choose(m.seed, s.ply, seat);
          unawaited(m.send('$add', asSeat: seat));
          s.apply(seat, add);
          continue;
        }
        break;
      }
      if (s.over && m.status != MatchStatus.done) await m.finish(s.winner);
    } finally {
      _busy = false;
    }
  }

  /// Hamle reddedildi: masa sunucudaki geçmişten yeniden kurulur (OnlineTable._resync).
  Future<void> resync() async {
    final fresh = await b.rejoin(m.id, ended: true);
    if (fresh == null) return;
    resyncs++;
    await close();
    await m.leave();
    m = fresh;
    _open();
    await step();
  }
}

Future<void> settle([int rounds = 60]) async {
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

class Table {
  final MemoryServer server = MemoryServer();
  final List<MemoryBackend> backends = [];
  final List<Client> clients = [];
  int now = 1000000;

  Table() {
    server.clock = () => now;
  }

  /// [humans] istemci, [size] koltuk; boş koltuklara bot oturur.
  Future<void> open(int humans, int size, {String version = '2.1', List<String>? names}) async {
    for (var i = 0; i < humans; i++) {
      final b = MemoryBackend(server, 'u$i');
      final p = await b.signIn();
      if (names != null) p.name = names[i];
      backends.add(b);
    }
    final host = await backends[0].createMatch('oyun-x', size, version: version);
    final ms = <OnlineMatch>[host];
    for (var i = 1; i < humans; i++) {
      ms.add((await backends[i].joinByCode(host.code, version: version))!);
    }
    if (humans < size) await host.fillWithBotsAndStart();
    for (var i = 0; i < humans; i++) {
      clients.add(Client(backends[i], ms[i]));
    }
  }

  Future<void> run({int rounds = 80}) async {
    for (final c in clients) {
      unawaited(c.step());
    }
    await settle(rounds);
  }

  void expectConsistent() {
    final ref = clients.first.s;
    expect(ref.over, isTrue, reason: 'maç bitmedi: ${ref.log}');
    for (final c in clients) {
      expect(c.s.log, ref.log, reason: '${c.b.uid} masadan ayrıştı');
      expect(c.s.winner, ref.winner);
    }
    final d = server.matches.values.single;
    expect(d.status, MatchStatus.done);
    // Sunucudaki hamle günlüğü (sıra numarasıyla) ekrandakiyle aynı.
    final ns = d.moves.keys.toList()..sort();
    expect([for (final n in ns) '${d.moves[n]!.$1}:${d.moves[n]!.$2}'], ref.log);
  }
}

void main() {
  group('tam maç (2–4 istemci, botlar)', () {
    for (final (humans, size) in [(2, 2), (3, 3), (2, 4), (4, 4)]) {
      test('$humans insan / $size koltuk: herkes aynı maçı sonuna kadar görür', () async {
        final t = Table();
        await t.open(humans, size);
        await t.run();
        t.expectConsistent();
        expect(t.server.rejected, isEmpty);
      });
    }

    test('gecikme enjeksiyonu (0–25 ms, istemci başına farklı) ile tutarlı', () async {
      for (var seed = 0; seed < 6; seed++) {
        final t = Table();
        final r = math.Random(seed);
        await t.open(4, 4);
        for (final b in t.backends) {
          t.server.latencyOf[b.uid] = Duration(milliseconds: r.nextInt(26));
        }
        await t.run(rounds: 200);
        t.expectConsistent();
      }
    });
  });

  group('kopma ve geri dönüş', () {
    test('maç ortasında kopma → ev sahibi botla oynar → geri dönüp kaldığı yerden sürer', () async {
      final t = Table();
      await t.open(3, 3);
      final c1 = t.clients[1];
      // 1. koltuk sırası gelince oynamıyor ve bağlantısı kopuyor.
      c1.playing = false;
      t.server.goOffline('u1');
      await t.run(rounds: 20);
      expect(t.clients[0].s.over, isFalse);
      expect(t.clients[0].s.turn, 1, reason: 'kopan oyuncunun sırasında beklenir (45 sn dolmadı)');
      // 50 sn geçti: ev sahibi koltuğu bota verir, maç sürer.
      t.now += 50000;
      expect(t.clients[0].m.dropped, {1});
      expect(t.clients[2].m.dropped, {1});
      expect(t.clients[0].m.isHost, isTrue);
      await t.clients[0].step();
      await settle(20);
      // Geri dönüş: bekleyen değişiklikler gelir, oyuncu sürdürür.
      c1.playing = true;
      await t.server.goOnline('u1');
      await t.run(rounds: 80);
      t.expectConsistent();
    });

    test('çevrimdışıyken sıraya giren hamle, bot hamlesiyle çakışırsa reddedilir ve masa geçmişten kurulur', () async {
      final t = Table();
      await t.open(2, 2);
      final c1 = t.clients[1];
      c1.playing = false;
      await t.run(rounds: 10);
      expect(c1.s.turn, 1, reason: 'ev sahibi oynadı, sıra misafirde');
      // Misafirin bağlantısı koptu ama oynadı: hamlesi yerelde sıraya girer.
      t.server.goOffline('u1');
      c1.playing = true;
      await c1.step();
      expect(c1.s.ply, 2);
      // 60 sn: ev sahibi misafirin yerine bot oynar (aynı sıra numarası).
      t.now += 60000;
      await t.clients[0].step();
      await settle(5);
      // Bağlantı geldi: sıradaki hamle reddedilir, misafir masayı geçmişten kurar.
      await t.server.goOnline('u1');
      await t.run(rounds: 120);
      expect(t.server.rejected.where((x) => x.startsWith('move:u1:')), isNotEmpty);
      expect(c1.resyncs, greaterThan(0));
      t.expectConsistent();
    });

    test('uygulama kapanıp açılır: geçmiş hamleler yeniden oynanır, maç sürer', () async {
      final t = Table();
      await t.open(2, 3);
      final c1 = t.clients[1];
      c1.playing = false;
      await t.run(rounds: 10);
      final before = List<String>.of(c1.s.log);
      expect(before, isNotEmpty);
      // "Kapanma": dinleme kesilir, leave çağrılmaz, kalp atışı durur.
      await c1.close();
      t.server.goOffline('u1');
      t.now += 5000;
      await t.server.goOnline('u1');
      final back = await t.backends[1].rejoin(c1.m.id);
      expect(back, isNotNull);
      final c1b = Client(t.backends[1], back!);
      t.clients[1] = c1b;
      expect(c1b.inbox.length, before.length, reason: 'geçmiş eksiksiz gelmeli');
      await t.run(rounds: 80);
      t.expectConsistent();
    });

    test('ev sahibi maçtan çıkar (yenik): koltuğu hemen bota geçer, yeni ev sahibi botları oynar', () async {
      final t = Table();
      await t.open(3, 4);
      t.clients[0].playing = false;
      await t.run(rounds: 5);
      await t.clients[0].close();
      await t.clients[0].m.leave(forfeit: true);
      final rest = t.clients.sublist(1);
      expect(rest[0].m.dropped, contains(0), reason: '45 sn beklenmeden');
      expect(rest[0].m.isHost, isTrue);
      expect(rest[1].m.isHost, isFalse);
      expect(await t.backends[0].rejoin(rest[0].m.id), isNull, reason: 'yenik sayılan geri dönmez');
      t.clients
        ..clear()
        ..addAll(rest);
      await t.run(rounds: 80);
      t.expectConsistent();
    });

    test('kopan oyuncu cihaz saati yanlış olsa da kimseyi "kopmuş" saymaz', () {
      // Kalp atışları sunucu saatiyle; karşılaştırma masadaki en taze atışa göre.
      const seats = [Seat('a', 'A'), Seat('b', 'B'), Seat('', ''), Seat('c', 'C')];
      expect(droppedSeats(seats, {'a': 1000000, 'b': 990000, 'c': 999000}, 0), isEmpty);
      expect(droppedSeats(seats, {'a': 1000000, 'b': 950000, 'c': 999000}, 0), {1});
      expect(droppedSeats(seats, {'a': 1000000, 'b': 0, 'c': 999000}, 0), {1}, reason: '0 = masadan kalktı');
      expect(droppedSeats(seats, {'a': 1000000, 'b': null, 'c': 999000}, 0), isEmpty, reason: 'bekleyen yazma taze');
      // Ben kendim çevrimdışıyım: kendi atışım da donmuş, diğerleri "kopmuş" görünmez.
      expect(droppedSeats(seats, {'a': 900000, 'b': 899000, 'c': 899500}, 0), isEmpty);
      expect(hostSeatIs(seats, {0}, 1), isTrue);
      expect(hostSeatIs(seats, {0, 1}, 3), isTrue);
    });
  });

  group('eşzamanlılık ve hile', () {
    test('aynı sıra numarasına iki hamle: biri kazanır, diğeri reddedilir (hiçbir hamle sessizce kaybolmaz)', () async {
      final t = Table();
      await t.open(2, 2);
      final a = t.clients[0].m, b = t.clients[1].m;
      final ra = <MoveRejected>[], rb = <MoveRejected>[];
      a.rejections.listen(ra.add);
      b.rejections.listen(rb.add);
      t.server.latency = const Duration(milliseconds: 5);
      await Future.wait([a.send('1'), b.send('2')]);
      await settle(5);
      final d = t.server.matches.values.single;
      expect(d.moves.length, 1);
      expect(ra.length + rb.length, 1);
      expect((ra.isEmpty ? rb : ra).single.reason, 'exists');
    });

    test('kural dışı yazmalar reddedilir', () async {
      final t = Table();
      await t.open(3, 3);
      final a = t.clients[0].m, b = t.clients[1].m;
      final rej = <MoveRejected>[];
      b.rejections.listen(rej.add);
      await b.send('3', asSeat: 2); // bağlı oyuncunun yerine
      await b.send('3', asSeat: 0);
      await b.send('3', asSeat: 7); // olmayan koltuk
      expect(rej.map((r) => r.reason), ['seat', 'seat', 'seat']);
      await b.say(const TableEvent(0, 'p', 'chat_gg')); // başkası adına sohbet
      await b.say(const TableEvent(1, 't', 'merhaba')); // 16 yaş beyanı yok
      expect(t.server.rejected.where((x) => x.startsWith('event:')), hasLength(2));
      // Masada olmayan biri hamle yazamaz.
      final x = MemoryBackend(t.server, 'yabanci');
      await x.signIn();
      expect(await x.joinByCode(a.code, version: '2.1'), isNull, reason: 'masa dolu');
      // Bitmiş maça hamle yazılamaz.
      await a.finish(0);
      await a.send('1');
      expect(t.server.rejected.last, contains(':status'));
      expect(t.server.matches.values.single.moves, isEmpty);
    });

    test('bot koltuğu ve kopan koltuk adına yazılabilir', () async {
      final t = Table();
      await t.open(2, 3);
      final a = t.clients[0].m;
      final rej = <MoveRejected>[];
      a.rejections.listen(rej.add);
      await a.send('1', asSeat: 2); // bot
      t.server.goOffline('u1');
      t.now += 41000;
      await a.send('1', asSeat: 1); // 40 sn'den eski kalp atışı
      expect(rej, isEmpty);
      expect(t.server.matches.values.single.moves.length, 2);
    });
  });

  group('lobi', () {
    test('ev sahibi gitmiş (eskimiş) masa listelenmez ve hızlı eşleşmede seçilmez', () async {
      final t = Table();
      final a = MemoryBackend(t.server, 'a'), b = MemoryBackend(t.server, 'b');
      await a.signIn();
      await b.signIn();
      final stale = await a.quickMatch('oyun-okey', 4, 1000, version: '2.1');
      t.server.goOffline('a');
      t.now += 60000;
      expect(await b.openTables('oyun-okey', 4, version: '2.1'), isEmpty);
      final mb = await b.quickMatch('oyun-okey', 4, 1000, version: '2.1');
      expect(mb.id, isNot(stale.id));
      expect(mb.isHost, isTrue);
    });

    test('farklı sürüm: listelenmez, eşleşmez, kodla katılımda "güncelle"', () async {
      final t = Table();
      final a = MemoryBackend(t.server, 'a'), b = MemoryBackend(t.server, 'b');
      await a.signIn();
      await b.signIn();
      final old = await a.createMatch('oyun-101-okey', 2, private: false, version: '2.1');
      expect(await b.openTables('oyun-101-okey', 2, version: '2.2'), isEmpty);
      expect((await b.quickMatch('oyun-101-okey', 2, 1000, version: '2.2')).id, isNot(old.id));
      await expectLater(b.joinByCode(old.code, version: '2.2'), throwsA(isA<OnlineVersionMismatch>()));
      expect(onlineKey(3), '$kOnlineProtocol.3');
    });

    test('ilk hamleler masa ekranı açılmadan gelirse kaybolmaz', () async {
      final t = Table();
      final a = MemoryBackend(t.server, 'a'), b = MemoryBackend(t.server, 'b');
      await a.signIn();
      await b.signIn();
      final ma = await a.createMatch('g', 3, version: '2.1');
      final mb = (await b.joinByCode(ma.code, version: '2.1'))!;
      await ma.fillWithBotsAndStart();
      await ma.send('1');
      await ma.send('2', asSeat: 2);
      await settle(2);
      final got = <(int, String)>[];
      mb.moves.listen(got.add); // ekran sonradan açıldı
      await settle(2);
      expect(got, [(0, '1'), (2, '2')]);
    });

    test('rövanş: ilk açan kazanır, diğerleri onun masasına oturur', () async {
      final t = Table();
      await t.open(2, 2);
      await t.run();
      final a = t.clients[0].m, b = t.clients[1].m;
      final na = await t.backends[0].createMatch('oyun-x', 2, version: '2.1');
      final nb = await t.backends[1].createMatch('oyun-x', 2, version: '2.1');
      final wa = await a.offerRematch(na.id);
      final wb = await b.offerRematch(nb.id);
      expect(wa, '0|${na.id}');
      expect(wb, wa, reason: 'ikinci teklif ilkini ezmez');
      expect(b.next, wa);
      final joined = await t.backends[1].joinTable(wa.split('|').last, version: '2.1');
      expect(joined!.status, MatchStatus.playing);
    });
  });

  group('dil', () {
    test('tr ve ar adlarla masa: hamleler dilden bağımsız, metinler doğru dilde', () async {
      final t = Table();
      await t.open(2, 2, names: ['Mavi Tilki', 'نسر ذهبي']);
      await t.run();
      t.expectConsistent();
      expect(t.clients[0].m.seats[1].name, 'نسر ذهبي');
      expect(encodeNums([1.5, 2, -0.25]), '1.5,2,-0.25');
      final ar = netNoteText('ar', NetNote.botPlaying, 'نسر ذهبي');
      expect(ar, contains('نسر ذهبي'));
      expect(ar, isNot(netNoteText('tr', NetNote.botPlaying, 'نسر ذهبي')));
      expect(netLeaveTitle('ar'), isNot(netLeaveTitle('en')));
      expect(netTurnLeft('tr', 12), 'Sıra sende: 12 sn');
      expect(netTurnLeft('ar', 12), contains('12'));
    });
  });

  group('sıra süresi (TurnClock)', () {
    testWidgets('süre dolunca bir kez zaman aşımı; oyuncu oynarsa iptal; üst üste 3 kez dolunca beklemez', (tester) async {
      var fired = 0, changes = 0;
      final c = TurnClock(() => changes++, seconds: 5);
      c.start(() => fired++);
      expect(c.left, 5);
      await tester.pump(const Duration(seconds: 3));
      expect(c.left, 2);
      c.stop(byPlayer: true);
      await tester.pump(const Duration(seconds: 10));
      expect(fired, 0);
      for (var i = 0; i < 3; i++) {
        c.start(() => fired++);
        await tester.pump(const Duration(seconds: 6));
      }
      expect(fired, 3);
      expect(c.timeouts, 3);
      c.start(() => fired++);
      await tester.pump(Duration.zero);
      expect(fired, 4, reason: 'uzun süredir yok: hemen oynanır');
      c.stop(byPlayer: true);
      expect(c.timeouts, 0);
      expect(changes, greaterThan(0));
      c.dispose();
    });
  });
}
