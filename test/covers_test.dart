import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/covers.dart';

void main() {
  testWidgets('bütün kapak türleri hatasız çizilir', (tester) async {
    const kinds = [
      'cards', 'cardback', 'solitaire', 'pyramid', 'rack', 'domino', 'mahjong', 'chess', 'checkers', 'go', 'reversi',
      'xo', 'connect', 'backgammon', 'mancala', 'dice', 'race', 'grid', 'nonogram', 'blocks', 'hexes', 'bubbles',
      'gems', 'tubes', 'maze', 'pipes', 'shelf', 'pairs', 'lens', 'chain', 'fruit', 'pins', 'map', 'war', 'yok',
      'pool', 'hockey', 'foosball', 'pingpong', 'ships', 'dots', 'marbles', 'cube', 'hanoi', 'cars', 'arrows', 'jigsaw',
      'tangram', 'lights',
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

  testWidgets('arcade kapakları hatasız çizilir', (tester) async {
    const kinds = [
      'snake', 'bricks', 'space', 'runner', 'sky', 'ball', 'target', 'balloons', 'slice', 'mole', 'stack',
      'helix', 'ring', 'knife', 'lander', 'missile', 'tank', 'cannon', 'rope', 'hole', 'pinball', 'trail',
      'bomb', 'dig', 'boulder', 'walkers', 'bug', 'bullets', 'fish', 'castle', 'ski', 'apps',
    ];
    const labels = ['', 'basket', 'soccer', 'bowling', 'golf', 'volley', 'tennis'];
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in kinds)
            for (final v in [0, 1, 2])
              for (final l in (k == 'ball' ? labels : const ['']))
                CoverArt(cover: GameCover(k, v: v, label: l), color: Colors.indigo, size: 40),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('kelime kapakları hatasız çizilir', (tester) async {
    const kinds = [
      'letters', 'guessrows', 'wheel', 'crossgrid', 'hive', 'wordrack', 'quote', 'ladderw', 'chainw', 'petal',
      'keyboard', 'pairsw', 'fall', 'sudokuw',
    ];
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in kinds)
            for (final v in [0, 1, 2])
              for (final l in const ['', 'KELİME', 'ΛΕΞΗ'])
                CoverArt(cover: GameCover(k, v: v, label: l), color: Colors.teal, size: 40),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('zihin kapakları hatasız çizilir', (tester) async {
    const kinds = ['pads', 'inkword', 'numgrid', 'memgrid', 'nback', 'mathq', 'reflex', 'pattern', 'rotate', 'daily'];
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in kinds)
            for (final v in [0, 1, 2])
              for (final l in const ['', 'RED BLUE GREEN'])
                CoverArt(cover: GameCover(k, v: v, label: l), color: Colors.indigo, size: 40),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });

  testWidgets('özgün oyun kapakları hatasız çizilir', (tester) async {
    const kinds = [
      'kilimc', 'cinic', 'ebruc', 'tulipc', 'caravanc', 'callic', 'shadowc', 'nbhdc', 'gearc', 'lightc', 'rotworldc', 'paintc',
      'dominoc', 'honeyc', 'foldc', 'aquac', 'stallc', 'starsc', 'trainc', 'soundc', 'trioc', 'mushc', 'sandc',
    ];
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in kinds)
            for (final v in [0, 1, 2]) CoverArt(cover: GameCover(k, v: v), color: Colors.brown, size: 40),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
