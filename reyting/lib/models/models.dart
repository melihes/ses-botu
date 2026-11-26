import 'dart:math';

import '../data/content.dart';
import '../data/content2.dart';

/// Ekonomi çarpanı (1.0.2): tüm gelirler ve günlük giderler (maaş, kira,
/// bakım) bu oranla ölçeklenir; satın alma fiyatları değişmez.
/// Sonuç: kazanılan para ~%70 azalır, kâr marjları korunur.
const double kIncome = 0.32;

/// Kayıt formatındaki ekonomi sürümü (eski kayıtlar yüklenirken ölçeklenir)
const int kEconVersion = 2;

/// Kadrodaki (veya pazardaki) bir kişi
class Staff {
  final String id;
  final String name;
  final Role role;
  int skill; // 1..99 (eğitimle artar)
  double salary; // günlük maaş
  String? showId; // bağlı olduğu program
  int trainedDay; // en son eğitim aldığı gün
  int spec; // uzmanlık (specsByRole[role] index)
  int trait; // karakter özelliği (traitDefs index)
  int age;
  int potential; // ulaşabileceği en yüksek yetenek
  double fame; // şöhret 0..100
  double xp; // gelişim birikimi (1 dolunca +1 yetenek)
  bool forSale; // transfer listesinde
  int joinedDay; // kadroya/akademiye katıldığı gün (hemen satıp kâr etmeyi engeller)

  Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.skill,
    required this.salary,
    this.showId,
    this.trainedDay = -99,
    this.spec = -1,
    this.trait = 0,
    this.age = 30,
    this.potential = 0,
    this.fame = 0,
    this.xp = 0,
    this.forSale = false,
    this.joinedDay = -9999,
  }) {
    if (spec < 0) spec = id.hashCode.abs() % specsByRole[role]!.length;
    if (potential < skill) potential = skill;
  }

  bool get isStar => skill >= 85;
  double get signingFee => salary * 5;
  SpecDef get specDef => specsByRole[role]![spec % specsByRole[role]!.length];
  TraitDef get traitDef => traitDefs[trait % traitDefs.length];
  bool get isYoung => age <= 23;

  /// Uzmanlık uyumu: 1 tam uyum, 0.5 çok yönlü, 0 uyumsuz
  double fitGenre(Genre g) =>
      specDef.genres.contains(g) ? 1 : (trait == 7 ? 0.5 : 0);
  double fitFilm(FilmGenre g) =>
      specDef.films.contains(g) ? 1 : (trait == 7 ? 0.5 : 0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role.index,
    'skill': skill,
    'salary': salary,
    'showId': showId,
    'trainedDay': trainedDay,
    'spec': spec,
    'trait': trait,
    'age': age,
    'pot': potential,
    'fame': fame,
    'xp': xp,
    'sale': forSale,
    'joined': joinedDay,
  };

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
    id: j['id'],
    name: j['name'],
    role: Role.values[j['role']],
    skill: j['skill'],
    salary: (j['salary'] as num).toDouble(),
    showId: j['showId'],
    trainedDay: j['trainedDay'] ?? -99,
    spec: j['spec'] ?? -1,
    trait: j['trait'] ?? 0,
    age: j['age'] ?? 30,
    potential: j['pot'] ?? 0,
    fame: (j['fame'] as num? ?? 0).toDouble(),
    xp: (j['xp'] as num? ?? 0).toDouble(),
    forSale: j['sale'] ?? false,
    joinedDay: j['joined'] ?? -9999,
  );
}

enum ShowStatus { producing, ready, onAir, ended }

