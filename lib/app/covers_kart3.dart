part of 'covers.dart';

/// Kâğıt Oyunları merkezindeki her oyunun kendine ait kapağı (kc_* türleri).
/// Önceden birçok oyun aynı 'cards' / 'solitaire' / 'rack' / 'war' çizimini
/// yalnız bir sayı farkıyla paylaşıyordu; burada her oyun kendi düzenini,
/// mekaniğini ya da temasını gösterir. Vektör çizim, dış görsel ve marka yok.
/// Döndürür: tür tanındıysa true.
bool _paintKart3Cover(Canvas c, GameCover cover, Color seed) {
  const gold = Color(0xFFF5B82E);
  const blue = Color(0xFF2E5FA8);
  const maroon = Color(0xFF8E1A2C);
  switch (cover.kind) {
    // ---- Sabır (solitaire) -------------------------------------------------
    case 'kc_klondike': // dört temel yuva, kapalı/açık basamaklı yedi sütun
      _bg(c, seed, tint: _felt);
      for (var i = 0; i < 4; i++) {
        final o = Offset(14 + i * 16.0, 17);
        if (i < 2) {
          drawCard(c, o, 13, 0, rank: 'A', suit: i + 1);
        } else {
          _kcSlot(c, o, 13);
        }
      }
      drawCard(c, const Offset(86, 17), 13, 0, back: true);
      for (var col = 0; col < 5; col++) {
        for (var j = 0; j <= col; j++) {
          drawCard(c, Offset(14 + col * 18.0, 42 + j * 8.0), 14, 0,
              rank: const ['K', 'Q', 'J', '10', '9'][col], suit: (col + j) % 4, back: j != col);
        }
      }
    case 'kc_spider': // örümcek ağı köşesi, iki takımlı uzun diziler
      _bg(c, seed, tint: const Color(0xFF3B2A55));
      final web = _stroke(Colors.white38, 0.8);
      for (var k = 0; k < 4; k++) {
        final a = math.pi / 2 + k * math.pi / 6;
        c.drawLine(const Offset(100, 0), Offset(100 + 34 * math.cos(a), 34 * math.sin(a)), web);
      }
      for (final r in const [12.0, 22.0, 32.0]) {
        c.drawArc(Rect.fromCircle(center: const Offset(100, 0), radius: r), math.pi / 2, math.pi / 2, false, web);
      }
      for (var col = 0; col < 6; col++) {
        for (var j = 0; j < 5; j++) {
          drawCard(c, Offset(12 + col * 14.0, 38 + j * 7.0), 12, 0,
              rank: const ['K', 'Q', 'J', '10', '9', '8'][(j + col) % 6], suit: col.isEven ? 0 : 1, back: j < 2);
        }
      }
      c.drawLine(const Offset(84, 0), const Offset(84, 12), _stroke(Colors.white54, 0.6));
      for (final side in const [-1.0, 1.0]) {
        for (var k = 0; k < 4; k++) {
          c.drawPath(
              Path()
                ..moveTo(84, 16)
                ..lineTo(84 + side * 6, 11 + k * 3.0)
                ..lineTo(84 + side * 9, 14 + k * 4.0),
              _stroke(_ink, 1));
        }
      }
      c.drawCircle(const Offset(84, 17), 3.6, _p(_ink));
      c.drawCircle(const Offset(84, 12.5), 2.2, _p(_ink));
    case 'kc_freecell': // dört boş hücre (altın çerçeve), dört temel, açık sütunlar
      _bg(c, seed, tint: const Color(0xFF1E3A5F));
      for (var i = 0; i < 4; i++) {
        final o = Offset(10 + i * 11.5, 16);
        if (i == 1) {
          drawCard(c, o, 10, 0, rank: '7', suit: 2);
        } else {
          _kcSlot(c, o, 10, col: gold);
        }
        drawCard(c, Offset(56 + i * 11.5, 16), 10, 0, rank: 'A', suit: i);
      }
      for (var col = 0; col < 6; col++) {
        for (var j = 0; j < 4; j++) {
          drawCard(c, Offset(14 + col * 14.4, 40 + j * 9.0), 12, 0,
              rank: const ['9', '8', '7', '6', '5', '4'][(col + j) % 6], suit: (col * 3 + j) % 4);
        }
      }
    case 'kc_tripeaks': // üç tepe, alt sıra açık, deste ve açık kart
      _bg(c, seed, tint: const Color(0xFF1F5E63));
      for (final cx in const [24.0, 50.0, 76.0]) {
        for (var r = 0; r < 3; r++) {
          for (var i = 0; i <= r; i++) {
            drawCard(c, Offset(cx + (i - r / 2) * 11, 20 + r * 10.0), 10, 0, back: true);
          }
        }
      }
      for (var i = 0; i < 9; i++) {
        drawCard(c, Offset(10 + i * 10.0, 54), 10, 0, rank: const ['3', '8', 'K', '5', '9', 'Q', '2', '6', 'J'][i], suit: i % 4);
      }
      drawCard(c, const Offset(38, 82), 13, 0, back: true, backColor: maroon);
      drawCard(c, const Offset(58, 82), 13, 0.08, rank: '7', suit: 1);
      _kcArrow(c, const Offset(66, 84), const Offset(84, 74), gold);
    case 'kc_golf': // bayraklı çim tepe ve sütunlar
      _bg(c, seed, tint: const Color(0xFF3F7D3A));
      c.drawOval(const Rect.fromLTWH(46, 58, 70, 40), _p(const Color(0xFF7CC46A)));
      c.drawOval(const Rect.fromLTWH(73, 64, 10, 3.6), _p(const Color(0xFF1E3B1A)));
      c.drawLine(const Offset(78, 65), const Offset(78, 30), _stroke(Colors.white, 1.6));
      c.drawPath(Path()..addPolygon(const [Offset(78, 30), Offset(92, 35), Offset(78, 40)], true), _p(_red));
      c.drawCircle(const Offset(62, 74), 2.4, _p(Colors.white));
      for (var col = 0; col < 4; col++) {
        for (var j = 0; j < 3; j++) {
          drawCard(c, Offset(12 + col * 13.0, 18 + j * 8.0), 11, 0,
              rank: const ['4', '9', 'J', '2', '6', 'Q'][(col + j * 2) % 6], suit: (col + j) % 4);
        }
      }
      drawCard(c, const Offset(24, 76), 15, -0.1, rank: '5', suit: 3);
      drawCard(c, const Offset(36, 74), 15, 0.08, rank: '6', suit: 1);
    case 'kc_yukon': // karlı dağ silueti önünde yoğun açık sütunlar
      _bg(c, seed, tint: const Color(0xFF2F5C80));
      final mount = Path()
        ..addPolygon(const [Offset(0, 46), Offset(22, 16), Offset(40, 38), Offset(60, 10), Offset(84, 36), Offset(100, 22), Offset(100, 46)], true);
      c.drawPath(mount, _p(Colors.white.withValues(alpha: 0.2)));
      for (final (x, y) in const [(22.0, 16.0), (60.0, 10.0), (100.0, 22.0)]) {
        c.drawPath(Path()..addPolygon([Offset(x, y), Offset(x + 6, y + 8), Offset(x - 6, y + 8)], true), _p(Colors.white));
      }
      for (var col = 0; col < 5; col++) {
        for (var j = 0; j < 6; j++) {
          drawCard(c, Offset(14 + col * 18.0, 38 + j * 6.5), 15, 0,
              rank: const ['K', '10', '7', 'Q', '4', '9', 'J', '2'][(j + col * 3) % 8], suit: (j + col) % 4, back: j == 0);
        }
      }
    case 'kc_scorpion': // sütunlar ve kıvrık kuyruklu akrep silueti
      _bg(c, seed, tint: const Color(0xFF8A5A2B));
      for (var col = 0; col < 4; col++) {
        for (var j = 0; j < 5; j++) {
          drawCard(c, Offset(12 + col * 14.0, 20 + j * 9.0), 12, 0,
              rank: const ['K', 'Q', 'J', '10', '9'][j], suit: col % 4, back: col < 2 && j < 2);
        }
      }
      const sc = Color(0xFF2A1A0E);
      c.drawOval(Rect.fromCenter(center: const Offset(76, 82), width: 18, height: 9), _p(sc));
      for (final (x, y, r) in const [(86.0, 78.0, 3.6), (90.0, 70.0, 3.4), (92.0, 62.0, 3.2), (90.0, 54.0, 3.0), (86.0, 48.0, 2.8), (80.0, 46.0, 2.6)]) {
        c.drawCircle(Offset(x, y), r, _p(sc));
      }
      c.drawPath(Path()..addPolygon(const [Offset(78, 44), Offset(72, 48), Offset(78, 49)], true), _p(sc));
      for (final dy in const [-1.0, 1.0]) {
        c.drawLine(Offset(68, 82 + dy * 2), Offset(62, 82 + dy * 8), _stroke(sc, 1.8));
        c.drawCircle(Offset(60, 82 + dy * 9), 2.8, _p(sc));
      }
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(72 + k * 4.0, 86), Offset(70 + k * 4.0, 92), _stroke(sc, 1));
      }
    case 'kc_forty': // sekiz dar sütun, dört as, "40" rozeti
      _bg(c, seed, tint: const Color(0xFF6E2230));
      for (var col = 0; col < 8; col++) {
        for (var j = 0; j < 4; j++) {
          drawCard(c, Offset(10 + col * 11.4, 22 + j * 7.0), 9, 0,
              rank: const ['Q', '9', '6', '3'][j], suit: (col + j) % 4);
        }
      }
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(16 + i * 14.0, 74), 12, 0, rank: 'A', suit: i);
      }
      _kcBadge(c, const Offset(84, 78), 11, '40');
    case 'kc_canfield': // yüksek yedek deste "13", dört sütun
      _bg(c, seed, tint: const Color(0xFF283A6B));
      for (var i = 0; i < 6; i++) {
        drawCard(c, Offset(22 + i * 0.8, 58 - i * 1.6), 22, 0, back: true, backColor: maroon);
      }
      drawCard(c, const Offset(27, 48), 22, 0, rank: 'J', suit: 1);
      _kcBadge(c, const Offset(24, 82), 8, '13');
      for (var col = 0; col < 4; col++) {
        for (var j = 0; j < 3; j++) {
          drawCard(c, Offset(50 + col * 13.0, 32 + j * 10.0), 11, 0,
              rank: const ['8', '7', '6'][j], suit: (col + j) % 4);
        }
      }
      for (var i = 0; i < 4; i++) {
        _kcSlot(c, Offset(50 + i * 13.0, 13), 10);
      }
    case 'kc_accordion': // tek sırada zikzak kartlar, üç geri atlama oku
      _bg(c, seed, tint: const Color(0xFF4B2E6F));
      for (var i = 0; i < 8; i++) {
        drawCard(c, Offset(12 + i * 10.8, 60 + (i.isEven ? -5.0 : 5.0)), 14, i.isEven ? -0.2 : 0.2,
            rank: const ['3', '7', '7', 'K', '2', '9', 'J', '9'][i], suit: (i * 3) % 4);
      }
      c.drawPath(
          Path()
            ..moveTo(87, 44)
            ..quadraticBezierTo(70, 14, 55, 42),
          _stroke(gold, 2.4));
      c.drawPath(Path()..addPolygon(const [Offset(55, 42), Offset(51, 34), Offset(59, 36)], true), _p(gold));
    case 'kc_clock': // çember üzerinde 12 deste, ortada papaz ve akrep-yelkovan
      _bg(c, seed, tint: const Color(0xFF5A3B22));
      c.drawCircle(const Offset(50, 52), 42, _p(Colors.black.withValues(alpha: 0.15)));
      for (var i = 0; i < 12; i++) {
        final a = -math.pi / 2 + i * math.pi / 6;
        final o = Offset(50 + 34 * math.cos(a), 52 + 34 * math.sin(a));
        if (i % 3 == 0) {
          drawCard(c, o, 10, a + math.pi / 2, rank: const ['Q', '3', '6', '9'][i ~/ 3], suit: i ~/ 3);
        } else {
          drawCard(c, o, 10, a + math.pi / 2, back: true);
        }
      }
      drawCard(c, const Offset(50, 52), 15, 0, rank: 'K', suit: 0);
      c.drawLine(const Offset(50, 52), const Offset(50, 30), _stroke(gold, 2.2));
      c.drawLine(const Offset(50, 52), const Offset(64, 58), _stroke(gold, 2.2));
      c.drawCircle(const Offset(50, 52), 2.4, _p(gold));
    case 'kc_solcesit': // dört çerçevede dört ayrı sabır dizilimi
      _bg(c, seed, tint: const Color(0xFF2E6B4A));
      void mini(double x, double y, double w, Color col) => c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: w, height: w * 1.4), const Radius.circular(1.2)),
          _p(col));
      for (var q = 0; q < 4; q++) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(8 + (q % 2) * 44.0, 8 + (q ~/ 2) * 44.0, 40, 40), const Radius.circular(6));
        c.drawRRect(r, _p(Colors.black.withValues(alpha: 0.18)));
        c.drawRRect(r, _stroke(gold.withValues(alpha: 0.6), 1));
      }
      for (var row = 0; row < 3; row++) {
        for (var i = 0; i <= row; i++) {
          mini(28 + (i - row / 2) * 9, 17 + row * 9.0, 7, i == row ? _ivory : blue);
        }
      }
      for (var col = 0; col < 4; col++) {
        for (var j = 0; j <= col % 3 + 1; j++) {
          mini(60 + col * 8.0, 16 + j * 6.0, 6.5, j == col % 3 + 1 ? _ivory : blue);
        }
      }
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        mini(28 + 12 * math.cos(a), 72 + 12 * math.sin(a), 5, i.isEven ? _ivory : blue);
      }
      for (var i = 0; i < 6; i++) {
        mini(58 + i * 5.0, 72 + (i.isEven ? -2.0 : 2.0), 7, i == 5 ? _ivory : blue);
      }
    // ---- El alma ----------------------------------------------------------
    case 'kc_batak': // dört yönden atılan el, üstte kazanan maça ası, ihale rozeti
      _bg(c, seed, tint: const Color(0xFF6E1A2A));
      drawSuit(c, 0, const Offset(50, 50), 80, color: Colors.white.withValues(alpha: 0.07));
      drawCard(c, const Offset(50, 30), 17, 0, rank: 'K', suit: 1);
      drawCard(c, const Offset(71, 50), 17, math.pi / 2, rank: 'Q', suit: 2);
      drawCard(c, const Offset(50, 70), 17, 0, rank: 'J', suit: 3);
      drawCard(c, const Offset(29, 50), 17, math.pi / 2, rank: '10', suit: 1);
      drawCard(c, const Offset(52, 50), 22, 0.15, rank: 'A', suit: 0);
      _kcBadge(c, const Offset(84, 84), 9, '5');
    case 'kc_batakcesit': // altın büyük maça, dört köşede dört koz kartı
      _bg(c, seed, tint: const Color(0xFF7A2E1E));
      const corners = [(20.0, 24.0, -0.4), (80.0, 24.0, 0.4), (20.0, 78.0, 0.4), (80.0, 78.0, -0.4)];
      for (var i = 0; i < 4; i++) {
        final (x, y, a) = corners[i];
        drawCard(c, Offset(x, y), 17, a, rank: 'A', suit: i);
      }
      c.drawCircle(const Offset(50, 50), 22, _p(Colors.black.withValues(alpha: 0.2)));
      drawSuit(c, 0, const Offset(50, 50), 36, color: gold);
    case 'kc_hearts': // maça kızı ve çevresinde kupalar
      _bg(c, seed, tint: const Color(0xFF8C2F4A));
      for (var i = 0; i < 9; i++) {
        final a = i * 2 * math.pi / 9;
        drawSuit(c, 1, Offset(50 + 38 * math.cos(a), 52 + 38 * math.sin(a)), 9 + (i % 3) * 2.0,
            color: const Color(0xFFFF9FB2));
      }
      drawCard(c, const Offset(50, 52), 34, -0.08, rank: 'Q', suit: 0);
    case 'kc_spades': // beyaz büyük maça ve üç fiş
      _bg(c, seed, tint: const Color(0xFF1C2541));
      drawSuit(c, 0, const Offset(50, 42), 54, color: Colors.white);
      _kcChip(c, const Offset(28, 82), 9, _pal[0], '4');
      _kcChip(c, const Offset(50, 85), 9, _pal[1], '3');
      _kcChip(c, const Offset(72, 82), 9, _pal[3], '0');
    case 'kc_whist': // koz gösteren deste ve çapraz dizilmiş kazanılmış eller
      _bg(c, seed, tint: const Color(0xFF234B3B));
      drawCard(c, const Offset(32, 56), 24, math.pi / 2, rank: '9', suit: 2);
      for (var i = 0; i < 5; i++) {
        drawCard(c, Offset(26 + i * 0.6, 54 - i * 1.2), 24, 0, back: true);
      }
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(74, 18 + i * 21.0), 13, i.isEven ? 0 : math.pi / 2, back: true, backColor: maroon);
      }
    case 'kc_ohhell': // her elde bir kart artan merdiven, tam tahmin rozeti
      _bg(c, seed, tint: const Color(0xFF2B4C6F));
      for (var col = 0; col < 5; col++) {
        for (var j = 0; j <= col; j++) {
          final top = j == col;
          drawCard(c, Offset(16 + col * 17.0, 78 - j * 9.0), 13, 0,
              rank: const ['2', '5', '8', 'J', 'A'][col], suit: col % 4, back: !top);
        }
      }
      _kcBadge(c, const Offset(20, 22), 10, '?');
    case 'kc_briscola': // İtalyan takımlı (altın, kupa, kılıç, sopa) yelpaze ve koz
      _bg(c, seed, tint: const Color(0xFF5B5A2A));
      _kcFace(c, const Offset(66, 68), 22, math.pi / 2, () => _kcItalian(c, 0, 10));
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(64 + i * 0.6, 66 - i * 1.2), 22, 0, back: true, backColor: const Color(0xFF7A3B1E));
      }
      for (var i = 0; i < 3; i++) {
        _kcFace(c, Offset(24 + i * 12.0, 38 + (i == 1 ? -3.0 : 0)), 20, (i - 1) * 0.28, () => _kcItalian(c, i + 1, 9));
      }
    case 'kc_sueca': // çini desenli zemin, koz yedili ve as, "61" rozeti
      _bg(c, seed, tint: const Color(0xFF1F4E79));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final o = Offset(12.5 + x * 25, 12.5 + y * 25);
          c.drawRect(Rect.fromCenter(center: o, width: 23, height: 23), _p(Colors.white.withValues(alpha: 0.12)));
          for (var k = 0; k < 4; k++) {
            final a = k * math.pi / 2;
            c.drawCircle(o + Offset(5 * math.cos(a), 5 * math.sin(a)), 3, _stroke(Colors.white.withValues(alpha: 0.3), 0.9));
          }
        }
      }
      drawCard(c, const Offset(40, 52), 28, -0.18, rank: '7', suit: 1);
      drawCard(c, const Offset(60, 50), 28, 0.16, rank: 'A', suit: 1);
      _kcBadge(c, const Offset(82, 84), 10, '61');
    case 'kc_king': // büyük altın taç, altında dört papaz
      _bg(c, seed, tint: const Color(0xFF6B4E16));
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(29 + i * 14.0, 64 + ((i - 1.5).abs()) * 3), 24, (i - 1.5) * 0.25, rank: 'K', suit: i);
      }
      _kcCrown(c, const Offset(50, 24), 18, gold);
    case 'kc_euchre': // çapraz iki vale (sağ ve sol bower), puan tutan 6 ve 4
      _bg(c, seed, tint: const Color(0xFF3E5C76));
      drawCard(c, const Offset(40, 44), 30, -0.32, rank: 'J', suit: 1);
      drawCard(c, const Offset(60, 44), 30, 0.32, rank: 'J', suit: 2);
      drawCard(c, const Offset(76, 82), 14, 0, rank: '6', suit: 0);
      drawCard(c, const Offset(80, 84), 14, 0.5, back: true);
      for (var i = 0; i < 5; i++) {
        c.drawCircle(Offset(14 + i * 9.0, 86), 3, _p(i < 3 ? gold : Colors.white24));
      }
    case 'kc_belot': // koz vale ve dokuzlu, köşede kız-papaz (belote) çifti
      _bg(c, seed, tint: const Color(0xFF2A4D8F));
      drawCard(c, const Offset(34, 44), 28, -0.12, rank: 'J', suit: 3);
      drawCard(c, const Offset(60, 40), 28, 0.12, rank: '9', suit: 3);
      drawCard(c, const Offset(70, 78), 14, -0.1, rank: 'K', suit: 1);
      drawCard(c, const Offset(82, 80), 14, 0.15, rank: 'Q', suit: 1);
      c.drawCircle(const Offset(76, 79), 13, _stroke(gold, 1.6));
    case 'kc_klaverjas': // dört ardışık kart (roem), altın parantez ve "50"
      _bg(c, seed, tint: const Color(0xFFB5651D));
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(26 + i * 14.0, 42), 20, 0, rank: const ['7', '8', '9', '10'][i], suit: 2);
      }
      c.drawPath(
          Path()
            ..moveTo(16, 62)
            ..lineTo(16, 68)
            ..lineTo(78, 68)
            ..lineTo(78, 62),
          _stroke(gold, 2.4));
      _kcBadge(c, const Offset(47, 82), 10, '50');
    case 'kc_jass': // tebeşir tahtasında Z çizgisi, çan ve meşe palamudu kartları
      _bg(c, seed, tint: const Color(0xFF7F1D1D));
      final board = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 46, 80, 44), const Radius.circular(4));
      _shadowRRect(c, board);
      c.drawRRect(board, _p(_wood));
      c.drawRRect(board.deflate(3), _p(const Color(0xFF2F3B36)));
      final chalk = _stroke(Colors.white70, 1.6);
      c.drawPath(
          Path()
            ..moveTo(20, 54)
            ..lineTo(80, 54)
            ..lineTo(20, 82)
            ..lineTo(80, 82),
          chalk);
      for (var i = 0; i < 4; i++) {
        c.drawLine(Offset(30 + i * 4.0, 58), Offset(30 + i * 4.0, 66), chalk);
        c.drawLine(Offset(58 + i * 4.0, 70), Offset(58 + i * 4.0, 78), chalk);
      }
      _kcFace(c, const Offset(36, 24), 18, -0.15, () => _kcBell(c, 7));
      _kcFace(c, const Offset(60, 22), 18, 0.15, () => _kcAcorn(c, 7));
    case 'kc_pinokl': // ikişer kopya kartlarla geniş yelpaze (çift deste)
      _bg(c, seed, tint: const Color(0xFF4F2C1D));
      const rk = ['A', 'A', '10', '10', 'K', 'K', 'Q'];
      for (var i = 0; i < 7; i++) {
        final a = (i - 3) * 0.2;
        drawCard(c, Offset(50 + 46 * math.sin(a), 96 - 46 * math.cos(a)), 18, a, rank: rk[i], suit: i ~/ 2 % 4);
      }
      for (var i = 0; i < 2; i++) {
        drawCard(c, Offset(14 + i * 4.0, 18 + i * 3.0), 14, -0.1, back: true, backColor: i == 0 ? blue : maroon);
      }
    case 'kc_skat': // ortada iki kapalı skat kartı, altta dört vale, yanlarda eller
      _bg(c, seed, tint: const Color(0xFF1D3B2A));
      for (final side in const [-1.0, 1.0]) {
        for (var i = 0; i < 3; i++) {
          drawCard(c, Offset(50 + side * 38, 30 + i * 8.0), 12, side * (math.pi / 2), back: true);
        }
      }
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(50, 34), width: 34, height: 30), const Radius.circular(5)),
          _stroke(gold, 1.4));
      drawCard(c, const Offset(44, 34), 15, -0.15, back: true, backColor: maroon);
      drawCard(c, const Offset(56, 34), 15, 0.15, back: true, backColor: maroon);
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(29 + i * 14.0, 76 + ((i - 1.5).abs()) * 2), 17, (i - 1.5) * 0.18, rank: 'J', suit: (i + 3) % 4);
      }
    case 'kc_koyun': // yün bulutlu koyun başı, yanlarında kız ve vale
      _bg(c, seed, tint: const Color(0xFF3B5249));
      for (var i = 0; i < 9; i++) {
        final a = i * 2 * math.pi / 9;
        c.drawCircle(Offset(50 + 18 * math.cos(a), 40 + 15 * math.sin(a)), 9, _p(const Color(0xFFF4F1EA)));
      }
      c.drawOval(Rect.fromCenter(center: const Offset(50, 46), width: 18, height: 24), _p(const Color(0xFF2B2522)));
      for (final s in const [-1.0, 1.0]) {
        c.drawOval(Rect.fromCenter(center: Offset(50 + s * 13, 38), width: 10, height: 5), _p(const Color(0xFF2B2522)));
        c.drawCircle(Offset(50 + s * 4.5, 42), 2, _p(Colors.white));
      }
      drawCard(c, const Offset(20, 78), 18, -0.25, rank: 'Q', suit: 3);
      drawCard(c, const Offset(80, 78), 18, 0.25, rank: 'J', suit: 2);
    case 'kc_kontrat': // ihale kutusu: seviye x takım kartonları, seçili 3 kupa
      _bg(c, seed, tint: const Color(0xFF14213D));
      for (var lv = 0; lv < 4; lv++) {
        for (var s = 0; s < 5; s++) {
          final r = RRect.fromRectAndRadius(Rect.fromLTWH(8 + s * 17.0, 14 + lv * 19.0, 15, 15), const Radius.circular(2.5));
          final hi = lv == 2 && s == 2;
          _shadowRRect(c, r, dy: 1);
          c.drawRRect(r, _p(hi ? gold : _ivory));
          _text(c, '${lv + 1}', Offset(r.left + 4.5, r.center.dy), 7, _ink);
          if (s < 4) {
            drawSuit(c, const [3, 2, 1, 0][s], Offset(r.right - 4.5, r.center.dy), 7);
          } else {
            _text(c, 'NT', Offset(r.right - 4.5, r.center.dy), 4.5, _ink);
          }
        }
      }
      drawCard(c, const Offset(80, 88), 12, 0.2, back: true);
      drawCard(c, const Offset(20, 88), 12, -0.2, back: true);
    case 'kc_bezik': // iki deste, maça kızı + karo valesi, puan kadranı
      _bg(c, seed, tint: const Color(0xFF5A189A));
      drawCard(c, const Offset(18, 76), 16, 0, back: true, backColor: blue);
      drawCard(c, const Offset(22, 72), 16, 0, back: true, backColor: maroon);
      drawCard(c, const Offset(44, 50), 30, -0.2, rank: 'Q', suit: 0);
      drawCard(c, const Offset(60, 54), 30, 0.18, rank: 'J', suit: 2);
      c.drawCircle(const Offset(80, 20), 12, _p(_ivory));
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi / 5;
        c.drawLine(Offset(80 + 9 * math.cos(a), 20 + 9 * math.sin(a)), Offset(80 + 11 * math.cos(a), 20 + 11 * math.sin(a)),
            _stroke(_ink, 0.8));
      }
      c.drawLine(const Offset(80, 20), const Offset(86, 14), _stroke(_red, 1.6));
    case 'kc_tarok': // uzun tarok kartları: XXI, I ve yıldızlı soytarı
      _bg(c, seed, tint: const Color(0xFF283618));
      _kcFace(c, const Offset(30, 54), 22, -0.25, () => _text(c, 'I', const Offset(0, 0), 12, maroon), hr: 1.8);
      _kcFace(c, const Offset(70, 54), 22, 0.25, () => _kcStar(c, Offset.zero, 9, 4, gold), hr: 1.8);
      _kcFace(c, const Offset(50, 48), 24, 0, () {
        _text(c, 'XXI', const Offset(0, -9), 8, maroon);
        c.drawCircle(const Offset(0, 6), 6, _stroke(gold, 1.6));
      }, hr: 1.8);
    // ---- Aile ---------------------------------------------------------------
    case 'kc_pisti': // altın patlama üstünde yığına çarpan vale
      _bg(c, seed, tint: const Color(0xFF9B2226));
      _kcStar(c, const Offset(52, 52), 40, 12, gold.withValues(alpha: 0.45), inner: 24);
      for (final (a, r) in const [(-0.3, '4'), (0.25, '9'), (-0.05, '2')]) {
        drawCard(c, const Offset(50, 56), 26, a, rank: r, suit: 3);
      }
      drawCard(c, const Offset(55, 50), 28, 0.12, rank: 'J', suit: 1);
      drawCard(c, const Offset(16, 22), 16, -0.6, rank: '10', suit: 2);
    case 'kc_scopa': // masada açık İtalyan kartları, süpüren süpürge
      _bg(c, seed, tint: const Color(0xFF2D6A4F));
      for (var i = 0; i < 3; i++) {
        _kcFace(c, Offset(20 + i * 22.0, 34 + (i == 1 ? -4.0 : 0)), 17, (i - 1) * 0.15, () => _kcItalian(c, i, 8));
      }
      c.drawLine(const Offset(90, 30), const Offset(60, 70), _stroke(_woodLight, 3));
      final head = Path()..addPolygon(const [Offset(62, 66), Offset(68, 72), Offset(50, 94), Offset(36, 86)], true);
      c.drawPath(head, _p(const Color(0xFFE0B85A)));
      for (var k = 0; k < 5; k++) {
        c.drawLine(Offset(60 - k * 2.0, 70 + k * 1.0), Offset(42 + k * 2.4, 90 - k * 0.4), _stroke(const Color(0xFFA8792E), 0.8));
      }
    case 'kc_toplam': // 2 + 3 = 5: toplayarak alma ve alınan yığın
      _bg(c, seed, tint: const Color(0xFF3D405B));
      drawCard(c, const Offset(18, 38), 17, 0, rank: '2', suit: 1);
      _text(c, '+', const Offset(32, 38), 12, Colors.white);
      drawCard(c, const Offset(46, 38), 17, 0, rank: '3', suit: 3);
      _text(c, '=', const Offset(60, 38), 12, Colors.white);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(80, 38), width: 23, height: 30), const Radius.circular(4)),
          _stroke(gold, 2));
      drawCard(c, const Offset(80, 38), 17, 0, rank: '5', suit: 2);
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(46 + i * 1.5, 80 - i * 1.5), 17, 1.2 + i * 0.12, back: true);
      }
      _kcBadge(c, const Offset(76, 82), 8, '+3');
    case 'kc_renkesle': // dört renkli joker sekiz, açık yığın ve deste
      _bg(c, seed, tint: const Color(0xFF264653));
      drawCard(c, const Offset(22, 60), 20, -0.25, rank: '4', suit: 2);
      drawCard(c, const Offset(78, 60), 20, 0.25, back: true);
      drawCard(c, const Offset(50, 48), 32, 0, rank: '8', suit: 0);
      for (var q = 0; q < 4; q++) {
        c.drawArc(Rect.fromCircle(center: const Offset(53, 54), radius: 9), q * math.pi / 2, math.pi / 2, true, _p(_pal[q]));
      }
      c.drawCircle(const Offset(53, 54), 9, _stroke(Colors.white, 1.2));
    case 'kc_savas': // çarpışan iki kart, kıvılcım ve çapraz kılıçlar
      _bg(c, seed, tint: const Color(0xFF3C1518));
      _kcStar(c, const Offset(50, 60), 16, 8, gold, inner: 7);
      drawCard(c, const Offset(30, 62), 26, 0.3, rank: 'A', suit: 0);
      drawCard(c, const Offset(70, 62), 26, -0.3, rank: 'K', suit: 1);
      for (final s in const [-1.0, 1.0]) {
        c.drawLine(Offset(50 - s * 16, 8), Offset(50 + s * 14, 34), _stroke(const Color(0xFFDDE3EA), 2.6));
        c.drawLine(Offset(50 - s * 18, 13), Offset(50 - s * 10, 8), _stroke(gold, 2.2));
      }
    case 'kc_baskan': // 1-2-3 kürsüsü, taç ve uçuşan kartlar
      _bg(c, seed, tint: const Color(0xFF4A3F8C));
      for (final (x, y, h, col, n) in const [
        (14.0, 64.0, 26.0, Color(0xFFC0C7D1), '2'),
        (38.0, 52.0, 38.0, Color(0xFFF5B82E), '1'),
        (62.0, 70.0, 20.0, Color(0xFFCD7F32), '3'),
      ]) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 24, h), const Radius.circular(3));
        _shadowRRect(c, r);
        c.drawRRect(r, _p(col));
        _text(c, n, Offset(x + 12, y + 10), 11, _ink);
      }
      _kcCrown(c, const Offset(50, 40), 10, gold);
      drawCard(c, const Offset(22, 40), 14, -0.3, back: true);
      drawCard(c, const Offset(80, 50), 14, 0.3, rank: '2', suit: 0);
    case 'kc_papaz': // kaçan papaz (hız çizgileri), atılan çiftler
      _bg(c, seed, tint: const Color(0xFF5E3023));
      for (final (x, y, r) in const [(14.0, 22.0, '7'), (22.0, 26.0, '7'), (78.0, 82.0, '5'), (86.0, 78.0, '5')]) {
        drawCard(c, Offset(x, y), 13, 0.1, rank: r, suit: x < 50 ? 1 : 3);
      }
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(18, 44 + k * 8.0), Offset(32, 44 + k * 8.0), _stroke(Colors.white54, 2));
      }
      drawCard(c, const Offset(54, 52), 30, 0.18, rank: 'K', suit: 0);
    case 'kc_balik': // dalgalar, turuncu balık, dört dörtlü
      _bg(c, seed, tint: const Color(0xFF1B4965));
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(29 + i * 14.0, 30 + ((i - 1.5).abs()) * 2), 18, (i - 1.5) * 0.2, rank: '4', suit: i);
      }
      final wave = Path()..moveTo(0, 74);
      for (var x = 0; x <= 100; x += 10) {
        wave.quadraticBezierTo(x + 5.0, x % 20 == 0 ? 68.0 : 80.0, x + 10.0, 74);
      }
      wave
        ..lineTo(100, 100)
        ..lineTo(0, 100)
        ..close();
      c.drawPath(wave, _p(const Color(0xFF5FA8D3).withValues(alpha: 0.6)));
      c.drawOval(Rect.fromCenter(center: const Offset(50, 72), width: 30, height: 15), _p(const Color(0xFFF08A4B)));
      c.drawPath(Path()..addPolygon(const [Offset(64, 72), Offset(76, 64), Offset(76, 80)], true), _p(const Color(0xFFF08A4B)));
      c.drawCircle(const Offset(41, 70), 1.8, _p(_ink));
    case 'kc_blof': // kapalı atılan kartlar, "3 K" balonu, kırmızı ünlem
      _bg(c, seed, tint: const Color(0xFF3A3042));
      for (var i = 0; i < 3; i++) {
        drawCard(c, Offset(48 + i * 4.0, 66 - i * 2.0), 24, -0.2 + i * 0.2, back: true);
      }
      final bubble = RRect.fromRectAndRadius(const Rect.fromLTWH(8, 12, 40, 22), const Radius.circular(10));
      c.drawRRect(bubble, _p(Colors.white));
      c.drawPath(Path()..addPolygon(const [Offset(24, 33), Offset(34, 33), Offset(36, 42)], true), _p(Colors.white));
      _text(c, '3 K', const Offset(28, 23), 11, _ink);
      _kcBadge(c, const Offset(80, 24), 11, '!', fill: _red, ink: Colors.white);
    case 'kc_31': // aynı renkten üç kart ve büyük "31"
      _bg(c, seed, tint: const Color(0xFF0B6E4F));
      for (var i = 0; i < 3; i++) {
        drawCard(c, Offset(34 + i * 14.0, 60 + (i == 1 ? -3.0 : 0)), 26, (i - 1) * 0.25, rank: const ['A', 'K', '10'][i], suit: 1);
      }
      _kcBadge(c, const Offset(78, 22), 14, '31');
    case 'kc_hafiza': // kapalı kart ızgarası, açılan iki eş kız
      _bg(c, seed, tint: const Color(0xFF33415C));
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 4; x++) {
          final o = Offset(20 + x * 20.0, 22 + y * 28.0);
          final open = (x == 1 && y == 0) || (x == 2 && y == 2);
          if (open) {
            c.drawCircle(o, 12, _p(gold.withValues(alpha: 0.35)));
            drawCard(c, o, 13, 0, rank: 'Q', suit: 1);
          } else {
            drawCard(c, o, 13, 0, back: true, backColor: (x + y).isEven ? blue : maroon);
          }
        }
      }
    // ---- Remi ve dahası -----------------------------------------------------
    case 'kc_gin': // masada üçlü per ve sıralı per, "GIN" rozeti
      _bg(c, seed, tint: const Color(0xFF3A5A40));
      for (var i = 0; i < 3; i++) {
        drawCard(c, Offset(18 + i * 11.0, 34), 16, 0, rank: '7', suit: i);
      }
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(40 + i * 11.0, 70), 16, 0, rank: const ['4', '5', '6', '7'][i], suit: 0);
      }
      _kcBadge(c, const Offset(80, 24), 12, 'GIN');
    case 'kc_kartremi': // jokerli sıralı per, deste ve atılan kart
      _bg(c, seed, tint: const Color(0xFF6A040F));
      drawCard(c, const Offset(20, 24), 15, 0, back: true);
      drawCard(c, const Offset(38, 24), 15, 0.1, rank: '9', suit: 3);
      for (var i = 0; i < 4; i++) {
        final o = Offset(24 + i * 16.0, 66);
        if (i == 1) {
          _kcFace(c, o, 20, 0, () => _kcStar(c, Offset.zero, 7, 5, _pal[i + 3], inner: 3));
        } else {
          drawCard(c, o, 20, 0, rank: const ['4', '', '6', '7'][i], suit: 1);
        }
      }
    case 'kc_konken': // iki renk deste, on üç kartlık el, "51" rozeti
      _bg(c, seed, tint: const Color(0xFF7A4419));
      drawCard(c, const Offset(30, 28), 20, -0.1, back: true, backColor: blue);
      drawCard(c, const Offset(52, 28), 20, 0.1, back: true, backColor: maroon);
      for (var i = 0; i < 13; i++) {
        final a = (i - 6) * 0.08;
        drawCard(c, Offset(50 + 60 * math.sin(a), 130 - 60 * math.cos(a)), 13, a,
            rank: const ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'][i], suit: i % 4);
      }
      _kcBadge(c, const Offset(82, 24), 11, '51');
    case 'kc_asamali': // görev listesi: işaretli aşamalar ve küçük kart simgeleri
      _bg(c, seed, tint: const Color(0xFF355070));
      final sheet = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 12, 72, 78), const Radius.circular(6));
      _shadowRRect(c, sheet);
      c.drawRRect(sheet, _p(_ivory));
      for (var row = 0; row < 4; row++) {
        final y = 24 + row * 18.0;
        final box = Rect.fromCenter(center: Offset(26, y), width: 9, height: 9);
        c.drawRect(box, _stroke(_ink, 1.2));
        if (row < 2) {
          c.drawPath(
              Path()
                ..moveTo(23, y)
                ..lineTo(26, y + 3)
                ..lineTo(31, y - 4),
              _stroke(const Color(0xFF3BA776), 2));
        }
        for (var k = 0; k < row % 3 + 2; k++) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(38 + k * 9.0, y - 6, 7, 11), const Radius.circular(1.5)),
              _p(_pal[(row + k) % 4]));
        }
      }
    case 'kc_kanasta': // yedi sekizlik kanasta yığını ve kenarda kırmızı üçlü
      _bg(c, seed, tint: const Color(0xFF9C6644));
      for (var i = 0; i < 7; i++) {
        drawCard(c, Offset(38, 22 + i * 7.0), 22, 0, rank: '8', suit: i % 4);
      }
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 6, 28, 90), const Radius.circular(5)), _stroke(gold, 1.8));
      drawCard(c, const Offset(74, 50), 22, 0.3, rank: '3', suit: 1);
      _kcStar(c, const Offset(82, 26), 7, 5, gold, inner: 3);
    case 'kc_elayak': // el ve ayak simgeli iki kapalı deste
      _bg(c, seed, tint: const Color(0xFF6D597A));
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(30 + i * 0.7, 66 - i * 1.4), 24, -0.06, back: true);
        drawCard(c, Offset(70 + i * 0.7, 66 - i * 1.4), 24, 0.06, back: true, backColor: maroon);
      }
      c.save();
      c.translate(30, 26);
      c.rotate(math.pi);
      _kcHand(c, Offset.zero, 18, const Color(0xFFF3C9A8));
      c.restore();
      const skin = Color(0xFFF3C9A8);
      c.drawOval(Rect.fromCenter(center: const Offset(70, 28), width: 13, height: 20), _p(skin));
      for (var k = 0; k < 5; k++) {
        c.drawCircle(Offset(64.5 + k * 2.8, 15 + (k - 1.5).abs() * 0.8), 1.8 - k * 0.12, _p(skin));
      }
    case 'kc_cribbage': // delikli ahşap sayı tahtası, renkli çiviler, 5 ve vale
      _bg(c, seed, tint: const Color(0xFF3E5641));
      c.save();
      c.translate(50, 44);
      c.rotate(-0.35);
      final pb = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 92, height: 26), const Radius.circular(8));
      _shadowRRect(c, pb);
      c.drawRRect(pb, Paint()..shader = const LinearGradient(colors: [_woodLight, _wood]).createShader(pb.outerRect));
      for (var row = 0; row < 3; row++) {
        for (var i = 0; i < 15; i++) {
          c.drawCircle(Offset(-38 + i * 5.4, -7 + row * 7.0), 1.1, _p(Colors.black54));
        }
      }
      for (final (i, row, col) in const [(4, 0, Color(0xFFE2574C)), (9, 0, Color(0xFFE2574C)), (7, 2, Color(0xFF3075C4)), (11, 2, Color(0xFF3075C4))]) {
        c.drawCircle(Offset(-38 + i * 5.4, -7 + row * 7.0), 2.2, _p(col));
      }
      c.restore();
      drawCard(c, const Offset(66, 80), 18, 0.15, rank: '5', suit: 1);
      drawCard(c, const Offset(80, 78), 18, 0.3, rank: 'J', suit: 0);
    case 'kc_durak': // saldırı kartlarının üstüne çapraz savunma, kozlu deste
      _bg(c, seed, tint: const Color(0xFF335C67));
      for (var i = 0; i < 3; i++) {
        final o = Offset(22 + i * 28.0, 36);
        drawCard(c, o, 18, 0, rank: const ['6', '9', 'J'][i], suit: i);
        drawCard(c, o + const Offset(5, 6), 18, 0.4, rank: const ['8', 'Q', 'A'][i], suit: i == 1 ? 3 : i);
      }
      drawCard(c, const Offset(56, 80), 20, math.pi / 2, rank: '7', suit: 3);
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(42 + i * 0.6, 80 - i * 1.2), 18, 0, back: true);
      }
    // ---- Gerçek zamanlı -----------------------------------------------------
    case 'kc_snap': // iki eş yedili ve üstten inen el, çarpma çizgileri
      _bg(c, seed, tint: const Color(0xFFE76F51));
      drawCard(c, const Offset(38, 66), 26, -0.15, rank: '7', suit: 0);
      drawCard(c, const Offset(62, 66), 26, 0.15, rank: '7', suit: 1);
      for (var k = 0; k < 5; k++) {
        final a = math.pi + k * math.pi / 4;
        c.drawLine(Offset(50 + 32 * math.cos(a), 62 + 26 * math.sin(a)), Offset(50 + 42 * math.cos(a), 62 + 34 * math.sin(a)),
            _stroke(Colors.white, 2));
      }
      _kcHand(c, const Offset(50, 30), 24, const Color(0xFFF3C9A8));
    case 'kc_hiz': // iki orta yığın ve şimşek
      _bg(c, seed, tint: const Color(0xFF0F4C5C));
      for (final (x, r, s) in const [(30.0, '6', 1), (70.0, '8', 0)]) {
        for (var i = 0; i < 3; i++) {
          drawCard(c, Offset(x, 62), 24, (i - 1) * 0.15, rank: i == 2 ? r : 'A', suit: s);
        }
      }
      c.drawPath(
          Path()..addPolygon(const [Offset(56, 6), Offset(40, 36), Offset(50, 36), Offset(42, 60), Offset(62, 28), Offset(52, 28)], true),
          _p(gold));
    case 'kc_nertz': // iki oyuncunun karşılıklı sabır dizilimi ve kronometre
      _bg(c, seed, tint: const Color(0xFF283D3B));
      for (var col = 0; col < 4; col++) {
        for (var j = 0; j < 2; j++) {
          drawCard(c, Offset(12 + col * 13.0, 16 + j * 7.0), 11, 0, rank: const ['5', '4', '9', '8'][(col + j) % 4], suit: (col + j) % 4);
          drawCard(c, Offset(12 + col * 13.0, 70 + j * 7.0), 11, 0, rank: const ['J', '10', '3', '2'][(col + j) % 4], suit: (col + j + 1) % 4);
        }
      }
      drawCard(c, const Offset(34, 50), 11, math.pi / 2, back: true, backColor: maroon);
      c.drawCircle(const Offset(76, 52), 17, _p(Colors.white));
      c.drawCircle(const Offset(76, 52), 17, _stroke(_ink, 1.6));
      c.drawRect(const Rect.fromLTWH(73, 31, 6, 4), _p(_ink));
      c.drawArc(Rect.fromCircle(center: const Offset(76, 52), radius: 13), -math.pi / 2, math.pi * 1.3, true, _p(_red.withValues(alpha: 0.35)));
      c.drawLine(const Offset(76, 52), const Offset(76, 40), _stroke(_ink, 1.8));
    case 'kc_kemps': // ortada dört kart, değiş-tokuş okları, gizli işaret gözü, dört kız
      _bg(c, seed, tint: const Color(0xFF5F0F40));
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(23 + i * 18.0, 36), 15, 0, rank: const ['3', 'Q', '9', '5'][i], suit: (i * 3) % 4);
      }
      _kcArrow(c, const Offset(40, 52), const Offset(32, 60), gold);
      _kcArrow(c, const Offset(60, 60), const Offset(52, 52), gold);
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(36 + i * 9.0, 78), 15, (i - 1.5) * 0.15, rank: 'Q', suit: i);
      }
      c.drawPath(
          Path()
            ..moveTo(70, 14)
            ..quadraticBezierTo(82, 4, 94, 14)
            ..quadraticBezierTo(82, 24, 70, 14),
          _p(Colors.white));
      c.drawCircle(const Offset(82, 14), 4, _p(const Color(0xFF3075C4)));
      c.drawCircle(const Offset(82, 14), 1.8, _p(_ink));
    // ---- Bulmaca ve hafıza --------------------------------------------------
    case 'kc_kartyolu': // 3x3 kart ızgarasında hepsinden geçen altın yol
      _bg(c, seed, tint: const Color(0xFF2C3E50));
      const order = [(0, 0), (1, 0), (2, 0), (2, 1), (1, 1), (0, 1), (0, 2), (1, 2), (2, 2)];
      final path = Path();
      for (var i = 0; i < order.length; i++) {
        final (x, y) = order[i];
        final o = Offset(22 + x * 28.0, 22 + y * 28.0);
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      c.drawPath(path, _stroke(gold.withValues(alpha: 0.85), 5));
      for (var i = 0; i < order.length; i++) {
        final (x, y) = order[i];
        drawCard(c, Offset(22 + x * 28.0, 22 + y * 28.0), 13, 0, rank: const ['A', '2', '3', '4', '5', '6', '7', '8', '9'][i], suit: i % 4);
      }
      _kcArrow(c, const Offset(80, 86), const Offset(94, 86), gold);
    case 'kc_kartkaresi': // 3x3 kart karesi, satır ve sütun toplam rozetleri
      _bg(c, seed, tint: const Color(0xFF3D2C8D));
      const v = [3, 7, 5, 9, 1, 4, 2, 6, 8];
      for (var i = 0; i < 9; i++) {
        drawCard(c, Offset(20 + (i % 3) * 20.0, 20 + (i ~/ 3) * 24.0), 14, 0, rank: '${v[i]}', suit: i % 4);
      }
      for (var k = 0; k < 3; k++) {
        _kcBadge(c, Offset(84, 20 + k * 24.0), 6.5, '${v[k * 3] + v[k * 3 + 1] + v[k * 3 + 2]}');
        _kcBadge(c, Offset(20 + k * 20.0, 88), 6.5, '${v[k] + v[k + 3] + v[k + 6]}', fill: const Color(0xFF9ED8F5));
      }
    default:
      return false;
  }
  return true;
}

