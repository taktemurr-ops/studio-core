/// Çevrimiçi ekranlar: oyun lobisi, bekleme odası, masada sohbet/hediye,
/// profil (ad, avatar, arkadaşlar, hediyeler, lig) ve sıralama.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/adaptive.dart';
import '../app/app_state.dart';
import '../app/screens/play.dart';
import '../app/widgets.dart';
import '../core/clock.dart';
import '../core/level_plan.dart';
import '../core/net_sync.dart';
import '../core/net_texts.dart';
import '../core/strings.dart';
import 'online.dart';
import 'online_service.dart';

const avatars = ['🦊', '🐼', '🦁', '🐯', '🐻', '🐨', '🐸', '🐵', '🦉', '🦅', '🐬', '🐢', '🦄', '🐝', '🐙', '🦋', '🌟', '🍀', '⚽', '🎲', '♟️', '🃏', '🎯', '🎸'];

String avatarOf(int i) => avatars[i.clamp(0, avatars.length - 1)];

/// Çevrimiçi kapalıyken ya da açılamazsa kullanıcıya kısa bilgi verir.
Future<bool> _ensureOnline(BuildContext context, AppState app) async {
  final ok = await Online.instance.start();
  if (!ok && context.mounted) showToast(context, app.t('online_unavailable'));
  if (!ok || !context.mounted) return false;
  return ensureTerms(context, app);
}

/// Güncel kural sürümü; metin değişirse artırılır, herkes yeniden onaylar.
const termsVersion = 1;

/// Çevrimiçi oyun kuralları: ilk girişte (ve kurallar değişince) gösterilir,
/// onaylanmadan lobi, sohbet ve hediye açılmaz.
Future<bool> ensureTerms(BuildContext context, AppState app) async {
  final p = Online.instance.profile;
  if (p == null) return false;
  if (p.terms >= termsVersion) return true;
  final ok = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _TermsDialog(app: app),
      ) ??
      false;
  if (ok) {
    p.terms = termsVersion;
    unawaited(Online.instance.saveProfile());
  }
  return ok;
}

class _TermsDialog extends StatefulWidget {
  final AppState app;
  const _TermsDialog({required this.app});

  @override
  State<_TermsDialog> createState() => _TermsDialogState();
}

class _TermsDialogState extends State<_TermsDialog> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    return AlertDialog(
      key: const ValueKey('terms-dialog'),
      title: Text(app.t('terms_title')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(app.t('terms_body')),
          const SizedBox(height: 12),
          CheckboxListTile(
            key: const ValueKey('terms-check'),
            contentPadding: EdgeInsets.zero,
            value: _checked,
            onChanged: (v) => setState(() => _checked = v ?? false),
            title: Text(app.t('terms_accept')),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(app.t('cancel'))),
        FilledButton(
          key: const ValueKey('terms-ok'),
          onPressed: _checked ? () => Navigator.pop(context, true) : null,
          child: Text(app.t('ok')),
        ),
      ],
    );
  }
}

/// Bir davete ya da yarım kalan maça götürmek için: istenen oyunu açar ve
/// [action]'ı o oyunun ekranında çalıştırır. Oyun bu uygulamada yoksa false.
typedef OpenForGame = Future<bool> Function(String gameId, Future<void> Function(BuildContext context, AppState app) action);

/// Açılışta bir kez bağlanır: arkadaş davetlerini dinler, daha önce çevrimiçi
/// oynamış kullanıcıyı sessizce bağlar ve yarım kalan maçı sorar.
class OnlineHost {
  OnlineHost._();
  static StreamSubscription<Invite>? _sub;
  static bool _asked = false;

  static Future<void> attach(BuildContext context, Strings s, String Function(String gameId) gameName, OpenForGame open) async {
    if (!Online.instance.available) return;
    _sub ??= Online.instance.invites.listen((i) {
      if (context.mounted) unawaited(_invite(context, s, i, gameName(i.gameId), open));
    });
    if (_asked) return;
    _asked = true;
    if (!await Online.instance.resumeSession()) return;
    final m = await Online.instance.resumeActive();
    if (m == null || !context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const ValueKey('rejoin-dialog'),
        title: Text(s.t('rejoin_title')),
        content: Text(s.t('rejoin_body')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('later'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('rejoin_yes'))),
        ],
      ),
    );
    if (ok == true && await open(m.gameId, (c, app) => openTable(c, app, m))) return;
    await m.leave();
    await Online.instance.setActive('');
  }

  static Future<void> _invite(BuildContext context, Strings s, Invite i, String game, OpenForGame open) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        key: const ValueKey('invite-dialog'),
        title: Text('${avatarOf(i.avatar)}  ${s.t('invite_title')}'),
        content: Text(s.t('invite_body', {'name': i.name, 'game': game})),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(s.t('later'))),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(s.t('invite_join'))),
        ],
      ),
    );
    unawaited(Online.instance.dismissInvite(i));
    if (ok == true) await open(i.gameId, (c, app) => joinByInvite(c, app, i.code));
  }
}

