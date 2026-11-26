// Onaylı tasarımın oyun içine taşınması: merkezin paleti oyun ekranlarına
// geçer, ekranlar taşmadan açılır (sağdan sola ve tablet dahil), renkler
// okunur kalır.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_core/app/app_state.dart';
import 'package:studio_core/app/approved_hub.dart';
import 'package:studio_core/app/bootstrap.dart';
import 'package:studio_core/app/game_api.dart';
import 'package:studio_core/app/hub.dart';
import 'package:studio_core/app/play_kit.dart';
import 'package:studio_core/app/screens/home.dart';
import 'package:studio_core/app/screens/levels.dart';
import 'package:studio_core/app/screens/onboarding.dart';
import 'package:studio_core/app/screens/settings.dart';
import 'package:studio_core/app/screens/shop.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/app/services/prefs_backend.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/studio_ui.dart';
import 'package:studio_core/app/widgets.dart';
import 'package:studio_core/core/daily.dart';
import 'package:studio_core/core/strings.dart';
import 'package:studio_core/core/telemetry.dart';

import 'sample_rules.dart';

const _hubLook = StudioLook(
  background: [Color(0xFF6E1A2A), Color(0xFF4A1020), Color(0xFF2A0812)],
  accent: Color(0xFFFFB347),
  card: Color(0xFF8A2238),
  play: Color(0xFFFF8A1F),
);

