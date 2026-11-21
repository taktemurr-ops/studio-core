import 'level_plan.dart';
import 'missions.dart';
import 'rng.dart';
import 'stats.dart';

/// Result of a solvability / rule check of a generated level.
class Validation {
  final bool ok;
  final String reason;

  /// Optional measured metric (e.g. optimal moves) used for star limits.
  final int metric;

  const Validation.ok([this.metric = 0])
      : ok = true,
        reason = '';
  const Validation.fail(this.reason)
      : ok = false,
        metric = 0;
}

/// Contract every game implements in pure Dart (testable without Flutter).
abstract class GameRules<P> {
  String get gameId;

  /// Mechanics the planner may combine (doc 5.3).
  List<String> get optionalMechanics;

  List<GameModeId> get modes;

  List<GameStat> get gameStats;

  List<MissionTemplate> get missionTemplates;

  /// Builds a puzzle for [spec]. MUST be deterministic for spec.seed.
  P generate(LevelSpec spec);

  /// Verifies the puzzle obeys the rules and can be solved (doc 5.3).
  Validation validate(P puzzle, LevelSpec spec);

  /// Generates, validates and retries with derived seeds until valid.
  /// Deterministic: the same spec always yields the same accepted puzzle.
  GeneratedLevel<P> build(LevelSpec spec, {int maxAttempts = 40}) {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final s = attempt == 0 ? spec : spec.copyWith(seed: mixSeed([spec.seed, attempt, 4049]));
      final p = generate(s);
      final v = validate(p, s);
      if (v.ok) return GeneratedLevel(s, p, v, attempt);
    }
    // Last resort: easiest difficulty is always generatable.
    final easy = spec.copyWith(
        difficulty: 1, mechanics: const [], seed: mixSeed([spec.seed, 99991]));
    final p = generate(easy);
    final v = validate(p, easy);
    if (!v.ok) {
      throw StateError('Level generation failed for ${spec.toJson()}: ${v.reason}');
    }
    return GeneratedLevel(easy, p, v, maxAttempts);
  }
}

class GeneratedLevel<P> {
  final LevelSpec spec;
  final P puzzle;
  final Validation validation;
  final int attempts;

  GeneratedLevel(this.spec, this.puzzle, this.validation, this.attempts);
}

/// Outcome reported by a game screen when a round ends.
class RoundResult {
  final bool won;
  final int score;

  /// 0..3
  final int stars;
  final int seconds;
  final int moves;
  final int hintsUsed;
  final int undosUsed;

  /// Game specific counters, e.g. {'lines_cleared': 4}.
  final Map<String, int> gameStats;

  const RoundResult({
    required this.won,
    this.score = 0,
    this.stars = 0,
    this.seconds = 0,
    this.moves = 0,
    this.hintsUsed = 0,
    this.undosUsed = 0,
    this.gameStats = const {},
  });
}
