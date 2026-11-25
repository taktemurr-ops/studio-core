/// Çevrimiçi katman: hesap, profil, arkadaşlar, skor tabloları, bulut kayıt,
/// eşleşme ve maç (hamle, sohbet, hediye). Arka uçtan bağımsızdır:
/// [MemoryBackend] testler ve yerel deneme için, Firebase uygulaması
/// `firebase_backend.dart` içinde.
library;

import 'dart:async';
import 'dart:math' as math;

// ---- Modeller -------------------------------------------------------------------

class Profile {
  final String uid;
  String name;
  int avatar;

  /// 16 yaş ve üzeri olduğunu beyan etti: serbest yazışma açılır.
  bool age16;

  /// Çevrimiçi oyun kurallarını kabul etti (sürüm numarası; 0 = hiç).
  int terms;

  /// Sürmekte olan maç (uygulama kapanırsa geri dönmek için); boş = yok.
  String active;

  /// Premium sahibi: masada yıldızlı ad, günlük ücretsiz güller.
  bool vip;

  /// Oyuncunun beklediği masa: "oyunKimliği|masaKimliği" (boş = yok).
  /// Arkadaşlar listesinde "masasına otur" için kullanılır.
  String table;

  /// Arkadaş kodu (6 harf).
  final String code;

  /// Oyun başına lig puanı (Elo).
  final Map<String, int> rating;

  /// Alınan hediyeler: tür → adet.
  final Map<String, int> gifts;
  final Set<String> blocked;

  Profile({
    required this.uid,
    required this.name,
    required this.code,
    this.avatar = 0,
    this.age16 = false,
    this.terms = 0,
    this.active = '',
    this.vip = false,
    this.table = '',
    Map<String, int>? rating,
    Map<String, int>? gifts,
    Set<String>? blocked,
  })  : rating = rating ?? {},
        gifts = gifts ?? {},
        blocked = blocked ?? {};

  int ratingFor(String gameId) => rating[gameId] ?? 1000;

  Map<String, Object?> toJson() => {
        'uid': uid,
        'name': name,
        'avatar': avatar,
        'age16': age16,
        'terms': terms,
        'active': active,
        'vip': vip,
        'table': table,
        'code': code,
        'rating': rating,
        'gifts': gifts,
        'blocked': blocked.toList(),
      };

  static Profile fromJson(Map<String, dynamic> j) => Profile(
        uid: j['uid'] as String,
        name: j['name'] as String? ?? 'Oyuncu',
        code: j['code'] as String? ?? '',
        avatar: (j['avatar'] as num?)?.toInt() ?? 0,
        age16: j['age16'] == true,
        terms: (j['terms'] as num?)?.toInt() ?? 0,
        active: j['active'] as String? ?? '',
        vip: j['vip'] == true,
        table: j['table'] as String? ?? '',
        rating: {for (final e in ((j['rating'] as Map?) ?? {}).entries) '${e.key}': (e.value as num).toInt()},
        gifts: {for (final e in ((j['gifts'] as Map?) ?? {}).entries) '${e.key}': (e.value as num).toInt()},
        blocked: {for (final x in (j['blocked'] as List?) ?? const []) '$x'},
      );
}

class ScoreEntry {
  final String uid, name;
  final int score, avatar;
  const ScoreEntry(this.uid, this.name, this.score, [this.avatar = 0]);
}

class Seat {
  final String uid; // boş: bot
  final String name;
  final int avatar;
  final bool vip;
  const Seat(this.uid, this.name, [this.avatar = 0, this.vip = false]);
  bool get bot => uid.isEmpty;

  /// Masada görünen ad (Premium sahipleri yıldızlı).
  String get label => vip ? '⭐ $name' : name;
  Map<String, Object?> toJson() => {'uid': uid, 'name': name, 'avatar': avatar, 'vip': vip};
  static Seat fromJson(Map<String, dynamic> j) =>
      Seat(j['uid'] as String? ?? '', j['name'] as String? ?? '', (j['avatar'] as num?)?.toInt() ?? 0, j['vip'] == true);
}

