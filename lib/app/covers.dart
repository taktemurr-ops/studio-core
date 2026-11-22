import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bir oyunun içeriğini anlatan küçük vektör kapak resmi. Merkez listesinde,
/// "haftanın oyunu" kartında ve oyunun ana ekranında simge yerine çizilir;
/// böylece adı yanıltıcı olabilen oyunlar (ör. kâğıt oyunu "Golf") ilk
/// bakışta ne olduklarını gösterir. Hiçbir dış görsel kullanılmaz.
class GameCover {
  /// Çizim türü: cards, solitaire, pyramid, rack, domino, mahjong, chess,
  /// checkers, go, reversi, xo, connect, backgammon, mancala, dice, race,
  /// grid, nonogram, blocks, hexes, bubbles, gems, tubes, maze, pipes,
  /// shelf, pairs, lens, chain, fruit, pins, war, map.
  final String kind;

  /// Kartta ya da ızgarada gösterilecek kısa yazı (ör. "A", "7", "21").
  final String label;

  /// Türün küçük ayarları (ör. takım, renk sayısı).
  final int v;
  const GameCover(this.kind, {this.label = '', this.v = 0});
}

/// Kapak resmini çizen widget.
class CoverArt extends StatelessWidget {
  final GameCover cover;
  final Color color;
  final double size;
  final double radius;
  const CoverArt({super.key, required this.cover, required this.color, this.size = 64, this.radius = 16});

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _CoverPainter(cover, color), isComplex: true),
        ),
      );
}

class _CoverPainter extends CustomPainter {
  final GameCover c;
  final Color color;
  _CoverPainter(this.c, this.color);

  @override
  bool shouldRepaint(covariant _CoverPainter o) => o.c != c || o.color != color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);
    paintCover(canvas, c, color);
    canvas.restore();
  }
}

// ---- Renkler ve yardımcılar --------------------------------------------------

const _red = Color(0xFFD23C3C);
const _ink = Color(0xFF1D2433);
const _ivory = Color(0xFFFFFBF2);
const _wood = Color(0xFF8A5A36);
const _woodLight = Color(0xFFC08A5A);
const _felt = Color(0xFF1F6B4A);
const _pal = [
  Color(0xFFE2574C), Color(0xFF3075C4), Color(0xFFF2A93B), Color(0xFF3BA776),
  Color(0xFF9763BC), Color(0xFF2BB3B1), Color(0xFFE58FB0), Color(0xFFF08A4B),
];

Paint _p(Color c) => Paint()..color = c..isAntiAlias = true;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _shadowRRect(Canvas c, RRect r, {double dy = 2.2, double a = 0.28}) {
  c.drawRRect(r.shift(Offset(0, dy)), _p(Colors.black.withValues(alpha: a)));
}

