import 'package:flutter/material.dart';

/// World themes (one per 100-level world, cycling) and piece skins.
class Palettes {
  /// Dünya arka planları: koyu, yumuşak geçişli; parçaların renkleri öne çıkar.
  static const themes = <List<Color>>[
    [Color(0xFF13203B), Color(0xFF2E4A7A)], // İznik gecesi
    [Color(0xFF0C3B45), Color(0xFF1F7A72)], // lagün
    [Color(0xFF2A1745), Color(0xFF5C3A8C)], // mor akşam
    [Color(0xFF4A1F12), Color(0xFFA0482E)], // kızıl kaya
    [Color(0xFF15361F), Color(0xFF3C7A44)], // çam
    [Color(0xFF22252F), Color(0xFF4F586B)], // bazalt
    [Color(0xFF3A0F2A), Color(0xFF8A2546)], // nar
    [Color(0xFF062F5A), Color(0xFF1C6FA3)], // derin deniz
    [Color(0xFF3B1730), Color(0xFFB4562C)], // gün batımı
    [Color(0xFF26301A), Color(0xFF7A6A2E)], // zeytinlik
    [Color(0xFF0F1A2E), Color(0xFF6A4B1F)], // fener
    [Color(0xFF0E2F44), Color(0xFF4E7F99)], // kış sabahı
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
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  );
  // Yüzeyleri hafifçe sıcak tona çek: düz gri/beyaz yerine kâğıt ve gece mavisi.
  final scheme = base.copyWith(
    surface: dark ? const Color(0xFF141821) : const Color(0xFFFBF8F3),
    surfaceContainerLowest: dark ? const Color(0xFF0F121A) : const Color(0xFFFFFFFF),
    surfaceContainerLow: dark ? const Color(0xFF1A1F2A) : const Color(0xFFF6F2EB),
    surfaceContainer: dark ? const Color(0xFF1E2430) : const Color(0xFFF1ECE3),
    surfaceContainerHigh: dark ? const Color(0xFF242B38) : const Color(0xFFEBE5DA),
    surfaceContainerHighest: dark ? const Color(0xFF2B3341) : const Color(0xFFE4DDD0),
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
      elevation: 0,
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
