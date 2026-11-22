/// Günlük hatırlatma bildirimi (telefonun kendisi gösterir, sunucu yok).
/// Web'de bildirim yoktur; mobilde `reminders_mobile.dart` kullanılır.
library;

import 'reminders_stub.dart' if (dart.library.io) 'reminders_mobile.dart' as impl;

class Reminders {
  /// Açıksa her gün bir kez hatırlatır; kapalıysa planlanmış olanı siler.
  /// İlk açılışta bildirim izni ister (Android 13+, iOS).
  static Future<bool> set(bool enabled, {required String title, required String body}) =>
      impl.setDaily(enabled, title, body);
}