class Show {
  final String id;
  String name;
  final Genre genre;
  int tier; // bütçe seviyesi index
  List<String> staffIds;
  ShowStatus status;
  double prodLeft; // kalan üretim günü
  int episodesAired;
  int season;
  double quality; // 0..~1.2
  SlotId? slot;
  double noise; // günlük rastgele dalgalanma
  List<double> ratingHistory;
  double totalRevenue;
  double seasonRevenue;
  double buff; // olaylardan gelen geçici reyting çarpanı
  int buffDays;
  int lastAiredDay; // en son yayında olduğu gün (ödüller için)
  SlotId? autoSlot; // Genel Müdür yeniledi: hazır olunca bu kuşağa döner
  String? sponsor; // ürün yerleştirme markası
  double sponsorPerDay;
  int sponsorDays;
  int budget; // prodüksiyon bütçesi (prodBudgets index)
  int guest; // ünlü konuk seviyesi (guestTiers index)
  String? guestName;
  String? location; // çekim lokasyonu id
  double loyalty; // izleyici sadakati (az reklamla büyür, 0..0.25)
  double castShock; // kadro değişince izleyici küser: başlangıç cezası (0.3 = %30)
  int castShockDay; // cezanın başladığı gün (20 günde biter)
  List<String> pastCrew; // bu programda daha önce çalışmış herkes (geri dönüş sevinci)

  Show({
    this.castShock = 0,
    this.castShockDay = 0,
    List<String>? pastCrew,
    this.loyalty = 0,
    this.budget = 1,
    this.guest = 0,
    this.guestName,
    this.location,
    this.lastAiredDay = 0,
    this.autoSlot,
    this.sponsor,
    this.sponsorPerDay = 0,
    this.sponsorDays = 0,
    this.buff = 1.0,
    this.buffDays = 0,
    required this.id,
    required this.name,
    required this.genre,
    required this.tier,
    required this.staffIds,
    this.status = ShowStatus.producing,
    required this.prodLeft,
    this.episodesAired = 0,
    this.season = 1,
    required this.quality,
    this.slot,
    this.noise = 1.0,
    List<double>? ratingHistory,
    this.totalRevenue = 0,
    this.seasonRevenue = 0,
  }) : ratingHistory = ratingHistory ?? [],
       pastCrew = pastCrew ?? [];

  GenreDef get def => genreDefs[genre]!;
  int get seasonDays => def.seasonDays;
  double get seasonProgress => (episodesAired / seasonDays).clamp(0.0, 1.0);

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'genre': genre.index,
    'tier': tier,
    'staffIds': staffIds,
    'status': status.index,
    'prodLeft': prodLeft,
    'episodesAired': episodesAired,
    'season': season,
    'quality': quality,
    'slot': slot?.index,
    'noise': noise,
    'ratingHistory': ratingHistory,
    'totalRevenue': totalRevenue,
    'seasonRevenue': seasonRevenue,
    'buff': buff,
    'buffDays': buffDays,
    'lastAiredDay': lastAiredDay,
    'autoSlot': autoSlot?.index,
    'sponsor': sponsor,
    'sponsorPerDay': sponsorPerDay,
    'sponsorDays': sponsorDays,
    'budget': budget,
    'guest': guest,
    'guestName': guestName,
    'loc': location,
    'loy': loyalty,
    'shock': castShock,
    'shockDay': castShockDay,
    'past': pastCrew,
  };

  factory Show.fromJson(Map<String, dynamic> j) => Show(
    castShock: (j['shock'] as num? ?? 0).toDouble(),
    castShockDay: j['shockDay'] ?? 0,
    pastCrew: List<String>.from((j['past'] as List?) ?? j['staffIds'] ?? const []),
    id: j['id'],
    name: j['name'],
    genre: Genre.values[j['genre']],
    tier: j['tier'],
    staffIds: List<String>.from(j['staffIds']),
    status: ShowStatus.values[j['status']],
    prodLeft: (j['prodLeft'] as num).toDouble(),
    episodesAired: j['episodesAired'],
    season: j['season'],
    quality: (j['quality'] as num).toDouble(),
    slot: j['slot'] == null ? null : SlotId.values[j['slot']],
    noise: (j['noise'] as num).toDouble(),
    ratingHistory: (j['ratingHistory'] as List)
        .map((e) => (e as num).toDouble())
        .toList(),
    totalRevenue: (j['totalRevenue'] as num).toDouble(),
    seasonRevenue: (j['seasonRevenue'] as num? ?? 0).toDouble(),
    buff: (j['buff'] as num? ?? 1).toDouble(),
    buffDays: j['buffDays'] ?? 0,
    lastAiredDay: j['lastAiredDay'] ?? 0,
    autoSlot: j['autoSlot'] == null ? null : SlotId.values[j['autoSlot']],
    sponsor: j['sponsor'],
    sponsorPerDay: (j['sponsorPerDay'] as num? ?? 0).toDouble(),
    sponsorDays: j['sponsorDays'] ?? 0,
    budget: j['budget'] ?? 1,
    guest: j['guest'] ?? 0,
    guestName: j['guestName'],
    location: j['loc'],
    loyalty: (j['loy'] as num? ?? 0).toDouble(),
  );
}

