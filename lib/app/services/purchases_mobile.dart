import 'dart:async';
import 'dart:io' show Platform;

import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/monetization.dart';
import 'purchases.dart';

PurchaseService createPurchaseService() =>
    (Platform.isAndroid || Platform.isIOS) ? StorePurchaseService() : NoPurchaseService();

class StorePurchaseService implements PurchaseService {
  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, ProductDetails> _details = {};
  bool _available = false;

  @override
  bool get available => _available;

  @override
  List<StoreProduct> get products =>
      _details.values.map((d) => StoreProduct(d.id, d.price)).toList();

  @override
  Future<void> init(void Function(PurchaseEvent e) onEvent) async {
    try {
      _available = await _iap.isAvailable();
      if (!_available) return;
      _sub = _iap.purchaseStream.listen((list) async {
        for (final p in list) {
          final status = switch (p.status) {
            PurchaseStatus.pending => 'pending',
            PurchaseStatus.purchased => 'purchased',
            PurchaseStatus.restored => 'restored',
            PurchaseStatus.error => 'error',
            PurchaseStatus.canceled => 'canceled',
          };
          onEvent(PurchaseEvent(p.productID, p.purchaseID ?? '', status, _verify(p)));
          if (p.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(p);
            } catch (_) {}
          }
        }
      }, onError: (Object _) {});
      final resp = await _iap.queryProductDetails(Products.all);
      for (final d in resp.productDetails) {
        _details[d.id] = d;
      }
    } catch (_) {
      _available = false;
    }
  }

  /// Local verification: the store must return signed verification data.
  /// For production, send `serverVerificationData` to a validation server
  /// (Google Play Developer API / App Store Server API) before granting.
  bool _verify(PurchaseDetails p) =>
      p.verificationData.serverVerificationData.isNotEmpty &&
      Products.all.contains(p.productID);

  @override
  Future<bool> buy(String productId) async {
    final d = _details[productId];
    if (!_available || d == null) return false;
    final param = PurchaseParam(productDetails: d);
    try {
      if (Products.consumable.contains(productId)) {
        return await _iap.buyConsumable(purchaseParam: param);
      }
      return await _iap.buyNonConsumable(purchaseParam: param);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> restore() async {
    if (!_available) return;
    try {
      await _iap.restorePurchases();
    } catch (_) {}
  }

  @override
  void dispose() => _sub?.cancel();
}
