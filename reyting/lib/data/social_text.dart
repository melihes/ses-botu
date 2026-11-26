// Kurmaca sosyal medya: kullanıcı adları ve paylaşım parçaları.
// Metinler parça parça birleşir (açılış + gövde + kapanış + etiket + emoji),
// böylece binlerce farklı paylaşım çıkar; son kullanılanlar tekrar seçilmez.
//
// Yer tutucular: {show} program adı, {tag} program etiketi, {host} sunucu,
// {actor} oyuncu, {guest} konuk, {channel} kanal, {extra} olay adı, {slot} kuşak

/// Paylaşım konusu
enum SocialTopic {
  hit, // program çok iyi gidiyor
  flop, // program kötü gidiyor
  average, // idare eder
  newShow, // yeni program yayında
  ended, // sezon bitti
  special, // özel gün bölümü
  crisisWin, // canlı yayın krizi iyi yönetildi
  crisisFail, // canlı yayın krizi kötü yönetildi
  drama, // kulis dedikodusu
  holiday, // bayram / özel gün sohbeti
  film, // sinema filmi vizyonda
  viral, // viral an
  award, // ödül
  random, // gündelik izleyici sohbeti
}

// ---------------- Kullanıcı adları ----------------
const socialWords = [
  'kahve', 'dizi', 'kanepe', 'gece', 'kedi', 'cay', 'simit', 'kumanda', 'patlamis', 'misir',
  'ekran', 'reyting', 'sinema', 'yildiz', 'ay', 'deniz', 'ruzgar', 'yagmur', 'kitap', 'sahil',
  'vapur', 'martı', 'balkon', 'pazar', 'lodos', 'poyraz', 'karadut', 'lale', 'zeytin', 'incir',
  'tost', 'menemen', 'boza', 'salep', 'kestane', 'gozleme', 'fıstık', 'cilek', 'portakal', 'nar',
  'kurt', 'tilki', 'baykus', 'kirpi', 'kaplumbaga', 'panda', 'penguen', 'yunus', 'atmaca', 'serce',
];
const socialStyles = [
  '{w}_{n}', '{w}{n}', '{f}_{w}', '{f}.{l}', '{w}bagimlisi', '{w}_sever', 'bir{w}', '{f}{n}',
  '{w}_kurdu', 'gercek{f}', '{f}_{l}{n}', '{w}ci_{f}', '{w}.{w2}', 'ben{f}', '{f}_tv', '{w}_{w2}',
];
const socialPlates = ['34', '06', '35', '16', '01', '07', '42', '27', '61', '55', '38', '21', '41', '26', '09'];

// ---------------- Parçalar ----------------
const socialOpeners = [
  '', '', '', '', '', // çoğu paylaşım açılışsız
  'Arkadaşlar', 'Yemin ederim', 'Ciddi soruyorum', 'Şu an', 'Evdekiler uyurken ben',
  'Annemle izliyoruz ve', 'İşten geldim,', 'Bu akşam', 'Az önce', 'Sabah sabah',
  'Kimse konuşmuyor ama', 'Söylemem lazım:', 'Dürüst olayım,', 'Kanalı değiştirirken denk geldim,',
  'Babam kumandayı vermiyor çünkü', 'Kardeşim zorla izletti,', 'Otobüste telefondan izliyorum,',
  'Gece 2 oldu,', 'Mutfaktan koşarak geldim,', 'Tatildeyim ama',
];

const socialClosers = [
  '', '', '', '', '', '',
  'Bu kadar.', 'Başka söze gerek yok.', 'Not alın.', 'Ben söylemiş olayım.', 'Haftaya görüşürüz.',
  'Kimse beni ikna edemez.', 'Yorumlar sizin.', 'Katılan RT.', 'Hadi bakalım.', 'İyi geceler.',
  'Sabah işe nasıl gideceğim bilmiyorum.', 'Çayımı demledim, hazırım.', 'Kalbim dayanmıyor.',
  'Ekran görüntüsü aldım.', 'Grubumuza attım bile.',
];

const socialEmojisGood = ['🔥', '😍', '👏', '💯', '🙌', '😂', '🥹', '✨', '❤️', '🤩', '👌', '🎉'];
const socialEmojisBad = ['😴', '🙄', '😤', '🤦', '💤', '😒', '👎', '🥱', '😑', '😬'];
const socialEmojisNeutral = ['🤔', '📺', '👀', '☕', '🍿', '😅', '🙃', '🫠'];

