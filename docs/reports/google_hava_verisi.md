# Google hava verisi (Hava Durumu) — rapor

Dal: `feat/google-hava-verisi` · Taslak PR · Sahip kararları 2026-10-17
20:13–20:44 (İstanbul), TestFlight 113.

## Ne

- Hava Durumu'nun hava verisi (sıcaklık, nem, basınç, rüzgâr hızı ve yönü)
  artık önce **Google Weather API**'den alınıyor; sayfa bunlardan bugünkü
  gibi **sıcaklık, nem ve rüzgâr hızı** kutularını doldurur (basınç kutusu
  için bkz. "Bilerek yapılmayan"). Google cevap vermezse (anahtar yok, ağ
  yok, zaman aşımı, 200 dışı yanıt, okunamayan/akla yatkın olmayan veri) veri
  **bugünkü gibi MET Norway**'den alınıyor.
- Hava kartı notu: Google kaynaksa
  `Hava verisi konumdan dolduruldu (Google, HH:MM). Basınç için "Basınç al", irtifa için İrtifa kartı. Rüzgâr yönünü siz seçin.`
  MET kaynaksa metin hiç değişmedi: `… (MET Norway (CC BY 4.0), HH:MM) …`.
- Rüzgâr kartının en altında, Hava notuyla aynı kutu (mavi sol çizgi,
  aynı `MenzilNotice`):
  `Google rüzgâr verisi (HH:MM): <yön>dan, <derece>°, <hız> m/s. Rüzgâr yönünü siz seçin.`
  Örnek: `Google rüzgâr verisi (20:00): kuzeybatıdan, 315°, 4,2 m/s. Rüzgâr yönünü siz seçin.`
  MET kaynaksa `MET Norway rüzgâr verisi (HH:MM): …` (MET'in
  `wind_from_direction` / `wind_speed` değerleri).
- Rüzgâr hızı kutusu bugünkü gibi doldurulur (elle değiştirilebilir).
  **Rüzgâr saati otomatik değişmez.**
- Gizlilik metinleri (03 TR + EN, 02) güncellendi: yuvarlanmış konum Google
  Weather API'ye de gidiyor, MET Norway yedek.

## Nasıl

- `lib/tools/adapters/google_weather_provider.dart` (yeni): mevcut
  `WeatherProvider` portu. `GET https://weather.googleapis.com/v1/currentConditions:lookup`
  `?location.latitude=…&location.longitude=…&unitsSystem=METRIC&key=…`,
  başlık `X-Ios-Bundle-Identifier: com.sniperturk.sniperTurk`.
  Anahtar `String.fromEnvironment('GOOGLE_MAPS_IOS_API_KEY')` (yalnız
  TestFlight derlemesinde; depoda yok). Anahtar boşsa **istek gönderilmez**.
  Konum MET'teki gibi 2 ondalığa (~1 km) yuvarlanır.
- Alan eşlemesi (Google'ın resmî belgesi:
  developers.google.com/maps/documentation/weather/current-conditions ve
  …/weather-units-systems):
  | Google alanı | Birim (METRIC) | Uygulama |
  |---|---|---|
  | `temperature.degrees` (`unit: CELSIUS`) | °C | sıcaklık °C |
  | `relativeHumidity` | % | nem % |
  | `airPressure.meanSeaLevelMillibars` | mb (= hPa) | basınç hPa, `PressureKind.seaLevel` (MET ile aynı) |
  | `wind.speed.value` (`unit: KILOMETERS_PER_HOUR`) | **km/h** | m/s = km/h ÷ 3,6 (örn. 8 km/h → 2,222… m/s; 36 km/h → 10 m/s) |
  | `wind.direction.degrees` | ° (rüzgârın geldiği yön) | yalnız not |
  | `currentTime` | RFC 3339 UTC | notlardaki HH:MM (yerel saat) |
- Doğrulama: sıcaklık −90…60 °C, nem 0…100, basınç 850…1100 hPa, hız
  0…410 km/h, yön 0…360°; birim CELSIUS / KILOMETERS_PER_HOUR değilse,
  alan eksikse ya da sayı değilse yanıt reddedilir → MET Norway.
- `lib/tools/adapters/fallback_weather_provider.dart` (yeni): önce Google,
  her hata/istisnada MET Norway (aynen bugünkü sağlayıcı). İkisi de
  başarısızsa MET'in hatası gösterilir (bugünkü mesajlar).
  `lib/tools/tools_services.dart` üretim bağlantısı bu sağlayıcı.
- `WeatherObservation.source` (yeni alan, `WeatherSource.google /
  metNorway / other`; varsayılan `other`): hangi kaynağın kullanıldığı
  gözlemle taşınır. Kaydedilen veri değişmedi.
- `lib/features/ballistics/wind_source_note.dart` (yeni): not metni. 8 yön,
  45°'lik dilimler (kuzeyden, kuzeydoğudan, doğudan, güneydoğudan, güneyden,
  güneybatıdan, batıdan, kuzeybatıdan); derece tam sayıya yuvarlanır,
  360° → 0°; hız 1 ondalık, virgülle.
