import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/covers.dart';

void main() {
  testWidgets('3. tur ek oyun kapakları kendi çizimiyle hatasız çizilir', (tester) async {
    const kinds = ['mc_satrancbulmaca'];
    for (final k in kinds) {
      expect(coverHasFamilyArt(GameCover(k)), isTrue, reason: k);
    }
    await tester.pumpWidget(MaterialApp(
      home: Wrap(children: [
        for (final k in kinds)
          for (final size in [32.0, 64.0, 128.0]) CoverArt(cover: GameCover(k), color: const Color(0xFF14703A), size: size),
      ]),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CoverArt), findsNWidgets(kinds.length * 3));
  });
}
