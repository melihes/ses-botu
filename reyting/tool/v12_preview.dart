// Geliştirme aracı: v0.12 ekranlarını dolu bir oyunla önizler (oyuna dahil değil).
// ?p=map|agency|board|brands|production|identity|wizard|sting|story
import 'package:flutter/material.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/data/content2.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:reyting/ui/dialogs/identity_dialog.dart';
import 'package:reyting/ui/screens/live_view.dart';
import 'package:reyting/ui/screens/production_screen.dart';
import 'package:reyting/ui/shell.dart';
import 'package:reyting/ui/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  try {
    await _main();
  } catch (e, st) {
    // ignore: avoid_print
    print('HATA: $e\n$st');
  }
}

Future<void> _main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  final g = Game();
  await g.start();
  g.introSeen = true;
  g.identitySet = true;
  g.companyName = 'Esmer';
  g.companySuffix = 0;
  g.logo = CompanyLogo(shape: 0, palette: 0, frame: 1);
  g.channelName = 'Esmer TV';
  g.cash = 5e9;
  g.studioLevel = 6;
  g.diamonds = 200;
  g.stingOn = p != 'sting' ? false : true;
  g.ownedLocations.addAll(['ist', 'kapadokya', 'karadeniz', 'paris']);
  g.upgradeAgency();
  g.upgradeAgency();
  g.upgradeAgency();
  for (final y in g.youthMarket.take(3).toList()) {
    g.signYouth(y);
  }
  const names = ['Derin Ak', 'Mert Kaya', 'Elif Su', 'Can Ateş', 'Zeynep Ay', 'Burak Er',
    'Ece Nur', 'Ali Tan', 'Selin Ilgaz', 'Kerem Sancak', 'Ayla Rüzgâr', 'Ozan Yel'];
  var k = 0;
  for (final r in Role.values) {
    for (int i = 0; i < 3; i++) {
      final sk = 55 + (k * 7) % 40;
      g.staff.add(Staff(id: 'pv$k', name: names[k], role: r, skill: sk,
          salary: 1500 + sk * sk * 3.0, trait: k % 9, age: 22 + k * 2));
      k++;
    }
  }
  g.debugAdvanceDays(1);
  for (final e in g.execCandidates.where((e) => e.skill > 80).take(3).toList()) {
    g.hireExec(e);
  }
  final crew = g.staff.where((s) => s.role != Role.sunucu).take(4).toList();
  final e1 = g.createShow('Konaktaki Sır', Genre.dizi, 3, [
    g.freeStaff(Role.senarist).first, g.freeStaff(Role.yonetmen).first,
    ...g.freeStaff(Role.oyuncu).take(2)], budget: 3, guest: 4, location: 'kapadokya');
  final e2 = g.createShow('Gece Yarısı', Genre.talkShow, 1, [for (final e in genreDefs[Genre.talkShow]!.needs.entries) ...g.freeStaff(e.key).take(e.value)], budget: 2, guest: 3);
  // ignore: avoid_print
  print('show: $e1 / $e2');
  for (final s in g.shows) {
    g.speedUp(s);
  }
  g.putOnAir(g.shows[1], SlotId.prime1);
  g.putOnAir(g.shows[0], SlotId.prime2);
  g.debugAdvanceDays(2);
  for (int i = 0; i < 4; i++) {
    g.debugSpawnBrand();
  }
  g.staff.first.fame = 64;
  g.toggleForSale(g.staff.first);
  g.debugAdvanceDays(1);
  g.pendingDecision = null;
  g.dismissLogin();
  if (p == 'story') g.debugOfferStory();
  crew.length;
  final page = switch (p) {
    'map' => PageId.map,
    'agency' => PageId.agency,
    'board' => PageId.board,
    'brands' => PageId.brands,
    'production' || 'story' => PageId.production,
    'home' => PageId.home,
    'staff' => PageId.staff,
    'luxury' => PageId.luxury,
    'broadcast' => PageId.broadcast,
    'cinema' => PageId.cinema,
    _ => PageId.home,
  };
  runApp(GameScope(
    game: g,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: Builder(builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (p == 'identity') showIdentityDialog(ctx, first: true);
          if (p == 'wizard') openNewShowWizard(ctx);
          if (p == 'sting') g.sting.value = 'Konaktaki Sır';
          if (p == 'live' || p == 'live2') {
            openLiveView(ctx, g.shows.firstWhere((s) => s.status == ShowStatus.onAir && (p == 'live2' ? s.genre == Genre.dizi : s.genre == Genre.talkShow)));
          }
          if (p == 'live3') {
            final cr = [for (final e in genreDefs[Genre.yarisma]!.needs.entries) ...g.freeStaff(e.key).take(e.value)];
            g.ownedEquip.add('drone');
            g.createShow('Adada Kalan', Genre.yarisma, 5, cr, budget: 4, guest: 4);
            g.speedUp(g.shows.first);
            g.putOnAir(g.shows.first, SlotId.aksam1);
            openLiveView(ctx, g.shows.first);
          }
        });
        return Shell(initial: page);
      }),
    ),
  ));
}

String get p => Uri.base.queryParameters['p'] ?? 'home';
