import 'progression.dart';
import 'save_data.dart';

enum ItemType { theme, skin, badge, avatar, frame, effect }

enum UnlockKind { free, world, playerLevel, stars, coins, gems, achievementCount, premium, wheel }

class CollectionItem {
  final String id;
  final ItemType type;
  final int index;
  final UnlockKind unlock;
  final int value;

  const CollectionItem(this.id, this.type, this.index, this.unlock, this.value);

  bool canUnlock(SaveData s) {
    switch (unlock) {
      case UnlockKind.free:
        return true;
      case UnlockKind.world:
        return s.highestLevel >= (value - 1) * 100 + 1;
      case UnlockKind.playerLevel:
        return PlayerProgression.levelForXp(s.totalXp) >= value;
      case UnlockKind.stars:
        return s.totalStars >= value;
      case UnlockKind.achievementCount:
        return s.achievements.length >= value;
      case UnlockKind.premium:
        return s.premium;
      case UnlockKind.coins:
      case UnlockKind.gems:
      case UnlockKind.wheel:
        return false; // bought / won explicitly
    }
  }
}

/// 100-500 collectible cosmetics (doc 4.1, 4.4): themes, skins, badges,
/// avatars, frames and effects. Pure cosmetics - never pay-to-win.
class CollectionCatalog {
  final List<CollectionItem> items;
  final Map<String, CollectionItem> byId;

  CollectionCatalog._(this.items) : byId = {for (final i in items) i.id: i};

  factory CollectionCatalog.build({int themes = 12}) {
    final l = <CollectionItem>[];
    for (var i = 0; i < themes; i++) {
      l.add(CollectionItem('theme_$i', ItemType.theme, i,
          i == 0 ? UnlockKind.free : UnlockKind.world, i * 2 + 1));
    }
    for (var i = 0; i < 24; i++) {
      final kind = i == 0
          ? UnlockKind.free
          : i % 4 == 0
              ? UnlockKind.gems
              : i % 3 == 0
                  ? UnlockKind.stars
                  : UnlockKind.coins;
      final value = switch (kind) {
        UnlockKind.gems => 20 + i * 2,
        UnlockKind.stars => i * 60,
        UnlockKind.coins => 300 + i * 150,
        _ => 0,
      };
      l.add(CollectionItem('skin_$i', ItemType.skin, i, kind, value));
    }
    for (var i = 0; i < 120; i++) {
      l.add(CollectionItem('badge_$i', ItemType.badge, i,
          UnlockKind.achievementCount, 1 + i * 2));
    }
    for (var i = 0; i < 40; i++) {
      l.add(CollectionItem('avatar_$i', ItemType.avatar, i,
          i < 2 ? UnlockKind.free : (i % 5 == 0 ? UnlockKind.wheel : UnlockKind.playerLevel),
          i * 12));
    }
    for (var i = 0; i < 24; i++) {
      l.add(CollectionItem('frame_$i', ItemType.frame, i,
          i < 20 ? UnlockKind.playerLevel : UnlockKind.premium, 10 + i * 20));
    }
    for (var i = 0; i < 16; i++) {
      l.add(CollectionItem('effect_$i', ItemType.effect, i,
          i == 0 ? UnlockKind.free : UnlockKind.coins, 500 + i * 250));
    }
    return CollectionCatalog._(l);
  }

  /// Grants every item whose automatic condition is met. Returns new ids.
  List<CollectionItem> autoUnlock(SaveData s) {
    final out = <CollectionItem>[];
    for (final it in items) {
      if (s.collection.contains(it.id)) continue;
      if (it.canUnlock(s)) {
        s.collection.add(it.id);
        out.add(it);
      }
    }
    return out;
  }

  /// Purchase with soft currency. Returns false if not affordable.
  bool buy(SaveData s, String id) {
    final it = byId[id];
    if (it == null || s.collection.contains(id)) return false;
    if (it.unlock == UnlockKind.coins && s.coins >= it.value) {
      s.coins -= it.value;
      s.addStat('coins_spent', it.value);
    } else if (it.unlock == UnlockKind.gems && s.gems >= it.value) {
      s.gems -= it.value;
    } else {
      return false;
    }
    s.collection.add(id);
    return true;
  }

  /// A random locked wheel/avatar item, or null.
  CollectionItem? wheelPrize(SaveData s, int roll) {
    final locked = items
        .where((i) => i.unlock == UnlockKind.wheel && !s.collection.contains(i.id))
        .toList();
    if (locked.isEmpty) return null;
    return locked[roll % locked.length];
  }
}
