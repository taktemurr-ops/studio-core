part of 'covers.dart';

/// Özgün oyunların kapak resimleri.
bool _paintOzgunCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const warm = [Color(0xFFB23A48), Color(0xFF2E5E8C), Color(0xFFD9A441), Color(0xFF4F7F52), Color(0xFF7A4E7E), Color(0xFFE07A5F)];
  const paper = Color(0xFFF7F1E6);
  RRect box(Offset o, double w, double h, [double r = 4]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));
  Path hex(Offset m, double s) {
    final p = Path();
    for (var k = 0; k < 6; k++) {
      final a = math.pi / 180 * (60 * k - 30);
      final q = m + Offset(math.cos(a) * s, math.sin(a) * s);
      if (k == 0) {
        p.moveTo(q.dx, q.dy);
      } else {
        p.lineTo(q.dx, q.dy);
      }
    }
    return p..close();
  }

  switch (cover.kind) {
    case 'kilimc':
      _bg(c, seed, tint: const Color(0xFF6B2E2E));
      for (var y = 0; y < 6; y++) {
        for (var x = 0; x < 6; x++) {
          final d = (x - 2.5).abs() + (y - 2.5).abs();
          if ((d.round() + v) % 3 == 0) continue;
          c.drawRect(Rect.fromLTWH(20 + x * 10.0, 20 + y * 10.0, 9, 9), _p(warm[(d ~/ 1.5) % 4]));
        }
      }
    case 'cinic':
      _bg(c, seed, tint: const Color(0xFF16365F));
      const iz = [Color(0xFFF7F3EA), Color(0xFF1F4E9A), Color(0xFF2A9D9A), Color(0xFFC8453B)];
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          final o = Offset(22 + x * 19.0, 22 + y * 19.0);
          final m = o + const Offset(9, 9);
          final corners = [o, o + const Offset(18, 0), o + const Offset(18, 18), o + const Offset(0, 18)];
          for (var d = 0; d < 4; d++) {
            final t = Path()
              ..moveTo(corners[d].dx, corners[d].dy)
              ..lineTo(corners[(d + 1) % 4].dx, corners[(d + 1) % 4].dy)
              ..lineTo(m.dx, m.dy)
              ..close();
            c.drawPath(t, _p(iz[(x + y + d + v) % 4]));
          }
        }
      }
    case 'ebruc':
      _bg(c, seed, tint: const Color(0xFFEDE3CF));
      for (var k = 0; k < 5; k++) {
        final p = Path()..moveTo(10, 25.0 + k * 13);
        p.cubicTo(35, 10.0 + k * 13 + v * 3, 60, 40.0 + k * 13, 90, 22.0 + k * 13);
        c.drawPath(p, _stroke(warm[(k + v) % warm.length], 6));
      }
    case 'tulipc':
      _bg(c, seed, tint: const Color(0xFF4F7F52));
      for (var k = 0; k < 5; k++) {
        final m = Offset(18 + k * 16.0, 48 + (k.isEven ? 0 : 14) - v * 2.0);
        c.drawLine(m, m + const Offset(0, 26), _stroke(const Color(0xFF2F5D34), 3));
        final cup = Path()
          ..moveTo(m.dx - 7, m.dy - 9)
          ..lineTo(m.dx - 3, m.dy - 4)
          ..lineTo(m.dx, m.dy - 10)
          ..lineTo(m.dx + 3, m.dy - 4)
          ..lineTo(m.dx + 7, m.dy - 9)
          ..quadraticBezierTo(m.dx + 8, m.dy + 3, m.dx, m.dy + 3)
          ..quadraticBezierTo(m.dx - 8, m.dy + 3, m.dx - 7, m.dy - 9)
          ..close();
        c.drawPath(cup, _p([const Color(0xFFC8453B), const Color(0xFFE9B949), const Color(0xFFB23A48)][k % 3]));
      }
    case 'caravanc':
      _bg(c, seed, tint: const Color(0xFFC9A66B));
      for (var k = 0; k < 4; k++) {
        c.drawPath(hex(Offset(22 + k * 18.0, 50 + (k.isEven ? -8 : 8)), 10), _p(const Color(0xFFEBD3A4)));
      }
      c.drawLine(const Offset(22, 42), const Offset(76, 58), _stroke(const Color(0xFF5B3A0A), 3));
      c.drawCircle(const Offset(76, 58), 6, _p(const Color(0xFF7A4E7E)));
      c.drawCircle(const Offset(22, 42), 6, _p(const Color(0xFF3E6FB0)));
    case 'callic':
      _bg(c, seed, tint: const Color(0xFFF6EEDC));
      final p = Path()..moveTo(18, 70);
      p.cubicTo(30, 20, 50, 85, 60, 40);
      p.cubicTo(66, 18, 84, 30, 82, 60);
      c.drawPath(p, _stroke(const Color(0xFF1E2A44), 6));
      c.drawPath(p, _stroke(const Color(0xFFD9A441), 2));
      for (final o in const [Offset(18, 70), Offset(60, 40), Offset(82, 60)]) {
        c.drawCircle(o, 4, _p(const Color(0xFF1E2A44)));
      }
    case 'shadowc':
      _bg(c, seed, tint: const Color(0xFFF4DFB0));
      c.drawRRect(box(const Offset(50, 46), 70, 56, 6), _p(const Color(0xFFF7E6C0)));
      for (var k = 0; k < 2; k++) {
        final o = Offset(34 + k * 30.0, 46);
        c.drawCircle(o + const Offset(0, -12), 7, _p(const Color(0xDD2B1D14)));
        c.drawRRect(box(o + const Offset(0, 6), 16, 22, 4), _p(const Color(0xDD2B1D14)));
      }
      c.drawRect(const Rect.fromLTWH(15, 78, 70, 8), _p(const Color(0xFF8B5A2B)));
    case 'nbhdc':
      _bg(c, seed, tint: const Color(0xFFDCE8C8));
      const cols = [Color(0xFFC8553D), Color(0xFF4F9A6E), Color(0xFF3E6FB0), Color(0xFF7D6E62)];
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          c.drawRRect(box(Offset(30 + x * 20.0, 30 + y * 20.0), 17, 17, 3), _p(cols[(x * 2 + y + v) % 4]));
        }
      }
    case 'gearc':
      _bg(c, seed, tint: const Color(0xFF3B2F25));
      void gear(Offset m, double r, Color col) {
        for (var k = 0; k < 8; k++) {
          final a = k * math.pi / 4;
          c.drawCircle(m + Offset(math.cos(a) * r, math.sin(a) * r), r * 0.22, _p(col));
        }
        c.drawCircle(m, r * 0.9, _p(col));
        c.drawCircle(m, r * 0.3, _p(const Color(0xFF3B2F25)));
      }
      gear(const Offset(36, 40), 16, const Color(0xFFD9A441));
      gear(const Offset(64, 62), 13, const Color(0xFFB8860B));
    case 'lightc':
      _bg(c, seed, tint: const Color(0xFF1B2333));
      final p = Path()
        ..moveTo(12, 30)
        ..lineTo(50, 30)
        ..lineTo(50, 72)
        ..lineTo(88, 72);
      c.drawPath(p, _stroke(const Color(0x66FFD166), 8));
      c.drawPath(p, _stroke(const Color(0xFFFFF3C4), 2.5));
      c.drawLine(const Offset(44, 24), const Offset(56, 36), _stroke(const Color(0xFFB8C4D9), 3));
      c.drawLine(const Offset(44, 78), const Offset(56, 66), _stroke(const Color(0xFFB8C4D9), 3));
      c.drawCircle(const Offset(88, 72), 6, _p(const Color(0xFF34C6B8)));
    case 'rotworldc':
      _bg(c, seed);
      c.save();
      c.translate(50, 50);
      c.rotate(0.3 + v * 0.2);
      c.drawRRect(box(Offset.zero, 54, 54, 6), _p(const Color(0xFFF1E6D2)));
      c.drawRect(const Rect.fromLTWH(-27, 5, 30, 8), _p(const Color(0xFF8B6B4A)));
      c.drawCircle(const Offset(14, -12), 6, _p(const Color(0xFF2B2B2B)));
      c.drawCircle(const Offset(-10, -2), 6, _p(const Color(0xFFC8453B)));
      c.restore();
    case 'paintc':
      _bg(c, seed, tint: const Color(0xFFF7F3EA));
      c.drawCircle(const Offset(38, 50), 22, _p(const Color(0xFFC8453B).withValues(alpha: 0.8)));
      c.drawCircle(const Offset(62, 50), 22, _p(const Color(0xFF3D85C6).withValues(alpha: 0.8)));
      c.drawCircle(const Offset(50, 32), 22, _p(const Color(0xFFF4C430).withValues(alpha: 0.7)));
    case 'dominoc':
      _bg(c, seed, tint: const Color(0xFF3F6E5A));
      for (var k = 0; k < 6; k++) {
        c.save();
        c.translate(18 + k * 12.0, 56);
        c.rotate(k < 3 ? 0.9 : 0);
        c.drawRRect(box(Offset.zero, 6, 22, 1.5), _p(paper));
        c.restore();
      }
      c.drawCircle(const Offset(88, 50), 6, _p(const Color(0xFFE9C46A)));
    case 'honeyc':
      _bg(c, seed, tint: const Color(0xFFB7862B));
      var n = 1;
      for (var r = -1; r <= 1; r++) {
        for (var q = -1; q <= 1; q++) {
          if ((q + r).abs() > 1) continue;
          final m = Offset(50 + 17 * (q + r / 2), 50 + 15.0 * r);
          c.drawPath(hex(m, 9.5), _p(n % 3 == 0 ? const Color(0xFFE9B949) : const Color(0xFFFFF4D6)));
          _text(c, '${n++}', m, 8, _ink);
        }
      }
    case 'foldc':
      _bg(c, seed);
      c.drawRect(const Rect.fromLTWH(26, 26, 24, 48), _p(const Color(0xFFE07A5F)));
      final flap = Path()
        ..moveTo(50, 26)
        ..lineTo(74, 34)
        ..lineTo(74, 66)
        ..lineTo(50, 74)
        ..close();
      c.drawPath(flap, _p(const Color(0xFFF2E8D5)));
      c.drawLine(const Offset(50, 22), const Offset(50, 78), _stroke(Colors.white70, 1.5));
    case 'aquac':
      _bg(c, seed, tint: const Color(0xFF3A8D8C));
      c.drawRRect(box(const Offset(50, 52), 72, 50, 6), _p(const Color(0xFF7EC8E3)));
      for (var k = 0; k < 3; k++) {
        final m = Offset(32 + k * 18.0, 46 + (k.isEven ? 0 : 8));
        c.drawOval(Rect.fromCenter(center: m, width: 12, height: 7), _p(const Color(0xFFF2B33D)));
      }
      c.drawLine(const Offset(24, 76), const Offset(26, 58), _stroke(const Color(0xFF3F8F4F), 2.5));
      c.drawLine(const Offset(76, 76), const Offset(72, 60), _stroke(const Color(0xFF3F8F4F), 2.5));
    case 'stallc':
      _bg(c, seed, tint: const Color(0xFFC89F6C));
      const prod = [Color(0xFFD7263D), Color(0xFFF4C430), Color(0xFF5C3C92)];
      for (var r = 0; r < 3; r++) {
        c.drawRect(Rect.fromLTWH(14, 28 + r * 20.0, 72, 3), _p(const Color(0xFF8B5A2B)));
        for (var k = 0; k < 4; k++) {
          c.drawCircle(Offset(24 + k * 17.0, 21 + r * 20.0), 6, _p(prod[(r + v) % 3]));
        }
      }
    case 'starsc':
      _bg(c, seed, tint: const Color(0xFF0E1430));
      const pts = [Offset(22, 30), Offset(40, 40), Offset(55, 34), Offset(70, 46), Offset(78, 70), Offset(58, 66)];
      for (var k = 0; k < pts.length - 1; k++) {
        c.drawLine(pts[k], pts[k + 1], _stroke(const Color(0xFF9FB4FF), 1.5));
      }
      for (final p in pts) {
        c.drawCircle(p, 3, _p(const Color(0xFFFFF7E0)));
      }
    case 'trainc':
      _bg(c, seed);
      c.drawLine(const Offset(10, 50), const Offset(40, 50), _stroke(const Color(0xFF6B5B4B), 3));
      c.drawLine(const Offset(40, 50), const Offset(80, 28), _stroke(const Color(0xFF6B5B4B), 3));
      c.drawLine(const Offset(40, 50), const Offset(80, 72), _stroke(const Color(0xFF6B5B4B), 3));
      c.drawCircle(const Offset(40, 50), 6, _p(Colors.white));
      c.drawRRect(box(const Offset(24, 50), 16, 10, 3), _p(const Color(0xFFC8453B)));
      c.drawRect(const Rect.fromLTWH(78, 22, 12, 12), _p(const Color(0xFFC8453B)));
      c.drawRect(const Rect.fromLTWH(78, 66, 12, 12), _p(const Color(0xFF2E5E8C)));
    case 'soundc':
      _bg(c, seed, tint: const Color(0xFF111827));
      for (var k = 1; k <= 3; k++) {
        c.drawArc(Rect.fromCenter(center: const Offset(40, 50), width: k * 18.0, height: k * 18.0), -0.7, 1.4, false, _stroke(const Color(0xFFFFD166), 2.5));
      }
      c.drawCircle(const Offset(40, 50), 5, _p(const Color(0xFFFFD166)));
      c.drawRect(const Rect.fromLTWH(70, 20, 4, 60), _p(const Color(0xFFF9FAFB)));
    case 'trioc':
      _bg(c, seed);
      for (var k = 0; k < 3; k++) {
        c.drawRRect(box(Offset(28 + k * 22.0, 50), 18, 26, 4), _p(warm[(k + v) % warm.length]));
      }
    case 'mushc':
      _bg(c, seed, tint: const Color(0xFF8DB86B));
      for (var k = 0; k < 2; k++) {
        final m = Offset(36 + k * 28.0, 54 - k * 8.0);
        c.drawRect(Rect.fromCenter(center: m + const Offset(0, 8), width: 7, height: 14), _p(const Color(0xFFF4EBDC)));
        c.drawArc(Rect.fromCenter(center: m, width: 26, height: 20), math.pi, math.pi, true, _p(const Color(0xFFC8453B)));
        c.drawCircle(m + const Offset(-4, -4), 2, _p(Colors.white));
      }
      _text(c, '2', const Offset(76, 74), 14, const Color(0xFF2E5E8C));
    case 'sandc':
      _bg(c, seed, tint: const Color(0xFF4B3B2F));
      final glass = Path()
        ..moveTo(32, 20)
        ..lineTo(68, 20)
        ..lineTo(54, 50)
        ..lineTo(68, 80)
        ..lineTo(32, 80)
        ..lineTo(46, 50)
        ..close();
      c.drawPath(glass, _p(const Color(0x33FFFFFF)));
      c.drawRect(const Rect.fromLTRB(36, 66, 64, 78), _p(const Color(0xFFE2B866)));
      c.drawLine(const Offset(50, 50), const Offset(50, 66), _stroke(const Color(0xFFE2B866), 2));
      c.drawPath(glass, _stroke(const Color(0xFF8B6B4A), 2));
    default:
      return false;
  }
  return true;
}
