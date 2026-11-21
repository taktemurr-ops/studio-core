import 'dart:async';

import 'package:flutter/material.dart';

/// Shared building blocks for game screens: HUD chips, booster bar and a
/// round clock with pause support.
class PlayHud extends StatelessWidget {
  final List<(IconData, String)> items;
  const PlayHud({super.key, required this.items});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final i in items)
              Chip(
                avatar: Icon(i.$1, size: 16),
                label: Text(i.$2),
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      );
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final b in buttons)
              IconButton.filledTonal(
                isSelected: b.active,
                onPressed: b.onPressed,
                icon: Icon(b.icon),
                tooltip: b.label,
              ),
          ],
        ),
      );
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
