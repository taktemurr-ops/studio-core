import 'ads_stub.dart' if (dart.library.io) 'ads_mobile.dart' as impl;

/// Ad abstraction. Mobile uses Google AdMob (UMP consent included),
/// Web and tests use a no-op implementation. Load failures are tolerated
/// (doc 12.12) - the game never waits on an ad.
abstract class AdsService {
  bool get available;

  /// Runs the platform consent flow (GDPR/UMP). Returns true when ads may
  /// be requested.
  Future<bool> init({required bool underAge, required bool personalized, bool child = false});

  Future<bool> showInterstitial();

  /// Returns true only if the user earned the reward.
  Future<bool> showRewarded();

  Future<void> openPrivacyOptions();

  int get failures;

  static AdsService create() => impl.createAdsService();
}

class NoAdsService implements AdsService {
  @override
  bool get available => false;
  @override
  int get failures => 0;
  @override
  Future<bool> init({required bool underAge, required bool personalized, bool child = false}) async => false;
  @override
  Future<bool> showInterstitial() async => false;
  @override
  Future<bool> showRewarded() async => false;
  @override
  Future<void> openPrivacyOptions() async {}
}
