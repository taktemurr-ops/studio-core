part of 'covers.dart';

/// Bulmaca ve Sayı merkezi, 1. kısım: ortak yardımcılar ve sayı bulmacaları.
/// Her oyunun kendi kapağı vardır (tür adı `bz_` ile başlar); hepsi vektördür,
/// dış görsel ya da marka kullanılmaz. Döndürür: çizildiyse true.
bool _paintBulmaca1Cover(Canvas c, GameCover cover, Color seed) {
  switch (cover.kind) {
    case 'bz_sudoku':
      _bzSudoku(c);
    case 'bz_sudokupack':
      _bzSudokuPack(c);
    case 'bz_killer':
      _bzKiller(c);
    case 'bz_sudokuvar':
      _bzSudokuVariants(c);
    case 'bz_skyscraper':
      _bzSkyscraper(c);
    case 'bz_kakuro':
      _bzKakuro(c);
    case 'bz_kenken':
      _bzKenken(c);
    case 'bz_futoshiki':
      _bzFutoshiki(c);
    case 'bz_mathcross':
      _bzMathCross(c);
    case 'bz_numberlink':
      _bzNumberlink(c);
    case 'bz_hidato':
      _bzHidato(c);
    case 'bz_fillomino':
      _bzFillomino(c);
    case 'bz_suguru':
      _bzSuguru(c);
    case 'bz_kakurasu':
      _bzKakurasu(c);
    case 'bz_sumplete':
      _bzSumplete(c);
    case 'bz_numbermatch':
      _bzNumberMatch(c);
    case 'bz_2048':
      _bz2048(c);
    case 'bz_mergechain':
      _bzMergeChain(c);
    case 'bz_fifteen':
      _bzFifteen(c);
    case 'bz_sixteen':
      _bzSixteen(c);
    case 'bz_hitori':
      _bzHitori(c);
    case 'bz_signpost':
      _bzSignpost(c);
    case 'bz_dominosa':
      _bzDominosa(c);
    default:
      return false;
  }
  return true;
}

/// Bu merkezin bütün özgün kapak türleri (testler ve denetim için).
const bulmacaCoverKinds = [
  // sayı bulmacaları
  'bz_sudoku', 'bz_sudokupack', 'bz_killer', 'bz_sudokuvar', 'bz_skyscraper', 'bz_kakuro', 'bz_kenken',
  'bz_futoshiki', 'bz_mathcross', 'bz_numberlink', 'bz_hidato', 'bz_fillomino', 'bz_suguru', 'bz_kakurasu',
  'bz_sumplete', 'bz_numbermatch', 'bz_2048', 'bz_mergechain', 'bz_fifteen', 'bz_sixteen', 'bz_hitori',
  'bz_signpost', 'bz_dominosa',
  // mantık ızgaraları
  'bz_logicgrid', 'bz_nonogram', 'bz_colornono', 'bz_mines', 'bz_binairo', 'bz_slitherlink', 'bz_bridges',
  'bz_nurikabe', 'bz_starbattle', 'bz_tents', 'bz_heyawake', 'bz_yajilin', 'bz_battleships', 'bz_aquarium',
  'bz_norinori', 'bz_lits', 'bz_tapa', 'bz_queens', 'bz_kuromasu', 'bz_range', 'bz_lightup', 'bz_magnets',
  'bz_pearl', 'bz_slant', 'bz_rectangles', 'bz_galaxies', 'bz_tracks', 'bz_ghosts', 'bz_fence', 'bz_mosaic',
  'bz_mapcolor', 'bz_blackbox', 'bz_logicpack',
  // sıralama, kaydırma ve yol
  'bz_watersort', 'bz_ballsort', 'bz_nuts', 'bz_hexstack', 'bz_arrowout', 'bz_blockout', 'bz_klotski',
  'bz_parking', 'bz_bus', 'bz_picslide', 'bz_iceslide', 'bz_inertia', 'bz_sokoban', 'bz_labyrinth',
  'bz_twiddle', 'bz_netslide', 'bz_netrotate', 'bz_flow', 'bz_oneline', 'bz_lightsout', 'bz_flip',
  // klasik zekâ oyunları
  'bz_knightqueen', 'bz_codebreak', 'bz_twistcube', 'bz_drawline', 'bz_ropes', 'bz_untangle', 'bz_pegjump',
];

// ---- Ortak yardımcılar -------------------------------------------------------

const _bzNavy = Color(0xFF13233F);
const _bzCyan = Color(0xFF2FD3F5);
const _bzGold = Color(0xFFFFC94A);

void _bzBg(Canvas c, Color tint) => _bg(c, tint, tint: tint);

RRect _bzPanel(Canvas c, Rect r, {Color fill = Colors.white, double rad = 5}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(rad));
  _shadowRRect(c, rr);
  c.drawRRect(rr, _p(fill));
  return rr;
}

Rect _bzCell(Rect g, int cols, int rows, int x, int y) {
  final w = g.width / cols, h = g.height / rows;
  return Rect.fromLTWH(g.left + x * w, g.top + y * h, w, h);
}

void _bzLines(Canvas c, Rect g, int cols, int rows, Paint p) {
  for (var i = 1; i < cols; i++) {
    final x = g.left + i * g.width / cols;
    c.drawLine(Offset(x, g.top), Offset(x, g.bottom), p);
  }
  for (var i = 1; i < rows; i++) {
    final y = g.top + i * g.height / rows;
    c.drawLine(Offset(g.left, y), Offset(g.right, y), p);
  }
}

