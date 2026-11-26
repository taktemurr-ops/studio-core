part of 'covers.dart';

/// 4. tur Kart, Masa ve Kelime kapakları. Her tür yalnızca bir oyuna aittir:
/// k4_tigergoat Kaplan ve Keçiler, k4_hiddenranks Gizli Rütbeler, k4_cini Çini
/// Döşeme, k4_cardline Kartlı Beşleme, k4_partnerdomino Eşli Domino,
/// k4_chinchon Çinçon, k4_burako Burako, k4_doppelkopf Doppelkopf,
/// k4_fourpics Dört Resim Bir Kelime, k4_fiveclues Beş İpucu, k4_letterbox
/// Harf Kutusu, k4_themehunt Tema Avı. Hepsi vektör; dış görsel ya da marka yok.
bool _paintEk4KmkCover(Canvas c, GameCover cover, Color seed) {
  switch (cover.kind) {
    case 'k4_tigergoat':
      _k4TigerGoat(c);
    case 'k4_hiddenranks':
      _k4HiddenRanks(c);
    case 'k4_cini':
      _k4Cini(c);
    case 'k4_cardline':
      _k4CardLine(c);
    case 'k4_partnerdomino':
      _k4PartnerDomino(c);
    case 'k4_chinchon':
      _k4Chinchon(c);
    case 'k4_burako':
      _k4Burako(c);
    case 'k4_doppelkopf':
      _k4Doppelkopf(c);
    case 'k4_fourpics':
      _k4FourPics(c);
    case 'k4_fiveclues':
      _k4FiveClues(c);
    case 'k4_letterbox':
      _k4LetterBox(c);
    case 'k4_themehunt':
      _k4ThemeHunt(c);
    default:
      return false;
  }
  return true;
}

/// Bu dosyadaki bütün kapak türleri (testler için).
const ek4KmkCoverKinds = [
  'k4_tigergoat', 'k4_hiddenranks', 'k4_cini', 'k4_cardline', 'k4_partnerdomino', 'k4_chinchon',
  'k4_burako', 'k4_doppelkopf', 'k4_fourpics', 'k4_fiveclues', 'k4_letterbox', 'k4_themehunt',
];

// ---- Masa ----------------------------------------------------------------------

/// Kaplan ve Keçiler: çaprazlı 5×5 ağ tahtası, çizgili turuncu kaplanlar, beyaz keçiler.
void _k4TigerGoat(Canvas c) {
  _bg(c, const Color(0xFF6B3A1E));
  _woodBoard(c, const Rect.fromLTWH(10, 10, 80, 80));
  const o = Offset(20, 20), g = 15.0;
  final line = _stroke(const Color(0xFF3E2414), 1.2);
  for (var i = 0; i < 5; i++) {
    c.drawLine(o + Offset(0, i * g), o + Offset(4 * g, i * g), line);
    c.drawLine(o + Offset(i * g, 0), o + Offset(i * g, 4 * g), line);
  }
  c.drawLine(o, o + const Offset(4 * g, 4 * g), line);
  c.drawLine(o + const Offset(4 * g, 0), o + const Offset(0, 4 * g), line);
  c.drawLine(o + const Offset(2 * g, 0), o + const Offset(4 * g, 2 * g), line);
  c.drawLine(o + const Offset(4 * g, 2 * g), o + const Offset(2 * g, 4 * g), line);
  c.drawLine(o + const Offset(2 * g, 4 * g), o + const Offset(0, 2 * g), line);
  c.drawLine(o + const Offset(0, 2 * g), o + const Offset(2 * g, 0), line);
  void tiger(int x, int y) {
    final p = o + Offset(x * g, y * g);
    _stone(c, p, 6.2, const Color(0xFFF08A24));
    final s = _stroke(const Color(0xFF2A1A0E), 1.3);
    for (final dx in [-2.6, 0.0, 2.6]) {
      c.drawLine(p + Offset(dx - 1, -4), p + Offset(dx + 0.6, -0.8), s);
    }
    c.drawCircle(p + const Offset(-1.8, 1.6), 0.8, _p(_ink));
    c.drawCircle(p + const Offset(1.8, 1.6), 0.8, _p(_ink));
  }

  void goat(int x, int y) {
    final p = o + Offset(x * g, y * g);
    _stone(c, p, 5.2, const Color(0xFFF2EEE4));
    final h = _stroke(const Color(0xFF8C7A5E), 1.1);
    c.drawArc(Rect.fromCircle(center: p + const Offset(-2.4, -3.2), radius: 2.2), math.pi, 1.6, false, h);
    c.drawArc(Rect.fromCircle(center: p + const Offset(2.4, -3.2), radius: 2.2), -1.6, 1.6, false, h);
  }

  for (final (x, y) in const [(0, 0), (4, 0), (0, 4), (3, 3)]) {
    tiger(x, y);
  }
  for (final (x, y) in const [(1, 1), (2, 1), (1, 2), (2, 2), (3, 1), (2, 3), (1, 3)]) {
    goat(x, y);
  }
}

