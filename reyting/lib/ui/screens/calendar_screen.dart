import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/calendar.dart';
import '../../data/content.dart';
import '../../data/content2.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';

/// Takvim: mevsim, bu ay, yaklaşan özel günler ve özel bölümler
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int _monthOffset = 0;
  bool _showLocked = false;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final today = dateOfDay(game.day);
    final (sEmoji, sName, sDesc) = seasonInfo[game.season]!;
    final active = game.activeSpecialDays;
    final upcoming = game.upcomingSpecialDays(within: 200, all: _showLocked);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Panel(
          gradient: const LinearGradient(colors: [Color(0xFF2A1F45), AppColors.panel]),
          child: Wrap(
            spacing: 14,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('${today.dom} ${monthNames[today.month - 1]}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                Text('${today.year}. yayın yılı · Gün ${game.day} · ${weekdayOf(game.day)}',
                    style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ]),
              Tag('$sEmoji $sName', color: AppColors.yellow),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(sDesc, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ),
              for (final (d, _) in active)
                Tag('${d.emoji} ${d.name} sürüyor', color: AppColors.green),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _MonthGrid(
          offset: _monthOffset,
          onPrev: () => setState(() => _monthOffset--),
          onNext: () => setState(() => _monthOffset++),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const SectionLabel('Yaklaşan özel günler'),
            GestureDetector(
              onTap: () => setState(() => _showLocked = !_showLocked),
              child: Tag(_showLocked ? '🌍 Kilitli dünya günleri gösteriliyor' : '🌍 Kilitli dünya günlerini göster',
                  color: _showLocked ? AppColors.cyan : AppColors.textDim),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const PageHint(
          'Özel günden 10 gün önce "Özel bölüm hazırla" açılır. Uygun türdeki programın o günlerde '
          'büyük reyting alır ve sponsor geliri getirir. Dünya özel günleri için o ülkede çekim lokasyonun olmalı '
          '(Harita). Bayramlarda sinema salonları dolar.',
        ),
        const SizedBox(height: 8),
        AutoGrid(
          minItemWidth: 300,
          spacing: 8,
          children: [for (final (d, start) in upcoming) _DayCard(day: d, start: start)],
        ),
      ],
    );
  }
}

class _MonthGrid extends StatelessWidget {
  final int offset;
  final VoidCallback onPrev, onNext;
  const _MonthGrid({required this.offset, required this.onPrev, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final t = dateOfDay(game.day);
    // gösterilen ayın ilk günü (oyun günü)
    final monthStart = game.day - (t.dom - 1) + offset * 30;
    final m = dateOfDay(monthStart);
    final marks = <int, List<SpecialDay>>{};
    for (int i = 0; i < 30; i++) {
      final dd = monthStart + i;
      if (dd < 1) continue;
      for (final d in specialDays) {
        if (d.activeStart(dd) != null) (marks[i] ??= []).add(d);
      }
    }
    return Panel(
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        Row(children: [
          IconButton(onPressed: monthStart - 30 >= 1 ? onPrev : null, icon: const Icon(Icons.chevron_left_rounded)),
          Expanded(
            child: Text('${monthNames[m.month - 1]} · ${m.year}. yıl',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded)),
        ]),
        LayoutBuilder(builder: (ctx, c) {
          const cols = 10;
          final w = (c.maxWidth - (cols - 1) * 4) / cols;
          return Wrap(spacing: 4, runSpacing: 4, children: [
            for (int i = 0; i < 30; i++)
              Builder(builder: (_) {
                final dd = monthStart + i;
                final isToday = dd == game.day;
                final past = dd < game.day;
                final ms = marks[i] ?? const [];
                final avail = ms.where(game.specialAvailable).toList();
                return Tooltip(
                  message: ms.isEmpty ? '${i + 1} ${monthNames[m.month - 1]}' : ms.map((e) => e.name).join(', '),
                  child: Container(
                    width: w,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isToday
                          ? AppColors.accent.withValues(alpha: 0.35)
                          : (avail.isNotEmpty
                              ? AppColors.green.withValues(alpha: 0.15)
                              : AppColors.panelHi.withValues(alpha: past ? 0.3 : 0.8)),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isToday ? AppColors.accent : AppColors.border),
                    ),
                    child: Stack(children: [
                      Positioned(
                        left: 4,
                        top: 2,
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: past ? AppColors.textFaint : AppColors.textDim)),
                      ),
                      if (ms.isNotEmpty)
                        Center(
                          child: Opacity(
                            opacity: avail.isEmpty ? 0.35 : 1,
                            child: Text(ms.first.emoji, style: const TextStyle(fontSize: 16)),
                          ),
                        ),
                    ]),
                  ),
                );
              }),
          ]);
        }),
      ]),
    );
  }
}