/// Boş kart yuvası (temel, boş hücre).
void _kcSlot(Canvas c, Offset o, double w, {Color col = Colors.white54}) {
  final r = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: w * 1.4), Radius.circular(w * 0.12));
  c.drawRRect(r, _p(Colors.black.withValues(alpha: 0.14)));
  c.drawRRect(r, _stroke(col, 1));
}

/// Yuvarlak rozet (puan, ihale).
void _kcBadge(Canvas c, Offset o, double r, String s, {Color fill = const Color(0xFFF5B82E), Color ink = _ink}) {
  c.drawCircle(o + const Offset(0, 1.4), r, _p(Colors.black26));
  c.drawCircle(o, r, _p(fill));
  c.drawCircle(o, r - 1.6, _stroke(Colors.white70, 0.9));
  _text(c, s, o, r * (s.length > 2 ? 0.62 : (s.length == 2 ? 0.9 : 1.1)), ink);
}

/// Boş yüzlü kart; [icon] kartın merkezine göre (0,0) çizilir.
void _kcFace(Canvas c, Offset o, double w, double a, void Function() icon, {double hr = 1.4}) {
  final h = w * hr;
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(a);
  final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), Radius.circular(w * 0.12));
  _shadowRRect(c, r, dy: w * 0.06, a: 0.3);
  c.drawRRect(r, _p(_ivory));
  c.drawRRect(r, _stroke(Colors.black.withValues(alpha: 0.12), w * 0.02));
  icon();
  c.restore();
}

