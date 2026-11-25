import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/arcade_duel.dart';
import 'package:studio_core/core/net_sync.dart';
import 'package:studio_core/core/net_texts.dart';
import 'package:studio_core/core/strings.dart';
import 'package:studio_core/core/strings_phrases.dart';
import 'package:studio_core/online/live_ring.dart';
import 'package:studio_core/online/online.dart';
import 'package:studio_core/online/online_service.dart';

/// Gecikmeli, kayıplı ve sırasız sahte ağ: her mesaj gönderen dışındaki
/// bütün koltuklara gider.
///
/// [ring] verilirse Firestore halkası gibi davranır (`live_ring.dart`): bir
/// gönderenin alıcıya henüz ulaşmamış mesajlarından yalnızca son [ring]
/// tanesi kalır (eskiler üzerine yazılmış sayılır) ve alıcı bir gönderenden
/// gördüğünden eski mesajı atar (sıra numarası).
class FakeNet {
  final math.Random r;
  final double loss;
  final int minMs, maxMs;
  final int? ring;
  int now = 0;
  final List<(int, int, int, String, int)> _q = []; // teslim anı, alıcı, gönderen, veri, sıra
  final Map<int, NetSync> peers = {};
  final Set<int> offline = {};
  final Map<int, int> sentBy = {};
  final Map<(int, int), int> _seen = {};
  int sent = 0, _seq = 0;

  FakeNet({int seed = 1, this.loss = 0, this.minMs = 40, this.maxMs = 160, this.ring}) : r = math.Random(seed);

  void Function(String) sender(int seat) => (d) {
        if (offline.contains(seat)) return;
        sent++;
        sentBy[seat] = (sentBy[seat] ?? 0) + 1;
        final seq = ++_seq;
        for (final to in peers.keys) {
          if (to == seat) continue;
          if (r.nextDouble() < loss) continue;
          final k = ring;
          if (k != null) {
            final mine = _q.where((m) => m.$2 == to && m.$3 == seat).toList();
            if (mine.length >= k) _q.remove(mine.reduce((a, b) => a.$5 < b.$5 ? a : b));
          }
          _q.add((now + minMs + r.nextInt(maxMs - minMs + 1), to, seat, d, seq));
        }
      };

  void step(int ms) {
    now += ms;
    final due = _q.where((m) => m.$1 <= now).toList()..sort((a, b) => a.$1.compareTo(b.$1));
    _q.removeWhere((m) => m.$1 <= now);
    for (final m in due) {
      if (offline.contains(m.$2)) continue;
      if (ring != null) {
        final last = _seen[(m.$2, m.$3)] ?? 0;
        if (m.$5 <= last) continue;
        _seen[(m.$2, m.$3)] = m.$5;
      }
      peers[m.$2]!.receive(m.$3, m.$4, now);
    }
  }
}

NetSync peer(FakeNet n, int seat, {int seats = 2, Set<int>? humans}) {
  final s = NetSync(mySeat: seat, seats: seats, humans: humans ?? {for (var i = 0; i < seats; i++) i}, send: n.sender(seat));
  n.peers[seat] = s;
  return s;
}

