import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/covers.dart';

/// Bulmaca ve Sayı merkezinin oyuna özgü kapakları: her tür tanınır (yedek
/// etikete düşmez), hatasız çizilir ve liste tekrarsızdır.
void main() {
  test('bulmaca kapak türleri tekrarsız ve tanınmış', () {
    expect(bulmacaCoverKinds.toSet().length, bulmacaCoverKinds.length);
    for (final k in bulmacaCoverKinds) {
      expect(coverHasFamilyArt(GameCover(k)), isTrue, reason: k);
    }
  });

  testWidgets('bulmaca kapakları hatasız çizilir', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in bulmacaCoverKinds)
            for (final size in const [40.0, 96.0]) CoverArt(cover: GameCover(k), color: const Color(0xFF2E6F8E), size: size),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CoverArt), findsNWidgets(bulmacaCoverKinds.length * 2));
  });
}
