part of 'covers.dart';

/// Blok Oyunları merkezinin oyuna özgü kapakları (tür adları `b-` ile başlar).
/// Her oyun kendi tahtasını ve mekaniğini gösterir: yerleştir-temizle,
/// düşen, kaydır-çıkar, sayı birleştirme, kum, altıgen, küp, kule… Paketteki
/// 20 çeşit (`b-cesit`, v: 0–19) kendi tahta boyutu, kutu düzeni, parça
/// takımı ya da özel taşıyla çizilir. Renkler merkezin onaylı mavi–camgöbeği
/// paletiyle uyumludur. Vektör, dış görsel ve marka yok.
/// Döndürür: çizildiyse true.
bool _paintBlokCover(Canvas c, GameCover cover, Color seed) {
  if (!cover.kind.startsWith('b-')) return false;
  const deep = Color(0xFF0B1A52);
  const navy = Color(0xFF16338C);
  const royal = Color(0xFF1E58C8);
  const cyan = Color(0xFF35D6F6);
  const ice = Color(0xFF3FE0FF);
  const blockCols = [
    Color(0xFFFF5D73), Color(0xFFFFB02E), Color(0xFFFFE066), Color(0xFF5BD67A),
    Color(0xFF35D6F6), Color(0xFF7B8CFF), Color(0xFFC77DFF), Color(0xFFFF8FAB),
  ];

  void plain(Color top, Color bottom) {
    c.drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()
          ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [top, bottom])
              .createShader(const Rect.fromLTWH(0, 0, 100, 100)));
  }

  Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);

  // Parlak, kabartmalı blok hücresi.
  void block(Rect r, Color col) {
    final rad = Radius.circular(r.width * 0.18);
    c.drawRRect(RRect.fromRectAndRadius(r.shift(Offset(0, r.height * 0.08)), rad), _p(Color.lerp(col, Colors.black, 0.4)!));
    c.drawRRect(RRect.fromRectAndRadius(r, rad), _p(col));
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.left + r.width * 0.15, r.top + r.height * 0.12, r.width * 0.7, r.height * 0.25), rad),
        _p(Colors.white.withValues(alpha: 0.35)));
  }

  // n×n tahta; hücre sol-üst köşesini döndüren yardımcıyla.
  Rect boardRect(Rect area, int n, {int box = 0, Color bg = deep}) {
    c.drawRRect(RRect.fromRectAndRadius(area.inflate(2.5), const Radius.circular(5)), _p(Colors.black.withValues(alpha: 0.3)));
    c.drawRRect(RRect.fromRectAndRadius(area.inflate(1.5), const Radius.circular(4)), _p(bg));
    final cs = area.width / n;
    final g = _stroke(Colors.white.withValues(alpha: 0.10), 0.5);
    for (var i = 1; i < n; i++) {
      c.drawLine(Offset(area.left + i * cs, area.top), Offset(area.left + i * cs, area.bottom), g);
      c.drawLine(Offset(area.left, area.top + i * cs), Offset(area.right, area.top + i * cs), g);
    }
    if (box > 0) {
      final bp = _stroke(cyan.withValues(alpha: 0.55), 1.1);
      for (var i = box; i < n; i += box) {
        c.drawLine(Offset(area.left + i * cs, area.top), Offset(area.left + i * cs, area.bottom), bp);
        c.drawLine(Offset(area.left, area.top + i * cs), Offset(area.right, area.top + i * cs), bp);
      }
    }
    return area;
  }

  Rect cellOf(Rect area, int n, int x, int y, [double pad = 0.6]) {
    final cs = area.width / n;
    return Rect.fromLTWH(area.left + x * cs + pad, area.top + y * cs + pad, cs - pad * 2, cs - pad * 2);
  }

  // Parça (hücre listesi) verilen köşe ve hücre boyunda.
  void piece(List<(int, int)> cells, Offset o, double s, Color col) {
    for (final (x, y) in cells) {
      block(Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s - 0.8, s - 0.8), col);
    }
  }

  void sparkle(Offset o, double r, Color col) {
    final p = Path()
      ..moveTo(o.dx, o.dy - r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx + r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy + r)
      ..quadraticBezierTo(o.dx, o.dy, o.dx - r, o.dy)
      ..quadraticBezierTo(o.dx, o.dy, o.dx, o.dy - r)
      ..close();
    c.drawPath(p, _p(col));
  }

  Path hexPath(Offset o, double r) {
    final p = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final q = o + Offset(math.cos(a) * r, math.sin(a) * r);
      i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  void hexCell(Offset o, double r, Color col) {
    c.drawPath(hexPath(o + Offset(0, r * 0.12), r), _p(Color.lerp(col, Colors.black, 0.4)!));
    c.drawPath(hexPath(o, r), _p(col));
    c.drawPath(hexPath(o + Offset(0, -r * 0.25), r * 0.45), _p(Colors.white.withValues(alpha: 0.28)));
  }

  int h(int a, int b) => ((a * 73856093) ^ (b * 19349663) ^ (cover.v * 83492791)) & 0x7fffffff;

  switch (cover.kind) {
    case 'b-master': // Blok Bulmaca: 8×8 tahta, parlayan dolu sıra, altta üç parça
      plain(royal, deep);
      final a = boardRect(const Rect.fromLTWH(14, 6, 72, 72), 8);
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          if (y == 5 || (y > 5 && (x + y) % 3 != 0) || (y == 4 && x % 3 == 0) || (y == 3 && x == 6)) {
            block(cellOf(a, 8, x, y), y == 5 ? ice : blockCols[(x * 3 + y) % 8]);
          }
        }
      }
      c.drawRect(Rect.fromLTWH(a.left - 1, a.top + 5 * 9 - 1, a.width + 2, 11), _stroke(Colors.white, 1.4));
      sparkle(Offset(a.right - 2, a.top + 5 * 9), 4, Colors.white);
      piece(const [(0, 0), (0, 1), (1, 1)], const Offset(14, 84), 6, blockCols[0]);
      piece(const [(0, 0), (1, 0), (0, 1), (1, 1)], const Offset(42, 84), 6, blockCols[2]);
      piece(const [(0, 0), (1, 0), (2, 0)], const Offset(66, 87), 6, blockCols[6]);
    case 'b-sudoku': // Blok Sudoku: 9×9, kalın 3×3 kutular, tamamlanan kutu, yıldız
      plain(const Color(0xFF2346A8), deep);
      final a = boardRect(const Rect.fromLTWH(10, 6, 72, 72), 9, box: 3, bg: const Color(0xFFEAF2FF));
      for (var y = 0; y < 9; y++) {
        for (var x = 0; x < 9; x++) {
          final inBox = x >= 3 && x < 6 && y >= 3 && y < 6;
          if (inBox || h(x, y) % 4 == 0) {
            block(cellOf(a, 9, x, y), inBox ? royal : const Color(0xFF7B8CFF));
          }
        }
      }
      c.drawRect(Rect.fromLTWH(a.left + 24, a.top + 24, 24, 24), _stroke(const Color(0xFFFFB02E), 2));
      sparkle(Offset(a.left + 48, a.top + 24), 5, const Color(0xFFFFE066));
      piece(const [(0, 0), (1, 0), (1, 1)], const Offset(86, 16), 4.5, blockCols[1]);
      piece(const [(0, 0), (0, 1), (0, 2)], const Offset(88, 50), 4.5, blockCols[3]);
      c.drawRect(Rect.fromLTWH(a.left - 1, a.top - 1, a.width + 2, a.height + 2), _stroke(navy, 1.6));
      _text(c, '3×3', const Offset(50, 90), 9, Colors.white);
    case 'b-doldurma': // Blok Doldurma: düzensiz şekil (ev) silüeti, parçalarla doluyor, biri havada
      plain(const Color(0xFF1E3A8A), deep);
      const n = 7;
      const area = Rect.fromLTWH(15, 14, 70, 70);
      const shape = ['...X...', '..XXX..', '.XXXXX.', 'XXXXXXX', '.XXXXX.', '.XX.XX.', '.XX.XX.'];
      const owner = ['...0...', '..001..', '.22011.', '3220114', '.32244.', '.33.44.', '.33.55.'];
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          if (shape[y][x] != 'X') continue;
          final r = cellOf(area, n, x, y, 0.4);
          final o = owner[y][x];
          if (o == '5') {
            c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.5)), _stroke(cyan, 1));
          } else {
            block(r, blockCols[int.parse(o)]);
          }
        }
      }
      // Havadaki son parça (gölgesiyle)
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 68, 16, 7), const Radius.circular(2)), _p(Colors.black26));
      piece(const [(0, 0), (1, 0)], const Offset(68, 3), 9.6, blockCols[5]);
      c.drawLine(const Offset(77, 14), const Offset(77, 22), _stroke(Colors.white54, 1.2));
    case 'b-poliomino': // Beşli yerleştirme: beşlilerle döşenen dikdörtgen, eksik parça havada
      plain(const Color(0xFF203A9E), deep);
      const tiling = ['AAAAB', 'ACCBB', 'DCCCB', 'DDDDB'];
      const area = Rect.fromLTWH(14, 34, 72, 57.6);
      final cs = area.width / 5;
      c.drawRRect(RRect.fromRectAndRadius(area.inflate(2), const Radius.circular(4)), _p(Colors.black.withValues(alpha: 0.35)));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 5; x++) {
          final id = tiling[y][x];
          final r = Rect.fromLTWH(area.left + x * cs, area.top + y * cs, cs, cs);
          if (id == 'D') {
            c.drawRect(r.deflate(1), _stroke(Colors.white30, 0.8));
            continue;
          }
          final col = {'A': blockCols[0], 'B': blockCols[4], 'C': blockCols[2]}[id]!;
          c.drawRect(r, _p(col));
          c.drawRect(Rect.fromLTWH(r.left + 2, r.top + 2, r.width - 4, 3), _p(Colors.white.withValues(alpha: 0.3)));
          // Parça sınırları: komşu farklıysa koyu çizgi
          final edge = _stroke(deep, 1.4);
          if (x == 4 || tiling[y][x + 1] != id) c.drawLine(r.topRight, r.bottomRight, edge);
          if (y == 3 || tiling[y + 1][x] != id) c.drawLine(r.bottomLeft, r.bottomRight, edge);
        }
      }
      // Havadaki D (L-beşli), döndürme oku
      piece(const [(0, 0), (0, 1), (1, 1), (2, 1), (3, 1)], const Offset(20, 6), 9, blockCols[6]);
      c.drawArc(const Rect.fromLTWH(64, 6, 18, 18), -2.6, 4.2, false, _stroke(ice, 2));
      c.drawPath(poly(const [Offset(62, 12), Offset(64, 6), Offset(68, 11)]), _p(ice));
    case 'b-alanbolme': // Alan bölme: sayılı ızgara, sayıya göre çizilmiş dikdörtgenler
      plain(const Color(0xFF1F4FB8), deep);
      final a = boardRect(const Rect.fromLTWH(12, 12, 76, 76), 6, bg: const Color(0xFFF1F6FF));
      final cs = a.width / 6;
      const rects = [(0, 0, 3, 2, 6, 0, 1), (3, 0, 3, 1, 3, 4, 0), (3, 1, 1, 3, 3, 3, 2), (4, 1, 2, 2, 4, 5, 1)];
      for (var i = 0; i < rects.length; i++) {
        final (x, y, w, hh, nv, nx, ny) = rects[i];
        final r = Rect.fromLTWH(a.left + x * cs + 1.5, a.top + y * cs + 1.5, w * cs - 3, hh * cs - 3);
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _p(blockCols[(i * 2 + 1) % 8].withValues(alpha: 0.55)));
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _stroke(navy, 1.6));
        _text(c, '$nv', Offset(a.left + (nx + 0.5) * cs, a.top + (ny + 0.5) * cs), 8, deep);
      }
      for (final (x, y, nv) in const [(0, 3, 4), (2, 4, 2), (5, 4, 6), (1, 5, 3)]) {
        _text(c, '$nv', Offset(a.left + (x + 0.5) * cs, a.top + (y + 0.5) * cs), 8, navy);
      }
      // Çizilmekte olan dikdörtgen (kesik)
      final drag = Rect.fromLTWH(a.left + 0 * cs + 1.5, a.top + 2 * cs + 1.5, 2 * cs - 3, 2 * cs - 3);
      c.drawRRect(RRect.fromRectAndRadius(drag, const Radius.circular(3)), _stroke(const Color(0xFFFFB02E), 2));
    case 'b-paket': // Blok çeşit paketi: yelpaze gibi açılmış farklı boyda üç tahta, +20 rozeti
      plain(royal, deep);
      void mini(double cx, double cy, double ang, int n, int box, Color accent) {
        c.save();
        c.translate(cx, cy);
        c.rotate(ang);
        final area = boardRect(const Rect.fromLTWH(-20, -20, 40, 40), n, box: box);
        for (var y = 0; y < n; y++) {
          for (var x = 0; x < n; x++) {
            if (h(x + n, y) % 3 == 0) block(cellOf(area, n, x, y, 0.3), accent);
          }
        }
        c.restore();
      }
      mini(30, 54, -0.35, 6, 0, blockCols[0]);
      mini(70, 54, 0.35, 10, 5, blockCols[4]);
      mini(50, 48, 0, 8, 4, blockCols[1]);
      c.drawCircle(const Offset(80, 18), 12, _p(const Color(0xFFFFB02E)));
      c.drawCircle(const Offset(80, 18), 10, _stroke(Colors.white70, 1));
      _text(c, '20', const Offset(80, 18), 10, deep);
    case 'b-dusen': // Düşen bloklar: kuyu, yığın, düşen T parça ve hayalet izi, silinen sıra
      plain(navy, deep);
      const area = Rect.fromLTWH(24, 4, 52, 92);
      c.drawRect(area.inflate(2), _p(const Color(0xFF0A1440)));
      c.drawRect(area.inflate(2), _stroke(cyan.withValues(alpha: 0.5), 1.4));
      final cs = area.width / 8;
      Rect cell(int x, int y) => Rect.fromLTWH(area.left + x * cs + 0.4, area.top + y * cs + 0.4, cs - 0.8, cs - 0.8);
      const stack = [
        '....AA..', 'B..CAA..', 'BBCCCDDE', 'FFFFFFFF', 'GGB.HHDE', 'GGBBHHEE',
      ];
      for (var y = 0; y < stack.length; y++) {
        for (var x = 0; x < 8; x++) {
          final ch = stack[y][x];
          if (ch == '.') continue;
          block(cell(x, 8 + y), ch == 'F' ? Colors.white : blockCols['ABCDEGH'.indexOf(ch) % 8]);
        }
      }
      sparkle(Offset(area.right - 4, area.top + 11 * cs + 3), 4, ice);
      // Hayalet (iniş yeri) ve düşen T
      for (final (x, y) in const [(4, 7), (5, 7), (6, 7), (5, 6)]) {
        c.drawRRect(RRect.fromRectAndRadius(cell(x, y).deflate(0.6), const Radius.circular(1.5)), _stroke(Colors.white54, 0.9));
      }
      for (final (x, y) in const [(4, 2), (5, 2), (6, 2), (5, 1)]) {
        block(cell(x, y), const Color(0xFFC77DFF));
      }
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(area.left + 4.6 * cs + i * 3, area.top + 3.4 * cs), Offset(area.left + 4.6 * cs + i * 3, area.top + 5 * cs),
            _stroke(Colors.white24, 1));
      }
    case 'b-altigen': // Altıgen blok: altıgen tahta, dolu hücreler, altıgen parça tepside
      plain(const Color(0xFF1F5FD0), deep);
      const r = 6.2;
      final dx = r * math.sqrt(3);
      for (var q = -3; q <= 3; q++) {
        for (var s = -3; s <= 3; s++) {
          final t = -q - s;
          if (t.abs() > 3) continue;
          final o = Offset(50 + dx * (q + s / 2), 42 + r * 1.5 * s);
          final k = h(q + 5, s + 5) % 5;
          if (s == 0) {
            hexCell(o, r - 0.6, ice);
          } else if (k < 2) {
            hexCell(o, r - 0.6, blockCols[(q + s + 8) % 8]);
          } else {
            c.drawPath(hexPath(o, r - 0.6), _p(Colors.white.withValues(alpha: 0.12)));
          }
        }
      }
      for (final (ox, oy) in const [(20.0, 90.0), (26.0, 90.0), (23.0, 85.0)]) {
        hexCell(Offset(ox, oy), 3.6, blockCols[1]);
      }
      for (final (ox, oy) in const [(66.0, 90.0), (72.5, 90.0), (79.0, 90.0)]) {
        hexCell(Offset(ox, oy), 3.6, blockCols[6]);
      }
    case 'b-altigendusen': // Altıgen düşen: dikey altıgen kuyu, düşen üçlü altıgen küme
      plain(const Color(0xFF14307A), deep);
      const r = 5.4;
      final dx = r * math.sqrt(3);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(18, 2, 64, 96), const Radius.circular(6)), _p(const Color(0xFF0A1440)));
      for (var row = 0; row < 11; row++) {
        for (var col = 0; col < 6; col++) {
          final o = Offset(25 + col * dx + (row.isOdd ? dx / 2 : 0), 8 + row * r * 1.5);
          if (o.dx > 80) continue;
          if (row >= 8 || (row == 7 && col % 2 == 0)) {
            hexCell(o, r - 0.5, blockCols[(row * 2 + col) % 8]);
          } else {
            c.drawPath(hexPath(o, r - 0.5), _p(Colors.white.withValues(alpha: 0.06)));
          }
        }
      }
      for (final (col, row) in const [(2, 2), (3, 2), (2, 3)]) {
        hexCell(Offset(25 + col * dx + (row.isOdd ? dx / 2 : 0), 8 + row * r * 1.5), r - 0.5, ice);
      }
      c.drawLine(const Offset(52, 36), const Offset(52, 48), _stroke(Colors.white38, 1.4));
      c.drawPath(poly(const [Offset(48.5, 46), Offset(52, 51), Offset(55.5, 46)]), _p(Colors.white38));
    case 'b-sayili': // Sayılı bloklar: sütunlara düşen sayılı küpler, 4+4 birleşip 8 oluyor
      plain(const Color(0xFF1A3C9E), deep);
      for (var i = 0; i < 5; i++) {
        c.drawRect(Rect.fromLTWH(8 + i * 17.5, 8, 15.5, 88), _p(Colors.white.withValues(alpha: i == 2 ? 0.12 : 0.05)));
      }
      void numBlock(int col, int row, int val) {
        const vals = [2, 4, 8, 16, 32, 64];
        final ci = vals.indexOf(val);
        final r = Rect.fromLTWH(8.5 + col * 17.5, 82 - row * 15.5, 14.5, 14);
        block(r, blockCols[(ci < 0 ? 0 : ci * 2 + 1) % 8]);
        _text(c, '$val', r.center, val >= 10 ? 7 : 8.5, deep);
      }
      numBlock(0, 0, 2);
      numBlock(0, 1, 16);
      numBlock(1, 0, 8);
      numBlock(2, 0, 32);
      numBlock(2, 1, 4);
      numBlock(3, 0, 2);
      numBlock(4, 0, 64);
      numBlock(4, 1, 8);
      numBlock(2, 4, 4);
      c.drawLine(const Offset(50.75, 40), const Offset(50.75, 56), _stroke(Colors.white54, 1.4));
      c.drawCircle(const Offset(80, 22), 9, _p(const Color(0xFFFFB02E).withValues(alpha: 0.3)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 14, 16, 16), const Radius.circular(3)), _p(blockCols[5]));
      _text(c, '8', const Offset(80, 22), 9, deep);
      sparkle(const Offset(66, 32), 4, Colors.white);
    case 'b-retro': // Retro tuğla konsolu: yatay, turuncu gövdeli el konsolu; nokta ekranda dört mini oyun
      plain(const Color(0xFF173A99), deep);
      final body = RRect.fromRectAndRadius(const Rect.fromLTWH(4, 22, 92, 58), const Radius.circular(16));
      c.drawRRect(body.shift(const Offset(0, 2.5)), _p(Colors.black38));
      c.drawRRect(body, _p(const Color(0xFFFF8A3D)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 26, 84, 6), const Radius.circular(3)), _p(Colors.white24));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(28, 28, 44, 46), const Radius.circular(5)), _p(const Color(0xFF3B2A4A)));
      const scr = Rect.fromLTWH(32, 32, 36, 38);
      c.drawRect(scr, _p(const Color(0xFF9AA86B)));
      final dot = scr.width / 10;
      // Dört bölmeli ekran: yarış, yılan, atış, tuğla kır
      const art = [
        '.#..#.####', '###.#.....', '.#..#.##..', '#.#.#.....', '..........',
        '#.#.#....#', '.#..#..#..', '#.#.#.###.', '.......#..', '####...#..',
      ];
      for (var y = 0; y < 10; y++) {
        for (var x = 0; x < 10; x++) {
          c.drawRect(Rect.fromLTWH(scr.left + x * dot + 0.4, scr.top + y * 3.8 + 0.4, dot - 0.8, 3.0),
              _p(art[y][x] == '#' ? const Color(0xFF2B3320) : const Color(0xFF8B9960)));
        }
      }
      // Sol: dört yön düğmeleri (ayrık yuvarlaklar); sağ: tek büyük düğme
      for (final o in const [Offset(16, 44), Offset(16, 60), Offset(8.5, 52), Offset(23.5, 52)]) {
        c.drawCircle(o + const Offset(0, 1), 4, _p(Colors.black26));
        c.drawCircle(o, 4, _p(const Color(0xFFFFE066)));
      }
      c.drawCircle(const Offset(84, 53), 8.5, _p(Colors.black26));
      c.drawCircle(const Offset(84, 52), 8.5, _p(const Color(0xFF35D6F6)));
      c.drawCircle(const Offset(82, 49.5), 3, _p(Colors.white38));
      for (var i = 0; i < 4; i++) {
        c.drawCircle(Offset(38.0 + i * 8, 86), 2.4, _p(blockCols[i * 2]));
      }
    case 'b-kum': // Kum blokları: renkli kum yığını, soldan sağa uzanan renk köprüsü, ufalanan parça
      plain(const Color(0xFF1B3F9C), deep);
      c.drawRect(const Rect.fromLTWH(10, 4, 80, 92), _p(const Color(0xFF0A1440)));
      final rnd = math.Random(7);
      const sandCols = [Color(0xFFFFB02E), Color(0xFFFF5D73), Color(0xFF5BD67A), Color(0xFF35D6F6)];
      for (var y = 50.0; y < 95; y += 2.2) {
        for (var x = 11.0; x < 89; x += 2.2) {
          final hill = 50 + 14 * math.sin((x - 10) / 80 * math.pi * 1.6) * 0.5 + 6;
          if (y < hill) continue;
          final band = ((y - 50) / 11).floor();
          final col = (y > 70 && y < 77) ? sandCols[3] : sandCols[(band + (x / 22).floor()) % 3];
          c.drawRect(Rect.fromLTWH(x + rnd.nextDouble() * 0.4, y, 2.0, 2.0), _p(col));
        }
      }
      c.drawRect(const Rect.fromLTWH(10, 69.6, 80, 7.6), _stroke(Colors.white, 1.2));
      sparkle(const Offset(86, 66), 4, Colors.white);
      // Düşen parça ve ufalanan taneler
      piece(const [(0, 0), (1, 0), (1, 1)], const Offset(42, 12), 8, sandCols[1]);
      for (var i = 0; i < 14; i++) {
        c.drawRect(Rect.fromLTWH(48 + (i % 4) * 2.4 + rnd.nextDouble(), 30 + i * 1.6, 1.8, 1.8), _p(sandCols[1]));
      }
    case 'b-kaydirma': // Blok kaydırma: boşluklu sıralar, yana kayan blok oku, alttan yükselen sıra
      plain(const Color(0xFF1E4FC0), deep);
      final a = boardRect(const Rect.fromLTWH(12, 6, 76, 76), 8);
      const rows = ['........', '........', '...AA...', '.BBB..CC', 'DD.EEEE.', 'FFF.GGHH', 'II.JJJJJ', 'KKKK.LLL'];
      for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
          final ch = rows[y][x];
          if (ch == '.') continue;
          block(cellOf(a, 8, x, y), blockCols['ABCDEFGHIJKL'.indexOf(ch) % 8]);
        }
      }
      final cs = a.width / 8;
      // Yana kayma oku
      c.drawLine(Offset(a.left + 1.5 * cs, a.top + 3.5 * cs), Offset(a.left + 4.7 * cs, a.top + 3.5 * cs), _stroke(Colors.white, 2));
      c.drawPath(poly([Offset(a.left + 4.6 * cs, a.top + 3.1 * cs), Offset(a.left + 5.2 * cs, a.top + 3.5 * cs), Offset(a.left + 4.6 * cs, a.top + 3.9 * cs)]),
          _p(Colors.white));
      // Yükselen sıra
      for (var x = 0; x < 8; x++) {
        if (x == 3) continue;
        block(Rect.fromLTWH(a.left + x * cs + 0.6, 87, cs - 1.2, cs - 1.2), blockCols[(x + 2) % 8].withValues(alpha: 0.7));
      }
      for (final x in [6.0, 94.0]) {
        c.drawPath(poly([Offset(x - 3, 92), Offset(x, 86), Offset(x + 3, 92)]), _p(ice));
      }
    case 'b-kacis': // Blok kaçışı: oklu bloklar, biri ok yönünde tahtadan çıkıyor
      plain(const Color(0xFF173E9E), deep);
      final a = boardRect(const Rect.fromLTWH(14, 14, 66, 66), 5);
      final cs = a.width / 5;
      void arrowBlock(int x, int y, int dir, Color col, {Offset shift = Offset.zero}) {
        final r = cellOf(a, 5, x, y, 1).shift(shift);
        block(r, col);
        final o = r.center;
        final v = [const Offset(0, -1), const Offset(1, 0), const Offset(0, 1), const Offset(-1, 0)][dir];
        final pv = Offset(-v.dy, v.dx);
        c.drawPath(poly([o + v * 4.5, o - v * 2 + pv * 3.6, o - v * 2 - pv * 3.6]), _p(Colors.white));
      }
      const layout = [(0, 0, 2), (1, 0, 1), (3, 0, 3), (0, 1, 1), (2, 1, 0), (4, 1, 2), (1, 2, 2), (3, 2, 3), (0, 3, 0), (2, 3, 1), (4, 3, 0), (1, 4, 1), (3, 4, 0)];
      for (var i = 0; i < layout.length; i++) {
        final (x, y, d) = layout[i];
        arrowBlock(x, y, d, blockCols[i % 8]);
      }
      // Kaçan blok: sağ kenardan çıkıyor
      arrowBlock(4, 2, 1, ice, shift: Offset(cs * 1.15, 0));
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(a.right - 2 + i * 2.0, a.top + 2.2 * cs + i * 3), Offset(a.right + 6 + i * 2.0, a.top + 2.2 * cs + i * 3),
            _stroke(Colors.white38, 1));
      }
    case 'b-renkli': // Renkli kapılar: duvarlarda renkli kapı boşlukları, eşleşen bloklar, çıkan blok
      plain(const Color(0xFF1C47B0), deep);
      const area = Rect.fromLTWH(16, 16, 68, 68);
      c.drawRect(area, _p(const Color(0xFF0A1440)));
      final cs = area.width / 6;
      final wall = _stroke(const Color(0xFF8FA8E8), 4);
      c.drawRect(area, wall);
      // Kapılar: üst (pembe), sağ (sarı), sol (yeşil)
      c.drawLine(Offset(area.left + 2 * cs, area.top), Offset(area.left + 4 * cs, area.top), _stroke(blockCols[0], 5));
      c.drawLine(Offset(area.right, area.top + 3 * cs), Offset(area.right, area.top + 5 * cs), _stroke(blockCols[2], 5));
      c.drawLine(Offset(area.left, area.top + 1 * cs), Offset(area.left, area.top + 2 * cs), _stroke(blockCols[3], 5));
      void bl(double x, double y, double w, double hh, Color col) => block(
          Rect.fromLTWH(area.left + x * cs + 0.8, area.top + y * cs + 0.8, w * cs - 1.6, hh * cs - 1.6), col);
      bl(2, -1.1, 2, 1, blockCols[0]); // kapıdan çıkıyor
      bl(4, 3, 1, 2, blockCols[2]);
      bl(1, 1, 1, 1, blockCols[3]);
      bl(0, 3, 2, 1, blockCols[5]);
      bl(2, 2, 1, 2, blockCols[6]);
      bl(3, 4, 1, 2, blockCols[1]);
      c.drawLine(Offset(area.left + 3 * cs, area.top + 1.2 * cs), Offset(area.left + 3 * cs, area.top + 0.2 * cs), _stroke(Colors.white54, 1.4));
    case 'b-egim': // Eğim kutusu: eğilmiş kutu, bloklar köşeye kaymış, gri taş, eriyen eşler
      plain(const Color(0xFF2050B8), deep);
      c.save();
      c.translate(50, 50);
      c.rotate(-0.22);
      const area = Rect.fromLTWH(-30, -30, 60, 60);
      c.drawRRect(RRect.fromRectAndRadius(area.inflate(4), const Radius.circular(6)), _p(const Color(0xFF8FA8E8)));
      c.drawRect(area, _p(const Color(0xFF0A1440)));
      final cs = area.width / 5;
      Rect cl(int x, int y) => Rect.fromLTWH(area.left + x * cs + 0.6, area.top + y * cs + 0.6, cs - 1.2, cs - 1.2);
      for (final (x, y, k) in const [(0, 4, 0), (1, 4, 3), (2, 4, 9), (3, 4, 5), (4, 4, 1), (0, 3, 5), (1, 3, 9), (4, 3, 1), (0, 2, 3)]) {
        if (k == 9) {
          c.drawRRect(RRect.fromRectAndRadius(cl(x, y), const Radius.circular(2)), _p(const Color(0xFF8D99AE)));
          c.drawLine(cl(x, y).topLeft + const Offset(3, 4), cl(x, y).center, _stroke(Colors.black26, 0.8));
        } else {
          block(cl(x, y), blockCols[k]);
        }
      }
      // Eriyen çift (sarı-sarı)
      for (final p in [cl(4, 4).center, cl(4, 3).center]) {
        c.drawCircle(p, cs * 0.55, _stroke(Colors.white70, 1));
      }
      c.restore();
      sparkle(const Offset(84, 52), 4.5, Colors.white);
      c.drawArc(const Rect.fromLTWH(10, 6, 30, 22), math.pi * 1.05, 0.9, false, _stroke(ice, 2.2));
      c.drawPath(poly(const [Offset(26, 4), Offset(32, 7), Offset(26, 11)]), _p(ice));
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(70.0 + i * 5, 90), Offset(64.0 + i * 5, 96), _stroke(Colors.white24, 1.2));
      }
    case 'b-kup': // Küp ustası: izometrik 3×3×3 küp, ayrılmış parça, döndürme oku
      plain(const Color(0xFF1E4BB4), deep);
      const s = 8.0;
      Offset iso(double x, double y, double z) => Offset(44 + (x - y) * s * 0.87, 56 + (x + y) * s * 0.5 - z * s);
      void cube(int x, int y, int z, Color col) {
        final t = [iso(x + 0.0, y + 0.0, z + 1.0), iso(x + 1.0, y + 0.0, z + 1.0), iso(x + 1.0, y + 1.0, z + 1.0), iso(x + 0.0, y + 1.0, z + 1.0)];
        final l = [iso(x + 0.0, y + 1.0, z + 1.0), iso(x + 1.0, y + 1.0, z + 1.0), iso(x + 1.0, y + 1.0, z + 0.0), iso(x + 0.0, y + 1.0, z + 0.0)];
        final r = [iso(x + 1.0, y + 0.0, z + 1.0), iso(x + 1.0, y + 1.0, z + 1.0), iso(x + 1.0, y + 1.0, z + 0.0), iso(x + 1.0, y + 0.0, z + 0.0)];
        c.drawPath(poly(t), _p(Color.lerp(col, Colors.white, 0.15)!));
        c.drawPath(poly(l), _p(Color.lerp(col, Colors.black, 0.2)!));
        c.drawPath(poly(r), _p(Color.lerp(col, Colors.black, 0.4)!));
        final e = _stroke(deep.withValues(alpha: 0.6), 0.6);
        c.drawPath(poly(t), e);
        c.drawPath(poly(l), e);
        c.drawPath(poly(r), e);
      }
      bool missing(int x, int y, int z) => (z == 2 && x >= 1 && y == 2) || (z == 2 && x == 2 && y == 1);
      for (var z = 0; z < 3; z++) {
        for (var y = 0; y < 3; y++) {
          for (var x = 0; x < 3; x++) {
            if (missing(x, y, z)) continue;
            cube(x, y, z, blockCols[(x + y * 2 + z * 3) % 3 == 0 ? 4 : ((x + z) % 2 == 0 ? 5 : 6)]);
          }
        }
      }
      // Ayrık parça (L üçlü) yukarıda
      c.save();
      c.translate(26, -30);
      cube(1, 2, 4, blockCols[1]);
      cube(2, 2, 4, blockCols[1]);
      cube(2, 1, 4, blockCols[1]);
      c.restore();
      c.drawArc(const Rect.fromLTWH(70, 4, 22, 22), 0.4, 4.6, false, _stroke(ice, 2));
      c.drawPath(poly(const [Offset(86, 24), Offset(91, 20), Offset(92, 27)]), _p(ice));
    case 'b-kule': // Denge kulesi (sıra tabanlı): çapraz katlı kule, yandan çekilen blok, tepeye ok
      plain(const Color(0xFF2050B8), deep);
      c.drawRect(const Rect.fromLTWH(0, 90, 100, 10), _p(const Color(0xFF0A1440)));
      const wood = [Color(0xFFE9C46A), Color(0xFFDDB15A), Color(0xFFF1D38A)];
      for (var lvl = 0; lvl < 8; lvl++) {
        final y = 82.0 - lvl * 9;
        if (lvl.isEven) {
          for (var i = 0; i < 3; i++) {
            if (lvl == 4 && i == 1) continue;
            final r = RRect.fromRectAndRadius(Rect.fromLTWH(32 + i * 12.0, y, 11.4, 8.4), const Radius.circular(1.5));
            c.drawRRect(r, _p(wood[(i + lvl) % 3]));
            c.drawRRect(r, _stroke(const Color(0xFF9C6644), 0.7));
          }
        } else {
          final r = RRect.fromRectAndRadius(Rect.fromLTWH(32, y, 35.4, 8.4), const Radius.circular(1.5));
          c.drawRRect(r, _p(wood[lvl % 3]));
          c.drawRRect(r, _stroke(const Color(0xFF9C6644), 0.7));
          c.drawLine(Offset(32, y + 4.2), Offset(67.4, y + 4.2), _stroke(const Color(0xFFB08850), 0.5));
        }
      }
      // Çekilen blok (sağa çıkmış)
      final pulled = RRect.fromRectAndRadius(const Rect.fromLTWH(70, 46, 11.4, 8.4), const Radius.circular(1.5));
      c.drawRRect(pulled, _p(const Color(0xFFFFB02E)));
      c.drawRRect(pulled, _stroke(Colors.white, 1));
      c.drawLine(const Offset(58, 50), const Offset(68, 50), _stroke(Colors.white54, 1.2));
      final up = Path()..moveTo(84, 44)..quadraticBezierTo(92, 20, 64, 12);
      c.drawPath(up, _stroke(ice, 2));
      c.drawPath(poly(const [Offset(66, 8), Offset(60, 12), Offset(66, 16)]), _p(ice));
      // Rakip simgesi (bilgisayar)
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 10, 18, 13), const Radius.circular(2)), _p(const Color(0xFF8FA8E8)));
      c.drawRect(const Rect.fromLTWH(10, 12, 14, 9), _p(deep));
      c.drawCircle(const Offset(14, 16.5), 1.2, _p(ice));
      c.drawCircle(const Offset(20, 16.5), 1.2, _p(ice));
      c.drawRect(const Rect.fromLTWH(14, 23, 6, 3), _p(const Color(0xFF8FA8E8)));
    case 'b-cesit': // Blok çeşitleri: her çeşit kendi tahtası ve özelliğiyle
      _paintBlokVariant(c, cover.v, block, boardRect, cellOf, piece, sparkle, h, blockCols);
    default:
      return false;
  }
  return true;
}

