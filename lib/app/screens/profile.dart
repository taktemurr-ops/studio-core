import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/progression.dart';
import '../../core/stats.dart';
import '../app_state.dart';
import '../widgets.dart';

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
        (app.strings.lang == 'tr' ? g.nameTr : g.nameEn, '${s.stat(g.key)}'),
    ];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Center(
        child: Column(children: [
          CircleAvatar(radius: 40, child: Text('$lvl', style: const TextStyle(fontSize: 28))),
          const SizedBox(height: 8),
          Text('${app.t('player_level')} $lvl · ${app.t('tier_${tier.name}')}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          SizedBox(width: 240, child: LinearProgressIndicator(value: PlayerProgression.progressInLevel(s.totalXp))),
        ]),
      ),
      SectionTitle(app.t('stats')),
      Card(
        child: Column(children: [
          for (final r in rows) ListTile(dense: true, title: Text(r.$1), trailing: Text(r.$2)),
        ]),
      ),
      SectionTitle(app.t('records')),
      Card(
        child: Column(children: [
          for (final e in s.records.entries)
            ListTile(dense: true, title: Text(app.t('mode_${e.key}')), trailing: Text('${e.value}')),
          if (s.records.isEmpty) const ListTile(title: Text('—')),
        ]),
      ),
      SectionTitle(app.t('backup')),
      Wrap(spacing: 8, children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.copy),
          label: Text(app.t('backup')),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: app.session.store.exportBackup(s)));
            if (context.mounted) showToast(context, app.t('backup_copied'));
          },
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.restore),
          label: Text(app.t('restore_backup')),
          onPressed: () => _import(context, app),
        ),
      ]),
    ]);
  }

  Future<void> _import(BuildContext context, AppState app) async {
    final ctrl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(app.t('paste_backup')),
        content: TextField(controller: ctrl, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(app.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: Text(app.t('ok'))),
        ],
      ),
    );
    ctrl.dispose();
    if (text == null || !context.mounted) return;
    final data = app.session.store.importBackup(text);
    if (data == null) {
      showToast(context, app.t('backup_invalid'));
      return;
    }
    app.session.save = data;
    app.changed(saveNow: true);
    showToast(context, app.t('backup_restored'));
  }
}
