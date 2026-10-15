# Garmin saati Pro Ayarlar'da (2026-10-16)

Sahibin kararı (İstanbul, 2026-10-16 01:00–01:04): "Garmin özelliğini Pro
Ayarlar'a alalım", "Garmin isteğe bağlı deriz", "Garmin başlığı yanında ⓘ;
içine nasıl kullanıldığı, aktif etmenin faydaları ve aktif etmediğinizde
ayarlarınızda hiçbir değişiklik olmadığı yazsın".

## Ne yapıldı

- "Garmin saati" satırı Araçlar'dan kaldırıldı, Pro Ayarlar'ın en sonuna,
  "Tüfek düzeltmeleri"nden sonra, "Hedef'e geç" düğmesinden önce kondu.
- Başlık satırı: "Garmin saati", hemen yanında ⓘ, sağ uçta ikincil renkte
  (#9CB1C0, koyu tema) "isteğe bağlı". "Ek mühimmat bilgileri" başlığıyla
  aynı yazı stili.
- ⓘ, öteki Pro ⓘ'leri gibi alttan açılan sayfada açılır; içinde tek
  paragraf açıklama ve "Kapat" var.
- Satırın görünüşü aynı: gri-mavi (#1B3245) üstünde beyaz saat simgesi,
  sola yaslı yazı, alt satırda seçili saat sayısı; satıra dokununca Garmin
  Connect açılır (önceki gibi).

## Nasıl

- `lib/features/tools/garmin_pair_tile.dart` → `lib/features/ballistics/garmin_pair_tile.dart`
  (git'te taşıma). Başlık satırına ⓘ ve "isteğe bağlı" eklendi; altındaki
  boşluk Pro kutularınınki gibi 8 pt.
- `pro_ayarlar_view.dart`: Tüfek düzeltmeleri kutusundan sonra
  `const GarminPairTile()`.
- `tools_screen.dart`: satır ve import silindi (bayrak yok).
- `pro_section_info.dart`: ⓘ metni `ProSectionInfo.garmin` sabitinde,
  öteki Pro açıklamalarının yanında.
- `pro_info_sheet.dart`: alttan sayfaya isteğe bağlı `text` (tek paragraf)
  eklendi; öteki Pro kutularında değişiklik yok (Ne? / Neden önemli? /
  Nasıl? aynı).
- `menzil_widgets.dart` `MenzilToolTile`: üç isteğe bağlı parametre:
  `titleTrailing` (başlığın hemen yanı: ⓘ), `titleEnd` (satırın sağ ucu:
  "isteğe bağlı") ve `margin` (varsayılan eskisi gibi 10 pt). Araçlar'daki
  öteki satırlar değişmedi.
- `tools/test_v271_removed_feature_scope.py`: Garmin satırının artık
  Araçlar'da olmadığını ve Pro Ayarlar'da olduğunu denetler.

## Neden

Sahip Garmin'i Pro Ayarlar'da, isteğe bağlı bir seçenek olarak istedi.
Satır bir hesap ayarı değildir: hiçbir Pro özetine sayılmaz ve hiçbir
hesap onu okumaz.

## ⓘ metni ve koda göre denetim

Kullanılan metin:

> Hesap sonucunu (üst ve yan kule klikleri, mesafe, rüzgâr) Garmin saatinize
> gönderir; sonucu telefonu çıkarmadan bileğinizden okursunuz. Nasıl
> kullanılır: saatinize Connect IQ mağazasından SNIPER TÜRK uygulamasını
> yükleyin, bu satıra dokunun ve Garmin Connect'te saatinizi seçin. Sonra
> Hedef'teki her yeni hesap saate kendiliğinden gider; saatten mesafe de
> gönderebilirsiniz. Kullanmazsanız hiçbir ayarınız ve hesabınız değişmez.

Tek değişiklik: "Sonra her yeni hesap" → "Sonra **Hedef'teki** her yeni
hesap". Neden: telefon sonucu yalnız Hedef sayfası açıkken gönderir
(`ballistics_screen.dart` `_publishWatch`, `_isShotView`); Hedef'ten
çıkınca saate "Çözüm yok" gider (`_withdrawWatch`). Tablo, Hava Durumu veya
Pro'daki hesaplar saate gitmez.

Doğru bulunan kısımlar:

- Gönderilenler (`watch_solution.dart` `toMessage`): üst ve yan klik
  (`up`, `right`), aynı düzeltmenin açısı, mesafe (`range`, birimiyle),
  rüzgâr hızı ve saat yönü (`windSpeed`, `windClock`; yalnız rüzgâr
  girilmişse), profil adı. Saat bunları gösterir (`garmin/source/MainView.mc`).
- Saatten mesafe: saat `setRange` gönderir (`garmin/source/RangeView.mc`),
  telefon `WatchBridge.rangeRequests` ile alır ve Hedef'in mesafesini
  değiştirir (`_onWatchRange`).
- "Bu satıra dokunun ve Garmin Connect'te saatinizi seçin":
  `GarminLink.selectDevice()` Garmin Connect'i açar.
- "Kullanmazsanız hiçbir ayarınız ve hesabınız değişmez": satır hiçbir
  ayarı ya da hesabı değiştirmez.

Kodla denetlenemeyen kısım: "Connect IQ mağazasından". `garmin/README.md`
(8. madde) ve `garmin/manifest.xml`'e göre uygulamayı Connect IQ Store'a
sahibin Garmin hesabıyla yüklemesi gerekiyor; mağazada olup olmadığı koddan
görülemez. Metin sahibin sözü olduğu için değiştirilmedi; mağaza yüklemesi
bitmeden bu cümle kullanıcı için henüz doğru değil.

## Uç durumlar

- Garmin köprüsü olmayan sürüm (TestFlight, CI): satır ve ⓘ hiç yok, yer de
  kaplamaz; Pro sayfasının düzeni değişmez (test: satır konumları ±0,5 pt).
- Köprülü sürüm, saat seçilmemiş: "Saat seçilmedi: Garmin Connect'te
  saatinizi seçin".
- ⓘ'ye dokunmak Garmin Connect'i açmaz; yalnız açıklamayı açar.
- Dar ekran (320 pt) ve yazı ölçeği 1.3: başlık ve "isteğe bağlı" gerekirse
  alt satıra kayar, taşma olmaz. Başlık ile ⓘ satırın en çok dörtte üçünü
  alır; "isteğe bağlı" her zaman sağ uçta durur. 390 pt'lik telefonda yer
  dar olduğundan "isteğe bağlı" iki satıra bölünebilir (isteğe / bağlı).
- Kaydedilmiş veri yok; silinen veri yok.

## Bilerek yapılmayan

- Saat uygulaması, köprü, gönderilen değerler ve hesaplar değişmedi.
- Araçlar'daki öteki satırlar, Pro'daki öteki kutular ve özet yazıları
  değişmedi.
- garmin-sim.yml çalıştırılmadı (Garmin lisansı).
- Birleştirme ve TestFlight yok.

## Testler

- `test/garmin_pro_ayarlar_test.dart` (yeni): köprüyle satır Tüfek
  düzeltmeleri'nden sonra, Hedef'e geç'ten önce; ⓘ ve "isteğe bağlı" var;
  ⓘ alttan sayfayı açar ve metin aynen görünür; köprüsüz hiçbir şey yok,
  kutuların konumu köprülü/köprüsüz aynı (±0,5 pt), özet yazıları aynı;
  320 ve 390 pt, yazı ölçeği 1.0 ve 1.3'te taşma yok.
- `test/garmin_link_test.dart`: yeni dosya yolu; başlık satırında sırasıyla
  başlık, ⓘ, "isteğe bağlı" (#9CB1C0, sağ uçta, oktan önce); ⓘ eşleştirme
  yapmaz;
  Araçlar'da köprü olsa da olmasa da satır yok.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (395 Dart dosyası,
  0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 861
  test OK.
- Bu ortamda Flutter SDK indirilemedi (storage.googleapis.com engelli);
  `flutter test` ve `flutter analyze` yalnız CI'da çalıştı.

## CI

CI_PLACEHOLDER

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
