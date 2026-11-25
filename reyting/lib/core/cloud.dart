import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../engine/game.dart';
import 'ads.dart';

/// İlk 100 listesindeki bir satır (gerçek oyuncular)
class OnlineRow {
  final int rank;
  final String uid;
  final String name;
  final double worth;
  final int level;
  final int frame;
  OnlineRow(this.rank, this.uid, this.name, this.worth, this.level, [this.frame = 0]);
}

/// Online bağlantı: Google ile giriş, bulut kaydı, zenginler listesi.
/// Oyun çevrimdışı da tam oynanır; bunlar ek özelliklerdir.
class Cloud extends ChangeNotifier {
  Cloud._();
  static final Cloud instance = Cloud._();

  /// Firebase konsolundaki "web istemci" kimliği (Google girişi için)
  static const _webClientId =
      '198787500188-ao82butiqjekbjb25eee562ipgg7jps0.apps.googleusercontent.com';

  bool ready = false; // Firebase başlatıldı mı
  bool busy = false;
  String? error;
  User? user;
  DateTime? lastSync;
  String? lastSyncNote;
  List<OnlineRow> top = [];
  int totalPlayers = 0;
  int? myRank;
  DateTime? topUpdated;
  Timer? _timer;
  Game? _game;

  bool get signedIn => user != null;

  /// Hata metnini ekranda okunur uzunlukta göster (teşhis için)
  static String _short(Object e) {
    final t = e.toString().replaceAll('\n', ' ');
    return t.length > 180 ? '${t.substring(0, 180)}…' : t;
  }

  /// Bu kariyer neden sıralamaya giremiyor (null: giriyor)
  String? unverifiedReason;

  /// Sıralamaya temiz girmek için oyunu baştan başlat
  Future<void> startFreshCareer() async {
    final g = _game;
    if (g == null) return;
    await g.resetGame();
    unverifiedReason = null;
    await sync(force: true);
    await refreshTop();
  }

  /// Misafir (anonim) hesap: Google'a bağlanmadıysa
  bool get isGuest => user?.isAnonymous ?? false;

