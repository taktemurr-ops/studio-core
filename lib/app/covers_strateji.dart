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
    case 'dicebagc': // zar macerası: torba ve üç zar
      _bg(c, seed, tint: const Color(0xFF4A2E57));
      final bag = Path()
        ..moveTo(30, 40)
        ..quadraticBezierTo(22, 78, 50, 82)
        ..quadraticBezierTo(78, 78, 70, 40)
        ..close();
      c.drawPath(bag, _p(const Color(0xFFB38B5D)));
      c.drawLine(const Offset(32, 42), const Offset(68, 42), _stroke(const Color(0xFF6E4E2E), 3));
      const faces = [Color(0xFFB0563B), Color(0xFF3E6FB0), Color(0xFF7A4E7E)];
      for (var i = 0; i < 3; i++) {
        c.save();
        c.translate(34.0 + i * 16, 30.0 - (i == 1 ? 8 : 0));
        c.rotate((i - 1) * 0.25 + v * 0.05);
        final r = RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -8, 16, 16), const Radius.circular(3.5));
        c.drawRRect(r, _p(const Color(0xFFF4EBDD)));
        c.drawRRect(r, _stroke(faces[i], 1.4));
        for (var d = 0; d <= i; d++) {
          c.drawCircle(Offset(-4.0 + d * 4, -4.0 + d * 4), 1.6, _p(faces[i]));
        }
        c.restore();
      }
      c.drawCircle(const Offset(50, 64), 5, _p(const Color(0xFFD9A441)));
    case 'seasoncrownc': // dört mevsim krallık: dört renkli dilim ve taç
      _bg(c, seed, tint: const Color(0xFF8C6A3F));
      const sc = [Color(0xFF8DBF6A), Color(0xFFE0A93B), Color(0xFFC0703A), Color(0xFF7FA7C9)];
      for (var k = 0; k < 4; k++) {
        c.drawArc(Rect.fromCircle(center: const Offset(50, 54), radius: 30), -math.pi / 2 + k * math.pi / 2 + v * 0.1, math.pi / 2, true, _p(sc[k]));
      }
      c.drawCircle(const Offset(50, 54), 16, _p(const Color(0xFFF4EBDD)));
      final crown = Path()
        ..moveTo(40, 60)
        ..lineTo(38, 46)
        ..lineTo(44, 52)
        ..lineTo(50, 43)
        ..lineTo(56, 52)
        ..lineTo(62, 46)
        ..lineTo(60, 60)
        ..close();
      c.drawPath(crown, _p(const Color(0xFFD9A441)));
      c.drawPath(crown, _stroke(const Color(0xFF7A5A20), 1));
    case 'mapjournalc': // harita defteri: kareli sayfa, renkli parçalar, dağ
      _bg(c, seed, tint: const Color(0xFF4A7A6B));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 18, 64, 64), const Radius.circular(4)), _p(const Color(0xFFF2EAD8)));
      for (var i = 0; i <= 6; i++) {
        c.drawLine(Offset(22 + i * 9.3, 22), Offset(22 + i * 9.3, 78), _stroke(const Color(0x22000000), 0.6));
        c.drawLine(Offset(22, 22 + i * 9.3), Offset(78, 22 + i * 9.3), _stroke(const Color(0x22000000), 0.6));
      }
      const mjc = [Color(0xFF4F7F52), Color(0xFFB0563B), Color(0xFFD9B44A), Color(0xFF4A86B8)];
      const cells = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (3, 1, 3), (4, 1, 3), (4, 2, 3), (1, 3, 1), (2, 3, 1), (2, 4, 1), (4, 4, 2), (5, 4, 2), (5, 5, 2)];
      for (final (x, y, t) in cells) {
        c.drawRect(Rect.fromLTWH(22 + x * 9.3 + 0.4, 22 + y * 9.3 + 0.4, 8.5, 8.5), _p(mjc[(t + v) % 4]));
      }
      c.drawPath(Path()..addPolygon(const [Offset(52, 62), Offset(58, 50), Offset(64, 62)], true), _p(const Color(0xFF8C8178)));
    case 'autobattlerc': // Otomatik Savaşçı: iki yarım tahta, karşılıklı birlikler, çapraz kılıç, yedek sıra
      _bg(c, seed, tint: const Color(0xFF26222F));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 5; x++) {
          c.drawRect(Rect.fromLTWH(15 + x * 14.0, 10 + y * 14.0, 13.2, 13.2),
              _p((x + y).isEven ? const Color(0xFF4A4458) : const Color(0xFF3B3647)));
        }
      }
      c.drawLine(const Offset(15, 38), const Offset(85, 38), _stroke(const Color(0xFFD9B44A).withValues(alpha: 0.6), 1));
      void unit(Offset o, Color col, bool up) {
        final p = Path()
          ..moveTo(o.dx - 5, o.dy - 5)
          ..lineTo(o.dx + 5, o.dy - 5)
          ..lineTo(o.dx + 5, o.dy + 1)
          ..quadraticBezierTo(o.dx, o.dy + 7, o.dx - 5, o.dy + 1)
          ..close();
        c.drawPath(p.shift(const Offset(0, 1)), _p(Colors.black38));
        c.drawPath(p, _p(col));
        c.drawLine(o + Offset(0, up ? -3 : 3), o + Offset(0, up ? 2 : -2), _stroke(Colors.white70, 1.2));
      }
      const red = Color(0xFFB0563B);
      const blue = Color(0xFF4A86B8);
      for (final x in const [1, 2, 3]) {
        unit(Offset(22 + x * 14.0, 17), red, false);
      }
      for (final x in const [0, 2, 4]) {
        unit(Offset(22 + x * 14.0, 59 - ((x + v) % 2) * 14.0), blue, true);
      }
      // Çapraz kılıçlar
      c.drawLine(const Offset(44, 32), const Offset(56, 44), _stroke(const Color(0xFFE8E2D6), 2.2));
      c.drawLine(const Offset(56, 32), const Offset(44, 44), _stroke(const Color(0xFFE8E2D6), 2.2));
      c.drawLine(const Offset(42, 42), const Offset(46, 46), _stroke(const Color(0xFFD9B44A), 2.6));
      c.drawLine(const Offset(58, 42), const Offset(54, 46), _stroke(const Color(0xFFD9B44A), 2.6));
      // Yedek sıra ve altın
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 74, 64, 16), const Radius.circular(4)), _p(const Color(0xFF1A1720)));
      for (var k = 0; k < 4; k++) {
        unit(Offset(21 + k * 15.0, 82), k == v % 4 ? const Color(0xFFD9B44A) : blue, true);
      }
      c.drawCircle(const Offset(86, 82), 6, _p(const Color(0xFFD9B44A)));
      c.drawCircle(const Offset(86, 82), 3.4, _stroke(const Color(0xFF8C6A1E), 1));
    case 'dungeonkeeperc': // Zindan Ustası: odalar ve koridorlar, diken tuzakları, sandık, yaklaşan kahramanlar
      _bg(c, seed, tint: const Color(0xFF1D1B22));
      const stone = Color(0xFF8C8178);
      const floor = Color(0xFFCDBB9A);
      final rooms = [
        const Rect.fromLTWH(10, 12, 30, 26),
        const Rect.fromLTWH(56, 10, 34, 30),
        const Rect.fromLTWH(30, 58, 40, 32),
      ];
      c.drawRect(const Rect.fromLTWH(38, 22, 20, 8), _p(floor.withValues(alpha: 0.8)));
      c.drawRect(const Rect.fromLTWH(20, 36, 8, 30), _p(floor.withValues(alpha: 0.8)));
      c.drawRect(const Rect.fromLTWH(20, 64, 12, 8), _p(floor.withValues(alpha: 0.8)));
      c.drawRect(const Rect.fromLTWH(70, 38, 8, 22), _p(floor.withValues(alpha: 0.8)));
      for (final r in rooms) {
        c.drawRect(r.inflate(2), _p(stone));
        c.drawRect(r, _p(floor));
      }
      // Diken tuzakları
      for (var k = 0; k < 3; k++) {
        final x = 18.0 + k * 6;
        c.drawPath(Path()..addPolygon([Offset(x, 30), Offset(x + 2.5, 24), Offset(x + 5, 30)], true), _p(const Color(0xFF5A5560)));
      }
      // Hazine sandığı
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(41, 66, 18, 13), const Radius.circular(2)), _p(const Color(0xFF8A5A36)));
      c.drawRect(const Rect.fromLTWH(41, 70, 18, 2), _p(const Color(0xFFD9B44A)));
      c.drawRect(const Rect.fromLTWH(48.5, 68, 3, 5), _p(const Color(0xFFD9B44A)));
      // Ustanın gözü (köşede parlayan iki göz)
      c.drawCircle(const Offset(66, 22), 2.2, _p(const Color(0xFFE85D5D)));
      c.drawCircle(const Offset(74, 22), 2.2, _p(const Color(0xFFE85D5D)));
      c.drawArc(Rect.fromCenter(center: const Offset(70, 28), width: 18, height: 12), math.pi, math.pi, false, _stroke(const Color(0xFF5A3E6B), 3));
      // Yaklaşan kahramanlar
      for (var k = 0; k < 2 + v % 2; k++) {
        final o = Offset(74, 46.0 + k * 6);
        c.drawCircle(o, 2.6, _p(const Color(0xFF4A86B8)));
      }
      c.drawCircle(const Offset(66, 22), 6, _p(const Color(0x33E85D5D)));
    default:
      return false;
  }
  return true;
}
