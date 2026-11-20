import 'dart:async';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/theme.dart';
import 'dialogs/offline_dialog.dart';
import 'dialogs/settings_dialog.dart';
import 'screens/bank_screen.dart';
import 'screens/broadcast_screen.dart';
import 'screens/channels_screen.dart';
import 'screens/home_screen.dart';
import 'screens/luxury_screen.dart';
import 'screens/online_screen.dart';
import 'screens/production_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/studio_screen.dart';
import 'widgets/common.dart';

enum PageId { home, staff, production, broadcast, studio, bank, channels, luxury, online }

class _NavItem {
  final PageId id;
  final String label;
  final String section;
  final String title;
  final IconData icon;
  const _NavItem(this.id, this.label, this.section, this.title, this.icon);
}

const _nav = [
  _NavItem(PageId.home, 'Ana ekran', 'KANAL', '', Icons.home_rounded),
  _NavItem(PageId.staff, 'Kadro', 'İNSAN KAYNAKLARI', 'Kadro',
      Icons.groups_rounded),
  _NavItem(PageId.production, 'Yapım', 'STÜDYO', 'Yapımlar',
      Icons.movie_creation_rounded),
  _NavItem(PageId.broadcast, 'Yayın', 'CANLI', 'Yayın akışı',
      Icons.live_tv_rounded),
  _NavItem(PageId.studio, 'Stüdyo', 'TESİSLER', 'Stüdyo & ekipman',
      Icons.domain_rounded),
  _NavItem(PageId.bank, 'Banka', 'FİNANS', 'Banka',
      Icons.account_balance_rounded),
  _NavItem(PageId.channels, 'Kanallar', 'SATIN ALMA', 'Kanal pazarı',
      Icons.connected_tv_rounded),
  _NavItem(PageId.luxury, 'Lüks', 'YAŞAM', 'Lüks yaşam',
      Icons.diamond_rounded),
  _NavItem(PageId.online, 'Online', 'YAKINDA', 'Online arena',
      Icons.public_rounded),
];

/// Ekranlar arası geçiş için
class ShellNav extends InheritedWidget {
  final void Function(PageId) goTo;
  const ShellNav({super.key, required this.goTo, required super.child});
  static void go(BuildContext context, PageId id) =>
      context.getInheritedWidgetOfExactType<ShellNav>()!.goTo(id);
  @override
  bool updateShouldNotify(covariant ShellNav old) => false;
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  // Oyun her açılışta ana ekranda başlar (bkz. docs/DERSLER.md #5)
  PageId _page = PageId.home;
  bool _offlineShowing = false;

  Widget _body() => switch (_page) {
        PageId.home => const HomeScreen(),
        PageId.staff => const StaffScreen(),
        PageId.production => const ProductionScreen(),
        PageId.broadcast => const BroadcastScreen(),
        PageId.studio => const StudioScreen(),
        PageId.bank => const BankScreen(),
        PageId.channels => const ChannelsScreen(),
        PageId.luxury => const LuxuryScreen(),
        PageId.online => const OnlineScreen(),
      };

