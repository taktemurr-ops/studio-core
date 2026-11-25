import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/arcade.dart';
import '../core/arcade_duel.dart';
import '../core/game_rules.dart';
import '../core/net_sync.dart';
import 'arcade_stage.dart';
import 'game_api.dart';
import 'services/audio.dart';

/// İki kişilik çevrimiçi masa oyunu ekranı (yetkili ev sahibi eşitlemesi).
///
/// * Ev sahibi simülasyonu 60 Hz yürütür, ~12 Hz anlık durum yayınlar.
/// * Misafir yalnızca parmak girdisini (~15 Hz) gönderir; ekranı gelen anlık
///   durumlardan ara kareyle (120 ms geriden) çizer.
/// * Rakibin bağlantısı koparsa yerine yapay zekâ oynar; ev sahibi koparsa
///   misafir son durumdan maçı devralır.
/// * Koltuk 1'deki oyuncu masayı ters çevrilmiş görür (kendisi hep altta).
///
/// [create] [DuelSim] uygulayan bir [ArcadeSim] döndürmelidir.
class ArcadeDuelStage extends StatefulWidget {
  final PlayContext ctx;
  final ArcadeSim Function() create;
  final ArcadePainterFn paint;

  /// Alt taraf için otomatik oyuncu (koltuk 0 koparsa).
  final ArcadeInput Function(ArcadeSim sim) bot;
  final Sfx? Function(ArcadeSim sim)? sound;

  const ArcadeDuelStage({
    super.key,
    required this.ctx,
    required this.create,
    required this.paint,
    required this.bot,
    this.sound,
  });

  @override
  State<ArcadeDuelStage> createState() => _ArcadeDuelStageState();
}

class _ArcadeDuelStageState extends State<ArcadeDuelStage> with SingleTickerProviderStateMixin {
  late final ArcadeSim sim; // yetkili kopya (ev sahibiyken yürür)
  late final ArcadeSim view; // gösterim kopyası
  late final ArcadeSim _probe; // misafirde maç sonu denetimi
  late final NetSync sync;
  late final Ticker _ticker;
  StreamSubscription<(int, String)>? _sub;
  final Stopwatch _clock = Stopwatch()..start();
  Duration _last = Duration.zero;
  double _acc = 0;
  bool _ended = false;
  bool _overSent = false;
  int _overAt = -1;

  late final int me;
  late final int side; // 0 alt, 1 üst
  MatchLink? get link => widget.ctx.match;

  /// Gerçek zamanlı kanal (çevrimiçi maçta).
  RealtimeLink? get _rt {
    final Object? l = link;
    return l is RealtimeLink ? l : null;
  }

  // yerel girdi (bu cihazın ekran koordinatları)
  bool _down = false;
  double _px = -1, _py = -1;
  bool _tapEdge = false, _upEdge = false;
  int _taps = 0, _ups = 0;
  Offset? _panStart;
  double _scale = 1;
  Offset _origin = Offset.zero;

  // uzak girdinin görülen dokunma/kaydırma sayaçları
  final Map<int, int> _seenTaps = {}, _seenUps = {};

  int get _now => _clock.elapsedMilliseconds;
  DuelSim get _duel => sim as DuelSim;

  @override
  void initState() {
    super.initState();
    sim = widget.create();
    view = widget.create();
    _probe = widget.create();
    (_probe as DuelSim).enableDuel();
    (sim as DuelSim).enableDuel();
    (view as DuelSim).enableDuel();
    final l = link;
    me = l?.mySeat ?? 0;
    side = me == 0 ? 0 : 1;
    final names = l?.names ?? const ['', ''];
    sync = NetSync(
      mySeat: me,
      seats: math.max(2, names.length),
      humans: {
        for (var i = 0; i < names.length; i++)
          if (names[i].isNotEmpty) i
      },
      send: (d) {
        final rt = _rt;
        if (rt != null) unawaited(rt.pulse(d).catchError((Object _) {}));
      },
    );
    _sub = _rt?.pulses.listen((p) => sync.receive(p.$1, p.$2, _now));
    _show(_duel.netState());
    _ticker = createTicker(_onFrame)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _sub?.cancel();
    super.dispose();
  }

  // ---- girdi ----

  ArcadeInput _localInput() {
    final i = ArcadeInput(down: _down, x: _px, y: _py, tap: _tapEdge, swipe: _upEdge ? 0 : -1);
    _tapEdge = false;
    _upEdge = false;
    return i;
  }

  ArcadeInput? _remoteInput(int seat) {
    final a = sync.axesOf(seat);
    if (a == null || a.length < 5) return null;
    final taps = a[3].round(), ups = a[4].round();
    final tap = taps > (_seenTaps[seat] ?? 0);
    final up = ups > (_seenUps[seat] ?? 0);
    _seenTaps[seat] = math.max(taps, _seenTaps[seat] ?? 0);
    _seenUps[seat] = math.max(ups, _seenUps[seat] ?? 0);
    return ArcadeInput(down: a[0] > 0.5, x: a[1], y: a[2], tap: tap, swipe: up ? 0 : -1);
  }

  /// Koltuğun bu tikteki girdisi; null: o tarafa yapay zekâ oynar.
  ArcadeInput? _inputFor(int seat, ArcadeInput local, int now) {
    if (seat == me) return local;
    if (sync.live(seat, now)) {
      final r = _remoteInput(seat);
      if (r != null) return r;
    }
    return null;
  }

  // ---- kare ----

