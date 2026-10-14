# Pro: "Kalan tüp basıncı" gizlendi

İstek (sahip, 2026-10-14 08:11, TestFlight ekran görüntüsü, Pro Ayarlar, PCP profili, "Tüfek düzeltmeleri" kartının altı): "Kalan tüp basıncını kaldıralım." Kural: gizle, silme.

## Ne değişti

`lib/features/ballistics/ballistics_screen.dart`:

- Yeni bayrak: `static const bool _showProTubePressure = bool.fromEnvironment('PRO_TUBE_PRESSURE');` Varsayılan kapalı. `--dart-define=PRO_TUBE_PRESSURE=true` ile derlenirse eski davranış aynen geri gelir.
- Bayrak kapalıyken Pro > Tüfek düzeltmeleri (PCP) içinde şunlar görünmez:
  - "Kalan tüp basıncı" kutusu (bar, ⓘ),
  - "Kalan basınç, profildeki tüp basıncından yüksek…" uyarısı,
  - "Tüp basıncı regülatör basıncının altında…" uyarısı,
  - "Kullanılan hız: … fps (profil … fps)" satırı.
- Tüfek düzeltmeleri ⓘ alttan sayfasından "Kalan tüp basıncı" alan satırı ve "Tüp basıncı" açıklaması (kutuya yazmayı anlatıyordu) çıkarıldı.
- Hedef sayfasındaki "Regülatör devre dışı: tüp basıncı regülatör basıncının altında, hız düşer." uyarısı görünmez.
- Tüfek düzeltmeleri başlığındaki özet ("1 ayar açık" vb.) kayıtlı tüp basıncını artık saymaz.

## Hız şimdi nasıl seçiliyor

Bayrak kapalıyken `_pcpVelocity` hiç hesap yapmaz (null döner). Böylece hesapta kullanılan hız, kutu boşken olduğu gibi profil hızıdır (ateşli tüfekte barut sıcaklığı düzeltmesi aynen uygulanır; PCP'de bu düzeltme zaten yok). Sıfırlama hızı da profil hızı olarak kalır.

## Neden

Sahip kutunun kaldırılmasını istedi. Kutu gizlenip eski kayıtlı değer hesapta kalsaydı kullanıcı göremediği ve değiştiremediği bir değer yüzünden farklı nişan alırdı. Bu yüzden gizliyken kayıtlı değer tamamen yok sayılır.

## Uç durumlar

- **Eskiden kaydedilmiş değer:** Ayar kaydında (`ShotSettings.tubePressureText`, anahtar `tubePressure`) olduğu gibi kalır, silinmez; sayfa yine okur ve geri yazar. Yalnız gizliyken hesaba, uyarılara ve özete girmez. Bayrak açılırsa aynı değer yeniden kullanılır.
- **Regülatörlü PCP:** Kayıtlı 120 bar, 150 bar regülatörün altında olsa bile hız profil hızıdır, Hedef'te uyarı çıkmaz.
- **Regülatörsüz PCP:** Kayıtlı tüp basıncı, basınca göre hız tablosundan hız seçtirmez; profil hızı kullanılır.
- **Ateşli tüfek:** Değişiklik yok; kutu zaten yoktu, kayıtlı değer zaten yok sayılıyordu.
- **Tüfek düzeltmeleri kartı PCP'de boş kalmıyor:** Gerçek / yazan, Sıfır ofseti (Yukarı/Sağ) ve Mermi uzunluğu duruyor. Spin drift hep açık olduğu için özet boş kutuda olduğu gibi "1 ayar açık" gösterir.

## Bilerek yapılmayanlar

- Profil formundaki PCP alanları (Tüp basıncı, Regülatör basıncı, Basınca göre hız tablosu) değişmedi. Profil sayfasına dokunulmadı (açık olan fix/profil-ekle-arti ile çakışma yok).
- `PcpPressure` hesap kodu, `EnvironmentFieldInfo.tubePressure` ve `ProSectionInfo.pcpPressure` metinleri silinmedi; bayrak açılınca kullanılır.
- `test/support/pro_sections.dart` içindeki eski anahtar eşlemeleri zararsız olduğu için bırakıldı.

## Hangi test kapsıyor

- `test/pcp_pressure_ui_test.dart` ("Pro and Hedef" grubu yeniden yazıldı):
  - PCP Pro'da "Kalan tüp basıncı" kutusu, uyarıları ve "Kullanılan hız" yok; kartın diğer kutuları var; kayıtlı 120 bar varken özet "1 ayar açık".
  - Tüfek düzeltmeleri ⓘ sayfasında alanlar yalnız Gerçek / yazan, Yukarı + / aşağı −, Sağ + / sol −, Mermi uzunluğu; "Tüp basıncı" açıklaması yok.
  - Regülatörlü: kayıtlı 120 bar (150 bar regülatör) Hedef'teki yükselmeyi değiştirmiyor, "Regülatör devre dışı" uyarısı yok, kayıtlı değer depoda duruyor.
  - Regülatörsüz: kayıtlı tüp basıncı tablo hızını seçtirmiyor.
  - Ateşli tüfek: kayıtlı değer çözümü değiştirmiyor, Pro'da kutu yok.
- `test/pro_info_popup_test.dart`: PCP beklenen ⓘ listelerinden tüp basıncı çıkarıldı; "en uzun sayfanın son alanı" testi artık Mermi uzunluğu ⓘ'sine dokunuyor ve listede "Kalan tüp basıncı" olmadığını denetliyor.
- `integration_test/sim_screens_test.dart`: kutuya 120 yazan `pro_tup_basinci` adımı kaldırıldı.

## Doğrulama

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test OK.
- Bu ortamda Flutter SDK yok; `flutter test` / `flutter analyze` GitHub Actions'ta çalıştırıldı:
  - Format (`format-fix.yml`): yeşil; iki kez çalıştı, ikisinde de CI biçimlendirme commit'i ekledi (9c11a4b, 50c343c), dala çekildi — https://github.com/sniperTurk/flutter-app/actions/runs/38515583540 , https://github.com/sniperTurk/flutter-app/actions/runs/38516245140
  - Testler (`test-diag.yml`, `files=test`): ilk çalıştırma kırmızıydı (yeni ⓘ testi alan adını `find.text` ile arıyordu, alan adı zengin metin içinde; test `ProInfoFieldEntry` ile düzeltildi) — https://github.com/sniperTurk/flutter-app/actions/runs/38515674607 ; düzeltmeden sonra 50c343c üzerinde yeşil — https://github.com/sniperTurk/flutter-app/actions/runs/38516310489
  - Analiz (`analyze-diag.yml`): 50c343c üzerinde yeşil — https://github.com/sniperTurk/flutter-app/actions/runs/38516313835
- iOS CI, Simulator, TestFlight çalıştırılmadı. Birleştirme yapılmadı (taslak PR).

---
_Generated by [Claude Code](https://claude.ai/code)_
