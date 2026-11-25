// Geliştirme aracı: yeni karakter yüzlerini önizler.
// FACES=1 flutter test test/face_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/ui/widgets/face.dart';
import 'package:reyting/ui/widgets/item_art.dart';

void main() {
  testWidgets('yüz önizleme', (t) async {
    if (Platform.environment['FACES'] != '1') return;
    t.view.physicalSize = const Size(1200, 760);
    t.view.devicePixelRatio = 1;
    final key = GlobalKey();
    final names = <(String, int)>[];
    for (int i = 0; i < 40; i++) {
      names.add(('${firstNames[(i * 7) % firstNames.length]} X', 18 + (i * 13) % 50));
    }
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: Container(
          color: const Color(0xFF1A1626),
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            Wrap(spacing: 10, runSpacing: 10, children: [
              for (final (i, n) in names.indexed)
                PersonAvatar(seed: 1000 + i * 31, name: n.$1, age: n.$2, color: Colors.primaries[i % 18], size: 100),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              for (final m in FaceMood.values)
                FaceView(spec: FaceSpec.of(42, female: false), cacheKey: 42, mood: m, size: 140),
            ]),
          ]),
        ),
      ),
    ));
    await t.runAsync(() => Future.delayed(const Duration(milliseconds: 1500)));
    for (int i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 200)));
    }
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage();
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      File('/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/faces.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
    });
  });
}
