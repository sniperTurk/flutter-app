# Mermi uzunluğu yalnız Pro'da (fix/uzunluk-sadece-pro)

Sahip kararı (2026-10-13 23:32): "Profilden çıkartın". Mermi uzunluğu iki
yerde soruluyordu: Profil > Mühimmat "Uzunluk" ve Pro Ayarlar > Tüfek
düzeltmeleri "Mermi uzunluğu". Aynı değerin iki yerde olması hataya açıktı.
Artık yalnız Pro kutusu var.

## Ne değişti

- `lib/features/profiles/profiles_screen.dart`
  - Profil > Mühimmat "Uzunluk" kutusu (Key `ammo-length`, yalnız PCP)
    **gizlendi, silinmedi**: `bool.fromEnvironment('PROFILE_AMMO_LENGTH')`
    bayrağına bağlandı, varsayılan kapalı. Kutu kapalıyken ⓘ'si de
    görünmez; metni `ProfileFieldInfo.ammoLength` yerinde duruyor.
  - Profil özeti (Mühimmat bilgileri kartı) "Uzunluk" satırını artık
    göstermez (aynı bayrağa bağlı).
  - Kayıt: kutu gizliyken form **yeni uzunluk yazmaz**; mühimmatta daha
    önce kayıtlı bir uzunluk varsa **aynen korunur** (silinmez).
  - Uzunluk doğrulaması (eksik/hatalı alan listesi) kutu gizliyken
    çalışmaz; görünmeyen bir kutu kaydı engelleyemez.
  - PCP Mühimmat düzeni: Tip kendi satırında, ardından **Ağırlık | BC** yan
    yana (iki kutu bir satır kuralı). Önceden Tip | Ağırlık, Uzunluk | BC
    idi; Uzunluk gidince BC tek kalıyordu.
- `lib/features/ballistics/ballistics_screen.dart`: `_bulletLengthMm`
  artık yalnız Pro "Mermi uzunluğu" kutusunu (`bulletLengthCtl`) okur.
  PR #264'te eklenen `ammunition?.lengthMm` yedeği kaldırıldı; açıklama
  notu güncellendi.
- ⓘ metinleri: "Mermi uzunluğu" (`EnvironmentFieldInfo.bulletLength`) ve
  Spin drift (`ProSectionInfo.spinDrift`) içindeki "Boşsa profildeki
  uzunluk kullanılır" cümlesi artık yanlış olduğu için "Boşsa
  hesaplanmaz." oldu.
- `docs/reports/formul_denetimi_rapor.md`, "Profil mermi uzunluğu"
  bölümü: "2026-10-13 23:32: sahip kararıyla geri alındı, yalnız Pro
  kutusu" notu eklendi.

## Hesap uzunluğu nereden alıyor

Yalnız Pro > Tüfek düzeltmeleri > "Mermi uzunluğu" kutusundan. Değer
0'dan büyük ve en çok 100 mm ise Sg (Miller) ve spin drift hesaplanır;
kutu boşsa ya da değer geçersizse ikisi de hesaplanmaz (`null`). Profilde
kayıtlı uzunluk hesaba hiç girmez.

## Neden

Profil kutusu gizlenince kullanıcının göremediği, değiştiremediği eski bir
profil uzunluğu sessizce spin drift'i ve Sg'yi değiştirebilirdi. Tek
kaynak (Pro kutusu) olunca kullanıcı neyin hesaba girdiğini her zaman
görür.

## Kenar durumlar

- **Eski profilde kayıtlı uzunluk:** profil sorunsuz açılır ve kaydedilir;
  uzunluk kayıtta kalır (veri kaybı yok), ama hesaba girmez ve özette
  görünmez. Bayrak açılırsa (`--dart-define=PROFILE_AMMO_LENGTH=true`)
  kutu kayıtlı değerle geri gelir.
- **Mühimmat değişirse:** tüfek türü PCP ↔ Ateşli değişince mühimmat zaten
  boşaltılır; o zaman eski uzunluk da yeni kayda taşınmaz (başka mühimmat).
