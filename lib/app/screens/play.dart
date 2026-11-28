import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/daily.dart';
import '../../core/game_rules.dart';
import '../../core/game_session.dart';
import '../../core/level_plan.dart';
import '../../core/net_texts.dart';
import '../../core/telemetry.dart';
import '../adaptive.dart';
import '../app_state.dart';
import '../services/gen_runner_stub.dart' if (dart.library.io) '../services/gen_runner_io.dart';
import '../game_api.dart';
import '../parental_gate.dart';
import '../services/audio.dart';
import '../services/portal.dart';
import '../studio_ui.dart';
import '../theme.dart';
import '../widgets.dart';
import 'tutorial.dart';

/// Hosts one round of the game: generation, HUD frame, pause, boosters,
/// continue offers, results and rewards.
class PlayScreen extends ConsumerStatefulWidget {
  final LevelSpec spec;
  final bool resume;

  /// Aynı cihazda oynayan kişi sayısı (0/1: tek kişi).
  final int players;

  /// Çevrimiçi maç bağlantısı.
  final MatchLink? match;

  /// Dışarıdan açılan tek el (Günün Bulmacası, Aile Turnuvası): sonuç
  /// ekranı yerine el bitince [RoundResult] ile kapanır; vazgeçilirse null.
  final bool external;

  /// Çevrimiçi maç: sonuç ekranındaki "Rövanş" (yoksa düğme gösterilmez;
  /// çevrimiçi maçta "Tekrar" hiç gösterilmez, masa yerelde yeniden başlamaz).
  final Future<void> Function()? onRematch;

  /// Çevrimiçi maç: sonuç ekranında gösterilecek rövanş daveti ("Ada rövanş istiyor").
  final ValueListenable<String>? rematchNote;
  const PlayScreen(
      {super.key,
      required this.spec,
      this.resume = false,
      this.players = 0,
      this.match,
      this.external = false,
      this.onRematch,
      this.rematchNote});

  @override
  ConsumerState<PlayScreen> createState() => _PlayScreenState();
}

class _PlayScreenState extends ConsumerState<PlayScreen> {
  GeneratedLevel? _level;
  Object? _error;
  int _roundKey = 0;
  bool _finished = false;
  late LevelSpec _spec = widget.spec;

  /// Bölüm hazır olduğundan beri geçen süre (günlük sıralama için).
  final Stopwatch _clock = Stopwatch();

  @override
  void initState() {
    super.initState();
    Portal.gameplayStart();
    _generate();
  }

  @override
  void dispose() {
    Portal.gameplayStop();
    super.dispose();
  }

