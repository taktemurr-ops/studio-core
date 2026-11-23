part of 'covers.dart';

/// Özgün oyunların ikinci kapak dosyası: Kündekâri, Tezhip, Cam Boncuk, Çömlek.
bool _paintOzgun2Cover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  Path star(Offset m, double r, double inner, int points) {
    final p = Path();
    for (var k = 0; k < points * 2; k++) {
      final a = k * math.pi / points - math.pi / 2;
      final rr = k.isEven ? r : r * inner;
      final q = m + Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (k == 0) {
        p.moveTo(q.dx, q.dy);
      } else {
        p.lineTo(q.dx, q.dy);
      }
    }
    return p..close();
  }

  switch (cover.kind) {
    case 'kundec':
      _bg(c, seed, tint: const Color(0xFF4A2F1B));
      const wood = [Color(0xFF9C6B3F), Color(0xFFB7834F), Color(0xFF8A5A33), Color(0xFFC49563)];
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          final o = Offset(23 + x * 18.0, 23 + y * 18.0);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 17, 17), const Radius.circular(2)), _p(wood[(x + y * 2 + v) % 4]));
          c.drawPath(star(o + const Offset(8.5, 8.5), 6.5, 0.5, 8), _stroke(const Color(0xAAF4E3C1), 1.2));
        }
      }
      c.drawCircle(const Offset(50, 41), 2.4, _p(const Color(0xFFD9A441)));
      c.drawCircle(const Offset(41, 50), 2.4, _stroke(const Color(0xFF3E6FB0), 1.2));
    case 'tezhipc':
      _bg(c, seed, tint: const Color(0xFF15365F));
      const lapis = Color(0xFF1F4E8C), gold = Color(0xFFD4A017);
      c.drawCircle(const Offset(50, 50), 32, _p(const Color(0xFFF4EBD9)));
      for (var k = 0; k < 8; k++) {
        final a = k * math.pi / 4 + v * 0.2;
        final m = const Offset(50, 50) + Offset(math.cos(a) * 19, math.sin(a) * 19);
        c.drawPath(star(m, 7, 0.45, 4), _p(k.isEven ? lapis : gold));
      }
      c.drawPath(star(const Offset(50, 50), 12, 0.5, 8), _p(gold));
      c.drawCircle(const Offset(50, 50), 32, _stroke(gold, 2.5));
    case 'boncukc':
      _bg(c, seed, tint: const Color(0xFF3A2A22));
      const glass = [Color(0xFF1F5FAF), Color(0xFFE0A030), Color(0xFFB0303F), Color(0xFF2FA6A0), Color(0xFFF2EFE6)];
      for (var k = 5; k >= 1; k--) {
        c.drawCircle(const Offset(50, 48), k * 6.0, _p(glass[(k + v) % glass.length]));
      }
      c.drawCircle(const Offset(50, 48), 3.5, _p(const Color(0xFF3B3B3B)));
      c.drawCircle(const Offset(41, 39), 4, _p(const Color(0x66FFFFFF)));
      c.drawLine(const Offset(20, 82), const Offset(80, 82), _stroke(const Color(0xFFE07A2F), 3));
    case 'comlekc':
      _bg(c, seed, tint: const Color(0xFF5B4636));
      c.drawOval(const Rect.fromLTWH(14, 72, 72, 12), _p(const Color(0xFF8C7A68)));
      final pot = Path()
        ..moveTo(38, 76)
        ..cubicTo(22, 64, 26, 44, 40, 36)
        ..cubicTo(44, 32, 42, 24, 38, 20)
        ..lineTo(62, 20)
        ..cubicTo(58, 24, 56, 32, 60, 36)
        ..cubicTo(74, 44, 78, 64, 62, 76)
        ..close();
      c.drawPath(pot, _p(const Color(0xFFB8704A)));
      for (var k = 0; k < 3; k++) {
        final x = 36.0 + k * 12 + v;
        c.drawLine(Offset(x, 40), Offset(x, 72), _stroke(const Color(0x22FFFFFF), 2));
      }
      c.drawPath(pot, _stroke(const Color(0xFFD9A441), 1.4));
    default:
      return false;
  }
  return true;
}
