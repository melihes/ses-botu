import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../engine/game.dart';
import 'ads.dart';
import 'cloud.dart';
import 'monetization_config.dart';

/// Gerçek parayla satın alma (Google Play Faturalandırma).
/// Ödül, satın alma SUNUCUDA Google'a sorulup doğrulandıktan sonra verilir;
/// böylece sahte satın alma ile para/elmas basılamaz.
class Shop extends ChangeNotifier {
  Shop._();
  static final Shop instance = Shop._();

  bool available = false;
  bool loading = true;
  final Map<String, ProductDetails> products = {};
  String? message;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  Game? _game;

  Future<void> init(Game game) async {
    _game = game;
    Ads.instance.noInterstitials = game.noAds;
    try {
      final iap = InAppPurchase.instance;
      available = await iap.isAvailable();
      if (available) {
        _sub ??= iap.purchaseStream.listen(_onPurchases, onError: (e) {
          message = 'Satın alma hatası.';
          notifyListeners();
        });
        final res = await iap.queryProductDetails(allProductIds);
        products
          ..clear()
          ..addEntries(res.productDetails.map((p) => MapEntry(p.id, p)));
      }
    } catch (e) {
      debugPrint('Mağaza açılamadı: $e');
      available = false;
    }
    loading = false;
    notifyListeners();
  }

  /// Telefon değişince "Reklamsız"/"VIP" geri yüklensin
  Future<void> restore() async {
    if (!available) return;
    await InAppPurchase.instance.restorePurchases();
  }

  bool isConsumable(String id) => productDiamonds.containsKey(id) || productMoney.containsKey(id);

  Future<void> buy(String id) async {
    final p = products[id];
    if (!available || p == null) {
      message = 'Bu ürün şu an satın alınamıyor.';
      notifyListeners();
      return;
    }
    message = null;
    final param = PurchaseParam(productDetails: p);
    if (isConsumable(id)) {
      await InAppPurchase.instance.buyConsumable(purchaseParam: param);
    } else {
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: param);
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    final g = _game;
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          message = 'Ödeme bekleniyor…';
        case PurchaseStatus.error:
          message = 'Satın alma tamamlanamadı.';
        case PurchaseStatus.canceled:
          message = null;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (g == null) break;
          final money = productMoney[p.productID];
          final cash = money == null ? null : g.moneyPackAmount(money);
          final ok = await Cloud.instance.verifyPurchase(
            productId: p.productID,
            token: p.verificationData.serverVerificationData,
            cashAmount: cash,
          );
          if (ok == null) {
            // sunucuya ulaşılamadı: satın alma bekletilir, sonra tekrar denenir
            message = 'Satın alma doğrulanamadı; internet gelince tekrar denenecek.';
            notifyListeners();
            continue;
          }
          // aynı satın alma tekrar gelirse (uygulama yarıda kapandıysa) iki kez verilmesin
          final pid = p.purchaseID ?? p.verificationData.serverVerificationData;
          if (ok && g.grantedPurchases.contains(pid)) {
            message = null;
          } else if (ok) {
            if (p.status == PurchaseStatus.restored) {
              // geri yüklemede sadece kalıcı haklar (elmas tekrar verilmez)
              if (p.productID == productNoAds) g.noAds = true;
              if (p.productID == productVip) {
                g.vip = true;
                g.noAds = true;
              }
            } else {
              g.grantPurchase(p.productID, cashAmount: cash);
            }
            g.grantedPurchases.add(pid);
            if (g.grantedPurchases.length > 40) g.grantedPurchases.removeAt(0);
            await g.save();
            Ads.instance.noInterstitials = g.noAds;
            message = null;
          } else {
            message = 'Satın alma Google tarafından onaylanmadı.';
          }
      }
      if (p.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(p);
      }
    }
    notifyListeners();
  }
}
