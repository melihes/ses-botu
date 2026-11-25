import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart' show kIncome;
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/cities.dart';
import '../../data/content.dart';
import '../../data/content2.dart';
import '../../engine/game.dart';
import '../widgets/common.dart';

/// Bir ilin sınırları (boylam/enlem halkaları)
class _Prov {
  final int plate;
  final String name;
  final List<List<Offset>> rings; // dx = boylam, dy = enlem
  _Prov(this.plate, this.name, this.rings);
}

List<_Prov>? _cache;

Future<List<_Prov>> _loadProvinces() async {
  if (_cache != null) return _cache!;
  final raw = await rootBundle.loadString('assets/geo/tr_iller.json');
  final list = jsonDecode(raw) as List;
  _cache = [
    for (final o in list)
      _Prov(o['p'] as int, o['n'] as String, [
        for (final r in (o['r'] as List))
          [
            for (int i = 0; i + 1 < (r as List).length; i += 2)
              Offset((r[i] as num).toDouble(), (r[i + 1] as num).toDouble())
          ]
      ])
  ];
  return _cache!;
}

/// Türkiye 81 il haritası: dokun, yakınlaştır, şehir aç, set kur.
class CityMapView extends StatefulWidget {
  const CityMapView({super.key});
  @override
  State<CityMapView> createState() => _CityMapViewState();
}

class _CityMapViewState extends State<CityMapView> {
  int _sel = homeCityPlate;
  final _chips = ScrollController();
  late final Future<List<_Prov>> _future = _loadProvinces();

  @override
  void dispose() {
    _chips.dispose();
    super.dispose();
  }

