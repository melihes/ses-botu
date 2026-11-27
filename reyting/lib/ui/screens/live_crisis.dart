import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../core/theme.dart';
import '../../engine/game.dart';
import '../../models/models.dart';
import '../widgets/common.dart';

/// Canlı yayın krizi katmanı: sahnenin üstünde alarm, geri sayım, seçenekler
/// ve sonuç animasyonu. Kriz sırasında [onActive] ile akış durdurulur.
class CrisisLayer extends StatefulWidget {
  final Show show;
  final Widget child;
  final ValueChanged<bool> onActive;
  const CrisisLayer({super.key, required this.show, required this.child, required this.onActive});
  @override
  State<CrisisLayer> createState() => _CrisisLayerState();
}

enum _Phase { idle, intro, choose, suspense, result, outro }

class _CrisisLayerState extends State<CrisisLayer> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  Duration _now = Duration.zero;
  Duration _phaseAt = Duration.zero;
  _Phase _phase = _Phase.idle;
  LiveCrisis? _crisis;
  CrisisOutcome? _out;
  int _picked = -1;
  late Duration _next;
  final _r = Random();
  int _seed = 0;

  static const _intro = 1600, _choose = 9000, _suspense = 1900, _result = 3600, _outro = 500;

  @override
  void initState() {
    super.initState();
    // ilk kriz izlemeye başladıktan 14-32 saniye sonra
    _next = Duration(seconds: 14 + _r.nextInt(18));
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    // kriz açıkken ekran kapatılırsa: süre dolmuş sayılır (kaçarak yeni kriz denenemez)
    final c = _crisis;
    if (c != null && (_phase == _Phase.intro || _phase == _Phase.choose)) {
      final g = _game, show = widget.show;
      // ağaç kapanırken bildirim yapılmasın diye bir sonraki adımda
      Future.microtask(() => g?.resolveCrisis(show, c, -1));
    }
    _ticker.dispose();
    super.dispose();
  }

  Game? _game;
  Duration _last = Duration.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _game = GameScope.read(context);
  }

  double get _p => (_now - _phaseAt).inMilliseconds.toDouble();

  void _go(_Phase p) {
    _phase = p;
    _phaseAt = _now;
  }

  void _tick(Duration e) {
    // kendi saatimiz: telefon kilitlenip açılınca süre bir anda dolmasın
    final dt = e - _last;
    _last = e;
    _now += dt > const Duration(milliseconds: 100) ? const Duration(milliseconds: 100) : dt;
    e = _now;
    final wasIdle = _phase == _Phase.idle;
    switch (_phase) {
      case _Phase.idle:
        if (e >= _next) {
          final game = GameScope.read(context);
          final c = game.rollCrisis(widget.show);
          if (c == null) {
            _next = e + const Duration(seconds: 30);
          } else {
            _crisis = c;
            _out = null;
            _picked = -1;
            _seed = _r.nextInt(1 << 20);
            widget.onActive(true);
            _go(_Phase.intro);
          }
        }
      case _Phase.intro:
        if (_p >= _intro) _go(_Phase.choose);
      case _Phase.choose:
        if (_p >= _choose) _pick(-1);
      case _Phase.suspense:
        if (_p >= _suspense) _go(_Phase.result);
      case _Phase.result:
        if (_p >= _result) _go(_Phase.outro);
      case _Phase.outro:
        if (_p >= _outro) {
          _crisis = null;
          _phase = _Phase.idle;
          _next = e + Duration(seconds: 40 + _r.nextInt(40));
          widget.onActive(false);
        }
    }
    // boştayken her karede yeniden çizme (sahne kendi animasyonunu yapar)
    if (mounted && !(wasIdle && _phase == _Phase.idle)) setState(() {});
  }

  void _pick(int i) {
    if (_phase != _Phase.choose || _crisis == null) return;
    final game = GameScope.read(context);
    _picked = i;
    _out = game.resolveCrisis(widget.show, _crisis!, i);
    _go(i < 0 ? _Phase.result : _Phase.suspense);
  }

  @override
  Widget build(BuildContext context) {
    final c = _crisis;
    final t = _now.inMilliseconds / 1000.0;
    // sahne sarsıntısı: kriz girişinde ve başarısızlıkta
    var shake = 0.0;
    if (_phase == _Phase.intro && (c?.def.fx == 3 || c?.def.fx == 2)) {
      shake = 7 * (1 - _p / _intro).clamp(0.0, 1.0);
    } else if (_phase == _Phase.result && _out?.win == false) {
      shake = 5 * (1 - _p / 900).clamp(0.0, 1.0);
    }
    final dx = shake * sin(t * 61), dy = shake * cos(t * 47);
    return Stack(fit: StackFit.expand, children: [
      Transform.translate(offset: Offset(dx, dy), child: widget.child),
      if (c != null) ..._layers(c, t),
    ]);
  }

  List<Widget> _layers(LiveCrisis c, double t) {
    final out = _out;
    final win = out?.win == true;
    final pIntro = _phase == _Phase.intro ? (_p / _intro).clamp(0.0, 1.0) : 1.0;
    final fadeOut = _phase == _Phase.outro ? 1 - (_p / _outro).clamp(0.0, 1.0) : 1.0;
    return [
      // karartma
      IgnorePointer(
        child: Container(
          color: Colors.black.withValues(
              alpha: (0.55 * (_phase == _Phase.intro ? pIntro : 1) * fadeOut).toDouble()),
        ),
      ),
      // parazit / glitch
      if (_phase == _Phase.intro || (_phase == _Phase.result && !win && _p < 1400))
        IgnorePointer(
          child: CustomPaint(
            painter: _GlitchPainter(
              t: t,
              seed: _seed,
              power: _phase == _Phase.intro ? (1 - pIntro * 0.6) : (1 - _p / 1400),
              dark: c.def.fx == 1,
            ),
          ),
        ),
      // alarm şeritleri (üst ve alt)
      if (_phase == _Phase.intro || _phase == _Phase.choose)
        IgnorePointer(child: CustomPaint(painter: _HazardPainter(t: t, show: pIntro))),
      // içerik
      Opacity(opacity: fadeOut.toDouble(), child: _content(c, t, pIntro)),
      // konfeti
      if (_phase == _Phase.result && win)
        IgnorePointer(child: CustomPaint(painter: _ConfettiPainter(t: _p / 1000, seed: _seed))),
    ];
  }

  Widget _content(LiveCrisis c, double t, double pIntro) {
    return LayoutBuilder(builder: (ctx, box) {
      final small = box.maxWidth < 520 || box.maxHeight < 300;
      switch (_phase) {
        case _Phase.intro:
          return _introView(c, t, pIntro, small);
        case _Phase.choose:
          return _chooseView(c, t, small);
        case _Phase.suspense:
          return _suspenseView(c, t, small);
        case _Phase.result:
        case _Phase.outro:
          return _resultView(c, t, small);
        case _Phase.idle:
          return const SizedBox.shrink();
      }
    });
  }

  // ------------------------------------------------------------------
  Widget _banner(double slide, {required String text, required Color color}) {
    return Transform.translate(
      offset: Offset(-600 * (1 - Curves.easeOutBack.transform(slide.clamp(0.0, 1.0))), 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 18)],
        ),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: Colors.white)),
      ),
    );
  }

  Widget _introView(LiveCrisis c, double t, double p, bool small) {
    final pop = Curves.elasticOut.transform(((p - 0.25) / 0.6).clamp(0.0, 1.0));
    final blink = (sin(t * 18) > 0) ? 1.0 : 0.55;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Opacity(
          opacity: blink,
          child: _banner(p / 0.35, text: '⚠ CANLI YAYIN KRİZİ', color: AppColors.red),
        ),
        SizedBox(height: small ? 8 : 14),
        Transform.scale(
          scale: 0.2 + pop * 0.8,
          child: Transform.rotate(
            angle: (1 - pop) * 0.6,
            child: Text(c.def.emoji, style: TextStyle(fontSize: small ? 54 : 76)),
          ),
        ),
        SizedBox(height: small ? 4 : 8),
        Opacity(
          opacity: ((p - 0.45) / 0.3).clamp(0.0, 1.0),
          child: Text(c.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: small ? 20 : 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 8)])),
        ),
      ]),
    );
  }

  Widget _chooseView(LiveCrisis c, double t, bool small) {
    final left = ((_choose - _p) / 1000).clamp(0.0, 99.0);
    final frac = (left / (_choose / 1000)).clamp(0.0, 1.0);
    final urgent = left < 3;
    // harf harf yazılır (emoji ortadan bölünmesin diye karakter karakter)
    final chars = c.desc.characters;
    final typed = (chars.length * (_p / 900)).clamp(0, chars.length).round();
    return Padding(
      padding: EdgeInsets.all(small ? 6 : 12),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c.def.emoji, style: TextStyle(fontSize: small ? 26 : 34)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(c.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: small ? 15 : 19, color: Colors.white)),
              Text(chars.take(typed).toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: small ? 11 : 13, color: Colors.white70)),
            ]),
          ),
          const SizedBox(width: 8),
          // geri sayım halkası
          Transform.scale(
            scale: urgent ? 1 + 0.08 * sin(t * 20).abs() : 1,
            child: SizedBox(
              width: small ? 42 : 54,
              height: small ? 42 : 54,
              child: Stack(alignment: Alignment.center, children: [
                CircularProgressIndicator(
                  value: frac,
                  strokeWidth: 5,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation(urgent ? AppColors.red : AppColors.yellow),
                ),
                Text('${left.ceil()}',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: small ? 16 : 20,
                        color: urgent ? AppColors.red : Colors.white)),
              ]),
            ),
          ),
        ]),
        const Spacer(),
        Text('Reji sende! Ne yapacaksın?',
            style: TextStyle(color: AppColors.yellow, fontWeight: FontWeight.w900, fontSize: small ? 11 : 13)),
        SizedBox(height: small ? 4 : 8),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (int i = 0; i < c.options.length; i++) ...[
            if (i > 0) SizedBox(width: small ? 5 : 8),
            Expanded(child: _optionCard(c, i, small)),
          ],
        ]),
      ]),
    );
  }

  Widget _optionCard(LiveCrisis c, int i, bool small) {
    final o = c.options[i];
    final ch = c.chances[i];
    final appear = Curves.easeOutBack.transform(((_p - 150 - i * 140) / 450).clamp(0.0, 1.0));
    final color = ch >= 0.7 ? AppColors.green : (ch >= 0.45 ? AppColors.yellow : AppColors.red);
    return Opacity(
      opacity: appear.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, 60 * (1 - appear)),
        child: Material(
          color: const Color(0xEE1A1428),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _pick(i),
            child: Container(
              padding: EdgeInsets.all(small ? 6 : 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(o.emoji, style: TextStyle(fontSize: small ? 16 : 22)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(o.label,
                        maxLines: 2,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: small ? 11 : 13, color: Colors.white)),
                  ),
                ]),
                SizedBox(height: small ? 3 : 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: ch,
                    minHeight: small ? 4 : 6,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 3),
                Text('Şans %${(ch * 100).round()}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: small ? 10 : 11)),
                Text('Ödül +%${(22 * o.reward).round()} · Risk -%${(8 * o.risk).round()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white60, fontSize: small ? 9 : 10)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _suspenseView(LiveCrisis c, double t, bool small) {
    final o = c.options[_picked];
    final p = (_p / _suspense).clamp(0.0, 1.0);
    // ibre sağa sola sallanır, sonunda sonuca oturur
    final target = _out!.win ? -0.7 : 0.7;
    final wobble = sin(t * 14) * (1 - p) * 1.1;
    final needle = target * Curves.easeOut.transform(p) + wobble;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(o.emoji, style: TextStyle(fontSize: small ? 40 : 56)),
        Text(o.label,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: small ? 16 : 20, color: Colors.white)),
        SizedBox(height: small ? 8 : 14),
        SizedBox(
          width: small ? 180 : 240,
          height: small ? 90 : 120,
          child: CustomPaint(painter: _GaugePainter(needle: needle.clamp(-1.2, 1.2).toDouble())),
        ),
        const SizedBox(height: 6),
        Text('Seyirci nefesini tuttu${'.' * (1 + (t * 3).floor() % 3)}',
            style: TextStyle(color: Colors.white70, fontSize: small ? 11 : 13)),
      ]),
    );
  }

  Widget _resultView(LiveCrisis c, double t, bool small) {
    final out = _out!;
    final win = out.win;
    final p = _p / 1000;
    final stamp = Curves.elasticOut.transform((p / 0.9).clamp(0.0, 1.0));
    final color = win ? AppColors.yellow : AppColors.red;
    final delta = (out.ratingDelta * 100 * Curves.easeOut.transform((p / 1.4).clamp(0.0, 1.0))).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Transform.rotate(
            angle: -0.18 + (1 - stamp) * 0.5,
            child: Transform.scale(
              scale: 2.4 - stamp * 1.4,
              child: Opacity(
                opacity: stamp.clamp(0.0, 1.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: color, width: 4),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black.withValues(alpha: 0.3),
                  ),
                  child: Text(win ? (out.ratingDelta >= 0.2 ? 'VİRAL!' : 'KURTARDIN!') : 'REZALET!',
                      style: TextStyle(
                          fontSize: small ? 28 : 40,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: color)),
                ),
              ),
            ),
          ),
          SizedBox(height: small ? 8 : 14),
          Opacity(
            opacity: ((p - 0.3) / 0.4).clamp(0.0, 1.0),
            child: Text(out.text,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: small ? 12 : 15,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 6)])),
          ),
          SizedBox(height: small ? 6 : 10),
          Opacity(
            opacity: ((p - 0.6) / 0.4).clamp(0.0, 1.0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(win ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  color: win ? AppColors.green : AppColors.red, size: small ? 22 : 30),
              const SizedBox(width: 6),
              Text('Reyting ${delta >= 0 ? '+' : ''}%$delta',
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: small ? 18 : 24,
                      color: win ? AppColors.green : AppColors.red)),
              const SizedBox(width: 8),
              Text(win ? '(2 gün)' : '(1 gün)',
                  style: const TextStyle(color: Colors.white60, fontSize: 12)),
            ]),
          ),
          if (win)
            Opacity(
              opacity: ((p - 1.0) / 0.4).clamp(0.0, 1.0),
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('📱 Sosyal medya bu anı konuşuyor!',
                    style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w800, fontSize: small ? 11 : 13)),
              ),
            ),
        ]),
      ),
    );
  }
}

