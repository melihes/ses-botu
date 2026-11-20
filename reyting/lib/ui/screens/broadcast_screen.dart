import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/economy.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';

class BroadcastScreen extends StatelessWidget {
  const BroadcastScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const PageHint(
            'Reklam süresini kaydırarak ayarla: reklam uzadıkça gelir artar ama izleyici kaçar. '
            'Kaliteli programlar daha uzun reklamı kaldırır. En iyi noktayı bul!'),
        AutoGrid(
          minItemWidth: 360,
          spacing: 12,
          children: [
            for (final id in SlotId.values) _SlotCard(id: id),
          ],
        ),
      ],
    );
  }
}

class _SlotCard extends StatelessWidget {
  final SlotId id;
  const _SlotCard({required this.id});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final def = slotDefs[id]!;
    final slot = game.slots[id]!;
    final show = game.showById(slot.showId);
    final unlocked = game.slotUnlocked(id);

    final header = Row(children: [
      Icon(unlocked ? Icons.schedule_rounded : Icons.lock_rounded,
          color: AppColors.cyan, size: 18),
      const SizedBox(width: 6),
      Text(def.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      const SizedBox(width: 8),
      Text(def.hours,
          style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
            '${fmtDec(def.poolMillions * game.reach, 1)} M potansiyel · '
            'reklam ×${fmtDec(def.adValue, 1)}',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
      ),
    ]);

    Widget body;
    if (!unlocked) {
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text('Stüdyo seviyesi ${def.unlockLevel} ile açılır',
              style: const TextStyle(color: AppColors.textDim)),
        ),
      );
    } else if (show == null) {
      final ready =
          game.shows.where((s) => s.status == ShowStatus.ready).toList();
      body = Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(children: [
          const Text('Bu kuşak boş — ekranda test kartı dönüyor 📺',
              style: TextStyle(color: AppColors.textDim)),
          const SizedBox(height: 10),
          if (ready.isEmpty)
            const Text('Hazır programın yok. Yapım\'dan yeni program çek.',
                style: TextStyle(color: AppColors.textFaint, fontSize: 12))
          else
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in ready)
                GhostButton('${s.name} · ~${fmtPct(game.previewRating(s, id))}',
                    compact: true,
                    icon: s.def.icon,
                    onTap: () => report(context, game.putOnAir(s, id))),
            ]),
        ]),
      );
    } else {
      body = _OnAir(game: game, show: show, id: id);
    }

    return Panel(
      borderColor:
          show != null ? AppColors.accent.withValues(alpha: 0.5) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, const SizedBox(height: 10), body],
      ),
    );
  }
}

class _OnAir extends StatelessWidget {
  final Game game;
  final Show show;
  final SlotId id;
  const _OnAir({required this.game, required this.show, required this.id});

  @override
  Widget build(BuildContext context) {
    final s = show;
    final m = game.slots[id]!.adMinutes;
    final ret = adRetention(m, s.quality);
    final lost = 1 - ret;
    final retColor = ret >= 0.85
        ? AppColors.green
        : ret >= 0.65
            ? AppColors.yellow
            : AppColors.red;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ArtTile(icon: s.def.icon, color: s.def.color, size: 70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                  if (s.buffDays > 0)
                    Tag(s.buff >= 1 ? '▲ ${s.buffDays}g' : '▼ ${s.buffDays}g',
                        color: s.buff >= 1 ? AppColors.green : AppColors.red),
                ]),
                Text(
                    '${s.def.label} · Bölüm ${s.episodesAired}/${s.seasonDays}',
                    style: TextStyle(color: s.def.color, fontSize: 12)),
                const SizedBox(height: 4),
                Bar(s.seasonProgress, color: AppColors.accent, height: 4),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmtPct(game.currentRating(s), 2),
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.cyan)),
            Text(
                '${fmtShort(game.viewers(s)).replaceAll(' ₺', '')} izleyici',
                style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          ]),
        ]),
        if (s.ratingHistory.length >= 2) ...[
          const SizedBox(height: 6),
          SizedBox(
              height: 30,
              child: Sparkline(s.ratingHistory, color: AppColors.cyan)),
        ],
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.campaign_rounded,
              size: 18, color: AppColors.accent),
          const SizedBox(width: 6),
          Text('Reklam: ${fmtDec(m, 0)} dk/saat',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('İzleyici kaybı ${fmtPct(lost * 100, 0)}',
              style: TextStyle(
                  color: retColor, fontWeight: FontWeight.w800, fontSize: 12)),
        ]),
        Slider(
          value: m,
          min: 0,
          max: 24,
          divisions: 24,
          label: '${m.round()} dk',
          onChanged: (v) => game.setAdMinutes(id, v),
        ),
        Row(children: [
          Expanded(
              child: StatBlock('Gelir/gün', fmtSigned(game.revenuePerDay(s)),
                  color: AppColors.green)),
          Expanded(
              child: StatBlock('Sezon geliri', fmtShort(s.seasonRevenue))),
          GhostButton('Yayından kaldır',
              compact: true,
              color: AppColors.red,
              onTap: () async {
                final ok = await confirm(context, 'Yayından kaldırılsın mı?',
                    '"${s.name}" sezonu erken bitecek. Ekip serbest kalır.',
                    ok: 'Kaldır');
                if (ok) game.takeOffAir(id);
              }),
        ]),
      ],
    );
  }
}
