import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../dialogs/negotiation_dialog.dart';
import '../widgets/common.dart';

class ChannelsScreen extends StatelessWidget {
  const ChannelsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        PageHint(
            'Rakip kanalları satın al, her gün pasif gelir getirsinler. '
            'Fiyat pazarlığa açık! Sahip olduğun kanalların günlük geliri: '
            '${fmtShort(game.channelIncomePerDay)}'),
        AutoGrid(minItemWidth: 280, spacing: 10, children: [
          for (final c in channelDefs) _ChannelCard(c: c),
        ]),
      ],
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final ChannelDef c;
  const _ChannelCard({required this.c});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final owned = game.ownedChannels.contains(c.id);
    final locked = game.studioLevel + 1 < c.reqLevel;
    final payback = (c.price / c.dailyIncome).round();
    final initials = c.name
        .split(' ')
        .map((w) => w.isEmpty ? '' : w[0])
        .take(2)
        .join();
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: owned ? AppColors.green.withValues(alpha: 0.6) : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(colors: [
              c.color,
              Color.lerp(c.color, AppColors.bg, 0.6)!,
            ], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          alignment: Alignment.center,
          child: Text(initials,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800)),
              Text(c.region,
                  style:
                      const TextStyle(color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 4),
              Text('Günlük gelir +${fmtShort(c.dailyIncome)}',
                  style: const TextStyle(
                      color: AppColors.green, fontWeight: FontWeight.w700)),
              Text('Fiyat ${fmtShort(c.price)} · ~$payback günde amorti',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              if (owned)
                Row(children: [
                  const Tag('SENİN ✓', color: AppColors.green),
                  const Spacer(),
                  GhostButton('Sat · ${fmtShort(game.sellValueChannel(c))}',
                      compact: true,
                      color: AppColors.textDim, onTap: () async {
                    final ok = await confirm(context, '${c.name} satılsın mı?',
                        'Alış fiyatının %80\'i kasana girer.',
                        ok: 'Sat');
                    if (ok) game.sellChannel(c);
                  }),
                ])
              else if (locked)
                Tag('Stüdyo seviyesi ${c.reqLevel}',
                    color: AppColors.textDim, icon: Icons.lock_rounded)
              else
                AccentButton('Pazarlık yap',
                    compact: true,
                    icon: Icons.handshake_rounded,
                    onTap: () => showNegotiation(context,
                        id: c.id,
                        name: c.name,
                        subtitle: '${c.region} · günlük +${fmtShort(c.dailyIncome)}',
                        price: c.price,
                        icon: Icons.connected_tv_rounded,
                        color: c.color)),
            ],
          ),
        ),
      ]),
    );
  }
}
