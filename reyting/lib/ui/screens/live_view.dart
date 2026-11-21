import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/live_script.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/company_logo.dart';
import '../widgets/item_art.dart';
import '../widgets/scene.dart';

/// Programı tam ekran canlı izle: konuşmalar, skor, seyirci tepkileri.
Future<void> openLiveView(BuildContext context, Show s) => showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: LiveView(show: s),
      ),
    );

class LiveView extends StatefulWidget {
  final Show show;
  const LiveView({super.key, required this.show});
  @override
  State<LiveView> createState() => _LiveViewState();
}

class _Bubble {
  final String who;
  final String text;
  final int id;
  _Bubble(this.who, this.text, this.id);
}

class _LiveViewState extends State<LiveView> {
  LiveScript? _script;
  Timer? _timer;
  final _feed = <LiveBeat>[];
  final _bubbles = <int, _Bubble?>{0: null, 1: null, 2: null};
  final _clearAt = <int, DateTime>{};
  int _reaction = 0;
  DateTime _reactionUntil = DateTime(2000);
  String _ticker = '';
  int _bid = 0;
  double _jitter = 1;
  final _r = Random();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_script != null) return;
    final game = GameScope.read(context);
    final s = widget.show;
    final crew = s.staffIds.map(game.staffById).whereType<Staff>().toList();
    String first(Staff p) => p.name.split(' ').first;
    final hosts = crew.where((p) => p.role == Role.sunucu).map(first).toList();
    final actors = crew.where((p) => p.role == Role.oyuncu).map(first).toList();
    final others = crew.map(first).toList();
    final host = hosts.isNotEmpty ? hosts.first : (others.isNotEmpty ? others.first : 'Sunucu');
    final guest = s.guestName ??
        (actors.isNotEmpty ? actors.first : (others.length > 1 ? others[1] : 'Konuk'));
    _script = LiveScript(
      genre: s.genre,
      prop: formatOf(s.genre, s.tier).prop,
      host: host,
      guest: guest,
      cast: actors.isNotEmpty ? actors : others,
      seed: s.id.hashCode ^ DateTime.now().millisecond,
    );
    _ticker = '${game.channelName} · ${s.name} · ${s.def.label}';
    _step();
    _timer = Timer.periodic(const Duration(milliseconds: 2900), (_) => _step());
  }

  void _step() {
    if (!mounted) return;
    final b = _script!.next();
    final now = DateTime.now();
    setState(() {
      _bubbles[b.side] = _Bubble(b.who, b.text, ++_bid);
      _clearAt[b.side] = now.add(const Duration(milliseconds: 5200));
      for (final e in _clearAt.entries) {
        if (now.isAfter(e.value)) _bubbles[e.key] = null;
      }
      if (b.reaction > 0) {
        _reaction = b.reaction;
        _reactionUntil = now.add(const Duration(milliseconds: 2200));
      } else if (now.isAfter(_reactionUntil)) {
        _reaction = 0;
      }
      if (b.ticker != null) _ticker = b.ticker!;
      _feed.insert(0, b);
      if (_feed.length > 30) _feed.removeLast();
      _jitter = 0.97 + _r.nextDouble() * 0.06 + (b.reaction == 2 ? 0.03 : 0);
    });
    // tepki kısa sürsün
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (mounted && DateTime.now().isAfter(_reactionUntil)) setState(() => _reaction = 0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final s = widget.show;
    final rating = game.currentRating(s) * _jitter;
    final viewers = game.viewers(s) * _jitter;
    final fmt = formatOf(s.genre, s.tier);
    final board = _script?.board;
    final slot = s.slot == null ? null : slotDefs[s.slot]!;

    return SafeArea(
      child: Column(children: [
        // üst bant
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          color: const Color(0xFF120E1C),
          child: Row(children: [
            _LivePill(onAir: s.status == ShowStatus.onAir, label: switch (s.status) {
              ShowStatus.onAir => '● CANLI',
              ShowStatus.producing => '● ÇEKİMDE',
              _ => '● TEKRAR',
            }),
            const SizedBox(width: 8),
            CompanyLogoView(logo: game.logo, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                    Text(
                        '${game.channelName} · ${fmt.name}${slot != null ? ' · ${slot.label} ${slot.hours}' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
                  ]),
            ),
            if (s.status == ShowStatus.onAir) ...[
              _Stat('REYTİNG', fmtPct(rating, 2), AppColors.cyan),
              const SizedBox(width: 12),
              _Stat('İZLEYİCİ', fmtShort(viewers).replaceAll(' ₺', ''), AppColors.yellow),
              const SizedBox(width: 8),
            ],
            IconButton(
              tooltip: 'Kapat',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ]),
        ),
        Expanded(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Expanded(
              child: LayoutBuilder(builder: (ctx, c) {
                return Stack(children: [
                  Positioned.fill(
                    child: StageScene(
                      prop: fmt.prop,
                      color: s.def.color,
                      tier: max(0, s.tier + s.budget - 1),
                      live: false,
                      reaction: _reaction,
                      width: c.maxWidth,
                      height: c.maxHeight,
                      radius: BorderRadius.zero,
                    ),
                  ),
                  // konuşma balonları
                  if (_bubbles[0] != null)
                    Positioned(
                      left: c.maxWidth * 0.03,
                      top: c.maxHeight * 0.03,
                      width: c.maxWidth * 0.43,
                      child: _TalkBubble(b: _bubbles[0]!, color: AppColors.accent, tailLeft: true),
                    ),
                  if (_bubbles[1] != null)
                    Positioned(
                      right: c.maxWidth * 0.03,
                      top: c.maxHeight * 0.13,
                      width: c.maxWidth * 0.43,
                      child: _TalkBubble(b: _bubbles[1]!, color: AppColors.cyan, tailLeft: false),
                    ),
                  if (_bubbles[2] != null)
                    Positioned(
                      left: c.maxWidth * 0.15,
                      right: c.maxWidth * 0.15,
                      top: c.maxHeight * 0.46,
                      child: Center(child: _Caption(b: _bubbles[2]!)),
                    ),
                  // seyirci tepkisi
                  if (_reaction > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 58,
                      child: Center(child: _ReactionBurst(kind: _reaction, key: ValueKey(_bid))),
                    ),
                  // skor tabelası
                  if (board != null)
                    Positioned(right: 10, bottom: 34, child: _Scoreboard(board: board)),
                  // alt bant + kayan yazı
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _LowerThird(
                      title: s.name,
                      sub: s.guestName != null ? 'Konuk: ${s.guestName}' : s.def.label,
                      ticker: _ticker,
                      color: s.def.color,
                    ),
                  ),
                ]);
              }),
            ),
            // olay akışı
            Container(
              width: 210,
              color: const Color(0xFF120E1C),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: SectionLabel('Canlı akış'),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: _feed.length,
                    itemBuilder: (_, i) {
                      final b = _feed[i];
                      return Opacity(
                        opacity: max(0.35, 1 - i * 0.08),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: RichText(
                            text: TextSpan(children: [
                              TextSpan(
                                  text: '${b.who}: ',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 11,
                                      color: b.side == 0
                                          ? AppColors.accent
                                          : (b.side == 1 ? AppColors.cyan : AppColors.yellow))),
                              TextSpan(
                                  text: b.text,
                                  style: const TextStyle(fontSize: 11, color: AppColors.text)),
                            ]),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (s.status == ShowStatus.onAir)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text('Gelir ${fmtShort(game.revenuePerDay(s))}/gün',
                        style: const TextStyle(
                            color: AppColors.green, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _LivePill extends StatefulWidget {
  final bool onAir;
  final String label;
  const _LivePill({required this.onAir, required this.label});
  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (widget.onAir ? AppColors.red : AppColors.yellow)
                .withValues(alpha: 0.6 + 0.4 * _c.value),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(widget.label,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
        ),
      );
}

class _Stat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _Stat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 9, color: AppColors.textDim, fontWeight: FontWeight.w800)),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(value,
                key: ValueKey(value),
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
          ),
        ],
      );
}

class _TalkBubble extends StatelessWidget {
  final _Bubble b;
  final Color color;
  final bool tailLeft;
  const _TalkBubble({required this.b, required this.color, required this.tailLeft});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(b.id),
        tween: Tween(begin: 0.5, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (_, v, child) => Transform.scale(
          scale: v,
          alignment: tailLeft ? Alignment.bottomLeft : Alignment.bottomRight,
          child: Opacity(opacity: v.clamp(0.0, 1.0), child: child),
        ),
        child: Column(
          crossAxisAlignment: tailLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 10, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                // konuşanın portresi
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: PersonAvatar(name: b.who, seed: b.who.hashCode, color: color, size: 38),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(b.who.toUpperCase(),
                        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    Text(b.text,
                        style: const TextStyle(
                            color: Color(0xFF1E182B), fontSize: 13, fontWeight: FontWeight.w800, height: 1.2)),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: CustomPaint(size: const Size(14, 9), painter: _Tail(color)),
            ),
          ],
        ),
      );
}

class _Tail extends CustomPainter {
  final Color c;
  _Tail(this.c);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width / 2, s.height)
      ..close();
    canvas.drawPath(p, Paint()..color = c);
  }

  @override
  bool shouldRepaint(covariant _Tail o) => o.c != c;
}

