# Güvenlik ve kod sağlığı denetimi — 2026-10-11 (main @ 3a0e645)

Kapsam: depo + tüm git geçmişi (900 commit, tüm dallar), `lib/`, `.github/workflows/`,
iOS yapılandırma betikleri (`tools/configure_ios_*.py`), `pubspec.yaml`/`pubspec.lock`.
Yerel Flutter SDK yok: Dart davranışı statik okundu, testler CI'da (`test-diag.yml`) koştu.
Bu raporda **hiçbir gizli değer yazılmamıştır**; yalnız dosya/commit ve tür verilir.

Bu dalda düzeltilenler **[DÜZELTİLDİ]** ile işaretli; geri kalanı yalnız rapor.
Satır numaraları main @ 3a0e645'e (düzeltme öncesi) göredir.

---

## Kritik

Kritik bulgu yok.

- **Gizli değer taraması (geçmiş dahil): temiz.** `git log -p --all` üzerinde Google API
  anahtarı (`AIza…`), özel anahtar/sertifika blokları, GitHub/AWS/Slack token'ları, JWT,
  base64 `.p12` blokları ve `api_key/secret/password/token = "…"` atamaları arandı;
  `.p8/.p12/.pem/.mobileprovision/.cer/.jks/.env/GoogleService*` dosya adları arandı.
  Eşleşmeler yalnızca desen içeren testler (`assertNotRegex(… "AIza…")`) ve
  `${{ secrets.… }}` başvurularıydı; gerçek değer bulunmadı.

## Yüksek

### Y1. Sıfır çözücüde uçuş süresi sınırı yok → uygulama donması [DÜZELTİLDİ]
- `lib/core/aerodynamic_trajectory_solver.dart:228-259` (`_heightAtRange`): ana döngüde
  60 s uçuş sınırı var (`:141`), sıfır arayan döngüde yoktu; hız sıfıra asimptotik
  yaklaşınca döngü `_maxSteps = 4 000 000` adımın tamamını koşuyordu.
  `BallisticEngine.solveReachable` (`lib/core/ballistic_engine.dart:41-56`) her istenen
  mesafe için yeniden denediğinden (11 mesafe ≈ 44 M RK4 adımı) Atış sayfası UI
  isolate'inde onlarca saniye donuyordu. Hız/BC doğrulamada (`velocity_truing.dart:123,233`)
  her bisection adımı aynı yolu tekrarlıyor.
- Tetikleyici (editörün kabul ettiği değerler): PCP, 800 fps, G1 BC 0,02, sıfır 600 m.
- Düzeltme: aynı 60 s sınırı `_heightAtRange`'e eklendi. Test:
  `test/input_robustness_audit_test.dart` (ilk test).
- Etki: 60 s'den uzun uçuşla ulaşılan bir sıfır artık reddedilir; sıfır ≤ 3000 m için
  bu ortalama < 50 m/s demektir, gerçek bir ayarda olmaz.
- Kalan öneri: `solveReachable` sıfır bulunamadığında her mesafe için yeniden denemesin
  (ayrı bir `ZeroUnreachable` hatası). Davranış değişikliği olduğu için yapılmadı.

### Y2. İki hızdan BC hesabı sonsuz döngü [DÜZELTİLDİ]
- `lib/tools/domain/field_calc.dart:237` (`velocityAfter`, `while (x < distanceM)`), her
  tuş vuruşunda `build()` içinden (`lib/features/tools/calculators_screen.dart:812-825`)
  ~62 kez çağrılıyor. Mesafe "1e999" (Infinity) → sonsuz döngü; "1e9" → dakikalarca donma.
- Düzeltme: mesafe sonlu ve `ProductionLimits.maxRangeM` (3000 m) içinde değilse `null`
  (ekran zaten "BC bulunamadı" yolunu gösteriyor). Test: ikinci test.
- Kalan öneri (UI metni, yapılmadı): 3000 m üstünde "BC bulunamadı" yerine
  "Mesafe en fazla 3000 m olabilir." gösterilmeli.

### Y3. Tık doğrulama sayfası çöküyor [DÜZELTİLDİ]
- `lib/features/tools/calculators_screen.dart:672-674`: `Infinity == Infinity.roundToDouble()`
  doğru olduğundan `clicksD.toInt()` `build()` içinde `UnsupportedError` atıyordu
  (kırmızı hata ekranı). Tetikleyici: tık sayısına "1e999"/"Infinity" yapıştırmak.
