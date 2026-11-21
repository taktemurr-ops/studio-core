import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Screen classes used across all games (Material 3 window size classes).
///
/// * compact  (< 600 dp):  phones in portrait, small foldables folded
/// * medium   (600-839 dp): small tablets, foldables unfolded, phones landscape
/// * expanded (>= 840 dp): tablets, iPad, desktop / web browsers
enum FormFactor { compact, medium, expanded }

class Adaptive {
  Adaptive._();

  static const double mediumWidth = 600;
  static const double expandedWidth = 840;

  /// Comfortable reading width for list / settings style screens.
  static const double readableWidth = 720;

  /// Wider width for grids and dashboards.
  static const double wideWidth = 1200;

  static FormFactor of(BuildContext context) => forWidth(MediaQuery.sizeOf(context).width);

  static FormFactor forWidth(double w) {
    if (w >= expandedWidth) return FormFactor.expanded;
    if (w >= mediumWidth) return FormFactor.medium;
    return FormFactor.compact;
  }

  /// True for devices whose shortest side is tablet sized (iPad, Android
  /// tablets, unfolded foldables) - independent of the current orientation.
  static bool isTablet(BuildContext context) => MediaQuery.sizeOf(context).shortestSide >= mediumWidth;

  /// Orientation policy, applied once at start-up and whenever the window
  /// changes (foldables, iPad Split View, Android multi-window):
  /// * phones: portrait only (every game layout is designed portrait first);
  /// * tablets, foldables (unfolded), desktop and web: every orientation, the
  ///   game stage letterboxes itself so nothing is cropped or stretched.
  static Future<void> applyOrientationPolicy() async {
    if (kIsWeb) return; // browsers decide; the layout adapts instead.
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return;
    final view = views.first;
    final logical = view.physicalSize / view.devicePixelRatio;
    final shortest = logical.shortestSide;
    if (shortest <= 0) return;
    final phone = shortest < mediumWidth;
    final wanted = phone
        ? const [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
        : const <DeviceOrientation>[]; // empty list = all orientations allowed
    if (_last != null && listEquals(_last, wanted)) return;
    _last = wanted;
    try {
      await SystemChrome.setPreferredOrientations(wanted);
    } catch (_) {/* not supported on this platform */}
  }

  static List<DeviceOrientation>? _last;

  /// Number of columns for card grids at the given width.
  static int columns(double width, {double minTile = 280, int max = 4}) =>
      (width / minTile).floor().clamp(1, max);
}

/// Centers [child] horizontally and limits its width, so menus, lists and
/// settings stay readable on tablets, foldables, desktop and web while phones
/// keep using the full width.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ContentWidth({super.key, required this.child, this.maxWidth = Adaptive.readableWidth});

  const ContentWidth.wide({super.key, required this.child}) : maxWidth = Adaptive.wideWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
