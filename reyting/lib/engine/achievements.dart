import 'package:flutter/material.dart';

import 'game.dart';

/// Başarım tanımı: koşul sağlanınca rozet ve elmas ödülü
class AchDef {
  final String id;
  final String title;
  final String desc;
  final IconData icon;
  final int reward;
  final bool Function(Game g) check;
  const AchDef(this.id, this.title, this.desc, this.icon, this.reward, this.check);
}

final achDefs = <AchDef>[
  AchDef('first_air', 'İlk yayın', 'Bir programı yayına koy.', Icons.live_tv_rounded, 2,
      (g) => g.shows.any((s) => s.totalRevenue > 0)),
  AchDef('rating5', 'Reyting %5', 'Bir programın %5 reytinge ulaşsın.', Icons.trending_up_rounded, 3,
      (g) => g.bestRating >= 5),
  AchDef('rating10', 'Çift hane', 'Bir programın %10 reytinge ulaşsın.', Icons.rocket_launch_rounded, 8,
      (g) => g.bestRating >= 10),
  AchDef('prime1', 'Prime time lideri', 'Reyting raporunda prime time birincisi ol.', Icons.emoji_events_rounded, 5,
      (g) => g.primeWins >= 1),
  AchDef('prime7', 'Prime time kralı', 'Prime time\'da 7 kez birinci ol.', Icons.workspace_premium_rounded, 10,
      (g) => g.primeWins >= 7),
  AchDef('film1', 'Yönetmen koltuğu', 'İlk filmini çek.', Icons.movie_rounded, 2,
      (g) => g.films.isNotEmpty),
  AchDef('film8', 'Başyapıt', '8 puan üstü bir film çek.', Icons.star_rounded, 8,
      (g) => g.films.any((f) => f.score >= 8)),
  AchDef('license3', 'Hak sahibi', 'Bir filmi 3 kez platformlara lisansla.', Icons.copyright_rounded, 4,
      (g) => g.films.any((f) => f.licensesSold >= 3)),
  AchDef('yt1m', 'Milyonluk YouTuber', 'Bir YouTuber\'ın 1 milyon takipçiye ulaşsın.', Icons.smart_display_rounded, 6,
      (g) => g.creators.any((c) => c.followers >= 1e6)),
  AchDef('sponsor', 'Marka dostu', 'Bir programa sponsor bul.', Icons.handshake_rounded, 2,
      (g) => g.sponsorDeals >= 1),
  AchDef('crisis', 'Kriz yöneticisi', '5 kriz kararı ver.', Icons.gavel_rounded, 3,
      (g) => g.decisionsMade >= 5),
  AchDef('yacht', 'Denizlerin hâkimi', 'Bir yat satın al.', Icons.sailing_rounded, 5,
      (g) => g.ownedLuxury.any((id) => id.startsWith('y'))),
  AchDef('island', 'Ada sahibi', 'Bir ada satın al.', Icons.landscape_rounded, 10,
      (g) => g.ownedLuxury.any((id) => id.startsWith('i'))),
  AchDef('channel', 'Kanal patronu', 'Bir rakip kanalı satın al.', Icons.connected_tv_rounded, 5,
      (g) => g.ownedChannels.isNotEmpty),
  AchDef('platform', 'Dijital dev', 'Bir dijital platform satın al.', Icons.play_circle_rounded, 8,
      (g) => g.ownedPlatforms.isNotEmpty),
  AchDef('holding5', 'Holding', '5 farklı işletme kur.', Icons.business_center_rounded, 6,
      (g) => g.bizLevels.values.where((v) => v > 0).length >= 5),
  AchDef('billion', 'İlk milyar', 'Kasanda 1 milyar ₺ olsun.', Icons.savings_rounded, 10,
      (g) => g.cash >= 1e9),
  AchDef('trophy', 'Altın Anten', 'Bir Altın Anten ödülü kazan.', Icons.military_tech_rounded, 5,
      (g) => g.trophies.isNotEmpty),
  AchDef('empire', 'Medya imparatoru', 'Stüdyoyu 6. seviyeye çıkar.', Icons.domain_rounded, 15,
      (g) => g.studioLevel >= 5),
  AchDef('global', 'Dünya sahnesi', 'Uluslararası genişlemeye başla (7. seviye).', Icons.public_rounded, 20,
      (g) => g.studioLevel >= 6),
  AchDef('legend', 'Efsanevi patron', 'Stüdyonun son seviyesine ulaş.', Icons.auto_awesome_rounded, 100,
      (g) => g.studioLevel >= 11),
  AchDef('trader', 'Borsacı', 'Borsada toplam 1 milyar ₺ kâr et.', Icons.candlestick_chart_rounded, 15,
      (g) => g.tradingProfit >= 1e9),
  AchDef('top100', 'İlk 100', 'Zenginler listesinde ilk 100\'e gir.', Icons.leaderboard_rounded, 30,
      (g) => g.richRank <= 100),
  AchDef('top10', 'İlk 10', 'Zenginler listesinde ilk 10\'a gir.', Icons.workspace_premium_rounded, 60,
      (g) => g.richRank <= 10),
  AchDef('top1', 'Bir numara', 'Zenginler listesinin zirvesine otur.', Icons.emoji_events_rounded, 200,
      (g) => g.richRank == 1),
];

