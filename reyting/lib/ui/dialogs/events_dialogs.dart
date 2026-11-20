import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';
import '../widgets/scene.dart';

/// Kriz / zam / transfer / sponsor kararı
Future<void> showDecisionDialog(BuildContext context, Game game, Decision d) {
  final kindProp = {
    'scandal': Prop.paparazzi,
    'setCrisis': Prop.livingRoom,
    'regulator': Prop.debate,
    'sponsor': Prop.redCarpet,
  }[d.kind];
  final person = d.kind == 'raise' || d.kind == 'poach';
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(
              width: 200,
              height: 160,
              child: person
                  ? Center(
                      child: PersonAvatar(
                          seed: (d.targetId ?? '').hashCode,
                          color: d.kind == 'raise' ? AppColors.yellow : AppColors.red,
                          size: 140,
                          badgeIcon: Icons.star_rounded))
                  : StageScene(
                      prop: kindProp ?? Prop.globe,
                      color: AppColors.accent,
                      tier: 2,
                      live: true,
                      height: 160),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionLabel('Karar zamanı', color: AppColors.accent),
                const SizedBox(height: 4),
                Text(d.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(d.body, style: const TextStyle(color: AppColors.textDim, height: 1.35)),
                const SizedBox(height: 12),
                for (int i = 0; i < d.options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Panel(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: AppColors.panelHi,
                      borderColor: i == 0 ? AppColors.accent.withValues(alpha: 0.6) : null,
                      onTap: () {
                        game.resolveDecision(i);
                        Navigator.pop(c);
                      },
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.options[i], style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(d.hints[i], style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                          ]),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
                      ]),
                    ),
                  ),
              ]),
            ),
          ]),
        ),
      ),
    ),
  );
}

/// Altın Anten Ödülleri töreni
Future<void> showAwardsDialog(BuildContext context, Game game, List<AwardResult> results) {
  final won = results.where((r) => r.won).length;
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760, maxHeight: 380),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(
                width: 230,
                child: StageScene(prop: Prop.awards, color: AppColors.yellow, tier: 4, live: true, height: 300)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SectionLabel('Altın Anten Ödülleri', color: AppColors.yellow),
                Text(won > 0 ? '$won ödül kazandın! 🏆' : 'Bu sefer olmadı…',
                    style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                Text(won > 0 ? 'Her ödül: +15 prestij, +3 💎' : 'Reytinglerini yükselt, 30 gün sonra yeni tören var.',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView(children: [
                    for (final r in results)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(children: [
                          Icon(r.won ? Icons.emoji_events_rounded : Icons.close_rounded,
                              color: r.won ? AppColors.yellow : AppColors.textFaint, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(r.category, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              Text('Aday: ${r.nominee}',
                                  style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                            ]),
                          ),
                          Tag(r.won ? 'KAZANDI' : 'Aday', color: r.won ? AppColors.yellow : AppColors.textDim),
                        ]),
                      ),
                  ]),
                ),
                AccentButton('Tören bitti', expand: true, onTap: () => Navigator.pop(c)),
              ]),
            ),
          ]),
        ),
      ),
    ),
  );
}