/// Harita dizesine göre (her harf bir bölge) bölge sınırlarını kalın çizer.
void _bzRegions(Canvas c, Rect g, List<String> map, Paint p) {
  final rows = map.length, cols = map[0].length;
  for (var y = 0; y < rows; y++) {
    for (var x = 0; x < cols; x++) {
      final r = _bzCell(g, cols, rows, x, y);
      if (x + 1 < cols && map[y][x] != map[y][x + 1]) c.drawLine(r.topRight, r.bottomRight, p);
      if (y + 1 < rows && map[y][x] != map[y + 1][x]) c.drawLine(r.bottomLeft, r.bottomRight, p);
    }
  }
  c.drawRect(g, p);
}

void _bzArrow(Canvas c, Offset a, Offset b, Color col, double w) {
  final d = b - a;
  final ang = d.direction;
  final h = w * 2.3;
  c.drawLine(a, b - Offset.fromDirection(ang, h * 0.6), _stroke(col, w));
  c.drawPath(
      Path()
        ..moveTo(b.dx, b.dy)
        ..lineTo(b.dx - math.cos(ang - 0.5) * h, b.dy - math.sin(ang - 0.5) * h)
        ..lineTo(b.dx - math.cos(ang + 0.5) * h, b.dy - math.sin(ang + 0.5) * h)
        ..close(),
      _p(col));
}

