import '../core/strings.dart';
import 'package:flutter/material.dart';

import '../core/game_rules.dart';
import '../core/level_plan.dart';
import 'services/audio.dart';

/// Everything a game screen needs from the shell.
/// Bir koltuğu kim oynuyor.
enum SeatRole {
  /// Bu cihazdaki oyuncu.
  local,

  /// Yapay zekâ.
  ai,

  /// Çevrimiçi rakip (hamleleri ağdan gelir).
  remote,
}

/// Çevrimiçi maçın oyun motoruna bakan yüzü: hamle gönderir, rakip
/// hamlelerini dinler. Hamle, oyunun kendi kodladığı bir metindir.
abstract class MatchLink {
  /// Bu cihazın koltuğu.
  int get mySeat;

  /// Maçın ortak tohumu (deste, zar ve dizilim herkes için aynı olur).
  int get seed;

  /// Koltuk adları (oyuncu takma adları; bot koltukları için boş).
  List<String> get names;

  /// Bu cihazın hamlesini yayınlar. [asSeat]: maçın ev sahibi, botların ve
  /// bağlantısı kopan oyuncuların yerine oynarken o koltuk adına gönderir.
  Future<void> send(String move, {int? asSeat});

  /// Botların hamlelerini bu cihaz mı hesaplıyor (maçın ev sahibi).
  bool get isHost;

  /// Bağlantısı kopan oyuncular: bu koltuklara artık bot oynar.
  Set<int> get dropped;

  /// Rakiplerin hamleleri, sırayla.
  Stream<(int seat, String move)> get moves;

  /// Maça geri dönüldüyse o ana kadarki bütün hamleler (bu cihazınkiler
  /// dahil); motor bunları [moves]'tan önce, beklemeden uygular.
  List<(int seat, String move)> get history;

  /// Maç bitti: kazanan koltuk (-1 berabere). [iWon]: eşli oyunlarda
  /// takım arkadaşı kazandıysa da doğru.
  Future<void> finish(int winner, {bool? iWon});
}

/// Çevrimiçi maçta gerçek zamanlı kanal (ör. [OnlineMatchLink]): hamle
/// günlüğünün yanında, saniyede birkaç kez gönderilen anlık durum ve girdi
/// mesajları için. Mesajlar aynı anda birden çok koltuktan gelebilir.
/// Dinlemeye başlayınca son birkaç mesaj (bu cihazınkiler dahil) bir kez
/// gelir; sonra yalnızca diğer koltukların mesajları. Eşitleme protokolü:
/// `core/net_sync.dart`.
abstract class RealtimeLink {
  Stream<(int seat, String data)> get pulses;
  Future<void> pulse(String data, {int? asSeat});
}

class PlayContext {
  final LevelSpec spec;

  /// The validated puzzle produced by [GameRules.build] for [spec].
  final GeneratedLevel generated;
  final Map<String, Object?> resume;
  final List<Color> pieceColors;
  final List<Color> background;
  final bool colorBlind;
  final bool reducedMotion;
  final bool leftHanded;
  final String lang;
  final String Function(String key, [Map<String, Object> params]) t;

  /// Ends the round; the shell shows results, rewards, achievements.
  final void Function(RoundResult result) finish;

  /// Persists an in-progress round so it can be resumed after the app is
  /// killed (doc 6.3 / 10: "uygulama kapanma testi").
  final void Function(Map<String, Object?> state) saveResume;

  /// Spends a hint (or offers a rewarded ad). True = hint granted.
  final Future<bool> Function() requestHint;

  /// Spends a booster (or offers coins). True = granted.
  final Future<bool> Function() requestBooster;

  /// Offers "continue" after a fail (ad or coins). True = keep playing.
  final Future<bool> Function() requestContinue;

  final void Function(Sfx s) sfx;

  /// Plays a named extra sound asset (piano notes, animal calls ...).
  final void Function(String name) sound;

