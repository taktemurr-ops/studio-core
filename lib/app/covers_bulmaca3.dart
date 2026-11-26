part of 'covers.dart';

/// Bulmaca ve Sayı merkezi, 3. kısım: sıralama, kaydırma ve yol oyunları ile
/// klasik zekâ oyunları. Yardımcılar covers_bulmaca1.dart dosyasında.
/// Döndürür: çizildiyse true.
bool _paintBulmaca3Cover(Canvas c, GameCover cover, Color seed) {
  switch (cover.kind) {
    case 'bz_watersort':
      _bzWaterSort(c);
    case 'bz_ballsort':
      _bzBallSort(c);
    case 'bz_nuts':
      _bzNuts(c);
    case 'bz_hexstack':
      _bzHexStack(c);
    case 'bz_arrowout':
      _bzArrowOut(c);
    case 'bz_blockout':
      _bzBlockOut(c);
    case 'bz_klotski':
      _bzKlotski(c);
    case 'bz_parking':
      _bzParking(c);
    case 'bz_bus':
      _bzBus(c);
    case 'bz_picslide':
      _bzPicSlide(c);
    case 'bz_iceslide':
      _bzIceSlide(c);
    case 'bz_inertia':
      _bzInertia(c);
    case 'bz_sokoban':
      _bzSokoban(c);
    case 'bz_labyrinth':
      _bzLabyrinth(c);
    case 'bz_twiddle':
      _bzTwiddle(c);
    case 'bz_netslide':
      _bzNetSlide(c);
    case 'bz_netrotate':
      _bzNetRotate(c);
    case 'bz_flow':
      _bzFlow(c);
    case 'bz_oneline':
      _bzOneLine(c);
    case 'bz_lightsout':
      _bzLightsOut(c);
    case 'bz_flip':
      _bzFlip(c);
    case 'bz_knightqueen':
      _bzKnightQueen(c);
    case 'bz_codebreak':
      _bzCodeBreak(c);
    case 'bz_twistcube':
      _bzTwistCube(c);
    case 'bz_drawline':
      _bzDrawLine(c);
    case 'bz_ropes':
      _bzRopes(c);
    case 'bz_untangle':
      _bzUntangle(c);
    case 'bz_pegjump':
      _bzPegJump(c);
    default:
      return false;
  }
  return true;
}

const _bzLiquid = [Color(0xFFE2574C), Color(0xFF3075C4), Color(0xFFF2C14E), Color(0xFF3BA776), Color(0xFF9763BC), Color(0xFFF08A4B)];

// ---- Sıralama, kaydırma ve yol ----------------------------------------------

void _bzWaterSort(Canvas c) {
  _bzBg(c, const Color(0xFF2A4F9E));
  void tube(Offset base, double a, List<int> layers, {double fill = 1}) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(a);
    final glass = RRect.fromRectAndCorners(const Rect.fromLTWH(-7, -56, 14, 56),
        bottomLeft: const Radius.circular(7), bottomRight: const Radius.circular(7));
    c.drawRRect(glass, _p(Colors.white.withValues(alpha: 0.16)));
    c.save();
    c.clipRRect(glass);
    for (var i = 0; i < layers.length; i++) {
      final h = 12.0 * (i == layers.length - 1 ? fill : 1);
      c.drawRect(Rect.fromLTWH(-7, -12.0 * (i + 1) + (12 - h), 14, h), _p(_bzLiquid[layers[i]]));
    }
    c.restore();
    c.drawRRect(glass, _stroke(Colors.white, 1.3));
    c.drawLine(const Offset(-4, -50), const Offset(-4, -10), _stroke(Colors.white38, 1.2));
    c.restore();
  }

  tube(const Offset(18, 90), 0, [0, 1, 2, 1]);
  tube(const Offset(38, 90), 0, [2, 3, 3]);
  tube(const Offset(58, 90), 0, [0, 0]);
  // dökülen tüp
  tube(const Offset(84, 50), -1.9, [3, 0], fill: 0.7);
  c.drawPath(Path()..moveTo(64, 34)..quadraticBezierTo(60, 44, 58, 58), _stroke(_bzLiquid[0], 3));
}

void _bzBallSort(Canvas c) {
  _bzBg(c, const Color(0xFF7A3FA0));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 84, 84, 8), const Radius.circular(3)), _p(_woodLight));
  for (var t = 0; t < 4; t++) {
    final x = 20.0 + t * 20;
    final r = RRect.fromRectAndCorners(Rect.fromLTWH(x - 8, 38, 16, 47), bottomLeft: const Radius.circular(8), bottomRight: const Radius.circular(8));
    c.drawRRect(r, _p(Colors.white.withValues(alpha: 0.14)));
    const balls = [
      [0, 1, 0],
      [1, 2, 1, 2],
      [2, 0],
      [3, 3, 3],
    ];
    for (var i = 0; i < balls[t].length; i++) {
      _stone(c, Offset(x, 77 - i * 12.5), 6, _pal[balls[t][i] == 3 ? 5 : balls[t][i]]);
    }
    c.drawRRect(r, _stroke(Colors.white70, 1.2));
  }
  // havadaki top ve yay
  _stone(c, const Offset(60, 22), 6.5, _pal[0]);
  final arc = Path()..moveTo(60, 14)..quadraticBezierTo(70, 4, 80, 28);
  for (final m in arc.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += 4) {
      c.drawPath(m.extractPath(d, d + 2), _stroke(Colors.white70, 1.3));
    }
  }
}

void _bzNuts(Canvas c) {
  _bzBg(c, const Color(0xFF56606E));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 82, 84, 10), const Radius.circular(3)), _p(_wood));
  const nutCols = [Color(0xFFE2574C), Color(0xFF3BA776), Color(0xFFF2A93B), Color(0xFF3075C4)];
  const stacks = [
    [0, 1, -1, -1],
    [2, 2, 0],
    [1, 3, 3, 3],
  ];
  for (var s = 0; s < 3; s++) {
    final x = 24.0 + s * 26;
    // dişli çubuk
    c.drawRect(Rect.fromLTWH(x - 2.4, 26, 4.8, 57), _p(const Color(0xFFB8C0CC)));
    for (var y = 28.0; y < 82; y += 3) {
      c.drawLine(Offset(x - 2.4, y), Offset(x + 2.4, y + 1.4), _stroke(const Color(0xFF7D8794), 0.6));
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, 25), width: 12, height: 4), const Radius.circular(1.5)),
        _p(const Color(0xFF9AA3AF)));
    for (var i = 0; i < stacks[s].length; i++) {
      final k = stacks[s][i];
      final r = Rect.fromCenter(center: Offset(x, 76 - i * 11), width: 20, height: 9);
      final p = Path()
        ..moveTo(r.left + 3, r.top)
        ..lineTo(r.right - 3, r.top)
        ..lineTo(r.right, r.center.dy)
        ..lineTo(r.right - 3, r.bottom)
        ..lineTo(r.left + 3, r.bottom)
        ..lineTo(r.left, r.center.dy)
        ..close();
      final col = k < 0 ? const Color(0xFF8A919E) : nutCols[k];
      c.drawPath(p.shift(const Offset(0, 1.2)), _p(Colors.black38));
      c.drawPath(p, _p(col));
      c.drawLine(Offset(r.left + 6, r.top + 1), Offset(r.left + 6, r.bottom - 1), _stroke(Colors.black.withValues(alpha: 0.18), 0.8));
      c.drawLine(Offset(r.right - 6, r.top + 1), Offset(r.right - 6, r.bottom - 1), _stroke(Colors.black.withValues(alpha: 0.18), 0.8));
      if (k < 0) _text(c, '?', r.center, 6.5, Colors.white);
    }
  }
}

