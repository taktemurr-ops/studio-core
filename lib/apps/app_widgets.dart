/// Araç ekranlarında ortak kullanılan sade yapı taşları. Renkler merkezin
/// onaylı tasarımından ([ApprovedHubStyle]) gelir; [AppLook] ile aktarılır.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/approved_hub.dart' show ApprovedHubStyle;
import 'app_tx.dart';

/// Merkezin görünümünü araç ekranlarına taşır.
class AppLook extends InheritedWidget {
  final ApprovedHubStyle style;
  const AppLook({super.key, required this.style, required super.child});

  static ApprovedHubStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppLook>()?.style ?? const ApprovedHubStyle();

  @override
  bool updateShouldNotify(AppLook oldWidget) => oldWidget.style != style;
}

/// Koyu degrade zemin (oyun merkezleriyle aynı).
class AppBackdrop extends StatelessWidget {
  final Widget child;
  const AppBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = AppLook.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: s.background),
      ),
      child: child,
    );
  }
}

/// Yarı saydam yuvarlak kart.
class AppPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  const AppPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
  });

  @override
  Widget build(BuildContext context) {
    final s = AppLook.of(context);
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(s.card, Colors.white, 0.06)!, Color.lerp(s.card, Colors.black, 0.30)!],
        ),
        border: Border.all(color: s.accent.withValues(alpha: 0.35)),
      ),
      child: child,
    );
  }
}

/// Bölüm başlığı.
class AppHeading extends StatelessWidget {
  final String text;
  final IconData? icon;
  const AppHeading(this.text, {super.key, this.icon});

  @override
  Widget build(BuildContext context) {
    final s = AppLook.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, color: s.accent, size: 20), const SizedBox(width: 8)],
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        ),
      ]),
    );
  }
}

/// Sayı girişi (ondalık için virgül de kabul edilir).
class AppNumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final bool decimal;
  final bool signed;
  final ValueChanged<String>? onChanged;
  const AppNumberField({
    super.key,
    required this.controller,
    required this.label,
    this.suffix,
    this.decimal = true,
    this.signed = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: TextInputType.numberWithOptions(decimal: decimal, signed: signed),
        style: const TextStyle(color: Colors.white, fontSize: 18),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

/// Metindeki sayıyı okur: "1.234,5" ve "1,234.5" biçimlerini anlar.
double? parseNumber(String raw) {
  var s = raw.trim().replaceAll(' ', '').replaceAll(' ', '');
  if (s.isEmpty) return null;
  final comma = s.lastIndexOf(',');
  final dot = s.lastIndexOf('.');
  if (comma >= 0 && dot >= 0) {
    if (comma > dot) {
      s = s.replaceAll('.', '').replaceAll(',', '.');
    } else {
      s = s.replaceAll(',', '');
    }
  } else if (comma >= 0) {
    s = s.replaceAll(',', '.');
  }
  return double.tryParse(s);
}

/// Sayıyı okunur biçimde yazar (en fazla [digits] ondalık, sondaki sıfırlar atılır).
String formatNumber(double v, {int digits = 6}) {
  if (v.isNaN || v.isInfinite) return '—';
  if (v != 0 && (v.abs() >= 1e12 || v.abs() < 1e-6)) return v.toStringAsExponential(4);
  var s = v.toStringAsFixed(digits);
  if (s.contains('.')) {
    s = s.replaceFirst(RegExp(r'0+$'), '');
    if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  }
  if (s == '-0') s = '0';
  return s;
}

/// Kopyalanabilir sonuç satırı.
class AppResult extends StatelessWidget {
  final String label;
  final String value;
  final String lang;
  final bool big;
  const AppResult({super.key, required this.label, required this.value, required this.lang, this.big = false});

  @override
  Widget build(BuildContext context) {
    final s = AppLook.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onLongPress: () => _copy(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Expanded(child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 15))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: big ? s.number : Colors.white,
                    fontSize: big ? 28 : 18,
                    fontWeight: big ? FontWeight.w900 : FontWeight.w700)),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: appTx('copied', lang),
            icon: const Icon(Icons.copy_rounded, size: 18, color: Colors.white60),
            onPressed: () => _copy(context),
          ),
        ]),
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(appTx('copied', lang))));
  }
}

/// "Bu cihazda yok" ya da "web'de yok" bilgisi.
class AppInfoCard extends StatelessWidget {
  final String text;
  final IconData icon;
  const AppInfoCard(this.text, {super.key, this.icon = Icons.info_outline_rounded});

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      child: Row(children: [
        Icon(icon, color: Colors.white70),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white70))),
      ]),
    );
  }
}

/// Ana eylem düğmesi.
class AppButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  const AppButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final s = AppLook.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: s.play,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.play_arrow_rounded),
          label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }
}
