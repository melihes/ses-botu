// Yönetici (admin) işlemleri ve hesap taşıma.
//
// Yetki: Firestore'daki config/admins belgesinin "emails" listesindeki,
// e-postası Google tarafından doğrulanmış hesaplar. Bu belgeyi yalnızca
// Firebase konsolundan proje sahibi yazabilir (istemci kuralları kapalı).
//
// Oyuncuya yapılan her değişiklik grants/{uid} belgesine "işlem" olarak
// yazılır; oyun bunu anında dinler ve uygular. Oyuncunun bir sonraki
// kaydında hile denetimi bu değişiklik için atlanır (adminRebase), böylece
// yöneticinin verdiği para yüzünden kimse sıralamadan düşmez.
import { randomInt } from 'node:crypto';
import { getAuth } from 'firebase-admin/auth';
import { FieldValue, getFirestore, Timestamp } from 'firebase-admin/firestore';
import { HttpsError, onCall as rawOnCall, type CallableRequest } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

/** Beklenmeyen hatalar "internal" yerine okunur mesajla dönsün */
function onCall<T>(handler: (req: CallableRequest) => Promise<T>) {
  return rawOnCall(async (req) => {
    try {
      return await handler(req);
    } catch (e: any) {
      if (e instanceof HttpsError) throw e;
      logger.error('admin hata', e);
      throw new HttpsError('internal', `Sunucu hatası: ${String(e?.message ?? e).slice(0, 300)}`);
    }
  });
}

// index.ts initializeApp() çağırdıktan sonra kullanılır
const db = () => getFirestore();

let adminCache: { emails: string[]; at: number } | null = null;

async function adminEmails(): Promise<string[]> {
  if (adminCache && Date.now() - adminCache.at < 60_000) return adminCache.emails;
  const snap = await db().collection('config').doc('admins').get();
  // "emails" dizi (array) ya da virgüllü metin olabilir; "email" alanı da kabul edilir
  const raw: unknown = snap.get('emails') ?? snap.get('email') ?? [];
  const list = Array.isArray(raw) ? raw : String(raw).split(/[,;\s]+/);
  const emails = list.map((e) => String(e).trim().toLowerCase()).filter((e) => e.includes('@'));
  adminCache = { emails, at: Date.now() };
  return emails;
}

export async function requireAdmin(req: CallableRequest): Promise<string> {
  const t = req.auth?.token;
  const email = String(t?.email ?? '').toLowerCase();
  if (!req.auth || !email || t?.email_verified !== true) {
    throw new HttpsError('permission-denied', 'Yönetici girişi gerekli.');
  }
  if (!(await adminEmails()).includes(email)) {
    throw new HttpsError('permission-denied', 'Bu hesap yönetici değil.');
  }
  return email;
}

function cleanUid(v: unknown): string {
  const s = String(v ?? '');
  if (!/^[A-Za-z0-9_-]{6,128}$/.test(s)) throw new HttpsError('invalid-argument', 'Geçersiz oyuncu.');
  return s;
}

function num(v: unknown, min: number, max: number): number {
  const n = Number(v);
  if (!Number.isFinite(n)) throw new HttpsError('invalid-argument', 'Geçersiz sayı.');
  return Math.max(min, Math.min(max, n));
}

/** Oyuncuya bir işlem gönder (oyun anında uygular) */
async function pushGrant(uid: string, op: Record<string, unknown>, by: string): Promise<number> {
  const ref = db().collection('grants').doc(uid);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const seq = Number(snap.get('seq') ?? 0) + 1;
    const ops = ((snap.get('ops') as any[]) ?? []).slice(-20);
    ops.push({ ...op, seq, by, at: Date.now() });
    tx.set(ref, { seq, ops, updatedAt: Timestamp.now() });
    // bir sonraki kayıtta hile denetimi bu değişiklik için atlanır
    tx.set(db().collection('players').doc(uid), { adminRebase: true }, { merge: true });
    return seq;
  });
}

const SUMMARY_FIELDS = ['name', 'email', 'day', 'worth', 'level', 'cash', 'diamonds', 'stats', 'verified',
  'unverifiedReason', 'updatedAt', 'createdAt', 'rejected', 'lastReject', 'banned', 'frame'];

function rowOf(id: string, d: FirebaseFirestore.DocumentData) {
  const ts = (v: any) => (v instanceof Timestamp ? v.toMillis() : null);
  return {
    uid: id,
    name: d.name ?? 'Kanal',
    email: d.email ?? null,
    day: d.day ?? 0,
    worth: d.worth ?? 0,
    level: d.level ?? 0,
    cash: d.cash ?? null,
    diamonds: d.diamonds ?? null,
    stats: d.stats ?? null,
    verified: d.verified !== false,
    unverifiedReason: d.unverifiedReason ?? null,
    banned: d.banned === true,
    rejected: d.rejected ?? 0,
    lastReject: d.lastReject ?? null,
    updatedAt: ts(d.updatedAt),
    createdAt: ts(d.createdAt),
  };
}