/// Lobide listelenen, oyuncu bekleyen herkese açık masa.
class TableInfo {
  final String id, gameId, hostName;
  final int hostAvatar, taken, size, rating;
  const TableInfo(this.id, this.gameId, this.hostName, this.hostAvatar, this.taken, this.size, this.rating);
}

enum MatchStatus { waiting, playing, done }

/// Masadaki sohbet ya da hediye olayı.
class TableEvent {
  final int seat;

  /// 'p' hazır mesaj, 't' yazı, 'g' hediye.
  final String kind;

  /// Hazır mesaj/hediye kimliği ya da yazı.
  final String value;

  /// Hediyenin gönderildiği koltuk.
  final int to;
  const TableEvent(this.seat, this.kind, this.value, [this.to = -1]);
}

/// Bir çevrimiçi maç. Oyun motoru bunu `MatchLink` olarak görür.
/// Arkadaştan gelen masa daveti (uygulama açıkken gösterilir).
class Invite {
  final String id, from, name, gameId, code;
  final int avatar, atMs;
  const Invite(this.id, this.from, this.name, this.avatar, this.gameId, this.code, this.atMs);

  Map<String, Object?> toJson() => {'from': from, 'name': name, 'avatar': avatar, 'gameId': gameId, 'code': code, 'at': atMs};

  static Invite fromJson(String id, Map<String, dynamic> j) => Invite(
        id,
        j['from'] as String? ?? '',
        j['name'] as String? ?? '',
        (j['avatar'] as num?)?.toInt() ?? 0,
        j['gameId'] as String? ?? '',
        j['code'] as String? ?? '',
        (j['at'] as num?)?.toInt() ?? 0,
      );

  /// Davetler 10 dakika geçerlidir.
  bool fresh(DateTime now) => now.millisecondsSinceEpoch - atMs < 10 * 60 * 1000;
}

abstract class OnlineMatch {
  String get id;
  String get gameId;
  String get code;

  /// Kodla kurulan (davetli) masa mı; hızlı eşleşme masaları herkese açık.
  bool get private;
  int get seed;
  int get mySeat;
  String get hostUid;
  bool get isHost;
  List<Seat> get seats;
  MatchStatus get status;
  Stream<void> get changes;

  /// Rakip hamleleri (kendi gönderdiklerimiz gelmez).
  Stream<(int, String)> get moves;
  Stream<TableEvent> get events;

  /// Maça geri dönüldüyse o ana kadarki bütün hamleler (kendi hamlelerimiz
  /// dahil, sırayla); oyun motoru bunları hızlıca yeniden oynar.
  List<(int, String)> get history;

  /// Hamle gönder ([asSeat]: ev sahibi bot/kopan oyuncu adına).
  Future<void> send(String move, {int? asSeat});
  Future<void> say(TableEvent e);
  Future<void> finish(int winner);
  Future<void> leave();

  /// Kalp atışı gelmeyen (bağlantısı kopan) koltuklar.
  Set<int> get dropped;

  /// Masa dolmadıysa boş koltuklara bot oturt ve başlat (ev sahibi).
  Future<void> fillWithBotsAndStart();
}

/// Gerçek zamanlı oyunlar için hızlı kanal (anlık durum ve girdi). Hamle
/// günlüğünden ayrıdır: mesajlar aynı anda birden çok koltuktan gelebilir,
/// sıra numarası çakışmaz. Dinlemeye başlayınca son [kRecentPulses] mesaj
/// (kendi gönderdiklerimiz dahil) bir kez verilir; sonra yalnızca diğer
/// koltukların mesajları gelir.
abstract class RealtimeMatch {
  Stream<(int, String)> get pulses;
  Future<void> pulse(String data, {int? asSeat});
}

/// Geri dönüşte yeniden verilen son mesaj sayısı.
const kRecentPulses = 16;

