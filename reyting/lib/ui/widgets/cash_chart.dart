import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../engine/game.dart';
import 'common.dart';

/// Grafikteki bir nokta
class _Pt {
  final String label;
  final double cash;
  final double income;
  final double expense;
  final bool intraday;
  _Pt(this.label, this.cash, this.income, this.expense, {this.intraday = false});
  double get net => income - expense;
}

/// Kasa grafiği: Bugün / 7 gün / 30 gün / Tümü. Dokun veya sürükle → detay.
class CashChart extends StatefulWidget {
  const CashChart({super.key});
  @override
  State<CashChart> createState() => _CashChartState();
}

class _CashChartState extends State<CashChart> {
  int _range = 1; // 0 bugün, 1 7g, 2 30g, 3 tümü
  int? _sel;

  List<_Pt> _points(Game g) {
    if (_range == 0) {
      final pts = <_Pt>[];
      for (int h = 0; h < g.todaySamples.length; h++) {
        pts.add(_Pt('Saat ${h.toString().padLeft(2, '0')}:00', g.todaySamples[h], 0, 0, intraday: true));
      }
      pts.add(_Pt('Şimdi', g.cash, g.todayIncome, 0, intraday: true));
      return pts;
    }
    final today = _Pt('Bugün (Gün ${g.day})', g.cash, g.todayIncome,
        g.todayIncome - (g.cash - g.cashAtDayStart));
    final hist = g.history;
    final n = _range == 1 ? 7 : _range == 2 ? 30 : hist.length;
    final slice = hist.sublist(max(0, hist.length - n));
    final pts = <_Pt>[];
    const maxPts = 90;
    if (slice.length <= maxPts) {
      for (final h in slice) {
        pts.add(_Pt('Gün ${h.day} · ${weekdayOf(h.day)}', h.cash, h.income, h.expense));
      }
    } else {
      final bucket = (slice.length / maxPts).ceil();
      for (int i = 0; i < slice.length; i += bucket) {
        final part = slice.sublist(i, min(slice.length, i + bucket));
        pts.add(_Pt('Gün ${part.first.day}–${part.last.day}', part.last.cash,
            part.fold(0.0, (a, e) => a + e.income),
            part.fold(0.0, (a, e) => a + e.expense)));
      }
    }
    pts.add(today);
    return pts;
  }

  @override
  Widget build(BuildContext context) {
    final g = GameScope.of(context);
    final pts = _points(g);
    final sel = _sel == null ? null : pts[_sel!.clamp(0, pts.length - 1)];
    final periodIncome = pts.fold(0.0, (a, p) => a + p.income);
    final periodExpense = pts.fold(0.0, (a, p) => a + p.expense);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          for (int i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => setState(() {
                  _range = i;
                  _sel = null;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: i == _range ? AppColors.accent.withValues(alpha: 0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: i == _range ? AppColors.accent : AppColors.border),
                  ),
                  child: Text(const ['Bugün', '7 gün', '30 gün', 'Tümü'][i],
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: i == _range ? AppColors.text : AppColors.textDim)),
                ),
              ),
            ),
          const Spacer(),
          if (_range > 0)
            Text('Net ${fmtSigned(periodIncome - periodExpense)}',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: periodIncome >= periodExpense ? AppColors.green : AppColors.red)),
        ]),
        const SizedBox(height: 6),
        Expanded(
          child: LayoutBuilder(builder: (ctx, c) {
            void pick(Offset p) {
              if (pts.length < 2) return;
              final i = (p.dx / c.maxWidth * (pts.length - 1)).round();
              setState(() => _sel = i.clamp(0, pts.length - 1));
            }

            return GestureDetector(
              onTapDown: (d) => pick(d.localPosition),
              onHorizontalDragUpdate: (d) => pick(d.localPosition),
              child: Stack(children: [
                Positioned.fill(
                    child: CustomPaint(painter: _ChartPainter(pts, _sel))),
                if (sel != null)
                  Positioned(
                    left: ((_sel! / max(1, pts.length - 1)) * c.maxWidth - 80)
                        .clamp(0.0, max(0.0, c.maxWidth - 165)),
                    top: 0,
                    child: _Tip(p: sel),
                  ),
                if (pts.length < 2)
                  const Center(
                      child: Text('Grafik için birkaç gün oyna',
                          style: TextStyle(color: AppColors.textFaint, fontSize: 12))),
              ]),
            );
          }),
        ),
      ],
    );
  }
}

