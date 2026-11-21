import 'dart:math';

import '../data/content.dart';

/// Canlı izleme ekranındaki tek bir an: kim ne dedi, seyirci ne yaptı.
class LiveBeat {
  final int side; // 0 sol (sunucu/ev sahibi), 1 sağ (konuk/yarışmacı), 2 anlatıcı/alt bant
  final String who;
  final String text;
  final int reaction; // 0 yok, 1 kahkaha, 2 alkış/coşku, 3 şaşkınlık
  final String? ticker; // alt bantta kayacak haber
  const LiveBeat(this.side, this.who, this.text, {this.reaction = 0, this.ticker});
}

/// Canlı skor / durum tabelası
class LiveBoard {
  final String leftName, rightName;
  final int left, right;
  final String? extra; // dakika, soru no, ödül…
  const LiveBoard(this.leftName, this.left, this.rightName, this.right, {this.extra});
}

/// Programın türüne ve formatına göre sonsuz canlı yayın akışı üretir.
/// Gerçek kadro isimlerini kullanır (sunucu, oyuncular, ünlü konuk).
class LiveScript {
  final Genre genre;
  final Prop prop;
  final String host;
  final String guest;
  final List<String> cast;
  final Random _r;
  LiveScript({
    required this.genre,
    required this.prop,
    required this.host,
    required this.guest,
    required this.cast,
    int seed = 1,
  }) : _r = Random(seed);

  final List<LiveBeat> _queue = [];
  int _a = 0, _b = 0; // skorlar
  int _minute = 0, _round = 0;
  int _prize = 0;
  LiveBoard? board;

  T _pick<T>(List<T> l) => l[_r.nextInt(l.length)];

  static const _contestants = [
    'Elif', 'Mert', 'Zeynep', 'Kaan', 'Ayşe', 'Burak', 'Deniz', 'Selin', 'Emre', 'Cansu',
  ];
  late final List<String> _players = () {
    final l = [..._contestants]..shuffle(_r);
    return l.take(2).toList();
  }();

  /// Yarışmalarda yarışmacılar halktan, dizide oyuncular kadrodan
  bool get _contest => genre == Genre.yarisma;
  String get _a1 => _contest ? _players[0] : (cast.isNotEmpty ? cast[0] : host);
  String get _a2 => _contest
      ? _players[1]
      : (cast.length > 1 ? cast[1] : (cast.isNotEmpty && cast[0] != host ? cast[0] : guest));

  LiveBeat next() {
    if (_queue.isEmpty) _fill();
    return _queue.removeAt(0);
  }

  void _add(int side, String who, String text, {int reaction = 0, String? ticker}) =>
      _queue.add(LiveBeat(side, who, text, reaction: reaction, ticker: ticker));

  void _fill() {
    switch (genre) {
      case Genre.talkShow:
        _talk();
      case Genre.yarisma:
        switch (prop) {
          case Prop.island:
            _island();
          case Prop.quiz:
            _quiz();
          case Prop.wheel:
            _wheel();
          case Prop.couples:
            _couples();
          default:
            _voice();
        }
      case Genre.dizi:
        _drama();
      case Genre.haber:
        _news();
      case Genre.spor:
        _sport();
      case Genre.magazin:
        _gossip();
      case Genre.belgesel:
        _doc();
      case Genre.cocuk:
        _kids();
    }
  }

  // ---------------- Talk show ----------------
  static const _jokes = [
    'Dün markete gittim, kasiyer "poşet ister misiniz?" dedi. "Hayır, tatil istiyorum!" dedim.',
    'Diyete başladım. İlk gün 2 kilo verdim… sonra buzdolabı beni geri çağırdı.',
    'Annem aradı: "Yemek yedin mi?" 34 yaşındayım, hâlâ cevabı bilmiyorum!',
    'Spor salonuna yazıldım. Şimdiye kadar en çok çalışan kartım oldu.',
    'Trafikte o kadar bekledim ki yanımdaki arabayla akraba olduk.',
    'Telefonumu sessize aldım, şimdi o bana küs.',
    'Saat 8\'de kalkacaktım, alarm çaldı… ben de onu erteledim, o da beni.',
    'Hava durumu "parçalı bulutlu" dedi. Hangi parçası diye sormadım.',
  ];
  static const _questions = [
    ('Bu sezon seni en çok ne heyecanlandırıyor?', 'Yeni projem! Ama şimdilik sır, söylersem yapımcım beni kovar.'),
    ('Sette başına gelen en komik şey neydi?', 'Duygusal sahnede kostümüm yırtıldı. Yönetmen "Kestik!" diyemedi, gülmekten.'),
    ('Sabahları nasıl uyanıyorsun?', 'Üç alarm, iki kahve ve bir kedi. Kedi en etkilisi.'),
    ('Hayranlarına bir mesajın var mı?', 'Sizi çok seviyorum! Ve lütfen spoiler vermeyin.'),
    ('Mutfakta aran nasıl?', 'Su kaynatıyorum. Bazen yakıyorum ama azmim tam.'),
    ('Tatilde nereye gitmek istersin?', 'Kapadokya! Balonla güneşin doğuşunu izlemek hayalim.'),
  ];

