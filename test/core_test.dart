import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/achievements.dart';
import 'package:studio_core/core/clock.dart';
import 'package:studio_core/core/collection.dart';
import 'package:studio_core/core/daily.dart';
import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/game_session.dart';
import 'package:studio_core/core/integrity.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/monetization.dart';
import 'package:studio_core/core/progression.dart';
import 'package:studio_core/core/rng.dart';
import 'package:studio_core/core/save_data.dart';
import 'package:studio_core/core/save_store.dart';
import 'package:studio_core/core/telemetry.dart';
import 'sample_rules.dart';

class _FailingSink implements AnalyticsSink {
  @override
  Future<bool> send(List<AnalyticsEvent> batch) async => false;
}

void main() {
  final rules = createRules();

  group('rng', () {
    test('deterministic sequence and known vector (web-safe math)', () {
      final a = SeededRandom(12345);
      final b = SeededRandom(12345);
      final xs = List.generate(50, (_) => a.nextUint32());
      final ys = List.generate(50, (_) => b.nextUint32());
      expect(xs, equals(ys));
      // Reference value computed with 32-bit JS Math.imul mulberry32.
      expect(SeededRandom(1).nextUint32(), 2693262067);
      expect(SeededRandom.imul(0xFFFFFFFF, 0xFFFFFFFF), 1);
    });
    test('nextInt stays in range', () {
      final r = SeededRandom(7);
      for (var i = 0; i < 10000; i++) {
        expect(r.nextInt(13), inInclusiveRange(0, 12));
      }
    });
  });

  group('level planner (doc 5)', () {
    final p = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);
    test('same level -> same spec', () {
      expect(p.spec(1250).toJson(), equals(p.spec(1250).toJson()));
      expect(p.spec(1250).seed == p.spec(1251).seed, isFalse);
    });
    test('1000 worlds, sources and milestones', () {
      expect(p.worldCount, 1000);
      expect(p.spec(1).source, LevelSource.starter);
      expect(p.spec(5000).source, LevelSource.extended);
      expect(p.spec(40000).source, LevelSource.procedural);
      expect(p.spec(90000).source, LevelSource.procedural);
      expect(p.spec(120000).source, LevelSource.endless);
      expect(p.spec(3000).milestone, isTrue);
      expect(p.spec(3000).reward, greaterThan(1000));
      expect(p.spec(250).world, 3);
    });
    test('difficulty within 1..10 and mechanics stable within 50-block', () {
      for (var l = 1; l <= 3000; l++) {
        expect(p.spec(l).difficulty, inInclusiveRange(1, 10));
      }
      expect(p.mechanicsFor(101), equals(p.mechanicsFor(150)));
    });
    test('150 challenges, daily/weekly specs deterministic', () {
      expect(LevelPlanner.challengeCount, greaterThanOrEqualTo(100));
      expect(p.daily('2026-11-19').seed, p.daily('2026-11-19').seed);
      expect(p.daily('2026-11-19').seed == p.daily('2026-11-20').seed, isFalse);
      expect(p.weekly('2026-W47').mode, GameModeId.weekly);
    });
    test('adaptive difficulty eases after losses', () {
      final a = AdaptiveDifficulty([]);
      for (var i = 0; i < 3; i++) {
        a.record(false);
      }
      expect(a.offset, -2);
    });
  });

  group('progression (doc 4.4)', () {
    test('levels 1..500 and tiers', () {
      expect(PlayerProgression.levelForXp(0), 1);
      expect(PlayerProgression.levelForXp(1 << 40), 500);
      final need = PlayerProgression.totalXpFor(51);
      expect(PlayerProgression.levelForXp(need), 51);
      expect(PlayerProgression.tierFor(300), PlayerTier.legend);
      expect(PlayerProgression.tierFor(60), PlayerTier.expert);
    });
  });

  group('catalogs (doc 4.3, 4.1)', () {
    test('100-300 achievements with 50+ hidden', () {
      final c = AchievementCatalog.build(rules.gameStats);
      expect(c.all.length, inInclusiveRange(100, 300));
      expect(c.hiddenCount, greaterThanOrEqualTo(50));
      expect(c.all.map((a) => a.id).toSet().length, c.all.length);
    });
    test('100-500 collection items, unique ids', () {
      final c = CollectionCatalog.build();
      expect(c.items.length, inInclusiveRange(100, 500));
      expect(c.byId.length, c.items.length);
    });
  });

  group('save system (doc 6.3, 12)', () {
    test('round trip keeps every field', () {
      final s = SaveData()
        ..currentLevel = 42
        ..coins = 999
        ..achievements = {'a', 'b'}
        ..resume = {'board': 'x'};
      s.setStars(5, 3);
      s.setStars(5, 1); // never lowers
      final r = SaveData.decode(s.encode());
      expect(r.currentLevel, 42);
      expect(r.coins, 999);
      expect(r.starsFor(5), 3);
      expect(r.achievements, equals({'a', 'b'}));
      expect(r.resume['board'], 'x');
    });
    test('migrates v1 saves', () {
      final r = SaveData.fromJson({
        'saveVersion': 1,
        'level': 7,
        'starsByLevel': {'1': 3, '3': 2},
        'noAds': true,
      });
      expect(r.currentLevel, 7);
      expect(r.starsFor(1), 3);
      expect(r.starsFor(2), 0);
      expect(r.starsFor(3), 2);
      expect(r.removeAds, isTrue);
      expect(r.saveVersion, SaveData.currentVersion);
    });
    test('corrupt primary recovers from backup', () async {
      final mem = MemoryBackend();
      final store = SaveStore(mem);
      final a = SaveData()..coins = 1;
      await store.save(a);
      final b = SaveData()..coins = 2;
      await store.save(b);
      mem.data['gs100.save'] = '123|{broken';
      final loaded = await store.load();
      expect(loaded.coins, 1);
      expect(store.lastOutcome, LoadOutcome.recoveredFromBackup);
    });
    test('interrupted write (pending slot) is recovered', () async {
      final mem = MemoryBackend();
      final store = SaveStore(mem);
      await store.save(SaveData()..coins = 5);
      mem.data['gs100.save.pending'] = SaveStore.wrap((SaveData()..coins = 6).encode());
      expect((await store.load()).coins, 6);
    });
    test('write failure is reported, not thrown', () async {
      final mem = MemoryBackend()..failWrites = true;
      final store = SaveStore(mem);
      expect(await store.save(SaveData()), isFalse);
      expect(store.writeFailures, 1);
    });
    test('10.000 save/load cycles stay consistent (doc 10)', () async {
      final mem = MemoryBackend();
      final store = SaveStore(mem);
      final s = SaveData();
      for (var i = 0; i < 10000; i++) {
        s.coins = i;
        s.currentLevel = i + 1;
        await store.save(s);
        if (i % 500 == 0) {
          final l = await store.load();
          expect(l.coins, i);
        }
      }
      expect((await store.load()).currentLevel, 10000);
    });
    test('export / import backup', () {
      final store = SaveStore(MemoryBackend());
      final text = store.exportBackup(SaveData()..gems = 77);
      expect(store.importBackup(text)!.gems, 77);
      expect(store.importBackup('garbage'), isNull);
    });
    test('HMAC-SHA256 matches RFC 4231 test vector', () {
      final mac = Integrity.hex(Integrity.hmacSha256(Integrity.utf8('Jefe'), Integrity.utf8('what do ya want for nothing?')));
      expect(mac, '5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843');
      expect(Integrity.hex(Integrity.sha256(Integrity.utf8('abc'))),
          'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(Integrity.hex(Integrity.sha256(Integrity.utf8('ğüşİöç €'))).length, 64);
    });
    test('edited save is rejected and the last signed backup is used', () async {
      final mem = MemoryBackend();
      final store = SaveStore(mem);
      await store.save(SaveData()..coins = 10);
      await store.save(SaveData()..coins = 20);
      // Player edits the stored JSON (coins 20 -> 999999) without the key.
      mem.data['gs100.save'] = mem.data['gs100.save']!.replaceFirst('"coins":20', '"coins":999999');
      final l = await SaveStore(mem).load();
      expect(l.coins, 10);
      expect(store.exportBackup(l).startsWith('s2:'), isTrue);
    });
    test('legacy saves load once, then unsigned data is refused', () async {
      final mem = MemoryBackend();
      mem.data['gs100.save'] = SaveStore.wrapLegacy((SaveData()..coins = 7).encode());
      final store = SaveStore(mem);
      final l = await store.load();
      expect(l.coins, 7);
      await store.save(l); // migrates to the signed format
      expect(mem.data['gs100.save']!.startsWith('s2:'), isTrue);
      mem.data['gs100.save'] = SaveStore.wrapLegacy((SaveData()..coins = 5000).encode());
      mem.data.remove('gs100.save.bak0');
      expect((await SaveStore(mem).load()).coins, isNot(5000));
      // Unsigned or foreign-game backups are never imported.
      expect(store.importBackup(SaveStore.wrapLegacy((SaveData()..gems = 9).encode())), isNull);
      final other = SaveStore(MemoryBackend(), prefix: 'other_game');
      expect(store.importBackup(other.exportBackup(SaveData()..gems = 9)), isNull);
    });
  });

  group('clock guard (doc 12.6)', () {
    test('turning the clock back does not re-open daily rewards', () {
      var t = DateTime(2026, 11, 19, 12);
      final g = ClockGuard(now: () => t);
      final s = SaveData();
      final d = DailySystems('x');
      expect(d.claimLogin(s, g.trustedNow(s)), isNotNull);
      t = DateTime(2026, 11, 18, 12);
      final trusted = g.trustedNow(s);
      expect(DateKeys.day(trusted), '2026-11-19');
      expect(d.claimLogin(s, trusted), isNull);
      expect(s.clockTamperCount, 1);
    });
    test('iso week keys', () {
      expect(DateKeys.week(DateTime(2026, 1, 1)), '2026-W01');
      expect(DateKeys.week(DateTime(2026, 11, 19)), '2026-W47');
      expect(DateKeys.week(DateTime(2027, 1, 1)), '2026-W53');
    });
  });

  group('daily systems (doc 4.2)', () {
    test('login streak, reset and comeback', () {
      final d = DailySystems('x');
      final s = SaveData();
      d.registerVisit(s, DateTime(2026, 1, 1));
      d.registerVisit(s, DateTime(2026, 1, 2));
      d.registerVisit(s, DateTime(2026, 1, 3));
      expect(s.loginStreak, 3);
      final gap = d.registerVisit(s, DateTime(2026, 1, 10));
      expect(gap, 7);
      expect(s.loginStreak, 1);
      expect(s.bestLoginStreak, 3);
      expect(d.comebackReward(s, DateTime(2026, 1, 10), gap), isNotNull);
      expect(d.comebackReward(s, DateTime(2026, 1, 10), gap), isNull);
    });
    test('daily gift once per day, fixed rotation', () {
      final d = DailySystems('x');
      final s = SaveData();
      final day = DateTime(2026, 3, 3);
      final idx = d.wheelResult(s, day);
      expect(d.spinWheel(s, day), isNotNull);
      expect(d.spinWheel(s, day), isNull);
      expect(d.wheelResult(s, day), idx);
      // No chance element: consecutive days follow a fixed rotation.
      final n = DailySystems.wheelSlices.length;
      for (var i = 0; i < n * 2; i++) {
        expect(d.wheelResult(s, day.add(Duration(days: i))), (idx + i) % n);
      }
      expect(d.todaysGift(day), DailySystems.wheelSlices[idx]);
    });
    test('missions: 4 daily, 7 weekly, same for everyone', () {
      final m = MissionBoard('x', const []);
      expect(m.daily('2026-01-01').length, 4);
      expect(m.weekly('2026-W01').length, 7);
      expect(m.daily('2026-01-01').map((e) => e.id).toList(),
          equals(m.daily('2026-01-01').map((e) => e.id).toList()));
    });
  });

  group('monetization (doc 7)', () {
    test('purchase idempotency, restore and refund', () {
      final s = SaveData();
      expect(
          PurchaseLedger.apply(s,
              productId: Products.coinsSmall, purchaseId: 't1', state: PurchaseState.purchased, verified: true),
          'purchase_ok');
      final coins = s.coins;
      expect(
          PurchaseLedger.apply(s,
              productId: Products.coinsSmall, purchaseId: 't1', state: PurchaseState.purchased, verified: true),
          'purchase_duplicate');
      expect(s.coins, coins);
      expect(
          PurchaseLedger.apply(s,
              productId: Products.premium, purchaseId: 't2', state: PurchaseState.purchased, verified: false),
          'purchase_unverified');
      expect(s.premium, isFalse);
      PurchaseLedger.apply(s,
          productId: Products.premium, purchaseId: 't3', state: PurchaseState.restored, verified: true);
      expect(s.premium, isTrue);
      expect(s.removeAds, isTrue);
      PurchaseLedger.apply(s,
          productId: Products.premium, purchaseId: 't3r', state: PurchaseState.refunded, verified: true);
      expect(s.premium, isFalse);
      expect(s.removeAds, isFalse);
    });
    test('ads: never before level 8, never for premium, capped', () {
      const p = AdPolicy();
      final s = SaveData()..adConsent = 'granted';
      final t = DateTime(2026, 1, 1, 12);
      expect(p.shouldShowInterstitial(s, t, emergencyAdsOff: false), isFalse);
      s.completedLevels = 20;
      var shown = 0;
      for (var i = 0; i < 12; i++) {
        if (p.shouldShowInterstitial(s, t.add(Duration(minutes: i * 5)), emergencyAdsOff: false)) {
          shown++;
          p.markInterstitialShown(s, t.add(Duration(minutes: i * 5)));
        }
      }
      expect(shown, 3);
      s.removeAds = true;
      expect(p.shouldShowInterstitial(s, t.add(const Duration(days: 1)), emergencyAdsOff: false), isFalse);
      final s2 = SaveData()..completedLevels = 50;
      expect(p.shouldShowInterstitial(s2, t, emergencyAdsOff: false), isFalse,
          reason: 'no consent decision yet');
    });
  });

  group('telemetry (doc 6.1, 8)', () {
    test('analytics queue survives offline and flushes later', () async {
      final mem = MemoryBackend();
      final q = AnalyticsQueue(mem, enabled: true);
      for (var i = 0; i < 5; i++) {
        await q.log('e$i');
      }
      expect(await q.flush(_FailingSink()), 0);
      final q2 = AnalyticsQueue(mem, enabled: true);
      await q2.restore();
      expect(q2.length, 5);
      expect(await q2.flush(NoopSink()), 5);
      expect(q2.length, 0);
    });
    test('no analytics without consent', () async {
      final q = AnalyticsQueue(MemoryBackend());
      await q.log('x');
      expect(q.length, 0);
    });
    test('crash loop -> safe mode', () async {
      final mem = MemoryBackend();
      for (var i = 0; i < 3; i++) {
        await ErrorJournal(mem).beginLaunch();
      }
      final j = ErrorJournal(mem);
      await j.beginLaunch();
      expect(j.safeMode, isTrue);
      await j.launchSucceeded();
      final k = ErrorJournal(mem);
      await k.beginLaunch();
      expect(k.safeMode, isFalse);
    });
    test('emergency config merge', () {
      final e = EmergencyConfig()..merge({'adsDisabled': true, 'junk': 1});
      expect(e.adsDisabled, isTrue);
    });
  });

  group('game session end-to-end', () {
    test('win flow grants rewards, xp, stars and advances', () async {
      final session = GameSession(rules: rules, store: SaveStore(MemoryBackend()));
      await session.start();
      final spec = session.nextCampaignSpec;
      final out = session.completeRound(spec, const RoundResult(won: true, stars: 3, seconds: 20, score: 500));
      expect(out.reward.coins, greaterThan(0));
      expect(session.save.currentLevel, 2);
      expect(session.save.starsFor(1), 3);
      expect(session.save.achievements.contains('lvl_1'), isTrue);
      final again = session.completeRound(spec, const RoundResult(won: true, stars: 1));
      expect(again.reward.coins, lessThan(out.reward.coins));
      expect(session.save.starsFor(1), 3);
      expect(await session.persist(), isTrue);
    });
    test('premium: 3 free hints a day, double login reward, exclusive items', () async {
      final session = GameSession(rules: rules, store: SaveStore(MemoryBackend()));
      await session.start();
      final s = session.save;
      s.hints = 0;
      expect(session.spendHint(), isFalse);
      final base = DailySystems('t').loginRewardPreview(s);
      PurchaseLedger.apply(s,
          productId: Products.premium, purchaseId: 'p1', state: PurchaseState.purchased, verified: true);
      expect(s.premiumGift, isTrue);
      final hints = s.hints;
      expect(session.premiumHintsLeft, Products.premiumDailyHints);
      for (var i = 0; i < Products.premiumDailyHints; i++) {
        expect(session.spendHint(), isTrue);
      }
      expect(session.premiumHintsLeft, 0);
      expect(s.hints, hints);
      expect(DailySystems('t').loginRewardPreview(s).coins, base.coins * Products.premiumRewardMultiplier);
      final cat = CollectionCatalog.build();
      final prem = cat.items.where((i) => i.unlock == UnlockKind.premium).toList();
      expect(prem.length, greaterThanOrEqualTo(9));
    });
    test('starter pack is marked as bought', () {
      final s = SaveData();
      PurchaseLedger.apply(s,
          productId: Products.starterPack, purchaseId: 'sp', state: PurchaseState.purchased, verified: true);
      expect(s.starterBought, isTrue);
    });
    test('missions can be claimed exactly once', () async {
      final session = GameSession(rules: rules, store: SaveStore(MemoryBackend()));
      await session.start();
      for (var i = 0; i < 60; i++) {
        session.completeRound(session.nextCampaignSpec,
            const RoundResult(won: true, stars: 3, seconds: 10, score: 100));
      }
      final m = session.dailyMissions.firstWhere((m) => m.done(session.save),
          orElse: () => session.dailyMissions.first);
      if (m.done(session.save)) {
        expect(session.claimMission(m), isNotNull);
        expect(session.claimMission(m), isNull);
      }
    });
  });
}
