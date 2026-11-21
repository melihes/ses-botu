import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';

/// Online özelliklerin tanıtım ekranı (Aşama 3-4'te gerçek olacak)
class OnlineScreen extends StatelessWidget {
  const OnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        Icons.gavel_rounded,
        AppColors.accent,
        'Canlı transfer ihalesi',
        'Yıldız oyuncu ve yönetmenler tüm oyuncuların teklif verdiği süreli açık artırmaya düşer. Teklifin bloke edilir, geçilirse iade edilir.',
      ),
      (
        Icons.leaderboard_rounded,
        AppColors.cyan,
        'Prime Time Ligi',
        'Aynı kuşakta yayınlanan programların reytingleri haftalık karşılaştırılır. Sezon sonunda ödüller!',
      ),
      (
        Icons.storefront_rounded,
        AppColors.yellow,
        'Format pazarı',
        'Başarılı program formatını diğer oyunculara sat ya da onlarınkini satın al.',
      ),
      (
        Icons.handshake_rounded,
        AppColors.green,
        'Ortak yapım',
        'Başka bir kanalla güçlerini birleştir, büyük bütçeli yapımları birlikte çek.',
      ),
      (
        Icons.emoji_events_rounded,
        AppColors.purple,
        'Liderlik tablosu',
        'En zengin, en prestijli ve en çok izlenen kanallar.',
      ),
      (
        Icons.flight_takeoff_rounded,
        AppColors.orange,
        'Yurt dışına dizi satışı',
        'Dizilerini başka ülkelerin kanallarına sat, döviz değil ₺ kazan.',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const PageHint(
          'Online arena yakında! Tüm ihale, lig ve ekonomi hesapları hile '
          'yapılamasın diye sunucuda yapılacak.',
        ),
        AutoGrid(
          minItemWidth: 300,
          spacing: 10,
          children: [
            for (final it in items)
              Panel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ArtTile(icon: it.$1, color: it.$2, size: 64),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.$3,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Tag('YAKINDA', color: AppColors.textDim),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            it.$4,
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