Path _bzStarPath(Offset o, double r, {int n = 5, double inner = 0.45}) {
  final p = Path();
  for (var i = 0; i < n * 2; i++) {
    final a = -math.pi / 2 + i * math.pi / n;
    final rr = i.isEven ? r : r * inner;
    final pt = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

Path _bzHexPath(Offset o, double r, {bool pointy = true}) {
  final p = Path();
  for (var i = 0; i < 6; i++) {
    final a = (pointy ? -math.pi / 2 : 0) + i * math.pi / 3;
    final pt = o + Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

/// Her karakteri bir hücreye yazar (boşluk atlanır).
void _bzDigits(Canvas c, Rect g, int cols, int rows, String s, Color col, {double scale = 0.62}) {
  for (var i = 0; i < s.length && i < cols * rows; i++) {
    if (s[i] == ' ' || s[i] == '.') continue;
    final r = _bzCell(g, cols, rows, i % cols, i ~/ cols);
    _text(c, s[i], r.center, r.height * scale, col);
  }
}

void _bzDashRect(Canvas c, Rect r, Paint p, {double dash = 2.2, double gap = 1.6}) {
  void line(Offset a, Offset b) {
    final len = (b - a).distance;
    final dir = (b - a) / len;
    for (var t = 0.0; t < len; t += dash + gap) {
      c.drawLine(a + dir * t, a + dir * math.min(t + dash, len), p);
    }
  }

  line(r.topLeft, r.topRight);
  line(r.topRight, r.bottomRight);
  line(r.bottomRight, r.bottomLeft);
  line(r.bottomLeft, r.topLeft);
}

void _bzBadge(Canvas c, Offset o, double r, String s, Color fill, {Color text = Colors.white}) {
  c.drawCircle(o + const Offset(0, 1), r, _p(Colors.black26));
  c.drawCircle(o, r, _p(fill));
  _text(c, s, o, r * (s.length > 2 ? 0.8 : 1.1), text);
}

// ---- Sayı bulmacaları --------------------------------------------------------

void _bzSudoku(Canvas c) {
  _bzBg(c, const Color(0xFF1E4E9C));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  // Seçili satır/sütun/kutu vurgusu
  final hl = _p(_bzCyan.withValues(alpha: 0.18));
  c.drawRect(_bzCell(g, 9, 9, 0, 4).expandToInclude(_bzCell(g, 9, 9, 8, 4)), hl);
  c.drawRect(_bzCell(g, 9, 9, 5, 0).expandToInclude(_bzCell(g, 9, 9, 5, 8)), hl);
  c.drawRect(_bzCell(g, 9, 9, 5, 4), _p(_bzCyan.withValues(alpha: 0.55)));
  _bzLines(c, g, 9, 9, _stroke(_bzNavy.withValues(alpha: 0.25), 0.5));
  _bzLines(c, g, 3, 3, _stroke(_bzNavy, 1.6));
  c.drawRect(g, _stroke(_bzNavy, 2));
  const digits = '53  7    6  195    98    6 8   6   34  8 3  17   2   6 6    28    419  5    8  79';
  _bzDigits(c, g, 9, 9, digits, _bzNavy, scale: 0.72);
  _text(c, '7', _bzCell(g, 9, 9, 5, 4).center, 6, const Color(0xFF1E4E9C));
}

void _bzSudokuPack(Canvas c) {
  _bzBg(c, const Color(0xFF16807A));
  void board(Offset o, double a, int style) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(a);
    const g = Rect.fromLTWH(-22, -22, 44, 44);
    _bzPanel(c, g, rad: 3);
    if (style == 0) {
      // renkli bölgeler (çeşit)
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          if ((x * 3 + y) % 5 == 0) c.drawRect(_bzCell(g, 4, 4, x, y), _p(_pal[(x + y) % 4].withValues(alpha: 0.45)));
        }
      }
    } else if (style == 1) {
      c.drawLine(g.topLeft, g.bottomRight, _stroke(_bzGold, 3));
      c.drawLine(g.topRight, g.bottomLeft, _stroke(_bzGold, 3));
    }
    _bzLines(c, g, 4, 4, _stroke(_bzNavy.withValues(alpha: 0.35), 0.6));
    _bzLines(c, g, 2, 2, _stroke(_bzNavy, 1.4));
    c.drawRect(g, _stroke(_bzNavy, 1.6));
    if (style == 2) _bzDigits(c, g, 4, 4, '1 3  4  2  1 4 3', _bzNavy, scale: 0.65);
    c.restore();
  }

  board(const Offset(34, 38), -0.22, 0);
  board(const Offset(66, 40), 0.2, 1);
  board(const Offset(50, 60), 0, 2);
  _bzBadge(c, const Offset(80, 82), 9, '30', _bzGold, text: _bzNavy);
}

void _bzKiller(Canvas c) {
  _bzBg(c, const Color(0xFF7A2A3A));
  const g = Rect.fromLTWH(14, 14, 72, 72);
  _bzPanel(c, g, rad: 3);
  // (x, y, w, h, toplam, renk)
  const cages = [(0, 0, 2, 1, '7', 0), (2, 0, 1, 2, '5', 2), (3, 0, 1, 3, '8', 3), (0, 1, 1, 2, '6', 5),
      (1, 1, 1, 2, '4', 6), (2, 2, 1, 2, '6', 1), (0, 3, 2, 1, '5', 2), (3, 3, 1, 1, '1', 4)];
  for (final (x, y, w, h, s, k) in cages) {
    final r = Rect.fromLTRB(_bzCell(g, 4, 4, x, y).left, _bzCell(g, 4, 4, x, y).top,
            _bzCell(g, 4, 4, x + w - 1, y + h - 1).right, _bzCell(g, 4, 4, x + w - 1, y + h - 1).bottom)
        .deflate(2);
    c.drawRect(r, _p(_pal[k].withValues(alpha: 0.22)));
    _bzDashRect(c, r, _stroke(const Color(0xFF7A2A3A), 0.9));
    _text(c, s, r.topLeft + const Offset(3.2, 3.4), 4.6, const Color(0xFF7A2A3A));
  }
  _bzLines(c, g, 2, 2, _stroke(_bzNavy, 1.5));
  c.drawRect(g, _stroke(_bzNavy, 1.8));
  _bzDigits(c, g, 4, 4, ' 4 3 2 1     4 1', _bzNavy, scale: 0.45);
}

void _bzSudokuVariants(Canvas c) {
  _bzBg(c, const Color(0xFF5B3A9E));
  const g = Rect.fromLTWH(13, 13, 74, 74);
  _bzPanel(c, g, rad: 3);
  // pencere bölgeleri
  for (final (x, y) in const [(1, 1), (3, 3)]) {
    c.drawRect(Rect.fromLTRB(_bzCell(g, 6, 6, x, y).left, _bzCell(g, 6, 6, x, y).top, _bzCell(g, 6, 6, x + 1, y + 1).right,
        _bzCell(g, 6, 6, x + 1, y + 1).bottom), _p(const Color(0xFFB79CF0).withValues(alpha: 0.5)));
  }
  // köşegenler
  for (var i = 0; i < 6; i++) {
    c.drawCircle(_bzCell(g, 6, 6, i, i).center, 4.6, _p(_bzGold.withValues(alpha: 0.55)));
    c.drawCircle(_bzCell(g, 6, 6, 5 - i, i).center, 4.6, _p(const Color(0xFFFF8FA3).withValues(alpha: 0.5)));
  }
  _bzLines(c, g, 6, 6, _stroke(_bzNavy.withValues(alpha: 0.3), 0.6));
  _bzLines(c, g, 2, 3, _stroke(_bzNavy, 1.6));
  c.drawRect(g, _stroke(_bzNavy, 1.8));
  _bzDigits(c, g, 6, 6, '1    4  3     6 2  5  4 1     2    6', _bzNavy, scale: 0.6);
}

void _bzSkyscraper(Canvas c) {
  // gün batımı göğü
  c.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF2B2F77), Color(0xFFB8457A), Color(0xFFF29E4C)])
            .createShader(const Rect.fromLTWH(0, 0, 100, 100)));
  c.drawCircle(const Offset(76, 26), 9, _p(const Color(0xFFFFE08A).withValues(alpha: 0.9)));
  // zemin ızgarası (4 hücre)
  const base = Rect.fromLTWH(22, 78, 68, 12);
  c.drawRect(base, _p(const Color(0xFF1C2140)));
  for (var i = 0; i < 4; i++) {
    final r = _bzCell(base, 4, 1, i, 0).deflate(1);
    c.drawRect(r, _p(Colors.white.withValues(alpha: 0.9)));
    _text(c, '${const [2, 1, 4, 3][i]}', r.center, 7, _bzNavy);
  }
  // binalar
  const heights = [2, 1, 4, 3];
  for (var i = 0; i < 4; i++) {
    final h = heights[i] * 14.0;
    final r = Rect.fromLTWH(24 + i * 17, 78 - h, 13, h);
    c.drawRect(r.shift(const Offset(1.5, 0)), _p(Colors.black26));
    c.drawRect(r, _p(Color.lerp(const Color(0xFF2E3A6E), const Color(0xFF4F6BC4), heights[i] / 4)!));
    for (var wy = r.top + 4; wy < r.bottom - 3; wy += 6) {
      for (var wx = 0; wx < 2; wx++) {
        c.drawRect(Rect.fromLTWH(r.left + 2.5 + wx * 5, wy, 3, 3), _p(const Color(0xFFFFE08A).withValues(alpha: (wy ~/ 6 + wx).isEven ? 0.9 : 0.35)));
      }
    }
  }
  // ipucu ve görüş çizgisi
  _bzBadge(c, const Offset(11, 64), 7, '2', _bzCyan, text: _bzNavy);
  c.drawLine(const Offset(17, 60), const Offset(74, 22), _stroke(Colors.white70, 1));
  c.drawLine(const Offset(17, 60), const Offset(30, 50), _stroke(Colors.white, 1.6));
}

