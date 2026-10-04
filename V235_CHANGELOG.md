# V235

- Kronograf ekranı v234'teki gerçek iOS PCM capture controller'a bağlandı.
- Kullanıcıdan hedef mesafesi ve sıcaklık alınarak akustik ortalama hız tahmini başlatılıyor.
- Mikrofon sonucu UI'da açıkça deneysel/tahmini gösteriliyor; namlu çıkış hızı veya doğrulanmış `valid` sonuç olarak sunulmuyor.
- Capture sırasında tekrar başlatma engellendi; controller ekran kapanırken durduruluyor.
- Native köprü/izin/cihaz hataları kullanıcıya başarısızlık olarak gösteriliyor.
- Production wiring için offline sözleşme regresyon testleri eklendi.

## Doğrulama sınırı
Bu sürümde Flutter SDK/Xcode çalıştırılmadıysa Dart/Swift derlemesi, Simulator ve fiziksel iPhone sonucu başarılı kabul edilemez.
