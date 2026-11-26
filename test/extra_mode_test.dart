// Oyunun kendi ek modu (ör. öğretici): ana ekranda mod kartı olarak görünür
// ve dokununca onaylı stüdyo iskeletinde açılır.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_core/app/app_state.dart';
import 'package:studio_core/app/bootstrap.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/hub.dart';
import 'package:studio_core/app/screens/home.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/app/services/prefs_backend.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/studio_ui.dart';
import 'package:studio_core/core/telemetry.dart';

import 'sample_rules.dart';

GameConfig _game() => GameConfig(
      gameId: 'oyun-blok',
      title: const ['Blok Bulmaca', 'Block Puzzle'],
      tagline: const ['Kısa açıklama', 'Short tagline'],
      seedColor: Colors.teal,
      icon: Icons.extension,
      rules: BlockRules(),
      buildPlay: (_) => const SizedBox(),
      tutorial: const [],
      extraModes: [
        ExtraMode(
          id: 'ogretici',
          title: const ['Öğretici', 'Tutorial'],
          subtitle: const ['Adım adım öğren', 'Learn step by step'],
          icon: Icons.school_rounded,
          builder: (c, lang) => Center(child: Text('ders-$lang')),
        ),
      ],
    );

Future<AppState> _state(String lang) async {
  SharedPreferences.setMockInitialValues({'hub.consent': 'granted'});
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
  final st = await s.stateFor(_game());
  st.save.language = lang;
  st.startup = null;
  return st;
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final ch in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(ch), (call) async => null);
    }
  });

  for (final lang in ['tr', 'en']) {
    testWidgets('ek mod kartı ana ekranda ve açılıyor ($lang)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final st = (await tester.runAsync(() => _state(lang)))!;
      await tester.pumpWidget(ProviderScope(
        overrides: [appStateProvider.overrideWith((ref) => st)],
        child: GameApp(state: st),
      ));
      await _settle(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      final card = find.byKey(const ValueKey('extra-mode-ogretici'));
      await tester.ensureVisible(card);
      await _settle(tester);
      expect(find.descendant(of: card, matching: find.text(lang == 'tr' ? 'Öğretici' : 'Tutorial')), findsOneWidget);
      await tester.tap(card);
      await _settle(tester);
      expect(find.text('ders-$lang'), findsOneWidget);
      expect(find.byType(StudioScaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(st.save.stat('extra_ogretici_opened'), 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });
  }
}
