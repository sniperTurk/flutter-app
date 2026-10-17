# Pro barut notu — Tüfek düzeltmeleri

Dal: `fix/pro-barut-not` (main @ 8cc3aab'dan) · Taslak PR (birleştirilmedi, TestFlight yok).

## Sahibin kararı (İstanbul, 17.10.2026 10:28–10:35, TestFlight 112, Pro Ayarlar → Tüfek düzeltmeleri açık)
- "Mermi uzunluğu ve mühimmat sıcaklığı yan yana olacak."
- "İsteğe bağlıyı sil."
- Eski not için: "ben bile anlamadım … bu bilgi notunu değiştir"; yeni metinler için: "Yeni açıklama metin daha doğru ifade ediyor".

## Ne yapıldı
1. **Mermi uzunluğu | Mühimmat sıcaklığı yan yana.** Ateşli silahta iki kutu aynı satırda: Mermi uzunluğu solda, Mühimmat sıcaklığı sağda. "Yukarı + / aşağı −" | "Sağ + / sol −" satırıyla aynı iki kutulu satır (`MenzilFieldGrid`), aynı sütun genişlikleri. Birimler kutunun içinde (mm, °C; ABD birimlerinde °F, önceki gibi). Kutularda ⓘ yok (Pro açılır bölüm istisnası); açıklamalar bölüm başlığındaki ⓘ sayfasında, değişmedi.
2. **"isteğe bağlı" silindi.** Mühimmat sıcaklığı yanındaki yazı ve onun yerleşim kodu silindi; testlerdeki ilgili beklentiler de silindi/değiştirildi. Başlık ⓘ metni "isteğe bağlı" içermiyordu, dokunulmadı.
3. **Barut notu yeni metin** (`pro-powder-source`), sahibin onayladığı metinler harfi harfine, sayı biçimi aynı (`n(k)`, `n(t0)`):
   - Katsayı ya da hız ölçüm sıcaklığı yoksa: "Mühimmat sıcaklığının hesaba girmesi için Profil → Mühimmat'ta Barut katsayısı ve Hız ölçüm sıcaklığı kutularını doldurun. Bu iki kutu boşsa buraya yazılan sıcaklık hesabı değiştirmez."
   - İkisi de profilde: "Hesapta kullanılan: Barut katsayısı %1,5 / 15 °C, Hız ölçüm sıcaklığı 20 °C. Değiştirmek için Profil → Mühimmat."
   - İkisi de eski sürümde Pro'da girilmiş: "Hesapta kullanılan: Barut katsayısı %1,2 / 15 °C, Hız ölçüm sıcaklığı 21 °C. Bu değerler eski sürümde burada girilmişti; artık Profil → Mühimmat'ta değiştirilir."

## Nasıl
- Yalnız `lib/features/ballistics/pro_ayarlar_view.dart` (uygulama kodu). Mermi uzunluğu kutusu küçük bir yardımcıya (`_bulletLengthInput()`) alındı; aynı anahtar (`pro-bullet-length`), denetleyici, etiket, birim. Ateşli silahta `MenzilFieldGrid(key: 'pro-ammo-temp-row', [Mermi uzunluğu, Mühimmat sıcaklığı])`; PCP'de Mermi uzunluğu eskisi gibi tek başına tam satır.
- Mühimmat sıcaklığı kutusu aynı: anahtar `env-ammo-temp`, denetleyici `ammoTempCtl`, kayıt `ammoTemp`/`ammoTempText`, birim, klavye. Satır anahtarı `pro-ammo-temp-row` korundu (eski ekran görüntüsü turu da çalışsın diye).
- "Profilde yiv yönü veya yiv oranı yok" uyarısı eskiden Mermi uzunluğu ile Mühimmat sıcaklığı arasındaydı; iki kutu artık aynı satırda olduğu için uyarı satırın altına geldi (aynı koşul, aynı metin).
- `lib/ui/menzil_widgets.dart`'a dokunulmadı (PR #368 ile çakışmasın diye). `pro_ayarlar_view.dart` diff'i yalnız bu bölümde.

## Neden
Sahip TestFlight 112'de iki kutunun alt alta ve "isteğe bağlı" yazısının gereksiz durduğunu, notun anlaşılmadığını söyledi; yeni metinleri onayladı.

## Uç durumlar
- **PCP:** Mühimmat sıcaklığı ve barut notu yok (önceki gibi). Mermi uzunluğu bugünkü gibi tam satır (Gerçek / yazan kutusuyla aynı en). Böylece PCP düzeni hiç değişmedi.
- **Dar ekran / büyük yazı:** `MenzilFieldGrid`, Yukarı | Sağ satırıyla aynı kuralı uygular: sütun başına yer yetmezse (genişlik / yazı ölçeği < 300) iki kutu alt alta iner. 320 pt + 1,3 yazı ölçeğinde iki satır da alt alta iner, taşma yok (test). 320 pt + 1,0'da Mermi | Mühimmat satırı Yukarı | Sağ satırıyla aynı davranır (test).
- **"Eksik" koşulu:** kod `k == null || t0 == null` koşulunu kullanıyor, değiştirmedim. Yalnız profilde biri varsa ve eski Pro kayıtlarında ikisi varsa eski kayıt kullanılır (değişmedi). Etiketler `Barut katsayısı` ve `Hız ölçüm sıcaklığı` `lib/features/profiles/profile_editor_ammo_extra.dart`'ta (görev metnindeki `profile_editor_ammo.dart` değil); metinle aynı.
- **Bilgi (değiştirilmedi, kararı sahibin):** hesap (`PowderTemperature.factor`) katsayı |k| > 10 ya da hız ölçüm sıcaklığı −50…60 °C dışındaysa düzeltme yapmaz; bu durumda not yine "Hesapta kullanılan: …" der. Profil düzenleyici bu aralık dışını kabul ediyorsa ayrı görev olabilir. Katsayı 0 ise hız değişmez, not yine değerleri gösterir.
- **Kayıtlı veri:** kayıt anahtarları değişmedi; eski kayıtlı Mühimmat sıcaklığı ve eski Pro barut değerleri açılır (testler).

## Bilerek yapılmayan
- Hesap, varsayılan, bayrak, kayıt anahtarı, başka sayfa, başlık ⓘ metinleri, `EnvironmentFieldInfo.ammoTemperature` metni değişmedi.
- `lib/ui/menzil_widgets.dart` değişmedi.

## Testler
- `test/muhimmat_sicakligi_bolum_test.dart` (güncellendi): gerçek Pro sayfası, Tüfek düzeltmeleri açık, 390 pt: Mermi uzunluğu ve Mühimmat sıcaklığı aynı üst kenar (±0,5 pt), Mermi solda, sütunlar Yukarı | Sağ ile aynı (sol kenar ve en ±0,5 pt), satır Yukarı | Sağ'ın altında ve notun üstünde; "isteğe bağlı" yok; birimler mm ve °C; kutularda ⓘ yok, başlık ⓘ sayfasında Mühimmat sıcaklığı satırı. PCP: Mühimmat sıcaklığı yok, Mermi uzunluğu tam satır, not yok. 320 ve 390 pt, yazı ölçeği 1,3: taşma yok. Silinen tek test: "320 pt, yazı ölçeği 2: isteğe bağlı kesilmez" (silinen yazıya aitti).
- `test/pro_barut_not_test.dart` (yeni): üç not metni harfi harfine (eksik: ikisi boş / yalnız katsayı / yalnız sıcaklık; profilden; eski sürüm kaydından), eski metinler yok, 320 pt + 1,3'te not taşmıyor, 320 pt + 1,0 satır davranışı.
- `test/pro_barut_not_sayi_test.dart` (yeni): sabit bir ateşli silah profili (800 m/s, 1,5 %/15 °C, 20 °C), hava 15 °C, 600 m'de Hedef'in gereken üst açısı. Aynı test önce main @ 8cc3aab üzerinde çalıştırıldı (test-diag run [39014771706](https://github.com/sniperTurk/flutter-app/actions/runs/39014771706)), sayılar test içine yazıldı; dalda aynı sayılar 1e-9 hassasiyetle bekleniyor:
  - katsayılı, mühimmat boş: 5,603925379378539 mil; "Bugünkü hız: 2612 fps"
  - katsayılı, mühimmat 35 °C: 5,315103568534314 mil; "Bugünkü hız: 2664 fps" (800 × (1 + 0,015) = 812 m/s)
  - katsayısız, boş ve 35 °C: ikisi de 5,529980691211749 mil, "Bugünkü hız" yok.
- `test/support/pro_sections.dart`: silinen `pro-ammo-temp-optional` anahtarı çıkarıldı.
- `integration_test/pro_barut_not_screens_test.dart` (yeni): simülatör ekran turu.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (421 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlandı).
- Yerelde Flutter SDK kurulamadı (Dart SDK indirmesi proxy'de 403): Flutter testleri yalnız CI'da çalıştı.

## Ekran görüntüsü
Simülatör: iPhone 16e (390 pt), iOS 26.2, `sim-screens` run [39014730169](https://github.com/sniperTurk/flutter-app/actions/runs/39014730169), tur `integration_test/pro_barut_not_screens_test.dart`, çıkış kodu 0. Uygulama kodu 82056a2 (sonraki commit yalnız test + rapor). Ölçülen kutular (SIMRECT, pt): ateşli silahta Mermi uzunluğu 28–190, Mühimmat sıcaklığı 200–362, ikisinin de üst kenarı aynı (474,4); PCP'de Mermi uzunluğu 28–362 (tam satır).

| Ateşli, not 1 (katsayı yok) | Ateşli, not 2 (profilden) | PCP |
|---|---|---|
| ![not1](https://raw.githubusercontent.com/sniperTurk/flutter-app/1d3c07914be92596a97f26c95b82f245189a1aa4/latest/01_pro_atesli_not1.png) | ![not2](https://raw.githubusercontent.com/sniperTurk/flutter-app/1d3c07914be92596a97f26c95b82f245189a1aa4/latest/02_pro_atesli_not2.png) | ![pcp](https://raw.githubusercontent.com/sniperTurk/flutter-app/1d3c07914be92596a97f26c95b82f245189a1aa4/latest/03_pro_pcp.png) |

Ekranda görülen: Mermi uzunluğu (mm) | Mühimmat sıcaklığı (°C) Yukarı | Sağ satırıyla aynı hizada; "isteğe bağlı" yok; not metni onaylı metinle aynı. PCP'de düzen önceki gibi (yiv bilgisi olmayan katalog tüfeğinde spin drift uyarısı, önceki gibi). Onaylı ayrı bir çizim yok; karşılaştırma sahibin TestFlight 112 ekran görüntüsündeki sözlerine göre.

## CI
Son kod commit'i 27df26b; sonraki commit'ler yalnız bu raporu değiştirir. iOS CI PR'ın son commit'inde de çalışır; sonucu PR'ın Checks sekmesinde. 27df26b sonuçları:
- iOS CI (PR): [run 39014931793](https://github.com/sniperTurk/flutter-app/actions/runs/39014931793) — `verify` success, `dart-checks` success, `wind-acceptance` success, `ios-simulator` atlandı (isteğe bağlı iş).
- test-diag (tüm `test`): [39014926238](https://github.com/sniperTurk/flutter-app/actions/runs/39014926238) success. İlk commit 82056a2'de de: [39014727322](https://github.com/sniperTurk/flutter-app/actions/runs/39014727322) success.
- analyze-diag: [39014927900](https://github.com/sniperTurk/flutter-app/actions/runs/39014927900) success.
- format-fix (375209577): [39014924729](https://github.com/sniperTurk/flutter-app/actions/runs/39014924729) — biçim değişikliği gerekmedi.
- Code Review + Security review: PR yorumunda (engelleyici bulgu yok).
- TestFlight çalıştırılmadı.

## Not
- Sayı karşılaştırması için açılan geçici dal `tmp/pro-barut-sayi-main` silinemedi (bu oturumdan dal silme izni yok); güvenle silinebilir.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01Q1U1eLrKmxvYnPejPENnsy
