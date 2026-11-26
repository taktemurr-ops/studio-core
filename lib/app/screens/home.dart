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
import '../studio_ui.dart';
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
    final look = StudioLook.of(context);
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
    final dailyBadge = app.session.daily.loginRewardAvailable(app.save, app.session.now()) ||
        app.session.daily.wheelAvailable(app.save, app.session.now());
    final items = [
      StudioNavItem(Icons.home_rounded, app.t('home')),
      StudioNavItem(Icons.calendar_today_rounded, app.t('daily'), badge: dailyBadge),
      StudioNavItem(Icons.person_outline_rounded, app.t('profile')),
    ];
    return Scaffold(
      backgroundColor: look.base,
      body: StudioBackdrop(
        child: SafeArea(
          bottom: false,
          child: Row(children: [
            // Tablets, foldables, desktop and web: side navigation rail.
            if (wide)
              NavigationRail(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                labelType: NavigationRailLabelType.all,
                destinations: [
                  for (final d in items)
                    NavigationRailDestination(
                      icon: Badge(isLabelVisible: d.badge, smallSize: 9, child: Icon(d.icon)),
                      label: Text(d.label),
                    ),
                ],
              ),
            Expanded(
              child: Column(children: [
                _topBar(app),
                ContentWidth.wide(child: CurrencyBar(app: app)),
                Expanded(
                  child: ContentWidth(maxWidth: Adaptive.readableWidth + 120, child: pages[_tab]),
                ),
              ]),
            ),
          ]),
        ),
      ),
      // Phones: bottom navigation bar.
      bottomNavigationBar: wide
          ? null
          : StudioNavBar(items: items, selected: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }

  /// Merkezin üst çubuğu: merkeze dönüş · oyunun kapağı ve adı · taç (mağaza) · ayarlar.
  Widget _topBar(AppState app) {
    final cover = app.cover;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(children: [
        if (app.exitToHub != null)
          IconButton(
            tooltip: app.exitToHubLabel,
            icon: const Icon(Icons.apps_rounded, size: 28),
            onPressed: app.exitToHub,
          )
        else
          const SizedBox(width: 48),
        Expanded(
          child: Center(
            child: StudioTitle(
              app.title,
              icon: app.config.icon,
              art: cover == null ? null : CoverArt(cover: cover, color: app.config.seedColor, size: 30, radius: 8),
            ),
          ),
        ),
        IconButton(
          tooltip: app.t('shop'),
          icon: const StudioCrown(),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
        ),
        IconButton(
          tooltip: app.t('settings'),
          icon: const Icon(Icons.settings_rounded),
          onPressed: () {
            app.openedScreen('settings_opened');
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
        ),
      ]),
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

  Widget _art(double size) {
    final seed = app.config.seedColor;
    final cover = app.cover;
    if (cover != null) return CoverArt(cover: cover, color: seed, size: size, radius: size * 0.18);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.18),
        gradient: LinearGradient(colors: [seed, Color.lerp(seed, Colors.black, 0.35)!]),
      ),
      child: Icon(app.config.icon, size: size * 0.55, color: Colors.white),
    );
  }

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    final s = app.save;
    final spec = app.session.nextCampaignSpec;
    final modes = app.config.rules.modes
        .where((m) => m != GameModeId.campaign && m != GameModeId.practice && m != GameModeId.versus && m != GameModeId.online)
        .toList();
    final resume = s.resume['spec'] is Map;
    const heroShadow = [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))];
    final hero = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [
            Color.lerp(look.card, app.config.seedColor, 0.25)!,
            Color.lerp(look.card, Colors.black, 0.45)!,
          ],
        ),
        border: Border.all(color: look.accent.withValues(alpha: 0.55), width: 1.4),
        boxShadow: [BoxShadow(color: look.accent.withValues(alpha: 0.25), blurRadius: 16)],
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
      child: Column(children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(app.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: look.number,
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      shadows: heroShadow)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Text(
                    _multi
                        ? app.t('stage_n', {'n': spec.levelId})
                        : '${app.t('world', {'n': spec.world})} · ${app.t('level', {'n': spec.levelId})}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: [BoxShadow(color: look.accent.withValues(alpha: 0.35), blurRadius: 18)],
              ),
              child: _art(104),
            ),
          ),
        ]),
        const SizedBox(height: 16),
        StudioButton.hot(
          icon: resume ? Icons.play_circle_rounded : (_multi ? Icons.smart_toy_rounded : Icons.play_arrow_rounded),
          label: resume ? app.t('resume') : (_multi ? app.t('play_ai') : app.t('play')),
          onPressed: () => resume ? openResume(context, app) : openPlay(context, app, spec),
        ),
        if (_multi) ...[
          const SizedBox(height: 10),
          StudioButton(
            key: const ValueKey('online-table'),
            tone: StudioButtonTone.gold,
            icon: Icons.groups_rounded,
            label: app.t('online_table'),
            onPressed: () => _online(context),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(app.t('online_table_d'),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13)),
          ),
        ],
        TextButton.icon(
          icon: const Icon(Icons.map_rounded),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LevelsScreen())),
          label: Text('${app.t('worlds')} ›'),
        ),
      ]),
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        hero,
        if (Online.instance.available)
          StudioPanel(
            margin: const EdgeInsets.only(top: 12),
            semanticLabel: app.t('leaderboards'),
            onTap: () async {
              if (!await Online.instance.start()) {
                if (context.mounted) showToast(context, app.t('online_unavailable'));
                return;
              }
              if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(app: app)));
            },
            child: Row(children: [
              const Icon(Icons.leaderboard_rounded, color: StudioLook.gold, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(app.t('leaderboards'),
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 28),
            ]),
          ),
        if (modes.isNotEmpty)
          StudioSectionHeader(
            icon: Icons.star_rounded,
            iconColor: StudioLook.gold,
            title: app.t('other_modes'),
            padding: const EdgeInsets.fromLTRB(2, 18, 2, 8),
          ),
        LayoutBuilder(builder: (context, c) {
          final cols = (c.maxWidth / 140).floor().clamp(3, 6);
          final w = (c.maxWidth - (cols - 1) * 10) / cols;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final m in modes)
              SizedBox(width: w, height: w * 1.55, child: _ModeCard(app: app, mode: m, art: _art)),
          ]);
        }),
      ],
    );
  }
}

