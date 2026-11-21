import '../data/content.dart';

// =====================================================================
// 81 il: harita (assets/geo/tr_iller.json, kaynak: geoBoundaries, CC BY 4.0)
// ve oyundaki şehir bilgileri. Şehir açmak izleyici erişimini büyütür,
// bölgenin sevdiği türlerde reytingi artırır ve o şehirde set kurmayı açar.
// =====================================================================

class RegionDef {
  final String name;
  final Set<Genre> genres;
  final Set<FilmGenre> films;
  const RegionDef(this.name, this.genres, this.films);
}

const regionDefs = [
  RegionDef('Marmara', {Genre.dizi, Genre.magazin, Genre.talkShow}, {FilmGenre.romantik, FilmGenre.dram}),
  RegionDef('Ege', {Genre.talkShow, Genre.yarisma}, {FilmGenre.komedi, FilmGenre.romantik}),
  RegionDef('Akdeniz', {Genre.yarisma, Genre.spor}, {FilmGenre.aksiyon}),
  RegionDef('İç Anadolu', {Genre.haber, Genre.cocuk}, {FilmGenre.bilimKurgu}),
  RegionDef('Karadeniz', {Genre.dizi, Genre.belgesel}, {FilmGenre.dram}),
  RegionDef('Doğu Anadolu', {Genre.belgesel, Genre.spor}, {FilmGenre.dram, FilmGenre.aksiyon}),
  RegionDef('Güneydoğu Anadolu', {Genre.belgesel, Genre.dizi}, {FilmGenre.dram, FilmGenre.korku}),
];

class CityDef {
  final int plate;
  final String name;
  final int region;
  final bool metro; // büyükşehir
  final double weight; // nüfus/izleyici ağırlığı
  const CityDef(this.plate, this.name, this.region, this.metro, this.weight);
  RegionDef get regionDef => regionDefs[region];
  /// Açılış bedeli
  double get price => plate == 34 ? 0 : weight * 6e6;
}

/// Ev şehri: oyun İstanbul'da başlar
const homeCityPlate = 34;

