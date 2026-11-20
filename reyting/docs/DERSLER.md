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