/// Konu → gövde cümleleri (çok sayıda; tekrar engeli ile seçilir)
const socialBodies = <SocialTopic, List<String>>{
  SocialTopic.hit: [
    '{show} bu hafta da çok iyiydi',
    '{show} ekrana gelince sokaklar boşalıyor resmen',
    '{host} sunuculuğun dersini veriyor, {show} başka seviye',
    '{show} izlemeden uyuyamıyorum artık',
    '{actor} bu sahnede herkesi ağlattı, {show} efsane',
    '{show} gibi bir program yıllardır yoktu',
    '{channel} bu sefer şov yaptı, {show} herkesin dilinde',
    '{show} için yemek saatimizi değiştirdik',
    'İş yerinde herkes {show} konuşuyor',
    '{show:gen} müziği hâlâ kulağımda',
    '{show} bitince ne yapacağım bilmiyorum',
    '{actor} ile {host} aynı karede, daha ne olsun',
    '{show} reytingleri uçuruyor, hakkını veriyor',
    'Haftanın en iyi saati {show} saati',
    '{show:gen} son bölümünü üç kere izledim',
    'Annem bile {show} hakkında teori kuruyor',
    '{show} yapımcılarının elinden öpüyorum',
    '{show} başlayınca telefonları bırakıyoruz evde',
    'Bu sezonun açık ara en iyisi {show}',
    '{show:loc} {guest} gelince stüdyo yıkıldı',
    '{show} sayesinde {slot} kuşağı artık bizim saatimiz',
    '{actor} bu rolü oynamak için doğmuş',
    '{show} her hafta çıtayı biraz daha yükseltiyor',
    'Kim ne derse desin {show} bu işi biliyor',
    '{show} için yorum yazmaya kelime yetmiyor',
  ],
  SocialTopic.flop: [
    '{show} gittikçe sıkıcı olmaya başladı',
    '{show} izlerken uyuyakaldım, yine',
    'Bu {show} neden hâlâ yayında anlamıyorum',
    '{host} biraz daha enerjik olsa {show} kurtulur belki',
    '{show} bu hafta hiç olmamış',
    '{channel} {show} yerine başka bir şey koysun artık',
    '{show:gen} senaryosu ilk haftadan beri aynı yerde dönüyor',
    '{show} başladı, kanal değiştirdim',
    'Reklamlar {show:abl} daha eğlenceliydi',
    '{show} için verilen emeğe yazık, tutmadı',
    '{actor} iyi ama {show} onu taşıyamıyor',
    '{show:gen} formatı eskidi bence',
    '{show} yerine eski bölümleri izlesek daha iyi',
    'Bu kadar reklamla {show} izlenmez ki',
    '{show} geçen sezonun gölgesinde kaldı',
    '{show} izleyip zaman kaybetmeyin',
    'Babam bile {show:dat} söylendi, durum ciddi',
    '{show} bu kuşağa hiç uymamış',
  ],
  SocialTopic.average: [
    '{show} fena değil ama bir şey eksik',
    '{show} arka planda açık, yarım yarım izliyorum',
    '{show} bu hafta idare ederdi',
    '{host} güzel sunuyor, konular biraz zayıf',
    '{show:acc} sevdim ama hâlâ ısınamadım',
    '{show} biraz daha cesur olabilir',
    '{show:loc} {actor} tek başına çekiyor',
    '{show} başı iyiydi, sonu dağıldı',
    'Akşam yemeğinde {show} vardı, eh işte',
    '{show} için karar veremedim, haftaya bakacağım',
    '{show} ortalama ama yine de izliyorum',
    '{show:gen} potansiyeli var, değerlendirilmiyor',
  ],
  SocialTopic.newShow: [
    '{show} bu akşam başladı, ilk bölüm umut verici',
    '{channel:gen} yeni programı {show} ekranda, bakalım',
    '{show} fragmanı izledim, beklentim yüksek',
    'Yeni başlayan {show:dat} bir şans verdim',
    '{show} ilk bölümden iddialı geldi',
    '{host:acc} yeni programı {show:loc} görmek güzel',
    '{show} {slot} kuşağına iddialı bir giriş yaptı',
    '{show} başlarken çok konuşuluyordu, ilk izlenim iyi',
    'Herkes {show:acc} soruyor, ilk bölüm tamam',
    '{actor} yeni projesi {show} ile döndü',
  ],
  SocialTopic.ended: [
    '{show} sezonu bitti, şimdi ne izleyeceğiz',
    '{show:gen} finali tam bir duygu seli',
    'Elveda {show}, iyi ki vardın',
    '{show} finali herkesi şaşırttı',
    '{show} yeni sezonla dönsün lütfen {channel}',
    '{show} biterken {actor:gen} son sözleri...',
    '{show} sezon finali beklediğim gibi çıkmadı',
    '{show} bitti, akşamlar boş kaldı',
  ],
  SocialTopic.special: [
    '{show} {extra} bölümü harikaydı',
    '{extra} için {show} ne güzel düşünmüş',
    '{show:gen} {extra} hazırlığı çok emek kokuyor',
    'Bayram havasını {show} getirdi',
    '{extra} denince akla artık {show} geliyor',
    'Ailece {show} {extra} izledik',
    '{show} {extra} bölümünü kaçıran yandı',
    '{extra} sofrasında konu {show:cop}',
    '{channel} {extra} için {show} ile fark yarattı',
  ],
  SocialTopic.crisisWin: [
    '{show:loc} canlı yayın kazası oldu ama {host} öyle güzel toparladı ki',
    '{host} doğaçlamanın kralı, {show:lockI} o anı izlediniz mi',
    'Canlı yayında {extra}, {show} ekibi panik yapmadan çözdü',
    '{show:lockI} o an için {host:dat} heykel dikilsin',
    '{extra} anı {show:gen} en iyi sahnesi oldu',
    'Kriz anı falan değil, şov anıydı resmen {show}',
    '{show:gen} canlı yayın anı şimdiden efsane',
    '{host} soğukkanlılığıyla {show:acc} kurtardı',
  ],
  SocialTopic.crisisFail: [
    '{show:loc} canlı yayın rezaletiydi resmen',
    '{extra} anında {host} dondu kaldı, izlerken utandım',
    '{show} ekibi o krizi hiç yönetemedi',
    'Canlı yayında {extra}, {show} bunu nasıl toparlayamaz',
    '{show:lockI} o an capsi oldu bile',
    '{channel} reji ne yapıyordu o sırada {show}',
    '{show} canlı yayın kazası herkesin ağzında, kötü anlamda',
  ],
  SocialTopic.drama: [
    '{extra}, {show} kulisi karışık',
    'Duyduk duymadık demeyin: {extra}',
    '{show} setinden sızan haber: {extra}',
    '{extra}. {show} hayranları ikiye bölündü',
    'Magazin programları {extra} haberiyle çalkalanıyor',
    '{extra} olayı {show:acc} gündeme taşıdı',
    'Ben zaten biliyordum, {extra}',
    '{extra}? {show} izleyicisi şokta',
  ],
  SocialTopic.holiday: [
    '{extra} geldi, televizyonda ne var bakalım',
    '{extra} programı yapmayan kanal kaldı mı',
    '{extra} kutlu olsun herkese',
    '{extra} için ekran başındayız',
    '{extra} tatilinde bütün gün dizi',
    '{extra} havası başka, {channel} da unutmamış',
  ],
  SocialTopic.film: [
    '{extra} filmine gittik, salon tıklım tıklımdı',
    '{extra} vizyonda, yorum yapmadan önce izleyin',
    '{extra:gen} sonu beni mahvetti',
    '{extra} filmi için iki kere bilet aldım',
    '{extra} afişi her yerde, gitmek lazım',
    '{extra} sinemada izlenecek bir film, televizyonu beklemeyin',
    '{extra} biraz uzun ama değdi',
  ],
  SocialTopic.viral: [
    '{show:lockI} o sahne milyonlarca izlendi',
    '{show} kesiti her yerde dönüyor',
    'Herkes {show:lockI} o anı paylaşıyor',
    '{show:gen} o sahnesi caps oldu bile',
    'Dünkü {show} kesitini izlemeyen kalmadı',
    '{show} gündemin bir numarası',
  ],
  SocialTopic.award: [
    '{show} ödülü fazlasıyla hak etti',
    '{show} ödül aldı, tebrikler {channel}',
    'Yılın programı {show}, tartışmaya gerek yok',
    '{show} ekibi kürsüde, gurur duydum',
    '{host} ödül konuşmasında ağlattı',
  ],
  SocialTopic.random: [
    'Akşam ne izlesem diye bakıyorum, öneri?',
    'Kumanda yine kayıp, kanal değiştiremiyorum',
    'Televizyonda reklam süresi uzadı mı yoksa bana mı öyle geliyor',
    'Pazar akşamı + çay + {channel} = huzur',
    'Eskiden bütün aile aynı programı izlerdi, özledim',
    '{channel} yayın akışını kim hazırlıyor, tebrikler',
    'Bugün yağmur var, evde kanepe günü',
    'Bu akşam {slot} kuşağı çok dolu',
    'Hangi dizi bitti de bu kadar boş kaldım',
    'Bu akşam maç mı izleyelim dizi mi, ev karıştı',
  ],
};

