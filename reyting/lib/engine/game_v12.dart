part of 'game.dart';

/// v0.12: şirket kimliği, prodüksiyon bütçesi, ünlü konuklar, senaryo
/// kararları, çekim lokasyonları, yetenek ajansı, yönetim kurulu, markalar.
extension GameV12 on Game {
  // =================================================================
  // Kayıt
  // =================================================================
  void _resetV12() {
    companyName = 'Kanal 9';
    companySuffix = 0;
    logo = CompanyLogo();
    identitySet = false;
    ownedLocations.clear();
    openedCities
      ..clear()
      ..add(homeCityPlate);
    luxSold.clear();
    luxSerial.clear();
    luxListings.clear();
    luxForSale.clear();
    luxOffers.clear();
    _luxInit();
    eventReadyDay.clear();
    agencyLevel = 0;
    yagizUsed = false;
    academy.clear();
    youthMarket.clear();
    transferMarket.clear();
    transferOffers.clear();
    talentsSold = 0;
    transferProfit = 0;
    execs.clear();
    execCandidates.clear();
    brandOffers.clear();
    deals.clear();
    storyChoices = 0;
    eventsHeld = 0;
    _shopReset();
    _refreshExecCandidates();
  }

  Map<String, dynamic> _v12ToJson() => {
    'companyName': companyName,
    'companySuffix': companySuffix,
    'logo': logo.toJson(),
    'identitySet': identitySet,
    'stingOn': stingOn,
    'locations': ownedLocations.toList(),
    'cities': openedCities.toList(),
    'luxSold': luxSold,
    'luxSerial': luxSerial,
    'luxListings': luxListings.map((e) => e.toJson()).toList(),
    'luxForSale': luxForSale.toList(),
    'luxOffers': luxOffers.map((e) => e.toJson()).toList(),
    'eventReady': eventReadyDay,
    'agencyLevel': agencyLevel,
    'yagizUsed': yagizUsed,
    'academy': academy.map((e) => e.toJson()).toList(),
    'youthMarket': youthMarket.map((e) => e.toJson()).toList(),
    'transferMarket': transferMarket.map((e) => e.toJson()).toList(),
    'transferOffers': transferOffers.map((e) => e.toJson()).toList(),
    'talentsSold': talentsSold,
    'transferProfit': transferProfit,
    'econ': kEconVersion,
    'execs': execs.values.map((e) => e.toJson()).toList(),
    'execCandidates': execCandidates.map((e) => e.toJson()).toList(),
    'brandOffers': brandOffers.map((e) => e.toJson()).toList(),
    'deals': deals.map((e) => e.toJson()).toList(),
    'storyChoices': storyChoices,
    'eventsHeld': eventsHeld,
    ..._shopToJson(),
    'adDemand': adDemand,
  };

  void _v12Load(Map<String, dynamic> j) {
    companyName = j['companyName'] ?? channelName;
    companySuffix = j['companySuffix'] ?? 0;
    logo = j['logo'] == null ? CompanyLogo() : CompanyLogo.fromJson(j['logo']);
    identitySet = j['identitySet'] ?? false;
    stingOn = j['stingOn'] ?? true;
    ownedLocations
      ..clear()
      ..addAll(List<String>.from(j['locations'] ?? []));
    eventReadyDay
      ..clear()
      ..addAll(Map<String, int>.from(j['eventReady'] ?? {}));
    openedCities
      ..clear()
      ..add(homeCityPlate)
      ..addAll(List<int>.from(j['cities'] ?? []));
    luxSold
      ..clear()
      ..addAll(Map<String, int>.from(j['luxSold'] ?? {}));
    luxSerial
      ..clear()
      ..addAll(Map<String, int>.from(j['luxSerial'] ?? {}));
    luxListings
      ..clear()
      ..addAll((j['luxListings'] as List? ?? []).map((e) => LuxListing.fromJson(e)));
    luxForSale
      ..clear()
      ..addAll(List<String>.from(j['luxForSale'] ?? []));
    luxOffers
      ..clear()
      ..addAll((j['luxOffers'] as List? ?? []).map((e) => LuxOffer.fromJson(e)));
    if (luxSold.isEmpty) _luxInit();
    for (final id in ownedLuxury) {
      final d = luxuryDefs.where((x) => x.id == id).firstOrNull;
      if (d != null && d.edition != null && !luxSerial.containsKey(id)) _assignSerial(d);
    }
    // eski kayıt: set kurulmuş lokasyonların şehirleri açık sayılır
    for (final id in ownedLocations) {
      final pl = locationCity[id];
      if (pl != null) openedCities.add(pl);
    }
    agencyLevel = j['agencyLevel'] ?? 0;
    yagizUsed = j['yagizUsed'] ?? false;
    List<Staff> ppl(String k) =>
        (j[k] as List? ?? []).map((e) => Staff.fromJson(e)).toList();
    academy
      ..clear()
      ..addAll(ppl('academy'));
    youthMarket
      ..clear()
      ..addAll(ppl('youthMarket'));
    transferMarket
      ..clear()
      ..addAll(ppl('transferMarket'));
    transferOffers
      ..clear()
      ..addAll(
        (j['transferOffers'] as List? ?? []).map(
          (e) => TransferOffer.fromJson(e),
        ),
      );
    talentsSold = j['talentsSold'] ?? 0;
    transferProfit = (j['transferProfit'] as num? ?? 0).toDouble();
    execs.clear();
    for (final e in (j['execs'] as List? ?? [])) {
      final x = Exec.fromJson(e);
      execs[x.role] = x;
    }
    // eski kayıt: tek Genel Müdür
    if (j['execs'] == null && (j['managerHired'] ?? false) == true) {
      execs[ExecRole.genelMudur] = Exec(
        _newId('e'),
        'Kemal Ardıç',
        ExecRole.genelMudur,
        55,
        managerSalary,
      );
    }
    execCandidates
      ..clear()
      ..addAll(
        (j['execCandidates'] as List? ?? []).map((e) => Exec.fromJson(e)),
      );
    if (execCandidates.isEmpty) _refreshExecCandidates();
    brandOffers
      ..clear()
      ..addAll(
        (j['brandOffers'] as List? ?? []).map((e) => BrandOffer.fromJson(e)),
      );
    deals
      ..clear()
      ..addAll((j['deals'] as List? ?? []).map((e) => Deal.fromJson(e)));
    storyChoices = j['storyChoices'] ?? 0;
    eventsHeld = j['eventsHeld'] ?? 0;
    _shopLoad(j);
    if ((j['econ'] as int? ?? 1) < kEconVersion) _migrateEcon();
    adDemand = (j['adDemand'] as num? ?? 1).toDouble();
  }

