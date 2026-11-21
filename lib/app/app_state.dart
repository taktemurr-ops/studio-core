import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/achievements.dart';
import '../core/clock.dart';
import '../core/daily.dart';
import '../core/game_rules.dart';
import '../core/game_session.dart';
import '../core/level_plan.dart';
import '../core/monetization.dart';
import '../core/save_data.dart';
import '../core/stats.dart';
import '../core/strings.dart';
import '../core/telemetry.dart';
import 'game_api.dart';
import 'services/ads.dart';
import 'services/audio.dart';
import 'services/purchases.dart';

/// Riverpod entry point. Overridden in [bootstrap] with the loaded state.
final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  throw UnimplementedError('AppState must be provided by bootstrap()');
});

/// App-wide state: the [GameSession] plus platform services.
class AppState extends ChangeNotifier {
  final GameConfig config;
  final GameSession session;
  final AudioService audio;
  final AdsService ads;
  final PurchaseService purchases;
  final AnalyticsQueue analytics;
  final ErrorJournal errors;
  final PerformanceMonitor perf;
  StartupReport? startup;
  String? toast;
  Timer? _saveDebounce;

  AppState({
    required this.config,
    required this.session,
    required this.audio,
    required this.ads,
    required this.purchases,
    required this.analytics,
    required this.errors,
    required this.perf,
  });

  SaveData get save => session.save;

  Strings get strings => Strings(save.language, extra: config.strings);
  String t(String key, [Map<String, Object> p = const {}]) => strings.t(key, p);

  String get title => config.localized(config.title, strings.lang);

  bool get needsOnboarding => !save.ageGateDone || save.adConsent.isEmpty;

  Future<void> afterStart() async {
    audio
      ..sound = save.sound
      ..music = save.music
      ..haptics = save.haptics;
    analytics.enabled = save.analyticsConsent && !config.kidsMode && !session.emergency.analyticsDisabled;
    unawaited(audio.init().then((_) => audio.startMusic()));
    unawaited(purchases.init(onPurchase));
    if (!needsOnboarding) unawaited(_initAds());
    unawaited(analytics.log('session_start', {'level': save.currentLevel}));
    unawaited(analytics.flush(NoopSink()));
  }

  Future<void> _initAds() async {
    if (session.emergency.adsDisabled || errors.safeMode) return;
    await ads.init(
        underAge: save.underAge || config.kidsMode,
        personalized: save.adConsent == 'granted' && !config.kidsMode,
        child: config.kidsMode);
  }

  // ---- Persistence -------------------------------------------------------
  void changed({bool saveNow = false}) {
    notifyListeners();
    _saveDebounce?.cancel();
    if (saveNow) {
      unawaited(session.persist());
    } else {
      _saveDebounce = Timer(const Duration(milliseconds: 400), () => session.persist());
    }
  }

  Future<void> flushSave() async {
    _saveDebounce?.cancel();
    await session.persist();
  }

  // ---- Onboarding / privacy ------------------------------------------------
  Future<void> completeOnboarding({required int birthYear, required bool acceptAll}) async {
    final age = DateTime.now().year - birthYear;
    save.ageGateDone = true;
    save.underAge = config.kidsMode || age < 16;
    save.adConsent = acceptAll && !save.underAge ? 'granted' : 'denied';
    save.analyticsConsent = acceptAll && !save.underAge;
    analytics.enabled = save.analyticsConsent;
    changed(saveNow: true);
    await _initAds();
  }

  void setAnalyticsConsent(bool v) {
    save.analyticsConsent = v && !save.underAge;
    analytics.enabled = save.analyticsConsent;
    if (!v) unawaited(analytics.clear());
    changed();
  }

  Future<void> deleteAllData() async {
    await session.store.wipe();
    await analytics.clear();
    session.save = SaveData();
    changed(saveNow: true);
  }

