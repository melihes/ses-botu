import '../../core/format.dart';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme.dart';
import '../../data/content.dart';
import '../../models/models.dart';

/// Altın Anten Ödülleri töreni: kırmızı halı, adaylar, zarf, kazanan.
/// Sağ üstteki "Geç" ile her an atlanabilir; ekrana dokunmak sonraki adıma geçer.
Future<void> showAwardCeremony(BuildContext context, String channel, List<AwardResult> results) {
  if (results.isEmpty) return Future.value();
  return Navigator.of(context).push(PageRouteBuilder(
    opaque: true,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => AwardCeremony(channel: channel, results: results),
    transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
  ));
}

class AwardCeremony extends StatefulWidget {
  final String channel;
  final List<AwardResult> results;
  const AwardCeremony({super.key, required this.channel, required this.results});
  @override
  State<AwardCeremony> createState() => _AwardCeremonyState();
}

class _AwardCeremonyState extends State<AwardCeremony> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0; // saniye (toplam)
  double _stepAt = 0; // bu adımın başladığı an
  Duration _last = Duration.zero;
  int _step = 0; // 0 kırmızı halı, 1..n kategoriler, n+1 bitti
  final _r = Random();
  late final List<List<String>> _nominees;

  static const _introLen = 3.6, _catLen = 6.2;

  @override
  void initState() {
    super.initState();
    // her kategori için 3 aday: bizimki + 2 rakip (yerleri karışık)
    _nominees = [
      for (final r in widget.results)
        (() {
          // iki farklı rakip kanal
          final rv = [...rivalDefs]..shuffle(_r);
          return [r.nominee, '${rv[0].name} · ${_rivalShow()}', '${rv[1].name} · ${_rivalShow()}']..shuffle(_r);
        })(),
    ];
    _ticker = createTicker((e) {
      final dt = ((e - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
      _last = e;
      _t += dt;
      final len = _step == 0 ? _introLen : _catLen;
      if (_t - _stepAt >= len) _next();
      if (mounted) setState(() {});
    })
      ..start();
  }

  String _rivalShow() {
    final all = showNameIdeas.values.expand((l) => l).toList();
    return all[_r.nextInt(all.length)];
  }

  void _next() {
    if (_step >= widget.results.length) {
      _finish();
      return;
    }
    _step++;
    _stepAt = _t;
  }

  bool _done = false;
  void _finish() {
    if (_done) return;
    _done = true;
    _ticker.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = _t - _stepAt;
    final cat = _step == 0 ? null : widget.results[_step - 1];
    // sonuç açıklandı mı (zarf 3. saniyede açılır)
    final revealed = cat != null && p > 3.0;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // dokununca: sonuç açılmadıysa hemen aç, açıldıysa sonrakine geç
          if (cat != null && !revealed) {
            _stepAt = _t - 3.0;
          } else {
            _next();
          }
        },
        child: Stack(fit: StackFit.expand, children: [
          CustomPaint(
            painter: _HallPainter(
              t: _t,
              carpet: _step == 0,
              spot: revealed && cat.won ? 1 : (revealed ? 0.3 : 0.6),
              flashes: _step == 0 || (revealed && cat.won),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(builder: (ctx, c) {
              final small = c.maxHeight < 330;
              return _step == 0 ? _intro(p, small) : _category(cat!, _nominees[_step - 1], p, revealed, small);
            }),
          ),
          if (revealed && cat.won) IgnorePointer(child: CustomPaint(painter: _GoldConfetti(t: p - 3.0))),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _finish,
                  icon: const Icon(Icons.skip_next_rounded),
                  label: const Text('Geç', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _intro(double p, bool small) {
    final a = Curves.easeOut.transform((p / 1.2).clamp(0.0, 1.0));
    return Center(
      child: Opacity(
        opacity: a,
        child: Transform.scale(
          scale: 0.85 + a * 0.15,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🏆', style: TextStyle(fontSize: small ? 46 : 64)),
            Text('ALTIN ANTEN ÖDÜLLERİ',
                style: TextStyle(
                  fontSize: small ? 24 : 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: const Color(0xFFFFD43B),
                  shadows: const [Shadow(color: Color(0xFFB8860B), blurRadius: 18)],
                )),
            const SizedBox(height: 6),
            Text('Kırmızı halıda yıldızlar, flaşlar patlıyor…',
                style: TextStyle(color: Colors.white70, fontSize: small ? 12 : 15)),
            const SizedBox(height: 4),
            Text('${widget.results.length} kategoride ${widget.channel} aday!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: small ? 13 : 16)),
          ]),
        ),
      ),
    );
  }

  Widget _category(AwardResult r, List<String> noms, double p, bool revealed, bool small) {
    final appear = Curves.easeOutBack.transform((p / 0.6).clamp(0.0, 1.0));
    // zarf: 1.6-3.0 sn arası titrer, 3.0'da açılır
    final shake = p > 1.6 && p < 3.0 ? sin(p * 40) * 4 : 0.0;
    final winner = r.won ? r.nominee : noms.firstWhere((n) => n != r.nominee);
    return Padding(
      padding: EdgeInsets.all(small ? 8 : 16),
      child: Column(children: [
        Opacity(
          opacity: appear.clamp(0.0, 1.0),
          child: Text(trUpper(r.category),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: small ? 18 : 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  color: const Color(0xFFFFD43B))),
        ),
        SizedBox(height: small ? 6 : 12),
        Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 6, children: [
          for (final (i, n) in noms.indexed)
            Opacity(
              opacity: Curves.easeOut.transform(((p - 0.3 - i * 0.25) / 0.4).clamp(0.0, 1.0)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                padding: EdgeInsets.symmetric(horizontal: small ? 8 : 12, vertical: small ? 5 : 8),
                decoration: BoxDecoration(
                  color: revealed && n == winner ? const Color(0xFF3B2F00) : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: revealed && n == winner
                        ? const Color(0xFFFFD43B)
                        : (n == r.nominee ? AppColors.accent : Colors.white24),
                    width: revealed && n == winner ? 2.5 : 1.2,
                  ),
                ),
                child: Text(
                  n == r.nominee ? '⭐ $n' : n,
                  style: TextStyle(
                    color: revealed && n != winner ? Colors.white38 : Colors.white,
                    fontWeight: n == r.nominee ? FontWeight.w900 : FontWeight.w600,
                    fontSize: small ? 11 : 13,
                  ),
                ),
              ),
            ),
        ]),
        const Spacer(),
        if (!revealed) ...[
          Transform.translate(
            offset: Offset(shake, 0),
            child: Opacity(
              opacity: (p / 1.0).clamp(0.0, 1.0),
              child: Text('✉️', style: TextStyle(fontSize: small ? 42 : 60)),
            ),
          ),
          Text(p > 1.6 ? 'Ve ödül gidiyor…' : 'Adaylar…',
              style: TextStyle(color: Colors.white70, fontSize: small ? 14 : 18, fontStyle: FontStyle.italic)),
        ] else ...[
          Transform.scale(
            scale: Curves.elasticOut.transform(((p - 3.0) / 0.9).clamp(0.0, 1.0)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(r.won ? '🏆' : '👏', style: TextStyle(fontSize: small ? 40 : 56)),
              Text(winner,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: small ? 18 : 24,
                    fontWeight: FontWeight.w900,
                    color: r.won ? const Color(0xFFFFD43B) : Colors.white70,
                  )),
              const SizedBox(height: 4),
              Text(
                r.won ? '🎉 Kazandın! +15 prestij, +3 💎' : 'Bu sefer rakip kazandı. Bir dahaki törene!',
                style: TextStyle(
                    color: r.won ? AppColors.green : Colors.white54,
                    fontWeight: FontWeight.w800,
                    fontSize: small ? 12 : 15),
              ),
            ]),
          ),
        ],
        SizedBox(height: small ? 4 : 10),
        Text('$_step/${widget.results.length} · dokun: sonraki',
            style: const TextStyle(color: Colors.white30, fontSize: 11)),
      ]),
    );
  }
}