void _text(Canvas c, String s, Offset center, double size, Color color, {FontWeight w = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(color: color, fontSize: size, fontWeight: w, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

/// Kâğıt takımları vektör olarak (emoji/yazı tipi yok). 0 maça, 1 kupa, 2 karo, 3 sinek.
void drawSuit(Canvas c, int suit, Offset o, double s, {Color? color}) {
  final col = color ?? (suit == 1 || suit == 2 ? _red : _ink);
  final p = _p(col);
  switch (suit % 4) {
    case 1: // kupa
      final path = Path()
        ..moveTo(o.dx, o.dy + s * 0.45)
        ..cubicTo(o.dx - s * 0.9, o.dy - s * 0.15, o.dx - s * 0.35, o.dy - s * 0.75, o.dx, o.dy - s * 0.25)
        ..cubicTo(o.dx + s * 0.35, o.dy - s * 0.75, o.dx + s * 0.9, o.dy - s * 0.15, o.dx, o.dy + s * 0.45)
        ..close();
      c.drawPath(path, p);
    case 2: // karo
      c.drawPath(
          Path()
            ..moveTo(o.dx, o.dy - s * 0.55)
            ..lineTo(o.dx + s * 0.4, o.dy)
            ..lineTo(o.dx, o.dy + s * 0.55)
            ..lineTo(o.dx - s * 0.4, o.dy)
            ..close(),
          p);
    case 3: // sinek
      final r = s * 0.22;
      c.drawCircle(o + Offset(0, -s * 0.26), r, p);
      c.drawCircle(o + Offset(-s * 0.24, s * 0.06), r, p);
      c.drawCircle(o + Offset(s * 0.24, s * 0.06), r, p);
      c.drawPath(
          Path()
            ..moveTo(o.dx - s * 0.04, o.dy)
            ..lineTo(o.dx - s * 0.18, o.dy + s * 0.5)
            ..lineTo(o.dx + s * 0.18, o.dy + s * 0.5)
            ..lineTo(o.dx + s * 0.04, o.dy)
            ..close(),
          p);
    default: // maça
      final path = Path()
        ..moveTo(o.dx, o.dy - s * 0.55)
        ..cubicTo(o.dx - s * 0.9, o.dy + s * 0.05, o.dx - s * 0.35, o.dy + s * 0.6, o.dx, o.dy + s * 0.15)
        ..cubicTo(o.dx + s * 0.35, o.dy + s * 0.6, o.dx + s * 0.9, o.dy + s * 0.05, o.dx, o.dy - s * 0.55)
        ..close();
      c.drawPath(path, p);
      c.drawPath(
          Path()
            ..moveTo(o.dx - s * 0.03, o.dy + s * 0.1)
            ..lineTo(o.dx - s * 0.17, o.dy + s * 0.55)
            ..lineTo(o.dx + s * 0.17, o.dy + s * 0.55)
            ..lineTo(o.dx + s * 0.03, o.dy + s * 0.1)
            ..close(),
          p);
  }
}

/// Tek bir oyun kâğıdı: [center] merkez, [w] genişlik, [angle] radyan.
void drawCard(Canvas c, Offset center, double w, double angle,
    {String rank = 'A', int suit = 0, bool back = false, Color backColor = const Color(0xFF2E5FA8)}) {
  final h = w * 1.4;
  c.save();
  c.translate(center.dx, center.dy);
  c.rotate(angle);
  final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: w, height: h), Radius.circular(w * 0.12));
  _shadowRRect(c, r, dy: w * 0.06, a: 0.3);
  if (back) {
    c.drawRRect(r, _p(Colors.white));
    final inner = r.deflate(w * 0.07);
    c.drawRRect(inner, _p(backColor));
    c.save();
    c.clipRRect(inner);
    final lp = _stroke(Colors.white.withValues(alpha: 0.28), w * 0.035);
    for (var k = -6; k <= 6; k++) {
      c.drawLine(Offset(k * w * 0.16 - h, -h), Offset(k * w * 0.16 + h, h), lp);
      c.drawLine(Offset(k * w * 0.16 + h, -h), Offset(k * w * 0.16 - h, h), lp);
    }
    c.restore();
  } else {
    c.drawRRect(r, _p(_ivory));
    c.drawRRect(r, _stroke(Colors.black.withValues(alpha: 0.12), w * 0.02));
    final col = suit == 1 || suit == 2 ? _red : _ink;
    _text(c, rank, Offset(-w * 0.28, -h * 0.34), w * 0.26, col);
    drawSuit(c, suit, Offset(-w * 0.28, -h * 0.16), w * 0.18);
    drawSuit(c, suit, Offset(w * 0.06, h * 0.12), w * 0.5);
  }
  c.restore();
}

void _bg(Canvas c, Color seed, {Color? tint}) {
  final base = tint ?? seed;
  final hsl = HSLColor.fromColor(base);
  final light = hsl.withLightness((hsl.lightness + 0.18).clamp(0.0, 0.85)).toColor();
  final dark = hsl.withLightness((hsl.lightness - 0.16).clamp(0.08, 1.0)).toColor();
  c.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader =RadialGradient(center: const Alignment(-0.4, -0.5), radius: 1.3, colors: [light, base, dark])
            .createShader(const Rect.fromLTWH(0, 0, 100, 100)));
  // Hafif ışık lekesi
  c.drawCircle(const Offset(18, 12), 34, _p(Colors.white.withValues(alpha: 0.07)));
}

void _woodBoard(Canvas c, Rect r) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
  _shadowRRect(c, rr, dy: 2.5);
  c.drawRRect(rr, Paint()..shader = const LinearGradient(colors: [_woodLight, _wood]).createShader(r));
  final g = _stroke(Colors.black.withValues(alpha: 0.08), 0.8);
  for (var y = r.top + 4; y < r.bottom; y += 5) {
    c.drawLine(Offset(r.left + 2, y), Offset(r.right - 2, y + 1.5), g);
  }
}

void _stone(Canvas c, Offset o, double r, Color col) {
  c.drawCircle(o + const Offset(0, 1.2), r, _p(Colors.black.withValues(alpha: 0.3)));
  c.drawCircle(
      o,
      r,
      Paint()
        ..shader = RadialGradient(
                center: const Alignment(-0.4, -0.5),
                colors: [Color.lerp(col, Colors.white, 0.45)!, col, Color.lerp(col, Colors.black, 0.35)!])
            .createShader(Rect.fromCircle(center: o, radius: r)));
}

void _tile(Canvas c, Rect r, {Color face = _ivory, double rad = 3}) {
  final rr = RRect.fromRectAndRadius(r, Radius.circular(rad));
  c.drawRRect(rr.shift(const Offset(0, 1.6)), _p(const Color(0xFFB9A88C)));
  c.drawRRect(rr, _p(face));
  c.drawRRect(rr, _stroke(Colors.black.withValues(alpha: 0.12), 0.6));
}

// ---- Çizimler -----------------------------------------------------------------

