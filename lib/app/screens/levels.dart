import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/level_plan.dart';
import '../adaptive.dart';
import '../app_state.dart';
import '../studio_ui.dart';
import '../theme.dart';
import '../widgets.dart';
import 'home.dart';

/// levelCount / 100 worlds (500 or 1000), lazily built. Endless beyond.
class LevelsScreen extends ConsumerWidget {
  const LevelsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final current = app.save.currentLevel;
    final currentWorld = (current - 1) ~/ LevelPlanner.levelsPerWorld + 1;
    // Show the full 50.000-level map (500 worlds); endless worlds keep going past it.
    final total = app.config.rules.levelCount;
    final worlds = currentWorld + 2 > total ~/ LevelPlanner.levelsPerWorld
        ? currentWorld + 2
        : total ~/ LevelPlanner.levelsPerWorld;
    return StudioScaffold(
      title: app.t('worlds'),
      icon: Icons.map_rounded,
      body: ContentWidth(
        child: ListView.builder(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: worlds + 1,
          itemBuilder: (c, i) {
            if (i == 0) {
              final frac = total == 0 ? 0.0 : (current - 1) / total;
              return StudioPanel(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(children: [
                  StudioIconBadge(Icons.flag_rounded, color: StudioLook.of(c).play, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('${current - 1} / $total',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      StudioBar(value: frac),
                    ]),
                  ),
                ]),
              );
            }
            final w = i;
            final unlocked = w <= currentWorld;
            final colors = Palettes.theme((w - 1) % Palettes.themes.length);
            var stars = 0;
            for (var l = (w - 1) * 100 + 1; l <= w * 100; l++) {
              stars += app.save.starsFor(l);
            }
            return StudioPanel(
              semanticLabel: '${app.t('world', {'n': w})}, ★ $stars/300',
              onTap: unlocked ? () => Navigator.push(c, MaterialPageRoute(builder: (_) => WorldScreen(world: w))) : null,
              borderColor: w == currentWorld ? StudioLook.of(c).accent : null,
              child: Opacity(
                opacity: unlocked ? 1 : 0.55,
                child: Row(children: [
                  // Dünyanın kendi teması küçük bir pencerede.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 54,
                      height: 54,
                      child: ThemedBackground(
                        colors: colors,
                        child: Center(
                          child: unlocked
                              ? Text('$w',
                                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900))
                              : const Icon(Icons.lock_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(app.t('world', {'n': w}),
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('${(w - 1) * 100 + 1} - ${w * 100}',
                          style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 13)),
                      const SizedBox(height: 6),
                      StudioBar(value: stars / 300, color: StudioLook.gold, height: 7),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded, color: StudioLook.gold, size: 22),
                    Text('$stars', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ]),
                  if (unlocked) const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                ]),
              ),
            );
          },
        ),
      ),
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
    final look = StudioLook.of(context);
    return StudioScaffold(
      title: app.t('world', {'n': world}),
      icon: Icons.public_rounded,
      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 78, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: 100,
        itemBuilder: (c, i) {
          final level = first + i;
          final open = level <= app.save.currentLevel;
          final isCurrent = level == app.save.currentLevel;
          final stars = app.save.starsFor(level);
          final r = BorderRadius.circular(16);
          return Semantics(
            button: true,
            enabled: open,
            label: '${app.t('level', {'n': level})} $stars/3',
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              borderRadius: r,
              child: InkWell(
                borderRadius: r,
                onTap: open ? () => openPlay(c, app, app.session.campaignSpec(level)) : null,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: isCurrent ? look.playGradient : (open ? look.tile : null),
                    color: open ? null : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isCurrent
                          ? Colors.white.withValues(alpha: 0.85)
                          : (open ? look.accent.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.14)),
                      width: isCurrent ? 2 : 1.2,
                    ),
                    boxShadow: isCurrent ? [BoxShadow(color: look.play.withValues(alpha: 0.55), blurRadius: 14)] : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        open
                            ? Text('$level',
                                style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: isCurrent ? look.onPlay : Colors.white))
                            : const Icon(Icons.lock_rounded, size: 18, color: Colors.white38),
                        if (open && stars > 0) StarRow(stars: stars, size: 13),
                        if (level % 1000 == 0)
                          const Icon(Icons.card_giftcard_rounded, size: 15, color: Color(0xFFD9A6FF)),
                      ]),
                    ),
                  ),
                ),
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
    final look = StudioLook.of(context);
    return StudioScaffold(
      title: app.t('mode_challenge'),
      icon: Icons.military_tech_rounded,
      body: GridView.builder(
        padding: const EdgeInsets.all(14),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 92, mainAxisSpacing: 10, crossAxisSpacing: 10),
        itemCount: LevelPlanner.challengeCount,
        itemBuilder: (c, i) {
          final n = i + 1;
          // Challenges unlock progressively: 5 + 1 per 20 campaign levels.
          final open = n <= 5 + app.save.highestLevel ~/ 20;
          final ok = done.contains('c$n');
          final r = BorderRadius.circular(18);
          return Semantics(
            button: true,
            enabled: open,
            label: app.t('challenge_n', {'n': n}),
            excludeSemantics: true,
            child: Material(
              color: Colors.transparent,
              borderRadius: r,
              child: InkWell(
                borderRadius: r,
                onTap: open ? () => openPlay(c, app, app.session.planner.challenge(n)) : null,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: r,
                    gradient: open ? look.tile : null,
                    color: open ? null : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                        color: ok
                            ? StudioLook.good
                            : (open ? look.accent.withValues(alpha: 0.55) : Colors.white.withValues(alpha: 0.14)),
                        width: ok ? 2 : 1.2),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(ok ? Icons.check_circle_rounded : (open ? Icons.military_tech_rounded : Icons.lock_rounded),
                            color: ok ? StudioLook.good : (open ? StudioLook.gold : Colors.white38), size: 28),
                        Text('$n',
                            style: TextStyle(
                                color: open ? Colors.white : Colors.white38, fontWeight: FontWeight.w900, fontSize: 16)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
