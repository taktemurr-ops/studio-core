import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/level_plan.dart';
import '../adaptive.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';

/// 500 worlds x 100 levels, lazily built. Endless beyond 50.000.
class LevelsScreen extends ConsumerWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final current = app.save.currentLevel;
    final currentWorld = (current - 1) ~/ LevelPlanner.levelsPerWorld + 1;
    final worlds = currentWorld.clamp(1, 1 << 20) + 2;
    return Scaffold(
      appBar: AppBar(title: Text(app.t('worlds'))),
      body: ContentWidth(child: ListView.builder(
        itemCount: worlds,
        itemBuilder: (c, i) {
          final w = i + 1;
          final unlocked = w <= currentWorld;
          final colors = Palettes.theme((w - 1) % Palettes.themes.length);
          var stars = 0;
          for (var l = (w - 1) * 100 + 1; l <= w * 100; l++) {
            stars += app.save.starsFor(l);
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ThemedBackground(
                colors: colors,
                child: ListTile(
                  enabled: unlocked,
                  textColor: Colors.white,
                  iconColor: Colors.white,
                  leading: Icon(unlocked ? Icons.public : Icons.lock),
                  title: Text(app.t('world', {'n': w})),
                  subtitle: Text('${(w - 1) * 100 + 1} - ${w * 100}   ★ $stars/300'),
                  onTap: unlocked
                      ? () => Navigator.push(c, MaterialPageRoute(builder: (_) => WorldScreen(world: w)))
                      : null,
                ),
              ),
            ),
          );
        },
      )),
    );
  }
}

class WorldScreen extends ConsumerWidget {
  final int world;
  const WorldScreen({super.key, required this.world});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final first = (world - 1) * 100 + 1;
    return Scaffold(
      appBar: AppBar(title: Text(app.t('world', {'n': world}))),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 76, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: 100,
        itemBuilder: (c, i) {
          final level = first + i;
          final open = level <= app.save.currentLevel;
          final stars = app.save.starsFor(level);
          return Semantics(
            button: true,
            label: '${app.t('level', {'n': level})} $stars/3',
            child: Material(
              color: open
                  ? (level == app.save.currentLevel
                      ? Theme.of(c).colorScheme.primary
                      : Theme.of(c).colorScheme.primaryContainer)
                  : Theme.of(c).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: open ? () => openPlay(c, app, app.session.campaignSpec(level)) : null,
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  open
                      ? Text('$level',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: level == app.save.currentLevel ? Colors.white : null))
                      : const Icon(Icons.lock, size: 16),
                  if (open && stars > 0) StarRow(stars: stars, size: 12),
                  if (level % 1000 == 0) const Icon(Icons.card_giftcard, size: 14, color: Colors.purple),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final done = app.save.challengesDone;
    return Scaffold(
      appBar: AppBar(title: Text(app.t('mode_challenge'))),
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 90, mainAxisSpacing: 8, crossAxisSpacing: 8),
        itemCount: LevelPlanner.challengeCount,
        itemBuilder: (c, i) {
          final n = i + 1;
          // Challenges unlock progressively: 5 + 1 per 20 campaign levels.
          final open = n <= 5 + app.save.highestLevel ~/ 20;
          final ok = done.contains('c$n');
          return Card(
            color: ok ? Colors.green.shade100 : null,
            child: InkWell(
              onTap: open ? () => openPlay(c, app, app.session.planner.challenge(n)) : null,
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(ok ? Icons.check_circle : (open ? Icons.military_tech : Icons.lock),
                      color: ok ? Colors.green : null),
                  Text('$n'),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
