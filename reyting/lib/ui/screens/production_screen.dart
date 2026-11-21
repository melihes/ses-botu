import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../data/content2.dart';
import '../../engine/economy.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';
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
        Row(
          children: [
            const Expanded(
              child: PageHint(
                'Tür, bütçe ve kadro yeteneği programın kalitesini belirler. '
                'Kalite = daha yüksek reyting + daha uzun reklama tahammül.',
              ),
            ),
            const SizedBox(width: 10),
            AccentButton(
              'Yeni program',
              icon: Icons.add_rounded,
              onTap: () => openNewShowWizard(context),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (game.shows.isEmpty)
          const Panel(
            child: Text(
              'Henüz programın yok. "Yeni program" ile ilk yapımını başlat!',
              style: TextStyle(color: AppColors.textDim),
            ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StageScene(
            talk:
                s.status == ShowStatus.onAir ||
                s.status == ShowStatus.producing,
            prop: propFor(s.genre, s.tier),
            color: s.def.color,
            tier: max(0, s.tier + s.budget - 1),
            live: s.status == ShowStatus.onAir,
            width: 130,
            height: 96,
            badge: '${s.season}. SEZON',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    statusTag,
                  ],
                ),
                Text(
                  '${s.def.label} · ${formatOf(s.genre, s.tier).name} · '
                  'Kalite ${(s.quality * 100).round()}',
                  style: TextStyle(color: s.def.color, fontSize: 12),
                ),
                Text(
                  crew.isEmpty ? '' : 'Ekip: $crew',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    Tag(
                      '💰 ${prodBudgets[s.budget].label}',
                      color: AppColors.yellow,
                    ),
                    if (s.guest > 0)
                      Tag(
                        '🌟 ${s.guestName ?? guestTiers[s.guest].label}',
                        color: AppColors.pink,
                      ),
                    if (locationById(s.location) != null)
                      Tag(
                        '📍 ${locationById(s.location)!.city}',
                        color: AppColors.cyan,
                      ),
                    if (s.status == ShowStatus.producing ||
                        s.status == ShowStatus.onAir) ...[
                      if (s.budget < prodBudgets.length - 1)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              report(context, game.upgradeShowBudget(s)),
                          child: Tag(
                            '⬆ ${prodBudgets[s.budget + 1].label} · ${fmtShort(game.upgradeBudgetCost(s))}',
                            color: AppColors.green,
                          ),
                        ),
                      if (s.guest < guestTiers.length - 1)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () =>
                              report(context, game.upgradeShowGuest(s)),
                          child: Tag(
                            '⬆ ${guestTiers[s.guest + 1].label} · ${fmtShort(game.upgradeGuestCost(s))}',
                            color: AppColors.green,
                          ),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                ..._actions(context, game, s),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, Game game, Show s) {
    switch (s.status) {
      case ShowStatus.producing:
        final total = s.def.prodDays * game.prodSpeedMult();
        return [
          Bar(1 - s.prodLeft / max(total, 0.01), color: AppColors.yellow),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${fmtDec(s.prodLeft, 1)} gün kaldı',
                style: const TextStyle(fontSize: 12),
              ),
              const Spacer(),
              GhostButton(
                'Hızlandır · ${game.speedUpCost(s)} 💎',
                compact: true,
                onTap: () => report(context, game.speedUp(s)),
              ),
            ],
          ),
        ];
      case ShowStatus.ready:
        return [
          AccentButton(
            'Yayına koy',
            compact: true,
            icon: Icons.live_tv_rounded,
            onTap: () => pickSlotFor(context, s),
          ),
        ];
      case ShowStatus.onAir:
        return [
          Bar(s.seasonProgress, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(
            'Bölüm ${s.episodesAired}/${s.seasonDays} · '
            '${fmtPct(game.currentRating(s), 2)} · '
            'Sezon geliri ${fmtShort(s.seasonRevenue)}',
            style: const TextStyle(fontSize: 12),
          ),
        ];
      case ShowStatus.ended:
        return [
          Text(
            'Toplam gelir ${fmtShort(s.totalRevenue)} · '
            'Yeni sezon: ${fmtShort(game.showCostOf(s))}',
            style: const TextStyle(fontSize: 12, color: AppColors.textDim),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              AccentButton(
                'Yeni sezon',
                compact: true,
                icon: Icons.replay_rounded,
                onTap: () => report(context, game.renewShow(s)),
              ),
              const SizedBox(width: 8),
              GhostButton(
                'Arşive kaldır',
                compact: true,
                color: AppColors.textDim,
                onTap: () => game.deleteShow(s),
              ),
            ],
          ),
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
                for (final id in SlotId.values) _slotOption(c, game, s, id),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Kapat'),
          ),
        ],
      );
    },
  );
}