// ======================================================================
// Çizimler
// ======================================================================

/// Bozuk yayın görüntüsü: renkli yatay şeritler ve kar
class _GlitchPainter extends CustomPainter {
  final double t, power;
  final int seed;
  final bool dark;
  _GlitchPainter({required this.t, required this.power, required this.seed, required this.dark});

  @override
  void paint(Canvas canvas, Size size) {
    if (power <= 0) return;
    final frame = (t * 24).floor();
    final r = Random(seed + frame);
    final paint = Paint();
    if (dark) {
      paint.color = Colors.black.withValues(alpha: 0.6 * power);
      canvas.drawRect(Offset.zero & size, paint);
    }
    // şeritler
    for (int i = 0; i < (10 * power).ceil() + 2; i++) {
      final y = r.nextDouble() * size.height;
      final h = 2 + r.nextDouble() * 18 * power;
      final colors = [const Color(0xFF00E5FF), const Color(0xFFFF2D95), Colors.white, const Color(0xFF39FF14)];
      paint.color = colors[r.nextInt(colors.length)].withValues(alpha: 0.12 + 0.3 * power * r.nextDouble());
      final x = (r.nextDouble() - 0.5) * 40 * power;
      canvas.drawRect(Rect.fromLTWH(x, y, size.width, h), paint);
    }
    // kar (nokta parazit)
    paint.color = Colors.white.withValues(alpha: 0.35 * power);
    for (int i = 0; i < (260 * power).round(); i++) {
      canvas.drawRect(Rect.fromLTWH(r.nextDouble() * size.width, r.nextDouble() * size.height, 2, 2), paint);
    }
    // tarama çizgileri
    paint.color = Colors.black.withValues(alpha: 0.18 * power);
    for (double y = (t * 60) % 4; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlitchPainter old) => true;
}

/// Sarı-siyah alarm şeritleri (üstte ve altta kayar)
class _HazardPainter extends CustomPainter {
  final double t, show;
  _HazardPainter({required this.t, required this.show});
  @override
  void paint(Canvas canvas, Size size) {
    const h = 10.0;
    final shift = (t * 40) % 28;
    final yel = Paint()..color = const Color(0xFFFFC400).withValues(alpha: 0.85 * show);
    final blk = Paint()..color = Colors.black.withValues(alpha: 0.85 * show);
    for (final y in [0.0, size.height - h]) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, y, size.width, h));
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, h), blk);
      for (double x = -28 + shift; x < size.width + 28; x += 28) {
        final path = Path()
          ..moveTo(x, y + h)
          ..lineTo(x + 14, y)
          ..lineTo(x + 28, y)
          ..lineTo(x + 14, y + h)
          ..close();
        canvas.drawPath(path, yel);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _HazardPainter old) => true;
}

