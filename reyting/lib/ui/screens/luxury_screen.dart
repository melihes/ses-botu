import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../dialogs/negotiation_dialog.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

class LuxuryScreen extends StatefulWidget {
  const LuxuryScreen({super.key});
  @override
  State<LuxuryScreen> createState() => _LuxuryScreenState();
}

class _LuxuryScreenState extends State<LuxuryScreen> {
  int _cat = 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final cat = LuxCat.values[_cat];
    final items = luxuryDefs.where((d) => d.cat == cat).toList();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Expanded(
              child: PillTabs(
                labels: [for (final c in LuxCat.values) c.label],
                selected: _cat,
                onChanged: (i) => setState(() => _cat = i),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PageHint(
          'Prestijin (${fmtInt(game.prestige)}) reklam fiyatlarını '
          '${fmtPct(game.adBonus * 100, 1)} artırıyor (en fazla %30). '
          'Yat, jet, ada ve özel parçalarda pazarlık yapılır.',
        ),
        AutoGrid(
          minItemWidth: 280,
          spacing: 10,
          children: [for (final d in items) _LuxCard(d: d)],
        ),
      ],
    );
  }
}

class _LuxCard extends StatelessWidget {
  final LuxuryDef d;
  const _LuxCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final owned = game.ownedLuxury.contains(d.id);
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: owned ? AppColors.green.withValues(alpha: 0.6) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemArt(
            id: d.id,
            color: d.cat.color,
            width: 110,
            height: 96,
            badge: d.negotiable ? 'PAZARLIK' : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  d.desc,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      fmtShort(d.price),
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tag(
                      '+${d.prestige} prestij',
                      color: AppColors.yellow,
                      icon: Icons.star_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (owned)
                  Row(
                    children: [
                      const Tag('SENİN ✓', color: AppColors.green),
                      const Spacer(),
                      GhostButton(
                        'Sat · ${fmtShort(game.sellValueLuxury(d))}',
                        compact: true,
                        color: AppColors.textDim,
                        onTap: () async {
                          final ok = await confirm(
                            context,
                            '${d.name} satılsın mı?',
                            'Alış fiyatının %70\'i kasana girer.',
                            ok: 'Sat',
                          );
                          if (ok) game.sellLuxury(d);
                        },
                      ),
                    ],
                  )
                else if (d.negotiable)
                  AccentButton(
                    'Pazarlık yap',
                    compact: true,
                    icon: Icons.handshake_rounded,
                    onTap: () => showNegotiation(
                      context,
                      id: d.id,
                      name: d.name,
                      subtitle: d.desc,
                      price: d.price,
                      icon: d.cat.icon,
                      color: d.cat.color,
                    ),
                  )
                else
                  AccentButton(
                    'Satın al',
                    compact: true,
                    icon: Icons.shopping_bag_rounded,
                    onTap: () => report(context, game.buyFixed(d)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
