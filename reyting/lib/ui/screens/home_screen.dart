import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../shell.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth > 760;
      final left = Column(children: [
        _CashCard(game: game),
        const SizedBox(height: 12),
        _OnAirStrip(game: game),
      ]);
      final right = Column(children: [
        if (!_tutorialDone(game)) ...[
          _Tutorial(game: game),
          const SizedBox(height: 12),
        ],
        _QuickTiles(game: game),
        const SizedBox(height: 12),
        _EventFeed(game: game),
      ]);
      return SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: wide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 14),
                Expanded(flex: 2, child: right),
              ])
            : Column(children: [left, const SizedBox(height: 12), right]),
      );
    });
  }

  static bool _tutorialDone(Game g) =>
      g.shows.any((s) => s.totalRevenue > 0) ||
      g.films.isNotEmpty ||
      g.day > 20;
}

class _CashCard extends StatelessWidget {
  final Game game;
  const _CashCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final net = game.netPerDay;
    return Panel(
      gradient: const LinearGradient(
        colors: [Color(0xFF2A1E3D), AppColors.panel],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const SectionLabel('Kasa', color: AppColors.textDim),
                    const SizedBox(width: 8),
                    Tag(game.studio.name,
                        color: AppColors.cyan, icon: Icons.domain_rounded),
                  ]),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(fmtFull(game.cash),
                        style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: game.cash < 0
                                ? AppColors.red
                                : AppColors.text)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${net >= 0 ? '▲' : '▼'} ${fmtSigned(net)}/gün net  ·  '
                    '${fmtShort(game.totalViewers).replaceAll(' ₺', '')} izleyici',
                    style: TextStyle(
                        color: net >= 0 ? AppColors.green : AppColors.red,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(
                width: 170,
                height: 70,
                child: Sparkline(game.cashHistory,
                    color: net >= 0 ? AppColors.green : AppColors.red)),
          ]),
          const Divider(color: AppColors.border, height: 22),
          Row(children: [
            Expanded(
                child: StatBlock('Reklam/gün', fmtSigned(game.adIncomePerDay),
                    color: AppColors.green)),
            Expanded(
                child: StatBlock('Diğer gelir/gün',
                    fmtSigned(game.channelIncomePerDay +
                        game.platformIncomePerDay +
                        game.bizIncomePerDay +
                        game.boxOfficePerDay),
                    color: AppColors.green)),
            Expanded(
                child: StatBlock('Maaş/gün', fmtSigned(-game.dailySalaries),
                    color: AppColors.orange)),
            Expanded(
                child: StatBlock('Kira+bakım',
                    fmtSigned(-(game.dailyRent + game.dailyUpkeep)),
                    color: AppColors.orange)),
            Expanded(
                child: StatBlock('Borç', fmtShort(game.debt),
                    color:
                        game.debt > 0 ? AppColors.red : AppColors.textDim)),
          ]),
        ],
      ),
    );
  }
}

