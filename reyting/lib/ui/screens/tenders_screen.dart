import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import 'production_screen.dart';
import '../widgets/item_art.dart';
import '../widgets/scene.dart';

class TendersScreen extends StatefulWidget {
  const TendersScreen({super.key});
  @override
  State<TendersScreen> createState() => _TendersScreenState();
}

class _TendersScreenState extends State<TendersScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final open = game.tenders
        .where((t) => t.status == TenderStatus.open)
        .toList();
    final mine = game.tenders
        .where((t) => t.status != TenderStatus.open)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Row(
          children: [
            PillTabs(
              labels: [
                'Açık ihaleler ${open.length}',
                'Projelerim ${mine.where((t) => t.myBid != null).length}',
              ],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const Spacer(),
            Tag(
              '🏛️ Teslim edilen: ${game.tendersWon}',
              color: AppColors.yellow,
            ),
          ],
        ),
        const SizedBox(height: 8),
        const PageHint(
          'Kamu kurumları yapım ihalesi açar. Kapalı zarfla teklif ver: en düşük "fiyat ÷ kalite" puanı kazanır. '
          'İyi ekip ve fazladan ekipman kaliteni yükseltir. Teklifte %5 teminat bloke edilir, kaybedersen iade edilir.',
        ),
        if (_tab == 0)
          AutoGrid(
            minItemWidth: 360,
            spacing: 10,
            children: [for (final t in open) _TenderCard(t: t)],
          )
        else if (mine.isEmpty)
          const Panel(
            child: Text(
              'Henüz proje yok.',
              style: TextStyle(color: AppColors.textDim),
            ),
          )
        else
          AutoGrid(
            minItemWidth: 360,
            spacing: 10,
            children: [for (final t in mine) _TenderCard(t: t)],
          ),
      ],
    );
  }
}