void main() {
  group('sayı yazımı', () {
    test('tam sayılar ve 2 basamaklı ondalıklar gidip gelir', () {
      final v = <num>[0, 3, -7, 1.5, 2.25, -0.004, 999.999, double.nan];
      final s = encodeNums(v);
      expect(s, '0,3,-7,1.5,2.25,0,1000,0');
      expect(decodeNums(s), [0, 3, -7, 1.5, 2.25, 0, 1000, 0]);
      expect(decodeInts('1,2.6,-3'), [1, 3, -3]);
      expect(decodeNums(''), isEmpty);
    });
  });

  group('NetSync', () {
    test('kayıplı ve sırasız ağda misafir eylemleri bir kez ve sırayla işlenir', () {
      final n = FakeNet(seed: 3, loss: 0.3, minMs: 30, maxMs: 250);
      final host = peer(n, 0), guest = peer(n, 1);
      expect(host.isHost, isTrue);
      expect(guest.isHost, isFalse);
      final applied = <String>[];
      var sent = 0;
      for (var t = 0; t < 20000; t += 10) {
        if (t % 170 == 0 && sent < 60) guest.act('a${sent++}');
        guest.setAxes([1, (t % 1000).toDouble(), 5]);
        guest.pump(n.now);
        for (final (seat, a) in host.takeActions()) {
          expect(seat, 1);
          applied.add(a);
        }
        host.publish(t, '${applied.length}', n.now);
        n.step(10);
      }
      expect(applied, [for (var i = 0; i < 60; i++) 'a$i']);
      expect(guest.pending, 0);
      expect(host.axesOf(1), isNotNull);
      expect(guest.latest!.payload, '60');
      expect(guest.latest!.acks[1], 60);
    });

    test('ev sahibinin kendi eylemleri de takeActions ile gelir', () {
      final n = FakeNet();
      final host = peer(n, 0);
      peer(n, 1);
      host.act('x');
      host.act('y');
      expect(host.takeActions(), [(0, 'x'), (0, 'y')]);
      expect(host.takeActions(), isEmpty);
    });

    test('anlık durum sıklığı sınırlı; değişmeyen durum yalnızca canlılık için gider', () {
      final n = FakeNet(loss: 0);
      final host = peer(n, 0);
      peer(n, 1);
      var count = 0;
      for (var t = 0; t < 1000; t += 10) {
        if (host.publish(t, 'p$t', n.now)) count++;
        n.step(10);
      }
      expect(count, inInclusiveRange(10, 11)); // en çok 10 Hz
      count = 0;
      for (var t = 0; t < 3000; t += 10) {
        if (host.publish(t, 'same', n.now, changed: false)) count++;
        n.step(10);
      }
      expect(count, inInclusiveRange(2, 4)); // yalnızca saniyede bir
    });

    for (final ring in [1, 3]) {
      test('üzerine yazılan halka (ring=$ring) + kayıp: eylemler yine bir kez ve sırayla', () {
        final n = FakeNet(seed: 11, loss: 0.2, minMs: 30, maxMs: 300, ring: ring);
        final host = peer(n, 0), guest = peer(n, 1);
        final applied = <String>[];
        var sent = 0;
        for (var t = 0; t < 30000; t += 10) {
          if (t % 90 == 0 && sent < 120) guest.act('a${sent++}');
          guest.setAxes([1, (t % 700).toDouble(), 3]);
          guest.pump(n.now);
          for (final (seat, a) in host.takeActions()) {
            expect(seat, 1);
            applied.add(a);
          }
          host.publish(t, '${applied.length}', n.now);
          n.step(10);
        }
        expect(applied, [for (var i = 0; i < 120; i++) 'a$i']);
        expect(guest.pending, 0);
        expect(guest.latest!.acks[1], 120);
      });
    }

    test('girdi mesajı en çok kMaxActsPerInput eylem taşır; kalanlar onaydan sonra gider', () {
      final n = FakeNet(loss: 0, ring: 1);
      final host = peer(n, 0);
      final msgs = <String>[];
      final inner = n.sender(1);
      final spy = NetSync(mySeat: 1, seats: 2, humans: {0, 1}, send: (d) {
        msgs.add(d);
        inner(d);
      });
      n.peers[1] = spy;
      for (var i = 0; i < 100; i++) {
        spy.act('x$i');
      }
      final applied = <String>[];
      for (var t = 0; t < 5000; t += 10) {
        spy.pump(n.now);
        for (final (_, a) in host.takeActions()) {
          applied.add(a);
        }
        host.publish(t, '${applied.length}', n.now);
        n.step(10);
      }
      expect(applied, [for (var i = 0; i < 100; i++) 'x$i']);
      for (final m in msgs) {
        expect(m.split('|')[2].split('~').length, lessThanOrEqualTo(kMaxActsPerInput));
      }
    });

    test('yazma bütçesi: hareket hâlinde ≤10/sn/koltuk, durgunken ~1/sn', () {
      final n = FakeNet(loss: 0, ring: kLiveRing);
      final host = peer(n, 0), guest = peer(n, 1);
      for (var t = 0; t < 60000; t += 16) {
        guest.setAxes([1, (t ~/ 16 % 250 * 4).toDouble(), 500, 0, 0]);
        guest.pump(n.now);
        host.takeActions();
        host.publish(t, 'p$t', n.now);
        n.step(16);
      }
      expect(n.sentBy[0]! / 60, lessThanOrEqualTo(10.5));
      expect(n.sentBy[1]! / 60, lessThanOrEqualTo(10.5));
      n.sentBy.clear();
      for (var t = 0; t < 60000; t += 16) {
        guest.pump(n.now);
        host.publish(60000 + t, 'same', n.now, changed: false);
        n.step(16);
      }
      expect(n.sentBy[0]! / 60, lessThanOrEqualTo(1.1));
      expect(n.sentBy[1]! / 60, lessThanOrEqualTo(1.1));
      expect(host.live(1, n.now), isTrue);
      expect(guest.checkTakeover(n.now), isFalse);
    });

    test('halkada devralma: ev sahibi düşer, misafir sürer, eski ev sahibi misafir olur', () {
      final n = FakeNet(seed: 4, loss: 0.1, ring: 1);
      final host = peer(n, 0), guest = peer(n, 1);
      final applied = <String>[];
      for (var t = 0; t < 2000; t += 10) {
        if (t % 200 == 0) guest.act('g$t');
        guest.pump(n.now);
        for (final (_, a) in host.takeActions()) {
          applied.add(a);
        }
        host.publish(t, '${applied.length}', n.now);
        n.step(10);
      }
      n.offline.add(0);
      guest.act('after');
      var took = false;
      for (var t = 0; t < 6000 && !took; t += 10) {
        guest.pump(n.now);
        took = guest.checkTakeover(n.now);
        n.step(10);
      }
      expect(took, isTrue);
      final done = int.parse(guest.latest!.payload);
      // ev sahibinin işlediği eylemler + devralmada bekleyenler: kayıpsız, tekrarsız
      final rest = [for (final (_, a) in guest.takeActions()) a];
      final all = [...applied.take(done), ...rest];
      expect(all.toSet().length, all.length);
      expect(all.last, 'after');
      expect(all.length, 11);
      n.offline.remove(0);
      for (var t = 0; t < 1500; t += 10) {
        guest.publish(9000 + t, 'new', n.now);
        host.publish(t, 'old', n.now);
        host.pump(n.now);
        n.step(10);
      }
      expect(host.isHost, isFalse);
      expect(host.latest!.payload, 'new');
    });

    test('ara kare: misafir ekranı ev sahibinin gerisinden, sırayla ilerler', () {
      final n = FakeNet(seed: 5, minMs: 50, maxMs: 120);
      final host = peer(n, 0), guest = peer(n, 1);
      var lastT = -1.0;
      for (var t = 0; t < 4000; t += 10) {
        host.publish(t, '$t', n.now);
        n.step(10);
        final fr = guest.frame(n.now);
        if (fr == null) continue;
        final a = fr.$1.t, b = fr.$2.t, f = fr.$3;
        expect(f, inInclusiveRange(0.0, 1.0));
        final shown = a + (b - a) * f;
        expect(shown, greaterThanOrEqualTo(lastT - 1));
        expect(shown, lessThanOrEqualTo(t.toDouble()));
        lastT = shown;
      }
      expect(lastT, greaterThan(3500));
    });

    test('ev sahibi susunca misafir son durumdan devralır; dönen ev sahibi misafir olur', () {
      final n = FakeNet(seed: 9, loss: 0.1);
      final host = peer(n, 0), guest = peer(n, 1);
      for (var t = 0; t < 2000; t += 10) {
        host.publish(t, 'state$t', n.now);
        guest.pump(n.now);
        n.step(10);
      }
      expect(guest.latest, isNotNull);
      // ev sahibi düşer; misafirin bekleyen eylemi var
      n.offline.add(0);
      guest.act('late');
      var took = false;
      for (var t = 0; t < 5000 && !took; t += 10) {
        guest.pump(n.now);
        took = guest.checkTakeover(n.now);
        n.step(10);
      }
      expect(took, isTrue);
      expect(guest.isHost, isTrue);
      expect(guest.ep, 1);
      expect(guest.latest!.payload, startsWith('state'));
      // devralmadan önce gönderilmiş ama onaylanmamış eylem yeni ev sahibinde işlenir
      expect(guest.takeActions(), [(1, 'late')]);
      // eski ev sahibi geri döner, yeni dönemin durumunu görünce misafir olur
      n.offline.remove(0);
      for (var t = 0; t < 1000; t += 10) {
        guest.publish(5000 + t, 'new$t', n.now);
        host.publish(t, 'old$t', n.now);
        n.step(10);
      }
      expect(host.isHost, isFalse);
      expect(host.takeDemoted(), isTrue);
      expect(host.host, 1);
      expect(host.ep, 1);
      expect(guest.isHost, isTrue);
      expect(host.latest!.payload, startsWith('new'));
    });

    test('aynı dönemde iki ev sahibi: küçük koltuk kazanır', () {
      final n = FakeNet(loss: 0);
      final a = peer(n, 0, seats: 3), b = peer(n, 1, seats: 3);
      b.host = 1; // ayrık ağda ikisi de kendini ev sahibi sanıyor
      for (var t = 0; t < 500; t += 10) {
        a.publish(t, 'a', n.now);
        b.publish(t, 'b', n.now);
        n.step(10);
      }
      expect(a.isHost, isTrue);
      expect(b.isHost, isFalse);
      expect(b.latest!.payload, 'a');
    });

    test('üç kişilik masada devralma: ayakta kalan en küçük misafir koltuğu', () {
      final n = FakeNet(loss: 0);
      final h = peer(n, 0, seats: 3), g1 = peer(n, 1, seats: 3), g2 = peer(n, 2, seats: 3);
      for (var t = 0; t < 1000; t += 10) {
        h.publish(t, 's', n.now);
        g1.pump(n.now);
        g2.pump(n.now);
        n.step(10);
      }
      n.offline.add(0);
      var any = false;
      for (var t = 0; t < 6000; t += 10) {
        g1.pump(n.now);
        g2.pump(n.now);
        final a = g1.checkTakeover(n.now), b = g2.checkTakeover(n.now);
        expect(b, isFalse);
        any = any || a;
        if (g1.isHost) g1.publish(t, 'g1', n.now);
        n.step(10);
      }
      expect(any, isTrue);
      expect(g1.isHost, isTrue);
      expect(g2.isHost, isFalse);
      expect(g2.host, 1);
    });

    test('sessiz misafirin koltuğu yapay zekâya geçer, girdi gelince geri döner', () {
      final n = FakeNet(loss: 0);
      final host = peer(n, 0), guest = peer(n, 1);
      for (var t = 0; t < 1000; t += 10) {
        guest.pump(n.now);
        host.publish(t, 's', n.now);
        n.step(10);
      }
      expect(host.live(1, n.now), isTrue);
      n.offline.add(1);
      for (var t = 0; t < 3000; t += 10) {
        n.step(10);
      }
      expect(host.live(1, n.now), isFalse);
      host.publish(4000, 's2', n.now, force: true);
      n.offline.remove(1);
      for (var t = 0; t < 600; t += 10) {
        guest.pump(n.now);
        n.step(10);
      }
      expect(host.live(1, n.now), isTrue);
    });

    test('anlık durumda bot maskesi', () {
      final n = FakeNet(loss: 0);
      final host = peer(n, 0, seats: 3, humans: {0, 1}), guest = peer(n, 1, seats: 3, humans: {0, 1});
      host.publish(0, 'x', n.now, force: true);
      n.step(200);
      expect(guest.latest!.isBot(2), isTrue);
      expect(guest.latest!.isBot(1), isFalse);
      expect(guest.latest!.isBot(0), isFalse);
    });

    test('geri dönüş: ev sahibi kendi son anlık durumundan sürer', () {
      final n = FakeNet(loss: 0);
      final again = peer(n, 0);
      // kanalın verdiği geçmiş: kendi eski anlık durumlarımız ve misafirin girdisi
      again.receive(0, 'S|0|1000|1:2||a', 0);
      again.receive(1, 'I|2|c|1,2,3,0,0', 0);
      again.receive(0, 'S|0|1500|1:2||b', 0);
      final r = again.takeResume();
      expect(r, isNotNull);
      expect(r!.payload, 'b');
      expect(again.isHost, isTrue);
      expect(again.takeResume(), isNull);
      // misafirin 2 eylemi zaten işlenmişti; sıradaki (2. sıra) 'c' bir kez gelir
      again.receive(1, 'I|2|c|1,2,3,0,0', 10);
      expect(again.takeActions(), [(1, 'c')]);
      expect(again.takeActions(), isEmpty);
    });

    test('bozuk mesajlar yok sayılır', () {
      final n = FakeNet();
      final g = peer(n, 1);
      g.receive(0, 'S|x|1|||', 0);
      g.receive(0, 'S|0', 0);
      g.receive(9, 'S|0|1|||p', 0);
      g.receive(0, 'Z|nonsense', 0);
      expect(g.latest, isNull);
      g.receive(0, 'S|0|5|||a|b', 0);
      expect(g.latest!.payload, 'a|b');
    });
  });

  group('düello yardımcıları', () {
    test('ayna girdisi iki kez uygulanınca aynı', () {
      const i = ArcadeInput(down: true, x: 120, y: 300, tap: true, swipe: 0, dirX: 1, dirY: -1);
      final m = mirrorInput(i);
      expect(m.x, kWorldW - 120);
      expect(m.y, kWorldH - 300);
      expect(m.swipe, 0);
      final back = mirrorInput(m);
      expect(back.x, 120);
      expect(back.y, 300);
      expect(back.dirX, 1);
      expect(mirrorInput(ArcadeInput.idle).hasPointer, isFalse);
    });

    test('ara kare büyük sıçramada karıştırmaz', () {
      final r = lerpAt([0, 0, 7], [100, 1000, 9], 0.5, [0, 1]);
      expect(r, [50, 1000, 9]);
    });
  });

  group('bellek içi gerçek zamanlı kanal', () {
    test('canlı mesajlar karşıya gider; geri dönüşte son mesajlar (kendininkiler dahil) gelir', () async {
      final server = MemoryServer();
      final a = MemoryBackend(server, 'a'), b = MemoryBackend(server, 'b');
      await a.signIn();
      await b.signIn();
      final ma = await a.quickMatch('oyun-hava-hokeyi', 2, 1000);
      final mb = await b.quickMatch('oyun-hava-hokeyi', 2, 1000);
      final la = OnlineMatchLink(ma), lb = OnlineMatchLink(mb);
      expect(la, isA<RealtimeLink>());
      final gotB = <(int, String)>[];
      final gotA = <(int, String)>[];
      final sb = lb.pulses.listen(gotB.add);
      final sa = la.pulses.listen(gotA.add);
      await Future<void>.delayed(Duration.zero);
      await la.pulse('S|0|1|||x');
      await lb.pulse('I|0||1,2,3,0,0');
      await la.pulse('S|0|2|||y');
      await Future<void>.delayed(Duration.zero);
      expect(gotB, [(0, 'S|0|1|||x'), (0, 'S|0|2|||y')]);
      expect(gotA, [(1, 'I|0||1,2,3,0,0')]);
      await sa.cancel();
      await sb.cancel();

      final back = await a.rejoin(ma.id);
      final replay = <(int, String)>[];
      final sr = (back! as RealtimeMatch).pulses.listen(replay.add);
      await Future<void>.delayed(Duration.zero);
      expect(replay, hasLength(3));
      expect([for (final r in replay) if (r.$1 == 0) r.$2], ['S|0|1|||x', 'S|0|2|||y']);
      expect([for (final r in replay) if (r.$1 == 1) r.$2], ['I|0||1,2,3,0,0']);
      await sr.cancel();
    });

    test('halka sınırlı: geri dönüşte koltuk başına en çok kLiveRing (en yeni) mesaj; maç bitince silinir', () async {
      final server = MemoryServer();
      final a = MemoryBackend(server, 'a'), b = MemoryBackend(server, 'b');
      await a.signIn();
      await b.signIn();
      final ma = await a.quickMatch('oyun-masa-tenisi', 2, 1000);
      final mb = await b.quickMatch('oyun-masa-tenisi', 2, 1000);
      final la = OnlineMatchLink(ma), lb = OnlineMatchLink(mb);
      for (var i = 0; i < 37; i++) {
        await la.pulse('S|0|$i|||$i');
        await lb.pulse('I|0||$i');
      }
      final back = await a.rejoin(ma.id);
      final replay = <(int, String)>[];
      final sr = (back! as RealtimeMatch).pulses.listen(replay.add);
      await Future<void>.delayed(Duration.zero);
      expect(replay.length, 2 * kLiveRing);
      expect([for (final r in replay) if (r.$1 == 0) r.$2], [for (var i = 37 - kLiveRing; i < 37; i++) 'S|0|$i|||$i']);
      await sr.cancel();
      await ma.finish(0);
      // bitince halka silindi; ilk kez dinleyen hiçbir şey almaz, yeni yazma da yapılmaz
      await la.pulse('S|0|99|||late');
      final none = <(int, String)>[];
      final s2 = lb.pulses.listen(none.add);
      await Future<void>.delayed(Duration.zero);
      expect(none, isEmpty);
      await s2.cancel();
    });

    test('ev sahibi ve misafir bellek içi kanal üzerinden eşitlenir', () async {
      final server = MemoryServer();
      final a = MemoryBackend(server, 'a'), b = MemoryBackend(server, 'b');
      await a.signIn();
      await b.signIn();
      final ma = await a.quickMatch('oyun-langirt', 2, 1000) as RealtimeMatch;
      final mb = await b.quickMatch('oyun-langirt', 2, 1000) as RealtimeMatch;
      var now = 0;
      final host = NetSync(mySeat: 0, seats: 2, humans: {0, 1}, send: (d) => unawaited(ma.pulse(d)));
      final guest = NetSync(mySeat: 1, seats: 2, humans: {0, 1}, send: (d) => unawaited(mb.pulse(d)));
      final s1 = ma.pulses.listen((p) => host.receive(p.$1, p.$2, now));
      final s2 = mb.pulses.listen((p) => guest.receive(p.$1, p.$2, now));
      final applied = <String>[];
      guest.act('kick');
      for (var i = 0; i < 40; i++) {
        guest.pump(now);
        for (final (_, x) in host.takeActions()) {
          applied.add(x);
        }
        host.publish(now, '${applied.length}', now);
        await Future<void>.delayed(Duration.zero);
        now += 50;
      }
      expect(applied, ['kick']);
      expect(guest.pending, 0);
      expect(guest.latest!.payload, '1');
      await s1.cancel();
      await s2.cancel();
    });
  });

  group('canlı belge halkası', () {
    test('yuvalar döner, kimlikler sınırlı, sıra numarası artar ve yeniden açılışta geri gitmez', () {
      final w = LiveWriter(ring: 4);
      final t0 = DateTime.utc(2026, 1, 1);
      final ids = <String>{};
      var last = 0;
      for (var i = 0; i < 50; i++) {
        final (id, d) = w.next(1, 'x$i', 'u', t0);
        ids.add(id);
        expect(d.seq, greaterThan(last));
        expect(d.expireAt, t0.add(kLiveTtl));
        last = d.seq;
      }
      expect(ids, {'1_0', '1_1', '1_2', '1_3'});
      // uygulama yeniden açıldı, saat geride: halkadan okunan sıra numarasının üstünden sürer
      final w2 = LiveWriter(ring: 4)..saw(last);
      expect(w2.next(1, 'y', 'u', t0.subtract(const Duration(minutes: 5))).$2.seq, greaterThan(last));
    });

    test('okuyan: ilk partide kendi mesajları da gelir, sonra gelmez; eski sıra numarası atlanır', () {
      final r = LiveReader('me');
      final e = DateTime.utc(2026);
      final first = r.take([LiveDoc(0, 5, 'mine-old', 'me', e), LiveDoc(1, 3, 'g3', 'them', e), LiveDoc(1, 4, 'g4', 'them', e)]);
      expect(first, [(1, 'g3'), (1, 'g4'), (0, 'mine-old')]);
      expect(r.take([LiveDoc(0, 9, 'mine', 'me', e), LiveDoc(1, 4, 'g4', 'them', e), LiveDoc(1, 2, 'old', 'them', e)]), isEmpty);
      expect(r.take([LiveDoc(1, 7, 'g7', 'them', e)]), [(1, 'g7')]);
      expect(LiveDoc.parse({'seat': 1, 'seq': 2, 'd': 'x', 'by': 'u'})!.data, 'x');
      expect(LiveDoc.parse({'seat': 1, 'd': 'x'}), isNull);
    });
  });

  group('bağlantı bildirimleri', () {
    test('bekleniyor → yok → yeniden bağlanıyor → devraldın', () {
      final n = FakeNet(loss: 0);
      final host = peer(n, 0), guest = peer(n, 1);
      final notes = NetNotes();
      expect(notes.update(guest, n.now), NetNote.waiting);
      final hn = NetNotes();
      expect(hn.update(host, n.now), NetNote.waiting);
      for (var t = 0; t < 1000; t += 10) {
        host.publish(t, 's', n.now);
        guest.pump(n.now);
        n.step(10);
      }
      expect(notes.update(guest, n.now), NetNote.none);
      expect(hn.update(host, n.now), NetNote.none);
      n.offline.add(0);
      for (var t = 0; t < 1500; t += 10) {
        n.step(10);
      }
      expect(notes.update(guest, n.now), NetNote.reconnecting);
      while (!guest.checkTakeover(n.now)) {
        n.step(10);
      }
      expect(notes.update(guest, n.now), NetNote.nowHost);
      n.step(3100);
      // eski ev sahibi sessiz: koltuğunda yapay zekâ
      expect(notes.update(guest, n.now), NetNote.botPlaying);
      expect(notes.seat, 0);
    });

    test('misafir: ev sahibi değişince bildirim; bot koltuğu anlık durumdan', () {
      final n = FakeNet(loss: 0);
      final a = peer(n, 0, seats: 3), b = peer(n, 1, seats: 3), c = peer(n, 2, seats: 3);
      final notes = NetNotes();
      for (var t = 0; t < 500; t += 10) {
        a.publish(t, 's', n.now);
        b.pump(n.now);
        c.pump(n.now);
        n.step(10);
      }
      expect(notes.update(c, n.now), NetNote.none);
      n.offline.add(0);
      for (var t = 0; t < 8000; t += 10) {
        b.checkTakeover(n.now);
        if (b.isHost) b.publish(t, 'b', n.now);
        c.pump(n.now);
        n.step(10);
        if (notes.update(c, n.now) == NetNote.hostChanged) break;
      }
      expect(notes.note, NetNote.hostChanged);
      expect(c.host, 1);
    });
  });

  group('çevrimiçi metinler', () {
    test('33 dilin hepsinde var', () {
      expect(Strings.languages.length, 33);
      for (final k in kNetPhraseKeys) {
        expect(kPhrases[k]?.length, kPhraseLanguages.length, reason: k);
        expect(kPhrases[k]!.every((x) => x.trim().isNotEmpty && x.contains('{0}') == k.contains('{0}')), isTrue, reason: k);
      }
      for (final l in Strings.languages) {
        expect(netYou(l), isNotEmpty);
        for (final n in NetNote.values) {
          final s = netNoteText(l, n, 'Ada');
          expect(s.isEmpty, n == NetNote.none, reason: '$l $n');
          expect(s.contains('{0}'), isFalse, reason: '$l $n');
          if (n == NetNote.botPlaying) expect(s, contains('Ada'), reason: l);
          if (l != 'en' && n != NetNote.none) expect(s, isNot(netNoteText('en', n, 'Ada')), reason: '$l $n');
        }
        expect(netSeatLabel(l, 'Ada', bot: true), allOf(startsWith('🤖'), contains('Ada')));
        expect(netSeatLabel(l, 'Ada', bot: false), 'Ada');
      }
      expect(netNoteText('tr', NetNote.reconnecting), 'Yeniden bağlanıyor…');
    });
  });
}
