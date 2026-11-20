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
  StudioLevel('Yerel Stüdyo', 0.20, 0, 8000, 8),
  StudioLevel('Bölgesel Stüdyo', 0.35, 3000000, 20000, 14),
  StudioLevel('Ulusal Kanal', 0.50, 12000000, 50000, 22),
  StudioLevel('Büyük Plato', 0.65, 40000000, 120000, 32),
  StudioLevel('Medya Kampüsü', 0.82, 120000000, 300000, 45),
  StudioLevel('Medya İmparatorluğu', 1.00, 400000000, 700000, 60),
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
