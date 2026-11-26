/// Günün Bulmacası ekranları: oyun içi kart, merkez sayfası, sonuç penceresi
/// (seri + spoiler'sız paylaşım metni) ve günün çevrimiçi sıralaması.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_rules.dart';
import '../core/global_daily.dart';
import '../core/level_plan.dart';
import '../core/play_texts.dart';
import '../core/save_store.dart';
import '../core/strings.dart';
import '../online/online.dart';
import '../online/online_service.dart';
import '../online/online_ui.dart' show avatarOf;
import 'adaptive.dart';
import 'app_state.dart';
import 'game_api.dart';
import 'screens/play.dart';
import 'studio_look.dart';
import 'studio_ui.dart';
import 'widgets.dart';

/// Oyunu dışarıdan tek el oynatır (sonuç ekranı yok). Vazgeçilirse null.
typedef ExternalPlay = Future<RoundResult?> Function(AppState state, LevelSpec spec, int players);

/// Varsayılan [ExternalPlay]: oyun ekranını bulunulan gezginde açar.
Future<RoundResult?> playExternal(BuildContext context, AppState state, LevelSpec spec, [int players = 0]) {
  return Navigator.push<RoundResult>(
    context,
    MaterialPageRoute<RoundResult>(
      builder: (_) => ProviderScope(
        overrides: [appStateProvider.overrideWith((ref) => state)],
        child: PlayScreen(spec: spec, players: players, external: true),
      ),
    ),
  );
}

/// Bugünün bulmacasını oynatır; sonuç kaydedildiyse günün (ilk) sonucunu döndürür.
Future<DailyEntry?> playGlobalDaily(AppState app, ExternalPlay play) async {
  final spec = app.startGlobalDaily();
  final day = app.globalDailyDay!;
  app.pendingDaily = null;
  final r = await play(app, spec, 0);
  app.globalDailyDay = null;
  final pending = app.pendingDaily;
  if (r == null || pending == null) return null;
  await pending;
  return app.dailyStore.result(app.config.gameId, day);
}

String _metric(DailyEntry e, String lang) => e.rank == DailyRank.time
    ? '⏱ ${GlobalDaily.clock(e.ms)}${e.moves > 0 ? ' · ${playTx('gd_moves', lang)} ${e.moves}' : ''}'
    : '${playTx('gd_score', lang)} ${e.score} · ⏱ ${GlobalDaily.clock(e.ms)}';

String _countdown(String lang) {
  final d = GlobalDaily.untilNext(DateTime.now());
  final h = d.inHours, m = d.inMinutes % 60;
  return playTx('gd_next', lang, {'t': '$h:${m.toString().padLeft(2, '0')}'});
}

/// Sonuç penceresi: süre/hamle, seri, paylaş, sıralama.
Future<void> showDailyResult(BuildContext context,
    {required AppState app, required DailyEntry e, required String lang, required String gameTitle}) async {
  final store = app.dailyStore;
  final today = e.day;
  final streak = store.streak(today);
  final text = GlobalDaily.shareText(
    title: playTx('gd_title', lang),
    gameTitle: gameTitle,
    e: e,
    lastWeek: store.lastDays(today),
    streak: streak,
  );
  final online = !app.config.kidsMode && Online.instance.available;
  await showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.emoji_events_rounded, color: StudioLook.gold, size: 48),
      title: Text('${playTx('gd_title', lang)} #${GlobalDaily.number(today)}', textAlign: TextAlign.center),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(gameTitle, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          Text(_metric(e, lang), textAlign: TextAlign.center, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          Text('🔥 ${playTx('gd_streak', lang, {'n': streak})} · ${playTx('gd_best', lang, {'n': store.best})}',
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          SelectableText(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.4)),
          if (online && !e.synced) ...[
            const SizedBox(height: 10),
            Text(playTx('gd_offline', lang), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12.5)),
          ],
          const SizedBox(height: 6),
          Text(playTx('gd_first', lang), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
        ]),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        FilledButton.icon(
          key: const ValueKey('gd-share'),
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(playTx('gd_share', lang)),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: text));
            if (c.mounted) showToast(c, playTx('gd_copied', lang));
          },
        ),
        if (online)
          OutlinedButton.icon(
            icon: const Icon(Icons.leaderboard_rounded),
            label: Text(playTx('gd_board', lang)),
            onPressed: () {
              Navigator.pop(c);
              unawaited(openDailyBoard(context, app: app, lang: lang, gameTitle: gameTitle, day: today));
            },
          ),
        TextButton(onPressed: () => Navigator.pop(c), child: Text(Strings(lang).t('ok'))),
      ],
    ),
  );
}

