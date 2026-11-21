import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../widgets/common.dart';
import '../widgets/item_art.dart';

/// Yat, ada, kanal, platform gibi pahalı şeyler için pazarlık ekranı.
Future<void> showNegotiation(
  BuildContext context, {
  required String id,
  required String name,
  required String subtitle,
  required double price,
  required IconData icon,
  required Color color,
  String? artId,
}) {
  return showDialog(
    context: context,
    builder: (c) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      child: _Negotiation(
        id: id,
        name: name,
        subtitle: subtitle,
        price: price,
        artId: artId ?? id,
        color: color,
      ),
    ),
  );
}

const _sellerNames = [
  'Rıza Bey',
  'Nevin Hanım',
  'Cemil Bey',
  'Saadet Hanım',
  'Ferhat Bey',
  'Leyla Hanım',
];

class _Negotiation extends StatefulWidget {
  final String id, name, subtitle, artId;
  final double price;
  final Color color;
  const _Negotiation({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.artId,
    required this.color,
  });
  @override
  State<_Negotiation> createState() => _NegotiationState();
}

class _NegotiationState extends State<_Negotiation> {
  double _pct = 0.8;
  String _say = 'Hoş geldiniz! Fiyatımız belli ama konuşuruz.';
  bool _mad = false;
  bool _done = false;
  final List<(bool, double)> _log = []; // (benim mi, tutar)

  double get _offer => (widget.price * _pct / 1000).round() * 1000.0;
  int get _sellerSeed => widget.id.hashCode;
  String get _seller => _sellerNames[_sellerSeed.abs() % _sellerNames.length];

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final st = game.negFor(widget.id);
    final locked = game.negLocked(widget.id);
    final mood = locked ? 0 : st.patience;
    final face = ['😠', '😤', '😐', '😊'][mood.clamp(0, 3)];

    void handle(NegResult r) {
      setState(() {
        _say = r.message;
        _mad =
            r.outcome == NegOutcome.rejected ||
            r.outcome == NegOutcome.walkedAway ||
            r.outcome == NegOutcome.locked;
        if (r.outcome == NegOutcome.counter && r.price != null)
          _log.add((false, r.price!));
      });
      if (r.outcome == NegOutcome.accepted) {
        game.completePurchase(widget.id, r.price!);
        setState(() => _done = true);
      }
    }

    final left = SizedBox(
      width: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ItemArt(
            id: widget.artId,
            color: widget.color,
            width: 210,
            height: 150,
          ),
          const SizedBox(height: 8),
          Text(
            widget.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            widget.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textDim, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'İstenen: ${fmtShort(widget.price)}',
            style: const TextStyle(
              color: AppColors.yellow,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          Text(
            'Kasan: ${fmtShort(game.cash)}',
            style: TextStyle(
              color: game.cash >= widget.price * 0.5
                  ? AppColors.textDim
                  : AppColors.red,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    final right = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Satıcı
        Row(
          children: [
            PersonAvatar(
              seed: _sellerSeed,
              color: _mad ? AppColors.red : AppColors.cyan,
              size: 54,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Satıcı · $_seller',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  Row(
                    children: [
                      Text(
                        '$face  Sabır ',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textDim,
                        ),
                      ),
                      for (int i = 0; i < 3; i++)
                        Container(
                          width: 22,
                          height: 7,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: i < mood
                                ? [
                                    AppColors.red,
                                    AppColors.orange,
                                    AppColors.green,
                                  ][mood - 1]
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: (_mad ? AppColors.red : AppColors.cyan).withValues(
              alpha: 0.12,
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(
              color: (_mad ? AppColors.red : AppColors.cyan).withValues(
                alpha: 0.4,
              ),
            ),
          ),
          child: Text(
            '"$_say"',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        if (_log.isNotEmpty) ...[
          const SizedBox(height: 6),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final l in _log)
                Tag(
                  '${l.$1 ? 'Sen' : 'Satıcı'}: ${fmtShort(l.$2)}',
                  color: l.$1 ? AppColors.cyan : AppColors.yellow,
                ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        if (_done) ...[
          const Text(
            '🎉 Anlaşma tamam! Hayırlı olsun.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.green,
            ),
          ),
          const SizedBox(height: 8),
          AccentButton(
            'Harika!',
            expand: true,
            onTap: () => Navigator.pop(context),
          ),
        ] else ...[
          Row(
            children: [
              const Text(
                'Teklifin',
                style: TextStyle(color: AppColors.textDim),
              ),
              const Spacer(),
              Text(
                '${fmtShort(_offer)}  ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Tag('-${fmtPct((1 - _pct) * 100, 0)}', color: AppColors.green),
            ],
          ),
          Slider(
            value: _pct,
            min: 0.5,
            max: 1.0,
            divisions: 50,
            onChanged: locked ? null : (v) => setState(() => _pct = v),
          ),
          Row(
            children: [
              for (final p in [0.6, 0.7, 0.8, 0.9])
                Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: GhostButton(
                    '%${(p * 100).round()}',
                    compact: true,
                    color: AppColors.textDim,
                    onTap: locked ? null : () => setState(() => _pct = p),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AccentButton(
                  'Teklif ver',
                  icon: Icons.gavel_rounded,
                  onTap: locked
                      ? null
                      : () {
                          setState(() => _log.add((true, _offer)));
                          handle(
                            game.negotiate(widget.id, widget.price, _offer),
                          );
                        },
                ),
              ),
              if (st.counter != null && !locked) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: GhostButton(
                    'Kabul: ${fmtShort(st.counter!)}',
                    color: AppColors.green,
                    onTap: () {
                      if (game.cash < st.counter!) {
                        setState(() {
                          _say = 'Kasanız bu parayı karşılamıyor.';
                          _mad = true;
                        });
                        return;
                      }
                      handle(
                        NegResult(NegOutcome.accepted, 'Anlaştık!', st.counter),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'İpucu: Satıcının gizli bir taban fiyatı var. Çok düşük teklif sabrını tüketir; sabrı biterse 3 gün masaya dönmez.',
            style: TextStyle(color: AppColors.textFaint, fontSize: 11),
          ),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 820),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            left,
            const SizedBox(width: 16),
            Expanded(child: right),
          ],
        ),
      ),
    );
  }
}
