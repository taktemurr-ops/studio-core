/// Firebase (Authentication + Cloud Firestore) arka ucu.
///
/// Veri düzeni (kurallar: firebase/firestore.rules):
///   users/{uid}                 profil (ad, avatar, 16+, kod, puanlar, hediyeler, engellenenler)
///   users/{uid}/friends/{fuid}  arkadaşlar
///   codes/{code}                arkadaş kodu → uid
///   saves/{uid}/blobs/{key}     bulut kayıt
///   boards/{board}/scores/{uid} skor tabloları
///   matches/{id}                maç (oyun, koltuklar, tohum, durum, kalp atışları)
///   matches/{id}/moves/{n}      hamleler (n: sıra numarası)
///   matches/{id}/events/{auto}  sohbet ve hediyeler
///   reports/{auto}              şikâyetler (yalnızca yazılır; panelden okunur)
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'online.dart';

class FirebaseBackend implements OnlineBackend {
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  final math.Random _r = math.Random();
  Profile? _me;

  FirebaseBackend({FirebaseFirestore? db, FirebaseAuth? auth})
      : db = db ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  String get uid => auth.currentUser!.uid;

  @override
  Profile? get me => _me;

  @override
  Future<Profile> signIn() async {
    if (auth.currentUser == null) await auth.signInAnonymously();
    final ref = db.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return _me = Profile.fromJson({...snap.data()!, 'uid': uid});
    // Yeni hesap: otomatik ad ve benzersiz arkadaş kodu.
    String code;
    do {
      code = makeCode(_r);
    } while ((await db.collection('codes').doc(code).get()).exists);
    final p = Profile(uid: uid, name: makeName(_r), code: code);
    await db.collection('codes').doc(code).set({'uid': uid});
    await ref.set({...p.toJson(), 'created': FieldValue.serverTimestamp()});
    return _me = p;
  }

  @override
  Future<void> saveProfile(Profile p) async {
    _me = p;
    await db.collection('users').doc(p.uid).set(p.toJson(), SetOptions(merge: true));
  }

  @override
  Future<Profile?> profileOf(String id) async {
    final s = await db.collection('users').doc(id).get();
    return s.exists ? Profile.fromJson({...s.data()!, 'uid': id}) : null;
  }

  @override
  Future<Profile?> addFriend(String code) async {
    final c = await db.collection('codes').doc(code.toUpperCase()).get();
    final f = c.data()?['uid'] as String?;
    if (f == null || f == uid) return null;
    await db.collection('users').doc(uid).collection('friends').doc(f).set({'at': FieldValue.serverTimestamp()});
    await db.collection('users').doc(f).collection('friends').doc(uid).set({'at': FieldValue.serverTimestamp()});
    return profileOf(f);
  }

  @override
  Future<List<Profile>> friends() async {
    final q = await db.collection('users').doc(uid).collection('friends').limit(200).get();
    final out = <Profile>[];
    for (final d in q.docs) {
      final p = await profileOf(d.id);
      if (p != null) out.add(p);
    }
    return out;
  }

  @override
  Future<void> submitScore(String board, int score) async {
    final ref = db.collection('boards').doc(board).collection('scores').doc(uid);
    await db.runTransaction((t) async {
      final old = await t.get(ref);
      final prev = (old.data()?['score'] as num?)?.toInt() ?? -1;
      if (score > prev) {
        t.set(ref, {'score': score, 'name': _me?.name ?? '', 'avatar': _me?.avatar ?? 0, 'ts': FieldValue.serverTimestamp()});
      }
    });
  }

  @override
  Future<List<ScoreEntry>> top(String board, {int limit = 50}) async {
    final q = await db.collection('boards').doc(board).collection('scores').orderBy('score', descending: true).limit(limit).get();
    return [
      for (final d in q.docs)
        ScoreEntry(d.id, d.data()['name'] as String? ?? '', (d.data()['score'] as num).toInt(), (d.data()['avatar'] as num?)?.toInt() ?? 0)
    ];
  }

  @override
  Future<void> saveBlob(String key, String json) =>
      db.collection('saves').doc(uid).collection('blobs').doc(key).set({'v': json, 'ts': FieldValue.serverTimestamp()});

  @override
  Future<String?> loadBlob(String key) async =>
      (await db.collection('saves').doc(uid).collection('blobs').doc(key).get()).data()?['v'] as String?;

  Map<String, Object?> get _mySeat => {'uid': uid, 'name': _me?.name ?? '', 'avatar': _me?.avatar ?? 0};