/// Bu program için kazancı en yüksek olacak boş kuşak
SlotId? bestSlotFor(Game game, Show s) {
  SlotId? best;
  var bestV = -1.0;
  for (final id in SlotId.values) {
    if (!game.slotUnlocked(id) || game.slots[id]!.showId != null) continue;
    final d = slotDefs[id]!;
    final v = game.previewRating(s, id) * d.poolMillions * d.adValue;
    if (v > bestV) {
      bestV = v;
      best = id;
    }
  }
  return best;
}

Widget _slotOption(BuildContext c, Game game, Show s, SlotId id) {
  final def = slotDefs[id]!;
  final unlocked = game.slotUnlocked(id);
  final occupied = game.showById(game.slots[id]!.showId);
  final fit = s.def.fit[def.band] ?? 1;
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
        child: Row(
          children: [
            Icon(
              unlocked ? Icons.schedule_rounded : Icons.lock_rounded,
              color: AppColors.cyan,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${def.label} · ${def.hours}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    !unlocked
                        ? 'Stüdyo seviyesi ${def.unlockLevel} gerekli'
                        : occupied != null
                        ? 'Dolu: ${occupied.name}'
                        : 'Türe uygunluk: ${fit >= 1.1
                              ? 'Mükemmel'
                              : fit >= 0.95
                              ? 'İyi'
                              : fit >= 0.8
                              ? 'Orta'
                              : 'Zayıf'}',
                    style: const TextStyle(
                      color: AppColors.textDim,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (bestSlotFor(game, s) == id)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Tag('⭐ Önerilen', color: AppColors.yellow),
              ),
            if (unlocked)
              Text(
                '~${fmtPct(preview, 1)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyan,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// Yeni program sihirbazını tam ekran açar
Future<void> openNewShowWizard(BuildContext context) => showDialog(
  context: context,
  builder: (_) => const Dialog.fullscreen(
    backgroundColor: AppColors.bg,
    child: NewShowWizard(),
  ),
);

/// Yeni program sihirbazı: tür → format → ekip, tek ekranda
class NewShowWizard extends StatefulWidget {
  const NewShowWizard({super.key});
  @override
  State<NewShowWizard> createState() => _NewShowWizardState();
}

class _NewShowWizardState extends State<NewShowWizard> {
  Genre _genre = Genre.magazin;
  int _tier = 0;
  int _budget = 1;
  int _guest = 0;
  String? _loc;
  final _name = TextEditingController();
  final Set<String> _crew = {};
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _suggest();
  }

  bool _filled = false;

  /// Her rol için boştaki en yetenekli kişileri seçer.
  void _autoFill(Game game) {
    _crew.clear();
    genreDefs[_genre]!.needs.forEach((role, count) {
      final free = game.freeStaff(role)
        ..sort((a, b) => b.skill.compareTo(a.skill));
      for (final p in free.take(count)) {
        _crew.add(p.id);
      }
    });
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
    if (!_filled) {
      _filled = true;
      _autoFill(game);
    }
    final def = genreDefs[_genre]!;
    final fmt = formatOf(_genre, _tier);
    if (_loc != null && !game.ownedLocations.contains(_loc)) _loc = null;
    final cost = game.showCost(_genre, _tier, _budget, _guest, _loc);
    final crewList = _crew.map(game.staffById).whereType<Staff>().toList();
    final quality = game.fullShowQuality(
      crewList,
      _genre,
      _tier,
      _budget,
      _loc,
    );
    var complete = game.formatUnlocked(_genre, _tier);
    for (final e in def.needs.entries) {
      if (crewList.where((c) => c.role == e.key).length < e.value) {
        complete = false;
      }
    }
    final formats = genreFormats[_genre]!;
    final missing = <String>[
      for (final e in def.needs.entries)
        if (crewList.where((c) => c.role == e.key).length < e.value)
          '${e.value - crewList.where((c) => c.role == e.key).length} ${e.key.label}',
    ];

    // 1) Tür listesi
    final genres = SizedBox(
      width: 128,
      child: ListView(
        children: [
          const SectionLabel('1 · Tür'),
          const SizedBox(height: 6),
          for (final g in Genre.values) _genreItem(game, g),
        ],
      ),
    );

    // 2) Format kartları
    final formatGrid = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SectionLabel('2 · ${def.label} formatı', color: def.color),
            const Spacer(),
            Text(
              'Seviye arttıkça maliyet ve reyting artar',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, c) {
              const cols = 3, gap = 6.0;
              final rows = (formats.length / cols).ceil();
              final w = (c.maxWidth - gap * (cols - 1)) / cols;
              final h = max(70.0, (c.maxHeight - gap * (rows - 1)) / rows);
              return SingleChildScrollView(
                child: Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (int i = 0; i < formats.length; i++)
                      SizedBox(
                        width: w,
                        height: h,
                        child: _formatCard(game, i),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fmt.desc,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
        const SizedBox(height: 4),
        _prodOptions(game),
      ],
    );

    // 3) İsim, ekip, özet
    final right = SizedBox(
      width: 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('3 · İsim ve ekip'),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 28,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Başka isim öner',
                onPressed: () => setState(_suggest),
                icon: const Icon(Icons.casino_rounded, color: AppColors.accent),
              ),
            ],
          ),
          // Gerekli roller: tek bakışta ne eksik görünsün
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final e in def.needs.entries)
                Builder(
                  builder: (_) {
                    final n = crewList.where((c) => c.role == e.key).length;
                    final ok = n >= e.value;
                    return Tag(
                      '${ok ? '✓' : '!'} ${e.key.label} $n/${e.value}',
                      color: ok ? AppColors.green : AppColors.orange,
                    );
                  },
                ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _autoFill(game)),
                child: const Tag('⚡ Otomatik seç', color: AppColors.cyan),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView(
              children: [
                for (final e in def.needs.entries)
                  _roleRow(game, e.key, e.value),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: StatBlock(
                  'Maliyet',
                  fmtShort(cost),
                  color: game.cash >= cost ? AppColors.text : AppColors.red,
                ),
              ),
              Expanded(
                child: StatBlock(
                  'Çekim',
                  '${fmtDec(def.prodDays * game.prodSpeedMult(), 1)} gün',
                ),
              ),
              Expanded(
                child: StatBlock(
                  'Kalite',
                  '${(quality * 100).round()}',
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AccentButton(
            complete
                ? (game.cash >= cost
                      ? 'Çekimlere başla'
                      : 'Kasada yeterli para yok')
                : !game.formatUnlocked(_genre, _tier)
                ? 'Bu format kilitli'
                : 'Eksik: ${missing.join(', ')}',
            expand: true,
            icon: complete
                ? Icons.videocam_rounded
                : Icons.info_outline_rounded,
            onTap: complete && game.cash >= cost
                ? () {
                    final err = game.createShow(
                      _name.text,
                      _genre,
                      _tier,
                      crewList,
                      budget: _budget,
                      guest: _guest,
                      location: _loc,
                    );
                    report(context, err);
                    if (err == null) Navigator.pop(context);
                  }
                : null,
          ),
        ],
      ),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Yeni program',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 10),
                Text(
                  'Kasa ${fmtShort(game.cash)}',
                  style: const TextStyle(color: AppColors.textDim),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  genres,
                  const SizedBox(width: 12),
                  Expanded(child: formatGrid),
                  const SizedBox(width: 12),
                  right,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatCard(Game game, int i) {
    final f = genreFormats[_genre]![i];
    final unlocked = game.formatUnlocked(_genre, i);
    final sel = i == _tier;
    final def = genreDefs[_genre]!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!unlocked) {
          game.showToast(
            f.reqEquip != null && !game.ownedEquip.contains(f.reqEquip)
                ? '🔒 ${f.name} için ${equipById(f.reqEquip!)!.name} gerekli.'
                : '🔒 ${f.name} stüdyo seviyesi ${f.unlockLevel} ile açılır.',
          );
          return;
        }
        setState(() => _tier = i);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: sel ? AppColors.accent : AppColors.border,
            width: sel ? 2.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              StageScene(
                prop: f.prop,
                color: def.color,
                tier: sel ? max(0, i + _budget - 1) : i,
                height: 200,
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1],
                    colors: [Colors.transparent, Color(0xEE130F1D)],
                  ),
                ),
              ),
              if (!unlocked) Container(color: Colors.black54),
              Positioned(
                left: 6,
                top: 5,
                child: Tag(
                  'SV ${i + 1}',
                  color: unlocked ? AppColors.yellow : AppColors.textDim,
                ),
              ),
              if (!unlocked)
                const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      unlocked
                          ? '${fmtShort(productionCost(_genre, i))} · kalite ×${fmtDec(f.qualityMult, 2)}'
                          : (f.reqEquip != null &&
                                    !game.ownedEquip.contains(f.reqEquip)
                                ? '${equipById(f.reqEquip!)!.name} gerekli'
                                : 'Stüdyo seviyesi ${f.unlockLevel}'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optChip(
    String label,
    bool sel,
    bool locked,
    VoidCallback onTap, {
    Color color = AppColors.accent,
  }) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(right: 4, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: sel ? color.withValues(alpha: 0.25) : AppColors.panel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: sel ? color : AppColors.border),
      ),
      child: Text(
        locked ? '🔒 $label' : label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: locked
              ? AppColors.textFaint
              : (sel ? AppColors.text : AppColors.textDim),
        ),
      ),
    ),
  );

  Widget _optRow(String title, List<Widget> chips) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 82,
        child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textDim,
            ),
          ),
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: chips),
        ),
      ),
    ],
  );

  /// Bütçe, ünlü konuk ve çekim yeri seçimi
  Widget _prodOptions(Game game) {
    final base = productionCost(_genre, _tier);
    final locs = locationDefs
        .where((l) => game.ownedLocations.contains(l.id))
        .toList();
    final share = game.runShareFor(_budget, _guest, _loc);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (share < 0.999)
          Text(
            'Büyük yapım bölüm başı gider ister: yayın gelirinin %${((1 - share) * 100).round()}\'i '
            'set, konuk ve ekip payına gider. Reyting daha çok artar.',
            style: const TextStyle(fontSize: 10, color: AppColors.textFaint),
          ),
        _optRow('💰 Bütçe', [
          for (int i = 0; i < prodBudgets.length; i++)
            _optChip(
              '${prodBudgets[i].label} ×${fmtDec(prodBudgets[i].qualityMult, 2)}'
              '${prodBudgets[i].share > 0 ? ' · %${(prodBudgets[i].share * 100).round()} pay' : ''}',
              i == _budget,
              !game.budgetUnlocked(i),
              () {
                if (!game.budgetUnlocked(i)) {
                  game.showToast(
                    '🔒 ${prodBudgets[i].label} bütçe stüdyo seviyesi ${prodBudgets[i].unlockLevel} ile açılır.',
                  );
                  return;
                }
                setState(() => _budget = i);
              },
              color: AppColors.yellow,
            ),
        ]),
        _optRow('🌟 ${guestLabelFor(_genre)}', [
          for (int i = 0; i < guestTiers.length; i++)
            _optChip(
              i == 0
                  ? 'Yok'
                  : '${guestTiers[i].label} +%${(guestTiers[i].boost * 100).round()} · ${fmtShort(base * guestTiers[i].feeMult)} · %${(guestTiers[i].share * 100).round()} pay',
              i == _guest,
              !game.guestUnlocked(i),
              () {
                if (!game.guestUnlocked(i)) {
                  game.showToast(
                    '🔒 ${guestTiers[i].label} stüdyo seviyesi ${guestTiers[i].unlockLevel} ile açılır.',
                  );
                  return;
                }
                setState(() => _guest = i);
              },
              color: AppColors.pink,
            ),
        ]),
        _optRow('📍 Çekim yeri', [
          _optChip(
            'Stüdyo',
            _loc == null,
            false,
            () => setState(() => _loc = null),
            color: AppColors.cyan,
          ),
          for (final l in locs)
            _optChip(
              '${l.city}${game.locationFits(l, _genre) ? ' ⭐+%${(l.bonus * 100).round()}' : ''}',
              _loc == l.id,
              false,
              () => setState(() => _loc = l.id),
              color: AppColors.cyan,
            ),
          if (locs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Harita\'dan set kurarsan burada seçebilirsin',
                style: TextStyle(fontSize: 11, color: AppColors.textFaint),
              ),
            ),
        ]),
      ],
    );
  }

  Widget _genreItem(Game game, Genre g) {
    final d = genreDefs[g]!;
    final unlocked = game.genreUnlocked(g);
    final sel = g == _genre;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!unlocked) {
            game.showToast(
              '🔒 ${d.label} için ${equipById(d.reqEquip!)!.name} gerekli (Stüdyo).',
            );
            return;
          }
          setState(() {
            _genre = g;
            _tier = 0;
            _guest = 0;
            _suggest();
            _autoFill(game);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            color: sel ? d.color.withValues(alpha: 0.22) : AppColors.panel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? d.color : AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                unlocked ? d.icon : Icons.lock_rounded,
                size: 16,
                color: unlocked ? d.color : AppColors.textFaint,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: unlocked ? AppColors.text : AppColors.textFaint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleRow(Game game, Role role, int count) {
    final free = game.freeStaff(role);
    final picked = free.where((p) => _crew.contains(p.id)).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${role.label} · $picked/$count',
            style: TextStyle(
              color: picked >= count ? AppColors.green : role.color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          if (free.length < count)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GhostButton(
                free.isEmpty
                    ? 'Boşta ${role.label.toLowerCase()} yok · İşe al'
                    : '${count - free.length} ${role.label.toLowerCase()} daha gerekli · İşe al',
                compact: true,
                color: AppColors.orange,
                icon: Icons.person_add_alt_1_rounded,
                onTap: () async {
                  final hired = await showQuickHire(context, role);
                  if (hired != null) {
                    setState(() {
                      final mine = _crew
                          .where((id) => game.staffById(id)?.role == role)
                          .toList();
                      if (mine.length >= count) _crew.remove(mine.first);
                      _crew.add(hired.id);
                    });
                  }
                },
              ),
            ),
          if (free.isNotEmpty)
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: [
                for (final p in free)
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() {
                      if (_crew.contains(p.id)) {
                        _crew.remove(p.id);
                      } else {
                        if (picked >= count) {
                          _crew.remove(
                            free.firstWhere((x) => _crew.contains(x.id)).id,
                          );
                        }
                        _crew.add(p.id);
                      }
                    }),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(3, 3, 8, 3),
                      decoration: BoxDecoration(
                        color: _crew.contains(p.id)
                            ? role.color.withValues(alpha: 0.3)
                            : AppColors.panelHi,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _crew.contains(p.id)
                              ? role.color
                              : AppColors.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PersonAvatar(
                            seed: p.id.hashCode,
                            color: role.color,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${p.name.split(' ').first} · ${p.skill}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Yapım penceresinden çıkmadan belirli bir rol için işe alma
Future<Staff?> showQuickHire(BuildContext context, Role role) {
  return showDialog<Staff>(
    context: context,
    builder: (c) {
      final game = GameScope.of(c);
      final cands = game.market.where((p) => p.role == role).toList()
        ..sort((a, b) => b.skill.compareTo(a.skill));
      return AlertDialog(
        title: Text('${role.label} işe al'),
        content: SizedBox(
          width: 460,
          child: cands.isEmpty
              ? Text(
                  'Şu an iş ilanlarında ${role.label.toLowerCase()} yok. '
                  'Kadro ekranından "Yeni adaylar" ile listeyi yenileyebilirsin.',
                )
              : SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final p in cands)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              PersonAvatar(
                                seed: p.id.hashCode,
                                color: role.color,
                                size: 36,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p.name} · yetenek ${p.skill}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'Maaş ${fmtShort(p.salary)}/gün',
                                      style: const TextStyle(
                                        color: AppColors.textDim,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AccentButton(
                                'İşe al · ${fmtShort(p.signingFee)}',
                                compact: true,
                                onTap: () {
                                  final err = game.hire(p);
                                  report(c, err);
                                  if (err == null) Navigator.pop(c, p);
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Kapat'),
          ),
        ],
      );
    },
  );
}
