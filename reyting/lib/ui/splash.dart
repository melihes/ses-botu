import 'dart:math';

import 'package:flutter/material.dart';

import 'widgets/brand_logo.dart';

/// Açılış (yükleme) ekranı: logo, dolan altın çubuk, ESM Games ve sürüm.
class SplashScreen extends StatefulWidget {
  final double progress; // 0..1
  final String status;
  final String version;
  const SplashScreen(
      {super.key, required this.progress, required this.status, required this.version});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0A22),
      body: Stack(fit: StackFit.expand, children: [
        // arka plan ve yıldız tozu
        AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(painter: _SkyPainter(_c.value)),
        ),
        SafeArea(
          child: LayoutBuilder(builder: (ctx, c) {
            final logo = min(c.maxHeight * 0.42, 190.0);
            final barW = min(c.maxWidth * 0.55, 520.0);
            return Column(children: [
              const Spacer(flex: 2),
              AnimatedBuilder(
                animation: _c,
                builder: (_, child) => Transform.scale(
                    scale: 1 + 0.02 * sin(_c.value * 2 * pi), child: child),
                child: BrandLogo(size: logo),
              ),
              const Spacer(),
              _GoldBar(progress: widget.progress, width: barW, t: _c),
              const SizedBox(height: 10),
              Text(widget.status,
                  style: const TextStyle(
                      color: Color(0xFFF2D58A), fontSize: 15, fontWeight: FontWeight.w600)),
              const Spacer(flex: 2),
              Text('ESM Games',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: 2),
              Text('Sürüm ${widget.version}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.45), fontSize: 11)),
              const SizedBox(height: 10),
            ]);
          }),
        ),
      ]),
    );
  }
}

class _GoldBar extends StatelessWidget {
  final double progress;
  final double width;
  final Animation<double> t;
  const _GoldBar({required this.progress, required this.width, required this.t});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 22,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(colors: [Color(0xFFFFF1B8), Color(0xFFB07A22), Color(0xFFFFE08A)]),
        boxShadow: const [BoxShadow(color: Color(0x66FFC857), blurRadius: 16)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Container(
          color: const Color(0xFF15102E),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: progress.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 400),
              builder: (_, v, _) => FractionallySizedBox(
                widthFactor: max(0.02, v),
                child: AnimatedBuilder(
                  animation: t,
                  builder: (_, _) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(-1 + t.value * 4 - 1.5, 0),
                        end: Alignment(t.value * 4 - 1.5, 0),
                        colors: const [Color(0xFFB07A22), Color(0xFFFFF4C8), Color(0xFFE8B04A)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkyPainter extends CustomPainter {
  final double t;
  _SkyPainter(this.t);

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
        r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(0, -0.3),
            radius: 1.1,
            colors: [Color(0xFF2A1F6B), Color(0xFF120D33), Color(0xFF0A0820)],
          ).createShader(r));
    // dönen ışık kuşağı
    final band = Path();
    for (double x = 0; x <= s.width; x += 8) {
      final y = s.height * 0.45 + sin(x / s.width * 2 * pi + t * 2 * pi) * s.height * 0.12;
      x == 0 ? band.moveTo(x, y) : band.lineTo(x, y);
    }
    c.drawPath(
        band,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0x55B79BFF));
    final rnd = Random(4);
    for (int i = 0; i < 60; i++) {
      final x = rnd.nextDouble() * s.width, y = rnd.nextDouble() * s.height;
      final a = (sin(t * 2 * pi * 2 + i) + 1) / 2;
      c.drawCircle(Offset(x, y), 0.8 + rnd.nextDouble() * 1.4,
          Paint()..color = const Color(0xFFFFE9A8).withValues(alpha: 0.15 + a * 0.6));
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter old) => old.t != t;
}
