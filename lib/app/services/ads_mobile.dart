import 'dart:async';
import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../ad_ids.dart';
import 'ads.dart';

AdsService createAdsService() =>
    (Platform.isAndroid || Platform.isIOS) ? AdMobService() : NoAdsService();

class AdMobService implements AdsService {
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _ready = false;
  bool _personalized = true;
  int _failures = 0;

  @override
  bool get available => _ready;

  @override
  int get failures => _failures;

  String get _interstitialId =>
      Platform.isAndroid ? AdIds.androidInterstitial : AdIds.iosInterstitial;
  String get _rewardedId => Platform.isAndroid ? AdIds.androidRewarded : AdIds.iosRewarded;

  AdRequest get _request => AdRequest(nonPersonalizedAds: !_personalized);

  @override
  Future<bool> init({required bool underAge, required bool personalized, bool child = false}) async {
    _personalized = personalized && !underAge;
    try {
      // 1) Google UMP consent (shows the GDPR form only where required).
      final done = Completer<void>();
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(tagForUnderAgeOfConsent: underAge),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((FormError? e) {
            if (!done.isCompleted) done.complete();
          });
        },
        (FormError e) {
          _failures++;
          if (!done.isCompleted) done.complete();
        },
      );
      await done.future.timeout(const Duration(seconds: 15), onTimeout: () {});
      final canRequest = await ConsentInformation.instance.canRequestAds();
      if (!canRequest) return false;

      // 2) Child-directed / under-age tagging.
      await MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
        ageRestrictedTreatment: child
            ? AgeRestrictedTreatment.child
            : (underAge ? AgeRestrictedTreatment.teen : AgeRestrictedTreatment.unspecified),
        maxAdContentRating: underAge ? MaxAdContentRating.g : MaxAdContentRating.pg,
      ));
      await MobileAds.instance.initialize();
      _ready = true;
      _loadInterstitial();
      _loadRewarded();
      return true;
    } catch (_) {
      _failures++;
      return false;
    }
  }

  void _loadInterstitial() {
    if (!_ready) return;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: _request,
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitial = ad,
        onAdFailedToLoad: (e) {
          _failures++;
          _interstitial = null;
        },
      ),
    );
  }

  void _loadRewarded() {
    if (!_ready) return;
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: _request,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewarded = ad,
        onAdFailedToLoad: (e) {
          _failures++;
          _rewarded = null;
        },
      ),
    );
  }

  @override
  Future<bool> showInterstitial() async {
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return false;
    }
    _interstitial = null;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
        if (!done.isCompleted) done.complete(true);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _failures++;
        _loadInterstitial();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show();
    return done.future.timeout(const Duration(minutes: 2), onTimeout: () => false);
  }

  @override
  Future<bool> showRewarded() async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    var earned = false;
    final done = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (!done.isCompleted) done.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _failures++;
        _loadRewarded();
        if (!done.isCompleted) done.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (a, reward) => earned = true);
    return done.future.timeout(const Duration(minutes: 3), onTimeout: () => earned);
  }

  @override
  Future<void> openPrivacyOptions() async {
    try {
      ConsentForm.showPrivacyOptionsForm((FormError? e) {});
    } catch (_) {}
  }
}
