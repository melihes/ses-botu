import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/format.dart';
import 'package:reyting/data/calendar.dart';
import 'package:reyting/data/crisis_text.dart';
import 'package:reyting/engine/game.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_test.dart' show gameWithShowOnAir;
import 'ui_monkey_test.dart' show richGame;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Takvim', () {
    test('1. gün 1 Eylül, 360 gün bir yıl', () {
      expect(dateLabel(1), '1 Eylül');
      expect(dateLabel(31), '1 Ekim');
      expect(dateOfDay(361).year, 2);
      expect(dateLabel(361), '1 Eylül');
      expect(seasonOfDay(1), TvSeason.acilis);
      expect(seasonOfDay(1 + 30 * 9), TvSeason.yaz); // Haziran
    });
    test('yılbaşı yıl sonundan yeni yıla taşar', () {
      final y = specialDayById('yilbasi')!;
      final s = y.startDay(1);
      expect(dateLabel(s), '30 Aralık');
      expect(y.activeStart(s + 1), s);
      expect(dateLabel(s + 1), '1 Ocak');
      expect(y.activeStart(s + 2), isNull);
    });
    test('Ramazan her yıl 11 gün öne kayar', () {
      final r = specialDayById('ramazan')!;
      expect(r.doyIn(2), (r.doyIn(1) - 11 + 360) % 360);
    });
    test('özel bölüm: hazırlık penceresi, ödeme ve reyting', () async {
      final g = await gameWithShowOnAir(); // magazin programı
      final s = g.shows.first;
      final d = specialDayById('sevgililer')!; // magazin uygun
      final start = d.nextStart(g.day);
      expect(g.prepareSpecial(s, d), isNotNull, reason: 'çok erken');
      g.debugAdvanceDays((start - 5 - g.day).toDouble());
      g.cash = 1e12;
      final before = g.calendarMult(s);
      expect(g.prepareSpecial(s, d), isNull);
      expect(g.prepareSpecial(s, d), isNotNull, reason: 'iki kez olmaz');
      g.debugAdvanceDays((start - g.day).toDouble());
      expect(g.day, start);
      expect(g.calendarMult(s), greaterThan(before * 1.3));
      g.debugAdvanceDays(2);
      expect(g.specials.containsKey(s.id), isFalse, reason: 'bitince temizlenir');
    });
    test('dünya özel günü lokasyon ister', () async {
      final g = Game();
      await g.start();
      final c = specialDayById('cadilar')!;
      expect(g.specialAvailable(c), isFalse);
      g.ownedLocations.add('ny');
      expect(g.specialAvailable(c), isTrue);
    });
  });

  group('Türkçe ekler', () {
    test('ünlü uyumu', () {
      expect(trEk('Gece Yarısı', 'gen'), "Gece Yarısı'nın");
      expect(trEk('Deniz', 'dat'), "Deniz'e");
      expect(trEk('Mert', 'loc'), "Mert'te");
      expect(trEk('Kanal 9', 'gen'), "Kanal 9'un");
      expect(trEk('Yüzük', 'acc'), "Yüzük'ü");
    });
  });

  group('Sosyal medya', () {
    test('paylaşımlar üretilir, yer tutucu kalmaz, art arda aynı gövde çıkmaz', () async {
      final g = await gameWithShowOnAir();
      g.debugAdvanceDays(6);
      expect(g.socialFeed, isNotEmpty);
      for (final p in g.socialFeed) {
        expect(p.text.contains('{'), isFalse, reason: p.text);
        expect(p.handle.startsWith('@'), isTrue);
      }
      final texts = g.socialFeed.take(12).map((p) => p.text).toSet();
      expect(texts.length, g.socialFeed.take(12).length);
      expect(g.trendList, isNotEmpty);
    });
    test('kayıt ve geri yükleme', () async {
      final g = await gameWithShowOnAir();
      g.debugAdvanceDays(3);
      final raw = g.exportSave();
      final g2 = Game();
      await g2.start();
      await g2.importSave(raw);
      expect(g2.socialFeed.length, min(40, g.socialFeed.length));
      expect(jsonDecode(raw)['dramaLevel'], 1);
    });
  });

  group('Canlı yayın krizi', () {
    test('günde sınırlı, sonuç reytingi etkiler', () async {
      final g = await gameWithShowOnAir();
      final s = g.shows.first;
      final c = g.rollCrisis(s)!;
      expect(c.options.length, 3);
      expect(c.chances.every((x) => x > 0 && x < 1), isTrue);
      expect(c.desc.contains('{'), isFalse);
      final out = g.resolveCrisis(s, c, 1);
      expect(out.ratingDelta != 0, isTrue);
      expect(s.buffDays, greaterThan(0));
      expect(g.rollCrisis(s), isNull, reason: 'aynı program aynı gün bir kez');
    });
    test('süre dolarsa kötü sonuç', () async {
      final g = await gameWithShowOnAir();
      final s = g.shows.first;
      final out = g.resolveCrisis(s, g.rollCrisis(s)!, -1);
      expect(out.win, isFalse);
      expect(out.ratingDelta, lessThan(0));
    });
    test('kriz metinlerinde tanımsız yer tutucu yok', () {
      final ok = RegExp(r'\{(host|guest|actor|show)(:(gen|acc|dat|loc))?\}');
      for (final d in crisisDefs) {
        for (final t in [d.title, d.desc, for (final o in d.options) ...[o.win, o.fail]]) {
          expect(t.replaceAll(ok, '').contains('{'), isFalse, reason: t);
        }
      }
    });
  });

  group('Kulis dramaları', () {
    test('kapalıyken hiç drama çıkmaz', () async {
      final g = await gameWithShowOnAir();
      g.setDramaLevel(0);
      g.debugAdvanceDays(40);
      expect(g.bonds, isEmpty);
    });
    test('iki drama arasında bekleme süresi var', () async {
      final g = await richGame();
      g.pendingDecision = null;
      g.setDramaLevel(3);
      var count = 0;
      var last = -99;
      for (int i = 0; i < 60; i++) {
        g.debugAdvanceDays(1);
        if (g.dramaLastDay != last && g.dramaLastDay > 0) {
          if (last > 0) expect(g.dramaLastDay - last, greaterThanOrEqualTo(3));
          last = g.dramaLastDay;
          count++;
        }
        if (g.pendingDecision != null) g.resolveDecision(g.pendingDecision!.defaultOption);
      }
      expect(count, greaterThan(2), reason: 'kalabalık kadroda drama çıkmalı');
      expect(count, lessThanOrEqualTo(20));
    });
  });
}

int min(int a, int b) => a < b ? a : b;
