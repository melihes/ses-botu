import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  int _tab = 1;

  @override
  void initState() {
    super.initState();
    // Kadrosu olan oyuncu doğrudan kendi kadrosunu görsün
    _tab = GameScope.read(context).staff.isEmpty ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final list = _tab == 0 ? game.staff : game.market;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(children: [
          PillTabs(
            labels: [
              'Kadrom ${game.staff.length}/${game.studio.maxStaff}',
              'İş ilanları ${game.market.length}',
            ],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const Spacer(),
          if (_tab == 1)
            GhostButton('Yeni adaylar · 3 💎',
                compact: true,
                icon: Icons.refresh_rounded,
                onTap: () => report(context, game.refreshMarketPaid())),
        ]),
        const SizedBox(height: 10),
        PageHint(_tab == 0
            ? 'Günlük maaş toplamı: ${fmtShort(game.dailySalaries)}. '
                'Programda çalışan kişiler kadrodan çıkarılamaz.'
            : 'Adaylar her 3 günde bir yenilenir. İşe alırken 5 günlük maaş '
                'kadar imza ücreti ödenir. ★ Yıldızlar ileride online ihaleye düşecek!'),
        if (list.isEmpty)
          Panel(
            child: Text(
                _tab == 0
                    ? 'Kadron boş. "İş ilanları" sekmesinden ilk çalışanlarını al!'
                    : 'Şu an aday yok.',
                style: const TextStyle(color: AppColors.textDim)),
          ),
        AutoGrid(
          minItemWidth: 250,
          spacing: 10,
          children: [
            for (final p in list) _PersonCard(person: p, hired: _tab == 0),
          ],
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Staff person;
  final bool hired;
  const _PersonCard({required this.person, required this.hired});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final p = person;
    final show = game.assignmentOf(p);
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: p.isStar ? AppColors.yellow : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            PersonAvatar(
                seed: p.id.hashCode,
                color: p.role.color,
                size: 46,
                badgeIcon: p.role.icon),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(p.role.label,
                      style: TextStyle(
                          color: p.role.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            if (p.isStar)
              const Tag('YILDIZ', color: AppColors.yellow, icon: Icons.star),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            const Text('Yetenek',
                style: TextStyle(color: AppColors.textDim, fontSize: 12)),
            const SizedBox(width: 8),
            Expanded(
                child: Bar(p.skill / 100,
                    color: p.skill >= 70
                        ? AppColors.green
                        : p.skill >= 45
                            ? AppColors.yellow
                            : AppColors.orange)),
            const SizedBox(width: 8),
            Text('${p.skill}',
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ]),
          const SizedBox(height: 6),
          Text(
              hired && p.showId == null
                  ? 'Maaş: ${fmtShort(p.salary)}/gün (boştayken yarısı)'
                  : 'Maaş: ${fmtShort(p.salary)}/gün',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
          const SizedBox(height: 10),
          if (hired)
            Row(children: [
              Expanded(
                child: Text(
                  show == null ? '● Boşta' : '● $show',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: show == null ? AppColors.yellow : AppColors.green,
                      fontWeight: FontWeight.w700,
                      fontSize: 12),
                ),
              ),
              GhostButton('Çıkar',
                  compact: true,
                  color: AppColors.red,
                  onTap: show != null
                      ? null
                      : () async {
                          final ok = await confirm(
                              context,
                              '${p.name} çıkarılsın mı?',
                              'Tazminat: ${fmtShort(p.salary * 3)}',
                              ok: 'Çıkar');
                          if (ok && context.mounted) {
                            report(context, game.fire(p));
                          }
                        }),
            ])
          else
            AccentButton('İşe al · ${fmtShort(p.signingFee)}',
                compact: true,
                expand: true,
                icon: Icons.handshake_rounded,
                onTap: () => report(context, game.hire(p))),
        ],
      ),
    );
  }
}
