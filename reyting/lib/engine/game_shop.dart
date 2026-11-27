part of 'game.dart';

/// Reklam ödülleri ve mağaza paketleri (oyun içi kurallar).
/// Reklam ve ödeme altyapısı lib/core/ads.dart ve lib/core/shop.dart'tadır.
extension GameShop on Game {
  void _shopReset() {
    adBoosts.clear();
    lastAdDiscountDay = -999;
    adsWatched = 0;
    purchasedCash = 0;
    // noAds ve vip satın alındığı için yeni kariyerde de kalır
  }

  Map<String, dynamic> _shopToJson() => {
    'noAds': noAds,
    'adBoosts': adBoosts,
    'lastAdDiscountDay': lastAdDiscountDay,
    'adsWatched': adsWatched,
    'purchasedCash': purchasedCash,
    'lastGrantSeq': lastGrantSeq,
    'profileFrame': profileFrame,
    'careerStart': careerStart,
    'cloudUid': cloudUid,
    'grantedPurchases': grantedPurchases,
  };

  void _shopLoad(Map<String, dynamic> j) {
    noAds = j['noAds'] ?? false;
    adBoosts
      ..clear()
      ..addAll(Map<String, int>.from(j['adBoosts'] ?? {}));
    lastAdDiscountDay = j['lastAdDiscountDay'] ?? -999;
    adsWatched = j['adsWatched'] ?? 0;
    purchasedCash = (j['purchasedCash'] as num? ?? 0).toDouble();
    lastGrantSeq = j['lastGrantSeq'] as int? ?? lastGrantSeq;
    profileFrame = j['profileFrame'] as int? ?? 0;
    careerStart = (j['careerStart'] as num? ?? 0).toInt();
    cloudUid = j['cloudUid'] as String?;
    grantedPurchases
      ..clear()
      ..addAll(List<String>.from((j['grantedPurchases'] as List?) ?? const []));
  }

  /// Yönetici hesabı tamamen sildi: telefondaki kariyer de sıfırdan başlar
  Future<void> wipeAll() async {
    _newGame();
    // parayla alınan reklamsız/VIP korunur
    adBoosts.clear();
    adsWatched = 0;
    purchasedCash = 0;
    profileFrame = 0;
    cloudUid = null;
    await save();
    _notify('🗑️ Hesabın yönetici tarafından silindi. Yeni kariyer başladı.');
    _changed();
  }

  /// Yönetici panelinden gelen işlem (hediye, düzeltme, sıfırlama, mesaj)
  Future<void> applyAdminOp(Map<String, dynamic> op) async {
    double n(String k) => (op[k] as num? ?? 0).toDouble();
    switch (op['type']) {
      case 'give':
        final c = n('cash'), d = n('diamonds').round();
        cash += c;
        diamonds = max(0, diamonds + d);
        final parts = [
          if (c != 0) '${c > 0 ? '+' : ''}${fmtShort(c)}',
          if (d != 0) '${d > 0 ? '+' : ''}$d 💎',
        ];
        _notify('🎁 Yönetici hediyesi: ${parts.join(', ')}');
      case 'set':
        if (op['cash'] != null) cash = n('cash');
        if (op['diamonds'] != null) diamonds = max(0, n('diamonds').round());
        if (op['studioLevel'] != null) {
          studioLevel = n('studioLevel').round().clamp(0, studioLevels.length - 1);
        }
        _notify('🛠️ Hesabın yönetici tarafından güncellendi.');
      case 'vip':
        vip = op['vip'] == true;
        noAds = op['noAds'] == true || vip;
        _notify(vip ? '👑 VIP hesabına tanımlandı!' : '🛠️ Paket ayarların güncellendi.');
      case 'reset':
        final seq = lastGrantSeq;
        _newGame();
        lastGrantSeq = seq;
        _notify('🔄 Hesabın yönetici tarafından sıfırlandı. Yeni kariyer başladı.');
      case 'message':
        _notify('📩 ${op['text'] ?? ''}');
    }
    _changed();
  }

  /// Gelir ölçüsü: negatif ya da çok küçük olmasın
  double get _incomeScale => max(max(netPerDay, yesterdayIncome * 0.5), 100000.0);

