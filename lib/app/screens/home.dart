import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../online/online_service.dart';
import '../../online/online_ui.dart';

import '../../core/level_plan.dart';
import '../../core/save_store.dart';
import '../adaptive.dart';
import '../covers.dart';
import '../app_state.dart';
import '../theme.dart';
import '../widgets.dart';
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
    final pending = app.pendingOnline;
    if (pending != null) {
      app.pendingOnline = null;
      pending(context);
    }
    if (!app.hubManaged) {
      unawaited(OnlineHost.attach(context, app.strings, (_) => app.title, (gameId, action) async {
        if (gameId != app.config.gameId || !mounted) return false;
        await action(context, app);
        return true;
      }));
    }
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
      (const Icon(Icons.person), app.t('profile')),
    ];
    return Scaffold(
      appBar: AppBar(
        leading: app.exitToHub == null
            ? null
            : IconButton(
                tooltip: app.exitToHubLabel,
                icon: const Icon(Icons.apps_rounded),
                onPressed: app.exitToHub,
              ),
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
                child: ContentWidth(maxWidth: Adaptive.readableWidth + 120, child: pages[_tab]),
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

  /// Aynı masada birden çok kişinin oynadığı oyun (rakip yapay zekâ ya da
  /// çevrimiçi masa). Aynı cihazda sırayla oynama sunulmaz.
  bool get _multi => app.config.rules.localPlayers >= 2;

  Future<void> _online(BuildContext context) async {
    if (!Online.instance.available) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          icon: const Icon(Icons.wifi_off_rounded),
          title: Text(app.t('online_table')),
          content: Text(app.t('online_needs_net')),
          actions: [FilledButton(onPressed: () => Navigator.pop(c), child: Text(app.t('ok')))],
        ),
      );
      return;
    }
    await openOnline(context, app);
  }

  @override
  Widget build(BuildContext context) {
    final s = app.save;
    final spec = app.session.nextCampaignSpec;
    final theme = Palettes.theme(spec.theme);
    final seed = app.config.seedColor;
    final modes = app.config.rules.modes
        .where((m) => m != GameModeId.campaign && m != GameModeId.practice && m != GameModeId.versus && m != GameModeId.online)
        .toList();
    final resume = s.resume['spec'] is Map;
    final text = Theme.of(context).textTheme;
    final hero = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(seed, theme.last, 0.35)!, Color.lerp(seed, theme.first, 0.55)!],
        ),
        boxShadow: [BoxShadow(color: seed.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(children: [
        Row(children: [
          app.cover != null
              ? CoverArt(cover: app.cover!, color: seed, size: 96, radius: 22)
              : Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(22)),
                  child: Icon(app.config.icon, size: 56, color: Colors.white),
                ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.22), borderRadius: BorderRadius.circular(20)),
                child: Text(
                    _multi
                        ? app.t('stage_n', {'n': spec.levelId})
                        : '${app.t('world', {'n': spec.world})} · ${app.t('level', {'n': spec.levelId})}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56), backgroundColor: Colors.white, foregroundColor: Color.lerp(seed, Colors.black, 0.3)),
            icon: Icon(resume ? Icons.play_circle : (_multi ? Icons.smart_toy_rounded : Icons.play_arrow_rounded)),
            label: Text(resume ? app.t('resume') : (_multi ? app.t('play_ai') : app.t('play')),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            onPressed: () => resume ? openResume(context, app) : openPlay(context, app, spec),
          ),
        ),
        if (_multi) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const ValueKey('online-table'),
              style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFFFFC857),
                  foregroundColor: const Color(0xFF2A1E05)),
              icon: const Icon(Icons.groups_rounded),
              label: Text(app.t('online_table'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              onPressed: () => _online(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(app.t('online_table_d'),
                textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
          ),
        ],
        TextButton.icon(
          icon: const Icon(Icons.map_rounded, color: Colors.white),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelsScreen())),
          label: Text(app.t('worlds'), style: const TextStyle(color: Colors.white)),
        ),
      ]),
    );
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        hero,
        if (Online.instance.available)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.leaderboard),
              label: Text(app.t('leaderboards')),
              onPressed: () async {
                if (!await Online.instance.start()) {
                  if (context.mounted) showToast(context, app.t('online_unavailable'));
                  return;
                }
                if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(app: app)));
              },
            ),
          ),
        if (modes.isNotEmpty) SectionTitle(app.t('other_modes')),
        GridView(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: Adaptive.columns(MediaQuery.sizeOf(context).width, minTile: 200, max: 4).clamp(2, 4),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 104,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: modes.map((m) => _ModeCard(app: app, mode: m)).toList(),
        ),
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
        GameModeId.versus => Icons.people_alt,
        GameModeId.online => Icons.public,
        _ => Icons.play_arrow,
      };

  Color get tint => switch (mode) {
        GameModeId.endless => const Color(0xFF7B4FD6),
        GameModeId.timeAttack => const Color(0xFFE0533D),
        GameModeId.zen => const Color(0xFF2E9E78),
        GameModeId.daily => const Color(0xFF2F7BD9),
        GameModeId.weekly => const Color(0xFFD9822B),
        GameModeId.challenge => const Color(0xFFC23D7A),
        _ => const Color(0xFF3C6E8F),
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
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(color: tint.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: tint, size: 22),
              ),
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
    case GameModeId.versus:
      openVersus(context, app);
      break;
    case GameModeId.online:
      openOnline(context, app);
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

/// Aynı cihazda çok kişili oyun: kişi sayısını sorar (2'den fazlası
/// mümkünse), sonra maçı açar. Kalan koltuklara yapay zekâ oturur.
Future<void> openVersus(BuildContext context, AppState app) async {
  final max = app.config.rules.localPlayers;
  var n = 2;
  if (max > 2) {
    final picked = await showDialog<int>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(app.t('choose_players')),
        children: [
          for (var i = 2; i <= max; i++)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(c, i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(app.t('players_n', {'n': i}), style: const TextStyle(fontSize: 18)),
              ),
            ),
        ],
      ),
    );
    if (picked == null) return;
    n = picked;
  }
  if (!context.mounted) return;
  final run = app.save.stat('run_versus') + 1;
  app.save.stats['run_versus'] = run;
  final spec = app.session.planner.run(GameModeId.versus, run, difficulty: 4);
  Navigator.push(context, MaterialPageRoute(builder: (_) => PlayScreen(spec: spec, players: n)));
}
