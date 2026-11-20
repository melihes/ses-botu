import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/economy.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';

class ProductionScreen extends StatelessWidget {
  const ProductionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    List<Show> by(ShowStatus st) =>
        game.shows.where((s) => s.status == st).toList();
    final groups = [
      ('Yayına hazır', by(ShowStatus.ready), AppColors.green),
      ('Çekimde', by(ShowStatus.producing), AppColors.yellow),
      ('Yayında', by(ShowStatus.onAir), AppColors.accent),
      ('Sezonu biten', by(ShowStatus.ended), AppColors.textDim),
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(children: [
          const Expanded(
            child: PageHint(
                'Tür, bütçe ve kadro yeteneği programın kalitesini belirler. '
                'Kalite = daha yüksek reyting + daha uzun reklama tahammül.'),
          ),
          const SizedBox(width: 10),
          AccentButton('Yeni program',
              icon: Icons.add_rounded,
              onTap: () => showDialog(
                  context: context,
                  builder: (_) => const Dialog(
                      insetPadding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: NewShowWizard()))),
        ]),
        const SizedBox(height: 6),
        if (game.shows.isEmpty)
          const Panel(
            child: Text(
                'Henüz programın yok. "Yeni program" ile ilk yapımını başlat!',
                style: TextStyle(color: AppColors.textDim)),
          ),
        for (final g in groups)
          if (g.$2.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 8),
              child: SectionLabel('${g.$1} · ${g.$2.length}', color: g.$3),
            ),
            AutoGrid(
              minItemWidth: 300,
              spacing: 10,
              children: [for (final s in g.$2) _ShowCard(show: s)],
            ),
          ],
      ],
    );
  }
}

class _ShowCard extends StatelessWidget {
  final Show show;
  const _ShowCard({required this.show});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final s = show;
    final statusTag = switch (s.status) {
      ShowStatus.producing => const Tag('ÇEKİMDE', color: AppColors.yellow),
      ShowStatus.ready => const Tag('HAZIR', color: AppColors.green),
      ShowStatus.onAir => const Tag('YAYINDA', color: AppColors.accent),
      ShowStatus.ended => const Tag('SEZON BİTTİ', color: AppColors.textDim),
    };
    final crew = s.staffIds
        .map(game.staffById)
        .whereType<Staff>()
        .map((p) => p.name.split(' ').first)
        .join(', ');
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        StageScene(
            kind: sceneForGenre(s.genre),
            color: s.def.color,
            tier: s.tier,
            live: s.status == ShowStatus.onAir,
            width: 130,
            height: 96,
            badge: '${s.season}. SEZON'),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(s.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w800)),
                ),
                statusTag,
              ]),
              Text(
                  '${s.def.label} · ${budgetTiers[s.tier].label} bütçe · '
                  'Kalite ${(s.quality * 100).round()}',
                  style: TextStyle(color: s.def.color, fontSize: 12)),
              Text(crew.isEmpty ? '' : 'Ekip: $crew',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 8),
              ..._actions(context, game, s),
            ],
          ),
        ),
      ]),
    );
  }

  List<Widget> _actions(BuildContext context, Game game, Show s) {
    switch (s.status) {
      case ShowStatus.producing:
        final total = s.def.prodDays * game.prodSpeedMult();
        return [
          Bar(1 - s.prodLeft / max(total, 0.01), color: AppColors.yellow),
          const SizedBox(height: 6),
          Row(children: [
            Text('${fmtDec(s.prodLeft, 1)} gün kaldı',
                style: const TextStyle(fontSize: 12)),
            const Spacer(),
            GhostButton('Hızlandır · ${game.speedUpCost(s)} 💎',
                compact: true,
                onTap: () => report(context, game.speedUp(s))),
          ]),
        ];
      case ShowStatus.ready:
        return [
          AccentButton('Yayına koy',
              compact: true,
              icon: Icons.live_tv_rounded,
              onTap: () => pickSlotFor(context, s)),
        ];
      case ShowStatus.onAir:
        return [
          Bar(s.seasonProgress, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(
              'Bölüm ${s.episodesAired}/${s.seasonDays} · '
              '${fmtPct(game.currentRating(s), 2)} · '
              'Sezon geliri ${fmtShort(s.seasonRevenue)}',
              style: const TextStyle(fontSize: 12)),
        ];
      case ShowStatus.ended:
        return [
          Text(
              'Toplam gelir ${fmtShort(s.totalRevenue)} · '
              'Yeni sezon: ${fmtShort(productionCost(s.genre, s.tier))}',
              style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
          const SizedBox(height: 6),
          Row(children: [
            AccentButton('Yeni sezon',
                compact: true,
                icon: Icons.replay_rounded,
                onTap: () => report(context, game.renewShow(s))),
            const SizedBox(width: 8),
            GhostButton('Arşive kaldır',
                compact: true,
                color: AppColors.textDim,
                onTap: () => game.deleteShow(s)),
          ]),
        ];
    }
  }
}

/// Hazır programı bir kuşağa yerleştirme penceresi
Future<void> pickSlotFor(BuildContext context, Show s) {
  return showDialog(
    context: context,
    builder: (c) {
      final game = GameScope.of(c);
      return AlertDialog(
        title: Text('"${s.name}" hangi kuşakta yayınlansın?'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final id in SlotId.values)
                  _slotOption(c, game, s, id),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c), child: const Text('Kapat')),
        ],
      );
    },
  );
}

