// Oyuncular arası pazar: yetenek (oyuncu/sunucu…) al-sat, teklif ve açık artırma.
// Saf fonksiyonlar: Firestore'da her işlem bir transaction içinde çalışacak.
// Kural: para asla yoktan var olmaz. Teklif verilen para "bloke" edilir;
// teklif reddedilir/geçerse/aşılırsa aynen iade edilir. Satıştan %5 komisyon kesilir.

export const FEE = 0.05;
export const OFFER_TTL_MS = 3 * 24 * 3600 * 1000;
export const MAX_OPEN_OFFERS = 20;
export const MAX_LISTINGS = 10;

export interface Talent {
  id: string;
  owner: string;
  skill: number;
  value: number; // istemcinin değil sunucunun hesapladığı değer
}

export interface Wallet {
  cash: number; // serbest para
  blocked: number; // tekliflerde bekleyen para
}

export interface Listing {
  id: string;
  talentId: string;
  seller: string;
  ask: number;
  createdAt: number;
}

export interface Offer {
  id: string;
  listingId: string;
  buyer: string;
  amount: number;
  expiresAt: number;
}

export interface Market {
  wallets: Map<string, Wallet>;
  talents: Map<string, Talent>;
  listings: Map<string, Listing>;
  offers: Map<string, Offer>;
  feesCollected: number;
  seq: number;
}

export type Res = { ok: true } | { ok: false; error: string };
const fail = (error: string): Res => ({ ok: false, error });
const OK: Res = { ok: true };

export function newMarket(): Market {
  return { wallets: new Map(), talents: new Map(), listings: new Map(), offers: new Map(), feesCollected: 0, seq: 0 };
}

const valid = (n: number) => typeof n === 'number' && Number.isFinite(n) && n > 0;

function wallet(m: Market, uid: string): Wallet | undefined {
  return m.wallets.get(uid);
}

/** İlan fiyatı makul aralıkta olmalı (kara para / hile transferini engeller). */
export function priceBand(t: Talent): [number, number] {
  return [Math.floor(t.value * 0.25), Math.ceil(t.value * 4)];
}

export function listTalent(m: Market, uid: string, talentId: string, ask: number, now: number): Res {
  const t = m.talents.get(talentId);
  if (!t) return fail('Böyle bir yetenek yok.');
  if (t.owner !== uid) return fail('Bu yetenek senin değil.');
  if (!valid(ask)) return fail('Geçersiz fiyat.');
  const [lo, hi] = priceBand(t);
  if (ask < lo || ask > hi) return fail(`Fiyat ${lo}–${hi} arasında olmalı.`);
  for (const l of m.listings.values()) {
    if (l.talentId === talentId) return fail('Zaten satışta.');
  }
  let mine = 0;
  for (const l of m.listings.values()) if (l.seller === uid) mine++;
  if (mine >= MAX_LISTINGS) return fail(`En fazla ${MAX_LISTINGS} ilan açabilirsin.`);
  const id = `L${++m.seq}`;
  m.listings.set(id, { id, talentId, seller: uid, ask: Math.round(ask), createdAt: now });
  t.owner = `escrow:${id}`; // satış süresince kimse kullanamaz
  return OK;
}

function refundOffer(m: Market, o: Offer) {
  const w = wallet(m, o.buyer);
  if (w) {
    w.blocked -= o.amount;
    w.cash += o.amount;
  }
  m.offers.delete(o.id);
}

function closeListing(m: Market, l: Listing, newOwner: string) {
  for (const o of [...m.offers.values()]) if (o.listingId === l.id) refundOffer(m, o);
  const t = m.talents.get(l.talentId);
  if (t) t.owner = newOwner;
  m.listings.delete(l.id);
}

export function cancelListing(m: Market, uid: string, listingId: string): Res {
  const l = m.listings.get(listingId);
  if (!l) return fail('İlan bulunamadı.');
  if (l.seller !== uid) return fail('Bu ilan senin değil.');
  closeListing(m, l, uid);
  return OK;
}

function settle(m: Market, l: Listing, buyer: string, price: number, fromBlocked: boolean) {
  const bw = wallet(m, buyer)!;
  const sw = wallet(m, l.seller)!;
  if (fromBlocked) bw.blocked -= price;
  else bw.cash -= price;
  const fee = Math.round(price * FEE);
  sw.cash += price - fee;
  m.feesCollected += fee;
  closeListing(m, l, buyer);
}

