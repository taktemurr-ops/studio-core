part of 'covers.dart';

/// Bulmaca ve Sayı merkezi, 2. kısım: mantık ızgaraları. Her oyunun kendi
/// kapağı; yardımcılar covers_bulmaca1.dart dosyasında. Döndürür: çizildiyse true.
bool _paintBulmaca2Cover(Canvas c, GameCover cover, Color seed) {
  switch (cover.kind) {
    case 'bz_logicgrid':
      _bzLogicGrid(c);
    case 'bz_nonogram':
      _bzNonogram(c);
    case 'bz_colornono':
      _bzColorNono(c);
    case 'bz_mines':
      _bzMines(c);
    case 'bz_binairo':
      _bzBinairo(c);
    case 'bz_slitherlink':
      _bzSlitherlink(c);
    case 'bz_bridges':
      _bzBridges(c);
    case 'bz_nurikabe':
      _bzNurikabe(c);
    case 'bz_starbattle':
      _bzStarBattle(c);
    case 'bz_tents':
      _bzTents(c);
    case 'bz_heyawake':
      _bzHeyawake(c);
    case 'bz_yajilin':
      _bzYajilin(c);
    case 'bz_battleships':
      _bzBattleships(c);
    case 'bz_aquarium':
      _bzAquarium(c);
    case 'bz_norinori':
      _bzNorinori(c);
    case 'bz_lits':
      _bzLits(c);
    case 'bz_tapa':
      _bzTapa(c);
    case 'bz_queens':
      _bzQueens(c);
    case 'bz_kuromasu':
      _bzKuromasu(c);
    case 'bz_range':
      _bzRange(c);
    case 'bz_lightup':
      _bzLightUp(c);
    case 'bz_magnets':
      _bzMagnets(c);
    case 'bz_pearl':
      _bzPearl(c);
    case 'bz_slant':
      _bzSlant(c);
    case 'bz_rectangles':
      _bzRectangles(c);
    case 'bz_galaxies':
      _bzGalaxies(c);
    case 'bz_tracks':
      _bzTracks(c);
    case 'bz_ghosts':
      _bzGhosts(c);
    case 'bz_fence':
      _bzFence(c);
    case 'bz_mosaic':
      _bzMosaic(c);
    case 'bz_mapcolor':
      _bzMapColor(c);
    case 'bz_blackbox':
      _bzBlackBox(c);
    case 'bz_logicpack':
      _bzLogicPack(c);
    default:
      return false;
  }
  return true;
}

Path _bzLoop(Rect g, int n, List<(int, int)> pts) {
  final p = Path();
  for (var i = 0; i < pts.length; i++) {
    final o = _bzCell(g, n, n, pts[i].$1, pts[i].$2).center;
    i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
  }
  return p..close();
}

void _bzCross(Canvas c, Offset o, double s, Color col, double w) {
  c.drawLine(o + Offset(-s, -s), o + Offset(s, s), _stroke(col, w));
  c.drawLine(o + Offset(s, -s), o + Offset(-s, s), _stroke(col, w));
}

void _bzCheck(Canvas c, Offset o, double s, Color col, double w) {
  c.drawPath(Path()..moveTo(o.dx - s, o.dy)..lineTo(o.dx - s * 0.3, o.dy + s * 0.7)..lineTo(o.dx + s, o.dy - s * 0.7), _stroke(col, w));
}

void _bzLogicGrid(Canvas c) {
  _bzBg(c, const Color(0xFF35307A));
  const g = Rect.fromLTWH(32, 32, 56, 56);
  _bzPanel(c, Rect.fromLTRB(12, 12, g.right, g.bottom), fill: const Color(0xFFF3F0FF), rad: 4);
  // başlıklar: şekiller (üst) ve renkler (sol)
  for (var i = 0; i < 4; i++) {
    final top = Offset(_bzCell(g, 4, 4, i, 0).center.dx, 22);
    final col = _pal[i + 1];
    switch (i) {
      case 0:
        c.drawCircle(top, 4.2, _p(col));
      case 1:
        c.drawRect(Rect.fromCenter(center: top, width: 8, height: 8), _p(col));
      case 2:
        c.drawPath(Path()..addPolygon([top + const Offset(0, -4.5), top + const Offset(4.5, 4), top + const Offset(-4.5, 4)], true), _p(col));
      default:
        c.drawPath(_bzStarPath(top, 5), _p(col));
    }
    final left = Offset(22, _bzCell(g, 4, 4, 0, i).center.dy);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: left, width: 13, height: 7), const Radius.circular(3.5)), _p(_pal[(i + 4) % 8]));
  }
  c.drawRect(g, _p(Colors.white));
  _bzLines(c, g, 4, 4, _stroke(const Color(0xFF35307A).withValues(alpha: 0.3), 0.7));
  _bzLines(c, g, 2, 2, _stroke(const Color(0xFF35307A), 1.4));
  c.drawRect(g, _stroke(const Color(0xFF35307A), 1.6));
  const marks = 'xvxx' 'xxvx' 'v.x.' 'x..v';
  for (var i = 0; i < 16; i++) {
    final o = _bzCell(g, 4, 4, i % 4, i ~/ 4).center;
    if (marks[i] == 'x') _bzCross(c, o, 2.4, const Color(0xFFE2574C), 1.3);
    if (marks[i] == 'v') _bzCheck(c, o, 3.6, const Color(0xFF2FA66A), 2);
  }
}

void _bzNonogram(Canvas c) {
  _bzBg(c, const Color(0xFF2458B8));
  const g = Rect.fromLTWH(34, 34, 54, 54);
  _bzPanel(c, const Rect.fromLTRB(10, 10, 90, 90), fill: const Color(0xFFEFF4FF), rad: 4);
  c.drawRect(const Rect.fromLTRB(34, 12, 88, 33), _p(const Color(0xFFDCE6FA)));
  c.drawRect(const Rect.fromLTRB(12, 34, 33, 88), _p(const Color(0xFFDCE6FA)));
  const pic = ['01010', '11111', '11111', '01110', '00100'];
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final r = _bzCell(g, 5, 5, x, y);
      c.drawRect(r, _p(Colors.white));
      if (pic[y][x] == '1' && !(y == 4 && x == 2)) c.drawRect(r.deflate(0.8), _p(const Color(0xFF1B2A4A)));
      if (pic[y][x] == '0' && (x + y).isEven) _bzCross(c, r.center, 1.6, Colors.black26, 0.8);
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black26, 0.6));
  c.drawRect(g, _stroke(_bzNavy, 1.4));
  const top = ['2', '4', '4', '4', '2'];
  const left = ['1 1', '5', '5', '3', '1'];
  for (var i = 0; i < 5; i++) {
    _text(c, top[i], Offset(_bzCell(g, 5, 5, i, 0).center.dx, 26), 6, const Color(0xFF2458B8));
    _text(c, left[i], Offset(23, _bzCell(g, 5, 5, 0, i).center.dy), 6, const Color(0xFF2458B8));
  }
}

