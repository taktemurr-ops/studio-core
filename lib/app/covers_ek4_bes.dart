part of 'covers.dart';

/// 4. tur kapakları (Bulmaca ve Sayı, Eşleştirme, Blok Oyunları). Her tür
/// yalnızca bir oyuna aittir: bz_dominocond Domino Koşulları, bz_pinpull Pim
/// Çekme, bz_trickq Tuzaklı Bilmeceler, pixelflowc Piksel Akışı, desserttrayc
/// Tatlı Tepsisi, colorloopc Renk Döngüsü, b-ikili Renk İkilileri, b-macera
/// Blok Macerası. Hepsi vektör; dış görsel ya da marka yok.
bool _paintEk4BesCover(Canvas c, GameCover cover, Color seed) {
  switch (cover.kind) {
    case 'bz_dominocond':
      _e5DominoCond(c);
    case 'bz_pinpull':
      _e5PinPull(c);
    case 'bz_trickq':
      _e5Trick(c);
    case 'pixelflowc':
      _e5PixelFlow(c);
    case 'desserttrayc':
      _e5DessertTray(c);
    case 'colorloopc':
      _e5ColorLoop(c);
    case 'b-ikili':
      _e5Pairs(c);
    case 'b-macera':
      _e5Adventure(c);
    default:
      return false;
  }
  return true;
}

/// Bu dosyadaki bütün kapak türleri (testler için).
const ek4BesCoverKinds = ['bz_dominocond', 'bz_pinpull', 'bz_trickq', 'pixelflowc', 'desserttrayc', 'colorloopc', 'b-ikili', 'b-macera'];

const _e5Cols = [Color(0xFFFF6B6B), Color(0xFFFFC145), Color(0xFF4DD4AC), Color(0xFF5DA9FF), Color(0xFFC77DFF), Color(0xFFFF8FB1)];

void _e5Pips(Canvas c, Rect r, int n) {
  final s = math.min(r.width, r.height);
  final q = s * 0.26;
  const pos = {
    0: <(int, int)>[],
    1: [(0, 0)],
    2: [(-1, -1), (1, 1)],
    3: [(-1, -1), (0, 0), (1, 1)],
    4: [(-1, -1), (1, -1), (-1, 1), (1, 1)],
    5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)],
    6: [(-1, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (1, 1)],
  };
  for (final (x, y) in pos[n]!) {
    c.drawCircle(r.center + Offset(x * q, y * q), s * 0.09, _p(_ink));
  }
}

void _e5Domino(Canvas c, Rect r, int a, int b, {bool vertical = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(3.5));
  _shadowRRect(c, rr, dy: 1.6);
  c.drawRRect(rr, _p(_ivory));
  c.drawRRect(rr, _stroke(const Color(0xFF9C8B6E), 0.8));
  if (vertical) {
    c.drawLine(Offset(r.left + 2, r.center.dy), Offset(r.right - 2, r.center.dy), _stroke(const Color(0xFF9C8B6E), 0.8));
    _e5Pips(c, Rect.fromLTWH(r.left, r.top, r.width, r.height / 2), a);
    _e5Pips(c, Rect.fromLTWH(r.left, r.center.dy, r.width, r.height / 2), b);
  } else {
    c.drawLine(Offset(r.center.dx, r.top + 2), Offset(r.center.dx, r.bottom - 2), _stroke(const Color(0xFF9C8B6E), 0.8));
    _e5Pips(c, Rect.fromLTWH(r.left, r.top, r.width / 2, r.height), a);
    _e5Pips(c, Rect.fromLTWH(r.center.dx, r.top, r.width / 2, r.height), b);
  }
}

