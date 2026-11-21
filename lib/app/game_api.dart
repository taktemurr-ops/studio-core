import 'package:flutter/material.dart';

import '../core/game_rules.dart';
import '../core/level_plan.dart';
import 'services/audio.dart';

/// Everything a game screen needs from the shell.
class PlayContext {
  final LevelSpec spec;

  /// The validated puzzle produced by [GameRules.build] for [spec].
  final GeneratedLevel generated;
  final Map<String, Object?> resume;
  final List<Color> pieceColors;
  final List<Color> background;
  final bool colorBlind;
  final bool reducedMotion;
  final bool leftHanded;
  final String lang;
  final String Function(String key, [Map<String, Object> params]) t;

  /// Ends the round; the shell shows results, rewards, achievements.
  final void Function(RoundResult result) finish;

  /// Persists an in-progress round so it can be resumed after the app is
  /// killed (doc 6.3 / 10: "uygulama kapanma testi").
  final void Function(Map<String, Object?> state) saveResume;

  /// Spends a hint (or offers a rewarded ad). True = hint granted.
  final Future<bool> Function() requestHint;

  /// Spends a booster (or offers coins). True = granted.
  final Future<bool> Function() requestBooster;

  /// Offers "continue" after a fail (ad or coins). True = keep playing.
  final Future<bool> Function() requestContinue;

  final void Function(Sfx s) sfx;

  /// Plays a named extra sound asset (piano notes, animal calls ...).
  final void Function(String name) sound;

  const PlayContext({
    required this.spec,
    required this.generated,
    required this.resume,
    required this.pieceColors,
    required this.background,
    required this.colorBlind,
    required this.reducedMotion,
    required this.leftHanded,
    required this.lang,
    required this.t,
    required this.finish,
    required this.saveResume,
    required this.requestHint,
    required this.requestBooster,
    required this.requestContinue,
    required this.sfx,
    this.sound = _noSound,
  });

  static void _noSound(String name) {}

  String symbol(int i) => const ['●', '■', '▲', '◆', '★', '✚', '♥', '⬟', '✱', '☾'][i % 10];
}

class TutorialStep {
  final IconData icon;
  final List<String> text; // tr, en, de, es, fr
  const TutorialStep(this.icon, this.text);
}

/// Per-game configuration consumed by the shared shell.
class GameConfig {
  final String gameId;
  final List<String> title; // tr, en, de, es, fr
  final List<String> tagline;
  final Color seedColor;
  final IconData icon;
  final GameRules rules;
  final Widget Function(PlayContext ctx) buildPlay;
  final List<TutorialStep> tutorial;
  final Map<String, List<String>> strings;
  final String privacyUrl;

  /// Designed-for-families title: every player is treated as a child
  /// (child-directed ads, no analytics), purchases sit behind a parental gate.
  final bool kidsMode;

  const GameConfig({
    required this.gameId,
    required this.title,
    required this.tagline,
    required this.seedColor,
    required this.icon,
    required this.rules,
    required this.buildPlay,
    required this.tutorial,
    this.strings = const {},
    this.privacyUrl = '',
    this.kidsMode = false,
  });

  String localized(List<String> l, String lang) {
    const order = ['tr', 'en', 'de', 'es', 'fr'];
    final i = order.indexOf(lang);
    return l.length > i && i >= 0 ? l[i] : l[1];
  }
}
