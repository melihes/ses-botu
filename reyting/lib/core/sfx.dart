import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Oyunun sesleri: karakter konuşmaları (bıdı bıdı) ve seyirci sesleri.
/// Sesler tool/make_sounds.py ile sentezlenmiştir (telifsiz).
class Sfx {
  static bool enabled = true;
  static double volume = 0.7;
  static bool _paused = false;
  static final _rng = Random();
  static final List<AudioPlayer> _pool = [];
  static int _next = 0;
  static DateTime _lastVoice = DateTime(2000);
  static DateTime _lastCrowd = DateTime(2000);

  static const voiceTypes = ['low', 'mid', 'high', 'kid'];

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
    player.play(AssetSource('sounds/$name.m4a'), volume: vol * volume).catchError((_) {});
  }

  /// Bir karakterin konuşması. Üst üste binmesin diye aralıklı çalar.
  static bool voice({String? type}) {
    final now = DateTime.now();
    if (now.difference(_lastVoice).inMilliseconds < 1500) return false;
    _lastVoice = now;
    final t = type ?? voiceTypes[_rng.nextInt(3)];
    _play('voice_${t}_${_rng.nextInt(3)}', 0.8);
    return true;
  }

  /// Seyirci: alkış, kahkaha ya da tribün coşkusu.
  static void crowd(String kind) {
    final now = DateTime.now();
    if (now.difference(_lastCrowd).inSeconds < 6) return;
    _lastCrowd = now;
    _play(kind, 0.45);
  }
}
