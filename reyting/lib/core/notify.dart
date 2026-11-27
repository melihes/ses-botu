import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../data/calendar.dart';
import '../engine/economy.dart';
import '../engine/game.dart';
import '../models/models.dart';
import 'format.dart';

/// Telefon bildirimleri: oyun kapalıyken olacakları önceden zamanlar
/// (çekim bitti, özel gün geliyor, sen yokken kazandın). Oyun açılınca
/// bekleyenler iptal edilir. Ayarlar'dan kapatılabilir.
class Notify {
  static final _p = FlutterLocalNotificationsPlugin();
  static bool _ready = false;
  static bool enabled = true;
  static const _key = 'notify_on';
  static const _askedKey = 'notify_asked';

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'reyting_oyun',
      'Oyun bildirimleri',
      channelDescription: 'Çekim bitti, özel gün yaklaşıyor, kanalın seni bekliyor',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_key) ?? true;
      await _p.initialize(
        settings: const InitializationSettings(android: AndroidInitializationSettings('@drawable/ic_stat_reyting')),
      );
      _ready = true;
      await clear();
    } catch (e) {
      debugPrint('Bildirimler başlatılamadı: $e');
    }
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, v);
    if (v) {
      await askPermission(force: true);
    } else {
      await clear();
    }
  }

  /// Android 13+ izin penceresi (bir kez sorulur)
  static Future<void> askPermission({bool force = false}) async {
    if (!_ready) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!force && (prefs.getBool(_askedKey) ?? false)) return;
      await prefs.setBool(_askedKey, true);
      await _p
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    } catch (_) {}
  }

  /// Her çağrı bir "nesil": oyuna hızla dönülürse geç biten zamanlama iptal edilir
  static int _gen = 0;

  static Future<void> clear() async {
    _gen++;
    if (!_ready) return;
    try {
      await _p.cancelAll();
    } catch (_) {}
  }

  static Future<void> _at(int id, Duration after, String title, String body) async {
    if (after.inSeconds < 60) return;
    await _p.zonedSchedule(
      id: id,
      scheduledDate: tz.TZDateTime.now(tz.UTC).add(after),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: title,
      body: body,
    );
  }

  /// Oyun arka plana atılınca: kapalıyken olacakları zamanla
  static Future<void> scheduleAway(Game g) async {
    if (!_ready || !enabled) return;
    try {
      await clear();
      final gen = _gen;
      for (final n in planAway(g)) {
        if (gen != _gen) return; // bu arada oyuna dönüldü
        await _at(n.$1, n.$2, n.$3, n.$4);
      }
      if (gen != _gen) await _p.cancelAll();
    } catch (e) {
      debugPrint('Bildirim zamanlanamadı: $e');
    }
  }

  /// Zamanlanacak bildirimler (test edilebilsin diye ayrı): (id, ne zaman, başlık, metin)
  static List<(int, Duration, String, String)> planAway(Game g) {
    final out = <(int, Duration, String, String)>[];
    // oyun kapalıyken bir oyun günü kaç gerçek dakika sürer
    final minPerDay = secondsPerDay / 60 / max(0.01, g.offlineSpeed);
    final cap = g.offlineCapMinutes;
    Duration real(double days) => Duration(seconds: (days * minPerDay * 60).round());

    // 1) en erken biten çekim
    Show? next;
    for (final s in g.shows) {
      if (s.status == ShowStatus.producing && (next == null || s.prodLeft < next.prodLeft)) next = s;
    }
    if (next != null && next.prodLeft * minPerDay <= cap) {
      out.add((1, real(next.prodLeft), '🎬 "${next.name}" çekimi bitti!', 'Yayına koymak için gel, kuşak seni bekliyor.'));
    }
    // 2) biten film
    Film? film;
    for (final f in g.films) {
      if (f.status == FilmStatus.producing && (film == null || f.prodLeft < film.prodLeft)) film = f;
    }
    if (film != null && film.prodLeft * minPerDay <= cap) {
      out.add((2, real(film.prodLeft), '🍿 "${film.name}" filmi hazır!', 'Vizyona sokma zamanı.'));
    }
    // 3) yaklaşan özel gün (bir gün önceden)
    final up = g.upcomingSpecialDays(within: 30).where((e) => e.$2 > g.day).toList();
    if (up.isNotEmpty) {
      final (d, start) = up.first;
      final days = (start - 1 - g.day) + (1 - g.dayProgress);
      if (days > 0 && days * minPerDay <= cap) {
        out.add((3, real(days), '${d.emoji} ${d.name} yarın!', '"${d.special}" hazırlarsan reyting ve sponsor geliri katlanır.'));
      }
    }
    // 4) sen yokken kazanç (20 saat sonra)
    const away = Duration(hours: 20);
    final earnedDays = min(away.inMinutes.toDouble(), cap) / minPerDay;
    final earned = max(0.0, g.netPerDay * earnedDays);
    if (earned > 0) {
      out.add((10, away, '📺 Kanalın seni bekliyor', 'Sen yokken yaklaşık ${fmtShort(earned)} kazandın. Gel, sosyal medyada neler konuşulmuş bak!'));
    } else {
      out.add((10, away, '📺 Kanalın seni bekliyor', 'Yayın akışın boş kalmasın; yeni bir program hazırla.'));
    }
    // 5) uzun süre girmeyene (3 gün)
    out.add((11, const Duration(days: 3), '🔥 Rakip kanallar reytingini çalıyor!',
        'Yıldızların yeni projeler bekliyor. ${dateLabel(g.day)} sonrası neler oldu, gel bak.'));
    return out;
  }
}
