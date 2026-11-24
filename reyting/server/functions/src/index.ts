// Reyting sunucu fonksiyonları (Firebase Cloud Functions, 2. nesil)
// Bölge: europe-west1 (Belçika) — Türkiye'ye yakın ve en ucuz fiyat grubu.
//
// İlk online sürüm:
//  - submitSave : oyuncunun kaydını doğrular (hile kontrolü) ve buluta yazar,
//                 zenginler listesindeki yerini günceller.
//  - top100     : her 10 dakikada bir ilk 100'ü TEK belgeye yazar; oyuncular
//                 listeyi tek okumayla görür (100 bin oyuncuda bile ucuz).
//
// Maliyet kuralları: bir oyuncu en fazla dakikada bir kayıt gönderebilir;
// kaydın kendisi oyuncunun kendi belgesinde durur, istemci doğrudan okur.
import { initializeApp } from 'firebase-admin/app';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { cleanName, summarize, validateSave } from './logic';

initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 10, memory: '256MiB' });

const db = getFirestore();
const MIN_SAVE_INTERVAL_MS = 55_000;
const MAX_SAVE_BYTES = 900_000; // Firestore belge sınırı 1 MiB

export const submitSave = onCall({ enforceAppCheck: false }, async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Önce giriş yapmalısın.');
  const raw = req.data?.save;
  if (typeof raw !== 'string' || raw.length < 10) {
    throw new HttpsError('invalid-argument', 'Kayıt eksik.');
  }
  if (raw.length > MAX_SAVE_BYTES) {
    throw new HttpsError('invalid-argument', 'Kayıt çok büyük.');
  }
  let parsed: unknown;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new HttpsError('invalid-argument', 'Kayıt okunamadı.');
  }
  const next = summarize(parsed);
  const ref = db.collection('players').doc(uid);
  const now = Date.now();

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const prevData = snap.exists ? snap.data()! : null;
    const prevAt = prevData?.updatedAt instanceof Timestamp ? prevData.updatedAt.toMillis() : 0;
    if (prevData && now - prevAt < MIN_SAVE_INTERVAL_MS) {
      // çok sık kayıt: sessizce atla (oyun zaten yerelde kaydediyor)
      return { ok: true, skipped: true, worth: prevData.worth ?? 0 };
    }
    const prev = prevData
      ? { day: prevData.day ?? 0, worth: prevData.worth ?? 0, level: prevData.level ?? 0 }
      : null;
    const verdict = validateSave(prev, next, prevAt ? now - prevAt : 0, 0);
    if (!verdict.ok) {
      tx.set(
        ref,
        { rejected: FieldValue.increment(1), lastReject: verdict.reason ?? '', lastRejectAt: Timestamp.now() },
        { merge: true },
      );
      return { ok: false, reason: verdict.reason ?? 'Kayıt reddedildi.' };
    }
    const name = cleanName(String(req.data?.company ?? next.channelName));
    const stamp = Timestamp.fromMillis(now);
    tx.set(
      ref,
      {
        save: raw,
        day: next.day,
        worth: verdict.worth,
        level: next.studioLevel,
        name,
        updatedAt: stamp,
      },
      { merge: true },
    );
    tx.set(db.collection('leaderboard').doc(uid), {
      name,
      worth: verdict.worth,
      level: next.studioLevel,
      day: next.day,
      updatedAt: stamp,
    });
    return { ok: true, worth: verdict.worth };
  });
});

/** İlk 100 listesi: her 10 dakikada tek belgeye yazılır */
export const top100 = onSchedule({ schedule: 'every 10 minutes', timeZone: 'Europe/Istanbul' }, async () => {
  const q = await db.collection('leaderboard').orderBy('worth', 'desc').limit(100).get();
  const rows = q.docs.map((d, i) => ({
    rank: i + 1,
    uid: d.id,
    name: d.get('name') ?? 'Kanal',
    worth: d.get('worth') ?? 0,
    level: d.get('level') ?? 0,
  }));
  const total = (await db.collection('leaderboard').count().get()).data().count;
  await db.collection('meta').doc('top100').set({ rows, total, updatedAt: Timestamp.now() });
});
