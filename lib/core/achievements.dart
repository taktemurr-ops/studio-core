import 'progression.dart';
import 'save_data.dart';
import 'stats.dart';

/// Context of the event that is being evaluated (for hidden achievements).
class AchievementContext {
  final DateTime now;
  final bool justWon;
  final int lastLevel;
  final int lastScore;
  final int lastSeconds;
  final bool usedHint;
  final int lossesBeforeWin;

  const AchievementContext({
    required this.now,
    this.justWon = false,
    this.lastLevel = 0,
    this.lastScore = 0,
    this.lastSeconds = 0,
    this.usedHint = false,
    this.lossesBeforeWin = 0,
  });
}

typedef AchievementCheck = bool Function(SaveData s, AchievementContext c);
typedef AchievementProgress = double Function(SaveData s);

class Achievement {
  final String id;

  /// Localization template key + parameters, e.g. ('ach_stat', {...}).
  final String titleKey;
  final Map<String, String> params;
  final bool hidden;
  final int coins;
  final int gems;
  final AchievementCheck check;
  final AchievementProgress progress;

  const Achievement({
    required this.id,
    required this.titleKey,
    required this.params,
    required this.check,
    required this.progress,
    this.hidden = false,
    this.coins = 50,
    this.gems = 0,
  });
}

/// Builds 100-300 achievements per game, with 50+ hidden ones (doc 4.3).
class AchievementCatalog {
  final List<Achievement> all;

  AchievementCatalog._(this.all);

  static const _tiers = [1, 10, 50, 100, 250, 500, 1000, 2500, 5000, 10000];
  static const _levelMilestones = [
    1, 10, 25, 50, 100, 200, 300, 500, 750, 1000, 1500, 2000, 3000, 5000,
    7500, 10000, 15000, 20000, 30000, 40000, 50000
  ];

  factory AchievementCatalog.build(List<GameStat> gameStats) {
    final list = <Achievement>[];

    void statLadder(String key, {int scale = 1, int maxTiers = 10}) {
      for (final t in _tiers.take(maxTiers)) {
        final target = t * scale;
        list.add(Achievement(
          id: 'st_${key}_$target',
          titleKey: 'ach_stat',
          params: {'stat': key, 'n': '$target'},
          coins: 20 + (target ~/ scale).clamp(0, 2000) ~/ 5,
          gems: t >= 1000 ? 5 : (t >= 100 ? 1 : 0),
          check: (s, c) => s.stat(key) >= target,
          progress: (s) => (s.stat(key) / target).clamp(0.0, 1.0),
        ));
      }
    }

    // Level milestones ("İlk bölümü tamamla", "10.000 bölüm tamamla" ...)
    for (final m in _levelMilestones) {
      list.add(Achievement(
        id: 'lvl_$m',
        titleKey: 'ach_levels',
        params: {'n': '$m'},
        coins: 25 + m ~/ 20,
        gems: m >= 1000 ? 10 : 0,
        check: (s, c) => s.completedLevels >= m,
        progress: (s) => (s.completedLevels / m).clamp(0.0, 1.0),
      ));
    }

    // Common stat ladders
    statLadder(Stat.starsEarned, scale: 3, maxTiers: 9);
    statLadder(Stat.threeStars, maxTiers: 8);
    statLadder(Stat.noHintWins, maxTiers: 7);
    statLadder(Stat.dailyLevels, maxTiers: 6);
    statLadder(Stat.weeklyLevels, maxTiers: 4);
    statLadder(Stat.challengesWon, maxTiers: 5);
    statLadder(Stat.endlessRuns, maxTiers: 6);
    statLadder(Stat.timeAttackRuns, maxTiers: 6);
    statLadder(Stat.missionsDone, maxTiers: 7);
    statLadder(Stat.coinsEarned, scale: 100, maxTiers: 7);
    statLadder(Stat.fastWins, maxTiers: 6);
    for (final g in gameStats) {
      statLadder(g.key, scale: g.scale, maxTiers: 9);
    }

    // Login streaks (incl. "100 günlük giriş serisi")
    for (final d in [3, 7, 14, 30, 60, 100, 180, 365]) {
      list.add(Achievement(
        id: 'streak_$d',
        titleKey: 'ach_streak',
        params: {'n': '$d'},
        coins: d * 5,
        gems: d >= 30 ? 5 : 0,
        check: (s, c) => s.bestLoginStreak >= d,
        progress: (s) => (s.bestLoginStreak / d).clamp(0.0, 1.0),
      ));
    }

    // Win streaks
    for (final d in [3, 5, 10, 20, 50]) {
      list.add(Achievement(
        id: 'wstreak_$d',
        titleKey: 'ach_winstreak',
        params: {'n': '$d'},
        coins: d * 10,
        check: (s, c) => s.stat(Stat.bestWinStreak) >= d,
        progress: (s) => (s.stat(Stat.bestWinStreak) / d).clamp(0.0, 1.0),
      ));
    }

    // Player level
    for (final l in [5, 10, 25, 50, 100, 150, 200, 250, 300, 400, 500]) {
      list.add(Achievement(
        id: 'plv_$l',
        titleKey: 'ach_plevel',
        params: {'n': '$l'},
        coins: l * 4,
        gems: l >= 100 ? 5 : 0,
        check: (s, c) => PlayerProgression.levelForXp(s.totalXp) >= l,
        progress: (s) =>
            (PlayerProgression.levelForXp(s.totalXp) / l).clamp(0.0, 1.0),
      ));
    }

    // Collection
    for (final n in [5, 10, 25, 50, 100, 150, 200]) {
      list.add(Achievement(
        id: 'col_$n',
        titleKey: 'ach_collection',
        params: {'n': '$n'},
        coins: n * 5,
        check: (s, c) => s.collection.length >= n,
        progress: (s) => (s.collection.length / n).clamp(0.0, 1.0),
      ));
    }

    // Worlds
    for (final w in [1, 5, 10, 25, 50, 100, 250, 500]) {
      list.add(Achievement(
        id: 'world_$w',
        titleKey: 'ach_worlds',
        params: {'n': '$w'},
        coins: w * 20,
        check: (s, c) => s.stat(Stat.worldsCompleted) >= w,
        progress: (s) => (s.stat(Stat.worldsCompleted) / w).clamp(0.0, 1.0),
      ));
    }

    list.addAll(_hidden());
    return AchievementCatalog._(list);
  }