/// Bu uygulamanın çevrimiçi sürüm anahtarı (aynı anahtarlılar aynı masaya oturur).
String onlineVersionOf(AppState app) => onlineKey(app.config.rules.onlineVersion);

/// Davetteki kodla masaya oturur.
Future<void> joinByInvite(BuildContext context, AppState app, String code) async {
  if (!await _ensureOnline(context, app) || !context.mounted) return;
  OnlineMatch? m;
  try {
    m = await Online.instance.backend!.joinByCode(code, version: onlineVersionOf(app));
  } on OnlineVersionMismatch {
    if (context.mounted) showToast(context, netUpdateNeeded(app.strings.lang));
    return;
  } catch (_) {
    m = null;
  }
  if (!context.mounted) return;
  if (m == null) {
    showToast(context, app.t('code_not_found'));
    return;
  }
  await Navigator.push(context, MaterialPageRoute(builder: (_) => WaitingRoom(app: app, match: m)));
}

/// Süren bir maçın masasını açar (geri dönüşte geçmiş hamleler yeniden oynanır).
Future<void> openTable(BuildContext context, AppState app, OnlineMatch m) async {
  final spec = app.session.planner.run(GameModeId.online, m.seed, difficulty: 4);
  await Navigator.push(context, MaterialPageRoute(builder: (_) => OnlineTable(app: app, match: m, spec: spec)));
}