void _bzHexStack(Canvas c) {
  _bzBg(c, const Color(0xFF2E7F7A));
  // zemin altıgen ızgarası
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 4; x++) {
      final o = Offset(20 + x * 20 + (y.isOdd ? 10 : 0), 34 + y * 22);
      c.drawPath(_bzHexPath(o, 11), _p(Colors.white.withValues(alpha: 0.12)));
      c.drawPath(_bzHexPath(o, 11), _stroke(Colors.white24, 0.8));
    }
  }
  void stack(Offset o, List<int> cols) {
    for (var i = 0; i < cols.length; i++) {
      final p = o - Offset(0, i * 3.2);
      final hex = Path()..addOval(Rect.fromCenter(center: p, width: 18, height: 10));
      c.drawPath(hex.shift(const Offset(0, 2.6)), _p(Color.lerp(_pal[cols[i]], Colors.black, 0.35)!));
      c.drawPath(hex, _p(_pal[cols[i]]));
      c.drawPath(hex, _stroke(Colors.white30, 0.6));
    }
  }

  stack(const Offset(40, 37), const [1, 1, 2, 2, 2]);
  stack(const Offset(70, 58), const [0, 0, 0, 5]);
  stack(const Offset(30, 81), const [3, 3, 3, 3, 3, 3]);
  stack(const Offset(60, 82), const [2, 4]);
  _bzArrow(c, const Offset(48, 30), const Offset(64, 48), Colors.white, 1.6);
}

void _bzArrowOut(Canvas c) {
  _bzBg(c, const Color(0xFF3A6BD1));
  const g = Rect.fromLTWH(14, 22, 64, 64);
  c.drawRRect(RRect.fromRectAndRadius(g.inflate(3), const Radius.circular(6)), _p(Colors.white.withValues(alpha: 0.12)));
  void arrowBlock(int x, int y, int len, int dir, Color col, {Offset shift = Offset.zero}) {
    final horiz = dir.isEven;
    final a = _bzCell(g, 4, 4, x, y);
    final b = _bzCell(g, 4, 4, horiz ? x + len - 1 : x, horiz ? y : y + len - 1);
    final r = a.expandToInclude(b).deflate(2.2).shift(shift);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
    c.drawRRect(rr.shift(const Offset(0, 1.2)), _p(Colors.black26));
    c.drawRRect(rr, _p(col));
    const v = [Offset(1, 0), Offset(0, 1), Offset(-1, 0), Offset(0, -1)];
    final d = v[dir];
    final half = (horiz ? r.width : r.height) / 2 - 4;
    _bzArrow(c, r.center - d * half, r.center + d * half, Colors.white, 1.6);
  }

  arrowBlock(0, 0, 2, 0, const Color(0xFFF2A93B));
  arrowBlock(2, 0, 2, 1, const Color(0xFF3BA776));
  arrowBlock(0, 1, 3, 1, const Color(0xFFE2574C));
  arrowBlock(1, 2, 2, 2, const Color(0xFF9763BC));
  arrowBlock(3, 2, 2, 3, const Color(0xFF2BB3B1));
  arrowBlock(1, 3, 2, 0, const Color(0xFFF2A93B), shift: const Offset(20, 0));
  // uçan ok ve hız çizgileri
  for (var i = 0; i < 3; i++) {
    c.drawLine(Offset(70 + i * 3.0, 74 + i * 2.5), Offset(80 + i * 3.0, 74 + i * 2.5), _stroke(Colors.white54, 1));
  }
}

void _bzBlockOut(Canvas c) {
  _bzBg(c, const Color(0xFFD2603A));
  const g = Rect.fromLTWH(16, 16, 64, 64);
  c.drawRRect(RRect.fromRectAndRadius(g.inflate(4), const Radius.circular(6)), _p(const Color(0xFF5A2A1A)));
  c.drawRect(g, _p(const Color(0xFFF3E2D3)));
  _bzLines(c, g, 4, 4, _stroke(Colors.black12, 0.6));
  // renkli çıkış kapıları
  c.drawRect(Rect.fromLTWH(g.right, _bzCell(g, 4, 4, 0, 1).top + 2, 4, 28), _p(const Color(0xFF3075C4)));
  c.drawRect(Rect.fromLTWH(_bzCell(g, 4, 4, 1, 0).left + 2, g.top - 4, 28, 4), _p(const Color(0xFF3BA776)));
  c.drawRect(Rect.fromLTWH(g.left - 4, _bzCell(g, 4, 4, 0, 3).top + 2, 4, 12), _p(const Color(0xFFF2C14E)));
  void block(List<(int, int)> cells, Color col, {Offset shift = Offset.zero}) {
    for (final (x, y) in cells) {
      final r = RRect.fromRectAndRadius(_bzCell(g, 4, 4, x, y).deflate(1.2).shift(shift), const Radius.circular(3));
      c.drawRRect(r.shift(const Offset(0, 1.3)), _p(Colors.black26));
      c.drawRRect(r, _p(col));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 2, r.top + 2, r.width - 4, 3), const Radius.circular(1.5)), _p(Colors.white30));
    }
  }

  block(const [(2, 1), (3, 1), (3, 2)], const Color(0xFF3075C4), shift: const Offset(8, 0));
  block(const [(1, 0), (1, 1)], const Color(0xFF3BA776));
  block(const [(0, 3), (1, 3)], const Color(0xFFF2C14E));
  block(const [(0, 1), (0, 2)], const Color(0xFF9763BC));
  block(const [(2, 3)], const Color(0xFFE2574C));
  _bzArrow(c, const Offset(84, 30), const Offset(94, 30), Colors.white, 1.6);
}

void _bzKlotski(Canvas c) {
  _bzBg(c, const Color(0xFF7A5230));
  const g = Rect.fromLTWH(22, 10, 56, 70);
  _woodBoard(c, g.inflate(4));
  c.drawRect(g, _p(const Color(0xFF3A2616)));
  // çıkış ağzı
  c.drawRect(Rect.fromLTWH(_bzCell(g, 4, 5, 1, 4).left + 1, g.bottom - 1, 26, 6), _p(const Color(0xFF3A2616)));
  void piece(int x, int y, int w, int h, Color col) {
    final r = RRect.fromRectAndRadius(
        _bzCell(g, 4, 5, x, y).expandToInclude(_bzCell(g, 4, 5, x + w - 1, y + h - 1)).deflate(1.4), const Radius.circular(3));
    c.drawRRect(r.shift(const Offset(0, 1.2)), _p(Colors.black38));
    c.drawRRect(r, _p(col));
    c.drawRRect(r.deflate(1.6), _stroke(Colors.white24, 0.8));
  }

  piece(1, 1, 2, 2, const Color(0xFFD23C3C));
  piece(0, 0, 1, 2, const Color(0xFFE9C46A));
  piece(3, 0, 1, 2, const Color(0xFFE9C46A));
  piece(0, 2, 1, 2, const Color(0xFFE9C46A));
  piece(3, 2, 1, 2, const Color(0xFFE9C46A));
  piece(1, 0, 2, 1, const Color(0xFFF4A261));
  piece(1, 3, 1, 1, const Color(0xFF8AB17D));
  piece(2, 3, 1, 1, const Color(0xFF8AB17D));
  piece(0, 4, 1, 1, const Color(0xFF8AB17D));
  piece(3, 4, 1, 1, const Color(0xFF8AB17D));
  _bzArrow(c, const Offset(50, 84), const Offset(50, 96), Colors.white, 1.8);
}