/// İtalyan destesinin takım simgeleri (0 altın, 1 kupa, 2 kılıç, 3 sopa), (0,0) merkezli.
void _kcItalian(Canvas c, int suit, double s) {
  switch (suit % 4) {
    case 0:
      c.drawCircle(Offset.zero, s * 0.55, _p(const Color(0xFFE9B949)));
      c.drawCircle(Offset.zero, s * 0.4, _stroke(const Color(0xFFB07A12), s * 0.08));
      c.drawCircle(Offset.zero, s * 0.12, _p(const Color(0xFFB07A12)));
    case 1:
      final cup = Path()
        ..moveTo(-s * 0.5, -s * 0.5)
        ..lineTo(s * 0.5, -s * 0.5)
        ..quadraticBezierTo(s * 0.5, s * 0.1, 0, s * 0.15)
        ..quadraticBezierTo(-s * 0.5, s * 0.1, -s * 0.5, -s * 0.5)
        ..close();
      c.drawPath(cup, _p(_red));
      c.drawRect(Rect.fromLTWH(-s * 0.06, s * 0.15, s * 0.12, s * 0.35), _p(_red));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-s * 0.3, s * 0.48, s * 0.6, s * 0.12), Radius.circular(s * 0.05)), _p(_red));
    case 2:
      c.drawLine(Offset(0, -s * 0.7), Offset(0, s * 0.45), _stroke(const Color(0xFF3075C4), s * 0.16));
      c.drawLine(Offset(-s * 0.32, s * 0.35), Offset(s * 0.32, s * 0.35), _stroke(const Color(0xFFB07A12), s * 0.14));
      c.drawLine(Offset(0, s * 0.4), Offset(0, s * 0.7), _stroke(_wood, s * 0.14));
    default:
      c.save();
      c.rotate(0.5);
      c.drawLine(Offset(0, -s * 0.65), Offset(0, s * 0.65), _stroke(const Color(0xFF3BA776), s * 0.26));
      for (final y in [-0.3, 0.1, 0.45]) {
        c.drawCircle(Offset(s * 0.12, y * s), s * 0.07, _p(const Color(0xFF1F6B4A)));
      }
      c.restore();
  }
}

