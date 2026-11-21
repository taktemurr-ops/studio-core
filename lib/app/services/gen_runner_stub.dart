import '../../core/game_rules.dart';
import '../../core/level_plan.dart';

/// Web: iş parçacığı yok, bölüm doğrudan üretilir.
Future<GeneratedLevel> runBuild(GameRules rules, LevelSpec spec) async => rules.build(spec);
