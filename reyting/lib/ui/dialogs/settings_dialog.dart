import '../../core/notify.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/ads.dart';
import '../../core/cloud.dart';
import '../../engine/game.dart';
import '../screens/online_screen.dart' show showTransferDialog;
import '../widgets/common.dart';
import '../widgets/company_logo.dart';
import 'identity_dialog.dart';

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
            const Text(
              'Ayarlar',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            const SectionLabel('Kanal adı'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _name,
                    maxLength: 20,
                    decoration: const InputDecoration(
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GhostButton(
                  'Kaydet',
                  compact: true,
                  onTap: () => game.rename(_name.text),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CompanyLogoView(logo: game.logo, size: 40),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    game.companyFullName,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                GhostButton(
                  'Logo ve isim',
                  compact: true,
                  icon: Icons.brush_rounded,
                  onTap: () => showIdentityDialog(context),
                ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: game.stingOn,
              onChanged: (v) => game.setSting(v),
              title: const Text(
                '🎬 Açılış logosu',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: const Text(
                'Yeni yapım başlarken şirket logon ekrana gelsin',
                style: TextStyle(fontSize: 12, color: AppColors.textDim),
              ),
            ),
            StatefulBuilder(
              builder: (c, setS) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: Notify.enabled,
                onChanged: (v) async {
                  await Notify.setEnabled(v);
                  setS(() {});
                },
                title: const Text('🔔 Bildirimler', style: TextStyle(fontWeight: FontWeight.w800)),
                subtitle: const Text(
                  'Çekim bitince, özel gün yaklaşınca ve uzun süre girmezsen haber ver',
                  style: TextStyle(fontSize: 12, color: AppColors.textDim),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text('🎭 Kulis dramaları', style: TextStyle(fontWeight: FontWeight.w800)),
            const Text(
              'Kadrodaki aşklar, kavgalar, yıldız talepleri ne sıklıkla çıksın?',
              style: TextStyle(fontSize: 12, color: AppColors.textDim),
            ),
            const SizedBox(height: 6),
            PillTabs(
              labels: dramaLevelNames,
              selected: game.dramaLevel,
              onChanged: game.setDramaLevel,
            ),
            const SizedBox(height: 8),
            const SectionLabel(
              'Test modu · zaman hızı',
              color: AppColors.yellow,
            ),
            const SizedBox(height: 4),
            const Text(
              'Denemeyi kolaylaştırmak için. Normalde 1 oyun günü = 1 dakika.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (game.tainted)
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('⚠️ Bu kariyerde test modu kullanıldı: online sıralamaya giremez (bulut yedeği çalışır).',
                    style: TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            PillTabs(
              labels: const ['Normal', '10× hızlı', '60× hızlı'],
              selected: speeds.indexOf(game.timeScale).clamp(0, 2),
              onChanged: (i) async {
                if (speeds[i] > 1 && !game.tainted) {
                  final ok = await confirm(
                    context,
                    'Test modu açılsın mı?',
                    'Hızlı zaman sadece denemek içindir. Bir kez kullanırsan bu kariyer online zenginler '
                        'listesine bir daha giremez (kayıt buluta yedeklenmeye devam eder). '
                        'Listeye girmek için sonra yeni kariyer başlatman gerekir.',
                    ok: 'Yine de aç',
                  );
                  if (!ok) return;
                }
                game.setTimeScale(speeds[i]);
              },
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GhostButton(
                  'Reklam gizlilik ayarları',
                  icon: Icons.privacy_tip_rounded,
                  compact: true,
                  onTap: () => Ads.instance.showPrivacyOptions(),
                ),
                GhostButton(
                  'Hesabı başka cihaza taşı',
                  compact: true,
                  icon: Icons.phonelink_setup_rounded,
                  onTap: () => showTransferDialog(context),
                ),
                if (Cloud.instance.signedIn)
                  GhostButton(
                    'Hesabımı sil',
                    icon: Icons.delete_forever_rounded,
                    color: AppColors.red,
                    compact: true,
                    onTap: () async {
                      final ok = await confirm(
                        context,
                        'Hesabın silinsin mi?',
                        'Online hesabın, bulut kaydın ve zenginler listesindeki yerin kalıcı olarak silinir. '
                            'Telefondaki oyunun kalır; istersen "Oyunu sıfırla" ile onu da silebilirsin. '
                            'Satın aldığın Reklamsız/VIP hakları Google Play hesabına bağlıdır, geri yüklenebilir.',
                        ok: 'Kalıcı olarak sil',
                      );
                      if (!ok) return;
                      final err = await Cloud.instance.deleteAccount();
                      if (context.mounted) {
                        report(context, err);
                        if (err == null) game.showToast('Hesabın ve sunucudaki verilerin silindi.');
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            GhostButton(
              'Oyunu sıfırla',
              icon: Icons.restart_alt_rounded,
              color: AppColors.red,
              compact: true,
              onTap: () async {
                final ok = await confirm(
                  context,
                  'Oyunu sıfırla?',
                  'Tüm ilerlemen silinecek ve Gün 1\'den başlayacaksın.',
                  ok: 'Sıfırla',
                );
                if (ok) {
                  await game.resetGame();
                  if (context.mounted) Navigator.pop(context);
                }
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Reyting · v1.2.0',
              style: TextStyle(color: AppColors.textFaint, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
