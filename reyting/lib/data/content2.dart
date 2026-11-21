import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'content.dart';

// =====================================================================
// v0.12 İÇERİKLERİ — hepsi kurgusal.
// Şirket kimliği, prodüksiyon bütçesi, ünlü konuklar, uzmanlıklar,
// çekim lokasyonları (Türkiye + dünya), yetenek ajansı, yönetim kurulu,
// marka teklifleri ve senaryo kararları.
// =====================================================================

// ---------------------------------------------------------------------
// Şirket kimliği ve logo
// ---------------------------------------------------------------------
const companySuffixes = [
  'Yapım',
  'Yapım A.Ş.',
  'Film',
  'Film Yapım',
  'Medya',
  'Medya Grubu',
  'Prodüksiyon',
  'Stüdyoları',
  'Yapımevi',
  'Sinema',
  'Televizyon',
  'Yayıncılık',
  'Eğlence',
  'Holding',
  'Kreatif',
  'Ajans',
];

const companyNameIdeas = [
  'Ay',
  'Rüzgâr',
  'Esmer',
  'Yıldız',
  'Martı',
  'Çınar',
  'Poyraz',
  'Lodos',
  'Kartal',
  'Mavi',
  'Gökkuşağı',
  'Anka',
  'Deniz',
  'Toros',
  'Kapadokya',
  'Boğaz',
  'Gümüş',
  'Altın Kare',
  'Sarmaşık',
  'Kervan',
  'Fener',
  'Pusula',
];

/// Logo sembolleri (kod ile çizilir)
const logoShapeNames = [
  'Hilal',
  'Güneş',
  'Yıldız',
  'Rüzgâr',
  'Dalga',
  'Dağ',
  'Alev',
  'Elmas',
  'Taç',
  'Kanat',
  'Kalp',
  'Şimşek',
  'Yaprak',
  'Göz',
  'Film şeridi',
  'Kamera',
  'Mikrofon',
  'Nota',
  'Kalkan',
  'Çark',
  'Atom',
  'Kelebek',
  'Ok',
  'Sonsuzluk',
  'Kule',
  'Lale',
  'Martı',
  'Pusula',
];

/// Logo renk paletleri (ana, ikincil)
const logoPalettes = <List<Color>>[
  [Color(0xFFFF5C7A), Color(0xFFFF8F5C)],
  [Color(0xFF4FD1FF), Color(0xFF7C5CFF)],
  [Color(0xFFFFD25C), Color(0xFFFF8F5C)],
  [Color(0xFF3DDC97), Color(0xFF4FD1FF)],
  [Color(0xFFB57CFF), Color(0xFFFF5CC8)],
  [Color(0xFFFFFFFF), Color(0xFFB0B0C8)],
  [Color(0xFFE53935), Color(0xFF1A1A1A)],
  [Color(0xFF1E88E5), Color(0xFFFFFFFF)],
  [Color(0xFFD4AF37), Color(0xFF3B2A12)],
  [Color(0xFF00BFA5), Color(0xFF004D40)],
  [Color(0xFFFF7043), Color(0xFF5D4037)],
  [Color(0xFF8BC34A), Color(0xFF33691E)],
  [Color(0xFFF06292), Color(0xFF880E4F)],
  [Color(0xFF90A4AE), Color(0xFF263238)],
];

const logoFrameNames = [
  'Çerçevesiz',
  'Daire',
  'Kare',
  'Kalkan',
  'Altıgen',
  'Yıldız ışığı',
];

int get logoCombinations =>
    logoShapeNames.length * logoPalettes.length * logoFrameNames.length;

// ---------------------------------------------------------------------
// Prodüksiyon bütçesi (formatın üstüne)
// ---------------------------------------------------------------------
class ProdBudget {
  final String label;
  final String desc;
  final double costMult;
  final double qualityMult;
  final int unlockLevel; // stüdyo seviyesi
  final double share; // yayın gelirinden bölüm başı giden pay
  const ProdBudget(
    this.label,
    this.desc,
    this.costMult,
    this.qualityMult,
    this.unlockLevel,
    this.share,
  );
}

const prodBudgets = [
  ProdBudget('Düşük', 'Tek kamera, az ışık, sade dekor.', 0.6, 0.88, 1, 0),
  ProdBudget('Standart', 'Olması gerektiği gibi.', 1.0, 1.0, 1, 0),
  ProdBudget(
    'Yüksek',
    'Ek kameralar, büyük dekor, kalabalık ekip.',
    1.8,
    1.11,
    2,
    0.08,
  ),
  ProdBudget(
    'Premium',
    'Vinçler, LED duvarlar, özel efektler.',
    3.2,
    1.22,
    4,
    0.16,
  ),
  ProdBudget(
    'Mega yapım',
    'Dünya standartlarında dev prodüksiyon.',
    6.0,
    1.33,
    6,
    0.23,
  ),
];

// ---------------------------------------------------------------------
// Ünlü konuklar (kurgusal isimler)
// ---------------------------------------------------------------------
class GuestTier {
  final String label;
  final double feeMult; // prodüksiyon maliyetine oranla sezonluk ücret
  final double boost; // reyting çarpanı artışı
  final int unlockLevel;
  final List<String> names;
  final double share; // yayın gelirinden konuk payı
  const GuestTier(
    this.label,
    this.feeMult,
    this.boost,
    this.unlockLevel,
    this.share,
    this.names,
  );
}