Widget _slotOption(BuildContext c, Game game, Show s, SlotId id) {
  final def = slotDefs[id]!;
  final unlocked = game.slotUnlocked(id);
  final occupied = game.showById(game.slots[id]!.showId);
  final fit = s.def.fit[id] ?? 1;
  final preview = game.previewRating(s, id);
  final enabled = unlocked && occupied == null;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Panel(
      padding: const EdgeInsets.all(10),
      color: AppColors.panelHi,
      onTap: enabled
          ? () {
              report(c, game.putOnAir(s, id));
              Navigator.pop(c);
            }
          : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Row(children: [
          Icon(unlocked ? Icons.schedule_rounded : Icons.lock_rounded,
              color: AppColors.cyan),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${def.label} · ${def.hours}',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(
                    !unlocked
                        ? 'Stüdyo seviyesi ${def.unlockLevel} gerekli'
                        : occupied != null
                            ? 'Dolu: ${occupied.name}'
                            : 'Türe uygunluk: ${fit >= 1.1 ? 'Mükemmel' : fit >= 0.95 ? 'İyi' : fit >= 0.8 ? 'Orta' : 'Zayıf'}',
                    style: const TextStyle(
                        color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
          if (unlocked)
            Text('~${fmtPct(preview, 1)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w900, color: AppColors.cyan)),
        ]),
      ),
    ),
  );
}

/// Yeni program sihirbazı: tür → bütçe → isim → ekip
class NewShowWizard extends StatefulWidget {
  const NewShowWizard({super.key});
  @override
  State<NewShowWizard> createState() => _NewShowWizardState();
}

