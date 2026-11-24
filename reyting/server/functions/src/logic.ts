// Saf (veritabanından bağımsız) oyun kuralları: kolayca test edilir.
import {
  channelPrices, firstNames, lastNames, locationPrices, luxuryPrices, maxNetPerDay,
  platformPrices, roles, salaryFor, stockBase, studioCosts,
} from './gamedata';

/** İstemcinin gönderdiği kayıttan sunucunun okuduğu alanlar */
export interface SaveSummary {
  day: number;
  cash: number;
  studioLevel: number;
  channelName: string;
  debt: number;
  ownedLuxury: string[];
  ownedChannels: string[];
  ownedPlatforms: string[];
  ownedLocations: string[];
  holdings: Record<string, number>;
  stockPrices: Record<string, number>;
  timeScale: number;
  /** Test modu (hızlı zaman) bu kayıtta hiç kullanıldı mı */
  tainted: boolean;
}

export function summarize(save: any): SaveSummary {
  if (!save || typeof save !== 'object') throw new Error('kayıt okunamadı');
  const num = (v: any, d = 0) => (typeof v === 'number' && isFinite(v) ? v : d);
  const loans: any[] = Array.isArray(save.loans) ? save.loans : [];
  return {
    day: Math.floor(num(save.day, 1)),
    cash: num(save.cash),
    studioLevel: Math.max(0, Math.min(studioCosts.length - 1, Math.floor(num(save.studioLevel)))),
    channelName: cleanName(String(save.channelName ?? 'Kanal')),
    debt: loans.reduce((a, l) => a + num(l.installment) * num(l.installmentsLeft), 0),
    ownedLuxury: Array.isArray(save.ownedLuxury) ? save.ownedLuxury.map(String) : [],
    ownedChannels: Array.isArray(save.ownedChannels) ? save.ownedChannels.map(String) : [],
    ownedPlatforms: Array.isArray(save.ownedPlatforms) ? save.ownedPlatforms.map(String) : [],
    ownedLocations: Array.isArray(save.locations) ? save.locations.map(String) : [],
    holdings: typeof save.holdings === 'object' && save.holdings ? save.holdings : {},
    stockPrices: typeof save.stockPrices === 'object' && save.stockPrices ? save.stockPrices : {},
    timeScale: num(save.timeScale, 1),
    tainted: save.tainted === true || num(save.timeScale, 1) > 1,
  };
}

/** Sıralamada görünen ismi temizler */
export function cleanName(s: string): string {
  const t = s.replace(/[\u0000-\u001f<>]/g, '').trim().slice(0, 24);
  return t.length === 0 ? 'Kanal' : t;
}

/**
 * Sunucunun hesapladığı şirket değeri. Hisse fiyatları istemciden gelir ama
 * makul bir tavanla sınırlanır (adil değerin 3 katı).
 */
export function serverWorth(s: SaveSummary): number {
  let v = s.cash - s.debt;
  for (let i = 1; i <= s.studioLevel; i++) v += studioCosts[i] * 0.7;
  for (const id of new Set(s.ownedLuxury)) v += (luxuryPrices[id] ?? 0) * 0.7;
  for (const id of new Set(s.ownedChannels)) v += (channelPrices[id] ?? 0) * 0.65;
  for (const id of new Set(s.ownedPlatforms)) v += (platformPrices[id] ?? 0) * 0.65;
  for (const id of new Set(s.ownedLocations)) v += (locationPrices[id] ?? 0) * 0.5;
  v += portfolioWorth(s);
  return v;
}

export function portfolioWorth(s: SaveSummary): number {
  let v = 0;
  for (const [t, qty] of Object.entries(s.holdings)) {
    const base = stockBase[t];
    if (base === undefined || typeof qty !== 'number' || qty <= 0) continue;
    const cap = base * (1 + s.day / 3000) * 3;
    const p = Math.min(Number(s.stockPrices[t]) || base, cap);
    v += qty * p;
  }
  return v;
}

export interface Verdict {
  ok: boolean;
  reason?: string;
  worth: number;
  /** Kayıt yedeklenir ama bu kariyer sıralamaya hiç giremez */
  unverified?: boolean;
}

/** İlk online kayıtta hesabın açılmasından önce oynanmış olabilecek gün payı (≈24 saat) */
export const OFFLINE_GRACE_DAYS = 1440;

/**
 * Yeni kaydın, bir önceki onaylı kayda göre makul olup olmadığını denetler.
 * - Oyun zamanı gerçek zamandan hızlı akamaz (1 oyun günü = 1 gerçek dakika).
 * - Şirket değeri, seviyenin makul kazancının 3 katından hızlı büyüyemez.
 * - İhalede bloke edilen para kasada durmalıdır.
 */
