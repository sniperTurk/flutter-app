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
- Saatin ekindeki "'de" sahibin örneği (07:57'de) için doğru; diğer
  saatlerde Türkçe okunuşa göre değişir: son okunan sözcük dakika (00
  ise saat). Ör. "07:53'te", "08:40'ta", "10:00'da", "09:06'da"
  (`_timeSuffix`). Code Review bunu buldu; sabit "'de" yanlış Türkçe
  olurdu.
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
- Ek uyumu: 07:53 → "07:53'te", 08:40 → "08:40'ta", 10:00 → "10:00'da",
  09:06 → "09:06'da".
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

Kod commit'i `43603a9` üzerinde (bu rapor commit'inden önceki son kod):

- iOS CI (PR): success. https://github.com/sniperTurk/flutter-app/actions/runs/38881755670
  - `verify`: success (iOS Simulator derleme ve açılış testi dahil).
  - `dart-checks`: success (biçim, `flutter analyze`, birim ve widget testleri).
  - `wind-acceptance`: success.
- `gh workflow run 375209577` (One-off dart format fix): success, değişiklik
  gerekmedi (commit eklemedi). https://github.com/sniperTurk/flutter-app/actions/runs/38881747582
- `test-diag.yml` (files=test): success. https://github.com/sniperTurk/flutter-app/actions/runs/38882018054
- `analyze-diag.yml`: success. https://github.com/sniperTurk/flutter-app/actions/runs/38882020921

İlk kod commit'i `d0ef558` için başlayan iOS CI, yeni commit gelince iptal
edildi (cancelled): https://github.com/sniperTurk/flutter-app/actions/runs/38881250237

Code Review ve Security review PR'da çalıştı. Code Review bir gerçek sorun
buldu (saat ekinin Türkçe uyumu, sabit "'de"); `43603a9` ile düzeltildi.
Security review sorun bulmadı (yalnız ekranda metin üretimi; ağ, kayıt ya da
dış girdi yok).

Simulator dışında cihaz, imza, TestFlight ve App Store işlemi çalışmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01NBSrDv9J77WeDsAychwciP
