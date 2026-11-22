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
import 'studio_apps.dart';
import 'theme.dart';

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

  const HubConfig({
    required this.hubId,
    required this.title,
    required this.tagline,
    required this.seedColor,
    required this.icon,
    required this.games,
    this.groups = const [],
  });

  /// Every game in the hub, including those inside groups.
  List<GameConfig> get allGames => [...games, for (final g in groups) ...g.games];

  String localized(List<String> l, String lang) {
    return Strings.pick(l, lang);
  }
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
  }

  void _onPurchase(PurchaseEvent e) {
    final target = active ?? (_states.isEmpty ? null : _states.values.first);
    if (target == null) return;
    target.onPurchase(e);
    // Kalıcı ürünler merkezin her oyununa geçer.
    entitlements = {for (final id in Products.nonConsumable) if (target.save.ownedProducts.contains(id)) id};
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
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      errors.record(ErrorCategory.crash, error, fatal: true);
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
    runApp(HubApp(hub: hub, services: services));
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
    final entries = <(String, List<String>, List<String>, Color, IconData, VoidCallback, bool)>[
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
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid.builder(
              gridDelegate: delegate,
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final (id, title, tagline, color, icon, onTap, isGroup) = entries[i];
                return _tile(context, id, title, tagline, color, icon, onTap,
                    trailing: isGroup ? Icons.chevron_right_rounded : Icons.play_arrow_rounded);
              },
            ),
          ),
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
