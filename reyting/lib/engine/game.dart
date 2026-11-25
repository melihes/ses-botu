import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../data/content.dart';
import '../data/cities.dart';
import '../core/monetization_config.dart';
import '../data/content2.dart';
import '../models/models.dart';
import 'achievements.dart';
import 'economy.dart';

part 'game_v12.dart';
part 'game_shop.dart';

/// Oyunun tüm durumunu tutan ve zamanı ilerleten motor.
/// Ekranlar bunu dinler; her değişiklikte notifyListeners() çağrılır.
class Game extends ChangeNotifier {
  static const _saveKey = 'reyting_save_v1';
  static const _saveVersion = 2;

  final _rng = Random();
  int _idCounter = 0;

  // ---- Durum ----
  String channelName = 'Kanal 9';
  double cash = startingCash;
  int diamonds = startingDiamonds;
  int day = 1;
  double dayProgress = 0;
  int studioLevel = 0; // studioLevels index
  bool vip = false;
  bool noAds = false; // "Reklamsız" paketi
  final Map<String, int> adBoosts = {}; // reklamla hızlandırılan yapımlar
  int lastAdDiscountDay = -999; // reklamla indirim en son ne zaman kullanıldı
  int adsWatched = 0;
  double purchasedCash = 0; // gerçek parayla alınan oyun parası (toplam)
  int lastGrantSeq = 0; // yöneticiden gelen son işlem (tekrar uygulanmasın)
  int profileFrame = 0; // online listede görünen profil çerçevesi
  int careerStart = 0; // bu kariyerin başladığı an (yönetici toplu silmesi için)
  String? cloudUid; // bu kaydın en son bağlı olduğu online hesap
  double timeScale = 1; // test modu için hızlandırma

  /// Test modu bu kariyerde hiç kullanıldı mı (kullanıldıysa online sıralamaya giremez)
  bool tainted = false;

  final List<Staff> staff = [];
  final List<Staff> market = [];
  final List<Show> shows = [];
  final Map<SlotId, SlotState> slots = {
    for (final s in SlotId.values) s: SlotState(),
  };
  final List<Loan> loans = [];
  final Set<String> ownedLuxury = {};
  final Set<String> ownedChannels = {};
  final Set<String> ownedEquip = {};
  final List<Film> films = [];
  final Set<String> ownedPlatforms = {};
  final Map<String, int> bizLevels = {};
  final List<Creator> creators = [];
  final List<Creator> creatorMarket = [];
  final List<DayStat> history = [];
  final List<double> todaySamples = [];
  double cashAtDayStart = startingCash;
  bool introSeen = false;
  bool adTouched = false;
  final Set<int> claimedGoals = {};
  final Map<SlotId, List<ReportRow>> lastReport = {};
  int reportDay = 0;
  int primeWins = 0;
  double bestRating = 0;
  int sponsorDeals = 0;
  int decisionsMade = 0;
  final List<Trophy> trophies = [];
  final Set<String> achievements = {};
  Decision? pendingDecision;
  final List<Tender> tenders = [];
  int tendersWon = 0;
  final Map<String, double> stockPrices = {};
  final Map<String, List<double>> stockHist = {};
  final Map<String, double> holdings = {};
  final Map<String, double> costBasis = {};
  double tradingProfit = 0;
  int lastStockHour = 0;
  List<AwardResult>? pendingAwards;
  final Map<String, NegState> negotiations = {};
  final List<double> cashHistory = [];
  final List<GameEvent> eventLog = [];
  int bonusPrestige = 0;
  double todayIncome = 0;
  double yesterdayIncome = 0;

  // ---- v0.12: şirket kimliği, lokasyonlar, ajans, yönetim kurulu, markalar ----
  String companyName = 'Kanal 9';
  int companySuffix = 0;
  CompanyLogo logo = CompanyLogo();
  bool identitySet = false;
  bool stingOn = true;
  final Set<String> ownedLocations = {};
  final Set<int> openedCities = {homeCityPlate};
  final Map<String, int> luxSold = {}; // fabrikadan satılan adet
  final Map<String, int> luxSerial = {}; // sahip olduğun parçanın seri no
  final List<LuxListing> luxListings = [];
  final Set<String> luxForSale = {};
  final List<LuxOffer> luxOffers = [];
  final Map<String, int> eventReadyDay = {};
  int agencyLevel = 0;
  final List<Staff> academy = [];
  final List<Staff> youthMarket = [];
  final List<Staff> transferMarket = [];
  final List<TransferOffer> transferOffers = [];
  int talentsSold = 0;
  double transferProfit = 0;
  final Map<ExecRole, Exec> execs = {};
  final List<Exec> execCandidates = [];
  final List<BrandOffer> brandOffers = [];
  final List<Deal> deals = [];
  int storyChoices = 0;
  double adDemand = 1.0; // reklam verenlerin günlük talebi (0,85–1,2)
  int eventsHeld = 0;

  /// Yeni yapım başlarken oynatılan şirket logosu (yapım adı)
  final sting = ValueNotifier<String?>(null);

  /// Ekranın altında kısa süre görünen bildirim.
  final toast = ValueNotifier<String?>(null);

  /// Açılışta gösterilecek "Sen yokken" özeti.
  PeriodSummary? pendingOffline;

  Timer? _timer;
  DateTime? _lastTick;
  bool _offlineMode = false;
  PeriodSummary? _acc;
  int _secondsSinceSave = 0;