void _bzColorNono(Canvas c) {
  _bzBg(c, const Color(0xFFC2477E));
  const g = Rect.fromLTWH(30, 30, 58, 58);
  _bzPanel(c, const Rect.fromLTRB(10, 10, 90, 90), fill: const Color(0xFFFFF2F7), rad: 4);
  const pic = ['.rr.rr', 'rryyrr', '.ryyr.', '..rr..', '.g.g..', '..gg..'];
  const cols = {'r': Color(0xFFE2574C), 'y': Color(0xFFF7C948), 'g': Color(0xFF3BA776)};
  for (var y = 0; y < 6; y++) {
    for (var x = 0; x < 6; x++) {
      final r = _bzCell(g, 6, 6, x, y);
      c.drawRect(r, _p(cols[pic[y][x]] ?? Colors.white));
    }
  }
  _bzLines(c, g, 6, 6, _stroke(Colors.black12, 0.5));
  c.drawRect(g, _stroke(const Color(0xFF7A1F48), 1.2));
  // renkli ipuçları
  const topClues = ['r', 'r', 'y', 'y', 'r', 'r'];
  for (var i = 0; i < 6; i++) {
    final o = Offset(_bzCell(g, 6, 6, i, 0).center.dx, 22);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 7.5, height: 9), const Radius.circular(2)), _p(cols[topClues[i]]!));
    _text(c, '${(i % 3) + 1}', o, 5.5, Colors.white);
    final l = Offset(20, _bzCell(g, 6, 6, 0, i).center.dy);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: l, width: 9, height: 7.5), const Radius.circular(2)),
        _p(cols[i < 4 ? (i == 1 || i == 2 ? 'y' : 'r') : 'g']!));
    _text(c, '${i % 2 + 1}', l, 5.5, Colors.white);
  }
}

void _bzMines(Canvas c) {
  _bzBg(c, const Color(0xFF5A6B7D));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  const open = ['..112', '..1x.', '1121.', 'f3...', '.....'];
  const numCol = {'1': Color(0xFF3075C4), '2': Color(0xFF2FA66A), '3': Color(0xFFE2574C)};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final r = _bzCell(g, 5, 5, x, y).deflate(0.8);
      final ch = open[y][x];
      final revealed = (y < 3 && ch != '.') || (y < 2 && x < 2) || (y == 2 && x < 4);
      if (revealed || ch == 'x') {
        c.drawRect(r, _p(const Color(0xFFE9EEF3)));
        if (numCol.containsKey(ch)) _text(c, ch, r.center, 9, numCol[ch]!);
        if (ch == 'x') {
          c.drawRect(r, _p(const Color(0xFFFFB4AB)));
          for (var k = 0; k < 4; k++) {
            final a = k * math.pi / 4;
            c.drawLine(r.center + Offset.fromDirection(a, 6), r.center - Offset.fromDirection(a, 6), _stroke(_bzNavy, 1.2));
          }
          c.drawCircle(r.center, 4, _p(_bzNavy));
          c.drawCircle(r.center + const Offset(-1.4, -1.4), 1.1, _p(Colors.white));
        }
      } else {
        final rr = RRect.fromRectAndRadius(r, const Radius.circular(2));
        c.drawRRect(rr, _p(const Color(0xFF8FA3B8)));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 1.4, r.top + 1.4, r.width - 2.8, 2.4), const Radius.circular(1)),
            _p(Colors.white.withValues(alpha: 0.45)));
        if (ch == 'f') {
          c.drawLine(r.center + const Offset(-1, 6), r.center + const Offset(-1, -6), _stroke(_bzNavy, 1.2));
          c.drawPath(Path()..addPolygon([r.center + const Offset(-1, -6), r.center + const Offset(6, -3), r.center + const Offset(-1, 0)], true),
              _p(const Color(0xFFE2574C)));
        }
      }
    }
  }
}

void _bzBinairo(Canvas c) {
  _bzBg(c, const Color(0xFF0F6E78));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, fill: const Color(0xFFDDEFF0), rad: 4);
  _bzLines(c, g, 6, 6, _stroke(const Color(0xFF0F6E78).withValues(alpha: 0.35), 0.6));
  const s = 'bw.bww' 'w.bw.b' '.wb.bw' 'bw.wb.' 'w.wb.b' '.bw.wb';
  for (var i = 0; i < 36; i++) {
    final ch = s[i];
    if (ch == '.') continue;
    final o = _bzCell(g, 6, 6, i % 6, i ~/ 6).center;
    _stone(c, o, 4.8, ch == 'b' ? const Color(0xFF1B2433) : Colors.white);
  }
}

void _bzSlitherlink(Canvas c) {
  _bzBg(c, const Color(0xFF1F2E4A));
  const n = 4;
  Offset pt(int x, int y) => Offset(16 + x * 17, 16 + y * 17);
  const loop = [(0, 0), (2, 0), (2, 1), (3, 1), (3, 0), (4, 0), (4, 3), (2, 3), (2, 4), (0, 4)];
  final path = Path();
  for (var i = 0; i < loop.length; i++) {
    final o = pt(loop[i].$1, loop[i].$2);
    i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
  }
  path.close();
  c.drawPath(path, _p(const Color(0xFF2FD3F5).withValues(alpha: 0.12)));
  c.drawPath(path, _stroke(_bzGold, 2.6));
  const nums = '3 2 ' ' 1 3' '2 0 ' ' 3  ';
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final ch = nums[y * n + x];
      if (ch != ' ') _text(c, ch, pt(x, y) + const Offset(8.5, 8.5), 8, Colors.white);
    }
  }
  for (var y = 0; y <= n; y++) {
    for (var x = 0; x <= n; x++) {
      c.drawCircle(pt(x, y), 1.8, _p(Colors.white));
    }
  }
}

void _bzBridges(Canvas c) {
  _bzBg(c, const Color(0xFF1C6FA8));
  final wave = _stroke(Colors.white.withValues(alpha: 0.12), 1.2);
  for (var y = 10.0; y < 100; y += 12) {
    c.drawPath(Path()..moveTo(0, y)..quadraticBezierTo(12, y - 3, 25, y)..quadraticBezierTo(38, y + 3, 50, y)..quadraticBezierTo(62, y - 3, 75, y)..quadraticBezierTo(88, y + 3, 100, y), wave);
  }
  const isl = [(20.0, 20.0, '3'), (78.0, 20.0, '4'), (20.0, 58.0, '2'), (78.0, 58.0, '5'), (50.0, 84.0, '1'), (78.0, 86.0, '3')];
  final plank = _stroke(const Color(0xFFD9A066), 2.2);
  void bridge(int a, int b, {bool dbl = false}) {
    final p = Offset(isl[a].$1, isl[a].$2), q = Offset(isl[b].$1, isl[b].$2);
    final n = Offset(-(q - p).dy, (q - p).dx) / (q - p).distance * 2.2;
    if (dbl) {
      c.drawLine(p + n, q + n, plank);
      c.drawLine(p - n, q - n, plank);
    } else {
      c.drawLine(p, q, plank);
    }
  }

  bridge(0, 1, dbl: true);
  bridge(0, 2);
  bridge(1, 3, dbl: true);
  bridge(2, 3);
  bridge(3, 5, dbl: true);
  bridge(4, 5);
  for (final (x, y, s) in isl) {
    c.drawCircle(Offset(x, y + 1.2), 8, _p(Colors.black26));
    c.drawCircle(Offset(x, y), 8, _p(const Color(0xFFF7E7C6)));
    c.drawCircle(Offset(x, y), 8, _stroke(const Color(0xFF8A5A36), 1.2));
    _text(c, s, Offset(x, y), 9, _bzNavy);
  }
}

