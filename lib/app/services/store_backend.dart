import 'package:flutter/foundation.dart';

import '../edition.dart';
import 'ads.dart';
import 'ads_stub.dart' if (dart.library.io) 'ads_mobile.dart' as ads_impl;
import 'portal.dart';
import 'purchases.dart';
import 'purchases_stub.dart' if (dart.library.io) 'purchases_mobile.dart' as iap_impl;

/// Uygulamanın dağıtıldığı mağaza.
///
/// * [google]: Google Play (AdMob + Google Play Billing).
/// * [apple]: App Store (AdMob + StoreKit).
/// * [huawei]: Huawei AppGallery. Huawei cihazlarında Google Mobile Services
///   yoktur; reklam (Petal Ads) ve satın alma (HMS IAP) `studio_huawei`
///   paketinden gelir. Paket derlemeye eklenmemişse reklam kapalıdır, satın
///   alma görünmez; uygulama yine eksiksiz çalışır.
enum StoreKind { google, apple, huawei }

/// Derleme zamanı mağaza seçimi: `--dart-define=STORE=huawei`.
///
/// Verilmezse platformdan çıkarılır (iOS -> apple, diğerleri -> google).
class StoreFlavor {
  StoreFlavor._();

  /// Ham `STORE` değeri (boş: varsayılan).
  static const String raw = String.fromEnvironment('STORE');

  /// AppGallery derlemesi mi?
  static const bool isHuawei = raw == 'huawei';

  /// Test/ön izleme için mağazayı elle seçmek (yalnızca testler).
  @visibleForTesting
  static StoreKind? debugOverride;

  static StoreKind get current {
    final o = debugOverride;
    if (o != null) return o;
    switch (raw) {
      case 'huawei':
        return StoreKind.huawei;
      case 'apple':
        return StoreKind.apple;
      case 'google':
        return StoreKind.google;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ? StoreKind.apple : StoreKind.google;
  }

  /// Uygulamanın mağaza sayfası (çapraz tanıtım ve "puan ver" bağlantıları).
  static Uri storePage(String package, {StoreKind? kind}) {
    switch (kind ?? current) {
      case StoreKind.huawei:
        // AppGallery istemcisi paket adıyla açar (Huawei cihazlarda yüklü).
        return Uri.parse('appmarket://details?id=$package');
      case StoreKind.google:
      case StoreKind.apple:
        return Uri.parse('https://play.google.com/store/apps/details?id=$package');
    }
  }
}

/// Bir mağazanın reklam ve satın alma arka ucu.
abstract class StoreBackend {
  StoreKind get kind;

  /// Reklam hizmeti (yükleme hataları tolere edilir; oyun reklamı beklemez).
  AdsService createAds();

  /// Uygulama içi satın alma hizmeti.
  PurchaseService createPurchases();

  /// Uzak anlık bildirim (FCM/APNs) var mı? Bütün merkezler yalnızca yerel
  /// bildirim kullanır; Huawei'de FCM hiç yoktur.
  bool get remotePush => false;
}

/// Google Play ve App Store: AdMob + `in_app_purchase`.
class GoogleAppleStoreBackend extends StoreBackend {
  @override
  final StoreKind kind;
  GoogleAppleStoreBackend(this.kind);

  @override
  AdsService createAds() => ads_impl.createAdsService();

  @override
  PurchaseService createPurchases() => iap_impl.createPurchaseService();
}

/// AppGallery derlemesi, HMS eklentisi kayıtlı değilken: Google hizmetlerine
/// hiç dokunmaz. Reklam yok, satın alma yok (mağaza bölümü gizlenir).
class GmsFreeFallbackBackend extends StoreBackend {
  @override
  StoreKind get kind => StoreKind.huawei;

  @override
  AdsService createAds() => NoAdsService();

  @override
  PurchaseService createPurchases() => NoPurchaseService();
}

/// Masaüstü sürümü (Microsoft Store / Mac App Store): mağazada ücretli tam
/// sürüm olarak satılır. Reklam ve uygulama içi satın alma yoktur; premium
/// avantajları [Edition.desktopEntitlements] ile baştan açıktır.
class DesktopEditionBackend extends StoreBackend {
  @override
  StoreKind get kind => StoreFlavor.current;

  @override
  AdsService createAds() => NoAdsService();

  @override
  PurchaseService createPurchases() => NoPurchaseService();
}

/// Web oyun portalı paketi: reklamlar portalın SDK'sından, satın alma yok
/// (portallar oyun içi satın almaya izin vermez).
class PortalStoreBackend extends StoreBackend {
  @override
  StoreKind get kind => StoreFlavor.current;

  @override
  AdsService createAds() => PortalAdsService();

  @override
  PurchaseService createPurchases() => NoPurchaseService();
}

/// Etkin arka ucun kaydı. `studio_huawei` paketi AppGallery derlemesinde
/// `registerHuaweiStore()` ile kendini buraya kaydeder (merkezin
/// `lib/store_flavor.dart` dosyası, bkz. tool/huawei_flavor.py).
class StoreBackends {
  StoreBackends._();

  static final Map<StoreKind, StoreBackend> _registered = {};

  static void register(StoreBackend backend) => _registered[backend.kind] = backend;

  @visibleForTesting
  static void reset() => _registered.clear();

  static bool isRegistered(StoreKind kind) => _registered.containsKey(kind);

  /// Derlemenin mağazasına göre arka uç. AppGallery derlemesinde HMS paketi
  /// kayıtlı değilse GMS'siz yedek kullanılır (AdMob/Play Billing çağrılmaz).
  static StoreBackend get current {
    if (StoreFlavor.debugOverride == null) {
      if (Edition.portal) return PortalStoreBackend();
      if (Edition.desktop) return DesktopEditionBackend();
    }
    final k = StoreFlavor.current;
    final r = _registered[k];
    if (r != null) return r;
    if (k == StoreKind.huawei) return GmsFreeFallbackBackend();
    return GoogleAppleStoreBackend(k);
  }
}
