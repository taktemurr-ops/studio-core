import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/studio_apps.dart';

void main() {
  test('stüdyo uygulamaları 33 dilde ve benzersiz', () {
    expect(studioApps.map((a) => a.hubId).toSet().length, studioApps.length);
    for (final a in studioApps) {
      expect(a.title.length, 33, reason: a.hubId);
      expect(a.package, 'com.gamestudio100.${a.hubId.replaceAll('-', '_')}');
    }
    for (final l in [kWeekTitle, kWeekSubtitle, kMoreApps]) {
      expect(l.length, 33);
    }
  });

  test('haftanın oyunu pazartesi değişir', () {
    final mon = weekIndex(DateTime.utc(2026, 11, 23));
    expect(weekIndex(DateTime.utc(2026, 11, 29, 23)), mon);
    expect(weekIndex(DateTime.utc(2026, 11, 22, 23)), mon - 1);
    expect(weekIndex(DateTime.utc(2026, 11, 30)), mon + 1);
  });
}
