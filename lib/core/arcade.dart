import 'game_rules.dart';
import 'level_plan.dart';
import 'rng.dart';

/// Shared real-time ("arcade") framework.
///
/// Every arcade game is a pure-Dart, fixed-timestep simulation
/// ([ArcadeSim]) driven by an [ArcadeInput] per tick (60 ticks/second).
/// Because the simulation is deterministic for a given seed and input
/// stream, the shell can:
///  * validate every generated level by letting a bot play it (doc 5.3),
///  * resume an interrupted round by replaying the recorded inputs
///    (doc 6.3 "uygulama kapanma testi"),
///  * run the same level on Android, iOS and Web.

/// World size used by every arcade game (portrait 10:16).
const double kWorldW = 1000;
const double kWorldH = 1600;
const int kTicksPerSecond = 60;
const double kDt = 1 / kTicksPerSecond;

/// One tick of player input in world coordinates.
class ArcadeInput {
  /// Pointer/finger is down (or space/fire key held).
  final bool down;

  /// Pointer position in world units, -1 if none.
  final double x;
  final double y;

  /// A tap started on this tick (edge).
  final bool tap;

  /// Swipe/arrow edge on this tick: -1 none, 0 up, 1 right, 2 down, 3 left.
  final int swipe;

  /// Held direction from keyboard: -1, 0, 1.
  final int dirX;
  final int dirY;

  const ArcadeInput({
    this.down = false,
    this.x = -1,
    this.y = -1,
    this.tap = false,
    this.swipe = -1,
    this.dirX = 0,
    this.dirY = 0,
  });

  static const idle = ArcadeInput();

  bool get hasPointer => x >= 0;

  List<int> encode() =>
      [down ? 1 : 0, x.round(), y.round(), tap ? 1 : 0, swipe, dirX, dirY];

  static ArcadeInput decode(List<dynamic> l) => ArcadeInput(
        down: l[0] == 1,
        x: (l[1] as num).toDouble(),
        y: (l[2] as num).toDouble(),
        tap: l[3] == 1,
        swipe: (l[4] as num).toInt(),
        dirX: (l[5] as num).toInt(),
        dirY: (l[6] as num).toInt(),
      );

  /// Quantized so that recorded inputs replay exactly.
  ArcadeInput quantized() => ArcadeInput(
        down: down,
        x: x < 0 ? -1 : x.roundToDouble(),
        y: y < 0 ? -1 : y.roundToDouble(),
        tap: tap,
        swipe: swipe,
        dirX: dirX,
        dirY: dirY,
      );

  bool sameAs(ArcadeInput o) =>
      down == o.down &&
      x == o.x &&
      y == o.y &&
      tap == o.tap &&
      swipe == o.swipe &&
      dirX == o.dirX &&
      dirY == o.dirY;
}

/// Mode-related settings shared by every arcade level.
class ArcadeMeta {
  final int seed;
  final int difficulty;
  final GameModeId mode;
  final List<String> mechanics;

  const ArcadeMeta(this.seed, this.difficulty, this.mode, this.mechanics);

  factory ArcadeMeta.of(LevelSpec s) => ArcadeMeta(s.seed, s.difficulty, s.mode, s.mechanics);

  bool get endless => mode == GameModeId.endless;
  bool get zen => mode == GameModeId.zen;
  bool get timed => mode == GameModeId.timeAttack;

  /// Goal-based (campaign, daily, weekly, challenge, practice).
  bool get goal => !endless && !zen && !timed;

  bool has(String m) => mechanics.contains(m);

  /// Seconds for time attack.
  int get timeLimit => timed ? 90 : 0;
}

/// A deterministic real-time simulation.
abstract class ArcadeSim {
  final ArcadeMeta meta;
  final SeededRandom rng;
  int ticks = 0;
  int score = 0;
  int lives;
  int revives = 0;
  bool _won = false;
  bool _dead = false;

  /// Remaining invulnerability ticks (after revive / shield booster).
  int shield = 0;

  /// Remaining slow-motion ticks (booster).
  int slow = 0;

  ArcadeSim(this.meta, {this.lives = 3}) : rng = SeededRandom(mixSeed([meta.seed, 515]));

  bool get won => _won;
  bool get dead => _dead;

  /// Round finished (won, dead with no lives, or time up).
  bool get over => _won || _dead || timeUp;

  bool get timeUp => meta.timeLimit > 0 && ticks >= meta.timeLimit * kTicksPerSecond;

  double get seconds => ticks / kTicksPerSecond;

  /// 0..1 goal progress for the HUD.
  double get progress;

  /// Short HUD text for the goal, e.g. "12/40".
  String get goalText;

