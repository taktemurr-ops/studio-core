import 'rng.dart';

/// Where a level's content comes from (hybrid model, doc section 5.1).
enum LevelSource {
  /// 1..1000: starter levels, validated in CI on every build.
  starter,

  /// 1001..10000: extended content, validated in the nightly CI job.
  extended,

  /// 10001..50000: procedural, validated on device before being served.
  procedural,

  /// > 50000: endless generation.
  endless,
}

/// Game modes. Every game declares which subset it supports.
enum GameModeId {
  campaign,
  endless,
  daily,
  weekly,
  timeAttack,
  zen,
  challenge,
  practice,
}

/// Immutable description of one level. Same inputs => same level.
class LevelSpec {
  final int levelId;
  final int seed;

  /// 1 (easiest) .. 10 (hardest), after adaptive adjustment.
  final int difficulty;
  final int world;
  final int theme;
  final List<String> mechanics;
  final int reward;
  final int version;
  final GameModeId mode;
  final LevelSource source;
  final bool milestone;

  const LevelSpec({
    required this.levelId,
    required this.seed,
    required this.difficulty,
    required this.world,
    required this.theme,
    required this.mechanics,
    required this.reward,
    required this.version,
    required this.mode,
    required this.source,
    required this.milestone,
  });

  bool has(String mechanic) => mechanics.contains(mechanic);

  LevelSpec copyWith({int? difficulty, int? seed, GameModeId? mode, List<String>? mechanics}) =>
      LevelSpec(
        levelId: levelId,
        seed: seed ?? this.seed,
        difficulty: difficulty ?? this.difficulty,
        world: world,
        theme: theme,
        mechanics: mechanics ?? this.mechanics,
        reward: reward,
        version: version,
        mode: mode ?? this.mode,
        source: source,
        milestone: milestone,
      );

  Map<String, Object?> toJson() => {
        'level_id': levelId,
        'seed': seed,
        'difficulty': difficulty,
        'world': world,
        'theme': theme,
        'mechanics': mechanics,
        'reward': reward,
        'version': version,
        'mode': mode.name,
        'source': source.name,
      };
}

/// Builds [LevelSpec]s following the production rules of section 5.3:
/// difficulty step every 10 levels, new mechanic combination every 50,
/// new theme every 100, new experience every 500, special reward every 1000.
class LevelPlanner {
  final String gameId;
  final int contentVersion;

  /// Optional mechanics the game can mix in (e.g. "timer", "obstacle").
  final List<String> optionalMechanics;
  final int themeCount;

  static const int levelsPerWorld = 100;
  static const int mainLevelCount = 50000;

  const LevelPlanner({
    required this.gameId,
    required this.optionalMechanics,
    this.contentVersion = 1,
    this.themeCount = 12,
  });

  int get worldCount => mainLevelCount ~/ levelsPerWorld;

  static LevelSource sourceFor(int level) {
    if (level <= 1000) return LevelSource.starter;
    if (level <= 10000) return LevelSource.extended;
    if (level <= mainLevelCount) return LevelSource.procedural;
    return LevelSource.endless;
  }

  int worldOf(int level) => (level - 1) ~/ levelsPerWorld + 1;

  /// Base difficulty: rises every 10 levels inside a 100-level world with a
  /// gentle global ramp, then saws back down at the start of each world so
  /// players get relief after a theme change.
  int baseDifficulty(int level) {
    final inWorld = ((level - 1) % levelsPerWorld) ~/ 10; // 0..9
    final global = ((level - 1) ~/ 500).clamp(0, 6); // +1 every 500 levels
    final d = 1 + (inWorld * 0.6).floor() + (global ~/ 2);
    // Every 10th level is a slightly harder "boss" level.
    final boss = level % 10 == 0 ? 1 : 0;
    return (d + boss).clamp(1, 10);
  }

  List<String> mechanicsFor(int level) {
    if (optionalMechanics.isEmpty || level <= 20) return const [];
    final block = (level - 1) ~/ 50; // new combo every 50 levels
    final r = SeededRandom(mixSeed([stableHash(gameId), block, 77]));
    final experience = (level - 1) ~/ 500; // new experience every 500
    final maxCount = (1 + experience ~/ 2).clamp(1, optionalMechanics.length);
    final count = level <= 200 ? r.range(0, maxCount) : r.range(1, maxCount);
    final pool = [...optionalMechanics];
    r.shuffle(pool);
    final chosen = pool.take(count).toList()..sort();
    return chosen;
  }

