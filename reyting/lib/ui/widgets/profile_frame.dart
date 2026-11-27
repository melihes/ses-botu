import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/cloud.dart';
import '../../engine/game.dart';

/// Online listede adının yanında görünen profil çerçeveleri.
/// Çoğu oyunda ilerledikçe açılır; bazıları sıralama ve VIP'e özeldir.
enum FrameStyle { ring, double, dashed, glow, spikes, laurel, crown, gem, flame, stars }

class FrameDef {
  final int id;
  final String name;
  final List<Color> colors;
  final FrameStyle style;
  final String unlockText;
  final bool Function(Game g, int? onlineRank) unlocked;
  const FrameDef(this.id, this.name, this.colors, this.style, this.unlockText, this.unlocked);
}

bool _lv(Game g, int n) => g.studioLevel + 1 >= n;
bool _always(Game g, int? r) => true;

final frameDefs = <FrameDef>[
  FrameDef(0, 'Sade', const [Color(0xFF6E6A80)], FrameStyle.ring, 'Herkese açık', _always),
  FrameDef(1, 'Gökyüzü', const [Color(0xFF4DABF7), Color(0xFF15AABF)], FrameStyle.ring, 'Herkese açık', _always),
  FrameDef(2, 'Gül', const [Color(0xFFFF6B9A), Color(0xFFF783AC)], FrameStyle.ring, 'Herkese açık', _always),
  FrameDef(3, 'Nane', const [Color(0xFF38D9A9), Color(0xFF69DB7C)], FrameStyle.ring, 'Herkese açık', _always),
  FrameDef(4, 'Gün batımı', const [Color(0xFFFFA94D), Color(0xFFFF6B6B)], FrameStyle.double, 'Stüdyo seviye 2', (g, _) => _lv(g, 2)),
  FrameDef(5, 'Okyanus', const [Color(0xFF1C7ED6), Color(0xFF22B8CF)], FrameStyle.double, 'Stüdyo seviye 2', (g, _) => _lv(g, 2)),
  FrameDef(6, 'Film şeridi', const [Color(0xFFDEE2E6), Color(0xFF495057)], FrameStyle.dashed, 'Stüdyo seviye 3', (g, _) => _lv(g, 3)),
  FrameDef(7, 'Neon', const [Color(0xFFB197FC), Color(0xFFFF4F8B)], FrameStyle.glow, 'Stüdyo seviye 3', (g, _) => _lv(g, 3)),
  FrameDef(8, 'Elektrik', const [Color(0xFF66D9E8), Color(0xFFFFD43B)], FrameStyle.spikes, 'Stüdyo seviye 4', (g, _) => _lv(g, 4)),
  FrameDef(9, 'Lav', const [Color(0xFFFF6B2B), Color(0xFFFFD43B)], FrameStyle.flame, 'Stüdyo seviye 4', (g, _) => _lv(g, 4)),
  FrameDef(10, 'Zümrüt', const [Color(0xFF2F9E44), Color(0xFF69DB7C)], FrameStyle.gem, 'Stüdyo seviye 5', (g, _) => _lv(g, 5)),
  FrameDef(11, 'Yakut', const [Color(0xFFC92A2A), Color(0xFFFF8787)], FrameStyle.gem, 'Stüdyo seviye 5', (g, _) => _lv(g, 5)),
  FrameDef(12, 'Defne', const [Color(0xFF94D82D), Color(0xFF2B8A3E)], FrameStyle.laurel, 'Stüdyo seviye 6', (g, _) => _lv(g, 6)),
  FrameDef(13, 'Yıldızlı gece', const [Color(0xFF5F3DC4), Color(0xFFFFD43B)], FrameStyle.stars, 'Stüdyo seviye 6', (g, _) => _lv(g, 6)),
  FrameDef(14, 'Gümüş defne', const [Color(0xFFE9ECEF), Color(0xFFADB5BD)], FrameStyle.laurel, 'Stüdyo seviye 7', (g, _) => _lv(g, 7)),
  FrameDef(15, 'Safir', const [Color(0xFF364FC7), Color(0xFF91A7FF)], FrameStyle.gem, 'Stüdyo seviye 8', (g, _) => _lv(g, 8)),
  FrameDef(16, 'Altın defne', const [Color(0xFFFFD43B), Color(0xFFF08C00)], FrameStyle.laurel, 'Stüdyo seviye 9', (g, _) => _lv(g, 9)),
  FrameDef(17, 'Medya devi', const [Color(0xFFFFD43B), Color(0xFFFF4F8B), Color(0xFF7A3CFF)], FrameStyle.glow, 'Stüdyo seviye 10', (g, _) => _lv(g, 10)),
  FrameDef(18, 'İlk 100', const [Color(0xFF15AABF), Color(0xFFE3FAFC)], FrameStyle.stars, 'Gerçek oyuncu sıralamasında ilk 100', (g, r) => r != null && r <= 100),
  FrameDef(19, 'İlk 50', const [Color(0xFF7048E8), Color(0xFFE5DBFF)], FrameStyle.spikes, 'Gerçek oyuncu sıralamasında ilk 50', (g, r) => r != null && r <= 50),
  FrameDef(20, 'İlk 10', const [Color(0xFFFF4F8B), Color(0xFFFFD43B)], FrameStyle.crown, 'Gerçek oyuncu sıralamasında ilk 10', (g, r) => r != null && r <= 10),
  FrameDef(21, 'Şampiyon', const [Color(0xFFFFD43B), Color(0xFFFFF3BF), Color(0xFFF08C00)], FrameStyle.crown, 'Gerçek oyuncu sıralamasında 1.', (g, r) => r == 1),
  FrameDef(22, 'VIP', const [Color(0xFFFFD43B), Color(0xFF7A3CFF)], FrameStyle.crown, 'VIP paket', (g, _) => g.vip),
  FrameDef(23, 'Elmas', const [Color(0xFF99E9F2), Color(0xFFFFFFFF), Color(0xFF66D9E8)], FrameStyle.gem, '1000 💎 biriktir', (g, _) => g.diamonds >= 1000),
];

