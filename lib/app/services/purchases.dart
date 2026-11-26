import 'store_backend.dart';

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

/// Google Play Billing / StoreKit through `in_app_purchase`, HMS IAP in
/// AppGallery builds (see [StoreBackends]). No-op on Web.
abstract class PurchaseService {
  bool get available;
  List<StoreProduct> get products;

  Future<void> init(void Function(PurchaseEvent e) onEvent);
  Future<bool> buy(String productId);
  Future<void> restore();
  void dispose();

  static PurchaseService create() => StoreBackends.current.createPurchases();
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
