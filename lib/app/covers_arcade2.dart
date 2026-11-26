part of 'covers.dart';

/// Arcade Klasikleri merkezinin oyuna özgü kapakları (tür adları `a-` ile
/// başlar). Her çizim yalnız bir oyunu anlatır: tahtası, kahramanı ya da
/// mekaniği farklı bir sahnedir; ortak taban türü (space, ball, target,
/// runner…) paylaşılmaz. Renkler merkezin onaylı mor–kehribar paletiyle
/// uyumludur. Vektör, dış görsel ve marka yok. Döndürür: çizildiyse true.
bool _paintArcade2Cover(Canvas c, GameCover cover, Color seed) {
  if (!cover.kind.startsWith('a-')) return false;
  const amber = Color(0xFFFFB02E);
  const orange = Color(0xFFFF7A2E);
  const gold = Color(0xFFFFC93C);
  const night = Color(0xFF180840);
  const violet = Color(0xFF3A1270);
  const cyan = Color(0xFF4CC9F0);
  const lime = Color(0xFF80ED99);
  const pink = Color(0xFFF72585);

  void plain(Color top, Color bottom) {
    c.drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom])
              .createShader(const Rect.fromLTWH(0, 0, 100, 100)));
  }

  void stars(int n, {double alpha = 0.7}) {
    for (var i = 0; i < n; i++) {
      c.drawCircle(Offset((i * 37 + 11) % 96 + 2, (i * 53 + 7) % 96 + 2), i % 3 == 0 ? 1.3 : 0.8,
          _p(Colors.white.withValues(alpha: alpha)));
    }
  }

  RRect rr(double l, double t, double w, double h, [double r = 3]) =>
      RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r));

  Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);

  void star5(Offset o, double r, Color col) {
    final s = Path();
    for (var i = 0; i < 10; i++) {
      final a = -math.pi / 2 + i * math.pi / 5;
      final rad = i.isEven ? r : r * 0.45;
      final p = Offset(o.dx + rad * math.cos(a), o.dy + rad * math.sin(a));
      i == 0 ? s.moveTo(p.dx, p.dy) : s.lineTo(p.dx, p.dy);
    }
    c.drawPath(s..close(), _p(col));
  }

  void burst(Offset o, double r, Color col) {
    final s = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final rad = i.isEven ? r : r * 0.5;
      final p = Offset(o.dx + rad * math.cos(a), o.dy + rad * math.sin(a));
      i == 0 ? s.moveTo(p.dx, p.dy) : s.lineTo(p.dx, p.dy);
    }
    c.drawPath(s..close(), _p(col));
  }

  // Basit insan figürü (kafa + gövde + kol/bacak çizgileri).
  void person(Offset o, double s, Color body, {double lean = 0, bool arms = true}) {
    final st = _stroke(body, s * 0.22);
    c.drawCircle(o + Offset(lean * s * 0.3, -s * 1.15), s * 0.32, _p(const Color(0xFFFFD6A5)));
    c.drawLine(o + Offset(lean * s * 0.25, -s * 0.85), o + Offset(0, -s * 0.1), _stroke(body, s * 0.34));
    c.drawLine(o + Offset(0, -s * 0.1), o + Offset(-s * 0.35, s * 0.55), st);
    c.drawLine(o + Offset(0, -s * 0.1), o + Offset(s * 0.4, s * 0.45), st);
    if (arms) {
      c.drawLine(o + Offset(lean * s * 0.2, -s * 0.7), o + Offset(-s * 0.45, -s * 0.35), st);
      c.drawLine(o + Offset(lean * s * 0.2, -s * 0.7), o + Offset(s * 0.5, -s * 0.55), st);
    }
  }

  // Üstten görünen araba.
  void carTop(Offset o, Color col, {double a = 0, double s = 1}) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(a);
    c.scale(s);
    final body = rr(-6, -10, 12, 20, 3);
    _shadowRRect(c, body, dy: 1.2);
    c.drawRRect(body, _p(col));
    c.drawRRect(rr(-4.5, -6, 9, 5, 1.5), _p(const Color(0xFFBDE0FE)));
    c.drawRRect(rr(-4.5, 3, 9, 4, 1.5), _p(const Color(0xFF8ECAE6)));
    c.drawCircle(const Offset(-4, -9.2), 1, _p(const Color(0xFFFFF3B0)));
    c.drawCircle(const Offset(4, -9.2), 1, _p(const Color(0xFFFFF3B0)));
    c.restore();
  }

  // Futbol topu (beşgen motifli).
  void soccerBall(Offset o, double r) {
    _stone(c, o, r, Colors.white);
    final pent = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final p = o + Offset(math.cos(a) * r * 0.38, math.sin(a) * r * 0.38);
      i == 0 ? pent.moveTo(p.dx, p.dy) : pent.lineTo(p.dx, p.dy);
    }
    c.drawPath(pent..close(), _p(_ink));
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      c.drawLine(o + Offset(math.cos(a) * r * 0.38, math.sin(a) * r * 0.38),
          o + Offset(math.cos(a) * r * 0.95, math.sin(a) * r * 0.95), _stroke(_ink, r * 0.1));
    }
  }

  switch (cover.kind) {
    // ---- Klasik arcade -------------------------------------------------------
    case 'a-yilan': // Klasik yılan: LCD ızgara, kare kare yılan, elma
      plain(const Color(0xFF9BBC0F), const Color(0xFF6E8F0A));
      final px = _p(const Color(0xFF0F380F));
      c.drawRect(const Rect.fromLTWH(6, 6, 88, 88), _stroke(const Color(0xFF0F380F), 2));
      for (final (x, y) in const [
        (2, 8), (3, 8), (4, 8), (5, 8), (5, 7), (5, 6), (5, 5), (6, 5), (7, 5), (8, 5), (8, 4), (8, 3),
      ]) {
        c.drawRect(Rect.fromLTWH(8 + x * 8.0 + 0.6, 8 + y * 8.0 + 0.6, 6.8, 6.8), px);
      }
      c.drawRect(const Rect.fromLTWH(74, 34, 2, 2), _p(const Color(0xFF9BBC0F)));
      // Elma: piksel kare + yaprak
      c.drawRect(const Rect.fromLTWH(24.6, 24.6, 6.8, 6.8), _p(const Color(0xFF8B1E1E)));
      c.drawRect(const Rect.fromLTWH(30, 21, 3, 3), px);
      for (var i = 0; i < 3; i++) {
        c.drawRect(Rect.fromLTWH(70.0 + i * 6, 88, 4, 3), px);
      }
    case 'a-yilanio': // Çevrimiçi yılan: kıvrımlı parlak solucanlar, ışık taneleri
      plain(const Color(0xFF14123A), night);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          c.drawCircle(Offset(7 + x * 12.0 + (y.isOdd ? 6 : 0), 7 + y * 12.0), 0.9, _p(Colors.white10));
        }
      }
      for (var i = 0; i < 14; i++) {
        final col = _pal[i % 8];
        final o = Offset((i * 29 + 9) % 90 + 5, (i * 43 + 13) % 90 + 5);
        c.drawCircle(o, 3, _p(col.withValues(alpha: 0.25)));
        c.drawCircle(o, 1.4, _p(col));
      }
      void worm(List<Offset> pts, Color col, double r) {
        for (var i = 0; i < pts.length; i++) {
          c.drawCircle(pts[i], r + 1.5, _p(col.withValues(alpha: 0.25)));
        }
        for (var i = 0; i < pts.length; i++) {
          c.drawCircle(pts[i], r, _p(Color.lerp(col, Colors.white, i.isEven ? 0 : 0.2)!));
        }
        final h = pts.last;
        c.drawCircle(h + Offset(-r * 0.35, -r * 0.3), r * 0.32, _p(Colors.white));
        c.drawCircle(h + Offset(r * 0.35, -r * 0.3), r * 0.32, _p(Colors.white));
        c.drawCircle(h + Offset(-r * 0.3, -r * 0.35), r * 0.15, _p(_ink));
        c.drawCircle(h + Offset(r * 0.4, -r * 0.35), r * 0.15, _p(_ink));
      }
      worm([for (var i = 0; i < 12; i++) Offset(14 + i * 5.5, 70 - math.sin(i * 0.6) * 12)], pink, 5.5);
      worm([for (var i = 0; i < 9; i++) Offset(80 - math.sin(i * 0.5) * 10, 88 - i * 6.5)], amber, 4.5);
      worm([for (var i = 0; i < 7; i++) Offset(20 + i * 4, 18 + math.cos(i * 0.8) * 5)], cyan, 3.8);
    case 'a-uzayatisi': // Dikey uzay atışı: ikiz lazer, patlayan düşman, kalkan halkası
      plain(night, const Color(0xFF0B1026));
      stars(26);
      // Hız çizgileri
      for (final x in [12.0, 30.0, 70.0, 88.0]) {
        c.drawLine(Offset(x, 10 + x % 20), Offset(x, 30 + x % 20), _stroke(Colors.white24, 0.8));
      }
      burst(const Offset(50, 22), 13, orange);
      burst(const Offset(50, 22), 7, gold);
      for (final dx in [-6.0, 6.0]) {
        c.drawLine(Offset(50 + dx, 66), Offset(50 + dx, 34), _stroke(pink.withValues(alpha: 0.4), 4));
        c.drawLine(Offset(50 + dx, 66), Offset(50 + dx, 34), _stroke(Colors.white, 1.4));
      }
      // Gemi: delta kanat + kokpit + iki itici alev
      c.drawPath(poly(const [Offset(50, 60), Offset(66, 86), Offset(56, 82), Offset(50, 88), Offset(44, 82), Offset(34, 86)]),
          _p(const Color(0xFFDEE2E6)));
      c.drawPath(poly(const [Offset(50, 62), Offset(54, 76), Offset(46, 76)]), _p(cyan));
      c.drawPath(poly(const [Offset(44, 86), Offset(47, 96), Offset(50, 86)]), _p(orange));
      c.drawPath(poly(const [Offset(50, 86), Offset(53, 96), Offset(56, 86)]), _p(gold));
      c.drawCircle(const Offset(50, 76), 20, _stroke(cyan.withValues(alpha: 0.3), 1.2));
    case 'a-istila': // İstilacılar: piksel uzaylı sıraları, kalkan siperleri, top
      plain(const Color(0xFF0A0A1F), night);
      stars(10, alpha: 0.4);
      const alien = ['0010000100', '0001001000', '0011111100', '0110110110', '1111111111', '1011111101', '1010000101', '0001101100'];
      void invader(double ox, double oy, double s, Color col) {
        for (var y = 0; y < alien.length; y++) {
          for (var x = 0; x < 10; x++) {
            if (alien[y][x] == '1') c.drawRect(Rect.fromLTWH(ox + x * s, oy + y * s, s, s), _p(col));
          }
        }
      }
      for (var r = 0; r < 2; r++) {
        for (var i = 0; i < 4; i++) {
          invader(10 + i * 21.0, 12 + r * 16.0, 1.4, r == 0 ? lime : pink);
        }
      }
      for (final x in [14.0, 42.0, 70.0]) {
        c.drawPath(
            Path()
              ..moveTo(x, 76)
              ..lineTo(x, 68)
              ..quadraticBezierTo(x + 8, 62, x + 16, 68)
              ..lineTo(x + 16, 76)
              ..lineTo(x + 11, 76)
              ..lineTo(x + 11, 72)
              ..lineTo(x + 5, 72)
              ..lineTo(x + 5, 76)
              ..close(),
            _p(const Color(0xFF3BA776)));
      }
      c.drawLine(const Offset(50, 58), const Offset(50, 48), _stroke(Colors.white, 1.5));
      c.drawRect(const Rect.fromLTWH(42, 86, 16, 6), _p(cyan));
      c.drawRect(const Rect.fromLTWH(48, 82, 4, 5), _p(cyan));
      c.drawLine(const Offset(30, 40), const Offset(31, 46), _stroke(amber, 1.2));
    case 'a-asteroit': // Vektör çizgili gemi ve çok köşeli kayalar (tel çerçeve)
      plain(const Color(0xFF05050F), const Color(0xFF101026));
      final line = _stroke(Colors.white, 1.6);
      void rock(Offset o, double r, int seed) {
        final p = Path();
        for (var i = 0; i < 9; i++) {
          final a = i * 2 * math.pi / 9;
          final rad = r * (0.72 + ((i * 7 + seed) % 5) * 0.08);
          final q = o + Offset(math.cos(a) * rad, math.sin(a) * rad);
          i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
        }
        c.drawPath(p..close(), line);
      }
      rock(const Offset(24, 26), 15, 1);
      rock(const Offset(78, 30), 10, 3);
      rock(const Offset(74, 76), 13, 2);
      rock(const Offset(20, 78), 6, 4);
      c.save();
      c.translate(48, 54);
      c.rotate(-0.6);
      c.drawPath(poly(const [Offset(0, -10), Offset(7, 8), Offset(0, 4), Offset(-7, 8)]), _stroke(gold, 1.8));
      c.drawPath(poly(const [Offset(-3, 7), Offset(0, 13), Offset(3, 7)]), _stroke(orange, 1.2));
      c.restore();
      for (var i = 0; i < 3; i++) {
        c.drawCircle(Offset(40 - i * 5.0, 42 - i * 6.5), 1.1, _p(Colors.white));
      }
    case 'a-raket': // Raket düellosu: orta kesik çizgi, iki kürek, kare top, skor
      plain(const Color(0xFF111827), const Color(0xFF0B0F1A));
      for (var y = 6.0; y < 96; y += 9) {
        c.drawRect(Rect.fromLTWH(49, y, 2, 5), _p(Colors.white38));
      }
      c.drawRRect(rr(8, 30, 5, 22, 2), _p(cyan));
      c.drawRRect(rr(87, 52, 5, 22, 2), _p(pink));
      c.drawRect(const Rect.fromLTWH(62, 40, 5, 5), _p(Colors.white));
      for (var i = 1; i < 4; i++) {
        c.drawRect(Rect.fromLTWH(62.0 - i * 7, 40.0 - i * 3.4 + 1, 3, 3), _p(Colors.white.withValues(alpha: 0.35 - i * 0.08)));
      }
      _text(c, '3', const Offset(34, 14), 12, cyan);
      _text(c, '2', const Offset(66, 14), 12, pink);
      c.drawRect(const Rect.fromLTWH(4, 4, 92, 92), _stroke(Colors.white24, 1));
    case 'a-labkov': // Labirent kovalamaca: koridorlar, yem noktaları, kahraman ve iki avcı
      plain(const Color(0xFF0D0A2B), night);
      final wall = _stroke(const Color(0xFF7B61FF), 3.2);
      for (final r in const [
        Rect.fromLTWH(8, 8, 84, 84), Rect.fromLTWH(22, 22, 20, 14), Rect.fromLTWH(58, 22, 20, 14),
        Rect.fromLTWH(22, 64, 20, 14), Rect.fromLTWH(58, 64, 20, 14),
      ]) {
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), wall);
      }
      c.drawLine(const Offset(50, 22), const Offset(50, 36), wall);
      c.drawLine(const Offset(50, 64), const Offset(50, 78), wall);
      for (var x = 15.0; x <= 85; x += 7) {
        c.drawCircle(Offset(x, 50), 1.3, _p(gold));
      }
      for (var y = 15.0; y <= 85; y += 7) {
        if ((y - 50).abs() > 3) c.drawCircle(Offset(15, y), 1.3, _p(gold));
      }
      c.drawCircle(const Offset(85, 15), 3, _p(gold));
      // Kahraman: yeşil damla gözlü
      c.drawCircle(const Offset(36, 50), 6, _p(lime));
      c.drawCircle(const Offset(38, 48), 1.6, _p(Colors.white));
      c.drawCircle(const Offset(38.5, 48), 0.8, _p(_ink));
      // Avcılar: dikenli yuvarlak
      for (final (o, col) in const [(Offset(64, 50), Color(0xFFFF5C8A)), (Offset(78, 50), Color(0xFFFFA94D))]) {
        burst(o, 6.5, col);
        c.drawCircle(o, 4, _p(col));
        c.drawCircle(o + const Offset(-1.6, -0.5), 1.2, _p(Colors.white));
        c.drawCircle(o + const Offset(1.6, -0.5), 1.2, _p(Colors.white));
      }
    case 'a-isik': // Işık motoru: perspektif neon ızgara, iki parlak iz ve motorlar
      plain(const Color(0xFF020617), const Color(0xFF1B0A3A));
      final grid = _stroke(cyan.withValues(alpha: 0.25), 0.8);
      for (var i = 0; i <= 10; i++) {
        c.drawLine(Offset(50 + (i - 5) * 4.0, 36), Offset(50 + (i - 5) * 22.0, 100), grid);
      }
      for (var i = 0; i < 6; i++) {
        final y = 36 + math.pow(i / 5, 1.8) * 64;
        c.drawLine(Offset(0, y.toDouble()), Offset(100, y.toDouble()), grid);
      }
      c.drawRect(const Rect.fromLTWH(0, 0, 100, 36), _p(const Color(0xFF020617)));
      c.drawLine(const Offset(0, 36), const Offset(100, 36), _stroke(pink, 1.2));
      void glowPath(Path p, Color col) {
        c.drawPath(p, _stroke(col.withValues(alpha: 0.3), 6));
        c.drawPath(p, _stroke(col, 2.2));
      }
      glowPath(Path()..moveTo(14, 98)..lineTo(28, 66)..lineTo(52, 66)..lineTo(58, 50), cyan);
      glowPath(Path()..moveTo(92, 96)..lineTo(78, 74)..lineTo(66, 74)..lineTo(70, 56), orange);
      c.drawRRect(rr(55, 44, 6, 9, 2), _p(Colors.white));
      c.drawRRect(rr(67, 50, 6, 9, 2), _p(Colors.white));
      c.drawCircle(const Offset(58, 45), 1.4, _p(cyan));
      c.drawCircle(const Offset(70, 51), 1.4, _p(orange));
    case 'a-alan': // Alan kapma: renkli bölgeler, bölgeden çıkan kesik iz, kare oyuncu
      plain(const Color(0xFFF3EEFF), const Color(0xFFE0D6FF));
      c.drawPath(poly(const [Offset(8, 56), Offset(40, 50), Offset(46, 92), Offset(8, 92)]), _p(const Color(0xFF9D6BFF)));
      c.drawPath(poly(const [Offset(60, 8), Offset(92, 8), Offset(92, 42), Offset(66, 38)]), _p(const Color(0xFFFF9F43)));
      c.drawPath(poly(const [Offset(70, 66), Offset(92, 60), Offset(92, 92), Offset(64, 92)]), _p(const Color(0xFF2EC4B6)));
      final trail = _stroke(const Color(0xFF6A1E9C), 2.6);
      final tp = Path()..moveTo(40, 54)..lineTo(40, 28)..lineTo(58, 28)..lineTo(58, 44);
      for (final m in tp.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 6) {
          c.drawPath(m.extractPath(d, d + 3.5), trail);
        }
      }
      c.drawRRect(rr(53, 42, 10, 10, 2.5), _p(const Color(0xFF6A1E9C)));
      c.drawRRect(rr(55, 44, 6, 6, 1.5), _p(const Color(0xFFB794F6)));
      c.drawRRect(rr(16, 18, 8, 8, 2), _p(const Color(0xFFFF9F43)));

    // ---- Koş ve zıpla ---------------------------------------------------------
    case 'a-kosu': // Sonsuz koşu: yandan şehir, kayarak bariyerin altından geçen koşucu
      plain(const Color(0xFFFFB86B), const Color(0xFFE76F51));
      c.drawCircle(const Offset(76, 26), 12, _p(const Color(0xFFFFE8A3)));
      for (final (x, h) in const [(0.0, 34.0), (14.0, 46.0), (30.0, 28.0), (46.0, 52.0), (64.0, 38.0), (84.0, 44.0)]) {
        c.drawRect(Rect.fromLTWH(x, 74 - h, 15, h), _p(const Color(0xFF7A3E65).withValues(alpha: 0.6)));
      }
      c.drawRect(const Rect.fromLTWH(0, 74, 100, 26), _p(const Color(0xFF3D2C4E)));
      for (var x = 4.0; x < 100; x += 16) {
        c.drawRect(Rect.fromLTWH(x, 85, 8, 2), _p(gold));
      }
      // Bariyer
      c.drawRect(const Rect.fromLTWH(54, 52, 4, 22), _p(Colors.white));
      c.drawRect(const Rect.fromLTWH(84, 52, 4, 22), _p(Colors.white));
      c.drawRect(const Rect.fromLTWH(52, 52, 38, 7), _p(_red));
      for (var i = 0; i < 4; i++) {
        c.drawRect(Rect.fromLTWH(56.0 + i * 9, 52, 4, 7), _p(Colors.white));
      }
      // Kayan koşucu (yatık)
      c.drawCircle(const Offset(62, 66), 3.6, _p(const Color(0xFFFFD6A5)));
      c.drawLine(const Offset(58, 68), const Offset(44, 71), _stroke(cyan, 4.5));
      c.drawLine(const Offset(44, 71), const Offset(34, 72), _stroke(_ink, 2.4));
      c.drawLine(const Offset(46, 70), const Offset(38, 66), _stroke(_ink, 2.4));
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(16.0 + i * 3, 64.0 + i * 3), Offset(28.0 + i * 3, 64.0 + i * 3), _stroke(Colors.white54, 1));
      }
      _stone(c, const Offset(24, 46), 3.2, gold);
      _stone(c, const Offset(34, 42), 3.2, gold);
    case 'a-dinozor': // Dinozor koşusu: çöl, kaktüsün üstünden atlayan yeşil dinozor
      plain(const Color(0xFFFFE7B3), const Color(0xFFF4C27A));
      c.drawCircle(const Offset(80, 20), 9, _p(const Color(0xFFFFF4D6)));
      c.drawPath(poly(const [Offset(0, 74), Offset(22, 62), Offset(40, 74)]), _p(const Color(0xFFE9A86A)));
      c.drawPath(poly(const [Offset(50, 74), Offset(78, 58), Offset(100, 74)]), _p(const Color(0xFFE9A86A)));
      c.drawRect(const Rect.fromLTWH(0, 74, 100, 26), _p(const Color(0xFFD98E4A)));
      for (var x = 6.0; x < 100; x += 13) {
        c.drawRect(Rect.fromLTWH(x, 80 + (x % 3), 3, 1.4), _p(const Color(0xFFB86A2E)));
      }
      // Kaktüs
      const cg = Color(0xFF2D6A4F);
      c.drawRRect(rr(66, 54, 7, 20, 3.5), _p(cg));
      c.drawRRect(rr(59, 58, 5, 9, 2.5), _p(cg));
      c.drawRect(const Rect.fromLTWH(61, 64, 6, 3), _p(cg));
      c.drawRRect(rr(75, 56, 5, 8, 2.5), _p(cg));
      c.drawRect(const Rect.fromLTWH(72, 61, 5, 3), _p(cg));
      // Dinozor (havada)
      const dg = Color(0xFF52B788);
      final dino = Path()
        ..moveTo(26, 52)
        ..quadraticBezierTo(22, 40, 32, 36)
        ..lineTo(34, 26)
        ..quadraticBezierTo(36, 20, 46, 21)
        ..quadraticBezierTo(52, 22, 51, 28)
        ..lineTo(42, 30)
        ..lineTo(42, 38)
        ..quadraticBezierTo(46, 46, 40, 52)
        ..close();
      c.drawPath(dino, _p(dg));
      c.drawPath(poly(const [Offset(26, 50), Offset(12, 44), Offset(28, 42)]), _p(dg));
      c.drawLine(const Offset(30, 52), const Offset(28, 58), _stroke(dg, 3.4));
      c.drawLine(const Offset(38, 52), const Offset(42, 57), _stroke(dg, 3.4));
      c.drawCircle(const Offset(43, 25), 1.5, _p(_ink));
      for (var i = 0; i < 4; i++) {
        c.drawCircle(Offset(31.0 + i * 3, 37.5 - i * 0.5), 1.1, _p(const Color(0xFFB7E4C7)));
      }
      c.drawOval(const Rect.fromLTWH(22, 76, 22, 3), _p(Colors.black12));
    case 'a-kaykay': // Kaykay koşusu: üç şeritli perspektif yol, kaykaycı, raylı engel
      plain(const Color(0xFF7DD3FC), const Color(0xFF3A86FF));
      c.drawPath(poly(const [Offset(40, 30), Offset(60, 30), Offset(100, 100), Offset(0, 100)]), _p(const Color(0xFF475569)));
      for (final t in [-1.0, 1.0]) {
        for (var i = 0; i < 6; i++) {
          final y0 = 34 + i * 12.0;
          final x0 = 50 + t * (3.3 + (y0 - 30) * 0.24);
          c.drawLine(Offset(x0, y0), Offset(50 + t * (3.3 + (y0 + 6 - 30) * 0.24), y0 + 6), _stroke(Colors.white70, 1.2));
        }
      }
      for (final x in [8.0, 24.0, 76.0, 92.0]) {
        c.drawRect(Rect.fromLTWH(x - 6, 6 + (x % 7), 12, 26 - (x % 7)), _p(const Color(0xFFB5179E).withValues(alpha: 0.55)));
      }
      c.drawRRect(rr(58, 40, 14, 10, 2), _p(orange));
      c.drawRect(const Rect.fromLTWH(60, 50, 2, 4), _p(_ink));
      c.drawRect(const Rect.fromLTWH(68, 50, 2, 4), _p(_ink));
      _stone(c, const Offset(46, 46), 2.6, gold);
      _stone(c, const Offset(45, 54), 2.8, gold);
      // Kaykaycı
      person(const Offset(42, 78), 9, const Color(0xFF6A1E9C), lean: 0.6);
      c.drawRRect(rr(29, 84, 24, 3.4, 1.7), _p(amber));
      c.drawCircle(const Offset(33, 89), 2, _p(_ink));
      c.drawCircle(const Offset(49, 89), 2, _p(_ink));
    case 'a-ziplama': // Sonsuz zıplama: neon küp dikenlerin üstünden sekiyor, hız çizgileri
      plain(const Color(0xFF2B0B57), const Color(0xFF12052E));
      for (var i = 0; i < 5; i++) {
        c.drawLine(Offset(4, 20.0 + i * 9), Offset(30.0 - i * 3, 20.0 + i * 9), _stroke(Colors.white24, 1.2));
      }
      c.drawRect(const Rect.fromLTWH(0, 76, 100, 24), _p(const Color(0xFF3A1270)));
      c.drawLine(const Offset(0, 76), const Offset(100, 76), _stroke(cyan, 2));
      for (final x in [46.0, 56.0, 84.0]) {
        c.drawPath(poly([Offset(x - 5, 76), Offset(x, 64), Offset(x + 5, 76)]), _p(pink));
      }
      c.drawRRect(rr(70, 62, 10, 14, 1), _p(const Color(0xFF7B61FF)));
      // Zıplama yayı
      for (var i = 0; i < 6; i++) {
        final t = i / 6;
        c.drawCircle(Offset(26 + t * 46, 70 - math.sin(t * math.pi) * 40), 1.2, _p(Colors.white38));
      }
      c.save();
      c.translate(50, 34);
      c.rotate(0.5);
      c.drawRect(const Rect.fromLTWH(-8, -8, 16, 16), _p(gold));
      c.drawRect(const Rect.fromLTWH(-8, -8, 16, 16), _stroke(Colors.white, 1.4));
      c.drawRect(const Rect.fromLTWH(-3, -3, 6, 6), _p(orange));
      c.restore();
    case 'a-kanat': // Kanat çırpma: taş sütunlar arası yuvarlak kuş, kanadı açık
      plain(const Color(0xFF9AD0F5), const Color(0xFFFFD6E0));
      c.drawCircle(const Offset(22, 18), 8, _p(const Color(0xFFFFF3B0)));
      for (final (x, h) in const [(0.0, 18.0), (18.0, 26.0), (36.0, 14.0), (56.0, 22.0), (76.0, 16.0)]) {
        c.drawRect(Rect.fromLTWH(x, 100 - h, 20, h), _p(const Color(0xFFB8A1D9)));
      }
      void column(double x, double top, double bottom) {
        c.drawRect(Rect.fromLTWH(x, top, 16, bottom - top), _p(const Color(0xFFCBB89D)));
        c.drawRect(Rect.fromLTWH(x - 2, bottom - 5, 20, 5), _p(const Color(0xFFA68A64)));
        for (var y = top + 6; y < bottom - 6; y += 7) {
          c.drawLine(Offset(x + 4, y), Offset(x + 4, y + 4), _stroke(Colors.black12, 1.2));
          c.drawLine(Offset(x + 11, y + 2), Offset(x + 11, y + 6), _stroke(Colors.black12, 1.2));
        }
      }
      column(66, 0, 34);
      c.drawRect(const Rect.fromLTWH(64, 66, 20, 5), _p(const Color(0xFFA68A64)));
      c.drawRect(const Rect.fromLTWH(66, 70, 16, 30), _p(const Color(0xFFCBB89D)));
      // Kuş
      _stone(c, const Offset(36, 50), 10, orange);
      c.drawPath(
          Path()
            ..moveTo(30, 50)
            ..quadraticBezierTo(22, 36, 34, 40)
            ..close(),
          _p(gold));
      c.drawCircle(const Offset(41, 46), 3.2, _p(Colors.white));
      c.drawCircle(const Offset(42, 46), 1.5, _p(_ink));
      c.drawPath(poly(const [Offset(45, 50), Offset(53, 52), Offset(45, 55)]), _p(const Color(0xFFE63946)));
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(14.0, 46.0 + i * 4), Offset(22.0, 46.0 + i * 4), _stroke(Colors.white70, 1.2));
      }
    case 'a-ucak': // Kâğıt uçak: bulutlar arası süzülen uçak, ilmekli kesik iz, halkalar
      plain(const Color(0xFFBDE0FE), const Color(0xFFE0C3FC));
      for (final (x, y, w) in const [(10.0, 70.0, 28.0), (60.0, 80.0, 34.0), (64.0, 16.0, 24.0)]) {
        c.drawOval(Rect.fromLTWH(x, y, w, w * 0.38), _p(Colors.white));
        c.drawOval(Rect.fromLTWH(x + w * 0.2, y - w * 0.18, w * 0.5, w * 0.4), _p(Colors.white));
      }
      final path = Path()
        ..moveTo(6, 40)
        ..cubicTo(20, 20, 34, 60, 24, 56)
        ..cubicTo(14, 52, 30, 34, 44, 46)
        ..lineTo(56, 52);
      for (final m in path.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 5) {
          c.drawPath(m.extractPath(d, d + 2.5), _stroke(const Color(0xFF6A1E9C).withValues(alpha: 0.6), 1.3));
        }
      }
      c.drawOval(const Rect.fromLTWH(78, 40, 8, 22), _stroke(amber, 2.4));
      c.drawPath(poly(const [Offset(56, 46), Offset(80, 50), Offset(58, 58)]), _p(Colors.white));
      c.drawPath(poly(const [Offset(56, 46), Offset(80, 50), Offset(62, 52)]), _p(const Color(0xFFE5E7EB)));
      c.drawLine(const Offset(62, 52), const Offset(80, 50), _stroke(const Color(0xFF9CA3AF), 0.8));
    case 'a-platform': // Platform: tuğla platformlar, yıldızlı soru kutusu, düşman, bayrak
      plain(const Color(0xFF6EC6FF), const Color(0xFFB3E5FC));
      c.drawOval(const Rect.fromLTWH(12, 12, 22, 8), _p(Colors.white));
      c.drawRect(const Rect.fromLTWH(0, 84, 100, 16), _p(const Color(0xFF8D5524)));
      c.drawRect(const Rect.fromLTWH(0, 82, 100, 4), _p(const Color(0xFF55A630)));
      void bricks(double x, double y, int n) {
        for (var i = 0; i < n; i++) {
          c.drawRect(Rect.fromLTWH(x + i * 9, y, 9, 8), _p(const Color(0xFFC1440E)));
          c.drawRect(Rect.fromLTWH(x + i * 9, y, 9, 8), _stroke(const Color(0xFF7F2704), 0.8));
        }
      }
      bricks(14, 54, 3);
      bricks(58, 40, 2);
      c.drawRect(const Rect.fromLTWH(41, 54, 9, 8), _p(gold));
      star5(const Offset(45.5, 58), 3, Colors.white);
      // Bayrak
      c.drawLine(const Offset(88, 82), const Offset(88, 28), _stroke(Colors.white, 1.6));
      c.drawPath(poly(const [Offset(88, 28), Offset(76, 33), Offset(88, 38)]), _p(_red));
      // Düşman: mantar gövdeli böcek
      c.drawArc(const Rect.fromLTWH(56, 72, 14, 14), math.pi, math.pi, true, _p(const Color(0xFF8B4513)));
      c.drawCircle(const Offset(60, 77), 1.2, _p(Colors.white));
      c.drawCircle(const Offset(66, 77), 1.2, _p(Colors.white));
      // Kahraman zıplıyor
      person(const Offset(30, 40), 7, const Color(0xFF1D4ED8), lean: 0.2);
      c.drawRect(const Rect.fromLTWH(26.5, 30, 7, 2.5), _p(_red));
      _stone(c, const Offset(66, 32), 2.6, gold);
    case 'a-kosates': // Koş ve ateş et: silahlı kahraman, mermi izi, robot düşman, kasalar
      plain(const Color(0xFF3D405B), const Color(0xFF22223B));
      for (final (x, h) in const [(0.0, 30.0), (22.0, 40.0), (50.0, 24.0), (74.0, 36.0)]) {
        c.drawRect(Rect.fromLTWH(x, 72 - h, 24, h), _p(const Color(0xFF4A4E69)));
      }
      c.drawRect(const Rect.fromLTWH(0, 72, 100, 28), _p(const Color(0xFF6B4F3A)));
      c.drawRect(const Rect.fromLTWH(0, 72, 100, 3), _p(const Color(0xFF9C6644)));
      // Kasa
      c.drawRect(const Rect.fromLTWH(50, 60, 12, 12), _p(const Color(0xFFBC8A5F)));
      c.drawLine(const Offset(50, 60), const Offset(62, 72), _stroke(const Color(0xFF7F5539), 1.2));
      c.drawLine(const Offset(62, 60), const Offset(50, 72), _stroke(const Color(0xFF7F5539), 1.2));
      // Kahraman
      person(const Offset(22, 62), 8, const Color(0xFF2A9D8F));
      c.drawRect(const Rect.fromLTWH(24, 49, 9, 3), _p(_ink));
      burst(const Offset(35, 50.5), 3.5, gold);
      for (var i = 0; i < 3; i++) {
        c.drawRRect(rr(42.0 + i * 10, 49.5, 5, 2, 1), _p(gold));
      }
      // Robot
      c.drawRRect(rr(74, 44, 14, 16, 3), _p(const Color(0xFFADB5BD)));
      c.drawRect(const Rect.fromLTWH(76, 48, 10, 4), _p(_red));
      c.drawLine(const Offset(77, 60), const Offset(76, 72), _stroke(const Color(0xFF6C757D), 3));
      c.drawLine(const Offset(85, 60), const Offset(86, 72), _stroke(const Color(0xFF6C757D), 3));
      c.drawLine(const Offset(81, 44), const Offset(81, 38), _stroke(const Color(0xFF6C757D), 1.4));
      c.drawCircle(const Offset(81, 37), 1.6, _p(_red));
    case 'a-yolgecme': // Yol geçme: üstten çimen-yol-nehir şeritleri, ördek yavrusu, kütükler
      const lanes = [
        Color(0xFF7BC950), Color(0xFF495057), Color(0xFF495057), Color(0xFF7BC950), Color(0xFF3A86FF), Color(0xFF3A86FF), Color(0xFF7BC950),
      ];
      for (var i = 0; i < lanes.length; i++) {
        c.drawRect(Rect.fromLTWH(0, i * 100 / 7, 100, 100 / 7 + 0.5), _p(lanes[i]));
      }
      for (var x = 4.0; x < 100; x += 14) {
        c.drawRect(Rect.fromLTWH(x, 28.0, 7, 1.2), _p(Colors.white70));
      }
      carTop(const Offset(22, 21.5), _red, a: math.pi / 2, s: 0.8);
      carTop(const Offset(74, 36), gold, a: -math.pi / 2, s: 0.8);
      c.drawRRect(rr(8, 60, 30, 9, 4), _p(const Color(0xFF8D6E63)));
      c.drawRRect(rr(58, 74, 34, 9, 4), _p(const Color(0xFF8D6E63)));
      for (final x in [14.0, 26.0, 66.0, 80.0]) {
        c.drawCircle(Offset(x, x < 50 ? 64.5 : 78.5), 1.6, _p(const Color(0xFF6D4C41)));
      }
      for (final (x, y) in const [(12.0, 50.0), (88.0, 52.0), (20.0, 92.0)]) {
        c.drawCircle(Offset(x, y), 4.5, _p(const Color(0xFF2D6A4F)));
      }
      // Ördek yavrusu
      c.drawOval(const Rect.fromLTWH(44, 88, 12, 9), _p(const Color(0xFFFFE066)));
      c.drawCircle(const Offset(50, 86), 4, _p(const Color(0xFFFFE066)));
      c.drawPath(poly(const [Offset(48.5, 83), Offset(50, 80), Offset(51.5, 83)]), _p(orange));
      c.drawCircle(const Offset(48.5, 85.5), 0.8, _p(_ink));
      c.drawCircle(const Offset(51.5, 85.5), 0.8, _p(_ink));
    case 'a-ustten': // Üstten yarış: trafikte giden kurye minibüsü, paket simgesi, şerit çizgileri
      plain(const Color(0xFF55A630), const Color(0xFF3F7D20));
      c.drawRect(const Rect.fromLTWH(18, 0, 64, 100), _p(const Color(0xFF3F3F46)));
      c.drawRect(const Rect.fromLTWH(18, 0, 3, 100), _p(Colors.white));
      c.drawRect(const Rect.fromLTWH(79, 0, 3, 100), _p(Colors.white));
      for (final x in [39.0, 60.0]) {
        for (var y = 2.0; y < 100; y += 14) {
          c.drawRect(Rect.fromLTWH(x, y, 2, 7), _p(Colors.white70));
        }
      }
      carTop(const Offset(30, 28), const Color(0xFF3A86FF));
      carTop(const Offset(70, 46), const Color(0xFF9D4EDD));
      carTop(const Offset(30, 84), const Color(0xFFE63946));
      // Kurye minibüsü
      c.drawRRect(rr(42, 58, 16, 28, 3), _p(amber));
      c.drawRRect(rr(44, 60, 12, 6, 2), _p(const Color(0xFFBDE0FE)));
      c.drawRect(const Rect.fromLTWH(45, 70, 10, 10), _p(const Color(0xFFC08A5A)));
      c.drawLine(const Offset(50, 70), const Offset(50, 80), _stroke(const Color(0xFF7F5539), 1));
      c.drawLine(const Offset(45, 75), const Offset(55, 75), _stroke(const Color(0xFF7F5539), 1));
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(44.0 + i * 6, 90), Offset(44.0 + i * 6, 98), _stroke(Colors.white38, 1.2));
      }
      // Hedef işareti
      c.drawCircle(const Offset(70, 12), 6, _p(pink));
      c.drawCircle(const Offset(70, 12), 2.4, _p(Colors.white));
      c.drawPath(poly(const [Offset(65, 14), Offset(70, 22), Offset(75, 14)]), _p(pink));
    case 'a-park': // 2B park: çizgili park yerleri, geri giren araba, rehber ok, konilar
      plain(const Color(0xFF52525B), const Color(0xFF3F3F46));
      final lineP = _stroke(Colors.white, 1.6);
      for (var i = 0; i < 5; i++) {
        c.drawLine(Offset(10 + i * 20.0, 8), Offset(10 + i * 20.0, 40), lineP);
      }
      c.drawLine(const Offset(10, 8), const Offset(90, 8), lineP);
      carTop(const Offset(20, 24), const Color(0xFF3A86FF), s: 1.1);
      carTop(const Offset(60, 24), const Color(0xFFE63946), s: 1.1);
      carTop(const Offset(80, 24), const Color(0xFF6A994E), s: 1.1);
      // Boş yer yeşil çerçeve + P
      c.drawRect(const Rect.fromLTWH(31, 10, 18, 29), _p(lime.withValues(alpha: 0.2)));
      _text(c, 'P', const Offset(40, 24), 12, lime);
      // Geri giren araba
      carTop(const Offset(52, 70), amber, a: 0.7, s: 1.2);
      final arrow = Path()
        ..moveTo(46, 60)
        ..quadraticBezierTo(38, 52, 40, 44);
      c.drawPath(arrow, _stroke(Colors.white, 2));
      c.drawPath(poly(const [Offset(36, 46), Offset(40, 40), Offset(44, 46)]), _p(Colors.white));
      for (final x in [14.0, 86.0]) {
        c.drawPath(poly([Offset(x - 4, 92), Offset(x, 80), Offset(x + 4, 92)]), _p(orange));
        c.drawRect(Rect.fromLTWH(x - 2.4, 85, 4.8, 2), _p(Colors.white));
      }

    // ---- Spor --------------------------------------------------------------------
    case 'a-dart': // Dart tahtası: dilimli tahta, çift/üçlü halkalar, saplanmış üç ok
      plain(violet, night);
      const o = Offset(46, 54);
      c.drawCircle(o + const Offset(0, 2), 38, _p(Colors.black38));
      c.drawCircle(o, 38, _p(const Color(0xFF1F1F1F)));
      for (var i = 0; i < 20; i++) {
        final a0 = -math.pi / 2 - math.pi / 20 + i * math.pi / 10;
        final dark = i.isEven;
        for (final (r1, r2, base) in [
          (32.0, 30.0, dark ? _red : const Color(0xFF2D6A4F)),
          (30.0, 19.0, dark ? const Color(0xFF111111) : const Color(0xFFF1E3C6)),
          (19.0, 17.0, dark ? _red : const Color(0xFF2D6A4F)),
          (17.0, 5.0, dark ? const Color(0xFF111111) : const Color(0xFFF1E3C6)),
        ]) {
          final p = Path()
            ..arcTo(Rect.fromCircle(center: o, radius: r1), a0, math.pi / 10, true)
            ..arcTo(Rect.fromCircle(center: o, radius: r2), a0 + math.pi / 10, -math.pi / 10, false)
            ..close();
          c.drawPath(p, _p(base));
        }
      }
      c.drawCircle(o, 5, _p(const Color(0xFF2D6A4F)));
      c.drawCircle(o, 2.4, _p(_red));
      for (final (x, y) in const [(50.0, 50.0), (38.0, 40.0), (58.0, 66.0)]) {
        c.drawLine(Offset(x, y), Offset(x + 14, y - 12), _stroke(const Color(0xFFADB5BD), 1.6));
        c.drawPath(poly([Offset(x + 12, y - 10), Offset(x + 20, y - 14), Offset(x + 16, y - 18)]), _p(amber));
      }
    case 'a-nisan': // Nişan antrenmanı: dağınık küçülen hedef halkaları, artı imleci, isabet izi
      plain(const Color(0xFF101828), const Color(0xFF1E1B4B));
      final g = _stroke(Colors.white10, 0.6);
      for (var i = 0.0; i <= 100; i += 12.5) {
        c.drawLine(Offset(i, 0), Offset(i, 100), g);
        c.drawLine(Offset(0, i), Offset(100, i), g);
      }
      for (final (x, y, r, a) in const [(24.0, 26.0, 9.0, 1.0), (74.0, 30.0, 6.0, 0.8), (30.0, 74.0, 4.5, 0.6), (80.0, 76.0, 3.0, 0.5)]) {
        c.drawCircle(Offset(x, y), r, _p(cyan.withValues(alpha: a)));
        c.drawCircle(Offset(x, y), r * 0.55, _p(Colors.white.withValues(alpha: a)));
        c.drawCircle(Offset(x, y), r * 0.22, _p(cyan.withValues(alpha: a)));
        c.drawCircle(Offset(x, y), r + 3, _stroke(cyan.withValues(alpha: a * 0.35), 0.8));
      }
      const m = Offset(54, 54);
      final cross = _stroke(lime, 1.8);
      c.drawCircle(m, 10, cross);
      for (final d in const [Offset(0, -1), Offset(0, 1), Offset(-1, 0), Offset(1, 0)]) {
        c.drawLine(m + d * 5, m + d * 15, cross);
      }
      c.drawCircle(m, 1.4, _p(lime));
      _text(c, '+50', const Offset(76, 50), 8, gold);
    case 'a-galeri': // Atış galerisi: çizgili tente, raylı ahşap ördekler, yasak levha
      plain(const Color(0xFF5A1E3C), const Color(0xFF2A0E2A));
      for (var i = 0; i < 7; i++) {
        c.drawRect(Rect.fromLTWH(i * 100 / 7, 0, 100 / 7, 18), _p(i.isEven ? _red : Colors.white));
      }
      for (var i = 0; i < 7; i++) {
        c.drawArc(Rect.fromLTWH(i * 100 / 7, 12, 100 / 7, 10), 0, math.pi, true, _p(i.isEven ? _red : Colors.white));
      }
      for (var i = 0; i < 9; i++) {
        c.drawCircle(Offset(6 + i * 11.0, 26), 1.6, _p(gold));
      }
      c.drawRect(const Rect.fromLTWH(0, 62, 100, 6), _p(const Color(0xFF8A5A36)));
      c.drawRect(const Rect.fromLTWH(0, 86, 100, 14), _p(const Color(0xFF6B3E26)));
      void duck(double x, Color col, {bool down = false}) {
        if (down) {
          c.drawOval(Rect.fromLTWH(x - 8, 58, 16, 5), _p(col.withValues(alpha: 0.7)));
          return;
        }
        c.drawOval(Rect.fromLTWH(x - 8, 48, 16, 12), _p(col));
        c.drawCircle(Offset(x + 5, 44), 5, _p(col));
        c.drawPath(poly([Offset(x + 9, 43), Offset(x + 14, 45), Offset(x + 9, 46)]), _p(orange));
        c.drawCircle(Offset(x + 6, 43), 1, _p(_ink));
        c.drawRect(Rect.fromLTWH(x - 1, 60, 2, 3), _p(_ink));
      }
      duck(18, gold);
      duck(42, gold, down: true);
      duck(66, gold);
      // Yasak levha (vurma)
      c.drawRect(const Rect.fromLTWH(85, 56, 2, 7), _p(_ink));
      c.drawCircle(const Offset(86, 50), 7, _p(Colors.white));
      c.drawCircle(const Offset(86, 50), 7, _stroke(_red, 2));
      c.drawLine(const Offset(81, 55), const Offset(91, 45), _stroke(_red, 2));
      c.drawCircle(const Offset(42, 78), 6, _stroke(lime, 1.4));
      c.drawLine(const Offset(42, 70), const Offset(42, 86), _stroke(lime, 1));
      c.drawLine(const Offset(34, 78), const Offset(50, 78), _stroke(lime, 1));
    case 'a-okculuk': // Okçuluk: gerili yay ve ok, ayaklı saman hedef, rüzgâr flaması
      plain(const Color(0xFF9AD0F5), const Color(0xFFC7E9B0));
      c.drawRect(const Rect.fromLTWH(0, 74, 100, 26), _p(const Color(0xFF6A994E)));
      // Hedef ayaklı
      c.drawLine(const Offset(72, 60), const Offset(66, 84), _stroke(_wood, 2.4));
      c.drawLine(const Offset(80, 60), const Offset(86, 84), _stroke(_wood, 2.4));
      c.drawCircle(const Offset(76, 46), 17, _p(const Color(0xFFE9C46A)));
      for (final (r, col) in const [
        (14.0, Colors.white), (11.0, Color(0xFF222222)), (8.0, Color(0xFF3A86FF)), (5.0, Color(0xFFE63946)), (2.4, Color(0xFFFFD60A)),
      ]) {
        c.drawCircle(const Offset(76, 46), r, _p(col));
      }
      // Yay
      c.drawArc(const Rect.fromLTWH(6, 30, 20, 44), -math.pi / 2, math.pi, false, _stroke(const Color(0xFF7F4F24), 3));
      c.drawLine(const Offset(16, 30), const Offset(8, 52), _stroke(Colors.white, 0.9));
      c.drawLine(const Offset(8, 52), const Offset(16, 74), _stroke(Colors.white, 0.9));
      c.drawLine(const Offset(8, 52), const Offset(44, 50), _stroke(const Color(0xFF8D6E63), 1.8));
      c.drawPath(poly(const [Offset(44, 48), Offset(50, 50), Offset(44, 52)]), _p(const Color(0xFF6C757D)));
      c.drawPath(poly(const [Offset(8, 52), Offset(12, 48), Offset(14, 52), Offset(12, 56)]), _p(_red));
      // Flama
      c.drawLine(const Offset(44, 74), const Offset(44, 20), _stroke(Colors.white, 1.2));
      c.drawPath(poly(const [Offset(44, 20), Offset(58, 24), Offset(44, 28)]), _p(orange));
    case 'a-refleks': // Refleks testi: büyük basma düğmesi, yeşil “şimdi” ışığı, kronometre
      plain(const Color(0xFF14532D), const Color(0xFF052E16));
      for (var i = 0; i < 3; i++) {
        c.drawCircle(Offset(26 + i * 24.0, 16), 7, _p(i == 2 ? const Color(0xFF4ADE80) : const Color(0xFF1F3B2A)));
        if (i == 2) c.drawCircle(const Offset(74, 16), 11, _p(const Color(0xFF4ADE80).withValues(alpha: 0.25)));
      }
      c.drawOval(const Rect.fromLTWH(18, 64, 64, 22), _p(const Color(0xFF1F2937)));
      c.drawOval(const Rect.fromLTWH(24, 52, 52, 24), _p(const Color(0xFFB91C1C)));
      c.drawOval(const Rect.fromLTWH(24, 48, 52, 24), _p(const Color(0xFFEF4444)));
      c.drawOval(const Rect.fromLTWH(32, 51, 22, 7), _p(Colors.white30));
      // Şimşek
      c.drawPath(poly(const [Offset(54, 26), Offset(42, 44), Offset(50, 44), Offset(44, 58), Offset(60, 38), Offset(51, 38)]), _p(gold));
      _text(c, '183ms', const Offset(50, 92), 9, Colors.white);
    case 'a-basket': // Basket: pota, file, kavisli atış izi, parke zemin
      plain(const Color(0xFF2B2D42), const Color(0xFF1B1C2B));
      c.drawRect(const Rect.fromLTWH(0, 82, 100, 18), _p(const Color(0xFFC8874B)));
      for (var x = 0.0; x < 100; x += 10) {
        c.drawLine(Offset(x, 82), Offset(x, 100), _stroke(const Color(0xFF9C6644), 0.8));
      }
      c.drawRect(const Rect.fromLTWH(56, 12, 34, 24), _p(Colors.white));
      c.drawRect(const Rect.fromLTWH(66, 20, 14, 10), _stroke(_red, 1.6));
      c.drawLine(const Offset(88, 36), const Offset(96, 82), _stroke(const Color(0xFF6C757D), 3));
      c.drawLine(const Offset(60, 38), const Offset(80, 38), _stroke(orange, 2.4));
      for (var i = 0; i < 5; i++) {
        c.drawLine(Offset(60.0 + i * 5, 38), Offset(63.0 + i * 3.5, 50), _stroke(Colors.white70, 0.8));
      }
      c.drawLine(const Offset(62, 44), const Offset(78, 44), _stroke(Colors.white54, 0.7));
      for (var i = 0; i < 7; i++) {
        final t = i / 7;
        c.drawCircle(Offset(18 + t * 42, 70 - math.sin(t * math.pi) * 52 + t * 4), 1.3, _p(Colors.white38));
      }
      _stone(c, const Offset(62, 28), 8, orange);
      c.drawArc(Rect.fromCircle(center: const Offset(62, 28), radius: 8), -1.2, 2.4, false, _stroke(Colors.black45, 0.9));
      c.drawLine(const Offset(54, 28), const Offset(70, 28), _stroke(Colors.black45, 0.9));
    case 'a-bowling': // Bowling: perspektif pist, üçgen dizilmiş on lobut, yuvarlanan top
      plain(const Color(0xFF241046), night);
      c.drawPath(poly(const [Offset(36, 8), Offset(64, 8), Offset(88, 100), Offset(12, 100)]), _p(const Color(0xFFD9A066)));
      for (var i = 1; i < 5; i++) {
        c.drawLine(Offset(36 + i * 5.6, 8), Offset(12 + i * 15.2, 100), _stroke(const Color(0xFFB07A45), 0.7));
      }
      c.drawPath(poly(const [Offset(36, 8), Offset(12, 100), Offset(6, 100), Offset(33, 8)]), _p(const Color(0xFF3A1270)));
      c.drawPath(poly(const [Offset(64, 8), Offset(88, 100), Offset(94, 100), Offset(67, 8)]), _p(const Color(0xFF3A1270)));
      for (var row = 3; row >= 0; row--) {
        for (var i = 0; i <= row; i++) {
          final x = 50 + (i - row / 2) * 6.0;
          final y = 14 + (3 - row) * 5.0;
          c.drawOval(Rect.fromCenter(center: Offset(x, y + 4), width: 4.6, height: 10), _p(Colors.white));
          c.drawCircle(Offset(x, y), 1.8, _p(Colors.white));
          c.drawLine(Offset(x - 1.6, y + 2), Offset(x + 1.6, y + 2), _stroke(_red, 0.9));
        }
      }
      _stone(c, const Offset(46, 76), 12, const Color(0xFF6A1E9C));
      for (final d in const [Offset(-3, -4), Offset(2, -5), Offset(-0.5, 0)]) {
        c.drawCircle(const Offset(46, 76) + d, 1.4, _p(night));
      }
      c.drawLine(const Offset(46, 90), const Offset(47, 96), _stroke(Colors.white38, 1));
    case 'a-golf': // Mini golf: kenarlı yeşil parkur, yel değirmeni engeli, sekme izi, bayrak
      plain(const Color(0xFF2E1065), night);
      final course = Path()
        ..moveTo(10, 90)
        ..lineTo(10, 50)
        ..lineTo(46, 50)
        ..lineTo(46, 12)
        ..lineTo(90, 12)
        ..lineTo(90, 90)
        ..close();
      c.drawPath(course, _p(const Color(0xFF52B788)));
      c.drawPath(course, _stroke(const Color(0xFFC08A5A), 3.6));
      c.drawCircle(const Offset(74, 24), 3, _p(_ink));
      c.drawLine(const Offset(74, 24), const Offset(74, 6), _stroke(Colors.white, 1.2));
      c.drawPath(poly(const [Offset(74, 6), Offset(84, 9), Offset(74, 12)]), _p(gold));
      // Yel değirmeni
      c.drawRect(const Rect.fromLTWH(60, 56, 12, 16), _p(const Color(0xFFE76F51)));
      c.drawPath(poly(const [Offset(58, 56), Offset(66, 48), Offset(74, 56)]), _p(const Color(0xFF9D0208)));
      for (var i = 0; i < 4; i++) {
        final a = 0.4 + i * math.pi / 2;
        c.drawLine(const Offset(66, 52), Offset(66 + math.cos(a) * 13, 52 + math.sin(a) * 13), _stroke(Colors.white, 2.4));
      }
      final shot = Path()..moveTo(22, 80)..lineTo(38, 56)..lineTo(52, 72)..lineTo(80, 36);
      for (final m in shot.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 5) {
          c.drawPath(m.extractPath(d, d + 2.4), _stroke(Colors.white70, 1.2));
        }
      }
      _stone(c, const Offset(22, 80), 3.4, Colors.white);
    case 'a-penalti': // Penaltı: önden kale, ağ dokusu, uzanan kaleci, köşeye giden top
      plain(const Color(0xFF1B263B), const Color(0xFF0D1B2A));
      c.drawRect(const Rect.fromLTWH(0, 70, 100, 30), _p(const Color(0xFF2D6A4F)));
      for (var i = 0; i < 5; i++) {
        c.drawRect(Rect.fromLTWH(i * 20.0, 70, 10, 30), _p(const Color(0xFF40916C)));
      }
      final net = _stroke(Colors.white24, 0.6);
      for (var x = 12.0; x <= 88; x += 4) {
        c.drawLine(Offset(x, 20), Offset(x, 70), net);
      }
      for (var y = 20.0; y <= 70; y += 4) {
        c.drawLine(Offset(12, y), Offset(88, y), net);
      }
      c.drawLine(const Offset(12, 70), const Offset(12, 18), _stroke(Colors.white, 3));
      c.drawLine(const Offset(88, 70), const Offset(88, 18), _stroke(Colors.white, 3));
      c.drawLine(const Offset(10.5, 18), const Offset(89.5, 18), _stroke(Colors.white, 3));
      // Kaleci (çapraz uzanmış)
      c.save();
      c.translate(40, 52);
      c.rotate(-0.9);
      c.drawRRect(rr(-4, -12, 8, 20, 3), _p(gold));
      c.drawCircle(const Offset(0, -16), 4, _p(const Color(0xFFFFD6A5)));
      c.drawLine(const Offset(-2, -10), const Offset(-8, -22), _stroke(gold, 3));
      c.drawLine(const Offset(2, -10), const Offset(8, -22), _stroke(gold, 3));
      c.drawLine(const Offset(-2, 8), const Offset(-4, 18), _stroke(_ink, 3));
      c.drawLine(const Offset(2, 8), const Offset(5, 18), _stroke(_ink, 3));
      c.restore();
      soccerBall(const Offset(76, 30), 6.5);
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(66.0 - i * 3, 40.0 + i * 3), Offset(58.0 - i * 3, 50.0 + i * 3), _stroke(Colors.white38, 1.2));
      }
      c.drawCircle(const Offset(50, 88), 1.6, _p(Colors.white));
    case 'a-futbol': // Parmak futbolu: üstten saha, top süren oyuncu, iki rakip, kale
      plain(const Color(0xFF2D6A4F), const Color(0xFF1B4332));
      for (var i = 0; i < 5; i++) {
        c.drawRect(Rect.fromLTWH(0, i * 20.0, 100, 10), _p(const Color(0xFF40916C)));
      }
      final ln = _stroke(Colors.white70, 1.4);
      c.drawRect(const Rect.fromLTWH(6, 6, 88, 88), ln);
      c.drawLine(const Offset(6, 50), const Offset(94, 50), ln);
      c.drawCircle(const Offset(50, 50), 12, ln);
      c.drawRect(const Rect.fromLTWH(30, 6, 40, 14), ln);
      c.drawRect(const Rect.fromLTWH(40, 2, 20, 4), _p(Colors.white));
      void player(Offset o, Color col) {
        c.drawCircle(o + const Offset(0, 1.2), 5.5, _p(Colors.black26));
        c.drawCircle(o, 5.5, _p(col));
        c.drawCircle(o, 2.4, _p(const Color(0xFF3D2C1E)));
      }
      player(const Offset(32, 30), const Color(0xFFE63946));
      player(const Offset(62, 36), const Color(0xFFE63946));
      player(const Offset(46, 66), const Color(0xFF3A86FF));
      soccerBall(const Offset(52, 56), 3.6);
      final run = Path()..moveTo(46, 66)..quadraticBezierTo(70, 56, 56, 24);
      c.drawPath(run, _stroke(gold, 1.6));
      c.drawPath(poly(const [Offset(52, 26), Offset(56, 18), Offset(60, 26)]), _p(gold));
    case 'a-tenis': // Tenis: kil kort üstten, file, iki raket ve top, iz çizgisi
      plain(const Color(0xFF1D3557), const Color(0xFF0D1B2A));
      c.drawRect(const Rect.fromLTWH(14, 6, 72, 88), _p(const Color(0xFFD4703A)));
      final w = _stroke(Colors.white, 1.3);
      c.drawRect(const Rect.fromLTWH(14, 6, 72, 88), w);
      c.drawLine(const Offset(24, 6), const Offset(24, 94), w);
      c.drawLine(const Offset(76, 6), const Offset(76, 94), w);
      c.drawLine(const Offset(24, 30), const Offset(76, 30), w);
      c.drawLine(const Offset(24, 70), const Offset(76, 70), w);
      c.drawLine(const Offset(50, 30), const Offset(50, 70), w);
      c.drawLine(const Offset(10, 50), const Offset(90, 50), _stroke(Colors.white, 2.6));
      c.drawLine(const Offset(10, 51.5), const Offset(90, 51.5), _stroke(Colors.black26, 1));
      void racket(Offset o, double a, Color col) {
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(a);
        c.drawOval(const Rect.fromLTWH(-6, -16, 12, 15), _p(Colors.white24));
        c.drawOval(const Rect.fromLTWH(-6, -16, 12, 15), _stroke(col, 2));
        c.drawLine(const Offset(0, -1), const Offset(0, 9), _stroke(_ink, 2.6));
        c.restore();
      }
      racket(const Offset(34, 84), -0.5, cyan);
      racket(const Offset(66, 20), 2.6, pink);
      final tr = Path()..moveTo(38, 72)..quadraticBezierTo(60, 54, 62, 38);
      for (final m in tr.computeMetrics()) {
        for (var d = 0.0; d < m.length; d += 5) {
          c.drawPath(m.extractPath(d, d + 2.5), _stroke(Colors.white70, 1));
        }
      }
      _stone(c, const Offset(62, 38), 3.6, const Color(0xFFD4E157));
    case 'a-voleybol': // Plaj voleybolu: kum, file, sıçrayan oyuncu, güneş ve top
      plain(const Color(0xFFFFC371), const Color(0xFFFF5F6D));
      c.drawCircle(const Offset(80, 22), 11, _p(const Color(0xFFFFF1B8)));
      c.drawRect(const Rect.fromLTWH(0, 62, 100, 12), _p(const Color(0xFF48CAE4)));
      c.drawRect(const Rect.fromLTWH(0, 74, 100, 26), _p(const Color(0xFFF4D58D)));
      c.drawLine(const Offset(50, 84), const Offset(50, 40), _stroke(Colors.white, 1.8));
      final net = _stroke(Colors.white70, 0.6);
      for (var y = 42.0; y <= 58; y += 4) {
        c.drawLine(Offset(48, y), Offset(52, y), net);
      }
      c.drawRect(const Rect.fromLTWH(47.5, 40, 5, 18), _stroke(Colors.white, 0.9));
      person(const Offset(30, 66), 8, const Color(0xFF3A0CA3));
      c.drawLine(const Offset(30, 57), const Offset(34, 46), _stroke(const Color(0xFF3A0CA3), 1.8));
      person(const Offset(74, 80), 7, const Color(0xFFD00000), arms: false);
      _stone(c, const Offset(38, 32), 6.5, Colors.white);
      c.drawArc(Rect.fromCircle(center: const Offset(38, 32), radius: 6.5), 0.4, 2.0, false, _stroke(const Color(0xFF3A86FF), 1.6));
      c.drawArc(Rect.fromCircle(center: const Offset(38, 32), radius: 6.5), 3.2, 1.6, false, _stroke(gold, 1.6));

    // ---- Beceri ---------------------------------------------------------------
    case 'a-kulekurma': // Kule kurma: izometrik dilimler, kayarak gelen dilim, kopan parça
      plain(const Color(0xFF7B2CBF), const Color(0xFF240046));
      void slab(double cx, double cy, double w, Color col) {
        final top = poly([Offset(cx, cy - w * 0.3), Offset(cx + w * 0.6, cy), Offset(cx, cy + w * 0.3), Offset(cx - w * 0.6, cy)]);
        final left = poly([Offset(cx - w * 0.6, cy), Offset(cx, cy + w * 0.3), Offset(cx, cy + w * 0.3 + 6), Offset(cx - w * 0.6, cy + 6)]);
        final right = poly([Offset(cx + w * 0.6, cy), Offset(cx, cy + w * 0.3), Offset(cx, cy + w * 0.3 + 6), Offset(cx + w * 0.6, cy + 6)]);
        c.drawPath(left, _p(Color.lerp(col, Colors.black, 0.25)!));
        c.drawPath(right, _p(Color.lerp(col, Colors.black, 0.45)!));
        c.drawPath(top, _p(col));
      }
      for (var i = 0; i < 6; i++) {
        slab(50, 86 - i * 9.0, 40 - i * 1.5, Color.lerp(const Color(0xFF4CC9F0), pink, i / 6)!);
      }
      slab(66, 22, 30, gold);
      // Kopan parça düşüyor
      c.save();
      c.translate(84, 50);
      c.rotate(0.5);
      c.drawRect(const Rect.fromLTWH(-4, -3, 8, 6), _p(orange));
      c.restore();
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(84.0 + i * 3, 36), Offset(84.0 + i * 3, 42), _stroke(Colors.white30, 1));
      }

    // ---- Fizik ve nişan ---------------------------------------------------------------
    case 'a-sapan': // Sapan: Y sapan gerili, kaleyi oluşturan bloklar, tepede yaratıklar
      plain(const Color(0xFF90E0EF), const Color(0xFFCAF0F8));
      c.drawRect(const Rect.fromLTWH(0, 82, 100, 18), _p(const Color(0xFF6A994E)));
      c.drawLine(const Offset(18, 82), const Offset(18, 64), _stroke(_wood, 4));
      c.drawLine(const Offset(18, 66), const Offset(11, 54), _stroke(_wood, 3.5));
      c.drawLine(const Offset(18, 66), const Offset(25, 54), _stroke(_wood, 3.5));
      c.drawLine(const Offset(11, 55), const Offset(8, 64), _stroke(const Color(0xFF3D2C1E), 1.4));
      c.drawLine(const Offset(25, 55), const Offset(8, 64), _stroke(const Color(0xFF3D2C1E), 1.4));
      _stone(c, const Offset(8, 64), 3.6, const Color(0xFF6C757D));
      for (var i = 1; i < 6; i++) {
        final t = i / 6;
        c.drawCircle(Offset(10 + t * 58, 62 - math.sin(t * math.pi) * 34), 1.2, _p(Colors.white));
      }
      const wood = Color(0xFFD4A373);
      c.drawRect(const Rect.fromLTWH(60, 62, 5, 20), _p(wood));
      c.drawRect(const Rect.fromLTWH(84, 62, 5, 20), _p(wood));
      c.drawRect(const Rect.fromLTWH(58, 58, 33, 4), _p(wood));
      c.drawRect(const Rect.fromLTWH(70, 42, 4, 16), _p(const Color(0xFFADB5BD)));
      c.drawRect(const Rect.fromLTWH(66, 38, 14, 4), _p(wood));
      for (final o in const [Offset(76, 76), Offset(73, 32)]) {
        c.drawCircle(o, 5, _p(lime));
        c.drawCircle(o + const Offset(-1.8, -1), 1.2, _p(Colors.white));
        c.drawCircle(o + const Offset(1.8, -1), 1.2, _p(Colors.white));
        c.drawLine(o + const Offset(-1.5, 2), o + const Offset(1.5, 2), _stroke(_ink, 0.8));
      }
    case 'a-topcu': // Topçu düellosu: iki tepe, karşılıklı toplar, mermi kavisi, rüzgâr oku
      plain(const Color(0xFFFFB4A2), const Color(0xFF6D597A));
      c.drawPath(
          Path()
            ..moveTo(0, 100)
            ..lineTo(0, 66)
            ..quadraticBezierTo(18, 54, 34, 70)
            ..quadraticBezierTo(50, 86, 66, 66)
            ..quadraticBezierTo(82, 48, 100, 62)
            ..lineTo(100, 100)
            ..close(),
          _p(const Color(0xFF355070)));
      void cannon(Offset o, double a, Color col) {
        c.drawArc(Rect.fromCircle(center: o, radius: 6), math.pi, math.pi, true, _p(col));
        c.drawLine(o, o + Offset(math.cos(a) * 12, math.sin(a) * 12), _stroke(col, 4));
        c.drawCircle(o + const Offset(0, 1), 2.5, _p(_ink));
      }
      cannon(const Offset(16, 60), -0.7, cyan);
      cannon(const Offset(86, 56), -2.5, pink);
      for (var i = 1; i < 9; i++) {
        final t = i / 9;
        c.drawCircle(Offset(26 + t * 46, 52 - math.sin(t * math.pi) * 38), 1.2, _p(Colors.white70));
      }
      burst(const Offset(78, 52), 6, gold);
      _stone(c, const Offset(52, 15), 2.6, _ink);
      // Rüzgâr oku
      c.drawLine(const Offset(10, 14), const Offset(30, 14), _stroke(Colors.white, 1.8));
      c.drawPath(poly(const [Offset(30, 10), Offset(36, 14), Offset(30, 18)]), _p(Colors.white));
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(12.0 + i * 5, 20), Offset(18.0 + i * 5, 20), _stroke(Colors.white54, 1));
      }
    case 'a-egik': // Eğik labirent: ahşap eğik tahta, duvarlar, çelik bilye, delikler ve hedef
      plain(const Color(0xFF3A1270), night);
      final board = poly(const [Offset(16, 12), Offset(88, 18), Offset(92, 90), Offset(8, 84)]);
      c.drawPath(board.shift(const Offset(0, 4)), _p(const Color(0xFF5C3A21)));
      c.drawPath(board, _p(const Color(0xFFD7A86E)));
      final wall = _stroke(const Color(0xFF8A5A36), 3.4);
      c.drawPath(board, wall);
      c.drawLine(const Offset(14, 40), const Offset(60, 42), wall);
      c.drawLine(const Offset(40, 62), const Offset(90, 66), wall);
      c.drawLine(const Offset(60, 42), const Offset(60, 26), wall);
      for (final o in const [Offset(30, 54), Offset(76, 32), Offset(24, 74)]) {
        c.drawCircle(o, 4.4, _p(const Color(0xFF2B1B12)));
      }
      c.drawCircle(const Offset(80, 80), 5, _p(lime));
      c.drawCircle(const Offset(80, 80), 2.4, _p(const Color(0xFF1B4332)));
      c.drawCircle(const Offset(36, 26) + const Offset(0, 1.6), 5, _p(Colors.black38));
      c.drawCircle(
          const Offset(36, 26),
          5,
          Paint()
            ..shader = const RadialGradient(center: Alignment(-0.4, -0.5), colors: [Colors.white, Color(0xFFADB5BD), Color(0xFF495057)])
                .createShader(Rect.fromCircle(center: const Offset(36, 26), radius: 5)));
      // Eğim oku
      c.drawArc(const Rect.fromLTWH(70, 2, 24, 14), 0.2, 2.6, false, _stroke(amber, 1.8));
    default:
      return false;
  }
  return true;
}
