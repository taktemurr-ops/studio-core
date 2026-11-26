import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_core/app/app_state.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/global_daily_ui.dart';
import 'package:studio_core/app/hub.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/app/services/prefs_backend.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/tournament_ui.dart';
import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/global_daily.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/telemetry.dart';
import 'package:studio_core/core/tournament.dart';

import 'sample_rules.dart';

class _DailyRules extends BlockRules {
  @override
  bool get globalDaily => true;
}

class _DuoRules extends BlockRules {
  @override
  int get localPlayers => 2;
}

GameConfig _game(String id, String title, GameRules rules) => GameConfig(
      gameId: id,
      title: [title, title],
      tagline: const ['', ''],
      seedColor: Colors.teal,
      icon: Icons.extension,
      rules: rules,
      buildPlay: (_) => const SizedBox(),
      tutorial: const [],
    );

Tournament _t(int n, List<TGame> games, {int rounds = 1}) => Tournament(
    seed: 7, players: [for (var i = 0; i < n; i++) TPlayer('P$i', i)], games: games, rounds: rounds);

Future<HubServices> _services() async {
  SharedPreferences.setMockInitialValues({'hub.consent': 'granted', 'hub.guide.v1': '1'});
  final backend = await PrefsBackend.create();
  final s = HubServices(
    backend: backend,
    errors: ErrorJournal(backend),
    analytics: AnalyticsQueue(backend),
    emergency: EmergencyConfig(),
    perf: PerformanceMonitor(),
    ads: NoAdsService(),
    purchases: NoPurchaseService(),
    audio: AudioService(),
  );
  await s.loadShared();
  return s;
}

