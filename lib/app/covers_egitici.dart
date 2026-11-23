part of 'covers.dart';

/// Eğitici ve Çocuk oyunlarının kapak resimleri: yumuşak, sıcak renkler,
/// büyük ve sade şekiller (okuma bilmeyen çocuk da tanısın diye).
bool _paintEgiticiCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const kid = [
    Color(0xFFE76F51),
    Color(0xFF2A9D8F),
    Color(0xFFE9C46A),
    Color(0xFF457B9D),
    Color(0xFFB5838D),
    Color(0xFF8AB17D),
  ];
  const cream = Color(0xFFFFF8EC);
  const ink = Color(0xFF3D405B);
  RRect card(Offset o, double w, double h, [double r = 8]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));

  switch (cover.kind) {
    case 'abcc':
      _bg(c, seed, tint: const Color(0xFFFFE8D6));
      const letters = ['A', 'B', 'C'];
      for (var k = 0; k < 3; k++) {
        final o = Offset(26 + k * 24.0, 50 + (k.isOdd ? -8.0 : 6.0));
        c.drawRRect(card(o, 22, 24, 6), _p(kid[(k + v) % kid.length]));
        _text(c, letters[k], o, 15, cream);
      }
    case 'numc':
      _bg(c, seed, tint: const Color(0xFFDDEFE7));
      for (var k = 0; k < 3; k++) {
        final o = Offset(28 + k * 22.0, 44);
        _text(c, '${k + 1}', o, 20, kid[(k + v) % kid.length]);
        for (var d = 0; d <= k; d++) {
          c.drawCircle(Offset(o.dx - 5 + d * 5.0, 66), 2.4, _p(ink));
        }
      }
    case 'clockc':
      _bg(c, seed, tint: const Color(0xFFE3EEF7));
      const mc = Offset(50, 50);
      c.drawCircle(mc, 30, _p(cream));
      c.drawCircle(mc, 30, _stroke(ink, 3));
      for (var k = 0; k < 12; k++) {
        final a = math.pi / 6 * k;
        c.drawCircle(mc + Offset(math.cos(a) * 24, math.sin(a) * 24), k % 3 == 0 ? 2.2 : 1.2, _p(ink));
      }
      c.drawLine(mc, mc + const Offset(0, -20), _stroke(kid[0], 3.5));
      c.drawLine(mc, mc + const Offset(14, 0), _stroke(kid[3], 4));
      c.drawCircle(mc, 3, _p(ink));
    case 'shapec':
      _bg(c, seed, tint: const Color(0xFFFFF1C9));
      c.drawCircle(const Offset(30, 36), 13, _p(kid[(0 + v) % kid.length]));
      c.drawRect(Rect.fromCenter(center: const Offset(68, 36), width: 24, height: 24), _p(kid[(1 + v) % kid.length]));
      final tri = Path()
        ..moveTo(50, 56)
        ..lineTo(66, 82)
        ..lineTo(34, 82)
        ..close();
      c.drawPath(tri, _p(kid[(3 + v) % kid.length]));
    case 'flagkc':
      _bg(c, seed, tint: const Color(0xFFE8F1F2));
      c.drawLine(const Offset(26, 20), const Offset(26, 84), _stroke(ink, 3));
      for (var k = 0; k < 3; k++) {
        c.drawRect(Rect.fromLTWH(28, 22 + k * 10.0, 46, 10), _p(kid[(k * 2 + v) % kid.length]));
      }
      c.drawCircle(const Offset(51, 37), 5, _p(cream));
    case 'pinc':
      _bg(c, seed, tint: const Color(0xFFDCEBDF));
      final land = Path()
        ..moveTo(14, 60)
        ..cubicTo(22, 40, 44, 46, 52, 36)
        ..cubicTo(62, 26, 82, 34, 86, 52)
        ..cubicTo(90, 70, 60, 76, 46, 72)
        ..cubicTo(32, 68, 18, 78, 14, 60)
        ..close();
      c.drawPath(land, _p(const Color(0xFF8AB17D)));
      final pin = Path()
        ..moveTo(56, 58)
        ..cubicTo(46, 44, 48, 30, 56, 30)
        ..cubicTo(64, 30, 66, 44, 56, 58)
        ..close();
      c.drawPath(pin, _p(kid[0]));
      c.drawCircle(const Offset(56, 38), 3.5, _p(cream));
    case 'plusc':
      _bg(c, seed, tint: const Color(0xFFFDE2E4));
      _text(c, '2', const Offset(24, 50), 20, kid[3]);
      _text(c, v.isOdd ? '−' : '+', const Offset(42, 50), 20, ink);
      _text(c, '3', const Offset(60, 50), 20, kid[1]);
      _text(c, '=', const Offset(76, 50), 18, ink);
      _text(c, v.isOdd ? '?' : '5', const Offset(50, 76), 16, kid[0]);
    case 'mulc':
      _bg(c, seed, tint: const Color(0xFFE7E6F7));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          c.drawRRect(card(Offset(26 + x * 16.0, 26 + y * 16.0), 13, 13, 3),
              _p((x + 1) * (y + 1) % 2 == 0 ? kid[(3 + v) % kid.length] : const Color(0xFFCDD3E8)));
        }
      }
      _text(c, '×', const Offset(82, 82), 16, ink);
    case 'pianoc':
      _bg(c, seed, tint: const Color(0xFFFFE8D6));
      for (var k = 0; k < 6; k++) {
        final r = Rect.fromLTWH(16 + k * 11.5, 36, 11, 40);
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _p(kid[(k + v) % kid.length]));
      }
      for (var k = 0; k < 5; k++) {
        if (k == 2) continue;
        c.drawRect(Rect.fromLTWH(24 + k * 11.5, 36, 7, 22), _p(ink));
      }
    case 'tracec':
      _bg(c, seed, tint: const Color(0xFFFFF4D6));
      final s = Path()
        ..moveTo(30, 78)
        ..lineTo(50, 22)
        ..lineTo(70, 78);
      c.drawPath(s, _stroke(const Color(0x553D405B), 10));
      for (var k = 0; k < 7; k++) {
        c.drawCircle(Offset(30 + k * 3.3, 78 - k * 9.3), 2, _p(kid[0]));
      }
      c.drawLine(const Offset(38, 56), const Offset(62, 56), _stroke(const Color(0x553D405B), 8));
      c.drawCircle(const Offset(54, 32), 4, _p(kid[3]));
    case 'sylc':
      _bg(c, seed, tint: const Color(0xFFE6F2EA));
      c.drawRRect(card(const Offset(32, 50), 30, 26), _p(kid[(1 + v) % kid.length]));
      c.drawRRect(card(const Offset(68, 50), 30, 26), _p(kid[(2 + v) % kid.length]));
      _text(c, 'ke', const Offset(32, 50), 14, cream);
      _text(c, 'di', const Offset(68, 50), 14, ink);
    case 'trmapc':
      _bg(c, seed, tint: const Color(0xFFE3EEF7));
      final tr = Path()
        ..moveTo(10, 48)
        ..lineTo(22, 40)
        ..lineTo(42, 38)
        ..lineTo(60, 34)
        ..lineTo(82, 36)
        ..lineTo(92, 46)
        ..lineTo(84, 58)
        ..lineTo(62, 62)
        ..lineTo(40, 66)
        ..lineTo(22, 62)
        ..close();
      c.drawPath(tr, _p(kid[(0 + v) % kid.length]));
      c.drawPath(tr, _stroke(cream, 1.5));
      for (var k = 0; k < 4; k++) {
        c.drawLine(Offset(28 + k * 16.0, 39), Offset(26 + k * 16.0, 64), _stroke(cream, 1.2));
      }
    case 'fracc':
      _bg(c, seed, tint: const Color(0xFFFFF1C9));
      const mf = Offset(50, 50);
      final rf = Rect.fromCircle(center: mf, radius: 28);
      c.drawCircle(mf, 28, _p(cream));
      c.drawArc(rf, -math.pi / 2, math.pi * 2 * (v.isOdd ? 0.25 : 0.75), true, _p(kid[(0 + v) % kid.length]));
      for (var k = 0; k < 4; k++) {
        final a = math.pi / 2 * k;
        c.drawLine(mf, mf + Offset(math.cos(a) * 28, math.sin(a) * 28), _stroke(ink, 1.5));
      }
      c.drawCircle(mf, 28, _stroke(ink, 2));
    case 'coinc':
      _bg(c, seed, tint: const Color(0xFFE6F2EA));
      for (var k = 0; k < 3; k++) {
        final o = Offset(32 + k * 16.0, 64 - k * 12.0);
        c.drawCircle(o, 15, _p(const Color(0xFFE9C46A)));
        c.drawCircle(o, 15, _stroke(const Color(0xFFB08A2E), 2));
        _text(c, '${[1, 5, 10][k]}', o, 10, const Color(0xFF7A5A12));
      }
    case 'codec':
      _bg(c, seed, tint: const Color(0xFFE7E6F7));
      const arrows = ['→', '↑', '→', '↓'];
      for (var k = 0; k < 4; k++) {
        final o = Offset(22 + k * 19.0, 34);
        c.drawRRect(card(o, 16, 16, 4), _p(kid[(k + v) % kid.length]));
        _text(c, arrows[k], o, 11, cream);
      }
      c.drawCircle(const Offset(30, 68), 7, _p(kid[1]));
      c.drawRRect(card(const Offset(72, 68), 14, 14, 3), _p(kid[2]));
      c.drawLine(const Offset(38, 68), const Offset(64, 68), _stroke(const Color(0x663D405B), 2));
    case 'notec':
      _bg(c, seed, tint: const Color(0xFFFFE8D6));
      for (var k = 0; k < 5; k++) {
        c.drawLine(Offset(14, 34 + k * 8.0), Offset(86, 34 + k * 8.0), _stroke(const Color(0x663D405B), 1.2));
      }
      for (var k = 0; k < 3; k++) {
        final o = Offset(30 + k * 20.0, 62 - k * 8.0);
        c.drawOval(Rect.fromCenter(center: o, width: 11, height: 8), _p(kid[(k + v) % kid.length]));
        c.drawLine(o + const Offset(5, 0), o + const Offset(5, -22), _stroke(ink, 1.6));
      }
    case 'sunc':
      _bg(c, seed, tint: const Color(0xFF1D2D44));
      c.drawCircle(const Offset(22, 50), 14, _p(const Color(0xFFF4A261)));
      for (var k = 0; k < 3; k++) {
        c.drawCircle(const Offset(22, 50), 26.0 + k * 14, _stroke(const Color(0x44FFFFFF), 1));
      }
      c.drawCircle(const Offset(48, 50), 4, _p(kid[3]));
      c.drawCircle(const Offset(62, 36), 5, _p(kid[0]));
      c.drawCircle(const Offset(76, 58), 7, _p(kid[2]));
    case 'trafficc':
      _bg(c, seed, tint: const Color(0xFFE6F2EA));
      c.drawRRect(card(const Offset(50, 48), 26, 60, 8), _p(ink));
      const lights = [Color(0xFFE63946), Color(0xFFF4A261), Color(0xFF2A9D8F)];
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(50, 30 + k * 18.0), 7, _p(k == (v % 3) ? lights[k] : lights[k].withValues(alpha: 0.35)));
      }
      c.drawRect(const Rect.fromLTWH(47, 78, 6, 14), _p(ink));
    case 'seasonc':
      _bg(c, seed, tint: const Color(0xFFE3EEF7));
      const qs = [Color(0xFF8AB17D), Color(0xFFE9C46A), Color(0xFFE76F51), Color(0xFFBFD7EA)];
      for (var k = 0; k < 4; k++) {
        c.drawArc(Rect.fromCircle(center: const Offset(50, 50), radius: 30), math.pi / 2 * k, math.pi / 2, true, _p(qs[k]));
      }
      c.drawCircle(const Offset(50, 50), 8, _p(cream));
    case 'eyec':
      _bg(c, seed, tint: const Color(0xFFFFF4D6));
      final eye = Path()
        ..moveTo(16, 50)
        ..quadraticBezierTo(50, 18, 84, 50)
        ..quadraticBezierTo(50, 82, 16, 50)
        ..close();
      c.drawPath(eye, _p(cream));
      c.drawPath(eye, _stroke(ink, 2.5));
      c.drawCircle(const Offset(50, 50), 12, _p(kid[(3 + v) % kid.length]));
      c.drawCircle(const Offset(50, 50), 5, _p(ink));
      c.drawCircle(const Offset(54, 46), 2, _p(Colors.white));
    case 'animalc':
      _bg(c, seed, tint: const Color(0xFFE6F2EA));
      const face = Color(0xFFE9B872);
      c.drawCircle(const Offset(34, 30), 9, _p(face));
      c.drawCircle(const Offset(66, 30), 9, _p(face));
      c.drawCircle(const Offset(50, 52), 26, _p(face));
      c.drawCircle(const Offset(41, 48), 3, _p(ink));
      c.drawCircle(const Offset(59, 48), 3, _p(ink));
      c.drawOval(Rect.fromCenter(center: const Offset(50, 60), width: 10, height: 7), _p(const Color(0xFF8D5A3B)));
    case 'engc':
      _bg(c, seed, tint: const Color(0xFFE7E6F7));
      c.drawRRect(card(const Offset(40, 52), 40, 50, 6), _p(cream));
      c.drawRRect(card(const Offset(40, 52), 40, 50, 6), _stroke(ink, 2));
      _text(c, 'Aa', const Offset(40, 44), 15, kid[(0 + v) % kid.length]);
      c.drawCircle(const Offset(40, 66), 6, _p(kid[1]));
      c.drawRRect(card(const Offset(68, 40), 26, 30, 5), _p(kid[3]));
      _text(c, 'Bb', const Offset(68, 40), 11, cream);
    case 'mazekc':
      _bg(c, seed, tint: const Color(0xFFFFF1C9));
      final w = _stroke(kid[(3 + v) % kid.length], 5);
      c.drawRect(const Rect.fromLTWH(18, 18, 64, 64), w);
      c.drawLine(const Offset(18, 40), const Offset(60, 40), w);
      c.drawLine(const Offset(40, 60), const Offset(82, 60), w);
      c.drawLine(const Offset(40, 40), const Offset(40, 60), w);
      c.drawCircle(const Offset(28, 30), 5, _p(kid[0]));
      final star = Path();
      for (var k = 0; k < 10; k++) {
        final a = -math.pi / 2 + math.pi / 5 * k;
        final r = k.isEven ? 7.0 : 3.0;
        final q = Offset(72 + math.cos(a) * r, 72 + math.sin(a) * r);
        if (k == 0) {
          star.moveTo(q.dx, q.dy);
        } else {
          star.lineTo(q.dx, q.dy);
        }
      }
      c.drawPath(star..close(), _p(kid[2]));
    case 'paintkc':
      _bg(c, seed, tint: const Color(0xFFFDE2E4));
      final pal = Path()
        ..moveTo(50, 20)
        ..cubicTo(84, 20, 90, 54, 76, 66)
        ..cubicTo(66, 74, 60, 62, 52, 70)
        ..cubicTo(44, 80, 16, 76, 14, 52)
        ..cubicTo(12, 32, 30, 20, 50, 20)
        ..close();
      c.drawPath(pal, _p(cream));
      c.drawPath(pal, _stroke(const Color(0xFFD8C3A5), 2));
      for (var k = 0; k < 5; k++) {
        final a = math.pi * (0.85 + k * 0.28);
        c.drawCircle(Offset(48 + math.cos(a) * 22, 46 + math.sin(a) * 18), 6, _p(kid[(k + v) % kid.length]));
      }
    case 'numpaintc':
      _bg(c, seed, tint: const Color(0xFFE3EEF7));
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          final n = (x + y + v) % 3 + 1;
          final r = Rect.fromLTWH(22 + x * 19.0, 22 + y * 19.0, 18, 18);
          c.drawRect(r, _p(x + y < 3 ? kid[n] : cream));
          c.drawRect(r, _stroke(const Color(0x553D405B), 1));
          if (x + y >= 3) _text(c, '$n', r.center, 9, ink);
        }
      }
    case 'racec':
      _bg(c, seed, tint: const Color(0xFFDDEFE7));
      c.drawLine(const Offset(14, 70), const Offset(86, 70), _stroke(ink, 2));
      for (var k = 0; k < 2; k++) {
        final o = Offset(34 + k * 30.0, 52);
        c.drawRRect(card(o, 24, 14, 5), _p(kid[(k * 3 + v) % kid.length]));
        c.drawCircle(o + const Offset(-7, 9), 4, _p(ink));
        c.drawCircle(o + const Offset(7, 9), 4, _p(ink));
      }
      _text(c, '7×8', const Offset(50, 28), 13, kid[0]);
    default:
      return false;
  }
  return true;
}
