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
import '../dialogs/shop_dialog.dart';
import '../widgets/scene.dart';
import 'production_screen.dart' show showQuickHire;

class CinemaScreen extends StatelessWidget {
  const CinemaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    List<Film> by(FilmStatus st) =>
        game.films.where((f) => f.status == st).toList();
    final groups = [
      ('Gösterime hazır', by(FilmStatus.ready), AppColors.green),
      ('Çekimde', by(FilmStatus.producing), AppColors.yellow),
      ('Vizyonda', by(FilmStatus.inTheaters), AppColors.accent),
      (
        'Film kütüphanem · haklar bende',
        by(FilmStatus.library),
        AppColors.cyan,
      ),
      ('Hakları satılanlar', by(FilmStatus.rightsSold), AppColors.textDim),
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            const Expanded(
              child: PageHint(
                'Film çek → vizyona sok (gişe) → dijital platformlara 30 günlük '
                'lisansla sat. Haklar sende kalır, tekrar tekrar satabilirsin. '
                'Ya da hakları tek seferde yüklü bir paraya sat.',
              ),
            ),
            const SizedBox(width: 10),
            AccentButton(
              'Yeni film',
              icon: Icons.movie_rounded,
              onTap: () => openNewFilmWizard(context),
            ),
          ],
        ),
        if (game.films.isEmpty)
          const Panel(
            child: Text(
              'Henüz filmin yok. Komedi ve korku ucuz ve hızlı çekilir, ilk film için ideal!',
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
              minItemWidth: 320,
              spacing: 10,
              children: [for (final f in g.$2) _FilmCard(film: f)],
            ),
          ],
      ],
    );
  }
}

class _FilmCard extends StatelessWidget {
  final Film film;
  const _FilmCard({required this.film});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final f = film;
    final hasScore = f.status != FilmStatus.producing;
    return Panel(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StageScene(
            talk: true,
            // çekimdeyken set, sonra sinema salonu
            prop: f.status == FilmStatus.producing ? Prop.filmSet : Prop.film,
            live: f.status == FilmStatus.producing,
            color: f.def.color,
            tier: f.tier,
            width: 120,
            height: 100,
            badge: f.def.label.toUpperCase(),
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
                        f.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (hasScore)
                      Tag(
                        '★ ${fmtDec(f.score, 1)}',
                        color: f.score >= 7
                            ? AppColors.green
                            : f.score >= 5
                            ? AppColors.yellow
                            : AppColors.orange,
                      ),
                  ],
                ),
                Text(
                  '${budgetTiers[f.tier].label} bütçe · maliyet ${fmtShort(f.cost)}'
                  '${f.totalIncome > 0 ? ' · kazanç ${fmtShort(f.totalIncome)}' : ''}',
                  style: TextStyle(color: f.def.color, fontSize: 12),
                ),
                const SizedBox(height: 6),
                ..._body(context, game, f),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(BuildContext context, Game game, Film f) {
    switch (f.status) {
      case FilmStatus.producing:
        final total = f.def.prodDays * game.prodSpeedMult();
        return [
          Bar(1 - f.prodLeft / max(total, 0.01), color: AppColors.yellow),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  '${fmtDec(f.prodLeft, 1)} gün kaldı',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              if (game.adBoostsLeft(f.id) > 0)
                GhostButton(
                  '📺 1 gün',
                  compact: true,
                  color: AppColors.green,
                  onTap: () async {
                    if (await watchAd(context)) report(context, game.adSpeedUpFilm(f));
                  },
                ),
              GhostButton(
                'Hızlandır · ${game.filmSpeedUpCost(f)} 💎',
                compact: true,
                onTap: () => report(context, game.speedUpFilm(f)),
              ),
            ],
          ),
        ];
      case FilmStatus.ready:
        return [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AccentButton(
                'Vizyona sok',
                compact: true,
                icon: Icons.local_movies_rounded,
                onTap: () => report(context, game.releaseInTheaters(f)),
              ),
              GhostButton(
                'Doğrudan platforma',
                compact: true,
                icon: Icons.cast_rounded,
                onTap: () => showLicenseDialog(context, f),
              ),
            ],
          ),
        ];
      case FilmStatus.inTheaters:
        return [
          Bar(f.theaterDay / theaterRunDays, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(
            'Vizyonda ${f.theaterDay + 1}/$theaterRunDays. gün · '
            'gişe ${fmtShort(f.boxOffice)} · bugün ~${fmtShort(boxOfficeForDay(f, f.theaterDay, game.reach, game.boxOfficeBonus))}',
            style: const TextStyle(fontSize: 12),
          ),
        ];
      case FilmStatus.library:
        final active = f.licenses
            .map((l) => '${platformById(l.platformId)?.name} ${l.daysLeft}g')
            .join(', ');
        return [
          Text(
            active.isEmpty
                ? 'Şu an hiçbir platformda değil.'
                : 'Lisanslar: $active',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          if (f.onOwnPlatform)
            Text(
              'Kendi platformunda yayında · +${fmtShort(filmValue(f) * 0.004 * f.def.streaming)}/gün',
              style: const TextStyle(color: AppColors.green, fontSize: 12),
            ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AccentButton(
                'Platformlara sat',
                compact: true,
                icon: Icons.cast_rounded,
                onTap: () => showLicenseDialog(context, f),
              ),
              if (game.ownedPlatforms.isNotEmpty)
                GhostButton(
                  f.onOwnPlatform
                      ? 'Kendi platformumdan kaldır'
                      : 'Kendi platformuma koy',
                  compact: true,
                  color: AppColors.green,
                  onTap: () => report(context, game.toggleOwnPlatform(f)),
                ),
              GhostButton(
                'Hakları sat · ${fmtShort(game.rightsValueFor(f))}',
                compact: true,
                color: AppColors.yellow,
                onTap: () async {
                  final ok = await confirm(
                    context,
                    '"${f.name}" haklarını sat?',
                    'Film tamamen başka şirkete geçer. Bir daha lisans satamazsın. '
                        'Karşılığında ${fmtShort(game.rightsValueFor(f))} alırsın.',
                    ok: 'Sat',
                  );
                  if (ok && context.mounted)
                    report(context, game.sellRights(f));
                },
              ),
            ],
          ),
        ];
      case FilmStatus.rightsSold:
        return [
          Text(
            'Haklar ${fmtShort(f.soldFor)} karşılığında satıldı.',
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 6),
          GhostButton(
            'Arşive kaldır',
            compact: true,
            color: AppColors.textDim,
            onTap: () => game.deleteFilm(f),
          ),
        ];
    }
  }
}

