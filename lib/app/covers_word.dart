part of 'covers.dart';

/// Kelime oyunlarının kapak resimleri. [GameCover.label] taşlarda yazacak
/// harfleri verir (boşsa varsayılan harfler).
bool _paintWordCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  final txt = cover.label.isEmpty ? 'KELIME' : cover.label;
  const paper = Color(0xFFF7F1E6);
  const edge = Color(0xFFD9CBB3);
  const hit = Color(0xFF4F9A6E);
  const near = Color(0xFFD9A441);
  const miss = Color(0xFF7B8494);
  void tile(Offset o, double s, String ch, {Color fill = paper, Color ink = _ink}) {
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: s, height: s), Radius.circular(s * 0.18));
    c.drawRRect(r.shift(Offset(0, s * 0.07)), _p(Colors.black26));
    c.drawRRect(r, _p(fill));
    c.drawRRect(r, _stroke(edge, 0.6));
    if (ch.isNotEmpty) _text(c, ch, o, s * 0.6, ink);
  }

  String ch(int i) => txt[i % txt.length];
  switch (cover.kind) {
    case 'letters':
      _bg(c, seed);
      const n = 4;
      for (var y = 0; y < n; y++) {
        for (var x = 0; x < n; x++) {
          final o = Offset(20 + x * 20.0, 20 + y * 20.0);
          final on = v == 0 ? y == 1 : (v == 1 ? (x == y) : (y >= 2 && x <= y - 1));
          tile(o, 17, ch(y * n + x + v), fill: on ? near : paper);
        }
      }
      if (v == 0) c.drawLine(const Offset(14, 40), const Offset(86, 40), _stroke(Colors.white.withValues(alpha: 0.6), 3));
    case 'guessrows':
      _bg(c, seed, tint: const Color(0xFF243142));
      final rows = v == 0 ? 4 : 3;
      final cols = v == 0 ? 5 : (v == 1 ? 4 : 6);
      final s = 76.0 / cols;
      for (var y = 0; y < rows; y++) {
        for (var x = 0; x < cols; x++) {
          final o = Offset(12 + s / 2 + x * s, 20 + y * (s + 2) + s / 2);
          final st = (x * 3 + y * 5 + v) % 4;
          final fill = y == rows - 1 ? hit : [miss, near, hit, miss][st];
          tile(o, s - 3, ch(x + y), fill: fill, ink: Colors.white);
        }
      }
    case 'wheel':
      _bg(c, seed);
      c.drawCircle(const Offset(50, 52), 34, _p(Colors.white.withValues(alpha: 0.85)));
      final n = math.min(6, txt.length);
      for (var i = 0; i < n; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / n;
        final o = Offset(50 + math.cos(a) * 22, 52 + math.sin(a) * 22);
        c.drawCircle(o, 10, _p(i == 0 ? near : paper));
        _text(c, txt[i], o, 12, _ink);
      }
      c.drawLine(Offset(50 + math.cos(-math.pi / 2) * 22, 52 + math.sin(-math.pi / 2) * 22),
          Offset(50 + math.cos(-math.pi / 2 + 2 * math.pi / n) * 22, 52 + math.sin(-math.pi / 2 + 2 * math.pi / n) * 22), _stroke(near, 3));
    case 'crossgrid':
      _bg(c, seed);
      const pattern = ['11100', '10111', '11101', '01111', '11100'];
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          final r = Rect.fromLTWH(14 + x * 14.4, 14 + y * 14.4, 14, 14);
          final on = pattern[y][x] == '1';
          c.drawRect(r, _p(on ? paper : (v == 1 ? const Color(0xFFE9DCC4) : _ink)));
          c.drawRect(r, _stroke(_ink, 0.6));
          if (on && (x + y + v) % 3 == 0) _text(c, v == 2 ? '${(x * 3 + y) % 9 + 1}' : ch(x + y), r.center, 9, v == 2 ? _WCover.accent : _ink);
          if (!on && v == 1) _text(c, '→', r.center, 8, _ink);
        }
      }
    case 'hive':
      _bg(c, seed, tint: const Color(0xFF6B4F2A));
      for (var i = 0; i < 7; i++) {
        final o = i == 0 ? const Offset(50, 52) : Offset(50 + math.cos(math.pi / 3 * i - math.pi / 2) * 23, 52 + math.sin(math.pi / 3 * i - math.pi / 2) * 23);
        final path = Path();
        for (var k = 0; k < 6; k++) {
          final a = math.pi / 3 * k;
          final p = o + Offset(math.cos(a) * 12, math.sin(a) * 12);
          if (k == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        c.drawPath(path, _p(i == 0 ? near : paper));
        _text(c, ch(i), o, 11, _ink);
      }
    case 'wordrack':
      _bg(c, seed, tint: const Color(0xFF2F7F73));
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 5; x++) {
          c.drawRect(Rect.fromLTWH(12 + x * 15.5, 12 + y * 15.5, 14.5, 14.5), _p(((x + y) % 3 == 0) ? const Color(0xFFF1C6B6) : const Color(0xFFE8E2D4)));
        }
      }
      for (var i = 0; i < 3; i++) {
        tile(Offset(27 + i * 15.5, 35.5), 14, ch(i), fill: const Color(0xFFF3E1B9));
      }
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 70, 80, 20), const Radius.circular(4)), _p(const Color(0xFF8A5A36)));
      for (var i = 0; i < 5; i++) {
        tile(Offset(20 + i * 15.0, 78), 13, ch(i + 2), fill: const Color(0xFFF3E1B9));
      }
    case 'quote':
      _bg(c, seed);
      final b = RRect.fromRectAndRadius(const Rect.fromLTWH(12, 18, 76, 50), const Radius.circular(12));
      c.drawRRect(b, _p(paper));
      c.drawPath(Path()..moveTo(30, 66)..lineTo(26, 82)..lineTo(44, 66)..close(), _p(paper));
      _text(c, v == 0 ? '“ _ _ ”' : (v == 1 ? '7 3 1 5' : 'A ↔ Z'), const Offset(50, 43), 16, _ink);
    case 'ladderw':
      _bg(c, seed);
      c.drawLine(const Offset(26, 10), const Offset(26, 92), _stroke(_wood, 4));
      c.drawLine(const Offset(74, 10), const Offset(74, 92), _stroke(_wood, 4));
      for (var i = 0; i < 4; i++) {
        final y = 20.0 + i * 20;
        for (var k = 0; k < 4; k++) {
          tile(Offset(33 + k * 11.5, y), 10, ch(i + k), fill: k == i ? near : paper);
        }
      }
    case 'chainw':
      _bg(c, seed);
      for (var i = 0; i < 3; i++) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(10 + i * 4.0, 16 + i * 24.0, 60, 18), const Radius.circular(9));
        c.drawRRect(r, _p(i.isEven ? paper : const Color(0xFF3E6FB0)));
        _text(c, txt.substring(0, math.min(5, txt.length)), r.center, 10, i.isEven ? _ink : Colors.white);
      }
    case 'petal':
      _bg(c, seed, tint: const Color(0xFF6FA35F));
      for (var i = 0; i < 7; i++) {
        final a = -math.pi / 2 + i * 2 * math.pi / 7;
        c.save();
        c.translate(50 + math.cos(a) * 15, 40 + math.sin(a) * 15);
        c.rotate(a + math.pi / 2);
        c.drawOval(Rect.fromCenter(center: Offset.zero, width: 11, height: 19), _p(i < 5 ? _pal[(i * 3) % 8] : Colors.black12));
        c.restore();
      }
      c.drawCircle(const Offset(50, 40), 8, _p(const Color(0xFFF2C14E)));
      for (var i = 0; i < 5; i++) {
        c.drawLine(Offset(22 + i * 13.0, 86), Offset(31 + i * 13.0, 86), _stroke(Colors.white, 2));
        if (i.isEven) _text(c, ch(i), Offset(26.5 + i * 13.0, 78), 10, Colors.white);
      }
    case 'keyboard':
      _bg(c, seed, tint: const Color(0xFF243142));
      _text(c, txt.substring(0, math.min(5, txt.length)), const Offset(50, 26), 16, const Color(0xFF8BD3A8));
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 7 - y; x++) {
          final r = RRect.fromRectAndRadius(Rect.fromLTWH(10 + y * 5 + x * 11.5, 48 + y * 13.0, 10, 11), const Radius.circular(2));
          c.drawRRect(r, _p((x + y + v) % 5 == 0 ? near : paper));
        }
      }
    case 'pairsw':
      _bg(c, seed);
      for (var i = 0; i < 3; i++) {
        final l = RRect.fromRectAndRadius(Rect.fromLTWH(10, 16 + i * 24.0, 30, 16), const Radius.circular(6));
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(60, 16 + ((i + 1) % 3) * 24.0, 30, 16), const Radius.circular(6));
        c.drawRRect(l, _p(paper));
        c.drawRRect(r, _p(paper));
        c.drawLine(l.center + const Offset(15, 0), r.center - const Offset(15, 0), _stroke(_pal[i * 2], 2.5));
      }
    case 'fall':
      _bg(c, seed, tint: const Color(0xFF1E4D5C));
      for (var i = 0; i < 5; i++) {
        tile(Offset(18 + i * 16.0, 16 + ((i * 37) % 50)), 13, ch(i));
      }
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 78, 80, 14), const Radius.circular(4)), _p(Colors.white24));
    case 'sudokuw':
      _bg(c, seed);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final r = Rect.fromLTWH(18 + x * 16.0, 18 + y * 16.0, 16, 16);
          c.drawRect(r, _p(y == 0 ? const Color(0xFFFFF1D6) : paper));
          c.drawRect(r, _stroke(_ink, (x == 2 || y == 2) ? 1.2 : 0.4));
          if ((x + y * 2) % 3 != 1) _text(c, ch((x + y * 2) % 4), r.center, 10, _ink);
        }
      }
    default:
      return false;
  }
  return true;
}

/// Kapaklarda kullanılan ek renk.
class _WCover {
  static const accent = Color(0xFF3E6FB0);
}
