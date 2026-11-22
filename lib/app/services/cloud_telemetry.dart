/// Çökme raporu (Crashlytics) ve temel ölçüm (Firebase Analytics).
///
/// Yalnızca Firebase yapılandırılmışsa (FIREBASE_* dart-define) ve mobilde
/// çalışır; aksi hâlde her çağrı sessizce hiçbir şey yapmaz.
/// * Çökme raporu: çocuk modunda kapalı, diğer herkeste açık (oyun hatalarını
///   düzeltmek için; kişisel veri içermez).
/// * Ölçüm: yalnızca kullanıcı izin verdiyse (Ayarlar > Gizlilik), reklam
///   kimliği toplanmaz (manifest'te kapalı).
library;

import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../core/telemetry.dart';
import '../../online/online_service.dart';

class CloudTelemetry {
  CloudTelemetry._();

  static bool _ready = false;
  static bool _crash = false;
  static bool _measure = false;

  static bool get supported =>
      OnlineConfig.configured &&
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  /// Açılışta bir kez (runApp'ten sonra) çağrılır.
  static Future<void> init({required bool crashReports, required bool measurement}) async {
    if (!supported) return;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: OnlineConfig.options);
      _ready = true;
      await setCrashReports(crashReports);
      await setMeasurement(measurement);
    } catch (_) {
      _ready = false;
    }
  }

  static Future<void> setCrashReports(bool on) async {
    if (!_ready) return;
    _crash = on;
    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(on);
    } catch (_) {}
  }

  static Future<void> setMeasurement(bool on) async {
    if (!_ready) return;
    _measure = on;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(on);
    } catch (_) {}
  }

  static void recordError(Object error, StackTrace? stack, {bool fatal = false}) {
    if (!_ready || !_crash) return;
    unawaited(FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal).catchError((_) {}));
  }

  static void recordFlutter(FlutterErrorDetails details) {
    if (!_ready || !_crash) return;
    unawaited(FirebaseCrashlytics.instance.recordFlutterFatalError(details).catchError((_) {}));
  }

  static void setKey(String key, Object value) {
    if (!_ready || !_crash) return;
    unawaited(FirebaseCrashlytics.instance.setCustomKey(key, value).catchError((_) {}));
  }

  /// Kuyruktaki olayların gideceği yer. Firebase yoksa olaylar düşer (kabul).
  static AnalyticsSink get sink => _FirebaseSink();
}

class _FirebaseSink implements AnalyticsSink {
  @override
  Future<bool> send(List<AnalyticsEvent> batch) async {
    if (!CloudTelemetry._ready || !CloudTelemetry._measure) return true;
    for (final e in batch) {
      final params = <String, Object>{
        for (final p in e.params.entries)
          _clean(p.key): p.value is num || p.value is String ? p.value : '${p.value}',
      };
      await FirebaseAnalytics.instance.logEvent(name: _clean(e.name), parameters: params);
    }
    return true;
  }

  /// Firebase olay/parametre adı: harf ile başlar, en çok 40 karakter, [a-z0-9_].
  static String _clean(String s) {
    var t = s.toLowerCase().replaceAll(RegExp('[^a-z0-9_]'), '_');
    if (t.isEmpty || !RegExp('^[a-z]').hasMatch(t)) t = 'e_$t';
    return t.length > 40 ? t.substring(0, 40) : t;
  }
}