/// Platformların bu film için teklifleri
Future<void> showLicenseDialog(BuildContext context, Film f) {
  return showDialog(
    context: context,
    builder: (c) {
      final game = GameScope.of(c);
      return AlertDialog(
        title: Text('"${f.name}" · platform teklifleri'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lisans $licenseDays gün sürer, haklar sende kalır. '
                  'Her satışta filmin piyasa değeri biraz düşer.',
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                // Lisans mı, hak satışı mı? Karşılaştırma ve öneri
                Builder(builder: (_) {
                  final now = game.licensablePlatforms(f).fold(0.0, (a, p) => a + game.licenseOfferFor(f, p));
                  final life = game.licenseLifetime(f);
                  final rights = game.rightsValueFor(f);
                  final licBetter = life > rights * 1.1;
                  return Panel(
                    padding: const EdgeInsets.all(10),
                    color: AppColors.panelHi,
                    borderColor: AppColors.yellow.withValues(alpha: 0.5),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: StatBlock('Bu ay tüm platformlar', fmtShort(now), color: AppColors.cyan)),
                        Expanded(child: StatBlock('12 ayda lisanslarla', fmtShort(life), color: AppColors.green)),
                        Expanded(child: StatBlock('Hakları şimdi sat', fmtShort(rights), color: AppColors.yellow)),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        licBetter
                            ? '💡 Öneri: Lisansla. Haklar sende kalır, her ay tekrar satarsın; 12 ayda hak satışının '
                                '${fmtDec(life / max(1, rights), 1)} katı kazanırsın. Hemen paraya ihtiyacın varsa hakları sat.'
                            : '💡 Öneri: Hakları sat. Bu film için platformlar az ödüyor; tek seferde daha çok kazanırsın.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        if (now > 0)
                          AccentButton('Hepsine lisansla · ${fmtShort(now)}', compact: true, onTap: () {
                            report(c, game.licenseAll(f));
                          }),
                        const SizedBox(width: 6),
                        GhostButton('Hakları sat · ${fmtShort(rights)}', compact: true, color: AppColors.yellow,
                            onTap: () {
                          report(c, game.sellRights(f));
                          Navigator.pop(c);
                        }),
                      ]),
                    ]),
                  );
                }),
                const SizedBox(height: 8),
                for (final p in platformDefs) _offerRow(c, game, f, p),
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

