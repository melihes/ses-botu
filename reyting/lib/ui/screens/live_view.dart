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
import '../widgets/face.dart';
import 'live_crisis.dart';
import 'live_stage.dart';

/// Programı tam ekran canlı izle: konuşmalar, skor, seyirci tepkileri.
/// Tam ekran (opak) sayfa: arkadaki ekranların animasyonları bu sırada durur.
Future<void> openLiveView(BuildContext context, Show s) => Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, _, _) => Scaffold(backgroundColor: Colors.black, body: LiveView(show: s)),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
    );

class LiveView extends StatefulWidget {
  final Show show;
  const LiveView({super.key, required this.show});
  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {
  LiveScript? _script;
  Timer? _timer;
  final _feed = <LiveBeat>[];
  String _ticker = '';
  int _bid = 0;
  double _jitter = 1;
  final _r = Random();
  final Map<String, LivePerson> _people = {};
  late LivePerson _host, _guest;
  List<FaceSpec> _crowd = const [];
  LiveBeat? _beat;
  bool _paused = false;

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
    // canlı yayındaki kişiler: kadrodaki yüzlerle aynı
    for (final p in crew) {
      _people[first(p)] = LivePerson(
          first(p), PersonAvatar.specFor(p.id.hashCode, p.name, age: p.age, star: p.isStar), p.id.hashCode);
    }
    final g = s.guestName;
    if (g != null) {
      _people[g] = LivePerson(g, PersonAvatar.specFor(g.hashCode, g, age: 40, star: true), g.hashCode);
    }
    LivePerson person(String who) =>
        _people[who] ??= LivePerson(who, PersonAvatar.specFor(who.hashCode, who, age: 28), who.hashCode);
    _host = person(host);
    _guest = person(guest);
    final kids = s.genre == Genre.cocuk;
    _crowd = [
      for (int i = 0; i < 14; i++)
        FaceSpec.of(s.id.hashCode + i * 977,
            female: i.isOdd, age: kids ? 12 : 19 + (i * 7) % 45),
    ];
    _ticker = '${game.channelName} · ${s.name} · ${s.def.label}';
    _step();
  }

  void _step() {
    if (!mounted || _paused) return;
    final b = _script!.next();
    if (b.side < 2 && !_people.containsKey(b.who)) {
      _people[b.who] = LivePerson(b.who, PersonAvatar.specFor(b.who.hashCode, b.who, age: 27), b.who.hashCode);
    }
    setState(() {
      _beat = b;
      _bid++;
      if (b.ticker != null) _ticker = b.ticker!;
      _feed.insert(0, b);
      if (_feed.length > 30) _feed.removeLast();
      _jitter = 0.97 + _r.nextDouble() * 0.06 + (b.reaction == 2 ? 0.03 : 0);
    });
    // konuşma okunabilsin: süre metnin uzunluğuna göre (ilk an jenerik)
    final ms = _bid == 1 ? 2600 : (1700 + b.text.length * 36).clamp(2800, 6200);
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: ms), _step);
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
              child: CrisisLayer(
                show: s,
                // kriz sırasında konuşma akışı durur
                onActive: (on) {
                  _paused = on;
                  if (on) {
                    _timer?.cancel();
                  } else {
                    _step();
                  }
                },
                child: LiveStage(
                genre: s.genre,
                prop: fmt.prop,
                title: s.name,
                channel: game.channelName,
                channelLogo: CompanyLogoView(logo: game.logo, size: 22),
                color: s.def.color,
                beat: _beat,
                beatId: _bid,
                ticker: _ticker,
                board: board == null ? null : _Scoreboard(board: board),
                host: _host,
                guest: _guest,
                people: _people,
                crowd: _crowd,
                seed: s.id.hashCode,
              ),
              ),
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
                          child: Text.rich(
                            TextSpan(children: [
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
