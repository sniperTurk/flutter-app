# Kod temizliği (14.10.2026)

İstek (sahip, 14.10.2026 09:12): "Çok değişiklik yaptık dünden beri… kodlar temizlensin."

Bu PR davranışı, ekranı, yazıları, düzeni ve hesap sonuçlarını değiştirmez. Yalnız hiç kullanılmayan kodu siler, aynı işi yapan kopya yardımcıları tek yardımcıda toplar ve yanlış ya da eskimiş yorumları düzeltir.

## Kısa sonuç

- 7 küçük commit, her biri tek konu.
- `lib/` toplamı: **54 466 satır → 54 393 satır** (−73). 8 dosya değişti: 126 satır eklendi, 199 satır silindi. Eklenen satırların çoğu düzeltilmiş ya da yeri değiştirilmiş yorumlar.
- Bayrakla gizlenen kodun hiçbiri silinmedi. Kayıtlı veri alanlarının hiçbiri silinmedi. Eski profiller ve ayarlar aynı şekilde yüklenir.
- `lib/core` ve `lib/data/*_library.dart` dosyalarına dokunulmadı.
- Hiçbir test silinmedi ya da değiştirilmedi.

## Dosya dosya ne değişti

Her "kullanılmıyor" kararı için `lib/`, `test/`, `integration_test/` ve `tools/` (Python testleri dahil) içinde arama yapıldı. Aramaların sonucu aşağıda.

### 1. `lib/ui/menzil_widgets.dart`: `MenzilInfoButton`

- **Silindi:** `body` alanı. #274'te Pro kutu açıklamalarını ortada açılan pencerede göstermek için eklenmişti. #279'dan beri Pro kutu ⓘ'si alttan açılan sayfayı `onPressed` ile açıyor.
  - Kanıt: `MenzilInfoButton(` çağrılarının hepsi tarandı. `body:` veren çağrı yok. Çağrılarda kullanılan isimli değerler yalnız `key, title, text, info, tooltip, illustration, onPressed`.
- **Silindi:** `closeLabel` alanı. Tek kullanımı `ballistics_screen.dart` içindeki Pro kutu ⓘ'sindeki `closeLabel: 'Kapat'` idi. O düğmede `onPressed` de verildiği için pencere hiç açılmıyordu, yani bu değer hiç kullanılmıyordu. Alan ve o satır silindi. Normal ⓘ penceresinin düğmesi önceden de "Tamam" idi, yine "Tamam".
  - Kanıt: `grep -rn closeLabel lib test integration_test tools` artık boş. Önce yalnız tanım ve o tek satır vardı.
  - Testlerdeki "Kapat", alttan açılan sayfanın kendi düğmesi (`pro_info_sheet.dart:188`). O düğmeye dokunulmadı.

### 2. `lib/ui/menzil_widgets.dart`: `MenzilTopBar`

- **Silindi:** `unitLabel`, `onUnitTap` (birim düğmesi) ve `showBrand`. Uygulama V380'den beri yalnız metrik. Üst çubuğun tek çağrısı `home_screen.dart:311` bu üçünü hiç vermiyor.
  - Önce `unitLabel` hep `null` olduğu için birim düğmesi hiç çizilmiyordu. `showBrand` hep `true` olduğu için "Sniper Türk" yazısı her zaman gösteriliyordu. Kod bu iki durumu sabit hâle getirdi. Görünüm aynı.
  - Kanıt: `grep -rn "unitLabel:\|onUnitTap\|showBrand" lib test integration_test tools`. Üst çubukla ilgili hiçbir sonuç yok. Kalan `unitLabel:` sonuçları başka sınıflara ait: dürbün görünümü, retikül ve atış defteri.
  - `titleSlotWidth(includeBrand: …)` bırakıldı. Testler `false` değerini kullanıyor (`test/top_bar_fixed_slot_test.dart:168`).

### 3. `lib/ui/menzil_widgets.dart`: `MenzilInput.labelTrailing`

- **Silindi:** `MenzilInput.labelTrailing`. Hiçbir çağrıda verilmiyordu. Ona bağlı `_CompactLabel.trailing` ve `MenzilFieldLabel.trailing` da başka hiçbir yerden verilmiyordu, onlar da silindi.
  - Kanıt: `grep -rn labelTrailing lib test integration_test tools` artık boş. Önce yalnız `menzil_widgets.dart` içindeydi. `MenzilFieldLabel(` çağrılarında `trailing:` yok.
  - Etiket satırındaki `Row` yerinde bırakıldı. Yerleşim birebir aynı.