void _bzKakuro(Canvas c) {
  _bzBg(c, const Color(0xFF2E3B55));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  // 0: kara, 1: ipucu (aşağı/sağ), 2: beyaz
  const cells = ['01011', '12222', '12222', '01222', '01222'];
  const clue = {'1,0': ('16', ''), '3,0': ('7', ''), '4,0': ('9', ''), '0,1': ('', '17'), '0,2': ('', '23'), '1,3': ('', '8'), '1,4': ('', '6')};
  const nums = {'1,1': '9', '2,1': '8', '1,2': '7', '2,2': '6', '3,2': '5', '4,2': '9', '2,3': '1', '3,3': '2', '4,4': '?'};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final r = _bzCell(g, 5, 5, x, y).deflate(0.8);
      final t = cells[y][x];
      if (t == '2') {
        c.drawRect(r, _p(Colors.white));
        final n = nums['$x,$y'];
        if (n != null) _text(c, n, r.center, 9, n == '?' ? const Color(0xFFE2574C) : _bzNavy);
      } else {
        c.drawRect(r, _p(const Color(0xFF151C2B)));
        if (t == '1') {
          c.drawLine(r.topLeft, r.bottomRight, _stroke(Colors.white54, 0.8));
          final cl = clue['$x,$y'];
          if (cl != null) {
            if (cl.$1.isNotEmpty) _text(c, cl.$1, r.center + const Offset(-3.5, 3.5), 5, _bzGold);
            if (cl.$2.isNotEmpty) _text(c, cl.$2, r.center + const Offset(3.5, -3.5), 5, _bzCyan);
          }
        }
      }
    }
  }
}

void _bzKenken(Canvas c) {
  _bzBg(c, const Color(0xFF2F7D4F));
  const g = Rect.fromLTWH(13, 13, 74, 74);
  _bzPanel(c, g, rad: 3);
  const map = ['AABC', 'DEBC', 'DEFF', 'GGHF'];
  const tints = {'A': 2, 'B': 0, 'C': 5, 'D': 1, 'E': 3, 'F': 7, 'G': 4, 'H': 6};
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      c.drawRect(_bzCell(g, 4, 4, x, y), _p(_pal[tints[map[y][x]]!].withValues(alpha: 0.16)));
    }
  }
  _bzLines(c, g, 4, 4, _stroke(_bzNavy.withValues(alpha: 0.25), 0.6));
  _bzRegions(c, g, map, _stroke(_bzNavy, 2));
  for (final (x, y, s) in const [(0, 0, '3+'), (2, 0, '2÷'), (3, 0, '12×'), (0, 1, '1-'), (1, 1, '5+'), (2, 2, '7+'), (0, 3, '6×'), (2, 3, '4')]) {
    final r = _bzCell(g, 4, 4, x, y);
    _text(c, s, r.topLeft + Offset(2 + s.length * 1.4, 4), 4.8, const Color(0xFF1F5A36));
  }
  _bzDigits(c, g, 4, 4, '12 4  2 3    2  ', _bzNavy, scale: 0.5);
}

void _bzFutoshiki(Canvas c) {
  _bzBg(c, const Color(0xFF3A3F9E));
  const n = 4;
  const s = 15.0, gap = 5.0;
  Offset at(int x, int y) => Offset(14 + x * (s + gap), 14 + y * (s + gap));
  const nums = '3  1 4    2  1  ';
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final r = RRect.fromRectAndRadius(at(x, y) & const Size(s, s), const Radius.circular(3));
      _shadowRRect(c, r, dy: 1.2);
      c.drawRRect(r, _p(Colors.white));
      final ch = nums[y * n + x];
      if (ch != ' ') _text(c, ch, r.center, 9, _bzNavy);
    }
  }
  final p = _stroke(_bzGold, 1.8);
  void chev(Offset o, double dir) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(dir);
    c.drawPath(Path()..moveTo(1.6, -2.4)..lineTo(-1.6, 0)..lineTo(1.6, 2.4), p);
    c.restore();
  }

  // yatay işaretler (< ya da >), dikey işaretler (∧ ∨)
  for (final (x, y, d) in const [(0, 0, 0.0), (2, 1, math.pi), (1, 3, 0.0), (2, 2, math.pi)]) {
    chev(at(x, y) + const Offset(s + gap / 2, s / 2), d);
  }
  for (final (x, y, d) in const [(1, 0, math.pi / 2), (3, 1, -math.pi / 2), (0, 2, math.pi / 2)]) {
    chev(at(x, y) + const Offset(s / 2, s + gap / 2), d);
  }
}