void _bzNurikabe(Canvas c) {
  _bzBg(c, const Color(0xFF0B3954));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  const map = ['I.SSI', 'SSS.S', 'IS.SS', 'IS.S.', 'SSSSI'];
  const nums = {'0,0': '1', '4,0': '1', '3,1': '2', '0,2': '2', '2,2': '3', '4,4': '1'};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final r = _bzCell(g, 5, 5, x, y).deflate(0.7);
      final sea = map[y][x] == 'S';
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)),
          _p(sea ? const Color(0xFF07263A) : const Color(0xFFF6E7B8)));
      if (sea) {
        c.drawPath(Path()..moveTo(r.left + 3, r.center.dy)..quadraticBezierTo(r.center.dx - 2, r.center.dy - 2.5, r.center.dx, r.center.dy)
          ..quadraticBezierTo(r.center.dx + 2, r.center.dy + 2.5, r.right - 3, r.center.dy), _stroke(const Color(0xFF2FD3F5).withValues(alpha: 0.35), 0.9));
      }
      final n = nums['$x,$y'];
      if (n != null) _text(c, n, r.center, 9, const Color(0xFF6B4A12));
    }
  }
}

void _bzStarBattle(Canvas c) {
  _bzBg(c, const Color(0xFF2A1B5C));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  const map = ['AABBB', 'ACCBD', 'ECCDD', 'EECDD', 'EEEEE'];
  const tone = {'A': Color(0xFFB9A7F2), 'B': Color(0xFF9FD6F5), 'C': Color(0xFFF5C6E0), 'D': Color(0xFFBFE8C5), 'E': Color(0xFFFCE3A6)};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      c.drawRect(_bzCell(g, 5, 5, x, y), _p(tone[map[y][x]]!));
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  _bzRegions(c, g, map, _stroke(const Color(0xFF2A1B5C), 1.8));
  for (final (x, y) in const [(0, 0), (3, 0), (1, 2), (4, 3), (2, 4)]) {
    final o = _bzCell(g, 5, 5, x, y).center;
    c.drawPath(_bzStarPath(o + const Offset(0, 1), 6.2), _p(Colors.black26));
    c.drawPath(_bzStarPath(o, 6.2), _p(_bzGold));
  }
  for (final (x, y) in const [(10.0, 92.0), (92.0, 8.0), (94.0, 60.0)]) {
    c.drawCircle(Offset(x, y), 0.9, _p(Colors.white70));
  }
}

void _bzTents(Canvas c) {
  _bzBg(c, const Color(0xFF3E8E3A));
  const g = Rect.fromLTWH(20, 20, 66, 66);
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      c.drawRect(_bzCell(g, 5, 5, x, y).deflate(0.5), _p((x + y).isEven ? const Color(0xFFB8E08A) : const Color(0xFFA6D477)));
    }
  }
  void tree(Rect r) {
    c.drawRect(Rect.fromCenter(center: r.center + const Offset(0, 4), width: 2.4, height: 5), _p(const Color(0xFF7A4B2A)));
    c.drawCircle(r.center + const Offset(0, -1), 5, _p(const Color(0xFF1F6B3A)));
    c.drawCircle(r.center + const Offset(-1.5, -2.5), 2, _p(const Color(0xFF3BA776)));
  }

  void tent(Rect r) {
    final o = r.center;
    c.drawPath(Path()..addPolygon([o + const Offset(0, -6), o + const Offset(6.5, 5), o + const Offset(-6.5, 5)], true), _p(const Color(0xFFF08A4B)));
    c.drawPath(Path()..addPolygon([o + const Offset(0, -1), o + const Offset(2, 5), o + const Offset(-2, 5)], true), _p(const Color(0xFF8A3F0A)));
  }

  for (final (x, y) in const [(1, 0), (4, 1), (0, 3), (3, 3)]) {
    tree(_bzCell(g, 5, 5, x, y));
  }
  for (final (x, y) in const [(2, 0), (4, 2), (0, 2), (3, 4)]) {
    tent(_bzCell(g, 5, 5, x, y));
  }
  const top = ['1', '0', '1', '1', '1'];
  const left = ['1', '0', '2', '0', '1'];
  for (var i = 0; i < 5; i++) {
    _text(c, top[i], Offset(_bzCell(g, 5, 5, i, 0).center.dx, 13), 6.5, Colors.white);
    _text(c, left[i], Offset(12, _bzCell(g, 5, 5, 0, i).center.dy), 6.5, Colors.white);
  }
}

void _bzHeyawake(Canvas c) {
  _bzBg(c, const Color(0xFF9A4A2E));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, fill: const Color(0xFFFFF7EE), rad: 3);
  const map = ['AABBC', 'AABBC', 'DDEEC', 'DDEEF', 'GGGFF'];
  const black = {(1, 0), (3, 1), (0, 2), (2, 3), (4, 2), (1, 4), (4, 4)};
  for (final (x, y) in black) {
    c.drawRect(_bzCell(g, 5, 5, x, y).deflate(0.6), _p(const Color(0xFF3A1A10)));
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  _bzRegions(c, g, map, _stroke(const Color(0xFF5A2414), 2.2));
  for (final (x, y, s) in const [(0, 0, '1'), (2, 0, '1'), (0, 2, '1'), (2, 2, '1'), (0, 4, '1')]) {
    if (black.contains((x, y))) continue;
    _text(c, s, _bzCell(g, 5, 5, x, y).topLeft + const Offset(4, 4.5), 6, const Color(0xFF9A4A2E));
  }
  // beyaz yol bağlılığı ipucu
  c.drawPath(
      Path()
        ..moveTo(_bzCell(g, 5, 5, 0, 0).center.dx, _bzCell(g, 5, 5, 0, 0).center.dy)
        ..lineTo(_bzCell(g, 5, 5, 0, 1).center.dx, _bzCell(g, 5, 5, 0, 1).center.dy)
        ..lineTo(_bzCell(g, 5, 5, 2, 1).center.dx, _bzCell(g, 5, 5, 2, 1).center.dy)
        ..lineTo(_bzCell(g, 5, 5, 2, 2).center.dx, _bzCell(g, 5, 5, 2, 2).center.dy),
      _stroke(const Color(0xFF2FA66A).withValues(alpha: 0.55), 2));
}

void _bzYajilin(Canvas c) {
  _bzBg(c, const Color(0xFFB8892A));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  // ipucu hücreleri (sayı + ok) ve kara hücreler
  for (final (x, y, s, d) in const [(0, 0, '1', 0), (3, 2, '1', 1)]) {
    final r = _bzCell(g, 5, 5, x, y).deflate(0.6);
    c.drawRect(r, _p(const Color(0xFFDDD6C6)));
    _text(c, s, r.center + const Offset(-2.5, 0), 7, _bzNavy);
    const v = [Offset(1, 0), Offset(0, 1)];
    _bzArrow(c, r.center + const Offset(2.5, 0) - v[d] * 2.4, r.center + const Offset(2.5, 0) + v[d] * 3.6, _bzNavy, 0.9);
  }
  for (final (x, y) in const [(2, 0), (3, 3)]) {
    c.drawRect(_bzCell(g, 5, 5, x, y).deflate(0.6), _p(const Color(0xFF241A08)));
  }
  c.drawPath(_bzLoop(g, 5, const [(0, 1), (3, 1), (3, 0), (4, 0), (4, 4), (2, 4), (2, 2), (1, 2), (1, 4), (0, 4)]),
      _stroke(const Color(0xFFB8892A), 3));
}