  @override
  Future<OnlineMatch> createMatch(String gameId, int seats, {bool private = true}) async {
    final ref = db.collection('matches').doc();
    final code = makeCode(_r);
    await ref.set({
      'gameId': gameId,
      'size': seats,
      'seed': _r.nextInt(1 << 30),
      'code': code,
      'private': private,
      'host': uid,
      'status': 'waiting',
      'seats': [_mySeat],
      'uids': [uid],
      'rating': _me?.ratingFor(gameId) ?? 1000,
      'created': FieldValue.serverTimestamp(),
      'beats': {uid: FieldValue.serverTimestamp()},
    });
    return _FsMatch.open(this, ref);
  }

  Future<OnlineMatch?> _join(DocumentReference<Map<String, dynamic>> ref) async {
    final ok = await db.runTransaction<bool>((t) async {
      final s = await t.get(ref);
      final d = s.data();
      if (d == null || d['status'] != 'waiting') return false;
      final seats = List<Map<String, dynamic>>.from((d['seats'] as List).map((e) => Map<String, dynamic>.from(e as Map)));
      if (seats.length >= (d['size'] as num).toInt() || seats.any((x) => x['uid'] == uid)) return false;
      seats.add(Map<String, dynamic>.from(_mySeat));
      t.update(ref, {
        'seats': seats,
        'uids': FieldValue.arrayUnion([uid]),
        'beats.$uid': FieldValue.serverTimestamp(),
        if (seats.length == (d['size'] as num).toInt()) 'status': 'playing',
      });
      return true;
    });
    return ok ? _FsMatch.open(this, ref) : null;
  }

  @override
  Future<OnlineMatch?> joinByCode(String code) async {
    final q = await db.collection('matches').where('code', isEqualTo: code.toUpperCase()).where('status', isEqualTo: 'waiting').limit(1).get();
    if (q.docs.isEmpty) return null;
    return _join(q.docs.first.reference);
  }

  @override
  Future<OnlineMatch> quickMatch(String gameId, int seats, int rating) async {
    final q = await db
        .collection('matches')
        .where('gameId', isEqualTo: gameId)
        .where('size', isEqualTo: seats)
        .where('private', isEqualTo: false)
        .where('status', isEqualTo: 'waiting')
        .orderBy('created')
        .limit(10)
        .get();
    final blocked = _me?.blocked ?? const <String>{};
    for (final d in q.docs) {
      final r = (d.data()['rating'] as num?)?.toInt() ?? 1000;
      if ((r - rating).abs() > 400 || blocked.contains(d.data()['host'])) continue;
      final m = await _join(d.reference);
      if (m != null) return m;
    }
    return createMatch(gameId, seats, private: false);
  }

  @override
  Future<void> report(String target, String reason, {String matchId = '', String text = ''}) =>
      db.collection('reports').add({'by': uid, 'target': target, 'reason': reason, 'match': matchId, 'text': text, 'ts': FieldValue.serverTimestamp()});

  @override
  Future<void> block(String target) async {
    _me?.blocked.add(target);
    await db.collection('users').doc(uid).update({'blocked': FieldValue.arrayUnion([target])});
  }

  @override
  Future<void> deleteAccount() async {
    final me = _me;
    final friends = await db.collection('users').doc(uid).collection('friends').get();
    for (final f in friends.docs) {
      await db.collection('users').doc(f.id).collection('friends').doc(uid).delete().catchError((_) {});
      await f.reference.delete();
    }
    final blobs = await db.collection('saves').doc(uid).collection('blobs').get();
    for (final b in blobs.docs) {
      await b.reference.delete();
    }
    if (me != null) await db.collection('codes').doc(me.code).delete().catchError((_) {});
    await db.collection('users').doc(uid).delete();
    await auth.currentUser?.delete();
    _me = null;
  }

  @override
  Future<void> recordGift(String toUid, String gift) =>
      db.collection('users').doc(toUid).update({'gifts.$gift': FieldValue.increment(1)});
}

class _FsMatch implements OnlineMatch {
  final FirebaseBackend b;
  final DocumentReference<Map<String, dynamic>> ref;
  Map<String, dynamic> _d = {};
  final _changes = StreamController<void>.broadcast();
  final _moves = StreamController<(int, String)>.broadcast();
  final _events = StreamController<TableEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subs = [];
  Timer? _beat;

  /// Bu istemcinin gördüğü ya da gönderdiği hamle sayısı (sıra numarası).
  int _ply = 0;

  _FsMatch(this.b, this.ref);