void _bzMathCross(Canvas c) {
  _bzBg(c, const Color(0xFFC77A1E));
  const sz = 15.0;
  Rect at(int x, int y) => Rect.fromLTWH(13 + x * 15.5, 13 + y * 15.5, sz, sz);
  void tile(int x, int y, String s, {bool op = false, bool hi = false}) {
    final r = RRect.fromRectAndRadius(at(x, y), const Radius.circular(3));
    _shadowRRect(c, r, dy: 1.3);
    c.drawRRect(r, _p(op ? const Color(0xFF7A4510) : (hi ? _bzCyan : _ivory)));
    _text(c, s, r.center, 9, op ? Colors.white : _bzNavy);
  }

  const row = ['3', '+', '4', '=', '7'];
  const col = ['8', '−', '4', '=', '4'];
  for (var i = 0; i < 5; i++) {
    if (i != 2) tile(2, i, col[i], op: i.isOdd);
    tile(i, 2, row[i], op: i.isOdd, hi: i == 2);
  }
}

void _bzNumberlink(Canvas c) {
  _bzBg(c, const Color(0xFF1B3F8F));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  c.drawRRect(RRect.fromRectAndRadius(g, const Radius.circular(4)), _p(const Color(0xFF0F2559)));
  _bzLines(c, g, 5, 5, _stroke(Colors.white12, 0.7));
  const paths = [
    [(0, 0), (0, 1), (0, 2), (0, 3), (1, 3)],
    [(1, 0), (2, 0), (3, 0), (3, 1), (3, 2)],
    [(1, 1), (1, 2), (2, 2), (2, 3), (2, 4), (3, 4)],
    [(4, 0), (4, 1), (4, 2), (4, 3), (3, 3)],
  ];
  const cols = [Color(0xFFFF6B6B), Color(0xFFFFC94A), Color(0xFF4ADE80), Color(0xFFC084FC)];
  for (var k = 0; k < paths.length; k++) {
    final path = Path();
    for (var i = 0; i < paths[k].length; i++) {
      final o = _bzCell(g, 5, 5, paths[k][i].$1, paths[k][i].$2).center;
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    c.drawPath(path, _stroke(cols[k].withValues(alpha: 0.85), 5));
    for (final e in [paths[k].first, paths[k].last]) {
      _bzBadge(c, _bzCell(g, 5, 5, e.$1, e.$2).center, 5.6, '${k + 1}', cols[k], text: _bzNavy);
    }
  }
  _bzBadge(c, _bzCell(g, 5, 5, 0, 4).center, 5.6, '5', Colors.white, text: _bzNavy);
  _bzBadge(c, _bzCell(g, 5, 5, 4, 4).center, 5.6, '5', Colors.white, text: _bzNavy);
}

void _bzHidato(Canvas c) {
  _bzBg(c, const Color(0xFF0E7C9A));
  const g = Rect.fromLTWH(14, 14, 72, 72);
  const order = [(0, 0), (1, 0), (2, 1), (3, 0), (3, 1), (3, 2), (2, 2), (1, 1), (0, 1), (0, 2), (1, 3), (0, 3), (1, 2), (2, 3), (3, 3)];
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      c.drawCircle(_bzCell(g, 4, 4, x, y).center, 7.5, _p(Colors.white.withValues(alpha: 0.18)));
    }
  }
  final path = Path();
  for (var i = 0; i < 9; i++) {
    final o = _bzCell(g, 4, 4, order[i].$1, order[i].$2).center;
    i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
  }
  c.drawPath(path, _stroke(_bzGold, 2.6));
  for (var i = 0; i < order.length; i++) {
    final o = _bzCell(g, 4, 4, order[i].$1, order[i].$2).center;
    final shown = i < 9 || i == order.length - 1;
    if (!shown) continue;
    _bzBadge(c, o, 7, '${i + 1}', i == 0 || i == order.length - 1 ? _bzGold : Colors.white, text: _bzNavy);
  }
}

void _bzFillomino(Canvas c) {
  _bzBg(c, const Color(0xFFB0457A));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  const map = ['AABCC', 'ADBBE', 'DDFEE', 'GDFFH', 'GGIIH'];
  final size = <String, int>{};
  for (final row in map) {
    for (final ch in row.split('')) {
      size[ch] = (size[ch] ?? 0) + 1;
    }
  }
  const tone = {2: Color(0xFFFFD6E5), 3: Color(0xFFFFB3CC), 4: Color(0xFFF07FA8)};
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      final n = size[map[y][x]]!;
      final r = _bzCell(g, 5, 5, x, y);
      c.drawRect(r, _p(tone[n] ?? Colors.white));
      if ((x + y * 2) % 3 != 1) _text(c, '$n', r.center, 8, const Color(0xFF6B1840));
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.5));
  _bzRegions(c, g, map, _stroke(const Color(0xFF6B1840), 1.8));
}

