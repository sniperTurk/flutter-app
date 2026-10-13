# Profili Düzenle: "Üretim" kutusu kayıtlı tüfeğin menşeini gösterir

## Sorun

TestFlight'ta (2026-10-13) kayıtlı bir Ateşli Tüfek profili ("Christensen Arms" / "Modern Precision Rifle Rimfire") Profili Düzenle ile açıldığında Kimlik bölümündeki "Üretim" kutusu (Key `rifle-origin`) "Seçiniz" gösteriyordu. Tüfek ithal olduğu için "İthal" görünmeliydi.

## Ne değişti

- Dosya: `lib/features/profiles/profiles_screen.dart`
- Yöntem: `_ProfileDialogState.initState`
- Eklenen satır (kayıtlı tüfek listede bulunduğunda çalışan `if (known)` bloğunun başında):
  `_domestic = _domesticBrands.contains(rifleBrand.text);`

Uygulama kodunda başka hiçbir şey değişmedi. Dürbün koduna dokunulmadı. (Yalnızca iOS CI için PR #267'deki entegrasyon testi düzeltmesi alındı; aşağıdaki "iOS CI (PR) notu" bölümüne bakın.)

## Nasıl çalışır

- `_domestic` Üretim kutusunun değeridir: `true` = Yerli, `false` = İthal, `null` = seçilmemiş.
- Form açılırken kayıtlı tüfeğin Marka + Model ikilisi tüfek listesinde (`RifleLibrary`) aranır (`known`). Bu arama `_domestic` henüz `null` iken yapılır, yani bütün liste taranır.
- Tüfek listede bulunursa (`known == true`, yani `_rifleManual == false`): markası yerli markalar listesinde (`_domesticBrands`) varsa `_domestic = true` (Yerli), yoksa `false` (İthal) olur.
- Marka listesi `_domestic` ile süzülür. Tüfeğin markası kendi menşeinin listesinde her zaman bulunduğu için Marka ve Model kutuları kayıtlı değeri korur, açılışta hiçbir şey silinmez. (Silme yalnızca kullanıcı Üretim kutusunu kendisi değiştirdiğinde `onChanged` içinde olur; bu davranış değişmedi.)

## Neden

`_domestic` hiçbir zaman kaydedilmiyordu ve initState içinde de ayarlanmıyordu; bu yüzden düzenleme ekranı her zaman "Seçiniz" ile açılıyordu. Değeri kaydetmek yerine tüfeğin markasından türetmek seçildi: profil verisi ve kayıt biçimi değişmez, eski profiller de doğru değeri alır.

## Uç durumlar

- **Elle yazılmış tüfek ("Listede yok")**: `known == false`, `_rifleManual == true`. `_domestic` `null` kalır, kutu "Seçiniz" gösterir; Marka/Model yazı kutuları kayıtlı değerleri korur.
- **Hiçbir listede olmayan marka**: Yalnızca yerli markalar için bir liste vardır; o listede olmayan her liste markası İthal sayılır. Uygulamanın Üretim süzgeci de aynı kuralı kullanır (`contains(r.brand) == _domestic`), bu yüzden İthal seçiliyken bu marka Marka listesinde yine görünür.
- **Eski profiller**: Değer kaydedilmediği, her açılışta markadan hesaplandığı için eski profiller de güncelleme gerektirmeden doğru menşei gösterir.
- **Yeni profil**: `widget.initial == null` olduğu için marka boştur, kod çalışmaz; davranış değişmedi.
- **PCP tüfek**: Listedeki bir PCP tüfeği için de aynı kural geçerlidir (ör. Hatsan → Yerli).

## Bilerek yapılmayanlar

- `_domestic` profil kaydına eklenmedi (veri modeli ve yedek biçimi değişmesin diye).
- Dürbün formuna dokunulmadı (`feat/durbun-form-sade` PR'ı ile çakışmasın diye).
- Üretim kutusunun seçenekleri, metinleri ve `onChanged` davranışı değiştirilmedi.

## Testler

Yeni dosya: `test/profile_origin_edit_test.dart`

- `an imported library rifle opens on Üretim İthal`: Christensen Arms / Modern Precision Rifle Rimfire → Üretim İthal; Marka ve Model değerlerini korur; yazı kutusuna düşmez.
- `a domestic library rifle (Hatsan) opens on Üretim Yerli`: Hatsan / Escort 22LR → Üretim Yerli; Marka ve Model korunur.
- `a typed ("Listede yok") rifle leaves Üretim on Seçiniz`: elle yazılmış tüfek → Üretim boş; yazılan Marka/Model korunur.

Yerel kontroller:

- `python3 tools/offline_dart_lint.py` → PASS (310 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 724 test, OK

Bu ortamda Flutter SDK yoktu; Flutter testleri ve analiz yalnızca aşağıdaki CI çalıştırmalarında koşuldu.

## CI çalıştırmaları

CI, kod commit'i `5be2995` üzerinde koştu (bu rapor sonradan yalnızca belge olarak eklendi):

- Format (One-off dart format fix): https://github.com/sniperTurk/flutter-app/actions/runs/38422864721 — başarılı, biçim değişikliği gerekmedi (dala commit gelmedi).
- Test (One-off test diagnostic, `files=test`): https://github.com/sniperTurk/flutter-app/actions/runs/38423158360 — başarılı (bütün `test` klasörü, yeni testler dahil)
- Analiz (One-off analyze diagnostic): https://github.com/sniperTurk/flutter-app/actions/runs/38423161918 — başarılı (`flutter analyze --fatal-infos --fatal-warnings`)

## iOS CI (PR) notu

PR'ın `iOS CI / verify` işi ilk denemede (https://github.com/sniperTurk/flutter-app/actions/runs/38425602209) "Boot iOS Simulator and run launch smoke test" adımında düştü: `integration_test/app_launch_test.dart` 129. satır, PCP'de artık gösterilmeyen `ammo-brand-select` kutusunu arıyordu (`Bad state: No element`). Bu hata main'de de var ve bu PR'ın değişikliğiyle ilgisi yok. Düzeltmesi PR #267'de (`fix/ios-ci-pcp-marka`), orada simülatör testi geçti. Aynı üç `integration_test` dosyası #267'deki hâliyle birebir buraya alındı; #267 main'e girince bu değişiklik etkisiz olur, çakışma çıkmaz.

TestFlight yüklemesi yapılmadı. PR taslak olarak açıldı; birleştirme sahibin ana oturumundadır.

---
_Generated by [Claude Code](https://claude.ai/code)_
