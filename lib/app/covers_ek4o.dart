part of 'covers.dart';

/// 4. tur kapakları: Özgün, Strateji, Boşta ve Simülasyon, Eğitici (100×100 tuval).
bool _paintEk4oCover(Canvas c, GameCover cover, Color seed) {
  final v = cover.v;
  RRect box(Offset o, double w, double h, [double r = 4]) =>
      RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: w, height: h), Radius.circular(r));
  void glyph(String s, Offset o, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: col, fontWeight: FontWeight.w800, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  }

  switch (cover.kind) {
    case 'ek4grocer': // Mahalle Bakkalı: çizgili tente, raflar, tezgâh
      _bg(c, seed, tint: const Color(0xFF2F8F6B));
      for (var k = 0; k < 6; k++) {
        c.drawRect(Rect.fromLTWH(8 + k * 14.0, 10, 14, 12), _p(k.isEven ? const Color(0xFFF5F1E6) : const Color(0xFF2F8F6B)));
      }
      c.drawRect(const Rect.fromLTWH(10, 24, 80, 52), _p(const Color(0xFFF3E3C3)));
      for (var r = 0; r < 2; r++) {
        c.drawRect(Rect.fromLTWH(14, 40.0 + r * 16, 72, 2.5), _p(const Color(0xFF8A6A4A)));
        for (var k = 0; k < 6; k++) {
          c.drawRRect(box(Offset(20 + k * 12.0, 34.0 + r * 16), 8, 10, 2),
              _p([const Color(0xFFE4572E), const Color(0xFFF2A516), const Color(0xFF4FA3D9), const Color(0xFF7DB356)][(k + r + v) % 4]));
        }
      }
      c.drawRRect(box(const Offset(50, 84), 70, 14, 3), _p(const Color(0xFF8A5A36)));
    case 'ek4village': // Kasaba Hayatı: ev, tarla, gölet, güneş
      _bg(c, seed, tint: const Color(0xFF8CC0DE));
      c.drawRect(const Rect.fromLTWH(0, 60, 100, 40), _p(const Color(0xFF7DB356)));
      c.drawCircle(const Offset(80, 20), 9, _p(const Color(0xFFFFD54A)));
      c.drawRect(const Rect.fromLTWH(14, 38, 30, 24), _p(const Color(0xFFF6E3C6)));
      c.drawPath(Path()..addPolygon(const [Offset(10, 40), Offset(29, 24), Offset(48, 40)], true), _p(const Color(0xFFC8553D)));
      c.drawRect(const Rect.fromLTWH(25, 48, 8, 14), _p(const Color(0xFF8A5A36)));
      c.drawOval(const Rect.fromLTWH(58, 66, 34, 16), _p(const Color(0xFF4FA3D9)));
      for (var k = 0; k < 4; k++) {
        c.drawRRect(box(Offset(14 + k * 11.0, 82), 9, 12, 2), _p(const Color(0xFF6B4A2E)));
        c.drawCircle(Offset(14 + k * 11.0, 78), 3, _p(const Color(0xFFE4572E)));
      }
    case 'ek4shine': // Parlat!: yarısı kirli araba, köpük ve parıltı
      _bg(c, seed, tint: const Color(0xFFDDEFF6));
      const body = Rect.fromLTWH(12, 46, 76, 22);
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(8)), _p(const Color(0xFFE4572E)));
      c.drawRRect(box(const Offset(48, 42), 40, 18, 6), _p(const Color(0xFFE4572E)));
      c.drawRRect(box(const Offset(48, 42), 32, 11, 4), _p(const Color(0xFFBFE3F2)));
      c.drawRect(const Rect.fromLTWH(12, 46, 34, 22), _p(const Color(0x997A5A3A)));
      c.drawCircle(const Offset(28, 70), 8, _p(const Color(0xFF2B2B2B)));
      c.drawCircle(const Offset(72, 70), 8, _p(const Color(0xFF2B2B2B)));
      for (final (x, y, r) in const [(20.0, 30.0, 5.0), (30.0, 24.0, 4.0), (14.0, 22.0, 3.0)]) {
        c.drawCircle(Offset(x, y), r, _p(const Color(0xCCFFFFFF)));
      }
      for (final o in const [Offset(70, 30), Offset(84, 40), Offset(62, 22)]) {
        c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy - 5)
              ..lineTo(o.dx + 1.5, o.dy - 1.5)
              ..lineTo(o.dx + 5, o.dy)
              ..lineTo(o.dx + 1.5, o.dy + 1.5)
              ..lineTo(o.dx, o.dy + 5)
              ..lineTo(o.dx - 1.5, o.dy + 1.5)
              ..lineTo(o.dx - 5, o.dy)
              ..lineTo(o.dx - 1.5, o.dy - 1.5)
              ..close(),
            _p(const Color(0xFFFFF3B0)));
      }
    case 'ek4reno': // Ev Yenileme: üstten oda planı, yerleşmiş mobilyalar
      _bg(c, seed, tint: const Color(0xFFC9A27A));
      c.drawRect(const Rect.fromLTWH(14, 14, 72, 72), _p(const Color(0xFFDCEBDD)));
      c.drawRect(const Rect.fromLTWH(14, 14, 72, 72), _stroke(const Color(0xFF5B4636), 4));
      c.drawRRect(box(const Offset(32, 34), 30, 28, 4), _p(const Color(0xFF6D9DC5)));
      c.drawRRect(box(const Offset(68, 30), 22, 20, 3), _p(const Color(0xFFE9C46A)));
      c.drawRRect(box(const Offset(66, 66), 28, 12, 3), _p(const Color(0xFFE76F51)));
      c.drawRRect(box(const Offset(28, 70), 14, 14, 3), _p(const Color(0xFF8AB17D)));
      c.drawRect(const Rect.fromLTWH(44, 84, 14, 4), _p(const Color(0xFFF3E6D0)));
    case 'ek4swarm': // Sürü Avcısı: ışık halesi, gölge yaratıklar halkası
      _bg(c, seed, tint: const Color(0xFF26314A));
      c.drawCircle(const Offset(50, 52), 22, _p(const Color(0x33FFE08A)));
      for (var k = 0; k < 9; k++) {
        final a = k * 0.7 + v * 0.3;
        final o = Offset(50 + 36 * math.cos(a), 52 + 34 * math.sin(a));
        c.drawCircle(o, 6, _p(const Color(0xCC1B1430)));
        c.drawCircle(o + const Offset(-2, -1), 1, _p(const Color(0xFFE8E0FF)));
        c.drawCircle(o + const Offset(2, -1), 1, _p(const Color(0xFFE8E0FF)));
      }
      for (var k = 0; k < 3; k++) {
        final a = k * 2.1;
        c.drawLine(const Offset(50, 52), Offset(50 + 26 * math.cos(a), 52 + 26 * math.sin(a)), _stroke(const Color(0xFFFFE08A), 2));
      }
      c.drawCircle(const Offset(50, 52), 6, _p(const Color(0xFFF4F1EA)));
      c.drawCircle(const Offset(50, 51), 2.5, _p(const Color(0xFFFFB13B)));
    case 'ek4bag': // Heybe Savaşları: ızgaralı heybe, kılıç, kalkan
      _bg(c, seed, tint: const Color(0xFF5B4636));
      c.drawRRect(box(const Offset(50, 56), 74, 52, 8), _p(const Color(0xFF8A5A36)));
      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 5; x++) {
          c.drawRRect(box(Offset(24 + x * 13.0, 42 + y * 14.0), 11, 12, 2), _p(const Color(0xFFB98A5E)));
        }
      }
      c.drawRRect(box(const Offset(24, 56), 10, 38, 2), _p(const Color(0xFF9AA3AE)));
      c.drawRRect(box(const Offset(56, 49), 24, 24, 4), _p(const Color(0xFF8C6E54)));
      c.drawCircle(const Offset(76, 70), 5, _p(const Color(0xFFD94F4F)));
      c.drawPath(Path()..addPolygon(const [Offset(30, 30), Offset(50, 14), Offset(70, 30)], true), _p(const Color(0xFF6A4228)));
    case 'ek4bounce': // Top Sekme Zindanı: sayılı taş bloklar, sekme izi
      _bg(c, seed, tint: const Color(0xFF2B2622));
      for (var r = 0; r < 3; r++) {
        for (var k = 0; k < 5; k++) {
          if ((k + r + v) % 3 == 0) continue;
          c.drawRRect(box(Offset(16 + k * 17.0, 18 + r * 14.0), 15, 12, 2), _p(const Color(0xFF8C9A7A)));
          glyph('${(k * 3 + r * 5) % 9 + 1}', Offset(16 + k * 17.0, 18 + r * 14.0), 8, Colors.white);
        }
      }
      final path = Path()
        ..moveTo(50, 92)
        ..lineTo(88, 64)
        ..lineTo(60, 50)
        ..lineTo(20, 70);
      c.drawPath(path, _stroke(const Color(0x99F4F1EA), 1.5));
      c.drawCircle(const Offset(20, 70), 3, _p(const Color(0xFFF4F1EA)));
      c.drawCircle(const Offset(50, 92), 4, _p(const Color(0xFFD9A441)));
    case 'ek4siege': // Kale Kuşatması: iki sur, üç şerit, birlikler
      _bg(c, seed, tint: const Color(0xFF5F7F4A));
      for (var l = 0; l < 3; l++) {
        c.drawRect(Rect.fromLTWH(10 + l * 28.0, 20, 24, 60), _p(const Color(0xFFB59A6E)));
      }
      void wall(double y, Color col) {
        c.drawRect(Rect.fromLTWH(6, y, 88, 10), _p(col));
        for (var i = 0; i < 9; i++) {
          c.drawRect(Rect.fromLTWH(8 + i * 10.0, y - 4, 5, 4), _p(col));
        }
      }
      wall(10, const Color(0xFFC8553D));
      wall(82, const Color(0xFF3E6FB0));
      for (final (x, y, b) in const [(22.0, 60.0, true), (50.0, 44.0, true), (78.0, 36.0, false), (22.0, 34.0, false)]) {
        c.drawCircle(Offset(x, y), 5, _p(b ? const Color(0xFF3E6FB0) : const Color(0xFFC8553D)));
        c.drawCircle(Offset(x, y), 5, _stroke(Colors.white, 1));
      }
    case 'ek4kolam': // Kolam Çizgisi: nokta ızgarası ve tek kapalı kıvrım
      _bg(c, seed, tint: const Color(0xFF3B2A4A));
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          c.drawCircle(Offset(26 + x * 16.0, 26 + y * 16.0), 2, _p(Colors.white));
        }
      }
      final loop = Path();
      for (var i = 0; i <= 64; i++) {
        final t = i / 64 * 2 * math.pi;
        final r = 30 + 8 * math.cos(4 * t);
        final o = Offset(50 + r * math.cos(t), 50 + r * math.sin(t));
        if (i == 0) {
          loop.moveTo(o.dx, o.dy);
        } else {
          loop.lineTo(o.dx, o.dy);
        }
      }
      c.drawPath(loop, _stroke(const Color(0xFFF6D365), 2.5));
    case 'ek4girih': // Girih Desenleri: on köşeli yıldız ve beşgen karolar
      _bg(c, seed, tint: const Color(0xFF1F4E8C));
      final star = Path();
      for (var i = 0; i < 20; i++) {
        final a = i * math.pi / 10 - math.pi / 2;
        final r = i.isEven ? 34.0 : 16.0;
        final o = Offset(50 + r * math.cos(a), 50 + r * math.sin(a));
        if (i == 0) {
          star.moveTo(o.dx, o.dy);
        } else {
          star.lineTo(o.dx, o.dy);
        }
      }
      star.close();
      c.drawPath(star, _p(const Color(0xFFE8C468)));
      c.drawPath(star, _stroke(const Color(0xFF0F2E57), 1.5));
      final pent = Path();
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5 - math.pi / 2;
        final o = Offset(50 + 12 * math.cos(a), 50 + 12 * math.sin(a));
        if (i == 0) {
          pent.moveTo(o.dx, o.dy);
        } else {
          pent.lineTo(o.dx, o.dy);
        }
      }
      c.drawPath(pent..close(), _p(const Color(0xFF2A9D8F)));
    case 'ek4batik': // Batik Atölyesi: mum çizgileri ve boya katmanları
      _bg(c, seed, tint: const Color(0xFF7A3E1D));
      c.drawRect(const Rect.fromLTWH(12, 14, 76, 72), _p(const Color(0xFFF2D7A6)));
      c.drawRect(const Rect.fromLTWH(12, 14, 76, 72), _p(const Color(0x66C8702E)));
      for (var k = 0; k < 3; k++) {
        final p = Path()..moveTo(14, 30.0 + k * 20);
        for (var x = 14.0; x <= 86; x += 6) {
          p.lineTo(x, 30.0 + k * 20 + 5 * math.sin(x / 6 + k));
        }
        c.drawPath(p, _stroke(const Color(0xFF3D2310), 2));
      }
      for (final o in const [Offset(30, 40), Offset(62, 58), Offset(70, 26)]) {
        c.drawCircle(o, 6, _p(const Color(0xFF2E4A7A)));
        c.drawCircle(o, 3, _p(const Color(0xFFF2D7A6)));
      }
    case 'ek4mini': // Minyatür Boyama: numaralı bölgeli çerçeve, yarısı boyalı
      _bg(c, seed, tint: const Color(0xFF8C2F39));
      c.drawRRect(box(const Offset(50, 50), 70, 70, 6), _p(const Color(0xFFF7EBD3)));
      c.drawRRect(box(const Offset(50, 50), 70, 70, 6), _stroke(const Color(0xFFC9A227), 3));
      c.drawCircle(const Offset(50, 46), 18, _p(const Color(0xFF2A9D8F)));
      c.drawPath(Path()..addPolygon(const [Offset(22, 78), Offset(50, 58), Offset(78, 78)], true), _p(const Color(0xFFE9C46A)));
      for (final (x, y, n) in const [(36.0, 30.0, '3'), (66.0, 30.0, '5'), (30.0, 60.0, '2')]) {
        glyph(n, Offset(x, y), 9, const Color(0xFF8C2F39));
      }
    case 'ek4papel': // Kağıt Oyma: renkli kâğıt bayraklar ve oyuk desen
      _bg(c, seed, tint: const Color(0xFF2B2D42));
      c.drawLine(const Offset(4, 16), const Offset(96, 22), _stroke(const Color(0xFFB0B0B0), 1));
      for (var k = 0; k < 4; k++) {
        final x = 8 + k * 22.0;
        final col = [const Color(0xFFE4572E), const Color(0xFF29BF12), const Color(0xFFF2A516), const Color(0xFFD94F70)][(k + v) % 4];
        c.drawRect(Rect.fromLTWH(x, 18 + k * 1.5, 20, 30), _p(col));
        c.drawCircle(Offset(x + 10, 30 + k * 1.5), 4, _p(const Color(0xFF2B2D42)));
        c.drawPath(Path()..addPolygon([Offset(x + 4, 40 + k * 1.5), Offset(x + 10, 46 + k * 1.5), Offset(x + 16, 40 + k * 1.5)], true),
            _p(const Color(0xFF2B2D42)));
      }
      c.drawRRect(box(const Offset(50, 74), 50, 30, 3), _p(const Color(0xFFF2A516)));
      c.drawLine(const Offset(50, 60), const Offset(50, 88), _stroke(const Color(0x662B2D42), 1));
    case 'ek4henna': // Kına Deseni: avuç ve simetrik desen (dini simge yok)
      _bg(c, seed, tint: const Color(0xFFE8D5C4));
      final skin = [const Color(0xFFF1C27D), const Color(0xFFD9A066), const Color(0xFF8D5524)][v % 3];
      c.drawOval(const Rect.fromLTWH(28, 34, 44, 50), _p(skin));
      for (var k = 0; k < 4; k++) {
        c.drawRRect(box(Offset(32 + k * 12.0, 26), 9, 24, 4.5), _p(skin));
      }
      c.drawCircle(const Offset(50, 60), 9, _stroke(const Color(0xFF8B3A1E), 2));
      for (var k = 0; k < 8; k++) {
        final a = k * math.pi / 4;
        c.drawCircle(Offset(50 + 14 * math.cos(a), 60 + 14 * math.sin(a)), 2, _p(const Color(0xFF8B3A1E)));
      }
      c.drawLine(const Offset(36, 76), const Offset(64, 76), _stroke(const Color(0xFF8B3A1E), 1.5));
    case 'ek4toyhouse': // Oyuncak Ev Dünyası: kesitli ev ve odalar
      _bg(c, seed, tint: const Color(0xFFF7E3C9));
      c.drawPath(Path()..addPolygon(const [Offset(14, 40), Offset(50, 12), Offset(86, 40)], true), _p(const Color(0xFFE76F51)));
      c.drawRect(const Rect.fromLTWH(18, 40, 64, 48), _p(const Color(0xFFFFF7EA)));
      c.drawLine(const Offset(18, 64), const Offset(82, 64), _stroke(const Color(0xFFCBBFA8), 2));
      c.drawLine(const Offset(50, 40), const Offset(50, 88), _stroke(const Color(0xFFCBBFA8), 2));
      c.drawRRect(box(const Offset(34, 56), 22, 8, 3), _p(const Color(0xFF6D9DC5)));
      c.drawRRect(box(const Offset(66, 54), 10, 14, 2), _p(const Color(0xFF8AB17D)));
      c.drawCircle(const Offset(34, 78), 5, _p(const Color(0xFFF6C85F)));
      c.drawRRect(box(const Offset(66, 80), 18, 8, 3), _p(const Color(0xFFB392AC)));
    case 'ek4vet': // Minik Veteriner: tavşan, kalp ve yara bandı
      _bg(c, seed, tint: const Color(0xFFE8F4F1));
      c.drawOval(const Rect.fromLTWH(30, 46, 40, 36), _p(const Color(0xFFF1F3F8)));
      c.drawCircle(const Offset(50, 40), 14, _p(const Color(0xFFF1F3F8)));
      c.drawOval(const Rect.fromLTWH(38, 8, 9, 24), _p(const Color(0xFFF1F3F8)));
      c.drawOval(const Rect.fromLTWH(53, 8, 9, 24), _p(const Color(0xFFF1F3F8)));
      c.drawCircle(const Offset(45, 38), 1.8, _p(const Color(0xFF2E3A4B)));
      c.drawCircle(const Offset(55, 38), 1.8, _p(const Color(0xFF2E3A4B)));
      c.drawRRect(box(const Offset(60, 64), 16, 6, 3), _p(const Color(0xFFF2C6A0)));
      c.drawPath(
          Path()
            ..moveTo(82, 30)
            ..cubicTo(76, 22, 66, 30, 82, 42)
            ..cubicTo(98, 30, 88, 22, 82, 30),
          _p(const Color(0xFFE07A5F)));
    case 'ek4tales': // Masal Kitaplığı: açık kitap ve yıldızlar
      _bg(c, seed, tint: const Color(0xFF2E3A5B));
      c.drawPath(Path()..addPolygon(const [Offset(12, 34), Offset(50, 40), Offset(50, 84), Offset(12, 76)], true), _p(const Color(0xFFFBF7EF)));
      c.drawPath(Path()..addPolygon(const [Offset(88, 34), Offset(50, 40), Offset(50, 84), Offset(88, 76)], true), _p(const Color(0xFFF1E8D6)));
      for (var k = 0; k < 4; k++) {
        c.drawLine(Offset(18, 48.0 + k * 7), Offset(44, 52.0 + k * 7), _stroke(const Color(0xFFCBBFA8), 1.2));
      }
      c.drawCircle(const Offset(68, 58), 8, _p(const Color(0xFF5BAA6E)));
      for (final o in const [Offset(24, 16), Offset(50, 12), Offset(76, 18)]) {
        c.drawCircle(o, 2.5, _p(const Color(0xFFF6C85F)));
      }
    case 'ek4carwash': // Araba Yıkama ve Tamir: araba, köpük, anahtar
      _bg(c, seed, tint: const Color(0xFF8EC5E8));
      c.drawRRect(box(const Offset(50, 60), 64, 20, 8), _p(const Color(0xFF3F6FD8)));
      c.drawRRect(box(const Offset(48, 46), 34, 16, 6), _p(const Color(0xFF3F6FD8)));
      c.drawRRect(box(const Offset(48, 46), 26, 10, 3), _p(const Color(0xFFDDEFF6)));
      c.drawCircle(const Offset(32, 72), 8, _p(const Color(0xFF2B2B2B)));
      c.drawCircle(const Offset(68, 72), 8, _p(const Color(0xFF2B2B2B)));
      c.drawCircle(const Offset(32, 72), 3, _p(const Color(0xFFB0B0B0)));
      c.drawCircle(const Offset(68, 72), 3, _p(const Color(0xFFB0B0B0)));
      for (final (x, y) in const [(20.0, 30.0), (28.0, 22.0), (14.0, 22.0), (80.0, 28.0)]) {
        c.drawCircle(Offset(x, y), 4, _p(const Color(0xDDFFFFFF)));
      }
      c.drawLine(const Offset(76, 86), const Offset(92, 70), _stroke(const Color(0xFF9AA3AE), 4));
    case 'ek4scripts': // Dünya Alfabeleri: farklı yazılardan harfler
      _bg(c, seed, tint: const Color(0xFF4F86C6));
      const letters = ['ا', 'अ', 'ㄱ', 'あ', 'Ж', 'Ω'];
      const cols = [Color(0xFFFFE3B3), Color(0xFFD7EEDC), Color(0xFFD6E6F7), Color(0xFFF7D9E3), Color(0xFFE8DEF5), Color(0xFFFFF1C1)];
      for (var k = 0; k < 6; k++) {
        final o = Offset(24 + (k % 3) * 26.0, 34 + (k ~/ 3) * 32.0);
        c.drawRRect(box(o, 22, 26, 5), _p(cols[(k + v) % 6]));
        glyph(letters[k], o, 15, const Color(0xFF2E3A4B));
      }
    default:
      return false;
  }
  return true;
}
