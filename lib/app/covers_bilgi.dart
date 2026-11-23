part of 'covers.dart';

/// Bilgi Yarışması oyunlarının kapak resimleri (100×100 mantıksal alan).
/// Türler: quizc, timelinec, platec, globec, atomc, pawc, duelc, scalec.
bool _paintBilgiCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const ink = Color(0xFF22303F);
  const paper = Color(0xFFF7F1E6);
  RRect box(Offset o, double w, double h, [double r = 6]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));

  switch (cover.kind) {
    case 'quizc':
      // Soru balonu ve dört seçenek düğmesi.
      _bg(c, seed, tint: const Color(0xFF2E5E8C));
      final bubble = box(const Offset(50, 30), 64, 32, 10);
      _shadowRRect(c, bubble);
      c.drawRRect(bubble, _p(paper));
      c.drawPath(
          Path()
            ..moveTo(40, 45)
            ..lineTo(34, 54)
            ..lineTo(50, 45)
            ..close(),
          _p(paper));
      _text(c, '?', const Offset(50, 30), 24, ink);
      const cols = [Color(0xFFE9B949), Color(0xFF4F9A6E), Color(0xFFE07A5F), Color(0xFF8FB8DE)];
      for (var k = 0; k < 4; k++) {
        final o = Offset(31 + (k % 2) * 38.0, 66 + (k ~/ 2) * 16.0);
        final r = box(o, 32, 12, 6);
        c.drawRRect(r, _p(cols[(k + v) % 4]));
      }
    case 'timelinec':
      // Zaman çizgisi üzerinde dört olay kartı.
      _bg(c, seed, tint: const Color(0xFF8C5A3C));
      c.drawLine(const Offset(12, 56), const Offset(88, 56), _stroke(paper, 3));
      for (var k = 0; k < 4; k++) {
        final x = 18 + k * 21.0;
        c.drawCircle(Offset(x, 56), 4, _p(const Color(0xFFE9B949)));
        final up = (k + v).isEven;
        final card = box(Offset(x, up ? 36 : 76), 18, 16, 3);
        c.drawLine(Offset(x, 56), Offset(x, up ? 44 : 68), _stroke(paper.withValues(alpha: 0.7), 1.5));
        _shadowRRect(c, card, dy: 1.4);
        c.drawRRect(card, _p(paper));
        c.drawLine(Offset(x - 5, up ? 34 : 74), Offset(x + 5, up ? 34 : 74), _stroke(ink.withValues(alpha: 0.5), 1.6));
        c.drawLine(Offset(x - 5, up ? 39 : 79), Offset(x + 3, up ? 39 : 79), _stroke(ink.withValues(alpha: 0.35), 1.6));
      }
    case 'platec':
      // Sade plaka: mavi şerit ve iki haneli kod.
      _bg(c, seed, tint: const Color(0xFFB23A48));
      final plate = box(const Offset(50, 50), 80, 30, 5);
      _shadowRRect(c, plate);
      c.drawRRect(plate, _p(Colors.white));
      c.drawRRect(plate, _stroke(ink, 2.2));
      c.drawRRect(RRect.fromRectAndCorners(const Rect.fromLTWH(11, 36, 11, 28), topLeft: const Radius.circular(4), bottomLeft: const Radius.circular(4)),
          _p(const Color(0xFF2E5E8C)));
      _text(c, cover.label.isEmpty ? '${(v % 81) + 1}'.padLeft(2, '0') : cover.label, const Offset(44, 50), 20, ink);
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(66 + k * 7.0, 50), 2.2, _p(ink.withValues(alpha: 0.55)));
      }
    case 'globec':
      // Enlem-boylam çizgili küre ve iğne.
      _bg(c, seed, tint: const Color(0xFF1F4E5F));
      const o = Offset(50, 52);
      c.drawCircle(o, 32, _p(const Color(0xFF8FC1D4)));
      final land = Path()
        ..moveTo(32, 38)
        ..quadraticBezierTo(44, 28, 54, 36)
        ..quadraticBezierTo(60, 46, 50, 50)
        ..quadraticBezierTo(40, 54, 36, 64)
        ..quadraticBezierTo(26, 56, 32, 38)
        ..close()
        ..moveTo(60, 58)
        ..quadraticBezierTo(72, 54, 76, 64)
        ..quadraticBezierTo(70, 76, 60, 72)
        ..close();
      c.save();
      c.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: 32)));
      c.drawPath(land, _p(const Color(0xFFE9D9B8)));
      for (var k = -2; k <= 2; k++) {
        c.drawLine(Offset(16, 52 + k * 12.0), Offset(84, 52 + k * 12.0), _stroke(Colors.white.withValues(alpha: 0.35), 1));
        c.drawOval(Rect.fromCenter(center: o, width: (k.abs() * 22).toDouble() + 8, height: 64), _stroke(Colors.white.withValues(alpha: 0.3), 1));
      }
      c.restore();
      c.drawCircle(o, 32, _stroke(paper, 2));
      final pin = Offset(56.0 + v * 3, 42);
      c.drawPath(
          Path()
            ..moveTo(pin.dx, pin.dy)
            ..lineTo(pin.dx - 5, pin.dy - 9)
            ..lineTo(pin.dx + 5, pin.dy - 9)
            ..close(),
          _p(const Color(0xFFC8553D)));
      c.drawCircle(pin - const Offset(0, 12), 6, _p(const Color(0xFFC8553D)));
      c.drawCircle(pin - const Offset(0, 12), 2.4, _p(Colors.white));
    case 'atomc':
      // Element kutucuğu ve yörüngeler.
      _bg(c, seed, tint: const Color(0xFF3A4E8C));
      for (var k = 0; k < 3; k++) {
        c.save();
        c.translate(50, 50);
        c.rotate(k * math.pi / 3 + v * 0.2);
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: 80, height: 30), _stroke(const Color(0xFF8FB8DE), 2));
        c.drawCircle(const Offset(40, 0), 3.5, _p(const Color(0xFFE9B949)));
        c.restore();
      }
      final tile = box(const Offset(50, 50), 30, 30, 5);
      _shadowRRect(c, tile);
      c.drawRRect(tile, _p(paper));
      c.drawRRect(tile, _stroke(const Color(0xFF3A8D8C), 2));
      _text(c, cover.label.isEmpty ? 'Fe' : cover.label, const Offset(50, 52), 15, ink);
    case 'pawc':
      // Pati izi ve yaprak.
      _bg(c, seed, tint: const Color(0xFF4F7F52));
      final leaf = Path()
        ..moveTo(20, 84)
        ..quadraticBezierTo(18, 58, 44, 50)
        ..quadraticBezierTo(46, 76, 20, 84)
        ..close();
      c.drawPath(leaf, _p(const Color(0xFF9CC17E)));
      c.drawLine(const Offset(20, 84), const Offset(40, 56), _stroke(const Color(0xFF5E8A47), 1.6));
      final pad = Offset(60 + v * 2.0, 58);
      c.drawOval(Rect.fromCenter(center: pad, width: 24, height: 20), _p(paper));
      for (var k = 0; k < 4; k++) {
        final a = math.pi * (1.15 + k * 0.23);
        c.drawOval(Rect.fromCenter(center: pad + Offset(math.cos(a) * 19, math.sin(a) * 17), width: 9, height: 11), _p(paper));
      }
    case 'duelc':
      // İki yarı, iki düğme, ortada şimşek.
      c.drawRect(const Rect.fromLTWH(0, 0, 100, 50), _p(const Color(0xFF2E5E8C)));
      c.drawRect(const Rect.fromLTWH(0, 50, 100, 50), _p(const Color(0xFFB23A48)));
      for (var k = 0; k < 2; k++) {
        final o = Offset(30.0 + k * 40, 25);
        c.drawRRect(box(o, 28, 12, 6), _p(paper.withValues(alpha: 0.9)));
        c.drawRRect(box(Offset(30.0 + k * 40, 75), 28, 12, 6), _p(paper.withValues(alpha: 0.9)));
      }
      final bolt = Path()
        ..moveTo(54, 36)
        ..lineTo(42, 52)
        ..lineTo(50, 52)
        ..lineTo(46, 66)
        ..lineTo(58, 48)
        ..lineTo(50, 48)
        ..close();
      c.drawPath(bolt, _p(const Color(0xFFE9B949)));
      c.drawPath(bolt, _stroke(ink.withValues(alpha: 0.4), 1));
    case 'scalec':
      // Terazi: iki kefe, biri daha ağır.
      _bg(c, seed, tint: const Color(0xFFE07A5F));
      c.drawLine(const Offset(50, 22), const Offset(50, 80), _stroke(paper, 3));
      c.drawRRect(box(const Offset(50, 82), 30, 6, 3), _p(paper));
      final tilt = v.isEven ? 6.0 : -6.0;
      c.drawLine(Offset(22, 30 - tilt), Offset(78, 30 + tilt), _stroke(paper, 3));
      for (var k = 0; k < 2; k++) {
        final x = k == 0 ? 22.0 : 78.0;
        final y = (k == 0 ? 30 - tilt : 30 + tilt) + 18;
        c.drawLine(Offset(x, y - 18), Offset(x - 10, y), _stroke(paper.withValues(alpha: 0.8), 1.2));
        c.drawLine(Offset(x, y - 18), Offset(x + 10, y), _stroke(paper.withValues(alpha: 0.8), 1.2));
        c.drawPath(
            Path()
              ..moveTo(x - 12, y)
              ..quadraticBezierTo(x, y + 9, x + 12, y)
              ..close(),
            _p(paper));
        if ((k == 0) == v.isEven) c.drawCircle(Offset(x, y - 4), 5, _p(const Color(0xFF22303F)));
      }
    default:
      return false;
  }
  return true;
}