  // =================================================================
  // Başlatma / kayıt
  // =================================================================

  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw != null) {
      try {
        _load(jsonDecode(raw));
        final lastSeen = DateTime.fromMillisecondsSinceEpoch(
          jsonDecode(raw)['savedAt'] as int,
        );
        _catchUp(DateTime.now().difference(lastSeen));
      } catch (e) {
        debugPrint('Kayıt okunamadı, yeni oyun: $e');
        _newGame();
      }
    } else {
      _newGame();
    }
    _dailyCheck();
    _startTimer();
    notifyListeners();
  }

  void _newGame() {
    careerStart = DateTime.now().millisecondsSinceEpoch;
    tainted = false;
    timeScale = 1;
    channelName = 'Kanal 9';
    cash = startingCash;
    diamonds = startingDiamonds;
    day = 1;
    dayProgress = 0;
    studioLevel = 0;
    staff.clear();
    market.clear();
    shows.clear();
    for (final s in slots.values) {
      s.showId = null;
      s.adMinutes = 8;
    }
    loans.clear();
    ownedLuxury.clear();
    ownedChannels.clear();
    ownedEquip.clear();
    films.clear();
    ownedPlatforms.clear();
    bizLevels.clear();
    creators.clear();
    creatorMarket.clear();
    history.clear();
    todaySamples.clear();
    cashAtDayStart = cash;
    introSeen = false;
    adTouched = false;
    claimedGoals.clear();
    lastReport.clear();
    reportDay = 0;
    primeWins = 0;
    bestRating = 0;
    sponsorDeals = 0;
    decisionsMade = 0;
    trophies.clear();
    achievements.clear();
    pendingDecision = null;
    pendingAwards = null;
    _initStocks();
    tenders.clear();
    tendersWon = 0;
    holdings.clear();
    costBasis.clear();
    tradingProfit = 0;
    _refreshCreators();
    negotiations.clear();
    cashHistory
      ..clear()
      ..add(cash);
    eventLog.clear();
    bonusPrestige = 0;
    todayIncome = 0;
    yesterdayIncome = 0;
    _resetV12();
    _refreshMarket();
    _tendersDaily();
    _log(
      'Kanal kuruldu',
      '$channelName yayın hayatına başladı. Bol reytingler!',
      true,
    );
  }

  Future<void> resetGame() async {
    _newGame();
    await save();
    _changed();
  }

  void _startTimer() {
    _timer?.cancel();
    _lastTick = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final dt = now.difference(_lastTick!).inMilliseconds / 1000.0;
    _lastTick = now;
    if (dt <= 0 || dt > 5) return; // uyku/arka plan atlamalarını yok say
    _advance(dt * timeScale / secondsPerDay);
    _secondsSinceSave++;
    if (_secondsSinceSave >= 20) {
      _secondsSinceSave = 0;
      save();
    }
    notifyListeners();
  }

  /// Uygulama arka plana atıldı.
  void onPause() {
    _timer?.cancel();
    save();
  }

  /// Uygulama geri geldi: aradaki süreyi çevrimdışı olarak işle.
  Future<void> onResume() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw != null) {
      final savedAt = DateTime.fromMillisecondsSinceEpoch(
        jsonDecode(raw)['savedAt'] as int,
      );
      _catchUp(DateTime.now().difference(savedAt));
    }
    _dailyCheck();
    _startTimer();
    notifyListeners();
  }

  double get offlineCapMinutes =>
      vip ? offlineCapMinutesVip : offlineCapMinutesFree;
  double get offlineSpeed => vip ? offlineSpeedVip : offlineSpeedFree;

  /// Genel Müdür (işe alınırsa): biten sezonları otomatik yeniler ve
  /// aynı kuşağa koyar. Günlük maaşı stüdyo seviyesiyle artar.
  bool get autoManager => execs.containsKey(ExecRole.genelMudur);

  double get managerSalary => 15000 * pow(1.9, studioLevel).toDouble() * kIncome;
  double get managerSigningFee => managerSalary * 10;

  /// Hızlı yol: orta seviye (55) bir Genel Müdür işe alır.
  String? hireManager() {
    if (autoManager) return 'Genel Müdür zaten görevde.';
    if (cash < managerSigningFee) {
      return 'İmza ücreti için ${fmtShort(managerSigningFee)} gerekli.';
    }
    cash -= managerSigningFee;
    execs[ExecRole.genelMudur] = Exec(
      _newId('e'),
      'Kemal Ardıç',
      ExecRole.genelMudur,
      55,
      managerSalary,
    );
    _notify(
      '🤵 Genel Müdür göreve başladı! Biten sezonları artık o yenileyecek.',
    );
    _changed();
    return null;
  }

  void fireManager() => fireExec(ExecRole.genelMudur);

  @visibleForTesting
  void debugAway(Duration d) => _catchUp(d);

  void _catchUp(Duration away) {
    // Telefon saati geri alındıysa (negatif süre) hiçbir şey işlenmez.
    final minutes = away.inSeconds / 60.0;
    if (minutes <= 0) return;
    if (minutes < 1) {
      // kısa ayrılık (ör. başka uygulamaya bakıp dönme): özet göstermeden işle
      _offlineMode = true;
      _advance(minutes * 60 / secondsPerDay);
      _offlineMode = false;
      return;
    }
    final counted = min(minutes, offlineCapMinutes);
    final sum = PeriodSummary()
      ..minutesAway = minutes
      ..minutesCounted = counted
      ..cashBefore = cash;
    _offlineMode = true;
    _acc = sum;
    _advance(counted * 60 / secondsPerDay * offlineSpeed);
    _offlineMode = false;
    _acc = null;
    sum.cashAfter = cash;
    pendingOffline = sum;
    save();
  }

  /// Reklam izleyerek çevrimdışı süreyi uzatma (şimdilik ödülsüz deneme).
  void dismissOffline() {
    pendingOffline = null;
    notifyListeners();
  }

  Timer? _saveDebounce;

  /// Oyuncu bir işlem yaptı: ekranı yenile ve kısa süre içinde kaydet.
  /// (Uygulama aniden kapansa bile son işlem kaybolmasın.)
  void _changed() {
    _checkGoals();
    _checkAchievements();
    notifyListeners();
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), save);
  }

  /// Bulut kaydı için oyunun tamamı (JSON metni)
  String exportSave() => jsonEncode(_toJson());

  /// Buluttan gelen kaydı yükle (yerel kaydın yerine geçer)
  Future<void> importSave(String raw) async {
    _load(jsonDecode(raw) as Map<String, dynamic>);
    await save();
    _changed();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
    'v': _saveVersion,
    'tainted': tainted,
    'savedAt': DateTime.now().millisecondsSinceEpoch,
    'idCounter': _idCounter,
    'channelName': channelName,
    'cash': cash,
    'diamonds': diamonds,
    'day': day,
    'dayProgress': dayProgress,
    'studioLevel': studioLevel,
    'vip': vip,
    'staff': staff.map((e) => e.toJson()).toList(),
    'market': market.map((e) => e.toJson()).toList(),
    'shows': shows.map((e) => e.toJson()).toList(),
    'slots': {for (final e in slots.entries) e.key.name: e.value.toJson()},
    'loans': loans.map((e) => e.toJson()).toList(),
    'ownedLuxury': ownedLuxury.toList(),
    'ownedChannels': ownedChannels.toList(),
    'ownedEquip': ownedEquip.toList(),
    'films': films.map((e) => e.toJson()).toList(),
    'ownedPlatforms': ownedPlatforms.toList(),
    'bizLevels': bizLevels,
    'creators': creators.map((e) => e.toJson()).toList(),
    'creatorMarket': creatorMarket.map((e) => e.toJson()).toList(),
    'history': history.map((e) => e.toJson()).toList(),
    'todaySamples': todaySamples.map((e) => e.round()).toList(),
    'cashAtDayStart': cashAtDayStart,
    'introSeen': introSeen,
    'managerHired': autoManager,
    'missionDate': missionDate,
    'missions': missions.map((m) => m.toJson()).toList(),
    'loginDate': loginDate,
    'loginStreak': loginStreak,
    'adTouched': adTouched,
    'claimedGoals': claimedGoals.toList(),
    'lastReport': {
      for (final e in lastReport.entries)
        e.key.name: e.value.map((r) => r.toJson()).toList(),
    },
    'reportDay': reportDay,
    'primeWins': primeWins,
    'bestRating': bestRating,
    'sponsorDeals': sponsorDeals,
    'decisionsMade': decisionsMade,
    'trophies': trophies.map((e) => e.toJson()).toList(),
    'achievements': achievements.toList(),
    'tenders': tenders.map((e) => e.toJson()).toList(),
    'tendersWon': tendersWon,
    'stockPrices': stockPrices,
    'stockHist': stockHist,
    'holdings': holdings,
    'costBasis': costBasis,
    'tradingProfit': tradingProfit,
    'lastStockHour': lastStockHour,
    'negotiations': {
      for (final e in negotiations.entries) e.key: e.value.toJson(),
    },
    'cashHistory': cashHistory,
    'eventLog': eventLog.map((e) => e.toJson()).toList(),
    'bonusPrestige': bonusPrestige,
    'todayIncome': todayIncome,
    'yesterdayIncome': yesterdayIncome,
    ..._v12ToJson(),
  };

  void _load(Map<String, dynamic> j) {
    _idCounter = j['idCounter'] ?? 0;
    tainted = j['tainted'] == true || ((j['timeScale'] as num?) ?? 1) > 1;
    channelName = j['channelName'];
    cash = (j['cash'] as num).toDouble();
    diamonds = j['diamonds'];
    day = j['day'];
    dayProgress = (j['dayProgress'] as num).toDouble();
    studioLevel = j['studioLevel'];
    vip = j['vip'] ?? false;
    staff
      ..clear()
      ..addAll((j['staff'] as List).map((e) => Staff.fromJson(e)));
    market
      ..clear()
      ..addAll((j['market'] as List).map((e) => Staff.fromJson(e)));
    shows
      ..clear()
      ..addAll((j['shows'] as List).map((e) => Show.fromJson(e)));
    final legacy = (j['v'] ?? 1) < 2; // 4 kuşaklı eski kayıt
    for (final s in slots.values) {
      s.showId = null;
      s.adMinutes = 8;
    }
    final sl = j['slots'] as Map<String, dynamic>;
    sl.forEach((k, v) {
      final id = legacy ? legacySlotNames[k] : SlotId.values.asNameMap()[k];
      if (id != null) slots[id] = SlotState.fromJson(v);
    });
    if (legacy) {
      for (final s in shows) {
        if (s.slot != null) s.slot = legacySlotMap[s.slot!.index];
        if (s.autoSlot != null) s.autoSlot = legacySlotMap[s.autoSlot!.index];
      }
    }
    loans
      ..clear()
      ..addAll((j['loans'] as List).map((e) => Loan.fromJson(e)));
    ownedLuxury
      ..clear()
      ..addAll(List<String>.from(j['ownedLuxury']));
    ownedChannels
      ..clear()
      ..addAll(List<String>.from(j['ownedChannels']));
    ownedEquip
      ..clear()
      ..addAll(List<String>.from(j['ownedEquip'] ?? []));
    films
      ..clear()
      ..addAll((j['films'] as List? ?? []).map((e) => Film.fromJson(e)));
    ownedPlatforms
      ..clear()
      ..addAll(List<String>.from(j['ownedPlatforms'] ?? []));
    bizLevels
      ..clear()
      ..addAll(Map<String, int>.from(j['bizLevels'] ?? {}));
    creators
      ..clear()
      ..addAll((j['creators'] as List? ?? []).map((e) => Creator.fromJson(e)));
    creatorMarket
      ..clear()
      ..addAll(
        (j['creatorMarket'] as List? ?? []).map((e) => Creator.fromJson(e)),
      );
    if (creatorMarket.isEmpty) _refreshCreators();
    history
      ..clear()
      ..addAll((j['history'] as List? ?? []).map((e) => DayStat.fromJson(e)));
    todaySamples
      ..clear()
      ..addAll(
        (j['todaySamples'] as List? ?? []).map((e) => (e as num).toDouble()),
      );
    cashAtDayStart = (j['cashAtDayStart'] as num? ?? cash).toDouble();
    introSeen = j['introSeen'] ?? true;
    missionDate = j['missionDate'] ?? '';
    missions
      ..clear()
      ..addAll((j['missions'] as List? ?? []).map((e) => Mission.fromJson(e)));
    loginDate = j['loginDate'] ?? '';
    loginStreak = j['loginStreak'] ?? 0;
    adTouched = j['adTouched'] ?? false;
    claimedGoals
      ..clear()
      ..addAll(List<int>.from(j['claimedGoals'] ?? []));
    lastReport.clear();
    (j['lastReport'] as Map<String, dynamic>? ?? {}).forEach((k, v) {
      final id = SlotId.values.asNameMap()[k];
      if (id != null && !legacy) {
        lastReport[id] = (v as List).map((e) => ReportRow.fromJson(e)).toList();
      }
    });
    reportDay = j['reportDay'] ?? 0;
    primeWins = j['primeWins'] ?? 0;
    bestRating = (j['bestRating'] as num? ?? 0).toDouble();
    sponsorDeals = j['sponsorDeals'] ?? 0;
    decisionsMade = j['decisionsMade'] ?? 0;
    trophies
      ..clear()
      ..addAll((j['trophies'] as List? ?? []).map((e) => Trophy.fromJson(e)));
    achievements
      ..clear()
      ..addAll(List<String>.from(j['achievements'] ?? []));
    tenders
      ..clear()
      ..addAll((j['tenders'] as List? ?? []).map((e) => Tender.fromJson(e)));
    tendersWon = j['tendersWon'] ?? 0;
    if (!tenders.any((t) => t.status == TenderStatus.open)) _tendersDaily();
    stockPrices.clear();
    stockHist.clear();
    if (j['stockPrices'] == null) {
      _initStocks();
    } else {
      (j['stockPrices'] as Map<String, dynamic>).forEach(
        (k, v) => stockPrices[k] = (v as num).toDouble(),
      );
      (j['stockHist'] as Map<String, dynamic>).forEach(
        (k, v) => stockHist[k] = (v as List)
            .map((e) => (e as num).toDouble())
            .toList(),
      );
      for (final d in stockDefs) {
        stockPrices.putIfAbsent(d.ticker, () => d.basePrice);
        stockHist.putIfAbsent(d.ticker, () => [d.basePrice]);
      }
    }
    holdings
      ..clear()
      ..addAll(
        (j['holdings'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
    costBasis
      ..clear()
      ..addAll(
        (j['costBasis'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
    tradingProfit = (j['tradingProfit'] as num? ?? 0).toDouble();
    lastStockHour = j['lastStockHour'] ?? ((day + dayProgress) * 24).floor();
    negotiations
      ..clear()
      ..addAll(
        (j['negotiations'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, NegState.fromJson(v)),
        ),
      );
    cashHistory
      ..clear()
      ..addAll((j['cashHistory'] as List).map((e) => (e as num).toDouble()));
    eventLog
      ..clear()
      ..addAll(
        (j['eventLog'] as List? ?? []).map((e) => GameEvent.fromJson(e)),
      );
    bonusPrestige = j['bonusPrestige'] ?? 0;
    todayIncome = (j['todayIncome'] as num? ?? 0).toDouble();
    yesterdayIncome = (j['yesterdayIncome'] as num? ?? 0).toDouble();
    _v12Load(j);
  }

  // =================================================================
  // Zaman akışı
  // =================================================================

  /// Testler için zamanı ileri sar.
  @visibleForTesting
  void debugAdvanceDays(double days) => _advance(days);

  void _advance(double days) {
    var rem = days;
    while (rem > 1e-9) {
      final step = min(rem, 1 - dayProgress);
      _accrue(step);
      dayProgress += step;
      rem -= step;
      final hourNow = (gameTime * 24).floor();
      if (lastStockHour < hourNow - 24 * 40) lastStockHour = hourNow - 24 * 40;
      while (lastStockHour < hourNow) {
        lastStockHour++;
        _stockTick(lastStockHour);
      }
      final pd = pendingDecision;
      if (pd != null && gameTime >= pd.deadline) {
        resolveDecision(pd.defaultOption, auto: true);
      }
      final hour = (dayProgress * 24).floor();
      while (todaySamples.length <= hour && todaySamples.length < 24) {
        todaySamples.add(cash);
      }
      if (dayProgress >= 1 - 1e-9) {
        dayProgress = 0;
        _endOfDay();
      }
    }
  }

  /// Gün içinde sürekli akan gelir ve üretim ilerlemesi.
  void _accrue(double step) {
    for (final s in shows) {
      if (s.status == ShowStatus.onAir && s.slot != null) {
        final inc = revenuePerDay(s) * step;
        cash += inc;
        todayIncome += inc;
        s.totalRevenue += inc;
        s.seasonRevenue += inc;
        _acc?.adIncome += inc;
      } else if (s.status == ShowStatus.producing) {
        s.prodLeft -= step;
        if (s.prodLeft <= 0) {
          s.prodLeft = 0;
          s.status = ShowStatus.ready;
          _acc?.finishedProductions++;
          final auto = s.autoSlot;
          if (auto != null &&
              slots[auto]!.showId == null &&
              slotUnlocked(auto)) {
            slots[auto]!.showId = s.id;
            s.slot = auto;
            s.status = ShowStatus.onAir;
          }
          s.autoSlot = null;
          _notify('🎬 "${s.name}" hazır! Yayın akışına koyabilirsin.');
        }
      }
    }
    final ch = channelIncomePerDay * step;
    cash += ch;
    todayIncome += ch;
    _acc?.channelIncome += ch;

    // Sinema: çekim ve gişe
    for (final f in films) {
      if (f.status == FilmStatus.producing) {
        f.prodLeft -= step;
        if (f.prodLeft <= 0) _finishFilm(f);
      } else if (f.status == FilmStatus.inTheaters) {
        final inc =
            boxOfficeForDay(f, f.theaterDay, reach, boxOfficeBonus) * step;
        cash += inc;
        todayIncome += inc;
        f.boxOffice += inc;
        _acc?.boxOffice += inc;
      }
    }
    for (final t in tenders) {
      if (t.status == TenderStatus.producing) {
        t.prodLeft -= step;
        if (t.prodLeft <= 0) _deliverTender(t);
      }
    }
    final pf = platformIncomePerDay * step;
    cash += pf;
    todayIncome += pf;
    _acc?.platformIncome += pf;
    final sp = (sponsorIncomePerDay + dealIncomePerDay) * step;
    cash += sp;
    todayIncome += sp;
    _acc?.sponsorIncome += sp;
    final dg = creatorIncomePerDay * step;
    cash += dg;
    todayIncome += dg;
    _acc?.digitalIncome += dg;
    final bz = bizIncomePerDay * step;
    cash += bz;
    todayIncome += bz;
    _acc?.bizIncome += bz;
  }

  void _finishFilm(Film f) {
    f.prodLeft = 0;
    f.status = FilmStatus.ready;
    f.finishedDay = day;
    f.score = filmScore(f.quality, 0.8 + _rng.nextDouble() * 0.4);
    for (final st in staff) {
      if (st.showId == f.id) st.showId = null;
    }
    _acc?.filmsDone++;
    _notify(
      '🎞️ "${f.name}" tamamlandı! İzleyici puanı ${fmtDec(f.score, 1)}. '
      'Vizyona sok ya da platformlara sat.',
    );
  }

  void _endOfDay() {
    day++;

    // Giderler
    final sal =
        dailySalaries +
        creators.fold(0.0, (a, c) => a + c.salary) +
        execSalaries;
    cash -= sal;
    _acc?.salaries += sal;
    final rent = dailyRent;
    cash -= rent;
    _acc?.rent += rent;
    final up = dailyUpkeep;
    cash -= up;
    _acc?.upkeep += up;

    // Kredi taksitleri
    for (final l in loans.toList()) {
      if (day >= l.nextDueDay) {
        cash -= l.installment;
        _acc?.loanPaid += l.installment;
        l.installmentsLeft--;
        l.nextDueDay += 7;
        if (l.installmentsLeft <= 0) {
          loans.remove(l);
          _notify('🏦 Bir kredi tamamen ödendi.');
        }
      }
    }

    // Yayındaki programlar: bölüm sayısı, reyting geçmişi, sezon sonu
    for (final s in shows) {
      if (s.status != ShowStatus.onAir || s.slot == null) continue;
      final r = currentRating(s);
      s.lastAiredDay = day;
      s.ratingHistory.add(r);
      if (s.ratingHistory.length > 30) s.ratingHistory.removeAt(0);
      _acc?.ratingSum += r;
      _acc?.ratingCount++;
      s.episodesAired++;
      s.noise = 0.92 + _rng.nextDouble() * 0.16;
      if (s.buffDays > 0) {
        s.buffDays--;
        if (s.buffDays == 0) s.buff = 1.0;
      }
      if (r > bestRating) bestRating = r;
      // izleyici sadakati: az reklam büyütür, çok reklam eritir
      final ret = adRetention(slots[s.slot]!.adMinutes, s.quality);
      if (ret >= 0.85) {
        s.loyalty = min(0.25, s.loyalty + 0.01);
      } else if (ret < 0.65) {
        s.loyalty = max(0.0, s.loyalty - 0.01);
      }
      if (s.sponsorDays > 0) {
        s.sponsorDays--;
        if (s.sponsorDays == 0) {
          _notify('🤝 ${s.sponsor} sponsorluğu "${s.name}" için sona erdi.');
          s.sponsor = null;
          s.sponsorPerDay = 0;
        }
      }
      if (s.episodesAired >= s.seasonDays) _endSeason(s);
    }
    _tendersDaily();
    _v12Daily();
    _buildReport();
    _stockNews();
    _maybeDecision();
    if (day % 30 == 0) _awardCeremony();

    for (final f in films) {
      if (f.status == FilmStatus.inTheaters) {
        f.theaterDay++;
        if (f.theaterDay >= theaterRunDays) {
          f.status = FilmStatus.library;
          _notify(
            '🍿 "${f.name}" vizyondan kalktı. Gişe: ${fmtShort(f.boxOffice)}. '
            'Artık platformlara lisanslayabilirsin.',
          );
        }
      }
      for (final l in f.licenses) {
        l.daysLeft--;
      }
      f.licenses.removeWhere((l) => l.daysLeft <= 0);
    }

    for (final c in creators) {
      // tavana yaklaştıkça büyüme yavaşlar (doyma)
      final room = max(0.0, 1 - c.followers / followerCap);
      c.followers *= 1 + c.growth * room;
      c.growth = max(0.002, c.growth * 0.995);
    }
    if (day % 5 == 0) _refreshCreators();

    _rollEvent();

    _refreshMarket(); // iş ilanları her gün yenilenir

    cashHistory.add(cash);
    if (cashHistory.length > 60) cashHistory.removeAt(0);
    final net = cash - cashAtDayStart;
    history.add(DayStat(day - 1, cash, todayIncome, todayIncome - net));
    if (history.length > 5000) history.removeAt(0);
    cashAtDayStart = cash;
    todaySamples
      ..clear()
      ..add(cash);
    yesterdayIncome = todayIncome;
    todayIncome = 0;
    _checkAchievements();
    _acc?.days++;
  }

  void _endSeason(Show s, {bool manual = false}) {
    final prevSlot = s.slot;
    slots[s.slot]?.showId = null;
    s.slot = null;
    s.status = ShowStatus.ended;
    s.buff = 1;
    s.buffDays = 0;
    s.sponsor = null;
    s.sponsorPerDay = 0;
    s.sponsorDays = 0;
    for (final st in staff) {
      if (st.showId == s.id) st.showId = null;
    }
    _acc?.endedSeasons++;
    if (autoManager && !manual && prevSlot != null) {
      // Genel Müdür: kasa elveriyorsa yeni sezonu başlatır
      final cost = showCostOf(s);
      final gm = execs[ExecRole.genelMudur]!;
      if (cash >= cost * (2.0 - gm.power * 0.8) && renewShow(s) == null) {
        s.autoSlot = prevSlot;
        _acc?.autoRenewed++;
        _notify(
          '🤵 Genel Müdür: "${s.name}" ${s.season}. sezon çekimlerine başladı.',
        );
        return;
      }
    }
    _notify(
      '🏁 "${s.name}" ${s.season}. sezon finali yaptı! '
      'Yeni sezon çekebilirsin.',
    );
  }

  // =================================================================
  // Rastgele olaylar
  // =================================================================

  void _rollEvent() {
    if (_rng.nextDouble() > 0.10) return;
    final onAir = shows.where((s) => s.status == ShowStatus.onAir).toList();
    final pick = _rng.nextInt(10);
    Show? s = onAir.isEmpty ? null : onAir[_rng.nextInt(onAir.length)];

    switch (pick) {
      case 0:
        if (s == null) return;
        s.buff = 1.2;
        s.buffDays = 2;
        _event(
          '📈 Viral oldu!',
          '"${s.name}" sosyal medyada gündem oldu. 2 gün reyting +%20.',
          true,
        );
      case 1:
        if (s == null || !s.def.needs.containsKey(Role.oyuncu)) return;
        if (_offerDecision(_setCrisisDecision(s))) return;
        s.buff = 0.92;
        s.buffDays = 1;
        _event(
          '😤 Sette kriz',
          '"${s.name}" başrolü sete geç geldi. 1 gün reyting -%8.',
          false,
        );
      case 2:
        final cost = (yesterdayIncome * 0.15).clamp(20000.0, 2e6);
        cash -= cost;
        _acc?.eventCash -= cost;
        _event(
          '⚡ Verici arızası',
          'Fırtına vericiyi vurdu. Onarım: ${fmtShort(cost)}',
          false,
        );
      case 3:
        if (s == null ||
            !(s.genre == Genre.magazin || s.genre == Genre.talkShow)) {
          return;
        }
        final fine =
            productionCost(s.genre, s.tier) *
            0.3 *
            (1 - execBonus(ExecRole.hukuk));
        if (_offerDecision(_regulatorDecision(s, fine))) return;
        cash -= fine;
        _acc?.eventCash -= fine;
        _event(
          '⚖️ Yayın Kurulu cezası',
          '"${s.name}" için ${fmtShort(fine)} idari para cezası.',
          false,
        );
      case 4:
        if (s == null) return;
        s.buff = 1.15;
        s.buffDays = 4;
        bonusPrestige += 15;
        _event(
          '🏆 Ödül töreni',
          '"${s.name}" yılın programı seçildi! +15 prestij, 4 gün reyting +%15.',
          true,
        );
      case 5:
        final amount = (yesterdayIncome * 1.5).clamp(80000.0, 50e6);
        _gain(amount);
        _acc?.eventCash += amount;
        _event(
          '🤝 Sponsor anlaşması',
          'Bir içecek markası sponsor oldu: +${fmtShort(amount)}',
          true,
        );
      case 6:
        if (s == null) return;
        if (_offerDecision(_scandalDecision(s))) return;
        s.buff = 1.12;
        s.buffDays = 2;
        bonusPrestige = max(0, bonusPrestige - 3);
        _event(
          '📰 Skandal manşette',
          '"${s.name}" kulis dedikodusuyla gazetelerde. Reyting +%12 ama -3 prestij.',
          true,
        );
      case 7:
        if (s == null) return;
        s.buff = 0.93;
        s.buffDays = 2;
        _event(
          '📺 Rakip hamlesi',
          'Rakip kanal aynı saate dev yapım koydu. "${s.name}" 2 gün -%7.',
          false,
        );
      case 9:
        final pool = films
            .where(
              (f) =>
                  f.status == FilmStatus.inTheaters ||
                  f.status == FilmStatus.library,
            )
            .toList();
        if (pool.isEmpty) return;
        final f = pool[_rng.nextInt(pool.length)];
        f.score = min(9.9, f.score + 0.5);
        bonusPrestige += 10;
        _event(
          '🎖️ Festival ödülü',
          '"${f.name}" uluslararası festivalde ödül aldı! Puan +0,5, +10 prestij.',
          true,
        );
      case 8:
        diamonds += 2;
        _event(
          '💎 Sadık izleyici',
          'İzleyici kulübü sana 2 elmas hediye etti.',
          true,
        );
    }
  }

  void _event(String title, String body, bool good) {
    _log(title, body, good);
    _acc?.events++;
    _notify('$title — $body');
  }

  void _log(String title, String body, bool good) {
    eventLog.insert(0, GameEvent(day, title, body, good));
    if (eventLog.length > 30) eventLog.removeLast();
  }

  void _notify(String msg) {
    if (_offlineMode) return;
    toast.value = msg;
  }

  void showToast(String msg) => toast.value = msg;

  // =================================================================
  // Hesaplanan değerler
  // =================================================================

  StudioLevel get studio => studioLevels[studioLevel];

  double get reach {
    var r = studio.reach;
    for (final id in ownedEquip) {
      r += equipById(id)?.reachBonus ?? 0;
    }
    return r * (1 + cityReachBonus);
  }

  int get prestige {
    var p =
        bonusPrestige +
        studioLevel * 50 +
        (bizEffect(BizEffect.prestige)).round();
    for (final d in luxuryDefs) {
      if (ownedLuxury.contains(d.id)) p += d.prestige;
    }
    for (final c in channelDefs) {
      if (ownedChannels.contains(c.id)) p += (c.price / 2e6).round();
    }
    for (final pf in platformDefs) {
      if (ownedPlatforms.contains(pf.id)) p += (pf.price / 2e6).round();
    }
    for (final l in locationDefs) {
      if (ownedLocations.contains(l.id)) p += l.prestige;
    }
    return p;
  }

  /// Şirket değeri: kasa + varlıklar - borç. Online sıralamanın temel ölçüsü.
  double get netWorth {
    var v = cash - debt;
    for (int i = 1; i <= studioLevel; i++) {
      v += studioLevels[i].upgradeCost * 0.7;
    }
    for (final id in ownedEquip) {
      v += (equipById(id)?.price ?? 0) * 0.5;
    }
    for (final c in channelDefs) {
      if (ownedChannels.contains(c.id)) v += c.price * 0.65;
    }
    for (final p in platformDefs) {
      if (ownedPlatforms.contains(p.id)) v += p.price * 0.65;
    }
    for (final d in luxuryDefs) {
      if (ownedLuxury.contains(d.id)) v += d.price * 0.7;
    }
    for (final b in bizDefs) {
      for (int l = 0; l < bizLevel(b.id); l++) {
        v += bizUpgradeCost(b, l) * 0.6;
      }
    }
    for (final f in films) {
      if (f.rightsOwned && f.score > 0) v += filmValue(f);
    }
    v += portfolioValue;
    for (final c in cityDefs) {
      if (openedCities.contains(c.plate)) v += c.price * 0.5;
    }
    for (final l in locationDefs) {
      if (ownedLocations.contains(l.id)) v += l.price * 0.5;
    }
    return v;
  }

  double get adBonus =>
      prestigeAdBonus(prestige) +
      bizEffect(BizEffect.adRate) +
      execBonus(ExecRole.genelMudur);

  // ---- Holding etkileri ----
  int bizLevel(String id) => bizLevels[id] ?? 0;

  /// Belirli etki türündeki tüm işletmelerin toplam etkisi.
  double bizEffect(BizEffect e, {Genre? genre}) {
    var v = 0.0;
    for (final b in bizDefs) {
      if (b.effect != e) continue;
      if (genre != null && b.genres.isNotEmpty && !b.genres.contains(genre)) {
        continue;
      }
      if (genre == null && b.genres.isNotEmpty) continue;
      v += b.perLevel * bizLevel(b.id);
    }
    return v;
  }

  double ratingMultFor(Genre g) =>
      (1 + bizEffect(BizEffect.showRating, genre: g) + digitalBoost) *
      (1 + cityGenreBonus(g)) *
      saturationFor(g) *
      rivalPressure;

  /// Aynı türden birden fazla program yayındaysa izleyici sıkılır.
  double saturationFor(Genre g) {
    final n = shows
        .where((s) => s.status == ShowStatus.onAir && s.genre == g)
        .length;
    return n <= 1 ? 1.0 : max(0.6, 1 - 0.12 * (n - 1));
  }

  /// Rakipler zamanla güçlenir ve seyirci çalar (zirvede kalmak emek ister).
  double get rivalPressure => max(0.65, 1 / (1 + day / 800));

  double get sponsorIncomePerDay => shows
      .where((s) => s.status == ShowStatus.onAir && s.sponsorDays > 0)
      .fold(0.0, (a, s) => a + s.sponsorPerDay) *
      kIncome;

  // ---- Dijital ----
  double get totalFollowers => creators.fold(0.0, (a, c) => a + c.followers);
  double get creatorIncomePerDay =>
      creators.fold(0.0, (a, c) => a + c.revenuePerDay);
  double get creatorSalaries => creators.fold(0.0, (a, c) => a + c.salary);

  /// Sosyal medya etkisi: takipçiler TV reytingini artırır (en fazla %10)
  double get digitalBoost => min(totalFollowers / 20e6, 0.10);
  double get boxOfficeBonus =>
      bizEffect(BizEffect.boxOffice) +
      ownedEquip.fold(
        0.0,
        (a, id) => a + (equipById(id)?.boxOfficeBonus ?? 0),
      ) +
      execBonus(ExecRole.sinema);
  double get licenseBonus => bizEffect(BizEffect.licenseFee);
  double get musicQualityBonus => bizEffect(BizEffect.quality);

  double get bizIncomePerDay =>
      bizDefs.fold(0.0, (a, b) => a + bizIncome(b, bizLevel(b.id))) * kIncome;

  double get platformIncomePerDay {
    if (ownedPlatforms.isEmpty) return 0;
    var v = platformDefs
        .where((p) => ownedPlatforms.contains(p.id))
        .fold(0.0, (a, p) => a + p.dailyIncome);
    for (final f in films) {
      if (f.onOwnPlatform && f.rightsOwned) {
        v += filmValue(f) * 0.004 * f.def.streaming;
      }
    }
    return v * kIncome;
  }

  double get boxOfficePerDay => films
      .where((f) => f.status == FilmStatus.inTheaters)
      .fold(
        0.0,
        (a, f) => a + boxOfficeForDay(f, f.theaterDay, reach, boxOfficeBonus),
      );

  /// Boşta bekleyen (programda olmayan) kadro yarım maaş alır.
  double get dailySalaries =>
      staff.fold(
        0.0,
        (a, s) => a + (s.showId == null ? s.salary * 0.5 : s.salary),
      ) +
      academy.fold(0.0, (a, s) => a + s.salary);
  double get dailyRent => studio.rentPerDay * kIncome * (1 - execBonus(ExecRole.finans));
  double get dailyUpkeep =>
      (ownedEquip.fold(0.0, (a, id) => a + (equipById(id)?.upkeepPerDay ?? 0)) +
          locationUpkeep) *
      kIncome *
      (1 - execBonus(ExecRole.finans));
  double get debt => loans.fold(0.0, (a, l) => a + l.remaining);

  double get channelIncomePerDay => channelDefs
      .where((c) => ownedChannels.contains(c.id))
      .fold(0.0, (a, c) => a + c.dailyIncome) *
      kIncome;

  double get adIncomePerDay => shows
      .where((s) => s.status == ShowStatus.onAir)
      .fold(0.0, (a, s) => a + revenuePerDay(s));

  double get netPerDay =>
      adIncomePerDay +
      channelIncomePerDay +
      platformIncomePerDay +
      bizIncomePerDay +
      creatorIncomePerDay +
      sponsorIncomePerDay +
      dealIncomePerDay -
      creatorSalaries -
      execSalaries +
      boxOfficePerDay -
      dailySalaries -
      dailyRent -
      dailyUpkeep;

  double currentRating(Show s) {
    if (s.slot == null) return 0;
    return showRating(s, s.slot!, slots[s.slot]!.adMinutes) *
        ratingMultFor(s.genre) *
        showExtraMult(s);
  }

  /// Programı belirli bir kuşağa koysak reytingi ne olurdu (önizleme).
  double previewRating(Show s, SlotId slot) =>
      showRating(s, slot, slots[slot]!.adMinutes) *
      ratingMultFor(s.genre) *
      showExtraMult(s);

  double viewers(Show s) =>
      s.slot == null ? 0 : viewersFor(currentRating(s), s.slot!, reach);

  /// Net yayın geliri: büyük bütçe, ünlü konuk ve dış çekim bölüm başı
  /// gelirden pay alır (bkz. [runShare]).
  double revenuePerDay(Show s) => grossRevenuePerDay(s) * runShare(s);

  double grossRevenuePerDay(Show s) {
    if (s.slot == null) return 0;
    final m = slots[s.slot]!.adMinutes;
    return adRevenuePerDay(viewers(s), m, s.slot!, adBonus) * adDemand * kIncome;
  }

  double get totalViewers => shows
      .where((s) => s.status == ShowStatus.onAir)
      .fold(0.0, (a, s) => a + viewers(s));

  bool slotUnlocked(SlotId id) => studioLevel + 1 >= slotDefs[id]!.unlockLevel;

  Show? showById(String? id) {
    if (id == null) return null;
    for (final s in shows) {
      if (s.id == id) return s;
    }
    return null;
  }

  Staff? staffById(String id) {
    for (final s in staff) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Kişinin çalıştığı program veya filmin adı (boştaysa null)
  String? assignmentOf(Staff p) {
    if (p.showId == null) return null;
    final s = showById(p.showId);
    if (s != null) return s.name;
    for (final f in films) {
      if (f.id == p.showId) return '🎬 ${f.name}';
    }
    for (final t in tenders) {
      if (t.id == p.showId) return '🏛️ ${t.def.title}';
    }
    return null;
  }

  List<Staff> freeStaff(Role r) =>
      staff.where((s) => s.role == r && s.showId == null).toList();

  bool formatUnlocked(Genre g, int tier) {
    final f = formatOf(g, tier);
    return studioLevel + 1 >= f.unlockLevel &&
        (f.reqEquip == null || ownedEquip.contains(f.reqEquip));
  }

  bool genreUnlocked(Genre g) {
    final req = genreDefs[g]!.reqEquip;
    return req == null || ownedEquip.contains(req);
  }

  double prodSpeedMult() {
    var m = 1 - bizEffect(BizEffect.prodSpeed);
    for (final id in ownedEquip) {
      m *= equipById(id)?.prodSpeed ?? 1;
    }
    return m;
  }

  // =================================================================
  // Kadro
  // =================================================================

  String _newId(String p) => '$p${++_idCounter}';

  Staff _randomPerson(Role role) {
    final base =
        30 + studioLevel * 9 + bizEffect(BizEffect.marketSkill).round();
    // yaklaşık normal dağılım
    final g =
        (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() - 1.5) * 2;
    var skill = (base + g * 16).round().clamp(8, 99);
    if (_rng.nextDouble() < 0.06) skill = 85 + _rng.nextInt(14); // yıldız!
    final name =
        '${firstNames[_rng.nextInt(firstNames.length)]} ${lastNames[_rng.nextInt(lastNames.length)]}';
    final salary =
        (salaryFor(skill) * (0.85 + _rng.nextDouble() * 0.3) / 100).round() *
        100.0;
    return Staff(
      id: _newId('p'),
      name: name,
      role: role,
      skill: skill,
      salary: salary,
    );
  }

  /// Adayların yenilenmesine kalan gerçek süre (saniye)
  int get marketRefreshSeconds =>
      ((1 - dayProgress) * secondsPerDay / max(timeScale, 1)).ceil();

  /// Her rolde en az bir iyi aday
  Staff _goodPerson(Role r) {
    final p = _randomPerson(r);
    final target = min(95, 52 + studioLevel * 7 + _rng.nextInt(12));
    if (p.skill < target) {
      p.skill = target;
      p.potential = max(p.potential, target);
      p.salary = (salaryFor(target) * (0.9 + _rng.nextDouble() * 0.25) / 100).round() * 100.0;
    }
    return p;
  }

  /// Tek bir rol için yeni adaylar (1 elmas): biri mutlaka iyi
  String? refreshRole(Role r) {
    if (diamonds < 1) return 'Yeterli elmasın yok (1 💎 gerekli).';
    diamonds -= 1;
    market.removeWhere((p) => p.role == r);
    market.add(_goodPerson(r));
    market.add(_goodPerson(r));
    market.add(_randomPerson(r));
    _changed();
    return null;
  }

  void _refreshMarket() {
    market.clear();
    for (final r in Role.values) {
      market.add(_randomPerson(r));
      market.add(_goodPerson(r));
    }
    market.add(_randomPerson(Role.values[_rng.nextInt(4)]));
    market.add(_randomPerson(Role.values[_rng.nextInt(4)]));
    market.sort((a, b) => a.role.index.compareTo(b.role.index));
    // Günün Yıldızı: her gün yüksek puanlı (ama daha pahalı) bir aday
    final star = _randomPerson(Role.values[_rng.nextInt(4)]);
    star.skill = min(
      99,
      max(star.skill, 80 + studioLevel * 2 + _rng.nextInt(12)),
    );
    star.salary = (salaryFor(star.skill) * 1.3 / 100).round() * 100.0;
    market.insert(0, star);
  }

  String? refreshMarketPaid() {
    if (diamonds < 3) return 'Yeterli elmasın yok (3 💎 gerekli).';
    diamonds -= 3;
    _refreshMarket();
    _changed();
    return null;
  }

  String? hire(Staff p) {
    if (staff.length >= studio.maxStaff) {
      return 'Kadro dolu (${studio.maxStaff}). Stüdyoyu büyüt.';
    }
    final fee = signingFeeFor(p);
    if (cash < fee) return 'İmza ücreti için kasada para yok.';
    cash -= fee;
    market.remove(p);
    staff.add(p);
    _count('hire');
    _notify('✍️ ${p.name} kadroya katıldı!');
    _changed();
    return null;
  }

  String? fire(Staff p) {
    if (p.showId != null) return 'Bu kişi bir programda çalışıyor.';
    final severance = p.salary * 3;
    cash -= severance;
    staff.remove(p);
    _forgetPerson(p);
    _notify('${p.name} ile yollar ayrıldı (tazminat ${fmtShort(severance)}).');
    _changed();
    return null;
  }

  // =================================================================
  // Yapım
  // =================================================================

  String? createShow(
    String name,
    Genre genre,
    int tier,
    List<Staff> crew, {
    int budget = 1,
    int guest = 0,
    String? location,
  }) {
    final def = genreDefs[genre]!;
    if (!genreUnlocked(genre)) {
      return '${def.label} için ${equipById(def.reqEquip!)!.name} gerekli.';
    }
    final fmt = formatOf(genre, tier);
    if (!formatUnlocked(genre, tier)) {
      return fmt.reqEquip != null && !ownedEquip.contains(fmt.reqEquip)
          ? '${fmt.name} için ${equipById(fmt.reqEquip!)!.name} gerekli.'
          : '${fmt.name} için stüdyo seviyesi ${fmt.unlockLevel} gerekli.';
    }
    for (final e in def.needs.entries) {
      final n = crew.where((c) => c.role == e.key).length;
      if (n < e.value) return '${e.value} ${e.key.label} seçmelisin.';
    }
    final optErr = prodOptionError(genre, budget, guest, location);
    if (optErr != null) return optErr;
    final cost = showCost(genre, tier, budget, guest, location);
    if (cash < cost) return 'Kasada yeterli para yok (${fmtShort(cost)}).';
    cash -= cost;
    final s = Show(
      budget: budget,
      guest: guest,
      guestName: guest > 0
          ? guestTiers[guest].names[_rng.nextInt(
              guestTiers[guest].names.length,
            )]
          : null,
      location: location,
      id: _newId('s'),
      name: name.trim().isEmpty ? showNameIdeas[genre]!.first : name.trim(),
      genre: genre,
      tier: tier,
      staffIds: crew.map((c) => c.id).toList(),
      prodLeft: def.prodDays * prodSpeedMult(),
      quality: fullShowQuality(crew, genre, tier, budget, location),
    );
    for (final c in crew) {
      c.showId = s.id;
    }
    shows.insert(0, s);
    _playSting(s.name);
    _count('show');
    _notify('🎥 "${s.name}" çekimleri başladı!');
    _changed();
    return null;
  }

  /// Biten programın yeni sezonu: aynı ekip, hafif yorgunluk.
  String? renewShow(Show s) {
    if (s.status != ShowStatus.ended) return null;
    final crew = <Staff>[];
    for (final id in s.staffIds) {
      final st = staffById(id);
      if (st == null) return 'Ekipten biri artık kadroda değil.';
      if (st.showId != null) return '${st.name} başka bir programda.';
      crew.add(st);
    }
    final cost = showCostOf(s);
    if (cash < cost) return 'Kasada yeterli para yok (${fmtShort(cost)}).';
    cash -= cost;
    for (final c in crew) {
      c.showId = s.id;
    }
    final fatigue = max(0.75, pow(0.97, s.season).toDouble());
    s
      ..season += 1
      ..episodesAired = 0
      ..seasonRevenue = 0
      ..status = ShowStatus.producing
      ..prodLeft = max(1.0, s.def.prodDays - 1) * prodSpeedMult()
      ..quality =
          fullShowQuality(crew, s.genre, s.tier, s.budget, s.location) * fatigue
      ..ratingHistory.clear();
    if (!_offlineMode) _count('show');
    _notify('🎥 "${s.name}" ${s.season}. sezon çekimleri başladı!');
    _changed();
    return null;
  }

  int speedUpCost(Show s) => max(1, (s.prodLeft * 3).ceil());

  String? speedUp(Show s) {
    final c = speedUpCost(s);
    if (diamonds < c) return 'Yeterli elmas yok ($c 💎).';
    diamonds -= c;
    s.prodLeft = 0.0001;
    _advance(0.0002);
    _changed();
    return null;
  }

  void deleteShow(Show s) {
    if (s.status != ShowStatus.ended) return;
    shows.remove(s);
    _changed();
  }

  // =================================================================
  // Yayın akışı
  // =================================================================

  String? putOnAir(Show s, SlotId slot) {
    if (s.status != ShowStatus.ready) return 'Program yayına hazır değil.';
    if (!slotUnlocked(slot)) return 'Bu kuşak henüz açık değil.';
    if (slots[slot]!.showId != null) return 'Bu kuşak dolu.';
    slots[slot]!.showId = s.id;
    s.slot = slot;
    s.status = ShowStatus.onAir;
    _count('air');
    _notify('📡 "${s.name}" ${slotDefs[slot]!.label} kuşağında yayında!');
    _changed();
    return null;
  }

  /// Yayındaki programı başka kuşağa taşır; hedef doluysa yer değiştirir.
  /// Sezon kesilmez, bölüm sayısı korunur.
  String? moveShow(Show s, SlotId to) {
    if (s.status != ShowStatus.onAir || s.slot == null)
      return 'Program yayında değil.';
    if (!slotUnlocked(to)) return 'Bu kuşak henüz açık değil.';
    final from = s.slot!;
    if (from == to) return null;
    final other = showById(slots[to]!.showId);
    slots[to]!.showId = s.id;
    s.slot = to;
    slots[from]!.showId = other?.id;
    other?.slot = from;
    _notify(
      other == null
          ? '🔀 "${s.name}" ${slotDefs[to]!.label} kuşağına taşındı.'
          : '🔀 "${s.name}" ile "${other.name}" yer değiştirdi.',
    );
    _changed();
    return null;
  }

  void takeOffAir(SlotId slot) {
    final s = showById(slots[slot]!.showId);
    if (s != null) _endSeason(s, manual: true);
    _changed();
  }

  void setAdMinutes(SlotId slot, double m) {
    if (slots[slot]!.adMinutes != m) _count('ads');
    slots[slot]!.adMinutes = m;
    adTouched = true;
    _changed();
  }

  // =================================================================
  // Stüdyo, ekipman
  // =================================================================

  String? upgradeStudio({double discount = 0}) {
    if (studioLevel >= studioLevels.length - 1) return 'Zaten en üst seviye!';
    final next = studioLevels[studioLevel + 1];
    final cost = next.upgradeCost * (1 - discount);
    if (cash < cost) return 'Kasada yeterli para yok.';
    cash -= cost;
    studioLevel++;
    _refreshMarket();
    _log('Stüdyo büyüdü', '$channelName artık bir ${next.name}!', true);
    _notify('🏗️ Tebrikler! Artık bir ${next.name}sın!');
    _ensureExecCandidates();
    _changed();
    return null;
  }

  String? buyEquip(EquipDef e, {double discount = 0}) {
    if (ownedEquip.contains(e.id)) return 'Zaten sahipsin.';
    if (studioLevel + 1 < e.reqLevel) {
      return 'Stüdyo seviyesi ${e.reqLevel} gerekli.';
    }
    final cost = e.price * (1 - discount);
    if (cash < cost) return 'Kasada yeterli para yok.';
    cash -= cost;
    ownedEquip.add(e.id);
    _notify('🛠️ ${e.name} satın alındı!');
    _changed();
    return null;
  }

  // =================================================================
  // Banka
  // =================================================================

  String? takeLoan(LoanOffer o) {
    if (loans.length >= 3) return 'En fazla 3 açık kredin olabilir.';
    _gain(o.amount);
    loans.add(
      Loan(
        id: _newId('l'),
        principal: o.amount,
        installment: o.installment,
        installmentsLeft: o.installments,
        nextDueDay: day + 7,
      ),
    );
    _notify('🏦 ${fmtShort(o.amount)} kredi hesabına yattı.');
    _changed();
    return null;
  }

  /// Erken kapama: kalan borcun %90'ı.
  double payoffAmount(Loan l) => l.remaining * 0.9;

  String? payOffLoan(Loan l) {
    final amt = payoffAmount(l);
    if (cash < amt) return 'Kasada yeterli para yok.';
    cash -= amt;
    loans.remove(l);
    _notify('🏦 Kredi erken kapatıldı.');
    _changed();
    return null;
  }

  // =================================================================
  // Lüks ve kanallar (pazarlık)
  // =================================================================

  String? buyFixed(LuxuryDef d, {double discount = 0}) {
    if (ownedLuxury.contains(d.id)) return 'Zaten sahipsin.';
    if (luxSoldOut(d)) return 'Fabrikada kalmadı. İkinci el pazara bak.';
    final cost = d.price * (1 - discount);
    if (cash < cost) return 'Kasada yeterli para yok.';
    cash -= cost;
    ownedLuxury.add(d.id);
    _assignSerial(d);
    _notify('✨ ${d.name} artık senin! +${d.prestige} prestij');
    _changed();
    return null;
  }

  double sellValueLuxury(LuxuryDef d) => d.price * 0.7;

  void sellLuxury(LuxuryDef d) {
    if (!ownedLuxury.remove(d.id)) return;
    _dropLux(d.id);
    _gain(sellValueLuxury(d));
    _notify('${d.name} satıldı: +${fmtShort(sellValueLuxury(d))}');
    _changed();
  }

  /// Satış değeri, pazarlıkta inilebilecek en düşük fiyatın (%74) altında
  /// tutulur; böylece "ucuza al, pahalıya sat" döngüsüyle para basılamaz.
  double sellValueChannel(ChannelDef c) => c.price * 0.65;

  void sellChannel(ChannelDef c) {
    if (!ownedChannels.remove(c.id)) return;
    _gain(sellValueChannel(c));
    _notify('${c.name} satıldı: +${fmtShort(sellValueChannel(c))}');
    _changed();
  }

  NegState negFor(String id) => negotiations.putIfAbsent(
    id,
    () => NegState(floorFactor: 0.74 + _rng.nextDouble() * 0.18),
  );

  bool negLocked(String id) => (negotiations[id]?.lockedUntil ?? 0) > day;

  static const _acceptLines = [
    'Anlaştık! Elini sıkıyorum.',
    'Pazarlıkta ustasın, hayırlı olsun!',
    'Tamam tamam, senin olsun.',
  ];
  static const _counterLines = [
    'Yaklaştın ama olmaz. Şuna ne dersin?',
    'Bu fiyata veremem, ortada buluşalım.',
    'Eşim beni evden atar! Son sözüm şu:',
  ];
  static const _rejectLines = [
    'Şaka yapıyorsun herhalde!',
    'Bu teklif hakaret gibi.',
    'Bu fiyata sana ancak maketini veririm.',
  ];

  String _pick(List<String> l) => l[_rng.nextInt(l.length)];

  /// Pazarlık turu. [price] satıcının istediği fiyat, [onWin] satın alma.
  NegResult negotiate(String id, double price, double offer) {
    final st = negFor(id);
    if (negLocked(id)) {
      return NegResult(
        NegOutcome.locked,
        'Satıcı seninle konuşmak istemiyor. ${st.lockedUntil - day} gün bekle.',
      );
    }
    if (cash < offer) {
      return const NegResult(
        NegOutcome.noMoney,
        'Önce kasanı doldur, sonra konuşalım.',
      );
    }
    final floor = price * st.floorFactor;
    if (offer >= floor) {
      return NegResult(NegOutcome.accepted, _pick(_acceptLines), offer);
    }
    st.patience--;
    if (st.patience <= 0) {
      st
        ..patience = 3
        ..counter = null
        ..lockedUntil = day + 3
        ..floorFactor = min(0.97, st.floorFactor + 0.04);
      _changed();
      return const NegResult(
        NegOutcome.walkedAway,
        'Yeter! Satıcı masadan kalktı. 3 gün sonra tekrar dene.',
      );
    }
    if (offer >= floor * 0.88) {
      final prev = st.counter ?? price;
      final c = max(floor * 1.02, (offer + prev) / 2);
      st.counter = (c / 1000).round() * 1000.0;
      _changed();
      return NegResult(NegOutcome.counter, _pick(_counterLines), st.counter);
    }
    _changed();
    return NegResult(NegOutcome.rejected, _pick(_rejectLines));
  }

  /// Pazarlık başarıyla bitti: öde ve sahiplen.
  void completePurchase(String id, double paid) {
    cash -= paid;
    negotiations.remove(id);
    final lux = luxuryDefs.where((d) => d.id == id);
    final plat = platformById(id);
    if (plat != null) {
      ownedPlatforms.add(id);
      _log(
        'Platform satın alındı',
        '${plat.name} artık $channelName ailesinde!',
        true,
      );
      _notify(
        '📲 ${plat.name} artık senin! ${fmtDec(plat.subscribersM, 1)} M abone, '
        'günlük +${fmtShort(plat.dailyIncome)}',
      );
    } else if (lux.isNotEmpty) {
      ownedLuxury.add(id);
      _assignSerial(lux.first);
      _notify(
        '✨ ${lux.first.name} artık senin! +${lux.first.prestige} prestij',
      );
    } else {
      final ch = channelDefs.firstWhere((c) => c.id == id);
      ownedChannels.add(id);
      _log(
        'Kanal satın alındı',
        '${ch.name} artık $channelName ailesinde!',
        true,
      );
      _notify('📺 ${ch.name} artık senin! Günlük +${fmtShort(ch.dailyIncome)}');
    }
    _changed();
  }

  // =================================================================
  // Sinema
  // =================================================================

  bool filmGenreUnlocked(FilmGenre g) {
    final req = filmGenreDefs[g]!.reqEquip;
    return req == null || ownedEquip.contains(req);
  }

  double filmQuality(List<Staff> crew, int tier) {
    if (crew.isEmpty) return 0;
    final avg =
        crew.map((s) => s.skill).reduce((a, b) => a + b) / crew.length / 100;
    var bonus = musicQualityBonus;
    for (final id in ownedEquip) {
      bonus += equipById(id)?.filmBonus ?? 0;
    }
    if (ownedEquip.contains('sound')) bonus += 0.04;
    return (avg * budgetTiers[tier].qualityMult * (1 + bonus)).clamp(0.0, 1.3);
  }

  String? createFilm(
    String name,
    FilmGenre genre,
    int tier,
    List<Staff> crew, {
    String? location,
  }) {
    final def = filmGenreDefs[genre]!;
    if (!filmGenreUnlocked(genre)) {
      return '${def.label} için ${equipById(def.reqEquip!)!.name} gerekli.';
    }
    for (final e in def.needs.entries) {
      if (crew.where((c) => c.role == e.key).length < e.value) {
        return '${e.value} ${e.key.label} seçmelisin.';
      }
    }
    if (location != null && !ownedLocations.contains(location)) {
      return 'Bu lokasyonda setin yok.';
    }
    final cost = filmCost(genre, tier) + filmLocationFee(genre, tier, location);
    if (cash < cost) return 'Kasada yeterli para yok (${fmtShort(cost)}).';
    cash -= cost;
    final f = Film(
      id: _newId('f'),
      name: name.trim().isEmpty ? filmNameIdeas[genre]!.first : name.trim(),
      genre: genre,
      tier: tier,
      staffIds: crew.map((c) => c.id).toList(),
      cost: cost,
      prodLeft: def.prodDays * prodSpeedMult(),
      quality: (filmQuality(crew, tier) * filmExtraMult(crew, genre, location))
          .clamp(0.0, 1.5),
    );
    for (final c in crew) {
      c.showId = f.id;
    }
    films.insert(0, f);
    _playSting(f.name);
    _count('film');
    _notify('🎬 "${f.name}" filminin çekimleri başladı!');
    _changed();
    return null;
  }

  int filmSpeedUpCost(Film f) => max(1, (f.prodLeft * 2).ceil());

  String? speedUpFilm(Film f) {
    final c = filmSpeedUpCost(f);
    if (diamonds < c) return 'Yeterli elmas yok ($c 💎).';
    diamonds -= c;
    _finishFilm(f);
    _changed();
    return null;
  }

  String? releaseInTheaters(Film f) {
    if (f.status != FilmStatus.ready) return 'Film vizyona hazır değil.';
    f.status = FilmStatus.inTheaters;
    f.theaterDay = 0;
    _notify('🍿 "${f.name}" bugün vizyonda! $theaterRunDays gün salonlarda.');
    _changed();
    return null;
  }

  /// Platformun bu filmi alması için gereken en düşük puan.
  double minScoreFor(PlatformDef p) =>
      [0.0, 4.0, 5.0, 6.0, 7.0][platformDefs.indexOf(p)];

  double licenseOfferFor(Film f, PlatformDef p) =>
      licenseOffer(f, p, licenseBonus);

  String? licenseFilm(Film f, PlatformDef p) {
    if (!f.rightsOwned) return 'Bu filmin hakları artık sende değil.';
    if (f.status == FilmStatus.producing || f.status == FilmStatus.inTheaters) {
      return 'Film vizyondayken platforma verilemez.';
    }
    if (ownedPlatforms.contains(p.id)) {
      return '${p.name} zaten senin. "Kendi platformunda yayınla"yı kullan.';
    }
    if (f.licenses.any((l) => l.platformId == p.id)) {
      return '${p.name} ile lisans zaten sürüyor.';
    }
    if (f.score < minScoreFor(p)) {
      return '${p.name} en az ${fmtDec(minScoreFor(p), 0)} puanlı filmleri alır.';
    }
    final fee = licenseOfferFor(f, p);
    cash += fee;
    todayIncome += fee;
    f.licenseIncome += fee;
    f.licensesSold++;
    f.licenses.add(FilmLicense(p.id, licenseDays, fee));
    _count('license');
    if (f.status == FilmStatus.ready) f.status = FilmStatus.library;
    _notify(
      '📲 "${f.name}" $licenseDays günlüğüne ${p.name}\'a satıldı: +${fmtShort(fee)}',
    );
    _changed();
    return null;
  }

  String? toggleOwnPlatform(Film f) {
    if (ownedPlatforms.isEmpty) return 'Önce bir dijital platform satın al.';
    if (!f.rightsOwned) return 'Bu filmin hakları artık sende değil.';
    if (f.status == FilmStatus.producing || f.status == FilmStatus.inTheaters) {
      return 'Film vizyondayken platforma konamaz.';
    }
    f.onOwnPlatform = !f.onOwnPlatform;
    if (f.status == FilmStatus.ready) f.status = FilmStatus.library;
    _changed();
    return null;
  }

  double rightsValueFor(Film f) => rightsSaleValue(f) * (1 + licenseBonus);

  String? sellRights(Film f) {
    if (!f.rightsOwned) return 'Haklar zaten satıldı.';
    if (f.status == FilmStatus.producing || f.status == FilmStatus.inTheaters) {
      return 'Vizyon bitmeden haklar satılamaz.';
    }
    final v = rightsValueFor(f);
    cash += v;
    todayIncome += v;
    f.soldFor = v;
    f.status = FilmStatus.rightsSold;
    f.onOwnPlatform = false;
    _notify('💼 "${f.name}" filminin tüm hakları satıldı: +${fmtShort(v)}');
    _changed();
    return null;
  }

  void deleteFilm(Film f) {
    if (f.status != FilmStatus.rightsSold) return;
    films.remove(f);
    _changed();
  }

  // =================================================================
  // Dijital: içerik üreticileri
  // =================================================================

  static const _ascii = {
    'ç': 'c',
    'ğ': 'g',
    'ı': 'i',
    'ö': 'o',
    'ş': 's',
    'ü': 'u',
    'â': 'a',
  };

  Creator _randomCreator() {
    final niche = Niche.values[_rng.nextInt(Niche.values.length)];
    final first = firstNames[_rng.nextInt(firstNames.length)];
    final last = lastNames[_rng.nextInt(lastNames.length)];
    var h = first.toLowerCase();
    _ascii.forEach((k, v) => h = h.replaceAll(k, v));
    final followers =
        (20000 * pow(2.6, studioLevel) * (0.3 + _rng.nextDouble() * 2.7))
            .roundToDouble();
    final engagement = 0.02 + _rng.nextDouble() * 0.06;
    final rev = followers * engagement * 2;
    return Creator(
      id: _newId('c'),
      name: '$first $last',
      handle: '@$h.${niche.handleWord}',
      niche: niche,
      followers: followers,
      growth: 0.005 + _rng.nextDouble() * 0.025,
      engagement: engagement,
      salary: (rev * kIncome * (0.35 + _rng.nextDouble() * 0.2) / 100).round() * 100.0,
      look: _rng.nextInt(1000),
    );
  }

  /// Dijitalin yıldızları: her zaman pazarın en iyileri ve en pahalıları.
  /// (id, ad, kullanıcı adı, alan, kadın mı, görünüm tohumu)
  static const starCreatorDefs = [
    ('star_a1rr', 'A1rr', '@a1rr', Niche.oyun, false, 9101),
    ('star_angel', 'Angel', '@angel', Niche.guzellik, true, 9202),
    ('star_krystal', 'Krystal', '@krystal', Niche.muzik, false, 9303),
  ];

  static bool isFemaleCreator(Creator c) => c.id == 'star_angel';
  static bool isStarCreator(Creator c) => c.id.startsWith('star_');

  Creator _starCreator(int i) {
    final d = starCreatorDefs[i];
    final followers = (20000 * pow(2.6, studioLevel) * (4.6 + i * 0.35)).roundToDouble();
    const engagement = 0.092;
    final rev = followers * engagement * 2;
    return Creator(
      id: d.$1,
      name: d.$2,
      handle: d.$3,
      niche: d.$4,
      followers: followers,
      growth: 0.03,
      engagement: engagement,
      salary: (rev * kIncome * 0.62 / 100).round() * 100.0,
      look: d.$6,
    );
  }

  void _refreshCreators() {
    creatorMarket.clear();
    for (int i = 0; i < starCreatorDefs.length; i++) {
      final id = starCreatorDefs[i].$1;
      if (!creators.any((c) => c.id == id)) creatorMarket.add(_starCreator(i));
    }
    creatorMarket.addAll(List.generate(6, (_) => _randomCreator()));
  }

  String? refreshCreatorsPaid() {
    if (diamonds < 3) return 'Yeterli elmasın yok (3 💎 gerekli).';
    diamonds -= 3;
    _refreshCreators();
    _changed();
    return null;
  }

  int get maxCreators => 3 + min(studioLevel, 5) * 2 + max(0, studioLevel - 5);

  /// Bir içerik üreticisinin ulaşabileceği en fazla takipçi (erişime bağlı)
  double get followerCap => 3e6 * reach * reach;

  String? signCreator(Creator c) {
    if (creators.length >= maxCreators) {
      return 'En fazla $maxCreators içerik üreticin olabilir. Stüdyoyu büyüt.';
    }
    if (cash < c.signingFee) return 'İmza ücreti için kasada para yok.';
    cash -= c.signingFee;
    creatorMarket.remove(c);
    creators.add(c);
    _notify(
      '📱 ${c.handle} artık $channelName ailesinde! '
      '${fmtShort(c.followers).replaceAll(' ₺', '')} takipçi',
    );
    _changed();
    return null;
  }

  void releaseCreator(Creator c) {
    creators.remove(c);
    _notify('${c.handle} ile sözleşme bitti.');
    _changed();
  }

  String? runCampaign(Creator c) {
    if (day < c.campaignReadyDay) {
      return 'Kampanya ${c.campaignReadyDay - day} gün sonra tekrar yapılabilir.';
    }
    final cost = c.campaignCost;
    if (cash < cost) return 'Kasada yeterli para yok (${fmtShort(cost)}).';
    cash -= cost;
    c.followers = min(followerCap, c.followers * 1.15);
    c.growth = min(0.04, c.growth + 0.005);
    c.campaignReadyDay = day + 5;
    _count('campaign');
    _notify('🚀 ${c.handle} reklam kampanyası: takipçiler +%15!');
    _changed();
    return null;
  }

  // =================================================================
  // Sabah reyting raporu
  // =================================================================

  void _buildReport() {
    lastReport.clear();
    reportDay = day - 1;
    final growth = 1 + day / 400;
    final r = Random(day * 7919);
    for (final slot in SlotId.values) {
      final def = slotDefs[slot]!;
      final slotMul = def.poolMillions / slotDefs[SlotId.prime1]!.poolMillions;
      final rows = <ReportRow>[];
      for (int i = 0; i < rivalDefs.length; i++) {
        final rv = rivalDefs[i];
        if (ownedChannels.any(
          (id) => channelDefs.any((c) => c.id == id && c.name == rv.name),
        )) {
          continue;
        }
        final g = Genre.values[r.nextInt(Genre.values.length)];
        final ideas = showNameIdeas[g]!;
        final rating =
            rv.strength *
            (0.6 + slotMul * 0.5) *
            (0.7 + r.nextDouble() * 0.6) *
            growth;
        rows.add(
          ReportRow(rv.name, ideas[r.nextInt(ideas.length)], rating, false, i),
        );
      }
      final mine = showById(slots[slot]!.showId);
      if (mine != null && mine.ratingHistory.isNotEmpty) {
        rows.add(
          ReportRow(channelName, mine.name, mine.ratingHistory.last, true, -1),
        );
      }
      rows.sort((a, b) => b.rating.compareTo(a.rating));
      lastReport[slot] = rows;
    }
    final prime = lastReport[SlotId.prime1]!;
    final rank = prime.indexWhere((e) => e.mine);
    if (rank == 0) primeWins++;
    if (rank >= 0) {
      _notify(
        '📊 Dünün reytingleri: Prime Time\'da ${rank + 1}. oldun '
        '(${fmtPct(prime[rank].rating, 2)})${rank == 0 ? ' 🏆' : ''}',
      );
    }
  }

  int? rankIn(SlotId slot) {
    final rows = lastReport[slot];
    if (rows == null) return null;
    final i = rows.indexWhere((e) => e.mine);
    return i < 0 ? null : i + 1;
  }

  // =================================================================
  // Kararlar: kriz, ego, sponsor
  // =================================================================

  /// Karar bekliyorsa yenisini açma; çevrimdışıyken karar sorulmaz.
  bool _offerDecision(Decision d) {
    if (_offlineMode || pendingDecision != null) return false;
    _setDecision(d);
    return true;
  }

  double get gameTime => day + dayProgress;

  /// Kasaya giren her para günlük gelire de yazılır (grafik doğru olsun).
  void _gain(double amount) {
    cash += amount;
    todayIncome += amount;
  }

  void _setDecision(Decision d) {
    d.deadline = gameTime + 1.0;
    pendingDecision = d;
  }

  /// Karara kalan süre (0..1)
  double get decisionTimeLeft {
    final d = pendingDecision;
    if (d == null) return 0;
    return (d.deadline - gameTime).clamp(0.0, 1.0);
  }

  Decision _scandalDecision(Show s) => Decision(
    kind: 'scandal',
    title: '📰 Skandal manşetlerde!',
    body: '"${s.name}" kulis dedikodusuyla gazetelerde. Ne yapacaksın?',
    options: ['Özür dile', 'Sessiz kal', 'Avukat tut'],
    hints: [
      '+5 prestij, 1 gün -%5',
      'Şans: +%15 ya da -%10',
      '${fmtShort(productionCost(s.genre, s.tier) * 0.1)}, risk yok',
    ],
    targetId: s.id,
    amount: productionCost(s.genre, s.tier) * 0.1,
  );

  Decision _setCrisisDecision(Show s) => Decision(
    kind: 'setCrisis',
    title: '😤 Sette kriz!',
    body: '"${s.name}" başrolü sete gelmedi, menajeri "şartlarımız var" diyor.',
    options: ['Prim öde', 'Senaryoyu değiştir', 'Bekle'],
    hints: [
      '${fmtShort(productionCost(s.genre, s.tier) * 0.08)}, sorun biter',
      '2 gün -%8',
      'Şans: sorun yok ya da 1 gün -%10',
    ],
    targetId: s.id,
    amount: productionCost(s.genre, s.tier) * 0.08,
    defaultOption: 2,
  );

  Decision _regulatorDecision(Show s, double fine) => Decision(
    kind: 'regulator',
    title: '⚖️ Yayın Kurulu uyarısı',
    body: '"${s.name}" için şikâyet geldi. Ceza ${fmtShort(fine)} olabilir.',
    options: ['Cezayı öde', 'Programı düzenle', 'İtiraz et'],
    hints: [
      fmtShort(fine),
      '${fmtShort(fine * 0.4)} + 1 gün -%5',
      '%70 ceza yok, %30 ceza ×1,3',
    ],
    targetId: s.id,
    amount: fine,
  );

  void _maybeDecision() {
    if (_offlineMode || pendingDecision != null) return;
    // Senaryo kararları: sadece oyun açıkken (başında olana ekstra kazanç)
    if (_rng.nextDouble() < 0.22 && _offerStory()) return;
    // Yıldız egosu: zam talebi ya da rakip transfer teklifi
    final stars = staff.where((p) => p.isStar && p.trait != 5).toList();
    if (stars.isNotEmpty && _rng.nextDouble() < 0.03) {
      final p = stars[_rng.nextInt(stars.length)];
      if (_rng.nextBool() && p.salary < salaryFor(p.skill) * 1.9) {
        _setDecision(
          Decision(
            kind: 'raise',
            title: '⭐ ${p.name} zam istiyor',
            body:
                '${p.role.label} ${p.name} (yetenek ${p.skill}) maaşına %20 zam istiyor.',
            options: ['Zammı ver', 'Pazarlık et (%10)', 'Reddet'],
            hints: [
              'Maaş ${fmtShort(p.salary * 1.2)}/gün',
              '%75 kabul eder',
              '%25 istifa eder',
            ],
            targetId: p.id,
          ),
        );
      } else {
        // sahip olduğun kanallar sana transfer teklifi yapmaz
        final rivals = rivalDefs
            .where(
              (r) => !channelDefs.any(
                (c) => c.name == r.name && ownedChannels.contains(c.id),
              ),
            )
            .toList();
        if (rivals.isEmpty) return;
        final rival = rivals[_rng.nextInt(rivals.length)].name;
        _setDecision(
          Decision(
            kind: 'poach',
            title: '📞 $rival transfer teklifi',
            body:
                '$rival, ${p.name} için teklif yaptı. Bonservis olarak ${fmtShort(p.salary * 25)} ödemeye hazırlar.',
            options: ['Teklifi eşle (+%15 maaş)', 'Sat gitsin'],
            hints: [
              'Maaş ${fmtShort(p.salary * 1.15)}/gün, kadroda kalır',
              '+${fmtShort(p.salary * 25)}, yıldızı kaybedersin',
            ],
            targetId: p.id,
            extra: rival,
          ),
        );
      }
      return;
    }
  }

  void resolveDecision(int option, {bool auto = false}) {
    final d = pendingDecision;
    if (d == null) return;
    if (auto) _notify('⏱️ Süre doldu, otomatik seçildi: ${d.options[option]}');
    pendingDecision = null;
    decisionsMade++;
    if (!auto) _count('decision');
    final s = d.targetId == null ? null : showById(d.targetId);
    final p = d.targetId == null ? null : staffById(d.targetId!);
    String msg;
    switch (d.kind) {
      case 'story':
        msg = _resolveStory(d, option, s);
      case 'scandal':
        if (option == 0) {
          bonusPrestige += 5;
          s
            ?..buff = 0.95
            ..buffDays = 1;
          msg = 'Özür kabul gördü. +5 prestij.';
        } else if (option == 1) {
          if (_rng.nextBool()) {
            s
              ?..buff = 1.15
              ..buffDays = 2;
            msg = 'Merak uyandı! 2 gün reyting +%15.';
          } else {
            s
              ?..buff = 0.9
              ..buffDays = 2;
            bonusPrestige = max(0, bonusPrestige - 5);
            msg = 'Tepki büyüdü: -5 prestij, 2 gün reyting -%10.';
          }
        } else {
          cash -= d.amount;
          msg = 'Avukatlar konuyu kapattı (-${fmtShort(d.amount)}).';
        }
      case 'setCrisis':
        if (option == 0) {
          cash -= d.amount;
          msg = 'Başrol sete döndü (-${fmtShort(d.amount)}).';
        } else if (option == 1) {
          s
            ?..buff = 0.92
            ..buffDays = 2;
          msg = 'Senaryo değişti, 2 gün reyting -%8.';
        } else {
          if (_rng.nextBool()) {
            msg = 'Ertesi gün özür dileyip sete geldi. Bedava çözüm!';
          } else {
            s
              ?..buff = 0.9
              ..buffDays = 1;
            msg = 'Gelmedi! 1 gün reyting -%10.';
          }
        }
      case 'regulator':
        if (option == 0) {
          cash -= d.amount;
          msg = 'Ceza ödendi (-${fmtShort(d.amount)}).';
        } else if (option == 1) {
          cash -= d.amount * 0.4;
          s
            ?..buff = 0.95
            ..buffDays = 1;
          msg = 'Program düzenlendi (-${fmtShort(d.amount * 0.4)}).';
        } else {
          if (_rng.nextDouble() < 0.7) {
            msg = 'İtiraz kabul edildi, ceza yok! 🎉';
          } else {
            cash -= d.amount * 1.3;
            msg = 'İtiraz reddedildi (-${fmtShort(d.amount * 1.3)}).';
          }
        }
      case 'raise':
        if (p == null) return;
        if (option == 0) {
          _replaceSalary(p, p.salary * 1.2);
          msg = '${p.name} mutlu, kadroda kalıyor.';
        } else if (option == 1) {
          if (_rng.nextDouble() < 0.75) {
            _replaceSalary(p, p.salary * 1.1);
            msg = '${p.name} %10 zamma razı oldu.';
          } else {
            _quit(p);
            msg = '${p.name} pazarlığı beğenmedi ve istifa etti!';
          }
        } else {
          if (_rng.nextDouble() < 0.75) {
            msg = '${p.name} söylendi ama kaldı.';
          } else {
            _quit(p);
            msg = '${p.name} istifa etti!';
          }
        }
      case 'poach':
        if (p == null) return;
        if (option == 0) {
          _replaceSalary(p, p.salary * 1.15);
          msg = '${p.name} sende kaldı, maaşı arttı.';
        } else {
          final fee = p.salary * 25;
          _gain(fee);
          _quit(p);
          msg = '${p.name}, ${d.extra}\'a transfer oldu: +${fmtShort(fee)}';
        }
      case 'sponsor':
        if (s == null) return;
        if (option == 0) {
          _setSponsor(s, d.extra, d.amount);
          msg = '${d.extra} anlaşması imzalandı!';
        } else if (option == 1) {
          if (_rng.nextBool()) {
            _setSponsor(s, d.extra, d.amount * 1.4);
            msg = '${d.extra} pes etti: %40 daha fazla ödeyecek!';
          } else {
            msg = '${d.extra} teklifini geri çekti.';
          }
        } else {
          msg = 'Teklif reddedildi.';
        }
      default:
        msg = '';
    }
    _log(d.title, msg, !msg.contains('-'));
    if (!auto) _notify(msg);
    _changed();
  }

  void _setSponsor(Show s, String brand, double perDay) {
    s
      ..sponsor = brand
      ..sponsorPerDay = perDay
      ..sponsorDays = 10
      ..buff = s.buffDays > 0 ? s.buff : 0.97
      ..buffDays = s.buffDays > 0 ? s.buffDays : 10;
    sponsorDeals++;
  }

  /// Staff değişmez (final alanlar), maaş için kopyası değiştirilir.
  void _replaceSalary(Staff p, double salary) {
    // zam tavanı: piyasa maaşının en fazla 2 katı
    salary = min(salary, salaryFor(p.skill) * 2);
    p.salary = (salary / 100).round() * 100.0;
  }

  void _forgetPerson(Staff p) {
    transferOffers.removeWhere((o) => o.staffId == p.id);
    deals.removeWhere((d) => d.targetId == p.id);
  }

  /// Kişi ayrılır; bir programdaysa program kalitesi düşer.
  void _quit(Staff p) {
    staff.remove(p);
    _forgetPerson(p);
    if (p.showId != null) {
      final s = showById(p.showId);
      if (s != null) {
        s.staffIds.remove(p.id);
        s.quality *= 0.85;
      }
    }
  }

  // =================================================================
  // Altın Anten Ödülleri (her 30 günde bir)
  // =================================================================

  void _awardCeremony() {
    final results = <AwardResult>[];
    final bar = 3.0 + day / 60;
    for (final g in Genre.values) {
      // sadece son 30 günde yayında olan programlar aday olur
      final cands = shows
          .where(
            (s) =>
                s.genre == g &&
                s.ratingHistory.isNotEmpty &&
                s.lastAiredDay > day - 30,
          )
          .toList();
      if (cands.isEmpty) continue;
      double avg(Show s) =>
          s.ratingHistory.reduce((a, b) => a + b) / s.ratingHistory.length;
      cands.sort((a, b) => avg(b).compareTo(avg(a)));
      final best = cands.first;
      final need = bar * genreDefs[g]!.ratingMult;
      results.add(
        AwardResult(
          'Yılın ${genreDefs[g]!.label} Programı',
          best.name,
          avg(best) >= need,
        ),
      );
    }
    final recentFilms =
        films.where((f) => f.score > 0 && f.finishedDay > day - 30).toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    if (recentFilms.isNotEmpty) {
      results.add(
        AwardResult(
          'En İyi Film',
          recentFilms.first.name,
          recentFilms.first.score >= 7,
        ),
      );
    }
    if (creators.isNotEmpty) {
      final top = creators.reduce((a, b) => a.followers > b.followers ? a : b);
      results.add(
        AwardResult(
          'Yılın YouTuber\'ı',
          top.handle,
          top.followers >= 500000 * (1 + day / 200),
        ),
      );
    }
    if (results.isEmpty) return;
    for (final r in results.where((r) => r.won)) {
      trophies.add(Trophy(day, r.category, r.nominee));
      bonusPrestige += 15;
      diamonds += 3;
    }
    pendingAwards = results;
    _log(
      '🏆 Altın Anten Ödülleri',
      '${results.where((r) => r.won).length}/${results.length} ödül kazandın!',
      true,
    );
  }

  void dismissAwards() {
    pendingAwards = null;
    _changed();
  }

  // =================================================================
  // Başarımlar
  // =================================================================

  void _checkAchievements() {
    for (final a in achDefs) {
      if (!achievements.contains(a.id) && a.check(this)) {
        achievements.add(a.id);
        diamonds += a.reward;
        _notify('🎖️ Başarım: ${a.title}! +${a.reward} 💎');
      }
    }
  }

  // =================================================================
  // Medya Borsası
  // =================================================================

  void _initStocks() {
    stockPrices.clear();
    stockHist.clear();
    for (final d in stockDefs) {
      stockPrices[d.ticker] = d.basePrice;
      stockHist[d.ticker] = [d.basePrice];
    }
    lastStockHour = ((day + dayProgress) * 24).floor();
  }

  double _gauss() {
    final u1 = max(1e-9, _rng.nextDouble()), u2 = _rng.nextDouble();
    return sqrt(-2 * log(u1)) * cos(2 * pi * u2);
  }

  /// Şirketin "adil değeri" zamanla büyür (ekonomi büyüyor).
  double fairPrice(StockDef d) => d.basePrice * (1 + day / 3000);

  void _stockTick(int hour) {
    for (final d in stockDefs) {
      final p = stockPrices[d.ticker] ?? d.basePrice;
      final gap = log(fairPrice(d) / p);
      final ret = 0.01 * gap + d.volatility / sqrt(24) * _gauss();
      final np = max(0.05, p * exp(ret));
      stockPrices[d.ticker] = np;
      if (hour % 3 == 0) {
        final h = stockHist[d.ticker]!..add(np);
        if (h.length > 80) h.removeAt(0);
      }
    }
  }

  static const _goodNews = [
    'yeni dizisiyle rekor kırdı',
    'yurt dışına büyük satış yaptı',
    'rekor kâr açıkladı',
    'dev bir sponsorlukla anlaştı',
  ];
  static const _badNews = [
    'zarar açıkladı',
    'yıldız oyuncusunu kaybetti',
    'yayın cezası aldı',
    'reytinglerde çakıldı',
  ];

  void _stockNews() {
    if (_rng.nextDouble() > 0.25) return;
    final d = stockDefs[_rng.nextInt(stockDefs.length)];
    final up = _rng.nextBool();
    final pct = 0.06 + _rng.nextDouble() * 0.12;
    stockPrices[d.ticker] = stockPrices[d.ticker]! * (up ? 1 + pct : 1 - pct);
    final msg = '${d.name} ${(up ? _goodNews : _badNews)[_rng.nextInt(4)]}';
    lastStockNews =
        '📰 ${d.ticker}: $msg (${up ? '+' : '-'}%${(pct * 100).round()})';
    if (holdings.containsKey(d.ticker)) _notify(lastStockNews!);
  }

  String? lastStockNews;

  double priceOf(String t) => stockPrices[t] ?? 0;
  double get portfolioValue =>
      holdings.entries.fold(0.0, (a, e) => a + e.value * priceOf(e.key));

  StockDef stockDef(String t) => stockDefs.firstWhere((d) => d.ticker == t);

  /// [qty] lot almanın toplam maliyeti (fiyat etkisi + %0,3 komisyon)
  double buyQuote(String t, double qty) {
    final impact = qty / stockDef(t).shares * 0.5;
    return priceOf(t) * (1 + impact / 2) * qty * 1.003;
  }

  /// [qty] lot satmanın getirisi (fiyat etkisi + %0,3 komisyon)
  double sellQuote(String t, double qty) {
    final impact = qty / stockDef(t).shares * 0.5;
    return priceOf(t) * (1 - impact / 2) * qty * 0.997;
  }

  /// En fazla şirketin %25'i alınabilir.
  double maxBuyable(String t) {
    final d = stockDef(t);
    final room = d.shares * 0.25 - (holdings[t] ?? 0);
    final afford = cash / (priceOf(t) * 1.003 * 1.07);
    return max(0, min(room, afford)).floorToDouble();
  }

  String? buyStock(String t, double qty) {
    qty = qty.floorToDouble();
    if (qty < 1) return 'En az 1 hisse almalısın.';
    final d = stockDef(t);
    if ((holdings[t] ?? 0) + qty > d.shares * 0.25) {
      return 'Bir şirketin en fazla %25\'ine sahip olabilirsin.';
    }
    // Büyük alımlar fiyatı yukarı iter; işlem bu hareketin ORTALAMA
    // fiyatından gerçekleşir (aksi hâlde al-sat döngüsü para basardı).
    final impact = qty / d.shares * 0.5;
    final cost = buyQuote(t, qty);
    if (cash < cost) return 'Kasada yeterli para yok.';
    cash -= cost;
    holdings[t] = (holdings[t] ?? 0) + qty;
    costBasis[t] = (costBasis[t] ?? 0) + cost;
    _count('trade');
    stockPrices[t] = priceOf(t) * (1 + impact);
    _changed();
    return null;
  }

  String? sellStock(String t, double qty) {
    qty = min(qty.floorToDouble(), holdings[t] ?? 0);
    if (qty < 1) return 'Satacak hissen yok.';
    final d = stockDef(t);
    final have = holdings[t]!;
    final proceeds = sellQuote(t, qty);
    final basis = (costBasis[t] ?? 0) * qty / have;
    tradingProfit += proceeds - basis;
    _count('trade');
    _gain(proceeds);
    holdings[t] = have - qty;
    costBasis[t] = (costBasis[t] ?? 0) - basis;
    if (holdings[t]! < 1) {
      holdings.remove(t);
      costBasis.remove(t);
    }
    // büyük satışlar fiyatı aşağı iter
    stockPrices[t] = max(0.05, priceOf(t) * (1 - qty / d.shares * 0.5));
    _changed();
    return null;
  }

  // =================================================================
  // Zenginler listesi
  // =================================================================

  /// Kurgusal patronların servetleri (online'da gerçek oyuncular gelecek)
  /// Takvim simülasyonuna göre ayarlı: günde ~1 saat oynayan oyuncu
  /// ~1. ayda ilk 100'e, ~1 yılda ilk 10-15'e ulaşır; 1 numara ekstra emek ister.
  double tycoonWorth(int i) => 3.2e12 * exp(-i * 0.0266) * (1 + day / 1e6);

  String tycoonName(int i) =>
      '${firstNames[(i * 17 + 3) % firstNames.length]} '
      '${lastNames[(i * 11 + 5) % lastNames.length]} '
      '${tycoonFirms[(i * 3) % tycoonFirms.length]}';

  int get richRank {
    final me = netWorth;
    int rank = 1;
    for (int i = 0; i < 150; i++) {
      if (tycoonWorth(i) > me) rank++;
    }
    return rank;
  }

  // =================================================================
  // Devlet ihaleleri
  // =================================================================

  /// Açık ihale sayısını 3'te tutar; süresi dolanları sonuçlandırır.
  void _tendersDaily() {
    for (final t
        in tenders.where((t) => t.status == TenderStatus.open).toList()) {
      if (day >= t.closesDay) _resolveTender(t);
    }
    // eski kayıtları temizle (son 12 kapanmış ihale kalsın)
    final closed = tenders
        .where(
          (t) =>
              t.status == TenderStatus.delivered ||
              t.status == TenderStatus.lost ||
              t.status == TenderStatus.expired,
        )
        .toList();
    if (closed.length > 12) {
      for (final t in closed.take(closed.length - 12)) {
        tenders.remove(t);
      }
    }
    while (tenders.where((t) => t.status == TenderStatus.open).length < 3) {
      if (!_spawnTender()) break;
    }
  }

  bool _spawnTender() {
    final lv = studioLevel + 1;
    final pool = tenderDefs
        .where(
          (d) =>
              d.minLevel <= lv + 1 &&
              !tenders.any(
                (t) => t.defId == d.id && t.status == TenderStatus.open,
              ),
        )
        .toList();
    if (pool.isEmpty) return false;
    final d = pool[_rng.nextInt(pool.length)];
    final scale = 1 + 0.4 * max(0, lv - d.minLevel);
    tenders.insert(
      0,
      Tender(
        id: _newId('t'),
        defId: d.id,
        budget:
            (d.budget * scale * (0.9 + _rng.nextDouble() * 0.25) / 1000)
                .round() *
            1000.0,
        closesDay: day + 3,
      ),
    );
    return true;
  }

  /// Teklif verilebilir mi? (null = evet, aksi hâlde sebep)
  String? tenderEligible(Tender t) {
    final d = t.def;
    if (studioLevel + 1 < d.minLevel)
      return 'Stüdyo seviyesi ${d.minLevel} gerekli.';
    final missing = d.equip.where((e) => !ownedEquip.contains(e)).toList();
    if (missing.isNotEmpty) {
      return 'Eksik ekipman: ${missing.map((e) => equipById(e)!.name).join(', ')}';
    }
    return null;
  }

  /// Fiyat+kalite puanı için kalite çarpanı: ekip yeteneği ve fazladan ekipman.
  /// Bu teklifle ihaleyi kazanma ihtimali (rakiplerin olası tekliflerine göre).
  /// Rakip davranışı [_resolveTender] ile aynıdır; sabit tohumla tahmin edilir.
  double tenderWinChance(Tender t, double bid, double q) {
    final r = Random(t.id.hashCode);
    var wins = 0;
    const n = 600;
    final my = bid / q;
    for (int i = 0; i < n; i++) {
      final k = 2 + r.nextInt(3);
      var best = double.infinity;
      for (int j = 0; j < k; j++) {
        final b = t.budget * (0.78 + r.nextDouble() * 0.22);
        final rq = 0.95 + r.nextDouble() * 0.2;
        best = min(best, b / rq);
      }
      if (my < best) wins++;
    }
    return wins / n;
  }

  double tenderQuality(Tender t, List<Staff> crew) {
    final avg = crew.isEmpty
        ? 0
        : crew.map((c) => c.skill).reduce((a, b) => a + b) / crew.length;
    final extra = min(0.1, (ownedEquip.length - t.def.equip.length) * 0.01);
    return 0.85 + avg / 100 * 0.35 + max(0.0, extra);
  }

  String? bidTender(Tender t, double amount, List<Staff> crew) {
    if (t.status != TenderStatus.open) return 'İhale kapandı.';
    if (t.myBid != null) return 'Bu ihaleye zaten teklif verdin.';
    final why = tenderEligible(t);
    if (why != null) return why;
    for (final e in t.def.crew.entries) {
      final n = crew.where((c) => c.role == e.key && c.showId == null).length;
      if (n < e.value) return '${e.value} boşta ${e.key.label} gerekli.';
    }
    if (amount < t.budget * 0.5 || amount > t.budget * 1.2) {
      return 'Teklif, tahmini bedelin %50-%120 aralığında olmalı.';
    }
    final deposit = amount * 0.05;
    if (cash < deposit + t.productionCost) {
      return 'Teminat ve yapım maliyeti için ${fmtShort(deposit + t.productionCost)} gerekli.';
    }
    cash -= deposit;
    t.myBid = amount;
    t.crewIds = crew.map((c) => c.id).toList();
    t.qualityFactor = tenderQuality(t, crew);
    for (final c in crew) {
      c.showId = t.id;
    }
    _count('tender');
    _notify(
      '📨 "${t.def.title}" için ${fmtShort(amount)} teklif verildi. Zarflar ${t.closesDay}. gün açılacak.',
    );
    _changed();
    return null;
  }

  void _freeCrew(Tender t) {
    for (final st in staff) {
      if (st.showId == t.id) st.showId = null;
    }
  }

  /// Kapalı zarf: en düşük (fiyat / kalite) puanı kazanır.
  void _resolveTender(Tender t) {
    final n = 2 + _rng.nextInt(3);
    String? bestName;
    var bestScore = double.infinity, bestBid = 0.0;
    final names = tenderRivals.toList()..shuffle(_rng);
    for (int i = 0; i < n; i++) {
      final bid = t.budget * (0.78 + _rng.nextDouble() * 0.22);
      final q = 0.95 + _rng.nextDouble() * 0.2;
      if (bid / q < bestScore) {
        bestScore = bid / q;
        bestBid = bid;
        bestName = names[i];
      }
    }
    if (t.myBid == null) {
      t.status = TenderStatus.expired;
      t.winner = bestName;
      t.winningBid = bestBid;
      return;
    }
    _gain(t.deposit); // teminat iadesi
    final myScore = t.myBid! / t.qualityFactor;
    if (myScore < bestScore) {
      t.status = TenderStatus.producing;
      t.prodLeft = t.def.days.toDouble();
      t.winner = channelName;
      t.winningBid = t.myBid;
      cash -= t.productionCost;
      _log(
        '🏛️ İhale kazanıldı',
        '"${t.def.title}" ${fmtShort(t.myBid!)} ile senin! Çekimler başladı.',
        true,
      );
      _notify('🏆 İhaleyi kazandın: "${t.def.title}"! Çekimler başladı.');
    } else {
      t.status = TenderStatus.lost;
      t.winner = bestName;
      t.winningBid = bestBid;
      _freeCrew(t);
      _notify(
        '📭 "${t.def.title}" ihalesini $bestName ${fmtShort(bestBid)} ile kazandı.',
      );
    }
  }

  void _deliverTender(Tender t) {
    t.prodLeft = 0;
    t.status = TenderStatus.delivered;
    // kaliteli iş için %0-15 başarı primi
    final bonus = t.myBid! * max(0.0, min(0.15, (t.qualityFactor - 1) * 0.6));
    t.paid = t.myBid! + bonus;
    _gain(t.paid);
    bonusPrestige += t.def.prestige;
    tendersWon++;
    _freeCrew(t);
    _log(
      '🏛️ Proje teslim edildi',
      '"${t.def.title}" teslim edildi: +${fmtShort(t.paid)}, +${t.def.prestige} prestij',
      true,
    );
    _notify(
      '✅ "${t.def.title}" teslim edildi! +${fmtShort(t.paid)}, +${t.def.prestige} prestij',
    );
  }

  // =================================================================
  // Kadro eğitimi
  // =================================================================

  double trainCost(Staff p) => p.salary * 8;
  bool canTrain(Staff p) => day - p.trainedDay >= 3 && p.skill < 99;

  /// Eğitim kampı: yetenek +3..6 (3 günde bir), maaş yeteneğe göre artar.
  String? trainStaff(Staff p) {
    if (p.skill >= 99) return '${p.name} zaten zirvede!';
    if (!canTrain(p))
      return '${p.name} ${3 - (day - p.trainedDay)} gün sonra tekrar eğitilebilir.';
    final cost = trainCost(p);
    if (cash < cost) return 'Eğitim için ${fmtShort(cost)} gerekli.';
    cash -= cost;
    var gain = 3 + _rng.nextInt(4);
    if (p.trait == 3) gain = (gain * 1.5).round();
    final ratio = p.salary / salaryFor(p.skill);
    p.skill = min(99, p.skill + gain);
    p.potential = max(p.potential, p.skill);
    p.salary = (salaryFor(p.skill) * ratio / 100).round() * 100.0;
    p.trainedDay = day;
    _count('train');
    _notify('🎓 ${p.name} eğitimden döndü: yetenek ${p.skill} (+$gain)');
    _changed();
    return null;
  }

  // =================================================================
  // Günlük görevler ve giriş ödülü (gerçek takvim gününe göre)
  // =================================================================

  String missionDate = '';
  final List<Mission> missions = [];
  String loginDate = '';
  int loginStreak = 0;

  /// Açılışta gösterilecek giriş ödülü (seri günü, elmas, para)
  (int, int, double)? pendingLogin;

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _dailyCheck() {
    final now = DateTime.now();
    final today = _dateKey(now);
    if (loginDate != today) {
      final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
      loginStreak = loginDate == yesterday ? loginStreak + 1 : 1;
      loginDate = today;
      final gems = min(loginStreak, 7);
      final money = max(50000.0, yesterdayIncome * 0.5) * min(loginStreak, 7);
      diamonds += gems;
      _gain(money);
      pendingLogin = (loginStreak, gems, money);
    }
    if (missionDate != today) {
      missionDate = today;
      _makeMissions();
    }
  }

  void dismissLogin() {
    pendingLogin = null;
    _changed();
  }

  static const _missionPool = [
    ('hire', 'Kadroya 2 kişi kat', 2),
    ('show', '2 yeni program ya da sezon başlat', 2),
    ('air', '2 programı yayına koy', 2),
    ('film', '1 film çek', 1),
    ('trade', 'Borsada 3 işlem yap', 3),
    ('train', '2 kişiyi eğitime gönder', 2),
    ('ads', 'Reklam süresini 3 kez ayarla', 3),
    ('license', '1 filmi platforma sat', 1),
    ('campaign', '1 YouTuber kampanyası yap', 1),
    ('tender', '1 devlet ihalesine teklif ver', 1),
    ('brand', '1 marka anlaşması imzala', 1),
    ('youth', 'Akademine 1 genç yetenek al', 1),
  ];

  /// Görev oyuncunun şu anki durumunda yapılabilir mi?
  bool _missionPossible(String kind) => switch (kind) {
    'license' => films.any(
      (f) => f.rightsOwned && f.status != FilmStatus.producing,
    ),
    'campaign' => creators.isNotEmpty,
    'train' => staff.length >= 2,
    'tender' => tenders.any(
      (t) => t.status == TenderStatus.open && tenderEligible(t) == null,
    ),
    'brand' => brandOffers.isNotEmpty,
    'youth' => agencyOpen,
    _ => true,
  };

  void _makeMissions() {
    final pool = _missionPool.where((m) => _missionPossible(m.$1)).toList()
      ..shuffle(_rng);
    missions
      ..clear()
      ..addAll(
        pool.take(3).map((m) => Mission(m.$1, m.$2, m.$3, 1 + _rng.nextInt(3))),
      );
  }

  /// Görev sayacı: ilgili işlem yapıldıkça artar.
  void _count(String kind) {
    for (final m in missions) {
      if (m.kind == kind && m.progress < m.target) m.progress++;
    }
  }

  double missionCash(Mission m) =>
      max(100000.0, yesterdayIncome * 0.6) * m.target;

  String? claimMission(Mission m) {
    if (m.claimed) return 'Ödül zaten alındı.';
    if (m.progress < m.target) return 'Görev henüz tamamlanmadı.';
    m.claimed = true;
    diamonds += m.gems;
    _gain(missionCash(m));
    _notify('✅ Görev ödülü: +${m.gems} 💎, +${fmtShort(missionCash(m))}');
    _changed();
    return null;
  }

  // =================================================================
  // Öğretici görevler
  // =================================================================

  /// (başlık, açıklama, tamamlandı mı, ödül elmas)
  List<(String, String, bool, int)> get goals => [
    ('Kadro kur', 'İş ilanlarından en az 2 kişi işe al.', staff.length >= 2, 3),
    (
      'İlk programını üret',
      'Yapım ekranından bir format seç ve çekime başla.',
      shows.isNotEmpty,
      3,
    ),
    (
      'Yayına çık',
      'Hazır programı bir yayın kuşağına koy.',
      shows.any((s) => s.status == ShowStatus.onAir || s.totalRevenue > 0),
      3,
    ),
    (
      'Reklam ayarı',
      'Yayın ekranında reklam süresini kaydırıp en iyi noktayı bul.',
      adTouched,
      2,
    ),
    (
      'YouTuber transfer et',
      'Dijital ekranından bir içerik üreticisi al.',
      creators.isNotEmpty,
      3,
    ),
    ('İlk filmini çek', 'Sinema ekranından bir film çek.', films.isNotEmpty, 3),
    (
      'Stüdyoyu büyüt',
      'Stüdyo ekranından bir üst seviyeye çık.',
      studioLevel >= 1,
      5,
    ),
  ];

  int get currentGoal {
    final g = goals;
    for (int i = 0; i < g.length; i++) {
      if (!claimedGoals.contains(i)) return i;
    }
    return -1;
  }

  void _checkGoals() {
    final g = goals;
    for (int i = 0; i < g.length; i++) {
      if (g[i].$3 && !claimedGoals.contains(i)) {
        claimedGoals.add(i);
        diamonds += g[i].$4;
        _notify('🎯 Görev tamam: ${g[i].$1}! +${g[i].$4} 💎');
      }
    }
  }

  void markIntroSeen() {
    introSeen = true;
    _changed();
  }

  // =================================================================
  // Holding
  // =================================================================

  String? upgradeBiz(BizDef b) {
    final lv = bizLevel(b.id);
    if (lv >= bizMaxLevel) return 'Zaten en üst seviye.';
    if (studioLevel + 1 < b.reqLevel) {
      return 'Stüdyo seviyesi ${b.reqLevel} gerekli.';
    }
    final cost = bizUpgradeCost(b, lv);
    if (cash < cost) return 'Kasada yeterli para yok (${fmtShort(cost)}).';
    cash -= cost;
    bizLevels[b.id] = lv + 1;
    _notify(
      lv == 0 ? '🏢 ${b.name} kuruldu!' : '🏢 ${b.name} seviye ${lv + 1} oldu!',
    );
    _changed();
    return null;
  }

  // =================================================================
  // Ayarlar
  // =================================================================

  void rename(String name) {
    if (name.trim().isEmpty) return;
    channelName = name.trim();
    _changed();
  }

  void setTimeScale(double s) {
    timeScale = s;
    if (s > 1) tainted = true;
    _changed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
  }
}