  /// 1.0.2 ekonomi dengesi: eski kayıttaki maaşlar yeni ölçeğe çekilir
  void _migrateEcon() {
    for (final l in [staff, academy, market, youthMarket, transferMarket]) {
      for (final p in l) {
        p.salary = (p.salary * kIncome / 100).round() * 100.0;
      }
    }
    for (final c in [...creators, ...creatorMarket]) {
      c.salary = (c.salary * kIncome / 100).round() * 100.0;
    }
    for (final e in [...execs.values, ...execCandidates]) {
      e.salary = (e.salary * kIncome / 100).round() * 100.0;
    }
  }

  // =================================================================
  // Şirket kimliği
  // =================================================================
  String get companyFullName =>
      '$companyName ${companySuffixes[companySuffix % companySuffixes.length]}';

  void setIdentity({
    required String company,
    required int suffix,
    required String channel,
    required CompanyLogo newLogo,
  }) {
    final c = company.trim();
    final ch = channel.trim();
    if (c.isNotEmpty) companyName = c.length > 22 ? c.substring(0, 22) : c;
    companySuffix = suffix.clamp(0, companySuffixes.length - 1);
    if (ch.isNotEmpty) channelName = ch.length > 18 ? ch.substring(0, 18) : ch;
    logo = newLogo;
    identitySet = true;
    _changed();
  }

  void setSting(bool on) {
    stingOn = on;
    _changed();
  }

  void _playSting(String title) {
    if (_offlineMode || !stingOn) return;
    sting.value = title;
  }

  // =================================================================
  // Prodüksiyon: bütçe, konuk, lokasyon, uzmanlık
  // =================================================================
  bool budgetUnlocked(int b) => studioLevel + 1 >= prodBudgets[b].unlockLevel;
  bool guestUnlocked(int g) => studioLevel + 1 >= guestTiers[g].unlockLevel;

  String? prodOptionError(Genre g, int budget, int guest, String? location) {
    if (budget < 0 || budget >= prodBudgets.length) return 'Geçersiz bütçe.';
    if (guest < 0 || guest >= guestTiers.length) return 'Geçersiz konuk.';
    if (!budgetUnlocked(budget)) {
      return '${prodBudgets[budget].label} bütçe stüdyo seviyesi '
          '${prodBudgets[budget].unlockLevel} ile açılır.';
    }
    if (!guestUnlocked(guest)) {
      return '${guestTiers[guest].label} konuk stüdyo seviyesi '
          '${guestTiers[guest].unlockLevel} ile açılır.';
    }
    if (location != null && !ownedLocations.contains(location)) {
      return 'Bu lokasyonda setin yok. Önce Harita\'dan set kur.';
    }
    return null;
  }

  double guestFee(Genre g, int tier, int guest) =>
      productionCost(g, tier) * guestTiers[guest].feeMult;

  double locationFee(Genre g, int tier, String? loc) {
    final l = locationById(loc);
    if (l == null) return 0;
    return productionCost(g, tier) * (l.world ? 0.3 : 0.12);
  }

  double showCost(Genre g, int tier, int budget, int guest, String? loc) =>
      productionCost(g, tier) * prodBudgets[budget].costMult +
      guestFee(g, tier, guest) +
      locationFee(g, tier, loc);

  /// Bölüm başı giderlerden sonra gelirin kalan oranı
  double runShare(Show s) {
    final l = locationById(s.location);
    return (1 - prodBudgets[s.budget.clamp(0, prodBudgets.length - 1)].share) *
        (1 - guestTiers[s.guest.clamp(0, guestTiers.length - 1)].share) *
        (1 - (l == null ? 0 : (l.world ? 0.06 : 0.03)));
  }

  double runShareFor(int budget, int guest, String? loc) {
    final l = locationById(loc);
    return (1 - prodBudgets[budget].share) *
        (1 - guestTiers[guest].share) *
        (1 - (l == null ? 0 : (l.world ? 0.06 : 0.03)));
  }

  double showCostOf(Show s) =>
      showCost(s.genre, s.tier, s.budget, s.guest, s.location);

  bool locationFits(LocationDef l, Genre g) => l.genres.contains(g);
  bool locationFitsFilm(LocationDef l, FilmGenre g) => l.films.contains(g);

  /// Uzmanlık ve karakter özelliği çarpanı
  double crewMult(List<Staff> crew, double Function(Staff) fit) {
    if (crew.isEmpty) return 1;
    final f = crew.fold(0.0, (a, c) => a + fit(c)) / crew.length;
    final disc = crew.where((c) => c.trait == 1).length / crew.length;
    return (1 + 0.10 * f) * (1 + 0.03 * disc);
  }

  double fullShowQuality(
    List<Staff> crew,
    Genre g,
    int tier,
    int budget,
    String? loc,
  ) {
    final l = locationById(loc);
    final locMult = l != null && locationFits(l, g) ? 1 + l.bonus : 1.0;
    return (showQuality(crew, g, tier, ownedEquip) *
            (g == Genre.dizi ? 1 + musicQualityBonus : 1) *
            prodBudgets[budget].qualityMult *
            crewMult(crew, (c) => c.fitGenre(g)) *
            locMult)
        .clamp(0.0, 1.8);
  }

  double filmExtraMult(List<Staff> crew, FilmGenre g, String? loc) {
    final l = locationById(loc);
    final locMult = l != null && locationFitsFilm(l, g) ? 1 + l.bonus : 1.0;
    return crewMult(crew, (c) => c.fitFilm(g)) * locMult;
  }

  double filmLocationFee(FilmGenre g, int tier, String? loc) {
    final l = locationById(loc);
    if (l == null) return 0;
    return filmCost(g, tier) * (l.world ? 0.25 : 0.1);
  }

  /// Konuk, şöhret ve yayın müdürü etkisi (kaliteye değil reytinge)
  double showExtraMult(Show s) {
    var fame = 0.0;
    var n = 0;
    for (final id in s.staffIds) {
      final p = staffById(id);
      if (p == null) continue;
      fame += p.fame;
      n++;
    }
    final fameBonus = n == 0 ? 0.0 : fame / n / 100 * 0.10;
    return (1 + s.loyalty) *
        (1 + guestTiers[s.guest.clamp(0, guestTiers.length - 1)].boost) *
        (1 + fameBonus) *
        (1 + execBonus(ExecRole.yayin)) *
        calendarMult(s) *
        dramaMult(s);
  }

  /// Yayındaki ya da çekimdeki programın bütçesini yükseltme maliyeti
  double upgradeBudgetCost(Show s) {
    if (s.budget >= prodBudgets.length - 1) return 0;
    return productionCost(s.genre, s.tier) *
        (prodBudgets[s.budget + 1].costMult - prodBudgets[s.budget].costMult);
  }