void _bzTopCar(Canvas c, Rect r, Color col) {
  final horiz = r.width > r.height;
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
  // tekerlekler
  final wp = _p(const Color(0xFF15181E));
  if (horiz) {
    for (final x in [r.left + 4, r.right - 7]) {
      c.drawRect(Rect.fromLTWH(x, r.top - 1.2, 3.2, 2), wp);
      c.drawRect(Rect.fromLTWH(x, r.bottom - 0.8, 3.2, 2), wp);
    }
  } else {
    for (final y in [r.top + 4, r.bottom - 7]) {
      c.drawRect(Rect.fromLTWH(r.left - 1.2, y, 2, 3.2), wp);
      c.drawRect(Rect.fromLTWH(r.right - 0.8, y, 2, 3.2), wp);
    }
  }
  c.drawRRect(rr.shift(const Offset(0, 1.4)), _p(Colors.black38));
  c.drawRRect(rr, _p(col));
  final glass = _p(const Color(0xFFBFE3F5));
  if (horiz) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.right - r.width * 0.36, r.top + 2, r.width * 0.14, r.height - 4), const Radius.circular(1.5)), glass);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + r.width * 0.16, r.top + 2.5, r.width * 0.1, r.height - 5), const Radius.circular(1.5)), glass);
  } else {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 2, r.top + r.height * 0.22, r.width - 4, r.height * 0.14), const Radius.circular(1.5)), glass);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 2.5, r.bottom - r.height * 0.26, r.width - 5, r.height * 0.1), const Radius.circular(1.5)), glass);
  }
}

void _bzParking(Canvas c) {
  _bzBg(c, const Color(0xFF3C4350));
  const g = Rect.fromLTWH(10, 10, 78, 78);
  c.drawRRect(RRect.fromRectAndRadius(g, const Radius.circular(4)), _p(const Color(0xFF2A2F38)));
  final dash = _stroke(Colors.white24, 0.8);
  for (var i = 1; i < 6; i++) {
    c.drawLine(Offset(g.left + i * 13, g.top + 2), Offset(g.left + i * 13, g.bottom - 2), dash);
  }
  // çıkış
  c.drawRect(Rect.fromLTWH(g.right - 1, 36, 12, 13), _p(const Color(0xFF2A2F38)));
  _bzArrow(c, const Offset(89, 42.5), const Offset(98, 42.5), _bzGold, 1.6);
  _bzTopCar(c, const Rect.fromLTWH(14, 37, 26, 11), const Color(0xFFD23C3C));
  _bzTopCar(c, const Rect.fromLTWH(46, 14, 11, 36), const Color(0xFFF2C14E));
  _bzTopCar(c, const Rect.fromLTWH(62, 30, 11, 26), const Color(0xFF3075C4));
  _bzTopCar(c, const Rect.fromLTWH(14, 62, 38, 12), const Color(0xFF3BA776));
  _bzTopCar(c, const Rect.fromLTWH(74, 58, 11, 26), const Color(0xFF9763BC));
  _bzTopCar(c, const Rect.fromLTWH(14, 16, 24, 11), const Color(0xFFF08A4B));
}

void _bzBus(Canvas c) {
  _bzBg(c, const Color(0xFF2D8F5E));
  // yol
  c.drawRect(const Rect.fromLTWH(0, 62, 100, 22), _p(const Color(0xFF3C4350)));
  for (var x = 4.0; x < 100; x += 14) {
    c.drawRect(Rect.fromLTWH(x, 72.5, 7, 1.4), _p(Colors.white54));
  }
  // otobüs
  final body = RRect.fromRectAndRadius(const Rect.fromLTWH(8, 34, 58, 30), const Radius.circular(6));
  c.drawRRect(body.shift(const Offset(0, 2)), _p(Colors.black26));
  c.drawRRect(body, _p(const Color(0xFFF2C14E)));
  c.drawRect(const Rect.fromLTWH(8, 54, 58, 3), _p(const Color(0xFFE2574C)));
  const riders = [0, 1, 0, 3];
  for (var i = 0; i < 4; i++) {
    final w = Rect.fromLTWH(12 + i * 12.5, 38, 10, 12);
    c.drawRRect(RRect.fromRectAndRadius(w, const Radius.circular(2)), _p(const Color(0xFFBFE3F5)));
    if (i < 3) {
      c.drawCircle(w.center + const Offset(0, 1), 3, _p(_pal[riders[i]]));
      c.drawRect(Rect.fromLTWH(w.left + 2, w.bottom - 3, 6, 3), _p(_pal[riders[i]]));
    }
  }
  for (final x in [20.0, 54.0]) {
    c.drawCircle(Offset(x, 64), 5, _p(const Color(0xFF15181E)));
    c.drawCircle(Offset(x, 64), 2, _p(const Color(0xFFB0B7C3)));
  }
  // durakta bekleyen renkli yolcular
  for (var i = 0; i < 4; i++) {
    final o = Offset(74 + (i % 2) * 10, 30 + (i ~/ 2) * 16);
    final col = _pal[const [3, 0, 1, 3][i]];
    c.drawCircle(o, 3.2, _p(col));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - 3.5, o.dy + 3.4, 7, 7), const Radius.circular(2.5)), _p(col));
  }
  c.drawRect(const Rect.fromLTWH(92, 18, 2, 44), _p(Colors.white70));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(86, 12, 12, 8), const Radius.circular(2)), _p(Colors.white));
}

void _bzPicSlide(Canvas c) {
  _bzBg(c, const Color(0xFF3A86C8));
  const g = Rect.fromLTWH(14, 14, 72, 72);
  // resmin kendisi (karolara bölünüp karıştırılır)
  void scene(Canvas c) {
    c.drawRect(
        g,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8FD3FF), Color(0xFFFFE3B3)])
              .createShader(g));
    c.drawCircle(const Offset(66, 32), 9, _p(const Color(0xFFFFC94A)));
    c.drawPath(Path()..addPolygon(const [Offset(14, 74), Offset(38, 42), Offset(58, 74)], true), _p(const Color(0xFF4F7CAC)));
    c.drawPath(Path()..addPolygon(const [Offset(40, 76), Offset(66, 50), Offset(86, 76)], true), _p(const Color(0xFF3B6B8F)));
    c.drawRect(const Rect.fromLTWH(14, 72, 72, 14), _p(const Color(0xFF3BA776)));
  }

  const perm = [0, 1, 2, 3, 5, 8, 6, 4, -1];
  for (var i = 0; i < 9; i++) {
    final src = perm[i];
    final dst = _bzCell(g, 3, 3, i % 3, i ~/ 3).deflate(1);
    if (src < 0) {
      c.drawRect(dst, _p(Colors.black.withValues(alpha: 0.25)));
      continue;
    }
    final from = _bzCell(g, 3, 3, src % 3, src ~/ 3);
    c.save();
    c.clipRect(dst);
    c.translate(dst.left - from.left - 1, dst.top - from.top - 1);
    scene(c);
    c.restore();
    c.drawRect(dst, _stroke(Colors.white, 1));
  }
  _bzArrow(c, _bzCell(g, 3, 3, 1, 2).center, _bzCell(g, 3, 3, 2, 2).center - const Offset(4, 0), Colors.white, 1.8);
}