const guestTiers = [
  GuestTier('Yok', 0, 0, 1, 0, []),
  GuestTier('Yerel ünlü', 0.2, 0.05, 1, 0.025, [
    'Mahalle muhtarı Cemal',
    'Yöresel türkücü Hatice',
    'Esnaf komiği Rıza',
    'Yerel spiker Nevin',
  ]),
  GuestTier('Tanınan yüz', 0.45, 0.11, 2, 0.06, [
    'Dizi oyuncusu Burak Er',
    'Şarkıcı Selin Akça',
    'Şef Doğan Usta',
    'Komedyen Tolga Kaya',
  ]),
  GuestTier('Ünlü', 0.9, 0.18, 3, 0.09, [
    'Pop yıldızı Ece Ilgaz',
    'Film yıldızı Kerem Sancak',
    'Rock grubu Kuzey Rüzgârı',
    'Sunucu Neşe Aral',
  ]),
  GuestTier('Süperstar', 1.7, 0.26, 5, 0.12, [
    'Megastar Derin Yıldız',
    'Efsane futbolcu Arda Çelik',
    'Diva Leyla Saray',
    'Oscar adayı Mert Ateş',
  ]),
  GuestTier('Dünya yıldızı', 3.0, 0.35, 7, 0.15, [
    'Global pop ikonu Nova Reyes',
    'Hollywood yıldızı Jack Moreau',
    'K-pop grubu STARLINE',
    'Süper model Ana Lund',
  ]),
];

String guestLabelFor(Genre g) => switch (g) {
  Genre.dizi => 'Konuk oyuncu',
  Genre.yarisma => 'Ünlü jüri',
  Genre.haber => 'Uzman konuk',
  Genre.magazin => 'Ünlü konuk',
  Genre.talkShow => 'Ünlü konuk',
  Genre.belgesel => 'Ünlü anlatıcı',
  Genre.spor => 'Yıldız yorumcu',
  Genre.cocuk => 'Ünlü maskot sesi',
};

// ---------------------------------------------------------------------
// Uzmanlıklar ve karakter özellikleri
// ---------------------------------------------------------------------
class SpecDef {
  final String label;
  final Set<Genre> genres;
  final Set<FilmGenre> films;
  const SpecDef(this.label, this.genres, this.films);
}

const specsByRole = <Role, List<SpecDef>>{
  Role.senarist: [
    SpecDef('Dram yazarı', {Genre.dizi}, {FilmGenre.dram}),
    SpecDef('Komedi yazarı', {Genre.talkShow, Genre.cocuk}, {FilmGenre.komedi}),
    SpecDef('Polisiye yazarı', {Genre.dizi, Genre.haber}, {FilmGenre.aksiyon}),
    SpecDef('Format yaratıcısı', {Genre.yarisma, Genre.magazin}, {}),
    SpecDef('Belgesel yazarı', {Genre.belgesel}, {}),
    SpecDef('Masal yazarı', {Genre.cocuk}, {FilmGenre.animasyon}),
    SpecDef('Gerilim yazarı', {}, {FilmGenre.korku, FilmGenre.bilimKurgu}),
    SpecDef('Aşk romanı yazarı', {Genre.dizi}, {FilmGenre.romantik}),
  ],
  Role.yonetmen: [
    SpecDef(
      'Dizi yönetmeni',
      {Genre.dizi},
      {FilmGenre.dram, FilmGenre.romantik},
    ),
    SpecDef('Canlı yayın yönetmeni', {
      Genre.yarisma,
      Genre.spor,
      Genre.haber,
    }, {}),
    SpecDef('Sinema yönetmeni', {}, {
      FilmGenre.aksiyon,
      FilmGenre.dram,
      FilmGenre.bilimKurgu,
    }),
    SpecDef('Belgeselci', {Genre.belgesel}, {}),
    SpecDef('Klip yönetmeni', {Genre.magazin, Genre.talkShow}, {}),
    SpecDef('Aksiyon yönetmeni', {}, {FilmGenre.aksiyon, FilmGenre.bilimKurgu}),
    SpecDef('Animasyon yönetmeni', {Genre.cocuk}, {FilmGenre.animasyon}),
    SpecDef('Korku ustası', {}, {FilmGenre.korku}),
  ],
  Role.oyuncu: [
    SpecDef('Dram oyuncusu', {Genre.dizi}, {FilmGenre.dram}),
    SpecDef('Komedyen', {Genre.talkShow}, {FilmGenre.komedi}),
    SpecDef('Aksiyon yıldızı', {}, {FilmGenre.aksiyon, FilmGenre.bilimKurgu}),
    SpecDef('Romantik başrol', {Genre.dizi}, {FilmGenre.romantik}),
    SpecDef('Çocuk oyuncu', {Genre.cocuk}, {FilmGenre.animasyon}),
    SpecDef('Karakter oyuncusu', {Genre.dizi}, {FilmGenre.korku}),
    SpecDef(
      'Seslendirme sanatçısı',
      {Genre.cocuk, Genre.belgesel},
      {FilmGenre.animasyon},
    ),
    SpecDef('Tiyatrocu', {Genre.dizi, Genre.talkShow}, {FilmGenre.dram}),
    SpecDef('Dublör', {}, {FilmGenre.aksiyon}),
  ],
  Role.sunucu: [
    SpecDef('Haber spikeri', {Genre.haber}, {}),
    SpecDef('Şovmen', {Genre.yarisma, Genre.talkShow}, {}),
    SpecDef('Spor yorumcusu', {Genre.spor}, {}),
    SpecDef('Magazin muhabiri', {Genre.magazin}, {}),
    SpecDef('Sabah sunucusu', {Genre.talkShow, Genre.magazin}, {}),
    SpecDef('Çocuk sunucusu', {Genre.cocuk}, {}),
    SpecDef('Jüri üyesi', {Genre.yarisma}, {}),
    SpecDef('Belgesel anlatıcısı', {Genre.belgesel}, {}),
    SpecDef('Savaş muhabiri', {Genre.haber, Genre.belgesel}, {}),
  ],
};

