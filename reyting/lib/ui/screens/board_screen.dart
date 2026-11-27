import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content2.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

/// Yönetim kurulu: her koltuğa farklı yetenekte yönetici
class BoardScreen extends StatelessWidget {
  const BoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            Expanded(
              child: PageHint(
                'Sen telefon başında değilken işleri yöneticiler yürütür. Orta seviye yöneticiler ucuzdur ama az kazandırır; '
                'uzmanlar pahalıdır ama çok daha yüksek kâr getirir. Adaylar 5 günde bir yenilenir (sıradaki: ${game.execRefreshDays} gün sonra). '
                'Toplam maaş: ${fmtShort(game.execSalaries)}/gün',
              ),
            ),
          ],
        ),
        AutoGrid(
          minItemWidth: 380,
          spacing: 10,
          children: [for (final r in ExecRole.values) _Seat(role: r)],
        ),
      ],
    );
  }
}

class _Seat extends StatelessWidget {
  final ExecRole role;
  const _Seat({required this.role});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final d = execDefs[role]!;
    final cur = game.execs[role];
    final unlocked = game.execUnlocked(role);
    final cands = game.execCandidates.where((e) => e.role == role).toList()
      ..sort((a, b) => a.skill.compareTo(b.skill));
    return Panel(
      padding: const EdgeInsets.all(10),
      borderColor: cur != null ? d.color.withValues(alpha: 0.7) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: d.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(d.icon, color: d.color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.label,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '🤖 ${d.auto}',
                      maxLines: 2,
                      style: const TextStyle(
                        color: AppColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!unlocked)
            Tag(
              'Stüdyo seviyesi ${d.unlockLevel} ile açılır',
              color: AppColors.textDim,
              icon: Icons.lock_rounded,
            )
          else ...[
            if (cur != null)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: d.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    PersonAvatar(name: cur.name, seed: cur.id.hashCode,
                      color: d.color,
                      size: 36,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cur.name} · ${_grade(cur.skill)} ${cur.skill}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '+${fmtPct(game.execBonus(role) * 100, 1)} ${d.bonusLabel} · ${fmtShort(cur.salary)}/gün',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GhostButton(
                      'Kov',
                      compact: true,
                      color: AppColors.red,
                      onTap: () async {
                        if (await confirm(
                          context,
                          '${cur.name} kovulsun mu?',
                          'Otomatik işler duracak.',
                        )) {
                          game.fireExec(role);
                        }
                      },
                    ),
                  ],
                ),
              )
            else
              const Text(
                'Koltuk boş',
                style: TextStyle(color: AppColors.textFaint, fontSize: 12),
              ),
            const SizedBox(height: 6),
            Text(
              cur == null ? 'Adaylar' : 'Daha iyisini bul',
              style: const TextStyle(
                color: AppColors.textDim,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            for (final e in cands) _cand(context, game, e, d),
          ],
        ],
      ),
    );
  }

  String _grade(int s) => s >= 82 ? '🏅 Uzman' : (s >= 60 ? 'İyi' : 'Orta');

  Widget _cand(BuildContext context, Game game, Exec e, ExecRoleDef d) {
    final bonus = d.maxBonus * e.power;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          PersonAvatar(name: e.name, seed: e.id.hashCode, color: d.color, size: 26),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${e.name} · ${_grade(e.skill)} ${e.skill} · +${fmtPct(bonus * 100, 1)} · ${fmtShort(e.salary)}/gün',
              maxLines: 2,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          AccentButton(
            'Al ${fmtShort(e.signingFee)}',
            compact: true,
            onTap: () => report(context, game.hireExec(e)),
          ),
        ],
      ),
    );
  }
}

/// Marka teklifleri ve süren anlaşmalar
class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final tierName = const [
      'Yerel',
      'Bölgesel',
      'Ulusal',
      'Büyük',
      'Global',
    ][game.brandTier];
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            Tag('Marka seviyesi: $tierName', color: AppColors.yellow),
            Tag(
              'Anlaşma geliri ${fmtShort(game.dealIncomePerDay + game.sponsorIncomePerDay)}/gün',
              color: AppColors.green,
            ),
            if (game.execs.containsKey(ExecRole.pazarlama))
              const Tag(
                '🤖 Pazarlama Müdürü teklifleri otomatik kabul ediyor',
                color: AppColors.cyan,
              ),
          ],
        ),
        const SizedBox(height: 8),
        const PageHint(
          'Prestijin, şöhretli oyuncuların ve büyüklüğün arttıkça daha büyük markalar kapını çalar. '
          'Teklifler 3 gün geçerlidir.',
        ),
        const SectionLabel('Gelen teklifler'),
        const SizedBox(height: 4),
        if (game.brandOffers.isEmpty)
          const Text(
            'Şu an bekleyen teklif yok. Yayındaki programların ve ünlü kadron arttıkça teklif gelir.',
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        AutoGrid(
          minItemWidth: 360,
          spacing: 10,
          children: [
            for (final o in game.brandOffers)
              Panel(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: AppColors.accentGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(o.kind.icon, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o.brand,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          Text(
                            '${o.kind.label} · ${game.brandTargetName(o)}',
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            o.lump > 0
                                ? 'Tek seferlik +${fmtShort(o.lump)}'
                                : '+${fmtShort(o.perDay * kIncome)}/gün × ${o.days} gün = ${fmtShort(o.total * kIncome)}'
                                      '${o.ratingCost > 0 ? ' · reyting -%${(o.ratingCost * 100).round()}' : ''}',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${o.expires - game.day + 1} gün geçerli',
                            style: const TextStyle(
                              color: AppColors.textFaint,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        AccentButton(
                          'Kabul',
                          compact: true,
                          onTap: () =>
                              report(context, game.acceptBrandOffer(o)),
                        ),
                        const SizedBox(height: 4),
                        GhostButton(
                          'Reddet',
                          compact: true,
                          onTap: () => game.rejectBrandOffer(o),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        const SectionLabel('Süren anlaşmalar'),
        const SizedBox(height: 4),
        for (final s in game.shows.where((s) => s.sponsorDays > 0 && s.status == ShowStatus.onAir))
          _dealRow(
            '${s.sponsor}',
            'Ürün yerleştirme · ${s.name}',
            s.sponsorPerDay,
            s.sponsorDays,
          ),
        for (final d in game.deals)
          _dealRow(
            d.brand,
            '${d.kind.label}${d.targetId != null ? ' · ${game.personById(d.targetId!)?.name ?? ''}' : ''}',
            d.perDay,
            d.daysLeft,
          ),
        if (game.deals.isEmpty && !game.shows.any((s) => s.sponsorDays > 0))
          const Text(
            'Henüz anlaşma yok.',
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
      ],
    );
  }

  Widget _dealRow(String brand, String what, double perDay, int days) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Panel(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              const Icon(Icons.handshake_rounded, color: AppColors.yellow),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$brand — $what',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '+${fmtShort(perDay * kIncome)}/gün · $days gün',
                style: const TextStyle(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
}
