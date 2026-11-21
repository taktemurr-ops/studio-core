import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import 'play.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final all = app.session.achievementCatalog.all;
    final unlocked = app.save.achievements;
    final sorted = [...all]..sort((a, b) {
        final ua = unlocked.contains(a.id) ? 0 : 1;
        final ub = unlocked.contains(b.id) ? 0 : 1;
        if (ua != ub) return ua - ub;
        return b.progress(app.save).compareTo(a.progress(app.save));
      });
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text(app.t('unlocked_n', {'a': unlocked.length, 'b': all.length}),
            style: Theme.of(context).textTheme.titleMedium),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: sorted.length,
          itemBuilder: (c, i) {
            final a = sorted[i];
            final done = unlocked.contains(a.id);
            final hiddenLocked = a.hidden && !done;
            return ListTile(
              leading: Icon(
                done ? Icons.emoji_events : (a.hidden ? Icons.help_outline : Icons.lock_outline),
                color: done ? Colors.amber : Colors.grey,
              ),
              title: Text(hiddenLocked ? app.t('hidden_ach') : achievementTitle(app, a.titleKey, a.params, a.id)),
              subtitle: hiddenLocked
                  ? null
                  : LinearProgressIndicator(value: done ? 1 : a.progress(app.save)),
              trailing: Text('+${a.coins}${a.gems > 0 ? ' 💎${a.gems}' : ''}'),
            );
          },
        ),
      ),
    ]);
  }
}