/// Gizli Rütbeler: kale düzeninde iki ordu; mavi taşların arkası soru işaretli, bir kırmızı taş açılmış (fil başı).
void _k4HiddenRanks(Canvas c) {
  _bg(c, const Color(0xFF2F5D34));
  const board = Rect.fromLTWH(8, 8, 84, 84);
  c.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(6)), _p(const Color(0xFF9CCB7A)));
  final grid = _stroke(Colors.black.withValues(alpha: 0.18), 0.7);
  for (var i = 1; i < 6; i++) {
    c.drawLine(Offset(8 + i * 14, 8), Offset(8 + i * 14, 92), grid);
    c.drawLine(Offset(8, 8 + i * 14), Offset(92, 8 + i * 14), grid);
  }
  // göl
  c.drawOval(const Rect.fromLTWH(37, 41, 26, 18), _p(const Color(0xFF4FA3D9)));
  void piece(int x, int y, Color col, String? face) {
    final r = Rect.fromLTWH(10 + x * 14, 10 + y * 14, 10, 10);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(2.5));
    _shadowRRect(c, rr, dy: 1.2);
    c.drawRRect(rr, _p(col));
    _text(c, face ?? '?', r.center, 7, Colors.white);
  }

  for (var x = 0; x < 6; x++) {
    piece(x, 0, const Color(0xFF2E5FA8), null);
    if (x != 2 && x != 3) piece(x, 1, const Color(0xFF2E5FA8), null);
    piece(x, 5, const Color(0xFFC0392B), x == 1 ? '9' : null);
    if (x != 4) piece(x, 4, const Color(0xFFC0392B), null);
  }
  // açılan taş: büyük fil silueti
  const big = Rect.fromLTWH(56, 54, 26, 26);
  final rr = RRect.fromRectAndRadius(big, const Radius.circular(5));
  _shadowRRect(c, rr, dy: 2);
  c.drawRRect(rr, _p(const Color(0xFFE74C3C)));
  final e = _p(Colors.white);
  c.drawOval(const Rect.fromLTWH(61, 60, 16, 12), e);
  c.drawOval(const Rect.fromLTWH(58, 59, 8, 10), e);
  c.drawPath(
      Path()
        ..moveTo(62, 67)
        ..quadraticBezierTo(60, 74, 63, 77)
        ..lineTo(65, 76)
        ..quadraticBezierTo(63, 72, 65, 68)
        ..close(),
      e);
  c.drawCircle(const Offset(66, 64), 0.9, _p(_ink));
}

