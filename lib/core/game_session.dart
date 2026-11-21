import 'achievements.dart';
import 'clock.dart';
import 'collection.dart';
import 'daily.dart';
import 'game_rules.dart';
import 'level_plan.dart';
import 'missions.dart';
import 'monetization.dart';
import 'progression.dart';
import 'save_data.dart';
import 'save_store.dart';
import 'stats.dart';
import 'telemetry.dart';

class LevelOutcome {
  final Reward reward;
  final int xpGained;
  final int playerLevelBefore;
  final int playerLevelAfter;
  final List<Achievement> achievements;
  final List<CollectionItem> items;
  final bool newRecord;
  final bool showInterstitial;
  final bool worldCompleted;

  const LevelOutcome({
    required this.reward,
    required this.xpGained,
    required this.playerLevelBefore,
    required this.playerLevelAfter,
    required this.achievements,
    required this.items,
    required this.newRecord,
    required this.showInterstitial,
    required this.worldCompleted,
  });

  bool get leveledUp => playerLevelAfter > playerLevelBefore;
}

class StartupReport {
  final int daysAway;
  final Reward? comeback;
  final bool loginRewardReady;
  final LoadOutcome loadOutcome;
  final bool safeMode;

  const StartupReport(
      this.daysAway, this.comeback, this.loginRewardReady, this.loadOutcome, this.safeMode);
}

/// Single owner of the player's state. Every system in the doc is driven
/// from here so that the UI layer stays thin and everything is testable.
class GameSession {
  final GameRules rules;
  final SaveStore store;
  final ClockGuard clock;
  final LevelPlanner planner;
  final MissionBoard missions;
  final AchievementCatalog achievementCatalog;
  final CollectionCatalog collection;
  final DailySystems daily;
  final AdPolicy adPolicy;
  final EmergencyConfig emergency;
  final AnalyticsQueue? analytics;
  final ErrorJournal? errors;

  SaveData save = SaveData();
  late AdaptiveDifficulty adaptive;
  int lossesSinceWin = 0;

  GameSession({
    required this.rules,
    required this.store,
    ClockGuard? clock,
    AdPolicy? adPolicy,
    EmergencyConfig? emergency,
    this.analytics,
    this.errors,
    int themeCount = 12,
  })  : clock = clock ?? ClockGuard(),
        adPolicy = adPolicy ?? const AdPolicy(),
        emergency = emergency ?? EmergencyConfig(),
        planner = LevelPlanner(
            gameId: rules.gameId,
            optionalMechanics: rules.optionalMechanics,
            themeCount: themeCount),
        missions = MissionBoard(rules.gameId, rules.missionTemplates),
        achievementCatalog = AchievementCatalog.build(rules.gameStats),
        collection = CollectionCatalog.build(themes: themeCount),
        daily = DailySystems(rules.gameId);

  DateTime now() => clock.trustedNow(save);

  Future<StartupReport> start({bool safeMode = false}) async {
    save = await store.load();
    final t = now();
    if (save.firstLaunchMs == 0) save.firstLaunchMs = t.millisecondsSinceEpoch;
    if (safeMode) save.resume = {};
    adaptive = AdaptiveDifficulty(save.recentResults);
    missions.roll(save, t);
    final days = daily.registerVisit(save, t);
    final comeback = daily.comebackReward(save, t, days);
    save.addStat(Stat.sessions);
    collection.autoUnlock(save);
    save.lastActiveMs = t.millisecondsSinceEpoch;
    await persist();
    return StartupReport(days, comeback, daily.loginRewardAvailable(save, t),
        store.lastOutcome, safeMode);
  }

  Future<bool> persist() async {
    final ok = await store.save(save);
    if (!ok) await errors?.record(ErrorCategory.save, 'save failed');
    return ok;
  }

  // ---- Levels ---------------------------------------------------------------
  LevelSpec campaignSpec(int level) =>
      planner.spec(level, difficultyOffset: adaptive.offset);

  LevelSpec get nextCampaignSpec => campaignSpec(save.currentLevel);

  void _emit(String key, [int n = 1]) {
    if (n == 0) return;
    save.addStat(key, n);
    missions.track(save, key, n);
  }

