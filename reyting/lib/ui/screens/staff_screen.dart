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
        if (_tab == 0) ...[
          const _ManagerCard(),
          const SizedBox(height: 10),
        ],
        PageHint(_tab == 0
            ? 'Günlük maaş toplamı: ${fmtShort(game.dailySalaries)}. '
                'Programda çalışan kişiler kadrodan çıkarılamaz. '
                'Eğitim kampı yeteneği artırır (3 günde bir).'
            : 'Adaylar her gün yenilenir. En üstteki ⭐ Günün Yıldızı yüksek puanlı ama daha pahalı. '
                'İşe alırken 5 günlük maaş kadar imza ücreti ödenir.'),
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
            for (int i = 0; i < list.length; i++)
              _PersonCard(person: list[i], hired: _tab == 0, featured: _tab == 1 && i == 0),
          ],
        ),
      ],
    );
  }
}

class _PersonCard extends StatelessWidget {
  final Staff person;
  final bool hired;
  final bool featured;
  const _PersonCard({required this.person, required this.hired, this.featured = false});

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
            if (featured)
              const Tag('GÜNÜN YILDIZI', color: AppColors.yellow, icon: Icons.auto_awesome)
            else if (p.isStar)
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
              GhostButton(
                  game.canTrain(p) ? 'Eğit · ${fmtShort(game.trainCost(p))}' : 'Eğitimde',
                  compact: true,
                  icon: Icons.school_rounded,
                  onTap: game.canTrain(p) ? () => report(context, game.trainStaff(p)) : null),
              const SizedBox(width: 4),
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

/// Genel Müdür: maaşlı yönetici, biten sezonları otomatik yeniler.
class _ManagerCard extends StatelessWidget {
  const _ManagerCard();
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final hired = game.autoManager;
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: hired ? AppColors.green.withValues(alpha: 0.6) : AppColors.yellow.withValues(alpha: 0.6),
      child: Row(children: [
        const PersonAvatar(seed: 7777, color: AppColors.purple, size: 52, badgeIcon: Icons.business_center_rounded),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🤵 Genel Müdür', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(width: 8),
              Tag(hired ? 'GÖREVDE' : 'BOŞ KADRO', color: hired ? AppColors.green : AppColors.textDim),
            ]),
            const Text(
                'Sezonu biten programları otomatik yeniler ve aynı kuşağa geri koyar. '
                'Sen yokken kanalın boş kalmaz.',
                style: TextStyle(color: AppColors.textDim, fontSize: 12)),
            Text('Maaş ${fmtShort(game.managerSalary)}/gün (stüdyo seviyesiyle artar)',
                style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 8),
        hired
            ? GhostButton('Görevden al', compact: true, color: AppColors.red, onTap: () async {
                final ok = await confirm(context, 'Genel Müdür görevden alınsın mı?',
                    'Biten sezonları artık sen yenilemek zorunda kalırsın.', ok: 'Görevden al');
                if (ok) game.fireManager();
              })
            : AccentButton('İşe al · ${fmtShort(game.managerSigningFee)}',
                compact: true, icon: Icons.handshake_rounded, onTap: () => report(context, game.hireManager())),
      ]),
    );
  }
}
