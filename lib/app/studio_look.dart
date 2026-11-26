/// Stüdyonun ortak görünümü: onaylı merkez tasarımının ("Oyun Merkezleri ·
/// Tasarım Örnekleri 1–3") renkleri ve bu renklerden kurulan koyu tema.
///
/// Merkez ([bootstrapApprovedHub]) kendi paletini [StudioLookScope] ile
/// ağacın tepesine koyar; oyun ([GameApp]) ve araç ekranları aynı paleti
/// okur, böylece merkezden oyuna geçince tasarım değişmez. Palet yoksa
/// (tek oyunlu uygulama ya da eski merkez) oyunun kendi renginden koyu bir
/// palet türetilir ([StudioLook.fromSeed]).
library;

import 'package:flutter/material.dart';

/// Onaylı tasarımın renkleri. [ThemeData.extensions] içinde taşınır.
@immutable
class StudioLook extends ThemeExtension<StudioLook> {
  /// Arka plan degradesi (yukarıdan aşağı).
  final List<Color> background;

  /// Seçili sekme, çip, bağlantı ve vurgu rengi.
  final Color accent;

  /// Kart ve kutu zemini.
  final Color card;

  /// Oyna düğmesi rengi.
  final Color play;

  /// Büyük sayıların ("N Oyun", puan) rengi.
  final Color number;

  const StudioLook({
    this.background = const [Color(0xFF2A1A6E), Color(0xFF15104A), Color(0xFF0B0A2E)],
    this.accent = const Color(0xFF2FD3F5),
    this.card = const Color(0xFF3A2290),
    this.play = const Color(0xFF1FA2F2),
    this.number = Colors.white,
  });

  /// Oyunun kendi renginden koyu, canlı bir palet (merkez paleti yoksa).
  factory StudioLook.fromSeed(Color seed) {
    final h = HSLColor.fromColor(seed);
    final hue = h.hue;
    final sat = h.saturation < 0.15 ? 0.45 : h.saturation.clamp(0.45, 0.9);
    Color c(double s, double l, [double shift = 0]) =>
        HSLColor.fromAHSL(1, (hue + shift) % 360, s.clamp(0.0, 1.0), l.clamp(0.0, 1.0)).toColor();
    return StudioLook(
      background: [c(sat * 0.75, 0.25, -12), c(sat * 0.8, 0.15, -6), c(sat * 0.85, 0.08)],
      accent: c(sat, 0.64, 8),
      card: c(sat * 0.7, 0.32, -10),
      play: c(sat, 0.46),
      number: Colors.white,
    );
  }

  /// Ağaçtaki görünüm: tema uzantısı, sonra kapsam, en son temanın ana rengi.
  static StudioLook of(BuildContext context) {
    final theme = Theme.of(context);
    return theme.extension<StudioLook>() ??
        StudioLookScope.maybeOf(context) ??
        StudioLook.fromSeed(theme.colorScheme.primary);
  }

  /// Vurgu renginin üstündeki yazı rengi (okunurluk için).
  Color get onAccent => _onColor(accent);

  /// Oyna rengi üstündeki yazı rengi.
  /// Kalın, büyük düğme yazısı için beyaz tercih edilir (tasarımdaki gibi);
  /// beyazın karşıtlığı 3:1'in altına düşerse siyah.
  Color get onPlay => 1.05 / (play.computeLuminance() + 0.05) >= 3 ? Colors.white : Colors.black;

  /// En koyu zemin (sayfa ve alt çubuk).
  Color get base => background.last;

  /// Diyalog, alt sayfa ve açılır menü zemini.
  Color get sheet => Color.lerp(Color.lerp(card, base, 0.55)!, Colors.black, 0.18)!;

