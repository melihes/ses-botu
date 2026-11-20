import 'package:flutter/material.dart';

import '../core/theme.dart';

// =====================================================================
// TÜM İSİMLER KURGUSALDIR. Gerçek kanal, dizi, program veya ünlü yoktur.
// =====================================================================

/// Kadro rolleri
enum Role { senarist, yonetmen, oyuncu, sunucu }

extension RoleX on Role {
  String get label =>
      const ['Senarist', 'Yönetmen', 'Oyuncu', 'Sunucu'][index];
  IconData get icon => const [
        Icons.edit_note_rounded,
        Icons.videocam_rounded,
        Icons.theater_comedy_rounded,
        Icons.mic_rounded,
      ][index];
  Color get color => const [
        AppColors.blue,
        AppColors.purple,
        AppColors.pink,
        AppColors.orange,
      ][index];
}

/// Yayın kuşakları
enum SlotId { gunduz, aksam, prime, gece }

class SlotDef {
  final String label;
  final String hours;
  final double poolMillions; // bu saatte TV başındaki potansiyel izleyici
  final double adValue; // reklam dakikasının değer çarpanı
  final int unlockLevel; // hangi stüdyo seviyesinde açılır
  const SlotDef(
      this.label, this.hours, this.poolMillions, this.adValue, this.unlockLevel);
}

const slotDefs = <SlotId, SlotDef>{
  SlotId.gunduz: SlotDef('Gündüz', '10:00–17:00', 6, 0.6, 1),
  SlotId.aksam: SlotDef('Akşam', '17:00–20:00', 9, 1.0, 2),
  SlotId.prime: SlotDef('Prime Time', '20:00–23:00', 14, 1.6, 1),
  SlotId.gece: SlotDef('Gece', '23:00–02:00', 5, 0.5, 3),
};

/// Program türleri
enum Genre { dizi, yarisma, haber, magazin, talkShow, belgesel, spor, cocuk }

class GenreDef {
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final Map<Role, int> needs;
  final int prodDays;
  final int seasonDays;
  final double baseCost;
  final double ratingMult;
  final Map<SlotId, double> fit;
  final String? reqEquip; // bu türü açmak için gereken ekipman
  const GenreDef({
    this.reqEquip,
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.needs,
    required this.prodDays,
    required this.seasonDays,
    required this.baseCost,
    required this.ratingMult,
    required this.fit,
  });
}

const genreDefs = <Genre, GenreDef>{
  Genre.dizi: GenreDef(
    label: 'Dizi',
    desc: 'Pahalı ama prime time\'ın kralı. Sezon ortasında zirve yapar.',
    icon: Icons.movie_filter_rounded,
    color: AppColors.pink,
    needs: {Role.senarist: 1, Role.yonetmen: 1, Role.oyuncu: 2},
    prodDays: 3,
    seasonDays: 14,
    baseCost: 300000,
    ratingMult: 1.15,
    fit: {
      SlotId.gunduz: 0.6,
      SlotId.aksam: 0.9,
      SlotId.prime: 1.2,
      SlotId.gece: 0.7,
    },
  ),
  Genre.yarisma: GenreDef(
    label: 'Yarışma',
    desc: 'Sunucu ve yönetmen yeterli. Akşam ve prime time\'da güçlü.',
    icon: Icons.emoji_events_rounded,
    color: AppColors.yellow,
    needs: {Role.yonetmen: 1, Role.sunucu: 1},
    prodDays: 2,
    seasonDays: 10,
    baseCost: 200000,
    ratingMult: 1.05,
    fit: {
      SlotId.gunduz: 0.8,
      SlotId.aksam: 1.1,
      SlotId.prime: 1.05,
      SlotId.gece: 0.7,
    },
  ),
  Genre.haber: GenreDef(
    label: 'Haber',
    desc: 'Ucuz ve hızlı. Akşam kuşağında sadık izleyici toplar.',
    icon: Icons.newspaper_rounded,
    color: AppColors.blue,
    needs: {Role.senarist: 1, Role.sunucu: 1},
    prodDays: 1,
    seasonDays: 7,
    baseCost: 60000,
    ratingMult: 0.8,
    fit: {
      SlotId.gunduz: 0.9,
      SlotId.aksam: 1.2,
      SlotId.prime: 0.85,
      SlotId.gece: 1.0,
    },
  ),
  Genre.magazin: GenreDef(
    label: 'Magazin',
    desc: 'Tek sunucuyla çekilir. Gündüz ve gece kuşağına uygun.',
    icon: Icons.auto_awesome_rounded,
    color: AppColors.purple,
    needs: {Role.sunucu: 1},
    prodDays: 1,
    seasonDays: 7,
    baseCost: 50000,
    ratingMult: 0.85,
    fit: {
      SlotId.gunduz: 1.2,
      SlotId.aksam: 0.9,
      SlotId.prime: 0.7,
      SlotId.gece: 1.1,
    },
  ),
  Genre.talkShow: GenreDef(
    label: 'Talk Show',
    desc: 'Sunucunun esprisi her şey. Gece kuşağının yıldızı.',
    icon: Icons.weekend_rounded,
    color: AppColors.cyan,
    needs: {Role.sunucu: 1, Role.senarist: 1},
    prodDays: 1,
    seasonDays: 10,
    baseCost: 120000,
    ratingMult: 0.95,
    fit: {
      SlotId.gunduz: 0.8,
      SlotId.aksam: 0.9,
      SlotId.prime: 0.9,
      SlotId.gece: 1.25,
    },
  ),
  Genre.belgesel: GenreDef(
    label: 'Belgesel',
    desc: 'Drone ekibi ister. Prestij kazandırır, sakin ama istikrarlı izlenir.',
    icon: Icons.forest_rounded,
    color: AppColors.green,
    needs: {Role.yonetmen: 1, Role.senarist: 1},
    prodDays: 3,
    seasonDays: 8,
    baseCost: 180000,
    ratingMult: 0.8,
    reqEquip: 'drone',
    fit: {
      SlotId.gunduz: 1.0,
      SlotId.aksam: 0.9,
      SlotId.prime: 0.8,
      SlotId.gece: 1.1,
    },
  ),
  Genre.spor: GenreDef(
    label: 'Spor',
    desc: 'Canlı yayın aracı şart. Yayın hakları pahalı, reytingi çok yüksek.',
    icon: Icons.sports_soccer_rounded,
    color: AppColors.orange,
    needs: {Role.sunucu: 1, Role.yonetmen: 1},
    prodDays: 1,
    seasonDays: 7,
    baseCost: 450000,
    ratingMult: 1.3,
    reqEquip: 'ob',
    fit: {
      SlotId.gunduz: 0.7,
      SlotId.aksam: 1.0,
      SlotId.prime: 1.15,
      SlotId.gece: 0.8,
    },
  ),
  Genre.cocuk: GenreDef(
    label: 'Çocuk',
    desc: 'Gündüz kuşağında rakipsiz. Ucuz, uzun soluklu.',
    icon: Icons.toys_rounded,
    color: AppColors.teal,
    needs: {Role.senarist: 1, Role.oyuncu: 1},
    prodDays: 2,
    seasonDays: 12,
    baseCost: 90000,
    ratingMult: 0.85,
    fit: {
      SlotId.gunduz: 1.3,
      SlotId.aksam: 0.9,
      SlotId.prime: 0.5,
      SlotId.gece: 0.3,
    },
  ),
};

