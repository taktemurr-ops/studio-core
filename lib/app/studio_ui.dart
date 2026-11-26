/// Onaylı tasarımın yapı taşları: merkezde, oyun içinde ve araç
/// ekranlarında aynı kart, başlık, düğme, çip ve alt çubuk.
///
/// Renkler [StudioLook.of] ile temadan okunur. Yerleşimler yön bağımsızdır
/// (Arapça, Farsça, İbranice, Urduca sağdan sola), dokunma alanları en az
/// 48 piksel.
library;

import 'package:flutter/material.dart';

import 'studio_look.dart';

export 'studio_look.dart';

/// Koyu degrade zemin; üstte hafif bir ışık halesi.
class StudioBackdrop extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  const StudioBackdrop({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors ?? look.background,
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -1.05),
            radius: 1.1,
            colors: [look.accent.withValues(alpha: 0.16), look.accent.withValues(alpha: 0)],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// Başlıkta simge + kalın beyaz yazı (merkezin üst çubuğu gibi).
class StudioTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Widget? art;
  const StudioTitle(this.text, {super.key, this.icon, this.art});

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (art != null) ...[
          art!,
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, color: look.accent, size: 26),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

/// Saydam üst çubuk; içerik degrade zeminin üstünde akar.
PreferredSizeWidget studioAppBar(
  BuildContext context, {
  required String title,
  IconData? icon,
  Widget? art,
  Widget? leading,
  List<Widget>? actions,
  PreferredSizeWidget? bottom,
}) {
  return AppBar(
    backgroundColor: Colors.transparent,
    foregroundColor: Colors.white,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: leading,
    title: StudioTitle(title, icon: icon, art: art),
    actions: actions,
    bottom: bottom,
  );
}

/// Onaylı tasarımlı sayfa: saydam üst çubuk + degrade zemin.
class StudioScaffold extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? art;
  final Widget? leading;
  final List<Widget>? actions;
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? bottom;
  final bool safeBottom;
  const StudioScaffold({
    super.key,
    required this.title,
    required this.body,
    this.icon,
    this.art,
    this.leading,
    this.actions,
    this.bottomNavigationBar,
    this.bottom,
    this.safeBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return Scaffold(
      backgroundColor: look.base,
      extendBodyBehindAppBar: true,
      appBar: studioAppBar(
        context,
        title: title,
        icon: icon,
        art: art,
        leading: leading,
        actions: actions,
        bottom: bottom,
      ),
      body: StudioBackdrop(
        child: SafeArea(bottom: safeBottom, child: body),
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// Yarı saydam, vurgu kenarlı yuvarlak kart (merkezdeki görev/ilerleme kartı).
class StudioPanel extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final String? semanticLabel;
  const StudioPanel({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.gradient,
    this.borderColor,
    this.radius = 18,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    final r = BorderRadius.circular(radius);
    Widget body = Ink(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: r,
        color: gradient == null ? Colors.white.withValues(alpha: 0.07) : null,
        gradient: gradient,
        border: Border.all(color: borderColor ?? look.accent.withValues(alpha: 0.45), width: 1.2),
      ),
      child: child,
    );
    if (onTap != null) body = InkWell(borderRadius: r, onTap: onTap, child: body);
    body = Material(color: Colors.transparent, borderRadius: r, child: body);
    if (semanticLabel != null) body = Semantics(button: onTap != null, label: semanticLabel, child: body);
    return Padding(padding: margin, child: body);
  }
}

/// Bölüm başlığı: renkli simge, kalın başlık, isteğe bağlı "Tümü ›".
class StudioSectionHeader extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? allLabel;
  final VoidCallback? onAll;
  final EdgeInsetsGeometry padding;
  const StudioSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
    this.allLabel,
    this.onAll,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 6),
  });

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? look.accent, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          if (onAll != null && allLabel != null) TextButton(onPressed: onAll, child: Text('$allLabel ›')),
        ],
      ),
    );
  }
}