void main() {
  group('fikstür ve puanlama', () {
    test('sırayla oyunda 3/2/1 puan, eşitler aynı sırayı paylaşır, vazgeçen 0', () {
      final t = _t(5, const [TGame('a', 0)]);
      expect(t.valid, isTrue);
      expect(t.schedule.length, 1);
      final order = t.schedule.first.players;
      expect(order.toSet().length, 5);
      final scores = {
        order[0]: const TScore(won: true, score: 100, ms: 9000),
        order[1]: const TScore(won: true, score: 100, ms: 9000),
        order[2]: const TScore(won: true, score: 80),
        order[3]: const TScore(won: false, score: 500),
        order[4]: const TScore.gaveUp(),
      };
      for (var i = 0; i < 5; i++) {
        expect(t.player, order[i]);
        final done = t.submitTurn(scores[order[i]]!);
        expect(done, i == 4);
      }
      expect(t.finished, isTrue);
      final pts = t.totals;
      expect(pts[order[0]], 3);
      expect(pts[order[1]], 3);
      expect(pts[order[2]], 1, reason: 'iki kişi önde: 3. sıra');
      expect(pts[order[3]], 0);
      expect(pts[order[4]], 0);
      expect(t.champions.toSet(), {order[0], order[1]});
    });

    test('birlikte oyun: kalabalık aile gruplara ayrılır, tek kalan bay geçer', () {
      final t = _t(5, const [TGame('duo', 2)], rounds: 2);
      // 5 kişi, 2 kişilik oyun: tur başına 3 grup (2+2+1), bay oynanmaz.
      expect(t.schedule.length, 6);
      expect(t.schedule.where((m) => m.players.length == 1).length, 2);
      var plays = 0;
      while (!t.finished) {
        final m = t.match!;
        expect(m.players.length, 2);
        expect(t.player, isNull);
        t.submitTogether(plays.isEven ? m.players.first : -1);
        plays++;
      }
      expect(plays, 4);
      expect(t.totals.reduce((a, b) => a + b), 3 * 2 + 2 * 2 + 2 * 1);
      // Her turda başka biri bay geçer.
      final byes = [for (final m in t.schedule) if (m.players.length == 1) m.players.single];
      expect(byes[0], isNot(byes[1]));
    });

    test('aynı karşılaşmada herkese aynı bölüm; mod ve tohum', () {
      final t = _t(3, const [TGame('a', 0), TGame('b', 4)], rounds: 2);
      final m0 = t.schedule[0], m1 = t.schedule[1];
      expect(t.specFor(m0).seed, t.specFor(m0).seed);
      expect(t.specFor(m0).seed, isNot(t.specFor(m1).seed));
      expect(t.specFor(m0).mode, GameModeId.practice);
      expect(t.specFor(m1).mode, GameModeId.versus);
      expect(t.schedule[2].players.first, isNot(m0.players.first), reason: 'başlayan oyuncu döner');
    });

    test('kayıt/geri yükleme yarıda kalan turnuvayı aynen sürdürür', () {
      final t = _t(3, const [TGame('a', 0), TGame('duo', 2)], rounds: 2);
      t.submitTurn(const TScore(won: true, score: 10));
      final j = jsonDecode(jsonEncode(t.toJson()));
      final r = Tournament.fromJson(j)!;
      expect(r.matchIndex, t.matchIndex);
      expect(r.turn, 1);
      expect(r.player, t.player);
      expect(r.awarded, t.awarded);
      while (!t.finished) {
        if (t.game!.together) {
          t.submitTogether(t.match!.players.first);
          r.submitTogether(r.match!.players.first);
        } else {
          t.submitTurn(const TScore(won: true, score: 5));
          r.submitTurn(const TScore(won: true, score: 5));
        }
      }
      expect(r.finished, isTrue);
      expect(r.totals, t.totals);
      expect(Tournament.fromJson({'v': 2}), isNull);
      expect(Tournament.fromJson('x'), isNull);
    });

    test('geçersiz kurulum ve takma ad temizliği', () {
      expect(_t(1, const [TGame('a', 0)]).valid, isFalse);
      expect(_t(9, const [TGame('a', 0)]).valid, isFalse);
      expect(_t(3, const []).valid, isFalse);
      expect(TPlayer.clean('  Çok\nuzun bir takma ad burada  '), 'Çok uzun bir t');
    });
  });

  testWidgets('turnuva ekranı: kurulum → sırayla iki oyuncu → şampiyon', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final services = (await tester.runAsync(_services))!;
    final games = [_game('oyun-a', 'Bloklar', BlockRules()), _game('oyun-duo', 'İkili', _DuoRules())];
    for (final g in games) {
      await tester.runAsync(() => services.stateFor(g));
    }
    var played = 0;
    Future<RoundResult?> fake(AppState st, LevelSpec spec, int players) async {
      played++;
      return RoundResult(won: true, score: played == 1 ? 50 : 80, seconds: 30);
    }

    await tester.pumpWidget(MaterialApp(
      home: TournamentPage(
        games: games,
        stateFor: services.stateFor,
        play: fake,
        backend: services.backend,
        lang: 'tr',
        titleOf: (g) => g.title.first,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byKey(const ValueKey('tn-name-0')), 'Ali');
    await tester.enterText(find.byKey(const ValueKey('tn-name-1')), 'Ayşe');
    await tester.ensureVisible(find.byKey(const ValueKey('tn-game-oyun-a')));
    await tester.tap(find.byKey(const ValueKey('tn-game-oyun-a')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('tn-start')));
    await tester.tap(find.byKey(const ValueKey('tn-start')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const ValueKey('tn-pass')), findsOneWidget);
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const ValueKey('tn-ready')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(played, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const ValueKey('tn-champion')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('Günün Bulmacası sayfası: oyna → sonuç kaydedilir, seri başlar', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final services = (await tester.runAsync(_services))!;
    final games = [_game('oyun-g1', 'Bir', _DailyRules()), _game('oyun-g2', 'İki', _DailyRules()), _game('oyun-g3', 'Üç', BlockRules())];
    for (final g in games) {
      await tester.runAsync(() => services.stateFor(g));
    }
    final eligible = GlobalDailyHubPage.eligible(games);
    expect(eligible.map((g) => g.gameId), ['oyun-g1', 'oyun-g2']);
    String? playedDay;
    Future<RoundResult?> fake(AppState st, LevelSpec spec, int players) async {
      playedDay = st.globalDailyDay;
      expect(spec.seed, st.config.rules.globalDailySpec(playedDay!).seed);
      const r = RoundResult(won: true, score: 10, seconds: 42, moves: 17);
      st.finishRound(spec, r, elapsedMs: 42000);
      return r;
    }

    await tester.pumpWidget(MaterialApp(
      home: GlobalDailyHubPage(
        games: eligible,
        stateFor: services.stateFor,
        play: fake,
        backend: services.backend,
        lang: 'tr',
        titleOf: (g) => g.title.first,
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('gd-featured')));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(playedDay, GlobalDaily.utcDay(DateTime.now()));
    final store = GlobalDailyStore.of(services.backend);
    final feat = GlobalDaily.featured(eligible.map((g) => g.gameId), playedDay!)!;
    final e = store.result(feat, playedDay!);
    expect(e, isNotNull);
    expect(e!.ms, 42000);
    expect(e.moves, 17);
    expect(store.streak(playedDay!), 1);
    expect(find.byKey(const ValueKey('gd-share')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
