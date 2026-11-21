import 'purchases_stub.dart' if (dart.library.io) 'purchases_mobile.dart' as impl;

/// Store product shown in the shop.
class StoreProduct {
  final String id;
  final String price;
  const StoreProduct(this.id, this.price);
}

/// Purchase update forwarded to [PurchaseLedger].
class PurchaseEvent {
  final String productId;
  final String purchaseId;
  final String status; // pending, purchased, restored, error, canceled
  final bool verified;
  const PurchaseEvent(this.productId, this.purchaseId, this.status, this.verified);
}

/// Google Play Billing / StoreKit through `in_app_purchase`. No-op on Web.
abstract class PurchaseService {
  bool get available;
  List<StoreProduct> get products;

  Future<void> init(void Function(PurchaseEvent e) onEvent);
  Future<bool> buy(String productId);
  Future<void> restore();
  void dispose();

  static PurchaseService create() => impl.createPurchaseService();
}

class NoPurchaseService implements PurchaseService {
  @override
  bool get available => false;
  @override
  List<StoreProduct> get products => const [];
  @override
  Future<void> init(void Function(PurchaseEvent e) onEvent) async {}
  @override
  Future<bool> buy(String productId) async => false;
  @override
  Future<void> restore() async {}
  @override
  void dispose() {}
}