  /// Ödüllü reklam parası: kasanın %5'i, ama en fazla 6 günlük kazanç
  /// (kasada çok para biriktiğinde reklamla oyun bozulmasın: saatte en fazla
  /// 2 reklam × 6 gün = 60 oyun gününün ~%20'si)
  double get adRewardAmount {
    final v = min(max(cash, 0.0) * 0.05, _incomeScale * 6);
    final r = max(25000.0, v);
    // okunaklı yuvarla
    final mag = pow(10, (log(r) / ln10).floor() - 1).toDouble();
    return (r / mag).round() * mag;
  }

  /// Reklam sonuna kadar izlendi: parayı ver
  void grantAdCash(double amount) {
    _cashIn(amount); // günlük gelir sayılmaz
    adsWatched++;
    _notify('🎁 Reklam ödülü: +${fmtShort(amount)}');
    _changed();
  }

  // ---- Reklamla hızlandırma (her yapım için en fazla 2 kez) ----
  static const adBoostLimit = 2;
  int adBoostsLeft(String id) => adBoostLimit - (adBoosts[id] ?? 0);

  String? adSpeedUpShow(Show s) {
    if (s.status != ShowStatus.producing) return 'Program çekimde değil.';
    if (adBoostsLeft(s.id) <= 0) return 'Bu yapım reklamla en fazla $adBoostLimit kez hızlanır.';
    adBoosts[s.id] = (adBoosts[s.id] ?? 0) + 1;
    s.prodLeft = max(0.0001, s.prodLeft - 1);
    adsWatched++;
    _advance(0.0002);
    _notify('⏩ "${s.name}" çekimi 1 gün hızlandı!');
    _changed();
    return null;
  }

  String? adSpeedUpFilm(Film f) {
    if (f.status != FilmStatus.producing) return 'Film çekimde değil.';
    if (adBoostsLeft(f.id) <= 0) return 'Bu film reklamla en fazla $adBoostLimit kez hızlanır.';
    adBoosts[f.id] = (adBoosts[f.id] ?? 0) + 1;
    f.prodLeft = max(0.0001, f.prodLeft - 1);
    adsWatched++;
    _advance(0.0002);
    _notify('⏩ "${f.name}" çekimi 1 gün hızlandı!');
    _changed();
    return null;
  }

  // ---- Reklamla %15 indirim (20 oyun gününde bir) ----
  static const adDiscount = 0.15;
  static const adDiscountEveryDays = 20;
  bool get adDiscountReady => day - lastAdDiscountDay >= adDiscountEveryDays;
  int get adDiscountWaitDays => max(0, adDiscountEveryDays - (day - lastAdDiscountDay));

  /// İndirimli alım yapıldıktan sonra çağrılır
  void useAdDiscount() {
    lastAdDiscountDay = day;
    adsWatched++;
    _changed();
  }

  // ---- Gerçek parayla alınan paketler ----
  /// Para paketinin vereceği tutar (oyuncunun büyüklüğüne göre)
  double moneyPackAmount(double mult) {
    final v = max(_incomeScale * mult, 1e6 * mult / 5);
    final mag = pow(10, (log(v) / ln10).floor() - 1).toDouble();
    return (v / mag).round() * mag;
  }

  /// Satın alma doğrulandıktan sonra ödülü ver
  void grantPurchase(String productId, {double? cashAmount}) {
    final d = productDiamonds[productId];
    if (d != null) {
      diamonds += d;
      _notify('💎 +$d elmas hesabına eklendi. Teşekkürler!');
    } else if (productMoney.containsKey(productId)) {
      final a = cashAmount ?? moneyPackAmount(productMoney[productId]!);
      _cashIn(a); // günlük gelir sayılmaz
      purchasedCash += a;
      _notify('💰 +${fmtShort(a)} kasana eklendi. Teşekkürler!');
    } else if (productId == productNoAds) {
      noAds = true;
      _notify('🚫 Reklamsız oyun açıldı. Teşekkürler!');
    } else if (productId == productVip) {
      vip = true;
      noAds = true;
      diamonds += 300;
      _notify('👑 VIP açıldı: 16 saat tam hızda çevrimdışı kazanç, reklamsız oyun, +300 💎');
    }
    _changed();
  }
}