void _bzSuguru(Canvas c) {
  _bzBg(c, const Color(0xFF6E7F2A));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, fill: const Color(0xFFFBF8EC), rad: 3);
  const map = ['AABBB', 'ACCBD', 'ECCDD', 'EEFFD', 'EFFGG'];
  for (var y = 0; y < 5; y++) {
    for (var x = 0; x < 5; x++) {
      if (map[y][x] == 'C') c.drawRect(_bzCell(g, 5, 5, x, y), _p(const Color(0xFFD9E5A8)));
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black12, 0.6));
  _bzRegions(c, g, map, _stroke(const Color(0xFF3B4512), 2.2));
  const digits = '13 21 2 4 4 1 3 2 1  4  ';
  for (var i = 0; i < digits.length; i++) {
    if (digits[i] == ' ') continue;
    final r = _bzCell(g, 5, 5, i % 5, i ~/ 5);
    c.drawCircle(r.center, 5.4, _stroke(const Color(0xFF6E7F2A).withValues(alpha: 0.5), 0.8));
    _text(c, digits[i], r.center, 7.5, const Color(0xFF3B4512));
  }
}

void _bzKakurasu(Canvas c) {
  _bzBg(c, const Color(0xFF8A4F2B));
  const g = Rect.fromLTWH(24, 24, 56, 56);
  _bzPanel(c, g, fill: const Color(0xFFFFF4E3), rad: 2);
  const filled = ['1001', '0110', '1010', '0011'];
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      if (filled[y][x] == '1') {
        c.drawRRect(RRect.fromRectAndRadius(_bzCell(g, 4, 4, x, y).deflate(1.6), const Radius.circular(2)), _p(const Color(0xFF3A2414)));
      }
    }
  }
  _bzLines(c, g, 4, 4, _stroke(const Color(0xFF3A2414).withValues(alpha: 0.4), 0.7));
  for (var i = 0; i < 4; i++) {
    _text(c, '${i + 1}', Offset(_bzCell(g, 4, 4, i, 0).center.dx, 17), 6, Colors.white70);
    _text(c, '${i + 1}', Offset(17, _bzCell(g, 4, 4, 0, i).center.dy), 6, Colors.white70);
    const right = ['5', '5', '4', '7'];
    const bottom = ['4', '3', '5', '6'];
    _bzBadge(c, Offset(88, _bzCell(g, 4, 4, 0, i).center.dy), 4.6, right[i], _bzGold, text: _bzNavy);
    _bzBadge(c, Offset(_bzCell(g, 4, 4, i, 0).center.dx, 88), 4.6, bottom[i], _bzGold, text: _bzNavy);
  }
}

void _bzSumplete(Canvas c) {
  _bzBg(c, const Color(0xFFB23A48));
  const g = Rect.fromLTWH(12, 12, 64, 64);
  _bzPanel(c, g, rad: 3);
  const nums = '4729163852471386';
  const state = 'kxkkkkxkxkkkkkxk'; // k: kalır, x: silinir
  for (var i = 0; i < 16; i++) {
    final r = _bzCell(g, 4, 4, i % 4, i ~/ 4);
    final del = state[i] == 'x';
    if (!del && (i % 5 == 0)) c.drawCircle(r.center, 6.6, _stroke(const Color(0xFF2FA66A), 1.4));
    _text(c, nums[i], r.center, 9, del ? _bzNavy.withValues(alpha: 0.25) : _bzNavy);
    if (del) {
      c.drawLine(r.center + const Offset(-5, -5), r.center + const Offset(5, 5), _stroke(const Color(0xFFE2574C), 1.8));
      c.drawLine(r.center + const Offset(5, -5), r.center + const Offset(-5, 5), _stroke(const Color(0xFFE2574C), 1.8));
    }
  }
  _bzLines(c, g, 4, 4, _stroke(Colors.black12, 0.6));
  const right = ['13', '9', '14', '17'];
  const bottom = ['7', '16', '15', '13'];
  for (var i = 0; i < 4; i++) {
    _bzBadge(c, Offset(85, _bzCell(g, 4, 4, 0, i).center.dy), 5.6, right[i], const Color(0xFFFFE3E6), text: const Color(0xFF8A1E2B));
    _bzBadge(c, Offset(_bzCell(g, 4, 4, i, 0).center.dx, 86), 5.6, bottom[i], const Color(0xFFFFE3E6), text: const Color(0xFF8A1E2B));
  }
}

void _bzNumberMatch(Canvas c) {
  _bzBg(c, const Color(0xFF4E8A2E));
  const g = Rect.fromLTWH(10, 18, 80, 64);
  _bzPanel(c, g, fill: const Color(0xFFFDFBF3), rad: 4);
  for (var y = 1; y < 4; y++) {
    c.drawLine(Offset(g.left, g.top + y * 16), Offset(g.right, g.top + y * 16), _stroke(const Color(0xFF9CC3E6), 0.7));
  }
  const rows = ['371582', '649315', '258746', '91 3  '];
  const gone = {'1,0', '4,1'};
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 6; x++) {
      final ch = rows[y][x];
      if (ch == ' ') continue;
      final o = _bzCell(g, 6, 4, x, y).center;
      _text(c, ch, o, 9, gone.contains('$x,$y') ? Colors.black12 : _bzNavy);
    }
  }
  // eşleşen çiftler: 3-7 ve 5-5
  RRect cap(int x0, int y0, int x1, int y1) =>
      RRect.fromRectAndRadius(_bzCell(g, 6, 4, x0, y0).expandToInclude(_bzCell(g, 6, 4, x1, y1)).deflate(1.5), const Radius.circular(7));
  c.drawRRect(cap(0, 0, 1, 0), _stroke(const Color(0xFFE2574C), 1.8));
  c.drawRRect(cap(3, 0, 3, 1), _stroke(const Color(0xFF3075C4), 1.8));
  c.drawRRect(cap(4, 2, 5, 2), _p(const Color(0xFF3BA776).withValues(alpha: 0.25)));
}

