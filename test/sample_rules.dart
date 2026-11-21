import 'package:studio_core/core/game_rules.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/missions.dart';
import 'package:studio_core/core/stats.dart';
import 'block_engine.dart';

class BlockRules extends GameRules<BlockLevel> {
  @override
  String get gameId => 'game-001-block-puzzle-master';

  @override
  List<String> get optionalMechanics => const ['obstacle', 'gem', 'ice', 'bomb', 'timer', 'big_board'];

  @override
  List<GameModeId> get modes => const [
        GameModeId.campaign,
        GameModeId.endless,
        GameModeId.timeAttack,
        GameModeId.zen,
        GameModeId.daily,
        GameModeId.weekly,
        GameModeId.challenge,
      ];

  @override
  List<GameStat> get gameStats => const [
        GameStat('lines_cleared', 'Temizlenen satır/sütun', 'Lines cleared', scale: 10),
        GameStat('combos', 'Kombo', 'Combos', scale: 5),
        GameStat('gems_collected', 'Toplanan elmas', 'Gems collected', scale: 3),
        GameStat('blocks_placed', 'Yerleştirilen blok', 'Blocks placed', scale: 50),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('lines', 'lines_cleared', [10, 25, 50]),
        MissionTemplate('combos', 'combos', [3, 8, 15]),
        MissionTemplate('blocks', 'blocks_placed', [40, 80, 150]),
      ];

  @override
  BlockLevel generate(LevelSpec spec) => generateBlockLevel(spec);

  @override
  Validation validate(BlockLevel level, LevelSpec spec) {
    // Structural rules.
    if (level.cells.length != level.size * level.size) {
      return const Validation.fail('bad board size');
    }
    for (var y = 0; y < level.size; y++) {
      final row = List.generate(level.size, (x) => level.cells[y * level.size + x]);
      if (row.every(Cell.filled)) return const Validation.fail('pre-filled full row');
    }
    for (var x = 0; x < level.size; x++) {
      final col = List.generate(level.size, (y) => level.cells[y * level.size + x]);
      if (col.every(Cell.filled)) return const Validation.fail('pre-filled full column');
    }
    for (final g in level.gems) {
      if (!Cell.filled(level.cells[g])) return const Validation.fail('gem on empty cell');
    }
    if (level.goal.target == 0) {
      // Endless / zen / time attack: the opening tray must be playable.
      final game = BlockGame(level);
      return game.hasMove ? const Validation.ok() : const Validation.fail('dead start');
    }
    // Solvability: the AI must reach the goal with the same piece stream.
    final moves = simulateBlockLevel(level);
    if (moves < 0) return const Validation.fail('AI could not solve');
    return Validation.ok(moves);
  }

  /// Applies the measured AI result: move limit with generous slack.
  BlockLevel finalize(GeneratedLevel<BlockLevel> g) {
    final l = g.puzzle;
    if (l.goal.target == 0) return l;
    final ai = g.validation.metric;
    final slack = 2.4 - l.difficulty * 0.1; // 2.3x (easy) .. 1.4x (hard)
    final limit = l.difficulty >= 4 ? (ai * slack).ceil() + 4 : 0;
    return l.withAi(ai, limit);
  }

  /// Stars from moves (goal levels) or score (endless).
  static int stars(BlockGame g) {
    if (!g.won) return 0;
    final ai = g.level.aiMoves;
    if (ai <= 0) return 3;
    if (g.moves <= (ai * 1.25).ceil()) return 3;
    if (g.moves <= (ai * 1.7).ceil()) return 2;
    return 1;
  }

  static int endlessStars(int score) => score >= 3000 ? 3 : score >= 1200 ? 2 : score >= 300 ? 1 : 0;
}

GameRules createRules() => BlockRules();
