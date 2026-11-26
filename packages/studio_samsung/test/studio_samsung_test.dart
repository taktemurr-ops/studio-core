import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';
import 'package:studio_core/core/monetization.dart';
import 'package:studio_samsung/studio_samsung.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(SamsungPurchaseService.channelName);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    StoreFlavor.debugOverride = null;
    StoreBackends.reset();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('kayıt yalnızca Galaxy Store derlemesinde devreye girer', () {
    registerSamsungStore();
    expect(StoreBackends.current, isNot(isA<SamsungStoreBackend>()));
    StoreFlavor.debugOverride = StoreKind.samsung;
    expect(StoreBackends.current, isA<SamsungStoreBackend>());
    expect(PurchaseService.create(), isA<SamsungPurchaseService>());
    expect(SamsungPurchaseService().testMode, isFalse);
  });

  test('SDK olmadan derleme (stub): satın alma kapalı', () async {
    messenger.setMockMethodCallHandler(channel, (c) async {
      if (c.method == 'init') return {'available': false, 'products': <Object>[], 'sdk': false};
      return null;
    });
    final iap = SamsungPurchaseService();
    await iap.init((_) {});
    expect(iap.available, isFalse);
    expect(await iap.buy(Products.removeAds), isFalse);
  });

  test('ürün sorgusu aynı kimliklerle yapılır', () async {
    Map? initArgs;
    messenger.setMockMethodCallHandler(channel, (c) async {
      if (c.method == 'init') {
        initArgs = c.arguments as Map;
        return {
          'available': true,
          'products': [
            {'id': Products.premium, 'price': '₩3,300'},
          ],
        };
      }
      return true;
    });
    final iap = SamsungPurchaseService();
    await iap.init((_) {});
    expect((initArgs!['skus'] as List).toSet(), Products.all);
    expect((initArgs!['consumables'] as List).toSet(), Products.consumable);
    expect(iap.available, isTrue);
    expect(await iap.buy(Products.premium), isTrue);
    expect(await iap.buy(Products.coinsLarge), isFalse, reason: 'mağazada tanımlı değil');
  });
}
