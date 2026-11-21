import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../core/arcade.dart';
import '../core/game_rules.dart';
import 'game_api.dart';
import 'play_kit.dart';
import 'services/audio.dart';

/// Colors handed to an arcade painter.
class ArcadePalette {
  final List<Color> pieces;
  final List<Color> background;
  final bool colorBlind;
  final bool reducedMotion;
  const ArcadePalette(this.pieces, this.background, this.colorBlind, this.reducedMotion);

  Color piece(int i) => pieces[i % pieces.length];
}

typedef ArcadePainterFn = void Function(Canvas canvas, ArcadeSim sim, ArcadePalette p, double t);

/// Generic real-time game screen used by every arcade game:
/// fixed 60 Hz simulation, touch (tap / drag / swipe) + keyboard (arrows,
/// WASD, space), pause on app background, continue after game over,
/// two boosters, and resume by input replay.
class ArcadeStage extends StatefulWidget {
  final PlayContext ctx;
  final ArcadeSim Function() create;
  final ArcadePainterFn paint;

  /// Sound hooks: called after each tick with the sim, returns an effect.
  final Sfx? Function(ArcadeSim sim)? sound;
  final IconData boosterIcon;
  final String Function(String lang) boosterLabel;

  /// Text shown on the start overlay.
  final List<String> howTo; // tr, en, de, es, fr

  const ArcadeStage({
    super.key,
    required this.ctx,
    required this.create,
    required this.paint,
    required this.howTo,
    this.sound,
    this.boosterIcon = Icons.shield,
    this.boosterLabel = _defaultBooster,
  });

  static String _defaultBooster(String lang) => lang == 'tr' ? 'Kalkan' : 'Shield';

  @override
  State<ArcadeStage> createState() => _ArcadeStageState();
}

