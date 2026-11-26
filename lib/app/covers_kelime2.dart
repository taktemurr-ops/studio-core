part of 'covers.dart';

/// Kelime Oyunları merkezinde aynı temel kapağı paylaşan oyunlara verilen
/// özgün kapaklar. Her tür tek bir oyunun mekaniğini çizer; [GameCover.label]
/// doluysa taşlardaki harfler oradan alınır. Merkezin mor-çivit paletine uygun
/// zeminler (vektör, dış görsel yok). Döndürür: çizildiyse true.
bool _paintKelime2Cover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  const paper = Color(0xFFF7F1E6);
  const edge = Color(0xFFD9CBB3);
  const pink = Color(0xFFFF5BC8);
  const blue = Color(0xFF1FA2F2);
  const gold = Color(0xFFFFC93C);
  const green = Color(0xFF4F9A6E);
  const red = Color(0xFFE2574C);

  void tile(Offset o, double s, String ch, {Color fill = paper, Color ink = _ink, double rot = 0}) {
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(rot);
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: s, height: s), Radius.circular(s * 0.18));
    c.drawRRect(r.shift(Offset(0, s * 0.08)), _p(Colors.black26));
    c.drawRRect(r, _p(fill));
    c.drawRRect(r, _stroke(edge, 0.6));
    if (ch.isNotEmpty) _text(c, ch, Offset.zero, s * 0.58, ink);
    c.restore();
  }

  void clock(Offset o, double r, Color ring) {
    c.drawCircle(o, r, _p(Colors.white));
    c.drawCircle(o, r, _stroke(ring, r * 0.18));
    c.drawLine(o, o + Offset(0, -r * 0.6), _stroke(_ink, r * 0.15));
    c.drawLine(o, o + Offset(r * 0.45, r * 0.2), _stroke(_ink, r * 0.15));
    c.drawRect(Rect.fromCenter(center: o + Offset(0, -r - 1.6), width: r * 0.5, height: 2.4), _p(ring));
  }

  void check(Offset o, double s, Color col) {
    c.drawCircle(o, s, _p(col));
    c.drawPath(
        Path()
          ..moveTo(o.dx - s * 0.45, o.dy)
          ..lineTo(o.dx - s * 0.1, o.dy + s * 0.38)
          ..lineTo(o.dx + s * 0.5, o.dy - s * 0.35),
        _stroke(Colors.white, s * 0.28));
  }

  void cross(Offset o, double s, Color col) {
    c.drawCircle(o, s, _p(col));
    final w = _stroke(Colors.white, s * 0.28);
    c.drawLine(o + Offset(-s * 0.38, -s * 0.38), o + Offset(s * 0.38, s * 0.38), w);
    c.drawLine(o + Offset(s * 0.38, -s * 0.38), o + Offset(-s * 0.38, s * 0.38), w);
  }

  String word(String def) => cover.label.isEmpty ? def : cover.label;

  switch (cover.kind) {
    case 'countdownc': // Harf ve Sayı Yarışı: harf sırası, sayı kartları, hedef sayı ve saat
      _bg(c, seed, tint: const Color(0xFF1B2F6B));
      final w = word('KALEMLIK');
      for (var i = 0; i < 6; i++) {
        tile(Offset(14 + i * 14.4, 20), 12.5, w[i % w.length], fill: i < 4 ? paper : const Color(0xFFE6DDF7));
      }
      const nums = ['25', '7', '3', '100', '6'];
      for (var i = 0; i < nums.length; i++) {
        final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(14 + i * 15.0, 46), width: 13, height: 15),
            const Radius.circular(3));
        c.drawRRect(r.shift(const Offset(0, 1.2)), _p(Colors.black26));
        c.drawRRect(r, _p(blue));
        _text(c, nums[i], r.center, nums[i].length > 2 ? 5.5 : 7.5, Colors.white);
      }
      final target = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 62, 52, 26), const Radius.circular(5));
      c.drawRRect(target, _p(_ink));
      c.drawRRect(target, _stroke(gold, 1.4));
      _text(c, '${527 + v * 111}', target.center, 15, gold);
      clock(const Offset(80, 74), 12, pink);
    case 'fourguessc': // Dört Harf çeşit paketi: dört küçük tahmin tahtası
      _bg(c, seed, tint: const Color(0xFF2A1F5C));
      const fills = [green, Color(0xFFD9A441), Color(0xFF7B8494)];
      for (var b = 0; b < 4; b++) {
        final ox = 10.0 + (b % 2) * 42;
        final oy = 10.0 + (b ~/ 2) * 42;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(ox - 2, oy - 2, 40, 40), const Radius.circular(5)),
            _p(Colors.white.withValues(alpha: 0.1)));
        for (var y = 0; y < 4; y++) {
          for (var x = 0; x < 4; x++) {
            final solved = y == b % 4 && b != 3;
            final col = y > b % 4 + (b == 3 ? 1 : 0)
                ? Colors.white.withValues(alpha: 0.15)
                : (solved ? green : fills[(x * 2 + y + b + v) % 3]);
            c.drawRRect(
                RRect.fromRectAndRadius(Rect.fromLTWH(ox + x * 9.2, oy + y * 9.2, 8, 8), const Radius.circular(1.6)), _p(col));
          }
        }
      }
      c.drawCircle(const Offset(50, 50), 8, _p(pink));
      _text(c, '4', const Offset(50, 50), 10, Colors.white);
    case 'acrostc': // Akrostiş: dikey baş harfler gizli kelimeyi yazar
      _bg(c, seed, tint: const Color(0xFF4B1E78));
      final w = word('KALEM');
      final n = math.min(5, w.length);
      for (var i = 0; i < n; i++) {
        final y = 16.0 + i * 17;
        tile(Offset(18, y), 14, w[i], fill: gold);
        for (var k = 0; k < 3 + (i * 2 + v) % 3; k++) {
          tile(Offset(33 + k * 13.0, y), 11.5, '', fill: paper);
        }
      }
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(9, 7, 18, 86), const Radius.circular(6)), _stroke(pink, 2));
      c.drawPath(
          Path()
            ..moveTo(18, 95)
            ..lineTo(14, 90)
            ..lineTo(22, 90)
            ..close(),
          _p(pink));
    case 'wordduelc': // Kelime Düellosu: iki oyuncu, ortak harfler, skorlar
      _bg(c, seed, tint: const Color(0xFF2B1660));
      void player(Offset o, Color col, int score) {
        c.drawCircle(o, 11, _p(col));
        c.drawCircle(o + const Offset(0, -3), 4, _p(Colors.white));
        c.drawPath(
            Path()
              ..moveTo(o.dx - 7, o.dy + 8)
              ..quadraticBezierTo(o.dx, o.dy - 2, o.dx + 7, o.dy + 8),
            _p(Colors.white));
        final b = RRect.fromRectAndRadius(Rect.fromCenter(center: o + const Offset(0, 18), width: 20, height: 10),
            const Radius.circular(5));
        c.drawRRect(b, _p(Colors.white));
        _text(c, '$score', b.center, 7, _ink);
      }

      player(const Offset(18, 22), blue, 42 + v);
      player(const Offset(82, 22), pink, 37 + v);
      c.drawCircle(const Offset(50, 24), 10, _p(gold));
      _text(c, 'VS', const Offset(50, 24), 8, _ink);
      final w = word('DUELLO');
      for (var i = 0; i < 6; i++) {
        final a = math.pi + i * math.pi / 5;
        tile(Offset(50 + math.cos(a) * 34, 76 + math.sin(a) * 14), 12, w[i % w.length], rot: (i - 2.5) * 0.08);
      }
    case 'antonymc': // Eş ve Zıt: iki sütun, eş anlam (=) yeşil, zıt anlam (↔) kırmızı
      _bg(c, seed, tint: const Color(0xFF3C2470));
      for (var i = 0; i < 3; i++) {
        final y = 22.0 + i * 25;
        final same = (i + v).isEven;
        final l = RRect.fromRectAndRadius(Rect.fromLTWH(8, y - 8, 30, 16), const Radius.circular(8));
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(62, y - 8, 30, 16), const Radius.circular(8));
        c.drawRRect(l, _p(paper));
        c.drawRRect(r, _p(paper));
        for (final rr in [l, r]) {
          for (var k = 0; k < 3; k++) {
            c.drawLine(Offset(rr.left + 6 + k * 7, y), Offset(rr.left + 10 + k * 7, y), _stroke(_ink, 2));
          }
        }
        final badge = Offset(50, y);
        c.drawCircle(badge, 8, _p(same ? green : red));
        _text(c, same ? '=' : '≠', badge, 10, Colors.white);
      }
      // Güneş / ay ikilisi (zıt kavram simgesi)
      c.drawCircle(const Offset(30, 88), 6, _p(gold));
      c.drawCircle(const Offset(70, 88), 6, _p(const Color(0xFFE8E6F5)));
      c.drawCircle(const Offset(73, 86), 5.2, _p(const Color(0xFF3C2470)));
      c.drawLine(const Offset(40, 88), const Offset(60, 88), _stroke(Colors.white70, 1.4));
    case 'spellc': // Doğru Yazım: iki yazım seçeneği, biri onaylı, kalem
      _bg(c, seed, tint: const Color(0xFF1E3C72));
      final good = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 18, 64, 22), const Radius.circular(6));
      final bad = RRect.fromRectAndRadius(const Rect.fromLTWH(10, 50, 64, 22), const Radius.circular(6));
      c.drawRRect(good, _p(paper));
      c.drawRRect(good, _stroke(green, 2));
      c.drawRRect(bad, _p(paper.withValues(alpha: 0.8)));
      _text(c, 'HERKES', good.center, 11, _ink);
      _text(c, 'HERKEZ', bad.center, 11, const Color(0xFF7B8494));
      c.drawLine(Offset(bad.left + 8, bad.center.dy), Offset(bad.right - 8, bad.center.dy), _stroke(red, 1.8));
      check(const Offset(84, 29), 8, green);
      cross(const Offset(84, 61), 8, red);
      // Kalem
      c.save();
      c.translate(56, 86);
      c.rotate(-0.5);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-22, -3.5, 36, 7), const Radius.circular(1.5)), _p(gold));
      c.drawRect(const Rect.fromLTWH(-26, -3.5, 4, 7), _p(pink));
      c.drawPath(
          Path()
            ..moveTo(14, -3.5)
            ..lineTo(21, 0)
            ..lineTo(14, 3.5)
            ..close(),
          _p(const Color(0xFFF1D3A3)));
      c.drawCircle(const Offset(20, 0), 1, _p(_ink));
      c.restore();
    case 'cryptoc': // Kriptogram: harflerin altında sayılar, anahtar
      _bg(c, seed, tint: const Color(0xFF2A1B4E));
      final w = word('SIRLAR');
      const codes = [14, 9, 21, 3, 1, 21];
      for (var row = 0; row < 2; row++) {
        for (var i = 0; i < 5; i++) {
          final o = Offset(14 + i * 15.5, 26 + row * 30.0);
          final known = (i + row + v) % 3 != 1;
          final r = Rect.fromCenter(center: o, width: 13, height: 15);
          c.drawRect(r, _p(known ? paper : Colors.white.withValues(alpha: 0.12)));
          c.drawLine(Offset(r.left, r.bottom + 2), Offset(r.right, r.bottom + 2), _stroke(Colors.white70, 1));
          if (known) _text(c, w[(i + row * 2) % w.length], o, 9, _ink);
          _text(c, '${codes[(i + row) % codes.length]}', o + const Offset(0, 14), 6, gold);
        }
      }
      // Anahtar
      c.drawCircle(const Offset(26, 86), 6, _stroke(gold, 2.4));
      c.drawLine(const Offset(32, 86), const Offset(58, 86), _stroke(gold, 2.4));
      c.drawLine(const Offset(52, 86), const Offset(52, 91), _stroke(gold, 2.4));
      c.drawLine(const Offset(57, 86), const Offset(57, 90), _stroke(gold, 2.4));
      _text(c, '“', const Offset(80, 84), 22, pink);
    case 'blankc': // Eksik Harfler: kelimedeki boşluklara uçan taşlar
      _bg(c, seed, tint: const Color(0xFF41207A));
      final w = word('KITAPLIK');
      for (var i = 0; i < 6; i++) {
        final o = Offset(13 + i * 14.8, 48);
        final blank = i == 1 || i == 4;
        if (blank) {
          final r = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 12.5, height: 12.5), const Radius.circular(2.5));
          c.drawRRect(r, _stroke(gold, 1.6));
          c.drawLine(o + const Offset(-4, 4), o + const Offset(4, 4), _stroke(gold, 1.6));
        } else {
          tile(o, 12.5, w[i % w.length]);
        }
      }
      // Seçenek taşları ve uçuş yolu
      final choices = [w[1 % w.length], 'E', w[4 % w.length], 'U'];
      for (var i = 0; i < 4; i++) {
        tile(Offset(20 + i * 20.0, 82), 13, choices[i], fill: i == 0 ? gold : const Color(0xFFE6DDF7), rot: (i - 1.5) * 0.06);
      }
      final arc = _stroke(Colors.white70, 1.4);
      c.drawPath(
          Path()
            ..moveTo(20, 74)
            ..quadraticBezierTo(16, 62, 27.8, 57),
          arc);
      c.drawPath(
          Path()
            ..moveTo(60, 74)
            ..quadraticBezierTo(66, 64, 72, 57),
          arc);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 12, 40, 16), const Radius.circular(8)), _p(pink));
      _text(c, '_ ? _', const Offset(50, 20), 9, Colors.white);
    case 'boggc': // Harf Izgarası: zar küpleri, komşu harfleri birleştiren yol
      _bg(c, seed, tint: const Color(0xFF243A7A));
      final w = word('HARFIZGARASI');
      const path = [(0, 0), (1, 1), (2, 1), (3, 2), (2, 3)];
      final centers = <Offset>[];
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final o = Offset(20 + x * 20.0, 20 + y * 20.0);
          final on = path.contains((x, y));
          final r = RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 17, height: 17), const Radius.circular(4));
          c.drawRRect(r.shift(const Offset(1.2, 1.8)), _p(const Color(0xFF9A8E74)));
          c.drawRRect(r, _p(on ? const Color(0xFFFFE8A3) : paper));
          c.drawCircle(o, 6.8, _stroke(Colors.black12, 0.8));
          _text(c, w[(y * 4 + x + v) % w.length], o, 9, _ink);
        }
      }
      for (final (x, y) in path) {
        centers.add(Offset(20 + x * 20.0, 20 + y * 20.0));
      }
      final pp = Path()..moveTo(centers.first.dx, centers.first.dy);
      for (final o in centers.skip(1)) {
        pp.lineTo(o.dx, o.dy);
      }
      c.drawPath(pp, _stroke(pink.withValues(alpha: 0.85), 3.2));
      for (final o in centers) {
        c.drawCircle(o, 2.2, _p(pink));
      }
    case 'slidecolc': // Harf Kaydırma: yukarı-aşağı dönen sütunlar, ortada kelime bandı
      _bg(c, seed, tint: const Color(0xFF331A68));
      final w = word('KAYDIR');
      const alphabet = 'AEKLMNRST';
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, 42, 88, 18), const Radius.circular(5)), _p(gold.withValues(alpha: 0.9)));
      for (var x = 0; x < 5; x++) {
        final off = ((x * 7 + v) % 3 - 1) * 4.0;
        for (var y = 0; y < 5; y++) {
          final o = Offset(16 + x * 17.0, 17 + y * 17.0 + off);
          final mid = y == 2;
          tile(o, 13.5, mid ? w[x % w.length] : alphabet[(x * 3 + y * 5) % alphabet.length],
              fill: mid ? paper : const Color(0xFFD7CCEF));
        }
        // Sütun okları
        if (x.isEven) {
          c.drawPath(
              Path()
                ..moveTo(16 + x * 17.0 - 3, 6)
                ..lineTo(16 + x * 17.0, 2)
                ..lineTo(16 + x * 17.0 + 3, 6),
              _stroke(Colors.white, 1.4));
        } else {
          c.drawPath(
              Path()
                ..moveTo(16 + x * 17.0 - 3, 94)
                ..lineTo(16 + x * 17.0, 98)
                ..lineTo(16 + x * 17.0 + 3, 94),
              _stroke(Colors.white, 1.4));
        }
      }
    case 'wordblockc': // Kelime Blokları: kutuda kayan kelime blokları, temizlenen satır
      _bg(c, seed, tint: const Color(0xFF1F2F66));
      final frame = RRect.fromRectAndRadius(const Rect.fromLTWH(12, 8, 76, 86), const Radius.circular(4));
      c.drawRRect(frame, _p(Colors.black.withValues(alpha: 0.22)));
      c.drawRRect(frame, _stroke(Colors.white38, 1.2));
      void block(double x, double y, String s, Color col) {
        final r = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, s.length * 9.0 + 2, 11), const Radius.circular(3));
        c.drawRRect(r.shift(const Offset(0, 1)), _p(Colors.black26));
        c.drawRRect(r, _p(col));
        for (var i = 0; i < s.length; i++) {
          _text(c, s[i], Offset(x + 5.5 + i * 9.0, y + 5.5), 7.5, Colors.white);
        }
      }

      block(16, 80, 'ELMA', blue);
      block(54, 80, 'SU', green);
      block(16, 68, 'AY', pink);
      block(40, 68, 'KUŞ', const Color(0xFF9B6CFF));
      block(30, 56, 'GÜL', const Color(0xFFFF7A45));
      // Kayan blok ve ok
      block(46, 22, 'DAL', gold);
      c.drawLine(const Offset(60, 37), const Offset(60, 48), _stroke(Colors.white70, 1.6));
      c.drawPath(
          Path()
            ..moveTo(56, 45)
            ..lineTo(60, 50)
            ..lineTo(64, 45),
          _stroke(Colors.white70, 1.6));
      // Temizlenen satır parıltısı
      c.drawLine(const Offset(14, 92), const Offset(86, 92), _stroke(gold, 1.6));
    case 'wordsqc': // Kelime Kafesi: satır ve sütunların hepsi kelime
      _bg(c, seed, tint: const Color(0xFF4A2380));
      const sq = ['KALE', 'ASİL', 'LİMA', 'ELAN'];
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final o = Offset(24 + x * 17.0, 24 + y * 17.0);
          final hl = y == (v % 4) || x == (v % 4);
          tile(o, 15, sq[y][x], fill: hl ? const Color(0xFFFFE8A3) : paper);
        }
      }
      // Satır ve sütun okları (iki yönde de kelime)
      final a = _stroke(pink, 2);
      for (var i = 0; i < 4; i++) {
        c.drawLine(Offset(88, 24 + i * 17.0), Offset(95, 24 + i * 17.0), a);
        c.drawLine(Offset(24 + i * 17.0, 88), Offset(24 + i * 17.0, 95), a);
      }
      c.drawRect(const Rect.fromLTWH(14.5, 14.5, 68, 68), _stroke(Colors.white, 1.2));
    case 'arrowwordc': // Kare Bulmaca: oklu ipucu kutuları
      _bg(c, seed, tint: const Color(0xFF2C2168));
      const clue = Color(0xFF5B3FB0);
      const layout = ['C.C..', '.....', 'C....', '..C..', 'C....'];
      for (var y = 0; y < 5; y++) {
        for (var x = 0; x < 5; x++) {
          final r = Rect.fromLTWH(12 + x * 15.2, 12 + y * 15.2, 15, 15);
          final isClue = layout[y][x] == 'C';
          c.drawRect(r, _p(isClue ? clue : paper));
          c.drawRect(r, _stroke(_ink, 0.6));
          if (isClue) {
            for (var k = 0; k < 3; k++) {
              c.drawLine(Offset(r.left + 3, r.top + 4 + k * 3.2), Offset(r.right - 3 - k * 2, r.top + 4 + k * 3.2),
                  _stroke(Colors.white70, 1));
            }
            // Ok: sağa ya da aşağı
            final right = (x + y + v).isEven;
            final tip = right ? Offset(r.right + 4, r.center.dy) : Offset(r.center.dx, r.bottom + 4);
            final p = right
                ? (Path()
                  ..moveTo(tip.dx - 3.5, tip.dy - 2.5)
                  ..lineTo(tip.dx, tip.dy)
                  ..lineTo(tip.dx - 3.5, tip.dy + 2.5)
                  ..close())
                : (Path()
                  ..moveTo(tip.dx - 2.5, tip.dy - 3.5)
                  ..lineTo(tip.dx, tip.dy)
                  ..lineTo(tip.dx + 2.5, tip.dy - 3.5)
                  ..close());
            c.drawPath(p, _p(pink));
          } else if ((x * 3 + y) % 4 == 1) {
            _text(c, 'AEİLMR'[(x + y) % 6], r.center, 8.5, _ink);
          }
        }
      }
    case 'codewordc': // Şifreli Bulmaca: köşesinde sayı olan kareler, altta çözüm anahtarı
      _bg(c, seed, tint: const Color(0xFF1A3A5E));
      const pattern = ['1101', '1111', '0111', '1110'];
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          final r = Rect.fromLTWH(14 + x * 18.0, 8 + y * 16.0, 17, 15);
          final on = pattern[y][x] == '1';
          c.drawRect(r, _p(on ? paper : _ink));
          if (!on) continue;
          final n = (x * 5 + y * 3 + v) % 9 + 1;
          _text(c, '$n', r.topLeft + const Offset(3.4, 3.4), 4.8, const Color(0xFF3E6FB0));
          if (n % 3 == 0) _text(c, 'ARKE'[n % 4], r.center + const Offset(1.5, 1.5), 8, _ink);
        }
      }
      // Anahtar şeridi: 1-9 sayı/harf eşleri
      final strip = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 76, 88, 18), const Radius.circular(4));
      c.drawRRect(strip, _p(Colors.white.withValues(alpha: 0.9)));
      for (var i = 0; i < 6; i++) {
        final o = Offset(14 + i * 14.4, 85);
        _text(c, '${i + 1}', o + const Offset(0, -4.2), 4.8, const Color(0xFF3E6FB0));
        _text(c, i % 2 == 0 ? 'AKRE'[i ~/ 2 % 4] : '·', o + const Offset(0, 2.4), 7, _ink);
      }
    case 'wordpilec': // Kelime Yığını: üst üste yığılmış harf taşları ve kum saati
      _bg(c, seed, tint: const Color(0xFF3D1B6E));
      final w = word('YIGINLAR');
      const pile = [
        [24.0, 82.0, -0.1], [38.0, 84.0, 0.05], [52.0, 83.0, -0.04], [66.0, 84.0, 0.12],
        [31.0, 70.0, 0.15], [45.0, 71.0, -0.08], [59.0, 70.0, 0.06], [38.0, 58.0, -0.12],
        [52.0, 58.0, 0.1], [45.0, 46.0, 0.02],
      ];
      for (var i = 0; i < pile.length; i++) {
        final p = pile[i];
        final hl = i == 9 || i == 7 || i == 8;
        tile(Offset(p[0], p[1]), 13, w[i % w.length], rot: p[2], fill: hl ? gold : paper);
      }
      // Kum saati
      final glass = Path()
        ..moveTo(76, 14)
        ..lineTo(92, 14)
        ..lineTo(84, 28)
        ..lineTo(92, 42)
        ..lineTo(76, 42)
        ..lineTo(84, 28)
        ..close();
      c.drawPath(glass, _p(Colors.white.withValues(alpha: 0.85)));
      c.drawPath(
          Path()
            ..moveTo(79, 18)
            ..lineTo(89, 18)
            ..lineTo(84, 26)
            ..close(),
          _p(gold));
      c.drawPath(
          Path()
            ..moveTo(80, 42)
            ..lineTo(88, 42)
            ..lineTo(84, 35)
            ..close(),
          _p(gold));
      c.drawLine(const Offset(74, 13), const Offset(94, 13), _stroke(_wood, 2.2));
      c.drawLine(const Offset(74, 43), const Offset(94, 43), _stroke(_wood, 2.2));
      // Toplanan kelime rozeti
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 12, 46, 16), const Radius.circular(8)), _p(pink));
      _text(c, '+${3 + v} ★', const Offset(31, 20), 8, Colors.white);
    case 'anagramc': // Anagram Yarışı: karışık harfler, karıştırma okları, kronometre
      _bg(c, seed, tint: const Color(0xFF52206E));
      final w = word('ANAGRAM');
      final n = math.min(6, w.length);
      for (var i = 0; i < n; i++) {
        final j = (i * 4 + 1 + v) % n;
        tile(Offset(16 + i * 13.6, 40 + (i.isEven ? -4 : 4)), 12, w[j], rot: (i.isEven ? -1 : 1) * 0.18);
      }
      for (var i = 0; i < n; i++) {
        tile(Offset(16 + i * 13.6, 76), 12, i < 3 ? w[i] : '', fill: i < 3 ? gold : Colors.white.withValues(alpha: 0.25));
      }
      final arr = _stroke(Colors.white, 1.6);
      c.drawArc(Rect.fromCenter(center: const Offset(50, 58), width: 40, height: 14), math.pi * 0.15, math.pi * 0.7, false, arr);
      c.drawPath(
          Path()
            ..moveTo(30, 59)
            ..lineTo(33.5, 63.5)
            ..lineTo(37, 59),
          arr);
      clock(const Offset(84, 16), 9, pink);
      c.drawArc(Rect.fromCircle(center: const Offset(84, 16), radius: 7.2), -math.pi / 2, math.pi * (1.1 + v % 3 * 0.2), true,
          _p(pink.withValues(alpha: 0.35)));
    case 'wordjigc': // Kelime Yapbozu: hece parçalı yapboz taşları birleşiyor
      _bg(c, seed, tint: const Color(0xFF233B70));
      void piece(Offset o, String s, Color col, {bool knobRight = true, bool slotLeft = false, double rot = 0}) {
        c.save();
        c.translate(o.dx, o.dy);
        c.rotate(rot);
        final p = Path()..addRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-14, -10, 28, 20), const Radius.circular(3)));
        if (knobRight) p.addOval(Rect.fromCircle(center: const Offset(15.5, 0), radius: 4.6));
        var shape = p;
        if (slotLeft) {
          shape = Path.combine(PathOperation.difference, p, Path()..addOval(Rect.fromCircle(center: const Offset(-12.5, 0), radius: 4.6)));
        }
        c.drawPath(shape.shift(const Offset(0, 1.6)), _p(Colors.black26));
        c.drawPath(shape, _p(col));
        c.drawPath(shape, _stroke(Colors.white54, 0.8));
        _text(c, s, const Offset(-1, 0), 9, Colors.white);
        c.restore();
      }

      piece(const Offset(24, 30), 'KE', pink);
      piece(const Offset(52.5, 30), 'Lİ', blue, slotLeft: true);
      piece(const Offset(81, 30), 'ME', green, slotLeft: true, knobRight: false);
      piece(const Offset(30, 70), 'YAP', const Color(0xFFFF7A45), rot: -0.15);
      piece(const Offset(72, 74), 'BOZ', const Color(0xFF9B6CFF), slotLeft: true, knobRight: false, rot: 0.2);
      c.drawLine(const Offset(46, 70), const Offset(56, 72), _stroke(Colors.white70, 1.4));
      check(const Offset(50, 52), 5.5, gold);
    default:
      return false;
  }
  return true;
}
