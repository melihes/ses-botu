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
import { createHash } from 'node:crypto';
import { GoogleAuth } from 'google-auth-library';
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { setGlobalOptions } from 'firebase-functions/v2';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { maxNetPerDay } from './gamedata';
import { cleanName, serverWorth, summarize, validateSave, type Verdict } from './logic';

export { ackGrants, adminAction, adminList, adminResetAll, adminDeleteAll, adminPlayer, createTransferCode, redeemTransferCode } from './admin';

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

  // ilk kayıtta hesabın yaşı gerekir (hızlandırıp sonra online olmayı engeller)
  let accountAgeMs = Number.POSITIVE_INFINITY;
  let email: string | null = null;
  try {
    const u = await getAuth().getUser(uid);
    accountAgeMs = now - new Date(u.metadata.creationTime).getTime();
    email = u.email ?? null;
  } catch (e: any) {
    // hesap silinmiş: oyun yeni misafir hesap açsın
    if (e?.code === 'auth/user-not-found') throw new HttpsError('unauthenticated', 'Hesap silinmiş.');
    accountAgeMs = 0;
  }
  // yalnız yönetici panelinde görünen özet (sıralamayı etkilemez)
  const st = req.data?.stats ?? {};
  const n = (v: unknown) => (typeof v === 'number' && Number.isFinite(v) ? v : 0);
  const stats = { prestige: n(st.prestige), shows: n(st.shows), staff: n(st.staff), films: n(st.films),
    netPerDay: n(st.netPerDay) };
  const frame = Math.max(0, Math.min(99, Math.floor(n(req.data?.frame))));
  const info = { cash: next.cash, diamonds: next.diamonds, email, stats, frame };

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const prevData = snap.exists ? snap.data()! : null;
    const prevAt = prevData?.updatedAt instanceof Timestamp ? prevData.updatedAt.toMillis() : 0;
    if (prevData && now - prevAt < MIN_SAVE_INTERVAL_MS) {
      // çok sık kayıt: sessizce atla (oyun zaten yerelde kaydediyor)
      return { ok: true, skipped: true, worth: prevData.worth ?? 0 };
    }
    let prev = prevData && prevData.day != null
      ? { day: prevData.day ?? 0, worth: prevData.worth ?? 0, level: prevData.level ?? 0 }
      : null;
    let verified = prevData?.verified !== false;
    const rebase = prevData?.adminRebase === true && prevData?.banned !== true;
    if (rebase) {
      prev = null;
      accountAgeMs = Number.POSITIVE_INFINITY;
    }
    // Yeni kariyer: oyuncu oyunu sıfırladı (gün başa döndü) → temiz sayfa
    // (sıralamadan atılan hesap yeni kariyerle geri giremez)
    if (prev && next.day < prev.day && next.day <= 1440 && prevData?.banned !== true) {
      prev = null;
      verified = true;
      accountAgeMs = Number.POSITIVE_INFINITY; // yeni kariyer şimdi başlıyor
    }
    const name = cleanName(String(req.data?.company ?? next.channelName));
    const stamp = Timestamp.fromMillis(now);
    const lbRef = db.collection('leaderboard').doc(uid);

    const backupOnly = (reason: string) => {
      // kayıt yedeklenir (ilerleme kaybolmaz) ama sıralamaya girmez
      tx.set(ref, { save: raw, day: next.day, worth: 0, level: next.studioLevel, name, ...info,
        verified: false, unverifiedReason: reason, updatedAt: stamp,
        ...(prevData ? {} : { createdAt: stamp }) }, { merge: true });
      tx.delete(lbRef);
      return { ok: false, unverified: true, reason };
    };

    if (!verified) {
      return backupOnly(prevData?.unverifiedReason ?? 'Bu kariyer doğrulanamadı.');
    }
    const bonus = Number(prevData?.bonusAllowance ?? 0);
    // yönetici düzeltmesinden sonraki ilk kayıt: yeni başlangıç noktası kabul edilir
    const verdict: Verdict = rebase && !next.tainted && next.timeScale <= 1
      ? { ok: true, worth: serverWorth(next) }
      : validateSave(prev, next, prevAt ? now - prevAt : 0, 0, prev ? Number.POSITIVE_INFINITY : accountAgeMs, bonus);
    if (verdict.unverified) return backupOnly(verdict.reason ?? 'Doğrulanamadı.');
    if (!verdict.ok) {
      tx.set(
        ref,
        { rejected: FieldValue.increment(1), lastReject: verdict.reason ?? '', lastRejectAt: Timestamp.now() },
        { merge: true },
      );
      return { ok: false, reason: verdict.reason ?? 'Kayıt reddedildi.' };
    }
    tx.set(
      ref,
      { save: raw, day: next.day, worth: verdict.worth, level: next.studioLevel, name, ...info,
        verified: true, updatedAt: stamp, bonusAllowance: 0,
        // yönetici işlemi daha oyuna ulaşmadıysa bir sonraki kayıtta da denetim atlanır
        adminRebase: rebase && next.lastGrantSeq >= 0 && next.lastGrantSeq < Number(prevData?.rebaseSeq ?? 0),
        ...(prevData ? {} : { createdAt: stamp }) },
      { merge: true },
    );
    tx.set(lbRef, { name, worth: verdict.worth, level: next.studioLevel, day: next.day, frame, updatedAt: stamp });
    return { ok: true, worth: verdict.worth };
  });
});