- Sayfa: not bellekte tutulur (Hava notu gibi), yalnız veri alındıktan
  sonra görünür, Hava kartının **Sıfırla**'sı onu da siler. Not Rüzgâr
  kartındaki alan ızgarasının en sonuna eklendi; önceki kutular yer
  değiştirmez (yazılan değer kaybolmaz).

## Neden

- 20:14 "Bu veriyi Google'dan alacaktık! Rüzgâr ve basınç da buradan
  alınacaktı!", 20:37 Google önce, MET yedek. 20:40 not kutusu, saat kalsın.
  20:44 seçenek 1: Google yönü saate çevrilmez, atış azimutu kullanılmaz.

## Hesaba etkisi (somut sayılar)

- Hesap kutulardaki metinden yapılır; `source` alanı hesaba hiçbir yerde
  girmez (`grep WeatherSource lib` → yalnız port, adaptörler ve not metni).
- Widget testi: aynı değerler (18,5 °C, %55, 1012,3 hPa deniz seviyesi,
  4,2 m/s, 315°) Google'dan da MET'ten de gelse kutular aynı
  (`18.5`, `55`, basınç boş, irtifa boş, `4.2`, yön boş) ve sayfadaki bütün
  metinler (Hava özeti dahil, iki not hariç) birebir aynı.
- Bağımsız referans (tools/formula_reference.py, CIPM-2007): 18,5 °C,
  1013,25 hPa, %55 → hava yoğunluğu 1,2055 kg/m³, ses hızı 342,94 m/s,
  yoğunluk irtifası ≈ 167 m — kaynak ne olursa olsun aynı girdi, aynı sonuç.
