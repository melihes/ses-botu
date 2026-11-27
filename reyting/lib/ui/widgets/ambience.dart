import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/calendar.dart';
import '../../engine/game.dart';
import 'common.dart';

/// Sahnenin ortamı: oyundaki saat, mevsim ve süren özel günler.
class Ambience {
  final double hour; // 0..24
  final TvSeason season;
  final Set<String> holidays;
  const Ambience(this.hour, this.season, this.holidays);

  /// Önizleme/test için zorla ortam
  static Ambience? debug;

  static Ambience of(BuildContext context) {
    if (debug != null) return debug!;
    final g = context.getInheritedWidgetOfExactType<GameScope>()?.notifier;
    if (g == null) return const Ambience(14, TvSeason.bahar, {});
    return Ambience(
      g.dayProgress * 24,
      g.season,
      {for (final (d, _) in g.activeSpecialDays) d.id},
    );
  }

  /// Saate göre ışık: (renk, yoğunluk)
  (Color, double) get light {
    final h = hour;
    if (h < 5 || h >= 21) return (const Color(0xFF0B1240), 0.42); // gece
    if (h < 7) return (const Color(0xFF6A3D7A), 0.24 * (7 - h) / 2 + 0.08); // şafak
    if (h < 9) return (const Color(0xFFFFB86B), 0.10); // sabah
    if (h < 17) return (Colors.transparent, 0.0); // gündüz
    if (h < 19) return (const Color(0xFFFF8A4C), 0.12 + (h - 17) * 0.04); // akşamüstü
    return (const Color(0xFF3A2A6B), 0.22 + (h - 19) * 0.08); // akşam → gece
  }

  bool get isNight => hour < 5 || hour >= 20;
}

/// Saate göre ışık: dekorun üstüne, karakterlerin altına çizilir
/// (stüdyo ışıkları kişileri aydınlatır, arka plan kararır).
class LightPainter extends CustomPainter {
  final Ambience a;
  LightPainter(this.a);
  @override
  void paint(Canvas c, Size s) {
    final (col, k) = a.light;
    if (k <= 0) return;
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..color = col.withValues(alpha: k));
    // kenarlar biraz daha koyu (göz alışkanlığı: ortası aydınlık)
    c.drawRect(
      r,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [Colors.transparent, Colors.black.withValues(alpha: k * 0.5)],
        ).createShader(r),
    );
    if (a.isNight) {
      // gece: stüdyo spotu ortayı aydınlatır
      c.drawCircle(
        Offset(s.width / 2, s.height * 0.55),
        s.width * 0.45,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0xFFFFF1C1).withValues(alpha: 0.18), Colors.transparent])
              .createShader(Rect.fromCircle(center: Offset(s.width / 2, s.height * 0.55), radius: s.width * 0.45)),
      );
    } else if (a.hour >= 6 && a.hour < 10) {
      // sabah güneşi: çapraz ışık huzmesi
      final p = Path()
        ..moveTo(s.width * 0.75, 0)
        ..lineTo(s.width * 0.95, 0)
        ..lineTo(s.width * 0.55, s.height)
        ..lineTo(s.width * 0.3, s.height)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFFFFF3BF).withValues(alpha: 0.10));
    }
  }

  @override
  bool shouldRepaint(covariant LightPainter o) => (o.a.hour * 6).floor() != (a.hour * 6).floor();
}

/// Mevsim ve özel gün süsleri (arka planda, karakterlerin arkasında)
class DecorPainter extends CustomPainter {
  final Ambience a;
  final double t; // saniye
  DecorPainter(this.a, this.t);

