import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';

/// Günlük görevler: her gerçek gün 3 yeni görev.
Future<void> showMissionsDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const Dialog(child: _Missions()),
    );

class _Missions extends StatelessWidget {
  const _Missions();
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('🎯 Günlük görevler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const Spacer(),
            Tag('🔥 ${game.loginStreak} gün seri', color: AppColors.orange),
          ]),
          const Text('Her gün 3 yeni görev. Gece yarısı yenilenir.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 12),
          for (final m in game.missions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Panel(
                padding: const EdgeInsets.all(10),
                color: AppColors.panelHi,
                borderColor: m.done && !m.claimed ? AppColors.green : null,
                child: Row(children: [
                  Icon(m.claimed ? Icons.check_circle_rounded : Icons.flag_rounded,
                      color: m.claimed ? AppColors.green : AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(m.title, style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Bar(m.progress / m.target, color: m.done ? AppColors.green : AppColors.cyan),
                      const SizedBox(height: 2),
                      Text('${m.progress}/${m.target} · ödül ${m.gems} 💎 + ${fmtShort(game.missionCash(m))}',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                    ]),
                  ),
                  const SizedBox(width: 8),
                  m.claimed
                      ? const Tag('ALINDI', color: AppColors.green)
                      : AccentButton('Ödülü al',
                          compact: true, onTap: m.done ? () => report(context, game.claimMission(m)) : null),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

/// Günlük giriş ödülü (7 günlük seri)
Future<void> showLoginReward(BuildContext context, (int, int, double) r) => showDialog(
      context: context,
      builder: (c) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('🎁 Günlük giriş ödülü', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text('${r.$1}. gün üst üste geldin!', style: const TextStyle(color: AppColors.textDim)),
              const SizedBox(height: 12),
              Row(children: [
                for (int d = 1; d <= 7; d++)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: d <= (r.$1 > 7 ? 7 : r.$1) ? AppColors.accent.withValues(alpha: 0.25) : AppColors.panelHi,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: d == (r.$1 > 7 ? 7 : r.$1) ? AppColors.accent : AppColors.border),
                      ),
                      child: Column(children: [
                        Text('$d. gün', style: const TextStyle(fontSize: 10, color: AppColors.textDim)),
                        Text('$d 💎', style: const TextStyle(fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),
              Text('+${r.$2} 💎  ·  +${fmtShort(r.$3)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.green)),
              const SizedBox(height: 4),
              const Text('Her gün gelirsen ödül büyür (7. günde en yüksek). Bir gün kaçırırsan seri sıfırlanır.',
                  textAlign: TextAlign.center, style: TextStyle(color: AppColors.textFaint, fontSize: 11)),
              const SizedBox(height: 12),
              AccentButton('Topla!', expand: true, onTap: () => Navigator.pop(c)),
            ]),
          ),
        ),
      ),
    );