  /// Records a finished round and returns everything the result screen shows.
  LevelOutcome completeRound(LevelSpec spec, RoundResult r) {
    final t = now();
    missions.roll(save, t);
    final levelBefore = PlayerProgression.levelForXp(save.totalXp);
    _emit(Stat.levelsPlayed);
    _emit(Stat.playSeconds, r.seconds);
    _emit(Stat.hintsUsed, r.hintsUsed);
    _emit(Stat.undosUsed, r.undosUsed);
    r.gameStats.forEach(_emit);

    var reward = const Reward();
    var xp = 0;
    var worldDone = false;
    final lossesBefore = lossesSinceWin;

    if (r.won) {
      lossesSinceWin = 0;
      adaptive.record(true);
      _emit(Stat.levelsWon);
      _emit(Stat.starsEarned, r.stars);
      if (r.stars >= 3) _emit(Stat.threeStars);
      if (r.hintsUsed == 0) _emit(Stat.noHintWins);
      if (r.seconds > 0 && r.seconds <= 30) _emit(Stat.fastWins);
      save.addStat(Stat.winStreak);
      save.maxStat(Stat.bestWinStreak, save.stat(Stat.winStreak));
      if (t.hour < 5) save.addStat(Stat.nightWins);
      if (t.hour >= 5 && t.hour < 9) save.addStat(Stat.morningWins);
      if (t.weekday >= 6) save.addStat(Stat.weekendWins);

      xp = PlayerProgression.xpForWin(difficulty: spec.difficulty, stars: r.stars);
      var coins = spec.reward + r.stars * 5;
      switch (spec.mode) {
        case GameModeId.campaign:
          final firstClear = spec.levelId > save.highestLevel;
          if (!firstClear) coins = (coins / 3).ceil();
          save.setStars(spec.levelId, r.stars);
          if (firstClear) {
            save.highestLevel = spec.levelId;
            save.completedLevels++;
            if (spec.levelId % LevelPlanner.levelsPerWorld == 0) {
              save.addStat(Stat.worldsCompleted);
              worldDone = true;
            }
          }
          if (spec.levelId == save.currentLevel) save.currentLevel++;
          break;
        case GameModeId.daily:
          if (save.dailyLevelDoneDay != DateKeys.day(t)) {
            save.dailyLevelDoneDay = DateKeys.day(t);
            _emit(Stat.dailyLevels);
          } else {
            coins = 0;
          }
          break;
        case GameModeId.weekly:
          if (save.weeklyLevelDoneWeek != DateKeys.week(t)) {
            save.weeklyLevelDoneWeek = DateKeys.week(t);
            _emit(Stat.weeklyLevels);
          } else {
            coins = 0;
          }
          break;
        case GameModeId.challenge:
          final key = 'c${spec.levelId}';
          if (!save.challengesDone.contains(key)) {
            save.challengesDone.add(key);
            _emit(Stat.challengesWon);
          } else {
            coins = (coins / 4).ceil();
          }
          break;
        case GameModeId.endless:
          _emit(Stat.endlessRuns);
          break;
        case GameModeId.timeAttack:
          _emit(Stat.timeAttackRuns);
          break;
        case GameModeId.zen:
          _emit(Stat.zenRuns);
          coins = (coins / 2).ceil();
          break;
        case GameModeId.practice:
          coins = 0;
          xp = (xp / 4).ceil();
          break;
      }
      reward = Reward(coins: coins, xp: xp, gems: spec.milestone ? 25 : 0);
      reward.applyTo(save);
    } else {
      lossesSinceWin++;
      adaptive.record(false);
      _emit(Stat.levelsLost);
      save.stats[Stat.winStreak] = 0;
      if (spec.mode == GameModeId.endless) _emit(Stat.endlessRuns);
      if (spec.mode == GameModeId.timeAttack) _emit(Stat.timeAttackRuns);
      if (spec.mode == GameModeId.zen) _emit(Stat.zenRuns);
      // Consolation XP keeps progress flowing (no "dead" sessions).
      xp = 5;
      save.totalXp += xp;
    }
    save.recentResults = List.of(adaptive.recent);

    final newRecord = daily.submitScore(save, spec.mode.name, r.score, t);
    if (r.score > 0) save.maxStat(Stat.bestScore, r.score);

    final ach = achievementCatalog.evaluate(
      save,
      AchievementContext(
        now: t,
        justWon: r.won,
        lastLevel: spec.mode == GameModeId.campaign ? spec.levelId : 0,
        lastScore: r.score,
        lastSeconds: r.seconds,
        usedHint: r.hintsUsed > 0,
        lossesBeforeWin: r.won ? lossesBefore : 0,
      ),
    );
    for (final a in ach) {
      Reward(coins: a.coins, gems: a.gems).applyTo(save);
    }
    final items = collection.autoUnlock(save);
    if (items.isNotEmpty) save.addStat(Stat.itemsUnlocked, items.length);

    final showAd = r.won &&
        spec.mode == GameModeId.campaign &&
        adPolicy.shouldShowInterstitial(save, t, emergencyAdsOff: emergency.adsDisabled);
    save.resume = {};
    save.lastActiveMs = t.millisecondsSinceEpoch;

    analytics?.log(r.won ? 'level_win' : 'level_fail', {
      'mode': spec.mode.name,
      'level': spec.levelId,
      'difficulty': spec.difficulty,
      'seconds': r.seconds,
      'stars': r.stars,
    });

    return LevelOutcome(
      reward: reward,
      xpGained: xp,
      playerLevelBefore: levelBefore,
      playerLevelAfter: PlayerProgression.levelForXp(save.totalXp),
      achievements: ach,
      items: items,
      newRecord: newRecord,
      showInterstitial: showAd,
      worldCompleted: worldDone,
    );
  }

  // ---- Missions -----------------------------------------------------------------
  List<Mission> get dailyMissions => missions.daily(save.dailyKey);
  List<Mission> get weeklyMissions => missions.weekly(save.weeklyKey);

  Reward? claimMission(Mission m) {
    if (!m.done(save) || m.claimed(save)) return null;
    final r = Reward(coins: m.coins, xp: m.xp, gems: m.gems);
    r.applyTo(save);
    (m.weekly ? save.weeklyClaimed : save.dailyClaimed).add(m.id);
    save.addStat(Stat.missionsDone);
    achievementCatalog.evaluate(save, AchievementContext(now: now()));
    collection.autoUnlock(save);
    return r;
  }

  // ---- Helpers for boosters --------------------------------------------------
  bool spendHint() {
    if (save.hints <= 0) return false;
    save.hints--;
    return true;
  }

  bool spendCoins(int n) {
    if (save.coins < n) return false;
    save.coins -= n;
    save.addStat(Stat.coinsSpent, n);
    return true;
  }

  bool spendBooster() {
    if (save.boosters <= 0) return false;
    save.boosters--;
    return true;
  }

  int get playerLevel => PlayerProgression.levelForXp(save.totalXp);
}