/// Basit taç.
void _kcCrown(Canvas c, Offset o, double s, Color col) {
  final p = Path()
    ..moveTo(o.dx - s, o.dy + s * 0.5)
    ..lineTo(o.dx - s, o.dy - s * 0.45)
    ..lineTo(o.dx - s * 0.5, o.dy)
    ..lineTo(o.dx, o.dy - s * 0.65)
    ..lineTo(o.dx + s * 0.5, o.dy)
    ..lineTo(o.dx + s, o.dy - s * 0.45)
    ..lineTo(o.dx + s, o.dy + s * 0.5)
    ..close();
  c.drawPath(p.shift(const Offset(0, 1.2)), _p(Colors.black26));
  c.drawPath(p, _p(col));
  c.drawPath(p, _stroke(Colors.black.withValues(alpha: 0.25), 0.8));
  for (final dx in const [-1.0, 0.0, 1.0]) {
    c.drawCircle(Offset(o.dx + dx * s * 0.5, o.dy + s * 0.22), s * 0.1, _p(_red));
  }
}

/// Yıldız / patlama: [n] köşe, [r] dış, [inner] iç yarıçap.
void _kcStar(Canvas c, Offset o, double r, int n, Color col, {double? inner}) {
  final ri = inner ?? r * 0.45;
  final path = Path();
  for (var i = 0; i < n * 2; i++) {
    final a = -math.pi / 2 + i * math.pi / n;
    final rr = i.isEven ? r : ri;
    final pt = Offset(o.dx + rr * math.cos(a), o.dy + rr * math.sin(a));
    i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
  }
  path.close();
  c.drawPath(path, _p(col));
}

