import 'package:flutter/material.dart';

/// World themes (one per 100-level world, cycling) and piece skins.
class Palettes {
  /// Dünya arka planları: koyu, yumuşak geçişli; parçaların renkleri öne çıkar.
  static const themes = <List<Color>>[
    [Color(0xFF1A2E5C), Color(0xFF3A6FC4)], // İznik gecesi
    [Color(0xFF0B4A55), Color(0xFF23A396)], // lagün
    [Color(0xFF34195C), Color(0xFF7B4CC2)], // mor akşam
    [Color(0xFF5A2414), Color(0xFFD0603A)], // kızıl kaya
    [Color(0xFF15452A), Color(0xFF45A05A)], // çam
    [Color(0xFF263049), Color(0xFF5D7196)], // bazalt
    [Color(0xFF4A1235), Color(0xFFC0395F)], // nar
    [Color(0xFF07386B), Color(0xFF2389C9)], // derin deniz
    [Color(0xFF4A1C3C), Color(0xFFE0743A)], // gün batımı
    [Color(0xFF2E3D1C), Color(0xFF9C8A35)], // zeytinlik
    [Color(0xFF142240), Color(0xFF9A6A28)], // fener
    [Color(0xFF103A55), Color(0xFF5E9CBE)], // kış sabahı
  ];

  static List<Color> theme(int i) => themes[i % themes.length];

  static int themeIndex(String id) => int.tryParse(id.split('_').last) ?? 0;

  /// Stüdyonun kendi parça paletleri: elle seçilmiş, birbirinden kolay ayrılan
  /// sekizer renk. Gri kullanılmaz (taşlar gridir). Her paletin ayrıca pastel
  /// ve koyu bir türevi var: toplam 24 görünüm.
  static const baseSkins = <List<Color>>[
    // 0 İznik çinisi
    [Color(0xFF3075C4), Color(0xFF2BB3B1), Color(0xFFE2574C), Color(0xFFF2A93B),
     Color(0xFF7BA05B), Color(0xFF9763BC), Color(0xFFE58FB0), Color(0xFFC9A66B)],
    // 1 Ege
    [Color(0xFF1E88C7), Color(0xFF4FC3C8), Color(0xFFF4D35E), Color(0xFFF08A4B),
     Color(0xFF3BA776), Color(0xFFE5566E), Color(0xFF8E7CC3), Color(0xFF6C8EAD)],
    // 2 Kapadokya
    [Color(0xFFC8553D), Color(0xFFF28F3B), Color(0xFFE9C46A), Color(0xFF6B9080),
     Color(0xFF3D7EA6), Color(0xFFB56576), Color(0xFF8E6C8A), Color(0xFFA98467)],
    // 3 Lale
    [Color(0xFFD7263D), Color(0xFFF46036), Color(0xFFFFB400), Color(0xFF5C6BC0),
     Color(0xFF1B998B), Color(0xFF9BC53D), Color(0xFFE85D9A), Color(0xFF8A5CF5)],
    // 4 Boğaz
    [Color(0xFF1A8BBB), Color(0xFF39A9DB), Color(0xFF5FC9A8), Color(0xFFF2C14E),
     Color(0xFFF78154), Color(0xFFCC5A82), Color(0xFF9483AA), Color(0xFF4D9078)],
    // 5 Çay bahçesi
    [Color(0xFF3E8C65), Color(0xFF52B788), Color(0xFFB7D36B), Color(0xFFD4A017),
     Color(0xFFC1502E), Color(0xFF9C6644), Color(0xFF8C74A3), Color(0xFF3A86A8)],
    // 6 Lavanta
    [Color(0xFF7E5BB5), Color(0xFFD07FCF), Color(0xFF5E8BD6), Color(0xFF4CB5AE),
     Color(0xFFF2A65A), Color(0xFFE0607E), Color(0xFFC9B458), Color(0xFF8FB35C)],
    // 7 Gece pazarı
    [Color(0xFFF25F5C), Color(0xFFFFE066), Color(0xFF247BA0), Color(0xFF70C1B3),
     Color(0xFFB388EB), Color(0xFFFF9F1C), Color(0xFFE36BAE), Color(0xFF7DCE82)],
  ];

  static const skinNames = [
    'İznik', 'Ege', 'Kapadokya', 'Lale', 'Boğaz', 'Çay bahçesi', 'Lavanta', 'Gece pazarı',
  ];

  /// 24 görünüm: 0-7 temel, 8-15 pastel, 16-23 koyu.
  static List<Color> skin(int i) {
    final base = baseSkins[i % baseSkins.length];
    final variant = (i ~/ baseSkins.length) % 3;
    if (variant == 0) return base;
    return [
      for (final c in base)
        () {
          final h = HSLColor.fromColor(c);
          return variant == 1
              ? h.withLightness((h.lightness + 0.14).clamp(0.0, 0.86)).withSaturation((h.saturation * 0.85).clamp(0.0, 1.0)).toColor()
              : h.withLightness((h.lightness - 0.12).clamp(0.18, 1.0)).withSaturation((h.saturation * 1.05).clamp(0.0, 1.0)).toColor();
        }(),
    ];
  }

  /// Symbols drawn on top of colors in color-blind mode.
  static const symbols = ['●', '■', '▲', '◆', '★', '✚', '♥', '⬟', '✱', '☾'];
}

/// Stüdyo görünümü: yumuşak köşeler, sıcak tonlu yüzeyler, sade çubuklar.
ThemeData buildTheme(Color seed, Brightness b) {
  final dark = b == Brightness.dark;
  final base = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: b,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  // Yüzeyler oyunun kendi renginden çok hafif bir tonla boyanır: her oyun
  // kendine özgü, ferah ve canlı görünür (düz bej/gri yerine).
  Color tint(Color c, double a) => Color.alphaBlend(seed.withValues(alpha: a), c);
  final scheme = base.copyWith(
    surface: dark ? tint(const Color(0xFF12151D), 0.06) : tint(const Color(0xFFF7F8FC), 0.05),
    surfaceContainerLowest: dark ? const Color(0xFF0F121A) : const Color(0xFFFFFFFF),
    surfaceContainerLow: dark ? tint(const Color(0xFF1A1F2A), 0.07) : tint(const Color(0xFFFFFFFF), 0.04),
    surfaceContainer: dark ? tint(const Color(0xFF1E2430), 0.08) : tint(const Color(0xFFF3F5FA), 0.07),
    surfaceContainerHigh: dark ? tint(const Color(0xFF242B38), 0.09) : tint(const Color(0xFFECEFF6), 0.09),
    surfaceContainerHighest: dark ? tint(const Color(0xFF2B3341), 0.10) : tint(const Color(0xFFE4E8F1), 0.11),
  );
  final radius = BorderRadius.circular(18);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2, color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      elevation: dark ? 0 : 1,
      shadowColor: seed.withValues(alpha: 0.18),
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
    ),
    listTileTheme: ListTileThemeData(shape: RoundedRectangleBorder(borderRadius: radius)),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLow,
      indicatorColor: scheme.primaryContainer,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 50),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}
