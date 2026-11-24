import 'package:flutter/material.dart';

import '../../core/ads.dart';
import '../../core/format.dart';
import '../../core/monetization_config.dart';
import '../../core/shop.dart';
import '../../core/theme.dart';
import '../../engine/game.dart';
import '../widgets/common.dart';

/// Ödüllü reklam izlet; ödül sadece reklam sonuna kadar izlenirse verilir.
Future<bool> watchAd(BuildContext context, {bool fromOffer = false}) async {
  final game = GameScope.read(context);
  if (!Ads.instance.rewardedReady) {
    game.showToast('📺 Reklam hazırlanıyor, biraz sonra tekrar dene.');
    return false;
  }
  final ok = await Ads.instance.showRewarded(fromOffer: fromOffer);
  if (!ok) game.showToast('Reklam sonuna kadar izlenmedi, ödül verilmedi.');
  return ok;
}

Future<void> showShopDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const Dialog(child: _ShopBody()),
    );

class _ShopBody extends StatelessWidget {
  const _ShopBody();

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([Shop.instance, Ads.instance]),
      builder: (context, _) {
        final shop = Shop.instance;
        String price(String id) => shop.products[id]?.price ?? '—';
        bool can(String id) => shop.available && shop.products.containsKey(id);
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760, maxHeight: 520),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.storefront_rounded, color: AppColors.accent),
                const SizedBox(width: 8),
                const Text('Mağaza', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const Spacer(),
                Tag('💎 ${game.diamonds}', color: AppColors.cyan),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
              if (shop.message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(shop.message!, style: const TextStyle(color: AppColors.yellow, fontSize: 12)),
                ),
              if (!shop.loading && (!shop.available || shop.products.isEmpty))
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text(
                      'Ücretli ürünler Google Play üzerinden yüklenen sürümde açılır.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                ),
              Expanded(
                child: ListView(children: [
                  const SectionLabel('Ücretsiz', color: AppColors.green),
                  const SizedBox(height: 6),
                  _Row(
                    icon: Icons.ondemand_video_rounded,
                    color: AppColors.green,
                    title: 'Reklam izle, ${fmtShort(game.adRewardAmount)} kazan',
                    sub: 'Kısa bir reklam izle, kasana para eklensin.',
                    action: 'İzle',
                    enabled: Ads.instance.rewardedReady,
                    onTap: () async {
                      final amount = game.adRewardAmount;
                      if (await watchAd(context, fromOffer: true)) game.grantAdCash(amount);
                    },
                  ),
                  const SizedBox(height: 12),
                  const SectionLabel('Elmas', color: AppColors.cyan),
                  const SizedBox(height: 6),
                  for (final e in productDiamonds.entries)
                    _Row(
                      icon: Icons.diamond_rounded,
                      color: AppColors.cyan,
                      title: '${e.value} elmas',
                      sub: 'Çekim hızlandır, aday yenile, gözlemci gönder.',
                      action: price(e.key),
                      enabled: can(e.key),
                      onTap: () => shop.buy(e.key),
                    ),
                  const SizedBox(height: 12),
                  const SectionLabel('Oyun parası', color: AppColors.yellow),
                  const SizedBox(height: 6),
                  for (final e in productMoney.entries)
                    _Row(
                      icon: Icons.payments_rounded,
                      color: AppColors.yellow,
                      title: '${fmtShort(game.moneyPackAmount(e.value))} oyun parası',
                      sub: 'Tutar şirketin büyüdükçe artar (${e.value.round()} günlük kazanç).',
                      action: price(e.key),
                      enabled: can(e.key),
                      onTap: () => shop.buy(e.key),
                    ),
                  const SizedBox(height: 12),
                  const SectionLabel('Özel', color: AppColors.accent),
                  const SizedBox(height: 6),
                  _Row(
                    icon: Icons.block_rounded,
                    color: AppColors.orange,
                    title: game.noAds ? 'Reklamsız ✓' : 'Reklamsız oyun',
                    sub: 'Araya giren reklamlar kalkar (ödüllü reklamları istersen izlemeye devam edersin).',
                    action: game.noAds ? 'Alındı' : price(productNoAds),
                    enabled: !game.noAds && can(productNoAds),
                    onTap: () => shop.buy(productNoAds),
                  ),
                  _Row(
                    icon: Icons.workspace_premium_rounded,
                    color: AppColors.accent,
                    title: game.vip ? 'VIP ✓' : 'VIP paket',
                    sub: 'Çevrimdışı 16 saat tam hızda kazanç, reklamsız oyun, +300 💎.',
                    action: game.vip ? 'Alındı' : price(productVip),
                    enabled: !game.vip && can(productVip),
                    onTap: () => shop.buy(productVip),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GhostButton('Satın alımları geri yükle',
                        compact: true, icon: Icons.restore_rounded, onTap: shop.restore),
                  ),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, sub, action;
  final bool enabled;
  final VoidCallback onTap;
  const _Row({
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
    required this.action,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Panel(
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(sub, style: const TextStyle(color: AppColors.textDim, fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 8),
            AccentButton(action, compact: true, onTap: enabled ? onTap : null),
          ]),
        ),
      );
}

/// Köşede kendiliğinden çıkan, kapatılabilir ödüllü reklam teklifi
class RewardOfferCard extends StatelessWidget {
  const RewardOfferCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Ads.instance,
      builder: (context, _) {
        if (!Ads.instance.offerVisible) return const SizedBox.shrink();
        final game = GameScope.of(context);
        final amount = game.adRewardAmount;
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (_, v, child) => Transform.scale(scale: v, child: child),
          child: Container(
            width: 300,
            padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
            decoration: BoxDecoration(
              color: const Color(0xF51E182B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.green.withValues(alpha: 0.8)),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 12)],
            ),
            child: Row(children: [
              const Text('🎁', style: TextStyle(fontSize: 26)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Text('+${fmtShort(amount)}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.green, fontSize: 16)),
                  const Text('Kısa bir reklam izle, kasana eklensin',
                      style: TextStyle(color: AppColors.textDim, fontSize: 11)),
                ]),
              ),
              AccentButton('İzle', compact: true, onTap: () async {
                if (await watchAd(context, fromOffer: true)) game.grantAdCash(amount);
              }),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Kapat',
                onPressed: Ads.instance.dismissOffer,
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textDim),
              ),
            ]),
          ),
        );
      },
    );
  }
}
