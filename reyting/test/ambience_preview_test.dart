// AMB=1 flutter test test/ambience_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/calendar.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/ui/widgets/ambience.dart';
import 'package:reyting/ui/widgets/scene.dart';

import 'ui_monkey_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  final cases = [
    ('sabah_ramazan', const Ambience(7.5, TvSeason.bahar, {'ramazan'}), Prop.morning, 0.5),
    ('gunduz_bahar', const Ambience(13, TvSeason.bahar, {}), Prop.livingRoom, 0.5),
    ('aksam_29ekim', const Ambience(18.5, TvSeason.acilis, {'cumhuriyet'}), Prop.newsDesk, 0.5),
    ('gece_yilbasi', const Ambience(23, TvSeason.kis, {'yilbasi'}), Prop.nightShow, 0.9),
    ('gece_kis_sikici', const Ambience(22, TvSeason.kis, {}), Prop.quiz, 0.1),
    ('sevgililer_cosku', const Ambience(20, TvSeason.kis, {'sevgililer'}), Prop.voice, 0.95),
  ];
  for (final (name, amb, prop, aud) in cases) {
    testWidgets('ortam $name', (t) async {
      if (Platform.environment['AMB'] != '1') return;
      Ambience.debug = amb;
      addTearDown(() => Ambience.debug = null);
      t.view.physicalSize = const Size(400, 230);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      final key = GlobalKey();
      await t.pumpWidget(MaterialApp(
        home: RepaintBoundary(
          key: key,
          child: StageScene(seed: 4, prop: prop, color: const Color(0xFFFF4F8B), audience: aud, width: 400, height: 230),
        ),
      ));
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 1500)));
      await t.pump(const Duration(milliseconds: 50));
      await t.runAsync(() async {
        final r = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await r.toImage();
        final data = await img.toByteData(format: ui.ImageByteFormat.png);
        Directory('/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/amb').createSync(recursive: true);
        File('/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/amb/$name.png')
            .writeAsBytesSync(data!.buffer.asUint8List());
      });
    });
  }
}