void _bzBattleships(Canvas c) {
  _bzBg(c, const Color(0xFF14406B));
  const g = Rect.fromLTWH(22, 22, 66, 66);
  c.drawRect(g, _p(const Color(0xFF1E5F8E)));
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final r = _bzCell(g, 5, 5, x, y);
      if ((x * 2 + y) % 3 == 0) {
        c.drawPath(Path()..moveTo(r.left + 3, r.center.dy)..quadraticBezierTo(r.center.dx, r.center.dy - 3, r.right - 3, r.center.dy),
            _stroke(Colors.white30, 0.9));
      }
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.white24, 0.6));
  const hull = Color(0xFFCFD8DC);
  // 3'lük yatay gemi
  final a = _bzCell(g, 5, 5, 0, 1), b = _bzCell(g, 5, 5, 2, 1);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(a.left + 2, a.top + 3, b.right - 2, b.bottom - 3), const Radius.circular(7)), _p(hull));
  // 2'lik dikey gemi
  final d = _bzCell(g, 5, 5, 4, 2), e = _bzCell(g, 5, 5, 4, 3);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(d.left + 3, d.top + 2, e.right - 3, e.bottom - 2), const Radius.circular(7)), _p(hull));
  // denizaltı
  c.drawCircle(_bzCell(g, 5, 5, 1, 3).center, 5, _p(hull));
  c.drawCircle(_bzCell(g, 5, 5, 3, 4).center, 5, _p(hull));
  const top = ['1', '2', '1', '1', '2'];
  const left = ['0', '3', '1', '2', '1'];
  for (var i = 0; i < 5; i++) {
    _text(c, top[i], Offset(_bzCell(g, 5, 5, i, 0).center.dx, 14), 7, _bzGold);
    _text(c, left[i], Offset(14, _bzCell(g, 5, 5, 0, i).center.dy), 7, _bzGold);
  }
}

void _bzAquarium(Canvas c) {
  _bzBg(c, const Color(0xFF1A8FB0));
  const g = Rect.fromLTWH(22, 22, 66, 66);
  c.drawRect(g, _p(const Color(0xFFF2FBFF)));
  const map = ['AABCC', 'ABBCD', 'EEBDD', 'EFFFD', 'GGFHH'];
  const water = {'0,1', '1,2', '0,2', '1,1', '2,2', '2,1', '3,2', '4,2', '4,3', '3,1', '0,3', '1,3', '2,3', '3,3', '0,4', '1,4', '3,4', '4,4', '2,4'};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      if (!water.contains('$x,$y')) continue;
      final r = _bzCell(g, 5, 5, x, y);
      c.drawRect(r, _p(const Color(0xFF3AA6DD)));
      if (!water.contains('$x,${y - 1}')) {
        c.drawPath(Path()..moveTo(r.left, r.top + 1)..quadraticBezierTo(r.center.dx, r.top - 1.5, r.right, r.top + 1), _stroke(Colors.white70, 1));
      }
    }
  }
  c.drawCircle(_bzCell(g, 5, 5, 1, 3).center + const Offset(-2, 1), 1.4, _stroke(Colors.white70, 0.7));
  c.drawCircle(_bzCell(g, 5, 5, 1, 3).center + const Offset(1, -3), 0.9, _stroke(Colors.white70, 0.7));
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.5));
  _bzRegions(c, g, map, _stroke(const Color(0xFF0B3954), 2));
  for (var i = 0; i < 5; i++) {
    _text(c, '${const [3, 4, 4, 5, 3][i]}', Offset(_bzCell(g, 5, 5, i, 0).center.dx, 14), 7, Colors.white);
    _text(c, '${const [0, 4, 5, 5, 5][i]}', Offset(14, _bzCell(g, 5, 5, 0, i).center.dy), 7, Colors.white);
  }
}

void _bzNorinori(Canvas c) {
  _bzBg(c, const Color(0xFFE07A2E));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, fill: const Color(0xFFFFF5EA), rad: 3);
  const map = ['AABBC', 'ADDBC', 'EDFFC', 'EEFGG', 'HHHGG'];
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      if ('ADFH'.contains(map[y][x])) c.drawRect(_bzCell(g, 5, 5, x, y), _p(const Color(0xFFFFE0C2)));
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  _bzRegions(c, g, map, _stroke(const Color(0xFF7A3A0A), 1.8));
  for (final (x, y, h) in const [(0, 0, false), (3, 0, false), (2, 2, true), (4, 2, false), (0, 4, true), (3, 4, true)]) {
    final a = _bzCell(g, 5, 5, x, y), b = _bzCell(g, 5, 5, h ? x + 1 : x, h ? y : y + 1);
    final r = RRect.fromRectAndRadius(a.expandToInclude(b).deflate(2.2), const Radius.circular(5));
    c.drawRRect(r, _p(const Color(0xFF2A1A0E)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 2, r.top + 2, h ? r.width - 4 : 3, h ? 2 : r.height - 4), const Radius.circular(1)),
        _p(Colors.white24));
  }
}