/// Günün sıralamasını açar (gerekirse anonim çevrimiçi oturum açılır).
Future<void> openDailyBoard(BuildContext context,
    {required AppState app, required String lang, required String gameTitle, String? day}) async {
  if (app.config.kidsMode) return;
  if (!await Online.instance.start()) {
    if (context.mounted) showToast(context, Strings(lang).t('online_unavailable'));
    return;
  }
  unawaited(Online.instance.syncDaily(app.dailyStore));
  final d = day ?? GlobalDaily.utcDay(DateTime.now());
  final rules = app.config.rules;
  final board = GlobalDaily.board(app.config.gameId, d, lang: rules.dailyPerLanguage ? app.strings.lang : '');
  if (!context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => DailyBoardPage(board: board, title: gameTitle, lang: lang, day: d, rank: rules.dailyRank),
    ),
  );
}

/// Günün sıralaması (ilk 50).
class DailyBoardPage extends StatefulWidget {
  final String board, title, lang, day;
  final DailyRank rank;
  const DailyBoardPage(
      {super.key, required this.board, required this.title, required this.lang, required this.day, required this.rank});

  @override
  State<DailyBoardPage> createState() => _DailyBoardPageState();
}

class _DailyBoardPageState extends State<DailyBoardPage> {
  List<DailyScore>? _rows;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = Online.instance.backend;
    if (b == null) {
      setState(() => _failed = true);
      return;
    }
    try {
      final r = await b.dailyTop(widget.board).timeout(const Duration(seconds: 15));
      if (mounted) setState(() => _rows = r);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final me = Online.instance.profile?.uid;
    final rows = _rows;
    final myIndex = rows == null ? -1 : rows.indexWhere((r) => r.uid == me);
    return StudioScaffold(
      title: playTx('gd_board', lang),
      icon: Icons.leaderboard_rounded,
      body: ContentWidth(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
            StudioPanel(
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('${widget.title} · #${GlobalDaily.number(widget.day)}',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                if (myIndex >= 0)
                  Text(playTx('gd_rank', lang, {'n': myIndex + 1}),
                      style: const TextStyle(color: StudioLook.gold, fontWeight: FontWeight.w800)),
                Text(_countdown(lang), style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 13)),
              ]),
            ),
            if (rows == null && !_failed)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_failed)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(Strings(lang).t('online_unavailable'), textAlign: TextAlign.center),
              )
            else if (rows!.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(playTx('gd_empty', lang), textAlign: TextAlign.center),
              )
            else
              for (var i = 0; i < rows.length; i++)
                StudioPanel(
                  margin: const EdgeInsets.symmetric(vertical: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  borderColor: rows[i].uid == me ? StudioLook.gold : null,
                  child: Row(children: [
                    SizedBox(
                      width: 34,
                      child: Text(i < 3 ? const ['🥇', '🥈', '🥉'][i] : '${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                    Text(avatarOf(rows[i].avatar), style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(rows[i].uid == me ? '${rows[i].name} (${playTx('gd_you', lang)})' : rows[i].name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      rows[i].mode == 's'
                          ? '${rows[i].score}'
                          : '${GlobalDaily.clock(rows[i].ms)}${rows[i].moves > 0 ? ' · ${rows[i].moves}' : ''}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ]),
                ),
          ]),
        ),
      ),
    );
  }
}

/// Oyun içi Günlük sekmesindeki kart (oyun katılıyorsa).
class GlobalDailyCard extends StatefulWidget {
  final AppState app;
  const GlobalDailyCard({super.key, required this.app});