class _Caption extends StatelessWidget {
  final _Bubble b;
  const _Caption({required this.b});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        key: ValueKey(b.id),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 300),
        builder: (_, v, child) => Opacity(opacity: v, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.yellow.withValues(alpha: 0.6)),
          ),
          child: Text('${b.who}: ${b.text}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
        ),
      );
}

class _ReactionBurst extends StatelessWidget {
  final int kind;
  const _ReactionBurst({super.key, required this.kind});
  @override
  Widget build(BuildContext context) {
    final txt = switch (kind) {
      1 => '😂 HA HA HA 😂',
      2 => '👏 👏 👏 ALKIŞ 👏 👏 👏',
      _ => '😱 OOOO! 😱',
    };
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1800),
      builder: (_, v, _) => Opacity(
        opacity: (v < 0.15 ? v / 0.15 : (1 - v) / 0.85).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, -30 * v),
          child: Transform.scale(
            scale: 0.8 + 0.4 * Curves.easeOutBack.transform(min(1, v * 3)),
            child: Text(txt,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black, blurRadius: 8)])),
          ),
        ),
      ),
    );
  }
}

class _Scoreboard extends StatelessWidget {
  final LiveBoard board;
  const _Scoreboard({required this.board});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        decoration: BoxDecoration(
          color: const Color(0xE6120E1C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.yellow.withValues(alpha: 0.6)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            _team(board.leftName, board.left, AppColors.blue),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text('–', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ),
            _team(board.rightName, board.right, AppColors.red),
          ]),
          if (board.extra != null)
            Text(board.extra!,
                style: const TextStyle(color: AppColors.yellow, fontSize: 10, fontWeight: FontWeight.w800)),
        ]),
      );

  Widget _team(String name, int v, Color c) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 6, height: 22, color: c),
        const SizedBox(width: 4),
        Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
        const SizedBox(width: 6),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
          child: Text(fmtInt(v),
              key: ValueKey('$name$v'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        ),
      ]);
}

