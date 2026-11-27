// BULTEN=1 flutter test test/bulletin_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/ui/dialogs/bulletin.dart';
import 'package:reyting/ui/widgets/common.dart';

import 'ui_monkey_test.dart' show loadFonts, richGame;

void main() {
  setUpAll(() async {
    await loadFonts();
    final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
    if (emoji.existsSync()) {
      final l = FontLoader('NotoColorEmoji')..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())));
      await l.load();
    }
  });
  testWidgets('bülten', (t) async {
    if (Platform.environment['BULTEN'] != '1') return;
    t.view.physicalSize = const Size(800, 380);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    late final g;
    await t.runAsync(() async {
      g = await richGame();
      g.debugAway(const Duration(hours: 8));
    });
    final sum = g.pendingOffline!;
    final key = GlobalKey();
    await t.pumpWidget(RepaintBoundary(key: key, child: GameScope(
      game: g,
      child: MaterialApp(
        theme: buildTheme().copyWith(
            textTheme: buildTheme().textTheme.apply(fontFamilyFallback: const ['NotoColorEmoji'])),
        home: SizedBox(
          child: Builder(builder: (c) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => showBulletin(c, g.channelName, g.day - sum.days as int, g.day as int, sum),
                  child: const Text('aç'),
                ),
              ),
            );
          }),
        ),
      ),
    )));
    await t.tap(find.text('aç'));
    for (int i = 0; i < 120; i++) {
      await t.pump(const Duration(milliseconds: 50));
    }
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
    await t.pump(const Duration(milliseconds: 16));
    await t.runAsync(() async {
      final r = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await r.toImage();
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/amb/bulten.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
    // ignore: avoid_print
    print('başlık: ${sum.headlines.length} · gün ${sum.days}');
    g.dispose();
    await t.pumpWidget(const SizedBox());
  });
}