  int rewardFor(int level) {
    var reward = 10 + baseDifficulty(level) * 5;
    if (level % 1000 == 0) reward += 1000; // special reward every 1000
    if (level % 100 == 0) reward += 100;
    return reward;
  }

  int seedFor(int level, {GameModeId mode = GameModeId.campaign, int salt = 0}) =>
      mixSeed([stableHash(gameId), level, contentVersion, mode.index, salt]);

  LevelSpec spec(int level,
      {GameModeId mode = GameModeId.campaign, int difficultyOffset = 0, int salt = 0}) {
    if (level < 1) throw ArgumentError('level must be >= 1');
    final world = worldOf(level);
    return LevelSpec(
      levelId: level,
      seed: seedFor(level, mode: mode, salt: salt),
      difficulty: (baseDifficulty(level) + difficultyOffset).clamp(1, 10),
      world: world,
      theme: (world - 1) % themeCount,
      mechanics: mechanicsFor(level),
      reward: rewardFor(level),
      version: contentVersion,
      mode: mode,
      source: sourceFor(level),
      milestone: level % 1000 == 0,
    );
  }

  /// Daily special level: identical for every player on the same date.
  LevelSpec daily(String dateKey, {int difficulty = 5}) {
    final seed = mixSeed([stableHash(gameId), stableHash('daily:$dateKey')]);
    return LevelSpec(
      levelId: 0,
      seed: seed,
      difficulty: difficulty,
      world: 0,
      theme: seed % themeCount,
      mechanics: const [],
      reward: 150,
      version: contentVersion,
      mode: GameModeId.daily,
      source: LevelSource.procedural,
      milestone: false,
    );
  }

  LevelSpec weekly(String weekKey, {int difficulty = 7}) {
    final seed = mixSeed([stableHash(gameId), stableHash('weekly:$weekKey')]);
    return LevelSpec(
      levelId: 0,
      seed: seed,
      difficulty: difficulty,
      world: 0,
      theme: seed % themeCount,
      mechanics: optionalMechanics.take(2).toList(),
      reward: 500,
      version: contentVersion,
      mode: GameModeId.weekly,
      source: LevelSource.procedural,
      milestone: false,
    );
  }

  /// Special challenges (100+). Index 1..challengeCount.
  static const int challengeCount = 150;

  LevelSpec challenge(int index) {
    final seed = mixSeed([stableHash(gameId), stableHash('challenge'), index]);
    final r = SeededRandom(seed);
    final pool = [...optionalMechanics];
    r.shuffle(pool);
    return LevelSpec(
      levelId: index,
      seed: seed,
      difficulty: (3 + index ~/ 20).clamp(3, 10),
      world: 0,
      theme: index % themeCount,
      mechanics: pool.isEmpty
          ? const []
          : (pool.take(r.range(1, pool.length < 3 ? pool.length : 3)).toList()..sort()),
      reward: 200 + index * 5,
      version: contentVersion,
      mode: GameModeId.challenge,
      source: LevelSource.procedural,
      milestone: index % 25 == 0,
    );
  }

  /// Endless / time-attack / zen rounds use a run number as salt.
  LevelSpec run(GameModeId mode, int runIndex, {int difficulty = 4}) {
    final seed = mixSeed([stableHash(gameId), mode.index, runIndex, 991]);
    return LevelSpec(
      levelId: runIndex,
      seed: seed,
      difficulty: difficulty,
      world: 0,
      theme: runIndex % themeCount,
      mechanics: const [],
      reward: 20,
      version: contentVersion,
      mode: mode,
      source: LevelSource.endless,
      milestone: false,
    );
  }
}

/// Adapts difficulty to player performance (doc 6.1 "Zorluk sistemi").
class AdaptiveDifficulty {
  /// Recent results, newest last. true = win.
  final List<bool> recent;

  AdaptiveDifficulty(List<bool> recent) : recent = List.of(recent);

  static const int window = 8;

  void record(bool win) {
    recent.add(win);
    while (recent.length > window) {
      recent.removeAt(0);
    }
  }

  /// -2..+1 offset applied to the planned difficulty.
  int get offset {
    if (recent.length < 3) return 0;
    final last3 = recent.sublist(recent.length - 3);
    if (last3.every((w) => !w)) return -2;
    final wins = recent.where((w) => w).length;
    final rate = wins / recent.length;
    if (rate < 0.4) return -1;
    if (rate == 1.0 && recent.length >= window) return 1;
    return 0;
  }
}
