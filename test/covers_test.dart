import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/covers.dart';

void main() {
  testWidgets('bütün kapak türleri hatasız çizilir', (tester) async {
    const kinds = [
      'cards', 'cardback', 'solitaire', 'pyramid', 'rack', 'domino', 'mahjong', 'chess', 'checkers', 'go', 'reversi',
      'xo', 'connect', 'backgammon', 'mancala', 'dice', 'race', 'grid', 'nonogram', 'blocks', 'hexes', 'bubbles',
      'gems', 'tubes', 'maze', 'pipes', 'shelf', 'pairs', 'lens', 'chain', 'fruit', 'pins', 'map', 'war', 'yok',
    ];
    await tester.pumpWidget(MaterialApp(
      home: Wrap(children: [
        for (final k in kinds)
          for (final v in [0, 1, 2])
            CoverArt(cover: GameCover(k, v: v, label: k == 'rack' ? '1,2,3' : ''), color: Colors.teal, size: 48),
      ]),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CoverArt), findsNWidgets(kinds.length * 3));
  });
}
