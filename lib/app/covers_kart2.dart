part of 'covers.dart';

/// İkinci turda eklenen kâğıt ve masa oyunlarının özgün kapakları:
/// tarneebc, trixc, balootc, hokmc, twentyninec (kâğıt), carromc, pacisic (masa).
/// Kâğıt kapakları çuha zemini ve ince altın çizgilerle, masa kapakları ahşap
/// tahta üslubuyla çizilir (vektör, dış görsel yok). Döndürür: çizildiyse true.
bool _paintKart2Cover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const gold = Color(0xFFE9C46A);
  const teamA = Color(0xFFE76F51);
  const teamB = Color(0xFF4A90C2);
  RRect box(Offset o, double w, double h, [double r = 4]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));

  // Masa çevresinde dört oyuncu yeri; karşılıklılar aynı takım.
  void seats() {
    for (var k = 0; k < 4; k++) {
      final a = -math.pi / 2 + k * math.pi / 2;
      final o = Offset(50 + 39 * math.cos(a), 50 + 39 * math.sin(a));
      c.drawCircle(o + const Offset(0, 1.2), 6.5, _p(Colors.black26));
      c.drawCircle(o, 6.5, _p(k.isEven ? teamA : teamB));
      c.drawCircle(o, 6.5, _stroke(Colors.white60, 1));
    }
  }

  // Altın halka içinde rozet (teklif, sayı).
  void badge(Offset o, double r, String s, {Color fill = gold}) {
    c.drawCircle(o + const Offset(0, 1.4), r, _p(Colors.black26));
    c.drawCircle(o, r, _p(fill));
    c.drawCircle(o, r - 1.8, _stroke(Colors.white70, 0.9));
    _text(c, s, o, r * 1.05, _ink);
  }

  // Basit taç.
  void crown(Offset o, double s, Color col) {
    final p = Path()
      ..moveTo(o.dx - s, o.dy + s * 0.5)
      ..lineTo(o.dx - s, o.dy - s * 0.4)
      ..lineTo(o.dx - s * 0.5, o.dy)
      ..lineTo(o.dx, o.dy - s * 0.6)
      ..lineTo(o.dx + s * 0.5, o.dy)
      ..lineTo(o.dx + s, o.dy - s * 0.4)
      ..lineTo(o.dx + s, o.dy + s * 0.5)
      ..close();
    c.drawPath(p, _p(col));
    c.drawPath(p, _stroke(Colors.black.withValues(alpha: 0.25), 0.8));
  }

  switch (cover.kind) {
    case 'tarneebc': // Tarneeb: yuvarlak masa, dört oyuncu, ortada löve, teklif rozeti
      _bg(c, seed, tint: _felt);
      c.drawCircle(const Offset(50, 50), 31, _p(Colors.black.withValues(alpha: 0.16)));
      c.drawCircle(const Offset(50, 50), 31, _stroke(gold.withValues(alpha: 0.7), 1.3));
      seats();
      drawCard(c, const Offset(50, 38), 14, 0.04, rank: 'A', suit: 0);
      drawCard(c, const Offset(62, 50), 14, 0.2, rank: 'K', suit: (v + 1) % 4);
      drawCard(c, const Offset(50, 62), 14, -0.05, rank: '7', suit: (v + 2) % 4);
      drawCard(c, const Offset(38, 50), 14, -0.2, rank: 'Q', suit: 0);
      badge(const Offset(83, 83), 10, '${7 + v % 3}');
      drawSuit(c, 0, const Offset(17, 17), 13, color: Colors.white);
    case 'trixc': // Trix: dört krallık; kupa papazı, kızlar, karolar, sıralı dizilim
      _bg(c, seed, tint: const Color(0xFF16523B));
      for (var k = 0; k < 4; k++) {
        final o = Offset(30 + (k % 2) * 40.0, 30 + (k ~/ 2) * 40.0);
        final r = box(o, 34, 34, 8);
        _shadowRRect(c, r, dy: 1.6);
        c.drawRRect(r, _p(_ivory));
        c.drawRRect(r, _stroke((k + v) % 4 == 0 ? gold : Colors.black12, (k + v) % 4 == 0 ? 2.2 : 0.8));
        switch (k) {
          case 0:
            crown(o + const Offset(0, -6), 9, gold);
            drawSuit(c, 1, o + const Offset(0, 9), 13);
          case 1:
            _text(c, 'Q', o + const Offset(-6, -4), 15, _red);
            _text(c, 'Q', o + const Offset(6, 6), 15, _ink);
          case 2:
            drawSuit(c, 2, o + const Offset(-6, -5), 12);
            drawSuit(c, 2, o + const Offset(6, 6), 12);
          default:
            for (var i = 0; i < 4; i++) {
              c.drawRRect(box(o + Offset(-9 + i * 6.0, 6 - i * 4.0), 8, 11, 1.5), _p(_pal[(i + v) % 4]));
              c.drawRRect(box(o + Offset(-9 + i * 6.0, 6 - i * 4.0), 8, 11, 1.5), _stroke(Colors.white70, 0.7));
            }
        }
      }
      c.drawCircle(const Offset(50, 50), 7, _p(gold));
      _text(c, '4', const Offset(50, 50), 9, _ink);
    case 'balootc': // Baloot: "güneş" (sun) ilanı ve aynı renkten üçlü proje dizisi
      _bg(c, seed, tint: const Color(0xFF6B3F25));
      // Güneş
      const sunO = Offset(30, 28);
      for (var k = 0; k < 12; k++) {
        final a = k * math.pi / 6 + v * 0.1;
        c.drawLine(sunO + Offset(math.cos(a) * 13, math.sin(a) * 13), sunO + Offset(math.cos(a) * 19, math.sin(a) * 19),
            _stroke(gold, 2.2));
      }
      c.drawCircle(sunO, 10.5, _p(gold));
      c.drawCircle(sunO, 10.5, _stroke(Colors.white54, 1));
      // Proje: sıralı üç kart, aynı takım
      final s = (v + 1) % 4;
      const ranks = ['10', 'J', 'Q'];
      for (var i = 0; i < 3; i++) {
        drawCard(c, Offset(44 + i * 14.0, 66 - i * 3.0), 22, -0.12 + i * 0.12, rank: ranks[i], suit: s);
      }
      // Koz kart arka yüzü, sağ üstte
      drawCard(c, const Offset(76, 26), 18, 0.25, back: true, backColor: const Color(0xFF8E3B2E));
    case 'hokmc': // Hokm: ilan edilen koz rozeti, yelpaze el ve yedi el çentiği
      _bg(c, seed, tint: const Color(0xFF233A5E));
      final trump = v % 4;
      c.drawCircle(const Offset(50, 28), 18, _p(gold.withValues(alpha: 0.25)));
      c.drawCircle(const Offset(50, 28), 14, _p(_ivory));
      c.drawCircle(const Offset(50, 28), 14, _stroke(gold, 2.4));
      drawSuit(c, trump, const Offset(50, 29), 15);
      for (var i = 0; i < 5; i++) {
        final a = (i - 2) * 0.22;
        drawCard(c, Offset(50 + (i - 2) * 9.0, 72 + (i - 2).abs() * 1.6), 20, a,
            rank: const ['7', '9', 'J', 'K', 'A'][i], suit: i == 4 ? trump : (trump + i + 1) % 4);
      }
      for (var i = 0; i < 7; i++) {
        final on = i < 4 + v % 3;
        c.drawRRect(box(Offset(14, 14 + i * 6.0), 6, 3.6, 1.5), _p(on ? gold : Colors.white24));
      }
    case 'twentyninec': // Yirmi Dokuz: 29 rozeti, en değerli vale ve dokuz
      _bg(c, seed, tint: _felt);
      drawCard(c, const Offset(36, 62), 28, -0.2, rank: 'J', suit: v % 4);
      drawCard(c, const Offset(60, 60), 28, 0.16, rank: '9', suit: (v + 2) % 4);
      badge(const Offset(50, 24), 15, '29');
      for (var i = 0; i < 4; i++) {
        c.drawCircle(Offset(80, 50 + i * 8.0), 2.6, _p(i < 2 + v % 3 ? gold : Colors.white24));
      }
    case 'carromc': // Karambol: kare tahta, köşe delikleri, ortada çiçek dizilimi, vurucu pul
      _bg(c, seed);
      const b = Rect.fromLTWH(10, 10, 80, 80);
      _woodBoard(c, b);
      final inner = b.deflate(6);
      c.drawRect(inner, _p(const Color(0xFFF1DDB5)));
      for (final o in [inner.topLeft, inner.topRight, inner.bottomLeft, inner.bottomRight]) {
        final q = Offset(o.dx + (o.dx < 50 ? 4.5 : -4.5), o.dy + (o.dy < 50 ? 4.5 : -4.5));
        c.drawCircle(q, 4.5, _p(const Color(0xFF2B2B2B)));
      }
      final line = _stroke(const Color(0xFF7A4B2A).withValues(alpha: 0.7), 0.9);
      c.drawRect(inner.deflate(9), line);
      c.drawCircle(const Offset(50, 50), 12, line);
      c.drawCircle(const Offset(50, 50), 13.5, _stroke(const Color(0xFFB23A3A).withValues(alpha: 0.7), 0.8));
      // Pullar: kraliçe ortada, çevresinde koyu-açık sıra
      for (var k = 0; k < 6; k++) {
        final a = k * math.pi / 3 + v * 0.2;
        final o = Offset(50 + math.cos(a) * 6.6, 50 + math.sin(a) * 6.6);
        _stone(c, o, 3.3, k.isEven ? const Color(0xFF3A2A22) : const Color(0xFFEFE3C8));
      }
      _stone(c, const Offset(50, 50), 3.3, const Color(0xFFC0392B));
      // Vurucu ve nişan çizgisi
      _stone(c, const Offset(36, 76), 4.8, const Color(0xFF3B7DD8));
      c.drawLine(const Offset(38, 72), const Offset(45, 59), _stroke(Colors.black38, 1));
    case 'pacisic': // Paçisi: artı biçimli kumaş tahta, dört renk piyon, deniz kabukları
      _bg(c, seed, tint: const Color(0xFF7B2D26));
      const cloth = Color(0xFFE9B949);
      const cell = 7.0;
      // Dört kol: 3 sütun x 4 hücre; ortada ev
      void arm(double x, double y, bool vertical) {
        for (var i = 0; i < 4; i++) {
          for (var j = 0; j < 3; j++) {
            final r = vertical
                ? Rect.fromLTWH(x + j * cell, y + i * cell, cell, cell)
                : Rect.fromLTWH(x + i * cell, y + j * cell, cell, cell);
            c.drawRect(r, _p((i + j).isEven ? cloth : const Color(0xFFF4D58D)));
            c.drawRect(r, _stroke(const Color(0xFF7B2D26).withValues(alpha: 0.5), 0.5));
          }
        }
      }
      const h0 = 50 - cell * 1.5;
      arm(h0, h0 - cell * 4, true);
      arm(h0, h0 + cell * 3, true);
      arm(h0 - cell * 4, h0, false);
      arm(h0 + cell * 3, h0, false);
      final home = Rect.fromLTWH(h0, h0, cell * 3, cell * 3);
      c.drawRect(home, _p(const Color(0xFF2E7D5B)));
      c.drawLine(home.topLeft, home.bottomRight, _stroke(cloth, 0.8));
      c.drawLine(home.topRight, home.bottomLeft, _stroke(cloth, 0.8));
      const pawns = [Color(0xFFD23C3C), Color(0xFF3075C4), Color(0xFF3BA776), Color(0xFFF2F2F2)];
      final spots = [
        Offset(50, h0 - cell * 2.5),
        Offset(h0 + cell * 5.5, 50 - cell),
        Offset(50 + cell, h0 + cell * 5.5),
        Offset(h0 - cell * 2.5, 50 + cell),
      ];
      for (var k = 0; k < 4; k++) {
        _stone(c, spots[(k + v) % 4], 3.2, pawns[k]);
      }
      // Deniz kabukları (zar yerine)
      for (var k = 0; k < 3; k++) {
        final o = Offset(14 + k * 8.0, 86 - (k % 2) * 3.0);
        c.drawOval(Rect.fromCenter(center: o, width: 6.5, height: 9), _p(const Color(0xFFF7EEDC)));
        c.drawLine(o + const Offset(0, -3), o + const Offset(0, 3), _stroke(const Color(0xFF8A6A4A), 1));
      }
    default:
      return false;
  }
  return true;
}
