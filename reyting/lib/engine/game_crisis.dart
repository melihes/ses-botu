part of 'game.dart';

/// Canlı yayında çıkan kriz (seçenekler ve hesaplanmış şanslar)
class LiveCrisis {
  final CrisisDef def;
  final String title;
  final String desc;
  final List<CrisisOption> options;
  final List<double> chances;
  final Map<String, String> names;
  LiveCrisis(this.def, this.title, this.desc, this.options, this.chances, this.names);

  String fill(String t) => t.replaceAllMapped(RegExp(r'\{(\w+)(?::(\w+))?\}'), (m) {
    final v = names[m.group(1)] ?? '';
    return m.group(2) == null ? v : trEk(v, m.group(2)!);
  });
}

/// Krizin sonucu (animasyon için)
class CrisisOutcome {
  final bool win;
  final String text;
  final double ratingDelta; // +0.22 = %22 artış
  final int option; // -1: süre doldu
  const CrisisOutcome(this.win, this.text, this.ratingDelta, this.option);
}

/// 1.1: Canlı yayın kriz anları.
extension GameCrisis on Game {
  static const crisisPerDay = 3;

  Map<String, dynamic> _crisisToJson() => {
    'crisisDay': crisisDay,
    'crisisCount': crisisCount,
    'crisisShow': crisisShowDay,
  };

  void _crisisLoad(Map<String, dynamic> j) {
    crisisDay = j['crisisDay'] ?? 0;
    crisisCount = j['crisisCount'] ?? 0;
    crisisShowDay
      ..clear()
      ..addAll(Map<String, int>.from((j['crisisShow'] as Map?) ?? const {}));
  }

  void _crisisReset() {
    crisisDay = 0;
    crisisCount = 0;
    crisisShowDay.clear();
  }

  /// Bugün bu programda kriz çıkabilir mi (günde en çok 3, programa 1)
  bool crisisAllowed(Show s) =>
      s.status == ShowStatus.onAir &&
      (crisisDay != day || crisisCount < crisisPerDay) &&
      crisisShowDay[s.id] != day;

  /// Programın kriz yöneticisi: sunucu, yoksa oyuncular
  (String, int) _crisisLead(Show s) {
    Staff? best;
    for (final id in s.staffIds) {
      final p = staffById(id);
      if (p == null) continue;
      final pri = p.role == Role.sunucu ? 2 : (p.role == Role.oyuncu ? 1 : 0);
      final bp = best == null ? -1 : (best.role == Role.sunucu ? 2 : (best.role == Role.oyuncu ? 1 : 0));
      if (pri > bp || (pri == bp && p.skill > best!.skill)) best = p;
    }
    return (best?.name.split(' ').first ?? 'Sunucu', best?.skill ?? 40);
  }

  LiveCrisis? rollCrisis(Show s) {
    if (!crisisAllowed(s)) return null;
    final own = crisisDefs.where((c) => c.genres.contains(s.genre)).toList();
    final any = crisisDefs.where((c) => c.genres.isEmpty).toList();
    final pool = own.isNotEmpty && _rng.nextDouble() < 0.6 ? own : any;
    final def = pool[_rng.nextInt(pool.length)];
    final (lead, skill) = _crisisLead(s);
    String? actor;
    for (final id in s.staffIds) {
      final p = staffById(id);
      if (p != null && p.role == Role.oyuncu) {
        actor = p.name.split(' ').first;
        break;
      }
    }
    final names = {
      'host': lead,
      'guest': s.guestName ?? actor ?? firstNames[_rng.nextInt(firstNames.length)],
      'actor': actor ?? lead,
      'show': s.name,
    };
    // sunucunun yeteneği ve şöhreti şansı artırır
    final chances = [
      for (final o in def.options)
        (o.base + (skill - 50) / 100 * o.skill + execBonus(ExecRole.yayin) * 0.3).clamp(0.05, 0.95).toDouble(),
    ];
    final c = LiveCrisis(def, def.title, '', def.options, chances, names);
    return LiveCrisis(def, c.fill(def.title), c.fill(def.desc), def.options, chances, names);
  }

  /// Kriz kararı: [option] -1 ise süre doldu (en kötü sonuç)
  CrisisOutcome resolveCrisis(Show s, LiveCrisis c, int option) {
    if (crisisDay != day) {
      crisisDay = day;
      crisisCount = 0;
    }
    crisisCount++;
    crisisShowDay[s.id] = day;
    crisisShowDay.removeWhere((k, v) => v < day - 2);

    final timeout = option < 0;
    final o = timeout ? null : c.options[option];
    final win = !timeout && _rng.nextDouble() < c.chances[option];
    final CrisisOutcome out;
    if (win) {
      final up = 0.22 * o!.reward;
      _buffCombine(s, 1 + up, 2);
      bonusPrestige += (o.reward * 3).round();
      out = CrisisOutcome(true, c.fill(o.win), up, option);
      _post(SocialTopic.crisisWin, show: s, extra: c.def.title.replaceAll('!', '').toLowerCase());
      _log('${c.def.emoji} Canlı yayın anı', '"${s.name}": ${out.text} (2 gün +%${(up * 100).round()})', true);
    } else {
      final down = 0.08 * (o?.risk ?? 1.3);
      _buffCombine(s, 1 - down, 1);
      out = CrisisOutcome(
        false,
        timeout ? c.fill('{host} donup kaldı, kimse ne yapacağını bilemedi.') : c.fill(o!.fail),
        -down,
        option,
      );
      _post(SocialTopic.crisisFail, show: s, extra: c.def.title.replaceAll('!', '').toLowerCase());
      _log('${c.def.emoji} Canlı yayın kazası', '"${s.name}": ${out.text} (1 gün -%${(down * 100).round()})', false);
    }
    _changed();
    return out;
  }

  /// Geçici reyting etkisini mevcut etkiyle birleştir
  void _buffCombine(Show s, double mult, int days) {
    if (s.buffDays > 0) {
      s.buff = (s.buff * mult).clamp(0.6, 1.7).toDouble();
      s.buffDays = max(s.buffDays, days);
    } else {
      s.buff = mult;
      s.buffDays = days;
    }
  }
}
