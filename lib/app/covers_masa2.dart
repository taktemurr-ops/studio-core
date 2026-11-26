part of 'covers.dart';

/// Masa Oyunları merkezindeki her oyunun kendine ait kapağı (mc_* türleri).
/// Önceden aynı 'chess' / 'checkers' / 'race' / 'dice' / 'hexes' / 'xo'
/// çizimini paylaşan oyunlar burada kendi tahtasını, taşlarını ya da
/// mekaniğini gösterir. Vektör çizim, dış görsel ve marka yok.
/// Döndürür: tür tanındıysa true.
bool _paintMasa2Cover(Canvas c, GameCover cover, Color seed) {
  const gold = Color(0xFFF5B82E);
  const cream = Color(0xFFF4EBDD);
  const boardTan = Color(0xFFE8CF9C);
  switch (cover.kind) {
    // ---- Satranç ailesi ---------------------------------------------------
    case 'mc_satranc': // perspektif dama tahtasında beyaz şah ve siyah at
      _bg(c, seed, tint: const Color(0xFF14503A));
      double hw(double y) => 30 + (y - 46) * 0.45;
      for (var r = 0; r < 5; r++) {
        final y0 = 46 + r * 10.0, y1 = y0 + 10;
        for (var k = 0; k < 8; k++) {
          final t0 = k / 8, t1 = (k + 1) / 8;
          final q = [
            Offset(50 - hw(y0) + 2 * hw(y0) * t0, y0),
            Offset(50 - hw(y0) + 2 * hw(y0) * t1, y0),
            Offset(50 - hw(y1) + 2 * hw(y1) * t1, y1),
            Offset(50 - hw(y1) + 2 * hw(y1) * t0, y1),
          ];
          c.drawPath(Path()..addPolygon(q, true), _p((r + k).isEven ? const Color(0xFFEBD3A8) : const Color(0xFF7A4B2A)));
        }
      }
      _chessKing(c, const Offset(36, 50), 46, Colors.white);
      _chessKnight(c, const Offset(66, 58), 40, _ink);
      _chessPawn(c, const Offset(84, 74), 22, Colors.white);
    case 'mc_satranccesit': // karışık arka sıra ve karıştırma okları
      _bg(c, seed, tint: const Color(0xFF2D4A3E));
      for (var i = 0; i < 8; i++) {
        c.drawRect(Rect.fromLTWH(8 + i * 10.5, 52, 10.5, 16), _p(i.isEven ? const Color(0xFFEBD3A8) : const Color(0xFF7A4B2A)));
      }
      for (var i = 0; i < 8; i++) {
        final o = Offset(13.25 + i * 10.5, 58);
        switch ((i * 5 + 2) % 3) {
          case 0:
            _chessKnight(c, o, 14, Colors.white);
          case 1:
            _chessKing(c, o, 14, Colors.white);
          default:
            _chessPawn(c, o, 12, Colors.white);
        }
      }
      c.drawPath(
          Path()
            ..moveTo(20, 44)
            ..quadraticBezierTo(50, 8, 80, 44),
          _stroke(gold, 2.4));
      c.drawPath(Path()..addPolygon(const [Offset(80, 44), Offset(73, 40), Offset(80, 36)], true), _p(gold));
      c.drawPath(
          Path()
            ..moveTo(80, 76)
            ..quadraticBezierTo(50, 100, 20, 76),
          _stroke(gold, 2.4));
      c.drawPath(Path()..addPolygon(const [Offset(20, 76), Offset(27, 80), Offset(20, 84)], true), _p(gold));
    case 'mc_xiangqi': // nehirli çizgi tahtası, yuvarlak kırmızı/siyah taşlar
      _bg(c, seed, tint: const Color(0xFF6B2E1E));
      const l = 12.0, t = 10.0, dx = 9.5, dy = 80 / 9;
      c.drawRect(const Rect.fromLTWH(8, 6, 84, 88), _p(const Color(0xFFE9C891)));
      c.drawRect(Rect.fromLTWH(l, t + 4 * dy, 8 * dx, dy), _p(const Color(0xFF7FB7D6).withValues(alpha: 0.55)));
      final ln = _stroke(const Color(0xFF6B3A1E), 0.7);
      for (var j = 0; j <= 9; j++) {
        c.drawLine(Offset(l, t + j * dy), Offset(l + 8 * dx, t + j * dy), ln);
      }
      for (var i = 0; i <= 8; i++) {
        final x = l + i * dx;
        if (i == 0 || i == 8) {
          c.drawLine(Offset(x, t), Offset(x, t + 9 * dy), ln);
        } else {
          c.drawLine(Offset(x, t), Offset(x, t + 4 * dy), ln);
          c.drawLine(Offset(x, t + 5 * dy), Offset(x, t + 9 * dy), ln);
        }
      }
      for (final (i, j) in const [(0, 0), (2, 0), (4, 0), (6, 0), (8, 0), (1, 2), (7, 2), (3, 3)]) {
        _mcDisc(c, Offset(l + i * dx, t + j * dy), 4.2, _ink);
      }
      for (final (i, j) in const [(0, 9), (2, 9), (4, 9), (6, 9), (8, 9), (1, 7), (7, 7), (5, 6)]) {
        _mcDisc(c, Offset(l + i * dx, t + j * dy), 4.2, _red);
      }
    case 'mc_janggi': // saray çaprazlı tahta, sekizgen yeşil/kırmızı taşlar
      _bg(c, seed, tint: const Color(0xFF3D5A40));
      const l = 14.0, t = 10.0, dx = 9.0, dy = 80 / 9;
      c.drawRect(const Rect.fromLTWH(9, 5, 82, 90), _p(const Color(0xFFF0D9A6)));
      final ln = _stroke(const Color(0xFF5C3A20), 0.7);
      for (var j = 0; j <= 9; j++) {
        c.drawLine(Offset(l, t + j * dy), Offset(l + 8 * dx, t + j * dy), ln);
      }
      for (var i = 0; i <= 8; i++) {
        c.drawLine(Offset(l + i * dx, t), Offset(l + i * dx, t + 9 * dy), ln);
      }
      for (final j0 in const [0, 7]) {
        c.drawLine(Offset(l + 3 * dx, t + j0 * dy), Offset(l + 5 * dx, t + (j0 + 2) * dy), ln);
        c.drawLine(Offset(l + 5 * dx, t + j0 * dy), Offset(l + 3 * dx, t + (j0 + 2) * dy), ln);
      }
      const green = Color(0xFF2E7D4F);
      for (final (i, j, r) in const [(4, 1, 6.0), (0, 0, 4.4), (8, 0, 4.4), (1, 2, 4.0), (7, 2, 4.0), (2, 3, 3.6), (6, 3, 3.6)]) {
        _mcOcta(c, Offset(l + i * dx, t + j * dy), r, green);
      }
      for (final (i, j, r) in const [(4, 8, 6.0), (0, 9, 4.4), (8, 9, 4.4), (1, 7, 4.0), (7, 7, 4.0), (4, 6, 3.6), (2, 6, 3.6)]) {
        _mcOcta(c, Offset(l + i * dx, t + j * dy), r, _red);
      }
    case 'mc_shogi': // açık sarı ızgara, iki yöne bakan beşgen kama taşlar
      _bg(c, seed, tint: const Color(0xFF4E3B1F));
      const b = Rect.fromLTWH(14, 14, 72, 72);
      _woodBoard(c, b.inflate(4));
      c.drawRect(b, _p(const Color(0xFFF0CF7A)));
      for (var i = 0; i <= 6; i++) {
        c.drawLine(Offset(b.left + i * 12, b.top), Offset(b.left + i * 12, b.bottom), _stroke(_ink, 0.7));
        c.drawLine(Offset(b.left, b.top + i * 12), Offset(b.right, b.top + i * 12), _stroke(_ink, 0.7));
      }
      for (final (i, j) in const [(2, 2), (4, 2), (2, 4), (4, 4)]) {
        c.drawCircle(Offset(b.left + i * 12, b.top + j * 12), 1.3, _p(_ink));
      }
      for (final (i, j, up) in const [(0, 0, false), (2, 0, false), (4, 0, false), (1, 1, false), (3, 1, false), (5, 2, false),
          (0, 5, true), (2, 5, true), (5, 5, true), (1, 4, true), (4, 4, true), (3, 3, true)]) {
        _mcWedge(c, Offset(b.left + (i + 0.5) * 12, b.top + (j + 0.5) * 12), 5, up);
      }
    // ---- Dama ailesi --------------------------------------------------------
    case 'mc_damacesit': // üç boyda dama tahtası üst üste, taçlı dama
      _bg(c, seed, tint: const Color(0xFF2B4A3A));
      for (final (x, y, n, dark) in const [
        (8.0, 8.0, 6, Color(0xFF7A4B2A)),
        (44.0, 18.0, 5, Color(0xFF2E7D4F)),
        (20.0, 42.0, 8, Color(0xFF3B5B8C)),
      ]) {
        final r = Rect.fromLTWH(x, y, 46, 46);
        _shadowRRect(c, RRect.fromRectAndRadius(r, const Radius.circular(2)), dy: 2.4, a: 0.35);
        final cell = 46 / n;
        for (var i = 0; i < n; i++) {
          for (var j = 0; j < n; j++) {
            c.drawRect(Rect.fromLTWH(x + i * cell, y + j * cell, cell + 0.2, cell + 0.2),
                _p((i + j).isOdd ? dark : const Color(0xFFF1DEB0)));
          }
        }
      }
      _stone(c, const Offset(78, 84), 9, _red);
      _stone(c, const Offset(78, 79), 9, _red);
      _kcCrown(c, const Offset(78, 79), 5, gold);
    case 'mc_turkdama': // tek renk kareler, iki sıra dolu taş, dik yön okları
      _bg(c, seed, tint: const Color(0xFF7A2E1E));
      const b = Rect.fromLTWH(12, 12, 76, 76);
      _woodBoard(c, b.inflate(4));
      c.drawRect(b, _p(const Color(0xFFF1DEB0)));
      const cell = 9.5;
      for (var i = 0; i <= 8; i++) {
        c.drawLine(Offset(b.left + i * cell, b.top), Offset(b.left + i * cell, b.bottom), _stroke(_wood, 0.8));
        c.drawLine(Offset(b.left, b.top + i * cell), Offset(b.right, b.top + i * cell), _stroke(_wood, 0.8));
      }
      for (var i = 0; i < 8; i++) {
        for (final j in const [1, 2]) {
          if (i == 4 && j == 2) continue;
          _stone(c, Offset(b.left + (i + 0.5) * cell, b.top + (j + 0.5) * cell), 3.8, _ink);
        }
        for (final j in const [5, 6]) {
          if (i == 3 && j == 5) continue;
          _stone(c, Offset(b.left + (i + 0.5) * cell, b.top + (j + 0.5) * cell), 3.8, cream);
        }
      }
      const o = Offset(12 + 3.5 * cell, 12 + 4.5 * cell);
      _stone(c, o, 3.8, cream);
      _kcArrow(c, o + const Offset(0, -5), o + const Offset(0, -13), gold);
      _kcArrow(c, o + const Offset(-5, 0), o + const Offset(-13, 0), gold);
      _kcArrow(c, o + const Offset(5, 0), o + const Offset(13, 0), gold);
    case 'mc_alquerque': // 5x5 çaprazlı çizgi tahtası, atlama oku
      _bg(c, seed, tint: const Color(0xFF5B3A29));
      _woodBoard(c, const Rect.fromLTWH(8, 8, 84, 84));
      Offset pt(int i, int j) => Offset(18 + i * 16.0, 18 + j * 16.0);
      final ln = _stroke(const Color(0xFF3A2414), 1.2);
      for (var k = 0; k < 5; k++) {
        c.drawLine(pt(k, 0), pt(k, 4), ln);
        c.drawLine(pt(0, k), pt(4, k), ln);
      }
      for (final (a, b2) in const [((0, 0), (4, 4)), ((4, 0), (0, 4)), ((0, 2), (2, 0)), ((2, 0), (4, 2)), ((4, 2), (2, 4)), ((2, 4), (0, 2))]) {
        c.drawLine(pt(a.$1, a.$2), pt(b2.$1, b2.$2), ln);
      }
      for (var j = 0; j < 5; j++) {
        for (var i = 0; i < 5; i++) {
          if ((i == 2 && j == 2) || (i == 1 && j == 1)) continue;
          final red = j < 2 || (j == 2 && i < 2);
          _stone(c, pt(i, j), 4.6, red ? _red : cream);
        }
      }
      c.drawPath(
          Path()
            ..moveTo(pt(1, 3).dx, pt(1, 3).dy - 5)
            ..quadraticBezierTo(pt(1, 2).dx - 12, pt(1, 2).dy, pt(1, 1).dx, pt(1, 1).dy + 3),
          _stroke(gold, 2.2));
      c.drawCircle(pt(1, 1), 3, _p(gold));
    case 'mc_fanorona': // 9x5 çaprazlı tahta, yaklaşarak süpürme
      _bg(c, seed, tint: const Color(0xFF7B4B2A));
      _woodBoard(c, const Rect.fromLTWH(4, 14, 92, 72));
      Offset pt(int i, int j) => Offset(10 + i * 10.0, 20 + j * 15.0);
      final ln = _stroke(const Color(0xFF3A2414), 1);
      for (var j = 0; j < 5; j++) {
        c.drawLine(pt(0, j), pt(8, j), ln);
      }
      for (var i = 0; i < 9; i++) {
        c.drawLine(pt(i, 0), pt(i, 4), ln);
      }
      for (var j = 0; j < 5; j++) {
        for (var i = 0; i < 9; i++) {
          if ((i + j).isOdd) continue;
          if (i < 8 && j < 4) c.drawLine(pt(i, j), pt(i + 1, j + 1), ln);
          if (i > 0 && j < 4) c.drawLine(pt(i, j), pt(i - 1, j + 1), ln);
        }
      }
      for (var j = 0; j < 5; j++) {
        for (var i = 0; i < 9; i++) {
          if (j == 2) {
            if (i < 4) _stone(c, pt(i, j), 3.6, _ink.withValues(alpha: 0.3));
            if (i > 4) _stone(c, pt(i, j), 3.6, cream);
          } else {
            _stone(c, pt(i, j), 3.6, j < 2 ? _ink : cream);
          }
        }
      }
      _kcArrow(c, pt(5, 2) + const Offset(-4, -6), pt(4, 2) + const Offset(-2, -6), gold);
    case 'mc_dokuztas': // iç içe üç kare, üçlenmiş altın hat
      _bg(c, seed, tint: const Color(0xFF2F4858));
      _woodBoard(c, const Rect.fromLTWH(4, 4, 92, 92));
      final ln = _stroke(const Color(0xFF3A2414), 1.6);
      for (final h in const [38.0, 26.0, 14.0]) {
        c.drawRect(Rect.fromCenter(center: const Offset(50, 50), width: h * 2, height: h * 2), ln);
      }
      c.drawLine(const Offset(50, 12), const Offset(50, 36), ln);
      c.drawLine(const Offset(50, 64), const Offset(50, 88), ln);
      c.drawLine(const Offset(12, 50), const Offset(36, 50), ln);
      c.drawLine(const Offset(64, 50), const Offset(88, 50), ln);
      c.drawLine(const Offset(12, 12), const Offset(88, 12), _stroke(gold, 4));
      for (final x in const [12.0, 50.0, 88.0]) {
        _stone(c, Offset(x, 12), 5, cream);
      }
      for (final o in const [Offset(24, 50), Offset(76, 76), Offset(50, 64), Offset(88, 50)]) {
        _stone(c, o, 5, _ink);
      }
      _stone(c, const Offset(24, 24), 5, cream);
      _stone(c, const Offset(36, 64), 5, _ink.withValues(alpha: 0.35));
    case 'mc_hnefatafl': // ortada taçlı kral, köşe kaleleri, kuşatan saldırganlar
      _bg(c, seed, tint: const Color(0xFF3E4A5C));
      const l = 11.5, cell = 11.0;
      _woodBoard(c, const Rect.fromLTWH(l - 3, l - 3, 7 * cell + 6, 7 * cell + 6));
      c.drawRect(const Rect.fromLTWH(l, l, 7 * cell, 7 * cell), _p(const Color(0xFFE6CFA3)));
      for (final (i, j) in const [(0, 0), (6, 0), (0, 6), (6, 6), (3, 3)]) {
        final r = Rect.fromLTWH(l + i * cell, l + j * cell, cell, cell);
        c.drawRect(r, _p(const Color(0xFF8A5A36)));
        c.drawLine(r.topLeft, r.bottomRight, _stroke(Colors.white38, 0.8));
        c.drawLine(r.topRight, r.bottomLeft, _stroke(Colors.white38, 0.8));
      }
      for (var i = 0; i <= 7; i++) {
        c.drawLine(Offset(l + i * cell, l), Offset(l + i * cell, l + 7 * cell), _stroke(Colors.black26, 0.6));
        c.drawLine(Offset(l, l + i * cell), Offset(l + 7 * cell, l + i * cell), _stroke(Colors.black26, 0.6));
      }
      Offset ctr(int i, int j) => Offset(l + (i + 0.5) * cell, l + (j + 0.5) * cell);
      for (final (i, j) in const [(2, 3), (4, 3), (3, 2), (3, 4)]) {
        _stone(c, ctr(i, j), 4.2, cream);
      }
      for (final (i, j) in const [(0, 2), (0, 3), (0, 4), (1, 3), (6, 2), (6, 3), (6, 4), (5, 3), (2, 0), (3, 0), (4, 0), (3, 1), (2, 6), (3, 6), (4, 6), (3, 5)]) {
        _stone(c, ctr(i, j), 4.2, _ink);
      }
      _stone(c, ctr(3, 3), 4.8, cream);
      _kcCrown(c, ctr(3, 3) + const Offset(0, -0.5), 3.2, gold);
    case 'mc_surakarta': // köşe halkalı ızgara (iç yeşil, dış kırmızı)
      _bg(c, seed, tint: const Color(0xFF34495E));
      _woodBoard(c, const Rect.fromLTWH(4, 4, 92, 92));
      const s = 26.0, step = 9.6;
      for (var k = 0; k < 6; k++) {
        c.drawLine(Offset(s + k * step, s), Offset(s + k * step, s + 5 * step), _stroke(_ink, 0.9));
        c.drawLine(Offset(s, s + k * step), Offset(s + 5 * step, s + k * step), _stroke(_ink, 0.9));
      }
      const e = s + 5 * step;
      for (final (cx, cy, st, sw) in const [
        (s, s, 0.0, -1.5),
        (e, s, 1.0, 1.5),
        (s, e, 0.0, 1.5),
        (e, e, 1.0, -1.5),
      ]) {
        for (final (r, col) in const [(step, Color(0xFF2E9E5B)), (2 * step, Color(0xFFD9483B))]) {
          c.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), st * math.pi, sw * math.pi, false, _stroke(col, 2));
        }
      }
      for (var k = 0; k < 6; k++) {
        for (final j in const [0, 1]) {
          if (k == 2 && j == 1) continue;
          _stone(c, Offset(s + k * step, s + j * step), 3.4, _red);
        }
        for (final j in const [4, 5]) {
          if (k == 4 && j == 4) continue;
          _stone(c, Offset(s + k * step, s + j * step), 3.4, const Color(0xFF3075C4));
        }
      }
    case 'mc_halma': // kare tahtada iki karşı köşe kampı ve çiviler
      _bg(c, seed, tint: const Color(0xFF4A4E69));
      const l = 8.0, cell = 10.5;
      for (var i = 0; i < 8; i++) {
        for (var j = 0; j < 8; j++) {
          final camp = i + j < 4 ? 1 : (i + j > 10 ? 2 : 0);
          c.drawRect(Rect.fromLTWH(l + i * cell, l + j * cell, cell, cell),
              _p(camp == 1 ? const Color(0xFFF4B6B0) : (camp == 2 ? const Color(0xFFB0CBEF) : ((i + j).isEven ? cream : const Color(0xFFDCCFB8)))));
          if (camp > 0 && (i + j) % 3 != 1) {
            final o = Offset(l + (i + 0.5) * cell, l + (j + 0.5) * cell);
            _stone(c, o, 3.4, camp == 1 ? _red : const Color(0xFF3075C4));
            c.drawCircle(o + const Offset(-1, -1.2), 1, _p(Colors.white70));
          }
        }
      }
      c.drawRect(const Rect.fromLTWH(l, l, 8 * cell, 8 * cell), _stroke(_wood, 2));
    case 'mc_cindama': // altı köşeli yıldız, altı renk bilye
      _bg(c, seed, tint: const Color(0xFF1B3A4B));
      Path tri(double a0) {
        final p = Path();
        for (var k = 0; k < 3; k++) {
          final a = a0 + k * 2 * math.pi / 3;
          final pt = Offset(50 + 46 * math.cos(a), 50 + 46 * math.sin(a));
          k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        return p..close();
      }
      c.drawPath(tri(-math.pi / 2), _p(const Color(0xFFE9D6B0)));
      c.drawPath(tri(math.pi / 2), _p(const Color(0xFFE9D6B0)));
      const e1 = Offset(6.2, 0), e2 = Offset(3.1, 5.37);
      for (var q = -3; q <= 3; q++) {
        for (var r = -3; r <= 3; r++) {
          if ((q + r).abs() > 3) continue;
          c.drawCircle(const Offset(50, 50) + e1 * q.toDouble() + e2 * r.toDouble(), 1.3, _p(Colors.black26));
        }
      }
      for (var k = 0; k < 6; k++) {
        final a = -math.pi / 2 + k * math.pi / 3;
        final dir = Offset(math.cos(a), math.sin(a));
        final perp = Offset(-dir.dy, dir.dx);
        for (var row = 0; row < 3; row++) {
          for (var i = 0; i <= row; i++) {
            _stone(c, const Offset(50, 50) + dir * (40 - row * 5.4) + perp * ((i - row / 2) * 6.2), 2.8, _pal[k]);
          }
        }
      }
    case 'mc_mermer': // altıgen tahtada siyah-beyaz bilyeler, itme oku, düşen bilye
      _bg(c, seed, tint: const Color(0xFF3A3A4A));
      final hex = Path();
      for (var k = 0; k < 6; k++) {
        final a = k * math.pi / 3;
        final pt = Offset(50 + 44 * math.cos(a), 50 + 44 * math.sin(a));
        k == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
      }
      hex.close();
      c.drawPath(hex.shift(const Offset(0, 2)), _p(Colors.black38));
      c.drawPath(hex, _p(const Color(0xFF9C6B3E)));
      const e1 = Offset(8.4, 0), e2 = Offset(4.2, 7.27);
      for (var q = -4; q <= 4; q++) {
        for (var r = -4; r <= 4; r++) {
          if ((q + r).abs() > 4) continue;
          final o = const Offset(50, 50) + e1 * q.toDouble() + e2 * r.toDouble();
          c.drawCircle(o, 3.4, _p(const Color(0xFF5C3A20)));
          if (r <= -3 || (r == -2 && q >= 0 && q <= 2)) _stone(c, o, 3.6, Colors.white);
          if (r >= 3 || (r == 2 && q >= -2 && q <= 0)) _stone(c, o, 3.6, _ink);
        }
      }
      _kcArrow(c, const Offset(30, 50), const Offset(60, 50), gold);
      _stone(c, const Offset(92, 12), 3.6, Colors.white);
      c.drawLine(const Offset(84, 22), const Offset(88, 17), _stroke(Colors.white54, 1.2));
    case 'mc_duvar': // duvarlı ızgara, iki piyon ve dolambaçlı yol
      _bg(c, seed, tint: const Color(0xFF3C2F2F));
      const l = 11.5, cell = 11.0;
      for (var i = 0; i < 7; i++) {
        for (var j = 0; j < 7; j++) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l + i * cell + 0.8, l + j * cell + 0.8, cell - 1.6, cell - 1.6), const Radius.circular(1.5)),
              _p(const Color(0xFF8A5A36)));
        }
      }
      for (final (x, y, w, h) in const [(11.5, 43.5, 22.0, 2.4), (44.5, 54.5, 22.0, 2.4), (65.5, 23.5, 2.4, 22.0), (33.5, 65.5, 2.4, 22.0)]) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 1.2 * (w < h ? 1 : 0), y - 1.2 * (w > h ? 1 : 0), w, h), const Radius.circular(1)),
            _p(gold));
      }
      final path = Path()
        ..moveTo(50, 83)
        ..lineTo(50, 61)
        ..lineTo(72, 61)
        ..lineTo(72, 50)
        ..lineTo(50, 50)
        ..lineTo(50, 17);
      c.drawPath(path, _stroke(Colors.white54, 1.4));
      _chessPawn(c, const Offset(50, 82), 20, Colors.white);
      _chessPawn(c, const Offset(50, 16), 20, _ink);
    case 'mc_mangalacesit': // dört sıralı uzun kuyu tahtası, değişen tohum sayıları
      _bg(c, seed, tint: const Color(0xFF6A4C2E));
      _woodBoard(c, const Rect.fromLTWH(6, 12, 88, 76));
      c.drawLine(const Offset(10, 50), const Offset(90, 50), _stroke(const Color(0xFF3A2414), 1.4));
      for (var row = 0; row < 4; row++) {
        for (var i = 0; i < 6; i++) {
          final o = Offset(17 + i * 13.2, 22 + row * 18.5 + (row >= 2 ? 1.0 : -1.0));
          c.drawCircle(o, 5.8, _p(const Color(0xFF5C3A20)));
          c.drawCircle(o, 5.8, _stroke(Colors.black26, 0.6));
          final n = (i * 7 + row * 3) % 5;
          for (var s = 0; s < n; s++) {
            final a = s * 2 * math.pi / math.max(n, 1) + row;
            _stone(c, o + Offset(math.cos(a) * 2.6, math.sin(a) * 2.6), 1.7, _pal[(s + i + row) % 8]);
          }
        }
      }
    // ---- Taş dizme ----------------------------------------------------------
    case 'mc_altilibag': // gri tahtada altılı yatay sıra, yeni konan iki taş işaretli
      _bg(c, seed, tint: const Color(0xFF37474F));
      _mcGridBoard(c, const Rect.fromLTWH(10, 10, 80, 80), 9, const Color(0xFFCFD8DC));
      Offset at(int i, int j) => Offset(10 + i * 10.0, 10 + j * 10.0);
      c.drawLine(at(1, 4), at(6, 4), _stroke(gold, 4));
      for (var i = 1; i <= 6; i++) {
        _stone(c, at(i, 4), 4, _ink);
      }
      for (final i in const [5, 6]) {
        c.drawCircle(at(i, 4), 1.6, _p(gold));
      }
      for (final (i, j) in const [(2, 2), (3, 6), (5, 3), (7, 5), (4, 7), (6, 2), (2, 5)]) {
        _stone(c, at(i, j), 4, Colors.white);
      }
    case 'mc_besleme': // ahşap tahtada çapraz beşli, kırmızı çizgi
      _bg(c, seed, tint: const Color(0xFF5D4037));
      _mcGridBoard(c, const Rect.fromLTWH(10, 10, 80, 80), 8, boardTan);
      Offset at(int i, int j) => Offset(10 + i * 10.0, 10 + j * 10.0);
      c.drawLine(at(2, 7), at(6, 3), _stroke(_red, 3));
      for (var k = 0; k < 5; k++) {
        _stone(c, at(2 + k, 7 - k), 4.2, _ink);
      }
      for (final (i, j) in const [(3, 3), (4, 4), (5, 2), (6, 6), (2, 4), (7, 4)]) {
        _stone(c, at(i, j), 4.2, Colors.white);
      }
    case 'mc_kapmali': // çift kapma: arada kalan iki beyaz, kenarda kazanılmış çiftler
      _bg(c, seed, tint: const Color(0xFF2F5233));
      _mcGridBoard(c, const Rect.fromLTWH(8, 14, 72, 72), 8, const Color(0xFFD6E5C3));
      Offset at(int i, int j) => Offset(8 + i * 9.0, 14 + j * 9.0);
      c.drawCircle(at(4, 4), 1.6, _p(_ink));
      _stone(c, at(1, 3), 3.8, _ink);
      _stone(c, at(4, 3), 3.8, _ink);
      for (final i in const [2, 3]) {
        _stone(c, at(i, 3), 3.8, Colors.white.withValues(alpha: 0.45));
        c.drawLine(at(i, 3) + const Offset(-3, -3), at(i, 3) + const Offset(3, 3), _stroke(_red, 1.8));
        c.drawLine(at(i, 3) + const Offset(3, -3), at(i, 3) + const Offset(-3, 3), _stroke(_red, 1.8));
      }
      for (final (i, j, w) in const [(5, 5, true), (6, 5, false), (3, 6, true), (2, 5, false), (5, 2, true)]) {
        _stone(c, at(i, j), 3.8, w ? Colors.white : _ink);
      }
      final tray = RRect.fromRectAndRadius(const Rect.fromLTWH(84, 14, 12, 72), const Radius.circular(6));
      c.drawRRect(tray, _p(Colors.black26));
      for (var k = 0; k < 6; k++) {
        _stone(c, Offset(90, 21 + k * 10.0), 3.4, Colors.white);
      }
    case 'mc_hex': // eşkenar dörtgen altıgen tahta, kırmızı/mavi kenarlar, kırmızı yol
      _bg(c, seed, tint: const Color(0xFF2B2D42));
      const r = 4.4, w = 7.62, x0 = 16.0, y0 = 30.0;
      Offset hc(int col, int row) => Offset(x0 + col * w + row * w / 2, y0 + row * 1.5 * r);
      const red = Color(0xFFE63946), blu = Color(0xFF457B9D);
      c.drawLine(hc(0, 0) + const Offset(0, -7), hc(6, 0) + const Offset(0, -7), _stroke(red, 3));
      c.drawLine(hc(0, 6) + const Offset(0, 7), hc(6, 6) + const Offset(0, 7), _stroke(red, 3));
      c.drawLine(hc(0, 0) + const Offset(-7, 0), hc(0, 6) + const Offset(-7, 0), _stroke(blu, 3));
      c.drawLine(hc(6, 0) + const Offset(7, 0), hc(6, 6) + const Offset(7, 0), _stroke(blu, 3));
      final path = <(int, int)>{(3, 0), (3, 1), (2, 2), (2, 3), (3, 3), (2, 4), (1, 5), (1, 6)};
      final blues = <(int, int)>{(0, 2), (1, 2), (4, 1), (5, 3), (4, 4), (3, 5), (0, 5)};
      for (var row = 0; row < 7; row++) {
        for (var col = 0; col < 7; col++) {
          final o = hc(col, row);
          final fill = path.contains((col, row)) ? red : (blues.contains((col, row)) ? blu : const Color(0xFFF1E9DA));
          c.drawPath(_mcHex(o, r - 0.3), _p(fill));
          c.drawPath(_mcHex(o, r - 0.3), _stroke(Colors.black26, 0.5));
        }
      }
    case 'mc_havannah': // altıgen biçimli tahta, bir hücreyi saran halka
      _bg(c, seed, tint: const Color(0xFF264653));
      const r = 4.6;
      final w = math.sqrt(3) * r;
      final whites = <(int, int)>{(2, -3), (-3, 2), (3, 0), (-1, 3), (0, -3), (-4, 1), (1, 0)};
      for (var q = -4; q <= 4; q++) {
        for (var s = -4; s <= 4; s++) {
          if ((q + s).abs() > 4) continue;
          final o = Offset(50 + (q + s / 2) * w, 50 + s * 1.5 * r);
          final d = math.max(q.abs(), math.max(s.abs(), (q + s).abs()));
          final ring = d == 1 && !(q == 1 && s == 0);
          final white = whites.contains((q, s));
          final fill = d == 0 ? gold.withValues(alpha: 0.6) : (ring ? _ink : (white ? Colors.white : const Color(0xFFE9D8A6)));
          c.drawPath(_mcHex(o, r - 0.25), _p(fill));
          c.drawPath(_mcHex(o, r - 0.25), _stroke(Colors.black26, 0.5));
        }
      }
    case 'mc_blokus': // köşeden değen dört renk çoklu kare parçalar
      _bg(c, seed, tint: const Color(0xFF3A506B));
      const b = Rect.fromLTWH(10, 10, 80, 80);
      c.drawRRect(RRect.fromRectAndRadius(b.inflate(3), const Radius.circular(4)), _p(const Color(0xFFE5E7EB)));
      for (var i = 0; i <= 10; i++) {
        c.drawLine(Offset(b.left + i * 8, b.top), Offset(b.left + i * 8, b.bottom), _stroke(Colors.black12, 0.6));
        c.drawLine(Offset(b.left, b.top + i * 8), Offset(b.right, b.top + i * 8), _stroke(Colors.black12, 0.6));
      }
      const pieces = [
        (Color(0xFF3075C4), [(0, 0), (1, 0), (1, 1), (2, 1), (3, 2), (3, 3), (4, 3)]),
        (Color(0xFFF2A93B), [(9, 0), (9, 1), (8, 1), (8, 2), (8, 3), (7, 4), (6, 4), (6, 5)]),
        (Color(0xFFE2574C), [(9, 9), (8, 9), (7, 9), (7, 8), (6, 7), (5, 7), (5, 6)]),
        (Color(0xFF3BA776), [(0, 9), (0, 8), (1, 8), (0, 7), (2, 6), (2, 5), (3, 5)]),
      ];
      for (final (col, cells) in pieces) {
        for (final (i, j) in cells) {
          final rr = RRect.fromRectAndRadius(Rect.fromLTWH(b.left + i * 8 + 0.5, b.top + j * 8 + 0.5, 7, 7), const Radius.circular(1.5));
          c.drawRRect(rr, _p(col));
          c.drawRRect(rr.deflate(1.6), _stroke(Colors.white.withValues(alpha: 0.35), 0.8));
        }
      }
    // ---- Zar ve yarış -------------------------------------------------------
    case 'mc_tavlacesit': // yakın plan çeyrek tahta, yüksek yığınlar, kapılan pul, katlama küpü
      _bg(c, seed, tint: const Color(0xFF1D3557));
      const b = Rect.fromLTWH(8, 10, 70, 80);
      _woodBoard(c, b.inflate(3));
      c.drawRect(b, _p(const Color(0xFF2A6F6B)));
      for (var i = 0; i < 5; i++) {
        final x0 = b.left + i * 14.0;
        c.drawPath(Path()..addPolygon([Offset(x0, b.top), Offset(x0 + 14, b.top), Offset(x0 + 7, b.top + 34)], true),
            _p(i.isEven ? const Color(0xFFF1E3C6) : const Color(0xFFC1502E)));
        c.drawPath(Path()..addPolygon([Offset(x0, b.bottom), Offset(x0 + 14, b.bottom), Offset(x0 + 7, b.bottom - 34)], true),
            _p(i.isOdd ? const Color(0xFFF1E3C6) : const Color(0xFFC1502E)));
      }
      for (var k = 0; k < 5; k++) {
        _stone(c, Offset(b.left + 7, b.top + 5 + k * 6.5), 3.6, Colors.white);
      }
      for (var k = 0; k < 4; k++) {
        _stone(c, Offset(b.left + 35, b.bottom - 5 - k * 6.5), 3.6, _ink);
      }
      _stone(c, Offset(b.left + 63, b.top + 5), 3.6, _ink);
      _stone(c, Offset(b.left + 63, b.top + 9), 3.6, Colors.white);
      final cube = RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(88, 50), width: 15, height: 15), const Radius.circular(3));
      _shadowRRect(c, cube);
      c.drawRRect(cube, _p(Colors.white));
      _text(c, '2', const Offset(88, 50), 10, _ink);
    case 'mc_kizma': // haç biçimli parkur, dört renkli ev köşeleri, renkli piyonlar
      _bg(c, seed, tint: const Color(0xFF3D405B));
      const l = 6.0, cell = 8.0;
      c.drawRect(const Rect.fromLTWH(l, l, 11 * cell, 11 * cell), _p(cream));
      const homes = [(0, 0, 0), (7, 0, 1), (7, 7, 3), (0, 7, 2)];
      for (final (x, y, k) in homes) {
        final r = Rect.fromLTWH(l + x * cell, l + y * cell, 4 * cell, 4 * cell);
        c.drawRect(r, _p(_pal[k]));
        for (final (dx, dy) in const [(1.2, 1.2), (2.8, 1.2), (1.2, 2.8), (2.8, 2.8)]) {
          c.drawCircle(Offset(r.left + dx * cell, r.top + dy * cell), 3.2, _p(Colors.white));
        }
      }
      for (var i = 0; i < 11; i++) {
        for (var j = 0; j < 11; j++) {
          final onTrack = (i >= 4 && i <= 6) || (j >= 4 && j <= 6);
          if (!onTrack || (i >= 4 && i <= 6 && j >= 4 && j <= 6)) continue;
          c.drawRect(Rect.fromLTWH(l + i * cell, l + j * cell, cell, cell), _stroke(Colors.black26, 0.5));
        }
      }
      for (var k = 1; k <= 4; k++) {
        c.drawRect(Rect.fromLTWH(l + 5 * cell, l + k * cell, cell, cell), _p(_pal[0].withValues(alpha: 0.6)));
        c.drawRect(Rect.fromLTWH(l + (10 - k) * cell, l + 5 * cell, cell, cell), _p(_pal[1].withValues(alpha: 0.6)));
        c.drawRect(Rect.fromLTWH(l + 5 * cell, l + (10 - k) * cell, cell, cell), _p(_pal[3].withValues(alpha: 0.6)));
        c.drawRect(Rect.fromLTWH(l + k * cell, l + 5 * cell, cell, cell), _p(_pal[2].withValues(alpha: 0.6)));
      }
      const m = Offset(l + 5.5 * cell, l + 5.5 * cell);
      const h = 1.5 * cell;
      for (final (a, b2, k) in const [
        (Offset(-h, -h), Offset(h, -h), 0),
        (Offset(h, -h), Offset(h, h), 1),
        (Offset(h, h), Offset(-h, h), 3),
        (Offset(-h, h), Offset(-h, -h), 2),
      ]) {
        c.drawPath(Path()..addPolygon([m, m + a, m + b2], true), _p(_pal[k]));
      }
      _stone(c, Offset(l + 4.5 * cell, l + 1.5 * cell), 3.2, _pal[0]);
      _stone(c, Offset(l + 9.5 * cell, l + 4.5 * cell), 3.2, _pal[1]);
      _stone(c, Offset(l + 6.5 * cell, l + 8.5 * cell), 3.2, _pal[3]);
    case 'mc_yilan': // numaralı kareler, merdiven ve kıvrık yılan
      _bg(c, seed, tint: const Color(0xFF386641));
      const l = 10.0, cell = 16.0;
      for (var j = 0; j < 5; j++) {
        for (var i = 0; i < 5; i++) {
          final n = (4 - j) * 5 + ((4 - j).isEven ? i + 1 : 5 - i);
          c.drawRect(Rect.fromLTWH(l + i * cell, l + j * cell, cell, cell),
              _p((i + j).isEven ? const Color(0xFFF7E7C6) : const Color(0xFFBFD8B8)));
          _text(c, '$n', Offset(l + i * cell + 4.5, l + j * cell + 4), 4.4, _ink.withValues(alpha: 0.7), w: FontWeight.w600);
        }
      }
      final rail = _stroke(_wood, 2.2);
      c.drawLine(const Offset(20, 84), const Offset(36, 24), rail);
      c.drawLine(const Offset(30, 86), const Offset(46, 26), rail);
      for (var k = 1; k < 6; k++) {
        final t = k / 6;
        c.drawLine(Offset.lerp(const Offset(20, 84), const Offset(36, 24), t)!, Offset.lerp(const Offset(30, 86), const Offset(46, 26), t)!,
            _stroke(_woodLight, 1.6));
      }
      final snake = Path()
        ..moveTo(76, 20)
        ..cubicTo(92, 34, 56, 44, 70, 58)
        ..cubicTo(82, 70, 58, 78, 64, 88);
      c.drawPath(snake, _stroke(const Color(0xFF2E9E5B), 5.5));
      c.drawPath(snake, _stroke(const Color(0xFFB7E4A5), 1.2));
      c.drawOval(Rect.fromCenter(center: const Offset(75, 19), width: 10, height: 7), _p(const Color(0xFF2E9E5B)));
      c.drawCircle(const Offset(73, 18), 1, _p(_ink));
      c.drawCircle(const Offset(77, 18), 1, _p(_ink));
    case 'mc_zarbesli': // puan kâğıdı ve beşi de aynı gelen beş zar
      _bg(c, seed, tint: const Color(0xFF8D2C24));
      final sheet = RRect.fromRectAndRadius(const Rect.fromLTWH(18, 8, 64, 50), const Radius.circular(4));
      _shadowRRect(c, sheet);
      c.drawRRect(sheet, _p(_ivory));
      for (var k = 0; k < 5; k++) {
        final y = 16 + k * 8.0;
        c.drawLine(Offset(22, y + 4), Offset(78, y + 4), _stroke(Colors.black12, 0.8));
        c.drawRect(Rect.fromLTWH(24, y - 2, 5, 5), _p(_pal[k % 4].withValues(alpha: 0.7)));
        c.drawLine(Offset(32, y), Offset(32 + 14 + k * 4.0, y), _stroke(Colors.black26, 1.4));
      }
      _kcBadge(c, const Offset(72, 24), 8, '50');
      for (var i = 0; i < 5; i++) {
        _die(c, Offset(14 + i * 18.0, 76 + (i.isEven ? 0 : 3.0)), 15, 5, (i - 2) * 0.12);
      }
    case 'mc_farkle': // dağınık altı zar, 1 ve 5'ler altın halkalı
      _bg(c, seed, tint: const Color(0xFF1F6B4A));
      for (final (x, y, n, a) in const [(24.0, 26.0, 1, -0.2), (56.0, 22.0, 3, 0.3), (80.0, 40.0, 5, -0.1), (32.0, 60.0, 5, 0.25), (62.0, 62.0, 2, -0.35), (44.0, 84.0, 6, 0.1)]) {
        if (n == 1 || n == 5) c.drawCircle(Offset(x, y), 14, _stroke(gold, 2.4));
        _die(c, Offset(x, y), 17, n, a);
      }
      _kcBadge(c, const Offset(82, 82), 10, '200');
    case 'mc_yalanci': // ters kupalar, altında saklı zarlar, "3 x beş" balonu
      _bg(c, seed, tint: const Color(0xFF4A2C2A));
      const leather = Color(0xFF7B4A2A);
      for (var k = 0; k < 3; k++) {
        _die(c, Offset(60 + k * 10.0, 84), 9, const [5, 2, 5][k], 0.1 * k);
      }
      void cup(Offset o, double a) {
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(a);
        final p = Path()..addPolygon(const [Offset(-13, 14), Offset(13, 14), Offset(9, -14), Offset(-9, -14)], true);
        c.drawPath(p.shift(const Offset(0, 2)), _p(Colors.black38));
        c.drawPath(p, _p(leather));
        c.drawRect(const Rect.fromLTWH(-13, 10, 26, 4), _p(const Color(0xFF5A321A)));
        c.drawLine(const Offset(-6, -10), const Offset(-8, 8), _stroke(Colors.white24, 1.4));
        c.restore();
      }
      cup(const Offset(26, 70), 0);
      cup(const Offset(70, 62), -0.35);
      final bubble = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 10, 50, 28), const Radius.circular(12));
      c.drawRRect(bubble, _p(Colors.white));
      c.drawPath(Path()..addPolygon(const [Offset(22, 37), Offset(32, 37), Offset(24, 46)], true), _p(Colors.white));
      _text(c, '3 ×', const Offset(26, 24), 10, _ink);
      _die(c, const Offset(46, 24), 14, 5, 0);
    case 'mc_ur': // ayrık üç sıralı tahta, rozet kareler, dört yüzlü zarlar
      _bg(c, seed, tint: const Color(0xFF5E4B3C));
      const l = 6.0, cell = 11.0, t = 22.0;
      for (var j = 0; j < 3; j++) {
        for (var i = 0; i < 8; i++) {
          if (j != 1 && (i == 4 || i == 5)) continue;
          final r = Rect.fromLTWH(l + i * cell, t + j * cell, cell, cell);
          c.drawRect(r.deflate(0.4), _p(const Color(0xFF27408B)));
          final rosette = (j != 1 && (i == 0 || i == 6)) || (j == 1 && i == 3);
          if (rosette) {
            _kcStar(c, r.center, 4.6, 8, Colors.white, inner: 2.4);
            c.drawCircle(r.center, 1.4, _p(_red));
          } else if ((i + j).isEven) {
            for (final (dx, dy) in const [(-2.5, -2.5), (2.5, -2.5), (0.0, 0.0), (-2.5, 2.5), (2.5, 2.5)]) {
              c.drawCircle(r.center + Offset(dx, dy), 0.9, _p(Colors.white70));
            }
          } else {
            c.drawRect(r.deflate(3), _stroke(Colors.white54, 0.8));
          }
        }
      }
      _stone(c, Offset(l + 1.5 * cell, t + 0.5 * cell), 3.8, Colors.white);
      _stone(c, Offset(l + 4.5 * cell, t + 1.5 * cell), 3.8, _ink);
      _stone(c, Offset(l + 2.5 * cell, t + 2.5 * cell), 3.8, _ink);
      for (var k = 0; k < 4; k++) {
        final o = Offset(22 + k * 18.0, 80);
        c.drawPath(Path()..addPolygon([o + const Offset(0, -8), o + const Offset(8, 6), o + const Offset(-8, 6)], true), _p(const Color(0xFFE6CFA3)));
        c.drawLine(o + const Offset(0, -8), o + const Offset(0, 6), _stroke(Colors.black26, 0.8));
        if (k != 2) c.drawCircle(o + const Offset(0, -6), 1.4, _p(k.isEven ? Colors.white : _ink));
      }
    case 'mc_senet': // 3x10 uzun tahta, koni ve makara taşlar, dört atış çubuğu
      _bg(c, seed, tint: const Color(0xFFB08850));
      const l = 5.0, cell = 9.0, t = 22.0;
      _woodBoard(c, const Rect.fromLTWH(l - 2, t - 2, 10 * cell + 4, 3 * cell + 4));
      for (var j = 0; j < 3; j++) {
        for (var i = 0; i < 10; i++) {
          final r = Rect.fromLTWH(l + i * cell, t + j * cell, cell, cell);
          c.drawRect(r.deflate(0.5), _p(const Color(0xFFF1DFB8)));
        }
      }
      final mk = _stroke(const Color(0xFF2B6CB0), 0.9);
      final sq = Rect.fromLTWH(l + 6 * cell, t + 2 * cell, cell, cell);
      for (var k = 0; k < 2; k++) {
        c.drawPath(
            Path()
              ..moveTo(sq.left + 1, sq.top + 3 + k * 3)
              ..quadraticBezierTo(sq.left + 3, sq.top + 1 + k * 3, sq.center.dx, sq.top + 3 + k * 3)
              ..quadraticBezierTo(sq.right - 3, sq.top + 5 + k * 3, sq.right - 1, sq.top + 3 + k * 3),
            mk);
      }
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(l + 7 * cell + 2.5 + k * 2, t + 2 * cell + 2), Offset(l + 7 * cell + 2.5 + k * 2, t + 3 * cell - 2), mk);
      }
      c.drawCircle(Rect.fromLTWH(l + 5 * cell, t + 2 * cell, cell, cell).center, 2.6, mk);
      for (final i in const [1, 4, 8]) {
        final o = Offset(l + (i + 0.5) * cell, t + 0.5 * cell);
        c.drawPath(Path()..addPolygon([o + const Offset(0, -4), o + const Offset(3.4, 3.6), o + const Offset(-3.4, 3.6)], true), _p(_ink));
      }
      for (final i in const [2, 6, 9]) {
        final o = Offset(l + (i + 0.5) * cell, t + 1.5 * cell);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 6, height: 7), const Radius.circular(1.5)), _p(Colors.white));
        c.drawRect(Rect.fromCenter(center: o, width: 6, height: 1.6), _p(const Color(0xFFB0A080)));
      }
      for (var k = 0; k < 4; k++) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(18 + k * 17.0, 60, 8, 32), const Radius.circular(3.5));
        _shadowRRect(c, r, dy: 1.2);
        c.drawRRect(r, _p(k == 1 ? const Color(0xFF5C3A20) : const Color(0xFFF1DFB8)));
      }
    case 'mc_yut': // çaprazlı yut tahtası ve dört yarım yuvarlak çubuk
      _bg(c, seed, tint: const Color(0xFF7D3C3C));
      const b = Rect.fromLTWH(18, 8, 64, 64);
      c.drawRRect(RRect.fromRectAndRadius(b.inflate(6), const Radius.circular(6)), _p(const Color(0xFFF2E3C2)));
      final ln = _stroke(const Color(0xFF5C3A20), 1.2);
      c.drawRect(b, ln);
      c.drawLine(b.topLeft, b.bottomRight, ln);
      c.drawLine(b.topRight, b.bottomLeft, ln);
      for (var k = 0; k <= 5; k++) {
        final t = k / 5;
        for (final o in [Offset.lerp(b.topLeft, b.topRight, t)!, Offset.lerp(b.bottomLeft, b.bottomRight, t)!,
            Offset.lerp(b.topLeft, b.bottomLeft, t)!, Offset.lerp(b.topRight, b.bottomRight, t)!]) {
          c.drawCircle(o, k == 0 || k == 5 ? 3.6 : 2.2, _p(const Color(0xFF5C3A20)));
        }
      }
      for (final t in const [1 / 6, 2 / 6, 4 / 6, 5 / 6]) {
        c.drawCircle(Offset.lerp(b.topLeft, b.bottomRight, t)!, 2.2, _p(const Color(0xFF5C3A20)));
        c.drawCircle(Offset.lerp(b.topRight, b.bottomLeft, t)!, 2.2, _p(const Color(0xFF5C3A20)));
      }
      c.drawCircle(b.center, 3.8, _p(_red));
      _stone(c, Offset.lerp(b.topRight, b.bottomRight, 0.4)!, 3.6, const Color(0xFF3075C4));
      _stone(c, Offset.lerp(b.topLeft, b.bottomRight, 1 / 3)!, 3.6, _pal[2]);
      for (var k = 0; k < 4; k++) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(14 + k * 19.0, 82, 16, 7), const Radius.circular(3.5));
        _shadowRRect(c, r, dy: 1.2);
        c.drawRRect(r, _p(k == 3 ? const Color(0xFFC08A5A) : const Color(0xFFF4E4C1)));
        if (k == 3) {
          c.drawLine(r.outerRect.center + const Offset(-2, -2), r.outerRect.center + const Offset(2, 2), _stroke(_ink, 0.8));
          c.drawLine(r.outerRect.center + const Offset(2, -2), r.outerRect.center + const Offset(-2, 2), _stroke(_ink, 0.8));
        }
      }
    case 'mc_emlak': // kare mülk parkuru, renk şeritleri, evler, banknot ve zar
      _bg(c, seed, tint: const Color(0xFF2A9D8F));
      const b = Rect.fromLTWH(8, 8, 84, 84);
      c.drawRect(b, _p(const Color(0xFFE8F1E4)));
      const cw = 11.2, corner = 14.0;
      final edge = _stroke(Colors.black26, 0.6);
      for (var k = 0; k < 5; k++) {
        final col = _pal[k % 2 + (k ~/ 2) * 2 % 8];
        final top = Rect.fromLTWH(b.left + corner + k * cw, b.top, cw, corner);
        final bot = Rect.fromLTWH(b.left + corner + k * cw, b.bottom - corner, cw, corner);
        final lft = Rect.fromLTWH(b.left, b.top + corner + k * cw, corner, cw);
        final rgt = Rect.fromLTWH(b.right - corner, b.top + corner + k * cw, corner, cw);
        for (final r in [top, bot, lft, rgt]) {
          c.drawRect(r, edge);
        }
        c.drawRect(Rect.fromLTWH(top.left, top.bottom - 4, cw, 4), _p(col));
        c.drawRect(Rect.fromLTWH(bot.left, bot.top, cw, 4), _p(_pal[(k + 4) % 8]));
        c.drawRect(Rect.fromLTWH(lft.right - 4, lft.top, 4, cw), _p(_pal[(k + 2) % 8]));
        c.drawRect(Rect.fromLTWH(rgt.left, rgt.top, 4, cw), _p(_pal[(k + 6) % 8]));
      }
      c.drawRect(b, _stroke(_ink, 1.2));
      void house(Offset o, Color col, double s) {
        c.drawPath(Path()..addPolygon([o + Offset(-s, 0), o + Offset(-s, -s), o + Offset(0, -s * 1.8), o + Offset(s, -s), o + Offset(s, 0)], true),
            _p(col));
      }
      house(const Offset(40, 50), const Color(0xFF3BA776), 4);
      house(const Offset(50, 50), const Color(0xFF3BA776), 4);
      house(const Offset(60, 50), _red, 5);
      final note = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 56, 26, 13), const Radius.circular(2));
      c.drawRRect(note, _p(const Color(0xFFB7E4A5)));
      c.drawCircle(note.center, 3.6, _stroke(const Color(0xFF2E7D4F), 1));
      _die(c, const Offset(66, 64), 12, 4, 0.25);
    case 'mc_yerlesim': // denizde kaynak altıgenleri, sayı pulları, ev ve yol
      _bg(c, seed, tint: const Color(0xFF1D6FA3));
      const r = 15.0;
      final w = math.sqrt(3) * r;
      const res = [Color(0xFF2E7D32), Color(0xFFF2C14E), Color(0xFFC1502E), Color(0xFF9CCC65), Color(0xFF9AA3AF), Color(0xFFF2C14E), Color(0xFF2E7D32)];
      const axial = [(0, 0), (1, 0), (0, 1), (-1, 1), (-1, 0), (0, -1), (1, -1)];
      const nums = ['8', '5', '6', '9', '4', '10', '3'];
      for (var k = 0; k < 7; k++) {
        final (q, s) = axial[k];
        final o = Offset(50 + (q + s / 2) * w, 52 + s * 1.5 * r);
        c.drawPath(_mcHex(o, r - 0.6), _p(res[k]));
        c.drawPath(_mcHex(o, r - 0.6), _stroke(const Color(0xFFF4E4C1), 1.4));
        c.drawCircle(o, 5, _p(cream));
        _text(c, nums[k], o, 5.4, nums[k] == '6' || nums[k] == '8' ? _red : _ink);
      }
      final v = Offset(50 + w / 2, 52 - r / 2);
      c.drawLine(v, v + Offset(w / 2, -r / 2), _stroke(_red, 3));
      c.drawPath(Path()..addPolygon([v + const Offset(-3.4, 3), v + const Offset(-3.4, -2), v + const Offset(0, -5), v + const Offset(3.4, -2), v + const Offset(3.4, 3)], true),
          _p(_red));
    // ---- Taş oyunları -------------------------------------------------------
    case 'mc_101okey': // açılmış perler, ıstaka ve "101" rozeti
      _bg(c, seed, tint: const Color(0xFF14703A));
      for (final (row, nums, cols) in const [
        (0, ['10', '11', '12', '13'], [0, 0, 0, 0]),
        (1, ['7', '7', '7'], [1, 2, 3]),
      ]) {
        for (var i = 0; i < nums.length; i++) {
          final r = Rect.fromLTWH(10 + i * 11.0 + row * 8, 12 + row * 20.0, 10, 16);
          _tile(c, r, rad: 2);
          final col = [_red, _ink, const Color(0xFF2B6CB0), const Color(0xFFD69E2E)][cols[i]];
          _text(c, nums[i], r.center - const Offset(0, 2), 6, col);
        }
      }
      _kcBadge(c, const Offset(80, 24), 13, '101');
      final rack = const Rect.fromLTWH(6, 66, 88, 26);
      _woodBoard(c, rack);
      for (var i = 0; i < 7; i++) {
        final r = Rect.fromLTWH(9 + i * 12.0, 52, 11, 18);
        _tile(c, r, rad: 2);
        final col = [_red, _ink, const Color(0xFF2B6CB0), const Color(0xFFD69E2E)][(i * 3) % 4];
        _text(c, '${(i * 5) % 13 + 1}', r.center - const Offset(0, 2), 6.4, col);
        c.drawCircle(r.center + const Offset(0, 5), 1, _p(col));
      }
    case 'mc_okeycesit': // üstten masa: dört yanda ıstaka, ortada deste ve gösterge taşı
      _bg(c, seed, tint: const Color(0xFF0A3D22));
      final table = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 10, 80, 80), const Radius.circular(10));
      _shadowRRect(c, table);
      c.drawRRect(table, _p(const Color(0xFF1F7A45)));
      c.drawRRect(table.deflate(3), _stroke(Colors.white24, 1));
      for (var side = 0; side < 4; side++) {
        c.save();
        c.translate(50, 50);
        c.rotate(side * math.pi / 2);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-28, 28, 56, 8), const Radius.circular(2)), _p(_wood));
        for (var i = 0; i < 7; i++) {
          c.drawRect(Rect.fromLTWH(-26 + i * 7.6, 24, 6.4, 5), _p(_ivory));
          c.drawCircle(Offset(-22.8 + i * 7.6, 26.5), 1, _p(_pal[(i + side) % 4]));
        }
        c.restore();
      }
      for (var k = 0; k < 4; k++) {
        _tile(c, Rect.fromLTWH(36 - k * 0.6, 40 - k * 1.2, 12, 18), rad: 2);
      }
      _tile(c, const Rect.fromLTWH(54, 41, 12, 18), rad: 2);
      _text(c, '9', const Offset(60, 47), 7, _red);
      _kcStar(c, const Offset(60, 54), 2.6, 5, _red, inner: 1.2);
    case 'mc_mahjongcesit': // üstten bakış: kare taş duvarı ve ortada zarlar
      _bg(c, seed, tint: const Color(0xFF1F4F4A));
      for (var side = 0; side < 4; side++) {
        c.save();
        c.translate(50, 50);
        c.rotate(side * math.pi / 2);
        for (var i = 0; i < 7; i++) {
          if (side == 1 && i == 3) continue;
          final r = Rect.fromLTWH(-31 + i * 8.6, -38, 8, 10);
          _tile(c, r, face: i.isEven ? _ivory : const Color(0xFF4E9F7A), rad: 1.5);
        }
        c.restore();
      }
      _die(c, const Offset(43, 47), 12, 3, -0.2);
      _die(c, const Offset(57, 55), 12, 6, 0.25);
      for (var i = 0; i < 3; i++) {
        final r = Rect.fromLTWH(38 + i * 8.5, 68, 8, 11);
        _tile(c, r, rad: 1.5);
        c.drawCircle(r.center, 2.4, _stroke(_pal[i], 1.2));
      }
    default:
      return false;
  }
  return true;
}

