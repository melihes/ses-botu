import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../engine/game.dart';

/// İlk 100 listesindeki bir satır (gerçek oyuncular)
class OnlineRow {
  final int rank;
  final String uid;
  final String name;
  final double worth;
  final int level;
  OnlineRow(this.rank, this.uid, this.name, this.worth, this.level);
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
      }
    }
    if (signedIn) {
      if ((_game?.timeScale ?? 1) > 1) _game!.setTimeScale(1);
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
      if ((_game?.timeScale ?? 1) > 1) _game!.setTimeScale(1); // online'da hızlı zaman yok
      await _offerCloudSave();
      await sync(force: true);
      await refreshTop();
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      error = 'Giriş yapılamadı (${e.code.name}).';
      return error;
    } catch (e) {
      error = 'Giriş yapılamadı.';
      debugPrint('Giriş hatası: $e');
      return error;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
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
    if (g.timeScale > 1) {
      lastSyncNote = 'Test modunda (hızlı zaman) kayıt sıralamaya gönderilmez.';
      notifyListeners();
      return;
    }
    try {
      final res = await _fn.httpsCallable('submitSave').call({
        'save': g.exportSave(),
        'company': g.companyFullName,
      });
      final data = Map<String, dynamic>.from(res.data as Map);
      lastSync = DateTime.now();
      lastSyncNote = data['ok'] == true
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

  /// Oyun kapanırken son durumu gönder
  Future<void> onPause() => sync();

  String get displayName =>
      isGuest ? 'Misafir oyuncu' : (user?.displayName ?? user?.email ?? 'Oyuncu');

  /// Hata ayıklama için
  String debugState() => jsonEncode({'ready': ready, 'signedIn': signedIn});
}