/// Domino Koşulları: renkli bölgeler (kesikli sınır, "=" / "8" / "<4" rozetleri), yerleşmiş dominolar ve tepside bir taş.
void _e5DominoCond(Canvas c) {
  _bg(c, const Color(0xFF3B4F7A));
  const g = 13.0;
  const o = Offset(18, 12);
  // bölgeler: (x, y, w, h, renk)
  const regions = [
    (0, 0, 2, 1, Color(0xFFF4A261)),
    (2, 0, 2, 2, Color(0xFF8AB17D)),
    (0, 1, 1, 2, Color(0xFF7FB7E6)),
    (1, 1, 1, 3, Color(0xFFE76F51)),
    (2, 2, 3, 1, Color(0xFFB392F0)),
    (4, 0, 1, 2, Color(0xFFE9C46A)),
  ];
  for (final (x, y, w, h, col) in regions) {
    final r = Rect.fromLTWH(o.dx + x * g, o.dy + y * g, w * g, h * g).deflate(0.8);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _p(Color.lerp(col, Colors.white, 0.35)!));
    _bzDashRect(c, r, _stroke(col, 1.1));
  }
  _e5Domino(c, Rect.fromLTWH(o.dx + 0.6, o.dy + 0.6, 2 * g - 1.2, g - 1.2), 4, 4);
  _e5Domino(c, Rect.fromLTWH(o.dx + 2 * g + 0.6, o.dy + 0.6, g - 1.2, 2 * g - 1.2), 2, 6, vertical: true);
  _e5Domino(c, Rect.fromLTWH(o.dx + g + 0.6, o.dy + g + 0.6, g - 1.2, 2 * g - 1.2), 1, 3, vertical: true);
  // rozetler
  _bzBadge(c, Offset(o.dx + 1, o.dy + 1), 5, '=', const Color(0xFFF4A261));
  _bzBadge(c, Offset(o.dx + 2 * g + 1, o.dy + 1), 5, '8', const Color(0xFF8AB17D));
  _bzBadge(c, Offset(o.dx + 2 * g + 1, o.dy + 2 * g + 1), 5, '<4', const Color(0xFFB392F0));
  _bzBadge(c, Offset(o.dx + 4 * g + 1, o.dy + 1), 5, '≠', const Color(0xFFE9C46A));
  // tepsi
  final tray = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 70, 80, 22), const Radius.circular(6));
  c.drawRRect(tray, _p(Colors.black.withValues(alpha: 0.22)));
  _e5Domino(c, const Rect.fromLTWH(16, 74, 24, 13), 5, 0);
  _e5Domino(c, const Rect.fromLTWH(46, 74, 24, 13), 6, 2);
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(44, 72, 28, 17), const Radius.circular(4)), _stroke(_bzGold, 1.4));
}

/// Pim Çekme: iki bölmeli cam kule, kırmızı topuzlu çekilen pim, akan renkli toplar ve kavanoz.
void _e5PinPull(Canvas c) {
  _bg(c, const Color(0xFF6E5A4B));
  final frame = RRect.fromRectAndRadius(const Rect.fromLTWH(20, 8, 60, 86), const Radius.circular(10));
  c.drawRRect(frame, _p(const Color(0xFF8A7360)));
  final glass = _p(const Color(0xFF1E2A3A));
  c.drawRect(const Rect.fromLTWH(26, 13, 20, 38), glass);
  c.drawRect(const Rect.fromLTWH(54, 13, 20, 38), glass);
  final funnel = Path()
    ..moveTo(26, 51)
    ..lineTo(74, 51)
    ..lineTo(62, 64)
    ..lineTo(38, 64)
    ..close();
  c.drawPath(funnel, glass);
  // kavanoz
  final jar = RRect.fromRectAndCorners(const Rect.fromLTWH(36, 64, 28, 25), bottomLeft: const Radius.circular(8), bottomRight: const Radius.circular(8));
  c.drawRRect(jar, _p(const Color(0xFF26405A)));
  c.drawRRect(jar, _stroke(const Color(0xCCBFE7FF), 1.6));
  // toplar: solda mürekkep, sağda renkli; kavanozda renkliler
  for (var i = 0; i < 6; i++) {
    c.drawCircle(Offset(30 + (i % 3) * 6.0, 20 + (i ~/ 3) * 6.0), 2.8, _p(const Color(0xFF231B3B)));
  }
  for (var i = 0; i < 6; i++) {
    c.drawCircle(Offset(58 + (i % 3) * 6.0, 36 + (i ~/ 3) * 6.0), 2.8, _p(_e5Cols[i % 4]));
  }
  for (var i = 0; i < 9; i++) {
    c.drawCircle(Offset(41 + (i % 4) * 6.0 + ((i ~/ 4).isOdd ? 3.0 : 0.0), 84 - (i ~/ 4) * 5.5), 2.6, _p(_e5Cols[(i + 1) % 5]));
  }
  // pimler: soldaki yerinde, sağdaki çekiliyor
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 30, 26, 3.2), const Radius.circular(1.6)), _p(const Color(0xFFD8DDE3)));
  c.drawCircle(const Offset(52, 31.6), 3.4, _p(const Color(0xFFE85D4A)));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 50, 26, 3.2), const Radius.circular(1.6)), _p(const Color(0xFFD8DDE3)));
  c.drawCircle(const Offset(94, 51.6), 3.6, _p(const Color(0xFFE85D4A)));
  _bzArrow(c, const Offset(78, 44), const Offset(92, 44), _bzGold, 1.6);
}

