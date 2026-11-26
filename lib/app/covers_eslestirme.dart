part of 'covers.dart';

/// Eşleştir ve Sırala merkezinin oyuna özgü kapakları. Her tür tek bir oyunu
/// anlatır (tahta, taş, mekanik); hiçbiri başka oyunla paylaşılmaz.
/// Merkezin mor-pembe paletine uygun zeminler ve parlak vurgu renkleri
/// kullanılır (vektör, dış görsel yok). Döndürür: çizildiyse true.
bool _paintEslestirmeCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const pink = Color(0xFFFF5BC8);
  const gold = Color(0xFFFFC93C);
  const sky = Color(0xFF1FA2F2);
  const mint = Color(0xFF3BD18F);
  const plum = Color(0xFF4A1A6E);
  const night = Color(0xFF2C0E52);
  final cols = [pink, gold, sky, mint, const Color(0xFFFF7A45), const Color(0xFF9B6CFF)];

  RRect box(Offset o, double w, double h, [double r = 3]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));

  Path hex(Offset o, double r, {double rot = 0}) {
    final p = Path();
    for (var k = 0; k < 6; k++) {
      final a = rot + math.pi / 3 * k;
      final q = o + Offset(math.cos(a) * r, math.sin(a) * r);
      k == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  Path star(Offset o, double r, {int n = 5, double inner = 0.45}) {
    final p = Path();
    for (var i = 0; i < n * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / n;
      final rr = i.isEven ? r : r * inner;
      final q = o + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? p.moveTo(q.dx, q.dy) : p.lineTo(q.dx, q.dy);
    }
    return p..close();
  }

  // Küçük simgeler (taş/kart yüzleri): 0 daire, 1 üçgen, 2 yıldız, 3 kalp, 4 kare, 5 yaprak.
  void glyph(int k, Offset o, double s, Color col) {
    final p = _p(col);
    switch (k % 6) {
      case 0:
        c.drawCircle(o, s * 0.42, p);
      case 1:
        c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy - s * 0.45)
              ..lineTo(o.dx + s * 0.45, o.dy + s * 0.38)
              ..lineTo(o.dx - s * 0.45, o.dy + s * 0.38)
              ..close(),
            p);
      case 2:
        c.drawPath(star(o, s * 0.5), p);
      case 3:
        drawSuit(c, 1, o, s * 0.9, color: col);
      case 4:
        c.drawRRect(box(o, s * 0.72, s * 0.72, s * 0.12), p);
      default:
        c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy - s * 0.48)
              ..quadraticBezierTo(o.dx + s * 0.5, o.dy, o.dx, o.dy + s * 0.48)
              ..quadraticBezierTo(o.dx - s * 0.5, o.dy, o.dx, o.dy - s * 0.48)
              ..close(),
            p);
    }
  }

  // Fildişi taş (mahjong benzeri), yüzünde simge.
  void ivoryTile(Offset o, double w, double h, int g, Color col, {bool lit = false, double depth = 2}) {
    final r = box(o, w, h, w * 0.14);
    c.drawRRect(r.shift(Offset(depth * 0.6, depth)), _p(const Color(0xFF8C7A5E)));
    c.drawRRect(r, _p(lit ? const Color(0xFFFFF3C4) : _ivory));
    c.drawRRect(r, _stroke(lit ? gold : Colors.black.withValues(alpha: 0.18), lit ? 1.4 : 0.6));
    glyph(g, o, w * 0.55, col);
  }

  void sparkle(Offset o, double r, Color col) {
    c.drawPath(star(o, r, n: 4, inner: 0.3), _p(col));
  }

  switch (cover.kind) {
    case 'stacktrayc': // Yığın Eşleştirme: üst üste yığılmış 3B nesneler, altta 7 gözlü tepsi
      _bg(c, seed, tint: const Color(0xFF6A1A8C));
      const heap = [
        [30.0, 44.0, 0], [44.0, 40.0, 1], [58.0, 43.0, 2], [72.0, 46.0, 0], [37.0, 30.0, 3],
        [52.0, 27.0, 1], [66.0, 31.0, 2], [45.0, 16.0, 0], [60.0, 18.0, 3], [24.0, 55.0, 2], [78.0, 57.0, 1],
      ];
      for (final h in heap) {
        final o = Offset(h[0] as double, h[1] as double);
        final k = h[2] as int;
        final col = cols[(k + v) % cols.length];
        switch (k) {
          case 0: // top
            _stone(c, o, 7, col);
          case 1: // küp
            final f = box(o, 12, 12, 2);
            _shadowRRect(c, f, dy: 1.2);
            c.drawRRect(f, _p(col));
            c.drawPath(
                Path()
                  ..moveTo(o.dx - 6, o.dy - 6)
                  ..lineTo(o.dx - 2, o.dy - 9.5)
                  ..lineTo(o.dx + 9.5, o.dy - 9.5)
                  ..lineTo(o.dx + 6, o.dy - 6)
                  ..close(),
                _p(Color.lerp(col, Colors.white, 0.4)!));
          case 2: // koni
            final p = Path()
              ..moveTo(o.dx, o.dy - 9)
              ..lineTo(o.dx + 7, o.dy + 6)
              ..quadraticBezierTo(o.dx, o.dy + 9, o.dx - 7, o.dy + 6)
              ..close();
            c.drawPath(p.shift(const Offset(0, 1.2)), _p(Colors.black26));
            c.drawPath(p, _p(col));
            c.drawLine(o + const Offset(-1.5, -5), o + const Offset(-4, 4), _stroke(Colors.white54, 1.2));
          default: // silindir
            c.drawRRect(box(o, 11, 14, 5), _p(col));
            c.drawOval(Rect.fromCenter(center: o - const Offset(0, 5), width: 11, height: 4.5),
                _p(Color.lerp(col, Colors.white, 0.45)!));
        }
      }
      final tray = RRect.fromRectAndRadius(const Rect.fromLTWH(7, 70, 86, 20), const Radius.circular(8));
      _shadowRRect(c, tray, dy: 2);
      c.drawRRect(tray, _p(night));
      c.drawRRect(tray, _stroke(pink, 1.2));
      for (var i = 0; i < 7; i++) {
        final o = Offset(14.5 + i * 11.8, 80);
        c.drawRRect(box(o, 10, 13, 3), _p(Colors.white.withValues(alpha: 0.12)));
        if (i < 3) _stone(c, o, 4.6, cols[v % cols.length]);
        if (i == 3) c.drawRRect(box(o, 8, 8, 1.5), _p(cols[(1 + v) % cols.length]));
      }
      sparkle(const Offset(24, 64), 4, gold);
    case 'hexmatchc': // Altıgen Eşleştirme: petek tahta, ortada patlayan üçlü
      _bg(c, seed, tint: const Color(0xFF3A1670));
      const r = 8.2;
      for (var row = 0; row < 6; row++) {
        for (var col = 0; col < 6; col++) {
          final o = Offset(15 + col * r * 1.5 + 2, 13 + row * r * 1.732 + (col.isOdd ? r * 0.866 : 0));
          if (o.dy > 96) continue;
          final hot = (row == 2 && col == 2) || (row == 2 && col == 3) || (row == 3 && col == 2);
          final k = hot ? 0 : (row * 5 + col * 3 + v) % 5 + 1;
          final fill = hot ? pink : cols[k % cols.length];
          c.drawPath(hex(o, r - 0.8).shift(const Offset(0, 1)), _p(Colors.black26));
          c.drawPath(hex(o, r - 0.8), _p(fill));
          c.drawPath(hex(o, r - 3.2), _stroke(Colors.white.withValues(alpha: hot ? 0.8 : 0.3), 0.9));
        }
      }
      final burst = Offset(15 + 2.5 * r * 1.5 + 2, 13 + 2.5 * r * 1.732);
      c.drawCircle(burst, 15, _stroke(Colors.white.withValues(alpha: 0.7), 1.6));
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        c.drawLine(burst + Offset(math.cos(a) * 18, math.sin(a) * 18), burst + Offset(math.cos(a) * 24, math.sin(a) * 24),
            _stroke(gold, 2));
      }
    case 'onetc': // Bağlantılı Eşleştirme: iki dönüşlü yolla birleşen aynı taşlar
      _bg(c, seed, tint: const Color(0xFF2E1F6B));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 5; x++) {
          if ((x == 1 && y == 1) || (x == 2 && y == 1) || (x == 3 && y == 1) || (x == 3 && y == 2)) continue;
          final o = Offset(16 + x * 17.0, 22 + y * 19.0);
          final target = (x == 0 && y == 1) || (x == 4 && y == 3);
          ivoryTile(o, 14, 17, target ? 2 : (x * 2 + y * 3 + v) % 6, target ? pink : cols[(x + y * 2 + 1) % cols.length],
              lit: target);
        }
      }
      // İki dönüşlü bağlantı yolu (yalnız yatay ve dikey parçalar)
      final path = Path()
        ..moveTo(23, 41)
        ..lineTo(67, 41)
        ..lineTo(67, 79)
        ..lineTo(77, 79);
      c.drawPath(path, _stroke(Colors.white, 4));
      c.drawPath(path, _stroke(pink, 2.2));
      c.drawCircle(const Offset(67, 41), 2.6, _p(gold));
      c.drawCircle(const Offset(67, 79), 2.6, _p(gold));
    case 'shooterc': // Balon Patlatıcı: tavanda petek balonlar, altta nişan alan atıcı
      _bg(c, seed, tint: const Color(0xFF1B2A6B));
      for (var row = 0; row < 4; row++) {
        final n = row.isEven ? 8 : 7;
        for (var i = 0; i < n; i++) {
          if (row == 3 && i > 3) continue;
          final o = Offset(9 + i * 11.6 + (row.isOdd ? 5.8 : 0), 9 + row * 10.0);
          _stone(c, o, 5.4, cols[(i ~/ 2 + row + v) % 4]);
        }
      }
      // Nişan çizgisi (duvardan sekme)
      final aim = _stroke(Colors.white70, 1.6);
      for (var t = 0.0; t < 1; t += 0.12) {
        final a = Offset.lerp(const Offset(50, 80), const Offset(88, 56), t)!;
        c.drawCircle(a, 0.9, aim);
      }
      for (var t = 0.0; t < 1; t += 0.14) {
        final a = Offset.lerp(const Offset(88, 56), const Offset(66, 42), t)!;
        c.drawCircle(a, 0.9, aim);
      }
      // Atıcı
      c.drawCircle(const Offset(50, 88), 13, _p(night));
      c.drawCircle(const Offset(50, 88), 13, _stroke(pink, 1.6));
      c.save();
      c.translate(50, 86);
      c.rotate(0.55);
      c.drawRRect(box(const Offset(0, -9), 6, 16, 2), _p(const Color(0xFFDADFF0)));
      c.restore();
      _stone(c, const Offset(50, 86), 5.6, cols[(1 + v) % 4]);
      _stone(c, const Offset(30, 90), 4, cols[(2 + v) % 4]);
    case 'stonebubblec': // Taşlı Balonlar: inen tavan, gri taşlar, bomba ve gökkuşağı balonu
      _bg(c, seed, tint: const Color(0xFF243B6E));
      c.drawRect(const Rect.fromLTWH(0, 0, 100, 10), _p(const Color(0xFF6B5B95)));
      for (var i = 0; i < 10; i++) {
        c.drawPath(
            Path()
              ..moveTo(i * 10.0, 10)
              ..lineTo(i * 10.0 + 5, 15)
              ..lineTo(i * 10.0 + 10, 10)
              ..close(),
            _p(const Color(0xFF6B5B95)));
      }
      c.drawLine(const Offset(50, 17), const Offset(50, 23), _stroke(Colors.white70, 1.4));
      c.drawPath(
          Path()
            ..moveTo(46, 21)
            ..lineTo(50, 25)
            ..lineTo(54, 21),
          _stroke(Colors.white70, 1.4));
      for (var row = 0; row < 4; row++) {
        for (var i = 0; i < 7; i++) {
          final o = Offset(14 + i * 12.0 + (row.isOdd ? 6 : 0), 32 + row * 10.5);
          if (o.dx > 92) continue;
          final kind = (row * 7 + i + v) % 9;
          if (kind == 4 || kind == 7) {
            _stone(c, o, 5.6, const Color(0xFF8D93A3)); // taş
            c.drawLine(o + const Offset(-2.5, -1), o + const Offset(1.5, 2), _stroke(Colors.black26, 0.8));
          } else {
            _stone(c, o, 5.6, cols[(kind + row) % 4]);
          }
        }
      }
      // Bomba
      c.drawCircle(const Offset(28, 84), 8, _p(_ink));
      c.drawCircle(const Offset(26, 82), 2.4, _p(Colors.white38));
      c.drawPath(
          Path()
            ..moveTo(33, 78)
            ..quadraticBezierTo(37, 72, 41, 74),
          _stroke(const Color(0xFFC9A26B), 1.6));
      sparkle(const Offset(42, 73), 3.6, gold);
      // Gökkuşağı balonu
      for (var i = 0; i < 4; i++) {
        c.drawArc(Rect.fromCircle(center: const Offset(72, 84), radius: 8), -math.pi / 2 + i * math.pi / 2, math.pi / 2,
            true, _p(cols[i]));
      }
      c.drawCircle(const Offset(72, 84), 8, _stroke(Colors.white70, 1.2));
    case 'samegamec': // Blok Patlatma: büyük aynı renk grubu patlıyor, puan yükseliyor
      _bg(c, seed, tint: const Color(0xFF2A1450));
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 7; x++) {
          final o = Offset(14 + x * 12.0, 22 + y * 11.0);
          final inGroup = (x >= 1 && x <= 3 && y >= 3 && y <= 5) || (x == 4 && y == 5) || (x == 2 && y == 2);
          final col = inGroup ? mint : cols[(x * 7 + y * 3 + v) % 5 == 3 ? 4 : (x * 7 + y * 3 + v) % 5];
          final r = box(o, 11, 10, 2);
          c.drawRRect(r, _p(inGroup ? col.withValues(alpha: 0.95) : col));
          c.drawRRect(r.deflate(2.2), _stroke(Colors.white.withValues(alpha: inGroup ? 0.9 : 0.25), 0.8));
        }
      }
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(19, 50, 50, 34), const Radius.circular(4)),
          _stroke(Colors.white, 1.6));
      for (final s in const [Offset(20, 48), Offset(69, 52), Offset(44, 86)]) {
        sparkle(s, 3.8, Colors.white);
      }
      c.drawRRect(box(const Offset(72, 11), 34, 13, 6), _p(gold));
      _text(c, '+240', const Offset(72, 11), 9, _ink);
    case 'picpairc': // Resim Çiftleri: kapalı kartlar arasında açılmış aynı iki resim
      _bg(c, seed, tint: const Color(0xFF7A2A8C));
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 4; x++) {
          final o = Offset(17 + x * 22.0, 21 + y * 29.0);
          final r = box(o, 18, 25, 3.5);
          _shadowRRect(c, r, dy: 1.6);
          final open = (x == 0 && y == 1) || (x == 3 && y == 0);
          final gone = (x == 2 && y == 2) || (x == 1 && y == 0);
          if (gone) {
            c.drawRRect(r, _stroke(Colors.white24, 1));
            continue;
          }
          if (open) {
            c.drawRRect(r, _p(Colors.white));
            // Güneş resmi
            c.drawCircle(o, 4.6, _p(gold));
            for (var i = 0; i < 8; i++) {
              final a = i * math.pi / 4;
              c.drawLine(o + Offset(math.cos(a) * 6, math.sin(a) * 6), o + Offset(math.cos(a) * 8, math.sin(a) * 8),
                  _stroke(const Color(0xFFFF9F1C), 1.3));
            }
            c.drawRRect(r, _stroke(pink, 1.4));
          } else {
            c.drawRRect(r, _p(plum));
            c.drawRRect(r.deflate(2.5), _stroke(pink.withValues(alpha: 0.6), 0.9));
            c.drawPath(star(o, 4), _p(pink.withValues(alpha: 0.6)));
          }
        }
      }
    case 'domsumc': // Domino Eşleştirme: toplamı 12 eden iki taş
      _bg(c, seed, tint: const Color(0xFF3F1D63));
      void bone(Offset o, int a, int b, double ang, {bool lit = false}) {
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(ang);
        final r = box(Offset.zero, 18, 34, 3.5);
        c.drawRRect(r.shift(const Offset(1, 2)), _p(Colors.black38));
        c.drawRRect(r, _p(lit ? const Color(0xFFFFF7E0) : _ivory));
        if (lit) c.drawRRect(r, _stroke(gold, 1.6));
        c.drawLine(const Offset(-6, 0), const Offset(6, 0), _stroke(Colors.black38, 0.9));
        void pips(int n, double cy) {
          const q = 4.4;
          const map = {
            0: <(int, int)>[],
            1: [(0, 0)],
            2: [(-1, -1), (1, 1)],
            3: [(-1, -1), (0, 0), (1, 1)],
            4: [(-1, -1), (1, -1), (-1, 1), (1, 1)],
            5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)],
            6: [(-1, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (1, 1)],
          };
          for (final (x, y) in map[n]!) {
            c.drawCircle(Offset(x * q, cy + y * q), 1.5, _p(_ink));
          }
        }

        pips(a, -8.5);
        pips(b, 8.5);
        c.restore();
      }

      bone(const Offset(16, 30), 1, 2, -0.3);
      bone(const Offset(84, 28), 0, 3, 0.35);
      bone(const Offset(36, 54), 6, 2, 0, lit: true);
      bone(const Offset(62, 54), 3, 1, 0, lit: true);
      c.drawCircle(const Offset(49, 54), 4, _p(Colors.white));
      _text(c, '+', const Offset(49, 54), 8, plum);
      c.drawRRect(box(const Offset(50, 86), 36, 14, 7), _p(gold));
      _text(c, '= 12', const Offset(50, 86), 10, _ink);
    case 'hiddenc': // Gizli Nesne: kalabalık sahne, bulunacak nesneler şeridi
      _bg(c, seed, tint: const Color(0xFF34224F));
      // Sahne: raf ve dağınık siluetler
      c.drawRect(const Rect.fromLTWH(6, 44, 88, 3), _p(_woodLight));
      for (var i = 0; i < 14; i++) {
        final o = Offset(10 + (i * 37 % 80).toDouble(), 14 + (i * 23 % 52).toDouble());
        glyph(i, o, 9, Colors.white.withValues(alpha: 0.18 + (i % 3) * 0.08));
      }
      // Anahtar (aranan nesne) bulunmuş, halkayla işaretli
      void key(Offset o, double s, Color col) {
        c.drawCircle(o, s * 0.3, _stroke(col, s * 0.12));
        c.drawLine(o + Offset(s * 0.3, 0), o + Offset(s * 1.1, 0), _stroke(col, s * 0.12));
        c.drawLine(o + Offset(s * 0.85, 0), o + Offset(s * 0.85, s * 0.25), _stroke(col, s * 0.12));
        c.drawLine(o + Offset(s * 1.05, 0), o + Offset(s * 1.05, s * 0.2), _stroke(col, s * 0.12));
      }

      key(const Offset(58, 30), 14, gold);
      c.drawOval(Rect.fromCenter(center: const Offset(65, 31), width: 30, height: 18), _stroke(pink, 2));
      // Liste şeridi
      final strip = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 72, 88, 22), const Radius.circular(6));
      c.drawRRect(strip, _p(Colors.white.withValues(alpha: 0.92)));
      key(const Offset(16, 83), 9, const Color(0xFFB8860B));
      c.drawLine(const Offset(10, 83), const Offset(29, 83), _stroke(mint, 1.8));
      glyph(0, const Offset(43, 83), 10, sky);
      glyph(2, const Offset(60, 83), 10, pink);
      glyph(5, const Offset(77, 83), 10, mint);
      for (final x in [36.0, 53.0, 70.0]) {
        c.drawLine(Offset(x, 75), Offset(x, 91), _stroke(Colors.black12, 0.8));
      }
    case 'goalpopc': // Grup Patlatma: hedef sayaçları ve fitili yanan bomba
      _bg(c, seed, tint: const Color(0xFF51207A));
      final bar = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 6, 88, 18), const Radius.circular(9));
      c.drawRRect(bar, _p(night));
      for (var i = 0; i < 3; i++) {
        final o = Offset(20 + i * 26.0, 15);
        c.drawRRect(box(o, 9, 9, 2), _p(cols[i]));
        _text(c, '${(3 - i) * 4 + v}', o + const Offset(10, 0), 7, Colors.white);
      }
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 6; x++) {
          final o = Offset(17 + x * 13.2, 36 + y * 12.4);
          final k = (x * 5 + y * 4 + v) % 4;
          final r = box(o, 11.5, 11, 3);
          c.drawRRect(r.shift(const Offset(0, 1)), _p(Colors.black26));
          c.drawRRect(r, _p(cols[k]));
          c.drawCircle(o + const Offset(-2.5, -2.5), 1.6, _p(Colors.white54));
        }
      }
      // Bomba (blok yerine)
      c.drawCircle(const Offset(56.6, 60.8), 7.5, _p(_ink));
      c.drawCircle(const Offset(54.4, 58.4), 2, _p(Colors.white38));
      c.drawPath(
          Path()
            ..moveTo(61, 55)
            ..quadraticBezierTo(64, 49, 68, 50),
          _stroke(const Color(0xFFC9A26B), 1.6));
      sparkle(const Offset(69, 49), 4.2, gold);
    case 'cratec': // İçecek Kasaları: şişelerle dolan kasalar ve sevkiyat oku
      _bg(c, seed, tint: const Color(0xFF14365E));
      void bottle(Offset o, Color col) {
        c.drawRRect(box(o + const Offset(0, 3), 6, 13, 2), _p(col));
        c.drawRect(Rect.fromCenter(center: o + const Offset(0, -5.5), width: 2.6, height: 5), _p(col));
        c.drawRect(Rect.fromCenter(center: o + const Offset(0, -8.4), width: 3.4, height: 1.6), _p(Colors.white70));
        c.drawRect(Rect.fromCenter(center: o + const Offset(0, 3), width: 6, height: 3.4), _p(Colors.white60));
      }

      void crate(Rect r, List<Color> bs, {bool done = false}) {
        final rr = RRect.fromRectAndRadius(r, const Radius.circular(2.5));
        _shadowRRect(c, rr, dy: 1.6);
        c.drawRRect(rr, _p(done ? const Color(0xFFE29B3F) : const Color(0xFFB9783A)));
        for (var i = 0; i < bs.length; i++) {
          bottle(Offset(r.left + 6 + i * 8.0, r.top - 1), bs[i]);
        }
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top + 4, r.width, r.height - 4), const Radius.circular(2.5)),
            _p(done ? const Color(0xFFF0B45A) : const Color(0xFFC98A45)));
        c.drawLine(Offset(r.left + 3, r.top + 8), Offset(r.right - 3, r.top + 8), _stroke(Colors.black26, 0.9));
      }

      crate(const Rect.fromLTWH(8, 30, 34, 14), [pink, sky, pink, gold]);
      crate(const Rect.fromLTWH(54, 30, 34, 14), [sky, mint, sky]);
      crate(const Rect.fromLTWH(8, 66, 34, 14), [mint, gold]);
      crate(const Rect.fromLTWH(54, 66, 34, 14), [pink, pink, pink, pink], done: true);
      // Sevkiyat oku ve onay
      c.drawPath(
          Path()
            ..moveTo(60, 92)
            ..lineTo(86, 92)
            ..lineTo(86, 88)
            ..lineTo(94, 94)
            ..lineTo(86, 100)
            ..lineTo(86, 96)
            ..lineTo(60, 96)
            ..close(),
          _p(mint));
      c.drawCircle(const Offset(90, 60), 6, _p(mint));
      c.drawPath(
          Path()
            ..moveTo(87, 60)
            ..lineTo(89.5, 62.5)
            ..lineTo(93.5, 57.5),
          _stroke(Colors.white, 1.6));
    case 'yarnc': // Yün Sıralama: çubuklara dizilmiş yün yumakları
      _bg(c, seed, tint: const Color(0xFF5C2A6E));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 84, 84, 8), const Radius.circular(3)), _p(_wood));
      void yarn(Offset o, double r, Color col) {
        c.drawCircle(o + const Offset(0, 1.2), r, _p(Colors.black26));
        c.drawCircle(o, r, _p(col));
        final s = _stroke(Color.lerp(col, Colors.white, 0.45)!, 0.9);
        for (var k = -1; k <= 1; k++) {
          c.drawArc(Rect.fromCircle(center: o + Offset(k * r * 0.35, 0), radius: r * 0.85), -1.1, 2.2, false, s);
        }
      }

      const stacks = [
        [0, 1, 0],
        [1, 1, 1, 1],
        [2, 0, 2],
        [3, 2],
      ];
      for (var i = 0; i < 4; i++) {
        final x = 20.0 + i * 20;
        c.drawLine(Offset(x, 30), Offset(x, 86), _stroke(const Color(0xFFE6D5B8), 2.4));
        for (var j = 0; j < stacks[i].length; j++) {
          yarn(Offset(x, 78 - j * 12.5), 7.2, cols[(stacks[i][j] + v) % 4]);
        }
      }
      // Kopan iplik ucu ve parıltı
      c.drawPath(
          Path()
            ..moveTo(47, 30)
            ..quadraticBezierTo(56, 18, 66, 24)
            ..quadraticBezierTo(74, 30, 84, 16),
          _stroke(cols[(1 + v) % 4], 1.4));
      sparkle(const Offset(40, 22), 4, gold);
    case 'symcolc': // Kart Sıralama: sütunlara dizilmiş simgeli kartlar, biri tamam
      _bg(c, seed, tint: const Color(0xFF1F4A5C));
      const colsDef = [
        [0, 2, 1, 0],
        [1, 1, 1, 1],
        [2, 0, 2],
        [3, 1],
      ];
      for (var i = 0; i < 4; i++) {
        final x = 17.0 + i * 22;
        c.drawRRect(box(Offset(x, 56), 19, 74, 4), _p(Colors.white.withValues(alpha: 0.08)));
        for (var j = 0; j < colsDef[i].length; j++) {
          final o = Offset(x, 26 + j * 13.0);
          final done = i == 1;
          final r = box(o, 17, 22, 2.5);
          _shadowRRect(c, r, dy: 1.2, a: 0.22);
          c.drawRRect(r, _p(done ? const Color(0xFFFFF3C4) : Colors.white));
          c.drawRRect(r, _stroke(done ? gold : Colors.black12, done ? 1.2 : 0.6));
          glyph(colsDef[i][j], o + const Offset(0, -4), 7, cols[(colsDef[i][j] + v) % cols.length]);
        }
      }
      c.drawCircle(const Offset(39, 90), 5.5, _p(mint));
      c.drawPath(
          Path()
            ..moveTo(36.5, 90)
            ..lineTo(38.6, 92.2)
            ..lineTo(42, 87.8),
          _stroke(Colors.white, 1.5));
    case 'layoutsc': // Mahjong dizilim çeşitleri: kelebek dizilimi ve öbür dizilimlerin izleri
      _bg(c, seed, tint: const Color(0xFF1E5B4B));
      // Arka planda diğer dizilimlerin kesik çizgili silüetleri
      final dash = _stroke(Colors.white.withValues(alpha: 0.28), 1.1);
      c.drawPath(hex(const Offset(20, 20), 11, rot: math.pi / 6), dash);
      c.drawCircle(const Offset(82, 18), 10, dash);
      c.drawPath(
          Path()
            ..moveTo(10, 92)
            ..lineTo(22, 80)
            ..lineTo(34, 92)
            ..close(),
          dash);
      c.drawRect(const Rect.fromLTWH(70, 80, 22, 13), dash);
      // Kelebek dizilimi: iki kanat, gövde
      const wing = [
        [-3, -1], [-2, -1], [-3, 0], [-2, 0], [-1, 0], [-3, 1], [-2, 1],
      ];
      for (final side in [-1, 1]) {
        for (final w in wing) {
          final o = Offset(50 + side * (w[0].abs() * 9.0), 52 + w[1] * 13.0);
          ivoryTile(o, 8.5, 12, (w[0] + w[1] + 3 + v) % 6, cols[(w[0] + 5) % cols.length], depth: 1.4);
        }
      }
      for (var i = -1; i <= 1; i++) {
        ivoryTile(Offset(50, 52 + i * 13.0), 8.5, 12, 2, pink, lit: i == 0, depth: 1.4);
      }
      ivoryTile(const Offset(50, 46), 8.5, 12, 2, pink, depth: 1.4);
    case 'turtlec': // Mahjong Solitaire: üç katlı kule, serbest çift parlıyor
      _bg(c, seed, tint: const Color(0xFF14543F));
      const tw = 11.0, th = 14.5;
      for (var layer = 0; layer < 3; layer++) {
        final n = 6 - layer * 2;
        final rows = 4 - layer;
        for (var y = 0; y < rows; y++) {
          for (var x = 0; x < n; x++) {
            final o = Offset(50 - (n - 1) * tw / 2 + x * tw - layer * 1.6, 62 - (rows - 1) * th / 2 + y * th - layer * 2.4);
            final free = layer == 2 && y == 0 && x == 0;
            ivoryTile(o, tw - 0.8, th - 0.8, (x * 3 + y * 2 + layer + v) % 6, cols[(x + y + layer) % cols.length],
                lit: free, depth: 1.6);
          }
        }
      }
      // Kenarda serbest eş taş
      ivoryTile(const Offset(85, 30), 10.2, 13.7, (0 + 0 + 2 + v) % 6, cols[2 % cols.length], lit: true);
      c.drawLine(const Offset(48, 46), const Offset(79, 32), _stroke(gold.withValues(alpha: 0.8), 1.2));
    case 'gemswapc': // Mücevher Değiştir: yer değiştiren iki taş ve akan süre
      _bg(c, seed, tint: const Color(0xFF2A1858));
      void gem(Offset o, int k, double s) {
        final col = cols[k % cols.length];
        final p = k % 3 == 0
            ? hex(o, s * 0.55)
            : k % 3 == 1
                ? (Path()
                  ..moveTo(o.dx, o.dy - s * 0.55)
                  ..lineTo(o.dx + s * 0.5, o.dy)
                  ..lineTo(o.dx, o.dy + s * 0.55)
                  ..lineTo(o.dx - s * 0.5, o.dy)
                  ..close())
                : (Path()..addOval(Rect.fromCenter(center: o, width: s, height: s * 0.9)));
        c.drawPath(p.shift(const Offset(0, 1)), _p(Colors.black26));
        c.drawPath(p, _p(col));
        c.drawCircle(o + Offset(-s * 0.14, -s * 0.16), s * 0.1, _p(Colors.white70));
      }

      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          final o = Offset(18 + x * 16.0, 30 + y * 14.0);
          if ((x == 1 || x == 2) && y == 2) continue;
          gem(o, (x * 2 + y * 3 + v) % 6, 11);
        }
      }
      // Değişen ikili ve oklar
      gem(const Offset(31, 58), 4, 13);
      gem(const Offset(53, 58), 1, 13);
      final arr = _stroke(Colors.white, 1.6);
      c.drawArc(Rect.fromCenter(center: const Offset(42, 58), width: 20, height: 14), math.pi * 1.1, math.pi * 0.8, false, arr);
      c.drawArc(Rect.fromCenter(center: const Offset(42, 58), width: 20, height: 14), math.pi * 0.1, math.pi * 0.8, false, arr);
      // Süre çubuğu ve kronometre
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(22, 9, 70, 8), const Radius.circular(4)), _p(Colors.white24));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(22, 9, 70 * (0.62 - v % 3 * 0.1), 8), const Radius.circular(4)),
          _p(gold));
      c.drawCircle(const Offset(13, 13), 7, _p(Colors.white));
      c.drawCircle(const Offset(13, 13), 7, _stroke(pink, 1.4));
      c.drawLine(const Offset(13, 13), const Offset(13, 8.5), _stroke(_ink, 1.2));
      c.drawLine(const Offset(13, 13), const Offset(16, 14.5), _stroke(_ink, 1.2));
    case 'symbolcardc': // Ortak Sembol: iki yuvarlak kart, tek ortak simge bağlı
      _bg(c, seed, tint: const Color(0xFF61237E));
      void disc(Offset o, List<int> gs, int common, Offset cpos) {
        c.drawCircle(o + const Offset(0, 1.8), 26, _p(Colors.black26));
        c.drawCircle(o, 26, _p(Colors.white));
        c.drawCircle(o, 26, _stroke(pink, 1.4));
        for (var i = 0; i < gs.length; i++) {
          final a = i * 2 * math.pi / gs.length + 0.4;
          glyph(gs[i], o + Offset(math.cos(a) * 15, math.sin(a) * 15), 9, cols[(gs[i] + 1) % cols.length]);
        }
        c.drawCircle(o + cpos, 7, _p(gold.withValues(alpha: 0.35)));
        glyph(common, o + cpos, 10, pink);
      }

      disc(const Offset(30, 38), [0, 4, 1, 5], 2, Offset.zero);
      disc(const Offset(70, 64), [3, 1, 4, 0], 2, Offset.zero);
      c.drawLine(const Offset(36, 44), const Offset(64, 58), _stroke(gold, 2));
    case 'floodc': // Renk Doldurma: köşeden yayılan renk, altta renk düğmeleri
      _bg(c, seed, tint: const Color(0xFF231446));
      for (var y = 0; y < 6; y++) {
        for (var x = 0; x < 6; x++) {
          final flooded = x + y < 4 || (x == 4 && y == 0) || (x == 0 && y == 4);
          final col = flooded ? cols[(2 + v) % 4] : cols[(x * 5 + y * 7 + v) % 4];
          c.drawRect(Rect.fromLTWH(14 + x * 12.0, 8 + y * 11.0, 12.2, 11.2), _p(col));
        }
      }
      c.drawRect(const Rect.fromLTWH(14, 8, 72, 66), _stroke(Colors.white, 1.2));
      // Yayılma dalgası
      c.drawArc(Rect.fromCircle(center: const Offset(14, 8), radius: 44), 0, math.pi / 2, false,
          _stroke(Colors.white.withValues(alpha: 0.75), 1.6));
      for (var i = 0; i < 4; i++) {
        final o = Offset(20 + i * 15.0, 88);
        c.drawCircle(o, 6, _p(cols[i]));
        if (i == (2 + v) % 4) c.drawCircle(o, 7.8, _stroke(Colors.white, 1.6));
      }
      c.drawRRect(box(const Offset(86, 88), 16, 12, 4), _p(Colors.white));
      _text(c, '${12 - v % 3}', const Offset(86, 88), 8, _ink);
    case 'bigtilec': // Büyük Taş Çıkarma: iri taşlar, ay ve sakin dalgalar
      _bg(c, seed, tint: const Color(0xFF2D3F6E));
      c.drawCircle(const Offset(80, 18), 9, _p(const Color(0xFFFFF1B8)));
      c.drawCircle(const Offset(84, 15), 8, _p(const Color(0xFF2D3F6E)));
      final wave = _stroke(Colors.white.withValues(alpha: 0.18), 1.6);
      for (var i = 0; i < 3; i++) {
        final y = 86.0 + i * 5;
        c.drawPath(
            Path()
              ..moveTo(0, y)
              ..quadraticBezierTo(12, y - 4, 25, y)
              ..quadraticBezierTo(38, y + 4, 50, y)
              ..quadraticBezierTo(62, y - 4, 75, y)
              ..quadraticBezierTo(88, y + 4, 100, y),
            wave);
      }
      ivoryTile(const Offset(28, 40), 24, 31, 5, mint, depth: 3);
      ivoryTile(const Offset(54, 44), 24, 31, 3, pink, depth: 3);
      ivoryTile(const Offset(41, 64), 24, 31, 5, mint, lit: true, depth: 3);
    case 'tiletrayc': // Taş Eşleştirme: dağınık yassı taşlar, altta tek sıra raf ve üçlü
      _bg(c, seed, tint: const Color(0xFF4B1F6F));
      const spots = [
        [18.0, 20.0, 0], [34.0, 16.0, 3], [50.0, 22.0, 1], [66.0, 15.0, 4], [82.0, 21.0, 0],
        [26.0, 38.0, 5], [44.0, 40.0, 3], [60.0, 36.0, 1], [76.0, 40.0, 2], [36.0, 56.0, 4], [56.0, 56.0, 0],
      ];
      for (final s in spots) {
        final k = s[2] as int;
        ivoryTile(Offset(s[0] as double, s[1] as double), 13, 15, k, cols[(k + v) % cols.length]);
      }
      final rack = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 72, 88, 20), const Radius.circular(3));
      c.drawRRect(rack, _p(_wood));
      c.drawRRect(rack, _stroke(_woodLight, 1.2));
      for (var i = 0; i < 6; i++) {
        final o = Offset(15 + i * 14.0, 82);
        if (i < 3) {
          ivoryTile(o, 11, 14, 2, cols[(2 + v) % cols.length], lit: true, depth: 1.2);
        } else if (i == 3) {
          ivoryTile(o, 11, 14, 4, cols[(4 + v) % cols.length], depth: 1.2);
        } else {
          c.drawRRect(box(o, 11, 14, 2), _stroke(Colors.white24, 0.9));
        }
      }
      sparkle(const Offset(29, 68), 3.6, gold);
    case 'mergetreec': // Üçlü Birleştirme: üç tohum → fidan → ağaç
      _bg(c, seed, tint: const Color(0xFF2F5E3A));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          c.drawRRect(box(Offset(20 + x * 20.0, 22 + y * 20.0), 18, 18, 3),
              _p((x + y).isEven ? const Color(0xFF7BC67E) : const Color(0xFF6AB46D)));
        }
      }
      void seedDot(Offset o) => c.drawOval(Rect.fromCenter(center: o, width: 5, height: 7), _p(const Color(0xFF8A5A36)));
      void sapling(Offset o) {
        c.drawLine(o + const Offset(0, 6), o + const Offset(0, -3), _stroke(const Color(0xFF2E7D32), 1.6));
        c.drawOval(Rect.fromCenter(center: o + const Offset(-3, -3), width: 6, height: 4), _p(const Color(0xFF43A047)));
        c.drawOval(Rect.fromCenter(center: o + const Offset(3, -5), width: 6, height: 4), _p(const Color(0xFF43A047)));
      }

      seedDot(const Offset(20, 22));
      seedDot(const Offset(40, 22));
      seedDot(const Offset(20, 42));
      sapling(const Offset(60, 42));
      sapling(const Offset(60, 62));
      sapling(const Offset(80, 62));
      // Büyük ağaç (birleşme sonucu)
      c.drawRect(const Rect.fromLTWH(37, 72, 6, 16), _p(const Color(0xFF6D4C41)));
      c.drawCircle(const Offset(40, 66), 12, _p(const Color(0xFF2E7D32)));
      c.drawCircle(const Offset(33, 70), 8, _p(const Color(0xFF388E3C)));
      c.drawCircle(const Offset(47, 70), 8, _p(const Color(0xFF388E3C)));
      c.drawCircle(const Offset(44, 62), 2, _p(pink));
      final arr = _stroke(Colors.white, 1.6);
      c.drawLine(const Offset(46, 28), const Offset(54, 36), arr);
      c.drawLine(const Offset(70, 70), const Offset(52, 74), arr);
      sparkle(const Offset(56, 54), 4, gold);
    default:
      return false;
  }
  return true;
}
