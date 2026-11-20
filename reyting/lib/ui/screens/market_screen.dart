import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/content.dart';
import '../../engine/game.dart';
import '../widgets/common.dart';

String _price(double p) => p >= 1000 ? fmtShort(p) : '${fmtDec(p, 2)} ₺';

double _change(Game g, String t) {
  final h = g.stockHist[t] ?? [];
  if (h.length < 2) return 0;
  final ref = h[max(0, h.length - 9)]; // ~1 gün önce
  return (g.priceOf(t) / ref - 1) * 100;
}

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final list = _tab == 0
        ? stockDefs
        : stockDefs.where((d) => game.holdings.containsKey(d.ticker)).toList();
    final unrealized = game.holdings.entries.fold(
        0.0, (a, e) => a + e.value * game.priceOf(e.key) - (game.costBasis[e.key] ?? 0));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Panel(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Expanded(child: StatBlock('Portföy', fmtShort(game.portfolioValue), color: AppColors.cyan)),
            Expanded(
                child: StatBlock('Açık kâr/zarar', fmtSigned(unrealized),
                    color: unrealized >= 0 ? AppColors.green : AppColors.red)),
            Expanded(
                child: StatBlock('Gerçekleşen kâr', fmtSigned(game.tradingProfit),
                    color: game.tradingProfit >= 0 ? AppColors.green : AppColors.red)),
            Expanded(
                flex: 2,
                child: Text(game.lastStockNews ?? 'Piyasalar sakin…',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.yellow))),
          ]),
        ),
        const SizedBox(height: 10),
        Row(children: [
          PillTabs(
            labels: ['Hisseler ${stockDefs.length}', 'Portföyüm ${game.holdings.length}'],
            selected: _tab,
            onChanged: (i) => setState(() => _tab = i),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
                'Fiyatlar her saat değişir, haberler sert hareket ettirir. Komisyon %0,3. '
                'Büyük alım-satımlar fiyatı oynatır.',
                style: TextStyle(color: AppColors.textDim, fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const Panel(
              child: Text('Henüz hissen yok. "Hisseler" sekmesinden al!',
                  style: TextStyle(color: AppColors.textDim))),
        AutoGrid(minItemWidth: 240, spacing: 8, children: [
          for (final d in list) _StockCard(d: d),
        ]),
      ],
    );
  }
}

class _StockCard extends StatelessWidget {
  final StockDef d;
  const _StockCard({required this.d});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final ch = _change(game, d.ticker);
    final up = ch >= 0;
    final own = game.holdings[d.ticker] ?? 0;
    return Panel(
      padding: const EdgeInsets.all(10),
      onTap: () => showTradeDialog(context, d),
      child: Row(children: [
        Container(width: 4, height: 54, color: d.color, margin: const EdgeInsets.only(right: 8)),
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(d.ticker,
                  style: TextStyle(color: d.color, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(d.sector.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textFaint, fontSize: 9, fontWeight: FontWeight.w800)),
              ),
            ]),
            Text(d.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            if (own > 0)
              Text('${fmtShort(own).replaceAll(' ₺', '')} lot',
                  style: const TextStyle(color: AppColors.cyan, fontSize: 11)),
          ]),
        ),
        Expanded(
          flex: 2,
          child: SizedBox(
              height: 40,
              child: Sparkline(game.stockHist[d.ticker] ?? const [], color: up ? AppColors.green : AppColors.red)),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(_price(game.priceOf(d.ticker)), style: const TextStyle(fontWeight: FontWeight.w900)),
          Tag('${up ? '+' : ''}${fmtPct(ch, 2)}', color: up ? AppColors.green : AppColors.red),
        ]),
      ]),
    );
  }
}

Future<void> showTradeDialog(BuildContext context, StockDef d) => showDialog(
      context: context,
      builder: (_) => Dialog(child: _Trade(d: d)),
    );

class _Trade extends StatefulWidget {
  final StockDef d;
  const _Trade({required this.d});
  @override
  State<_Trade> createState() => _TradeState();
}

class _TradeState extends State<_Trade> {
  double _pct = 0.25;
  bool _buy = true;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final t = widget.d.ticker;
    final price = game.priceOf(t);
    final own = game.holdings[t] ?? 0;
    final maxQ = _buy ? game.maxBuyable(t) : own;
    final qty = (maxQ * _pct).floorToDouble();
    final total = qty * price * (_buy ? 1.003 : 0.997);
    final ch = _change(game, t);
    final avg = own > 0 ? (game.costBasis[t] ?? 0) / own : 0.0;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 760),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${widget.d.ticker} · ${widget.d.name}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: widget.d.color)),
              Text(widget.d.sector, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                Text(_price(price), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(width: 8),
                Tag('${ch >= 0 ? '+' : ''}${fmtPct(ch, 2)} (1 gün)', color: ch >= 0 ? AppColors.green : AppColors.red),
              ]),
              const SizedBox(height: 6),
              SizedBox(
                  height: 120,
                  child: Sparkline(game.stockHist[t] ?? const [], color: ch >= 0 ? AppColors.green : AppColors.red)),
              const SizedBox(height: 6),
              Text(
                  'Piyasa değeri ${fmtShort(price * widget.d.shares)} · '
                  'elindeki ${fmtShort(own).replaceAll(' ₺', '')} lot'
                  '${own > 0 ? ' · ortalama maliyet ${_price(avg)}' : ''}',
                  style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 260,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              PillTabs(
                labels: const ['Al', 'Sat'],
                selected: _buy ? 0 : 1,
                onChanged: (i) => setState(() => _buy = i == 0),
              ),
              const SizedBox(height: 10),
              Text('${fmtShort(qty).replaceAll(' ₺', '')} lot',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              Text('${_buy ? 'Ödenecek' : 'Alınacak'}: ${fmtShort(total)}',
                  style: const TextStyle(color: AppColors.textDim)),
              Slider(value: _pct, min: 0, max: 1, divisions: 20, onChanged: (v) => setState(() => _pct = v)),
              Row(children: [
                for (final p in [0.1, 0.25, 0.5, 1.0])
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: GhostButton(p == 1 ? 'Tümü' : '%${(p * 100).round()}',
                        compact: true, color: AppColors.textDim, onTap: () => setState(() => _pct = p)),
                  ),
              ]),
              const SizedBox(height: 10),
              AccentButton(_buy ? 'Satın al' : 'Sat',
                  expand: true,
                  icon: _buy ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                  onTap: qty < 1
                      ? null
                      : () {
                          final err = _buy ? game.buyStock(t, qty) : game.sellStock(t, qty);
                          report(context, err);
                          if (err == null) {
                            game.showToast('${_buy ? '📈 Alındı' : '💰 Satıldı'}: '
                                '${fmtShort(qty).replaceAll(' ₺', '')} lot $t');
                          }
                        }),
              const SizedBox(height: 6),
              const Text('Bir şirketin en fazla %25\'ine sahip olabilirsin.',
                  style: TextStyle(color: AppColors.textFaint, fontSize: 11)),
            ]),
          ),
        ]),
      ),
    );
  }
}
