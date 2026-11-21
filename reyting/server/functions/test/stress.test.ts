// Stres testi: 10.000 sanal oyuncu aynı anda pazarda al-sat, teklif ve açık artırma yapar.
// Oyuncular "eski ekran" görüntüsüne bakarak karar verir (gerçekte olduğu gibi):
// biri ilanı satın alırken başkası da aynı ilana basabilir, fiyat değişmiş olabilir…
// Sunucu kuralları her seferinde yeniden doğrulamalı; para yoktan var olmamalı.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { applyBid, makeAuction, minNextBid, rng, Auction } from '../src/logic';
import {
  acceptOffer, audit, buyNow, cancelListing, expireOffers, listTalent, makeOffer,
  newMarket, withdrawOffer, priceBand, Market,
} from '../src/trade';

const PLAYERS = Number(process.env.PLAYERS ?? 10000);
const OPS = Number(process.env.OPS ?? 600000);

interface Snap { listings: { id: string; ask: number; seller: string }[]; offers: { id: string; buyer: string; listingId: string }[] }

function snapshot(m: Market): Snap {
  return {
    listings: [...m.listings.values()].map((l) => ({ id: l.id, ask: l.ask, seller: l.seller })),
    offers: [...m.offers.values()].map((o) => ({ id: o.id, buyer: o.buyer, listingId: o.listingId })),
  };
}