  String? upgradeShowBudget(Show s) {
    if (s.status == ShowStatus.ended)
      return 'Biten programın bütçesi artırılamaz.';
    if (s.budget >= prodBudgets.length - 1) return 'Zaten en yüksek bütçede.';
    final nb = s.budget + 1;
    if (!budgetUnlocked(nb)) {
      return '${prodBudgets[nb].label} bütçe stüdyo seviyesi '
          '${prodBudgets[nb].unlockLevel} ile açılır.';
    }
    final cost = upgradeBudgetCost(s);
    if (cash < cost) return 'Yükseltme için ${fmtShort(cost)} gerekli.';
    cash -= cost;
    s.quality =
        (s.quality *
                prodBudgets[nb].qualityMult /
                prodBudgets[s.budget].qualityMult)
            .clamp(0.0, 1.8);
    s.budget = nb;
    _notify(
      '💎 "${s.name}" artık ${prodBudgets[nb].label} bütçeli! Dekor ve ışıklar büyüdü.',
    );
    _changed();
    return null;
  }

  /// Yayındaki programa daha ünlü bir konuk getirme (fark ödenir)
  String? upgradeShowGuest(Show s) {
    if (s.status == ShowStatus.ended) return 'Program bitti.';
    if (s.guest >= guestTiers.length - 1) return 'Zaten en ünlü konuk var.';
    final ng = s.guest + 1;
    if (!guestUnlocked(ng)) {
      return '${guestTiers[ng].label} stüdyo seviyesi ${guestTiers[ng].unlockLevel} ile açılır.';
    }
    final cost =
        guestFee(s.genre, s.tier, ng) - guestFee(s.genre, s.tier, s.guest);
    if (cash < cost) return 'Konuk ücreti için ${fmtShort(cost)} gerekli.';
    cash -= cost;
    s.guest = ng;
    final names = guestTiers[ng].names;
    s.guestName = names[_rng.nextInt(names.length)];
    _notify('🌟 ${s.guestName}, "${s.name}" programına katılıyor!');
    _changed();
    return null;
  }

  double upgradeGuestCost(Show s) => s.guest >= guestTiers.length - 1
      ? 0
      : guestFee(s.genre, s.tier, s.guest + 1) -
            guestFee(s.genre, s.tier, s.guest);

  // =================================================================
  // Senaryo kararları
  // =================================================================
  @visibleForTesting
  bool debugOfferStory() => _offerStory();

  @visibleForTesting
  void debugSpawnBrand() => _spawnBrandOffer();

  bool _offerStory() {
    final pool = shows
        .where(
          (s) =>
              s.status == ShowStatus.onAir &&
              storyTemplates.containsKey(s.genre) &&
              s.buffDays == 0,
        )
        .toList();
    if (pool.isEmpty) return false;
    final s = pool[_rng.nextInt(pool.length)];
    final tpls = storyTemplates[s.genre]!;
    final ti = _rng.nextInt(tpls.length);
    final t = tpls[ti];
    final cast = s.staffIds
        .map(staffById)
        .whereType<Staff>()
        .where((p) => p.role == Role.oyuncu || p.role == Role.sunucu)
        .toList();
    final a = cast.isNotEmpty ? cast[0].name.split(' ').first : 'Başrol';
    final b = cast.length > 1 ? cast[1].name.split(' ').first : 'Yan rol';
    String fill(String x) =>
        x.replaceAll('{a}', a).replaceAll('{b}', b).replaceAll('{s}', s.name);
    var safest = 0;
    for (int i = 1; i < t.options.length; i++) {
      if (t.options[i].chance > t.options[safest].chance) safest = i;
    }
    _setDecision(
      Decision(
        kind: 'story',
        title: t.title,
        body: fill(t.body),
        options: [for (final o in t.options) fill(o.label)],
        hints: [
          for (final o in t.options)
            '%${o.chance}: ${o.days} gün +%${((o.win - 1) * 100).round()} · '
                'değilse ${o.lose >= 1 ? 'etkisiz' : '-%${((1 - o.lose) * 100).round()}'}',
        ],
        chances: [for (final o in t.options) o.chance],
        targetId: s.id,
        extra: '${s.genre.index}:$ti',
        defaultOption: safest,
      ),
    );
    return true;
  }

  String _resolveStory(Decision d, int option, Show? s) {
    if (s == null || s.status != ShowStatus.onAir)
      return 'Program artık yayında değil.';
    final parts = d.extra.split(':');
    final t =
        storyTemplates[Genre.values[int.parse(parts[0])]]![int.parse(parts[1])];
    final o = t.options[option];
    storyChoices++;
    if (_rng.nextInt(100) < o.chance) {
      s
        ..buff = o.win
        ..buffDays = o.days;
      bonusPrestige += 1;
      return '🎉 Seyirci bayıldı! "${s.name}" ${o.days} gün reyting +%${((o.win - 1) * 100).round()}.';
    }
    if (o.lose < 1) {
      s
        ..buff = o.lose
        ..buffDays = max(1, o.days - 1);
      return '😬 Tutmadı… "${s.name}" ${max(1, o.days - 1)} gün reyting -%${((1 - o.lose) * 100).round()}.';
    }
    return 'Seyirci pek tepki vermedi.';
  }

  // =================================================================
  // Lokasyonlar ve etkinlikler
  // =================================================================
  double get locationUpkeep => locationDefs
      .where((l) => ownedLocations.contains(l.id))
      .fold(0.0, (a, l) => a + l.upkeep);

  // =================================================================
  // Şehirler (81 il)
  // =================================================================
  /// Açık şehirler izleyici erişimini en fazla %15 büyütür (nüfusa göre)
  double get cityReachBonus =>
      0.15 *
      cityDefs.where((c) => openedCities.contains(c.plate)).fold(0.0, (a, c) => a + c.weight) /
      totalCityWeight;

  /// Bölgede açılan şehirler oranında o bölgenin sevdiği türlere +%5'e kadar reyting
  double cityGenreBonus(Genre g) {
    var b = 0.0;
    for (int r = 0; r < regionDefs.length; r++) {
      if (!regionDefs[r].genres.contains(g)) continue;
      var tot = 0.0, open = 0.0;
      for (final c in cityDefs) {
        if (c.region != r) continue;
        tot += c.weight;
        if (openedCities.contains(c.plate)) open += c.weight;
      }
      if (tot > 0) b += 0.03 * open / tot;
    }
    return b;
  }

  double cityReachShare(CityDef c) => 0.15 * c.weight / totalCityWeight;

  String? openCity(CityDef c) {
    if (openedCities.contains(c.plate)) return '${c.name} zaten açık.';
    if (cash < c.price) return '${c.name} için ${fmtShort(c.price)} gerekli.';
    cash -= c.price;
    openedCities.add(c.plate);
    _count('city');
    _notify('🏙️ ${c.name} yayın ağına katıldı! Erişim +%${fmtDec(cityReachShare(c) * 100, 1)}');
    _changed();
    return null;
  }

  String? locationLockReason(LocationDef l) {
    final pl = locationCity[l.id];
    if (!l.world && pl != null && !openedCities.contains(pl)) {
      return 'Önce ${cityByPlate(pl)!.name} şehrini aç';
    }
    if (studioLevel + 1 < l.reqLevel)
      return 'Stüdyo seviyesi ${l.reqLevel} gerekli';
    if (l.reqEquip != null && !ownedEquip.contains(l.reqEquip)) {
      return '${equipById(l.reqEquip!)!.name} gerekli';
    }
    return null;
  }

