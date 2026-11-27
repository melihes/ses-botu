# Reyting

Türkçe, yatay (landscape), TV kanalı patronu tycoon/idle oyunu. Flutter ile Android ve iOS.
Tüm kanal, program ve kişi isimleri kurgusaldır.

## Klasör yapısı
- `lib/core/` – renk teması, Türkçe para/sayı biçimi
- `lib/data/` – kurgusal içerik: türler, kuşaklar, ekipman, lüks eşyalar, kanallar, isimler
- `lib/models/` – veri yapıları (kadro, program, kredi, pazarlık…)
- `lib/engine/` – ekonomi formülleri (`economy.dart`) ve oyun motoru (`game.dart`)
- `lib/ui/` – ekranlar, pencereler, ortak bileşenler
- `test/` – otomatik testler
- `docs/DERSLER.md` – benzer oyunlardaki hatalardan çıkarılan dersler

## Komutlar
```
flutter test                 # testler
flutter build apk --release  # Android kurulum dosyası
```
1 oyun günü = 1 gerçek dakika. Ayarlar > Test modu ile zaman hızlandırılabilir.
