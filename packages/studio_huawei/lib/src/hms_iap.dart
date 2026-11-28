import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:huawei_iap/huawei_iap.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/core/monetization.dart';

import 'hms_signature.dart';

/// AppGallery Connect'te tanımlanması gereken ürünler (Google Play ile aynı
/// kimlikler, bkz. [Products]).
class HmsProductCatalog {
  HmsProductCatalog._();

  /// HMS ürün türü: 0 tüketilebilir, 1 tüketilemez.
  static int priceTypeOf(String productId) =>
      Products.consumable.contains(productId) ? IapClient.IN_APP_CONSUMABLE : IapClient.IN_APP_NONCONSUMABLE;

  static List<String> idsOf(int priceType) => [
        for (final id in Products.all)
          if (priceTypeOf(id) == priceType) id,
      ];
}

/// HMS IAP Kit ile satın alma.
///
/// Akış Google Play ile aynıdır: ürünler [Products] kimlikleriyle sorulur,
/// satın alma olayları [PurchaseEvent] olarak `PurchaseLedger`'a iletilir,
/// tüketilebilir ürünler teslimden sonra tüketilir; her sipariş AppGallery
/// IAP ortak anahtarıyla imza doğrulamasından geçer ([HmsSignatureVerifier]); teslim edilmemiş
/// (tüketilmemiş) siparişler açılışta yeniden teslim edilir. Tüketilemez
/// ürünler (reklamsız, premium) "geri yükle" ile yeniden etkinleşir.
class HmsPurchaseService implements PurchaseService {
  HmsPurchaseService({HmsSignatureVerifier? verifier})
      : _verifier = verifier ?? HmsSignatureVerifier.fromEnvironment();

  final HmsSignatureVerifier _verifier;
  final Map<String, ProductInfo> _details = {};
  void Function(PurchaseEvent e)? _onEvent;
  bool _available = false;

  static const _ok = '0';
  static const _canceled = '60000';
  static const _owned = '60051';

  @override
  bool get available => _available;

  @override
  List<StoreProduct> get products => [
        for (final d in _details.values)
          if (d.productId != null) StoreProduct(d.productId!, d.price ?? ''),
      ];

  @override
  Future<void> init(void Function(PurchaseEvent e) onEvent) async {
    _onEvent = onEvent;
    if (!Platform.isAndroid) return;
    var env = false;
    try {
      final r = await IapClient.isEnvReady();
      env = r.returnCode == null || r.returnCode == _ok;
    } catch (_) {
      env = false;
    }
    for (final type in const [IapClient.IN_APP_CONSUMABLE, IapClient.IN_APP_NONCONSUMABLE]) {
      try {
        final res = await IapClient.obtainProductInfo(
            ProductInfoReq(priceType: type, skuIds: HmsProductCatalog.idsOf(type)));
        for (final p in res.productInfoList ?? const <ProductInfo>[]) {
          final id = p.productId;
          if (id != null && Products.all.contains(id)) _details[id] = p;
        }
      } catch (_) {}
    }
    _available = env && _details.isNotEmpty;
    if (_available) unawaited(_redeliverConsumables());
  }

  /// Ödemesi alınmış ama teslim/tüketim yarım kalmış tüketilebilirler.
  Future<void> _redeliverConsumables() async {
    try {
      final owned = await IapClient.obtainOwnedPurchases(OwnedPurchasesReq(priceType: IapClient.IN_APP_CONSUMABLE));
      await _deliverOwned(owned, 'purchased');
    } catch (_) {}
  }

  /// Sahip olunan siparişler: imza, ayrıştırılmış nesneden değil yanıttaki
  /// ham `inAppPurchaseData` metninden doğrulanır.
  Future<void> _deliverOwned(OwnedPurchasesResult owned, String status) async {
    final raw = rawList(owned.rawValue, 'inAppPurchaseDataList');
    final sigs = owned.inAppSignature ?? const <String>[];
    for (var i = 0; i < raw.length; i++) {
      await _deliver(raw[i], i < sigs.length ? sigs[i] : '', status, owned.signatureAlgorithm);
    }
  }