  String? buyLocation(LocationDef l) {
    if (ownedLocations.contains(l.id)) return 'Burada zaten setin var.';
    final lock = locationLockReason(l);
    if (lock != null) return lock;
    if (cash < l.price) return 'Set kurmak için ${fmtShort(l.price)} gerekli.';
    cash -= l.price;
    ownedLocations.add(l.id);
    _count('location');
    _notify('📍 ${l.city} · ${l.name} setin kuruldu! +${l.prestige} prestij');
    _changed();
    return null;
  }

  double eventCost(LocationDef l) => l.price * (l.event?.costMult ?? 0);

  int eventDaysLeft(LocationDef l) => max(0, (eventReadyDay[l.id] ?? 0) - day);

  /// Etkinliğin tahmini getirisi (aralık ortası)
  double eventExpected(LocationDef l) {
    var m = 1.45;
    if (l.id == 'seul') {
      final dizi = shows
          .where((s) => s.genre == Genre.dizi && s.season >= 1)
          .length;
      m += min(0.6, dizi * 0.12);
    }
    return eventCost(l) * (1 + (m - 1) * kIncome * 2.2) * (1 + prestigeAdBonus(prestige));
  }

  String? holdEvent(LocationDef l) {
    final ev = l.event;
    if (ev == null) return 'Bu lokasyonda etkinlik yok.';
    if (!ownedLocations.contains(l.id)) return 'Önce set kur.';
    if (eventDaysLeft(l) > 0)
      return '${eventDaysLeft(l)} gün sonra tekrar düzenlenebilir.';
    final cost = eventCost(l);
    if (cash < cost) return 'Etkinlik için ${fmtShort(cost)} gerekli.';
    cash -= cost;
    final reward = eventExpected(l) * (0.8 + _rng.nextDouble() * 0.4);
    _gain(reward);
    bonusPrestige += ev.prestige;
    eventReadyDay[l.id] = day + ev.cooldown;
    eventsHeld++;
    _log(
      '🎪 ${ev.name}',
      '${l.city}: +${fmtShort(reward - cost)} kâr, +${ev.prestige} prestij',
      true,
    );
    _notify(
      '🎪 ${ev.name} (${l.city}) büyük ilgi gördü! '
      'Net +${fmtShort(reward - cost)}, +${ev.prestige} prestij',
    );
    _changed();
    return null;
  }

  // =================================================================
  // Yetenek ajansı
  // =================================================================
  AgencyLevel get agency => agencyLevels[agencyLevel];
  bool get agencyOpen => agencyLevel > 0;
  AgencyLevel? get nextAgency => agencyLevel + 1 < agencyLevels.length
      ? agencyLevels[agencyLevel + 1]
      : null;

  String? upgradeAgency() {
    final n = nextAgency;
    if (n == null) return 'Ajans zirvede!';
    final reqStudio = agencyLevel + 1; // ajans seviyesi stüdyoyu geçemez
    if (studioLevel + 1 < reqStudio) {
      return 'Önce stüdyoyu seviye $reqStudio yap.';
    }
    if (cash < n.cost) return 'Gerekli: ${fmtShort(n.cost)}';
    cash -= n.cost;
    agencyLevel++;
    if (agencyLevel == 1) _refreshYouth();
    _refreshTransferMarket();
    _notify('⭐ Ajans seviye $agencyLevel: ${agency.name}!');
    _changed();
    return null;
  }

  /// Piyasa değeri: yetenek, şöhret, potansiyel ve yaş
  double talentValue(Staff p) {
    final room = max(0, p.potential - p.skill) / 40 * (p.age <= 23 ? 1.0 : 0.3);
    return salaryFor(p.skill) * 40 * (1 + p.fame / 40) * (1 + room);
  }

  String _name() =>
      '${firstNames[_rng.nextInt(firstNames.length)]} ${lastNames[_rng.nextInt(lastNames.length)]}';

  int _randTrait({bool young = false}) {
    final r = _rng.nextDouble();
    if (r < 0.45) return 0;
    if (young && r > 0.92) return 8;
    return 1 + _rng.nextInt(7);
  }

  Staff _youngPerson({int bonus = 0}) {
    final role = Role.values[_rng.nextInt(4)];
    final age = 16 + _rng.nextInt(5);
    final skill = 12 + _rng.nextInt(22) + agencyLevel * 2;
    final maxP = min(99, agency.maxPotential + bonus);
    final pot = max(
      skill + 10,
      min(maxP, 45 + _rng.nextInt(max(1, maxP - 44)) + bonus ~/ 2),
    );
    final p = Staff(
      id: _newId('y'),
      name: _name(),
      role: role,
      skill: skill,
      salary: (salaryFor(skill) * 0.5 / 100).round() * 100.0,
      age: age,
      potential: pot,
      trait: _randTrait(young: true),
      spec: _rng.nextInt(specsByRole[role]!.length),
    );
    return p;
  }

  double youthSignFee(Staff p) => talentValue(p) * 0.3;

  /// Özel genç yetenek: Yağız Ada (ortalama değerlerde, her kariyerde bir kez)
  static const yagizId = 'y_yagiz_ada';

  Staff _yagizAda() {
    final skill = 24 + agencyLevel * 2;
    return Staff(
      id: yagizId,
      name: 'Yağız Ada',
      role: Role.oyuncu,
      skill: skill,
      salary: (salaryFor(skill) * 0.5 / 100).round() * 100.0,
      age: 18,
      potential: min(99, 68 + agencyLevel * 3),
      trait: 0,
      spec: 0,
    );
  }

  bool get _yagizOwned =>
      yagizUsed || [...staff, ...academy, ...transferMarket].any((p) => p.id == yagizId);

  void _refreshYouth() {
    youthMarket.clear();
    if (!agencyOpen) return;
    if (!_yagizOwned) youthMarket.add(_yagizAda());
    // daha çok seçenek: gözlemci sayısının iki katı aday (en az 6)
    final n = max(6, agency.scouts * 2);
    for (int i = 0; i < n; i++) {
      youthMarket.add(_youngPerson());
    }
  }

  static const scoutCost = 2;

  /// Gözlemci gönder: 3 yeni ve daha potansiyelli genç (2 elmas)
  String? sendScout() {
    if (!agencyOpen) return 'Önce ajansı aç.';
    if (diamonds < scoutCost) return '$scoutCost 💎 gerekli.';
    diamonds -= scoutCost;
    for (int i = 0; i < 3; i++) {
      youthMarket.insert(0, _youngPerson(bonus: 6));
    }
    _notify('🔭 Gözlemcin 3 yeni genç yetenek buldu!');
    _changed();
    return null;
  }

