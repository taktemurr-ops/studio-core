/// Çevrimiçi ekranlar: oyun lobisi, bekleme odası, masada sohbet/hediye,
/// profil (ad, avatar, arkadaşlar, hediyeler, lig) ve sıralama.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/adaptive.dart';
import '../app/app_state.dart';
import '../app/screens/play.dart';
import '../app/widgets.dart';
import '../core/clock.dart';
import '../core/level_plan.dart';
import 'online.dart';
import 'online_service.dart';

const avatars = ['🦊', '🐼', '🦁', '🐯', '🐻', '🐨', '🐸', '🐵', '🦉', '🦅', '🐬', '🐢', '🦄', '🐝', '🐙', '🦋', '🌟', '🍀', '⚽', '🎲', '♟️', '🃏', '🎯', '🎸'];

String avatarOf(int i) => avatars[i.clamp(0, avatars.length - 1)];

/// Çevrimiçi kapalıyken ya da açılamazsa kullanıcıya kısa bilgi verir.
Future<bool> _ensureOnline(BuildContext context, AppState app) async {
  final ok = await Online.instance.start();
  if (!ok && context.mounted) showToast(context, app.t('online_unavailable'));
  return ok;
}

/// Oyunun çevrimiçi lobisi: hızlı eşleşme, arkadaş daveti, kodla katılma.
Future<void> openOnline(BuildContext context, AppState app) async {
  if (!await _ensureOnline(context, app) || !context.mounted) return;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineLobby(app: app)));
}

class OnlineLobby extends StatefulWidget {
  final AppState app;
  const OnlineLobby({super.key, required this.app});

  @override
  State<OnlineLobby> createState() => _OnlineLobbyState();
}

class _OnlineLobbyState extends State<OnlineLobby> {
  bool _busy = false;
  final _code = TextEditingController();

  AppState get app => widget.app;
  OnlineBackend get b => Online.instance.backend!;
  int get seats => app.config.rules.localPlayers;
  String get gameId => app.config.gameId;

  Future<void> _go(Future<OnlineMatch?> Function() f) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final m = await f();
      if (!mounted) return;
      if (m == null) {
        showToast(context, app.t('code_not_found'));
        return;
      }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => WaitingRoom(app: app, match: m)));
    } catch (_) {
      if (mounted) showToast(context, app.t('online_unavailable'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Online.instance.profile!;
    final rating = p.ratingFor(gameId);
    return Scaffold(
      appBar: AppBar(title: Text(app.t('online_play')), actions: [
        IconButton(
            icon: const Icon(Icons.leaderboard),
            tooltip: app.t('leaderboards'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LeaderboardScreen(app: app)))),
        IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: app.t('profile'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineProfileScreen(app: app)))),
      ]),
      body: ContentWidth(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(
            child: ListTile(
              leading: Text(avatarOf(p.avatar), style: const TextStyle(fontSize: 34)),
              title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${app.t(leagueKeys[leagueTier(rating)])} · ${app.t('rating')}: $rating'),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            icon: const Icon(Icons.bolt),
            label: Text(app.t('quick_match')),
            onPressed: _busy ? null : () => _go(() => b.quickMatch(gameId, seats, rating)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.group_add),
            label: Text(app.t('invite_friend')),
            onPressed: _busy ? null : () => _go(() => b.createMatch(gameId, seats)),
          ),
          const SizedBox(height: 20),
          Text(app.t('join_code'), style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: InputDecoration(hintText: app.t('enter_code'), counterText: ''),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _busy ? null : () => _go(() => b.joinByCode(_code.text.trim())),
              child: Text(app.t('join_code')),
            ),
          ]),
          if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
        ]),
      ),
    );
  }
}

/// Masanın dolmasını bekler; hızlı eşleşmede 15 saniye sonra boş
/// koltuklara bot oturur, davette ev sahibi "Botlarla başla" diyebilir.
class WaitingRoom extends StatefulWidget {
  final AppState app;
  final OnlineMatch match;
  const WaitingRoom({super.key, required this.app, required this.match});