  /// Sayfa zemini.
  LinearGradient get backdrop =>
      LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: background);

  /// Oyun kutusu ve mod kartı degradesi.
  LinearGradient get tile => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color.lerp(card, Colors.white, 0.10)!, Color.lerp(card, Colors.black, 0.35)!],
  );

  /// Oyna düğmesi degradesi.
  LinearGradient get playGradient => LinearGradient(colors: [play, Color.lerp(play, Colors.white, 0.25)!]);

  /// "Hemen Oyna" turuncusu (tasarımdaki büyük eylem düğmesi).
  static const hot = [Color(0xFFFFB21F), Color(0xFFFF7A1A)];

  /// Ödül ve yıldız sarısı.
  static const gold = Color(0xFFFFC93C);

  /// Elmas moru.
  static const gem = Color(0xFFD36BFF);

  /// Başarı yeşili.
  static const good = Color(0xFF3BD45A);

  /// Uyarı kırmızısı.
  static const bad = Color(0xFFFF5A5A);

  /// Beyaz ya da siyahtan hangisi daha okunursa (WCAG karşıtlık oranı).
  static Color _onColor(Color c) {
    final l = c.computeLuminance();
    final onWhite = 1.05 / (l + 0.05);
    final onBlack = (l + 0.05) / 0.05;
    return onBlack > onWhite ? Colors.black : Colors.white;
  }

  @override
  StudioLook copyWith({List<Color>? background, Color? accent, Color? card, Color? play, Color? number}) => StudioLook(
    background: background ?? this.background,
    accent: accent ?? this.accent,
    card: card ?? this.card,
    play: play ?? this.play,
    number: number ?? this.number,
  );

  @override
  StudioLook lerp(covariant StudioLook? other, double t) {
    if (other == null) return this;
    final n = background.length > other.background.length ? background.length : other.background.length;
    Color at(List<Color> l, int i) => l[i < l.length ? i : l.length - 1];
    return StudioLook(
      background: [for (var i = 0; i < n; i++) Color.lerp(at(background, i), at(other.background, i), t)!],
      accent: Color.lerp(accent, other.accent, t)!,
      card: Color.lerp(card, other.card, t)!,
      play: Color.lerp(play, other.play, t)!,
      number: Color.lerp(number, other.number, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StudioLook &&
      other.accent == accent &&
      other.card == card &&
      other.play == play &&
      other.number == number &&
      _sameList(other.background, background);

  @override
  int get hashCode => Object.hash(accent, card, play, number, Object.hashAll(background));

  static bool _sameList(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Merkezin paletini alt ağaca (içindeki oyun uygulamaları dahil) taşır.
class StudioLookScope extends InheritedWidget {
  final StudioLook look;
  const StudioLookScope({super.key, required this.look, required super.child});

  static StudioLook? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StudioLookScope>()?.look;

  @override
  bool updateShouldNotify(StudioLookScope oldWidget) => oldWidget.look != look;
}

/// Onaylı tasarımın koyu teması: yuvarlak kartlar, hap düğmeler, degrade
/// zemin üstünde yarı saydam yüzeyler. Bütün Material bileşenleri (diyalog,
/// alt sayfa, liste satırı, anahtar, sekme, çip…) bu paletle çizilir.
ThemeData buildStudioTheme(StudioLook look) {
  final base = ColorScheme.fromSeed(
    seedColor: look.accent,
    brightness: Brightness.dark,
    dynamicSchemeVariant: DynamicSchemeVariant.vibrant,
  );
  final card = look.card;
  final scheme = base.copyWith(
    primary: look.accent,
    onPrimary: look.onAccent,
    primaryContainer: Color.lerp(card, look.accent, 0.35),
    onPrimaryContainer: Colors.white,
    secondary: look.play,
    onSecondary: look.onPlay,
    secondaryContainer: Color.lerp(card, look.play, 0.30),
    onSecondaryContainer: Colors.white,
    tertiary: StudioLook.gold,
    onTertiary: const Color(0xFF2A1E05),
    error: StudioLook.bad,
    surface: look.base,
    onSurface: Colors.white,
    onSurfaceVariant: const Color(0xFFD9DCF0),
    surfaceContainerLowest: Color.lerp(look.base, Colors.black, 0.3),
    surfaceContainerLow: Color.lerp(look.base, card, 0.25),
    surfaceContainer: Color.lerp(look.base, card, 0.35),
    surfaceContainerHigh: Color.lerp(look.base, card, 0.45),
    surfaceContainerHighest: Color.lerp(look.base, card, 0.58),
    outline: Colors.white.withValues(alpha: 0.38),
    outlineVariant: Colors.white.withValues(alpha: 0.16),
    inverseSurface: Colors.white,
    onInverseSurface: look.base,
  );
  final typo = Typography.material2021(platform: TargetPlatform.android).white;
  final text = typo
      .copyWith(
        headlineLarge: typo.headlineLarge?.copyWith(fontWeight: FontWeight.w900),
        headlineMedium: typo.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
        headlineSmall: typo.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        titleLarge: typo.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        titleMedium: typo.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        titleSmall: typo.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        labelLarge: typo.labelLarge?.copyWith(fontWeight: FontWeight.w800),
      )
      .apply(bodyColor: Colors.white, displayColor: Colors.white);
  final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));
  final sheetSide = BorderSide(color: look.accent.withValues(alpha: 0.45), width: 1.2);
  return ThemeData(
    colorScheme: scheme,
    brightness: Brightness.dark,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    textTheme: text,
    scaffoldBackgroundColor: look.base,
    canvasColor: look.sheet,
    splashColor: look.accent.withValues(alpha: 0.12),
    highlightColor: look.accent.withValues(alpha: 0.08),
    iconTheme: const IconThemeData(color: Colors.white),
    extensions: [look],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Color.lerp(look.base, card, 0.42)!.withValues(alpha: 0.88),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: look.accent.withValues(alpha: 0.40)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: look.accent,
      textColor: Colors.white,
      titleTextStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      subtitleTextStyle: const TextStyle(fontSize: 13, color: Color(0xFFC9CCE4)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      minVerticalPadding: 10,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: look.sheet,
      surfaceTintColor: Colors.transparent,
      iconColor: look.accent,
      titleTextStyle: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white),
      contentTextStyle: const TextStyle(fontSize: 15, height: 1.35, color: Color(0xFFE1E3F2)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26), side: sheetSide),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: look.sheet,
      modalBackgroundColor: look.sheet,
      surfaceTintColor: Colors.transparent,
      dragHandleColor: Colors.white54,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: sheetSide,
      ),
      clipBehavior: Clip.antiAlias,
    ),
    drawerTheme: DrawerThemeData(backgroundColor: look.base, surfaceTintColor: Colors.transparent),
    popupMenuTheme: PopupMenuThemeData(
      color: look.sheet,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: sheetSide),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: look.sheet,
      contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      actionTextColor: look.accent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: sheetSide),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.12), space: 1),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.08),
      selectedColor: look.accent,
      disabledColor: Colors.white.withValues(alpha: 0.04),
      labelStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      secondaryLabelStyle: TextStyle(color: look.onAccent, fontWeight: FontWeight.w800),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
      shape: const StadiumBorder(),
      checkmarkColor: look.onAccent,
      iconTheme: IconThemeData(color: look.accent, size: 18),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: look.play,
        foregroundColor: look.onPlay,
        disabledBackgroundColor: Colors.white.withValues(alpha: 0.10),
        disabledForegroundColor: Colors.white54,
        minimumSize: const Size(64, 50),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: pill,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: look.play,
        foregroundColor: look.onPlay,
        minimumSize: const Size(64, 50),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        shape: pill,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.06),
        minimumSize: const Size(64, 48),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        shape: pill,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: look.accent,
        minimumSize: const Size(48, 44),
        textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        shape: pill,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: Colors.white, minimumSize: const Size(48, 48)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: look.play,
      foregroundColor: look.onPlay,
      shape: const StadiumBorder(),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.08),
      hintStyle: const TextStyle(color: Colors.white60),
      labelStyle: const TextStyle(color: Color(0xFFD9DCF0)),
      prefixIconColor: Colors.white70,
      suffixIconColor: Colors.white70,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: look.accent, width: 1.6),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : const Color(0xFFB9BCD6),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? look.accent : Colors.white.withValues(alpha: 0.14),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? look.accent : Colors.white.withValues(alpha: 0.35),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? look.accent : null),
      checkColor: WidgetStatePropertyAll(look.onAccent),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? look.accent : Colors.white70,
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: look.accent,
      thumbColor: Colors.white,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.18),
      overlayColor: look.accent.withValues(alpha: 0.18),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: look.accent,
      linearTrackColor: Colors.white.withValues(alpha: 0.15),
      circularTrackColor: Colors.white.withValues(alpha: 0.12),
      linearMinHeight: 8,
      borderRadius: BorderRadius.circular(6),
    ),
    tabBarTheme: TabBarThemeData(
      indicator: BoxDecoration(color: look.accent, borderRadius: BorderRadius.circular(20)),
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Colors.transparent,
      labelColor: look.onAccent,
      unselectedLabelColor: Colors.white,
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      splashBorderRadius: BorderRadius.circular(20),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Color.lerp(look.base, Colors.black, 0.25),
      indicatorColor: look.accent.withValues(alpha: 0.75),
      surfaceTintColor: Colors.transparent,
      iconTheme: const WidgetStatePropertyAll(IconThemeData(color: Colors.white)),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: Colors.black.withValues(alpha: 0.18),
      indicatorColor: look.accent.withValues(alpha: 0.75),
      selectedIconTheme: const IconThemeData(color: Colors.white),
      unselectedIconTheme: const IconThemeData(color: Colors.white70),
      selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      unselectedLabelTextStyle: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
    ),
    badgeTheme: const BadgeThemeData(backgroundColor: StudioLook.bad, textColor: Colors.white),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: look.sheet,
        borderRadius: BorderRadius.circular(10),
        border: Border.fromBorderSide(sheetSide),
      ),
      textStyle: const TextStyle(color: Colors.white),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(look.sheet))),
  );
}