void paintCover(Canvas c, GameCover cover, Color seed) {
  final k = cover.kind;
  final v = cover.v;
  switch (k) {
    case 'cards':
      _bg(c, seed, tint: _felt);
      final ranks = cover.label.isEmpty ? ['Q', 'K', 'A'] : cover.label.split(',');
      final n = ranks.length;
      for (var i = 0; i < n; i++) {
        final a = (i - (n - 1) / 2) * 0.32;
        drawCard(c, Offset(50 + (i - (n - 1) / 2) * 15, 56 + ((i - (n - 1) / 2).abs()) * 3), 34, a,
            rank: ranks[i], suit: (v + i) % 4);
      }
    case 'cardback':
      _bg(c, seed, tint: _felt);
      drawCard(c, const Offset(38, 52), 32, -0.18, back: true);
      drawCard(c, const Offset(60, 50), 32, 0.14, rank: cover.label.isEmpty ? 'J' : cover.label, suit: v);
    case 'solitaire':
      _bg(c, seed, tint: _felt);
      for (var col = 0; col < 4; col++) {
        for (var i = 0; i <= col % 3 + 1; i++) {
          final last = i == col % 3 + 1;
          drawCard(c, Offset(17 + col * 22, 26 + i * 12), 19, 0,
              rank: ['K', 'Q', 'J', '10', '9'][(i + col) % 5], suit: (i + col + v) % 4, back: !last && i < col % 3);
        }
      }
    case 'pyramid':
      _bg(c, seed, tint: _felt);
      for (var row = 0; row < 3; row++) {
        for (var i = 0; i <= row; i++) {
          drawCard(c, Offset(50 + (i - row / 2) * 20, 24 + row * 22), 18, 0,
              rank: ['A', '5', '8', '3', 'K', '7'][(row * 2 + i) % 6], suit: (row + i + v) % 4);
        }
      }
    case 'rack': // okey/remi taşları ıstakada
      _bg(c, seed);
      final rack = const Rect.fromLTWH(8, 52, 84, 30);
      _woodBoard(c, rack);
      final nums = cover.label.isEmpty ? ['7', '8', '9', '9', '9'] : cover.label.split(',');
      for (var i = 0; i < nums.length; i++) {
        final r = Rect.fromLTWH(12 + i * 16.2, 26 + (i.isOdd ? 2 : 0), 14.5, 26);
        _tile(c, r);
        final col = [_red, _ink, const Color(0xFF2B6CB0), const Color(0xFFD69E2E)][(i < 3 ? v : i + v) % 4];
        _text(c, nums[i], r.center - const Offset(0, 3), 10, col);
        c.drawCircle(r.center + const Offset(0, 7), 1.6, _p(col));
      }
    case 'domino':
      _bg(c, seed);
      void dom(Offset o, double a, int x, int y) {
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(a);
        final r = const Rect.fromLTWH(-13, -25, 26, 50);
        _tile(c, r, rad: 5);
        c.drawLine(const Offset(-10, 0), const Offset(10, 0), _stroke(Colors.black54, 1.2));
        void pips(int n, double cy) {
          const pos = {
            1: [Offset(0, 0)],
            2: [Offset(-5, -5), Offset(5, 5)],
            3: [Offset(-5, -5), Offset(0, 0), Offset(5, 5)],
            4: [Offset(-5, -5), Offset(5, -5), Offset(-5, 5), Offset(5, 5)],
            5: [Offset(-5, -5), Offset(5, -5), Offset(0, 0), Offset(-5, 5), Offset(5, 5)],
            6: [Offset(-5, -6), Offset(5, -6), Offset(-5, 0), Offset(5, 0), Offset(-5, 6), Offset(5, 6)],
          };
          for (final p in pos[n] ?? const <Offset>[]) {
            c.drawCircle(Offset(p.dx, cy + p.dy), 2.1, _p(_ink));
          }
        }

        pips(x, -12.5);
        pips(y, 12.5);
        c.restore();
      }
      dom(const Offset(38, 52), -0.25, 6, 3);
      dom(const Offset(64, 50), 0.2, 3, 5);
    case 'mahjong':
      _bg(c, seed, tint: const Color(0xFF2F6B5E));
      for (var layer = 0; layer < 2; layer++) {
        for (var i = 0; i < (layer == 0 ? 3 : 2); i++) {
          for (var j = 0; j < 2; j++) {
            final r = Rect.fromLTWH(18 + i * 22 + layer * 11 - layer * 2, 22 + j * 30 - layer * 4, 20, 27);
            _tile(c, r, rad: 3);
            final col = _pal[(i + j * 3 + layer * 2 + v) % 4];
            if ((i + j + layer).isEven) {
              c.drawCircle(r.center, 5.5, _stroke(col, 2));
              c.drawCircle(r.center, 1.8, _p(col));
            } else {
              for (var b = -1; b <= 1; b++) {
                c.drawLine(r.center + Offset(b * 4.5, -7), r.center + Offset(b * 4.5, 7), _stroke(col, 2.2));
              }
            }
          }
        }
      }
    case 'chess':
    case 'checkers':
    case 'go':
    case 'reversi':
      _bg(c, seed);
      final n = k == 'go' ? 6 : (k == 'reversi' ? 4 : 5);
      final board = const Rect.fromLTWH(14, 14, 72, 72);
      _woodBoard(c, board.inflate(4));
      final cell = board.width / n;
      if (k == 'go') {
        c.drawRect(board, _p(const Color(0xFFE2B56C)));
        for (var i = 0; i <= n; i++) {
          c.drawLine(Offset(board.left + i * cell, board.top), Offset(board.left + i * cell, board.bottom), _stroke(_ink, 0.7));
          c.drawLine(Offset(board.left, board.top + i * cell), Offset(board.right, board.top + i * cell), _stroke(_ink, 0.7));
        }
        const st = [(1, 1, 0), (2, 2, 1), (3, 2, 0), (2, 3, 1), (4, 3, 0), (3, 4, 1), (1, 4, 1)];
        for (final (x, y, w) in st) {
          _stone(c, Offset(board.left + x * cell, board.top + y * cell), cell * 0.45, w == 0 ? _ink : Colors.white);
        }
      } else {
        for (var y = 0; y < n; y++) {
          for (var x = 0; x < n; x++) {
            final dark = (x + y).isOdd;
            c.drawRect(Rect.fromLTWH(board.left + x * cell, board.top + y * cell, cell, cell),
                _p(k == 'reversi' ? const Color(0xFF2E7D4F) : (dark ? const Color(0xFF7A4B2A) : const Color(0xFFEBD3A8))));
          }
        }
        if (k == 'reversi') {
          for (var i = 0; i <= n; i++) {
            c.drawLine(Offset(board.left + i * cell, board.top), Offset(board.left + i * cell, board.bottom), _stroke(Colors.black26, 0.8));
            c.drawLine(Offset(board.left, board.top + i * cell), Offset(board.right, board.top + i * cell), _stroke(Colors.black26, 0.8));
          }
          for (final (x, y, w) in const [(1, 1, 0), (2, 1, 1), (1, 2, 1), (2, 2, 0), (3, 2, 0)]) {
            _stone(c, Offset(board.left + (x + 0.5) * cell, board.top + (y + 0.5) * cell), cell * 0.4, w == 0 ? _ink : Colors.white);
          }
        } else if (k == 'checkers') {
          for (final (x, y, w) in const [(1, 0, 0), (3, 0, 0), (0, 1, 0), (2, 1, 0), (1, 3, 1), (3, 3, 1), (4, 4, 1), (2, 4, 1)]) {
            final o = Offset(board.left + (x + 0.5) * cell, board.top + (y + 0.5) * cell);
            _stone(c, o, cell * 0.38, w == 0 ? _red : const Color(0xFFF4EBDD));
            c.drawCircle(o, cell * 0.24, _stroke(Colors.black.withValues(alpha: 0.2), 0.8));
          }
        } else {
          // satranç: şah ve at siluetleri
          _chessKing(c, Offset(board.left + 1.5 * cell, board.top + 3.6 * cell), cell * 1.1, Colors.white);
          _chessKnight(c, Offset(board.left + 3.5 * cell, board.top + 2.6 * cell), cell * 1.1, _ink);
          _chessPawn(c, Offset(board.left + 2.5 * cell, board.top + 1.6 * cell), cell * 0.9, _ink);
          _chessPawn(c, Offset(board.left + 0.5 * cell, board.top + 4.6 * cell), cell * 0.9, Colors.white);
        }
      }
    case 'xo':
      _bg(c, seed);
      final pen = _stroke(Colors.white, 3);
      for (var i = 1; i < 3; i++) {
        c.drawLine(Offset(20 + i * 20, 18), Offset(20 + i * 20, 82), pen);
        c.drawLine(Offset(18, 20 + i * 20), Offset(82, 20 + i * 20), pen);
      }
      void x(double cx, double cy) {
        final p = _stroke(const Color(0xFFFFD166), 4.5);
        c.drawLine(Offset(cx - 6, cy - 6), Offset(cx + 6, cy + 6), p);
        c.drawLine(Offset(cx + 6, cy - 6), Offset(cx - 6, cy + 6), p);
      }
      void o(double cx, double cy) => c.drawCircle(Offset(cx, cy), 7, _stroke(const Color(0xFF7FD8FF), 4.5));
      x(30, 30);
      o(50, 30);
      x(50, 50);
      o(70, 50);
      x(70, 70);
    case 'connect':
      _bg(c, seed);
      final r = RRect.fromRectAndRadius(const Rect.fromLTWH(12, 22, 76, 62), const Radius.circular(8));
      _shadowRRect(c, r);
      c.drawRRect(r, _p(const Color(0xFF2B5DB8)));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 5; x++) {
          const fill = {'0,3': 1, '1,3': 2, '2,3': 1, '1,2': 1, '2,2': 2, '2,1': 1, '3,3': 2, '3,2': 2};
          final f = fill['$x,$y'] ?? 0;
          final o = Offset(21 + x * 14.5, 31 + y * 14.5);
          c.drawCircle(o, 5.6, _p(f == 0 ? const Color(0xFF16346E) : (f == 1 ? const Color(0xFFF2C14E) : _red)));
        }
      }
    case 'backgammon':
      _bg(c, seed);
      final b = const Rect.fromLTWH(10, 14, 80, 72);
      _woodBoard(c, b.inflate(3));
      c.drawRect(b, _p(const Color(0xFF2F5D46)));
      for (var i = 0; i < 6; i++) {
        final col = i.isEven ? const Color(0xFFE9D6B0) : const Color(0xFFB34A3A);
        final x0 = b.left + i * (b.width / 6);
        c.drawPath(Path()..moveTo(x0, b.top)..lineTo(x0 + b.width / 6, b.top)..lineTo(x0 + b.width / 12, b.top + 30)..close(), _p(col));
        final col2 = i.isOdd ? const Color(0xFFE9D6B0) : const Color(0xFFB34A3A);
        c.drawPath(Path()..moveTo(x0, b.bottom)..lineTo(x0 + b.width / 6, b.bottom)..lineTo(x0 + b.width / 12, b.bottom - 30)..close(), _p(col2));
      }
      for (var i = 0; i < 3; i++) {
        _stone(c, Offset(b.left + b.width / 12, b.top + 6 + i * 10), 5, Colors.white);
        _stone(c, Offset(b.left + 5 * b.width / 12 * 2 - b.width / 12 * 4, b.bottom - 6 - i * 10), 5, _ink);
      }
      _die(c, const Offset(56, 50), 13, 5, 0.2);
      _die(c, const Offset(72, 52), 13, 3, -0.15);
    case 'mancala':
      _bg(c, seed);
      final b = const Rect.fromLTWH(6, 28, 88, 44);
      _woodBoard(c, b);
      for (var row = 0; row < 2; row++) {
        for (var i = 0; i < 4; i++) {
          final o = Offset(26 + i * 16, 40 + row * 20);
          c.drawCircle(o, 6.8, _p(const Color(0xFF5C3A20)));
          for (var s = 0; s < 3; s++) {
            _stone(c, o + Offset(math.cos(s * 2.1 + i) * 2.5, math.sin(s * 2.1 + i) * 2.5), 1.9, _pal[(s + i + row) % 6]);
          }
        }
      }
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 33, 8, 34), const Radius.circular(4)), _p(const Color(0xFF5C3A20)));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(83, 33, 8, 34), const Radius.circular(4)), _p(const Color(0xFF5C3A20)));
    case 'dice':
      _bg(c, seed);
      _die(c, const Offset(38, 46), 30, v == 0 ? 5 : v, -0.25);
      _die(c, const Offset(64, 60), 30, 6, 0.2);
    case 'race': // yılan merdiven / kızma birader tipi parkur
      _bg(c, seed);
      final b = const Rect.fromLTWH(12, 12, 76, 76);
      _woodBoard(c, b.inflate(3));
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          c.drawRect(Rect.fromLTWH(b.left + x * 15.2, b.top + y * 15.2, 15.2, 15.2),
              _p((x + y).isEven ? const Color(0xFFF7E7C6) : _pal[(x + y * 2) % 6].withValues(alpha: 0.75)));
        }
      }
      _stone(c, const Offset(35, 64), 5.5, _red);
      _stone(c, const Offset(58, 34), 5.5, const Color(0xFF3075C4));
      _die(c, const Offset(70, 70), 16, 4, 0.2);
    case 'grid':
      _bg(c, seed);
      final g = const Rect.fromLTWH(15, 15, 70, 70);
      _shadowRRect(c, RRect.fromRectAndRadius(g, const Radius.circular(6)));
      c.drawRRect(RRect.fromRectAndRadius(g, const Radius.circular(6)), _p(Colors.white));
      const n = 4;
      final cs = g.width / n;
      for (var i = 1; i < n; i++) {
        final w = i == 2 ? 1.8 : 0.7;
        c.drawLine(Offset(g.left + i * cs, g.top), Offset(g.left + i * cs, g.bottom), _stroke(_ink.withValues(alpha: 0.6), w));
        c.drawLine(Offset(g.left, g.top + i * cs), Offset(g.right, g.top + i * cs), _stroke(_ink.withValues(alpha: 0.6), w));
      }
      final digits = (cover.label.isEmpty ? '1 3  4 2 2 4  3 1' : cover.label).padRight(16);
      for (var i = 0; i < 16; i++) {
        final ch = digits[i];
        if (ch == ' ') continue;
        _text(c, ch, Offset(g.left + (i % 4 + 0.5) * cs, g.top + (i ~/ 4 + 0.5) * cs), cs * 0.6,
            i.isEven ? _ink : HSLColor.fromColor(seed).withLightness(0.4).toColor());
      }
    case 'nonogram':
      _bg(c, seed);
      final g = const Rect.fromLTWH(18, 18, 64, 64);
      c.drawRRect(RRect.fromRectAndRadius(g.inflate(3), const Radius.circular(5)), _p(Colors.white));
      const pic = ['01110', '11111', '11011', '01110', '00100'];
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          final r = Rect.fromLTWH(g.left + x * 12.8 + 0.6, g.top + y * 12.8 + 0.6, 11.6, 11.6);
          c.drawRect(r, _p(pic[y][x] == '1' ? (v == 1 ? _pal[(x + y) % 4] : _ink) : const Color(0xFFEFEAE0)));
        }
      }
    case 'blocks':
      _bg(c, seed);
      const shapes = [
        [(0, 0), (1, 0), (2, 0), (1, 1)],
        [(0, 0), (0, 1), (1, 1), (1, 2)],
        [(0, 0), (1, 0), (0, 1), (1, 1)],
      ];
      final offs = const [Offset(16, 20), Offset(58, 26), Offset(32, 58)];
      for (var s = 0; s < 3; s++) {
        for (final (x, y) in shapes[s]) {
          final r = RRect.fromRectAndRadius(Rect.fromLTWH(offs[s].dx + x * 13, offs[s].dy + y * 13, 12.4, 12.4), const Radius.circular(3));
          c.drawRRect(r.shift(const Offset(0, 1.5)), _p(Colors.black26));
          c.drawRRect(r, _p(_pal[(s * 3 + v) % 8]));
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 2, r.top + 2, 8, 3), const Radius.circular(2)),
              _p(Colors.white.withValues(alpha: 0.35)));
        }
      }
    case 'hexes':
      _bg(c, seed);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final o = Offset(22 + x * 17 + (y.isOdd ? 8.5 : 0), 24 + y * 15);
          final path = Path();
          for (var i = 0; i < 6; i++) {
            final a = math.pi / 6 + i * math.pi / 3;
            final p = o + Offset(math.cos(a) * 9, math.sin(a) * 9);
            i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
          }
          path.close();
          c.drawPath(path.shift(const Offset(0, 1.4)), _p(Colors.black26));
          c.drawPath(path, _p(_pal[(x * 2 + y * 3 + v) % 5]));
        }
      }
    case 'bubbles':
      _bg(c, seed, tint: const Color(0xFF203A6B));
      final rnd = math.Random(4 + v);
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 6; x++) {
          _stone(c, Offset(13 + x * 15 + (y.isOdd ? 7.5 : 0), 14 + y * 13), 7, _pal[rnd.nextInt(5)]);
        }
      }
      c.drawLine(const Offset(50, 88), const Offset(42, 66), _stroke(Colors.white54, 1.5));
      _stone(c, const Offset(50, 86), 7, _pal[1]);
    case 'gems':
      _bg(c, seed, tint: const Color(0xFF3A2D5C));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final o = Offset(20 + x * 20, 20 + y * 20);
          final col = _pal[(x * 3 + y * 5 + v) % 5];
          final path = Path()
            ..moveTo(o.dx, o.dy - 8)
            ..lineTo(o.dx + 8, o.dy - 2)
            ..lineTo(o.dx + 5, o.dy + 8)
            ..lineTo(o.dx - 5, o.dy + 8)
            ..lineTo(o.dx - 8, o.dy - 2)
            ..close();
          c.drawPath(path.shift(const Offset(0, 1.3)), _p(Colors.black38));
          c.drawPath(path, _p(col));
          c.drawPath(
              Path()
                ..moveTo(o.dx, o.dy - 8)
                ..lineTo(o.dx + 8, o.dy - 2)
                ..lineTo(o.dx, o.dy + 1)
                ..close(),
              _p(Colors.white.withValues(alpha: 0.3)));
        }
      }
    case 'tubes':
      _bg(c, seed);
      for (var t = 0; t < 4; t++) {
        final r = RRect.fromRectAndCorners(Rect.fromLTWH(14 + t * 19, 22, 14, 60),
            bottomLeft: const Radius.circular(7), bottomRight: const Radius.circular(7));
        c.drawRRect(r, _p(Colors.white.withValues(alpha: 0.22)));
        for (var i = 0; i < 3; i++) {
          final col = _pal[(t * 2 + i + v) % 5];
          if (v == 1) {
            _stone(c, Offset(21 + t * 19, 75 - i * 13), 5.5, col);
          } else {
            c.drawRRect(
                RRect.fromRectAndCorners(Rect.fromLTWH(15 + t * 19, 70 - i * 13 + (t == 3 ? 13 : 0), 12, 11),
                    bottomLeft: Radius.circular(i == 0 ? 6 : 0), bottomRight: Radius.circular(i == 0 ? 6 : 0)),
                _p(col));
          }
        }
        c.drawRRect(r, _stroke(Colors.white, 1.4));
      }
    case 'maze':
      _bg(c, seed);
      final p = _stroke(Colors.white, 3.5);
      final path = Path()
        ..moveTo(16, 16)
        ..lineTo(84, 16)
        ..lineTo(84, 84)
        ..lineTo(30, 84)
        ..moveTo(16, 16)
        ..lineTo(16, 84)
        ..moveTo(30, 30)
        ..lineTo(70, 30)
        ..lineTo(70, 70)
        ..moveTo(30, 30)
        ..lineTo(30, 70)
        ..lineTo(55, 70)
        ..moveTo(44, 44)
        ..lineTo(56, 44)
        ..lineTo(56, 56);
      c.drawPath(path, p);
      c.drawPath(
          Path()
            ..moveTo(23, 90)
            ..lineTo(23, 23)
            ..lineTo(77, 23)
            ..lineTo(77, 77)
            ..lineTo(63, 77),
          _stroke(const Color(0xFFFFD166), 2.5));
      _stone(c, const Offset(63, 77), 4.5, const Color(0xFFFFD166));
    case 'pipes':
      _bg(c, seed);
      final p = _stroke(const Color(0xFF9ED8F5), 7);
      c.drawPath(
          Path()
            ..moveTo(12, 30)
            ..lineTo(40, 30)
            ..arcToPoint(const Offset(50, 40), radius: const Radius.circular(10))
            ..lineTo(50, 60)
            ..arcToPoint(const Offset(60, 70), radius: const Radius.circular(10), clockwise: false)
            ..lineTo(88, 70),
          p);
      c.drawPath(
          Path()
            ..moveTo(12, 30)
            ..lineTo(40, 30)
            ..arcToPoint(const Offset(50, 40), radius: const Radius.circular(10))
            ..lineTo(50, 52),
          _stroke(const Color(0xFF1E88C7), 4));
    case 'shelf':
      _bg(c, seed);
      for (var s = 0; s < 2; s++) {
        final y = 46.0 + s * 34;
        c.drawRect(Rect.fromLTWH(8, y, 84, 4), _p(_wood));
        for (var i = 0; i < 6; i++) {
          final col = _pal[(i ~/ 2 + s * 2 + v) % 6];
          final r = RRect.fromRectAndRadius(Rect.fromLTWH(12 + i * 13.5, y - 22, 11, 22), const Radius.circular(3));
          c.drawRRect(r, _p(col));
          c.drawRect(Rect.fromLTWH(r.left + 1.5, r.top + 7, 8, 6), _p(Colors.white.withValues(alpha: 0.75)));
        }
      }
    case 'pairs':
      _bg(c, seed);
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          final r = RRect.fromRectAndRadius(Rect.fromLTWH(14 + x * 25, 14 + y * 25, 21, 21), const Radius.circular(4));
          _shadowRRect(c, r, dy: 1.4);
          final open = (x + y * 3) % 4 == 0;
          c.drawRRect(r, _p(open ? Colors.white : Color.lerp(seed, Colors.black, 0.25)!));
          if (open) {
            _stone(c, r.center, 5.5, _pal[1]);
          } else {
            c.drawRRect(r.deflate(3), _stroke(Colors.white38, 1));
          }
        }
      }
    case 'lens':
      _bg(c, seed);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 20, 38, 50), const Radius.circular(4)), _p(Colors.white));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(52, 20, 38, 50), const Radius.circular(4)), _p(Colors.white));
      for (final dx in [10.0, 52.0]) {
        c.drawCircle(Offset(dx + 12, 34), 6, _p(const Color(0xFFF2A93B)));
        c.drawRect(Rect.fromLTWH(dx + 6, 52, 26, 12), _p(const Color(0xFF3BA776)));
      }
      c.drawCircle(const Offset(80, 34), 6, _p(const Color(0xFF3075C4)));
      c.drawCircle(const Offset(72, 62), 13, _stroke(Colors.white, 3));
      c.drawCircle(const Offset(72, 62), 13, _stroke(_ink, 1.6));
      c.drawLine(const Offset(81, 71), const Offset(92, 82), _stroke(_ink, 4));
    case 'chain':
      _bg(c, seed, tint: const Color(0xFF26402F));
      final path = Path();
      for (var i = 0; i <= 40; i++) {
        final a = i / 40 * math.pi * 3.2;
        final rr = 38 - i * 0.65;
        final p = Offset(50 + math.cos(a) * rr, 52 + math.sin(a) * rr);
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, _stroke(Colors.black26, 9));
      for (var i = 0; i < 14; i++) {
        final a = i / 40 * math.pi * 3.2 * 2.4;
        final rr = 38 - i * 0.65 * 2.4;
        _stone(c, Offset(50 + math.cos(a) * rr, 52 + math.sin(a) * rr), 4.6, _pal[(i ~/ 2) % 5]);
      }
    case 'fruit':
      _bg(c, seed, tint: const Color(0xFF6B4C8A));
      final jar = RRect.fromRectAndCorners(const Rect.fromLTWH(14, 26, 72, 62),
          bottomLeft: const Radius.circular(10), bottomRight: const Radius.circular(10));
      c.drawRRect(jar, _p(Colors.white.withValues(alpha: 0.18)));
      for (final (x, y, r, i) in const [(28.0, 76.0, 10.0, 0), (50.0, 74.0, 12.0, 2), (72.0, 76.0, 9.0, 3), (38.0, 56.0, 8.0, 1), (62.0, 54.0, 11.0, 6)]) {
        _stone(c, Offset(x, y), r, _pal[i]);
        c.drawLine(Offset(x, y - r), Offset(x + 2, y - r - 4), _stroke(const Color(0xFF5B8C3A), 1.6));
      }
      c.drawRRect(jar, _stroke(Colors.white70, 1.6));
    case 'pins': // somun/vida
      _bg(c, seed);
      for (var i = 0; i < 3; i++) {
        final x = 25.0 + i * 25;
        c.drawRect(Rect.fromLTWH(x - 2, 30, 4, 52), _p(const Color(0xFF9AA3AF)));
        for (var j = 0; j < 3; j++) {
          final r = RRect.fromRectAndRadius(Rect.fromLTWH(x - 10, 70 - j * 12, 20, 9), const Radius.circular(3));
          c.drawRRect(r.shift(const Offset(0, 1.2)), _p(Colors.black26));
          c.drawRRect(r, _p(_pal[(i + j + v) % 5]));
        }
      }
    case 'map':
      _bg(c, seed, tint: const Color(0xFF2C6E91));
      final land = Path()
        ..moveTo(18, 40)
        ..cubicTo(25, 20, 50, 18, 62, 28)
        ..cubicTo(80, 30, 88, 50, 78, 66)
        ..cubicTo(66, 86, 36, 84, 26, 70)
        ..cubicTo(14, 60, 12, 50, 18, 40)
        ..close();
      c.drawPath(land, _p(const Color(0xFF8BBF6A)));
      c.drawLine(const Offset(50, 22), const Offset(46, 82), _stroke(Colors.white70, 1.2));
      c.drawLine(const Offset(18, 52), const Offset(82, 46), _stroke(Colors.white70, 1.2));
      for (final (x, y, i) in const [(34.0, 40.0, 0), (64.0, 42.0, 1), (36.0, 68.0, 3), (64.0, 68.0, 2)]) {
        c.drawRect(Rect.fromLTWH(x - 4, y - 4, 8, 8), _p(_pal[i]));
      }
    case 'war': // kart savaşı / blöf: kapalı deste
      _bg(c, seed, tint: _felt);
      for (var i = 0; i < 4; i++) {
        drawCard(c, Offset(36 + i * 1.5, 54 - i * 1.5), 30, -0.1, back: true);
      }
      drawCard(c, const Offset(64, 50), 30, 0.12, rank: cover.label.isEmpty ? 'K' : cover.label, suit: v);
    default:
      _bg(c, seed);
      _text(c, cover.label.isEmpty ? '?' : cover.label, const Offset(50, 50), 40, Colors.white);
  }
}