export function validateSave(
  prev: { day: number; worth: number; level: number } | null,
  next: SaveSummary,
  elapsedMs: number,
  reserved: number,
  accountAgeMs: number = Number.POSITIVE_INFINITY,
): Verdict {
  const worth = serverWorth(next);
  if (next.tainted) {
    return {
      ok: false,
      unverified: true,
      reason: 'Bu kayıtta test modu (hızlı zaman) kullanıldı; sıralamaya giremez.',
      worth,
    };
  }
  if (next.timeScale > 1) {
    return { ok: false, reason: 'Online oyunda zaman hızlandırma kapalıdır.', worth };
  }
  if (next.cash < reserved) {
    return { ok: false, reason: 'İhalede bloke edilen para kasada yok.', worth };
  }
  if (!prev) {
    // İlk kayıt: oyun günü, hesabın yaşından (1 gün = 1 dakika) fazla olamaz.
    const maxDay = (accountAgeMs / 60000) * 1.05 + OFFLINE_GRACE_DAYS;
    if (next.day > maxDay) {
      return {
        ok: false,
        unverified: true,
        reason: 'Bu kariyer çevrimdışı ilerlemiş ve doğrulanamıyor; sıralamaya yeni kariyerle girebilirsin.',
        worth,
      };
    }
    // İlk kayıt: yeni oyuncu ya da eski çevrimdışı ilerlemesi.
    const maxDays = 3 * 24 * 60; // en fazla 3 günlük oyun (başlangıç toleransı)
    const cap = 50e6 + maxNetPerDay[next.studioLevel] * 3 * Math.min(next.day, maxDays);
    if (worth > cap) return { ok: false, reason: 'Başlangıç kaydı olağan dışı.', worth };
    return { ok: true, worth };
  }
  const dayDelta = next.day - prev.day;
  if (dayDelta < 0) return { ok: false, reason: 'Kayıt geriye gidemez.', worth };
  const elapsedMin = elapsedMs / 60000;
  if (dayDelta > elapsedMin * 1.05 + 2) {
    return { ok: false, reason: 'Oyun zamanı gerçek zamandan hızlı ilerlemiş.', worth };
  }
  const level = Math.max(prev.level, next.studioLevel);
  const allowance =
    maxNetPerDay[level] * 3 * (dayDelta + 1) + // normal kazanç
    portfolioWorth(next) * 0.5 + // borsa dalgalanması
    5e6; // küçük tolerans
  if (worth - prev.worth > allowance) {
    return { ok: false, reason: 'Servet olağan dışı hızlı arttı.', worth };
  }
  return { ok: true, worth };
}

// ------------------------------------------------------------------
// Canlı transfer ihalesi
// ------------------------------------------------------------------
export interface AuctionStaff {
  name: string;
  role: string;
  skill: number;
  salary: number;
}

export interface Auction {
  staff: AuctionStaff;
  startPrice: number;
  highBid: number;
  highBidder: string | null;
  highBidderName: string | null;
  endsAt: number; // ms
  status: 'open' | 'settled';
  bids: number;
}

/** Deterministik rastgele (test edilebilir) */
export function rng(seed: number): () => number {
  let s = seed >>> 0 || 1;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

export function makeAuction(r: () => number, now: number, durationMs = 30 * 60000): Auction {
  const skill = 85 + Math.floor(r() * 15);
  const name = `${firstNames[Math.floor(r() * firstNames.length)]} ${lastNames[Math.floor(r() * lastNames.length)]}`;
  const salary = Math.round(salaryFor(skill) / 100) * 100;
  return {
    staff: { name, role: roles[Math.floor(r() * roles.length)], skill, salary },
    startPrice: salary * 20,
    highBid: 0,
    highBidder: null,
    highBidderName: null,
    endsAt: now + durationMs,
    status: 'open',
    bids: 0,
  };
}

export function minNextBid(a: Auction): number {
  if (a.highBid <= 0) return a.startPrice;
  return Math.ceil(a.highBid + Math.max(a.highBid * 0.05, 10000));
}

export interface BidResult {
  ok: boolean;
  error?: string;
  auction?: Auction;
  refund?: { uid: string; amount: number };
}

/**
 * Teklif kuralları: süre dolmamış olmalı, en az minimum artış kadar yüksek
 * olmalı, oyuncunun bloke edilmemiş parası yetmeli. Önceki liderin teklifi
 * iade edilir. Son 30 saniyede gelen teklif süreyi 30 saniye uzatır.
 */
export function applyBid(
  a: Auction,
  uid: string,
  name: string,
  amount: number,
  available: number,
  now: number,
): BidResult {
  if (a.status !== 'open' || now >= a.endsAt) return { ok: false, error: 'İhale sona erdi.' };
  if (a.highBidder === uid) return { ok: false, error: 'Zaten en yüksek teklif senin.' };
  if (!(amount >= minNextBid(a))) {
    return { ok: false, error: `En az ${minNextBid(a)} ₺ teklif vermelisin.` };
  }
  if (amount > available) return { ok: false, error: 'Kasanda bu kadar serbest para yok.' };
  const refund = a.highBidder ? { uid: a.highBidder, amount: a.highBid } : undefined;
  const auction: Auction = {
    ...a,
    highBid: amount,
    highBidder: uid,
    highBidderName: name,
    bids: a.bids + 1,
    endsAt: a.endsAt - now < 30000 ? now + 30000 : a.endsAt,
  };
  return { ok: true, auction, refund };
}
