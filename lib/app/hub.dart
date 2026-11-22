import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/game_session.dart';
import '../core/monetization.dart';
import '../core/save_data.dart';
import '../core/save_store.dart';
import '../core/strings.dart';
import '../core/telemetry.dart';
import 'adaptive.dart';
import 'app_state.dart';
import 'bootstrap.dart';
import 'game_api.dart';
import 'services/ads.dart';
import 'services/audio.dart';
import 'services/prefs_backend.dart';
import 'services/purchases.dart';
import '../online/online_service.dart';
import '../online/online_ui.dart';
import 'studio_apps.dart';
import 'theme.dart';
import 'services/cloud_telemetry.dart';

/// A hub ("merkez") app: one store listing that bundles several games of
/// the same family. Every game keeps its own save (prefixed by gameId), its
/// own progress, missions and settings; device-level services are shared.
class HubConfig {
  final String hubId;
  final List<String> title; // tr, en, de, es, fr
  final List<String> tagline;
  final Color seedColor;
  final IconData icon;
  final List<GameConfig> games;

  /// Families of variants shown as one tile that opens its own list.
  final List<HubGroup> groups;

  /// Optional headings on the home screen. Each section lists game and group
  /// ids in order; anything not listed is shown at the end without a heading.
  final List<HubSection> sections;

  /// İlk açılış rehberinde önerilen oyunlar (gameId); boşsa ilk üç oyun.
  final List<String> starters;

  const HubConfig({
    required this.hubId,
    required this.title,
    required this.tagline,
    required this.seedColor,
    required this.icon,
    required this.games,
    this.groups = const [],
    this.sections = const [],
    this.starters = const [],
  });

  /// Every game in the hub, including those inside groups.
  List<GameConfig> get allGames => [...games, for (final g in groups) ...g.games];

  String localized(List<String> l, String lang) {
    return Strings.pick(l, lang);
  }
}

/// A heading on the hub's home screen with the games (and groups) under it.
class HubSection {
  final List<String> title;
  final List<String> ids;
  const HubSection({required this.title, required this.ids});
}

/// A tile on the hub's home screen that opens a list of variant games.
class HubGroup {
  final String id;
  final List<String> title;
  final List<String> tagline;
  final Color seedColor;
  final IconData icon;
  final List<GameConfig> games;

  const HubGroup({
    required this.id,
    required this.title,
    required this.tagline,
    required this.seedColor,
    required this.icon,
    required this.games,
  });
}

/// Device-level services shared by all games inside a hub.
class HubServices {
  final PrefsBackend backend;
  final ErrorJournal errors;
  final AnalyticsQueue analytics;
  final EmergencyConfig emergency;
  final PerformanceMonitor perf;
  final AdsService ads;
  final PurchaseService purchases;
  final AudioService audio;
  final Map<String, AppState> _states = {};

  /// Merkez genelinde bir kez sorulan gizlilik tercihi: 'granted' / 'denied'.
  String? consent;

  /// Merkez genelindeki kalıcı satın almalar (reklamsız, premium).
  Set<String> entitlements = {};

  /// Şu an açık olan oyun: tüketilen ürünler (altın, ipucu) ona yazılır.
  AppState? active;

  /// Son geçiş reklamı (tüm oyunlar için ortak); en az 3 dakika ara.
  int lastInterstitialMs = 0;
  static const _adGap = Duration(minutes: 3);
  bool _purchasesStarted = false;

  Future<void> loadShared() async {
    consent = await backend.read('hub.consent');
    final e = await backend.read('hub.entitlements');
    entitlements = e == null || e.isEmpty ? {} : e.split(',').toSet();
    lastInterstitialMs = int.tryParse(await backend.read('hub.lastAd') ?? '') ?? 0;
  }

  void _applyEntitlements(AppState s) {
    final save = s.save;
    for (final id in Products.nonConsumable) {
      if (entitlements.contains(id)) {
        save.ownedProducts.add(id);
      } else {
        save.ownedProducts.remove(id);
      }
    }
    save.premium = entitlements.contains(Products.premium);
    save.removeAds = save.premium || entitlements.contains(Products.removeAds);
    if (entitlements.contains(Products.starterPack)) save.starterBought = true;
    // Premium hediyesi merkezdeki her oyuna bir kez yüklenir.
    if (save.premium && !save.premiumGift) {
      Products.grantFor(Products.premium).applyTo(save);
      save.premiumGift = true;
    }
  }