/// Bütçe seviyeleri
class BudgetTier {
  final String label;
  final double costMult;
  final double qualityMult;
  const BudgetTier(this.label, this.costMult, this.qualityMult);
}

const budgetTiers = [
  BudgetTier('Düşük', 0.5, 0.85),
  BudgetTier('Orta', 1.0, 1.0),
  BudgetTier('Yüksek', 2.2, 1.18),
];

/// Program adı önerileri (kurgusal, oyuncu değiştirebilir)
const showNameIdeas = <Genre, List<String>>{
  Genre.dizi: [
    'Konaktaki Sır',
    'Mavi Kapılı Ev',
    'Rüzgâr Sokağı',
    'Son Vapur',
    'Çınar Altı',
    'Kırk Pencere',
    'Dut Ağacı Mahallesi',
    'Gölgedeki Varis',
    'Fener Yolu',
    'İncir Bahçesi',
  ],
  Genre.yarisma: [
    'Adada Kalan',
    'Bil Bakalım Kazan',
    'Altın Kutu',
    'Hızlı Parmak',
    'Kapıyı Seç',
    'Son Kalan Kazanır',
    'Beş Soru Bir Servet',
  ],
  Genre.haber: [
    'Akşam Bülteni',
    'Gün Ortası',
    'Haber Masası',
    'Ana Hat',
    'Saat Başı',
    'Gece Gündemi',
  ],
  Genre.magazin: [
    'Flaş Kulis',
    'Kırmızı Halı',
    'Ekran Arkası',
    'Paparazzi Saati',
    'Işıklar Altında',
    'Dedikodu Kahvesi',
  ],
  Genre.talkShow: [
    'Gece Yarısı Sohbetleri',
    'Koltuk',
    'Kahkaha Saati',
    'Ay Işığında',
  ],
  Genre.belgesel: [
    'Toprağın Sesi',
    'Mavi Derinlikler',
    'Kayıp Şehirler',
    'Bozkırın Kanatları',
  ],
  Genre.spor: [
    'Tribün',
    'Doksanıncı Dakika',
    'Saha Kenarı',
    'Süper Maç Gecesi',
  ],
  Genre.cocuk: [
    'Bulut Kasabası',
    'Minik Kâşifler',
    'Robot Pıtırcık',
    'Masal Treni',
  ],
};

/// Rastgele kurgusal kişi adları için ad/soyad havuzları
const firstNames = [
  'Ayla', 'Bora', 'Cemre', 'Deniz', 'Ece', 'Ferit', 'Gizem', 'Harun',
  'Irmak', 'Kaan', 'Lale', 'Mert', 'Nehir', 'Oğuz', 'Pelin', 'Rüzgâr',
  'Selin', 'Tolga', 'Umay', 'Volkan', 'Yaren', 'Zeki', 'Arda', 'Berk',
  'Ceyda', 'Doruk', 'Elif', 'Fulya', 'Gökay', 'İlkin', 'Kumsal', 'Melis',
  'Nazlı', 'Onur', 'Sarp', 'Tuana', 'Utku', 'Yağmur', 'Alper', 'Defne',
];

const lastNames = [
  'Akarsu', 'Bayraktaroğlu', 'Çınaroğlu', 'Demirkaya', 'Erdemli',
  'Fırtına', 'Gündoğdu', 'Hisarlı', 'Işıkgöz', 'Kaplanoğlu', 'Karadut',
  'Limoncu', 'Martılı', 'Narlıdere', 'Ormanlı', 'Poyrazoğlu', 'Rüzgârlı',
  'Sarıçam', 'Taşdelen', 'Uçurumlu', 'Yelkenci', 'Zeytinoğlu', 'Ilgaz',
  'Karabulut', 'Mercanlı', 'Yamaçlı', 'Dağdelen', 'Pınarbaşı',
];

/// Stüdyo seviyeleri
class StudioLevel {
  final String name;
  final double reach; // ülke çapında erişim oranı
  final double upgradeCost; // bu seviyeye çıkış bedeli
  final double rentPerDay;
  final int maxStaff;
  const StudioLevel(
      this.name, this.reach, this.upgradeCost, this.rentPerDay, this.maxStaff);
}

