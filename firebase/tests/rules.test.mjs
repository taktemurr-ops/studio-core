// Firestore güvenlik kuralları testleri (emülatörde):
//   cd firebase && npx firebase-tools emulators:exec --only firestore --project demo-studio "cd tests && npm test"
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc, deleteDoc, serverTimestamp, collection, getDocs, query, orderBy } from 'firebase/firestore';

let env;
const utcDay = (d = new Date()) => d.toISOString().slice(0, 10);
const shiftDay = (n) => utcDay(new Date(Date.now() + n * 86400000));
const today = utcDay();
const board = (day = today, game = 'oyun-sudoku') => `${game}_${day}`;
const timeResult = (o = {}) => {
  const r = { ms: 83000, moves: 41, score: 0, m: 't', name: 'HizliTilki42', avatar: 3, at: serverTimestamp(), ...o };
  if (!('k' in o)) r.k = r.m === 't' ? r.ms * 1000 + Math.min(r.moves, 999) : 1000000000 - r.score;
  return r;
};

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-studio',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => env.clearFirestore());

const db = (uid) => (uid ? env.authenticatedContext(uid) : env.unauthenticatedContext()).firestore();

describe('Günün Bulmacası: daily/{board}/results/{uid}', () => {
  test('oyuncu bugünkü tabloya kendi sonucunu yazar ve herkes okur', async () => {
    await assertSucceeds(setDoc(doc(db('ali'), `daily/${board()}/results/ali`), timeResult()));
    await assertSucceeds(getDoc(doc(db('ayse'), `daily/${board()}/results/ali`)));
    await assertSucceeds(getDocs(query(collection(db('ayse'), `daily/${board()}/results`), orderBy('k'))));
  });

  test('dile bağlı tablo (oyun-dil_gün) ve puan sıralaması kabul edilir', async () => {
    const b = board(today, 'oyun-kelime-avi-tr');
    await assertSucceeds(setDoc(doc(db('ali'), `daily/${b}/results/ali`), timeResult({ m: 's', score: 1250, ms: 60000 })));
  });

  test('giriş yapmayan okuyamaz ve yazamaz', async () => {
    await assertFails(getDoc(doc(db(null), `daily/${board()}/results/ali`)));
    await assertFails(setDoc(doc(db(null), `daily/${board()}/results/ali`), timeResult()));
  });

  test('başkası adına yazılamaz', async () => {
    await assertFails(setDoc(doc(db('ayse'), `daily/${board()}/results/ali`), timeResult()));
  });

  test('sonuç değiştirilemez ve silinemez (günün ilk sonucu)', async () => {
    const ref = doc(db('ali'), `daily/${board()}/results/ali`);
    await assertSucceeds(setDoc(ref, timeResult()));
    await assertFails(updateDoc(ref, { ms: 1000, k: 1000 * 1000 + 41 }));
    await assertFails(setDoc(ref, timeResult({ ms: 2000 })));
    await assertFails(deleteDoc(ref));
  });

  test('sıralama anahtarı tutarsızsa reddedilir', async () => {
    await assertFails(setDoc(doc(db('ali'), `daily/${board()}/results/ali`), timeResult({ k: 5 })));
    await assertFails(setDoc(doc(db('ali'), `daily/${board()}/results/ali`), timeResult({ m: 's', score: 10, k: 0 })));
  });

  test('geçersiz değerler reddedilir', async () => {
    const ref = doc(db('ali'), `daily/${board()}/results/ali`);
    await assertFails(setDoc(ref, timeResult({ ms: 500 })));
    await assertFails(setDoc(ref, timeResult({ ms: 86400001 })));
    await assertFails(setDoc(ref, timeResult({ moves: -1 })));
    await assertFails(setDoc(ref, timeResult({ m: 'x' })));
    await assertFails(setDoc(ref, timeResult({ name: 'x'.repeat(17) })));
    await assertFails(setDoc(ref, timeResult({ avatar: 100 })));
    await assertFails(setDoc(ref, { ...timeResult(), extra: 1 }));
    await assertFails(setDoc(ref, timeResult({ at: new Date(0) })));
  });

  test('tablo adı biçimi denetlenir', async () => {
    await assertFails(setDoc(doc(db('ali'), `daily/Oyun_${today}/results/ali`), timeResult()));
    await assertFails(setDoc(doc(db('ali'), `daily/oyun-sudoku/results/ali`), timeResult()));
  });

  test('çevrimdışı sonuç birkaç gün sonra gönderilebilir, eski ve gelecek günlere yazılamaz', async () => {
    await assertSucceeds(setDoc(doc(db('ali'), `daily/${board(shiftDay(-2))}/results/ali`), timeResult()));
    await assertFails(setDoc(doc(db('ali'), `daily/${board(shiftDay(-6))}/results/ali`), timeResult()));
    await assertFails(setDoc(doc(db('ali'), `daily/${board(shiftDay(2))}/results/ali`), timeResult()));
  });
});

describe('mevcut kurallar (gerileme yok)', () => {
  test('profil: sahibi yazar, başkası yalnızca hediye sayacını değiştirir', async () => {
    await assertSucceeds(setDoc(doc(db('ali'), 'users/ali'), { name: 'Ali', gifts: {} }));
    await assertFails(setDoc(doc(db('ayse'), 'users/ali'), { name: 'X' }));
    await assertSucceeds(updateDoc(doc(db('ayse'), 'users/ali'), { gifts: { rose: 1 } }));
    await assertFails(updateDoc(doc(db('ayse'), 'users/ali'), { name: 'Hack' }));
  });

  test('skor tablosu: yalnızca kendi skorunu yazar', async () => {
    await assertSucceeds(setDoc(doc(db('ali'), 'boards/r_oyun-satranc/scores/ali'), { score: 1200, name: 'Ali', avatar: 0 }));
    await assertFails(setDoc(doc(db('ali'), 'boards/r_oyun-satranc/scores/ayse'), { score: 1200 }));
    await assertFails(setDoc(doc(db('ali'), 'boards/r_oyun-satranc/scores/ali'), { score: -1 }));
  });

  test('maç hamlesi: yalnızca masadakiler kendi adına yazar', async () => {
    await env.withSecurityRulesDisabled(async (c) => {
      await setDoc(doc(c.firestore(), 'matches/m1'), { host: 'ali', uids: ['ali', 'ayse'] });
    });
    await assertSucceeds(setDoc(doc(db('ayse'), 'matches/m1/moves/1'), { by: 'ayse', seat: 1, m: 'P:60=a' }));
    await assertFails(setDoc(doc(db('veli'), 'matches/m1/moves/2'), { by: 'veli', seat: 1, m: 'X' }));
    await assertFails(setDoc(doc(db('ayse'), 'matches/m1/moves/3'), { by: 'ali', seat: 0, m: 'X' }));
  });

  test('şikâyet yalnızca yazılır', async () => {
    await assertSucceeds(setDoc(doc(db('ali'), 'reports/r1'), { by: 'ali', uid: 'ayse', reason: 'spam' }));
    await assertFails(getDoc(doc(db('ali'), 'reports/r1')));
  });
});
