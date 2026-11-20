import '../data/content.dart';

/// Kadrodaki (veya pazardaki) bir kişi
class Staff {
  final String id;
  final String name;
  final Role role;
  final int skill; // 1..99
  final double salary; // günlük maaş
  String? showId; // bağlı olduğu program

  Staff({
    required this.id,
    required this.name,
    required this.role,
    required this.skill,
    required this.salary,
    this.showId,
  });

  bool get isStar => skill >= 85;
  double get signingFee => salary * 5;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role.index,
        'skill': skill,
        'salary': salary,
        'showId': showId,
      };

  factory Staff.fromJson(Map<String, dynamic> j) => Staff(
        id: j['id'],
        name: j['name'],
        role: Role.values[j['role']],
        skill: j['skill'],
        salary: (j['salary'] as num).toDouble(),
        showId: j['showId'],
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
  String? sponsor; // ürün yerleştirme markası
  double sponsorPerDay;
  int sponsorDays;

  Show({
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
  }) : ratingHistory = ratingHistory ?? [];

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
        'sponsor': sponsor,
        'sponsorPerDay': sponsorPerDay,
        'sponsorDays': sponsorDays,
      };

  factory Show.fromJson(Map<String, dynamic> j) => Show(
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
        sponsor: j['sponsor'],
        sponsorPerDay: (j['sponsorPerDay'] as num? ?? 0).toDouble(),
        sponsorDays: j['sponsorDays'] ?? 0,
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

  Map<String, dynamic> toJson() =>
      {'day': day, 'title': title, 'body': body, 'good': good};
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
  Map<String, dynamic> toJson() =>
      {'p': platformId, 'd': daysLeft, 'f': fee};
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
  final double salary;
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

  double get revenuePerDay => followers * engagement * 2;
  double get signingFee => salary * 7;
  double get campaignCost => followers * 0.5;

  Map<String, dynamic> toJson() => {
        'id': id, 'name': name, 'handle': handle, 'niche': niche.index,
        'followers': followers, 'growth': growth, 'engagement': engagement,
        'salary': salary, 'crd': campaignReadyDay, 'look': look,
      };
  factory Creator.fromJson(Map<String, dynamic> j) => Creator(
        id: j['id'], name: j['name'], handle: j['handle'],
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
  factory DayStat.fromJson(List j) => DayStat(j[0] as int, (j[1] as num).toDouble(),
      (j[2] as num).toDouble(), (j[3] as num).toDouble());
}

/// Reyting raporundaki bir satır
class ReportRow {
  final String channel;
  final String program;
  final double rating;
  final bool mine;
  final int colorIndex;
  ReportRow(this.channel, this.program, this.rating, this.mine, this.colorIndex);
  List toJson() => [channel, program, rating, mine, colorIndex];
  factory ReportRow.fromJson(List j) => ReportRow(j[0], j[1],
      (j[2] as num).toDouble(), j[3] as bool, j[4] as int);
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
  double deadline = 0; // oyun zamanı (gün + ilerleme)
  Decision({
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