  void _onPurchase(PurchaseEvent e) {
    final target = active ?? (_states.isEmpty ? null : _states.values.first);
    if (target == null) return;
    target.onPurchase(e);
    // Kalıcı ürünler merkezin her oyununa geçer.
    entitlements = {
      for (final id in Products.nonConsumable)
        if (target.save.ownedProducts.contains(id)) id,
      if (target.save.starterBought || entitlements.contains(Products.starterPack)) Products.starterPack,
    };
    unawaited(backend.write('hub.entitlements', entitlements.join(',')));
    for (final s in _states.values) {
      _applyEntitlements(s);
      if (!identical(s, target)) s.changed();
    }
  }

  Future<void> setConsent(bool acceptAll) async {
    consent = acceptAll ? 'granted' : 'denied';
    await backend.write('hub.consent', consent!);
    for (final s in _states.values) {
      s.applyConsent(acceptAll);
    }
  }

  HubServices({
    required this.backend,
    required this.errors,
    required this.analytics,
    required this.emergency,
    required this.perf,
    required this.ads,
    required this.purchases,
    required this.audio,
  });

  /// Telefon değişimi için: bütün oyunların kayıtları (oyun kimliği → kayıt).
  void registerTransfer(List<GameConfig> games) {
    Online.instance.exportAll = () async {
      for (final st in _states.values) {
        await st.flushSave();
      }
      final out = <String, String>{};
      for (final g in games) {
        final d = await SaveStore(backend, prefix: g.gameId).load();
        out[g.gameId] = d.encode();
      }
      return out;
    };
    Online.instance.importAll = (blobs) async {
      for (final e in blobs.entries) {
        await SaveStore(backend, prefix: e.key).save(SaveData.decode(e.value));
      }
      _states.clear();
    };
  }

  /// Lazily starts a game's session the first time it is opened.
  Future<AppState> stateFor(GameConfig config) async {
    final cached = _states[config.gameId];
    if (cached != null) return cached;
    final session = GameSession(
      rules: config.rules,
      store: SaveStore(backend, prefix: config.gameId),
      emergency: emergency,
      analytics: analytics,
      errors: errors,
    );
    final report = await session.start(safeMode: errors.safeMode);
    if (session.save.language.isEmpty) {
      session.save.language = Strings.pickLanguage(PlatformDispatcher.instance.locale.languageCode);
    }
    final state = AppState(
      config: config,
      session: session,
      audio: audio,
      ads: ads,
      purchases: purchases,
      analytics: analytics,
      errors: errors,
      perf: perf,
    )..startup = report;
    _states[config.gameId] = state;
    final c = consent;
    if (c != null && !session.save.ageGateDone) state.applyConsent(c == 'granted');
    state
      ..hubManaged = true
      ..adGate = (() => DateTime.now().millisecondsSinceEpoch - lastInterstitialMs >= _adGap.inMilliseconds)
      ..onInterstitialShown = () {
        lastInterstitialMs = DateTime.now().millisecondsSinceEpoch;
        unawaited(backend.write('hub.lastAd', '$lastInterstitialMs'));
      };
    _applyEntitlements(state);
    if (!_purchasesStarted) {
      _purchasesStarted = true;
      unawaited(purchases.init(_onPurchase));
    }
    await state.afterStart();
    return state;
  }

  void onPaused() {
    for (final s in _states.values) {
      s.onPaused();
    }
  }

  void onResumed() {
    for (final s in _states.values) {
      s.onResumed();
    }
  }
}

