import 'dart:math';

import 'package:flutter/material.dart';

import '../../data/content.dart';

/// Film türüne özel set: arka plan (dekor) çizimi. t: saniye.
class FilmSetPainter extends CustomPainter {
  final FilmGenre genre;
  final double t;
  final double pan;
  FilmSetPainter(this.genre, this.t, this.pan);

  @override
  void paint(Canvas c, Size s) {
    switch (genre) {
      case FilmGenre.aksiyon:
        _action(c, s);
      case FilmGenre.komedi:
        _comedy(c, s);
      case FilmGenre.dram:
        _drama(c, s);
      case FilmGenre.korku:
        _horror(c, s);
      case FilmGenre.romantik:
        _romance(c, s);
      case FilmGenre.bilimKurgu:
        _scifi(c, s);
      case FilmGenre.animasyon:
        _cartoon(c, s);
    }
  }

  void _grad(Canvas c, Rect r, List<Color> cols) => c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols)
            .createShader(r));

  void _glow(Canvas c, Offset o, double r, Color col) => c.drawCircle(
      o,
      r,
      Paint()..shader = RadialGradient(colors: [col, col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: o, radius: r)));

  // ---------------- AKSİYON: gece şehir, patlama, yanan araba, helikopter
  void _action(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _grad(c, Offset.zero & s, const [Color(0xFF1B1030), Color(0xFF4A1C1C), Color(0xFF2A1A14)]);
    final r = Random(3);
    // binalar
    for (int i = 0; i < 12; i++) {
      final bw = 40.0 + r.nextDouble() * 40, bh = h * (0.25 + r.nextDouble() * 0.35);
      final x = i * 58.0 - 20 - pan * 0.3;
      c.drawRect(Rect.fromLTWH(x, h * 0.7 - bh, bw, bh), Paint()..color = const Color(0xFF140C18));
      for (int k = 0; k < 6; k++) {
        if (r.nextDouble() < 0.4) {
          c.drawRect(Rect.fromLTWH(x + 6 + (k % 3) * 11, h * 0.7 - bh + 10 + (k ~/ 3) * 16, 6, 8),
              Paint()..color = const Color(0xFFFFB347).withValues(alpha: 0.7));
        }
      }
    }
    // zemin (yol)
    c.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFF221A1A));
    for (double x = -40 + (t * 120) % 80; x < w; x += 80) {
      c.drawRect(Rect.fromLTWH(x, h * 0.84, 40, 4), Paint()..color = const Color(0xFFFFD43B).withValues(alpha: 0.6));
    }
    // patlama (tekrar eden)
    final ph = (t % 4.0) / 4.0;
    final bx = w * 0.72, by = h * 0.55;
    if (ph < 0.5) {
      final k = ph / 0.5;
      _glow(c, Offset(bx, by), 40 + k * 140, const Color(0xFFFF7A00).withValues(alpha: 1 - k));
      _glow(c, Offset(bx, by), 20 + k * 80, const Color(0xFFFFF3A0).withValues(alpha: (1 - k) * 0.9));
      for (int i = 0; i < 14; i++) {
        final a = i / 14 * pi * 2;
        c.drawCircle(Offset(bx + cos(a) * k * 150, by + sin(a) * k * 110 - k * 30), 4 * (1 - k) + 1,
            Paint()..color = const Color(0xFFFFC14D).withValues(alpha: 1 - k));
      }
    }
    // yanan araba
    final car = Rect.fromLTWH(w * 0.6, h * 0.66, 120, 38);
    c.drawRRect(RRect.fromRectAndRadius(car, const Radius.circular(10)), Paint()..color = const Color(0xFF3A3A44));
    c.drawCircle(Offset(car.left + 25, car.bottom), 12, Paint()..color = Colors.black);
    c.drawCircle(Offset(car.right - 25, car.bottom), 12, Paint()..color = Colors.black);
    for (int i = 0; i < 5; i++) {
      final f = sin(t * 9 + i) * 6;
      final p = Path()
        ..moveTo(car.left + 20 + i * 18, car.top + 4)
        ..quadraticBezierTo(car.left + 28 + i * 18 + f, car.top - 30 - (i % 2) * 14, car.left + 36 + i * 18, car.top + 4)
        ..close();
      c.drawPath(p, Paint()..color = (i.isEven ? const Color(0xFFFF6B1A) : const Color(0xFFFFC233)).withValues(alpha: 0.9));
    }
    // helikopter (sağdan sola süzülür) + projektör
    final hx = w - ((t * 40) % (w + 200)) + 100, hy = h * 0.16;
    final beam = Path()
      ..moveTo(hx, hy + 10)
      ..lineTo(hx - 90, h * 0.75)
      ..lineTo(hx + 30, h * 0.75)
      ..close();
    c.drawPath(beam, Paint()..color = Colors.white.withValues(alpha: 0.08));
    c.drawOval(Rect.fromCenter(center: Offset(hx, hy), width: 60, height: 22), Paint()..color = const Color(0xFF0C0A10));
    c.drawRect(Rect.fromLTWH(hx + 25, hy - 3, 40, 5), Paint()..color = const Color(0xFF0C0A10));
    c.drawLine(Offset(hx - 45 + sin(t * 40) * 10, hy - 14), Offset(hx + 45 - sin(t * 40) * 10, hy - 14),
        Paint()
          ..color = const Color(0xFF0C0A10)
          ..strokeWidth = 3);
    if ((t * 2).floor().isEven) c.drawCircle(Offset(hx - 28, hy), 3, Paint()..color = Colors.red);
  }

  // ---------------- KOMEDİ: renkli apartman dairesi, uçan pasta, muz kabuğu
  void _comedy(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _grad(c, Offset.zero & s, const [Color(0xFFFFE08A), Color(0xFFFFB86B)]);
    // puantiyeli duvar
    for (double y = 18; y < h * 0.7; y += 34) {
      for (double x = 18 + ((y ~/ 34).isOdd ? 17 : 0); x < w; x += 34) {
        c.drawCircle(Offset(x - pan * 0.2, y), 5, Paint()..color = const Color(0xFFFF8FAB).withValues(alpha: 0.5));
      }
    }
    // kanepe
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.33, h * 0.52, w * 0.34, h * 0.18), const Radius.circular(18)),
        Paint()..color = const Color(0xFF4DABF7));
    // çerçeveli komik resim
    c.drawRect(Rect.fromLTWH(w * 0.44, h * 0.12, 70, 50), Paint()..color = const Color(0xFF8D5A3B));
    c.drawRect(Rect.fromLTWH(w * 0.44 + 6, h * 0.12 + 6, 58, 38), Paint()..color = const Color(0xFFFFF3BF));
    c.drawCircle(Offset(w * 0.44 + 35, h * 0.12 + 25), 10, Paint()..color = const Color(0xFFFFC078));
    // zemin
    c.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFFB5651D));
    for (double x = 0; x < w; x += 46) {
      c.drawLine(Offset(x, h * 0.7), Offset(x - 30, h), Paint()..color = const Color(0xFF8B4513));
    }
    // muz kabuğu
    final bp = Offset(w * 0.5, h * 0.9);
    c.drawOval(Rect.fromCenter(center: bp, width: 34, height: 10), Paint()..color = const Color(0xFFFFD43B));
    // uçan pasta (yay çizer)
    final k = (t % 3.0) / 3.0;
    final px = w * 0.15 + k * w * 0.7, py = h * 0.45 - sin(k * pi) * h * 0.3;
    c.drawCircle(Offset(px, py), 14, Paint()..color = Colors.white);
    c.drawCircle(Offset(px, py - 8), 5, Paint()..color = const Color(0xFFE03131));
    // konfeti
    final r = Random(9);
    for (int i = 0; i < 18; i++) {
      final y = (r.nextDouble() * h + t * (30 + r.nextDouble() * 40)) % h;
      c.drawRect(Rect.fromLTWH(r.nextDouble() * w, y, 5, 3),
          Paint()..color = [const Color(0xFFE64980), const Color(0xFF7950F2), const Color(0xFF12B886)][i % 3]);
    }
  }

  // ---------------- DRAM: yağmurlu pencere, lamba, piyano
  void _drama(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _grad(c, Offset.zero & s, const [Color(0xFF1E2A3A), Color(0xFF2B2F3A)]);
    // pencere
    final win = Rect.fromLTWH(w * 0.36, h * 0.08, w * 0.28, h * 0.5);
    _grad(c, win, const [Color(0xFF3B4B66), Color(0xFF6B7A99)]);
    c.drawRect(win, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = const Color(0xFF3A2A1E));
    c.drawLine(win.topCenter, win.bottomCenter, Paint()
      ..strokeWidth = 4
      ..color = const Color(0xFF3A2A1E));
    // yağmur
    final r = Random(5);
    final rain = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.2;
    for (int i = 0; i < 60; i++) {
      final x = r.nextDouble() * w;
      final y = (r.nextDouble() * h + t * (220 + r.nextDouble() * 80)) % (h * 1.1) - 20;
      c.drawLine(Offset(x, y), Offset(x - 4, y + 14), rain);
    }
    // camdaki damlalar
    for (int i = 0; i < 10; i++) {
      final x = win.left + 8 + r.nextDouble() * (win.width - 16);
      final y = win.top + ((r.nextDouble() * win.height + t * 18 * (1 + i % 3)) % win.height);
      c.drawCircle(Offset(x, y), 2.5, Paint()..color = Colors.white.withValues(alpha: 0.5));
    }
    // lamba ışığı
    _glow(c, Offset(w * 0.12, h * 0.42), 120, const Color(0xFFFFC46B).withValues(alpha: 0.35 + 0.05 * sin(t * 3)));
    c.drawRect(Rect.fromLTWH(w * 0.11, h * 0.45, 6, h * 0.25), Paint()..color = const Color(0xFF2A2018));
    c.drawPath(
        Path()
          ..moveTo(w * 0.08, h * 0.45)
          ..lineTo(w * 0.16, h * 0.45)
          ..lineTo(w * 0.145, h * 0.36)
          ..lineTo(w * 0.095, h * 0.36)
          ..close(),
        Paint()..color = const Color(0xFFE8C07A));
    // piyano
    c.drawRect(Rect.fromLTWH(w * 0.74, h * 0.46, w * 0.22, h * 0.24), Paint()..color = const Color(0xFF15110F));
    for (int i = 0; i < 9; i++) {
      c.drawRect(Rect.fromLTWH(w * 0.745 + i * w * 0.023, h * 0.5, w * 0.02, h * 0.06), Paint()..color = Colors.white);
    }
    c.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFF2A221C));
  }

  // ---------------- KORKU: dolunay, yarasalar, sis, şimşek, terk edilmiş ev
  void _horror(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final flash = (t % 5.0) < 0.12 || ((t % 5.0) > 0.25 && (t % 5.0) < 0.32);
    _grad(c, Offset.zero & s,
        flash ? const [Color(0xFF9AA8D8), Color(0xFF3A3A5A)] : const [Color(0xFF07070F), Color(0xFF14121E)]);
    _glow(c, Offset(w * 0.78, h * 0.2), 70, const Color(0xFFE8F0FF).withValues(alpha: 0.35));
    c.drawCircle(Offset(w * 0.78, h * 0.2), 30, Paint()..color = const Color(0xFFF1F3F5));
    // ev siluet
    final house = Path()
      ..moveTo(w * 0.32, h * 0.7)
      ..lineTo(w * 0.32, h * 0.34)
      ..lineTo(w * 0.42, h * 0.18)
      ..lineTo(w * 0.52, h * 0.34)
      ..lineTo(w * 0.52, h * 0.7)
      ..close();
    c.drawPath(house, Paint()..color = const Color(0xFF0A0810));
    final lit = (sin(t * 1.7) > 0.2);
    c.drawRect(Rect.fromLTWH(w * 0.4, h * 0.4, 18, 22),
        Paint()..color = lit ? const Color(0xFFFFC94D).withValues(alpha: 0.8) : const Color(0xFF1A1620));
    // ölü ağaç
    final tree = Paint()
      ..color = const Color(0xFF0A0810)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(w * 0.12, h * 0.72), Offset(w * 0.12, h * 0.3), tree);
    c.drawLine(Offset(w * 0.12, h * 0.42), Offset(w * 0.04, h * 0.3), tree..strokeWidth = 4);
    c.drawLine(Offset(w * 0.12, h * 0.38), Offset(w * 0.21, h * 0.26), tree);
    // yarasalar
    for (int i = 0; i < 4; i++) {
      final x = (w * 0.2 + i * 90 + t * 60) % (w + 60) - 30;
      final y = h * (0.15 + 0.06 * i) + sin(t * 4 + i) * 10;
      final flap = sin(t * 18 + i) * 6;
      final bat = Path()
        ..moveTo(x, y)
        ..lineTo(x - 12, y - 6 + flap)
        ..lineTo(x - 6, y + 2)
        ..lineTo(x, y + 4)
        ..lineTo(x + 6, y + 2)
        ..lineTo(x + 12, y - 6 + flap)
        ..close();
      c.drawPath(bat, Paint()..color = Colors.black);
    }
    c.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFF0C0B12));
    // sis
    for (int i = 0; i < 6; i++) {
      final x = (i * 140 + t * 25) % (w + 200) - 100;
      c.drawOval(Rect.fromCenter(center: Offset(x, h * 0.74 + (i % 2) * 14), width: 220, height: 40),
          Paint()..color = Colors.white.withValues(alpha: 0.07));
    }
  }

  // ---------------- ROMANTİK: gün batımı park, bank, kalpler, ışık zinciri
  void _romance(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _grad(c, Offset.zero & s, const [Color(0xFFFF8FA3), Color(0xFFFFC078), Color(0xFFFFE3B3)]);
    _glow(c, Offset(w * 0.5, h * 0.62), 130, const Color(0xFFFFF3BF).withValues(alpha: 0.9));
    c.drawCircle(Offset(w * 0.5, h * 0.62), 46, Paint()..color = const Color(0xFFFFD8A8));
    // ağaçlar
    for (final x in [w * 0.08, w * 0.9]) {
      c.drawRect(Rect.fromLTWH(x - 6, h * 0.4, 12, h * 0.32), Paint()..color = const Color(0xFF7A4E2D));
      c.drawCircle(Offset(x, h * 0.36), 50, Paint()..color = const Color(0xFFE599B6));
    }
    // ışık zinciri
    final path = Path()..moveTo(0, h * 0.1);
    path.quadraticBezierTo(w / 2, h * 0.3, w, h * 0.1);
    c.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF5C3D2E)
      ..strokeWidth = 1.5);
    for (int i = 1; i < 14; i++) {
      final x = w * i / 14;
      final y = h * 0.1 + sin(i / 14 * pi) * h * 0.1;
      final on = ((t * 3).floor() + i) % 3 != 0;
      c.drawCircle(Offset(x, y + 6), 4, Paint()..color = on ? const Color(0xFFFFF3BF) : const Color(0xFFFFC078));
    }
    // çim
    c.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), Paint()..color = const Color(0xFF8CC572));
    // bank
    c.drawRect(Rect.fromLTWH(w * 0.38, h * 0.62, w * 0.24, 10), Paint()..color = const Color(0xFF6B4226));
    c.drawRect(Rect.fromLTWH(w * 0.38, h * 0.55, w * 0.24, 8), Paint()..color = const Color(0xFF6B4226));
    // uçan kalpler
    final r = Random(2);
    for (int i = 0; i < 10; i++) {
      final x = r.nextDouble() * w + sin(t + i) * 12;
      final y = h - ((t * (20 + r.nextDouble() * 20) + r.nextDouble() * h) % h);
      _heart(c, Offset(x, y), 6 + r.nextDouble() * 6, const Color(0xFFE64980).withValues(alpha: 0.7));
    }
  }

  void _heart(Canvas c, Offset o, double s, Color col) {
    final p = Path()
      ..moveTo(o.dx, o.dy + s * 0.9)
      ..cubicTo(o.dx - s * 1.6, o.dy - s * 0.2, o.dx - s * 0.6, o.dy - s * 1.3, o.dx, o.dy - s * 0.4)
      ..cubicTo(o.dx + s * 0.6, o.dy - s * 1.3, o.dx + s * 1.6, o.dy - s * 0.2, o.dx, o.dy + s * 0.9);
    c.drawPath(p, Paint()..color = col);
  }

  // ---------------- BİLİM KURGU: uzay gemisi köprüsü, kayan yıldızlar, hologram
  void _scifi(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF050817));
    // ışık hızı yıldızları
    final r = Random(7);
    final center = Offset(w / 2, h * 0.32);
    for (int i = 0; i < 70; i++) {
      final a = r.nextDouble() * pi * 2;
      final d = ((r.nextDouble() + t * 0.35) % 1.0);
      final p1 = center + Offset(cos(a), sin(a)) * (d * w * 0.7);
      final p2 = center + Offset(cos(a), sin(a)) * (d * w * 0.7 + 6 + d * 22);
      c.drawLine(p1, p2, Paint()
        ..color = Colors.white.withValues(alpha: d)
        ..strokeWidth = 1.4);
    }
    // gemi penceresi çerçevesi
    final frame = Paint()..color = const Color(0xFF1C2333);
    c.drawPath(
        Path()
          ..moveTo(0, 0)
          ..lineTo(w * 0.18, h * 0.08)
          ..lineTo(w * 0.18, h * 0.62)
          ..lineTo(0, h * 0.7)
          ..close(),
        frame);
    c.drawPath(
        Path()
          ..moveTo(w, 0)
          ..lineTo(w * 0.82, h * 0.08)
          ..lineTo(w * 0.82, h * 0.62)
          ..lineTo(w, h * 0.7)
          ..close(),
        frame);
    // konsol
    c.drawRect(Rect.fromLTWH(0, h * 0.62, w, h * 0.38), Paint()..color = const Color(0xFF151B2B));
    for (int i = 0; i < 16; i++) {
      final on = ((t * 4).floor() + i * 7) % 5 != 0;
      c.drawRect(Rect.fromLTWH(20.0 + i * (w - 40) / 16, h * 0.68, 14, 6),
          Paint()..color = (on ? [const Color(0xFF22D3EE), const Color(0xFFA3E635), const Color(0xFFF472B6)][i % 3] : const Color(0xFF2A3348)));
    }
    // hologram gezegen
    final hp = Offset(w * 0.5, h * 0.5);
    _glow(c, hp, 50, const Color(0xFF22D3EE).withValues(alpha: 0.35));
    c.drawCircle(hp, 22, Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF67E8F9)
      ..strokeWidth = 1.5);
    c.drawOval(Rect.fromCenter(center: hp, width: 70 + sin(t) * 4, height: 16), Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF67E8F9).withValues(alpha: 0.7));
  }

  // ---------------- ANİMASYON: şeker renkli masal dünyası, gökkuşağı, zıplayan toplar
  void _cartoon(Canvas c, Size s) {
    final w = s.width, h = s.height;
    _grad(c, Offset.zero & s, const [Color(0xFF8BE0FF), Color(0xFFD0F4FF)]);
    // gökkuşağı
    const cols = [Color(0xFFFF6B6B), Color(0xFFFFA94D), Color(0xFFFFD43B), Color(0xFF69DB7C), Color(0xFF4DABF7), Color(0xFF9775FA)];
    for (int i = 0; i < cols.length; i++) {
      c.drawArc(Rect.fromCenter(center: Offset(w / 2, h * 0.78), width: w * 0.9 - i * 24, height: h * 1.0 - i * 24), pi, pi,
          false, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 12
            ..color = cols[i].withValues(alpha: 0.8));
    }
    // bulutlar
    for (int i = 0; i < 3; i++) {
      final x = (i * 230 + t * 20) % (w + 120) - 60;
      for (final d in const [Offset(0, 0), Offset(22, -10), Offset(44, 0)]) {
        c.drawCircle(Offset(x, h * (0.12 + i * 0.05)) + d, 18, Paint()..color = Colors.white);
      }
    }
    // tepeler
    c.drawOval(Rect.fromLTWH(-w * 0.2, h * 0.6, w * 0.8, h * 0.6), Paint()..color = const Color(0xFF8CE99A));
    c.drawOval(Rect.fromLTWH(w * 0.4, h * 0.64, w * 0.8, h * 0.6), Paint()..color = const Color(0xFF69DB7C));
    // zıplayan toplar
    for (int i = 0; i < 3; i++) {
      final b = (sin(t * 3 + i * 2)).abs();
      c.drawCircle(Offset(w * (0.2 + i * 0.3), h * 0.7 - b * h * 0.2), 12, Paint()..color = cols[(i * 2) % cols.length]);
    }
    // şeker çubukları
    for (final x in [w * 0.06, w * 0.94]) {
      c.drawRect(Rect.fromLTWH(x - 4, h * 0.42, 8, h * 0.3), Paint()..color = Colors.white);
      c.drawCircle(Offset(x, h * 0.4), 18, Paint()..color = const Color(0xFFF783AC));
      c.drawCircle(Offset(x, h * 0.4), 9, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant FilmSetPainter old) => true;
}

/// Film setinin önündeki ekip: kamera, boom mikrofon, klaket
class FilmCrewPainter extends CustomPainter {
  static final _slate = TextPainter(
    text: const TextSpan(
        text: 'SAHNE 12 · ÇEKİM 3', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800)),
    textDirection: TextDirection.ltr,
  )..layout();
  final double t;
  FilmCrewPainter(this.t);
  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final dark = Paint()..color = const Color(0xFF111015);
    // kamera (sol altta, tripod)
    final cam = Offset(w * 0.06, h * 0.78);
    for (final dx in [-22.0, 0.0, 22.0]) {
      c.drawLine(cam, cam + Offset(dx, h * 0.25), Paint()
        ..color = const Color(0xFF2A2A30)
        ..strokeWidth = 4);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: cam, width: 62, height: 34), const Radius.circular(6)), dark);
    c.drawCircle(cam + const Offset(36, 0), 11, Paint()..color = const Color(0xFF26262E));
    c.drawCircle(cam + const Offset(36, 0), 6, Paint()..color = const Color(0xFF3B82F6).withValues(alpha: 0.7));
    if ((t * 2).floor().isEven) c.drawCircle(cam + const Offset(-22, -10), 3.5, Paint()..color = Colors.red);
    // boom mikrofon (üstten sarkar, sallanır)
    final sway = sin(t * 0.9) * 18;
    c.drawLine(Offset(w * 0.98, h * 0.02), Offset(w * 0.6 + sway, h * 0.12), Paint()
      ..color = const Color(0xFF2A2A30)
      ..strokeWidth = 4);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.6 + sway, h * 0.14), width: 46, height: 16),
        const Radius.circular(8)), Paint()..color = const Color(0xFF55555F));
    // klaket (her 6 sn'de bir çarpar)
    final ph = (t % 6.0);
    if (ph < 1.2) {
      final k = (ph / 1.2);
      final open = k < 0.5 ? 0.5 : (k < 0.6 ? 0.5 - (k - 0.5) * 5 : 0.0);
      final base = Offset(w * 0.5, h * 0.82);
      c.drawRect(Rect.fromCenter(center: base, width: 90, height: 56), dark);
      c.save();
      c.translate(base.dx - 45, base.dy - 28);
      c.rotate(-open);
      for (int i = 0; i < 6; i++) {
        c.drawRect(Rect.fromLTWH(i * 15.0, -12, 15, 12), Paint()..color = i.isEven ? Colors.white : Colors.black);
      }
      c.restore();
      _slate.paint(c, base - Offset(_slate.width / 2, 4));
    }
  }

  @override
  bool shouldRepaint(covariant FilmCrewPainter old) => true;
}

