// Ekran boyutları: ortak oyun ekranları (ana sayfa, ayarlar, bölümler,
// mağaza, günlük, profil, başarımlar, koleksiyon, meydan okumalar, ilk
// açılış) ve uygulama merkezi kabuğu küçük telefondan (320x568) yatay
// tablete (1280x800) kadar, büyük yazı (1.3x) ve sağdan sola dilde taşmadan,
// metin kesilmeden, düğmeler erişilebilir biçimde açılır. Oyunların ve
// araçların kendi ekranları merkezlerin screen_sizes_test.dart dosyasında.
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
import 'package:studio_core/app/screens/achievements.dart';
import 'package:studio_core/app/screens/collection.dart';
import 'package:studio_core/app/screens/daily.dart';
import 'package:studio_core/app/screens/home.dart';
import 'package:studio_core/app/screens/levels.dart';
import 'package:studio_core/app/screens/profile.dart';
import 'package:studio_core/app/screens/settings.dart';
import 'package:studio_core/app/screens/shop.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/audio.dart';
import 'package:studio_core/app/services/prefs_backend.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/studio_look.dart';
import 'package:studio_core/apps/apps.dart';
import 'package:studio_core/core/save_store.dart';
import 'package:studio_core/core/telemetry.dart';

import 'layout_check.dart';
import 'sample_rules.dart';

final issues = LayoutIssues();

const _hubStyle = ApprovedHubStyle(
  background: [Color(0xFF6E1A2A), Color(0xFF4A1020), Color(0xFF2A0812)],
  accent: Color(0xFFFFB347),
  card: Color(0xFF8A2238),
  play: Color(0xFFFF8A1F),
);

GameConfig _game() => GameConfig(
      gameId: 'oyun-blok',
      title: const ['Blok Bulmaca Ustası Uzun Adlı Oyun', 'Block Puzzle Master With A Long Name'],
      tagline: const ['Kısa açıklama', 'Short tagline'],
      seedColor: Colors.teal,
      icon: Icons.extension,
      rules: BlockRules(),
      buildPlay: (_) => const SizedBox(),
      tutorial: const [],
    );

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

bool _phoneLandscape(Size s) => s.width > s.height && s.shortestSide < 600;

AppTool _tool(String id, String tr, String en, String cat) => AppTool(
      id: id,
      title: [tr, en],
      tagline: const ['Günlük hesaplar için hızlı ve sade bir araç', 'A quick and simple tool for everyday sums'],
      icon: Icons.calculate_rounded,
      color: Colors.teal,
      category: cat,
      keywords: const ['math'],
      builder: (context, tool) => const Center(child: Text('Araç gövdesi')),
    );