/// Arka uç sözleşmesi.
abstract class OnlineBackend {
  /// Oturum aç (gerekirse anonim hesap oluştur); profili döndür.
  Future<Profile> signIn();
  Profile? get me;
  Future<void> saveProfile(Profile p);
  Future<Profile?> profileOf(String uid);

  // Arkadaşlar
  Future<Profile?> addFriend(String code);
  Future<List<Profile>> friends();

  // Skor tabloları
  Future<void> submitScore(String board, int score);
  Future<List<ScoreEntry>> top(String board, {int limit = 50});

  // Bulut kayıt
  Future<void> saveBlob(String key, String json);
  Future<String?> loadBlob(String key);

  // Maçlar
  Future<OnlineMatch> createMatch(String gameId, int seats, {bool private = true});
  Future<OnlineMatch?> joinByCode(String code);
  Future<OnlineMatch> quickMatch(String gameId, int seats, int rating);

  /// Oyuncu bekleyen herkese açık masalar (en eskisi başta).
  Future<List<TableInfo>> openTables(String gameId, int seats);

  /// Listeden seçilen masaya otur (doluysa ya da başladıysa null).
  Future<OnlineMatch?> joinTable(String matchId);

  /// Uygulama kapanıp açıldıysa sürmekte olan maça geri dön (oturduğum
  /// koltuk duruyor ve maç bitmemişse). Geçmiş hamleler [OnlineMatch.history].
  Future<OnlineMatch?> rejoin(String matchId);

  // Arkadaşa doğrudan davet
  Future<void> sendInvite(String toUid, Invite invite);
  Stream<Invite> invites();
  Future<void> deleteInvite(String id);

  // Güvenlik
  Future<void> report(String uid, String reason, {String matchId = '', String text = ''});
  Future<void> block(String uid);

  /// Hediye ilet (alıcının profil sayacına işlenir).
  Future<void> recordGift(String toUid, String gift);

  /// Çevrimiçi hesabı ve sunucudaki bütün verisini siler.
  Future<void> deleteAccount();

  /// Telefon değişimi: profil ve yedeklerin anlık kopyasını tahmin edilemez
  /// bir koda bağlar. Kod yeni cihazda bir kez kullanılır.
  Future<String> createTransfer(Map<String, String> blobs);

  /// Kodu kullanır: eski profili (ad, avatar, lig, hediyeler) bu hesaba
  /// taşır ve yedekleri döndürür (oyun kimliği → kayıt). Kod yoksa null.
  Future<Map<String, String>?> claimTransfer(String code);
}

// ---- Yardımcılar -----------------------------------------------------------------

/// Elo: [score] 1 kazanma, 0.5 berabere, 0 kayıp.
int eloUpdate(int me, int opp, double score, {int k = 24}) {
  final expected = 1 / (1 + math.pow(10, (opp - me) / 400));
  return (me + k * (score - expected)).round();
}

/// Lig adı (Bronz → Elmas) için basamak: 0..4.
int leagueTier(int rating) => rating < 1100 ? 0 : rating < 1250 ? 1 : rating < 1400 ? 2 : rating < 1600 ? 3 : 4;

const leagueKeys = ['league_bronze', 'league_silver', 'league_gold', 'league_platinum', 'league_diamond'];

/// Arkadaş/davet kodu: karışmayan harfler.
String makeCode(math.Random r, [int n = 6]) {
  const a = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  return String.fromCharCodes([for (var i = 0; i < n; i++) a.codeUnitAt(r.nextInt(a.length))]);
}

/// Otomatik takma ad: sıfat + hayvan + sayı (kişisel bilgi içermez).
String makeName(math.Random r) {
  const adj = ['Hızlı', 'Usta', 'Sakin', 'Cesur', 'Neşeli', 'Akıllı', 'Şanslı', 'Yıldız', 'Mavi', 'Altın'];
  const noun = ['Kartal', 'Tilki', 'Kaplan', 'Yunus', 'Baykuş', 'Aslan', 'Panda', 'Şahin', 'Kurt', 'Ceylan'];
  return '${adj[r.nextInt(adj.length)]}${noun[r.nextInt(noun.length)]}${10 + r.nextInt(90)}';
}