void _die(Canvas c, Offset o, double s, int n, double a) {
  c.save();
  c.translate(o.dx, o.dy);
  c.rotate(a);
  final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s, height: s), Radius.circular(s * 0.2));
  _shadowRRect(c, r, dy: s * 0.07);
  c.drawRRect(r, _p(Colors.white));
  c.drawRRect(r, _stroke(Colors.black.withValues(alpha: 0.15), s * 0.03));
  final q = s * 0.26;
  const pos = {
    1: [(0, 0)],
    2: [(-1, -1), (1, 1)],
    3: [(-1, -1), (0, 0), (1, 1)],
    4: [(-1, -1), (1, -1), (-1, 1), (1, 1)],
    5: [(-1, -1), (1, -1), (0, 0), (-1, 1), (1, 1)],
    6: [(-1, -1), (1, -1), (-1, 0), (1, 0), (-1, 1), (1, 1)],
  };
  for (final (x, y) in pos[n.clamp(1, 6)]!) {
    c.drawCircle(Offset(x * q, y * q), s * 0.085, _p(n == 1 ? _red : _ink));
  }
  c.restore();
}

void _chessPawn(Canvas c, Offset o, double s, Color col) {
  final p = _p(col);
  final edge = _stroke(col == _ink ? Colors.white54 : _ink, s * 0.04);
  final path = Path()
    ..addOval(Rect.fromCircle(center: o + Offset(0, -s * 0.22), radius: s * 0.14))
    ..moveTo(o.dx - s * 0.1, o.dy - s * 0.1)
    ..lineTo(o.dx - s * 0.2, o.dy + s * 0.2)
    ..lineTo(o.dx + s * 0.2, o.dy + s * 0.2)
    ..lineTo(o.dx + s * 0.1, o.dy - s * 0.1)
    ..close()
    ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: o + Offset(0, s * 0.25), width: s * 0.5, height: s * 0.1), Radius.circular(s * 0.03)));
  c.drawPath(path.shift(const Offset(0, 1)), _p(Colors.black26));
  c.drawPath(path, p);
  c.drawPath(path, edge);
}