void _bzIceSlide(Canvas c) {
  _bzBg(c, const Color(0xFF3C8DBC));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final r = _bzCell(g, 5, 5, x, y).deflate(0.6);
      c.drawRect(r, _p(Color.lerp(const Color(0xFFDDF3FF), const Color(0xFFB8E2F8), ((x + y) % 3) / 2)!));
      c.drawLine(r.topLeft + const Offset(3, 9), r.topLeft + const Offset(9, 3), _stroke(Colors.white, 1));
    }
  }
  // kayalar
  for (final (x, y) in const [(4, 1), (1, 3), (3, 4)]) {
    final o = _bzCell(g, 5, 5, x, y).center;
    c.drawPath(Path()..addPolygon([o + const Offset(-6, 5), o + const Offset(-4, -3), o + const Offset(1, -6), o + const Offset(6, -1), o + const Offset(6, 5)], true),
        _p(const Color(0xFF6B7684)));
  }
  // çıkış bayrağı
  final f = _bzCell(g, 5, 5, 4, 4).center;
  c.drawLine(f + const Offset(-2, 6), f + const Offset(-2, -6), _stroke(_bzNavy, 1.2));
  c.drawPath(Path()..addPolygon([f + const Offset(-2, -6), f + const Offset(6, -3), f + const Offset(-2, 0)], true), _p(const Color(0xFFE2574C)));
  // kayan karakter ve iz
  final from = _bzCell(g, 5, 5, 0, 1).center, to = _bzCell(g, 5, 5, 3, 1).center;
  for (var i = 0; i < 3; i++) {
    c.drawLine(from + Offset(0, -4 + i * 4.0), to + Offset(-8, -4 + i * 4.0), _stroke(Colors.white, 1.2));
  }
  c.drawOval(Rect.fromCenter(center: to + const Offset(0, 6), width: 12, height: 3), _p(Colors.black12));
  c.drawCircle(to, 6.5, _p(const Color(0xFF1B2433)));
  c.drawOval(Rect.fromCenter(center: to + const Offset(0, 1.5), width: 8, height: 8.5), _p(Colors.white));
  c.drawCircle(to + const Offset(-1.8, -1.5), 0.9, _p(_bzNavy));
  c.drawCircle(to + const Offset(1.8, -1.5), 0.9, _p(_bzNavy));
  c.drawPath(Path()..addPolygon([to + const Offset(-1.4, 0.4), to + const Offset(1.4, 0.4), to + const Offset(0, 2.4)], true), _p(const Color(0xFFF2A93B)));
}

void _bzInertia(Canvas c) {
  _bzBg(c, const Color(0xFF2E2A4F));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  c.drawRect(g, _p(const Color(0xFF1E1B36)));
  _bzLines(c, g, 6, 6, _stroke(Colors.white10, 0.6));
  // duraklar
  for (final (x, y) in const [(4, 1), (1, 4)]) {
    final r = _bzCell(g, 6, 6, x, y).deflate(3);
    c.drawRect(r, _stroke(Colors.white54, 1));
  }
  // duvarlar
  for (final (x, y) in const [(5, 0), (0, 2), (3, 5)]) {
    c.drawRect(_bzCell(g, 6, 6, x, y).deflate(0.6), _p(const Color(0xFF5A5480)));
  }
  // mücevherler
  for (final (x, y, k) in const [(2, 2, 1), (4, 4, 4), (5, 3, 5), (1, 0, 2)]) {
    final o = _bzCell(g, 6, 6, x, y).center;
    c.drawPath(Path()..addPolygon([o + const Offset(0, -5), o + const Offset(4.4, 0), o + const Offset(0, 5), o + const Offset(-4.4, 0)], true), _p(_pal[k]));
    c.drawPath(Path()..addPolygon([o + const Offset(0, -5), o + const Offset(4.4, 0), o + const Offset(0, 0)], true), _p(Colors.white30));
  }
  // mayınlar
  for (final (x, y) in const [(3, 1), (0, 5)]) {
    final o = _bzCell(g, 6, 6, x, y).center;
    for (var k = 0; k < 4; k++) {
      c.drawLine(o + Offset.fromDirection(k * math.pi / 4, 5.4), o - Offset.fromDirection(k * math.pi / 4, 5.4), _stroke(const Color(0xFFE2574C), 1.2));
    }
    c.drawCircle(o, 3.4, _p(const Color(0xFFE2574C)));
  }
  // çapraz kayan top
  final a = _bzCell(g, 6, 6, 0, 0).center, b = _bzCell(g, 6, 6, 2, 2).center;
  c.drawLine(a, b, _stroke(_bzCyan.withValues(alpha: 0.4), 5));
  _stone(c, b + const Offset(-6.3, -6.3), 4.6, _bzCyan);
}

void _bzSokoban(Canvas c) {
  _bzBg(c, const Color(0xFF5C3A2A));
  const g = Rect.fromLTWH(10, 10, 80, 80);
  const map = ['#####', '#..o#', '#.B.#', '#@.B#', '#####'];
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final r = _bzCell(g, 5, 5, x, y);
      if (map[y][x] == '#') {
        c.drawRect(r, _p(const Color(0xFF8A4B32)));
        final m = _stroke(const Color(0xFF5C2E1C), 0.8);
        c.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), m);
        c.drawLine(Offset(r.left + r.width * (y.isEven ? 0.5 : 0.25), r.top), Offset(r.left + r.width * (y.isEven ? 0.5 : 0.25), r.center.dy), m);
        c.drawLine(Offset(r.left + r.width * (y.isEven ? 0.25 : 0.75), r.center.dy), Offset(r.left + r.width * (y.isEven ? 0.25 : 0.75), r.bottom), m);
      } else {
        c.drawRect(r, _p(const Color(0xFFE8D8BC)));
        c.drawRect(r, _stroke(const Color(0xFFD3BF9D), 0.5));
      }
    }
  }
  // hedefler
  for (final (x, y) in const [(3, 1), (1, 1)]) {
    c.drawCircle(_bzCell(g, 5, 5, x, y).center, 5, _stroke(const Color(0xFFE2574C), 1.6));
    c.drawCircle(_bzCell(g, 5, 5, x, y).center, 1.6, _p(const Color(0xFFE2574C)));
  }
  // kasalar
  for (final (x, y) in const [(2, 2), (3, 3)]) {
    final r = _bzCell(g, 5, 5, x, y).deflate(2);
    c.drawRect(r.shift(const Offset(0, 1.3)), _p(Colors.black26));
    c.drawRect(r, _p(const Color(0xFFD9A066)));
    c.drawRect(r.deflate(1), _stroke(const Color(0xFF8A5A36), 1.3));
    c.drawLine(r.topLeft + const Offset(1, 1), r.bottomRight - const Offset(1, 1), _stroke(const Color(0xFF8A5A36), 1.3));
    c.drawLine(r.topRight + const Offset(-1, 1), r.bottomLeft + const Offset(1, -1), _stroke(const Color(0xFF8A5A36), 1.3));
  }
  // itici
  final o = _bzCell(g, 5, 5, 1, 3).center;
  c.drawCircle(o + const Offset(0, -4), 3.2, _p(const Color(0xFFF2C9A0)));
  c.drawRect(Rect.fromCenter(center: o + const Offset(0, -6.6), width: 7, height: 2), _p(const Color(0xFF3075C4)));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + const Offset(0, 3), width: 7, height: 8), const Radius.circular(2)),
      _p(const Color(0xFF3075C4)));
  _bzArrow(c, o + const Offset(5, 0), o + const Offset(10, 0), Colors.white, 1.2);
}

