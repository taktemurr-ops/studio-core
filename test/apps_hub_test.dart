import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/apps/apps.dart';
import 'package:studio_core/core/save_store.dart';
import 'package:studio_core/core/strings.dart';

class _FakeAds extends NoAdsService {
  int shown = 0;
  @override
  bool get available => true;
  @override
  Future<bool> showInterstitial() async {
    shown++;
    return true;
  }

  @override
  Future<bool> showRewarded() async => true;
}

AppTool _tool(String id, String tr, String en, {String cat = 'calc', AppDisclaimer d = AppDisclaimer.none}) => AppTool(
      id: id,
      title: [tr, en],
      tagline: const ['Kısa', 'Short'],
      icon: Icons.calculate_rounded,
      color: Colors.teal,
      category: cat,
      disclaimer: d,
      keywords: const ['math'],
      builder: (context, tool) => Center(child: Text('body-$id')),
    );

AppHubConfig _config() => AppHubConfig(
      hubId: 'merkez-deneme',
      title: const ['Araç Kutusu', 'Toolbox'],
      tagline: const ['Günlük araçlar', 'Everyday tools'],
      icon: Icons.handyman_rounded,
      style: const ApprovedHubStyle(),
      categories: const [
        AppCategory(id: 'calc', title: ['Hesap', 'Calc'], icon: Icons.calculate_rounded),
        AppCategory(id: 'measure', title: ['Ölçüm', 'Measure'], icon: Icons.straighten_rounded),
      ],
      tools: [
        _tool('hesap', 'Hesap Makinesi', 'Calculator'),
        _tool('cetvel', 'Cetvel', 'Ruler', cat: 'measure'),
        _tool('nabiz', 'Nabız', 'Pulse', d: AppDisclaimer.wellness),
      ],
      featured: const ['cetvel'],
    );

AppServices _services({AdsService? ads, int? now}) => AppServices(
      hubId: 'merkez-deneme',
      backend: MemoryBackend(),
      ads: ads ?? NoAdsService(),
      purchases: NoPurchaseService(),
      nowMs: now,
    );

Future<void> _pump(WidgetTester tester, AppServices s, String lang) async {
  await s.load();
  if (s.consent == null) await s.setConsent(false);
  await s.setLanguage(lang);
  tester.view.physicalSize = const Size(1080, 2200);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(AppHubApp(config: _config(), services: s));
  await tester.pumpAndSettle();
}

void main() {
  test('every app string has 33 languages', () {
    for (final e in kAppTx.entries) {
      expect(e.value.length, Strings.languages.length, reason: e.key);
    }
    expect(appTx('n_apps', 'tr', {'n': 60}), '60 Uygulama');
  });

  test('AppStore keeps values per tool and clears them', () async {
    final b = MemoryBackend();
    final s = AppStore(b, 'app.x');
    await s.write('a', '1');
    await s.writeMap('m', {'k': 2});
    await s.writeStrings('l', ['p', 'q']);
    expect(await s.readInt('a'), 1);
    expect((await s.readMap('m'))['k'], 2);
    expect(await s.readStrings('l'), ['p', 'q']);
    await s.clearAll();
    expect(await s.read('a'), isNull);
  });

  test('interstitial only at natural breaks, after 3 minutes, never when ad-free', () async {
    final ads = _FakeAds();
    final s = _services(ads: ads, now: 0);
    await s.load();
    await s.setConsent(true);
    expect(await s.naturalBreak(nowMs: 60 * 1000), isFalse);
    expect(await s.naturalBreak(nowMs: 3 * 60 * 1000 + 1), isTrue);
    expect(await s.naturalBreak(nowMs: 4 * 60 * 1000), isFalse);
    expect(await s.naturalBreak(nowMs: 7 * 60 * 1000), isTrue);
    expect(ads.shown, 2);
    s.entitlements.add('remove_ads');
    expect(await s.naturalBreak(nowMs: 20 * 60 * 1000), isFalse);
    expect(await s.rewarded(), isTrue);
  });

  testWidgets('consent page appears first', (tester) async {
    final s = _services();
    await s.load();
    await tester.pumpWidget(AppHubApp(config: _config(), services: s));
    await tester.pumpAndSettle();
    expect(find.text(Strings('tr').t('accept_all')).evaluate().isNotEmpty ||
        find.byType(AppConsentPage).evaluate().isNotEmpty, isTrue);
  });

  for (final lang in ['tr', 'en', 'ar']) {
    testWidgets('hub shell renders in $lang', (tester) async {
      final s = _services();
      await _pump(tester, s, lang);
      expect(find.text(appTx('n_apps', lang, {'n': 3})), findsOneWidget);
      expect(find.text(appTx('nav_favorites', lang)), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('search, open tool, favorite and tabs', (tester) async {
    final s = _services();
    await _pump(tester, s, 'en');
    await tester.enterText(find.byKey(const ValueKey('app-search')), 'puls');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tool-nabiz')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tool-nabiz')));
    await tester.pumpAndSettle();
    expect(find.text('body-nabiz'), findsOneWidget);
    expect(find.text(appTx('wellness', 'en')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('fav-toggle')));
    await tester.pumpAndSettle();
    expect(s.isFavorite('nabiz'), isTrue);
    expect(s.recents.first, 'nabiz');
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text(appTx('nav_favorites', 'en')).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tool-nabiz')), findsOneWidget);
    await tester.tap(find.text(appTx('nav_profile', 'en')).last);
    await tester.pumpAndSettle();
    expect(find.text(Strings('en').t('delete_data')), findsOneWidget);
    await tester.tap(find.text(appTx('nav_apps', 'en')).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('tool-hesap')), findsOneWidget);
  });
}
