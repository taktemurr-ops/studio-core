part of 'covers.dart';

/// Zihin antrenmanı egzersizlerinin kapak resimleri.
bool _paintBrainCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const cols = [Color(0xFFE76F51), Color(0xFF2A9D8F), Color(0xFFE9C46A), Color(0xFF457B9D), Color(0xFF8E7DBE), Color(0xFF6A994E)];
  const paper = Color(0xFFF7F1E6);
  const dim = Color(0xFF3B4A66);
  RRect box(Offset o, double w, double h, [double r = 4]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));
  switch (cover.kind) {
    case 'pads':
      _bg(c, seed, tint: const Color(0xFF243142));
      for (var i = 0; i < 4; i++) {
        final o = Offset(32 + (i % 2) * 36.0, 32 + (i ~/ 2) * 36.0);
        final lit = i == v % 4;
        final col = cols[i];
        if (lit) c.drawCircle(o, 24, _p(col.withValues(alpha: 0.35)));
        c.drawRRect(box(o, 30, 30, 8), _p(lit ? col : col.withValues(alpha: 0.45)));
      }
      c.drawCircle(const Offset(50, 50), 6, _p(paper));
    case 'inkword':
      _bg(c, seed, tint: const Color(0xFF2A2D4A));
      final words = cover.label.isEmpty ? const ['KIRMIZI', 'MAVİ', 'YEŞİL'] : cover.label.split(' ');
      for (var i = 0; i < 3; i++) {
        final w = words[(i + v) % words.length];
        _text(c, w, Offset(50, 28 + i * 22.0), w.length > 6 ? 11 : 14, cols[(i * 2 + v + 1) % cols.length]);
      }
    case 'numgrid':
      _bg(c, seed);
      const n = 4;
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          final k = (x * 7 + y * 5 + v * 3) % 16 + 1;
          final o = Offset(23 + x * 18.0, 23 + y * 18.0);
          c.drawRRect(box(o, 16, 16, 3), _p(k <= 3 ? const Color(0xFFE9C46A) : paper));
          _text(c, '$k', o, 9, _ink);
        }
      }
    case 'memgrid':
      _bg(c, seed, tint: const Color(0xFF243142));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final on = (x * 5 + y * 3 + v) % 4 == 0;
          final o = Offset(23 + x * 18.0, 23 + y * 18.0);
          c.drawRRect(box(o, 15, 15, 3), _p(on ? const Color(0xFF7FD1B9) : dim));
        }
      }
    case 'nback':
      _bg(c, seed);
      final letters = [const ['A', 'K', 'A', 'M'], const ['7', '3', '7', '1'], const ['■', '●', '■', '▲']][v % 3];
      for (var i = 0; i < 4; i++) {
        final o = Offset(17 + i * 22.0, 50);
        final same = i == 2;
        c.drawRRect(box(o, 18, 26, 4).shift(const Offset(0, 2)), _p(Colors.black26));
        c.drawRRect(box(o, 18, 26, 4), _p(same ? const Color(0xFFE9C46A) : paper));
        _text(c, letters[i], o, 13, _ink);
      }
      c.drawArc(const Rect.fromLTWH(17, 26, 44, 26), math.pi, math.pi, false, _stroke(Colors.white, 2));
    case 'mathq':
      _bg(c, seed, tint: const Color(0xFF2E4057));
      final a = 3 + v * 4, b = 2 + v;
      c.drawRRect(box(const Offset(50, 40), 76, 30, 8), _p(paper));
      _text(c, '$a + $b', const Offset(50, 40), 16, _ink);
      for (var i = 0; i < 3; i++) {
        final o = Offset(24 + i * 26.0, 74);
        final ok = i == 1;
        c.drawRRect(box(o, 22, 18, 5), _p(ok ? const Color(0xFF6A994E) : Colors.white.withValues(alpha: 0.85)));
        _text(c, '${a + b + i - 1}', o, 10, ok ? Colors.white : _ink);
      }
    case 'reflex':
      _bg(c, seed, tint: const Color(0xFF1F2A3A));
      final col = v == 1 ? const Color(0xFFE76F51) : const Color(0xFF6A994E);
      for (var r = 3; r >= 1; r--) {
        c.drawCircle(const Offset(50, 50), 12.0 + r * 9, _p(col.withValues(alpha: 0.12 * r)));
      }
      c.drawCircle(const Offset(50, 50), 18, _p(col));
      c.drawCircle(const Offset(50, 50), 18, _stroke(Colors.white, 2));
    case 'pattern':
      _bg(c, seed);
      for (var i = 0; i < 4; i++) {
        final o = Offset(16 + i * 22.0, 50);
        c.drawRRect(box(o, 19, 19, 4), _p(paper));
        if (i == 3) {
          _text(c, '?', o, 13, _ink);
          continue;
        }
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(i * math.pi / 4 * (v + 1));
        final p = Path()
          ..moveTo(0, -6)
          ..lineTo(6, 5)
          ..lineTo(-6, 5)
          ..close();
        c.drawPath(p, _p(cols[(v + 3) % cols.length]));
        c.restore();
      }
    case 'rotate':
      _bg(c, seed, tint: const Color(0xFF2A2D4A));
      void shape(Offset o, double a, Color col) {
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(a);
        for (final q in const [Offset(-6, -12), Offset(-6, -4), Offset(-6, 4), Offset(2, 4)]) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(q.dx, q.dy, 8, 8), const Radius.circular(1.5)), _p(col));
        }
        c.restore();
      }
      shape(const Offset(30, 50), 0, const Color(0xFFE9C46A));
      shape(const Offset(72, 50), math.pi / 2 * (v + 1), const Color(0xFF7FD1B9));
      c.drawArc(const Rect.fromLTWH(38, 26, 26, 22), math.pi * 1.1, math.pi * 0.8, false, _stroke(Colors.white, 2));
    case 'daily':
      _bg(c, seed);
      c.drawRRect(box(const Offset(50, 54), 66, 60, 8), _p(paper));
      c.drawRRect(RRect.fromRectAndCorners(const Rect.fromLTWH(17, 24, 66, 14), topLeft: const Radius.circular(8), topRight: const Radius.circular(8)),
          _p(const Color(0xFFE76F51)));
      for (var i = 0; i < 3; i++) {
        final y = 48 + i * 13.0;
        final done = i < (v % 3) + 1;
        c.drawCircle(Offset(28, y), 4.5, _p(done ? const Color(0xFF6A994E) : dim.withValues(alpha: 0.3)));
        c.drawRRect(box(Offset(56, y), 40, 5, 2.5), _p(dim.withValues(alpha: done ? 0.5 : 0.25)));
      }
    case 'facename':
      _bg(c, seed, tint: const Color(0xFF2B3A4A));
      const skins = [Color(0xFFEBC0A0), Color(0xFF8D5A3B), Color(0xFFD5A07A)];
      const hairs = [Color(0xFF3B2A20), Color(0xFF1F1A17), Color(0xFFD9B26F)];
      for (var i = 0; i < 2; i++) {
        final cx = 32.0 + i * 36;
        final k = (i + v) % 3;
        c.drawCircle(Offset(cx, 44), 15, _p(hairs[k]));
        c.drawOval(Rect.fromCenter(center: Offset(cx, 48), width: 24, height: 28), _p(skins[k]));
        c.drawCircle(Offset(cx - 5, 47), 1.8, _p(_ink));
        c.drawCircle(Offset(cx + 5, 47), 1.8, _p(_ink));
        c.drawArc(Rect.fromCenter(center: Offset(cx, 53), width: 9, height: 5), 0.3, math.pi - 0.6, false, _stroke(const Color(0xFF9E4A47), 1.4));
        c.drawRRect(box(Offset(cx, 74), 30, 11, 5), _p(paper));
        c.drawRRect(box(Offset(cx, 74), 18, 3, 1.5), _p(dim.withValues(alpha: 0.6)));
      }
    case 'dualtask':
      _bg(c, seed);
      c.drawRRect(box(const Offset(50, 32), 76, 34, 8), _p(paper));
      c.drawLine(const Offset(20, 40), const Offset(80, 40), _stroke(dim.withValues(alpha: 0.3), 4));
      c.drawLine(const Offset(38, 40), const Offset(62, 40), _stroke(const Color(0xFF6A994E), 4));
      c.drawCircle(Offset(46 + (v % 3) * 4.0, 31), 7, _p(const Color(0xFF457B9D)));
      c.drawRRect(box(const Offset(31, 72), 28, 18, 6), _p(const Color(0xFFE76F51)));
      c.drawRRect(box(const Offset(69, 72), 28, 18, 6), _p(const Color(0xFF6A994E)));
      _text(c, '✗', const Offset(31, 72), 12, paper);
      _text(c, '✓', const Offset(69, 72), 12, paper);
    case 'digitspanc': // Rakam Dizisi: gösterilen rakamlar, ardından gizlenen kutular
      _bg(c, seed, tint: const Color(0xFF243142));
      final digits = cover.label.isEmpty ? '3815' : cover.label;
      for (var i = 0; i < 4; i++) {
        final o = Offset(20 + i * 20.0, 36);
        c.drawRRect(box(o, 16, 22, 5), _p(paper));
        _text(c, digits[i % digits.length], o, 14, cols[(i + v) % cols.length]);
      }
      for (var i = 0; i < 4; i++) {
        final o = Offset(20 + i * 20.0, 68);
        final filled = i < 2 + v % 2;
        c.drawRRect(box(o, 16, 22, 5), _p(filled ? cols[1] : dim));
        if (filled) {
          _text(c, digits[i % digits.length], o, 14, paper);
        } else {
          c.drawCircle(o, 2.4, _p(paper.withValues(alpha: 0.6)));
        }
      }
      c.drawLine(const Offset(50, 49), const Offset(50, 55), _stroke(paper.withValues(alpha: 0.7), 2));
      c.drawPath(Path()..addPolygon(const [Offset(46, 54), Offset(54, 54), Offset(50, 58)], true), _p(paper.withValues(alpha: 0.7)));
    case 'searchgridc': // Görsel Arama: aynı şekiller arasında tek farklı şekil ve büyüteç halkası
      _bg(c, seed, tint: const Color(0xFF2A2D4A));
      final odd = (7 + v * 5) % 25;
      for (var i = 0; i < 25; i++) {
        final o = Offset(18 + (i % 5) * 16.0, 18 + (i ~/ 5) * 16.0);
        if (i == odd) {
          c.drawPath(Path()..addPolygon([o + const Offset(0, -5), o + const Offset(5, 4), o + const Offset(-5, 4)], true), _p(cols[2]));
        } else {
          c.drawCircle(o, 4.6, _p(cols[(v + 1) % cols.length].withValues(alpha: 0.85)));
        }
      }
      final f = Offset(18 + (odd % 5) * 16.0, 18 + (odd ~/ 5) * 16.0);
      c.drawCircle(f, 9.5, _stroke(paper, 2.4));
      c.drawLine(f + const Offset(7, 7), f + const Offset(14, 14), _stroke(paper, 3.2));
    case 'wordmemc': // Kelime Hafızası: kelime kartları, biri çevrilmiş, işaretli liste
      _bg(c, seed, tint: const Color(0xFF2B3A55));
      final words = cover.label.isEmpty ? const ['ELMA', 'DENİZ', 'KİTAP'] : cover.label.split(' ');
      for (var i = 0; i < 3; i++) {
        final o = Offset(34, 26 + i * 22.0);
        c.drawRRect(box(o, 46, 17, 5), _p(i == v % 3 ? cols[(i + v) % cols.length] : paper));
        _text(c, words[i % words.length], o, 9, i == v % 3 ? paper : dim);
      }
      c.drawRRect(box(const Offset(76, 50), 22, 50, 6), _p(dim));
      for (var i = 0; i < 4; i++) {
        final y = 32 + i * 12.0;
        final ok = i < 2 + v % 2;
        c.drawCircle(Offset(70, y), 3, _p(ok ? cols[5] : paper.withValues(alpha: 0.25)));
        c.drawLine(Offset(76, y), Offset(84, y), _stroke(paper.withValues(alpha: 0.5), 2));
      }
    default:
      return false;
  }
  return true;
}
