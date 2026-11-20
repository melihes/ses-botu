import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/economy.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});
  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(children: [
          PillTabs(
            labels: [
              'Yayın akışı',
              game.reportDay > 0 ? 'Reyting raporu · Gün ${game.reportDay}' : 'Reyting raporu',
            ],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const Spacer(),
          Tooltip(
            message: 'Rakip kanallar zamanla güçlenir ve seyirci çalar.',
            child: Tag('Rakip baskısı -${fmtPct((1 - game.rivalPressure) * 100, 0)}', color: AppColors.orange),
          ),
          const SizedBox(width: 6),
          Tag('🏆 Prime time birinciliği: ${game.primeWins}', color: AppColors.yellow),
        ]),
        const SizedBox(height: 10),
        if (_tab == 0) ...[
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
        ] else
          const _Report(),
      ],
    );
  }
}

class _Report extends StatelessWidget {
  const _Report();

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    if (game.lastReport.isEmpty) {
      return const Panel(
          child: Text('İlk rapor yarın sabah gelecek. Programlarını yayına koy!',
              style: TextStyle(color: AppColors.textDim)));
    }
    return AutoGrid(minItemWidth: 360, spacing: 10, children: [
      for (final slot in SlotId.values)
        if (game.lastReport[slot] != null)
          Panel(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(slotDefs[slot]!.label,
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                const SizedBox(width: 6),
                Text(slotDefs[slot]!.hours,
                    style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                const Spacer(),
                if (game.rankIn(slot) != null)
                  Tag('Sen: ${game.rankIn(slot)}.',
                      color: game.rankIn(slot) == 1 ? AppColors.yellow : AppColors.cyan),
              ]),
              const SizedBox(height: 6),
              ..._rows(game.lastReport[slot]!),
            ]),
          ),
    ]);
  }

  List<Widget> _rows(List<ReportRow> rows) {
    final top = rows.isEmpty ? 1.0 : rows.first.rating;
    return [
      for (int i = 0; i < rows.length && i < 6; i++)
        Container(
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: rows[i].mine ? AppColors.accent.withValues(alpha: 0.18) : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(children: [
            SizedBox(
              width: 20,
              child: Text('${i + 1}',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: i == 0 ? AppColors.yellow : AppColors.textDim)),
            ),
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rows[i].mine ? AppColors.accent : rivalDefs[rows[i].colorIndex].color,
              ),
            ),
            SizedBox(
              width: 92,
              child: Text(rows[i].channel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: rows[i].mine ? FontWeight.w900 : FontWeight.w600)),
            ),
            Expanded(
              child: Text(rows[i].program,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.textDim)),
            ),
            SizedBox(width: 50, child: Bar(rows[i].rating / top, color: rows[i].mine ? AppColors.accent : AppColors.cyan, height: 5)),
            const SizedBox(width: 6),
            SizedBox(
              width: 44,
              child: Text(fmtPct(rows[i].rating, 2),
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
    ];
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
          StageScene(
              talk: true,
              prop: propFor(s.genre, s.tier),
              color: s.def.color,
              tier: s.tier,
              live: true,
              width: 120,
              height: 78),
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
                if (game.saturationFor(s.genre) < 1)
                  Text('⚠️ Aynı türden çok program: reyting -${fmtPct((1 - game.saturationFor(s.genre)) * 100, 0)}',
                      style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w700)),
                if (s.sponsorDays > 0)
                  Text('🤝 ${s.sponsor} · +${fmtShort(s.sponsorPerDay)}/gün · ${s.sponsorDays}g',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.yellow, fontSize: 11, fontWeight: FontWeight.w700)),
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
