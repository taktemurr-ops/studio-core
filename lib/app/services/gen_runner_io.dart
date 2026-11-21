import 'dart:io' show Platform;
import 'dart:isolate';

import '../../core/game_rules.dart';
import '../../core/level_plan.dart';

/// Telefon/tablet: bölüm üretimi (çözücüyle doğrulama) ayrı iş parçacığında,
/// ekran donmaz. Testlerde ve gönderilemeyen kurallarda doğrudan üretilir.
Future<GeneratedLevel> runBuild(GameRules rules, LevelSpec spec) async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) return rules.build(spec);
  try {
    return await Isolate.run(() => rules.build(spec));
  } on ArgumentError {
    return rules.build(spec);
  }
}
