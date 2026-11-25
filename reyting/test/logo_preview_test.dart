// Geliştirme aracı: LOGOS=1 flutter test test/logo_preview_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/data/content2.dart';
import 'package:reyting/models/models.dart';
import 'package:reyting/ui/widgets/company_logo.dart';
import 'package:reyting/ui/widgets/profile_frame.dart';

void main() {
  testWidgets('logolar', (t) async {
    if (Platform.environment['LOGOS'] != '1') return;
    t.view.physicalSize = const Size(1000, 1100);
    t.view.devicePixelRatio = 1;
    final key = GlobalKey();
    await t.pumpWidget(MaterialApp(
      home: RepaintBoundary(
        key: key,
        child: Container(
          color: const Color(0xFF130F1D),
          child: Wrap(spacing: 6, runSpacing: 6, children: [
            for (int i = 0; i < logoShapeNames.length; i++)
              CompanyLogoView(logo: CompanyLogo(shape: i, palette: i % logoPalettes.length, frame: i % logoFrameNames.length), size: 70),
            for (int i = 0; i < logoFrameNames.length; i++)
              CompanyLogoView(logo: CompanyLogo(shape: 2, palette: 1, frame: i), size: 70),
            for (int i = 0; i < logoPalettes.length; i++)
              CompanyLogoView(logo: CompanyLogo(shape: 7, palette: i, frame: 1), size: 50),
            for (final f in frameDefs)
              ProfileFrame(frame: f.id, size: 70, child: const ColoredBox(color: Colors.blueGrey)),
          ]),
        ),
      ),
    ));
    await t.pump();
    await t.runAsync(() async {
      final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final img = await b.toImage();
      final d = await img.toByteData(format: ui.ImageByteFormat.png);
      File('/tmp/claude-0/-home-user-ses-botu/d1614294-b2e5-5584-9d98-eb928e63445d/scratchpad/logos.png').writeAsBytesSync(d!.buffer.asUint8List());
    });
  });
}
