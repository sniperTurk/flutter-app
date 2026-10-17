Yüksek bulgu: 1

# Denetim: TestFlight 114 öncesi uçtan uca hesap denetimi

Sahip emri: 17.10.2026 22:33 (İstanbul) — "bekleyen işlerin testini başlat ver artık yayınla".
Kapsam: TestFlight 113 (commit 2101b3f, run 113) ile `origin/main` (53100e05) arası. Yalnız rapor; uygulama kodu değişmedi.

`git log 2101b3f..origin/main`: 10 commit, hepsi listede (#387, #388, #389, #390, #391, #392, #393, #394, #395, #398). **Fazladan commit yok.**
İkinci hedef: açık PR #400 (`feat/google-hava-verisi`, head a1fd2905). PR #399 (`fix/pro-aralik`, head 6607673a) yalnız "hesap değişmiyor mu" diye bakıldı.

## Bulgular

| Kimlik | Önem | PR | Girdi → beklenen → gerçek | Referans |
|---|---|---|---|---|
| D114-0 | YÜKSEK | #389 × #395 | `origin/main` (53100e05) derleme → derlenmeli → **derlenmiyor**. #395 `_shortCartridge` metodunu ve `MenzilSelect`'in kısa ad (`short:`) parametresini sildi; ondan sonra birleşen #389 ikisini de kullanıyor (`profile_editor_rifle.dart:87` undefined_method, `:118` undefined_named_parameter). Her PR kendi dalında yeşildi, birlikte kırık. Bu hâliyle TestFlight derlemesi çıkmaz; Profil kütüphanesini içe aktaran bütün testler yüklenemez. | `flutter analyze` (analyze-diag run 39065099052); main iOS CI run 39063391136 kırmızı |
| D114-1 | ORTA | #400 | Konumdan hava al (Google) → sahibin 20:14 sözüne göre basınç da Google'dan gelmeli → Google'ın `meanSeaLevelMillibars` değeri okunuyor, doğrulanıyor ama **hiçbir kutuya yazılmıyor**; İstasyon basıncı boş/elle kalıyor. Hesap yanlış değil (çift düzeltme de yok), ama istenen iş eksik. Yazılacaksa deniz seviyesi → istasyon çevrimi irtifa ister (ayrı görev, sahip kararı). | Sahip 17.10 20:14 "Rüzgâr ve basınç da buradan alınacaktı!"; Google Weather API belgesi (`airPressure.meanSeaLevelMillibars`, deniz seviyesine indirgenmiş); PR #400 raporu "Bilerek yapılmayan" |
| D114-2 | ORTA | #388 | PCP, Tüfek kartı 300 m/s (984 fps), En düşük 250 / En yüksek 260 m/s → hesap 255 m/s (837 fps) kullanıyor (doğru) → **Profil özeti Tüfek kartı, Profiller listesi satırı ve Kronograf ekranı "Namlu çıkış hızı 984 fps" gösteriyor**; ikili girilince Tüfek kartındaki hız zorunlu ama hesapta kullanılmıyor ve bunu söyleyen bir yer yok (ⓘ metinleri söylemiyor). Hedef'in Hesap dökümü doğru hızı (837 fps) gösteriyor. | El hesabı (250+260)/2 = 255 m/s = 836,6 fps; `profileListSummary`, `profile_summary.dart:243`, `chrono_screen.dart:362/416` |
| D114-3 | DÜŞÜK | #387 | Eski sürümden kalan, artık kutusu olmayan Pro > Mermi uzunluğu değeri (gizli, `bulletLength`) 100–150 mm ise: TF113'te yok sayılıyordu → şimdi Sg/spin drift'e giriyor. Profil > Mühimmat'ta uzunluk varsa o kullanılır; gerçek bir merminin 100 mm'den uzun olması pratikte yok. | `_bulletLengthMm` 0–100 → 0–150 |
| D114-4 | DÜŞÜK | #400 | Google 10 sn zaman aşımı + MET 12 sn → ağ kötüyken "alınıyor…" en çok ~22 sn sürebilir (önce ~12 sn). Hesap etkisi yok. | `google_weather_provider.dart` timeout 10 s |

D114-0 bir derleme hatası; hesap bulgularının hiçbiri sayının yanlış hesaplandığı bir durum değil. **D114-0 düzelmeden TestFlight başlatılmamalı** (CLAUDE.md: yüksek bulgu açıkken TestFlight yok).

## Bulgusuz kontrol edilenler

- **#388 PCP ortalama hız** — giriş (fps) → `ProfileInput.validate` → `RifleProfile` (kayıt/yükleme) → `velocityMps` → çözücü. Ortalama el hesabıyla aynı (250/260 → 255 m/s). Hedef, Pro (barut satırı), MPBR, Hız Doğrulama ortalamayı kullanıyor; Kronograf/Doğrulama "Profile uygula" ikili varken tek hız yazmıyor (onaydan önce reddediyor). Eşit ikili (255/255) kaydoluyor. Yalnız biri girilirse kayıt engelleniyor; eskiden tek değerle kaydedilmiş profil açılıyor ve Tüfek hızını kullanıyor (lone min ve lone max). Ters ikili (min > max) kaydedilemiyor; bellekte ters olursa ortalama alınmıyor. Ateşli silahta PCP kutuları düşürülüyor. Araçlardan tek değerli eski PCP'ye hız yazılınca tek değer korunuyor. Profil kopyalama ikiliyi taşıyor. Hedef, ikili değişince yeniden kuruluyor (home_screen anahtarı). Bir önceki denetimin (test/audit_2026_10_17e) bağımsız referansı (tools/formula_reference.py, CIPM-2007): 845 fps → 100 m 6,7532 mrad, 950 fps → 5,3710 mrad; geçiyor. #368 PCP kartları ile etkileşim: ikili Mühimmat kartında, hız Tüfek kartında; kayıt/yükleme yolu bozulmamış. Eski denetim testlerinden ikisi (audit_2026_10_14b F3/KUL-2, audit_2026_10_15c KUL-10) bu kasıtlı kural değişikliği için yeniden yazılmış; zayıflatılmamış (sayılar ve beklentiler yeni kurala göre aynı sıkılıkta).
- **#387 Mermi uzunluğu 150 mm** — Profil kutusu 1–150 mm, hesap 0–150 mm. Miller formülü yayımlanmış hâliyle birebir; .308 168 gr 1,215" 1:10 2650 fps 59 °F 29,92 inHg → Sg 2,4591 (el hesabı). 150 mm'de Sg sonlu, pozitif, "kararsız". Saçma (pellet) yolunda Sg/spin drift hiç hesaplanmıyor (değişmedi). #379 (Pro Tüfek) ile etkileşim: Pro'da kutu yok, Profil değeri önce, eski Pro değeri yedek (D114-3 dışında değişiklik yok). 0 mm/boş → hesaplanmaz; 151 mm → Profil kaydetmez.
- **#389 Diğer kalibre silindi** — yalnız editör. Modelin listesinde olmayan eski kalibre kutuda "kayıtlı" değeriyle gösteriliyor ve dokunulmadan kaydedilince aynı kalıyor; çözücü tüfek kaydındaki `caliberMm`'i okuyor, bu değişmedi. PR'ın 344 satırlık testi + ekran testi var.
- **#390 Arken Optics SFP** — OUTRIDER 3-18x50 SFP üretici sayfasında (arkenopticsusa.com, 17.10.2026 okundu) 0.25 MOA, 56/48 MOA, 14.4 in, FDR 29.2 oz, SFP, Zero Stop: No; katalogla aynı. Üç modelde MOA → mrad (× π/10,8), in → mm, oz → g çevrimleri doğru. Yalnız tarih/not değişti, sayılar aynı.
- **#391 Klik değeri (özet)** — özet, Hedef'in kule kliğiyle aynı kuralı kullanıyor (birim aynıysa katalog kliği, değilse 0,1 mrad / ¼ MOA; `ScopeDialMath.standardClick` = `AngularUnit.standardClick`).
- **#392 Tip / uzunluk, Mühimmat türü** — yalnız gösterim; hesaba girmiyor. Elle girilmiş el dolumu merminin "Fabrika fişeği" görünmesi PR raporunda zaten yazılı (editörle aynı davranış).
- **#393, #394, #395, #398 (UI)** — diff'lerde hesap koduna dokunan satır yok (yalnız yerleşim, başlık, logo, tek satır seçim kutusu, tarih satırı). #395'te kaldırılan `_shortCartridge` yalnız gösterim. Ateşli silah altın sayı testleri (ballistic_audit, formula_reference_vectors vb.) değiştirilmemiş; tam paket CI'da.
- **#399 Pro aralık** — diff yalnız `pro_ayarlar_view.dart` yerleşimi (Stack/padding/60 pt başlık). **Hesap değişikliği yok.**
- **#400 Google hava** — birimler: °C (`unit: CELSIUS` şartı), % nem 0–100, hPa (1 mbar = 1 hPa), rüzgâr km/h ÷ 3,6 (15 km/h → 4,1667 m/s), birim farklıysa ret → MET. Basınç türü deniz seviyesi olarak işaretli ve sayfaya hiç yazılmadığı için **istasyon/deniz seviyesi çift düzeltmesi ya da irtifa ile çift sayım yok** (hava yoğunluğu yalnız kutulardaki İstasyon basıncı/İrtifa'dan). Rüzgâr saati elle kalıyor; yön yalnız notta. Zaman: `currentTime` 9 basamaklı kesir doğru okunuyor; tazelik denetimi (6 sa) çekme zamanına göre, MET ile aynı. Google hata/anahtarsız/429/5xx/bozuk veri → MET Norway, mesajlar eskisi gibi. Anahtar: depoda yok, `--dart-define` ile geliyor; `ClientException` metni aktarılmıyor, `FallbackWeatherProvider` hatayı yutuyor, log yok; Python güvenlik testleri (919) geçti. Aynı değerler iki kaynaktan gelince sayfa aynı (PR'ın testi).

## Kontrol edilemeyenler

- **Yerel Flutter doğrulaması: BLOCKED.** `tools/claude_bootstrap_and_verify.sh`: Flutter 3.47.2 deposu indirildi, ama Dart SDK/engine `storage.googleapis.com`'dan indirilemedi (vekil 403). Sonuç: "BOOTSTRAP BLOCKED: Expected Flutter 3.47.2, found unknown." Dart testleri yerelde çalıştırılamadı; CI'da çalıştırıldı (aşağıda).
- Yerelde çalışanlar: `python3 tools/offline_dart_lint.py` PASS (main+test 450 dosya; #400 dalı 442 dosya), `python3 -m unittest discover -s tools -p 'test_*.py'` main 915 test OK, #400 dalı 919 test OK.
- Google'ın gerçek yanıtı ve anahtar kısıtı: anahtar yalnız TestFlight derlemesinde; Simulator/CI'da Google'a istek gitmiyor. Gerçek cihazda görülmeli.
- Simulator/cihaz ekranları bu denetimde çekilmedi (hesap denetimi).

## Testler (test/audit_testflight_114/)

- `denetim_114_test.dart` (bu dal): #388 ortalama, eşit ikili, tek değer reddi, ateşli silahta düşürme, tek değerli eski profil yükleme (min ve max), ters ikili, Araçlar yazma kuralı; #387 Miller el hesabı ve 150 mm; #390 üretici değerleri. Profil kütüphanesini içe aktarmadığı için kırık main'de de çalışıyor: **11 test geçti** (CI).
- `denetim_114_ozet_test.dart` (bu dal): **D114-0** kaynak testi `skip:` ve **D114-2** `skip:` (Profiller listesi hesap hızını göstermeli). Bu dosya Profil kütüphanesini içe aktardığı için D114-0 düzelene kadar yüklenemez; D114-0'ın düzeltmesi bunu da çözer.
- `denetim_114_pr400_test.dart` (#400 head + bu test, dal `audit/testflight-114-pr400`, PR açılmadı; #400 birleşince eklenmeli): birimler, 360° → 0°, akla yatkın olmayan basınç reddi, basıncın İstasyon basıncına yazılmadığı (çift düzeltme yok). **D114-1** `skip:`.
- D114-3 ve D114-4 için test eklenmedi (DÜŞÜK; davranış kasıtlı/sahip kararı).

## CI bağlantıları

- `denetim_114_test.dart`, test-diag (audit/testflight-114): **başarılı** — https://github.com/sniperTurk/flutter-app/actions/runs/39065335502
- İlk deneme (iki dosya birlikte): **başarısız**, dosya yüklenemedi (D114-0) — https://github.com/sniperTurk/flutter-app/actions/runs/39064592613
- analyze-diag (audit/testflight-114 = main + testler): **başarısız**, D114-0'ın iki hatası — https://github.com/sniperTurk/flutter-app/actions/runs/39065099052
- main iOS CI (push, 53100e05): **başarısız** — https://github.com/sniperTurk/flutter-app/actions/runs/39063391136
- #400 + denetim testi (audit/testflight-114-pr400), test-diag: **başarılı** — https://github.com/sniperTurk/flutter-app/actions/runs/39064594338
- PR #400'ün kendi iOS CI'ı (run 39064038950): `wind-acceptance` başarılı, `dart-checks` **başarısız**, `verify` atlandı — https://github.com/sniperTurk/flutter-app/actions/runs/39064038950 (nedeni bu denetimde incelenmedi; PR CI main ile birleştirilmiş hâli derlediği için D114-0 olabilir, doğrulanmadı).
- Bu PR'ın iOS CI'ı (`verify`, `dart-checks`, `wind-acceptance`): main kırık olduğu için `verify`/`dart-checks`'in kırmızı olması bekleniyor; sonuç aşağıya eklenecek.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