/// Hazır mesajlar (kimlik → metin anahtarı). Serbest yazı olmadan da
/// anlaşılır, her dilde aynı anlama gelir.
const presetMessages = ['chat_hi', 'chat_gg', 'chat_wp', 'chat_thanks', 'chat_oops', 'chat_hurry', 'chat_wow', 'chat_bye'];

/// Hediyeler: kimlik, simge, elmas fiyatı (0: ücretsiz, günlük hak).
class Gift {
  final String id;
  final String icon;
  final int gems;
  const Gift(this.id, this.icon, this.gems);
}

const giftCatalog = [
  Gift('coffee', '☕', 0),
  Gift('tea', '🍵', 0),
  Gift('applause', '👏', 0),
  Gift('rose', '🌹', 5),
  Gift('cake', '🎂', 10),
  Gift('trophy', '🏆', 20),
  Gift('crown', '👑', 50),
];

const freeGiftsPerDay = 10;

/// Basit küfür süzgeci: yasaklı köklerle başlayan sözcükleri yıldızlar.
/// (Ağır içerik şikâyetle denetlenir; bu katman ilk eleme.)
String filterText(String text) {
  final words = text.split(RegExp(r'(\s+)'));
  final seps = RegExp(r'\s+').allMatches(text).map((m) => m.group(0)!).toList();
  final out = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    final w = words[i];
    final norm = w.toLowerCase().replaceAll(RegExp(r'[^a-zçğıöşü0-9]'), '').replaceAll('ı', 'i');
    final bad = _badWords.contains(norm) || _badRoots.any((b) => norm.startsWith(b));
    out.write(bad ? '*' * w.length : w);
    if (i < seps.length) out.write(seps[i]);
  }
  return out.toString();
}

/// Yaygın küfürler (Türkçe ve İngilizce): kısa olanlar tam sözcük olarak,
/// uzun olanlar kök olarak aranır ("götür" gibi masum sözcükler takılmasın).
const _badWords = {'amk', 'aq', 'oc', 'oç', 'piç', 'pic', 'göt', 'got', 'mk', 'sg'};
const _badRoots = [
  'orospu', 'siktir', 'sikik', 'sikim', 'yarrak', 'pezevenk', 'kahpe', 'ibne', 'gavat', 'amına', 'amina',
  'fuck', 'shit', 'bitch', 'cunt', 'whore', 'slut', 'nigg', 'faggot', 'bastard', 'asshole', 'motherf',
];

/// Serbest yazının uzunluk ve tekrar sınırı.
const maxChatLength = 120;

/// Sohbet yazısının gönderilmeden önceki son hali (boşsa gönderilmez).
String cleanChat(String text) {
  var t = text.trim();
  if (t.length > maxChatLength) t = t.substring(0, maxChatLength);
  // Bağlantı ve telefon numarası paylaşımını engelle (dolandırıcılık riski).
  t = t.replaceAll(RegExp(r'(https?://|www\.)\S+', caseSensitive: false), '***');
  t = t.replaceAll(RegExp(r'\+?\d[\d\s\-]{7,}\d'), '***');
  return filterText(t);
}

// ---- Bellek içi arka uç (testler ve geliştirme) ---------------------------------------

/// Birden çok istemcinin paylaştığı sahte sunucu.
class MemoryServer {
  final profiles = <String, Profile>{};
  final codes = <String, String>{};
  final friends = <String, Set<String>>{};
  final boards = <String, Map<String, ScoreEntry>>{};
  final blobs = <String, String>{};
  final matches = <String, _MemMatchData>{};
  final reports = <Map<String, String>>[];
  final transfers = <String, (Map<String, Object?>, Map<String, String>)>{};
  final invites = <String, List<Invite>>{};
  final inviteCtl = StreamController<String>.broadcast();
  final r = math.Random(7);
}

