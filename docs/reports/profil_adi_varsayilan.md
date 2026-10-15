# Profil adı varsayılanı: "Profil"

Sahip kararı: 15 Ekim 2026, 13:16 (İstanbul) — "Profil adı yeni profilde "Yeni Profil" ile dolu geliyor (12 Ekim kararı). Profil olsun".

## Ne
- Profil Oluştur sayfasında yeni profilin Profil adı kutusu artık "Profil" ile dolu gelir.
- Bu ad başka bir kayıtlı profilde varsa sıradaki boş numara kullanılır: "Profil 2", "Profil 3", … (araya boşluk düşmüşse ilk boş numara, ör. "Profil" ve "Profil 3" varken "Profil 2").

## Nasıl
- `lib/features/profiles/profile_editor.dart` içindeki `defaultProfileName` fonksiyonunda temel ad `'Yeni Profil'` yerine `'Profil'` oldu; numaralama mantığına dokunulmadı. Açıklama yorumu güncellendi.
- Kutunun davranışı aynı: kutuya dokununca varsayılan ad silinir, boş bırakılırsa varsayılan ad geri gelir, boş kutuyla kaydedilirse varsayılan ad kullanılır.

## Neden
- Sahibin 15 Ekim kararı; 12 Ekim'deki "Yeni Profil" varsayılanının yerini alır.

## Uç durumlar
- Önceden "Yeni Profil" adıyla kaydedilmiş profil adını korur; yeniden adlandırma ya da taşıma (migration) yok. Yeni profil bu durumda "Profil" ile açılır (o ad boş olduğu için).
- Kayıt anahtarları ve veri biçimi değişmedi; eski kayıtlar aynen yüklenir.
- "Profil" kelimesi alt menü sekmesinin ve başka metinlerin de adı. Bu yüzden testlerde `find.text('Profil')` kullanılmadı; bulucular profil listesindeki satırın ad metnine (`profile-row-name` anahtarı) daraltıldı. Testler gevşetilmedi, aksine daha belirgin oldu.

## Bilerek yapılmayan
- Başka hiçbir arayüz, metin, yerleşim veya davranış değişikliği yok.
- ⓘ metni değişmedi: `profile_field_info.dart` içinde "Yeni Profil" geçmiyor.
- Mevcut profillerin adları değiştirilmedi.

## Hangi test
- `test/profile_page_test.dart`: `defaultProfileName` beklentileri "Profil / Profil 2 / Profil 3" oldu ve eski "Yeni Profil" adının yeni varsayılanı engellemediği eklendi; "ikinci yeni profil "Profil 2" olarak açılır" testi güncellendi; yeni test: kayıtlı "Yeni Profil" adını korur, yeni profil "Profil" olarak açılır.
- `test/menzil_shell_test.dart`: kaydedilen profilin adı "Profil"; listedeki satır anahtarla bulunup adı kontrol ediliyor.
- `integration_test/app_launch_test.dart`, `integration_test/sim_screens_test.dart`, `integration_test/sim_screens_paralaks_mpbr_test.dart`: kayıttan sonra listede adı "Profil" olan tek satır aranıyor. Simulator testi kalıcı kayıtta `"name":"Profil"` alanını arıyor (eskiden yalnızca metin içinde "Yeni Profil" aranıyordu).
- `tools/test_ios_profile_persistence_platform_contract.py`, `tools/test_ios_profile_persistence_smoke_contract.py`: yeni işaretlere göre güncellendi.
- Yerelde: `python3 tools/offline_dart_lint.py` geçti (365 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (842 test).
- Bu ortamda Flutter SDK yok; `flutter test` / `flutter analyze` yerelde çalıştırılmadı, CI'da çalıştırıldı.

## CI bağlantıları
- Dart format düzeltme: https://github.com/sniperTurk/flutter-app/actions/runs/38719650118 — başarılı; biçim commit'i (1077ffb) dala alındı.
- Test teşhisi (`test-diag.yml`, tüm `test/`, commit 1077ffb): https://github.com/sniperTurk/flutter-app/actions/runs/38719939375 — başarılı (`flutter test` çıkış kodu 0).
- Analiz teşhisi (`analyze-diag.yml`, `flutter analyze --fatal-infos --fatal-warnings`, commit 1077ffb): https://github.com/sniperTurk/flutter-app/actions/runs/38719942590 — başarılı.
- PR'ın iOS CI çalışması (commit 6a259c1, ilk rapor dahil): https://github.com/sniperTurk/flutter-app/actions/runs/38720052379 — `dart-checks` başarılı, `wind-acceptance` başarılı, `verify` başarılı (iOS Simulator derlemesi ve Simulator'da `app_launch_test.dart` başarılı); `ios-simulator` işi iş akışı tarafından atlandı (skipped).

Bu rapor güncellemesi yalnızca belge değişikliğidir; PR'daki son commit için CI yeniden çalışır, sonucu PR sayfasındadır. Birleştirme ve TestFlight yok; taslak PR.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
