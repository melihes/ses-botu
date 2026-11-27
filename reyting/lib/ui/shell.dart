import 'dart:async';

import 'package:flutter/material.dart';

import '../core/format.dart';
import '../engine/game.dart';
import '../core/theme.dart';
import 'dialogs/offline_dialog.dart';
import 'dialogs/settings_dialog.dart';
import 'dialogs/shop_dialog.dart';
import '../core/ads.dart';
import '../core/cloud.dart';
import 'screens/calendar_screen.dart';
import '../data/calendar.dart';
import 'screens/social_screen.dart';
import 'screens/agency_screen.dart';
import 'screens/bank_screen.dart';
import 'screens/board_screen.dart';
import 'screens/map_screen.dart';
import 'dialogs/identity_dialog.dart';
import 'screens/broadcast_screen.dart';
import 'screens/channels_screen.dart';
import 'screens/cinema_screen.dart';
import 'screens/digital_screen.dart';
import 'dialogs/tutorial.dart';
import 'dialogs/events_dialogs.dart';
import 'dialogs/missions_dialog.dart';
import 'screens/trophies_screen.dart';
import 'screens/market_screen.dart';
import 'screens/tenders_screen.dart';
import 'screens/holding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/luxury_screen.dart';
import 'screens/online_screen.dart';
import 'screens/production_screen.dart';
import 'screens/staff_screen.dart';
import 'screens/studio_screen.dart';
import 'widgets/common.dart';
import 'widgets/company_logo.dart';

enum PageId {
  home,
  map,
  agency,
  board,
  brands,
  staff,
  production,
  broadcast,
  cinema,
  digital,
  social,
  calendar,
  studio,
  holding,
  channels,
  tenders,
  market,
  bank,
  luxury,
  trophies,
  online,
}

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
  _NavItem(
    PageId.staff,
    'Kadro',
    'İNSAN KAYNAKLARI',
    'Kadro',
    Icons.groups_rounded,
  ),
  _NavItem(
    PageId.production,
    'Yapım',
    'STÜDYO',
    'Yapımlar',
    Icons.movie_creation_rounded,
  ),
  _NavItem(
    PageId.broadcast,
    'Yayın',
    'CANLI',
    'Yayın akışı',
    Icons.live_tv_rounded,
  ),
  _NavItem(
    PageId.cinema,
    'Sinema',
    'FİLM YAPIM',
    'Sinema & haklar',
    Icons.theaters_rounded,
  ),
  _NavItem(
    PageId.digital,
    'Dijital',
    'VİDEOM',
    'Dijital · YouTuber\'lar',
    Icons.smart_display_rounded,
  ),
  _NavItem(
    PageId.social,
    'Sosyal',
    'GÜNDEM',
    'Sosyal medya',
    Icons.tag_rounded,
  ),
  _NavItem(
    PageId.calendar,
    'Takvim',
    'ÖZEL GÜNLER',
    'Takvim & özel günler',
    Icons.event_rounded,
  ),
  _NavItem(
    PageId.map,
    'Harita',
    'ÇEKİM LOKASYONLARI',
    'Türkiye & dünya haritası',
    Icons.map_rounded,
  ),
  _NavItem(
    PageId.agency,
    'Ajans',
    'GENÇ YETENEKLER',
    'Yetenek ajansı',
    Icons.star_rounded,
  ),
  _NavItem(
    PageId.board,
    'Yönetim',
    'YÖNETİM KURULU',
    'Yönetim kurulu',
    Icons.groups_3_rounded,
  ),
  _NavItem(
    PageId.brands,
    'Markalar',
    'REKLAM VERENLER',
    'Marka teklifleri',
    Icons.handshake_rounded,
  ),
  _NavItem(
    PageId.studio,
    'Stüdyo',
    'TESİSLER',
    'Stüdyo & ekipman',
    Icons.domain_rounded,
  ),
  _NavItem(
    PageId.holding,
    'Holding',
    'YAN İŞLER',
    'Holding',
    Icons.business_center_rounded,
  ),
  _NavItem(
    PageId.channels,
    'Pazar',
    'SATIN ALMA',
    'Kanal & platform pazarı',
    Icons.connected_tv_rounded,
  ),
  _NavItem(
    PageId.tenders,
    'İhaleler',
    'DEVLET PROJELERİ',
    'Devlet ihaleleri',
    Icons.gavel_rounded,
  ),
  _NavItem(
    PageId.market,
    'Borsa',
    'MEDYA BORSASI',
    'Borsa',
    Icons.candlestick_chart_rounded,
  ),
  _NavItem(
    PageId.bank,
    'Banka',
    'FİNANS',
    'Banka',
    Icons.account_balance_rounded,
  ),
  _NavItem(PageId.luxury, 'Lüks', 'YAŞAM', 'Lüks yaşam', Icons.diamond_rounded),
  _NavItem(
    PageId.trophies,
    'Kupalar',
    'BAŞARIMLAR',
    'Kupalar & koleksiyon',
    Icons.emoji_events_rounded,
  ),
  _NavItem(
    PageId.online,
    'Online',
    'SIRALAMA',
    'Online arena',
    Icons.public_rounded,
  ),
];