/** Hemen al: ilan fiyatı ödenir. */
export function buyNow(m: Market, uid: string, listingId: string, expectedAsk: number): Res {
  const l = m.listings.get(listingId);
  if (!l) return fail('İlan artık yok (satılmış ya da kaldırılmış).');
  if (l.seller === uid) return fail('Kendi ilanını alamazsın.');
  // fiyat ekranda gördükten sonra değiştiyse alma
  if (l.ask !== expectedAsk) return fail('Fiyat değişti, tekrar bak.');
  const w = wallet(m, uid);
  if (!w) return fail('Hesap bulunamadı.');
  if (w.cash < l.ask) return fail('Serbest paran yetmiyor.');
  settle(m, l, uid, l.ask, false);
  return OK;
}

/** Pazarlık teklifi: para bloke edilir. */
export function makeOffer(m: Market, uid: string, listingId: string, amount: number, now: number): Res {
  const l = m.listings.get(listingId);
  if (!l) return fail('İlan artık yok.');
  if (l.seller === uid) return fail('Kendi ilanına teklif veremezsin.');
  if (!valid(amount)) return fail('Geçersiz teklif.');
  amount = Math.round(amount);
  if (amount >= l.ask) return fail('Bu fiyata zaten hemen alabilirsin.');
  const t = m.talents.get(l.talentId)!;
  if (amount < priceBand(t)[0]) return fail('Teklif çok düşük.');
  let open = 0;
  for (const o of m.offers.values()) {
    if (o.buyer === uid) {
      open++;
      if (o.listingId === listingId) return fail('Bu ilana zaten teklifin var.');
    }
  }
  if (open >= MAX_OPEN_OFFERS) return fail('Çok fazla açık teklifin var.');
  const w = wallet(m, uid);
  if (!w) return fail('Hesap bulunamadı.');
  if (w.cash < amount) return fail('Serbest paran yetmiyor.');
  w.cash -= amount;
  w.blocked += amount;
  const id = `O${++m.seq}`;
  m.offers.set(id, { id, listingId, buyer: uid, amount, expiresAt: now + OFFER_TTL_MS });
  return OK;
}

export function withdrawOffer(m: Market, uid: string, offerId: string): Res {
  const o = m.offers.get(offerId);
  if (!o) return fail('Teklif bulunamadı.');
  if (o.buyer !== uid) return fail('Bu teklif senin değil.');
  refundOffer(m, o);
  return OK;
}

export function acceptOffer(m: Market, uid: string, offerId: string, now: number): Res {
  const o = m.offers.get(offerId);
  if (!o) return fail('Teklif geri çekilmiş.');
  if (now >= o.expiresAt) {
    refundOffer(m, o);
    return fail('Teklifin süresi dolmuş.');
  }
  const l = m.listings.get(o.listingId);
  if (!l) return fail('İlan yok.');
  if (l.seller !== uid) return fail('Bu ilan senin değil.');
  m.offers.delete(o.id);
  settle(m, l, o.buyer, o.amount, true);
  return OK;
}

/** Süresi dolan teklifleri iade eder (zamanlanmış görev). */
export function expireOffers(m: Market, now: number): number {
  let n = 0;
  for (const o of [...m.offers.values()]) {
    if (now >= o.expiresAt) {
      refundOffer(m, o);
      n++;
    }
  }
  return n;
}

/** Tutarlılık kontrolleri: hata listesi (boşsa her şey yolunda). */
export function audit(m: Market, startingMoney: number): string[] {
  const e: string[] = [];
  let total = m.feesCollected;
  const blockedBy = new Map<string, number>();
  for (const o of m.offers.values()) {
    blockedBy.set(o.buyer, (blockedBy.get(o.buyer) ?? 0) + o.amount);
    if (!m.listings.has(o.listingId)) e.push(`sahipsiz teklif ${o.id}`);
  }
  for (const [uid, w] of m.wallets) {
    total += w.cash + w.blocked;
    if (w.cash < 0) e.push(`eksi para ${uid}`);
    if (w.blocked < 0) e.push(`eksi bloke ${uid}`);
    if (w.blocked !== (blockedBy.get(uid) ?? 0)) e.push(`bloke uyuşmuyor ${uid}`);
  }
  if (total !== startingMoney) e.push(`para korunmadı: ${total} != ${startingMoney}`);
  const listed = new Set<string>();
  for (const l of m.listings.values()) {
    if (listed.has(l.talentId)) e.push(`çift ilan ${l.talentId}`);
    listed.add(l.talentId);
    const t = m.talents.get(l.talentId);
    if (!t || t.owner !== `escrow:${l.id}`) e.push(`emanet hatası ${l.id}`);
  }
  for (const t of m.talents.values()) {
    if (t.owner.startsWith('escrow:') && !m.listings.has(t.owner.slice(7))) e.push(`kayıp yetenek ${t.id}`);
  }
  return e;
}