/// Konuya göre hazır etiketler (programın kendi etiketi de eklenir)
const socialExtraTags = <SocialTopic, List<String>>{
  SocialTopic.hit: ['#reyting', '#akşamkeyfi', '#ekranbaşı', '#favori'],
  SocialTopic.flop: ['#sıkıcı', '#kanaldeğiştir', '#reytingyok'],
  SocialTopic.average: ['#ehişte', '#bakalım'],
  SocialTopic.newShow: ['#yenisezon', '#ilkbölüm', '#prömiyer'],
  SocialTopic.ended: ['#sezonfinali', '#elveda'],
  SocialTopic.special: ['#özelbölüm', '#bayram', '#özelgün'],
  SocialTopic.crisisWin: ['#canlıyayın', '#doğaçlama', '#efsaneAn'],
  SocialTopic.crisisFail: ['#canlıyayınkazası', '#rezalet'],
  SocialTopic.drama: ['#kulis', '#magazin', '#dedikodu'],
  SocialTopic.holiday: ['#bayram', '#tatil'],
  SocialTopic.film: ['#vizyonda', '#sinema'],
  SocialTopic.viral: ['#viral', '#gündem'],
  SocialTopic.award: ['#ödül', '#yılınprogramı'],
  SocialTopic.random: ['#televizyon', '#akşam'],
};
