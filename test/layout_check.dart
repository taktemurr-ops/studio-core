// Ekran boyutu denetimi (ortak yardımcı): taşma (RenderFlex overflow vb.),
// kesilen metin ve ekran dışında kalıp erişilemeyen düğmeleri toplar.
// screen_sizes_test.dart ve cihaz duman testi (integration_test) kullanır.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Denenen mantıksal ekran boyutları (dikey; yatay için en/boy yer değiştirir).
const kScreens = <(String, Size)>[
  ('320x568', Size(320, 568)), // küçük telefon (iPhone SE 1)
  ('360x640', Size(360, 640)), // küçük Android
  ('393x852', Size(393, 852)), // iPhone 15/16, Pixel 7 sınıfı
  ('412x915', Size(412, 915)), // büyük Android
  ('430x932', Size(430, 932)), // iPhone Pro Max
  ('673x841', Size(673, 841)), // katlanabilir iç ekran
  ('768x1024', Size(768, 1024)), // iPad mini / 9.7"
  ('820x1180', Size(820, 1180)), // iPad Air / 10.9"
  ('800x1280', Size(800, 1280)), // Android tablet (yatayda 1280x800)
];

/// Bir denemenin adı: boyut, yön, dil, yazı ölçeği.
String comboName(String size, bool landscape, String lang, double scale) =>
    '$size${landscape ? '-yatay' : '-dikey'} $lang x$scale';

/// Bulunan sorunlar; testler sonunda boyuta göre özetlenir.
class LayoutIssues {
  final List<String> items = [];
  final Map<String, int> bySize = {};
  final Map<String, int> combosBySize = {};
  int ellipsized = 0;

  void add(String screen, String combo, String kind, String msg) {
    final line = 'SORUN|$screen|$combo|$kind|${msg.replaceAll('\n', ' ').trim()}';
    if (items.contains(line)) return;
    items.add(line);
    final size = combo.split(' ').first;
    bySize[size] = (bySize[size] ?? 0) + 1;
  }

  void tried(String combo) {
    final size = combo.split(' ').first;
    combosBySize[size] = (combosBySize[size] ?? 0) + 1;
  }

  /// CI günlüğünde ayrıştırılan özet satırları.
  void printSummary(String suite) {
    final keys = {...combosBySize.keys, ...bySize.keys}.toList()..sort();
    // ignore: avoid_print
    print('BOYUT_OZET|$suite|deneme=${combosBySize.values.fold(0, (a, b) => a + b)}|sorun=${items.length}|ucnokta=$ellipsized');
    for (final k in keys) {
      // ignore: avoid_print
      print('BOYUT|$suite|$k|deneme=${combosBySize[k] ?? 0}|sorun=${bySize[k] ?? 0}');
    }
    for (final i in items.take(400)) {
      // ignore: avoid_print
      print(i);
    }
  }
}

/// Test sırasında Flutter'ın bildirdiği hataları (taşma dahil) yakalar.
/// [stop] çağrılmadan test bitmemeli (FlutterError.onError geri yüklenir).
class ErrorTrap {
  final void Function(FlutterErrorDetails details)? _old;
  final List<String> errors = [];
  ErrorTrap() : _old = FlutterError.onError {
    FlutterError.onError = (d) {
      final s = d.exceptionAsString();
      var first = s.split('\n').firstWhere((l) => l.trim().isNotEmpty, orElse: () => s);
      // Kaynağı bul: hatayı doğuran widget'ın dosyası (SDK dışı) ve üst zinciri.
      final full = d.toString();
      final files = RegExp(r'file:///\S+?\.dart:\d+:\d+').allMatches(full).map((m) => m.group(0)!)
          .where((f) => !f.contains('/packages/flutter/')).toList();
      final creator = RegExp(r'creator: ([^\n]+)').firstMatch(full)?.group(1);
      final where = [
        if (files.isNotEmpty) files.first.replaceFirst(RegExp(r'^file:///home/runner/(work/[^/]+/[^/]+/|\.pub-cache/(git|hosted/[^/]+)/)'), ''),
        if (creator != null) creator.split(' ← ').take(4).join('<'),
      ].join(' ');
      if (where.isNotEmpty) first = '$first @ ${where.length > 220 ? where.substring(0, 220) : where}';
      errors.add(first);
    };
  }

  List<String> take() {
    final e = [...errors];
    errors.clear();
    return e;
  }

  void stop() => FlutterError.onError = _old;
}

