// Firestore güvenlik kuralları testleri (Firestore emülatörü).
// Çalıştırma: cd firebase && npm ci && npm test
// Kapsam: kimliksiz erişim, başkasının belgesine yazma, alan/boyut/expireAt
// doğrulaması, maç/hamle/canlı halka/sohbet/hediye/şikâyet/skor tabloları,
// özel maçların listelenememesi, başkasının özel verisinin okunamaması.
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  addDoc,
  arrayUnion,
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  increment,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
} from 'firebase/firestore';

const [host, port] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
let env;

const A = 'alice';
const B = 'bob';
const C = 'carol';
const db = (uid) => env.authenticatedContext(uid).firestore();
const anon = () => env.unauthenticatedContext().firestore();
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
const inHours = (h) => Timestamp.fromMillis(Date.now() + h * 3600 * 1000);

const profile = (uid, extra = {}) => ({
  uid,
  name: 'Mavi Tilki 12',
  avatar: 3,
  age16: false,
  terms: 1,
  active: '',
  vip: false,
  table: '',
  code: 'ABC234',
  rating: {},
  gifts: {},
  blocked: [],
  ...extra,
});

const waitingMatch = (host, extra = {}) => ({
  gameId: 'okey',
  size: 2,
  seed: 42,
  code: 'TBL234',
  private: false,
  host,
  status: 'waiting',
  seats: [{ uid: host, name: 'Host', avatar: 1, vip: false }],
  uids: [host],
  rating: 1000,
  created: Timestamp.now(),
  beats: { [host]: Timestamp.now() },
  ...extra,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-studio-core',
    firestore: {
      host,
      port: Number(port),
      rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
    },
  });
});

after(async () => {
  await env?.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
});

describe('kimliksiz erişim', () => {
  it('hiçbir koleksiyon okunamaz ya da yazılamaz', async () => {
    await seed(async (s) => {
      await setDoc(doc(s, 'users', A), profile(A));
      await setDoc(doc(s, 'matches', 'm1'), waitingMatch(A));
      await setDoc(doc(s, 'boards', 'b1', 'scores', A), { score: 5, name: 'x', avatar: 0 });
    });
    const u = anon();
    await assertFails(getDoc(doc(u, 'users', A)));
    await assertFails(getDoc(doc(u, 'matches', 'm1')));
    await assertFails(getDocs(collection(u, 'boards', 'b1', 'scores')));
    await assertFails(setDoc(doc(u, 'users', 'x'), profile('x')));
    await assertFails(addDoc(collection(u, 'reports'), { by: 'x', target: A, reason: 'spam', ts: serverTimestamp() }));
    await assertFails(getDoc(doc(u, 'codes', 'ABC234')));
    await assertFails(getDoc(doc(u, 'transfers', 'ABCDEFGHJK23')));
  });
});