/// Oyunun çevrimiçi lobisi: hızlı eşleşme, arkadaş daveti, kodla katılma.
Future<void> openOnline(BuildContext context, AppState app) async {
  // Çocuk oyunlarında çevrimiçi masa (yabancılarla oyun ve sohbet) yoktur.
  if (app.config.kidsMode) return;
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
  bool _private = false;
  final _code = TextEditingController();
  List<TableInfo>? _tables;
  List<Profile> _atTable = const [];

  AppState get app => widget.app;
  OnlineBackend get b => Online.instance.backend!;
  /// Masa büyüklüğü: oyun birden çok seçenek sunuyorsa oyuncu seçer.
  late int seats = app.config.rules.onlineSeatChoices.isNotEmpty
      ? app.config.rules.onlineSeatChoices.first
      : app.config.rules.localPlayers;
  String get gameId => app.config.gameId;
  String get version => onlineVersionOf(app);

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final t = await b.openTables(gameId, seats, version: version).catchError((_) => <TableInfo>[]);
    final f = await b.friends().catchError((_) => <Profile>[]);
    if (!mounted) return;
    setState(() {
      _tables = t;
      _atTable = [for (final p in f) if (p.table.startsWith('$gameId|')) p];
    });
  }

  Future<void> _go(Future<OnlineMatch?> Function() f, {bool quick = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final m = await f();
      if (!mounted) return;
      if (m == null) {
        showToast(context, app.t('code_not_found'));
        unawaited(_refresh());
        return;
      }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => WaitingRoom(app: app, match: m, quick: quick)));
      unawaited(_refresh());
    } on OnlineVersionMismatch {
      if (mounted) showToast(context, netUpdateNeeded(app.strings.lang));
    } catch (_) {
      if (mounted) showToast(context, app.t('online_unavailable'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _seatDots(int taken, int size) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (var i = 0; i < size; i++)
          Padding(
            padding: const EdgeInsets.only(right: 3),
            child: Icon(i < taken ? Icons.person_rounded : Icons.person_outline_rounded,
                size: 18, color: i < taken ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.outline),
          ),
      ]);

  @override
  Widget build(BuildContext context) {
    final p = Online.instance.profile!;
    final rating = p.ratingFor(gameId);
    final text = Theme.of(context).textTheme;
    if (p.vip != app.save.premium) {
      p.vip = app.save.premium;
      unawaited(Online.instance.saveProfile());
    }
    return Scaffold(
      appBar: AppBar(title: Text(app.t('online_table')), actions: [
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
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Card(
              child: ListTile(
                leading: Text(avatarOf(p.avatar), style: const TextStyle(fontSize: 34)),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${app.t(leagueKeys[leagueTier(rating)])} · ${app.t('rating')}: $rating'),
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('open-table'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  icon: const Icon(Icons.table_restaurant_rounded),
                  label: Text(app.t('open_table')),
                  onPressed: _busy ? null : () => _go(() => b.createMatch(gameId, seats, private: _private, version: version)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  icon: const Icon(Icons.bolt),
                  label: Text(app.t('quick_match')),
                  onPressed: _busy ? null : () => _go(() => b.quickMatch(gameId, seats, rating, version: version), quick: true),
                ),
              ),
            ]),
            if (app.config.rules.onlineSeatChoices.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                  const Icon(Icons.groups_rounded),
                  for (final n in app.config.rules.onlineSeatChoices)
                    ChoiceChip(
                      key: ValueKey('seats-$n'),
                      label: Text('$n'),
                      selected: seats == n,
                      onSelected: _busy
                          ? null
                          : (_) {
                              setState(() {
                                seats = n;
                                _tables = null;
                              });
                              unawaited(_refresh());
                            },
                    ),
                ]),
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(app.t('private_table')),
              secondary: const Icon(Icons.lock_outline_rounded),
              value: _private,
              onChanged: (v) => setState(() => _private = v),
            ),
            if (_atTable.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(app.t('friends_title'), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              for (final f in _atTable)
                Card(
                  child: ListTile(
                    leading: Text(avatarOf(f.avatar), style: const TextStyle(fontSize: 28)),
                    title: Text(f.name),
                    subtitle: Text(app.t('friend_at_table')),
                    trailing: FilledButton(
                      onPressed: _busy ? null : () => _go(() => b.joinTable(f.table.split('|').last, version: version)),
                      child: Text(app.t('join_table')),
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: Text(app.t('open_tables'), style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
              IconButton(tooltip: app.t('refresh'), icon: const Icon(Icons.refresh_rounded), onPressed: _refresh),
            ]),
            if (_tables == null)
              const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator()))
            else if (_tables!.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(app.t('no_open_tables'), textAlign: TextAlign.center, style: text.bodyMedium),
              )
            else
              for (final t in _tables!)
                Card(
                  child: ListTile(
                    leading: Text(avatarOf(t.hostAvatar), style: const TextStyle(fontSize: 28)),
                    title: Text(t.hostName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Row(children: [
                      _seatDots(t.taken, t.size),
                      const SizedBox(width: 6),
                      Flexible(child: Text(app.t('table_seats', {'n': t.taken, 'm': t.size}), overflow: TextOverflow.ellipsis)),
                    ]),
                    trailing: FilledButton(
                      onPressed: _busy ? null : () => _go(() => b.joinTable(t.id, version: version)),
                      child: Text(app.t('join_table')),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              leading: const Icon(Icons.vpn_key_outlined),
              title: Text(app.t('join_code')),
              children: [
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
                    onPressed: _busy ? null : () => _go(() => b.joinByCode(_code.text.trim(), version: version)),
                    child: Text(app.t('join_code')),
                  ),
                ]),
              ],
            ),
            if (_busy) const Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
          ]),
        ),
      ),
    );
  }
}

/// Masanın dolmasını bekler; hızlı eşleşmede 15 saniye sonra boş
/// koltuklara bot oturur, davette ev sahibi "Botlarla başla" diyebilir.
class WaitingRoom extends StatefulWidget {
  final AppState app;
  final OnlineMatch match;

