import '../../core/format.dart';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../data/content.dart';
import '../../engine/live_script.dart';
import '../widgets/ambience.dart';
import '../widgets/face.dart';

/// Canlı yayındaki bir kişi
class LivePerson {
  final String who;
  final FaceSpec face;
  final int key;
  const LivePerson(this.who, this.face, this.key);
}

enum _Shot { opening, wide, two, closeL, closeR, audience, split, bumper, drama }

/// Gerçek TV yayını gibi: jenerik, kamera planları (geniş, yakın, omuz üstü,
/// seyirci), türe ve formata özel dekor, konuşan/göz kırpan karakterler,
/// alt yazı, isim bandı, kayan haber bandı, reklam arası geçişi.
///
/// Tasarım 640 genişlikte bir tuval üzerine yapılır ve ekrana ölçeklenir.
class LiveStage extends StatefulWidget {
  final Genre genre;
  final Prop prop;
  final String title;
  final String channel;
  final Widget channelLogo;
  final Color color;
  final LiveBeat? beat;
  final int beatId;
  final String ticker;
  final Widget? board;
  final LivePerson host;
  final LivePerson guest;
  final Map<String, LivePerson> people;
  final List<FaceSpec> crowd;
  final int seed;

  /// Seyircinin keyfi 0..1 (reytinge göre)
  final double audience;

  const LiveStage({
    super.key,
    this.audience = 0.5,
    required this.genre,
    required this.prop,
    required this.title,
    required this.channel,
    required this.channelLogo,
    required this.color,
    required this.beat,
    required this.beatId,
    required this.ticker,
    required this.board,
    required this.host,
    required this.guest,
    required this.people,
    required this.crowd,
    required this.seed,
  });

  @override
  State<LiveStage> createState() => _LiveStageState();
}

