import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/game.dart';

/// Oyun motoruna her yerden erişim: GameScope.of(context)
class GameScope extends InheritedNotifier<Game> {
  const GameScope({super.key, required Game game, required super.child})
      : super(notifier: game);

  static Game of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GameScope>()!.notifier!;

  /// Dinlemeden erişim (buton callback'leri için)
  static Game read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<GameScope>()!.notifier!;
}

/// Bir işlemin sonucunu (hata mesajı varsa) bildirim olarak gösterir.
void report(BuildContext context, String? error) {
  if (error != null) GameScope.read(context).showToast('⚠️ $error');
}

class Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? gradient;
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.color,
    this.borderColor,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.panel) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? AppColors.border, width: 1),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: box,
      ),
    );
  }
}

/// Ana eylem butonu: mercan → turuncu degrade
class AccentButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool compact;
  final bool expand;
  const AccentButton(this.label,
      {super.key,
      this.onTap,
      this.icon,
      this.compact = false,
      this.expand = false});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final h = compact ? 36.0 : 46.0;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(h / 2),
          child: Ink(
            height: h,
            width: expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 22),
            decoration: BoxDecoration(
              gradient: enabled ? AppColors.accentGradient : null,
              color: enabled ? null : AppColors.border,
              borderRadius: BorderRadius.circular(h / 2),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: compact ? 16 : 20, color: Colors.white),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 13 : 15,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// İkincil buton: turkuaz çerçeveli
class GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final bool compact;
  final bool expand;
  const GhostButton(this.label,
      {super.key,
      this.onTap,
      this.icon,
      this.color = AppColors.cyan,
      this.compact = false,
      this.expand = false});

  @override
  Widget build(BuildContext context) {
    final h = compact ? 36.0 : 46.0;
    return Opacity(
      opacity: onTap == null ? 0.45 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(h / 2),
          child: Container(
            height: h,
            width: expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(h / 2),
              border: Border.all(color: color.withValues(alpha: 0.8), width: 1.5),
              color: color.withValues(alpha: 0.08),
            ),
            child: Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: compact ? 16 : 18, color: color),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: compact ? 13 : 14,
                          color: color)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const SectionLabel(this.text, {super.key, this.color = AppColors.cyan});
  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.6,
        ),
      );
}

class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  const Tag(this.text, {super.key, this.color = AppColors.cyan, this.icon});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(text,
              style: TextStyle(
                  color: color, fontSize: 11, fontWeight: FontWeight.w800)),
        ]),
      );
}

class StatBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const StatBlock(this.label, this.value,
      {super.key, this.color = AppColors.text});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    color: color, fontSize: 17, fontWeight: FontWeight.w800)),
          ),
        ],
      );
}

class Bar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const Bar(this.value,
      {super.key, this.color = AppColors.cyan, this.height = 6});
  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Stack(children: [
          Container(height: height, color: AppColors.border),
          FractionallySizedBox(
            widthFactor: value.clamp(0.0, 1.0),
            child: Container(height: height, color: color),
          ),
        ]),
      );
}

/// Küçük çizgi grafik
class Sparkline extends StatelessWidget {
  final List<double> values;
  final Color color;
  const Sparkline(this.values, {super.key, this.color = AppColors.green});
  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _SparkPainter(values, color), size: Size.infinite);
}

class _SparkPainter extends CustomPainter {
  final List<double> v;
  final Color color;
  _SparkPainter(this.v, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (v.length < 2) return;
    final lo = v.reduce(min), hi = v.reduce(max);
    final span = (hi - lo).abs() < 1e-9 ? 1.0 : hi - lo;
    final path = Path();
    for (int i = 0; i < v.length; i++) {
      final x = size.width * i / (v.length - 1);
      final y = size.height - (v[i] - lo) / span * (size.height - 6) - 3;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    final fill = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)],
          ).createShader(Offset.zero & size));
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round);
    final lastY = size.height - (v.last - lo) / span * (size.height - 6) - 3;
    canvas.drawCircle(Offset(size.width, lastY), 4, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) => true;
}

/// Görsel yerine kullanılan degrade + büyük ikonlu "afiş" kutusu.
class ArtTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final String? badge;
  const ArtTile(
      {super.key,
      required this.icon,
      required this.color,
      this.size = 72,
      this.badge});

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.85),
              Color.lerp(color, AppColors.bg, 0.65)!,
            ],
          ),
        ),
        child: Stack(children: [
          Positioned(
            right: -size * 0.12,
            bottom: -size * 0.12,
            child: Icon(icon,
                size: size * 0.8, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Center(child: Icon(icon, size: size * 0.45, color: Colors.white)),
          if (badge != null)
            Positioned(
              left: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(badge!,
                    style: const TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );
}

/// Genişliğe göre sütun sayısı ayarlayan basit ızgara
class AutoGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;
  const AutoGrid(
      {super.key,
      required this.children,
      this.minItemWidth = 260,
      this.spacing = 12});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (ctx, c) {
        final cols = max(1, (c.maxWidth / minItemWidth).floor());
        final w = (c.maxWidth - spacing * (cols - 1)) / cols;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      });
}

/// Sekme düğmeleri (hap şeklinde)
class PillTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const PillTabs(
      {super.key,
      required this.labels,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            for (int i = 0; i < labels.length; i++)
              GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: i == selected ? AppColors.accentGradient : null,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(labels[i],
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: i == selected ? Colors.white : AppColors.textDim,
                      )),
                ),
              ),
          ]),
        ),
      );
}

Future<bool> confirm(BuildContext context, String title, String body,
    {String ok = 'Evet'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Vazgeç')),
        TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(ok,
                style: const TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w800))),
      ],
    ),
  );
  return r ?? false;
}

/// Sayfa başlığı altında açıklama satırı
class PageHint extends StatelessWidget {
  final String text;
  const PageHint(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text,
            style: const TextStyle(color: AppColors.textDim, fontSize: 13)),
      );
}