  String? signYouth(Staff p) {
    if (!agencyOpen) return 'Önce ajansı aç.';
    if (academy.length >= agency.academySlots) {
      return 'Akademi dolu (${agency.academySlots}). Ajansı büyüt ya da birini kadroya al.';
    }
    final fee = youthSignFee(p);
    if (cash < fee) return 'İmza için ${fmtShort(fee)} gerekli.';
    cash -= fee;
    youthMarket.remove(p);
    p.joinedDay = day;
    if (p.id == yagizId) yagizUsed = true;
    academy.add(p);
    _count('youth');
    _notify('🌱 ${p.name} (${p.age}) akademine katıldı!');
    _changed();
    return null;
  }

  /// Akademiden kadroya (programlarda oynayabilir)
  String? promoteYouth(Staff p) {
    if (staff.length >= studio.maxStaff) {
      return 'Kadro dolu (${studio.maxStaff}). Stüdyoyu büyüt.';
    }
    academy.remove(p);
    p.salary = (salaryFor(p.skill) * 0.8 / 100).round() * 100.0;
    staff.add(p);
    _notify('🎬 ${p.name} kadroya yükseldi! Artık programlarda çalışabilir.');
    _changed();
    return null;
  }

  /// Kadrodaki genci akademiye geri gönder (programda değilse)
  String? sendToAcademy(Staff p) {
    if (p.showId != null) return 'Bu kişi bir projede çalışıyor.';
    if (academy.length >= agency.academySlots) return 'Akademi dolu.';
    staff.remove(p);
    p.salary = (salaryFor(p.skill) * 0.5 / 100).round() * 100.0;
    academy.add(p);
    _changed();
    return null;
  }

  double prCost(Staff p) => talentValue(p) * 0.3;

  /// Tanıtım kampanyası: şöhret +12
  String? promoteFame(Staff p) {
    if (p.fame >= 95) return '${p.name} zaten çok ünlü.';
    final c = prCost(p);
    if (cash < c) return 'Kampanya için ${fmtShort(c)} gerekli.';
    cash -= c;
    p.fame = min(100, p.fame + 12 * (p.trait == 2 ? 1.5 : 1));
    _notify('📣 ${p.name} için tanıtım kampanyası: şöhret ${p.fame.round()}');
    _changed();
    return null;
  }

  void toggleForSale(Staff p) {
    p.forSale = !p.forSale;
    if (!p.forSale) transferOffers.removeWhere((o) => o.staffId == p.id);
    _changed();
  }

  Staff? _anyPerson(String id) {
    for (final p in staff) {
      if (p.id == id) return p;
    }
    for (final p in academy) {
      if (p.id == id) return p;
    }
    return null;
  }

  Staff? personById(String id) => _anyPerson(id);

  void _removePerson(Staff p) {
    if (academy.remove(p)) return;
    _quit(p);
  }

  String? acceptTransfer(TransferOffer o) {
    final p = _anyPerson(o.staffId);
    if (p == null || o.expires < day) {
      transferOffers.remove(o);
      _changed();
      return 'Teklif artık geçerli değil.';
    }
    _cashIn(o.amount); // günlük gelir sayılmaz
    transferProfit += o.amount;
    talentsSold++;
    _removePerson(p);
    transferOffers.removeWhere((x) => x.staffId == p.id);
    deals.removeWhere((d) => d.targetId == p.id);
    _count('transfer');
    _notify(
      '💸 ${p.name}, ${o.from} kanalına transfer oldu: +${fmtShort(o.amount)}',
    );
    _changed();
    return null;
  }

  /// Yeni alınan kişi hemen satılırsa değeri düşük; 60 günde tam değere çıkar
  double holdFactor(Staff p) => ((day - p.joinedDay) / 60).clamp(0.15, 1.0).toDouble();

  double quickSaleValue(Staff p) => talentValue(p) * 0.6 * holdFactor(p);

  String? quickSell(Staff p) {
    if (p.showId != null && showById(p.showId) == null) {
      return 'Bu kişi bir film/ihale çekiminde.';
    }
    final v = quickSaleValue(p);
    _cashIn(v); // günlük gelir sayılmaz
    transferProfit += v;
    talentsSold++;
    _removePerson(p);
    transferOffers.removeWhere((x) => x.staffId == p.id);
    deals.removeWhere((d) => d.targetId == p.id);
    _notify('💸 ${p.name} ajanslara satıldı: +${fmtShort(v)}');
    _changed();
    return null;
  }

  double transferPrice(Staff p) => talentValue(p) * 1.3;

  void _refreshTransferMarket() {
    transferMarket.clear();
    if (!agencyOpen) return;
    for (int i = 0; i < agency.transferList; i++) {
      final role = Role.values[_rng.nextInt(4)];
      final skill = min(99, 55 + studioLevel * 3 + _rng.nextInt(30));
      final fame = 15.0 + _rng.nextInt(60);
      transferMarket.add(
        Staff(
          id: _newId('t'),
          name: _name(),
          role: role,
          skill: skill,
          salary: (salaryFor(skill) * (1 + fame / 100) / 100).round() * 100.0,
          age: 20 + _rng.nextInt(16),
          fame: fame,
          trait: _randTrait(),
          spec: _rng.nextInt(specsByRole[role]!.length),
        ),
      );
    }
  }

  String? buyTransfer(Staff p) {
    if (staff.length >= studio.maxStaff) {
      return 'Kadro dolu (${studio.maxStaff}). Stüdyoyu büyüt.';
    }
    final price = transferPrice(p);
    if (cash < price) return 'Bonservis için ${fmtShort(price)} gerekli.';
    cash -= price;
    transferMarket.remove(p);
    p.joinedDay = day;
    staff.add(p);
    _notify(
      '✍️ Yıldız transfer: ${p.name} kadroda! (şöhret ${p.fame.round()})',
    );
    _changed();
    return null;
  }

  void _agencyDaily() {
    final growth = agency.growth * (1 + execBonus(ExecRole.ajans));
    void grow(Staff p, double mult) {
      if (p.age > 26 || p.skill >= p.potential) return;
      var g = 0.32 * mult * (p.trait == 8 ? 1.6 : 1) * (p.age <= 19 ? 1.2 : 1);
      p.xp += g;
      while (p.xp >= 1 && p.skill < p.potential) {
        p.xp -= 1;
        p.skill++;
      }
    }

    for (final p in academy) {
      grow(p, max(1.0, growth) * 1.3);
      p.salary = (salaryFor(p.skill) * 0.5 / 100).round() * 100.0;
    }
    for (final p in staff) {
      grow(p, max(0.6, growth));
      // şöhret: yayındaki programda büyür, yoksa yavaşça söner
      final s = showById(p.showId);
      if (s != null && s.status == ShowStatus.onAir) {
        final r = currentRating(s);
        p.fame = min(
          100,
          p.fame + r / 12 * (p.trait == 2 ? 2 : 1) * (p.trait == 4 ? 1.5 : 1),
        );
      } else {
        p.fame = max(0, p.fame - 0.15);
      }
    }
    if (day % 120 == 0) {
      for (final p in [...staff, ...academy]) {
        p.age++;
      }
    }
    if (!agencyOpen) return;
    _refreshYouth();
    if (day % 3 == 0) _refreshTransferMarket();
    // satıştaki oyunculara teklifler
    transferOffers.removeWhere(
      (o) => o.expires < day || _anyPerson(o.staffId) == null,
    );
    final rivals = rivalDefs.map((r) => r.name).toList();
    for (final p in [...staff, ...academy]) {
      if (!p.forSale) continue;
      if (_rng.nextDouble() < 0.55) {
        transferOffers.add(
          TransferOffer(
            p.id,
            rivals[_rng.nextInt(rivals.length)],
            (talentValue(p) * holdFactor(p) * (0.75 + _rng.nextDouble() * 0.45) / 1000)
                    .round() *
                1000.0,
            day + 3,
          ),
        );
      }
    }
    final aj = execs[ExecRole.ajans];
    if (aj != null) {
      final thr = 1.12 - aj.power * 0.1;
      for (final o in transferOffers.toList()) {
        final p = _anyPerson(o.staffId);
        if (p != null && o.amount >= talentValue(p) * thr) acceptTransfer(o);
      }
    }
  }