const studioLevels = [
  StudioLevel('Yerel Stüdyo', 0.25, 0, 8000, 8),
  StudioLevel('Bölgesel Stüdyo', 0.40, 2000000, 16000, 14),
  StudioLevel('Ulusal Kanal', 0.55, 8000000, 40000, 22),
  StudioLevel('Büyük Plato', 0.70, 25000000, 90000, 32),
  StudioLevel('Medya Kampüsü', 0.85, 130000000, 250000, 45),
  StudioLevel('Medya İmparatorluğu', 1.00, 500000000, 600000, 60),
  // ---- Uluslararası genişleme: uzun soluklu hedefler ----
  StudioLevel('Balkan Yayın Ağı', 1.30, 35e9, 1500000, 70),
  StudioLevel('Avrasya Medya Grubu', 1.70, 135e9, 3000000, 80),
  StudioLevel('Kıtalararası Ağ', 2.20, 420e9, 5000000, 90),
  StudioLevel('Küresel Yayın Devi', 2.90, 1e12, 8000000, 100),
  StudioLevel('Dünya Medya İmparatorluğu', 3.80, 2e12, 12000000, 110),
  StudioLevel('Efsanevi Medya Patronu', 5.00, 3.5e12, 18000000, 120),
];

/// Lüks yaşam
enum LuxCat { saat, araba, ev, yat, jet, ada }

extension LuxCatX on LuxCat {
  String get label =>
      const ['Saatler', 'Arabalar', 'Evler', 'Yatlar', 'Özel Jet', 'Adalar']
          [index];
  IconData get icon => const [
        Icons.watch_rounded,
        Icons.directions_car_filled_rounded,
        Icons.villa_rounded,
        Icons.sailing_rounded,
        Icons.flight_rounded,
        Icons.landscape_rounded,
      ][index];
  Color get color => const [
        AppColors.yellow,
        AppColors.red,
        AppColors.teal,
        AppColors.blue,
        AppColors.purple,
        AppColors.green,
      ][index];
}

class LuxuryDef {
  final String id;
  final LuxCat cat;
  final String name;
  final String desc;
  final double price;
  final int prestige;
  final bool negotiable;
  const LuxuryDef(this.id, this.cat, this.name, this.desc, this.price,
      this.prestige, {this.negotiable = false});
}

const luxuryDefs = [
  LuxuryDef('w1', LuxCat.saat, 'Kronos Klasik', 'Çelik kasa, sade şıklık.',
      250000, 5),
  LuxuryDef('w2', LuxCat.saat, 'Helvetia Royal', 'Altın kasa, el işçiliği.',
      1200000, 15),
  LuxuryDef('w3', LuxCat.saat, 'Aurum Tourbillon',
      'Sınırlı üretim, koleksiyonluk.', 6000000, 40, negotiable: true),
  LuxuryDef('c1', LuxCat.araba, 'Strada Sedan', 'Konforlu makam aracı.',
      1800000, 10),
  LuxuryDef('c2', LuxCat.araba, 'Vantor GT', 'İki kapılı İtalyan tarzı GT.',
      9000000, 35),
  LuxuryDef('c3', LuxCat.araba, 'Falco Hiper', 'Dünyada sadece 99 adet.',
      45000000, 90, negotiable: true),
  LuxuryDef('h1', LuxCat.ev, 'Şehir Rezidansı', 'Merkezde 3+1, manzaralı.',
      8000000, 25),
  LuxuryDef('h2', LuxCat.ev, 'Boğaz Manzaralı Villa', 'Havuzlu, bahçeli.',
      60000000, 80, negotiable: true),
  LuxuryDef('h3', LuxCat.ev, 'Kuzey Ormanı Malikânesi',
      'Kendi göleti olan tarihi malikâne.', 250000000, 200, negotiable: true),
  LuxuryDef('y1', LuxCat.yat, 'Martı 40 Motoryat', '12 metre, 6 kişilik.',
      30000000, 60, negotiable: true),
  LuxuryDef('y2', LuxCat.yat, 'Poyraz 80 Süperyat', 'Jakuzili, 4 kabinli.',
      180000000, 180, negotiable: true),
  LuxuryDef('y3', LuxCat.yat, 'Okyanus 140 Megayat',
      'Helikopter pisti ve sinema salonu.', 900000000, 500, negotiable: true),
  LuxuryDef('j1', LuxCat.jet, 'Bulut Jet S', '8 kişilik iş jeti.', 400000000,
      300, negotiable: true),
  LuxuryDef('j2', LuxCat.jet, 'Ufuk Jet XL', 'Kıtalararası uçuş menzili.',
      1500000000, 700, negotiable: true),
  LuxuryDef('i1', LuxCat.ada, "Ege'de Küçük Ada",
      'Koylu, iskeleli, çam ağaçlı.', 600000000, 450, negotiable: true),
  LuxuryDef('i2', LuxCat.ada, 'Akdeniz Özel Adası',
      'Kendi limanı ve villa köyü olan ada.', 3000000000, 1200,
      negotiable: true),
];

/// Satın alınabilecek rakip kanallar (yapay rakipler)
class ChannelDef {
  final String id;
  final String name;
  final String region;
  final double dailyIncome;
  final double price;
  final int reqLevel;
  final Color color;
  const ChannelDef(this.id, this.name, this.region, this.dailyIncome,
      this.price, this.reqLevel, this.color);
}

