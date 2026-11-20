// Geliştirme aracı: karar ve tören pencerelerini önizler (oyuna dahil değil).
import 'package:flutter/material.dart';
import 'package:reyting/core/theme.dart';
import 'package:reyting/engine/game.dart';
import 'package:reyting/models/models.dart';
import 'package:reyting/ui/dialogs/events_dialogs.dart';
import 'package:reyting/ui/widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final g = Game();
  await g.start();
  final which = Uri.base.queryParameters['d'] ?? 'decision';
  runApp(GameScope(
    game: g,
    child: MaterialApp(
      theme: buildTheme(),
      home: Builder(builder: (ctx) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (which == 'awards') {
            showAwardsDialog(ctx, g, [
              AwardResult('Yılın Yarışma Programı', 'Şans Çarkı', true),
              AwardResult('Yılın Dizi Programı', 'Konaktaki Sır', false),
              AwardResult('En İyi Film', 'Son Kurşun', true),
            ]);
          } else {
            g.pendingDecision = (Decision(
              kind: which, title: '📰 Skandal manşetlerde!',
              body: '"Kırmızı Halı" kulis dedikodusuyla gazetelerde. Ne yapacaksın?',
              options: ['Kamuoyundan özür dile', 'Sessiz kal', 'Avukat tut'],
              hints: ['Reyting biraz düşer, +10 prestij', 'Kumar: reyting uçabilir ya da çakılır', '150 B ₺, risk yok'],
              targetId: 'x')..deadline = g.gameTime + 0.6);
            g.showToast('');
          }
        });
        return const Scaffold(
            body: Stack(children: [
          Positioned(top: 64, left: 94, right: 10, child: Center(child: DecisionCard())),
        ]));
      }),
    ),
  ));
}