FrameDef frameById(int id) => frameDefs.firstWhere((f) => f.id == id, orElse: () => frameDefs.first);

/// Çerçeveli profil rozeti: ortada [child] (logo ya da baş harf)
class ProfileFrame extends StatefulWidget {
  final int frame;
  final double size;
  final Widget child;
  const ProfileFrame({super.key, required this.frame, required this.size, required this.child});

  @override
  State<ProfileFrame> createState() => _ProfileFrameState();
}

class _ProfileFrameState extends State<ProfileFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final f = frameById(widget.frame);
    final s = widget.size;
    final animated = f.style == FrameStyle.glow || f.style == FrameStyle.stars || f.style == FrameStyle.flame;
    Widget painter(double t) => CustomPaint(size: Size(s, s), painter: _FramePainter(f, t));
    return SizedBox(
      width: s,
      height: s,
      child: Stack(alignment: Alignment.center, children: [
        Padding(
          padding: EdgeInsets.all(s * 0.16),
          child: ClipOval(child: SizedBox.expand(child: widget.child)),
        ),
        animated ? AnimatedBuilder(animation: _c, builder: (_, _) => painter(_c.value)) : painter(0),
      ]),
    );
  }
}

class _FramePainter extends CustomPainter {
  final FrameDef f;
  final double t;
  _FramePainter(this.f, this.t);

