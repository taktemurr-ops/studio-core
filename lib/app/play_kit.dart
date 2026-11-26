import 'dart:async';

import 'package:flutter/material.dart';

import 'studio_ui.dart';

/// Shared building blocks for game screens: HUD chips, booster bar and a
/// round clock with pause support. Onaylı tasarım: koyu, kenarlı haplar.
class PlayHud extends StatelessWidget {
  final List<(IconData, String)> items;
  const PlayHud({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          for (final i in items) StudioStatChip(icon: i.$1, color: look.accent, text: i.$2, compact: true),
        ],
      ),
    );
  }
}

class BoosterButton {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool active;
  const BoosterButton(this.icon, this.label, this.onPressed, {this.active = false});
}

class BoosterBar extends StatelessWidget {
  final List<BoosterButton> buttons;
  const BoosterBar({super.key, required this.buttons});

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final b in buttons)
            IconButton(
              isSelected: b.active,
              onPressed: b.onPressed,
              icon: Icon(b.icon),
              tooltip: b.label,
              style: IconButton.styleFrom(
                fixedSize: const Size(54, 54),
                foregroundColor: Colors.white,
                backgroundColor: b.active ? look.accent : Colors.black.withValues(alpha: 0.32),
                disabledBackgroundColor: Colors.black.withValues(alpha: 0.18),
                disabledForegroundColor: Colors.white38,
                side: BorderSide(color: b.active ? look.accent : look.accent.withValues(alpha: 0.55), width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ).copyWith(
                foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled)
                    ? Colors.white38
                    : (b.active ? look.onAccent : Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Seconds counter for a round. Call [startClock] in initState and
/// [stopClock] in dispose. [onTimeUp] fires once when [timeLimit] passes.
mixin RoundClock<T extends StatefulWidget> on State<T> {
  Timer? _clock;
  int seconds = 0;
  int timeLimit = 0;
  bool clockPaused = false;
  bool _timeUpFired = false;

  void onTimeUp() {}

  int get timeLeft => timeLimit == 0 ? -1 : (timeLimit - seconds).clamp(0, 1 << 30);

  String get timeText {
    final t = timeLimit == 0 ? seconds : timeLeft;
    return '${t ~/ 60}:${(t % 60).toString().padLeft(2, '0')}';
  }

  void startClock({int initialSeconds = 0, int limit = 0}) {
    seconds = initialSeconds;
    timeLimit = limit;
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || clockPaused) return;
      setState(() => seconds++);
      if (timeLimit > 0 && seconds >= timeLimit && !_timeUpFired) {
        _timeUpFired = true;
        onTimeUp();
      }
    });
  }

  void stopClock() => _clock?.cancel();
}

/// Draws centered text on a canvas.
void paintText(Canvas canvas, String s, Offset center, double size, Color color,
    {FontWeight weight = FontWeight.bold}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color, fontWeight: weight)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}
