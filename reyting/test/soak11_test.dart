import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/calendar.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_monkey_test.dart' show richGame;

/// Uzun oyun: 2 yıl, çok drama, her gün kriz ve özel bölüm denemesi,
/// 30 günde bir kaydet-yükle. Çökme, NaN, sonsuz reyting yok.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('2 yıllık yeni içerik dayanıklılık testi', () async {
    var g = await richGame();
    g.setDramaLevel(3);
    g.ownedLocations.addAll(['ny', 'tokyo', 'rio']);
    for (int d = 0; d < 720; d++) {
      g.debugAdvanceDays(1);
      g.pendingAwards = null;
      g.pendingOffline = null;
      if (g.pendingDecision != null) g.resolveDecision(d % g.pendingDecision!.options.length);
      for (final s in g.shows.where((s) => s.status == ShowStatus.onAir).take(2)) {
        final c = g.rollCrisis(s);
        if (c != null) g.resolveCrisis(s, c, d % 4 - 1);
      }
      for (final (sd, _) in g.upcomingSpecialDays(within: 10)) {
        for (final s in g.specialCandidates(sd).take(1)) {
          g.prepareSpecial(s, sd);
        }
      }
      for (final s in g.shows.where((s) => s.status == ShowStatus.ended).take(1)) {
        final rep = <String, String>{};
        for (final (id, _) in g.renewBlockers(s)) {
          final old = g.staffById(id);
          final cand = g.staff.where((p) => p.showId == null && (old == null || p.role == old.role) && !rep.containsValue(p.id));
          if (cand.isNotEmpty) rep[id] = cand.first.id;
        }
        g.renewShow(s, replace: rep);
      }
      for (final s in g.shows.where((s) => s.status == ShowStatus.onAir)) {
        final r = g.currentRating(s);
        expect(r.isFinite && r >= 0 && r < 100, isTrue, reason: 'gün ${g.day} ${s.name} reyting $r');
      }
      expect(g.cash.isFinite, isTrue);
      if (d % 30 == 29) {
        final raw = g.exportSave();
        final g2 = Game();
        await g2.start();
        await g2.importSave(raw);
        expect(g2.day, g.day);
        expect(g2.specials, g.specials);
        expect(g2.bonds, g.bonds);
        expect(g2.shows.map((s) => s.castShock).toList(), g.shows.map((s) => s.castShock).toList());
        g.dispose();
        g = g2;
        g.setDramaLevel(3);
      }
    }
    // tarih ve takvim tutarlı
    expect(dateOfDay(g.day).year, greaterThanOrEqualTo(2));
    expect(g.socialFeed, isNotEmpty);
    // ignore: avoid_print
    print('gün ${g.day} · kasa ${g.cash.toStringAsExponential(2)} · ilişki ${g.bonds.length} · paylaşım ${g.socialFeed.length}');
  });
}