class TraitDef {
  final String label;
  final String emoji;
  final String desc;
  const TraitDef(this.label, this.emoji, this.desc);
}

/// 0: özelliksiz
const traitDefs = [
  TraitDef('Sıradan', '', ''),
  TraitDef('Disiplinli', '⏱️', 'Programa +%3 kalite'),
  TraitDef('Karizmatik', '✨', 'Şöhreti 2 kat hızlı büyür'),
  TraitDef('Hızlı öğrenen', '📚', 'Eğitimden %50 fazla gelişir'),
  TraitDef('Fenomen', '📱', 'Sosyal medyada çok sevilir: +şöhret'),
  TraitDef('Sadık', '🤝', 'Rakip teklifleri reddeder, zam istemez'),
  TraitDef('Huysuz yıldız', '😤', 'Yetenekli ama sette kriz çıkarır'),
  TraitDef('Çok yönlü', '🎭', 'Her türde yarım uzmanlık bonusu'),
  TraitDef('Doğal yetenek', '🌟', 'Genç yetenek: potansiyeline hızla ulaşır'),
];

// ---------------------------------------------------------------------
// Çekim lokasyonları: Türkiye haritası + dünya haritası
// ---------------------------------------------------------------------
class EventDef {
  final String name;
  final String desc;
  final double costMult; // lokasyon fiyatına oranla
  final int cooldown; // gün
  final int prestige;
  const EventDef(
    this.name,
    this.desc,
    this.costMult,
    this.cooldown,
    this.prestige,
  );
}

class LocationDef {
  final String id;
  final String name;
  final String city;
  final bool world;
  final double lon, lat;
  final String desc;
  final double price;
  final double upkeep;
  final int reqLevel;
  final Set<Genre> genres;
  final Set<FilmGenre> films;
  final double bonus; // uyumlu türde kalite bonusu
  final int prestige;
  final IconData icon;
  final Color color;
  final EventDef? event;
  final String? reqEquip;
  const LocationDef({
    required this.id,
    required this.name,
    required this.city,
    required this.world,
    required this.lon,
    required this.lat,
    required this.desc,
    required this.price,
    required this.upkeep,
    required this.reqLevel,
    required this.genres,
    required this.films,
    required this.bonus,
    required this.prestige,
    required this.icon,
    required this.color,
    this.event,
    this.reqEquip,
  });
}