/// Çini Döşeme: lacivert-turkuaz çini duvarı (lale motifli karolar), önde karo atölyesi tabağı.
void _k4Cini(Canvas c) {
  _bg(c, const Color(0xFF1F3F7A));
  const cols = [Color(0xFF1F5FBF), Color(0xFF2BB3B1), Color(0xFFE2574C), Color(0xFFF2EEE4), Color(0xFF1D2433)];
  void tileAt(Rect r, int k) {
    _tile(c, r, face: cols[k], rad: 2);
    final m = r.center;
    final ink = k == 3 ? const Color(0xFF1F5FBF) : Colors.white.withValues(alpha: 0.85);
    // lale: üç yaprak
    c.drawOval(Rect.fromCenter(center: m + Offset(0, -r.height * 0.1), width: r.width * 0.22, height: r.height * 0.36), _p(ink));
    c.drawOval(Rect.fromCenter(center: m + Offset(-r.width * 0.14, -r.height * 0.02), width: r.width * 0.16, height: r.height * 0.28), _p(ink));
    c.drawOval(Rect.fromCenter(center: m + Offset(r.width * 0.14, -r.height * 0.02), width: r.width * 0.16, height: r.height * 0.28), _p(ink));
    c.drawLine(m + Offset(0, r.height * 0.08), m + Offset(0, r.height * 0.3), _stroke(ink, r.width * 0.06));
  }

  const pattern = [
    [0, 1, 2, 3, 4],
    [4, 0, 1, -1, 3],
    [3, 4, -1, -1, 2],
  ];
  for (var y = 0; y < 3; y++) {
    for (var x = 0; x < 5; x++) {
      final r = Rect.fromLTWH(10 + x * 16.4, 8 + y * 16.4, 14.6, 14.6);
      if (pattern[y][x] < 0) {
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), _stroke(Colors.white.withValues(alpha: 0.35), 0.9));
      } else {
        tileAt(r, pattern[y][x]);
      }
    }
  }
  // atölye tabağı
  c.drawCircle(const Offset(50, 78), 17, _p(Colors.black.withValues(alpha: 0.25)));
  c.drawCircle(const Offset(50, 76), 17, _p(const Color(0xFFF4E6C8)));
  c.drawCircle(const Offset(50, 76), 17, _stroke(const Color(0xFFB08A4E), 1.5));
  tileAt(const Rect.fromLTWH(38, 64, 11, 11), 2);
  tileAt(const Rect.fromLTWH(51, 64, 11, 11), 2);
  tileAt(const Rect.fromLTWH(38, 77, 11, 11), 1);
  tileAt(const Rect.fromLTWH(51, 77, 11, 11), 0);
}

/// Kartlı Beşleme: küçük kart yüzlü 6×6 tahta, çaprazda beş yeşil pul, elde bir kart.
void _k4CardLine(Canvas c) {
  _bg(c, const Color(0xFF1F5C46));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 6, 74, 74), const Radius.circular(5)), _p(_felt));
  const g = 12.0;
  for (var y = 0; y < 6; y++) {
    for (var x = 0; x < 6; x++) {
      final r = Rect.fromLTWH(9 + x * g, 9 + y * g, g - 2, g - 2);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.5)), _p(_ivory));
      final corner = (x == 0 || x == 5) && (y == 0 || y == 5);
      if (corner) {
        c.drawCircle(r.center, 3, _p(const Color(0xFFF2A93B)));
      } else {
        drawSuit(c, (x * 3 + y) % 4, r.center, 5);
      }
    }
  }
  for (var i = 0; i < 5; i++) {
    final ctr = Offset(9 + i * g + (g - 2) / 2, 9 + i * g + (g - 2) / 2);
    c.drawCircle(ctr + const Offset(0, 0.8), 4.6, _p(Colors.black.withValues(alpha: 0.3)));
    c.drawCircle(ctr, 4.6, _p(const Color(0xFF2ECC71)));
    c.drawCircle(ctr, 2.4, _stroke(Colors.white.withValues(alpha: 0.7), 0.8));
  }
  for (final (x, y) in const [(4, 1), (1, 4), (5, 3)]) {
    final ctr = Offset(9 + x * g + (g - 2) / 2, 9 + y * g + (g - 2) / 2);
    c.drawCircle(ctr, 4.6, _p(const Color(0xFF3075C4)));
  }
  c.drawLine(const Offset(14, 14), const Offset(62, 62), _stroke(Colors.white.withValues(alpha: 0.85), 1.6));
  drawCard(c, const Offset(84, 80), 20, 0.22, rank: '7', suit: 2);
}