void _bzLabyrinth(Canvas c) {
  _bzBg(c, const Color(0xFF1F5E46));
  const o = Offset(50, 50);
  final wall = _stroke(const Color(0xFFF7E7C6), 3);
  // halkalar (açıklıklı) ve radyal duvarlar
  const rings = [(40.0, 0.3), (30.0, 2.2), (20.0, 4.1), (10.0, 1.0)];
  for (final (r, gap) in rings) {
    c.drawArc(Rect.fromCircle(center: o, radius: r), gap + 0.45, 2 * math.pi - 0.9, false, wall);
  }
  for (final (r0, r1, a) in const [(30.0, 40.0, 1.4), (20.0, 30.0, 0.2), (20.0, 30.0, 3.4), (10.0, 20.0, 2.6), (30.0, 40.0, 4.6)]) {
    c.drawLine(o + Offset.fromDirection(a, r0), o + Offset.fromDirection(a, r1), wall);
  }
  // yol
  final path = Path()
    ..moveTo(o.dx + math.cos(0.3) * 48, o.dy + math.sin(0.3) * 48)
    ..lineTo(o.dx + math.cos(0.3) * 35, o.dy + math.sin(0.3) * 35)
    ..arcTo(Rect.fromCircle(center: o, radius: 35), 0.3, 1.9, false)
    ..lineTo(o.dx + math.cos(2.2) * 25, o.dy + math.sin(2.2) * 25)
    ..arcTo(Rect.fromCircle(center: o, radius: 25), 2.2, 1.9, false)
    ..lineTo(o.dx + math.cos(4.1) * 15, o.dy + math.sin(4.1) * 15);
  c.drawPath(path, _stroke(_bzGold, 2));
  _stone(c, o, 4.5, _bzGold);
}

void _bzTwiddle(Canvas c) {
  _bzBg(c, const Color(0xFF4C5BB8));
  const g = Rect.fromLTWH(16, 16, 68, 68);
  const nums = [1, 2, 3, 5, 8, 6, 4, 7, 9];
  for (var i = 0; i < 9; i++) {
    final x = i % 3, y = i ~/ 3;
    final inGroup = x >= 1 && y >= 1;
    final r = _bzCell(g, 3, 3, x, y).deflate(2.2);
    c.save();
    if (inGroup) {
      final piv = _bzCell(g, 3, 3, 1, 1).bottomRight;
      c.translate(piv.dx, piv.dy);
      c.rotate(0.22);
      c.translate(-piv.dx, -piv.dy);
    }
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
    c.drawRRect(rr.shift(const Offset(0, 1.4)), _p(Colors.black26));
    c.drawRRect(rr, _p(inGroup ? const Color(0xFFFFE08A) : Colors.white));
    _text(c, '${nums[i]}', r.center, 11, _bzNavy);
    c.restore();
  }
  // döndürme oku
  final piv = _bzCell(g, 3, 3, 1, 1).bottomRight;
  c.drawArc(Rect.fromCircle(center: piv, radius: 30), -1.2, 1.5, false, _stroke(Colors.white, 2));
  _bzArrow(c, piv + Offset.fromDirection(0.15, 30) + const Offset(-1, -3), piv + Offset.fromDirection(0.35, 30), Colors.white, 2);
}

void _bzPipeTile(Canvas c, Rect r, int mask, Color col, double w) {
  // mask: 1 yukarı, 2 sağ, 4 aşağı, 8 sol
  final o = r.center;
  final p = _stroke(col, w);
  if (mask & 1 != 0) c.drawLine(o, Offset(o.dx, r.top), p);
  if (mask & 2 != 0) c.drawLine(o, Offset(r.right, o.dy), p);
  if (mask & 4 != 0) c.drawLine(o, Offset(o.dx, r.bottom), p);
  if (mask & 8 != 0) c.drawLine(o, Offset(r.left, o.dy), p);
  c.drawCircle(o, w * 0.55, _p(col));
}

void _bzNetSlide(Canvas c) {
  _bzBg(c, const Color(0xFF1D3B5C));
  const g = Rect.fromLTWH(18, 18, 64, 64);
  const masks = [6, 10, 14, 12, 5, 6, 9, 5, 3, 13, 10, 9, 0, 3, 10, 8];
  for (var i = 0; i < 16; i++) {
    final x = i % 4, y = i ~/ 4;
    final shift = y == 2 ? const Offset(8, 0) : Offset.zero;
    final r = _bzCell(g, 4, 4, x, y).deflate(1).shift(shift);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), _p(y == 2 ? const Color(0xFF2E5A88) : const Color(0xFF26496F)));
    _bzPipeTile(c, r, masks[i], y == 2 ? const Color(0xFFFFC94A) : const Color(0xFF7FD8FF), 3.2);
  }
  final yy = _bzCell(g, 4, 4, 0, 2).center.dy;
  _bzArrow(c, Offset(8, yy), Offset(17, yy), Colors.white, 1.8);
  _bzArrow(c, Offset(83, yy), Offset(95, yy), Colors.white, 1.8);
  c.drawRect(g, _stroke(Colors.white30, 1));
}