/// Izgara çizgili tahta (beşleme türleri için).
void _mcGridBoard(Canvas c, Rect b, int n, Color face) {
  c.drawRRect(RRect.fromRectAndRadius(b.inflate(5), const Radius.circular(4)), _p(face));
  final step = b.width / n;
  for (var i = 0; i <= n; i++) {
    c.drawLine(Offset(b.left + i * step, b.top), Offset(b.left + i * step, b.bottom), _stroke(Colors.black38, 0.7));
    c.drawLine(Offset(b.left, b.top + i * step), Offset(b.right, b.top + i * step), _stroke(Colors.black38, 0.7));
  }
}

/// Sivri tepeli altıgen yolu.
Path _mcHex(Offset o, double r) {
  final p = Path();
  for (var k = 0; k < 6; k++) {
    final a = -math.pi / 2 + k * math.pi / 3;
    final pt = Offset(o.dx + r * math.cos(a), o.dy + r * math.sin(a));
    k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// Yuvarlak, halkalı Çin satrancı taşı.
void _mcDisc(Canvas c, Offset o, double r, Color ring) {
  c.drawCircle(o + const Offset(0, 1), r, _p(Colors.black38));
  c.drawCircle(o, r, _p(const Color(0xFFF6E7C8)));
  c.drawCircle(o, r * 0.72, _stroke(ring, r * 0.16));
  c.drawCircle(o, r * 0.26, _p(ring));
}

/// Sekizgen Kore satrancı taşı.
void _mcOcta(Canvas c, Offset o, double r, Color ink) {
  final p = Path();
  for (var k = 0; k < 8; k++) {
    final a = math.pi / 8 + k * math.pi / 4;
    final pt = Offset(o.dx + r * math.cos(a), o.dy + r * math.sin(a));
    k == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  p.close();
  c.drawPath(p.shift(const Offset(0, 1)), _p(Colors.black38));
  c.drawPath(p, _p(const Color(0xFFF6EBD3)));
  c.drawPath(p, _stroke(ink, r * 0.14));
  c.drawCircle(o, r * 0.3, _p(ink));
}

/// Beşgen Japon satrancı taşı; [up] karşı tarafa doğru.
void _mcWedge(Canvas c, Offset o, double s, bool up) {
  c.save();
  c.translate(o.dx, o.dy);
  if (!up) c.rotate(math.pi);
  final p = Path()
    ..addPolygon([Offset(0, -s), Offset(s * 0.62, -s * 0.5), Offset(s * 0.78, s), Offset(-s * 0.78, s), Offset(-s * 0.62, -s * 0.5)], true);
  c.drawPath(p.shift(const Offset(0, 0.8)), _p(Colors.black26));
  c.drawPath(p, _p(const Color(0xFFE8C07D)));
  c.drawPath(p, _stroke(const Color(0xFF8A5A36), 0.6));
  c.drawLine(Offset(0, -s * 0.3), Offset(0, s * 0.6), _stroke(_ink, 0.8));
  c.drawLine(Offset(-s * 0.3, s * 0.15), Offset(s * 0.3, s * 0.15), _stroke(_ink, 0.8));
  c.restore();
}