const channelDefs = [
  ChannelDef('k1', 'Martı TV', 'Yerel · Ege', 30000, 1800000, 1,
      AppColors.blue),
  ChannelDef('k2', 'Pusula TV', 'Yerel · Karadeniz', 55000, 3600000, 1,
      AppColors.teal),
  ChannelDef('k3', 'Telesim', 'Bölgesel · Marmara', 140000, 10000000, 2,
      AppColors.orange),
  ChannelDef('k4', 'Kuzey 24', 'Bölgesel · Haber', 260000, 20000000, 2,
      AppColors.red),
  ChannelDef('k5', 'Mavi Ekran', 'Ulusal · Aile', 600000, 50000000, 3,
      AppColors.purple),
  ChannelDef('k6', 'Yıldız Kanal', 'Ulusal · Eğlence', 1300000, 115000000, 4,
      AppColors.yellow),
  ChannelDef('k7', 'Nova Türk', 'Ulusal · Dizi', 2800000, 260000000, 5,
      AppColors.pink),
  ChannelDef('k8', 'Ufuk Global', 'Uluslararası', 7000000, 700000000, 6,
      AppColors.green),
];

/// Ekipman, araç ve tesisler
class EquipDef {
  final String id;
  final String name;
  final String desc;
  final IconData icon;
  final double price;
  final int reqLevel;
  final Set<Genre> boosts; // boşsa tüm türler
  final double qualityBonus; // ör. 0.06 = %6
  final double prodSpeed; // üretim süresi çarpanı (0.75 = %25 hızlı)
  final double reachBonus; // erişime eklenen
  const EquipDef(this.id, this.name, this.desc, this.icon, this.price,
      this.reqLevel,
      {this.boosts = const {},
      this.qualityBonus = 0,
      this.prodSpeed = 1,
      this.reachBonus = 0});
  double get upkeepPerDay => price * 0.002;
}

const equipDefs = [
  EquipDef('cam', 'Sinema Kamerası', 'Dizi ve belgesele sinema kalitesi.',
      Icons.camera_alt_rounded, 1500000, 1,
      boosts: {Genre.dizi, Genre.belgesel}, qualityBonus: 0.06),
  EquipDef('edit', 'Kurgu Odası', 'Tüm yapımlar %25 daha hızlı biter.',
      Icons.content_cut_rounded, 2500000, 1,
      prodSpeed: 0.75),
  EquipDef('jib', 'Kamera Vinci', 'Stüdyo şovlarında görkemli çekimler.',
      Icons.precision_manufacturing_rounded, 3000000, 2,
      boosts: {Genre.yarisma, Genre.talkShow, Genre.spor},
      qualityBonus: 0.05),
  EquipDef('drone', 'Drone Ekibi', 'Belgesel türünü açar, dizilere havadan çekim.',
      Icons.flight_takeoff_rounded, 4000000, 2,
      boosts: {Genre.belgesel, Genre.dizi}, qualityBonus: 0.05),
  EquipDef('sound', 'Ses Stüdyosu', 'Tüm programlarda temiz ses.',
      Icons.graphic_eq_rounded, 6000000, 2,
      qualityBonus: 0.04),
  EquipDef('ob', 'Canlı Yayın Aracı', 'Spor türünü açar, haberde sahadan canlı bağlantı.',
      Icons.local_shipping_rounded, 15000000, 3,
      boosts: {Genre.spor, Genre.haber}, qualityBonus: 0.06),
  EquipDef('led', 'LED Sanal Stüdyo', 'Haber, magazin, talk show ve çocuk programlarına ışıltı.',
      Icons.tv_rounded, 25000000, 3,
      boosts: {Genre.haber, Genre.magazin, Genre.talkShow, Genre.cocuk},
      qualityBonus: 0.08),
  EquipDef('vfx', 'Görsel Efekt (VFX) Atölyesi',
      'Bilim kurgu ve animasyon filmlerini açar.',
      Icons.auto_fix_high_rounded, 20000000, 3,
      qualityBonus: 0.0),
  EquipDef('tower', 'Verici Kulesi', 'Yayın erişimini %8 artırır.',
      Icons.cell_tower_rounded, 60000000, 4,
      reachBonus: 0.08),
  EquipDef('sat', 'Uydu Bağlantısı', 'Yayın erişimini %12 artırır.',
      Icons.satellite_alt_rounded, 150000000, 5,
      reachBonus: 0.12),
];

EquipDef? equipById(String id) {
  for (final e in equipDefs) {
    if (e.id == id) return e;
  }
  return null;
}

// =====================================================================
// SİNEMA: film türleri
// =====================================================================
enum FilmGenre { aksiyon, komedi, dram, korku, romantik, bilimKurgu, animasyon }

class FilmGenreDef {
  final String label;
  final String desc;
  final IconData icon;
  final Color color;
  final Map<Role, int> needs;
  final int prodDays;
  final double baseCost;
  final double boxOffice; // gişe çekiciliği
  final double streaming; // platformlarda çekicilik
  final String? reqEquip;
  const FilmGenreDef({
    required this.label,
    required this.desc,
    required this.icon,
    required this.color,
    required this.needs,
    required this.prodDays,
    required this.baseCost,
    required this.boxOffice,
    required this.streaming,
    this.reqEquip,
  });
}

