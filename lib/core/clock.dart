import 'save_data.dart';

/// Date keys used by daily / weekly systems (local calendar).
class DateKeys {
  static String day(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';

  /// ISO-8601 week key, e.g. 2026-W47.
  static String week(DateTime t) {
    final d = DateTime(t.year, t.month, t.day);
    final thursday = d.add(Duration(days: 4 - d.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final week1Monday =
        firstThursday.subtract(Duration(days: firstThursday.weekday - 1));
    final weekNo = thursday.difference(week1Monday).inDays ~/ 7 + 1;
    return '${thursday.year}-W${weekNo.toString().padLeft(2, '0')}';
  }

  static int daysBetween(String fromDay, String toDay) {
    final a = DateTime.tryParse(fromDay);
    final b = DateTime.tryParse(toDay);
    if (a == null || b == null) return 0;
    return DateTime.utc(b.year, b.month, b.day)
        .difference(DateTime.utc(a.year, a.month, a.day))
        .inDays;
  }
}

/// Protection against device clock manipulation (doc 12.6).
///
/// The guard remembers the latest wall-clock time ever seen. If the clock
/// jumps backwards by more than [tolerance], time-based rewards use the
/// remembered time instead (so turning the clock back cannot re-unlock
/// daily rewards) and the incident is counted. Jumping forward is allowed
/// but capped: a forward jump only grants the rewards of ONE missed day.
class ClockGuard {
  final DateTime Function() now;
  final Duration tolerance;

  ClockGuard({DateTime Function()? now, this.tolerance = const Duration(hours: 2)})
      : now = now ?? DateTime.now;

  bool _flagged = false;

  /// Returns the trusted "now" and updates the save.
  DateTime trustedNow(SaveData save) {
    final t = now();
    final ms = t.millisecondsSinceEpoch;
    if (save.maxSeenWallMs == 0 || ms >= save.maxSeenWallMs) {
      save.maxSeenWallMs = ms;
      return t;
    }
    final back = save.maxSeenWallMs - ms;
    if (back > tolerance.inMilliseconds) {
      if (!_flagged) save.clockTamperCount++;
      _flagged = true;
      return DateTime.fromMillisecondsSinceEpoch(save.maxSeenWallMs);
    }
    return t;
  }

  bool suspicious(SaveData save) => save.clockTamperCount >= 3;
}
