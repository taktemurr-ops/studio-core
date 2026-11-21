/// Stat keys shared by every game. Games add their own [GameStat]s.
class Stat {
  static const levelsWon = 'levels_won';
  static const levelsPlayed = 'levels_played';
  static const levelsLost = 'levels_lost';
  static const starsEarned = 'stars_earned';
  static const threeStars = 'three_stars';
  static const noHintWins = 'no_hint_wins';
  static const fastWins = 'fast_wins';
  static const hintsUsed = 'hints_used';
  static const undosUsed = 'undos_used';
  static const coinsEarned = 'coins_earned';
  static const coinsSpent = 'coins_spent';
  static const dailyLevels = 'daily_levels';
  static const weeklyLevels = 'weekly_levels';
  static const challengesWon = 'challenges_won';
  static const endlessRuns = 'endless_runs';
  static const timeAttackRuns = 'time_attack_runs';
  static const zenRuns = 'zen_runs';
  static const playSeconds = 'play_seconds';
  static const loginDays = 'login_days';
  static const missionsDone = 'missions_done';
  static const wheelSpins = 'wheel_spins';
  static const itemsUnlocked = 'items_unlocked';
  static const bestScore = 'best_score';
  static const winStreak = 'win_streak';
  static const bestWinStreak = 'best_win_streak';
  static const comebackWins = 'comeback_wins';
  static const nightWins = 'night_wins';
  static const morningWins = 'morning_wins';
  static const weekendWins = 'weekend_wins';
  static const rewardedWatched = 'rewarded_watched';
  static const recordsBroken = 'records_broken';
  static const worldsCompleted = 'worlds_completed';
  static const sessions = 'sessions';
}

/// A game-specific counter (e.g. "lines_cleared" for Block Puzzle).
class GameStat {
  final String key;
  final String nameTr;
  final String nameEn;

  /// Multiplier for achievement thresholds (lines are cheap, wins are not).
  final int scale;

  const GameStat(this.key, this.nameTr, this.nameEn, {this.scale = 1});
}
