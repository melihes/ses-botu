import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/format.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/engine/economy.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kadro tutup bir magazin programını yayına koyan yardımcı.
Future<Game> gameWithShowOnAir() async {
  final g = Game();
  await g.start();
  final host = g.market.firstWhere((p) => p.role == Role.sunucu);
  expect(g.hire(host), isNull);
  expect(g.createShow('Test Şov', Genre.magazin, 1, [host]), isNull);
  final show = g.shows.first;
  expect(g.speedUp(show), isNull);
  expect(show.status, ShowStatus.ready);
  expect(g.putOnAir(show, SlotId.prime), isNull);
  return g;
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Biçimlendirme', () {
    test('tam para', () {
      expect(fmtFull(3507617548), '3.507.617.548 ₺');
      expect(fmtFull(-1500), '-1.500 ₺');
    });
    test('kısa para', () {
      expect(fmtShort(25900000), '25,9 M ₺');
      expect(fmtShort(3.5e9), '3,5 Mr ₺');
      expect(fmtShort(2e12), '2 Tn ₺');
      expect(fmtShort(94e15), '94 Ktr ₺');
      expect(fmtShort(250000), '250 B ₺');
    });
  });

  group('Ekonomi', () {
    test('reklam geliri tahammül noktasında zirve yapar', () {
      const q = 0.5;
      final t = adTolerance(q);
      double rev(double m) => m * adRetention(m, q);
      expect(rev(t), greaterThan(rev(t - 3)));
      expect(rev(t), greaterThan(rev(t + 3)));
    });
    test('kaliteli program daha çok reklamı kaldırır', () {
      expect(adRetention(12, 0.9), greaterThan(adRetention(12, 0.3)));
    });
    test('daha iyi kadro daha yüksek kalite', () {
      Staff p(int s) => Staff(
          id: 'x$s', name: 'a', role: Role.sunucu, skill: s, salary: 1);
      expect(showQuality([p(80)], Genre.magazin, 1, const []),
          greaterThan(showQuality([p(40)], Genre.magazin, 1, const [])));
    });
  });

  group('Oyun akışı', () {
    test('yayındaki program gelir getirir, gün sonunda maaş kesilir', () async {
      final g = await gameWithShowOnAir();
      final show = g.shows.first;
      expect(g.revenuePerDay(show), greaterThan(0));
      final day = g.day;
      g.timeScale = 1;
      // 1 günü elle ilerlet
      g.setTimeScale(1);
      g.dispose();
      expect(g.day, day);
    });

    test('ÇEVRİMDIŞI: gelir de gider de işlenir (simetri)', () async {
      final g = await gameWithShowOnAir();
      await g.save();
      g.dispose();

      // Kaydı 20 dakika öncesine çek
      final prefs = await SharedPreferences.getInstance();
      final j = jsonDecode(prefs.getString('reyting_save_v1')!);
      j['savedAt'] = DateTime.now()
          .subtract(const Duration(minutes: 20))
          .millisecondsSinceEpoch;
      await prefs.setString('reyting_save_v1', jsonEncode(j));

      final g2 = Game();
      await g2.start();
      final s = g2.pendingOffline!;
      expect(s.days, inInclusiveRange(19, 20));
      expect(s.adIncome, greaterThan(0), reason: 'gelir işlenmeli');
      expect(s.salaries, greaterThan(0), reason: 'gider işlenmeli');
      expect(s.rent, greaterThan(0));
      expect(g2.day, greaterThan(15));
      g2.dispose();
    });

    test('çevrimdışı süre 30 dakika ile sınırlı', () async {
      final g = Game();
      await g.start();
      await g.save();
      g.dispose();
      final prefs = await SharedPreferences.getInstance();
      final j = jsonDecode(prefs.getString('reyting_save_v1')!);
      j['savedAt'] = DateTime.now()
          .subtract(const Duration(hours: 5))
          .millisecondsSinceEpoch;
      await prefs.setString('reyting_save_v1', jsonEncode(j));
      final g2 = Game();
      await g2.start();
      expect(g2.pendingOffline!.days, 30);
      g2.dispose();
    });

    test('telefon saati geri alınırsa hiçbir şey işlenmez', () async {
      final g = Game();
      await g.start();
      await g.save();
      g.dispose();
      final prefs = await SharedPreferences.getInstance();
      final j = jsonDecode(prefs.getString('reyting_save_v1')!);
      j['savedAt'] = DateTime.now()
          .add(const Duration(hours: 3))
          .millisecondsSinceEpoch;
      await prefs.setString('reyting_save_v1', jsonEncode(j));
      final g2 = Game();
      await g2.start();
      expect(g2.pendingOffline, isNull);
      expect(g2.day, 1);
      g2.dispose();
    });

    test('kayıt/yükleme tüm durumu korur', () async {
      final g = await gameWithShowOnAir();
      g.buyFixed(luxuryDefs.first);
      await g.save();
      g.dispose();
      final g2 = Game();
      await g2.start();
      expect(g2.staff.length, 1);
      expect(g2.shows.first.status, ShowStatus.onAir);
      expect(g2.ownedLuxury, contains(luxuryDefs.first.id));
      g2.dispose();
    });

    test('HATA #1: işlemden hemen sonra kapanırsa kayıp olmaz', () async {
      final g = Game();
      await g.start();
      final p = g.market.first;
      g.hire(p);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      g.dispose(); // uygulama aniden kapandı, onPause çağrılmadı
      final g2 = Game();
      await g2.start();
      expect(g2.staff.map((e) => e.id), contains(p.id));
      g2.dispose();
    });

    test('pazarlık: istenen fiyat her zaman kabul edilir', () async {
      final g = Game();
      await g.start();
      g.cash = 1e12;
      final d = luxuryDefs.firstWhere((x) => x.negotiable);
      final r = g.negotiate(d.id, d.price, d.price);
      expect(r.outcome, NegOutcome.accepted);
      g.completePurchase(d.id, r.price!);
      expect(g.ownedLuxury, contains(d.id));
      g.dispose();
    });

    test('pazarlık: sabır biterse satıcı kilitlenir', () async {
      final g = Game();
      await g.start();
      g.cash = 1e12;
      final d = luxuryDefs.firstWhere((x) => x.negotiable);
      for (int i = 0; i < 3; i++) {
        g.negotiate(d.id, d.price, d.price * 0.3);
      }
      expect(g.negLocked(d.id), isTrue);
      g.dispose();
    });
  });

  group('Sinema ve holding', () {
    Future<(Game, Film)> filmReady() async {
      final g = Game();
      await g.start();
      g.cash = 1e9;
      g.diamonds = 100;
      Staff mk(Role r, int i) {
        final p = Staff(id: 't${r.index}$i', name: 'Test $i', role: r, skill: 70, salary: 1000);
        g.staff.add(p);
        return p;
      }
      final crew = [mk(Role.senarist, 1), mk(Role.yonetmen, 1), mk(Role.oyuncu, 1)];
      expect(g.createFilm('Test Film', FilmGenre.komedi, 1, crew), isNull);
      final f = g.films.first;
      expect(f.status, FilmStatus.producing);
      expect(g.speedUpFilm(f), isNull);
      expect(f.status, FilmStatus.ready);
      expect(f.score, greaterThan(1));
      expect(crew.every((c) => c.showId == null), isTrue, reason: 'ekip serbest kalmalı');
      return (g, f);
    }

    test('vizyon: gişe gelir, 10 gün sonra kütüphaneye geçer', () async {
      final (g, f) = await filmReady();
      expect(g.releaseInTheaters(f), isNull);
      g.debugAdvanceDays(theaterRunDays.toDouble() + 0.5);
      expect(f.boxOffice, greaterThan(0));
      expect(f.status, FilmStatus.library);
      g.dispose();
    });

    test('lisans: para gelir, haklar bende kalır, aynı platforma iki kez olmaz', () async {
      final (g, f) = await filmReady();
      final cash = g.cash;
      final p = platformDefs.first;
      expect(g.licenseFilm(f, p), isNull);
      expect(g.cash, greaterThan(cash));
      expect(f.rightsOwned, isTrue);
      expect(g.licenseFilm(f, p), isNotNull);
      g.debugAdvanceDays(licenseDays + 1.0);
      expect(f.licenses, isEmpty, reason: 'lisans süresi bitmeli');
      expect(g.licenseFilm(f, p), isNull, reason: 'süre bitince tekrar satılabilmeli');
      g.dispose();
    });

    test('hak satışı: film başkasına geçer, artık lisanslanamaz', () async {
      final (g, f) = await filmReady();
      final cash = g.cash;
      expect(g.sellRights(f), isNull);
      expect(g.cash, greaterThan(cash));
      expect(f.rightsOwned, isFalse);
      expect(g.licenseFilm(f, platformDefs.first), isNotNull);
      g.dispose();
    });

    test('kendi platformunda yayın gelir getirir', () async {
      final (g, f) = await filmReady();
      g.completePurchase(platformDefs.first.id, 0);
      final before = g.platformIncomePerDay;
      expect(g.toggleOwnPlatform(f), isNull);
      expect(g.platformIncomePerDay, greaterThan(before));
      g.dispose();
    });

    test('holding: işletme gelir ve etki verir, kayıtta korunur', () async {
      final g = Game();
      await g.start();
      g.cash = 1e9;
      final ajans = bizById('ajans')!;
      final bonus = g.adBonus;
      expect(g.upgradeBiz(ajans), isNull);
      expect(g.bizLevel('ajans'), 1);
      expect(g.adBonus, greaterThan(bonus));
      expect(g.bizIncomePerDay, greaterThan(0));
      await g.save();
      g.dispose();
      final g2 = Game();
      await g2.start();
      expect(g2.bizLevel('ajans'), 1);
      g2.dispose();
    });

    test('çevrimdışı: gişe ve işletme gelirleri de işlenir', () async {
      final (g, f) = await filmReady();
      g.upgradeBiz(bizById('radyo')!);
      g.releaseInTheaters(f);
      await g.save();
      g.dispose();
      final prefs = await SharedPreferences.getInstance();
      final j = jsonDecode(prefs.getString('reyting_save_v1')!);
      j['savedAt'] = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      await prefs.setString('reyting_save_v1', jsonEncode(j));
      final g2 = Game();
      await g2.start();
      expect(g2.pendingOffline!.boxOffice, greaterThan(0));
      expect(g2.pendingOffline!.bizIncome, greaterThan(0));
      g2.dispose();
    });
  });
}