class _Tip extends StatelessWidget {
  final _Pt p;
  const _Tip({required this.p});
  @override
  Widget build(BuildContext context) => Container(
        width: 165,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xF2140F1F),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(p.label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.cyan)),
            Text('Kasa ${fmtShort(p.cash)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
            if (!p.intraday) ...[
              Text('Gelir ${fmtSigned(p.income)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.green)),
              Text('Gider ${fmtSigned(-p.expense)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.orange)),
              Text('Net ${fmtSigned(p.net)}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: p.net >= 0 ? AppColors.green : AppColors.red)),
            ],
          ],
        ),
      );
}

class _ChartPainter extends CustomPainter {
  final List<_Pt> pts;
  final int? sel;
  _ChartPainter(this.pts, this.sel);

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) return;
    final barH = pts.first.intraday ? 0.0 : size.height * 0.22;
    final chartH = size.height - barH - 4;
    final lo = pts.map((e) => e.cash).reduce(min);
    final hi = pts.map((e) => e.cash).reduce(max);
    final span = (hi - lo).abs() < 1 ? 1.0 : hi - lo;
    double x(int i) => size.width * i / (pts.length - 1);
    double y(double v) => chartH - (v - lo) / span * (chartH - 18) - 9;

    // yatay çizgiler + etiketler
    final grid = Paint()..color = AppColors.border.withValues(alpha: 0.6);
    for (int k = 0; k <= 2; k++) {
      final gy = 9 + (chartH - 18) * k / 2;
      canvas.drawLine(Offset(0, gy), Offset(size.width, gy), grid);
      final v = hi - span * k / 2;
      final tp = TextPainter(
          text: TextSpan(text: fmtShort(v), style: const TextStyle(fontSize: 9, color: AppColors.textFaint)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(2, gy - 11));
    }

    final up = pts.last.cash >= pts.first.cash;
    final col = up ? AppColors.green : AppColors.red;
    final path = Path();
    for (int i = 0; i < pts.length; i++) {
      i == 0 ? path.moveTo(x(i), y(pts[i].cash)) : path.lineTo(x(i), y(pts[i].cash));
    }
    final fill = Path.from(path)
      ..lineTo(size.width, chartH)
      ..lineTo(0, chartH)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [col.withValues(alpha: 0.35), col.withValues(alpha: 0)],
          ).createShader(Rect.fromLTWH(0, 0, size.width, chartH)));
    canvas.drawPath(path, Paint()..color = col..strokeWidth = 2.5..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round);

    // günlük net çubukları
    if (barH > 0) {
      final maxNet = pts.map((e) => e.net.abs()).fold(1.0, max);
      final bw = max(2.0, size.width / pts.length * 0.6);
      final base = size.height - barH / 2;
      for (int i = 0; i < pts.length; i++) {
        final h = pts[i].net / maxNet * barH / 2;
        canvas.drawRect(Rect.fromLTRB(x(i) - bw / 2, base - max(0, h), x(i) + bw / 2, base - min(0, h)),
            Paint()..color = (pts[i].net >= 0 ? AppColors.green : AppColors.red).withValues(alpha: i == sel ? 1 : 0.6));
      }
      canvas.drawLine(Offset(0, base), Offset(size.width, base), grid);
    }

    if (sel != null) {
      final i = sel!.clamp(0, pts.length - 1);
      canvas.drawLine(Offset(x(i), 0), Offset(x(i), size.height),
          Paint()..color = AppColors.accent.withValues(alpha: 0.7)..strokeWidth = 1.5);
      canvas.drawCircle(Offset(x(i), y(pts[i].cash)), 5, Paint()..color = AppColors.accent);
    } else {
      canvas.drawCircle(Offset(size.width, y(pts.last.cash)), 4, Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter old) => true;
}