  // =================================================================
  // Yönetim kurulu
  // =================================================================
  bool execUnlocked(ExecRole r) => studioLevel + 1 >= execDefs[r]!.unlockLevel;

  double execBonus(ExecRole r) {
    final e = execs[r];
    if (e == null) return 0;
    return e.def.maxBonus * e.power;
  }

  /// Yönetici adaylarının yenilenmesine kalan gün
  int get execRefreshDays => 5 - (day % 5);

  double get execSalaries => execs.values.fold(0.0, (a, e) => a + e.salary);

  double execSalaryFor(ExecRole r, int skill) =>
      15000 *
      pow(1.9, studioLevel).toDouble() *
      (r == ExecRole.genelMudur ? 1.0 : 0.7) *
      (0.35 + 1.4 * pow(skill / 100, 2.5)) *
      kIncome;

  void _refreshExecCandidates() {
    execCandidates.clear();
    for (final r in ExecRole.values) {
      if (!execUnlocked(r)) continue;
      for (final band in const [(35, 20), (60, 18), (82, 17)]) {
        final skill = min(99, band.$1 + _rng.nextInt(band.$2));
        execCandidates.add(
          Exec(
            _newId('e'),
            _name(),
            r,
            skill,
            (execSalaryFor(r, skill) / 100).round() * 100.0,
          ),
        );
      }
    }
  }

  /// Yeni açılan koltukların adayları beklemeden gelsin
  void _ensureExecCandidates() {
    for (final r in ExecRole.values) {
      if (!execUnlocked(r) || execCandidates.any((e) => e.role == r)) continue;
      for (final band in const [(35, 20), (60, 18), (82, 17)]) {
        final skill = min(99, band.$1 + _rng.nextInt(band.$2));
        execCandidates.add(Exec(_newId('e'), _name(), r, skill,
            (execSalaryFor(r, skill) / 100).round() * 100.0));
      }
    }
  }

  String? hireExec(Exec e) {
    if (!execUnlocked(e.role)) return 'Bu koltuk henüz açılmadı.';
    if (cash < e.signingFee)
      return 'İmza ücreti için ${fmtShort(e.signingFee)} gerekli.';
    final old = execs[e.role];
    cash -= e.signingFee;
    execs[e.role] = e;
    execCandidates.remove(e);
    _notify(
      old == null
          ? '🤵 ${e.name}, ${e.def.label} olarak göreve başladı!'
          : '🤵 ${old.name} gitti, yerine ${e.name} geldi.',
    );
    _changed();
    return null;
  }

  void fireExec(ExecRole r) {
    final e = execs.remove(r);
    if (e != null) _notify('${e.name} ile yollar ayrıldı.');
    _changed();
  }

  /// Yöneticilerin her gün yaptığı otomatik işler
  void _execDaily() {
    // Yayın planlama: hazır programları en iyi boş kuşağa koy, reklamı ayarla
    final yp = execs[ExecRole.yayin];
    if (yp != null) {
      for (final s
          in shows.where((s) => s.status == ShowStatus.ready).toList()) {
        SlotId? best;
        var bestV = 0.0;
        for (final id in SlotId.values) {
          if (!slotUnlocked(id) || slots[id]!.showId != null) continue;
          final v =
              previewRating(s, id) *
              slotDefs[id]!.poolMillions *
              slotDefs[id]!.adValue;
          if (v > bestV) {
            bestV = v;
            best = id;
          }
        }
        if (best != null) putOnAir(s, best);
      }
      for (final e in slots.entries) {
        final s = showById(e.value.showId);
        if (s == null) continue;
        final err = (1 - yp.power) * 0.3 * (_rng.nextBool() ? 1 : -1);
        e.value.adMinutes = (adTolerance(s.quality) * (1 + err))
            .clamp(2.0, 20.0)
            .roundToDouble();
      }
    }
    // İK: kadroyu eğitime gönder
    final ik = execs[ExecRole.ik];
    if (ik != null) {
      final cands = staff.where(canTrain).toList()
        ..sort((a, b) => b.skill.compareTo(a.skill));
      final n = 1 + (ik.power * 2).floor();
      for (final p in cands.take(n)) {
        if (cash > trainCost(p) * 20) trainStaff(p);
      }
    }
    // Sinema: biten filmi vizyona, vizyondan ineni platforma
    if (execs.containsKey(ExecRole.sinema)) {
      for (final f in films) {
        if (f.status == FilmStatus.ready) {
          releaseInTheaters(f);
        } else if (f.status == FilmStatus.library && f.rightsOwned) {
          PlatformDef? best;
          var bv = 0.0;
          for (final p in platformDefs) {
            if (ownedPlatforms.contains(p.id) ||
                f.licenses.any((l) => l.platformId == p.id) ||
                f.score < minScoreFor(p)) {
              continue;
            }
            final v = licenseOfferFor(f, p);
            if (v > bv) {
              bv = v;
              best = p;
            }
          }
          if (best != null) licenseFilm(f, best);
        }
      }
    }
    // Pazarlama: en iyi marka tekliflerini kabul et
    if (execs.containsKey(ExecRole.pazarlama)) {
      final offers = brandOffers.toList()
        ..sort((a, b) => b.total.compareTo(a.total));
      for (final o in offers) {
        acceptBrandOffer(o, silent: true);
      }
    }
  }

  double signingFeeFor(Staff p) => p.signingFee * (1 - execBonus(ExecRole.ik));

  // =================================================================
  // Markalar
  // =================================================================
  int get brandTier => min(brandTiers.length - 1, prestige ~/ 250);

  double get brandMult => 1 + execBonus(ExecRole.pazarlama);

  double get dealIncomePerDay =>
      deals.fold(0.0, (a, d) => a + d.perDay) * kIncome;