class _MemMatchData {
  final String id, gameId, code, hostUid;
  final int seed, size;
  final bool private;
  final List<Seat> seats = [];
  MatchStatus status = MatchStatus.waiting;
  int winner = -2;
  final moves = <(int, String, String)>[]; // seat, move, sender uid
  final pulses = <(int, String, String)>[]; // seat, data, sender uid
  final events = <(TableEvent, String)>[];
  final ctl = StreamController<void>.broadcast();
  final int rating;
  _MemMatchData(this.id, this.gameId, this.code, this.hostUid, this.seed, this.size, this.private, this.rating);
}

class MemoryBackend implements OnlineBackend {
  final MemoryServer server;
  final String uid;
  Profile? _me;
  MemoryBackend(this.server, this.uid);

  @override
  Profile? get me => _me;

  @override
  Future<Profile> signIn() async {
    final p = server.profiles[uid] ??
        Profile(uid: uid, name: makeName(server.r), code: makeCode(server.r));
    server.profiles[uid] = p;
    server.codes[p.code] = uid;
    return _me = p;
  }

  @override
  Future<void> saveProfile(Profile p) async => server.profiles[p.uid] = p;

  @override
  Future<Profile?> profileOf(String uid) async => server.profiles[uid];

  @override
  Future<Profile?> addFriend(String code) async {
    final f = server.codes[code.toUpperCase()];
    if (f == null || f == uid) return null;
    server.friends.putIfAbsent(uid, () => {}).add(f);
    server.friends.putIfAbsent(f, () => {}).add(uid);
    return server.profiles[f];
  }

  @override
  Future<List<Profile>> friends() async => [for (final f in server.friends[uid] ?? <String>{}) server.profiles[f]!];

  @override
  Future<void> submitScore(String board, int score) async {
    final b = server.boards.putIfAbsent(board, () => {});
    final old = b[uid];
    if (old == null || score > old.score) b[uid] = ScoreEntry(uid, _me!.name, score, _me!.avatar);
  }

  @override
  Future<List<ScoreEntry>> top(String board, {int limit = 50}) async {
    final l = [...(server.boards[board] ?? {}).values]..sort((a, b) => b.score.compareTo(a.score));
    return l.take(limit).toList();
  }

  @override
  Future<void> saveBlob(String key, String json) async => server.blobs['$uid/$key'] = json;

  @override
  Future<String?> loadBlob(String key) async => server.blobs['$uid/$key'];

  Seat get _mySeat => Seat(uid, _me!.name, _me!.avatar, _me!.vip);

  @override
  Future<OnlineMatch> createMatch(String gameId, int seats, {bool private = true}) async {
    final id = 'm${server.matches.length + 1}';
    final d = _MemMatchData(id, gameId, makeCode(server.r), uid, server.r.nextInt(1 << 30), seats, private,
        _me!.ratingFor(gameId));
    d.seats.add(_mySeat);
    server.matches[id] = d;
    return _MemMatch(this, d);
  }

  @override
  Future<OnlineMatch?> joinByCode(String code) async {
    for (final d in server.matches.values) {
      if (d.code == code.toUpperCase() && d.status == MatchStatus.waiting && d.seats.length < d.size) {
        d.seats.add(_mySeat);
        if (d.seats.length == d.size) d.status = MatchStatus.playing;
        d.ctl.add(null);
        return _MemMatch(this, d);
      }
    }
    return null;
  }

  @override
  Future<OnlineMatch> quickMatch(String gameId, int seats, int rating) async {
    for (final d in server.matches.values) {
      if (!d.private &&
          d.gameId == gameId &&
          d.size == seats &&
          d.status == MatchStatus.waiting &&
          d.seats.length < seats &&
          (d.rating - rating).abs() <= 400 &&
          !(_me!.blocked.contains(d.hostUid))) {
        d.seats.add(_mySeat);
        if (d.seats.length == d.size) d.status = MatchStatus.playing;
        d.ctl.add(null);
        return _MemMatch(this, d);
      }
    }
    return createMatch(gameId, seats, private: false);
  }

