import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'monetization_config.dart';

/// Reklamlar: ödüllü reklam (oyuncu isterse izler, ödül alır) ve
/// seyrek geçiş reklamı. Rıza (KVKK/GDPR) formu Google'ın UMP aracıyla.
class Ads extends ChangeNotifier {
  Ads._();
  static final Ads instance = Ads._();

  bool _ready = false;
  RewardedAd? _rewarded;
  InterstitialAd? _interstitial;
  bool _loadingRewarded = false;
  bool _loadingInterstitial = false;

  /// "Reklamsız" ya da VIP paketi alındıysa geçiş reklamı yok
  bool noInterstitials = false;

  /// Aktif oyun süresi (saniye): reklam zamanlaması gerçek oynamaya göre
  int _activeSeconds = 0;
  int _nextOfferAt = 0;
  int _nextInterstitialAt = interstitialMinutes * 60;
  Timer? _clock;
  final _rng = Random();

  /// Ekranda ödüllü reklam teklifi var mı
  bool offerVisible = false;

  bool get rewardedReady => _rewarded != null;

  Future<void> init() async {
    try {
      await _consent();
      await MobileAds.instance.initialize();
      _ready = true;
      _loadRewarded();
      _loadInterstitial();
    } catch (e) {
      debugPrint('Reklamlar başlatılamadı: $e');
    }
    _nextOfferAt = _minutesRandom();
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _consent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        if (!done.isCompleted) done.complete();
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(const Duration(seconds: 8), onTimeout: () {});
  }

  int _minutesRandom() =>
      _activeSeconds +
      (rewardOfferMinMinutes + _rng.nextInt(rewardOfferMaxMinutes - rewardOfferMinMinutes + 1)) * 60;

  bool _paused = false;
  void pause(bool p) => _paused = p;

  void _tick() {
    if (_paused) return;
    _activeSeconds++;
    if (!offerVisible && _activeSeconds >= _nextOfferAt && rewardedReady) {
      offerVisible = true;
      notifyListeners();
      // 40 sn içinde dokunulmazsa kendiliğinden kapanır
      Future.delayed(const Duration(seconds: 40), () {
        if (offerVisible) dismissOffer();
      });
    }
  }

  void dismissOffer() {
    offerVisible = false;
    _nextOfferAt = _minutesRandom();
    notifyListeners();
  }

  void _loadRewarded() {
    if (!_ready || _loadingRewarded || _rewarded != null) return;
    _loadingRewarded = true;
    RewardedAd.load(
      adUnitId: rewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          _loadingRewarded = false;
          notifyListeners();
        },
        onAdFailedToLoad: (e) {
          _loadingRewarded = false;
          // bir süre sonra tekrar dene
          Future.delayed(const Duration(seconds: 60), _loadRewarded);
        },
      ),
    );
  }

  void _loadInterstitial() {
    if (!_ready || noInterstitials || _loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: interstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (e) {
          _loadingInterstitial = false;
          Future.delayed(const Duration(seconds: 90), _loadInterstitial);
        },
      ),
    );
  }

  /// Ödüllü reklamı göster. Ödül sadece reklam sonuna kadar izlenirse verilir.
  /// [fromOffer]: kendiliğinden çıkan tekliften mi geldi (30 dk bekleme başlar)
  Future<bool> showRewarded({bool fromOffer = false}) async {
    final ad = _rewarded;
    if (ad == null) {
      _loadRewarded();
      return false;
    }
    _rewarded = null;
    final result = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadRewarded();
        if (!result.isCompleted) result.complete(false);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    final ok = await result.future;
    if (fromOffer) {
      offerVisible = false;
      _nextOfferAt = _activeSeconds + rewardCooldownMinutes * 60;
    }
    // reklam izlendiyse geçiş reklamını da ertele (üst üste reklam olmasın)
    _nextInterstitialAt = max(_nextInterstitialAt, _activeSeconds + 10 * 60);
    notifyListeners();
    return ok;
  }

  /// Sayfa değişirken çağrılır: süresi geldiyse geçiş reklamı gösterir
  void maybeInterstitial() {
    if (noInterstitials || _activeSeconds < _nextInterstitialAt) return;
    final ad = _interstitial;
    if (ad == null) {
      _loadInterstitial();
      return;
    }
    _interstitial = null;
    _nextInterstitialAt = _activeSeconds + (interstitialMinutes + _rng.nextInt(4)) * 60;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        a.dispose();
        _loadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (a, e) {
        a.dispose();
        _loadInterstitial();
      },
    );
    ad.show();
  }

  /// Gizlilik ayarlarını yeniden açma (ayarlar ekranından)
  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((_) {});
  }
}
