import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';

/// Polyomino piece. Cells are (x, y) offsets with min x = min y = 0.
class BlockPiece {
  final int shape;
  final List<List<int>> cells;
  final int color;

  const BlockPiece(this.shape, this.cells, this.color);

  int get width => cells.map((c) => c[0]).reduce((a, b) => a > b ? a : b) + 1;
  int get height => cells.map((c) => c[1]).reduce((a, b) => a > b ? a : b) + 1;
  int get size => cells.length;

  BlockPiece rotated() {
    final r = cells.map((c) => [height - 1 - c[1], c[0]]).toList();
    return BlockPiece(shape, r, color);
  }

  Map<String, Object> toJson() => {'s': shape, 'c': color, 'r': cells.expand((e) => e).toList()};

  static BlockPiece fromJson(Map<String, Object?> j) {
    final flat = (j['r'] as List).cast<num>().map((e) => e.toInt()).toList();
    final cells = <List<int>>[];
    for (var i = 0; i + 1 < flat.length; i += 2) {
      cells.add([flat[i], flat[i + 1]]);
    }
    return BlockPiece((j['s'] as num).toInt(), cells, (j['c'] as num).toInt());
  }
}

/// All shapes used by the game (21 classic polyomino shapes).
const List<List<List<int>>> kShapes = [
  [[0, 0]], // 0 dot
  [[0, 0], [1, 0]], // 1 domino h
  [[0, 0], [0, 1]], // 2 domino v
  [[0, 0], [1, 0], [2, 0]], // 3 line3 h
  [[0, 0], [0, 1], [0, 2]], // 4 line3 v
  [[0, 0], [1, 0], [0, 1]], // 5 corner
  [[0, 0], [1, 0], [1, 1]], // 6 corner
  [[1, 0], [0, 1], [1, 1]], // 7 corner
  [[0, 0], [0, 1], [1, 1]], // 8 corner
  [[0, 0], [1, 0], [0, 1], [1, 1]], // 9 square
  [[0, 0], [1, 0], [2, 0], [3, 0]], // 10 line4 h
  [[0, 0], [0, 1], [0, 2], [0, 3]], // 11 line4 v
  [[0, 0], [1, 0], [2, 0], [1, 1]], // 12 T
  [[0, 0], [0, 1], [0, 2], [1, 2]], // 13 L
  [[1, 0], [1, 1], [1, 2], [0, 2]], // 14 J
  [[1, 0], [2, 0], [0, 1], [1, 1]], // 15 S
  [[0, 0], [1, 0], [1, 1], [2, 1]], // 16 Z
  [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]], // 17 line5 h
  [[0, 0], [0, 1], [0, 2], [0, 3], [0, 4]], // 18 line5 v
  [[0, 0], [1, 0], [2, 0], [0, 1], [0, 2]], // 19 big L
  [[0, 0], [1, 0], [2, 0], [0, 1], [1, 1], [2, 1], [0, 2], [1, 2], [2, 2]], // 20 3x3
];

/// Cell codes.
class Cell {
  static const empty = 0;
  // 1..8 = colored blocks
  static const stone = 20;
  static const ice2 = 30;
  static const ice1 = 31;
  static bool filled(int v) => v != empty;
}

enum GoalType { score, lines, gems, survive }

class BlockGoal {
  final GoalType type;
  final int target;
  const BlockGoal(this.type, this.target);
}

/// Static description of a generated level.
class BlockLevel {
  final int size;
  final List<int> cells;
  final Set<int> gems;
  final Map<int, int> bombs;
  final BlockGoal goal;
  final int moveLimit; // 0 = unlimited
  final int timeLimit; // seconds, 0 = none
  final int seed;
  final int difficulty;
  final bool zen;
  final int aiMoves;

  const BlockLevel({
    required this.size,
    required this.cells,
    required this.gems,
    required this.bombs,
    required this.goal,
    required this.moveLimit,
    required this.timeLimit,
    required this.seed,
    required this.difficulty,
    required this.zen,
    required this.aiMoves,
  });

  BlockLevel withAi(int moves, int limit) => BlockLevel(
        size: size,
        cells: cells,
        gems: gems,
        bombs: bombs,
        goal: goal,
        moveLimit: limit,
        timeLimit: timeLimit,
        seed: seed,
        difficulty: difficulty,
        zen: zen,
        aiMoves: moves,
      );
}

class PlaceResult {
  final int lines;
  final int points;
  final int gemsCollected;
  final bool exploded;
  const PlaceResult(this.lines, this.points, this.gemsCollected, this.exploded);
}