const filmGenreDefs = <FilmGenre, FilmGenreDef>{
  FilmGenre.aksiyon: FilmGenreDef(
    label: 'Aksiyon',
    desc: 'Pahalı ama gişenin kralı. Patlamalar, kovalamacalar!',
    icon: Icons.local_fire_department_rounded,
    color: AppColors.orange,
    needs: {Role.senarist: 1, Role.yonetmen: 1, Role.oyuncu: 2},
    prodDays: 5,
    baseCost: 900000,
    boxOffice: 1.3,
    streaming: 0.9,
  ),
  FilmGenre.komedi: FilmGenreDef(
    label: 'Komedi',
    desc: 'Ucuz çekilir, aileler bayılır. Gişede sürpriz yapar.',
    icon: Icons.sentiment_very_satisfied_rounded,
    color: AppColors.yellow,
    needs: {Role.senarist: 1, Role.yonetmen: 1, Role.oyuncu: 1},
    prodDays: 3,
    baseCost: 400000,
    boxOffice: 1.15,
    streaming: 1.0,
  ),
  FilmGenre.dram: FilmGenreDef(
    label: 'Dram',
    desc: 'Festivallerin gözdesi. Platformlarda uzun soluklu izlenir.',
    icon: Icons.theater_comedy_rounded,
    color: AppColors.blue,
    needs: {Role.senarist: 1, Role.yonetmen: 1, Role.oyuncu: 2},
    prodDays: 4,
    baseCost: 500000,
    boxOffice: 0.85,
    streaming: 1.3,
  ),
  FilmGenre.korku: FilmGenreDef(
    label: 'Korku',
    desc: 'Düşük bütçe, yüksek kâr. Platformlar korkuya bayılır.',
    icon: Icons.nightlight_round,
    color: AppColors.red,
    needs: {Role.senarist: 1, Role.yonetmen: 1, Role.oyuncu: 1},
    prodDays: 3,
    baseCost: 350000,
    boxOffice: 1.0,
    streaming: 1.25,
  ),
  FilmGenre.romantik: FilmGenreDef(
    label: 'Romantik',
    desc: 'İki iyi oyuncu yeter. Sevgililer gününün garantisi.',
    icon: Icons.favorite_rounded,
    color: AppColors.pink,
    needs: {Role.senarist: 1, Role.yonetmen: 1, Role.oyuncu: 2},
    prodDays: 3,
    baseCost: 450000,
    boxOffice: 1.0,
    streaming: 1.15,
  ),
  FilmGenre.bilimKurgu: FilmGenreDef(
    label: 'Bilim Kurgu',
    desc: 'VFX atölyesi ister. Dünya çapında platformların gözdesi.',
    icon: Icons.rocket_launch_rounded,
    color: AppColors.cyan,
    needs: {Role.senarist: 1, Role.yonetmen: 1, Role.oyuncu: 2},
    prodDays: 6,
    baseCost: 1600000,
    boxOffice: 1.25,
    streaming: 1.35,
    reqEquip: 'vfx',
  ),
  FilmGenre.animasyon: FilmGenreDef(
    label: 'Animasyon',
    desc: 'VFX atölyesi ister. Oyuncu gerekmez, çocuklar tekrar tekrar izler.',
    icon: Icons.pets_rounded,
    color: AppColors.green,
    needs: {Role.senarist: 1, Role.yonetmen: 1},
    prodDays: 6,
    baseCost: 1200000,
    boxOffice: 1.1,
    streaming: 1.45,
    reqEquip: 'vfx',
  ),
};

const filmNameIdeas = <FilmGenre, List<String>>{
  FilmGenre.aksiyon: ['Son Kurşun', 'Köprüdeki Takip', 'Gece Operasyonu', 'Demir Yumruk', 'Kırmızı Alarm'],
  FilmGenre.komedi: ['Bizim Apartman Karışık', 'Düğün Telaşı', 'Yanlış Valiz', 'Kaynanam Tatilde', 'Şanslı Bilet'],
  FilmGenre.dram: ['Rüzgârın Ardından', 'Sessiz Liman', 'Babamın Saati', 'Son Mektup', 'Kar Altında'],
  FilmGenre.korku: ['Bodrum Katı', 'Terk Edilmiş Köy', 'Gece Yarısı Sinyali', 'Kuyu', 'Fısıltılar'],
  FilmGenre.romantik: ['Vapurda Tanıştık', 'Bir Bahar Akşamı', 'İki Kişilik Şemsiye', 'Yağmurdan Sonra'],
  FilmGenre.bilimKurgu: ['Yörünge 9', 'Zaman Kapısı', 'Mars Kolonisi', 'Son İstasyon', 'Kuantum Gecesi'],
  FilmGenre.animasyon: ['Minik Martı', 'Sihirli Kalem', 'Robot ve Kedi', 'Ormanın Bekçileri', 'Uzay Tavşanı'],
};

// =====================================================================
// DİJİTAL PLATFORMLAR (kurgusal isteğe bağlı izleme servisleri)
// =====================================================================
class PlatformDef {
  final String id;
  final String name;
  final String tagline;
  final Color color;
  final double subscribersM;
  final double dailyIncome;
  final double price;
  final int reqLevel;
  final double payMult; // film lisansı için ödeme gücü
  const PlatformDef(this.id, this.name, this.tagline, this.color,
      this.subscribersM, this.dailyIncome, this.price, this.reqLevel,
      this.payMult);
}

const platformDefs = [
  PlatformDef('pf1', 'Seyirlik', 'Yerli dizi ve filmler', AppColors.teal, 0.4,
      90000, 6000000, 2, 0.6),
  PlatformDef('pf2', 'Akış+', 'Gençlerin favorisi', AppColors.accent, 1.5,
      300000, 25000000, 3, 0.9),
  PlatformDef('pf3', 'Perdeli', 'Sinema severlerin adresi', AppColors.purple,
      3, 700000, 60000000, 3, 1.1),
  PlatformDef('pf4', 'Galaksi Play', 'Bölgenin en büyüğü', AppColors.blue, 8,
      2000000, 180000000, 4, 1.4),
  PlatformDef('pf5', 'Kutu Global', 'Dünya çapında yayın', AppColors.yellow,
      25, 6000000, 600000000, 5, 1.8),
];

