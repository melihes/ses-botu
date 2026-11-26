import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/cloud.dart';
import '../../core/format.dart';
import '../widgets/common.dart';
import '../widgets/company_logo.dart';
import '../widgets/profile_frame.dart';

/// Online özelliklerin tanıtım ekranı (Aşama 3-4'te gerçek olacak)
class OnlineScreen extends StatelessWidget {
  const OnlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.gavel_rounded,
        AppColors.accent,
        'Canlı transfer ihalesi',
        'Yıldız oyuncu ve yönetmenler tüm oyuncuların teklif verdiği süreli açık artırmaya düşer. Teklifin bloke edilir, geçilirse iade edilir.',
      ),
      (
        Icons.leaderboard_rounded,
        AppColors.cyan,
        'Prime Time Ligi',
        'Aynı kuşakta yayınlanan programların reytingleri haftalık karşılaştırılır. Sezon sonunda ödüller!',
      ),
      (
        Icons.storefront_rounded,
        AppColors.yellow,
        'Format pazarı',
        'Başarılı program formatını diğer oyunculara sat ya da onlarınkini satın al.',
      ),
      (
        Icons.handshake_rounded,
        AppColors.green,
        'Ortak yapım',
        'Başka bir kanalla güçlerini birleştir, büyük bütçeli yapımları birlikte çek.',
      ),
      (
        Icons.flight_takeoff_rounded,
        AppColors.orange,
        'Yurt dışına dizi satışı',
        'Dizilerini başka ülkelerin kanallarına sat, döviz değil ₺ kazan.',
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        const _OnlinePanel(),
        const SizedBox(height: 14),
        const SectionLabel('Sıradaki online özellikler'),
        const SizedBox(height: 6),
        AutoGrid(
          minItemWidth: 300,
          spacing: 10,
          children: [
            for (final it in items)
              Panel(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ArtTile(icon: it.$1, color: it.$2, size: 64),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  it.$3,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const Tag('GÜNCELLEMEYLE', color: AppColors.textDim),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            it.$4,
                            style: const TextStyle(
                              color: AppColors.textDim,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}


/// Google ile giriş, bulut kaydı ve gerçek oyuncularla zenginler listesi
class _OnlinePanel extends StatelessWidget {
  const _OnlinePanel();

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return ListenableBuilder(
      listenable: Cloud.instance,
      builder: (context, _) {
        final c = Cloud.instance;
        if (!c.ready) {
          return const Panel(
            child: Text('Online sisteme şu an bağlanılamıyor. Oyun çevrimdışı oynanmaya devam eder.',
                style: TextStyle(color: AppColors.textDim)),
          );
        }
        if (!c.signedIn) {
          return Panel(
            gradient: const LinearGradient(colors: [Color(0xFF1F2A44), AppColors.panel]),
            child: Row(children: [
              const Icon(Icons.public_rounded, color: AppColors.cyan, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Gerçek oyuncularla yarış',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  const Text(
                      'Google ile giriş yap: ilerlemen buluta kaydedilsin (telefon değişse de kaybolmaz) '
                      've zenginler listesinde gerçek oyuncularla yarış.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                  if (c.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SelectableText('⚠️ ${c.error}',
                          style: const TextStyle(color: AppColors.red, fontSize: 11)),
                    ),
                ]),
              ),
              const SizedBox(width: 10),
              AccentButton(c.busy ? 'Bağlanıyor…' : 'Google ile giriş yap',
                  icon: Icons.login_rounded,
                  onTap: c.busy ? null : () async => report(context, await c.signIn())),
            ]),
          );
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (c.cloudSaveRaw != null)
            Panel(
              borderColor: AppColors.yellow,
              child: Row(children: [
                const Icon(Icons.cloud_download_rounded, color: AppColors.yellow, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Bulutta bir kaydın var (Gün ${c.cloudDay ?? '?'}). Telefondaki oyun: Gün ${game.day}. '
                      'Hangisiyle devam edelim?',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                AccentButton('Buluttakini yükle', compact: true, onTap: () async {
                  if (await confirm(context, 'Buluttaki kayıt yüklensin mi?',
                      'Telefondaki ilerlemenin yerine buluttaki geçer.')) {
                    await c.restoreCloud();
                  }
                }),
                const SizedBox(width: 6),
                GhostButton('Telefondakiyle devam', compact: true, onTap: () {
                  c.dismissCloud();
                  c.sync(force: true);
                }),
              ]),
            ),
          if (c.cloudSaveRaw != null) const SizedBox(height: 10),
          if (c.unverifiedReason != null || game.tainted) ...[
            Panel(
              borderColor: AppColors.orange,
              child: Row(children: [
                const Icon(Icons.gpp_maybe_rounded, color: AppColors.orange, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      '${c.unverifiedReason ?? 'Bu kariyerde test modu kullanıldı.'} '
                      'İlerlemen buluta yedekleniyor ama zenginler listesine giremezsin.',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
                GhostButton('Yeni kariyer başlat', compact: true, color: AppColors.orange, onTap: () async {
                  if (await confirm(context, 'Yeni kariyer başlatılsın mı?',
                      'Oyun Gün 1\'den başlar ve sıralamaya temiz girersin. Mevcut ilerleme silinir.',
                      ok: 'Başlat')) {
                    await c.startFreshCareer();
                  }
                }),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          if (c.isGuest) ...[
            Panel(
              borderColor: AppColors.cyan,
              child: Row(children: [
                const Icon(Icons.shield_rounded, color: AppColors.cyan, size: 36),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text(
                        'Misafir olarak oynuyorsun. Telefonu değiştirir ya da oyunu silersen ilerlemen kaybolabilir. '
                        'Google hesabına bağla, ilerlemen hep korunsun.',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                    if (c.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: SelectableText('⚠️ ${c.error}',
                            style: const TextStyle(color: AppColors.red, fontSize: 11)),
                      ),
                    if (c.error != null && c.certPrints != null)
                      SelectableText('İmza: ${c.certPrints!.join('  ')}',
                          style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                  ]),
                ),
                AccentButton(c.busy ? 'Bağlanıyor…' : 'Google ile koru',
                    compact: true,
                    icon: Icons.link_rounded,
                    onTap: c.busy ? null : () async => report(context, await c.signIn())),
              ]),
            ),
            const SizedBox(height: 10),
          ],
          Panel(
            child: Row(children: [
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () => showFramePicker(context, game, CompanyLogoView(logo: game.logo, size: 60)),
                child: ProfileFrame(
                  frame: game.profileFrame,
                  size: 54,
                  child: CompanyLogoView(logo: game.logo, size: 54),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(
                      '${c.lastSyncNote ?? 'Henüz buluta kaydedilmedi.'}'
                      '${c.myRank != null ? ' · Gerçek sıran: #${c.myRank} / ${c.totalPlayers}' : ''}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                  const SizedBox(height: 6),
                  // düğmeler alta, sığmazsa alt satıra geçer
                  Wrap(spacing: 6, runSpacing: 6, children: [
                    GhostButton('Şimdi kaydet', compact: true, icon: Icons.cloud_upload_rounded,
                        onTap: () => c.sync(force: true)),
                    GhostButton('Yenile', compact: true, icon: Icons.refresh_rounded, onTap: c.refreshTop),
                    GhostButton('Telefon değiştir', compact: true, icon: Icons.phonelink_setup_rounded,
                        onTap: () => showTransferDialog(context)),
                    if (!c.isGuest)
                      GhostButton('Çıkış', compact: true, color: AppColors.textDim, onTap: c.signOut),
                  ]),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 10),
          SectionLabel('Zenginler listesi · gerçek oyuncular'
              '${c.topUpdated != null ? ' · ${c.topUpdated!.hour.toString().padLeft(2, '0')}:${c.topUpdated!.minute.toString().padLeft(2, '0')} güncel' : ''}'),
          const SizedBox(height: 6),
          if (c.top.isEmpty)
            const Text('Liste her 10 dakikada bir hazırlanır. Biraz sonra "Yenile"ye bas.',
                style: TextStyle(color: AppColors.textDim, fontSize: 12))
          else
            Panel(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(children: [
                for (final r in c.top.take(100))
                  Container(
                    color: r.uid == c.user?.uid ? AppColors.accent.withValues(alpha: 0.15) : null,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    child: Row(children: [
                      SizedBox(
                        width: 40,
                        child: Text('#${r.rank}',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: r.rank <= 3 ? AppColors.yellow : AppColors.textDim)),
                      ),
                      ProfileFrame(
                        frame: r.frame,
                        size: 30,
                        child: ColoredBox(
                          color: AppColors.panelHi,
                          child: Center(
                            child: Text(r.name.isEmpty ? '?' : r.name.characters.first.toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text('Sv ${r.level + 1}  ', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                      Text(fmtShort(r.worth), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.green)),
                    ]),
                  ),
              ]),
            ),
        ]);
      },
    );
  }
}


/// Telefon değiştirme: eski cihazda kod al, yeni cihazda kodu gir.
/// Google girişi olmadan da (misafir hesapta) çalışır.
Future<void> showTransferDialog(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const Dialog(child: _TransferBody()),
    );

class _TransferBody extends StatefulWidget {
  const _TransferBody();
  @override
  State<_TransferBody> createState() => _TransferBodyState();
}

class _TransferBodyState extends State<_TransferBody> {
  String? _code, _msg;
  bool _busy = false;
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Text('Hesabı başka cihaza taşı',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                const Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
              ]),
              const SizedBox(height: 6),
              const SectionLabel('1 · Eski cihazda'),
              const SizedBox(height: 4),
              const Text('Kod al; kod 24 saat geçerli. Kodu kimseyle paylaşma.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                AccentButton(_busy ? 'Bekle…' : 'Taşıma kodu al',
                    compact: true,
                    icon: Icons.key_rounded,
                    onTap: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            final (code, err) = await Cloud.instance.createTransferCode();
                            if (mounted) setState(() { _busy = false; _code = code; _msg = err; });
                          }),
                const SizedBox(width: 12),
                if (_code != null)
                  SelectableText(_code!,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3,
                          color: AppColors.yellow)),
              ]),
              const SizedBox(height: 14),
              const SectionLabel('2 · Yeni cihazda'),
              const SizedBox(height: 4),
              const Text('Eski cihazdaki kodu yaz. Bu cihazdaki ilerleme, taşınan hesapla değişir.',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12)),
              const SizedBox(height: 6),
              Row(children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: _input,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(hintText: 'ABCD-1234', isDense: true),
                  ),
                ),
                const SizedBox(width: 10),
                AccentButton(_busy ? 'Bekle…' : 'Hesabımı getir',
                    compact: true,
                    icon: Icons.download_rounded,
                    onTap: _busy
                        ? null
                        : () async {
                            setState(() => _busy = true);
                            final err = await Cloud.instance.redeemTransferCode(_input.text);
                            if (!mounted) return;
                            setState(() { _busy = false; _msg = err ?? '✅ Hesabın bu cihaza geldi!'; });
                          }),
              ]),
              if (_msg != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(_msg!,
                      style: TextStyle(
                          color: _msg!.startsWith('✅') ? AppColors.green : AppColors.red,
                          fontWeight: FontWeight.w700)),
                ),
            ]),
          ),
        ),
      );
}
