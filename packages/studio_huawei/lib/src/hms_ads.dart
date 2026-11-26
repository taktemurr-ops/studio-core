import 'dart:async';
import 'dart:io' show Platform;

import 'package:huawei_ads/huawei_ads.dart' as hw;
import 'package:studio_core/app/ad_ids.dart';
import 'package:studio_core/app/services/ads.dart';

/// Huawei Petal Ads: ödüllü ve geçiş reklamı.
///
/// Gösterim kuralları (3 dakika ara, oyunun ortasında asla, çocuk modunda
/// geçiş reklamı yok) üst katmanda, AdMob ile aynıdır. Burada ek olarak:
/// * çocuk/yaş altı: COPPA etiketi, "W" (genel izleyici) içerik sınıfı,
///   yalnızca kişiselleştirilmemiş reklam; çocuk modunda geçiş reklamı
///   bu katmanda da reddedilir;
/// * yükleme hataları tolere edilir: oyun reklamı hiç beklemez.
class HmsAdsService implements AdsService {
  bool _ready = false;
  bool _child = false;
  bool _personalized = false;
  int _failures = 0;

  hw.InterstitialAd? _interstitial;
  bool _interstitialLoaded = false;
  Completer<bool>? _interstitialDone;

  hw.RewardAd? _rewarded;
  bool _rewardedLoaded = false;
  bool _earned = false;
  Completer<bool>? _rewardedDone;

  @override
  bool get available => _ready;

  @override
  int get failures => _failures;

  hw.AdParam get _param => hw.AdParam(
        options: hw.RequestOptions(
          nonPersonalizedAd: _personalized
              ? hw.NonPersonalizedAd.ALLOW_ALL.value
              : hw.NonPersonalizedAd.ALLOW_NON_PERSONALIZED.value,
          tagForChildProtection: _child
              ? hw.TagForChild.TAG_FOR_CHILD_PROTECTION_TRUE
              : hw.TagForChild.TAG_FOR_CHILD_PROTECTION_UNSPECIFIED,
          tagForUnderAgeOfPromise: _child || !_personalized ? null : hw.UnderAge.PROMISE_FALSE,
          adContentClassification: _child
              ? hw.ContentClassification.AD_CONTENT_CLASSIFICATION_W
              : hw.ContentClassification.AD_CONTENT_CLASSIFICATION_PI,
          requestLocation: false,
        ),
      );

  @override
  Future<bool> init({required bool underAge, required bool personalized, bool child = false}) async {
    if (!Platform.isAndroid) return false;
    _child = child;
    _personalized = personalized && !underAge && !child;
    try {
      await hw.HwAds.init();
      await hw.HwAds.setRequestOptions(_param.requestOptions);
      if (underAge || child) {
        await hw.HwAds.setRequestOptions(hw.RequestOptions(
          tagForUnderAgeOfPromise: hw.UnderAge.PROMISE_TRUE,
          tagForChildProtection: child ? hw.TagForChild.TAG_FOR_CHILD_PROTECTION_TRUE : null,
          adContentClassification: hw.ContentClassification.AD_CONTENT_CLASSIFICATION_W,
          nonPersonalizedAd: hw.NonPersonalizedAd.ALLOW_NON_PERSONALIZED.value,
          requestLocation: false,
        ));
      }
      _ready = true;
      if (!_child) _loadInterstitial();
      _loadRewarded();
      return true;
    } catch (_) {
      _failures++;
      return false;
    }
  }

