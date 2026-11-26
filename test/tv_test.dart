import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/tv.dart';

void main() {
  tearDown(() {
    TvMode.debugIsTv = false;
    TvMode.gameDepth.value = 0;
  });

  test('televizyon merkezleri stores.json ile aynı', () {
    final t = jsonDecode(File('tool/stores.json').readAsStringSync()) as Map<String, dynamic>;
    expect((t['tv_hubs'] as List).cast<String>().toSet(), TvMode.tvHubs);
  });

  test('uygunluk: yalnızca TV merkezleri, refleks/ritim/kamera oyunları hariç', () {
    expect(TvMode.suitable('merkez-kart-oyunlari', 'klondike-solitaire'), isTrue);
    expect(TvMode.suitable('merkez-kart-oyunlari', 'hiz'), isFalse);
    expect(TvMode.suitable('merkez-bilgi-yarismasi', 'genel_kultur'), isTrue);
    expect(TvMode.suitable('merkez-arcade-klasikleri', 'yilan'), isFalse);
    expect(TvMode.suitable('merkez-muzik-ve-ritim', 'piyano'), isFalse);
    expect(TvMode.suitable('merkez-zihin-antrenmani', 'refleks-testi'), isFalse);
  });

  testWidgets('telefonda TvScope hiçbir şey değiştirmez', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TvScope(child: Text('x'))));
    expect(find.byType(TvCursorLayer), findsNothing);
  });

  testWidgets('oyun ekranında orta tuş imleç konumuna dokunur', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      builder: (c, child) => TvScope(enabled: true, child: child!),
      home: Scaffold(
        body: Center(
          child: GestureDetector(
            onTap: () => taps++,
            child: const SizedBox(width: 200, height: 200, child: ColoredBox(color: Colors.red)),
          ),
        ),
      ),
    ));
    // Merkez ekranında imleç kapalı: dokunma olmaz.
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(taps, 0);
    TvMode.gameDepth.value = 1;
    await tester.pump();
    // İmleç ekran ortasından başlar (kırmızı kutunun içi).
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(taps, 1);
    final layer = tester.state<TvCursorLayerState>(find.byType(TvCursorLayer));
    expect(layer.position, isNotNull);
    // Ekran dışına çıkamaz.
    for (var i = 0; i < 60; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    }
    expect(layer.position!.dx, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('Menü tuşu imleci her ekranda açar', (tester) async {
    await tester.pumpWidget(MaterialApp(
      builder: (c, child) => TvScope(enabled: true, child: child!),
      home: const Scaffold(body: SizedBox.expand()),
    ));
    final layer = tester.state<TvCursorLayerState>(find.byType(TvCursorLayer));
    expect(layer.active, isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.contextMenu);
    await tester.pump();
    expect(layer.active, isTrue);
  });
}
