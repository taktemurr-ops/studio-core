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

/// "Geri" isteği (Alt+Sol ok, tarayıcı/klavye geri tuşu).
class StudioBackIntent extends Intent {
  const StudioBackIntent();
}

/// [MaterialApp.builder] içinde Navigator'ın üstüne sarılır.
class DesktopInput extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;
  const DesktopInput({super.key, required this.navigatorKey, required this.child});

  static const Map<ShortcutActivator, Intent> shortcuts = {
    SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true): StudioBackIntent(),
    SingleActivator(LogicalKeyboardKey.browserBack): StudioBackIntent(),
    SingleActivator(LogicalKeyboardKey.goBack): StudioBackIntent(),
  };

  @override
  Widget build(BuildContext context) {
    final pop = _PopAction(navigatorKey);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        if (e.kind == PointerDeviceKind.mouse && (e.buttons & kBackMouseButton) != 0) {
          navigatorKey.currentState?.maybePop();
        }
      },
      child: Shortcuts(
        shortcuts: shortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            DismissIntent: pop,
            StudioBackIntent: pop,
          },
          child: child,
        ),
      ),
    );
  }
}

/// Yalnızca geri dönülecek bir ekran varken etkindir; yoksa tuş üst
/// katmana (iç içe uygulamada dıştaki Navigator'a) geçer.
class _PopAction extends Action<Intent> {
  final GlobalKey<NavigatorState> navigatorKey;
  _PopAction(this.navigatorKey);

  @override
  bool isEnabled(Intent intent) => navigatorKey.currentState?.canPop() ?? false;

  @override
  Object? invoke(Intent intent) {
    navigatorKey.currentState?.maybePop();
    return null;
  }
}
