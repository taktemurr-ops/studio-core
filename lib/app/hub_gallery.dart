import 'package:flutter/material.dart';
import 'covers.dart';

/// Visual layer for the five family hubs. Does not touch game state or saves.
class HubGalleryItem {
  final String id;
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  final GameCover? cover;
  final bool group;
  final VoidCallback open;
  const HubGalleryItem({
    required this.id, required this.title, required this.subtitle,
    required this.color, required this.icon, required this.cover,
    required this.group, required this.open,
  });
}

class HubGallery extends StatefulWidget {
  final String hubId;
  final String title;
  final String subtitle;
  final List<HubGalleryItem> games;
  final String? openingId;
  const HubGallery({super.key, required this.hubId, required this.title,
    required this.subtitle, required this.games, required this.openingId});

  @override
  State<HubGallery> createState() => _HubGalleryState();
}

class _HubGalleryState extends State<HubGallery> {
  int tab = 0;
  String search = '';
  final favorites = <String>{};
  static const gold = Color(0xFFFFC92D);

  bool get puzzle => widget.hubId.contains('bulmaca');
  bool get match => widget.hubId.contains('eslestirme');
  bool get cards => widget.hubId.contains('kart');
  bool get board => widget.hubId.contains('masa');
  bool get light => puzzle || match;
  Color get accent => puzzle ? const Color(0xFF1677F2)
      : match ? const Color(0xFFEE3696)
      : cards ? const Color(0xFF16D677)
      : board ? const Color(0xFFFFBC3D)
      : const Color(0xFFAD59FF);
  Color get bg => puzzle ? const Color(0xFFF3F6FD)
      : match ? const Color(0xFFFFE7F3)
      : cards ? const Color(0xFF031F17)
      : board ? const Color(0xFF0F1B31)
      : const Color(0xFF12072D);
  Color get surface => puzzle ? Colors.white
      : match ? const Color(0xFFFFF5FB)
      : cards ? const Color(0xFF073B27)
      : board ? const Color(0xFF1D2841)
      : const Color(0xFF2A1456);
  Color get ink => light ? const Color(0xFF161C3F) : Colors.white;
  Color get faded => light ? const Color(0xFF64708A) : const Color(0xFFD1C6ED);

