/// AppGallery mağaza arka ucu (Huawei Mobile Services).
///
/// Merkezin `lib/store_flavor.dart` dosyası AppGallery derlemesinde
/// `registerHuaweiStore()` çağırır; böylece `AdsService.create()` Petal Ads,
/// `PurchaseService.create()` HMS IAP döndürür. Google Play derlemesine bu
/// paket hiç eklenmez.
library;

import 'package:studio_core/app/services/store_backend.dart';

import 'src/hms_ads.dart';
import 'src/hms_iap.dart';

export 'src/hms_ads.dart' show HmsAdsService;
export 'src/hms_iap.dart' show HmsPurchaseService, HmsProductCatalog;
export 'src/hms_signature.dart' show HmsSignatureVerifier;

class HuaweiStoreBackend extends StoreBackend {
  @override
  StoreKind get kind => StoreKind.huawei;

  @override
  HmsAdsService createAds() => HmsAdsService();

  @override
  HmsPurchaseService createPurchases() => HmsPurchaseService();
}

/// AppGallery arka ucunu kaydeder. `--dart-define=STORE=huawei` olmadan
/// kaydedilse bile devreye girmez (bkz. [StoreBackends.current]).
void registerHuaweiStore() => StoreBackends.register(HuaweiStoreBackend());
