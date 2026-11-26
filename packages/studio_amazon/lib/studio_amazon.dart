/// Amazon Appstore mağaza arka ucu (Fire tablet ve Fire TV).
///
/// Merkezin `lib/store_flavor.dart` dosyası Amazon derlemesinde
/// `registerAmazonStore()` çağırır: `PurchaseService.create()` Amazon IAP
/// döndürür; reklam yoktur (AdMob, Google Play hizmetleri olmadan çalışmaz).
library;

import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/native_purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';

/// Amazon IAP (Java köprüsü: `StudioAmazonPlugin`, kanal `studio_amazon/iap`).
class AmazonPurchaseService extends NativeChannelPurchaseService {
  AmazonPurchaseService() : super(channelName);

  static const channelName = 'studio_amazon/iap';
}

class AmazonStoreBackend extends StoreBackend {
  @override
  StoreKind get kind => StoreKind.amazon;

  @override
  AdsService createAds() => NoAdsService();

  @override
  AmazonPurchaseService createPurchases() => AmazonPurchaseService();
}

/// Amazon arka ucunu kaydeder; `--dart-define=STORE=amazon` olmadan devreye girmez.
void registerAmazonStore() => StoreBackends.register(AmazonStoreBackend());
