import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oyunun sesleri: hafif seyirci sesleri (alkış, tribün).
/// Sesler tool/make_sounds.py ile sentezlenmiştir (telifsiz).
/// Not: sentezlenmiş karakter sesleri kulağa hoş gelmediği için kaldırıldı.
class Sfx {
  static bool enabled = true;
  static double volume = 0.7;
  static bool _paused = false;
  static final _rng = Random();
  static final List<AudioPlayer> _pool = [];
  static int _next = 0;
  static DateTime _lastCrowd = DateTime(2000);

  static Future<void> init() async {
    try {
      final p = await SharedPreferences.getInstance();
      enabled = p.getBool('sfx_on') ?? true;
      volume = p.getDouble('sfx_vol') ?? 0.7;
      for (int i = 0; i < 3; i++) {
        _pool.add(AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      }
    } catch (_) {
      enabled = false; // ses altyapısı yoksa (ör. testler) sessiz çalış
    }
  }

  static Future<void> setEnabled(bool v) async {
    enabled = v;
    final p = await SharedPreferences.getInstance();
    await p.setBool('sfx_on', v);
  }

  static Future<void> setVolume(double v) async {
    volume = v;
    final p = await SharedPreferences.getInstance();
    await p.setDouble('sfx_vol', v);
  }

  /// Uygulama arka plandayken ses çalınmaz.
  static void pause(bool v) => _paused = v;

  static void _play(String name, double vol) {
    if (!enabled || _paused || _pool.isEmpty || volume <= 0) return;
    final player = _pool[_next++ % _pool.length];
    player
        .play(AssetSource('sounds/$name.m4a'), volume: vol * volume)
        .catchError((_) {});
  }

  /// Seyirci: alkış ya da tribün coşkusu (seyrek ve kısık).
  static void crowd(String kind) {
    final now = DateTime.now();
    if (now.difference(_lastCrowd).inSeconds < 12) return;
    _lastCrowd = now;
    _play(kind, 0.3 + _rng.nextDouble() * 0.1);
  }
}
