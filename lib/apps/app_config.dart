/// Uygulama merkezleri (Araç Kutusu, Verimlilik, Sağlık ve Spor …) için
/// yapılandırma: araçlar, kategoriler ve merkezin görünümü.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/approved_hub.dart' show ApprovedHubStyle;
import '../core/strings.dart';
import 'app_services.dart';
import 'app_store.dart';
import 'app_tx.dart';

/// Araç sayfasının üstündeki uyarı türü.
enum AppDisclaimer {
  none,

  /// Sağlık / iyi yaşam: tıbbi cihaz değildir.
  wellness,

  /// Finans / vergi / hukuk: tavsiye değildir.
  finance,
}

/// Bir aracın çalıştığı bağlam: dil, kalıcı depo ve ortak hizmetler.
class ToolContext {
  final String toolId;
  final String lang;
  final AppStore store;
  final AppServices services;

  const ToolContext({required this.toolId, required this.lang, required this.store, required this.services});

  /// 33 dillik listeden bu dilin metni.
  String t(List<String> l) => Strings.pick(l, lang);

  /// Ortak uygulama metni (app_tx.dart).
  String tx(String key, [Map<String, Object> p = const {}]) => appTx(key, lang, p);

  /// Çekirdek metin (Ayarlar, İptal, Tamam …).
  String core(String key) => Strings(lang).t(key);

  bool get isWeb => kIsWeb;

  bool get rtl => Strings(lang).rtl;

  /// İsteğe bağlı ekstrayı ödüllü reklamla bugünlük açar.
  Future<bool> unlockForToday(String feature) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (await store.read('unlock.$feature') == today) return true;
    final ok = await services.rewarded();
    if (ok) await store.write('unlock.$feature', today);
    return ok;
  }

  Future<bool> unlockedToday(String feature) async {
    if (services.adFree) return true;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    return await store.read('unlock.$feature') == today;
  }
}

typedef AppToolBuilder = Widget Function(BuildContext context, ToolContext tool);

/// Merkezdeki tek bir uygulama (kendi deposunda yaşar).
class AppTool {
  /// Depo adı ile aynı kimlik (ör. 'uyg-hesap-makinesi').
  final String id;
  final List<String> title;
  final List<String> tagline;
  final IconData icon;
  final Color color;

  /// [AppCategory.id].
  final String category;
  final AppDisclaimer disclaimer;

  /// Arama için ek sözcükler (her dilde aynı; ör. 'qr', 'gps').
  final List<String> keywords;
  final AppToolBuilder builder;

  const AppTool({
    required this.id,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.category,
    required this.builder,
    this.disclaimer = AppDisclaimer.none,
    this.keywords = const [],
  });
}

class AppCategory {
  final String id;
  final List<String> title;
  final IconData icon;
  const AppCategory({required this.id, required this.title, required this.icon});
}

/// Bir uygulama merkezinin tamamı.
class AppHubConfig {
  final String hubId;
  final List<String> title;
  final List<String> tagline;
  final IconData icon;

  /// Oyun merkezlerinin onaylı tasarımıyla aynı renk ve görsel kodları.
  final ApprovedHubStyle style;
  final List<AppCategory> categories;
  final List<AppTool> tools;

  /// Ana sayfada öne çıkan araçların kimlikleri.
  final List<String> featured;

  /// Gizlilik politikası adresi (isteğe bağlı).
  final String? privacyUrl;

  const AppHubConfig({
    required this.hubId,
    required this.title,
    required this.tagline,
    required this.icon,
    required this.style,
    required this.categories,
    required this.tools,
    this.featured = const [],
    this.privacyUrl,
    this.mobileOnly = const [],
  });

  /// Masaüstü sürümünde gizlenen araçlar (kamera, ML Kit, sensör, GPS …
  /// gerektirenler; bkz. `ship/MASAUSTU_WEB.md`).
  final List<String> mobileOnly;

  /// Bu platformda gösterilecek merkez: masaüstünde [mobileOnly] araçları
  /// listelerden çıkarılır.
  AppHubConfig forPlatform({required bool desktop}) {
    if (!desktop || mobileOnly.isEmpty) return this;
    bool keep(AppTool t) => !mobileOnly.contains(t.id);
    return AppHubConfig(
      hubId: hubId,
      title: title,
      tagline: tagline,
      icon: icon,
      style: style,
      categories: [
        for (final c in categories)
          if (tools.any((t) => t.category == c.id && keep(t))) c,
      ],
      tools: [for (final t in tools) if (keep(t)) t],
      featured: [for (final f in featured) if (!mobileOnly.contains(f)) f],
      privacyUrl: privacyUrl,
    );
  }

  String localized(List<String> l, String lang) => Strings.pick(l, lang);

  AppTool? tool(String id) {
    for (final t in tools) {
      if (t.id == id) return t;
    }
    return null;
  }
}
