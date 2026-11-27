// BODIES=1 flutter test test/bodies_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/ui/widgets/face.dart';

import 'ui_monkey_test.dart' show loadFonts;

void main() {
  setUpAll(loadFonts);
  testWidgets('gövdeler', (t) async {
    if (Platform.environment['BODIES'] != '1') return;
    t.view.physicalSize = const Size(1300, 700);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    final base = FaceSpec.of(5);
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: const Color(0xFF8899AA),
          child: Wrap(children: [
            for (int b = 1; b <= 25; b++)
              SizedBox(
                width: 140,
                height: 170,
                child: Column(children: [
                  FaceView(
                    spec: FaceSpec(
                      hair: base.hair, body: b, brows: base.brows, eyes: base.eyes, nose: base.nose,
                      lips: base.lips, beard: null, glasses: null, skin: base.skin, hairColor: base.hairColor,
                      cloth: const Color(0xFFE8590C), female: false),
                    cacheKey: 5000 + b,
                    crop: false,
                    size: 140,
                  ),
                  Text('$b', style: const TextStyle(fontSize: 14, color: Colors.black)),
                ]),
              ),
          ]),
        ),
      ),
    ));
    await t.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    await t.pump();
    await t.runAsync(() async {
      final r = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await r.toImage();
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/scenes/govdeler.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
