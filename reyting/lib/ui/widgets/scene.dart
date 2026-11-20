import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/content.dart';

export '../../data/content.dart' show Prop;

/// Programın formatına göre sahne dekoru.
Prop propFor(Genre g, int tier) => formatOf(g, tier).prop;

const _outdoor = {
  Prop.police, Prop.epic, Prop.island, Prop.field, Prop.paparazzi,
  Prop.nature, Prop.ocean, Prop.history, Prop.space, Prop.football,
  Prop.derby, Prop.tournament, Prop.newYear, Prop.neighborhood,
};

/// Kodla çizilmiş, sürekli hareket eden sahne.
/// [tier] format seviyesi: arttıkça daha çok spot, kamera ve vinç.
class StageScene extends StatefulWidget {
  final Prop prop;
  final Color color;
  final int tier;
  final bool live;
  final String? badge;
  final double? width;
  final double height;
  final BorderRadius radius;
  const StageScene({
    super.key,
    required this.prop,
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
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 8))
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
                painter: ScenePainter(_c, widget.prop, widget.color,
                    widget.tier, widget.live)),
            if (widget.badge != null)
              Positioned(
                left: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
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

const skinTones = [
  Color(0xFFF2C9A0),
  Color(0xFFE0AC7E),
  Color(0xFFC68B59),
  Color(0xFF8D5A3B),
];
const hairColors = [
  Color(0xFF2B1B12),
  Color(0xFF5A3A22),
  Color(0xFFB07A3B),
  Color(0xFF111111),
  Color(0xFF8A8A8A),
];

/// Ortak çizim yardımcıları (sahneler ve eşya resimleri kullanır)
class Draw {
  final Canvas c;
  final Size s;
  Draw(this.c, this.s);
  double get W => s.width;
  double get H => s.height;
  Paint p(Color col) => Paint()..color = col;

  void rect(double x, double y, double w, double h, Color col) =>
      c.drawRect(Rect.fromLTWH(x * W, y * H, w * W, h * H), p(col));
  void rrect(double x, double y, double w, double h, double r, Color col) =>
      c.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(x * W, y * H, w * W, h * H), Radius.circular(r)),
          p(col));
  void circle(double x, double y, double r, Color col) =>
      c.drawCircle(Offset(x * W, y * H), r * H, p(col));
  void oval(double x, double y, double w, double h, Color col) => c.drawOval(
      Rect.fromCenter(center: Offset(x * W, y * H), width: w * W, height: h * H),
      p(col));
  void line(double x1, double y1, double x2, double y2, Color col,
          [double width = 1.5]) =>
      c.drawLine(
          Offset(x1 * W, y1 * H),
          Offset(x2 * W, y2 * H),
          p(col)
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round);
  void poly(List<double> xy, Color col) {
    final path = Path()..moveTo(xy[0] * W, xy[1] * H);
    for (int i = 2; i < xy.length; i += 2) {
      path.lineTo(xy[i] * W, xy[i + 1] * H);
    }
    path.close();
    c.drawPath(path, p(col));
  }

  void vgrad(double y0, double y1, Color top, Color bottom) {
    final r = Rect.fromLTRB(0, y0 * H, W, y1 * H);
    c.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [top, bottom])
              .createShader(r));
  }

  void glow(double x, double y, double r, Color col) {
    final o = Offset(x * W, y * H);
    c.drawCircle(
        o,
        r * H,
        Paint()
          ..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: o, radius: r * H)));
  }

  void text(String t, double x, double y, double size, Color col,
      {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
          text: t,
          style: TextStyle(
              color: col, fontSize: size * H, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x * W - (center ? tp.width / 2 : 0), y * H));
  }

  double measure(String t, double size) => (TextPainter(
        text: TextSpan(
            text: t,
            style: TextStyle(fontSize: size * H, fontWeight: FontWeight.w900)),
        textDirection: TextDirection.ltr,
      )..layout())
          .width;

  /// İnsan figürü. [x],[feet] göreli konum, [h] boy (yüksekliğe oranla).
  /// [armL]/[armR] radyan: 0 aşağı, pi/2 yana, pi yukarı.
  void person(
    double x,
    double feet,
    double h, {
    Color shirt = AppColors.cyan,
    Color pants = const Color(0xFF2A2440),
    int skin = 0,
    int hair = 0,
    double armL = 0.15,
    double armR = 0.15,
    bool mic = false,
    bool longHair = false,
    bool legsHidden = false,
    Color? hat,
    bool sunglasses = false,
    double walk = 0,
  }) {
    final px = x * W, fy = feet * H, ph = h * H;
    final skinC = skinTones[skin % skinTones.length];
    final hairC = hairColors[hair % hairColors.length];
    final hip = fy - ph * 0.46;
    final shoulder = fy - ph * 0.79;
    if (!legsHidden) {
      final lp = Paint()
        ..color = pants
        ..strokeWidth = ph * 0.1
        ..strokeCap = StrokeCap.round;
      final sw = sin(walk) * ph * 0.08;
      c.drawLine(Offset(px - ph * 0.05, hip), Offset(px - ph * 0.05 + sw, fy - ph * 0.04), lp);
      c.drawLine(Offset(px + ph * 0.05, hip), Offset(px + ph * 0.05 - sw, fy - ph * 0.04), lp);
      final shoe = p(const Color(0xFF151018));
      c.drawOval(Rect.fromCenter(center: Offset(px - ph * 0.06 + sw, fy - ph * 0.02), width: ph * 0.13, height: ph * 0.05), shoe);
      c.drawOval(Rect.fromCenter(center: Offset(px + ph * 0.06 - sw, fy - ph * 0.02), width: ph * 0.13, height: ph * 0.05), shoe);
    }
    // gövde
    final torso = Path()
      ..moveTo(px - ph * 0.15, shoulder + ph * 0.03)
      ..quadraticBezierTo(px - ph * 0.16, shoulder - ph * 0.01, px - ph * 0.1, shoulder - ph * 0.01)
      ..lineTo(px + ph * 0.1, shoulder - ph * 0.01)
      ..quadraticBezierTo(px + ph * 0.16, shoulder - ph * 0.01, px + ph * 0.15, shoulder + ph * 0.03)
      ..lineTo(px + ph * 0.11, hip + ph * 0.02)
      ..lineTo(px - ph * 0.11, hip + ph * 0.02)
      ..close();
    c.drawPath(torso, p(shirt));
    // kollar
    void arm(double sx, double ang, double side) {
      final len = ph * 0.33;
      final end = Offset(sx + side * sin(ang) * len, shoulder + ph * 0.03 + cos(ang) * len);
      c.drawLine(
          Offset(sx, shoulder + ph * 0.04),
          end,
          p(shirt)
            ..strokeWidth = ph * 0.075
            ..strokeCap = StrokeCap.round);
      c.drawCircle(end, ph * 0.04, p(skinC));
      if (mic && side > 0) {
        c.drawLine(end, end + Offset(-ph * 0.03, -ph * 0.08),
            p(const Color(0xFF222222))..strokeWidth = ph * 0.035);
        c.drawCircle(end + Offset(-ph * 0.035, -ph * 0.09), ph * 0.03, p(const Color(0xFF555555)));
      }
    }

    arm(px - ph * 0.13, armL, -1);
    arm(px + ph * 0.13, armR, 1);
    // boyun ve kafa
    c.drawRect(Rect.fromCenter(center: Offset(px, shoulder - ph * 0.03), width: ph * 0.07, height: ph * 0.06), p(skinC));
    final head = Offset(px, fy - ph * 0.9);
    final hr = ph * 0.1;
    if (longHair) {
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(head.dx - hr * 1.15, head.dy - hr, hr * 2.3, hr * 2.6), Radius.circular(hr)),
          p(hairC));
    }
    c.drawCircle(head, hr, p(skinC));
    c.drawArc(Rect.fromCircle(center: head - Offset(0, hr * 0.15), radius: hr * 1.05), pi, pi, true, p(hairC));
    // gözler
    final eye = p(const Color(0xFF1A1A1A));
    if (sunglasses) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: head + Offset(0, hr * 0.15), width: hr * 1.7, height: hr * 0.45), Radius.circular(hr * 0.2)), eye);
    } else {
      c.drawCircle(head + Offset(-hr * 0.35, hr * 0.15), hr * 0.12, eye);
      c.drawCircle(head + Offset(hr * 0.35, hr * 0.15), hr * 0.12, eye);
    }
    if (hat != null) {
      c.drawRect(Rect.fromCenter(center: head - Offset(0, hr * 1.35), width: hr * 1.5, height: hr * 1.3), p(hat));
      c.drawRect(Rect.fromCenter(center: head - Offset(0, hr * 0.75), width: hr * 2.4, height: hr * 0.3), p(hat));
    }
  }

  /// Ön sırada alkışlayan seyirci kafaları
  void audience(double w, {int n = 18, double y = 0.97}) {
    for (int k = 0; k < n; k++) {
      final x = (k + 0.5) / n;
      final clap = sin(w * 10 + k * 0.9) > 0.3 ? 0.02 : 0.0;
      circle(x, y - clap, 0.05, Colors.black.withValues(alpha: 0.8));
      rrect(x - 0.025, y + 0.02 - clap, 0.05, 0.1, 4, Colors.black.withValues(alpha: 0.8));
    }
  }

  /// Altta kayan yazı bandı
  void ticker(String msg, double t, Color bg) {
    rect(0, 0.87, 1, 0.13, bg);
    c.save();
    c.clipRect(Rect.fromLTWH(0, 0.87 * H, W, 0.13 * H));
    final tw = measure(msg, 0.085);
    final off = -((t * 2) % 1) * tw;
    for (double x = off; x < W; x += tw) {
      text(msg, x / W, 0.875, 0.085, Colors.white);
    }
    c.restore();
  }

  void skyline(int seed, double floor, Color col, double w, {bool lit = true}) {
    final rnd = Random(seed);
    double x = 0;
    int i = 0;
    while (x < 1) {
      final bw = 0.06 + rnd.nextDouble() * 0.07;
      final bh = 0.15 + rnd.nextDouble() * 0.35;
      rect(x, floor - bh, bw - 0.004, bh, col);
      if (lit) {
        for (double wy = floor - bh + 0.04; wy < floor - 0.04; wy += 0.07) {
          for (double wx = x + 0.012; wx < x + bw - 0.015; wx += 0.022) {
            i++;
            if (sin(w * 2 + i * 1.7) > 0.2) {
              rect(wx, wy, 0.01, 0.03, AppColors.yellow.withValues(alpha: 0.7));
            }
          }
        }
      }
      x += bw;
    }
  }

  void palm(double x, double floor, double h, double sway) {
    final top = Offset(x * W + sway * 6, (floor - h) * H);
    final path = Path()
      ..moveTo(x * W, floor * H)
      ..quadraticBezierTo(x * W + 6, (floor - h / 2) * H, top.dx, top.dy);
    c.drawPath(path, p(const Color(0xFF7A5230))..style = PaintingStyle.stroke..strokeWidth = 4);
    for (int k = 0; k < 5; k++) {
      final ang = -pi + k * pi / 4 + sway * 0.2;
      final end = top + Offset(cos(ang), sin(ang) + 0.6) * h * H * 0.45;
      c.drawLine(top, end, p(const Color(0xFF2E9E5B))..strokeWidth = 5..strokeCap = StrokeCap.round);
    }
  }

  void firework(double x, double y, double phase, Color col) {
    final r = phase * 0.25;
    final a = (1 - phase).clamp(0.0, 1.0);
    for (int k = 0; k < 12; k++) {
      final ang = k * pi / 6;
      final o = Offset(x * W, y * H);
      c.drawCircle(o + Offset(cos(ang), sin(ang)) * r * H, 2, p(col.withValues(alpha: a)));
    }
  }

  void camera(double x, double feet, double h, double w) {
    final b = Colors.black.withValues(alpha: 0.85);
    line(x, feet, x, feet - h * 0.6, b, 2);
    line(x, feet - h * 0.3, x - h * 0.25, feet, b, 2);
    line(x, feet - h * 0.3, x + h * 0.25, feet, b, 2);
    rrect(x - h * 0.2, feet - h, h * 0.5, h * 0.35, 3, b);
    circle(x + h * 0.32, feet - h * 0.82, h * 0.06, AppColors.red.withValues(alpha: (sin(w * 8) + 1) / 2));
  }
}