class Move {
  final int tray;
  final int x;
  final int y;
  const Move(this.tray, this.x, this.y);
}

/// Complete, deterministic game state. Pure Dart, no Flutter.
class BlockGame {
  final BlockLevel level;
  final int size;
  late List<int> cells;
  late Set<int> gems;
  late Map<int, int> bombs;
  late List<BlockPiece?> tray;
  late SeededRandom _rng;
  int _draws = 0;
  int score = 0;
  int combo = 0;
  int bestCombo = 0;
  int lines = 0;
  int gemsCollected = 0;
  int moves = 0;
  bool exploded = false;
  final List<String> _undo = [];

  /// Disabled on AI clones for speed.
  bool recordUndo = true;

  BlockGame(this.level) : size = level.size {
    cells = List.of(level.cells);
    gems = Set.of(level.gems);
    bombs = Map.of(level.bombs);
    _rng = SeededRandom(level.seed);
    tray = [null, null, null];
    _refill();
  }

  int idx(int x, int y) => y * size + x;

  /// Piece distribution depends on difficulty: harder = bigger pieces.
  BlockPiece _draw() {
    _draws++;
    final d = level.difficulty;
    final weights = List<int>.generate(kShapes.length, (i) {
      final n = kShapes[i].length;
      if (n <= 2) return (14 - d).clamp(3, 14);
      if (n == 3) return 10;
      if (n == 4) return 6 + d ~/ 2;
      if (n == 5) return 2 + d ~/ 2;
      return 1 + d ~/ 3; // 3x3
    });
    final s = _rng.weighted(weights);
    return BlockPiece(s, kShapes[s], 1 + _rng.nextInt(8));
  }

  void _refill() {
    for (var i = 0; i < 3; i++) {
      tray[i] = _draw();
    }
  }

  bool canPlace(BlockPiece p, int x, int y) {
    for (final c in p.cells) {
      final cx = x + c[0], cy = y + c[1];
      if (cx < 0 || cy < 0 || cx >= size || cy >= size) return false;
      if (Cell.filled(cells[idx(cx, cy)])) return false;
    }
    return true;
  }

