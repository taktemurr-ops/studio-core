import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/online/online.dart';

void main() {
  group('online (bellek içi arka uç)', () {
    test('hızlı eşleşme: iki oyuncu aynı masaya oturur, hamleler karşıya gider', () async {
      final server = MemoryServer();
      final a = MemoryBackend(server, 'a'), b = MemoryBackend(server, 'b');
      await a.signIn();
      await b.signIn();
      final ma = await a.quickMatch('oyun-tavla', 2, 1000);
      expect(ma.status, MatchStatus.waiting);
      final mb = await b.quickMatch('oyun-tavla', 2, 1000);
      expect(mb.id, ma.id);
      expect(mb.status, MatchStatus.playing);
      expect(ma.mySeat, 0);
      expect(mb.mySeat, 1);
      expect(ma.isHost, isTrue);
      expect(mb.isHost, isFalse);

      final got = <(int, String)>[];
      final sub = mb.moves.listen(got.add);
      await ma.send('42');
      await ma.send('7', asSeat: 1);
      await Future<void>.delayed(Duration.zero);
      expect(got, [(0, '42'), (1, '7')]);
      await sub.cancel();
    });

    test('davet kodu ile katılma, masa dolmadan botla başlatma', () async {
      final server = MemoryServer();
      final a = MemoryBackend(server, 'a'), b = MemoryBackend(server, 'b');
      await a.signIn();
      await b.signIn();
      final m = await a.createMatch('oyun-okey', 4);
      expect(m.private, isTrue);
      expect(await b.joinByCode('YANLIS'), isNull);
      final j = await b.joinByCode(m.code);
      expect(j, isNotNull);
      expect(m.seats.length, 2);
      await m.fillWithBotsAndStart();
      expect(m.status, MatchStatus.playing);
      expect(m.seats.where((s) => s.bot).length, 2);
    });

    test('engellenen oyuncunun masasına eşleşilmez', () async {
      final server = MemoryServer();
      final a = MemoryBackend(server, 'a'), b = MemoryBackend(server, 'b');
      await a.signIn();
      await b.signIn();
      final ma = await a.quickMatch('oyun-batak', 4, 1000);
      await b.block('a');
      final mb = await b.quickMatch('oyun-batak', 4, 1000);
      expect(mb.id, isNot(ma.id));
    });

    test('sohbet ve hediye olayları herkese ulaşır, hediye profile işlenir', () async {
      final server = MemoryServer();
      final a = MemoryBackend(server, 'a'), b = MemoryBackend(server, 'b');
      await a.signIn();
      await b.signIn();
      final ma = await a.createMatch('oyun-okey', 2);
      final mb = (await b.joinByCode(ma.code))!;
      final seen = <TableEvent>[];
      final sub = mb.events.listen(seen.add);
      await ma.say(const TableEvent(0, 'p', 'chat_gg'));
      await ma.say(const TableEvent(0, 'g', 'rose', 1));
      await a.recordGift('b', 'rose');
      await Future<void>.delayed(Duration.zero);
      expect(seen.map((e) => e.kind), ['p', 'g']);
      expect((await a.profileOf('b'))!.gifts['rose'], 1);
      await sub.cancel();
    });

    test('arkadaş kodu, skor tablosu, bulut kayıt, şikâyet', () async {
      final server = MemoryServer();
      final a = MemoryBackend(server, 'a'), b = MemoryBackend(server, 'b');
      final pa = await a.signIn();
      final pb = await b.signIn();
      expect(await a.addFriend(pb.code), isNotNull);
      expect((await b.friends()).single.uid, pa.uid);
      await a.submitScore('d_x_2026-11-22', 500);
      await b.submitScore('d_x_2026-11-22', 800);
      await a.submitScore('d_x_2026-11-22', 300); // düşük skor eskisini silmez
      final top = await a.top('d_x_2026-11-22');
      expect(top.map((e) => e.score), [800, 500]);
      await a.saveBlob('oyun-x', '{"v":1}');
      expect(await a.loadBlob('oyun-x'), '{"v":1}');
      expect(await b.loadBlob('oyun-x'), isNull);
      await b.report('a', 'user_report', matchId: 'm1');
      expect(server.reports.single['target'], 'a');
    });
  });

  group('güvenlik ve lig', () {
    test('küfür süzgeci, bağlantı ve telefon numarası engeli', () {
      expect(filterText('selam amk naber'), 'selam *** naber');
      expect(filterText('götür bunu'), 'götür bunu');
      expect(cleanChat('bak www.site.com 0532 123 45 67'), 'bak *** ***');
      expect(cleanChat('   '), '');
      expect(cleanChat('a' * 300).length, maxChatLength);
    });

    test('Elo: kazanan puan alır, kaybeden kaybeder, lig basamakları', () {
      expect(eloUpdate(1000, 1000, 1), greaterThan(1000));
      expect(eloUpdate(1000, 1000, 0), lessThan(1000));
      expect(eloUpdate(1000, 1000, 0.5), 1000);
      expect(leagueTier(900), 0);
      expect(leagueTier(1700), 4);
    });

    test('ücretli ve ücretsiz hediyeler tanımlı', () {
      expect(giftCatalog.where((g) => g.gems == 0).length, greaterThanOrEqualTo(3));
      expect(giftCatalog.any((g) => g.id == 'rose' && g.gems > 0), isTrue);
    });
  });

  test('zaman aşımı olmadan akışlar kapanır', () async {
    final server = MemoryServer();
    final a = MemoryBackend(server, 'a');
    await a.signIn();
    final m = await a.createMatch('g', 2);
    await m.leave();
    expect(m.dropped, isEmpty);
    await Future<void>.delayed(Duration.zero);
    unawaited(Future<void>.value());
  });
}
