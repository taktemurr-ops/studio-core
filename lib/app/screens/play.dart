import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/daily.dart';
import '../../core/game_rules.dart';
import '../../core/game_session.dart';
import '../../core/level_plan.dart';
import '../../core/telemetry.dart';
import '../app_state.dart';
import '../game_api.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tutorial.dart';

/// Hosts one round of the game: generation, HUD frame, pause, boosters,
/// continue offers, results and rewards.
class PlayScreen extends ConsumerStatefulWidget {
  final LevelSpec spec;
  final bool resume;
  const PlayScreen({super.key, required this.spec, this.resume = false});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  GeneratedLevel? _level;
  Object? _error;
  int _roundKey = 0;
  bool _finished = false;
  late LevelSpec _spec = widget.spec;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final app = ref.read(appStateProvider);
    try {
      final g = app.config.rules.build(_spec);
      if (!mounted) return;
      setState(() => _level = g);
      if (_spec.levelId == 1 && _spec.mode == GameModeId.campaign && app.save.stat('tutorial_seen') == 0) {
        app.save.stats['tutorial_seen'] = 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) showTutorial(context, app);
        });
      }
    } catch (e) {
      await app.errors.record(ErrorCategory.levelGen, e);
      if (mounted) setState(() => _error = e);
    }
  }

  String get _title {
    final app = ref.read(appStateProvider);
    switch (_spec.mode) {
      case GameModeId.campaign:
        return app.t('level', {'n': _spec.levelId});
      case GameModeId.challenge:
        return app.t('challenge_n', {'n': _spec.levelId});
      default:
        return app.t('mode_${_spec.mode.name}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final colors = Palettes.theme(_spec.mode == GameModeId.campaign
        ? _spec.theme
        : Palettes.themeIndex(app.save.activeTheme));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pause(app);
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text(_title),
          leading: IconButton(
            tooltip: app.t('pause'),
            icon: const Icon(Icons.pause_circle),
            onPressed: () => _pause(app),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Row(children: [
                  const Icon(Icons.lightbulb, color: Colors.orange, size: 18),
                  Text(' ${app.save.hints}  '),
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  Text(' ${compactNumber(app.save.coins)}'),
                ]),
              ),
            ),
          ],
        ),
        body: ThemedBackground(
          colors: colors,
          child: SafeArea(child: _body(app)),
        ),
      ),
    );
  }

  Widget _body(AppState app) {
    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, color: Colors.white, size: 48),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(app.t('quit'))),
        ]),
      );
    }
    final level = _level;
    if (level == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    final resumeState = widget.resume && _roundKey == 0 ? app.save.resume['state'] : null;
    final ctx = PlayContext(
      spec: level.spec,
      generated: level,
      resume: resumeState is Map ? Map<String, Object?>.from(resumeState) : const {},
      pieceColors: Palettes.skin(Palettes.themeIndex(app.save.activeSkin)),
      background: Palettes.theme(level.spec.theme),
      colorBlind: app.save.colorBlindMode,
      reducedMotion: app.save.reducedMotion,
      leftHanded: app.save.leftHanded,
      lang: app.strings.lang,
      t: app.t,
      finish: (r) => _finish(app, r),
      saveResume: (s) => app.saveResume(level.spec, s),
      requestHint: () => _requestHint(app),
      requestBooster: () => _requestBooster(app),
      requestContinue: () => _requestContinue(app),
      sfx: (s) => app.audio.play(s),
      sound: (n) => app.audio.playNamed(n),
    );
    return KeyedSubtree(key: ValueKey(_roundKey), child: app.config.buildPlay(ctx));
  }

  // ---- Pause -------------------------------------------------------------------
  Future<void> _pause(AppState app) async {
    await app.flushSave();
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.play_arrow), title: Text(app.t('resume')), onTap: () => Navigator.pop(c, 'resume')),
          ListTile(leading: const Icon(Icons.refresh), title: Text(app.t('restart')), onTap: () => Navigator.pop(c, 'restart')),
          ListTile(leading: const Icon(Icons.help_outline), title: Text(app.t('how_to_play')), onTap: () => Navigator.pop(c, 'help')),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: Text(app.t('sound')),
            value: app.save.sound,
            onChanged: (v) {
              app.updateSettings((s) => s.sound = v);
              Navigator.pop(c, 'resume');
            },
          ),
          ListTile(leading: const Icon(Icons.exit_to_app), title: Text(app.t('quit')), onTap: () => Navigator.pop(c, 'quit')),
        ]),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'restart':
        app.clearResume();
        setState(() => _roundKey++);
        break;
      case 'help':
        showTutorial(context, app);
        break;
      case 'quit':
        Navigator.pop(context);
        break;
      default:
        break;
    }
  }

  // ---- Boosters ------------------------------------------------------------------
  Future<bool> _requestHint(AppState app) async {
    if (await app.useHint()) return true;
    if (!mounted) return false;
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(app.t('no_hints')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(app.t('cancel'))),
          if (app.ads.available) TextButton(onPressed: () => Navigator.pop(c, 'ad'), child: Text(app.t('free_hint_ad'))),
          FilledButton(
            onPressed: app.save.coins >= 100 ? () => Navigator.pop(c, 'coins') : null,
            child: const Text('100 🪙'),
          ),
        ],
      ),
    );
    if (choice == 'ad') {
      final ok = await app.watchRewarded();
      if (!ok && mounted) showToast(context, app.t('ad_not_ready'));
      return ok;
    }
    if (choice == 'coins' && app.session.spendCoins(100)) {
      app.changed();
      return true;
    }
    return false;
  }

  Future<bool> _requestBooster(AppState app) async {
    if (app.session.spendBooster()) {
      app.changed();
      return true;
    }
    if (app.session.spendCoins(150)) {
      app.changed();
      return true;
    }
    if (mounted) showToast(context, '150 🪙');
    return false;
  }

  Future<bool> _requestContinue(AppState app) async {
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(app.t('lose_title')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text(app.t('quit'))),
          if (app.ads.available) TextButton(onPressed: () => Navigator.pop(c, 'ad'), child: Text(app.t('continue_ad'))),
          FilledButton(
            onPressed: app.save.coins >= 200 ? () => Navigator.pop(c, 'coins') : null,
            child: Text(app.t('continue_coins', {'n': 200})),
          ),
        ],
      ),
    );
    if (choice == 'ad') return app.watchRewarded();
    if (choice == 'coins' && app.session.spendCoins(200)) {
      app.changed();
      return true;
    }
    return false;
  }

  // ---- Results ---------------------------------------------------------------------
  Future<void> _finish(AppState app, RoundResult r) async {
    if (_finished) return;
    _finished = true;
    final out = app.finishRound(_spec, r);
    if (!mounted) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (c) => _ResultSheet(app: app, result: r, outcome: out, spec: _spec),
    );
    if (!mounted) return;
    await app.maybeInterstitial(out);
    if (!mounted) return;
    switch (action) {
      case 'next':
        setState(() {
          _spec = app.session.nextCampaignSpec;
          _level = null;
          _finished = false;
          _roundKey++;
        });
        _generate();
        break;
      case 'retry':
        setState(() {
          _finished = false;
          _roundKey++;
        });
        break;
      default:
        Navigator.pop(context);
    }
  }
}