- Düzeltme: sayfa genelindeki `_p()` artık sonlu olmayan değerleri geçersiz sayıyor;
  tık sayısı ayrıca |n| ≤ 1 000 000. Test: üçüncü test.

## Orta

### O1. TestFlight iş akışı, secret olarak saklanan iki kimliği maskeyi atlatarak loga basıyor
- `.github/workflows/ios-testflight.yml:140`: App Store Connect anahtar kimliği ve issuer
  kimliği harfleri boşlukla ayrılarak yazdırılıyor (GitHub maskesi tam dizgiyi aradığı
  için maske devre dışı kalıyor). **Depo herkese açık**, Actions logları da herkese açık.
  Bu iki değer tek başına anahtar değildir (asıl gizli `.p8` loga basılmıyor), ama
  saldırı yüzeyini daraltmak için gizli tutulmaları amaçlanmış.
- Öneri: bu satırı kaldırın veya yalnız uzunluk/son 2 karakter yazdırın. Logları
  geçmiş run'lardan silmek için Actions → ilgili run → "Delete logs". Sahibin kararı:
  iş akışı değişikliği bu dalda yapılmadı.

### O2. Üçüncü taraf action sabit SHA ile değil, sürüm etiketiyle
- `subosito/flutter-action@v2` tüm iş akışlarında (ör. `ios-testflight.yml:75`,
  `appetize-upload.yml:67`, `ios-ci.yml:77`). TestFlight işinde aynı job'da `.p8`
  anahtarı diske yazılıyor ve Maps anahtarı ortamda; etiket taşınırsa kod bu işte koşar.
  `actions/*` (GitHub'ın kendi) için risk düşük.
- Öneri: `subosito/flutter-action@<tam-commit-sha> # v2.x` ile sabitleyin, Dependabot
  `github-actions` güncellemelerini açın.

### O3. TestFlight işinde sürümü sabitlenmemiş `pip install`
- `.github/workflows/ios-testflight.yml:132`: `pyjwt cryptography` sürümsüz kuruluyor ve
  `|| true` ile hata yutuluyor; `.p8` anahtarı aynı runner'da. Öneri: sürüm + hash
  sabitleyin (`--require-hashes`) veya bu kontrol adımını kaldırın.

### O4. Konum izni açıklaması kullanımın tamamını söylemiyor; enlem kalıcı saklanıyor
- `tools/configure_ios_info_plist.py:15-29`: metin "yalnızca … Hava Durumu ve Coriolis"
  ve "kalıcı olarak saklanmaz" diyor. Kodda konum ayrıca **Haritadan mesafe**
  (`lib/features/tools/map_distance_screen.dart:83`), yerçekimi hesabı
  (`ballistics_screen.dart:619`) ve Özel konum hesaplayıcısında kullanılıyor; GPS'ten
  doldurulan enlem (`ballistics_screen.dart:3532`, 2 ondalık ≈ 1 km) atış ayarlarıyla
  birlikte SharedPreferences'a yazılıyor (`lib/services/shot_settings_store.dart:99,194`).
  App Store 5.1.1 (amaç metninin doğruluğu) açısından reddedilme riski.
- Öneri (metin değişikliği, sahibin onayı gerekir): "…hava verisi, haritada konumunuzu
  göstermek ve Coriolis/yerçekimi için enlem…; girdiğiniz enlem ayarlarınızla cihazda
  saklanır." Aynı metinlerde "Sight Height" Türkçeleştirilebilir ("Dürbün yüksekliği").

### O5. Vuruş Olasılığı "NaN %" gösteriyor [DÜZELTİLDİ]
- `lib/features/tools/hit_probability_screen.dart:36`: `_parse` sonlu kontrolü
  yapmıyordu; grup = hedef = "1e999" → Inf²/Inf² = NaN. Düzeltme: sonlu olmayan değer
  geçersiz. Test: dördüncü test.

## Düşük

### D1. Google Maps iOS anahtarı uygulama paketinin içinde
- `tools/configure_ios_google_maps.py` anahtarı CI secret'tan `Info.plist`'e (`GMSApiKey`)
  yazar; IPA'yı açan herkes okuyabilir (iOS SDK'da kaçınılmaz). Repoda/geçmişte değer yok.
