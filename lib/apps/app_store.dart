/// Uygulama araçları için cihazda kalan basit kayıt deposu.
///
/// Her araç kendi önekini kullanır (`app.<araç>.<anahtar>`); veriler
/// SharedPreferences üzerinden telefonda, tablette ve web'de saklanır.
library;

import 'dart:convert';

import '../core/save_store.dart';

class AppStore {
  final KeyValueBackend backend;
  final String prefix;

  const AppStore(this.backend, this.prefix);

  /// Aynı arka uçta başka bir araç için depo.
  AppStore child(String name) => AppStore(backend, '$prefix.$name');

  String _k(String key) => '$prefix.$key';

  Future<String?> read(String key) => backend.read(_k(key));

  Future<void> write(String key, String value) async {
    await backend.write(_k(key), value);
    await _remember(key);
  }

  Future<void> remove(String key) async {
    await backend.remove(_k(key));
  }

  Future<int> readInt(String key, [int fallback = 0]) async => int.tryParse(await read(key) ?? '') ?? fallback;

  Future<double> readDouble(String key, [double fallback = 0]) async =>
      double.tryParse(await read(key) ?? '') ?? fallback;

  Future<bool> readBool(String key, [bool fallback = false]) async {
    final v = await read(key);
    return v == null ? fallback : v == '1';
  }

  Future<void> writeBool(String key, bool v) => write(key, v ? '1' : '0');

  /// JSON nesnesi (harita) okur; yoksa ya da bozuksa boş harita döner.
  Future<Map<String, Object?>> readMap(String key) async {
    final raw = await read(key);
    if (raw == null || raw.isEmpty) return <String, Object?>{};
    try {
      final v = jsonDecode(raw);
      return v is Map ? Map<String, Object?>.from(v) : <String, Object?>{};
    } catch (_) {
      return <String, Object?>{};
    }
  }

  Future<void> writeMap(String key, Map<String, Object?> value) => write(key, jsonEncode(value));

  /// JSON listesi okur; her öğe bir harita.
  Future<List<Map<String, Object?>>> readList(String key) async {
    final raw = await read(key);
    if (raw == null || raw.isEmpty) return <Map<String, Object?>>[];
    try {
      final v = jsonDecode(raw);
      if (v is! List) return <Map<String, Object?>>[];
      return [
        for (final e in v)
          if (e is Map) Map<String, Object?>.from(e)
      ];
    } catch (_) {
      return <Map<String, Object?>>[];
    }
  }

  Future<void> writeList(String key, List<Map<String, Object?>> value) => write(key, jsonEncode(value));

  /// Metin listesi (virgülsüz güvenli: JSON).
  Future<List<String>> readStrings(String key) async {
    final raw = await read(key);
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final v = jsonDecode(raw);
      return v is List ? [for (final e in v) '$e'] : <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> writeStrings(String key, List<String> value) => write(key, jsonEncode(value));

  /// Bu depoya yazılmış bütün anahtarları siler ("verilerimi sil").
  Future<void> clearAll() async {
    final keys = await _keys();
    for (final k in keys) {
      await backend.remove(_k(k));
    }
    await backend.remove('$prefix.__keys');
  }

  Future<List<String>> _keys() async {
    final raw = await backend.read('$prefix.__keys');
    if (raw == null || raw.isEmpty) return <String>[];
    try {
      final v = jsonDecode(raw);
      return v is List ? [for (final e in v) '$e'] : <String>[];
    } catch (_) {
      return <String>[];
    }
  }

  Future<void> _remember(String key) async {
    final keys = await _keys();
    if (keys.contains(key)) return;
    keys.add(key);
    await backend.write('$prefix.__keys', jsonEncode(keys));
  }
}