const locationDefs = [
  // ---- Türkiye ----
  LocationDef(
    id: 'ist',
    name: 'Boğaz Setleri',
    city: 'İstanbul',
    world: false,
    lon: 29.0,
    lat: 41.05,
    desc: 'Yalılar, vapurlar, gece manzarası. Dizilerin ve magazinin kalbi.',
    price: 1.2e6,
    upkeep: 6000,
    reqLevel: 1,
    genres: {Genre.dizi, Genre.magazin, Genre.talkShow},
    films: {FilmGenre.romantik, FilmGenre.dram},
    bonus: 0.08,
    prestige: 10,
    icon: Icons.location_city_rounded,
    color: AppColors.pink,
    event: EventDef('Boğazda gala', 'Yeni sezon tanıtım galası', 0.35, 10, 12),
  ),
  LocationDef(
    id: 'ege',
    name: 'Ege Koyları',
    city: 'İzmir',
    world: false,
    lon: 26.9,
    lat: 38.4,
    desc: 'Zeytinlikler, begonvilli sokaklar. Komedi ve romantik yapımlar için ideal.',
    price: 2.5e6,
    upkeep: 9000,
    reqLevel: 2,
    genres: {Genre.yarisma, Genre.talkShow},
    films: {FilmGenre.komedi, FilmGenre.romantik},
    bonus: 0.09,
    prestige: 12,
    icon: Icons.beach_access_rounded,
    color: AppColors.cyan,
  ),
  LocationDef(
    id: 'akdeniz',
    name: 'Akdeniz Adaları',
    city: 'Antalya',
    world: false,
    lon: 30.7,
    lat: 36.75,
    desc: 'Issız koylar ve adalar. Ada yarışmaları ve aksiyon sahneleri.',
    price: 6e6,
    upkeep: 20000,
    reqLevel: 3,
    genres: {Genre.yarisma, Genre.spor},
    films: {FilmGenre.aksiyon, FilmGenre.romantik},
    bonus: 0.11,
    prestige: 18,
    icon: Icons.sailing_rounded,
    color: AppColors.blue,
  ),
  LocationDef(
    id: 'kapadokya',
    name: 'Peri Bacaları',
    city: 'Kapadokya',
    world: false,
    lon: 34.8,
    lat: 38.6,
    desc: 'Balonlar, kayadan evler. Masalsı ve fantastik çekimler.',
    price: 4e6,
    upkeep: 15000,
    reqLevel: 3,
    genres: {Genre.belgesel, Genre.dizi},
    films: {FilmGenre.bilimKurgu, FilmGenre.romantik},
    bonus: 0.10,
    prestige: 16,
    icon: Icons.air_rounded,
    color: AppColors.orange,
    event: EventDef(
      'Balon festivali yayını',
      'Gün doğumunda yüzlerce balon',
      0.4,
      12,
      15,
    ),
  ),
  LocationDef(
    id: 'karadeniz',
    name: 'Yayla Evleri',
    city: 'Karadeniz',
    world: false,
    lon: 40.5,
    lat: 40.85,
    desc: 'Sisli yaylalar, ahşap evler. Duygusal dramların vazgeçilmezi.',
    price: 3e6,
    upkeep: 11000,
    reqLevel: 2,
    genres: {Genre.dizi, Genre.belgesel},
    films: {FilmGenre.dram},
    bonus: 0.10,
    prestige: 12,
    icon: Icons.forest_rounded,
    color: AppColors.green,
  ),
  LocationDef(
    id: 'dogu',
    name: 'Doğu Dağları',
    city: 'Van · Ağrı',
    world: false,
    lon: 43.4,
    lat: 39.4,
    desc: 'Karlı zirveler, göller ve vahşi doğa. Doğa belgeselleri ve epik filmler.',
    price: 5e6,
    upkeep: 16000,
    reqLevel: 3,
    genres: {Genre.belgesel},
    films: {FilmGenre.dram, FilmGenre.aksiyon},
    bonus: 0.13,
    prestige: 18,
    icon: Icons.terrain_rounded,
    color: AppColors.cyan,
  ),
  LocationDef(
    id: 'mardin',
    name: 'Taş Konaklar',
    city: 'Mardin',
    world: false,
    lon: 40.7,
    lat: 37.3,
    desc: 'Taş sokaklar ve tarihi konaklar. Dönem dizileri ve tarih belgeselleri.',
    price: 4.5e6,
    upkeep: 14000,
    reqLevel: 4,
    genres: {Genre.dizi, Genre.belgesel},
    films: {FilmGenre.dram},
    bonus: 0.12,
    prestige: 18,
    icon: Icons.account_balance_rounded,
    color: AppColors.yellow,
  ),
  LocationDef(
    id: 'nemrut',
    name: 'Dev Heykeller',
    city: 'Nemrut',
    world: false,
    lon: 38.74,
    lat: 37.98,
    desc: 'Gizemli zirve. Korku ve gizem filmleri için tüyler ürpertici.',
    price: 7e6,
    upkeep: 20000,
    reqLevel: 4,
    genres: {Genre.belgesel},
    films: {FilmGenre.korku},
    bonus: 0.14,
    prestige: 20,
    icon: Icons.nightlight_round,
    color: AppColors.purple,
  ),
  LocationDef(
    id: 'ankara',
    name: 'Başkent Haber Merkezi',
    city: 'Ankara',
    world: false,
    lon: 32.85,
    lat: 39.93,
    desc: 'Meclis, bakanlıklar ve canlı bağlantılar. Haberin merkezi.',
    price: 3.5e6,
    upkeep: 12000,
    reqLevel: 2,
    genres: {Genre.haber},
    films: {},
    bonus: 0.12,
    prestige: 14,
    icon: Icons.podcasts_rounded,
    color: AppColors.blue,
  ),
  LocationDef(
    id: 'marmara',
    name: 'Marmara Dev Platoları',
    city: 'Kocaeli',
    world: false,
    lon: 29.9,
    lat: 40.75,
    desc: 'Yeşil perdeler, dev hangarlar. Uzay serüvenleri ve yüksek bütçeli aksiyon.',
    price: 25e6,
    upkeep: 60000,
    reqLevel: 5,
    genres: {Genre.cocuk, Genre.yarisma},
    films: {FilmGenre.bilimKurgu, FilmGenre.aksiyon, FilmGenre.animasyon},
    bonus: 0.15,
    prestige: 30,
    icon: Icons.rocket_launch_rounded,
    color: AppColors.accent,
  ),
  LocationDef(
    id: 'trakya',
    name: 'Trakya Ovaları',
    city: 'Edirne',
    world: false,
    lon: 26.6,
    lat: 41.7,
    desc: 'Uçsuz ovalar. Savaş sahneleri ve süvari çekimleri.',
    price: 5e6,
    upkeep: 15000,
    reqLevel: 4,
    genres: {Genre.dizi, Genre.spor},
    films: {FilmGenre.aksiyon},
    bonus: 0.11,
    prestige: 16,
    icon: Icons.grass_rounded,
    color: AppColors.green,
  ),
  LocationDef(
    id: 'pamukkale',
    name: 'Beyaz Travertenler',
    city: 'Pamukkale',
    world: false,
    lon: 29.12,
    lat: 37.92,
    desc: 'Bembeyaz teraslar. Klip, reklam ve romantik çekimler.',
    price: 3.2e6,
    upkeep: 11000,
    reqLevel: 3,
    genres: {Genre.magazin},
    films: {FilmGenre.romantik},
    bonus: 0.10,
    prestige: 14,
    icon: Icons.water_rounded,
    color: AppColors.cyan,
  ),
  // ---- Dünya ----
  LocationDef(
    id: 'paris',
    name: 'Moda Podyumu',
    city: 'Paris',
    world: true,
    lon: 2.35,
    lat: 48.86,
    desc: 'Moda haftası, ışıltılı podyumlar ve aşk şehri.',
    price: 60e6,
    upkeep: 150000,
    reqLevel: 5,
    genres: {Genre.magazin},
    films: {FilmGenre.romantik},
    bonus: 0.15,
    prestige: 45,
    icon: Icons.checkroom_rounded,
    color: AppColors.pink,
    event: EventDef(
      'Moda haftasında podyum',
      'Kendi defilen, dünya basını',
      0.25,
      14,
      40,
    ),
  ),
  LocationDef(
    id: 'londra',
    name: 'Sisli Sokaklar',
    city: 'Londra',
    world: true,
    lon: -0.12,
    lat: 51.5,
    desc: 'Polisiye ve dönem dizileri için klasik atmosfer.',
    price: 55e6,
    upkeep: 140000,
    reqLevel: 5,
    genres: {Genre.dizi, Genre.haber},
    films: {FilmGenre.dram, FilmGenre.korku},
    bonus: 0.14,
    prestige: 40,
    icon: Icons.cloud_rounded,
    color: AppColors.textDim,
  ),
  LocationDef(
    id: 'ny',
    name: 'Gökdelen Stüdyoları',
    city: 'New York',
    world: true,
    lon: -74.0,
    lat: 40.7,
    desc: 'Gece talk show\'ları, canlı haber ve dev ekranlar.',
    price: 90e6,
    upkeep: 220000,
    reqLevel: 6,
    genres: {Genre.talkShow, Genre.haber},
    films: {FilmGenre.komedi},
    bonus: 0.16,
    prestige: 55,
    icon: Icons.apartment_rounded,
    color: AppColors.yellow,
    event: EventDef(
      'Gala gecesi',
      'Dünya basınına özel gösterim',
      0.25,
      14,
      45,
    ),
  ),
  LocationDef(
    id: 'la',
    name: 'Tepe Platoları',
    city: 'Los Angeles',
    world: true,
    lon: -118.24,
    lat: 34.05,
    desc: 'Dünyanın film başkenti. Aksiyon, bilim kurgu, animasyon.',
    price: 180e6,
    upkeep: 400000,
    reqLevel: 7,
    genres: {Genre.cocuk},
    films: {FilmGenre.aksiyon, FilmGenre.bilimKurgu, FilmGenre.animasyon},
    bonus: 0.2,
    prestige: 80,
    icon: Icons.movie_creation_rounded,
    color: AppColors.accent2,
    event: EventDef(
      'Kırmızı halı ödül gecesi',
      'Filmlerin dünya ödüllerine aday',
      0.2,
      20,
      70,
    ),
  ),
  LocationDef(
    id: 'tokyo',
    name: 'Neon Şehir',
    city: 'Tokyo',
    world: true,
    lon: 139.7,
    lat: 35.7,
    desc: 'Neon ışıklar, robotlar ve animasyon kültürü.',
    price: 85e6,
    upkeep: 200000,
    reqLevel: 6,
    genres: {Genre.cocuk, Genre.yarisma},
    films: {FilmGenre.animasyon, FilmGenre.bilimKurgu},
    bonus: 0.17,
    prestige: 50,
    icon: Icons.light_rounded,
    color: AppColors.purple,
    event: EventDef(
      'Animasyon fuarı',
      'Karakterlerin lisansları satılır',
      0.25,
      14,
      35,
    ),
  ),
  LocationDef(
    id: 'seul',
    name: 'Dizi Fuarı',
    city: 'Seul',
    world: true,
    lon: 126.98,
    lat: 37.57,
    desc: 'Dünyanın en büyük dizi pazarı. Dizilerini yurt dışına sat.',
    price: 70e6,
    upkeep: 170000,
    reqLevel: 6,
    genres: {Genre.dizi},
    films: {FilmGenre.romantik},
    bonus: 0.15,
    prestige: 45,
    icon: Icons.storefront_rounded,
    color: AppColors.cyan,
    event: EventDef(
      'Yurt dışına dizi satışı',
      'Dizilerinin yabancı yayın hakları',
      0.3,
      12,
      30,
    ),
  ),
  LocationDef(
    id: 'dubai',
    name: 'Çöl Sarayı',
    city: 'Dubai',
    world: true,
    lon: 55.27,
    lat: 25.2,
    desc: 'Lüks yarışmalar, çöl rallileri ve şaşaalı galalar.',
    price: 75e6,
    upkeep: 180000,
    reqLevel: 6,
    genres: {Genre.yarisma, Genre.magazin},
    films: {FilmGenre.aksiyon},
    bonus: 0.15,
    prestige: 50,
    icon: Icons.diamond_rounded,
    color: AppColors.yellow,
    event: EventDef(
      'Lüks gala',
      'Dünyanın zenginleri tek salonda',
      0.25,
      14,
      40,
    ),
  ),
  LocationDef(
    id: 'rio',
    name: 'Karnaval Sahili',
    city: 'Rio',
    world: true,
    lon: -43.2,
    lat: -22.9,
    desc: 'Samba, futbol ve renk cümbüşü.',
    price: 50e6,
    upkeep: 130000,
    reqLevel: 5,
    genres: {Genre.spor, Genre.talkShow},
    films: {FilmGenre.komedi},
    bonus: 0.14,
    prestige: 35,
    icon: Icons.celebration_rounded,
    color: AppColors.green,
    event: EventDef(
      'Karnaval canlı yayını',
      'Dünyaya canlı yayın hakları',
      0.3,
      14,
      30,
    ),
  ),
  LocationDef(
    id: 'safari',
    name: 'Savan Kampı',
    city: 'Kenya',
    world: true,
    lon: 36.8,
    lat: -1.3,
    desc: 'Aslanlar, filler, büyük göç. Belgeselin zirvesi.',
    price: 45e6,
    upkeep: 120000,
    reqLevel: 5,
    genres: {Genre.belgesel},
    films: {FilmGenre.aksiyon},
    bonus: 0.2,
    prestige: 35,
    icon: Icons.pets_rounded,
    color: AppColors.orange,
  ),
  LocationDef(
    id: 'kahire',
    name: 'Piramitler',
    city: 'Kahire',
    world: true,
    lon: 31.2,
    lat: 30.0,
    desc: 'Antik sırlar, çöl maceraları.',
    price: 50e6,
    upkeep: 125000,
    reqLevel: 5,
    genres: {Genre.belgesel, Genre.dizi},
    films: {FilmGenre.aksiyon, FilmGenre.korku},
    bonus: 0.15,
    prestige: 35,
    icon: Icons.change_history_rounded,
    color: AppColors.yellow,
  ),
  LocationDef(
    id: 'izlanda',
    name: 'Buz Vadisi',
    city: 'İzlanda',
    world: true,
    lon: -21.9,
    lat: 64.1,
    desc: 'Başka bir gezegen gibi: buzullar, volkanlar, kutup ışıkları.',
    price: 80e6,
    upkeep: 190000,
    reqLevel: 6,
    genres: {Genre.belgesel},
    films: {FilmGenre.bilimKurgu, FilmGenre.korku},
    bonus: 0.18,
    prestige: 50,
    icon: Icons.ac_unit_rounded,
    color: AppColors.cyan,
  ),
  LocationDef(
    id: 'yz',
    name: 'Fantastik Vadiler',
    city: 'Yeni Zelanda',
    world: true,
    lon: 174.8,
    lat: -41.3,
    desc: 'Destansı manzaralar, fantastik dünyalar.',
    price: 150e6,
    upkeep: 330000,
    reqLevel: 7,
    genres: {Genre.dizi},
    films: {FilmGenre.aksiyon, FilmGenre.bilimKurgu},
    bonus: 0.2,
    prestige: 70,
    icon: Icons.landscape_rounded,
    color: AppColors.green,
  ),
  LocationDef(
    id: 'antarktika',
    name: 'Kutup Üssü',
    city: 'Antarktika',
    world: true,
    lon: 0,
    lat: -75,
    desc: 'Dünyanın en zor çekimi. Helikopter şart.',
    price: 300e6,
    upkeep: 600000,
    reqLevel: 8,
    genres: {Genre.belgesel},
    films: {FilmGenre.bilimKurgu},
    bonus: 0.25,
    prestige: 100,
    icon: Icons.severe_cold_rounded,
    color: AppColors.blue,
    reqEquip: 'heli',
  ),
];