GameConfig _game() => GameConfig(
  gameId: 'oyun-blok',
  title: const ['Blok Bulmaca', 'Block Puzzle'],
  tagline: const ['Kısa açıklama', 'Short tagline'],
  seedColor: Colors.teal,
  icon: Icons.extension,
  rules: BlockRules(),
  buildPlay: (_) => const SizedBox(),
  tutorial: const [],
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

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Widget _game0(AppState st, {StudioLook? look}) {
  final app = ProviderScope(
    overrides: [appStateProvider.overrideWith((ref) => st)],
    child: GameApp(state: st),
  );
  return look == null ? app : StudioLookScope(look: look, child: app);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
}

void main() {
  // Ses eklentisi testte yok: kanallar sessizce yanıtlanır.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final ch in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(ch), (call) async => null);
    }
  });

  group('palet', () {
    test('oyun renginden türeyen palet koyu ve okunur', () {
      for (final seed in [
        Colors.teal,
        Colors.amber,
        Colors.white,
        Colors.black,
        Colors.pink,
        const Color(0xFF3D5AFE),
      ]) {
        final l = StudioLook.fromSeed(seed);
        expect(l.base.computeLuminance(), lessThan(0.05), reason: '$seed zemini koyu olmalı');
        expect(_contrast(Colors.white, l.base), greaterThanOrEqualTo(7));
        expect(_contrast(l.onAccent, l.accent), greaterThanOrEqualTo(4.5), reason: '$seed vurgu üstü yazı');
        expect(_contrast(l.onPlay, l.play), greaterThanOrEqualTo(3), reason: '$seed oyna düğmesi');
      }
    });

    test('tema uzantısı ve merkez stilinden dönüşüm', () {
      final theme = buildStudioTheme(_hubLook);
      expect(theme.extension<StudioLook>(), _hubLook);
      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.primary, _hubLook.accent);
      const style = ApprovedHubStyle(accent: Color(0xFF00FF00), play: Color(0xFF0000FF));
      expect(style.look.accent, const Color(0xFF00FF00));
      expect(style.look.play, const Color(0xFF0000FF));
      expect(style.look.background, style.background);
      final mid = _hubLook.lerp(const StudioLook(), 0.5);
      expect(mid.background.length, 3);
    });
  });

  for (final lang in ['tr', 'en', 'ar']) {
    for (final tablet in [false, true]) {
      testWidgets('oyun ekranları merkez paletiyle açılır ($lang, ${tablet ? 'tablet' : 'telefon'})', (tester) async {
        tester.view.physicalSize = tablet ? const Size(2560, 1600) : const Size(1080, 2340);
        tester.view.devicePixelRatio = tablet ? 2 : 3;
        addTearDown(tester.view.reset);
        final st = (await tester.runAsync(() => _state(lang)))!;
        await tester.pumpWidget(_game0(st, look: _hubLook));
        await _settle(tester);
        expect(tester.takeException(), isNull);
        expect(find.byType(HomeScreen), findsOneWidget);

        // Merkezin paleti oyun ağacına geçti.
        final ctx = tester.element(find.byType(HomeScreen));
        expect(Theme.of(ctx).extension<StudioLook>(), _hubLook);
        expect(StudioLook.of(ctx), _hubLook);
        expect(Theme.of(ctx).brightness, Brightness.dark);
        if (lang == 'ar') expect(Directionality.of(ctx), TextDirection.rtl);

        // Telefonda alt çubuk, tablette yan ray.
        expect(find.byType(StudioNavBar), tablet ? findsNothing : findsOneWidget);
        expect(find.byType(NavigationRail), tablet ? findsOneWidget : findsNothing);
        expect(find.byType(StudioButton), findsWidgets);

        final s = Strings(lang);
        // Günlük ve profil sekmeleri.
        await tester.tap(find.byIcon(Icons.calendar_today_rounded).first);
        await _settle(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.person_outline_rounded).first);
        await _settle(tester);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.home_rounded).first);
        await _settle(tester);

        // Mağaza (taç) ve ayarlar.
        await tester.tap(find.byTooltip(s.t('shop')));
        await _settle(tester);
        expect(find.byType(ShopScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await _back(tester);
        await _settle(tester);
        await tester.tap(find.byTooltip(s.t('settings')));
        await _settle(tester);
        expect(find.byType(SettingsScreen), findsOneWidget);
        expect(find.byType(StudioPanel), findsWidgets);
        expect(tester.takeException(), isNull);
        await _back(tester);
        await _settle(tester);

        // Dünyalar ve ilk dünyanın bölüm kutuları.
        await tester.ensureVisible(find.byIcon(Icons.map_rounded).first);
        await tester.tap(find.byIcon(Icons.map_rounded).first);
        await _settle(tester);
        expect(find.byType(LevelsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(s.t('world', {'n': 1})).first);
        await _settle(tester);
        expect(find.byType(WorldScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
      });
    }
  }

  testWidgets('merkez paleti yoksa oyunun renginden koyu palet', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final st = (await tester.runAsync(() => _state('en')))!;
    await tester.pumpWidget(_game0(st));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    final ctx = tester.element(find.byType(HomeScreen));
    expect(StudioLook.of(ctx), StudioLook.fromSeed(Colors.teal));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('büyük yazı boyutunda taşma yok', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final st = (await tester.runAsync(() => _state('de')))!;
    await tester.pumpWidget(_game0(st, look: _hubLook));
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.calendar_today_rounded).first);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byIcon(Icons.person_outline_rounded).first);
    await _settle(tester);
    expect(tester.takeException(), isNull);
    await tester.tap(find.byTooltip(Strings('de').t('settings')));
    await _settle(tester);
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await _back(tester);
    await _settle(tester);
    await tester.tap(find.byTooltip(Strings('de').t('shop')));
    await _settle(tester);
    expect(find.byType(ShopScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('ortak parçalar ve ilk açılış ekranı onaylı tasarımda', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final st = (await tester.runAsync(() => _state('he')))!;
    var tapped = 0;
    await tester.pumpWidget(
      StudioLookScope(
        look: _hubLook,
        child: MaterialApp(
          theme: buildStudioTheme(_hubLook),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: ListView(
                children: [
                  CurrencyBar(app: st),
                  const PlayHud(items: [(Icons.star, '120'), (Icons.timer, '0:42')]),
                  BoosterBar(
                    buttons: [
                      BoosterButton(Icons.lightbulb, 'hint', () => tapped++),
                      const BoosterButton(Icons.shield, 'shield', null, active: true),
                    ],
                  ),
                  const RewardChips(reward: Reward(coins: 50, gems: 2, xp: 10)),
                  const StarRow(stars: 2, size: 40),
                  StudioPanel(onTap: () => tapped++, child: const Text('panel')),
                  const StudioSectionHeader(icon: Icons.star_rounded, title: 'Öne Çıkan'),
                  StudioPill(label: 'Tümü', selected: true, onTap: () {}),
                  StudioButton.hot(label: 'Hemen Oyna', onPressed: () => tapped++),
                  const StudioButton(label: 'kapalı'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('120'), findsOneWidget);
    expect(find.text('+50'), findsOneWidget);
    await tester.tap(find.byTooltip('hint'));
    await tester.tap(find.text('panel'));
    await tester.tap(find.text('Hemen Oyna'));
    await tester.tap(find.text('kapalı'));
    expect(tapped, 3);
    // Dokunma alanı en az 48 piksel.
    expect(tester.getSize(find.byType(StudioButton).first).height, greaterThanOrEqualTo(48));
    expect(tester.getSize(find.byTooltip('hint')).height, greaterThanOrEqualTo(48));

    await tester.pumpWidget(
      StudioLookScope(
        look: _hubLook,
        child: MaterialApp(
          theme: buildStudioTheme(_hubLook),
          home: ProviderScope(overrides: [appStateProvider.overrideWith((ref) => st)], child: const OnboardingScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(StudioBackdrop), findsOneWidget);
    expect(find.text(st.t('accept_all')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