- Öneri: Google Cloud Console'da anahtarı **yalnız iOS uygulamaları + bu bundle ID** ve
  **yalnız Maps SDK for iOS** ile kısıtlayın; kota/uyarı limiti koyun.

### D2. `workflow_dispatch` girdileri doğrudan `run:` içine gömülüyor
- `test-diag.yml:34` (`inputs.files`), `format-fix.yml:57`, `lock-update.yml:43`
  (`git push origin HEAD:${{ inputs.branch }}`), `format-diag.yml:62`, `sim-diag.yml:94`.
  Yalnız yazma yetkisi olan tetikleyebildiği için risk düşük; yine de girdiyi `env:`
  üzerinden geçirip `"$BRANCH"` olarak kullanmak kabuk enjeksiyonunu kapatır.
- `pull_request_target` hiçbir iş akışında yok. `appetize-upload.yml`'deki `workflow_run`
  yalnız elle tetiklenen "iOS TestFlight"e bağlı (fork PR'ı tetikleyemez).

### D3. Appetize token'ı job düzeyinde ortamda
- `.github/workflows/appetize-upload.yml:59`: token `flutter pub get` ve derleme dahil tüm
  adımlarda ortamda. Öneri: yalnız yükleme adımının `env:`'ine taşıyın.

### D4. Bağımlılıklar
- Doğrudan bağımlılıkların kilitli sürümleri için GitHub Advisory Database (Pub) tarandı:
  bilinen açık yok (`http 1.6.0` > 0.13.3, `archive 4.3.0`, `shared_preferences_android
  2.4.28` düzeltilmiş sürümlerden yeni). OSV API bu ortamdan erişilemedi; geçişli
  paketlerin tam taraması için CI'da `osv-scanner --lockfile=pubspec.lock` önerilir.
- `flutter_compass 0.8.1`: son yayın 17 Kasım 2024 (~23 ay), resmen terk edilmemiş ama
  bakım belirsiz. Pusula için `sensors_plus` manyetometresi veya bakımı süren bir paket
  izlenmeli.

### D5. Esri World Imagery döşemeleri anahtarsız kullanılıyor
- `lib/features/tools/map_distance_screen.dart:19`: `server.arcgisonline.com` doğrudan.
  Atıf gösteriliyor (`:494`), ancak ticari dağıtımda Esri kullanım koşulları (ArcGIS
  hesabı/lisans) kontrol edilmeli. Görüntülenen bölgenin döşeme koordinatları Esri'ye
  gider; gizlilik politikasında belirtilmeli (Nominatim ve MET Norway ile birlikte).

### D6. Diğer sınırsız girdi yolları (yalnız rapor)
- Vakum modunda mermi ağırlığına üst sınır yok (`lib/core/ballistic_input.dart:269`):
  "1e308" → enerji "Infinity J". Öneri: ör. 2000 gr üst sınır.
- `DopeRanges.parse` (`lib/core/dope_ranges.dart:12-27`) mesafe sayısını sınırlamıyor;
  ondalık virgül "100,5" sessizce iki mesafeye (100 ve 5) bölünüyor.
- Saklanan katalog değerleri yalnız `> 0` ve sonlu kontrol ediliyor
  (`manual_catalog_store.dart:171-175`, `user_catalog_store.dart:148-151`): elle bozulmuş
  depoda klik 1e-310 → `correction/click` sonsuz → `.round()` `build` içinde hata
  (`ballistics_screen.dart:1485,1693`, `scope_dial_view.dart:1134`). Editör sınırları
  (klik 0,01–1, kalibre 2–20 mm, yiv 3–80) çözümlemede de uygulanmalı.
- `lib/features/tools/reticle_screen.dart:12` `_p` de sonlu kontrol yapmıyor (çökme yolu
  bulunmadı; tutarlılık için aynı düzeltme önerilir).

### D7. Yerel saklama
- SharedPreferences'ta parola/token yok; profiller, kataloglar ve atış ayarları düz JSON
  (hassas sayılmaz). Bozuk profil JSON'u yedekten kurtarılıyor ve karantinaya alınıyor
  (`lib/services/profile_store.dart:66-103`), testli (`test/profile_recovery_test.dart`).
  Bozuk atış ayarları sessizce varsayılana dönüyor (`shot_settings_store.dart:187`).

### D8. Yutulan hatalar ve await edilmeyen işler
- Kullanıcıya hiç bildirilmeyen: atış ayarı kaydetme hatası
  (`ballistics_screen.dart:344`, `.catchError((_){})`), kalibrasyon yükleme hatası
  (`lib/tools/state/level_controller.dart:230`), kamera açma/izin reddi
  (`ballistics/incline_measure_screen.dart:76`), katalog birincil JSON bozulması
  (`user_catalog_store.dart:23,49`, `manual_catalog_store.dart:37,63`; yedeğe düşülüyor,
  iz yok).
- `unawaited_futures` lint kapalı; `main.dart:39`, `profiles_screen.dart:79,85`,
  `home_screen.dart:121-122`, `ballistics_screen.dart:740`, `level_controller.dart:214`
  çağrıları `unawaited()` ile işaretlenmemiş (hepsi kendi hatasını yakalıyor; risk yok).
- Dispose edilmeyen controller/FocusNode/Timer/abonelik bulunmadı (~110 oluşturma
  kontrol edildi).

## Ölü kod ve kullanılmayan varlıklar (SİLİNMEDİ, yalnız liste)

- Erişilemeyen dosya: `lib/features/profiles/bullet_library_screen.dart` (yalnız
  `test/bullet_library_test.dart` kullanıyor).
- Hiç kullanılmayan: `profile_field_info.dart:27 caliberOther`;
  `standard_drag_tables.dart:16,17,34,47,49` (kaynak URL/ad sabitleri, yalnız referans
  kopyası); `unit_system.dart:12 metersPerSecondPerKnot`;
  `level_controller.dart:335 setAutoMode`, `:418 cancelCalibrationCapture`,
  `:475 clearAllCalibration`; `tilt_math.dart:203 isAdaptive`.
- Yalnız testlerden çağrılan: `settings_store.dart:33 saveMetric` (ve `loadMetric()` hep
  `true` döndüğünden `ballistics_screen.dart:1003-1004` emperyal dönüşüm ve
  `home_screen.dart _loadUnitPreference` fiilen ölü), `catalog_repository.dart:768,770`,
  `cartridges.dart:169 diameterOf`, `compass_math.dart:13 shortestDelta`,
  `environment_field_info.dart:18 coriolisFor`, `level_controller.dart:117,132,341,391`,
  `serial_mutation_lock.dart:21 isHeld`.
- Varlıklar: `assets/fonts/DejaVuSans-Bold.ttf` (pubspec'te, kodda kullanılmıyor),
  `assets/fonts/Oswald-Light.ttf` (w300 hiç kullanılmıyor). Font lisansları
  (`OSWALD-LICENSE.txt`, `DEJAVU-LICENSE.txt`) `LicenseRegistry`'ye eklenmemiş; OFL
  atfı için önerilir.

## Bu dalda yapılan değişiklikler

| Dosya | Değişiklik |
|---|---|
| `lib/core/aerodynamic_trajectory_solver.dart` | Sıfır aramasına 60 s uçuş sınırı (Y1) |
| `lib/tools/domain/field_calc.dart` | Mesafe sonlu ve ≤ 3000 m değilse `null` (Y2) |
| `lib/features/tools/calculators_screen.dart` | `_p` sonlu değilse `null`; tık sayısı sınırı (Y3) |
| `lib/features/tools/hit_probability_screen.dart` | `_parse` sonlu değilse `null` (O5) |
| `test/input_robustness_audit_test.dart` | Dört regresyon testi (önce kırmızı, sonra yeşil) |

UI metni, iş akışları ve izin metinleri değiştirilmedi.

## Sahibin yapması gerekenler
1. Google Maps iOS anahtarını bundle ID + Maps SDK for iOS ile kısıtlayın (D1).
2. `ios-testflight.yml:140` satırını kaldırın; eski TestFlight run loglarını silin (O1).
3. `subosito/flutter-action`'ı commit SHA ile sabitleyin; TestFlight'taki `pip install`'ı
   sabitleyin (O2, O3).
4. Konum izin metnini gerçek kullanıma göre güncelleyin (O4).
5. Anahtar yenileme: taramada sızmış değer bulunmadığı için zorunlu değil. O1'deki
   kimlikler herkese açık loglarda göründüğünden, temkin için App Store Connect API
   anahtarını iptal edip yenisini oluşturmak düşünülebilir.
