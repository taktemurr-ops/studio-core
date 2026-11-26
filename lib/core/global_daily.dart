/// Günün Bulmacası: dünyadaki herkes aynı gün (UTC) aynı bulmacayı çözer.
///
/// Saf Dart: gün anahtarı, tohum, sıralama anahtarı, yerel sonuç kaydı
/// (seri, çevrimdışı bekleyen sonuçlar) ve paylaşım metni. Oyunlar
/// [GameRules.globalDaily] ile katılır; bölümü motor verir
/// ([GameRules.globalDailySpec]).
library;

import 'dart:convert';

import 'clock.dart';
import 'level_plan.dart';
import 'rng.dart';
import 'save_store.dart';

/// Günlük sıralamanın ölçütü.
enum DailyRank {
  /// Bulmaca: kısa süre (eşitlikte az hamle) önde.
  time,

  /// Puan oyunu: yüksek puan önde.
  score,
}

class GlobalDaily {
  GlobalDaily._();

  /// 1 numaralı günlük bulmacanın günü.
  static const firstDay = '2026-01-01';

  /// UTC gün anahtarı (YYYY-AA-GG): her saat diliminde aynı gün aynı bulmaca.
  static String utcDay(DateTime t) => DateKeys.day(t.toUtc());

  /// Bulmacanın numarası (#1 = 2026-01-01).
  static int number(String day) => DateKeys.daysBetween(firstDay, day) + 1;

  /// Bir sonraki bulmacaya kalan süre (UTC gece yarısı).
  static Duration untilNext(DateTime now) {
    final u = now.toUtc();
    return DateTime.utc(u.year, u.month, u.day + 1).difference(u);
  }

  /// Önceki/sonraki gün anahtarı.
  static String shift(String day, int days) {
    final d = DateTime.tryParse(day) ?? DateTime.utc(2026);
    return DateKeys.day(DateTime.utc(d.year, d.month, d.day + days));
  }

  /// Haftanın gününe göre zorluk: pazartesi 4 … pazar 7 (herkes için aynı).
  static int defaultDifficulty(String day) {
    final d = DateTime.tryParse(day) ?? DateTime.utc(2026);
    return const [4, 4, 5, 5, 6, 6, 7][(DateTime.utc(d.year, d.month, d.day).weekday - 1) % 7];
  }

  /// Ortak tohum: oyun kimliği + gün (cihaza, dile ve saate bağlı değil).
  static int seed(String gameId, String day) => mixSeed([stableHash(gameId), stableHash('global-daily:$day'), 2026]);

  /// Varsayılan günlük bölüm; motorlar [GameRules.globalDailySpec] ile değiştirebilir.
  static LevelSpec defaultSpec(String gameId, String day, {int? difficulty, List<String> mechanics = const []}) {
    final s = seed(gameId, day);
    return LevelSpec(
      levelId: 0,
      seed: s,
      difficulty: difficulty ?? defaultDifficulty(day),
      world: 0,
      theme: s % 12,
      mechanics: mechanics,
      reward: 150,
      version: 1,
      mode: GameModeId.daily,
      source: LevelSource.procedural,
      milestone: false,
    );
  }

  /// Sıralama tablosunun kimliği. Dile bağlı oyunlarda (kelime) her dilin
  /// tablosu ayrıdır, çünkü bulmaca dile göre değişir.
  static String board(String gameId, String day, {String lang = ''}) =>
      lang.isEmpty ? '${gameId}_$day' : '$gameId-${lang}_$day';

  /// Sunucuda tek alanla sıralama için anahtar (küçük olan önde).
  /// Süre: ms × 1000 + hamle; puan: 1.000.000.000 − puan.
  static int sortKey(DailyRank rank, int ms, int moves, int score) => rank == DailyRank.time
      ? ms * 1000 + moves.clamp(0, 999)
      : 1000000000 - score.clamp(0, 999999999);

  /// Günün seçkisi: katılan oyunlardan her gün bir tanesi (herkes için aynı).
  static String? featured(Iterable<String> ids, String day) {
    final l = ids.toList()..sort();
    if (l.isEmpty) return null;
    return l[(mixSeed([stableHash('featured:$day')]) & 0x7fffffff) % l.length];
  }

  /// 83 sn → "1:23", 3725 sn → "1:02:05".
  static String clock(int ms) {
    final s = (ms / 1000).round();
    final h = s ~/ 3600, m = (s % 3600) ~/ 60, x = s % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(x)}' : '$m:${two(x)}';
  }

  /// Paylaşım metni: bulmacanın kendisini (harf, sayı, çözüm) içermez.
  /// Son 7 günün izi: 🟦 çözüldü, ▫️ boş, bugün 🌟.
  static String shareText({
    required String title,
    required String gameTitle,
    required DailyEntry e,
    required List<bool> lastWeek,
    required int streak,
  }) {
    final b = StringBuffer('🧩 $title #${number(e.day)} · $gameTitle\n');
    if (e.rank == DailyRank.time) {
      b.write('⏱️ ${clock(e.ms)}');
      if (e.moves > 0) b.write(' · 👣 ${e.moves}');
    } else {
      b.write('⭐ ${e.score} · ⏱️ ${clock(e.ms)}');
    }
    b.write('\n');
    for (var i = 0; i < lastWeek.length; i++) {
      final today = i == lastWeek.length - 1;
      b.write(today ? (lastWeek[i] ? '🌟' : '▫️') : (lastWeek[i] ? '🟦' : '▫️'));
    }
    if (streak > 1) b.write('  🔥$streak');
    return b.toString();
  }
}