  /// Ham imzalı metinler (eklentinin JSON yanıtından).
  static List<String> rawList(String rawValue, String key) {
    try {
      final m = json.decode(rawValue) as Map;
      final v = m[key];
      if (v is List) return [for (final x in v) x is String ? x : json.encode(x)];
    } catch (_) {}
    return const [];
  }

  static String rawField(String rawValue, String key) {
    try {
      final v = (json.decode(rawValue) as Map)[key];
      if (v is String) return v;
      if (v != null) return json.encode(v);
    } catch (_) {}
    return '';
  }

  /// Sipariş doğrulandı mı: imza AppGallery IAP ortak anahtarıyla geçerli,
  /// ürün bizim, uygulama paketi ve ödeme durumu doğru.
  bool isVerified(String rawData, String signature, {String? algorithm, String? expectedPackage}) {
    if (!_verifier.verify(rawData, signature, algorithm: algorithm)) return false;
    try {
      final d = InAppPurchaseData.fromJson(rawData);
      if (!Products.all.contains(d.productId)) return false;
      if ((d.purchaseToken ?? '').isEmpty) return false;
      if (d.purchaseState != null && d.purchaseState != 0) return false;
      if (expectedPackage != null && d.packageName != null && d.packageName != expectedPackage) return false;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// purchaseState 0 = ödendi. Yalnızca ödenmiş ve imzası doğrulanmış
  /// siparişler teslim edilir/tüketilir; doğrulanamayan tüketilebilir
  /// tüketilmez (sonra yeniden teslim edilebilsin).
  Future<void> _deliver(String raw, String signature, String status, [String? algorithm]) async {
    final InAppPurchaseData d;
    try {
      d = InAppPurchaseData.fromJson(raw);
    } catch (_) {
      return;
    }
    final id = d.productId ?? '';
    if (d.purchaseState != null && d.purchaseState != 0) return;
    final verified = isVerified(raw, signature, algorithm: algorithm);
    _onEvent?.call(PurchaseEvent(id, d.orderId ?? d.purchaseToken ?? '', status, verified));
    if (verified && Products.consumable.contains(id)) {
      try {
        await IapClient.consumeOwnedPurchase(ConsumeOwnedPurchaseReq(purchaseToken: d.purchaseToken!));
      } catch (_) {}
    }
  }

  @override
  Future<bool> buy(String productId) async {
    if (!_available || !_details.containsKey(productId)) return false;
    final type = HmsProductCatalog.priceTypeOf(productId);
    try {
      final r = await IapClient.createPurchaseIntent(PurchaseIntentReq(priceType: type, productId: productId));
      switch (r.returnCode) {
        case _ok:
          final raw = rawField(r.rawValue, 'inAppPurchaseData');
          if (raw.isNotEmpty) await _deliver(raw, r.inAppDataSignature ?? '', 'purchased', r.signatureAlgorithm);
        case _canceled:
          _onEvent?.call(PurchaseEvent(productId, '', 'canceled', false));
        case _owned:
          // Zaten sahip: tüketilemezse geri yükle, tüketilebilirse teslim et.
          if (type == IapClient.IN_APP_NONCONSUMABLE) {
            await restore();
          } else {
            await _redeliverConsumables();
          }
        default:
          _onEvent?.call(PurchaseEvent(productId, '', 'error', false));
      }
      return true;
    } catch (_) {
      _onEvent?.call(PurchaseEvent(productId, '', 'error', false));
      return false;
    }
  }

  @override
  Future<void> restore() async {
    if (!_available) return;
    try {
      String? token;
      do {
        final owned = await IapClient.obtainOwnedPurchases(
            OwnedPurchasesReq(priceType: IapClient.IN_APP_NONCONSUMABLE, continuationToken: token));
        await _deliverOwned(owned, 'restored');
        token = owned.continuationToken;
      } while (token != null && token.isNotEmpty);
    } catch (_) {}
  }

  @override
  void dispose() {
    _onEvent = null;
  }
}
