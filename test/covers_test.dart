import 'dart:io';
import 'dart:ui' as ui;

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
      'tangram', 'lights', 'balance',
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
      'karagozc', 'hocac', 'mozrestc',
    ];
    for (final k in const ['karagozc', 'hocac', 'mozrestc']) {
      expect(coverHasFamilyArt(GameCover(k)), isTrue, reason: k);
    }
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
  testWidgets('ikinci tur özgün kapakları hatasız ve tanınmış olarak çizilir', (tester) async {
    const kinds = [
      'tarneebc', 'trixc', 'balootc', 'hokmc', 'twentyninec', 'carromc', 'pacisic', // kâğıt ve masa
      'jobsc', 'bodyc', 'dinoc', 'fruitvegc', // eğitici
      'digitspanc', 'searchgridc', 'wordmemc', // zihin
      'rhythmdictc', 'pitchholdc', // müzik
      'astroc', 'artlitc', // bilgi
      'autobattlerc', 'dungeonkeeperc', // strateji
      'wordbombc', 'fivesecc', 'mostlikelyc', // parti
      'simspace', 'simzoo', 'balance', // boşta ve arcade
      'hillclimb', 'kitefight', 'cricketbat', 'crowdgates', 'shuttlecourt', 'kabaddiraid', // 4. tur arcade
    ];
    // Bilinmeyen tür yedek çizime (etiket metni) düşer; yeni türlerin hiçbiri düşmemeli.
    for (final k in kinds) {
      for (final v in [0, 1, 2, 3]) {
        expect(coverHasFamilyArt(GameCover(k, v: v)), isTrue, reason: k);
      }
    }
    expect(coverHasFamilyArt(const GameCover('yok')), isFalse);
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in kinds)
            for (final v in [0, 1, 2]) CoverArt(cover: GameCover(k, v: v), color: Colors.deepPurple, size: 40),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CoverArt), findsNWidgets(kinds.length * 3));
  });

  testWidgets('kaynakta kayıtlı her kapak türü hatasız çizilir', (tester) async {
    // covers*.dart dosyalarındaki bütün türler kaynaktan toplanır; yeni bir
    // kapak eklendiğinde bu listeye ayrıca yazmak gerekmez.
    final kinds = <String>{};
    final files = Directory('lib/app')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'covers[a-z0-9_]*\.dart$').hasMatch(f.path));
    for (final f in files) {
      final src = f.readAsStringSync();
      for (final m in RegExp(r"(?:case|kind != |kind == ) ?'([a-z0-9_]+)'").allMatches(src)) {
        kinds.add(m.group(1)!);
      }
    }
    expect(kinds.length, greaterThan(200));
    for (final k in kinds) {
      for (final v in [0, 1, 2, 3]) {
        for (final l in const ['', '7', 'A,B']) {
          final rec = ui.PictureRecorder();
          paintCover(Canvas(rec), GameCover(k, v: v, label: l), const Color(0xFF4A7BD0));
          rec.endRecording().dispose();
        }
      }
    }
    expect(tester.takeException(), isNull);
    // Bu turda eklenen oyuna özel kapaklar yedek çizime düşmemeli.
    for (final k in const ['geosolidc', 'sportquizc']) {
      expect(kinds, contains(k));
      expect(coverHasFamilyArt(GameCover(k)), isTrue, reason: k);
    }
  });
  testWidgets('eşleştirme ve kelime merkezlerinin oyuna özgü kapakları hatasız ve tanınmış olarak çizilir', (tester) async {
    const kinds = [
      // Eşleştir ve Sırala
      'stacktrayc', 'hexmatchc', 'onetc', 'shooterc', 'stonebubblec', 'samegamec', 'picpairc', 'domsumc', 'hiddenc',
      'goalpopc', 'cratec', 'yarnc', 'symcolc', 'layoutsc', 'turtlec', 'gemswapc', 'symbolcardc', 'floodc', 'bigtilec',
      'tiletrayc', 'mergetreec',
      // Kelime
      'countdownc', 'fourguessc', 'acrostc', 'wordduelc', 'antonymc', 'spellc', 'cryptoc', 'blankc', 'boggc',
      'slidecolc', 'wordblockc', 'wordsqc', 'arrowwordc', 'codewordc', 'wordpilec', 'anagramc', 'wordjigc',
    ];
    expect(kinds.toSet().length, kinds.length);
    for (final k in kinds) {
      for (final v in [0, 1, 2, 3]) {
        expect(coverHasFamilyArt(GameCover(k, v: v)), isTrue, reason: k);
        expect(coverHasFamilyArt(GameCover(k, v: v, label: 'Ç')), isTrue, reason: k);
      }
    }
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in kinds)
            for (final v in [0, 1, 2])
              for (final l in const ['', 'Ç', 'ŞİFRELİKELİME'])
                CoverArt(cover: GameCover(k, v: v, label: l), color: Colors.purple, size: 40),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CoverArt), findsNWidgets(kinds.length * 9));
  });

  testWidgets('arcade ve blok merkezlerinin oyuna özgü kapakları hatasız çizilir', (tester) async {
    const arcade = [
      'a-yilan', 'a-yilanio', 'a-uzayatisi', 'a-istila', 'a-asteroit', 'a-raket', 'a-labkov', 'a-isik', 'a-alan',
      'a-kosu', 'a-dinozor', 'a-kaykay', 'a-ziplama', 'a-kanat', 'a-ucak', 'a-platform', 'a-kosates', 'a-yolgecme',
      'a-ustten', 'a-park', 'a-dart', 'a-nisan', 'a-galeri', 'a-okculuk', 'a-refleks', 'a-basket', 'a-bowling',
      'a-golf', 'a-penalti', 'a-futbol', 'a-tenis', 'a-voleybol', 'a-kulekurma', 'a-sapan', 'a-topcu', 'a-egik',
    ];
    const blok = [
      'b-master', 'b-sudoku', 'b-doldurma', 'b-poliomino', 'b-alanbolme', 'b-paket', 'b-dusen', 'b-altigen',
      'b-altigendusen', 'b-sayili', 'b-retro', 'b-kum', 'b-kaydirma', 'b-kacis', 'b-renkli', 'b-egim', 'b-kup', 'b-kule',
    ];
    final covers = [
      for (final k in [...arcade, ...blok]) GameCover(k),
      for (var v = 0; v < 20; v++) GameCover('b-cesit', v: v),
    ];
    for (final cv in covers) {
      expect(coverHasFamilyArt(cv), isTrue, reason: '${cv.kind} v${cv.v}');
    }
    expect(coverHasFamilyArt(const GameCover('a-yok')), isFalse);
    expect(coverHasFamilyArt(const GameCover('b-yok')), isFalse);
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final cv in covers)
            for (final size in [40.0, 96.0]) CoverArt(cover: cv, color: const Color(0xFF1D4E89), size: size),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CoverArt), findsNWidgets(covers.length * 2));
  });

  testWidgets('kart ve masa merkezlerinin oyuna özgü kapakları hatasız çizilir', (tester) async {
    const kart = [
      'kc_klondike', 'kc_spider', 'kc_freecell', 'kc_tripeaks', 'kc_golf', 'kc_yukon', 'kc_scorpion',
      'kc_forty', 'kc_canfield', 'kc_accordion', 'kc_clock', 'kc_solcesit', 'kc_batak', 'kc_batakcesit',
      'kc_hearts', 'kc_spades', 'kc_whist', 'kc_ohhell', 'kc_briscola', 'kc_sueca', 'kc_king', 'kc_euchre',
      'kc_belot', 'kc_klaverjas', 'kc_jass', 'kc_pinokl', 'kc_skat', 'kc_koyun', 'kc_kontrat', 'kc_bezik',
      'kc_tarok', 'kc_pisti', 'kc_scopa', 'kc_toplam', 'kc_renkesle', 'kc_savas', 'kc_baskan', 'kc_papaz',
      'kc_balik', 'kc_blof', 'kc_31', 'kc_hafiza', 'kc_gin', 'kc_kartremi', 'kc_konken', 'kc_asamali',
      'kc_kanasta', 'kc_elayak', 'kc_cribbage', 'kc_durak', 'kc_snap', 'kc_hiz', 'kc_nertz', 'kc_kemps',
      'kc_kartyolu', 'kc_kartkaresi',
    ];
    const masa = [
      'mc_satranc', 'mc_satranccesit', 'mc_xiangqi', 'mc_janggi', 'mc_shogi', 'mc_damacesit', 'mc_turkdama',
      'mc_alquerque', 'mc_fanorona', 'mc_dokuztas', 'mc_hnefatafl', 'mc_surakarta', 'mc_halma', 'mc_cindama',
      'mc_mermer', 'mc_duvar', 'mc_mangalacesit', 'mc_altilibag', 'mc_besleme', 'mc_kapmali', 'mc_hex',
      'mc_havannah', 'mc_blokus', 'mc_tavlacesit', 'mc_kizma', 'mc_yilan', 'mc_zarbesli', 'mc_farkle',
      'mc_yalanci', 'mc_ur', 'mc_senet', 'mc_yut', 'mc_emlak', 'mc_yerlesim', 'mc_101okey', 'mc_okeycesit',
      'mc_mahjongcesit',
    ];
    expect(kart.length, 56);
    expect(masa.length, 37);
    expect({...kart, ...masa}.length, kart.length + masa.length);
    for (final k in [...kart, ...masa]) {
      expect(coverHasFamilyArt(GameCover(k)), isTrue, reason: k);
    }
    expect(coverHasFamilyArt(const GameCover('kc_yok')), isFalse);
    expect(coverHasFamilyArt(const GameCover('mc_yok')), isFalse);
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in [...kart, ...masa])
            for (final size in [40.0, 96.0]) CoverArt(cover: GameCover(k), color: const Color(0xFF14703A), size: size),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
    expect(find.byType(CoverArt), findsNWidgets((kart.length + masa.length) * 2));
  });

  testWidgets('4. tur Bilgi, Zihin, Müzik ve Parti kapakları özgün ve tanınmış', (tester) async {
    const kinds = [
      'estimc', 'trailmkc', 'flankc', 'rhythmrunc', 'usulc', 'kalimbac', 'melpuzc', 'geniec', 'surveyc',
      'quizladderc', 'silhouettec', 'cornersc', 'dilemmac', 'onecluec', 'twotruthc',
    ];
    expect(kinds.toSet().length, kinds.length);
    for (final k in kinds) {
      for (final v in [0, 1, 2, 3]) {
        expect(coverHasFamilyArt(GameCover(k, v: v)), isTrue, reason: k);
      }
    }
    await tester.pumpWidget(MaterialApp(
      home: SingleChildScrollView(
        child: Wrap(children: [
          for (final k in kinds)
            for (final v in [0, 1, 2]) CoverArt(cover: GameCover(k, v: v), color: Colors.teal, size: 40),
        ]),
      ),
    ));
    expect(tester.takeException(), isNull);
  });
}
