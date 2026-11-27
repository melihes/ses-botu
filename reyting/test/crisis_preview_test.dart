// Geliştirme aracı: canlı yayın krizi animasyonundan kareler.
// CRISIS=1 flutter test test/crisis_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/models/models.dart';
import 'package:reyting/ui/screens/live_view.dart';
import 'package:reyting/ui/widgets/common.dart';

import 'ui_monkey_test.dart' show loadFonts, richGame;

const out = '/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/crisis';

void main() {
  setUpAll(() async {
    await loadFonts();
    final emoji = File('/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf');
    if (emoji.existsSync()) {
      final l = FontLoader('NotoColorEmoji')
        ..addFont(Future.value(ByteData.sublistView(emoji.readAsBytesSync())));
      await l.load();
    }
  });
  for (final size in const [Size(800, 360), Size(640, 360)]) {
    testWidgets('kriz ${size.width.round()}', (t) async {
      if (Platform.environment['CRISIS'] != '1') return;
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      late final g;
      await t.runAsync(() async => g = await richGame());
      final s = (g.shows as List<Show>).firstWhere((x) => x.status == ShowStatus.onAir);
      final key = GlobalKey();
      await t.pumpWidget(GameScope(
        game: g,
        child: MaterialApp(
          theme: buildTheme().copyWith(
            textTheme: buildTheme().textTheme.apply(fontFamilyFallback: const ['NotoColorEmoji']),
          ),
          home: RepaintBoundary(
            key: key,
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontFamilyFallback: ['NotoColorEmoji']),
              child: Scaffold(body: LiveView(show: s)),
            ),
          ),
        ),
      ));
      Future<void> shot(String name) async {
        await t.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
        await t.pump(const Duration(milliseconds: 16));
        await t.runAsync(() async {
          final r = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await r.toImage();
          final data = await img.toByteData(format: ui.ImageByteFormat.png);
          Directory(out).createSync(recursive: true);
          File('$out/${size.width.round()}_$name.png').writeAsBytesSync(data!.buffer.asUint8List());
        });
      }
      // krize kadar ilerle (en geç 32 sn)
      for (int i = 0; i < 33 * 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
        if (find.text('⚠ CANLI YAYIN KRİZİ').evaluate().isNotEmpty) break;
      }
      Future<void> wait(int ms) async {
        for (int i = 0; i < ms ~/ 50; i++) {
          await t.pump(const Duration(milliseconds: 50));
        }
      }
      await wait(500);
      await shot('1_giris');
      await wait(2400);
      await shot('2_secim');
      final opt = find.textContaining('Şans %');
      await t.tap(opt.first, warnIfMissed: false);
      await wait(700);
      await shot('3_gerilim');
      await wait(2500);
      await shot('4_sonuc');
      await wait(5000);
      g.dispose();
      await t.pumpWidget(const SizedBox());
    });
  }
}
