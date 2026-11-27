import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/calendar.dart';
import '../../data/content.dart';
import '../../models/models.dart';
import '../widgets/scene.dart';

/// "Sen yokken" haber bülteni: oyuna dönünce, kapalıyken olanlar
/// haber başlıkları olarak sırayla gelir. "Geç" ile atlanabilir.
Future<void> showBulletin(BuildContext context, String channel, int dayFrom, int dayTo, PeriodSummary s) {
  if (s.headlines.isEmpty) return Future.value();
  return Navigator.of(context).push(PageRouteBuilder(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (_, _, _) => _Bulletin(channel: channel, dayFrom: dayFrom, dayTo: dayTo, s: s),
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  ));
}

class _Bulletin extends StatefulWidget {
  final String channel;
  final int dayFrom, dayTo;
  final PeriodSummary s;
  const _Bulletin({required this.channel, required this.dayFrom, required this.dayTo, required this.s});
  @override
  State<_Bulletin> createState() => _BulletinState();
}

class _BulletinState extends State<_Bulletin> {
  int _shown = 1;
  Timer? _timer;

  List<(String, String, bool)> get _items => widget.s.headlines;

  @override
  void initState() {
    super.initState();
    // başlıklar teker teker gelir
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      if (_shown >= _items.length) {
        _timer?.cancel();
        return;
      }
      setState(() => _shown++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items.take(_shown).toList().reversed.toList();
    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: SafeArea(
        child: Column(children: [
          // üst bant
          Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: const Color(0xFFC92A2A),
            child: Row(children: [
              const Text('📰 SEN YOKKEN · ANA HABER',
                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 14, color: Colors.white)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${trUpper(widget.channel)} · ${dateLabel(widget.dayFrom)} – ${dateLabel(widget.dayTo)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.skip_next_rounded),
                label: const Text('Geç', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ]),
          ),
          Expanded(
            child: LayoutBuilder(builder: (ctx, c) {
              final anchorW = (c.maxWidth * 0.36).clamp(160.0, 320.0);
              return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                // spiker
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: StageScene(
                    prop: Prop.newsDesk,
                    color: AppColors.blue,
                    seed: widget.channel.hashCode,
                    talk: true,
                    live: true,
                    width: anchorW,
                    height: c.maxHeight - 16,
                  ),
                ),
                // başlıklar
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                    children: [
                      for (final (i, h) in items.indexed)
                        TweenAnimationBuilder<double>(
                          key: ValueKey('${h.$1}$i${items.length}'),
                          tween: Tween(begin: i == 0 ? 0 : 1, end: 1),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(offset: Offset(40 * (1 - v), 0), child: child),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              decoration: BoxDecoration(
                                color: i == 0 ? const Color(0xFF14213D) : const Color(0xFF0D1428),
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(color: h.$3 ? AppColors.green : AppColors.red, width: 4),
                                ),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(h.$1,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900, fontSize: i == 0 ? 16 : 14, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text(h.$2,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              ]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ]);
            }),
          ),
          // alt bant: raporu gör
          Container(
            height: 44,
            color: const Color(0xFF0B1022),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              Expanded(
                child: Text(
                  '${widget.s.days} gün geçti · ${_shown < _items.length ? 'haberler geliyor…' : 'bülten bitti'}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Raporu gör'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
