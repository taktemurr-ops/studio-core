import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';
import 'package:studio_core/core/monetization.dart';
import 'package:studio_onestore/studio_onestore.dart';

void main() {
  tearDown(() {
    StoreFlavor.debugOverride = null;
    StoreBackends.reset();
  });

  test('kayıt yalnızca ONE store derlemesinde devreye girer', () {
    registerOneStore();
    expect(StoreBackends.current, isNot(isA<OneStoreBackend>()));
    StoreFlavor.debugOverride = StoreKind.onestore;
    expect(StoreBackends.current, isA<OneStoreBackend>());
    expect(PurchaseService.create(), isA<OneStorePurchaseService>());
  });

  test('Android dışında (test ortamı) sessizce kapalı', () async {
    final iap = OneStorePurchaseService();
    await iap.init((_) {});
    expect(iap.available, isFalse);
    expect(iap.products, isEmpty);
    expect(await iap.buy(Products.removeAds), isFalse);
    await iap.restore();
    iap.dispose();
  });
}