AppHubConfig _appConfig() => AppHubConfig(
      hubId: 'merkez-deneme',
      title: const ['Araç Kutusu', 'Toolbox'],
      tagline: const ['Günlük araçlar tek yerde', 'Everyday tools in one place'],
      icon: Icons.handyman_rounded,
      style: _hubStyle,
      categories: const [
        AppCategory(id: 'calc', title: ['Hesaplama ve Dönüştürme', 'Calculation and Conversion'], icon: Icons.calculate_rounded),
        AppCategory(id: 'measure', title: ['Ölçüm', 'Measure'], icon: Icons.straighten_rounded),
      ],
      tools: [
        _tool('hesap', 'Bilimsel Hesap Makinesi', 'Scientific Calculator', 'calc'),
        _tool('cetvel', 'Cetvel ve Açı Ölçer', 'Ruler and Protractor', 'measure'),
        _tool('kur', 'Döviz ve Birim Çevirici', 'Currency and Unit Converter', 'calc'),
      ],
      featured: const ['cetvel', 'hesap'],
    );

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadRealFonts();
    for (final ch in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global']) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(MethodChannel(ch), (call) async => null);
    }
  });
  tearDownAll(() => issues.printSummary('studio_core'));

  final screens = <String, Widget Function()>{
    'ayarlar': () => const SettingsScreen(),
    'bolumler': () => const LevelsScreen(),
    'magaza': () => const ShopScreen(),
    'gunluk': () => const Scaffold(body: DailyScreen()),
    'profil': () => const Scaffold(body: ProfileScreen()),
    'basarimlar': () => const AchievementsScreen(),
    'koleksiyon': () => const CollectionScreen(),
    'meydan_okumalar': () => const ChallengesScreen(),
  };

  for (final name in ['ana', 'ilk_acilis', ...screens.keys]) {
    testWidgets('oyun ekranı tüm boyutlarda: $name', (tester) async {
      final s = (await tester.runAsync(_services))!;
      final st = (await tester.runAsync(() => s.stateFor(_game())))!;
      st.startup = null;
      st.save.ageGateDone = name != 'ilk_acilis';
      st.save.adConsent = name == 'ilk_acilis' ? '' : 'denied';
      await sweep(tester, issues, name, skip: _phoneLandscape, (lang) async {
        st.save.language = lang;
        await tester.pumpWidget(ProviderScope(
          overrides: [appStateProvider.overrideWith((ref) => st)],
          child: fresh(StudioLookScope(look: _hubStyle.look, child: GameApp(state: st))),
        ));
        await tester.pump(const Duration(milliseconds: 100));
        final b = screens[name];
        final home = find.byType(HomeScreen);
        if (b == null || home.evaluate().isEmpty) return;
        Navigator.of(tester.element(home), rootNavigator: true).push(MaterialPageRoute<void>(builder: (_) => b()));
      });
      expect(issues.items.where((i) => i.startsWith('SORUN|$name|')).toList(), isEmpty);
    });
  }

  testWidgets('oyun merkezi kabuğu tüm boyutlarda', (tester) async {
    final s = (await tester.runAsync(_services))!;
    final hub = HubConfig(
      hubId: 'merkez-deneme',
      title: const ['Boşta ve Simülasyon Oyunları', 'Idle and Simulation Games'],
      tagline: const ['Üret, geliştir, otomatik kazançla imparatorluğunu büyüt!', 'Build, upgrade and grow your empire!'],
      seedColor: Colors.indigo,
      icon: Icons.location_city,
      games: [_game()],
    );
    await sweep(tester, issues, 'oyun_merkezi', skip: _phoneLandscape,
        langScales: const [('tr', 1.0), ('tr', 1.3), ('ar', 1.3)], (lang) async {
      await tester.pumpWidget(fresh(MaterialApp(home: ApprovedHubShell(hub: hub, style: _hubStyle, services: s, lang: lang))));
    });
    expect(issues.items.where((i) => i.startsWith('SORUN|oyun_merkezi|')).toList(), isEmpty);
  });

  testWidgets('uygulama merkezi kabuğu ve araç sayfası tüm boyutlarda', (tester) async {
    final c = _appConfig();
    final s = AppServices(hubId: c.hubId, backend: MemoryBackend(), ads: NoAdsService(), purchases: NoPurchaseService());
    await tester.runAsync(() async {
      await s.load();
      await s.setConsent(false);
    });
    await sweep(tester, issues, 'uygulama_merkezi', langScales: const [('tr', 1.0), ('tr', 1.3), ('ar', 1.3)], (lang) async {
      await tester.runAsync(() => s.setLanguage(lang));
      await tester.pumpWidget(fresh(AppHubApp(config: c, services: s)));
    });
    await sweep(tester, issues, 'arac_sayfasi', langScales: const [('tr', 1.3), ('ar', 1.3)], (lang) async {
      await tester.runAsync(() => s.setLanguage(lang));
      await tester.pumpWidget(fresh(AppHubApp(config: c, services: s)));
      await tester.pump(const Duration(milliseconds: 100));
      final shell = find.byType(AppHubShell);
      if (shell.evaluate().isEmpty) return;
      Navigator.of(tester.element(shell))
          .push(MaterialPageRoute<void>(builder: (_) => AppToolPage(config: c, tool: c.tools.first, services: s, lang: lang)));
    });
    expect(issues.items.where((i) => i.startsWith('SORUN|uygulama_merkezi|') || i.startsWith('SORUN|arac_sayfasi|')).toList(), isEmpty);
  });
}
