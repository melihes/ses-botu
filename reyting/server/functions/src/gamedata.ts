// Oyun sabitlerinin SUNUCU kopyası. İstemcideki lib/data/content.dart ile
// uyumlu tutulmalıdır; sunucu hile kontrolünü bu değerlere göre yapar.

/** Stüdyo seviyelerinin yükseltme bedelleri (index = seviye - 1) */
export const studioCosts = [
  0, 2e6, 8e6, 25e6, 130e6, 500e6, 35e9, 135e9, 420e9, 1e12, 2e12, 3.5e12,
];

/**
 * Seviye başına makul en yüksek günlük net kazanç (simülasyondan, cömert).
 * Bunun 3 katından hızlı büyüyen kayıtlar şüpheli sayılır.
 */
export const maxNetPerDay = [
  1e6, 2.5e6, 8e6, 25e6, 50e6, 80e6, 120e6, 180e6, 250e6, 400e6, 600e6, 1e9,
];

export const luxuryPrices: Record<string, number> = {
  w1: 250000, w2: 1200000, w3: 6000000,
  c1: 1800000, c2: 9000000, c3: 45000000,
  h1: 8000000, h2: 60000000, h3: 250000000,
  y1: 30000000, y2: 180000000, y3: 900000000,
  j1: 400000000, j2: 1500000000,
  i1: 600000000, i2: 3000000000,
};

export const channelPrices: Record<string, number> = {
  k1: 1800000, k2: 3600000, k3: 10000000, k4: 20000000,
  k5: 50000000, k6: 115000000, k7: 260000000, k8: 700000000,
};

export const platformPrices: Record<string, number> = {
  pf1: 6000000, pf2: 25000000, pf3: 60000000, pf4: 180000000, pf5: 600000000,
};

export const stockBase: Record<string, number> = {
  MRTV: 4.2, PSLA: 7.8, TLSM: 18.5, KZY24: 26, MVEK: 54, YLDZ: 88, NOVA: 140,
  UFUK: 320, SYRL: 12, AKIS: 45, GLKS: 210, VDOM: 95, BYZP: 22, NOTA: 9.5,
  REKL: 31, UYDU: 480,
};

export function salaryFor(skill: number): number {
  return 1500 + skill * skill * 3;
}

export const firstNames = [
  'Ayla', 'Bora', 'Cemre', 'Deniz', 'Ece', 'Ferit', 'Gizem', 'Harun', 'Irmak',
  'Kaan', 'Lale', 'Mert', 'Nehir', 'Oğuz', 'Pelin', 'Selin', 'Tolga', 'Umay',
  'Volkan', 'Yaren', 'Arda', 'Berk', 'Ceyda', 'Doruk', 'Elif', 'Melis',
];
export const lastNames = [
  'Akarsu', 'Çınaroğlu', 'Demirkaya', 'Erdemli', 'Fırtına', 'Gündoğdu',
  'Kaplanoğlu', 'Karadut', 'Martılı', 'Poyrazoğlu', 'Sarıçam', 'Taşdelen',
  'Yelkenci', 'Zeytinoğlu', 'Ilgaz', 'Mercanlı', 'Yamaçlı', 'Pınarbaşı',
];
export const roles = ['senarist', 'yonetmen', 'oyuncu', 'sunucu'];
