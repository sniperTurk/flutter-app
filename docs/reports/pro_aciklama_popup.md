# Pro Ayarlar: açıklamalar ⓘ popup'ta

Sahip kararı (2026-10-13 19:51): "Uygulamada çok yazı var, özellikle Pro
sayfası çok karmaşık. Pro sayfasındaki açıklamalar popup olsun. Hedef
sayfasındaki açıklamalar güzel duruyor."

## Ne değişti

Pro Ayarlar'da bir kutu açıldığında artık "Ne? / Neden önemli? / Nasıl?"
yazıları sayfada görünmüyor. Her kutunun başlığının hemen yanında bir ⓘ var.
ⓘ'ye dokununca aynı yazılar bir pencerede (popup) açılıyor. Yazıların hiçbiri
değişmedi.

### Değişen kutular ve popup içerikleri

| Kutu (başlık) | ⓘ anahtarı | Popup'taki açıklamalar (sayfadaki sırayla) |
|---|---|---|
| Açı | `pro-info-angle` | Tüfek eğimi, Dürbün eğimi |
| Rüzgâr düzeltmesi | `pro-info-wind` | Rüzgâr aralığı (windMax), Rüzgâr bölgeleri (windZones) |
| Coriolis | `pro-info-coriolis` | Coriolis |
| Yerçekimi | `pro-info-gravity` | Yerel yerçekimi |
| Hareketli hedef | `pro-info-target` | Hareketli hedef, İsabet olasılığı (WEZ) |
| Tüfek düzeltmeleri | `pro-info-rifle` | Kule ölçek katsayısı, Sıfır ofseti, Spin drift (+ PCP'de spin notu), Barut sıcaklığı (yalnız ateşli tüfek), Tüp basıncı (yalnız PCP) |

Böylece daha önce sayfada duran 13 açıklama bloğunun (incline, cant, windMax,
windZones, coriolis, gravity, movingTarget, hitProbability, turretScale,
zeroOffset, spinDrift + PCP notu, powder, pcpPressure) hepsi ilgili kutunun
ⓘ'sine taşındı.

### Dosya / metot

- `lib/features/ballistics/ballistics_screen.dart`
  - `_proBox(...)`: yeni `info` parametresi (kutunun açıklama listesi). Başlık
    satırında başlığın hemen sağına `MenzilInfoButton` (anahtar
    `pro-info-<kutu>`, ipucu "Açıklama: <başlık>", kapatma düğmesi "Kapat").
  - `_proInfoBody(...)` (yeni): popup gövdesi; kutunun açıklamalarını sırayla
    `_explain` ile çizer.
  - `_explain(...)`: silinmedi (gizle-silme kuralı). Artık popup gövdesini
    çiziyor; renkleri popup'ın kendi temasından alması için isteğe bağlı
    `within` bağlamı eklendi. Kalın sorular, iki yana yaslı paragraf, not
    satırı aynı.
  - `_windCorrectionBox`, `_proSection`, `_pcpPressureProFields`: sayfadaki
    `_explain(...)` çağrıları kaldırıldı; bunların yerine kutuya `info:` listesi
    verildi. Rüzgâr kutusunda iki alan arası boşluk kaybolmasın diye bir
    `SizedBox` kondu.
  - Dosya sonuna küçük `_ProInfo` sınıfı (açıklama + isteğe bağlı not).
- `lib/ui/menzil_widgets.dart` — `MenzilInfoButton`: isteğe bağlı `body`
  (zengin içerik), `tooltip` ve `closeLabel` parametreleri eklendi.
  Varsayılanlar aynı ("Bilgi: …", "Tamam", düz metin); alan ⓘ'leri hiç
  değişmedi.

## ⓘ ve popup nasıl çalışıyor

- ⓘ, kutu başlığıyla aynı satırda, başlığın hemen sağında. Kutu kapalıyken de
  görünür; açıklamayı okumak için kutuyu açmak gerekmez.
- ⓘ kendi dokunma alanına sahip (44×44 pt). Ona dokunmak kutuyu açıp
  kapatmaz; yalnızca popup'ı açar. Başlığın geri kalanına dokunmak kutuyu her
  zamanki gibi açar/kapatır.
- Popup, alan ⓘ'leriyle aynı `showDialog` / `AlertDialog` görünümünü kullanır:
  başlıkta kutunun adı, altında her açıklama için (kutu adıyla aynı değilse)
  açıklamanın başlığı, sonra "Ne?", "Neden önemli?", "Nasıl?" (sorular kalın,
  sahip kuralı 2026-10-12), paragraflar iki yana yaslı, varsa not satırı
  (PCP spin notu, turuncu). Altta "Kapat" düğmesi.
- Kutu başlığıyla aynı açıklama başlığı tekrar yazılmaz (Coriolis, Hareketli
  hedef; sahip kuralı 2026-10-12).

## Neden

Sahip, Pro sayfasını çok kalabalık buldu ve açıklamaların popup olmasını
istedi. Sayfada yalnızca girilecek değerler, düğmeler, sonuçlar ve uyarılar
kalıyor; açıklama isteyen ⓘ'ye dokunuyor.

## Uç durumlar

- **Uzun yazılar:** Popup içeriği `SingleChildScrollView` içinde; en uzun olan
  Tüfek düzeltmeleri popup'ı kayar, "Kapat" her zaman görünür.
- **Notlar:** PCP'de spin drift notu popup'ta, spin açıklamasının altında
  (anahtar `pro-spin-pcp-note` korunuyor). Ateşli tüfekte yok.
- **Platforma göre içerik:** Barut sıcaklığı yalnız ateşli tüfekte, tüp
  basıncı yalnız PCP'de popup'a girer (sayfadaki alanlarla aynı kural).
- **Dar telefon / büyük yazı:** 320×568 ekran ve yazı ölçeği 1,3 ile test
  edildi: popup ekrana sığar, taşma yok, uzun içerik sonuna kadar kayar.
  Başlık uzunsa satır kırılır, ⓘ yanında kalır.
- **Koyu tema:** Popup yazı renkleri popup'ın kendi temasından alınır
  (`MenzilColors.of(dialog)`); koyu temada koyu renkler kullanılır (testli).
- **Ekran okuyucu (VoiceOver):** ⓘ ayrı bir düğme; etiketi "Açıklama: <kutu
  adı>" (alan ⓘ'lerinin "Bilgi: …" etiketleriyle karışmasın diye; örneğin
  Yerçekimi alanı ⓘ'si "Bilgi: Yerçekimi" olarak kalıyor). Testte düğme,
  dokunma eylemi ve etiket doğrulanıyor.
- **Başlığa dokunma:** Başlık satırının ortası artık ⓘ'ye denk gelebildiği
  için testlerdeki kutu açma yardımcısı (`openProFor` → yeni `tapProHeader`)
  ve `integration_test/sim_screens_test.dart` başlık yazısının üstüne dokunuyor.

## Bilerek değiştirilmeyenler

- **Hedef sayfası:** Açıklamalar olduğu gibi duruyor (`ScopeDialView`
  açıklamaları, sonuç satırları). Hedef'te Pro ⓘ'si yok (testli).
- **Boş durum ekranları** (`lib/features/home/empty_states.dart`): profilsiz
  Pro önizlemesindeki açıklamalar aynen kaldı.
- **Alan ⓘ metinleri** (`EnvironmentFieldInfo` vb.) ve görünümü: aynı ("Tamam").
- **Uyarılar / `MenzilNotice`:** sayfada kalmaya devam ediyor (ör. "Profilde
  yiv yönü veya yiv oranı yok…", tüp basıncı uyarısı).
- **Metinler:** `pro_section_info.dart` hiç değişmedi; kelime değişikliği yok.
- **Hava Durumu rüzgâr bölümü** (PR `fix/ruzgar-rehber`) ve üst çubuk:
  dokunulmadı.

## Testler

- `test/pro_info_popup_test.dart` (yeni):
  - Ateşli tüfek ve PCP: her kutu açıldığında sayfada "Ne?", "Neden önemli?",
    "Nasıl?" ve hiçbir açıklama metni yok.
  - Ateşli tüfek ve PCP: her kutunun başlık satırında ⓘ var; popup kutu adını,
    açıklamaların Ne?/Neden önemli?/Nasıl? metinlerini aynen ve sırayla
    gösteriyor; sorular kalın (w600), paragraflar iki yana yaslı; PCP spin notu
    yalnız PCP'de; popup kutuyu açmıyor; "Kapat" kapatıyor.
  - ⓘ ayrı VoiceOver düğmesi ("Açıklama: …", dokunma eylemi).
  - Dar telefon (320×568) + yazı ×1,3: popup sığıyor, taşma yok, en uzun popup
    sonuna kadar kayıyor.
  - Koyu tema: popup yazıları koyu tema renginde.
  - Hedef: açıklamalar (`scope-workings`) yerinde, Pro ⓘ'si yok.
- Güncellenen: `test/pro_tab_test.dart` (açıklama artık ⓘ'den; PCP spin notu
  popup'ta), `test/pro_new_effects_test.dart` (ateşli tüfekte not popup'ta da
  yok), `test/pcp_pressure_ui_test.dart` ve `test/support/pro_sections.dart`
  (başlığa dokunma), `integration_test/sim_screens_test.dart` (başlığa
  dokunma). `integration_test/wez_tour.dart` bu metinleri aramıyor; değişmedi.
- `test/ballistics_profile_gate_test.dart` boş Pro önizlemesindeki açıklamanın
  (değişmeyen) hâlâ açıldığını doğruluyor.

## Doğrulama

Yerel (bu oturum, Flutter SDK indirilemedi — storage.googleapis.com engelli,
bu yüzden Flutter komutları yalnız CI'da çalıştı):

- `python3 tools/offline_dart_lint.py` → PASS (310 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 724 test OK

CI (hepsi `fix/pro-aciklama-popup` dalında):

- Biçim (dart format), commit `257d6c6` dala itildi:
  https://github.com/sniperTurk/flutter-app/actions/runs/38435027310 — başarılı
- İlk analiz denemesi (başarısız: `getCenterLeft` yok, `containsSemantics`
  eskimiş; düzeltildi): https://github.com/sniperTurk/flutter-app/actions/runs/38435185409
- İlk test denemesi (aynı derleme hatası yüzünden başarısız):
  https://github.com/sniperTurk/flutter-app/actions/runs/38435181450
- `flutter analyze --fatal-infos --fatal-warnings`, commit `4eec856`:
  https://github.com/sniperTurk/flutter-app/actions/runs/38436504786 — başarılı
- `flutter test test` (tüm birim/widget testleri), commit `4eec856`:
  https://github.com/sniperTurk/flutter-app/actions/runs/38436509507 — başarılı

Çalıştırılmayanlar: iOS Simulator, cihaz, imzalama, TestFlight. `iOS CI /
verify` işi bu rapor yazılırken çalışmadı; geçti denemez.

Taslak (draft) PR; birleştirme sahibin ana oturumunda.

---
_Generated by [Claude Code](https://claude.ai/code)_
