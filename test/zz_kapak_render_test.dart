import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/covers.dart';

Future<void> sheet(String name, List<GameCover> covers) async {
  const cell = 160.0;
  const cols = 8;
  final rows = (covers.length / cols).ceil();
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  c.drawRect(Rect.fromLTWH(0, 0, cols * cell, rows * cell), Paint()..color = Colors.black);
  for (var i = 0; i < covers.length; i++) {
    c.save();
    c.translate((i % cols) * cell + 5, (i ~/ cols) * cell + 5);
    c.clipRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, cell - 10, cell - 10), const Radius.circular(18)));
    c.scale((cell - 10) / 100);
    paintCover(c, covers[i], const Color(0xFF1D4E89));
    c.restore();
  }
  final img = await rec.endRecording().toImage((cols * cell).toInt(), (rows * cell).toInt());
  final data = await img.toByteData(format: ui.ImageByteFormat.png);
  Directory('render').createSync();
  File('render/$name.png').writeAsBytesSync(data!.buffer.asUint8List());
}

void main() {
  test('kapak sayfaları', () async {
    const arcade = [
      'a-yilan', 'a-yilanio', 'a-uzayatisi', 'a-istila', 'a-asteroit', 'a-raket', 'a-labkov', 'a-isik', 'a-alan',
      'a-kosu', 'a-dinozor', 'a-kaykay', 'a-ziplama', 'a-kanat', 'a-ucak', 'a-platform', 'a-kosates', 'a-yolgecme',
      'a-ustten', 'a-park', 'a-dart', 'a-nisan', 'a-galeri', 'a-okculuk', 'a-refleks', 'a-basket', 'a-bowling',
      'a-golf', 'a-penalti', 'a-futbol', 'a-tenis', 'a-voleybol', 'a-kulekurma', 'a-sapan', 'a-topcu', 'a-egik',
    ];
    const blok = [
      'b-master', 'b-sudoku', 'b-doldurma', 'b-poliomino', 'b-alanbolme', 'b-paket', 'b-dusen', 'b-altigen',
      'b-altigendusen', 'b-sayili', 'b-retro', 'b-kum', 'b-kaydirma', 'b-kacis', 'b-renkli', 'b-egim', 'b-kup', 'b-kule',
    ];
    await sheet('arcade', [for (final k in arcade) GameCover(k)]);
    await sheet('blok', [for (final k in blok) GameCover(k), for (var v = 0; v < 20; v++) GameCover('b-cesit', v: v)]);
  });
}