  @override
  State<GlobalDailyCard> createState() => _GlobalDailyCardState();
}

class _GlobalDailyCardState extends State<GlobalDailyCard> {
  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    unawaited(app.dailyStore.load().then((_) {
      if (mounted) setState(() {});
      if (!app.config.kidsMode) {
        unawaited(Online.instance.resumeSession().then((ok) async {
          if (ok) await Online.instance.syncDaily(app.dailyStore);
        }));
      }
    }));
  }

  Future<void> _play() async {
    final e = await playGlobalDaily(app, (st, spec, n) => playExternal(context, st, spec, n));
    if (!mounted) return;
    setState(() {});
    if (e != null) await showDailyResult(context, app: app, e: e, lang: app.strings.lang, gameTitle: app.title);
  }

  @override
  Widget build(BuildContext context) {
    final lang = app.strings.lang;
    final store = app.dailyStore;
    final today = GlobalDaily.utcDay(DateTime.now());
    final e = store.result(app.config.gameId, today);
    final look = StudioLook.of(context);
    return StudioPanel(
      key: const ValueKey('global-daily-card'),
      margin: const EdgeInsets.only(bottom: 6),
      gradient: LinearGradient(colors: [look.card, Color.lerp(look.card, look.play, 0.35)!]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const StudioIconBadge(Icons.public_rounded, color: Color(0xFF2F9E8F), size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${playTx('gd_title', lang)} #${GlobalDaily.number(today)}',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
              Text(e == null ? playTx('gd_body', lang) : '${playTx('gd_done', lang)} · ${_metric(e, lang)}',
                  style: const TextStyle(color: Color(0xFFD9DCF0), fontSize: 13)),
              Text('🔥 ${playTx('gd_streak', lang, {'n': store.streak(today)})} · ${_countdown(lang)}',
                  style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 12.5)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        StudioButton(
          icon: e == null ? Icons.play_arrow_rounded : Icons.replay_rounded,
          label: e == null ? playTx('gd_play', lang) : playTx('gd_again', lang),
          tone: e == null ? StudioButtonTone.play : StudioButtonTone.ghost,
          height: 46,
          fontSize: 15,
          onPressed: _play,
        ),
        if (e != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(playTx('gd_share', lang)),
                onPressed: () => showDailyResult(context, app: app, e: e, lang: lang, gameTitle: app.title),
              ),
            ),
            if (!app.config.kidsMode && Online.instance.available)
              Expanded(
                child: TextButton.icon(
                  icon: const Icon(Icons.leaderboard_rounded),
                  label: Text(playTx('gd_board', lang)),
                  onPressed: () => openDailyBoard(context, app: app, lang: lang, gameTitle: app.title, day: today),
                ),
              ),
          ]),
        ],
      ]),
    );
  }
}

/// Merkezin Günün Bulmacası sayfası: katılan bütün oyunlar, günün seçkisi,
/// ortak seri. Oyunlar [stateFor] ile açılır, [play] ile oynatılır.
class GlobalDailyHubPage extends StatefulWidget {
  final List<GameConfig> games;
  final Future<AppState> Function(GameConfig g) stateFor;
  final ExternalPlay play;
  final KeyValueBackend backend;
  final String lang;
  final String Function(GameConfig g) titleOf;
  final Widget Function(GameConfig g, double size)? art;
  const GlobalDailyHubPage({
    super.key,
    required this.games,
    required this.stateFor,
    required this.play,
    required this.backend,
    required this.lang,
    required this.titleOf,
    this.art,
  });

  /// Merkezdeki katılan oyunlar.
  static List<GameConfig> eligible(Iterable<GameConfig> games) =>
      [for (final g in games) if (g.rules.globalDaily && !g.kidsMode) g];

  @override
  State<GlobalDailyHubPage> createState() => _GlobalDailyHubPageState();
}