/// Blok Çeşit Paketi'nin 20 çeşidi (sıra paketteki `blokCesitleri` ile aynı).
const _blokVariantSpec = [
  (6, 0, 0xFFE2574C), // mini-6
  (7, 0, 0xFF9763BC), // yedili
  (9, 0, 0xFF4C63A8), // genis-9
  (10, 0, 0xFF3075C4), // buyuk-10
  (12, 0, 0xFF2BA39A), // dev-12
  (8, 0, 0xFF4E9A5E), // cizgiler
  (8, 0, 0xFF86A84A), // koseler
  (9, 0, 0xFFB9B03A), // kareler
  (10, 0, 0xFFE0A42E), // dortlu
  (10, 0, 0xFFE8853A), // besli
  (8, 0, 0xFF9C6644), // kolay
  (10, 0, 0xFF6C8EAD), // iri
  (8, 4, 0xFFD9577F), // dort-kutu
  (6, 2, 0xFFE58FB0), // ikili-kutu
  (12, 4, 0xFF7E5BB5), // dev-kutu
  (10, 5, 0xFF1A8BBB), // besli-kutu
  (9, 3, 0xFF2BB3B1), // kolay-sudoku
  (7, 0, 0xFF8A5A3C), // tasli
  (8, 0, 0xFF5FA8D3), // buzlu
  (8, 0, 0xFF1B998B), // elmas
];