/// Uçlu ok.
void _kcArrow(Canvas c, Offset a, Offset b, Color col) {
  c.drawLine(a, b, _stroke(col, 2.2));
  final d = b - a;
  final u = d / d.distance;
  final n = Offset(-u.dy, u.dx);
  c.drawPath(Path()..addPolygon([b + u * 3, b - u * 3 + n * 3.4, b - u * 3 - n * 3.4], true), _p(col));
}

/// Poker fişi.
void _kcChip(Canvas c, Offset o, double r, Color col, String s) {
  c.drawCircle(o + const Offset(0, 1.6), r, _p(Colors.black38));
  c.drawCircle(o, r, _p(col));
  for (var k = 0; k < 6; k++) {
    final a = k * math.pi / 3;
    c.drawLine(o + Offset(r * 0.72 * math.cos(a), r * 0.72 * math.sin(a)), o + Offset(r * math.cos(a), r * math.sin(a)),
        _stroke(Colors.white, r * 0.22));
  }
  c.drawCircle(o, r * 0.55, _p(Colors.white));
  _text(c, s, o, r * 0.8, _ink);
}

/// Avuç içi aşağı bakan el.
void _kcHand(Canvas c, Offset o, double s, Color col) {
  final p = _p(col);
  final edge = _stroke(Colors.black.withValues(alpha: 0.25), 0.8);
  final palm = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: s * 0.8, height: s * 0.7), Radius.circular(s * 0.2));
  c.drawRRect(palm, p);
  c.drawRRect(palm, edge);
  for (var k = 0; k < 4; k++) {
    final f = RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx - s * 0.38 + k * s * 0.2, o.dy + s * 0.2, s * 0.16, s * (0.42 - (k - 1.5).abs() * 0.06)),
        Radius.circular(s * 0.08));
    c.drawRRect(f, p);
    c.drawRRect(f, edge);
  }
  final t = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + s * 0.32, o.dy - s * 0.05, s * 0.3, s * 0.15), Radius.circular(s * 0.07));
  c.drawRRect(t, p);
  c.drawRRect(t, edge);
}

