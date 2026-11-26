import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_amazon/studio_amazon.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';
import 'package:studio_core/core/monetization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel(AmazonPurchaseService.channelName);
  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    StoreFlavor.debugOverride = null;
    StoreBackends.reset();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('kayıt yalnızca Amazon derlemesinde devreye girer; reklam yok', () {
    registerAmazonStore();
    expect(StoreBackends.current, isNot(isA<AmazonStoreBackend>()));
    StoreFlavor.debugOverride = StoreKind.amazon;
    expect(StoreBackends.current, isA<AmazonStoreBackend>());
    expect(AdsService.create().available, isFalse);
    expect(PurchaseService.create(), isA<AmazonPurchaseService>());
  });

  test('yerel eklenti yoksa sessizce kapalı', () async {
    final iap = AmazonPurchaseService();
    await iap.init((_) {});
    expect(iap.available, isFalse);
    expect(await iap.buy(Products.removeAds), isFalse);
  });

  test('teslim sonrası tüketilebilir bildirilir, tüketilemez yalnızca teslim', () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (c) async {
      calls.add(c);
      if (c.method == 'init') {
        return {
          'available': true,
          'products': [
            {'id': Products.removeAds, 'price': '\$1.99'},
            {'id': Products.coinsSmall, 'price': '\$0.99'},
            {'id': 'bilinmeyen', 'price': '\$9'},
          ],
        };
      }
      return true;
    });
    final events = <PurchaseEvent>[];
    final iap = AmazonPurchaseService();
    await iap.init(events.add);
    expect(iap.available, isTrue);
    expect(iap.products.map((p) => p.id), [Products.removeAds, Products.coinsSmall]);
    expect(await iap.buy(Products.coinsSmall), isTrue);
    await iap.deliver(Products.coinsSmall, 'r1', 'purchased', true);
    await iap.deliver(Products.removeAds, 'r2', 'restored', true);
    await iap.deliver(Products.coinsLarge, 'r3', 'canceled', false);
    expect(events.map((e) => '${e.productId}:${e.status}:${e.verified}'),
        ['${Products.coinsSmall}:purchased:true', '${Products.removeAds}:restored:true', '${Products.coinsLarge}:canceled:false']);
    final finish = calls.where((c) => c.method == 'finish').toList();
    expect(finish.length, 2);
    expect((finish[0].arguments as Map)['consumable'], isTrue);
    expect((finish[1].arguments as Map)['consumable'], isFalse);
  });
}