### 4. `lib/features/ballistics/ballistics_screen.dart`: `_windMaxAuto`

- **Silindi:** "Rüzgâr hızı × 1,5" kutusunun eski otomatik doldurma artıkları:
  - `_windMaxAuto` alanı. 12.10'dan beri hep `false`.
  - `_autoWindMax()` fonksiyonu. İlk satırı `if (!_windMaxAuto) return;` olduğu için hiçbir şey yapmıyordu.
  - Rüzgâr kutusundaki dinleyici, iki çağrı ve iki `?:` dalı.
  - Kanıt: `grep -rn "windMaxAuto\|autoWindMax" lib test integration_test tools` artık boş. Önce alana `true` yazan tek bir satır bile yoktu.
- Kayıt aynı: `windMaxText` ve `windMaxOff` önceden de `false` dalının değerlerini yazıyordu. Bu iki alan ve onları okuyan kod duruyor.
- `lib/services/shot_settings_store.dart`: `windMaxOff` yorumu düzeltildi. Artık var olmayan "Otomatik doldur" düğmesinden söz ediyordu. Alan, JSON'a yazılması ve okunması duruyor.

### 5. Aynı işi yapan kopya yardımcılar

Gövdeleri karakter karakter aynı olanlar tek yardımcıda toplandı. Çıktı aynı.

- `lib/features/profiles/profiles_screen.dart`: `_applyBullet` ve `_applyFactory` içindeki yerel `n()` kapanışları, dosyadaki `_trimNum` ile aynı gövdeye sahip: `v % 1 == 0 ? toStringAsFixed(0) : toString().replaceAll('.', ',')`. Verilen değerlerin hepsi `double`: `grain`, `bc`, `bands.$2` ve `muzzleVelocityFps`. Kapanışlar yerine `_trimNum` kullanılıyor.
- `lib/features/ballistics/scope_dial_view.dart`: `ScopeDialView._mag` ve `_DrumPainter._num`, `ScopeDialView._trim` ile aynı. Üçü tek `_trim` oldu.
- `lib/features/ballistics/ballistics_screen.dart`: `_celsiusText` ile `_putWeatherSi` ve `EnvironmentCarry` içindeki iki yerel `f()` aynı. Üçü dosya sonundaki tek `_twoDecimals` oldu.

### 6. Eskimiş ya da yanlış yorumlar (yalnız yorum, kod aynı)

- `ballistics_screen.dart`:
  - Pro ⓘ açıklaması üç yerde "popup" yerine "alttan açılan sayfa" (bottom sheet) diye düzeltildi.
  - `tubePressureCtl`, `solve` içindeki hız yorumu ve `_pcpRegulatorBypassed`: tüp basıncı profilden gelir. Pro kutusu yalnız `PRO_TUBE_PRESSURE` bayrağıyla açılır.
  - `_stability` üstündeki doc yorumunun ilk yarısı başka bir fonksiyonu anlatıyordu. O kısım `_spinDriftMrad` üstüne taşındı.
  - Coriolis ve Yerçekimi: "kapalı / açık" yerine "her zaman açık, anahtar yok" yazıldı.
  - Mesafe düğmeleri: "±1/±10" yerine "±1/±5" yazıldı.
  - Hava Durumu: "Yeniden doldur" yerine "Konumdan canlı hava verisi al" yazıldı. "Sıfırla kutuları boşaltır" yorumu eklendi. Hava düğmesi basıncı hiç yazmaz.
  - DOPE PDF: Oswald yalnız PDF'te kullanılıyor.
  - Basınç Ölçer: artık var olmayan "Atmosfer" başlığına yapılan atıf düzeltildi.
  - Rüzgâr gözlemi (bayraklı kod) içindeki anlamsız "class top" yorumu silindi. Kod duruyor.