  @override
  Widget build(BuildContext context) {
    final available = widget.games.where((g) =>
        (tab != 2 || favorites.contains(g.id)) &&
        (search.isEmpty || (g.title + ' ' + g.subtitle).toLowerCase().contains(search.toLowerCase()))).toList();
    final featured = widget.games.isEmpty ? null : widget.games.firstWhere(
      (g) => !g.group, orElse: () => widget.games.first);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: Column(children: [
        Expanded(child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(13)),
                child: Icon(cards ? Icons.style_rounded : board ? Icons.casino_rounded
                  : match ? Icons.favorite_rounded : puzzle ? Icons.extension_rounded
                  : Icons.grid_view_rounded, color: accent, size: 27),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 19, color: ink)),
                Text(widget.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: faded)),
              ])),
              IconButton(tooltip: 'Ara', onPressed: () => setState(() => tab = 1),
                icon: Icon(Icons.search_rounded, color: ink)),
              IconButton(tooltip: 'Hakkında', onPressed: () => showAboutDialog(context: context,
                applicationName: widget.title,
                children: [Text('${widget.games.length} oyun, tek merkez uygulama.')]),
                icon: Icon(Icons.settings_outlined, color: ink)),
            ]),
          )),
          if (tab == 0 && featured != null) SliverToBoxAdapter(
            child: Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: _hero(featured))),
          if (tab == 1) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: TextField(
              onChanged: (v) => setState(() => search = v),
              style: TextStyle(color: ink),
              decoration: InputDecoration(
                hintText: 'Oyun ara...', hintStyle: TextStyle(color: faded),
                prefixIcon: Icon(Icons.search_rounded, color: accent),
                filled: true, fillColor: surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none)),
            ))),
          SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18, 7, 18, 10),
            child: Row(children: [
              Text(tab == 2 ? 'Favori Oyunlarım' : tab == 1 ? 'Oyunları Keşfet' :
                   tab == 3 ? 'Koleksiyon Bilgisi' : 'Oyun Kütüphanesi',
                style: TextStyle(color: ink, fontSize: 18, fontWeight: FontWeight.w900)),
              const Spacer(),
              Text('${available.length} oyun', style: TextStyle(color: accent,
                fontWeight: FontWeight.w700, fontSize: 12)),
            ]))),
          if (tab == 3) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(18),
            child: _panel(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Oyun merkezim', style: TextStyle(color: ink, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('Bu merkezde ${widget.games.length} oyun ve ${favorites.length} favori bulunuyor.',
                style: TextStyle(color: faded)),
              const SizedBox(height: 8),
              Text('Her oyunun mevcut kayıt ve ilerleme sistemi korunur.',
                style: TextStyle(color: faded)),
            ])))),
          if (tab != 3 && available.isEmpty) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(tab == 2 ? 'Henüz favori oyun seçmedin.' : 'Aramana uygun oyun yok.',
              textAlign: TextAlign.center, style: TextStyle(color: faded)))),
          if (tab != 3) SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            sliver: SliverLayoutBuilder(builder: (context, constraints) {
              final width = constraints.crossAxisExtent;
              final columns = width >= 950 ? 5 : width >= 650 ? 4 : width >= 430 ? 3 : 2;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12,
                  childAspectRatio: 0.88),
                delegate: SliverChildBuilderDelegate((context, i) => _gameTile(available[i]),
                  childCount: available.length),
              );
            }),
          ),
        ])),
        _nav(),
      ])),
    );
  }

  Widget _panel(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surface, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: accent.withValues(alpha: 0.24))),
    child: child);

  Widget _hero(HubGalleryItem feature) => Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
        colors: [surface, Color.lerp(surface, accent, 0.4)!]),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.5),
      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.15), blurRadius: 20)]),
    child: Padding(padding: const EdgeInsets.all(19),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('ÖNE ÇIKAN', style: TextStyle(color: gold, fontSize: 11,
                letterSpacing: 1.8, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Text(feature.title, maxLines: 2,
              style: TextStyle(color: ink, fontWeight: FontWeight.w900, fontSize: 26)),
            const SizedBox(height: 7),
            Text('Tüm favori oyunların tek yerde!',
              style: TextStyle(color: faded, fontSize: 12)),
          ])),
          feature.cover == null
            ? Icon(feature.icon, color: gold, size: 85)
            : CoverArt(cover: feature.cover!, color: feature.color, size: 100, radius: 18),
        ]),
        const SizedBox(height: 17),
        Row(children: [
          _pill(Icons.videogame_asset_rounded, '${widget.games.length} Oyun'),
          const SizedBox(width: 9),
          _pill(Icons.layers_rounded, 'Tek Merkez'),
        ]),
        const SizedBox(height: 17),
        SizedBox(width: double.infinity, height: 49,
          child: FilledButton.icon(onPressed: feature.open,
            style: FilledButton.styleFrom(backgroundColor: gold, foregroundColor: const Color(0xFF25123A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17))),
            icon: const Icon(Icons.play_arrow_rounded, size: 27),
            label: const Text('Oyna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
      ])));

  Widget _pill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: bg.withValues(alpha: 0.64),
      borderRadius: BorderRadius.circular(13)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: accent, size: 17), const SizedBox(width: 5),
      Text(label, style: TextStyle(color: ink, fontSize: 11, fontWeight: FontWeight.bold)),
    ]));

  Widget _gameTile(HubGalleryItem g) => Material(
    color: surface, borderRadius: BorderRadius.circular(16),
    child: InkWell(onTap: g.open, borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          border: Border.all(color: accent.withValues(alpha: 0.28)),
          borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          Expanded(child: Center(child: g.cover == null
            ? Container(padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [g.color.withValues(alpha: 0.50), surface]),
                  borderRadius: BorderRadius.circular(14)),
                child: Icon(g.icon, size: 42, color: accent))
            : LayoutBuilder(builder: (context, c) =>
                CoverArt(cover: g.cover!, color: g.color,
                  size: c.maxWidth.clamp(45.0, 110.0).toDouble(), radius: 14)))),
          const SizedBox(height: 6),
          Text(g.title, maxLines: 2, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center, style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w800, color: ink)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            if (widget.openingId == g.id)
              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(
                strokeWidth: 2, color: accent))
            else Icon(g.group ? Icons.grid_view_rounded : Icons.play_arrow_rounded,
              color: accent, size: 18),
            IconButton(
              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
              padding: EdgeInsets.zero, iconSize: 21,
              tooltip: favorites.contains(g.id) ? 'Favorilerden çıkar' : 'Favorilere ekle',
              onPressed: () => setState(() {
                if (!favorites.add(g.id)) favorites.remove(g.id);
              }),
              icon: Icon(favorites.contains(g.id) ? Icons.favorite : Icons.favorite_border,
                color: favorites.contains(g.id) ? const Color(0xFFFE4B9C) : faded)),
          ]),
        ])),
    ));

  Widget _nav() => Container(
    decoration: BoxDecoration(color: surface,
      border: Border(top: BorderSide(color: accent.withValues(alpha: 0.33)))),
    child: SafeArea(top: false, child: Row(children: [
      _navItem(0, Icons.home_rounded, 'Ana Sayfa'),
      _navItem(1, Icons.search_rounded, 'Keşfet'),
      _navItem(2, Icons.layers_rounded, 'Koleksiyon'),
      _navItem(3, Icons.person_outline_rounded, 'Profil'),
    ])));

  Widget _navItem(int i, IconData icon, String label) => Expanded(
    child: InkWell(onTap: () => setState(() { tab = i; search = ''; }),
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 11),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: tab == i ? accent : faded, size: 23),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(
            color: tab == i ? accent : faded, fontSize: 10,
            fontWeight: tab == i ? FontWeight.w900 : FontWeight.w500)),
        ]))));
}
