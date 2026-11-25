import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/core/arcade.dart';
import 'package:studio_core/core/arcade_duel.dart';
import 'package:studio_core/core/net_sync.dart';
import 'package:studio_core/online/online.dart';
import 'package:studio_core/online/online_service.dart';

/// Gecikmeli, kayıplı ve sırasız sahte ağ: her mesaj gönderen dışındaki
/// bütün koltuklara gider.
class FakeNet {
  final math.Random r;
  final double loss;
  final int minMs, maxMs;
  int now = 0;
  final List<(int, int, int, String)> _q = []; // teslim anı, alıcı, gönderen, veri
  final Map<int, NetSync> peers = {};
  final Set<int> offline = {};
  int sent = 0;

  FakeNet({int seed = 1, this.loss = 0, this.minMs = 40, this.maxMs = 160}) : r = math.Random(seed);

  void Function(String) sender(int seat) => (d) {
        if (offline.contains(seat)) return;
        sent++;
        for (final to in peers.keys) {
          if (to == seat) continue;
          if (r.nextDouble() < loss) continue;
          _q.add((now + minMs + r.nextInt(maxMs - minMs + 1), to, seat, d));
        }
      };

  void step(int ms) {
    now += ms;
    final due = _q.where((m) => m.$1 <= now).toList()..sort((a, b) => a.$1.compareTo(b.$1));
    _q.removeWhere((m) => m.$1 <= now);
    for (final m in due) {
      if (offline.contains(m.$2)) continue;
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
      expect(count, inInclusiveRange(12, 13)); // ~12,5 Hz
      count = 0;
      for (var t = 0; t < 3000; t += 10) {
        if (host.publish(t, 'same', n.now, changed: false)) count++;
        n.step(10);
      }
      expect(count, inInclusiveRange(2, 4)); // yalnızca saniyede bir
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
      expect(replay, [(0, 'S|0|1|||x'), (1, 'I|0||1,2,3,0,0'), (0, 'S|0|2|||y')]);
      await sr.cancel();
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
}
