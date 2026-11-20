import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../data/content2.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

/// Yetenek ajansı: genç yetenek keşfi, akademi, transfer pazarı, satış
class AgencyScreen extends StatefulWidget {
  const AgencyScreen({super.key});
  @override
  State<AgencyScreen> createState() => _AgencyScreenState();
}

class _AgencyScreenState extends State<AgencyScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final next = game.nextAgency;
    final offers = game.transferOffers.length;
    return ListView(padding: const EdgeInsets.all(12), children: [
      Panel(
        gradient: const LinearGradient(colors: [Color(0xFF3A1F3F), AppColors.panel]),
        child: Row(children: [
          const Icon(Icons.star_rounded, color: AppColors.pink, size: 44),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel('Ajans seviyesi ${game.agencyLevel}/${agencyLevels.length - 1}'),
              Text(game.agencyOpen ? game.agency.name : 'Ajans henüz kurulmadı',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              if (game.agencyOpen)
                Text(
                    'Günde ${game.agency.scouts} genç · potansiyel en fazla ${game.agency.maxPotential} · '
                    'akademi ${game.academy.length}/${game.agency.academySlots} · gelişim ×${fmtDec(game.agency.growth, 2)}',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12))
              else
                const Text(
                    'Genç yetenekleri keşfet, yetiştir, yıldız yap; sonra kendi dizilerinde oynat ya da rakiplere sat.',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 250,
            child: next == null
                ? const Text('🏆 Efsaneler akademisi!',
                    style: TextStyle(fontWeight: FontWeight.w800))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(game.agencyOpen ? 'Sonraki: ${next.name}' : 'Kuruluş: ${next.name}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(
                        'Potansiyel ${next.maxPotential} · akademi ${next.academySlots} · transfer listesi ${next.transferList}'
                        '${game.studioLevel + 1 < game.agencyLevel + 1 ? ' · Stüdyo sv ${game.agencyLevel + 1} gerekli' : ''}',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                    const SizedBox(height: 6),
                    AccentButton(
                        '${game.agencyOpen ? 'Yükselt' : 'Ajansı kur'} · ${fmtShort(next.cost)}',
                        expand: true,
                        icon: Icons.upgrade_rounded,
                        onTap: () => report(context, game.upgradeAgency())),
                  ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      if (game.agencyOpen) ...[
        Row(children: [
          PillTabs(
            labels: [
              'Genç yetenekler ${game.youthMarket.length}',
              'Akademi ${game.academy.length}',
              'Transfer pazarı ${game.transferMarket.length}',
              'Satış${offers > 0 ? ' · $offers teklif' : ''}',
            ],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const Spacer(),
          if (_tab == 0)
            GhostButton('Gözlemci gönder · 2 💎',
                compact: true,
                icon: Icons.travel_explore_rounded,
                onTap: () => report(context, game.sendScout())),
        ]),
        const SizedBox(height: 8),
        ..._tabBody(context, game),
      ],
    ]);
  }

  List<Widget> _tabBody(BuildContext context, Game game) {
    switch (_tab) {
      case 0:
        return [
          const PageHint('Her gün yeni gençler gelir. Potansiyel (⭐) ne kadar yüksekse o kadar büyük yıldız olur. '
              'Akademide hızlı gelişirler; kadroya alınca dizilerinde oynarlar ve şöhret kazanırlar.'),
          if (game.youthMarket.isEmpty)
            const Text('Bugünlük aday kalmadı.', style: TextStyle(color: AppColors.textDim)),
          AutoGrid(minItemWidth: 330, spacing: 10, children: [
            for (final p in game.youthMarket)
              TalentCard(p: p, actions: [
                AccentButton('İmzala · ${fmtShort(game.youthSignFee(p))}',
                    compact: true, onTap: () => report(context, game.signYouth(p))),
              ]),
          ]),
        ];
      case 1:
        return [
          const PageHint('Akademidekiler her gün gelişir (yaş 26\'ya kadar). Hazır olduklarında kadroya al.'),
          if (game.academy.isEmpty)
            const Text('Akademin boş. "Genç yetenekler" sekmesinden imzala.',
                style: TextStyle(color: AppColors.textDim)),
          AutoGrid(minItemWidth: 330, spacing: 10, children: [
            for (final p in game.academy)
              TalentCard(p: p, actions: [
                AccentButton('Kadroya al', compact: true,
                    onTap: () => report(context, game.promoteYouth(p))),
                GhostButton(p.forSale ? 'Satıştan çek' : 'Satışa çıkar',
                    compact: true, onTap: () => game.toggleForSale(p)),
              ]),
          ]),
        ];
      case 2:
        return [
          const PageHint('Başka ajansların yetiştirdiği hazır yıldızlar. Şöhretleri programlarının reytingini artırır. '
              'Liste 3 günde bir yenilenir. (Gerçek oyuncularla takas online sürümde açılacak.)'),
          AutoGrid(minItemWidth: 330, spacing: 10, children: [
            for (final p in game.transferMarket)
              TalentCard(p: p, actions: [
                AccentButton('Transfer · ${fmtShort(game.transferPrice(p))}',
                    compact: true, onTap: () => report(context, game.buyTransfer(p))),
              ]),
          ]),
        ];
      default:
        final mine = [...game.staff, ...game.academy];
        mine.sort((a, b) => game.talentValue(b).compareTo(game.talentValue(a)));
        return [
          PageHint('Satışa çıkardığın kişilere rakip kanallar her gün teklif yapar (3 gün geçerli). '
              'Toplam satış: ${game.talentsSold} kişi · ${fmtShort(game.transferProfit)}'),
          if (game.transferOffers.isNotEmpty) ...[
            const SectionLabel('Gelen teklifler', color: AppColors.green),
            const SizedBox(height: 4),
            for (final o in game.transferOffers)
              Builder(builder: (_) {
                final p = game.personById(o.staffId);
                if (p == null) return const SizedBox.shrink();
                final v = game.talentValue(p);
                return Panel(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    PersonAvatar(seed: p.id.hashCode, color: p.role.color, size: 34),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${o.from} → ${p.name}: ${fmtShort(o.amount)} '
                          '(değeri ${fmtShort(v)}, ${o.amount >= v ? '+' : ''}${fmtPct((o.amount / v - 1) * 100, 0)}) · ${o.expires - game.day + 1} gün',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    AccentButton('Kabul', compact: true,
                        onTap: () => report(context, game.acceptTransfer(o))),
                  ]),
                );
              }),
            const SizedBox(height: 8),
          ],
          AutoGrid(minItemWidth: 330, spacing: 10, children: [
            for (final p in mine)
              TalentCard(p: p, actions: [
                GhostButton(p.forSale ? 'Satıştan çek' : 'Satışa çıkar',
                    compact: true,
                    color: p.forSale ? AppColors.orange : AppColors.cyan,
                    onTap: () => game.toggleForSale(p)),
                GhostButton('Hemen sat ${fmtShort(game.quickSaleValue(p))}',
                    compact: true,
                    onTap: () async {
                      if (await confirm(context, '${p.name} satılsın mı?',
                          'Ajanslara hemen ${fmtShort(game.quickSaleValue(p))} karşılığında satılır.')) {
                        if (context.mounted) report(context, game.quickSell(p));
                      }
                    }),
              ]),
          ]),
        ];
    }
  }
}

/// Kişi kartı: uzmanlık, karakter, yaş, potansiyel, şöhret ve değer
class TalentCard extends StatelessWidget {
  final Staff p;
  final List<Widget> actions;
  const TalentCard({super.key, required this.p, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final stars = (p.potential / 20).clamp(0, 5);
    return Panel(
      padding: const EdgeInsets.all(10),
      borderColor: p.forSale ? AppColors.orange.withValues(alpha: 0.7) : null,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        PersonAvatar(seed: p.id.hashCode, color: p.role.color, size: 54,
            badgeIcon: p.role.icon),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${p.name} · ${p.age}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900)),
            Text('${p.role.label} · ${p.specDef.label}',
                style: TextStyle(color: p.role.color, fontSize: 12, fontWeight: FontWeight.w700)),
            if (p.trait != 0)
              Text('${p.traitDef.emoji} ${p.traitDef.label} — ${p.traitDef.desc}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
            const SizedBox(height: 4),
            Row(children: [
              Text('Yetenek ${p.skill}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(width: 6),
              Expanded(
                child: Stack(children: [
                  Bar(p.potential / 100, color: AppColors.yellow.withValues(alpha: 0.35), height: 6),
                  Bar(p.skill / 100, color: AppColors.cyan, height: 6),
                ]),
              ),
              const SizedBox(width: 6),
              Text('${'★' * stars.round()}${'☆' * (5 - stars.round())}',
                  style: const TextStyle(color: AppColors.yellow, fontSize: 12)),
            ]),
            Text('Potansiyel ${p.potential} · şöhret ${p.fame.round()} · değer ${fmtShort(game.talentValue(p))}',
                style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: [
                ...actions,
                if (p.fame < 95 && (game.staff.contains(p) || game.academy.contains(p)))
                  GhostButton('📣 Tanıtım ${fmtShort(game.prCost(p))}',
                      compact: true, onTap: () => report(context, game.promoteFame(p))),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }
}