describe('profil (users)', () => {
  it('sahibi geçerli profil oluşturur; başkası adına oluşturamaz', async () => {
    await assertSucceeds(setDoc(doc(db(A), 'users', A), { ...profile(A), created: serverTimestamp() }));
    await assertFails(setDoc(doc(db(A), 'users', B), profile(B)));
  });

  it('alan ve boyut doğrulaması', async () => {
    await assertFails(setDoc(doc(db(A), 'users', A), profile(A, { name: 'x'.repeat(17) })));
    await assertFails(setDoc(doc(db(A), 'users', A), profile(A, { isAdmin: true })));
    await assertFails(setDoc(doc(db(A), 'users', A), profile(A, { uid: B })));
    await assertFails(setDoc(doc(db(A), 'users', A), profile(A, { blocked: Array(501).fill('x') })));
  });

  it('arkadaş kodu değiştirilemez', async () => {
    await seed((s) => setDoc(doc(s, 'users', A), profile(A)));
    await assertSucceeds(updateDoc(doc(db(A), 'users', A), { name: 'Yeni Ad' }));
    await assertFails(updateDoc(doc(db(A), 'users', A), { code: 'ZZZ999' }));
  });

  it('tek tek okunur ama listelenemez', async () => {
    await seed((s) => setDoc(doc(s, 'users', A), profile(A)));
    await assertSucceeds(getDoc(doc(db(B), 'users', A)));
    await assertFails(getDocs(collection(db(B), 'users')));
  });

  it('başkası profili değiştiremez, yalnızca katalogdaki hediyeyi 1 artırır', async () => {
    await seed((s) => setDoc(doc(s, 'users', A), profile(A, { gifts: { rose: 2 } })));
    await assertFails(updateDoc(doc(db(B), 'users', A), { name: 'Hacked' }));
    await assertFails(updateDoc(doc(db(B), 'users', A), { vip: true }));
    await assertSucceeds(updateDoc(doc(db(B), 'users', A), { 'gifts.rose': increment(1) }));
    await assertSucceeds(updateDoc(doc(db(B), 'users', A), { 'gifts.tea': increment(1) }));
    await assertFails(updateDoc(doc(db(B), 'users', A), { 'gifts.rose': increment(5) }));
    await assertFails(updateDoc(doc(db(B), 'users', A), { 'gifts.rose': 0 }));
    await assertFails(updateDoc(doc(db(B), 'users', A), { 'gifts.diamond': increment(1) }));
    await assertFails(updateDoc(doc(db(B), 'users', A), { 'gifts.cake': increment(1), 'gifts.crown': increment(1) }));
    await assertFails(deleteDoc(doc(db(B), 'users', A)));
    await assertSucceeds(deleteDoc(doc(db(A), 'users', A)));
  });

  it('arkadaş listesi ve davetler yalnızca sahibine görünür', async () => {
    await seed(async (s) => {
      await setDoc(doc(s, 'users', A), profile(A));
      await setDoc(doc(s, 'users', A, 'friends', B), { at: Timestamp.now() });
      await setDoc(doc(s, 'users', A, 'invites', 'i1'), { from: B, code: 'TBL234', at: Date.now() });
    });
    await assertSucceeds(getDocs(collection(db(A), 'users', A, 'friends')));
    await assertFails(getDocs(collection(db(C), 'users', A, 'friends')));
    await assertFails(getDocs(collection(db(C), 'users', A, 'invites')));
    await assertFails(getDoc(doc(db(C), 'users', A, 'invites', 'i1')));
  });

  it('arkadaşlık belgesi: iki taraf yazar, üçüncü kişi yazamaz', async () => {
    await assertSucceeds(setDoc(doc(db(A), 'users', A, 'friends', B), { at: serverTimestamp() }));
    await assertSucceeds(setDoc(doc(db(A), 'users', B, 'friends', A), { at: serverTimestamp() }));
    await assertFails(setDoc(doc(db(C), 'users', B, 'friends', A), { at: serverTimestamp() }));
    await assertFails(setDoc(doc(db(A), 'users', A, 'friends', B), { at: serverTimestamp(), extra: 1 }));
  });

  it('davet: yalnızca arkadaştan, geçerli alanlarla', async () => {
    await seed((s) => setDoc(doc(s, 'users', A, 'friends', B), { at: Timestamp.now() }));
    const inv = { from: B, name: 'Bob', avatar: 1, gameId: 'okey', code: 'TBL234', at: Date.now(), ts: serverTimestamp() };
    await assertSucceeds(addDoc(collection(db(B), 'users', A, 'invites'), inv));
    await assertFails(addDoc(collection(db(C), 'users', A, 'invites'), { ...inv, from: C }));
    await assertFails(addDoc(collection(db(B), 'users', A, 'invites'), { ...inv, from: C }));
    await assertFails(addDoc(collection(db(B), 'users', A, 'invites'), { ...inv, code: 'X'.repeat(9) }));
  });
});

describe('arkadaş kodları (codes)', () => {
  it('kendi kodunu yazar, listelenemez, başkasınınkini silemez', async () => {
    await assertSucceeds(setDoc(doc(db(A), 'codes', 'ABC234'), { uid: A }));
    await assertFails(setDoc(doc(db(B), 'codes', 'XYZ234'), { uid: A }));
    await assertFails(setDoc(doc(db(B), 'codes', 'ABC234'), { uid: B }));
    await assertFails(setDoc(doc(db(B), 'codes', 'bad code'), { uid: B }));
    await assertSucceeds(getDoc(doc(db(B), 'codes', 'ABC234')));
    await assertFails(getDocs(collection(db(B), 'codes')));
    await assertFails(deleteDoc(doc(db(B), 'codes', 'ABC234')));
    await assertSucceeds(deleteDoc(doc(db(A), 'codes', 'ABC234')));
  });
});

describe('bulut kayıt (saves)', () => {
  it('yalnızca sahibi okur/yazar; boyut sınırı', async () => {
    await assertSucceeds(setDoc(doc(db(A), 'saves', A, 'blobs', 'k1'), { v: '{}', ts: serverTimestamp() }));
    await assertFails(getDoc(doc(db(B), 'saves', A, 'blobs', 'k1')));
    await assertFails(setDoc(doc(db(B), 'saves', A, 'blobs', 'k1'), { v: '{}' }));
    await assertFails(setDoc(doc(db(A), 'saves', A, 'blobs', 'k2'), { v: 'x'.repeat(900001) }));
    await assertFails(setDoc(doc(db(A), 'saves', A, 'blobs', 'k3'), { v: 5 }));
    await assertSucceeds(deleteDoc(doc(db(A), 'saves', A, 'blobs', 'k1')));
  });
});

