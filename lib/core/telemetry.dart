import 'dart:convert';

import 'save_store.dart';

/// One analytics event.
class AnalyticsEvent {
  final String name;
  final Map<String, Object> params;
  final int atMs;

  AnalyticsEvent(this.name, this.params, this.atMs);

  Map<String, Object> toJson() => {'n': name, 'p': params, 't': atMs};

  static AnalyticsEvent? fromJson(Object? j) {
    if (j is! Map) return null;
    final n = j['n'];
    final t = j['t'];
    final p = j['p'];
    if (n is! String || t is! num) return null;
    return AnalyticsEvent(
        n, p is Map ? p.map((k, v) => MapEntry('$k', v as Object)) : {}, t.toInt());
  }
}

/// Where events go when online (Firebase Analytics adapter, or any other).
abstract class AnalyticsSink {
  /// Returns true when the batch was accepted.
  Future<bool> send(List<AnalyticsEvent> batch);
}

class NoopSink implements AnalyticsSink {
  @override
  Future<bool> send(List<AnalyticsEvent> batch) async => true;
}

/// Offline-first analytics (doc 6.1: "İnternet geldiğinde gönderilir").
/// Events are persisted, capped, and flushed in batches; a failed flush
/// keeps the events for the next attempt. Disabled without consent.
class AnalyticsQueue {
  final KeyValueBackend backend;
  final String key;
  final int maxEvents;
  final List<AnalyticsEvent> _events = [];
  bool enabled;

  AnalyticsQueue(this.backend,
      {this.key = 'gs100.analytics', this.maxEvents = 2000, this.enabled = false});

  int get length => _events.length;

  Future<void> restore() async {
    final raw = await backend.read(key);
    if (raw == null) return;
    try {
      final list = jsonDecode(raw);
      if (list is List) {
        for (final j in list) {
          final e = AnalyticsEvent.fromJson(j);
          if (e != null) _events.add(e);
        }
      }
    } catch (_) {
      await backend.remove(key);
    }
  }

  Future<void> _persist() async {
    try {
      await backend.write(key, jsonEncode(_events.map((e) => e.toJson()).toList()));
    } catch (_) {/* storage full: keep in memory */}
  }

  Future<void> log(String name, [Map<String, Object> params = const {}]) async {
    if (!enabled) return;
    _events.add(AnalyticsEvent(name, params, DateTime.now().millisecondsSinceEpoch));
    if (_events.length > maxEvents) {
      _events.removeRange(0, _events.length - maxEvents);
    }
    await _persist();
  }

  Future<int> flush(AnalyticsSink sink, {int batchSize = 100}) async {
    var sent = 0;
    while (_events.isNotEmpty) {
      final batch = _events.take(batchSize).toList();
      bool ok;
      try {
        ok = await sink.send(batch);
      } catch (_) {
        ok = false;
      }
      if (!ok) break;
      _events.removeRange(0, batch.length);
      sent += batch.length;
    }
    await _persist();
    return sent;
  }

  Future<void> clear() async {
    _events.clear();
    await backend.remove(key);
  }
}

enum ErrorCategory { crash, save, levelGen, ads, purchase, network, performance, other }

class ErrorRecord {
  final ErrorCategory category;
  final String message;
  final int atMs;
  final bool fatal;

  ErrorRecord(this.category, this.message, this.atMs, this.fatal);

  Map<String, Object> toJson() =>
      {'c': category.name, 'm': message, 't': atMs, 'f': fatal};
}

/// Local error journal + crash-loop detection (doc 8, 12.8, 12.9).
/// If the app crashes [crashLoopThreshold] times within a short window
/// right after launch, the next launch starts in SAFE MODE (ads off,
/// resume state dropped, effects reduced) so a bad state cannot brick it.
class ErrorJournal {
  final KeyValueBackend backend;
  final int maxRecords;
  final List<ErrorRecord> records = [];
  static const _key = 'gs100.errors';
  static const _launchKey = 'gs100.launch';

  static const int crashLoopThreshold = 3;

  ErrorJournal(this.backend, {this.maxRecords = 200});

  int pendingLaunchFailures = 0;
  bool safeMode = false;

  /// Call first thing on startup.
  Future<void> beginLaunch() async {
    final raw = await backend.read(_launchKey);
    final n = int.tryParse(raw ?? '') ?? 0;
    pendingLaunchFailures = n;
    safeMode = n >= crashLoopThreshold;
    await backend.write(_launchKey, '${n + 1}');
  }

  /// Call once the first frame rendered and the player can interact.
  Future<void> launchSucceeded() async {
    await backend.write(_launchKey, '0');
  }

  Future<void> record(ErrorCategory c, Object error, {bool fatal = false}) async {
    var msg = error.toString();
    if (msg.length > 500) msg = msg.substring(0, 500);
    records.add(ErrorRecord(c, msg, DateTime.now().millisecondsSinceEpoch, fatal));
    if (records.length > maxRecords) records.removeAt(0);
    try {
      await backend.write(_key, jsonEncode(records.map((r) => r.toJson()).toList()));
    } catch (_) {}
  }

  int count(ErrorCategory c) => records.where((r) => r.category == c).length;
}

/// Startup / frame metrics (doc 8: açılış süresi, bellek, pil).
class PerformanceMonitor {
  final List<int> startupMs = [];
  int slowFrames = 0;
  int frames = 0;

  void recordStartup(int ms) {
    startupMs.add(ms);
    if (startupMs.length > 20) startupMs.removeAt(0);
  }

  void recordFrame(int buildMicros, int rasterMicros) {
    frames++;
    if (buildMicros + rasterMicros > 33000) slowFrames++;
  }

  double get slowFrameRate => frames == 0 ? 0 : slowFrames / frames;

  /// Low-power hint: reduce effects if many frames are slow.
  bool get shouldReduceEffects => frames > 300 && slowFrameRate > 0.15;
}

/// Kill switches (doc 12.15). Defaults are bundled; an optional remote JSON
/// can override them when online. Unknown keys are ignored.
class EmergencyConfig {
  bool adsDisabled;
  bool purchasesDisabled;
  bool analyticsDisabled;
  bool dailyEventsDisabled;
  int maxGeneratedLevel;
  String message;

  EmergencyConfig({
    this.adsDisabled = false,
    this.purchasesDisabled = false,
    this.analyticsDisabled = false,
    this.dailyEventsDisabled = false,
    this.maxGeneratedLevel = 1 << 30,
    this.message = '',
  });

  void merge(Map<String, Object?> j) {
    if (j['adsDisabled'] is bool) adsDisabled = j['adsDisabled'] as bool;
    if (j['purchasesDisabled'] is bool) purchasesDisabled = j['purchasesDisabled'] as bool;
    if (j['analyticsDisabled'] is bool) analyticsDisabled = j['analyticsDisabled'] as bool;
    if (j['dailyEventsDisabled'] is bool) {
      dailyEventsDisabled = j['dailyEventsDisabled'] as bool;
    }
    if (j['maxGeneratedLevel'] is num) {
      maxGeneratedLevel = (j['maxGeneratedLevel'] as num).toInt();
    }
    if (j['message'] is String) message = j['message'] as String;
  }
}