/// Entry point of a hub app's `main()`.
void bootstrapHub(HubConfig hub) {
  final startWatch = Stopwatch()..start();
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    final backend = await PrefsBackend.create();
    final errors = ErrorJournal(backend);
    await errors.beginLaunch();
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      errors.record(ErrorCategory.crash, details.exceptionAsString());
      CloudTelemetry.recordFlutter(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      errors.record(ErrorCategory.crash, error, fatal: true);
      CloudTelemetry.recordError(error, stack, fatal: true);
      return true;
    };
    final emergency = EmergencyConfig();
    try {
      final raw = await rootBundle.loadString('assets/config/emergency.json');
      emergency.merge(Map<String, Object?>.from(jsonDecode(raw) as Map));
    } catch (_) {/* optional file */}
    if (errors.safeMode) emergency.adsDisabled = true;
    final analytics = AnalyticsQueue(backend);
    await analytics.restore();
    final perf = PerformanceMonitor();
    final services = HubServices(
      backend: backend,
      errors: errors,
      analytics: analytics,
      emergency: emergency,
      perf: perf,
      ads: AdsService.create(),
      purchases: PurchaseService.create(),
      audio: AudioService(),
    );
    await services.loadShared();
    services.registerTransfer(hub.allGames);
    runApp(HubApp(hub: hub, services: services));
    unawaited(CloudTelemetry.init(crashReports: true, measurement: false));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Adaptive.applyOrientationPolicy();
      perf.recordStartup(startWatch.elapsedMilliseconds);
      await errors.launchSucceeded();
    });
  }, (error, stack) {
    debugPrint('Uncaught: $error');
  });
}

class HubApp extends StatefulWidget {
  final HubConfig hub;
  final HubServices services;
  const HubApp({super.key, required this.hub, required this.services});

  @override
  State<HubApp> createState() => _HubAppState();
}

class _HubAppState extends State<HubApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() => Adaptive.applyOrientationPolicy();

  @override
  Widget build(BuildContext context) {
    final lang = Strings.pickLanguage(PlatformDispatcher.instance.locale.languageCode);
    return MaterialApp(
      title: widget.hub.localized(widget.hub.title, lang),
      debugShowCheckedModeBanner: false,
      theme: buildTheme(widget.hub.seedColor, Brightness.light),
      darkTheme: buildTheme(widget.hub.seedColor, Brightness.dark),
      locale: Locale(lang),
      supportedLocales: Strings.languages.map(Locale.new).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: widget.services.consent == null
          ? _HubConsentPage(
              hub: widget.hub,
              lang: lang,
              onChoice: (all) async {
                await widget.services.setConsent(all);
                if (mounted) setState(() {});
              },
            )
          : HubHome(hub: widget.hub, services: widget.services, lang: lang),
    );
  }
}

/// İlk açılış: merkez için tek seferlik gizlilik tercihi (yaş sorulmaz).
class _HubConsentPage extends StatelessWidget {
  final HubConfig hub;
  final String lang;
  final Future<void> Function(bool acceptAll) onChoice;
  const _HubConsentPage({required this.hub, required this.lang, required this.onChoice});

