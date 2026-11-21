/// Player level 1..500 with tiers (doc 4.4).
class PlayerProgression {
  static const int maxLevel = 500;

  /// XP needed to go from [level] to [level]+1.
  static int xpForNext(int level) {
    if (level >= maxLevel) return 0;
    return 100 + (level - 1) * 25 + ((level - 1) ~/ 50) * 250;
  }

  /// Total XP required to reach [level] from level 1.
  static int totalXpFor(int level) {
    var sum = 0;
    for (var l = 1; l < level && l < maxLevel; l++) {
      sum += xpForNext(l);
    }
    return sum;
  }

  /// Returns the level reached with [totalXp].
  static int levelForXp(int totalXp) {
    var level = 1;
    var remaining = totalXp;
    while (level < maxLevel) {
      final need = xpForNext(level);
      if (remaining < need) break;
      remaining -= need;
      level++;
    }
    return level;
  }

  /// 0..1 progress within the current level.
  static double progressInLevel(int totalXp) {
    final level = levelForXp(totalXp);
    if (level >= maxLevel) return 1;
    final base = totalXpFor(level);
    return ((totalXp - base) / xpForNext(level)).clamp(0.0, 1.0);
  }

  static PlayerTier tierFor(int level) {
    if (level <= 10) return PlayerTier.beginner;
    if (level <= 50) return PlayerTier.developing;
    if (level <= 100) return PlayerTier.expert;
    if (level <= 250) return PlayerTier.master;
    return PlayerTier.legend;
  }

  /// XP granted for finishing a level.
  static int xpForWin({required int difficulty, required int stars}) =>
      20 + difficulty * 6 + stars * 10;
}

enum PlayerTier { beginner, developing, expert, master, legend }
