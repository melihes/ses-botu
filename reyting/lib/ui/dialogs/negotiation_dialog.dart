import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../widgets/common.dart';

/// Yat, ada, kanal gibi pahalı şeyler için pazarlık ekranı.
Future<void> showNegotiation(
  BuildContext context, {
  required String id,
  required String name,
  required String subtitle,
  required double price,
  required IconData icon,
  required Color color,
}) {
  return showDialog(
    context: context,
    builder: (c) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: _Negotiation(
          id: id,
          name: name,
          subtitle: subtitle,
          price: price,
          icon: icon,
          color: color),
    ),
  );
}

class _Negotiation extends StatefulWidget {
  final String id, name, subtitle;
  final double price;
  final IconData icon;
  final Color color;
  const _Negotiation(
      {required this.id,
      required this.name,
      required this.subtitle,
      required this.price,
      required this.icon,
      required this.color});
  @override
  State<_Negotiation> createState() => _NegotiationState();
}

class _NegotiationState extends State<_Negotiation> {
  double _pct = 0.8;
  String _say = 'Hoş geldin! Fiyatımız belli ama konuşuruz.';
  bool _mad = false;
  bool _done = false;

  double get _offer => (widget.price * _pct / 1000).round() * 1000.0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final st = game.negFor(widget.id);
    final locked = game.negLocked(widget.id);

    void handle(NegResult r) {
      setState(() {
        _say = r.message;
        _mad = r.outcome == NegOutcome.rejected ||
            r.outcome == NegOutcome.walkedAway ||
            r.outcome == NegOutcome.locked;
      });
      if (r.outcome == NegOutcome.accepted) {
        game.completePurchase(widget.id, r.price!);
        setState(() => _done = true);
      }
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ArtTile(icon: widget.icon, color: widget.color, size: 150),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel('Pazarlık', color: AppColors.accent),
                Text(widget.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                Text(widget.subtitle,
                    style: const TextStyle(color: AppColors.textDim)),
                const SizedBox(height: 6),
                Row(children: [
                  Text('İstenen: ${fmtShort(widget.price)}',
                      style: const TextStyle(
                          color: AppColors.yellow,
                          fontWeight: FontWeight.w800)),
                  const Spacer(),
                  const Text('Sabır ',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  for (int i = 0; i < 3; i++)
                    Icon(
                      i < st.patience
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                ]),
                const SizedBox(height: 10),
                // Satıcının konuşma balonu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_mad ? AppColors.red : AppColors.cyan)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (_mad ? AppColors.red : AppColors.cyan)
                            .withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    Icon(Icons.person_rounded,
                        color: _mad ? AppColors.red : AppColors.cyan),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Satıcı: "$_say"',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                if (_done) ...[
                  const Text('🎉 Satın alma tamamlandı!',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green)),
                  const SizedBox(height: 10),
                  AccentButton('Harika!',
                      expand: true, onTap: () => Navigator.pop(context)),
                ] else ...[
                  Row(children: [
                    const Text('Teklifin',
                        style: TextStyle(color: AppColors.textDim)),
                    const Spacer(),
                    Text(
                        '${fmtShort(_offer)}  (${fmtPct(_pct * 100, 0)})',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ]),
                  Slider(
                    value: _pct,
                    min: 0.5,
                    max: 1.0,
                    divisions: 50,
                    onChanged: locked ? null : (v) => setState(() => _pct = v),
                  ),
                  Row(children: [
                    Expanded(
                      child: AccentButton(
                        'Teklif ver',
                        icon: Icons.gavel_rounded,
                        onTap: locked
                            ? null
                            : () => handle(game.negotiate(
                                widget.id, widget.price, _offer)),
                      ),
                    ),
                    if (st.counter != null && !locked) ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: GhostButton(
                          'Kabul: ${fmtShort(st.counter!)}',
                          color: AppColors.green,
                          onTap: () {
                            if (game.cash < st.counter!) {
                              setState(() {
                                _say = 'Kasan bu parayı karşılamıyor.';
                                _mad = true;
                              });
                              return;
                            }
                            handle(NegResult(
                                NegOutcome.accepted, 'Anlaştık!', st.counter));
                          },
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 8),
                  const Text(
                    'İpucu: Satıcının gizli bir taban fiyatı var. Çok düşük teklif sabrını tüketir; '
                    'sabrı biterse 3 gün masaya dönmez.',
                    style: TextStyle(color: AppColors.textFaint, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