/// Bir yayın kuşağının ayarı
class SlotState {
  String? showId;
  double adMinutes; // saat başına reklam dakikası
  SlotState({this.showId, this.adMinutes = 8});

  Map<String, dynamic> toJson() => {'showId': showId, 'adMinutes': adMinutes};
  factory SlotState.fromJson(Map<String, dynamic> j) => SlotState(
    showId: j['showId'],
    adMinutes: (j['adMinutes'] as num).toDouble(),
  );
}

class Loan {
  final String id;
  final double principal;
  final double installment;
  int installmentsLeft;
  int nextDueDay;

  Loan({
    required this.id,
    required this.principal,
    required this.installment,
    required this.installmentsLeft,
    required this.nextDueDay,
  });

  double get remaining => installment * installmentsLeft;

  Map<String, dynamic> toJson() => {
    'id': id,
    'principal': principal,
    'installment': installment,
    'installmentsLeft': installmentsLeft,
    'nextDueDay': nextDueDay,
  };
  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
    id: j['id'],
    principal: (j['principal'] as num).toDouble(),
    installment: (j['installment'] as num).toDouble(),
    installmentsLeft: j['installmentsLeft'],
    nextDueDay: j['nextDueDay'],
  );
}

/// Pazarlık durumu (yat, ada, kanal vb. için)
class NegState {
  int patience;
  double floorFactor; // satıcının gizli taban fiyat oranı
  double? counter; // satıcının son karşı teklifi
  int lockedUntil; // bu güne kadar satıcı masaya dönmez

  NegState({
    this.patience = 3,
    required this.floorFactor,
    this.counter,
    this.lockedUntil = 0,
  });

  Map<String, dynamic> toJson() => {
    'patience': patience,
    'floorFactor': floorFactor,
    'counter': counter,
    'lockedUntil': lockedUntil,
  };
  factory NegState.fromJson(Map<String, dynamic> j) => NegState(
    patience: j['patience'],
    floorFactor: (j['floorFactor'] as num).toDouble(),
    counter: (j['counter'] as num?)?.toDouble(),
    lockedUntil: j['lockedUntil'],
  );
}

enum NegOutcome { accepted, counter, rejected, walkedAway, locked, noMoney }

class NegResult {
  final NegOutcome outcome;
  final String message;
  final double? price;
  const NegResult(this.outcome, this.message, [this.price]);
}

/// Çevrimdışı ilerleme / dönem özeti
class PeriodSummary {
  int days = 0;
  double minutesAway = 0;
  double minutesCounted = 0;
  double cashBefore = 0;
  double cashAfter = 0;
  double adIncome = 0;
  double channelIncome = 0;
  double salaries = 0;
  double rent = 0;
  double loanPaid = 0;
  int finishedProductions = 0;
  int endedSeasons = 0;
  double upkeep = 0;
  double boxOffice = 0;
  double platformIncome = 0;
  double bizIncome = 0;
  double digitalIncome = 0;
  double sponsorIncome = 0;
  int autoRenewed = 0;
  int filmsDone = 0;
  double eventCash = 0;
  int events = 0;
  double ratingSum = 0;
  int ratingCount = 0;

  double get avgRating => ratingCount == 0 ? 0 : ratingSum / ratingCount;
}

