import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_core/app/approved_hub.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/hub.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/app/services/prefs_backend.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/core/telemetry.dart';

import 'sample_rules.dart';

GameConfig _game(String id, String tr, Color c) => GameConfig(
      gameId: id,
      title: [tr, tr],
      tagline: const ['Kısa açıklama', 'Short tagline'],
      seedColor: c,
      icon: Icons.extension,
      rules: BlockRules(),
      buildPlay: (_) => const SizedBox(),
      tutorial: const [],
    );

HubConfig _hub() {
  final games = [
    _game('oyun-a', 'Çiftlik', Colors.green),
    _game('oyun-b', 'Şehir Kurma', Colors.blue),
    _game('oyun-c', 'Fabrika', Colors.orange),
    _game('oyun-d', 'Arı Kovanı', Colors.amber),
    _game('oyun-e', 'Çay Bahçesi', Colors.teal),
  ];
  return HubConfig(
    hubId: 'merkez-deneme',
    title: const ['Boşta ve Simülasyon', 'Idle & Simulation'],
    tagline: const ['Üret, geliştir, otomatik kazançla imparatorluğunu büyüt!', 'Build and grow!'],
    seedColor: Colors.indigo,
    icon: Icons.location_city,
    games: games,
    sections: const [
      HubSection(title: ['Doğa', 'Nature'], ids: ['oyun-a', 'oyun-d']),
      HubSection(title: ['Kasaba', 'Town'], ids: ['oyun-b', 'oyun-c']),
      HubSection(title: ['Mutfak', 'Kitchen'], ids: ['oyun-e']),
    ],
  );
}

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
  for (final lang in ['tr', 'en', 'ar']) {
    for (final blocks in const [
      [ApprovedBlock.currency, ApprovedBlock.growth, ApprovedBlock.featured],
      [ApprovedBlock.search, ApprovedBlock.chips, ApprovedBlock.featured, ApprovedBlock.progress],
      [ApprovedBlock.dailyChallenge, ApprovedBlock.brainStats, ApprovedBlock.featured],
      [ApprovedBlock.weeklyContest, ApprovedBlock.categoryTiles, ApprovedBlock.scoreRank, ApprovedBlock.playNow],
      [ApprovedBlock.featured, ApprovedBlock.categories, ApprovedBlock.weeklyQuest, ApprovedBlock.dailyReward, ApprovedBlock.campaign],
    ]) {
      testWidgets('onaylı merkez ($lang, ${blocks.first.name}) taşmadan açılır, sekmeler gezilir', (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final services = await tester.runAsync(_services);
        final style = ApprovedHubStyle(
          blocks: blocks,
          featured: const ['oyun-a', 'oyun-b', 'oyun-c'],
          challengeGameId: 'oyun-e',
          categoryTiles: const [
            ApprovedCategory(title: ['Doğa', 'Nature'], icon: Icons.public, color: Colors.blue, ids: ['oyun-a']),
            ApprovedCategory(title: ['Kasaba', 'Town'], icon: Icons.science, color: Colors.purple, ids: ['oyun-b']),
            ApprovedCategory(title: ['Mutfak', 'Kitchen'], icon: Icons.account_balance, color: Colors.orange, ids: ['oyun-e']),
            ApprovedCategory(title: ['Hepsi', 'All'], icon: Icons.sports_soccer, color: Colors.green, ids: ['oyun-c']),
          ],
        );
        await tester.pumpWidget(MaterialApp(
          home: ApprovedHubShell(hub: _hub(), style: style, services: services!, lang: lang),
        ));
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        expect(find.byType(ApprovedHubShell), findsOneWidget);
        // Oyunlar sekmesi.
        await tester.tap(find.byIcon(Icons.sports_esports_rounded).last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        // Ana sayfaya dön.
        await tester.tap(find.byIcon(Icons.home_rounded).last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 2));
      });
    }
  }
}