class _TenderCard extends StatelessWidget {
  final Tender t;
  const _TenderCard({required this.t});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final d = t.def;
    final why = game.tenderEligible(t);
    final statusTag = switch (t.status) {
      TenderStatus.open =>
        t.myBid != null
            ? Tag('TEKLİF VERİLDİ · Gün ${t.closesDay}', color: AppColors.cyan)
            : Tag(
                '${t.closesDay - game.day} gün kaldı',
                color: AppColors.green,
              ),
      TenderStatus.producing => const Tag('ÇEKİMDE', color: AppColors.yellow),
      TenderStatus.delivered => const Tag(
        'TESLİM EDİLDİ ✓',
        color: AppColors.green,
      ),
      TenderStatus.lost => const Tag('KAYBEDİLDİ', color: AppColors.red),
      TenderStatus.expired => const Tag('KATILMADIN', color: AppColors.textDim),
    };
    return Panel(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StageScene(
            prop: d.prop,
            color: AppColors.blue,
            tier: 3,
            width: 120,
            height: 104,
            badge: d.agency.toUpperCase(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        d.title,
                        maxLines: 2,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    statusTag,
                  ],
                ),
                Text(
                  d.desc,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tahmini bedel ${fmtShort(t.budget)} · ${d.days} gün · +${d.prestige} prestij',
                  style: const TextStyle(
                    color: AppColors.yellow,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    for (final e in d.equip)
                      Tag(
                        equipById(e)!.name,
                        color: game.ownedEquip.contains(e)
                            ? AppColors.green
                            : AppColors.red,
                        icon: game.ownedEquip.contains(e)
                            ? Icons.check_rounded
                            : Icons.close_rounded,
                      ),
                    for (final c in d.crew.entries)
                      Tag('${c.value} ${c.key.label}', color: c.key.color),
                    if (d.minLevel > 1)
                      Tag(
                        'Stüdyo Sv${d.minLevel}',
                        color: game.studioLevel + 1 >= d.minLevel
                            ? AppColors.green
                            : AppColors.red,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                if (t.status == TenderStatus.open && t.myBid == null)
                  why == null
                      ? AccentButton(
                          'Teklif ver',
                          compact: true,
                          icon: Icons.gavel_rounded,
                          onTap: () => showBidDialog(context, t),
                        )
                      : Text(
                          '🔒 $why',
                          style: const TextStyle(
                            color: AppColors.orange,
                            fontSize: 12,
                          ),
                        ),
                if (t.status == TenderStatus.open && t.myBid != null)
                  Text(
                    'Teklifin ${fmtShort(t.myBid!)} · kalite ×${fmtDec(t.qualityFactor, 2)} · teminat ${fmtShort(t.deposit)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                if (t.status == TenderStatus.producing) ...[
                  Bar(1 - t.prodLeft / d.days, color: AppColors.yellow),
                  Text(
                    '${fmtDec(t.prodLeft, 1)} gün kaldı · teslimde ${fmtShort(t.myBid!)}+prim',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (t.status == TenderStatus.delivered)
                  Text(
                    'Alınan ödeme ${fmtShort(t.paid)}',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 12,
                    ),
                  ),
                if (t.status == TenderStatus.lost ||
                    t.status == TenderStatus.expired)
                  Text(
                    'Kazanan: ${t.winner} · ${fmtShort(t.winningBid ?? 0)}'
                    '${t.myBid != null ? ' (senin teklifin ${fmtShort(t.myBid!)})' : ''}',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showBidDialog(BuildContext context, Tender t) => showDialog(
  context: context,
  builder: (_) => Dialog(child: _Bid(t: t)),
);

class _Bid extends StatefulWidget {
  final Tender t;
  const _Bid({required this.t});
  @override
  State<_Bid> createState() => _BidState();
}

class _BidState extends State<_Bid> {
  double _pct = 0.84;
  final Set<String> _crew = {};
  bool _filled = false;

  void _autoFill(Game g) {
    _crew.clear();
    widget.t.def.crew.forEach((role, n) {
      final free = g.freeStaff(role)
        ..sort((a, b) => b.skill.compareTo(a.skill));
      for (final p in free.take(n)) {
        _crew.add(p.id);
      }
    });
  }

  Widget _step(String label, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.panelHi,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      );

  Widget _strategy(Game game, Tender t, double q, String label, double pct) {
    final bid = (t.budget * pct / 1000).round() * 1000.0;
    final ch = game.tenderWinChance(t, bid, q);
    final sel = (_pct - pct).abs() < 0.005;
    final profit = bid - t.productionCost;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _pct = pct),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: sel ? AppColors.accent.withValues(alpha: 0.18) : AppColors.panelHi,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.accent : AppColors.border, width: sel ? 2 : 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          Text('%${(pct * 100).round()} · ${fmtShort(bid)}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          Text('Kâr ${fmtSigned(profit)}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: profit >= 0 ? AppColors.green : AppColors.red)),
          const SizedBox(height: 4),
          Bar(ch, color: ch >= 0.6 ? AppColors.green : (ch >= 0.3 ? AppColors.yellow : AppColors.red), height: 5),
          Text('Şans %${(ch * 100).round()}',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    if (!_filled) {
      _filled = true;
      _autoFill(game);
    }
    final t = widget.t;
    final crew = _crew.map(game.staffById).whereType<Staff>().toList();
    final bid = (t.budget * _pct / 1000).round() * 1000.0;
    final q = game.tenderQuality(t, crew);
    final profit = bid - t.productionCost;
    final missing = [
      for (final e in t.def.crew.entries)
        if (crew.where((c) => c.role == e.key).length < e.value)
          '${e.value - crew.where((c) => c.role == e.key).length} ${e.key.label}',
    ];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 720),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📨 ${t.def.title}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              '${t.def.agency} · tahmini bedel ${fmtShort(t.budget)} · zarflar ${t.closesDay}. gün açılır',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Teklifin'),
                      Row(
                        children: [
                          Text(
                            fmtShort(bid),
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Tag(
                            'bedelin %${(_pct * 100).round()}',
                            color: AppColors.cyan,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Hazır stratejiler: kazanma şansı ve kâr yan yana
                      Row(
                        children: [
                          for (final st in const [
                            ('🛡️ Garantici', 0.76),
                            ('⚖️ Dengeli', 0.84),
                            ('💰 Kârlı', 0.92),
                            ('🎲 Riskli', 1.0),
                          ])
                            Expanded(child: _strategy(game, t, q, st.$1, st.$2)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('İnce ayar',
                              style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                          const SizedBox(width: 8),
                          _step('−1%', () => setState(() => _pct = (_pct - 0.01).clamp(0.5, 1.2))),
                          const SizedBox(width: 6),
                          _step('+1%', () => setState(() => _pct = (_pct + 0.01).clamp(0.5, 1.2))),
                          const Spacer(),
                          Builder(builder: (_) {
                            final ch = game.tenderWinChance(t, bid, q);
                            return Tag('Kazanma şansı %${(ch * 100).round()}',
                                color: ch >= 0.6
                                    ? AppColors.green
                                    : (ch >= 0.3 ? AppColors.yellow : AppColors.red));
                          }),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Yapım maliyeti ${fmtShort(t.productionCost)} (kazanırsan ödenir)',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Tahmini kâr ${fmtSigned(profit)}',
                        style: TextStyle(
                          color: profit >= 0 ? AppColors.green : AppColors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Teminat (iade edilir) ${fmtShort(bid * 0.05)}',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kalite çarpanın ×${fmtDec(q, 2)} → puan ${fmtShort(bid / q)}',
                        style: const TextStyle(
                          color: AppColors.yellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Rakipler genelde bedelin %78-100\'ü arasında teklif verir. Düşük teklif kazandırır ama kârı azaltır.',
                        style: TextStyle(
                          color: AppColors.textFaint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox(
                  width: 250,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Ekip'),
                      for (final e in t.def.crew.entries) ...[
                        Text(
                          '${e.key.label} · ${crew.where((c) => c.role == e.key).length}/${e.value}',
                          style: TextStyle(
                            color: e.key.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final p in game.freeStaff(e.key))
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => setState(() {
                                  if (_crew.contains(p.id)) {
                                    _crew.remove(p.id);
                                  } else {
                                    final same = crew
                                        .where((c) => c.role == e.key)
                                        .toList();
                                    if (same.length >= e.value)
                                      _crew.remove(same.first.id);
                                    _crew.add(p.id);
                                  }
                                }),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    3,
                                    3,
                                    8,
                                    3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _crew.contains(p.id)
                                        ? e.key.color.withValues(alpha: 0.3)
                                        : AppColors.panelHi,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _crew.contains(p.id)
                                          ? e.key.color
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      PersonAvatar(name: p.name, seed: p.id.hashCode, age: p.age, star: p.isStar,
                                        color: e.key.color,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${p.name.split(' ').first} · ${p.skill}',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        if (crew.where((c) => c.role == e.key).length < e.value)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: GhostButton(
                              '${e.key.label} işe al',
                              compact: true,
                              color: AppColors.orange,
                              icon: Icons.person_add_alt_1_rounded,
                              onTap: () async {
                                final hired = await showQuickHire(context, e.key);
                                if (hired != null) setState(() => _crew.add(hired.id));
                              },
                            ),
                          ),
                        const SizedBox(height: 4),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AccentButton(
              missing.isEmpty ? 'Zarfı gönder' : 'Eksik: ${missing.join(', ')}',
              expand: true,
              icon: Icons.send_rounded,
              onTap: missing.isEmpty
                  ? () {
                      final err = game.bidTender(t, bid, crew);
                      report(context, err);
                      if (err == null) Navigator.pop(context);
                    }
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