  @override
  Future<List<TableInfo>> openTables(String gameId, int seats) async => [
        for (final d in server.matches.values)
          if (!d.private &&
              d.gameId == gameId &&
              d.size == seats &&
              d.status == MatchStatus.waiting &&
              d.seats.length < d.size &&
              !_me!.blocked.contains(d.hostUid))
            TableInfo(d.id, d.gameId, d.seats.first.label, d.seats.first.avatar, d.seats.length, d.size, d.rating),
      ];

  @override
  Future<OnlineMatch?> joinTable(String matchId) async {
    final d = server.matches[matchId];
    if (d == null || d.status != MatchStatus.waiting || d.seats.length >= d.size || d.seats.any((x) => x.uid == uid)) {
      return null;
    }
    d.seats.add(_mySeat);
    if (d.seats.length == d.size) d.status = MatchStatus.playing;
    d.ctl.add(null);
    return _MemMatch(this, d);
  }

  @override
  Future<OnlineMatch?> rejoin(String matchId) async {
    final d = server.matches[matchId];
    if (d == null || d.status != MatchStatus.playing || !d.seats.any((s) => s.uid == uid)) return null;
    return _MemMatch(this, d, replay: true);
  }

  @override
  Future<void> sendInvite(String toUid, Invite invite) async {
    if (!(server.friends[uid]?.contains(toUid) ?? false)) return;
    final l = server.invites.putIfAbsent(toUid, () => []);
    l.add(Invite('i${l.length + 1}', uid, invite.name, invite.avatar, invite.gameId, invite.code, invite.atMs));
    server.inviteCtl.add(toUid);
  }

  @override
  Stream<Invite> invites() {
    var seen = 0;
    final l = server.invites.putIfAbsent(uid, () => []);
    late final StreamController<Invite> ctl;
    StreamSubscription<String>? sub;
    void pump() {
      while (seen < l.length) {
        ctl.add(l[seen++]);
      }
    }

    ctl = StreamController<Invite>(
      onListen: () {
        pump();
        sub = server.inviteCtl.stream.listen((to) {
          if (to == uid) pump();
        });
      },
      onCancel: () => sub?.cancel(),
    );
    return ctl.stream;
  }

  @override
  Future<void> deleteInvite(String id) async => server.invites[uid]?.removeWhere((i) => i.id == id);

  @override
  Future<void> report(String target, String reason, {String matchId = '', String text = ''}) async =>
      server.reports.add({'by': uid, 'target': target, 'reason': reason, 'match': matchId, 'text': text});

  @override
  Future<void> block(String target) async => _me!.blocked.add(target);

  @override
  Future<String> createTransfer(Map<String, String> blobs) async {
    final code = makeCode(server.r, 12);
    server.transfers[code] = (_me!.toJson(), Map.of(blobs));
    return code;
  }

  @override
  Future<Map<String, String>?> claimTransfer(String code) async {
    final t = server.transfers.remove(code.toUpperCase());
    if (t == null) return null;
    final old = Profile.fromJson(Map<String, dynamic>.from(t.$1));
    _me!
      ..name = old.name
      ..avatar = old.avatar
      ..age16 = old.age16
      ..terms = old.terms;
    _me!.rating.addAll(old.rating);
    _me!.gifts.addAll(old.gifts);
    for (final e in t.$2.entries) {
      server.blobs['$uid/${e.key}'] = e.value;
    }
    return t.$2;
  }

  @override
  Future<void> deleteAccount() async {
    final p = server.profiles.remove(uid);
    if (p != null) server.codes.remove(p.code);
    server.friends.remove(uid);
    for (final f in server.friends.values) {
      f.remove(uid);
    }
    server.blobs.removeWhere((k, _) => k.startsWith('$uid/'));
    for (final b in server.boards.values) {
      b.remove(uid);
    }
    _me = null;
  }