void _paintBlokVariant(
  Canvas c,
  int v,
  void Function(Rect, Color) block,
  Rect Function(Rect, int, {int box, Color bg}) boardRect,
  Rect Function(Rect, int, int, int, [double]) cellOf,
  void Function(List<(int, int)>, Offset, double, Color) piece,
  void Function(Offset, double, Color) sparkle,
  int Function(int, int) h,
  List<Color> cols,
) {
  final i = v % _blokVariantSpec.length;
  final (n, box, argb) = _blokVariantSpec[i];
  final accent = Color(argb);
  final hsl = HSLColor.fromColor(accent);
  // Zemin: çeşidin kendi rengiyle koyulaştırılmış mavi.
  c.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
          Color.lerp(const Color(0xFF1E58C8), accent, 0.45)!,
          Color.lerp(const Color(0xFF0B1A52), hsl.withLightness(0.15).toColor(), 0.4)!,
        ]).createShader(const Rect.fromLTWH(0, 0, 100, 100)));
  const area = Rect.fromLTWH(16, 6, 68, 68);
  final a = boardRect(area, n, box: box);
  // Dolu hücreler (çeşide göre farklı desen)
  // Dolu hücre deseni çeşide göre değişir: alt sıralar, köşe, artı, çapraz, kenar sütunları, adacıklar.
  bool filled(int x, int y) {
    final k = h(x, y) % 7;
    final m = n - 1;
    switch (i % 6) {
      case 0:
        return (y >= n - 2 && k < 4) || (y == n - 3 && k < 2);
      case 1:
        return (x <= 1 || y >= m - 1) && k < 5;
      case 2:
        return ((x - m / 2).abs() < 1 || (y - m / 2).abs() < 1) && k < 5;
      case 3:
        return ((x - y).abs() <= 1 || (x + y - m).abs() == 0) && k < 5;
      case 4:
        return (x == 0 || x == m || y == m) && k < 5;
      default:
        return ((x ~/ 2 + y ~/ 2) % 3 == 0) && k < 4;
    }
  }

  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (filled(x, y)) block(cellOf(a, n, x, y, 0.35), Color.lerp(accent, cols[(x + y) % 8], 0.35)!);
    }
  }
  final cs = a.width / n;
  // Özel taşlar / tepside parça takımı
  const tray = Offset(0, 80);
  switch (i) {
    case 0: // mini 6x6: büyük hücreler, tek kare parça
      piece(const [(0, 0)], tray + const Offset(28, 2), 11, accent);
      piece(const [(0, 0), (1, 0)], tray + const Offset(52, 2), 11, cols[2]);
    case 1: // yedili: 7 rakamı ve L parça
      piece(const [(0, 0), (0, 1), (1, 1)], tray + const Offset(22, 1), 7, accent);
      piece(const [(0, 0), (1, 0), (2, 0)], tray + const Offset(58, 4), 7, cols[4]);
    case 2: // geniş 9x9: uzun yatay şerit temizliği
      c.drawRect(Rect.fromLTWH(a.left - 1, a.top + (n - 2) * cs - 1, a.width + 2, cs + 2), _stroke(Colors.white, 1.2));
      piece(const [(0, 0), (1, 0), (0, 1)], tray + const Offset(36, 1), 7, accent);
    case 3: // büyük 10x10: dört parça tepside
      for (var k = 0; k < 4; k++) {
        piece(const [(0, 0), (1, 0)], tray + Offset(12 + k * 20.0, 4), 6, cols[k * 2]);
      }
    case 4: // dev 12x12: büyüteç
      c.drawCircle(const Offset(72, 30), 12, Paint()..color = Colors.white24);
      c.drawCircle(const Offset(72, 30), 12, _stroke(Colors.white, 2.4));
      c.drawLine(const Offset(80.5, 38.5), const Offset(90, 48), _stroke(Colors.white, 4));
      piece(const [(0, 0), (1, 0), (2, 0), (1, 1)], tray + const Offset(36, 1), 6, accent);
    case 5: // çizgiler: yalnız düz çubuklar
      piece(const [(0, 0), (1, 0), (2, 0), (3, 0)], tray + const Offset(10, 4), 6.5, accent);
      piece(const [(0, 0), (1, 0), (2, 0)], tray + const Offset(48, 4), 6.5, cols[3]);
      piece(const [(0, 0), (1, 0)], tray + const Offset(76, 4), 6.5, cols[4]);
    case 6: // köşeler: L ve köşe parçaları
      piece(const [(0, 0), (0, 1), (1, 1)], tray + const Offset(12, 1), 7, accent);
      piece(const [(1, 0), (0, 1), (1, 1)], tray + const Offset(42, 1), 7, cols[1]);
      piece(const [(0, 0), (1, 0), (0, 1)], tray + const Offset(72, 1), 7, cols[5]);
    case 7: // kareler: kare bloklar
      piece(const [(0, 0), (1, 0), (0, 1), (1, 1)], tray + const Offset(18, 0), 7, accent);
      piece(const [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1), (0, 2), (1, 2), (2, 2)], tray + const Offset(56, -2), 5, cols[2]);
    case 8: // dörtlüler: T, S, L, I dörtlüleri
      piece(const [(0, 0), (1, 0), (2, 0), (1, 1)], tray + const Offset(6, 2), 6, accent);
      piece(const [(1, 0), (2, 0), (0, 1), (1, 1)], tray + const Offset(32, 2), 6, cols[3]);
      piece(const [(0, 0), (0, 1), (1, 1), (2, 1)], tray + const Offset(58, 2), 6, cols[6]);
      piece(const [(0, 0), (0, 1), (0, 2), (0, 3)], tray + const Offset(86, -4), 4.8, cols[4]);
    case 9: // uzun parçalar: beşli çubuk
      piece(const [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)], tray + const Offset(18, 4), 7, accent);
      c.drawLine(const Offset(14, 96), const Offset(86, 96), _stroke(Colors.white38, 1));
    case 10: // kolay parçalar: tekli ve ikililer, yaprak
      piece(const [(0, 0)], tray + const Offset(20, 4), 7, accent);
      piece(const [(0, 0), (1, 0)], tray + const Offset(40, 4), 7, cols[3]);
      piece(const [(0, 0)], tray + const Offset(68, 4), 7, cols[2]);
      c.drawOval(const Rect.fromLTWH(80, 8, 12, 7), _p(const Color(0xFF5BD67A)));
    case 11: // iri parçalar: 3x3 dolu blok
      piece(const [(0, 0), (1, 0), (2, 0), (0, 1), (1, 1), (2, 1)], tray + const Offset(16, 1), 7, accent);
      piece(const [(0, 0), (1, 0), (0, 1), (1, 1), (0, 2), (1, 2)], tray + const Offset(62, -2), 5.6, cols[5]);
    case 12 || 13 || 14 || 15 || 16: // kutulu çeşitler: dolu kutu parlıyor
      final bx = box;
      c.drawRect(Rect.fromLTWH(a.left, a.top, bx * cs, bx * cs), _p(Colors.white.withValues(alpha: 0.15)));
      for (var y = 0; y < bx; y++) {
        for (var x = 0; x < bx; x++) {
          block(cellOf(a, n, x, y, 0.35), accent);
        }
      }
      c.drawRect(Rect.fromLTWH(a.left, a.top, bx * cs, bx * cs), _stroke(Colors.white, 1.6));
      sparkle(Offset(a.left + bx * cs, a.top), 4.5, Colors.white);
      _text(c, '${n}x$n · $bx', const Offset(50, 89), 9, Colors.white);
    case 17: // taşlı: gri kaya engeller
      for (final (x, y) in const [(1, 1), (5, 1), (3, 3), (1, 4), (5, 4)]) {
        final r = cellOf(a, n, x, y, 0.8);
        c.drawPath(
            Path()
              ..moveTo(r.left, r.bottom)
              ..lineTo(r.left + r.width * 0.2, r.top + r.height * 0.3)
              ..lineTo(r.center.dx, r.top)
              ..lineTo(r.right - r.width * 0.1, r.top + r.height * 0.35)
              ..lineTo(r.right, r.bottom)
              ..close(),
            _p(const Color(0xFF8D99AE)));
      }
      piece(const [(0, 0), (1, 0), (1, 1)], tray + const Offset(40, 1), 7, accent);
    case 18: // buzlu: buz kaplı hücreler, kar tanesi
      for (final (x, y) in const [(2, 1), (5, 2), (1, 3), (4, 4), (6, 5), (3, 6)]) {
        final r = cellOf(a, n, x, y, 0.5);
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.5)), _p(const Color(0xFFBDE7FF).withValues(alpha: 0.85)));
        c.drawLine(r.topLeft + const Offset(1.5, 4), r.topLeft + const Offset(4, 1.5), _stroke(Colors.white, 0.8));
      }
      for (var k = 0; k < 3; k++) {
        final ang = k * math.pi / 3;
        c.drawLine(Offset(50 + math.cos(ang) * 7, 88 + math.sin(ang) * 7), Offset(50 - math.cos(ang) * 7, 88 - math.sin(ang) * 7),
            _stroke(Colors.white, 1.6));
      }
    default: // elmas: tahtaya gömülü mücevherler
      for (final (x, y, ci) in const [(1, 1, 0), (5, 2, 4), (3, 4, 6), (6, 5, 2)]) {
        final r = cellOf(a, n, x, y, 1);
        final o = r.center;
        final s = r.width / 2;
        c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy - s)
              ..lineTo(o.dx + s, o.dy - s * 0.2)
              ..lineTo(o.dx, o.dy + s)
              ..lineTo(o.dx - s, o.dy - s * 0.2)
              ..close(),
            _p(cols[ci]));
        c.drawLine(Offset(o.dx - s, o.dy - s * 0.2), Offset(o.dx + s, o.dy - s * 0.2), _stroke(Colors.white54, 0.6));
      }
      sparkle(const Offset(50, 89), 5, Colors.white);
  }
}