  void _select(int plate) {
    setState(() => _sel = plate);
    final i = cityDefs.indexWhere((c) => c.plate == plate);
    if (i >= 0 && _chips.hasClients) {
      _chips.animateTo((i * 118.0 - 200).clamp(0, _chips.position.maxScrollExtent),
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final city = cityByPlate(_sel)!;
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(
        child: Column(children: [
          Expanded(
            child: Panel(
              padding: EdgeInsets.zero,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FutureBuilder<List<_Prov>>(
                  future: _future,
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final provs = snap.data!;
                    return LayoutBuilder(builder: (ctx, c) {
                      final proj = _TrProj(c.biggest);
                      final paths = {
                        for (final p in provs) p.plate: proj.path(p.rings),
                      };
                      return InteractiveViewer(
                        minScale: 1,
                        maxScale: 6,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (d) {
                            for (final e in paths.entries) {
                              if (e.value.contains(d.localPosition)) {
                                _select(e.key);
                                return;
                              }
                            }
                          },
                          child: CustomPaint(
                            size: c.biggest,
                            painter: _ProvPainter(
                              provs: provs,
                              paths: paths,
                              opened: game.openedCities,
                              selected: _sel,
                              proj: proj,
                              ownedLocs: game.ownedLocations,
                            ),
                          ),
                        ),
                      );
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          // 81 il: plakasıyla tek tek seçilebilir
          SizedBox(
            height: 34,
            child: ListView.builder(
              controller: _chips,
              scrollDirection: Axis.horizontal,
              itemCount: cityDefs.length,
              itemBuilder: (_, i) {
                final c = cityDefs[i];
                final sel = c.plate == _sel;
                final open = game.openedCities.contains(c.plate);
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _select(c.plate),
                    child: Container(
                      width: 112,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.yellow.withValues(alpha: 0.85) : AppColors.panel,
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: open ? AppColors.yellow : AppColors.border),
                      ),
                      child: Text(
                        '${c.plate.toString().padLeft(2, '0')}  ${c.name}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: sel ? Colors.black : (open ? AppColors.yellow : AppColors.text)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ]),
      ),
      const SizedBox(width: 10),
      SizedBox(width: 300, child: _CityPanel(city: city)),
    ]);
  }
}

class _TrProj {
  final Size size;
  static const minLon = 25.6, maxLon = 44.9, minLat = 35.75, maxLat = 42.15;
  late final double sx, sy, ox, oy;
  _TrProj(this.size) {
    final k = cos(39 * pi / 180);
    final w = (maxLon - minLon) * k, h = maxLat - minLat;
    final s = min(size.width / w, size.height / h) * 0.97;
    sx = s * k;
    sy = s;
    ox = (size.width - w * s) / 2;
    oy = (size.height - h * s) / 2;
  }
  Offset of(double lon, double lat) => Offset(ox + (lon - minLon) * sx, oy + (maxLat - lat) * sy);
  Path path(List<List<Offset>> rings) {
    final p = Path();
    for (final r in rings) {
      for (int i = 0; i < r.length; i++) {
        final o = of(r[i].dx, r[i].dy);
        i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
      }
      p.close();
    }
    return p;
  }
}

class _ProvPainter extends CustomPainter {
  final List<_Prov> provs;
  final Map<int, Path> paths;
  final Set<int> opened;
  final int selected;
  final _TrProj proj;
  final Set<String> ownedLocs;
  _ProvPainter({
    required this.provs,
    required this.paths,
    required this.opened,
    required this.selected,
    required this.proj,
    required this.ownedLocs,
  });

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
          ).createShader(r));
    void label(String t, double lon, double lat, double fs, Color c) {
      final tp = TextPainter(
          text: TextSpan(
              text: t,
              style: TextStyle(fontFamily: 'Roboto', fontFamilyFallback: const ['NotoColorEmoji'], color: c, fontSize: fs, fontStyle: FontStyle.italic, letterSpacing: 3)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, proj.of(lon, lat) - Offset(tp.width / 2, tp.height / 2));
    }

    label('KARADENİZ', 35, 42.05, 11, const Color(0x664FD1FF));
    label('AKDENİZ', 32.5, 35.9, 11, const Color(0x664FD1FF));
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = const Color(0xFF0E1622);
    for (final p in provs) {
      final path = paths[p.plate]!;
      final isOpen = opened.contains(p.plate);
      final col = p.plate == selected
          ? const Color(0xFF8FD3FF)
          : (isOpen ? const Color(0xFFE8B04A) : const Color(0xFF2E3F55));
      canvas.drawPath(path, Paint()..color = col);
      canvas.drawPath(path, border);
    }
    // seçili ilin kalın çerçevesi
    final sp = paths[selected];
    if (sp != null) {
      canvas.drawPath(
          sp,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = Colors.white);
    }
    // çekim lokasyonları
    for (final l in locationDefs.where((l) => !l.world)) {
      final o = proj.of(l.lon, l.lat);
      final own = ownedLocs.contains(l.id);
      canvas.drawCircle(o, 6.5, Paint()..color = Colors.black54);
      canvas.drawCircle(o, 5, Paint()..color = own ? AppColors.green : l.color);
      canvas.drawCircle(
          o,
          5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = Colors.white);
    }
    // seçili ilin adı
    if (sp != null) {
      final b = sp.getBounds();
      final name = provs.firstWhere((p) => p.plate == selected).name;
      final tp = TextPainter(
          text: TextSpan(
              text: name,
              style: TextStyle(fontFamily: 'Roboto', fontFamilyFallback: const ['NotoColorEmoji'], color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr)
        ..layout();
      final at = Offset(b.center.dx - tp.width / 2, max(2, b.top - tp.height - 8));
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(at.dx - 8, at.dy - 3, tp.width + 16, tp.height + 6), const Radius.circular(8)),
          Paint()..color = const Color(0xE6120E1C));
      tp.paint(canvas, at);
    }
    // kaynak
    final src = TextPainter(
        text: const TextSpan(
            text: 'Harita: geoBoundaries (CC BY 4.0)', style: TextStyle(fontFamily: 'Roboto', fontFamilyFallback: const ['NotoColorEmoji'], color: Colors.white38, fontSize: 9)),
        textDirection: TextDirection.ltr)
      ..layout();
    src.paint(canvas, Offset(6, size.height - src.height - 4));
  }

  @override
  bool shouldRepaint(covariant _ProvPainter o) =>
      o.selected != selected || o.opened.length != opened.length || o.ownedLocs.length != ownedLocs.length ||
      o.proj.size != proj.size;
}

class _CityPanel extends StatelessWidget {
  final CityDef city;
  const _CityPanel({required this.city});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final c = city;
    final open = game.openedCities.contains(c.plate);
    final reg = c.regionDef;
    final regCities = cityDefs.where((x) => x.region == c.region).toList();
    final regOpen = regCities.where((x) => game.openedCities.contains(x.plate)).length;
    final locs = locationDefs.where((l) => !l.world && locationCity[l.id] == c.plate).toList();
    return Panel(
      padding: const EdgeInsets.all(12),
      borderColor: open ? AppColors.yellow.withValues(alpha: 0.6) : null,
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // plaka
            Container(
              padding: const EdgeInsets.fromLTRB(0, 4, 10, 4),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 12,
                  height: 30,
                  decoration: const BoxDecoration(
                      color: Color(0xFF1E4FD8),
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(6))),
                  alignment: Alignment.bottomCenter,
                  child: const Text('TR', style: TextStyle(color: Colors.white, fontSize: 6, fontWeight: FontWeight.w900)),
                ),
                const SizedBox(width: 8),
                Text(c.plate.toString().padLeft(2, '0'),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 20)),
              ]),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
                Wrap(spacing: 4, children: [
                  if (c.metro) const Tag('BÜYÜKŞEHİR', color: AppColors.cyan),
                  Tag(reg.name, color: AppColors.textDim),
                ]),
              ]),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: StatBlock('Erişim katkısı', '+%${fmtDec(game.cityReachShare(c) * 100, 1)}', color: AppColors.cyan)),
            Expanded(child: StatBlock('Bölge', '$regOpen/${regCities.length} açık')),
          ]),
          const SizedBox(height: 6),
          Text(
              '${reg.name} seyircisi sever: ${[
                ...reg.genres.map((g) => genreDefs[g]!.label),
                ...reg.films.map((g) => '${filmGenreDefs[g]!.label} filmi'),
              ].join(', ')}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          Text(
              'Bölgedeki her açık şehir bu türlere reyting katar (bölgenin tamamı: +%3). '
              'Şu an +%${fmtDec(game.cityGenreBonus(reg.genres.first) * 100, 1)}',
              style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
          const SizedBox(height: 10),
          if (open)
            const Tag('YAYIN AĞINDA ✓', color: AppColors.yellow)
          else
            AccentButton('Şehri aç · ${fmtShort(c.price)}',
                expand: true,
                icon: Icons.location_city_rounded,
                onTap: () => report(context, game.openCity(c))),
          if (locs.isNotEmpty) ...[
            const SizedBox(height: 12),
            const SectionLabel('Çekim seti', color: AppColors.green),
            for (final l in locs) _LocCard(l: l),
          ],
        ]),
      ),
    );
  }
}

