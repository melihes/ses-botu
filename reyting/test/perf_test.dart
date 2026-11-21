// Performans: ağır bir geç oyun kaydında bir saniyelik oyun ne kadar sürüyor,
// kayıt dosyası ne kadar büyük, açılış ne kadar sürüyor.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('geç oyun performansı', () async {
    SharedPreferences.setMockInitialValues({});
    final g = Game();
    await g.start();
    g.introSeen = true;
    g.cash = 1e13;
    g.studioLevel = 11;
    g.diamonds = 100000;
    for (int i = 0; i < 70; i++) {
      g.staff.add(
        Staff(
          id: 'p$i',
          name: 'K $i',
          role: Role.values[i % 4],
          skill: 80,
          salary: 20000,
        ),
      );
    }
    // 10 kuşak dolu + yüzlerce eski program
    var n = 0;
    for (final slot in SlotId.values) {
      final crew = <Staff>[];
      genreDefs[Genre.yarisma]!.needs.forEach(
        (r, k) => crew.addAll(g.freeStaff(r).take(k)),
      );
      g.createShow('S${n++}', Genre.yarisma, 2, crew, budget: 3, guest: 3);
      g.speedUp(g.shows.first);
      g.putOnAir(g.shows.first, slot);
    }
    for (int i = 0; i < 400; i++) {
      g.shows.add(
        Show(
          id: 'old$i',
          name: 'Eski $i',
          genre: Genre.dizi,
          tier: 1,
          staffIds: [],
          status: ShowStatus.ended,
          prodLeft: 0,
          quality: 0.5,
          ratingHistory: List.filled(30, 5.0),
        ),
      );
    }
    g.upgradeAgency();
    g.debugAdvanceDays(2000); // uzun geçmiş
    final sw = Stopwatch()..start();
    for (int i = 0; i < 1200; i++) {
      g.debugAdvanceDays(0.5 / 60); // 10 dakikalık gerçek oyun (500 ms adımlar)
    }
    final perTick = sw.elapsedMicroseconds / 1200;
    sw.reset();
    await g.save();
    final saveMs = sw.elapsedMilliseconds;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('reyting_save_v1')!;
    sw.reset();
    final g2 = Game();
    await g2.start();
    final loadMs = sw.elapsedMilliseconds;
    sw.reset();
    g2.debugAway(const Duration(hours: 8)); // 8 saat yokluk
    final awayMs = sw.elapsedMilliseconds;
    // ignore: avoid_print
    print(
      'adım başına ${(perTick / 1000).toStringAsFixed(2)} ms · kayıt ${(raw.length / 1024).toStringAsFixed(0)} KB, '
      'kaydetme $saveMs ms · açılış $loadMs ms · 8 saat yokluk hesabı $awayMs ms · gün ${g.day}',
    );
    expect(
      perTick / 1000,
      lessThan(8),
      reason: 'her 500 ms adım telefonda takılmaya yol açmasın',
    );
    expect(raw.length, lessThan(2 * 1024 * 1024));
    expect(jsonDecode(raw), isA<Map>());
    g.dispose();
    g2.dispose();
  });
}