class _LiveStageState extends State<LiveStage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  double _t = 0;
  double _shotStart = 0;
  _Shot _shot = _Shot.opening;
  int _lastBeat = -1;
  int _beats = 0;
  bool _flip = false;
  final _r = Random();

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => setState(() => _t = d.inMicroseconds / 1e6))..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  bool get _hasAudience => const {
        Prop.morning, Prop.nightShow, Prop.standup, Prop.sketch, Prop.newYear, //
        Prop.quiz, Prop.couples, Prop.wheel, Prop.voice, Prop.talent,
        Prop.gossip, Prop.redCarpet, Prop.awards, Prop.paparazzi,
        Prop.cartoon, Prop.puppet, Prop.lab, Prop.kidsStage,
        Prop.football, Prop.basketball, Prop.derby, Prop.tournament, Prop.sportsDesk,
        Prop.island, Prop.studio,
      }.contains(widget.prop);

  void _pickShot() {
    final b = widget.beat;
    _beats++;
    _shotStart = _t;
    if (_beats == 1) {
      _shot = _Shot.opening;
      return;
    }
    if (_beats % 17 == 0) {
      _shot = _Shot.bumper;
      return;
    }
    if (b == null) {
      _shot = _Shot.wide;
      return;
    }
    final g = widget.genre;
    if (b.reaction == 1 || b.reaction == 2) {
      if (_hasAudience) {
        _shot = _Shot.audience;
        return;
      }
      if (g == Genre.dizi) {
        _shot = _Shot.drama;
        return;
      }
    }
    if (b.reaction == 3 && g == Genre.dizi) {
      _shot = _Shot.drama;
      return;
    }
    if (b.side == 2) {
      _shot = _Shot.wide;
      return;
    }
    if (g == Genre.haber && b.side == 1) {
      _shot = _Shot.split;
      return;
    }
    if (g == Genre.belgesel && _r.nextDouble() < 0.5) {
      _shot = _Shot.wide;
      return;
    }
    final roll = _r.nextDouble();
    if (roll < 0.22) {
      _shot = _Shot.two;
    } else if (roll < 0.3) {
      _shot = _Shot.wide;
    } else {
      _shot = b.side == 0 ? _Shot.closeL : _Shot.closeR;
    }
    _flip = !_flip;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.beatId != _lastBeat) {
      _lastBeat = widget.beatId;
      _pickShot();
    }
    return LayoutBuilder(builder: (context, c) {
      const w = 640.0;
      final h = (w * c.maxHeight / max(1, c.maxWidth)).clamp(300.0, 480.0);
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(width: w, height: h, child: _frame(w, h)),
        ),
      );
    });
  }

  // ------------------------------------------------------------------
  double get _u => _t - _shotStart;

  LivePerson? get _speaker {
    final b = widget.beat;
    if (b == null) return null;
    return widget.people[b.who] ?? (b.side == 0 ? widget.host : (b.side == 1 ? widget.guest : null));
  }

  bool _talking(LivePerson p) {
    final b = widget.beat;
    if (b == null || _speaker?.key != p.key) return false;
    return _u * 28 < b.text.length + 4;
  }

  FaceMood _moodOf(LivePerson p) {
    final b = widget.beat;
    if (_talking(p)) return FaceMood.talk;
    if (b == null) return FaceMood.neutral;
    return switch (b.reaction) {
      1 => FaceMood.laugh,
      2 => FaceMood.smile,
      3 => FaceMood.surprised,
      _ => FaceMood.smile,
    };
  }

  bool _blink(int key) => ((_t + (key % 997) / 211) % 2.9) < 0.12;

  Widget _face(LivePerson p, double size, {bool crop = true, String? gesture, bool flipX = false}) {
    final mood = _moodOf(p);
    final alt = (_t * 8).floor().isEven;
    Widget f = FaceView(
      spec: p.face,
      cacheKey: p.key,
      mood: mood,
      alt: alt,
      blink: _blink(p.key),
      crop: crop,
      gesture: gesture,
      size: size,
    );
    if (flipX) f = Transform.flip(flipX: true, child: f);
    return f;
  }

  Widget _frame(double w, double h) {
    final shot = _shot;
    final shake = (shot != _Shot.opening && shot != _Shot.bumper)
        ? Offset(sin(_t * 9) * 1.2, cos(_t * 7) * 1.2)
        : Offset.zero;
    final children = <Widget>[
      Positioned.fill(child: Transform.translate(offset: shake, child: _shotView(shot, w, h))),
      ..._overlays(shot, w, h),
    ];
    // kesme flaşı
    if (_u < 0.1 && _beats > 1) {
      children.add(Positioned.fill(
        child: IgnorePointer(
          child: ColoredBox(color: Colors.white.withValues(alpha: (1 - _u / 0.1) * 0.55)),
        ),
      ));
    }
    return Stack(clipBehavior: Clip.hardEdge, children: children);
  }

  Widget _set({double pan = 0, double blur = 0, double zoom = 1}) {
    final amb = Ambience.of(context);
    Widget s = Stack(fit: StackFit.expand, children: [
      CustomPaint(
        painter: SetPainter(widget.prop, widget.genre, _t, widget.color, widget.title, pan, widget.seed),
        size: Size.infinite,
      ),
      // saate göre ışık, mevsim ve bayram süsleri
      CustomPaint(painter: LightPainter(amb), size: Size.infinite),
      CustomPaint(painter: DecorPainter(amb, _t), size: Size.infinite),
    ]);
    if (zoom != 1) s = Transform.scale(scale: zoom, child: s);
    if (blur > 0) {
      s = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: s);
    }
    return s;
  }

  Widget _shotView(_Shot shot, double w, double h) {
    final host = widget.host, guest = widget.guest;
    switch (shot) {
      case _Shot.opening:
        return _OpeningView(t: _u, title: widget.title, color: widget.color, genre: widget.genre);
      case _Shot.bumper:
        return _BumperView(t: _u, title: widget.title, color: widget.color);
      case _Shot.wide:
        final pan = _u * 14;
        final noPeople = widget.genre == Genre.belgesel ||
            const {Prop.football, Prop.derby, Prop.tournament, Prop.basketball}.contains(widget.prop);
        final furn = FrontPainter.hasFurniture(widget.prop);
        final size = furn ? 190.0 : 260.0;
        final bottom = furn ? h * 0.2 : -h * 0.02;
        return Stack(children: [
          Positioned.fill(child: _set(pan: pan, zoom: 1 + _u * 0.01)),
          if (!noPeople) ...[
            Positioned(
              left: w * 0.07 - pan * 0.6,
              bottom: bottom,
              child: _withRim(_face(host, size, crop: false, gesture: _talking(host) ? 'hand' : null),
                  const Color(0xFFFF4F8B)),
            ),
            if (_twoPeople)
              Positioned(
                right: w * 0.06 + pan * 0.6,
                bottom: bottom - (furn ? 4 : 0),
                child: _withRim(
                    _face(guest, size, crop: false, gesture: _talking(guest) ? 'waveLongArm' : null),
                    const Color(0xFF4DABF7)),
              ),
          ],
          Positioned.fill(
              child: CustomPaint(
                  painter: FrontPainter(widget.prop, widget.genre, _t, pan, widget.title, audience: widget.audience))),
        ]);
      case _Shot.two:
        return Stack(children: [
          Positioned.fill(child: _set(blur: 3, zoom: 1.25, pan: 30)),
          Positioned(
            left: w * 0.02,
            top: h * 0.12,
            child: _withRim(_face(host, 300), const Color(0xFFFF4F8B)),
          ),
          if (_twoPeople)
            Positioned(
              right: w * 0.02,
              top: h * 0.14,
              child: _withRim(_face(guest, 290, flipX: true), const Color(0xFF4DABF7)),
            ),
        ]);
      case _Shot.closeL:
      case _Shot.closeR:
        final p = _speaker ?? (shot == _Shot.closeL ? host : guest);
        final other = p.key == host.key ? guest : host;
        final z = 1 + _u * 0.025;
        final ots = shot == _Shot.closeR && _twoPeople && _flip;
        return Stack(children: [
          Positioned.fill(child: _set(blur: 5, zoom: 1.4, pan: shot == _Shot.closeL ? -40 : 40)),
          Positioned.fill(child: CustomPaint(painter: _BokehPainter(_t, widget.color))),
          Positioned(
            left: (w - 430 * z) / 2 + (ots ? 50 : 0),
            top: -46 - _u * 3,
            child: Transform.rotate(
              angle: sin(_u * 2.4) * 0.025,
              child: _withRim(_face(p, 430 * z),
                  shot == _Shot.closeL ? const Color(0xFFFF4F8B) : const Color(0xFF4DABF7)),
            ),
          ),
          if (ots)
            Positioned(
              left: -190,
              top: 60,
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Color(0x99000000), BlendMode.srcATop),
                  child: _face(other, 520, flipX: true),
                ),
              ),
            ),
        ]);
      case _Shot.drama:
        final p = _speaker ?? host;
        final z = 1.1 + _u * 0.06;
        return Stack(children: [
          Positioned.fill(child: _set(blur: 6, zoom: 1.5)),
          Positioned(
            left: (w - 430 * z) / 2,
            top: -60 - _u * 6,
            child: _face(p, 430 * z),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.85,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                    stops: const [0.55, 1],
                  ),
                ),
              ),
            ),
          ),
        ]);
      case _Shot.split:
        return Row(children: [
          Expanded(
            child: ClipRect(
              child: Stack(children: [
                Positioned.fill(child: _set(blur: 4, zoom: 1.3)),
                Positioned(left: -60, top: 10, child: _face(host, 380)),
              ]),
            ),
          ),
          Container(width: 4, color: Colors.white),
          Expanded(
            child: ClipRect(
              child: Stack(children: [
                Positioned.fill(
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                    child: CustomPaint(painter: SetPainter(Prop.field, Genre.haber, _t, widget.color, '', 0, widget.seed)),
                  ),
                ),
                Positioned(left: -40, top: 10, child: _face(guest, 380)),
                Positioned(
                  left: 8,
                  top: 40,
                  child: _pill('CANLI BAĞLANTI', const Color(0xFFE11D48)),
                ),
              ]),
            ),
          ),
        ]);
      case _Shot.audience:
        return _audience(w, h);
    }
  }

  bool get _twoPeople => widget.guest.key != widget.host.key;

  Widget _withRim(Widget child, Color c) => DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: c.withValues(alpha: 0.0), blurRadius: 0)],
        ),
        child: Stack(children: [
          Transform.translate(
            offset: const Offset(-3, 0),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(c.withValues(alpha: 0.55), BlendMode.srcATop),
              child: child,
            ),
          ),
          child,
        ]),
      );

  Widget _audience(double w, double h) {
    final crowd = widget.crowd;
    final sport = widget.genre == Genre.spor;
    final island = widget.prop == Prop.island;
    final cheer = widget.beat?.reaction == 2;
    final laugh = widget.beat?.reaction == 1;
    final kids = <Widget>[
      Positioned.fill(
        child: CustomPaint(painter: _AudienceBgPainter(_t, widget.color, sport: sport, island: island)),
      ),
    ];
    for (int r = 0; r < 2; r++) {
      for (int i = 0; i < 7; i++) {
        final k = r * 7 + i;
        if (k >= crowd.length) break;
        final f = crowd[k];
        final jump = sin(_u * 13 + k) * (cheer ? 8 : 3);
        final mood = laugh ? FaceMood.laugh : (cheer ? FaceMood.smile : FaceMood.smile);
        kids.add(Positioned(
          left: i * 92.0 - 30 + r * 46,
          bottom: (r == 0 ? h * 0.30 : -h * 0.12) + jump,
          child: Opacity(
            opacity: r == 0 ? 0.85 : 1,
            child: FaceView(
              spec: f,
              cacheKey: 50000 + k,
              mood: mood,
              alt: (_t * 6 + k).floor().isEven,
              blink: _blink(k * 31),
              crop: false,
              gesture: (cheer && k.isEven) || (laugh && k % 3 == 0) ? 'waveLongArms' : null,
              size: r == 0 ? 140 : 190,
            ),
          ),
        ));
      }
    }
    kids.add(Positioned.fill(
      child: CustomPaint(painter: _ConfettiPainter(_u, cheer, laugh, sport)),
    ));
    return Stack(children: kids);
  }

  Widget _pill(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(5)),
        child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
      );

  List<Widget> _overlays(_Shot shot, double w, double h) {
    final out = <Widget>[];
    // köşe logosu ve CANLI
    out.add(Positioned(
      left: 10,
      top: 8,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 3, 10, 3),
        decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(width: 22, height: 22, child: widget.channelLogo),
          const SizedBox(width: 6),
          Text(trUpper(widget.channel),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
      ),
    ));
    if (shot == _Shot.opening || shot == _Shot.bumper) return out;
    out.add(Positioned(
      right: 10,
      top: 8,
      child: Opacity(
        opacity: 0.75 + 0.25 * sin(_t * 5),
        child: _pill(widget.genre == Genre.haber ? '● CANLI · SON DAKİKA' : '● CANLI', const Color(0xFFE11D48)),
      ),
    ));
    if (widget.board != null) out.add(Positioned(right: 10, top: 40, child: widget.board!));

    // isim bandı
    final sp = _speaker;
    final b = widget.beat;
    String? name, role;
    if (shot == _Shot.closeL || shot == _Shot.closeR || shot == _Shot.drama) {
      final p = sp ?? (shot == _Shot.closeL ? widget.host : widget.guest);
      name = p.who;
      role = p.key == widget.host.key
          ? (widget.genre == Genre.haber ? 'Spiker' : (widget.genre == Genre.dizi ? 'Başrol' : 'Sunucu'))
          : (widget.genre == Genre.yarisma ? 'Yarışmacı' : (widget.genre == Genre.dizi ? 'Oyuncu' : 'Konuk'));
    } else if (shot == _Shot.wide && widget.genre != Genre.dizi) {
      name = trUpper(widget.title);
      role = '${widget.guest.who} · ${widget.host.who}';
    }
    if (name != null) {
      final open = min(1.0, _u * 4);
      out.add(Positioned(
        left: 20,
        bottom: 84,
        child: ClipRect(
          child: Align(
            alignment: Alignment.centerLeft,
            widthFactor: open,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.fromLTRB(12, 4, 14, 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [widget.color, Color.lerp(widget.color, const Color(0xFF7A3CFF), 0.6)!]),
                ),
                child: Text(name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(12, 2, 14, 2),
                child: Text(role ?? '',
                    style: const TextStyle(color: Color(0xFF1A1033), fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ]),
          ),
        ),
      ));
    }
    // alt yazı (harf harf)
    if (b != null && (shot != _Shot.audience || b.side == 2)) {
      // karakter karakter (emoji ortadan bölünürse yazı çöker)
      final chars = b.text.characters;
      final n = min(chars.length, (_u * 28).floor());
      final txt = (b.side == 2 ? '' : '${b.who}: ') + chars.take(n).toString();
      out.add(Positioned(
        left: 40,
        right: 40,
        bottom: 36,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(8)),
            child: Text(
              n < b.text.length ? '$txt▌' : txt,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontStyle: b.side == 2 ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ),
      ));
    }
    if (shot == _Shot.audience && b != null) {
      final txt = switch (b.reaction) {
        1 => '😂 Kahkaha tufanı!',
        2 => widget.genre == Genre.spor ? '⚽ Tribünler ayakta!' : '👏 Alkış! Stüdyo ayakta!',
        _ => '😱 Seyirci şaşkın!',
      };
      out.add(Positioned(
        left: 0,
        right: 0,
        bottom: 96,
        child: Center(
          child: Transform.scale(
            scale: 0.8 + 0.2 * Curves.easeOutBack.transform(min(1, _u * 3)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(8)),
              child: Text(txt, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ));
    }
    // kayan bant
    out.add(Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: 28,
      child: Container(
        color: Colors.white,
        child: Row(children: [
          Container(
            color: const Color(0xFFE11D48),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            child: Text(widget.genre == Genre.haber ? 'SON DAKİKA' : 'GÜNDEM',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          Expanded(
            child: ClipRect(
              child: LayoutBuilder(builder: (_, c) {
                final text = '${widget.ticker}   ·   ${widget.title} her gün ${widget.channel} ekranlarında   ·   ';
                final x = c.maxWidth - ((_t * 70) % (c.maxWidth + text.length * 7.2));
                return Stack(children: [
                  Positioned(
                    left: x,
                    top: 6,
                    child: Text(text,
                        softWrap: false,
                        style: const TextStyle(color: Color(0xFF1A1033), fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                ]);
              }),
            ),
          ),
        ]),
      ),
    ));
    return out;
  }
}

// ======================================================================
// Jenerik ve reklam geçişi
// ======================================================================
class _OpeningView extends StatelessWidget {
  final double t;
  final String title;
  final Color color;
  final Genre genre;
  const _OpeningView({required this.t, required this.title, required this.color, required this.genre});

  @override
  Widget build(BuildContext context) {
    final u = min(1.0, t / 1.6);
    final s = 0.3 + Curves.easeOutBack.transform(min(1, u * 1.6)) * 0.7;
    final rot = (1 - min(1, u * 2)) * -0.5;
    return Stack(children: [
      Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(colors: [Color.lerp(color, Colors.black, 0.35)!, const Color(0xFF07030F)]),
          ),
        ),
      ),
      Positioned.fill(child: CustomPaint(painter: _BokehPainter(t * 3, color))),
      Positioned.fill(child: CustomPaint(painter: _BurstPainter(u))),
      Center(
        child: Transform.rotate(
          angle: rot,
          child: Transform.scale(
            scale: s,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ShaderMask(
                shaderCallback: (r) => LinearGradient(
                  colors: [const Color(0xFFFFD43B), color, const Color(0xFFA64DFF)],
                ).createShader(r),
                child: Text(trUpper(title),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 54,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [Shadow(color: Colors.black54, offset: Offset(0, 4))])),
              ),
              Opacity(
                opacity: max(0.0, u * 2 - 1),
                child: Text('${trUpper(genreDefs[genre]!.label)} · CANLI',
                    style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 14)),
              ),
            ]),
          ),
        ),
      ),
    ]);
  }
}