void _bzLits(Canvas c) {
  _bzBg(c, const Color(0xFF3B4FA8));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  const map = ['AAABB', 'ACCBB', 'DCCCB', 'DDEEE', 'DDEEE'];
  // L, I, T, S dörtlüleri
  const shapes = [
    ([(0, 0), (1, 0), (2, 0), (0, 1)], Color(0xFFE2574C)), // L
    ([(4, 0), (4, 1), (4, 2), (3, 1)], Color(0xFFF2A93B)), // T
    ([(1, 2), (2, 2), (2, 1), (3, 1)], Color(0xFF3BA776)), // S
    ([(0, 2), (0, 3), (0, 4), (1, 4)], Color(0xFF9763BC)), // L
    ([(2, 3), (3, 3), (4, 3), (4, 4)], Color(0xFF2BB3B1)),
  ];
  for (final (cells, col) in shapes) {
    for (final (x, y) in cells) {
      if (map[y][x] == ' ') continue;
      c.drawRect(_bzCell(g, 5, 5, x, y).deflate(0.6), _p(col));
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  _bzRegions(c, g, map, _stroke(_bzNavy, 2));
}

void _bzTapa(Canvas c) {
  _bzBg(c, const Color(0xFF465566));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  const wall = ['##.##', '#...#', '#.#.#', '#.###', '###..'];
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      if (wall[y][x] == '#') c.drawRect(_bzCell(g, 5, 5, x, y).deflate(0.6), _p(const Color(0xFF263040)));
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  void clue(int x, int y, List<String> ns) {
    final r = _bzCell(g, 5, 5, x, y).deflate(0.6);
    c.drawRect(r, _p(const Color(0xFFF2F5F9)));
    c.drawRect(r.deflate(1), _stroke(const Color(0xFF465566), 0.7));
    if (ns.length == 1) {
      _text(c, ns[0], r.center, 8, _bzNavy);
    } else {
      for (var i = 0; i < ns.length; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / ns.length;
        _text(c, ns[i], r.center + Offset(math.cos(a) * 3.6, math.sin(a) * 3.6), 5, _bzNavy);
      }
    }
  }

  clue(2, 0, ['1', '1']);
  clue(2, 1, ['2', '1']);
  clue(1, 2, ['5']);
  clue(3, 2, ['1', '3']);
  clue(3, 4, ['3']);
}

void _bzCrown(Canvas c, Offset o, double s, Color col) {
  final p = Path()
    ..moveTo(o.dx - s, o.dy + s * 0.55)
    ..lineTo(o.dx - s, o.dy - s * 0.35)
    ..lineTo(o.dx - s * 0.45, o.dy + s * 0.05)
    ..lineTo(o.dx, o.dy - s * 0.65)
    ..lineTo(o.dx + s * 0.45, o.dy + s * 0.05)
    ..lineTo(o.dx + s, o.dy - s * 0.35)
    ..lineTo(o.dx + s, o.dy + s * 0.55)
    ..close();
  c.drawPath(p.shift(const Offset(0, 1)), _p(Colors.black26));
  c.drawPath(p, _p(col));
  for (final dx in [-1.0, 0.0, 1.0]) {
    c.drawCircle(Offset(o.dx + dx * s * (dx == 0 ? 0 : 1), o.dy - s * (dx == 0 ? 0.65 : 0.35)), s * 0.16, _p(col));
  }
}

void _bzQueens(Canvas c) {
  _bzBg(c, const Color(0xFF6A2B8F));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  const map = ['AABBB', 'ACCCB', 'DDCEB', 'DDEEE', 'DDDEE'];
  const tone = {'A': Color(0xFFF7A6B6), 'B': Color(0xFFA8D8F0), 'C': Color(0xFFFFD98A), 'D': Color(0xFFB7E4A8), 'E': Color(0xFFD3B8F5)};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      c.drawRect(_bzCell(g, 5, 5, x, y), _p(tone[map[y][x]]!));
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  _bzRegions(c, g, map, _stroke(const Color(0xFF2E1240), 1.6));
  for (final (x, y) in const [(0, 0), (2, 1), (4, 2), (1, 3), (3, 4)]) {
    _bzCrown(c, _bzCell(g, 5, 5, x, y).center + const Offset(0, 0.5), 5, const Color(0xFF2E1240));
  }
  for (final (x, y) in const [(1, 0), (2, 0), (0, 1)]) {
    _bzCross(c, _bzCell(g, 5, 5, x, y).center, 1.8, Colors.black38, 0.9);
  }
}

void _bzKuromasu(Canvas c) {
  _bzBg(c, const Color(0xFF16595A));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  // görüş çizgisi (2. satır)
  c.drawRect(Rect.fromLTRB(_bzCell(g, 5, 5, 1, 1).left, _bzCell(g, 5, 5, 1, 1).top, g.right, _bzCell(g, 5, 5, 1, 1).bottom),
      _p(const Color(0xFF2FD3F5).withValues(alpha: 0.25)));
  c.drawRect(Rect.fromLTRB(_bzCell(g, 5, 5, 1, 0).left, g.top, _bzCell(g, 5, 5, 1, 0).right, _bzCell(g, 5, 5, 1, 2).bottom),
      _p(const Color(0xFF2FD3F5).withValues(alpha: 0.25)));
  for (final (x, y) in const [(0, 1), (1, 3), (3, 0), (4, 4), (2, 4)]) {
    c.drawRect(_bzCell(g, 5, 5, x, y).deflate(0.6), _p(const Color(0xFF0E2E2F)));
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  for (final (x, y, s) in const [(1, 1, '6'), (4, 0, '3'), (0, 3, '4'), (3, 3, '7'), (2, 2, '5')]) {
    final o = _bzCell(g, 5, 5, x, y).center;
    c.drawCircle(o, 6.2, _p(Colors.white));
    c.drawCircle(o, 6.2, _stroke(const Color(0xFF16595A), 1.3));
    _text(c, s, o, 7.5, const Color(0xFF16595A));
  }
}

void _bzRange(Canvas c) {
  _bzBg(c, const Color(0xFF7A3E9D));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, fill: const Color(0xFFF9F2FF), rad: 3);
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  for (final (x, y) in const [(2, 0), (0, 2), (4, 1), (1, 4)]) {
    c.drawRect(_bzCell(g, 5, 5, x, y).deflate(0.6), _p(const Color(0xFF3A1650)));
  }
  final o = _bzCell(g, 5, 5, 2, 2).center;
  const yel = Color(0xFFFFC94A);
  // dört yöne ölçüm okları ve çentikler
  for (final (d, len) in const [(Offset(1, 0), 2), (Offset(-1, 0), 1), (Offset(0, 1), 2), (Offset(0, -1), 1)]) {
    final end = o + d * (len * 15.2 + 5);
    _bzArrow(c, o + d * 7, end, yel, 1.6);
    for (var k = 1; k <= len; k++) {
      final t = o + d * (k * 15.2);
      final n = Offset(d.dy, d.dx) * 2.4;
      c.drawLine(t - n, t + n, _stroke(const Color(0xFF7A3E9D), 1.2));
    }
  }
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 13, height: 13), const Radius.circular(3)), _p(const Color(0xFF7A3E9D)));
  _text(c, '7', o, 9, Colors.white);
  _text(c, '3', _bzCell(g, 5, 5, 4, 4).center, 8, const Color(0xFF7A3E9D));
  _text(c, '4', _bzCell(g, 5, 5, 0, 0).center, 8, const Color(0xFF7A3E9D));
}

void _bzLightUp(Canvas c) {
  _bzBg(c, const Color(0xFF101830));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  c.drawRect(g, _p(const Color(0xFF243049)));
  const lit = Color(0xFFFFE9A0);
  final bulbs = const [(1, 1), (3, 3), (4, 0)];
  // ışık alan hücreler
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final on = bulbs.any((b) => b.$1 == x || b.$2 == y) && !(x == 2 && y == 2) && !(x == 0 && y == 3);
      c.drawRect(_bzCell(g, 5, 5, x, y).deflate(0.6), _p(on ? lit.withValues(alpha: 0.55) : const Color(0xFF2E3B58)));
    }
  }
  for (final (x, y, s) in const [(2, 2, '2'), (0, 3, '0'), (2, 4, '')]) {
    final r = _bzCell(g, 5, 5, x, y).deflate(0.6);
    c.drawRect(r, _p(const Color(0xFF0A0F1C)));
    if (s.isNotEmpty) _text(c, s, r.center, 8, Colors.white);
  }
  for (final (x, y) in bulbs) {
    final o = _bzCell(g, 5, 5, x, y).center;
    c.drawCircle(o, 8, _p(_bzGold.withValues(alpha: 0.35)));
    c.drawCircle(o + const Offset(0, -1), 4, _p(const Color(0xFFFFD23F)));
    c.drawRect(Rect.fromCenter(center: o + const Offset(0, 4), width: 3.4, height: 2.6), _p(const Color(0xFF8A93A6)));
  }
}

void _bzMagnets(Canvas c) {
  _bzBg(c, const Color(0xFF4A4F5A));
  const g = Rect.fromLTWH(20, 20, 66, 66);
  const plus = Color(0xFFE2574C), minus = Color(0xFF3075C4);
  // (x, y, yatay mı, ilk yarı: 1 artı, -1 eksi, 0 nötr)
  for (final (x, y, h, s) in const [(0, 0, true, 1), (2, 0, false, -1), (3, 0, true, 0), (0, 1, false, -1), (1, 1, true, 1),
      (3, 1, false, 1), (4, 1, false, 0), (1, 2, false, 0), (2, 2, true, -1), (0, 3, true, 1), (2, 3, false, 1), (3, 3, true, -1), (0, 4, true, 0), (3, 4, true, 1)]) {
    final a = _bzCell(g, 5, 5, x, y), b = _bzCell(g, 5, 5, h ? x + 1 : x, h ? y : y + 1);
    final r = RRect.fromRectAndRadius(a.expandToInclude(b).deflate(1.2), const Radius.circular(3));
    c.drawRRect(r, _p(s == 0 ? const Color(0xFF8A919E) : Colors.white));
    if (s != 0) {
      c.save();
      c.clipRRect(r);
      c.drawRect(a, _p(s == 1 ? plus : minus));
      c.drawRect(b, _p(s == 1 ? minus : plus));
      c.restore();
      for (final (cell, pl) in [(a, s == 1), (b, s != 1)]) {
        c.drawLine(cell.center - const Offset(3, 0), cell.center + const Offset(3, 0), _stroke(Colors.white, 1.6));
        if (pl) c.drawLine(cell.center - const Offset(0, 3), cell.center + const Offset(0, 3), _stroke(Colors.white, 1.6));
      }
    }
  }
  for (var i = 0; i < 5; i++) {
    _text(c, '${const [2, 1, 2, 2, 1][i]}', Offset(_bzCell(g, 5, 5, i, 0).center.dx, 13), 6, plus.withValues(alpha: 1));
    _text(c, '${const [1, 2, 1, 2, 1][i]}', Offset(12, _bzCell(g, 5, 5, 0, i).center.dy), 6, const Color(0xFF9EC5F5));
  }
}