/// Seçilebilir hap çip.
class StudioPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  const StudioPill({super.key, required this.label, this.selected = false, this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    final fg = selected ? look.onAccent : Colors.white;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: selected ? look.accent : Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: selected ? look.accent : Colors.white.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 6)],
                Text(
                  label,
                  style: TextStyle(color: fg, fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum StudioButtonTone {
  /// Merkezin oyna mavisi (paletin oyna rengi).
  play,

  /// Büyük turuncu "Hemen Oyna".
  hot,

  /// Altın (ödül al, çevrimiçi masa).
  gold,

  /// Yarı saydam, beyaz kenarlı ikincil düğme.
  ghost,
}

/// Degrade hap düğme (en az 52 piksel yükseklik).
class StudioButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final StudioButtonTone tone;
  final double height;
  final double fontSize;
  final bool expand;
  const StudioButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.tone = StudioButtonTone.play,
    this.height = 52,
    this.fontSize = 17,
    this.expand = true,
  });

  /// Büyük "Hemen Oyna" düğmesi.
  const StudioButton.hot({super.key, required this.label, this.icon = Icons.play_arrow_rounded, this.onPressed})
    : tone = StudioButtonTone.hot,
      height = 60,
      fontSize = 21,
      expand = true;

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    final enabled = onPressed != null;
    final (Gradient? g, Color? fill, Color fg, Color? glow, BoxBorder? border) = switch (tone) {
      StudioButtonTone.play => (look.playGradient, null, look.onPlay, look.play, null),
      StudioButtonTone.hot => (
        const LinearGradient(colors: StudioLook.hot),
        null,
        Colors.white,
        StudioLook.hot.last,
        null,
      ),
      StudioButtonTone.gold => (
        const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFC14A)]),
        null,
        const Color(0xFF2A1E05),
        StudioLook.gold,
        null,
      ),
      StudioButtonTone.ghost => (
        null,
        Colors.white.withValues(alpha: 0.07),
        Colors.white,
        null,
        Border.all(color: Colors.white.withValues(alpha: 0.38)),
      ),
    };
    final r = BorderRadius.circular(height / 2);
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, color: fg, size: fontSize + 9), const SizedBox(width: 8)],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Material(
          color: Colors.transparent,
          borderRadius: r,
          child: InkWell(
            borderRadius: r,
            onTap: onPressed,
            child: Ink(
              height: height,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                borderRadius: r,
                gradient: g,
                color: fill,
                border: border,
                boxShadow: glow == null || !enabled
                    ? null
                    : [BoxShadow(color: glow.withValues(alpha: 0.40), blurRadius: 14, offset: const Offset(0, 4))],
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Yuvarlatılmış ilerleme çubuğu.
class StudioBar extends StatelessWidget {
  final double value;
  final Color? color;
  final double height;
  const StudioBar({super.key, required this.value, this.color, this.height = 9});

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    return Semantics(
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: LinearProgressIndicator(
          value: v,
          minHeight: height,
          color: color ?? StudioLook.of(context).accent,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

/// Degrade zeminli yuvarlak kare simge (mod kartları, satır başları).
class StudioIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  const StudioIconBadge(this.icon, {super.key, required this.color, this.size = 42});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.3),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(color, Colors.white, 0.18)!, Color.lerp(color, Colors.black, 0.25)!],
        ),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.58),
    );
  }
}

