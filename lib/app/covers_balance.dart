part of 'covers.dart';

/// Denge Kulesi kapağı: sallanan vinçten sarkan düzensiz parça, altta
/// eğri büğrü yığılmış bloklar ve rüzgâr çizgileri (vektör, dış görsel yok).
/// Döndürür: çizildiyse true.
bool _paintBalanceCover(Canvas c, GameCover cover, Color seed) {
  if (cover.kind != 'balance') return false;
  final v = cover.v;
  _bg(c, seed, tint: const Color(0xFF1D3557));
  // Rüzgâr çizgileri
  final wind = _stroke(Colors.white24, 1.6)..strokeCap = StrokeCap.round;
  for (var i = 0; i < 3; i++) {
    final y = 30.0 + i * 9;
    c.drawPath(
        Path()
          ..moveTo(8, y)
          ..quadraticBezierTo(18, y - 4, 28, y)
          ..quadraticBezierTo(34, y + 3, 40, y),
        wind);
  }
  // Vinç kolu ve halat (hafif salınımlı)
  final beam = _stroke(const Color(0xFFFFD166), 3.2)..strokeCap = StrokeCap.round;
  c.drawLine(const Offset(46, 8), const Offset(92, 8), beam);
  c.drawLine(const Offset(86, 8), const Offset(92, 2), _stroke(const Color(0xFFFFD166), 2));
  final sway = (v % 3 - 1) * 4.0;
  final hook = Offset(68 + sway, 30);
  c.drawLine(const Offset(68, 9), hook, _stroke(Colors.white70, 1.1));
  // Sarkan düzensiz parça (L/çokgen)
  c.save();
  c.translate(hook.dx, hook.dy + 6);
  c.rotate(sway * 0.03);
  final piece = Path()
    ..moveTo(-12, -4)
    ..lineTo(8, -4)
    ..lineTo(8, 2)
    ..lineTo(13, 2)
    ..lineTo(13, 8)
    ..lineTo(-12, 8)
    ..close();
  c.drawPath(piece.shift(const Offset(0, 1.6)), _p(Colors.black26));
  c.drawPath(piece, _p(_pal[(v + 2) % 8]));
  c.drawPath(piece, _stroke(Colors.white38, 0.8));
  c.restore();
  // Zemin
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 88, 72, 6), const Radius.circular(2)),
      _p(const Color(0xFF6C584C)));
  // Yığılmış, hafif eğik bloklar
  const blocks = [
    [50.0, 82.0, 44.0, 10.0, 0.0],
    [47.0, 72.0, 34.0, 10.0, -0.04],
    [53.0, 62.5, 30.0, 9.0, 0.06],
    [49.0, 53.5, 22.0, 9.0, -0.08],
  ];
  for (var i = 0; i < blocks.length; i++) {
    final b = blocks[i];
    c.save();
    c.translate(b[0], b[1]);
    c.rotate(b[4]);
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: b[2], height: b[3]), const Radius.circular(2));
    _shadowRRect(c, r, dy: 1.4);
    c.drawRRect(r, _p(_pal[(v + i * 3) % 8]));
    c.drawRRect(r, _stroke(Colors.white30, 0.7));
    c.restore();
  }
  // Mükemmel bırakış yıldızı
  final star = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rad = i.isEven ? 5.0 : 2.2;
    final o = Offset(30 + rad * math.cos(a), 52 + rad * math.sin(a));
    i == 0 ? star.moveTo(o.dx, o.dy) : star.lineTo(o.dx, o.dy);
  }
  c.drawPath(star..close(), _p(const Color(0xFFFFE66D)));
  return true;
}