/// Eşli Domino: ortada haç biçiminde domino zinciri, dört köşede iki takımın renkli elleri.
void _k4PartnerDomino(Canvas c) {
  _bg(c, const Color(0xFF2E5E4E));
  c.drawCircle(const Offset(50, 50), 44, _p(const Color(0xFF1B4D3A)));
  c.drawCircle(const Offset(50, 50), 44, _stroke(const Color(0xFF8A5A36), 3));
  _e5Domino(c, const Rect.fromLTWH(43, 42, 14, 16), 6, 6, vertical: true);
  _e5Domino(c, const Rect.fromLTWH(25, 45, 18, 10), 6, 3);
  _e5Domino(c, const Rect.fromLTWH(57, 45, 18, 10), 6, 2);
  _e5Domino(c, const Rect.fromLTWH(45, 24, 10, 18), 1, 6, vertical: true);
  _e5Domino(c, const Rect.fromLTWH(45, 58, 10, 18), 6, 5, vertical: true);
  void hand(Offset o, double a, Color team) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(a);
    for (var i = -1; i <= 1; i++) {
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(i * 5.0, 0), width: 5, height: 9), const Radius.circular(1.4));
      c.drawRRect(r, _p(team));
      c.drawRRect(r, _stroke(Colors.white.withValues(alpha: 0.7), 0.6));
    }
    c.restore();
  }

  const a = Color(0xFFF2A93B), b = Color(0xFF5DA9FF);
  hand(const Offset(50, 10), 0, a);
  hand(const Offset(50, 90), 0, a);
  hand(const Offset(10, 50), math.pi / 2, b);
  hand(const Offset(90, 50), math.pi / 2, b);
}

// ---- Kart ----------------------------------------------------------------------

/// İspanyol destesi kart yüzü: 0 altın, 1 kupa, 2 kılıç, 3 sopa.
void _k4SpanishCard(Canvas c, Offset center, double w, double angle, int suit, String rank) {
  final h = w * 1.5;
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(angle);
  final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), Radius.circular(w * 0.1));
  _shadowRRect(c, r, dy: w * 0.06, a: 0.3);
  c.drawRRect(r, _p(_ivory));
  // İspanyol destesinin kesik çerçevesi
  c.drawRRect(r.deflate(w * 0.07), _stroke(const Color(0xFFC0392B), w * 0.025));
  const cols = [Color(0xFFE0A526), Color(0xFFC0392B), Color(0xFF2E5FA8), Color(0xFF3BA776)];
  final col = cols[suit];
  final s = w * 0.34;
  switch (suit) {
    case 0: // altın
      c.drawCircle(Offset.zero, s, _p(col));
      c.drawCircle(Offset.zero, s * 0.62, _stroke(const Color(0xFF9A6B12), w * 0.04));
      c.drawCircle(Offset.zero, s * 0.2, _p(const Color(0xFF9A6B12)));
    case 1: // kupa
      c.drawPath(
          Path()
            ..moveTo(-s, -s * 0.8)
            ..lineTo(s, -s * 0.8)
            ..quadraticBezierTo(s * 0.9, s * 0.2, 0, s * 0.3)
            ..quadraticBezierTo(-s * 0.9, s * 0.2, -s, -s * 0.8)
            ..close(),
          _p(col));
      c.drawRect(Rect.fromCenter(center: Offset(0, s * 0.6), width: s * 0.22, height: s * 0.6), _p(col));
      c.drawRect(Rect.fromCenter(center: Offset(0, s * 0.95), width: s * 0.9, height: s * 0.18), _p(col));
    case 2: // kılıç
      c.drawLine(Offset(0, -s * 1.2), Offset(0, s * 0.7), _stroke(col, w * 0.09));
      c.drawLine(Offset(-s * 0.55, s * 0.55), Offset(s * 0.55, s * 0.55), _stroke(const Color(0xFFE0A526), w * 0.08));
      c.drawLine(Offset(0, s * 0.6), Offset(0, s * 1.1), _stroke(const Color(0xFF8A5A36), w * 0.08));
    default: // sopa
      c.save();
      c.rotate(0.35);
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s * 0.55, height: s * 2.3), Radius.circular(s * 0.27)), _p(col));
      for (final y in [-0.6, 0.0, 0.6]) {
        c.drawCircle(Offset(s * 0.28, y * s), s * 0.12, _p(const Color(0xFF1F6B4A)));
      }
      c.restore();
  }
  _text(c, rank, Offset(-w * 0.3, -h * 0.36), w * 0.2, col);
  c.restore();
}

