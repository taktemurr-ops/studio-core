import 'package:flutter/material.dart';

import '../app_state.dart';
import '../studio_ui.dart';

Future<void> showTutorial(BuildContext context, AppState app) {
  final steps = app.config.tutorial;
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.school_rounded, size: 40),
      title: Text(app.t('tutorial_title')),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in steps)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  StudioIconBadge(s.icon, color: StudioLook.of(c).play, size: 38),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(app.config.localized(s.text, app.strings.lang),
                        style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3)),
                  ),
                ]),
              ),
          ],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(app.t('got_it')))],
    ),
  );
}