describe('skor tabloları (boards)', () => {
  it('herkes okur; yalnızca kendi skorunu yukarı doğru yazar', async () => {
    const s = { score: 100, name: 'Alice', avatar: 2, ts: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db(A), 'boards', 'okey', 'scores', A), s));
    await assertSucceeds(getDocs(collection(db(B), 'boards', 'okey', 'scores')));
    await assertFails(setDoc(doc(db(B), 'boards', 'okey', 'scores', A), s));
    await assertSucceeds(setDoc(doc(db(A), 'boards', 'okey', 'scores', A), { ...s, score: 150 }));
    await assertFails(setDoc(doc(db(A), 'boards', 'okey', 'scores', A), { ...s, score: 10 }));
    await assertFails(setDoc(doc(db(A), 'boards', 'okey', 'scores', A), { ...s, score: 100000000 }));
    await assertFails(setDoc(doc(db(A), 'boards', 'okey', 'scores', A), { ...s, score: 200, cheat: true }));
    await assertFails(setDoc(doc(db(A), 'boards', 'okey', 'scores', A), { ...s, score: 'çok' }));
  });
});

describe('maçlar (matches)', () => {
  it('oluşturma: yalnızca kendi adına, geçerli alanlarla', async () => {
    const m = { ...waitingMatch(A), created: serverTimestamp(), beats: { [A]: serverTimestamp() } };
    await assertSucceeds(setDoc(doc(db(A), 'matches', 'm1'), m));
    await assertFails(setDoc(doc(db(B), 'matches', 'm2'), m));
    await assertFails(setDoc(doc(db(A), 'matches', 'm3'), { ...m, status: 'done' }));
    await assertFails(setDoc(doc(db(A), 'matches', 'm4'), { ...m, uids: [A, B] }));
    await assertFails(setDoc(doc(db(A), 'matches', 'm5'), { ...m, size: 99 }));
    await assertFails(setDoc(doc(db(A), 'matches', 'm6'), { ...m, winner: 0 }));
  });

  it('özel masalar listelenemez; herkese açık lobi listelenir', async () => {
    await seed(async (s) => {
      await setDoc(doc(s, 'matches', 'pub'), waitingMatch(A));
      await setDoc(doc(s, 'matches', 'priv'), waitingMatch(A, { private: true, code: 'SEC234' }));
    });
    const lobby = query(
      collection(db(B), 'matches'),
      where('gameId', '==', 'okey'),
      where('size', '==', 2),
      where('private', '==', false),
      where('status', '==', 'waiting'),
    );
    await assertSucceeds(getDocs(lobby));
    await assertFails(getDocs(query(collection(db(B), 'matches'), where('code', '==', 'SEC234'))));
    await assertFails(getDocs(collection(db(B), 'matches')));
    await assertSucceeds(getDoc(doc(db(B), 'matches', 'priv')));
  });

  it('katılma: yalnızca kendi koltuğunu sona ekler', async () => {
    await seed((s) => setDoc(doc(s, 'matches', 'm1'), waitingMatch(A)));
    const me = { uid: B, name: 'Bob', avatar: 2, vip: false };
    const host = waitingMatch(A).seats[0];
    await assertFails(
      updateDoc(doc(db(B), 'matches', 'm1'), { seats: [host, { ...me, uid: C }], uids: arrayUnion(B) }),
    );
    await assertFails(updateDoc(doc(db(B), 'matches', 'm1'), { seats: [me], uids: arrayUnion(B) }));
    await assertFails(
      updateDoc(doc(db(B), 'matches', 'm1'), { seats: [host, me], uids: arrayUnion(B), host: B }),
    );
    await assertSucceeds(
      updateDoc(doc(db(B), 'matches', 'm1'), {
        seats: [host, me],
        uids: arrayUnion(B),
        [`beats.${B}`]: serverTimestamp(),
        status: 'playing',
      }),
    );
    // Dolu/başlamış masaya üçüncü kişi giremez.
    await assertFails(
      updateDoc(doc(db(C), 'matches', 'm1'), {
        seats: [host, me, { ...me, uid: C }],
        uids: arrayUnion(C),
      }),
    );
  });

  it('masadakiler: yalnızca kendi kalp atışı; bitmiş maç yeniden açılmaz', async () => {
    await seed((s) =>
      setDoc(
        doc(s, 'matches', 'm1'),
        waitingMatch(A, {
          status: 'playing',
          seats: [waitingMatch(A).seats[0], { uid: B, name: 'Bob', avatar: 0, vip: false }],
          uids: [A, B],
          beats: { [A]: Timestamp.now(), [B]: Timestamp.now() },
        }),
      ),
    );
    await assertSucceeds(updateDoc(doc(db(B), 'matches', 'm1'), { [`beats.${B}`]: serverTimestamp() }));
    await assertFails(updateDoc(doc(db(B), 'matches', 'm1'), { [`beats.${A}`]: serverTimestamp() }));
    await assertFails(updateDoc(doc(db(B), 'matches', 'm1'), { host: B }));
    await assertFails(updateDoc(doc(db(B), 'matches', 'm1'), { seats: [] }));
    await assertFails(updateDoc(doc(db(C), 'matches', 'm1'), { status: 'done', winner: 2 }));
    await assertSucceeds(updateDoc(doc(db(B), 'matches', 'm1'), { status: 'done', winner: 1 }));
    await assertFails(updateDoc(doc(db(A), 'matches', 'm1'), { status: 'playing' }));
  });

  it('botla doldurma: mevcut koltuklar korunur', async () => {
    await seed((s) => setDoc(doc(s, 'matches', 'm1'), waitingMatch(A, { size: 3 })));
    const host = waitingMatch(A).seats[0];
    const bot = { uid: '', name: '', avatar: 0, vip: false };
    await assertSucceeds(updateDoc(doc(db(A), 'matches', 'm1'), { seats: [host, bot, bot], status: 'playing' }));
    await assertFails(updateDoc(doc(db(A), 'matches', 'm1'), { seats: [host, bot, bot, bot] }));
  });

  it('hamleler: yalnızca masadakiler, değiştirilemez', async () => {
    await seed((s) => setDoc(doc(s, 'matches', 'm1'), waitingMatch(A, { uids: [A, B], status: 'playing' })));
    const mv = { n: 0, seat: 0, move: 'e2e4', by: A, ts: serverTimestamp() };
    await assertSucceeds(setDoc(doc(db(A), 'matches', 'm1', 'moves', '000000'), mv));
    await assertFails(setDoc(doc(db(A), 'matches', 'm1', 'moves', '000000'), { ...mv, move: 'e2e5' }));
    await assertFails(deleteDoc(doc(db(A), 'matches', 'm1', 'moves', '000000')));
    await assertFails(setDoc(doc(db(C), 'matches', 'm1', 'moves', '000001'), { ...mv, n: 1, by: C }));
    await assertFails(setDoc(doc(db(B), 'matches', 'm1', 'moves', '000001'), { ...mv, n: 1, by: A }));
    await assertFails(setDoc(doc(db(B), 'matches', 'm1', 'moves', '000001'), { ...mv, n: 1, by: B, move: 'x'.repeat(4001) }));
    await assertFails(setDoc(doc(db(B), 'matches', 'm1', 'moves', 'abc'), { ...mv, n: 1, by: B }));
    await assertSucceeds(getDocs(collection(db(C), 'matches', 'm1', 'moves')));
  });

  it('canlı halka (live): koltuk/yuva adı, boyut ve expireAt', async () => {
    await seed((s) => setDoc(doc(s, 'matches', 'm1'), waitingMatch(A, { uids: [A, B], status: 'playing' })));
    const live = { seat: 1, seq: 3, d: 'xy', by: B, expireAt: inHours(2) };
    await assertSucceeds(setDoc(doc(db(B), 'matches', 'm1', 'live', '1_3'), live));
    await assertFails(setDoc(doc(db(B), 'matches', 'm1', 'live', '0_3'), live));
    await assertFails(setDoc(doc(db(B), 'matches', 'm1', 'live', '1_4'), { ...live, expireAt: inHours(48) }));
    await assertFails(setDoc(doc(db(B), 'matches', 'm1', 'live', '1_5'), { ...live, d: 'x'.repeat(4001) }));
    await assertFails(setDoc(doc(db(B), 'matches', 'm1', 'live', '1_6'), { ...live, by: A }));
    await assertFails(setDoc(doc(db(C), 'matches', 'm1', 'live', '1_7'), { ...live, by: C }));
    await assertFails(setDoc(doc(db(B), 'matches', 'm1', 'live', '1_8'), { ...live, extra: 1 }));
    await assertFails(deleteDoc(doc(db(C), 'matches', 'm1', 'live', '1_3')));
    await assertSucceeds(deleteDoc(doc(db(A), 'matches', 'm1', 'live', '1_3')));
  });

  it('sohbet ve hediye olayları (events)', async () => {
    await seed(async (s) => {
      await setDoc(doc(s, 'matches', 'm1'), waitingMatch(A, { uids: [A, B], status: 'playing' }));
      await setDoc(doc(s, 'users', A), profile(A, { age16: true }));
      await setDoc(doc(s, 'users', B), profile(B, { age16: false }));
    });
    const ev = (by, kind, value) => ({ seat: 0, kind, value, to: -1, by, ts: serverTimestamp() });
    const events = (uid) => collection(db(uid), 'matches', 'm1', 'events');
    await assertSucceeds(addDoc(events(A), ev(A, 't', 'iyi oyun')));
    await assertFails(addDoc(events(A), ev(A, 't', 'x'.repeat(121))));
    await assertFails(addDoc(events(B), ev(B, 't', 'merhaba')));
    await assertSucceeds(addDoc(events(B), ev(B, 'p', 'msg_gg')));
    await assertSucceeds(addDoc(events(B), { ...ev(B, 'g', 'rose'), to: 0 }));
    await assertFails(addDoc(events(B), ev(B, 'x', 'hack')));
    await assertFails(addDoc(events(B), ev(A, 'p', 'msg_gg')));
    await assertFails(addDoc(events(C), ev(C, 'p', 'msg_gg')));
  });
});

