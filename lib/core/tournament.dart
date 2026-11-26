/// Aile Turnuvası: aynı cihazda 2–8 kişi, merkezin oyunlarıyla turlar.
///
/// Saf Dart (Flutter'sız test edilir): fikstür, puanlama, sıralama ve
/// kaldığı yerden devam için JSON. Kişisel bilgi yok: yalnızca takma ad ve
/// hayvan simgesi, yalnızca bu cihazda saklanır.
library;

import 'level_plan.dart';
import 'rng.dart';

/// Oyuncu simgeleri (çocuklara uygun hayvanlar).
const kTournamentAvatars = ['🦊', '🐼', '🐯', '🐸', '🐧', '🦁', '🐨', '🐙', '🦄', '🐢', '🐝', '🦉'];

class TPlayer {
  String name;
  int avatar;
  TPlayer(this.name, this.avatar);

  /// Takma ad: en çok 14 karakter, satır sonu yok.
  static String clean(String s) {
    final t = s.replaceAll(RegExp(r'[\r\n\t]'), ' ').trim();
    return t.length <= 14 ? t : t.substring(0, 14);
  }

  String get icon => kTournamentAvatars[avatar % kTournamentAvatars.length];
  Map<String, Object?> toJson() => {'n': name, 'a': avatar};
  static TPlayer fromJson(Map<dynamic, dynamic> j) => TPlayer(j['n'] as String? ?? '', (j['a'] as num?)?.toInt() ?? 0);
}

/// Turnuvadaki bir oyun. [seats] ≥ 2: aynı cihazda birlikte oynanan oyun
/// (en çok bu kadar kişi bir arada); 0/1: herkes sırayla aynı bölümü oynar.
class TGame {
  final String gameId;
  final int seats;
  const TGame(this.gameId, this.seats);
  bool get together => seats >= 2;
  Map<String, Object?> toJson() => {'g': gameId, 's': seats};
  static TGame fromJson(Map<dynamic, dynamic> j) => TGame(j['g'] as String? ?? '', (j['s'] as num?)?.toInt() ?? 0);
}

/// Sırayla oynanan oyunda bir oyuncunun sonucu.
class TScore {
  final bool done, won;
  final int score, ms;
  const TScore({this.done = true, this.won = false, this.score = 0, this.ms = 0});

  /// Oyundan çıktı (vazgeçti).
  const TScore.gaveUp()
      : done = false,
        won = false,
        score = 0,
        ms = 0;

  /// Karşılaştırma: tamamlayan > kazanan > yüksek puan > kısa süre.
  int compareTo(TScore o) {
    if (done != o.done) return done ? -1 : 1;
    if (won != o.won) return won ? -1 : 1;
    if (score != o.score) return o.score.compareTo(score);
    return ms.compareTo(o.ms);
  }

  Map<String, Object?> toJson() => {'d': done, 'w': won, 's': score, 'm': ms};
  static TScore fromJson(Map<dynamic, dynamic> j) => TScore(
      done: j['d'] != false, won: j['w'] == true, score: (j['s'] as num?)?.toInt() ?? 0, ms: (j['m'] as num?)?.toInt() ?? 0);
}

/// Fikstürde bir karşılaşma: bir turda bir oyun (birlikte oynanan oyunda
/// kalabalık aileler için gruplar halinde).
class TMatch {
  final int round, game, group, groups;
  final List<int> players;
  const TMatch(this.round, this.game, this.group, this.groups, this.players);
}

class Tournament {
  static const minPlayers = 2, maxPlayers = 8, maxRounds = 5;

  /// Sıra puanları: 1. 3 puan, 2. 2 puan, 3. 1 puan.
  static const placePoints = [3, 2, 1];

  final int seed;
  final List<TPlayer> players;
  final List<TGame> games;
  final int rounds;

  /// Şu anki karşılaşma ve (sırayla oyunlarda) oynayan oyuncu sırası.
  int matchIndex = 0;
  int turn = 0;

  /// Sürmekte olan sırayla oyunun sonuçları (oyuncu → sonuç).
  final Map<int, TScore> current = {};

  /// Biten karşılaşmaların puanları: her biri oyuncu sayısı uzunluğunda.
  final List<List<int>> awarded = [];

  late final List<TMatch> schedule = _schedule();

  Tournament({required this.seed, required this.players, required this.games, this.rounds = 1}) {
    if (valid) _skipByes();
  }

  /// Bay geçen (tek kişilik) karşılaşmalar oynanmadan 1 puanla geçilir.
  void _skipByes() {
    while (matchIndex < schedule.length && schedule[matchIndex].players.length < 2) {
      final pts = List<int>.filled(players.length, 0);
      for (final p in schedule[matchIndex].players) {
        pts[p] = 1;
      }
      awarded.add(pts);
      matchIndex++;
    }
  }

  bool get valid =>
      players.length >= minPlayers && players.length <= maxPlayers && games.isNotEmpty && rounds >= 1 && rounds <= maxRounds;

  List<TMatch> _schedule() {
    final out = <TMatch>[];
    final n = players.length;
    for (var r = 0; r < rounds; r++) {
      for (var g = 0; g < games.length; g++) {
        final game = games[g];
        // Her turda başlayan oyuncu değişir (adil sıra).
        final order = [for (var i = 0; i < n; i++) (i + r + g) % n];
        if (!game.together || game.seats >= n) {
          out.add(TMatch(r, g, 0, 1, order));
          continue;
        }
        // Gruplar olabildiğince eşit. İki kişilik oyunda oyuncu sayısı tekse
        // bir kişi bu karşılaşmada bay geçer (tek kişilik grup: oynamadan
        // 1 puan; her turda başka biri, çünkü sıra döner).
        final groups = (n / game.seats).ceil();
        final base = n ~/ groups, extra = n % groups;
        var k = 0;
        for (var gi = 0; gi < groups; gi++) {
          final size = base + (gi < extra ? 1 : 0);
          out.add(TMatch(r, g, gi, groups, order.sublist(k, k + size)));
          k += size;
        }
      }
    }
    return out;
  }