/// Oyun günlüğündeki bir olay
class GameEvent {
  final int day;
  final String title;
  final String body;
  final bool good;
  GameEvent(this.day, this.title, this.body, this.good);

  Map<String, dynamic> toJson() => {
    'day': day,
    'title': title,
    'body': body,
    'good': good,
  };
  factory GameEvent.fromJson(Map<String, dynamic> j) =>
      GameEvent(j['day'], j['title'], j['body'], j['good']);
}

enum FilmStatus { producing, ready, inTheaters, library, rightsSold }

/// Bir platforma verilmiş süreli film lisansı
class FilmLicense {
  final String platformId;
  int daysLeft;
  final double fee;
  FilmLicense(this.platformId, this.daysLeft, this.fee);
  Map<String, dynamic> toJson() => {'p': platformId, 'd': daysLeft, 'f': fee};
  factory FilmLicense.fromJson(Map<String, dynamic> j) =>
      FilmLicense(j['p'], j['d'], (j['f'] as num).toDouble());
}

class Film {
  final String id;
  final String name;
  final FilmGenre genre;
  final int tier;
  final List<String> staffIds;
  final double cost;
  FilmStatus status;
  double prodLeft;
  double quality;
  double score; // izleyici puanı 1..10
  int theaterDay; // vizyondaki kaçıncı gün
  double boxOffice;
  double licenseIncome;
  double soldFor;
  int licensesSold; // toplam satılan lisans sayısı (değer düşer)
  bool onOwnPlatform;
  int finishedDay; // çekimin bittiği gün (ödüller için)
  final List<FilmLicense> licenses;

  Film({
    required this.id,
    required this.name,
    required this.genre,
    required this.tier,
    required this.staffIds,
    required this.cost,
    this.status = FilmStatus.producing,
    required this.prodLeft,
    required this.quality,
    this.score = 0,
    this.theaterDay = 0,
    this.boxOffice = 0,
    this.licenseIncome = 0,
    this.soldFor = 0,
    this.licensesSold = 0,
    this.onOwnPlatform = false,
    this.finishedDay = 0,
    List<FilmLicense>? licenses,
  }) : licenses = licenses ?? [];

  FilmGenreDef get def => filmGenreDefs[genre]!;
  bool get rightsOwned => status != FilmStatus.rightsSold;
  double get totalIncome => boxOffice + licenseIncome + soldFor;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'genre': genre.index,
    'tier': tier,
    'staffIds': staffIds,
    'cost': cost,
    'status': status.index,
    'prodLeft': prodLeft,
    'quality': quality,
    'score': score,
    'theaterDay': theaterDay,
    'boxOffice': boxOffice,
    'licenseIncome': licenseIncome,
    'soldFor': soldFor,
    'licensesSold': licensesSold,
    'onOwnPlatform': onOwnPlatform,
    'finishedDay': finishedDay,
    'licenses': licenses.map((e) => e.toJson()).toList(),
  };

  factory Film.fromJson(Map<String, dynamic> j) => Film(
    id: j['id'],
    name: j['name'],
    genre: FilmGenre.values[j['genre']],
    tier: j['tier'],
    staffIds: List<String>.from(j['staffIds']),
    cost: (j['cost'] as num).toDouble(),
    status: FilmStatus.values[j['status']],
    prodLeft: (j['prodLeft'] as num).toDouble(),
    quality: (j['quality'] as num).toDouble(),
    score: (j['score'] as num).toDouble(),
    theaterDay: j['theaterDay'],
    boxOffice: (j['boxOffice'] as num).toDouble(),
    licenseIncome: (j['licenseIncome'] as num).toDouble(),
    soldFor: (j['soldFor'] as num).toDouble(),
    licensesSold: j['licensesSold'],
    onOwnPlatform: j['onOwnPlatform'] ?? false,
    finishedDay: j['finishedDay'] ?? 0,
    licenses: (j['licenses'] as List)
        .map((e) => FilmLicense.fromJson(e))
        .toList(),
  );
}