  Future<void> _generate() async {
    await Future<void>.delayed(const Duration(milliseconds: 16));
    final app = ref.read(appStateProvider);
    try {
      final g = await runBuild(app.config.rules, _spec);
      if (!mounted) return;
      setState(() => _level = g);
      _clock
        ..reset()
        ..start();
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
        backgroundColor: StudioLook.of(context).base,
        // Üst çubuk saydam; oyun alanının zemini (dünya teması) arkasına uzanır.
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: StudioTitle(_title),
          leading: Padding(
            padding: const EdgeInsetsDirectional.only(start: 6),
            child: IconButton(
              tooltip: app.t('pause'),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.30),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.pause_rounded),
              onPressed: () => _pause(app),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 10),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                StudioStatChip(
                  icon: Icons.lightbulb_rounded,
                  color: const Color(0xFFFFA53A),
                  compact: true,
                  semanticLabel: '${app.t('hints')} ${app.save.hints}',
                  text: app.session.premiumHintsLeft > 0
                      ? '${app.save.hints}+${app.session.premiumHintsLeft}'
                      : '${app.save.hints}',
                ),
                const SizedBox(width: 6),
                StudioStatChip(
                  icon: Icons.monetization_on_rounded,
                  color: StudioLook.gold,
                  compact: true,
                  semanticLabel: '${app.t('coins')} ${app.save.coins}',
                  text: compactNumber(app.save.coins),
                ),
              ]),
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
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          StudioButton(
              expand: false, icon: Icons.exit_to_app_rounded, label: app.t('quit'), onPressed: () => Navigator.pop(context)),
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
      // Çok kişili oyunlar yarıda kalırsa devam kaydı tutulmaz.
      saveResume: (s) {
        if (widget.players <= 1 && widget.match == null) app.saveResume(level.spec, s);
      },
      seats: widget.match != null
          ? [for (var i = 0; i < widget.match!.names.length; i++) i == widget.match!.mySeat ? SeatRole.local : (widget.match!.names[i].isEmpty ? SeatRole.ai : SeatRole.remote)]
          : widget.players > 1
              ? List.filled(widget.players, SeatRole.local)
              : const [],
      match: widget.match,
      requestHint: () => _requestHint(app),
      requestBooster: () => _requestBooster(app),
      requestContinue: () => _requestContinue(app),
      sfx: (s) => app.audio.play(s),
      sound: (n) => app.audio.playNamed(n),
    );
    // Oyun alanı (tahta) kendi alıştığı temayla çizilir: motorların tahta
    // görünümü değişmez. Ortak parçalar (üst bilgi hapları, güçlendirici
    // çubuğu) onaylı paleti tema uzantısından okur.
    final board = buildTheme(app.config.seedColor, MediaQuery.platformBrightnessOf(context))
        .copyWith(extensions: [StudioLook.of(context)]);
    // Oyun alanı renkleri hafifçe yumuşatılır: göz yormayan, sakin bir görünüm.
    return KeyedSubtree(
      key: ValueKey(_roundKey),
      child: Theme(
        data: board,
        child: ColorFiltered(colorFilter: kCalmColors, child: app.config.buildPlay(ctx)),
      ),
    );
  }

  // ---- Pause -------------------------------------------------------------------
  Future<void> _pause(AppState app) async {
    await app.flushSave();
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ContentWidth(
            maxWidth: 520,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              StudioSheetTitle(app.t('pause'), icon: Icons.pause_circle_rounded),
              StudioButton.hot(label: app.t('resume'), onPressed: () => Navigator.pop(c, 'resume')),
              const SizedBox(height: 10),
              // Çevrimiçi maçta baştan başlatma yok: masa herkes için aynı sürer
              // (yeniden başlatan cihaz masadan ayrışıyordu).
              if (widget.match == null)
                StudioMenuRow(
                    icon: Icons.refresh_rounded,
                    color: const Color(0xFF2F7BD9),
                    label: app.t('restart'),
                    onTap: () => Navigator.pop(c, 'restart')),
              StudioMenuRow(
                  icon: Icons.help_outline_rounded,
                  color: const Color(0xFF7B4FD6),
                  label: app.t('how_to_play'),
                  onTap: () => Navigator.pop(c, 'help')),
              StudioMenuRow(
                icon: app.save.sound ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: const Color(0xFF2E9E78),
                label: app.t('sound'),
                trailing: Switch(
                  value: app.save.sound,
                  onChanged: (v) {
                    app.updateSettings((s) => s.sound = v);
                    Navigator.pop(c, 'resume');
                  },
                ),
              ),
              StudioMenuRow(
                  icon: Icons.exit_to_app_rounded,
                  color: const Color(0xFFE0533D),
                  label: app.t('quit'),
                  onTap: () => Navigator.pop(c, 'quit')),
            ]),
          ),
        ),
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
        if (widget.match != null && !await _confirmLeave(app)) break;
        if (mounted) Navigator.pop(context);
        break;
      default:
        break;
    }
  }

  /// Çevrimiçi maçtan çıkış onayı (çıkan yenik sayılır, yerine bot oynar).
  Future<bool> _confirmLeave(AppState app) async {
    final lang = app.strings.lang;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const ValueKey('leave-match-dialog'),
        icon: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFE0533D), size: 36),
        title: Text(netLeaveTitle(lang)),
        content: Text(netLeaveBody(lang)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('cancel'))),
          FilledButton(
              key: const ValueKey('leave-match-yes'),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE0533D)),
              onPressed: () => Navigator.pop(c, true),
              child: Text(netLeaveYes(lang))),
        ],
      ),
    );
    return ok == true;
  }

  // ---- Boosters ------------------------------------------------------------------
  Future<bool> _requestHint(AppState app) async {
    if (await app.useHint()) return true;
    if (!mounted) return false;
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.lightbulb_rounded, color: Color(0xFFFFA53A), size: 40),
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
      // Çocuk oyununda reklam yalnız yetişkin onayıyla (ebeveyn kapısı).
      if (!mounted) return false;
      if (!await parentalGate(context, app)) return false;
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
        icon: const Icon(Icons.favorite_rounded, color: StudioLook.bad, size: 40),
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
    if (choice == 'ad') {
      // Çocuk oyununda reklam yalnız yetişkin onayıyla (ebeveyn kapısı).
      if (!mounted) return false;
      if (!await parentalGate(context, app)) return false;
      return app.watchRewarded();
    }
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
    Portal.gameplayStop();
    _clock.stop();
    final out = app.finishRound(_spec, r, elapsedMs: _clock.elapsedMilliseconds);
    if (!mounted) return;
    if (widget.external) {
      // Süreyi bildirmeyen oyunlarda kabuğun ölçtüğü süre kullanılır.
      Navigator.pop(
          context,
          r.seconds > 0
              ? r
              : RoundResult(
                  won: r.won,
                  score: r.score,
                  stars: r.stars,
                  seconds: (_clock.elapsedMilliseconds / 1000).ceil(),
                  moves: r.moves,
                  hintsUsed: r.hintsUsed,
                  undosUsed: r.undosUsed,
                  gameStats: r.gameStats,
                  headline: r.headline,
                  winnerSeat: r.winnerSeat,
                ));
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      showDragHandle: false,
      builder: (c) => _ResultSheet(
          app: app,
          result: r,
          outcome: out,
          spec: _spec,
          online: widget.match != null,
          rematch: widget.onRematch != null,
          rematchNote: widget.rematchNote),
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
      case 'rematch':
        await widget.onRematch?.call();
        break;
      case 'retry':
        if (widget.match != null) {
          Navigator.pop(context);
          break;
        }
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
  final bool online, rematch;
  final ValueListenable<String>? rematchNote;
  const _ResultSheet(
      {required this.app,
      required this.result,
      required this.outcome,
      required this.spec,
      this.online = false,
      this.rematch = false,
      this.rematchNote});

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
    final look = StudioLook.of(context);
    final title = r.headline ?? (r.won ? app.t('win_title') : app.t('lose_title'));
    return Stack(children: [
      // Üstte kazanınca altın, kaybedince kırmızı hafif bir hale.
      Positioned.fill(
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -1.1),
                radius: 1.0,
                colors: [(r.won ? StudioLook.gold : StudioLook.bad).withValues(alpha: 0.22), Colors.transparent],
              ),
            ),
          ),
        ),
      ),
      SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
          child: ContentWidth(
            maxWidth: 560,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              StudioSheetTitle(title,
                  icon: r.won ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded,
                  iconColor: r.won ? StudioLook.gold : StudioLook.bad),
              if (r.won && r.headline == null) StarRow(stars: r.stars, size: 52),
              if (r.score > 0)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.30),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: look.accent.withValues(alpha: 0.55)),
                  ),
                  child: Text('${app.t('score')}: ${r.score}',
                      style: TextStyle(color: look.number, fontSize: 22, fontWeight: FontWeight.w900)),
                ),
              if (o.newRecord)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(app.t('new_record'),
                      style: const TextStyle(color: Color(0xFFFFA53A), fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              const SizedBox(height: 14),
              RewardChips(
                  reward:
                      o.reward + Reward(xp: r.won ? 0 : o.xpGained) + (_doubled ? Reward(coins: o.reward.coins) : const Reward())),
              if (_doubled)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('x2', style: TextStyle(color: StudioLook.good, fontWeight: FontWeight.w900, fontSize: 18)),
                ),
              if (o.leveledUp)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(app.t('level_up', {'n': o.playerLevelAfter}),
                      style: const TextStyle(fontWeight: FontWeight.w900, color: StudioLook.good)),
                ),
              const SizedBox(height: 6),
              for (final a in o.achievements.take(3))
                StudioMenuRow(
                  icon: Icons.emoji_events_rounded,
                  color: const Color(0xFFD9A21C),
                  label: app.t('achievement_unlocked'),
                  subtitle: achievementTitle(app, a.titleKey, a.params, a.id),
                ),
              if (o.items.isNotEmpty)
                StudioMenuRow(
                  icon: Icons.card_giftcard_rounded,
                  color: const Color(0xFF9763BC),
                  label: app.t('item_unlocked'),
                  subtitle: '${o.items.length}',
                ),
              const SizedBox(height: 10),
              if (r.won && !_doubled && o.reward.coins > 0 && app.ads.available)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: StudioButton(
                    tone: StudioButtonTone.gold,
                    icon: Icons.ondemand_video_rounded,
                    label: app.t('double_reward'),
                    onPressed: () async {
                      // Çocuk oyununda reklam yalnız yetişkin onayıyla (ebeveyn kapısı).
                      if (!await parentalGate(context, app)) return;
                      final ok = await app.watchRewarded();
                      if (!context.mounted) return;
                      if (ok) {
                        Reward(coins: o.reward.coins).applyTo(app.save);
                        app.audio.play(Sfx.coin);
                        app.changed(saveNow: true);
                        setState(() => _doubled = true);
                      } else {
                        ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(
                            content: Text(app.strings.lang == 'tr'
                                ? 'Ödül alınamadı: reklam sonuna kadar izlenmedi ya da şu an hazır değil.'
                                : 'No reward: the ad was not finished or is not ready yet.')));
                      }
                    },
                  ),
                ),
              if (campaign && r.won) ...[
                StudioButton.hot(
                  icon: Icons.skip_next_rounded,
                  label: app.t('next'),
                  onPressed: () => Navigator.pop(context, 'next'),
                ),
                const SizedBox(height: 10),
              ],
              if (widget.rematchNote != null)
                ValueListenableBuilder<String>(
                  valueListenable: widget.rematchNote!,
                  builder: (_, v, __) => v.isEmpty
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(v,
                              key: const ValueKey('rematch-note'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFFFFD166), fontWeight: FontWeight.w800)),
                        ),
                ),
              Row(children: [
                Expanded(
                  child: StudioButton(
                    tone: StudioButtonTone.ghost,
                    icon: Icons.home_rounded,
                    label: app.t('home'),
                    onPressed: () => Navigator.pop(context, 'home'),
                  ),
                ),
                if (!widget.online || widget.rematch) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: widget.online
                        ? StudioButton(
                            key: const ValueKey('rematch'),
                            tone: StudioButtonTone.play,
                            icon: Icons.replay_rounded,
                            label: netRematch(app.strings.lang),
                            onPressed: () => Navigator.pop(context, 'rematch'),
                          )
                        : StudioButton(
                            tone: campaign && r.won ? StudioButtonTone.ghost : StudioButtonTone.play,
                            icon: Icons.replay_rounded,
                            label: app.t('retry'),
                            onPressed: () => Navigator.pop(context, 'retry'),
                          ),
                  ),
                ],
              ]),
            ]),
          ),
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
        ? gs.first.name(app.strings.lang)
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

/// Doygunluğu %15 azaltan renk süzgeci (renk ayrımı korunur, parlaklık yumuşar).
const ColorFilter kCalmColors = ColorFilter.matrix(<double>[
  0.8819, 0.1073, 0.0108, 0, 0, //
  0.0319, 0.9573, 0.0108, 0, 0, //
  0.0319, 0.1073, 0.8608, 0, 0, //
  0, 0, 0, 1, 0,
]);
