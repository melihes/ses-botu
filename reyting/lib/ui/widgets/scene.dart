import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/content.dart';

/// Sahne türleri: her program türünün kendi dekoru var, filmler sinema salonu.
enum SceneKind {
  dizi,
  yarisma,
  haber,
  magazin,
  talkShow,
  belgesel,
  spor,
  cocuk,
  film,
  studio,
}

SceneKind sceneForGenre(Genre g) => SceneKind.values[g.index];

/// Kodla çizilmiş, sürekli hareket eden stüdyo sahnesi.
/// [tier] (0-2) bütçe: arttıkça daha çok spot, kamera ve ışık.
/// [live] yayındaysa köşede yanıp sönen CANLI ışığı.
class StageScene extends StatefulWidget {
  final SceneKind kind;
  final Color color;
  final int tier;
  final bool live;
  final String? badge;
  final double? width;
  final double height;
  final BorderRadius radius;
  const StageScene({
    super.key,
    required this.kind,
    required this.color,
    this.tier = 1,
    this.live = false,
    this.badge,
    this.width,
    this.height = 90,
    this.radius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<StageScene> createState() => _StageSceneState();
}

class _StageSceneState extends State<StageScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(seconds: 8))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: widget.radius,
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(fit: StackFit.expand, children: [
            CustomPaint(
              painter: _ScenePainter(
                  _c, widget.kind, widget.color, widget.tier, widget.live),
            ),
            if (widget.badge != null)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(widget.badge!,
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w800)),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _ScenePainter extends CustomPainter {
  final Animation<double> a;
  final SceneKind kind;
  final Color color;
  final int tier;
  final bool live;
  _ScenePainter(this.a, this.kind, this.color, this.tier, this.live)
      : super(repaint: a);

  double get t => a.value; // 0..1
  double get w => a.value * 2 * pi;

  @override
  void paint(Canvas canvas, Size size) {
    final W = size.width, H = size.height;
    final floorY = H * 0.78;

    // Arka plan
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(color, Colors.black, 0.78)!,
            Color.lerp(color, AppColors.bg, 0.45)!,
          ],
        ).createShader(Offset.zero & size),
    );

    _backdrop(canvas, size, floorY);

