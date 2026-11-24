// Para kazanma ayarları. AdMob ve Play Console'dan gelen kimlikler buraya yazılır.
// Gerçek kimlikler gelene kadar Google'ın resmi TEST reklamları kullanılır
// (test reklamıyla para kazanılmaz ama hesap da cezalandırılmaz).

/// true: test reklamları. Gerçek AdMob kimlikleri girilince false yapılır.
const useTestAds = true;

// Google'ın resmi test kimlikleri (herkes kullanabilir)
const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

// AdMob'dan alınacak gerçek reklam birimi kimlikleri
const _realRewarded = 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
const _realInterstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZ';

String get rewardedUnitId => useTestAds ? _testRewarded : _realRewarded;
String get interstitialUnitId => useTestAds ? _testInterstitial : _realInterstitial;

// ---- Reklam sıklığı (oyuncuyu bunaltmayacak şekilde) ----
/// Ödüllü reklam teklifi: aktif oyunda en erken kaç dakikada bir çıkar
const rewardOfferMinMinutes = 12;
const rewardOfferMaxMinutes = 20;

/// Ödüllü reklam izlendikten sonra yeni teklif için bekleme
const rewardCooldownMinutes = 30;

/// Geçiş reklamı: aktif oyunda kaç dakikada bir (sayfa değişirken)
const interstitialMinutes = 32;

// ---- Mağaza ürünleri (Play Console'da aynı kimliklerle açılır) ----
const productDiamonds = {
  'elmas_80': 80,
  'elmas_450': 450,
  'elmas_1000': 1000,
  'elmas_2500': 2500,
};

/// Para paketleri: verilen para oyuncunun günlük kazancının kaç katı
const productMoney = {
  'para_kucuk': 5.0,
  'para_orta': 20.0,
  'para_buyuk': 60.0,
};

const productNoAds = 'reklamsiz';
const productVip = 'vip_paket';

Set<String> get allProductIds => {
      ...productDiamonds.keys,
      ...productMoney.keys,
      productNoAds,
      productVip,
    };