void _bz2048(Canvas c) {
  _bzBg(c, const Color(0xFF9C6A3C));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  c.drawRRect(RRect.fromRectAndRadius(g, const Radius.circular(6)), _p(const Color(0xFFBBA58C)));
  const vals = [2, 0, 4, 2, 0, 8, 16, 4, 4, 32, 64, 8, 2, 128, 2048, 0];
  for (var i = 0; i < 16; i++) {
    final r = _bzCell(g, 4, 4, i % 4, i ~/ 4).deflate(1.8);
    final v = vals[i];
    final t = v == 0 ? 0.0 : (math.log(v) / math.ln2) / 11;
    final col = v == 0 ? const Color(0xFFCDBFAE) : Color.lerp(const Color(0xFFF5EBDD), const Color(0xFFF2B33B), t * 1.3)!;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
    if (v == 2048) c.drawRRect(rr.inflate(2.5), _p(_bzGold.withValues(alpha: 0.5)));
    c.drawRRect(rr, _p(v == 2048 ? const Color(0xFFF2C12E) : col));
    if (v != 0) _text(c, '$v', r.center, v >= 1000 ? 5.2 : (v >= 100 ? 6.5 : 8.5), v >= 8 ? Colors.white : const Color(0xFF6B5A48));
  }
  _bzArrow(c, const Offset(60, 94), const Offset(88, 94), Colors.white, 2);
}

void _bzMergeChain(Canvas c) {
  _bzBg(c, const Color(0xFF8A2C8C));
  const g = Rect.fromLTWH(12, 30, 76, 60);
  const vals = [2, 4, 2, 8, 4, 2, 2, 16, 8, 4, 32, 4, 2, 8, 2, 4];
  const chain = [(0, 1), (1, 1), (2, 0), (2, 1)];
  final path = Path();
  for (var i = 0; i < chain.length; i++) {
    final o = _bzCell(g, 4, 4, chain[i].$1, chain[i].$2).center;
    i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
  }
  for (var i = 0; i < 16; i++) {
    final x = i % 4, y = i ~/ 4;
    if (y > 2) continue;
    final o = _bzCell(g, 4, 4, x, y).center;
    final v = vals[i];
    final col = _pal[(math.log(v) / math.ln2).round() % 8];
    _stone(c, o, 7.2, col);
    _text(c, '$v', o, 7, Colors.white);
  }
  c.drawPath(path, _stroke(Colors.white, 2.4));
  // birleşen sonuç
  c.drawCircle(const Offset(50, 17), 13, _p(_bzGold.withValues(alpha: 0.35)));
  _stone(c, const Offset(50, 17), 9.5, const Color(0xFFF2A93B));
  _text(c, '16', const Offset(50, 17), 8.5, Colors.white);
  _bzArrow(c, _bzCell(g, 4, 4, 2, 0).center + const Offset(-2, -8), const Offset(56, 27), Colors.white70, 1.4);
}

void _bzFifteen(Canvas c) {
  _bzBg(c, const Color(0xFF5E4127));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _woodBoard(c, g.inflate(3));
  c.drawRect(g, _p(const Color(0xFF3A2616)));
  for (var i = 0; i < 15; i++) {
    var x = i % 4, y = i ~/ 4;
    var r = _bzCell(g, 4, 4, x, y).deflate(1.4);
    if (i == 14) r = r.shift(const Offset(8, 0)); // kayan taş
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
    c.drawRRect(rr.shift(const Offset(0, 1.3)), _p(Colors.black38));
    c.drawRRect(rr, _p(i == 14 ? const Color(0xFFFFE6B0) : const Color(0xFFF3DDB5)));
    c.drawRRect(rr.deflate(1.4), _stroke(const Color(0xFFB98B54), 0.6));
    _text(c, '${i + 1}', r.center, 8, const Color(0xFF5E3A1A));
  }
  _bzArrow(c, const Offset(56, 96), const Offset(74, 96), _bzGold, 1.6);
}

void _bzSixteen(Canvas c) {
  _bzBg(c, const Color(0xFF127A6B));
  const g = Rect.fromLTWH(20, 20, 60, 60);
  const rowCol = [Color(0xFFE2574C), Color(0xFFF2A93B), Color(0xFF3075C4), Color(0xFF9763BC)];
  const order = [1, 2, 3, 4, 8, 5, 6, 7, 9, 10, 15, 12, 13, 14, 11, 16];
  for (var i = 0; i < 16; i++) {
    final n = order[i];
    final r = RRect.fromRectAndRadius(_bzCell(g, 4, 4, i % 4, i ~/ 4).deflate(1.5), const Radius.circular(3));
    c.drawRRect(r.shift(const Offset(0, 1.2)), _p(Colors.black26));
    c.drawRRect(r, _p(rowCol[(n - 1) ~/ 4]));
    _text(c, '$n', r.center, 7, Colors.white);
  }
  // satır döndürme oku (sağdan sola sarılır)
  final y = _bzCell(g, 4, 4, 0, 1).center.dy;
  _bzArrow(c, Offset(8, y), Offset(18, y), Colors.white, 1.6);
  _bzArrow(c, Offset(82, y), Offset(92, y), Colors.white, 1.6);
  // sütun döndürme oku
  final x = _bzCell(g, 4, 4, 2, 0).center.dx;
  _bzArrow(c, Offset(x, 92), Offset(x, 83), _bzGold, 1.6);
  _bzArrow(c, Offset(x, 8), Offset(x, 17), _bzGold, 1.6);
}