  void _loadInterstitial() {
    if (!_ready || _child) return;
    try {
      final ad = hw.InterstitialAd(
        adSlotId: HuaweiAdIds.interstitial,
        adParam: _param,
        listener: (hw.AdEvent event, {int? errorCode}) {
          switch (event) {
            case hw.AdEvent.loaded:
              _interstitialLoaded = true;
            case hw.AdEvent.failed:
              _failures++;
              _interstitialLoaded = false;
              // Yükleme hatası: bir sonraki gösterim denemesi yeniden yükler.
              if (_interstitialDone == null) _interstitial = null;
              _finishInterstitial(false);
            case hw.AdEvent.closed:
              _finishInterstitial(true);
            default:
              break;
          }
        },
      );
      _interstitial = ad;
      _interstitialLoaded = false;
      unawaited(ad.loadAd().catchError((Object _) {
        _failures++;
        return false;
      }));
    } catch (_) {
      _failures++;
    }
  }

  void _finishInterstitial(bool shown) {
    final done = _interstitialDone;
    if (done == null) return;
    _interstitialDone = null;
    final old = _interstitial;
    _interstitial = null;
    _interstitialLoaded = false;
    unawaited(old?.destroy().catchError((Object _) => false));
    _loadInterstitial();
    if (!done.isCompleted) done.complete(shown);
  }

  void _loadRewarded() {
    if (!_ready) return;
    try {
      final ad = hw.RewardAd(
        listener: (hw.RewardAdEvent? event, {hw.Reward? reward, int? errorCode}) {
          switch (event) {
            case hw.RewardAdEvent.loaded:
              _rewardedLoaded = true;
            case hw.RewardAdEvent.failedToLoad:
              _failures++;
              _rewardedLoaded = false;
              if (_rewardedDone == null) _rewarded = null;
              _finishRewarded();
            case hw.RewardAdEvent.rewarded:
              _earned = true;
            case hw.RewardAdEvent.closed:
              // Kapanış, ödül olayından önce gelebilir: kısa bir süre bekle.
              Future<void>.delayed(const Duration(milliseconds: 800), _finishRewarded);
            default:
              break;
          }
        },
      );
      _rewarded = ad;
      _rewardedLoaded = false;
      unawaited(ad.loadAd(adSlotId: HuaweiAdIds.rewarded, adParam: _param).catchError((Object _) {
        _failures++;
        return false;
      }));
    } catch (_) {
      _failures++;
    }
  }

  void _finishRewarded() {
    final done = _rewardedDone;
    if (done == null) return;
    _rewardedDone = null;
    final old = _rewarded;
    _rewarded = null;
    _rewardedLoaded = false;
    unawaited(old?.destroy().catchError((Object _) => false));
    _loadRewarded();
    if (!done.isCompleted) done.complete(_earned);
  }

  @override
  Future<bool> showInterstitial() async {
    // Çocuk modunda geçiş reklamı yok (üst katman da çağırmaz).
    if (_child || !_ready) return false;
    final ad = _interstitial;
    if (ad == null || !_interstitialLoaded) {
      if (ad == null) _loadInterstitial();
      return false;
    }
    final done = Completer<bool>();
    _interstitialDone = done;
    try {
      final ok = await ad.show();
      if (ok == false) _finishInterstitial(false);
    } catch (_) {
      _failures++;
      _finishInterstitial(false);
    }
    return done.future.timeout(const Duration(minutes: 2), onTimeout: () {
      _interstitialDone = null;
      return false;
    });
  }

  @override
  Future<bool> showRewarded() async {
    if (!_ready) return false;
    final ad = _rewarded;
    if (ad == null || !_rewardedLoaded) {
      if (ad == null) _loadRewarded();
      return false;
    }
    _earned = false;
    final done = Completer<bool>();
    _rewardedDone = done;
    try {
      final ok = await ad.show();
      if (ok == false) _finishRewarded();
    } catch (_) {
      _failures++;
      _finishRewarded();
    }
    return done.future.timeout(const Duration(minutes: 3), onTimeout: () {
      _rewardedDone = null;
      return _earned;
    });
  }

  /// Petal Ads'te ayrı bir gizlilik formu yok: kişiselleştirme uygulamanın
  /// kendi izin ekranından gelir (varsayılan kişiselleştirilmemiş).
  @override
  Future<void> openPrivacyOptions() async {}
}
