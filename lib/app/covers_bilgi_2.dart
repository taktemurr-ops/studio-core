part of 'covers.dart';

/// Bilgi Yarışması ikinci kapak dosyası. Türler:
/// sportquizc: Spor Bilgisi, şerit çizgili stadyum zemini üzerinde soru
/// işaretli kupa, kurdeleli madalya ve kronometre. Arcade merkezindeki top
/// ('ball') kapaklarından ayrı, yalnızca bu oyuna ait.
bool _paintBilgi2Cover(Canvas c, GameCover cover, Color seed) {
  if (cover.kind != 'sportquizc') return false;
  final v = cover.v;
  const ink = Color(0xFF22303F);
  const gold = Color(0xFFF2B53A);
  const goldDark = Color(0xFFB57F16);

  // Çim şeritleri ve saha çizgisi
  _bg(c, seed, tint: const Color(0xFF2E8B4E));
  for (var i = 0; i < 5; i++) {
    if (i.isOdd) {
      c.drawRect(Rect.fromLTWH(0, 60 + i * 8.0, 100, 8), _p(Colors.black.withValues(alpha: 0.08)));
    }
  }
  c.drawLine(const Offset(0, 60), const Offset(100, 60), _stroke(Colors.white70, 1.4));
  c.drawArc(Rect.fromCenter(center: const Offset(50, 100), width: 70, height: 50), math.pi, math.pi, false,
      _stroke(Colors.white54, 1.2));

  // Kupa: gövde, kulplar, ayak ve kaide
  final cup = Path()
    ..moveTo(30, 16)
    ..lineTo(70, 16)
    ..quadraticBezierTo(70, 50, 50, 54)
    ..quadraticBezierTo(30, 50, 30, 16)
    ..close();
  c.drawPath(cup.shift(const Offset(0, 2)), _p(Colors.black26));
  c.drawPath(
      cup,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFFFE08A), gold, goldDark])
            .createShader(const Rect.fromLTWH(30, 16, 40, 38)));
  final handle = _stroke(gold, 3.2);
  c.drawArc(Rect.fromCenter(center: const Offset(30, 28), width: 16, height: 18), math.pi / 2, math.pi, false, handle);
  c.drawArc(Rect.fromCenter(center: const Offset(70, 28), width: 16, height: 18), -math.pi / 2, math.pi, false, handle);
  c.drawRect(const Rect.fromLTWH(46, 53, 8, 9), _p(goldDark));
  final plinth = RRect.fromRectAndRadius(const Rect.fromLTWH(36, 62, 28, 10), const Radius.circular(2));
  _shadowRRect(c, plinth, dy: 1.6);
  c.drawRRect(plinth, _p(const Color(0xFF5B3A24)));
  c.drawRect(const Rect.fromLTWH(41, 65, 18, 4), _p(gold.withValues(alpha: 0.8)));
  _text(c, '?', const Offset(50, 31), 20, ink);

  // Madalya (sol alt): kurdele ve disk
  final ribbon = [const Color(0xFFE2574C), const Color(0xFF3075C4), const Color(0xFF9763BC)][v % 3];
  c.drawPath(Path()..addPolygon(const [Offset(8, 62), Offset(16, 62), Offset(22, 78), Offset(16, 80)], true), _p(ribbon));
  c.drawPath(Path()..addPolygon(const [Offset(28, 62), Offset(20, 62), Offset(14, 78), Offset(20, 80)], true),
      _p(Color.lerp(ribbon, Colors.black, 0.2)!));
  _stone(c, const Offset(18, 86), 8, const Color(0xFFC9CED6));
  c.drawCircle(const Offset(18, 86), 5, _stroke(Colors.white70, 1));
  _text(c, '1', const Offset(18, 86.5), 8, ink);

  // Kronometre (sağ alt)
  const sw = Offset(80, 84);
  c.drawRect(Rect.fromCenter(center: sw - const Offset(0, 12), width: 5, height: 4), _p(const Color(0xFFDDE3EA)));
  c.drawCircle(sw + const Offset(0, 1.2), 10.5, _p(Colors.black26));
  c.drawCircle(sw, 10.5, _p(Colors.white));
  c.drawCircle(sw, 10.5, _stroke(ink, 1.6));
  for (var k = 0; k < 12; k++) {
    final a = k * math.pi / 6;
    c.drawLine(sw + Offset(math.cos(a) * 8, math.sin(a) * 8), sw + Offset(math.cos(a) * 9.4, math.sin(a) * 9.4),
        _stroke(ink, 0.7));
  }
  c.drawArc(Rect.fromCircle(center: sw, radius: 6.5), -math.pi / 2, math.pi * 0.7, true,
      _p(const Color(0xFFE2574C).withValues(alpha: 0.35)));
  c.drawLine(sw, sw + Offset(math.cos(math.pi * 0.2) * 7, math.sin(math.pi * 0.2) * 7), _stroke(const Color(0xFFE2574C), 1.4));
  c.drawCircle(sw, 1.4, _p(ink));
  return true;
}
