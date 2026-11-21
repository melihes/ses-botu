import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

String _num(double v) => fmtShort(v).replaceAll(' ₺', '');

class DigitalScreen extends StatefulWidget {
  const DigitalScreen({super.key});
  @override
  State<DigitalScreen> createState() => _DigitalScreenState();
}

class _DigitalScreenState extends State<DigitalScreen> {
  late int _tab = GameScope.read(context).creators.isEmpty ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final list = _tab == 0 ? game.creators : game.creatorMarket;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Panel(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              const ItemArt(
                id: 'videom',
                color: AppColors.accent,
                width: 90,
                height: 64,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${game.channelName} · $videoPlatformName kanalı',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    const Text(
                      'YouTuber\'lar senin için video çeker, takipçileri büyüdükçe gelir artar.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatBlock(
                'Takipçi',
                _num(game.totalFollowers),
                color: AppColors.cyan,
              ),
              const SizedBox(width: 14),
              StatBlock(
                'Net/gün',
                fmtSigned(game.creatorIncomePerDay - game.creatorSalaries),
                color: AppColors.green,
              ),
              const SizedBox(width: 14),
              StatBlock(
                'TV etkisi',
                '+${fmtPct(game.digitalBoost * 100, 1)}',
                color: AppColors.yellow,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            PillTabs(
              labels: [
                'YouTuber\'larım ${game.creators.length}/${game.maxCreators}',
                'Keşfet ${game.creatorMarket.length}',
              ],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const Spacer(),
            if (_tab == 1)
              GhostButton(
                'Yeni yüzler · 3 💎',
                compact: true,
                icon: Icons.refresh_rounded,
                onTap: () => report(context, game.refreshCreatorsPaid()),
              ),
          ],
        ),
        const SizedBox(height: 6),
        PageHint(
          _tab == 0
              ? 'Kampanya yaparak takipçilerini hızla artırabilirsin (5 günde bir). Toplam takipçin TV reytinglerini de artırır.'
              : 'Keşfet listesi 5 günde bir yenilenir. İmza ücreti 7 günlük maaş kadardır.',
        ),
        if (list.isEmpty)
          Panel(
            child: Text(
              _tab == 0
                  ? 'Henüz YouTuber\'ın yok. "Keşfet" sekmesinden transfer et!'
                  : 'Şu an aday yok.',
              style: const TextStyle(color: AppColors.textDim),
            ),
          ),
        AutoGrid(
          minItemWidth: 250,
          spacing: 10,
          children: [for (final c in list) _CreatorCard(c: c, mine: _tab == 0)],
        ),
      ],
    );
  }
}

class _CreatorCard extends StatelessWidget {
  final Creator c;
  final bool mine;
  const _CreatorCard({required this.c, required this.mine});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final ready = game.day >= c.campaignReadyDay;
    return Panel(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PersonAvatar(
                name: c.name,
                seed: c.look,
                color: c.niche.color,
                size: 52,
                badgeIcon: c.niche.icon,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${c.name} · ${c.niche.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.niche.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StatBlock(
                  'Takipçi',
                  _num(c.followers),
                  color: AppColors.cyan,
                ),
              ),
              Expanded(
                child: StatBlock(
                  'Büyüme',
                  '+${fmtPct(c.growth * 100, 1)}/g',
                  color: AppColors.green,
                ),
              ),
              Expanded(
                child: StatBlock('Etkileşim', fmtPct(c.engagement * 100, 1)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Gelir ${fmtShort(c.revenuePerDay)}/gün · maaş ${fmtShort(c.salary)}/gün',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 8),
          if (mine)
            Row(
              children: [
                Expanded(
                  child: AccentButton(
                    ready
                        ? 'Kampanya · ${fmtShort(c.campaignCost)}'
                        : '${c.campaignReadyDay - game.day} gün sonra',
                    compact: true,
                    icon: Icons.rocket_launch_rounded,
                    onTap: ready
                        ? () => report(context, game.runCampaign(c))
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                GhostButton(
                  'Bırak',
                  compact: true,
                  color: AppColors.red,
                  onTap: () async {
                    final ok = await confirm(
                      context,
                      '${c.handle} ile yollar ayrılsın mı?',
                      'Sözleşme biter, takipçileri artık senin için çalışmaz.',
                      ok: 'Ayrıl',
                    );
                    if (ok) game.releaseCreator(c);
                  },
                ),
              ],
            )
          else
            AccentButton(
              'Transfer et · ${fmtShort(c.signingFee)}',
              compact: true,
              expand: true,
              icon: Icons.handshake_rounded,
              onTap: () => report(context, game.signCreator(c)),
            ),
        ],
      ),
    );
  }
}
