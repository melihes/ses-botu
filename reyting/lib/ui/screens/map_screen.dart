import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../data/content2.dart';
import '../../engine/game.dart';
import '../widgets/common.dart';
import 'city_map.dart';

/// Çekim lokasyonları: Türkiye haritası + dünya haritası
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen>
    with SingleTickerProviderStateMixin {
  int _tab = 0;
  String _sel = 'ist';
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final world = _tab == 1;
    final locs = locationDefs.where((l) => l.world == world).toList();
    if (!locs.any((l) => l.id == _sel)) _sel = locs.first.id;
    final sel = locationById(_sel)!;
    final owned = game.ownedLocations.length;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PillTabs(
                labels: const ['🇹🇷 Türkiye', '🌍 Dünya'],
                selected: _tab,
                onChanged: (i) => setState(() => _tab = i),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  world
                      ? 'Dünyada set kur: uyumlu türlerde kalite artar, etkinlik düzenle.'
                      : 'Şehir aç: izleyici erişimin büyür, bölgenin sevdiği türlerde reyting artar. '
                          'Şehirdeki sete dokunup kur.',
                  maxLines: 2,
                  style: const TextStyle(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ),
              Tag(
                '🏙️ ${game.openedCities.length}/81 şehir · 📍 $owned set',
                color: AppColors.cyan,
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (!world) const Expanded(child: CityMapView()),
          if (world) ...[
          const SizedBox(height: 6),
          // Haritada iğneler üst üste binebilir: her lokasyon buradan da seçilebilir
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final l in locs)
                  Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _sel = l.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: l.id == _sel
                              ? l.color.withValues(alpha: 0.25)
                              : AppColors.panel,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: l.id == _sel ? l.color : AppColors.border,
                          ),
                        ),
                        child: Text(
                          '${game.ownedLocations.contains(l.id) ? '✓ ' : ''}${l.city}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: game.ownedLocations.contains(l.id)
                                ? AppColors.green
                                : AppColors.text,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Panel(
                    padding: EdgeInsets.zero,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: LayoutBuilder(
                        builder: (ctx, c) {
                          final proj = _Proj(world, c.biggest);
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _MapPainter(world, proj),
                                ),
                              ),
                              for (final l in locs)
                                _pin(
                                  game,
                                  l,
                                  proj.of(l.lon, l.lat),
                                  l.id == _sel,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(width: 290, child: _detail(game, sel)),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _pin(Game game, LocationDef l, Offset p, bool selected) {
    final owned = game.ownedLocations.contains(l.id);
    final locked = game.locationLockReason(l) != null;
    final col = owned
        ? AppColors.green
        : (locked ? AppColors.textFaint : l.color);
    return Positioned(
      left: p.dx - 18,
      top: p.dy - 36,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _sel = l.id),
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (_, _) {
            final t = _pulse.value;
            return SizedBox(
              width: 36,
              height: 44,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  if (owned || selected)
                    Positioned(
                      top: 26 - 10 * t,
                      child: Container(
                        width: 10 + 26 * t,
                        height: (10 + 26 * t) * 0.45,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: col.withValues(alpha: 1 - t),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  AnimatedScale(
                    scale: selected ? 1.25 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: selected ? 2.5 : 1.5,
                        ),
                        boxShadow: const [
                          BoxShadow(color: Colors.black54, blurRadius: 6),
                        ],
                      ),
                      child: Icon(
                        owned
                            ? Icons.check_rounded
                            : (locked ? Icons.lock_rounded : l.icon),
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 28,
                    child: CustomPaint(
                      size: const Size(10, 8),
                      painter: _TipPainter(col),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _detail(Game game, LocationDef l) {
    final owned = game.ownedLocations.contains(l.id);
    final lock = game.locationLockReason(l);
    final ev = l.event;
    final fits = [
      ...l.genres.map((g) => genreDefs[g]!.label),
      ...l.films.map((g) => '${filmGenreDefs[g]!.label} filmi'),
    ];
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: owned ? AppColors.green.withValues(alpha: 0.6) : null,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: l.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(l.icon, color: l.color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.city.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        l.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              l.desc,
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'Uyumlu: ${fits.join(', ')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            Text(
              '• Uyumlu çekimlerde kalite +${fmtPct(l.bonus * 100, 0)}',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '• +${l.prestige} prestij',
              style: const TextStyle(
                color: AppColors.green,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '• Yol/konaklama: yapım maliyetinin %${l.world ? 30 : 12}\'si',
              style: const TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            Text(
              'Bakım: ${fmtShort(l.upkeep)}/gün',
              style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
            const SizedBox(height: 10),
            if (owned)
              const Tag('SET KURULDU ✓', color: AppColors.green)
            else if (lock != null)
              Tag(lock, color: AppColors.textDim, icon: Icons.lock_rounded)
            else
              AccentButton(
                'Set kur · ${fmtShort(l.price)}',
                expand: true,
                icon: Icons.add_location_alt_rounded,
                onTap: () => report(context, game.buyLocation(l)),
              ),
            if (ev != null) ...[
              const SizedBox(height: 12),
              const SectionLabel('Etkinlik', color: AppColors.yellow),
              Text(
                ev.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              Text(
                ev.desc,
                style: const TextStyle(color: AppColors.textDim, fontSize: 12),
              ),
              Text(
                'Maliyet ${fmtShort(game.eventCost(l))} · beklenen getiri ~${fmtShort(game.eventExpected(l))} · +${ev.prestige} prestij · ${ev.cooldown} günde bir',
                style: const TextStyle(fontSize: 11, color: AppColors.textDim),
              ),
              const SizedBox(height: 6),
              if (owned)
                game.eventDaysLeft(l) > 0
                    ? Tag(
                        '${game.eventDaysLeft(l)} gün sonra',
                        color: AppColors.textDim,
                      )
                    : AccentButton(
                        'Düzenle',
                        expand: true,
                        icon: Icons.celebration_rounded,
                        onTap: () => report(context, game.holdEvent(l)),
                      )
              else
                const Text(
                  'Önce set kurmalısın.',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 11),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TipPainter extends CustomPainter {
  final Color c;
  _TipPainter(this.c);
  @override
  void paint(Canvas canvas, Size s) => canvas.drawPath(
    Path()
      ..moveTo(0, 0)
      ..lineTo(s.width, 0)
      ..lineTo(s.width / 2, s.height)
      ..close(),
    Paint()..color = c,
  );
  @override
  bool shouldRepaint(covariant _TipPainter o) => o.c != c;
}

/// Boylam/enlem -> ekran
class _Proj {
  final bool world;
  final Size size;
  late final double minLon, maxLon, minLat, maxLat, sx, sy, ox, oy;
  _Proj(this.world, this.size) {
    if (world) {
      minLon = -170;
      maxLon = 180;
      minLat = -80;
      maxLat = 80;
    } else {
      minLon = 25.3;
      maxLon = 45.5;
      minLat = 35.4;
      maxLat = 42.6;
    }
    // en-boy oranını koru (enlem sıkıştırması: Türkiye için cos(39°))
    final k = world ? 1.0 : cos(39 * pi / 180);
    final w = (maxLon - minLon) * k, h = (maxLat - minLat);
    final s = min(size.width / w, size.height / h) * 0.96;
    sx = s * k;
    sy = s;
    ox = (size.width - w * s) / 2;
    oy = (size.height - h * s) / 2;
  }
  Offset of(double lon, double lat) =>
      Offset(ox + (lon - minLon) * sx, oy + (maxLat - lat) * sy);
}

class _MapPainter extends CustomPainter {
  final bool world;
  final _Proj p;
  _MapPainter(this.world, this.p);

  static const _turkey = [
    [26.04, 40.73],
    [26.36, 41.25],
    [26.6, 41.65],
    [27.4, 42.05],
    [28.0, 41.98],
    [28.9, 41.35],
    [29.15, 41.22],
    [30.3, 41.2],
    [31.3, 41.1],
    [32.3, 41.7],
    [33.4, 42.0],
    [34.7, 41.95],
    [35.2, 41.7],
    [36.0, 41.7],
    [36.4, 41.3],
    [37.6, 41.1],
    [38.4, 40.95],
    [39.4, 41.1],
    [40.4, 40.95],
    [41.5, 41.5],
    [42.5, 41.45],
    [43.4, 41.15],
    [43.7, 40.9],
    [43.6, 40.5],
    [44.0, 40.0],
    [44.8, 39.7],
    [44.4, 39.4],
    [44.2, 38.9],
    [44.3, 38.3],
    [44.8, 37.9],
    [44.6, 37.2],
    [43.0, 37.35],
    [42.3, 37.1],
    [41.2, 37.1],
    [40.0, 36.85],
    [38.8, 36.75],
    [38.0, 36.85],
    [37.0, 36.7],
    [36.7, 36.25],
    [36.2, 35.85],
    [35.8, 36.4],
    [36.1, 36.65],
    [35.5, 36.6],
    [34.6, 36.8],
    [33.6, 36.2],
    [32.5, 36.1],
    [31.0, 36.85],
    [30.4, 36.25],
    [29.6, 36.2],
    [28.8, 36.7],
    [28.0, 36.6],
    [27.4, 37.0],
    [27.2, 37.4],
    [26.8, 38.0],
    [26.3, 38.25],
    [26.7, 38.6],
    [26.8, 39.0],
    [26.1, 39.5],
    [26.2, 40.0],
    [26.7, 40.4],
    [26.2, 40.6],
  ];

  static const _world = <List<List<double>>>[
    // Kuzey Amerika
    [
      [-168, 66],
      [-140, 70],
      [-95, 72],
      [-80, 63],
      [-60, 55],
      [-55, 48],
      [-70, 43],
      [-76, 35],
      [-81, 25],
      [-97, 26],
      [-97, 18],
      [-88, 15],
      [-83, 9],
      [-78, 8],
      [-90, 14],
      [-105, 20],
      [-112, 30],
      [-118, 34],
      [-124, 40],
      [-125, 49],
      [-135, 58],
      [-150, 60],
      [-165, 60],
    ],
    // Grönland
    [
      [-45, 60],
      [-20, 70],
      [-25, 82],
      [-60, 82],
      [-70, 77],
      [-55, 68],
    ],
    // Güney Amerika
    [
      [-80, 8],
      [-75, 11],
      [-62, 10],
      [-50, 0],
      [-35, -6],
      [-40, -22],
      [-48, -28],
      [-58, -38],
      [-65, -55],
      [-73, -50],
      [-72, -30],
      [-70, -18],
      [-81, -5],
    ],
    // Avrupa
    [
      [-10, 36],
      [-9, 43],
      [-2, 44],
      [-5, 48],
      [2, 51],
      [8, 54],
      [10, 57],
      [5, 62],
      [15, 69],
      [28, 71],
      [40, 67],
      [60, 68],
      [60, 45],
      [40, 42],
      [30, 41],
      [26, 40],
      [23, 36],
      [19, 40],
      [12, 44],
      [15, 40],
      [8, 44],
      [3, 43],
      [-2, 37],
    ],
    // Britanya
    [
      [-5, 50],
      [1, 51],
      [0, 53],
      [-2, 56],
      [-5, 58],
      [-6, 55],
      [-3, 54],
    ],
    // İzlanda
    [
      [-24, 64],
      [-14, 64],
      [-15, 66],
      [-22, 66],
    ],
    // Afrika
    [
      [-17, 21],
      [-10, 30],
      [-5, 35],
      [10, 37],
      [20, 32],
      [32, 31],
      [35, 28],
      [43, 12],
      [51, 12],
      [40, -2],
      [40, -15],
      [33, -26],
      [20, -35],
      [17, -28],
      [12, -15],
      [13, -5],
      [9, 4],
      [-8, 4],
      [-15, 10],
    ],
    // Asya
    [
      [28, 41],
      [40, 42],
      [60, 45],
      [60, 68],
      [80, 73],
      [110, 76],
      [140, 72],
      [180, 68],
      [170, 60],
      [160, 58],
      [142, 52],
      [140, 40],
      [130, 35],
      [122, 30],
      [120, 22],
      [110, 20],
      [106, 10],
      [100, 13],
      [98, 8],
      [100, 3],
      [95, 15],
      [90, 22],
      [80, 15],
      [77, 8],
      [72, 20],
      [66, 25],
      [57, 25],
      [52, 28],
      [48, 30],
      [55, 22],
      [59, 22],
      [52, 12],
      [43, 13],
      [35, 28],
      [35, 36],
      [36, 37],
    ],
    // Japonya
    [
      [130, 31],
      [140, 35],
      [142, 41],
      [141, 45],
      [139, 40],
      [133, 34],
    ],
    // Avustralya
    [
      [114, -22],
      [122, -18],
      [130, -12],
      [137, -12],
      [142, -11],
      [146, -19],
      [153, -27],
      [150, -37],
      [141, -38],
      [131, -31],
      [115, -34],
    ],
    // Yeni Zelanda
    [
      [172, -35],
      [178, -38],
      [174, -41],
      [170, -46],
      [167, -46],
      [173, -41],
    ],
    // Antarktika
    [
      [-170, -70],
      [-60, -64],
      [0, -70],
      [90, -66],
      [180, -70],
      [180, -80],
      [-170, -80],
    ],
  ];

  Path _path(List<List<double>> pts) {
    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      final o = p.of(pts[i][0], pts[i][1]);
      i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10233A), Color(0xFF0A1626)],
        ).createShader(r),
    );
    // ızgara
    final grid = Paint()
      ..color = const Color(0x1A4FD1FF)
      ..strokeWidth = 1;
    final step = world ? 30.0 : 2.0;
    for (
      var lon = (p.minLon / step).ceil() * step;
      lon <= p.maxLon;
      lon += step
    ) {
      canvas.drawLine(p.of(lon, p.minLat), p.of(lon, p.maxLat), grid);
    }
    for (
      var lat = (p.minLat / step).ceil() * step;
      lat <= p.maxLat;
      lat += step
    ) {
      canvas.drawLine(p.of(p.minLon, lat), p.of(p.maxLon, lat), grid);
    }
    final land = Paint()..color = const Color(0xFF2B3B4F);
    final edge = Paint()
      ..color = const Color(0xFF4FD1FF).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    if (world) {
      for (final c in _world) {
        final path = _path(c);
        canvas.drawPath(path, land);
        canvas.drawPath(path, edge);
      }
      // Türkiye vurgusu
      final tr = _path(_turkey.map((e) => e.toList()).toList());
      canvas.drawPath(
        tr,
        Paint()..color = AppColors.accent.withValues(alpha: 0.8),
      );
    } else {
      // komşu kara parçaları (soluk)
      final faint = Paint()..color = const Color(0xFF1C2A3A);
      for (final c in _world) {
        canvas.drawPath(_path(c), faint);
      }
      final tr = _path(_turkey.map((e) => e.toList()).toList());
      canvas.drawPath(
        tr,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF3A5170), Color(0xFF2E4058), Color(0xFF4A3F5C)],
          ).createShader(tr.getBounds()),
      );
      canvas.drawPath(tr, edge..strokeWidth = 2);
      // Marmara denizi
      final mc = p.of(28.2, 40.72);
      final mr = p.of(29.3, 40.45) - mc;
      canvas.drawOval(
        Rect.fromCenter(
          center: mc,
          width: mr.dx.abs() * 2,
          height: mr.dy.abs() * 2,
        ),
        Paint()..color = const Color(0xFF10233A),
      );
      // deniz isimleri
      void label(String t, double lon, double lat) {
        final tp = TextPainter(
          text: TextSpan(
            text: t,
            style: TextStyle(fontFamily: 'Roboto', fontFamilyFallback: const ['NotoColorEmoji'], 
              color: Color(0x664FD1FF),
              fontSize: 11,
              fontStyle: FontStyle.italic,
              letterSpacing: 2,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, p.of(lon, lat) - Offset(tp.width / 2, tp.height / 2));
      }

      label('KARADENİZ', 35, 42.35);
      label('AKDENİZ', 32, 35.7);
      label('EGE', 25.8, 38.8);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter o) =>
      o.world != world || o.p.size != p.size;
}