LocationDef? locationById(String? id) {
  if (id == null) return null;
  for (final l in locationDefs) {
    if (l.id == id) return l;
  }
  return null;
}

// ---------------------------------------------------------------------
// Yetenek ajansı
// ---------------------------------------------------------------------
class AgencyLevel {
  final String name;
  final double cost;
  final int scouts; // günlük genç yetenek sayısı
  final int maxPotential;
  final int academySlots;
  final double growth; // gelişim hızı çarpanı
  final int transferList; // transfer pazarındaki oyuncu sayısı
  const AgencyLevel(
    this.name,
    this.cost,
    this.scouts,
    this.maxPotential,
    this.academySlots,
    this.growth,
    this.transferList,
  );
}

const agencyLevels = [
  AgencyLevel('Kapalı', 0, 0, 0, 0, 0, 0),
  AgencyLevel('Küçük ofis', 1e6, 2, 70, 3, 1.0, 2),
  AgencyLevel('Menajerlik bürosu', 4e6, 3, 76, 4, 1.15, 3),
  AgencyLevel('Oyunculuk okulu', 15e6, 3, 82, 6, 1.3, 4),
  AgencyLevel('Yetenek ajansı', 60e6, 4, 87, 8, 1.45, 5),
  AgencyLevel('Ulusal ajans', 250e6, 4, 91, 10, 1.6, 6),
  AgencyLevel('Yıldız fabrikası', 1e9, 5, 94, 12, 1.8, 7),
  AgencyLevel('Uluslararası ajans', 5e9, 5, 96, 15, 2.0, 8),
  AgencyLevel('Global yetenek ağı', 25e9, 6, 98, 18, 2.3, 9),
  AgencyLevel('Efsaneler akademisi', 120e9, 6, 99, 22, 2.6, 10),
];