Widget _offerRow(BuildContext c, Game game, Film f, PlatformDef p) {
  final owned = game.ownedPlatforms.contains(p.id);
  final active = f.licenses.where((l) => l.platformId == p.id).firstOrNull;
  final minScore = game.minScoreFor(p);
  final tooLow = f.score < minScore;
  String sub;
  if (owned) {
    sub = 'Bu platform senin';
  } else if (active != null) {
    sub = 'Lisans sürüyor · ${active.daysLeft} gün kaldı';
  } else if (tooLow) {
    sub = 'En az ★${fmtDec(minScore, 0)} puan istiyor';
  } else {
    sub = '${fmtDec(p.subscribersM, 1)} M abone · ${p.tagline}';
  }
  final can = !owned && active == null && !tooLow;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Panel(
      padding: const EdgeInsets.all(10),
      color: AppColors.panelHi,
      child: Row(
        children: [
          _PlatformLogo(p: p, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  sub,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AccentButton(
            can ? 'Sat · ${fmtShort(game.licenseOfferFor(f, p))}' : '—',
            compact: true,
            onTap: can ? () => report(c, game.licenseFilm(f, p)) : null,
          ),
        ],
      ),
    ),
  );
}

class _PlatformLogo extends StatelessWidget {
  final PlatformDef p;
  final double size;
  const _PlatformLogo({required this.p, this.size = 56});
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(size * 0.22),
      gradient: LinearGradient(
        colors: [p.color, Color.lerp(p.color, AppColors.bg, 0.6)!],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    alignment: Alignment.center,
    child: Icon(
      Icons.play_arrow_rounded,
      color: Colors.white,
      size: size * 0.6,
    ),
  );
}

Widget platformLogo(PlatformDef p, {double size = 56}) =>
    _PlatformLogo(p: p, size: size);

Future<void> openNewFilmWizard(BuildContext context) => showDialog(
  context: context,
  builder: (_) => const Dialog(
    insetPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    child: NewFilmWizard(),
  ),
);

/// Yeni film sihirbazı
class NewFilmWizard extends StatefulWidget {
  const NewFilmWizard({super.key});
  @override
  State<NewFilmWizard> createState() => _NewFilmWizardState();
}

