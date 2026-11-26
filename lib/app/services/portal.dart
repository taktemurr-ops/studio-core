import 'dart:async';

import '../edition.dart';
import 'ads.dart';
import 'portal_stub.dart' if (dart.library.js_interop) 'portal_web.dart' as impl;

/// Web oyun portalı köprüsü (CrazyGames, Poki …).
///
/// Dart tarafı SDK'dan bağımsızdır: portal paketinin `index.html` dosyasına
/// eklenen `portal.js` ara katmanı `window.gs100Portal` nesnesini tanımlar ve
/// çağrıları seçilen portalın SDK'sına iletir (bkz. merkezlerin
/// `tool/portal_build.py`). Nesne yoksa (normal web, mobil, masaüstü) her
/// çağrı sessizce hiçbir şey yapmaz.
class Portal {
  Portal._();

  static bool _playing = false;
  static bool _loaded = false;

  /// Reklam sırasında oyunu sessize alıp duraklatmak için (bootstrap ayarlar).
  static Future<void> Function(bool paused)? onAdPause;

  static bool get active => Edition.portal && impl.portalPresent();

  /// Yükleme bitti, oynanış başlamak üzere.
  static void loadingFinished() {
    if (_loaded || !active) return;
    _loaded = true;
    impl.portalCall('loadingStop');
  }

  /// Oyuncu oynamaya başladı / duraklatmadan döndü. Arka arkaya iki kez
  /// gönderilmez (Poki ve CrazyGames kuralı).
  static void gameplayStart() {
    if (_playing || !active) return;
    _playing = true;
    impl.portalCall('gameplayStart');
  }

  /// Oyun durdu: menü, bölüm sonu, duraklatma.
  static void gameplayStop() {
    if (!_playing || !active) return;
    _playing = false;
    impl.portalCall('gameplayStop');
  }

  /// Ara reklam (midgame / commercialBreak). Reklam gösterildiyse true.
  static Future<bool> commercialBreak() => _break('commercialBreak');

  /// Ödüllü reklam. Yalnızca izlenip ödül hak edildiyse true.
  static Future<bool> rewardedBreak() => _break('rewardedBreak');

  static Future<bool> _break(String fn) async {
    if (!active) return false;
    final wasPlaying = _playing;
    if (wasPlaying) gameplayStop();
    final pause = onAdPause;
    try {
      if (pause != null) await pause(true);
      return await impl.portalBreak(fn);
    } catch (_) {
      return false;
    } finally {
      if (pause != null) unawaited(pause(false));
      if (wasPlaying) gameplayStart();
    }
  }
}

/// Portal paketinde reklamlar portalın SDK'sından gelir (AdMob yok).
class PortalAdsService implements AdsService {
  @override
  bool get available => Portal.active;
  @override
  int get failures => 0;
  @override
  Future<bool> init({required bool underAge, required bool personalized, bool child = false}) async =>
      Portal.active;
  @override
  Future<bool> showInterstitial() => Portal.commercialBreak();
  @override
  Future<bool> showRewarded() => Portal.rewardedBreak();
  @override
  Future<void> openPrivacyOptions() async {}
}
