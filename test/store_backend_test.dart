import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';
import 'package:studio_core/app/studio_apps.dart';

class _FakeHuawei extends StoreBackend {
  @override
  StoreKind get kind => StoreKind.huawei;
  @override
  AdsService createAds() => _MarkedAds();
  @override
  PurchaseService createPurchases() => NoPurchaseService();
}

class _MarkedAds extends NoAdsService {}

void main() {
  tearDown(() {
    StoreFlavor.debugOverride = null;
    StoreBackends.reset();
  });

  test('varsayılan derleme Google/Apple arka ucunu kullanır', () {
    expect(StoreFlavor.raw, isEmpty);
    expect(StoreFlavor.isHuawei, isFalse);
    expect(StoreBackends.current, isA<TableStoreBackend>());
    expect(StoreBackends.current.kind, StoreKind.google);
    expect(StoreBackends.current.remotePush, isFalse);
    // Testlerde (dart:io, mobil değil) reklam/satın alma no-op'tur.
    expect(AdsService.create().available, isFalse);
    expect(PurchaseService.create().available, isFalse);
  });

  test('AppGallery: eklenti yoksa GMS\'siz yedek, reklam ve satın alma kapalı', () async {
    StoreFlavor.debugOverride = StoreKind.huawei;
    final b = StoreBackends.current;
    expect(b, isA<TableStoreBackend>());
    expect(b.kind, StoreKind.huawei);
    final ads = AdsService.create();
    expect(await ads.init(underAge: false, personalized: true), isFalse);
    expect(await ads.showRewarded(), isFalse);
    expect(await ads.showInterstitial(), isFalse);
    final iap = PurchaseService.create();
    await iap.init((_) {});
    expect(iap.available, isFalse);
    expect(iap.products, isEmpty);
    expect(await iap.buy('remove_ads'), isFalse);
  });

  test('AppGallery: kayıtlı HMS arka ucu kullanılır', () {
    StoreBackends.register(_FakeHuawei());
    expect(StoreBackends.isRegistered(StoreKind.huawei), isTrue);
    // Google derlemesinde kayıtlı Huawei arka ucu devreye girmez.
    expect(StoreBackends.current.kind, StoreKind.google);
    StoreFlavor.debugOverride = StoreKind.huawei;
    expect(StoreBackends.current, isA<_FakeHuawei>());
    expect(AdsService.create(), isA<_MarkedAds>());
  });

  test('mağaza sayfası derlemeye göre', () {
    const pkg = 'com.gamestudio100.merkez_verimlilik';
    expect(StoreFlavor.storePage(pkg, kind: StoreKind.google).toString(),
        'https://play.google.com/store/apps/details?id=$pkg');
    expect(StoreFlavor.storePage(pkg, kind: StoreKind.huawei).toString(), 'appmarket://details?id=$pkg');
    final a = studioApps.first;
    expect(a.storeUrl.host, 'play.google.com');
    expect(a.playUrl, a.storeUrl);
    StoreFlavor.debugOverride = StoreKind.huawei;
    expect(a.storeUrl.scheme, 'appmarket');
  });

  test('tablo tek kaynaktan (tool/stores.json) üretilmiş ve tutarlı', () {
    final t = jsonDecode(File('tool/stores.json').readAsStringSync()) as Map<String, dynamic>;
    final rows = (t['stores'] as List).cast<Map<String, dynamic>>();
    expect(rows.map((r) => r['id']).toList(), StoreKind.values.map((k) => k.name).toList(),
        reason: 'tool/gen_store_table.py yeniden çalıştırılmalı');
    for (final r in rows) {
      final s = storeTable[StoreFlavor.parse(r['id'] as String)]!;
      expect(s.name, r['name']);
      expect(s.ads.name, r['ads']);
      expect(s.gms, r['gms']);
      expect(s.storePage, r['store_page']);
      expect(s.artifactSuffix, r['artifact_suffix']);
      expect(s.plugin, (r['plugin'] as Map?)?['package']);
      // Eklentisi olmayan mağazada eklenti gerektiren sağlayıcı yedeğe düşer.
      StoreFlavor.debugOverride = s.kind;
      final b = StoreBackends.current;
      expect(b.kind, s.kind);
    }
    final ids = rows.map((r) => r['artifact_suffix']).where((x) => x != '').toList();
    expect(ids.toSet().length, ids.length, reason: 'çıktı adları benzersiz olmalı');
    expect(StoreFlavor.parse('yok'), isNull);
  });

  test('Amazon gibi reklamsız mağaza AdMob açmaz', () async {
    StoreFlavor.debugOverride = StoreKind.amazon;
    expect(StoreFlavor.spec.ads, AdProvider.none);
    expect(await AdsService.create().init(underAge: false, personalized: true), isFalse);
  });
}