/// Videom'daki içerik üreticisi (YouTuber)
class Creator {
  final String id;
  final String name;
  final String handle;
  final Niche niche;
  double followers;
  double growth; // günlük büyüme oranı
  final double engagement; // etkileşim oranı
  double salary;
  int campaignReadyDay;
  final int look; // avatar varyasyonu

  Creator({
    required this.id,
    required this.name,
    required this.handle,
    required this.niche,
    required this.followers,
    required this.growth,
    required this.engagement,
    required this.salary,
    this.campaignReadyDay = 0,
    this.look = 0,
  });

  double get revenuePerDay => followers * engagement * 2 * kIncome;
  double get signingFee => salary * 7;
  double get campaignCost => followers * 0.5;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'handle': handle,
    'niche': niche.index,
    'followers': followers,
    'growth': growth,
    'engagement': engagement,
    'salary': salary,
    'crd': campaignReadyDay,
    'look': look,
  };
  factory Creator.fromJson(Map<String, dynamic> j) => Creator(
    id: j['id'],
    name: j['name'],
    handle: j['handle'],
    niche: Niche.values[j['niche']],
    followers: (j['followers'] as num).toDouble(),
    growth: (j['growth'] as num).toDouble(),
    engagement: (j['engagement'] as num).toDouble(),
    salary: (j['salary'] as num).toDouble(),
    campaignReadyDay: j['crd'] ?? 0,
    look: j['look'] ?? 0,
  );
}

/// Kasa geçmişi (grafik için): bir günün özeti
class DayStat {
  final int day;
  final double cash;
  final double income;
  final double expense;
  DayStat(this.day, this.cash, this.income, this.expense);
  double get net => income - expense;
  List<num> toJson() => [day, cash.round(), income.round(), expense.round()];
  factory DayStat.fromJson(List j) => DayStat(
    j[0] as int,
    (j[1] as num).toDouble(),
    (j[2] as num).toDouble(),
    (j[3] as num).toDouble(),
  );
}

/// Reyting raporundaki bir satır
class ReportRow {
  final String channel;
  final String program;
  final double rating;
  final bool mine;
  final int colorIndex;
  ReportRow(
    this.channel,
    this.program,
    this.rating,
    this.mine,
    this.colorIndex,
  );
  List toJson() => [channel, program, rating, mine, colorIndex];
  factory ReportRow.fromJson(List j) => ReportRow(
    j[0],
    j[1],
    (j[2] as num).toDouble(),
    j[3] as bool,
    j[4] as int,
  );
}

/// Oyuncunun karar vermesi gereken durum (kriz, zam talebi, sponsor…)
class Decision {
  final String kind;
  final String title;
  final String body;
  final List<String> options;
  final List<String> hints;
  final String? targetId;
  final double amount;
  final String extra;
  final int defaultOption; // cevap verilmezse seçilen güvenli seçenek
  final List<int>? chances; // senaryo kararlarında başarı ihtimalleri
  double deadline = 0; // oyun zamanı (gün + ilerleme)
  Decision({
    this.chances,
    this.defaultOption = 0,
    required this.kind,
    required this.title,
    required this.body,
    required this.options,
    required this.hints,
    this.targetId,
    this.amount = 0,
    this.extra = '',
  });
}

/// Kazanılan ödül (kupa dolabı)
class Trophy {
  final int day;
  final String award;
  final String winner;
  Trophy(this.day, this.award, this.winner);
  List toJson() => [day, award, winner];
  factory Trophy.fromJson(List j) => Trophy(j[0] as int, j[1], j[2]);
}

/// Ödül töreninde bir kategori sonucu
class AwardResult {
  final String category;
  final String nominee;
  final bool won;
  AwardResult(this.category, this.nominee, this.won);
}

/// Günlük görev
class Mission {
  final String kind;
  final String title;
  final int target;
  final int gems;
  int progress;
  bool claimed;
  Mission(
    this.kind,
    this.title,
    this.target,
    this.gems, {
    this.progress = 0,
    this.claimed = false,
  });
  bool get done => progress >= target;
  Map<String, dynamic> toJson() => {
    'k': kind,
    't': title,
    'n': target,
    'g': gems,
    'p': progress,
    'c': claimed,
  };
  factory Mission.fromJson(Map<String, dynamic> j) => Mission(
    j['k'],
    j['t'],
    j['n'],
    j['g'],
    progress: j['p'],
    claimed: j['c'],
  );
}

