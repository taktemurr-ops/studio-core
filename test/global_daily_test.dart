import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/global_daily.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/play_texts.dart';
import 'package:studio_core/core/save_store.dart' as kv;
import 'package:studio_core/core/strings.dart';
import 'package:studio_core/online/online.dart' as net;

import 'sample_rules.dart';

class _DailyRules extends BlockRules {
  @override
  bool get globalDaily => true;
}

void main() {
  group('UTC günü ve ortak bölüm', () {
    test('saat diliminden bağımsız UTC günü ve numara', () {
      expect(GlobalDaily.utcDay(DateTime.utc(2026, 11, 26, 23, 59)), '2026-11-26');
      expect(GlobalDaily.utcDay(DateTime.utc(2026, 11, 27, 0, 1)), '2026-11-27');
      expect(GlobalDaily.number('2026-01-01'), 1);
      expect(GlobalDaily.number('2026-11-26'), 330);
      expect(GlobalDaily.shift('2026-12-31', 1), '2027-01-01');
      expect(GlobalDaily.shift('2026-03-01', -1), '2026-02-28');
      expect(GlobalDaily.untilNext(DateTime.utc(2026, 11, 26, 22)).inHours, 2);
    });

    test('herkese aynı, güne ve oyuna göre farklı, belirlenimci bölüm', () {
      final a = GlobalDaily.defaultSpec('oyun-sudoku', '2026-11-26');
      final b = GlobalDaily.defaultSpec('oyun-sudoku', '2026-11-26');
      expect(a.seed, b.seed);
      expect(a.difficulty, b.difficulty);
      expect(a.mode, GameModeId.daily);
      expect(GlobalDaily.defaultSpec('oyun-sudoku', '2026-11-27').seed, isNot(a.seed));
      expect(GlobalDaily.defaultSpec('oyun-kakuro', '2026-11-26').seed, isNot(a.seed));
      for (var d = 0; d < 14; d++) {
        final k = GlobalDaily.defaultDifficulty(GlobalDaily.shift('2026-11-23', d));
        expect(k, inInclusiveRange(4, 7));
      }
      final rules = _DailyRules();
      expect(BlockRules().globalDaily, isFalse);
      expect(rules.globalDaily, isTrue);
      expect(rules.globalDailySpec('2026-11-26').seed, GlobalDaily.defaultSpec(rules.gameId, '2026-11-26').seed);
      // Motor bölümü üretebilir ve doğrular.
      final g = rules.build(rules.globalDailySpec('2026-11-26'));
      expect(g.validation.ok, isTrue);
    });

    test('tablo adı, sıralama anahtarı, günün seçkisi', () {
      expect(GlobalDaily.board('oyun-sudoku', '2026-11-26'), 'oyun-sudoku_2026-11-26');
      expect(GlobalDaily.board('oyun-kelime-avi', '2026-11-26', lang: 'tr'), 'oyun-kelime-avi-tr_2026-11-26');
      expect(RegExp(r'^[a-z0-9-]{1,80}_[0-9]{4}-[0-9]{2}-[0-9]{2}$').hasMatch(GlobalDaily.board('oyun-a', '2026-11-26', lang: 'fil')), isTrue);
      expect(GlobalDaily.sortKey(DailyRank.time, 60000, 10, 0) < GlobalDaily.sortKey(DailyRank.time, 60000, 11, 0), isTrue);
      expect(GlobalDaily.sortKey(DailyRank.time, 59000, 900, 0) < GlobalDaily.sortKey(DailyRank.time, 60000, 1, 0), isTrue);
      expect(GlobalDaily.sortKey(DailyRank.score, 0, 0, 900) < GlobalDaily.sortKey(DailyRank.score, 0, 0, 800), isTrue);
      final ids = ['c', 'a', 'b'];
      expect(GlobalDaily.featured(ids, '2026-11-26'), GlobalDaily.featured(['b', 'c', 'a'], '2026-11-26'));
      expect(GlobalDaily.featured(const [], '2026-11-26'), isNull);
      expect(GlobalDaily.clock(83000), '1:23');
      expect(GlobalDaily.clock(3725000), '1:02:05');
    });

    test('paylaşım metni bulmacayı ele vermez', () {
      final e = DailyEntry(gameId: 'oyun-sudoku', day: '2026-11-26', ms: 83000, moves: 41);
      final s = GlobalDaily.shareText(
          title: 'Günün Bulmacası', gameTitle: 'Sudoku', e: e, lastWeek: [true, false, true, true, true, true, true], streak: 5);
      expect(s, contains('#330'));
      expect(s, contains('1:23'));
      expect(s, contains('41'));
      expect(s, contains('🔥5'));
      expect(s, contains('🌟'));
      expect(s.split('\n').length, 3);
      final sc = GlobalDaily.shareText(
          title: 'Daily', gameTitle: 'Speed', e: DailyEntry(gameId: 'x', day: '2026-11-26', ms: 60000, score: 950, rank: DailyRank.score),
          lastWeek: [false, true], streak: 1);
      expect(sc, contains('950'));
      expect(sc, isNot(contains('🔥')));
    });
  });

  group('yerel kayıt', () {
    test('günün ilk sonucu, seri, en iyi seri ve kalıcılık', () async {
      final b = kv.MemoryBackend();
      final s = GlobalDailyStore(b);
      await s.load();
      expect(await s.record(DailyEntry(gameId: 'g1', day: '2026-11-24', ms: 5000)), isTrue);
      expect(await s.record(DailyEntry(gameId: 'g1', day: '2026-11-24', ms: 3000)), isFalse);
      expect(s.result('g1', '2026-11-24')!.ms, 5000);
      await s.record(DailyEntry(gameId: 'g2', day: '2026-11-25', ms: 5000));
      await s.record(DailyEntry(gameId: 'g1', day: '2026-11-25', ms: 5000));
      expect(s.streak('2026-11-25'), 2);
      expect(s.streak('2026-11-26'), 2, reason: 'bugün henüz çözülmedi, seri sürüyor');
      expect(s.streak('2026-11-27'), 0);
      expect(s.solvedOn('2026-11-25'), 2);
      expect(s.best, 2);
      expect(s.lastDays('2026-11-26', 3), [true, true, false]);
      final s2 = GlobalDailyStore(b);
      await s2.load();
      expect(s2.streak('2026-11-25'), 2);
      expect(s2.best, 2);
      expect(s2.result('g2', '2026-11-25'), isNotNull);
      expect(identical(GlobalDailyStore.of(b), GlobalDailyStore.of(b)), isTrue);
    });

    test('çevrimdışı sonuçlar bekler ve sonra gönderilir', () async {
      final s = GlobalDailyStore(kv.MemoryBackend());
      await s.record(DailyEntry(gameId: 'g1', day: '2026-11-25', ms: 5000));
      await s.record(DailyEntry(gameId: 'g2', day: '2026-11-25', ms: 7000));
      expect(s.pending.length, 2);
      var online = false;
      final sent = <String>[];
      Future<bool> send(DailyEntry e) async {
        if (!online) return false;
        sent.add(e.key);
        return true;
      }

      expect(await s.sync(send), 0);
      expect(s.pending.length, 2);
      online = true;
      expect(await s.sync(send), 2);
      expect(s.pending, isEmpty);
      expect(sent.length, 2);
    });

    test('eski sonuçlar budanır, bozuk kayıt sorun çıkarmaz', () async {
      final b = kv.MemoryBackend();
      final s = GlobalDailyStore(b);
      await s.record(DailyEntry(gameId: 'g', day: '2026-01-01', ms: 5000));
      await s.record(DailyEntry(gameId: 'g', day: '2026-11-26', ms: 5000));
      expect(s.result('g', '2026-01-01'), isNull);
      b.data[GlobalDailyStore.storageKey] = '{bozuk';
      final s2 = GlobalDailyStore(b);
      await s2.load();
      expect(s2.streak('2026-11-26'), 0);
    });
  });

  group('çevrimiçi sıralama (bellek sunucusu)', () {
    test('süreye göre sıralanır, günün ilk sonucu kalır', () async {
      final server = net.MemoryServer();
      final a = net.MemoryBackend(server, 'a'), b = net.MemoryBackend(server, 'b'), c = net.MemoryBackend(server, 'c');
      await a.signIn();
      await b.signIn();
      await c.signIn();
      const board = 'oyun-sudoku_2026-11-26';
      await a.submitDailyResult(board, const net.DailyScore('a', '', 0, 90000, 30, 0, 't'));
      await b.submitDailyResult(board, const net.DailyScore('b', '', 0, 60000, 50, 0, 't'));
      await c.submitDailyResult(board, const net.DailyScore('c', '', 0, 60000, 40, 0, 't'));
      await a.submitDailyResult(board, const net.DailyScore('a', '', 0, 1000, 1, 0, 't'));
      final top = await a.dailyTop(board);
      expect(top.map((e) => e.uid).toList(), ['c', 'b', 'a']);
      expect(top.last.ms, 90000);
      final m = await a.createMatch('oyun-x', 3);
      expect(m.size, 3);
    });
  });

  test('metinler 33 dilde, yer tutucular eksiksiz', () {
    expect(Strings.languages.length, 33);
    final ph = RegExp(r'\{\w+\}');
    for (final e in kPlayTx.entries) {
      expect(e.value.length, 33, reason: e.key);
      final want = ph.allMatches(e.value[1]).map((m) => m.group(0)).toSet();
      for (var i = 0; i < 33; i++) {
        expect(e.value[i].trim(), isNotEmpty, reason: '${e.key} ${Strings.languages[i]}');
        expect(ph.allMatches(e.value[i]).map((m) => m.group(0)).toSet(), want, reason: '${e.key} ${Strings.languages[i]}');
      }
    }
    expect(playTx('tn_pass', 'tr', {'name': 'Ali'}), 'Cihazı ver: Ali');
    expect(playTx('gd_streak', 'en', {'n': 3}), '3-day streak');
  });
}
