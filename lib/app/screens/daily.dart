import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/daily.dart';
import '../../core/level_plan.dart';
import '../../core/missions.dart';
import '../app_state.dart';
import '../widgets.dart';
import 'home.dart';
import 'play.dart';

/// Daily login, daily gift, surprise, daily/weekly levels, missions, records.
class DailyScreen extends ConsumerWidget {
  const DailyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final s = app.save;
    final now = app.session.now();
    final d = app.session.daily;
    final today = app.dayKey();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ---- Login calendar ----
        SectionTitle(app.t('daily_login')),
        Text(app.t('streak', {'n': s.loginStreak})),
        const SizedBox(height: 8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: DailySystems.loginCycle.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (c, i) {
              final cyclePos = (s.loginStreak - 1) % DailySystems.loginCycle.length;
              final isToday = i == cyclePos;
              final r = DailySystems.loginCycle[i];
              return Container(
                width: 72,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isToday
                      ? Theme.of(c).colorScheme.primaryContainer
                      : Theme.of(c).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: isToday ? Border.all(color: Theme.of(c).colorScheme.primary, width: 2) : null,
                ),
                // scaleDown: the tile never overflows, whatever the font scale.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(app.t('day_n', {'n': i + 1}), style: const TextStyle(fontSize: 12)),
                    Icon(r.gems > 0 ? Icons.diamond : Icons.monetization_on,
                        color: r.gems > 0 ? Colors.cyan : Colors.amber),
                    Text('${r.coins}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: d.loginRewardAvailable(s, now)
              ? () {
                  final r = app.claimLogin();
                  if (r != null) _rewardDialog(context, app, r);
                }
              : null,
          child: Text(d.loginRewardAvailable(s, now) ? app.t('claim') : app.t('claimed')),
        ),

        // ---- Daily gift & surprise ----
        SectionTitle(app.t('wheel')),
        _Wheel(app: app),
        SectionTitle(app.t('surprise')),
        ListTile(
          leading: const Icon(Icons.card_giftcard, color: Colors.purple),
          title: Text(app.t('surprise')),
          subtitle: Text(s.lastSurpriseDay == today ? app.t('claimed') : app.t('surprise_hint')),
          trailing: FilledButton(
            onPressed: d.surpriseAvailable(s, now)
                ? () {
                    final r = app.claimSurprise();
                    if (r != null) _rewardDialog(context, app, r);
                  }
                : null,
            child: Text(app.t('claim')),
          ),
        ),

        // ---- Special levels ----
        SectionTitle(app.t('mode_daily')),
        Card(
          child: ListTile(
            leading: const Icon(Icons.today),
            title: Text(app.t('mode_daily')),
            subtitle: Text(app.t('mode_daily_d')),
            trailing: s.dailyLevelDoneDay == today
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.play_arrow),
            onTap: () => openMode(context, app, GameModeId.daily),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.date_range),
            title: Text(app.t('mode_weekly')),
            subtitle: Text(app.t('mode_weekly_d')),
            trailing: s.weeklyLevelDoneWeek == s.weeklyKey
                ? const Icon(Icons.check_circle, color: Colors.green)
                : const Icon(Icons.play_arrow),
            onTap: () => openMode(context, app, GameModeId.weekly),
          ),
        ),
        Text(app.t('daily_record', {'n': s.dailyRecordDay == today ? s.dailyRecord : 0})),
        Text(app.t('weekly_goal', {'a': d.weeklyGoalProgress(s), 'b': d.weeklyGoal(s)})),
        LinearProgressIndicator(
          value: (d.weeklyGoalProgress(s) / d.weeklyGoal(s)).clamp(0.0, 1.0),
        ),

        // ---- Missions ----
        SectionTitle(app.t('daily_missions')),
        for (final m in app.session.dailyMissions) _MissionTile(app: app, m: m),
        SectionTitle(app.t('weekly_missions')),
        for (final m in app.session.weeklyMissions) _MissionTile(app: app, m: m),
      ],
    );
  }
}

void _rewardDialog(BuildContext context, AppState app, Reward r) {
  showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(app.t('reward')),
      content: RewardChips(reward: r),
      actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(app.t('ok')))],
    ),
  );
}

String missionTitle(AppState app, Mission m) {
  final id = m.id.substring(2);
  final key = 'mission_$id';
  final text = app.t(key, {'n': m.target});
  if (text != key) return text;
  return achievementTitle(app, 'mission_stat', {'stat': m.statKey, 'n': '${m.target}'}, m.id);
}

class _MissionTile extends StatelessWidget {
  final AppState app;
  final Mission m;
  const _MissionTile({required this.app, required this.m});

  @override
  Widget build(BuildContext context) {
    final p = m.progress(app.save).clamp(0, m.target);
    final claimed = m.claimed(app.save);
    return Card(
      child: ListTile(
        title: Text(missionTitle(app, m)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(value: p / m.target),
          const SizedBox(height: 4),
          Text('$p / ${m.target}   +${m.coins} 🪙${m.gems > 0 ? '  +${m.gems} 💎' : ''}'),
        ]),
        trailing: claimed
            ? const Icon(Icons.check_circle, color: Colors.green)
            : FilledButton(
                onPressed: m.done(app.save)
                    ? () {
                        final r = app.session.claimMission(m);
                        if (r != null) {
                          app.changed(saveNow: true);
                          _rewardDialog(context, app, r);
                        }
                      }
                    : null,
                child: Text(app.t('claim')),
              ),
      ),
    );
  }
}

class _Wheel extends StatelessWidget {
  final AppState app;
  const _Wheel({required this.app});

  @override
  Widget build(BuildContext context) {
    final now = app.session.now();
    final available = app.session.daily.wheelAvailable(app.save, now);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.redeem, color: Colors.orange, size: 36),
        title: RewardChips(reward: app.session.daily.todaysGift(now)),
        trailing: FilledButton(
          onPressed: available
              ? () {
                  final r = app.spinWheel();
                  if (r != null) _rewardDialog(context, app, r);
                }
              : null,
          child: Text(available ? app.t('spin') : app.t('claimed')),
        ),
      ),
    );
  }
}