void _bzNetRotate(Canvas c) {
  _bzBg(c, const Color(0xFF0F5F7A));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  const masks = [6, 10, 12, 4, 0, 5, 1, 7, 13, 9, 3, 10, 8, 0, 0, 0];
  for (var i = 0; i < 16; i++) {
    final r = _bzCell(g, 4, 4, i % 4, i ~/ 4).deflate(0.8);
    c.drawRect(r, _p(const Color(0xFF0B4A60)));
    final lit = i != 3 && i != 11;
    _bzPipeTile(c, r, masks[i], lit ? const Color(0xFF7FE3FF) : const Color(0xFF4A7A8C), 3.4);
  }
  // merkez sunucu
  final s = _bzCell(g, 4, 4, 1, 1);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: s.center, width: 12, height: 14), const Radius.circular(2)), _p(const Color(0xFFDDE6F0)));
  for (var k = 0; k < 3; k++) {
    c.drawRect(Rect.fromLTWH(s.center.dx - 4, s.center.dy - 5 + k * 4, 8, 1.6), _p(const Color(0xFF0F5F7A)));
  }
  // uç bilgisayarlar
  void screen(int x, int y, bool on) {
    final o = _bzCell(g, 4, 4, x, y).center;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 11, height: 8), const Radius.circular(1.5)), _p(const Color(0xFFDDE6F0)));
    c.drawRect(Rect.fromCenter(center: o, width: 8, height: 5), _p(on ? const Color(0xFF2FD3F5) : const Color(0xFF26323F)));
  }

  screen(3, 0, false);
  screen(0, 1, true);
  screen(0, 3, true);
  screen(1, 2, true);
  // döndürme oku (bağlanmamış uçta)
  final o = _bzCell(g, 4, 4, 3, 2).center;
  c.drawArc(Rect.fromCircle(center: o, radius: 8), -2.6, 4.2, false, _stroke(_bzGold, 1.6));
  _bzArrow(c, o + Offset.fromDirection(1.2, 8) + const Offset(1.5, -1), o + Offset.fromDirection(1.6, 8), _bzGold, 1.6);
}

void _bzFlow(Canvas c) {
  _bzBg(c, const Color(0xFF101A2E));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  c.drawRect(g, _p(const Color(0xFF0A1020)));
  _bzLines(c, g, 5, 5, _stroke(const Color(0xFF2A3654), 0.7));
  c.drawRect(g, _stroke(const Color(0xFF2A3654), 1));
  const lanes = [
    ([(0, 0), (1, 0), (2, 0), (3, 0), (4, 0), (4, 1)], Color(0xFFFF5D5D)),
    ([(0, 1), (1, 1), (2, 1), (3, 1), (3, 2)], Color(0xFF4F8CFF)),
    ([(0, 2), (1, 2), (2, 2), (2, 3), (3, 3), (4, 3), (4, 2)], Color(0xFF3DDC84)),
    ([(0, 3), (1, 3), (1, 4), (2, 4), (3, 4), (4, 4)], Color(0xFFFFD23F)),
    ([(0, 4)], Color(0xFFFF8BD1)),
  ];
  for (final (cells, col) in lanes) {
    final p = Path();
    for (var i = 0; i < cells.length; i++) {
      final o = _bzCell(g, 5, 5, cells[i].$1, cells[i].$2).center;
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      c.drawRect(_bzCell(g, 5, 5, cells[i].$1, cells[i].$2).deflate(0.6), _p(col.withValues(alpha: 0.14)));
    }
    c.drawPath(p, _stroke(col, 6.4));
    for (final e in [cells.first, cells.last]) {
      c.drawCircle(_bzCell(g, 5, 5, e.$1, e.$2).center, 5.8, _p(col));
    }
  }
}

void _bzOneLine(Canvas c) {
  _bzBg(c, const Color(0xFF6D4C9F));
  const g = Rect.fromLTWH(14, 14, 72, 72);
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      final blocked = x == 2 && y == 1;
      c.drawRRect(RRect.fromRectAndRadius(_bzCell(g, 4, 4, x, y).deflate(1.6), const Radius.circular(3)),
          _p(blocked ? const Color(0xFF3A2858) : Colors.white.withValues(alpha: 0.9)));
    }
  }
  const order = [(0, 0), (1, 0), (2, 0), (3, 0), (3, 1), (3, 2), (2, 2), (1, 2), (1, 1), (0, 1), (0, 2), (0, 3), (1, 3), (2, 3)];
  final p = Path();
  for (var i = 0; i < order.length; i++) {
    final o = _bzCell(g, 4, 4, order[i].$1, order[i].$2).center;
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  c.drawPath(
      p,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(colors: [Color(0xFFF2A93B), Color(0xFFE2574C), Color(0xFF9763BC)]).createShader(g));
  _stone(c, _bzCell(g, 4, 4, 0, 0).center, 5, const Color(0xFFF2A93B));
  // kalem ucu
  final e = _bzCell(g, 4, 4, 2, 3).center;
  c.save();
  c.translate(e.dx + 2, e.dy - 2);
  c.rotate(0.8);
  c.drawPath(Path()..addPolygon(const [Offset(0, 0), Offset(-3, -6), Offset(3, -6)], true), _p(const Color(0xFFF2C9A0)));
  c.drawRect(const Rect.fromLTWH(-3, -22, 6, 16), _p(_bzGold));
  c.restore();
}

void _bzLightsOut(Canvas c) {
  _bzBg(c, const Color(0xFF1A1A2E));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  const on = {(2, 1), (1, 2), (2, 2), (3, 2), (2, 3), (0, 4), (4, 0)};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final o = _bzCell(g, 5, 5, x, y).center;
      final lit = on.contains((x, y));
      if (lit) c.drawCircle(o, 9, _p(const Color(0xFF7FFFD4).withValues(alpha: 0.25)));
      c.drawCircle(o + const Offset(0, 1.2), 6, _p(Colors.black38));
      c.drawCircle(o, 6, _p(lit ? const Color(0xFF7FFFD4) : const Color(0xFF34344F)));
      c.drawCircle(o + const Offset(-1.8, -1.8), 1.6, _p(Colors.white.withValues(alpha: lit ? 0.7 : 0.12)));
    }
  }
  // dokunuş halkaları
  final t = _bzCell(g, 5, 5, 2, 2).center;
  c.drawCircle(t, 11, _stroke(Colors.white54, 1));
  c.drawCircle(t, 14.5, _stroke(Colors.white24, 0.8));
}

void _bzFlip(Canvas c) {
  _bzBg(c, const Color(0xFF2F6F5F));
  const g = Rect.fromLTWH(14, 14, 72, 72);
  const dark = {(0, 0), (2, 0), (1, 2), (2, 2)};
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 3; x++) {
      final r = _bzCell(g, 3, 3, x, y).deflate(2.4);
      final isDark = dark.contains((x, y));
      if (x == 1 && y == 1) {
        // dönmekte olan karo
        final p = Path()
          ..addPolygon([r.topLeft + const Offset(6, 0), r.topRight - const Offset(6, -3), r.bottomRight - const Offset(6, 3), r.bottomLeft + const Offset(6, 0)], true);
        c.drawPath(p.shift(const Offset(0, 1.4)), _p(Colors.black26));
        c.drawPath(p, _p(const Color(0xFFB8C7C2)));
        c.drawLine(Offset(r.center.dx, r.top - 3), Offset(r.center.dx, r.bottom + 3), _stroke(Colors.white54, 0.8));
        continue;
      }
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
      c.drawRRect(rr.shift(const Offset(0, 1.4)), _p(Colors.black26));
      c.drawRRect(rr, _p(isDark ? const Color(0xFF15302A) : const Color(0xFFF4F1E8)));
      // her karonun kendi çevirme deseni (3x3 mini nokta)
      for (var k = 0; k < 9; k++) {
        final m = (x * 5 + y * 3 + k * 7) % 4 == 0 || k == 4;
        final d = r.center + Offset((k % 3 - 1) * 4.2, (k ~/ 3 - 1) * 4.2);
        c.drawCircle(d, m ? 1.4 : 0.6, _p(isDark ? (m ? _bzGold : Colors.white24) : (m ? const Color(0xFF2F6F5F) : Colors.black12)));
      }
    }
  }
  _bzArrow(c, const Offset(38, 50), const Offset(30, 50), Colors.white70, 1.2);
  _bzArrow(c, const Offset(62, 50), const Offset(70, 50), Colors.white70, 1.2);
}