    // Zemin
    final floor = Paint()..color = Colors.black.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTRB(0, floorY, W, H), floor);
    final line = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..strokeWidth = 1;
    for (int i = -4; i <= 4; i++) {
      canvas.drawLine(Offset(W / 2 + i * W * 0.06, floorY),
          Offset(W / 2 + i * W * 0.22, H), line);
    }

    _foreground(canvas, size, floorY);

    // Tavan ışık barı ve spotlar (bütçeye göre)
    if (kind != SceneKind.belgesel && kind != SceneKind.spor) {
      final truss = Paint()..color = Colors.black.withValues(alpha: 0.6);
      canvas.drawRect(Rect.fromLTWH(0, 0, W, H * 0.06), truss);
      final lamps = 3 + tier * 2;
      for (int i = 0; i < lamps; i++) {
        final x = W * (i + 0.5) / lamps;
        final on = (sin(w * 3 + i * 1.7) + 1) / 2;
        canvas.drawCircle(
            Offset(x, H * 0.045),
            H * 0.025,
            Paint()
              ..color = Color.lerp(AppColors.yellow, Colors.white, on)!
                  .withValues(alpha: 0.6 + 0.4 * on));
      }
      final spots = 1 + tier;
      for (int i = 0; i < spots; i++) {
        final x = W * (i + 1) / (spots + 1);
        final swing = sin(w + i * 2.1) * W * 0.18;
        final path = Path()
          ..moveTo(x - 3, H * 0.05)
          ..lineTo(x + 3, H * 0.05)
          ..lineTo(x + swing + W * 0.09, floorY + 4)
          ..lineTo(x + swing - W * 0.09, floorY + 4)
          ..close();
        canvas.drawPath(
            path,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.28),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ).createShader(Rect.fromLTWH(0, 0, W, floorY)));
        canvas.drawOval(
            Rect.fromCenter(
                center: Offset(x + swing, floorY + 3),
                width: W * 0.2,
                height: H * 0.05),
            Paint()..color = Colors.white.withValues(alpha: 0.12));
      }
    }

    // Kameralar (bütçeye göre)
    if (tier >= 1 && kind != SceneKind.film && kind != SceneKind.belgesel) {
      _camera(canvas, Offset(W * 0.08, H * 0.92), H * 0.22, false);
    }
    if (tier >= 2 && kind != SceneKind.film && kind != SceneKind.belgesel) {
      _jib(canvas, size);
    }

    // CANLI ışığı
    if (live) {
      final on = sin(w * 8) > -0.2;
      final r = Rect.fromLTWH(W - 52, 5, 47, 15);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = Colors.black.withValues(alpha: 0.6));
      canvas.drawCircle(Offset(r.left + 8, r.center.dy), 3.5,
          Paint()..color = on ? AppColors.red : AppColors.red.withValues(alpha: 0.25));
      _text(canvas, 'CANLI', Offset(r.left + 14, r.top + 1.5), 9,
          Colors.white);
    }
  }

  // ---------------------------------------------------------------
  void _backdrop(Canvas c, Size s, double floorY) {
    final W = s.width, H = s.height;
    switch (kind) {
      case SceneKind.dizi:
        // Mahalle silueti, ışıkları yanıp sönen pencereler
        final rnd = Random(7);
        double x = 0;
        int i = 0;
        while (x < W) {
          final bw = W * (0.1 + rnd.nextDouble() * 0.08);
          final bh = H * (0.25 + rnd.nextDouble() * 0.3);
          final r = Rect.fromLTWH(x, floorY - bh, bw - 2, bh);
          c.drawRect(r, Paint()..color = Colors.black.withValues(alpha: 0.45));
          final roof = Path()
            ..moveTo(r.left - 2, r.top)
            ..lineTo(r.center.dx, r.top - bh * 0.18)
            ..lineTo(r.right + 2, r.top)
            ..close();
          c.drawPath(roof, Paint()..color = color.withValues(alpha: 0.35));
          for (double wy = r.top + 5; wy < r.bottom - 6; wy += 9) {
            for (double wx = r.left + 4; wx < r.right - 5; wx += 8) {
              i++;
              final lit = sin(w * 2 + i * 1.3) > 0.1;
              c.drawRect(
                  Rect.fromLTWH(wx, wy, 4, 5),
                  Paint()
                    ..color = lit
                        ? AppColors.yellow.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.08));
            }
          }
          x += bw;
        }
      case SceneKind.yarisma:
        // Dönen büyük çark
        final center = Offset(W * 0.5, H * 0.42);
        final r = H * 0.3;
        const cols = [
          AppColors.accent,
          AppColors.yellow,
          AppColors.cyan,
          AppColors.green,
          AppColors.purple,
          AppColors.orange,
          AppColors.pink,
          AppColors.blue,
        ];
        for (int k = 0; k < 8; k++) {
          c.drawArc(Rect.fromCircle(center: center, radius: r),
              w + k * pi / 4, pi / 4, true, Paint()..color = cols[k]);
        }
        c.drawCircle(center, r * 0.18, Paint()..color = Colors.white);
        c.drawCircle(
            center,
            r,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3
              ..color = Colors.white.withValues(alpha: 0.8));
        // Işıklı kenar
        for (int k = 0; k < 16; k++) {
          final ang = k * pi / 8;
          final on = (k + (t * 16).floor()) % 2 == 0;
          c.drawCircle(center + Offset(cos(ang), sin(ang)) * (r + 4), 2,
              Paint()..color = on ? AppColors.yellow : Colors.white24);
        }
      case SceneKind.haber:
        // Dönen dünya
        final center = Offset(W * 0.72, H * 0.38);
        final r = H * 0.24;
        c.drawCircle(center, r, Paint()..color = AppColors.blue.withValues(alpha: 0.35));
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.cyan.withValues(alpha: 0.7);
        c.drawCircle(center, r, stroke);
        for (int k = 0; k < 4; k++) {
          final ph = (w + k * pi / 4) % pi;
          c.drawOval(
              Rect.fromCenter(
                  center: center, width: 2 * r * cos(ph).abs(), height: 2 * r),
              stroke);
        }
        for (final f in [-0.5, 0.0, 0.5]) {
          final y = center.dy + f * r;
          final hw = sqrt(max(0, r * r - (f * r) * (f * r)));
          c.drawLine(Offset(center.dx - hw, y), Offset(center.dx + hw, y), stroke);
        }
        // Ekran duvarı
        c.drawRect(Rect.fromLTWH(W * 0.08, H * 0.16, W * 0.36, H * 0.34),
            Paint()..color = color.withValues(alpha: 0.35));
        for (int k = 0; k < 3; k++) {
          c.drawRect(
              Rect.fromLTWH(W * 0.1, H * (0.2 + k * 0.09),
                  W * (0.15 + 0.12 * ((sin(w + k) + 1) / 2)), H * 0.04),
              Paint()..color = Colors.white.withValues(alpha: 0.5));
        }
      case SceneKind.magazin:
        // Arkada flaşlar patlıyor
        c.drawRect(Rect.fromLTWH(0, H * 0.1, W, floorY - H * 0.1),
            Paint()..color = AppColors.purple.withValues(alpha: 0.15));
        final seg = (t * 24).floor();
        for (int k = 0; k < 3; k++) {
          final rr = Random(seg * 31 + k);
          final p = Offset(rr.nextDouble() * W, H * (0.15 + rr.nextDouble() * 0.5));
          final life = (t * 24) - seg;
          final a = (1 - life).clamp(0.0, 1.0);
          c.drawCircle(p, 4 + 10 * life,
              Paint()..color = Colors.white.withValues(alpha: 0.6 * a));
          c.drawCircle(p, 2, Paint()..color = Colors.white.withValues(alpha: a));
        }
      case SceneKind.talkShow:
        // Gece silueti ve ay
        c.drawCircle(Offset(W * 0.78, H * 0.28), H * 0.1,
            Paint()..color = const Color(0xFFFFF4C8));
        final rnd = Random(3);
        double x = 0;
        while (x < W) {
          final bw = W * (0.05 + rnd.nextDouble() * 0.06);
          final bh = H * (0.15 + rnd.nextDouble() * 0.35);
          c.drawRect(Rect.fromLTWH(x, floorY - bh, bw - 1, bh),
              Paint()..color = Colors.black.withValues(alpha: 0.5));
          x += bw;
        }
        for (int k = 0; k < 14; k++) {
          final rr = Random(k);
          final tw = (sin(w * 4 + k) + 1) / 2;
          c.drawCircle(Offset(rr.nextDouble() * W, rr.nextDouble() * H * 0.4),
              0.8 + tw, Paint()..color = Colors.white.withValues(alpha: 0.3 + 0.5 * tw));
        }
      case SceneKind.belgesel:
        // Gökyüzü, güneş, dağlar, uçan kuş
        final sky = Rect.fromLTWH(0, 0, W, floorY);
        c.drawRect(
            sky,
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF3B6FB6), Color(0xFFF2B27A)],
              ).createShader(sky));
        c.drawCircle(Offset(W * 0.75, H * 0.28 + sin(w) * 3), H * 0.11,
            Paint()..color = const Color(0xFFFFE08A));
        for (int layer = 0; layer < 3; layer++) {
          final p = Path()..moveTo(0, floorY);
          final rnd = Random(layer + 11);
          for (double x = 0; x <= W; x += W / 6) {
            p.lineTo(x, floorY - H * (0.32 - 0.09 * layer + rnd.nextDouble() * 0.12));
          }
          p
            ..lineTo(W, floorY)
            ..close();
          c.drawPath(
              p,
              Paint()
                ..color = Color.lerp(const Color(0xFF4FA36B), const Color(0xFF173A2A), layer / 2)!);
        }
        final bx = (t * 1.3 % 1) * (W + 40) - 20;
        final by = H * 0.25 + sin(w * 3) * 6;
        final flap = sin(w * 20) * 4;
        final bird = Paint()
          ..color = Colors.black87
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        c.drawLine(Offset(bx - 7, by - flap), Offset(bx, by), bird);
        c.drawLine(Offset(bx, by), Offset(bx + 7, by - flap), bird);
      case SceneKind.spor:
        // Tribün ve saha
        c.drawRect(Rect.fromLTWH(0, H * 0.1, W, H * 0.35),
            Paint()..color = Colors.black.withValues(alpha: 0.4));
        for (int k = 0; k < 60; k++) {
          final rr = Random(k);
          final jump = sin(w * 6 + k) > 0.6 ? 2.0 : 0.0;
          c.drawCircle(
              Offset(rr.nextDouble() * W, H * (0.15 + rr.nextDouble() * 0.27) - jump),
              1.6,
              Paint()
                ..color = [AppColors.accent, AppColors.yellow, Colors.white, AppColors.cyan][k % 4]
                    .withValues(alpha: 0.8));
        }
        c.drawRect(Rect.fromLTWH(0, H * 0.45, W, floorY - H * 0.45 + H),
            Paint()..color = const Color(0xFF2E8B57));
        final lp = Paint()
          ..color = Colors.white70
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        c.drawLine(Offset(W / 2, H * 0.45), Offset(W / 2, H), lp);
        c.drawCircle(Offset(W / 2, H * 0.72), H * 0.12, lp);
        final bxp = W * (0.2 + 0.6 * ((sin(w * 2) + 1) / 2));
        final byp = H * 0.7 - (sin(w * 4).abs()) * H * 0.2;
        c.drawCircle(Offset(bxp, byp), 3.5, Paint()..color = Colors.white);
      case SceneKind.cocuk:
        // Gökkuşağı ve balonlar
        const rb = [AppColors.red, AppColors.orange, AppColors.yellow, AppColors.green, AppColors.blue, AppColors.purple];
        for (int k = 0; k < rb.length; k++) {
          c.drawArc(
              Rect.fromCenter(
                  center: Offset(W / 2, floorY),
                  width: W * 0.8 - k * 8,
                  height: H * 1.1 - k * 8),
              pi,
              pi,
              false,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = 4
                ..color = rb[k].withValues(alpha: 0.7));
        }
        for (int k = 0; k < 5; k++) {
          final x = W * (0.12 + k * 0.19);
          final y = H * 0.35 + sin(w * 2 + k) * 6;
          c.drawLine(Offset(x, y + 9), Offset(x + sin(w + k) * 3, floorY),
              Paint()..color = Colors.white38);
          c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 13, height: 17),
              Paint()..color = rb[k]);
        }
      case SceneKind.film:
        // Sinema perdesi ve projektör ışığı
        final screen = Rect.fromLTWH(W * 0.15, H * 0.12, W * 0.7, H * 0.5);
        c.drawRect(
            screen,
            Paint()
              ..shader = LinearGradient(colors: [
                color.withValues(alpha: 0.9),
                Color.lerp(color, Colors.white, 0.3 + 0.2 * sin(w * 2))!,
              ]).createShader(screen));
        final beam = Path()
          ..moveTo(W * 0.5, H * 0.98)
          ..lineTo(screen.left, screen.bottom)
          ..lineTo(screen.right, screen.bottom)
          ..close();
        c.drawPath(beam, Paint()..color = Colors.white.withValues(alpha: 0.07 + 0.04 * sin(w * 6)));
        // perde kenarları
        final curtain = Paint()..color = const Color(0xFF7A1530);
        c.drawRect(Rect.fromLTWH(0, 0, W * 0.15, floorY), curtain);
        c.drawRect(Rect.fromLTWH(W * 0.85, 0, W * 0.15, floorY), curtain);
      case SceneKind.studio:
        // Stüdyo binası ve dönen anten
        final b = Rect.fromLTWH(W * 0.25, H * 0.3, W * 0.5, floorY - H * 0.3);
        c.drawRect(b, Paint()..color = Colors.black.withValues(alpha: 0.5));
        for (double y = b.top + 6; y < b.bottom - 6; y += 10) {
          for (double x = b.left + 6; x < b.right - 6; x += 10) {
            final lit = sin(w * 2 + x * 0.3 + y) > 0;
            c.drawRect(Rect.fromLTWH(x, y, 5, 5),
                Paint()..color = lit ? AppColors.cyan.withValues(alpha: 0.7) : Colors.white10);
          }
        }
        final top = Offset(b.center.dx, b.top);
        c.drawLine(top, top - Offset(0, H * 0.2),
            Paint()..color = Colors.white70..strokeWidth = 2);
        for (int k = 0; k < 3; k++) {
          final rr = ((t * 3 + k / 3) % 1) * H * 0.25;
          c.drawCircle(top - Offset(0, H * 0.2), rr,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = AppColors.accent.withValues(alpha: 1 - rr / (H * 0.25)));
        }
    }
  }

  void _foreground(Canvas c, Size s, double floorY) {
    final W = s.width, H = s.height;
    switch (kind) {
      case SceneKind.haber:
        // Haber masası + kayan bant
        final desk = RRect.fromRectAndRadius(
            Rect.fromLTWH(W * 0.25, floorY - H * 0.14, W * 0.5, H * 0.16),
            const Radius.circular(4));
        c.drawRRect(desk, Paint()..color = color.withValues(alpha: 0.9));
        _person(c, Offset(W * 0.5, floorY - H * 0.14), H * 0.16, AppColors.blue);
        final band = Rect.fromLTWH(0, H * 0.86, W, H * 0.14);
        c.drawRect(band, Paint()..color = AppColors.red.withValues(alpha: 0.9));
        c.save();
        c.clipRect(band);
        const msg = 'SON DAKİKA • Reytingler açıklandı • Yarın hava güneşli • '
            'Borsa güne yükselişle başladı •  ';
        final tw = _measure(msg, H * 0.085);
        final off = -((t * 2) % 1) * tw;
        for (double x = off; x < W; x += tw) {
          _text(c, msg, Offset(x, band.top + 1), H * 0.085, Colors.white);
        }
        c.restore();
      case SceneKind.yarisma:
        // Kürsüler ve seyirci
        for (int k = 0; k < 3; k++) {
          final x = W * (0.2 + k * 0.3);
          c.drawRect(Rect.fromLTWH(x - 10, floorY - H * 0.12, 20, H * 0.14),
              Paint()..color = [AppColors.accent, AppColors.cyan, AppColors.yellow][k]);
          _person(c, Offset(x, floorY - H * 0.12), H * 0.13, Colors.white70);
        }
        _audience(c, s);
      case SceneKind.talkShow:
        // Kanepe, masa, sunucu
        c.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(W * 0.15, floorY - H * 0.1, W * 0.3, H * 0.1),
                const Radius.circular(6)),
            Paint()..color = AppColors.purple);
        _person(c, Offset(W * 0.3, floorY - H * 0.1), H * 0.15, AppColors.pink);
        c.drawRect(Rect.fromLTWH(W * 0.58, floorY - H * 0.13, W * 0.22, H * 0.13),
            Paint()..color = color.withValues(alpha: 0.9));
        _person(c, Offset(W * 0.69, floorY - H * 0.13), H * 0.15, AppColors.cyan);
        _audience(c, s);
      case SceneKind.magazin:
        // Kırmızı halı ve yürüyen ünlü
        final carpet = Path()
          ..moveTo(W * 0.42, floorY)
          ..lineTo(W * 0.58, floorY)
          ..lineTo(W * 0.75, H)
          ..lineTo(W * 0.25, H)
          ..close();
        c.drawPath(carpet, Paint()..color = const Color(0xFFB3123A));
        final px = W * (0.3 + 0.4 * ((sin(w) + 1) / 2));
        _person(c, Offset(px, floorY + H * 0.04), H * 0.22, AppColors.yellow);
      case SceneKind.dizi:
        _person(c, Offset(W * 0.4 + sin(w) * W * 0.05, floorY + 2), H * 0.2, AppColors.pink);
        _person(c, Offset(W * 0.6 - sin(w) * W * 0.05, floorY + 2), H * 0.2, AppColors.cyan);
      case SceneKind.cocuk:
        _person(c, Offset(W * 0.5, floorY + 2 - (sin(w * 4).abs()) * 6), H * 0.18, AppColors.yellow);
      case SceneKind.film:
        // Seyirci koltukları
        for (int row = 0; row < 2; row++) {
          for (double x = W * 0.05; x < W; x += W * 0.07) {
            c.drawRRect(
                RRect.fromRectAndRadius(
                    Rect.fromLTWH(x, H * (0.8 + row * 0.1), W * 0.05, H * 0.08),
                    const Radius.circular(3)),
                Paint()..color = const Color(0xFF5A1024));
          }
        }
        // Dönen film makarası
        final rc = Offset(W * 0.92, H * 0.2);
        c.drawCircle(rc, H * 0.1, Paint()..color = Colors.white24);
        for (int k = 0; k < 5; k++) {
          final ang = w * 2 + k * 2 * pi / 5;
          c.drawCircle(rc + Offset(cos(ang), sin(ang)) * H * 0.055, H * 0.022,
              Paint()..color = Colors.black54);
        }
      default:
        break;
    }
  }

  void _audience(Canvas c, Size s) {
    final W = s.width, H = s.height;
    for (int k = 0; k < 18; k++) {
      final x = W * (k + 0.5) / 18;
      final clap = sin(w * 10 + k * 0.9) > 0.3 ? 2.0 : 0.0;
      c.drawCircle(Offset(x, H * 0.97 - clap), H * 0.045,
          Paint()..color = Colors.black.withValues(alpha: 0.75));
    }
  }

  void _person(Canvas c, Offset feet, double h, Color col) {
    final body = Paint()..color = col;
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: feet - Offset(0, h * 0.35), width: h * 0.32, height: h * 0.55),
            Radius.circular(h * 0.12)),
        body);
    c.drawCircle(feet - Offset(0, h * 0.8), h * 0.15,
        Paint()..color = const Color(0xFFF2C9A0));
  }

  void _camera(Canvas c, Offset base, double h, bool flip) {
    final p = Paint()..color = Colors.black.withValues(alpha: 0.85);
    // tripod
    c.drawLine(base, base - Offset(0, h * 0.6), p..strokeWidth = 2);
    c.drawLine(base - Offset(0, h * 0.3), base + Offset(-h * 0.2, 0), p);
    c.drawLine(base - Offset(0, h * 0.3), base + Offset(h * 0.2, 0), p);
    c.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(base.dx - h * 0.2, base.dy - h, h * 0.5, h * 0.35),
            const Radius.circular(3)),
        p);
    c.drawCircle(Offset(base.dx + h * 0.32, base.dy - h * 0.82), h * 0.08,
        Paint()..color = AppColors.red.withValues(alpha: (sin(w * 8) + 1) / 2));
  }

  void _jib(Canvas c, Size s) {
    final W = s.width, H = s.height;
    final pivot = Offset(W * 0.93, H * 0.85);
    final ang = -pi / 2 - 0.5 + sin(w) * 0.35;
    final tip = pivot + Offset(cos(ang), sin(ang)) * H * 0.6;
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.85)
      ..strokeWidth = 3;
    c.drawLine(Offset(pivot.dx, H), pivot, p);
    c.drawLine(pivot, tip, p);
    c.drawRect(Rect.fromCenter(center: tip, width: 12, height: 8), p);
  }

  double _measure(String s, double size) => (TextPainter(
        text: TextSpan(
            text: s,
            style: TextStyle(fontSize: size, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout())
          .width;

  void _text(Canvas c, String s, Offset o, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(
          text: s,
          style: TextStyle(
              color: col, fontSize: size, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, o);
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.kind != kind || old.color != color || old.tier != tier || old.live != live;
}
