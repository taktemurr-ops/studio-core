/// studio_core: shared engine for every game and hub app.
///
/// Games import the parts they need, e.g.
/// `package:studio_core/app/game_api.dart` and `package:studio_core/core/rng.dart`.
/// A game app's `main()` is just `bootstrap(gameConfig)`.
library;

export 'app/bootstrap.dart';
export 'app/game_api.dart';
export 'app/hub.dart';
