part of 'covers.dart';

/// 4. tur kapakları (Bilgi, Zihin, Müzik, Parti). Her tür yalnızca bir oyuna aittir:
/// estimc Kestirme Ustası, trailmkc İz Sürme, flankc Ok Yönü, rhythmrunc Ritim Koşusu,
/// usulc Usul ve Tala, kalimbac Kalimba ve Gamelan, melpuzc Melodi Bulmacası,
/// geniec Aklımdan Tuttum, surveyc Halk Ne Dedi?, quizladderc Bilgi Merdiveni,
/// silhouettec Ülke Silüeti, cornersc 2-4 Kişilik Mini Oyunlar, dilemmac Hangisini
/// Seçerdin?, onecluec Tek İpucu, twotruthc İki Doğru Bir Yalan.
bool _paintEk4bCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  switch (cover.kind) {
    case 'estimc':
      _e4Estim(c, seed, v);
    case 'trailmkc':
      _e4Trail(c, seed, v);
    case 'flankc':
      _e4Flank(c, seed, v);
    case 'rhythmrunc':
      _e4Run(c, seed, v);
    case 'usulc':
      _e4Usul(c, seed, v);
    case 'kalimbac':
      _e4Kalimba(c, seed, v);
    case 'melpuzc':
      _e4MelPuz(c, seed, v);
    case 'geniec':
      _e4Genie(c, seed, v);
    case 'surveyc':
      _e4Survey(c, seed, v);
    case 'quizladderc':
      _e4Ladder(c, seed, v);
    case 'silhouettec':
      _e4Silhouette(c, seed, v);
    case 'cornersc':
      _e4Corners(c, seed, v);
    case 'dilemmac':
      _e4Dilemma(c, seed, v);
    case 'onecluec':
      _e4OneClue(c, seed, v);
    case 'twotruthc':
      _e4TwoTruth(c, seed, v);
    default:
      return false;
  }
  return true;
}

const _e4Ink = Color(0xFF22303F);
const _e4Paper = Color(0xFFF7F2E8);

void _e4Card(Canvas c, Rect r, {Color face = _e4Paper, double rad = 6}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(rad));
  _shadowRRect(c, rr);
  c.drawRRect(rr, _p(face));
}

void _e4Estim(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFFD0674E));
  _e4Card(c, const Rect.fromLTWH(8, 10, 50, 50));
  final r = math.Random(11 + v);
  for (var i = 0; i < 26; i++) {
    c.drawCircle(Offset(13 + r.nextDouble() * 40, 15 + r.nextDouble() * 40), 1.9, _p(_pal[i % _pal.length]));
  }
  // İletki ve açı
  const o = Offset(76, 50);
  c.drawArc(Rect.fromCircle(center: o, radius: 20), math.pi, math.pi, true, _p(Colors.white.withValues(alpha: 0.9)));
  for (var k = 0; k <= 12; k++) {
    final a = math.pi + k * math.pi / 12;
    c.drawLine(o + Offset(math.cos(a), math.sin(a)) * 17, o + Offset(math.cos(a), math.sin(a)) * 20, _stroke(_e4Ink, 0.7));
  }
  final ang = math.pi + 0.7 + v * 0.25;
  c.drawLine(o, o + const Offset(-19, 0), _stroke(const Color(0xFFC8553D), 1.8));
  c.drawLine(o, o + Offset(math.cos(ang), math.sin(ang)) * 19, _stroke(const Color(0xFFC8553D), 1.8));
  // Cetvel
  final ruler = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 70, 80, 14), const Radius.circular(3));
  _shadowRRect(c, ruler);
  c.drawRRect(ruler, _p(const Color(0xFFF2C14E)));
  for (var x = 14.0; x < 88; x += 4) {
    c.drawLine(Offset(x, 70), Offset(x, (x - 14) % 16 == 0 ? 77 : 74), _stroke(_e4Ink, 0.7));
  }
  _text(c, '≈', const Offset(30, 35), 22, _e4Ink.withValues(alpha: 0.25));
}

