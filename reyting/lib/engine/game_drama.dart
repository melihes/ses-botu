part of 'game.dart';

/// Kadrodaki iki kişi arasındaki ilişki
enum Bond { ask, kavga, dost, mentor }

const bondInfo = {
  Bond.ask: ('❤️', 'Aşk', 0.04),
  Bond.kavga: ('⚡', 'Küs', -0.06),
  Bond.dost: ('🤝', 'Dost', 0.02),
  Bond.mentor: ('🎓', 'Usta-çırak', 0.01),
};

/// Kulis dramaları sıklığı: 0 kapalı, 1 az, 2 normal, 3 çok
const dramaLevelNames = ['Kapalı', 'Az', 'Normal', 'Çok'];

/// 1.1: Kulis dramaları (kadro ilişkileri). Sıklığı Ayarlar'dan seçilir;
/// iki drama arasında en az birkaç gün geçer, can sıkmasın.
extension GameDrama on Game {
  Map<String, dynamic> _dramaToJson() => {
    'dramaLevel': dramaLevel,
    'dramaLast': dramaLastDay,
    'bonds': bonds,
  };

  void _dramaLoad(Map<String, dynamic> j) {
    dramaLevel = ((j['dramaLevel'] as num?) ?? 1).toInt().clamp(0, 3);
    dramaLastDay = j['dramaLast'] ?? 0;
    bonds
      ..clear()
      ..addAll(Map<String, String>.from((j['bonds'] as Map?) ?? const {}));
  }

  void _dramaReset() {
    dramaLastDay = 0;
    bonds.clear();
  }

  void setDramaLevel(int v) {
    dramaLevel = v.clamp(0, 3);
    _changed();
  }

  String _pair(String a, String b) => a.compareTo(b) < 0 ? '$a|$b' : '$b|$a';

  Bond? bondOf(String a, String b) {
    final v = bonds[_pair(a, b)];
    if (v == null) return null;
    final i = int.tryParse(v.split(':').first) ?? -1;
    return i >= 0 && i < Bond.values.length ? Bond.values[i] : null;
  }

  void _setBond(String a, String b, Bond? bond) {
    if (bond == null) {
      bonds.remove(_pair(a, b));
    } else {
      bonds[_pair(a, b)] = '${bond.index}:$day';
    }
  }

  /// Bir kişinin ilişkileri (ekranda simge olarak)
  List<(Bond, Staff)> bondsOf(Staff p) {
    final out = <(Bond, Staff)>[];
    for (final k in bonds.keys) {
      final ids = k.split('|');
      if (!ids.contains(p.id)) continue;
      final other = staffById(ids.first == p.id ? ids.last : ids.first);
      final b = bondOf(ids.first, ids.last);
      if (other != null && b != null) out.add((b, other));
    }
    return out;
  }

  /// İlişkilerin programa etkisi: aynı programdaki çiftler
  double dramaMult(Show s) {
    if (bonds.isEmpty) return 1;
    var m = 1.0;
    final ids = s.staffIds;
    for (int i = 0; i < ids.length; i++) {
      for (int k = i + 1; k < ids.length; k++) {
        final b = bondOf(ids[i], ids[k]);
        if (b != null) m *= 1 + bondInfo[b]!.$3;
      }
    }
    return m.clamp(0.8, 1.2).toDouble();
  }

  int get _dramaCooldown => const [999, 8, 5, 3][dramaLevel];
  double get _dramaChance => const <double>[0, 0.30, 0.45, 0.6][dramaLevel];

  void _dramaDaily() {
    // ilişkisi olanlardan biri ayrıldıysa temizle
    bonds.removeWhere((k, v) => k.split('|').any((id) => staffById(id) == null));
    // usta-çırak: çırak her gün biraz gelişir
    for (final k in bonds.keys) {
      if (bondOf(k.split('|').first, k.split('|').last) != Bond.mentor) continue;
      for (final id in k.split('|')) {
        final p = staffById(id);
        if (p != null && p.age <= 25 && p.skill < p.potential) p.xp += 0.08;
      }
    }
    if (dramaLevel == 0 || _offlineMode) return;
    if (day - dramaLastDay < _dramaCooldown) return;
    if (pendingDecision != null) return;
    if (_rng.nextDouble() > _dramaChance) return;
    if (_rollDrama()) dramaLastDay = day;
  }

