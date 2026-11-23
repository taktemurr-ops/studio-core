part of 'covers.dart';

/// Arcade oyunlarının kapak resimleri (vektör, dış görsel yok).
/// Döndürür: çizildiyse true.
bool _paintArcadeCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  final sky = const Color(0xFF14213D);
  switch (cover.kind) {
    case 'snake':
      _bg(c, seed, tint: const Color(0xFF1B4332));
      final g = _stroke(Colors.white10, 0.6);
      for (var i = 10.0; i < 100; i += 10) {
        c.drawLine(Offset(i, 6), Offset(i, 94), g);
        c.drawLine(Offset(6, i), Offset(94, i), g);
      }
      final body = Path()
        ..moveTo(20, 80)
        ..lineTo(20, 50)
        ..lineTo(50, 50)
        ..lineTo(50, 30)
        ..lineTo(74, 30);
      c.drawPath(body, _stroke(const Color(0xFF80ED99), 9));
      _stone(c, const Offset(74, 30), 6, const Color(0xFF52B788));
      _stone(c, const Offset(76, 72), 6, _red);
    case 'bricks':
      _bg(c, seed, tint: sky);
      for (var r = 0; r < 4; r++) {
        for (var i = 0; i < 5; i++) {
          if ((r + i + v) % 7 == 3) continue;
          final rr = RRect.fromRectAndRadius(Rect.fromLTWH(10 + i * 16.5, 14 + r * 9, 14.5, 7), const Radius.circular(2));
          c.drawRRect(rr, _p(_pal[(r + v) % 8]));
        }
      }
      _stone(c, const Offset(56, 62), 4.5, Colors.white);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(36, 82, 30, 6), const Radius.circular(3)), _p(const Color(0xFFFFD166)));
    case 'space':
      _bg(c, seed, tint: const Color(0xFF0B1026));
      for (var i = 0; i < 18; i++) {
        c.drawCircle(Offset((i * 37) % 96 + 2, (i * 53) % 96 + 2), i.isEven ? 0.9 : 1.4, _p(Colors.white70));
      }
      if (v == 1) {
        for (var r = 0; r < 2; r++) {
          for (var i = 0; i < 4; i++) {
            final o = Offset(24 + i * 17.0, 22 + r * 14.0);
            c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 12, height: 8), const Radius.circular(3)), _p(_pal[4 + r]));
            c.drawCircle(o + const Offset(-2.5, -1), 1.2, _p(Colors.white));
            c.drawCircle(o + const Offset(2.5, -1), 1.2, _p(Colors.white));
          }
        }
      } else if (v == 2) {
        for (final (x, y, r) in const [(28.0, 30.0, 11.0), (70.0, 26.0, 7.0), (74.0, 58.0, 9.0)]) {
          _stone(c, Offset(x, y), r, const Color(0xFF8D7B6E));
        }
      } else {
        for (final (x, y) in const [(30.0, 26.0), (70.0, 22.0)]) {
          c.drawPath(Path()..moveTo(x - 7, y - 5)..lineTo(x + 7, y - 5)..lineTo(x, y + 6)..close(), _p(_red));
        }
      }
      c.drawLine(const Offset(50, 64), const Offset(50, 40), _stroke(const Color(0xFFFFD166), 2));
      final ship = Path()
        ..moveTo(50, 64)
        ..lineTo(60, 84)
        ..lineTo(50, 79)
        ..lineTo(40, 84)
        ..close();
      c.drawPath(ship, _p(const Color(0xFF4CC9F0)));
    case 'runner':
      _bg(c, seed, tint: v == 0 ? const Color(0xFFE9A178) : (v == 1 ? const Color(0xFF3D405B) : const Color(0xFF4CC9F0)));
      c.drawRect(const Rect.fromLTWH(0, 74, 100, 26), _p(v == 0 ? const Color(0xFFDDA15E) : const Color(0xFF495057)));
      if (v == 0) {
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(66, 50, 8, 24), const Radius.circular(4)), _p(const Color(0xFF2D6A4F)));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(60, 56, 5, 10), const Radius.circular(2.5)), _p(const Color(0xFF2D6A4F)));
      } else {
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(64, 60, 18, 14), const Radius.circular(3)), _p(const Color(0xFFF77F00)));
      }
      final body = v == 0 ? const Color(0xFF52B788) : const Color(0xFF1D2433);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(26, 44, 14, 20), const Radius.circular(6)), _p(body));
      c.drawCircle(const Offset(36, 38), 7, _p(v == 0 ? body : const Color(0xFFFFD6A5)));
      c.drawLine(const Offset(30, 64), const Offset(24, 72), _stroke(body, 3));
      c.drawLine(const Offset(36, 64), const Offset(42, 72), _stroke(body, 3));
      if (v == 2) c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 72, 28, 4), const Radius.circular(2)), _p(const Color(0xFF6A4C93)));
    case 'sky':
      _bg(c, seed, tint: const Color(0xFF8ECAE6));
      c.drawOval(const Rect.fromLTWH(56, 12, 30, 10), _p(Colors.white70));
      if (v == 1) {
        for (final x in [62.0]) {
          c.drawRect(Rect.fromLTWH(x, 0, 14, 34), _p(const Color(0xFF8D6E63)));
          c.drawRect(Rect.fromLTWH(x, 66, 14, 34), _p(const Color(0xFF8D6E63)));
        }
        c.drawPath(Path()..moveTo(44, 50)..lineTo(18, 42)..lineTo(24, 50)..close(), _p(Colors.white));
        c.drawPath(Path()..moveTo(44, 50)..lineTo(24, 50)..lineTo(18, 56)..close(), _p(const Color(0xFFDEE2E6)));
      } else {
        for (final x in [60.0]) {
          c.drawRect(Rect.fromLTWH(x, 0, 16, 32), _p(const Color(0xFF52B788)));
          c.drawRect(Rect.fromLTWH(x, 66, 16, 34), _p(const Color(0xFF52B788)));
        }
        _stone(c, const Offset(32, 50), 8, const Color(0xFFFFD166));
        c.drawCircle(const Offset(35, 47), 2, _p(Colors.white));
        c.drawPath(Path()..moveTo(39, 51)..lineTo(46, 53)..lineTo(39, 55)..close(), _p(const Color(0xFFF77F00)));
      }
    case 'ball':
      _bg(c, seed);
      final l = cover.label;
      if (l == 'basket') {
        c.drawRect(const Rect.fromLTWH(58, 12, 30, 20), _p(Colors.white));
        c.drawRect(const Rect.fromLTWH(58, 12, 30, 20), _stroke(_red, 1.5));
        c.drawLine(const Offset(62, 34), const Offset(82, 34), _stroke(const Color(0xFFF77F00), 2.5));
        _stone(c, const Offset(36, 66), 14, const Color(0xFFF77F00));
        c.drawLine(const Offset(22, 66), const Offset(50, 66), _stroke(Colors.black54, 1));
        c.drawLine(const Offset(36, 52), const Offset(36, 80), _stroke(Colors.black54, 1));
      } else if (l == 'soccer') {
        c.drawRect(const Rect.fromLTWH(20, 14, 60, 26), _stroke(Colors.white, 2.5));
        _stone(c, const Offset(50, 70), 13, Colors.white);
        c.drawCircle(const Offset(50, 70), 4.5, _p(_ink));
      } else if (l == 'bowling') {
        for (var i = 0; i < 3; i++) {
          final o = Offset(62 + i * 9.0, 30 + (i.isEven ? 0 : 6));
          c.drawOval(Rect.fromCenter(center: o, width: 7, height: 16), _p(Colors.white));
          c.drawLine(o + const Offset(-3, -2), o + const Offset(3, -2), _stroke(_red, 1.4));
        }
        _stone(c, const Offset(34, 68), 13, const Color(0xFF6D597A));
      } else if (l == 'golf') {
        c.drawOval(const Rect.fromLTWH(14, 54, 72, 32), _p(const Color(0xFF52B788)));
        c.drawOval(const Rect.fromLTWH(62, 66, 10, 5), _p(_ink));
        c.drawLine(const Offset(67, 68), const Offset(67, 34), _stroke(Colors.white, 1.4));
        c.drawPath(Path()..moveTo(67, 34)..lineTo(80, 39)..lineTo(67, 44)..close(), _p(_red));
        _stone(c, const Offset(32, 68), 4, Colors.white);
      } else if (l == 'volley') {
        c.drawRect(const Rect.fromLTWH(0, 74, 100, 26), _p(const Color(0xFFF4D58D)));
        c.drawLine(const Offset(50, 74), const Offset(50, 44), _stroke(Colors.white, 2));
        _stone(c, const Offset(36, 30), 11, Colors.white);
        c.drawArc(Rect.fromCircle(center: const Offset(36, 30), radius: 11), 0.3, 2.2, false, _stroke(const Color(0xFFFFB703), 2));
      } else {
        // tenis
        c.drawRect(const Rect.fromLTWH(16, 14, 68, 72), _p(const Color(0xFF3A7D44)));
        c.drawRect(const Rect.fromLTWH(16, 14, 68, 72), _stroke(Colors.white, 1.4));
        c.drawLine(const Offset(16, 50), const Offset(84, 50), _stroke(Colors.white, 2));
        _stone(c, const Offset(64, 32), 5, const Color(0xFFD4E157));
        c.drawOval(const Rect.fromLTWH(26, 58, 16, 20), _stroke(_red, 2.2));
        c.drawLine(const Offset(34, 78), const Offset(34, 88), _stroke(_wood, 3));
      }
    case 'target':
      _bg(c, seed, tint: v == 1 ? const Color(0xFF7F1D1D) : null);
      for (var i = 0; i < 5; i++) {
        c.drawCircle(const Offset(50, 50), 34.0 - i * 7, _p(i.isEven ? _red : Colors.white));
      }
      if (v == 2) {
        c.drawLine(const Offset(84, 18), const Offset(54, 46), _stroke(_wood, 2.5));
        c.drawPath(Path()..moveTo(84, 18)..lineTo(90, 12)..lineTo(92, 20)..close(), _p(const Color(0xFF3BA776)));
      } else {
        c.drawLine(const Offset(50, 6), const Offset(50, 94), _stroke(Colors.black38, 1));
        c.drawLine(const Offset(6, 50), const Offset(94, 50), _stroke(Colors.black38, 1));
      }
    case 'balloons':
      _bg(c, seed, tint: const Color(0xFF8ECAE6));
      for (final (x, y, i) in const [(30.0, 40.0, 0), (54.0, 30.0, 2), (72.0, 50.0, 4), (44.0, 62.0, 5)]) {
        c.drawLine(Offset(x, y + 11), Offset(x + 2, y + 28), _stroke(Colors.black38, 0.8));
        c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 18, height: 22), _p(_pal[i]));
        c.drawCircle(Offset(x - 4, y - 5), 2.5, _p(Colors.white54));
      }
    case 'slice':
      _bg(c, seed, tint: const Color(0xFF6F4518));
      c.drawArc(Rect.fromCircle(center: const Offset(38, 50), radius: 16), 1.2, math.pi, true, _p(const Color(0xFFFFB703)));
      c.drawArc(Rect.fromCircle(center: const Offset(44, 54), radius: 16), 1.2 + math.pi, math.pi, true, _p(const Color(0xFFFF7F11)));
      _stone(c, const Offset(70, 34), 10, const Color(0xFFE63946));
      c.drawLine(const Offset(16, 80), const Offset(86, 20), _stroke(Colors.white, 3));
    case 'mole':
      _bg(c, seed, tint: const Color(0xFF6A994E));
      for (final (x, y) in const [(28.0, 40.0), (72.0, 40.0), (50.0, 74.0)]) {
        c.drawOval(Rect.fromCenter(center: Offset(x, y + 10), width: 30, height: 10), _p(const Color(0xFF2B1B12)));
      }
      c.drawOval(const Rect.fromLTWH(40, 52, 20, 26), _p(const Color(0xFF8D6E63)));
      c.drawCircle(const Offset(46, 60), 2, _p(Colors.black));
      c.drawCircle(const Offset(54, 60), 2, _p(Colors.black));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(60, 18, 22, 10), const Radius.circular(3)), _p(_wood));
      c.drawLine(const Offset(71, 28), const Offset(64, 44), _stroke(_wood, 3));
    case 'stack':
      _bg(c, seed);
      for (var i = 0; i < 6; i++) {
        final w = 50.0 - (i % 3) * 4;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(50 + (i.isOdd ? 2 : -2), 82 - i * 10.0), width: w, height: 9), const Radius.circular(2)), _p(_pal[(i + v) % 8]));
      }
    case 'helix':
      _bg(c, seed);
      c.drawRect(const Rect.fromLTWH(44, 0, 12, 100), _p(Colors.white38));
      for (var i = 0; i < 3; i++) {
        final y = 26.0 + i * 26;
        c.drawArc(Rect.fromCenter(center: Offset(50, y), width: 76, height: 16), 0.4, math.pi * 1.6, true, _p(i == 1 ? _red : _pal[(i + 1) % 8]));
      }
      _stone(c, const Offset(56, 46), 5, Colors.white);
    case 'ring':
      _bg(c, seed, tint: const Color(0xFF1B1B2F));
      for (var q = 0; q < 4; q++) {
        c.drawArc(Rect.fromCircle(center: const Offset(50, 44), radius: 24), q * math.pi / 2 + 0.1, math.pi / 2 - 0.2, false, _stroke(_pal[q * 2], 7));
      }
      _stone(c, const Offset(50, 84), 6, _pal[0]);
    case 'knife':
      _bg(c, seed, tint: const Color(0xFF3D405B));
      c.drawCircle(const Offset(50, 40), 22, _p(const Color(0xFFA0522D)));
      c.drawCircle(const Offset(50, 40), 14, _stroke(Colors.black12, 1.5));
      for (final a in [0.6, 2.2, 3.9]) {
        final o = Offset(50 + math.cos(a) * 28, 40 + math.sin(a) * 28);
        c.drawLine(Offset(50 + math.cos(a) * 20, 40 + math.sin(a) * 20), o, _stroke(const Color(0xFFDEE2E6), 3));
      }
      c.drawLine(const Offset(50, 92), const Offset(50, 74), _stroke(const Color(0xFFDEE2E6), 3.5));
      c.drawLine(const Offset(50, 92), const Offset(50, 84), _stroke(_ink, 4));
    case 'lander':
      _bg(c, seed, tint: const Color(0xFF03071E));
      c.drawPath(Path()..moveTo(0, 100)..lineTo(0, 78)..lineTo(20, 70)..lineTo(36, 82)..lineTo(64, 82)..lineTo(80, 66)..lineTo(100, 74)..lineTo(100, 100)..close(), _p(const Color(0xFFADB5BD)));
      c.drawRect(const Rect.fromLTWH(38, 80, 24, 3), _p(const Color(0xFFFFB703)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(42, 34, 16, 10), const Radius.circular(3)), _p(const Color(0xFFCED4DA)));
      c.drawLine(const Offset(44, 44), const Offset(40, 50), _stroke(Colors.white70, 1.5));
      c.drawLine(const Offset(56, 44), const Offset(60, 50), _stroke(Colors.white70, 1.5));
      c.drawPath(Path()..moveTo(46, 44)..lineTo(50, 54)..lineTo(54, 44)..close(), _p(const Color(0xFFFF9F1C)));
    case 'missile':
      _bg(c, seed, tint: const Color(0xFF10002B));
      for (final (x0, x1) in const [(20.0, 34.0), (60.0, 52.0), (88.0, 76.0)]) {
        c.drawLine(Offset(x0, 0), Offset(x1, 40), _stroke(const Color(0xFFFF9E00), 1.6));
      }
      c.drawCircle(const Offset(52, 40), 12, _p(const Color(0xFFFFD60A).withValues(alpha: 0.8)));
      for (var i = 0; i < 4; i++) {
        c.drawRect(Rect.fromLTWH(12.0 + i * 22, 80 - (i % 2) * 6, 10, 20.0 + (i % 2) * 6), _p(_pal[i]));
      }
    case 'tank':
      _bg(c, seed, tint: const Color(0xFFCCD5AE));
      c.drawRect(const Rect.fromLTWH(10, 20, 22, 22), _p(_wood));
      c.drawRect(const Rect.fromLTWH(68, 58, 22, 22), _p(_wood));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 54, 30, 22), const Radius.circular(4)), _p(const Color(0xFF52796F)));
      c.drawCircle(const Offset(45, 65), 7, _p(const Color(0xFF354F52)));
      c.drawLine(const Offset(45, 65), const Offset(66, 44), _stroke(const Color(0xFF354F52), 4));
      _stone(c, const Offset(76, 32), 3, const Color(0xFFFFE066));
    case 'cannon':
      _bg(c, seed, tint: const Color(0xFF90E0EF));
      c.drawPath(Path()..moveTo(0, 100)..lineTo(0, 78)..quadraticBezierTo(50, 40, 100, 78)..lineTo(100, 100)..close(), _p(const Color(0xFF80B918)));
      final dots = _p(Colors.white70);
      for (var i = 1; i < 6; i++) {
        final t = i / 6;
        c.drawCircle(Offset(18 + t * 64, 70 - math.sin(t * math.pi) * 46), 1.6, dots);
      }
      if (v == 1) {
        // sapan ve kale
        c.drawLine(const Offset(16, 80), const Offset(16, 66), _stroke(_wood, 3));
        c.drawLine(const Offset(16, 66), const Offset(11, 58), _stroke(_wood, 3));
        c.drawLine(const Offset(16, 66), const Offset(21, 58), _stroke(_wood, 3));
        c.drawRect(const Rect.fromLTWH(74, 54, 8, 22), _p(const Color(0xFFD4A373)));
        _stone(c, const Offset(78, 48), 5, const Color(0xFF80ED99));
      } else {
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 68, 16, 8), const Radius.circular(3)), _p(_pal[1]));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(76, 68, 16, 8), const Radius.circular(3)), _p(_pal[0]));
      }
    case 'rope':
      _bg(c, seed, tint: const Color(0xFFFDE2E4));
      c.drawLine(const Offset(30, 8), const Offset(50, 44), _stroke(_wood, 2));
      c.drawLine(const Offset(74, 14), const Offset(50, 44), _stroke(_wood, 2));
      _stone(c, const Offset(50, 46), 7, const Color(0xFFE63946));
      _stone(c, const Offset(50, 84), 12, const Color(0xFF52B788));
      c.drawOval(const Rect.fromLTWH(44, 84, 12, 6), _p(const Color(0xFF6A040F)));
    case 'hole':
      _bg(c, seed, tint: const Color(0xFF95D5B2));
      c.drawCircle(const Offset(50, 56), 20, _p(_ink));
      c.drawCircle(const Offset(50, 56), 22, _stroke(_pal[1], 2));
      c.drawRect(const Rect.fromLTWH(14, 16, 12, 12), _p(_pal[0]));
      _stone(c, const Offset(80, 24), 6, _pal[2]);
      c.drawRect(const Rect.fromLTWH(72, 74, 10, 10), _p(_pal[3]));
    case 'pinball':
      _bg(c, seed, tint: const Color(0xFF240046));
      for (final (x, y) in const [(34.0, 30.0), (66.0, 30.0), (50.0, 48.0)]) {
        c.drawCircle(Offset(x, y), 9, _p(const Color(0xFFFFD60A)));
        c.drawCircle(Offset(x, y), 4, _p(Colors.white70));
      }
      c.drawLine(const Offset(30, 82), const Offset(44, 88), _stroke(const Color(0xFFF72585), 5));
      c.drawLine(const Offset(70, 82), const Offset(56, 88), _stroke(const Color(0xFFF72585), 5));
      _stone(c, const Offset(58, 66), 4, Colors.white);
    case 'trail':
      _bg(c, seed, tint: v == 1 ? const Color(0xFFF1F5F9) : const Color(0xFF020617));
      if (v == 1) {
        c.drawRect(const Rect.fromLTWH(14, 54, 32, 32), _p(_pal[7].withValues(alpha: 0.7)));
        c.drawRect(const Rect.fromLTWH(56, 14, 30, 30), _p(_pal[4].withValues(alpha: 0.7)));
        c.drawPath(Path()..moveTo(46, 60)..lineTo(70, 60)..lineTo(70, 44), _stroke(_pal[7], 4));
      } else {
        c.drawPath(Path()..moveTo(12, 84)..lineTo(12, 50)..lineTo(44, 50)..lineTo(44, 24), _stroke(const Color(0xFF4CC9F0), 4));
        c.drawPath(Path()..moveTo(88, 16)..lineTo(88, 60)..lineTo(60, 60)..lineTo(60, 80), _stroke(const Color(0xFFF97316), 4));
        _stone(c, const Offset(44, 24), 4, const Color(0xFF4CC9F0));
        _stone(c, const Offset(60, 80), 4, const Color(0xFFF97316));
      }
    case 'bomb':
      _bg(c, seed, tint: const Color(0xFF386641));
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          final r = Rect.fromLTWH(5 + x * 18.0, 5 + y * 18.0, 17, 17);
          if (x.isOdd && y.isOdd) {
            c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _p(const Color(0xFF6C757D)));
          } else if ((x + y * 3) % 4 == 0) {
            c.drawRRect(RRect.fromRectAndRadius(r.deflate(1.5), const Radius.circular(2)), _p(const Color(0xFFBC6C25)));
          }
        }
      }
      _stone(c, const Offset(50, 50), 7, _ink);
      c.drawCircle(const Offset(56, 42), 2.5, _p(const Color(0xFFFF6D00)));
    case 'dig':
      _bg(c, seed, tint: const Color(0xFF8ECAE6));
      for (var i = 0; i < 4; i++) {
        c.drawRect(Rect.fromLTWH(0, 24.0 + i * 19, 100, 19), _p(Color.lerp(const Color(0xFFDDA15E), const Color(0xFF6F2E0E), i / 3)!));
      }
      c.drawPath(Path()..moveTo(50, 24)..lineTo(50, 60)..lineTo(80, 60), _stroke(_ink, 9));
      _stone(c, const Offset(50, 58), 5, _pal[1]);
      _stone(c, const Offset(78, 60), 7, _red);
    case 'boulder':
      _bg(c, seed, tint: const Color(0xFF7F5539));
      _stone(c, const Offset(30, 30), 11, const Color(0xFFADB5BD));
      _stone(c, const Offset(66, 60), 11, const Color(0xFFADB5BD));
      for (final (x, y) in const [(70.0, 26.0), (28.0, 72.0)]) {
        c.drawPath(Path()..moveTo(x, y - 9)..lineTo(x + 8, y)..lineTo(x, y + 9)..lineTo(x - 8, y)..close(), _p(const Color(0xFF4CC9F0)));
      }
    case 'walkers':
      _bg(c, seed, tint: const Color(0xFF457B9D));
      c.drawRect(const Rect.fromLTWH(6, 40, 34, 6), _p(const Color(0xFF8D6E63)));
      c.drawRect(const Rect.fromLTWH(56, 40, 38, 6), _p(const Color(0xFF8D6E63)));
      c.drawRect(const Rect.fromLTWH(40, 40, 16, 3), _p(const Color(0xFFFFB703)));
      c.drawRect(const Rect.fromLTWH(6, 80, 88, 6), _p(const Color(0xFF8D6E63)));
      for (final x in [16.0, 28.0, 66.0]) {
        c.drawCircle(Offset(x, 26), 3.5, _p(const Color(0xFFFFD6A5)));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, 30, 6, 9), const Radius.circular(2)), _p(_pal[1]));
      }
    case 'bug':
      _bg(c, seed, tint: const Color(0xFF31572C));
      for (var i = 0; i < 6; i++) {
        _stone(c, Offset(20 + i * 11.0, 34), 6, i == 5 ? const Color(0xFFFFB703) : const Color(0xFF80B918));
      }
      for (final (x, y) in const [(30.0, 56.0), (68.0, 50.0)]) {
        c.drawArc(Rect.fromCenter(center: Offset(x, y), width: 16, height: 12), math.pi, math.pi, true, _p(_red));
        c.drawRect(Rect.fromLTWH(x - 2, y, 4, 6), _p(Colors.white));
      }
      c.drawPath(Path()..moveTo(50, 76)..lineTo(58, 90)..lineTo(42, 90)..close(), _p(const Color(0xFF4CC9F0)));
    case 'bullets':
      _bg(c, seed, tint: const Color(0xFF161A1D));
      c.drawCircle(const Offset(50, 26), 12, _p(const Color(0xFFE85D04)));
      for (var i = 0; i < 12; i++) {
        final a = i / 12 * math.pi * 2;
        c.drawCircle(Offset(50 + math.cos(a) * 26, 26 + math.sin(a) * 26 + 10), 2.6, _p(i.isEven ? const Color(0xFFFF4D6D) : const Color(0xFF4CC9F0)));
      }
      c.drawPath(Path()..moveTo(50, 70)..lineTo(58, 86)..lineTo(42, 86)..close(), _p(const Color(0xFF4CC9F0)));
    case 'fish':
      _bg(c, seed, tint: const Color(0xFF0077B6));
      c.drawRect(const Rect.fromLTWH(0, 0, 100, 22), _p(const Color(0xFF90E0EF)));
      c.drawPath(Path()..moveTo(30, 22)..lineTo(70, 22)..lineTo(64, 12)..lineTo(36, 12)..close(), _p(_wood));
      c.drawLine(const Offset(60, 12), const Offset(60, 62), _stroke(Colors.white70, 0.8));
      for (final (x, y, i) in const [(34.0, 54.0, 2), (70.0, 76.0, 0)]) {
        c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 20, height: 10), _p(_pal[i]));
        c.drawPath(Path()..moveTo(x + 9, y)..lineTo(x + 16, y - 5)..lineTo(x + 16, y + 5)..close(), _p(_pal[i]));
      }
    case 'castle':
      _bg(c, seed, tint: const Color(0xFF6A994E));
      c.drawPath(Path()..moveTo(10, 0)..lineTo(10, 40)..lineTo(70, 40)..lineTo(70, 80), _stroke(const Color(0xFFDDA15E), 9));
      c.drawRect(const Rect.fromLTWH(58, 78, 26, 18), _p(const Color(0xFFADB5BD)));
      for (var i = 0; i < 3; i++) {
        c.drawRect(Rect.fromLTWH(58.0 + i * 10, 74, 6, 6), _p(const Color(0xFFADB5BD)));
      }
      _stone(c, const Offset(36, 22), 7, _pal[4]);
      _stone(c, const Offset(86, 50), 7, _pal[1]);
    case 'ski':
      _bg(c, seed, tint: const Color(0xFFE9F1F7));
      for (final (x, col) in const [(28.0, Color(0xFFE63946)), (72.0, Color(0xFF1D4ED8))]) {
        c.drawLine(Offset(x, 30), Offset(x, 52), _stroke(Colors.black54, 1.5));
        c.drawPath(Path()..moveTo(x, 30)..lineTo(x + 10, 34)..lineTo(x, 38)..close(), _p(col));
      }
      c.drawPath(Path()..moveTo(70, 66)..lineTo(78, 86)..lineTo(62, 86)..close(), _p(const Color(0xFF2D6A4F)));
      c.drawLine(const Offset(44, 74), const Offset(58, 70), _stroke(_ink, 2));
      c.drawCircle(const Offset(50, 62), 4, _p(_pal[0]));
    case 'apps':
      _bg(c, seed);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(16 + x * 24.0, 16 + y * 24.0, 18, 18), const Radius.circular(5)), _p(_pal[(x + y * 3) % 8]));
        }
      }
    default:
      return false;
  }
  return true;
}
