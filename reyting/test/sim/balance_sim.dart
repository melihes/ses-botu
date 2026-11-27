// Ekonomi dengesi simülasyonu: makul oynayan bir bot ile oyunu ileri sarar.
// Çalıştırma: flutter test test/sim/balance_sim.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/format.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/data/cities.dart';
import 'package:reyting/data/content2.dart';
import 'package:reyting/engine/economy.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bestGenreByBand = {
  Band.sabah: [Genre.cocuk, Genre.talkShow, Genre.haber],
  Band.ogle: [Genre.magazin, Genre.cocuk],
  Band.aksam: [Genre.haber, Genre.yarisma],
  Band.prime: [Genre.dizi, Genre.yarisma, Genre.spor],
  Band.gece: [Genre.talkShow, Genre.magazin],
};
List<Genre> bestGenreFor(SlotId s) => bestGenreByBand[slotDefs[s]!.band]!;

double burn(Game g) =>
    g.dailySalaries + g.dailyRent + g.dailyUpkeep + g.creatorSalaries;

bool ensureCrew(Game g, Genre genre, List<Staff> out) {
  final def = genreDefs[genre]!;
  out.clear();
  for (final e in def.needs.entries) {
    for (int k = 0; k < e.value; k++) {
      var free = g.freeStaff(e.key).where((p) => !out.contains(p)).toList();
      if (free.isEmpty) {
        final cands = g.market.where((p) => p.role == e.key).toList()
          ..sort((a, b) => (b.skill / b.salary).compareTo(a.skill / a.salary));
        if (cands.isEmpty) return false;
        if (g.cash - cands.first.signingFee < burn(g) * 3) return false;
        if (g.hire(cands.first) != null) return false;
        free = [cands.first];
      }
      free.sort((a, b) => b.skill.compareTo(a.skill));
      out.add(free.first);
    }
  }
  return true;
}

bool naive = false;
bool useV12 = const bool.fromEnvironment('V12', defaultValue: true);
const v12Parts = String.fromEnvironment('PARTS', defaultValue: 'bmel');
bool part(String c) => useV12 && v12Parts.contains(c);
final _r = Random(3);