void _bzPearl(Canvas c) {
  _bzBg(c, const Color(0xFF3A5A7A));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, fill: const Color(0xFFF7F4EE), rad: 3);
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  final loop = _bzLoop(g, 5, const [(0, 0), (3, 0), (3, 1), (4, 1), (4, 4), (2, 4), (2, 2), (1, 2), (1, 3), (0, 3)]);
  c.drawPath(loop, _stroke(const Color(0xFF3A5A7A), 3));
  for (final (x, y, black) in const [(3, 0, true), (2, 4, true), (0, 1, false), (4, 2, false), (2, 3, false), (1, 2, true)]) {
    final o = _bzCell(g, 5, 5, x, y).center;
    c.drawCircle(o + const Offset(0, 0.8), 5, _p(Colors.black26));
    if (black) {
      _stone(c, o, 5, const Color(0xFF1B2433));
    } else {
      c.drawCircle(o, 5, _p(Colors.white));
      c.drawCircle(o, 5, _stroke(const Color(0xFF1B2433), 1.4));
      c.drawCircle(o + const Offset(-1.6, -1.6), 1.2, _p(const Color(0xFFDDE6F0)));
    }
  }
}

void _bzSlant(Canvas c) {
  _bzBg(c, const Color(0xFFB8925A));
  const g = Rect.fromLTWH(14, 14, 72, 72);
  _bzPanel(c, g, fill: const Color(0xFFFFF8EA), rad: 2);
  _bzLines(c, g, 4, 4, _stroke(Colors.black12, 0.6));
  const s = '\\//\\' '/\\\\/' '\\/\\/' '//\\\\';
  for (var i = 0; i < 16; i++) {
    final r = _bzCell(g, 4, 4, i % 4, i ~/ 4).deflate(1.5);
    s[i] == '\\'
        ? c.drawLine(r.topLeft, r.bottomRight, _stroke(const Color(0xFF5A3A16), 2.2))
        : c.drawLine(r.topRight, r.bottomLeft, _stroke(const Color(0xFF5A3A16), 2.2));
  }
  for (final (x, y, n) in const [(1, 0, '1'), (3, 1, '2'), (0, 2, '1'), (2, 2, '3'), (4, 3, '0'), (1, 4, '1'), (2, 1, '2')]) {
    final o = Offset(g.left + x * 18, g.top + y * 18);
    c.drawCircle(o, 4.2, _p(Colors.white));
    c.drawCircle(o, 4.2, _stroke(const Color(0xFF5A3A16), 1));
    _text(c, n, o, 5.5, const Color(0xFF5A3A16));
  }
}

void _bzRectangles(Canvas c) {
  _bzBg(c, const Color(0xFF2F8F83));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  // (x, y, w, h, renk)
  for (final (x, y, w, h, k) in const [(0, 0, 2, 2, 0), (2, 0, 3, 1, 2), (2, 1, 1, 3, 3), (3, 1, 2, 2, 5), (0, 2, 2, 1, 4), (0, 3, 2, 2, 6),
      (3, 3, 2, 1, 1), (2, 4, 3, 1, 7)]) {
    final r = Rect.fromLTRB(_bzCell(g, 5, 5, x, y).left, _bzCell(g, 5, 5, x, y).top, _bzCell(g, 5, 5, x + w - 1, y + h - 1).right,
            _bzCell(g, 5, 5, x + w - 1, y + h - 1).bottom)
        .deflate(1.4);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
    c.drawRRect(rr, _p(_pal[k].withValues(alpha: 0.35)));
    c.drawRRect(rr, _stroke(_pal[k], 1.6));
    final cell = _bzCell(g, 5, 5, x + (w - 1) ~/ 2, y + (h - 1) ~/ 2);
    _text(c, '${w * h}', cell.center, 8, _bzNavy);
  }
}

void _bzGalaxies(Canvas c) {
  c.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = const RadialGradient(center: Alignment(0.2, -0.2), radius: 1.1, colors: [Color(0xFF3B2A7A), Color(0xFF140F3A), Color(0xFF07061A)])
            .createShader(const Rect.fromLTWH(0, 0, 100, 100)));
  final rnd = math.Random(7);
  for (var i = 0; i < 40; i++) {
    c.drawCircle(Offset(rnd.nextDouble() * 100, rnd.nextDouble() * 100), rnd.nextDouble() * 0.7 + 0.2, _p(Colors.white.withValues(alpha: 0.6)));
  }
  const g = Rect.fromLTWH(14, 14, 72, 72);
  _bzLines(c, g, 6, 6, _stroke(Colors.white12, 0.5));
  c.drawRect(g, _stroke(Colors.white24, 0.8));
  // simetrik bölgeler
  const regs = [
    ([(0, 0), (1, 0), (0, 1), (1, 1)], Color(0xFF9F7AEA)),
    ([(2, 0), (3, 0), (4, 0), (2, 1), (3, 1), (4, 1)], Color(0xFF4FD1C5)),
    ([(5, 0), (5, 1), (5, 2), (5, 3)], Color(0xFFF687B3)),
    ([(0, 2), (1, 2), (2, 2), (0, 3), (1, 3), (2, 3)], Color(0xFFF6AD55)),
    ([(3, 2), (4, 2), (3, 3), (4, 3), (3, 4), (4, 4)], Color(0xFF63B3ED)),
    ([(0, 4), (1, 4), (2, 4), (0, 5), (1, 5), (2, 5)], Color(0xFF68D391)),
  ];
  for (final (cells, col) in regs) {
    for (final (x, y) in cells) {
      c.drawRect(_bzCell(g, 6, 6, x, y).deflate(0.4), _p(col.withValues(alpha: 0.38)));
    }
  }
  // merkez noktaları (hücre köşesi, kenarı ya da ortası)
  for (final o in const [Offset(26, 26), Offset(50, 26), Offset(80, 38), Offset(32, 50), Offset(62, 56), Offset(32, 74)]) {
    c.drawCircle(o, 4.4, _p(Colors.white.withValues(alpha: 0.25)));
    c.drawCircle(o, 2.6, _p(Colors.white));
  }
}