  void _brandDaily() {
    brandOffers.removeWhere((o) => o.expires < day);
    for (final d in deals) {
      d.daysLeft--;
    }
    deals.removeWhere(
      (d) =>
          d.daysLeft <= 0 ||
          (d.kind == DealKind.starFace &&
              d.targetId != null &&
              _anyPerson(d.targetId!) == null),
    );
    final p =
        0.22 +
        min(0.3, prestige / 3000) +
        (execs.containsKey(ExecRole.pazarlama) ? 0.15 : 0);
    if (brandOffers.length < 4 && _rng.nextDouble() < p) _spawnBrandOffer();
  }

  void _spawnBrandOffer() {
    final tierBrands = brandTiers[max(0, brandTier - _rng.nextInt(2))];
    final brand = tierBrands[_rng.nextInt(tierBrands.length)];
    final kinds = <DealKind>[];
    final freeShows = shows
        .where(
          (s) =>
              s.status == ShowStatus.onAir &&
              s.sponsorDays == 0 &&
              !brandOffers.any((o) => o.targetId == s.id),
        )
        .toList();
    if (freeShows.isNotEmpty)
      kinds.addAll([DealKind.placement, DealKind.placement]);
    if (adIncomePerDay > 0 &&
        !deals.any((d) => d.kind == DealKind.adBlock) &&
        !brandOffers.any((o) => o.kind == DealKind.adBlock)) {
      kinds.add(DealKind.adBlock);
    }
    final famous = staff
        .where(
          (s) =>
              s.fame >= 30 &&
              !deals.any((d) => d.targetId == s.id) &&
              !brandOffers.any((o) => o.targetId == s.id),
        )
        .toList();
    if (famous.isNotEmpty) kinds.add(DealKind.starFace);
    final prodFilms = films
        .where((f) => f.status == FilmStatus.producing)
        .toList();
    if (prodFilms.isNotEmpty) kinds.add(DealKind.filmPlacement);
    if (prestige >= 300 &&
        adIncomePerDay > 0 &&
        !deals.any((d) => d.kind == DealKind.channelSponsor) &&
        !brandOffers.any((o) => o.kind == DealKind.channelSponsor)) {
      kinds.add(DealKind.channelSponsor);
    }
    if (kinds.isEmpty) return;
    final k = kinds[_rng.nextInt(kinds.length)];
    final r = _rng.nextDouble();
    final exp = day + 3;
    final m = brandMult;
    BrandOffer? o;
    switch (k) {
      case DealKind.placement:
        final s = freeShows[_rng.nextInt(freeShows.length)];
        o = BrandOffer(
          _newId('b'),
          brand,
          k,
          s.id,
          max(5000.0, revenuePerDay(s) * (0.2 + r * 0.15)) * m,
          0,
          10,
          0.03,
          exp,
        );
      case DealKind.adBlock:
        o = BrandOffer(
          _newId('b'),
          brand,
          k,
          null,
          adIncomePerDay * (0.04 + r * 0.03) * m,
          0,
          14,
          0,
          exp,
        );
      case DealKind.starFace:
        final p = famous[_rng.nextInt(famous.length)];
        o = BrandOffer(
          _newId('b'),
          brand,
          k,
          p.id,
          p.salary * (0.5 + p.fame / 50) * m,
          0,
          20,
          0,
          exp,
        );
      case DealKind.filmPlacement:
        final f = prodFilms[_rng.nextInt(prodFilms.length)];
        o = BrandOffer(
          _newId('b'),
          brand,
          k,
          f.id,
          0,
          f.cost * (0.1 + r * 0.1) * m,
          0,
          0,
          exp,
        );
      case DealKind.channelSponsor:
        o = BrandOffer(
          _newId('b'),
          brand,
          k,
          null,
          adIncomePerDay * (0.06 + r * 0.04) * m,
          0,
          30,
          0,
          exp,
        );
    }
    brandOffers.add(o);
    if (!execs.containsKey(ExecRole.pazarlama)) {
      _notify('📩 $brand seninle çalışmak istiyor: ${k.label}');
    }
  }

  String brandTargetName(BrandOffer o) {
    final t = o.targetId;
    if (t == null) return companyFullName;
    final s = showById(t);
    if (s != null) return s.name;
    final p = _anyPerson(t);
    if (p != null) return p.name;
    for (final f in films) {
      if (f.id == t) return f.name;
    }
    return '—';
  }

  String? acceptBrandOffer(BrandOffer o, {bool silent = false}) {
    if (!brandOffers.contains(o)) return 'Teklif bulunamadı.';
    switch (o.kind) {
      case DealKind.placement:
        final s = showById(o.targetId);
        if (s == null || s.status != ShowStatus.onAir || s.sponsorDays > 0) {
          brandOffers.remove(o);
          if (!silent) _changed();
          return 'Program artık uygun değil.';
        }
        _setSponsor(s, o.brand, o.perDay);
        s.sponsorDays = o.days;
      case DealKind.filmPlacement:
        Film? f;
        for (final x in films) {
          if (x.id == o.targetId) f = x;
        }
        if (f == null || f.status != FilmStatus.producing) {
          brandOffers.remove(o);
          if (!silent) _changed();
          return 'Film artık çekimde değil.';
        }
        _gain(o.lump);
        _acc?.sponsorIncome += o.lump;
        sponsorDeals++;
      case DealKind.starFace:
        if (o.targetId == null || _anyPerson(o.targetId!) == null) {
          brandOffers.remove(o);
          if (!silent) _changed();
          return 'Kişi artık kadroda değil.';
        }
        deals.add(Deal(o.brand, o.kind, o.targetId, o.perDay, o.days));
        sponsorDeals++;
      case DealKind.adBlock:
      case DealKind.channelSponsor:
        if (deals.any((d) => d.kind == o.kind)) {
          brandOffers.remove(o);
          if (!silent) _changed();
          return 'Bu türde bir anlaşma zaten sürüyor.';
        }
        deals.add(Deal(o.brand, o.kind, o.targetId, o.perDay, o.days));
        sponsorDeals++;
    }
    brandOffers.remove(o);
    _count('brand');
    if (!silent) {
      _notify('🤝 ${o.brand} ile ${o.kind.label} anlaşması imzalandı!');
      _changed();
    }
    return null;
  }

  void rejectBrandOffer(BrandOffer o) {
    brandOffers.remove(o);
    _changed();
  }

  // =================================================================
  // Günlük
  // =================================================================
  /// Belirli reklam süresiyle bu programın günlük net geliri (önizleme)
  double revenueWithAds(Show s, double m) {
    final slot = s.slot;
    if (slot == null) return 0;
    final rating = showRating(s, slot, m) * ratingMultFor(s.genre) * showExtraMult(s);
    final v = viewersFor(rating, slot, reach);
    return adRevenuePerDay(v, m, slot, adBonus) * adDemand * runShare(s);
  }