class _LocCard extends StatelessWidget {
  final LocationDef l;
  const _LocCard({required this.l});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final owned = game.ownedLocations.contains(l.id);
    final lock = game.locationLockReason(l);
    final ev = l.event;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.panelHi,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: owned ? AppColors.green : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(l.icon, color: l.color, size: 18),
          const SizedBox(width: 6),
          Expanded(child: Text(l.name, style: const TextStyle(fontWeight: FontWeight.w900))),
        ]),
        Text(l.desc, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
        Text(
            'Uyumlu çekimde kalite +%${(l.bonus * 100).round()} · +${l.prestige} prestij · bakım ${fmtShort(l.upkeep * kIncome)}/gün',
            style: const TextStyle(color: AppColors.green, fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        if (owned)
          const Tag('SET KURULDU ✓', color: AppColors.green)
        else if (lock != null)
          Tag(lock, color: AppColors.textDim, icon: Icons.lock_rounded)
        else
          AccentButton('Set kur · ${fmtShort(l.price)}',
              compact: true, onTap: () => report(context, game.buyLocation(l))),
        if (ev != null && owned) ...[
          const SizedBox(height: 6),
          game.eventDaysLeft(l) > 0
              ? Tag('${ev.name}: ${game.eventDaysLeft(l)} gün sonra', color: AppColors.textDim)
              : GhostButton('${ev.name} · ${fmtShort(game.eventCost(l))}',
                  compact: true,
                  color: AppColors.yellow,
                  icon: Icons.celebration_rounded,
                  onTap: () => report(context, game.holdEvent(l))),
        ],
      ]),
    );
  }
}