/**
 * Satın almayı Google Play'e sorar. Geçerliyse aynı satın alma bir daha
 * kullanılamasın diye kaydeder ve parayla alınan oyun parası için sıralama
 * kontrolüne izin payı ekler.
 */
const PACKAGE = 'com.esmgames.reyting';
const MONEY_MULT: Record<string, number> = { para_kucuk: 5, para_orta: 20, para_buyuk: 60 };
const KNOWN = new Set(['elmas_80', 'elmas_450', 'elmas_1000', 'elmas_2500', 'reklamsiz', 'vip_paket',
  ...Object.keys(MONEY_MULT)]);
const playAuth = new GoogleAuth({ scopes: ['https://www.googleapis.com/auth/androidpublisher'] });

export const verifyPurchase = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Önce giriş yapmalısın.');
  const productId = String(req.data?.productId ?? '');
  const token = String(req.data?.token ?? '');
  if (!KNOWN.has(productId) || token.length < 10 || token.length > 4000) {
    throw new HttpsError('invalid-argument', 'Geçersiz satın alma.');
  }
  const client = await playAuth.getClient();
  const url = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}` +
    `/purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(token)}`;
  let purchase: any;
  try {
    purchase = (await client.request({ url })).data;
  } catch (e: any) {
    const status = e?.response?.status;
    if (status === 400 || status === 404 || status === 410) {
      throw new HttpsError('permission-denied', 'Satın alma bulunamadı.');
    }
    throw new HttpsError('unavailable', 'Google Play şu an doğrulanamadı.');
  }
  // purchaseState: 0 satın alındı, 1 iptal, 2 beklemede
  if (purchase?.purchaseState !== 0) {
    throw new HttpsError('permission-denied', 'Satın alma tamamlanmamış.');
  }
  const key = createHash('sha256').update(token).digest('hex');
  const pRef = db.collection('purchases').doc(key);
  const playerRef = db.collection('players').doc(uid);
  const playerSnap = await playerRef.get();
  const level = Math.max(0, Math.min(11, Number(playerSnap.get('level') ?? 0)));
  const mult = MONEY_MULT[productId] ?? 0;
  // para paketi: istemcinin söylediği tutar, seviyenin makul kazancıyla sınırlı
  const cash = mult > 0 ? Math.min(Math.max(0, Number(req.data?.cash ?? 0)), mult * maxNetPerDay[level] * 1.5) : 0;
  return db.runTransaction(async (tx) => {
    const prev = await tx.get(pRef);
    if (prev.exists) {
      // aynı satın alma: başka hesap kullanamaz, aynı hesap için tekrar verilmez
      // kalıcı haklar (reklamsız, VIP) aynı Play hesabıyla yeni oyun hesabına da geri yüklenebilir
      const permanent = productId === 'reklamsiz' || productId === 'vip_paket';
      if (prev.get('uid') !== uid && !permanent) {
        throw new HttpsError('permission-denied', 'Bu satın alma başka hesaba ait.');
      }
      return { ok: true, already: true };
    }
    tx.set(pRef, { uid, productId, orderId: purchase.orderId ?? null, cash, at: Timestamp.now() });
    if (cash > 0) tx.set(playerRef, { bonusAllowance: FieldValue.increment(cash) }, { merge: true });
    return { ok: true };
  });
});

/**
 * Hesabı ve tüm sunucu verisini kalıcı olarak siler (Google Play zorunluluğu).
 * Bulut kaydı, sıralama kaydı ve giriş hesabı silinir.
 */
export const deleteAccount = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Önce giriş yapmalısın.');
  const batch = db.batch();
  batch.delete(db.collection('players').doc(uid));
  batch.delete(db.collection('leaderboard').doc(uid));
  batch.delete(db.collection('grants').doc(uid));
  await batch.commit();
  try {
    await getAuth().deleteUser(uid);
  } catch (e) {
    // kullanıcı zaten yoksa sorun değil
  }
  return { ok: true };
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
    frame: d.get('frame') ?? 0,
  }));
  const total = (await db.collection('leaderboard').count().get()).data().count;
  await db.collection('meta').doc('top100').set({ rows, total, updatedAt: Timestamp.now() });
});