enum TenderStatus { open, producing, delivered, lost, expired }

/// Bir devlet ihalesi (açık, kazanılmış ya da kaybedilmiş)
class Tender {
  final String id;
  final String defId;
  final double budget; // tahmini bedel
  final int closesDay;
  TenderStatus status;
  double? myBid;
  List<String> crewIds;
  double prodLeft;
  double qualityFactor;
  String? winner;
  double? winningBid;
  double paid; // teslimde alınan

  Tender({
    required this.id,
    required this.defId,
    required this.budget,
    required this.closesDay,
    this.status = TenderStatus.open,
    this.myBid,
    List<String>? crewIds,
    this.prodLeft = 0,
    this.qualityFactor = 1,
    this.winner,
    this.winningBid,
    this.paid = 0,
  }) : crewIds = crewIds ?? [];

  TenderDef get def => tenderDefs.firstWhere((d) => d.id == defId);
  double get deposit => (myBid ?? 0) * 0.05; // teminat
  double get productionCost => budget * 0.45;

  Map<String, dynamic> toJson() => {
    'id': id,
    'd': defId,
    'b': budget,
    'c': closesDay,
    's': status.index,
    'm': myBid,
    'cr': crewIds,
    'p': prodLeft,
    'q': qualityFactor,
    'w': winner,
    'wb': winningBid,
    'pd': paid,
  };
  factory Tender.fromJson(Map<String, dynamic> j) => Tender(
    id: j['id'],
    defId: j['d'],
    budget: (j['b'] as num).toDouble(),
    closesDay: j['c'],
    status: TenderStatus.values[j['s']],
    myBid: (j['m'] as num?)?.toDouble(),
    crewIds: List<String>.from(j['cr'] ?? []),
    prodLeft: (j['p'] as num? ?? 0).toDouble(),
    qualityFactor: (j['q'] as num? ?? 1).toDouble(),
    winner: j['w'],
    winningBid: (j['wb'] as num?)?.toDouble(),
    paid: (j['pd'] as num? ?? 0).toDouble(),
  );
}

/// Yönetim kurulu üyesi
class Exec {
  final String id;
  final String name;
  final ExecRole role;
  final int skill; // 1..99
  double salary;
  Exec(this.id, this.name, this.role, this.skill, this.salary);
  ExecRoleDef get def => execDefs[role]!;
  double get signingFee => salary * 10;

  /// Yeteneğe göre etki (0..1): uzmanlar çok daha etkili
  double get power => pow(skill / 100, 1.5).toDouble();

  Map<String, dynamic> toJson() => {
    'id': id,
    'n': name,
    'r': role.index,
    's': skill,
    'm': salary,
  };
  factory Exec.fromJson(Map<String, dynamic> j) => Exec(
    j['id'],
    j['n'],
    ExecRole.values[j['r']],
    j['s'],
    (j['m'] as num).toDouble(),
  );
}

/// Gelen marka teklifi (kabul edilmeyi bekler)
class BrandOffer {
  final String id;
  final String brand;
  final DealKind kind;
  final String? targetId;
  final double perDay;
  final double lump;
  final int days;
  final double ratingCost; // reyting çarpanı kaybı (0.03 = -%3)
  final int expires; // bu günden sonra geçersiz
  BrandOffer(
    this.id,
    this.brand,
    this.kind,
    this.targetId,
    this.perDay,
    this.lump,
    this.days,
    this.ratingCost,
    this.expires,
  );
  double get total => perDay * days + lump;
  Map<String, dynamic> toJson() => {
    'id': id,
    'b': brand,
    'k': kind.index,
    't': targetId,
    'p': perDay,
    'l': lump,
    'd': days,
    'r': ratingCost,
    'e': expires,
  };
  factory BrandOffer.fromJson(Map<String, dynamic> j) => BrandOffer(
    j['id'],
    j['b'],
    DealKind.values[j['k']],
    j['t'],
    (j['p'] as num).toDouble(),
    (j['l'] as num).toDouble(),
    j['d'],
    (j['r'] as num).toDouble(),
    j['e'],
  );
}