class _GlobalDailyHubPageState extends State<GlobalDailyHubPage> {
  GlobalDailyStore get store => GlobalDailyStore.of(widget.backend);
  Timer? _tick;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(store.load().then((_) {
      if (mounted) setState(() {});
    }));
    unawaited(Online.instance.resumeSession().then((ok) async {
      if (ok) await Online.instance.syncDaily(store);
    }));
    _tick = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Future<void> _play(GameConfig g) async {
    if (_busy) return;
    _busy = true;
    try {
      final st = await widget.stateFor(g);
      final e = await playGlobalDaily(st, widget.play);
      if (!mounted) return;
      setState(() {});
      if (e != null) await showDailyResult(context, app: st, e: e, lang: widget.lang, gameTitle: widget.titleOf(g));
    } finally {
      _busy = false;
    }
  }

  Future<void> _board(GameConfig g) async {
    final st = await widget.stateFor(g);
    if (!mounted) return;
    await openDailyBoard(context, app: st, lang: widget.lang, gameTitle: widget.titleOf(g));
  }

  Widget _status(GameConfig g, String today) {
    final e = store.result(g.gameId, today);
    if (e == null) return Icon(Icons.play_circle_fill_rounded, color: StudioLook.of(context).play, size: 34);
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      const Icon(Icons.check_circle_rounded, color: StudioLook.good, size: 26),
      Text(e.rank == DailyRank.time ? GlobalDaily.clock(e.ms) : '${e.score}',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
      if (!e.synced && Online.instance.available)
        Text(playTx('gd_pending', widget.lang), style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 10)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final today = GlobalDaily.utcDay(DateTime.now());
    final games = widget.games;
    final featId = GlobalDaily.featured(games.map((g) => g.gameId), today);
    final feat = games.where((g) => g.gameId == featId).firstOrNull;
    final look = StudioLook.of(context);
    return StudioScaffold(
      title: playTx('gd_title', lang),
      icon: Icons.public_rounded,
      body: ContentWidth(
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
          StudioPanel(
            margin: const EdgeInsets.only(bottom: 8),
            gradient: LinearGradient(colors: [look.card, Color.lerp(look.card, look.play, 0.4)!]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('#${GlobalDaily.number(today)} · ${playTx('gd_body', lang)}',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, children: [
                StudioStatChip(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF8A1F),
                    text: playTx('gd_streak', lang, {'n': store.streak(today)})),
                StudioStatChip(
                    icon: Icons.emoji_events_rounded, color: StudioLook.gold, text: playTx('gd_best', lang, {'n': store.best})),
                StudioStatChip(
                    icon: Icons.task_alt_rounded,
                    color: StudioLook.good,
                    text: playTx('gd_count', lang, {'n': store.solvedOn(today)})),
              ]),
              const SizedBox(height: 6),
              Text(_countdown(lang), style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 13)),
            ]),
          ),
          if (feat != null) ...[
            StudioSectionHeader(
                icon: Icons.star_rounded, iconColor: StudioLook.gold, title: playTx('gd_pick', lang), padding: EdgeInsets.zero),
            StudioPanel(
              key: const ValueKey('gd-featured'),
              margin: const EdgeInsets.symmetric(vertical: 6),
              onTap: () => _play(feat),
              child: Row(children: [
                if (widget.art != null) ClipRRect(borderRadius: BorderRadius.circular(14), child: widget.art!(feat, 64)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(widget.titleOf(feat),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                ),
                _status(feat, today),
              ]),
            ),
          ],
          StudioSectionHeader(
              icon: Icons.grid_view_rounded, title: playTx('gd_all', lang), padding: const EdgeInsets.only(top: 8)),
          for (final g in games)
            StudioPanel(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onTap: () => _play(g),
              child: Row(children: [
                if (widget.art != null)
                  ClipRRect(borderRadius: BorderRadius.circular(10), child: widget.art!(g, 42))
                else
                  StudioIconBadge(g.icon, color: g.seedColor, size: 42),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.titleOf(g),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                if (Online.instance.available)
                  IconButton(
                    tooltip: playTx('gd_board', lang),
                    icon: const Icon(Icons.leaderboard_rounded, color: Colors.white70),
                    onPressed: () => _board(g),
                  ),
                _status(g, today),
              ]),
            ),
        ]),
      ),
    );
  }
}