  // ---- Settings ----------------------------------------------------------------
  void updateSettings(void Function(SaveData s) f) {
    f(save);
    audio
      ..sound = save.sound
      ..music = save.music
      ..haptics = save.haptics;
    if (save.music) {
      unawaited(audio.startMusic());
    } else {
      unawaited(audio.stopMusic());
    }
    changed();
  }

  // ---- Rounds -------------------------------------------------------------------
  LevelOutcome finishRound(LevelSpec spec, RoundResult r) {
    final out = session.completeRound(spec, r);
    audio.play(r.won ? Sfx.win : Sfx.lose);
    changed(saveNow: true);
    return out;
  }

  void saveResume(LevelSpec spec, Map<String, Object?> state) {
    save.resume = {'spec': spec.toJson(), 'state': state};
    changed();
  }

  void clearResume() {
    save.resume = {};
    changed();
  }

  /// Hint economy: free hint if owned, else rewarded ad, else coins.
  Future<bool> useHint() async {
    if (session.spendHint()) {
      changed();
      return true;
    }
    return false;
  }

  Future<bool> watchRewarded() async {
    final now = session.now();
    if (!session.adPolicy.canOfferRewarded(save, now,
        emergencyAdsOff: session.emergency.adsDisabled)) {
      return false;
    }
    await audio.pauseAll();
    final ok = await ads.showRewarded();
    await audio.resumeAll();
    if (ok) {
      session.adPolicy.markRewarded(save);
      changed();
    }
    return ok;
  }

  Future<void> maybeInterstitial(LevelOutcome o) async {
    if (!o.showInterstitial || !ads.available) return;
    await audio.pauseAll();
    final shown = await ads.showInterstitial();
    await audio.resumeAll();
    if (shown) {
      session.adPolicy.markInterstitialShown(save, session.now());
      changed();
    }
  }

  // ---- Daily ---------------------------------------------------------------------
  Reward? claimLogin() {
    final r = session.daily.claimLogin(save, session.now());
    if (r != null) {
      audio.play(Sfx.coin);
      changed(saveNow: true);
    }
    return r;
  }

  Reward? spinWheel() {
    final r = session.daily.spinWheel(save, session.now());
    if (r != null) changed(saveNow: true);
    return r;
  }

  Reward? claimSurprise() {
    final r = session.daily.claimSurprise(save, session.now());
    if (r != null) changed(saveNow: true);
    return r;
  }

  // ---- Shop ------------------------------------------------------------------------
  void onPurchase(PurchaseEvent e) {
    final state = switch (e.status) {
      'pending' => PurchaseState.pending,
      'purchased' => PurchaseState.purchased,
      'restored' => PurchaseState.restored,
      'canceled' => PurchaseState.canceled,
      _ => PurchaseState.failed,
    };
    final key = PurchaseLedger.apply(save,
        productId: e.productId, purchaseId: e.purchaseId, state: state, verified: e.verified);
    toast = t(key);
    if (key == 'purchase_ok') audio.play(Sfx.coin);
    session.collection.autoUnlock(save);
    unawaited(analytics.log('purchase', {'product': e.productId, 'result': key}));
    changed(saveNow: true);
  }

  String? takeToast() {
    final t = toast;
    toast = null;
    return t;
  }

  // ---- Lifecycle ------------------------------------------------------------------
  void onPaused() {
    unawaited(flushSave());
    unawaited(audio.pauseAll());
  }

  void onResumed() {
    final now = session.now();
    session.missions.roll(save, now);
    session.daily.registerVisit(save, now);
    unawaited(audio.resumeAll());
    unawaited(analytics.flush(NoopSink()));
    changed();
  }

  String dayKey() => DateKeys.day(session.now());

  void openedScreen(String stat) {
    save.addStat(stat);
    if (stat == 'stats_opened' || stat == 'settings_opened') {
      session.achievementCatalog.evaluate(save, AchievementContext(now: session.now()));
    }
    changed();
  }

  int get winRatePercent {
    final played = save.stat(Stat.levelsPlayed);
    return played == 0 ? 0 : (save.stat(Stat.levelsWon) * 100 / played).round();
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    purchases.dispose();
    super.dispose();
  }
}
