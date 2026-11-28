// Çok istemcili çevrimiçi masa testleri: Firestore + Authentication emülatörü.
//
// Her istemci ayrı bir Firebase uygulamasıdır ve Auth emülatöründe anonim
// oturum açar (gerçek kimlik belirteci, gerçek kurallar). İstemcilerin yazdığı
// belgeler lib/online/firebase_backend.dart'ın yazdıklarının birebir aynısıdır
// (createMatch, _join işlemi, send, pulse, say, finish, leave(forfeit),
// fillWithBotsAndStart işlemi, offerRematch işlemi, quickMatch süzgeci).
//
// Kapsam: 2–4 istemciyle masa kurma (kod, hızlı eşleşme), maçı sonuna kadar
// oynama; son koltuk için yarış; aynı sıra numarasına eşzamanlı hamle;
// kopma (ağ kapalı) → bot devralması → geri dönüşte çakışan hamlenin
// reddedilmesi; ev sahibinin masadan kalkması; hileli yazmalar; eskimiş
// masalar ve TTL alanları; gecikme enjeksiyonu; sürüm alanı; rövanş.
import { after, before, describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { deleteApp, initializeApp } from 'firebase/app';
import { connectAuthEmulator, getAuth, signInAnonymously } from 'firebase/auth';
import {
  Timestamp,
  addDoc,
  arrayUnion,
  collection,
  connectFirestoreEmulator,
  disableNetwork,
  doc,
  enableNetwork,
  getDoc,
  getDocs,
  getFirestore,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  setDoc,
  updateDoc,
  where,
  limit,
} from 'firebase/firestore';
import { initializeTestEnvironment } from '@firebase/rules-unit-testing';

const PROJECT = 'demo-studio-core';
const [fsHost, fsPort] = (process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080').split(':');
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const VERSION = '2.1';
const BOT = { uid: '', name: '', avatar: 0, vip: false };

let env;
const apps = [];
let appN = 0;

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
const inDays = (d) => Timestamp.fromMillis(Date.now() + d * 86400000);
const pad = (n) => String(n).padStart(6, '0');
const denied = async (p) => {
  await assert.rejects(p, (e) => /permission|PERMISSION_DENIED|denied/i.test(String(e?.code ?? e?.message ?? e)));
};

/** Bir istemci: Auth emülatöründe anonim oturum + kendi Firestore örneği. */
async function client(name, { age16 = false, latency = 0 } = {}) {
  const app = initializeApp({ projectId: PROJECT, apiKey: 'demo-key', appId: `demo-${appN}` }, `c${appN++}`);
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${authHost}`, { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, fsHost, Number(fsPort));
  const cred = await signInAnonymously(auth);
  const uid = cred.user.uid;
  await setDoc(doc(db, 'users', uid), {
    uid, name, avatar: 1, age16, terms: 1, active: '', vip: false, table: '', code: '', rating: {}, gifts: {}, blocked: [],
  });
  const c = { app, db, uid, name, latency, ply: 0, maxSeen: -1 };
  c.seat = () => ({ uid, name, avatar: 1, vip: false });
  c.delay = async () => { if (c.latency) await sleep(Math.floor(Math.random() * c.latency)); };
  return c;
}

// ---- firebase_backend.dart ile aynı yazmalar -------------------------------------------

async function createMatch(c, size, { priv = true, code = null, version = VERSION } = {}) {
  const ref = doc(collection(c.db, 'matches'));
  code ??= Math.random().toString(36).slice(2, 8).toUpperCase().replace(/[^A-Z0-9]/g, 'X');
  await setDoc(ref, {
    gameId: 'oyun-x', size, seed: 42, code, private: priv, host: c.uid, status: 'waiting',
    seats: [c.seat()], uids: [c.uid], rating: 1000, created: serverTimestamp(),
    beats: { [c.uid]: serverTimestamp() }, v: version, expireAt: inDays(1),
  });
  await setDoc(doc(c.db, 'matchCodes', code), { match: ref.id, by: c.uid, expireAt: inDays(1) });
  return { id: ref.id, code };
}

async function join(c, id, version = VERSION) {
  const ref = doc(c.db, 'matches', id);
  return runTransaction(c.db, async (t) => {
    const s = await t.get(ref);
    const d = s.data();
    if (!d || d.status !== 'waiting') return false;
    if ((d.v ?? '') !== version) throw new Error('version-mismatch');
    if (d.seats.length >= d.size || d.seats.some((x) => x.uid === c.uid)) return false;
    const seats = [...d.seats, c.seat()];
    t.update(ref, {
      seats, uids: arrayUnion(c.uid), [`beats.${c.uid}`]: serverTimestamp(),
      ...(seats.length === d.size ? { status: 'playing' } : {}),
    });
    return true;
  });
}

async function joinByCode(c, code) {
  const s = await getDoc(doc(c.db, 'matchCodes', code));
  return s.exists() ? join(c, s.data().match) : false;
}

async function fillWithBots(c, id) {
  const ref = doc(c.db, 'matches', id);
  await runTransaction(c.db, async (t) => {
    const d = (await t.get(ref)).data();
    if (!d || d.status !== 'waiting') return;
    const seats = [...d.seats];
    while (seats.length < d.size) seats.push({ ...BOT });
    t.update(ref, { seats, status: 'playing' });
  });
}

/** send(): sıra numarası = görülen en büyük + 1; reddedilirse hata döner. */
async function send(c, id, move, seat) {
  const n = c.ply++;
  await c.delay();
  try {
    await setDoc(doc(c.db, 'matches', id, 'moves', pad(n)), {
      n, seat, move, by: c.uid, ts: serverTimestamp(), expireAt: inDays(1),
    });
    if (n > c.maxSeen) c.maxSeen = n;
    return true;
  } catch (e) {
    c.ply = c.maxSeen + 1;
    return false;
  }
}

async function moves(c, id) {
  const q = await getDocs(query(collection(c.db, 'matches', id, 'moves'), orderBy('n')));
  const out = q.docs.map((d) => d.data());
  for (const m of out) if (m.n >= c.ply) c.ply = m.n + 1;
  for (const m of out) if (m.n > c.maxSeen) c.maxSeen = m.n;
  return out;
}

async function quickMatchCandidates(c, size, version = VERSION) {
  const q = await getDocs(query(
    collection(c.db, 'matches'),
    where('gameId', '==', 'oyun-x'), where('size', '==', size), where('private', '==', false),
    where('status', '==', 'waiting'), orderBy('created'), limit(10),
  ));
  const now = Date.now();
  return q.docs.filter((d) => {
    const j = d.data();
    const b = j.beats?.[j.host];
    const alive = !(b instanceof Timestamp) || Math.abs(now - b.toMillis()) <= 90000;
    return (j.v ?? '') === version && alive;
  }).map((d) => d.id);
}

// ---- Yarış oyunu: sırayla 1–3 eklenir, 31'e ulaşan kazanır ---------------------------

const choose = (ply, seat) => 1 + ((ply * 7 + seat * 3 + 5) % 3);

/** Sunucudaki hamlelerden durumu kurar (her istemci aynı sonucu bulmalı). */
function replay(ms, size) {
  let total = 0, turn = 0, winner = -1;
  const log = [];
  for (const m of ms) {
    if (winner >= 0) break;
    if (m.seat !== turn) continue; // sırası olmayan hamle yok sayılır (motorlarda da)
    total += Number(m.move);
    log.push(`${m.seat}:${m.move}`);
    if (total >= 31) winner = m.seat; else turn = (turn + 1) % size;
  }
  return { total, turn, winner, log };
}

/** Bir maçı sonuna kadar oynatır: herkes kendi sırasında, ev sahibi botlar için. */
async function playOut(cs, id, size, botSeats, { maxSteps = 400 } = {}) {
  for (let step = 0; step < maxSteps; step++) {
    const ms = await moves(cs[0], id);
    const st = replay(ms, size);
    if (st.winner >= 0) return st;
    const seat = st.turn;
    const owner = botSeats.has(seat) ? cs[0] : cs.find((c) => c.mySeat === seat);
    await moves(owner, id);
    await send(owner, id, String(choose(st.log.length, seat)), seat);
  }
  throw new Error('maç bitmedi');
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { host: fsHost, port: Number(fsPort), rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
  await env.clearFirestore();
});

after(async () => {
  for (const a of apps) await deleteApp(a).catch(() => {});
  await env?.cleanup();
});

describe('çok istemcili masa (Auth + Firestore emülatörü)', () => {
  for (const [humans, size] of [[2, 2], [3, 3], [2, 4], [4, 4]]) {
    it(`${humans} istemci / ${size} koltuk: kodla kurulur, maç sonuna kadar oynanır`, async () => {
      const cs = [];
      for (let i = 0; i < humans; i++) cs.push(await client(i === 1 ? 'نسر ذهبي' : `Oyuncu${i}`));
      const { id, code } = await createMatch(cs[0], size);
      cs[0].mySeat = 0;
      for (let i = 1; i < humans; i++) {
        assert.equal(await joinByCode(cs[i], code), true);
        cs[i].mySeat = i;
      }
      if (humans < size) await fillWithBots(cs[0], id);
      const m = (await getDoc(doc(cs[1].db, 'matches', id))).data();
      assert.equal(m.status, 'playing');
      assert.equal(m.seats.length, size);
      const bots = new Set([...Array(size).keys()].filter((s) => s >= humans));
      const st = await playOut(cs, id, size, bots);
      // Herkes sunucudan aynı maçı okur.
      for (const c of cs) assert.deepEqual(replay(await moves(c, id), size).log, st.log);
      await updateDoc(doc(cs[0].db, 'matches', id), { status: 'done', winner: st.winner });
      // Bitmiş maça hamle yazılamaz.
      assert.equal(await send(cs[1], id, '1', 1), false);
    });
  }

  it('gecikme enjeksiyonu: 3 istemci rastgele 0–80 ms gecikmeyle tutarlı', async () => {
    const cs = [await client('A', { latency: 80 }), await client('B', { latency: 80 }), await client('C', { latency: 80 })];
    const { id, code } = await createMatch(cs[0], 3);
    cs[0].mySeat = 0;
    for (let i = 1; i < 3; i++) { await joinByCode(cs[i], code); cs[i].mySeat = i; }
    const st = await playOut(cs, id, 3, new Set());
    for (const c of cs) assert.deepEqual(replay(await moves(c, id), 3).log, st.log);
  });

  it('son koltuk için iki istemci yarışır: yalnızca biri oturur', async () => {
    const a = await client('A'), b = await client('B'), c = await client('C');
    const { id } = await createMatch(a, 2, { priv: false });
    const r = await Promise.allSettled([join(b, id), join(c, id)]);
    const ok = r.filter((x) => x.status === 'fulfilled' && x.value === true).length;
    assert.equal(ok, 1);
    const m = (await getDoc(doc(a.db, 'matches', id))).data();
    assert.equal(m.seats.length, 2);
    assert.equal(m.status, 'playing');
  });

  it('aynı sıra numarasına eşzamanlı iki hamle: biri yazılır, diğeri reddedilir', async () => {
    const a = await client('A'), b = await client('B');
    const { id, code } = await createMatch(a, 3);
    await joinByCode(b, code);
    await fillWithBots(a, id);
    // A kendi koltuğuna, B'nin cihazı (eski görünümle) bot koltuğuna aynı numarayla.
    const r = await Promise.all([send(a, id, '1', 0), send(b, id, '2', 2)]);
    assert.equal(r.filter(Boolean).length, 1);
    assert.equal((await moves(a, id)).length, 1);
  });

  it('kopma → bot devralması → geri dönüşte çakışan hamle reddedilir; masa geçmişten kurulur', async () => {
    const a = await client('Ev'), b = await client('Misafir');
    const { id, code } = await createMatch(a, 2);
    await joinByCode(b, code);
    assert.equal(await send(a, id, '2', 0), true);
    await moves(b, id);
    // Misafirin ağı kesildi; kendi sırasında oynadı (yazma sıraya girdi).
    await disableNetwork(b.db);
    const pending = send(b, id, '3', 1);
    // 60 sn geçmiş gibi: misafirin kalp atışı eskidi; ev sahibi bot olarak oynar.
    await seed((s) => updateDoc(doc(s, 'matches', id), { [`beats.${b.uid}`]: Timestamp.fromMillis(Date.now() - 60000) }));
    await moves(a, id);
    assert.equal(await send(a, id, '1', 1), true, 'kopan koltuk adına ev sahibi yazabilir');
    // Bağlantı geri geldi: bekleyen hamle aynı sıra numarasına düşer ve reddedilir.
    await enableNetwork(b.db);
    assert.equal(await pending, false);
    const ms = await moves(b, id);
    assert.deepEqual(ms.map((m) => `${m.seat}:${m.move}`), ['0:2', '1:1']);
    // Geri dönen misafir kendi kalp atışını tazeler; artık onun yerine yazılamaz.
    await updateDoc(doc(b.db, 'matches', id), { [`beats.${b.uid}`]: serverTimestamp() });
    assert.equal(await send(a, id, '1', 1), false);
  });

  it('ev sahibi masadan kalkar (yenik): kalp atışı 0, yeni ev sahibi onun yerine oynar', async () => {
    const a = await client('A'), b = await client('B'), c = await client('C');
    const { id, code } = await createMatch(a, 3);
    await joinByCode(b, code);
    await joinByCode(c, code);
    await updateDoc(doc(a.db, 'matches', id), { [`beats.${a.uid}`]: Timestamp.fromMillis(0) });
    const m = (await getDoc(doc(b.db, 'matches', id))).data();
    assert.equal(m.beats[a.uid].toMillis(), 0);
    assert.equal(await send(b, id, '2', 0), true, 'kalkan oyuncunun koltuğu bota geçti');
    // Kimse başkasının kalp atışını sıfırlayamaz; kendi kalp atışı eski bir zamana çekilemez.
    await denied(updateDoc(doc(c.db, 'matches', id), { [`beats.${b.uid}`]: Timestamp.fromMillis(0) }));
    await denied(updateDoc(doc(c.db, 'matches', id), { [`beats.${c.uid}`]: Timestamp.fromMillis(Date.now() - 120000) }));
  });

  it('hileli yazmalar reddedilir', async () => {
    const a = await client('A', { age16: true }), b = await client('B'), x = await client('Yabancı');
    const { id, code } = await createMatch(a, 3);
    await joinByCode(b, code);
    // Bağlı oyuncunun yerine hamle (B, A'nın koltuğuna) ve olmayan koltuk.
    await denied(setDoc(doc(b.db, 'matches', id, 'moves', pad(0)), { n: 0, seat: 0, move: '3', by: b.uid, ts: serverTimestamp() }));
    // Masa henüz başlamadı (bekliyor): hamle yazılamaz.
    await denied(setDoc(doc(b.db, 'matches', id, 'moves', pad(0)), { n: 0, seat: 1, move: '3', by: b.uid, ts: serverTimestamp() }));
    await fillWithBots(a, id);
    await denied(setDoc(doc(b.db, 'matches', id, 'moves', pad(0)), { n: 0, seat: 9, move: '3', by: b.uid, ts: serverTimestamp() }));
    // Belge adı sıra numarasıyla aynı olmalı.
    await denied(setDoc(doc(b.db, 'matches', id, 'moves', pad(5)), { n: 0, seat: 1, move: '3', by: b.uid, ts: serverTimestamp() }));
    // Masada olmayan yazamaz.
    await denied(setDoc(doc(x.db, 'matches', id, 'moves', pad(0)), { n: 0, seat: 2, move: '3', by: x.uid, ts: serverTimestamp() }));
    // Sahte insan koltuğu eklenemez (yalnızca bot): masa dolu, ama boş masada da denenir.
    const t2 = await createMatch(a, 3);
    await denied(updateDoc(doc(a.db, 'matches', t2.id), { seats: [a.seat(), { uid: x.uid, name: 'Sahte', avatar: 0, vip: false }] }));
    await denied(updateDoc(doc(a.db, 'matches', t2.id), { seats: [a.seat(), { ...BOT, name: 'gizli bot' }] }));
    // Aşırı uzun adla katılınamaz.
    await denied(runTransaction(x.db, async (t) => {
      const ref = doc(x.db, 'matches', t2.id);
      const d = (await t.get(ref)).data();
      t.update(ref, { seats: [...d.seats, { uid: x.uid, name: 'x'.repeat(200), avatar: 0, vip: false }], uids: arrayUnion(x.uid), [`beats.${x.uid}`]: serverTimestamp() });
    }));
    // Canlı halkada başkasının koltuğu.
    await denied(setDoc(doc(b.db, 'matches', id, 'live', '0_0'), { seat: 0, seq: 1, d: 'S|0', by: b.uid, expireAt: inDays(0.5) }));
    assert.ok(await setDoc(doc(b.db, 'matches', id, 'live', '1_0'), { seat: 1, seq: 1, d: 'I|0', by: b.uid, expireAt: inDays(0.5) }).then(() => true));
    // Sohbet: başkası adına; 16 yaş altı serbest yazı.
    await denied(addDoc(collection(b.db, 'matches', id, 'events'), { seat: 0, kind: 'p', value: 'chat_gg', to: -1, by: b.uid, ts: serverTimestamp() }));
    await denied(addDoc(collection(b.db, 'matches', id, 'events'), { seat: 1, kind: 't', value: 'selam', to: -1, by: b.uid, ts: serverTimestamp() }));
    await addDoc(collection(a.db, 'matches', id, 'events'), { seat: 0, kind: 't', value: 'iyi oyun', to: -1, by: a.uid, ts: serverTimestamp(), expireAt: inDays(1) });
    // TTL alanı en çok 2 gün sonrası.
    await denied(setDoc(doc(a.db, 'matches', id, 'moves', pad(0)), { n: 0, seat: 0, move: '1', by: a.uid, ts: serverTimestamp(), expireAt: inDays(5) }));
    // Sürüm alanı sınırlı; masa ömrü en çok 2 gün.
    await denied(setDoc(doc(collection(a.db, 'matches')), {
      gameId: 'oyun-x', size: 2, seed: 1, code: 'ZZZ234', private: true, host: a.uid, status: 'waiting',
      seats: [a.seat()], uids: [a.uid], rating: 1000, created: serverTimestamp(), beats: { [a.uid]: serverTimestamp() },
      v: 'x'.repeat(40),
    }));
    await denied(setDoc(doc(collection(a.db, 'matches')), {
      gameId: 'oyun-x', size: 2, seed: 1, code: 'ZZZ235', private: true, host: a.uid, status: 'waiting',
      seats: [a.seat()], uids: [a.uid], rating: 1000, created: serverTimestamp(), beats: { [a.uid]: serverTimestamp() },
      expireAt: inDays(5),
    }));
  });

  it('eskimiş masa (ev sahibi gitmiş) ve farklı sürüm hızlı eşleşmede seçilmez', async () => {
    const a = await client('A'), b = await client('B'), c = await client('C');
    const stale = await createMatch(a, 4, { priv: false });
    const other = await createMatch(c, 4, { priv: false, version: '2.9' });
    await seed((s) => updateDoc(doc(s, 'matches', stale.id), { [`beats.${a.uid}`]: Timestamp.fromMillis(Date.now() - 5 * 60000) }));
    const cand = await quickMatchCandidates(b, 4);
    assert.ok(!cand.includes(stale.id), 'eskimiş masa');
    assert.ok(!cand.includes(other.id), 'başka sürüm');
    await assert.rejects(join(b, other.id), /version-mismatch/);
    const fresh = await createMatch(c, 4, { priv: false });
    assert.ok((await quickMatchCandidates(b, 4)).includes(fresh.id));
    const m = (await getDoc(doc(b.db, 'matches', fresh.id))).data();
    assert.ok(m.expireAt instanceof Timestamp, 'TTL alanı var');
  });

  it('rövanş: yalnızca bir kez yazılır', async () => {
    const a = await client('A'), b = await client('B');
    const { id, code } = await createMatch(a, 2);
    await joinByCode(b, code);
    await updateDoc(doc(a.db, 'matches', id), { status: 'done', winner: 0 });
    const n1 = await createMatch(a, 2);
    await updateDoc(doc(a.db, 'matches', id), { next: `0|${n1.id}` });
    await denied(updateDoc(doc(b.db, 'matches', id), { next: '1|baska' }));
    assert.equal(await joinByCode(b, n1.code), true);
  });
});
