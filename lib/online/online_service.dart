/// Çevrimiçi hizmetin uygulama tarafı: Firebase yapılandırılmışsa açılır,
/// değilse bütün çevrimiçi düğmeler gizli kalır ve oyun çevrimdışı çalışır.
///
/// Yapılandırma derlemede `--dart-define` ile gelir (CI'da gizli değişkenlerden):
///   FIREBASE_PROJECT_ID, FIREBASE_API_KEY, FIREBASE_SENDER_ID,
///   FIREBASE_ANDROID_APP_ID, FIREBASE_IOS_APP_ID, FIREBASE_WEB_APP_ID
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../app/game_api.dart';
import 'firebase_backend.dart';
import 'online.dart';

class OnlineConfig {
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const senderId = String.fromEnvironment('FIREBASE_SENDER_ID');
  static const androidAppId = String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');

  static bool get configured => projectId.isNotEmpty && apiKey.isNotEmpty;

  static FirebaseOptions get options {
    final appId = kIsWeb
        ? webAppId
        : defaultTargetPlatform == TargetPlatform.iOS
            ? iosAppId
            : androidAppId;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: senderId,
      projectId: projectId,
      authDomain: '$projectId.firebaseapp.com',
      storageBucket: '$projectId.appspot.com',
    );
  }
}

/// Uygulama genelinde tek çevrimiçi hizmet.
class Online extends ChangeNotifier {
  Online._();
  static final Online instance = Online._();

  OnlineBackend? _backend;
  Profile? profile;
  bool _starting = false;
  Object? lastError;

  /// Testler ve yerel deneme için arka uç verilebilir.
  @visibleForTesting
  void useBackend(OnlineBackend b) => _backend = b;

  bool get available => _backend != null || OnlineConfig.configured;
  bool get ready => profile != null;
  OnlineBackend? get backend => _backend;

  /// Gerekirse Firebase'i başlatır ve anonim oturum açar.
  Future<bool> start() async {
    if (ready) return true;
    if (!available || _starting) return false;
    _starting = true;
    try {
      if (_backend == null) {
        if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: OnlineConfig.options);
        _backend = FirebaseBackend();
      }
      profile = await _backend!.signIn();
      lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      lastError = e;
      return false;
    } finally {
      _starting = false;
    }
  }

  /// Merkez uygulaması bütün oyunların kayıtlarını buradan okur/yazar
  /// (telefon değişiminde hepsi birlikte taşınır).
  Future<Map<String, String>> Function()? exportAll;
  Future<void> Function(Map<String, String> blobs)? importAll;

  Future<String?> createTransfer() async {
    final b = _backend;
    if (b == null || exportAll == null) return null;
    return b.createTransfer(await exportAll!());
  }

  Future<bool> claimTransfer(String code) async {
    final b = _backend;
    if (b == null) return false;
    final blobs = await b.claimTransfer(code.trim());
    if (blobs == null) return false;
    await importAll?.call(blobs);
    notifyListeners();
    return true;
  }

  /// Hesabı ve sunucudaki verileri sil; çevrimiçi baştan başlar.
  Future<void> deleteAccount() async {
    await _backend?.deleteAccount();
    profile = null;
    notifyListeners();
  }

  Future<void> saveProfile() async {
    final p = profile;
    if (p == null) return;
    await _backend!.saveProfile(p);
    notifyListeners();
  }

  /// Bölüm skoru: günlük ve haftalık tablolar (oyun başına) + toplam.
  Future<void> submitDaily(String gameId, String dayKey, String weekKey, int score) async {
    if (!ready || score <= 0) return;
    final b = _backend!;
    unawaited(b.submitScore('d_${gameId}_$dayKey', score).catchError((_) {}));
    unawaited(b.submitScore('w_${gameId}_$weekKey', score).catchError((_) {}));
  }

  /// Lig puanını maç sonucuna göre güncelle.
  Future<void> applyResult(String gameId, List<int> opponentRatings, double score) async {
    final p = profile;
    if (p == null || opponentRatings.isEmpty) return;
    final avg = opponentRatings.reduce((a, b) => a + b) ~/ opponentRatings.length;
    p.rating[gameId] = eloUpdate(p.ratingFor(gameId), avg, score);
    await saveProfile();
    unawaited(_backend!.submitScore('r_$gameId', p.rating[gameId]!).catchError((_) {}));
  }
}

/// Çevrimiçi maçı oyun motorunun beklediği [MatchLink]'e çevirir.
class OnlineMatchLink implements MatchLink {
  final OnlineMatch m;
  OnlineMatchLink(this.m);

  @override
  int get mySeat => m.mySeat;
  @override
  int get seed => m.seed;
  @override
  List<String> get names => [for (final s in m.seats) s.bot ? '' : s.label];
  @override
  bool get isHost => m.isHost;
  @override
  Set<int> get dropped => m.dropped;
  @override
  Stream<(int, String)> get moves => m.moves;
  @override
  Future<void> send(String move, {int? asSeat}) => m.send(move, asSeat: asSeat);
  @override
  Future<void> finish(int winner, {bool? iWon}) async {
    await m.finish(winner);
    // Lig puanı: rakiplerin ortalamasına göre Elo.
    final b = Online.instance.backend;
    if (b == null) return;
    final ratings = <int>[];
    for (var i = 0; i < m.seats.length; i++) {
      final s = m.seats[i];
      if (i == m.mySeat) continue;
      if (s.bot) {
        ratings.add(1000);
        continue;
      }
      final p = await b.profileOf(s.uid).catchError((_) => null);
      ratings.add(p?.ratingFor(m.gameId) ?? 1000);
    }
    final score = winner < 0 ? 0.5 : ((iWon ?? winner == m.mySeat) ? 1.0 : 0.0);
    await Online.instance.applyResult(m.gameId, ratings, score);
  }
}