- `pro_info_sheet.dart`: "Popups are left-aligned" yerine "her ⓘ yazısı gibi sola yaslı" yazıldı.
- `scope_dial_view.dart`: üç doc yorumu yanlış sınıfın üstündeydi. Ait oldukları yere taşındı: `ScopeDialView`, `_TurretDrum`, `ScopeReticlePainter`.
- `profiles_screen.dart`:
  - Kayan doc yorumları ait oldukları yere taşındı: `_ProfileDialog`, `_bcError`, `_clearAmmo`, `_libraryHere`, `_applyFactory`.
  - Silinmiş Ağırlık örneğinden ("kutuya dokununca kaybolur") söz eden yorum kaldırıldı.
  - Mühimmat Uzunluk kutusunun `PROFILE_AMMO_LENGTH` bayrağıyla gizli olduğu ve hesapta kullanılmadığı yazıldı.
  - Mühimmat sırası güncellendi: PCP Marka `PCP_AMMO_BRAND` bayrağıyla açılır. Namlu çıkış hızı Tüfek kartında.
  - Dürbün model satırında marka yok.
  - Elle girilen dürbün "Aradığın dürbün listede yok mu?" bağlantısıyla açılıyor.
  - Profil birimleri: hız fps, mesafe profilin kendi biriminde.
- `home_screen.dart`:
  - Sekme adı "Atış" yerine "Hedef" yazıldı.
  - "Menzil wordmark" yerine "Sniper Türk" yazıldı.
  - Birim tercihinin üst çubukta bir düğmesi yok. Yalnız hesap alanının anahtarında kullanılıyor.
- `menzil_widgets.dart`:
  - `MenzilFieldLabel` doc yorumu doğru sınıfa taşındı.
  - Kompakt kutuda ⓘ yorumu düzeltildi: popup ya da Pro'da alttan açılan sayfa.
- `menzil_theme.dart`:
  - `dart:ui` açıklaması doğru satırın üstüne taşındı.
  - "4-pt spacing scale" yorumu "Spacing scale" oldu. Değerlerin hepsi 4'ün katı değil.

## Bilerek bırakılanlar

