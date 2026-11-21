# studio-core

Ortak oyun çekirdeği. Her oyun deposu (`oyun-*`) ve her merkez uygulama (`merkez-*`) bu paketi kullanır.
Böylece bir düzeltme bir kez yapılır ve hepsine gider.

- `lib/core/`: kayıt (HMAC imzalı), günlük hediye, görevler, başarımlar, koleksiyon, bölüm planı (50.000+ bölüm, tohumla üretim), mağaza defteri, telemetri.
- `lib/app/`: açılış (`bootstrap`), oyun arayüzü sözleşmesi (`game_api.dart`), ekranlar, telefon/tablet/web uyumu, reklam ve satın alma servisleri, arcade sahnesi.

Kullanım (`pubspec.yaml`):

```yaml
dependencies:
  studio_core:
    git:
      url: https://github.com/taktemurr-ops/studio-core
      ref: v1.0.0
```

Kurallar: kumar ve şans mekaniği yok; 18+ içerik yok; çocuk modunda ebeveyn kapısı zorunlu.

## Merkez uygulama (hub)

Bir ailedeki oyunları tek mağaza uygulamasında toplar. Her oyunun kaydı, ilerlemesi ve ayarları ayrı kalır.

```dart
void main() => bootstrapHub(HubConfig(
  hubId: 'merkez-blok-oyunlari',
  title: ['Blok Oyunları', 'Block Games', 'Blockspiele', 'Juegos de Bloques', 'Jeux de Blocs'],
  tagline: [...],
  seedColor: Color(0xFF3F51B5),
  icon: Icons.grid_view_rounded,
  games: [blockPuzzleConfig, blokSudokuConfig],
));
```