/// Tuzaklı Bilmeceler: soru balonu, kenara itilmiş kutu ve altından çıkan yıldız, parmak.
void _e5Trick(Canvas c) {
  _bg(c, const Color(0xFF7A4BC2));
  final bubble = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 8, 80, 26), const Radius.circular(10));
  c.drawRRect(bubble, _p(Colors.white.withValues(alpha: 0.92)));
  _text(c, '?!', const Offset(30, 21), 15, const Color(0xFF7A4BC2));
  _text(c, '★', const Offset(66, 21), 15, _bzGold);
  // yıldız (bulundu)
  _text(c, '★', const Offset(36, 66), 26, _bzGold);
  // kayan kutu
  final box = RRect.fromRectAndRadius(const Rect.fromLTWH(56, 52, 30, 26), const Radius.circular(3));
  _shadowRRect(c, box, dy: 2);
  c.drawRRect(box, _p(const Color(0xFFC08A55)));
  c.drawLine(const Offset(56, 52), const Offset(86, 78), _stroke(const Color(0xFF8D5A32), 1.6));
  c.drawLine(const Offset(86, 52), const Offset(56, 78), _stroke(const Color(0xFF8D5A32), 1.6));
  // kutunun eski yeri (kesikli)
  _bzDashRect(c, const Rect.fromLTWH(22, 52, 30, 26), _stroke(Colors.white70, 1.1));
  _bzArrow(c, const Offset(44, 88), const Offset(66, 88), Colors.white, 1.6);
  // parmak
  c.drawCircle(const Offset(20, 84), 6, _p(const Color(0xFFFFD9B8)));
}

/// Piksel Akışı: piksel kalp resmi, çevresinde bant ve banttaki renkli atıcılar; bir ışın pikseli vuruyor.
void _e5PixelFlow(Canvas c) {
  _bg(c, const Color(0xFF2B3550));
  const o = Offset(30, 24);
  const s = 5.0;
  const art = [
    '.RR.RR..',
    'RRRRRRR.',
    'RRYYRRR.',
    'RRYYRRR.',
    '.RRRRR..',
    '..RRR...',
    '...R....',
    '........',
  ];
  for (var y = 0; y < 8; y++) {
    for (var x = 0; x < 8; x++) {
      final ch = art[y][x];
      if (ch == '.') continue;
      c.drawRect(Rect.fromLTWH(o.dx + x * s, o.dy + y * s, s - 0.5, s - 0.5), _p(ch == 'R' ? const Color(0xFFFF5C7A) : const Color(0xFFFFC145)));
    }
  }
  // bant
  final track = RRect.fromRectAndRadius(const Rect.fromLTWH(20, 14, 60, 60), const Radius.circular(12));
  c.drawRRect(track, _stroke(const Color(0xFF59627A), 7));
  // atıcılar
  for (final (p, col, n) in [(const Offset(50, 14), 0, '9'), (const Offset(80, 44), 1, '4'), (const Offset(32, 74), 3, '6')]) {
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 11, height: 11), const Radius.circular(3));
    c.drawRRect(r, _p([const Color(0xFFFF5C7A), const Color(0xFFFFC145), const Color(0xFF4DD4AC), const Color(0xFF5DA9FF)][col]));
    _text(c, n, p, 6.5, Colors.white);
  }
  c.drawLine(const Offset(50, 20), const Offset(52.5, 29), _stroke(const Color(0xFFFFF2A8), 1.4));
  // kuyruk
  for (var i = 0; i < 3; i++) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(30 + i * 15.0, 84, 11, 11), const Radius.circular(3));
    c.drawRRect(r, _p(_e5Cols[(i + 2) % 6]));
  }
}

