import 'package:shared_preferences/shared_preferences.dart';

import '../../core/save_store.dart';

/// SharedPreferences works on Android, iOS and Web with no native setup.
class PrefsBackend implements KeyValueBackend {
  final SharedPreferences prefs;
  PrefsBackend(this.prefs);

  static Future<PrefsBackend> create() async =>
      PrefsBackend(await SharedPreferences.getInstance());

  @override
  Future<String?> read(String key) async => prefs.getString(key);

  @override
  Future<void> write(String key, String value) async {
    final ok = await prefs.setString(key, value);
    if (!ok) throw StateError('write failed: $key');
  }

  @override
  Future<void> remove(String key) async {
    await prefs.remove(key);
  }
}