void _bzTracks(Canvas c) {
  _bzBg(c, const Color(0xFF5B7A3A));
  const g = Rect.fromLTWH(20, 20, 66, 66);
  c.drawRect(g, _p(const Color(0xFFD9C79A)));
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  const route = [(-1, 1), (0, 1), (1, 1), (1, 2), (1, 3), (2, 3), (3, 3), (3, 2), (3, 1), (4, 1), (4, 2), (4, 3), (4, 4), (4, 5)];
  final pts = [for (final (x, y) in route) Offset(g.left + (x + 0.5) * 13.2, g.top + (y + 0.5) * 13.2)];
  // traversler
  for (var i = 0; i < pts.length - 1; i++) {
    final a = pts[i], b = pts[i + 1];
    final d = (b - a) / (b - a).distance;
    final n = Offset(-d.dy, d.dx);
    for (final t in [0.25, 0.75]) {
      final m = Offset.lerp(a, b, t)!;
      c.drawLine(m - n * 4.2, m + n * 4.2, _stroke(const Color(0xFF7A4B2A), 1.8));
    }
  }
  final rail = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final p in pts.skip(1)) {
    rail.lineTo(p.dx, p.dy);
  }
  c.drawPath(rail, _stroke(const Color(0xFF8E9AA8), 5.4));
  c.drawPath(rail, _stroke(const Color(0xFFD9C79A), 3));
  // lokomotif
  final o = pts[2] + const Offset(0, 2);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 10, height: 7), const Radius.circular(2)), _p(const Color(0xFFE2574C)));
  c.drawRect(Rect.fromCenter(center: o + const Offset(2, -4.5), width: 3, height: 3), _p(_bzNavy));
  for (var i = 0; i < 5; i++) {
    _text(c, '${const [1, 4, 1, 3, 5][i]}', Offset(_bzCell(g, 5, 5, i, 0).center.dx, 13), 6.5, Colors.white);
    _text(c, '${const [0, 4, 2, 4, 2][i]}', Offset(12, _bzCell(g, 5, 5, 0, i).center.dy), 6.5, Colors.white);
  }
}

void _bzGhosts(Canvas c) {
  _bzBg(c, const Color(0xFF3D2466));
  const g = Rect.fromLTWH(20, 20, 66, 66);
  c.drawRect(g, _p(const Color(0xFF241540)));
  _bzLines(c, g, 4, 4, _stroke(Colors.white12, 0.6));
  final mirror = _stroke(const Color(0xFFC8D6E5), 2.2);
  for (final (x, y, back) in const [(1, 0, true), (3, 1, false), (0, 2, false), (2, 3, true)]) {
    final r = _bzCell(g, 4, 4, x, y).deflate(2);
    back ? c.drawLine(r.topLeft, r.bottomRight, mirror) : c.drawLine(r.topRight, r.bottomLeft, mirror);
  }
  void ghost(Offset o) {
    final p = Path()
      ..moveTo(o.dx - 5.5, o.dy + 6)
      ..lineTo(o.dx - 5.5, o.dy - 1)
      ..arcToPoint(Offset(o.dx + 5.5, o.dy - 1), radius: const Radius.circular(5.5))
      ..lineTo(o.dx + 5.5, o.dy + 6)
      ..lineTo(o.dx + 3, o.dy + 4)
      ..lineTo(o.dx + 1, o.dy + 6)
      ..lineTo(o.dx - 1, o.dy + 4)
      ..lineTo(o.dx - 3, o.dy + 6)
      ..close();
    c.drawPath(p, _p(const Color(0xFFF2F0FF)));
    c.drawCircle(o + const Offset(-2, -1), 1.1, _p(_bzNavy));
    c.drawCircle(o + const Offset(2, -1), 1.1, _p(_bzNavy));
  }

  void bat(Offset o) {
    final p = Path()
      ..moveTo(o.dx, o.dy - 1)
      ..quadraticBezierTo(o.dx - 3, o.dy - 5, o.dx - 7, o.dy - 3)
      ..quadraticBezierTo(o.dx - 5, o.dy, o.dx - 6, o.dy + 3)
      ..quadraticBezierTo(o.dx - 3, o.dy + 1, o.dx, o.dy + 3)
      ..quadraticBezierTo(o.dx + 3, o.dy + 1, o.dx + 6, o.dy + 3)
      ..quadraticBezierTo(o.dx + 5, o.dy, o.dx + 7, o.dy - 3)
      ..quadraticBezierTo(o.dx + 3, o.dy - 5, o.dx, o.dy - 1)
      ..close();
    c.drawPath(p, _p(const Color(0xFF9F7AEA)));
    c.drawCircle(o + const Offset(-1, -0.5), 0.7, _p(_bzGold));
    c.drawCircle(o + const Offset(1, -0.5), 0.7, _p(_bzGold));
  }

  ghost(_bzCell(g, 4, 4, 0, 0).center);
  ghost(_bzCell(g, 4, 4, 2, 2).center);
  bat(_bzCell(g, 4, 4, 3, 0).center);
  c.drawCircle(_bzCell(g, 4, 4, 1, 3).center, 5.5, _p(const Color(0xFF68D391)));
  c.drawCircle(_bzCell(g, 4, 4, 1, 3).center + const Offset(-1.8, -1), 1, _p(_bzNavy));
  c.drawCircle(_bzCell(g, 4, 4, 1, 3).center + const Offset(1.8, -1), 1, _p(_bzNavy));
  for (var i = 0; i < 4; i++) {
    _text(c, '${const [2, 0, 1, 3][i]}', Offset(_bzCell(g, 4, 4, i, 0).center.dx, 13), 6.5, Colors.white70);
    _text(c, '${const [1, 2, 2, 0][i]}', Offset(12, _bzCell(g, 4, 4, 0, i).center.dy), 6.5, Colors.white70);
  }
}

void _bzFence(Canvas c) {
  _bzBg(c, const Color(0xFF5E8F3E));
  const g = Rect.fromLTWH(14, 14, 72, 72);
  c.drawRRect(RRect.fromRectAndRadius(g, const Radius.circular(3)), _p(const Color(0xFF8CC063)));
  for (var i = 0; i < 30; i++) {
    final x = g.left + (i * 37 % 70) + 1, y = g.top + (i * 53 % 70) + 1;
    c.drawLine(Offset(x, y + 2), Offset(x + 1, y), _stroke(const Color(0xFF4E8A2E), 0.8));
  }
  final rail = _stroke(const Color(0xFF8A5A36), 2.6);
  final segs = const [
    [(0, 2), (2, 2), (2, 0)],
    [(2, 2), (2, 4)],
    [(2, 2), (4, 2)],
  ];
  Offset pt(int x, int y) => Offset(g.left + x * 18, g.top + y * 18);
  for (final s in segs) {
    for (var i = 0; i < s.length - 1; i++) {
      c.drawLine(pt(s[i].$1, s[i].$2), pt(s[i + 1].$1, s[i + 1].$2), rail);
      c.drawLine(pt(s[i].$1, s[i].$2) + const Offset(0, 2.4), pt(s[i + 1].$1, s[i + 1].$2) + const Offset(0, 2.4), _stroke(const Color(0xFF5E3A1E), 1));
    }
  }
  for (var y = 0; y <= 4; y++) {
    for (var x = 0; x <= 4; x++) {
      final o = pt(x, y);
      c.drawRect(Rect.fromCenter(center: o, width: 2.6, height: 4.2), _p(const Color(0xFF5E3A1E)));
    }
  }
  for (final o in const [Offset(32, 32), Offset(68, 32), Offset(32, 68), Offset(68, 68)]) {
    _bzBadge(c, o, 6.5, '4', Colors.white, text: const Color(0xFF3E6B22));
  }
}

