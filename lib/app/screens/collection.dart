import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/collection.dart';
import '../app_state.dart';
import '../services/audio.dart';
import '../theme.dart';
import '../widgets.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appStateProvider);
    final cat = app.session.collection;
    return DefaultTabController(
      length: ItemType.values.length,
      child: Column(children: [
        Text('${app.save.collection.length} / ${cat.items.length}'),
        TabBar(
          isScrollable: true,
          tabs: [for (final t in ItemType.values) Tab(text: app.t('type_${t.name}'))],
        ),
        Expanded(
          child: TabBarView(children: [
            for (final t in ItemType.values)
              GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 120, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 0.8),
                itemCount: cat.items.where((i) => i.type == t).length,
                itemBuilder: (c, i) {
                  final item = cat.items.where((x) => x.type == t).elementAt(i);
                  return _ItemCard(app: app, item: item);
                },
              ),
          ]),
        ),
      ]),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final AppState app;
  final CollectionItem item;
  const _ItemCard({required this.app, required this.item});

  String _requirement() {
    switch (item.unlock) {
      case UnlockKind.world:
        return app.t('unlock_world', {'n': item.value});
      case UnlockKind.playerLevel:
        return app.t('unlock_plevel', {'n': item.value});
      case UnlockKind.stars:
        return app.t('unlock_stars', {'n': item.value});
      case UnlockKind.achievementCount:
        return app.t('unlock_ach', {'n': item.value});
      case UnlockKind.premium:
        return app.t('unlock_premium');
      case UnlockKind.wheel:
        return app.t('unlock_wheel');
      case UnlockKind.coins:
        return '${item.value} 🪙';
      case UnlockKind.gems:
        return '${item.value} 💎';
      case UnlockKind.free:
        return '';
    }
  }

  Widget _preview() {
    switch (item.type) {
      case ItemType.theme:
        return ThemedBackground(colors: Palettes.theme(item.index), child: const SizedBox.expand());
      case ItemType.skin:
        final cs = Palettes.skin(item.index);
        return Wrap(
          alignment: WrapAlignment.center,
          children: [for (final c in cs.take(6)) Container(width: 16, height: 16, margin: const EdgeInsets.all(2), color: c)],
        );
      case ItemType.badge:
        return Icon(Icons.verified, size: 40, color: HSLColor.fromAHSL(1, (item.index * 29) % 360.0, 0.7, 0.5).toColor());
      case ItemType.avatar:
        return CircleAvatar(
          backgroundColor: HSLColor.fromAHSL(1, (item.index * 53) % 360.0, 0.6, 0.6).toColor(),
          child: Text(String.fromCharCode(65 + item.index % 26)),
        );
      case ItemType.frame:
        return Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(width: 4, color: HSLColor.fromAHSL(1, (item.index * 41) % 360.0, 0.8, 0.5).toColor()),
            borderRadius: BorderRadius.circular(item.index.isEven ? 22 : 8),
          ),
        );
      case ItemType.effect:
        return Icon(Icons.auto_awesome, size: 36, color: HSLColor.fromAHSL(1, (item.index * 67) % 360.0, 0.8, 0.55).toColor());
    }
  }

  @override
  Widget build(BuildContext context) {
    final owned = app.save.collection.contains(item.id);
    final equipped = app.save.activeTheme == item.id || app.save.activeSkin == item.id;
    final buyable = !owned && (item.unlock == UnlockKind.coins || item.unlock == UnlockKind.gems);
    final equippable = owned && (item.type == ItemType.theme || item.type == ItemType.skin);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          if (equippable) {
            app.updateSettings((s) {
              if (item.type == ItemType.theme) s.activeTheme = item.id;
              if (item.type == ItemType.skin) s.activeSkin = item.id;
            });
          } else if (buyable) {
            if (app.session.collection.buy(app.save, item.id)) {
              app.audio.play(Sfx.unlock);
              app.changed(saveNow: true);
            } else {
              app.audio.play(Sfx.error);
            }
          }
        },
        child: Column(children: [
          Expanded(child: Center(child: Opacity(opacity: owned ? 1 : 0.35, child: _preview()))),
          Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              equipped ? app.t('equipped') : owned ? (equippable ? app.t('equip') : '✓') : _requirement(),
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ]),
      ),
    );
  }
}
