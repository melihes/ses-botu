import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/cloud.dart';
import '../../core/format.dart';
import '../widgets/common.dart';

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
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Gerçek oyuncularla yarış',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                  Text(
                      'Google ile giriş yap: ilerlemen buluta kaydedilsin (telefon değişse de kaybolmaz) '
                      've zenginler listesinde gerçek oyuncularla yarış.',
                      style: TextStyle(color: AppColors.textDim, fontSize: 12)),
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
                const Expanded(
                  child: Text(
                      'Misafir olarak oynuyorsun. Telefonu değiştirir ya da oyunu silersen ilerlemen kaybolabilir. '
                      'Google hesabına bağla, ilerlemen hep korunsun.',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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
              const Icon(Icons.verified_user_rounded, color: AppColors.green, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.displayName, style: const TextStyle(fontWeight: FontWeight.w900)),
                  Text(
                      '${c.lastSyncNote ?? 'Henüz buluta kaydedilmedi.'}'
                      '${c.myRank != null ? ' · Gerçek sıran: #${c.myRank} / ${c.totalPlayers}' : ''}',
                      style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                ]),
              ),
              GhostButton('Şimdi kaydet', compact: true, icon: Icons.cloud_upload_rounded,
                  onTap: () => c.sync(force: true)),
              const SizedBox(width: 6),
              GhostButton('Yenile', compact: true, icon: Icons.refresh_rounded, onTap: c.refreshTop),
              if (!c.isGuest) ...[
                const SizedBox(width: 6),
                GhostButton('Çıkış', compact: true, color: AppColors.textDim, onTap: c.signOut),
              ],
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
