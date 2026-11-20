import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../engine/economy.dart';
import '../widgets/common.dart';

class BankScreen extends StatelessWidget {
  const BankScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final offers = loanOffersFor(game.studioLevel);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const PageHint(
            'Kredi, büyümeyi hızlandırır ama taksitler her 7 günde bir otomatik kesilir. '
            'Kasa eksiye düşerse yeni yatırım yapamazsın. En fazla 3 açık kredi.'),
        const SectionLabel('Kredi teklifleri'),
        const SizedBox(height: 8),
        AutoGrid(minItemWidth: 230, spacing: 10, children: [
          for (final o in offers)
            Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fmtShort(o.amount),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                      '${o.installments} haftalık taksit × ${fmtShort(o.installment)}',
                      style: const TextStyle(color: AppColors.textDim)),
                  Text(
                      'Toplam faiz ${fmtPct(o.interest * 100, 0)} · '
                      'geri ödeme ${fmtShort(o.installment * o.installments)}',
                      style: const TextStyle(
                          color: AppColors.orange, fontSize: 12)),
                  const SizedBox(height: 10),
                  AccentButton('Krediyi çek',
                      compact: true,
                      expand: true,
                      icon: Icons.account_balance_rounded,
                      onTap: () async {
                        final ok = await confirm(
                            context,
                            '${fmtShort(o.amount)} kredi çekilsin mi?',
                            'Her 7 günde bir ${fmtShort(o.installment)} '
                                'kasandan otomatik kesilecek (${o.installments} taksit).',
                            ok: 'Çek');
                        if (ok && context.mounted) {
                          report(context, game.takeLoan(o));
                        }
                      }),
                ],
              ),
            ),
        ]),
        const SizedBox(height: 18),
        SectionLabel('Açık kredilerim · ${game.loans.length}'),
        const SizedBox(height: 8),
        if (game.loans.isEmpty)
          const Panel(
              child: Text('Borcun yok. Tebrikler! 🎉',
                  style: TextStyle(color: AppColors.textDim))),
        for (final l in game.loans)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Panel(
              child: Row(children: [
                const Icon(Icons.receipt_long_rounded,
                    color: AppColors.blue, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${fmtShort(l.principal)} kredi',
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                      Text(
                          'Kalan ${l.installmentsLeft} taksit × ${fmtShort(l.installment)} · '
                          'sonraki: Gün ${l.nextDueDay}',
                          style: const TextStyle(
                              color: AppColors.textDim, fontSize: 12)),
                    ],
                  ),
                ),
                StatBlock('Kalan borç', fmtShort(l.remaining),
                    color: AppColors.red),
                const SizedBox(width: 12),
                GhostButton('Erken kapat · ${fmtShort(game.payoffAmount(l))}',
                    compact: true,
                    onTap: () => report(context, game.payOffLoan(l))),
              ]),
            ),
          ),
        const SizedBox(height: 6),
        const Text('Erken kapatmada kalan borçtan %10 indirim yapılır.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
      ],
    );
  }
}