  const PlayContext({
    required this.spec,
    required this.generated,
    required this.resume,
    required this.pieceColors,
    required this.background,
    required this.colorBlind,
    required this.reducedMotion,
    required this.leftHanded,
    required this.lang,
    required this.t,
    required this.finish,
    required this.saveResume,
    required this.requestHint,
    required this.requestBooster,
    required this.requestContinue,
    required this.sfx,
    this.sound = _noSound,
    this.seats = const [],
    this.match,
  });

  /// Koltuk rolleri; boşsa koltuk 0 bu cihaz, diğerleri yapay zekâ.
  final List<SeatRole> seats;

  /// Çevrimiçi maçta ağ bağlantısı; değilse null.
  final MatchLink? match;

  SeatRole role(int seat) {
    if (seat < seats.length) return seats[seat];
    if (seats.isEmpty && seat == 0) return SeatRole.local;
    return SeatRole.ai;
  }

  /// Aynı cihazda birden çok kişi oynuyor mu.
  bool get passAndPlay => seats.where((r) => r == SeatRole.local).length > 1;

  /// Koltuğun ekranda görünen adı.
  String seatName(int seat) {
    final m = match;
    if (m != null && seat < m.names.length && m.names[seat].isNotEmpty) return m.names[seat];
    return t('player_n', {'n': seat + 1});
  }

  static void _noSound(String name) {}

  String symbol(int i) => const ['●', '■', '▲', '◆', '★', '✚', '♥', '⬟', '✱', '☾'][i % 10];
}

class TutorialStep {
  final IconData icon;
  final List<String> text; // tr, en, de, es, fr
  const TutorialStep(this.icon, this.text);
}

/// Oyunun kendi ek modu (ana ekranda mod kartı): ör. "Öğretici". Kart
/// dokunulunca [builder]'ın ekranı onaylı stüdyo iskeletinde açılır.
class ExtraMode {
  /// Kalıcı kimlik (ör. 'ogretici'); ölçüm ve testler için.
  final String id;

  /// Kart başlığı ve kısa açıklaması (33 dil, [Strings.pick] sırası).
  final List<String> title;
  final List<String> subtitle;
  final IconData icon;
  final Color color;

  /// Modun gövdesi. [lang] arayüz dili (ör. 'tr').
  final Widget Function(BuildContext context, String lang) builder;

  const ExtraMode({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.builder,
    this.color = const Color(0xFF2E9E78),
  });
}

/// Privacy policy address shared by every game of a hub; set once at start-up
/// (see `bootstrapApprovedHub`). Used when a game has no own [GameConfig.privacyUrl].
String hubPrivacyUrl = '';

/// Per-game configuration consumed by the shared shell.
class GameConfig {
  final String gameId;
  final List<String> title; // tr, en, de, es, fr
  final List<String> tagline;
  final Color seedColor;
  final IconData icon;
  final GameRules rules;
  final Widget Function(PlayContext ctx) buildPlay;
  final List<TutorialStep> tutorial;
  final Map<String, List<String>> strings;
  final String privacyUrl;

  /// Designed-for-families title: every player is treated as a child
  /// (child-directed ads, no analytics), purchases sit behind a parental gate.
  final bool kidsMode;

  /// Oyunun ana ekranında "Diğer modlar" arasında duran kendi ek modları
  /// (ör. adım adım öğretici). Her biri bir mod kartı olarak çizilir.
  final List<ExtraMode> extraModes;

  const GameConfig({
    required this.gameId,
    required this.title,
    required this.tagline,
    required this.seedColor,
    required this.icon,
    required this.rules,
    required this.buildPlay,
    required this.tutorial,
    this.strings = const {},
    this.privacyUrl = '',
    this.kidsMode = false,
    this.extraModes = const [],
  });

  /// The privacy page to open: the game's own address, else the hub's.
  String get effectivePrivacyUrl => privacyUrl.isNotEmpty ? privacyUrl : hubPrivacyUrl;

  String localized(List<String> l, String lang) {
    return Strings.pick(l, lang);
  }
}
