// Geliştirme aracı: kodla çizilmiş amblemi 1024x1024 PNG ikona dönüştürür.
// RENDER_ICON=1 flutter test test/render_icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/ui/widgets/brand_logo.dart';

void main() {
  final enabled = Platform.environment['RENDER_ICON'] == '1';
  testWidgets('ikon üret', (t) async {
    final key = GlobalKey();
    await t.binding.setSurfaceSize(const Size(1024, 1024));
    await t.pumpWidget(
      RepaintBoundary(
        key: key,
        child: Container(
          width: 1024,
          height: 1024,
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.2),
              radius: 0.9,
              colors: [Color(0xFF3A2A8C), Color(0xFF140E38)],
            ),
          ),
          alignment: Alignment.center,
          child: const SizedBox(
            width: 820,
            height: 820,
            child: CustomPaint(painter: CrestPainter()),
          ),
        ),
      ),
    );
    await t.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await boundary.toImage();
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('assets/brand/icon_generated.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  }, skip: !enabled);
}
