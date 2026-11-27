import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../engine/game.dart';

/// Çökme raporu (Crashlytics) ve kullanım istatistikleri (Analytics).
/// Kişisel veri gönderilmez: sadece olay adları ve sayılar.
class Telemetry {
  static FirebaseAnalytics? _a;
  static bool _ready = false;

  /// Firebase başlatıldıktan sonra çağrılır
  static Future<void> init() async {
    if (_ready) return;
    try {
      final c = FirebaseCrashlytics.instance;
      // geliştirme sırasında rapor gönderme
      await c.setCrashlyticsCollectionEnabled(!kDebugMode);
      final prev = FlutterError.onError;
      FlutterError.onError = (d) {
        c.recordFlutterError(d);
        prev?.call(d);
      };
      PlatformDispatcher.instance.onError = (e, st) {
        c.recordError(e, st, fatal: true);
        return true;
      };
      _a = FirebaseAnalytics.instance;
      // oyun motorundaki önemli anlar
      Game.onEvent = log;
      _ready = true;
    } catch (e) {
      debugPrint('Telemetri başlatılamadı: $e');
    }
  }

  static void log(String name, [Map<String, Object>? p]) {
    try {
      _a?.logEvent(name: name, parameters: p);
    } catch (_) {}
  }

  static void screen(String name) {
    try {
      _a?.logScreenView(screenName: name);
    } catch (_) {}
  }

  /// Çökme raporunda hangi oyun durumu olduğu görünsün (kişisel bilgi yok)
  static void context(Game g) {
    try {
      final c = FirebaseCrashlytics.instance;
      c.setCustomKey('gun', g.day);
      c.setCustomKey('studyo', g.studioLevel);
      c.setCustomKey('program', g.shows.length);
      c.setCustomKey('kadro', g.staff.length);
    } catch (_) {}
  }
}
