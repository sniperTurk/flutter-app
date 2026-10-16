# Hava Durumu: Mühimmat sıcaklığı kendi bölümünde

Sahibin isteği (16.10.2026 07:08, İstanbul): "Mühimmat sıcaklığı için yeni bir sekme yapalım, burada zorunlu alan gibi anlaşılabilir. Hava sekmesi içinde mühimmat sıcaklığını sil, gizleme yapma."

## Ne
- "Hava" kartındaki Mühimmat sıcaklığı kutusu silindi (kod silindi, bayrak yok). Hava kartında Sıcaklık | Bağıl nem tek satırda, altında hava verisi düğmesi.
- Hava kartının hemen altına (Basınç Ölçer'den önce) yeni bölüm: başlık "Mühimmat sıcaklığı", başlığın yanında ⓘ, satırın sağ ucunda "isteğe bağlı" (ikincil renk, koyu temada #9CB1C0). Altında kendi kartı ve içinde aynı kutu.
- Bölüm yalnız ateşli silah profillerinde görünür (eskiden kutu da yalnız orada görünüyordu). PCP'de yok.

## Nasıl
- `lib/features/ballistics/hava_durumu_view.dart`: kutu Hava kartından çıkarıldı; `if (_isFirearm)` altında `MenzilSectionHeader` (boyut 18, diğer Hava Durumu başlıklarıyla aynı boşluk) + `MenzilCard` (Hava kartıyla aynı iç boşluk) + `MenzilFieldGrid` içinde aynı `MenzilInput`.
- Kutu aynen taşındı: anahtar `env-ammo-temp`, aynı `ammoTempCtl` denetleyicisi, aynı °C/°F birimi, aynı ⓘ metni (`EnvironmentFieldInfo.ammoTemperature`), aynı `onChanged`.
- Başlık deseni onaylı "Ek mühimmat bilgileri" başlığıyla aynı: solda başlık, ⓘ başlığın hemen yanında, "isteğe bağlı" sağ uçta, metin sola yaslı.

## Neden
Kutu Sıcaklık'ın yanında durunca hava için doldurulması gereken bir alan gibi okunuyordu. Kendi bölümü ve "isteğe bağlı" yazısıyla zorunlu olmadığı görülür.

## Uç durumlar
- Kayıt ve hesap değişmedi: değer aynı `ammoTemp` anahtarıyla profil başına kaydedilir/yüklenir; eski kayıtlı değer taşınan kutuya gelir.
- Boş kutu eskisi gibi hava sıcaklığını kullanır; barut katsayısı yoksa kutu hesabı değiştirmez; geçersiz değer (ör. 75 °C) eskisi gibi yok sayılır.
- Profil yokken gösterilen Hava Durumu'nda ateşli silah olmadığından bölüm görünmez (önceki davranış).
- Dar ekran (320 pt) ve yazı ölçeği 1.3'te başlık iki satıra kayabilir; taşma yok (testte doğrulandı).
- Başlıktaki ⓘ ile kutudaki ⓘ aynı metni açar (istekte ikisi de istendi; yeni metin yazılmadı).

## Bilerek yapılmayan
- Kronograf ekranındaki "Mühimmat sıcaklığı" (`chrono_screen.dart`) değişmedi.
- Rüzgâr bölümü ve sayfanın üstü değişmedi (açık PR #335 ve fix/hdf1-ruzgar-rehberi-sil ile çakışmamak için).
- Hesap, kayıt anahtarı, doğrulama, birimler değişmedi. Başka değişiklik yok.
- `docs/design/clean-2026-10-15/README.md` depoda yok; okunamadı.

## Testler
- Yeni: `test/muhimmat_sicakligi_bolum_test.dart`
  - ateşli: kutu Hava kartında değil, yeni kartta; başlık, ⓘ, "isteğe bağlı" (#9CB1C0, sağ uçta); Sıcaklık | Bağıl nem aynı satırda; bölüm Hava kartı ile Basınç Ölçer arasında; başlıktaki ⓘ açıklamayı açar.
  - PCP: bölüm yok.
  - Kayıtlı değer (35) taşınan kutuya yüklenir; çözüm, aynı değeri elle yazmakla birebir aynı; boş kutu hava sıcaklığına (main davranışı) döner; kayıt aynı `ammoTemp` anahtarında.
  - 320 ve 390 pt, yazı ölçeği 1.3: taşma yok.
- Güncellenen (yalnız konuma bağlı bulucu): `test/ammo_temperature_test.dart` → "firearm: next to Sıcaklık, on the same row" testi artık kutunun yeni kartta ve Sıcaklık'ın altında olduğunu kontrol ediyor; `find.text('Mühimmat sıcaklığı') findsOneWidget` kutunun içine daraltıldı (başlık da aynı metni taşıyor).
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (400 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 868 test OK. Flutter SDK bu ortamda yok; widget testleri yalnız CI'da çalıştı.

## CI
- Format (dart format, iş akışı 375209577): https://github.com/sniperTurk/flutter-app/actions/runs/38849499142 ve https://github.com/sniperTurk/flutter-app/actions/runs/38850751386 — başarılı.
- İlk çalıştırma: yeni testte bir geometri şartı (ⓘ ile "isteğe bağlı" arasında boşluk beklentisi; ikisi bitişik, 263.0 = 263.0) düştü: https://github.com/sniperTurk/flutter-app/actions/runs/38849635661/job/116807764805 . Şart "≥" yapıldı, kod değişmedi.
- Düzeltmeden sonra (main #335 rebase'inden önce), commit 6943e7e:
  - iOS CI / dart-checks: başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38850755742/job/116811206683
  - iOS CI / wind-acceptance: başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38850755742/job/116811206438
  - iOS CI / verify: başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38850755742/job/116814989487
  - test-diag (files=test): başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38850976148
  - analyze-diag: başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38850978433
- Sonra main'e (#335 RUZ-1/RUZ-2) rebase edildi, çakışma yok. Rebase sonrası son çalıştırmaların sonuçları PR açıklamasının sonunda.
- Code Review ve Security review PR üzerinde çalıştırıldı: sorun bulunmadı (https://github.com/sniperTurk/flutter-app/pull/355#issuecomment-6207948340).
- ios-simulator işi bu iş akışında atlandı (skipped); Simulator, TestFlight, App Store çalıştırılmadı.

---
_Generated by [Claude Code](https://claude.ai/code)_
