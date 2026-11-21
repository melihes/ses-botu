import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/data/content2.dart';
import 'package:reyting/engine/economy.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

Staff person(String id, Role r, int skill, {int spec = 0, int trait = 0}) =>
    Staff(
      id: id,
      name: 'Ad Soyad',
      role: r,
      skill: skill,
      salary: salaryFor(skill),
      spec: spec,
      trait: trait,
    );

Future<Game> fresh() async {
  final g = Game();
  await g.start();
  g.introSeen = true;
  return g;
}

/// Yayında bir dizi (oyuncular dahil) kurar.
Future<(Game, Show)> diziOnAir({
  int budget = 1,
  int guest = 0,
  String? loc,
}) async {
  final g = await fresh();
  g.cash = 1e9;
  g.studioLevel = 5;
  final crew = [
    person('a1', Role.senarist, 60),
    person('a2', Role.yonetmen, 60),
    person('a3', Role.oyuncu, 60),
    person('a4', Role.oyuncu, 60),
  ];
  g.staff.addAll(crew);
  expect(
    g.createShow(
      'Dizi',
      Genre.dizi,
      1,
      crew,
      budget: budget,
      guest: guest,
      location: loc,
    ),
    isNull,
  );
  final s = g.shows.first;
  g.speedUp(s);
  g.diamonds = 100;
  expect(g.putOnAir(s, SlotId.prime1), isNull);
  return (g, s);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Şirket kimliği', () {
    test('isim, ek ve logo kaydedilir ve geri yüklenir', () async {
      final g = await fresh();
      expect(g.identitySet, isFalse);
      g.setIdentity(
        company: 'Esmer',
        suffix: 2,
        channel: 'Esmer TV',
        newLogo: CompanyLogo(shape: 5, palette: 3, frame: 4),
      );
      expect(g.companyFullName, 'Esmer ${companySuffixes[2]}');
      await g.save();
      g.dispose();
      final g2 = await fresh();
      expect(g2.identitySet, isTrue);
      expect(g2.companyName, 'Esmer');
      expect(g2.channelName, 'Esmer TV');
      expect(g2.logo.shape, 5);
      expect(g2.logo.frame, 4);
      g2.dispose();
    });
    test('100\'den fazla logo kombinasyonu var', () {
      expect(logoCombinations, greaterThan(100));
    });
  });

  group('Bütçe, konuk, lokasyon', () {
    test('yüksek bütçe daha pahalı ve daha kaliteli', () async {
      final g = await fresh();
      g.studioLevel = 5;
      final crew = [person('x', Role.sunucu, 60)];
      final low = g.fullShowQuality(crew, Genre.talkShow, 1, 0, null);
      final prem = g.fullShowQuality(crew, Genre.talkShow, 1, 3, null);
      expect(prem, greaterThan(low));
      expect(
        g.showCost(Genre.talkShow, 1, 3, 0, null),
        greaterThan(g.showCost(Genre.talkShow, 1, 0, 0, null)),
      );
      g.dispose();
    });
    test('kilitli bütçe ve konuk reddedilir', () async {
      final g = await fresh();
      g.cash = 1e9;
      final host = person('h', Role.sunucu, 50);
      g.staff.add(host);
      expect(
        g.createShow('X', Genre.talkShow, 0, [host], budget: 4),
        isNotNull,
      );
      expect(g.createShow('X', Genre.talkShow, 0, [host], guest: 5), isNotNull);
      expect(
        g.createShow('X', Genre.talkShow, 0, [host], location: 'paris'),
        isNotNull,
      );
      g.dispose();
    });
    test('ünlü konuk reytingi artırır', () async {
      final (g, s) = await diziOnAir();
      final before = g.currentRating(s);
      expect(g.upgradeShowGuest(s), isNull);
      expect(g.currentRating(s), greaterThan(before));
      expect(s.guestName, isNotNull);
      g.dispose();
    });
    test('bütçe yükseltme kaliteyi artırır', () async {
      final (g, s) = await diziOnAir();
      final q = s.quality;
      final cash = g.cash;
      expect(g.upgradeShowBudget(s), isNull);
      expect(s.quality, greaterThan(q));
      expect(g.cash, lessThan(cash));
      g.dispose();
    });
    test('uyumlu lokasyon kaliteyi artırır, bakım gideri eklenir', () async {
      final g = await fresh();
      g.cash = 1e9;
      g.studioLevel = 5;
      final up = g.dailyUpkeep;
      expect(g.buyLocation(locationById('karadeniz')!), isNull);
      expect(g.dailyUpkeep, greaterThan(up));
      final crew = [
        person('a', Role.senarist, 60),
        person('b', Role.yonetmen, 60),
        person('c', Role.oyuncu, 60),
        person('d', Role.oyuncu, 60),
      ];
      expect(
        g.fullShowQuality(crew, Genre.dizi, 1, 1, 'karadeniz'),
        greaterThan(g.fullShowQuality(crew, Genre.dizi, 1, 1, null)),
      );
      // uyumsuz türde bonus yok
      expect(
        g.fullShowQuality([crew[0]], Genre.spor, 1, 1, 'karadeniz'),
        closeTo(g.fullShowQuality([crew[0]], Genre.spor, 1, 1, null), 1e-9),
      );
      g.dispose();
    });
    test('etkinlik bekleme süresi ve prestij', () async {
      final g = await fresh();
      g.cash = 1e12;
      g.studioLevel = 8;
      final l = locationById('paris')!;
      expect(g.holdEvent(l), isNotNull); // set yok
      expect(g.buyLocation(l), isNull);
      final p = g.prestige;
      expect(g.holdEvent(l), isNull);
      expect(g.prestige, greaterThan(p));
      expect(g.holdEvent(l), isNotNull); // bekleme
      g.dispose();
    });
  });

  group('Senaryo kararları', () {
    test('karar ihtimallerle gelir ve reytingi etkiler', () async {
      final (g, s) = await diziOnAir();
      expect(g.debugOfferStory(), isTrue);
      final d = g.pendingDecision!;
      expect(d.kind, 'story');
      expect(d.chances!.length, d.options.length);
      g.resolveDecision(0);
      expect(g.pendingDecision, isNull);
      expect(g.storyChoices, 1);
      expect(s.buff, isNot(1.0));
      g.dispose();
    });
  });

  group('Yetenek ajansı', () {
    test('genç yetenek gelişir ve satılabilir', () async {
      final g = await fresh();
      g.cash = 1e9;
      expect(
        g.signYouth(
          Staff(id: 'q', name: 'a', role: Role.oyuncu, skill: 20, salary: 1),
        ),
        isNotNull,
      ); // ajans kapalı
      expect(g.upgradeAgency(), isNull);
      expect(g.youthMarket, isNotEmpty);
      final y = g.youthMarket.first;
      final s0 = y.skill;
      expect(g.signYouth(y), isNull);
      expect(g.academy, contains(y));
      g.debugAdvanceDays(20);
      expect(y.skill, greaterThan(s0));
      expect(y.skill, lessThanOrEqualTo(y.potential));
      expect(g.promoteYouth(y), isNull);
      expect(g.staff, contains(y));
      final cash = g.cash;
      expect(g.quickSell(y), isNull);
      expect(g.staff, isNot(contains(y)));
      expect(g.cash, greaterThan(cash));
      g.dispose();
    });
    test('transfer al-sat ile para basılamaz', () async {
      final g = await fresh();
      g.cash = 1e9;
      g.upgradeAgency();
      final p = g.transferMarket.first;
      final price = g.transferPrice(p);
      expect(g.buyTransfer(p), isNull);
      // en iyi teklif bile alış fiyatının altında kalır
      expect(g.talentValue(p) * 1.2, lessThan(price));
      expect(g.quickSaleValue(p), lessThan(price));
      g.dispose();
    });
    test('satıştaki oyuncuya teklif gelir', () async {
      final g = await fresh();
      g.cash = 1e9;
      g.upgradeAgency();
      final p = person('s1', Role.oyuncu, 70);
      g.staff.add(p);
      g.toggleForSale(p);
      for (int i = 0; i < 10 && g.transferOffers.isEmpty; i++) {
        g.debugAdvanceDays(1);
      }
      expect(g.transferOffers, isNotEmpty);
      final o = g.transferOffers.first;
      expect(g.acceptTransfer(o), isNull);
      expect(g.staff, isNot(contains(p)));
      expect(g.talentsSold, 1);
      g.dispose();
    });
  });

  group('Yönetim kurulu', () {
    test('uzman yönetici daha çok kazandırır, eski kayıt taşınır', () async {
      final g = await fresh();
      g.cash = 1e9;
      g.studioLevel = 7;
      g.debugAdvanceDays(1);
      final gms =
          g.execCandidates.where((e) => e.role == ExecRole.genelMudur).toList()
            ..sort((a, b) => a.skill.compareTo(b.skill));
      expect(gms.length, 3);
      expect(gms.last.salary, greaterThan(gms.first.salary));
      expect(g.hireExec(gms.last), isNull);
      expect(g.autoManager, isTrue);
      final hi = g.execBonus(ExecRole.genelMudur);
      g.execs[ExecRole.genelMudur] = gms.first;
      expect(hi, greaterThan(g.execBonus(ExecRole.genelMudur)));
      g.dispose();

      // eski kayıt: managerHired
      final j = {'managerHired': true};
      SharedPreferences.setMockInitialValues({});
      final g2 = await fresh();
      g2.hireManager();
      await g2.save();
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonDecode(
        prefs.getString('reyting_save_v1')!,
      ) as Map<String, dynamic>;
      raw.remove('execs');
      raw.addAll(j);
      await prefs.setString('reyting_save_v1', jsonEncode(raw));
      g2.dispose();
      final g3 = await fresh();
      expect(g3.autoManager, isTrue);
      g3.dispose();
    });
    test('yayın planlama müdürü hazır programı yayına koyar', () async {
      final g = await fresh();
      g.cash = 1e9;
      g.studioLevel = 3;
      g.debugAdvanceDays(1);
      final yp = g.execCandidates.firstWhere((e) => e.role == ExecRole.yayin);
      expect(g.hireExec(yp), isNull);
      final host = person('h', Role.sunucu, 60);
      final dir = person('d', Role.yonetmen, 60);
      g.staff.addAll([host, dir]);
      expect(g.createShow('Y', Genre.yarisma, 0, [host, dir]), isNull);
      g.debugAdvanceDays(4);
      expect(g.shows.first.status, ShowStatus.onAir);
      g.dispose();
    });
  });

  group('Markalar', () {
    test('teklif kabulü günlük gelir ekler', () async {
      final (g, s) = await diziOnAir();
      g.debugAdvanceDays(1);
      g.brandOffers.clear();
      for (int i = 0; i < 30 && g.brandOffers.isEmpty; i++) {
        g.debugSpawnBrand();
      }
      expect(g.brandOffers, isNotEmpty);
      final o = g.brandOffers.first;
      final before = g.dealIncomePerDay + g.sponsorIncomePerDay;
      final cash = g.cash;
      expect(g.acceptBrandOffer(o), isNull);
      expect(
        g.dealIncomePerDay + g.sponsorIncomePerDay > before || g.cash > cash,
        isTrue,
      );
      g.dispose();
    });
  });

  group('Kayıt', () {
    test('yeni alanlar kaydedilip yüklenir', () async {
      final (g, s) = await diziOnAir(budget: 3, guest: 2);
      g.buyLocation(locationById('ist')!);
      g.upgradeAgency();
      g.signYouth(g.youthMarket.first);
      g.debugAdvanceDays(1);
      g.hireExec(g.execCandidates.first);
      await g.save();
      final worth = g.netWorth;
      g.dispose();
      final g2 = await fresh();
      expect(g2.shows.first.budget, 3);
      expect(g2.shows.first.guest, 2);
      expect(g2.ownedLocations, contains('ist'));
      expect(g2.agencyLevel, 1);
      expect(g2.academy.length, 1);
      expect(g2.execs.length, 1);
      expect(g2.netWorth, closeTo(worth, worth.abs() * 0.01 + 1));
      g2.dispose();
    });
  });
}