/// Çinçon: İspanyol destesinin dört takımı yelpaze halinde (altın, kupa, kılıç, sopa).
void _k4Chinchon(Canvas c) {
  _bg(c, const Color(0xFFB8860B));
  c.drawOval(const Rect.fromLTWH(8, 62, 84, 30), _p(_felt));
  _k4SpanishCard(c, const Offset(26, 52), 30, -0.38, 3, '1');
  _k4SpanishCard(c, const Offset(42, 46), 30, -0.13, 2, '1');
  _k4SpanishCard(c, const Offset(58, 46), 30, 0.13, 1, '1');
  _k4SpanishCard(c, const Offset(74, 52), 30, 0.38, 0, '1');
}

/// Burako: masada iki per (merdiven ve aynı sayılı), yanda ölü destesi (ters çevrili iki küçük yığın).
void _k4Burako(Canvas c) {
  _bg(c, const Color(0xFF8E3B2E));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 8, 88, 84), const Radius.circular(8)), _p(_felt));
  for (var i = 0; i < 5; i++) {
    drawCard(c, Offset(18 + i * 9.0, 30), 16, 0, rank: '${4 + i}', suit: 1);
  }
  for (var i = 0; i < 4; i++) {
    drawCard(c, Offset(18 + i * 9.0, 62), 16, 0, rank: i == 3 ? '2' : 'K', suit: i % 4);
  }
  // ölüler
  for (var k = 0; k < 2; k++) {
    for (var j = 0; j < 3; j++) {
      drawCard(c, Offset(78 + j * 0.8, 30 + k * 32 - j * 1.2), 15, k == 0 ? 0.05 : -0.05, back: true, backColor: const Color(0xFF7A2E2A));
    }
  }
  // burako yıldızı
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rad = i.isEven ? 6.5 : 2.8;
    final pt = Offset(64 + rad * math.cos(a), 48 + rad * math.sin(a));
    if (i == 0) {
      star.moveTo(pt.dx, pt.dy);
    } else {
      star.lineTo(pt.dx, pt.dy);
    }
  }
  c.drawPath(star..close(), _p(const Color(0xFFF2C94C)));
}

/// Doppelkopf: dört oyunculu masa, ortada dört kart; iki sinek kızı (Q♣) altın çerçeveyle vurgulu.
void _k4Doppelkopf(Canvas c) {
  _bg(c, const Color(0xFF2F4F4F));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 12, 76, 76), const Radius.circular(12)), _p(_felt));
  for (final o in const [Offset(50, 6), Offset(50, 94), Offset(6, 50), Offset(94, 50)]) {
    c.drawCircle(o, 5.5, _p(const Color(0xFFD9C7A3)));
    c.drawCircle(o, 5.5, _stroke(Colors.black.withValues(alpha: 0.25), 0.8));
  }
  drawCard(c, const Offset(50, 30), 18, 0.05, rank: '10', suit: 1);
  drawCard(c, const Offset(30, 52), 18, -0.12, rank: 'A', suit: 2);
  drawCard(c, const Offset(70, 52), 18, 0.12, rank: 'Q', suit: 3);
  drawCard(c, const Offset(50, 70), 18, -0.04, rank: 'Q', suit: 3);
  for (final (o, a) in const [(Offset(70, 52), 0.12), (Offset(50, 70), -0.04)]) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(a);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 21, height: 28.5), const Radius.circular(3)),
        _stroke(const Color(0xFFF2C94C), 1.6));
    c.restore();
  }
}

// ---- Kelime --------------------------------------------------------------------

