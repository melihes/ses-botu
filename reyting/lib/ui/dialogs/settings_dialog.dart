import 'package:flutter/material.dart';

import '../../core/sfx.dart';
import '../../core/theme.dart';
import '../widgets/common.dart';

Future<void> showSettingsDialog(BuildContext context) {
  return showDialog(
    context: context,
    builder: (c) => const Dialog(child: _Settings()),
  );
}

class _Settings extends StatefulWidget {
  const _Settings();
  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  late final TextEditingController _name;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: GameScope.read(context).channelName);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    const speeds = [1.0, 10.0, 60.0];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ayarlar',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            const SectionLabel('Kanal adı'),
            const SizedBox(height: 6),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _name,
                  maxLength: 20,
                  decoration: const InputDecoration(
                      counterText: '', isDense: true),
                ),
              ),
              const SizedBox(width: 10),
              GhostButton('Kaydet',
                  compact: true, onTap: () => game.rename(_name.text)),
            ]),
            const SizedBox(height: 14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: Sfx.enabled,
              onChanged: (v) async {
                await Sfx.setEnabled(v);
                setState(() {});
                if (v) Sfx.crowd('applause');
              },
              title: const Text('🔊 Sesler',
                  style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Seyirci alkışı ve tribün sesleri',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim)),
            ),
            if (Sfx.enabled)
              Row(children: [
                const Icon(Icons.volume_down_rounded, color: AppColors.textDim),
                Expanded(
                  child: Slider(
                    value: Sfx.volume,
                    onChanged: (v) => setState(() => Sfx.volume = v),
                    onChangeEnd: (v) {
                      Sfx.setVolume(v);
                      Sfx.crowd('applause');
                    },
                  ),
                ),
                const Icon(Icons.volume_up_rounded, color: AppColors.textDim),
              ]),
            const SizedBox(height: 8),
            const SectionLabel('Test modu · zaman hızı', color: AppColors.yellow),
            const SizedBox(height: 4),
            const Text(
              'Denemeyi kolaylaştırmak için. Normalde 1 oyun günü = 1 dakika.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 8),
            PillTabs(
              labels: const ['Normal', '10× hızlı', '60× hızlı'],
              selected: speeds.indexOf(game.timeScale).clamp(0, 2),
              onChanged: (i) => game.setTimeScale(speeds[i]),
            ),
            const SizedBox(height: 22),
            GhostButton(
              'Oyunu sıfırla',
              icon: Icons.restart_alt_rounded,
              color: AppColors.red,
              compact: true,
              onTap: () async {
                final ok = await confirm(context, 'Oyunu sıfırla?',
                    'Tüm ilerlemen silinecek ve Gün 1\'den başlayacaksın.',
                    ok: 'Sıfırla');
                if (ok) {
                  await game.resetGame();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 12),
            const Text('Reyting · prototip v0.1',
                style: TextStyle(color: AppColors.textFaint, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