class _BumperView extends StatelessWidget {
  final double t;
  final String title;
  final Color color;
  const _BumperView({required this.t, required this.title, required this.color});
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color, const Color(0xFF7A3CFF)],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _BokehPainter(t * 2, Colors.white))),
        Center(
          child: Transform.scale(
            scale: min(1, 0.6 + t * 2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text('BİRAZDAN',
                  style: TextStyle(color: Colors.white70, fontSize: 18, letterSpacing: 8)),
              const Text('REKLAMLAR',
                  style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('$title · birazdan devam ediyor',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ]),
          ),
        ),
      ]);
}

// ======================================================================
// Ressamlar
// ======================================================================
final _rnd = List.generate(400, (i) {
  final x = sin(i * 12.9898) * 43758.5453;
  return x - x.floorToDouble();
});
double _rn(int i) => _rnd[i % _rnd.length];

class _BokehPainter extends CustomPainter {
  final double t;
  final Color color;
  _BokehPainter(this.t, this.color);
  @override
  void paint(Canvas c, Size s) {
    final cols = [color, const Color(0xFFFFD43B), const Color(0xFF4DABF7), const Color(0xFFB197FC)];
    for (int i = 0; i < 14; i++) {
      final x = ((_rn(i) * (s.width + 60) + t * 8 * (i % 3 + 1)) % (s.width + 60)) - 30;
      final y = _rn(i + 20) * s.height * 0.85;
      final r = 10 + _rn(i + 40) * 22;
      c.drawCircle(
          Offset(x, y),
          r,
          Paint()
            ..color = cols[i % cols.length].withValues(alpha: 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }
  }

  @override
  bool shouldRepaint(covariant _BokehPainter o) => o.t != t;
}

class _BurstPainter extends CustomPainter {
  final double u;
  _BurstPainter(this.u);
  @override
  void paint(Canvas c, Size s) {
    if (u >= 1) return;
    final p = Paint()..color = Colors.white.withValues(alpha: 1 - u);
    for (int i = 0; i < 20; i++) {
      final a = i / 20 * pi * 2, d = u * s.width * 0.45;
      c.drawCircle(Offset(s.width / 2 + cos(a) * d, s.height / 2 + sin(a) * d * 0.6), 3, p);
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter o) => o.u != u;
}

class _ConfettiPainter extends CustomPainter {
  final double u;
  final bool cheer, laugh, sport;
  _ConfettiPainter(this.u, this.cheer, this.laugh, this.sport);
  @override
  void paint(Canvas c, Size s) {
    const cols = [Color(0xFFFF4F8B), Color(0xFFFFD43B), Color(0xFF4DABF7), Color(0xFF69DB7C), Color(0xFFB197FC)];
    if (cheer) {
      for (int i = 0; i < 46; i++) {
        final x = _rn(i) * s.width + sin(u * 3 + i) * 14;
        final y = ((u * 150 + _rn(i + 9) * s.height * 1.2) % (s.height + 40)) - 30;
        c.save();
        c.translate(x, y);
        c.rotate(u * 5 + i);
        c.drawRect(const Rect.fromLTWH(-4, -6, 8, 12), Paint()..color = cols[i % 5]);
        c.restore();
      }
    }
    // telefon / foto flaşları
    final k = (u * 6).floor();
    for (int i = 0; i < 4; i++) {
      if (_rn(i * 7 + k) > 0.55) {
        final o = Offset(_rn(i * 13 + k) * s.width, s.height * (0.35 + _rn(i * 3) * 0.2));
        c.drawCircle(
            o,
            14,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.85)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      }
    }
    if (laugh) {
      final tp = TextPainter(textDirection: TextDirection.ltr);
      for (int i = 0; i < 6; i++) {
        final y = s.height * 0.6 - ((u * 90 + i * 40) % (s.height * 0.6));
        tp.text = TextSpan(text: i.isEven ? '😂' : 'HA', style: TextStyle(fontSize: 22, color: cols[i % 5]));
        tp.layout();
        tp.paint(c, Offset(40 + i * 100.0, y));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter o) => true;
}

class _AudienceBgPainter extends CustomPainter {
  final double t;
  final Color color;
  final bool sport, island;
  _AudienceBgPainter(this.t, this.color, {required this.sport, required this.island});
  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    if (island) {
      c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4FC3F7), Color(0xFFFFE0A3)]).createShader(r));
      return;
    }
    c.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: sport ? [const Color(0xFF0B1B3A), const Color(0xFF173B2A)] : [const Color(0xFF24123F), const Color(0xFF090412)],
          ).createShader(r));
    _beams(c, s, t, [color, const Color(0xFF4DABF7), const Color(0xFFFFD43B), const Color(0xFFB197FC)]);
    if (sport) {
      for (int i = 0; i < 4; i++) {
        c.drawCircle(Offset(s.width * (0.15 + i * 0.23), 18), 10,
            Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AudienceBgPainter o) => o.t != t;
}

void _beams(Canvas c, Size s, double t, List<Color> cols) {
  for (int i = 0; i < cols.length; i++) {
    final x = s.width * (0.15 + i * 0.22);
    c.save();
    c.translate(x, -20);
    c.rotate(sin(t * 1.4 + i) * 0.28);
    final rect = Rect.fromLTWH(-40, 0, 80, s.height * 1.3);
    c.drawPath(
        Path()
          ..moveTo(-8, 0)
          ..lineTo(8, 0)
          ..lineTo(50, s.height * 1.3)
          ..lineTo(-50, s.height * 1.3)
          ..close(),
        Paint()
          ..blendMode = BlendMode.screen
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cols[i].withValues(alpha: 0.55), cols[i].withValues(alpha: 0)],
          ).createShader(rect)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    c.restore();
  }
}

void _text(Canvas c, String t, Offset center, double size, Color color,
    {FontWeight w = FontWeight.w900, double spacing = 0, List<Shadow>? shadows}) {
  final tp = TextPainter(
    text: TextSpan(
        text: t,
        style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: size,
            color: color,
            fontWeight: w,
            letterSpacing: spacing,
            shadows: shadows)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
}

void _grad(Canvas c, Rect r, List<Color> cols, {bool vertical = true, double radius = 0}) {
  final p = Paint()
    ..shader = LinearGradient(
      begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
      end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
      colors: cols,
    ).createShader(r);
  if (radius > 0) {
    c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(radius)), p);
  } else {
    c.drawRect(r, p);
  }
}

