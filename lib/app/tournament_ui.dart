/// Aile Turnuvası ekranı: kurulum (2–8 oyuncu, oyunlar, tur sayısı),
/// cihazı sıradakine verme, puan tablosu ve şampiyon töreni. Yalnızca bu
/// cihazda: çevrimiçi bağlantı, reklam ya da kişisel bilgi yok.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/play_texts.dart';
import '../core/save_store.dart';
import '../core/tournament.dart';
import 'adaptive.dart';
import 'app_state.dart';
import 'game_api.dart';
import 'global_daily_ui.dart' show ExternalPlay;
import 'studio_look.dart';
import 'studio_ui.dart';
import 'widgets.dart';

class TournamentPage extends StatefulWidget {
  final List<GameConfig> games;
  final Future<AppState> Function(GameConfig g) stateFor;
  final ExternalPlay play;
  final KeyValueBackend backend;
  final String lang;
  final String Function(GameConfig g) titleOf;
  final Widget Function(GameConfig g, double size)? art;
  const TournamentPage({
    super.key,
    required this.games,
    required this.stateFor,
    required this.play,
    required this.backend,
    required this.lang,
    required this.titleOf,
    this.art,
  });

  static const storageKey = 'tourney.v1';

  @override
  State<TournamentPage> createState() => _TournamentPageState();
}

class _TournamentPageState extends State<TournamentPage> {
  Tournament? _t;
  Tournament? _saved;
  bool _loaded = false;
  bool _busy = false;
  final List<TPlayer> _players = [];
  final List<TextEditingController> _names = [];
  final Set<String> _picked = {};
  int _rounds = 1;

