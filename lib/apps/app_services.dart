/// Uygulama merkezlerinin ortak hizmetleri: gizlilik tercihi, reklam,
/// satın alma, favoriler, son kullanılanlar ve dil. Oyunlardaki hizmetleri
/// (AdsService, PurchaseService, PrefsBackend) olduğu gibi kullanır.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../app/services/ads.dart';
import '../app/services/purchases.dart';
import '../core/monetization.dart';
import '../core/save_store.dart';
import 'app_store.dart';

/// Satın alma ya da reklam sonucunu arayüze bildiren olay.
class AppNotice {
  /// Strings anahtarı (ör. 'purchase_ok', 'purchase_failed').
  final String key;
  const AppNotice(this.key);
}

class AppServices {
  final String hubId;
  final KeyValueBackend backend;
  final AdsService ads;
  final PurchaseService purchases;

  /// Arayüz bunu dinleyerek yeniden çizilir.
  final ValueNotifier<int> changes = ValueNotifier<int>(0);

  /// Satın alma bildirimleri (SnackBar için).
  final StreamController<AppNotice> notices = StreamController<AppNotice>.broadcast();

  /// 'granted' / 'denied'; null ise henüz sorulmadı.
  String? consent;

  /// Kullanıcının seçtiği dil (null: cihaz dili).
  String? language;

  Set<String> entitlements = <String>{};
  List<String> favorites = <String>[];
  List<String> recents = <String>[];

  /// Son geçiş reklamı ve uygulamanın açılış anı (ms).
  int lastInterstitialMs = 0;
  final int startedMs;

  /// Geçiş reklamları arasında en az bu kadar süre olur.
  static const adGap = Duration(minutes: 3);

  bool _adsStarted = false;
  bool _purchasesStarted = false;

  AppServices({
    required this.hubId,
    required this.backend,
    required this.ads,
    required this.purchases,
    int? nowMs,
  }) : startedMs = nowMs ?? DateTime.now().millisecondsSinceEpoch;

  String _k(String key) => '$hubId.$key';

  /// Bir araca ait kalıcı depo.
  AppStore storeFor(String toolId) => AppStore(backend, 'app.$toolId');

  Future<void> load() async {
    consent = await backend.read(_k('consent'));
    language = await backend.read(_k('lang'));
    if (language != null && language!.isEmpty) language = null;
    final e = await backend.read(_k('entitlements'));
    entitlements = e == null || e.isEmpty ? <String>{} : e.split(',').toSet();
    favorites = _split(await backend.read(_k('favorites')));
    recents = _split(await backend.read(_k('recents')));
    lastInterstitialMs = int.tryParse(await backend.read(_k('lastAd')) ?? '') ?? 0;
  }

  static List<String> _split(String? raw) =>
      raw == null || raw.isEmpty ? <String>[] : raw.split(',').where((s) => s.isNotEmpty).toList();

  void _changed() => changes.value++;

  bool get adFree => entitlements.contains(Products.removeAds) || entitlements.contains(Products.premium);

  bool get premium => entitlements.contains(Products.premium);

  Future<void> setConsent(bool acceptAll) async {
    consent = acceptAll ? 'granted' : 'denied';
    await backend.write(_k('consent'), consent!);
    _adsStarted = false;
    await startServices();
    _changed();
  }

  Future<void> setLanguage(String? lang) async {
    language = lang;
    await backend.write(_k('lang'), lang ?? '');
    _changed();
  }

  bool isFavorite(String id) => favorites.contains(id);

  Future<void> toggleFavorite(String id) async {
    if (favorites.contains(id)) {
      favorites.remove(id);
    } else {
      favorites.insert(0, id);
    }
    await backend.write(_k('favorites'), favorites.join(','));
    _changed();
  }

  Future<void> touchRecent(String id) async {
    recents.remove(id);
    recents.insert(0, id);
    if (recents.length > 12) recents = recents.sublist(0, 12);
    await backend.write(_k('recents'), recents.join(','));
    _changed();
  }

