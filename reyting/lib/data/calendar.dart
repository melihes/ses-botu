import 'content.dart';

/// Oyun takvimi: 1 yıl = 360 gün (12 ay × 30 gün). 1. gün = 1 Eylül
/// (televizyonda yeni sezonun açıldığı gün).
const daysPerYear = 360;

const monthNames = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

/// Oyun günü → (yıl, ay 1-12, ayın günü 1-30)
({int year, int month, int dom, int doy}) dateOfDay(int day) {
  final i = max0(day - 1);
  final doy = i % daysPerYear;
  return (
    year: i ~/ daysPerYear + 1,
    month: (8 + doy ~/ 30) % 12 + 1,
    dom: doy % 30 + 1,
    doy: doy,
  );
}

int max0(int v) => v < 0 ? 0 : v;

/// "12 Eylül"
String dateLabel(int day) {
  final d = dateOfDay(day);
  return '${d.dom} ${monthNames[d.month - 1]}';
}

/// Ay ve gün → yılın kaçıncı günü (0 = 1 Eylül)
int doyOf(int month, int dom) => ((month - 9 + 12) % 12) * 30 + (dom.clamp(1, 30)) - 1;

/// Mevsim (yayın dönemi)
enum TvSeason { acilis, kis, bahar, yaz }

TvSeason seasonOfDay(int day) {
  final m = dateOfDay(day).month;
  if (m == 9 || m == 10) return TvSeason.acilis;
  if (m >= 11 || m <= 2) return TvSeason.kis;
  if (m <= 5) return TvSeason.bahar;
  return TvSeason.yaz;
}

const seasonInfo = {
  TvSeason.acilis: ('🍂', 'Sezon açılışı', 'Herkes ekran başında: tüm programlara +%6.'),
  TvSeason.kis: ('❄️', 'Kış', 'Evde vakit geçiren izleyici: +%4.'),
  TvSeason.bahar: ('🌷', 'Bahar', 'Olağan izlenme.'),
  TvSeason.yaz: ('☀️', 'Yaz', 'Tatil sezonu: izleyici %12 düşer (spor ve yarışma hariç).'),
};

/// Özel gün / bayram / festival
class SpecialDay {
  final String id;
  final String name;
  final String emoji;
  final String desc;
  final int month; // 1-12
  final int dom; // 1-30 (31 olanlar 30'a çekilir)
  final int length; // gün
  final bool lunar; // her yıl 11 gün öne kayar (Ramazan, bayramlar)
  /// Boşsa Türkiye (herkes için); doluysa bu dünya lokasyonlarından birine
  /// sahip olmak gerekir (o ülkede çekim yapıyorsun).
  final List<String> locations;
  final Set<Genre> genres;
  final double tvBonus; // uygun türdeki programlara reyting artışı
  final Set<FilmGenre> films;
  final bool allFilms; // bütün filmler (bayram tatili sineması)
  final double filmBonus;
  final double audience; // genel izleyici çarpanı (tatile gidenler)
  final String special; // özel bölüm adı
  const SpecialDay({
    required this.id,
    required this.name,
    required this.emoji,
    required this.desc,
    required this.month,
    required this.dom,
    this.length = 1,
    this.lunar = false,
    this.locations = const [],
    required this.genres,
    this.tvBonus = 0,
    this.films = const {},
    this.allFilms = false,
    this.filmBonus = 0,
    this.audience = 1,
    required this.special,
  });

  bool get world => locations.isNotEmpty;

  /// Bu özel günün o yıldaki başlangıcı (yılın günü)
  int doyIn(int year) {
    final base = doyOf(month, dom);
    if (!lunar) return base;
    return ((base - 11 * (year - 1)) % daysPerYear + daysPerYear) % daysPerYear;
  }

  /// Bu yıl (ya da önceki yıl) başlayan dönem: oyun günü olarak başlangıç
  int startDay(int year) => (year - 1) * daysPerYear + doyIn(year) + 1;

  /// [day] gününü kapsayan dönemin başlangıcı (yoksa null)
  int? activeStart(int day) {
    final y = dateOfDay(day).year;
    for (final yy in [y - 1, y]) {
      if (yy < 1) continue;
      final s = startDay(yy);
      if (day >= s && day < s + length) return s;
    }
    return null;
  }

  /// Bugünden itibaren (bugün dahil, sürmekte olan da sayılır) sıradaki başlangıç
  int nextStart(int day) {
    final a = activeStart(day);
    if (a != null) return a;
    final y = dateOfDay(day).year;
    for (final yy in [y, y + 1]) {
      final s = startDay(yy);
      if (s >= day) return s;
    }
    return startDay(y + 2);
  }
}