- **Bayraklı kodun tamamı** (sahip kuralı "gizle, silme"): `WIND_OBSERVATION`, `PRO_TUBE_PRESSURE`, `PROFILE_AMMO_LENGTH`, `PCP_AMMO_BRAND`, `SCOPE_LISTEDE_YOK`, `SHOT_SAMPLE_PREVIEW`, `RESTORE_ON_WELCOME` (`empty_states.dart`), `SHOT_MODE_SWITCH` (`home_screen.dart`), `GOOGLE_MAPS_ENABLED` ve `METNO_CONTACT`. Bunların kullandığı alanlar, denetleyiciler ve fonksiyonlar da (ör. `tubePressureCtl`, `ammoLength`) duruyor.
- **Kayıtlı veri alanları:** `ShotSettings` içindeki `coriolisOn`, `gravityOn`, `spinDriftOn`, `windMaxOff`, `tubePressureText`, `bulletLengthText` ve profilin `lengthMm` alanı. Hem yazılması hem okunması duruyor.
- **`_coriolisOn`, `_gravityOn` ve `_spinDriftOn`** (`ballistics_screen.dart`): üçü de hep `true`, yani bağlı `if` dalları hep aynı sonucu veriyor. Bu dalları sökmek Pro kutularında büyük yeniden girinti ve `const` değişikliği demek. Değerler ayrıca kayda yazılıyor. Risk/yarar oranı düşük olduğu için silinmedi. Yorumları "her zaman açık" diye düzeltildi. İstenirse ayrı bir PR'da sökülebilir.
- **`MenzilType.family`** (`menzil_theme.dart`): `lib/` içinde kullanılmıyor. Ancak açıklaması "açık PR'lar için tutuldu" diyor. Açık PR #128 (sistem yazısı) ve #228 (Garmin) bunu kullanabilir. Bu yüzden silinmedi.
- **`StandardDragTables.moreSourceName` ve `ra4SourceUrl`** (`lib/core/standard_drag_tables.dart`): `lib/` içinde kullanılmıyorlar. Ancak public sabitler ve görev kuralı gereği `lib/core` içinde yalnız private ölü kod silinebilir. Bırakıldı.
- **Yalnız testlerin kullandığı public API'ler:** `MemoryProfileStore`, `MemoryActiveProfileStore`, `InMemoryLevelCalibrationStore`, `LevelController.setMode/calibrationFor` ve benzerleri. Testlerin parçası oldukları için ölü sayılmadı.
- **Inter yazı tipi dosyaları** ve `pubspec.yaml`'daki tanımları duruyor. Testler (`sistem_yazisi_test.dart`) bunları ölçüm için yüklüyor.
- **Dokunulmayan alanlar:** açık PR #285'in bölgeleri (`MenzilPrimaryButton` ve "Profil ekle" satırı) ve #287'nin dosyaları (CLAUDE.md ve docs). Benim değişikliklerim bu bölgelerle çakışmıyor. `menzil_widgets.dart` içindeki en yakın değişiklik `MenzilPrimaryButton`'dan yaklaşık 250 satır yukarıda.
- **Ekranda görünen yazılar:** `calculators_screen.dart:948` hâlâ "Diabolo saçmada GA…" diyor. Bu GA modeli kaldırılmadan (#195) önceden kalma bir **kullanıcı metni**. Görevde yazı değişikliği yasak olduğu için dokunulmadı. Sahibin ayrıca karar vermesi gerekir.
- **`MenzilSecondaryButton.twoLines` yorumu:** yorum biraz eskimiş görünüyor. Ancak #285'in düğme bölgesine çok yakın olduğu ve anlamı tartışmalı olduğu için dokunulmadı.

## Riskler

- Kod silmelerinin hepsi ya hiç çağrılmayan parametreler ya da hep aynı değeri alan dallar. Derleyici ve analiz bunları yakalar. CI'da analiz temiz geçti (aşağıda).
- Yardımcı birleştirmede tek fark parametre tipi: `n(num)` yerine `_trimNum(double)`. Çağrıların hepsi `double` verdiği için sonuç aynı. Analiz de bunu doğruladı.
- Yorum taşımaları kodu değiştirmez.
- `lib/core` değişmedi. Formül denetimi (`audit/formul-2026-10-14`) ile çakışma yok.

## Hangi testler kapsıyor

- ⓘ penceresi ve Pro sayfası: `test/pro_info_popup_test.dart`, `test/pro_tab_test.dart`, `test/pro_new_effects_test.dart`, `test/wind_guide_test.dart`, `test/yasla_sadece_hedef_test.dart`.
- Üst çubuk: `test/top_bar_fixed_slot_test.dart`.
- Kutular ve etiketler: `test/kutu_fikir4_test.dart`, `test/velocity_caliber_row_test.dart`, `test/profile_lists_test.dart`.
- Rüzgâr düzeltmesi kaydı: `test/pcp_pressure_ui_test.dart`, `test/fetch_reset_buttons_test.dart` ve Pro testleri.
- Mühimmat doldurma (`_trimNum`): `test/profile_editor_fail_closed_test.dart`, `test/profile_lists_test.dart`.
- Dürbün sayıları (`_trim`): `test/reticle_test.dart`, `test/menzil_shell_test.dart`.
- Hava kutularının geri yüklenmesi (`_twoDecimals`): `test/shot_settings_test.dart`, `test/weather_filled_state_test.dart`, `test/phone_pressure_test.dart`.

## Doğrulama

Yerel:

- `python3 tools/offline_dart_lint.py`: GEÇTİ (325 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: GEÇTİ (732 test).
- Bu ortamda Flutter SDK yok. `gh` CLI oturumu da yoktu. Bu yüzden iş akışları GitHub bağlantısıyla aynı girdilerle başlatıldı.

CI (dal `chore/kod-temizligi`, son kod commit'i 1647c36):

- Biçimlendirme (format-fix, 375209577): https://github.com/sniperTurk/flutter-app/actions/runs/38522260826. Başarılı. "Formatted 327 files (0 changed)", yani biçim commit'i gerekmedi.
- Analiz (analyze-diag): https://github.com/sniperTurk/flutter-app/actions/runs/38523326529. Başarılı (`flutter analyze --fatal-infos --fatal-warnings`).
- Tüm testler (test-diag, files=test): https://github.com/sniperTurk/flutter-app/actions/runs/38523319117. Başarılı.
- Not: aynı dakikalarda başka oturumlar da aynı iş akışlarını çalıştırdı (ör. 38522709933 ve 38522663357; o dallarda olup bu dalda olmayan dosyalarda hata veriyorlar). Bu dalın koşuları, tetikleme saatine göre ayırt edildi: 06:37:42 test, 06:37:46 analiz (UTC). Bu rapor commit'i yalnız belge ekliyor; kod 1647c36 ile aynı.

iOS CI, Simulator ve TestFlight bu iş için çalıştırılmadı. TestFlight'a gönderilmedi. Birleştirme yapılmadı. PR taslak.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
