// AWARD=1 flutter test test/award_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/models/models.dart';
import 'package:reyting/ui/dialogs/award_ceremony.dart';

import 'ui_monkey_test.dart' show loadFonts;

void main() {
  setUpAll(() async {
    await loadFonts();
    final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
    if (emoji.existsSync()) {
      final l = FontLoader('NotoColorEmoji')..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())));
      await l.load();
    }
  });
  testWidgets('tören', (t) async {
    if (Platform.environment['AWARD'] != '1') return;
    t.view.physicalSize = const Size(800, 380);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
      theme: ThemeData(fontFamily: 'Roboto', fontFamilyFallback: const ['NotoColorEmoji']),
      home: RepaintBoundary(
        key: key,
        child: AwardCeremony(channel: 'Kanal 9', results: [
          AwardResult('Yılın dizisi', 'Konaktaki Sır', true),
          AwardResult('En iyi talk show', 'Gece Yarısı', false),
        ]),
      ),
    ));
    Future<void> shot(String n) async {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
      await t.pump(const Duration(milliseconds: 16));
      await t.runAsync(() async {
        final r = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await r.toImage();
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        File('/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/amb/odul_$n.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
      });
    }
    Future<void> wait(double s) async {
      for (int i = 0; i < s * 20; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
    }
    await wait(1.6);
    await shot('1_hali');
    await wait(4.0);
    await shot('2_zarf');
    await wait(2.6);
    await shot('3_kazandi');
    await wait(8);
    await t.pumpWidget(const SizedBox());
  });
}