test(`${PLAYERS} oyuncu, ${OPS} eşzamanlı pazar işlemi`, () => {
  const r = rng(42);
  const m = newMarket();
  let money = 0;
  const uids: string[] = [];
  const talentsOf = new Map<string, string[]>();
  for (let i = 0; i < PLAYERS; i++) {
    const uid = `u${i}`;
    uids.push(uid);
    // zengin-fakir karışık: bazıları çok zengin
    const cash = Math.round(1e6 * Math.pow(10, r() * 5));
    m.wallets.set(uid, { cash, blocked: 0 });
    money += cash;
    const mine: string[] = [];
    for (let k = 0; k < 3; k++) {
      const id = `t${i}_${k}`;
      const skill = 20 + Math.floor(r() * 80);
      m.talents.set(id, { id, owner: uid, skill, value: Math.round(1500 + skill * skill * 3) * 40 });
      mine.push(id);
    }
    talentsOf.set(uid, mine);
  }
  const pick = <T>(a: T[]): T => a[Math.floor(r() * a.length)];

  // açık artırmalar (yıldız transferleri): sistemden gelir, kazananın parası sisteme gider
  let now = 0;
  const auctions: Auction[] = [];
  for (let i = 0; i < 20; i++) auctions.push(makeAuction(r, now, 3600_000));
  let auctionSink = 0;

  let snap = snapshot(m);
  const stats: Record<string, { ok: number; fail: number }> = {};
  const count = (k: string, ok: boolean) => {
    stats[k] ??= { ok: 0, fail: 0 };
    ok ? stats[k].ok++ : stats[k].fail++;
  };

  for (let i = 0; i < OPS; i++) {
    now += 200; // her işlem arası 0,2 sn (saatte 18.000 işlem)
    if (i % 400 === 0) snap = snapshot(m); // ekranlar arada bir yenilenir
    const uid = pick(uids);
    const k = r();
    let res: { ok: boolean };
    if (k < 0.22) {
      const owned = [...(talentsOf.get(uid) ?? [])].filter((t) => m.talents.get(t)!.owner === uid);
      // bazen başkasının yeteneğini satmaya çalışır (hile denemesi)
      const tid = r() < 0.05 ? `t${Math.floor(r() * PLAYERS)}_0` : owned.length ? pick(owned) : `t0_0`;
      const t = m.talents.get(tid)!;
      const ask = r() < 0.03 ? -5 : Math.round(t.value * (0.2 + r() * 4));
      res = listTalent(m, uid, tid, ask, now);
      count('ilan', res.ok);
    } else if (k < 0.40 && snap.listings.length) {
      const l = pick(snap.listings);
      const tid = m.listings.get(l.id)?.talentId;
      res = buyNow(m, uid, l.id, l.ask);
      if (res.ok && tid) talentsOf.get(uid)!.push(tid);
      count('hemen al', res.ok);
    } else if (k < 0.58 && snap.listings.length) {
      const l = pick(snap.listings);
      const amt = r() < 0.02 ? NaN : l.ask * (0.2 + r() * 0.9);
      res = makeOffer(m, uid, l.id, amt, now);
      count('teklif', res.ok);
    } else if (k < 0.70 && snap.offers.length) {
      // satıcı (ya da hileci) teklif kabul eder
      const o = pick(snap.offers);
      const seller = r() < 0.9 ? (m.listings.get(o.listingId)?.seller ?? uid) : uid;
      const before = m.offers.get(o.id)?.buyer;
      const tid = m.listings.get(o.listingId)?.talentId;
      res = acceptOffer(m, seller, o.id, now);
      if (res.ok && before && tid) talentsOf.get(before)!.push(tid);
      count('kabul', res.ok);
    } else if (k < 0.76 && snap.offers.length) {
      const o = pick(snap.offers);
      res = withdrawOffer(m, r() < 0.8 ? o.buyer : uid, o.id);
      count('geri çek', res.ok);
    } else if (k < 0.82 && snap.listings.length) {
      const l = pick(snap.listings);
      res = cancelListing(m, r() < 0.8 ? l.seller : uid, l.id);
      count('ilan kaldır', res.ok);
    } else {
      // açık artırma teklifi
      const ai = Math.floor(r() * auctions.length);
      const a = auctions[ai];
      const w = m.wallets.get(uid)!;
      const amt = r() < 0.02 ? Infinity : Math.ceil(minNextBid(a) * (1 + r() * 0.2));
      const b = applyBid(a, uid, uid, amt, w.cash, now);
      if (b.ok) {
        w.cash -= amt;
        w.blocked += amt;
        if (b.refund) {
          const pw = m.wallets.get(b.refund.uid)!;
          pw.blocked -= b.refund.amount;
          pw.cash += b.refund.amount;
        }
        auctions[ai] = b.auction!;
      }
      count('artırma', b.ok);
    }
    // süresi dolan artırmaları kapat
    for (let j = 0; j < auctions.length; j++) {
      const a = auctions[j];
      if (now >= a.endsAt) {
        if (a.highBidder) {
          const w = m.wallets.get(a.highBidder)!;
          w.blocked -= a.highBid;
          auctionSink += a.highBid;
        }
        auctions[j] = makeAuction(r, now, 3600_000);
      }
    }
    if (i % 5000 === 0) expireOffers(m, now);
    if (i % 50000 === 0 || i === OPS - 1) {
      // açık artırmada bloke edilen para bu test için ayrı tutulur
      const auctionBlocked = new Map<string, number>();
      for (const a of auctions) if (a.highBidder) auctionBlocked.set(a.highBidder, (auctionBlocked.get(a.highBidder) ?? 0) + a.highBid);
      for (const [u, v] of auctionBlocked) m.wallets.get(u)!.blocked -= v;
      m.feesCollected += auctionSink;
      const ab = [...auctionBlocked.values()].reduce((x, y) => x + y, 0);
      const errs = audit(m, money - ab);
      m.feesCollected -= auctionSink;
      for (const [u, v] of auctionBlocked) m.wallets.get(u)!.blocked += v;
      assert.deepEqual(errs.slice(0, 5), [], `işlem ${i} sonrası tutarsızlık`);
    }
  }
  // fiyat bandı dışındaki ilan olmamalı
  for (const l of m.listings.values()) {
    const [lo, hi] = priceBand(m.talents.get(l.talentId)!);
    assert.ok(l.ask >= lo && l.ask <= hi);
  }
  // eslint-disable-next-line no-console
  console.log('işlem sonuçları:', JSON.stringify(stats));
  console.log(`açık ilan ${m.listings.size}, açık teklif ${m.offers.size}, komisyon ${m.feesCollected}, artırma ${auctionSink}`);
});
