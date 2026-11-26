import 'dart:async';
import 'dart:convert';
import 'dart:io' show ContentType, HttpClient, Platform;

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
          final granted = status == 'purchased' || status == 'restored';
          final ok = granted && await _verify(p);
          onEvent(PurchaseEvent(p.productID, p.purchaseID ?? '', status, ok));
          // Doğrulanmamış satın alma onaylanmaz (acknowledge/finish): mağaza
          // onu bir sonraki açılışta yeniden verir; Google Play 3 gün içinde
          // onaylanmayanı iade eder. Hata/iptal her zaman kapatılır.
          if (p.pendingCompletePurchase && (ok || !granted)) {
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

  /// Sunucu doğrulama adresi (merkez deposundaki server/purchase_verifier;
  /// CI gizli değişkeni PURCHASE_VERIFY_URL). Tanımlı değilse yalnızca yerel
  /// denetim yapılır (bilinen ürün + mağazanın imzalı verisi var mı).
  static const String _verifyUrl = String.fromEnvironment('PURCHASE_VERIFY_URL');

  Future<bool> _verify(PurchaseDetails p) async {
    final data = p.verificationData.serverVerificationData;
    if (data.isEmpty || !Products.all.contains(p.productID)) return false;
    if (_verifyUrl.isEmpty || !_verifyUrl.startsWith('https://')) return true;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(Uri.parse(_verifyUrl));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({
        'platform': Platform.isIOS ? 'ios' : 'android',
        'productId': p.productID,
        'purchaseToken': data,
        'transactionId': p.purchaseID ?? '',
      }));
      final res = await req.close().timeout(const Duration(seconds: 15));
      final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return false;
      final j = jsonDecode(body);
      return j is Map && j['valid'] == true;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

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
