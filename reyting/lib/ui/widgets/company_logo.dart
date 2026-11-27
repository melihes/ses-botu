import '../../core/format.dart';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/content2.dart';
import '../../models/models.dart';

/// Oyuncunun kendi tasarladığı şirket logosu (sembol × renk × çerçeve).
class CompanyLogoView extends StatelessWidget {
  final CompanyLogo logo;
  final double size;
  final double glow; // 0..1 animasyonlar için parlama
  const CompanyLogoView({
    super.key,
    required this.logo,
    this.size = 48,
    this.glow = 0,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: LogoPainter(logo.shape, logo.palette, logo.frame, glow),
    ),
  );
}

class LogoPainter extends CustomPainter {
  final int shape, palette, frame;
  final double glow;
  LogoPainter(this.shape, this.palette, this.frame, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final cols = logoPalettes[palette % logoPalettes.length];
    final c1 = cols[0], c2 = cols[1];
    final grad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [c1, Color.lerp(c1, c2, 0.7)!],
      ).createShader(Offset.zero & size);
    final c = Offset(w / 2, w / 2);

    if (glow > 0) {
      canvas.drawCircle(
        c,
        w * 0.55,
        Paint()
          ..color = c1.withValues(alpha: 0.35 * glow)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.15),
      );
    }

    // ---- çerçeve ----
    final framePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.05
      ..color = c1;
    final bg = Paint()..color = const Color(0xFF1A1426);
    var inset = 0.12;
    switch (frame % logoFrameNames.length) {
      case 0:
        inset = 0.04;
      case 1:
        canvas.drawCircle(c, w * 0.47, bg);
        canvas.drawCircle(c, w * 0.45, framePaint);
      case 2:
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.04, w * 0.04, w * 0.92, w * 0.92),
          Radius.circular(w * 0.18),
        );
        canvas.drawRRect(r, bg);
        canvas.drawRRect(r, framePaint);
      case 3:
        final p = Path()
          ..moveTo(w * 0.5, w * 0.03)
          ..lineTo(w * 0.92, w * 0.16)
          ..quadraticBezierTo(w * 0.92, w * 0.72, w * 0.5, w * 0.97)
          ..quadraticBezierTo(w * 0.08, w * 0.72, w * 0.08, w * 0.16)
          ..close();
        canvas.drawPath(p, bg);
        canvas.drawPath(p, framePaint);
        inset = 0.16;
      case 4:
        final p = _poly(c, w * 0.47, 6, -pi / 2);
        canvas.drawPath(p, bg);
        canvas.drawPath(p, framePaint);
      case 5:
        canvas.drawCircle(c, w * 0.42, bg);
        final ray = Paint()
          ..color = c2
          ..strokeWidth = w * 0.03
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 16; i++) {
          final a = i * pi / 8;
          canvas.drawLine(
            c + Offset(cos(a), sin(a)) * w * 0.43,
            c + Offset(cos(a), sin(a)) * w * 0.49,
            ray,
          );
        }
        canvas.drawCircle(c, w * 0.40, framePaint..strokeWidth = w * 0.025);
      case 6: // çift daire
        canvas.drawCircle(c, w * 0.47, bg);
        canvas.drawCircle(c, w * 0.46, framePaint..strokeWidth = w * 0.03);
        canvas.drawCircle(c, w * 0.39, Paint()..style = PaintingStyle.stroke..strokeWidth = w * 0.02..color = c2);
        inset = 0.15;
      case 7: // elmas
        final p = _poly(c, w * 0.49, 4, -pi / 2);
        canvas.drawPath(p, bg);
        canvas.drawPath(p, framePaint);
        inset = 0.2;
      case 8: // sekizgen
        final p = _poly(c, w * 0.48, 8, -pi / 8);
        canvas.drawPath(p, bg);
        canvas.drawPath(p, framePaint);
      case 9: // rozet (tırtıklı)
        final p = _poly(c, w * 0.49, 16, -pi / 2, w * 0.43);
        canvas.drawPath(p, Paint()..color = c1);
        canvas.drawCircle(c, w * 0.4, bg);
        inset = 0.15;
      case 10: // defne
        canvas.drawCircle(c, w * 0.4, bg);
        final leaf = Paint()..color = c2;
        for (final side in [-1, 1]) {
          for (int i = 0; i < 6; i++) {
            final a = pi / 2 + side * (0.4 + i * 0.36);
            final pt = c + Offset(cos(a), sin(a)) * w * 0.44;
            canvas.save();
            canvas.translate(pt.dx, pt.dy);
            canvas.rotate(a + side * 0.9);
            canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.13, height: w * 0.06), leaf);
            canvas.restore();
          }
        }
        inset = 0.16;
      case 11: // kalın halka
        canvas.drawCircle(c, w * 0.46, Paint()..shader = grad.shader);
        canvas.drawCircle(c, w * 0.36, bg);
        inset = 0.18;
      case 12: // kesik köşe
        final k = w * 0.16;
        final p = Path()
          ..moveTo(w * 0.04 + k, w * 0.04)
          ..lineTo(w * 0.96 - k, w * 0.04)
          ..lineTo(w * 0.96, w * 0.04 + k)
          ..lineTo(w * 0.96, w * 0.96 - k)
          ..lineTo(w * 0.96 - k, w * 0.96)
          ..lineTo(w * 0.04 + k, w * 0.96)
          ..lineTo(w * 0.04, w * 0.96 - k)
          ..lineTo(w * 0.04, w * 0.04 + k)
          ..close();
        canvas.drawPath(p, bg);
        canvas.drawPath(p, framePaint);
      case 13: // damla
        final p = Path()
          ..moveTo(w * 0.5, w * 0.02)
          ..quadraticBezierTo(w * 0.95, w * 0.5, w * 0.85, w * 0.72)
          ..arcToPoint(Offset(w * 0.15, w * 0.72), radius: Radius.circular(w * 0.36))
          ..quadraticBezierTo(w * 0.05, w * 0.5, w * 0.5, w * 0.02)
          ..close();
        canvas.drawPath(p, bg);
        canvas.drawPath(p, framePaint);
        inset = 0.2;
      case 14: // yıldız
        final p = _poly(c, w * 0.5, 5, -pi / 2, w * 0.3);
        canvas.drawPath(p, bg);
        canvas.drawPath(p, framePaint..strokeWidth = w * 0.04);
        inset = 0.26;
      case 15: // flama
        final p = Path()
          ..moveTo(w * 0.1, w * 0.04)
          ..lineTo(w * 0.9, w * 0.04)
          ..lineTo(w * 0.9, w * 0.96)
          ..lineTo(w * 0.5, w * 0.78)
          ..lineTo(w * 0.1, w * 0.96)
          ..close();
        canvas.drawPath(p, bg);
        canvas.drawPath(p, framePaint);
        inset = 0.14;
    }

    // ---- sembol ----
    final box = Rect.fromLTWH(
      w * inset + w * 0.1,
      w * inset + w * 0.1,
      w * (1 - 2 * inset - 0.2),
      w * (1 - 2 * inset - 0.2),
    );
    canvas.save();
    canvas.translate(box.left, box.top);
    canvas.scale(box.width, box.height);
    _symbol(canvas, shape % logoShapeNames.length, grad, c1, c2, box.width);
    canvas.restore();
  }

  Path _poly(Offset c, double r, int n, double start, [double inner = 0]) {
    final p = Path();
    final steps = inner > 0 ? n * 2 : n;
    for (int i = 0; i < steps; i++) {
      final rr = inner > 0 && i.isOdd ? inner : r;
      final a = start + i * 2 * pi / steps;
      final pt = c + Offset(cos(a), sin(a)) * rr;
      i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
    }
    return p..close();
  }

  void _symbol(Canvas cv, int s, Paint fill, Color c1, Color c2, double scale) {
    // birim kare (0..1) içinde çizim; shader ölçek sonrası bozulmasın diye düz renk
    final f = Paint()..color = c1;
    final f2 = Paint()..color = c2;
    final st = Paint()
      ..color = c1
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const c = Offset(0.5, 0.5);
    switch (s) {
      case 0: // Hilal
        final p = Path()..addOval(Rect.fromCircle(center: c, radius: 0.45));
        final cut = Path()
          ..addOval(
            Rect.fromCircle(center: const Offset(0.66, 0.42), radius: 0.38),
          );
        cv.drawPath(Path.combine(PathOperation.difference, p, cut), f);
        cv.drawPath(_poly(const Offset(0.74, 0.5), 0.12, 5, -pi / 2, 0.05), f2);
      case 1: // Güneş
        cv.drawCircle(c, 0.22, f);
        for (int i = 0; i < 12; i++) {
          final a = i * pi / 6;
          cv.drawLine(
            c + Offset(cos(a), sin(a)) * 0.3,
            c + Offset(cos(a), sin(a)) * 0.47,
            st..strokeWidth = 0.06,
          );
        }
      case 2: // Yıldız
        cv.drawPath(_poly(c, 0.5, 5, -pi / 2, 0.2), f);
        cv.drawPath(_poly(c, 0.18, 5, -pi / 2, 0.07), f2);
      case 3: // Rüzgâr
        for (int i = 0; i < 3; i++) {
          final y = 0.25 + i * 0.25;
          final p = Path()
            ..moveTo(0.05, y)
            ..cubicTo(0.35, y - 0.12, 0.6, y + 0.12, 0.8 - i * 0.1, y)
            ..arcToPoint(
              Offset(0.8 - i * 0.1, y - 0.14),
              radius: const Radius.circular(0.07),
              clockwise: false,
            );
          cv.drawPath(
            p,
            (i == 1 ? (Paint()..color = c2) : f)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.08
              ..strokeCap = StrokeCap.round,
          );
        }
      case 4: // Dalga
        for (int i = 0; i < 3; i++) {
          final y = 0.3 + i * 0.2;
          final p = Path()..moveTo(0.02, y);
          for (int k = 0; k < 4; k++) {
            p.quadraticBezierTo(
              0.02 + k * 0.24 + 0.12,
              y - 0.12,
              0.02 + (k + 1) * 0.24,
              y,
            );
          }
          cv.drawPath(
            p,
            (i.isEven ? Paint() : (Paint()..color = c2))
              ..color = i.isEven ? c1 : c2
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.08
              ..strokeCap = StrokeCap.round,
          );
        }
      case 5: // Dağ
        cv.drawPath(
          Path()
            ..moveTo(0, 0.9)
            ..lineTo(0.38, 0.15)
            ..lineTo(0.62, 0.6)
            ..lineTo(0.75, 0.4)
            ..lineTo(1, 0.9)
            ..close(),
          f,
        );
        cv.drawPath(
          Path()
            ..moveTo(0.28, 0.35)
            ..lineTo(0.38, 0.15)
            ..lineTo(0.48, 0.35)
            ..lineTo(0.4, 0.3)
            ..close(),
          Paint()..color = Colors.white,
        );
      case 6: // Alev
        final p = Path()
          ..moveTo(0.5, 0.0)
          ..cubicTo(0.9, 0.35, 0.95, 0.65, 0.5, 1)
          ..cubicTo(0.05, 0.65, 0.2, 0.4, 0.35, 0.3)
          ..cubicTo(0.35, 0.5, 0.45, 0.5, 0.5, 0.0);
        cv.drawPath(p, f);
        cv.drawPath(
          Path()
            ..moveTo(0.5, 0.45)
            ..cubicTo(0.75, 0.65, 0.7, 0.85, 0.5, 0.95)
            ..cubicTo(0.3, 0.85, 0.3, 0.65, 0.5, 0.45),
          f2,
        );
      case 7: // Elmas
        cv.drawPath(
          Path()
            ..moveTo(0.2, 0.15)
            ..lineTo(0.8, 0.15)
            ..lineTo(1, 0.38)
            ..lineTo(0.5, 0.95)
            ..lineTo(0, 0.38)
            ..close(),
          f,
        );
        cv.drawPath(
          Path()
            ..moveTo(0, 0.38)
            ..lineTo(1, 0.38)
            ..moveTo(0.35, 0.15)
            ..lineTo(0.28, 0.38)
            ..lineTo(0.5, 0.95)
            ..lineTo(0.72, 0.38)
            ..lineTo(0.65, 0.15),
          Paint()
            ..color = c2
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.03,
        );
      case 8: // Taç
        cv.drawPath(
          Path()
            ..moveTo(0.05, 0.8)
            ..lineTo(0.05, 0.3)
            ..lineTo(0.3, 0.55)
            ..lineTo(0.5, 0.15)
            ..lineTo(0.7, 0.55)
            ..lineTo(0.95, 0.3)
            ..lineTo(0.95, 0.8)
            ..close(),
          f,
        );
        cv.drawRect(const Rect.fromLTWH(0.05, 0.82, 0.9, 0.1), f2);
        for (final x in [0.05, 0.5, 0.95]) {
          cv.drawCircle(Offset(x, x == 0.5 ? 0.12 : 0.27), 0.06, f2);
        }
      case 9: // Kanat
        for (int i = 0; i < 4; i++) {
          cv.drawPath(
            Path()
              ..moveTo(0.1, 0.75)
              ..quadraticBezierTo(
                0.3 + i * 0.1,
                0.15 + i * 0.12,
                0.95 - i * 0.05,
                0.1 + i * 0.16,
              )
              ..quadraticBezierTo(0.5, 0.45 + i * 0.1, 0.1, 0.75),
            i.isEven ? f : f2,
          );
        }
      case 10: // Kalp
        cv.drawPath(
          Path()
            ..moveTo(0.5, 0.92)
            ..cubicTo(-0.15, 0.45, 0.15, -0.05, 0.5, 0.28)
            ..cubicTo(0.85, -0.05, 1.15, 0.45, 0.5, 0.92),
          f,
        );
      case 11: // Şimşek
        cv.drawPath(
          Path()
            ..moveTo(0.6, 0.0)
            ..lineTo(0.15, 0.55)
            ..lineTo(0.45, 0.55)
            ..lineTo(0.35, 1)
            ..lineTo(0.85, 0.4)
            ..lineTo(0.55, 0.4)
            ..close(),
          f,
        );
      case 12: // Yaprak
        cv.drawPath(
          Path()
            ..moveTo(0.1, 0.9)
            ..quadraticBezierTo(0.0, 0.1, 0.9, 0.1)
            ..quadraticBezierTo(0.95, 0.9, 0.1, 0.9),
          f,
        );
        cv.drawLine(
          const Offset(0.1, 0.9),
          const Offset(0.7, 0.3),
          Paint()
            ..color = c2
            ..strokeWidth = 0.05,
        );
      case 13: // Göz
        cv.drawPath(
          Path()
            ..moveTo(0, 0.5)
            ..quadraticBezierTo(0.5, 0.0, 1, 0.5)
            ..quadraticBezierTo(0.5, 1.0, 0, 0.5),
          f,
        );
        cv.drawCircle(c, 0.18, Paint()..color = const Color(0xFF1A1426));
        cv.drawCircle(c, 0.09, f2);
      case 14: // Film şeridi
        cv.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.05, 0.2, 0.9, 0.6),
            const Radius.circular(0.06),
          ),
          f,
        );
        final hole = Paint()..color = const Color(0xFF1A1426);
        for (int i = 0; i < 5; i++) {
          cv.drawRect(Rect.fromLTWH(0.1 + i * 0.17, 0.24, 0.09, 0.07), hole);
          cv.drawRect(Rect.fromLTWH(0.1 + i * 0.17, 0.69, 0.09, 0.07), hole);
        }
        cv.drawRect(const Rect.fromLTWH(0.15, 0.36, 0.3, 0.28), f2);
        cv.drawRect(const Rect.fromLTWH(0.55, 0.36, 0.3, 0.28), f2);
      case 15: // Kamera
        cv.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.05, 0.35, 0.62, 0.45),
            const Radius.circular(0.06),
          ),
          f,
        );
        cv.drawPath(
          Path()
            ..moveTo(0.67, 0.5)
            ..lineTo(0.95, 0.38)
            ..lineTo(0.95, 0.78)
            ..lineTo(0.67, 0.66)
            ..close(),
          f2,
        );
        cv.drawCircle(const Offset(0.2, 0.2), 0.13, f);
        cv.drawCircle(const Offset(0.48, 0.2), 0.13, f);
      case 16: // Mikrofon
        cv.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.33, 0.02, 0.34, 0.55),
            const Radius.circular(0.17),
          ),
          f,
        );
        cv.drawPath(
          Path()
            ..moveTo(0.2, 0.4)
            ..quadraticBezierTo(0.2, 0.75, 0.5, 0.75)
            ..quadraticBezierTo(0.8, 0.75, 0.8, 0.4),
          Paint()
            ..color = c2
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.06,
        );
        cv.drawRect(const Rect.fromLTWH(0.47, 0.75, 0.06, 0.15), f2);
        cv.drawRect(const Rect.fromLTWH(0.3, 0.9, 0.4, 0.06), f2);
      case 17: // Nota
        cv.drawOval(const Rect.fromLTWH(0.08, 0.68, 0.3, 0.22), f);
        cv.drawOval(const Rect.fromLTWH(0.55, 0.58, 0.3, 0.22), f);
        cv.drawRect(const Rect.fromLTWH(0.32, 0.12, 0.06, 0.68), f);
        cv.drawRect(const Rect.fromLTWH(0.79, 0.02, 0.06, 0.68), f);
        cv.drawPath(
          Path()
            ..moveTo(0.32, 0.12)
            ..lineTo(0.85, 0.02)
            ..lineTo(0.85, 0.16)
            ..lineTo(0.32, 0.26)
            ..close(),
          f2,
        );
      case 18: // Kalkan
        cv.drawPath(
          Path()
            ..moveTo(0.5, 0)
            ..lineTo(0.95, 0.15)
            ..quadraticBezierTo(0.95, 0.75, 0.5, 1)
            ..quadraticBezierTo(0.05, 0.75, 0.05, 0.15)
            ..close(),
          f,
        );
        cv.drawPath(
          Path()
            ..moveTo(0.5, 0.0)
            ..lineTo(0.5, 1)
            ..quadraticBezierTo(0.05, 0.75, 0.05, 0.15)
            ..close(),
          f2,
        );
      case 19: // Çark
        final teeth = _poly(c, 0.5, 10, 0, 0.38);
        cv.drawPath(teeth, f);
        cv.drawCircle(c, 0.16, Paint()..color = const Color(0xFF1A1426));
        cv.drawCircle(c, 0.08, f2);
      case 20: // Atom
        for (int i = 0; i < 3; i++) {
          cv.save();
          cv.translate(0.5, 0.5);
          cv.rotate(i * pi / 3);
          cv.drawOval(
            const Rect.fromLTWH(-0.48, -0.17, 0.96, 0.34),
            Paint()
              ..color = c1
              ..style = PaintingStyle.stroke
              ..strokeWidth = 0.05,
          );
          cv.restore();
        }
        cv.drawCircle(c, 0.1, f2);
      case 21: // Kelebek
        cv.drawOval(const Rect.fromLTWH(0.02, 0.08, 0.46, 0.48), f);
        cv.drawOval(const Rect.fromLTWH(0.52, 0.08, 0.46, 0.48), f);
        cv.drawOval(const Rect.fromLTWH(0.1, 0.5, 0.36, 0.38), f2);
        cv.drawOval(const Rect.fromLTWH(0.54, 0.5, 0.36, 0.38), f2);
        cv.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(0.46, 0.15, 0.08, 0.75),
            const Radius.circular(0.04),
          ),
          Paint()..color = const Color(0xFF1A1426),
        );
      case 22: // Ok
        cv.drawPath(
          Path()
            ..moveTo(0.05, 0.95)
            ..lineTo(0.8, 0.2),
          st,
        );
        cv.drawPath(
          Path()
            ..moveTo(0.95, 0.05)
            ..lineTo(0.55, 0.12)
            ..lineTo(0.88, 0.45)
            ..close(),
          f2,
        );
      case 23: // Sonsuzluk
        final p = Path()
          ..moveTo(0.5, 0.5)
          ..cubicTo(0.3, 0.15, 0.0, 0.25, 0.02, 0.5)
          ..cubicTo(0.0, 0.75, 0.3, 0.85, 0.5, 0.5)
          ..cubicTo(0.7, 0.15, 1.0, 0.25, 0.98, 0.5)
          ..cubicTo(1.0, 0.75, 0.7, 0.85, 0.5, 0.5);
        cv.drawPath(p, st..strokeWidth = 0.1);
      case 24: // Kule
        cv.drawPath(
          Path()
            ..moveTo(0.3, 1)
            ..lineTo(0.42, 0.3)
            ..lineTo(0.58, 0.3)
            ..lineTo(0.7, 1)
            ..close(),
          f,
        );
        cv.drawRect(const Rect.fromLTWH(0.36, 0.2, 0.28, 0.12), f2);
        cv.drawPath(
          Path()
            ..moveTo(0.38, 0.2)
            ..lineTo(0.5, 0.0)
            ..lineTo(0.62, 0.2)
            ..close(),
          f,
        );
      case 25: // Lale
        cv.drawPath(
          Path()
            ..moveTo(0.5, 0.65)
            ..cubicTo(0.15, 0.6, 0.15, 0.2, 0.25, 0.05)
            ..lineTo(0.38, 0.25)
            ..lineTo(0.5, 0.02)
            ..lineTo(0.62, 0.25)
            ..lineTo(0.75, 0.05)
            ..cubicTo(0.85, 0.2, 0.85, 0.6, 0.5, 0.65),
          f,
        );
        cv.drawLine(
          const Offset(0.5, 0.62),
          const Offset(0.5, 1),
          Paint()
            ..color = c2
            ..strokeWidth = 0.06,
        );
        cv.drawPath(
          Path()
            ..moveTo(0.5, 0.95)
            ..quadraticBezierTo(0.2, 0.9, 0.18, 0.65)
            ..quadraticBezierTo(0.42, 0.72, 0.5, 0.95),
          f2,
        );
      case 26: // Martı
        cv.drawPath(
          Path()
            ..moveTo(0.0, 0.4)
            ..quadraticBezierTo(0.25, 0.2, 0.5, 0.55)
            ..quadraticBezierTo(0.75, 0.2, 1.0, 0.4)
            ..quadraticBezierTo(0.75, 0.35, 0.5, 0.7)
            ..quadraticBezierTo(0.25, 0.35, 0.0, 0.4),
          f,
        );
        cv.drawCircle(const Offset(0.5, 0.85), 0.06, f2);
      case 28: // Anten
        cv.drawLine(const Offset(0.5, 0.35), const Offset(0.5, 0.95), st);
        cv.drawLine(const Offset(0.3, 0.95), const Offset(0.5, 0.55), st);
        cv.drawLine(const Offset(0.7, 0.95), const Offset(0.5, 0.55), st);
        cv.drawCircle(const Offset(0.5, 0.3), 0.08, f2);
        for (final r in [0.18, 0.3]) {
          cv.drawArc(Rect.fromCircle(center: const Offset(0.5, 0.3), radius: r), -pi * 0.85, pi * 0.7, false, st..strokeWidth = 0.05);
        }
      case 29: // Uydu
        cv.save();
        cv.translate(0.5, 0.5);
        cv.rotate(-pi / 4);
        cv.drawRect(const Rect.fromLTWH(-0.12, -0.12, 0.24, 0.24), f);
        cv.drawRect(const Rect.fromLTWH(-0.48, -0.08, 0.3, 0.16), f2);
        cv.drawRect(const Rect.fromLTWH(0.18, -0.08, 0.3, 0.16), f2);
        cv.restore();
      case 30: // Ekran
        cv.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0.05, 0.15, 0.9, 0.6), const Radius.circular(0.08)), f);
        cv.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0.13, 0.23, 0.74, 0.44), const Radius.circular(0.04)), f2);
        cv.drawRect(const Rect.fromLTWH(0.42, 0.75, 0.16, 0.1), f);
        cv.drawRect(const Rect.fromLTWH(0.28, 0.85, 0.44, 0.06), f);
      case 31: // Oynat
        cv.drawCircle(c, 0.47, f);
        cv.drawPath(Path()..moveTo(0.4, 0.28)..lineTo(0.74, 0.5)..lineTo(0.4, 0.72)..close(), f2);
      case 32: // Kayıt
        cv.drawCircle(c, 0.47, st..strokeWidth = 0.07);
        cv.drawCircle(c, 0.28, f2);
      case 33: // Klaket
        cv.drawRect(const Rect.fromLTWH(0.08, 0.42, 0.84, 0.5), f);
        cv.save();
        cv.translate(0.08, 0.38);
        cv.rotate(-0.25);
        cv.drawRect(const Rect.fromLTWH(0, -0.14, 0.86, 0.14), f2);
        cv.restore();
        for (int i = 0; i < 4; i++) {
          cv.drawLine(Offset(0.15 + i * 0.2, 0.42), Offset(0.25 + i * 0.2, 0.92), Paint()..color = c2..strokeWidth = 0.05);
        }
      case 34: // Spot ışığı
        cv.drawPath(Path()..moveTo(0.42, 0.18)..lineTo(0.58, 0.18)..lineTo(0.95, 0.95)..lineTo(0.05, 0.95)..close(),
            Paint()..color = c2.withValues(alpha: 0.6));
        cv.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0.32, 0.05, 0.36, 0.2), const Radius.circular(0.05)), f);
      case 35: // Megafon
        cv.drawPath(Path()..moveTo(0.1, 0.4)..lineTo(0.35, 0.4)..lineTo(0.85, 0.12)..lineTo(0.85, 0.88)..lineTo(0.35, 0.6)..lineTo(0.1, 0.6)..close(), f);
        cv.drawRect(const Rect.fromLTWH(0.2, 0.6, 0.1, 0.25), f2);
      case 36: // Kupa
        cv.drawPath(Path()..moveTo(0.2, 0.1)..lineTo(0.8, 0.1)..quadraticBezierTo(0.8, 0.6, 0.5, 0.62)..quadraticBezierTo(0.2, 0.6, 0.2, 0.1)..close(), f);
        cv.drawRect(const Rect.fromLTWH(0.45, 0.6, 0.1, 0.2), f);
        cv.drawRect(const Rect.fromLTWH(0.28, 0.8, 0.44, 0.1), f2);
        cv.drawArc(const Rect.fromLTWH(0.04, 0.15, 0.3, 0.3), pi / 2, pi, false, st..strokeWidth = 0.05);
        cv.drawArc(const Rect.fromLTWH(0.66, 0.15, 0.3, 0.3), -pi / 2, pi, false, st..strokeWidth = 0.05);
      case 37: // Roket
        cv.drawPath(Path()..moveTo(0.5, 0.02)..quadraticBezierTo(0.78, 0.3, 0.68, 0.7)..lineTo(0.32, 0.7)..quadraticBezierTo(0.22, 0.3, 0.5, 0.02)..close(), f);
        cv.drawCircle(const Offset(0.5, 0.35), 0.08, f2);
        cv.drawPath(Path()..moveTo(0.32, 0.55)..lineTo(0.15, 0.8)..lineTo(0.34, 0.72)..close(), f2);
        cv.drawPath(Path()..moveTo(0.68, 0.55)..lineTo(0.85, 0.8)..lineTo(0.66, 0.72)..close(), f2);
        cv.drawPath(Path()..moveTo(0.4, 0.72)..lineTo(0.5, 0.98)..lineTo(0.6, 0.72)..close(), Paint()..color = const Color(0xFFFFA000));
      case 38: // Gezegen
        cv.drawCircle(c, 0.3, f);
        cv.drawOval(Rect.fromCenter(center: c, width: 0.98, height: 0.3), st..strokeWidth = 0.06..color = c2);
      case 39: // Kristal
        cv.drawPath(Path()..moveTo(0.5, 0.02)..lineTo(0.82, 0.35)..lineTo(0.5, 0.98)..lineTo(0.18, 0.35)..close(), f);
        cv.drawPath(Path()..moveTo(0.5, 0.02)..lineTo(0.62, 0.35)..lineTo(0.5, 0.98)..lineTo(0.38, 0.35)..close(), f2);
      case 40: // Üçgen
        cv.drawPath(_poly(c + const Offset(0, 0.06), 0.5, 3, -pi / 2), f);
        cv.drawPath(_poly(c + const Offset(0, 0.06), 0.24, 3, pi / 2), f2);
      case 41: // Küp
        cv.drawPath(Path()..moveTo(0.5, 0.05)..lineTo(0.9, 0.27)..lineTo(0.5, 0.5)..lineTo(0.1, 0.27)..close(), f);
        cv.drawPath(Path()..moveTo(0.1, 0.27)..lineTo(0.5, 0.5)..lineTo(0.5, 0.95)..lineTo(0.1, 0.72)..close(), f2);
        cv.drawPath(Path()..moveTo(0.9, 0.27)..lineTo(0.5, 0.5)..lineTo(0.5, 0.95)..lineTo(0.9, 0.72)..close(),
            Paint()..color = Color.lerp(c1, Colors.black, 0.3)!);
      case 42: // Spiral
        final sp = Path()..moveTo(0.5, 0.5);
        for (double a = 0; a < pi * 6; a += 0.2) {
          final r = 0.02 + a * 0.024;
          sp.lineTo(0.5 + cos(a) * r, 0.5 + sin(a) * r);
        }
        cv.drawPath(sp, st..strokeWidth = 0.06);
      case 43: // Sinyal
        for (int i = 0; i < 4; i++) {
          cv.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0.1 + i * 0.22, 0.75 - i * 0.2, 0.16, 0.2 + i * 0.2), const Radius.circular(0.03)),
              i.isEven ? f : f2);
        }
      case 44: // Çiçek
        for (int i = 0; i < 6; i++) {
          final a = i * pi / 3;
          cv.drawCircle(c + Offset(cos(a), sin(a)) * 0.24, 0.17, f);
        }
        cv.drawCircle(c, 0.15, f2);
      case 45: // Ağaç
        cv.drawRect(const Rect.fromLTWH(0.44, 0.65, 0.12, 0.32), f2);
        cv.drawCircle(const Offset(0.5, 0.38), 0.3, f);
        cv.drawCircle(const Offset(0.3, 0.52), 0.18, f);
        cv.drawCircle(const Offset(0.7, 0.52), 0.18, f);
      case 46: // Balık
        cv.drawOval(const Rect.fromLTWH(0.1, 0.28, 0.6, 0.44), f);
        cv.drawPath(Path()..moveTo(0.65, 0.5)..lineTo(0.95, 0.25)..lineTo(0.95, 0.75)..close(), f2);
        cv.drawCircle(const Offset(0.25, 0.45), 0.04, Paint()..color = const Color(0xFF1A1426));
      case 47: // Dünya
        cv.drawCircle(c, 0.46, f);
        final l = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.035..color = c2;
        cv.drawOval(Rect.fromCenter(center: c, width: 0.4, height: 0.92), l);
        cv.drawLine(const Offset(0.04, 0.5), const Offset(0.96, 0.5), l);
        cv.drawLine(const Offset(0.5, 0.04), const Offset(0.5, 0.96), l);
        cv.drawArc(Rect.fromCenter(center: const Offset(0.5, 0.05), width: 0.9, height: 0.5), 0.3, pi - 0.6, false, l);
        cv.drawArc(Rect.fromCenter(center: const Offset(0.5, 0.95), width: 0.9, height: 0.5), pi + 0.3, pi - 0.6, false, l);
      case 48: // Bulut
        cv.drawCircle(const Offset(0.35, 0.55), 0.2, f);
        cv.drawCircle(const Offset(0.58, 0.45), 0.26, f);
        cv.drawCircle(const Offset(0.78, 0.6), 0.16, f);
        cv.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0.15, 0.55, 0.78, 0.22), const Radius.circular(0.11)), f);
        cv.drawCircle(const Offset(0.58, 0.45), 0.1, f2);
      case 49: // Damla
        cv.drawPath(Path()..moveTo(0.5, 0.02)..quadraticBezierTo(0.9, 0.5, 0.82, 0.7)..arcToPoint(const Offset(0.18, 0.7), radius: const Radius.circular(0.33))
          ..quadraticBezierTo(0.1, 0.5, 0.5, 0.02)..close(), f);
        cv.drawOval(const Rect.fromLTWH(0.3, 0.55, 0.12, 0.2), f2);
      case 50: // Anahtar
        cv.drawCircle(const Offset(0.3, 0.5), 0.22, st..strokeWidth = 0.08);
        cv.drawLine(const Offset(0.52, 0.5), const Offset(0.95, 0.5), st);
        cv.drawLine(const Offset(0.8, 0.5), const Offset(0.8, 0.7), st);
        cv.drawLine(const Offset(0.92, 0.5), const Offset(0.92, 0.65), st);
      case 51: // Ateş topu
        cv.drawCircle(const Offset(0.4, 0.6), 0.3, f);
        for (int i = 0; i < 3; i++) {
          cv.drawPath(Path()..moveTo(0.5 + i * 0.05, 0.32 + i * 0.12)..quadraticBezierTo(0.85, 0.1 + i * 0.12, 0.98, 0.15 + i * 0.12)
            ..quadraticBezierTo(0.8, 0.4 + i * 0.1, 0.62, 0.48 + i * 0.1)..close(), f2);
        }
        cv.drawCircle(const Offset(0.4, 0.6), 0.14, f2);
      default: // Pusula
        cv.drawCircle(
          c,
          0.46,
          Paint()
            ..color = c1
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.05,
        );
        cv.drawPath(
          Path()
            ..moveTo(0.5, 0.06)
            ..lineTo(0.6, 0.5)
            ..lineTo(0.4, 0.5)
            ..close(),
          f,
        );
        cv.drawPath(
          Path()
            ..moveTo(0.5, 0.94)
            ..lineTo(0.6, 0.5)
            ..lineTo(0.4, 0.5)
            ..close(),
          f2,
        );
    }
  }

  @override
  bool shouldRepaint(covariant LogoPainter o) =>
      o.shape != shape ||
      o.palette != palette ||
      o.frame != frame ||
      o.glow != glow;
}

/// Logo + şirket adı (yatay amblem)
class CompanyBadge extends StatelessWidget {
  final CompanyLogo logo;
  final String name;
  final double size;
  const CompanyBadge({
    super.key,
    required this.logo,
    required this.name,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final c = logoPalettes[logo.palette % logoPalettes.length];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CompanyLogoView(logo: logo, size: size),
        SizedBox(width: size * 0.2),
        Flexible(
          child: Text(
            trUpper(name),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: size * 0.38,
              color: c[0],
            ),
          ),
        ),
      ],
    );
  }
}
