part of 'covers.dart';

/// Özgün oyunların üçüncü kapak dosyası: Hacivat ile Karagöz, Nasreddin Hoca
/// Fıkraları, Mozaik Restorasyonu.
bool _paintOzgun3Cover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  switch (cover.kind) {
    case 'karagozc':
      // Mum ışığıyla aydınlanan perde ve karşılıklı iki tasvir.
      _bg(c, seed, tint: const Color(0xFF3B2414));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 14, 80, 66), const Radius.circular(4)), _p(const Color(0xFF5A3A22)));
      final screen = const Rect.fromLTWH(14, 18, 72, 54);
      c.drawRect(
          screen,
          Paint()
            ..shader = const RadialGradient(colors: [Color(0xFFFFF3D6), Color(0xFFE8C98E), Color(0xFFB98A4E)], stops: [0, 0.6, 1])
                .createShader(Rect.fromCenter(center: const Offset(50, 52), width: 84, height: 80)));
      for (var k = 0; k < 7; k++) {
        c.drawRect(Rect.fromLTWH(14 + k * 72 / 7, 72, 72 / 7 - 1, 6), _p(k.isEven ? const Color(0xFFD9A441) : const Color(0xFF7A2E22)));
      }
      void puppet(double x, bool right, Color robe, bool tall) {
        c.save();
        c.translate(x, 70);
        c.scale(right ? 1 : -1, 1);
        final body = Path()
          ..moveTo(-4, -26)
          ..lineTo(5, -26)
          ..quadraticBezierTo(9, -12, 9, 0)
          ..lineTo(-8, 0)
          ..quadraticBezierTo(-7, -13, -4, -26)
          ..close();
        c.drawPath(body, _p(robe));
        c.drawCircle(const Offset(1, -30), 4.5, _p(const Color(0xDDE0B07A)));
        if (tall) {
          final hat = Path()
            ..moveTo(-3, -33)
            ..lineTo(5, -33)
            ..lineTo(4, -44)
            ..lineTo(-2, -44)
            ..close();
          c.drawPath(hat, _p(const Color(0xDDE8E2D0)));
          final beard = Path()
            ..moveTo(0, -27)
            ..lineTo(6, -27)
            ..lineTo(3, -21)
            ..close();
          c.drawPath(beard, _p(const Color(0xEE3B2A1E)));
        } else {
          c.drawCircle(const Offset(3, -26), 3.2, _p(const Color(0xF01E1410)));
          c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -38, 10, 4.5), const Radius.circular(2)), _p(const Color(0xDDC8553D)));
          c.drawCircle(const Offset(3.6, -31), 1.2, _p(const Color(0xFF1E1410)));
        }
        c.drawLine(const Offset(3, -22), Offset(12, -28 - v * 2.0), _stroke(robe, 2.6));
        c.restore();
      }

      puppet(34, true, const Color(0xD92E7D6B), true);
      puppet(66, false, const Color(0xD9B23A3A), false);
    case 'hocac':
      // Kocaman sarıklı Hoca, ters bindiği eşek ve ay.
      _bg(c, seed, tint: const Color(0xFF1F3B4D));
      c.drawCircle(Offset(76 - v * 3.0, 22), 8, _p(const Color(0xFFF5D06A)));
      c.drawCircle(Offset(80 - v * 3.0, 20), 7, _p(const Color(0xFF1F3B4D).withValues(alpha: 0.9)));
      // Eşek.
      c.drawOval(const Rect.fromLTWH(26, 56, 46, 20), _p(const Color(0xFF8C8A84)));
      c.drawCircle(const Offset(78, 56), 7, _p(const Color(0xFF8C8A84)));
      c.drawLine(const Offset(80, 50), const Offset(84, 40), _stroke(const Color(0xFF8C8A84), 3));
      c.drawLine(const Offset(76, 50), const Offset(76, 40), _stroke(const Color(0xFF8C8A84), 3));
      for (final x in const [32.0, 42.0, 58.0, 66.0]) {
        c.drawLine(Offset(x, 72), Offset(x, 86), _stroke(const Color(0xFF6B6963), 3));
      }
      // Hoca (ters oturmuş: yüzü kuyruğa dönük).
      final robe = Path()
        ..moveTo(36, 60)
        ..quadraticBezierTo(46, 34, 56, 60)
        ..close();
      c.drawPath(robe, _p(const Color(0xFF3A8D8C)));
      c.drawCircle(const Offset(46, 36), 7, _p(const Color(0xFFE0B07A)));
      c.drawOval(const Rect.fromLTWH(35, 20, 22, 14), _p(const Color(0xFFFBF7EE)));
      c.drawCircle(const Offset(46, 21), 2.4, _p(const Color(0xFF4F7F52)));
      final beard = Path()
        ..moveTo(39, 39)
        ..quadraticBezierTo(43, 52, 47, 39)
        ..close();
      c.drawPath(beard, _p(const Color(0xFFFBF7EE)));
      c.drawCircle(const Offset(42, 35), 1.1, _p(const Color(0xFF2A1A10)));
    case 'mozrestc':
      // Simetrik antik desen; bir köşesi kırık, yanında taşlar.
      _bg(c, seed, tint: const Color(0xFF3B3530));
      const cols = [Color(0xFFEDE3CC), Color(0xFFB5523B), Color(0xFF2B2622), Color(0xFFD39B3A), Color(0xFF3F5E7A)];
      const n = 9;
      const s = 7.0, ox = 18.5, oy = 14.0;
      c.drawRect(const Rect.fromLTWH(ox - 2, oy - 2, n * s + 4, n * s + 4), _p(const Color(0xFF6B5E4E)));
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          final ux = (2 * x - (n - 1)).abs(), vy = (2 * y - (n - 1)).abs();
          final ring = (n - 1 - (ux > vy ? ux : vy)) ~/ 2;
          final p = ux ~/ 2, q = vy ~/ 2;
          final idx = ring == 0 ? ((ux > vy ? q : p) % 2) : ((p + q + v) % 3 + 2);
          final broken = x + y < 4 && !(x == 0 && y == 3) && !(x == 3 && y == 0);
          final r = Rect.fromLTWH(ox + x * s + 0.6, oy + y * s + 0.6, s - 1.2, s - 1.2);
          if (broken) {
            c.drawRect(r, _p(const Color(0xFFCFC6B8)));
          } else {
            c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.2)), _p(cols[idx % cols.length]));
          }
        }
      }
      c.drawLine(const Offset(ox + 2, oy + 9), const Offset(ox + 12, oy + 16), _stroke(const Color(0x88574B3E), 0.8));
      for (var k = 0; k < 3; k++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(70 + k * 8.0, 84 - k * 3.0, 6, 6), const Radius.circular(1.2)), _p(cols[(k + 1 + v) % cols.length]));
      }
    default:
      return false;
  }
  return true;
}
