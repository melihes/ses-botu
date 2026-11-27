// Gerçek takvim simülasyonu: "günde ~1 saat oynayan" oyuncu.
// Her gerçek gün: 3 oturum x 20 dk aktif oyun + aralarda ~7,7 saat yokluk.
// flutter test test/sim/calendar_sim.dart --dart-define=REALDAYS=365
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/format.dart';
import 'package:reyting/engine/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'balance_sim.dart' as sim;

void main() {
  test('takvim simülasyonu', () async {
    SharedPreferences.setMockInitialValues({});
    sim.naive = false;
    final g = Game();
    await g.start();
    g.introSeen = true;
    final realDays = int.parse(
      const String.fromEnvironment('REALDAYS', defaultValue: '365'),
    );
    const report = {1, 2, 3, 4, 5, 7, 10, 14, 30, 60, 90, 120, 180, 240, 300, 365};
    var lastLv = 0;
    for (int rd = 1; rd <= realDays; rd++) {
      for (int session = 0; session < 3; session++) {
        for (int m = 0; m < 20; m++) {
          sim.botDay(g);
          g.debugAdvanceDays(1);
        }
        sim.botDay(g);
        g.debugAway(const Duration(minutes: 460));
        g.pendingOffline = null;
        g.pendingAwards = null;
      }
      if (report.contains(rd) || g.studioLevel != lastLv) {
        lastLv = g.studioLevel;
        // ignore: avoid_print
        print(
          'Gerçek gün ${rd.toString().padLeft(3)} · oyun günü ${g.day} · seviye ${g.studioLevel + 1} '
          '· net/gün ${fmtShort(g.netPerDay)} · değer ${fmtShort(g.netWorth)} · sıra #${g.richRank}',
        );
      }
    }
    g.dispose();
  }, timeout: const Timeout(Duration(minutes: 60)));
}