PlatformDef? platformById(String id) {
  for (final p in platformDefs) {
    if (p.id == id) return p;
  }
  return null;
}

// =====================================================================
// HOLDİNG: yan işletmeler (gelir + oyuna etkisi)
// =====================================================================
enum BizEffect {
  showRating, // belirli türlerde reyting
  adRate, // reklam fiyatı
  marketSkill, // aday yetenekleri
  quality, // dizi/film kalitesi
  prodSpeed, // çekim süresi
  boxOffice, // gişe
  licenseFee, // platform lisans ücretleri
  prestige, // prestij
}

class BizDef {
  final String id;
  final String name;
  final String desc;
  final IconData icon;
  final Color color;
  final double baseCost;
  final double baseIncome;
  final BizEffect effect;
  final double perLevel;
  final String effectText; // "{v}" yerine değer yazılır
  final Set<Genre> genres;
  final int reqLevel;
  const BizDef(this.id, this.name, this.desc, this.icon, this.color,
      this.baseCost, this.baseIncome, this.effect, this.perLevel,
      this.effectText,
      {this.genres = const {}, this.reqLevel = 1});
}

const bizMaxLevel = 5;

const bizDefs = [
  BizDef('radyo', 'Frekans 9 FM', 'Magazin ve talk show programlarını radyoda tanıtır.',
      Icons.radio_rounded, AppColors.pink, 800000, 15000, BizEffect.showRating,
      0.03, 'Magazin & talk show reytingi +{v}',
      genres: {Genre.magazin, Genre.talkShow}),
  BizDef('gazete', 'Günlük Manşet', 'Kendi gazeten: haberlerin güvenilirliği artar.',
      Icons.feed_rounded, AppColors.blue, 1500000, 25000, BizEffect.showRating,
      0.04, 'Haber reytingi +{v}',
      genres: {Genre.haber}),
  BizDef('akademi', 'Oyunculuk Akademisi', 'Yeni yetenekler yetiştirir.',
      Icons.school_rounded, AppColors.purple, 2500000, 10000, BizEffect.marketSkill,
      3, 'İş ilanlarında yetenek +{v}'),
  BizDef('ajans', 'Reklam Ajansı', 'Reklam kuşaklarını daha pahalıya satar.',
      Icons.campaign_rounded, AppColors.accent, 3000000, 40000, BizEffect.adRate,
      0.03, 'Reklam fiyatı +{v}'),
  BizDef('muzik', 'Nota Müzik Şirketi', 'Dizi ve film müzikleri besteler.',
      Icons.music_note_rounded, AppColors.yellow, 5000000, 70000, BizEffect.quality,
      0.02, 'Dizi ve film kalitesi +{v}',
      reqLevel: 2),
  BizDef('plato', 'Plato Kiralama', 'Boş platolarını diğer yapımcılara kiralar.',
      Icons.warehouse_rounded, AppColors.teal, 8000000, 140000, BizEffect.prodSpeed,
      0.05, 'Çekim süresi -{v}',
      reqLevel: 2),
  BizDef('sinema', 'Beyazperde Salonları', 'Sinema salonları zinciri. Filmlerin kendi salonlarında oynar.',
      Icons.chair_rounded, AppColors.red, 12000000, 180000, BizEffect.boxOffice,
      0.10, 'Gişe geliri +{v}',
      reqLevel: 2),
  BizDef('dublaj', 'Ses & Dublaj Stüdyosu', 'Filmlerini yabancı dillere çevirir.',
      Icons.translate_rounded, AppColors.cyan, 10000000, 120000, BizEffect.licenseFee,
      0.08, 'Platform lisans ücretleri +{v}',
      reqLevel: 3),
  BizDef('otel', 'Kıyı Oteli & Film Festivali', 'Her yaz yıldızların akın ettiği festival oteli.',
      Icons.hotel_rounded, AppColors.green, 30000000, 450000, BizEffect.prestige,
      20, 'Prestij +{v}',
      reqLevel: 3),
];

BizDef? bizById(String id) {
  for (final b in bizDefs) {
    if (b.id == id) return b;
  }
  return null;
}

// =====================================================================
// FORMATLAR: her türün seviyeli program formatları (bütçe merdiveni)
// =====================================================================

/// Sahnede çizilecek dekor
enum Prop {
  // dizi
  livingRoom, neighborhood, sitcom, police, palace, epic,
  // yarışma
  quiz, couples, wheel, voice, talent, island,
  // haber
  newsDesk, globe, debate, field, election,
  // magazin
  gossip, redCarpet, paparazzi, awards,
  // talk show
  morning, nightShow, standup, sketch, newYear,
  // belgesel
  nature, ocean, history, space,
  // spor
  sportsDesk, football, basketball, derby, tournament,
  // çocuk
  cartoon, puppet, lab, kidsStage,
  // diğer
  film, studio,
}

class FormatDef {
  final String name;
  final String desc;
  final Prop prop;
  final double costMult;
  final double qualityMult;
  final int unlockLevel; // stüdyo seviyesi
  final String? reqEquip;
  const FormatDef(this.name, this.desc, this.prop, this.costMult,
      this.qualityMult, this.unlockLevel,
      {this.reqEquip});
}

