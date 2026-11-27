// Geliştirme aracı: Play Store ekran görüntüleri (1920x1080) üretir.
// SHOTS=1 flutter test test/store_shots_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/ui/shell.dart';
import 'package:reyting/ui/widgets/common.dart';

import 'package:reyting/data/content.dart';
import 'package:reyting/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ui_monkey_test.dart' show loadFonts;

/// Görüntüler için gerçek isimli kadrosu olan, birkaç hafta oynanmış oyun
Future<Game> shotGame() async {
  SharedPreferences.setMockInitialValues({});
  final g = Game();
  await g.start();
  g.introSeen = true;
  g.identitySet = true;
  g.dismissLogin();
  g.stingOn = false;
  g.cash = 2e9;
  g.studioLevel = 6;
  for (int k = 0; k < 40; k++) {
    for (final p in g.market.toList()) {
      if (Role.values.any((r) => r == p.role && g.freeStaff(r).length < 3)) g.hire(p);
    }
    g.diamonds += 3;
    g.refreshMarketPaid();
  }
  g.ownedLocations.addAll(['ist', 'kapadokya']);
  List<Staff> crew(Genre ge) => [
        for (final e in genreDefs[ge]!.needs.entries) ...g.freeStaff(e.key).take(e.value),
      ];
  g.createShow('Konaktaki Sır', Genre.dizi, 3, crew(Genre.dizi), budget: 3, guest: 2, location: 'kapadokya');
  g.createShow('Gece Yarısı', Genre.talkShow, 1, crew(Genre.talkShow), budget: 2, guest: 1);
  g.createShow('Ada Macerası', Genre.yarisma, 2,
      crew(Genre.yarisma), budget: 2);
  for (final s in g.shows) {
    g.speedUp(s);
    g.speedUp(s);
  }
  g.putOnAir(g.shows[0], SlotId.prime1);
  g.putOnAir(g.shows[1], SlotId.prime2);
  g.putOnAir(g.shows[2], SlotId.aksam1);
  g.createShow('Sabah Kuşağı', Genre.magazin, 0, crew(Genre.magazin));
  for (int d = 0; d < 4; d++) {
    g.debugAdvanceDays(1);
    g.pendingDecision = null;
    g.pendingAwards = null;
    g.pendingOffline = null;
  }
  g.cash = 3.2e9;
  g.diamonds = 240;
  g.dismissLogin();
  return g;
}

Future<void> main() async {
  final enabled = Platform.environment['SHOTS'] == '1';
  setUpAll(() async {
    await loadFonts();
    final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
    if (emoji.existsSync()) {
      final l = FontLoader('NotoColorEmoji')
        ..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())));
      await l.load();
    }
  });
  const pages = [
    PageId.home,
    PageId.production,
    PageId.broadcast,
    PageId.staff,
    PageId.studio,
    PageId.agency,
    PageId.luxury,
    PageId.brands,
  ];
  for (final (i, page) in pages.indexed) {
    testWidgets('görüntü ${page.name}', (t) async {
      if (!enabled) return;
      t.view.physicalSize = const Size(1920, 1080);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      late Game g;
      await t.runAsync(() async => g = await shotGame());
      final base = buildTheme();
      final theme = base.copyWith(
        textTheme: base.textTheme.apply(fontFamilyFallback: const ['NotoColorEmoji']),
      );
      final key = GlobalKey();
      await t.pumpWidget(RepaintBoundary(
        key: key,
        child: GameScope(
          game: g,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: DefaultTextStyle.merge(
              style: const TextStyle(fontFamilyFallback: ['NotoColorEmoji']),
              child: Shell(initial: page),
            ),
          ),
        ),
      ));
      for (int k = 0; k < 10; k++) {
        await t.pump(const Duration(milliseconds: 120));
      }
      await t.runAsync(() async {
        final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await b.toImage(pixelRatio: 2);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('store/ekran_${i + 1}_${page.name}.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
      });
      g.dispose();
    });
  }
}