// ---- Klasik zekâ oyunları ----------------------------------------------------

void _bzQueenPiece(Canvas c, Offset o, double s, Color col) {
  final p = Path()
    ..moveTo(o.dx - s * 0.3, o.dy + s * 0.32)
    ..lineTo(o.dx - s * 0.36, o.dy - s * 0.2)
    ..lineTo(o.dx - s * 0.16, o.dy - s * 0.02)
    ..lineTo(o.dx, o.dy - s * 0.3)
    ..lineTo(o.dx + s * 0.16, o.dy - s * 0.02)
    ..lineTo(o.dx + s * 0.36, o.dy - s * 0.2)
    ..lineTo(o.dx + s * 0.3, o.dy + s * 0.32)
    ..close();
  c.drawPath(p.shift(const Offset(0, 1)), _p(Colors.black26));
  c.drawPath(p, _p(col));
  c.drawPath(p, _stroke(col == _ink ? Colors.white54 : _ink, s * 0.035));
  for (final dx in [-0.36, 0.0, 0.36]) {
    c.drawCircle(o + Offset(dx * s, dx == 0 ? -s * 0.34 : -s * 0.24), s * 0.06, _p(col));
  }
}

void _bzKnightQueen(Canvas c) {
  _bzBg(c, const Color(0xFF4A3A2A));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _woodBoard(c, g.inflate(3));
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      c.drawRect(_bzCell(g, 5, 5, x, y), _p((x + y).isOdd ? const Color(0xFF8A5A36) : const Color(0xFFEBD3A8)));
    }
  }
  // atın L sıçrayışları (numaralı)
  const tour = [(0, 4), (1, 2), (2, 0), (4, 1), (3, 3)];
  final p = Path();
  for (var i = 0; i < tour.length; i++) {
    final o = _bzCell(g, 5, 5, tour[i].$1, tour[i].$2).center;
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  c.drawPath(p, _stroke(const Color(0xFF2FA66A), 1.8));
  for (var i = 1; i < tour.length; i++) {
    _bzBadge(c, _bzCell(g, 5, 5, tour[i].$1, tour[i].$2).center, 4, '${i + 1}', const Color(0xFF2FA66A));
  }
  _chessKnight(c, _bzCell(g, 5, 5, 0, 4).center, 16, Colors.white);
  // vezirler
  _bzQueenPiece(c, _bzCell(g, 5, 5, 3, 0).center, 14, _ink);
  _bzQueenPiece(c, _bzCell(g, 5, 5, 0, 1).center, 14, _ink);
  _bzQueenPiece(c, _bzCell(g, 5, 5, 4, 3).center + const Offset(0, 0), 14, _ink);
}

void _bzCodeBreak(Canvas c) {
  _bzBg(c, const Color(0xFF3E2C5E));
  final board = RRect.fromRectAndRadius(const Rect.fromLTWH(18, 8, 64, 84), const Radius.circular(6));
  _shadowRRect(c, board);
  c.drawRRect(board, Paint()..shader = const LinearGradient(colors: [_woodLight, _wood]).createShader(board.outerRect));
  // gizli kod kapağı
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(22, 11, 44, 12), const Radius.circular(3)), _p(const Color(0xFF3A2616)));
  _text(c, '? ? ? ?', const Offset(44, 17), 6, Colors.white70);
  const rows = [
    [0, 1, 2, 3],
    [1, 0, 4, 2],
    [1, 2, 0, 5],
    [-1, -1, -1, -1],
  ];
  const fb = [
    [2, 1, 0, 0],
    [2, 2, 1, 0],
    [2, 2, 2, 1],
    [0, 0, 0, 0],
  ];
  for (var r = 0; r < rows.length; r++) {
    final y = 34.0 + r * 15;
    for (var i = 0; i < 4; i++) {
      final o = Offset(28 + i * 11, y);
      if (rows[r][i] < 0) {
        c.drawCircle(o, 3, _p(const Color(0xFF5C3A20)));
      } else {
        _stone(c, o, 4.3, _bzLiquid[rows[r][i]]);
      }
    }
    for (var k = 0; k < 4; k++) {
      final o = Offset(73 + (k % 2) * 4.5, y - 2.2 + (k ~/ 2) * 4.5);
      final v = fb[r][k];
      c.drawCircle(o, 1.6, _p(v == 0 ? const Color(0xFF5C3A20) : (v == 1 ? Colors.white : const Color(0xFF15181E))));
    }
  }
}

void _bzTwistCube(Canvas c) {
  _bzBg(c, const Color(0xFF263A5A));
  const cols = [Color(0xFFE2574C), Color(0xFF3BA776), Color(0xFF3075C4), Color(0xFFF2C14E), Color(0xFFF08A4B), Colors.white];
  Offset iso(double x, double y, double z) => Offset(50 + (x - y) * 13, 58 + (x + y) * 7.5 - z * 15);
  void quad(List<Offset> q, Color col) {
    final p = Path()..addPolygon(q, true);
    c.drawPath(p, _p(col));
    c.drawPath(p, _stroke(const Color(0xFF15181E), 1.3));
  }

  // alt iki katman: ön yüzler
  for (var z = 0; z < 2; z++) {
    for (var i = 0; i < 3; i++) {
      quad([iso(i.toDouble(), 3, z + 1.0), iso(i + 1.0, 3, z + 1.0), iso(i + 1.0, 3, z.toDouble()), iso(i.toDouble(), 3, z.toDouble())],
          cols[(i + z * 2) % 3 == 0 ? 0 : (i + z) % 6]);
      quad([iso(3, i.toDouble(), z + 1.0), iso(3, i + 1.0, z + 1.0), iso(3, i + 1.0, z.toDouble()), iso(3, i.toDouble(), z.toDouble())],
          cols[(i * 2 + z + 1) % 6]);
    }
  }
  // üst katman döndürülmüş
  c.save();
  final pivot = iso(1.5, 1.5, 3);
  c.translate(pivot.dx, pivot.dy - 3);
  c.rotate(-0.18);
  c.translate(-pivot.dx, -pivot.dy);
  for (var i = 0; i < 3; i++) {
    quad([iso(i.toDouble(), 3, 3), iso(i + 1.0, 3, 3), iso(i + 1.0, 3, 2), iso(i.toDouble(), 3, 2)], cols[(i + 2) % 6]);
    quad([iso(3, i.toDouble(), 3), iso(3, i + 1.0, 3), iso(3, i + 1.0, 2), iso(3, i.toDouble(), 2)], cols[(i + 4) % 6]);
  }
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 3; x++) {
      quad([iso(x.toDouble(), y.toDouble(), 3), iso(x + 1.0, y.toDouble(), 3), iso(x + 1.0, y + 1.0, 3), iso(x.toDouble(), y + 1.0, 3)],
          cols[(x + y * 2 + 3) % 6]);
    }
  }
  c.restore();
  // döndürme oku
  c.drawArc(Rect.fromCenter(center: const Offset(50, 22), width: 70, height: 26), 3.6, 2.2, false, _stroke(Colors.white, 2));
  _bzArrow(c, Offset(50 + math.cos(5.6) * 35, 22 + math.sin(5.6) * 13) - const Offset(3, 2), Offset(50 + math.cos(5.8) * 35, 22 + math.sin(5.8) * 13) + const Offset(1, 1),
      Colors.white, 2);
}