class ScenePainter extends CustomPainter {
  final Animation<double> a;
  final Prop prop;
  final Color color;
  final int tier;
  final bool live;
  ScenePainter(this.a, this.prop, this.color, this.tier, this.live)
      : super(repaint: a);

  @override
  void paint(Canvas canvas, Size size) {
    final d = Draw(canvas, size);
    final t = a.value, w = t * 2 * pi;
    final floor = 0.78;

    // Arka plan
    d.vgrad(0, 1, Color.lerp(color, Colors.black, 0.78)!,
        Color.lerp(color, AppColors.bg, 0.45)!);

    _prop(d, t, w, floor);

    final outdoor = _outdoor.contains(prop);
    if (!outdoor && prop != Prop.film) {
      // tavan ışıkları ve spotlar
      d.rect(0, 0, 1, 0.06, Colors.black.withValues(alpha: 0.6));
      final lamps = 3 + min(tier, 4) * 2;
      for (int i = 0; i < lamps; i++) {
        final on = (sin(w * 3 + i * 1.7) + 1) / 2;
        d.circle((i + 0.5) / lamps, 0.045, 0.022,
            Color.lerp(AppColors.yellow, Colors.white, on)!.withValues(alpha: 0.6 + 0.4 * on));
      }
      final spots = 1 + min(tier, 4);
      for (int i = 0; i < spots; i++) {
        final x = (i + 1) / (spots + 1);
        final sw = sin(w + i * 2.1) * 0.18;
        final path = Path()
          ..moveTo((x - 0.01) * size.width, 0.05 * size.height)
          ..lineTo((x + 0.01) * size.width, 0.05 * size.height)
          ..lineTo((x + sw + 0.09) * size.width, (floor + 0.04) * size.height)
          ..lineTo((x + sw - 0.09) * size.width, (floor + 0.04) * size.height)
          ..close();
        canvas.drawPath(
            path,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.22),
                  Colors.white.withValues(alpha: 0.02)
                ],
              ).createShader(Offset.zero & size));
      }
      if (tier >= 1) d.camera(0.07, 0.94, 0.22, w);
      if (tier >= 3) {
        final ang = -pi / 2 - 0.5 + sin(w) * 0.35;
        final pv = Offset(0.93 * size.width, 0.85 * size.height);
        final tip = pv + Offset(cos(ang), sin(ang)) * size.height * 0.6;
        final pp = Paint()
          ..color = Colors.black.withValues(alpha: 0.85)
          ..strokeWidth = 3;
        canvas.drawLine(Offset(pv.dx, size.height), pv, pp);
        canvas.drawLine(pv, tip, pp);
        canvas.drawRect(Rect.fromCenter(center: tip, width: 12, height: 8), pp);
      }
    }

    if (live) {
      final on = sin(w * 8) > -0.2;
      final r = Rect.fromLTWH(size.width - 52, 5, 47, 15);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = Colors.black.withValues(alpha: 0.6));
      canvas.drawCircle(Offset(r.left + 8, r.center.dy), 3.5,
          Paint()..color = on ? AppColors.red : AppColors.red.withValues(alpha: 0.25));
      final tp = TextPainter(
          text: const TextSpan(
              text: 'CANLI',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(r.left + 14, r.top + 1.5));
    }
  }

  void _floor(Draw d, double floor, Color col) {
    d.rect(0, floor, 1, 1 - floor, col);
    for (int i = -4; i <= 4; i++) {
      d.line(0.5 + i * 0.06, floor, 0.5 + i * 0.22, 1, Colors.white.withValues(alpha: 0.06), 1);
    }
  }

  void _prop(Draw d, double t, double w, double floor) {
    final dark = Colors.black.withValues(alpha: 0.45);
    switch (prop) {
      // ---------------- DİZİ ----------------
      case Prop.livingRoom:
        d.vgrad(0, floor, const Color(0xFF8C5A44), const Color(0xFF6B3F31));
        for (double x = 0.02; x < 1; x += 0.08) {
          d.rect(x, 0, 0.02, floor, Colors.white.withValues(alpha: 0.04));
        }
        d.rect(0.1, 0.16, 0.24, 0.32, const Color(0xFF9FD3F5));
        d.rect(0.08 + sin(w) * 0.005, 0.14, 0.06, 0.38, const Color(0xFFB3123A));
        d.rect(0.3 - sin(w) * 0.005, 0.14, 0.06, 0.38, const Color(0xFFB3123A));
        d.rect(0.55, 0.2, 0.14, 0.14, const Color(0xFFE8C07A));
        d.rect(0.565, 0.215, 0.11, 0.11, const Color(0xFF4F7A5A));
        d.line(0.86, floor, 0.86, 0.3, const Color(0xFF333333), 2);
        d.poly([0.82, 0.3, 0.9, 0.3, 0.88, 0.22, 0.84, 0.22], const Color(0xFFFFE6A6));
        d.glow(0.86, 0.3, 0.2, AppColors.yellow.withValues(alpha: 0.3));
        _floor(d, floor, const Color(0xFF4A2E22));
        d.person(0.3, 0.97, 0.5, shirt: AppColors.pink, longHair: true, hair: 2, armR: 0.6 + sin(w * 2) * 0.4);
        d.person(0.55, floor + 0.05, 0.45, shirt: AppColors.blue, skin: 1, legsHidden: true);
        d.rrect(0.42, floor - 0.06, 0.32, 0.16, 8, const Color(0xFF3F6E8C));
        d.rrect(0.42, floor - 0.1, 0.05, 0.2, 6, const Color(0xFF345C75));
        d.rrect(0.69, floor - 0.1, 0.05, 0.2, 6, const Color(0xFF345C75));
      case Prop.neighborhood:
        d.vgrad(0, floor, const Color(0xFF6E8FC4), const Color(0xFFF2B27A));
        final rnd = Random(7);
        double x = 0;
        int i = 0;
        while (x < 1) {
          final bw = 0.1 + rnd.nextDouble() * 0.08;
          final bh = 0.25 + rnd.nextDouble() * 0.28;
          final col = [const Color(0xFFE8B98A), const Color(0xFFD98C6A), const Color(0xFFF2D6A2)][rnd.nextInt(3)];
          d.rect(x, floor - bh, bw - 0.01, bh, col);
          d.poly([x - 0.01, floor - bh, x + bw / 2, floor - bh - 0.1, x + bw, floor - bh], const Color(0xFFA8432F));
          for (double wy = floor - bh + 0.05; wy < floor - 0.06; wy += 0.1) {
            for (double wx = x + 0.015; wx < x + bw - 0.03; wx += 0.035) {
              i++;
              d.rect(wx, wy, 0.018, 0.05, sin(w * 2 + i * 1.3) > 0.3 ? AppColors.yellow : const Color(0xFF5B7DA8));
            }
          }
          x += bw;
        }
        _floor(d, floor, const Color(0xFF5E5A66));
        d.circle(0.15, floor - 0.12, 0.09, const Color(0xFF3E8E57));
        d.line(0.15, floor, 0.15, floor - 0.05, const Color(0xFF6B4A2B), 3);
        d.person(0.4 + sin(w) * 0.05, 0.98, 0.42, shirt: AppColors.pink, longHair: true, hair: 1, walk: w * 6);
        d.person(0.62 - sin(w) * 0.05, 0.98, 0.45, shirt: AppColors.cyan, skin: 2, walk: w * 6 + 1);
      case Prop.sitcom:
        d.vgrad(0, floor, const Color(0xFF5FA88C), const Color(0xFF3E7D66));
        d.rect(0.08, 0.15, 0.13, floor - 0.15, const Color(0xFF8A5A3C));
        d.circle(0.19, 0.47, 0.012, AppColors.yellow);
        d.rect(0.62, 0.15, 0.22, 0.25, const Color(0xFFBFE3F7));
        d.line(0.73, 0.15, 0.73, 0.4, Colors.white, 2);
        _floor(d, floor, const Color(0xFF6B4A3A));
        d.person(0.3, 0.92, 0.45, shirt: AppColors.yellow, armL: 1.2 + sin(w * 3) * 0.5, armR: 0.3);
        d.person(0.5 + sin(w) * 0.05, 0.92, 0.48, shirt: AppColors.accent, skin: 1, hair: 3, walk: w * 5);
        d.person(0.7, 0.92, 0.42, shirt: AppColors.purple, longHair: true, hair: 2, armR: 2.5);
        d.audience(w, n: 16);
        final laugh = sin(w * 4);
        if (laugh > 0.3) d.text('HA HA HA!', 0.5, 0.2, 0.1, AppColors.yellow.withValues(alpha: laugh), center: true);
      case Prop.police:
        d.vgrad(0, floor, const Color(0xFF0B1230), const Color(0xFF1F2B5A));
        d.circle(0.85, 0.15, 0.07, const Color(0xFFF5F0D0));
        d.skyline(5, floor, const Color(0xFF0A0F22), w);
        _floor(d, floor, const Color(0xFF2A2A33));
        d.rect(0, floor + 0.09, 1, 0.012, Colors.white24);
        // polis arabası
        d.rrect(0.52, 0.72, 0.34, 0.12, 6, Colors.white);
        d.rrect(0.58, 0.64, 0.2, 0.1, 6, Colors.white);
        d.rect(0.52, 0.76, 0.34, 0.03, const Color(0xFF1E3A8A));
        final blink = sin(w * 16) > 0;
        d.rect(0.62, 0.61, 0.05, 0.03, blink ? AppColors.red : const Color(0xFF551111));
        d.rect(0.67, 0.61, 0.05, 0.03, blink ? const Color(0xFF112255) : AppColors.blue);
        d.glow(blink ? 0.645 : 0.695, 0.62, 0.35, (blink ? AppColors.red : AppColors.blue).withValues(alpha: 0.35));
        d.circle(0.58, 0.85, 0.045, Colors.black);
        d.circle(0.8, 0.85, 0.045, Colors.black);
        final rx = (t * 1.5 % 1) * 1.2 - 0.1;
        d.person(rx, 0.97, 0.4, shirt: const Color(0xFF333333), hair: 3, walk: w * 30, armL: 0.8, armR: 0.8);
      case Prop.palace:
        d.vgrad(0, floor, const Color(0xFF6B2D4F), const Color(0xFF3A1730));
        for (int k = 0; k < 4; k++) {
          final x = 0.08 + k * 0.24;
          d.rect(x, 0.2, 0.14, floor - 0.2, const Color(0xFF8C4A6B));
          c(d).drawArc(Rect.fromLTWH(x * d.W, 0.12 * d.H, 0.14 * d.W, 0.16 * d.H), pi, pi, true, d.p(const Color(0xFF8C4A6B)));
          d.rect(x + 0.03, 0.3, 0.08, floor - 0.3, const Color(0xFF2A0F20));
          d.rect(x - 0.02, 0.15, 0.025, floor - 0.15, const Color(0xFFE8C07A));
        }
        _floor(d, floor, const Color(0xFF3A2030));
        d.poly([0.44, floor, 0.56, floor, 0.66, 1, 0.34, 1], const Color(0xFFB3123A));
        d.rrect(0.43, 0.42, 0.14, 0.3, 6, const Color(0xFFE8C07A));
        d.person(0.5, floor + 0.02, 0.42, shirt: const Color(0xFF7A1530), hat: Colors.white, armL: 0.5, armR: 0.5, skin: 1);
        d.person(0.25, 0.98, 0.42, shirt: const Color(0xFF1E5A8A), hat: const Color(0xFFB3123A), armR: 0.1);
        d.person(0.75, 0.98, 0.42, shirt: const Color(0xFF1E5A8A), hat: const Color(0xFFB3123A), armL: 0.1);
      case Prop.epic:
        d.vgrad(0, floor, const Color(0xFF2A1B4D), const Color(0xFFE07A4F));
        d.poly([0, floor, 0.15, 0.4, 0.3, floor], const Color(0xFF3A2A4A));
        d.poly([0.7, floor, 0.88, 0.35, 1, floor], const Color(0xFF3A2A4A));
        d.rect(0.3, 0.35, 0.4, floor - 0.35, const Color(0xFF4A3A55));
        for (int k = 0; k < 4; k++) {
          final x = 0.28 + k * 0.13;
          d.rect(x, 0.22, 0.07, floor - 0.22, const Color(0xFF5A4865));
          d.poly([x - 0.01, 0.22, x + 0.035, 0.12, x + 0.08, 0.22], const Color(0xFF7A3040));
          d.line(x + 0.035, 0.12, x + 0.035, 0.04, Colors.white70, 1.5);
          d.poly([x + 0.035, 0.04, x + 0.035 + 0.05 + sin(w * 6 + k) * 0.01, 0.06, x + 0.035, 0.08], AppColors.accent);
        }
        d.rect(0.45, 0.55, 0.1, floor - 0.55, const Color(0xFF1A1020));
        _floor(d, floor, const Color(0xFF3B2E25));
        for (int k = 0; k < 2; k++) {
          final x = 0.38 + k * 0.24;
          final f = sin(w * 14 + k) * 0.01;
          d.poly([x - 0.015, 0.55, x + 0.015, 0.55, x + f, 0.47], AppColors.orange);
          d.glow(x, 0.52, 0.12, AppColors.orange.withValues(alpha: 0.4));
        }
        for (int k = 0; k < 9; k++) {
          d.person(0.08 + k * 0.105, 0.99, 0.28 + (k % 3) * 0.03, shirt: const Color(0xFF6B6B7A), hat: const Color(0xFF8A8A9A), armR: 2.8 + sin(w * 4 + k) * 0.2);
        }

      // ---------------- YARIŞMA ----------------
      case Prop.quiz:
        d.vgrad(0, floor, const Color(0xFF1B2A6B), const Color(0xFF0E1640));
        for (double x = 0; x < 1; x += 0.05) {
          d.line(x, 0.08, x, floor, Colors.white.withValues(alpha: 0.04), 1);
        }
        d.rrect(0.28, 0.1, 0.44, 0.36, 6, const Color(0xFF0A1030));
        final hl = (t * 8).floor() % 4;
        const lbl = ['A', 'B', 'C', 'D'];
        for (int k = 0; k < 4; k++) {
          final x = 0.3 + (k % 2) * 0.21, y = 0.2 + (k ~/ 2) * 0.12;
          d.rrect(x, y, 0.19, 0.09, 8, k == hl ? AppColors.yellow : const Color(0xFF2A3F8F));
          d.text(lbl[k], x + 0.02, y + 0.012, 0.06, k == hl ? Colors.black : Colors.white);
        }
        d.rrect(0.3, 0.115, 0.4, 0.06, 6, const Color(0xFF3D56B8));
        _floor(d, floor, const Color(0xFF141A3A));
        for (int k = 0; k < 2; k++) {
          final x = k == 0 ? 0.18 : 0.82;
          d.person(x, floor + 0.02, 0.36, shirt: k == 0 ? AppColors.pink : AppColors.green, skin: k + 1, longHair: k == 0, legsHidden: true, armR: 0.9);
          d.rrect(x - 0.08, floor - 0.08, 0.16, 0.2, 4, const Color(0xFF2A3F8F));
          d.circle(x, floor - 0.1, 0.03, sin(w * 6 + k * pi) > 0 ? AppColors.red : const Color(0xFF551111));
        }
        d.person(0.5, 0.98, 0.42, shirt: const Color(0xFF222244), armL: 1.0, hair: 4);
      case Prop.couples:
        d.vgrad(0, floor, const Color(0xFFC2547A), const Color(0xFF7A2A4F));
        for (int k = 0; k < 6; k++) {
          final y = (0.7 - ((t + k / 6) % 1) * 0.7);
          final x = 0.1 + k * 0.16;
          d.circle(x - 0.012, y, 0.025, Colors.white.withValues(alpha: 0.2));
          d.circle(x + 0.012, y, 0.025, Colors.white.withValues(alpha: 0.2));
          d.poly([x - 0.03, y + 0.01, x + 0.03, y + 0.01, x, y + 0.06], Colors.white.withValues(alpha: 0.2));
        }
        _floor(d, floor, const Color(0xFF4A1F33));
        for (int k = 0; k < 2; k++) {
          final x = k == 0 ? 0.08 : 0.62;
          d.person(x + 0.07, floor + 0.04, 0.38, shirt: AppColors.blue, skin: k * 2, legsHidden: true, armR: 0.8);
          d.person(x + 0.2, floor + 0.04, 0.36, shirt: AppColors.yellow, longHair: true, hair: k + 1, legsHidden: true, armL: 0.8 + sin(w * 3 + k) * 0.3);
          d.rrect(x, floor - 0.06, 0.28, 0.14, 8, const Color(0xFFE8E0F0));
        }
        d.person(0.5, 0.98, 0.42, shirt: const Color(0xFF2A2440), armR: 1.2 + sin(w * 2) * 0.3, mic: true);
      case Prop.wheel:
        final center = Offset(0.5 * d.W, 0.42 * d.H);
        final r = d.H * 0.3;
        const cols = [AppColors.accent, AppColors.yellow, AppColors.cyan, AppColors.green, AppColors.purple, AppColors.orange, AppColors.pink, AppColors.blue];
        for (int k = 0; k < 8; k++) {
          d.c.drawArc(Rect.fromCircle(center: center, radius: r), w + k * pi / 4, pi / 4, true, d.p(cols[k]));
        }
        d.c.drawCircle(center, r * 0.18, d.p(Colors.white));
        for (int k = 0; k < 16; k++) {
          final ang = k * pi / 8;
          final on = (k + (t * 16).floor()) % 2 == 0;
          d.c.drawCircle(center + Offset(cos(ang), sin(ang)) * (r + 4), 2, d.p(on ? AppColors.yellow : Colors.white24));
        }
        _floor(d, floor, dark);
        for (int k = 0; k < 3; k++) {
          final x = 0.2 + k * 0.3;
          d.rect(x - 0.05, floor - 0.12, 0.1, 0.14, [AppColors.accent, AppColors.cyan, AppColors.yellow][k]);
          d.person(x, floor - 0.12, 0.3, shirt: Colors.white70, skin: k, legsHidden: true, armR: k == 1 ? 2.6 : 0.3);
        }
        d.audience(w);
      case Prop.voice:
        d.vgrad(0, floor, const Color(0xFF250B3D), const Color(0xFF5A1A6B));
        d.glow(0.5, 0.45, 0.6, AppColors.purple.withValues(alpha: 0.5));
        for (int k = 0; k < 5; k++) {
          final y = 0.6 - ((t * 2 + k / 5) % 1) * 0.5;
          d.text('♪', 0.35 + k * 0.07 + sin(w * 3 + k) * 0.02, y, 0.1, Colors.white.withValues(alpha: 0.6));
        }
        _floor(d, floor, const Color(0xFF1A0A25));
        d.person(0.5, floor + 0.04, 0.5, shirt: AppColors.yellow, longHair: true, hair: 2, mic: true, armR: 2.4, armL: 0.6 + sin(w * 2) * 0.3);
        for (int k = 0; k < 4; k++) {
          final x = 0.15 + k * 0.233;
          final turn = cos(w * 1.5 + k * 1.3);
          final cw = 0.16 * turn.abs();
          final front = turn > 0;
          d.rrect(x - cw / 2, 0.72, cw, 0.28, 8, front ? const Color(0xFFD62246) : const Color(0xFF7A1025));
          if (front && cw > 0.08) d.person(x, 1.02, 0.28, shirt: const Color(0xFF222222), skin: k, legsHidden: true, armR: 2.6);
        }
      case Prop.talent:
        d.vgrad(0, floor, const Color(0xFF14143A), const Color(0xFF2A1A5A));
        for (int k = 0; k < 20; k++) {
          final rr = Random(k);
          d.circle(rr.nextDouble(), rr.nextDouble() * 0.6, 0.01, Colors.white.withValues(alpha: (sin(w * 4 + k) + 1) / 2));
        }
        _floor(d, floor, const Color(0xFF221A40));
        d.person(0.5, floor + 0.02, 0.45, shirt: AppColors.green, armL: 2.6 + sin(w * 8) * 0.3, armR: 2.6 - sin(w * 8) * 0.3);
        for (int k = 0; k < 3; k++) {
          final ang = w * 4 + k * 2 * pi / 3;
          d.circle(0.5 + cos(ang) * 0.06, 0.25 + sin(ang) * 0.08, 0.025, [AppColors.red, AppColors.yellow, AppColors.cyan][k]);
        }
        d.rect(0.15, 0.86, 0.7, 0.14, const Color(0xFF0A0A20));
        for (int k = 0; k < 3; k++) {
          final x = 0.3 + k * 0.2;
          d.person(x, 1.05, 0.3, shirt: [AppColors.pink, AppColors.blue, AppColors.orange][k], skin: k, longHair: k == 0, legsHidden: true);
          final buzz = sin(w * 2 + k * 2) > 0.85;
          d.text('X', x - 0.02, 0.62, 0.12, buzz ? AppColors.red : AppColors.red.withValues(alpha: 0.15));
        }
      case Prop.island:
        d.vgrad(0, 0.5, const Color(0xFF5EC4F2), const Color(0xFFBDEBFF));
        d.circle(0.85, 0.15, 0.08, const Color(0xFFFFE08A));
        d.vgrad(0.45, 0.7, const Color(0xFF1F8FBF), const Color(0xFF3FC1D9));
        for (int k = 0; k < 6; k++) {
          final x = ((t * 0.5 + k / 6) % 1);
          d.line(x, 0.55 + (k % 3) * 0.04, x + 0.06, 0.55 + (k % 3) * 0.04, Colors.white70, 1.5);
        }
        d.poly([0, 0.66, 1, 0.62, 1, 1, 0, 1], const Color(0xFFF2D59A));
        d.palm(0.12, 0.85, 0.5, sin(w * 2));
        d.palm(0.9, 0.82, 0.45, sin(w * 2 + 1));
        for (int k = 0; k < 2; k++) {
          final x = k == 0 ? 0.3 : 0.7;
          d.line(x, 0.9, x, 0.45, const Color(0xFF6B4A2B), 2);
          d.poly([x, 0.45, x + 0.08 + sin(w * 8 + k) * 0.01, 0.48, x, 0.52], k == 0 ? AppColors.red : AppColors.blue);
        }
        final run = (t * 2 % 1);
        d.person(0.2 + run * 0.6, 0.97, 0.35, shirt: AppColors.red, skin: 1, walk: w * 30, armL: 0.8, armR: 0.8);
        d.person(0.15 + run * 0.6, 0.98, 0.36, shirt: AppColors.blue, skin: 2, walk: w * 30 + 1, armL: 0.8, armR: 0.8);
        d.poly([0.48, 0.88, 0.52, 0.88, 0.5 + sin(w * 20) * 0.006, 0.8], AppColors.orange);

      // ---------------- HABER ----------------
      case Prop.newsDesk:
        d.vgrad(0, floor, const Color(0xFF1C3A5E), const Color(0xFF0F2038));
        d.rect(0.55, 0.14, 0.38, 0.32, const Color(0xFF2E5A8A));
        d.skyline(9, 0.46, const Color(0xFF1A3352), w);
        _floor(d, floor, dark);
        d.person(0.35, floor + 0.04, 0.48, shirt: const Color(0xFF2A2440), hair: 3, armL: 0.9, armR: 0.9, legsHidden: true);
        d.rrect(0.15, floor - 0.12, 0.42, 0.18, 4, color);
        d.rect(0.3, floor - 0.13, 0.08, 0.02, Colors.white);
      case Prop.globe:
        final center = Offset(0.72 * d.W, 0.38 * d.H);
        final r = d.H * 0.24;
        d.c.drawCircle(center, r, d.p(AppColors.blue.withValues(alpha: 0.35)));
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppColors.cyan.withValues(alpha: 0.7);
        d.c.drawCircle(center, r, stroke);
        for (int k = 0; k < 4; k++) {
          final ph = (w + k * pi / 4) % pi;
          d.c.drawOval(Rect.fromCenter(center: center, width: 2 * r * cos(ph).abs(), height: 2 * r), stroke);
        }
        d.rect(0.08, 0.16, 0.36, 0.34, color.withValues(alpha: 0.35));
        for (int k = 0; k < 3; k++) {
          d.rect(0.1, 0.2 + k * 0.09, 0.15 + 0.12 * ((sin(w + k) + 1) / 2), 0.04, Colors.white.withValues(alpha: 0.5));
        }
        _floor(d, floor, dark);
        d.person(0.5, floor - 0.1, 0.4, shirt: AppColors.blue, legsHidden: true, longHair: true, hair: 1, armL: 0.8, armR: 0.8);
        d.rrect(0.25, floor - 0.14, 0.5, 0.16, 4, color.withValues(alpha: 0.9));
        d.ticker('SON DAKİKA • Reytingler açıklandı • Yarın hava güneşli • Borsa güne yükselişle başladı •  ', t, AppColors.red);
      case Prop.debate:
        d.vgrad(0, floor, const Color(0xFF5A0F1F), const Color(0xFF250610));
        d.text('TARTIŞMA', 0.5, 0.1, 0.13, Colors.white.withValues(alpha: 0.15), center: true);
        _floor(d, floor, dark);
        for (int k = 0; k < 4; k++) {
          final x = 0.15 + k * 0.233;
          final y = floor + 0.02 - (k == 1 || k == 2 ? 0.04 : 0);
          final talk = (t * 4).floor() % 4 == k;
          d.person(x, y, 0.36, shirt: [AppColors.blue, AppColors.orange, AppColors.green, AppColors.purple][k], skin: k, hair: k, longHair: k == 2, legsHidden: true, armR: talk ? 1.6 + sin(w * 12) * 0.5 : 0.4);
          d.rrect(x - 0.08, y - 0.08, 0.16, 0.14, 4, const Color(0xFF8C1C33));
        }
        d.ticker('CANLI TARTIŞMA • Gündemin en sıcak konusu • Telefonla bağlanabilirsiniz •  ', t, const Color(0xFF8C1C33));
      case Prop.field:
        d.vgrad(0, floor, const Color(0xFF7AA6D9), const Color(0xFFCFE3F5));
        d.skyline(4, floor, const Color(0xFF8C9AB0), w, lit: false);
        _floor(d, floor, const Color(0xFF55555F));
        d.rrect(0.5, 0.52, 0.36, 0.3, 4, Colors.white);
        d.rrect(0.84, 0.6, 0.12, 0.22, 4, const Color(0xFFE6E6E6));
        d.rect(0.5, 0.65, 0.36, 0.04, AppColors.accent);
        d.rect(0.86, 0.63, 0.08, 0.08, const Color(0xFF9FD3F5));
        d.circle(0.58, 0.83, 0.05, Colors.black);
        d.circle(0.88, 0.83, 0.05, Colors.black);
        final dishA = sin(w) * 0.3;
        d.line(0.68, 0.52, 0.68, 0.42, Colors.grey, 2);
        d.c.drawArc(Rect.fromCenter(center: Offset(0.68 * d.W, 0.38 * d.H), width: 0.12 * d.W, height: 0.16 * d.H), pi + dishA, pi, false, d.p(Colors.white)..style = PaintingStyle.stroke..strokeWidth = 3);
        d.person(0.25, 0.97, 0.48, shirt: AppColors.accent, longHair: true, hair: 2, mic: true, armR: 1.5);
        d.person(0.08, 0.98, 0.45, shirt: const Color(0xFF333344), skin: 2, armR: 1.2);
        d.rrect(0.1, 0.55, 0.08, 0.06, 2, Colors.black);
      case Prop.election:
        d.vgrad(0, floor, const Color(0xFF0F1F3D), const Color(0xFF050B18));
        const bc = [AppColors.accent, AppColors.blue, AppColors.yellow, AppColors.green];
        for (int k = 0; k < 4; k++) {
          final h = 0.12 + 0.25 * ((sin(w + k * 1.4) + 1) / 2);
          d.rect(0.08 + k * 0.1, 0.55 - h, 0.07, h, bc[k]);
          d.text('%${(h * 100).round()}', 0.08 + k * 0.1, 0.5 - h, 0.06, Colors.white);
        }
        final pc = Offset(0.75 * d.W, 0.3 * d.H);
        double start = w * 0.2;
        for (int k = 0; k < 4; k++) {
          final sweep = [2.2, 1.8, 1.4, 0.88][k];
          d.c.drawArc(Rect.fromCircle(center: pc, radius: d.H * 0.18), start, sweep, true, d.p(bc[k]));
          start += sweep;
        }
        _floor(d, floor, dark);
        d.person(0.5, floor - 0.08, 0.38, shirt: const Color(0xFF2A2440), legsHidden: true, armL: 1.0, hair: 4);
        d.rrect(0.3, floor - 0.12, 0.4, 0.14, 4, AppColors.blue);
        d.ticker('SEÇİM ÖZEL • Sandıkların yüzde 64\'ü açıldı • Sonuçlar canlı yayında •  ', t, const Color(0xFF1E3A8A));

      // ---------------- MAGAZİN ----------------
      case Prop.gossip:
        d.vgrad(0, floor, const Color(0xFFB0397A), const Color(0xFF5A1A45));
        d.rrect(0.32, 0.12, 0.36, 0.3, 6, const Color(0xFF2A0F25));
        final on = sin(w * 6) > 0;
        d.text('FLAŞ!', 0.5, 0.18, 0.13, on ? AppColors.yellow : Colors.white, center: true);
        _floor(d, floor, const Color(0xFF3A1030));
        d.person(0.32, floor + 0.04, 0.46, shirt: AppColors.yellow, longHair: true, hair: 2, legsHidden: true, armR: 1.4 + sin(w * 5) * 0.4);
        d.person(0.68, floor + 0.04, 0.46, shirt: AppColors.cyan, skin: 1, hair: 0, legsHidden: true, armL: 1.0);
        d.rrect(0.22, floor - 0.06, 0.56, 0.14, 6, const Color(0xFFE8E0F0));
      case Prop.redCarpet:
        d.rect(0, 0.1, 1, floor - 0.1, AppColors.purple.withValues(alpha: 0.15));
        final seg = (t * 24).floor();
        for (int k = 0; k < 3; k++) {
          final rr = Random(seg * 31 + k);
          final life = (t * 24) - seg;
          d.circle(rr.nextDouble(), 0.15 + rr.nextDouble() * 0.5, 0.04 + 0.1 * life, Colors.white.withValues(alpha: 0.6 * (1 - life)));
        }
        _floor(d, floor, dark);
        d.poly([0.42, floor, 0.58, floor, 0.75, 1, 0.25, 1], const Color(0xFFB3123A));
        d.person(0.3 + 0.4 * ((sin(w) + 1) / 2), 0.98, 0.5, shirt: AppColors.yellow, longHair: true, hair: 2, sunglasses: true, walk: w * 10, armR: 1.2);
        d.line(0.1, floor, 0.1, 0.6, AppColors.yellow, 2);
        d.line(0.9, floor, 0.9, 0.6, AppColors.yellow, 2);
      case Prop.paparazzi:
        d.vgrad(0, floor, const Color(0xFF101528), const Color(0xFF242A45));
        d.skyline(12, floor, const Color(0xFF0B0F20), w);
        _floor(d, floor, const Color(0xFF2A2A33));
        final cx = 0.3 + 0.4 * ((sin(w) + 1) / 2);
        d.person(cx, 0.97, 0.5, shirt: const Color(0xFF111111), sunglasses: true, longHair: true, hair: 3, walk: w * 10, armL: 0.2);
        for (int k = 0; k < 3; k++) {
          final x = [0.1, 0.85, 0.65][k];
          d.person(x, 0.99, 0.4, shirt: [AppColors.blue, AppColors.green, AppColors.orange][k], skin: k, armR: 1.6, armL: 1.6);
          d.rect(x - 0.03, 0.62, 0.06, 0.05, Colors.black);
          final flash = sin(w * 9 + k * 2.1) > 0.9;
          if (flash) d.glow(x, 0.64, 0.25, Colors.white.withValues(alpha: 0.9));
        }
      case Prop.awards:
        d.vgrad(0, floor, const Color(0xFF3A2A0A), const Color(0xFF1A1205));
        for (double x = 0; x < 1; x += 0.04) {
          d.rect(x, 0, 0.02, floor, const Color(0xFFB08A2A).withValues(alpha: 0.35));
        }
        _floor(d, floor, const Color(0xFF221805));
        d.glow(0.5, 0.4, 0.45, AppColors.yellow.withValues(alpha: 0.4 + 0.2 * sin(w * 3)));
        d.rect(0.46, 0.62, 0.08, 0.14, const Color(0xFF8A6A1A));
        d.circle(0.5, 0.27, 0.07, const Color(0xFFFFD166));
        d.poly([0.46, 0.33, 0.54, 0.33, 0.52, 0.62, 0.48, 0.62], const Color(0xFFFFD166));
        d.person(0.22, floor + 0.04, 0.42, shirt: const Color(0xFF111111), mic: true, armR: 1.5, legsHidden: true);
        d.rrect(0.12, floor - 0.1, 0.2, 0.16, 4, const Color(0xFF6B4F10));
        d.audience(w);

      // ---------------- TALK SHOW ----------------
      case Prop.morning:
        d.vgrad(0, floor, const Color(0xFFF5E3C4), const Color(0xFFE8C99A));
        d.rect(0.62, 0.14, 0.28, 0.28, const Color(0xFFBFE7FF));
        d.circle(0.82, 0.22, 0.05, const Color(0xFFFFD166));
        for (int k = 0; k < 4; k++) {
          d.rrect(0.05 + k * 0.13, 0.08, 0.12, 0.16, 3, const Color(0xFF7FB3A0));
        }
        _floor(d, floor, const Color(0xFFB08A6A));
        d.person(0.35, floor, 0.45, shirt: AppColors.orange, longHair: true, hair: 2, legsHidden: true, armR: 1.0 + sin(w * 3) * 0.3);
        d.person(0.62, floor, 0.45, shirt: AppColors.blue, skin: 1, legsHidden: true, armL: 1.2);
        d.rect(0.15, floor - 0.12, 0.7, 0.24, const Color(0xFFEDEDED));
        d.rect(0.15, floor - 0.13, 0.7, 0.03, const Color(0xFF7A5A3A));
        for (int k = 0; k < 2; k++) {
          final x = k == 0 ? 0.4 : 0.56;
          d.rrect(x, floor - 0.2, 0.04, 0.07, 2, Colors.white);
          for (int s = 0; s < 2; s++) {
            final y = floor - 0.24 - ((t * 2 + s * 0.5) % 1) * 0.12;
            d.line(x + 0.01 + s * 0.02, y, x + 0.01 + s * 0.02 + sin(w * 6 + s) * 0.01, y - 0.04, Colors.white70, 1.2);
          }
        }
      case Prop.nightShow:
        d.circle(0.78, 0.28, 0.1, const Color(0xFFFFF4C8));
        d.skyline(3, floor, Colors.black.withValues(alpha: 0.5), w);
        for (int k = 0; k < 14; k++) {
          final rr = Random(k);
          final tw = (sin(w * 4 + k) + 1) / 2;
          d.circle(rr.nextDouble(), rr.nextDouble() * 0.4, 0.008 + tw * 0.008, Colors.white.withValues(alpha: 0.3 + 0.5 * tw));
        }
        _floor(d, floor, dark);
        d.person(0.3, floor + 0.04, 0.42, shirt: AppColors.pink, longHair: true, hair: 1, legsHidden: true, armR: 0.8 + sin(w * 2) * 0.4);
        d.rrect(0.15, floor - 0.08, 0.3, 0.12, 6, AppColors.purple);
        d.person(0.69, floor - 0.08, 0.38, shirt: const Color(0xFF222244), legsHidden: true, hair: 3, armL: 1.0);
        d.rect(0.58, floor - 0.13, 0.22, 0.15, color.withValues(alpha: 0.9));
        d.audience(w);
      case Prop.standup:
        d.rect(0, 0, 1, floor, const Color(0xFF7A3A2A));
        for (double y = 0; y < floor; y += 0.07) {
          final off = ((y / 0.07).round() % 2) * 0.04;
          for (double x = -off; x < 1; x += 0.08) {
            d.rect(x + 0.003, y + 0.005, 0.074, 0.06, const Color(0xFF8C4632));
          }
        }
        d.glow(0.5, 0.45, 0.5, Colors.white.withValues(alpha: 0.35));
        _floor(d, floor, const Color(0xFF2A1510));
        d.line(0.43, floor + 0.04, 0.43, 0.45, const Color(0xFF333333), 2);
        d.person(0.5, floor + 0.05, 0.52, shirt: const Color(0xFF223355), hair: 1, mic: true, armR: 2.2, armL: 0.8 + sin(w * 4) * 0.6);
        final laugh = sin(w * 3);
        if (laugh > 0.2) d.text('HAHAHA', 0.75, 0.2, 0.09, AppColors.yellow.withValues(alpha: laugh), center: true);
        d.audience(w);
      case Prop.sketch:
        d.vgrad(0, floor, const Color(0xFF87C6E8), const Color(0xFFE8F4FA));
        d.rect(0.35, 0.3, 0.3, floor - 0.3, const Color(0xFFF2D6A2));
        d.poly([0.32, 0.3, 0.5, 0.15, 0.68, 0.3], const Color(0xFFA8432F));
        d.rect(0.46, 0.5, 0.08, floor - 0.5, const Color(0xFF7A5230));
        _floor(d, floor, const Color(0xFF6B4A3A));
        d.person(0.3, 0.97 - (sin(w * 6).abs()) * 0.05, 0.45, shirt: AppColors.green, hat: const Color(0xFF222222), armL: 2.5, armR: 2.5);
        d.person(0.7, 0.97, 0.45, shirt: AppColors.orange, skin: 2, hat: AppColors.red, armR: 1.4 + sin(w * 6) * 0.3);
        d.rect(0, 0, 0.12, 1, const Color(0xFF8C1530));
        d.rect(0.88, 0, 0.12, 1, const Color(0xFF8C1530));
        d.audience(w, n: 14);
      case Prop.newYear:
        d.vgrad(0, floor, const Color(0xFF060A20), const Color(0xFF1A1050));
        for (int k = 0; k < 4; k++) {
          final ph = (t * 2 + k / 4) % 1;
          final rr = Random((t * 2 + k / 4).floor() * 7 + k);
          d.firework(0.15 + rr.nextDouble() * 0.7, 0.15 + rr.nextDouble() * 0.3, ph, [AppColors.yellow, AppColors.accent, AppColors.cyan, AppColors.green][k]);
        }
        d.rrect(0.25, 0.48, 0.5, 0.12, 6, AppColors.accent);
        d.text('MUTLU YILLAR', 0.5, 0.5, 0.08, Colors.white, center: true);
        _floor(d, floor, dark);
        d.audience(w, n: 20);

      // ---------------- BELGESEL ----------------
      case Prop.nature:
        d.vgrad(0, floor, const Color(0xFF3B6FB6), const Color(0xFFF2B27A));
        d.circle(0.75, 0.28 + sin(w) * 0.02, 0.11, const Color(0xFFFFE08A));
        for (int layer = 0; layer < 3; layer++) {
          final rnd = Random(layer + 11);
          final pts = <double>[0, floor];
          for (double x = 0; x <= 1.001; x += 1 / 6) {
            pts..add(x)..add(floor - (0.32 - 0.09 * layer + rnd.nextDouble() * 0.12));
          }
          pts..add(1)..add(floor);
          d.poly(pts, Color.lerp(const Color(0xFF4FA36B), const Color(0xFF173A2A), layer / 2)!);
        }
        _floor(d, floor, const Color(0xFF2E6B3A));
        final bx = (t * 1.3 % 1) * 1.1 - 0.05;
        final flap = sin(w * 20) * 0.03;
        d.line(bx - 0.03, 0.25 - flap, bx, 0.25, Colors.black87, 2);
        d.line(bx, 0.25, bx + 0.03, 0.25 - flap, Colors.black87, 2);
        d.oval(0.3, 0.88, 0.14, 0.1, const Color(0xFF8A5A3A));
        d.circle(0.37, 0.83, 0.04, const Color(0xFF8A5A3A));
      case Prop.ocean:
        d.vgrad(0, 1, const Color(0xFF1C8CB0), const Color(0xFF062A45));
        for (int k = 0; k < 4; k++) {
          d.poly([0.1 + k * 0.25, 0, 0.16 + k * 0.25, 0, 0.3 + k * 0.25, 0.8, 0.2 + k * 0.25, 0.8], Colors.white.withValues(alpha: 0.05));
        }
        d.rect(0, 0.85, 1, 0.15, const Color(0xFFD9C08A));
        for (int k = 0; k < 6; k++) {
          final x = 0.05 + k * 0.18;
          final sw = sin(w * 2 + k) * 0.02;
          d.line(x, 0.88, x + sw, 0.65, const Color(0xFF2E9E5B), 3);
        }
        d.circle(0.7, 0.86, 0.06, const Color(0xFFFF7E8A));
        for (int k = 0; k < 4; k++) {
          final sp = 0.6 + k * 0.25;
          final x = ((t * sp + k * 0.3) % 1.2) - 0.1;
          final y = 0.25 + k * 0.13 + sin(w * 3 + k) * 0.02;
          final col = [AppColors.orange, AppColors.yellow, AppColors.pink, AppColors.cyan][k];
          d.oval(x, y, 0.1, 0.09, col);
          d.poly([x - 0.05, y, x - 0.09, y - 0.04, x - 0.09, y + 0.04], col);
          d.circle(x + 0.025, y - 0.01, 0.01, Colors.black);
        }
        for (int k = 0; k < 6; k++) {
          final y = 0.85 - ((t * 1.5 + k / 6) % 1) * 0.85;
          d.circle(0.15 + k * 0.15 + sin(w * 4 + k) * 0.01, y, 0.012, Colors.white.withValues(alpha: 0.5));
        }
      case Prop.history:
        d.vgrad(0, floor, const Color(0xFFF2A65A), const Color(0xFFFFE0A6));
        d.circle(0.2, 0.25, 0.09, const Color(0xFFFFF4C8));
        d.poly([0.45, floor, 0.65, 0.3, 0.85, floor], const Color(0xFFD9A55A));
        d.poly([0.65, 0.3, 0.85, floor, 0.75, floor], const Color(0xFFB8843F));
        d.poly([0.75, floor, 0.88, 0.48, 1.01, floor], const Color(0xFFC99A50));
        _floor(d, floor, const Color(0xFFE0B870));
        for (int k = 0; k < 4; k++) {
          final x = 0.06 + k * 0.08;
          final h = [0.35, 0.25, 0.38, 0.15][k];
          d.rect(x, floor - h, 0.04, h, const Color(0xFFEDE0C8));
        }
        d.rect(0.05, floor - 0.4, 0.2, 0.04, const Color(0xFFEDE0C8));
        d.person(0.45, 0.98, 0.42, shirt: const Color(0xFFB08A5A), hat: const Color(0xFF8A6A3A), armR: 1.5, skin: 1);
      case Prop.space:
        d.vgrad(0, 1, const Color(0xFF02030A), const Color(0xFF15103A));
        for (int k = 0; k < 30; k++) {
          final rr = Random(k);
          d.circle(rr.nextDouble(), rr.nextDouble(), 0.006 + ((sin(w * 3 + k) + 1) / 2) * 0.006, Colors.white70);
        }
        d.circle(0.25, 0.55, 0.22, const Color(0xFFE07A4F));
        d.oval(0.25, 0.55, 0.6, 0.08, const Color(0xFFF2C08A).withValues(alpha: 0.7));
        d.circle(0.82, 0.25, 0.06, const Color(0xFFCCCCDD));
        final rx = (t * 0.8 % 1) * 1.2 - 0.1, ry = 0.8 - (t * 0.8 % 1) * 0.6;
        d.poly([rx, ry - 0.08, rx + 0.03, ry, rx - 0.03, ry], Colors.white);
        d.poly([rx - 0.02, ry, rx + 0.02, ry, rx + sin(w * 30) * 0.005, ry + 0.07], AppColors.orange);
        d.person(0.65, 0.75 + sin(w * 2) * 0.03, 0.3, shirt: Colors.white, pants: Colors.white, armL: 1.6, armR: 1.6, hat: null);

      // ---------------- SPOR ----------------
      case Prop.sportsDesk:
        d.vgrad(0, floor, const Color(0xFF0F3A2A), const Color(0xFF06201A));
        d.rrect(0.3, 0.1, 0.4, 0.3, 6, const Color(0xFF0A0A0A));
        d.text('${(t * 3).floor() % 3 + 1} - 1', 0.5, 0.15, 0.17, AppColors.yellow, center: true);
        _floor(d, floor, dark);
        d.person(0.35, floor - 0.06, 0.4, shirt: AppColors.green, legsHidden: true, armR: 1.2 + sin(w * 3) * 0.3);
        d.person(0.65, floor - 0.06, 0.4, shirt: const Color(0xFF222222), skin: 2, legsHidden: true, longHair: true, hair: 1);
        d.rrect(0.2, floor - 0.1, 0.6, 0.14, 4, const Color(0xFF1F6B4A));
        d.ticker('SKORLAR • Kartallar 2-1 Şimşekler • Martılar 0-0 Kartallar • Yıldızlar 3-2 Boğalar •  ', t, const Color(0xFF1F6B4A));
      case Prop.football:
      case Prop.derby:
      case Prop.tournament:
        final night = prop == Prop.derby;
        d.vgrad(0, 0.45, night ? const Color(0xFF060A1A) : const Color(0xFF5EA8E0), night ? const Color(0xFF1A1030) : const Color(0xFFA8D8F5));
        d.rect(0, 0.1, 1, 0.35, Colors.black.withValues(alpha: 0.45));
        for (int k = 0; k < 70; k++) {
          final rr = Random(k);
          final jump = sin(w * 6 + k) > 0.6 ? 0.01 : 0.0;
          d.circle(rr.nextDouble(), 0.15 + rr.nextDouble() * 0.27 - jump, 0.012, [AppColors.accent, AppColors.yellow, Colors.white, AppColors.cyan][k % 4].withValues(alpha: 0.85));
        }
        if (night) {
          for (int k = 0; k < 5; k++) {
            final x = 0.1 + k * 0.2;
            d.glow(x, 0.3, 0.12 + sin(w * 12 + k) * 0.02, AppColors.red.withValues(alpha: 0.7));
          }
          d.firework(0.3, 0.12, (t * 2) % 1, AppColors.yellow);
          d.firework(0.75, 0.1, (t * 2 + 0.5) % 1, AppColors.accent);
        }
        if (prop == Prop.tournament) {
          const fc = [AppColors.red, AppColors.blue, AppColors.yellow, AppColors.green, Colors.white, AppColors.orange];
          for (int k = 0; k < 6; k++) {
            final x = 0.05 + k * 0.17;
            d.line(x, 0.42, x, 0.1, Colors.white70, 1.5);
            d.poly([x, 0.1, x + 0.08 + sin(w * 6 + k) * 0.01, 0.13, x, 0.16], fc[k]);
          }
        }
        d.rect(0, 0.45, 1, 0.55, const Color(0xFF2E8B57));
        for (int k = 0; k < 6; k++) {
          d.rect(k / 6, 0.45, 1 / 12, 0.55, Colors.white.withValues(alpha: 0.04));
        }
        d.line(0.5, 0.45, 0.5, 1, Colors.white70, 1.2);
        d.c.drawCircle(Offset(0.5 * d.W, 0.72 * d.H), d.H * 0.12, d.p(Colors.white70)..style = PaintingStyle.stroke..strokeWidth = 1.2);
        final bx = 0.2 + 0.6 * ((sin(w * 2) + 1) / 2);
        d.person(bx - 0.05, 0.85, 0.22, shirt: AppColors.red, walk: w * 20);
        d.person(1 - bx + 0.02, 0.8, 0.22, shirt: AppColors.blue, walk: w * 20 + 1, skin: 2);
        d.circle(bx, 0.84 - (sin(w * 4).abs()) * 0.15, 0.02, Colors.white);
        if (prop == Prop.tournament) {
          d.glow(0.85, 0.72, 0.2, AppColors.yellow.withValues(alpha: 0.5));
          d.circle(0.85, 0.65, 0.04, const Color(0xFFFFD166));
          d.poly([0.82, 0.68, 0.88, 0.68, 0.865, 0.8, 0.835, 0.8], const Color(0xFFFFD166));
          d.rect(0.81, 0.8, 0.08, 0.04, const Color(0xFF8A6A1A));
        }
      case Prop.basketball:
        d.vgrad(0, 0.45, const Color(0xFF1A1030), const Color(0xFF2A1A45));
        for (int k = 0; k < 60; k++) {
          final rr = Random(k + 3);
          d.circle(rr.nextDouble(), 0.12 + rr.nextDouble() * 0.3, 0.012, [AppColors.orange, Colors.white, AppColors.purple][k % 3].withValues(alpha: 0.8));
        }
        d.rect(0, 0.45, 1, 0.55, const Color(0xFFC98A4A));
        for (double y = 0.5; y < 1; y += 0.06) {
          d.line(0, y, 1, y, const Color(0xFFB07A3A), 1);
        }
        d.c.drawArc(Rect.fromCenter(center: Offset(0.85 * d.W, 0.72 * d.H), width: 0.5 * d.W, height: 0.5 * d.H), pi / 2, pi, false, d.p(Colors.white70)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        d.rect(0.88, 0.2, 0.02, 0.6, const Color(0xFF444444));
        d.rect(0.82, 0.2, 0.08, 0.14, Colors.white);
        d.rect(0.78, 0.33, 0.05, 0.015, AppColors.red);
        final ph = (t * 2) % 1;
        final bx = 0.35 + ph * 0.45, by = 0.55 - sin(ph * pi) * 0.35;
        d.person(0.35, 0.95 - sin(ph * pi) * 0.05, 0.4, shirt: AppColors.purple, skin: 3, armR: 2.8, armL: 2.6);
        d.circle(bx, by, 0.035, AppColors.orange);

      // ---------------- ÇOCUK ----------------
      case Prop.cartoon:
        d.vgrad(0, floor, const Color(0xFFFFE6A6), const Color(0xFFFFC8A0));
        d.rrect(0.2, 0.08, 0.6, 0.55, 14, const Color(0xFF333344));
        d.rrect(0.24, 0.12, 0.52, 0.47, 8, const Color(0xFF8FE3FF));
        d.rect(0.24, 0.47, 0.52, 0.12, const Color(0xFF7ED957));
        d.circle(0.68, 0.2, 0.05, const Color(0xFFFFD166));
        final jy = 0.4 - (sin(w * 4).abs()) * 0.12;
        d.circle(0.45, jy, 0.09, AppColors.pink);
        final blink = sin(w * 5) > 0.95;
        d.circle(0.42, jy - 0.02, 0.025, Colors.white);
        d.circle(0.48, jy - 0.02, 0.025, Colors.white);
        if (!blink) {
          d.circle(0.42, jy - 0.02, 0.012, Colors.black);
          d.circle(0.48, jy - 0.02, 0.012, Colors.black);
        }
        _floor(d, floor, const Color(0xFFC98A6A));
        d.person(0.35, 1.0, 0.3, shirt: AppColors.green, legsHidden: true, longHair: true, hair: 2);
        d.person(0.5, 1.0, 0.28, shirt: AppColors.yellow, legsHidden: true, skin: 2);
        d.person(0.65, 1.0, 0.3, shirt: AppColors.blue, legsHidden: true, skin: 1);
        d.rrect(0.25, 0.9, 0.5, 0.1, 6, AppColors.purple);
      case Prop.puppet:
        d.vgrad(0, floor, const Color(0xFF6BC4A6), const Color(0xFF3E8E7A));
        d.rect(0.25, 0.15, 0.5, floor - 0.15, const Color(0xFF8C1530));
        for (int k = 0; k < 6; k++) {
          d.rect(0.25 + k * 0.0833, 0.08, 0.0833, 0.08, k.isEven ? AppColors.yellow : AppColors.red);
        }
        d.rect(0.3, 0.2, 0.4, 0.3, const Color(0xFF1A2A4A));
        for (int k = 0; k < 2; k++) {
          final x = 0.42 + k * 0.16;
          final y = 0.38 + sin(w * 4 + k * 2) * 0.04;
          d.rrect(x - 0.04, y, 0.08, 0.14, 6, k == 0 ? AppColors.orange : AppColors.cyan);
          d.circle(x, y - 0.02, 0.06, k == 0 ? const Color(0xFFF2C9A0) : const Color(0xFFB0E0A0));
          d.circle(x - 0.015, y - 0.03, 0.012, Colors.black);
          d.circle(x + 0.015, y - 0.03, 0.012, Colors.black);
          d.oval(x, y - 0.0, 0.03, 0.02, AppColors.red);
        }
        _floor(d, floor, const Color(0xFF2A5A4A));
        d.audience(w, n: 12);
      case Prop.lab:
        d.vgrad(0, floor, const Color(0xFFE8F4FA), const Color(0xFFC8E0EA));
        for (int k = 0; k < 18; k++) {
          d.rrect(0.05 + (k % 9) * 0.1, 0.08 + (k ~/ 9) * 0.1, 0.08, 0.08, 3, [AppColors.cyan, AppColors.yellow, AppColors.pink, AppColors.green][k % 4].withValues(alpha: 0.35));
        }
        _floor(d, floor, const Color(0xFF8AA0AA));
        d.person(0.25, floor + 0.02, 0.48, shirt: Colors.white, hair: 4, legsHidden: true, armR: 1.2);
        d.person(0.75, floor + 0.04, 0.34, shirt: AppColors.orange, legsHidden: true, longHair: true, hair: 1, armL: 2.6 + sin(w * 6) * 0.3);
        d.rect(0.1, floor - 0.04, 0.8, 0.26, const Color(0xFF5A6A7A));
        for (int k = 0; k < 3; k++) {
          final x = 0.38 + k * 0.1;
          final col = [AppColors.green, AppColors.pink, AppColors.cyan][k];
          d.poly([x - 0.04, floor - 0.04, x + 0.04, floor - 0.04, x + 0.012, floor - 0.16, x - 0.012, floor - 0.16], col.withValues(alpha: 0.8));
          for (int b = 0; b < 3; b++) {
            final y = floor - 0.17 - ((t * 3 + b / 3 + k * 0.2) % 1) * 0.2;
            d.circle(x + sin(w * 5 + b) * 0.01, y, 0.015, col.withValues(alpha: 0.6));
          }
        }
      case Prop.kidsStage:
        const rb = [AppColors.red, AppColors.orange, AppColors.yellow, AppColors.green, AppColors.blue, AppColors.purple];
        for (int k = 0; k < rb.length; k++) {
          d.c.drawArc(Rect.fromCenter(center: Offset(0.5 * d.W, floor * d.H), width: 0.8 * d.W - k * 8, height: 1.1 * d.H - k * 8), pi, pi, false,
              d.p(rb[k].withValues(alpha: 0.7))..style = PaintingStyle.stroke..strokeWidth = 4);
        }
        for (int k = 0; k < 5; k++) {
          final x = 0.12 + k * 0.19;
          final y = 0.35 + sin(w * 2 + k) * 0.04;
          d.line(x, y + 0.06, x + sin(w + k) * 0.01, floor, Colors.white38, 1);
          d.oval(x, y, 0.06, 0.15, rb[k]);
        }
        _floor(d, floor, dark);
        d.person(0.5, 0.98 - (sin(w * 4).abs()) * 0.04, 0.38, shirt: AppColors.yellow, longHair: true, hair: 2, mic: true, armR: 2.2, armL: 1.5 + sin(w * 4) * 0.4);
        d.audience(w, n: 14);

      // ---------------- SİNEMA / STÜDYO ----------------
      case Prop.film:
        final screen = Rect.fromLTWH(0.15 * d.W, 0.12 * d.H, 0.7 * d.W, 0.5 * d.H);
        d.c.drawRect(screen, Paint()..shader = LinearGradient(colors: [color.withValues(alpha: 0.9), Color.lerp(color, Colors.white, 0.3 + 0.2 * sin(w * 2))!]).createShader(screen));
        d.poly([0.5, 0.98, 0.15, 0.62, 0.85, 0.62], Colors.white.withValues(alpha: 0.07 + 0.04 * sin(w * 6)));
        d.rect(0, 0, 0.15, floor, const Color(0xFF7A1530));
        d.rect(0.85, 0, 0.15, floor, const Color(0xFF7A1530));
        for (int row = 0; row < 2; row++) {
          for (double x = 0.05; x < 1; x += 0.07) {
            d.rrect(x, 0.8 + row * 0.1, 0.05, 0.08, 3, const Color(0xFF5A1024));
          }
        }
        final rc = Offset(0.92 * d.W, 0.2 * d.H);
        d.c.drawCircle(rc, d.H * 0.1, d.p(Colors.white24));
        for (int k = 0; k < 5; k++) {
          final ang = w * 2 + k * 2 * pi / 5;
          d.c.drawCircle(rc + Offset(cos(ang), sin(ang)) * d.H * 0.055, d.H * 0.022, d.p(Colors.black54));
        }
        final spots = 1 + min(tier, 2);
        for (int i = 0; i < spots; i++) {
          d.circle((i + 1) / (spots + 1), 0.04, 0.02, AppColors.yellow);
        }
      case Prop.studio:
        d.rect(0.25, 0.3, 0.5, floor - 0.3, Colors.black.withValues(alpha: 0.5));
        for (double y = 0.34; y < floor - 0.04; y += 0.08) {
          for (double x = 0.27; x < 0.72; x += 0.05) {
            d.rect(x, y, 0.025, 0.04, sin(w * 2 + x * 30 + y * 10) > 0 ? AppColors.cyan.withValues(alpha: 0.7) : Colors.white10);
          }
        }
        d.line(0.5, 0.3, 0.5, 0.1, Colors.white70, 2);
        for (int k = 0; k < 3; k++) {
          final rr = ((t * 3 + k / 3) % 1) * 0.25;
          d.c.drawCircle(Offset(0.5 * d.W, 0.1 * d.H), rr * d.H, d.p(AppColors.accent.withValues(alpha: 1 - rr / 0.25))..style = PaintingStyle.stroke);
        }
        _floor(d, floor, dark);
    }
  }

  Canvas c(Draw d) => d.c;

  @override
  bool shouldRepaint(covariant ScenePainter old) =>
      old.prop != prop || old.color != color || old.tier != tier || old.live != live;
}