/// Oyunun kendi kapağıyla mod kartı (merkezdeki oyun kutusu biçiminde).
class _ModeCard extends StatelessWidget {
  final AppState app;
  final GameModeId mode;
  final Widget Function(double size) art;
  const _ModeCard({required this.app, required this.mode, required this.art});

  IconData get icon => switch (mode) {
        GameModeId.endless => Icons.all_inclusive_rounded,
        GameModeId.timeAttack => Icons.timer_rounded,
        GameModeId.zen => Icons.spa_rounded,
        GameModeId.daily => Icons.today_rounded,
        GameModeId.weekly => Icons.date_range_rounded,
        GameModeId.challenge => Icons.military_tech_rounded,
        GameModeId.versus => Icons.people_alt_rounded,
        GameModeId.online => Icons.public_rounded,
        _ => Icons.play_arrow_rounded,
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
    final look = StudioLook.of(context);
    final best = app.save.records[mode.name];
    final title = app.t('mode_${mode.name}');
    final sub = best != null && best > 0 ? '${app.t('best')}: $best' : app.t('mode_${mode.name}_d');
    final r = BorderRadius.circular(18);
    return Semantics(
      button: true,
      label: '$title. $sub',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: InkWell(
          borderRadius: r,
          onTap: () => openMode(context, app, mode),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: r,
              gradient: look.tile,
              border: Border.all(color: look.accent.withValues(alpha: 0.55), width: 1.4),
              boxShadow: [BoxShadow(color: look.accent.withValues(alpha: 0.22), blurRadius: 10)],
            ),
            child: LayoutBuilder(builder: (context, c) {
              final a = c.maxWidth - 12;
              return Padding(
                padding: const EdgeInsets.all(6),
                child: Column(children: [
                  SizedBox(
                    width: a,
                    height: a,
                    child: Stack(children: [
                      art(a),
                      // Modun rengi kapağın altına süzülür; köşede mod simgesi.
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(a * 0.18),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [tint.withValues(alpha: 0), tint.withValues(alpha: 0.75)],
                              stops: const [0.45, 1],
                            ),
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        start: 4,
                        bottom: 4,
                        child: StudioIconBadge(icon, color: tint, size: (a * 0.34).clamp(26.0, 44.0)),
                      ),
                      if (best != null && best > 0)
                        PositionedDirectional(
                          end: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(10)),
                            child: Text('★ $best',
                                style: const TextStyle(
                                    color: StudioLook.gold, fontSize: 11, fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ]),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13, height: 1.1, fontWeight: FontWeight.w800)),
                    ),
                  ),
                  Container(
                    width: a * 0.6,
                    height: 26,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), gradient: look.playGradient),
                    child: Icon(Icons.play_arrow_rounded, color: look.onPlay, size: 22),
                  ),
                ]),
              );
            }),
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
                child: Row(children: [
                  StudioIconBadge(Icons.people_alt_rounded, color: StudioLook.of(c).play, size: 34),
                  const SizedBox(width: 12),
                  Text(app.t('players_n', {'n': i}),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
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
