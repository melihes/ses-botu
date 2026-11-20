import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/scene.dart';

class _Page {
  final Prop prop;
  final Color color;
  final String title;
  final String body;
  const _Page(this.prop, this.color, this.title, this.body);
}

const _pages = [
  _Page(Prop.studio, AppColors.purple, 'Hoş geldin patron! 🎬',
      'Küçük bir yerel kanalın sahibisin. Hedefin: Türkiye\'nin en büyük medya imparatorluğunu kurmak. Her şey kurgusal, her şey senin elinde!'),
  _Page(Prop.debate, AppColors.pink, '1 · Kadronu kur',
      'Senarist, yönetmen, oyuncu ve sunucu işe al. Yetenekleri arttıkça maaşları da artar. Arada bir ★ yıldızlar çıkar, kaçırma!'),
  _Page(Prop.wheel, AppColors.yellow, '2 · Program üret',
      'Tür seç, sonra formatını seç. Her türün seviyeleri var: bilgi yarışmasından başlayıp dev ada yarışmasına kadar çıkabilirsin. Üst formatlar pahalı ama reytingi uçurur.'),
  _Page(Prop.globe, AppColors.blue, '3 · Yayına koy, reklamı ayarla',
      'Hazır programı bir kuşağa koy. Reklam süresini kaydır: reklam uzarsa gelir artar ama izleyici kaçar. En iyi noktayı bulmak senin işin!'),
  _Page(Prop.film, AppColors.orange, '4 · Paranı büyüt',
      'Film çek, vizyona sok, platformlara sat; haklar sende kalsın. YouTuber transfer et, holding kur, rakip kanalları satın al. Yatlar, adalar seni bekliyor!'),
  _Page(Prop.nightShow, AppColors.cyan, '5 · Zaman akıyor',
      '1 oyun günü = 1 dakika. Maaşlar ve kira her gün ödenir. Sen yokken de kanalın 30 dakikaya kadar çalışmaya devam eder. Hadi başlayalım!'),
];

/// İlk açılışta gösterilen tanıtım turu
Future<void> showIntroTutorial(BuildContext context) => showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(child: _Intro()),
    );

class _Intro extends StatefulWidget {
  const _Intro();
  @override
  State<_Intro> createState() => _IntroState();
}

class _IntroState extends State<_Intro> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final p = _pages[_i];
    final last = _i == _pages.length - 1;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760, maxHeight: 360),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Expanded(
            flex: 5,
            child: StageScene(
                key: ValueKey(_i), talk: true, prop: p.prop, color: p.color, tier: 3, live: _i == 3, height: 300),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 5,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SectionLabel('Öğretici · ${_i + 1}/${_pages.length}', color: AppColors.accent),
              const SizedBox(height: 6),
              Text(p.title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(p.body,
                      style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textDim)),
                ),
              ),
              Row(children: [
                for (int k = 0; k < _pages.length; k++)
                  Container(
                    width: k == _i ? 18 : 7,
                    height: 7,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: k == _i ? AppColors.accent : AppColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                if (!last)
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Atla', style: TextStyle(color: AppColors.textDim))),
                const Spacer(),
                AccentButton(last ? 'Başla!' : 'İleri',
                    icon: last ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                    onTap: () => last ? Navigator.pop(context) : setState(() => _i++)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Ekranın köşesinde duran görev balonu
class CoachBubble extends StatefulWidget {
  final void Function(int goal) onGo;
  const CoachBubble({super.key, required this.onGo});
  @override
  State<CoachBubble> createState() => _CoachBubbleState();
}

class _CoachBubbleState extends State<CoachBubble> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final i = game.currentGoal;
    if (i < 0) return const SizedBox.shrink();
    final goals = game.goals;
    final g = goals[i];
    if (!_open) {
      return GestureDetector(
        onTap: () => setState(() => _open = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
          ),
          child: Text('🎯 Görev ${i + 1}/${goals.length}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
        ),
      );
    }
    return Container(
      width: 290,
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 8),
      decoration: BoxDecoration(
        color: const Color(0xF2241C34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.7)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text('🎯 Görev ${i + 1}/${goals.length} · ${g.$1}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            Text('${g.$2} Ödül: ${g.$4} 💎',
                style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          ]),
        ),
        const SizedBox(width: 6),
        AccentButton('Git', compact: true, onTap: () => widget.onGo(i)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => setState(() => _open = false),
          icon: const Icon(Icons.expand_more_rounded, size: 20, color: AppColors.textDim),
        ),
      ]),
    );
  }
}