class _NewShowWizardState extends State<NewShowWizard> {
  Genre _genre = Genre.magazin;
  int _tier = 1;
  final _name = TextEditingController();
  final Set<String> _crew = {};
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _suggest();
  }

  void _suggest() {
    final ideas = showNameIdeas[_genre]!;
    _name.text = ideas[_rng.nextInt(ideas.length)];
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final def = genreDefs[_genre]!;
    final cost = productionCost(_genre, _tier);
    final crewList =
        _crew.map(game.staffById).whereType<Staff>().toList();
    final quality = showQuality(crewList, _genre, _tier, game.ownedEquip);
    var complete = true;
    for (final e in def.needs.entries) {
      if (crewList.where((c) => c.role == e.key).length < e.value) {
        complete = false;
      }
    }

    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('1 · Tür'),
        const SizedBox(height: 6),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final g in Genre.values) _genreChip(game, g),
        ]),
        const SizedBox(height: 6),
        Text(def.desc,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
        const SizedBox(height: 12),
        const SectionLabel('2 · Bütçe'),
        const SizedBox(height: 6),
        PillTabs(
          labels: [
            for (int i = 0; i < budgetTiers.length; i++)
              '${budgetTiers[i].label} · ${fmtShort(productionCost(_genre, i))}'
          ],
          selected: _tier,
          onChanged: (i) => setState(() => _tier = i),
        ),
        const SizedBox(height: 12),
        const SectionLabel('3 · İsim'),
        Row(children: [
          Expanded(
            child: TextField(
              controller: _name,
              maxLength: 28,
              decoration:
                  const InputDecoration(counterText: '', isDense: true),
            ),
          ),
          IconButton(
            tooltip: 'Başka isim öner',
            onPressed: () => setState(_suggest),
            icon: const Icon(Icons.casino_rounded, color: AppColors.accent),
          ),
        ]),
      ],
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StageScene(
            kind: sceneForGenre(_genre),
            color: def.color,
            tier: _tier,
            height: 110,
            width: double.infinity,
            badge: '${def.label} · ${budgetTiers[_tier].label} bütçe'),
        const SizedBox(height: 10),
        const SectionLabel('4 · Ekip'),
        const SizedBox(height: 4),
        for (final e in def.needs.entries) _roleRow(game, e.key, e.value),
        const Divider(color: AppColors.border, height: 20),
        Row(children: [
          Expanded(
              child: StatBlock('Maliyet', fmtShort(cost),
                  color: game.cash >= cost ? AppColors.text : AppColors.red)),
          Expanded(
              child: StatBlock('Çekim',
                  '${fmtDec(def.prodDays * game.prodSpeedMult(), 1)} gün')),
          Expanded(
              child: StatBlock('Sezon', '${def.seasonDays} bölüm')),
          Expanded(
              child: StatBlock('Kalite', '${(quality * 100).round()}',
                  color: AppColors.cyan)),
        ]),
        const SizedBox(height: 12),
        AccentButton(
          'Çekimlere başla',
          expand: true,
          icon: Icons.videocam_rounded,
          onTap: complete
              ? () {
                  final err =
                      game.createShow(_name.text, _genre, _tier, crewList);
                  report(context, err);
                  if (err == null) Navigator.pop(context);
                }
              : null,
        ),
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 980),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Text('Yeni program',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const Spacer(),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded)),
            ]),
            LayoutBuilder(builder: (ctx, c) {
              if (c.maxWidth < 640) {
                return Column(
                    children: [left, const SizedBox(height: 16), right]);
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 20),
                  Expanded(child: right),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _genreChip(Game game, Genre g) {
    final d = genreDefs[g]!;
    final unlocked = game.genreUnlocked(g);
    final sel = g == _genre;
    return GestureDetector(
      onTap: () {
        if (!unlocked) {
          game.showToast(
              '🔒 ${d.label} için ${equipById(d.reqEquip!)!.name} gerekli (Stüdyo).');
          return;
        }
        setState(() {
          _genre = g;
          _crew.clear();
          _suggest();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: sel ? d.color.withValues(alpha: 0.22) : AppColors.panelHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: sel ? d.color : AppColors.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(unlocked ? d.icon : Icons.lock_rounded,
              size: 16, color: unlocked ? d.color : AppColors.textFaint),
          const SizedBox(width: 5),
          Text(d.label,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: unlocked ? AppColors.text : AppColors.textFaint)),
        ]),
      ),
    );
  }

  Widget _roleRow(Game game, Role role, int count) {
    final free = game.freeStaff(role);
    final picked = free.where((p) => _crew.contains(p.id)).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${role.label} · $picked/$count',
              style: TextStyle(
                  color: picked >= count ? AppColors.green : role.color,
                  fontWeight: FontWeight.w800,
                  fontSize: 13)),
          const SizedBox(height: 4),
          if (free.isEmpty)
            Text('Boşta ${role.label.toLowerCase()} yok. Kadro\'dan işe al.',
                style:
                    const TextStyle(color: AppColors.textFaint, fontSize: 12))
          else
            Wrap(spacing: 6, runSpacing: 6, children: [
              for (final p in free)
                FilterChip(
                  selected: _crew.contains(p.id),
                  showCheckmark: false,
                  selectedColor: role.color.withValues(alpha: 0.3),
                  backgroundColor: AppColors.panelHi,
                  side: BorderSide(
                      color: _crew.contains(p.id)
                          ? role.color
                          : AppColors.border),
                  label: Text('${p.name.split(' ').first} · ${p.skill}',
                      style: const TextStyle(fontSize: 12)),
                  onSelected: (v) => setState(() {
                    if (v) {
                      if (picked >= count) {
                        // en eski seçimi bırak
                        final drop = free.firstWhere(
                            (x) => _crew.contains(x.id));
                        _crew.remove(drop.id);
                      }
                      _crew.add(p.id);
                    } else {
                      _crew.remove(p.id);
                    }
                  }),
                ),
            ]),
        ],
      ),
    );
  }
}
