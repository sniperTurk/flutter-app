# TestFlight öncesi hesap denetimi — 15.10.2026 (c)

## Özet

- **Denetlenen sürüm:** main `e7b29bf` (#357 birleşmiş hâli). Dal `audit/testflight-2026-10-15c` bu sha'dan açıldı.
- **Yüksek bulgu: 1** (KUL-10).
- **Karar: TestFlight başlamamalı.** KUL-10 açık. Bu hata yeni değil, önceki TestFlight'ta da vardı. Ama yüksek bulgu açıkken TestFlight başlamaz.
- Yeni bulgular:
  - 1 yüksek: KUL-10.
  - 4 orta: HDF-4, HDF-5, PRF-11, UST-1.
  - 7 düşük: HDF-3, PRF-12, UST-2, UST-3, DGM-1, DGM-2, RUZ-4.
- İstenen 7 PR'da yanlış sayı bulunmadı.
  - PRF-7 ve PRF-8 her kalibrede ve iki seçim sırasında da düzelmiş.
  - Hedef sonuç satırı çözücünün klik, MOA ve MRAD değerlerini gösteriyor.
  - Profil kartındaki özet satırı kayıtla aynı.
  - Üst çubuktaki profil düğmesi bütün sekmeleri yeniden hesaplatıyor.
  - Eski tema kaydı uygulamayı bozmuyor; uygulama koyu açılıyor.
- `lib/` değişmedi. Depoda API anahtarı yok. TestFlight başlatılmadı.

## Kapsam ve yöntem

- Tarih: 16.10.2026, İstanbul saati 13:40–16:30.
- Önceki tam denetim (`denetim_testflight_2026_10_15b.md`) yalnız `4c51b77`'yi kapsıyordu. CLAUDE.md, önceki TestFlight'tan sonra birleşen bütün değişikliklerin denetlenmesini istiyor. Bu yüzden `4c51b77..e7b29bf` aralığındaki bütün PR'lara bakıldı.
- **Derin denetim** istenen 7 PR'a yapıldı:
  - #327 (`fix/prf7-tur-kalibre`)
  - #326 (`fix/klv1-rehber`)
  - #329 (`design/profiller-ustte`)
  - #331 (`design/ust-cubuk`)
  - #330 (`design/hedef-sonuc-ustte`)
  - #332 (`design/yan-kule-kucuk`)
  - #328 (`design/ikonsuz-dugmeler`)
- **Sayı yolu taraması** aralıktaki öbür PR'lara yapıldı. Bunlar önceki raporda "düzeldi" diye yazılmıştı ama baştan sona denetlenmemişti: #335, #336, #337, #338, #342, #343, #344, #345, #346, #347, #349, #350, #351, #352, #353, #355, #356, #357, #358, #228, #322, #339. Belge ve CI PR'larına da bakıldı (#334, #340).
- **Bağımsız kaynaklar:**
  - Tanımlardan birim sabitleri: 1 in = 25,4 mm, 1 yd = 0,9144 m, 1 gr = 0,06479891 g, MOA = π/10800 rad.
  - ICAO standart atmosfer.
  - `tools/formula_reference.py` (kendi çözücümüz).
  - Python'da elle hesap.
  - Depoda kaynağı yazılı üretici verisi.
  - Hiçbir balistik uygulaması kullanılmadı.
- Bu ortamda Flutter SDK yok. Dart testleri yalnız CI'da çalıştı.

## PR başına tablo

| PR | Ne kontrol edildi | Bağımsız kaynak | Sonuç |
|---|---|---|---|
| #327 PRF-7/PRF-8 | **Tür seçimi:** Kalibre'yi yalnız Tür gerçekten değişince sıfırlıyor mu? **Ateşli silah:** 168 kalibrenin hepsi, iki sırada da (Kalibre→Tür ve Tür→Kalibre). Marka/Model yolu: 149 fişek × 2. Fabrika fişeği önce: 131 × 2. El dolumu önce: 66 çap × 2. "Fişeğim listede yok": 36 çap. **PCP:** 10 çap. **Kayıt → çözücü:** 4924 tüfek satırı ve 1813 fabrika fişeğinin çapı kendi kalibresininkiyle aynı mı? | Dart verisi Python'da ayrıştırıldı, kural elle yazıldı | Hepsi doğru. Örnek: Tür'den önce .300 Win Mag seçilip kaydedildi → tüfek ve mühimmat 7,82 mm; 2650 fps = 807,72 m/s; 100 yd = 91,44 m. Ayrı bulgu: **PRF-11** (fişek adı kaydedilmiyor) |
| #329 özet satırı | Karttaki satır, kayıtlı profil ve çözücünün okuduğu değer | Birim tanımları, elle hesap | Aynı. 274,32 m → "300,0 yd"; 800 m/s → "2625 fps". Birim alanı olmayan eski profil metre olarak yükleniyor: "sıfır 100 m, 2700 fps, BC 0,475 G1". MOA ve MRAD profilinde satır aynı. BC'siz PCP slug'da BC kısmı yok. **PRF-12** |
| #330 Hedef sonuç satırı | Satır, çözücünün istediği değer mi? En yakın klik, tek ondalık, yukarı/aşağı ve sağ/sol yönü, "rüzgâr yok". Pro'dan otomatik kurma, "Kule:" satırı, DOPE ve "Kuleleri kur" ile uyum | `formula_reference.py`, elle hesap | **MRAD, 620 m:** 5,8948 mrad → 59 klik · 5,9 MRAD yukarı; −1,608 → 16 klik · 1,6 MRAD sol. DOPE'taki 5,89 da aynı klikleri veriyor. **MOA ¼, 620 m:** 20,2648 MOA → 81 klik. **Yard profil, 800 yd:** 7,9127 → 79 klik; −2,0124 → 20 klik sol. **1/8 MOA, 450 m:** 11,735 MOA → 94 klik; satır ve kule aynı. **Boş/sıfır:** 0 klik · 0,0. Ayrı bulgular: **HDF-3, HDF-4, HDF-5** |
| #332 yan kule 66 × 180 | Kutu çizgide ortalı mı, işaret kutunun içinde mi? Her ok dokunuşu bir klik mi? | Geometri: sütun 296 = 180 + 2·(30+28) | 320 pt ve 390 pt ekranda, 1/8 MOA dürbünle sıfır çizgide. Her ok tam bir klik |
| #331 üst çubuk | Profil değişince bütün sekmeler yeniden hesaplanıyor mu? Eski tema kaydı | Kod izleme, uçtan uca widget testi | Hava, Pro ve Hedef tek çalışma alanı. Bu alan profil, birim ve değerlere bağlı bir anahtarla kuruluyor; profil değişince baştan kuruluyor, eski sayı kalmıyor. Test: MRAD/metre profilde Hedef'te kuleler kurulu → üst çubuktan MOA/yard profile geçildi → kuleler 0/0, birim MOA, klik 0,25. Yukarı değeri, o profil tek başına açılınca çıkan değerle aynı. Eski `theme.dark` kaydı okunmuyor, uygulama koyu. **UST-1, UST-2, UST-3** |
| #328 yazılı düğmeler | 7 düğmenin anahtarı ve gittiği yer değişti mi? Eski adlar | Kod araması, mevcut testler | Gezinme aynı. Eski "Pro Ayarlara Geç" `lib/` içinde yok. **DGM-2** |
| #326, #343 Rehber | Rehberdeki adlar ile ekrandaki düğme adları | Widget testi, kaynak taraması | "Kuleleri kur", "Kuleleri sıfırla", "Kule sınırına kuruldu" ve "Profil ekle" doğru. **DGM-1** |
| #337 KUL-1, #349 HDF-2 | Kule yolu sınırı, okların dokunma alanı | Elle hesap | 1/8 MOA, 13,09 mrad yol: yukarı 145, aşağı 215 klik. Dokunma alanı 44 pt |
| #352 klik sesi | Sayı değişiyor mu? Testte çökme olur mu? | Kod, test | 6 dokunuş = 6 ses, hiçbir sayı değişmiyor. Varsayılanı sessiz, ses hataları yakalanıyor |
| #357 HDF-1 | `WIND_GUIDE_LINK` silindi mi? | Kaynak taraması | `lib/`, `tools/` ve `.github/` içinde yok. Eski atlanan testler artık atlanmadan çalışıyor |
| #335 RUZ-1/RUZ-2 | Rüzgârın değiştiği bütün yollar | Elle hesap | Düzelmiş: 5,0 × 1,5 = 7,5; "5" ile "5.0" değişiklik sayılmıyor. Eski RUZ testleri atlanmadan çalışıyor. Yalnız gizli bayrak yolu açık: **RUZ-4** |
| RUZ-3 | Gerçek Elevation isteği | maps-check çalışması 38785522797 | İstek uygulamayla aynı; Ankara 869 m. **RUZ-3 kapandı** |
| #338 KUL-2 | Hız Doğrulama'da PCP tablo hızı | `formula_reference.py` | Hız modu doğru. BC ve Sürüklenme eğrisi modu hâlâ Profil hızıyla çözüyor: **KUL-10** |
| #345 MUH-1/2/3/5 | BC modeli değişimi, FA007, eski 'ga' kaydı | Depodaki üretici verisi (aguilaammo.com: FA007 1130 fps) | FA007 = 1130 fps. Lapua 69 gr Scenar: G1 0,341 / G7 0,171. Eski 'ga' ve 'GA', G1 olarak yükleniyor ve BC'si korunuyor |
| #355 mühimmat sıcaklığı | Barut sıcaklığı kuralı | Elle hesap (2650 fps, %1,5 / 15 °C, T0 21 °C) | Hava 5 °C, mühimmat kutusu boş → 2607,60 fps. Mühimmat 30 °C → 2673,85 fps. İki kutu boş (15 °C) → 2634,10 fps. Kutu taşıma, sayı aynı |
| #356 tek irtifa kutusu | İrtifa → basınç → yoğunluk; boş kutu; eski kayıt | ICAO | 1500 m → 845,56 hPa. Boş kutu → 0 m / 1013,25 hPa. Eski kayıtlar yükleniyor |
| #344, #346, #350, #351, #322 | Sayı değişiyor mu? Birim ekleri | Birim tanımları | "Güncelle" dokunmadan basılınca sayı değişmiyor. Kutu birimleri, kutunun okunduğu birimle aynı |
| #228, #353 Garmin | Saate giden sayı ekrandaki sayıyla aynı mı? | Kod, widget testi | Aynı. Köprü TestFlight iş akışında yok |
| #336, #342, #339, #347, #358 | Metin, sayaç, yazı tipi, ikon, yerleşim | Kod | Hiçbir sayı değişmiyor |

### Kapsam güncellemesi (16.10.2026, 17:37)

Ana oturum kapsamı genişletti. İstenen: son TestFlight'tan (run 109, main `4c51b77`) sonra birleşen bütün PR'lar, yani `merged_at` 2026-10-15T16:58Z sonrası. Liste GitHub'dan yeniden çekildi.

- **Liste:** 32 PR. #322, #326–#340, #342–#347, #349–#353, #355–#358 ve #228.
- **Kapsam:** #333 denetim raporunun kendisi. Kalan 31 PR'ın hepsi yukarıdaki tabloda var.
- **main:** `e7b29bf`'den sonra değişmedi.

Ayrıca istenen noktalara yeniden bakıldı:

- **Garmin köprüsü (#228):**
  - Köprüsüz derlemede `deviceCount()` boş dönüyor ve "Garmin saati" satırı hiç çizilmiyor (`garmin_pair_tile.dart`).
  - Saat kanalı yoksa gönderim sessizce düşüyor (`MissingPluginException` yakalanıyor).
  - Apple Watch kanalı Garmin kanalından etkilenmiyor: ikisinden biri teslim alırsa "gönderildi" sayılıyor.
- **Kule klik sesi (#352):**
  - Yeni bağımlılık: `audioplayers` 6.4.0. pubspec.lock'ta sha256 ile kayıtlı.
  - iOS ses oturumu "ambient": sessiz düğmesine uyuyor, kullanıcının müziğini kesmiyor.
  - Ses hataları yakalanıyor. Ses hiçbir sayıyı değiştirmiyor (test).
  - Bu denetimde iOS Simulator derlemesi çalışmadı (ios-simulator işi atlandı). Yeni yerel eklentinin iOS'ta derlendiği burada kanıtlanmadı.
- **Kutulardaki birimler (#346):** her birim, kutunun okunduğu birimle aynı.
- **Tek İrtifa kutusu (#356):** önce harita, yoksa telefon. Boş kutu 0 m / 1013,25 hPa veriyor.
- **Mühimmat sıcaklığı bölümü (#355):** yalnız yer değişti, sayılar aynı.
- **BC ve kule düzeltmeleri:** #337, #338, #344, #345, #349 tabloda. #338'in bıraktığı yol KUL-10.
- **Pro satırı ve ⓘ (#358):** ⓘ dokunma alanı 44 × 44 pt (`proInfoTarget`). Sayı değişmiyor.

Bu genişletmede yeni bulgu çıkmadı. Karar aynı: KUL-10 açık, TestFlight başlamamalı.

### Gizli bayraklar

- 16 ortam okuması var; sayı `4c51b77` ile aynı.
  - `WIND_GUIDE_LINK` silindi (−1).
  - #338 ikinci bir `PRO_TUBE_PRESSURE` okuması ekledi (+1).
- Bütün `bool` bayraklar varsayılan kapalı.
- TestFlight derlemesi yalnız `METNO_CONTACT`, `GOOGLE_MAPS_ENABLED` ve `GOOGLE_MAPS_IOS_API_KEY` veriyor.
- Not: `WIND_OBSERVATION` ve `PRO_TUBE_PRESSURE` gibi bazı özellikler hâlâ bayrak arkasında. Bu, 15.10 kuralına ("kaldırılan özellik silinir") aykırı. Bu aralıktan önce de vardı; bulgu sayılmadı.

### API anahtarı

- Tarananlar: izlenen dosyalar, `4c51b77..e7b29bf` aralığındaki bütün commit'ler ve aralık dışındaki dallar.
- Google, Anthropic, OpenAI, GitHub, AWS anahtarı ya da özel anahtar bulunmadı.
- İmza dosyası (.p8, .p12, .mobileprovision) yok.
- maps-check iş akışı:
  - Yalnız elle çalışıyor.
  - İzni yalnız okuma (`contents: read`).
  - Anahtar yalnız `secrets` üzerinden geliyor ve yazdırılmıyor.

## Bulgular

| Kimlik | Önem | Ne | Nerede |
|---|---|---|---|
| **KUL-10** | **Yüksek** | Hız Doğrulama'da **BC** ya da **Sürüklenme eğrisi** modu, regülatörsüz PCP'de (tablo kullanılabilirken) Profil hızıyla çözüyor. Hedef ise aynı tüfeği tablo hızıyla sıfırlıyor ve atıyor. Bu yüzden bulunan BC yanlış oluyor. Örnek: tablo 120 bar → 255, 200 bar → 270 m/s; tüp 120 bar; profil 270 m/s; 18 gr, G1 0,031; sıfır 30 m; doğrulama 100 m'de. Bulunan BC 0,0252 (−%18,6). Uygulanınca Hedef doğrulama mesafesinde +0,83 mrad (8 cm) şaşıyor. Profil 260 m/s olunca BC −%7,4 değişiyor; sayfanın "%10" uyarısı çıkmıyor ve hata +0,28 mrad. Ayar basıncının altındaki regülatörlü PCP'de de aynı. Hata yeni değil: önceki TestFlight'ta da vardı. #338 yalnız hız modunu düzeltti; bu yolu bilerek bıraktı | `lib/features/tools/truing_screen.dart:308-310` (çözüm `p.muzzleVelocityMps * f` ile kuruluyor), `_applyBc` (583), `_applyDrag` (442) |
| HDF-4 | Orta | Kule yolunun ötesinde sonuç satırı kulenin kuramayacağı klik sayısını gösteriyor, satırda uyarı yok. Örnek: 1/8 MOA dürbün, 620 m → "162 klik". "Kuleleri kur" 145 klikte duruyor ("Kule sınırına kuruldu"). Uyarı yalnız nişangâh kartının altında | `scope_results.dart:125` (sınır yok), `scope_turrets.dart:21-22` (sınır var) |
| HDF-5 | Orta | BC'siz katalog saçması ya da slug'da (ör. FX saçmaları) hesap boşlukta yapılıyor, rüzgâr hesaba girmiyor. 4 m/s rüzgâr girilince en üstteki satır "Yan kule 0 klik · 0,0 MRAD" diyor. "KİLİTLİ" uyarısı yalnız aşağıda | `scope_results.dart:128`, `hedef_view.dart:166`, `ballistics_screen.dart:3006` |
| PRF-11 | Orta | Seçilen fişek adı kaydedilmiyor. "Profili Düzenle" fişeği çaptan (listedeki tüfekte çap ve yiv oranından) tahmin ediyor. Örnek: Anschütz 1782 .300 Win Mag, .30-06 olarak geri geliyor. Kayıtlı fabrika fişeği Model listesinde çıkmıyor ve MUH-1 koruması onu bulamıyor. Kullanıcı sonra BC modelini G1'den G7'ye çevirirse 0,425 kutuda kalıyor ve G7 olarak kaydediliyor. Dokunmadan "Güncelle" sayıları değiştirmiyor. Kullanıcı işlemi gerektiği için orta | `profile_editor.dart:1186-1202`, `:436-482`; `profile_editor_rifle.dart:235-253`; `profile_editor_ammo.dart:372-388` |
| UST-1 | Orta | Açılan profil listesi düğme kadar dar. Düğme de yalnız aktif profilin adı kadar geniş. Aktif ad kısaysa öbür profil adları "…" ile kesiliyor. Benzer adlar birbirinden ayrılamıyor. Sayı etkilenmiyor | `home_screen.dart:546-566`, `:610-620` |
| HDF-3 | Düşük | Yön kelimesi klik sayısına değil, tek ondalık yazıya bakıyor. 0,05 mrad dürbünde "1 klik · 0,0 MRAD" yönsüz çıkıyor. ¼ MOA dürbünde "0 klik · 0,1 MOA yukarı" çıkıyor | `scope_results.dart:114-119` |
| PRF-12 | Düşük | Özel sürüklenme eğrisi kartta ve "BC / model" kutusunda kesit yoğunluğu ile "G1" diye görünüyor. Örnek: "BC 0,2637508912160438 G1". Yalnız gösterim; çözücü eğriyi kullanıyor | `profiles_screen.dart:882-899`, `profile_summary.dart:135-136, 244-250` |
| UST-2 | Düşük | Hedef açıkken katalogda bulunmayan bir profile geçilince saate "Çözüm yok" gitmiyor. Saat 2 dakika boyunca eski profilin kliklerini gösteriyor | `ballistics_screen.dart:2141` (`dispose`), `:2900` (`_withdrawWatch`) |
| UST-3 | Düşük | Katalog açılış hatası ekranı hâlâ açık temayla çiziliyor ve telefonun ayarına uyuyor. Telefon açık moddaysa bu ekran açık görünüyor | `main.dart:84-90` |
| DGM-1 | Düşük | Rehber 1. adım 'Profil sayfasında "Profil oluştur"a dokun' diyor. İlk açılışta Profil sayfasındaki düğmenin adı "İlk profilimi oluştur" | `usage_guide_content.dart:35-37`, `empty_states.dart:166` |
| DGM-2 | Düşük | `MenzilPrimaryButton`'ın simgeli düzeni (`iconLead`) artık hiçbir yerde kullanılmıyor ama silinmemiş. Bu, "kullanılmayan kod silinir" kuralına aykırı | `menzil_widgets.dart:2228-2301` |
| RUZ-4 | Düşük | Gizli `WIND_OBSERVATION` bayrağı açılınca: Rüzgâr gözlemi rüzgârı yazıyor ama eski "En çok rüzgâr" değerini boşaltmıyor. TestFlight'ta bayrak kapalı | `ballistics_screen.dart:~689-706` |

Bulgu sayılmayan notlar:

- Özet satırı metre cinsinden sıfırı tam sayıya yuvarlıyor (27,5 m → "28 m"). Editör 27,5 gösteriyor.
- Eski kayıtta hem harita hem telefon irtifası varsa artık harita değeri kullanılıyor. Bu, sahibin kararı (`docs/reports/tek_irtifa.md`). Değer kutuda görünüyor.
- `home_screen.dart:680-701` arasında hiç çalışmayan eski "Profil oluştur" dalı var.
- `menzil_widgets.dart:142-144` yorumunda hâlâ tema düğmesinden söz ediliyor.

### Önceki bulguların durumu (main `e7b29bf`)

- **Düzelmiş, testleri atlanmadan çalışıyor:**
  - RUZ-1, RUZ-2 (#335)
  - HDF-1 / FLG-1 (#357)
  - HDF-2 (#349)
  - KUL-1, KUL-2
  - MUH-1, MUH-2, MUH-3, MUH-5
  - PRF-7, PRF-8, PRF-10 (#327)
- **Kapandı:** RUZ-3. Gerçek istek maps-check ile doğrulandı.
- **Hâlâ açık, testleri atlanıyor:**
  - PRF-9 (orta)
  - KUL-3, MUH-4, PRE-1 (düşük)
  - 14 raporundaki F4
- Bu denetimde hiçbir testin `skip`'i kaldırılmadı. Düzelmiş bulguların testleri zaten atlanmıyordu.

## Testler

`test/audit_2026_10_15c/`:
- **`profil_audit_test.dart`** — yaklaşık 690 test (döngülerle).
  - PRF-7/PRF-8: bütün kalibreler, iki sıra.
  - Özet satırı.
  - Uçtan uca yeni profil.
  - Atlanan: PRF-11 (3 test), PRF-12.
- **`hedef_audit_test.dart`** — 14 test.
  - Sonuç satırı: MRAD, MOA, yard, 1/8 MOA, boş/sıfır.
  - Yan kule geometrisi ve oklar.
  - KUL-1 yolu; klik sesi sayı değiştirmiyor.
  - Atlanan: HDF-3, HDF-4, HDF-5.
- **`ust_cubuk_audit_test.dart`** — 9 test.
  - Üst çubuktan profil değişimi uçtan uca.
  - Tema kodu taraması, rehber düğme adları, ilk açılış.
  - Atlanan: UST-1, UST-2, UST-3, DGM-1, DGM-2.
- **`diger_audit_test.dart`** — 7 test.
  - KUL-10 elle hesap, `WIND_OBSERVATION` varsayılan kapalı, #355 barut değerleri, Garmin = Hedef satırı.
  - Atlanan: KUL-10, RUZ-4.

Python (`tools/`):
- Elle hesap: `denetim_2026_10_15c_profil.py`, `_hedef.py`, `_ust.py`, `_diger.py`.
- Testleri: `test_denetim_2026_10_15c_*.py`. `_diger`, anahtar taramasını ve bayrak sayımını da içeriyor.

Atlanan testlerde gerekçe biçimi:
- `test`: `skip: '<kimlik>: <neden>'`
- `testWidgets`: `skip: true` ve aynı satırda `// <kimlik>: <neden>`

Atlanan testlerin `skip`'i kaldırılınca gerçekten düştüğü yalnız Python'da denendi (KUL-10, RUZ-4). Dart'ta CI'da ayrıca denenmedi.

Yerel:
- `python3 tools/offline_dart_lint.py` → 410 Dart dosyası, 0 sorun.
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 991 test başarılı, 6 atlandı.

## CI

| Ne | Sonuç | Bağlantı |
|---|---|---|
| dart format (tek seferlik) | başarılı; biçim commit'i geldi (`581757c`) | https://github.com/sniperTurk/flutter-app/actions/runs/38906405024 |
| `flutter test test/audit_2026_10_15c` (`92bdf1b`) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38906396826 |
| analyze (`92bdf1b`) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38906401269 |
| `flutter test test` (bütün testler, `581757c`) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38907663277 |
| analyze (`581757c`) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38907666763 |
| PR #363 iOS CI (`80d6372`): verify, dart-checks, wind-acceptance | başarılı (ios-simulator atlandı) | https://github.com/sniperTurk/flutter-app/actions/runs/38910197449 |

TestFlight, Simulator ve App Store çalıştırılmadı.

---
_Generated by [Claude Code](https://claude.ai/code)_