/// Bir günlük bulmaca sonucu.
class DailyEntry {
  final String gameId, day, lang;
  final int ms, moves, score;
  final DailyRank rank;

  /// Sunucuya gönderildi mi (çevrimdışıyken false kalır, sonra gönderilir).
  bool synced;

  DailyEntry({
    required this.gameId,
    required this.day,
    required this.ms,
    this.moves = 0,
    this.score = 0,
    this.rank = DailyRank.time,
    this.lang = '',
    this.synced = false,
  });

  String get key => '$gameId|$day';
  int get sortKey => GlobalDaily.sortKey(rank, ms, moves, score);

  Map<String, Object?> toJson() => {
        'g': gameId,
        'd': day,
        'l': lang,
        'ms': ms,
        'mv': moves,
        'sc': score,
        'r': rank.index,
        's': synced,
      };

  static DailyEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final g = j['g'], d = j['d'];
    if (g is! String || d is! String) return null;
    final r = (j['r'] as num?)?.toInt() ?? 0;
    return DailyEntry(
      gameId: g,
      day: d,
      lang: j['l'] as String? ?? '',
      ms: (j['ms'] as num?)?.toInt() ?? 0,
      moves: (j['mv'] as num?)?.toInt() ?? 0,
      score: (j['sc'] as num?)?.toInt() ?? 0,
      rank: DailyRank.values[r.clamp(0, DailyRank.values.length - 1)],
      synced: j['s'] == true,
    );
  }
}

/// Yerel günlük kayıt (merkezde bütün oyunlar için ortak): sonuçlar, seri,
/// gönderilmeyi bekleyenler. Aynı arka uç için tek örnek ([of]).
class GlobalDailyStore {
  static const storageKey = 'gdaily.v1';

  /// Bu kadar günden eski sonuçlar silinir.
  static const keepDays = 40;

  final KeyValueBackend backend;
  final Map<String, DailyEntry> _results = {};
  final Set<String> _days = {};
  int _best = 0;
  Future<void>? _loading;

  GlobalDailyStore(this.backend);

  static final _stores = Expando<GlobalDailyStore>();

  static GlobalDailyStore of(KeyValueBackend b) => _stores[b] ??= GlobalDailyStore(b);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = await backend.read(storageKey);
      if (raw == null || raw.isEmpty) return;
      final j = jsonDecode(raw);
      if (j is! Map) return;
      for (final x in (j['r'] as List?) ?? const []) {
        final e = DailyEntry.fromJson(x);
        if (e != null) _results[e.key] = e;
      }
      for (final d in (j['days'] as List?) ?? const []) {
        if (d is String) _days.add(d);
      }
      _best = (j['best'] as num?)?.toInt() ?? 0;
    } catch (_) {
      // Bozuk kayıt: günlük geçmiş sıfırdan başlar, oyun etkilenmez.
    }
  }

  Future<void> _save() async {
    try {
      await backend.write(
          storageKey,
          jsonEncode({
            'r': [for (final e in _results.values) e.toJson()],
            'days': (_days.toList()..sort()),
            'best': _best,
          }));
    } catch (_) {}
  }

  DailyEntry? result(String gameId, String day) => _results['$gameId|$day'];

  /// Günün sonucu kaydedilir; yalnızca günün ilk çözümü sayılır.
  /// İlk çözümse true.
  Future<bool> record(DailyEntry e) async {
    await load();
    if (_results.containsKey(e.key)) return false;
    _results[e.key] = e;
    _days.add(e.day);
    final s = streak(e.day);
    if (s > _best) _best = s;
    _prune(e.day);
    await _save();
    return true;
  }

  void _prune(String today) {
    final limit = GlobalDaily.shift(today, -keepDays);
    _results.removeWhere((_, e) => e.day.compareTo(limit) < 0);
    final dayLimit = GlobalDaily.shift(today, -400);
    _days.removeWhere((d) => d.compareTo(dayLimit) < 0);
  }

  /// Bugün (ya da henüz bugün çözülmediyse dün) biten kesintisiz gün sayısı.
  int streak(String today) {
    var d = _days.contains(today) ? today : GlobalDaily.shift(today, -1);
    var n = 0;
    while (_days.contains(d)) {
      n++;
      d = GlobalDaily.shift(d, -1);
    }
    return n;
  }

  int get best => _best;

  /// Son [n] günün izi (en eski başta, bugün sonda).
  List<bool> lastDays(String today, [int n = 7]) =>
      [for (var i = n - 1; i >= 0; i--) _days.contains(GlobalDaily.shift(today, -i))];

  int solvedOn(String day) => _results.values.where((e) => e.day == day).length;

  List<DailyEntry> get pending => [for (final e in _results.values) if (!e.synced) e];

  Future<void> markSynced(DailyEntry e) async {
    e.synced = true;
    await _save();
  }

  /// Bekleyen sonuçları [send] ile gönderir (başarısız olan beklemede kalır).
  /// Gönderilen sayısı.
  Future<int> sync(Future<bool> Function(DailyEntry e) send) async {
    await load();
    var n = 0;
    for (final e in pending) {
      bool ok;
      try {
        ok = await send(e);
      } catch (_) {
        ok = false;
      }
      if (ok) {
        e.synced = true;
        n++;
      }
    }
    if (n > 0) await _save();
    return n;
  }
}
