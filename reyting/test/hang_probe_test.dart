import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reyting/core/sfx.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/ui/shell.dart';
import 'package:reyting/ui/widgets/common.dart';

import 'ui_monkey_test.dart' show richGame, loadFonts;

void main() {
  Sfx.enabled = false;
  setUpAll(loadFonts);
  testWidgets('görev ödülü', (tester) async {
    tester.view.physicalSize = const Size(915, 412);
    tester.view.devicePixelRatio = 1;
    late Game g;
    await tester.runAsync(() async => g = await richGame());
    g.missions.last.progress = g.missions.last.target;
    await tester.pumpWidget(
      GameScope(
        game: g,
        child: MaterialApp(theme: buildTheme(), home: const Shell()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('0/3'));
    await tester.pump(const Duration(milliseconds: 300));
    for (int k = 0; k < 4; k++) {
      final d = find.text('Devam ediyor');
      if (d.evaluate().isEmpty) break;
      await tester.tap(d.first, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 120));
    }
    await tester.tap(find.text('Ödülü al').first, warnIfMissed: false);
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
    g.dispose();
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 3));
  });
}
