import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';

Future<void> showOfflineDialog(
    BuildContext context, PeriodSummary s, Game game) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: AppColors.border)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: _OfflineBody(s: s, game: game),
        ),
      ),
    ),
  );
}

class _OfflineBody extends StatelessWidget {
  final PeriodSummary s;
  final Game game;
  const _OfflineBody({required this.s, required this.game});

  @override
  Widget build(BuildContext context) {
    final delta = s.cashAfter - s.cashBefore;
    final capped = s.minutesAway > s.minutesCounted + 0.5;
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SectionLabel('Sen yokken', color: AppColors.green),
        const SizedBox(height: 4),
        Text('${s.days} gün geçti',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          '${fmtDec(s.minutesAway, 0)} dk uzaktaydın'
          '${capped ? ' · en fazla ${fmtDec(game.offlineCapMinutes, 0)} dk işlenir' : ''}',
          style: const TextStyle(color: AppColors.textDim),
        ),
        const SizedBox(height: 14),
        Panel(
          color: AppColors.panelHi,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('Kasa değişimi', color: AppColors.textDim),
              const SizedBox(height: 4),
              Text(fmtSigned(delta),
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: delta >= 0 ? AppColors.green : AppColors.red)),
              Text('${fmtShort(s.cashBefore)} → ${fmtShort(s.cashAfter)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        if (s.cashAfter < 0) ...[
          const SizedBox(height: 8),
          const Text(
            '💡 Kasa eksiye düştü. Yayına program koy, gereksiz kadroyu çıkar ya da Banka\'dan kredi çek.',
            style: TextStyle(color: AppColors.orange, fontSize: 12),
          ),
        ],
        if (capped) ...[
          const SizedBox(height: 8),
          const Text(
            'VIP ile 8 saate kadar işlenir (Aşama 5).',
            style: TextStyle(color: AppColors.yellow, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        AccentButton('Tamam',
            expand: true, onTap: () => Navigator.of(context).pop()),
      ],
    );

    final tiles = <Widget>[
      _tile('Reklam geliri', fmtSigned(s.adIncome), true),
      _tile('Kanal gelirleri', fmtSigned(s.channelIncome), true),
      _tile('Sinema gişesi', fmtSigned(s.boxOffice), true),
      _tile('Platform aboneleri', fmtSigned(s.platformIncome), true),
      _tile('Holding işletmeleri', fmtSigned(s.bizIncome), true),
      _tile('YouTuber gelirleri', fmtSigned(s.digitalIncome), true),
      _tile('Sponsorlar', fmtSigned(s.sponsorIncome), true),
      _tile('Ödenen maaşlar', fmtSigned(-s.salaries), false),
      _tile('Stüdyo kirası', fmtSigned(-s.rent), false),
      _tile('Ekipman bakımı', fmtSigned(-s.upkeep), false),
      _tile('Kredi taksitleri', fmtSigned(-s.loanPaid), false),
      _tile('Olaylar (${s.events})', fmtSigned(s.eventCash), s.eventCash >= 0),
      _tile('Ortalama reyting', fmtPct(s.avgRating), true, neutral: true),
      _tile('Biten çekimler', '${s.finishedProductions}', true, neutral: true),
      _tile('Biten filmler', '${s.filmsDone}', true, neutral: true),
      _tile('Biten sezonlar', '${s.endedSeasons}', true, neutral: true),
    ];

    return LayoutBuilder(builder: (ctx, c) {
      final wide = c.maxWidth > 640;
      final grid = AutoGrid(minItemWidth: 190, spacing: 10, children: tiles);
      if (!wide) {
        return Column(children: [left, const SizedBox(height: 16), grid]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 300, child: left),
        const SizedBox(width: 20),
        Expanded(child: grid),
      ]);
    });
  }

  Widget _tile(String label, String value, bool good, {bool neutral = false}) {
    final color = neutral
        ? AppColors.cyan
        : (good ? AppColors.green : AppColors.orange);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.panelHi,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