void _bzHitori(Canvas c) {
  _bzBg(c, const Color(0xFF495A70));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  _bzPanel(c, g, rad: 3);
  const nums = '3121423514523142415325143';
  const black = {1, 8, 10, 17, 19, 22};
  for (var i = 0; i < 25; i++) {
    final r = _bzCell(g, 5, 5, i % 5, i ~/ 5);
    if (black.contains(i)) {
      c.drawRect(r.deflate(0.6), _p(const Color(0xFF1C2433)));
      _text(c, nums[i], r.center, 7, Colors.white24);
    } else {
      _text(c, nums[i], r.center, 8, _bzNavy);
    }
  }
  _bzLines(c, g, 5, 5, _stroke(Colors.black26, 0.6));
  // tekrar eden çift işaretli
  c.drawCircle(_bzCell(g, 5, 5, 0, 0).center, 6.2, _stroke(const Color(0xFFE2574C), 1.4));
  c.drawCircle(_bzCell(g, 5, 5, 2, 0).center, 6.2, _stroke(const Color(0xFFE2574C), 1.4));
}

void _bzSignpost(Canvas c) {
  _bzBg(c, const Color(0xFFD06A1E));
  const g = Rect.fromLTWH(12, 12, 76, 76);
  // yön (0 sağ, 1 aşağı, 2 sol, 3 yukarı, 4 sağ-aşağı, 5 sol-aşağı) ve sıra
  const dirs = [0, 4, 1, 1, 1, 0, 5, 2, 0, 3, 0, 1, 3, 2, 2, 9];
  const nums = {0: '1', 1: '2', 6: '3', 9: '7', 15: '16'};
  for (var i = 0; i < 16; i++) {
    final r = _bzCell(g, 4, 4, i % 4, i ~/ 4).deflate(1.6);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
    _shadowRRect(c, rr, dy: 1.2);
    c.drawRRect(rr, _p(nums.containsKey(i) ? const Color(0xFFFFE7CC) : Colors.white));
    final d = dirs[i];
    if (d != 9) {
      const vec = [Offset(1, 0), Offset(0, 1), Offset(-1, 0), Offset(0, -1), Offset(0.7, 0.7), Offset(-0.7, 0.7)];
      final o = r.center + const Offset(2, 2);
      _bzArrow(c, o - vec[d] * 4, o + vec[d] * 4, const Color(0xFF8A3F0A), 1.3);
    } else {
      c.drawPath(_bzStarPath(r.center, 5), _p(_bzGold));
    }
    final n = nums[i];
    if (n != null) _text(c, n, r.topLeft + const Offset(4.5, 4.5), 5, const Color(0xFF8A3F0A));
  }
  // 1 → 2 → 3 bağlantısı
  final a = _bzCell(g, 4, 4, 0, 0).center, b = _bzCell(g, 4, 4, 1, 0).center, d = _bzCell(g, 4, 4, 2, 1).center;
  c.drawPath(Path()..moveTo(a.dx, a.dy)..lineTo(b.dx, b.dy)..lineTo(d.dx, d.dy), _stroke(const Color(0xFF3075C4).withValues(alpha: 0.6), 2.4));
}

void _bzDominosa(Canvas c) {
  _bzBg(c, const Color(0xFF2B6E5A));
  const g = Rect.fromLTWH(10, 18, 80, 64);
  const nums = '0120' '3123' '2031' '1302';
  for (var i = 0; i < 16; i++) {
    _text(c, nums[i], _bzCell(g, 4, 4, i % 4, i ~/ 4).center, 9, Colors.white70);
  }
  // yerleşmiş dominolar
  for (final (x, y, h) in const [(0, 0, true), (2, 0, true), (0, 1, false), (1, 2, true), (3, 1, false)]) {
    final a = _bzCell(g, 4, 4, x, y);
    final b = _bzCell(g, 4, 4, h ? x + 1 : x, h ? y : y + 1);
    final r = RRect.fromRectAndRadius(a.expandToInclude(b).deflate(1.6), const Radius.circular(4));
    _shadowRRect(c, r, dy: 1.4);
    c.drawRRect(r, _p(_ivory));
    c.drawLine(h ? Offset(a.right, a.top + 3) : Offset(a.left + 3, a.bottom), h ? Offset(a.right, a.bottom - 3) : Offset(a.right - 3, a.bottom),
        _stroke(Colors.black38, 0.9));
    _text(c, nums[y * 4 + x], a.center, 9, _bzNavy);
    _text(c, nums[(h ? y : y + 1) * 4 + (h ? x + 1 : x)], b.center, 9, _bzNavy);
  }
}
