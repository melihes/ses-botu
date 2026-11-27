// Geliştirme aracı: ana ekran sahnelerinin önizlemesi.
// SCENES=1 flutter test test/scene_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/ui/widgets/scene.dart';

import 'ui_monkey_test.dart' show loadFonts;

const out = '/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/scenes';

void main() {
  setUpAll(loadFonts);
  testWidgets('sahneler', (t) async {
    if (Platform.environment['SCENES'] != '1') return;
    t.view.physicalSize = const Size(1200, 760);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    final props = Platform.environment['OUTFIT'] == '1'
        ? [Prop.newsDesk, Prop.redCarpet, Prop.sportsDesk, Prop.kidsStage, Prop.police, Prop.palace, Prop.nature, Prop.quiz]
        : [Prop.nightShow, Prop.livingRoom, Prop.quiz, Prop.sitcom];
    final perProp = Platform.environment['OUTFIT'] == '1' ? 2 : 4;
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: Colors.black,
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            if (Platform.environment['FILMS'] == '1')
              for (final g in FilmGenre.values)
                StageScene(seed: g.index * 3, prop: Prop.filmSet, filmGenre: g, color: const Color(0xFFFF4F8B), width: 390, height: 180)
            else
              for (final p in props)
                for (int s = 0; s < perProp; s++)
                  StageScene(seed: s * 5 + 1, prop: p, color: const Color(0xFFFF4F8B), width: 290, height: 180),
          ]),
        ),
      ),
    ));
    await t.runAsync(() => Future.delayed(const Duration(seconds: 3)));
    await t.pump(const Duration(milliseconds: 100));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 600)));
    await t.pump(const Duration(milliseconds: 100));
    await t.runAsync(() async {
      final r = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await r.toImage();
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      Directory(out).createSync(recursive: true);
      File('$out/${Platform.environment['FILMS'] == '1' ? 'filmler' : (Platform.environment['OUTFIT'] == '1' ? 'kiyafet' : 'sahneler')}.png').writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