void _e4Trail(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF3D85C6));
  _e4Card(c, const Rect.fromLTWH(8, 8, 84, 84));
  const pts = [Offset(22, 26), Offset(48, 20), Offset(74, 32), Offset(60, 54), Offset(30, 50), Offset(26, 76), Offset(58, 78), Offset(80, 70)];
  const labels = ['1', 'A', '2', 'B', '3', 'C', '4', 'D'];
  final done = 5 + v % 3;
  final path = Path()..moveTo(pts[0].dx, pts[0].dy);
  for (var i = 1; i < done; i++) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  c.drawPath(path, _stroke(const Color(0xFF3E6FB0), 2.2));
  for (var i = 0; i < pts.length; i++) {
    c.drawCircle(pts[i], 7, _p(i < done ? const Color(0xFF4F9A6E) : Colors.white));
    c.drawCircle(pts[i], 7, _stroke(_e4Ink, 0.9));
    _text(c, labels[i], pts[i], 7.5, i < done ? Colors.white : _e4Ink);
  }
}

void _e4Arrow(Canvas c, Offset o, double s, bool right, Color col) {
  final p = _stroke(col, s * 0.16);
  c.drawLine(o - Offset(s / 2, 0), o + Offset(s / 2, 0), p);
  final tip = o + Offset(right ? s / 2 : -s / 2, 0);
  final b = right ? -1.0 : 1.0;
  c.drawPath(
      Path()
        ..moveTo(tip.dx + b * s * 0.32, tip.dy - s * 0.32)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + b * s * 0.32, tip.dy + s * 0.32),
      p);
}

void _e4Flank(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF3F8F78));
  final rr = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 24, 88, 26), const Radius.circular(8));
  _shadowRRect(c, rr);
  c.drawRRect(rr, _p(Colors.black.withValues(alpha: 0.35)));
  final mid = v.isEven;
  for (var i = 0; i < 5; i++) {
    final right = i == 2 ? mid : !mid;
    _e4Arrow(c, Offset(16 + i * 17.0, 37), 12, right, i == 2 ? Colors.white : Colors.white54);
  }
  final rr2 = RRect.fromRectAndRadius(const Rect.fromLTWH(20, 58, 60, 18), const Radius.circular(6));
  c.drawRRect(rr2, _p(Colors.black.withValues(alpha: 0.25)));
  for (var i = 0; i < 3; i++) {
    _e4Arrow(c, Offset(34 + i * 16.0, 67), 9, true, const Color(0xFFE5534B));
  }
  // Sol ve sağ dokunma alanları
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 82, 40, 12), const Radius.circular(5)), _p(Colors.white24));
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52, 82, 40, 12), const Radius.circular(5)), _p(Colors.white38));
}

void _e4Note(Canvas c, Offset o, double s, Color col) {
  c.drawOval(Rect.fromCenter(center: o, width: s * 1.3, height: s), _p(col));
  c.drawLine(o + Offset(s * 0.6, 0), o + Offset(s * 0.6, -s * 2.6), _stroke(col, s * 0.22));
}

void _e4Run(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF6B4FB5));
  // Vuruş çizgisi ve bloklar
  c.drawRect(const Rect.fromLTWH(0, 74, 100, 26), _p(Colors.black.withValues(alpha: 0.3)));
  for (var i = 0; i < 6; i++) {
    final x = 6.0 + i * 17;
    c.drawLine(Offset(x, 74), Offset(x, 100), _stroke(Colors.white.withValues(alpha: i.isEven ? 0.5 : 0.18), 1.2));
  }
  for (final x in [34.0, 68.0]) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, 62, 12, 12), const Radius.circular(2));
    c.drawRRect(r, _p(const Color(0xFFF2B53A)));
  }
  // Zıplayan koşucu
  final y = 40.0 - v * 2;
  c.drawCircle(Offset(42, y), 5, _p(Colors.white));
  final body = _stroke(Colors.white, 3);
  c.drawLine(Offset(42, y + 5), Offset(40, y + 18), body);
  c.drawLine(Offset(40, y + 18), Offset(33, y + 24), body);
  c.drawLine(Offset(40, y + 18), Offset(48, y + 22), body);
  c.drawLine(Offset(41, y + 9), Offset(32, y + 6), body);
  c.drawLine(Offset(41, y + 9), Offset(50, y + 12), body);
  // Yay ve notalar
  c.drawArc(const Rect.fromLTWH(20, 30, 46, 60), math.pi * 1.1, math.pi * 0.8, false, _stroke(Colors.white30, 1.2));
  _e4Note(c, const Offset(76, 30), 5, const Color(0xFFFFE08A));
  _e4Note(c, const Offset(86, 20), 4, const Color(0xFF8FD3FF));
  _e4Note(c, const Offset(16, 22), 4, const Color(0xFFFF9EC7));
}