  /// Aynı programda birlikte çalışan çiftler
  List<(Show, Staff, Staff)> _pairsOnShows() {
    final out = <(Show, Staff, Staff)>[];
    for (final s in shows) {
      if (s.status != ShowStatus.onAir && s.status != ShowStatus.producing) continue;
      final crew = s.staffIds.map(staffById).whereType<Staff>().toList();
      for (int i = 0; i < crew.length; i++) {
        for (int k = i + 1; k < crew.length; k++) {
          out.add((s, crew[i], crew[k]));
        }
      }
    }
    return out;
  }

  String _fn(Staff p) => p.name.split(' ').first;

  bool _rollDrama() {
    final pairs = _pairsOnShows()..shuffle(_rng);
    final stars = staff.where((p) => p.skill >= 78 || p.fame >= 55).toList()..shuffle(_rng);
    final kind = _rng.nextInt(8);
    switch (kind) {
      case 0: // aşk
        for (final (s, a, b) in pairs) {
          if (bondOf(a.id, b.id) != null) continue;
          if (genderOfName(a.name) == genderOfName(b.name)) continue;
          return _offerDecision(Decision(
            kind: 'drama_ask',
            title: '❤️ Sette aşk doğuyor',
            body: '"${s.name}" setinde ${_fn(a)} ile ${_fn(b)} birbirlerine çok yakın. Magazin kokusunu aldı!',
            options: ['Basına açıklayın', 'Gizli kalsın', 'Ayrı projelere'],
            hints: ['3 gün reyting +%12, ilişki kurulur', 'İlişki kurulur (+%4 birlikteyken)', 'Risk yok, ilişki olmaz'],
            targetId: s.id,
            extra: '${a.id}|${b.id}',
            defaultOption: 1,
          ));
        }
      case 1: // kavga
        for (final (s, a, b) in pairs) {
          final cur = bondOf(a.id, b.id);
          if (cur == Bond.kavga || cur == Bond.mentor) continue;
          final cost = (a.salary + b.salary) * 6;
          return _offerDecision(Decision(
            kind: 'drama_kavga',
            title: '⚡ Kulis kavgası',
            body: '"${s.name}" setinde ${_fn(a)} ile ${_fn(b)} sahne sırası yüzünden birbirine girdi.',
            options: ['Arabulucu tut', 'Ceza kes', 'Görmezden gel'],
            hints: ['${fmtShort(cost)}, dost olurlar', 'İkisinin de şöhreti -5, sorun biter', 'Küs kalırlar (-%6 birlikteyken)'],
            targetId: s.id,
            extra: '${a.id}|${b.id}',
            amount: cost,
            defaultOption: 2,
          ));
        }
      case 2: // yıldız talebi
        for (final p in stars) {
          if (p.showId == null) continue;
          final cost = p.salary * 12;
          final what = [
            'kendine özel bir karavan',
            'setinde kişisel aşçı',
            'adının afişte en üstte yazmasını',
            'her gün taze çiçek',
            'özel şoför ve araç',
            'set saatlerinin öğleden sonra başlamasını',
          ][_rng.nextInt(6)];
          return _offerDecision(Decision(
            kind: 'drama_talep',
            title: '💅 Yıldızın talepleri',
            body: '${p.name} $what istiyor. "Yoksa sete gelmem!" diyor.',
            options: ['Kabul et', 'Reddet', 'Yarısını ver'],
            hints: ['${fmtShort(cost)}, mutlu olur (şöhret +4)', '%50 ihtimalle 3 gün -%10', '${fmtShort(cost / 2)}, %70 ikna olur'],
            targetId: p.id,
            amount: cost,
            defaultOption: 1,
          ));
        }
      case 3: // rakip teklif
        for (final p in stars) {
          final rival = rivalDefs[_rng.nextInt(rivalDefs.length)].name;
          return _offerDecision(Decision(
            kind: 'drama_teklif',
            title: '📨 Rakipten gizli teklif',
            body: '$rival, ${p.name} için iki katı maaş teklif etti! Menajeri cevap bekliyor.',
            options: ['%30 zam yap', 'Pazarlık et', 'Gitsin'],
            hints: ['Kalır, maaş +%30', '%55 +%15 ile kalır, yoksa gider', 'Ayrılır, ${fmtShort(p.salary * 20)} bonservis alırsın'],
            targetId: p.id,
            extra: rival,
            defaultOption: 0,
          ));
        }
      case 4: // kıskançlık
        for (final (s, a, b) in pairs) {
          if ((a.fame - b.fame).abs() < 25) continue;
          final low = a.fame < b.fame ? a : b;
          final high = low == a ? b : a;
          final cost = productionCost(s.genre, s.tier) * 0.12;
          return _offerDecision(Decision(
            kind: 'drama_kiskanc',
            title: '😒 Kıskançlık krizi',
            body: '${_fn(low)}, "${s.name}" afişinde ${_fn(high)} kadar yer almadığı için küstü.',
            options: ['Eşit tanıtım yap', 'Konuş, ikna et', 'Boş ver'],
            hints: ['${fmtShort(cost)}, ${_fn(low)} şöhret +8', '%60 ikna olur, olmazsa küs kalırlar', 'Küs kalırlar'],
            targetId: s.id,
            extra: '${low.id}|${high.id}',
            amount: cost,
            defaultOption: 2,
          ));
        }
      case 5: // usta-çırak
        for (final (s, a, b) in pairs) {
          final senior = a.skill >= b.skill ? a : b;
          final junior = senior == a ? b : a;
          if (senior.skill < 65 || junior.age > 25 || bondOf(a.id, b.id) != null) continue;
          return _offerDecision(Decision(
            kind: 'drama_mentor',
            title: '🎓 Usta-çırak ilişkisi',
            body: '${_fn(senior)}, genç ${_fn(junior)} ile ilgileniyor; ona her gün çalışma veriyor.',
            options: ['Destekle', 'Karışma'],
            hints: ['${_fn(junior)} daha hızlı gelişir', 'Bir şey olmaz'],
            targetId: s.id,
            extra: '${senior.id}|${junior.id}',
            defaultOption: 0,
          ));
        }
      case 6: // ayrılık (aşk bitiyor)
        for (final (s, a, b) in pairs) {
          if (bondOf(a.id, b.id) != Bond.ask) continue;
          _setBond(a.id, b.id, Bond.kavga);
          _buffCombine(s, 1.08, 2);
          _event('💔 Sette ayrılık', '${_fn(a)} ile ${_fn(b)} ayrıldı! Magazin çalkalanıyor: "${s.name}" 2 gün +%8 ama artık küsler.', true);
          _post(SocialTopic.drama, show: s, extra: '${_fn(a)} ile ${_fn(b)} ayrıldı');
          return true;
        }
      default: // sette şaka viral
        for (final (s, a, b) in pairs) {
          if (bondOf(a.id, b.id) != null) continue;
          _setBond(a.id, b.id, Bond.dost);
          _buffCombine(s, 1.06, 2);
          _event('😂 Kamera arkası viral', '${_fn(a)} ile ${_fn(b)} sette birbirine şaka yaptı, video milyonlarca izlendi. "${s.name}" 2 gün +%6.', true);
          _post(SocialTopic.drama, show: s, extra: '${_fn(a)} ile ${_fn(b)} sette kahkaha krizine girdi');
          return true;
        }
    }
    return false;
  }