/// Konfeti patlaması
class _ConfettiPainter extends CustomPainter {
  // her karede yeniden ölçülmesin
  static final _emojis = [
    for (final e in ['❤️', '👏', '🔥', '😂'])
      TextPainter(text: TextSpan(text: e, style: const TextStyle(fontSize: 18)), textDirection: TextDirection.ltr)
        ..layout(),
  ];
  final double t; // saniye
  final int seed;
  _ConfettiPainter({required this.t, required this.seed});
  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(seed);
    final paint = Paint();
    const colors = [
      Color(0xFFFFC400), Color(0xFFFF2D95), Color(0xFF00E5FF), Color(0xFF39FF14), Colors.white, Color(0xFFFF6B3D),
    ];
    final origin = Offset(size.width / 2, size.height * 0.42);
    for (int i = 0; i < 90; i++) {
      final a = r.nextDouble() * pi * 2;
      final v = 120 + r.nextDouble() * 320;
      final spin = r.nextDouble() * 10;
      final delay = r.nextDouble() * 0.25;
      final tt = (t - delay).clamp(0.0, 9.0);
      final x = origin.dx + cos(a) * v * tt;
      final y = origin.dy + sin(a) * v * tt + 260 * tt * tt;
      final life = (1 - tt / 3.2).clamp(0.0, 1.0);
      if (life <= 0) continue;
      paint.color = colors[i % colors.length].withValues(alpha: life);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(spin * tt);
      canvas.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), paint);
      canvas.restore();
    }
    // yükselen kalpler
    for (int i = 0; i < 14; i++) {
      final x = size.width * (0.1 + 0.8 * r.nextDouble());
      final sp = 60 + r.nextDouble() * 80;
      final y = size.height + 20 - (t - i * 0.12).clamp(0.0, 9.0) * sp;
      if (y > size.height + 10) continue;
      _emojis[i % 4].paint(canvas, Offset(x + sin(t * 3 + i) * 10, y));
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) => true;
}

/// Gerilim ibresi: solda yeşil (başarı), sağda kırmızı
class _GaugePainter extends CustomPainter {
  final double needle; // -1 sol … 1 sağ
  _GaugePainter({required this.needle});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height);
    final rad = min(size.width / 2, size.height) - 6;
    final rect = Rect.fromCircle(center: c, radius: rad);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    p.shader = const SweepGradient(
      startAngle: pi,
      endAngle: 2 * pi,
      colors: [Color(0xFF39FF14), Color(0xFFFFC400), Color(0xFFFF3B30)],
    ).createShader(rect);
    canvas.drawArc(rect, pi, pi, false, p);
    final ang = -pi / 2 + needle * (pi / 2) * 0.85;
    final tip = c + Offset(cos(ang), sin(ang)) * (rad - 4);
    canvas.drawLine(
        c,
        tip,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(c, 7, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.needle != needle;
}
