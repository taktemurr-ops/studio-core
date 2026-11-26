/// AdMob reklam birimleri. Derlemede `--dart-define` ile verilir
/// (CI'da depo gizli değişkenlerinden). Verilmezse Google'ın herkese açık
/// TEST kimlikleri kullanılır: geliştirme sırasında güvenli, gelir getirmez.
///
///   flutter build appbundle \
///     --dart-define=ADMOB_ANDROID_INTERSTITIAL=ca-app-pub-xxx/yyy \
///     --dart-define=ADMOB_ANDROID_REWARDED=ca-app-pub-xxx/zzz
///
/// Uygulama kimliği (APPLICATION_ID) AndroidManifest / Info.plist'te ayrıca
/// ayarlanır (tool/patch_platforms.py, ADMOB_APP_ID ortam değişkeni).
class AdIds {
  static const androidInterstitial = String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL',
      defaultValue: 'ca-app-pub-3940256099942544/1033173712');
  static const androidRewarded = String.fromEnvironment('ADMOB_ANDROID_REWARDED',
      defaultValue: 'ca-app-pub-3940256099942544/5224354917');
  static const iosInterstitial = String.fromEnvironment('ADMOB_IOS_INTERSTITIAL',
      defaultValue: 'ca-app-pub-3940256099942544/4411468910');
  static const iosRewarded = String.fromEnvironment('ADMOB_IOS_REWARDED',
      defaultValue: 'ca-app-pub-3940256099942544/1712485313');

  /// Gerçek kimlikler verildi mi (test kimlikleri değil)?
  static bool get live => !androidInterstitial.startsWith('ca-app-pub-3940256099942544');
}

/// Huawei Petal Ads (AppGallery derlemesi) reklam yuvaları. Derlemede
/// `--dart-define=HUAWEI_ADS_INTERSTITIAL=...` / `HUAWEI_ADS_REWARDED=...`
/// ile verilir (CI'da depo gizli değişkenlerinden). Verilmezse Huawei'nin
/// herkese açık TEST yuvaları kullanılır: gelir getirmez.
class HuaweiAdIds {
  static const interstitial = String.fromEnvironment('HUAWEI_ADS_INTERSTITIAL', defaultValue: 'teste9ih9j0rc3');
  static const rewarded = String.fromEnvironment('HUAWEI_ADS_REWARDED', defaultValue: 'testx9dtjwj8hp');

  /// Gerçek yuvalar verildi mi (test yuvaları değil)?
  static bool get live => !interstitial.startsWith('test');
}
