/// Samsung Galaxy Store mağaza arka ucu.
///
/// Merkezin `lib/store_flavor.dart` dosyası Galaxy Store derlemesinde
/// `registerSamsungStore()` çağırır: reklam AdMob (Galaxy cihazlarda Google
/// Play hizmetleri vardır), satın alma Samsung IAP. Samsung IAP SDK'sı
/// derlemeye verilmemişse (SAMSUNG_IAP_AAR_URL yok) satın alma kapalıdır,
/// mağaza bölümü gizlenir.
library;

import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/native_purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';

/// Samsung IAP (Java köprüsü `StudioSamsungPlugin`, kanal `studio_samsung/iap`).
///
/// `--dart-define=SAMSUNG_IAP_TEST=true` ile OPERATION_MODE_TEST (gerçek
/// ödeme alınmaz; Seller Portal'daki lisanslı test hesapları için).
class SamsungPurchaseService extends NativeChannelPurchaseService {
  SamsungPurchaseService() : super(channelName, testMode: const bool.fromEnvironment('SAMSUNG_IAP_TEST'));

  static const channelName = 'studio_samsung/iap';
}

class SamsungStoreBackend extends StoreBackend {
  final TableStoreBackend _table = TableStoreBackend(storeTable[StoreKind.samsung]!);

  @override
  StoreKind get kind => StoreKind.samsung;

  /// AdMob (tablodan; GMS'li Galaxy cihazları).
  @override
  AdsService createAds() => _table.createAds();

  @override
  SamsungPurchaseService createPurchases() => SamsungPurchaseService();
}

/// Galaxy Store arka ucunu kaydeder; `--dart-define=STORE=samsung` olmadan devreye girmez.
void registerSamsungStore() => StoreBackends.register(SamsungStoreBackend());
