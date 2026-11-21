import 'package:flutter/material.dart';

import '../app_state.dart';

Future<void> showTutorial(BuildContext context, AppState app) {
  final steps = app.config.tutorial;
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(app.t('tutorial_title')),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final s in steps)
              ListTile(
                leading: Icon(s.icon, color: Theme.of(c).colorScheme.primary),
                title: Text(app.config.localized(s.text, app.strings.lang)),
              ),
          ],
        ),
      ),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(app.t('got_it')))],
    ),
  );
}