void _bzMosaic(Canvas c) {
  _bzBg(c, const Color(0xFF2C7DA0));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  const pic = ['.###.', '#.#.#', '#####', '#...#', '.###.'];
  const nums = {'0,0': '3', '2,0': '5', '4,1': '4', '1,2': '7', '3,3': '4', '0,4': '2', '2,4': '6', '4,4': '3', '2,2': '6'};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final r = _bzCell(g, 5, 5, x, y);
      final on = pic[y][x] == '#';
      if (on) c.drawRect(r.deflate(0.6), _p(const Color(0xFF1F5F7A)));
      final n = nums['$x,$y'];
      if (n != null) _text(c, n, r.center, 8, on ? Colors.white : const Color(0xFF1F5F7A));
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  // 3x3 komşuluk vurgusu
  c.drawRect(Rect.fromLTRB(_bzCell(g, 5, 5, 0, 1).left, _bzCell(g, 5, 5, 0, 1).top, _bzCell(g, 5, 5, 2, 3).right, _bzCell(g, 5, 5, 2, 3).bottom),
      _stroke(_bzGold, 1.8));
}

void _bzMapColor(Canvas c) {
  _bzBg(c, const Color(0xFF3C6E8F));
  const cols = [Color(0xFFE2574C), Color(0xFFF2C14E), Color(0xFF3BA776), Color(0xFF5B8DEF)];
  final regions = <(List<Offset>, int)>[
    (const [Offset(12, 14), Offset(46, 12), Offset(42, 40), Offset(14, 44)], 0),
    (const [Offset(46, 12), Offset(88, 16), Offset(84, 36), Offset(60, 44), Offset(42, 40)], 1),
    (const [Offset(14, 44), Offset(42, 40), Offset(50, 64), Offset(30, 80), Offset(12, 74)], 2),
    (const [Offset(42, 40), Offset(60, 44), Offset(66, 66), Offset(50, 64)], 3),
    (const [Offset(60, 44), Offset(84, 36), Offset(88, 70), Offset(66, 66)], 0),
    (const [Offset(12, 74), Offset(30, 80), Offset(50, 64), Offset(66, 66), Offset(70, 88), Offset(16, 88)], 1),
    (const [Offset(66, 66), Offset(88, 70), Offset(86, 88), Offset(70, 88)], 2),
  ];
  for (final (pts, k) in regions) {
    final p = Path()..addPolygon(pts, true);
    c.drawPath(p.shift(const Offset(0, 1.4)), _p(Colors.black26));
    c.drawPath(p, _p(k == 1 && pts.length == 6 ? Colors.white : cols[k]));
    c.drawPath(p, _stroke(Colors.white, 1.6));
  }
  // fırça
  c.save();
  c.translate(48, 78);
  c.rotate(-0.6);
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -18, 4, 14), const Radius.circular(2)), _p(const Color(0xFF8A5A36)));
  c.drawRect(const Rect.fromLTWH(-2.6, -5, 5.2, 3), _p(const Color(0xFFB0B7C3)));
  c.drawPath(Path()..moveTo(-2.6, -2)..lineTo(2.6, -2)..quadraticBezierTo(1, 5, 0, 6)..quadraticBezierTo(-1, 5, -2.6, -2)..close(), _p(cols[1]));
  c.restore();
}

void _bzBlackBox(Canvas c) {
  _bzBg(c, const Color(0xFF1A1A22));
  const g = Rect.fromLTWH(22, 22, 56, 56);
  c.drawRRect(RRect.fromRectAndRadius(g.inflate(3), const Radius.circular(4)), _p(const Color(0xFF3A3A48)));
  c.drawRect(g, _p(const Color(0xFF0B0B10)));
  _bzLines(c, g, 4, 4, _stroke(Colors.white10, 0.6));
  // gizli toplar (biri belirlenmiş)
  _stone(c, _bzCell(g, 4, 4, 2, 1).center, 5, const Color(0xFF7A7F8C));
  c.drawCircle(_bzCell(g, 4, 4, 0, 3).center, 5, _stroke(Colors.white24, 1));
  // ışın: soldan girer, sapar, alttan çıkar
  const ray = Color(0xFF2FD3F5);
  final y0 = _bzCell(g, 4, 4, 0, 2).center.dy;
  final x1 = _bzCell(g, 4, 4, 1, 0).center.dx;
  c.drawPath(Path()..moveTo(10, y0)..lineTo(x1, y0)..lineTo(x1, 90), _stroke(ray.withValues(alpha: 0.35), 4));
  c.drawPath(Path()..moveTo(10, y0)..lineTo(x1, y0)..lineTo(x1, 90), _stroke(ray, 1.6));
  _bzArrow(c, Offset(x1, 82), Offset(x1, 92), ray, 1.6);
  // kenar işaretleri
  _bzBadge(c, Offset(10, y0), 4.5, '1', _bzGold, text: _bzNavy);
  _bzBadge(c, const Offset(90, 36), 4.5, 'H', const Color(0xFFE2574C));
  _bzBadge(c, const Offset(64, 10), 4.5, 'R', const Color(0xFF9F7AEA));
}

void _bzLogicPack(Canvas c) {
  _bzBg(c, const Color(0xFF24508A));
  void tile(Rect r, int k) {
    final rr = _bzPanel(c, r, rad: 4);
    c.save();
    c.clipRRect(rr);
    final g = r.deflate(5);
    switch (k) {
      case 0: // mini resim ızgarası
        const pic = ['0110', '1111', '0110', '0100'];
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            if (pic[y][x] == '1') c.drawRect(_bzCell(g, 4, 4, x, y).deflate(0.5), _p(_bzNavy));
          }
        }
      case 1: // köprüler
        c.drawLine(g.topLeft + const Offset(5, 5), g.topRight + const Offset(-5, 5), _stroke(const Color(0xFFD9A066), 1.6));
        c.drawLine(g.topLeft + const Offset(5, 5), g.bottomLeft + const Offset(5, -5), _stroke(const Color(0xFFD9A066), 1.6));
        for (final o in [g.topLeft + const Offset(5, 5), g.topRight + const Offset(-5, 5), g.bottomLeft + const Offset(5, -5)]) {
          c.drawCircle(o, 4, _p(const Color(0xFF3075C4)));
        }
      case 2: // yıldızlar
        _bzLines(c, g, 3, 3, _stroke(Colors.black12, 0.5));
        c.drawPath(_bzStarPath(_bzCell(g, 3, 3, 0, 0).center, 3.4), _p(const Color(0xFFF2A93B)));
        c.drawPath(_bzStarPath(_bzCell(g, 3, 3, 2, 1).center, 3.4), _p(const Color(0xFFF2A93B)));
        c.drawPath(_bzStarPath(_bzCell(g, 3, 3, 1, 2).center, 3.4), _p(const Color(0xFFF2A93B)));
      default: // döngü
        c.drawRRect(RRect.fromRectAndRadius(g.deflate(3), const Radius.circular(2)), _stroke(const Color(0xFFE2574C), 1.8));
        c.drawCircle(g.center, 2.4, _p(_bzNavy));
    }
    c.restore();
  }

  tile(const Rect.fromLTWH(12, 12, 36, 36), 0);
  tile(const Rect.fromLTWH(52, 12, 36, 36), 1);
  tile(const Rect.fromLTWH(12, 52, 36, 36), 2);
  tile(const Rect.fromLTWH(52, 52, 36, 36), 3);
  _bzBadge(c, const Offset(50, 50), 10, '30', _bzCyan, text: _bzNavy);
}
