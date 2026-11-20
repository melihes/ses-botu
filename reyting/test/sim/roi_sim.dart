// Bütçe ve konuk seçeneklerinin sezonluk kârlılığı
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/format.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/data/content2.dart';
import 'package:reyting/engine/economy.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ROI', () async {
    for (final lv in [1, 4, 8]) {
      for (final genre in [Genre.dizi, Genre.talkShow, Genre.yarisma]) {
        for (final skill in [45, 75]) {
          final row = StringBuffer('sv${lv + 1} ${genre.name.padRight(9)} yetenek $skill: ');
          for (final mode in ['b', 'g']) {
            for (int i = 0; i < (mode == 'b' ? prodBudgets.length : guestTiers.length); i++) {
              SharedPreferences.setMockInitialValues({});
              final g = Game();
              await g.start();
              g.studioLevel = lv;
              g.cash = 1e15;
              g.diamonds = 9999;
              final crew = <Staff>[];
              int k = 0;
              genreDefs[genre]!.needs.forEach((r, n) {
                for (int j = 0; j < n; j++) {
                  crew.add(Staff(id: 'c${k++}', name: 'x', role: r, skill: skill, salary: 1, spec: 99));
                }
              });
              g.staff.addAll(crew);
              final tier = 1;
              final b = mode == 'b' ? i : 1;
              final gu = mode == 'g' ? i : 0;
              final cost = g.showCost(genre, tier, b, gu, null);
              if (g.createShow('x', genre, tier, crew, budget: b, guest: gu) != null) {
                row.write('$mode$i:- ');
                continue;
              }
              final s = g.shows.first;
              g.speedUp(s);
              g.putOnAir(s, SlotId.prime1);
              g.setAdMinutes(SlotId.prime1, adTolerance(s.quality).roundToDouble());
              final rev = g.revenuePerDay(s) * genreDefs[genre]!.seasonDays - cost;
              row.write("$mode$i:${fmtShort(rev)} ");
              g.dispose();
            }
          }
          // ignore: avoid_print
          print(row);
        }
      }
    }
  });
}