class _ResultSheet extends StatefulWidget {
  final AppState app;
  final RoundResult result;
  final LevelOutcome outcome;
  final LevelSpec spec;
  const _ResultSheet({required this.app, required this.result, required this.outcome, required this.spec});

  @override
  State<_ResultSheet> createState() => _ResultSheetState();
}

class _ResultSheetState extends State<_ResultSheet> {
  bool _doubled = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final r = widget.result;
    final o = widget.outcome;
    final campaign = widget.spec.mode == GameModeId.campaign;
    return Stack(children: [
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(r.won ? app.t('win_title') : app.t('lose_title'),
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            if (r.won) StarRow(stars: r.stars, size: 44),
            if (r.score > 0) Text('${app.t('score')}: ${r.score}', style: Theme.of(context).textTheme.titleLarge),
            if (o.newRecord) Text(app.t('new_record'), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            RewardChips(reward: o.reward + Reward(xp: r.won ? 0 : o.xpGained)),
            if (o.leveledUp)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(app.t('level_up', {'n': o.playerLevelAfter}),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ),
            for (final a in o.achievements.take(3))
              ListTile(
                dense: true,
                leading: const Icon(Icons.emoji_events, color: Colors.amber),
                title: Text(app.t('achievement_unlocked')),
                subtitle: Text(achievementTitle(app, a.titleKey, a.params, a.id)),
              ),
            if (o.items.isNotEmpty)
              ListTile(
                dense: true,
                leading: const Icon(Icons.card_giftcard, color: Colors.purple),
                title: Text(app.t('item_unlocked')),
                subtitle: Text('${o.items.length}'),
              ),
            const SizedBox(height: 12),
            if (r.won && !_doubled && o.reward.coins > 0 && app.ads.available)
              OutlinedButton.icon(
                icon: const Icon(Icons.ondemand_video),
                label: Text(app.t('double_reward')),
                onPressed: () async {
                  final ok = await app.watchRewarded();
                  if (ok) {
                    Reward(coins: o.reward.coins).applyTo(app.save);
                    app.audio.play(Sfx.coin);
                    app.changed(saveNow: true);
                    setState(() => _doubled = true);
                  }
                },
              ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'home'),
                  child: Text(app.t('home')),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, 'retry'),
                  child: Text(app.t('retry')),
                ),
              ),
              if (campaign && r.won) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, 'next'),
                    child: Text(app.t('next')),
                  ),
                ),
              ],
            ]),
          ]),
        ),
      ),
      if (r.won) Positioned.fill(child: Confetti(enabled: !app.save.reducedMotion)),
    ]);
  }
}

String achievementTitle(AppState app, String key, Map<String, String> params, String id) {
  final p = <String, Object>{...params};
  final stat = params['stat'];
  if (stat != null) {
    final gs = app.config.rules.gameStats.where((g) => g.key == stat);
    p['stat'] = gs.isNotEmpty
        ? (app.strings.lang == 'tr' ? gs.first.nameTr : gs.first.nameEn)
        : statLabel(app, stat);
  }
  final text = app.t(key, p);
  if (text == key && key.startsWith('secret_')) {
    final words = key.substring(7).split('_');
    return words.map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
  }
  return text;
}

String statLabel(AppState app, String stat) {
  const map = {
    'stars_earned': 'stars_total',
    'levels_won': 'levels_done',
    'coins_earned': 'coins',
    'three_stars': 'mission_three',
    'no_hint_wins': 'mission_nohint',
    'daily_levels': 'mode_daily',
    'weekly_levels': 'mode_weekly',
    'challenges_won': 'mode_challenge',
    'endless_runs': 'mode_endless',
    'time_attack_runs': 'mode_timeAttack',
    'missions_done': 'daily_missions',
    'fast_wins': 'mission_fast',
  };
  final k = map[stat];
  if (k == null) return stat;
  return app.t(k, {'n': ''}).replaceAll(RegExp(r'\s+'), ' ').trim();
}