  bool fitsAnywhere(BlockPiece p) {
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        if (canPlace(p, x, y)) return true;
      }
    }
    return false;
  }

  bool get hasMove => tray.any((p) => p != null && fitsAnywhere(p));

  int get goalProgress {
    switch (level.goal.type) {
      case GoalType.score:
        return score;
      case GoalType.lines:
        return lines;
      case GoalType.gems:
        return gemsCollected;
      case GoalType.survive:
        return moves;
    }
  }

  bool get won => level.goal.target > 0 && goalProgress >= level.goal.target && !exploded;

  int bonusMoves = 0;

  int get movesLeft => level.moveLimit == 0 ? -1 : level.moveLimit + bonusMoves - moves;

  bool get outOfMoves => level.moveLimit > 0 && moves >= level.moveLimit + bonusMoves;

  /// "Continue" after a fail: +5 moves, defuse bombs a bit, clear the
  /// centre 4x4 and give a fresh tray.
  void rescue() {
    bonusMoves += 5;
    exploded = false;
    for (final k in bombs.keys.toList()) {
      bombs[k] = bombs[k]! + 10;
    }
    final start = size ~/ 2 - 2;
    for (var y = start; y < start + 4; y++) {
      for (var x = start; x < start + 4; x++) {
        final i = idx(x, y);
        if (!gems.contains(i)) cells[i] = Cell.empty;
        bombs.remove(i);
      }
    }
    _refill();
  }

  bool get lost => exploded || (!won && (outOfMoves || (!hasMove && !level.zen)));

  /// Rows/cols that would clear if piece were placed (for preview glow).
  List<int> wouldClear(BlockPiece p, int x, int y) {
    final tmp = List.of(cells);
    for (final c in p.cells) {
      tmp[idx(x + c[0], y + c[1])] = 1;
    }
    final out = <int>[];
    for (var r = 0; r < size; r++) {
      if (List.generate(size, (i) => tmp[idx(i, r)]).every(Cell.filled)) out.add(r);
    }
    for (var col = 0; col < size; col++) {
      if (List.generate(size, (i) => tmp[idx(col, i)]).every(Cell.filled)) out.add(size + col);
    }
    return out;
  }

  PlaceResult place(int trayIndex, int x, int y) {
    final p = tray[trayIndex];
    if (p == null || !canPlace(p, x, y)) {
      throw StateError('illegal placement');
    }
    if (recordUndo) {
      _undo.add(_snapshot());
      if (_undo.length > 20) _undo.removeAt(0);
    }
    for (final c in p.cells) {
      cells[idx(x + c[0], y + c[1])] = p.color;
    }
    moves++;
    tray[trayIndex] = null;
    var points = p.size;

    // Find full lines.
    final fullRows = <int>[];
    final fullCols = <int>[];
    for (var r = 0; r < size; r++) {
      var ok = true;
      for (var c = 0; c < size; c++) {
        if (!Cell.filled(cells[idx(c, r)])) {
          ok = false;
          break;
        }
      }
      if (ok) fullRows.add(r);
    }
    for (var c = 0; c < size; c++) {
      var ok = true;
      for (var r = 0; r < size; r++) {
        if (!Cell.filled(cells[idx(c, r)])) {
          ok = false;
          break;
        }
      }
      if (ok) fullCols.add(c);
    }
    final toClear = <int>{};
    for (final r in fullRows) {
      for (var c = 0; c < size; c++) {
        toClear.add(idx(c, r));
      }
    }
    for (final c in fullCols) {
      for (var r = 0; r < size; r++) {
        toClear.add(idx(c, r));
      }
    }
    var gemsNow = 0;
    for (final i in toClear) {
      if (cells[i] == Cell.ice2) {
        cells[i] = Cell.ice1; // ice needs a second clear
        continue;
      }
      cells[i] = Cell.empty;
      if (gems.remove(i)) gemsNow++;
      bombs.remove(i);
    }
    final n = fullRows.length + fullCols.length;
    if (n > 0) {
      combo++;
      if (combo > bestCombo) bestCombo = combo;
      points += 10 * n * n + (combo - 1) * 10 * n;
      if (cells.every((v) => v == Cell.empty)) points += 300; // perfect clear
    } else {
      combo = 0;
    }
    lines += n;
    gemsCollected += gemsNow;
    score += points;

    // Bomb countdown.
    var boom = false;
    for (final k in bombs.keys.toList()) {
      bombs[k] = bombs[k]! - 1;
      if (bombs[k]! <= 0) boom = true;
    }
    if (boom) exploded = true;

    if (tray.every((t) => t == null)) _refill();
    if (level.zen && !hasMove && !won) {
      // Zen: never a dead end - re-roll the tray.
      _refill();
      if (!hasMove) _clearRandomRow();
    }
    return PlaceResult(n, points, gemsNow, boom);
  }

  void _clearRandomRow() {
    final r = _rng.nextInt(size);
    for (var c = 0; c < size; c++) {
      cells[idx(c, r)] = Cell.empty;
    }
  }

  // ---- Boosters --------------------------------------------------------
  bool get canUndo => _undo.isNotEmpty;

  void undo() {
    if (_undo.isEmpty) return;
    _restore(_undo.removeLast());
  }

  /// Hammer: removes one filled cell (not a bomb timer reset).
  bool hammer(int x, int y) {
    final i = idx(x, y);
    if (!Cell.filled(cells[i])) return false;
    _undo.add(_snapshot());
    cells[i] = Cell.empty;
    gems.remove(i);
    bombs.remove(i);
    return true;
  }

  /// Replace all tray pieces.
  void refreshTray() {
    _undo.add(_snapshot());
    _refill();
  }

  void rotate(int trayIndex) {
    final p = tray[trayIndex];
    if (p != null) tray[trayIndex] = p.rotated();
  }

  // ---- AI / hint ---------------------------------------------------------
  double _evaluate(BlockGame g, PlaceResult r) {
    final n = g.size;
    var s = r.lines * 120.0 + r.gemsCollected * 150.0 + r.points * 0.3;
    if (r.exploded) s -= 100000;
    bool f(int x, int y) => Cell.filled(g.cells[g.idx(x, y)]);
    var transitions = 0, holes = 0;
    for (var y = 0; y < n; y++) {
      var rowFill = 0;
      for (var x = 0; x < n; x++) {
        if (f(x, y)) rowFill++;
        if (x > 0 && f(x, y) != f(x - 1, y)) transitions++;
        if (y > 0 && f(x, y) != f(x, y - 1)) transitions++;
        if (!f(x, y)) {
          var blocked = 0;
          if (x == 0 || f(x - 1, y)) blocked++;
          if (x == n - 1 || f(x + 1, y)) blocked++;
          if (y == 0 || f(x, y - 1)) blocked++;
          if (y == n - 1 || f(x, y + 1)) blocked++;
          if (blocked == 4) holes++;
        }
      }
      s += rowFill * rowFill * 0.35;
    }
    for (var x = 0; x < n; x++) {
      var colFill = 0;
      for (var y = 0; y < n; y++) {
        if (f(x, y)) colFill++;
      }
      s += colFill * colFill * 0.35;
    }
    s -= transitions * 2.5 + holes * 35;
    // Keep room for the big pieces (3x3 square and 5-long lines).
    var room3 = false, roomH5 = false, roomV5 = false;
    for (var y = 0; y < n && !(room3 && roomH5 && roomV5); y++) {
      for (var x = 0; x < n; x++) {
        if (!room3 && x + 3 <= n && y + 3 <= n) {
          var ok = true;
          for (var dy = 0; dy < 3 && ok; dy++) {
            for (var dx = 0; dx < 3; dx++) {
              if (f(x + dx, y + dy)) {
                ok = false;
                break;
              }
            }
          }
          room3 = ok;
        }
        if (!roomH5 && x + 5 <= n) {
          roomH5 = List.generate(5, (k) => !f(x + k, y)).every((e) => e);
        }
        if (!roomV5 && y + 5 <= n) {
          roomV5 = List.generate(5, (k) => !f(x, y + k)).every((e) => e);
        }
      }
    }
    if (room3) s += 60;
    if (roomH5) s += 25;
    if (roomV5) s += 25;
    for (final e in g.bombs.entries) {
      final bx = e.key % n, by = e.key ~/ n;
      var rowFill = 0, colFill = 0;
      for (var k = 0; k < n; k++) {
        if (f(k, by)) rowFill++;
        if (f(bx, k)) colFill++;
      }
      final urgency = 40.0 / e.value.clamp(1, 40);
      s -= 60 * urgency;
      s += (rowFill > colFill ? rowFill : colFill) * 6 * urgency;
    }
    return s;
  }

  Move? bestMove() {
    Move? best;
    var bestScore = double.negativeInfinity;
    final seen = <String>{};
    for (var t = 0; t < 3; t++) {
      final p = tray[t];
      if (p == null) continue;
      final key = '${p.shape}';
      if (seen.contains(key)) continue;
      seen.add(key);
      for (var y = 0; y < size; y++) {
        for (var x = 0; x < size; x++) {
          if (!canPlace(p, x, y)) continue;
          final g = clone();
          final r = g.place(t, x, y);
          final s = _evaluate(g, r);
          if (s > bestScore) {
            bestScore = s;
            best = Move(t, x, y);
          }
        }
      }
    }
    return best;
  }

  /// Fast deep copy (used by the AI and hints).
  BlockGame clone() {
    final g = BlockGame._empty(level);
    g.cells = List.of(cells);
    g.gems = Set.of(gems);
    g.bombs = Map.of(bombs);
    g.tray = List.of(tray);
    g._rng = _rng.copy();
    g._draws = _draws;
    g.score = score;
    g.combo = combo;
    g.bestCombo = bestCombo;
    g.lines = lines;
    g.gemsCollected = gemsCollected;
    g.moves = moves;
    g.exploded = exploded;
    g.bonusMoves = bonusMoves;
    g.recordUndo = false;
    return g;
  }

  BlockGame._empty(this.level) : size = level.size {
    cells = List.of(level.cells);
    gems = {};
    bombs = {};
    tray = [null, null, null];
    _rng = SeededRandom(level.seed);
  }

  // ---- Persistence -----------------------------------------------------------
  String _snapshot() => [
        cells.join(','),
        gems.join(','),
        bombs.entries.map((e) => '${e.key}:${e.value}').join(','),
        tray.map((p) => p == null ? '-' : '${p.shape}.${p.color}.${p.cells.expand((e) => e).join('_')}').join(';'),
        '$score,$combo,$bestCombo,$lines,$gemsCollected,$moves,${exploded ? 1 : 0},$_draws,$bonusMoves',
      ].join('|');

  void _restore(String snap) {
    final parts = snap.split('|');
    cells = parts[0].split(',').map(int.parse).toList();
    gems = parts[1].isEmpty ? <int>{} : parts[1].split(',').map(int.parse).toSet();
    bombs = parts[2].isEmpty
        ? <int, int>{}
        : {
            for (final e in parts[2].split(','))
              int.parse(e.split(':')[0]): int.parse(e.split(':')[1])
          };
    tray = parts[3].split(';').map<BlockPiece?>((t) {
      if (t == '-') return null;
      final f = t.split('.');
      final flat = f[2].split('_').map(int.parse).toList();
      final cs = <List<int>>[];
      for (var i = 0; i + 1 < flat.length; i += 2) {
        cs.add([flat[i], flat[i + 1]]);
      }
      return BlockPiece(int.parse(f[0]), cs, int.parse(f[1]));
    }).toList();
    final n = parts[4].split(',').map(int.parse).toList();
    score = n[0];
    combo = n[1];
    bestCombo = n[2];
    lines = n[3];
    gemsCollected = n[4];
    moves = n[5];
    exploded = n[6] == 1;
    bonusMoves = n.length > 8 ? n[8] : 0;
    // Re-sync the RNG to the same draw count (deterministic stream).
    _rng = SeededRandom(level.seed);
    final target = n[7];
    _draws = 0;
    while (_draws < target) {
      _drawSilent();
    }
  }

  void _drawSilent() => _draw();

  String serialize() => _snapshot();

  static BlockGame restore(BlockLevel level, String snap) {
    final g = BlockGame._empty(level);
    g._restore(snap);
    return g;
  }
}