// ---------------------------------------------------------------------
// Yönetim kurulu
// ---------------------------------------------------------------------
enum ExecRole { genelMudur, yayin, ik, pazarlama, finans, sinema, ajans, hukuk }

class ExecRoleDef {
  final String label;
  final String desc;
  final String auto; // otomatik yaptığı iş
  final IconData icon;
  final Color color;
  final int unlockLevel; // stüdyo seviyesi
  final double maxBonus;
  final String bonusLabel;
  const ExecRoleDef(
    this.label,
    this.desc,
    this.auto,
    this.icon,
    this.color,
    this.unlockLevel,
    this.maxBonus,
    this.bonusLabel,
  );
}

const execDefs = <ExecRole, ExecRoleDef>{
  ExecRole.genelMudur: ExecRoleDef(
    'Genel Müdür',
    'Kanalın başı. Yayın gelirini artırır.',
    'Biten sezonları yeniler, aynı kuşağa geri koyar',
    Icons.business_center_rounded,
    AppColors.accent,
    1,
    0.08,
    'reklam geliri',
  ),
  ExecRole.yayin: ExecRoleDef(
    'Yayın Planlama Müdürü',
    'Akışı ve reklam sürelerini ayarlar.',
    'Hazır programları en iyi boş kuşağa koyar, reklam süresini ayarlar',
    Icons.view_timeline_rounded,
    AppColors.cyan,
    2,
    0.06,
    'reyting',
  ),
  ExecRole.ik: ExecRoleDef(
    'İnsan Kaynakları Müdürü',
    'İşe alım ve maaş pazarlıklarını yürütür.',
    'Kadroyu eğitime gönderir',
    Icons.badge_rounded,
    AppColors.blue,
    3,
    0.25,
    'imza ücreti indirimi',
  ),
  ExecRole.pazarlama: ExecRoleDef(
    'Pazarlama Müdürü',
    'Markalarla görüşür, anlaşmaları büyütür.',
    'En iyi marka tekliflerini kabul eder',
    Icons.campaign_rounded,
    AppColors.yellow,
    4,
    0.30,
    'marka geliri',
  ),
  ExecRole.finans: ExecRoleDef(
    'Finans Müdürü',
    'Giderleri kısar, kira ve bakım pazarlığı yapar.',
    'Kira ve bakım giderlerini düşürür',
    Icons.account_balance_wallet_rounded,
    AppColors.green,
    5,
    0.15,
    'gider indirimi',
  ),
  ExecRole.sinema: ExecRoleDef(
    'Sinema Müdürü',
    'Filmlerin vizyon ve lisans işlerini yürütür.',
    'Biten filmi vizyona sokar, vizyondan inen filmi platforma satar',
    Icons.local_movies_rounded,
    AppColors.orange,
    5,
    0.12,
    'gişe',
  ),
  ExecRole.ajans: ExecRoleDef(
    'Ajans Müdürü',
    'Genç yetenekleri yetiştirir, transferleri yönetir.',
    'İyi transfer tekliflerini kabul eder',
    Icons.star_rounded,
    AppColors.pink,
    6,
    0.5,
    'genç gelişimi',
  ),
  ExecRole.hukuk: ExecRoleDef(
    'Hukuk Müdürü',
    'Cezalar, davalar ve sözleşmeler.',
    'Yayın Kurulu cezalarını azaltır',
    Icons.gavel_rounded,
    AppColors.purple,
    7,
    0.6,
    'ceza indirimi',
  ),
};

