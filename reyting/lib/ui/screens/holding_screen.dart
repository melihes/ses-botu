import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/economy.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

class HoldingScreen extends StatelessWidget {
  const HoldingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final owned = bizDefs.where((b) => game.bizLevel(b.id) > 0).length;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Panel(
          child: Row(
            children: [
              Expanded(
                child: StatBlock('İşletmeler', '$owned/${bizDefs.length}'),
              ),
              Expanded(
                child: StatBlock(
                  'Günlük gelir',
                  fmtSigned(game.bizIncomePerDay),
                  color: AppColors.green,
                ),
              ),
              Expanded(
                child: StatBlock(
                  'Reklam bonusu',
                  fmtPct(game.bizEffect(BizEffect.adRate) * 100, 0),
                  color: AppColors.cyan,
                ),
              ),
              Expanded(
                child: StatBlock(
                  'Gişe bonusu',
                  fmtPct(game.boxOfficeBonus * 100, 0),
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const PageHint(
          'Yan işletmeler hem her gün gelir getirir hem de oyunun başka bir '
          'bölümünü güçlendirir. Her biri 5 seviyeye kadar büyür; etkiler kalıcıdır.',
        ),
        AutoGrid(
          minItemWidth: 300,
          spacing: 10,
          children: [for (final b in bizDefs) _BizCard(b: b)],
        ),
      ],
    );
  }
}

class _BizCard extends StatelessWidget {
  final BizDef b;
  const _BizCard({required this.b});

  String _effect(int level) {
    final v = b.perLevel * level;
    final txt = switch (b.effect) {
      BizEffect.marketSkill || BizEffect.prestige => fmtInt(v),
      _ => fmtPct(v * 100, 0),
    };
    return b.effectText.replaceAll('{v}', txt);
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final lv = game.bizLevel(b.id);
    final locked = game.studioLevel + 1 < b.reqLevel;
    final maxed = lv >= bizMaxLevel;
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: lv > 0 ? b.color.withValues(alpha: 0.6) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemArt(
            id: b.id,
            color: b.color,
            width: 96,
            height: 84,
            badge: lv > 0 ? 'SV $lv' : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  b.desc,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                // Seviye noktaları
                Row(
                  children: [
                    for (int i = 0; i < bizMaxLevel; i++)
                      Container(
                        width: 18,
                        height: 6,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          color: i < lv ? b.color : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  lv == 0
                      ? 'Kurulunca: ${_effect(1)} · +${fmtShort(bizIncome(b, 1))}/gün'
                      : '${_effect(lv)} · +${fmtShort(bizIncome(b, lv))}/gün',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (lv > 0 && !maxed)
                  Text(
                    'Sonraki: ${_effect(lv + 1)} · +${fmtShort(bizIncome(b, lv + 1))}/gün',
                    style: const TextStyle(
                      color: AppColors.textFaint,
                      fontSize: 11,
                    ),
                  ),
                const SizedBox(height: 8),
                if (maxed)
                  const Tag('EN ÜST SEVİYE ✓', color: AppColors.green)
                else if (locked)
                  Tag(
                    'Stüdyo seviyesi ${b.reqLevel}',
                    color: AppColors.textDim,
                    icon: Icons.lock_rounded,
                  )
                else
                  AccentButton(
                    '${lv == 0 ? 'Kur' : 'Yükselt'} · ${fmtShort(bizUpgradeCost(b, lv))}',
                    compact: true,
                    icon: lv == 0
                        ? Icons.add_business_rounded
                        : Icons.upgrade_rounded,
                    onTap: () => report(context, game.upgradeBiz(b)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