/// İsviçre destesi çanı, (0,0) merkezli.
void _kcBell(Canvas c, double s) {
  final p = Path()
    ..moveTo(-s * 0.6, s * 0.45)
    ..quadraticBezierTo(-s * 0.5, -s * 0.7, 0, -s * 0.7)
    ..quadraticBezierTo(s * 0.5, -s * 0.7, s * 0.6, s * 0.45)
    ..close();
  c.drawPath(p, _p(const Color(0xFFE9B949)));
  c.drawCircle(Offset(0, s * 0.55), s * 0.16, _p(const Color(0xFFB07A12)));
}

/// İsviçre destesi meşe palamudu, (0,0) merkezli.
void _kcAcorn(Canvas c, double s) {
  c.drawOval(Rect.fromCenter(center: Offset(0, s * 0.15), width: s * 0.8, height: s * 1.0), _p(const Color(0xFFC08A5A)));
  c.drawArc(Rect.fromCenter(center: Offset(0, -s * 0.2), width: s * 1.0, height: s * 0.7), math.pi, math.pi, true, _p(const Color(0xFF5C3A20)));
  c.drawLine(Offset(0, -s * 0.55), Offset(s * 0.1, -s * 0.8), _stroke(const Color(0xFF5C3A20), s * 0.12));
}
