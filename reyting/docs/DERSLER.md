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
