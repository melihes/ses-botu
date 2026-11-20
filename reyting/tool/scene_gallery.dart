// Geliştirme aracı: tüm sahneleri tek ekranda gösterir (oyuna dahil değil).
// flutter build web -t tool/scene_gallery.dart
import 'package:flutter/material.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/data/content.dart';
import 'package:reyting/ui/widgets/scene.dart';

void main() => runApp(MaterialApp(
      theme: buildTheme(),
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final g in Genre.values)
              StageScene(
                  kind: sceneForGenre(g),
                  color: genreDefs[g]!.color,
                  tier: g.index % 3,
                  live: true,
                  width: 200,
                  height: 120,
                  badge: '${genreDefs[g]!.label} · bütçe ${g.index % 3}'),
            const StageScene(
                kind: SceneKind.studio,
                color: AppColors.purple,
                width: 200,
                height: 120,
                badge: 'Stüdyo'),
          ]),
        ),
      ),
    ));
