import 'dart:convert';

/// Everything persisted for one player (doc 6.3). Mutable on purpose; the
/// [GameSession] is the single writer.
class SaveData {
  static const int currentVersion = 3;

  int saveVersion = currentVersion;
  int firstLaunchMs = 0;
  int lastActiveMs = 0;

  // ---- Progress -----------------------------------------------------------
  int currentLevel = 1;
  int highestLevel = 0;
  int completedLevels = 0;

  /// Stars per campaign level, one char per level ('0'..'3'), index 0 = L1.
  String starsCompact = '';
  int totalXp = 0;

  // ---- Economy ------------------------------------------------------------
  int coins = 100;
  int gems = 0;
  int hints = 3;
  int boosters = 1;
  int lives = 5;

  // ---- Meta systems --------------------------------------------------------
  Set<String> achievements = {};
  Set<String> collection = {'theme_0', 'skin_0'};
  String activeTheme = 'theme_0';
  String activeSkin = 'skin_0';
  Map<String, int> stats = {};

  /// Best score per mode / record key.
  Map<String, int> records = {};

  // ---- Daily / weekly ------------------------------------------------------
  int loginStreak = 0;
  int bestLoginStreak = 0;
  String lastLoginDay = '';
  String lastLoginRewardDay = '';
  String dailyKey = '';
  Map<String, int> dailyProgress = {};
  Set<String> dailyClaimed = {};
  String weeklyKey = '';
  Map<String, int> weeklyProgress = {};
  Set<String> weeklyClaimed = {};
  String lastWheelDay = '';
  String lastSurpriseDay = '';
  String dailyLevelDoneDay = '';
  String weeklyLevelDoneWeek = '';
  int dailyRecord = 0;
  String dailyRecordDay = '';
  int weeklyGoalTarget = 0;
  String comebackClaimedDay = '';
  Set<String> challengesDone = {};

  // ---- Adaptive difficulty -------------------------------------------------
  List<bool> recentResults = [];

  // ---- Settings --------------------------------------------------------------
  String language = '';
  bool sound = true;
  bool music = true;
  bool haptics = true;
  bool reducedMotion = false;
  bool colorBlindMode = false;
  bool leftHanded = false;
  double textScale = 1.0;

  // ---- Privacy / monetization ----------------------------------------------
  /// '', 'granted', 'denied', 'not_required'
  String adConsent = '';
  bool analyticsConsent = false;
  bool ageGateDone = false;
  bool underAge = false;
  bool removeAds = false;
  bool premium = false;
  Set<String> ownedProducts = {};
  Set<String> processedPurchaseIds = {};
  int levelsSinceInterstitial = 0;
  int lastInterstitialMs = 0;
  int rewardedToday = 0;
  String rewardedDay = '';

  // ---- Clock guard ---------------------------------------------------------
  int maxSeenWallMs = 0;
  int clockTamperCount = 0;

  /// Free-form state the active game can use to resume an interrupted round.
  Map<String, Object?> resume = {};

  SaveData();

  // ---- Stars helpers ---------------------------------------------------------
  int starsFor(int level) {
    if (level < 1 || level > starsCompact.length) return 0;
    return int.parse(starsCompact[level - 1]);
  }

  void setStars(int level, int stars) {
    if (level < 1) return;
    final buf = StringBuffer(starsCompact);
    while (buf.length < level) {
      buf.write('0');
    }
    final s = buf.toString();
    final current = int.parse(s[level - 1]);
    if (stars <= current) {
      starsCompact = s;
      return;
    }
    starsCompact = '${s.substring(0, level - 1)}$stars${s.substring(level)}';
  }

  int get totalStars {
    var t = 0;
    for (final c in starsCompact.codeUnits) {
      t += c - 48;
    }
    return t;
  }

  int stat(String key) => stats[key] ?? 0;
  void addStat(String key, [int by = 1]) => stats[key] = stat(key) + by;
  void maxStat(String key, int value) {
    if (value > stat(key)) stats[key] = value;
  }

