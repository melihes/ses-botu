// Geliştirme aracı: tüm eşya resimleri (oyuna dahil değil).
import 'package:flutter/material.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/ui/widgets/item_art.dart';

void main() {
  final items = <(String, Color)>[
    for (final l in luxuryDefs) (l.id, l.cat.color),
    for (final e in equipDefs) (e.id, AppColors.cyan),
    for (final b in bizDefs) (b.id, b.color),
  ];
  runApp(MaterialApp(
    theme: buildTheme(),
    home: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(4),
        child: Wrap(spacing: 4, runSpacing: 4, children: [
          for (final it in items) ItemArt(id: it.$1, color: it.$2, width: 92, height: 74, badge: it.$1),
        ]),
      ),
    ),
  ));
}