/** Oyuncu listesi (kayıt verisi olmadan, hafif) */
export const adminList = onCall(async (req) => {
  await requireAdmin(req);
  const order = ['worth', 'updatedAt', 'cash', 'day'].includes(String(req.data?.order))
    ? String(req.data.order)
    : 'updatedAt';
  const limit = num(req.data?.limit ?? 200, 1, 500);
  const q = await db().collection('players').orderBy(order, 'desc').limit(limit).select(...SUMMARY_FIELDS).get();
  const total = (await db().collection('players').count().get()).data().count;
  return { total, rows: q.docs.map((d) => rowOf(d.id, d.data())) };
});

/** Tek oyuncunun ayrıntısı: giriş bilgisi, kaydın özeti, bekleyen işlemler */
export const adminPlayer = onCall(async (req) => {
  await requireAdmin(req);
  const uid = cleanUid(req.data?.uid);
  const snap = await db().collection('players').doc(uid).get();
  if (!snap.exists) throw new HttpsError('not-found', 'Oyuncu bulunamadı.');
  const d = snap.data()!;
  let auth: any = null;
  try {
    const u = await getAuth().getUser(uid);
    auth = {
      email: u.email ?? null,
      anonymous: u.providerData.length === 0,
      providers: u.providerData.map((p) => p.providerId),
      created: u.metadata.creationTime,
      lastSignIn: u.metadata.lastSignInTime,
      disabled: u.disabled,
    };
  } catch {
    auth = null;
  }
  let save: any = null;
  try {
    const s = JSON.parse(String(d.save ?? '{}'));
    save = {
      day: s.day,
      cash: s.cash,
      diamonds: s.diamonds,
      studioLevel: s.studioLevel,
      channelName: s.channelName,
      companyName: s.companyName,
      vip: s.vip,
      noAds: s.noAds,
      staff: Array.isArray(s.staff) ? s.staff.length : 0,
      shows: Array.isArray(s.shows) ? s.shows.length : 0,
      films: Array.isArray(s.films) ? s.films.length : 0,
      loans: Array.isArray(s.loans) ? s.loans.length : 0,
      ownedLuxury: Array.isArray(s.ownedLuxury) ? s.ownedLuxury.length : 0,
    };
  } catch {
    save = null;
  }
  const g = await db().collection('grants').doc(uid).get();
  return { row: rowOf(uid, d), auth, save, grants: g.exists ? g.get('ops') ?? [] : [], saveBytes: String(d.save ?? '').length };
});

/**
 * Yönetici işlemi:
 *  give   : para/elmas ekle (eksi de olabilir)
 *  set    : para / elmas / stüdyo seviyesini tam değere ayarla
 *  reset  : hesabı sıfırla (yeni kariyer)
 *  vip    : VIP/Reklamsız ver ya da al
 *  verify : "doğrulanamadı" damgasını kaldır (sıralamaya geri al)
 *  ban    : sıralamadan çıkar (hile yapanlar için)
 *  message: oyuncuya mesaj gönder
 *  transfer: başka bir oyuncu hesabının kaydını bu hesaba taşı
 */
export const adminAction = onCall(async (req) => {
  const by = await requireAdmin(req);
  const uid = cleanUid(req.data?.uid);
  const action = String(req.data?.action ?? '');
  const pRef = db().collection('players').doc(uid);
  const lbRef = db().collection('leaderboard').doc(uid);
  switch (action) {
    case 'give': {
      const cash = num(req.data?.cash ?? 0, -1e16, 1e16);
      const diamonds = Math.round(num(req.data?.diamonds ?? 0, -1e6, 1e6));
      const seq = await pushGrant(uid, { type: 'give', cash, diamonds }, by);
      return { ok: true, seq };
    }
    case 'set': {
      const op: Record<string, unknown> = { type: 'set' };
      if (req.data?.cash != null) op.cash = num(req.data.cash, -1e16, 1e16);
      if (req.data?.diamonds != null) op.diamonds = Math.round(num(req.data.diamonds, 0, 1e7));
      if (req.data?.studioLevel != null) op.studioLevel = Math.round(num(req.data.studioLevel, 0, 11));
      const seq = await pushGrant(uid, op, by);
      return { ok: true, seq };
    }
    case 'reset': {
      const seq = await pushGrant(uid, { type: 'reset' }, by);
      await lbRef.delete();
      await pRef.set({ verified: true, unverifiedReason: FieldValue.delete(), banned: false }, { merge: true });
      return { ok: true, seq };
    }
    case 'vip': {
      const seq = await pushGrant(uid, { type: 'vip', vip: req.data?.vip === true, noAds: req.data?.noAds === true }, by);
      return { ok: true, seq };
    }
    case 'verify': {
      await pRef.set({ verified: true, unverifiedReason: FieldValue.delete(), banned: false, adminRebase: true },
        { merge: true });
      return { ok: true };
    }
    case 'ban': {
      const reason = String(req.data?.reason ?? 'Yönetici kararıyla sıralamadan çıkarıldı.').slice(0, 200);
      await pRef.set({ verified: false, unverifiedReason: reason, banned: true }, { merge: true });
      await lbRef.delete();
      return { ok: true };
    }
    case 'message': {
      const text = String(req.data?.text ?? '').slice(0, 300);
      if (!text) throw new HttpsError('invalid-argument', 'Mesaj boş.');
      const seq = await pushGrant(uid, { type: 'message', text }, by);
      return { ok: true, seq };
    }
    case 'transfer': {
      const from = cleanUid(req.data?.from);
      await copySave(from, uid);
      const seq = await pushGrant(uid, { type: 'load' }, by);
      return { ok: true, seq };
    }
    default:
      throw new HttpsError('invalid-argument', 'Bilinmeyen işlem.');
  }
});