// ---------------------------------------------------------------------
// Markalar (kurgusal) — prestij arttıkça büyük markalar gelir
// ---------------------------------------------------------------------
const brandTiers = <List<String>>[
  [
    'Köşe Bakkal Çay',
    'Mahalle Fırını',
    'Ucuz Dünya Market',
    'Pırıl Deterjan',
    'Sakız Pop',
  ],
  [
    'Serinlik Kola',
    'Altın Çikolata',
    'Hızlı Kargo',
    'Kumru Turizm',
    'Yudum Kahve',
    'Çıtır Cips',
  ],
  [
    'Mavi Hat GSM',
    'Volta Otomotiv',
    'Atlas Bank',
    'Zirve Sigorta',
    'Lezzet Burger',
    'Moda Park',
  ],
  [
    'Novatek Telefon',
    'Aurora Parfüm',
    'Gökyüzü Havayolları',
    'Titan Elektronik',
    'Prime Saat',
  ],
  [
    'Orion Global',
    'Lumière Lüks',
    'Zenith Motors',
    'Stellar Tech',
    'Royal Crown Mücevher',
  ],
];

enum DealKind { placement, adBlock, starFace, filmPlacement, channelSponsor }

extension DealKindX on DealKind {
  String get label => const [
    'Ürün yerleştirme',
    'Reklam kuşağı anlaşması',
    'Marka yüzü',
    'Filmde ürün yerleştirme',
    'Kanal sponsorluğu',
  ][index];
  IconData get icon => const [
    Icons.local_drink_rounded,
    Icons.view_week_rounded,
    Icons.face_retouching_natural_rounded,
    Icons.movie_rounded,
    Icons.workspace_premium_rounded,
  ][index];
}

// ---------------------------------------------------------------------
// Senaryo kararları (sadece oyun açıkken çıkar)
// ---------------------------------------------------------------------
class StoryOption {
  final String label;
  final int chance; // başarı ihtimali %
  final double win; // başarıda reyting çarpanı
  final double lose; // başarısızlıkta reyting çarpanı
  final int days;
  const StoryOption(this.label, this.chance, this.win, this.lose, this.days);
}

class StoryTemplate {
  final String title;
  final String body; // {a} {b}: oyuncu isimleri, {s}: program
  final List<StoryOption> options;
  const StoryTemplate(this.title, this.body, this.options);
}

