import 'dart:async';
import 'dart:io' show Platform;

import 'package:huawei_iap/huawei_iap.dart';
import 'package:studio_core/app/services/purchases.dart';
import 'package:studio_core/core/monetization.dart';

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
/// tüketilebilir ürünler teslimden sonra tüketilir; teslim edilmemiş
/// (tüketilmemiş) siparişler açılışta yeniden teslim edilir. Tüketilemez
/// ürünler (reklamsız, premium) "geri yükle" ile yeniden etkinleşir.
class HmsPurchaseService implements PurchaseService {
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
      final data = owned.inAppPurchaseDataList ?? const <InAppPurchaseData>[];
      final sigs = owned.inAppSignature ?? const <String>[];
      for (var i = 0; i < data.length; i++) {
        await _deliver(data[i], i < sigs.length ? sigs[i] : '', 'purchased');
      }
    } catch (_) {}
  }

  /// purchaseState 0 = ödendi. Yalnızca ödenmiş siparişler teslim edilir.
  Future<void> _deliver(InAppPurchaseData d, String signature, String status) async {
    final id = d.productId ?? '';
    if (d.purchaseState != null && d.purchaseState != 0) return;
    final verified = signature.isNotEmpty && (d.purchaseToken ?? '').isNotEmpty && Products.all.contains(id);
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
          final d = r.inAppPurchaseData;
          if (d != null) await _deliver(d, r.inAppDataSignature ?? '', 'purchased');
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
        final data = owned.inAppPurchaseDataList ?? const <InAppPurchaseData>[];
        final sigs = owned.inAppSignature ?? const <String>[];
        for (var i = 0; i < data.length; i++) {
          await _deliver(data[i], i < sigs.length ? sigs[i] : '', 'restored');
        }
        token = owned.continuationToken;
      } while (token != null && token.isNotEmpty);
    } catch (_) {}
  }

  @override
  void dispose() {
    _onEvent = null;
  }
}
