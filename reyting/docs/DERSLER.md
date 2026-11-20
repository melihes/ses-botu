# Rakip oyunlardaki şikâyetlerden çıkan dersler

Bu liste, benzer oyunların topluluk yorumlarında görülen hatalardan çıkarıldı.
Her yeni özellik eklenirken bu listeye karşı kontrol edilir.

1. **Çevrimdışı hesap simetrik olmalı.** Gelir ve gider aynı motorla, aynı adımlarla işlenir
   (`Game._advance`). Test: `test/economy_test.dart` → "çevrimdışı gelir de işlenir".
2. **Satın alınan her şeyin etkisi açıkça yazılmalı** (tek seferlik mi, süreli mi, kalıcı mı).
3. **Bulut kaydı:** cihaz sıfırlansa da ilerleme kaybolmamalı (Aşama 3, Firebase Auth + Firestore).
4. **Tek kişilik içerik internetsiz çalışmalı.** Online işlemlerde anlaşılır hata + otomatik yeniden deneme.
5. **Oyun her açılışta ana ekranda başlamalı.**
6. **Tek para birimi**, çok büyük sayılar doğru biçimlenmeli (Mr, Tn, Ktr).
7. **Saat hilesine karşı koruma:** geri alınan saat yok sayılır; online'da sunucu saati esastır.
8. **Arkadaş/ortaklık gibi sosyal özellikler** yayına çıkmadan önce iki gerçek hesapla uçtan uca test edilmeli.
9. **Oyuncuya seçim hakkı:** otomatik işlemler (ör. yöneticiler) oyuncunun tercihine göre ayarlanabilmeli.

## Ekonomi dengesi (v0.5)
`test/sim/balance_sim.dart` makul oynayan bir botla oyunu 300 gün oynatır:
`flutter test test/sim/balance_sim.dart`. Hedef: stüdyo seviyelerine yaklaşık
13 / 37 / 70 / 128 / 184. günde ulaşılması (1 gün = 1 dk). Sayılar değişince bu
simülasyon tekrar çalıştırılmalı.

Olaylar ve kararlar oyunu yönlendirmemeli: reyting etkisi ±%20 ile sınırlı,
kararlar oyunu durdurmaz ve cevap verilmezse güvenli seçenek otomatik seçilir.

## Rekabet dengesi (v0.6)
Simülasyon iki bot oynatır: AKILLI (reklam ayarı, tür-kuşak uyumu, kadro güçlendirme,
holding) ve ÖZENSİZ (ayar yok, rastgele tür, kadro güçlendirme yok).
Hedef: akıllı oyuncu son seviyeye ~200-220. günde, 300. günde şirket değeri
özensizin ~5-8 katı; özensiz oyuncu da ilerleyebilmeli (imkânsız değil).
Kaçak liderliği frenleyen kurallar: rakip baskısı (zamanla en fazla -%35),
aynı türe yığılma cezası (her ek program -%12), boştaki kadroya yarım maaş.
Online sıralama ölçüsü: Şirket Değeri (kasa + varlıklar - borç).

## Uzun vade: 1 yıllık zirve (v0.7)
`flutter test test/sim/long_sim.dart --dart-define=DAYS=80000` akıllı botu 80.000 gün oynatır.
Varsayım: ciddi oyuncu gerçek günde ~180-200 oyun günü ilerler (aktif oyun + çevrimdışı).
Ölçülen: ilk 100 ~800. gün, 12. (son) stüdyo seviyesi ~65.000. gün (~1 yıl), o anda
zenginler listesinde ~9. sıra. Birincilik için borsa al-satı gerekir.
Uzun simülasyonun yakaladığı hatalar: sınırsız katlanan YouTuber takipçisi (doyma tavanı
eklendi) ve üst üste binen zamlar (maaş tavanı = piyasa maaşının 2 katı).

## Genel denetim (v0.8.2)
`test/chaos_test.dart`: 12 senaryoda 6000'er rastgele hareket; her adımda oyunun
tutarlılığı (kasa, kadro-program bağları, kuşaklar, hisse sınırları, kaydet/yükle) denetlenir.
Bulunan ve kapatılan açıklar:
- Kanal al-sat ile para basma (satış %80 > pazarlık tabanı %74) → satış %65.
- Borsada büyük al-sat ile para basma (fiyat etkisi) → işlem ortalama fiyattan.
- Bitmiş program/film her törende tekrar ödül alıyordu → sadece son 30 gün.
- Sezon bitince sponsor programda kalıyordu → temizleniyor.
- 1 dakikadan kısa ayrılıklarda zaman kayboluyordu → sessizce işleniyor.
- Satın alınan kanal oyuncuya transfer teklifi yapabiliyordu → engellendi.
Bilinen sınır: telefon saatiyle oynanarak çevrimdışı ilerleme tekrarlanabilir; online
sıralamada sunucu bunu reddeder (oyun zamanı gerçek zamandan hızlı akamaz).

## Gerçek takvim dengesi (v0.9)
Hedef oyuncu: günde ~1 saat (3 x 20 dk) oynar; aralarda kanal 8 saate kadar, yarı hızda
çalışır (Genel Müdür biten sezonları yeniler). `flutter test test/sim/calendar_sim.dart`
ile ölçülür (~1 dk). Ölçülen: 1. gün 5. seviye, ~9. gün 7. seviye, ~1. ay ilk 100,
~341. gün son seviye (12), 1 yıl sonunda ~ilk 10-15. 1 numara ekstra emek ister
(borsa, sinema, kanallar, daha sık oynamak). Online'da sıralamayı gerçek oyuncular belirler.

## v0.10 notları
- Sentezlenmiş karakter sesleri ve kahkaha kulağa kötü geldiği için kaldırıldı;
  yerine sahneye özel konuşma balonları (film: "Motor!/Kestik!", bilgi yarışması:
  "A şıkkı, son kararım!" …). Sadece kısık alkış/tribün sesi kaldı.
- 10 kuşak (5 zaman dilimi x 2). Eski 4 kuşaklı kayıtlar otomatik taşınır.
- Tuzak: önce biten program en iyi kuşağı kapıyor, Genel Müdür de herkesi aynı
  yere geri koyuyordu → "Kuşak değiştir" (taşı/yer değiştir) ve "⭐ Önerilen" etiketi.
- Genel Müdür maaşlı çalışan; maaşı günlük net hesabına dahil (hata düzeltildi).
- Günlük görevler sadece oyuncunun yapabileceği türden seçilir.
