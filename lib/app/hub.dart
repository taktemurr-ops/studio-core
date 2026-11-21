import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/game_session.dart';
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
    const order = ['tr', 'en', 'de', 'es', 'fr'];
    final i = order.indexOf(lang);
    return l.length > i && i >= 0 ? l[i] : l[1];
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
      home: HubHome(hub: widget.hub, services: widget.services, lang: lang),
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
      await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => HubGamePage(state: state, backLabel: widget.hub.localized(_backLabel, widget.lang)),
      ));
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
    final scheme = Theme.of(context).colorScheme;
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
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.6,
          ),
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final (id, title, tagline, color, icon, onTap, isGroup) = entries[i];
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
                            ? const SizedBox(
                                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
                      Icon(isGroup ? Icons.chevron_right_rounded : Icons.play_arrow_rounded),
                    ]),
                  ),
                ),
              ),
            );
          },
        );
      }),
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
