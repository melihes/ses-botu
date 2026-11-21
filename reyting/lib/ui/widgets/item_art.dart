import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/content.dart';
import 'scene.dart';

/// Her eşyanın (lüks, ekipman, işletme) kendine özgü hareketli resmi.
class ItemArt extends StatefulWidget {
  final String id;
  final Color color;
  final double width;
  final double height;
  final String? badge;
  const ItemArt({
    super.key,
    required this.id,
    required this.color,
    this.width = 84,
    this.height = 84,
    this.badge,
  });

  @override
  State<ItemArt> createState() => _ItemArtState();
}

class _ItemArtState extends State<ItemArt> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _ItemPainter(_c, widget.id, widget.color)),
            if (widget.badge != null)
              Positioned(
                left: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _ItemPainter extends CustomPainter {
  final Animation<double> a;
  final String id;
  final Color color;
  _ItemPainter(this.a, this.id, this.color) : super(repaint: a);

  @override
  void paint(Canvas canvas, Size size) {
    final d = Draw(canvas, size);
    final t = a.value, w = t * 2 * pi;
    d.vgrad(
      0,
      1,
      Color.lerp(color, Colors.black, 0.55)!,
      Color.lerp(color, AppColors.bg, 0.75)!,
    );

    switch (id) {
      // ------------------ SAATLER ------------------
      case 'w1':
      case 'w2':
      case 'w3':
        final gold = id != 'w1';
        final caseC = id == 'w1'
            ? const Color(0xFFC9CED6)
            : id == 'w2'
            ? const Color(0xFFE8C062)
            : const Color(0xFF2A2A2A);
        final strap = id == 'w1'
            ? const Color(0xFF8A8F99)
            : id == 'w2'
            ? const Color(0xFF6B3A1E)
            : const Color(0xFF111111);
        d.rrect(0.38, 0.0, 0.24, 1.0, 6, strap);
        for (double y = 0.05; y < 1; y += 0.1) {
          d.line(0.38, y, 0.62, y, Colors.black26, 1);
        }
        d.circle(0.5, 0.5, 0.3, caseC);
        d.circle(
          0.5,
          0.5,
          0.26,
          id == 'w3' ? const Color(0xFF0E1A2E) : Colors.white,
        );
        for (int k = 0; k < 12; k++) {
          final ang = k * pi / 6;
          d.line(
            0.5 + cos(ang) * 0.16 * size.height / size.width,
            0.5 + sin(ang) * 0.22,
            0.5 + cos(ang) * 0.19 * size.height / size.width,
            0.5 + sin(ang) * 0.25,
            gold ? const Color(0xFFB8860B) : Colors.black54,
            1.5,
          );
        }
        if (id == 'w3') {
          // dönen tourbillon çarkı
          final o = Offset(0.5 * d.W, 0.62 * d.H);
          for (int k = 0; k < 6; k++) {
            final ang = w * 3 + k * pi / 3;
            canvas.drawLine(
              o,
              o + Offset(cos(ang), sin(ang)) * d.H * 0.06,
              Paint()
                ..color = const Color(0xFFE8C062)
                ..strokeWidth = 1.5,
            );
          }
          canvas.drawCircle(
            o,
            d.H * 0.07,
            Paint()
              ..color = const Color(0xFFE8C062)
              ..style = PaintingStyle.stroke,
          );
        }
        final c0 = Offset(0.5 * d.W, 0.5 * d.H);
        final hA = w - pi / 2, mA = w * 12 - pi / 2;
        canvas.drawLine(
          c0,
          c0 + Offset(cos(hA), sin(hA)) * d.H * 0.12,
          Paint()
            ..color = id == 'w3' ? Colors.white : Colors.black
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          c0,
          c0 + Offset(cos(mA), sin(mA)) * d.H * 0.19,
          Paint()
            ..color = id == 'w3' ? Colors.white70 : Colors.black87
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        d.circle(0.5, 0.5, 0.02, AppColors.red);
        _shine(d, t);

      // ------------------ ARABALAR ------------------
      case 'c1':
      case 'c2':
      case 'c3':
        d.vgrad(0, 0.7, const Color(0xFF2A3A5A), const Color(0xFF8A6A8A));
        d.rect(0, 0.72, 1, 0.28, const Color(0xFF333340));
        for (int k = 0; k < 4; k++) {
          final x = 1 - ((t * 3 + k / 4) % 1) * 1.2;
          d.rect(x, 0.86, 0.12, 0.02, Colors.white54);
        }
        final body = id == 'c1'
            ? const Color(0xFF2B2B33)
            : id == 'c2'
            ? AppColors.red
            : AppColors.yellow;
        if (id == 'c1') {
          d.rrect(0.08, 0.5, 0.84, 0.2, 6, body);
          d.poly([0.25, 0.5, 0.33, 0.33, 0.68, 0.33, 0.78, 0.5], body);
          d.poly([
            0.29,
            0.49,
            0.35,
            0.36,
            0.49,
            0.36,
            0.49,
            0.49,
          ], const Color(0xFF9FD3F5));
          d.poly([
            0.52,
            0.49,
            0.52,
            0.36,
            0.66,
            0.36,
            0.74,
            0.49,
          ], const Color(0xFF9FD3F5));
        } else if (id == 'c2') {
          d.poly([
            0.06,
            0.66,
            0.1,
            0.52,
            0.35,
            0.48,
            0.5,
            0.36,
            0.72,
            0.38,
            0.92,
            0.55,
            0.95,
            0.68,
            0.06,
            0.68,
          ], body);
          d.poly([
            0.38,
            0.48,
            0.5,
            0.39,
            0.7,
            0.4,
            0.8,
            0.5,
          ], const Color(0xFF9FD3F5));
        } else {
          d.poly([
            0.04,
            0.68,
            0.08,
            0.58,
            0.4,
            0.5,
            0.55,
            0.4,
            0.7,
            0.42,
            0.97,
            0.6,
            0.97,
            0.68,
          ], body);
          d.poly([
            0.44,
            0.5,
            0.56,
            0.42,
            0.68,
            0.43,
            0.76,
            0.52,
          ], const Color(0xFF223344));
          d.rect(0.02, 0.48, 0.12, 0.03, Colors.black);
          d.line(0.06, 0.51, 0.08, 0.58, Colors.black, 2);
        }
        d.circle(0.08, 0.6, 0.025, AppColors.red);
        d.circle(0.94, 0.6, 0.025, const Color(0xFFFFF4C8));
        for (final x in [0.25, 0.75]) {
          d.circle(x, 0.7, 0.1, const Color(0xFF111111));
          d.circle(x, 0.7, 0.05, const Color(0xFFAAAAAA));
          final o = Offset(x * d.W, 0.7 * d.H);
          for (int k = 0; k < 3; k++) {
            final ang = -w * 6 + k * 2 * pi / 3;
            canvas.drawLine(
              o,
              o + Offset(cos(ang), sin(ang)) * d.H * 0.05,
              Paint()
                ..color = const Color(0xFF555555)
                ..strokeWidth = 2,
            );
          }
        }
        _shine(d, t);

      // ------------------ EVLER ------------------
      case 'h1':
        d.vgrad(0, 0.8, const Color(0xFF5E8BC4), const Color(0xFFF2B27A));
        d.rect(0.3, 0.12, 0.4, 0.78, const Color(0xFFDDE3EA));
        for (double y = 0.16; y < 0.85; y += 0.08) {
          for (double x = 0.34; x < 0.66; x += 0.08) {
            d.rect(
              x,
              y,
              0.05,
              0.05,
              sin(w * 2 + x * 20 + y * 30) > 0
                  ? AppColors.yellow
                  : const Color(0xFF6A8AB0),
            );
          }
        }
        d.rect(0, 0.88, 1, 0.12, const Color(0xFF555560));
        d.rect(0.45, 0.8, 0.1, 0.1, const Color(0xFF7A5230));
      case 'h2':
        d.vgrad(0, 0.75, const Color(0xFF6EC6F5), const Color(0xFFC8ECFF));
        d.circle(0.85, 0.15, 0.08, const Color(0xFFFFE08A));
        d.rect(0, 0.72, 1, 0.28, const Color(0xFF6BBF59));
        d.rect(0.15, 0.4, 0.55, 0.32, Colors.white);
        d.rect(0.35, 0.25, 0.4, 0.17, const Color(0xFFF2F2F2));
        d.rect(0.12, 0.38, 0.62, 0.03, const Color(0xFF444444));
        d.rect(0.33, 0.23, 0.44, 0.03, const Color(0xFF444444));
        d.rect(0.2, 0.48, 0.2, 0.16, const Color(0xFF9FD3F5));
        d.rect(0.45, 0.28, 0.25, 0.1, const Color(0xFF9FD3F5));
        d.rect(0.5, 0.48, 0.08, 0.24, const Color(0xFF7A5230));
        d.rrect(0.1, 0.8, 0.6, 0.12, 4, const Color(0xFF3FC1D9));
        for (int k = 0; k < 3; k++) {
          final x = 0.15 + ((t + k / 3) % 1) * 0.5;
          d.line(x, 0.86, x + 0.05, 0.86, Colors.white70, 1.5);
        }
        d.palm(0.85, 0.75, 0.4, sin(w * 2));
      case 'h3':
        d.vgrad(0, 0.7, const Color(0xFF3A4A7A), const Color(0xFFE8A07A));
        d.rect(0, 0.68, 1, 0.32, const Color(0xFF3E7A4A));
        d.oval(0.8, 0.86, 0.35, 0.12, const Color(0xFF5AB0D9));
        d.rect(0.12, 0.35, 0.6, 0.35, const Color(0xFFE8DCC8));
        d.poly([0.08, 0.36, 0.42, 0.14, 0.76, 0.36], const Color(0xFF6B3A2A));
        d.rect(0.15, 0.25, 0.05, 0.1, const Color(0xFF6B3A2A));
        for (int k = 0; k < 4; k++) {
          d.rect(
            0.17 + k * 0.14,
            0.42,
            0.08,
            0.1,
            sin(w * 2 + k) > -0.3 ? AppColors.yellow : const Color(0xFF7A8AA0),
          );
          d.rect(0.17 + k * 0.14, 0.56, 0.08, 0.1, const Color(0xFF7A8AA0));
        }
        d.circle(0.92, 0.55, 0.12, const Color(0xFF2E6B3A));
        d.circle(0.05, 0.58, 0.1, const Color(0xFF2E6B3A));
        for (int k = 0; k < 5; k++) {
          final rr = Random(k);
          d.circle(
            rr.nextDouble(),
            rr.nextDouble() * 0.3,
            0.008,
            Colors.white.withValues(alpha: (sin(w * 3 + k) + 1) / 2),
          );
        }

      // ------------------ YATLAR ------------------
      case 'y1':
      case 'y2':
      case 'y3':
        d.vgrad(0, 0.6, const Color(0xFF4FB3E8), const Color(0xFFBFE9FF));
        d.circle(0.15, 0.15, 0.07, const Color(0xFFFFE08A));
        final bob = sin(w * 2) * 0.015;
        d.vgrad(0.62, 1, const Color(0xFF1F7FB0), const Color(0xFF0B3A5A));
        final big = id == 'y3'
            ? 1.0
            : id == 'y2'
            ? 0.85
            : 0.65;
        final x0 = 0.5 - 0.45 * big, x1 = 0.5 + 0.45 * big;
        d.poly([
          x0,
          0.55 + bob,
          x1 + 0.04,
          0.55 + bob,
          x1 - 0.04,
          0.68 + bob,
          x0 + 0.06,
          0.68 + bob,
        ], Colors.white);
        d.rect(x0 + 0.02, 0.6 + bob, (x1 - x0), 0.02, const Color(0xFF1E3A8A));
        d.poly([
          x0 + 0.12,
          0.55 + bob,
          x0 + 0.18,
          0.45 + bob,
          x1 - 0.12,
          0.45 + bob,
          x1 - 0.05,
          0.55 + bob,
        ], const Color(0xFFF2F2F2));
        d.rect(
          x0 + 0.2,
          0.47 + bob,
          (x1 - x0) * 0.45,
          0.04,
          const Color(0xFF223344),
        );
        if (id != 'y1') {
          d.poly([
            x0 + 0.24,
            0.45 + bob,
            x0 + 0.28,
            0.37 + bob,
            x1 - 0.2,
            0.37 + bob,
            x1 - 0.14,
            0.45 + bob,
          ], const Color(0xFFE6E6E6));
          d.rect(
            x0 + 0.3,
            0.39 + bob,
            (x1 - x0) * 0.3,
            0.03,
            const Color(0xFF223344),
          );
        }
        if (id == 'y3') {
          d.oval(x0 + 0.12, 0.54 + bob, 0.12, 0.03, const Color(0xFF444444));
          d.text('H', x0 + 0.105, 0.515 + bob, 0.05, Colors.white);
          d.line(
            x1 - 0.25,
            0.37 + bob,
            x1 - 0.25,
            0.25 + bob,
            Colors.grey,
            1.5,
          );
        }
        for (int k = 0; k < 6; k++) {
          final x = ((t + k / 6) % 1);
          d.line(
            x,
            0.72 + (k % 3) * 0.08,
            x + 0.07,
            0.72 + (k % 3) * 0.08,
            Colors.white38,
            1.5,
          );
        }

      // ------------------ JETLER ------------------
      case 'j1':
      case 'j2':
        d.vgrad(0, 1, const Color(0xFF3A7BD5), const Color(0xFFBFE3FF));
        for (int k = 0; k < 3; k++) {
          final x = 1.1 - ((t * (0.5 + k * 0.2) + k / 3) % 1) * 1.3;
          d.oval(x, 0.2 + k * 0.28, 0.25, 0.08, Colors.white70);
          d.oval(x + 0.06, 0.18 + k * 0.28, 0.15, 0.08, Colors.white70);
        }
        final long = id == 'j2' ? 0.82 : 0.62;
        final y = 0.5 + sin(w * 2) * 0.03;
        final x0 = 0.5 - long / 2;
        d.rrect(x0, y - 0.06, long, 0.12, 12, Colors.white);
        d.poly([
          x0 + long,
          y - 0.06,
          x0 + long + 0.08,
          y,
          x0 + long,
          y + 0.06,
        ], Colors.white);
        d.poly([
          x0 + 0.02,
          y - 0.04,
          x0 - 0.02,
          y - 0.22,
          x0 + 0.08,
          y - 0.04,
        ], const Color(0xFF1E3A8A));
        d.poly([
          x0 + long * 0.35,
          y + 0.02,
          x0 + long * 0.25,
          y + 0.25,
          x0 + long * 0.5,
          y + 0.02,
        ], const Color(0xFFDDDDDD));
        for (double wx = x0 + 0.12; wx < x0 + long - 0.06; wx += 0.06) {
          d.circle(wx, y - 0.01, 0.018, const Color(0xFF223344));
        }
        d.rect(x0, y + 0.015, long, 0.015, AppColors.accent);
        if (id == 'j2')
          d.rrect(x0 + 0.06, y + 0.05, 0.12, 0.05, 6, const Color(0xFFBBBBBB));

      // ------------------ ADALAR ------------------
      case 'i1':
      case 'i2':
        d.vgrad(0, 0.45, const Color(0xFF5EC4F2), const Color(0xFFBDEBFF));
        d.vgrad(0.4, 1, const Color(0xFF2BB5D9), const Color(0xFF0F6B9A));
        for (int k = 0; k < 8; k++) {
          final x = ((t * 0.6 + k / 8) % 1);
          d.line(
            x,
            0.5 + (k % 4) * 0.12,
            x + 0.06,
            0.5 + (k % 4) * 0.12,
            Colors.white38,
            1.2,
          );
        }
        final big = id == 'i2';
        d.oval(
          0.5,
          0.7,
          big ? 0.9 : 0.6,
          big ? 0.38 : 0.28,
          const Color(0xFFF2D59A),
        );
        d.oval(
          0.5,
          0.66,
          big ? 0.75 : 0.45,
          big ? 0.28 : 0.18,
          const Color(0xFF5BBF6A),
        );
        d.palm(0.4, 0.66, 0.35, sin(w * 2));
        d.palm(0.6, 0.66, 0.3, sin(w * 2 + 1));
        if (big) {
          for (int k = 0; k < 3; k++) {
            d.rect(0.2 + k * 0.08, 0.55, 0.06, 0.06, Colors.white);
            d.poly([
              0.195 + k * 0.08,
              0.55,
              0.23 + k * 0.08,
              0.51,
              0.265 + k * 0.08,
              0.55,
            ], AppColors.red);
          }
          d.rect(0.7, 0.75, 0.2, 0.02, const Color(0xFF7A5230));
          d.poly([
            0.78,
            0.72 + sin(w * 2) * 0.01,
            0.9,
            0.72 + sin(w * 2) * 0.01,
            0.88,
            0.76,
            0.8,
            0.76,
          ], Colors.white);
        } else {
          d.rect(0.55, 0.62, 0.15, 0.015, const Color(0xFF7A5230));
          d.rect(0.62, 0.58, 0.07, 0.05, Colors.white);
        }

      // ------------------ EKİPMAN ------------------
      case 'cam':
        d.rect(0, 0.85, 1, 0.15, Colors.black26);
        d.line(0.5, 0.88, 0.5, 0.55, const Color(0xFF333333), 3);
        d.line(0.5, 0.65, 0.3, 0.92, const Color(0xFF333333), 3);
        d.line(0.5, 0.65, 0.7, 0.92, const Color(0xFF333333), 3);
        d.rrect(0.25, 0.32, 0.45, 0.24, 4, const Color(0xFF1A1A1A));
        d.rrect(0.68, 0.36, 0.18, 0.16, 3, const Color(0xFF2A2A2A));
        d.circle(0.86, 0.44, 0.08, const Color(0xFF111111));
        d.circle(
          0.86,
          0.44,
          0.05,
          const Color(0xFF3A6AB0).withValues(alpha: 0.6 + 0.4 * sin(w * 2)),
        );
        for (final x in [0.33, 0.5]) {
          d.circle(x, 0.24, 0.09, const Color(0xFF2A2A2A));
          final o = Offset(x * d.W, 0.24 * d.H);
          canvas.drawLine(
            o,
            o + Offset(cos(w * 3), sin(w * 3)) * d.H * 0.08,
            Paint()
              ..color = Colors.white38
              ..strokeWidth = 1.5,
          );
        }
        d.circle(
          0.3,
          0.38,
          0.02,
          sin(w * 8) > 0 ? AppColors.red : Colors.black,
        );
      case 'edit':
        d.rect(0, 0.75, 1, 0.25, const Color(0xFF2A2A33));
        for (int k = 0; k < 3; k++) {
          final x = 0.06 + k * 0.31;
          d.rrect(x, 0.2, 0.28, 0.32, 3, const Color(0xFF111111));
          d.rect(
            x + 0.02,
            0.23,
            0.24,
            0.26,
            [
              AppColors.purple,
              AppColors.cyan,
              AppColors.orange,
            ][k].withValues(alpha: 0.6),
          );
          d.rect(x + 0.12, 0.52, 0.04, 0.1, const Color(0xFF111111));
        }
        d.rrect(0.1, 0.64, 0.8, 0.1, 3, const Color(0xFF1A1A22));
        for (int k = 0; k < 5; k++) {
          d.rect(
            0.12 + k * 0.15,
            0.66,
            0.12,
            0.025,
            [
              AppColors.cyan,
              AppColors.green,
              AppColors.yellow,
              AppColors.pink,
              AppColors.blue,
            ][k],
          );
          d.rect(
            0.14 + k * 0.13,
            0.7,
            0.1,
            0.025,
            [
              AppColors.orange,
              AppColors.purple,
              AppColors.cyan,
              AppColors.green,
              AppColors.red,
            ][k],
          );
        }
        final px = 0.12 + (t % 1) * 0.76;
        d.line(px, 0.63, px, 0.75, AppColors.red, 2);
      case 'jib':
        d.rect(0, 0.88, 1, 0.12, Colors.black26);
        final ang = -0.6 + sin(w) * 0.35;
        final pv = Offset(0.3 * d.W, 0.6 * d.H);
        final tip = pv + Offset(cos(ang), sin(ang)) * d.W * 0.6;
        final back = pv - Offset(cos(ang), sin(ang)) * d.W * 0.2;
        canvas.drawLine(
          back,
          tip,
          Paint()
            ..color = const Color(0xFFDDDDDD)
            ..strokeWidth = 4,
        );
        canvas.drawRect(
          Rect.fromCenter(center: back, width: 14, height: 14),
          Paint()..color = const Color(0xFF555555),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: tip + const Offset(0, 6),
              width: 18,
              height: 12,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = const Color(0xFF111111),
        );
        d.line(0.3, 0.6, 0.3, 0.9, const Color(0xFF555555), 4);
        d.line(0.3, 0.9, 0.15, 0.95, const Color(0xFF555555), 3);
        d.line(0.3, 0.9, 0.45, 0.95, const Color(0xFF555555), 3);
      case 'drone':
        d.vgrad(0, 1, const Color(0xFF5EA8E0), const Color(0xFFBFE3FF));
        d.poly([
          0,
          1,
          0.3,
          0.7,
          0.55,
          0.85,
          0.8,
          0.65,
          1,
          0.8,
          1,
          1,
        ], const Color(0xFF4FA36B));
        final y = 0.38 + sin(w * 2) * 0.05;
        d.rrect(0.38, y - 0.05, 0.24, 0.1, 6, const Color(0xFF333333));
        d.line(0.2, y - 0.08, 0.8, y + 0.08, const Color(0xFF444444), 3);
        d.line(0.2, y + 0.08, 0.8, y - 0.08, const Color(0xFF444444), 3);
        for (final p in [
          [0.2, -0.08],
          [0.8, 0.08],
          [0.2, 0.08],
          [0.8, -0.08],
        ]) {
          final spin = cos(w * 40 + p[0] * 10).abs();
          d.oval(
            p[0],
            y + p[1] - 0.03,
            0.2 * spin + 0.02,
            0.025,
            Colors.white70,
          );
        }
        d.circle(0.5, y + 0.07, 0.03, const Color(0xFF111111));
        d.circle(
          0.43,
          y,
          0.012,
          sin(w * 10) > 0 ? AppColors.green : AppColors.red,
        );
      case 'sound':
        d.rect(0, 0, 1, 1, const Color(0xFF1A1428));
        for (int k = 0; k < 10; k++) {
          final h = 0.1 + 0.3 * ((sin(w * 6 + k * 0.8) + 1) / 2);
          d.rect(
            0.08 + k * 0.085,
            0.45 - h,
            0.06,
            h,
            Color.lerp(AppColors.green, AppColors.red, h / 0.4)!,
          );
        }
        d.rrect(0.05, 0.55, 0.9, 0.38, 4, const Color(0xFF2A2A33));
        for (int k = 0; k < 8; k++) {
          final x = 0.1 + k * 0.105;
          d.line(x, 0.6, x, 0.88, Colors.black54, 2);
          final ky = 0.65 + ((sin(w * 2 + k) + 1) / 2) * 0.18;
          d.rrect(x - 0.025, ky, 0.05, 0.04, 2, Colors.white70);
        }
      case 'ob':
        d.vgrad(0, 0.75, const Color(0xFF7AA6D9), const Color(0xFFCFE3F5));
        d.rect(0, 0.78, 1, 0.22, const Color(0xFF555560));
        d.rrect(0.06, 0.38, 0.62, 0.42, 4, Colors.white);
        d.rrect(0.66, 0.5, 0.26, 0.3, 4, const Color(0xFFE6E6E6));
        d.rect(0.72, 0.53, 0.16, 0.12, const Color(0xFF9FD3F5));
        d.rect(0.06, 0.6, 0.62, 0.05, AppColors.accent);
        d.text('CANLI', 0.12, 0.47, 0.09, AppColors.accent);
        d.circle(0.2, 0.82, 0.08, Colors.black);
        d.circle(0.78, 0.82, 0.08, Colors.black);
        d.line(0.4, 0.38, 0.4, 0.26, Colors.grey, 2);
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(0.4 * d.W, 0.2 * d.H),
            width: 0.24 * d.W,
            height: 0.22 * d.H,
          ),
          pi + sin(w) * 0.4,
          pi,
          false,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        for (int k = 0; k < 2; k++) {
          final r = ((t * 2 + k / 2) % 1) * 0.3;
          canvas.drawCircle(
            Offset(0.4 * d.W, 0.12 * d.H),
            r * d.H,
            Paint()
              ..color = AppColors.cyan.withValues(alpha: 1 - r / 0.3)
              ..style = PaintingStyle.stroke,
          );
        }
      case 'led':
        d.rect(0, 0, 1, 1, const Color(0xFF0A0A14));
        for (int y = 0; y < 8; y++) {
          for (int x = 0; x < 12; x++) {
            final v = sin(w * 2 + x * 0.6 + y * 0.4);
            final col = HSVColor.fromAHSV(
              1,
              ((x * 20 + y * 15 + t * 360) % 360),
              0.7,
              0.5 + 0.5 * v.abs(),
            ).toColor();
            d.rect(0.03 + x * 0.08, 0.05 + y * 0.09, 0.07, 0.08, col);
          }
        }
        d.rect(0, 0.8, 1, 0.2, const Color(0xFF111118));
      case 'vfx':
        d.rect(0, 0, 1, 1, const Color(0xFF1EB85A));
        final o = Offset(0.5 * d.W, 0.45 * d.H);
        final r = d.H * 0.28;
        final pp = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawCircle(o, r, pp);
        for (int k = 0; k < 4; k++) {
          final ph = (w + k * pi / 4) % pi;
          canvas.drawOval(
            Rect.fromCenter(
              center: o,
              width: 2 * r * cos(ph).abs(),
              height: 2 * r,
            ),
            pp,
          );
        }
        for (final f in [-0.5, 0.0, 0.5]) {
          final yy = o.dy + f * r;
          final hw = sqrt(max(0, r * r - (f * r) * (f * r)));
          canvas.drawLine(Offset(o.dx - hw, yy), Offset(o.dx + hw, yy), pp);
        }
        d.person(
          0.18,
          0.98,
          0.45,
          shirt: const Color(0xFF222222),
          armR: 1.5,
          armL: 0.4,
        );
        for (int k = 0; k < 6; k++) {
          d.circle(0.12 + k * 0.03, 0.4 + (k % 2) * 0.12, 0.012, Colors.white);
        }
      case 'tower':
        d.vgrad(0, 1, const Color(0xFF0F1B3D), const Color(0xFF3A4A7A));
        d.poly([0.42, 0.95, 0.5, 0.2, 0.58, 0.95], Colors.transparent);
        d.line(0.42, 0.95, 0.5, 0.25, const Color(0xFFDD4444), 3);
        d.line(0.58, 0.95, 0.5, 0.25, const Color(0xFFDD4444), 3);
        for (double y = 0.35; y < 0.95; y += 0.1) {
          final hw = (y - 0.25) / 0.7 * 0.08;
          d.line(0.5 - hw, y, 0.5 + hw, y + 0.05, Colors.white70, 1.5);
          d.line(0.5 + hw, y, 0.5 - hw, y + 0.05, Colors.white70, 1.5);
        }
        d.circle(
          0.5,
          0.22,
          0.03,
          sin(w * 6) > 0 ? AppColors.red : const Color(0xFF551111),
        );
        for (int k = 0; k < 3; k++) {
          final r = ((t * 2 + k / 3) % 1) * 0.45;
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(0.5 * d.W, 0.22 * d.H),
              radius: r * d.H,
            ),
            -pi * 0.85,
            pi * 0.7,
            false,
            Paint()
              ..color = AppColors.cyan.withValues(alpha: 1 - r / 0.45)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      case 'sat':
        d.vgrad(0, 1, const Color(0xFF02030A), const Color(0xFF15103A));
        for (int k = 0; k < 20; k++) {
          final rr = Random(k);
          d.circle(
            rr.nextDouble(),
            rr.nextDouble() * 0.7,
            0.008,
            Colors.white70,
          );
        }
        d.oval(0.5, 1.05, 1.4, 0.45, const Color(0xFF2B6CB0));
        final ang = w;
        final sx = 0.5 + cos(ang) * 0.35, sy = 0.4 + sin(ang) * 0.15;
        d.rect(sx - 0.03, sy - 0.03, 0.06, 0.06, const Color(0xFFCCCCCC));
        d.rect(sx - 0.14, sy - 0.015, 0.1, 0.03, const Color(0xFF2A4A8A));
        d.rect(sx + 0.04, sy - 0.015, 0.1, 0.03, const Color(0xFF2A4A8A));
        canvas.drawArc(
          Rect.fromCenter(
            center: Offset(0.25 * d.W, 0.82 * d.H),
            width: 0.26 * d.W,
            height: 0.22 * d.H,
          ),
          -pi * 0.9,
          pi,
          false,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
        d.line(
          0.25,
          0.82,
          sx,
          sy,
          AppColors.cyan.withValues(alpha: 0.3 + 0.3 * sin(w * 8)),
          1,
        );

      // ------------------ İŞLETMELER ------------------
      case 'radyo':
        d.rect(0, 0, 1, 1, const Color(0xFF3A1430));
        d.rrect(
          0.3,
          0.15,
          0.4,
          0.12,
          6,
          sin(w * 3) > -0.5 ? AppColors.red : const Color(0xFF551111),
        );
        d.text('ON AIR', 0.5, 0.16, 0.09, Colors.white, center: true);
        d.rrect(0.42, 0.35, 0.16, 0.3, 10, const Color(0xFF444444));
        for (double y = 0.38; y < 0.62; y += 0.04) {
          d.line(0.44, y, 0.56, y, Colors.black45, 1);
        }
        d.line(0.5, 0.65, 0.5, 0.85, const Color(0xFF555555), 3);
        d.rect(0.38, 0.85, 0.24, 0.04, const Color(0xFF555555));
        for (int k = 0; k < 3; k++) {
          final r = ((t * 2 + k / 3) % 1) * 0.3;
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(0.5 * d.W, 0.5 * d.H),
              radius: (0.15 + r) * d.H,
            ),
            -0.6,
            1.2,
            false,
            Paint()
              ..color = AppColors.pink.withValues(alpha: 1 - r / 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          canvas.drawArc(
            Rect.fromCircle(
              center: Offset(0.5 * d.W, 0.5 * d.H),
              radius: (0.15 + r) * d.H,
            ),
            pi - 0.6,
            1.2,
            false,
            Paint()
              ..color = AppColors.pink.withValues(alpha: 1 - r / 0.3)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      case 'gazete':
        d.rect(0, 0, 1, 1, const Color(0xFF2A3445));
        for (int k = 0; k < 3; k++) {
          final x = ((t * 1.2 + k / 3) % 1) * 1.3 - 0.2;
          d.rrect(x, 0.25 + k * 0.05, 0.36, 0.5, 2, const Color(0xFFF2EEE4));
          d.rect(x + 0.03, 0.29 + k * 0.05, 0.3, 0.06, Colors.black87);
          for (int l = 0; l < 5; l++) {
            d.rect(
              x + 0.03,
              0.4 + k * 0.05 + l * 0.06,
              l == 0 ? 0.14 : 0.3,
              0.02,
              Colors.black38,
            );
          }
          d.rect(x + 0.19, 0.4 + k * 0.05, 0.14, 0.1, const Color(0xFF9AA5B5));
        }
      case 'akademi':
        d.vgrad(0, 0.8, const Color(0xFF6E8FC4), const Color(0xFFDDE6F5));
        d.rect(0, 0.8, 1, 0.2, const Color(0xFF6BBF59));
        d.rect(0.15, 0.4, 0.7, 0.42, const Color(0xFFE8DCC8));
        d.poly([0.1, 0.42, 0.5, 0.2, 0.9, 0.42], const Color(0xFF8C3A3A));
        for (int k = 0; k < 4; k++) {
          d.rect(0.22 + k * 0.16, 0.45, 0.04, 0.37, Colors.white);
        }
        d.rect(0.45, 0.62, 0.1, 0.2, const Color(0xFF6B3A2A));
        final cy = 0.12 + (sin(w * 2).abs()) * 0.05;
        d.poly([
          0.38,
          cy + 0.04,
          0.5,
          cy,
          0.62,
          cy + 0.04,
          0.5,
          cy + 0.08,
        ], const Color(0xFF111111));
        d.line(0.6, cy + 0.04, 0.62, cy + 0.12, AppColors.yellow, 1.5);
      case 'ajans':
        d.vgrad(0, 0.85, const Color(0xFF1A1035), const Color(0xFF3A2A6A));
        d.line(0.35, 0.9, 0.35, 0.6, const Color(0xFF555555), 3);
        d.line(0.65, 0.9, 0.65, 0.6, const Color(0xFF555555), 3);
        d.rrect(0.08, 0.15, 0.84, 0.45, 4, const Color(0xFF111111));
        final ad = (t * 3).floor() % 3;
        d.rect(
          0.1,
          0.17,
          0.8,
          0.41,
          [AppColors.accent, AppColors.cyan, AppColors.yellow][ad],
        );
        d.text(
          ['%50 İNDİRİM', 'YENİ SEZON', 'HEMEN AL'][ad],
          0.5,
          0.3,
          0.11,
          Colors.white,
          center: true,
        );
        for (int k = 0; k < 4; k++) {
          d.circle(
            0.15 + k * 0.23,
            0.12,
            0.025,
            AppColors.yellow.withValues(alpha: (sin(w * 4 + k) + 1) / 2),
          );
        }
      case 'muzik':
        d.rect(0, 0, 1, 1, const Color(0xFF2A1A0A));
        final o = Offset(0.45 * d.W, 0.5 * d.H);
        canvas.drawCircle(
          o,
          d.H * 0.38,
          Paint()..color = const Color(0xFF111111),
        );
        for (double r = 0.12; r < 0.38; r += 0.05) {
          canvas.drawCircle(
            o,
            d.H * r,
            Paint()
              ..color = Colors.white10
              ..style = PaintingStyle.stroke,
          );
        }
        canvas.drawCircle(o, d.H * 0.1, Paint()..color = AppColors.yellow);
        final hl = w * 3;
        canvas.drawLine(
          o + Offset(cos(hl), sin(hl)) * d.H * 0.15,
          o + Offset(cos(hl), sin(hl)) * d.H * 0.33,
          Paint()
            ..color = Colors.white24
            ..strokeWidth = 3,
        );
        d.line(0.88, 0.1, 0.72, 0.42, const Color(0xFFCCCCCC), 3);
        for (int k = 0; k < 3; k++) {
          final y = 0.8 - ((t * 2 + k / 3) % 1) * 0.7;
          d.text(
            '♪',
            0.82 + sin(w * 3 + k) * 0.04,
            y,
            0.12,
            AppColors.yellow.withValues(alpha: 0.8),
          );
        }
      case 'plato':
        d.vgrad(0, 0.75, const Color(0xFF5E8BC4), const Color(0xFFCFE3F5));
        d.rect(0, 0.78, 1, 0.22, const Color(0xFF555560));
        for (int k = 0; k < 2; k++) {
          final x = 0.05 + k * 0.48;
          d.rect(x, 0.4, 0.42, 0.4, const Color(0xFFB0B8C4));
          canvas.drawArc(
            Rect.fromLTWH(x * d.W, 0.28 * d.H, 0.42 * d.W, 0.24 * d.H),
            pi,
            pi,
            true,
            Paint()..color = const Color(0xFF9AA2B0),
          );
          d.rect(x + 0.12, 0.55, 0.18, 0.25, const Color(0xFF3A3A44));
          d.text('${k + 1}', x + 0.21, 0.42, 0.1, Colors.black54, center: true);
        }
        final tx = ((t * 0.8) % 1) * 1.3 - 0.2;
        d.rrect(tx, 0.72, 0.18, 0.08, 2, AppColors.orange);
        d.circle(tx + 0.04, 0.81, 0.02, Colors.black);
        d.circle(tx + 0.14, 0.81, 0.02, Colors.black);
      case 'sinema':
        d.vgrad(0, 0.85, const Color(0xFF14102A), const Color(0xFF2A1A45));
        d.rect(0.1, 0.3, 0.8, 0.6, const Color(0xFF7A1530));
        d.rect(0.15, 0.15, 0.7, 0.18, const Color(0xFF222222));
        for (int k = 0; k < 14; k++) {
          final on = (k + (t * 14).floor()) % 3 != 0;
          d.circle(
            0.17 + k * 0.05,
            0.15,
            0.015,
            on ? AppColors.yellow : const Color(0xFF554411),
          );
          d.circle(
            0.17 + k * 0.05,
            0.33,
            0.015,
            on ? AppColors.yellow : const Color(0xFF554411),
          );
        }
        d.text('SİNEMA', 0.5, 0.18, 0.1, Colors.white, center: true);
        d.rect(0.4, 0.6, 0.2, 0.3, const Color(0xFF2A0A12));
        d.rect(0.15, 0.45, 0.18, 0.25, const Color(0xFFFFE6A6));
        d.rect(0.67, 0.45, 0.18, 0.25, const Color(0xFFFFE6A6));
      case 'dublaj':
        d.rect(0, 0, 1, 1, const Color(0xFF0F2A3A));
        for (int k = 0; k < 24; k++) {
          final h =
              0.05 + 0.25 * ((sin(w * 5 + k * 0.7) * sin(k * 1.3) + 1) / 2);
          d.rect(0.04 + k * 0.04, 0.5 - h / 2, 0.025, h, AppColors.cyan);
        }
        d.rrect(0.05, 0.08, 0.2, 0.12, 4, Colors.white24);
        d.text('TR', 0.15, 0.1, 0.07, Colors.white, center: true);
        d.rrect(0.75, 0.08, 0.2, 0.12, 4, Colors.white24);
        d.text('EN', 0.85, 0.1, 0.07, Colors.white, center: true);
        d.rrect(0.42, 0.68, 0.16, 0.22, 8, const Color(0xFF444444));
      case 'otel':
        d.vgrad(0, 0.55, const Color(0xFFF2A65A), const Color(0xFFFFE0A6));
        d.circle(0.8, 0.2, 0.08, const Color(0xFFFFF4C8));
        d.vgrad(0.6, 1, const Color(0xFF2BB5D9), const Color(0xFF0F6B9A));
        d.rect(0.15, 0.15, 0.45, 0.5, const Color(0xFFF5F0E6));
        for (double y = 0.19; y < 0.6; y += 0.08) {
          for (double x = 0.18; x < 0.57; x += 0.07) {
            d.rect(
              x,
              y,
              0.04,
              0.05,
              sin(w * 2 + x * 20 + y * 30) > 0
                  ? AppColors.yellow
                  : const Color(0xFF6AA0C0),
            );
          }
        }
        d.rect(0, 0.62, 1, 0.06, const Color(0xFFF2D59A));
        d.palm(0.75, 0.65, 0.4, sin(w * 2));
        for (int k = 0; k < 2; k++) {
          d.line(0.25 + k * 0.2, 0.62, 0.25 + k * 0.2, 0.52, Colors.white70, 1);
          d.poly([
            0.2 + k * 0.2,
            0.53,
            0.25 + k * 0.2,
            0.48,
            0.3 + k * 0.2,
            0.53,
          ], [AppColors.accent, AppColors.cyan][k]);
        }

      case 'steadicam':
        d.rect(0, 0.85, 1, 0.15, Colors.black26);
        final bob = sin(w * 2) * 0.02;
        d.person(
          0.42,
          0.97,
          0.75,
          shirt: const Color(0xFF333344),
          hair: 1,
          armR: 1.4,
          armL: 1.2,
        );
        d.rect(0.47, 0.42 + bob, 0.28, 0.05, const Color(0xFF555555));
        d.line(0.6, 0.45 + bob, 0.6, 0.7 + bob, const Color(0xFF777777), 3);
        d.rrect(0.66, 0.32 + bob, 0.16, 0.12, 3, const Color(0xFF1A1A1A));
        d.circle(0.84, 0.38 + bob, 0.04, const Color(0xFF3A6AB0));
        d.circle(0.6, 0.72 + bob, 0.05, const Color(0xFF444444));
      case 'k8':
        d.rect(0, 0, 1, 1, const Color(0xFF101018));
        d.rrect(0.1, 0.15, 0.8, 0.55, 6, const Color(0xFF222230));
        for (int y = 0; y < 6; y++) {
          for (int x = 0; x < 12; x++) {
            final v = (sin(w + x * 0.5 + y * 0.7) + 1) / 2;
            d.rect(
              0.13 + x * 0.062,
              0.18 + y * 0.083,
              0.058,
              0.078,
              Color.lerp(
                const Color(0xFF1E6FB0),
                const Color(0xFFFFD166),
                v,
              )!.withValues(alpha: 0.9),
            );
          }
        }
        d.text('8K', 0.5, 0.74, 0.16, AppColors.yellow, center: true);
      case 'underwater':
        d.vgrad(0, 1, const Color(0xFF1C8CB0), const Color(0xFF062A45));
        for (int k = 0; k < 6; k++) {
          final y = 0.9 - ((t * 1.5 + k / 6) % 1) * 0.9;
          d.circle(0.65 + sin(w * 3 + k) * 0.03, y, 0.015, Colors.white54);
        }
        final dx = 0.35 + sin(w) * 0.05;
        d.oval(dx, 0.55, 0.42, 0.16, const Color(0xFF222233));
        d.circle(dx + 0.18, 0.5, 0.06, const Color(0xFFF2C9A0));
        d.circle(dx + 0.19, 0.5, 0.045, const Color(0xFF9FD3F5));
        d.rrect(dx - 0.08, 0.43, 0.1, 0.05, 3, AppColors.yellow);
        d.poly([
          dx - 0.2,
          0.55,
          dx - 0.32,
          0.48 + sin(w * 6) * 0.03,
          dx - 0.32,
          0.62,
        ], const Color(0xFF111122));
        d.rrect(dx + 0.26, 0.5, 0.14, 0.1, 3, const Color(0xFF111111));
        d.circle(dx + 0.41, 0.55, 0.035, const Color(0xFF3A6AB0));
      case 'spidercam':
        d.vgrad(0, 0.55, const Color(0xFF0A1530), const Color(0xFF1A2550));
        d.rect(0, 0.55, 1, 0.45, const Color(0xFF2E8B57));
        d.line(0.5, 0.55, 0.5, 1, Colors.white54, 1);
        d.c.drawCircle(
          Offset(0.5 * d.W, 0.8 * d.H),
          d.H * 0.1,
          d.p(Colors.white54)..style = PaintingStyle.stroke,
        );
        final cx = 0.5 + sin(w) * 0.3, cy = 0.35 + cos(w * 2) * 0.08;
        for (final corner in [
          [0.0, 0.05],
          [1.0, 0.05],
          [0.0, 0.5],
          [1.0, 0.5],
        ]) {
          d.line(corner[0], corner[1], cx, cy, Colors.white38, 1);
        }
        d.rrect(cx - 0.05, cy - 0.04, 0.1, 0.08, 3, const Color(0xFF222222));
        d.circle(cx, cy + 0.05, 0.03, const Color(0xFF3A6AB0));
        d.circle(
          cx + 0.04,
          cy - 0.03,
          0.012,
          sin(w * 8) > 0 ? AppColors.red : const Color(0xFF551111),
        );
      case 'heli':
        d.vgrad(0, 1, const Color(0xFF6EA8E0), const Color(0xFFF2B27A));
        d.poly([
          0,
          1,
          0.25,
          0.7,
          0.5,
          0.85,
          0.75,
          0.65,
          1,
          0.8,
          1,
          1,
        ], const Color(0xFF3E7A4A));
        final hy = 0.38 + sin(w * 2) * 0.04;
        d.oval(0.45, hy, 0.36, 0.2, const Color(0xFF1E3A8A));
        d.oval(0.53, hy - 0.01, 0.14, 0.12, const Color(0xFF9FD3F5));
        d.rect(0.12, hy - 0.015, 0.2, 0.03, const Color(0xFF1E3A8A));
        d.circle(0.12, hy, 0.035, const Color(0xFF555555));
        final blade = cos(w * 40).abs();
        d.line(
          0.45 - 0.35 * blade,
          hy - 0.12,
          0.45 + 0.35 * blade,
          hy - 0.12,
          Colors.black54,
          2,
        );
        d.line(0.45, hy - 0.1, 0.45, hy - 0.13, Colors.black, 2);
        d.line(0.4, hy + 0.1, 0.4, hy + 0.14, Colors.black54, 1.5);
        d.line(0.3, hy + 0.14, 0.58, hy + 0.14, Colors.black54, 2);
        d.rrect(0.5, hy + 0.08, 0.08, 0.05, 2, Colors.black);
      case 'imax':
        d.rect(0, 0, 1, 1, const Color(0xFF07060F));
        final scr = Rect.fromLTWH(
          0.06 * d.W,
          0.06 * d.H,
          0.88 * d.W,
          0.52 * d.H,
        );
        d.c.drawRect(
          scr,
          Paint()
            ..shader = LinearGradient(
              colors: [
                const Color(0xFF1E3A8A),
                Color.lerp(
                  const Color(0xFF6C9BFF),
                  Colors.white,
                  (sin(w) + 1) / 4,
                )!,
              ],
            ).createShader(scr),
        );
        d.circle(0.7, 0.3, 0.12, const Color(0xFFE07A4F));
        d.text('IMAX', 0.5, 0.62, 0.14, Colors.white, center: true);
        for (int row = 0; row < 2; row++) {
          for (double x = 0.04; x < 1; x += 0.08) {
            d.rrect(
              x,
              0.8 + row * 0.09,
              0.06,
              0.07,
              3,
              const Color(0xFF2A1A3A),
            );
          }
        }
      case 'atmos':
        d.rect(0, 0, 1, 1, const Color(0xFF0E0A1A));
        for (final pos in [
          [0.15, 0.3],
          [0.85, 0.3],
          [0.15, 0.75],
          [0.85, 0.75],
          [0.5, 0.12],
        ]) {
          d.rrect(
            pos[0] - 0.06,
            pos[1] - 0.08,
            0.12,
            0.16,
            3,
            const Color(0xFF333344),
          );
          d.circle(pos[0], pos[1], 0.04, const Color(0xFF111111));
        }
        for (int k = 0; k < 3; k++) {
          final r = ((t * 2 + k / 3) % 1) * 0.4;
          d.c.drawCircle(
            Offset(0.5 * d.W, 0.55 * d.H),
            r * d.H,
            Paint()
              ..color = AppColors.purple.withValues(alpha: 1 - r / 0.4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
        d.text('ATMOS', 0.5, 0.5, 0.09, Colors.white, center: true);
      case 'uplink':
        d.vgrad(0, 0.75, const Color(0xFF0F1B3D), const Color(0xFF3A4A7A));
        d.rect(0, 0.78, 1, 0.22, const Color(0xFF444450));
        d.rrect(0.1, 0.5, 0.65, 0.3, 4, Colors.white);
        d.rect(0.1, 0.62, 0.65, 0.04, AppColors.cyan);
        d.circle(0.22, 0.82, 0.07, Colors.black);
        d.circle(0.65, 0.82, 0.07, Colors.black);
        d.c.drawArc(
          Rect.fromCenter(
            center: Offset(0.45 * d.W, 0.38 * d.H),
            width: 0.36 * d.W,
            height: 0.3 * d.H,
          ),
          pi + 0.3 + sin(w) * 0.15,
          pi,
          true,
          d.p(const Color(0xFFDDDDDD)),
        );
        d.line(0.45, 0.5, 0.45, 0.4, Colors.grey, 3);
        for (int k = 0; k < 3; k++) {
          final r = ((t * 2 + k / 3) % 1) * 0.35;
          d.c.drawArc(
            Rect.fromCircle(
              center: Offset(0.55 * d.W, 0.25 * d.H),
              radius: r * d.H,
            ),
            -pi * 0.6,
            pi * 0.5,
            false,
            Paint()
              ..color = AppColors.yellow.withValues(alpha: 1 - r / 0.35)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      case 'mocap':
        d.rect(0, 0, 1, 1, const Color(0xFF101418));
        for (double x = 0; x < 1; x += 0.08) {
          d.line(
            x,
            0,
            x,
            1,
            const Color(0xFF1EB85A).withValues(alpha: 0.15),
            1,
          );
        }
        final ar = 1.5 + sin(w * 3) * 0.8;
        d.person(
          0.3,
          0.95,
          0.75,
          shirt: const Color(0xFF111111),
          pants: const Color(0xFF111111),
          armR: ar,
          armL: 1.0,
        );
        for (final pt in [
          [0.3, 0.3],
          [0.25, 0.55],
          [0.35, 0.55],
          [0.27, 0.8],
          [0.33, 0.8],
        ]) {
          d.circle(pt[0], pt[1], 0.02, Colors.white);
        }
        final skel = AppColors.cyan;
        d.circle(0.72, 0.3, 0.06, skel);
        d.line(0.72, 0.36, 0.72, 0.62, skel, 3);
        d.line(
          0.72,
          0.42,
          0.72 + sin(ar) * 0.12,
          0.42 + cos(ar) * 0.12,
          skel,
          3,
        );
        d.line(0.72, 0.42, 0.62, 0.54, skel, 3);
        d.line(0.72, 0.62, 0.66, 0.85, skel, 3);
        d.line(0.72, 0.62, 0.78, 0.85, skel, 3);
      case 'videom':
        d.vgrad(0, 1, const Color(0xFF3A0F2A), const Color(0xFF1A0A20));
        d.rrect(0.3, 0.08, 0.4, 0.84, 10, const Color(0xFF111111));
        d.rrect(0.33, 0.13, 0.34, 0.68, 6, const Color(0xFFFF4D6D));
        d.poly([0.45, 0.35, 0.45, 0.55, 0.58, 0.45], Colors.white);
        for (int k = 0; k < 4; k++) {
          final y = 0.8 - ((t * 1.5 + k / 4) % 1) * 0.7;
          final x = 0.75 + sin(w * 3 + k) * 0.05;
          d.text(
            k.isEven ? '♥' : '★',
            x,
            y,
            0.1,
            Colors.white.withValues(alpha: 0.8),
          );
        }
        d.text(
          '${(1000 + (t * 9000)).round()}',
          0.12,
          0.2,
          0.08,
          Colors.white70,
        );
      case 'pazar':
        d.vgrad(0, 1, const Color(0xFF1A2A45), const Color(0xFF0A1220));
        for (int k = 0; k < 3; k++) {
          final x = 0.08 + k * 0.3;
          d.rrect(
            x,
            0.25 + (k == 1 ? -0.08 : 0),
            0.26,
            0.42,
            6,
            const Color(0xFF111111),
          );
          d.rect(
            x + 0.02,
            0.28 + (k == 1 ? -0.08 : 0),
            0.22,
            0.32,
            [
              AppColors.blue,
              AppColors.accent,
              AppColors.green,
            ][k].withValues(alpha: 0.5 + 0.3 * sin(w * 2 + k)),
          );
          d.rect(
            x + 0.11,
            0.67 + (k == 1 ? -0.08 : 0),
            0.04,
            0.1,
            const Color(0xFF333333),
          );
        }
        d.text('SATILIK', 0.5, 0.8, 0.1, AppColors.yellow, center: true);
      default:
        d.circle(0.5, 0.5, 0.25, color);
    }
  }

  void _shine(Draw d, double t) {
    final x = ((t * 1.5) % 1.6) - 0.3;
    d.poly([
      x,
      0,
      x + 0.12,
      0,
      x - 0.08,
      1,
      x - 0.2,
      1,
    ], Colors.white.withValues(alpha: 0.12));
  }

  @override
  bool shouldRepaint(covariant _ItemPainter old) =>
      old.id != id || old.color != color;
}

/// Kişi portresi: aynı [seed] her zaman aynı görünür.
class PersonAvatar extends StatelessWidget {
  final int seed;
  final Color color;
  final double size;
  final IconData? badgeIcon;

  /// Kişinin adı: görünüm (kadın/erkek) isme uyar
  final String? name;
  const PersonAvatar({
    super.key,
    required this.seed,
    required this.color,
    this.size = 48,
    this.badgeIcon,
    this.name,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        ClipOval(
          child: CustomPaint(
            size: Size(size, size),
            painter: _AvatarPainter(seed, color, name == null ? -1 : genderOfName(name!)),
          ),
        ),
        if (badgeIcon != null)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.panel, width: 2),
              ),
              child: Icon(badgeIcon, size: size * 0.22, color: Colors.white),
            ),
          ),
      ],
    ),
  );
}

class _AvatarPainter extends CustomPainter {
  final int seed;
  final Color color;
  final int gender;
  _AvatarPainter(this.seed, this.color, this.gender);
  @override
  void paint(Canvas canvas, Size size) {
    final d = Draw(canvas, size);
    final r = Random(seed);
    d.vgrad(
      0,
      1,
      Color.lerp(color, Colors.white, 0.15)!,
      Color.lerp(color, Colors.black, 0.4)!,
    );
    const shirts = [
      AppColors.cyan,
      AppColors.pink,
      AppColors.yellow,
      AppColors.purple,
      AppColors.green,
      AppColors.orange,
      AppColors.blue,
      Color(0xFF2A2440),
    ];
    final female = gender == 1 || (gender < 0 && r.nextBool());
    d.person(
      0.5,
      1.85,
      1.75,
      shirt: shirts[r.nextInt(shirts.length)],
      skin: r.nextInt(4),
      hair: r.nextInt(5),
      longHair: female && r.nextInt(3) > 0,
      gender: female ? 1 : 0,
      look: seed.abs(),
      sunglasses: r.nextInt(6) == 0,
      legsHidden: true,
    );
  }

  @override
  bool shouldRepaint(covariant _AvatarPainter old) =>
      old.seed != seed || old.color != color || old.gender != gender;
}
