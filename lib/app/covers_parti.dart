part of 'covers.dart';

/// Parti ve Aile oyunlarının kapak resimleri (100×100 mantıksal birim).
bool _paintPartiCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const coral = Color(0xFFE0735A);
  const sea = Color(0xFF3B86A8);
  const sun = Color(0xFFD9A441);
  const leaf = Color(0xFF6A9E4F);
  const plum = Color(0xFF8A5BA6);
  const paper = Color(0xFFF7F2E8);
  const ink = Color(0xFF26313D);
  const fun = [coral, sea, sun, leaf, plum];
  RRect box(Offset o, double w, double h, [double r = 6]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));
  void card(Offset o, double w, double h, double angle, Color edge) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(angle);
    c.drawRRect(box(Offset.zero, w, h), _p(paper));
    c.drawRRect(box(Offset.zero, w, h), _stroke(edge, 2.5));
    c.restore();
  }

  void person(Offset o, Color col, [double s = 1]) {
    c.drawCircle(o + Offset(0, -9 * s), 6 * s, _p(col));
    c.drawRRect(box(o + Offset(0, 6 * s), 16 * s, 16 * s, 7 * s), _p(col));
  }

  switch (cover.kind) {
    case 'partyc':
      _bg(c, seed, tint: const Color(0xFF7A3E5C));
      for (var k = 0; k < 18; k++) {
        final x = 10 + (k * 37 + v * 11) % 80;
        final y = 10 + (k * 23) % 80;
        c.save();
        c.translate(x.toDouble(), y.toDouble());
        c.rotate(k * 0.7);
        c.drawRect(const Rect.fromLTWH(-3, -1.5, 6, 3), _p(fun[k % fun.length]));
        c.restore();
      }
      c.drawCircle(const Offset(50, 54), 20, _p(sun));
      c.drawArc(Rect.fromCenter(center: const Offset(50, 56), width: 22, height: 16), 0.2, math.pi - 0.4, false, _stroke(ink, 2.5));
      c.drawCircle(const Offset(43, 49), 2.2, _p(ink));
      c.drawCircle(const Offset(57, 49), 2.2, _p(ink));
    case 'namecityc':
      _bg(c, seed, tint: const Color(0xFF2E5E8C));
      c.drawRRect(box(const Offset(50, 54), 62, 52), _p(paper));
      for (var k = 0; k < 4; k++) {
        c.drawLine(Offset(22, 40.0 + k * 10), const Offset(78, 40) + Offset(0, k * 10.0), _stroke(const Color(0xFFBDB29E), 1.2));
      }
      c.drawLine(const Offset(40, 30), const Offset(40, 78), _stroke(coral, 1.5));
      c.drawRRect(box(const Offset(50, 22), 24, 22), _p(coral));
      _text(c, const ['A', 'K', 'M', 'S'][v % 4], const Offset(50, 22), 15, Colors.white);
    case 'tabuc':
      _bg(c, seed, tint: const Color(0xFF9E3B3B));
      card(const Offset(50, 52), 46, 60, -0.08, coral);
      c.drawRRect(box(const Offset(50, 36), 30, 8, 3), _p(ink));
      for (var k = 0; k < 4; k++) {
        c.drawRRect(box(Offset(50, 50.0 + k * 8), 26, 4, 2), _p(const Color(0xFFC8553D)));
      }
      c.drawCircle(const Offset(76, 24), 11, _stroke(Colors.white, 3));
      c.drawLine(const Offset(69, 31), const Offset(83, 17), _stroke(Colors.white, 3));
    case 'drawc':
      _bg(c, seed, tint: const Color(0xFF3F7D6B));
      c.drawRRect(box(const Offset(48, 54), 60, 50), _p(Colors.white));
      final sq = Path()
        ..moveTo(26, 64)
        ..cubicTo(34, 40, 44, 74, 52, 50)
        ..cubicTo(58, 34, 66, 62, 72, 46);
      c.drawPath(sq, _stroke(fun[v % fun.length], 4));
      c.save();
      c.translate(74, 28);
      c.rotate(0.7);
      c.drawRect(const Rect.fromLTWH(-4, -16, 8, 26), _p(sun));
      c.drawPath(Path()
        ..moveTo(-4, 10)
        ..lineTo(4, 10)
        ..lineTo(0, 17)
        ..close(), _p(ink));
      c.restore();
    case 'mimec':
      _bg(c, seed, tint: const Color(0xFF5B4A7A));
      c.drawOval(Rect.fromCenter(center: const Offset(40, 50), width: 34, height: 42), _p(paper));
      c.drawOval(Rect.fromCenter(center: const Offset(62, 54), width: 34, height: 42), _p(const Color(0xFF26313D)));
      c.drawArc(Rect.fromCenter(center: const Offset(40, 56), width: 16, height: 10), 0.2, math.pi - 0.4, false, _stroke(ink, 2.5));
      c.drawArc(Rect.fromCenter(center: const Offset(62, 64), width: 16, height: 10), math.pi + 0.2, math.pi - 0.4, false, _stroke(paper, 2.5));
      c.drawCircle(const Offset(34, 44), 2.2, _p(ink));
      c.drawCircle(const Offset(46, 44), 2.2, _p(ink));
      c.drawCircle(const Offset(56, 48), 2.2, _p(paper));
      c.drawCircle(const Offset(68, 48), 2.2, _p(paper));
    case 'truthc':
      _bg(c, seed, tint: const Color(0xFF7A4E7E));
      card(const Offset(38, 52), 34, 46, -0.18, sea);
      card(const Offset(62, 50), 34, 46, 0.16, coral);
      _text(c, '?', const Offset(37, 52), 20, sea);
      _text(c, '!', const Offset(62, 50), 20, coral);
    case 'spinc':
      _bg(c, seed, tint: const Color(0xFF2E7D7A));
      c.drawCircle(const Offset(50, 50), 34, _p(const Color(0x33FFFFFF)));
      for (var k = 0; k < 6; k++) {
        final a = k * math.pi / 3;
        c.drawCircle(Offset(50 + 30 * math.cos(a), 50 + 30 * math.sin(a)), 6, _p(fun[k % fun.length]));
      }
      c.save();
      c.translate(50, 50);
      c.rotate(-0.6 + v * 0.9);
      c.drawPath(Path()
        ..moveTo(22, 0)
        ..lineTo(12, -6)
        ..lineTo(12, -2.5)
        ..lineTo(-16, -2.5)
        ..lineTo(-16, 2.5)
        ..lineTo(12, 2.5)
        ..lineTo(12, 6)
        ..close(), _p(coral));
      c.restore();
      c.drawCircle(const Offset(50, 50), 4, _p(ink));
    case 'foreheadc':
      _bg(c, seed, tint: const Color(0xFFB0763B));
      c.drawCircle(const Offset(50, 64), 22, _p(const Color(0xFFF1C9A5)));
      c.drawRRect(box(const Offset(50, 30), 30, 20, 4), _p(ink));
      c.drawRRect(box(const Offset(50, 30), 26, 16, 3), _p(paper));
      _text(c, '?', const Offset(50, 30), 12, coral);
      c.drawCircle(const Offset(43, 64), 2.4, _p(ink));
      c.drawCircle(const Offset(57, 64), 2.4, _p(ink));
      c.drawArc(Rect.fromCenter(center: const Offset(50, 72), width: 12, height: 6), 0.2, math.pi - 0.4, false, _stroke(ink, 2));
    case 'vampc':
      _bg(c, seed, tint: const Color(0xFF1F2440));
      c.drawCircle(const Offset(72, 26), 12, _p(const Color(0xFFF2E6B8)));
      c.drawCircle(const Offset(77, 23), 10, _p(const Color(0xFF1F2440)));
      for (var k = 0; k < 4; k++) {
        final x = 18 + k * 18.0;
        c.drawRect(Rect.fromLTWH(x, 62, 14, 22), _p(const Color(0xFF3A3F63)));
        c.drawPath(Path()
          ..moveTo(x - 2, 62)
          ..lineTo(x + 7, 52)
          ..lineTo(x + 16, 62)
          ..close(), _p(const Color(0xFF4B5182)));
        c.drawRect(Rect.fromLTWH(x + 4, 68, 6, 6), _p(k == v % 4 ? sun : const Color(0xFF2A2E4D)));
      }
      final wing = Path()
        ..moveTo(30, 30)
        ..quadraticBezierTo(36, 22, 42, 30)
        ..quadraticBezierTo(46, 26, 50, 30)
        ..quadraticBezierTo(54, 26, 58, 30)
        ..quadraticBezierTo(64, 22, 70, 30)
        ..quadraticBezierTo(60, 34, 50, 40)
        ..quadraticBezierTo(40, 34, 30, 30)
        ..close();
      c.save();
      c.translate(-12, 2);
      c.scale(0.8);
      c.drawPath(wing, _p(const Color(0xFF0E1022)));
      c.restore();
    case 'spyc':
      _bg(c, seed, tint: const Color(0xFF3A4A5C));
      c.drawOval(Rect.fromCenter(center: const Offset(50, 38), width: 52, height: 12), _p(ink));
      c.drawRRect(box(const Offset(50, 30), 30, 18, 5), _p(ink));
      c.drawRRect(box(const Offset(50, 37), 30, 3, 1), _p(coral));
      c.drawCircle(const Offset(40, 58), 9, _stroke(paper, 3));
      c.drawCircle(const Offset(60, 58), 9, _stroke(paper, 3));
      c.drawLine(const Offset(49, 58), const Offset(51, 58), _stroke(paper, 3));
      c.drawLine(const Offset(66, 64), const Offset(76, 76), _stroke(paper, 4));
    case 'famquizc':
      _bg(c, seed, tint: const Color(0xFF2E5E8C));
      for (var k = 0; k < 4; k++) {
        final o = Offset(30 + (k % 2) * 40.0, 34 + (k ~/ 2) * 34.0);
        c.drawRRect(box(o, 34, 26), _p(k == v % 4 ? leaf : paper));
      }
      _text(c, '?', const Offset(50, 51), 22, sun);
    case 'scorec':
      _bg(c, seed, tint: const Color(0xFF4D6B4A));
      c.drawRRect(box(const Offset(50, 54), 60, 62), _p(paper));
      c.drawRRect(box(const Offset(50, 24), 22, 8, 3), _p(const Color(0xFF8B6B4A)));
      for (var k = 0; k < 4; k++) {
        c.drawCircle(Offset(28, 38.0 + k * 11), 3, _p(fun[k]));
        c.drawRRect(box(Offset(46, 38.0 + k * 11), 22, 4, 2), _p(const Color(0xFFBDB29E)));
        _text(c, '${[12, 9, 7, 4][(k + v) % 4]}', Offset(70, 38.0 + k * 11), 8, ink);
      }
    case 'cluec':
      _bg(c, seed, tint: const Color(0xFF34495E));
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          final i = (x * 7 + y * 3 + v) % 9;
          final col = i < 3 ? coral : (i < 6 ? sea : (i < 8 ? paper : ink));
          c.drawRRect(box(Offset(22 + x * 14.0, 22 + y * 14.0), 12, 12, 2.5), _p(col));
        }
      }
    case 'storyc':
      _bg(c, seed, tint: const Color(0xFF6B4E3A));
      final book = Path()
        ..moveTo(18, 70)
        ..lineTo(50, 76)
        ..lineTo(82, 70)
        ..lineTo(82, 40)
        ..lineTo(50, 46)
        ..lineTo(18, 40)
        ..close();
      c.drawPath(book, _p(paper));
      c.drawLine(const Offset(50, 46), const Offset(50, 76), _stroke(const Color(0xFFBDB29E), 1.5));
      for (var k = 0; k < 3; k++) {
        c.drawRRect(box(Offset(30 + k * 20.0, 26.0 - (k == 1 ? 6 : 0)), 14, 14, 3), _p(fun[(k + v) % fun.length]));
      }
    case 'chainc':
      _bg(c, seed, tint: const Color(0xFF41606E));
      for (var k = 0; k < 4; k++) {
        final o = Offset(24 + k * 17.0, 50.0 + (k.isEven ? -6 : 6));
        c.drawOval(Rect.fromCenter(center: o, width: 22, height: 14), _stroke(fun[(k + v) % fun.length], 4));
      }
    case 'reflexc':
      _bg(c, seed, tint: const Color(0xFF8C3B2E));
      c.drawPath(Path()
        ..moveTo(56, 14)
        ..lineTo(34, 54)
        ..lineTo(48, 54)
        ..lineTo(42, 86)
        ..lineTo(68, 42)
        ..lineTo(53, 42)
        ..close(), _p(sun));
      person(const Offset(20, 74), sea, 0.8);
      person(const Offset(80, 74), coral, 0.8);
    default:
      return false;
  }
  return true;
}