  void _talk() {
    final k = _r.nextInt(4);
    if (k <= 1) {
      _add(0, host, _pick(_jokes));
      _add(2, 'Seyirci', '😂 HA HA HA!', reaction: 1);
    } else if (k == 2) {
      final q = _pick(_questions);
      _add(0, host, '$guest, merak ediyorum: ${q.$1}');
      _add(1, guest, q.$2);
      _add(2, 'Seyirci', _r.nextBool() ? '👏 Alkışlar!' : '😂 Kahkahalar!', reaction: _r.nextBool() ? 2 : 1);
    } else {
      _add(0, host, _pick([
        'Şimdi sürpriz! Kulislerden çok özel biri geliyor…',
        'Seyircimizden biri sahneye geliyor, bir alkış alalım!',
        'Reklamdan sonra $guest bizim için şarkı söyleyecek!',
      ]), reaction: 3);
      _add(2, 'Seyirci', '😱 Ooooo!', reaction: 3);
    }
  }

  // ---------------- Adada Kalan ----------------
  void _island() {
    board = LiveBoard('MAVİ', _a, 'KIRMIZI', _b, extra: 'Dokunulmazlık · ilk 5');
    if (_a >= 5 || _b >= 5) {
      final w = _a >= 5 ? 'Mavi' : 'Kırmızı';
      _add(0, host, 'Ve dokunulmazlığı $w takım kazanıyor! Sonuç $_a-$_b!', reaction: 2);
      _add(1, '$w takım', 'Yeneceğiz dedik, yendik! 💪', reaction: 2);
      _a = 0;
      _b = 0;
      _add(0, host, 'Yeni oyun başlıyor! Yarışmacılar yerlerine…', reaction: 0);
      board = LiveBoard('MAVİ', 0, 'KIRMIZI', 0, extra: 'Yeni oyun');
      return;
    }
    final blue = _r.nextBool();
    final team = blue ? 'Mavi takım' : 'Kırmızı takım';
    final player = blue ? _a1 : _a2;
    final what = _pick([
      'ilk dubayı düşürdü',
      'halatın sonuna ilk ulaştı',
      'topu potaya attı',
      'denge parkurunu bitirdi',
      'bayrağı kaptı',
    ]);
    blue ? _a++ : _b++;
    _add(0, host, '$team $what! Skor $_a-$_b, ${_a == _b ? 'eşitlik!' : '${_a > _b ? 'Mavi' : 'Kırmızı'} önde!'}',
        reaction: 2, ticker: '🏝️ $team $what · skor $_a-$_b');
    _add(1, player, _pick(['Haydi! Pes etmek yok!', 'Bu sayı aileme gelsin!', 'Kumdan ayaklarım yandı ama değdi!', 'Daha bitmedi!']));
    board = LiveBoard('MAVİ', _a, 'KIRMIZI', _b, extra: 'Dokunulmazlık · ilk 5');
  }

  // ---------------- Bilgi yarışması ----------------
  static const _quizQ = [
    ('Türkiye\'nin en yüksek dağı hangisidir?', ['Erciyes', 'Ağrı', 'Uludağ', 'Kaçkar'], 1),
    ('Bir yılda kaç hafta vardır?', ['48', '50', '52', '54'], 2),
    ('Gökkuşağında kaç renk vardır?', ['5', '6', '7', '8'], 2),
    ('Hangisi bir gezegen değildir?', ['Mars', 'Venüs', 'Ay', 'Jüpiter'], 2),
    ('Suyun kaynama noktası (deniz seviyesinde) kaç derecedir?', ['90', '100', '110', '120'], 1),
    ('Kapadokya hangi bölgededir?', ['Ege', 'Karadeniz', 'İç Anadolu', 'Akdeniz'], 2),
    ('Bir futbol takımı sahada kaç kişidir?', ['9', '10', '11', '12'], 2),
    ('Hangisi bir müzik aletidir?', ['Bağlama', 'Kepçe', 'Merdane', 'Süzgeç'], 0),
  ];