  @override
  void paint(Canvas c, Size s) {
    final h = a.holidays;
    if (h.isEmpty && a.season == TvSeason.yaz) return; // çizecek süs yok
    // ---- mevsim parçacıkları
    switch (a.season) {
      case TvSeason.kis:
        _fall(c, s, 46, (x, y, i) => c.drawCircle(Offset(x, y), 2.2 + (i % 3) * 0.8, Paint()..color = Colors.white.withValues(alpha: 0.75)),
            speed: 26, drift: 14);
      case TvSeason.acilis:
        const leaf = [Color(0xFFE8590C), Color(0xFFF08C00), Color(0xFFC92A2A), Color(0xFFFAB005)];
        _fall(c, s, 12, (x, y, i) {
          c.save();
          c.translate(x, y);
          c.rotate(t * 1.5 + i);
          c.drawOval(const Rect.fromLTWH(-6, -3, 12, 6), Paint()..color = leaf[i % leaf.length].withValues(alpha: 0.85));
          c.restore();
        }, speed: 22, drift: 30);
      case TvSeason.bahar:
        _fall(c, s, 14, (x, y, i) {
          c.save();
          c.translate(x, y);
          c.rotate(t + i);
          c.drawOval(const Rect.fromLTWH(-4, -2.5, 8, 5), Paint()..color = const Color(0xFFFFC9DE).withValues(alpha: 0.85));
          c.restore();
        }, speed: 18, drift: 26);
      case TvSeason.yaz:
        break;
    }
    // ---- özel gün süsleri (üstte)
    if (h.contains('yilbasi') || h.contains('noel')) {
      _lights(c, s);
      _tree(c, Offset(s.width * 0.06, s.height * 0.88), s.height * 0.32);
    }
    if (h.contains('ramazan') || h.contains('ayYili')) {
      _lanterns(c, s, h.contains('ayYili') ? const Color(0xFFE03131) : const Color(0xFFFFC94D));
    }
    if (h.contains('ramazanBayrami') || h.contains('kurban') || h.contains('karnaval') || h.contains('okul') ||
        h.contains('karne')) {
      _bunting(c, s, const [Color(0xFFFF6B6B), Color(0xFFFFD43B), Color(0xFF4DABF7), Color(0xFF69DB7C), Color(0xFFDA77F2)]);
    }
    if (h.contains('cumhuriyet') || h.contains('zafer') || h.contains('cocuk23') || h.contains('genclik')) {
      _bunting(c, s, const [Color(0xFFE30A17), Colors.white]);
    }
    if (h.contains('sevgililer') || h.contains('anneler')) _hearts(c, s);
    if (h.contains('cadilar')) {
      _pumpkin(c, Offset(s.width * 0.05, s.height * 0.9), s.height * 0.07);
      _pumpkin(c, Offset(s.width * 0.95, s.height * 0.9), s.height * 0.06);
    }
  }

  /// Yukarıdan düşen parçacıklar (sonsuz döngü)
  void _fall(Canvas c, Size s, int n, void Function(double x, double y, int i) draw,
      {required double speed, required double drift}) {
    final r = Random(11);
    for (int i = 0; i < n; i++) {
      final x0 = r.nextDouble() * s.width;
      final sp = speed * (0.7 + r.nextDouble() * 0.6);
      final y = (r.nextDouble() * s.height + t * sp) % (s.height + 20) - 10;
      final x = x0 + sin(t * 0.8 + i) * drift;
      draw(x, y, i);
    }
  }

