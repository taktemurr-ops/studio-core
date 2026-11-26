import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/covers.dart';

void main() {
  testWidgets('render', (tester) async {
    final kinds = bulmacaCoverKinds;
    const s = 120.0, cols = 7;
    final rows = (kinds.length + cols - 1) ~/ cols;
    await tester.runAsync(() async {
      final rec = ui.PictureRecorder();
      final c = Canvas(rec);
      for (var i = 0; i < kinds.length; i++) {
        c.save();
        c.translate((i % cols) * (s + 6), (i ~/ cols) * (s + 6));
        c.clipRect(const Rect.fromLTWH(0, 0, s, s));
        c.scale(s / 100);
        paintCover(c, GameCover(kinds[i]), const Color(0xFF2E6F8E));
        c.restore();
      }
      final img = await rec.endRecording().toImage((cols * (s + 6)).toInt(), (rows * (s + 6)).toInt());
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      final b64 = base64Encode(bd!.buffer.asUint8List());
      for (var i = 0; i < b64.length; i += 900) {
        // ignore: avoid_print
        print('BZPNG ${b64.substring(i, math.min(i + 900, b64.length))}');
      }
    });
  });
}
