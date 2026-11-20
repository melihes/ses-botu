// Kaos testi: rastgele oyuncu hareketleriyle oyunun tutarlılığını sınar.
import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/data/content2.dart';
import 'package:reyting/engine/economy.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oyunun her an sağlaması gereken kurallar
List<String> invariants(Game g) {
  final e = <String>[];
  bool bad(num v) => v.isNaN || v.isInfinite;
  if (bad(g.cash)) e.add('kasa bozuk: ${g.cash}');
  if (bad(g.netWorth)) e.add('şirket değeri bozuk');
  if (bad(g.netPerDay)) e.add('günlük net bozuk');
  if (g.dayProgress < 0 || g.dayProgress > 1) e.add('gün ilerlemesi ${g.dayProgress}');
  final ids = <String>{};
  for (final s in g.staff) {
    if (!ids.add(s.id)) e.add('aynı kişi iki kez kadroda: ${s.id}');
    if (s.showId != null) {
      final show = g.showById(s.showId);
      final film = g.films.where((f) => f.id == s.showId).firstOrNull;
      final tender = g.tenders.where((t) => t.id == s.showId).firstOrNull;
      if (show == null && film == null && tender == null) e.add('${s.name} olmayan bir işe bağlı');
      if (tender != null && !(tender.status == TenderStatus.open || tender.status == TenderStatus.producing)) {
        e.add('${s.name} bitmiş ihaleye bağlı (${tender.status})');
      }
      if (show != null &&
          !(show.status == ShowStatus.producing || show.status == ShowStatus.ready || show.status == ShowStatus.onAir)) {
        e.add('${s.name} bitmiş programa bağlı (${show.status})');
      }
      if (film != null && film.status != FilmStatus.producing) e.add('${s.name} bitmiş filme bağlı');
    }
  }
  for (final s in g.shows) {
    if (bad(s.quality) || bad(s.totalRevenue)) e.add('program sayıları bozuk: ${s.name}');
    if (s.status == ShowStatus.onAir) {
      if (s.slot == null) {
        e.add('yayındaki programın kuşağı yok: ${s.name}');
      } else if (g.slots[s.slot]!.showId != s.id) {
        e.add('kuşak/program uyumsuz: ${s.name}');
      }
    } else if (s.slot != null) {
      e.add('yayında olmayan program kuşakta: ${s.name} ${s.status}');
    }
    if (g.currentRating(s) < 0 || bad(g.currentRating(s))) e.add('reyting bozuk: ${s.name}');
  }
  for (final entry in g.slots.entries) {
    final id = entry.value.showId;
    if (id != null) {
      final s = g.showById(id);
      if (s == null) {
        e.add('kuşakta olmayan program: ${entry.key}');
      } else if (s.status != ShowStatus.onAir) {
        e.add('kuşaktaki program yayında değil');
      }
    }
    if (entry.value.adMinutes < 0 || entry.value.adMinutes > 24) e.add('reklam süresi aralık dışı');
  }
  if (g.staff.length > g.studio.maxStaff) e.add('kadro sınırı aşıldı ${g.staff.length}/${g.studio.maxStaff}');
  if (g.creators.length > g.maxCreators) e.add('YouTuber sınırı aşıldı');
  for (final h in g.holdings.entries) {
    if (h.value < 1) e.add('sıfır hisse kaydı: ${h.key}');
    final d = stockDefs.firstWhere((d) => d.ticker == h.key);
    if (h.value > d.shares * 0.25 + 1) e.add('hisse sınırı aşıldı: ${h.key}');
  }
  for (final p in g.stockPrices.values) {
    if (bad(p) || p <= 0) e.add('hisse fiyatı bozuk: $p');
  }
  for (final l in g.loans) {
    if (l.installmentsLeft <= 0) e.add('bitmiş kredi listede');
  }
  if (g.diamonds < 0) e.add('elmas eksi: ${g.diamonds}');
  if (g.academy.length > g.agency.academySlots) e.add('akademi sınırı aşıldı');
  for (final o in g.transferOffers) {
    if (g.personById(o.staffId) == null) e.add('sahipsiz transfer teklifi');
  }
  for (final d in g.deals) {
    if (d.daysLeft <= 0 || bad(d.perDay) || d.perDay < 0) e.add('bozuk anlaşma');
  }
  for (final s in g.shows) {
    if (s.budget < 0 || s.budget >= prodBudgets.length) e.add('bozuk bütçe');
    if (s.guest < 0 || s.guest >= guestTiers.length) e.add('bozuk konuk');
    if (bad(s.quality) || s.quality > 1.8) e.add('kalite aralık dışı ${s.quality}');
  }
  for (final p in [...g.staff, ...g.academy]) {
    if (p.fame < 0 || p.fame > 100 || bad(p.fame)) e.add('şöhret bozuk');
    if (p.skill > 99 || p.skill < 1) e.add('yetenek aralık dışı');
  }
  if (bad(g.netWorth)) e.add('servet bozuk');
  return e;
}