  void _quiz() {
    _round++;
    final q = _pick(_quizQ);
    const letters = ['A', 'B', 'C', 'D'];
    final opts = [for (int i = 0; i < 4; i++) '${letters[i]}) ${q.$2[i]}'].join('  ');
    final prize = [1000, 5000, 25000, 100000, 250000, 1000000][min(_round - 1, 5)];
    board = LiveBoard(_a2, _prize, 'SORU', _round, extra: 'Sıradaki ödül ${_fmt(prize)} ₺');
    _add(0, host, 'Soru $_round, ${_fmt(prize)} lira için: ${q.$1}', ticker: opts);
    final right = _r.nextDouble() < 0.7;
    final ans = right ? q.$3 : (q.$3 + 1 + _r.nextInt(3)) % 4;
    _add(1, _a2, '${letters[ans]} şıkkı… ${letters[ans]}, son kararım!');
    if (right) {
      _prize = prize;
      _add(0, host, 'Doğru cevap… ${letters[q.$3]}! Tebrikler, ${_fmt(prize)} lira kazandınız!', reaction: 2);
    } else {
      _add(0, host, 'Ah! Doğru cevap ${letters[q.$3]} olacaktı… Yarışmamız burada bitiyor.', reaction: 3);
      _round = 0;
      _prize = 0;
    }
    board = LiveBoard(_a2, _prize, 'SORU', _round, extra: 'Kazanç ${_fmt(_prize)} ₺');
  }

  // ---------------- Şans çarkı ----------------
  void _wheel() {
    final pts = _pick([500, 1000, 2500, 5000, 0]);
    final letter = _pick(['R', 'A', 'K', 'L', 'M', 'E', 'S', 'T']);
    _add(0, host, 'Çark dönüyor… dönüyor… ${pts == 0 ? 'İFLAS! 😱' : '$pts puan!'}', reaction: pts == 0 ? 3 : 2);
    if (pts > 0) {
      final n = _r.nextInt(3);
      _add(1, _a2, 'Bir harf alayım: $letter!');
      _add(0, host, n == 0 ? 'Maalesef tahtada $letter yok.' : 'Tahtada $n tane $letter var! 🎉', reaction: n == 0 ? 3 : 2);
      _a += pts * n;
    } else {
      _a = 0;
    }
    board = LiveBoard(_a2, _a, 'TUR', ++_round);
  }

  // ---------------- Çiftler ----------------
  static const _coupleQ = [
    ('Eşinizin en sevdiği yemek ne?', ['Mantı', 'Karnıyarık', 'Lahmacun', 'Menemen']),
    ('İlk buluşmanız nerede oldu?', ['Sahilde', 'Sinemada', 'Otobüste', 'Düğünde']),
    ('Evde bulaşığı kim yıkar?', ['Ben', 'O', 'Makine', 'Kimse']),
  ];

  void _couples() {
    final q = _pick(_coupleQ);
    final a = _pick(q.$2), b = _r.nextDouble() < 0.55 ? a : _pick(q.$2);
    _add(0, host, q.$1);
    _add(1, _a1, '$a! Kesin $a!');
    _add(0, host, 'Kartı açıyoruz… "$b"! ${a == b ? '10 puan! 🎉' : 'Olmadı! 😂'}', reaction: a == b ? 2 : 1);
    if (a == b) _a += 10;
    board = LiveBoard(_a1, _a, 'TUR', ++_round);
  }

  // ---------------- Ses / yetenek ----------------
  void _voice() {
    final c = _pick(['Elif', 'Deniz', 'Mert', 'Zeynep', 'Kaan', 'Ayşe']);
    final turned = _r.nextInt(5);
    _add(1, c, _pick(['♪ Gönlümün içinde bir şarkı var… ♪', '🎻 Kemanla zor bir parça çalıyor…', '🤸 Akrobasi gösterisi başladı!', '♪ Uzun ince bir yoldayım… ♪']));
    _add(0, guest, turned == 0 ? 'Jüriden kimse dönmedi… 😢' : '$turned jüri döndü! ${turned >= 3 ? 'İnanılmaz!' : ''}',
        reaction: turned >= 3 ? 2 : (turned == 0 ? 3 : 2));
    board = LiveBoard('DÖNEN JÜRİ', turned, 'YARIŞMACI', ++_round);
  }

  // ---------------- Dizi ----------------
  static const _dramaPairs = [
    ('Bu evden gidiyorum! Artık dayanamıyorum!', 'Gidemezsin… Sana söylemem gereken bir şey var.'),
    ('O mektubu sen mi sakladın?', 'Seni korumak için yaptım, inan bana!'),
    ('Yıllardır bu sırrı nasıl taşıdın?', 'Her gece aynı rüyayı gördüm… artık bitmeli.'),
    ('Kapıdaki adam kimdi?', 'Babanın eski ortağı… geri döndü.'),
    ('Seni seviyorum, hep sevdim.', 'Neden şimdi? Neden bu kadar geç?'),
  ];

  void _drama() {
    final d = _pick(_dramaPairs);
    _add(0, _a1, d.$1);
    _add(1, _a2, d.$2, reaction: 3);
    if (_r.nextInt(3) == 0) {
      _add(2, 'Anlatıcı', _pick(['🎻 Hüzünlü müzik yükseliyor…', '⚡ Kapı çarpıyor!', '📱 Telefon çalıyor… ekranda bilinmeyen numara.']), reaction: 3,
          ticker: '📺 Sosyal medyada gündem: "${d.$1.split(' ').take(3).join(' ')}…"');
    }
  }