describe('masa kodları (matchCodes)', () => {
  it('yalnızca ev sahibi, maçtaki kodla; listelenemez', async () => {
    await seed((s) => setDoc(doc(s, 'matches', 'm1'), waitingMatch(A, { private: true, code: 'SEC234' })));
    const mc = { match: 'm1', by: A, expireAt: inHours(24) };
    await assertFails(setDoc(doc(db(B), 'matchCodes', 'SEC234'), { ...mc, by: B }));
    await assertFails(setDoc(doc(db(A), 'matchCodes', 'OTH234'), mc));
    await assertFails(setDoc(doc(db(A), 'matchCodes', 'SEC234'), { ...mc, expireAt: inHours(24 * 30) }));
    await assertSucceeds(setDoc(doc(db(A), 'matchCodes', 'SEC234'), mc));
    await assertFails(setDoc(doc(db(A), 'matchCodes', 'SEC234'), { ...mc, match: 'm2' }));
    await assertSucceeds(getDoc(doc(db(B), 'matchCodes', 'SEC234')));
    await assertFails(getDocs(collection(db(B), 'matchCodes')));
    await assertFails(deleteDoc(doc(db(B), 'matchCodes', 'SEC234')));
  });
});

describe('telefon değişimi (transfers)', () => {
  const code = 'ABCDEFGHJK23';
  it('oluşturma: kendi adına, 12 karakter kod, en çok 7 gün', async () => {
    const t = { by: A, profile: { name: 'Alice' }, created: serverTimestamp(), expireAt: inHours(24) };
    await assertFails(setDoc(doc(db(A), 'transfers', 'SHORT'), t));
    await assertFails(setDoc(doc(db(A), 'transfers', code), { ...t, by: B }));
    await assertFails(setDoc(doc(db(A), 'transfers', code), { ...t, expireAt: inHours(24 * 30) }));
    await assertSucceeds(setDoc(doc(db(A), 'transfers', code), t));
    await assertSucceeds(setDoc(doc(db(A), 'transfers', code, 'blobs', 'save'), { v: '{}' }));
    await assertFails(setDoc(doc(db(B), 'transfers', code, 'blobs', 'evil'), { v: '{}' }));
    await assertFails(getDocs(collection(db(B), 'transfers')));
    await assertSucceeds(getDoc(doc(db(B), 'transfers', code)));
    await assertSucceeds(getDocs(collection(db(B), 'transfers', code, 'blobs')));
  });
});

describe('şikâyetler (reports)', () => {
  it('yalnızca yazılır, kendi adına ve sınırlı boyutta', async () => {
    const r = { by: A, target: B, reason: 'spam', match: 'm1', text: 'kötü söz', ts: serverTimestamp() };
    await assertSucceeds(addDoc(collection(db(A), 'reports'), r));
    await assertFails(addDoc(collection(db(A), 'reports'), { ...r, by: B }));
    await assertFails(addDoc(collection(db(A), 'reports'), { ...r, text: 'x'.repeat(501) }));
    await assertFails(getDocs(collection(db(A), 'reports')));
  });
});

describe('tanımsız koleksiyonlar', () => {
  it('varsayılan olarak kapalı', async () => {
    await assertFails(setDoc(doc(db(A), 'admin', 'x'), { a: 1 }));
    await assertFails(getDoc(doc(db(A), 'admin', 'x')));
  });
});
