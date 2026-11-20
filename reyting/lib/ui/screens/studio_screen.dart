import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../widgets/common.dart';

class StudioScreen extends StatelessWidget {
  const StudioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final cur = game.studio;
    final hasNext = game.studioLevel < studioLevels.length - 1;
    final next = hasNext ? studioLevels[game.studioLevel + 1] : null;
    final nextSlots = SlotId.values
        .where((s) => slotDefs[s]!.unlockLevel == game.studioLevel + 2)
        .map((s) => slotDefs[s]!.label)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Panel(
          gradient: const LinearGradient(
              colors: [Color(0xFF2E1F45), AppColors.panel]),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const ArtTile(
                icon: Icons.domain_rounded, color: AppColors.purple, size: 110),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel('Seviye ${game.studioLevel + 1}/${studioLevels.length}'),
                  Text(cur.name,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 20, runSpacing: 8, children: [
                    StatBlock('Erişim', fmtPct(game.reach * 100, 0),
                        color: AppColors.cyan),
                    StatBlock('Kira/gün', fmtShort(cur.rentPerDay),
                        color: AppColors.orange),
                    StatBlock('Kadro sınırı', '${cur.maxStaff}'),
                    StatBlock(
                        'Açık kuşak',
                        '${SlotId.values.where(game.slotUnlocked).length}/4'),
                  ]),
                ],
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 260,
              child: next == null
                  ? const Text('🏆 Medya imparatorluğunun zirvesindesin!',
                      style: TextStyle(fontWeight: FontWeight.w800))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionLabel('Sonraki seviye',
                            color: AppColors.accent),
                        Text(next.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w900, fontSize: 16)),
                        Text(
                            'Erişim ${fmtPct(next.reach * 100, 0)} · '
                            'kadro ${next.maxStaff} · kira ${fmtShort(next.rentPerDay)}'
                            '${nextSlots.isEmpty ? '' : ' · ${nextSlots.join(', ')} kuşağı açılır'}',
                            style: const TextStyle(
                                color: AppColors.textDim, fontSize: 12)),
                        const SizedBox(height: 8),
                        AccentButton('Yükselt · ${fmtShort(next.upgradeCost)}',
                            expand: true,
                            icon: Icons.upgrade_rounded,
                            onTap: () => report(context, game.upgradeStudio())),
                      ],
                    ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        const SectionLabel('Ekipman, araç ve tesisler'),
        const SizedBox(height: 4),
        const PageHint(
            'Kalıcı yatırımlar. Bir kez alınır, her gün küçük bir bakım gideri vardır. '
            'Bazıları yeni program türlerinin kilidini açar.'),
        AutoGrid(minItemWidth: 280, spacing: 10, children: [
          for (final e in equipDefs) _EquipCard(e: e),
        ]),
      ],
    );
  }
}

class _EquipCard extends StatelessWidget {
  final EquipDef e;
  const _EquipCard({required this.e});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final owned = game.ownedEquip.contains(e.id);
    final locked = game.studioLevel + 1 < e.reqLevel;
    final unlocksGenre = genreDefs.values
        .where((g) => g.reqEquip == e.id)
        .map((g) => g.label)
        .toList();
    final effects = <String>[
      if (e.qualityBonus > 0)
        'Kalite +${fmtPct(e.qualityBonus * 100, 0)}'
            '${e.boosts.isEmpty ? ' (tüm türler)' : ' (${e.boosts.map((g) => genreDefs[g]!.label).join(', ')})'}',
      if (e.prodSpeed < 1)
        'Çekim süresi -${fmtPct((1 - e.prodSpeed) * 100, 0)}',
      if (e.reachBonus > 0) 'Erişim +${fmtPct(e.reachBonus * 100, 0)}',
      if (unlocksGenre.isNotEmpty) '${unlocksGenre.join(', ')} türünü açar',
    ];
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: owned ? AppColors.green.withValues(alpha: 0.6) : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ArtTile(
            icon: e.icon,
            color: owned ? AppColors.green : AppColors.cyan,
            size: 64),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.name,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text(e.desc,
                  style:
                      const TextStyle(color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 4),
              for (final f in effects)
                Text('• $f',
                    style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              Text('Bakım: ${fmtShort(e.upkeepPerDay)}/gün',
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 11)),
              const SizedBox(height: 8),
              if (owned)
                const Tag('SAHİPSİN ✓', color: AppColors.green)
              else if (locked)
                Tag('Stüdyo seviyesi ${e.reqLevel}',
                    color: AppColors.textDim, icon: Icons.lock_rounded)
              else
                AccentButton('Satın al · ${fmtShort(e.price)}',
                    compact: true,
                    onTap: () => report(context, game.buyEquip(e))),
            ],
          ),
        ),
      ]),
    );
  }
}