class _ArcadeStageState extends State<ArcadeStage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late ArcadeSim sim;
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _acc = 0;
  bool _started = false;
  bool _paused = false;
  bool _ended = false;
  bool _asking = false;
  final FocusNode _focus = FocusNode();
  final List<List<int>> _log = [];
  ArcadeInput _lastLogged = ArcadeInput.idle;
  int _boosters = 0;
  int _lastSave = 0;

  // live input state
  bool _down = false;
  double _px = -1, _py = -1;
  bool _tapEdge = false;
  int _swipeEdge = -1;
  int _kx = 0, _ky = 0;
  bool _space = false;
  Offset? _panStart;

  // world <-> screen
  double _scale = 1;
  Offset _origin = Offset.zero;

  PlayContext get ctx => widget.ctx;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sim = widget.create();
    final log = ctx.resume['log'];
    final at = (ctx.resume['ticks'] as num?)?.toInt() ?? 0;
    if (log is List && at > 0) {
      replayLog(sim, log, at);
      for (final e in log) {
        _log.add((e as List).map((v) => (v as num).toInt()).toList());
      }
      for (final e in _log.reversed) {
        if (e[1] != -1) {
          _lastLogged = ArcadeInput.decode(e.sublist(1));
          break;
        }
      }
      _boosters = (ctx.resume['boosters'] as num?)?.toInt() ?? 0;
    }
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _started && !_ended) {
      setState(() => _paused = true);
      _persist();
    }
  }

  ArcadeInput _currentInput() {
    final i = ArcadeInput(
      down: _down || _space,
      x: _px,
      y: _py,
      tap: _tapEdge,
      swipe: _swipeEdge,
      dirX: _kx,
      dirY: _ky,
    ).quantized();
    _tapEdge = false;
    _swipeEdge = -1;
    return i;
  }

  void _onFrame(Duration now) {
    final dt = _last == Duration.zero ? 0.0 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (!_started || _paused || _ended || _asking) return;
    _acc += math.min(dt, 0.1);
    var steps = 0;
    while (_acc >= kDt && steps < 6) {
      _acc -= kDt;
      steps++;
      final input = _currentInput();
      if (!input.sameAs(_lastLogged)) {
        _log.add([sim.ticks + 1, ...input.encode()]);
        _lastLogged = input;
      }
      final scoreBefore = sim.score;
      final livesBefore = sim.lives;
      sim.tick(input);
      final fx = widget.sound?.call(sim);
      if (fx != null) {
        ctx.sfx(fx);
      } else if (sim.lives < livesBefore) {
        ctx.sfx(Sfx.lose);
      } else if (sim.score > scoreBefore + 40) {
        ctx.sfx(Sfx.combo);
      }
      if (sim.over) break;
    }
    if (sim.ticks - _lastSave > 120) _persist();
    if (sim.over) _onOver();
    setState(() {});
  }

  void _persist() {
    _lastSave = sim.ticks;
    if (_ended) return;
    ctx.saveResume({'log': _log, 'ticks': sim.ticks, 'boosters': _boosters});
  }

  Future<void> _onOver() async {
    if (_ended || _asking) return;
    if (sim.won || !sim.meta.goal) {
      _finish(sim.won || (!sim.meta.goal && sim.score > 0));
      return;
    }
    _asking = true;
    final again = await ctx.requestContinue();
    _asking = false;
    if (!mounted) return;
    if (again) {
      setState(sim.revive);
      _log.add([sim.ticks + 1, -1, 3, 0, 0, -1, 0, 0]);
      _persist();
    } else {
      _finish(false);
    }
  }

  void _finish(bool won) {
    if (_ended) return;
    _ended = true;
    ctx.sfx(won ? Sfx.win : Sfx.lose);
    var stars = sim.stars;
    if (!sim.meta.goal) {
      stars = sim.score >= 5000 ? 3 : sim.score >= 1500 ? 2 : sim.score > 0 ? 1 : 0;
    }
    ctx.finish(RoundResult(
      won: won,
      score: sim.score,
      stars: won ? stars.clamp(1, 3) : 0,
      seconds: sim.seconds.round(),
      moves: _log.length,
      hintsUsed: _boosters,
      undosUsed: sim.revives,
      gameStats: sim.stats,
    ));
  }

  Future<void> _booster(bool slowMo) async {
    if (_ended || !_started) return;
    final wasPaused = _paused;
    setState(() => _paused = true);
    final ok = await ctx.requestBooster();
    if (!mounted) return;
    if (ok && (slowMo ? sim.useSlow() : sim.useBooster())) {
      _boosters++;
      ctx.sfx(Sfx.unlock);
      // Boosters change the deterministic state: log as a special entry.
      _log.add([sim.ticks + 1, -1, slowMo ? 2 : 1, 0, 0, -1, 0, 0]);
    }
    setState(() => _paused = wasPaused);
  }

  Offset _toWorld(Offset p) => (p - _origin) / _scale;

  void _pointer(Offset local) {
    final w = _toWorld(local);
    _px = clampD(w.dx, 0, kWorldW);
    _py = clampD(w.dy, 0, kWorldH);
  }

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    final k = e.logicalKey;
    final down = e is KeyDownEvent || e is KeyRepeatEvent;
    final edge = e is KeyDownEvent;
    int? sw;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.keyA) {
      _kx = down ? -1 : (_kx == -1 ? 0 : _kx);
      sw = 3;
    } else if (k == LogicalKeyboardKey.arrowRight || k == LogicalKeyboardKey.keyD) {
      _kx = down ? 1 : (_kx == 1 ? 0 : _kx);
      sw = 1;
    } else if (k == LogicalKeyboardKey.arrowUp || k == LogicalKeyboardKey.keyW) {
      _ky = down ? -1 : (_ky == -1 ? 0 : _ky);
      sw = 0;
    } else if (k == LogicalKeyboardKey.arrowDown || k == LogicalKeyboardKey.keyS) {
      _ky = down ? 1 : (_ky == 1 ? 0 : _ky);
      sw = 2;
    } else if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter) {
      _space = down;
      if (edge) {
        _tapEdge = true;
        if (!_started) setState(() => _started = true);
      }
      return KeyEventResult.handled;
    } else if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.keyP) {
      if (edge) setState(() => _paused = !_paused);
      return KeyEventResult.handled;
    } else {
      return KeyEventResult.ignored;
    }
    if (edge) {
      _swipeEdge = sw;
      if (!_started) setState(() => _started = true);
    }
    return KeyEventResult.handled;
  }

  String _t(List<String> l) {
    const order = ['tr', 'en', 'de', 'es', 'fr'];
    final i = order.indexOf(ctx.lang);
    return i >= 0 && i < l.length ? l[i] : l[1];
  }

  @override
  Widget build(BuildContext context) {
    final palette = ArcadePalette(ctx.pieceColors, ctx.background, ctx.colorBlind, ctx.reducedMotion);
    final lives = sim.meta.zen ? '∞' : '${sim.lives}';
    final time = sim.meta.timeLimit > 0
        ? '${math.max(0, sim.meta.timeLimit - sim.seconds.floor())}s'
        : '${sim.seconds.floor()}s';
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: PlayHud(items: [
                  (Icons.star, '${sim.score}'),
                  (Icons.flag, sim.goalText),
                  (Icons.favorite, lives),
                  (Icons.timer, time),
                ]),
              ),
              IconButton(
                tooltip: _paused ? 'Play' : 'Pause',
                onPressed: _started && !_ended ? () => setState(() => _paused = !_paused) : null,
                icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
              ),
            ],
          ),
          if (sim.meta.goal)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: LinearProgressIndicator(value: sim.progress.clamp(0.0, 1.0)),
            ),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              _scale = math.min(box.maxWidth / kWorldW, box.maxHeight / kWorldH);
              _origin = Offset((box.maxWidth - kWorldW * _scale) / 2, (box.maxHeight - kWorldH * _scale) / 2);
              return Listener(
                onPointerDown: (e) {
                  _focus.requestFocus();
                  _pointer(e.localPosition);
                  _down = true;
                  _tapEdge = true;
                  _panStart = e.localPosition;
                  if (!_started) setState(() => _started = true);
                },
                onPointerMove: (e) => _pointer(e.localPosition),
                onPointerUp: (e) {
                  _down = false;
                  final s = _panStart;
                  if (s != null) {
                    final d = e.localPosition - s;
                    if (d.distance > 28) {
                      _swipeEdge = d.dx.abs() > d.dy.abs() ? (d.dx > 0 ? 1 : 3) : (d.dy > 0 ? 2 : 0);
                    }
                  }
                  _panStart = null;
                },
                onPointerCancel: (_) => _down = false,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StagePainter(sim, widget.paint, palette, _scale, _origin, sim.ticks / 60.0),
                      ),
                    ),
                    if (!_started || _paused)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _started = true;
                            _paused = false;
                          }),
                          child: Container(
                            color: Colors.black45,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(16),
                            // Scrolls instead of overflowing on short phones (long how-to texts).
                            child: SingleChildScrollView(
                              child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_paused ? Icons.pause_circle : Icons.touch_app,
                                    size: 64, color: Colors.white),
                                const SizedBox(height: 12),
                                Text(
                                  _paused
                                      ? (ctx.lang == 'tr' ? 'Duraklatıldı – devam için dokun' : 'Paused – tap to resume')
                                      : _t(widget.howTo),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white, fontSize: 18),
                                ),
                              ],
                            ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
          BoosterBar(buttons: [
            BoosterButton(widget.boosterIcon, widget.boosterLabel(ctx.lang), () => _booster(false)),
            BoosterButton(Icons.slow_motion_video, ctx.lang == 'tr' ? 'Yavaş çekim' : 'Slow motion',
                () => _booster(true)),
            if (!sim.meta.goal)
              BoosterButton(Icons.flag_circle, ctx.lang == 'tr' ? 'Bitir' : 'Finish',
                  _ended ? null : () => _finish(sim.score > 0)),
          ]),
        ],
      ),
    );
  }
}

class _StagePainter extends CustomPainter {
  final ArcadeSim sim;
  final ArcadePainterFn fn;
  final ArcadePalette palette;
  final double scale;
  final Offset origin;
  final double t;
  _StagePainter(this.sim, this.fn, this.palette, this.scale, this.origin, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    canvas.clipRect(const Rect.fromLTWH(0, 0, kWorldW, kWorldH));
    final bg = palette.background;
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, kWorldW, kWorldH),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: bg.length >= 2 ? bg.take(2).toList() : [bg.first, bg.first],
        ).createShader(const Rect.fromLTWH(0, 0, kWorldW, kWorldH)),
    );
    fn(canvas, sim, palette, t);
    if (sim.shield > 0 && !sim.meta.zen) {
      paintText(canvas, '🛡', const Offset(kWorldW - 60, 60), 56, Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
