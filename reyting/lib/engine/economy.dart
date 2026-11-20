import 'dart:math';

import '../data/content.dart';
import '../models/models.dart';

/// Gerçek zamanda 1 oyun günü kaç saniye sürer.
const secondsPerDay = 60.0;

/// Çevrimdışı ilerleme üst sınırı (dakika).
const offlineCapMinutesFree = 30.0;
const offlineCapMinutesVip = 480.0;

/// Bir izleyicinin bir reklam dakikası başına getirdiği gelir (₺).
const adRatePerViewerMinute = 0.05;

const startingCash = 1500000.0;
const startingDiamonds = 25;

/// Yeteneğe göre günlük maaş.
double salaryFor(int skill) => 1500 + skill * skill * 3.0;

/// Program kalitesi (0..1.3): kadro yeteneği × bütçe × ekipman.
double showQuality(
    List<Staff> staff, Genre genre, int tier, Iterable<String> ownedEquip) {
  if (staff.isEmpty) return 0;
  final avg =
      staff.map((s) => s.skill).reduce((a, b) => a + b) / staff.length / 100;
  var bonus = 0.0;
  for (final id in ownedEquip) {
    final e = equipById(id);
    if (e == null || e.qualityBonus == 0) continue;
    if (e.boosts.isEmpty || e.boosts.contains(genre)) bonus += e.qualityBonus;
  }
  return (avg * budgetTiers[tier].qualityMult * (1 + bonus)).clamp(0.0, 1.3);
}

/// İzleyicinin tahammül ettiği reklam süresi: kaliteli program daha çok
/// reklamı kaldırır. Gelirin zirve yaptığı nokta tam bu değerdir.
double adTolerance(double quality) => 6 + 10 * quality;

/// Reklam süresine göre ekranda kalan izleyici oranı (0..1).
double adRetention(double adMinutes, double quality) {
  final t = adTolerance(quality);
  return exp(-0.5 * pow(adMinutes / t, 2));
}

/// Sezon ilerledikçe ilgi: dizi ortada zirve yapar, diğerleri yavaşça yorulur.
double freshness(Genre g, double progress) => g == Genre.dizi
    ? 0.9 + 0.25 * sin(pi * progress)
    : 1.05 - 0.15 * progress;

/// Reklamsız, ideal koşullardaki ham reyting (%).
double baseRating(double quality, Genre g) =>
    (1.5 + 16 * pow(quality, 1.4)) * genreDefs[g]!.ratingMult;

/// Programın o anki reytingi (%).
double showRating(Show s, SlotId slot, double adMinutes) {
  final fit = s.def.fit[slot] ?? 1.0;
  return baseRating(s.quality, s.genre) *
      fit *
      freshness(s.genre, s.seasonProgress) *
      s.noise *
      s.buff *
      adRetention(adMinutes, s.quality);
}

/// Reyting -> izleyici sayısı.
double viewersFor(double ratingPct, SlotId slot, double reach) =>
    slotDefs[slot]!.poolMillions * 1e6 * reach * ratingPct / 100;

/// Günlük reklam geliri.
double adRevenuePerDay(
        double viewers, double adMinutes, SlotId slot, double bonus) =>
    viewers * adMinutes * adRatePerViewerMinute * slotDefs[slot]!.adValue *
    (1 + bonus);

/// Prestij reklam fiyatlarını artırır (en fazla %30).
double prestigeAdBonus(int prestige) => min(prestige / 5000, 0.30);

double productionCost(Genre g, int tier) =>
    genreDefs[g]!.baseCost * budgetTiers[tier].costMult;

/// Kredi teklifleri (stüdyo seviyesine göre büyür).
class LoanOffer {
  final double amount;
  final int installments; // haftalık taksit sayısı
  final double interest; // toplam faiz oranı
  const LoanOffer(this.amount, this.installments, this.interest);
  double get installment => amount * (1 + interest) / installments;
}

List<LoanOffer> loanOffersFor(int level) {
  final scale = pow(3, level).toDouble();
  return [
    LoanOffer(500000 * scale, 4, 0.12),
    LoanOffer(1500000 * scale, 8, 0.20),
    LoanOffer(4000000 * scale, 12, 0.30),
  ];
}