  /// Bu ay lisans verilebilecek platformlar
  List<PlatformDef> licensablePlatforms(Film f) => [
        for (final p in platformDefs)
          if (!ownedPlatforms.contains(p.id) &&
              !f.licenses.any((l) => l.platformId == p.id) &&
              f.score >= minScoreFor(p))
            p
      ];

  /// 12 ay boyunca her ay uygun tüm platformlara lisans verilirse toplam kazanç (tahmin)
  double licenseLifetime(Film f) {
    if (!f.rightsOwned || f.score <= 0) return 0;
    final eligible = platformDefs
        .where((p) => !ownedPlatforms.contains(p.id) && f.score >= minScoreFor(p))
        .toList();
    var sold = f.licensesSold;
    var total = 0.0;
    for (int month = 0; month < 12; month++) {
      for (final p in eligible) {
        final v = f.cost * pow(f.score / 5, 2.2) * 1.2 * pow(0.85, sold);
        total += v * 0.45 * p.payMult * f.def.streaming * (1 + licenseBonus);
        sold++;
      }
    }
    return total;
  }

  /// Uygun tüm platformlara tek seferde lisans ver
  String? licenseAll(Film f) {
    final ps = licensablePlatforms(f);
    if (ps.isEmpty) return 'Şu an lisans verilebilecek platform yok.';
    for (final p in ps) {
      final err = licenseFilm(f, p);
      if (err != null) return err;
    }
    return null;
  }

  // =================================================================
  // Sınırlı üretim lüks parçalar ve ikinci el pazar
  // =================================================================
  void _luxInit() {
    for (final d in luxuryDefs) {
      final e = d.edition;
      if (e == null) continue;
      // tek parça (ada) başta satışta; diğerlerinin bir kısmı satılmış
      luxSold[d.id] = e <= 1 ? 0 : (e * (0.3 + _rng.nextDouble() * 0.5)).round();
    }
  }

  int luxLeft(LuxuryDef d) => d.edition == null ? 1 << 30 : d.edition! - (luxSold[d.id] ?? 0);
  bool luxSoldOut(LuxuryDef d) => d.edition != null && luxLeft(d) <= 0;

  void _assignSerial(LuxuryDef d) {
    if (d.edition == null) return;
    final sold = luxSold[d.id] ?? 0;
    luxSerial[d.id] = min(d.edition!, sold + 1);
    luxSold[d.id] = min(d.edition!, sold + 1);
  }

  void _dropLux(String id) {
    luxSerial.remove(id);
    luxForSale.remove(id);
    luxOffers.removeWhere((o) => o.defId == id);
  }

  /// Koleksiyon değeri: tükenen ve düşük seri numaralı parçalar daha değerli
  double luxMarketValue(LuxuryDef d, int? serial) {
    var v = d.price * (luxSoldOut(d) ? 1.15 : 0.8);
    if (serial != null && serial <= 10) v *= 1.2;
    if (d.edition == 1) v = d.price * 1.1;
    return v;
  }

  String? buyLuxListing(LuxListing l) {
    final d = luxuryDefs.firstWhere((x) => x.id == l.defId);
    if (ownedLuxury.contains(d.id)) return 'Bu parçadan zaten var.';
    if (cash < l.price) return 'Kasada yeterli para yok.';
    cash -= l.price;
    luxListings.remove(l);
    ownedLuxury.add(d.id);
    luxSerial[d.id] = l.serial;
    _notify('✨ ${d.name} #${l.serial} artık senin! (${l.seller} sattı)');
    _changed();
    return null;
  }

  void toggleLuxSale(LuxuryDef d) {
    if (!ownedLuxury.contains(d.id)) return;
    if (!luxForSale.remove(d.id)) {
      luxForSale.add(d.id);
    } else {
      luxOffers.removeWhere((o) => o.defId == d.id);
    }
    _changed();
  }

  String? acceptLuxOffer(LuxOffer o) {
    if (!ownedLuxury.contains(o.defId) || o.expires < day) {
      luxOffers.remove(o);
      _changed();
      return 'Teklif artık geçerli değil.';
    }
    final d = luxuryDefs.firstWhere((x) => x.id == o.defId);
    ownedLuxury.remove(d.id);
    _dropLux(d.id);
    _cashIn(o.amount); // günlük gelir sayılmaz
    _notify('💰 ${d.name}, ${o.from} tarafından ${fmtShort(o.amount)} karşılığında alındı.');
    _changed();
    return null;
  }

  static const _collectors = [
    'Koleksiyoncu Rıfat', 'Galerici Nail', 'Kaptan Sinan', 'Mücevherci Leyla',
    'Turizmci Selim', 'Holdingci Necla', 'Antikacı Zafer', 'Pilot Derya',
  ];

  void _luxDaily() {
    // fabrikadan diğer zenginler de alıyor
    for (final d in luxuryDefs) {
      final e = d.edition;
      if (e == null || e <= 1 || luxSoldOut(d)) continue;
      if (_rng.nextDouble() < 0.5) {
        luxSold[d.id] = min(e, (luxSold[d.id] ?? 0) + 1 + _rng.nextInt(max(1, e ~/ 250)));
      }
    }
    // tükenen parçalar ikinci el pazarda (5 günde bir yenilenir)
    if (day % 5 == 0) {
      luxListings.clear();
      for (final d in luxuryDefs) {
        if (!luxSoldOut(d) || ownedLuxury.contains(d.id) || d.edition == 1) continue;
        final n = 1 + _rng.nextInt(2);
        for (int i = 0; i < n; i++) {
          final serial = 1 + _rng.nextInt(d.edition!);
          luxListings.add(LuxListing(d.id, serial,
              (luxMarketValue(d, serial) * (1.2 + _rng.nextDouble() * 0.35) / 1000).round() * 1000.0,
              _collectors[_rng.nextInt(_collectors.length)]));
        }
      }
    }
    // satıştaki parçalarına teklifler
    luxOffers.removeWhere((o) => o.expires < day || !ownedLuxury.contains(o.defId));
    for (final id in luxForSale) {
      if (_rng.nextDouble() > 0.5) continue;
      final d = luxuryDefs.firstWhere((x) => x.id == id);
      luxOffers.add(LuxOffer(id, _collectors[_rng.nextInt(_collectors.length)],
          (luxMarketValue(d, luxSerial[id]) * (0.85 + _rng.nextDouble() * 0.3) / 1000).round() * 1000.0,
          day + 3));
    }
  }

  void _v12Daily() {
    _luxDaily();
    // reklam talebi ortalamaya dönen rastgele yürüyüş
    adDemand = (adDemand + (1 - adDemand) * 0.2 + (_rng.nextDouble() - 0.5) * 0.12)
        .clamp(0.85, 1.2);
    _agencyDaily();
    _brandDaily();
    _execDaily();
    // yönetici adayları 5 günde bir değişir (sürekli değişmesin)
    if (day % 5 == 0) {
      _refreshExecCandidates();
    } else {
      _ensureExecCandidates();
    }
  }
}