void _e4Usul(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF9C5B2E));
  const o = Offset(50, 52);
  // Def/darbuka derisi
  c.drawCircle(o + const Offset(0, 2), 30, _p(Colors.black26));
  c.drawCircle(o, 30, _p(const Color(0xFF7A4A24)));
  c.drawCircle(o, 25, _p(const Color(0xFFF1DFC0)));
  c.drawCircle(o, 25, _stroke(const Color(0xFF5B3A24), 1));
  // Usul döngüsü: DÜM (büyük) ve TEK (küçük) vuruşlar
  const pattern = [2, 0, 1, 0, 2, 1, 0, 1, 2, 0, 1, 1];
  final n = 8 + v % 3 * 2;
  for (var i = 0; i < n; i++) {
    final a = -math.pi / 2 + i * 2 * math.pi / n;
    final p = o + Offset(math.cos(a), math.sin(a)) * 38;
    final k = pattern[i % pattern.length];
    if (k == 0) {
      c.drawCircle(p, 1.6, _p(Colors.white54));
    } else {
      c.drawCircle(p, k == 2 ? 5.2 : 3.4, _p(k == 2 ? const Color(0xFFE2574C) : const Color(0xFFF2C14E)));
    }
  }
  _text(c, 'DÜM', o - const Offset(0, 6), 9, const Color(0xFF7A4A24));
  _text(c, 'tek', o + const Offset(0, 7), 8, const Color(0xFF7A4A24), w: FontWeight.w600);
}

void _e4Kalimba(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF2E8B7A));
  final body = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 26, 54, 64), const Radius.circular(10));
  _shadowRRect(c, body, dy: 2.6);
  c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFFD9A066), Color(0xFF9C6431)]).createShader(body.outerRect));
  c.drawCircle(const Offset(41, 70), 6, _p(const Color(0xFF5B3A24)));
  c.drawRect(const Rect.fromLTWH(16, 40, 50, 4), _p(const Color(0xFF8A8F98)));
  const lens = [22.0, 28.0, 34.0, 40.0, 34.0, 28.0, 22.0, 16.0];
  for (var i = 0; i < lens.length; i++) {
    final x = 19.0 + i * 6;
    final top = 42 - lens[i] * 0.55;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, top, 3.4, lens[i] * 0.55 + 6), const Radius.circular(1.6)),
        _p(i == 3 + v % 3 ? Colors.white : const Color(0xFFD6DCE3)));
  }
  // Gamelan gongu
  const g = Offset(80, 30);
  c.drawLine(const Offset(70, 12), const Offset(90, 12), _stroke(const Color(0xFF5B3A24), 2));
  c.drawLine(const Offset(80, 12), const Offset(80, 18), _stroke(Colors.black54, 1));
  _stone(c, g, 12, const Color(0xFFD9A441));
  c.drawCircle(g, 4.5, _p(const Color(0xFFB57F16)));
  for (var i = 0; i < 3; i++) {
    c.drawArc(Rect.fromCircle(center: g, radius: 15.0 + i * 4), -0.6, 1.2, false, _stroke(Colors.white.withValues(alpha: 0.45 - i * 0.12), 1));
  }
}