void _bzDrawLine(Canvas c) {
  c.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4FA3D9), Color(0xFF9FD6F5)])
            .createShader(const Rect.fromLTWH(0, 0, 100, 100)));
  // kareli kâğıt dokusu
  for (var i = 10.0; i < 100; i += 10) {
    c.drawLine(Offset(i, 0), Offset(i, 100), _stroke(Colors.white12, 0.5));
    c.drawLine(Offset(0, i), Offset(100, i), _stroke(Colors.white12, 0.5));
  }
  // platform ve sepet
  c.drawRect(const Rect.fromLTWH(6, 30, 24, 4), _p(const Color(0xFF5B6B7D)));
  final basket = Path()..moveTo(70, 70)..lineTo(92, 70)..lineTo(88, 90)..lineTo(74, 90)..close();
  c.drawPath(basket, _p(const Color(0xFFE2574C)));
  for (var x = 74.0; x < 90; x += 4) {
    c.drawLine(Offset(x, 72), Offset(x + 0.5, 88), _stroke(Colors.white38, 0.8));
  }
  // elle çizilmiş çizgi
  final line = Path()..moveTo(22, 46)..cubicTo(34, 50, 44, 58, 52, 62)..cubicTo(58, 65, 63, 66, 68, 64);
  c.drawPath(line, _stroke(const Color(0xFF1B2433), 3));
  // top ve kesik yörünge
  final traj = Path()..moveTo(18, 24)..quadraticBezierTo(22, 34, 26, 44);
  for (final m in traj.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += 4) {
      c.drawPath(m.extractPath(d, d + 2), _stroke(Colors.white, 1.2));
    }
  }
  _stone(c, const Offset(16, 24), 5, const Color(0xFFF2A93B));
  // kalem
  c.save();
  c.translate(70, 62);
  c.rotate(0.7);
  c.drawPath(Path()..addPolygon(const [Offset(0, 0), Offset(-2.6, -6), Offset(2.6, -6)], true), _p(const Color(0xFFF2C9A0)));
  c.drawRect(const Rect.fromLTWH(-2.6, -26, 5.2, 20), _p(const Color(0xFF3BA776)));
  c.drawRect(const Rect.fromLTWH(-2.6, -29, 5.2, 3), _p(const Color(0xFFE58FB0)));
  c.restore();
}

void _bzRopes(Canvas c) {
  _bzBg(c, const Color(0xFF6B3A5A));
  const pins = [Offset(20, 20), Offset(80, 22), Offset(18, 78), Offset(82, 80), Offset(50, 14), Offset(50, 86)];
  const ropes = [(0, 3, Color(0xFFF2C14E), 20.0), (1, 2, Color(0xFF2BB3B1), -24.0), (4, 5, Color(0xFFE58FB0), 30.0)];
  for (final (a, b, col, bend) in ropes) {
    final p = pins[a], q = pins[b];
    final m = Offset.lerp(p, q, 0.5)! + Offset(bend, 0);
    final path = Path()..moveTo(p.dx, p.dy)..quadraticBezierTo(m.dx, m.dy, q.dx, q.dy);
    c.drawPath(path.shift(const Offset(0, 1.6)), _stroke(Colors.black26, 4.4));
    c.drawPath(path, _stroke(col, 4));
    c.drawPath(path, _stroke(Colors.white24, 1));
  }
  for (var i = 0; i < pins.length; i++) {
    final o = pins[i];
    c.drawCircle(o + const Offset(0, 1.2), 5.4, _p(Colors.black38));
    c.drawCircle(o, 5.4, _p(const Color(0xFFD9DEE6)));
    c.drawCircle(o, 2.2, _p(const Color(0xFF6B7684)));
  }
  // sürüklenen kanca
  c.drawCircle(pins[1], 9, _stroke(Colors.white70, 1.2));
  _bzArrow(c, pins[1] + const Offset(-4, 10), pins[1] + const Offset(-14, 22), Colors.white, 1.5);
}

void _bzUntangle(Canvas c) {
  _bzBg(c, const Color(0xFF24324F));
  const n = [Offset(20, 24), Offset(78, 20), Offset(84, 70), Offset(24, 80), Offset(50, 48), Offset(52, 86), Offset(46, 14)];
  const ok = [(0, 6), (6, 1), (1, 4), (4, 0), (2, 5), (5, 3)];
  const bad = [(0, 2), (1, 3)];
  for (final (a, b) in ok) {
    c.drawLine(n[a], n[b], _stroke(const Color(0xFF68D391), 1.8));
  }
  for (final (a, b) in bad) {
    c.drawLine(n[a], n[b], _stroke(const Color(0xFFFF6B6B), 1.8));
  }
  // kesişme noktası
  c.drawCircle(const Offset(52.6, 51.4), 4, _stroke(_bzGold, 1.4));
  for (var i = 0; i < n.length; i++) {
    _stone(c, n[i], i == 4 ? 6 : 5, i == 4 ? _bzCyan : Colors.white);
  }
  _bzArrow(c, const Offset(58, 44), const Offset(66, 36), _bzCyan, 1.4);
}

void _bzPegJump(Canvas c) {
  _bzBg(c, const Color(0xFF6E4A2A));
  final cross = Path()
    ..addPolygon(const [
      Offset(30, 10), Offset(70, 10), Offset(70, 30), Offset(90, 30), Offset(90, 70), Offset(70, 70), Offset(70, 90), Offset(30, 90),
      Offset(30, 70), Offset(10, 70), Offset(10, 30), Offset(30, 30),
    ], true);
  c.drawPath(cross.shift(const Offset(0, 2.4)), _p(Colors.black38));
  c.drawPath(cross, Paint()..shader = const LinearGradient(colors: [_woodLight, _wood]).createShader(const Rect.fromLTWH(10, 10, 80, 80)));
  Offset hole(int x, int y) => Offset(22.5 + x * 13.75, 22.5 + y * 13.75);
  bool inside(int x, int y) => (x >= 1 && x <= 3) || (y >= 1 && y <= 3);
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      if (!inside(x, y)) continue;
      final o = hole(x, y);
      c.drawCircle(o, 4.2, _p(const Color(0xFF5C3A20)));
      final empty = (x == 2 && y == 2) || (x == 2 && y == 3);
      if (!empty) _stone(c, o, 4.2, x == 2 && y == 4 ? const Color(0xFFF2A93B) : const Color(0xFF3075C4));
    }
  }
  // sıçrama yayı: (2,4) → (2,2)
  final a = hole(2, 4), b = hole(2, 2);
  c.drawPath(Path()..moveTo(a.dx + 3, a.dy - 4)..quadraticBezierTo(a.dx + 16, (a.dy + b.dy) / 2, b.dx + 4, b.dy + 2), _stroke(Colors.white, 1.6));
  _bzArrow(c, b + const Offset(7, 5), b + const Offset(4, 2), Colors.white, 1.6);
}
