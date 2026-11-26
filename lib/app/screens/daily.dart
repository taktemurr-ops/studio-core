import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/daily.dart';
import '../../core/level_plan.dart';
import '../../core/missions.dart';
import '../app_state.dart';
import '../studio_ui.dart';
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
    final look = StudioLook.of(context);
    final loginReady = d.loginRewardAvailable(s, now);
    final goal = d.weeklyGoal(s);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // ---- Login calendar ----
        SectionTitle(app.t('daily_login'), icon: Icons.local_fire_department_rounded, iconColor: const Color(0xFFFF8A1F)),
        StudioPanel(
          margin: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(app.t('streak', {'n': s.loginStreak}),
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: DailySystems.loginCycle.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (c, i) {
                  final cyclePos = (s.loginStreak - 1) % DailySystems.loginCycle.length;
                  final isToday = i == cyclePos;
                  final r = DailySystems.loginCycle[i];
                  return Container(
                    width: 70,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: isToday ? look.playGradient : look.tile,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isToday ? Colors.white.withValues(alpha: 0.85) : look.accent.withValues(alpha: 0.45),
                          width: isToday ? 2 : 1.2),
                      boxShadow: isToday ? [BoxShadow(color: look.play.withValues(alpha: 0.5), blurRadius: 12)] : null,
                    ),
                    // scaleDown: the tile never overflows, whatever the font scale.
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(app.t('day_n', {'n': i + 1}),
                            style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                        Icon(r.gems > 0 ? Icons.diamond_rounded : Icons.monetization_on_rounded,
                            color: r.gems > 0 ? StudioLook.gem : StudioLook.gold, size: 28),
                        Text('${r.coins}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            StudioButton(
              tone: loginReady ? StudioButtonTone.gold : StudioButtonTone.ghost,
              icon: loginReady ? Icons.redeem_rounded : Icons.check_rounded,
              label: loginReady ? app.t('claim') : app.t('claimed'),
              onPressed: loginReady
                  ? () {
                      final r = app.claimLogin();
                      if (r != null) _rewardDialog(context, app, r);
                    }
                  : null,
            ),
          ]),
        ),

        // ---- Daily gift & surprise ----
        SectionTitle(app.t('wheel'), icon: Icons.redeem_rounded, iconColor: const Color(0xFFFF5FB4)),
        _Wheel(app: app),
        SectionTitle(app.t('surprise'), icon: Icons.card_giftcard_rounded, iconColor: const Color(0xFFB98CFF)),
        StudioPanel(
          margin: EdgeInsets.zero,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const StudioIconBadge(Icons.card_giftcard_rounded, color: Color(0xFF9763BC), size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(app.t('surprise'),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(s.lastSurpriseDay == today ? app.t('claimed') : app.t('surprise_hint'),
                      style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 13)),
                ]),
              ),
            ]),
            const SizedBox(height: 10),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: d.surpriseAvailable(s, now)
                    ? () {
                        final r = app.claimSurprise();
                        if (r != null) _rewardDialog(context, app, r);
                      }
                    : null,
                child: Text(app.t('claim')),
              ),
            ),
          ]),
        ),

        // ---- Special levels ----
        SectionTitle(app.t('mode_daily'), icon: Icons.event_available_rounded),
        StudioMenuRow(
          icon: Icons.today_rounded,
          color: const Color(0xFF2F7BD9),
          label: app.t('mode_daily'),
          subtitle: app.t('mode_daily_d'),
          trailing: s.dailyLevelDoneDay == today
              ? const Icon(Icons.check_circle_rounded, color: StudioLook.good, size: 30)
              : Icon(Icons.play_circle_fill_rounded, color: look.play, size: 34),
          onTap: () => openMode(context, app, GameModeId.daily),
        ),
        StudioMenuRow(
          icon: Icons.date_range_rounded,
          color: const Color(0xFFD9822B),
          label: app.t('mode_weekly'),
          subtitle: app.t('mode_weekly_d'),
          trailing: s.weeklyLevelDoneWeek == s.weeklyKey
              ? const Icon(Icons.check_circle_rounded, color: StudioLook.good, size: 30)
              : Icon(Icons.play_circle_fill_rounded, color: look.play, size: 34),
          onTap: () => openMode(context, app, GameModeId.weekly),
        ),
        StudioPanel(
          margin: const EdgeInsets.only(top: 4),
          child: Row(children: [
            Icon(Icons.bar_chart_rounded, color: look.accent, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(app.t('weekly_goal', {'a': d.weeklyGoalProgress(s), 'b': goal}),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                Text(app.t('daily_record', {'n': s.dailyRecordDay == today ? s.dailyRecord : 0}),
                    style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 13)),
                const SizedBox(height: 8),
                StudioBar(value: goal == 0 ? 0 : d.weeklyGoalProgress(s) / goal),
              ]),
            ),
          ]),
        ),

        // ---- Missions ----
        SectionTitle(app.t('daily_missions'), icon: Icons.flag_rounded, iconColor: StudioLook.gold),
        for (final m in app.session.dailyMissions) _MissionTile(app: app, m: m),
        SectionTitle(app.t('weekly_missions'), icon: Icons.emoji_events_rounded, iconColor: StudioLook.gold),
        for (final m in app.session.weeklyMissions) _MissionTile(app: app, m: m),
      ],
    );
  }
}

void _rewardDialog(BuildContext context, AppState app, Reward r) {
  showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.redeem_rounded, color: StudioLook.gold, size: 44),
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
    return StudioPanel(
      margin: const EdgeInsets.symmetric(vertical: 4),
      borderColor: claimed ? StudioLook.good.withValues(alpha: 0.7) : null,
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(missionTitle(app, m), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            StudioBar(value: m.target == 0 ? 0 : p / m.target, color: claimed ? StudioLook.good : null),
            const SizedBox(height: 6),
            Text('$p / ${m.target}   +${m.coins} 🪙${m.gems > 0 ? '  +${m.gems} 💎' : ''}',
                style: const TextStyle(color: Color(0xFFD9DCF0), fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
        ),
        const SizedBox(width: 10),
        claimed
            ? const Icon(Icons.check_circle_rounded, color: StudioLook.good, size: 32)
            : FilledButton(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14), minimumSize: const Size(48, 48)),
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
      ]),
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
    return StudioPanel(
      margin: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.redeem_rounded, color: Color(0xFFFF5FB4), size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: RewardChips(reward: app.session.daily.todaysGift(now)),
            ),
          ),
        ]),
        const SizedBox(height: 10),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: FilledButton(
            onPressed: available
                ? () {
                    final r = app.spinWheel();
                    if (r != null) _rewardDialog(context, app, r);
                  }
                : null,
            child: Text(available ? app.t('spin') : app.t('claimed')),
          ),
        ),
      ]),
    );
  }
}
