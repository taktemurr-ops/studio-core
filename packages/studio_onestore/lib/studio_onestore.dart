/// ONE store (Kore) mağaza arka ucu.
///
/// Merkezin `lib/store_flavor.dart` dosyası ONE store derlemesinde
/// `registerOneStore()` çağırır: reklam AdMob, satın alma ONE store IAP v21.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_onestore_inapp/flutter_onestore_inapp.dart';
import 'package:studio_core/app/services/ads.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/app/services/store_backend.dart';
import 'package:studio_core/core/monetization.dart';

/// ONE store IAP. Bütün ürünler "managed" (inapp) türündedir:
/// tüketilebilirler teslimden sonra `consume`, tüketilemezler (reklamsız,
/// premium) `acknowledge` edilir (3 gün içinde onaylanmayan satın almayı
/// ONE store iade eder). "Geri yükle" tüketilmemiş satın almaları okur.
///
/// Ortak lisans anahtarı `--dart-define=ONESTORE_LICENSE_KEY=...` (ONE store
/// Geliştirici Merkezi > Lisans yönetimi); verilmezse imza denetimi SDK'da
/// yapılmaz, satın alma yine çalışır.
class OneStorePurchaseService implements PurchaseService {
  static const licenseKey = String.fromEnvironment('ONESTORE_LICENSE_KEY');

  final Map<String, ProductDetail> _details = {};
  void Function(PurchaseEvent e)? _onEvent;
  StreamSubscription<List<PurchaseData>>? _sub;
  PurchaseClientManager? _client;
  bool _available = false;

  @override
  bool get available => _available;

  @override
  List<StoreProduct> get products => [for (final d in _details.values) StoreProduct(d.productId, d.price)];

  @override
  Future<void> init(void Function(PurchaseEvent e) onEvent) async {
    _onEvent = onEvent;
    if (!Platform.isAndroid) return;
    try {
      final c = PurchaseClientManager.instance;
      c.initialize(licenseKey.isEmpty ? null : licenseKey);
      _client = c;
      _sub = c.purchasesUpdatedStream.listen(
        (list) {
          for (final p in list) {
            unawaited(_deliver(p, 'purchased'));
          }
        },
        onError: (Object e) {
          final canceled = e is IapResult && e.responseCode == PurchaseResponse.userCanceled;
          _onEvent?.call(PurchaseEvent('', '', canceled ? 'canceled' : 'error', false));
        },
      );
      final r = await c.queryProductDetails(productIds: Products.all.toList(), productType: ProductType.inapp);
      if (r.iapResult.isSuccess()) {
        for (final d in r.productDetailsList) {
          if (Products.all.contains(d.productId)) _details[d.productId] = d;
        }
      }
      _available = _details.isNotEmpty;
      if (_available) unawaited(_owned('purchased'));
    } catch (_) {
      _available = false;
    }
  }

  /// Tüketilmemiş satın almalar: tüketilebilirler teslim edilir (yarım
  /// kalmış), tüketilemezler [status] ile (açılışta/geri yüklemede).
  Future<void> _owned(String status) async {
    final c = _client;
    if (c == null) return;
    try {
      final q = await c.queryPurchases(productType: ProductType.inapp);
      if (!q.iapResult.isSuccess()) return;
      for (final p in q.purchasesList) {
        await _deliver(p, Products.consumable.contains(p.productId) ? 'purchased' : status);
      }
    } catch (_) {}
  }

  Future<void> _deliver(PurchaseData p, String status) async {
    final id = p.productId;
    if (p.purchaseState != PurchaseState.purchased) return;
    final verified = p.purchaseToken.isNotEmpty && Products.all.contains(id);
    _onEvent?.call(PurchaseEvent(id, p.orderId.isNotEmpty ? p.orderId : p.purchaseToken, status, verified));
    final c = _client;
    if (!verified || c == null) return;
    try {
      if (Products.consumable.contains(id)) {
        await c.consumePurchase(purchaseData: p);
      } else if (!p.isAcknowledged) {
        await c.acknowledgePurchase(purchaseData: p);
      }
    } catch (_) {}
  }

  @override
  Future<bool> buy(String productId) async {
    final d = _details[productId];
    final c = _client;
    if (!_available || d == null || c == null) return false;
    try {
      final r = await c.launchPurchaseFlow(productDetail: d);
      if (r.responseCode == PurchaseResponse.itemAlreadyOwned) {
        await _owned('restored');
      } else if (!r.isSuccess()) {
        _onEvent?.call(PurchaseEvent(
            productId, '', r.responseCode == PurchaseResponse.userCanceled ? 'canceled' : 'error', false));
      }
      return true;
    } catch (_) {
      _onEvent?.call(PurchaseEvent(productId, '', 'error', false));
      return false;
    }
  }

  @override
  Future<void> restore() async {
    if (_available) await _owned('restored');
  }

  @override
  void dispose() {
    _onEvent = null;
    unawaited(_sub?.cancel());
    _sub = null;
  }
}

class OneStoreBackend extends StoreBackend {
  final TableStoreBackend _table = TableStoreBackend(storeTable[StoreKind.onestore]!);

  @override
  StoreKind get kind => StoreKind.onestore;

  @override
  AdsService createAds() => _table.createAds();

  @override
  OneStorePurchaseService createPurchases() => OneStorePurchaseService();
}

/// ONE store arka ucunu kaydeder; `--dart-define=STORE=onestore` olmadan devreye girmez.
void registerOneStore() => StoreBackends.register(OneStoreBackend());