- **PCP ve Ateşli:** Profil kutusu yalnız PCP'de vardı, şimdi ikisinde de
  yok. Pro "Mermi uzunluğu" kutusu ve ⓘ'si iki türde de olduğu gibi
  duruyor. Ateşli tüfekte davranış aynı; tek fark, mühimmat kaydında bir
  uzunluk olsa bile (ör. yedekten gelen) artık Sg'ye girmemesi.
- **Pro kutusu boş:** profilde uzunluk olsa bile Sg, spin drift ve
  kararlılık uyarısı çıkmaz (Pro'ya yazmadan önceki eski davranış).
- **Diabolo pellet:** değişmedi, spin drift yine hesaplanmaz.

## Bilerek yapılmayanlar

- `Ammunition.lengthMm`, kayıttan okuma (`user_catalog.dart`), saklama
  doğrulaması ve `ProfileFieldInfo.ammoLength` silinmedi ("gizle, silme").
- Kayıtlı eski uzunluklar Pro kutusuna otomatik taşınmadı; sahip "yalnız
  Pro kutusu" dedi, görünmeyen değerin hesaba sızmaması isteniyor.
- Hedef sayfası ve profil özetinin diğer satırlarına dokunulmadı (açık
  `fix/profilsiz-hedef-ayak` işiyle çakışmasın diye fark küçük tutuldu).
- Birleştirme, TestFlight yok; PR taslak.

## Testler

- `test/uzunluk_sadece_pro_test.dart`
  - "the Profil summary shows no Uzunluk line"
  - "an old profile with a saved length opens without the box and keeps
    the length when saved" (kutu yok, Güncelle sonrası kayıtta 10.5 mm
    duruyor)
- `test/profile_lists_test.dart` — "PCP mühimmat: Tip, then Ağırlık | BC;
  no Marka, no Uzunluk" (düzen ve kutunun yokluğu)
- `test/profile_editor_fail_closed_test.dart` — PCP'den Ateşli'ye geçiş
  testi artık Uzunluk kutusu yazmıyor, kutunun olmadığını doğruluyor.
- `test/formul_denetimi_2026_10_13_test.dart` (PR #264 testi güncellendi)
  - "slug: a saved Profil length alone gives no spin drift" (Pro boş →
    yok)
  - "slug: the Pro box length is used, the Profil one ignored" (profil
    10 mm + Pro 12 mm = profilsiz + Pro 12 mm; Pro 10 mm farklı sonuç)
  - "pellet: no spin drift even with a typed length" (değişmedi)
- `test/flight_warnings_wiring_test.dart` — "kayıtlı mühimmat uzunluğu
  Sg'ye girmez, yalnız Pro kutusu" (ateşli; kayıtlı 45 mm uyarı vermez,
  Pro 45 mm kararsız uyarısı verir). Diğer ateşli testleri değişmedi.
- `tools/test_formul_denetimi_2026_10_13.py` — kaynak sözleşmesi: yalnız
  `_parsed(bulletLengthCtl)`, `ammunition?.lengthMm` yok.

## Doğrulama

Yerel (Flutter SDK bu ortamda yok, bu yüzden `tools/claude_flutter_verify.sh`
çalıştırılmadı):

- `python3 tools/offline_dart_lint.py` — PASS (324 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` — PASS (732 test)

CI:

- Format: https://github.com/sniperTurk/flutter-app/actions/runs/38464905512 — başarılı; biçimlendirme commit'i (`eb80061`, yalnız test dosyasında 1 satır) dala eklendi ve çekildi
- Testler (test-diag, files=test): https://github.com/sniperTurk/flutter-app/actions/runs/38465196955 — başarılı (`flutter test` çıkış kodu 0, bütün test klasörü, yeni testler dahil). Not: ek açıklamalardaki "KESIK" satırları ve `truing_drag_band_test` / `scope_mount_cant_test` yığın izleri geçen testlerin günlük çıktısıdır; aynı satırlar main üzerinde de çıkıyor (karşılaştırma: https://github.com/sniperTurk/flutter-app/actions/runs/38465984382, o da başarılı).
- Analyze (analyze-diag): https://github.com/sniperTurk/flutter-app/actions/runs/38465200489 — başarılı (`flutter analyze --fatal-infos --fatal-warnings`, sorun yok)

iOS CI / Simulator / TestFlight bu iş kapsamında çalıştırılmadı.

---
_Generated by [Claude Code](https://claude.ai/code)_