/// Süren marka anlaşması (günlük gelir)
class Deal {
  final String brand;
  final DealKind kind;
  final String? targetId;
  final double perDay;
  int daysLeft;
  Deal(this.brand, this.kind, this.targetId, this.perDay, this.daysLeft);
  Map<String, dynamic> toJson() => {
    'b': brand,
    'k': kind.index,
    't': targetId,
    'p': perDay,
    'd': daysLeft,
  };
  factory Deal.fromJson(Map<String, dynamic> j) => Deal(
    j['b'],
    DealKind.values[j['k']],
    j['t'],
    (j['p'] as num).toDouble(),
    j['d'],
  );
}

/// Satışa çıkarılan oyuncu için gelen transfer teklifi
class TransferOffer {
  final String staffId;
  final String from;
  final double amount;
  final int expires;
  TransferOffer(this.staffId, this.from, this.amount, this.expires);
  Map<String, dynamic> toJson() => {
    's': staffId,
    'f': from,
    'a': amount,
    'e': expires,
  };
  factory TransferOffer.fromJson(Map<String, dynamic> j) =>
      TransferOffer(j['s'], j['f'], (j['a'] as num).toDouble(), j['e']);
}

/// Şirket logosu: sembol × renk × çerçeve
class CompanyLogo {
  int shape;
  int palette;
  int frame;
  CompanyLogo({this.shape = 0, this.palette = 0, this.frame = 1});
  List<int> toJson() => [shape, palette, frame];
  factory CompanyLogo.fromJson(List j) =>
      CompanyLogo(shape: j[0], palette: j[1], frame: j[2]);
}


/// İkinci el pazarda satılan sınırlı üretim lüks parça
class LuxListing {
  final String defId;
  final int serial;
  final double price;
  final String seller;
  LuxListing(this.defId, this.serial, this.price, this.seller);
  List toJson() => [defId, serial, price, seller];
  factory LuxListing.fromJson(List j) =>
      LuxListing(j[0], j[1], (j[2] as num).toDouble(), j[3]);
}

/// Satışa koyduğun lüks parçaya gelen teklif
class LuxOffer {
  final String defId;
  final String from;
  final double amount;
  final int expires;
  LuxOffer(this.defId, this.from, this.amount, this.expires);
  List toJson() => [defId, from, amount, expires];
  factory LuxOffer.fromJson(List j) =>
      LuxOffer(j[0], j[1], (j[2] as num).toDouble(), j[3]);
}

/// Kurmaca sosyal medya paylaşımı
class SocialPost {
  final int day;
  final int hour;
  final String name; // görünen ad
  final String handle; // @kullanici
  final String text;
  final int likes;
  final int shares;
  final int mood; // 1 olumlu, 0 nötr, -1 olumsuz
  final int seed; // profil resmi
  final bool female;
  const SocialPost({
    required this.day,
    required this.hour,
    required this.name,
    required this.handle,
    required this.text,
    required this.likes,
    required this.shares,
    required this.mood,
    required this.seed,
    required this.female,
  });

  Map<String, dynamic> toJson() => {
    'd': day, 'h': hour, 'n': name, 'u': handle, 't': text,
    'l': likes, 's': shares, 'm': mood, 'r': seed, 'f': female,
  };
  factory SocialPost.fromJson(Map<String, dynamic> j) => SocialPost(
    day: j['d'] ?? 0,
    hour: j['h'] ?? 0,
    name: j['n'] ?? '',
    handle: j['u'] ?? '',
    text: j['t'] ?? '',
    likes: j['l'] ?? 0,
    shares: j['s'] ?? 0,
    mood: j['m'] ?? 0,
    seed: j['r'] ?? 0,
    female: j['f'] ?? false,
  );
}
