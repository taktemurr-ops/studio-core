import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app_state.dart';
import '../studio_ui.dart';
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
    final look = StudioLook.of(context);
    return Column(children: [
      StudioPanel(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
        child: Row(children: [
          const Icon(Icons.emoji_events_rounded, color: StudioLook.gold, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.t('unlocked_n', {'a': unlocked.length, 'b': all.length}),
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              StudioBar(value: all.isEmpty ? 0 : unlocked.length / all.length, color: StudioLook.gold),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: sorted.length,
          itemBuilder: (c, i) {
            final a = sorted[i];
            final done = unlocked.contains(a.id);
            final hiddenLocked = a.hidden && !done;
            return StudioPanel(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              borderColor: done ? StudioLook.gold.withValues(alpha: 0.8) : null,
              child: Row(children: [
                StudioIconBadge(
                  done ? Icons.emoji_events_rounded : (a.hidden ? Icons.help_outline_rounded : Icons.lock_outline_rounded),
                  color: done ? const Color(0xFFD9A21C) : const Color(0xFF55597A),
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(hiddenLocked ? app.t('hidden_ach') : achievementTitle(app, a.titleKey, a.params, a.id),
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    if (!hiddenLocked) ...[
                      const SizedBox(height: 6),
                      StudioBar(value: done ? 1 : a.progress(app.save), color: done ? StudioLook.gold : look.accent, height: 7),
                    ],
                  ]),
                ),
                const SizedBox(width: 10),
                Text('+${a.coins}${a.gems > 0 ? ' 💎${a.gems}' : ''}',
                    style: const TextStyle(color: StudioLook.gold, fontWeight: FontWeight.w800)),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}