/// Builds a [BlockLevel] from a [LevelSpec] (no validation here).
BlockLevel generateBlockLevel(LevelSpec spec) {
  final r = SeededRandom(spec.seed);
  final d = spec.difficulty;
  final big = spec.has('big_board');
  final size = big ? 10 : 8;
  final cells = List<int>.filled(size * size, Cell.empty);
  final gems = <int>{};
  final bombs = <int, int>{};
  final zen = spec.mode == GameModeId.zen;
  final endless =
      spec.mode == GameModeId.endless || spec.mode == GameModeId.timeAttack || zen;

  if (!endless) {
    // Obstacles: stones / ice placed without forming full lines.
    final obstacles = spec.has('obstacle') ? 2 + d : (d >= 4 ? d - 2 : 0);
    final ice = spec.has('ice') ? 2 + d ~/ 2 : 0;
    void scatter(int count, int code) {
      var guard = 0;
      while (count > 0 && guard++ < 500) {
        final i = r.nextInt(size * size);
        if (cells[i] != Cell.empty) continue;
        cells[i] = code;
        final x = i % size, y = i ~/ size;
        final rowFull = List.generate(size, (k) => cells[y * size + k]).every(Cell.filled);
        final colFull = List.generate(size, (k) => cells[k * size + x]).every(Cell.filled);
        if (rowFull || colFull) {
          cells[i] = Cell.empty;
          continue;
        }
        count--;
      }
    }

    scatter(obstacles, Cell.stone);
    scatter(ice, Cell.ice2);
    // Pre-filled colored rubble for higher difficulties.
    scatter(d >= 6 ? d * 2 : 0, 1 + r.nextInt(8));
    if (spec.has('gem')) {
      final filled = [for (var i = 0; i < cells.length; i++) if (cells[i] != Cell.empty) i];
      r.shuffle(filled);
      gems.addAll(filled.take(2 + d ~/ 2));
      if (gems.length < 2) {
        // ensure gem cells exist: add colored blocks with gems
        for (var k = 0; k < 3; k++) {
          final i = r.nextInt(size * size);
          if (cells[i] == Cell.empty) {
            cells[i] = 1 + r.nextInt(8);
            gems.add(i);
          }
        }
      }
    }
    if (spec.has('bomb')) {
      final count = 1 + d ~/ 4;
      for (var k = 0; k < count; k++) {
        final i = r.nextInt(size * size);
        if (cells[i] == Cell.empty) {
          cells[i] = 1 + r.nextInt(8);
          bombs[i] = 18 + (10 - d) * 3;
        }
      }
    }
  }

  BlockGoal goal;
  if (endless) {
    goal = const BlockGoal(GoalType.score, 0);
  } else if (gems.isNotEmpty) {
    goal = BlockGoal(GoalType.gems, gems.length);
  } else {
    goal = r.chance(0.5)
        ? BlockGoal(GoalType.lines, 3 + d * 2)
        : BlockGoal(GoalType.score, 150 + d * 120);
  }

  return BlockLevel(
    size: size,
    cells: cells,
    gems: gems,
    bombs: bombs,
    goal: goal,
    moveLimit: 0,
    timeLimit: spec.mode == GameModeId.timeAttack
        ? 120
        : (spec.has('timer') ? 150 + (10 - d) * 15 : 0),
    seed: spec.seed,
    difficulty: d,
    zen: zen,
    aiMoves: 0,
  );
}

/// Plays the level with the greedy AI. Returns moves used, or -1.
int simulateBlockLevel(BlockLevel level, {int maxMoves = 160}) {
  final g = BlockGame(level);
  while (g.moves < maxMoves) {
    if (g.won) return g.moves;
    final m = g.bestMove();
    if (m == null) return -1;
    g.place(m.tray, m.x, m.y);
    if (g.exploded) return -1;
  }
  return g.won ? g.moves : -1;
}
