import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'core/ads.dart';
import 'core/cloud.dart';
import 'core/shop.dart';
import 'core/sfx.dart';
import 'core/theme.dart';
import 'engine/game.dart';
import 'ui/shell.dart';
import 'ui/splash.dart';
import 'ui/widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Oyun yatay (landscape) oynanır
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const ReytingApp());
}

class ReytingApp extends StatefulWidget {
  const ReytingApp({super.key});
  @override
  State<ReytingApp> createState() => _ReytingAppState();
}

class _ReytingAppState extends State<ReytingApp> with WidgetsBindingObserver {
  Game? _game;
  double _progress = 0;
  String _status = 'Stüdyo ışıkları yanıyor…';
  String _version = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  /// Açılış adımları: yükleme çubuğu gerçek adımlarla dolar.
  Future<void> _boot() async {
    final sw = Stopwatch()..start();
    void step(double p, String s) {
      if (mounted) {
        setState(() {
          _progress = p;
          _status = s;
        });
      }
    }

    try {
      final info = await PackageInfo.fromPlatform();
      _version = '${info.version} (${info.buildNumber})';
    } catch (_) {
      _version = '0.8.0';
    }
    await Sfx.init();
    step(0.15, 'Online sistem hazırlanıyor…');
    await Cloud.instance.init();
    step(0.25, 'Kayıtların okunuyor…');
    final game = Game();
    await game.start();
    // Açılış ekranı okunabilsin: logo ve "ESM Games" ~4 sn görünür
    Future<void> until(int ms) async {
      final rest = ms - sw.elapsedMilliseconds;
      if (rest > 0) await Future<void>.delayed(Duration(milliseconds: rest));
    }

    await until(1200);
    step(0.55, 'Yayın akışı hazırlanıyor…');
    await until(2300);
    step(0.8, 'Reytingler hesaplanıyor…');
    await until(3400);
    step(1.0, 'Yayındasın!');
    await until(4000);
    Cloud.instance.attach(game);
    if (mounted) setState(() => _game = game);
    // reklam ve mağaza oyun açıldıktan sonra (açılışı yavaşlatmasın)
    Ads.instance.init();
    Shop.instance.init(game);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final g = _game;
    if (g == null) return;
    Sfx.pause(state != AppLifecycleState.resumed);
    Ads.instance.pause(state != AppLifecycleState.resumed);
    if (state == AppLifecycleState.paused) {
      g.onPause();
      Cloud.instance.onPause();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      g.save();
    } else if (state == AppLifecycleState.resumed) {
      g.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = _game;
    final app = MaterialApp(
      title: 'Reyting',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: g == null
          ? SplashScreen(
              progress: _progress,
              status: _status,
              version: _version,
            )
          : const Shell(),
    );
    if (g == null) return app;
    return GameScope(game: g, child: app);
  }
}