  /// Hızlı eşleşme: 15 saniyede kimse gelmezse boş koltuklara bot oturur.
  /// Açılan masalar ise arkadaşlar ve listeden gelenler için bekler.
  final bool quick;
  const WaitingRoom({super.key, required this.app, required this.match, this.quick = false});

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
    unawaited(Online.instance.setTable('${m.gameId}|${m.id}'));
    // Hızlı eşleşme (kodu paylaşılmayan masa): kimse beklemesin. 15 sn sonra
    // ve ardından birkaç saniyede bir denetlenir: ev sahibi masadan gittiyse
    // (eskimiş masaya oturulduysa) ev sahipliği bu cihaza geçer ve masa yine
    // botlarla başlar (eskiden tek seferlik zamanlayıcı kaçınca sonsuza dek beklenirdi).
    final opened = DateTime.now();
    _auto = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {}); // kopan ev sahibi: "Botlarla başla" bu cihazda görünsün
      if (widget.quick &&
          DateTime.now().difference(opened).inSeconds >= 15 &&
          m.isHost &&
          m.status == MatchStatus.waiting &&
          !_private) {
        unawaited(m.fillWithBotsAndStart().catchError((Object _) {}));
      }
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
      unawaited(Online.instance.setActive(m.id));
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => OnlineTable(app: app, match: m, spec: spec)));
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _auto?.cancel();
    unawaited(Online.instance.setTable(''));
    if (!_started) m.leave();
    super.dispose();
  }

  /// Arkadaş listesinden seçilene uygulama içi davet gönderir.
  Future<void> _callFriend() async {
    final friends = await Online.instance.backend!.friends().catchError((_) => <Profile>[]);
    if (!mounted) return;
    final sent = <String>{};
    await showModalBottomSheet<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => SafeArea(
          child: friends.isEmpty
              ? Padding(padding: const EdgeInsets.all(24), child: Text(app.t('no_friends'), textAlign: TextAlign.center))
              : ListView(shrinkWrap: true, children: [
                  for (final f in friends)
                    ListTile(
                      leading: Text(avatarOf(f.avatar), style: const TextStyle(fontSize: 26)),
                      title: Text(f.name),
                      trailing: sent.contains(f.uid)
                          ? const Icon(Icons.check_circle)
                          : FilledButton(
                              onPressed: () async {
                                await Online.instance.sendInvite(f.uid, m.gameId, m.code).catchError((_) {});
                                set(() => sent.add(f.uid));
                                if (mounted) showToast(context, app.t('invite_sent'));
                              },
                              child: Text(app.t('invite')),
                            ),
                    ),
                ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final seats = m.seats;
    final size = m.size;
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
          _RoundTable(
            size: size,
            seats: [
              for (var i = 0; i < size; i++)
                i < seats.length
                    ? (seats[i].bot ? '🤖' : avatarOf(seats[i].avatar), seats[i].bot ? '🤖' : seats[i].label)
                    : (null, app.t('empty_seat')),
            ],
          ),
          const SizedBox(height: 12),
          const Center(child: CircularProgressIndicator()),
          const SizedBox(height: 12),
          if (m.isHost) ...[
            FilledButton.tonalIcon(
              key: const ValueKey('call-friend'),
              icon: const Icon(Icons.person_add_alt_1),
              label: Text(app.t('call_friend')),
              onPressed: _callFriend,
            ),
            const SizedBox(height: 8),
          ],
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
  StreamSubscription<void>? _chg;
  StreamSubscription<MoveRejected>? _rej;
  final List<(TableEvent, DateTime)> _bubbles = [];
  final Set<int> _muted = {};
  Timer? _tick;

  /// Masa: hamle reddedilince (eşzamanlı hamle) geçmişten yeniden kurulur.
  late OnlineMatch m = widget.match;
  late OnlineMatchLink _link = OnlineMatchLink(m);
  int _gen = 0;
  bool _resyncing = false;
  Set<int> _shownDropped = const {};
  final ValueNotifier<String> _rematchNote = ValueNotifier('');
  bool _leftMatch = false;

  AppState get app => widget.app;
  Profile get me => Online.instance.profile!;
  String get lang => app.strings.lang;

  @override
  void initState() {
    super.initState();
    _attach();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final d = m.status == MatchStatus.playing ? m.dropped : const <int>{};
      final stale = _bubbles.any((b) => now.difference(b.$2).inSeconds > 4);
      if (stale || !setEquals(d, _shownDropped)) {
        setState(() {
          _bubbles.removeWhere((b) => now.difference(b.$2).inSeconds > 4);
          _shownDropped = d;
        });
      }
    });
  }

  void _attach() {
    _sub = m.events.listen((e) {
      if (_muted.contains(e.seat) && e.kind != 'g') return;
      // Serbest yazı yalnızca 16+ beyan eden oyuncuya gösterilir (16 yaş altı
      // ve çocuk oyunlarında yabancıların yazdığı metin görünmez).
      if (e.kind == 't' && (!me.age16 || app.config.kidsMode)) return;
      final uid = e.seat >= 0 && e.seat < m.seats.length ? m.seats[e.seat].uid : '';
      if (me.blocked.contains(uid)) return;
      setState(() => _bubbles.add((e, DateTime.now())));
    });
    _chg = m.changes.listen((_) => _onChange());
    _rej = m.rejections.listen((_) => _resync());
  }

  Future<void> _detach() async {
    await _sub?.cancel();
    await _chg?.cancel();
    await _rej?.cancel();
  }

  void _onChange() {
    if (!mounted) return;
    final n = m.next;
    if (n.isNotEmpty) {
      final p = n.split('|');
      final seat = p.length == 2 ? int.tryParse(p.first) ?? -1 : -1;
      if (seat != m.mySeat && seat >= 0 && seat < m.seats.length) {
        _rematchNote.value = netRematchOffer(lang, m.seats[seat].label);
      }
    }
  }

  /// Bu cihazın hamlesi reddedildi (aynı anda başka bir cihaz o sıraya hamle
  /// yazdı): masa sunucudaki geçmişten yeniden kurulur, oyun ekranı geçmiş
  /// hamleleri yeniden oynar. Böylece hiçbir cihaz masadan ayrışmış kalmaz.
  Future<void> _resync() async {
    if (_resyncing || !mounted) return;
    _resyncing = true;
    showToast(context, netResyncing(lang));
    final fresh = await Online.instance.backend?.rejoin(m.id, ended: true).catchError((Object _) => null);
    if (!mounted) return;
    if (fresh != null) {
      final old = m;
      await _detach();
      unawaited(old.leave());
      setState(() {
        m = fresh;
        _link = OnlineMatchLink(fresh);
        _gen++;
      });
      _attach();
    }
    _resyncing = false;
  }

  /// Rövanş: masada biri açtıysa ona oturulur, yoksa aynı büyüklükte yeni
  /// (davetli) masa açılıp duyurulur; diğerleri sonuç ekranında daveti görür.
  Future<void> _rematch() async {
    final b = Online.instance.backend;
    if (b == null) return;
    final version = onlineVersionOf(app);
    try {
      var target = m.next.split('|').last;
      OnlineMatch? nm;
      if (target.isEmpty) {
        final created = await b.createMatch(m.gameId, m.size, private: true, version: version);
        final won = await m.offerRematch(created.id);
        if (won.split('|').last == created.id) {
          nm = created;
        } else {
          await created.leave();
          target = won.split('|').last;
        }
      }
      nm ??= await b.joinTable(target, version: version);
      if (!mounted) return;
      if (nm == null) {
        showToast(context, app.t('code_not_found'));
        Navigator.pop(context);
        return;
      }
      final next = nm;
      await Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WaitingRoom(app: app, match: next)));
    } catch (_) {
      if (mounted) showToast(context, app.t('online_unavailable'));
    }
  }

  @override
  void dispose() {
    _detach();
    _tick?.cancel();
    _rematchNote.dispose();
    // Maç sürerken masadan kalkan oyuncu yenik sayılır (lig puanı düşer) ve
    // koltuğu hemen bota geçer; maç bittiyse yalnızca dinleme kapanır.
    final forfeit = m.status == MatchStatus.playing && !_leftMatch && !_link.finished;
    if (forfeit) {
      _leftMatch = true;
      unawaited(_link.forfeit().catchError((Object _) {}));
    } else {
      unawaited(m.leave().catchError((Object _) {}));
    }
    super.dispose();
  }

  String _name(int seat) => seat >= 0 && seat < m.seats.length ? (m.seats[seat].bot ? '🤖' : m.seats[seat].label) : '';

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
    final dropped = _shownDropped.where((i) => i < m.seats.length).toList()..sort();
    return Stack(children: [
      PlayScreen(
        key: ValueKey('online-play-$_gen'),
        spec: widget.spec,
        match: _link,
        onRematch: _rematch,
        rematchNote: _rematchNote,
      ),
      // Bağlantı göstergesi: bağlantısı kopan oyuncunun yerine bot oynuyor.
      if (dropped.isNotEmpty)
        Positioned(
          top: MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
          left: 12,
          right: 12,
          child: IgnorePointer(
            child: Center(
              child: Container(
                key: const ValueKey('net-dropped'),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.wifi_off_rounded, color: Color(0xFFFFD166), size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      netNoteText(lang, NetNote.botPlaying, dropped.map((i) => m.seats[i].label).join(', ')),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      // Balonlar altta, ipucu düğmesinin üstünde: üstteki hedef/sıra satırını kapatmaz.
      Positioned(
        bottom: MediaQuery.paddingOf(context).bottom + 84,
        left: 12,
        right: 64,
        child: IgnorePointer(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          if (me.age16 && !app.config.kidsMode) ...[
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
    if (targets.isEmpty) {
      showToast(context, app.t('gift_no_target'));
      return;
    }
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
    final today = int.parse(DateKeys.day(app.session.now()).replaceAll('-', ''));
    // Premium: günde 5 gül ücretsiz.
    if (g.id == 'rose' && s.premium) {
      if (s.stat('rose_day') != today) {
        s.stats['rose_day'] = today;
        s.stats['rose_free'] = 0;
      }
      if (s.stat('rose_free') < 5) {
        s.stats['rose_free'] = s.stat('rose_free') + 1;
        app.changed(saveNow: true);
        return true;
      }
    }
    if (g.gems == 0) {
      if (_freeLeft <= 0) return false;
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
  final _transfer = TextEditingController();
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
          const SizedBox(height: 16),
          SectionTitle(app.t('transfer_title')),
          OutlinedButton.icon(
            icon: const Icon(Icons.phone_android),
            label: Text(app.t('transfer_create')),
            onPressed: () async {
              final code = await Online.instance.createTransfer();
              if (!mounted || code == null) return;
              await showDialog<void>(
                context: context,
                builder: (c) => AlertDialog(
                  title: SelectableText(code, style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800)),
                  content: Text(app.t('transfer_code_info')),
                  actions: [
                    TextButton(onPressed: () => Clipboard.setData(ClipboardData(text: code)), child: const Icon(Icons.copy)),
                    FilledButton(onPressed: () => Navigator.pop(c), child: Text(app.t('cloud_done'))),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _transfer,
                maxLength: 12,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(hintText: app.t('transfer_enter'), counterText: ''),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: () async {
                final ok = await Online.instance.claimTransfer(_transfer.text);
                if (!mounted) return;
                showToast(context, app.t(ok ? 'transfer_done' : 'code_not_found'));
              },
              child: const Icon(Icons.download),
            ),
          ]),
          const SizedBox(height: 24),
          TextButton.icon(
            icon: const Icon(Icons.delete_forever, color: Colors.red),
            label: Text(app.t('delete_account'), style: const TextStyle(color: Colors.red)),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  content: Text(app.t('delete_account_q')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: Text(app.t('cancel'))),
                    FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(app.t('delete_account'))),
                  ],
                ),
              );
              if (yes != true) return;
              await Online.instance.deleteAccount();
              if (mounted) Navigator.pop(context);
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


/// Bekleme odasındaki yuvarlak masa: koltuklar masanın çevresinde.
class _RoundTable extends StatelessWidget {
  final int size;
  final List<(String?, String)> seats;
  const _RoundTable({required this.size, required this.seats});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.25,
      child: LayoutBuilder(builder: (context, c) {
        final w = c.maxWidth, h = c.maxHeight;
        final center = Offset(w / 2, h / 2);
        final rx = w * 0.36, ry = h * 0.34;
        return Stack(children: [
          Positioned(
            left: center.dx - rx * 0.78,
            top: center.dy - ry * 0.72,
            width: rx * 1.56,
            height: ry * 1.44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(colors: [Color(0xFF2E8A5E), Color(0xFF1B5A3D)]),
                border: Border.all(color: const Color(0xFF8A5A36), width: 8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))],
              ),
            ),
          ),
          for (var i = 0; i < size; i++)
            Builder(builder: (context) {
              final a = math.pi / 2 + i * 2 * math.pi / size;
              final p = Offset(center.dx + math.cos(a) * rx, center.dy + math.sin(a) * ry);
              final (av, name) = seats[i];
              return Positioned(
                left: p.dx - 52,
                top: p.dy - 34,
                width: 104,
                child: Column(children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: av == null ? Colors.white24 : Colors.white,
                    child: av == null
                        ? const Icon(Icons.chair_alt_rounded, color: Colors.white70)
                        : Text(av, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(height: 2),
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700)),
                ]),
              );
            }),
        ]);
      }),
    );
  }
}
