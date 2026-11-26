import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';
import 'package:studio_core/core/monetization.dart';
import 'package:studio_huawei/studio_huawei.dart';

void main() {
  tearDown(() {
    StoreFlavor.debugOverride = null;
    StoreBackends.reset();
  });

  test('ürün kataloğu: tüketilebilir 0, tüketilemez 1', () {
    expect(HmsProductCatalog.priceTypeOf(Products.removeAds), 1);
    expect(HmsProductCatalog.priceTypeOf(Products.premium), 1);
    for (final id in Products.consumable) {
      expect(HmsProductCatalog.priceTypeOf(id), 0);
    }
    expect({...HmsProductCatalog.idsOf(0), ...HmsProductCatalog.idsOf(1)}, Products.all);
  });

  test('kayıt yalnızca AppGallery derlemesinde devreye girer', () {
    registerHuaweiStore();
    expect(StoreBackends.current, isNot(isA<HuaweiStoreBackend>()));
    StoreFlavor.debugOverride = StoreKind.huawei;
    expect(StoreBackends.current, isA<HuaweiStoreBackend>());
    expect(AdsService.create(), isA<HmsAdsService>());
    expect(PurchaseService.create(), isA<HmsPurchaseService>());
  });

  test('Android dışında (test ortamı) sessizce kapalı', () async {
    final ads = HmsAdsService();
    expect(await ads.init(underAge: false, personalized: true), isFalse);
    expect(ads.available, isFalse);
    expect(await ads.showInterstitial(), isFalse);
    expect(await ads.showRewarded(), isFalse);
    final iap = HmsPurchaseService();
    await iap.init((_) {});
    expect(iap.available, isFalse);
    expect(await iap.buy(Products.removeAds), isFalse);
  });
}