class _LowerThird extends StatelessWidget {
  final String title, sub, ticker;
  final Color color;
  const _LowerThird({required this.title, required this.sub, required this.ticker, required this.color});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 4),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 4, 14, 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.6)]),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(title.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
              Text(sub, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
            ]),
          ),
        ),
        Container(
          height: 26,
          color: const Color(0xF0120E1C),
          child: Row(children: [
            Container(
              color: AppColors.red,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              alignment: Alignment.center,
              child: const Text('GÜNDEM', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            ),
            Expanded(child: _Marquee(text: ticker)),
          ]),
        ),
      ]);
}

/// Sağdan sola kayan yazı
class _Marquee extends StatefulWidget {
  final String text;
  const _Marquee({required this.text});
  @override
  State<_Marquee> createState() => _MarqueeState();
}

class _MarqueeState extends State<_Marquee> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
        child: LayoutBuilder(builder: (ctx, c) {
          final tp = TextPainter(
            text: TextSpan(text: widget.text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();
          return AnimatedBuilder(
            animation: _c,
            builder: (_, _) {
              final total = c.maxWidth + tp.width;
              final x = c.maxWidth - _c.value * total;
              return Stack(children: [
                Positioned(
                  left: x,
                  top: 5,
                  child: Text(widget.text,
                      maxLines: 1,
                      softWrap: false,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ]);
            },
          );
        }),
      );
}

/// Sahneye dokununca canlı izleme açılır; köşede "▶ İzle" rozeti görünür.
class WatchTap extends StatelessWidget {
  final Show show;
  final Widget child;
  const WatchTap({super.key, required this.show, required this.child});
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openLiveView(context, show),
        child: Stack(children: [
          child,
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('▶ İzle',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
            ),
          ),
        ]),
      );
}