  String _resolveDrama(Decision d, int option) {
    final ids = d.extra.split('|');
    final a = ids.isNotEmpty ? staffById(ids.first) : null;
    final b = ids.length > 1 ? staffById(ids.last) : null;
    final s = d.targetId == null ? null : showById(d.targetId);
    final p = d.targetId == null ? null : staffById(d.targetId!);
    switch (d.kind) {
      case 'drama_ask':
        if (a == null || b == null) return 'Çift artık kadroda değil.';
        if (option == 0) {
          _setBond(a.id, b.id, Bond.ask);
          if (s != null) _buffCombine(s, 1.12, 3);
          a.fame = min(100, a.fame + 4);
          b.fame = min(100, b.fame + 4);
          if (s != null) _post(SocialTopic.drama, show: s, extra: '${_fn(a)} ile ${_fn(b)} aşk yaşıyor');
          return 'Aşk ilan edildi! 3 gün reyting +%12, ikisinin şöhreti arttı.';
        }
        if (option == 1) {
          _setBond(a.id, b.id, Bond.ask);
          return 'İlişki gizli kaldı. Birlikte çalıştıkça +%4.';
        }
        return 'İkisi farklı projelere yönlendirilecek.';
      case 'drama_kavga':
        if (a == null || b == null) return 'Kavga edenler artık kadroda değil.';
        if (option == 0) {
          if (cash < d.amount) {
            _setBond(a.id, b.id, Bond.kavga);
            return 'Arabulucu için para yetmedi, küs kaldılar.';
          }
          cash -= d.amount;
          _setBond(a.id, b.id, Bond.dost);
          return 'Arabulucu barıştırdı, artık dostlar! (+%2 birlikteyken)';
        }
        if (option == 1) {
          a.fame = max(0, a.fame - 5);
          b.fame = max(0, b.fame - 5);
          _setBond(a.id, b.id, null);
          return 'Ceza kesildi, sorun kapandı. Şöhretleri -5.';
        }
        _setBond(a.id, b.id, Bond.kavga);
        if (s != null) _post(SocialTopic.drama, show: s, extra: '${_fn(a)} ile ${_fn(b)} sette küs');
        return 'Küs kaldılar. Aynı programda -%6.';
      case 'drama_talep':
        if (p == null) return 'Artık kadroda değil.';
        if (option == 0 || (option == 2 && _rng.nextDouble() < 0.7)) {
          final c = option == 0 ? d.amount : d.amount / 2;
          if (cash < c) return 'Kasada para yok, talep karşılanamadı.';
          cash -= c;
          p.fame = min(100, p.fame + 4);
          return '${p.name} mutlu, sete şarkı söyleyerek geldi.';
        }
        if (option == 2) cash -= min(max(cash, 0.0), d.amount / 2);
        final sh = showById(p.showId);
        if (_rng.nextBool() && sh != null) {
          _buffCombine(sh, 0.90, 3);
          _post(SocialTopic.drama, show: sh, extra: '${p.name} setten kaçtı');
          return '${p.name} sete gelmedi! "${sh.name}" 3 gün -%10.';
        }
        return '${p.name} söylendi ama sete geldi.';
      case 'drama_teklif':
        if (p == null) return 'Artık kadroda değil.';
        if (option == 0) {
          _replaceSalary(p, p.salary * 1.3);
          return '${p.name} kaldı, maaşı %30 arttı.';
        }
        if (option == 1 && _rng.nextDouble() < 0.55) {
          _replaceSalary(p, p.salary * 1.15);
          return 'Pazarlık başarılı: ${p.name} %15 zamla kaldı.';
        }
        final fee = p.salary * 20;
        _cashIn(fee); // günlük gelir sayılmaz
        _quit(p);
        return '${p.name}, ${d.extra} kanalına geçti. Bonservis: +${fmtShort(fee)}';
      case 'drama_kiskanc':
        if (a == null || b == null) return 'Artık kadroda değiller.';
        if (option == 0 && cash >= d.amount) {
          cash -= d.amount;
          a.fame = min(100, a.fame + 8);
          return '${_fn(a)} afişte yerini aldı, şöhreti arttı.';
        }
        if (option == 1 && _rng.nextDouble() < 0.6) return '${_fn(a)} ikna oldu, sorun yok.';
        _setBond(a.id, b.id, Bond.kavga);
        return '${_fn(a)} ile ${_fn(b)} küs. Aynı programda -%6.';
      case 'drama_mentor':
        if (a == null || b == null) return '';
        if (option == 0) {
          _setBond(a.id, b.id, Bond.mentor);
          return '${_fn(b)}, ${_fn(a)} sayesinde daha hızlı gelişecek.';
        }
        return 'Kendi hallerine bırakıldılar.';
    }
    return '';
  }
}
