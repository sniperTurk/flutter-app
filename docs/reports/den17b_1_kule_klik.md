# DEN17B-1: Klik değeri değişince Üst kule klik sayısı yeniden sorulur

Sahip kararı (2026-10-17 11:14 İstanbul), düzeltme "klik değeri değişince üst kule klik sayısı silinip yeniden sorulsun" diye anlatıldıktan sonra: **"o zaman önce düzelt."**
Bulgu: denetim PR #378, `docs/reports/denetim_2026_10_17b.md`, DEN17B-1 (ORTA).

## Ne

- Profil > Dürbün, elle giriş ("Aradığın dürbün listede yok mu?"):
  - Kullanıcı **Klik değeri**ni başka bir değere çevirirse **Üst kule klik sayısı** boşalır.
  - Klik değeri **"Seçiniz"** yapılırsa kule sayısı boşalır.
  - **Dürbün birimi** değişip Klik değeri boşalırsa (ör. 0,1 MRAD → MOA) kule sayısı boşalır.
- Kule sayısı şu durumlarda **korunur**:
  - kayıtlı profil açılırken,
  - listeden (katalog) dürbün modeli seçilince; katalog klik ile kule sayısını birlikte doldurur,
  - aynı klik değeri yeniden seçilince.
- Örnek: 200 klik @ 0,1 MRAD → klik 0,05 MRAD olur → kutu boşalır. 400 girilince 400 × 0,05 = **20 mrad** kaydedilir. Eskiden 200 kutuda kalıyordu ve 200 × 0,05 = **10 mrad** kaydediliyordu.

## Nasıl

Değişiklik yalnızca `lib/features/profiles/profile_editor_scope.dart` dosyasında:
- `_clickSelect` onChanged: yeni seçilen klik eski klikten **sayı olarak** farklıysa `scopeTravelElevation.clear()`.
  - Neden sayı olarak: kayıtlı profil "0.1" ile açılıyor, listeden "0,1" geliyor. Metin karşılaştırması aynı kliği farklı sayardı.
- `_scopeUnitSelect` onChanged: elle girişte birim değişikliği kliği boşaltır ya da değiştirirse kule sayısı boşalır.
  - Liste (katalog) yolunda dokunulmaz.
- Açılış (`initState`) ve katalog doldurma (`_applyScope`) bu fonksiyonlardan geçmez. `MenzilSelect` onChanged'i yalnız kullanıcı listeden seçince çağırıyor. Bu yüzden programla doldurulan değerler silinmez.

## Neden

Kule boyu = klik sayısı × klik değeri (`_travelMrad`). Klik değişince eski sayı başka bir kule boyu demek olur. Yanlış kule boyu Hedef'teki "Kule yetmez" uyarısını, otomatik kule çevirmenin sınırını ve ayak önerisini bozar.

## Uç durumlar