void botDay(Game g) {
  // reklam ayarı: en iyi nokta
  for (final s in g.shows.where((s) => s.status == ShowStatus.onAir)) {
    if (naive) continue;
    g.setAdMinutes(
      s.slot!,
      adTolerance(s.quality).roundToDouble().clamp(0, 24),
    );
  }
  // hazır programları en uygun boş kuşağa koy (özensiz: ilk boş kuşağa)
  for (final s in g.shows.where((s) => s.status == ShowStatus.ready).toList()) {
    final free = SlotId.values
        .where((id) => g.slotUnlocked(id) && g.slots[id]!.showId == null)
        .toList();
    if (free.isEmpty) continue;
    if (!naive) {
      free.sort(
        (a, b) =>
            (g.previewRating(s, b) *
                    slotDefs[b]!.poolMillions *
                    slotDefs[b]!.adValue)
                .compareTo(
                  g.previewRating(s, a) *
                      slotDefs[a]!.poolMillions *
                      slotDefs[a]!.adValue,
                ),
      );
    }
    g.putOnAir(s, free.first);
  }
  // en verimli yerleşim: kazancı artıran bir taşıma/yer değiştirme varsa yap
  if (!naive) {
    double v(Show s, SlotId id) =>
        g.previewRating(s, id) *
        slotDefs[id]!.poolMillions *
        slotDefs[id]!.adValue;
    for (final s
        in g.shows.where((s) => s.status == ShowStatus.onAir).toList()) {
      final from = s.slot!;
      SlotId? best;
      var bestGain = 0.0;
      for (final to in SlotId.values) {
        if (to == from || !g.slotUnlocked(to)) continue;
        final other = g.showById(g.slots[to]!.showId);
        final gain =
            v(s, to) -
            v(s, from) +
            (other == null ? 0 : v(other, from) - v(other, to));
        if (gain > bestGain * 1.0 + 1e-9) {
          bestGain = gain;
          best = to;
        }
      }
      if (best != null) g.moveShow(s, best);
    }
  }
  // boş kuşaklar için yapım
  for (final slot in SlotId.values) {
    if (!g.slotUnlocked(slot) || g.slots[slot]!.showId != null) continue;
    final pending = g.shows
        .where(
          (s) =>
              s.status == ShowStatus.producing || s.status == ShowStatus.ready,
        )
        .length;
    final emptySlots = SlotId.values
        .where((id) => g.slotUnlocked(id) && g.slots[id]!.showId == null)
        .length;
    if (pending >= emptySlots) continue;
    // biten programın yeni sezonu
    final ended = g.shows.where((s) => s.status == ShowStatus.ended).toList();
    var done = false;
    for (final s in ended) {
      if (s.season >= 3) continue;
      if (g.cash - productionCost(s.genre, s.tier) > burn(g) * 4 &&
          g.renewShow(s) == null) {
        done = true;
        break;
      }
    }
    if (done) continue;
    final genres = naive
        ? (Genre.values.toList()..shuffle(_r))
        : bestGenreFor(slot);
    for (final genre in genres) {
      if (!g.genreUnlocked(genre)) continue;
      var tier = 0;
      for (int t = genreFormats[genre]!.length - 1; t >= 0; t--) {
        if (g.formatUnlocked(genre, t) &&
            g.cash - productionCost(genre, t) > burn(g) * 4 + 200000) {
          tier = t;
          break;
        }
      }
      final crew = <Staff>[];
      if (!ensureCrew(g, genre, crew)) continue;
      var budget = 1, guest = 0;
      if (!naive && part('b')) {
        for (int b = prodBudgets.length - 1; b >= 1; b--) {
          if (g.budgetUnlocked(b) &&
              g.cash - g.showCost(genre, tier, b, 0, null) >
                  burn(g) * 6 + 200000) {
            budget = b;
            break;
          }
        }
        for (int q = guestTiers.length - 1; q >= 0; q--) {
          if (g.guestUnlocked(q) &&
              g.cash - g.showCost(genre, tier, budget, q, null) >
                  burn(g) * 6 + 200000) {
            guest = q;
            break;
          }
        }
      }
      String? loc;
      if (!naive && part('l')) {
        for (final l in locationDefs) {
          if (g.ownedLocations.contains(l.id) && g.locationFits(l, genre))
            loc = l.id;
        }
      }
      if (g.createShow(
            'Bot',
            genre,
            tier,
            crew,
            budget: budget,
            guest: guest,
            location: loc,
          ) ==
          null)
        break;
    }
  }
  // kadroyu güçlendir: daha iyi aday varsa al, en zayıf boştakini çıkar
  if (!naive && g.day % 3 == 0 && g.cash > burn(g) * 20) {
    for (final r in Role.values) {
      final mine = g.staff.where((p) => p.role == r).toList();
      if (mine.isEmpty) continue;
      final weakest = mine.reduce((a, b) => a.skill < b.skill ? a : b);
      final cands = g.market
          .where((p) => p.role == r && p.skill > weakest.skill + 15)
          .toList();
      if (cands.isEmpty) continue;
      final best = cands.reduce((a, b) => a.skill > b.skill ? a : b);
      if (g.staff.length >= g.studio.maxStaff) {
        if (weakest.showId != null) continue;
        g.fire(weakest);
      }
      g.hire(best);
    }
  }
  // holding
  for (final b in bizDefs) {
    final lv = g.bizLevel(b.id);
    if (lv < bizMaxLevel && g.cash > bizUpgradeCost(b, lv) * 5) g.upgradeBiz(b);
  }
  // Genel Müdür
  if (!naive && !g.autoManager && g.cash > g.managerSigningFee * 4)
    g.hireManager();
  // devlet ihaleleri: uygunsa bedelin %88'iyle teklif
  if (!naive) {
    for (final t
        in g.tenders
            .where((t) => t.status == TenderStatus.open && t.myBid == null)
            .toList()) {
      if (g.tenderEligible(t) != null) continue;
      final crew = <Staff>[];
      t.def.crew.forEach((role, n) => crew.addAll(g.freeStaff(role).take(n)));
      if (g.cash > t.productionCost * 3) g.bidTender(t, t.budget * 0.88, crew);
    }
  }
  // günlük görev ödülleri
  for (final m in g.missions) {
    if (m.done && !m.claimed) g.claimMission(m);
  }
  // stüdyo yükselt
  if (g.studioLevel < studioLevels.length - 1) {
    final next = studioLevels[g.studioLevel + 1];
    if (g.cash > next.upgradeCost + burn(g) * 8) g.upgradeStudio();
  }
  // ekipman
  for (final e in equipDefs) {
    if (!g.ownedEquip.contains(e.id) && g.cash > e.price * 4) g.buyEquip(e);
  }
  // YouTuber
  if (g.creators.length < g.maxCreators && g.creatorMarket.isNotEmpty) {
    final c = g.creatorMarket.reduce(
      (a, b) => a.revenuePerDay - a.salary > b.revenuePerDay - b.salary ? a : b,
    );
    if (c.revenuePerDay > c.salary && g.cash > c.signingFee * 6)
      g.signCreator(c);
  }
  if (!naive && useV12) {
    // markalar
    if (part('m')) {
      for (final o in g.brandOffers.toList()) {
        g.acceptBrandOffer(o);
      }
    }
    // yönetim kurulu: kârlıysa en iyi adayı al
    final net = g.netPerDay;
    for (final e
        in g.execCandidates.toList()
          ..sort((a, b) => b.skill.compareTo(a.skill))) {
      final cur = g.execs[e.role];
      if (!part('e')) break;
      if (cur != null && cur.skill >= e.skill) continue;
      if (e.salary < net * 0.04 && g.cash > e.signingFee * 6) g.hireExec(e);
    }
    // şehirler: büyükten küçüğe, kârlıysa
    if (part('l')) {
      final cs = cityDefs.where((c) => !g.openedCities.contains(c.plate)).toList()
        ..sort((a, b) => b.weight.compareTo(a.weight));
      for (final c in cs) {
        if (g.cash > c.price * 6 + burn(g) * 4) g.openCity(c);
      }
    }
    // lokasyonlar
    for (final l in locationDefs) {
      if (!part('l')) break;
      if (!g.ownedLocations.contains(l.id) &&
          g.locationLockReason(l) == null &&
          g.cash > l.price * 6 &&
          l.upkeep < net * 0.02) {
        g.buyLocation(l);
      }
      if (g.ownedLocations.contains(l.id) &&
          l.event != null &&
          g.cash > g.eventCost(l) * 4) {
        g.holdEvent(l);
      }
    }
  }
  // kararları nötr çöz
  if (g.pendingDecision != null) g.resolveDecision(0);
  g.pendingAwards = null;
}

