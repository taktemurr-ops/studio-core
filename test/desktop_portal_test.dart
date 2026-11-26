import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:studio_core/app/desktop_input.dart';
import 'package:studio_core/app/edition.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/portal.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';
import 'package:studio_core/apps/apps.dart';
import 'package:studio_core/core/monetization.dart';

AppTool _tool(String id, String cat) => AppTool(
      id: id,
      title: [id, id],
      tagline: const ['Kısa', 'Short'],
      icon: Icons.apps_rounded,
      color: Colors.teal,
      category: cat,
      builder: (context, tool) => Text(id),
    );

void main() {
  tearDown(() {
    Edition.debugDesktop = null;
    Edition.debugPortal = null;
    StoreFlavor.debugOverride = null;
  });

  test('testlerde (Android varsayılanı) masaüstü ve portal kapalı', () {
    expect(Edition.desktop, isFalse);
    expect(Edition.portal, isFalse);
    expect(Edition.externalLinks, isTrue);
    expect(StoreBackends.current, isA<TableStoreBackend>());
  });

  test('masaüstü sürümü: reklam ve satın alma yok, premium açık', () async {
    Edition.debugDesktop = true;
    expect(StoreBackends.current, isA<DesktopEditionBackend>());
    final ads = AdsService.create();
    expect(ads.available, isFalse);
    expect(await ads.showInterstitial(), isFalse);
    expect(PurchaseService.create().available, isFalse);
    expect(Edition.desktopEntitlements, containsAll([Products.premium, Products.removeAds]));
  });

  test('portal paketi: reklamlar portal köprüsünden, dış bağlantı yok', () async {
    Edition.debugPortal = true;
    expect(StoreBackends.current, isA<PortalStoreBackend>());
    expect(AdsService.create(), isA<PortalAdsService>());
    expect(Edition.externalLinks, isFalse);
    // Web dışında köprü nesnesi yok: çağrılar sessizce false döner.
    expect(Portal.active, isFalse);
    expect(await Portal.commercialBreak(), isFalse);
    expect(await Portal.rewardedBreak(), isFalse);
    Portal.gameplayStart();
    Portal.gameplayStop();
  });

  test('masaüstünde mobilOnly araçları ve boş kategoriler gizlenir', () {
    final c = AppHubConfig(
      hubId: 'merkez-deneme',
      title: const ['Deneme', 'Test'],
      tagline: const ['a', 'b'],
      icon: Icons.apps_rounded,
      style: const ApprovedHubStyle(),
      categories: const [
        AppCategory(id: 'not', title: ['Not', 'Notes'], icon: Icons.note),
        AppCategory(id: 'kamera', title: ['Kamera', 'Camera'], icon: Icons.camera),
      ],
      tools: [_tool('uyg-not', 'not'), _tool('uyg-tarayici', 'kamera')],
      featured: const ['uyg-tarayici', 'uyg-not'],
      mobileOnly: const ['uyg-tarayici'],
    );
    expect(identical(c.forPlatform(desktop: false), c), isTrue);
    final d = c.forPlatform(desktop: true);
    expect(d.tools.map((t) => t.id), ['uyg-not']);
    expect(d.categories.map((x) => x.id), ['not']);
    expect(d.featured, ['uyg-not']);
  });

  testWidgets('Esc ve Alt+Sol ok bir önceki ekrana döner, ana ekranda bir şey yapmaz', (tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: key,
      scrollBehavior: const StudioScrollBehavior(),
      builder: (context, child) => DesktopInput(navigatorKey: key, child: child!),
      home: const Text('ana'),
    ));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('ana'), findsOneWidget);

    key.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('ikinci')));
    await tester.pumpAndSettle();
    expect(find.text('ikinci'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('ana'), findsOneWidget);
    expect(find.text('ikinci'), findsNothing);

    key.currentState!.push(MaterialPageRoute<void>(builder: (_) => const Text('üçüncü')));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
    await tester.pumpAndSettle();
    expect(find.text('ana'), findsOneWidget);
  });

  test('fare ile sürükleyerek kaydırma açık', () {
    const b = StudioScrollBehavior();
    expect(b.dragDevices, contains(PointerDeviceKind.mouse));
    expect(b.dragDevices, contains(PointerDeviceKind.trackpad));
  });
}
