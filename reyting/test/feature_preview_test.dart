// Geliştirme aracı: yeni sayfaların önizlemesi (telefon boyutu).
// FEATURES=1 flutter test test/feature_preview_test.dart
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

import 'store_shots_test.dart' show shotGame;
import 'ui_monkey_test.dart' show loadFonts;

const out = '/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/features';

Future<void> main() async {
  setUpAll(() async {
    await loadFonts();
    final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
    if (emoji.existsSync()) {
      final l = FontLoader('NotoColorEmoji')
        ..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())));
      await l.load();
    }
  });
  for (final page in [PageId.social, PageId.calendar, PageId.home, PageId.staff]) {
    testWidgets('önizleme ${page.name}', (t) async {
      if (Platform.environment['FEATURES'] != '1') return;
      t.view.physicalSize = const Size(1600, 760);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      late Game g;
      await t.runAsync(() async {
        g = await shotGame();
        g.setDramaLevel(3);
        for (int i = 0; i < 70; i++) {
          g.debugAdvanceDays(1);
          if (g.pendingDecision != null) g.resolveDecision(0);
          g.pendingAwards = null;
          g.pendingOffline = null;
        }
        g.cash = 3e9;
      });
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
        final img = await b.toImage(pixelRatio: 1);
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory(out).createSync(recursive: true);
        File('$out/${page.name}.png').writeAsBytesSync(data!.buffer.asUint8List());
      });
      g.dispose();
    });
  }
}
