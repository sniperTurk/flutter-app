# TestFlight öncesi uçtan uca hesap denetimi — 2026-10-14c

## Özet

- **Denetlenen main:** `ea9c9e85062bb158d9e1a4b96d9e0cac216d81f8` (#313 birleşmesi, 22:55 İstanbul).
- **ATM-1: düzeldi.**
- **PRF-2: düzeldi.** (Bulgudaki tekrar adımı artık asıl profili değiştirmiyor.)
- **Yüksek bulgu: 1** (yeni: PRF-6).
- **Karar: TestFlight başlamamalı.** PRF-6 açık. #313'ten önce Kopyala ile yapılmış profillerde Hız Doğrulama, öbür profilin mühimmatını da değiştiriyor.

Not: "iOS TestFlight" iş akışı sahip hesabıyla 22:56'da elle başlatılmış (run 38627824249), yani bu denetim bitmeden. 23:06'da "success" ile bitti. Bu denetim onu başlatmadı ve durdurmadı. Uygulamanın test kullanıcılarına ulaşıp ulaşmadığına bakılmadı.

## Kapsam ve yöntem

- Tarih: 14.10.2026, İstanbul.
- PR #313 21:45'ten itibaren 5 dakikada bir REST ile izlendi. 22:55'te birleşti.
- Dal: `audit/testflight-2026-10-14c`, main `ea9c9e8`'den açıldı.
- Kapsam: 7eb1416'dan sonra birleşenler: #309, #311, #312, #313. Etkileşimler #307/#308 ve gizli bayraklarla birlikte bakıldı.
- `lib/` değişmedi. Yalnız rapor ve test eklendi; her düzeltme ayrı görev.
- Bağımsız kaynaklar:
  - US Standart Atmosfer 1976 / ICAO sabitleri ve ideal gaz yasasıyla Python'da elle hesap (`tools/test_denetim_2026_10_14c.py`).
  - Kod okuma ve uygulama içi widget testleri.
  - Hiçbir balistik uygulaması kullanılmadı.

## ATM-1 ve PRF-2 doğrulaması

| Bulgu | Ne yapıldı | Sonuç |
|---|---|---|
| ATM-1 | `test/audit_2026_10_14b/atm1_restart_solve_test.dart`: #310'un iki ATM-1 testi `skip` olmadan, artı #312'nin uç durumları. Tekrar adımı uçtan uca: kayıt (15 °C, nem %0, İrtifa 1500 m, Basınç boş) → açılış → kutular → çözücü → ekrandaki "Hava yoğunluğu" ve "Basınç irtifadan tahmin edildi." notu | CI'da geçti. Ekranda 1,0223 kg/m³ ve not var. Elle hesap: ISA 1500 m = 845,56 hPa, ρ = P/(R·T) = 1,0223. 900 hPa kayıtlı: 1,0881. Kayıt yok: deniz seviyesi |
| ATM-1 yan etkiler | Kod: `_loadShotSettings` içinde tek bir `_quietSolve()` var, yalnız kayıt varsa ve `mounted` denetiminden sonra çalışıyor. Ağ ve zamanlayıcı çağrısı yok. Kendi kaydetme işlemi (`save`) yeniden yükleme bildirimi göndermiyor, döngü yok. İlk otomatik hesap `_basis` doluysa tekrar çalışmıyor | Çift hesap yok (ikinci hesap ilkinin yerine geçiyor, üst üste eklenmiyor). Ek ağ isteği yok. Boş kayıtta davranış eskisiyle aynı |
| PRF-2 | `test/audit_2026_10_14b/prf2_kopyala_test.dart`: #310'un PRF-2 testi `skip` olmadan, artı #313'ün testleri (yeni kimlik, katalog kimliği aynı kalıyor, eski paylaşılan kayıt ilk Güncelle'de ayrılıyor, silme). Tekrar adımı: kopyada BC 0,1 → 0,12, Güncelle → asıl profilin çözücü girdileri | CI'da geçti: asıl profil BC 0,1 ile kalıyor; kaydı ve bütün çözücü girdileri aynı |
| PRF-2 birleşme | #313 kendi dalında #312 olmadan test edilmişti. Birleşmiş main'de (ikisi birlikte) bütün takım yeniden çalıştı | Başarılı (aşağıda CI) |

## Değişiklik başına tablo

| PR | Ne kontrol edildi | Bağımsız kaynak | Sonuç |
|---|---|---|---|
| #309 Profiller ⋯ menüsü | Düzenle/Kopyala/Sil her satırda. Etkin olmayan profilde Kopyala ve Sil. Silme onayı. Yedekle/Geri yükle `PROFILE_BACKUP_BUTTONS` arkasında; kod ve veri duruyor | Kod + widget testi (`kopyala_old_firearm_audit_test.dart`) | Doğru |
| #309 Ek mühimmat bilgileri | Barut katsayısı, Hız ölçüm sıcaklığı, Hıza göre BC ve Özel eğri yalnız yer değiştirdi. Anahtarlar (`profile-powder-coef`, `profile-powder-temp`, `ammo-band-*`, `ammo-curve`), denetimler ve kayıt aynı. Başlık PCP'de çıkmıyor, ateşlide çıkıyor | Diff + widget testi: eski elle girilmiş ateşli profil (0,8 / 20 °C, 3 bant) → Kopyala → kopyada BC değişti → barut değerleri ve 3 bant duruyor | Doğru. Hesap değişmedi |
| #311 Tüfek sırası | Marka, Model, Kalibre tam satır. Namlu çıkış hızı Sıfırlama mesafesinin yanında. Eksik listesi aynı sırada. Denetleyiciler (controller) aynı | Diff | Hesap girdisi değişmedi |
| #311 Retikül listesi | Yazılı dürbünde birim "Seçiniz" iken 5 düz retikülün hepsi. Seçili retikül listeden düşmüyor (çökme yok) | Kod | Doğru. Yalnız `SCOPE_LISTEDE_YOK` açıkken ya da dürbün listesi boşken erişilebilir |
| #312 ATM-1 | Yukarıda | ISA, ideal gaz | Düzeldi |
| #313 PRF-2 | Kopyala elle girilmiş kayıtları yeni kimlikle kopyalıyor, katalog kimliklerine dokunmuyor. Kişisel katalogda olmayan kimlik aynen kalıyor. Düzenleyici, başka profilin kullandığı kaydı yeni kimlikle yazıyor. Kaydı yalnız bu profil kullanıyorsa yerinde güncelliyor. Açılışta hiçbir kayıt değişmiyor ya da silinmiyor | Kod + #313 testleri + bu denetimin testleri | Doğru. **PRF-6:** ayrılmamış eski paylaşılan kayıtları Hız Doğrulama yerinde yazıyor |

Etkileşimler:
- **Eski profilin Kopyala'sı (#308 → #313):** elle girilmiş eski ateşli profil, ⋯ → Kopyala. Kopyanın çözücü girdileri asılla birebir aynı: hız, sıfır, nişan yüksekliği, birim, ayak, barut, kalibre, yiv, ağırlık, BC, model, 3 bant, klik. Kopya düzenlenince asıl profil ve kaydı aynı kaldı.
- **İki eski profil aynı kaydı paylaşırken etkin olmayanı kopyalamak:** kopya üç yeni kimlik alıyor. İki eski profil değişmiyor.
- **Boş alanlar ve varsayılanlar:**
  - Kayıtsız Hava Durumu: ATM-1 ek hesabı çalışmıyor.
  - Kopya profilin kayıtlı Pro/Hava ayarı yok; eskisi gibi boş ya da taşınan değerlerle açılıyor. Bu değişiklikte yeni bir şey yok.
- **Yer değiştiren alanlar:** #309 ve #311 hesap girdisine dokunmuyor. Kayıt anahtarları aynı.

Gizli bayraklar (`WIND_OBSERVATION`, `PRO_TUBE_PRESSURE`, `SCOPE_LISTEDE_YOK`, `RIFLE_LISTEDE_YOK`, `AMMO_BC_BANDS_TYPED`, `AMMO_LISTEDE_YOK`, `PCP_AMMO_BRAND`, `PROFILE_AMMO_LENGTH`, `PROFILE_BACKUP_BUTTONS`, `GOOGLE_MAPS_ENABLED`):
- Hepsi `bool.fromEnvironment` ile okunuyor ve varsayılan kapalı (Python koruması).
- Kapalı yol: widget testleri. Açık yol: koddan okundu; testler bayrak açamıyor.
  - `AMMO_BC_BANDS_TYPED` kapalı: elle girilmiş fişeğin kayıtlı bantları Kopyala'da ve düzenlemede korunuyor (test).
  - `PROFILE_AMMO_LENGTH` kapalı: Kopyala kaydı alanlarıyla aynen kopyalıyor, uzunluk dahil (#313 testi).
  - `PROFILE_BACKUP_BUTTONS` açık: #313'ten önce alınmış bir yedek, paylaşılan kimlikleri geri getirebilir. O zaman da PRF-6 geçerli.
  - `SCOPE_LISTEDE_YOK` açık: #311 retikül değişikliği (aşağıda not).
- `GOOGLE_MAPS_ENABLED` kodda kapalı. `ios-testflight.yml`, anahtar sırrı varsa derlemede açıyor (önceki raporla aynı).

API anahtarı:
- İzlenen dosyalarda `AIza…` yok (Python testi).
- Anahtar yalnız `ios-testflight.yml` içinde `secrets.GOOGLE_MAPS_IOS_API_KEY` olarak geçiyor.

## Bulgular

### PRF-6 — Yüksek: #313'ten önceki kopyalarda Hız Doğrulama öbür profilin mühimmatını da değiştiriyor

- **Yer:** `lib/features/tools/truing_screen.dart`, `_applyDrag` (yaklaşık 397–470, "Mühimmata kaydet") ve `_applyBc` (yaklaşık 484–550, "Mühimmata uygula"). İkisi de etkin profilin mühimmat kaydını aynı kimlikle yerinde yazıyor (`store.upsert({...entry, …})`).
- **Ne oluyor:**
  - #313 yeni kopyaların kayıt paylaşmasını önlüyor. Paylaşılan eski kaydı yalnız Profili Düzenle → Güncelle ayırıyor.
  - #313'ten önce Kopyala ile yapılmış ve sonra hiç düzenlenmemiş profiller aynı elle girilmiş mühimmat kaydını kullanmaya devam ediyor.
  - Bunlardan birinde Hız Doğrulama sonucu mühimmata kaydedilince öbür profil de sessizce aynı eğri ya da BC ile hesaplanıyor. Eski BC'si ve modeli kayboluyor.
- **Tekrar** (CI'da ölçüldü):
  1. Profil A ve B, aynı elle girilmiş ateşli mühimmatı paylaşsın (G7 0,243, 175 gr; #313 öncesi Kopyala).
  2. A etkinken Araçlar → Hız Doğrulama → Sürüklenme eğrisi → 500/700/900 m → Hesapla → Mühimmata kaydet → Kaydet.
  3. B'nin mühimmatı artık A'nın özel eğrisini taşıyor (beklenen: eğri yok, G7 0,243; çıkan: eğri var).
- **Etkisi:** B'nin uzak mesafe düşüşü ve rüzgâr sayıları değişiyor; B'nin kullanıcısı bir şey yapmadı. "Mühimmata uygula" (BC) için de aynı yol var (koddan okundu; test sürüklenme yolunu ölçüyor).
- **Kapsam:** yalnız #313'ten önce yapılmış ve hiç Güncellenmemiş kopyalarda, ya da böyle kopyaları içeren eski bir yedekten geri yüklemede. #313'ten sonraki kopyalarda olmuyor (koruma testi geçiyor).
- **Köken:** 237c14d'de de var (PRF-2 ile aynı kök). #313 düzenleyici yolunu kapattı, Hız Doğrulama yolunu kapatmadı. #313 raporu bunu "Yapılmayan" olarak yazmış.
- **Önerilen düzeltme (uygulanmadı):** Hız Doğrulama, mühimmat kaydı başka bir profilde de kullanılıyorsa kaydı yeni kimlikle yazsın ve etkin profili ona bağlasın (Profili Düzenle'deki `sharedRecordIds` kuralı). Başka bir seçenek: açılışta paylaşılan elle girilmiş kayıtları bir kez ayırmak. Hangisi, sahibin kararı.
- **Testler:** `test/audit_2026_10_14c/truing_shared_record_audit_test.dart`
  - `PRF-6: truing on a copy made before #313 leaves the other profile alone`: `skip: true // PRF-6`. `--run-skipped` ile CI'da düştü: "B got A's trued drag curve", Expected: false, Actual: true.
  - `guard: a copy with its own record (Kopyala since #313) …`: geçiyor.

### Yeni orta ya da düşük bulgu

Yok.

### Açık (önceki rapor, PR #310)

Yeni değişiklikler bunları kötüleştirmedi. PRF-1'e (katalog dürbününde Güncelle yan yolu siliyor) özellikle bakıldı:
- #313'ün ayırma yolu da aynı alanları yazıyor; değişiklik yok.
- Kopyala kaydı bütün alanlarıyla kopyalıyor; yan yol korunuyor.

| Önem | Bulgular |
|---|---|
| Orta | KUL-1, KUL-2, RUZ-1, RUZ-2, RUZ-3 (şüphe), MUH-1, MUH-2, PRF-1, PRF-3, PRF-4 — açık (önceki rapor) |
| Düşük | KUL-3, ATM-2, ATM-3, MUH-3, MUH-4, MUH-5, PRF-5 — açık (önceki rapor) |

PR #310 hâlâ taslak; bu bulguların `skip`'li testleri main'de değil, `audit/testflight-2026-10-14b` dalında.

## Not edilen ama bulgu sayılmayanlar

- **CLAUDE.md ile çelişki:** CLAUDE.md, Kalibre dahil her satırda iki kutu ister ("Namlu çıkış hızı | Kalibre share a row"). #311, sahibin 14.10.2026 18:56–18:58 kararıyla Kalibre'yi tek başına tam satıra aldı. Kural metni güncellenmemiş; sahibin teyidi iyi olur. Hesaba etkisi yok.
- **#311, retikül listesi** (yalnız `SCOPE_LISTEDE_YOK` açıkken):
  - Birim seçilmeden MOA desenli bir retikül seçilip sonra MRAD seçilirse, retikül seçili kalıyor.
  - Çökme yok, sayı değişmiyor. Gerçekte MOA retikül + MRAD kule de var.
- **Artık kayıtlar:**
  - Paylaşılan bir kayıt Güncelle ile ayrılınca eski kayıt yerinde kalıyor (öbür profil kullanıyor).
  - Profil silinince kayıtları silinmiyor. Bu davranış eskiden de vardı.
  - Veri kaybı yok; yalnız kişisel katalog büyüyor.
- **Uyarı satırı:** CI günlüğünde iki dosyada (`truing_drag_band_test.dart` ve bu denetimin testi) Doğrulama mod listesine dokunuşta bir `tap` uyarı yığını var. Testler geçiyor; mod değişiyor.

## Testler

Yeni dosyalar:
- `test/audit_2026_10_14c/truing_shared_record_audit_test.dart`: PRF-6 (`skip`), koruma testi (geçiyor).
- `test/audit_2026_10_14c/kopyala_old_firearm_audit_test.dart`: #309 ⋯ menüsü × #313 × eski ateşli profil × `AMMO_BC_BANDS_TYPED` kapalı. İki koruma testi, ikisi de geçiyor.
- `tools/test_denetim_2026_10_14c.py`, 12 test:
  - ISA ve yoğunluk elle hesabı (845,56 hPa; 1,0223 / 1,2250 / 1,0881 kg/m³).
  - ATM-1 düzeltmesinin korumaları: tek hesap, ağ ve zamanlayıcı yok, kayıt döngüsü yok.
  - ATM-1 ve PRF-2 Dart testlerinde `skip` olmaması.
  - Düzenleyicinin paylaşılan kaydın üstüne yazmaması; Kopyala'nın katalog kimliğini koruması.
  - 10 bayrağın varsayılan kapalı olması; anahtar taraması.

Yerel:
- `python3 tools/offline_dart_lint.py`: PASS, 349 Dart dosyası, 0 sorun.
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 760 test, OK.
- Flutter SDK bu ortamda yok; Dart testleri yalnız CI'da çalıştı.

## CI

Hepsi `audit/testflight-2026-10-14c` dalında, commit 97df4ed (main ea9c9e8 + bu denetimin testleri).

| İş | Sonuç | Bağlantı |
|---|---|---|
| Dart format düzeltme (format-fix) | başarılı; değişiklik commit'i gerekmedi | https://github.com/sniperTurk/flutter-app/actions/runs/38627914643 |
| `flutter analyze --fatal-infos --fatal-warnings` (analyze-diag) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38627928216 |
| Bütün test takımı, `files=test` (test-diag) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38628124729 |
| `test/audit_2026_10_14b` + `test/audit_2026_10_14c` (ATM-1, PRF-2 skip'siz; PRF-6 skip'li) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38627918835 |
| PRF-6 kanıtı (`--run-skipped`) | beklendiği gibi başarısız: PRF-6 düştü, koruma testi geçti | https://github.com/sniperTurk/flutter-app/actions/runs/38627923510 |

- PR #314'ün iOS CI turu (27a743b, rapor commit'i; kod 97df4ed ile aynı): `verify`, `dart-checks`, `wind-acceptance` başarılı. `ios-simulator` atlandı (skipped), yani Simulator derlemesi çalışmadı. https://github.com/sniperTurk/flutter-app/actions/runs/38629503147
- Simulator ve App Store çalıştırılmadı; geçti denmiyor.
- TestFlight bu denetimde çalıştırılmadı. Sahip hesabının 22:56'da başlattığı TestFlight iş akışı yukarıda not edildi.

## Yapılmayanlar

- `lib/` içinde düzeltme yok. PRF-6 ayrı görev.
- Birleştirme yok; PR taslak.
- TestFlight'ı başlatma ya da durdurma yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
