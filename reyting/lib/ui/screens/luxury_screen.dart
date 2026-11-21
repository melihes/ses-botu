import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/game.dart';
import '../dialogs/negotiation_dialog.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

class LuxuryScreen extends StatefulWidget {
  const LuxuryScreen({super.key});
  @override
  State<LuxuryScreen> createState() => _LuxuryScreenState();
}

class _LuxuryScreenState extends State<LuxuryScreen> {
  int _cat = 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final market = _cat == LuxCat.values.length;
    final cat = market ? LuxCat.saat : LuxCat.values[_cat];
    final items = luxuryDefs.where((d) => d.cat == cat).toList();
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Expanded(
              child: PillTabs(
                labels: [
                  for (final c in LuxCat.values) c.label,
                  '🔁 İkinci el${game.luxOffers.isNotEmpty ? ' · ${game.luxOffers.length} teklif' : ''}',
                ],
                selected: _cat,
                onChanged: (i) => setState(() => _cat = i),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        PageHint(
          'Prestijin (${fmtInt(game.prestige)}) reklam fiyatlarını '
          '${fmtPct(game.adBonus * 100, 1)} artırıyor (en fazla %30). '
          'Yat, jet, ada ve özel parçalarda pazarlık yapılır. Sınırlı üretim parçaların seri numarası olur; '
          'fabrikada tükenince sadece ikinci el pazarda bulunur ve değeri artar.',
        ),
        if (market)
          ..._marketBody(context, game)
        else
          AutoGrid(
            minItemWidth: 280,
            spacing: 10,
            children: [for (final d in items) _LuxCard(d: d)],
          ),
      ],
    );
  }
}

List<Widget> _marketBody(BuildContext context, Game game) {
  final mine = luxuryDefs.where((d) => game.ownedLuxury.contains(d.id)).toList();
  return [
    if (game.luxOffers.isNotEmpty) ...[
      const SectionLabel('Parçalarına gelen teklifler', color: AppColors.green),
      const SizedBox(height: 4),
      for (final o in game.luxOffers)
        Builder(builder: (_) {
          final d = luxuryDefs.firstWhere((x) => x.id == o.defId);
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Panel(
              padding: const EdgeInsets.all(8),
              child: Row(children: [
                ItemArt(id: d.artId, color: d.cat.color, width: 56, height: 44),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      '${o.from} → ${d.name} #${game.luxSerial[d.id] ?? '-'}: ${fmtShort(o.amount)} '
                      '(alış ${fmtShort(d.price)}) · ${o.expires - game.day + 1} gün',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                AccentButton('Sat', compact: true, onTap: () => report(context, game.acceptLuxOffer(o))),
              ]),
            ),
          );
        }),
      const SizedBox(height: 10),
    ],
    const SectionLabel('Satılık parçalar (koleksiyonculardan)'),
    const SizedBox(height: 4),
    if (game.luxListings.isEmpty)
      const Text('Şu an ilan yok. Fabrikada tükenen parçalar burada satışa çıkar (5 günde bir yenilenir).',
          style: TextStyle(color: AppColors.textDim, fontSize: 12)),
    AutoGrid(minItemWidth: 300, spacing: 10, children: [
      for (final l in game.luxListings)
        Builder(builder: (_) {
          final d = luxuryDefs.firstWhere((x) => x.id == l.defId);
          return Panel(
            padding: const EdgeInsets.all(10),
            child: Row(children: [
              ItemArt(id: d.artId, color: d.cat.color, width: 90, height: 72),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text('Seri #${l.serial}/${d.edition} · satıcı ${l.seller}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                  Text(fmtShort(l.price),
                      style: const TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  AccentButton('Satın al', compact: true, onTap: () => report(context, game.buyLuxListing(l))),
                ]),
              ),
            ]),
          );
        }),
    ]),
    const SizedBox(height: 12),
    const SectionLabel('Benim parçalarım'),
    const SizedBox(height: 4),
    if (mine.isEmpty)
      const Text('Henüz lüks parçan yok.', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
    for (final d in mine)
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Panel(
          padding: const EdgeInsets.all(8),
          child: Row(children: [
            ItemArt(id: d.artId, color: d.cat.color, width: 56, height: 44),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  '${d.name}${game.luxSerial[d.id] != null ? ' · #${game.luxSerial[d.id]}/${d.edition}' : ''} · '
                  'piyasa değeri ~${fmtShort(game.luxMarketValue(d, game.luxSerial[d.id]))}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            GhostButton(game.luxForSale.contains(d.id) ? 'İlandan çek' : 'İlana koy',
                compact: true,
                color: game.luxForSale.contains(d.id) ? AppColors.orange : AppColors.cyan,
                onTap: () => game.toggleLuxSale(d)),
          ]),
        ),
      ),
    const SizedBox(height: 6),
    const Text('Gerçek oyuncularla alım-satım, online sürümde bu pazara bağlanacak.',
        style: TextStyle(color: AppColors.textFaint, fontSize: 11)),
  ];
}

class _LuxCard extends StatelessWidget {
  final LuxuryDef d;
  const _LuxCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final owned = game.ownedLuxury.contains(d.id);
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: owned ? AppColors.green.withValues(alpha: 0.6) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemArt(
            id: d.artId,
            color: d.cat.color,
            width: 110,
            height: 96,
            badge: d.negotiable ? 'PAZARLIK' : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  d.desc,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      fmtShort(d.price),
                      style: const TextStyle(
                        color: AppColors.yellow,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tag(
                      '+${d.prestige} prestij',
                      color: AppColors.yellow,
                      icon: Icons.star_rounded,
                    ),
                  ],
                ),
                if (d.edition != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      owned && game.luxSerial[d.id] != null
                          ? '🔢 Senin seri no: #${game.luxSerial[d.id]}/${d.edition}'
                          : game.luxSoldOut(d)
                          ? '⛔ Fabrikada tükendi · ikinci el pazara bak'
                          : '🔢 Sınırlı üretim: ${d.edition} adet · kalan ${game.luxLeft(d)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: game.luxSoldOut(d) && !owned ? AppColors.red : AppColors.cyan,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                if (owned)
                  Row(
                    children: [
                      const Tag('SENİN ✓', color: AppColors.green),
                      const Spacer(),
                      GhostButton(
                        'Sat · ${fmtShort(game.sellValueLuxury(d))}',
                        compact: true,
                        color: AppColors.textDim,
                        onTap: () async {
                          final ok = await confirm(
                            context,
                            '${d.name} satılsın mı?',
                            'Alış fiyatının %70\'i kasana girer.',
                            ok: 'Sat',
                          );
                          if (ok) game.sellLuxury(d);
                        },
                      ),
                    ],
                  )
                else if (game.luxSoldOut(d))
                  const Tag('TÜKENDİ', color: AppColors.red)
                else if (d.negotiable)
                  AccentButton(
                    'Pazarlık yap',
                    compact: true,
                    icon: Icons.handshake_rounded,
                    onTap: () => showNegotiation(
                      context,
                      id: d.id,
                      name: d.name,
                      subtitle: d.desc,
                      price: d.price,
                      icon: d.cat.icon,
                      color: d.cat.color,
                    ),
                  )
                else
                  AccentButton(
                    'Satın al',
                    compact: true,
                    icon: Icons.shopping_bag_rounded,
                    onTap: () => report(context, game.buyFixed(d)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
