import 'clock.dart';
import 'daily.dart';
import 'save_data.dart';
import 'stats.dart';

/// Store product ids. The same ids must be created in Google Play Console
/// and App Store Connect (per game bundle id).
class Products {
  static const removeAds = 'remove_ads';
  static const premium = 'premium_pack';
  static const coinsSmall = 'coins_small';
  static const coinsLarge = 'coins_large';
  static const hintPack = 'hint_pack';
  static const starterPack = 'starter_pack';

  static const nonConsumable = {removeAds, premium};
  static const consumable = {coinsSmall, coinsLarge, hintPack, starterPack};
  static const all = {...nonConsumable, ...consumable};

  static Reward grantFor(String id) {
    switch (id) {
      case coinsSmall:
        return const Reward(coins: 1000);
      case coinsLarge:
        return const Reward(coins: 6000, gems: 20);
      case hintPack:
        return const Reward(hints: 15);
      case starterPack:
        return const Reward(coins: 2000, hints: 5, boosters: 5, gems: 10);
      case premium:
        return const Reward(coins: 5000, hints: 20, gems: 50);
      default:
        return const Reward();
    }
  }
}

enum PurchaseState { pending, purchased, restored, failed, canceled, refunded }

/// Durable, idempotent entitlement ledger (doc 7.2): verification hook,
/// restore, failed/pending handling, refund revocation, premium protection.
class PurchaseLedger {
  /// Returns a message key for the UI.
  static String apply(SaveData s, {
    required String productId,
    required String purchaseId,
    required PurchaseState state,
    required bool verified,
  }) {
    if (!Products.all.contains(productId)) return 'purchase_unknown';
    switch (state) {
      case PurchaseState.pending:
        return 'purchase_pending';
      case PurchaseState.failed:
        return 'purchase_failed';
      case PurchaseState.canceled:
        return 'purchase_canceled';
      case PurchaseState.refunded:
        if (Products.nonConsumable.contains(productId)) {
          s.ownedProducts.remove(productId);
          if (productId == Products.removeAds && !s.ownedProducts.contains(Products.premium)) {
            s.removeAds = false;
          }
          if (productId == Products.premium) {
            s.premium = false;
            if (!s.ownedProducts.contains(Products.removeAds)) s.removeAds = false;
          }
        }
        return 'purchase_refunded';
      case PurchaseState.purchased:
      case PurchaseState.restored:
        if (!verified) return 'purchase_unverified';
        // Idempotency: never grant the same transaction twice.
        if (purchaseId.isNotEmpty && s.processedPurchaseIds.contains(purchaseId)) {
          return 'purchase_duplicate';
        }
        if (Products.nonConsumable.contains(productId)) {
          final already = s.ownedProducts.contains(productId);
          s.ownedProducts.add(productId);
          if (productId == Products.removeAds) s.removeAds = true;
          if (productId == Products.premium) {
            s.premium = true;
            s.removeAds = true;
          }
          if (!already && state == PurchaseState.purchased) {
            Products.grantFor(productId).applyTo(s);
          }
        } else if (state == PurchaseState.purchased) {
          Products.grantFor(productId).applyTo(s);
        }
        if (purchaseId.isNotEmpty) {
          s.processedPurchaseIds.add(purchaseId);
          if (s.processedPurchaseIds.length > 500) {
            s.processedPurchaseIds = s.processedPurchaseIds.skip(250).toSet();
          }
        }
        return state == PurchaseState.restored ? 'purchase_restored' : 'purchase_ok';
    }
  }
}

/// Ad frequency rules (doc 7.1: "oyun deneyimini bozmayacak sıklıkta").
class AdPolicy {
  final int interstitialEveryLevels;
  final Duration interstitialCooldown;
  final int firstAdAfterLevel;
  final int maxRewardedPerDay;

  const AdPolicy({
    this.interstitialEveryLevels = 4,
    this.interstitialCooldown = const Duration(minutes: 3),
    this.firstAdAfterLevel = 8,
    this.maxRewardedPerDay = 20,
  });

  bool adsAllowed(SaveData s, {required bool emergencyAdsOff}) =>
      !emergencyAdsOff && s.adConsent.isNotEmpty;

  /// Call after each finished level. True = show an interstitial now.
  bool shouldShowInterstitial(SaveData s, DateTime now, {required bool emergencyAdsOff}) {
    if (s.removeAds || s.premium || !adsAllowed(s, emergencyAdsOff: emergencyAdsOff)) {
      return false;
    }
    if (s.completedLevels < firstAdAfterLevel) return false;
    s.levelsSinceInterstitial++;
    if (s.levelsSinceInterstitial < interstitialEveryLevels) return false;
    if (now.millisecondsSinceEpoch - s.lastInterstitialMs <
        interstitialCooldown.inMilliseconds) {
      return false;
    }
    return true;
  }

  void markInterstitialShown(SaveData s, DateTime now) {
    s.levelsSinceInterstitial = 0;
    s.lastInterstitialMs = now.millisecondsSinceEpoch;
  }

  /// Rewarded ads are always optional and capped per day.
  bool canOfferRewarded(SaveData s, DateTime now, {required bool emergencyAdsOff}) {
    if (!adsAllowed(s, emergencyAdsOff: emergencyAdsOff)) return false;
    final today = DateKeys.day(now);
    if (s.rewardedDay != today) {
      s.rewardedDay = today;
      s.rewardedToday = 0;
    }
    return s.rewardedToday < maxRewardedPerDay;
  }

  void markRewarded(SaveData s) {
    s.rewardedToday++;
    s.addStat(Stat.rewardedWatched);
  }
}