  bool get finished => matchIndex >= schedule.length;
  TMatch? get match => finished ? null : schedule[matchIndex];
  TGame? get game => finished ? null : games[match!.game];

  /// Sırayla oyunda şimdi oynayacak oyuncu.
  int? get player {
    final m = match;
    if (m == null || game!.together || turn >= m.players.length) return null;
    return m.players[turn];
  }

  /// Karşılaşmanın bölümü: aynı karşılaşmada herkes aynı bölümü oynar.
  LevelSpec specFor(TMatch m, {int difficulty = 3}) {
    final s = mixSeed([seed, m.round, m.game, m.group, 515]);
    return LevelSpec(
      levelId: 50 + m.round,
      seed: s,
      difficulty: difficulty,
      world: 1,
      theme: s % 12,
      mechanics: const [],
      reward: 0,
      version: 1,
      mode: games[m.game].together ? GameModeId.versus : GameModeId.practice,
      source: LevelSource.procedural,
      milestone: false,
    );
  }

  /// Sırayla oyunda bir oyuncunun sonucu. Karşılaşma bittiyse true.
  bool submitTurn(TScore s) {
    final p = player;
    if (p == null) return false;
    current[p] = s;
    turn++;
    if (turn < match!.players.length) return false;
    _award(_turnPoints());
    return true;
  }

  List<int> _turnPoints() {
    final pts = List<int>.filled(players.length, 0);
    final ids = current.keys.toList();
    for (final i in ids) {
      final s = current[i]!;
      if (!s.done) continue;
      // Yarışma sıralaması: eşit sonuçlar aynı sırayı paylaşır.
      final place = 1 + ids.where((j) => current[j]!.compareTo(s) < 0).length;
      if (place <= placePoints.length) pts[i] = placePoints[place - 1];
    }
    return pts;
  }

  /// Birlikte oynanan oyunun sonucu: kazanan oyuncu (turnuvadaki dizini),
  /// -1 berabere. Kazanan 3 puan, beraberlikte herkes 1 puan.
  void submitTogether(int winner) {
    final m = match;
    if (m == null) return;
    final pts = List<int>.filled(players.length, 0);
    if (winner >= 0 && m.players.contains(winner)) {
      pts[winner] = placePoints.first;
    } else {
      for (final p in m.players) {
        pts[p] = 1;
      }
    }
    _award(pts);
  }

  void _award(List<int> pts) {
    awarded.add(pts);
    current.clear();
    turn = 0;
    matchIndex++;
    _skipByes();
  }

  List<int> get totals {
    final t = List<int>.filled(players.length, 0);
    for (final a in awarded) {
      for (var i = 0; i < t.length && i < a.length; i++) {
        t[i] += a[i];
      }
    }
    return t;
  }

  /// Birincilik sayısı (eşit puanda ayırıcı).
  List<int> get firsts {
    final f = List<int>.filled(players.length, 0);
    for (final a in awarded) {
      for (var i = 0; i < f.length && i < a.length; i++) {
        if (a[i] == placePoints.first) f[i]++;
      }
    }
    return f;
  }

  /// Sıralama: puan, sonra birincilik sayısı (oyuncu dizinleri).
  List<int> get standings {
    final t = totals, f = firsts;
    final l = [for (var i = 0; i < players.length; i++) i];
    l.sort((a, b) {
      final c = t[b].compareTo(t[a]);
      if (c != 0) return c;
      final d = f[b].compareTo(f[a]);
      return d != 0 ? d : a.compareTo(b);
    });
    return l;
  }

  /// Şampiyon(lar): en çok puan ve birincilik; eşitse ortak şampiyon.
  List<int> get champions {
    final s = standings;
    if (s.isEmpty) return const [];
    final t = totals, f = firsts;
    final top = s.first;
    return [for (final i in s) if (t[i] == t[top] && f[i] == f[top]) i];
  }

  double get progress => schedule.isEmpty ? 1 : matchIndex / schedule.length;

  Map<String, Object?> toJson() => {
        'v': 1,
        'seed': seed,
        'p': [for (final p in players) p.toJson()],
        'g': [for (final g in games) g.toJson()],
        'r': rounds,
        'mi': matchIndex,
        't': turn,
        'c': {for (final e in current.entries) '${e.key}': e.value.toJson()},
        'a': awarded,
      };

  static Tournament? fromJson(Object? j) {
    if (j is! Map || j['v'] != 1) return null;
    try {
      final t = Tournament(
        seed: (j['seed'] as num).toInt(),
        players: [for (final p in j['p'] as List) TPlayer.fromJson(p as Map)],
        games: [for (final g in j['g'] as List) TGame.fromJson(g as Map)],
        rounds: (j['r'] as num).toInt(),
      );
      if (!t.valid) return null;
      // Kurucunun geçtiği baylar kayıttaki puanlarda zaten var.
      t.awarded.clear();
      t.matchIndex = (j['mi'] as num).toInt().clamp(0, t.schedule.length);
      t.turn = (j['t'] as num?)?.toInt() ?? 0;
      for (final e in ((j['c'] as Map?) ?? const {}).entries) {
        t.current[int.parse('${e.key}')] = TScore.fromJson(e.value as Map);
      }
      for (final a in (j['a'] as List?) ?? const []) {
        t.awarded.add([for (final x in a as List) (x as num).toInt()]);
      }
      return t;
    } catch (_) {
      return null;
    }
  }
}