  static List<Achievement> _hidden() {
    final h = <Achievement>[];
    void add(String id, AchievementCheck check, {int coins = 150}) => h.add(
          Achievement(
            id: 'secret_$id',
            titleKey: 'secret_$id',
            params: const {},
            hidden: true,
            coins: coins,
            gems: 2,
            check: check,
            progress: (s) => s.achievements.contains('secret_$id') ? 1 : 0,
          ),
        );

    add('night_owl', (s, c) => c.justWon && c.now.hour >= 0 && c.now.hour < 4);
    add('early_bird', (s, c) => c.justWon && c.now.hour >= 5 && c.now.hour < 7);
    add('weekend', (s, c) => c.justWon && c.now.weekday >= 6);
    add('new_year', (s, c) => c.justWon && c.now.month == 1 && c.now.day == 1);
    add('lucky_7', (s, c) => c.justWon && c.lastLevel == 7);
    add('lucky_77', (s, c) => c.justWon && c.lastLevel == 77);
    add('lucky_777', (s, c) => c.justWon && c.lastLevel == 777);
    add('lucky_7777', (s, c) => c.justWon && c.lastLevel == 7777);
    add('palindrome', (s, c) {
      if (!c.justWon || c.lastLevel < 100) return false;
      final t = '${c.lastLevel}';
      return t == t.split('').reversed.join();
    });
    add('comeback', (s, c) => c.justWon && c.lossesBeforeWin >= 3);
    add('stubborn', (s, c) => c.justWon && c.lossesBeforeWin >= 10);
    add('speedster', (s, c) => c.justWon && c.lastSeconds > 0 && c.lastSeconds <= 10);
    add('marathon', (s, c) => s.stat(Stat.playSeconds) >= 36000);
    add('ironman', (s, c) => s.stat(Stat.playSeconds) >= 360000);
    add('purist', (s, c) => s.stat(Stat.noHintWins) >= 500);
    add('hoarder', (s, c) => s.coins >= 10000);
    add('millionaire', (s, c) => s.stat(Stat.coinsEarned) >= 1000000);
    add('spender', (s, c) => s.stat(Stat.coinsSpent) >= 5000);
    add('gem_keeper', (s, c) => s.gems >= 100);
    add('wheel_lover', (s, c) => s.stat(Stat.wheelSpins) >= 30);
    add('loyal', (s, c) => s.stat(Stat.loginDays) >= 200);
    add('first_daily', (s, c) => s.stat(Stat.dailyLevels) >= 1);
    add('first_weekly', (s, c) => s.stat(Stat.weeklyLevels) >= 1);
    add('perfect_10', (s, c) => s.stat(Stat.threeStars) >= 10 && s.stat(Stat.levelsLost) == 0);
    add('no_hints_100', (s, c) => s.completedLevels >= 100 && s.stat(Stat.hintsUsed) == 0);
    add('record_breaker', (s, c) => s.stat(Stat.recordsBroken) >= 25);
    add('collector_theme', (s, c) => s.collection.where((i) => i.startsWith('theme_')).length >= 12);
    add('collector_skin', (s, c) => s.collection.where((i) => i.startsWith('skin_')).length >= 24);
    add('collector_badge', (s, c) => s.collection.where((i) => i.startsWith('badge_')).length >= 50);
    add('all_frames', (s, c) => s.collection.where((i) => i.startsWith('frame_')).length >= 20);
    add('dressed_up', (s, c) => s.activeTheme != 'theme_0' && s.activeSkin != 'skin_0');
    add('settings_explorer', (s, c) => s.stat('settings_opened') >= 5);
    add('stats_nerd', (s, c) => s.stat('stats_opened') >= 10);
    add('zen_master', (s, c) => s.stat(Stat.zenRuns) >= 50);
    add('time_lord', (s, c) => s.stat(Stat.timeAttackRuns) >= 200);
    add('endless_soul', (s, c) => s.stat(Stat.endlessRuns) >= 300);
    add('challenge_50', (s, c) => s.challengesDone.length >= 50);
    add('challenge_all', (s, c) => s.challengesDone.length >= 150);
    add('streak_master', (s, c) => s.stat(Stat.bestWinStreak) >= 100);
    add('double_up', (s, c) => s.stat(Stat.rewardedWatched) >= 50);
    add('undo_fan', (s, c) => s.stat(Stat.undosUsed) >= 500);
    add('hint_fan', (s, c) => s.stat(Stat.hintsUsed) >= 300);
    add('round_1000', (s, c) => c.justWon && c.lastLevel == 1000);
    add('round_5000', (s, c) => c.justWon && c.lastLevel == 5000);
    add('round_25000', (s, c) => c.justWon && c.lastLevel == 25000);
    add('round_50000', (s, c) => c.justWon && c.lastLevel == 50000);
    add('beyond', (s, c) => s.completedLevels > 50000);
    add('sessions_100', (s, c) => s.stat(Stat.sessions) >= 100);
    add('sessions_1000', (s, c) => s.stat(Stat.sessions) >= 1000);
    add('long_break', (s, c) => s.stat(Stat.comebackWins) >= 1);
    add('triple_comeback', (s, c) => s.stat(Stat.comebackWins) >= 3);
    add('morning_10', (s, c) => s.stat(Stat.morningWins) >= 10);
    add('night_10', (s, c) => s.stat(Stat.nightWins) >= 10);
    add('weekend_25', (s, c) => s.stat(Stat.weekendWins) >= 25);
    add('high_score', (s, c) => c.lastScore >= 100000);
    add('legend', (s, c) => PlayerProgression.levelForXp(s.totalXp) >= 251);
    return h;
  }

  /// Unlocks newly satisfied achievements and returns them.
  List<Achievement> evaluate(SaveData s, AchievementContext c) {
    final unlocked = <Achievement>[];
    for (final a in all) {
      if (s.achievements.contains(a.id)) continue;
      bool ok;
      try {
        ok = a.check(s, c);
      } catch (_) {
        ok = false;
      }
      if (ok) {
        s.achievements.add(a.id);
        unlocked.add(a);
      }
    }
    return unlocked;
  }

  int get hiddenCount => all.where((a) => a.hidden).length;
}
