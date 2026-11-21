import 'clock.dart';
import 'rng.dart';
import 'save_data.dart';
import 'stats.dart';

class Reward {
  final int coins;
  final int gems;
  final int hints;
  final int boosters;
  final int xp;
  final String? itemId;

  const Reward({
    this.coins = 0,
    this.gems = 0,
    this.hints = 0,
    this.boosters = 0,
    this.xp = 0,
    this.itemId,
  });

  bool get isEmpty =>
      coins == 0 && gems == 0 && hints == 0 && boosters == 0 && xp == 0 && itemId == null;

  Reward operator +(Reward o) => Reward(
        coins: coins + o.coins,
        gems: gems + o.gems,
        hints: hints + o.hints,
        boosters: boosters + o.boosters,
        xp: xp + o.xp,
        itemId: itemId ?? o.itemId,
      );

  Reward scaled(int f) => Reward(
      coins: coins * f, gems: gems * f, hints: hints * f, boosters: boosters * f, xp: xp, itemId: itemId);

  void applyTo(SaveData s) {
    s.coins += coins;
    s.gems += gems;
    s.hints += hints;
    s.boosters += boosters;
    s.totalXp += xp;
    if (coins > 0) s.addStat(Stat.coinsEarned, coins);
    if (itemId != null) s.collection.add(itemId!);
  }
}

/// Daily login, daily gift, surprise, comeback, daily record and weekly goal
/// (doc 4.2 items 1, 6, 7, 8, 9, 10). All computed locally from the trusted
/// clock so they run for 24 months without any server.
class DailySystems {
  final String gameId;
  DailySystems(this.gameId);

  static const loginCycle = <Reward>[
    Reward(coins: 50),
    Reward(coins: 75, hints: 1),
    Reward(coins: 100),
    Reward(coins: 125, boosters: 1),
    Reward(coins: 150, hints: 1),
    Reward(coins: 200, gems: 1),
    Reward(coins: 300, gems: 3, hints: 2, boosters: 1),
  ];

  /// Updates the streak on app open. Returns days since previous visit.
  int registerVisit(SaveData s, DateTime now) {
    final today = DateKeys.day(now);
    if (s.lastLoginDay == today) return 0;
    final gap = s.lastLoginDay.isEmpty ? 0 : DateKeys.daysBetween(s.lastLoginDay, today);
    if (gap == 1) {
      s.loginStreak++;
    } else {
      s.loginStreak = 1;
    }
    if (s.loginStreak > s.bestLoginStreak) s.bestLoginStreak = s.loginStreak;
    s.lastLoginDay = today;
    s.addStat(Stat.loginDays);
    return gap;
  }

  bool loginRewardAvailable(SaveData s, DateTime now) =>
      s.lastLoginRewardDay != DateKeys.day(now);

  Reward loginRewardPreview(SaveData s) =>
      loginCycle[(s.loginStreak - 1).clamp(0, 1 << 20) % loginCycle.length];

  Reward? claimLogin(SaveData s, DateTime now) {
    if (!loginRewardAvailable(s, now)) return null;
    final r = loginRewardPreview(s);
    r.applyTo(s);
    s.lastLoginRewardDay = DateKeys.day(now);
    return r;
  }

  // ---- Daily gift ----------------------------------------------------------
  // Replaces the former lucky wheel: no chance element at all. The gift for
  // each day is fixed by a public rotation and shown before it is opened, so
  // there is nothing that resembles a game of chance (store policy, all ages).
  // API names keep the old "wheel" wording so existing saves stay compatible.
  static const wheelSlices = <Reward>[
    Reward(coins: 50),
    Reward(hints: 1),
    Reward(coins: 100),
    Reward(boosters: 1),
    Reward(coins: 75),
    Reward(gems: 1),
    Reward(coins: 150, hints: 1),
  ];

  bool wheelAvailable(SaveData s, DateTime now) => s.lastWheelDay != DateKeys.day(now);

  /// Index of today's gift: plain rotation by calendar day, no randomness.
  int wheelResult(SaveData s, DateTime now) {
    final d = DateKeys.daysBetween('2026-01-01', DateKeys.day(now));
    final n = wheelSlices.length;
    return ((d % n) + n) % n;
  }

  /// Today's gift, for showing it before it is opened.
  Reward todaysGift(DateTime now) => wheelSlices[wheelResult(SaveData(), now)];

  Reward? spinWheel(SaveData s, DateTime now) {
    if (!wheelAvailable(s, now)) return null;
    final r = wheelSlices[wheelResult(s, now)];
    r.applyTo(s);
    s.lastWheelDay = DateKeys.day(now);
    s.addStat(Stat.wheelSpins);
    return r;
  }

  // ---- Surprise --------------------------------------------------------------
  bool surpriseAvailable(SaveData s, DateTime now) =>
      s.lastSurpriseDay != DateKeys.day(now) && s.dailyProgress[Stat.levelsWon] != null &&
      (s.dailyProgress[Stat.levelsWon] ?? 0) >= 3;

  Reward? claimSurprise(SaveData s, DateTime now) {
    if (!surpriseAvailable(s, now)) return null;
    final r = SeededRandom(mixSeed([stableHash(gameId), stableHash('s${DateKeys.day(now)}')]));
    final reward = Reward(coins: 40 + r.nextInt(120), hints: r.chance(0.3) ? 1 : 0);
    reward.applyTo(s);
    s.lastSurpriseDay = DateKeys.day(now);
    return reward;
  }

  // ---- Comeback ---------------------------------------------------------------
  /// Players returning after 3+ days get a gift (doc 4.2 #8).
  Reward? comebackReward(SaveData s, DateTime now, int daysAway) {
    if (daysAway < 3 || s.comebackClaimedDay == DateKeys.day(now)) return null;
    final reward = Reward(
        coins: 100 + 20 * daysAway.clamp(3, 30), hints: 2, boosters: 1, gems: daysAway >= 14 ? 3 : 1);
    reward.applyTo(s);
    s.comebackClaimedDay = DateKeys.day(now);
    s.addStat(Stat.comebackWins);
    return reward;
  }

  // ---- Records ------------------------------------------------------------------
  /// Returns true when a new personal best is set.
  bool submitScore(SaveData s, String mode, int score, DateTime now) {
    final today = DateKeys.day(now);
    if (s.dailyRecordDay != today) {
      s.dailyRecordDay = today;
      s.dailyRecord = 0;
    }
    if (score > s.dailyRecord) s.dailyRecord = score;
    final best = s.records[mode] ?? 0;
    if (score > best) {
      s.records[mode] = score;
      if (best > 0) s.addStat(Stat.recordsBroken);
      return best > 0;
    }
    return false;
  }

  // ---- Weekly personal goal ------------------------------------------------------
  /// Goal = 120% of last week's wins, min 10, set lazily at week start.
  int weeklyGoal(SaveData s) {
    if (s.weeklyGoalTarget == 0) {
      final lastWeek = s.stat('last_week_wins');
      s.weeklyGoalTarget = (lastWeek * 1.2).ceil().clamp(10, 500);
    }
    return s.weeklyGoalTarget;
  }

  int weeklyGoalProgress(SaveData s) => s.weeklyProgress[Stat.levelsWon] ?? 0;
}
