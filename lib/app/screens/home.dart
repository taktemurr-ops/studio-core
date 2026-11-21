import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/level_plan.dart';
import '../../core/save_store.dart';
import '../adaptive.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
import 'achievements.dart';
import 'collection.dart';
import 'daily.dart';
import 'levels.dart';
import 'play.dart';
import 'profile.dart';
import 'settings.dart';
import 'shop.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  bool _shownStartup = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shownStartup) {
      _shownStartup = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startupMessages());
    }
  }

  void _startupMessages() {
    final app = ref.read(appStateProvider);
    final r = app.startup;
    if (r == null || !mounted) return;
    if (r.safeMode) showToast(context, app.t('safe_mode'));
    if (r.loadOutcome == LoadOutcome.recoveredFromBackup) {
      showToast(context, app.t('save_recovered'));
    }
    if (r.comeback != null) {
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(app.t('welcome_back')),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(app.t('welcome_back_d')),
            const SizedBox(height: 12),
            RewardChips(reward: r.comeback!),
          ]),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(app.t('ok')))],
        ),
      );
    } else if (r.loginRewardReady) {
      setState(() => _tab = 1);
    }
    app.startup = null;
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final toast = app.takeToast();
    if (toast != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showToast(context, toast);
      });
    }
    final pages = [
      _HomeTab(app: app),
      const DailyScreen(),
      const CollectionScreen(),
      const AchievementsScreen(),
      const ProfileScreen(),
    ];
    final wide = Adaptive.of(context) == FormFactor.expanded;
    final dests = <(Widget, String)>[
      (const Icon(Icons.home), app.t('home')),
      (
        Badge(
          isLabelVisible: app.session.daily.loginRewardAvailable(app.save, app.session.now()) ||
              app.session.daily.wheelAvailable(app.save, app.session.now()),
          child: const Icon(Icons.calendar_today),
        ),
        app.t('daily')
      ),
      (const Icon(Icons.collections), app.t('collection')),
      (const Icon(Icons.emoji_events), app.t('achievements')),
      (const Icon(Icons.person), app.t('profile')),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(app.title),
        actions: [
          IconButton(
            tooltip: app.t('shop'),
            icon: const Icon(Icons.storefront),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
          ),
          IconButton(
            tooltip: app.t('settings'),
            icon: const Icon(Icons.settings),
            onPressed: () {
              app.openedScreen('settings_opened');
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Row(children: [
          // Tablets, foldables, desktop and web: side navigation rail.
          if (wide)
            NavigationRail(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in dests)
                  NavigationRailDestination(icon: d.$1, label: Text(d.$2)),
              ],
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(
            child: Column(children: [
              ContentWidth.wide(child: CurrencyBar(app: app)),
              Expanded(
                child: _tab == 2 ? pages[_tab] : ContentWidth(maxWidth: Adaptive.readableWidth + 120, child: pages[_tab]),
              ),
            ]),
          ),
        ]),
      ),
      // Phones: bottom navigation bar.
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) => setState(() => _tab = i),
              destinations: [
                for (final d in dests) NavigationDestination(icon: d.$1, label: d.$2),
              ],
            ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final AppState app;
  const _HomeTab({required this.app});

  @override
  Widget build(BuildContext context) {
    final s = app.save;
    final spec = app.session.nextCampaignSpec;
    final theme = Palettes.theme(spec.theme);
    final modes = app.config.rules.modes
        .where((m) => m != GameModeId.campaign && m != GameModeId.practice)
        .toList();
    final resume = s.resume['spec'] is Map;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ThemedBackground(
          colors: theme,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Icon(app.config.icon, size: 72, color: Colors.white),
              const SizedBox(height: 8),
              Text(app.t('world', {'n': spec.world}),
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              Text(app.t('level', {'n': spec.levelId}),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    minimumSize: const Size(220, 56), backgroundColor: Colors.white, foregroundColor: theme.first),
                icon: Icon(resume ? Icons.play_circle : Icons.play_arrow),
                label: Text(resume ? app.t('resume') : app.t('play'), style: const TextStyle(fontSize: 20)),
                onPressed: () => resume ? openResume(context, app) : openPlay(context, app, spec),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelsScreen())),
                child: Text(app.t('worlds'), style: const TextStyle(color: Colors.white)),
              ),
            ]),
          ),
        ),
        SectionTitle(app.t('modes')),
        // Fixed tile height (not an aspect ratio): narrow phones and wide
        // tablets get the same readable card, and it can never overflow.
        GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Adaptive.columns(MediaQuery.sizeOf(context).width, minTile: 200, max: 4).clamp(2, 4),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 116,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: modes.map((m) => _ModeCard(app: app, mode: m)).toList(),
        ),
        const SizedBox(height: 12),
        Text(app.t('endless_unlocked_hint'),
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ModeCard extends StatelessWidget {
  final AppState app;
  final GameModeId mode;
  const _ModeCard({required this.app, required this.mode});

  IconData get icon => switch (mode) {
        GameModeId.endless => Icons.all_inclusive,
        GameModeId.timeAttack => Icons.timer,
        GameModeId.zen => Icons.spa,
        GameModeId.daily => Icons.today,
        GameModeId.weekly => Icons.date_range,
        GameModeId.challenge => Icons.military_tech,
        _ => Icons.play_arrow,
      };

  @override
  Widget build(BuildContext context) {
    final best = app.save.records[mode.name];
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => openMode(context, app, mode),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              // Flexible texts shrink (ellipsis) instead of overflowing with
              // large system font sizes or very narrow cards.
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.t('mode_${mode.name}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Flexible(
                      child: Text(
                        best != null && best > 0 ? '${app.t('best')}: $best' : app.t('mode_${mode.name}_d'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void openMode(BuildContext context, AppState app, GameModeId mode) {
  final p = app.session.planner;
  switch (mode) {
    case GameModeId.daily:
      openPlay(context, app, p.daily(app.dayKey()));
      break;
    case GameModeId.weekly:
      openPlay(context, app, p.weekly(app.save.weeklyKey));
      break;
    case GameModeId.challenge:
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ChallengesScreen()));
      break;
    default:
      final run = app.save.stat('run_${mode.name}') + 1;
      app.save.stats['run_${mode.name}'] = run;
      openPlay(context, app, p.run(mode, run, difficulty: (3 + app.session.playerLevel ~/ 40).clamp(3, 8)));
  }
}

void openPlay(BuildContext context, AppState app, LevelSpec spec) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => PlayScreen(spec: spec)));
}

void openResume(BuildContext context, AppState app) {
  final j = app.save.resume['spec'];
  if (j is! Map) return;
  final level = (j['level_id'] as num?)?.toInt() ?? app.save.currentLevel;
  final modeName = j['mode'] as String? ?? 'campaign';
  final mode = GameModeId.values.firstWhere((m) => m.name == modeName, orElse: () => GameModeId.campaign);
  final p = app.session.planner;
  LevelSpec spec;
  switch (mode) {
    case GameModeId.campaign:
      spec = app.session.campaignSpec(level);
      final d = (j['difficulty'] as num?)?.toInt();
      if (d != null) spec = spec.copyWith(difficulty: d);
      break;
    case GameModeId.daily:
      spec = p.daily(app.dayKey());
      break;
    case GameModeId.weekly:
      spec = p.weekly(app.save.weeklyKey);
      break;
    case GameModeId.challenge:
      spec = p.challenge(level);
      break;
    default:
      spec = p.run(mode, level, difficulty: (j['difficulty'] as num?)?.toInt() ?? 4);
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => PlayScreen(spec: spec, resume: true)));
}