  static Future<OnlineMatch> open(FirebaseBackend b, DocumentReference<Map<String, dynamic>> ref) async {
    final m = _FsMatch(b, ref);
    m._d = (await ref.get()).data() ?? {};
    m._subs.add(ref.snapshots().listen((s) {
      m._d = s.data() ?? m._d;
      m._changes.add(null);
    }));
    m._subs.add(ref.collection('moves').orderBy('n').snapshots().listen((q) {
      for (final c in q.docChanges) {
        if (c.type != DocumentChangeType.added) continue;
        final x = c.doc.data()!;
        final n = (x['n'] as num).toInt();
        if (n >= m._ply) m._ply = n + 1;
        if (x['by'] != b.uid) m._moves.add(((x['seat'] as num).toInt(), x['move'] as String));
      }
    }));
    m._subs.add(ref.collection('events').orderBy('ts').snapshots().listen((q) {
      for (final c in q.docChanges) {
        if (c.type != DocumentChangeType.added || c.doc.metadata.hasPendingWrites) continue;
        final x = c.doc.data()!;
        m._events.add(TableEvent((x['seat'] as num).toInt(), x['kind'] as String, x['value'] as String, (x['to'] as num?)?.toInt() ?? -1));
      }
    }));
    m._beat = Timer.periodic(const Duration(seconds: 15), (_) => ref.update({'beats.${b.uid}': FieldValue.serverTimestamp()}));
    return m;
  }

  @override
  String get id => ref.id;
  @override
  String get gameId => _d['gameId'] as String? ?? '';
  @override
  String get code => _d['code'] as String? ?? '';
  @override
  bool get private => _d['private'] == true;
  @override
  int get seed => (_d['seed'] as num?)?.toInt() ?? 0;
  @override
  List<Seat> get seats => [for (final x in (_d['seats'] as List? ?? const [])) Seat.fromJson(Map<String, dynamic>.from(x as Map))];
  @override
  int get mySeat => seats.indexWhere((s) => s.uid == b.uid);
  @override
  String get hostUid => _d['host'] as String? ?? '';

  /// Ev sahibi: kopmamış ilk insan koltuğu (asıl ev sahibi düşerse sıradaki devralır).
  @override
  bool get isHost {
    final s = seats;
    final gone = dropped;
    for (var i = 0; i < s.length; i++) {
      if (!s[i].bot && !gone.contains(i)) return i == mySeat;
    }
    return false;
  }

  @override
  MatchStatus get status => switch (_d['status']) {
        'playing' => MatchStatus.playing,
        'done' => MatchStatus.done,
        _ => MatchStatus.waiting,
      };
  @override
  Stream<void> get changes => _changes.stream;
  @override
  Stream<(int, String)> get moves => _moves.stream;
  @override
  Stream<TableEvent> get events => _events.stream;

  /// 45 saniyedir kalp atışı gelmeyen insan koltukları.
  @override
  Set<int> get dropped {
    final beats = (_d['beats'] as Map?) ?? const {};
    final now = DateTime.now();
    final s = seats;
    return {
      for (var i = 0; i < s.length; i++)
        if (!s[i].bot && i != mySeat && beats[s[i].uid] is Timestamp && now.difference((beats[s[i].uid] as Timestamp).toDate()).inSeconds > 45) i
    };
  }

  @override
  Future<void> send(String move, {int? asSeat}) async {
    final n = _ply++;
    await ref.collection('moves').doc(n.toString().padLeft(6, '0')).set({
      'n': n,
      'seat': asSeat ?? mySeat,
      'move': move,
      'by': b.uid,
      'ts': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> say(TableEvent e) async {
    _events.add(e); // kendi mesajını hemen göster
    await ref.collection('events').add({'seat': e.seat, 'kind': e.kind, 'value': e.value, 'to': e.to, 'by': b.uid, 'ts': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> finish(int winner) => ref.update({'status': 'done', 'winner': winner});

  @override
  Future<void> leave() async {
    _beat?.cancel();
    for (final s in _subs) {
      await s.cancel();
    }
    if (status == MatchStatus.waiting && isHost && seats.length == 1) {
      await ref.update({'status': 'done'});
    }
  }

  @override
  Future<void> fillWithBotsAndStart() async {
    final s = [for (final x in seats) x.toJson()];
    final size = (_d['size'] as num?)?.toInt() ?? s.length;
    while (s.length < size) {
      s.add(const Seat('', '').toJson());
    }
    await ref.update({'seats': s, 'status': 'playing'});
  }
}
