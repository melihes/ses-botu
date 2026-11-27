// Arayüz "maymun" testi: her sayfadaki her tıklanabilir şeye tek tek basar.
// Yakalanan: çökme (exception), taşma (RenderFlex overflow), başka bir şeyin
// altında kalıp basılamayan butonlar.
// flutter test test/ui_monkey_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/sfx.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:reyting/ui/shell.dart';
import 'package:reyting/ui/widgets/common.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Her şeyi açılmış, dolu bir oyun
Future<Game> richGame({bool poor = false}) async {
  SharedPreferences.setMockInitialValues({});
  final g = Game();
  await g.start();
  g.introSeen = true;
  g.identitySet = true;
  g.dismissLogin();
  g.stingOn = false;
  g.cash = poor ? 1000 : 5e9;
  g.studioLevel = poor ? 0 : 6;
  g.diamonds = poor ? 0 : 200;
  if (poor) return g;
  g.ownedLocations.addAll(['ist', 'kapadokya', 'paris']);
  for (int i = 0; i < 3; i++) {
    g.upgradeAgency();
  }
  for (final y in g.youthMarket.take(2).toList()) {
    g.signYouth(y);
  }
  var k = 0;
  for (final r in Role.values) {
    for (int i = 0; i < 3; i++) {
      final sk = 55 + (k * 7) % 40;
      g.staff.add(
        Staff(
          id: 'pv$k',
          name: 'Kişi $k',
          role: r,
          skill: sk,
          salary: 1500 + sk * sk * 3.0,
          trait: k % 9,
          age: 22 + k,
        ),
      );
      k++;
    }
  }
  g.debugAdvanceDays(1);
  for (final e
      in g.execCandidates.where((e) => e.skill > 80).take(2).toList()) {
    g.hireExec(e);
  }
  List<Staff> crew(Genre ge) => [
    for (final e in genreDefs[ge]!.needs.entries)
      ...g.freeStaff(e.key).take(e.value),
  ];
  g.createShow(
    'Konaktaki Sır',
    Genre.dizi,
    3,
    crew(Genre.dizi),
    budget: 3,
    guest: 2,
    location: 'kapadokya',
  );
  g.createShow(
    'Gece Yarısı',
    Genre.talkShow,
    1,
    crew(Genre.talkShow),
    budget: 2,
    guest: 1,
  );
  for (final s in g.shows) {
    g.speedUp(s);
  }
  g.putOnAir(g.shows[1], SlotId.prime1);
  g.createShow('Bekleyen', Genre.magazin, 0, crew(Genre.magazin));
  g.speedUp(g.shows.first);
  for (int i = 0; i < 3; i++) {
    g.debugSpawnBrand();
  }
  g.staff.first.fame = 60;
  g.toggleForSale(g.staff.first);
  g.debugAdvanceDays(1.3);
  g.pendingDecision = null;
  g.pendingAwards = null;
  g.pendingOffline = null;
  g.dismissLogin();
  return g;
}

/// Gerçek yazı tipleri (test yazı tipi kare harfli ve çok geniş; sahte taşma verir)
Future<void> loadFonts() async {
  const dir = '/opt/flutter/bin/cache/artifacts/material_fonts';
  final roboto = FontLoader('Roboto');
  for (final w in ['Regular', 'Medium', 'Bold', 'Black', 'Light', 'Italic']) {
    final f = File('$dir/Roboto-$w.ttf');
    if (f.existsSync())
      roboto.addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
  }
  await roboto.load();
  final icons = FontLoader('MaterialIcons');
  icons.addFont(
    Future.value(
      ByteData.sublistView(
        File('$dir/MaterialIcons-Regular.otf').readAsBytesSync(),
      ),
    ),
  );
  await icons.load();
}