/// Sol menüde yalnızca 5 ana başlık; alt sayfalar üstte sekme olarak açılır
class _Group {
  final String label;
  final IconData icon;
  final List<PageId> pages;
  const _Group(this.label, this.icon, this.pages);
}

const _groups = [
  _Group('Kanal', Icons.live_tv_rounded,
      [PageId.home, PageId.staff, PageId.production, PageId.broadcast, PageId.cinema, PageId.digital,
        PageId.social, PageId.calendar]),
  _Group('Şirket', Icons.business_rounded,
      [PageId.studio, PageId.map, PageId.agency, PageId.board, PageId.brands, PageId.holding, PageId.channels]),
  _Group('Para', Icons.account_balance_wallet_rounded, [PageId.tenders, PageId.market, PageId.bank]),
  _Group('Yaşam', Icons.diamond_rounded, [PageId.luxury, PageId.trophies]),
  _Group('Online', Icons.public_rounded, [PageId.online]),
];

_Group _groupOf(PageId p) => _groups.firstWhere((g) => g.pages.contains(p));

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
  final PageId initial;
  const Shell({super.key, this.initial = PageId.home});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  // Oyun her açılışta ana ekranda başlar (bkz. docs/DERSLER.md #5)
  late PageId _page = widget.initial;

  @override
  void initState() {
    super.initState();
    Cloud.instance.addListener(_cloudPrompt);
  }

  @override
  void dispose() {
    Cloud.instance.removeListener(_cloudPrompt);
    super.dispose();
  }

  /// Yeni telefonda bulutta daha ileri bir kariyer varsa bir kez sor
  bool _cloudAsked = false;
  void _cloudPrompt() {
    final c = Cloud.instance;
    if (_cloudAsked || c.cloudSaveRaw == null || !mounted) return;
    _cloudAsked = true;
    final game = GameScope.read(context);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || c.cloudSaveRaw == null) return;
      final load = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (d) => AlertDialog(
          title: const Text('☁️ Bulutta kaydın var'),
          content: Text(
            'Bu hesapta daha ileri bir kariyer var (Gün ${c.cloudDay ?? '?'}). '
            'Telefondaki oyun: Gün ${game.day}. Hangisiyle devam edelim?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Telefondakiyle devam')),
            FilledButton(onPressed: () => Navigator.pop(d, true), child: const Text('Buluttakini yükle')),
          ],
        ),
      );
      if (load == true) {
        await c.restoreCloud();
      } else {
        c.dismissCloud();
        c.sync(force: true);
      }
    });
  }

  /// Sayfa değiştir; süresi geldiyse araya reklam girer (reklamsız pakette yok)
  void _go(PageId p) {
    if (p != _page && !GameScope.read(context).noAds) Ads.instance.maybeInterstitial();
    setState(() {
      _page = p;
      _lastInGroup[_groupOf(p).label] = p;
    });
  }
  bool _offlineShowing = false;
  final Map<String, PageId> _lastInGroup = {};

  void _goGroup(_Group g) => _go(_lastInGroup[g.label] ?? g.pages.first);

  Widget _body() => switch (_page) {
    PageId.home => const HomeScreen(),
    PageId.map => const MapScreen(),
    PageId.agency => const AgencyScreen(),
    PageId.board => const BoardScreen(),
    PageId.brands => const BrandsScreen(),
    PageId.staff => const StaffScreen(),
    PageId.production => const ProductionScreen(),
    PageId.broadcast => const BroadcastScreen(),
    PageId.cinema => const CinemaScreen(),
    PageId.digital => const DigitalScreen(),
    PageId.studio => const StudioScreen(),
    PageId.holding => const HoldingScreen(),
    PageId.bank => const BankScreen(),
    PageId.channels => const ChannelsScreen(),
    PageId.luxury => const LuxuryScreen(),
    PageId.market => const MarketScreen(),
    PageId.tenders => const TendersScreen(),
    PageId.trophies => const TrophiesScreen(),
    PageId.online => const OnlineScreen(),
    PageId.social => const SocialScreen(),
    PageId.calendar => const CalendarScreen(),
  };

  bool _introShowing = false;
  bool _eventShowing = false;

  void _maybeShowEvents() {
    if (_eventShowing || _offlineShowing || _introShowing) return;
    final game = GameScope.read(context);
    if (game.pendingAwards == null && game.pendingLogin == null) return;
    _eventShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (game.pendingLogin != null) {
        await showLoginReward(context, game.pendingLogin!);
        game.dismissLogin();
      }
      if (!mounted) return;
      if (game.pendingAwards != null) {
        await showAwardsDialog(context, game, game.pendingAwards!);
        game.dismissAwards();
      }
      _eventShowing = false;
    });
  }

  void _maybeShowIntro() {
    if (_introShowing || _offlineShowing) return;
    _introShowing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final game = GameScope.read(context);
      if (!game.identitySet) await showIdentityDialog(context, first: true);
      if (!mounted) return;
      if (!game.introSeen) await showIntroTutorial(context);
      game.markIntroSeen();
      _introShowing = false;
    });
  }

  static const goalPages = [
    PageId.staff,
    PageId.production,
    PageId.broadcast,
    PageId.broadcast,
    PageId.digital,
    PageId.cinema,
    PageId.studio,
  ];

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
    final setup = !game.introSeen || !game.identitySet;
    if (setup && game.pendingOffline == null) _maybeShowIntro();
    if (!setup && game.pendingOffline == null) _maybeShowEvents();
    final item = _nav.firstWhere((n) => n.id == _page);
    return ShellNav(
      goTo: _go,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Row(
                children: [
                  _Sidebar(
                    selected: _page,
                    onGroup: _goGroup,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBar(
                          section: item.section,
                          title: item.id == PageId.home
                              ? game.channelName
                              : item.title,
                        ),
                        if (_groupOf(_page).pages.length > 1)
                          _SubTabs(group: _groupOf(_page), selected: _page, onTap: _go),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: KeyedSubtree(
                              key: ValueKey(_page),
                              child: _body(),
                            ),
                          ),
                        ),
                        // Görev balonu içeriğin üstüne binmesin: sayfanın altında kendi şeridinde durur
                        if (_page != PageId.home && game.currentGoal >= 0)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CoachBubble(
                                onGo: (i) => _go(goalPages[i]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const Positioned(
                top: 64,
                left: 94,
                right: 10,
                child: Center(child: DecisionCard()),
              ),
              const _ToastHost(),
            const Positioned(left: 94, bottom: 12, child: RewardOfferCard()),
              Positioned.fill(
                child: ValueListenableBuilder<String?>(
                  valueListenable: game.sting,
                  builder: (_, title, _) => title == null
                      ? const SizedBox.shrink()
                      : StingOverlay(
                          key: ValueKey(title),
                          logo: game.logo,
                          company: game.companyFullName,
                          title: title,
                          onDone: () => game.sting.value = null,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final PageId selected;
  final ValueChanged<_Group> onGroup;
  const _Sidebar({required this.selected, required this.onGroup});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      color: AppColors.sidebar,
      child: Column(
        children: [
          // Şirket logosu ve adı her sayfada görünür (dokununca düzenlenir)
          Builder(
            builder: (context) {
              final game = GameScope.of(context);
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showIdentityDialog(context),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                  child: Column(
                    children: [
                      CompanyLogoView(logo: game.logo, size: 38),
                      const SizedBox(height: 3),
                      Text(
                        game.companyFullName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                for (final g in _groups)
                  _SideButton(
                    label: g.label,
                    icon: g.icon,
                    active: g.pages.contains(selected),
                    onTap: () => onGroup(g),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _SideButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.textDim;
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.accent.withValues(alpha: 0.13) : null,
          borderRadius: BorderRadius.circular(12),
          border: active
              ? Border.all(color: AppColors.accent.withValues(alpha: 0.4))
              : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? AppColors.text : AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Seçili ana başlığın alt sayfaları (üstte sekme şeridi)
class _SubTabs extends StatelessWidget {
  final _Group group;
  final PageId selected;
  final ValueChanged<PageId> onTap;
  const _SubTabs({required this.group, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          children: [
            for (final id in group.pages)
              Builder(builder: (_) {
                final n = _nav.firstWhere((x) => x.id == id);
                final on = id == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onTap(id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: on ? AppColors.accent.withValues(alpha: 0.16) : AppColors.panel,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: on ? AppColors.accent.withValues(alpha: 0.6) : AppColors.border),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(n.icon, size: 17, color: on ? AppColors.accent : AppColors.textDim),
                        const SizedBox(width: 6),
                        Text(n.label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                                color: on ? AppColors.text : AppColors.textDim)),
                      ]),
                    ),
                  ),
                );
              }),
          ],
        ),
      );
}

class _TopBar extends StatelessWidget {
  final String section;
  final String title;
  const _TopBar({required this.section, required this.title});

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    return LayoutBuilder(
      builder: (context, c) {
        final narrow = c.maxWidth < 720;
        return Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(section),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Kasa
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SectionLabel('Kasa', color: AppColors.textDim),
                  Text(
                    narrow ? fmtShort(game.cash) : fmtFull(game.cash),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: game.cash < 0 ? AppColors.red : AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showMissionsDialog(context),
                child: Badge(
                  isLabelVisible: game.missions.any(
                    (m) => m.done && !m.claimed,
                  ),
                  backgroundColor: AppColors.green,
                  label: const Text('!'),
                  child: _Chip(
                    icon: Icons.flag_rounded,
                    color: AppColors.accent,
                    text:
                        '${game.missions.where((m) => m.claimed).length}/${game.missions.length}',
                    tooltip: 'Günlük görevler',
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => ShellNav.go(context, PageId.trophies),
                child: _Chip(
                  icon: Icons.star_rounded,
                  color: AppColors.yellow,
                  text: fmtInt(game.prestige),
                  tooltip: 'Prestij',
                ),
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
                onTap: () => showShopDialog(context),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => showSettingsDialog(context),
                icon: const Icon(
                  Icons.settings_rounded,
                  color: AppColors.textDim,
                ),
                tooltip: 'Ayarlar',
              ),
              _DayChip(day: game.day, progress: game.dayProgress),
            ],
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String tooltip;
  const _Chip({
    required this.icon,
    required this.color,
    required this.text,
    required this.tooltip,
  });
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _DayChip extends StatelessWidget {
  final int day;
  final double progress;
  const _DayChip({required this.day, required this.progress});
  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final act = game.activeSpecialDays;
    final narrow = MediaQuery.sizeOf(context).width < 840;
    return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () => ShellNav.go(context, PageId.calendar),
    child: Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
    decoration: BoxDecoration(
      color: AppColors.panel,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: act.isNotEmpty ? AppColors.green : AppColors.border),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 15,
              color: AppColors.cyan,
            ),
            const SizedBox(width: 5),
            Text(
              '${act.isNotEmpty ? '${act.first.$1.emoji} ' : ''}'
              '${narrow ? 'Gün $day' : 'Gün $day · ${dateLabel(day)}'}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: narrow ? 70 : 110,
          child: Bar(progress, color: AppColors.accent, height: 3),
        ),
      ],
    ),
    ),
    );
  }
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
      // bildirim butonların üstünü kapatmasın: dokunuşlar alttaki butona geçer
      child: IgnorePointer(
        ignoring: true,
        child: AnimatedOpacity(
          opacity: _msg == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 640),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xF0241C34),
                borderRadius: BorderRadius.circular(14),
                border: const Border(
                  left: BorderSide(color: AppColors.accent, width: 4),
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black54, blurRadius: 16),
                ],
              ),
              child: Text(
                _msg ?? '',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
