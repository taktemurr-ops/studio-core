
import 'package:flutter/services.dart';

import '../../core/monetization.dart';
import 'purchases.dart';

/// Yerel (Java/Kotlin) mağaza SDK'sı ile konuşan ortak satın alma hizmeti.
///
/// Samsung IAP (`studio_samsung`) ve Amazon Appstore IAP (`studio_amazon`)
/// eklentileri aynı kanal sözleşmesini uygular; böylece teslim, tüketme ve
/// "geri yükle" mantığı tek yerde (burada) kalır:
///
/// Dart -> yerel:
/// * `init {skus, consumables, test}` -> `{available: bool, products: [{id, price}]}`
/// * `buy {sku}` -> bool (akış başladı mı); sonuç `purchase` olayıyla gelir
/// * `restore` -> sahip olunan ürünler `purchase` (`restored`) olaylarıyla gelir
/// * `finish {sku, id, consumable}` -> tüketme / teslim bildirimi
///
/// yerel -> Dart: `purchase {sku, id, status, verified}`; status:
/// `purchased`, `restored`, `pending`, `canceled`, `error`.
///
/// Eklenti kayıtlı değilse (MissingPluginException) ya da SDK/mağaza
/// istemcisi yoksa hizmet kullanılamaz durumda kalır ve mağaza bölümü gizlenir.
class NativeChannelPurchaseService implements PurchaseService {
  final MethodChannel channel;

  /// Test (sandbox) kipi: Samsung'da OPERATION_MODE_TEST.
  final bool testMode;

  NativeChannelPurchaseService(String channelName, {this.testMode = false}) : channel = MethodChannel(channelName);

  final List<StoreProduct> _products = [];
  void Function(PurchaseEvent e)? _onEvent;
  bool _available = false;

  @override
  bool get available => _available;

  @override
  List<StoreProduct> get products => List.unmodifiable(_products);

  @override
  Future<void> init(void Function(PurchaseEvent e) onEvent) async {
    _onEvent = onEvent;
    channel.setMethodCallHandler(_handle);
    try {
      final r = await channel.invokeMapMethod<String, Object?>('init', {
        'skus': Products.all.toList(),
        'consumables': Products.consumable.toList(),
        'test': testMode,
      });
      _products.clear();
      for (final p in (r?['products'] as List?) ?? const []) {
        if (p is! Map) continue;
        final id = p['id']?.toString() ?? '';
        if (Products.all.contains(id)) _products.add(StoreProduct(id, p['price']?.toString() ?? ''));
      }
      _available = r?['available'] == true && _products.isNotEmpty;
    } on MissingPluginException {
      _available = false;
    } on PlatformException {
      _available = false;
    }
  }

  Future<void> _handle(MethodCall call) async {
    if (call.method != 'purchase') return;
    final m = (call.arguments as Map?) ?? const {};
    await deliver(
      m['sku']?.toString() ?? '',
      m['id']?.toString() ?? '',
      m['status']?.toString() ?? 'error',
      m['verified'] == true,
    );
  }

  /// Bir satın alma olayını deftere iletir; ödenmiş ve doğrulanmış
  /// tüketilebilirler teslimden SONRA tüketilir (yarım kalırsa açılışta
  /// `restore` yeniden teslim eder).
  Future<void> deliver(String sku, String id, String status, bool verified) async {
    final known = Products.all.contains(sku);
    _onEvent?.call(PurchaseEvent(sku, id, status, verified && known));
    if (!known || !verified || id.isEmpty) return;
    if (status != 'purchased' && status != 'restored') return;
    try {
      await channel.invokeMethod<void>('finish', {
        'sku': sku,
        'id': id,
        'consumable': Products.consumable.contains(sku),
      });
    } catch (_) {}
  }

  @override
  Future<bool> buy(String productId) async {
    if (!_available || !_products.any((p) => p.id == productId)) return false;
    try {
      return await channel.invokeMethod<bool>('buy', {'sku': productId}) ?? false;
    } catch (_) {
      _onEvent?.call(PurchaseEvent(productId, '', 'error', false));
      return false;
    }
  }

  @override
  Future<void> restore() async {
    if (!_available) return;
    try {
      await channel.invokeMethod<void>('restore');
    } catch (_) {}
  }

  @override
  void dispose() {
    _onEvent = null;
    channel.setMethodCallHandler(null);
  }
}