- Çözücü, ateşli silah altın sayıları ve formül testleri değişmedi (çözücü
  koduna dokunulmadı; tam test paketi CI'da).
- Not: hız birimi dönüşümü tam (÷ 3,6). Google rüzgârı tam sayı km/h
  verdiği için kutuda 0,1 m/s çözünürlük yeterli (örn. 15 km/h → 4,2 m/s).

## Uç durumlar

- Anahtarsız derleme (Simulator, PR CI): Google'a hiç istek gitmez, doğrudan
  MET Norway; not "MET Norway …" der.
- Google 403 (anahtar kısıtı/bundle uyuşmazlığı), 429, 5xx, zaman aşımı
  (10 sn), bozuk JSON, Fahrenheit/mph birimi → MET Norway.
- Rüzgârsız hava yön alanı olmadan gelirse (0 km/h) 0° kabul edilir.
- 359,6° → `kuzeyden, 0°`; 22,4° kuzey, 22,5° kuzeydoğu.
- Imperial birimde Rüzgâr hızı kutusu bugünkü gibi mph; not sahibin
  metnindeki gibi m/s.
- Veri alınamazsa önceki not (kutudaki değerlerle birlikte) kalır; Sıfırla
  siler.
- Anahtar hiçbir mesajda/logda yok: `ClientException` metni (URL'yi, yani
  anahtarı içerir) aktarılmaz; Python güvenlik testleri bunu denetliyor.

## Bilerek yapılmayan

- Rüzgâr yönü otomatik ayarlanmıyor, saat dönüşümü ve azimut hesabı yok.
- Yeni alan yok, başka sayfa yok, aralık/yerleşim değişikliği yok
  (`fix/hava-aralik-tarih` dalının alanlarına dokunulmadı; dal, o değişikliği içeren main @ 53100e05 üzerine yeniden kuruldu, çakışma çıkmadı).
- **Basınç kutusu bu çekişte de doldurulmuyor.** Google'ın basıncı gözleme
  okunuyor (MET gibi `seaLevel`), ama sayfanın 2026-10-12 kuralı ("her kutu
  kendi düğmesiyle", basınç yalnız "Basınç al") ve görevdeki not metni
  (`Basınç için "Basınç al"`) korunarak İstasyon basıncı kutusuna
  yazılmadı. Sahip 20:37'de "basınç da Google'dan gelsin" dediği için bu
  karar sahibe sorulmalı; yazılacaksa deniz seviyesi → istasyon basıncı
  çevrimi irtifa gerektirir (ayrı görev).
- Araçlar > Hava sayfasındaki "Veri, … hava servisinin model tahminidir"
  metni sağlayıcının adını aldığı için kendiliğinden
  "Google ya da MET Norway (CC BY 4.0)" oldu; başka değişiklik yok.
- Gizlilik etiketinde ayrıca gördüğüm, bu görevin dışında kalan bir nokta:
  İrtifa → Haritadan (`google_elevation_provider.dart`) konumu 5 ondalıkla
  (~1 m) gönderiyor; 02 belgesindeki "hassas konum hiçbir yere
  gönderilmiyor" cümlesi bununla çelişiyor. Düzeltilmedi; ayrı görev önerisi.

## Testler

- `test/google_weather_provider_test.dart`: Google'ın belgelenmiş yanıt
  şeklinden kurulmuş JSON (canlı anahtar yok); alan eşlemesi, km/h → m/s,
  aralık/birim reddi (19 durum), anahtar yok → istek yok, istek adresi,
  yuvarlanmış konum, METRIC, bundle başlığı, HTTP 400/403/404/429/500/503,
  ağ hatası, zaman aşımı, anahtarın hata metninde olmaması.
- `test/fallback_weather_provider_test.dart`: Google tamam → MET'e
  sorulmaz; Google 403/500/429/ağ/bozuk/zaman aşımı/anahtarsız → MET,
  `source` doğru; ikisi de hata → MET hatası; üretim bağlantısı.
- `test/google_hava_notu_test.dart`: sahibin örneği, MET metni, 8 yön,
  0°/360°/359,6°, dilim sınırları, virgüllü ondalık.
- `test/google_hava_notu_widget_test.dart`: iki not (Google ve MET) tam
  metin, aynı kutu tonu, veri yokken not yok, saat değişmiyor, not Rüzgâr
  kartının altında ve sola hizalı, Sıfırla siliyor, 320 pt × 1,3 yazı
  ölçeğinde taşma yok, aynı değerler → aynı sayfa.
- Python: `tools/test_denetim_2026_10_14b_ruz.py` anahtarı okuyan dosyalar
  listesine yeni adaptör eklendi + yeni `GoogleWeatherKeyHandlingTest`
  (log yok, hata metninde URL/anahtar yok, anahtarsız istek yok, bundle
  başlığı, yuvarlanmış konum); `tools/test_m1_tools_scope_contract.py` izinli
  ağ adaptörlerine eklendi. AIza… anahtar testi yerinde.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (441 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test; ilk
  çalıştırmada 2 güvenlik testi yeni adaptörü tanımadığı için kırmızıydı,
  testler genişletildi, sonra o iki dosya (33 test) yeşil.

## Ekran görüntüleri

`integration_test/google_hava_notu_screens_test.dart` (sahte sağlayıcı:
Google 390 pt, Google 320 pt, MET 390 pt). **Henüz çalıştırılmadı:**
Simulator kuyruğu başka işlerle dolu (ana oturum yönetiyor); kuyruk
boşalınca `sim-screens.yml` ref=`feat/google-hava-verisi`,
test=`integration_test/google_hava_notu_screens_test.dart` ile
çalıştırılacak. Ekran görüntüsü yokken "geçti" denmez.

## CI bağlantıları

- Tam test paketi (`test-diag`, files=test): **başarılı** —
  https://github.com/sniperTurk/flutter-app/actions/runs/39057728667
  (commit 8e30e634; sonraki commit yalnız eşitlik testini sıkılaştırdı)
- Yeni testler (ilk çalıştırma, 1 test düzeltildi):
  https://github.com/sniperTurk/flutter-app/actions/runs/39057531272
- `analyze-diag`: **başarılı** —
  https://github.com/sniperTurk/flutter-app/actions/runs/39057532974
- `dart format` (format-fix, iki kez, CI commit'i):
  https://github.com/sniperTurk/flutter-app/actions/runs/39057529183
- PR iOS CI, head 44103635 (main @ 4333f27e #404 birleştirildikten sonra): `dart-checks` **başarılı**, `wind-acceptance` **başarılı**, `verify` **başarılı** — https://github.com/sniperTurk/flutter-app/actions/runs/39072356352
  (Önce: 6e800f1b'de `verify` arşiv adımında dışarıdan iptal edildi; ef04fb3e'de main @ 53100e05'in kendi derleme hatası (#389 + #395) nedeniyle `dart-checks` kırmızıydı, #404 ile giderildi.)
- Code Review + Security review (alt ajan, statik): anahtar sızıntısı
  bulunmadı. Bulunan küçük noktalar: eşitlik testi ikinci kaynağı gerçekten
  çekmiyordu → düzeltildi (6e800f1b); Google 10 sn zaman aşımı + MET 12 sn →
  en kötü durumda ~22 sn bekleme; başarısız çekişte eski rüzgâr notu
  kalıyor (bilinçli, kutudaki değerlerle birlikte); Araçlar > Hava
  metni "Google ya da MET Norway (CC BY 4.0)" oldu.

## Cihazda kontrol gerekli

Google anahtarı yalnız TestFlight derlemesinde var. Simulator ve CI'da
Google'a hiç istek gitmez; gerçek Google yanıtı, anahtar kısıtı
(bundle başlığı) ve Hava notundaki "(Google, HH:MM)" ancak **TestFlight'ta
gerçek cihazda** görülebilir. Google Cloud Console'da Weather API istek
sayısının 0'dan artması da bunu doğrular. Kota: ayda 10.000 istek ücretsiz,
sonrası 1.000 istekte 0,15 $ (Google).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