  @override
  Widget build(BuildContext context) {
    final t = Strings(lang);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              shrinkWrap: true,
              children: [
                Icon(hub.icon, size: 96, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 12),
                Text(hub.localized(hub.title, lang),
                    textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                Text(t.t('consent_title'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(t.t('consent_body')),
                const SizedBox(height: 24),
                FilledButton(onPressed: () => onChoice(true), child: Text(t.t('accept_all'))),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: () => onChoice(false), child: Text(t.t('essential_only'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

typedef _Entry = (String, List<String>, List<String>, Color, IconData, VoidCallback, bool);

class HubHome extends StatefulWidget {
  final HubConfig hub;
  final HubServices services;
  final String lang;

  /// When set, the page lists this group's games instead of the hub's.
  final HubGroup? group;
  const HubHome({super.key, required this.hub, required this.services, required this.lang, this.group});

  @override
  State<HubHome> createState() => _HubHomeState();
}

class _HubHomeState extends State<HubHome> {
  String? _opening;

  @override
  void initState() {
    super.initState();
    if (widget.group == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final hub = widget.hub;
        unawaited(_firstRunGuide());
        unawaited(OnlineHost.attach(context, Strings(widget.lang), (id) {
          for (final g in hub.allGames) {
            if (g.gameId == id) return hub.localized(g.title, widget.lang);
          }
          return id;
        }, _openFor));
      });
    }
  }

  static const _guideKey = 'hub.guide.v1';

  /// İlk açılışta: kaç oyun olduğu, önerilen ilk oyunlar ve üç kısa bilgi.
  Future<void> _firstRunGuide() async {
    final backend = widget.services.backend;
    if (await backend.read(_guideKey) != null || !mounted) return;
    await backend.write(_guideKey, '1');
    final hub = widget.hub;
    final s = Strings(widget.lang);
    final all = hub.allGames;
    final picks = <GameConfig>[
      for (final id in hub.starters)
        for (final g in all)
          if (g.gameId == id) g,
    ];
    if (picks.isEmpty) picks.addAll(all.take(3));
    if (!mounted) return;
    final chosen = await showModalBottomSheet<GameConfig>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (c) => SafeArea(
        key: const ValueKey('hub-guide'),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, mainAxisSize: MainAxisSize.min, children: [
            Text(s.t('hub_welcome'), style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(s.t('hub_welcome_body', {'n': all.length})),
            const SizedBox(height: 12),
            for (final g in picks.take(3))
              Card(
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: g.seedColor.withValues(alpha: 0.18), child: Icon(g.icon, color: g.seedColor)),
                  title: Text(hub.localized(g.title, widget.lang), style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(hub.localized(g.tagline, widget.lang), maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: const Icon(Icons.play_arrow_rounded),
                  onTap: () => Navigator.pop(c, g),
                ),
              ),
            const SizedBox(height: 12),
            Text(s.t('hub_tips'), style: Theme.of(c).textTheme.bodyMedium?.copyWith(height: 1.5)),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: () => Navigator.pop(c), child: Text(s.t('hub_browse'))),
          ]),
        ),
      ),
    );
    if (chosen != null && mounted) unawaited(_open(chosen));
  }

  /// Davet ya da yarım maç: oyuna gidip [action]'ı onun ekranında çalıştırır.
  Future<bool> _openFor(String gameId, Future<void> Function(BuildContext, AppState) action) async {
    GameConfig? g;
    for (final x in widget.hub.allGames) {
      if (x.gameId == gameId) g = x;
    }
    if (g == null || !mounted) return false;
    // Başka bir oyundaysa ya da alt listedeyse önce ana listeye dön.
    Navigator.of(context).popUntil((r) => r.isFirst);
    final state = await widget.services.stateFor(g);
    state.pendingOnline = (c) => action(c, state);
    if (!mounted) return false;
    _opening = null;
    unawaited(_open(g));
    return true;
  }

  Future<void> _open(GameConfig g) async {
    if (_opening != null) return;
    setState(() => _opening = g.gameId);
    try {
      final state = await widget.services.stateFor(g);
      if (!mounted) return;
      state.onResumed();
      widget.services.active = state;
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => HubGamePage(state: state, backLabel: widget.hub.localized(_backLabel, widget.lang)),
      ));
      widget.services.active = null;
      state.onPaused(); // flush saves when returning to the list
    } finally {
      if (mounted) setState(() => _opening = null);
    }
  }

  static const _backLabel = ['Oyunlar', 'Games', 'Spiele', 'Juegos', 'Jeux'];

  void _openGroup(HubGroup g) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => HubHome(hub: widget.hub, services: widget.services, lang: widget.lang, group: g),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final hub = widget.hub;
    final lang = widget.lang;
    final group = widget.group;
    final entries = <_Entry>[
      if (group == null)
        for (final g in hub.groups)
          (g.id, g.title, ['${g.games.length} · ${hub.localized(g.tagline, lang)}'], g.seedColor, g.icon,
              () => _openGroup(g), true),
      for (final g in group?.games ?? hub.games)
        (g.gameId, g.title, g.tagline, g.seedColor, g.icon, () => _open(g), false),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(hub.localized(group?.title ?? hub.title, lang)),
        centerTitle: true,
      ),
      body: LayoutBuilder(builder: (context, cons) {
        final cols = (cons.maxWidth / 320).floor().clamp(1, 4);
        final delegate = SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.6,
        );
        final featured = group == null && hub.games.length > 1 ? hub.games[weekIndex(DateTime.now()) % hub.games.length] : null;
        final sisters = group == null && (kIsWeb || defaultTargetPlatform == TargetPlatform.android)
            ? [for (final a in studioApps) if (a.hubId != hub.hubId) a]
            : const <StudioApp>[];
        return CustomScrollView(slivers: [
          if (featured != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(child: _featuredCard(context, featured)),
            ),
          for (final (heading, list) in _sectioned(entries, group == null ? hub.sections : const [])) ...[
            if (heading != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: Text('${hub.localized(heading, lang)} · ${list.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              sliver: SliverGrid.builder(
                gridDelegate: delegate,
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final (id, title, tagline, color, icon, onTap, isGroup) = list[i];
                  return _tile(context, id, title, tagline, color, icon, onTap,
                      trailing: isGroup ? Icons.chevron_right_rounded : Icons.play_arrow_rounded);
                },
              ),
            ),
          ],
          if (sisters.isNotEmpty) ...[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Text(hub.localized(kMoreApps, lang), style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.builder(
                gridDelegate: delegate,
                itemCount: sisters.length,
                itemBuilder: (context, i) {
                  final a = sisters[i];
                  return _tile(context, a.hubId, a.title, const ['Google Play'], a.color, a.icon,
                      () => launchUrl(a.playUrl, mode: LaunchMode.externalApplication),
                      trailing: Icons.open_in_new_rounded);
                },
              ),
            ),
          ],
        ]);
      }),
    );
  }

  /// Girdileri bölümlere ayırır; hiçbir bölümde olmayanlar başlıksız en sona.
  List<(List<String>?, List<_Entry>)> _sectioned(List<_Entry> entries, List<HubSection> sections) {
    if (sections.isEmpty) return [(null, entries)];
    final byId = {for (final e in entries) e.$1: e};
    final used = <String>{};
    final out = <(List<String>?, List<_Entry>)>[];
    for (final s in sections) {
      final list = [for (final id in s.ids) if (byId[id] != null && used.add(id)) byId[id]!];
      if (list.isNotEmpty) out.add((s.title, list));
    }
    final rest = [for (final e in entries) if (!used.contains(e.$1)) e];
    if (rest.isNotEmpty) out.add((null, rest));
    return out;
  }

  /// Ana ekranın başındaki "haftanın oyunu" kartı.
  Widget _featuredCard(BuildContext context, GameConfig g) {
    final hub = widget.hub, lang = widget.lang;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '${hub.localized(kWeekTitle, lang)}: ${hub.localized(g.title, lang)}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _open(g),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [g.seedColor, Color.lerp(g.seedColor, Colors.black, 0.35)!]),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Icon(g.icon, color: Colors.white, size: 44),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hub.localized(kWeekTitle, lang).toUpperCase(),
                      style: text.labelSmall?.copyWith(color: Colors.white70, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text(hub.localized(g.title, lang),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(hub.localized(kWeekSubtitle, lang),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodySmall?.copyWith(color: Colors.white70)),
                ]),
              ),
              _opening == g.gameId
                  ? const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, String id, List<String> title, List<String> tagline, Color color, IconData icon,
      VoidCallback onTap,
      {required IconData trailing}) {
    final hub = widget.hub, lang = widget.lang;
    final scheme = Theme.of(context).colorScheme;
    final busy = _opening == id;
    return Semantics(
      button: true,
      label: hub.localized(title, lang),
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Color.alphaBlend(color.withValues(alpha: 0.18), scheme.surface),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: color,
                child: busy
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hub.localized(title, lang),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(tagline.length == 1 ? tagline.first : hub.localized(tagline, lang),
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(trailing),
            ]),
          ),
        ),
      ),
    );
  }
}

/// One game inside the hub: the game's own app shell. Its home screen shows
/// a "back to games" button that returns to the hub's list.
class HubGamePage extends StatelessWidget {
  final AppState state;
  final String backLabel;
  const HubGamePage({super.key, required this.state, required this.backLabel});

  @override
  Widget build(BuildContext context) {
    state.exitToHub = () {
      Navigator.of(context).pop();
    };
    state.exitToHubLabel = backLabel;
    return ProviderScope(
      overrides: [appStateProvider.overrideWith((ref) => state)],
      child: GameApp(state: state),
    );
  }
}
