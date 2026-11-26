import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/face.dart';

/// Sosyal medya: izleyiciler programların hakkında ne diyor, gündemde ne var
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});
  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  int _filter = 0; // 0 tümü, 1 olumlu, 2 olumsuz

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final all = game.socialFeed;
    final posts = all
        .where((p) => _filter == 0 || (_filter == 1 ? p.mood > 0 : p.mood < 0))
        .toList();
    final recent = all.take(40).toList();
    final pos = recent.where((p) => p.mood > 0).length;
    final neg = recent.where((p) => p.mood < 0).length;
    final feed = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
        PillTabs(
          labels: const ['Tümü', '😍 Olumlu', '😤 Olumsuz'],
          selected: _filter,
          onChanged: (i) => setState(() => _filter = i),
        ),
        if (recent.isNotEmpty)
          Tag('Hava: %${(pos * 100 / recent.length).round()} olumlu · %${(neg * 100 / recent.length).round()} olumsuz',
              color: pos >= neg ? AppColors.green : AppColors.red),
      ]),
      const SizedBox(height: 8),
      if (posts.isEmpty)
        const Panel(
          child: Text(
            'Henüz kimse bir şey yazmadı. Programların yayına girince izleyiciler konuşmaya başlar.',
            style: TextStyle(color: AppColors.textDim),
          ),
        ),
      for (int i = 0; i < posts.length && i < 50; i++)
        _PostCard(key: ValueKey('${posts[i].day}-${posts[i].seed}'), post: posts[i], fresh: i == 0 && _filter == 0),
    ]);
    final trends = _Trends(game: game);
    return LayoutBuilder(builder: (ctx, c) {
      final wide = c.maxWidth >= 720;
      if (!wide) {
        return ListView(padding: const EdgeInsets.all(12), children: [trends, const SizedBox(height: 10), feed]);
      }
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [feed])),
        SizedBox(
          width: 250,
          child: ListView(padding: const EdgeInsets.fromLTRB(0, 12, 12, 12), children: [trends]),
        ),
      ]);
    });
  }
}

class _Trends extends StatelessWidget {
  final Game game;
  const _Trends({required this.game});
  @override
  Widget build(BuildContext context) {
    final list = game.trendList;
    final mine = {for (final s in game.shows) game.tagOf(s.name)};
    return Panel(
      padding: const EdgeInsets.all(10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionLabel('🔥 Gündem'),
        const SizedBox(height: 4),
        if (list.isEmpty)
          const Text('Gündem sakin.', style: TextStyle(color: AppColors.textFaint, fontSize: 12)),
        for (int i = 0; i < list.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              SizedBox(
                width: 20,
                child: Text('${i + 1}',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: i == 0 ? AppColors.yellow : AppColors.textDim)),
              ),
              Expanded(
                child: Text(list[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: mine.contains(list[i].key) ? AppColors.cyan : AppColors.text)),
              ),
              Text('${fmtInt(list[i].value.round())} etkileşim',
                  style: const TextStyle(color: AppColors.textFaint, fontSize: 10)),
            ]),
          ),
        const SizedBox(height: 6),
        const Text(
          'Mavi olanlar senin programların. Gündemde açık ara 1 numara olan program ertesi gün +%7 izlenir.',
          style: TextStyle(color: AppColors.textFaint, fontSize: 10),
        ),
      ]),
    );
  }
}

class _PostCard extends StatefulWidget {
  final SocialPost post;
  final bool fresh;
  const _PostCard({super.key, required this.post, required this.fresh});
  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
  bool _liked = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final spec = FaceSpec.of(p.seed, female: p.female, age: 18 + p.seed % 40);
    final body = _richText(p.text);
    final card = Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Panel(
        padding: const EdgeInsets.all(10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: [AppColors.panelHi, const Color(0xFF2E2346), const Color(0xFF1E3346)][p.seed % 3],
            ),
            clipBehavior: Clip.antiAlias,
            child: FaceView(spec: spec, cacheKey: p.seed, size: 38),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                Text(p.handle, style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                Text('· Gün ${p.day} ${p.hour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
              ]),
              const SizedBox(height: 3),
              body,
              const SizedBox(height: 6),
              Row(children: [
                const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.textFaint),
                const SizedBox(width: 3),
                Text(fmtInt((p.shares * 0.6).round()), style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                const SizedBox(width: 14),
                const Icon(Icons.repeat_rounded, size: 14, color: AppColors.textFaint),
                const SizedBox(width: 3),
                Text(fmtInt(p.shares), style: const TextStyle(color: AppColors.textFaint, fontSize: 11)),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () => setState(() => _liked = !_liked),
                  child: Row(children: [
                    Icon(_liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        size: 14, color: _liked ? AppColors.red : AppColors.textFaint),
                    const SizedBox(width: 3),
                    Text(fmtInt(p.likes + (_liked ? 1 : 0)),
                        style: TextStyle(color: _liked ? AppColors.red : AppColors.textFaint, fontSize: 11)),
                  ]),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
    if (!widget.fresh) return card;
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
      child: FadeTransition(opacity: _c, child: card),
    );
  }

  /// Etiketler (#...) renkli
  Widget _richText(String text) {
    final spans = <TextSpan>[];
    for (final w in text.split(' ')) {
      final isTag = w.startsWith('#');
      spans.add(TextSpan(
        text: '$w ',
        style: TextStyle(
          color: isTag ? AppColors.cyan : AppColors.text,
          fontWeight: isTag ? FontWeight.w800 : FontWeight.w500,
        ),
      ));
    }
    return Text.rich(TextSpan(children: spans), style: const TextStyle(fontSize: 13, height: 1.3));
  }
}
