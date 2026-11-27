import 'content.dart';

/// Canlı yayında krize karşı bir hamle
class CrisisOption {
  final String emoji;
  final String label;
  final double base; // temel başarı şansı
  final double skill; // sunucu yeteneğinin şansa etkisi (0 = hiç)
  final double reward; // başarıda ödül büyüklüğü (1 = tam)
  final double risk; // başarısızlıkta ceza büyüklüğü (1 = tam)
  final String win; // başarı metni
  final String fail; // başarısızlık metni
  const CrisisOption(this.emoji, this.label, this.base, this.skill, this.reward, this.risk,
      this.win, this.fail);
}

/// Canlı yayın krizi (yer tutucular: {host} {guest} {actor} {show})
class CrisisDef {
  final String id;
  final String emoji;
  final String title;
  final String desc;
  final Set<Genre> genres; // boş = her tür
  final int fx; // giriş efekti: 0 parazit, 1 karartma, 2 alarm, 3 sarsıntı
  final List<CrisisOption> options;
  const CrisisDef(this.id, this.emoji, this.title, this.desc, this.genres, this.fx, this.options);
}

const _all = <Genre>{};

const crisisDefs = <CrisisDef>[
  // ---------------- Her türde ----------------
  CrisisDef('mic', '🎤', 'Mikrofon sustu!', '{host} konuşurken mikrofonu kesildi, stüdyo sessiz.', _all, 0, [
    CrisisOption('🗣️', 'Bağırarak devam et', 0.45, 0.5, 1.0, 1.0,
        '{host} mikrofonsuz devam etti, seyirci ayakta alkışladı!', '{host:gen} sesi duyulmadı, izleyiciler kanal değiştirdi.'),
    CrisisOption('📺', 'Reklama gir', 0.85, 0.0, 0.35, 0.4,
        'Reklam arası kurtardı, teknik ekip sorunu çözdü.', 'Reklamdan dönüşte mikrofon hâlâ bozuktu.'),
    CrisisOption('✍️', 'Yazıyla anlaş', 0.55, 0.3, 0.8, 0.7,
        '{host} kartonlara yazarak konuştu, an viral oldu!', 'Yazılar okunmadı, ortam karıştı.'),
  ]),
  CrisisDef('power', '💡', 'Elektrikler kesildi!', 'Stüdyo bir anda karardı, yayın siyah ekranda.', _all, 1, [
    CrisisOption('🔦', 'Telefon ışıklarıyla devam', 0.5, 0.4, 1.0, 1.0,
        'Seyirciler telefon ışıklarını yaktı, büyülü bir an yaşandı!', 'Karanlıkta kimse bir şey göremedi.'),
    CrisisOption('🔋', 'Jeneratörü bekle', 0.75, 0.0, 0.3, 0.6,
        'Jeneratör 20 saniyede devreye girdi, yayın kaldığı yerden sürdü.', 'Jeneratör çalışmadı, yayın dakikalarca siyah kaldı.'),
    CrisisOption('🎞️', 'Arşiv görüntüsü ver', 0.8, 0.0, 0.2, 0.5,
        'Eski efsane anlar ekrana geldi, izleyici nostalji yaşadı.', 'Arşivden yanlış kaset çıktı, izleyici şaşkın.'),
  ]),
  CrisisDef('prompter', '📜', 'Teleprompter dondu!', '{host} okuyacak metni kaybetti, gözleri boşlukta.', _all, 0, [
    CrisisOption('😎', 'Ezbere doğaçla', 0.4, 0.7, 1.0, 1.0,
        '{host} doğaçlamayla şov yaptı, en iyi anı buydu!', '{host} kekeledi, sosyal medya alay etti.'),
    CrisisOption('🤝', 'Konuğa söz ver', 0.6, 0.2, 0.6, 0.6,
        'Söz {guest:dat} geçti, sohbet çok samimi oldu.', '{guest} de hazırlıksızdı, sessizlik çöktü.'),
    CrisisOption('📺', 'Reklama gir', 0.85, 0.0, 0.3, 0.4,
        'Reklamda metin düzeldi, kimse fark etmedi.', 'Reklamdan sonra teleprompter yine bozuldu.'),
  ]),
  CrisisDef('fan', '🏃', 'Seyirci sahneye fırladı!', 'Bir hayran güvenliği aşıp {host:dat} koşuyor!', _all, 3, [
    CrisisOption('🤗', 'Sarıl ve sahneye al', 0.5, 0.4, 1.0, 1.0,
        'Hayran ağlayarak teşekkür etti, an milyonlarca izlendi!', 'Hayran mikrofonu kaptı, ortalık karıştı.'),
    CrisisOption('👮', 'Güvenliği çağır', 0.8, 0.0, 0.3, 0.5,
        'Güvenlik nazikçe çıkardı, yayın sakinledi.', 'Güvenlik sert davrandı, tepki çekti.'),
    CrisisOption('😂', 'Espriyle geç', 0.45, 0.6, 0.9, 0.8,
        '{host:gen} esprisi salonu kırıp geçirdi!', 'Espri yerini bulmadı, ortam gerildi.'),
  ]),
  CrisisDef('wrongName', '😳', 'Yanlış isim!', '{host}, {guest:acc} yanlış isimle tanıttı. Herkes donup kaldı.', _all, 0, [
    CrisisOption('🙏', 'Hemen özür dile', 0.75, 0.2, 0.5, 0.5,
        'Samimi özür herkesi gülümsetti.', 'Özür de karışık çıktı, durum tuhaflaştı.'),
    CrisisOption('😂', 'Kendinle dalga geç', 0.5, 0.6, 1.0, 0.9,
        '{host} kendiyle dalga geçti, kahkaha tufanı koptu!', 'Şaka anlaşılmadı, {guest} bozuldu.'),
    CrisisOption('🤫', 'Hiçbir şey olmamış gibi', 0.35, 0.3, 0.6, 1.0,
        'Kimse fark etmemiş, yayın akıp gitti.', 'Herkes fark etti, kesit her yerde dönüyor.'),
  ]),
  CrisisDef('camera', '📹', 'Kamera devrildi!', 'Ana kamera yere düştü, görüntü yamuk!', _all, 3, [
    CrisisOption('🎥', 'Telefonla çek', 0.5, 0.3, 0.9, 0.8,
        'Dikey telefon çekimi yeni nesle çok yakın geldi!', 'Görüntü titredi, izleyici başı döndü.'),
    CrisisOption('🔀', 'Yedek kameraya geç', 0.8, 0.0, 0.35, 0.5,
        'Reji yedek kameraya anında geçti.', 'Yedek kamera da bulanıktı.'),
    CrisisOption('😄', 'Yamuk açıyla devam', 0.4, 0.5, 1.0, 1.0,
        'Yamuk açı efsaneleşti, "eğik yayın" akımı başladı!', 'İzleyici "ne oluyor" diye kanal değiştirdi.'),
  ]),
  CrisisDef('rain', '🌧️', 'Çatıdan su damlıyor!', 'Stüdyonun tavanından {host:gen} kafasına su damlıyor.', _all, 2, [
    CrisisOption('☂️', 'Şemsiye açıp devam', 0.55, 0.4, 1.0, 0.9,
        'Şemsiyeli sunum yılın görüntüsü oldu!', 'Şemsiye dekoru devirdi.'),
    CrisisOption('🔧', 'Teknik ekibi çağır', 0.8, 0.0, 0.3, 0.5,
        'Ekip kova koydu, yayın devam etti.', 'Su kablolara kaçtı, yayın kesildi.'),
    CrisisOption('🎶', 'Yağmur şarkısı söyle', 0.35, 0.6, 1.2, 1.0,
        '{host} yağmur şarkısı söyledi, salon eşlik etti!', 'Şarkı berbattı, alay konusu oldu.'),
  ]),

  // ---------------- Talk show / magazin ----------------
  CrisisDef('walkout', '🚪', 'Konuk stüdyoyu terk ediyor!', '{guest} soruya sinirlendi, mikrofonu çıkarıp kalktı!', {Genre.talkShow, Genre.magazin}, 3, [
    CrisisOption('🏃', 'Peşinden koş', 0.45, 0.5, 1.2, 1.0,
        '{host} kulise kadar koştu, {guest} gülerek geri döndü!', '{guest} kapıyı çarpıp gitti, kamera her şeyi çekti.'),
    CrisisOption('🎤', 'Yalnız devam et', 0.6, 0.5, 0.6, 0.7,
        '{host} tek başına harika bir monolog yaptı.', 'Boş koltuk ekranda kaldı, izleyici sıkıldı.'),
    CrisisOption('📺', 'Reklama gir', 0.85, 0.0, 0.3, 0.4,
        'Reklamda barıştılar, kaldıkları yerden devam.', 'Reklamdan sonra {guest} hâlâ yoktu.'),
  ]),
  CrisisDef('slip', '🤐', 'Konuk sır verdi!', '{guest} canlı yayında yeni projesinin sırrını ağzından kaçırdı.', {Genre.talkShow, Genre.magazin}, 2, [
    CrisisOption('🔥', 'Üstüne git, detay sor', 0.55, 0.4, 1.2, 1.0,
        'Haber tüm sitelerde manşet oldu, kaynak sizsiniz!', '{guest:gen} menajeri yayını durdurttu.'),
    CrisisOption('🤝', 'Konuyu kapat', 0.85, 0.0, 0.3, 0.3,
        '{guest} jestinize teşekkür etti, tekrar gelmeye söz verdi.', 'İzleyici "neden kapattın" diye kızdı.'),
    CrisisOption('😏', 'Gizemli bırak', 0.6, 0.3, 0.8, 0.6,
        'Merak dalgası: herkes yarını bekliyor.', 'Kimse anlamadı, an boşa gitti.'),
  ]),
  CrisisDef('cry', '😢', 'Konuk ağlamaya başladı!', '{guest} çocukluk anısını anlatırken gözyaşlarını tutamadı.', {Genre.talkShow, Genre.magazin}, 1, [
    CrisisOption('🫂', 'Yanına git, sarıl', 0.7, 0.3, 1.0, 0.6,
        'Duygusal an tüm Türkiye\'yi ağlattı!', 'Fazla dramatik bulundu.'),
    CrisisOption('🎵', 'Hüzünlü müzik ver', 0.55, 0.2, 0.9, 0.8,
        'Reji müzikle anı unutulmaz yaptı.', 'Müzik yanlış çaldı: neşeli bir şarkı!'),
    CrisisOption('📺', 'Reklama gir', 0.8, 0.0, 0.25, 0.5,
        '{guest} toparlandı, yayın sakin devam etti.', 'İzleyici "duygusuz" diye eleştirdi.'),
  ]),
  CrisisDef('rival', '📞', 'Canlı yayına telefon!', 'Rakip kanalın yıldızı canlı yayını aradı, {host:dat} meydan okuyor!', {Genre.talkShow}, 2, [
    CrisisOption('⚔️', 'Meydan okumayı kabul et', 0.45, 0.6, 1.3, 1.0,
        'Atışma yılın televizyon anı seçildi!', '{host} cevap bulamadı, rakip kazandı.'),
    CrisisOption('😇', 'Kibarca teşekkür et', 0.8, 0.1, 0.4, 0.3,
        'Centilmence tavır çok beğenildi.', '"Korktu" yorumları yağdı.'),
    CrisisOption('📵', 'Hattı kes', 0.6, 0.0, 0.5, 0.8,
        'Kesin tavır hayranları sevindirdi.', 'Kaba bulundu, gündem oldu.'),
  ]),

  // ---------------- Yarışma ----------------
  CrisisDef('cheat', '🕵️', 'Hile iddiası!', 'Yarışmacı, rakibinin cevapları kulaklıktan aldığını iddia ediyor!', {Genre.yarisma}, 2, [
    CrisisOption('🔍', 'Canlı yayında kontrol et', 0.55, 0.4, 1.2, 1.0,
        'Kulaklık boş çıktı, gerilim reytingi uçurdu!', 'Kontrol uzun sürdü, yayın tıkandı.'),
    CrisisOption('🔁', 'Soruyu yenile', 0.8, 0.1, 0.4, 0.4,
        'Yeni soru herkesi rahatlattı.', 'Yeni soru daha da kolaydı, şüphe büyüdü.'),
    CrisisOption('⚖️', 'İkisini de diskalifiye et', 0.45, 0.2, 0.9, 1.1,
        'Sert karar yarışmanın ciddiyetini gösterdi.', 'Seyirci isyan etti, protesto başladı.'),
  ]),
  CrisisDef('buzzer', '🔔', 'Butonlar çalışmıyor!', 'Yarışmacıların butonları aynı anda yandı, kim önce bastı belli değil!', {Genre.yarisma}, 0, [
    CrisisOption('✊', 'Taş kâğıt makas', 0.6, 0.3, 1.0, 0.7,
        'Taş kâğıt makas finali stüdyoyu coşturdu!', 'Seyirci "ciddiyetsiz" dedi.'),
    CrisisOption('🔁', 'Soruyu tekrarla', 0.8, 0.0, 0.4, 0.4,
        'Tekrar sorulan soru adil bir sonuç verdi.', 'Butonlar yine bozuldu.'),
    CrisisOption('🎁', 'İkisine de puan ver', 0.65, 0.2, 0.7, 0.6,
        'Cömert karar alkış aldı.', 'Diğer yarışmacılar itiraz etti.'),
  ]),
  CrisisDef('faint', '😵', 'Yarışmacı bayıldı!', 'Heyecana dayanamayan yarışmacı sahnede yığıldı!', {Genre.yarisma}, 1, [
    CrisisOption('🚑', 'Sağlık ekibini çağır', 0.85, 0.0, 0.6, 0.4,
        'Yarışmacı kendine geldi, ayakta alkışlandı.', 'Ekip geç geldi, panik yayıldı.'),
    CrisisOption('💧', 'Su ver, sakinleştir', 0.6, 0.4, 0.9, 0.8,
        '{host:gen} sakinliği herkesi rahatlattı.', 'Durum ciddileşti, yayın kesildi.'),
    CrisisOption('📺', 'Reklama gir', 0.75, 0.0, 0.3, 0.5,
        'Reklam arasında her şey yoluna girdi.', '"Duyarsız" eleştirisi aldı.'),
  ]),
  CrisisDef('prize', '💰', 'Ödül yanlış çıktı!', 'Ekranda büyük ödül yazıyor ama yarışmacı aslında kaybetti!', {Genre.yarisma}, 2, [
    CrisisOption('🎉', 'Ödülü yine de ver', 0.75, 0.0, 1.2, 0.5,
        'Kanalın cömertliği gündem oldu, herkes konuşuyor!', 'Bütçe zorlandı, yönetim kızgın.'),
    CrisisOption('🙏', 'Hatayı açıkla', 0.7, 0.3, 0.5, 0.6,
        'Dürüstlük takdir edildi.', 'Yarışmacı sahnede ağladı, tepki büyük.'),
    CrisisOption('🎲', 'Bonus soru sor', 0.5, 0.4, 1.0, 0.9,
        'Bonus soruyu bildi, mutlu son!', 'Bonus soruyu da bilemedi, hayal kırıklığı.'),
  ]),

  // ---------------- Dizi ----------------
  CrisisDef('setFire', '🔥', 'Dekorda yangın!', 'Mumlu sahnede perde tutuştu, oyuncular panikte!', {Genre.dizi}, 2, [
    CrisisOption('🧯', 'Söndür ve devam', 0.7, 0.2, 0.6, 0.6,
        'Hızlı müdahale, sahne gerçekçiliği arttı.', 'Duman yüzünden sahne çöpe gitti.'),
    CrisisOption('🎬', 'Sahneye dahil et', 0.4, 0.5, 1.3, 1.0,
        '{actor} doğaçlamayla yangını hikâyeye kattı, izleyici büyülendi!', 'Senaryo saçmaladı, alay edildi.'),
    CrisisOption('⏪', 'Sahneyi baştan al', 0.85, 0.0, 0.25, 0.4,
        'Tekrar çekim kusursuz oldu.', 'Bölüm gecikti, izleyici sabırsızlandı.'),
  ]),
  CrisisDef('forgotLine', '🙊', 'Replik unutuldu!', '{actor} en dramatik sahnede repliğini unuttu, sessizlik!', {Genre.dizi}, 0, [
    CrisisOption('🎭', 'Doğaçla devam', 0.45, 0.6, 1.2, 1.0,
        '{actor:gen} doğaçlaması senaryodan iyi çıktı!', 'Sahne anlamsızlaştı.'),
    CrisisOption('🎶', 'Müzikle kurtar', 0.7, 0.1, 0.5, 0.5,
        'Duygusal müzik sessizliği anlamlı kıldı.', 'Müzik sahneyi komikleştirdi.'),
    CrisisOption('✂️', 'Kurguda kes', 0.85, 0.0, 0.25, 0.3,
        'Kurgu ekibi fark ettirmedi.', 'Kesik belli oldu, hata kesiti yayıldı.'),
  ]),
  CrisisDef('spoiler', '📸', 'Final sızdırıldı!', 'Bölümün sonu sosyal medyaya sızdı, herkes konuşuyor!', {Genre.dizi}, 2, [
    CrisisOption('🔀', 'Sonu değiştir', 0.5, 0.3, 1.3, 1.0,
        'Sürpriz son sızıntıyı yalanladı, herkes şok!', 'Yeni son mantıksız bulundu.'),
    CrisisOption('😏', 'Sahte sızıntı de', 0.6, 0.2, 0.9, 0.8,
        'Herkes kafası karışık izledi, merak zirvede.', 'Yalan ortaya çıktı.'),
    CrisisOption('🤷', 'Görmezden gel', 0.75, 0.0, 0.3, 0.6,
        'Sızıntı unutuldu, bölüm normal izlendi.', 'Merak kalmadı, izleyici düştü.'),
  ]),

  // ---------------- Haber ----------------
  CrisisDef('fakeNews', '📰', 'Yanlış haber okundu!', 'Spiker, doğrulanmamış bir haberi canlı yayında okudu!', {Genre.haber}, 2, [
    CrisisOption('✅', 'Anında düzelt', 0.8, 0.2, 0.7, 0.4,
        'Hızlı düzeltme güven kazandırdı.', 'Düzeltme de karışık oldu.'),
    CrisisOption('🔎', 'Muhabire bağlan', 0.55, 0.4, 1.0, 0.9,
        'Muhabir doğru bilgiyi verdi, haber derinleşti!', 'Bağlantı koptu, kafa karışıklığı arttı.'),
    CrisisOption('🤫', 'Sessizce geç', 0.35, 0.2, 0.5, 1.2,
        'Kimse fark etmedi.', 'Hata gündem oldu, Yayın Kurulu inceleme başlattı.'),
  ]),
  CrisisDef('lostLink', '📡', 'Canlı bağlantı koptu!', 'Muhabirle bağlantı tam en kritik anda kesildi.', {Genre.haber, Genre.spor}, 0, [
    CrisisOption('☎️', 'Telefonla bağlan', 0.7, 0.2, 0.7, 0.5,
        'Telefon bağlantısı haberi kurtardı.', 'Ses cızırtılıydı, anlaşılmadı.'),
    CrisisOption('🗺️', 'Stüdyoda haritayla anlat', 0.5, 0.5, 1.0, 0.8,
        '{host} haritayla ustaca anlattı, takdir topladı!', 'Harita yanlıştı.'),
    CrisisOption('⏭️', 'Diğer habere geç', 0.85, 0.0, 0.25, 0.4,
        'Akış sorunsuz devam etti.', 'İzleyici asıl haberi merak etti, rakibe geçti.'),
  ]),

  // ---------------- Spor ----------------
  CrisisDef('pitch', '⚽', 'Sahaya taraftar girdi!', 'Maçın en heyecanlı anında sahaya bir taraftar daldı!', {Genre.spor}, 3, [
    CrisisOption('🎙️', 'Esprili anlatım yap', 0.5, 0.6, 1.1, 0.8,
        'Spikerin esprili anlatımı maçtan çok konuşuldu!', 'Espri yersiz bulundu.'),
    CrisisOption('🔁', 'Tekrar görüntüleri ver', 0.8, 0.0, 0.4, 0.4,
        'Gol tekrarları akışı kurtardı.', 'Tekrarlar bitti, sahne hâlâ karışık.'),
    CrisisOption('📊', 'İstatistiklere geç', 0.7, 0.2, 0.5, 0.5,
        'Analiz sevenler mutlu oldu.', 'İzleyici sıkıldı.'),
  ]),
  CrisisDef('var', '📺', 'Tartışmalı pozisyon!', 'Son dakikada tartışmalı penaltı: stüdyo ikiye bölündü!', {Genre.spor}, 2, [
    CrisisOption('🧐', 'Uzmana analiz yaptır', 0.65, 0.3, 0.9, 0.6,
        'Analiz netti, programın güvenilirliği arttı.', 'Uzman da emin olamadı.'),
    CrisisOption('🗳️', 'İzleyici oylaması', 0.6, 0.2, 1.1, 0.7,
        'Milyonlar oy verdi, etkileşim rekoru!', 'Oylama sistemi çöktü.'),
    CrisisOption('🔥', 'Tartışmayı alevlendir', 0.4, 0.4, 1.3, 1.1,
        'Atışma reyting rekoru kırdı!', 'Kavga çıktı, ceza geldi.'),
  ]),

  // ---------------- Çocuk ----------------
  CrisisDef('kidCry', '😭', 'Minik konuk ağlıyor!', 'Programdaki çocuk annesini istiyor, hıçkırıklara boğuldu.', {Genre.cocuk}, 1, [
    CrisisOption('🧸', 'Oyuncakla oyala', 0.7, 0.3, 1.0, 0.6,
        'Kocaman sarılma, gülümseme: tüm aileler eridi!', 'Oyuncak da işe yaramadı.'),
    CrisisOption('🎶', 'Hep birlikte şarkı', 0.6, 0.4, 1.1, 0.7,
        'Bütün stüdyo şarkı söyledi, an unutulmaz oldu!', 'Şarkı ağlamayı artırdı.'),
    CrisisOption('👩', 'Annesini çağır', 0.85, 0.0, 0.5, 0.3,
        'Anne-çocuk kavuşması çok tatlıydı.', 'Yayın uzun süre durdu.'),
  ]),
  CrisisDef('mascot', '🐻', 'Maskotun kafası düştü!', 'Ayıcık maskotunun kafası çocukların önünde yere düştü!', {Genre.cocuk}, 3, [
    CrisisOption('🪄', '"Sihir!" de', 0.55, 0.5, 1.2, 0.9,
        'Çocuklar sihire inandı, kahkahalar yükseldi!', 'Çocuklar korktu, ağlama sesleri.'),
    CrisisOption('🔄', 'Hızla tak', 0.75, 0.1, 0.4, 0.5,
        'Kimse ne olduğunu anlamadı.', 'Kafa ters takıldı!'),
    CrisisOption('📺', 'Çizgi film ver', 0.85, 0.0, 0.25, 0.3,
        'Çizgi film araya girdi, sorun çözüldü.', 'Çocuklar programı istedi.'),
  ]),

  // ---------------- Belgesel ----------------
  CrisisDef('animal', '🐍', 'Hayvan kaçtı!', 'Stüdyodaki yılan kafesinden çıktı ve kayboldu!', {Genre.belgesel, Genre.cocuk}, 3, [
    CrisisOption('🧑‍🔬', 'Uzmanla canlı ara', 0.6, 0.4, 1.2, 0.9,
        'Arama anı gerilim filmi gibiydi, yılan bulundu!', 'Panik çıktı, yayın kesildi.'),
    CrisisOption('🚪', 'Stüdyoyu boşalt', 0.85, 0.0, 0.3, 0.4,
        'Güvenli tahliye takdir edildi.', 'Tahliye karışık oldu.'),
    CrisisOption('📖', 'Yılanı anlat', 0.45, 0.6, 1.0, 1.0,
        '{host} yılan hakkında bilgiler verdi, izleyici bir şey öğrendi!', 'Kimse dinlemedi, herkes yılanı aradı.'),
  ]),
];