  void _maybeShowOffline() {
    final game = GameScope.read(context);
    if (game.pendingOffline == null || _offlineShowing) return;
    _offlineShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final sum = game.pendingOffline;
      if (sum == null || !mounted) {
        _offlineShowing = false;
        return;
      }
      await showOfflineDialog(context, sum, game);
      game.dismissOffline();
      _offlineShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    if (game.pendingOffline != null) _maybeShowOffline();
    final item = _nav.firstWhere((n) => n.id == _page);
    return ShellNav(
      goTo: (p) => setState(() => _page = p),
      child: Scaffold(
        body: SafeArea(
          child: Stack(children: [
            Row(children: [
              _Sidebar(
                  selected: _page, onTap: (p) => setState(() => _page = p)),
              Expanded(
                child: Column(children: [
                  _TopBar(
                    section: item.section,
                    title: item.id == PageId.home ? game.channelName : item.title,
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: KeyedSubtree(key: ValueKey(_page), child: _body()),
                    ),
                  ),
                ]),
              ),
            ]),
            const _ToastHost(),
          ]),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final PageId selected;
  final ValueChanged<PageId> onTap;
  const _Sidebar({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      color: AppColors.sidebar,
      child: Column(children: [
        // Logo: kayıt ışığı
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 9,
              height: 9,
              decoration: const BoxDecoration(
                  color: AppColors.accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            const Text('REYTİNG',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.2)),
          ]),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              for (final n in _nav)
                _SideButton(
                  item: n,
                  active: n.id == selected,
                  onTap: () => onTap(n.id),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _SideButton extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _SideButton(
      {required this.item, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textDim;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.13) : null,
          borderRadius: BorderRadius.circular(12),
          border: active
              ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(children: [
          Icon(item.icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(item.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  color: active ? AppColors.text : AppColors.textDim)),
        ]),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String section;
  final String title;
  const _TopBar({required this.section, required this.title});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return LayoutBuilder(builder: (context, c) {
      final narrow = c.maxWidth < 720;
      return Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(section),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          // Kasa
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const SectionLabel('Kasa', color: AppColors.textDim),
              Text(narrow ? fmtShort(game.cash) : fmtFull(game.cash),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: game.cash < 0 ? AppColors.red : AppColors.text)),
            ],
          ),
          const SizedBox(width: 10),
          _Chip(
            icon: Icons.star_rounded,
            color: AppColors.yellow,
            text: fmtInt(game.prestige),
            tooltip: 'Prestij',
          ),
          const SizedBox(width: 6),
          _Chip(
            icon: Icons.diamond_outlined,
            color: AppColors.cyan,
            text: '${game.diamonds}',
            tooltip: 'Elmas',
          ),
          const SizedBox(width: 6),
          AccentButton(
            narrow ? '' : 'Mağaza',
            icon: Icons.storefront_rounded,
            compact: true,
            onTap: () => game.showToast(
                '🛍️ Mağaza (elmas, VIP, dekorlar) Aşama 5\'te açılacak.'),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: () => showSettingsDialog(context),
            icon: const Icon(Icons.settings_rounded, color: AppColors.textDim),
            tooltip: 'Ayarlar',
          ),
          _DayChip(day: game.day, progress: game.dayProgress),
        ]),
      );
    });
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String tooltip;
  const _Chip(
      {required this.icon,
      required this.color,
      required this.text,
      required this.tooltip});
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.panel,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(text,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ),
      );
}

class _DayChip extends StatelessWidget {
  final int day;
  final double progress;
  const _DayChip({required this.day, required this.progress});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
        decoration: BoxDecoration(
          color: AppColors.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_month_rounded,
                size: 15, color: AppColors.cyan),
            const SizedBox(width: 5),
            Text('Gün $day · ${weekdayOf(day)}',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
          const SizedBox(height: 4),
          SizedBox(
              width: 110,
              child: Bar(progress, color: AppColors.accent, height: 3)),
        ]),
      );
}

/// Alt ortada beliren bildirimler
class _ToastHost extends StatefulWidget {
  const _ToastHost();
  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> {
  String? _msg;
  Timer? _t;
  late final ValueNotifier<String?> _src;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _src = GameScope.read(context).toast;
    _src.removeListener(_on);
    _src.addListener(_on);
  }

  void _on() {
    final m = _src.value;
    if (m == null) return;
    setState(() => _msg = m);
    _src.value = null;
    _t?.cancel();
    _t = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _msg = null);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    _src.removeListener(_on);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 100,
      right: 16,
      bottom: 14,
      child: IgnorePointer(
        ignoring: _msg == null,
        child: AnimatedOpacity(
          opacity: _msg == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: GestureDetector(
              onTap: () => setState(() => _msg = null),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 640),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xF0241C34),
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                      left: BorderSide(color: AppColors.accent, width: 4)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 16)
                  ],
                ),
                child: Text(_msg ?? '',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