const cityDefs = [
  CityDef(1, 'Adana', 2, true, 2),
  CityDef(2, 'Adıyaman', 6, false, 0.7),
  CityDef(3, 'Afyonkarahisar', 1, false, 0.7),
  CityDef(4, 'Ağrı', 5, false, 0.7),
  CityDef(5, 'Amasya', 4, false, 0.7),
  CityDef(6, 'Ankara', 3, true, 6),
  CityDef(7, 'Antalya', 2, true, 2),
  CityDef(8, 'Artvin', 4, false, 0.7),
  CityDef(9, 'Aydın', 1, true, 2),
  CityDef(10, 'Balıkesir', 0, true, 2),
  CityDef(11, 'Bilecik', 0, false, 0.7),
  CityDef(12, 'Bingöl', 5, false, 0.7),
  CityDef(13, 'Bitlis', 5, false, 0.7),
  CityDef(14, 'Bolu', 4, false, 0.7),
  CityDef(15, 'Burdur', 2, false, 0.7),
  CityDef(16, 'Bursa', 0, true, 2),
  CityDef(17, 'Çanakkale', 0, false, 0.7),
  CityDef(18, 'Çankırı', 3, false, 0.7),
  CityDef(19, 'Çorum', 4, false, 0.7),
  CityDef(20, 'Denizli', 1, true, 2),
  CityDef(21, 'Diyarbakır', 6, true, 2),
  CityDef(22, 'Edirne', 0, false, 0.7),
  CityDef(23, 'Elazığ', 5, false, 0.7),
  CityDef(24, 'Erzincan', 5, false, 0.7),
  CityDef(25, 'Erzurum', 5, true, 2),
  CityDef(26, 'Eskişehir', 3, true, 2),
  CityDef(27, 'Gaziantep', 6, true, 2),
  CityDef(28, 'Giresun', 4, false, 0.7),
  CityDef(29, 'Gümüşhane', 4, false, 0.7),
  CityDef(30, 'Hakkâri', 5, false, 0.7),
  CityDef(31, 'Hatay', 2, true, 2),
  CityDef(32, 'Isparta', 2, false, 0.7),
  CityDef(33, 'Mersin', 2, true, 2),
  CityDef(34, 'İstanbul', 0, true, 15),
  CityDef(35, 'İzmir', 1, true, 5),
  CityDef(36, 'Kars', 5, false, 0.7),
  CityDef(37, 'Kastamonu', 4, false, 0.7),
  CityDef(38, 'Kayseri', 3, true, 2),
  CityDef(39, 'Kırklareli', 0, false, 0.7),
  CityDef(40, 'Kırşehir', 3, false, 0.7),
  CityDef(41, 'Kocaeli', 0, true, 2),
  CityDef(42, 'Konya', 3, true, 2),
  CityDef(43, 'Kütahya', 1, false, 0.7),
  CityDef(44, 'Malatya', 5, true, 2),
  CityDef(45, 'Manisa', 1, true, 2),
  CityDef(46, 'Kahramanmaraş', 2, true, 2),
  CityDef(47, 'Mardin', 6, true, 2),
  CityDef(48, 'Muğla', 1, true, 2),
  CityDef(49, 'Muş', 5, false, 0.7),
  CityDef(50, 'Nevşehir', 3, false, 0.7),
  CityDef(51, 'Niğde', 3, false, 0.7),
  CityDef(52, 'Ordu', 4, true, 2),
  CityDef(53, 'Rize', 4, false, 0.7),
  CityDef(54, 'Sakarya', 0, true, 2),
  CityDef(55, 'Samsun', 4, true, 2),
  CityDef(56, 'Siirt', 6, false, 0.7),
  CityDef(57, 'Sinop', 4, false, 0.7),
  CityDef(58, 'Sivas', 3, false, 0.7),
  CityDef(59, 'Tekirdağ', 0, true, 2),
  CityDef(60, 'Tokat', 4, false, 0.7),
  CityDef(61, 'Trabzon', 4, true, 2),
  CityDef(62, 'Tunceli', 5, false, 0.7),
  CityDef(63, 'Şanlıurfa', 6, true, 2),
  CityDef(64, 'Uşak', 1, false, 0.7),
  CityDef(65, 'Van', 5, true, 2),
  CityDef(66, 'Yozgat', 3, false, 0.7),
  CityDef(67, 'Zonguldak', 4, false, 0.7),
  CityDef(68, 'Aksaray', 3, false, 0.7),
  CityDef(69, 'Bayburt', 4, false, 0.7),
  CityDef(70, 'Karaman', 3, false, 0.7),
  CityDef(71, 'Kırıkkale', 3, false, 0.7),
  CityDef(72, 'Batman', 6, false, 0.7),
  CityDef(73, 'Şırnak', 6, false, 0.7),
  CityDef(74, 'Bartın', 4, false, 0.7),
  CityDef(75, 'Ardahan', 5, false, 0.7),
  CityDef(76, 'Iğdır', 5, false, 0.7),
  CityDef(77, 'Yalova', 0, false, 0.7),
  CityDef(78, 'Karabük', 4, false, 0.7),
  CityDef(79, 'Kilis', 6, false, 0.7),
  CityDef(80, 'Osmaniye', 2, false, 0.7),
  CityDef(81, 'Düzce', 4, false, 0.7),
];

final double totalCityWeight = cityDefs.fold(0.0, (a, c) => a + c.weight);

CityDef? cityByPlate(int p) {
  for (final c in cityDefs) {
    if (c.plate == p) return c;
  }
  return null;
}

CityDef? cityByName(String n) {
  for (final c in cityDefs) {
    if (c.name == n) return c;
  }
  return null;
}

/// Çekim lokasyonlarının bulunduğu il (plaka)
const locationCity = {
  'ist': 34, 'ege': 35, 'akdeniz': 7, 'kapadokya': 50, 'karadeniz': 53, 'dogu': 65,
  'mardin': 47, 'nemrut': 2, 'ankara': 6, 'marmara': 41, 'trakya': 22, 'pamukkale': 20,
};