  @override
  void paint(Canvas c, Size s) {
    final o = s.center(Offset.zero);
    final r = s.width * 0.42;
    final w = s.width * 0.07;
    final cols = f.colors.length == 1 ? [f.colors[0], f.colors[0]] : f.colors;
    final shader = SweepGradient(colors: [...cols, cols.first], transform: GradientRotation(t * pi * 2))
        .createShader(Rect.fromCircle(center: o, radius: r));
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..shader = shader;
    switch (f.style) {
      case FrameStyle.ring:
        c.drawCircle(o, r, ring);
      case FrameStyle.double:
        c.drawCircle(o, r, ring..strokeWidth = w * 0.6);
        c.drawCircle(o, r - w * 1.1, Paint()..style = PaintingStyle.stroke..strokeWidth = w * 0.35..shader = shader);
      case FrameStyle.dashed:
        for (int i = 0; i < 16; i++) {
          c.drawArc(Rect.fromCircle(center: o, radius: r), i * pi / 8, pi / 12, false, ring);
        }
      case FrameStyle.glow:
        c.drawCircle(o, r, Paint()..style = PaintingStyle.stroke..strokeWidth = w * 2.2..shader = shader
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 1.2));
        c.drawCircle(o, r, ring);
      case FrameStyle.spikes:
        final p = Path();
        for (int i = 0; i < 24; i++) {
          final a = i / 24 * pi * 2;
          final rr = i.isEven ? r + w * 1.2 : r - w * 0.3;
          final pt = o + Offset(cos(a), sin(a)) * rr;
          i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
        }
        p.close();
        final hole = Path()..addOval(Rect.fromCircle(center: o, radius: r - w * 0.3));
        c.drawPath(Path.combine(PathOperation.difference, p, hole), Paint()..shader = shader);
      case FrameStyle.laurel:
        c.drawCircle(o, r - w * 0.4, ring..strokeWidth = w * 0.5);
        final leaf = Paint()..shader = shader;
        for (final side in [-1, 1]) {
          for (int i = 0; i < 7; i++) {
            final a = pi / 2 + side * (0.35 + i * 0.32);
            final pt = o + Offset(cos(a), sin(a)) * (r + w * 0.3);
            c.save();
            c.translate(pt.dx, pt.dy);
            c.rotate(a + side * 0.9);
            c.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 2.4, height: w * 1.1), leaf);
            c.restore();
          }
        }
      case FrameStyle.crown:
        c.drawCircle(o, r, ring);
        final top = o - Offset(0, r + w * 0.4);
        final cw = s.width * 0.42, ch = s.width * 0.2;
        final p = Path()
          ..moveTo(top.dx - cw / 2, top.dy + ch * 0.3)
          ..lineTo(top.dx - cw / 2, top.dy - ch * 0.5)
          ..lineTo(top.dx - cw / 4, top.dy - ch * 0.05)
          ..lineTo(top.dx, top.dy - ch * 0.75)
          ..lineTo(top.dx + cw / 4, top.dy - ch * 0.05)
          ..lineTo(top.dx + cw / 2, top.dy - ch * 0.5)
          ..lineTo(top.dx + cw / 2, top.dy + ch * 0.3)
          ..close();
        c.drawPath(p, Paint()..color = cols.first);
        c.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = Colors.black45);
      case FrameStyle.gem:
        c.drawCircle(o, r, ring);
        for (int i = 0; i < 4; i++) {
          final a = i * pi / 2 - pi / 2;
          final pt = o + Offset(cos(a), sin(a)) * r;
          final g = s.width * 0.07;
          final p = Path()
            ..moveTo(pt.dx, pt.dy - g)
            ..lineTo(pt.dx + g, pt.dy)
            ..lineTo(pt.dx, pt.dy + g)
            ..lineTo(pt.dx - g, pt.dy)
            ..close();
          c.drawPath(p, Paint()..color = cols.last);
          c.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = Colors.white70);
        }
      case FrameStyle.flame:
        for (int i = 0; i < 18; i++) {
          final a = i / 18 * pi * 2;
          final h = w * (1.3 + 0.7 * sin(t * pi * 8 + i * 1.7).abs());
          final base = o + Offset(cos(a), sin(a)) * r;
          final tip = o + Offset(cos(a), sin(a)) * (r + h);
          c.drawLine(base, tip, Paint()..strokeWidth = w * 0.9..strokeCap = StrokeCap.round..shader = shader);
        }
        c.drawCircle(o, r, ring);
      case FrameStyle.stars:
        c.drawCircle(o, r, ring..strokeWidth = w * 0.6);
        for (int i = 0; i < 6; i++) {
          final a = i / 6 * pi * 2 + t * pi * 2;
          final pt = o + Offset(cos(a), sin(a)) * r;
          _star(c, pt, s.width * 0.06, Paint()..color = cols.last);
        }
    }
  }

  void _star(Canvas c, Offset o, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final rr = i.isEven ? r : r * 0.45;
      final pt = o + Offset(cos(a), sin(a)) * rr;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(path..close(), p);
  }

  @override
  bool shouldRepaint(covariant _FramePainter o) => o.f.id != f.id || o.t != t;
}

/// Çerçeve seçme penceresi
Future<void> showFramePicker(BuildContext context, Game game, Widget center) => showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: ListenableBuilder(
              listenable: Listenable.merge([game, Cloud.instance]),
              builder: (ctx, _) {
                final rank = Cloud.instance.myRank;
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Text('Profil çerçeven',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                    const Spacer(),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close_rounded)),
                  ]),
                  const Text('Gerçek oyuncular listesinde adının yanında görünür.',
                      style: TextStyle(fontSize: 12, color: Colors.white60)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.78,
                      children: [
                        for (final f in frameDefs)
                          Builder(builder: (_) {
                            final open = f.unlocked(game, rank);
                            final sel = game.profileFrame == f.id;
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: open
                                  ? () {
                                      game.profileFrame = f.id;
                                      game.save();
                                      Cloud.instance.sync(force: true);
                                      Navigator.pop(ctx);
                                    }
                                  : () => game.showToast('🔒 ${f.name}: ${f.unlockText}'),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: sel ? const Color(0xFFFFD43B) : Colors.white12, width: sel ? 2 : 1),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Column(children: [
                                  Expanded(
                                    child: Opacity(
                                      opacity: open ? 1 : 0.35,
                                      child: ProfileFrame(frame: f.id, size: 70, child: center),
                                    ),
                                  ),
                                  Text(open ? f.name : '🔒 ${f.name}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                                  if (!open)
                                    Text(f.unlockText,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 9, color: Colors.white54)),
                                ]),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ]);
              },
            ),
          ),
        ),
      ),
    );