  String get lang => widget.lang;
  String tx(String k, [Map<String, Object> p = const {}]) => playTx(k, lang, p);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 2; i++) {
      _addPlayer();
    }
    unawaited(_load());
  }

  @override
  void dispose() {
    for (final c in _names) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final raw = await widget.backend.read(TournamentPage.storageKey);
      if (raw != null && raw.isNotEmpty) {
        final t = Tournament.fromJson(jsonDecode(raw));
        if (t != null && !t.finished && t.games.every((g) => _game(g.gameId) != null)) _saved = t;
      }
    } catch (_) {}
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save() async {
    final t = _t;
    try {
      if (t == null || t.finished) {
        await widget.backend.remove(TournamentPage.storageKey);
      } else {
        await widget.backend.write(TournamentPage.storageKey, jsonEncode(t.toJson()));
      }
    } catch (_) {}
  }

  GameConfig? _game(String id) {
    for (final g in widget.games) {
      if (g.gameId == id) return g;
    }
    return null;
  }

  void _addPlayer() {
    if (_players.length >= Tournament.maxPlayers) return;
    final used = _players.map((p) => p.avatar).toSet();
    var a = 0;
    while (used.contains(a) && a < kTournamentAvatars.length - 1) {
      a++;
    }
    _players.add(TPlayer('', a));
    _names.add(TextEditingController(text: tx('tn_player_n', {'n': _players.length})));
  }

  void _removePlayer(int i) {
    if (_players.length <= Tournament.minPlayers) return;
    _players.removeAt(i);
    _names.removeAt(i).dispose();
  }

  void _start() {
    final players = [
      for (var i = 0; i < _players.length; i++)
        TPlayer(TPlayer.clean(_names[i].text).isEmpty ? tx('tn_player_n', {'n': i + 1}) : TPlayer.clean(_names[i].text),
            _players[i].avatar)
    ];
    final games = [
      for (final g in widget.games)
        if (_picked.contains(g.gameId)) TGame(g.gameId, g.rules.localPlayers)
    ];
    final t = Tournament(
        seed: DateTime.now().millisecondsSinceEpoch & 0x3fffffff, players: players, games: games, rounds: _rounds);
    if (!t.valid) {
      showToast(context, tx('tn_need'));
      return;
    }
    setState(() => _t = t);
    unawaited(_save());
  }

  // ---- Oynatma --------------------------------------------------------------

  Future<void> _playNext() async {
    final t = _t;
    final m = t?.match;
    if (t == null || m == null || _busy) return;
    final g = _game(t.games[m.game].gameId);
    if (g == null) return;
    _busy = true;
    try {
      final st = await widget.stateFor(g);
      final spec = t.specFor(m);
      if (t.game!.together) {
        final r = await widget.play(st, spec, m.players.length);
        if (!mounted) return;
        var winner = -2;
        if (r != null && r.winnerSeat == -1) winner = -1;
        if (r != null && r.winnerSeat >= 0 && r.winnerSeat < m.players.length) winner = m.players[r.winnerSeat];
        if (winner == -2) winner = await _askWinner(m.players, r?.headline);
        if (!mounted) return;
        setState(() => t.submitTogether(winner));
      } else {
        final r = await widget.play(st, spec, 0);
        if (!mounted) return;
        setState(() => t.submitTurn(r == null
            ? const TScore.gaveUp()
            : TScore(won: r.won, score: r.score, ms: r.seconds * 1000)));
      }
      await _save();
    } finally {
      _busy = false;
    }
  }

  Future<int> _askWinner(List<int> seats, String? headline) async {
    final t = _t!;
    final w = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: Text(tx('tn_who')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (headline != null && headline.isNotEmpty)
              Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(headline, textAlign: TextAlign.center)),
            for (var s = 0; s < seats.length; s++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: FilledButton.tonal(
                  onPressed: () => Navigator.pop(c, seats[s]),
                  child: Text('${tx('tn_player_n', {'n': s + 1})}: ${t.players[seats[s]].icon} ${t.players[seats[s]].name}'),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: OutlinedButton(onPressed: () => Navigator.pop(c, -1), child: Text(tx('tn_draw'))),
            ),
          ]),
        ),
      ),
    );
    return w ?? -1;
  }

  // ---- Görünüm -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return StudioScaffold(
      title: tx('tn_title'),
      icon: Icons.emoji_events_rounded,
      body: ContentWidth(
        child: !_loaded
            ? const Center(child: CircularProgressIndicator())
            : t == null
                ? _setup()
                : t.finished
                    ? _ceremony(t)
                    : _run(t),
      ),
    );
  }

  Widget _setup() {
    final valid = _players.length >= Tournament.minPlayers && _picked.isNotEmpty;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      StudioPanel(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tx('tn_body'), style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(tx('tn_rules'), style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 13)),
        ]),
      ),
      if (_saved != null)
        StudioMenuRow(
          key: const ValueKey('tn-resume'),
          icon: Icons.play_circle_fill_rounded,
          color: const Color(0xFF2F9E8F),
          label: tx('tn_resume'),
          subtitle: _saved!.players.map((p) => '${p.icon} ${p.name}').join('  '),
          onTap: () => setState(() {
            _t = _saved;
            _saved = null;
          }),
        ),
      StudioSectionHeader(icon: Icons.groups_rounded, title: tx('tn_players'), padding: const EdgeInsets.only(top: 10)),
      for (var i = 0; i < _players.length; i++)
        StudioPanel(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(children: [
            IconButton(
              tooltip: tx('tn_players'),
              onPressed: () => setState(() => _players[i].avatar = (_players[i].avatar + 1) % kTournamentAvatars.length),
              icon: Text(_players[i].icon, style: const TextStyle(fontSize: 28)),
            ),
            Expanded(
              child: TextField(
                key: ValueKey('tn-name-$i'),
                controller: _names[i],
                maxLength: 14,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: tx('tn_name'), counterText: ''),
              ),
            ),
            IconButton(
              tooltip: tx('tn_remove'),
              onPressed: _players.length > Tournament.minPlayers ? () => setState(() => _removePlayer(i)) : null,
              icon: const Icon(Icons.close_rounded),
            ),
          ]),
        ),
      if (_players.length < Tournament.maxPlayers)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('tn-add'),
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(tx('tn_add')),
            onPressed: () => setState(_addPlayer),
          ),
        ),
      StudioSectionHeader(icon: Icons.sports_esports_rounded, title: tx('tn_pick'), padding: const EdgeInsets.only(top: 10)),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final g in widget.games)
          FilterChip(
            key: ValueKey('tn-game-${g.gameId}'),
            avatar: Icon(g.rules.localPlayers >= 2 ? Icons.groups_rounded : Icons.person_rounded, size: 18),
            label: Text(widget.titleOf(g)),
            selected: _picked.contains(g.gameId),
            onSelected: (v) => setState(() => v ? _picked.add(g.gameId) : _picked.remove(g.gameId)),
          ),
      ]),
      StudioSectionHeader(icon: Icons.repeat_rounded, title: tx('tn_rounds'), padding: const EdgeInsets.only(top: 12)),
      Wrap(spacing: 8, children: [
        for (var r = 1; r <= Tournament.maxRounds; r++)
          ChoiceChip(label: Text('$r'), selected: _rounds == r, onSelected: (_) => setState(() => _rounds = r)),
      ]),
      const SizedBox(height: 18),
      StudioButton.hot(
        key: const ValueKey('tn-start'),
        label: tx('tn_start'),
        icon: Icons.emoji_events_rounded,
        onPressed: valid ? _start : () => showToast(context, tx('tn_need')),
      ),
    ]);
  }

  Widget _run(Tournament t) {
    final m = t.match!;
    final tg = t.game!;
    final g = _game(tg.gameId);
    final title = g == null ? tg.gameId : widget.titleOf(g);
    final who = t.player;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      StudioPanel(
        margin: const EdgeInsets.only(bottom: 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(tx('tn_round', {'a': m.round + 1, 'b': t.rounds}),
              style: TextStyle(color: StudioLook.of(context).accent, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(children: [
            if (g != null && widget.art != null) ClipRRect(borderRadius: BorderRadius.circular(12), child: widget.art!(g, 52)),
            if (g != null && widget.art != null) const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                Text(
                    '${tg.together ? tx('tn_together') : tx('tn_turns')}${m.groups > 1 ? ' · ${tx('tn_group', {'a': m.group + 1, 'b': m.groups})}' : ''}',
                    style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 13)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          StudioBar(value: t.progress),
        ]),
      ),
      StudioPanel(
        key: const ValueKey('tn-pass'),
        margin: const EdgeInsets.symmetric(vertical: 6),
        gradient: LinearGradient(colors: [StudioLook.of(context).card, StudioLook.of(context).play.withValues(alpha: 0.6)]),
        child: Column(children: [
          if (who != null) ...[
            Text(t.players[who].icon, style: const TextStyle(fontSize: 56)),
            Text(tx('tn_pass', {'name': t.players[who].name}),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
          ] else ...[
            Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 6, children: [
              for (var s = 0; s < m.players.length; s++)
                Chip(
                    avatar: Text(t.players[m.players[s]].icon),
                    label: Text('${tx('tn_player_n', {'n': s + 1})}: ${t.players[m.players[s]].name}')),
            ]),
          ],
          const SizedBox(height: 12),
          StudioButton(
            key: const ValueKey('tn-ready'),
            label: tx('tn_ready'),
            icon: Icons.play_arrow_rounded,
            onPressed: _playNext,
          ),
        ]),
      ),
      _scoreboard(t),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(tx('tn_saved'), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 12)),
      ),
      TextButton.icon(
        icon: const Icon(Icons.logout_rounded),
        label: Text(tx('tn_quit')),
        onPressed: () => Navigator.maybePop(context),
      ),
    ]);
  }

  Widget _scoreboard(Tournament t) {
    final totals = t.totals;
    final order = t.standings;
    final top = totals.isEmpty ? 0 : totals.reduce((a, b) => a > b ? a : b);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      StudioSectionHeader(icon: Icons.leaderboard_rounded, title: tx('tn_board'), padding: const EdgeInsets.only(top: 8)),
      for (var k = 0; k < order.length; k++)
        StudioPanel(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            SizedBox(width: 30, child: Text('${k + 1}.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
            Text(t.players[order[k]].icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t.players[order[k]].name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                StudioBar(value: top == 0 ? 0 : totals[order[k]] / top, height: 6),
              ]),
            ),
            const SizedBox(width: 10),
            Text(tx('tn_pts', {'n': totals[order[k]]}),
                style: const TextStyle(color: StudioLook.gold, fontWeight: FontWeight.w900)),
          ]),
        ),
    ]);
  }

  Widget _ceremony(Tournament t) {
    final champs = t.champions;
    final totals = t.totals;
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 24), children: [
      const SizedBox(height: 8),
      TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.4, end: 1),
        duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.elasticOut,
        builder: (_, v, child) => Transform.scale(scale: v, child: child),
        child: const Center(child: Text('🎉 🏆 🎉', style: TextStyle(fontSize: 64))),
      ),
      const SizedBox(height: 8),
      Text(
        key: const ValueKey('tn-champion'),
        champs.length == 1
            ? tx('tn_champ', {'name': '${t.players[champs.first].icon} ${t.players[champs.first].name}'})
            : '${tx('tn_joint')}\n${champs.map((i) => '${t.players[i].icon} ${t.players[i].name}').join('  ')}',
        textAlign: TextAlign.center,
        style: const TextStyle(color: StudioLook.gold, fontSize: 26, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      Text(tx('tn_congrats'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
      const SizedBox(height: 10),
      for (final i in t.standings)
        StudioPanel(
          margin: const EdgeInsets.symmetric(vertical: 3),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          borderColor: champs.contains(i) ? StudioLook.gold : null,
          child: Row(children: [
            Text(champs.contains(i) ? '🥇' : '🎖️', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 6),
            Text(t.players[i].icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Expanded(
                child: Text(t.players[i].name,
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))),
            Text(tx('tn_pts', {'n': totals[i]}), style: const TextStyle(color: StudioLook.gold, fontWeight: FontWeight.w900)),
          ]),
        ),
      const SizedBox(height: 16),
      StudioButton(
        key: const ValueKey('tn-new'),
        label: tx('tn_new'),
        icon: Icons.refresh_rounded,
        onPressed: () {
          setState(() => _t = null);
          unawaited(_save());
        },
      ),
    ]);
  }
}