/// Üstte başka bir sayfa açıkken alttaki (geçiş animasyonunda kayan) sayfa.
bool _behind(Element e) => ModalRoute.isCurrentOf(e) == false;

bool _inScrollable(Element e) {
  var found = false;
  e.visitAncestorElements((a) {
    if (a.widget is Scrollable || a.widget is SingleChildScrollView || a.widget is NestedScrollView) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}

String _label(Widget w) {
  if (w is IconButton) return 'IconButton(${w.tooltip ?? (w.icon is Icon ? (w.icon as Icon).icon.toString() : '')})';
  return w.runtimeType.toString();
}

/// Ekrandaki metin ve düğmeleri denetler; taşma hataları [trap] içindedir.
void checkLayout(WidgetTester tester, LayoutIssues issues, ErrorTrap trap, String screen, String combo) {
  issues.tried(combo);
  for (final e in trap.take()) {
    // Eklentiler (ses, kamera, sensör) testte yok: düzen sorunu değil.
    if (e.contains('MissingPluginException') || e.contains('No implementation found')) continue;
    issues.add(screen, combo, e.contains('overflowed') ? 'tasma' : 'hata', e);
  }
  // Kök görünümün mantıksal boyutu (cihazda da gerçek ekran boyutu).
  final screenRect = Offset.zero & tester.binding.renderViews.first.size;

  // Kesilen metin: satır sınırını aşıp kırpılan ya da kutusuna sığmayan yazı.
  for (final el in find.byType(RichText).evaluate()) {
    if (_behind(el)) continue;
    final r = el.renderObject;
    if (r is! RenderParagraph || !r.attached || !r.hasSize) continue;
    final text = r.text.toPlainText().trim();
    if (text.isEmpty) continue;
    // Simge yazı tipleri (Material Icons, özel kullanım alanı): metin değil.
    if (text.runes.every((c) => (c >= 0xE000 && c <= 0xF8FF) || c >= 0xF0000)) continue;
    final box = MatrixUtils.transformRect(r.getTransformTo(null), Offset.zero & r.size);
    if (!box.overlaps(screenRect)) continue; // görünmeyen (kaydırılabilir alanda aşağıda) metin
    if (r.didExceedMaxLines) {
      if (r.overflow == TextOverflow.ellipsis || r.overflow == TextOverflow.fade) {
        issues.ellipsized++;
      } else {
        issues.add(screen, combo, 'kesik_metin', '"${_short(text)}" satır sınırını aşıyor (${r.overflow.name})${_chain(r)}');
      }
      continue;
    }
    if (r.size.width <= 0) continue;
    final need = r.getMaxIntrinsicHeight(r.size.width);
    if (need > r.size.height + 3) {
      issues.add(screen, combo, 'kesik_metin',
          '"${_short(text)}" kutusuna sığmıyor (${need.toStringAsFixed(0)} > ${r.size.height.toStringAsFixed(0)})${_chain(r)}');
    }
  }

  // Erişilemeyen düğme: kaydırılamayan bir yerde ekran dışında kalan.
  bool tappable(Widget w) =>
      (w is ButtonStyleButton && w.enabled) ||
      (w is IconButton && w.onPressed != null) ||
      (w is FloatingActionButton && w.onPressed != null) ||
      (w is InkResponse && (w.onTap != null || w.onLongPress != null));
  for (final el in find.byWidgetPredicate(tappable).evaluate()) {
    if (_behind(el)) continue;
    final r = el.renderObject;
    if (r is! RenderBox || !r.attached || !r.hasSize || r.size.isEmpty) continue;
    if (_inScrollable(el)) continue;
    final rect = MatrixUtils.transformRect(r.getTransformTo(null), Offset.zero & r.size);
    final c = rect.center;
    if (!screenRect.inflate(0.5).contains(c)) {
      issues.add(screen, combo, 'erisilemez_dugme',
          '${_label(el.widget)} ekran dışında (${rect.left.toStringAsFixed(0)},${rect.top.toStringAsFixed(0)} ${rect.width.toStringAsFixed(0)}x${rect.height.toStringAsFixed(0)})${_chain(r)}');
    }
  }
}

/// Metnin üst widget zinciri (hangi ekranda/parçada olduğunu bulmak için).
String _chain(RenderObject r) {
  final c = r.debugCreator;
  if (c is! DebugCreator) return '';
  final parts = c.element.debugGetCreatorChain(12).split(' ← ');
  // RichText ← Text gibi tekrarları atla; özel (uygulama) widget'larını öne al.
  final own = parts.where((p) => p.startsWith('_') || !_sdk.contains(p.split('-').first)).take(4).toList();
  return ' [${own.join('<')}]';
}

const _sdk = {
  'RichText', 'Text', 'Center', 'Align', 'Padding', 'Expanded', 'Flexible', 'Column', 'Row', 'SizedBox', 'Container',
  'DecoratedBox', 'ConstrainedBox', 'DefaultTextStyle', 'Semantics', 'MergeSemantics', 'Stack', 'Positioned',
  'ClipRRect', 'Material', 'InkWell', 'Ink', 'Builder', 'LayoutBuilder', 'FittedBox', 'Opacity', 'Transform',
  'IconTheme', 'Listener', 'GestureDetector', 'RepaintBoundary', 'KeyedSubtree', 'AnimatedContainer', 'Wrap',
  'ExcludeSemantics', 'DefaultTextStyleTransition', 'Directionality', 'AnimatedDefaultTextStyle', 'PositionedDirectional',
  'ColoredBox', 'Flex', 'IntrinsicHeight', 'IntrinsicWidth', 'LimitedBox', 'Offstage', 'Visibility', 'TickerMode',
};

String _short(String s) => s.length > 40 ? '${s.substring(0, math.min(40, s.length))}…' : s;

/// Gerçek cihazdaki yazı ölçüleri için Roboto (Flutter SDK'daki
/// material_fonts) ve varsa sistemdeki Noto Arapça/emoji yazı tiplerini
/// yükler; yoksa test yazı tipi (her harf 1 em) taşmaları abartır.
Future<void> loadRealFonts() async {
  Future<void> load(String family, Iterable<File> files) async {
    final l = FontLoader(family);
    var n = 0;
    for (final f in files) {
      if (!f.existsSync()) continue;
      final bytes = f.readAsBytesSync();
      l.addFont(Future.value(ByteData.sublistView(bytes)));
      n++;
    }
    if (n > 0) await l.load();
  }

  try {
    final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
    final mf = Directory('${artifacts.path}/material_fonts');
    if (mf.existsSync()) {
      final all = mf.listSync().whereType<File>().toList();
      await load('Roboto', all.where((f) => f.path.contains('Roboto-') && f.path.endsWith('.ttf')));
      await load('MaterialIcons', all.where((f) => f.path.contains('MaterialIcons')));
    }
    const noto = '/usr/share/fonts/truetype/noto';
    await load('Noto Naskh Arabic', [File('$noto/NotoNaskhArabic-Regular.ttf'), File('$noto/NotoNaskhArabic-Bold.ttf')]);
    await load('Noto Color Emoji', [File('$noto/NotoColorEmoji.ttf')]);
  } catch (e) {
    // ignore: avoid_print
    print('yazı tipi yüklenemedi: $e');
  }
}

/// Her denemede ağacın sıfırdan kurulması için (taşma uyarısı her boyutta
/// yeniden bildirilir): kökteki durum (ör. ProviderScope) korunur.
Widget fresh(Widget child) => KeyedSubtree(key: UniqueKey(), child: child);

/// Görünümü verilen mantıksal boyuta ayarlar.
void setScreen(WidgetTester tester, Size logical, {double dpr = 2}) {
  tester.view.devicePixelRatio = dpr;
  tester.view.physicalSize = logical * dpr;
}

/// Tüm boyut/yön/ölçek denemelerinde [screen] ekranını dolaşır. [build]
/// ağacı her denemede [fresh] ile yeniden kurmalıdır.
Future<void> sweep(
  WidgetTester tester,
  LayoutIssues issues,
  String screen,
  Future<void> Function(String lang) build, {
  List<(String, double)> langScales = const [('tr', 1.0), ('tr', 1.3), ('ar', 1.3)],
  List<(String, Size)> screens = kScreens,
  int settleMs = 400,
  bool Function(Size logical)? skip,
}) async {
  final trap = ErrorTrap();
  try {
    for (final (lang, scale) in langScales) {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      for (final (name, size) in screens) {
        for (final land in [false, true]) {
          final logical = land ? Size(size.height, size.width) : size;
          if (skip != null && skip(logical)) continue;
          setScreen(tester, logical);
          await build(lang);
          for (var i = 0; i < settleMs ~/ 100; i++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
          checkLayout(tester, issues, trap, screen, comboName(name, land, lang, scale));
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    trap.take();
  } finally {
    trap.stop();
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    tester.view.reset();
  }
}
