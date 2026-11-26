import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/achievements.dart';
import '../core/clock.dart';
import '../core/daily.dart';
import '../core/game_rules.dart';
import '../core/global_daily.dart';
import '../core/game_session.dart';
import '../core/level_plan.dart';
import '../core/monetization.dart';
import '../core/save_data.dart';
import '../core/stats.dart';
import '../core/strings.dart';
import '../core/telemetry.dart';
import '../online/online_service.dart';
import 'covers.dart';
import 'game_api.dart';
import 'services/ads.dart';
import 'services/audio.dart';
import 'services/purchases.dart';
import 'services/cloud_telemetry.dart';

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

  /// Set when the game runs inside a hub app: shows a "back to games" button
  /// on the game's home screen.
  VoidCallback? exitToHub;
  String exitToHubLabel = '';

  /// Merkezden gelen kapak resmi (oyun ana ekranında simge yerine).
  GameCover? cover;
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

  Strings get strings {
    final extra = config.rules.strings;
    return Strings(save.language, extra: extra.isEmpty ? config.strings : {...extra, ...config.strings});
  }

  String t(String key, [Map<String, Object> p = const {}]) => strings.t(key, p);

  String get title => config.localized(config.title, strings.lang);

  bool get needsOnboarding => !save.ageGateDone || save.adConsent.isEmpty;

  /// Merkez uygulamada satın almaları ve reklam aralığını merkez yönetir.
  bool hubManaged = false;

  /// Ana ekran açılınca bir kez çalıştırılacak çevrimiçi iş (merkezden gelen
  /// davete katılma ya da yarım kalan maça dönme).
  Future<void> Function(BuildContext context)? pendingOnline;

  /// Merkez: geçiş reklamı şimdi gösterilebilir mi (tüm oyunlar için ortak süre).
  bool Function()? adGate;

  /// Merkez: geçiş reklamı gösterildi.
  void Function()? onInterstitialShown;

  Future<void> afterStart() async {
    audio
      ..sound = save.sound
      ..music = save.music
      ..haptics = save.haptics;
    analytics.enabled = save.analyticsConsent && !config.kidsMode && !session.emergency.analyticsDisabled;
    if (!hubManaged) {
      unawaited(CloudTelemetry.init(crashReports: !config.kidsMode, measurement: analytics.enabled));
    } else {
      unawaited(CloudTelemetry.setMeasurement(analytics.enabled));
    }
    CloudTelemetry.setKey('game', config.gameId);
    unawaited(audio.init().then((_) => audio.startMusic()));
    if (!hubManaged) unawaited(purchases.init(onPurchase));
    if (!needsOnboarding) unawaited(_initAds());
    unawaited(analytics.log('session_start', {'level': save.currentLevel}));
    unawaited(analytics.flush(CloudTelemetry.sink));
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
    // Çevrimiçi açıksa ilerleme buluta da yedeklenir (uygulama arka plana geçerken).
    final b = Online.instance.backend;
    if (Online.instance.ready && b != null) unawaited(b.saveBlob(config.gameId, save.encode()).catchError((_) {}));
  }

  /// Buluttaki yedeği bu cihaza yükler.
  Future<bool> restoreFromCloud() async {
    final b = Online.instance.backend;
    if (b == null) return false;
    final j = await b.loadBlob(config.gameId);
    if (j == null) return false;
    session.save = SaveData.decode(j);
    changed(saveNow: true);
    return true;
  }

  // ---- Onboarding / privacy ------------------------------------------------
  /// İlk açılış: yalnızca gizlilik tercihi (yaş sorulmaz; oyunlar genel
  /// kitleye yöneliktir, çocuk oyunlarında [GameConfig.kidsMode] açıktır).
  Future<void> completeOnboarding({required bool acceptAll}) async {
    applyConsent(acceptAll);
    await _initAds();
  }

  /// Tercihi kaydeder (merkez uygulama bunu her oyuna bir kez uygular).
  void applyConsent(bool acceptAll) {
    save.ageGateDone = true;
    save.underAge = config.kidsMode;
    save.adConsent = acceptAll && !save.underAge ? 'granted' : 'denied';
    save.analyticsConsent = acceptAll && !save.underAge;
    analytics.enabled = save.analyticsConsent;
    unawaited(CloudTelemetry.setMeasurement(analytics.enabled));
    changed(saveNow: true);
  }

  void setAnalyticsConsent(bool v) {
    save.analyticsConsent = v && !save.underAge;
    analytics.enabled = save.analyticsConsent;
    unawaited(CloudTelemetry.setMeasurement(analytics.enabled));
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

  // ---- Günün Bulmacası ---------------------------------------------------------
  /// Günün Bulmacası açıldığında oynanan UTC günü (sonuç bu güne yazılır).
  String? globalDailyDay;

  /// Son günlük sonucun kaydı (true: günün ilk çözümü, sıralamaya girer).
  Future<bool>? pendingDaily;

  /// Son kaydedilen günlük sonuç.
  DailyEntry? lastDaily;

  /// Merkezdeki bütün oyunlarla ortak yerel günlük kayıt.
  GlobalDailyStore get dailyStore => GlobalDailyStore.of(session.store.backend);

  /// Bugünün (UTC) ortak bölümünü oynat: [globalDailyDay] ayarlanır.
  LevelSpec startGlobalDaily([DateTime? now]) {
    final day = GlobalDaily.utcDay(now ?? DateTime.now());
    globalDailyDay = day;
    return config.rules.globalDailySpec(day);
  }

  void _maybeDaily(LevelSpec spec, RoundResult r, int elapsedMs) {
    final day = globalDailyDay;
    final rules = config.rules;
    if (day == null || !rules.globalDaily || spec.mode != GameModeId.daily) return;
    if (spec.seed != rules.globalDailySpec(day).seed) return;
    globalDailyDay = null;
    final rank = rules.dailyRank;
    if (!r.won && !(rank == DailyRank.score && r.score > 0)) return;
    final ms = elapsedMs > 0 ? elapsedMs : r.seconds * 1000;
    final e = DailyEntry(
      gameId: config.gameId,
      day: day,
      // Sunucu kuralları: 1 sn – 24 sa, hamle ≤ 100.000, puan < 10^9.
      ms: ms.clamp(1000, 86400000),
      moves: r.moves.clamp(0, 100000),
      score: r.score.clamp(0, 999999999),
      rank: rank,
      lang: rules.dailyPerLanguage ? strings.lang : '',
    );
    lastDaily = e;
    pendingDaily = _recordDaily(e);
  }

  Future<bool> _recordDaily(DailyEntry e) async {
    final store = dailyStore;
    final first = await store.record(e);
    // Çocuk oyunlarında çevrimiçi sıralama yok; sonuç yalnızca cihazda kalır.
    if (first && !config.kidsMode && await Online.instance.submitDailyResult(e)) await store.markSynced(e);
    return first;
  }

  // ---- Rounds -------------------------------------------------------------------
  LevelOutcome finishRound(LevelSpec spec, RoundResult r, {int elapsedMs = 0}) {
    _maybeDaily(spec, r, elapsedMs);
    final out = session.completeRound(spec, r);
    if (r.won && (spec.mode == GameModeId.daily || spec.mode == GameModeId.weekly)) {
      unawaited(Online.instance.submitDaily(config.gameId, dayKey(), save.weeklyKey, r.score));
    }
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
    // Çocuk oyunlarında geçiş reklamı yok (aile politikası); yalnızca
    // ebeveynin isteğiyle açılan ödüllü reklamlar kalabilir.
    if (config.kidsMode) return;
    final gate = adGate;
    if (gate != null && !gate()) return;
    await audio.pauseAll();
    final shown = await ads.showInterstitial();
    await audio.resumeAll();
    if (shown) {
      session.adPolicy.markInterstitialShown(save, session.now());
      onInterstitialShown?.call();
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
    unawaited(analytics.flush(CloudTelemetry.sink));
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
