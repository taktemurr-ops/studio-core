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

  const HubConfig({
    required this.hubId,
    required this.title,
    required this.tagline,
    required this.seedColor,
    required this.icon,
    required this.games,
  });

  String localized(List<String> l, String lang) {
    const order = ['tr', 'en', 'de', 'es', 'fr'];
    final i = order.indexOf(lang);
    return l.length > i && i >= 0 ? l[i] : l[1];
  }
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
  const HubHome({super.key, required this.hub, required this.services, required this.lang});

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

  @override
  Widget build(BuildContext context) {
    final hub = widget.hub;
    final lang = widget.lang;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(hub.localized(hub.title, lang)),
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
          itemCount: hub.games.length,
          itemBuilder: (context, i) {
            final g = hub.games[i];
            final busy = _opening == g.gameId;
            return Semantics(
              button: true,
              label: g.localized(g.title, lang),
              child: Card(
                clipBehavior: Clip.antiAlias,
                color: Color.alphaBlend(g.seedColor.withValues(alpha: 0.18), scheme.surface),
                child: InkWell(
                  onTap: () => _open(g),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: g.seedColor,
                        child: busy
                            ? const SizedBox(
                                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Icon(g.icon, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(g.localized(g.title, lang),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(g.localized(g.tagline, lang),
                                maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      const Icon(Icons.play_arrow_rounded),
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
    state
      ..exitToHub = () => Navigator.of(context).pop()
      ..exitToHubLabel = backLabel;
    return ProviderScope(
      overrides: [appStateProvider.overrideWith((ref) => state)],
      child: GameApp(state: state),
    );
  }
}