  @override
  State<WaitingRoom> createState() => _WaitingRoomState();
}

class _WaitingRoomState extends State<WaitingRoom> {
  StreamSubscription<void>? _sub;
  Timer? _auto;
  bool _started = false;

  OnlineMatch get m => widget.match;
  AppState get app => widget.app;

  @override
  void initState() {
    super.initState();
    _sub = m.changes.listen((_) => _check());
    // Hızlı eşleşme (kodu paylaşılmayan masa): kimse beklemesin.
    _auto = Timer(const Duration(seconds: 15), () {
      if (m.isHost && m.status == MatchStatus.waiting && !_private) m.fillWithBotsAndStart();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  bool get _private => m.private;

  void _check() {
    if (!mounted) return;
    setState(() {});
    if (m.status == MatchStatus.playing && !_started) {
      _started = true;
      final spec = app.session.planner.run(GameModeId.online, m.seed, difficulty: 4);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnlineTable(app: app, match: m, spec: spec)));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _auto?.cancel();
    if (!_started) m.leave();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final seats = m.seats;
    final size = app.config.rules.localPlayers;
    return Scaffold(
      appBar: AppBar(title: Text(app.t('waiting_players'))),
      body: ContentWidth(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          Text(app.t('share_code'), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Center(
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: m.code));
                showToast(context, m.code);
              },
              child: Text(m.code,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(letterSpacing: 6, fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < size; i++)
            Card(
              child: ListTile(
                leading: Text(i < seats.length && !seats[i].bot ? avatarOf(seats[i].avatar) : '⏳', style: const TextStyle(fontSize: 28)),
                title: Text(i < seats.length ? (seats[i].bot ? '🤖' : seats[i].name) : app.t('searching')),
              ),
            ),
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          if (m.isHost)
            OutlinedButton.icon(
              icon: const Icon(Icons.smart_toy),
              label: Text(app.t('start_with_bots')),
              onPressed: () => m.fillWithBotsAndStart(),
            ),
        ]),
      ),
    );
  }
}

/// Oyun ekranı + masadaki sosyal katman (sohbet, hediye, oyuncular).
class OnlineTable extends StatefulWidget {
  final AppState app;
  final OnlineMatch match;
  final LevelSpec spec;
  const OnlineTable({super.key, required this.app, required this.match, required this.spec});

  @override
  State<OnlineTable> createState() => _OnlineTableState();
}

class _OnlineTableState extends State<OnlineTable> {
  StreamSubscription<TableEvent>? _sub;
  final List<(TableEvent, DateTime)> _bubbles = [];
  final Set<int> _muted = {};
  Timer? _tick;

  OnlineMatch get m => widget.match;
  AppState get app => widget.app;
  Profile get me => Online.instance.profile!;

