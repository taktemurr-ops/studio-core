import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/daily.dart';
import '../core/progression.dart';
import 'app_state.dart';
import 'studio_ui.dart';

/// Coins / gems / hints and player level, shown on most screens.
/// Onaylı tasarım: seviye halkası + koyu, kenarlı para hapları.
class CurrencyBar extends StatelessWidget {
  final AppState app;
  const CurrencyBar({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final s = app.save;
    final look = StudioLook.of(context);
    final lvl = PlayerProgression.levelForXp(s.totalXp);
    final prog = PlayerProgression.progressInLevel(s.totalXp);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Semantics(
            label: '${app.t('player_level')} $lvl',
            excludeSemantics: true,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.30),
                border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
              ),
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                      value: prog, strokeWidth: 4, color: look.accent, backgroundColor: Colors.white.withValues(alpha: 0.15)),
                ),
                Text('$lvl', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          const Spacer(),
          _Pill(icon: Icons.monetization_on_rounded, color: StudioLook.gold, value: s.coins, label: app.t('coins')),
          _Pill(icon: Icons.diamond_rounded, color: StudioLook.gem, value: s.gems, label: app.t('gems')),
          _Pill(icon: Icons.lightbulb_rounded, color: const Color(0xFFFFA53A), value: s.hints, label: app.t('hints')),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  final String label;
  const _Pill({required this.icon, required this.color, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 6),
      child: StudioStatChip(icon: icon, color: color, text: compactNumber(value), semanticLabel: '$label $value', compact: true),
    );
  }
}

String compactNumber(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 10000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarRow({super.key, required this.stars, this.size = 20});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$stars/3',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Icon(i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i < stars ? StudioLook.gold : Colors.white.withValues(alpha: 0.35),
                shadows: i < stars && size >= 28
                    ? [Shadow(color: StudioLook.gold.withValues(alpha: 0.6), blurRadius: 12)]
                    : null),
          ),
        ),
      );
}

/// Ödül hapları (para, elmas, ipucu, güçlendirici, deneyim).
class RewardChips extends StatelessWidget {
  final Reward reward;
  const RewardChips({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    void add(IconData i, Color c, int v) {
      if (v > 0) chips.add(StudioStatChip(icon: i, color: c, text: '+$v', compact: true));
    }

    add(Icons.monetization_on_rounded, StudioLook.gold, reward.coins);
    add(Icons.diamond_rounded, StudioLook.gem, reward.gems);
    add(Icons.lightbulb_rounded, const Color(0xFFFFA53A), reward.hints);
    add(Icons.bolt_rounded, const Color(0xFFB98CFF), reward.boosters);
    add(Icons.trending_up_rounded, StudioLook.good, reward.xp);
    return Wrap(spacing: 6, runSpacing: 6, alignment: WrapAlignment.center, children: chips);
  }
}

/// Lightweight confetti; disabled when reduced motion is on.
class Confetti extends StatefulWidget {
  final bool enabled;
  const Confetti({super.key, this.enabled = true});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(painter: _ConfettiPainter(_c.value), size: Size.infinite),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final double t;
  _ConfettiPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.Random(7);
    final p = Paint();
    for (var i = 0; i < 70; i++) {
      final x = r.nextDouble() * size.width;
      final speed = 0.5 + r.nextDouble();
      final y = -20 + (size.height + 40) * (t * speed % 1.0);
      p.color = HSLColor.fromAHSL(1 - t * 0.6, (i * 47) % 360.0, 0.8, 0.6).toColor();
      canvas.save();
      canvas.translate(x + math.sin(t * 10 + i) * 12, y);
      canvas.rotate(t * 6 + i);
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}

class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? iconColor;
  const SectionTitle(this.text, {super.key, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
      child: Row(children: [
        Icon(icon ?? Icons.auto_awesome_rounded, color: iconColor ?? look.accent, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          ),
        ),
      ]),
    );
  }
}

void showToast(BuildContext context, String text) {
  ScaffoldMessenger.maybeOf(context)
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating));
}

/// Gradient background for the current world theme.
class ThemedBackground extends StatelessWidget {
  final List<Color> colors;
  final Widget child;
  const ThemedBackground({super.key, required this.colors, required this.child});

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _BackdropPainter(colors),
        child: child,
      );
}

/// Oyun arka planı: yumuşak geçiş, üstte ışık halesi, birkaç büyük ve çok
/// silik daire (derinlik hissi) ve kenarlarda hafif kararma. Düz renk yerine
/// canlı ama göz yormayan bir zemin.
class _BackdropPainter extends CustomPainter {
  final List<Color> colors;
  _BackdropPainter(this.colors);

  @override
  bool shouldRepaint(covariant _BackdropPainter o) => o.colors != colors;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    final top = colors.first, bottom = colors.length > 1 ? colors.last : colors.first;
    c.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(top, bottom, 0.15)!, Color.lerp(top, bottom, 0.55)!, bottom],
          ).createShader(r));
    c.drawRect(
        r,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.85),
            radius: 0.9,
            colors: [Colors.white.withValues(alpha: 0.16), Colors.white.withValues(alpha: 0)],
          ).createShader(r));
    final m = s.shortestSide;
    const spots = [(0.12, 0.22, 0.32), (0.88, 0.38, 0.26), (0.2, 0.78, 0.4), (0.82, 0.9, 0.3), (0.55, 0.06, 0.18)];
    for (final (x, y, rr) in spots) {
      c.drawCircle(Offset(s.width * x, s.height * y), m * rr, Paint()..color = Colors.white.withValues(alpha: 0.035));
    }
    c.drawRect(
        r,
        Paint()
          ..shader = RadialGradient(
            radius: 1.15,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.22)],
            stops: const [0.62, 1],
          ).createShader(r));
  }
}