class _DayCard extends StatelessWidget {
  final SpecialDay day;
  final int start;
  const _DayCard({required this.day, required this.start});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final d = day;
    final avail = game.specialAvailable(d);
    final left = start - game.day;
    final running = left <= 0;
    final open = avail && game.specialWindowOpen(d, start);
    final prepared = game.shows.where((s) => game.specials[s.id] == game.specialKey(d, start)).toList();
    final locNames = [
      for (final id in d.locations)
        for (final l in locationDefs)
          if (l.id == id) l.city,
    ];
    return Panel(
      padding: const EdgeInsets.all(10),
      borderColor: running ? AppColors.green : (open ? AppColors.yellow : null),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d.emoji, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Text(
                '${dateLabel(start)}${d.length > 1 ? ' – ${dateLabel(start + d.length - 1)}' : ''}'
                '${d.world ? ' · ${locNames.join(', ')}' : ' · Türkiye'}',
                style: const TextStyle(color: AppColors.textDim, fontSize: 11),
              ),
            ]),
          ),
          Tag(
            running ? 'Şimdi!' : (left == 1 ? 'Yarın' : '$left gün'),
            color: running ? AppColors.green : (left <= 10 ? AppColors.yellow : AppColors.textDim),
          ),
        ]),
        const SizedBox(height: 6),
        Text(d.desc, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
        const SizedBox(height: 6),
        Wrap(spacing: 4, runSpacing: 4, children: [
          for (final g in d.genres) Tag(genreDefs[g]!.label, color: genreDefs[g]!.color),
          if (d.tvBonus > 0) Tag('+%${(d.tvBonus * 100).round()} reyting', color: AppColors.green),
          if (d.filmBonus > 0)
            Tag('🍿 ${d.allFilms ? 'Tüm filmler' : d.films.map((f) => filmGenreDefs[f]!.label).join(', ')} +%${(d.filmBonus * 100).round()}',
                color: AppColors.orange),
          if (d.audience < 1) Tag('Tatil: izleyici -%${((1 - d.audience) * 100).round()}', color: AppColors.red),
        ]),
        const SizedBox(height: 8),
        if (!avail)
          Text('🔒 ${locNames.join(' / ')} lokasyonu gerekli (Harita)',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 12, fontWeight: FontWeight.w700))
        else if (prepared.isNotEmpty)
          Text('✅ Hazır: ${prepared.map((s) => s.name).join(', ')}',
              style: const TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w800)),
        if (avail)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: open
                ? AccentButton(
                    '${d.emoji} ${d.special} hazırla',
                    expand: true,
                    onTap: () => _pickShow(context, game, d),
                  )
                : Text('Özel bölüm ${left - 10} gün sonra hazırlanabilir.',
                    style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
          ),
      ]),
    );
  }

  void _pickShow(BuildContext context, Game game, SpecialDay d) {
    final cands = game.specialCandidates(d);
    showDialog(
      context: context,
      builder: (c) {
        final g = GameScope.of(c);
        final start = d.nextStart(g.day);
        return AlertDialog(
          title: Text('${d.emoji} ${d.special}'),
          content: SizedBox(
            width: 460,
            child: cands.isEmpty
                ? Text(
                    'Yayında ya da çekimde uygun program yok. Uygun türler: '
                    '${d.genres.map((x) => genreDefs[x]!.label).join(', ')}.',
                    style: const TextStyle(color: AppColors.textDim))
                : SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(
                        'Özel bölüm, özel gün boyunca reytingi +%${(g.specialBoost(d) * 100).round()} artırır ve '
                        '${d.world ? 'yurt dışı satışından' : 'sponsorlardan'} maliyetin '
                        '${d.world ? '1,5 katını' : '%90\'ını'} geri getirir.',
                        style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      for (final s in cands)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Panel(
                            padding: const EdgeInsets.all(8),
                            color: AppColors.panelHi,
                            child: Row(children: [
                              Icon(s.def.icon, color: s.def.color, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                                  Text(s.status == ShowStatus.onAir ? 'Yayında' : 'Çekimde',
                                      style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                                ]),
                              ),
                              g.specials[s.id] == g.specialKey(d, start)
                                  ? const Tag('Hazır ✅', color: AppColors.green)
                                  : GhostButton(fmtShort(g.specialCost(s, d)),
                                      compact: true,
                                      color: AppColors.green,
                                      onTap: () {
                                        final err = g.prepareSpecial(s, d);
                                        report(c, err);
                                        if (err == null) Navigator.pop(c);
                                      }),
                            ]),
                          ),
                        ),
                    ]),
                  ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Kapat'))],
        );
      },
    );
  }
}