/** Bir hesabın kaydını başka hesaba kopyalar (eski hesap sıralamadan çıkar) */
async function copySave(from: string, to: string): Promise<string> {
  if (from === to) throw new HttpsError('invalid-argument', 'Aynı hesap.');
  const src = await db().collection('players').doc(from).get();
  const save = src.get('save');
  if (typeof save !== 'string' || save.length < 10) throw new HttpsError('not-found', 'Taşınacak kayıt yok.');
  const batch = db().batch();
  batch.set(db().collection('players').doc(to), {
    save,
    day: src.get('day') ?? 0,
    worth: src.get('worth') ?? 0,
    level: src.get('level') ?? 0,
    name: src.get('name') ?? 'Kanal',
    verified: src.get('verified') !== false,
    unverifiedReason: src.get('unverifiedReason') ?? FieldValue.delete(),
    adminRebase: true,
    movedFrom: from,
    updatedAt: Timestamp.fromMillis(0), // bir sonraki kayıt bekletilmesin
  }, { merge: true });
  batch.set(db().collection('players').doc(from), { movedTo: to, verified: false, unverifiedReason: 'Hesap taşındı.' },
    { merge: true });
  batch.delete(db().collection('leaderboard').doc(from));
  await batch.commit();
  return save;
}

// ------------------------------------------------------------------
// Oyuncunun kendi hesabını taşıması (telefon değişince)
// ------------------------------------------------------------------
const CODE_CHARS = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/** Eski telefonda: 24 saat geçerli taşıma kodu üretir */
export const createTransferCode = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Önce giriş yapmalısın.');
  const p = await db().collection('players').doc(uid).get();
  if (!p.exists || typeof p.get('save') !== 'string') {
    throw new HttpsError('failed-precondition', 'Önce oyunun buluta kaydedilmesi gerekiyor (birkaç dakika oyna).');
  }
  let code = '';
  for (let i = 0; i < 8; i++) code += CODE_CHARS[randomInt(CODE_CHARS.length)];
  await db().collection('transfers').doc(code).set({ uid, expires: Timestamp.fromMillis(Date.now() + 24 * 3600e3) });
  return { code: `${code.slice(0, 4)}-${code.slice(4)}` };
});

/** Yeni telefonda: kodu girince eski hesabın kaydı bu hesaba gelir */
export const redeemTransferCode = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Önce giriş yapmalısın.');
  const code = String(req.data?.code ?? '').toUpperCase().replace(/[^A-Z0-9]/g, '');
  if (code.length !== 8) throw new HttpsError('invalid-argument', 'Kod 8 karakter olmalı.');
  const ref = db().collection('transfers').doc(code);
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError('not-found', 'Kod bulunamadı.');
  const exp = snap.get('expires');
  if (exp instanceof Timestamp && exp.toMillis() < Date.now()) {
    await ref.delete();
    throw new HttpsError('deadline-exceeded', 'Kodun süresi dolmuş, yenisini al.');
  }
  const from = String(snap.get('uid'));
  if (from === uid) throw new HttpsError('failed-precondition', 'Bu kod zaten bu hesaba ait.');
  const save = await copySave(from, uid);
  await ref.delete();
  return { ok: true, save };
});

/** Oyun, uyguladığı işlemleri onaylar (listeden silinir) */
export const ackGrants = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Önce giriş yapmalısın.');
  const upTo = Math.floor(num(req.data?.seq ?? 0, 0, 1e9));
  const ref = db().collection('grants').doc(uid);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return;
    const ops = ((snap.get('ops') as any[]) ?? []).filter((o) => Number(o.seq) > upTo);
    tx.set(ref, { ops }, { merge: true });
  });
  return { ok: true };
});
