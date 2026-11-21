import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/content2.dart';
import '../../models/models.dart';
import '../../engine/game.dart';
import '../widgets/common.dart';
import '../widgets/company_logo.dart';

/// Şirket adı, kanal adı ve logo oluşturucu (oyun başında ve ayarlardan).
Future<void> showIdentityDialog(BuildContext context, {bool first = false}) =>
    showDialog(
      context: context,
      barrierDismissible: !first,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: AppColors.bg,
        child: _IdentityEditor(first: first),
      ),
    );

class _IdentityEditor extends StatefulWidget {
  final bool first;
  const _IdentityEditor({required this.first});
  @override
  State<_IdentityEditor> createState() => _IdentityEditorState();
}

class _IdentityEditorState extends State<_IdentityEditor> {
  late final TextEditingController _company;
  late final TextEditingController _channel;
  late int _suffix;
  late CompanyLogo _logo;
  int _tab = 0;
  final _rng = Random();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initDone) return;
    _initDone = true;
    final g = GameScope.read(context);
    _company = TextEditingController(
      text: g.identitySet
          ? g.companyName
          : companyNameIdeas[_rng.nextInt(companyNameIdeas.length)],
    );
    _channel = TextEditingController(text: g.channelName);
    _suffix = g.companySuffix;
    _logo = CompanyLogo(
      shape: g.logo.shape,
      palette: g.logo.palette,
      frame: g.logo.frame,
    );
    if (!g.identitySet) _randomize();
  }

  bool _initDone = false;

  void _randomize() {
    _logo = CompanyLogo(
      shape: _rng.nextInt(logoShapeNames.length),
      palette: _rng.nextInt(logoPalettes.length),
      frame: _rng.nextInt(logoFrameNames.length),
    );
  }

  @override
  void dispose() {
    _company.dispose();
    _channel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final full =
        '${_company.text.trim().isEmpty ? 'Şirketim' : _company.text.trim()} '
        '${companySuffixes[_suffix]}';

    final preview = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          key: ValueKey('${_logo.shape}-${_logo.palette}-${_logo.frame}'),
          tween: Tween(begin: 0.6, end: 1),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutBack,
          builder: (_, v, _) => Transform.scale(
            scale: v,
            child: CompanyLogoView(logo: _logo, size: 130, glow: 1),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          full.toUpperCase(),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.5,
            color: logoPalettes[_logo.palette][0],
          ),
        ),
        Text(
          'sunar',
          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          '📺 ${_channel.text.trim().isEmpty ? 'Kanal' : _channel.text.trim()}',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          '$logoCombinations farklı logo mümkün',
          style: const TextStyle(color: AppColors.textFaint, fontSize: 11),
        ),
      ],
    );

    final form = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _company,
                maxLength: 22,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Şirket adı',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: 'İsim öner',
              onPressed: () => setState(
                () => _company.text =
                    companyNameIdeas[_rng.nextInt(companyNameIdeas.length)],
              ),
              icon: const Icon(Icons.casino_rounded, color: AppColors.accent),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _channel,
                maxLength: 18,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Kanal adı',
                  counterText: '',
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            for (int i = 0; i < companySuffixes.length; i++)
              _chip(
                companySuffixes[i],
                i == _suffix,
                () => setState(() => _suffix = i),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            PillTabs(
              labels: const ['Sembol', 'Renk', 'Çerçeve'],
              selected: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const Spacer(),
            GhostButton(
              'Rastgele',
              compact: true,
              icon: Icons.shuffle_rounded,
              onTap: () => setState(_randomize),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              if (_tab == 0)
                for (int i = 0; i < logoShapeNames.length; i++)
                  _logoCell(
                    CompanyLogo(
                      shape: i,
                      palette: _logo.palette,
                      frame: _logo.frame,
                    ),
                    i == _logo.shape,
                    () => setState(() => _logo.shape = i),
                    logoShapeNames[i],
                  ),
              if (_tab == 1)
                for (int i = 0; i < logoPalettes.length; i++)
                  _logoCell(
                    CompanyLogo(
                      shape: _logo.shape,
                      palette: i,
                      frame: _logo.frame,
                    ),
                    i == _logo.palette,
                    () => setState(() => _logo.palette = i),
                    null,
                  ),
              if (_tab == 2)
                for (int i = 0; i < logoFrameNames.length; i++)
                  _logoCell(
                    CompanyLogo(
                      shape: _logo.shape,
                      palette: _logo.palette,
                      frame: i,
                    ),
                    i == _logo.frame,
                    () => setState(() => _logo.frame = i),
                    logoFrameNames[i],
                  ),
            ],
          ),
        ),
      ],
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  widget.first ? '🎬 Yapım şirketini kur' : 'Şirket kimliği',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Her yeni yapımın başında bu logo ekrana gelir.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                ),
                if (!widget.first)
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 230,
                    child: Panel(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFF241A36), Color(0xFF0E0B16)],
                      ),
                      child: Center(
                        child: SingleChildScrollView(child: preview),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: form),
                ],
              ),
            ),
            const SizedBox(height: 8),
            AccentButton(
              widget.first ? 'Şirketi kur ve başla' : 'Kaydet',
              expand: true,
              icon: Icons.check_rounded,
              onTap: () {
                game.setIdentity(
                  company: _company.text,
                  suffix: _suffix,
                  channel: _channel.text,
                  newLogo: _logo,
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: sel ? AppColors.accent.withValues(alpha: 0.25) : AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sel ? AppColors.accent : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: sel ? AppColors.text : AppColors.textDim,
        ),
      ),
    ),
  );

  Widget _logoCell(
    CompanyLogo l,
    bool sel,
    VoidCallback onTap,
    String? label,
  ) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: sel ? AppColors.accent.withValues(alpha: 0.18) : AppColors.panel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: sel ? AppColors.accent : AppColors.border,
          width: sel ? 2 : 1,
        ),
      ),
      child: Tooltip(
        message: label ?? '',
        child: CompanyLogoView(logo: l, size: 60),
      ),
    ),
  );
}