void _e5Plate(Canvas c, Offset o, double r, List<int> slices) {
  c.drawCircle(o + const Offset(0, 1.5), r, _p(Colors.black.withValues(alpha: 0.25)));
  c.drawCircle(o, r, _p(const Color(0xFFF7F3EA)));
  const cols = [Color(0xFFD9A441), Color(0xFFF4A7B9), Color(0xFFE8772E), Color(0xFF8DB65B)];
  for (var i = 0; i < slices.length; i++) {
    final a0 = -math.pi / 2 + i * math.pi / 3;
    final path = Path()
      ..moveTo(o.dx, o.dy)
      ..arcTo(Rect.fromCircle(center: o, radius: r * 0.84), a0 + 0.05, math.pi / 3 - 0.1, false)
      ..close();
    c.drawPath(path, _p(cols[slices[i]]));
  }
}

/// Tatlı Tepsisi: tabaklarda baklava/lokum/künefe dilimleri; altı dilimle dolan tabak parlıyor.
void _e5DessertTray(Canvas c) {
  _bg(c, const Color(0xFF8E5A3C));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 10, 84, 64), const Radius.circular(10)), _p(const Color(0xFFC9A26B)));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 10, 84, 64), const Radius.circular(10)), _stroke(const Color(0xFF7A5230), 2));
  _e5Plate(c, const Offset(28, 30), 14, [0, 0, 0, 0, 0, 0]);
  c.drawCircle(const Offset(28, 30), 16, _stroke(_bzGold, 1.8));
  _e5Plate(c, const Offset(62, 30), 14, [1, 1, 2]);
  _e5Plate(c, const Offset(28, 58), 12, [2, 3]);
  _e5Plate(c, const Offset(62, 58), 12, [1, 3, 3, 0]);
  // sunulan tabak
  _e5Plate(c, const Offset(50, 88), 9, [1, 1]);
  _bzArrow(c, const Offset(58, 86), const Offset(64, 74), Colors.white, 1.4);
}

/// Renk Döngüsü: stadyum biçimli bant, üzerinde kum taneleri, üstte katmanlı kum kavanozu, kenarda dolan kaplar.
void _e5ColorLoop(Canvas c) {
  _bg(c, const Color(0xFF2E5D57));
  final track = RRect.fromRectAndRadius(const Rect.fromLTWH(12, 34, 76, 36), const Radius.circular(18));
  c.drawRRect(track, _stroke(const Color(0xFF3A4256), 7));
  // kavanoz
  final jar = RRect.fromRectAndRadius(const Rect.fromLTWH(41, 4, 18, 24), const Radius.circular(4));
  for (var k = 0; k < 4; k++) {
    c.drawRect(Rect.fromLTWH(43, 24 - k * 5.0, 14, 5), _p(_e5Cols[(k + 1) % 6]));
  }
  c.drawRRect(jar, _stroke(Colors.white70, 1.2));
  // taneler
  for (var i = 0; i < 14; i++) {
    final u = i / 14;
    final a = u * 2 * math.pi;
    final p = Offset(50 + 32 * math.cos(a), 52 + 15 * math.sin(a));
    c.drawCircle(p, 2.6, _p(_e5Cols[(i * 3) % 6]));
  }
  // kaplar
  for (final (x, col, fill) in [(20.0, 0, 2), (50.0, 2, 1), (80.0, 4, 3)]) {
    final r = Rect.fromLTWH(x - 7, 76, 14, 16);
    final path = Path()
      ..moveTo(r.left, r.top)
      ..lineTo(r.right, r.top)
      ..lineTo(r.right - 2, r.bottom)
      ..lineTo(r.left + 2, r.bottom)
      ..close();
    c.drawPath(path, _p(Color.lerp(_e5Cols[col], Colors.white, 0.55)!));
    c.save();
    c.clipPath(path);
    c.drawRect(Rect.fromLTRB(r.left, r.bottom - r.height * fill / 3, r.right, r.bottom), _p(_e5Cols[col]));
    c.restore();
    c.drawPath(path, _stroke(_e5Cols[col], 1.2));
  }
}