  /// Game specific counters reported to stats/missions.
  Map<String, int> get stats;

  /// 1..3 when won.
  int get stars;

  /// Advances one tick. Subclasses implement [update].
  void tick(ArcadeInput input) {
    if (over) return;
    ticks++;
    if (shield > 0) shield--;
    if (slow > 0) {
      slow--;
      // Slow motion: simulate every other tick.
      if (slow.isOdd) return;
    }
    update(input);
  }

  void update(ArcadeInput input);

  void win() => _won = true;

  /// Called by a game when the player is hit. Zen never dies.
  void hit() {
    if (shield > 0 || meta.zen || over) return;
    lives--;
    if (lives <= 0) {
      _dead = true;
    } else {
      onLifeLost();
      shield = 90;
    }
  }

  /// Called when a life is lost but the round continues (reset positions).
  void onLifeLost() {}

  /// "Continue" after game over (rewarded ad or coins).
  void revive() {
    if (!_dead) return;
    _dead = false;
    lives = 1;
    revives++;
    shield = 150;
    onLifeLost();
  }

  /// Booster: shield (default) — games may override with their own power.
  bool useBooster() {
    if (over) return false;
    shield = 300;
    return true;
  }

  /// Second booster: slow motion.
  bool useSlow() {
    if (over || slow > 0) return false;
    slow = 360;
    return true;
  }
}

/// Outcome of a bot run.
class BotRun {
  final bool won;
  final int ticks;
  final int score;
  const BotRun(this.won, this.ticks, this.score);
}

BotRun runBot(ArcadeSim sim, ArcadeInput Function(ArcadeSim) bot, int maxTicks) {
  while (!sim.over && sim.ticks < maxTicks) {
    sim.tick(bot(sim));
  }
  return BotRun(sim.won, sim.ticks, sim.score);
}

/// Replays a recorded input log: [[tick, ...encodedInput], ...] where each
/// entry is the input from that tick on (until the next entry).
void replayLog(ArcadeSim sim, List<dynamic> log, int untilTick) {
  var input = ArcadeInput.idle;
  var i = 0;
  while (sim.ticks < untilTick) {
    final next = sim.ticks + 1;
    while (i < log.length && ((log[i] as List)[0] as num).toInt() <= next) {
      final e = log[i] as List;
      if ((e[1] as num).toInt() == -1) {
        // Special entry: [tick, -1, kind] 1 = shield, 2 = slow, 3 = revive.
        final kind = (e[2] as num).toInt();
        if (kind == 2) {
          sim.useSlow();
        } else if (kind == 3) {
          sim.revive();
        } else {
          sim.useBooster();
        }
      } else {
        input = ArcadeInput.decode(e.sublist(1));
      }
      i++;
    }
    if (sim.over) break;
    sim.tick(input);
  }
}

/// Rules base for arcade games: validation = the bot must reach the goal.
abstract class ArcadeRules<L> extends GameRules<L> {
  ArcadeSim createSim(L level);

  /// Autopilot used for validation (and for the in-game demo).
  ArcadeInput bot(ArcadeSim sim);

  ArcadeMeta metaOf(L level);

  /// Upper bound of ticks for the bot to reach the goal.
  int maxTicks(L level) => 60 * 60 * 6;

  /// Extra structural checks before simulation.
  String? check(L level) => null;

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
  Validation validate(L level, LevelSpec spec) {
    final c = check(level);
    if (c != null) return Validation.fail(c);
    final m = metaOf(level);
    final sim = createSim(level);
    if (!m.goal) {
      // Endless / zen / time attack: the bot must survive a while and score.
      final r = runBot(sim, bot, 60 * 20);
      if (m.zen) return r.score >= 0 ? Validation.ok(r.ticks) : const Validation.fail('zen');
      if (r.ticks < 60 * 8 && !sim.timeUp) return const Validation.fail('bot died too early');
      return Validation.ok(r.ticks);
    }
    final r = runBot(sim, bot, maxTicks(level));
    if (!r.won) return Validation.fail('bot could not finish (score ${r.score}, t ${r.ticks})');
    return Validation.ok(r.ticks);
  }
}

/// Small helpers.
double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

double moveToward(double v, double target, double maxStep) {
  if ((target - v).abs() <= maxStep) return target;
  return v + (target > v ? maxStep : -maxStep);
}

/// Standard stars: lose a star per life lost / revive.
int lifeStars(ArcadeSim s, int startLives) {
  if (!s.won) return 0;
  final lost = (startLives - s.lives) + s.revives * 2;
  return (3 - lost).clamp(1, 3);
}
