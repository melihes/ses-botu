// LEGS=1 flutter test test/legs_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/ui/widgets/face.dart';
import 'package:reyting/ui/widgets/scene.dart';

void main() {
  testWidgets('bacaklar', (t) async {
    if (Platform.environment['LEGS'] != '1') return;
    t.view.physicalSize = const Size(1000, 560);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: ColoredBox(
          color: const Color(0xFF6B5A8A),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < 5; i++)
              Column(mainAxisSize: MainAxisSize.min, children: [
                FaceView(spec: FaceSpec.of(i * 7 + 1, female: i.isOdd), cacheKey: 900 + i, crop: false, size: 190),
                CustomPaint(
                    size: const Size(190, 137),
                    painter: LegsPainter(
                        seed: i,
                        walk: i == 4 ? 0.2 : -1,
                        female: i.isOdd,
                        cloth: FaceSpec.of(i * 7 + 1, female: i.isOdd).cloth,
                        skin: FaceSpec.of(i * 7 + 1, female: i.isOdd).skin)),
              ]),
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
      File('/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/scenes/bacak.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