/// Renk İkilileri: kuyuda birleşmiş renkli boncuk öbekleri, düşen ikili ve zincir yazısı; yanda rakip tahtası.
void _e5Pairs(Canvas c) {
  _bg(c, const Color(0xFF3A2F6B));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 10, 56, 84), const Radius.circular(8)), _p(Colors.black.withValues(alpha: 0.3)));
  const g = 9.0;
  const o = Offset(12, 12);
  const grid = [
    '......',
    '..ab..',
    '......',
    '......',
    '......',
    '....c.',
    'b...cc',
    'bb.dcd',
    'aabddd',
  ];
  Color col(String ch) => switch (ch) {
        'a' => const Color(0xFFFF6B6B),
        'b' => const Color(0xFF4DD4AC),
        'c' => const Color(0xFFFFC145),
        _ => const Color(0xFF5DA9FF),
      };
  for (var y = 0; y < grid.length; y++) {
    for (var x = 0; x < 6; x++) {
      final ch = grid[y][x];
      if (ch == '.') continue;
      final p = o + Offset((x + 0.5) * g, (y + 0.5) * g);
      if (x < 5 && grid[y][x + 1] == ch) c.drawRect(Rect.fromCenter(center: p + const Offset(g / 2, 0), width: g, height: g * 0.5), _p(col(ch)));
      if (y < grid.length - 1 && grid[y + 1][x] == ch) c.drawRect(Rect.fromCenter(center: p + const Offset(0, g / 2), width: g * 0.5, height: g), _p(col(ch)));
    }
  }
  for (var y = 0; y < grid.length; y++) {
    for (var x = 0; x < 6; x++) {
      final ch = grid[y][x];
      if (ch == '.') continue;
      final p = o + Offset((x + 0.5) * g, (y + 0.5) * g);
      c.drawCircle(p, g * 0.44, _p(col(ch)));
      c.drawCircle(p - Offset(g * 0.14, g * 0.15), g * 0.13, _p(Colors.white.withValues(alpha: 0.5)));
    }
  }
  _text(c, '3×', const Offset(38, 44), 15, _bzGold);
  // rakip tahtası (küçük)
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(72, 40, 20, 40), const Radius.circular(4)), _p(Colors.black.withValues(alpha: 0.3)));
  for (var i = 0; i < 10; i++) {
    c.drawCircle(Offset(76.0 + (i % 3) * 6, 76.0 - (i ~/ 3) * 6), 2.4, _p(i % 4 == 0 ? const Color(0xFF8B93A1) : _e5Cols[i % 5]));
  }
  _text(c, 'VS', const Offset(82, 30), 8, Colors.white70);
}

/// Blok Macerası: blok tahtası, açılmış lale resmi kareleri ve hâlâ gizli soluk noktalar, üstte macera bayrağı.
void _e5Adventure(Canvas c) {
  _bg(c, const Color(0xFF2F7D6B));
  const n = 8;
  const s = 9.0;
  const o = Offset(14, 16);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - 2, o.dy - 2, n * s + 4, n * s + 4), const Radius.circular(6)), _p(const Color(0xFF16203A)));
  const tulip = [
    '........',
    '..r.r...',
    '..rrr...',
    '..rrr...',
    '...g....',
    '..gg....',
    '...g....',
    '........',
  ];
  const revealedRows = {1, 2, 5, 6};
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + x * s + 0.6, o.dy + y * s + 0.6, s - 1.2, s - 1.2), const Radius.circular(1.6));
      final ch = tulip[y][x];
      if (ch != '.' && revealedRows.contains(y)) {
        c.drawRRect(r, _p(ch == 'r' ? const Color(0xFFE85D75) : const Color(0xFF5BC26A)));
      } else if (y == 7 || (y == 3 && x > 3)) {
        c.drawRRect(r, _p(_e5Cols[(x + y) % 6]));
      } else {
        c.drawRRect(r, _p(Colors.white.withValues(alpha: 0.1)));
        if (ch != '.') c.drawCircle(r.outerRect.center, 1.2, _p(Colors.white.withValues(alpha: 0.35)));
      }
    }
  }
  // bayrak
  c.drawLine(const Offset(84, 6), const Offset(84, 30), _stroke(Colors.white, 1.6));
  c.drawPath(
      Path()
        ..moveTo(84, 6)
        ..lineTo(96, 11)
        ..lineTo(84, 16)
        ..close(),
      _p(_bzGold));
  // parça
  for (final (x, y) in const [(0, 0), (1, 0), (1, 1)]) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(80 + x * 7.0, 84 + y * 7.0, 6.4, 6.4), const Radius.circular(1.4)), _p(const Color(0xFF5DA9FF)));
  }
}