const genreFormats = <Genre, List<FormatDef>>{
  Genre.dizi: [
    FormatDef('Gündüz dizisi', 'Ev içinde geçen sıcak aile hikâyesi. Ucuz ve sade.', Prop.livingRoom, 0.5, 0.85, 1),
    FormatDef('Mahalle dizisi', 'Mahallede dostluk, aşk ve dedikodu.', Prop.neighborhood, 1, 1.0, 1),
    FormatDef('Komedi dizisi', 'Seyircili çekilen, kahkahalı aile komedisi.', Prop.sitcom, 1.5, 1.1, 2),
    FormatDef('Polisiye', 'Gece çekimleri, sirenler, kovalamacalar.', Prop.police, 2.5, 1.22, 3),
    FormatDef('Dönem dizisi', 'Saraylar, kostümler, görkemli dekorlar.', Prop.palace, 4, 1.35, 4),
    FormatDef('Süper yapım', 'Dünyaya satılacak dev bütçeli epik yapım.', Prop.epic, 7, 1.5, 5),
  ],
  Genre.yarisma: [
    FormatDef('Bilgi yarışması', 'Klasik soru-cevap. Ucuz, sevimli, sadık izleyici.', Prop.quiz, 0.5, 0.85, 1),
    FormatDef('Çiftler yarışması', 'Eşler birbirini ne kadar tanıyor? Kahkaha garantili.', Prop.couples, 1, 1.0, 1),
    FormatDef('Şans çarkı', 'Çark döner, harfler açılır, ödüller dağılır.', Prop.wheel, 1.6, 1.12, 2),
    FormatDef('Ses yarışması', 'Jüri koltukları dönüyor, en güzel ses kazanıyor.', Prop.voice, 2.8, 1.25, 3),
    FormatDef('Yetenek şovu', 'Jüri önünde her türlü yetenek: dans, sihir, akrobasi.', Prop.talent, 4.5, 1.38, 4),
    FormatDef('Adada Kalan', 'İki takım, ıssız bir ada, dev prodüksiyon. Drone ekibi şart.', Prop.island, 8, 1.55, 5, reqEquip: 'drone'),
  ],
  Genre.haber: [
    FormatDef('Yerel bülten', 'Tek sunucu, sade masa, şehir haberleri.', Prop.newsDesk, 0.5, 0.85, 1),
    FormatDef('Ana haber', 'Dev ekranlar, dönen dünya, ülke gündemi.', Prop.globe, 1, 1.0, 1),
    FormatDef('Tartışma programı', 'Dört konuk, sıcak gündem, yüksek ses!', Prop.debate, 1.6, 1.12, 2),
    FormatDef('Sahadan canlı', 'Canlı yayın aracıyla olay yerinden bağlantı.', Prop.field, 2.5, 1.25, 3, reqEquip: 'ob'),
    FormatDef('Seçim gecesi', 'Canlı sonuçlar, grafikler, sabaha kadar yayın.', Prop.election, 4, 1.38, 4),
  ],
  Genre.magazin: [
    FormatDef('Stüdyo magazini', 'İki sunucu, bol dedikodu.', Prop.gossip, 0.5, 0.85, 1),
    FormatDef('Kırmızı halı', 'Ünlülerin geçidi, flaş patlamaları.', Prop.redCarpet, 1, 1.0, 1),
    FormatDef('Paparazzi takibi', 'Gece sokaklarda ünlü avı.', Prop.paparazzi, 1.8, 1.15, 2),
    FormatDef('Ödül gecesi', 'Yılın yıldızlarına ödüller, canlı tören.', Prop.awards, 3.5, 1.32, 4),
  ],
  Genre.talkShow: [
    FormatDef('Sabah kuşağı', 'Mutfakta kahve eşliğinde sohbet.', Prop.morning, 0.5, 0.85, 1),
    FormatDef('Gece talk show', 'Şehir manzarası, ünlü konuklar, esprili sunucu.', Prop.nightShow, 1, 1.0, 1),
    FormatDef('Stand-up gecesi', 'Tuğla duvar, tek spot, bol kahkaha.', Prop.standup, 1.6, 1.12, 2),
    FormatDef('Skeç şovu', 'Kostümlü komedi skeçleri.', Prop.sketch, 2.6, 1.25, 3),
    FormatDef('Yılbaşı özel', 'Havai fişekler, dev kadro, rekor reyting.', Prop.newYear, 4.5, 1.4, 4),
  ],
  Genre.belgesel: [
    FormatDef('Doğa belgeseli', 'Dağlar, ormanlar, vahşi yaşam.', Prop.nature, 1, 1.0, 1),
    FormatDef('Okyanus belgeseli', 'Mercanlar ve derin deniz canlıları.', Prop.ocean, 1.6, 1.15, 2),
    FormatDef('Tarih belgeseli', 'Antik kentlerin sırları.', Prop.history, 2.4, 1.25, 3),
    FormatDef('Uzay belgeseli', 'Gezegenler, roketler, sonsuz evren.', Prop.space, 4, 1.4, 4),
  ],
  Genre.spor: [
    FormatDef('Spor bülteni', 'Günün skorları ve yorumları.', Prop.sportsDesk, 0.5, 0.85, 1),
    FormatDef('Futbol maçı', 'Canlı lig maçı yayını.', Prop.football, 1, 1.0, 1),
    FormatDef('Basketbol maçı', 'Parkede heyecan, son saniye basketleri.', Prop.basketball, 1.6, 1.12, 2),
    FormatDef('Derbi gecesi', 'Meşaleler, dev tribün, yılın maçı.', Prop.derby, 3, 1.3, 3),
    FormatDef('Uluslararası turnuva', 'Kıtalar arası kupa yayın hakları.', Prop.tournament, 5, 1.45, 5),
  ],
  Genre.cocuk: [
    FormatDef('Çizgi film kuşağı', 'Sevimli karakterler, ucuz ve sürekli.', Prop.cartoon, 0.5, 0.85, 1),
    FormatDef('Kukla tiyatrosu', 'Çocukların bayıldığı kukla gösterisi.', Prop.puppet, 1, 1.0, 1),
    FormatDef('Bilim atölyesi', 'Fokurdayan deneyler, eğlenceli bilim.', Prop.lab, 1.6, 1.12, 2),
    FormatDef('Çocuk şarkı yarışması', 'Gökkuşağı sahnesinde minik sesler.', Prop.kidsStage, 2.5, 1.25, 3),
  ],
};