/// Dekor: her format (prop) için ayrı sahne
class SetPainter extends CustomPainter {
  final Prop prop;
  final Genre genre;
  final double t;
  final Color color;
  final String title;
  final double pan;
  final int seed;
  SetPainter(this.prop, this.genre, this.t, this.color, this.title, this.pan, this.seed);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.save();
    c.translate(-pan * 0.3, 0);
    final W = w + 80;
    switch (prop) {
      // ---------------- TALK SHOW ----------------
      case Prop.nightShow:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF0B1030), const Color(0xFF1B0F3A)]);
        _skyline(c, w, h, t, night: true);
        _ledWall(c, Rect.fromLTWH(w * 0.55, h * 0.08, w * 0.38, h * 0.3), title, t);
        _floor(c, w, h, const Color(0xFF2A1846), color);
      case Prop.morning:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFFFFE8C2), const Color(0xFFFFC48A)]);
        _window(c, Rect.fromLTWH(w * 0.08, h * 0.1, w * 0.34, h * 0.42), day: true, t: t);
        _ledWall(c, Rect.fromLTWH(w * 0.52, h * 0.1, w * 0.4, h * 0.3), title, t, warm: true);
        _plant(c, Offset(w * 0.47, h * 0.62));
        _floor(c, w, h, const Color(0xFFC98D5A), const Color(0xFFFFB347));
      case Prop.standup:
        _brick(c, w, h);
        c.drawCircle(Offset(w * 0.5, h * 0.42), h * 0.36,
            Paint()..color = const Color(0x55FFE8A3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40));
        _text(c, trUpper(title), Offset(w * 0.5, h * 0.12), 28, const Color(0xFFFF4F8B),
            spacing: 4, shadows: const [Shadow(color: Color(0xFFFF4F8B), blurRadius: 18)]);
        _floor(c, w, h, const Color(0xFF2B1A12), const Color(0xFFFFB347));
      case Prop.sketch:
      case Prop.studio:
        _curtains(c, w, h, const Color(0xFFB0203A));
        _ledWall(c, Rect.fromLTWH(w * 0.3, h * 0.1, w * 0.4, h * 0.28), title, t);
        _floor(c, w, h, const Color(0xFF3A1E14), color);
      case Prop.newYear:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF0A0F2E), const Color(0xFF2A0E3A)]);
        _fireworks(c, w, h, t);
        _ledWall(c, Rect.fromLTWH(w * 0.28, h * 0.1, w * 0.44, h * 0.26), 'MUTLU YILLAR', t);
        _floor(c, w, h, const Color(0xFF2A1846), const Color(0xFFFFD43B));

      // ---------------- YARIŞMA ----------------
      case Prop.quiz:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF0A1B4D), const Color(0xFF050A1F)]);
        _beams(c, s, t, [const Color(0xFF4DABF7), const Color(0xFF7A3CFF), const Color(0xFF4DABF7), const Color(0xFF7A3CFF)]);
        final q = Rect.fromLTWH(w * 0.25, h * 0.07, w * 0.5, h * 0.27);
        _grad(c, q, [const Color(0xFF1C3FAA), const Color(0xFF0B1E5B)], radius: 14);
        c.drawRRect(RRect.fromRectAndRadius(q, const Radius.circular(14)),
            Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = const Color(0xFFFFD43B));
        _text(c, 'SORU ${1 + (t / 12).floor() % 12}', q.center - const Offset(0, 22), 18, const Color(0xFFFFD43B));
        _text(c, '?', q.center + const Offset(0, 14), 44 + sin(t * 4) * 4, Colors.white);
        _floor(c, w, h, const Color(0xFF0E1A3A), const Color(0xFF4DABF7));
      case Prop.wheel:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF3B0A4F), const Color(0xFF12041C)]);
        _wheel(c, Offset(w * 0.5, h * 0.34), h * 0.3, t);
        _floor(c, w, h, const Color(0xFF2A0A3A), const Color(0xFFFFD43B));
      case Prop.couples:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFFFF8FB8), const Color(0xFF7A1E4A)]);
        _hearts(c, w, h, t);
        _ledWall(c, Rect.fromLTWH(w * 0.3, h * 0.08, w * 0.4, h * 0.26), title, t);
        _floor(c, w, h, const Color(0xFF5A1236), const Color(0xFFFF4F8B));
      case Prop.voice:
      case Prop.talent:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF1A0505), const Color(0xFF050101)]);
        _beams(c, s, t, [const Color(0xFFFF3B3B), const Color(0xFFFFD43B), const Color(0xFFFF3B3B)]);
        _text(c, trUpper(title), Offset(w * 0.5, h * 0.14), 30, const Color(0xFFFF3B3B),
            spacing: 6, shadows: const [Shadow(color: Color(0xFFFF3B3B), blurRadius: 20)]);
        _floor(c, w, h, const Color(0xFF200808), const Color(0xFFFF3B3B));
        for (int i = 0; i < 4; i++) {
          _chair(c, Offset(w * (0.14 + i * 0.24), h * 0.86), const Color(0xFFB0203A));
        }
      case Prop.island:
        _beach(c, w, h, t);

      // ---------------- DİZİ ----------------
      case Prop.livingRoom:
      case Prop.palace:
        _wallpaper(c, w, h, prop == Prop.palace ? const Color(0xFF5A1E2A) : const Color(0xFF6B4A3A),
            prop == Prop.palace ? const Color(0xFFE0B04A) : const Color(0xFFB08A60));
        _window(c, Rect.fromLTWH(w * 0.62, h * 0.1, w * 0.26, h * 0.46), day: (seed % 2) == 0, t: t, curtains: true);
        _frame(c, Rect.fromLTWH(w * 0.16, h * 0.14, w * 0.2, h * 0.24));
        _chandelier(c, Offset(w * 0.45, 0), t);
        _floor(c, w, h, const Color(0xFF4A2A18), const Color(0xFFE0B04A), wood: true);
      case Prop.sitcom:
        _wallpaper(c, w, h, const Color(0xFF4FA3A5), const Color(0xFFFFE08A));
        _window(c, Rect.fromLTWH(w * 0.1, h * 0.12, w * 0.26, h * 0.38), day: true, t: t, curtains: true);
        _frame(c, Rect.fromLTWH(w * 0.62, h * 0.16, w * 0.16, h * 0.2));
        _plant(c, Offset(w * 0.86, h * 0.64));
        _floor(c, w, h, const Color(0xFF8A5A34), const Color(0xFFFFB347), wood: true);
      case Prop.neighborhood:
        _street(c, w, h, t, night: false);
      case Prop.police:
        _street(c, w, h, t, night: true, siren: true);
      case Prop.epic:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF6E5A4A), const Color(0xFF2A1E18)]);
        _mountains(c, w, h, const Color(0xFF3E3028), const Color(0xFF241A14));
        _castle(c, Offset(w * 0.7, h * 0.55), h * 0.35);
        _fog(c, w, h, t);

      // ---------------- HABER ----------------
      case Prop.newsDesk:
      case Prop.globe:
      case Prop.debate:
      case Prop.election:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF071A3A), const Color(0xFF02081A)]);
        _grid(c, w, h, const Color(0x2229B6F6));
        if (prop == Prop.election) {
          _bars(c, Rect.fromLTWH(w * 0.25, h * 0.08, w * 0.5, h * 0.32), t);
        } else {
          _globe(c, Offset(w * 0.5, h * 0.27), h * 0.2, t);
        }
        _text(c, '${trUpper(title)} · HABER', Offset(w * 0.5, h * 0.53), 14, const Color(0xFF9FD8FF), spacing: 4);
        _floor(c, w, h, const Color(0xFF0A1A36), const Color(0xFF29B6F6));
      case Prop.field:
        _skyline(c, w, h, t, night: false);
        _grad(c, Rect.fromLTWH(-40, h * 0.72, W, h * 0.28), [const Color(0xFF6B6B6B), const Color(0xFF3E3E3E)]);

      // ---------------- MAGAZİN ----------------
      case Prop.gossip:
      case Prop.redCarpet:
      case Prop.paparazzi:
      case Prop.awards:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF3A0A2A), const Color(0xFF12040E)]);
        _stepRepeat(c, w, h, title);
        if (prop == Prop.awards) _trophy(c, Offset(w * 0.5, h * 0.3), h * 0.22, t);
        if (prop == Prop.redCarpet || prop == Prop.paparazzi) {
          c.drawPath(
              Path()
                ..moveTo(w * 0.38, h * 0.62)
                ..lineTo(w * 0.62, h * 0.62)
                ..lineTo(w * 0.85, h)
                ..lineTo(w * 0.15, h)
                ..close(),
              Paint()..color = const Color(0xFFC81E3A));
        } else {
          _floor(c, w, h, const Color(0xFF2A0A1E), const Color(0xFFFF4F8B));
        }
        _flashes(c, w, h, t);

      // ---------------- BELGESEL ----------------
      case Prop.nature:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF8FD3FF), const Color(0xFFFFE2B0)]);
        c.drawCircle(Offset(w * 0.78, h * 0.2), h * 0.08, Paint()..color = const Color(0xFFFFF3B0));
        _mountains(c, w, h, const Color(0xFF6A8CA8), const Color(0xFF3E6B4A));
        _trees(c, w, h);
        _birds(c, w, h, t);
      case Prop.ocean:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF0B6FA4), const Color(0xFF021B33)]);
        _rays(c, w, h, t);
        _fish(c, w, h, t);
        _bubbles(c, w, h, t);
      case Prop.history:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFFFFC98A), const Color(0xFFB0703A)]);
        _pyramids(c, w, h);
        for (int i = 0; i < 5; i++) {
          _column(c, Rect.fromLTWH(w * (0.04 + i * 0.2), h * 0.25, w * 0.06, h * 0.55));
        }
      case Prop.space:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF02010A), const Color(0xFF12082A)]);
        _stars(c, w, h, t);
        _planet(c, Offset(w * 0.72, h * 0.35), h * 0.18);

      // ---------------- SPOR ----------------
      case Prop.football:
      case Prop.derby:
      case Prop.tournament:
      case Prop.sportsDesk:
        _stadium(c, w, h, t, derby: prop == Prop.derby);
        _players(c, w, h, t);
        if (prop == Prop.tournament) _trophy(c, Offset(w * 0.5, h * 0.22), h * 0.14, t);
      case Prop.basketball:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF1A1030), const Color(0xFF0A0614)]);
        _crowdDots(c, w, h * 0.5, t);
        _grad(c, Rect.fromLTWH(-40, h * 0.55, W, h * 0.45), [const Color(0xFFD9A066), const Color(0xFFB07A44)]);
        _hoop(c, Offset(w * 0.8, h * 0.3));

      // ---------------- ÇOCUK ----------------
      case Prop.cartoon:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFFFFE3A3), const Color(0xFFFFB86B)]);
        _cartoonScreen(c, Rect.fromLTWH(w * 0.22, h * 0.06, w * 0.56, h * 0.5), t);
        _floor(c, w, h, const Color(0xFFB0703A), const Color(0xFF7A3CFF));
      case Prop.puppet:
        _curtains(c, w, h, const Color(0xFF7A3CFF));
        _puppets(c, w, h, t);
        _floor(c, w, h, const Color(0xFF3A1E14), const Color(0xFFFFD43B));
      case Prop.lab:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFFD6F5FF), const Color(0xFF9BD7F0)]);
        _labShelf(c, w, h, t);
        _floor(c, w, h, const Color(0xFF6A8CA8), const Color(0xFF38D9A9));
      case Prop.kidsStage:
        _grad(c, Rect.fromLTWH(-40, 0, W, h), [const Color(0xFF7AD3FF), const Color(0xFFFFB3D9)]);
        _balloons(c, w, h, t);
        _ledWall(c, Rect.fromLTWH(w * 0.3, h * 0.1, w * 0.4, h * 0.26), title, t);
        _floor(c, w, h, const Color(0xFF7A3CFF), const Color(0xFFFFD43B));
      case Prop.film:
      case Prop.filmSet:
        _wallpaper(c, w, h, const Color(0xFF2A2A3A), const Color(0xFF6A6A8A));
        _floor(c, w, h, const Color(0xFF1A1A24), color);
    }
    c.restore();
  }

  // ---- yardımcı çizimler ----
  void _floor(Canvas c, double w, double h, Color base, Color edge, {bool wood = false}) {
    final r = Rect.fromLTWH(-60, h * 0.64, w + 120, h * 0.36);
    _grad(c, r, [base, Color.lerp(base, Colors.black, 0.6)!]);
    c.drawLine(Offset(-60, h * 0.64), Offset(w + 60, h * 0.64), Paint()..color = edge..strokeWidth = 3);
    if (wood) {
      final p = Paint()..color = Colors.black.withValues(alpha: 0.15)..strokeWidth = 1.5;
      for (int i = 0; i < 6; i++) {
        final y = h * 0.64 + i * h * 0.06;
        c.drawLine(Offset(-60, y), Offset(w + 60, y), p);
      }
    }
  }

  void _ledWall(Canvas c, Rect r, String title, double t, {bool warm = false}) {
    c.drawRRect(
        RRect.fromRectAndRadius(r.inflate(6), const Radius.circular(14)),
        Paint()
          ..color = (warm ? const Color(0xFFFFB347) : const Color(0xFFB05CFF)).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    final a = t * 0.6;
    c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(12)),
        Paint()
          ..shader = SweepGradient(
            center: Alignment.center,
            transform: GradientRotation(a),
            colors: warm
                ? const [Color(0xFFFFB347), Color(0xFFFF6B6B), Color(0xFFFFD43B), Color(0xFFFFB347)]
                : [color, const Color(0xFF7A3CFF), const Color(0xFF2EC5FF), color],
          ).createShader(r));
    _text(c, trUpper(title), r.center, min(34, r.width / max(4, title.length) * 1.5), Colors.white,
        spacing: 3, shadows: const [Shadow(color: Colors.white, blurRadius: 14), Shadow(color: Colors.black45, offset: Offset(0, 3))]);
  }

  void _skyline(Canvas c, double w, double h, double t, {required bool night}) {
    if (!night) {
      _grad(c, Rect.fromLTWH(-40, 0, w + 80, h), [const Color(0xFF9AD0FF), const Color(0xFFE8F4FF)]);
    }
    final p = Paint()..color = night ? const Color(0xFF1A1A3A) : const Color(0xFF8A9AB0);
    for (int i = 0; i < 16; i++) {
      final bw = 30 + _rn(i) * 40, bh = h * (0.2 + _rn(i + 5) * 0.35);
      final x = -40 + i * 46.0;
      c.drawRect(Rect.fromLTWH(x, h * 0.66 - bh, bw, bh), p);
      if (night) {
        final wp = Paint()..color = const Color(0xFFFFE08A).withValues(alpha: 0.8);
        for (int k = 0; k < 6; k++) {
          if (_rn(i * 9 + k + (t ~/ 3)) > 0.5) {
            c.drawRect(Rect.fromLTWH(x + 6 + (k % 2) * 14, h * 0.66 - bh + 8 + (k ~/ 2) * 18, 6, 8), wp);
          }
        }
      }
    }
    if (night) c.drawCircle(Offset(w * 0.15, h * 0.14), 16, Paint()..color = const Color(0xFFFFF6D8));
  }

  void _window(Canvas c, Rect r, {required bool day, required double t, bool curtains = false}) {
    _grad(c, r, day ? [const Color(0xFF9AD0FF), const Color(0xFFDFF1FF)] : [const Color(0xFF0B1030), const Color(0xFF2A1E5A)]);
    if (!day) {
      for (int i = 0; i < 12; i++) {
        c.drawCircle(Offset(r.left + _rn(i) * r.width, r.top + _rn(i + 3) * r.height * 0.6), 1.2,
            Paint()..color = Colors.white.withValues(alpha: 0.5 + 0.5 * sin(t * 2 + i)));
      }
    } else {
      c.drawCircle(Offset(r.left + r.width * 0.75, r.top + r.height * 0.25), r.height * 0.1, Paint()..color = const Color(0xFFFFF3B0));
    }
    final fp = Paint()..color = const Color(0xFFF5F0E6)..style = PaintingStyle.stroke..strokeWidth = 6;
    c.drawRect(r, fp);
    c.drawLine(r.topCenter, r.bottomCenter, fp..strokeWidth = 4);
    c.drawLine(r.centerLeft, r.centerRight, fp);
    if (curtains) {
      final cp = Paint()..color = const Color(0xFF8A1E2A);
      c.drawPath(
          Path()
            ..moveTo(r.left - 14, r.top - 10)
            ..lineTo(r.left + r.width * 0.25, r.top - 10)
            ..quadraticBezierTo(r.left + r.width * 0.05, r.center.dy, r.left + r.width * 0.15, r.bottom + 10)
            ..lineTo(r.left - 14, r.bottom + 10)
            ..close(),
          cp);
      c.drawPath(
          Path()
            ..moveTo(r.right + 14, r.top - 10)
            ..lineTo(r.right - r.width * 0.25, r.top - 10)
            ..quadraticBezierTo(r.right - r.width * 0.05, r.center.dy, r.right - r.width * 0.15, r.bottom + 10)
            ..lineTo(r.right + 14, r.bottom + 10)
            ..close(),
          cp);
    }
  }

  void _plant(Canvas c, Offset o) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + const Offset(0, 18), width: 30, height: 30), const Radius.circular(6)),
        Paint()..color = const Color(0xFFB0703A));
    final lp = Paint()..color = const Color(0xFF2F9E44);
    for (int i = 0; i < 7; i++) {
      final a = -pi / 2 + (i - 3) * 0.35;
      c.drawOval(Rect.fromCenter(center: o + Offset(cos(a) * 22, sin(a) * 26), width: 14, height: 30), lp);
    }
  }

  void _brick(Canvas c, double w, double h) {
    _grad(c, Rect.fromLTWH(-40, 0, w + 80, h), [const Color(0xFF7A3A2A), const Color(0xFF3A1A12)]);
    final p = Paint()..color = Colors.black.withValues(alpha: 0.25)..strokeWidth = 1.5;
    for (int y = 0; y < 14; y++) {
      final yy = y * 22.0;
      c.drawLine(Offset(-40, yy), Offset(w + 40, yy), p);
      for (int x = 0; x < 20; x++) {
        final xx = x * 46.0 + (y.isEven ? 0 : 23) - 40;
        c.drawLine(Offset(xx, yy), Offset(xx, yy + 22), p);
      }
    }
  }

  void _curtains(Canvas c, double w, double h, Color col) {
    _grad(c, Rect.fromLTWH(-40, 0, w + 80, h), [Color.lerp(col, Colors.black, 0.3)!, Color.lerp(col, Colors.black, 0.75)!]);
    final p = Paint()..color = Colors.black.withValues(alpha: 0.22);
    for (int i = 0; i < 22; i++) {
      c.drawRect(Rect.fromLTWH(-40 + i * 34.0, 0, 12, h), p);
    }
    c.drawRect(Rect.fromLTWH(-40, 0, w + 80, h * 0.07), Paint()..color = const Color(0xFFE0B04A));
  }

  void _fireworks(Canvas c, double w, double h, double t) {
    const cols = [Color(0xFFFF4F8B), Color(0xFFFFD43B), Color(0xFF4DABF7), Color(0xFF69DB7C)];
    for (int k = 0; k < 4; k++) {
      final ph = (t * 0.6 + k * 0.27) % 1;
      final o = Offset(w * (0.15 + k * 0.23), h * (0.15 + _rn(k) * 0.2));
      for (int i = 0; i < 14; i++) {
        final a = i / 14 * pi * 2;
        c.drawCircle(o + Offset(cos(a), sin(a)) * (ph * 50), 2.5,
            Paint()..color = cols[k].withValues(alpha: 1 - ph));
      }
    }
  }

  void _wheel(Canvas c, Offset o, double rad, double t) {
    const cols = [Color(0xFFFF4F8B), Color(0xFFFFD43B), Color(0xFF4DABF7), Color(0xFF69DB7C), Color(0xFFB197FC), Color(0xFFFFA94D)];
    final rot = t * 1.2;
    for (int i = 0; i < 12; i++) {
      final a0 = rot + i * pi / 6;
      c.drawArc(Rect.fromCircle(center: o, radius: rad), a0, pi / 6, true, Paint()..color = cols[i % 6]);
    }
    c.drawCircle(o, rad, Paint()..style = PaintingStyle.stroke..strokeWidth = 8..color = const Color(0xFFFFD43B));
    for (int i = 0; i < 24; i++) {
      final a = i / 24 * pi * 2;
      c.drawCircle(o + Offset(cos(a), sin(a)) * (rad + 8), 3,
          Paint()..color = ((t * 6).floor() + i).isEven ? Colors.white : const Color(0xFFFFD43B));
    }
    c.drawCircle(o, rad * 0.15, Paint()..color = Colors.white);
    c.drawPath(
        Path()
          ..moveTo(o.dx - 10, o.dy - rad - 16)
          ..lineTo(o.dx + 10, o.dy - rad - 16)
          ..lineTo(o.dx, o.dy - rad + 6)
          ..close(),
        Paint()..color = Colors.white);
  }

  void _hearts(Canvas c, double w, double h, double t) {
    for (int i = 0; i < 12; i++) {
      final x = _rn(i) * w, y = h - ((t * 20 + _rn(i + 4) * h) % h);
      final s = 8 + _rn(i + 8) * 10;
      final p = Paint()..color = Colors.white.withValues(alpha: 0.35);
      c.drawCircle(Offset(x - s / 2, y), s / 2, p);
      c.drawCircle(Offset(x + s / 2, y), s / 2, p);
      c.drawPath(
          Path()
            ..moveTo(x - s, y + 2)
            ..lineTo(x + s, y + 2)
            ..lineTo(x, y + s * 1.3)
            ..close(),
          p);
    }
  }

  void _chair(Canvas c, Offset o, Color col) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o - const Offset(0, 20), width: 60, height: 60), const Radius.circular(18)),
        Paint()..color = col);
    c.drawRect(Rect.fromCenter(center: o + const Offset(0, 14), width: 8, height: 26), Paint()..color = const Color(0xFF333333));
  }

  void _beach(Canvas c, double w, double h, double t) {
    _grad(c, Rect.fromLTWH(-40, 0, w + 80, h * 0.5), [const Color(0xFF4FC3F7), const Color(0xFFB3E5FC)]);
    c.drawCircle(Offset(w * 0.8, h * 0.16), h * 0.08, Paint()..color = const Color(0xFFFFF3B0));
    _grad(c, Rect.fromLTWH(-40, h * 0.42, w + 80, h * 0.2), [const Color(0xFF0288D1), const Color(0xFF4FC3F7)]);
    final wp = Paint()..color = Colors.white.withValues(alpha: 0.6)..strokeWidth = 2..style = PaintingStyle.stroke;
    for (int k = 0; k < 3; k++) {
      final path = Path();
      for (double x = -40; x < w + 40; x += 8) {
        final y = h * (0.47 + k * 0.05) + sin(x / 30 + t * 2 + k) * 3;
        x == -40 ? path.moveTo(x, y) : path.lineTo(x, y);
      }
      c.drawPath(path, wp);
    }
    _grad(c, Rect.fromLTWH(-40, h * 0.6, w + 80, h * 0.4), [const Color(0xFFFFE0A3), const Color(0xFFE0B070)]);
    _palm(c, Offset(w * 0.08, h * 0.66), t);
    _palm(c, Offset(w * 0.9, h * 0.68), t + 1);
    // takım bayrakları
    for (final (i, col) in [(0, const Color(0xFF1C7ED6)), (1, const Color(0xFFE03131))]) {
      final x = w * (0.3 + i * 0.4);
      c.drawLine(Offset(x, h * 0.7), Offset(x, h * 0.42), Paint()..color = const Color(0xFF6B4A2A)..strokeWidth = 3);
      c.drawPath(
          Path()
            ..moveTo(x, h * 0.42)
            ..lineTo(x + 30, h * 0.45 + sin(t * 5 + i) * 3)
            ..lineTo(x, h * 0.48)
            ..close(),
          Paint()..color = col);
    }
  }

  void _palm(Canvas c, Offset o, double t) {
    c.drawPath(
        Path()
          ..moveTo(o.dx - 5, o.dy)
          ..quadraticBezierTo(o.dx + 10, o.dy - 80, o.dx + 18, o.dy - 150)
          ..lineTo(o.dx + 26, o.dy - 150)
          ..quadraticBezierTo(o.dx + 18, o.dy - 80, o.dx + 5, o.dy)
          ..close(),
        Paint()..color = const Color(0xFF8A5A34));
    final top = o + const Offset(22, -150);
    for (int i = 0; i < 6; i++) {
      final a = -pi + i * pi / 5 + sin(t * 1.5) * 0.05;
      c.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo(top.dx + cos(a) * 40, top.dy + sin(a) * 30 - 20, top.dx + cos(a) * 70, top.dy + sin(a) * 20 + 20)
            ..quadraticBezierTo(top.dx + cos(a) * 40, top.dy + sin(a) * 30, top.dx, top.dy + 4),
          Paint()..color = const Color(0xFF2F9E44));
    }
  }

  void _wallpaper(Canvas c, double w, double h, Color base, Color pattern) {
    _grad(c, Rect.fromLTWH(-40, 0, w + 80, h), [base, Color.lerp(base, Colors.black, 0.45)!]);
    final p = Paint()..color = pattern.withValues(alpha: 0.18);
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 16; x++) {
        final o = Offset(-40 + x * 46.0 + (y.isEven ? 0 : 23), y * 40.0 + 20);
        c.drawPath(
            Path()
              ..moveTo(o.dx, o.dy - 8)
              ..lineTo(o.dx + 6, o.dy)
              ..lineTo(o.dx, o.dy + 8)
              ..lineTo(o.dx - 6, o.dy)
              ..close(),
            p);
      }
    }
  }

  void _frame(Canvas c, Rect r) {
    c.drawRect(r.inflate(6), Paint()..color = const Color(0xFFC9A24A));
    _grad(c, r, [const Color(0xFF3E6B4A), const Color(0xFFE0B070)]);
    c.drawCircle(r.center - Offset(0, r.height * 0.1), r.height * 0.18, Paint()..color = const Color(0xFFF2C29B));
  }

  void _chandelier(Canvas c, Offset top, double t) {
    c.drawLine(top, top + const Offset(0, 40), Paint()..color = const Color(0xFFC9A24A)..strokeWidth = 2);
    final o = top + const Offset(0, 50);
    c.drawCircle(o, 46,
        Paint()..color = const Color(0x55FFE8A3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    for (int i = 0; i < 5; i++) {
      final x = o.dx + (i - 2) * 16;
      c.drawCircle(Offset(x, o.dy + (i % 2) * 6), 5, Paint()..color = Color.lerp(const Color(0xFFFFF3B0), Colors.white, 0.5 + 0.5 * sin(t * 6 + i))!);
    }
    c.drawArc(Rect.fromCenter(center: o, width: 80, height: 24), 0, pi, false,
        Paint()..color = const Color(0xFFC9A24A)..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  void _street(Canvas c, double w, double h, double t, {required bool night, bool siren = false}) {
    _skyline(c, w, h, t, night: night);
    _grad(c, Rect.fromLTWH(-40, h * 0.66, w + 80, h * 0.34), night ? [const Color(0xFF2A2A3A), const Color(0xFF101018)] : [const Color(0xFF8A8A8A), const Color(0xFF5A5A5A)]);
    // sokak lambası
    for (final x in [w * 0.2, w * 0.75]) {
      c.drawLine(Offset(x, h * 0.66), Offset(x, h * 0.25), Paint()..color = const Color(0xFF333333)..strokeWidth = 4);
      c.drawCircle(Offset(x, h * 0.25), night ? 26 : 6,
          Paint()..color = const Color(0xAAFFE08A)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }
    if (night) {
      // yağmur
      final rp = Paint()..color = Colors.white.withValues(alpha: 0.25)..strokeWidth = 1;
      for (int i = 0; i < 60; i++) {
        final x = _rn(i) * (w + 40), y = (t * 300 + _rn(i + 7) * h) % h;
        c.drawLine(Offset(x, y), Offset(x - 3, y + 10), rp);
      }
    }
    if (siren) {
      final on = (t * 3).floor().isEven;
      c.drawRect(Rect.fromLTWH(-40, 0, w + 80, h),
          Paint()..color = (on ? const Color(0xFFE03131) : const Color(0xFF1C7ED6)).withValues(alpha: 0.14));
    }
  }

  void _mountains(Canvas c, double w, double h, Color far, Color near) {
    c.drawPath(
        Path()
          ..moveTo(-40, h * 0.62)
          ..lineTo(w * 0.15, h * 0.3)
          ..lineTo(w * 0.32, h * 0.52)
          ..lineTo(w * 0.5, h * 0.24)
          ..lineTo(w * 0.72, h * 0.5)
          ..lineTo(w * 0.88, h * 0.32)
          ..lineTo(w + 40, h * 0.6)
          ..lineTo(w + 40, h)
          ..lineTo(-40, h)
          ..close(),
        Paint()..color = far);
    c.drawPath(
        Path()
          ..moveTo(-40, h * 0.75)
          ..quadraticBezierTo(w * 0.3, h * 0.55, w * 0.6, h * 0.7)
          ..quadraticBezierTo(w * 0.85, h * 0.8, w + 40, h * 0.66)
          ..lineTo(w + 40, h)
          ..lineTo(-40, h)
          ..close(),
        Paint()..color = near);
  }

  void _castle(Canvas c, Offset o, double s) {
    final p = Paint()..color = const Color(0xFF1A140F);
    c.drawRect(Rect.fromLTWH(o.dx - s * 0.5, o.dy - s * 0.6, s, s * 0.6), p);
    for (int i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(o.dx - s * 0.55 + i * s * 0.45, o.dy - s, s * 0.2, s * 0.45), p);
    }
  }

  void _fog(Canvas c, double w, double h, double t) {
    for (int i = 0; i < 6; i++) {
      final x = ((t * 10 + i * 140) % (w + 200)) - 100;
      c.drawOval(Rect.fromCenter(center: Offset(x, h * (0.6 + (i % 3) * 0.08)), width: 220, height: 50),
          Paint()..color = Colors.white.withValues(alpha: 0.12)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    }
  }

  void _grid(Canvas c, double w, double h, Color col) {
    final p = Paint()..color = col..strokeWidth = 1;
    for (double x = -40; x < w + 40; x += 32) {
      c.drawLine(Offset(x, 0), Offset(x, h), p);
    }
    for (double y = 0; y < h; y += 32) {
      c.drawLine(Offset(-40, y), Offset(w + 40, y), p);
    }
  }

  void _globe(Canvas c, Offset o, double r, double t) {
    c.drawCircle(o, r * 1.3, Paint()..color = const Color(0x3329B6F6)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));
    c.drawCircle(o, r, Paint()..color = const Color(0xFF0B3A6E));
    final lp = Paint()..color = const Color(0xFF6CCBFF)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    c.drawCircle(o, r, lp);
    for (int i = 0; i < 6; i++) {
      final ph = (t * 0.4 + i / 6) % 1;
      final rx = (r * cos(ph * pi)).abs();
      c.drawOval(Rect.fromCenter(center: o, width: rx * 2, height: r * 2), lp);
    }
    for (int i = 1; i < 4; i++) {
      final y = o.dy - r + i * r / 2;
      final hw = sqrt(max(0, r * r - pow(y - o.dy, 2)));
      c.drawLine(Offset(o.dx - hw, y), Offset(o.dx + hw, y), lp);
    }
  }

  void _bars(Canvas c, Rect r, double t) {
    const cols = [Color(0xFFE03131), Color(0xFF1C7ED6), Color(0xFFFFD43B), Color(0xFF2F9E44)];
    for (int i = 0; i < 4; i++) {
      final v = 0.3 + 0.6 * ((sin(t * 0.5 + i * 1.7) + 1) / 2);
      final bw = r.width / 6;
      final x = r.left + bw * 0.5 + i * bw * 1.4;
      c.drawRect(Rect.fromLTWH(x, r.bottom - r.height * v, bw, r.height * v), Paint()..color = cols[i]);
      _text(c, '%${(v * 50).round()}', Offset(x + bw / 2, r.bottom - r.height * v - 10), 12, Colors.white);
    }
  }

  void _stepRepeat(Canvas c, double w, double h, String title) {
    for (int y = 0; y < 5; y++) {
      for (int x = 0; x < 7; x++) {
        _text(c, trUpper(title), Offset(x * 110.0 + (y.isEven ? 0 : 55), 30 + y * 42.0), 12,
            Colors.white.withValues(alpha: 0.18));
      }
    }
  }

  void _trophy(Canvas c, Offset o, double s, double t) {
    c.drawCircle(o, s * 1.1, Paint()..color = const Color(0x55FFD43B)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24));
    final g = Paint()..color = const Color(0xFFFFC83B);
    c.drawPath(
        Path()
          ..moveTo(o.dx - s * 0.5, o.dy - s * 0.6)
          ..lineTo(o.dx + s * 0.5, o.dy - s * 0.6)
          ..quadraticBezierTo(o.dx + s * 0.45, o.dy + s * 0.1, o.dx, o.dy + s * 0.2)
          ..quadraticBezierTo(o.dx - s * 0.45, o.dy + s * 0.1, o.dx - s * 0.5, o.dy - s * 0.6)
          ..close(),
        g);
    c.drawRect(Rect.fromCenter(center: o + Offset(0, s * 0.4), width: s * 0.12, height: s * 0.4), g);
    c.drawRect(Rect.fromCenter(center: o + Offset(0, s * 0.65), width: s * 0.5, height: s * 0.12), g);
    c.drawCircle(o + Offset(-s * 0.2, -s * 0.4), s * 0.06 * (1 + sin(t * 5)), Paint()..color = Colors.white);
  }

  void _flashes(Canvas c, double w, double h, double t) {
    final k = (t * 5).floor();
    for (int i = 0; i < 5; i++) {
      if (_rn(i * 11 + k) > 0.6) {
        c.drawCircle(Offset(_rn(i * 5 + k) * w, h * (0.55 + _rn(i + k) * 0.3)), 16,
            Paint()..color = Colors.white.withValues(alpha: 0.9)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
    }
  }

  void _trees(Canvas c, double w, double h) {
    for (int i = 0; i < 9; i++) {
      final x = -20 + i * 80.0 + _rn(i) * 30, y = h * (0.72 + _rn(i + 3) * 0.1);
      c.drawRect(Rect.fromLTWH(x - 3, y - 10, 6, 20), Paint()..color = const Color(0xFF5A3A22));
      c.drawPath(
          Path()
            ..moveTo(x, y - 70)
            ..lineTo(x + 24, y - 6)
            ..lineTo(x - 24, y - 6)
            ..close(),
          Paint()..color = const Color(0xFF1F6B3A));
    }
  }

  void _birds(Canvas c, double w, double h, double t) {
    final p = Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = 2;
    for (int i = 0; i < 5; i++) {
      final x = ((t * 30 + i * 60) % (w + 100)) - 50, y = h * 0.2 + i * 12 + sin(t * 2 + i) * 6;
      final f = sin(t * 10 + i) * 5;
      c.drawPath(
          Path()
            ..moveTo(x - 10, y - f)
            ..quadraticBezierTo(x - 5, y - 4, x, y)
            ..quadraticBezierTo(x + 5, y - 4, x + 10, y - f),
          p);
    }
  }

  void _rays(Canvas c, double w, double h, double t) {
    for (int i = 0; i < 5; i++) {
      final x = w * (0.1 + i * 0.2) + sin(t + i) * 10;
      c.drawPath(
          Path()
            ..moveTo(x - 10, 0)
            ..lineTo(x + 10, 0)
            ..lineTo(x + 60, h)
            ..lineTo(x - 30, h)
            ..close(),
          Paint()..color = Colors.white.withValues(alpha: 0.06));
    }
  }

  void _fish(Canvas c, double w, double h, double t) {
    const cols = [Color(0xFFFFA94D), Color(0xFFFFD43B), Color(0xFF69DB7C), Color(0xFFFF6B6B)];
    for (int i = 0; i < 9; i++) {
      final dir = i.isEven ? 1 : -1;
      final x = dir > 0 ? ((t * (20 + i * 4) + i * 90) % (w + 80)) - 40 : w + 40 - ((t * (18 + i * 3) + i * 70) % (w + 80));
      final y = h * (0.2 + _rn(i) * 0.6) + sin(t * 2 + i) * 6;
      final p = Paint()..color = cols[i % 4];
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 26, height: 14), p);
      c.drawPath(
          Path()
            ..moveTo(x - dir * 12, y)
            ..lineTo(x - dir * 22, y - 7)
            ..lineTo(x - dir * 22, y + 7)
            ..close(),
          p);
    }
  }

  void _bubbles(Canvas c, double w, double h, double t) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.35)..style = PaintingStyle.stroke;
    for (int i = 0; i < 20; i++) {
      final x = _rn(i) * w + sin(t + i) * 6, y = h - ((t * 40 + _rn(i + 3) * h) % h);
      c.drawCircle(Offset(x, y), 2 + _rn(i + 9) * 4, p);
    }
  }

  void _pyramids(Canvas c, double w, double h) {
    for (final (x, s) in [(w * 0.3, h * 0.35), (w * 0.62, h * 0.25)]) {
      c.drawPath(
          Path()
            ..moveTo(x - s, h * 0.7)
            ..lineTo(x, h * 0.7 - s)
            ..lineTo(x + s, h * 0.7)
            ..close(),
          Paint()..color = const Color(0xFFC98A4A));
    }
    _grad(c, Rect.fromLTWH(-40, h * 0.7, w + 80, h * 0.3), [const Color(0xFFE0B070), const Color(0xFFB0703A)]);
  }

  void _column(Canvas c, Rect r) {
    _grad(c, r, [const Color(0xFFF5E6C8), const Color(0xFFC9B48A)], vertical: false);
    c.drawRect(Rect.fromLTWH(r.left - 6, r.top - 10, r.width + 12, 10), Paint()..color = const Color(0xFFE8D8B0));
  }

  void _stars(Canvas c, double w, double h, double t) {
    for (int i = 0; i < 90; i++) {
      c.drawCircle(Offset(_rn(i) * (w + 40) - 20, _rn(i + 100) * h), 0.8 + _rn(i + 50) * 1.4,
          Paint()..color = Colors.white.withValues(alpha: 0.4 + 0.6 * ((sin(t * 2 + i) + 1) / 2)));
    }
  }

  void _planet(Canvas c, Offset o, double r) {
    c.drawCircle(o, r, Paint()..shader = const RadialGradient(colors: [Color(0xFFFFB86B), Color(0xFF8A3A1A)]).createShader(Rect.fromCircle(center: o, radius: r)));
    c.drawOval(Rect.fromCenter(center: o, width: r * 3, height: r * 0.6),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = const Color(0xAAFFE0A3));
  }

  void _stadium(Canvas c, double w, double h, double t, {bool derby = false}) {
    _grad(c, Rect.fromLTWH(-40, 0, w + 80, h * 0.5), [const Color(0xFF0B1B3A), const Color(0xFF1A2A5A)]);
    _crowdDots(c, w, h * 0.5, t, derby: derby);
    for (int i = 0; i < 4; i++) {
      c.drawCircle(Offset(w * (0.1 + i * 0.27), h * 0.06), 10,
          Paint()..color = Colors.white..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    }
    final pitch = Rect.fromLTWH(-40, h * 0.5, w + 80, h * 0.5);
    c.drawRect(pitch, Paint()..color = const Color(0xFF2F9E44));
    for (int i = 0; i < 10; i++) {
      if (i.isEven) c.drawRect(Rect.fromLTWH(-40 + i * 76.0, h * 0.5, 76, h * 0.5), Paint()..color = const Color(0xFF37B24D));
    }
    final lp = Paint()..color = Colors.white.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 2;
    c.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.5, h), lp);
    c.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.72), width: 160, height: 60), lp);
    if (derby) {
      for (int i = 0; i < 5; i++) {
        c.drawCircle(Offset(w * (0.1 + i * 0.2), h * 0.45), 14 + sin(t * 8 + i) * 3,
            Paint()..color = const Color(0xCCFF6B2B)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      }
    }
  }

  void _players(Canvas c, double w, double h, double t) {
    final ball = Offset(w * (0.5 + 0.35 * sin(t * 0.7)), h * (0.74 + 0.1 * sin(t * 1.3)));
    for (int i = 0; i < 12; i++) {
      final home = i < 6;
      final base = Offset(w * (0.08 + (i % 6) * 0.17), h * (0.6 + (i % 3) * 0.12));
      final o = Offset.lerp(base, ball, 0.25 + 0.1 * sin(t + i))!;
      final run = sin(t * 9 + i) * 2;
      c.drawOval(Rect.fromCenter(center: o + const Offset(0, 14), width: 16, height: 5), Paint()..color = Colors.black26);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, run * 0.3), width: 10, height: 16), const Radius.circular(4)),
          Paint()..color = home ? const Color(0xFFFFD43B) : const Color(0xFF1C7ED6));
      c.drawCircle(o + Offset(0, -12 + run * 0.3), 5, Paint()..color = const Color(0xFFE8B48F));
      c.drawLine(o + const Offset(-3, 8), o + Offset(-3 - run, 15), Paint()..color = Colors.white..strokeWidth = 3);
      c.drawLine(o + const Offset(3, 8), o + Offset(3 + run, 15), Paint()..color = Colors.white..strokeWidth = 3);
    }
    c.drawCircle(ball, 5, Paint()..color = Colors.white);
    c.drawCircle(ball, 5, Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _crowdDots(Canvas c, double w, double h, double t, {bool derby = false}) {
    const cols = [Color(0xFFFFD43B), Color(0xFFE03131), Color(0xFF1C7ED6), Color(0xFFFFFFFF), Color(0xFFFFA94D)];
    for (int i = 0; i < 260; i++) {
      final x = _rn(i) * (w + 80) - 40, y = h * 0.15 + _rn(i + 300) * h * 0.85;
      final b = sin(t * 8 + i) * 1.5;
      c.drawCircle(Offset(x, y + b), 2.6, Paint()..color = cols[(derby ? i % 2 + 1 : i) % 5].withValues(alpha: 0.85));
    }
  }

  void _hoop(Canvas c, Offset o) {
    c.drawRect(Rect.fromCenter(center: o, width: 90, height: 60), Paint()..color = Colors.white.withValues(alpha: 0.9));
    c.drawRect(Rect.fromCenter(center: o + const Offset(0, 6), width: 34, height: 24),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFFE03131));
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, 36), width: 44, height: 10),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = const Color(0xFFFF6B2B));
  }

  void _cartoonScreen(Canvas c, Rect r, double t) {
    c.drawRRect(RRect.fromRectAndRadius(r.inflate(10), const Radius.circular(18)), Paint()..color = const Color(0xFF2A2A3A));
    _grad(c, r, [const Color(0xFF8FE3FF), const Color(0xFFDFF8FF)]);
    c.drawRect(Rect.fromLTWH(r.left, r.bottom - r.height * 0.28, r.width, r.height * 0.28), Paint()..color = const Color(0xFF7ED957));
    c.drawCircle(Offset(r.right - 40, r.top + 30), 18, Paint()..color = const Color(0xFFFFD43B));
    // zıplayan çizgi film kahramanları
    const cols = [Color(0xFFFF6BB5), Color(0xFF6B8BFF), Color(0xFFFFA94D)];
    for (int i = 0; i < 3; i++) {
      final ph = t * 3 + i * 2;
      final x = r.left + r.width * (0.22 + i * 0.28) + sin(t + i) * 12;
      final y = r.bottom - r.height * 0.28 - 22 - (sin(ph).abs() * 40);
      final sq = 1 - 0.15 * (1 - sin(ph).abs());
      c.save();
      c.translate(x, y);
      c.scale(1 / sq, sq);
      c.drawCircle(Offset.zero, 22, Paint()..color = cols[i]);
      c.drawCircle(const Offset(-8, -5), 6, Paint()..color = Colors.white);
      c.drawCircle(const Offset(8, -5), 6, Paint()..color = Colors.white);
      c.drawCircle(Offset(-8 + sin(t * 2) * 2, -5), 2.5, Paint()..color = Colors.black);
      c.drawCircle(Offset(8 + sin(t * 2) * 2, -5), 2.5, Paint()..color = Colors.black);
      c.drawArc(Rect.fromCenter(center: const Offset(0, 6), width: 16, height: 10), 0, pi, false,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.black);
      c.restore();
    }
  }

  void _puppets(Canvas c, double w, double h, double t) {
    final box = Rect.fromLTWH(w * 0.25, h * 0.2, w * 0.5, h * 0.36);
    c.drawRect(box, Paint()..color = const Color(0xFF1A0A2A));
    for (int i = 0; i < 2; i++) {
      final x = box.left + box.width * (0.3 + i * 0.4);
      final y = box.bottom - 40 - sin(t * 4 + i * 2).abs() * 14;
      c.drawCircle(Offset(x, y), 24, Paint()..color = i == 0 ? const Color(0xFFFFA94D) : const Color(0xFF69DB7C));
      c.drawCircle(Offset(x - 8, y - 4), 5, Paint()..color = Colors.white);
      c.drawCircle(Offset(x + 8, y - 4), 5, Paint()..color = Colors.white);
      c.drawCircle(Offset(x - 8, y - 4), 2, Paint()..color = Colors.black);
      c.drawCircle(Offset(x + 8, y - 4), 2, Paint()..color = Colors.black);
      c.drawOval(Rect.fromCenter(center: Offset(x, y + 10), width: 14, height: 6 + sin(t * 10 + i) * 4),
          Paint()..color = const Color(0xFF7A1E2A));
    }
    c.drawRect(Rect.fromLTWH(box.left - 10, box.bottom - 4, box.width + 20, 20), Paint()..color = const Color(0xFFE0B04A));
  }

  void _labShelf(Canvas c, double w, double h, double t) {
    c.drawRect(Rect.fromLTWH(-40, h * 0.42, w + 80, 8), Paint()..color = const Color(0xFF6A4A2A));
    const cols = [Color(0xFF69DB7C), Color(0xFFFF6BB5), Color(0xFF4DABF7), Color(0xFFFFD43B)];
    for (int i = 0; i < 9; i++) {
      final x = 20 + i * 70.0;
      final col = cols[i % 4];
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, h * 0.24, 30, h * 0.18), const Radius.circular(8)),
          Paint()..color = col.withValues(alpha: 0.7));
      for (int b = 0; b < 3; b++) {
        final by = h * 0.24 - ((t * 30 + b * 20 + i * 7) % 40);
        c.drawCircle(Offset(x + 15 + sin(t * 3 + b) * 4, by), 3, Paint()..color = col.withValues(alpha: 0.6));
      }
    }
  }

  void _balloons(Canvas c, double w, double h, double t) {
    const cols = [Color(0xFFFF6B6B), Color(0xFFFFD43B), Color(0xFF4DABF7), Color(0xFF69DB7C), Color(0xFFB197FC)];
    for (int i = 0; i < 10; i++) {
      final x = _rn(i) * w, y = h * 0.45 - ((t * 12 + _rn(i + 3) * h * 0.45) % (h * 0.45));
      c.drawLine(Offset(x, y + 16), Offset(x + sin(t + i) * 4, y + 46), Paint()..color = Colors.white70);
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 24, height: 30), Paint()..color = cols[i % 5]);
    }
  }

  @override
  bool shouldRepaint(covariant SetPainter o) => o.t != t || o.pan != pan || o.prop != prop;
}

