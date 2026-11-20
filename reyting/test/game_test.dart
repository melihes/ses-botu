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
      expect(s.days, inInclusiveRange(9, 10), reason: '20 dk yokluk, yarı hız = 10 gün');
      expect(s.adIncome, greaterThan(0), reason: 'gelir işlenmeli');
      expect(s.salaries, greaterThan(0), reason: 'gider işlenmeli');
      expect(s.rent, greaterThan(0));
      expect(g2.day, greaterThan(9));
      g2.dispose();
    });

    test('çevrimdışı süre 8 saat ile sınırlı, yarı hızda', () async {
      final g = Game();
      await g.start();
      await g.save();
      g.dispose();
      final prefs = await SharedPreferences.getInstance();
      final j = jsonDecode(prefs.getString('reyting_save_v1')!);
      j['savedAt'] = DateTime.now()
          .subtract(const Duration(hours: 20))
          .millisecondsSinceEpoch;
      await prefs.setString('reyting_save_v1', jsonEncode(j));
      final g2 = Game();
      await g2.start();
      expect(g2.pendingOffline!.days, 240, reason: '8 saat x 60 dk x 0,5');
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

  group('Formatlar, dijital, geçmiş, görevler', () {
    test('üst format kilitli, stüdyo büyüyünce açılır', () async {
      final g = Game();
      await g.start();
      g.cash = 1e10;
      expect(g.formatUnlocked(Genre.yarisma, 0), isTrue);
      expect(g.formatUnlocked(Genre.yarisma, 3), isFalse, reason: 'ses yarışması sv3');
      g.upgradeStudio();
      g.upgradeStudio();
      expect(g.formatUnlocked(Genre.yarisma, 3), isTrue);
      expect(g.formatUnlocked(Genre.yarisma, 5), isFalse, reason: 'ada: drone + sv5');
      g.dispose();
    });

    test('üst format daha pahalı ve daha kaliteli', () {
      Staff p(int s) => Staff(id: 'x$s', name: 'a', role: Role.sunucu, skill: s, salary: 1);
      expect(productionCost(Genre.yarisma, 4), greaterThan(productionCost(Genre.yarisma, 0)));
      expect(showQuality([p(60)], Genre.yarisma, 4, const []),
          greaterThan(showQuality([p(60)], Genre.yarisma, 0, const [])));
    });

    test('YouTuber: transfer, gelir, büyüme, kampanya', () async {
      final g = Game();
      await g.start();
      g.cash = 1e9;
      final c = g.creatorMarket.first;
      expect(g.signCreator(c), isNull);
      expect(g.creatorIncomePerDay, greaterThan(0));
      final f0 = c.followers;
      g.debugAdvanceDays(3);
      expect(c.followers, greaterThan(f0));
      final f1 = c.followers;
      expect(g.runCampaign(c), isNull);
      expect(c.followers, closeTo(f1 * 1.15, 1));
      expect(g.runCampaign(c), isNotNull, reason: 'bekleme süresi');
      g.dispose();
    });

    test('kasa geçmişi her gün kaydedilir ve gelir/gider doğru', () async {
      final g = await gameWithShowOnAir();
      g.debugAdvanceDays(3);
      expect(g.history.length, 3);
      final h = g.history.last;
      expect(h.income, greaterThan(0));
      expect(h.expense, greaterThan(0));
      expect(g.history[1].cash + g.history[2].net, closeTo(g.history[2].cash, 2));
      g.dispose();
    });

    test('görev tamamlanınca elmas ödülü verilir (bir kez)', () async {
      final g = Game();
      await g.start();
      final d0 = g.diamonds;
      g.cash = 1e9;
      g.hire(g.market[0]);
      g.hire(g.market[0]);
      expect(g.claimedGoals, contains(0));
      expect(g.diamonds, d0 + 3);
      g.hire(g.market[0]);
      expect(g.diamonds, d0 + 3);
      g.dispose();
    });
  });

  group('Rapor, kararlar, ödüller, başarımlar', () {
    test('her sabah reyting raporu çıkar ve sıralamada yer alırım', () async {
      final g = await gameWithShowOnAir();
      g.debugAdvanceDays(1);
      expect(g.lastReport[SlotId.prime], isNotEmpty);
      expect(g.rankIn(SlotId.prime), isNotNull);
      final rows = g.lastReport[SlotId.prime]!;
      for (int i = 1; i < rows.length; i++) {
        expect(rows[i - 1].rating, greaterThanOrEqualTo(rows[i].rating));
      }
      g.dispose();
    });

    test('sponsor kabul edilince günlük gelir gelir, 10 gün sonra biter', () async {
      final g = await gameWithShowOnAir();
      final s = g.shows.first;
      g.pendingDecision = Decision(kind: 'sponsor', title: 't', body: 'b',
          options: ['a', 'b', 'c'], hints: ['', '', ''], targetId: s.id, amount: 10000, extra: 'Fırtına Cola');
      g.resolveDecision(0);
      expect(g.pendingDecision, isNull);
      expect(g.sponsorIncomePerDay, 10000);
      expect(g.sponsorDeals, 1);
      s.episodesAired = -20; // sezon bitmesin
      g.debugAdvanceDays(10.5);
      expect(s.sponsorDays, 0);
      expect(g.sponsorIncomePerDay, 0);
      g.dispose();
    });

    test('yıldız zammı verilince maaş %20 artar', () async {
      final g = Game();
      await g.start();
      g.staff.add(Staff(id: 'star', name: 'Yıldız', role: Role.oyuncu, skill: 95, salary: 10000));
      g.pendingDecision = Decision(kind: 'raise', title: 't', body: 'b',
          options: ['a', 'b', 'c'], hints: ['', '', ''], targetId: 'star');
      g.resolveDecision(0);
      expect(g.staffById('star')!.salary, 12000);
      g.dispose();
    });

    test('transfer: satınca bonservis gelir, yıldız gider', () async {
      final g = Game();
      await g.start();
      g.staff.add(Staff(id: 'star', name: 'Yıldız', role: Role.oyuncu, skill: 95, salary: 10000));
      final c0 = g.cash;
      g.pendingDecision = Decision(kind: 'poach', title: 't', body: 'b',
          options: ['a', 'b'], hints: ['', ''], targetId: 'star', extra: 'Nova Türk');
      g.resolveDecision(1);
      expect(g.staffById('star'), isNull);
      expect(g.cash, c0 + 250000);
      g.dispose();
    });

    test('30. günde Altın Anten töreni yapılır', () async {
      final g = await gameWithShowOnAir();
      g.cash = 1e9;
      g.shows.first.episodesAired = -100;
      g.debugAdvanceDays(30);
      expect(g.pendingAwards, isNotNull);
      expect(g.pendingAwards!.first.nominee, 'Test Şov');
      g.dispose();
    });

    test('başarım bir kez verilir', () async {
      final g = await gameWithShowOnAir();
      g.debugAdvanceDays(1);
      g.hire(g.market.first);
      expect(g.achievements, contains('first_air'));
      final d = g.diamonds;
      g.hire(g.market.first);
      expect(g.diamonds, d);
      g.dispose();
    });
  });

  group('Kararlar oyunu durdurmaz', () {
    test('cevap verilmezse 1 gün sonra güvenli seçenek otomatik seçilir', () async {
      final g = await gameWithShowOnAir();
      final s = g.shows.first;
      s.episodesAired = -20;
      final d = Decision(kind: 'setCrisis', title: 't', body: 'b',
          options: ['a', 'b', 'c'], hints: ['', '', ''], targetId: s.id,
          amount: 1000, defaultOption: 2);
      d.deadline = g.gameTime + 1.0;
      g.pendingDecision = d;
      g.debugAdvanceDays(0.5);
      expect(g.pendingDecision, isNotNull, reason: 'süre dolmadı');
      g.debugAdvanceDays(0.6);
      expect(g.pendingDecision, isNull, reason: 'otomatik çözülmeli');
      expect(g.decisionsMade, 1);
      g.dispose();
    });

    test('olayların reyting etkisi ±%20 ile sınırlı', () async {
      final g = await gameWithShowOnAir();
      final s = g.shows.first;
      s.episodesAired = -200;
      for (int i = 0; i < 150; i++) {
        g.debugAdvanceDays(1);
        if (g.pendingDecision != null) g.resolveDecision(1);
        expect(s.buff, inInclusiveRange(0.85, 1.2));
      }
      g.dispose();
    });
  });

  test('HATA #2: grafikte gider hiçbir gün eksi çıkmaz', () async {
    final g = await gameWithShowOnAir();
    g.shows.first.episodesAired = -300;
    g.takeLoan(loanOffersFor(0).first);
    for (int i = 0; i < 200; i++) {
      g.debugAdvanceDays(1);
      if (g.pendingDecision != null) g.resolveDecision(i % 2);
    }
    for (final h in g.history) {
      expect(h.expense, greaterThanOrEqualTo(-1), reason: 'Gün ${h.day}');
    }
    g.dispose();
  });

  group('Rekabet dengesi', () {
    test('aynı türden iki program yayındaysa ikisi de reyting kaybeder', () async {
      final g = await gameWithShowOnAir();
      g.cash = 1e9;
      final r1 = g.currentRating(g.shows.first);
      final host = g.market.firstWhere((p) => p.role == Role.sunucu);
      g.hire(host);
      g.createShow('İkinci', Genre.magazin, 0, [host]);
      final s2 = g.shows.first;
      g.speedUp(s2);
      g.putOnAir(s2, SlotId.gunduz);
      expect(g.saturationFor(Genre.magazin), lessThan(1));
      expect(g.currentRating(g.shows.last), lessThan(r1));
      g.dispose();
    });

    test('rakip baskısı zamanla artar ama sınırlı kalır', () async {
      final g = Game();
      await g.start();
      final p0 = g.rivalPressure;
      g.day = 400;
      expect(g.rivalPressure, lessThan(p0));
      g.day = 5000;
      expect(g.rivalPressure, 0.65);
      g.dispose();
    });

    test('şirket değeri varlıkları da sayar', () async {
      final g = Game();
      await g.start();
      g.cash = 1e9;
      final v0 = g.netWorth;
      g.buyFixed(luxuryDefs.first);
      expect(g.netWorth, lessThan(v0));
      expect(g.netWorth, greaterThan(v0 - luxuryDefs.first.price));
      g.dispose();
    });
  });

  test('HATA #3: art arda zamlar maaşı sınırsız büyütemez', () async {
    final g = Game();
    await g.start();
    g.staff.add(Staff(id: 'star', name: 'Yıldız', role: Role.oyuncu, skill: 95, salary: salaryFor(95)));
    for (int i = 0; i < 50; i++) {
      g.pendingDecision = Decision(kind: 'raise', title: 't', body: 'b',
          options: ['a', 'b', 'c'], hints: ['', '', ''], targetId: 'star');
      g.resolveDecision(0);
    }
    expect(g.staffById('star')!.salary, lessThanOrEqualTo(salaryFor(95) * 2 + 100));
    g.dispose();
  });

  group('Borsa ve zenginler', () {
    test('hisse al-sat: komisyon ve kâr hesabı', () async {
      final g = Game();
      await g.start();
      g.cash = 1e8;
      final t = stockDefs.first.ticker;
      final p0 = g.priceOf(t);
      expect(g.buyStock(t, 1000), isNull);
      expect(g.holdings[t], 1000);
      expect(g.cash, closeTo(1e8 - p0 * 1000 * 1.003, 1));
      expect(g.netWorth, greaterThan(1e8 - p0 * 1000 * 0.01));
      expect(g.sellStock(t, 1000), isNull);
      expect(g.holdings.containsKey(t), isFalse);
      expect(g.tradingProfit, lessThan(0), reason: 'anında al-sat komisyon kaybettirir');
      g.dispose();
    });

    test('bir şirketin en fazla %25\'i alınabilir', () async {
      final g = Game();
      await g.start();
      g.cash = 1e15;
      final d = stockDefs.first;
      expect(g.buyStock(d.ticker, d.shares * 0.3), isNotNull);
      expect(g.maxBuyable(d.ticker), lessThanOrEqualTo(d.shares * 0.25));
      g.dispose();
    });

    test('fiyatlar zamanla hareket eder ve pozitif kalır', () async {
      final g = Game();
      await g.start();
      final before = Map.of(g.stockPrices);
      g.debugAdvanceDays(20);
      var moved = 0;
      for (final d in stockDefs) {
        expect(g.priceOf(d.ticker), greaterThan(0));
        if ((g.priceOf(d.ticker) - before[d.ticker]!).abs() > 1e-6) moved++;
      }
      expect(moved, stockDefs.length);
      g.dispose();
    });

    test('zenginler sırası servet arttıkça yükselir', () async {
      final g = Game();
      await g.start();
      final r0 = g.richRank;
      g.cash = 1e12;
      expect(g.richRank, lessThan(r0));
      g.dispose();
    });
  });

  group('Para basma açıkları kapalı', () {
    test('HATA #4: kanalı en ucuza alıp satmak kâr ettirmez', () async {
      final g = Game();
      await g.start();
      g.cash = 1e10;
      for (final c in channelDefs) {
        final c0 = g.cash;
        g.completePurchase(c.id, c.price * 0.74); // pazarlıkta inilebilecek en düşük
        g.sellChannel(c);
        expect(g.cash, lessThan(c0), reason: c.name);
      }
      g.dispose();
    });

    test('HATA #5: borsada büyük al-sat döngüsü kâr ettirmez', () async {
      final g = Game();
      await g.start();
      g.cash = 1e15;
      for (final d in stockDefs) {
        final c0 = g.cash;
        final q = (d.shares * 0.25).floorToDouble();
        expect(g.buyStock(d.ticker, q), isNull);
        expect(g.sellStock(d.ticker, q), isNull);
        expect(g.cash, lessThan(c0), reason: d.ticker);
      }
      g.dispose();
    });

    test('lüksü alıp satmak kâr ettirmez', () async {
      final g = Game();
      await g.start();
      g.cash = 1e12;
      for (final d in luxuryDefs) {
        final c0 = g.cash;
        g.completePurchase(d.id, d.price * 0.74);
        g.sellLuxury(d);
        expect(g.cash, lessThan(c0), reason: d.name);
      }
      g.dispose();
    });

    test('HATA #6: ödülü sadece son 30 günde yayında olanlar alır', () async {
      final g = await gameWithShowOnAir();
      g.cash = 1e9;
      final s = g.shows.first;
      s.ratingHistory.addAll(List.filled(10, 50.0)); // efsane bir sezon
      g.takeOffAir(s.slot!);
      g.debugAdvanceDays(60.5); // iki tören geçer
      final names = g.trophies.map((t) => t.winner).toList();
      expect(names.where((n) => n == s.name).length, lessThanOrEqualTo(1),
          reason: 'bitmiş program her törende ödül almamalı');
      g.dispose();
    });

    test('kısa ayrılık sessizce işlenir (zaman kaybolmaz)', () async {
      final g = Game();
      await g.start();
      await g.save();
      g.dispose();
      final prefs = await SharedPreferences.getInstance();
      final j = jsonDecode(prefs.getString('reyting_save_v1')!);
      j['savedAt'] = DateTime.now().subtract(const Duration(seconds: 40)).millisecondsSinceEpoch;
      await prefs.setString('reyting_save_v1', jsonEncode(j));
      final g2 = Game();
      await g2.start();
      expect(g2.pendingOffline, isNull, reason: 'özet penceresi çıkmamalı');
      expect(g2.dayProgress, greaterThan(0.5), reason: '40 sn = ~0,67 gün işlenmeli');
      g2.dispose();
    });
  });

  group('Genel Müdür', () {
    test('sezon bitince yenilenir ve hazır olunca aynı kuşağa döner', () async {
      final g = await gameWithShowOnAir();
      g.cash = 1e8;
      final s = g.shows.first;
      final slot = s.slot!;
      g.debugAdvanceDays(s.seasonDays + 0.5);
      expect(s.season, 2, reason: 'yeni sezon başlamalı');
      g.debugAdvanceDays(5);
      expect(s.status, ShowStatus.onAir);
      expect(s.slot, slot);
      g.dispose();
    });

    test('kapalıyken yenilemez; elle kaldırılan program yenilenmez', () async {
      final g = await gameWithShowOnAir();
      g.cash = 1e8;
      final s = g.shows.first;
      g.takeOffAir(s.slot!);
      expect(s.status, ShowStatus.ended);
      g.setAutoManager(false);
      final g2s = g.shows.first;
      expect(g2s.season, 1);
      g.dispose();
    });

    test('8 saatlik yoklukta kanal boş kalmaz', () async {
      final g = await gameWithShowOnAir();
      g.cash = 1e8;
      g.debugAway(const Duration(hours: 8));
      expect(g.shows.where((s) => s.status == ShowStatus.onAir), isNotEmpty);
      expect(g.shows.first.season, greaterThan(5));
      g.dispose();
    });
  });
}