FormatDef formatOf(Genre g, int tier) {
  final l = genreFormats[g]!;
  return l[tier.clamp(0, l.length - 1)];
}

// =====================================================================
// DİJİTAL: video platformu "Videom" ve içerik üreticileri (kurgusal)
// =====================================================================
enum Niche { oyun, yemek, komedi, vlog, teknoloji, guzellik, muzik, spor }

extension NicheX on Niche {
  String get label => const [
        'Oyun', 'Yemek', 'Komedi', 'Vlog', 'Teknoloji', 'Güzellik', 'Müzik', 'Spor'
      ][index];
  IconData get icon => const [
        Icons.sports_esports_rounded,
        Icons.restaurant_rounded,
        Icons.mood_rounded,
        Icons.flight_rounded,
        Icons.memory_rounded,
        Icons.brush_rounded,
        Icons.headphones_rounded,
        Icons.fitness_center_rounded,
      ][index];
  Color get color => const [
        AppColors.purple, AppColors.orange, AppColors.yellow, AppColors.cyan,
        AppColors.blue, AppColors.pink, AppColors.accent, AppColors.green,
      ][index];
  String get handleWord => const [
        'oyunda', 'mutfakta', 'gulduruyor', 'yolda', 'teknolojik', 'guzellik',
        'muzik', 'formda'
      ][index];
}

const videoPlatformName = 'Videom';

// =====================================================================
// Rakip kanallar (reyting raporu için yapay rakipler) ve sponsor markaları
// =====================================================================
class RivalDef {
  final String name;
  final double strength; // prime time'daki tipik reyting (%)
  final Color color;
  const RivalDef(this.name, this.strength, this.color);
}

const rivalDefs = [
  RivalDef('Martı TV', 1.4, AppColors.blue),
  RivalDef('Pusula TV', 2.0, AppColors.teal),
  RivalDef('Telesim', 3.0, AppColors.orange),
  RivalDef('Kuzey 24', 3.6, AppColors.red),
  RivalDef('Mavi Ekran', 5.0, AppColors.purple),
  RivalDef('Yıldız Kanal', 6.4, AppColors.yellow),
  RivalDef('Nova Türk', 8.0, AppColors.pink),
  RivalDef('Ufuk Global', 9.5, AppColors.green),
];

const sponsorBrands = [
  'Fırtına Cola', 'Köpük Deterjan', 'Lezzet Çikolata', 'Hızlı Kargo',
  'Mavi Banka', 'Çıtır Cips', 'Parla Diş Macunu', 'Rüzgâr Turizm',
  'Bulut Telekom', 'Sıcak Fırın Bisküvi',
];

// =====================================================================
// MEDYA BORSASI: kurgusal şirket hisseleri
// =====================================================================
class StockDef {
  final String ticker;
  final String name;
  final String sector;
  final double basePrice;
  final double shares; // toplam hisse adedi
  final double volatility; // günlük oynaklık
  final Color color;
  const StockDef(this.ticker, this.name, this.sector, this.basePrice,
      this.shares, this.volatility, this.color);
}

const stockDefs = [
  StockDef('MRTV', 'Martı TV', 'Yerel yayın', 4.2, 30e6, 0.045, AppColors.blue),
  StockDef('PSLA', 'Pusula Medya', 'Yerel yayın', 7.8, 40e6, 0.04, AppColors.teal),
  StockDef('TLSM', 'Telesim', 'Bölgesel yayın', 18.5, 80e6, 0.035, AppColors.orange),
  StockDef('KZY24', 'Kuzey 24 Haber', 'Haber', 26.0, 120e6, 0.03, AppColors.red),
  StockDef('MVEK', 'Mavi Ekran Grubu', 'Ulusal yayın', 54.0, 250e6, 0.028, AppColors.purple),
  StockDef('YLDZ', 'Yıldız Kanal', 'Eğlence', 88.0, 400e6, 0.03, AppColors.yellow),
  StockDef('NOVA', 'Nova Türk Yapım', 'Dizi yapımı', 140.0, 600e6, 0.032, AppColors.pink),
  StockDef('UFUK', 'Ufuk Global', 'Uluslararası', 320.0, 1.2e9, 0.025, AppColors.green),
  StockDef('SYRL', 'Seyirlik Dijital', 'Dijital platform', 12.0, 150e6, 0.055, AppColors.teal),
  StockDef('AKIS', 'Akış+ Teknoloji', 'Dijital platform', 45.0, 300e6, 0.05, AppColors.accent),
  StockDef('GLKS', 'Galaksi Play', 'Dijital platform', 210.0, 900e6, 0.045, AppColors.blue),
  StockDef('VDOM', 'Videom', 'Video platformu', 95.0, 1.5e9, 0.06, AppColors.accent),
  StockDef('BYZP', 'Beyazperde Sinemaları', 'Sinema', 22.0, 100e6, 0.035, AppColors.red),
  StockDef('NOTA', 'Nota Müzik', 'Müzik', 9.5, 60e6, 0.04, AppColors.yellow),
  StockDef('REKL', 'Reklamix Ajans', 'Reklam', 31.0, 90e6, 0.038, AppColors.orange),
  StockDef('UYDU', 'Yörünge Uydu', 'Altyapı', 480.0, 2e9, 0.022, AppColors.cyan),
];

/// Zenginler listesindeki kurgusal patronlar (online'da gerçek oyuncular gelecek)
const tycoonFirms = [
  'Holding', 'Medya Grubu', 'Yatırım', 'Yapım', 'Grup', 'Global', 'Medya',
];
