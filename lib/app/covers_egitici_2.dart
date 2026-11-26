part of 'covers.dart';

/// Eğitici ve Çocuk ikinci kapak dosyası. Türler:
/// geosolidc: Geometri Şekilleri, üç cisim (küp, koni, silindir), kesikli
/// arka kenarlar, köşe noktaları ve cetvel. Aynı merkezdeki 'shapec' (düz
/// renkli daire, kare, üçgen) kapağından bilerek farklı.
bool _paintEgitici2Cover(Canvas c, GameCover cover, Color seed) {
  if (cover.kind != 'geosolidc') return false;
  final v = cover.v;
  const ink = Color(0xFF3D405B);
  const kid = [Color(0xFFE76F51), Color(0xFF2A9D8F), Color(0xFFE9C46A), Color(0xFF457B9D)];
  Color tone(int i, double l) => HSLColor.fromColor(kid[(i + v) % kid.length]).withLightness(l).toColor();

  // Kareli defter zemini
  _bg(c, seed, tint: const Color(0xFFDCEBF5));
  final grid = _stroke(const Color(0xFF9EC3DB).withValues(alpha: 0.55), 0.6);
  for (var k = 8.0; k < 100; k += 8) {
    c.drawLine(Offset(k, 0), Offset(k, 100), grid);
    c.drawLine(Offset(0, k), Offset(100, k), grid);
  }

  // Küp (eğik izdüşüm): ön yüz, üst yüz, yan yüz, arka kenarlar kesikli.
  const f0 = Offset(10, 40), f1 = Offset(36, 40), f2 = Offset(36, 66), f3 = Offset(10, 66);
  const d = Offset(11, -10);
  c.drawPath(Path()..addPolygon(const [f0, f1, Offset(47, 30), Offset(21, 30)], true), _p(tone(0, 0.72)));
  c.drawPath(Path()..addPolygon(const [f1, Offset(47, 30), Offset(47, 56), f2], true), _p(tone(0, 0.5)));
  c.drawRect(Rect.fromPoints(f0, f2), _p(tone(0, 0.62)));
  final edge = _stroke(ink, 1.6);
  c.drawPath(
      Path()
        ..addPolygon(const [f0, f1, f2, f3], true)
        ..moveTo(f0.dx, f0.dy)
        ..lineTo(f0.dx + d.dx, f0.dy + d.dy)
        ..lineTo(f1.dx + d.dx, f1.dy + d.dy)
        ..lineTo(f2.dx + d.dx, f2.dy + d.dy)
        ..lineTo(f2.dx, f2.dy)
        ..moveTo(f1.dx, f1.dy)
        ..lineTo(f1.dx + d.dx, f1.dy + d.dy),
      edge);
  final dash = _stroke(ink.withValues(alpha: 0.6), 1.1);
  void dashed(Offset a, Offset b) {
    const n = 6;
    for (var i = 0; i < n; i += 2) {
      c.drawLine(Offset.lerp(a, b, i / n)!, Offset.lerp(a, b, (i + 1) / n)!, dash);
    }
  }

  dashed(f3, f3 + d);
  dashed(f3 + d, f0 + d);
  dashed(f3 + d, f2 + d);
  for (final p in const [f0, f1, f2, f3, Offset(21, 30), Offset(47, 30), Offset(47, 56)]) {
    c.drawCircle(p, 2, _p(const Color(0xFFFFFFFF)));
    c.drawCircle(p, 2, _stroke(ink, 0.9));
  }

  // Koni: tepe, yan yüzey ve taban elipsi.
  const apex = Offset(70, 12);
  final base = Rect.fromCenter(center: const Offset(70, 48), width: 30, height: 9);
  c.drawPath(
      Path()
        ..moveTo(apex.dx, apex.dy)
        ..lineTo(base.left, base.center.dy)
        ..arcTo(base, math.pi, -math.pi, false)
        ..close(),
      Paint()
        ..shader = LinearGradient(colors: [tone(2, 0.75), tone(2, 0.5)])
            .createShader(Rect.fromLTRB(base.left, apex.dy, base.right, base.bottom)));
  c.drawArc(base, math.pi, math.pi, false, dash);
  c.drawArc(base, 0, math.pi, false, edge);
  c.drawLine(apex, Offset(base.left, base.center.dy), edge);
  c.drawLine(apex, Offset(base.right, base.center.dy), edge);
  c.drawCircle(apex, 2, _p(Colors.white));
  c.drawCircle(apex, 2, _stroke(ink, 0.9));

  // Silindir: iki elips ve gövde.
  final top = Rect.fromCenter(center: const Offset(70, 60), width: 26, height: 8);
  final bot = Rect.fromCenter(center: const Offset(70, 84), width: 26, height: 8);
  c.drawPath(
      Path()
        ..moveTo(top.left, top.center.dy)
        ..lineTo(bot.left, bot.center.dy)
        ..arcTo(bot, math.pi, -math.pi, false)
        ..lineTo(top.right, top.center.dy)
        ..close(),
      Paint()
        ..shader = LinearGradient(colors: [tone(1, 0.6), tone(1, 0.4), tone(1, 0.55)])
            .createShader(Rect.fromLTRB(top.left, top.top, top.right, bot.bottom)));
  c.drawOval(top, _p(tone(1, 0.72)));
  c.drawOval(top, edge);
  c.drawArc(bot, 0, math.pi, false, edge);
  c.drawArc(bot, math.pi, math.pi, false, dash);
  c.drawLine(Offset(top.left, top.center.dy), Offset(bot.left, bot.center.dy), edge);
  c.drawLine(Offset(top.right, top.center.dy), Offset(bot.right, bot.center.dy), edge);

  // Cetvel (eğik), çentikli.
  c.save();
  c.translate(30, 84);
  c.rotate(-0.12);
  final ruler = RRect.fromRectAndRadius(const Rect.fromLTWH(-24, -5, 48, 10), const Radius.circular(2));
  _shadowRRect(c, ruler, dy: 1.4);
  c.drawRRect(ruler, _p(const Color(0xFFFFE08A)));
  c.drawRRect(ruler, _stroke(ink.withValues(alpha: 0.5), 0.8));
  for (var i = 0; i <= 11; i++) {
    final x = -22 + i * 4.0;
    c.drawLine(Offset(x, -5), Offset(x, i.isEven ? -0.5 : -2.5), _stroke(ink, 0.8));
  }
  c.restore();
  return true;
}