/// Film türüne göre karakterlerin hâli: 0 normal, 1 kızgın, 2 korkmuş, 3 mutlu
int filmMood(FilmGenre g) => switch (g) {
      FilmGenre.aksiyon => 1,
      FilmGenre.korku => 2,
      FilmGenre.romantik || FilmGenre.komedi || FilmGenre.animasyon => 3,
      _ => 0,
    };

/// Türe özel set diyalogları: (1. kişi, 2. kişi, seyirci tepkisi)
const filmDialogs = <FilmGenre, List<(String, String, int)>>{
  FilmGenre.aksiyon: [
    ('Atla! Bomba patlıyor!', 'Arkamızda helikopter var! 🚁', 3),
    ('Anahtarlar sende mi?!', 'Araba zaten yanıyor! 🔥', 3),
    ('Bu son görevim.', 'Hep böyle dersin… 😏', 0),
    ('Dublör hazır mı?', 'Patlama sayıyla: 3, 2, 1!', 2),
    ('Kırmızı kablo mu mavi mi?', 'İkisi de kırmızı! 😱', 3),
  ],
  FilmGenre.komedi: [
    ('Pastayı kim attı?!', 'Ben değil, kedi! 😂', 1),
    ('Muz kabuğuna dikkat et!', 'Hangi muz kabu— ahh! 🤣', 1),
    ('Kayınvalide geliyor!', 'Saklanın, çabuk! 😂', 1),
    ('Bu senin pijaman mı?', 'Hayır, düğün kıyafetim! 😅', 1),
    ('Kestik! Kimse gülmesin!', 'Herkes gülüyor ama… 😂', 1),
  ],
  FilmGenre.dram: [
    ('Yıllardır seni bekledim…', 'Biliyorum. Affet beni.', 3),
    ('Bu mektubu neden sakladın?', 'Seni korumak için…', 3),
    ('Babam bilmemeli.', 'Artık çok geç.', 3),
    ('Yağmur hiç dinmeyecek mi?', 'Sen gidince başladı.', 0),
    ('Kestik! Herkes ağlıyor! 😢', 'Mükemmeldi, çok gerçekti.', 2),
  ],
  FilmGenre.korku: [
    ('Bu ses de neydi?!', 'Bodrum kapısı açık… 😨', 3),
    ('Işıkları kapatma!', 'Ben kapatmadım ki… 😱', 3),
    ('Arkana bakma!', '…Ne var arkamda? 👻', 3),
    ('Kimse bu eve girmez.', 'O zaman kim çaldı zili?', 3),
    ('Kestik! Sis makinesi fazla!', 'Ben de korktum açıkçası 😅', 1),
  ],
  FilmGenre.romantik: [
    ('Bu bankı hatırlıyor musun?', 'Burada tanışmıştık… ❤️', 2),
    ('Gitme, kal.', 'Uçağım bir saat sonra…', 3),
    ('Gün batımı senin için.', 'Sen benim gün doğumumsun 😍', 2),
    ('Bir şey söylemem lazım…', 'Ben de seni seviyorum. ❤️', 2),
    ('Kestik! Kalpler eridi!', 'Bir daha alalım, gözler daha nemli!', 0),
  ],
  FilmGenre.bilimKurgu: [
    ('Işık hızına geç!', 'Motorlar dayanmaz kaptan! 🚀', 3),
    ('Bu gezegende hayat var.', 'Ve bize bakıyor… 👽', 3),
    ('Zaman çizgisi bozuldu!', 'Yarın dünden önce geldi! 😵', 3),
    ('Robot ne diyor?', '"Bip bop… arkadaş." 🤖', 1),
    ('Kestik! Yeşil perde düştü!', 'Uzay biraz sallandı 😂', 1),
  ],
  FilmGenre.animasyon: [
    ('Gökkuşağının sonuna gidelim!', 'Hazine orada mı? 🌈', 2),
    ('Ben konuşan bir ayıyım!', 'Ben de uçan bir kurbağa! 🐸', 1),
    ('Seslendirme hazır!', 'Mikrofona daha yakın, tatlım! 🎙️', 0),
    ('Ejderha geliyor!', 'Ama çok sevimli! 🐉', 1),
    ('Kestik! Çizimler harika!', 'Çocuklar bayılacak! 🎨', 2),
  ],
};
