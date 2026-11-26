import 'package:flutter/foundation.dart';

import '../core/monetization.dart';

/// Uygulamanın dağıtım sürümü: mobil (Google Play / App Store / AppGallery),
/// masaüstü (Microsoft Store / Mac App Store) ya da web oyun portalı paketi.
///
/// * Masaüstü sürümü mağazada **ücretli ve tam sürüm** olarak satılır:
///   reklam yok, uygulama içi satın alma yok, premium avantajları açık
///   (bkz. `ship/MASAUSTU_WEB.md`). Windows/macOS/Linux'ta kendiliğinden
///   etkindir; `--dart-define=EDITION=desktop` ile zorlanabilir,
///   `--dart-define=EDITION=mobile` ile kapatılabilir.
/// * Portal paketi (`--dart-define=PORTAL=1`, yalnızca web): tek oyun,
///   dış bağlantı yok, reklam ve duraklatma portalın SDK'sına gider
///   (bkz. `services/portal.dart`).
class Edition {
  Edition._();

  /// Ham `EDITION` değeri (boş: platformdan çıkarılır).
  static const String raw = String.fromEnvironment('EDITION');

  /// Ham `PORTAL` değeri (boş: portal paketi değil).
  static const String portalRaw = String.fromEnvironment('PORTAL');

  @visibleForTesting
  static bool? debugDesktop;

  @visibleForTesting
  static bool? debugPortal;

  /// Masaüstü (ücretli, reklamsız, premium açık) sürüm mü?
  static bool get desktop {
    final o = debugDesktop;
    if (o != null) return o;
    if (raw == 'desktop') return true;
    if (raw.isNotEmpty) return false;
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Web oyun portalı paketi mi (CrazyGames / Poki tarzı tek oyunluk paket)?
  static bool get portal {
    final o = debugPortal;
    if (o != null) return o;
    return kIsWeb && portalRaw.isNotEmpty && portalRaw != '0';
  }

  /// Dış bağlantılar (gizlilik sayfası, mağaza, kardeş uygulamalar) gösterilir mi?
  /// Portallar oyun içinden dışarı bağlantıya izin vermez.
  static bool get externalLinks => !portal;

  /// Masaüstü sürümünde satın alınmış sayılan kalıcı ürünler: mağazada
  /// ücretli indirilen tam sürüm reklamsız ve premiumdur.
  static const Set<String> desktopEntitlements = {Products.premium, Products.removeAds};
}
