# Basınç uyarısı: eski telefon basıncı ve doğru düğme adı

Sahip, TestFlight 2026-10-16 11:48–12:26 (İstanbul), Hava Durumu ekranı:
İstasyon basıncı 1014.3 hPa, tarih 16.10.2026 07:57 (sabah deniz kenarında
telefon barometresiyle alındı), İrtifa şimdi 359 m. Turuncu uyarı değeri
"deniz seviyesi basıncı olabilir" dedi ve "Basınç al" düğmesini önerdi; ama
ekrandaki düğme "Basıncı yenile" yazıyordu. Asıl sebep değerin eski olması
(başka yerde alınmış). Onay: "Yap".

## Ne

1. Basınç kutusunu telefon barometresi doldurduysa ve bu değer eskiyse
   (düğmenin kullandığı 30 dakika kuralı) uyarı artık şöyle:
   "Bu basınç 07:57'de alındı. 359 m irtifada yaklaşık 971 hPa beklenir;
   yer değiştirdiyseniz "Basıncı yenile"ye basın."
   Değer başka bir gün alındıysa saat yerine "15.10.2026 07:57" yazar.
   Basınç çok yüksek de olsa çok düşük de olsa aynı cümle kullanılır.
2. Elle yazılmış ya da taze (30 dakikadan yeni) telefon değerinde eski
   mesajlar aynen kalır; yalnız mesajdaki düğme adı, o an düğmede yazan
   adla aynıdır ("Basınç al", "Basınç alındı" ya da "Basıncı yenile").
3. Hava verisi alındıktan sonra çıkan bilgi yazısı ("Basınç için "…",
   irtifa için İrtifa kartı…") da düğmenin o anki adını yazar; düğme adı
   sonradan değişirse (ör. 30 dakika dolunca) yazı da değişir.

## Nasıl

- `ballistics_screen.dart`: düğme adı tek bir yerde üretiliyor:
  `_pressureActionLabel` ('Basınç alındı' / 'Basıncı yenile' / 'Basınç
  al'). Düğme (`hava_durumu_view.dart`) ve iki mesaj bu getter'ı kullanıyor;
  metinlerin ikinci bir kopyası yok. Düğme okurken yine "Okunuyor…" yazar.
- `_pressureWarning`: eşik hesapları aynı (1050/950 hPa'nın irtifadaki
  karşılığı, ±1 hPa). Yeni dal yalnız şu üç koşul birlikteyken çalışır:
  eşik aşıldı, değer telefondan geldi ve eski, alınma saati biliniyor.
- Saat yazısı `_pressureTakenAtText`: mevcut `fetchDateTimeText` (Basınç
  kartının altındaki tarih satırının kullandığı biçim) kullanılır; aynı
  gün ise yalnız "SS:dd" kısmı alınır.
- Hava verisi bilgi yazısı saklanırken düğme adı yerine bir yer tutucu
  (`{basinc-dugmesi}`) konur; yazı ekranda gösterilirken o anki düğme
  adıyla değiştirilir.

## Neden

Uyarı yanlış sebebi (deniz seviyesi değeri) söylüyordu ve ekranda olmayan bir
düğme adını gösteriyordu. Eski telefon değerinde en olası sebep yer
değiştirmek; kullanıcıya ne zaman alındığını ve hangi düğmeye basacağını
söylemek doğrudan çözüm.

## Uç durumlar

- Eski kayıtlarda alınma saati yok (`pressureFetchedAtMs` boş): değer eski
  sayılır, düğme "Basıncı yenile" yazar; saat bilinmediği için eski mesaj
  gösterilir ama düğme adı "Basıncı yenile" olur.
- Telefon saati geri alınmışsa (alınma saati gelecekte): değer eski sayılır
  (önceki kural), yeni mesaj alınma saatini yazar.
- Düğme okurken ("Okunuyor…", en çok birkaç saniye) mesajlar okumadan
  önceki adı yazar; "Okunuyor…" basılacak bir düğme adı olmadığı için
  mesaja konmadı.
- Değer elle değiştirilince `_pressureFilled` kapanır: eski mesaj ve
  "Basınç al" adı geri gelir.
- 30 dakika dolunca mevcut tazelik zamanlayıcısı sayfayı yeniler; uyarı ve
  bilgi yazısı kendiliğinden "Basıncı yenile"ye geçer.

## Bilerek yapılmayan

- Hesap, uyarı eşikleri, kayıtlı veri ve yerleşim değişmedi.
- "Basınç çok düşük" mesajının elle yazılmış değerdeki metni değişmedi
  (düğme adı içermiyor).
- Düğme adlarının kendisi değişmedi.
- Mevcut testlerde değişiklik gerekmedi: tam metin karşılaştıran eski test
  yok (`shot_settings_test.dart` yalnız "deniz seviyesi basıncı" parçasını
  arıyor ve o durum elle yazılmış değer, metni aynı).
- PR #357 aynı iki dosyaya dokunuyor (rüzgâr rehberi); bu PR başka
  satırlarda, main'in son hâli (#358 dahil) üzerine kuruldu.

## Testler

Yeni dosya `test/basinc_uyari_metni_test.dart` (sahte saat + sahte
barometre):

- 07:57'de 1014.3 alındı, saat 11:47, İrtifa 359 → tam metin "Bu basınç
  07:57'de alındı. 359 m irtifada yaklaşık 971 hPa beklenir; yer
  değiştirdiyseniz "Basıncı yenile"ye basın."; "Basınç al" ve "deniz
  seviyesi" yok; düğme "Basıncı yenile".
- Dün 07:57'de alındı → "15.10.2026 07:57'de alındı".
- Eski değer, çok düşük (912.4 hPa, 0 m) → aynı cümle kalıbı, 1013 hPa.
- 5 dakika önce alındı (taze) → deniz seviyesi mesajı, düğme ve mesaj
  "Basınç alındı".
- Elle 1014.3 (hiç alınmadı) → eski metin aynen, "Basınç al".
- Elle 700 hPa, 0 m → eski "çok düşük" metni aynen.
- Hava verisi bilgi yazısı: önce "Basınç al", basınç alınınca "Basınç
  alındı", 30 dakika sonra "Basıncı yenile"; yer tutucu ekranda görünmez.

Yerel:

- `python3 tools/offline_dart_lint.py`: PASS (407 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 868 test, OK.
- Flutter SDK bu ortama kurulamadı (Dart SDK indirmesi ağ vekili
  tarafından 403 ile engellendi): `flutter test`/`flutter analyze` yerelde
  BLOCKED. Sonuç yalnız CI'dan.

## CI

CI_PLACEHOLDER
