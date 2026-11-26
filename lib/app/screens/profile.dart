import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/progression.dart';
import '../../core/stats.dart';
import '../app_state.dart';
import '../studio_ui.dart';
import '../widgets.dart';
import 'achievements.dart';
import 'collection.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(appStateProvider).openedScreen('stats_opened');
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final s = app.save;
    final lvl = PlayerProgression.levelForXp(s.totalXp);
    final tier = PlayerProgression.tierFor(lvl);
    final secs = s.stat(Stat.playSeconds);
    final rows = <(String, String)>[
      (app.t('levels_done'), '${s.completedLevels}'),
      (app.t('stars_total'), '${s.totalStars}'),
      (app.t('win_rate'), '%${app.winRatePercent}'),
      (app.t('best_streak'), '${s.stat(Stat.bestWinStreak)}'),
      (app.t('play_time'), '${secs ~/ 3600}h ${(secs % 3600) ~/ 60}m'),
      (app.t('streak', {'n': s.loginStreak}), '${s.bestLoginStreak}'),
      for (final g in app.config.rules.gameStats)
        (g.name(app.strings.lang), '${s.stat(g.key)}'),
    ];
    final look = StudioLook.of(context);
    Widget table(List<(String, String)> list) => StudioPanel(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Column(children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Expanded(child: Text(list[i].$1, style: const TextStyle(color: Color(0xFFD9DCF0), fontSize: 14))),
                  const SizedBox(width: 8),
                  Text(list[i].$2, style: TextStyle(color: look.number, fontSize: 16, fontWeight: FontWeight.w900)),
                ]),
              ),
            ],
          ]),
        );
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      StudioPanel(
        margin: EdgeInsets.zero,
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [Color.lerp(look.card, look.accent, 0.20)!, Color.lerp(look.card, Colors.black, 0.40)!],
        ),
        child: Row(children: [
          Semantics(
            label: '${app.t('player_level')} $lvl',
            excludeSemantics: true,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [look.accent, look.play]),
                boxShadow: [BoxShadow(color: look.accent.withValues(alpha: 0.45), blurRadius: 16)],
              ),
              child: Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 76,
                  height: 76,
                  child: CircularProgressIndicator(
                    value: PlayerProgression.progressInLevel(s.totalXp),
                    strokeWidth: 5,
                    color: Colors.white,
                    backgroundColor: Colors.black.withValues(alpha: 0.25),
                  ),
                ),
                Text('$lvl', style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              ]),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${app.t('player_level')} $lvl',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFFFE08A), borderRadius: BorderRadius.circular(10)),
                child: Text(app.t('tier_${tier.name}'),
                    style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 10),
              StudioBar(value: PlayerProgression.progressInLevel(s.totalXp), color: StudioLook.good),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _Shortcut(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFD9A21C),
                label: app.t('achievements'),
                page: const AchievementsScreen())),
        const SizedBox(width: 10),
        Expanded(
            child: _Shortcut(
                icon: Icons.collections_rounded,
                color: const Color(0xFF9763BC),
                label: app.t('collection'),
                page: const CollectionScreen())),
      ]),
      SectionTitle(app.t('stats'), icon: Icons.bar_chart_rounded),
      table(rows),
      SectionTitle(app.t('records'), icon: Icons.military_tech_rounded, iconColor: StudioLook.gold),
      table([
        for (final e in s.records.entries) (app.t('mode_${e.key}'), '${e.value}'),
        if (s.records.isEmpty) ('—', ''),
      ]),
    ]);
  }
}

class _Shortcut extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final Widget page;
  const _Shortcut({required this.icon, required this.color, required this.label, required this.page});

  @override
  Widget build(BuildContext context) => StudioPanel(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        semanticLabel: label,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => StudioScaffold(title: label, icon: icon, body: page)),
        ),
        child: Row(children: [
          StudioIconBadge(icon, color: color, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
          ),
        ]),
      );
}