  late final FirebaseFunctions _fn =
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      await GoogleSignIn.instance.initialize(serverClientId: _webClientId);
      user = FirebaseAuth.instance.currentUser;
      ready = true;
    } catch (e) {
      debugPrint('Firebase başlatılamadı: $e');
      error = 'Online sistem başlatılamadı: ${_short(e)}';
      ready = false;
    }
    notifyListeners();
  }

  /// Oyun açıldıktan sonra: 5 dakikada bir buluta kaydet
  void attach(Game game) {
    _game = game;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 5), (_) => sync());
    if (signedIn) {
      _listenGrants();
      sync();
      refreshTop();
    } else {
      autoSignIn();
    }
  }

  /// Açılışta otomatik giriş: önce sessiz/tek dokunuş Google, olmazsa misafir.
  /// Oyuncu hiçbir düğmeye basmadan online olur.
  Future<void> autoSignIn() async {
    if (!ready || signedIn) return;
    try {
      final acc = await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (acc != null) {
        await _firebaseWithGoogle(acc);
      }
    } catch (e) {
      debugPrint('Sessiz giriş olmadı: $e');
    }
    if (!signedIn) {
      try {
        final res = await FirebaseAuth.instance.signInAnonymously();
        user = res.user;
      } catch (e) {
        debugPrint('Misafir giriş olmadı: $e');
        error = 'Misafir giriş olmadı: ${_short(e)}';
      }
    }
    if (signedIn) {
      _listenGrants();
      await _offerCloudSave();
      await sync(force: true);
      await refreshTop();
    }
    notifyListeners();
  }

  /// Google hesabıyla Firebase'e gir; misafirsen hesabını Google'a bağla
  Future<void> _firebaseWithGoogle(GoogleSignInAccount acc) async {
    final cred = GoogleAuthProvider.credential(idToken: acc.authentication.idToken);
    final cur = FirebaseAuth.instance.currentUser;
    if (cur != null && cur.isAnonymous) {
      try {
        final res = await cur.linkWithCredential(cred);
        user = res.user;
        return;
      } on FirebaseAuthException catch (e) {
        // bu Google hesabı zaten başka bir oyuncu kaydına bağlı: ona geç
        if (e.code != 'credential-already-in-use') rethrow;
      }
    }
    final res = await FirebaseAuth.instance.signInWithCredential(cred);
    user = res.user;
  }

  Future<String?> signIn() async {
    if (!ready) return 'Online sistem şu an kullanılamıyor.';
    busy = true;
    error = null;
    notifyListeners();
    try {
      final acc = await GoogleSignIn.instance.authenticate();
      await _firebaseWithGoogle(acc);
      _listenGrants();
      await _offerCloudSave();
      await sync(force: true);
      await refreshTop();
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      error = 'Giriş yapılamadı (${e.code.name}): ${_short(e.description ?? '')}';
      return error;
    } catch (e) {
      error = 'Giriş yapılamadı: ${_short(e)}';
      debugPrint('Giriş hatası: $e');
      return error;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  // ------------------------------------------------------------------
  // Yöneticiden gelen hediye ve düzeltmeler (anında uygulanır)
  // ------------------------------------------------------------------
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _grantSub;
  String? _grantUid;

  void _listenGrants() {
    final u = user;
    if (u == null || _grantUid == u.uid) return;
    _grantSub?.cancel();
    _grantUid = u.uid;
    _grantSub = FirebaseFirestore.instance
        .collection('grants')
        .doc(u.uid)
        .snapshots()
        .listen(_onGrants, onError: (e) => debugPrint('Hediye dinlenemedi: $e'));
  }

  Future<void> _onGrants(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final g = _game;
    final ops = snap.data()?['ops'];
    if (g == null || ops is! List || ops.isEmpty) return;
    var maxSeq = g.lastGrantSeq;
    var applied = false;
    for (final o in ops) {
      if (o is! Map) continue;
      final op = Map<String, dynamic>.from(o);
      final seq = (op['seq'] as num? ?? 0).toInt();
      if (seq <= g.lastGrantSeq) continue;
      if (op['type'] == 'load') {
        await _loadCloudSaveNow();
      } else {
        await g.applyAdminOp(op);
      }
      maxSeq = max(maxSeq, seq);
      applied = true;
    }
    if (!applied) return;
    g.lastGrantSeq = maxSeq;
    Ads.instance.noInterstitials = g.noAds;
    await g.save();
    try {
      await _fn.httpsCallable('ackGrants').call({'seq': maxSeq});
    } catch (_) {}
    await sync(force: true);
    notifyListeners();
  }

  Future<void> _loadCloudSaveNow() async {
    final u = user, g = _game;
    if (u == null || g == null) return;
    final doc = await FirebaseFirestore.instance.collection('players').doc(u.uid).get();
    final raw = doc.data()?['save'];
    if (raw is String) {
      final seq = g.lastGrantSeq;
      await g.importSave(raw);
      g.lastGrantSeq = max(seq, g.lastGrantSeq);
      g.showToast('☁️ Hesabın bu cihaza taşındı.');
    }
  }

  // ------------------------------------------------------------------
  // Telefon değiştirme: taşıma kodu
  // ------------------------------------------------------------------
  /// Eski cihazda: 24 saat geçerli kod
  Future<(String?, String?)> createTransferCode() async {
    if (!signedIn) await autoSignIn();
    if (!signedIn) return (null, 'Önce internete bağlan.');
    try {
      await sync(force: true);
      final res = await _fn.httpsCallable('createTransferCode').call();
      return ((res.data as Map)['code'] as String?, null);
    } on FirebaseFunctionsException catch (e) {
      return (null, e.message ?? 'Kod alınamadı.');
    } catch (e) {
      return (null, 'Kod alınamadı, internet bağlantını kontrol et.');
    }
  }

  /// Yeni cihazda: kodu gir, eski hesabın kaydı gelsin
  Future<String?> redeemTransferCode(String code) async {
    if (!signedIn) await autoSignIn();
    if (!signedIn) return 'Önce internete bağlan.';
    final g = _game;
    if (g == null) return 'Oyun hazır değil.';
    try {
      busy = true;
      notifyListeners();
      final res = await _fn.httpsCallable('redeemTransferCode').call({'code': code});
      final raw = (res.data as Map)['save'];
      if (raw is! String) return 'Kayıt gelmedi.';
      await g.importSave(raw);
      cloudSaveRaw = null;
      await sync(force: true);
      await refreshTop();
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Kod kullanılamadı.';
    } catch (e) {
      return 'Kod kullanılamadı, internet bağlantını kontrol et.';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _grantSub?.cancel();
    _grantSub = null;
    _grantUid = null;
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.signOut();
    user = null;
    myRank = null;
    notifyListeners();
  }

  /// Buluttaki kayıt, telefondakinden daha ilerideyse onu yükleme fırsatı
  String? cloudSaveRaw;
  int? cloudDay;

  Future<void> _offerCloudSave() async {
    final u = user;
    if (u == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('players').doc(u.uid).get();
      final raw = doc.data()?['save'];
      if (raw is String) {
        cloudSaveRaw = raw;
        cloudDay = (doc.data()?['day'] as num?)?.toInt();
      }
    } catch (e) {
      debugPrint('Bulut kaydı okunamadı: $e');
    }
  }

  /// Buluttaki kaydı telefona yükle
  Future<void> restoreCloud() async {
    final raw = cloudSaveRaw;
    final g = _game;
    if (raw == null || g == null) return;
    await g.importSave(raw);
    cloudSaveRaw = null;
    notifyListeners();
  }

  void dismissCloud() {
    cloudSaveRaw = null;
    notifyListeners();
  }

  /// Kaydı sunucuya gönder (sunucu hile kontrolü yapar, sıralamayı günceller)
  Future<void> sync({bool force = false}) async {
    final g = _game;
    if (!signedIn || g == null || busy && !force) return;
    if (cloudSaveRaw != null) return; // önce bulut/telefon seçimi yapılmalı
    _listenGrants();
    try {
      final res = await _fn.httpsCallable('submitSave').call({
        'save': g.exportSave(),
        'company': g.companyFullName,
        'frame': g.profileFrame,
        'stats': {
          'prestige': g.prestige,
          'shows': g.shows.length,
          'staff': g.staff.length,
          'films': g.films.length,
          'netPerDay': g.netPerDay,
        },
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      lastSync = DateTime.now();
      unverifiedReason = data['unverified'] == true ? data['reason'] as String? : null;
      lastSyncNote = data['unverified'] == true
          ? 'Yedeklendi, ama bu kariyer sıralamaya girmiyor.'
          : data['ok'] == true
          ? (data['skipped'] == true ? 'Az önce kaydedildi.' : 'Buluta kaydedildi.')
          : 'Kayıt reddedildi: ${data['reason']}';
    } catch (e) {
      lastSyncNote = 'Bağlantı yok, sonra tekrar denenecek.';
      debugPrint('Senkron hatası: $e');
    }
    notifyListeners();
  }

  /// Gerçek oyuncularla ilk 100 ve senin sıran
  Future<void> refreshTop() async {
    if (!signedIn) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('meta').doc('top100').get();
      final d = doc.data();
      if (d != null) {
        top = [
          for (final r in (d['rows'] as List? ?? []))
            OnlineRow(
              (r['rank'] as num).toInt(),
              r['uid'] as String,
              r['name'] as String,
              (r['worth'] as num).toDouble(),
              (r['level'] as num).toInt(),
              (r['frame'] as num? ?? 0).toInt(),
            ),
        ];
        totalPlayers = (d['total'] as num? ?? 0).toInt();
        topUpdated = (d['updatedAt'] as Timestamp?)?.toDate();
      }
      final me = await FirebaseFirestore.instance.collection('leaderboard').doc(user!.uid).get();
      final w = (me.data()?['worth'] as num?)?.toDouble();
      if (w != null) {
        final above = await FirebaseFirestore.instance
            .collection('leaderboard')
            .where('worth', isGreaterThan: w)
            .count()
            .get();
        myRank = (above.count ?? 0) + 1;
      }
    } catch (e) {
      debugPrint('Sıralama okunamadı: $e');
    }
    notifyListeners();
  }

  /// Satın almayı sunucuda Google'a doğrulatır.
  /// true: geçerli, false: geçersiz, null: şu an doğrulanamadı (sonra tekrar)
  Future<bool?> verifyPurchase({
    required String productId,
    required String token,
    double? cashAmount,
  }) async {
    if (!signedIn) await autoSignIn();
    if (!signedIn) return null;
    try {
      final res = await _fn.httpsCallable('verifyPurchase').call({
        'productId': productId,
        'token': token,
        'cash': cashAmount ?? 0,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      return data['ok'] == true;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied' || e.code == 'invalid-argument') return false;
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Hesabı ve sunucudaki tüm verileri kalıcı olarak siler
  Future<String?> deleteAccount() async {
    if (!signedIn) return 'Giriş yapılmamış.';
    try {
      await _fn.httpsCallable('deleteAccount').call();
      await FirebaseAuth.instance.signOut();
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
      user = null;
      myRank = null;
      top = [];
      notifyListeners();
      return null;
    } catch (e) {
      return 'Hesap silinemedi, internet bağlantını kontrol et.';
    }
  }

  /// Oyun kapanırken son durumu gönder
  Future<void> onPause() => sync();

  String get displayName =>
      isGuest ? 'Misafir oyuncu' : (user?.displayName ?? user?.email ?? 'Oyuncu');

  /// Hata ayıklama için
  String debugState() => jsonEncode({'ready': ready, 'signedIn': signedIn});
}