/// Yeni yapım başlarken oynayan kısa logo animasyonu ("… sunar").
class StingOverlay extends StatefulWidget {
  final CompanyLogo logo;
  final String company;
  final String title;
  final VoidCallback onDone;
  const StingOverlay({
    super.key,
    required this.logo,
    required this.company,
    required this.title,
    required this.onDone,
  });
  @override
  State<StingOverlay> createState() => _StingOverlayState();
}

class _StingOverlayState extends State<StingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward().whenComplete(() => widget.onDone());

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = logoPalettes[widget.logo.palette % logoPalettes.length][0];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onDone,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, _) {
          final t = _c.value;
          final fadeIn = (t / 0.15).clamp(0.0, 1.0);
          final fadeOut = ((1 - t) / 0.15).clamp(0.0, 1.0);
          final o = min(fadeIn, fadeOut);
          final scale =
              0.5 +
              0.5 * Curves.easeOutBack.transform((t / 0.35).clamp(0.0, 1.0));
          final textO = ((t - 0.3) / 0.2).clamp(0.0, 1.0) * fadeOut;
          final titleO = ((t - 0.5) / 0.2).clamp(0.0, 1.0) * fadeOut;
          return Container(
            color: Colors.black.withValues(alpha: 0.88 * o),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Opacity(
                  opacity: o,
                  child: Transform.rotate(
                    angle: (1 - scale) * 0.6,
                    child: Transform.scale(
                      scale: scale,
                      child: CompanyLogoView(
                        logo: widget.logo,
                        size: 120,
                        glow: 0.5 + 0.5 * sin(t * pi * 3).abs(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Opacity(
                  opacity: textO,
                  child: Text(
                    widget.company.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 3 + 3 * (1 - textO),
                      color: col,
                    ),
                  ),
                ),
                Opacity(
                  opacity: textO,
                  child: const Text(
                    'sunar',
                    style: TextStyle(color: Colors.white70, letterSpacing: 2),
                  ),
                ),
                const SizedBox(height: 10),
                Opacity(
                  opacity: titleO,
                  child: Text(
                    '“${widget.title}”',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