Future<void> main() async {
  Sfx.enabled = false;
  setUpAll(loadFonts);
  final problems = <String>[];

  Future<void> runPage(
    WidgetTester tester,
    PageId page, {
    bool poor = false,
  }) async {
    tester.view.physicalSize = _screen;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final errors = <String>[];
    final old = FlutterError.onError;
    var current = 'açılış';
    if (!const bool.fromEnvironment('RAWERR'))
      FlutterError.onError = (d) {
        if (!d.exceptionAsString().contains('overflowed')) {
          // ignore: avoid_print
          print(
            'YAKALANDI: ${d.exception}\n${d.stack.toString().split('\n').take(12).join('\n')}',
          );
        }
        try {
          final where =
              RegExp(r'lib/[\w/]+\.dart:\d+')
                  .firstMatch(d.toString())
                  ?.group(0) ??
              '?';
          errors.add(
            '${d.exceptionAsString().split('\n').first} @ $where (adım: $current)',
          );
        } catch (_) {
          errors.add('hata (adım: $current)');
        }
      };

    addTearDown(() => FlutterError.onError = old);
    late Game g;
    await tester.runAsync(() async => g = await richGame(poor: poor));
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      GameScope(
        game: g,
        child: MaterialApp(
          navigatorKey: nav,
          theme: buildTheme(),
          home: Shell(initial: page),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    bool tappable(Widget w) =>
        (w is InkWell && w.onTap != null) ||
        (w is GestureDetector && w.onTap != null) ||
        (w is ButtonStyleButton && w.onPressed != null) ||
        (w is IconButton && w.onPressed != null) ||
        (w is ChoiceChip && w.onSelected != null);
    Finder inPage() => find.descendant(
      of: find.byKey(ValueKey(page)),
      matching: find.byWidgetPredicate(tappable),
    );
    final all = page == PageId.home
        ? find.byWidgetPredicate(tappable)
        : inPage();
    final total = all.evaluate().length;
    final obscured = <String>{};
    for (int i = 0; i < total; i++) {
      // her basıştan önce sayfayı ve açık pencereleri temizle
      var guard = 0;
      while (nav.currentState!.canPop()) {
        if (++guard > 20) {
          errors.add('Kapatılamayan pencere (adım: $current)');
          break;
        }
        nav.currentState!.pop();
        await tester.pump(const Duration(milliseconds: 50));
      }
      if (const bool.fromEnvironment('MDEBUG')) print('   temiz');
      ShellNav.go(
        tester.element(
          find.byType(Shell).first.evaluate().isEmpty
              ? find.byType(Scaffold).first
              : find.byType(Scaffold).first,
        ),
        page,
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(
        const Duration(milliseconds: 200),
      ); // sayfa geçiş animasyonu bitsin
      final list =
          (page == PageId.home ? find.byWidgetPredicate(tappable) : inPage())
              .evaluate()
              .toList();
      if (i >= list.length) break;
      final f = find.byWidget(list[i].widget);
      final label = _labelOf(list[i]);
      current = label;
      if (const bool.fromEnvironment('MDEBUG')) print('[$i] $label');
      try {
        await tester.ensureVisible(f.first);
        await tester.pump(const Duration(milliseconds: 50));
      } catch (_) {}
      if (f.hitTestable().evaluate().isEmpty) {
        final r = tester.getRect(f.first);
        final screen = Offset.zero & _screen;
        if (screen.contains(r.center)) {
          final anc = <String>[];
          list[i].visitAncestorElements((a) {
            final t = a.widget.runtimeType.toString();
            if (!t.startsWith('_') && anc.length < 12) anc.add(t);
            return anc.length < 12;
          });
          obscured.add(
            label.trim().isEmpty
                ? '${anc.join('<')} ${list[i].widget.runtimeType} @ ${r.topLeft.dx.round()},${r.topLeft.dy.round()} ${r.width.round()}x${r.height.round()}'
                : label,
          );
        }
        continue;
      }
      await tester.tap(f.first, warnIfMissed: false);
      for (int p = 0; p < 4; p++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      final ex = tester.takeException();
      if (ex != null)
        errors.add('"$label" basınca: ${ex.toString().split('\n').first}');
      // açılan pencerenin içindeki butonlara da bas (ilk 6)
      if (nav.currentState!.canPop()) {
        final inner = find
            .byWidgetPredicate(tappable)
            .hitTestable()
            .evaluate()
            .take(6)
            .toList();
        for (final e in inner) {
          if (!nav.currentState!.canPop()) break;
          if (!e.mounted) continue; // önceki basış pencereyi kapatmış olabilir
          final fi = find.byWidget(e.widget);
          if (fi.hitTestable().evaluate().isEmpty) continue;
          if (const bool.fromEnvironment('MDEBUG'))
            print('   iç: ${_labelOf(e)}');
          await tester.tap(fi.first, warnIfMissed: false);
          if (const bool.fromEnvironment('MDEBUG')) print('   tıklandı');
          await tester.pump(const Duration(milliseconds: 120));
          if (const bool.fromEnvironment('MDEBUG')) print('   pump');
          final ex2 = tester.takeException();
          if (ex2 != null)
            errors.add('"$label" içinde: ${ex2.toString().split('\n').first}');
        }
      }
    }
    while (nav.currentState!.canPop()) {
      nav.currentState!.pop();
      await tester.pump(const Duration(milliseconds: 50));
    }
    FlutterError.onError = old;
    for (final e in {...errors}) {
      problems.add('[${page.name}${poor ? '/fakir' : ''}] $e');
    }
    for (final o in obscured) {
      problems.add(
        '[${page.name}${poor ? '/fakir' : ''}] üstü kapalı buton: $o',
      );
    }
    // ignore: avoid_print
    print(
      '${page.name}${poor ? '/fakir' : ''}: $total tıklanabilir, ${errors.toSet().length} hata, ${obscured.length} kapalı',
    );
    g.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  for (final poor in [false, true]) {
    for (final page in PageId.values) {
      testWidgets(
        'maymun: ${page.name}${poor ? ' (fakir)' : ''}',
        (t) => runPage(t, page, poor: poor),
      );
    }
  }
  tearDownAll(() {
    // ignore: avoid_print
    print(
      '\n===== SORUNLAR (${problems.length}) =====\n${problems.join('\n')}',
    );
  });
}

String _labelOf(Element e) {
  final texts = <String>[];
  void visit(Element c) {
    final w = c.widget;
    if (w is Text && w.data != null) texts.add(w.data!);
    if (w is Icon && texts.isEmpty)
      texts.add('ikon:${w.icon?.codePoint.toRadixString(16)}');
    if (texts.length < 2) c.visitChildElements(visit);
  }

  visit(e);
  return texts.isEmpty
      ? e.widget.runtimeType.toString()
      : texts.join(' ').replaceAll('\n', ' ');
}

/// MONKEY_SMALL=1: küçük telefon (640x360) ile dene
final Size _screen = Platform.environment['MONKEY_SMALL'] == '1'
    ? const Size(640, 360)
    : const Size(915, 412);
