// Uzun vadeli ilerleme: akıllı bot ile binlerce gün.
// flutter test test/sim/long_sim.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/format.dart';
import 'package:reyting/engine/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'balance_sim.dart' as sim;

void main() {
  test('uzun simülasyon', () async {
    SharedPreferences.setMockInitialValues({});
    sim.naive = false;
    final g = Game();
    await g.start();
    g.introSeen = true;
    final sw = Stopwatch()..start();
    final days = int.parse(const String.fromEnvironment('DAYS', defaultValue: '6000'));
    var lastLv = 0;
    for (int d = 1; d <= days; d++) {
      sim.botDay(g);
      g.debugAdvanceDays(1);
      if (g.studioLevel != lastLv || d % 1000 == 0) {
        lastLv = g.studioLevel;
        // ignore: avoid_print
        print('Gün ${d.toString().padLeft(6)} · seviye ${g.studioLevel + 1} · kasa ${fmtShort(g.cash)} '
            '· net/gün ${fmtShort(g.netPerDay)} · değer ${fmtShort(g.netWorth)} · sıra #${g.richRank} '
            '· ${sw.elapsed.inSeconds}s');
      }
    }
    g.dispose();
  }, timeout: const Timeout(Duration(minutes: 30)));
}
