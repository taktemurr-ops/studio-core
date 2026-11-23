part of 'covers.dart';

/// Strateji ve Roguelike oyunlarının kapak resimleri (100×100 tuval).
/// covers.dart'taki varsayılan dala eklenir:
///   if (_paintStratejiCover(c, cover, seed)) return;
bool _paintStratejiCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
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
    case 'lanternc': // zindan: sisli koridor, fener ışığı, merdiven
      _bg(c, seed, tint: const Color(0xFF1D1B22));
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          final d = (x - 2).abs() + (y - 2).abs();
          if (d > 3 || (x + y + v) % 5 == 0) continue;
          c.drawRect(Rect.fromLTWH(18 + x * 13.0, 18 + y * 13.0, 12, 12),
              _p(Color.lerp(const Color(0xFFCDBB9A), const Color(0xFF2E2924), d / 4)!));
        }
      }
      c.drawCircle(const Offset(50, 50), 24, _p(const Color(0x33F6D68A)));
      c.drawCircle(const Offset(50, 50), 5, _p(const Color(0xFFF6D68A)));
      c.drawLine(const Offset(50, 40), const Offset(50, 45), _stroke(const Color(0xFF5B4636), 2));
      for (var i = 0; i < 3; i++) {
        c.drawRect(Rect.fromLTWH(66 + i * 2.5, 70 + i * 4.0, 12 - i * 5.0, 3), _p(const Color(0xFFD9A441)));
      }
    case 'deckc': // deste: yelpaze kartlar
      _bg(c, seed, tint: const Color(0xFF6B2E2E));
      const cols = [Color(0xFFF6E3DA), Color(0xFFDCE7F2), Color(0xFFF6E3DA)];
      for (var k = 0; k < 3; k++) {
        c.save();
        c.translate(50, 70);
        c.rotate((k - 1) * 0.32);
        final r = RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -46, 28, 40), const Radius.circular(5));
        c.drawRRect(r, _p(cols[k]));
        c.drawRRect(r, _stroke(const Color(0x33000000), 1));
        c.drawCircle(const Offset(-8, -40), 4, _p(const Color(0xFFD9A441)));
        c.restore();
      }
      _text(c, '${(v % 3) + 1}', const Offset(50, 40), 14, const Color(0xFFB0563B));
    case 'hexwarc': // altıgen savaş: altıgenler, iki sancak
      _bg(c, seed, tint: const Color(0xFF2C4A6B));
      const terr = [Color(0xFFD8CFA0), Color(0xFF7FA36B), Color(0xFFBFA27A), Color(0xFF7FB2D0)];
      for (var r = -2; r <= 2; r++) {
        for (var q = -2; q <= 2; q++) {
          if ((q + r).abs() > 2) continue;
          final m = Offset(50 + 9 * math.sqrt(3) * (q + r / 2), 50 + 13.5 * r);
          c.drawPath(hex(m, 8.6), _p(terr[(q * 3 + r * 5 + v + 12) % 4]));
        }
      }
      for (final f in const [(Offset(38, 26), Color(0xFFC8553D)), (Offset(62, 74), Color(0xFF3E6FB0))]) {
        c.drawLine(f.$1 + const Offset(0, 8), f.$1 + const Offset(0, -8), _stroke(const Color(0xFF22303F), 1.6));
        c.drawPath(Path()..addPolygon([f.$1 + const Offset(0, -8), f.$1 + const Offset(10, -5), f.$1 + const Offset(0, -2)], true), _p(f.$2));
      }
    case 'squadc': // taktik: ızgara, üç kahraman, kaptan
      _bg(c, seed, tint: const Color(0xFF4A3A5C));
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          c.drawRect(Rect.fromLTWH(20 + x * 12.0, 20 + y * 12.0, 12, 12), _p((x + y) % 2 == 0 ? const Color(0xFFE4D8BE) : const Color(0xFFDACDB0)));
        }
      }
      for (final o in const [Offset(32, 68), Offset(44, 68), Offset(56, 68)]) {
        c.drawCircle(o, 5, _p(const Color(0xFF3E6FB0)));
      }
      c.drawCircle(Offset(50.0 + (v % 2) * 12, 32), 5.5, _p(const Color(0xFF6B3E8C)));
      c.drawCircle(Offset(50.0 + (v % 2) * 12, 32), 2, _p(const Color(0xFFD9A441)));
    case 'shorec': // hayatta kalma: ada, ateş, ufukta gemi
      _bg(c, seed, tint: const Color(0xFF2E8C83));
      c.drawRect(const Rect.fromLTWH(0, 62, 100, 38), _p(const Color(0xFF3E7FA8)));
      c.drawOval(const Rect.fromLTWH(18, 56, 64, 18), _p(const Color(0xFFE2C88E)));
      c.drawLine(const Offset(36, 62), const Offset(40, 34), _stroke(const Color(0xFF7A5B3A), 3));
      for (final a in const [-0.9, -0.3, 0.3]) {
        c.drawLine(const Offset(40, 34), Offset(40 + math.cos(a) * 14, 34 + math.sin(a) * 8 - 2), _stroke(const Color(0xFF4F9A6E), 3));
      }
      c.drawPath(Path()..addPolygon(const [Offset(58, 62), Offset(62, 52), Offset(66, 62)], true), _p(const Color(0xFFE07A5F)));
      c.drawPath(Path()..addPolygon([Offset(70.0 + v * 2, 46), Offset(84.0 + v * 2, 46), Offset(81.0 + v * 2, 50), Offset(73.0 + v * 2, 50)], true), _p(const Color(0xFFF4F1EA)));
    case 'hourglassc': // arena: kum saati ve iki birlik
      _bg(c, seed, tint: const Color(0xFF6B5320));
      final glass = Path()
        ..moveTo(36, 18)
        ..lineTo(64, 18)
        ..lineTo(52, 50)
        ..lineTo(64, 82)
        ..lineTo(36, 82)
        ..lineTo(48, 50)
        ..close();
      c.drawPath(glass, _p(const Color(0x33FFFFFF)));
      c.drawRect(const Rect.fromLTRB(40, 70, 60, 80), _p(const Color(0xFFE2B866)));
      c.drawPath(glass, _stroke(const Color(0xFFF4EBDD), 2));
      c.drawCircle(const Offset(22, 64), 8, _p(const Color(0xFF4F7F52)));
      c.drawCircle(const Offset(78, 36), 8, _p(const Color(0xFF8FB3C9)));
      _text(c, '★' * ((v % 3) + 1), const Offset(78, 52), 8, const Color(0xFFD9A441));
    case 'valleyc': // vadi: çayır ızgarası, evler, kuyu
      _bg(c, seed, tint: const Color(0xFF8DB36F));
      const tc = [Color(0xFFCFE0A8), Color(0xFF8DB36F), Color(0xFF8FC1DD), Color(0xFFB8AFA4)];
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          c.drawRect(Rect.fromLTWH(20 + x * 12.0, 20 + y * 12.0, 11.4, 11.4), _p(tc[(x * 7 + y * 3 + v) % 7 < 4 ? 0 : (x + y) % 3 + 1]));
        }
      }
      for (final o in const [Offset(38, 44), Offset(50, 44), Offset(50, 56)]) {
        c.drawRect(Rect.fromCenter(center: o + const Offset(0, 1.5), width: 8, height: 6), _p(const Color(0xFFB0563B)));
        c.drawPath(Path()..addPolygon([o + const Offset(-5, -1), o + const Offset(0, -6), o + const Offset(5, -1)], true), _p(const Color(0xFF7A3B28)));
      }
      c.drawCircle(const Offset(62, 56), 4, _stroke(const Color(0xFF3E6FB0), 2));
    default:
      return false;
  }
  return true;
}