  /// Gizlilik tercihinden sonra reklam ve mağaza hizmetlerini başlatır.
  Future<void> startServices() async {
    final c = consent;
    if (c == null) return;
    if (!_adsStarted) {
      _adsStarted = true;
      try {
        await ads.init(underAge: false, personalized: c == 'granted');
      } catch (_) {/* reklam olmadan da çalışır */}
    }
    if (!_purchasesStarted && purchases.available) {
      _purchasesStarted = true;
      try {
        await purchases.init(_onPurchase);
      } catch (_) {/* mağaza olmadan da çalışır */}
    }
  }

  void _onPurchase(PurchaseEvent e) {
    final ok = (e.status == 'purchased' || e.status == 'restored');
    if (ok && !e.verified) {
      notices.add(const AppNotice('purchase_unverified'));
      return;
    }
    if (ok && Products.nonConsumable.contains(e.productId)) {
      entitlements.add(e.productId);
      unawaited(backend.write(_k('entitlements'), entitlements.join(',')));
      _changed();
    }
    switch (e.status) {
      case 'purchased':
        notices.add(const AppNotice('purchase_ok'));
      case 'restored':
        notices.add(const AppNotice('purchase_restored'));
      case 'pending':
        notices.add(const AppNotice('purchase_pending'));
      case 'canceled':
        notices.add(const AppNotice('purchase_canceled'));
      case 'error':
        notices.add(const AppNotice('purchase_failed'));
    }
  }

  Future<void> buy(String productId) async {
    if (!purchases.available) {
      notices.add(const AppNotice('store_unavailable'));
      return;
    }
    await startServices();
    final ok = await purchases.buy(productId);
    if (!ok) notices.add(const AppNotice('store_unavailable'));
  }

  Future<void> restore() async {
    if (!purchases.available) {
      notices.add(const AppNotice('store_unavailable'));
      return;
    }
    await startServices();
    await purchases.restore();
  }

  /// Doğal bir duraklamada (araçtan çıkarken) geçiş reklamı gösterebilir.
  /// İşlem sırasında asla çağrılmaz; açılıştan sonra ve iki reklam arasında
  /// en az [adGap] süre bekler.
  Future<bool> naturalBreak({int? nowMs}) async {
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    if (!interstitialAllowed(now)) return false;
    final shown = await ads.showInterstitial();
    if (shown) {
      lastInterstitialMs = now;
      await backend.write(_k('lastAd'), '$now');
    }
    return shown;
  }

  /// Geçiş reklamı kuralları (test edilebilir).
  bool interstitialAllowed(int nowMs) {
    if (adFree || consent == null || !ads.available) return false;
    if (nowMs - startedMs < adGap.inMilliseconds) return false;
    return nowMs - lastInterstitialMs >= adGap.inMilliseconds;
  }

  /// İsteğe bağlı bir ekstrayı ödüllü reklamla açar. Reklamsız sürümde
  /// doğrudan açılır.
  Future<bool> rewarded() async {
    if (adFree) return true;
    if (!ads.available) {
      notices.add(const AppNotice('ad_not_ready'));
      return false;
    }
    final ok = await ads.showRewarded();
    if (!ok) notices.add(const AppNotice('ad_not_ready'));
    return ok;
  }

  /// Bu merkezdeki bütün araç verilerini ve tercihleri siler.
  Future<void> deleteAll(Iterable<String> toolIds) async {
    for (final id in toolIds) {
      await storeFor(id).clearAll();
    }
    for (final k in ['favorites', 'recents', 'lang', 'lastAd']) {
      await backend.remove(_k(k));
    }
    favorites = <String>[];
    recents = <String>[];
    language = null;
    _changed();
  }

  void dispose() {
    unawaited(notices.close());
    changes.dispose();
  }
}
