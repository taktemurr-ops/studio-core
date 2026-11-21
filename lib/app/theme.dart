import 'package:flutter/material.dart';

/// World themes (one per 100-level world, cycling) and piece skins.
class Palettes {
  static const themes = <List<Color>>[
    [Color(0xFF1B2A49), Color(0xFF465881)], // midnight
    [Color(0xFF0F4C5C), Color(0xFF2A9D8F)], // lagoon
    [Color(0xFF3D1E6D), Color(0xFF8E44AD)], // galaxy
    [Color(0xFF7F2704), Color(0xFFE76F51)], // desert
    [Color(0xFF1E5128), Color(0xFF4E9F3D)], // forest
    [Color(0xFF2B2D42), Color(0xFF8D99AE)], // stone
    [Color(0xFF4A0E4E), Color(0xFFD7263D)], // volcano
    [Color(0xFF023E8A), Color(0xFF48CAE4)], // ocean
    [Color(0xFF5F0F40), Color(0xFFFB8B24)], // sunset
    [Color(0xFF283618), Color(0xFFBC6C25)], // autumn
    [Color(0xFF14213D), Color(0xFFFCA311)], // night city
    [Color(0xFF0B3954), Color(0xFFBFD7EA)], // ice
  ];

  static List<Color> theme(int i) => themes[i % themes.length];

  static int themeIndex(String id) => int.tryParse(id.split('_').last) ?? 0;

  /// 24 skins, each 8 piece colors.
  static List<Color> skin(int i) {
    final hueShift = (i * 37) % 360;
    final sat = i % 3 == 0 ? 0.75 : (i % 3 == 1 ? 0.6 : 0.85);
    final light = i % 4 == 3 ? 0.62 : 0.55;
    return List.generate(8, (k) {
      final h = (hueShift + k * 45) % 360;
      return HSLColor.fromAHSL(1, h.toDouble(), sat, light).toColor();
    });
  }

  /// Symbols drawn on top of colors in color-blind mode.
  static const symbols = ['●', '■', '▲', '◆', '★', '✚', '♥', '⬟', '✱', '☾'];
}

ThemeData buildTheme(Color seed, Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
