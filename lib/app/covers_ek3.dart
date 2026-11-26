part of 'covers.dart';

/// 3. tur ek oyunların kapakları. Vektör çizim, dış görsel ve marka yok.
/// Döndürür: tür tanındıysa true.
bool _paintEk3Cover(Canvas c, GameCover cover, Color seed) {
  switch (cover.kind) {
    case 'mc_satrancbulmaca': // kuşbakışı köşe tahtası, at hamlesi oku ve mat yapboz rozeti
      _bg(c, seed, tint: const Color(0xFF1C3B5A));
      const light = Color(0xFFE9D8B4), dark = Color(0xFF5E7FA3);
      const sq = 15.0, ox = 8.0, oy = 30.0;
      final board = RRect.fromRectAndRadius(const Rect.fromLTWH(ox - 2, oy - 2, sq * 4 + 4, sq * 4 + 4), const Radius.circular(4));
      _shadowRRect(c, board, dy: 2.4);
      c.drawRRect(board, _p(const Color(0xFF2B2F3A)));
      for (var r = 0; r < 4; r++) {
        for (var k = 0; k < 4; k++) {
          c.drawRect(Rect.fromLTWH(ox + k * sq, oy + r * sq, sq, sq), _p((r + k).isEven ? light : dark));
        }
      }
      // Hedef kare: parlayan altın çerçeve.
      const target = Rect.fromLTWH(ox + 2 * sq, oy + sq, sq, sq);
      c.drawRect(target, _p(const Color(0xFFF5B82E).withValues(alpha: 0.55)));
      c.drawRect(target.deflate(1), _stroke(const Color(0xFFF5B82E), 1.6));
      // Köşeye sıkışmış siyah şah, hamle bekleyen beyaz at.
      _chessKing(c, const Offset(ox + 3.5 * sq, oy + 0.62 * sq), 15, _ink);
      _chessKnight(c, const Offset(ox + 1.5 * sq, oy + 3.55 * sq), 15, Colors.white);
      // L biçimli kesikli ok: at → hedef.
      final arrow = _stroke(const Color(0xFFFFD166), 2.2);
      const a = Offset(ox + 1.5 * sq, oy + 2.9 * sq), b = Offset(ox + 1.5 * sq, oy + 1.5 * sq), e = Offset(ox + 2.3 * sq, oy + 1.5 * sq);
      for (final (p0, p1) in const [(a, b), (b, e)]) {
        final d = p1 - p0;
        final n = (d.distance / 4).floor();
        for (var i = 0; i < n; i += 2) {
          c.drawLine(p0 + d * (i / n), p0 + d * ((i + 1) / n), arrow);
        }
      }
      c.drawPath(
          Path()
            ..addPolygon(const [Offset(ox + 2.45 * sq, oy + 1.5 * sq), Offset(ox + 2.15 * sq, oy + 1.28 * sq), Offset(ox + 2.15 * sq, oy + 1.72 * sq)], true),
          _p(const Color(0xFFFFD166)));
      // Sağ üstte yapboz parçası rozeti: "#2" (iki hamlede mat).
      final piece = Path()
        ..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(62, 8, 30, 30), const Radius.circular(5)))
        ..addOval(Rect.fromCircle(center: const Offset(77, 8), radius: 5.5))
        ..addOval(Rect.fromCircle(center: const Offset(62, 23), radius: 5.5));
      c.drawPath(piece.shift(const Offset(0, 2)), _p(Colors.black.withValues(alpha: 0.28)));
      c.drawPath(piece, _p(const Color(0xFFE2574C)));
      c.drawPath(piece, _stroke(Colors.white.withValues(alpha: 0.85), 1.4));
      _text(c, '#2', const Offset(78, 24), 14, Colors.white, w: FontWeight.w900);
      // Sağ altta ampul (ipucu).
      c.drawCircle(const Offset(82, 66), 8, _p(const Color(0xFFFFE08A)));
      c.drawCircle(const Offset(82, 66), 12, _p(const Color(0xFFFFE08A).withValues(alpha: 0.25)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(82, 77), width: 8, height: 6), const Radius.circular(1.5)),
          _p(const Color(0xFFB0B8C8)));
      return true;
    default:
      return false;
  }
}
