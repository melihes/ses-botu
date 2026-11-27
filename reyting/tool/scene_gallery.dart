// Geliştirme aracı: tüm sahneleri tek ekranda gösterir (oyuna dahil değil).
// flutter build web -t tool/scene_gallery.dart
import 'package:flutter/material.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/ui/widgets/scene.dart';

void main() {
  final page = Uri.base.queryParameters['p'] ?? '0';
  final items = <(Prop, Color, int, String)>[];
  for (final g in Genre.values) {
    final fs = genreFormats[g]!;
    for (int i = 0; i < fs.length; i++) {
      items.add((fs[i].prop, genreDefs[g]!.color, i, fs[i].name));
    }
  }
  items.add((Prop.film, AppColors.orange, 2, 'Film'));
  items.add((Prop.studio, AppColors.purple, 1, 'Stüdyo'));
  final start = int.parse(page) * 12;
  runApp(MaterialApp(
    theme: buildTheme(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(6),
        child: Wrap(spacing: 6, runSpacing: 6, children: [
          for (final it in items.skip(start).take(12))
            StageScene(prop: it.$1, color: it.$2, tier: it.$3, live: true, width: 206, height: 124, badge: it.$4),
        ]),
      ),
    ),
  ));
}