  @override
  void initState() {
    super.initState();
    _sub = m.events.listen((e) {
      if (_muted.contains(e.seat) && e.kind != 'g') return;
      final uid = e.seat < m.seats.length ? m.seats[e.seat].uid : '';
      if (me.blocked.contains(uid)) return;
      setState(() => _bubbles.add((e, DateTime.now())));
    });
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      if (_bubbles.any((b) => now.difference(b.$2).inSeconds > 4)) {
        setState(() => _bubbles.removeWhere((b) => now.difference(b.$2).inSeconds > 4));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    m.leave();
    super.dispose();
  }

  String _name(int seat) => seat >= 0 && seat < m.seats.length ? (m.seats[seat].bot ? '🤖' : m.seats[seat].name) : '';

  String _text(TableEvent e) {
    switch (e.kind) {
      case 'p':
        return app.t(e.value);
      case 'g':
        final g = giftCatalog.firstWhere((x) => x.id == e.value, orElse: () => giftCatalog.first);
        return '${g.icon} → ${_name(e.to)}';
      default:
        return e.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PlayScreen(spec: widget.spec, match: OnlineMatchLink(m)),
      Positioned(
        top: MediaQuery.paddingOf(context).top + 60,
        left: 12,
        right: 12,
        child: IgnorePointer(
          child: Column(children: [
            for (final b in _bubbles.take(3))
              Card(
                color: Theme.of(context).colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text('${_name(b.$1.seat)}: ${_text(b.$1)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
          ]),
        ),
      ),
      Positioned(
        right: 10,
        bottom: MediaQuery.paddingOf(context).bottom + 120,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FloatingActionButton.small(heroTag: 'chat', tooltip: app.t('chat'), onPressed: _chat, child: const Icon(Icons.chat_bubble)),
          const SizedBox(height: 8),
          FloatingActionButton.small(heroTag: 'gift', tooltip: app.t('gifts'), onPressed: _gift, child: const Icon(Icons.card_giftcard)),
          const SizedBox(height: 8),
          FloatingActionButton.small(heroTag: 'people', tooltip: app.t('players'), onPressed: _people, child: const Icon(Icons.people)),
        ]),
      ),
    ]);
  }

  Future<void> _chat() async {
    final text = TextEditingController();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (c) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom, left: 16, right: 16, top: 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in presetMessages)
              ActionChip(
                label: Text(app.t(p)),
                onPressed: () {
                  m.say(TableEvent(m.mySeat, 'p', p));
                  Navigator.pop(c);
                },
              ),
          ]),
          if (me.age16) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(controller: text, maxLength: maxChatLength, decoration: InputDecoration(hintText: app.t('type_message'), counterText: '')),
              ),
              IconButton.filled(
                icon: const Icon(Icons.send),
                tooltip: app.t('send'),
                onPressed: () {
                  final t = cleanChat(text.text);
                  if (t.isNotEmpty) m.say(TableEvent(m.mySeat, 't', t));
                  Navigator.pop(c);
                },
              ),
            ]),
          ],
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  int get _freeLeft {
    final s = app.save;
    final today = int.parse(DateKeys.day(app.session.now()).replaceAll('-', ''));
    if (s.stat('gift_day') != today) return freeGiftsPerDay + (s.premium ? 5 : 0);
    return (freeGiftsPerDay + (s.premium ? 5 : 0) - s.stat('gift_free')).clamp(0, 99);
  }

  Future<void> _gift() async {
    final targets = [for (var i = 0; i < m.seats.length; i++) if (i != m.mySeat && !m.seats[i].bot) i];
    if (targets.isEmpty) return;
    var to = targets.first;
    await showModalBottomSheet<void>(
      context: context,
      builder: (c) => StatefulBuilder(builder: (c, setS) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 8, children: [
              for (final t in targets) ChoiceChip(label: Text(_name(t)), selected: to == t, onSelected: (_) => setS(() => to = t)),
            ]),
            const SizedBox(height: 8),
            Text('${app.t('free_left', {'n': _freeLeft})} · 💎 ${app.save.gems}'),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [
              for (final g in giftCatalog)
                InkWell(
                  onTap: () async {
                    if (!_spend(g)) {
                      showToast(context, app.t('not_enough_gems'));
                      return;
                    }
                    Navigator.pop(c);
                    await m.say(TableEvent(m.mySeat, 'g', g.id, to));
                    unawaited(Online.instance.backend!.recordGift(m.seats[to].uid, g.id).catchError((_) {}));
                  },
                  child: Container(
                    width: 84,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
                    child: Column(children: [
                      Text(g.icon, style: const TextStyle(fontSize: 30)),
                      Text(app.t('gift_${g.id}'), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(g.gems == 0 ? '✓' : '💎 ${g.gems}', style: const TextStyle(fontSize: 12)),
                    ]),
                  ),
                ),
            ]),
          ]),
        );
      }),
    );
  }

  /// Ücretsiz hediye günlük haktan, ücretli olan elmastan düşer.
  bool _spend(Gift g) {
    final s = app.save;
    if (g.gems == 0) {
      if (_freeLeft <= 0) return false;
      final today = int.parse(DateKeys.day(app.session.now()).replaceAll('-', ''));
      if (s.stat('gift_day') != today) {
        s.stats['gift_day'] = today;
        s.stats['gift_free'] = 0;
      }
      s.stats['gift_free'] = s.stat('gift_free') + 1;
    } else {
      if (s.gems < g.gems) return false;
      s.gems -= g.gems;
    }
    app.changed(saveNow: true);
    return true;
  }

  Future<void> _people() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (c) => ListView(shrinkWrap: true, padding: const EdgeInsets.all(8), children: [
        for (var i = 0; i < m.seats.length; i++)
          if (i != m.mySeat && !m.seats[i].bot)
            ListTile(
              leading: Text(avatarOf(m.seats[i].avatar), style: const TextStyle(fontSize: 26)),
              title: Text(m.seats[i].name),
              trailing: Wrap(children: [
                IconButton(
                    tooltip: app.t('mute'),
                    icon: Icon(_muted.contains(i) ? Icons.volume_off : Icons.volume_up),
                    onPressed: () {
                      setState(() => _muted.contains(i) ? _muted.remove(i) : _muted.add(i));
                      Navigator.pop(c);
                    }),
                IconButton(
                    tooltip: app.t('report'),
                    icon: const Icon(Icons.flag),
                    onPressed: () async {
                      Navigator.pop(c);
                      await Online.instance.backend!.report(m.seats[i].uid, 'user_report', matchId: m.id);
                      if (mounted) showToast(context, app.t('reported'));
                    }),
                IconButton(
                    tooltip: app.t('block'),
                    icon: const Icon(Icons.block),
                    onPressed: () async {
                      Navigator.pop(c);
                      _muted.add(i);
                      await Online.instance.backend!.block(m.seats[i].uid);
                      if (mounted) showToast(context, app.t('blocked_msg'));
                    }),
              ]),
            ),
      ]),
    );
  }
}

