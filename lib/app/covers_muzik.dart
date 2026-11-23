part of 'covers.dart';

/// Müzik ve Ritim oyunlarının kapak resimleri (100×100 birim).
bool _paintMuzikCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const lanes = [Color(0xFFE07A5F), Color(0xFF3D9A8B), Color(0xFFE9B949), Color(0xFF7D6CC9), Color(0xFF5B9BD5), Color(0xFFC8608F)];
  const paper = Color(0xFFF6F1E7);
  const night = Color(0xFF1F2A44);
  RRect box(Offset o, double w, double h, [double r = 4]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));
  void noteHead(Offset o, double s, Color col) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(-0.35);
    c.drawOval(Rect.fromCenter(center: Offset.zero, width: s * 1.4, height: s), _p(col));
    c.restore();
  }

  switch (cover.kind) {
    case 'tilesc':
      _bg(c, seed, tint: night);
      for (var l = 0; l < 4; l++) {
        c.drawRect(Rect.fromLTWH(12 + l * 19.0, 8, 18, 84), _p(Colors.white.withValues(alpha: 0.05)));
        final y = 18.0 + ((l * 23 + v * 11) % 50);
        c.drawRRect(box(Offset(21 + l * 19.0, y), 15, 22, 4), _p(lanes[l]));
      }
      c.drawRect(const Rect.fromLTWH(10, 78, 80, 3), _p(Colors.white70));
    case 'beatc':
      _bg(c, seed, tint: const Color(0xFF2B2350));
      for (var k = 0; k < 4; k++) {
        final r = 12.0 + k * 9;
        c.drawArc(Rect.fromCircle(center: const Offset(50, 50), radius: r), 0.3 + k * 0.6 + v * 0.4, 3.6, false, _stroke(lanes[(k + v) % lanes.length], 4.5));
      }
      c.drawCircle(const Offset(50, 50), 6, _p(paper));
    case 'drumc':
      _bg(c, seed, tint: const Color(0xFF4A2E1F));
      c.drawOval(const Rect.fromLTWH(22, 30, 56, 24), _p(const Color(0xFFE9DCC4)));
      c.drawRect(const Rect.fromLTWH(22, 42, 56, 26), _p(lanes[v % lanes.length]));
      c.drawOval(const Rect.fromLTWH(22, 56, 56, 24), _p(lanes[v % lanes.length]));
      c.drawOval(const Rect.fromLTWH(22, 30, 56, 24), _p(const Color(0xFFE9DCC4)));
      c.drawOval(const Rect.fromLTWH(22, 30, 56, 24), _stroke(Colors.black26, 1.5));
      c.drawLine(const Offset(30, 14), const Offset(46, 38), _stroke(paper, 3.5));
      c.drawLine(const Offset(72, 12), const Offset(56, 38), _stroke(paper, 3.5));
    case 'earc':
      _bg(c, seed, tint: const Color(0xFF1E4D49));
      for (var k = 0; k < 3; k++) {
        c.drawArc(Rect.fromCircle(center: const Offset(36, 50), radius: 14.0 + k * 10), -0.8, 1.6, false, _stroke(paper.withValues(alpha: 0.9 - k * 0.25), 3.5));
      }
      noteHead(const Offset(68, 62), 10, lanes[2]);
      c.drawLine(const Offset(74, 60), const Offset(74, 30), _stroke(lanes[2], 3));
    case 'guitarc':
      _bg(c, seed, tint: const Color(0xFF5B3A26));
      c.drawRRect(box(const Offset(50, 50), 60, 76, 6), _p(const Color(0xFF3A2618)));
      for (var f = 0; f < 5; f++) {
        c.drawLine(Offset(22, 22 + f * 14.0), Offset(78, 22 + f * 14.0), _stroke(const Color(0xFFBFB6A0), f == 0 ? 4 : 1.5));
      }
      for (var s = 0; s < 6; s++) {
        c.drawLine(Offset(25 + s * 10.0, 20), Offset(25 + s * 10.0, 86), _stroke(paper, 1 + (5 - s) * 0.25));
      }
      const dots = [
        [1, 1],
        [2, 2],
        [4, 0],
      ];
      for (final d in dots) {
        c.drawCircle(Offset(25 + (d[0] + v % 2) * 10.0, 29 + d[1] * 14.0), 4.5, _p(lanes[(d[0] + v) % lanes.length]));
      }
    case 'melodyc':
      _bg(c, seed, tint: const Color(0xFF3A1F36));
      for (var i = 0; i < 6; i++) {
        final a = -math.pi / 2 + i * math.pi / 3;
        c.save();
        c.translate(50 + math.cos(a) * 22, 50 + math.sin(a) * 22);
        c.rotate(a + math.pi / 2);
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: 18, height: 26), _p(i == v % 6 ? paper : lanes[i]));
        c.restore();
      }
      c.drawCircle(const Offset(50, 50), 10, _p(const Color(0xFFE9B949)));
    case 'staffc':
      _bg(c, seed, tint: paper);
      for (var k = 0; k < 5; k++) {
        c.drawLine(Offset(10, 34 + k * 8.0), Offset(90, 34 + k * 8.0), _stroke(_ink, 1.5));
      }
      for (var i = 0; i < 4; i++) {
        final y = 70 - ((i * 3 + v) % 7) * 4.0;
        noteHead(Offset(32 + i * 16.0, y), 7, _ink);
        c.drawLine(Offset(36.5 + i * 16.0, y), Offset(36.5 + i * 16.0, y - 24), _stroke(_ink, 1.6));
      }
    case 'dailyc':
      _bg(c, seed, tint: const Color(0xFF3B3216));
      for (var i = 0; i < 3; i++) {
        final o = Offset(24 + i * 26.0, 50 + (i == 1 ? -8.0 : 4.0));
        c.drawCircle(o, 11, _p(lanes[(i * 2 + v) % lanes.length]));
      }
      c.drawCircle(const Offset(50, 50), 32, _stroke(const Color(0xFFE9B949), 3));
    default:
      return false;
  }
  return true;
}