class _OnAirStrip extends StatelessWidget {
  final Game game;
  const _OnAirStrip({required this.game});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];
    for (final id in SlotId.values) {
      if (!game.slotUnlocked(id)) continue;
      final show = game.showById(game.slots[id]!.showId);
      cards.add(_slotCard(context, id, show));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Text('Yayında',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          const Tag('CANLI', color: AppColors.accent, icon: Icons.circle),
          const Spacer(),
          TextButton(
            onPressed: () => ShellNav.go(context, PageId.broadcast),
            child: const Text('Yayın akışı ›',
                style: TextStyle(color: AppColors.cyan)),
          ),
        ]),
        const SizedBox(height: 6),
        AutoGrid(minItemWidth: 200, spacing: 10, children: cards),
      ],
    );
  }

  Widget _slotCard(BuildContext context, SlotId id, Show? s) {
    final def = slotDefs[id]!;
    if (s == null) {
      return Panel(
        onTap: () => ShellNav.go(context, PageId.broadcast),
        borderColor: AppColors.border,
        child: SizedBox(
          height: 96,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline_rounded,
                  color: AppColors.textFaint, size: 28),
              const SizedBox(height: 4),
              Text('${def.label} boş',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(def.hours,
                  style: const TextStyle(
                      color: AppColors.textFaint, fontSize: 12)),
            ],
          ),
        ),
      );
    }
    return Panel(
      onTap: () => ShellNav.go(context, PageId.broadcast),
      child: SizedBox(
        height: 96,
        child: Row(children: [
          StageScene(
              kind: sceneForGenre(s.genre),
              color: s.def.color,
              tier: s.tier,
              live: true,
              width: 92,
              height: 80),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SectionLabel(def.label, color: AppColors.textDim),
                Text(s.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(fmtPct(game.currentRating(s), 2),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.cyan)),
                Text('${fmtSigned(game.revenuePerDay(s))}/gün',
                    style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _Tutorial extends StatelessWidget {
  final Game game;
  const _Tutorial({required this.game});

  @override
  Widget build(BuildContext context) {
    final hired = game.staff.length >= 2;
    final produced = game.shows.isNotEmpty;
    final aired = game.shows.any((s) => s.status == ShowStatus.onAir);
    Widget step(int n, String text, bool done, PageId page) => InkWell(
          onTap: () => ShellNav.go(context, page),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(children: [
              Icon(done ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: done ? AppColors.green : AppColors.textDim, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('$n. $text',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: done ? AppColors.textDim : AppColors.text)),
              ),
              if (!done)
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.accent),
            ]),
          ),
        );
    return Panel(
      borderColor: AppColors.accent.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('İlk adımlar', color: AppColors.accent),
          const SizedBox(height: 4),
          step(1, 'Kadro tut (en az 2 kişi)', hired, PageId.staff),
          step(2, 'İlk programını üret', produced, PageId.production),
          step(3, 'Programı yayına koy', aired, PageId.broadcast),
          const SizedBox(height: 2),
          const Text(
            'İpucu: Magazin tek sunucuyla çekilir, en kolay başlangıçtır.',
            style: TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickTiles extends StatelessWidget {
  final Game game;
  const _QuickTiles({required this.game});

  @override
  Widget build(BuildContext context) {
    final producing =
        game.shows.where((s) => s.status == ShowStatus.producing).length;
    final ready = game.shows.where((s) => s.status == ShowStatus.ready).length;
    Widget tile(IconData icon, Color color, String title, String sub,
            PageId page, {bool badge = false}) =>
        Panel(
          padding: const EdgeInsets.all(10),
          onTap: () => ShellNav.go(context, page),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: badge ? AppColors.green : AppColors.textDim,
                          fontSize: 12)),
                ],
              ),
            ),
          ]),
        );
    return AutoGrid(minItemWidth: 170, spacing: 10, children: [
      tile(Icons.groups_rounded, AppColors.pink, 'Kadro',
          '${game.staff.length}/${game.studio.maxStaff} kişi', PageId.staff),
      tile(
          Icons.movie_creation_rounded,
          AppColors.accent,
          'Yapım',
          ready > 0 ? '$ready program hazır!' : '$producing çekimde',
          PageId.production,
          badge: ready > 0),
      tile(Icons.theaters_rounded, AppColors.purple, 'Sinema',
          '${game.films.where((f) => f.rightsOwned && f.status != FilmStatus.producing).length} film hakkı',
          PageId.cinema),
      tile(Icons.business_center_rounded, AppColors.green, 'Holding',
          '${bizDefs.where((b) => game.bizLevel(b.id) > 0).length} işletme',
          PageId.holding),
      tile(Icons.domain_rounded, AppColors.cyan, 'Stüdyo',
          '${game.ownedEquip.length} ekipman', PageId.studio),
      tile(Icons.account_balance_rounded, AppColors.blue, 'Banka',
          game.loans.isEmpty ? 'Kredi yok' : 'Borç ${fmtShort(game.debt)}',
          PageId.bank),
      tile(Icons.connected_tv_rounded, AppColors.orange, 'Pazar',
          '${game.ownedChannels.length} kanal · ${game.ownedPlatforms.length} platform',
          PageId.channels),
      tile(Icons.diamond_rounded, AppColors.yellow, 'Lüks',
          '${game.ownedLuxury.length} eşya', PageId.luxury),
    ]);
  }
}

class _EventFeed extends StatelessWidget {
  final Game game;
  const _EventFeed({required this.game});

  @override
  Widget build(BuildContext context) {
    final items = game.eventLog.take(4).toList();
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Son gelişmeler'),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Text('Henüz bir gelişme yok.',
                style: TextStyle(color: AppColors.textDim)),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 34,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: e.good ? AppColors.green : AppColors.red,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${e.title} · Gün ${e.day}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(e.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textDim, fontSize: 12)),
                      ],
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
