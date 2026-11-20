import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'engine/game.dart';
import 'ui/shell.dart';
import 'ui/widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Oyun yatay (landscape) oynanır
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final game = Game();
  await game.start();
  runApp(ReytingApp(game: game));
}

class ReytingApp extends StatefulWidget {
  final Game game;
  const ReytingApp({super.key, required this.game});
  @override
  State<ReytingApp> createState() => _ReytingAppState();
}

class _ReytingAppState extends State<ReytingApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      widget.game.onPause();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      widget.game.save();
    } else if (state == AppLifecycleState.resumed) {
      widget.game.onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScope(
      game: widget.game,
      child: MaterialApp(
        title: 'Reyting',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Shell(),
      ),
    );
  }
}