  void _lights(Canvas c, Size s) {
    final path = Path()..moveTo(0, s.height * 0.04);
    path.quadraticBezierTo(s.width / 2, s.height * 0.16, s.width, s.height * 0.04);
    c.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF2B8A3E));
    const cols = [Color(0xFFFF6B6B), Color(0xFFFFD43B), Color(0xFF4DABF7), Color(0xFF69DB7C)];
    for (int i = 1; i < 18; i++) {
      final x = s.width * i / 18;
      final y = s.height * 0.04 + sin(i / 18 * pi) * s.height * 0.12;
      final on = ((t * 3).floor() + i) % 3 != 0;
      final col = cols[i % cols.length];
      if (on) c.drawCircle(Offset(x, y + 5), 7, Paint()..color = col.withValues(alpha: 0.35));
      c.drawCircle(Offset(x, y + 5), 3.2, Paint()..color = on ? col : col.withValues(alpha: 0.4));
    }
  }

  void _tree(Canvas c, Offset base, double hgt) {
    final g = Paint()..color = const Color(0xFF2B8A3E);
    for (int i = 0; i < 3; i++) {
      final top = base.dy - hgt + i * hgt * 0.25;
      final wdt = hgt * (0.35 + i * 0.12);
      c.drawPath(
          Path()
            ..moveTo(base.dx, top)
            ..lineTo(base.dx - wdt / 2, top + hgt * 0.38)
            ..lineTo(base.dx + wdt / 2, top + hgt * 0.38)
            ..close(),
          g);
    }
    c.drawRect(Rect.fromLTWH(base.dx - 4, base.dy - hgt * 0.1, 8, hgt * 0.12), Paint()..color = const Color(0xFF7A4E2D));
    c.drawCircle(Offset(base.dx, base.dy - hgt), 5, Paint()..color = const Color(0xFFFFD43B));
    final r = Random(3);
    for (int i = 0; i < 8; i++) {
      c.drawCircle(Offset(base.dx + (r.nextDouble() - 0.5) * hgt * 0.45, base.dy - hgt * (0.15 + r.nextDouble() * 0.6)), 2.5,
          Paint()..color = [const Color(0xFFFF6B6B), const Color(0xFFFFD43B), Colors.white][i % 3]);
    }
  }

  void _lanterns(Canvas c, Size s, Color glow) {
    for (int i = 0; i < 5; i++) {
      final x = s.width * (0.12 + i * 0.19);
      final len = s.height * (0.08 + (i % 2) * 0.05);
      final sway = sin(t * 1.2 + i) * 3;
      c.drawLine(Offset(x, 0), Offset(x + sway, len), Paint()
        ..color = const Color(0xFF5C3D2E)
        ..strokeWidth = 1.2);
      final o = Offset(x + sway, len + 12);
      c.drawCircle(o, 22, Paint()..color = glow.withValues(alpha: 0.18));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 16, height: 24), const Radius.circular(6)),
          Paint()..color = glow);
      c.drawRect(Rect.fromCenter(center: o - const Offset(0, 13), width: 10, height: 3), Paint()..color = const Color(0xFF5C3D2E));
      c.drawRect(Rect.fromCenter(center: o + const Offset(0, 13), width: 10, height: 3), Paint()..color = const Color(0xFF5C3D2E));
    }
  }

  void _bunting(Canvas c, Size s, List<Color> cols) {
    final path = Path()..moveTo(0, s.height * 0.03);
    path.quadraticBezierTo(s.width / 2, s.height * 0.12, s.width, s.height * 0.03);
    c.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white70
      ..strokeWidth = 1.2);
    for (int i = 0; i < 16; i++) {
      final x = s.width * (i + 0.5) / 16;
      final y = s.height * 0.03 + sin((i + 0.5) / 16 * pi) * s.height * 0.09;
      final flap = sin(t * 2 + i) * 2;
      c.drawPath(
          Path()
            ..moveTo(x - 10, y)
            ..lineTo(x + 10, y)
            ..lineTo(x + flap, y + 20)
            ..close(),
          Paint()..color = cols[i % cols.length]);
    }
  }

  void _hearts(Canvas c, Size s) {
    for (int i = 0; i < 9; i++) {
      final x = s.width * (0.08 + i * 0.105);
      final y = s.height * (0.06 + (i % 2) * 0.04) + sin(t * 2 + i) * 3;
      final sz = 7.0 + (i % 3) * 2;
      final p = Path()
        ..moveTo(x, y + sz * 0.9)
        ..cubicTo(x - sz * 1.6, y - sz * 0.2, x - sz * 0.6, y - sz * 1.3, x, y - sz * 0.4)
        ..cubicTo(x + sz * 0.6, y - sz * 1.3, x + sz * 1.6, y - sz * 0.2, x, y + sz * 0.9);
      c.drawPath(p, Paint()..color = const Color(0xFFE64980).withValues(alpha: 0.85));
    }
  }

  void _pumpkin(Canvas c, Offset o, double r) {
    c.drawOval(Rect.fromCenter(center: o, width: r * 2.4, height: r * 1.8), Paint()..color = const Color(0xFFF76707));
    c.drawOval(Rect.fromCenter(center: o, width: r * 1.0, height: r * 1.8), Paint()..color = const Color(0xFFE8590C));
    c.drawRect(Rect.fromCenter(center: o - Offset(0, r * 1.0), width: r * 0.25, height: r * 0.5), Paint()..color = const Color(0xFF2B8A3E));
    final glow = Paint()..color = const Color(0xFFFFE066).withValues(alpha: 0.8 + 0.2 * sin(t * 6));
    c.drawPath(
        Path()
          ..moveTo(o.dx - r * 0.6, o.dy - r * 0.2)
          ..lineTo(o.dx - r * 0.3, o.dy - r * 0.45)
          ..lineTo(o.dx - r * 0.15, o.dy - r * 0.15)
          ..close(),
        glow);
    c.drawPath(
        Path()
          ..moveTo(o.dx + r * 0.6, o.dy - r * 0.2)
          ..lineTo(o.dx + r * 0.3, o.dy - r * 0.45)
          ..lineTo(o.dx + r * 0.15, o.dy - r * 0.15)
          ..close(),
        glow);
    c.drawRect(Rect.fromCenter(center: o + Offset(0, r * 0.3), width: r * 0.9, height: r * 0.18), glow);
  }

  @override
  bool shouldRepaint(covariant DecorPainter o) => true;
}