/// Dört Resim Bir Kelime: 2×2 çerçeveli simgeler (güneş, damla, ev, yaprak) ve altta harf taşları.
void _k4FourPics(Canvas c) {
  _bg(c, const Color(0xFF5B8FD1));
  const frames = [Rect.fromLTWH(12, 8, 36, 30), Rect.fromLTWH(52, 8, 36, 30), Rect.fromLTWH(12, 42, 36, 30), Rect.fromLTWH(52, 42, 36, 30)];
  const fills = [Color(0xFFFFE8A3), Color(0xFFCDE8FF), Color(0xFFFFD6C9), Color(0xFFD5F2D0)];
  for (var i = 0; i < 4; i++) {
    final rr = RRect.fromRectAndRadius(frames[i], const Radius.circular(4));
    _shadowRRect(c, rr, dy: 1.5);
    c.drawRRect(rr, _p(Colors.white));
    c.drawRRect(RRect.fromRectAndRadius(frames[i].deflate(2), const Radius.circular(3)), _p(fills[i]));
  }
  // güneş
  final sc = frames[0].center;
  for (var k = 0; k < 8; k++) {
    final a = k * math.pi / 4;
    c.drawLine(sc + Offset(math.cos(a) * 8, math.sin(a) * 8), sc + Offset(math.cos(a) * 11, math.sin(a) * 11), _stroke(const Color(0xFFF2A93B), 1.6));
  }
  c.drawCircle(sc, 6, _p(const Color(0xFFF2A93B)));
  // damla
  final dc = frames[1].center;
  c.drawPath(
      Path()
        ..moveTo(dc.dx, dc.dy - 10)
        ..quadraticBezierTo(dc.dx + 9, dc.dy + 2, dc.dx, dc.dy + 8)
        ..quadraticBezierTo(dc.dx - 9, dc.dy + 2, dc.dx, dc.dy - 10)
        ..close(),
      _p(const Color(0xFF3075C4)));
  // ev
  final hc = frames[2].center;
  c.drawPath(
      Path()
        ..moveTo(hc.dx - 10, hc.dy - 1)
        ..lineTo(hc.dx, hc.dy - 10)
        ..lineTo(hc.dx + 10, hc.dy - 1)
        ..close(),
      _p(const Color(0xFFE2574C)));
  c.drawRect(Rect.fromLTWH(hc.dx - 7, hc.dy - 1, 14, 10), _p(const Color(0xFFB0563C)));
  c.drawRect(Rect.fromLTWH(hc.dx - 2, hc.dy + 3, 4, 6), _p(const Color(0xFFFFE8A3)));
  // yaprak
  final lc = frames[3].center;
  c.drawPath(
      Path()
        ..moveTo(lc.dx - 9, lc.dy + 8)
        ..quadraticBezierTo(lc.dx - 9, lc.dy - 9, lc.dx + 9, lc.dy - 9)
        ..quadraticBezierTo(lc.dx + 9, lc.dy + 8, lc.dx - 9, lc.dy + 8)
        ..close(),
      _p(const Color(0xFF3BA776)));
  c.drawLine(lc + const Offset(-8, 7), lc + const Offset(5, -5), _stroke(const Color(0xFF1F6B4A), 1));
  // harf taşları
  for (var i = 0; i < 5; i++) {
    final r = Rect.fromLTWH(14 + i * 15.0, 78, 12, 13);
    _tile(c, r, rad: 2.5);
    if (i < 3) _text(c, const ['A', 'Ğ', 'A'][i], r.center, 9, _ink);
  }
}

