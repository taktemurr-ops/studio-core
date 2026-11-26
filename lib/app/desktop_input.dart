import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Fare ve klavye desteği (masaüstü, Chromebook, Google Play Games on PC,
/// web). Dokunmatik cihazlarda davranış değişmez.
///
/// * Kaydırılabilir her listede fareyle sürükleme (yatay şeritler tekerlekle
///   kaydırılamaz) ve kaydırma çubuğu.
/// * Esc, Alt+Sol ok, klavyenin "geri" tuşu ve farenin geri düğmesi bir önceki
///   ekrana döner. Açık bir iletişim kutusu, menü ya da oyunun kendi tuşları
///   (ör. arcade'de Esc = duraklat) önce davranır; ana ekranda hiçbir şey
///   yapmaz.
class StudioScrollBehavior extends MaterialScrollBehavior {
  const StudioScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
        PointerDeviceKind.invertedStylus,
        PointerDeviceKind.unknown,
      };
}

/// [MaterialApp.builder] içinde Navigator'ın üstüne sarılır.
class DesktopInput extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  const DesktopInput({super.key, required this.navigatorKey, required this.child});

  /// Geri tuşu mu (Esc, Alt+Sol ok, klavyenin geri tuşu)?
  static bool isBack(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    final k = e.logicalKey;
    if (k == LogicalKeyboardKey.escape || k == LogicalKeyboardKey.browserBack || k == LogicalKeyboardKey.goBack) {
      return true;
    }
    return k == LogicalKeyboardKey.arrowLeft && HardwareKeyboard.instance.isAltPressed;
  }

  bool _pop() {
    final nav = navigatorKey.currentState;
    if (nav == null || !nav.canPop()) return false;
    nav.maybePop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        if (e.kind == PointerDeviceKind.mouse && (e.buttons & kBackMouseButton) != 0) _pop();
      },
      // Odaktaki öğeden yukarı kabaran tuşlar: oyunun kendi tuşları (ör.
      // arcade'de Esc = duraklat) önce davranır. Geri dönülecek ekran yoksa
      // tuş üst katmana (iç içe uygulamada dıştaki Navigator'a) geçer.
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onKeyEvent: (node, e) => isBack(e) && _pop() ? KeyEventResult.handled : KeyEventResult.ignored,
        child: child,
      ),
    );
  }
}
