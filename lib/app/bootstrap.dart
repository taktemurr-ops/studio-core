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
import 'game_api.dart';
import 'screens/home.dart';
import 'screens/onboarding.dart';
import 'services/ads.dart';
import 'services/audio.dart';
import 'services/prefs_backend.dart';
import 'services/purchases.dart';
import 'studio_look.dart';
import 'services/cloud_telemetry.dart';

/// Shared entry point used by every game's `main()`.
void bootstrap(GameConfig config) {
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

    final session = GameSession(
      rules: config.rules,
      store: SaveStore(backend, prefix: config.gameId),
      emergency: emergency,
      analytics: analytics,
      errors: errors,
    );
    final report = await session.start(safeMode: errors.safeMode);
    if (session.save.language.isEmpty) {
      session.save.language =
          Strings.pickLanguage(PlatformDispatcher.instance.locale.languageCode);
    }

    final perf = PerformanceMonitor();
    final state = AppState(
      config: config,
      session: session,
      audio: AudioService(),
      ads: AdsService.create(),
      purchases: PurchaseService.create(),
      analytics: analytics,
      errors: errors,
      perf: perf,
    )..startup = report;

    runApp(ProviderScope(
      overrides: [appStateProvider.overrideWith((ref) => state)],
      child: GameApp(state: state),
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Adaptive.applyOrientationPolicy();
      perf.recordStartup(startWatch.elapsedMilliseconds);
      await errors.launchSucceeded();
      await state.afterStart();
    });
    WidgetsBinding.instance.addTimingsCallback((timings) {
      for (final t in timings) {
        perf.recordFrame(t.buildDuration.inMicroseconds, t.rasterDuration.inMicroseconds);
      }
    });
  }, (error, stack) {
    debugPrint('Uncaught: $error');
  });
}

class GameApp extends ConsumerStatefulWidget {
  final AppState state;
  const GameApp({super.key, required this.state});

  @override
  ConsumerState<GameApp> createState() => _GameAppState();
}

class _GameAppState extends ConsumerState<GameApp> with WidgetsBindingObserver {
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
  void didChangeMetrics() {
    // Foldables, iPad Split View / Stage Manager, Android multi-window.
    Adaptive.applyOrientationPolicy();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    final app = widget.state;
    if (s == AppLifecycleState.paused || s == AppLifecycleState.detached) {
      app.onPaused();
    } else if (s == AppLifecycleState.resumed) {
      app.onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appStateProvider);
    final lang = app.strings.lang;
    // Merkezden açıldıysa merkezin onaylı paleti, yoksa oyunun renginden
    // türetilen koyu palet: oyun içi her ekran merkezle aynı tasarımda.
    final look = StudioLookScope.maybeOf(context) ?? StudioLook.fromSeed(app.config.seedColor);
    final theme = buildStudioTheme(look);
    return MaterialApp(
      title: app.title,
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: ThemeMode.dark,
      locale: Locale(lang),
      supportedLocales: Strings.languages.map(Locale.new).toList(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        // Yazı boyutu sistem ayarından gelir (erişilebilirlik); en çok 1.6x.
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.6),
            disableAnimations: app.save.reducedMotion || mq.disableAnimations,
          ),
          child: StudioLookScope(look: look, child: child ?? const SizedBox.shrink()),
        );
      },
      home: app.needsOnboarding ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}