/// Önde: seyirci kafaları (geniş planda derinlik verir)
class FrontPainter extends CustomPainter {
  final Prop prop;
  final Genre genre;
  final double t;
  final double pan;
  final String title;

  /// Seyircinin keyfi 0..1 (0.5 normal): yüksekse ayakta alkış, düşükse boş koltuklar
  final double audience;
  FrontPainter(this.prop, this.genre, this.t, this.pan, this.title, {this.audience = 0.5});

  static const talkSets = {Prop.nightShow, Prop.morning, Prop.sketch, Prop.studio, Prop.newYear};
  static const podiumSets = {Prop.quiz, Prop.couples, Prop.talent, Prop.voice, Prop.wheel};
  static const newsSets = {Prop.newsDesk, Prop.globe, Prop.debate, Prop.election};

  /// Bu dekorda karakterlerin önünde mobilya var mı (yoksa karakterler aşağı oturur)
  static bool hasFurniture(Prop p) => talkSets.contains(p) || podiumSets.contains(p) || newsSets.contains(p);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    c.save();
    c.translate(-pan * 0.6, 0);
    if (talkSets.contains(prop)) {
      final d = Rect.fromLTWH(w * 0.04, h * 0.69, w * 0.36, h * 0.17);
      _grad(c, d, const [Color(0xFFFF6AA0), Color(0xFFA1255A)], radius: 14);
      c.drawRect(Rect.fromLTWH(d.left, d.top + 6, d.width, 4), Paint()..color = Colors.white54);
      _text(c, trUpper(title), d.center + const Offset(0, 6), min(16, d.width / max(4, title.length) * 1.6), Colors.white, spacing: 2);
      final so = Rect.fromLTWH(w * 0.56, h * 0.74, w * 0.4, h * 0.14);
      c.drawRRect(RRect.fromRectAndCorners(so, topLeft: const Radius.circular(30), topRight: const Radius.circular(30), bottomLeft: const Radius.circular(8), bottomRight: const Radius.circular(8)),
          Paint()..color = const Color(0xFF2FA99B));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(so.left - 8, so.top - 6, 22, so.height + 6), const Radius.circular(10)), Paint()..color = const Color(0xFF23877C));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(so.right - 14, so.top - 6, 22, so.height + 6), const Radius.circular(10)), Paint()..color = const Color(0xFF23877C));
    } else if (podiumSets.contains(prop)) {
      for (final (x, col) in [(0.06, const Color(0xFF4DABF7)), (0.6, const Color(0xFFFF4F8B))]) {
        final r = Rect.fromLTWH(w * x, h * 0.7, w * 0.34, h * 0.18);
        _grad(c, r, [Color.lerp(col, Colors.white, 0.25)!, Color.lerp(col, Colors.black, 0.5)!], radius: 10);
        c.drawRect(Rect.fromLTWH(r.left, r.top + 8, r.width, 5), Paint()..color = Colors.white.withValues(alpha: 0.75));
        final on = ((t * 4).floor() + (x * 10).round()).isEven;
        for (int i = 0; i < 6; i++) {
          c.drawCircle(Offset(r.left + 14 + i * r.width / 6, r.bottom - 10), 3,
              Paint()..color = (on == i.isEven) ? Colors.white : const Color(0xFFFFD43B));
        }
      }
    } else if (newsSets.contains(prop)) {
      final d = Rect.fromLTWH(w * 0.02, h * 0.7, w * 0.96, h * 0.17);
      _grad(c, d, const [Color(0xFF3B8EEA), Color(0xFF0B3A6E)], radius: 12);
      c.drawRect(Rect.fromLTWH(d.left, d.top + 6, d.width, 4), Paint()..color = Colors.white54);
      _text(c, 'HABER', d.center + const Offset(0, 6), 16, Colors.white, spacing: 8);
    }
    final stage = const {Genre.talkShow, Genre.yarisma, Genre.magazin, Genre.cocuk}.contains(genre) &&
        prop != Prop.island;
    if (stage) {
      final p = Paint()..color = const Color(0xFF04020A);
      final seat = Paint()..color = const Color(0xFF3A1B2A);
      final hype = audience > 0.68; // coşku: ayağa kalkıp alkışlarlar
      final bored = audience < 0.36; // sıkılmış: koltuklar boşalır
      final emptyShare = bored ? ((0.36 - audience) / 0.36 * 0.7 + 0.25).clamp(0.0, 0.8) : 0.0;
      for (int i = 0; i < 11; i++) {
        final x = i * 78.0 - 60 - pan * 0.6;
        // aynı koltuk hep aynı (titreşmesin): sıraya göre boş/dolu
        final empty = ((i * 37 + 11) % 100) / 100 < emptyShare;
        if (empty) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 6, h - 34, 60, 40), const Radius.circular(10)), seat);
          continue;
        }
        final bob = hype ? (sin(t * 9 + i * 1.7)).abs() * 10 + 6 : sin(t * 3 + i) * 2;
        final y = h - 46 - bob;
        c.drawRRect(
            RRect.fromRectAndCorners(Rect.fromLTWH(x, y, 72, 66 + bob),
                topLeft: const Radius.circular(36), topRight: const Radius.circular(36)),
            p);
        if (hype) {
          // alkışlayan eller
          final clap = sin(t * 14 + i) * 6;
          c.drawCircle(Offset(x + 22 - clap, y - 8), 7, p);
          c.drawCircle(Offset(x + 50 + clap, y - 8), 7, p);
        }
      }
      if (bored) {
        // esneyen seyirci: uçuşan "z"
        for (int k = 0; k < 3; k++) {
          final ph = (t * 0.6 + k / 3) % 1.0;
          _text(c, 'z', Offset(w * (0.25 + k * 0.25) - pan * 0.6, h - 60 - ph * 40), 14 + ph * 8,
              Colors.white.withValues(alpha: (1 - ph) * 0.6));
        }
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant FrontPainter o) => o.t != t || o.pan != pan || o.audience != audience;
}
