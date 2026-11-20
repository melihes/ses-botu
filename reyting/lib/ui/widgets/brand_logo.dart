import 'dart:math';

import 'package:flutter/material.dart';

/// Oyun logosu: assets/brand/logo.png varsa onu, yoksa kodla çizilmiş logoyu gösterir.
class BrandLogo extends StatelessWidget {
  final double size;
  final bool showTitle;
  const BrandLogo({super.key, this.size = 160, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Image.asset(
        'assets/brand/logo.png',
        width: size,
        height: size,
        errorBuilder: (_, _, _) => SizedBox(
          width: size,
          height: size,
          child: const CustomPaint(painter: CrestPainter()),
        ),
      ),
      if (showTitle) ...[
        SizedBox(height: size * 0.04),
        ShaderMask(
          shaderCallback: (r) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1B8), Color(0xFFE8B04A), Color(0xFFB07A22)],
          ).createShader(r),
          child: Text('REYTİNG',
              style: TextStyle(
                  fontSize: size * 0.3,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: size * 0.02,
                  color: Colors.white,
                  shadows: const [Shadow(color: Color(0x88FFC857), blurRadius: 18)])),
        ),
        SizedBox(height: size * 0.03),
        Text('TV Kanalı İmparatorluğu',
            style: TextStyle(
                fontSize: size * 0.1,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFEDE6FF))),
      ],
    ]);
  }
}

/// Kalkan + yıldız + yükselen ok amblemi
class CrestPainter extends CustomPainter {
  const CrestPainter();

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    Offset p(double x, double y) => Offset(x * w, y * h);

    // ışık halesi
    c.drawCircle(
        p(0.5, 0.5),
        w * 0.5,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x667B5CFF), Color(0x007B5CFF)])
              .createShader(Rect.fromCircle(center: p(0.5, 0.5), radius: w * 0.5)));

    // kalkan
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.12)
      ..quadraticBezierTo(w * 0.7, h * 0.2, w * 0.86, h * 0.2)
      ..quadraticBezierTo(w * 0.88, h * 0.62, w * 0.5, h * 0.92)
      ..quadraticBezierTo(w * 0.12, h * 0.62, w * 0.14, h * 0.2)
      ..quadraticBezierTo(w * 0.3, h * 0.2, w * 0.5, h * 0.12)
      ..close();
    c.drawPath(
        shield,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3B2A8C), Color(0xFF1A1250)],
          ).createShader(Offset.zero & s));
    c.drawPath(
        shield,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.045
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF1B8), Color(0xFFE8B04A), Color(0xFF9C6A1C)],
          ).createShader(Offset.zero & s));

    // yükselen ok (grafik çizgisi)
    final arrow = Path()
      ..moveTo(w * 0.22, h * 0.7)
      ..lineTo(w * 0.42, h * 0.5)
      ..lineTo(w * 0.52, h * 0.6)
      ..lineTo(w * 0.78, h * 0.3);
    final gold = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF7DA), Color(0xFFF2C25A)],
      ).createShader(Offset.zero & s);
    c.drawPath(arrow, gold);
    final head = Path()
      ..moveTo(w * 0.88, h * 0.18)
      ..lineTo(w * 0.86, h * 0.36)
      ..lineTo(w * 0.7, h * 0.22)
      ..close();
    c.drawPath(head, Paint()..color = const Color(0xFFFFE9A8));

    // yıldız
    final star = Path();
    const n = 5;
    for (int i = 0; i < n * 2; i++) {
      final r = i.isEven ? w * 0.13 : w * 0.055;
      final a = -pi / 2 + i * pi / n;
      final pt = p(0.46, 0.27) + Offset(cos(a), sin(a)) * r;
      i == 0 ? star.moveTo(pt.dx, pt.dy) : star.lineTo(pt.dx, pt.dy);
    }
    star.close();
    c.drawPath(
        star,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFFFFF7DA), Color(0xFFE8A93A)])
              .createShader(Rect.fromCircle(center: p(0.46, 0.27), radius: w * 0.13)));

    // parıltılar
    final spark = Paint()..color = const Color(0xFFFFF4C8);
    for (final o in [p(0.86, 0.16), p(0.2, 0.32), p(0.75, 0.48)]) {
      c.drawCircle(o, w * 0.012, spark);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
