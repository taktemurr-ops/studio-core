part of 'covers.dart';

/// Boşta ve Simülasyon oyunlarının kapak resimleri (100×100 tuval).
bool _paintSimulasyonCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  RRect box(Offset o, double w, double h, [double r = 4]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));

  switch (cover.kind) {
    case 'simlantern':
      _bg(c, seed, tint: const Color(0xFF1D2540));
      final rope = Path()
        ..moveTo(6, 26)
        ..quadraticBezierTo(50, 50, 94, 26);
      c.drawPath(rope, _stroke(const Color(0xFF8A7A6A), 1.5));
      for (var k = 0; k < 5; k++) {
        final u = (k + 0.5) / 5;
        final o = Offset(6 + u * 88, 26 + 4 * u * (1 - u) * 24 + 10);
        c.drawCircle(o, 11, _p(const Color(0xFFFFD27D).withValues(alpha: 0.25)));
        c.drawRRect(box(o, 12, 16, 6), _p([const Color(0xFFE4572E), const Color(0xFFF2A516), const Color(0xFFE88DB0)][(k + v) % 3]));
      }
      for (var k = 0; k < 4; k++) {
        c.drawRect(Rect.fromLTWH(4 + k * 24.0, 70.0 - (k % 2) * 8, 20, 30), _p(const Color(0xFF2B2F4A)));
        c.drawRect(Rect.fromLTWH(11 + k * 24.0, 78.0 - (k % 2) * 8, 6, 7), _p(const Color(0xFFFFD27D)));
      }
    case 'simpots':
      _bg(c, seed, tint: const Color(0xFF8C5A3C));
      for (var k = 0; k < 3; k++) {
        final s = 0.7 + k * 0.2;
        final m = Offset(22 + k * 28.0, 62 - k * 4.0);
        final pot = Path()
          ..moveTo(m.dx - 6 * s, m.dy - 18 * s)
          ..lineTo(m.dx + 6 * s, m.dy - 18 * s)
          ..quadraticBezierTo(m.dx + 16 * s, m.dy, m.dx + 9 * s, m.dy + 12 * s)
          ..lineTo(m.dx - 9 * s, m.dy + 12 * s)
          ..quadraticBezierTo(m.dx - 16 * s, m.dy, m.dx - 6 * s, m.dy - 18 * s)
          ..close();
        c.drawPath(pot, _p([const Color(0xFFD08C5B), const Color(0xFF3E7CB1), const Color(0xFFE9B949)][(k + v) % 3]));
        c.drawLine(Offset(m.dx - 10 * s, m.dy), Offset(m.dx + 10 * s, m.dy), _stroke(const Color(0x66FFFFFF), 2));
      }
      _text(c, '+', const Offset(36, 30), 18, Colors.white);
      _text(c, '=', const Offset(64, 30), 18, Colors.white);
    case 'simpet':
      _bg(c, seed, tint: const Color(0xFF8EC5E8));
      for (final o in const [Offset(36, 54), Offset(50, 46), Offset(64, 54), Offset(50, 60)]) {
        c.drawCircle(o, 16, _p(Colors.white));
      }
      c.drawCircle(const Offset(44, 52), 2.6, _p(const Color(0xFF2B2B3A)));
      c.drawCircle(const Offset(56, 52), 2.6, _p(const Color(0xFF2B2B3A)));
      c.drawArc(Rect.fromCenter(center: const Offset(50, 57), width: 8, height: 6), 0, math.pi, false,
          _stroke(const Color(0xFF2B2B3A), 1.6));
      c.drawCircle(const Offset(40, 58), 3, _p(const Color(0x66F28CA0)));
      c.drawCircle(const Offset(60, 58), 3, _p(const Color(0x66F28CA0)));
      _text(c, '★', Offset(78, 20 + v * 4.0), 14, const Color(0xFFFFD166));
    case 'simmine':
      _bg(c, seed, tint: const Color(0xFF4A3B33));
      c.drawRect(const Rect.fromLTWH(44, 10, 12, 80), _p(const Color(0xFF6B5A4A)));
      c.drawRect(Rect.fromLTWH(45, 24.0 + v * 12, 10, 12), _p(const Color(0xFFE9B949)));
      for (var k = 0; k < 3; k++) {
        final y = 30.0 + k * 22;
        c.drawRect(Rect.fromLTWH(10, y, 32, 12), _p(const Color(0xFF2E241E)));
        c.drawRect(Rect.fromLTWH(58, y + 6, 32, 12), _p(const Color(0xFF2E241E)));
        final gem = Path()
          ..moveTo(26, y + 1)
          ..lineTo(31, y + 6)
          ..lineTo(26, y + 11)
          ..lineTo(21, y + 6)
          ..close();
        c.drawPath(gem, _p([const Color(0xFF7FD1E8), const Color(0xFFB38CD9), const Color(0xFF8FE0A8)][k]));
      }
    case 'simfactory':
      _bg(c, seed, tint: const Color(0xFF5B7DA8));
      c.drawRect(const Rect.fromLTWH(8, 66, 84, 8), _p(const Color(0xFF3B3F4A)));
      for (var k = 0; k < 6; k++) {
        c.drawCircle(Offset(12 + k * 15.0, 74), 4, _p(const Color(0xFF6B7180)));
      }
      for (var k = 0; k < 3; k++) {
        c.drawRRect(box(Offset(24 + k * 26.0, 56), 16, 16, 3),
            _p([const Color(0xFFE4572E), const Color(0xFFE9B949), const Color(0xFF4F9A6E)][(k + v) % 3]));
      }
      c.drawRect(const Rect.fromLTWH(66, 16, 10, 30), _p(const Color(0xFF3B3F4A)));
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(74 + k * 5.0, 12 - k * 2.0), 5.0 + k, _p(const Color(0x88FFFFFF)));
      }
    case 'simdiner':
      _bg(c, seed, tint: const Color(0xFFB5433A));
      c.drawRect(const Rect.fromLTWH(0, 70, 100, 30), _p(const Color(0xFF7A4E33)));
      c.drawOval(Rect.fromCenter(center: const Offset(50, 56), width: 56, height: 14), _p(const Color(0xFFF4F1EA)));
      c.drawArc(Rect.fromCenter(center: const Offset(50, 56), width: 48, height: 44), math.pi, math.pi, true,
          _p(const Color(0xFFC9CED6)));
      c.drawCircle(const Offset(50, 32), 3.5, _p(const Color(0xFF8A9099)));
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(24 + k * 26.0, 86), 6, _p(const Color(0xFFE9B949).withValues(alpha: k <= v ? 1.0 : 0.4)));
      }
    case 'simfarm':
      _bg(c, seed, tint: const Color(0xFF8DBF6A));
      c.drawCircle(const Offset(80, 18), 9, _p(const Color(0xFFFFD166)));
      for (var r = 0; r < 3; r++) {
        final y = 46.0 + r * 16;
        c.drawRRect(box(Offset(50, y), 84, 12, 4), _p(const Color(0xFF7A5230)));
        for (var k = 0; k < 6; k++) {
          final x = 14 + k * 14.0;
          c.drawLine(Offset(x, y + 2), Offset(x, y - 8), _stroke(const Color(0xFF3F7A3F), 2));
          c.drawCircle(Offset(x, y - 9), 3, _p([const Color(0xFFE3C567), const Color(0xFFD64933), const Color(0xFFE88D2A)][(r + v) % 3]));
        }
      }
    case 'simaqua':
      _bg(c, seed, tint: const Color(0xFF2E7FA8));
      c.drawRect(const Rect.fromLTWH(0, 82, 100, 18), _p(const Color(0xFFE6D3A3)));
      for (var k = 0; k < 4; k++) {
        final x = 14 + k * 24.0;
        final p = Path()
          ..moveTo(x, 86)
          ..quadraticBezierTo(x + 6, 70, x + 2, 54 + k * 3.0);
        c.drawPath(p, _stroke(const Color(0xFF3F8F5A), 3));
      }
      for (var k = 0; k < 3; k++) {
        final o = Offset(30 + k * 22.0, 34.0 + (k * 13 + v * 5) % 26);
        c.drawOval(Rect.fromCenter(center: o, width: 18, height: 10), _p([const Color(0xFFF2A516), const Color(0xFFE4572E), const Color(0xFF7FD1E8)][k]));
        c.drawPath(
            Path()
              ..moveTo(o.dx - 8, o.dy)
              ..lineTo(o.dx - 14, o.dy - 5)
              ..lineTo(o.dx - 14, o.dy + 5)
              ..close(),
            _p([const Color(0xFFF2A516), const Color(0xFFE4572E), const Color(0xFF7FD1E8)][k]));
      }
    case 'simzen':
      _bg(c, seed, tint: const Color(0xFFD8CBB0));
      for (var k = 0; k < 6; k++) {
        c.drawArc(Rect.fromCenter(center: const Offset(36, 62), width: 20.0 + k * 10, height: 14.0 + k * 7), 0, math.pi * 2, false,
            _stroke(const Color(0x669C8B6E), 1.4));
      }
      c.drawOval(Rect.fromCenter(center: const Offset(36, 62), width: 16, height: 10), _p(const Color(0xFF7B7468)));
      c.drawRRect(box(const Offset(72, 74), 22, 10, 3), _p(const Color(0xFF8C5A3C)));
      c.drawLine(const Offset(72, 70), const Offset(70, 46), _stroke(const Color(0xFF6B4A2B), 3));
      for (final o in const [Offset(62, 44), Offset(72, 38), Offset(80, 46)]) {
        c.drawCircle(o, 8.0 + v, _p(const Color(0xFF4F8F4A)));
      }
    case 'simants':
      _bg(c, seed, tint: const Color(0xFF8C6A4A));
      c.drawRect(const Rect.fromLTWH(0, 0, 100, 22), _p(const Color(0xFF8DBF6A)));
      final tunnel = Path()
        ..moveTo(50, 22)
        ..lineTo(50, 40)
        ..lineTo(26, 54)
        ..moveTo(50, 40)
        ..lineTo(74, 60)
        ..lineTo(60, 80);
      c.drawPath(tunnel, _stroke(const Color(0xFF5A3F2A), 7));
      for (final o in const [Offset(26, 56), Offset(74, 62), Offset(58, 82)]) {
        c.drawOval(Rect.fromCenter(center: o, width: 20, height: 12), _p(const Color(0xFF5A3F2A)));
      }
      for (var k = 0; k < 3 + v; k++) {
        final o = Offset(20 + k * 17.0, 13);
        c.drawCircle(o, 2.2, _p(const Color(0xFF2B1D14)));
        c.drawCircle(o + const Offset(4, 0), 2.8, _p(const Color(0xFF2B1D14)));
      }
    case 'simtown':
      _bg(c, seed, tint: const Color(0xFF7FB3D5));
      c.drawRect(const Rect.fromLTWH(0, 72, 100, 28), _p(const Color(0xFF8DBF6A)));
      const roofs = [Color(0xFFB5433A), Color(0xFF3E7CB1), Color(0xFFE9B949), Color(0xFF7A4E7E)];
      for (var k = 0; k < 4; k++) {
        final x = 8 + k * 22.0;
        final h = 22.0 + (k * 7 + v * 3) % 14;
        c.drawRect(Rect.fromLTWH(x, 72 - h, 18, h), _p(const Color(0xFFF4EBDC)));
        c.drawPath(
            Path()
              ..moveTo(x - 2, 72 - h)
              ..lineTo(x + 9, 60 - h)
              ..lineTo(x + 20, 72 - h)
              ..close(),
            _p(roofs[k]));
        c.drawRect(Rect.fromLTWH(x + 6, 64, 6, 8), _p(const Color(0xFF6B4A2B)));
      }
    case 'simstyle':
      _bg(c, seed, tint: const Color(0xFFE88DB0));
      c.drawLine(const Offset(50, 14), const Offset(50, 22), _stroke(const Color(0xFF6B6B6B), 2));
      final hanger = Path()
        ..moveTo(28, 34)
        ..lineTo(50, 22)
        ..lineTo(72, 34);
      c.drawPath(hanger, _stroke(const Color(0xFF6B6B6B), 2));
      final dress = Path()
        ..moveTo(40, 32)
        ..lineTo(60, 32)
        ..lineTo(64, 50)
        ..lineTo(76, 86)
        ..lineTo(24, 86)
        ..lineTo(36, 50)
        ..close();
      c.drawPath(dress, _p([const Color(0xFF3E7CB1), const Color(0xFFF4F1EA), const Color(0xFF4F9A6E)][v % 3]));
      for (var k = 0; k < 5; k++) {
        c.drawCircle(Offset(34 + k * 8.0, 70.0 + (k % 2) * 6), 2.4, _p(const Color(0xFFE9B949)));
      }
    case 'simcook':
      _bg(c, seed, tint: const Color(0xFFE9B949));
      c.drawRRect(box(const Offset(50, 64), 60, 26, 8), _p(const Color(0xFF3B3F4A)));
      c.drawLine(const Offset(80, 62), const Offset(94, 56), _stroke(const Color(0xFF3B3F4A), 5));
      c.drawOval(Rect.fromCenter(center: const Offset(50, 52), width: 58, height: 12), _p(const Color(0xFF6B7180)));
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(38 + k * 12.0, 52), 4.5, _p([const Color(0xFFD64933), const Color(0xFF4F9A6E), const Color(0xFFF2C14E)][(k + v) % 3]));
      }
      for (var k = 0; k < 3; k++) {
        final p = Path()..moveTo(38 + k * 12.0, 42);
        p.quadraticBezierTo(34 + k * 12.0, 34, 40 + k * 12.0, 26);
        c.drawPath(p, _stroke(const Color(0x99FFFFFF), 2));
      }
    case 'simbee':
      _bg(c, seed, tint: const Color(0xFFF2C14E));
      for (var row = 0; row < 3; row++) {
        final w = 44.0 - row * 9;
        c.drawRRect(box(Offset(42, 74 - row * 14.0), w, 14, 7), _p(const Color(0xFFD99A1E)));
        c.drawRRect(box(Offset(42, 74 - row * 14.0), w, 14, 7), _stroke(const Color(0xFF8A5A14), 1.4));
      }
      c.drawCircle(const Offset(42, 78), 3.5, _p(const Color(0xFF4A2E0A)));
      for (var k = 0; k < 2 + v; k++) {
        final o = Offset(70 + k * 9.0, 24 + k * 14.0);
        c.drawOval(Rect.fromCenter(center: o, width: 12, height: 8), _p(const Color(0xFFF2C14E)));
        c.drawLine(o + const Offset(-1, -4), o + const Offset(-1, 4), _stroke(const Color(0xFF2B2B2B), 1.6));
        c.drawOval(Rect.fromCenter(center: o + const Offset(1, -5), width: 8, height: 6), _p(const Color(0xCCFFFFFF)));
      }
    case 'simtea':
      _bg(c, seed, tint: const Color(0xFF4F7F52));
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(20 + k * 30.0, 18), 16, _p(const Color(0xFF3F6F42)));
      }
      c.drawOval(Rect.fromCenter(center: const Offset(50, 76), width: 72, height: 14), _p(const Color(0xFF9C6B3E)));
      for (var g = 0; g < 2; g++) {
        final x = 38 + g * 24.0;
        final glass = Path()
          ..moveTo(x - 7, 46)
          ..quadraticBezierTo(x, 60, x - 5, 72)
          ..lineTo(x + 5, 72)
          ..quadraticBezierTo(x, 60, x + 7, 46)
          ..close();
        c.drawPath(glass, _p(const Color(0xDDB2361F)));
        c.drawPath(glass, _stroke(const Color(0x88FFFFFF), 1));
        final steam = Path()..moveTo(x, 42);
        steam.quadraticBezierTo(x - 4, 36, x + v * 1.0, 28);
        c.drawPath(steam, _stroke(const Color(0x99FFFFFF), 1.6));
      }
    case 'simtulip':
      _bg(c, seed, tint: const Color(0xFF6FA84F));
      final house = Path()
        ..moveTo(8, 40)
        ..lineTo(50, 14)
        ..lineTo(92, 40)
        ..lineTo(92, 92)
        ..lineTo(8, 92)
        ..close();
      c.drawPath(house, _p(const Color(0x55E1F4F0)));
      c.drawPath(house, _stroke(const Color(0xFF6B4F3A), 2));
      for (var k = 1; k < 4; k++) {
        c.drawLine(Offset(8 + k * 21.0, 92), Offset(8 + k * 21.0, 40 - (k == 2 ? 26 : 10)), _stroke(const Color(0x886B4F3A), 1));
      }
      const cols = [Color(0xFFD7263D), Color(0xFFF4C430), Color(0xFF7B4FB8), Color(0xFFF7F4EA)];
      for (var k = 0; k < 5; k++) {
        final x = 18 + k * 16.0;
        c.drawLine(Offset(x, 86), Offset(x, 62), _stroke(const Color(0xFF3E8E41), 2));
        final cup = Path()
          ..moveTo(x - 6, 52)
          ..quadraticBezierTo(x - 6, 64, x, 64)
          ..quadraticBezierTo(x + 6, 64, x + 6, 52)
          ..lineTo(x + 3, 56)
          ..lineTo(x, 50)
          ..lineTo(x - 3, 56)
          ..close();
        c.drawPath(cup, _p(cols[(k + v) % 4]));
        if ((k + v) % 2 == 0) c.drawLine(Offset(x, 62), Offset(x + 1, 54), _stroke(const Color(0xFF7B1E2B), 1.2));
      }
    case 'simcaravan':
      _bg(c, seed, tint: const Color(0xFFD9A066));
      c.drawRect(const Rect.fromLTWH(10, 34, 62, 40), _p(const Color(0xFFD9B98C)));
      c.drawArc(const Rect.fromLTWH(30, 22, 22, 22), 3.14159, 3.14159, true, _p(const Color(0xFF3E7C8C)));
      final gate = Path()
        ..moveTo(34, 74)
        ..lineTo(34, 56)
        ..arcToPoint(const Offset(48, 56), radius: const Radius.circular(7))
        ..lineTo(48, 74)
        ..close();
      c.drawPath(gate, _p(const Color(0xFF5B3A22)));
      for (var k = 0; k < 3; k++) {
        c.drawRRect(box(Offset(18 + k * 46.0 / 2 + (k > 0 ? 18 : 0), 46), 6, 9, 3), _p(const Color(0xFFFFD27A)));
      }
      c.drawLine(const Offset(0, 86), const Offset(100, 86), _stroke(const Color(0x88B07D48), 3));
      for (var k = 0; k < 1 + v % 2 + 1; k++) {
        final o = Offset(74 + k * 12.0, 78);
        c.drawOval(Rect.fromCenter(center: o, width: 14, height: 7), _p(const Color(0xFFB07D48)));
        c.drawCircle(o + const Offset(-2, -4), 3, _p(const Color(0xFFB07D48)));
        c.drawLine(o + const Offset(6, -1), o + const Offset(9, -8), _stroke(const Color(0xFFB07D48), 2));
        c.drawLine(o + const Offset(-4, 3), o + const Offset(-4, 9), _stroke(const Color(0xFFB07D48), 1.4));
        c.drawLine(o + const Offset(4, 3), o + const Offset(4, 9), _stroke(const Color(0xFFB07D48), 1.4));
      }
    case 'simspace': // Boşta Uzay: gezegen ufku, güneş panelli istasyon, yükselen roket
      _bg(c, seed, tint: const Color(0xFF111833));
      for (var k = 0; k < 12; k++) {
        c.drawCircle(Offset(((k * 41 + v * 7) % 94) + 3.0, ((k * 29) % 56) + 3.0), k % 3 == 0 ? 1.3 : 0.8, _p(Colors.white70));
      }
      c.drawCircle(const Offset(50, 150), 70, _p(const Color(0xFF3E6FB0)));
      c.drawCircle(const Offset(50, 150), 70, _stroke(const Color(0x668FC1F0), 3));
      // İstasyon
      c.drawRRect(box(const Offset(32, 34), 18, 9, 3), _p(const Color(0xFFD9DEE8)));
      c.drawCircle(const Offset(32, 34), 4, _p(const Color(0xFFF2A516)));
      for (final dx in const [-20.0, 20.0]) {
        c.drawRect(Rect.fromCenter(center: Offset(32 + dx, 34), width: 14, height: 8), _p(const Color(0xFF2E5FA8)));
        c.drawLine(Offset(32 + dx * 0.45, 34), Offset(32 + dx * 0.55, 34), _stroke(const Color(0xFFD9DEE8), 1.4));
        for (var i = 1; i < 3; i++) {
          final x = 32 + dx - 7 + i * 4.7;
          c.drawLine(Offset(x, 30), Offset(x, 38), _stroke(const Color(0x88FFFFFF), 0.6));
        }
      }
      // Roket
      c.save();
      c.translate(70, 54 - (v % 3) * 4.0);
      c.rotate(0.35);
      final body = Path()
        ..moveTo(0, -16)
        ..quadraticBezierTo(7, -6, 6, 10)
        ..lineTo(-6, 10)
        ..quadraticBezierTo(-7, -6, 0, -16)
        ..close();
      c.drawPath(Path()..addPolygon(const [Offset(-4, 10), Offset(0, 22), Offset(4, 10)], true), _p(const Color(0xFFF2A516)));
      c.drawPath(Path()..addPolygon(const [Offset(-6, 4), Offset(-11, 12), Offset(-6, 10)], true), _p(const Color(0xFFE4572E)));
      c.drawPath(Path()..addPolygon(const [Offset(6, 4), Offset(11, 12), Offset(6, 10)], true), _p(const Color(0xFFE4572E)));
      c.drawPath(body, _p(const Color(0xFFF1F3F8)));
      c.drawCircle(const Offset(0, -3), 3, _p(const Color(0xFF4FA3D9)));
      c.restore();
      // Biriken kaynak (yıldız parçaları)
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(16 + k * 9.0, 66), 3, _p(const Color(0xFFFFD27D)));
      }
    case 'simzoo': // Hayvanat Bahçesi: giriş kemeri, çit, zürafa, fil ve ağaç
      _bg(c, seed, tint: const Color(0xFF8CC0DE));
      c.drawRect(const Rect.fromLTWH(0, 70, 100, 30), _p(const Color(0xFF7DB356)));
      // Ağaç
      c.drawRect(const Rect.fromLTWH(84, 50, 5, 22), _p(const Color(0xFF8A5A36)));
      c.drawCircle(const Offset(86, 46), 11, _p(const Color(0xFF4E8A3A)));
      // Zürafa
      const gir = Color(0xFFF2B84B);
      const spot = Color(0xFFB0763A);
      c.drawOval(Rect.fromCenter(center: const Offset(30, 62), width: 26, height: 14), _p(gir));
      c.drawPath(Path()..addPolygon(const [Offset(36, 58), Offset(42, 22), Offset(48, 22), Offset(42, 60)], true), _p(gir));
      c.drawOval(Rect.fromCenter(center: const Offset(48, 21), width: 14, height: 8), _p(gir));
      c.drawLine(const Offset(44, 17), const Offset(43, 12), _stroke(spot, 1.6));
      c.drawCircle(const Offset(49, 19), 1.2, _p(const Color(0xFF3D2B1F)));
      for (final x in const [22.0, 28.0, 34.0, 38.0]) {
        c.drawLine(Offset(x, 66), Offset(x, 80), _stroke(gir, 3));
      }
      for (final (x, y) in const [(26.0, 60.0), (33.0, 63.0), (41.0, 44.0), (43.0, 32.0), (22.0, 64.0)]) {
        c.drawCircle(Offset(x, y), 2, _p(spot));
      }
      // Fil
      const ele = Color(0xFF9AA3AE);
      c.drawOval(Rect.fromCenter(center: const Offset(66, 66), width: 28, height: 20), _p(ele));
      c.drawCircle(const Offset(78, 58), 9, _p(ele));
      c.drawOval(Rect.fromCenter(center: const Offset(74, 58), width: 9, height: 12), _p(const Color(0xFF838C97)));
      c.drawPath(
          Path()
            ..moveTo(84, 60)
            ..quadraticBezierTo(90, 70, 86, 78),
          _stroke(ele, 4));
      c.drawCircle(const Offset(80, 55), 1.3, _p(const Color(0xFF2B2F3A)));
      for (final x in const [58.0, 64.0, 70.0, 75.0]) {
        c.drawLine(Offset(x, 72), Offset(x, 82), _stroke(ele, 4));
      }
      // Çit
      for (var k = 0; k < 11; k++) {
        c.drawRect(Rect.fromLTWH(k * 9.5, 80, 3, 14), _p(const Color(0xFFB07D48)));
      }
      c.drawLine(const Offset(0, 84), const Offset(100, 84), _stroke(const Color(0xFFB07D48), 2));
      // Giriş kemeri
      c.drawArc(const Rect.fromLTWH(8, 4, 40, 14), math.pi, math.pi, false, _stroke(const Color(0xFF8A5A36), 3));
      c.drawRRect(box(const Offset(28, 12), 22, 6, 2), _p(const Color(0xFFFFF3D6)));
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(22 + k * 6.0, 12), 1.2, _p([const Color(0xFFE4572E), const Color(0xFF4E8A3A), const Color(0xFF2E5FA8)][(k + v) % 3]));
      }
    default:
      return false;
  }
  return true;
}