Future<void> chaos(int seed, int steps) async {
  SharedPreferences.setMockInitialValues({});
  final r = Random(seed);
  var g = Game();
  await g.start();
  g.introSeen = true;
  T pick<T>(List<T> l) => l[r.nextInt(l.length)];
  final log = <String>[];
  for (int i = 0; i < steps; i++) {
    final a = r.nextInt(38);
    String act = 'a$a';
    try {
      switch (a) {
        case 0 || 1 || 2:
          if (g.market.isNotEmpty) { act = 'işe al'; g.hire(pick(g.market)); }
        case 3:
          if (g.staff.isNotEmpty) { act = 'çıkar'; g.fire(pick(g.staff)); }
        case 4 || 5 || 6:
          act = 'program';
          final genre = pick(Genre.values);
          final tier = r.nextInt(genreFormats[genre]!.length);
          final crew = <Staff>[];
          genreDefs[genre]!.needs.forEach((role, n) => crew.addAll(g.freeStaff(role).take(n)));
          g.createShow('S$i', genre, tier, crew);
        case 7:
          final p = g.shows.where((s) => s.status == ShowStatus.producing).toList();
          if (p.isNotEmpty) { act = 'hızlandır'; g.speedUp(pick(p)); }
        case 8 || 9:
          final ready = g.shows.where((s) => s.status == ShowStatus.ready).toList();
          if (ready.isNotEmpty) { act = 'yayına koy'; g.putOnAir(pick(ready), pick(SlotId.values)); }
        case 10:
          act = 'yayından kaldır'; g.takeOffAir(pick(SlotId.values));
        case 11:
          act = 'reklam'; g.setAdMinutes(pick(SlotId.values), r.nextInt(25).toDouble());
        case 12:
          final ended = g.shows.where((s) => s.status == ShowStatus.ended).toList();
          if (ended.isNotEmpty) { act = r.nextBool() ? 'yeni sezon' : 'arşiv'; final s = pick(ended); act == 'arşiv' ? g.deleteShow(s) : g.renewShow(s); }
        case 13:
          act = 'stüdyo'; g.upgradeStudio();
        case 14:
          act = 'ekipman'; g.buyEquip(pick(equipDefs));
        case 15:
          act = 'kredi'; g.takeLoan(pick(loanOffersFor(g.studioLevel)));
        case 16:
          if (g.loans.isNotEmpty) { act = 'kredi kapat'; g.payOffLoan(pick(g.loans)); }
        case 17:
          act = 'lüks'; final d = pick(luxuryDefs);
          if (d.negotiable) {
            final res = g.negotiate(d.id, d.price, d.price * (0.5 + r.nextDouble() * 0.5));
            if (res.outcome == NegOutcome.accepted) g.completePurchase(d.id, res.price!);
          } else {
            g.buyFixed(d);
          }
        case 18:
          if (g.ownedLuxury.isNotEmpty) { act = 'lüks sat'; g.sellLuxury(luxuryDefs.firstWhere((d) => d.id == g.ownedLuxury.first)); }
        case 19:
          act = 'film';
          final fg = pick(FilmGenre.values);
          final crew = <Staff>[];
          filmGenreDefs[fg]!.needs.forEach((role, n) => crew.addAll(g.freeStaff(role).take(n)));
          g.createFilm('F$i', fg, r.nextInt(3), crew);
        case 20:
          final f = g.films.where((f) => f.status == FilmStatus.producing).toList();
          if (f.isNotEmpty) { act = 'film hızlandır'; g.speedUpFilm(pick(f)); }
        case 21:
          if (g.films.isNotEmpty) {
            final f = pick(g.films);
            final k = r.nextInt(4);
            act = 'film işlem $k';
            if (k == 0) g.releaseInTheaters(f);
            if (k == 1) g.licenseFilm(f, pick(platformDefs));
            if (k == 2) g.sellRights(f);
            if (k == 3) g.toggleOwnPlatform(f);
          }
        case 22:
          act = 'işletme'; g.upgradeBiz(pick(bizDefs));
        case 23:
          if (g.creatorMarket.isNotEmpty) { act = 'youtuber'; g.signCreator(pick(g.creatorMarket)); }
        case 24:
          if (g.creators.isNotEmpty) { act = r.nextBool() ? 'kampanya' : 'youtuber bırak'; final c = pick(g.creators); act == 'kampanya' ? g.runCampaign(c) : g.releaseCreator(c); }
        case 25:
          final t = pick(stockDefs).ticker;
          act = 'borsa';
          if (r.nextBool()) { g.buyStock(t, g.maxBuyable(t) * r.nextDouble()); } else { g.sellStock(t, (g.holdings[t] ?? 0) * r.nextDouble() + 1); }
        case 26:
          if (g.pendingDecision != null) { act = 'karar'; g.resolveDecision(r.nextInt(g.pendingDecision!.options.length)); }
        case 29:
          final k = r.nextInt(4);
          act = 'müdür/eğitim/görev $k';
          if (k == 0) g.autoManager ? g.fireManager() : g.hireManager();
          if (k == 1 && g.staff.isNotEmpty) g.trainStaff(pick(g.staff));
          if (k == 2 && g.missions.isNotEmpty) g.claimMission(pick(g.missions));
          if (k == 3) g.dismissLogin();
        case 27:
          act = 'kanal'; final c = pick(channelDefs);
          if (g.ownedChannels.contains(c.id)) { g.sellChannel(c); } else if (g.cash > c.price) { g.completePurchase(c.id, c.price); }
        case 28:
          act = 'kaydet/yükle';
          await g.save();
          final before = jsonEncode(invariants(g));
          final cash = g.cash, day = g.day, staff = g.staff.length, shows = g.shows.length;
          g.dispose();
          g = Game();
          await g.start();
          expect(g.cash, closeTo(cash, 1), reason: 'yükleme sonrası kasa');
          expect(g.day, day);
          expect(g.staff.length, staff);
          expect(g.shows.length, shows);
          expect(jsonEncode(invariants(g)), before);
        case 31:
          final open = g.tenders.where((t) => t.status == TenderStatus.open && t.myBid == null).toList();
          if (open.isNotEmpty) {
            act = 'ihale';
            final t = pick(open);
            final crew = <Staff>[];
            t.def.crew.forEach((role, n) => crew.addAll(g.freeStaff(role).take(n)));
            g.bidTender(t, t.budget * (0.5 + r.nextDouble() * 0.7), crew);
          }
        case 32:
          act = 'premium program';
          final genre = pick(Genre.values);
          final tier = r.nextInt(genreFormats[genre]!.length);
          final crew = <Staff>[];
          genreDefs[genre]!.needs.forEach((role, n) => crew.addAll(g.freeStaff(role).take(n)));
          final locs = g.ownedLocations.toList();
          g.createShow('P$i', genre, tier, crew,
              budget: r.nextInt(prodBudgets.length),
              guest: r.nextInt(guestTiers.length),
              location: locs.isEmpty || r.nextBool() ? null : pick(locs));
        case 33:
          final l = pick(locationDefs);
          act = 'lokasyon';
          if (r.nextBool()) { g.buyLocation(l); } else { g.holdEvent(l); }
        case 34:
          final k = r.nextInt(9);
          act = 'ajans $k';
          final mine = [...g.staff, ...g.academy];
          if (k == 0) g.upgradeAgency();
          if (k == 1 && g.youthMarket.isNotEmpty) g.signYouth(pick(g.youthMarket));
          if (k == 2 && g.academy.isNotEmpty) g.promoteYouth(pick(g.academy));
          if (k == 3 && mine.isNotEmpty) g.toggleForSale(pick(mine));
          if (k == 4 && g.transferOffers.isNotEmpty) g.acceptTransfer(pick(g.transferOffers));
          if (k == 5 && mine.isNotEmpty) g.quickSell(pick(mine));
          if (k == 6 && g.transferMarket.isNotEmpty) g.buyTransfer(pick(g.transferMarket));
          if (k == 7 && mine.isNotEmpty) g.promoteFame(pick(mine));
          if (k == 8) g.sendScout();
        case 35:
          act = 'yönetici';
          if (r.nextInt(3) == 0 && g.execs.isNotEmpty) {
            g.fireExec(pick(g.execs.keys.toList()));
          } else if (g.execCandidates.isNotEmpty) {
            g.hireExec(pick(g.execCandidates));
          }
        case 36:
          if (g.brandOffers.isNotEmpty) {
            act = 'marka';
            final o = pick(g.brandOffers);
            r.nextBool() ? g.acceptBrandOffer(o) : g.rejectBrandOffer(o);
          }
        case 37:
          final live = g.shows.where((s) => s.status != ShowStatus.ended).toList();
          if (live.isNotEmpty) {
            act = 'bütçe/konuk yükselt';
            final s = pick(live);
            r.nextBool() ? g.upgradeShowBudget(s) : g.upgradeShowGuest(s);
          }
        case 30:
          act = 'uzaklaş';
          g.debugAway(Duration(minutes: r.nextInt(600)));
          g.pendingOffline = null;
        default:
          act = 'zaman';
          g.debugAdvanceDays(r.nextDouble() * 3);
      }
    } catch (e, st) {
      fail('Çöktü: adım $i "$act": $e\n$st\nSon hareketler: ${log.reversed.take(8).toList()}');
    }
    log.add(act);
    if (g.cash < 1e5 && r.nextInt(10) == 0) g.cash += 5e6; // oyunu canlı tut
    final errs = invariants(g);
    if (errs.isNotEmpty) {
      fail('Tutarsızlık: adım $i "$act" sonrası: $errs\nSon hareketler: ${log.reversed.take(10).toList()}');
    }
  }
  // ignore: avoid_print
  print('tohum $seed: gün ${g.day}, stüdyo ${g.studioLevel + 1}, kadro ${g.staff.length}, '
      'program ${g.shows.length} (yayında ${g.shows.where((s) => s.status == ShowStatus.onAir).length}), '
      'film ${g.films.length}, youtuber ${g.creators.length}, hisse ${g.holdings.length}, '
      'lüks ${g.ownedLuxury.length}, kanal ${g.ownedChannels.length}, kredi ${g.loans.length}, '
      'karar ${g.decisionsMade}, kupa ${g.trophies.length}');
  g.dispose();
}

void main() {
  for (int seed = 1; seed <= 12; seed++) {
    test('kaos testi (tohum $seed)', () => chaos(seed, 6000),
        timeout: const Timeout(Duration(minutes: 3)));
  }
}