Future<Map<int, int>> runOnce(
  bool isNaive,
  StringBuffer report, {
  bool log = false,
}) async {
  naive = isNaive;
  SharedPreferences.setMockInitialValues({});
  final g = Game();
  await g.start();
  g.introSeen = true;
  final m = <int, int>{};
  for (int d = 1; d <= 300; d++) {
    botDay(g);
    g.debugAdvanceDays(1);
    final lv = g.studioLevel + 1;
    if (!m.containsKey(lv)) m[lv] = d;
    if (log && [10, 20, 30, 45, 60, 90, 120, 200, 300].contains(d)) {
      final on = g.shows.where((s) => s.status == ShowStatus.onAir).toList();
      report.writeln(
        '${isNaive ? "ÖZENSİZ" : "AKILLI "} Gün ${d.toString().padLeft(3)}: kasa ${fmtShort(g.cash).padLeft(10)} '
        '· net/gün ${fmtShort(g.netPerDay).padLeft(9)} · stüdyo $lv · ort reyting '
        '${fmtDec(on.fold(0.0, (a, s) => a + g.currentRating(s)) / max(1, on.length), 2)} · değer ${fmtShort(g.netWorth)}',
      );
    }
  }
  g.dispose();
  return m;
}

void main() {
  test('denge simülasyonu', () async {
    final report = StringBuffer();
    for (final nv in [false, true]) {
      final all = <Map<int, int>>[];
      for (int run = 0; run < 3; run++) {
        all.add(await runOnce(nv, report, log: run == 0));
      }
      report.writeln(
        '${nv ? "ÖZENSİZ" : "AKILLI "} seviye günleri: ${all.map((m) => m.toString()).join("  ")}',
      );
    }
    // ignore: avoid_print
    print(report);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