/// Tören salonu: perde, dönen spot ışıkları, kırmızı halı ve flaşlar
class _HallPainter extends CustomPainter {
  final double t;
  final bool carpet;
  final double spot; // 0..1 ortadaki spot gücü
  final bool flashes;
  _HallPainter({required this.t, required this.carpet, required this.spot, required this.flashes});

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    final bg = Offset.zero & s;
    c.drawRect(
        bg,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF12060E), Color(0xFF2A0B1A), Color(0xFF0A0408)],
          ).createShader(bg));
    // perde kıvrımları
    for (int i = 0; i < 14; i++) {
      final x = w * i / 14;
      c.drawRect(
          Rect.fromLTWH(x, 0, w / 28, h * 0.75),
          Paint()..color = const Color(0xFF5C0A1E).withValues(alpha: 0.55));
    }
    // dönen spot ışıkları
    for (int i = 0; i < 4; i++) {
      final ang = sin(t * 0.7 + i * 1.6) * 0.5;
      final top = Offset(w * (0.15 + i * 0.23), -10);
      final len = h * 1.2;
      final p = Path()
        ..moveTo(top.dx, top.dy)
        ..lineTo(top.dx + sin(ang - 0.12) * len, len)
        ..lineTo(top.dx + sin(ang + 0.12) * len, len)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFFFFF3BF).withValues(alpha: 0.06));
    }
    // ortadaki spot (kazananda parlak)
    final center = Offset(w / 2, h * 0.62);
    c.drawCircle(
        center,
        w * 0.35,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFE8A3).withValues(alpha: 0.28 * spot),
            Colors.transparent,
          ]).createShader(Rect.fromCircle(center: center, radius: w * 0.35)));
    if (carpet) {
      // perspektif kırmızı halı
      final p = Path()
        ..moveTo(w * 0.44, h * 0.55)
        ..lineTo(w * 0.56, h * 0.55)
        ..lineTo(w * 0.8, h)
        ..lineTo(w * 0.2, h)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFFB3132E));
      // halı kenarındaki bariyerler
      for (int i = 0; i < 6; i++) {
        final k = i / 6;
        final y = h * 0.58 + k * h * 0.4;
        final xl = w * (0.42 - k * 0.24), xr = w * (0.58 + k * 0.24);
        for (final x in [xl, xr]) {
          c.drawCircle(Offset(x, y), 3 + k * 4, Paint()..color = const Color(0xFFD4A017));
        }
      }
    }
    // seyirci kafaları
    final head = Paint()..color = const Color(0xFF050205);
    for (int i = 0; i < 14; i++) {
      final x = i * w / 13 - 20;
      c.drawCircle(Offset(x, h - 8 + sin(t * 3 + i) * 2), w / 30, head);
    }
    // paparazzi flaşları
    if (flashes) {
      final r = Random((t * 6).floor());
      for (int i = 0; i < 3; i++) {
        if (r.nextDouble() < 0.55) continue;
        final o = Offset(r.nextDouble() * w, h * (0.55 + r.nextDouble() * 0.4));
        c.drawCircle(
            o,
            40,
            Paint()
              ..shader = RadialGradient(colors: [Colors.white.withValues(alpha: 0.9), Colors.transparent])
                  .createShader(Rect.fromCircle(center: o, radius: 40)));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HallPainter o) => true;
}

/// Altın konfeti yağmuru
class _GoldConfetti extends CustomPainter {
  final double t;
  _GoldConfetti({required this.t});
  @override
  void paint(Canvas c, Size s) {
    final r = Random(5);
    const cols = [Color(0xFFFFD43B), Color(0xFFFFE8A3), Color(0xFFD4A017), Colors.white];
    for (int i = 0; i < 80; i++) {
      final x = r.nextDouble() * s.width + sin(t * 2 + i) * 14;
      final sp = 90 + r.nextDouble() * 120;
      final y = -20 + (t - r.nextDouble() * 0.6) * sp;
      if (y < -20 || y > s.height) continue;
      c.save();
      c.translate(x, y);
      c.rotate(t * 4 + i);
      c.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), Paint()..color = cols[i % cols.length]);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _GoldConfetti o) => true;
}