/// Para / elmas / ipucu hapı (merkezdeki altın · elmas · can çubuğu gibi).
class StudioStatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String? semanticLabel;
  final VoidCallback? onTap;
  final bool plus;
  final bool compact;
  const StudioStatChip({
    super.key,
    required this.icon,
    required this.color,
    required this.text,
    this.semanticLabel,
    this.onTap,
    this.plus = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(24);
    final chip = Ink(
      height: compact ? 34 : 42,
      padding: EdgeInsetsDirectional.only(start: 8, end: plus ? 4 : 12),
      decoration: BoxDecoration(
        borderRadius: r,
        color: Colors.black.withValues(alpha: 0.30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: compact ? 18 : 22),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white, fontSize: compact ? 13.5 : 15, fontWeight: FontWeight.w800),
            ),
          ),
          if (plus) ...[
            const SizedBox(width: 4),
            Icon(Icons.add_circle_rounded, color: StudioLook.good, size: compact ? 20 : 24),
          ],
        ],
      ),
    );
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: Colors.transparent,
        borderRadius: r,
        child: onTap == null ? chip : InkWell(borderRadius: r, onTap: onTap, child: chip),
      ),
    );
  }
}

/// Mağazayı açan altın taç simgesi.
class StudioCrown extends StatelessWidget {
  final double width;
  const StudioCrown({super.key, this.width = 30});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: width * 0.86,
    child: const CustomPaint(painter: _CrownPainter()),
  );
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size s) {
    final w = s.width, h = s.height;
    final path = Path()
      ..moveTo(w * 0.08, h * 0.85)
      ..lineTo(w * 0.02, h * 0.25)
      ..lineTo(w * 0.30, h * 0.52)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.70, h * 0.52)
      ..lineTo(w * 0.98, h * 0.25)
      ..lineTo(w * 0.92, h * 0.85)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFE27A), Color(0xFFF2A21C)],
        ).createShader(Offset.zero & s),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.08, h * 0.80, w * 0.84, h * 0.16), const Radius.circular(2)),
      Paint()..color = const Color(0xFFE08A10),
    );
    final dot = Paint()..color = const Color(0xFFFFF4C2);
    for (final x in [0.02, 0.50, 0.98]) {
      canvas.drawCircle(Offset(w * x, h * (x == 0.50 ? 0.10 : 0.25)), w * 0.07, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Alt gezinme öğesi.
class StudioNavItem {
  final IconData icon;
  final String label;
  final bool badge;
  const StudioNavItem(this.icon, this.label, {this.badge = false});
}

/// Merkezin alt gezinme çubuğu (seçili sekme degrade hap içinde).
class StudioNavBar extends StatelessWidget {
  final List<StudioNavItem> items;
  final int selected;
  final ValueChanged<int> onTap;
  const StudioNavBar({super.key, required this.items, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, 8 + MediaQuery.paddingOf(context).bottom),
      decoration: BoxDecoration(
        color: Color.lerp(look.base, Colors.black, 0.25),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.10))),
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == i,
                label: items[i].label,
                excludeSemantics: true,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onTap(i),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: selected == i
                        ? BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [look.accent.withValues(alpha: 0.85), look.accent.withValues(alpha: 0.45)],
                            ),
                          )
                        : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Badge(
                          isLabelVisible: items[i].badge,
                          smallSize: 9,
                          child: Icon(items[i].icon, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: selected == i ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Alt sayfa ve diyalog satırı: renkli simge rozeti, kalın yazı.
class StudioMenuRow extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final String label;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  const StudioMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.color,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return StudioPanel(
      onTap: onTap,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          StudioIconBadge(icon, color: color ?? look.accent, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFFC9CCE4), fontSize: 13),
                  ),
              ],
            ),
          ),
          trailing ??
              (onTap != null ? const Icon(Icons.chevron_right_rounded, color: Colors.white70) : const SizedBox()),
        ],
      ),
    );
  }
}

/// Alt sayfa başlığı (ortada büyük, kalın, italik).
class StudioSheetTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? iconColor;
  const StudioSheetTitle(this.text, {super.key, this.icon, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final look = StudioLook.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, color: iconColor ?? look.accent, size: 28), const SizedBox(width: 8)],
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                shadows: [Shadow(blurRadius: 8, color: Colors.black54, offset: Offset(0, 2))],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
