import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _plugin = FlutterLocalNotificationsPlugin();
bool _ready = false;

Future<void> _init() async {
  if (_ready) return;
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(requestAlertPermission: false, requestBadgePermission: false, requestSoundPermission: false),
  );
  await _plugin.initialize(settings);
  _ready = true;
}

Future<bool> setDaily(bool enabled, String title, String body) async {
  if (!(Platform.isAndroid || Platform.isIOS)) return false;
  try {
    await _init();
    await _plugin.cancel(1);
    if (!enabled) return true;
    bool granted = true;
    if (Platform.isAndroid) {
      granted = await _plugin
              .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          true;
    } else {
      granted = await _plugin
              .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, sound: true) ??
          false;
    }
    if (!granted) return false;
    const details = NotificationDetails(
      android: AndroidNotificationDetails('daily', 'Daily reminder', importance: Importance.defaultImportance),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.periodicallyShow(1, title, body, RepeatInterval.daily, details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle);
    return true;
  } catch (_) {
    return false;
  }
}
