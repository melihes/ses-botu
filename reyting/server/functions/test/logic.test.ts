import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  applyBid, makeAuction, minNextBid, rng, serverWorth, summarize, validateSave,
} from '../src/logic';

const base = (o: any = {}) => summarize({ day: 10, cash: 5e6, studioLevel: 1, channelName: 'Kanal 9', ...o });

test('ilk kayıt makulse kabul edilir', () => {
  const v = validateSave(null, base(), 0, 0);
  assert.equal(v.ok, true);
});

test('ilk kayıtta uçuk servet reddedilir', () => {
  const v = validateSave(null, base({ cash: 1e15 }), 0, 0);
  assert.equal(v.ok, false);
});

test('oyun zamanı gerçek zamandan hızlı akamaz', () => {
  const prev = { day: 10, worth: 5e6, level: 1 };
  // 5 dakikada 100 gün geçmiş: hız hilesi
  const v = validateSave(prev, base({ day: 110 }), 5 * 60000, 0);
  assert.equal(v.ok, false);
  assert.match(v.reason!, /gerçek zamandan/);
});

test('normal ilerleme kabul edilir', () => {
  const prev = { day: 10, worth: 5e6, level: 1 };
  const v = validateSave(prev, base({ day: 20, cash: 8e6 }), 10 * 60000, 0);
  assert.equal(v.ok, true);
});

test('servet olağan dışı artarsa reddedilir', () => {
  const prev = { day: 10, worth: 5e6, level: 1 };
  const v = validateSave(prev, base({ day: 11, cash: 5e9 }), 60000, 0);
  assert.equal(v.ok, false);
  assert.match(v.reason!, /Servet/);
});

test('geriye giden kayıt reddedilir', () => {
  const v = validateSave({ day: 50, worth: 5e6, level: 1 }, base({ day: 40 }), 60000, 0);
  assert.equal(v.ok, false);
});

test('zaman hızlandırma online kapalı', () => {
  const v = validateSave({ day: 10, worth: 5e6, level: 1 }, base({ timeScale: 60 }), 60000, 0);
  assert.equal(v.ok, false);
});

test('ihalede bloke para kasada olmalı', () => {
  const v = validateSave({ day: 10, worth: 5e6, level: 1 }, base({ cash: 1e6 }), 60000, 2e6);
  assert.equal(v.ok, false);
});

test('hisse fiyatı hilesi tavanla sınırlanır', () => {
  const s = base({ holdings: { MRTV: 1000 }, stockPrices: { MRTV: 1e9 } });
  const without = serverWorth(base());
  assert.ok(serverWorth(s) - without <= 1000 * 4.2 * (1 + 10 / 3000) * 3 + 1);
});

test('ihale: ilk teklif başlangıç fiyatından az olamaz', () => {
  const a = makeAuction(rng(1), 0);
  const r = applyBid(a, 'u1', 'A', a.startPrice - 1, 1e12, 1000);
  assert.equal(r.ok, false);
});

test('ihale: geçilen teklif iade edilir, artış en az %5', () => {
  const a = makeAuction(rng(2), 0);
  const r1 = applyBid(a, 'u1', 'A', a.startPrice, 1e12, 1000);
  assert.equal(r1.ok, true);
  const tooLow = applyBid(r1.auction!, 'u2', 'B', a.startPrice + 1, 1e12, 2000);
  assert.equal(tooLow.ok, false);
  const r2 = applyBid(r1.auction!, 'u2', 'B', minNextBid(r1.auction!), 1e12, 2000);
  assert.equal(r2.ok, true);
  assert.deepEqual(r2.refund, { uid: 'u1', amount: a.startPrice });
});

test('ihale: parası yetmeyen teklif veremez', () => {
  const a = makeAuction(rng(3), 0);
  const r = applyBid(a, 'u1', 'A', a.startPrice, a.startPrice - 1, 1000);
  assert.equal(r.ok, false);
});

test('ihale: son saniye teklifi süreyi uzatır', () => {
  const a = makeAuction(rng(4), 0, 60000);
  const r = applyBid(a, 'u1', 'A', a.startPrice, 1e12, 50000);
  assert.equal(r.auction!.endsAt, 80000);
});

test('ihale: süresi bitmiş ihaleye teklif verilemez', () => {
  const a = makeAuction(rng(5), 0, 60000);
  assert.equal(applyBid(a, 'u1', 'A', a.startPrice, 1e12, 60001).ok, false);
});