/// Profil: ad, avatar, 16+ beyanı, arkadaşlar, hediyeler, lig, bulut kayıt.
class OnlineProfileScreen extends StatefulWidget {
  final AppState app;
  const OnlineProfileScreen({super.key, required this.app});

  @override
  State<OnlineProfileScreen> createState() => _OnlineProfileScreenState();
}

class _OnlineProfileScreenState extends State<OnlineProfileScreen> {
  final _name = TextEditingController();
  final _friend = TextEditingController();
  List<Profile> _friends = const [];

  AppState get app => widget.app;
  Profile get p => Online.instance.profile!;

  @override
  void initState() {
    super.initState();
    _name.text = p.name;
    Online.instance.backend!.friends().then((f) {
      if (mounted) setState(() => _friends = f);
    }).catchError((_) {});
  }

  Future<void> _save() async {
    final n = filterText(_name.text.trim());
    if (n.length >= 3 && !n.contains('*')) p.name = n.length > 16 ? n.substring(0, 16) : n;
    await Online.instance.saveProfile();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final rating = p.ratingFor(app.config.gameId);
    return Scaffold(
      appBar: AppBar(title: Text(app.t('profile'))),
      body: ContentWidth(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: Text(avatarOf(p.avatar), style: const TextStyle(fontSize: 64))),
          TextField(controller: _name, maxLength: 16, decoration: InputDecoration(labelText: app.t('nickname')), onSubmitted: (_) => _save()),
          Text(app.t('avatar'), style: Theme.of(context).textTheme.titleSmall),
          Wrap(spacing: 6, runSpacing: 6, children: [
            for (var i = 0; i < avatars.length; i++)
              ChoiceChip(
                label: Text(avatars[i], style: const TextStyle(fontSize: 22)),
                selected: p.avatar == i,
                onSelected: (_) {
                  p.avatar = i;
                  _save();
                },
              ),
          ]),
          SwitchListTile(
            title: Text(app.t('age16')),
            value: p.age16,
            onChanged: (v) {
              p.age16 = v;
              _save();
            },
          ),
          ListTile(
            title: Text(app.t('rating')),
            subtitle: Text('${app.t(leagueKeys[leagueTier(rating)])} · $rating'),
            leading: const Icon(Icons.military_tech),
          ),
          ListTile(
            leading: const Icon(Icons.qr_code),
            title: Text(app.t('friend_code')),
            subtitle: Text(p.code, style: const TextStyle(fontSize: 20, letterSpacing: 4, fontWeight: FontWeight.w800)),
            onTap: () => Clipboard.setData(ClipboardData(text: p.code)),
          ),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _friend,
                maxLength: 6,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: app.t('enter_code'), counterText: ''),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final f = await Online.instance.backend!.addFriend(_friend.text.trim());
                if (!mounted) return;
                showToast(context, app.t(f == null ? 'code_not_found' : 'friend_added'));
                if (f != null) setState(() => _friends = [..._friends, f]);
              },
              child: Text(app.t('add_friend')),
            ),
          ]),
          const SizedBox(height: 8),
          SectionTitle(app.t('friends')),
          if (_friends.isEmpty) Text(app.t('no_friends')),
          for (final f in _friends)
            ListTile(
              leading: Text(avatarOf(f.avatar), style: const TextStyle(fontSize: 26)),
              title: Text(f.name),
              subtitle: Text('${app.t(leagueKeys[leagueTier(f.ratingFor(app.config.gameId))])} · ${f.ratingFor(app.config.gameId)}'),
            ),
          SectionTitle(app.t('gifts_received')),
          Wrap(spacing: 12, children: [
            for (final g in giftCatalog)
              if ((p.gifts[g.id] ?? 0) > 0) Chip(label: Text('${g.icon} ${p.gifts[g.id]}')),
          ]),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.cloud_upload),
            label: Text(app.t('cloud_backup')),
            onPressed: () async {
              await app.flushSave();
              await Online.instance.backend!.saveBlob(app.config.gameId, app.save.encode());
              if (mounted) showToast(context, app.t('cloud_done'));
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.cloud_download),
            label: Text(app.t('cloud_restore')),
            onPressed: () async {
              final ok = await app.restoreFromCloud();
              if (mounted) showToast(context, app.t(ok ? 'cloud_done' : 'code_not_found'));
            },
          ),
        ]),
      ),
    );
  }
}

/// Oyunun sıralaması: bugün, bu hafta, lig.
class LeaderboardScreen extends StatelessWidget {
  final AppState app;
  const LeaderboardScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final g = app.config.gameId;
    final boards = [('d_${g}_${app.dayKey()}', 'board_daily'), ('w_${g}_${app.save.weeklyKey}', 'board_weekly'), ('r_$g', 'board_league')];
    return DefaultTabController(
      length: boards.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(app.t('leaderboards')),
          bottom: TabBar(tabs: [for (final b in boards) Tab(text: app.t(b.$2))]),
        ),
        body: TabBarView(children: [
          for (final b in boards)
            FutureBuilder<List<ScoreEntry>>(
              future: Online.instance.backend!.top(b.$1),
              builder: (context, snap) {
                final l = snap.data;
                if (l == null) return const Center(child: CircularProgressIndicator());
                final me = Online.instance.profile?.uid;
                return ListView.builder(
                  itemCount: l.length,
                  itemBuilder: (_, i) => ListTile(
                    selected: l[i].uid == me,
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text('${avatarOf(l[i].avatar)}  ${l[i].name}'),
                    trailing: Text('${l[i].score}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                );
              },
            ),
        ]),
      ),
    );
  }
}
