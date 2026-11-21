import 'clock.dart';
import 'rng.dart';
import 'save_data.dart';
import 'stats.dart';

class MissionTemplate {
  final String id;
  final String statKey;
  final List<int> targets; // easy..hard
  final int coinReward;
  final int xpReward;

  const MissionTemplate(this.id, this.statKey, this.targets,
      {this.coinReward = 50, this.xpReward = 40});
}

class Mission {
  final String id;
  final String statKey;
  final int target;
  final int coins;
  final int xp;
  final int gems;
  final bool weekly;

  const Mission(this.id, this.statKey, this.target, this.coins, this.xp,
      {this.gems = 0, this.weekly = false});

  int progress(SaveData s) =>
      (weekly ? s.weeklyProgress : s.dailyProgress)[statKey] ?? 0;
  bool done(SaveData s) => progress(s) >= target;
  bool claimed(SaveData s) => (weekly ? s.weeklyClaimed : s.dailyClaimed).contains(id);
}

/// Daily (3-5) and weekly (5-10) missions generated from templates,
/// identical for everyone on the same date and fully offline (doc 4.2, 6.1).
class MissionBoard {
  final String gameId;
  final List<MissionTemplate> templates;

  MissionBoard(this.gameId, List<MissionTemplate> gameTemplates)
      : templates = [...commonTemplates, ...gameTemplates];

  static const commonTemplates = <MissionTemplate>[
    MissionTemplate('win', Stat.levelsWon, [3, 5, 8]),
    MissionTemplate('play', Stat.levelsPlayed, [5, 8, 12]),
    MissionTemplate('stars', Stat.starsEarned, [6, 10, 18]),
    MissionTemplate('three', Stat.threeStars, [2, 4, 6], coinReward: 70),
    MissionTemplate('nohint', Stat.noHintWins, [2, 4, 6], coinReward: 60),
    MissionTemplate('coins', Stat.coinsEarned, [150, 300, 500]),
    MissionTemplate('daily', Stat.dailyLevels, [1, 1, 1], coinReward: 80),
    MissionTemplate('endless', Stat.endlessRuns, [1, 2, 3]),
    MissionTemplate('time', Stat.timeAttackRuns, [1, 2, 3]),
    MissionTemplate('challenge', Stat.challengesWon, [1, 2, 3], coinReward: 90),
    MissionTemplate('fast', Stat.fastWins, [1, 3, 5], coinReward: 70),
  ];

  static const int dailyCount = 4;
  static const int weeklyCount = 7;

  List<Mission> daily(String dayKey) => _build('d:$dayKey', dailyCount, false);
  List<Mission> weekly(String weekKey) => _build('w:$weekKey', weeklyCount, true);

  List<Mission> _build(String key, int count, bool weekly) {
    final r = SeededRandom(mixSeed([stableHash(gameId), stableHash(key)]));
    final pool = [...templates];
    r.shuffle(pool);
    final out = <Mission>[];
    for (final t in pool.take(count)) {
      final tier = r.nextInt(t.targets.length);
      final mul = weekly ? 5 : 1;
      out.add(Mission(
        '${weekly ? 'w' : 'd'}_${t.id}',
        t.statKey,
        t.targets[tier] * mul,
        t.coinReward * (tier + 1) * mul,
        t.xpReward * (tier + 1) * mul,
        gems: weekly ? 2 + tier : 0,
        weekly: weekly,
      ));
    }
    return out;
  }

  /// Resets progress when the day / week changes.
  void roll(SaveData s, DateTime now) {
    final d = DateKeys.day(now);
    if (s.dailyKey != d) {
      s.dailyKey = d;
      s.dailyProgress = {};
      s.dailyClaimed = {};
    }
    final w = DateKeys.week(now);
    if (s.weeklyKey != w) {
      if (s.weeklyKey.isNotEmpty) {
        s.stats['last_week_wins'] = s.weeklyProgress[Stat.levelsWon] ?? 0;
      }
      s.weeklyKey = w;
      s.weeklyProgress = {};
      s.weeklyClaimed = {};
      s.weeklyGoalTarget = 0;
    }
  }

  void track(SaveData s, String statKey, int amount) {
    s.dailyProgress[statKey] = (s.dailyProgress[statKey] ?? 0) + amount;
    s.weeklyProgress[statKey] = (s.weeklyProgress[statKey] ?? 0) + amount;
  }
}