void _e4MelPuz(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF3B6FB0));
  // Dört porte parçası, biri yerinden kaymış
  for (var i = 0; i < 4; i++) {
    final off = i == 1 + v % 3 ? const Offset(4, 10) : Offset.zero;
    final r = Rect.fromLTWH(6 + i * 22.0, 30, 22, 32).shift(off);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
    _shadowRRect(c, rr);
    c.drawRRect(rr, _p(i == 1 + v % 3 ? const Color(0xFFFFF4D6) : _e4Paper));
    for (var l = 0; l < 5; l++) {
      c.drawLine(Offset(r.left + 1, r.top + 8 + l * 4.0), Offset(r.right - 1, r.top + 8 + l * 4.0), _stroke(Colors.black38, 0.5));
    }
    _e4Note(c, Offset(r.left + 9, r.top + 24 - ((i * 5 + v) % 4) * 3.0), 3.4, _e4Ink);
    // Yapboz çıkıntısı
    c.drawCircle(Offset(r.right, r.top + 16), 3.2, _p(i == 1 + v % 3 ? const Color(0xFFFFF4D6) : _e4Paper));
    _text(c, '${i + 1}', Offset(r.center.dx, r.bottom - 4), 5.5, Colors.black54);
  }
  c.drawCircle(const Offset(80, 82), 9, _p(Colors.white.withValues(alpha: 0.9)));
  c.drawPath(Path()..addPolygon(const [Offset(77, 77), Offset(77, 87), Offset(85, 82)], true), _p(const Color(0xFF3B6FB0)));
}

void _e4Genie(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF4B2F8F));
  // Yıldızlar
  final r = math.Random(5 + v);
  for (var i = 0; i < 14; i++) {
    c.drawCircle(Offset(r.nextDouble() * 100, r.nextDouble() * 55), 0.8 + r.nextDouble(), _p(Colors.white70));
  }
  // Kristal küre ve altlık
  const o = Offset(50, 48);
  c.drawCircle(o, 30, _p(const Color(0xFF9B7BEA).withValues(alpha: 0.25)));
  c.drawCircle(
      o,
      24,
      Paint()
        ..shader = const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFE9DDFF), Color(0xFF8E6CE0), Color(0xFF3E2780)])
            .createShader(Rect.fromCircle(center: o, radius: 24)));
  c.drawCircle(const Offset(42, 40), 5, _p(Colors.white38));
  _text(c, '?', o + const Offset(1, 2), 26, Colors.white);
  c.drawPath(Path()..addPolygon(const [Offset(32, 70), Offset(68, 70), Offset(74, 82), Offset(26, 82)], true), _p(const Color(0xFFB57F16)));
  // Evet / hayır balonları
  final yes = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 84, 30, 12), const Radius.circular(6));
  final no = RRect.fromRectAndRadius(const Rect.fromLTWH(64, 84, 30, 12), const Radius.circular(6));
  c.drawRRect(yes, _p(const Color(0xFF4F9A6E)));
  c.drawRRect(no, _p(const Color(0xFFC8553D)));
  _text(c, '✓', yes.center, 9, Colors.white);
  _text(c, '✗', no.center, 9, Colors.white);
}

void _e4Survey(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF1F4E8C));
  final board = RRect.fromRectAndRadius(const Rect.fromLTWH(8, 10, 84, 80), const Radius.circular(8));
  _shadowRRect(c, board);
  c.drawRRect(board, _p(const Color(0xFF13294B)));
  c.drawRRect(board, _stroke(const Color(0xFFF2B53A), 2));
  const pts = [38, 24, 17, 11, 6];
  for (var i = 0; i < 5; i++) {
    final r = Rect.fromLTWH(14, 16 + i * 14.0, 72, 11);
    final open = i <= v % 3 + 1;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _p(open ? const Color(0xFF3075C4) : const Color(0xFF223C66)));
    if (open) {
      c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 4, 40 - i * 6.0, 3), _p(Colors.white70));
      _text(c, '${pts[i]}', Offset(r.right - 8, r.center.dy), 7.5, const Color(0xFFFFE08A));
    } else {
      _text(c, '${i + 1}', r.center, 7.5, Colors.white70);
    }
  }
}