  // ---- JSON -------------------------------------------------------------------
  Map<String, Object?> toJson() => {
        'saveVersion': saveVersion,
        'firstLaunchMs': firstLaunchMs,
        'lastActiveMs': lastActiveMs,
        'currentLevel': currentLevel,
        'highestLevel': highestLevel,
        'completedLevels': completedLevels,
        'stars': starsCompact,
        'totalXp': totalXp,
        'coins': coins,
        'gems': gems,
        'hints': hints,
        'boosters': boosters,
        'lives': lives,
        'achievements': achievements.toList()..sort(),
        'collection': collection.toList()..sort(),
        'activeTheme': activeTheme,
        'activeSkin': activeSkin,
        'stats': stats,
        'records': records,
        'loginStreak': loginStreak,
        'bestLoginStreak': bestLoginStreak,
        'lastLoginDay': lastLoginDay,
        'lastLoginRewardDay': lastLoginRewardDay,
        'dailyKey': dailyKey,
        'dailyProgress': dailyProgress,
        'dailyClaimed': dailyClaimed.toList(),
        'weeklyKey': weeklyKey,
        'weeklyProgress': weeklyProgress,
        'weeklyClaimed': weeklyClaimed.toList(),
        'lastWheelDay': lastWheelDay,
        'lastSurpriseDay': lastSurpriseDay,
        'dailyLevelDoneDay': dailyLevelDoneDay,
        'weeklyLevelDoneWeek': weeklyLevelDoneWeek,
        'dailyRecord': dailyRecord,
        'dailyRecordDay': dailyRecordDay,
        'weeklyGoalTarget': weeklyGoalTarget,
        'comebackClaimedDay': comebackClaimedDay,
        'challengesDone': challengesDone.toList(),
        'recentResults': recentResults,
        'language': language,
        'sound': sound,
        'music': music,
        'haptics': haptics,
        'reducedMotion': reducedMotion,
        'colorBlindMode': colorBlindMode,
        'leftHanded': leftHanded,
        'textScale': textScale,
        'adConsent': adConsent,
        'analyticsConsent': analyticsConsent,
        'ageGateDone': ageGateDone,
        'underAge': underAge,
        'removeAds': removeAds,
        'premium': premium,
        'ownedProducts': ownedProducts.toList(),
        'processedPurchaseIds': processedPurchaseIds.toList(),
        'levelsSinceInterstitial': levelsSinceInterstitial,
        'lastInterstitialMs': lastInterstitialMs,
        'rewardedToday': rewardedToday,
        'rewardedDay': rewardedDay,
        'maxSeenWallMs': maxSeenWallMs,
        'clockTamperCount': clockTamperCount,
        'resume': resume,
      };

  String encode() => jsonEncode(toJson());

  static int _i(Object? v, int d) => v is num ? v.toInt() : d;
  static String _s(Object? v, String d) => v is String ? v : d;
  static bool _b(Object? v, bool d) => v is bool ? v : d;
  static Set<String> _set(Object? v) =>
      v is List ? v.whereType<String>().toSet() : <String>{};
  static Map<String, int> _mapInt(Object? v) => v is Map
      ? {
          for (final e in v.entries)
            if (e.value is num) '${e.key}': (e.value as num).toInt()
        }
      : <String, int>{};

