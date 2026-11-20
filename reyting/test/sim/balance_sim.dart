// Ekonomi dengesi simülasyonu: makul oynayan bir bot ile oyunu ileri sarar.
// Çalıştırma: flutter test test/sim/balance_sim.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/format.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/engine/economy.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

const bestGenre = {
  SlotId.gunduz: [Genre.magazin, Genre.cocuk],
  SlotId.aksam: [Genre.haber, Genre.yarisma],
  SlotId.prime: [Genre.dizi, Genre.yarisma],
  SlotId.gece: [Genre.talkShow, Genre.magazin],
};

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
final _r = Random(3);

void botDay(Game g) {
  // reklam ayarı: en iyi nokta
  for (final s in g.shows.where((s) => s.status == ShowStatus.onAir)) {
    if (naive) continue;
    g.setAdMinutes(s.slot!, adTolerance(s.quality).roundToDouble().clamp(0, 24));
  }
  // hazır programları yayına koy
  for (final s in g.shows.where((s) => s.status == ShowStatus.ready).toList()) {
    final slot = SlotId.values.firstWhere(
        (id) => g.slotUnlocked(id) && g.slots[id]!.showId == null,
        orElse: () => SlotId.gece);
    if (g.slotUnlocked(slot) && g.slots[slot]!.showId == null) g.putOnAir(s, slot);
  }
  // boş kuşaklar için yapım
  for (final slot in SlotId.values) {
    if (!g.slotUnlocked(slot) || g.slots[slot]!.showId != null) continue;
    final pending = g.shows.where((s) =>
        s.status == ShowStatus.producing || s.status == ShowStatus.ready).length;
    final emptySlots = SlotId.values
        .where((id) => g.slotUnlocked(id) && g.slots[id]!.showId == null)
        .length;
    if (pending >= emptySlots) continue;
    // biten programın yeni sezonu
    final ended = g.shows.where((s) => s.status == ShowStatus.ended).toList();
    var done = false;
    for (final s in ended) {
      if (s.season >= 3) continue;
      if (g.cash - productionCost(s.genre, s.tier) > burn(g) * 4 && g.renewShow(s) == null) {
        done = true;
        break;
      }
    }
    if (done) continue;
    final genres = naive
        ? (Genre.values.toList()..shuffle(_r))
        : bestGenre[slot]!;
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
      if (g.createShow('Bot', genre, tier, crew) == null) break;
    }
  }
  // kadroyu güçlendir: daha iyi aday varsa al, en zayıf boştakini çıkar
  if (!naive && g.day % 3 == 0 && g.cash > burn(g) * 20) {
    for (final r in Role.values) {
      final mine = g.staff.where((p) => p.role == r).toList();
      if (mine.isEmpty) continue;
      final weakest = mine.reduce((a, b) => a.skill < b.skill ? a : b);
      final cands = g.market.where((p) => p.role == r && p.skill > weakest.skill + 15).toList();
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
    final c = g.creatorMarket.reduce((a, b) =>
        a.revenuePerDay - a.salary > b.revenuePerDay - b.salary ? a : b);
    if (c.revenuePerDay > c.salary && g.cash > c.signingFee * 6) g.signCreator(c);
  }
  // kararları nötr çöz
  if (g.pendingDecision != null) g.resolveDecision(0);
  g.pendingAwards = null;
}

Future<Map<int, int>> runOnce(bool isNaive, StringBuffer report, {bool log = false}) async {
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
    if (log && [10, 30, 60, 120, 200, 300].contains(d)) {
      final on = g.shows.where((s) => s.status == ShowStatus.onAir).toList();
      report.writeln('${isNaive ? "ÖZENSİZ" : "AKILLI "} Gün ${d.toString().padLeft(3)}: kasa ${fmtShort(g.cash).padLeft(10)} '
          '· net/gün ${fmtShort(g.netPerDay).padLeft(9)} · stüdyo $lv · ort reyting '
          '${fmtDec(on.fold(0.0, (a, s) => a + g.currentRating(s)) / max(1, on.length), 2)} · değer ${fmtShort(g.netWorth)}');
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
      report.writeln('${nv ? "ÖZENSİZ" : "AKILLI "} seviye günleri: ${all.map((m) => m.toString()).join("  ")}');
    }
    // ignore: avoid_print
    print(report);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
