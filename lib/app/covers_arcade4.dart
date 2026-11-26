part of 'covers.dart';

/// 4. tur Arcade kapakları (vektör, dış görsel yok): Tepe Tırmanışı,
/// Uçurtma Savaşı, Kriket Vuruşu, Kalabalık Koşusu, Badminton, Kabaddi
/// Baskını. Döndürür: çizildiyse true.
bool _paintArcade4Cover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  switch (cover.kind) {
    case 'hillclimb':
      _bg(c, seed, tint: const Color(0xFFFF9F68));
      c.drawCircle(const Offset(78, 22), 10, _p(const Color(0xFFFFE8A3)));
      final far = Path()..moveTo(0, 70);
      for (var x = 0.0; x <= 100; x += 5) {
        far.lineTo(x, 62 + math.sin(x / 9 + v) * 6);
      }
      far
        ..lineTo(100, 100)
        ..lineTo(0, 100)
        ..close();
      c.drawPath(far, _p(const Color(0xFFB5838D).withValues(alpha: 0.7)));
      final hill = Path()..moveTo(0, 100);
      double hy(double x) => 78 - 26 * math.exp(-math.pow((x - 52) / 22, 2)) + math.sin(x / 6) * 1.5;
      for (var x = 0.0; x <= 100; x += 2) {
        hill.lineTo(x, hy(x));
      }
      hill
        ..lineTo(100, 100)
        ..close();
      c.drawPath(hill, _p(const Color(0xFF7F5539)));
      c.drawPath(hill, _stroke(const Color(0xFF90BE6D), 3));
      // Cip, yokuşta eğik
      c.save();
      c.translate(36, hy(36) - 9);
      c.rotate(-0.42);
      final body = RRect.fromRectAndRadius(const Rect.fromLTWH(-16, -9, 32, 11), const Radius.circular(3));
      _shadowRRect(c, body);
      c.drawRRect(body, _p(_pal[v % 8]));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -16, 14, 8), const Radius.circular(2)), _p(const Color(0xFFCAF0F8)));
      for (final x in [-9.0, 10.0]) {
        c.drawCircle(Offset(x, 3), 6, _p(const Color(0xFF212529)));
        c.drawCircle(Offset(x, 3), 2.4, _p(const Color(0xFFADB5BD)));
      }
      c.restore();
      // Yakıt bidonu
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(70, hy(74) - 13, 9, 12), const Radius.circular(2)), _p(const Color(0xFFE63946)));
      _text(c, 'F', Offset(74.5, hy(74) - 7), 7, Colors.white);
      return true;
    case 'kitefight':
      _bg(c, seed, tint: const Color(0xFF48CAE4));
      for (var i = 0; i < 3; i++) {
        final x = 14.0 + i * 30, y = 18.0 + (i * 13 + v * 7) % 20;
        c.drawCircle(Offset(x, y), 6, _p(Colors.white.withValues(alpha: 0.5)));
        c.drawCircle(Offset(x + 7, y - 2), 7, _p(Colors.white.withValues(alpha: 0.5)));
      }
      c.drawRect(const Rect.fromLTWH(0, 86, 100, 14), _p(const Color(0xFFB08968)));
      c.drawRect(const Rect.fromLTWH(0, 84, 100, 3), _p(const Color(0xFF7F5539)));
      void kite(Offset o, Color col, double rot) {
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(rot);
        final d = Path()
          ..moveTo(0, -11)
          ..lineTo(9, 0)
          ..lineTo(0, 11)
          ..lineTo(-9, 0)
          ..close();
        c.drawPath(d.shift(const Offset(1.2, 1.6)), _p(Colors.black26));
        c.drawPath(d, _p(col));
        c.drawLine(const Offset(0, -11), const Offset(0, 11), _stroke(Colors.white70, 0.8));
        c.drawLine(const Offset(-9, 0), const Offset(9, 0), _stroke(Colors.white70, 0.8));
        final tail = Path()..moveTo(0, 11);
        for (var i = 1; i <= 4; i++) {
          tail.lineTo((i.isOdd ? 3 : -3).toDouble(), 11.0 + i * 5);
        }
        c.drawPath(tail, _stroke(col, 1.2));
        c.restore();
      }
      final a = const Offset(62, 30), b = const Offset(38, 34);
      // İpler kesişiyor
      c.drawLine(const Offset(16, 86), a, _stroke(Colors.white, 1.1));
      c.drawLine(const Offset(84, 86), b, _stroke(const Color(0xFF1D3557), 1.1));
      kite(a, _pal[(v + 0) % 8], 0.25);
      kite(b, _pal[(v + 3) % 8], -0.3);
      // Sürtünme kıvılcımı
      for (var i = 0; i < 6; i++) {
        final ang = i * math.pi / 3;
        c.drawLine(Offset(50 + math.cos(ang) * 2, 60 + math.sin(ang) * 2), Offset(50 + math.cos(ang) * 6, 60 + math.sin(ang) * 6),
            _stroke(const Color(0xFFFFB703), 1.4));
      }
      return true;
    case 'cricketbat':
      _bg(c, seed, tint: const Color(0xFF2D6A4F));
      c.drawOval(const Rect.fromLTWH(-20, 50, 140, 80), _p(const Color(0xFF52B788).withValues(alpha: 0.6)));
      final pitch = Path()
        ..moveTo(44, 30)
        ..lineTo(56, 30)
        ..lineTo(66, 96)
        ..lineTo(34, 96)
        ..close();
      c.drawPath(pitch, _p(const Color(0xFFD4A373)));
      // Kale
      for (final x in [45.0, 50.0, 55.0]) {
        c.drawLine(Offset(x, 86), Offset(x, 70), _stroke(const Color(0xFFFFF3B0), 1.8));
      }
      c.drawLine(const Offset(44, 70), const Offset(56, 70), _stroke(const Color(0xFFFFF3B0), 1.2));
      // Sopa (çapraz)
      c.save();
      c.translate(30, 64);
      c.rotate(-0.8 + (v % 3) * 0.12);
      final blade = RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 8, 30), const Radius.circular(2));
      _shadowRRect(c, blade);
      c.drawRRect(blade, _p(const Color(0xFFDDB892)));
      c.drawLine(const Offset(0, -10), const Offset(0, 1), _stroke(const Color(0xFF343A40), 3));
      c.restore();
      // Top ve hız izi
      c.drawLine(const Offset(70, 30), const Offset(80, 22), _stroke(Colors.white38, 2));
      c.drawCircle(const Offset(66, 34), 5.5, _p(const Color(0xFFC1121F)));
      c.drawArc(Rect.fromCircle(center: const Offset(66, 34), radius: 3.6), -0.6, 1.4, false, _stroke(Colors.white70, 0.8));
      _text(c, v.isEven ? '6' : '4', const Offset(82, 14), 14, const Color(0xFFFFD60A));
      return true;
    case 'crowdgates':
      _bg(c, seed, tint: const Color(0xFF95D5B2));
      c.drawRect(const Rect.fromLTWH(18, 0, 64, 100), _p(const Color(0xFF5C677D)));
      // Kapılar
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 24, 29, 14), const Radius.circular(3)), _p(const Color(0xFF00B4D8).withValues(alpha: 0.85)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(51, 24, 29, 14), const Radius.circular(3)), _p(const Color(0xFFE63946).withValues(alpha: 0.85)));
      _text(c, v.isEven ? '×2' : '+10', const Offset(34.5, 31), 9, Colors.white);
      _text(c, v.isEven ? '−5' : '÷2', const Offset(65.5, 31), 9, Colors.white);
      // Kalabalık
      const ga = 2.399963;
      for (var i = 0; i < 26; i++) {
        final r = 3.2 * math.sqrt(i + 0.5);
        final o = Offset(38 + math.cos(i * ga) * r, 74 + math.sin(i * ga) * r * 0.75);
        c.drawCircle(o + const Offset(0.6, 1), 2.6, _p(Colors.black26));
        c.drawCircle(o, 2.6, _p(_pal[(v + 1) % 8]));
      }
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(28, 50, 20, 10), const Radius.circular(5)), _p(const Color(0xFF1D4E89)));
      _text(c, '26', const Offset(38, 55), 7, Colors.white);
      // Rakip kule
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(60, 52, 16, 30), const Radius.circular(3)), _p(const Color(0xFFD62828)));
      for (var y = 56.0; y < 80; y += 6) {
        c.drawCircle(Offset(64, y), 1.6, _p(Colors.white24));
        c.drawCircle(Offset(72, y), 1.6, _p(Colors.white24));
      }
      return true;
    case 'shuttlecourt':
      _bg(c, seed, tint: const Color(0xFF3A5A40));
      final court = RRect.fromRectAndRadius(const Rect.fromLTWH(24, 8, 52, 84), const Radius.circular(1));
      c.drawRRect(court, _p(const Color(0xFF2D6A4F)));
      c.drawRRect(court, _stroke(Colors.white, 1.2));
      c.drawLine(const Offset(24, 38), const Offset(76, 38), _stroke(Colors.white70, 0.8));
      c.drawLine(const Offset(24, 62), const Offset(76, 62), _stroke(Colors.white70, 0.8));
      c.drawLine(const Offset(50, 8), const Offset(50, 38), _stroke(Colors.white70, 0.8));
      c.drawLine(const Offset(50, 62), const Offset(50, 92), _stroke(Colors.white70, 0.8));
      c.drawRect(const Rect.fromLTWH(18, 48.5, 64, 3), _p(const Color(0xFFF1FAEE)));
      // Tüy top (çapraz yükselen)
      c.save();
      c.translate(60, 30);
      c.rotate(-0.7 + (v % 3) * 0.15);
      final skirt = Path()
        ..moveTo(0, -2)
        ..lineTo(-12, -7)
        ..lineTo(-12, 7)
        ..lineTo(0, 2)
        ..close();
      c.drawPath(skirt, _p(Colors.white));
      c.drawPath(skirt, _stroke(Colors.black26, 0.6));
      c.drawCircle(Offset.zero, 3, _p(const Color(0xFFFFB703)));
      c.restore();
      c.drawOval(const Rect.fromLTWH(54, 40, 10, 4), _p(Colors.black26));
      // Raket
      c.save();
      c.translate(36, 76);
      c.rotate(0.5);
      c.drawLine(Offset.zero, const Offset(0, 14), _stroke(const Color(0xFF343A40), 2));
      c.drawOval(const Rect.fromLTWH(-6, -16, 12, 16), _stroke(_pal[v % 8], 2));
      c.restore();
      return true;
    case 'kabaddiraid':
      _bg(c, seed, tint: const Color(0xFF264653));
      c.drawRect(const Rect.fromLTWH(10, 10, 80, 40), _p(const Color(0xFFE76F51)));
      c.drawRect(const Rect.fromLTWH(10, 50, 80, 40), _p(const Color(0xFF2A9D8F)));
      c.drawRect(const Rect.fromLTWH(10, 10, 80, 80), _stroke(Colors.white, 1.2));
      c.drawLine(const Offset(10, 50), const Offset(90, 50), _stroke(Colors.white, 2.4));
      c.drawLine(const Offset(10, 41), const Offset(90, 41), _stroke(Colors.white70, 0.8));
      for (var x = 12.0; x < 90; x += 8) {
        c.drawLine(Offset(x, 26), Offset(x + 4, 26), _stroke(const Color(0xFFFFD60A), 0.9));
      }
      // Savunma yayı
      for (var i = 0; i < 5; i++) {
        final a = math.pi * (0.15 + 0.7 * i / 4);
        final o = Offset(50 - math.cos(a) * 30, 18 + math.sin(a) * 12);
        c.drawCircle(o + const Offset(0.6, 1), 4, _p(Colors.black26));
        c.drawCircle(o, 4, _p(_pal[(v + 3) % 8]));
      }
      // Akıncı: uzanan el ve hareket izi
      c.drawLine(const Offset(58, 58), const Offset(62, 70), _stroke(Colors.white38, 1.4));
      c.drawLine(const Offset(52, 58), const Offset(54, 70), _stroke(Colors.white38, 1.4));
      c.drawCircle(const Offset(56, 44), 5, _p(_pal[v % 8]));
      c.drawLine(const Offset(56, 44), const Offset(64, 36), _stroke(const Color(0xFFE0AC69), 1.8));
      c.drawCircle(const Offset(64.5, 35.5), 2.2, _p(const Color(0xFFFFD60A)));
      return true;
  }
  return false;
}
