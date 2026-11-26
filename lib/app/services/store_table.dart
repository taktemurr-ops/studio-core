// ÜRETİLDİ: tool/gen_store_table.py, kaynak tool/stores.json. Elle düzenlemeyin.
part of 'store_backend.dart';

/// Mağaza kimlikleri (`--dart-define=STORE=<id>`).
enum StoreKind { google, apple, huawei, samsung, xiaomi, oppo, vivo, honor, amazon, onestore }

/// Uygulama içi satın alma sağlayıcısı.
enum IapProvider { amazon, googlePlay, hms, none, onestore, samsung, storekit }

const Map<StoreKind, StoreSpec> storeTable = {
  StoreKind.google: StoreSpec(kind: StoreKind.google, name: "Google Play", ads: AdProvider.admob, iap: IapProvider.googlePlay, gms: true, storePage: "https://play.google.com/store/apps/details?id={package}", artifactSuffix: "", plugin: null),
  StoreKind.apple: StoreSpec(kind: StoreKind.apple, name: "App Store", ads: AdProvider.admob, iap: IapProvider.storekit, gms: false, storePage: "https://play.google.com/store/apps/details?id={package}", artifactSuffix: "", plugin: null),
  StoreKind.huawei: StoreSpec(kind: StoreKind.huawei, name: "Huawei AppGallery", ads: AdProvider.petal, iap: IapProvider.hms, gms: false, storePage: "appmarket://details?id={package}", artifactSuffix: "-huawei", plugin: "studio_huawei"),
  StoreKind.samsung: StoreSpec(kind: StoreKind.samsung, name: "Samsung Galaxy Store", ads: AdProvider.admob, iap: IapProvider.samsung, gms: true, storePage: "samsungapps://ProductDetail/{package}", artifactSuffix: "-samsung", plugin: "studio_samsung"),
  StoreKind.xiaomi: StoreSpec(kind: StoreKind.xiaomi, name: "Xiaomi GetApps", ads: AdProvider.admob, iap: IapProvider.none, gms: false, storePage: "mimarket://details?id={package}", artifactSuffix: "-xiaomi", plugin: null),
  StoreKind.oppo: StoreSpec(kind: StoreKind.oppo, name: "OPPO App Market", ads: AdProvider.admob, iap: IapProvider.none, gms: false, storePage: "oppomarket://details?packagename={package}", artifactSuffix: "-oppo", plugin: null),
  StoreKind.vivo: StoreSpec(kind: StoreKind.vivo, name: "vivo App Store", ads: AdProvider.admob, iap: IapProvider.none, gms: false, storePage: "vivomarket://details?id={package}", artifactSuffix: "-vivo", plugin: null),
  StoreKind.honor: StoreSpec(kind: StoreKind.honor, name: "HONOR App Market", ads: AdProvider.admob, iap: IapProvider.none, gms: false, storePage: "market://details?id={package}", artifactSuffix: "-honor", plugin: null),
  StoreKind.amazon: StoreSpec(kind: StoreKind.amazon, name: "Amazon Appstore", ads: AdProvider.none, iap: IapProvider.amazon, gms: false, storePage: "amzn://apps/android?p={package}", artifactSuffix: "-amazon", plugin: "studio_amazon"),
  StoreKind.onestore: StoreSpec(kind: StoreKind.onestore, name: "ONE Store", ads: AdProvider.admob, iap: IapProvider.onestore, gms: true, storePage: "market://details?id={package}", artifactSuffix: "-onestore", plugin: "studio_onestore"),
};
