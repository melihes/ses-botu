import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../engine/game.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../models/models.dart';
import '../shell.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});
  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  int _tab = 1;
  Role? _role; // iş ilanlarında rol filtresi

  @override
  void initState() {
    super.initState();
    // Kadrosu olan oyuncu doğrudan kendi kadrosunu görsün
    _tab = GameScope.read(context).staff.isEmpty ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final all = _tab == 0 ? game.staff : game.market;
    final list = _role == null ? all : all.where((p) => p.role == _role).toList();
    final star = _tab == 1 && game.market.isNotEmpty ? game.market.first : null;
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
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
              GhostButton(
                'Yeni adaylar · 3 💎',
                compact: true,
                icon: Icons.refresh_rounded,
                onTap: () => report(context, game.refreshMarketPaid()),
              ),
          ],
        ),
        const SizedBox(height: 8),
        // rol filtresi: sadece istediğin mesleği gör
        Wrap(
          spacing: 0,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final r in <Role?>[null, ...Role.values])
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _role = r),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _role == r
                          ? (r?.color ?? AppColors.accent).withValues(alpha: 0.25)
                          : AppColors.panel,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: _role == r ? (r?.color ?? AppColors.accent) : AppColors.border),
                    ),
                    child: Text(
                      r == null ? 'Tümü' : '${r.label} ${all.where((p) => p.role == r).length}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
              ),
            if (_tab == 1)
              Tag('Yeni adaylar ${game.marketRefreshSeconds} sn sonra',
                  color: AppColors.textDim, icon: Icons.schedule_rounded),
            if (_tab == 1 && _role != null) ...[
              const SizedBox(width: 6),
              GhostButton('Yeni ${_role!.label.toLowerCase()} · 1 💎',
                  compact: true,
                  icon: Icons.refresh_rounded,
                  onTap: () => report(context, game.refreshRole(_role!))),
            ],
          ],
        ),
        const SizedBox(height: 10),
        if (_tab == 0) ...[const _ManagerCard(), const SizedBox(height: 10)],
        PageHint(
          _tab == 0
              ? 'Günlük maaş toplamı: ${fmtShort(game.dailySalaries)}. '
                    'Programda çalışan kişiler kadrodan çıkarılamaz. '
                    'Eğitim kampı yeteneği artırır (3 günde bir).'
              : 'Adaylar her gün yenilenir. En üstteki ⭐ Günün Yıldızı yüksek puanlı ama daha pahalı. '
                    'İşe alırken 5 günlük maaş kadar imza ücreti ödenir.',
        ),
        if (list.isEmpty)
          Panel(
            child: Text(
              _tab == 0
                  ? 'Kadron boş. "İş ilanları" sekmesinden ilk çalışanlarını al!'
                  : 'Şu an aday yok.',
              style: const TextStyle(color: AppColors.textDim),
            ),
          ),
        AutoGrid(
          minItemWidth: 250,
          spacing: 10,
          children: [
            for (int i = 0; i < list.length; i++)
              _PersonCard(
                person: list[i],
                hired: _tab == 0,
                featured: identical(list[i], star),
              ),
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
  const _PersonCard({
    required this.person,
    required this.hired,
    this.featured = false,
  });

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
          Row(
            children: [
              PersonAvatar(name: p.name, seed: p.id.hashCode, age: p.age, star: p.isStar,
                color: p.role.color,
                size: 46,
                badgeIcon: p.role.icon,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${p.role.label} · ${p.specDef.label}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: p.role.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${p.age} yaş${p.trait != 0 ? ' · ${p.traitDef.emoji} ${p.traitDef.label}' : ''}'
                      '${p.fame >= 1 ? ' · şöhret ${p.fame.round()}' : ''}'
                      '${game.bondsOf(p).map((b) => ' · ${bondInfo[b.$1]!.$1} ${b.$2.name.split(' ').first}').join()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (featured)
                const Tag(
                  'GÜNÜN YILDIZI',
                  color: AppColors.yellow,
                  icon: Icons.auto_awesome,
                )
              else if (p.isStar)
                const Tag('YILDIZ', color: AppColors.yellow, icon: Icons.star),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Yetenek',
                style: TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Bar(
                  p.skill / 100,
                  color: p.skill >= 70
                      ? AppColors.green
                      : p.skill >= 45
                      ? AppColors.yellow
                      : AppColors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${p.skill}',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hired && p.showId == null
                ? 'Maaş: ${fmtShort(p.salary)}/gün (boştayken yarısı)'
                : 'Maaş: ${fmtShort(p.salary)}/gün',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (hired) ...[
            Text(
              show == null ? '● Boşta' : '🎬 $show',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: show == null ? AppColors.yellow : AppColors.green,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Spacer(),
                GhostButton(
                  game.canTrain(p)
                      ? 'Eğit · ${fmtShort(game.trainCost(p))}'
                      : (p.skill >= 99 ? 'Zirvede' : 'Eğitimde'),
                  compact: true,
                  icon: Icons.school_rounded,
                  onTap: () => report(context, game.trainStaff(p)),
                ),
                const SizedBox(width: 4),
                GhostButton(
                  'Çıkar',
                  compact: true,
                  color: AppColors.red,
                  onTap: show != null
                      ? () => game.showToast(
                          '${p.name} şu an "$show" projesinde. Önce proje bitmeli.',
                        )
                      : () async {
                          final ok = await confirm(
                            context,
                            '${p.name} çıkarılsın mı?',
                            'Tazminat: ${fmtShort(p.salary * 3)}',
                            ok: 'Çıkar',
                          );
                          if (ok && context.mounted) {
                            report(context, game.fire(p));
                          }
                        },
                ),
              ],
            ),
          ]
          else
            AccentButton(
              'İşe al · ${fmtShort(game.signingFeeFor(p))}',
              compact: true,
              expand: true,
              icon: Icons.handshake_rounded,
              onTap: () => report(context, game.hire(p)),
            ),
        ],
      ),
    );
  }
}

/// Yönetim kurulu kısayolu
class _ManagerCard extends StatelessWidget {
  const _ManagerCard();
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final n = game.execs.length;
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: n > 0
          ? AppColors.green.withValues(alpha: 0.6)
          : AppColors.yellow.withValues(alpha: 0.6),
      onTap: () => ShellNav.go(context, PageId.board),
      child: Row(
        children: [
          const PersonAvatar(
            seed: 7777,
            color: AppColors.purple,
            size: 48,
            badgeIcon: Icons.business_center_rounded,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🤵 Yönetim kurulu · $n yönetici',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
                Text(
                  n == 0
                      ? 'Genel Müdür, Yayın Planlama, İK, Pazarlama… Sen yokken kanalı onlar yönetir.'
                      : game.execs.values
                            .map((e) => '${e.def.label} (${e.skill})')
                            .join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textDim),
        ],
      ),
    );
  }
}