- **"Kaydet kapalı" beklentisi:** Görev metni "Kaydet stays blocked while it is required and empty, as today" diyor. Ama Üst kule klik sayısı bugün de **zorunlu değil**: boşsa kule boyu "bilinmiyor" olarak kaydediliyor (`_travelError` boşa izin veriyor; #367 testi de bunu bekliyor). Zorunluluk değiştirilmedi ("Nothing else").
  - Klik 0,05'e çevrilip kule boş bırakılırsa Kaydet açık kalır. Kaydedilen kule boyu yanlış 10 mrad değil, boştur. Bunu test ediyor.
  - Klik "Seçiniz" ise ya da birim kliği boşalttıysa Kaydet kapalıdır, çünkü Klik değeri eksik ("Kaydetmek için eksik: … Klik değeri").
  - Kule sayısının zorunlu olması isteniyorsa ayrı karar ve ayrı görev gerekir.
- **Listede olmayan eski klik (ör. 0,2 MRAD):** Önceki sahip kuralı geçerli (2026-10-16 22:24, "eski kayıtlar boş açılsın"). Klik "Seçiniz" açılır, kule sayısı boş görünür, Güncelle kapalıdır. Kayıtlı veri değişmez; test ediyor. Bu PR o davranışı değiştirmedi.
- **MOA ↔ SMOA, aynı sayı (1/4):** Klik listede kaldığı için boşalmaz, kule sayısı da kalır. Görev yalnız "klik boşalırsa" dediği için dokunulmadı. 1/4 MOA ile 1/4 SMOA arasında kule boyu yaklaşık %4,7 farklıdır. İstenirse ayrı karar.
- **Katalog listesi boşken elle giriş** (gerçekte olmuyor): Birim değişince klik varsayılana döner ve kule sayısı da boşalır, çünkü klik değişti.

## Bilerek yapılmayan

- Hesap, kayıt anahtarı, yerleşim, metin, liste ve başka alanlar değişmedi.
- Kule sayısı zorunlu yapılmadı.
- Denetim test dosyasının başındaki "skipped until fixed" yorumu, "skip kaldırmak dışında değiştirme" kuralı yüzünden olduğu gibi bırakıldı.
- TestFlight başlatılmadı, PR birleştirilmedi.

## Testler

- `test/audit_2026_10_17b/` (#378 dalından alındı): DEN17B-1'in iki testinde yalnız `skip: true` kaldırıldı. Diğer denetim testleri olduğu gibi duruyor.
- Yeni dosya: `test/den17b_1_kule_klik_test.dart`
  - (a) 200 @ 0,1 → 0,05: kutu boş; 400 → 20 mrad. Kutu boş kaydedilirse kule boyu boş, 10 değil.
  - Aynı klik yeniden seçilince sayı kalır. Bu hem yeni profilde hem açılan kayıtlı profilde ("0.1" / "0,125" metni) denendi.
  - (b) Seçiniz → kutu boş, Kaydet kapalı.
  - (c) MRAD → MOA: klik ve kutu boş; 1/4 MOA + 400 → 100 MOA. Birim → Seçiniz → kutu boş.
  - (d) Eski kayıtlar açılınca ve düzenlemeden Güncelle'ye basılınca her değer aynı kalıyor:
    - modelli elle giriş (1/8 MOA, 400, ayak 25),
    - modelsiz elle giriş,
    - listede olmayan eski klik (açılış hiçbir şeyi değiştirmiyor),
    - katalogla eşleşen kayıt.
  - (e) Katalog modeli (Element Optics Titan 3-18x50 FFP MOA, üretici değeri 43,63 mrad) seçilince sayı 600 olur; yeniden açılınca ve Güncelle'den sonra 600 kalır.
  - (f) Klik 0,1 → 0,05 → 0,1 yapılıp 200 yeniden girilen profil, doğrudan girilen profille birebir aynı kaydediliyor. Hedef klik sayıları elle hesapla tutuyor: 3,27 / 0,1 → 33; 45 MOA ayak → 130. Çözücü ve Hedef kodu değişmedi; diff yalnız editörde.
  - 320 pt + yazı ölçeği 1,3: taşma yok.
- Yerel:
  - `python3 tools/offline_dart_lint.py` → PASS (422 dosya, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlama, önceden var).
  - Bu ortamda Flutter SDK indirilemedi (storage.googleapis.com proxy 403). Dart testleri yalnız CI'da koştu.
- İlk hedefli test koşusunda (f) testi kendi hatası yüzünden kaldı: aynı ekranda iki store kullanılmıştı. Düzeltildi. Diğer 129 test geçti, iki DEN17B-1 denetim testi de dahil.

## Ekran görüntüleri

- Simülatör: iPhone 16e, 390 pt, `sim-screens` workflow ([koşu 39017089375](https://github.com/sniperTurk/flutter-app/actions/runs/39017089375); dal `fix/den17b-1-kule-klik` @ b36f9898; flutter test exit 0, 9 görüntü). Sonraki iki commit yalnız klik karşılaştırmasını sayıya çevirdi ve testleri düzeltti; bu ekranlarda görünen davranış aynı.
- Tur: `integration_test/den17b_kule_klik_screens_test.dart`. Tüm görüntüler: [`ci/sim-screens` latest/ @ db97bdb](https://github.com/sniperTurk/flutter-app/tree/db97bdba4fd720d745baf22206401f3e8de79dc4/latest).

| 1) Elle dürbün: 0,1 MRAD, Üst kule 200 | 2) Klik → 0,05 MRAD: Üst kule boş | 3) Klik → Seçiniz: Üst kule boş, Kaydet kapalı |
|---|---|---|
| <img src="https://github.com/sniperTurk/flutter-app/blob/db97bdba4fd720d745baf22206401f3e8de79dc4/latest/02_durbun_elle_kule_200_alt.png?raw=true" width="260" alt="kule 200"> | <img src="https://github.com/sniperTurk/flutter-app/blob/db97bdba4fd720d745baf22206401f3e8de79dc4/latest/05_durbun_klik_005_kule_bos_alt.png?raw=true" width="260" alt="klik 0,05 kule bos"> | <img src="https://github.com/sniperTurk/flutter-app/blob/db97bdba4fd720d745baf22206401f3e8de79dc4/latest/09_klik_seciniz_kaydet_kapali.png?raw=true" width="260" alt="Seciniz kaydet kapali"> |

- Görünen farklar: (2)'de Kaydet açık, çünkü Üst kule klik sayısı bugün de isteğe bağlı (bkz. Uç durumlar). (3)'te alt satır: "Kaydetmek için eksik: Dürbün: Klik değeri", Kaydet gri. Başka yerleşim, metin ya da kutu değişmedi.

## CI linkleri

- Tam test paketi (`test-diag.yml`, files=test), e88eeee üzerinde: [39018253828](https://github.com/sniperTurk/flutter-app/actions/runs/39018253828) → **success**.
  - Önceki iki koşu kendi test hatam yüzünden kaldı; ikisi de yalnız (f) testindeydi ve düzeltildi:
    - [39017008725](https://github.com/sniperTurk/flutter-app/actions/runs/39017008725): iki store kullanılmıştı.
    - [39017295057](https://github.com/sniperTurk/flutter-app/actions/runs/39017295057): iki ayrı profilin kimliği karşılaştırılıyordu. O koşuda kalan tek test buydu: +2288, −1.
- Analiz (`analyze-diag.yml`), e88eeee: [39018255380](https://github.com/sniperTurk/flutter-app/actions/runs/39018255380) → **success**.
- Biçim (`375209577`, one-off dart format fix): [39018256683](https://github.com/sniperTurk/flutter-app/actions/runs/39018256683) → success. Biçim değişikliği gerekmedi.
- iOS CI (`verify`, `dart-checks`, `wind-acceptance`): PR #380'in Checks sekmesinde, son commit üzerinde.
  - e88eeee üzerindeki [39018254692](https://github.com/sniperTurk/flutter-app/actions/runs/39018254692) koşusunda `wind-acceptance` success verdi. Ayrıca `dart-checks` içinde biçim ve statik analiz success verdi.
  - Bu rapor commit'i koşuyu yeniden başlatır. Son sonuç PR yorumunda yazılır. Yeşil görülmeden yeşil denmez.
- Simülatör (`sim-screens.yml`): [39017089375](https://github.com/sniperTurk/flutter-app/actions/runs/39017089375) → rc 0, 9 görüntü.
- Code Review + Security review: PR yorumunda.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01CBor7oM7rkEbX9ZE4uj1vR
