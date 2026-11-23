import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:studio_core/app/hub_gallery.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('game cards open; favorite survives gallery recreation', (tester) async {
    var opened = 0;
    Widget screen() => MaterialApp(
      home: HubGallery(
        hubId: 'merkez-blok-oyunlari',
        title: 'Blok Oyunları',
        subtitle: 'Bir arada',
        totalGames: 18,
        openingId: null,
        games: [
          HubGalleryItem(
            id: 'block-puzzle',
            title: 'Blok Bulmaca',
            subtitle: 'Klasik oyun',
            color: Colors.purple,
            icon: Icons.grid_view,
            cover: null,
            group: false,
            open: () => opened++,
          ),
          HubGalleryItem(
            id: 'sudoku',
            title: 'Blok Sudoku',
            subtitle: 'Sayılar',
            color: Colors.blue,
            icon: Icons.calculate,
            cover: null,
            group: false,
            open: () => opened++,
          ),
        ],
      ),
    );

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('Blok Bulmaca'), findsWidgets);
    await tester.tap(find.text('Oyna'));
    expect(opened, 1);

    await tester.tap(find.byTooltip('Favorilere ekle').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koleksiyon'));
    await tester.pumpAndSettle();
    expect(find.text('Blok Bulmaca'), findsOneWidget);
    expect(find.text('Blok Sudoku'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Koleksiyon'));
    await tester.pumpAndSettle();
    expect(find.text('Blok Bulmaca'), findsOneWidget);
  });

  testWidgets('discover search filters cards without losing navigation', (tester) async {
    await tester.pumpWidget(MaterialApp(home: HubGallery(
      hubId: 'merkez-masa-oyunlari',
      title: 'Masa Oyunları',
      subtitle: 'Strateji',
      totalGames: 2,
      openingId: null,
      games: [
        HubGalleryItem(id: 'sat', title: 'Satranç', subtitle: '',
          color: Colors.orange, icon: Icons.casino, cover: null,
          group: false, open: () {}),
        HubGalleryItem(id: 'bil', title: 'Bilardo', subtitle: '',
          color: Colors.green, icon: Icons.sports, cover: null,
          group: false, open: () {}),
      ],
    )));
    await tester.tap(find.text('Keşfet'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'sat');
    await tester.pumpAndSettle();
    expect(find.text('Satranç'), findsOneWidget);
    expect(find.text('Bilardo'), findsNothing);
    await tester.tap(find.text('Ana Sayfa'));
    await tester.pumpAndSettle();
    expect(find.text('Bilardo'), findsOneWidget);
  });
}