void _chessKing(Canvas c, Offset o, double s, Color col) {
  final path = Path()
    ..moveTo(o.dx - s * 0.2, o.dy + s * 0.3)
    ..lineTo(o.dx - s * 0.16, o.dy - s * 0.12)
    ..quadraticBezierTo(o.dx, o.dy - s * 0.26, o.dx + s * 0.16, o.dy - s * 0.12)
    ..lineTo(o.dx + s * 0.2, o.dy + s * 0.3)
    ..close()
    ..addRect(Rect.fromCenter(center: o + Offset(0, -s * 0.34), width: s * 0.06, height: s * 0.2))
    ..addRect(Rect.fromCenter(center: o + Offset(0, -s * 0.36), width: s * 0.18, height: s * 0.06));
  c.drawPath(path.shift(const Offset(0, 1)), _p(Colors.black26));
  c.drawPath(path, _p(col));
  c.drawPath(path, _stroke(col == _ink ? Colors.white54 : _ink, s * 0.035));
}

void _chessKnight(Canvas c, Offset o, double s, Color col) {
  final path = Path()
    ..moveTo(o.dx - s * 0.2, o.dy + s * 0.32)
    ..lineTo(o.dx - s * 0.1, o.dy - s * 0.05)
    ..lineTo(o.dx - s * 0.24, o.dy - s * 0.02)
    ..lineTo(o.dx - s * 0.2, o.dy - s * 0.18)
    ..quadraticBezierTo(o.dx - s * 0.05, o.dy - s * 0.42, o.dx + s * 0.12, o.dy - s * 0.3)
    ..quadraticBezierTo(o.dx + s * 0.26, o.dy - s * 0.05, o.dx + s * 0.2, o.dy + s * 0.32)
    ..close();
  c.drawPath(path.shift(const Offset(0, 1)), _p(Colors.black26));
  c.drawPath(path, _p(col));
  c.drawPath(path, _stroke(col == _ink ? Colors.white54 : _ink, s * 0.035));
  c.drawCircle(o + Offset(-s * 0.04, -s * 0.2), s * 0.03, _p(col == _ink ? Colors.white : _ink));
}
