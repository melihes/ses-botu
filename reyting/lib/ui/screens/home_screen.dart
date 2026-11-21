import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../data/content2.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../shell.dart';
import '../widgets/cash_chart.dart';
import '../widgets/common.dart';
import 'live_view.dart';
import '../widgets/item_art.dart';
import '../widgets/scene.dart';
import 'cinema_screen.dart';
import 'production_screen.dart';

/// Ana ekran: kaydırmadan her şeye ulaşılan kontrol paneli.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth > 680;
        final cash = _CashCard(game: game);
        final grid = _TileGrid(game: game);
        if (!wide || c.maxHeight < 260) {
          return ListView(
            padding: const EdgeInsets.all(10),
            children: [
              SizedBox(height: 260, child: cash),
              const SizedBox(height: 10),
              SizedBox(height: 330, child: grid),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: cash),
              const SizedBox(width: 10),
              Expanded(flex: 6, child: grid),
            ],
          ),
        );
      },
    );
  }
}

class _CashCard extends StatelessWidget {
  final Game game;
  const _CashCard({required this.game});

  @override
  Widget build(BuildContext context) {
    final net = game.netPerDay;
    final income =
        game.adIncomePerDay +
        game.channelIncomePerDay +
        game.platformIncomePerDay +
        game.bizIncomePerDay +
        game.creatorIncomePerDay +
        game.boxOfficePerDay;
    final expense = income - net;
    final ev = game.eventLog.isEmpty ? null : game.eventLog.first;
    return Panel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      gradient: const LinearGradient(
        colors: [Color(0xFF2A1E3D), AppColors.panel],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SectionLabel('Kasa', color: AppColors.textDim),
              const SizedBox(width: 6),
              Flexible(
                child: Tag(
                  game.studio.name,
                  color: AppColors.cyan,
                  icon: Icons.domain_rounded,
                ),
              ),
              const Spacer(),
              Text(
                '${net >= 0 ? '▲' : '▼'} ${fmtSigned(net)}/gün',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: net >= 0 ? AppColors.green : AppColors.red,
                ),
              ),
            ],
          ),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              fmtFull(game.cash),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: game.cash < 0 ? AppColors.red : AppColors.text,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Expanded(child: CashChart()),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ShellNav.go(context, PageId.trophies),
                  child: StatBlock(
                    '#${game.richRank} değer',
                    fmtShort(game.netWorth),
                    color: AppColors.yellow,
                  ),
                ),
              ),
              Expanded(
                child: StatBlock(
                  'Gelir/gün',
                  fmtSigned(income),
                  color: AppColors.green,
                ),
              ),
              Expanded(
                child: StatBlock(
                  'Gider/gün',
                  fmtSigned(-expense),
                  color: AppColors.orange,
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ShellNav.go(context, PageId.bank),
                  child: StatBlock(
                    'Borç ›',
                    fmtShort(game.debt),
                    color: game.debt > 0 ? AppColors.red : AppColors.textDim,
                  ),
                ),
              ),
            ],
          ),
          if (game.currentGoal >= 0) ...[
            const SizedBox(height: 4),
            _GoalRow(game: game),
          ] else if (ev != null) ...[
            const SizedBox(height: 4),
            Text(
              '${ev.title} — ${ev.body}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: ev.good ? AppColors.green : AppColors.orange,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  final Game game;
  const _TileGrid({required this.game});

  @override
  Widget build(BuildContext context) {
    final g = game;
    final onAir = g.shows.where((s) => s.status == ShowStatus.onAir).toList();
    final ready = g.shows.where((s) => s.status == ShowStatus.ready).toList();
    final producing = g.shows
        .where((s) => s.status == ShowStatus.producing)
        .length;
    final avgRating = onAir.isEmpty
        ? 0.0
        : onAir.map(g.currentRating).reduce((a, b) => a + b) / onAir.length;
    final nextLevel = g.studioLevel < studioLevels.length - 1
        ? studioLevels[g.studioLevel + 1]
        : null;
    final filmsLive = g.films
        .where((f) => f.status == FilmStatus.inTheaters)
        .length;
    final filmsReady = g.films
        .where((f) => f.status == FilmStatus.ready)
        .length;
    final bizCount = bizDefs.where((b) => g.bizLevel(b.id) > 0).length;

    final tiles = <Widget>[
      _Tile(
        art: onAir.isNotEmpty
            ? StageScene(
                talk: true,
                prop: propFor(onAir.first.genre, onAir.first.tier),
                color: onAir.first.def.color,
                tier: onAir.first.tier,
                live: true,
                height: 200,
              )
            : const StageScene(
                prop: Prop.globe,
                color: AppColors.blue,
                height: 200,
              ),
        title: 'Yayın',
        status: onAir.isEmpty
            ? 'Ekranda program yok'
            : '${onAir.length} yayında · ${fmtPct(avgRating, 1)}',
        alert: ready.isNotEmpty ? '${ready.length} hazır' : null,
        action: ready.isNotEmpty
            ? 'Yayına koy'
            : (onAir.isNotEmpty ? '▶ İzle' : null),
        onAction: ready.isNotEmpty
            ? () => pickSlotFor(context, ready.first)
            : (onAir.isNotEmpty ? () => openLiveView(context, onAir.first) : null),
        onTap: () => ShellNav.go(context, PageId.broadcast),
      ),
      _Tile(
        art: StageScene(
          prop: g.shows.isNotEmpty
              ? propFor(g.shows.first.genre, g.shows.first.tier)
              : Prop.wheel,
          color: AppColors.accent,
          tier: 2,
          height: 200,
        ),
        title: 'Yapım',
        status: '$producing çekimde · ${g.shows.length} program',
        action: '+ Yeni',
        onAction: () => openNewShowWizard(context),
        onTap: () => ShellNav.go(context, PageId.production),
      ),
      _Tile(
        art: const StageScene(
          prop: Prop.debate,
          color: AppColors.pink,
          height: 200,
        ),
        title: 'Kadro',
        status:
            '${g.staff.length}/${g.studio.maxStaff} kişi · ${fmtShort(g.dailySalaries)}/gün',
        alert: g.market.any((p) => p.isStar) ? '★ yıldız' : null,
        action: 'İşe al',
        onAction: () => ShellNav.go(context, PageId.staff),
        onTap: () => ShellNav.go(context, PageId.staff),
      ),
      _Tile(
        art: const StageScene(
          prop: Prop.film,
          color: AppColors.orange,
          tier: 2,
          height: 200,
        ),
        title: 'Sinema',
        status: '${g.films.length} film · $filmsLive vizyonda',
        alert: filmsReady > 0 ? '$filmsReady hazır' : null,
        action: '+ Film',
        onAction: () => openNewFilmWizard(context),
        onTap: () => ShellNav.go(context, PageId.cinema),
      ),
      _Tile(
        art: const ItemArt(
          id: 'videom',
          color: AppColors.accent,
          width: 300,
          height: 200,
        ),
        title: 'Dijital',
        status: g.creators.isEmpty
            ? 'YouTuber transfer et'
            : '${g.creators.length} YouTuber · ${fmtShort(g.totalFollowers).replaceAll(' ₺', '')} takipçi',
        action: 'Keşfet',
        onAction: () => ShellNav.go(context, PageId.digital),
        onTap: () => ShellNav.go(context, PageId.digital),
      ),
      _Tile(
        art: StageScene(
          prop: Prop.studio,
          color: AppColors.purple,
          tier: min(g.studioLevel, 4),
          height: 200,
        ),
        title: 'Stüdyo',
        status: 'Seviye ${g.studioLevel + 1} · ${g.ownedEquip.length} ekipman',
        alert: nextLevel != null && g.cash >= nextLevel.upgradeCost
            ? 'Yükselt!'
            : null,
        onTap: () => ShellNav.go(context, PageId.studio),
      ),
      _Tile(
        art: const StageScene(
          prop: Prop.globe,
          color: AppColors.cyan,
          tier: 2,
          height: 200,
        ),
        title: 'Harita',
        status:
            '${g.ownedLocations.length} set · ${locationDefs.length} lokasyon',
        onTap: () => ShellNav.go(context, PageId.map),
      ),
      _Tile(
        art: const StageScene(
          prop: Prop.talent,
          color: AppColors.pink,
          tier: 2,
          height: 200,
        ),
        title: 'Ajans',
        status: g.agencyOpen
            ? '${g.academy.length} genç · sv ${g.agencyLevel}'
            : 'Genç yetenek keşfet',
        alert: g.transferOffers.isNotEmpty
            ? '${g.transferOffers.length} teklif'
            : null,
        onTap: () => ShellNav.go(context, PageId.agency),
      ),
      _Tile(
        art: const StageScene(
          prop: Prop.election,
          color: AppColors.purple,
          tier: 2,
          height: 200,
        ),
        title: 'Yönetim',
        status: '${g.execs.length} yönetici · ${fmtShort(g.execSalaries)}/gün',
        onTap: () => ShellNav.go(context, PageId.board),
      ),
      _Tile(
        art: const StageScene(
          prop: Prop.redCarpet,
          color: AppColors.yellow,
          tier: 2,
          height: 200,
        ),
        title: 'Markalar',
        status:
            '${g.deals.length + g.shows.where((s) => s.sponsorDays > 0).length} anlaşma',
        alert: g.brandOffers.isNotEmpty
            ? '${g.brandOffers.length} teklif'
            : null,
        onTap: () => ShellNav.go(context, PageId.brands),
      ),
      _Tile(
        art: const ItemArt(
          id: 'otel',
          color: AppColors.green,
          width: 300,
          height: 200,
        ),
        title: 'Holding',
        status: '$bizCount işletme · ${fmtSigned(g.bizIncomePerDay)}/gün',
        onTap: () => ShellNav.go(context, PageId.holding),
      ),
      _Tile(
        art: const ItemArt(
          id: 'pazar',
          color: AppColors.orange,
          width: 300,
          height: 200,
        ),
        title: 'Pazar',
        status:
            '${g.ownedChannels.length} kanal · ${g.ownedPlatforms.length} platform',
        onTap: () => ShellNav.go(context, PageId.channels),
      ),
    ];

    // Sade düzen: 4 ana iş büyük kutularda, geri kalanlar tek sıra simge
    final minis = [
      _Mini(Icons.smart_display_rounded, 'Dijital', AppColors.accent, PageId.digital, null),
      _Mini(Icons.domain_rounded, 'Stüdyo', AppColors.purple, PageId.studio,
          nextLevel != null && g.cash >= nextLevel.upgradeCost ? '!' : null),
      _Mini(Icons.map_rounded, 'Harita', AppColors.cyan, PageId.map, null),
      _Mini(Icons.star_rounded, 'Ajans', AppColors.pink, PageId.agency,
          g.transferOffers.isNotEmpty ? '${g.transferOffers.length}' : null),
      _Mini(Icons.groups_3_rounded, 'Yönetim', AppColors.blue, PageId.board, null),
      _Mini(Icons.handshake_rounded, 'Markalar', AppColors.yellow, PageId.brands,
          g.brandOffers.isNotEmpty ? '${g.brandOffers.length}' : null),
      _Mini(Icons.business_center_rounded, 'Holding', AppColors.green, PageId.holding, null),
      _Mini(Icons.gavel_rounded, 'İhaleler', AppColors.orange, PageId.tenders, null),
    ];
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (ctx, c) {
              const gap = 8.0;
              final tw = (c.maxWidth - gap) / 2;
              final th = (c.maxHeight - gap) / 2;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final t in tiles.take(4)) SizedBox(width: tw, height: th, child: t),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 62,
          child: Row(
            children: [
              for (final m in minis)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _MiniButton(m: m),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Mini {
  final IconData icon;
  final String label;
  final Color color;
  final PageId page;
  final String? badge;
  const _Mini(this.icon, this.label, this.color, this.page, this.badge);
}

class _MiniButton extends StatelessWidget {
  final _Mini m;
  const _MiniButton({required this.m});
  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => ShellNav.go(context, m.page),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(m.icon, color: m.color, size: 24),
                const SizedBox(height: 2),
                Text(
                  m.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          if (m.badge != null)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(color: AppColors.green, borderRadius: BorderRadius.circular(8)),
                child: Text(m.badge!, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ),
        ],
      ),
    ),
  );
}

class _Tile extends StatelessWidget {
  final Widget art;
  final String title;
  final String status;
  final String? alert;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback onTap;
  const _Tile({
    required this.art,
    required this.title,
    required this.status,
    required this.onTap,
    this.alert,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(width: 300, height: 200, child: art),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.3, 1],
                  colors: [Colors.transparent, Color(0xE6130F1D)],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (alert != null)
              Positioned(
                left: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    alert!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            if (action != null)
              Positioned(
                right: 6,
                top: 6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onAction,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.accentGradient,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 6),
                      ],
                    ),
                    child: Text(
                      action!,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final Game game;
  const _GoalRow({required this.game});
  @override
  Widget build(BuildContext context) {
    final i = game.currentGoal;
    final g = game.goals[i];
    return InkWell(
      onTap: () => ShellNav.go(context, _ShellGoal.pages[i]),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '🎯 Görev ${i + 1}/${game.goals.length}: ${g.$1} · ${g.$4} 💎',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Text(
              'Git ›',
              style: TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShellGoal {
  static const pages = [
    PageId.staff,
    PageId.production,
    PageId.broadcast,
    PageId.broadcast,
    PageId.digital,
    PageId.cinema,
    PageId.studio,
  ];
}
