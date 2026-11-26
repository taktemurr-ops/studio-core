import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/covers.dart';

/// 4. tur Bulmaca, Eşleştirme ve Blok kapakları: her tür tanınır (yedek
/// etikete düşmez), hatasız çizilir ve liste tekrarsızdır.
void main() {
  test('4. tur kapak türleri tekrarsız ve tanınmış', () {
    expect(ek4BesCoverKinds.toSet().length, ek4BesCoverKinds.length);
    for (final k in ek4BesCoverKinds) {
      expect(coverHasFamilyArt(GameCover(k)), isTrue, reason: k);
    }
  });

  testWidgets('4. tur kapakları hatasız çizilir', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in ek4BesCoverKinds)
            for (final size in const [40.0, 96.0]) CoverArt(cover: GameCover(k), color: const Color(0xFF2E6F8E), size: size),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CoverArt), findsNWidgets(ek4BesCoverKinds.length * 2));
  });
}