  /// Parses JSON written by ANY previous save version (migration, doc 12.2).
  factory SaveData.fromJson(Map<String, Object?> raw) {
    final j = SaveMigrations.migrate(Map<String, Object?>.from(raw));
    final d = SaveData();
    d.saveVersion = currentVersion;
    d.firstLaunchMs = _i(j['firstLaunchMs'], 0);
    d.lastActiveMs = _i(j['lastActiveMs'], 0);
    d.currentLevel = _i(j['currentLevel'], 1).clamp(1, 1 << 30);
    d.highestLevel = _i(j['highestLevel'], 0);
    d.completedLevels = _i(j['completedLevels'], 0);
    final stars = _s(j['stars'], '');
    d.starsCompact = RegExp(r'^[0-3]*$').hasMatch(stars) ? stars : '';
    d.totalXp = _i(j['totalXp'], 0);
    d.coins = _i(j['coins'], 100);
    d.gems = _i(j['gems'], 0);
    d.hints = _i(j['hints'], 3);
    d.boosters = _i(j['boosters'], 1);
    d.lives = _i(j['lives'], 5);
    d.achievements = _set(j['achievements']);
    d.collection = _set(j['collection'])..addAll(['theme_0', 'skin_0']);
    d.activeTheme = _s(j['activeTheme'], 'theme_0');
    d.activeSkin = _s(j['activeSkin'], 'skin_0');
    d.stats = _mapInt(j['stats']);
    d.records = _mapInt(j['records']);
    d.loginStreak = _i(j['loginStreak'], 0);
    d.bestLoginStreak = _i(j['bestLoginStreak'], 0);
    d.lastLoginDay = _s(j['lastLoginDay'], '');
    d.lastLoginRewardDay = _s(j['lastLoginRewardDay'], '');
    d.dailyKey = _s(j['dailyKey'], '');
    d.dailyProgress = _mapInt(j['dailyProgress']);
    d.dailyClaimed = _set(j['dailyClaimed']);
    d.weeklyKey = _s(j['weeklyKey'], '');
    d.weeklyProgress = _mapInt(j['weeklyProgress']);
    d.weeklyClaimed = _set(j['weeklyClaimed']);
    d.lastWheelDay = _s(j['lastWheelDay'], '');
    d.lastSurpriseDay = _s(j['lastSurpriseDay'], '');
    d.dailyLevelDoneDay = _s(j['dailyLevelDoneDay'], '');
    d.weeklyLevelDoneWeek = _s(j['weeklyLevelDoneWeek'], '');
    d.dailyRecord = _i(j['dailyRecord'], 0);
    d.dailyRecordDay = _s(j['dailyRecordDay'], '');
    d.weeklyGoalTarget = _i(j['weeklyGoalTarget'], 0);
    d.comebackClaimedDay = _s(j['comebackClaimedDay'], '');
    d.challengesDone = _set(j['challengesDone']);
    final rr = j['recentResults'];
    d.recentResults = rr is List ? rr.whereType<bool>().toList() : <bool>[];
    d.language = _s(j['language'], '');
    d.sound = _b(j['sound'], true);
    d.music = _b(j['music'], true);
    d.haptics = _b(j['haptics'], true);
    d.reducedMotion = _b(j['reducedMotion'], false);
    d.colorBlindMode = _b(j['colorBlindMode'], false);
    d.leftHanded = _b(j['leftHanded'], false);
    final ts = j['textScale'];
    d.textScale = ts is num ? ts.toDouble().clamp(0.8, 1.6) : 1.0;
    d.adConsent = _s(j['adConsent'], '');
    d.analyticsConsent = _b(j['analyticsConsent'], false);
    d.ageGateDone = _b(j['ageGateDone'], false);
    d.underAge = _b(j['underAge'], false);
    d.removeAds = _b(j['removeAds'], false);
    d.premium = _b(j['premium'], false);
    d.ownedProducts = _set(j['ownedProducts']);
    d.processedPurchaseIds = _set(j['processedPurchaseIds']);
    d.levelsSinceInterstitial = _i(j['levelsSinceInterstitial'], 0);
    d.lastInterstitialMs = _i(j['lastInterstitialMs'], 0);
    d.rewardedToday = _i(j['rewardedToday'], 0);
    d.rewardedDay = _s(j['rewardedDay'], '');
    d.maxSeenWallMs = _i(j['maxSeenWallMs'], 0);
    d.clockTamperCount = _i(j['clockTamperCount'], 0);
    final res = j['resume'];
    d.resume = res is Map ? Map<String, Object?>.from(res) : <String, Object?>{};
    return d;
  }

  static SaveData decode(String text) =>
      SaveData.fromJson(Map<String, Object?>.from(jsonDecode(text) as Map));

  SaveData clone() => SaveData.decode(encode());
}

/// Step-by-step migrations so saves from older app versions keep working.
class SaveMigrations {
  static Map<String, Object?> migrate(Map<String, Object?> j) {
    var v = (j['saveVersion'] is num) ? (j['saveVersion'] as num).toInt() : 1;
    if (v < 2) {
      // v1 stored stars as a map {"1":3,"2":1}; convert to compact string.
      final old = j['starsByLevel'];
      if (old is Map) {
        var maxL = 0;
        final m = <int, int>{};
        old.forEach((k, val) {
          final l = int.tryParse('$k');
          if (l != null && val is num) {
            m[l] = val.toInt().clamp(0, 3);
            if (l > maxL) maxL = l;
          }
        });
        final b = StringBuffer();
        for (var l = 1; l <= maxL; l++) {
          b.write(m[l] ?? 0);
        }
        j['stars'] = b.toString();
      }
      j.remove('starsByLevel');
      // v1 used "level" for the current level.
      if (j['currentLevel'] == null && j['level'] is num) {
        j['currentLevel'] = j['level'];
      }
      v = 2;
    }
    if (v < 3) {
      // v2 had a single "noAds" flag.
      if (j['noAds'] == true) j['removeAds'] = true;
      j.remove('noAds');
      v = 3;
    }
    j['saveVersion'] = v;
    return j;
  }
}