const storyTemplates = <Genre, List<StoryTemplate>>{
  Genre.dizi: [
    StoryTemplate(
      '🎬 Sezon finali: kim ölsün?',
      '"{s}" finali yazılıyor. Senaristler kararını bekliyor.',
      [
        StoryOption('{a} ölsün', 45, 1.38, 0.85, 4),
        StoryOption('Kötü adam ölsün', 80, 1.14, 0.97, 3),
        StoryOption('Kimse ölmesin, düğün olsun', 65, 1.2, 0.93, 3),
      ],
    ),
    StoryTemplate(
      '💔 Aşk üçgeni',
      '"{s}" seyircisi {a} ile {b} arasında ikiye bölündü.',
      [
        StoryOption('{a} ile evlensin', 60, 1.22, 0.92, 3),
        StoryOption('{b} ile kaçsın', 40, 1.35, 0.86, 3),
        StoryOption('Kararsız kalsın', 85, 1.08, 0.98, 2),
      ],
    ),
    StoryTemplate(
      '🕵️ Büyük sır',
      '"{s}" bölümünde {a} karakterinin büyük sırrı ortaya çıkabilir.',
      [
        StoryOption('Sır şimdi açılsın', 55, 1.3, 0.88, 3),
        StoryOption('Finale saklayalım', 75, 1.12, 0.96, 2),
        StoryOption('Yeni bir sır ekleyelim', 35, 1.45, 0.85, 4),
      ],
    ),
    StoryTemplate(
      '🚑 Kaza sahnesi',
      '"{s}" yeni bölüm: {a} karakteri trafik kazası geçiriyor.',
      [
        StoryOption('Hafızasını kaybetsin', 50, 1.3, 0.88, 3),
        StoryOption('Komaya girsin', 60, 1.2, 0.92, 3),
        StoryOption('Hafif yaralansın', 90, 1.06, 0.99, 2),
      ],
    ),
  ],
  Genre.yarisma: [
    StoryTemplate(
      '🏆 Büyük final: kim kazansın?',
      '"{s}" finalinde iki yarışmacı kaldı. Oylama mı, jüri mi?',
      [
        StoryOption('Halk oylaması (SMS)', 65, 1.25, 0.93, 3),
        StoryOption('Sürpriz üçüncü finalist', 40, 1.4, 0.86, 3),
        StoryOption('Jüri karar versin', 85, 1.08, 0.98, 2),
      ],
    ),
    StoryTemplate(
      '😱 Sürpriz eleme',
      '"{s}" yapımcıları bu hafta sürpriz bir eleme planlıyor.',
      [
        StoryOption('Favori elensin', 40, 1.38, 0.85, 3),
        StoryOption('Çift eleme yapılsın', 60, 1.2, 0.92, 2),
        StoryOption('Eleme olmasın', 90, 1.05, 0.99, 2),
      ],
    ),
  ],
  Genre.talkShow: [
    StoryTemplate(
      '🎙️ Canlı yayında kavga!',
      '"{s}" konukları canlı yayında tartışmaya başladı.',
      [
        StoryOption('Yayına devam!', 50, 1.32, 0.86, 2),
        StoryOption('Reklama gir', 85, 1.04, 0.99, 1),
        StoryOption('Barıştır, sarılsınlar', 65, 1.18, 0.94, 2),
      ],
    ),
    StoryTemplate(
      '🎤 Sürpriz konuk',
      '"{s}" için sürpriz konuk ayarlanabilir.',
      [
        StoryOption('Eski sevgiliyi çağır', 45, 1.38, 0.86, 2),
        StoryOption('Çocukluk arkadaşı', 80, 1.12, 0.97, 2),
        StoryOption('Konuk yok', 95, 1.02, 1.0, 1),
      ],
    ),
  ],
  Genre.magazin: [
    StoryTemplate(
      '📸 Özel görüntüler',
      '"{s}" muhabiri ünlü bir çiftin gizli görüntülerini yakaladı.',
      [
        StoryOption('Hemen yayınla', 55, 1.3, 0.85, 2),
        StoryOption('Bulanıklaştırıp yayınla', 80, 1.12, 0.97, 2),
        StoryOption('Yayınlama', 95, 1.02, 1.0, 1),
      ],
    ),
  ],
  Genre.haber: [
    StoryTemplate(
      '🔴 Son dakika!',
      '"{s}" sırasında büyük bir son dakika haberi geldi.',
      [
        StoryOption('Canlı yayına geç', 70, 1.25, 0.92, 2),
        StoryOption('Uzman konuk çağır', 80, 1.12, 0.97, 2),
        StoryOption('Akışa devam', 95, 1.02, 1.0, 1),
      ],
    ),
  ],
  Genre.spor: [
    StoryTemplate(
      '⚽ Uzatmalar!',
      '"{s}" maçı uzatmaya gitti, sonraki program bekliyor.',
      [
        StoryOption('Yayını uzat', 75, 1.22, 0.94, 2),
        StoryOption('Penaltıları özel yayınla', 55, 1.32, 0.88, 2),
        StoryOption('Akışa dön', 95, 1.02, 1.0, 1),
      ],
    ),
  ],
  Genre.belgesel: [
    StoryTemplate(
      '🐾 Nadir görüntü',
      '"{s}" ekibi nadir bir hayvanın izini buldu.',
      [
        StoryOption('Günlerce bekle', 50, 1.32, 0.88, 3),
        StoryOption('Drone ile tara', 75, 1.15, 0.96, 2),
        StoryOption('Arşivden kullan', 95, 1.02, 1.0, 1),
      ],
    ),
  ],
  Genre.cocuk: [
    StoryTemplate(
      '🎈 Yeni maskot',
      '"{s}" için yeni bir maskot karakter tasarlandı.',
      [
        StoryOption('Ejderha maskot', 55, 1.3, 0.88, 3),
        StoryOption('Sevimli kedi', 85, 1.1, 0.98, 2),
        StoryOption('Eskisi kalsın', 95, 1.02, 1.0, 1),
      ],
    ),
  ],
};
