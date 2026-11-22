import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/daily.dart';
import '../core/progression.dart';
import 'app_state.dart';

/// Coins / gems / hints and player level, shown on most screens.
class CurrencyBar extends StatelessWidget {
  final AppState app;
  const CurrencyBar({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final s = app.save;
    final lvl = PlayerProgression.levelForXp(s.totalXp);
    final prog = PlayerProgression.progressInLevel(s.totalXp);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Semantics(
            label: '${app.t('player_level')} $lvl',
            child: SizedBox(
              width: 44,
              height: 44,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(value: prog, strokeWidth: 4),
                Text('$lvl', style: const TextStyle(fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
          const Spacer(),
          _Pill(icon: Icons.monetization_on, color: Colors.amber, value: s.coins, label: app.t('coins')),
          _Pill(icon: Icons.diamond, color: Colors.cyan, value: s.gems, label: app.t('gems')),
          _Pill(icon: Icons.lightbulb, color: Colors.orange, value: s.hints, label: app.t('hints')),
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
    return Semantics(
      label: '$label $value',
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(compactNumber(value), style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
      ),
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
                size: size, color: i < stars ? Colors.amber : Colors.grey),
          ),
        ),
      );
}

class RewardChips extends StatelessWidget {
  final Reward reward;
  const RewardChips({super.key, required this.reward});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    void add(IconData i, Color c, int v) {
      if (v > 0) {
        chips.add(Chip(
          avatar: Icon(i, color: c, size: 18),
          label: Text('+$v'),
          visualDensity: VisualDensity.compact,
        ));
      }
    }

    add(Icons.monetization_on, Colors.amber, reward.coins);
    add(Icons.diamond, Colors.cyan, reward.gems);
    add(Icons.lightbulb, Colors.orange, reward.hints);
    add(Icons.bolt, const Color(0xFF9763BC), reward.boosters);
    add(Icons.trending_up, Colors.green, reward.xp);
    return Wrap(spacing: 6, runSpacing: 4, alignment: WrapAlignment.center, children: chips);
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
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      );
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
