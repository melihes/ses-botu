part of 'game.dart';

/// 1.1: Takvim, mevsimler, özel günler ve özel bölümler.
extension GameCalendar on Game {
  // =================================================================
  // Kayıt
  // =================================================================
  Map<String, dynamic> _v13ToJson() => {
    'specials': specials,
    ..._socialToJson(),
    ..._dramaToJson(),
    ..._crisisToJson(),
  };

  void _v13Load(Map<String, dynamic> j) {
    specials
      ..clear()
      ..addAll(Map<String, String>.from((j['specials'] as Map?) ?? const {}));
    _socialLoad(j);
    _dramaLoad(j);
    _crisisLoad(j);
  }

  void _resetV13() {
    specials.clear();
    _socialReset();
    _dramaReset();
    _crisisReset();
  }

  void _v13Daily() {
    _calendarDaily();
    _socialDaily();
    _dramaDaily();
  }

  // =================================================================
  // Takvim
  // =================================================================
  String get dateText => dateLabel(day);
  int get calYear => dateOfDay(day).year;
  TvSeason get season => seasonOfDay(day);

  /// Mevsim etkisi
  double seasonMult(Genre g) => switch (season) {
    TvSeason.acilis => 1.06,
    TvSeason.kis => 1.04,
    TvSeason.bahar => 1.0,
    TvSeason.yaz => (g == Genre.spor || g == Genre.yarisma) ? 1.0 : 0.88,
  };

  /// Bu özel gün bu oyuncu için geçerli mi (dünya günleri o ülkede lokasyon ister)
  bool specialAvailable(SpecialDay d) =>
      !d.world || d.locations.any(ownedLocations.contains);

  /// Şu an süren özel günler (başlangıç günüyle)
  List<(SpecialDay, int)> get activeSpecialDays => [
    for (final d in specialDays)
      if (specialAvailable(d) && d.activeStart(day) != null) (d, d.activeStart(day)!),
  ];

  /// Yaklaşan (ve süren) özel günler, en yakından uzağa
  List<(SpecialDay, int)> upcomingSpecialDays({int within = 400, bool all = false}) {
    final l = <(SpecialDay, int)>[
      for (final d in specialDays)
        if (all || specialAvailable(d)) (d, d.nextStart(day)),
    ]..removeWhere((e) => e.$2 - day > within);
    l.sort((a, b) => a.$2.compareTo(b.$2));
    return l;
  }

  String specialKey(SpecialDay d, int start) => '${d.id}@$start';

  double specialBoost(SpecialDay d) => d.length >= 10 ? 0.15 : (d.world ? 0.25 : 0.35);

  /// Takvimin programa etkisi: mevsim × bayram/özel gün × özel bölüm
  double calendarMult(Show s) {
    var m = seasonMult(s.genre);
    for (final (d, start) in activeSpecialDays) {
      if (!d.world) {
        m *= d.audience;
        if (d.genres.contains(s.genre)) m *= 1 + d.tvBonus;
      }
      if (specials[s.id] == specialKey(d, start)) m *= 1 + specialBoost(d);
    }
    return m;
  }

  /// Bayramlarda sinema: gişe artışı
  double filmCalendarBonus(FilmGenre g) {
    var b = 0.0;
    for (final (d, _) in activeSpecialDays) {
      if (d.allFilms || d.films.contains(g)) b += d.filmBonus;
    }
    return b;
  }

  /// Özel bölüm hazırlanabilir mi? (10 gün öncesinden bitişe kadar)
  bool specialWindowOpen(SpecialDay d, int start) =>
      day >= start - 10 && day < start + d.length;

  double specialCost(Show s, SpecialDay d) =>
      productionCost(s.genre, s.tier) * (d.world ? 0.5 : 0.3) * (d.length >= 10 ? 1.5 : 1);

  /// Bu özel gün için uygun programlar
  List<Show> specialCandidates(SpecialDay d) => shows
      .where((s) =>
          (s.status == ShowStatus.onAir || s.status == ShowStatus.producing) &&
          d.genres.contains(s.genre))
      .toList();

  String? prepareSpecial(Show s, SpecialDay d) {
    final start = d.nextStart(day);
    if (!specialAvailable(d)) {
      return 'Bu özel gün için o ülkede bir çekim lokasyonun olmalı.';
    }
    if (!specialWindowOpen(d, start)) return 'Özel bölüm en erken 10 gün önce hazırlanabilir.';
    if (!d.genres.contains(s.genre)) return 'Bu tür bu özel güne uygun değil.';
    final key = specialKey(d, start);
    if (specials[s.id] == key) return 'Bu program için özel bölüm zaten hazır.';
    final c = specialCost(s, d);
    if (cash < c) return 'Özel bölüm için ${fmtShort(c)} gerekli.';
    cash -= c;
    specials[s.id] = key;
    _count('special');
    _notify('${d.emoji} "${s.name}" için "${d.special}" hazırlanıyor!');
    // gün zaten başladıysa ödeme hemen
    if (day >= start) _paySpecial(s, d);
    _changed();
    return null;
  }

  void _paySpecial(Show s, SpecialDay d) {
    final lump = specialCost(s, d) * (d.world ? 1.5 : 0.9);
    _gain(lump);
    bonusPrestige += d.world ? 8 : 4;
    _event(
      '${d.emoji} ${d.special} yayında!',
      '"${s.name}" ${d.world ? 'yurt dışına satıldı' : 'sponsorları kaptı'}: +${fmtShort(lump)}, '
          'reyting +%${(specialBoost(d) * 100).round()} (${d.length} gün)',
      true,
    );
    _post(SocialTopic.special, show: s, extra: d.special);
  }

  void _calendarDaily() {
    // biten özel bölüm kayıtlarını temizle
    specials.removeWhere((id, key) {
      final parts = key.split('@');
      final d = specialDayById(parts.first);
      final start = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
      return d == null || day >= start + d.length || showById(id) == null;
    });
    for (final d in specialDays) {
      if (!specialAvailable(d)) continue;
      final start = d.nextStart(day);
      if (start - day == 7) {
        _log('${d.emoji} ${d.name} yaklaşıyor', '7 gün kaldı. ${d.special} hazırlayabilirsin.', true);
        _notify('${d.emoji} ${d.name} 7 gün sonra! Takvimden özel bölüm hazırla.');
      }
      if (start == day) {
        _event('${d.emoji} ${d.name} başladı', d.desc, true);
        for (final s in shows) {
          if (specials[s.id] == specialKey(d, start)) _paySpecial(s, d);
        }
      }
    }
    final d = dateOfDay(day);
    if (d.doy == 0 && day > 1) {
      _event('🍂 Yeni sezon açıldı', '${d.year}. yayın yılı başladı. İzleyici ekran başında: +%6.', true);
    }
    if (d.month == 6 && d.dom == 1) {
      _log('☀️ Yaz sezonu', 'Tatil başladı: izleyici %12 azalır (spor ve yarışma hariç).', false);
    }
  }
}