  @override
  Future<void> recordGift(String toUid, String gift) async {
    final p = server.profiles[toUid];
    if (p == null) return;
    p.gifts[gift] = (p.gifts[gift] ?? 0) + 1;
  }
}

class _MemMatch implements OnlineMatch, RealtimeMatch {
  final MemoryBackend b;
  final _MemMatchData d;
  int _movesSeen = 0, _eventsSeen = 0, _pulsesSeen = 0;
  late final StreamController<(int, String)> _pulses = StreamController.broadcast(onListen: _pulseListen);

  void _pulseListen() {
    for (var i = math.max(0, d.pulses.length - kRecentPulses); i < d.pulses.length; i++) {
      _pulses.add((d.pulses[i].$1, d.pulses[i].$2));
    }
    _pulsesSeen = d.pulses.length;
  }

  @override
  Stream<(int, String)> get pulses => _pulses.stream;

  @override
  Future<void> pulse(String data, {int? asSeat}) async {
    d.pulses.add((asSeat ?? mySeat, data, b.uid));
    d.ctl.add(null);
  }

  late final StreamController<(int, String)> _moves = StreamController.broadcast(onListen: _pump);
  late final StreamController<TableEvent> _events = StreamController.broadcast(onListen: _pump);
  late final StreamSubscription<void> _sub;
  @override
  final List<(int, String)> history = [];

  _MemMatch(this.b, this.d, {bool replay = false}) {
    if (replay) {
      history.addAll([for (final m in d.moves) (m.$1, m.$2)]);
      _movesSeen = d.moves.length;
      _eventsSeen = d.events.length;
    }
    _sub = d.ctl.stream.listen((_) => _pump());
  }

  void _pump() {
    while (_movesSeen < d.moves.length) {
      final m = d.moves[_movesSeen++];
      if (m.$3 != b.uid) _moves.add((m.$1, m.$2));
    }
    while (_eventsSeen < d.events.length) {
      _events.add(d.events[_eventsSeen++].$1);
    }
    while (_pulsesSeen < d.pulses.length) {
      final p = d.pulses[_pulsesSeen++];
      if (p.$3 != b.uid && _pulses.hasListener) _pulses.add((p.$1, p.$2));
    }
  }

  @override
  String get id => d.id;
  @override
  String get gameId => d.gameId;
  @override
  String get code => d.code;
  @override
  bool get private => d.private;
  @override
  int get seed => d.seed;
  @override
  int get mySeat => d.seats.indexWhere((s) => s.uid == b.uid);
  @override
  String get hostUid => d.hostUid;
  @override
  bool get isHost => d.hostUid == b.uid;
  @override
  List<Seat> get seats => List.unmodifiable(d.seats);
  @override
  MatchStatus get status => d.status;
  @override
  Stream<void> get changes => d.ctl.stream;
  @override
  Stream<(int, String)> get moves => _moves.stream;
  @override
  Stream<TableEvent> get events => _events.stream;
  @override
  Set<int> get dropped => const {};

  @override
  Future<void> send(String move, {int? asSeat}) async {
    d.moves.add((asSeat ?? mySeat, move, b.uid));
    d.ctl.add(null);
  }

  @override
  Future<void> say(TableEvent e) async {
    d.events.add((e, b.uid));
    d.ctl.add(null);
  }

  @override
  Future<void> finish(int winner) async {
    d.status = MatchStatus.done;
    d.winner = winner;
    d.ctl.add(null);
  }

  @override
  Future<void> leave() async {
    await _sub.cancel();
  }

  @override
  Future<void> fillWithBotsAndStart() async {
    while (d.seats.length < d.size) {
      d.seats.add(const Seat('', ''));
    }
    d.status = MatchStatus.playing;
    d.ctl.add(null);
  }
}
