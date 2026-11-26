import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/achievements.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

class TrophiesScreen extends StatefulWidget {
  const TrophiesScreen({super.key});
  @override
  State<TrophiesScreen> createState() => _TrophiesScreenState();
}

class _TrophiesScreenState extends State<TrophiesScreen> {
  int _tab = 3;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final done = achDefs.where((a) => game.achievements.contains(a.id)).length;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PillTabs(
              labels: [
                'Başarımlar $done/${achDefs.length}',
                'Ödül dolabı ${game.trophies.length}',
                'Koleksiyon ${game.ownedLuxury.length}/${luxuryDefs.length}',
                'Zenginler #${game.richRank}',
              ],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            Tag(
              'Şirket değeri ${fmtShort(game.netWorth)}',
              color: AppColors.cyan,
            ),
            Tag('★ ${fmtInt(game.prestige)} prestij', color: AppColors.yellow),
          ],
        ),
        const SizedBox(height: 10),
        if (_tab == 0) ...[
          Bar(done / achDefs.length, color: AppColors.yellow, height: 8),
          const SizedBox(height: 10),
          AutoGrid(
            minItemWidth: 200,
            spacing: 8,
            children: [
              for (final a in achDefs)
                _Badge(
                  icon: a.icon,
                  title: a.title,
                  desc: a.desc,
                  reward: a.reward,
                  done: game.achievements.contains(a.id),
                ),
            ],
          ),
        ],
        if (_tab == 1) ...[
          const PageHint(
            'Her 30 günde bir Altın Anten Ödülleri dağıtılır. Kategorilerde barajı geçen programların ödül kazanır.',
          ),
          if (game.trophies.isEmpty)
            Panel(
              child: Text(
                'Henüz kupan yok. İlk tören Gün ${((game.day ~/ 30) + 1) * 30}\'da!',
                style: const TextStyle(color: AppColors.textDim),
              ),
            ),
          AutoGrid(
            minItemWidth: 180,
            spacing: 8,
            children: [
              for (final t in game.trophies.reversed)
                Panel(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE08A), Color(0xFFB8860B)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.award,
                              maxLines: 2,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '${t.winner} · Gün ${t.day}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                ),
            ],
          ),
        ],
        if (_tab == 3) ...[
          PageHint(
            'Zenginler listesi Şirket Değeri\'ne göre sıralanır. Şu an ${game.richRank}. sıradasın. '
            'Online sürümde bu listede gerçek oyuncular yarışacak.',
          ),
          _RichList(),
        ],
        if (_tab == 2) ...[
          const PageHint(
            'Lüks koleksiyonun. Sahip olmadıkların gölgede bekliyor!',
          ),
          AutoGrid(
            minItemWidth: 150,
            spacing: 8,
            children: [
              for (final d in luxuryDefs)
                Opacity(
                  opacity: game.ownedLuxury.contains(d.id) ? 1 : 0.35,
                  child: Panel(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ItemArt(
                          id: d.id,
                          color: d.cat.color,
                          width: double.infinity,
                          height: 80,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          d.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          game.ownedLuxury.contains(d.id)
                              ? 'Sahipsin ✓'
                              : fmtShort(d.price),
                          style: TextStyle(
                            fontSize: 11,
                            color: game.ownedLuxury.contains(d.id)
                                ? AppColors.green
                                : AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final int reward;
  final bool done;
  const _Badge({
    required this.icon,
    required this.title,
    required this.desc,
    required this.reward,
    required this.done,
  });

  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(10),
    borderColor: done ? AppColors.yellow.withValues(alpha: 0.7) : null,
    child: Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: done
                ? const LinearGradient(
                    colors: [Color(0xFFFFE08A), Color(0xFFE3A23F)],
                  )
                : null,
            color: done ? null : AppColors.border,
          ),
          child: Icon(
            done ? icon : Icons.lock_rounded,
            color: done ? Colors.white : AppColors.textFaint,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                desc,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textDim, fontSize: 11),
              ),
              Text(
                done ? 'Kazanıldı ✓' : 'Ödül: $reward 💎',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: done ? AppColors.green : AppColors.yellow,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _RichList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final me = game.netWorth;
    final myRank = game.richRank;
    final rows = <(int, String, double, bool)>[];
    int r = 1;
    var placed = false;
    for (int i = 0; i < 150 && r <= 100; i++) {
      final w = game.tycoonWorth(i);
      if (!placed && me >= w) {
        rows.add((r++, game.channelName, me, true));
        placed = true;
      }
      if (r > 100) break;
      rows.add((r++, game.tycoonName(i), w, false));
    }
    final needed = myRank > 100 ? game.tycoonWorth(99) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (needed != null)
          Panel(
            padding: const EdgeInsets.all(10),
            borderColor: AppColors.accent.withValues(alpha: 0.6),
            child: Text(
              'Sen: $myRank. sıra · ${fmtShort(me)}. İlk 100 için ${fmtShort(needed)} gerekiyor '
              '(%${(me / needed * 100).clamp(0, 100).toStringAsFixed(1)} yoldasın).',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        const SizedBox(height: 6),
        AutoGrid(
          minItemWidth: 260,
          spacing: 6,
          children: [
            for (final row in rows)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: row.$4
                      ? AppColors.accent.withValues(alpha: 0.2)
                      : AppColors.panel,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: row.$4 ? AppColors.accent : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 34,
                      child: Text(
                        '${row.$1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: row.$1 <= 3
                              ? AppColors.yellow
                              : AppColors.textDim,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: row.$4
                              ? FontWeight.w900
                              : FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      fmtShort(row.$3),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
