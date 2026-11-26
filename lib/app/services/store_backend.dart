import 'package:flutter/foundation.dart';

import 'ads.dart';
import 'ads_stub.dart' if (dart.library.io) 'ads_mobile.dart' as ads_impl;
import 'purchases.dart';
import 'purchases_stub.dart' if (dart.library.io) 'purchases_mobile.dart' as iap_impl;

part 'store_table.dart';

/// Reklam sağlayıcısı: AdMob (Google), Petal Ads (Huawei) ya da reklam yok.
enum AdProvider { admob, petal, none }

/// Bir mağazanın özellikleri. Tek kaynak `tool/stores.json`;
/// [storeTable] ondan üretilir (tool/gen_store_table.py). Merkezlerin
/// derleme betiği (tool/store_flavor.py) aynı JSON'u okur: eklenti paketi,
/// GMS'siz ML seçimi, Maven depoları, yapılandırma gizli değişkeni ve çıktı
/// dosya adı ([artifactSuffix]) oradan gelir.
class StoreSpec {
  final StoreKind kind;
  final String name;
  final AdProvider ads;
  final IapProvider iap;

  /// Derleme Google Play hizmetlerine (GMS) dayanabilir mi? false ise ML
  /// modelleri APK'ya gömülür, Play hizmetleri sürümleri kullanılmaz.
  final bool gms;

  /// Mağaza sayfası şablonu (`{package}` yerine paket adı).
  final String storePage;

  /// Test APK adı eki (`<merkez><ek>.apk`); Google Play için boş.
  final String artifactSuffix;

  /// AppGallery gibi eklenti gerektiren mağazalarda Dart paketi
  /// (studio-core/packages/<plugin>); merkez derlemesine yalnızca o mağazada
  /// eklenir ve `register...()` ile [StoreBackends]'e kaydolur.
  final String? plugin;

  const StoreSpec({
    required this.kind,
    required this.name,
    required this.ads,
    required this.iap,
    required this.gms,
    required this.storePage,
    required this.artifactSuffix,
    required this.plugin,
  });

  Uri pageFor(String package) => Uri.parse(storePage.replaceAll('{package}', package));
}

/// Derleme zamanı mağaza seçimi: `--dart-define=STORE=<id>` (bkz. [StoreKind]).
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

  static StoreKind? parse(String id) {
    for (final k in StoreKind.values) {
      if (k.name == id) return k;
    }
    return null;
  }

  static StoreKind get current {
    final o = debugOverride;
    if (o != null) return o;
    final k = parse(raw);
    if (k != null) return k;
    return defaultTargetPlatform == TargetPlatform.iOS ? StoreKind.apple : StoreKind.google;
  }

  static StoreSpec get spec => storeTable[current]!;

  /// Uygulamanın mağaza sayfası (çapraz tanıtım ve "puan ver" bağlantıları).
  static Uri storePage(String package, {StoreKind? kind}) => storeTable[kind ?? current]!.pageFor(package);
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

/// Eklentisiz mağazalar için tablo güdümlü arka uç: reklam AdMob ise
/// AdMob, satın alma Google Play/StoreKit ise `in_app_purchase`; tablodaki
/// sağlayıcının eklentisi kayıtlı değilse (ör. Petal, HMS) o özellik
/// kapalıdır ve Google hizmetlerine hiç dokunulmaz.
class TableStoreBackend extends StoreBackend {
  final StoreSpec spec;
  TableStoreBackend(this.spec);

  @override
  StoreKind get kind => spec.kind;

  @override
  AdsService createAds() => spec.ads == AdProvider.admob ? ads_impl.createAdsService() : NoAdsService();

  @override
  PurchaseService createPurchases() =>
      (spec.iap == IapProvider.googlePlay || spec.iap == IapProvider.storekit)
          ? iap_impl.createPurchaseService()
          : NoPurchaseService();
}

/// Etkin arka ucun kaydı. Eklentili mağaza paketleri (ör. `studio_huawei`)
/// o mağazanın derlemesinde kendini buraya kaydeder (merkezin
/// `lib/store_flavor.dart` dosyası, bkz. merkezlerde tool/store_flavor.py).
class StoreBackends {
  StoreBackends._();

  static final Map<StoreKind, StoreBackend> _registered = {};

  static void register(StoreBackend backend) => _registered[backend.kind] = backend;

  @visibleForTesting
  static void reset() => _registered.clear();

  static bool isRegistered(StoreKind kind) => _registered.containsKey(kind);

  /// Derlemenin mağazasına göre arka uç: kayıtlı eklenti, yoksa tablo
  /// güdümlü yedek (AppGallery'de HMS paketi yoksa reklam/satın alma kapalı;
  /// AdMob/Play Billing çağrılmaz).
  static StoreBackend get current {
    final k = StoreFlavor.current;
    return _registered[k] ?? TableStoreBackend(storeTable[k]!);
  }
}