/// Beş İpucu: beş ipucu şeridi (üçü açık, ikisi kapalı) ve büyüteç.
void _k4FiveClues(Canvas c) {
  _bg(c, const Color(0xFFE07A5F));
  for (var i = 0; i < 5; i++) {
    final r = Rect.fromLTWH(12, 10 + i * 15.0, 60, 11);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(5.5));
    _shadowRRect(c, rr, dy: 1.2);
    final open = i < 3;
    c.drawRRect(rr, _p(open ? _ivory : const Color(0xFF8E4A3A)));
    c.drawCircle(Offset(r.left + 6, r.center.dy), 3.6, _p(open ? const Color(0xFFE07A5F) : Colors.white.withValues(alpha: 0.4)));
    _text(c, '${i + 1}', Offset(r.left + 6, r.center.dy), 5, Colors.white);
    if (open) {
      c.drawLine(Offset(r.left + 13, r.center.dy), Offset(r.left + 22 + i * 9.0 + 10, r.center.dy), _stroke(_ink.withValues(alpha: 0.75), 2.4));
    } else {
      _text(c, '?', Offset(r.center.dx + 4, r.center.dy), 8, Colors.white.withValues(alpha: 0.85));
    }
  }
  // büyüteç
  c.drawCircle(const Offset(74, 62), 13, _p(Colors.white.withValues(alpha: 0.35)));
  c.drawCircle(const Offset(74, 62), 13, _stroke(_ink, 3.2));
  c.drawLine(const Offset(83.5, 71.5), const Offset(93, 81), _stroke(_ink, 5));
}

/// Harf Kutusu: kenarlarında üçer harf noktası olan kare, harfler arasında kenardan kenara zikzak zincir.
void _k4LetterBox(Canvas c) {
  _bg(c, const Color(0xFF81B29A));
  const sq = Rect.fromLTWH(24, 24, 52, 52);
  c.drawRect(sq, _p(Colors.white));
  c.drawRect(sq, _stroke(_ink, 2.4));
  final pts = <Offset>[];
  for (var i = 1; i <= 3; i++) {
    pts.add(Offset(sq.left + i * 13, sq.top));
    pts.add(Offset(sq.right, sq.top + i * 13));
    pts.add(Offset(sq.left + i * 13, sq.bottom));
    pts.add(Offset(sq.left, sq.top + i * 13));
  }
  const chain = [0, 5, 2, 7, 4, 9, 6, 11];
  final path = Path()..moveTo(pts[chain.first].dx, pts[chain.first].dy);
  for (final k in chain.skip(1)) {
    path.lineTo(pts[k].dx, pts[k].dy);
  }
  c.drawPath(path, _stroke(const Color(0xFFE07A5F), 2.2));
  const letters = ['K', 'T', 'A', 'E', 'M', 'R', 'İ', 'S', 'N', 'L', 'O', 'P'];
  for (var i = 0; i < pts.length; i++) {
    final used = chain.contains(i);
    c.drawCircle(pts[i], 3.4, _p(used ? const Color(0xFFE07A5F) : Colors.white));
    c.drawCircle(pts[i], 3.4, _stroke(_ink, 1.2));
    final out = pts[i] + (pts[i] - sq.center) * 0.24;
    _text(c, letters[i], out, 7.5, _ink);
  }
}

/// Tema Avı: harf ızgarası; kıvrılan renkli yollar bütün hücreleri doldurur.
void _k4ThemeHunt(Canvas c) {
  _bg(c, const Color(0xFF6C5CE7));
  const o = Offset(14, 14), g = 14.4;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - 4, o.dy - 4, g * 5 + 8, g * 5 + 8), const Radius.circular(8)), _p(_ivory));
  Offset ctr(int i) => o + Offset((i % 5 + 0.5) * g, (i ~/ 5 + 0.5) * g);
  const snakes = [
    [0, 1, 2, 7, 6, 5],
    [3, 4, 9, 8, 13, 14],
    [10, 11, 12, 17, 16, 15, 20],
    [21, 22, 23, 18, 19, 24],
  ];
  const cols = [Color(0xFFFFC145), Color(0xFF4DD4AC), Color(0xFFFF8FB1), Color(0xFF5DA9FF)];
  for (var k = 0; k < snakes.length; k++) {
    final p = Path()..moveTo(ctr(snakes[k].first).dx, ctr(snakes[k].first).dy);
    for (final i in snakes[k].skip(1)) {
      p.lineTo(ctr(i).dx, ctr(i).dy);
    }
    c.drawPath(p, _stroke(cols[k].withValues(alpha: k == 3 ? 0.35 : 0.9), g * 0.62));
  }
  const letters = 'ELMAKİRAZNARMUZUÇİLEKAYVA';
  for (var i = 0; i < 25; i++) {
    _text(c, letters[i], ctr(i), 8, _ink);
  }
}