const specialDays = <SpecialDay>[
  // ---------------- Türkiye ----------------
  SpecialDay(
    id: 'okul',
    name: 'Okullar açılıyor',
    emoji: '🎒',
    desc: 'Çocuklar okula dönüyor; çocuk programları sabah kuşağında patlar.',
    month: 9,
    dom: 15,
    length: 3,
    genres: {Genre.cocuk},
    tvBonus: 0.15,
    special: 'Okula Dönüş Özel',
  ),
  SpecialDay(
    id: 'cumhuriyet',
    name: 'Cumhuriyet Bayramı',
    emoji: '🇹🇷',
    desc: 'Tören yayınları, belgeseller ve özel haber kuşakları.',
    month: 10,
    dom: 29,
    genres: {Genre.belgesel, Genre.haber},
    tvBonus: 0.20,
    special: '29 Ekim Özel',
  ),
  SpecialDay(
    id: 'ogretmen',
    name: 'Öğretmenler Günü',
    emoji: '🍎',
    desc: 'Duygusal sahneler ve okul hikâyeleri ilgi görür.',
    month: 11,
    dom: 24,
    genres: {Genre.dizi, Genre.cocuk, Genre.belgesel},
    tvBonus: 0.10,
    special: 'Öğretmenler Günü Özel',
  ),
  SpecialDay(
    id: 'yilbasi',
    name: 'Yılbaşı',
    emoji: '🎄',
    desc: 'Yılın en çok izlenen gecesi: eğlence, yarışma ve sürpriz konuklar. Komedi ve animasyon filmleri dolu salonlarda.',
    month: 12,
    dom: 30,
    length: 2,
    genres: {Genre.yarisma, Genre.talkShow, Genre.magazin},
    tvBonus: 0.18,
    films: {FilmGenre.komedi, FilmGenre.animasyon},
    filmBonus: 0.30,
    special: 'Yılbaşı Gecesi Özel',
  ),
  SpecialDay(
    id: 'sevgililer',
    name: 'Sevgililer Günü',
    emoji: '💘',
    desc: 'Aşk dizileri ve romantik filmler için en iyi gün.',
    month: 2,
    dom: 14,
    genres: {Genre.dizi, Genre.magazin},
    tvBonus: 0.12,
    films: {FilmGenre.romantik},
    filmBonus: 0.40,
    special: 'Sevgililer Günü Özel',
  ),
  SpecialDay(
    id: 'ramazan',
    name: 'Ramazan',
    emoji: '🌙',
    desc: 'İftar ve sahur kuşakları: talk show, dizi ve yarışmalara ilgi artar. Her yıl 11 gün öne kayar.',
    month: 3,
    dom: 10,
    length: 29,
    lunar: true,
    genres: {Genre.talkShow, Genre.dizi, Genre.yarisma},
    tvBonus: 0.10,
    special: 'İftar Özel',
  ),
  SpecialDay(
    id: 'ramazanBayrami',
    name: 'Ramazan Bayramı',
    emoji: '🍬',
    desc: 'Bayram tatili: aileler sinemaya gider, çocuk programları ve diziler izlenir.',
    month: 4,
    dom: 9,
    length: 3,
    lunar: true,
    genres: {Genre.cocuk, Genre.dizi},
    tvBonus: 0.10,
    allFilms: true,
    filmBonus: 0.25,
    audience: 0.96,
    special: 'Bayram Özel',
  ),
  SpecialDay(
    id: 'cocuk23',
    name: '23 Nisan Çocuk Bayramı',
    emoji: '🎈',
    desc: 'Ekranlar çocukların: çocuk programlarına büyük ilgi.',
    month: 4,
    dom: 23,
    genres: {Genre.cocuk},
    tvBonus: 0.35,
    films: {FilmGenre.animasyon},
    filmBonus: 0.30,
    special: '23 Nisan Şenliği',
  ),
  SpecialDay(
    id: 'anneler',
    name: 'Anneler Günü',
    emoji: '💐',
    desc: 'Duygusal diziler ve sohbet programları.',
    month: 5,
    dom: 10,
    genres: {Genre.dizi, Genre.talkShow, Genre.magazin},
    tvBonus: 0.12,
    special: 'Anneler Günü Özel',
  ),
  SpecialDay(
    id: 'genclik',
    name: '19 Mayıs Gençlik ve Spor Bayramı',
    emoji: '🏃',
    desc: 'Spor yayınları ve gençlik programları öne çıkar.',
    month: 5,
    dom: 19,
    genres: {Genre.spor},
    tvBonus: 0.25,
    special: '19 Mayıs Özel',
  ),
  SpecialDay(
    id: 'final',
    name: 'Sezon finalleri haftası',
    emoji: '🎬',
    desc: 'Dizilerin büyük finalleri: herkes merakla bekliyor.',
    month: 6,
    dom: 1,
    length: 7,
    genres: {Genre.dizi},
    tvBonus: 0.15,
    special: 'Sezon Finali',
  ),
  SpecialDay(
    id: 'karne',
    name: 'Karne günü ve yaz tatili',
    emoji: '☀️',
    desc: 'Okullar kapandı: çocuk programları ve yarışmalar gündüz kuşağında.',
    month: 6,
    dom: 15,
    length: 3,
    genres: {Genre.cocuk, Genre.yarisma},
    tvBonus: 0.15,
    films: {FilmGenre.animasyon},
    filmBonus: 0.20,
    special: 'Yaz Tatili Özel',
  ),
  SpecialDay(
    id: 'babalar',
    name: 'Babalar Günü',
    emoji: '👔',
    desc: 'Spor ve belgeseller ailece izlenir.',
    month: 6,
    dom: 18,
    genres: {Genre.spor, Genre.belgesel},
    tvBonus: 0.12,
    special: 'Babalar Günü Özel',
  ),
  SpecialDay(
    id: 'kurban',
    name: 'Kurban Bayramı',
    emoji: '🐑',
    desc: 'Uzun bayram tatili: sinema salonları dolar, bir kısım izleyici tatilde.',
    month: 6,
    dom: 19,
    length: 4,
    lunar: true,
    genres: {Genre.dizi, Genre.belgesel},
    tvBonus: 0.08,
    allFilms: true,
    filmBonus: 0.25,
    audience: 0.92,
    special: 'Bayram Özel',
  ),
  SpecialDay(
    id: 'zafer',
    name: '30 Ağustos Zafer Bayramı',
    emoji: '🇹🇷',
    desc: 'Tarih belgeselleri ve özel haber yayınları.',
    month: 8,
    dom: 30,
    genres: {Genre.belgesel, Genre.haber},
    tvBonus: 0.20,
    special: 'Zafer Bayramı Özel',
  ),

  // ---------------- Dünya (o ülkede lokasyonun olmalı) ----------------
  SpecialDay(
    id: 'cadilar',
    name: 'Cadılar Bayramı',
    emoji: '🎃',
    desc: 'Kostümler, korku ve şeker: Amerika ve İngiltere\'de özel bölümler yurt dışına satılır. Korku filmlerine ilgi artar.',
    month: 10,
    dom: 30,
    locations: ['ny', 'la', 'londra'],
    genres: {Genre.dizi, Genre.yarisma, Genre.cocuk},
    films: {FilmGenre.korku},
    filmBonus: 0.35,
    special: 'Cadılar Bayramı Özel',
  ),
  SpecialDay(
    id: 'seulOdul',
    name: 'Seul Dizi Ödülleri',
    emoji: '🏅',
    desc: 'Asya\'nın en büyük dizi ödül gecesi: dizilerin yurt dışı hakları el değiştirir.',
    month: 10,
    dom: 5,
    length: 2,
    locations: ['seul'],
    genres: {Genre.dizi},
    special: 'Seul Gala Özel',
  ),
  SpecialDay(
    id: 'sukran',
    name: 'Şükran Günü',
    emoji: '🦃',
    desc: 'Amerika\'da aileler bir araya gelir: aile dizileri ve sohbet programları.',
    month: 11,
    dom: 26,
    locations: ['ny', 'la'],
    genres: {Genre.dizi, Genre.talkShow},
    special: 'Şükran Günü Özel',
  ),
  SpecialDay(
    id: 'kutup',
    name: 'Kutup Gün Dönümü',
    emoji: '🐧',
    desc: 'Güneşin hiç batmadığı gün: penguen kolonilerinin büyük belgeseli.',
    month: 12,
    dom: 21,
    locations: ['antarktika'],
    genres: {Genre.belgesel},
    special: 'Kutup Belgeseli Özel',
  ),
  SpecialDay(
    id: 'noel',
    name: 'Noel',
    emoji: '🎅',
    desc: 'Batı\'nın en büyük tatili: Noel özel bölümleri Avrupa ve Amerika\'ya satılır.',
    month: 12,
    dom: 24,
    length: 3,
    locations: ['londra', 'paris', 'ny', 'la', 'yz', 'izlanda'],
    genres: {Genre.cocuk, Genre.yarisma, Genre.dizi},
    films: {FilmGenre.animasyon, FilmGenre.komedi},
    filmBonus: 0.15,
    special: 'Noel Özel',
  ),
  SpecialDay(
    id: 'kuzeyIsik',
    name: 'Kuzey Işıkları',
    emoji: '🌌',
    desc: 'Gökyüzünde yeşil dans: dünyaca izlenen doğa belgeseli fırsatı.',
    month: 1,
    dom: 12,
    length: 7,
    locations: ['izlanda'],
    genres: {Genre.belgesel},
    special: 'Kuzey Işıkları Belgeseli',
  ),
  SpecialDay(
    id: 'dubaiFest',
    name: 'Alışveriş Festivali',
    emoji: '🛍️',
    desc: 'Dubai\'de lüks, ışıklar ve dev ödüller: magazin ve yarışma için altın fırsat.',
    month: 1,
    dom: 20,
    length: 5,
    locations: ['dubai'],
    genres: {Genre.magazin, Genre.yarisma},
    special: 'Festival Özel',
  ),
  SpecialDay(
    id: 'ayYili',
    name: 'Ay Yeni Yılı',
    emoji: '🧧',
    desc: 'Kore ve Japonya\'da yeni yıl kutlaması: aile dizileri ve yarışmalar.',
    month: 2,
    dom: 5,
    length: 3,
    locations: ['seul', 'tokyo'],
    genres: {Genre.dizi, Genre.yarisma, Genre.cocuk},
    special: 'Ay Yeni Yılı Özel',
  ),
  SpecialDay(
    id: 'karnaval',
    name: 'Rio Karnavalı',
    emoji: '🎭',
    desc: 'Samba, kostümler ve dev geçit töreni: dünya ekran başında.',
    month: 2,
    dom: 20,
    length: 4,
    locations: ['rio'],
    genres: {Genre.yarisma, Genre.magazin, Genre.belgesel},
    special: 'Karnaval Özel',
  ),
  SpecialDay(
    id: 'odulGecesi',
    name: 'Altın Heykel Gecesi',
    emoji: '🏆',
    desc: 'Los Angeles\'ta yılın en büyük film ödül gecesi: kırmızı halı yayınları.',
    month: 3,
    dom: 10,
    locations: ['la'],
    genres: {Genre.magazin, Genre.talkShow},
    films: {FilmGenre.dram},
    filmBonus: 0.20,
    special: 'Kırmızı Halı Özel',
  ),
  SpecialDay(
    id: 'hanami',
    name: 'Kiraz Çiçeği Festivali',
    emoji: '🌸',
    desc: 'Tokyo pembeye bürünür: belgesel ve magazin çekimleri için eşsiz manzara.',
    month: 4,
    dom: 1,
    length: 5,
    locations: ['tokyo'],
    genres: {Genre.belgesel, Genre.magazin},
    special: 'Hanami Özel',
  ),
  SpecialDay(
    id: 'paskalya',
    name: 'Paskalya',
    emoji: '🐣',
    desc: 'Avrupa ve Amerika\'da bahar tatili: çocuk programları ve aile dizileri.',
    month: 4,
    dom: 12,
    length: 2,
    locations: ['londra', 'paris', 'ny'],
    genres: {Genre.cocuk, Genre.dizi, Genre.belgesel},
    special: 'Paskalya Özel',
  ),
  SpecialDay(
    id: 'bastille',
    name: 'Bastille Günü',
    emoji: '🎆',
    desc: 'Paris\'te havai fişekler ve geçit töreni.',
    month: 7,
    dom: 14,
    locations: ['paris'],
    genres: {Genre.haber, Genre.belgesel, Genre.magazin},
    special: 'Paris Kutlaması Özel',
  ),
  SpecialDay(
    id: 'goc',
    name: 'Büyük Göç',
    emoji: '🦓',
    desc: 'Milyonlarca hayvan savanda yola çıkar: yılın belgesel olayı.',
    month: 8,
    dom: 1,
    length: 10,
    locations: ['safari'],
    genres: {Genre.belgesel, Genre.cocuk},
    special: 'Büyük Göç Belgeseli',
  ),
  SpecialDay(
    id: 'nil',
    name: 'Nil Festivali',
    emoji: '🏺',
    desc: 'Piramitlerin gölgesinde konserler ve tarih belgeselleri.',
    month: 8,
    dom: 15,
    length: 3,
    locations: ['kahire'],
    genres: {Genre.belgesel, Genre.dizi},
    special: 'Nil Özel',
  ),
];

SpecialDay? specialDayById(String id) {
  for (final d in specialDays) {
    if (d.id == id) return d;
  }
  return null;
}
