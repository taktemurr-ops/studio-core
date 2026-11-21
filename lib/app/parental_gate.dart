import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_state.dart';

/// Simple adult check shown before purchases in kids titles (Google Play
/// Families / Apple Kids category). Other titles pass straight through.
Future<bool> parentalGate(BuildContext context, AppState app) async {
  if (!app.config.kidsMode) return true;
  final r = math.Random();
  final a = 6 + r.nextInt(4), b = 6 + r.nextInt(4);
  final answer = a * b;
  final opts = <int>{answer};
  while (opts.length < 4) {
    opts.add(answer + (r.nextInt(17) - 8));
  }
  final list = opts.toList()..shuffle(r);
  final tr = app.strings.lang == 'tr';
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr ? 'Ebeveyn kontrolü' : 'Ask a grown-up'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(tr ? 'Devam etmek için bir yetişkin cevaplasın:' : 'A grown-up should answer to continue:'),
        const SizedBox(height: 12),
        Text('$a × $b = ?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final o in list)
            OutlinedButton(onPressed: () => Navigator.of(ctx).pop(o == answer), child: Text('$o')),
        ]),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(tr ? 'Vazgeç' : 'Cancel')),
      ],
    ),
  );
  return ok ?? false;
}