  // ---------------- Haber ----------------
  static const _headlines = [
    'Boğaz\'da balık bolluğu: tezgâhlarda fiyatlar düştü.',
    'Yarın Karadeniz\'de sağanak, Akdeniz\'de güneşli hava bekleniyor.',
    'Kapadokya\'da balon turları rekor kırdı.',
    'Yerli otomobil fuarına ziyaretçi akını.',
    'Öğrenciler bilim olimpiyatından altın madalyayla döndü.',
    'Şehirde yeni metro hattı yarın açılıyor.',
  ];

  void _news() {
    final h = _pick(_headlines);
    _add(0, host, 'İyi akşamlar. $h', ticker: '🔴 SON DAKİKA · $h');
    if (_r.nextBool()) {
      _add(0, host, 'Muhabirimiz $_a2 olay yerinde. Buyurun…');
      _add(1, _a2, 'Teşekkürler. Şu an bulunduğum noktada yoğun bir ilgi var…', reaction: 0);
    }
  }

  // ---------------- Spor ----------------
  void _sport() {
    _minute = min(90, _minute + 4 + _r.nextInt(9));
    final home = 'EV SAHİBİ', away = 'DEPLASMAN';
    final ev = _r.nextInt(5);
    if (_minute >= 90) {
      _add(0, host, 'Ve maç bitiyor! Sonuç $_a-$_b! ${_a == _b ? 'Puanlar paylaşıldı.' : 'Tebrikler!'}', reaction: 2);
      _a = 0;
      _b = 0;
      _minute = 0;
    } else if (ev <= 1) {
      final h = _r.nextBool();
      h ? _a++ : _b++;
      _add(0, host, '$_minute\'. GOOOOL! ${h ? 'Ev sahibi' : 'Konuk takım'} ağları sarstı! $_a-$_b!', reaction: 2,
          ticker: '⚽ $_minute\' GOL · $home $_a-$_b $away');
      _add(1, _a2, 'Muhteşem bir vuruş! Kaleci sadece baktı!');
    } else if (ev == 2) {
      _add(0, host, '$_minute\'. Kaleci uçtu, gol yok! İnanılmaz kurtarış!', reaction: 3);
    } else if (ev == 3) {
      _add(0, host, '$_minute\'. Sarı kart! Hakem cebine gitti.', reaction: 3);
      _add(1, _a2, 'Bence doğru karar, ayak yüksekte.');
    } else {
      _add(0, host, '$_minute\'. Top orta sahada, tribünler coşuyor!', reaction: 2);
    }
    board = LiveBoard(home, _a, away, _b, extra: '$_minute\'');
  }

  // ---------------- Magazin ----------------
  void _gossip() {
    final g = _pick([
      '$guest havalimanında görüntülendi, yanındaki gizemli kişi kim?',
      'Kırmızı halıda yılın elbisesi! Herkes onu konuşuyor.',
      'Ünlü çiftten barışma sinyali geldi!',
      '$guest yeni albümünün ilk şarkısını bizimle paylaştı!',
    ]);
    _add(0, host, g, ticker: '📸 $g');
    _add(1, _a2, _pick(['Bence aşk var! 😍', 'Ben zaten biliyordum!', 'Kaynaklarımız doğruluyor…']), reaction: _r.nextBool() ? 1 : 3);
  }

  // ---------------- Belgesel ----------------
  void _doc() {
    _add(2, 'Anlatıcı', _pick([
      'Bozkurt sürüsü karlı tepede avını bekliyor…',
      'Mercanların arasında renkli balıklar dans ediyor.',
      'Bu antik kent yüzyıllardır sırrını saklıyor.',
      'Gökyüzünde milyonlarca yıldız… ve uzakta bir kuyruklu yıldız.',
      'Leylekler binlerce kilometrelik yolculuğa çıkıyor.',
    ]), reaction: _r.nextInt(3) == 0 ? 3 : 0);
  }

  // ---------------- Çocuk ----------------
  void _kids() {
    _add(0, host, _pick([
      'Hadi çocuklar, hep birlikte sayalım: bir, iki, üç!',
      'Bugün renkleri öğreniyoruz! Bu ne renk?',
      'Kim dans etmek istiyor? Herkes ayağa!',
    ]));
    _add(2, 'Çocuklar', _pick(['🎈 Yaşasııın!', '🎵 La la la!', '👏 Bir daha, bir daha!']), reaction: 2);
  }

  static String _fmt(int v) {
    final s = v.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
      b.write(s[i]);
    }
    return b.toString();
  }
}