void _e4Ladder(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF2B5DA8));
  for (var i = 0; i < 8; i++) {
    final y = 86 - i * 10.0;
    final w = 46 - i * 3.0;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(50 - w / 2, y, w, 8), const Radius.circular(3));
    final cur = i == 3 + v % 3;
    c.drawRRect(r, _p(cur ? const Color(0xFFF2B53A) : (i < 3 + v % 3 ? const Color(0xFF4F9A6E) : Colors.white24)));
    _text(c, '${(i + 1) * 2 - 1}', r.center, 6, cur ? _e4Ink : Colors.white);
  }
  _e4Star(c, const Offset(50, 9), 7, const Color(0xFFFFD54F));
  // Üç joker
  for (var i = 0; i < 3; i++) {
    final o = Offset(10, 30 + i * 18.0);
    c.drawCircle(o, 7, _p(i == 0 ? Colors.white24 : const Color(0xFFE2574C)));
    _text(c, ['½', '↻', '👥'][i], o, i == 2 ? 6 : 8, Colors.white);
  }
}

void _e4Star(Canvas c, Offset o, double r, Color col) {
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r : r * 0.45;
    final p = o + Offset(math.cos(a), math.sin(a)) * rr;
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  c.drawPath(path, _p(col));
}

void _e4Silhouette(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF2F7F86));
  // Hayalî bir ülke silüeti (gerçek bir sınır değildir)
  final r = math.Random(31 + v);
  final path = Path();
  const o = Offset(42, 46);
  for (var i = 0; i < 18; i++) {
    final a = i * 2 * math.pi / 18;
    final rad = 22 + r.nextDouble() * 12 * (i.isEven ? 1 : 0.6);
    final p = o + Offset(math.cos(a) * rad, math.sin(a) * rad * 0.8);
    if (i == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  c.drawPath(path.shift(const Offset(0, 2)), _p(Colors.black26));
  c.drawPath(path, _p(_e4Ink));
  // Pusula oku ve mesafe
  const k = Offset(80, 74);
  c.drawCircle(k, 13, _p(Colors.white.withValues(alpha: 0.9)));
  final a = -0.8 + v * 0.6;
  c.drawPath(
      Path()
        ..moveTo(k.dx + math.cos(a) * 10, k.dy + math.sin(a) * 10)
        ..lineTo(k.dx + math.cos(a + 2.6) * 6, k.dy + math.sin(a + 2.6) * 6)
        ..lineTo(k.dx + math.cos(a - 2.6) * 6, k.dy + math.sin(a - 2.6) * 6)
        ..close(),
      _p(const Color(0xFFC8553D)));
  final tag = RRect.fromRectAndRadius(const Rect.fromLTWH(8, 82, 44, 12), const Radius.circular(6));
  c.drawRRect(tag, _p(Colors.black38));
  _text(c, '1240 km', tag.center, 7, Colors.white);
}

void _e4Corners(Canvas c, Color seed, int v) {
  const cols = [Color(0xFFE2574C), Color(0xFF3075C4), Color(0xFF3BA776), Color(0xFFF2A93B)];
  for (var i = 0; i < 4; i++) {
    final r = Rect.fromLTWH(i.isOdd ? 50 : 0, i >= 2 ? 50 : 0, 50, 50);
    c.drawRect(r, _p(cols[i]));
    final btn = Offset(i.isOdd ? 84 : 16, i >= 2 ? 84 : 16);
    c.drawCircle(btn + const Offset(0, 1.5), 10, _p(Colors.black26));
    c.drawCircle(btn, 10, _p(Color.lerp(cols[i], Colors.white, 0.45)!));
  }
  c.drawCircle(const Offset(50, 50), 22, _p(_e4Ink));
  c.drawCircle(const Offset(50, 50), 22, _stroke(Colors.white, 1.6));
  // Ortada mini oyun simgeleri: top, yıldız ve şimşek
  c.drawCircle(const Offset(42, 46), 5, _p(Colors.white));
  _e4Star(c, const Offset(58, 46), 6, const Color(0xFFFFD54F));
  _text(c, ['2', '3', '4'][v % 3], const Offset(50, 60), 10, Colors.white);
}

void _e4Dilemma(Canvas c, Color seed, int v) {
  c.drawRect(const Rect.fromLTWH(0, 0, 50, 100), _p(const Color(0xFFE0735A)));
  c.drawRect(const Rect.fromLTWH(50, 0, 50, 100), _p(const Color(0xFF3B86A8)));
  for (var i = 0; i < 2; i++) {
    final r = Rect.fromLTWH(8 + i * 50.0, 22, 34, 46);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
    _shadowRRect(c, rr);
    c.drawRRect(rr, _p(_e4Paper));
    for (var l = 0; l < 3; l++) {
      c.drawRect(Rect.fromLTWH(r.left + 5, r.top + 10 + l * 8.0, 24 - l * 5.0, 3), _p(Colors.black26));
    }
    _text(c, i == 0 ? 'A' : 'B', Offset(r.center.dx, r.bottom - 9), 12, i == 0 ? const Color(0xFFC8553D) : const Color(0xFF2B6C8A));
  }
  c.drawCircle(const Offset(50, 45), 11, _p(_e4Ink));
  _text(c, '?', const Offset(50, 45.5), 13, Colors.white);
  // Oy çubuğu
  final split = 30.0 + v * 15;
  c.drawRect(Rect.fromLTWH(8, 80, split, 8), _p(Colors.white));
  c.drawRect(Rect.fromLTWH(8 + split, 80, 84 - split, 8), _p(Colors.white54));
}

void _e4OneClue(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFF7A5BA6));
  final big = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 8, 40, 30), const Radius.circular(6));
  _shadowRRect(c, big);
  c.drawRRect(big, _p(const Color(0xFFFFE08A)));
  _text(c, '?', big.center, 20, _e4Ink);
  for (var i = 0; i < 4; i++) {
    final r = Rect.fromLTWH(6 + i * 23.0, 52 + (i.isOdd ? 6.0 : 0), 20, 30);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(4));
    _shadowRRect(c, rr);
    c.drawRRect(rr, _p(_e4Paper));
    c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 13, 12, 3), _p(_e4Ink.withValues(alpha: 0.6)));
    final dup = i == 1 + v % 2 || i == 3;
    if (dup) {
      c.drawLine(r.topLeft + const Offset(3, 3), r.bottomRight - const Offset(3, 3), _stroke(const Color(0xFFC8553D), 2));
      c.drawLine(r.topRight + const Offset(-3, 3), r.bottomLeft + const Offset(3, -3), _stroke(const Color(0xFFC8553D), 2));
    }
  }
}

void _e4TwoTruth(Canvas c, Color seed, int v) {
  _bg(c, seed, tint: const Color(0xFFC2507A));
  final lie = v % 3;
  for (var i = 0; i < 3; i++) {
    final r = Rect.fromLTWH(10 + (i.isOdd ? 12.0 : 0), 10 + i * 28.0, 66, 22);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    _shadowRRect(c, rr);
    c.drawRRect(rr, _p(_e4Paper));
    c.drawPath(
        Path()..addPolygon([Offset(r.left + 10, r.bottom - 1), Offset(r.left + 6, r.bottom + 6), Offset(r.left + 18, r.bottom - 1)], true),
        _p(_e4Paper));
    c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 9, 36, 3.4), _p(Colors.black26));
    final ok = i != lie;
    final b = Offset(r.right - 10, r.center.dy);
    c.drawCircle(b, 7, _p(ok ? const Color(0xFF4F9A6E) : const Color(0xFFC8553D)));
    _text(c, ok ? '✓' : '✗', b, 8, Colors.white);
  }
}
