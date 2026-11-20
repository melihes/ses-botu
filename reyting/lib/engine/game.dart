import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/format.dart';
import '../data/content.dart';
import '../models/models.dart';
import 'economy.dart';

/// Oyunun tüm durumunu tutan ve zamanı ilerleten motor.
/// Ekranlar bunu dinler; her değişiklikte notifyListeners() çağrılır.
class Game extends ChangeNotifier {
  static const _saveKey = 'reyting_save_v1';
  static const _saveVersion = 1;

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
  double timeScale = 1; // test modu için hızlandırma

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
  final Map<String, NegState> negotiations = {};
  final List<double> cashHistory = [];
  final List<GameEvent> eventLog = [];
  int bonusPrestige = 0;
  double todayIncome = 0;
  double yesterdayIncome = 0;

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
            jsonDecode(raw)['savedAt'] as int);
        _catchUp(DateTime.now().difference(lastSeen));
      } catch (e) {
        debugPrint('Kayıt okunamadı, yeni oyun: $e');
        _newGame();
      }
    } else {
      _newGame();
    }
    _startTimer();
    notifyListeners();
  }

  void _newGame() {
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
    negotiations.clear();
    cashHistory
      ..clear()
      ..add(cash);
    eventLog.clear();
    bonusPrestige = 0;
    todayIncome = 0;
    yesterdayIncome = 0;
    _refreshMarket();
    _log('Kanal kuruldu', '$channelName yayın hayatına başladı. Bol reytingler!',
        true);
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
          jsonDecode(raw)['savedAt'] as int);
      _catchUp(DateTime.now().difference(savedAt));
    }
    _startTimer();
    notifyListeners();
  }

  double get offlineCapMinutes =>
      vip ? offlineCapMinutesVip : offlineCapMinutesFree;

  void _catchUp(Duration away) {
    // Telefon saati geri alındıysa (negatif süre) hiçbir şey işlenmez.
    final minutes = away.inSeconds / 60.0;
    if (minutes < 1) return; // 1 dakikadan kısa ayrılıklar sessizce geçer
    final counted = min(minutes, offlineCapMinutes);
    final sum = PeriodSummary()
      ..minutesAway = minutes
      ..minutesCounted = counted
      ..cashBefore = cash;
    _offlineMode = true;
    _acc = sum;
    _advance(counted * 60 / secondsPerDay);
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
    notifyListeners();
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), save);
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_saveKey, jsonEncode(_toJson()));
  }

  Map<String, dynamic> _toJson() => {
        'v': _saveVersion,
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
        'negotiations': {
          for (final e in negotiations.entries) e.key: e.value.toJson()
        },
        'cashHistory': cashHistory,
        'eventLog': eventLog.map((e) => e.toJson()).toList(),
        'bonusPrestige': bonusPrestige,
        'todayIncome': todayIncome,
        'yesterdayIncome': yesterdayIncome,
      };

  void _load(Map<String, dynamic> j) {
    _idCounter = j['idCounter'] ?? 0;
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
    final sl = j['slots'] as Map<String, dynamic>;
    for (final id in SlotId.values) {
      if (sl[id.name] != null) slots[id] = SlotState.fromJson(sl[id.name]);
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
    negotiations
      ..clear()
      ..addAll((j['negotiations'] as Map<String, dynamic>)
          .map((k, v) => MapEntry(k, NegState.fromJson(v))));
    cashHistory
      ..clear()
      ..addAll((j['cashHistory'] as List).map((e) => (e as num).toDouble()));
    eventLog
      ..clear()
      ..addAll((j['eventLog'] as List? ?? []).map((e) => GameEvent.fromJson(e)));
    bonusPrestige = j['bonusPrestige'] ?? 0;
    todayIncome = (j['todayIncome'] as num? ?? 0).toDouble();
    yesterdayIncome = (j['yesterdayIncome'] as num? ?? 0).toDouble();
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
        final inc = boxOfficeForDay(f, f.theaterDay, reach, boxOfficeBonus) * step;
        cash += inc;
        todayIncome += inc;
        f.boxOffice += inc;
        _acc?.boxOffice += inc;
      }
    }
    final pf = platformIncomePerDay * step;
    cash += pf;
    todayIncome += pf;
    _acc?.platformIncome += pf;
    final bz = bizIncomePerDay * step;
    cash += bz;
    todayIncome += bz;
    _acc?.bizIncome += bz;
  }

  void _finishFilm(Film f) {
    f.prodLeft = 0;
    f.status = FilmStatus.ready;
    f.score = filmScore(f.quality, 0.8 + _rng.nextDouble() * 0.4);
    for (final st in staff) {
      if (st.showId == f.id) st.showId = null;
    }
    _acc?.filmsDone++;
    _notify('🎞️ "${f.name}" tamamlandı! İzleyici puanı ${fmtDec(f.score, 1)}. '
        'Vizyona sok ya da platformlara sat.');
  }

  void _endOfDay() {
    day++;

    // Giderler
    final sal = dailySalaries;
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
      if (s.episodesAired >= s.seasonDays) _endSeason(s);
    }

    for (final f in films) {
      if (f.status == FilmStatus.inTheaters) {
        f.theaterDay++;
        if (f.theaterDay >= theaterRunDays) {
          f.status = FilmStatus.library;
          _notify('🍿 "${f.name}" vizyondan kalktı. Gişe: ${fmtShort(f.boxOffice)}. '
              'Artık platformlara lisanslayabilirsin.');
        }
      }
      for (final l in f.licenses) {
        l.daysLeft--;
      }
      f.licenses.removeWhere((l) => l.daysLeft <= 0);
    }

    _rollEvent();

    if (day % 3 == 0) _refreshMarket();

    cashHistory.add(cash);
    if (cashHistory.length > 60) cashHistory.removeAt(0);
    yesterdayIncome = todayIncome;
    todayIncome = 0;
    _acc?.days++;
  }

  void _endSeason(Show s) {
    slots[s.slot]?.showId = null;
    s.slot = null;
    s.status = ShowStatus.ended;
    s.buff = 1;
    s.buffDays = 0;
    for (final st in staff) {
      if (st.showId == s.id) st.showId = null;
    }
    _acc?.endedSeasons++;
    _notify('🏁 "${s.name}" ${s.season}. sezon finali yaptı! '
        'Yeni sezon çekebilirsin.');
  }

  // =================================================================
  // Rastgele olaylar
  // =================================================================

  void _rollEvent() {
    if (_rng.nextDouble() > 0.14) return;
    final onAir = shows.where((s) => s.status == ShowStatus.onAir).toList();
    final pick = _rng.nextInt(10);
    Show? s = onAir.isEmpty ? null : onAir[_rng.nextInt(onAir.length)];

    switch (pick) {
      case 0:
        if (s == null) return;
        s.buff = 1.35;
        s.buffDays = 3;
        _event('📈 Viral oldu!',
            '"${s.name}" sosyal medyada gündem oldu. 3 gün reyting +%35.', true);
      case 1:
        if (s == null || !s.def.needs.containsKey(Role.oyuncu)) return;
        s.buff = 0.8;
        s.buffDays = 2;
        _event('😤 Sette kriz',
            '"${s.name}" başrolü sete gelmedi. 2 gün reyting -%20.', false);
      case 2:
        final cost = max(50000.0, cash.abs() * 0.02).clamp(50000.0, 5e6);
        cash -= cost;
        _acc?.eventCash -= cost;
        _event('⚡ Verici arızası',
            'Fırtına vericiyi vurdu. Onarım: ${fmtShort(cost)}', false);
      case 3:
        if (s == null ||
            !(s.genre == Genre.magazin || s.genre == Genre.talkShow)) {
          return;
        }
        final fine = productionCost(s.genre, s.tier) * 0.8;
        cash -= fine;
        _acc?.eventCash -= fine;
        _event('⚖️ Yayın Kurulu cezası',
            '"${s.name}" için ${fmtShort(fine)} idari para cezası.', false);
      case 4:
        if (s == null) return;
        s.buff = 1.15;
        s.buffDays = 4;
        bonusPrestige += 15;
        _event('🏆 Ödül töreni',
            '"${s.name}" yılın programı seçildi! +15 prestij, 4 gün reyting +%15.',
            true);
      case 5:
        final amount = (yesterdayIncome * 1.5).clamp(80000.0, 50e6);
        cash += amount;
        _acc?.eventCash += amount;
        _event('🤝 Sponsor anlaşması',
            'Bir içecek markası sponsor oldu: +${fmtShort(amount)}', true);
      case 6:
        if (s == null) return;
        s.buff = 1.25;
        s.buffDays = 2;
        bonusPrestige = max(0, bonusPrestige - 5);
        _event('📰 Skandal manşette',
            '"${s.name}" kulis dedikodusuyla gazetelerde. Reyting +%25 ama -5 prestij.',
            true);
      case 7:
        if (s == null) return;
        s.buff = 0.85;
        s.buffDays = 3;
        _event('📺 Rakip hamlesi',
            'Rakip kanal aynı saate dev yapım koydu. "${s.name}" 3 gün -%15.',
            false);
      case 9:
        final pool = films
            .where((f) =>
                f.status == FilmStatus.inTheaters ||
                f.status == FilmStatus.library)
            .toList();
        if (pool.isEmpty) return;
        final f = pool[_rng.nextInt(pool.length)];
        f.score = min(9.9, f.score + 0.5);
        bonusPrestige += 10;
        _event('🎖️ Festival ödülü',
            '"${f.name}" uluslararası festivalde ödül aldı! Puan +0,5, +10 prestij.',
            true);
      case 8:
        diamonds += 2;
        _event('💎 Sadık izleyici', 'İzleyici kulübü sana 2 elmas hediye etti.',
            true);
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
    return min(r, 1.2);
  }

  int get prestige {
    var p = bonusPrestige +
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
    return p;
  }

  double get adBonus => prestigeAdBonus(prestige) + bizEffect(BizEffect.adRate);

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

  double ratingMultFor(Genre g) => 1 + bizEffect(BizEffect.showRating, genre: g);
  double get boxOfficeBonus => bizEffect(BizEffect.boxOffice);
  double get licenseBonus => bizEffect(BizEffect.licenseFee);
  double get musicQualityBonus => bizEffect(BizEffect.quality);

  double get bizIncomePerDay =>
      bizDefs.fold(0.0, (a, b) => a + bizIncome(b, bizLevel(b.id)));

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
    return v;
  }

  double get boxOfficePerDay => films
      .where((f) => f.status == FilmStatus.inTheaters)
      .fold(0.0,
          (a, f) => a + boxOfficeForDay(f, f.theaterDay, reach, boxOfficeBonus));

  double get dailySalaries => staff.fold(0.0, (a, s) => a + s.salary);
  double get dailyRent => studio.rentPerDay;
  double get dailyUpkeep => ownedEquip.fold(
      0.0, (a, id) => a + (equipById(id)?.upkeepPerDay ?? 0));
  double get debt => loans.fold(0.0, (a, l) => a + l.remaining);

  double get channelIncomePerDay => channelDefs
      .where((c) => ownedChannels.contains(c.id))
      .fold(0.0, (a, c) => a + c.dailyIncome);

  double get adIncomePerDay => shows
      .where((s) => s.status == ShowStatus.onAir)
      .fold(0.0, (a, s) => a + revenuePerDay(s));

  double get netPerDay =>
      adIncomePerDay +
      channelIncomePerDay +
      platformIncomePerDay +
      bizIncomePerDay +
      boxOfficePerDay -
      dailySalaries -
      dailyRent -
      dailyUpkeep;

  double currentRating(Show s) {
    if (s.slot == null) return 0;
    return showRating(s, s.slot!, slots[s.slot]!.adMinutes) *
        ratingMultFor(s.genre);
  }

  /// Programı belirli bir kuşağa koysak reytingi ne olurdu (önizleme).
  double previewRating(Show s, SlotId slot) =>
      showRating(s, slot, slots[slot]!.adMinutes) * ratingMultFor(s.genre);

  double viewers(Show s) =>
      s.slot == null ? 0 : viewersFor(currentRating(s), s.slot!, reach);

  double revenuePerDay(Show s) {
    if (s.slot == null) return 0;
    final m = slots[s.slot]!.adMinutes;
    return adRevenuePerDay(viewers(s), m, s.slot!, adBonus);
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
    return null;
  }

  List<Staff> freeStaff(Role r) =>
      staff.where((s) => s.role == r && s.showId == null).toList();

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
    final base = 30 + studioLevel * 9 + bizEffect(BizEffect.marketSkill).round();
    // yaklaşık normal dağılım
    final g = (_rng.nextDouble() + _rng.nextDouble() + _rng.nextDouble() - 1.5) *
        2;
    var skill = (base + g * 16).round().clamp(8, 99);
    if (_rng.nextDouble() < 0.06) skill = 85 + _rng.nextInt(14); // yıldız!
    final name =
        '${firstNames[_rng.nextInt(firstNames.length)]} ${lastNames[_rng.nextInt(lastNames.length)]}';
    final salary = (salaryFor(skill) * (0.85 + _rng.nextDouble() * 0.3) / 100)
            .round() *
        100.0;
    return Staff(
        id: _newId('p'), name: name, role: role, skill: skill, salary: salary);
  }

  void _refreshMarket() {
    market.clear();
    for (final r in Role.values) {
      market.add(_randomPerson(r));
      market.add(_randomPerson(r));
    }
    market.add(_randomPerson(Role.values[_rng.nextInt(4)]));
    market.add(_randomPerson(Role.values[_rng.nextInt(4)]));
    market.sort((a, b) => a.role.index.compareTo(b.role.index));
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
    if (cash < p.signingFee) return 'İmza ücreti için kasada para yok.';
    cash -= p.signingFee;
    market.remove(p);
    staff.add(p);
    _notify('✍️ ${p.name} kadroya katıldı!');
    _changed();
    return null;
  }

  String? fire(Staff p) {
    if (p.showId != null) return 'Bu kişi bir programda çalışıyor.';
    final severance = p.salary * 3;
    cash -= severance;
    staff.remove(p);
    _notify('${p.name} ile yollar ayrıldı (tazminat ${fmtShort(severance)}).');
    _changed();
    return null;
  }

  // =================================================================
  // Yapım
  // =================================================================

  String? createShow(String name, Genre genre, int tier, List<Staff> crew) {
    final def = genreDefs[genre]!;
    if (!genreUnlocked(genre)) {
      return '${def.label} için ${equipById(def.reqEquip!)!.name} gerekli.';
    }
    for (final e in def.needs.entries) {
      final n = crew.where((c) => c.role == e.key).length;
      if (n < e.value) return '${e.value} ${e.key.label} seçmelisin.';
    }
    final cost = productionCost(genre, tier);
    if (cash < cost) return 'Kasada yeterli para yok (${fmtShort(cost)}).';
    cash -= cost;
    final s = Show(
      id: _newId('s'),
      name: name.trim().isEmpty ? showNameIdeas[genre]!.first : name.trim(),
      genre: genre,
      tier: tier,
      staffIds: crew.map((c) => c.id).toList(),
      prodLeft: def.prodDays * prodSpeedMult(),
      quality: showQuality(crew, genre, tier, ownedEquip) *
          (genre == Genre.dizi ? 1 + musicQualityBonus : 1),
    );
    for (final c in crew) {
      c.showId = s.id;
    }
    shows.insert(0, s);
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
    final cost = productionCost(s.genre, s.tier);
    if (cash < cost) return 'Kasada yeterli para yok (${fmtShort(cost)}).';
    cash -= cost;
    for (final c in crew) {
      c.showId = s.id;
    }
    final fatigue = pow(0.95, s.season).toDouble();
    s
      ..season += 1
      ..episodesAired = 0
      ..seasonRevenue = 0
      ..status = ShowStatus.producing
      ..prodLeft = max(1.0, s.def.prodDays - 1) * prodSpeedMult()
      ..quality = showQuality(crew, s.genre, s.tier, ownedEquip) * fatigue
      ..ratingHistory.clear();
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
    _notify('📡 "${s.name}" ${slotDefs[slot]!.label} kuşağında yayında!');
    _changed();
    return null;
  }

  void takeOffAir(SlotId slot) {
    final s = showById(slots[slot]!.showId);
    if (s != null) _endSeason(s);
    _changed();
  }

  void setAdMinutes(SlotId slot, double m) {
    slots[slot]!.adMinutes = m;
    _changed();
  }

  // =================================================================
  // Stüdyo, ekipman
  // =================================================================

  String? upgradeStudio() {
    if (studioLevel >= studioLevels.length - 1) return 'Zaten en üst seviye!';
    final next = studioLevels[studioLevel + 1];
    if (cash < next.upgradeCost) return 'Kasada yeterli para yok.';
    cash -= next.upgradeCost;
    studioLevel++;
    _refreshMarket();
    _log('Stüdyo büyüdü', '$channelName artık bir ${next.name}!', true);
    _notify('🏗️ Tebrikler! Artık bir ${next.name}sın!');
    _changed();
    return null;
  }

  String? buyEquip(EquipDef e) {
    if (ownedEquip.contains(e.id)) return 'Zaten sahipsin.';
    if (studioLevel + 1 < e.reqLevel) {
      return 'Stüdyo seviyesi ${e.reqLevel} gerekli.';
    }
    if (cash < e.price) return 'Kasada yeterli para yok.';
    cash -= e.price;
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
    cash += o.amount;
    loans.add(Loan(
      id: _newId('l'),
      principal: o.amount,
      installment: o.installment,
      installmentsLeft: o.installments,
      nextDueDay: day + 7,
    ));
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

  String? buyFixed(LuxuryDef d) {
    if (ownedLuxury.contains(d.id)) return 'Zaten sahipsin.';
    if (cash < d.price) return 'Kasada yeterli para yok.';
    cash -= d.price;
    ownedLuxury.add(d.id);
    _notify('✨ ${d.name} artık senin! +${d.prestige} prestij');
    _changed();
    return null;
  }

  double sellValueLuxury(LuxuryDef d) => d.price * 0.7;

  void sellLuxury(LuxuryDef d) {
    if (!ownedLuxury.remove(d.id)) return;
    cash += sellValueLuxury(d);
    _notify('${d.name} satıldı: +${fmtShort(sellValueLuxury(d))}');
    _changed();
  }

  double sellValueChannel(ChannelDef c) => c.price * 0.8;

  void sellChannel(ChannelDef c) {
    if (!ownedChannels.remove(c.id)) return;
    cash += sellValueChannel(c);
    _notify('${c.name} satıldı: +${fmtShort(sellValueChannel(c))}');
    _changed();
  }

  NegState negFor(String id) => negotiations.putIfAbsent(
      id, () => NegState(floorFactor: 0.74 + _rng.nextDouble() * 0.18));

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
      return NegResult(NegOutcome.locked,
          'Satıcı seninle konuşmak istemiyor. ${st.lockedUntil - day} gün bekle.');
    }
    if (cash < offer) {
      return const NegResult(
          NegOutcome.noMoney, 'Önce kasanı doldur, sonra konuşalım.');
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
      return const NegResult(NegOutcome.walkedAway,
          'Yeter! Satıcı masadan kalktı. 3 gün sonra tekrar dene.');
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
      _log('Platform satın alındı', '${plat.name} artık $channelName ailesinde!',
          true);
      _notify('📲 ${plat.name} artık senin! ${fmtDec(plat.subscribersM, 1)} M abone, '
          'günlük +${fmtShort(plat.dailyIncome)}');
    } else if (lux.isNotEmpty) {
      ownedLuxury.add(id);
      _notify('✨ ${lux.first.name} artık senin! +${lux.first.prestige} prestij');
    } else {
      final ch = channelDefs.firstWhere((c) => c.id == id);
      ownedChannels.add(id);
      _log('Kanal satın alındı', '${ch.name} artık $channelName ailesinde!',
          true);
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
    if (ownedEquip.contains('cam')) bonus += 0.06;
    if (ownedEquip.contains('sound')) bonus += 0.04;
    return (avg * budgetTiers[tier].qualityMult * (1 + bonus)).clamp(0.0, 1.3);
  }

  String? createFilm(String name, FilmGenre genre, int tier, List<Staff> crew) {
    final def = filmGenreDefs[genre]!;
    if (!filmGenreUnlocked(genre)) {
      return '${def.label} için ${equipById(def.reqEquip!)!.name} gerekli.';
    }
    for (final e in def.needs.entries) {
      if (crew.where((c) => c.role == e.key).length < e.value) {
        return '${e.value} ${e.key.label} seçmelisin.';
      }
    }
    final cost = filmCost(genre, tier);
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
      quality: filmQuality(crew, tier),
    );
    for (final c in crew) {
      c.showId = f.id;
    }
    films.insert(0, f);
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
    if (f.status == FilmStatus.ready) f.status = FilmStatus.library;
    _notify('📲 "${f.name}" $licenseDays günlüğüne ${p.name}\'a satıldı: +${fmtShort(fee)}');
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
    _notify(lv == 0
        ? '🏢 ${b.name} kuruldu!'
        : '🏢 ${b.name} seviye ${lv + 1} oldu!');
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
    _changed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _saveDebounce?.cancel();
    super.dispose();
  }
}