class _NewFilmWizardState extends State<NewFilmWizard> {
  FilmGenre _genre = FilmGenre.komedi;
  int _tier = 1;
  String? _loc;
  final _name = TextEditingController();
  final Set<String> _crew = {};
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _suggest();
  }

  void _suggest() {
    final ideas = filmNameIdeas[_genre]!;
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
    final def = filmGenreDefs[_genre]!;
    if (_loc != null && !game.ownedLocations.contains(_loc)) _loc = null;
    final cost =
        filmCost(_genre, _tier) + game.filmLocationFee(_genre, _tier, _loc);
    final crew = _crew.map(game.staffById).whereType<Staff>().toList();
    final q =
        (game.filmQuality(crew, _tier) * game.filmExtraMult(crew, _genre, _loc))
            .clamp(0.0, 1.5);
    final locs = locationDefs
        .where((l) => game.ownedLocations.contains(l.id))
        .toList();
    var complete = true;
    for (final e in def.needs.entries) {
      if (crew.where((c) => c.role == e.key).length < e.value) complete = false;
    }
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionLabel('1 · Tür'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [for (final g in FilmGenre.values) _chip(game, g)],
        ),
        const SizedBox(height: 6),
        Text(
          def.desc,
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Gişe çekiciliği ×${fmtDec(def.boxOffice, 2)} · platform çekiciliği ×${fmtDec(def.streaming, 2)}',
          style: const TextStyle(color: AppColors.cyan, fontSize: 12),
        ),
        const SizedBox(height: 12),
        const SectionLabel('2 · Bütçe'),
        const SizedBox(height: 6),
        PillTabs(
          labels: [
            for (int i = 0; i < budgetTiers.length; i++)
              '${budgetTiers[i].label} · ${fmtShort(filmCost(_genre, i))}',
          ],
          selected: _tier,
          onChanged: (i) => setState(() => _tier = i),
        ),
        const SizedBox(height: 12),
        const SectionLabel('📍 Çekim yeri'),
        const SizedBox(height: 6),
        if (locs.isEmpty)
          const Text(
            'Harita\'dan set kurarsan filmini Kapadokya\'da, Los Angeles\'ta çekebilirsin.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 12),
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: const Text('Stüdyo'),
                selected: _loc == null,
                onSelected: (_) => setState(() => _loc = null),
              ),
              for (final l in locs)
                ChoiceChip(
                  label: Text(
                    '${l.city}${game.locationFitsFilm(l, _genre) ? ' ⭐+%${(l.bonus * 100).round()}' : ''}',
                  ),
                  selected: _loc == l.id,
                  onSelected: (_) => setState(() => _loc = l.id),
                ),
            ],
          ),
        const SizedBox(height: 12),
        const SectionLabel('3 · İsim'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _name,
                maxLength: 28,
                decoration: const InputDecoration(
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(_suggest),
              icon: const Icon(Icons.casino_rounded, color: AppColors.accent),
            ),
          ],
        ),
      ],
    );
    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StageScene(
          prop: Prop.filmSet,
          talk: true,
          color: def.color,
          tier: _tier,
          height: 100,
          width: double.infinity,
          badge: def.label.toUpperCase(),
        ),
        const SizedBox(height: 10),
        const SectionLabel('4 · Ekip'),
        for (final e in def.needs.entries) _roleRow(game, e.key, e.value),
        const Divider(color: AppColors.border, height: 18),
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
                'Tahmini puan',
                '★ ${fmtDec(filmScore(q, 1), 1)}',
                color: AppColors.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AccentButton(
          complete
              ? (game.cash >= cost
                    ? 'Çekimlere başla'
                    : 'Kasada yeterli para yok')
              : 'Eksik: ${[for (final e in def.needs.entries)
                  if (crew.where((c) => c.role == e.key).length < e.value) '${e.value - crew.where((c) => c.role == e.key).length} ${e.key.label}'].join(', ')}',
          expand: true,
          icon: complete ? Icons.videocam_rounded : Icons.info_outline_rounded,
          onTap: complete && game.cash >= cost
              ? () {
                  final err = game.createFilm(
                    _name.text,
                    _genre,
                    _tier,
                    crew,
                    location: _loc,
                  );
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
            Row(
              children: [
                const Text(
                  'Yeni film',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            LayoutBuilder(
              builder: (ctx, c) {
                if (c.maxWidth < 640) {
                  return Column(
                    children: [left, const SizedBox(height: 16), right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 20),
                    Expanded(child: right),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(Game game, FilmGenre g) {
    final d = filmGenreDefs[g]!;
    final unlocked = game.filmGenreUnlocked(g);
    final sel = g == _genre;
    return GestureDetector(
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              unlocked ? d.icon : Icons.lock_rounded,
              size: 16,
              color: unlocked ? d.color : AppColors.textFaint,
            ),
            const SizedBox(width: 5),
            Text(
              d.label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: unlocked ? AppColors.text : AppColors.textFaint,
              ),
            ),
          ],
        ),
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
          Text(
            '${role.label} · $picked/$count',
            style: TextStyle(
              color: picked >= count ? AppColors.green : role.color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
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
                  if (hired != null) setState(() => _crew.add(hired.id));
                },
              ),
            ),
          if (free.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final p in free)
                  FilterChip(
                    selected: _crew.contains(p.id),
                    showCheckmark: false,
                    selectedColor: role.color.withValues(alpha: 0.3),
                    backgroundColor: AppColors.panelHi,
                    side: BorderSide(
                      color: _crew.contains(p.id)
                          ? role.color
                          : AppColors.border,
                    ),
                    label: Text(
                      '${p.name.split(' ').first} · ${p.skill}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onSelected: (v) => setState(() {
                      if (v) {
                        if (picked >= count) {
                          _crew.remove(
                            free.firstWhere((x) => _crew.contains(x.id)).id,
                          );
                        }
                        _crew.add(p.id);
                      } else {
                        _crew.remove(p.id);
                      }
                    }),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
