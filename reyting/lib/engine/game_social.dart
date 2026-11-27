part of 'game.dart';

/// 1.1: Kurmaca sosyal medya akışı ve gündem.
extension GameSocial on Game {
  Map<String, dynamic> _socialToJson() => {
    'social': [for (final p in socialFeed.take(40)) p.toJson()],
    'trends': trends,
  };

  void _socialLoad(Map<String, dynamic> j) {
    socialFeed
      ..clear()
      ..addAll([
        for (final p in (j['social'] as List?) ?? const [])
          SocialPost.fromJson(Map<String, dynamic>.from(p as Map)),
      ]);
    trends
      ..clear()
      ..addAll({
        for (final e in ((j['trends'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as num).toDouble(),
      });
  }

  void _socialReset() {
    socialFeed.clear();
    trends.clear();
    _socialRecent.clear();
  }

  /// Programın etiketi: "Gece Yarısı" → #GeceYarısı
  String tagOf(String name) {
    final words = name
        .replaceAll(RegExp(r"[^\wçğıöşüÇĞİÖŞÜ ]"), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty);
    return '#${words.map((w) => w[0].toUpperCase() + w.substring(1)).join()}';
  }

  /// Saatlik: izleyiciler yazar
  void _socialTick() {
    if (_offlineMode) return;
    if (_rng.nextDouble() > 0.55) return;
    final onAir = shows.where((s) => s.status == ShowStatus.onAir).toList();
    final r = _rng.nextDouble();
    if (onAir.isNotEmpty && r < 0.75) {
      // izleyici sayısına göre ağırlıklı seçim
      final w = [for (final s in onAir) max(1.0, viewers(s))];
      var pick = _rng.nextDouble() * w.fold(0.0, (a, b) => a + b);
      var s = onAir.first;
      for (int i = 0; i < onAir.length; i++) {
        pick -= w[i];
        if (pick <= 0) {
          s = onAir[i];
          break;
        }
      }
      _post(_moodTopic(s, onAir), show: s);
    } else if (r < 0.88 && activeSpecialDays.any((e) => !e.$1.world)) {
      final d = activeSpecialDays.firstWhere((e) => !e.$1.world).$1;
      _post(SocialTopic.holiday, extra: d.name);
    } else if (r < 0.94 && films.any((f) => f.status == FilmStatus.inTheaters)) {
      final f = films.firstWhere((f) => f.status == FilmStatus.inTheaters);
      _post(SocialTopic.film, extra: f.name, mood: f.score >= 6 ? 1 : (f.score < 4.5 ? -1 : 0));
    } else {
      _post(SocialTopic.random);
    }
  }

  /// Program iyi mi kötü mü gidiyor: diğer yayınlara göre reyting
  SocialTopic _moodTopic(Show s, List<Show> onAir) {
    final avg = onAir.fold(0.0, (a, x) => a + currentRating(x)) / onAir.length;
    final rel = avg <= 0 ? 1.0 : currentRating(s) / avg;
    final lift = (rel - 1) * 0.8 + (s.buff - 1) * 1.5 + s.loyalty * 0.5;
    final pHit = (0.30 + lift).clamp(0.10, 0.80);
    final pFlop = (0.18 - lift).clamp(0.04, 0.60);
    final x = _rng.nextDouble();
    if (x < pHit) return SocialTopic.hit;
    if (x < pHit + pFlop) return SocialTopic.flop;
    return SocialTopic.average;
  }

  T _pickS<T>(List<T> l) => l[_rng.nextInt(l.length)];

  String _socialHandle(String first) {
    final f = first.toLowerCase();
    final l = _pickS(lastNames).toLowerCase();
    final w = _pickS(socialWords);
    var w2 = _pickS(socialWords);
    if (w2 == w) w2 = '${w2}li';
    final n = _rng.nextBool() ? _pickS(socialPlates) : '${10 + _rng.nextInt(89)}';
    return _pickS(socialStyles)
        .replaceAll('{w2}', w2)
        .replaceAll('{w}', w)
        .replaceAll('{f}', f)
        .replaceAll('{l}', l.isEmpty ? 'x' : l.substring(0, min(3, l.length)))
        .replaceAll('{n}', n)
        .replaceAll(RegExp(r"[^a-z0-9_.çğıöşü]"), '');
  }

  /// Bir paylaşım üret ve akışa ekle
  void _post(SocialTopic topic, {Show? show, String? extra, int? mood}) {
    if (_offlineMode) return;
    final bodies = socialBodies[topic]!;
    // son kullanılanları seçme (aynı yazılar tekrar etmesin)
    final fresh = [
      for (int i = 0; i < bodies.length; i++)
        if (!_socialRecent.contains(topic.index * 1000 + i)) i,
    ];
    final bi = fresh.isEmpty ? _rng.nextInt(bodies.length) : _pickS(fresh);
    _socialRecent.add(topic.index * 1000 + bi);
    while (_socialRecent.length > 60) {
      _socialRecent.removeAt(0);
    }

    // programdaki kişiler
    String? host, actor;
    if (show != null) {
      for (final id in show.staffIds) {
        final p = staffById(id);
        if (p == null) continue;
        final first = p.name.split(' ').first;
        if (p.role == Role.sunucu) host ??= first;
        if (p.role == Role.oyuncu) actor ??= first;
      }
    }
    host ??= actor ?? _pickS(firstNames);
    actor ??= host;
    final guest = show?.guestName ?? actor;
    final values = {
      'show': show?.name ?? channelName,
      'tag': show == null ? tagOf(channelName) : tagOf(show.name),
      'host': host,
      'actor': actor,
      'guest': guest,
      'channel': channelName,
      'extra': extra ?? '',
      'slot': show?.slot == null ? 'akşam' : slotDefs[show!.slot]!.label,
    };
    var body = bodies[bi].replaceAllMapped(RegExp(r'\{(\w+)(?::(\w+))?\}'), (m) {
      final v = values[m.group(1)] ?? '';
      return m.group(2) == null ? v : trEk(v, m.group(2)!);
    });

    final moodV = mood ??
        switch (topic) {
          SocialTopic.flop || SocialTopic.crisisFail => -1,
          SocialTopic.average || SocialTopic.random || SocialTopic.drama || SocialTopic.film => 0,
          _ => 1,
        };
    final opener = _pickS(socialOpeners);
    if (opener.isNotEmpty) {
      body = '$opener $body';
    }
    final closer = _pickS(socialClosers);
    // kapanış cümlesi gelecekse gövde noktayla bitsin
    if (closer.isNotEmpty && !RegExp(r'[.!?…]$').hasMatch(body)) body = '$body${_rng.nextBool() ? '.' : '!'}';
    final emojis = moodV > 0
        ? socialEmojisGood
        : (moodV < 0 ? socialEmojisBad : socialEmojisNeutral);
    final e1 = _pickS(emojis);
    final e2 = _rng.nextDouble() < 0.35 ? _pickS(emojis) : '';
    final tags = <String>[
      if (show != null) values['tag']!,
      if (show == null && extra != null && extra.isNotEmpty) tagOf(extra),
      if (_rng.nextDouble() < 0.45) _pickS(socialExtraTags[topic]!),
    ];
    final text = [
      body[0].toUpperCase() + body.substring(1),
      if (closer.isNotEmpty) closer,
      '$e1$e2',
      ...tags,
    ].join(' ');

    // kim yazdı
    final first = _pickS(firstNames);
    final female = genderOfName(first) == 1;
    final lastName = _pickS(lastNames);
    final style = _rng.nextInt(10);
    final name = style < 5
        ? '$first ${lastName.isEmpty ? '' : '${lastName[0]}.'}'
        : (style < 8 ? '$first $lastName' : '$first ${_pickS(['🌙', '☕', '🎬', '📺', '🌸', '⚽', '🎧', '✨'])}');
    // etkileşim: büyük programlar daha çok konuşulur
    final reachV = show == null ? 0.5 : (viewers(show) / 1e6).clamp(0.2, 12.0);
    final base = (8 + _rng.nextDouble() * 120) * (1 + reachV) * (topic == SocialTopic.viral ? 6 : 1);
    final likes = (base * (moodV != 0 ? 1.4 : 1)).round();
    final shares = (likes * (0.05 + _rng.nextDouble() * 0.25)).round();
    socialFeed.insert(
      0,
      SocialPost(
        day: day,
        hour: (dayProgress * 24).floor().clamp(0, 23),
        name: name.trim(),
        handle: '@${_socialHandle(first)}',
        text: text,
        likes: likes,
        shares: shares,
        mood: moodV,
        seed: _rng.nextInt(1 << 30),
        female: female,
      ),
    );
    if (socialFeed.length > 80) socialFeed.removeRange(80, socialFeed.length);
    // gündem puanı
    for (final t in tags) {
      if (t.startsWith('#')) trends[t] = (trends[t] ?? 0) + likes + shares * 3;
    }
  }

  /// Seyircinin programdan keyfi 0..1 (0.5 normal): diğer yayınlara göre reyting,
  /// geçici etkiler (viral, kriz), sadakat, gündem ve kadro değişikliği
  double audienceMood(Show s) {
    if (s.status != ShowStatus.onAir) return 0.5;
    final onAir = shows.where((x) => x.status == ShowStatus.onAir).toList();
    final avg = onAir.fold(0.0, (a, x) => a + currentRating(x)) / max(1, onAir.length);
    final rel = avg <= 0 ? 1.0 : currentRating(s) / avg;
    var m = 0.5 + (rel - 1) * 0.6 + (s.buff - 1) * 1.6 + s.loyalty * 0.8 - (1 - castShockMult(s)) * 0.8;
    if (trendRankOf(s) == 1) m += 0.15;
    // sezon sonuna doğru hikâye eskir
    m -= s.seasonProgress * 0.1;
    return m.clamp(0.0, 1.0).toDouble();
  }

  /// "Sen yokken" bülteni için ek başlıklar ve dönüşte sosyal medya
  void _bulletin(PeriodSummary sum, int dayBefore) {
    final h = sum.headlines;
    final onAir = shows.where((s) => s.status == ShowStatus.onAir).toList()
      ..sort((a, b) => currentRating(b).compareTo(currentRating(a)));
    if (onAir.isNotEmpty) {
      final top = onAir.first;
      h.insert(0, (
        '📊 Zirvede "${top.name}" var',
        'Dün akşam ${fmtPct(currentRating(top), 2)} reytingle ${channelName} ekranlarının bir numarası oldu.',
        true,
      ));
    } else {
      h.insert(0, ('📺 Ekranlar boş kaldı', '$channelName yayın akışında program yok; izleyici rakiplere kaydı.', false));
    }
    final delta = sum.cashAfter - sum.cashBefore;
    h.add((
      delta >= 0 ? '💰 Kasa büyüdü' : '📉 Kasa eridi',
      '${sum.days} günde ${fmtSigned(delta)}. Ayrıntılar raporda.',
      delta >= 0,
    ));
    // geçen özel günler
    for (final d in specialDays) {
      if (!specialAvailable(d)) continue;
      final a = d.activeStart(day) ?? d.activeStart(max(1, day - 1));
      if (a != null && a > dayBefore) {
        h.add(('${d.emoji} ${d.name} başladı', d.desc, true));
        break;
      }
    }
    final tr = trendList;
    if (tr.isNotEmpty) h.add(('🔥 Gündem: ${tr.first.key}', 'Sosyal medyada en çok konuşulan konu buydu.', true));
    // aynı başlık birden çok kez olduysa birleştir (en yenisinin ayrıntısıyla), en fazla 10 haber
    final merged = <String, (String, String, bool)>{};
    final count = <String, int>{};
    for (final x in h) {
      merged[x.$1] = x;
      count[x.$1] = (count[x.$1] ?? 0) + 1;
    }
    h
      ..clear()
      ..addAll([
        for (final e in merged.entries)
          (count[e.key]! > 1 ? '${e.key} (${count[e.key]} kez)' : e.key, e.value.$2, e.value.$3),
      ].take(10));
    // dönüşte izleyiciler yazmaya devam eder
    for (final s in onAir.take(2)) {
      _post(_moodTopic(s, onAir), show: s);
    }
  }

  /// Gündem listesi (en çok konuşulan etiketler)
  List<MapEntry<String, double>> get trendList {
    final l = trends.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return l.take(8).toList();
  }

  /// Programın gündemdeki sırası (yoksa null)
  int? trendRankOf(Show s) {
    final t = tagOf(s.name);
    final l = trendList;
    for (int i = 0; i < l.length; i++) {
      if (l[i].key == t) return i + 1;
    }
    return null;
  }

  void _socialDaily() {
    // gündem 1 numarası olan program izleyici kazanır
    final l = trendList;
    if (l.length >= 2 && l[0].value > l[1].value * 1.25) {
      for (final s in shows) {
        if (s.status == ShowStatus.onAir && tagOf(s.name) == l[0].key && s.buffDays == 0) {
          s.buff = 1.07;
          s.buffDays = 1;
          _log('🔥 Gündemde 1 numara', '${l[0].key} sosyal medyada en çok konuşulan: "${s.name}" 1 gün +%7.', true);
          break;
        }
      }
    }
    // gündem eskir
    trends.updateAll((k, v) => v * 0.45);
    trends.removeWhere((k, v) => v < 5);
  }
}