  void _onFrame(Duration t) {
    if (!mounted) return;
    final dt = _last == Duration.zero ? 0.0 : (t - _last).inMicroseconds / 1e6;
    _last = t;
    final now = _now;
    if (sync.takeDemoted()) _acc = 0;
    final resume = sync.takeResume();
    if (resume != null && sync.isHost) _duel.applyNetState(decodeNums(resume.payload));
    if (!sync.isHost && sync.checkTakeover(now)) {
      final l = sync.latest;
      if (l != null) _duel.applyNetState(decodeNums(l.payload));
      _acc = 0;
    }
    if (_ended) return;
    if (sync.isHost) {
      _hostFrame(dt, now);
    } else {
      _guestFrame(now);
    }
    setState(() {});
  }

  void _hostFrame(double dt, int now) {
    _acc += math.min(dt, 0.1);
    var steps = 0;
    while (_acc >= kDt && steps < 6 && !sim.over) {
      _acc -= kDt;
      steps++;
      final local = _localInput();
      final i0 = _inputFor(0, local, now) ?? widget.bot(sim);
      _duel.rivalInput = _inputFor(1, local, now);
      sim.tick(i0);
      final fx = widget.sound?.call(sim);
      if (fx != null) widget.ctx.sfx(fx);
    }
    final payload = encodeNums(_duel.netState());
    final t = (sim.ticks * 1000 / kTicksPerSecond).round();
    if (sim.over && !_overSent) {
      _overSent = sync.publish(t, payload, now, force: true);
      _overAt = now;
    } else {
      sync.publish(t, payload, now);
    }
    _show(_duel.netState());
    if (_duel.duelWinner >= 0 && _overAt >= 0 && now - _overAt > 600) _finish(_duel.duelWinner);
  }

  void _guestFrame(int now) {
    final local = _localInput();
    if (local.tap) _taps++;
    if (local.swipe == 0) _ups++;
    sync.setAxes([_down ? 1 : 0, _px.roundToDouble(), _py.roundToDouble(), _taps.toDouble(), _ups.toDouble()]);
    sync.pump(now);
    final fr = sync.frame(now);
    if (fr == null) return;
    final a = decodeNums(fr.$1.payload), b = decodeNums(fr.$2.payload);
    _show(identical(fr.$1, fr.$2) ? b : (view as DuelSim).lerpNet(a, b, fr.$3));
    final l = sync.latest;
    if (l == null) return;
    final probe = _probe as DuelSim;
    probe.applyNetState(decodeNums(l.payload));
    final w = probe.duelWinner;
    if (w >= 0) {
      if (_overAt < 0) _overAt = now;
      if (now - _overAt > 700) _finish(w);
    }
  }

  void _show(List<double> state) {
    final v = view as DuelSim;
    v.applyNetState(state);
    if (side == 1) v.mirrorView();
  }

  void _finish(int winnerSide) {
    if (_ended) return;
    _ended = true;
    final won = winnerSide == side;
    final l = link;
    if (l != null) unawaited(l.finish(winnerSide, iWon: won).catchError((Object _) {}));
    widget.ctx.sfx(won ? Sfx.win : Sfx.lose);
    widget.ctx.finish(RoundResult(
      won: won,
      score: won ? 500 : 0,
      stars: won ? 2 : 0,
      seconds: (sim.ticks / kTicksPerSecond).round(),
      gameStats: {'matches_won': won ? 1 : 0},
    ));
  }

  // ---- ekran ----

  void _pointer(Offset local) {
    final w = (local - _origin) / _scale;
    _px = clampD(w.dx, 0, kWorldW);
    _py = clampD(w.dy, 0, kWorldH);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final palette = ArcadePalette(ctx.pieceColors, ctx.background, ctx.colorBlind, ctx.reducedMotion);
    final opp = side == 0 ? 1 : 0;
    final oppBot = sync.isHost ? !sync.live(opp, _now) : (sync.latest?.isBot(opp) ?? false);
    final head = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(children: [
        Flexible(child: _chip(ctx.seatName(me), true)),
        Expanded(
          child: Text(view.goalText,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
        ),
        Flexible(child: _chip('${oppBot ? '🤖 ' : ''}${ctx.seatName(opp)}', false)),
      ]),
    );
    return ColoredBox(
      color: const Color(0xFF1A1B2E),
      child: Column(children: [
        head,
        Expanded(
          child: LayoutBuilder(builder: (context, box) {
            _scale = math.min(box.maxWidth / kWorldW, box.maxHeight / kWorldH);
            _origin = Offset((box.maxWidth - kWorldW * _scale) / 2, (box.maxHeight - kWorldH * _scale) / 2);
            return Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (e) {
                _pointer(e.localPosition);
                _down = true;
                _tapEdge = true;
                _panStart = e.localPosition;
              },
              onPointerMove: (e) => _pointer(e.localPosition),
              onPointerUp: (e) {
                _down = false;
                final s = _panStart;
                if (s != null) {
                  final d = e.localPosition - s;
                  if (d.distance > 28 && d.dy.abs() > d.dx.abs() && d.dy < 0) _upEdge = true;
                }
                _panStart = null;
              },
              onPointerCancel: (_) => _down = false,
              child: CustomPaint(
                size: Size.infinite,
                painter: _DuelPainter(view, widget.paint, palette, _scale, _origin, view.ticks / 60.0),
              ),
            );
          }),
        ),
      ]),
    );
  }

  Widget _chip(String text, bool mine) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFF52B788) : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
      );
}

class _DuelPainter extends CustomPainter {
  final ArcadeSim sim;
  final ArcadePainterFn fn;
  final ArcadePalette palette;
  final double scale;
  final Offset origin;
  final double t;
  _DuelPainter(this.sim, this.fn, this.palette, this.scale, this.origin, this.t);

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
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
