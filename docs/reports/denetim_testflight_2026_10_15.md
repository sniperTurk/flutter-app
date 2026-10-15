# TestFlight öncesi hesap denetimi — 15.10.2026

## Özet

- **Denetlenen sürüm:** main `d86dfff` (PR #315 birleşmiş hâli).
- **PRF-6: düzeldi.** Paylaşılan elle girilmiş mühimmatta Hız Doğrulama artık öbür profili değiştirmiyor; hem "Mühimmata kaydet" (sürüklenme eğrisi) hem "Mühimmata uygula" (BC) için CI'da ölçüldü.
- **Yüksek bulgu: 0.** Yeni orta ya da düşük bulgu da yok.
- **Karar: TestFlight başlayabilir** (bu denetim açısından; açık yüksek bulgu yok). Bu denetim TestFlight başlatmadı.

## Kapsam ve yöntem

- Tarih: 15.10.2026, İstanbul saati 08:13–08:55.
- Dal: `audit/testflight-2026-10-15`, main `d86dfff`'den açıldı. `lib/` değişmedi; yalnız test, Python elle hesap ve bu rapor eklendi.
- Önceki TestFlight: main `ea9c9e8` (run 38627824249). O zamandan beri birleşen tek değişiklik: **#315 (PRF-6)**.
- Bağımsız kaynak: `tools/formula_reference.py` (yayımlanmış G7 tablosu, CIPM-2007 hava yoğunluğu, dünya ekseninde Dormand–Prince çözüm). Hiçbir balistik uygulaması kullanılmadı.
- Bu ortamda Flutter SDK indirilemedi (motor indirmesi 403). Dart testleri yalnız CI'da çalıştı. Python takımı yerelde çalıştı.

## 1. PRF-6 doğrulaması

| Ne | Nasıl | Sonuç |
|---|---|---|
| `test/audit_2026_10_14c/truing_shared_record_audit_test.dart` PRF-6 testi | main'de `skip` yok; bütün takımla CI'da çalıştı | Geçti |
| 14c raporundaki tekrar adımı, "Mühimmata kaydet" (eğri) | A ve B aynı elle girilmiş mühimmatı (G7 0,243, 175 gr) paylaşıyor; A'da 500/700/900 m eğri doğrulama → Kaydet | B hâlâ G7 0,243, eğri yok. A yeni kayda bağlı, eğrisi var |
| Aynı tekrar, "Mühimmata uygula" (BC) | Yeni test: `PRF-6 BC: …` (800 m, 9,84 mrad) | B G7 0,243 ile kaldı; eski kayıt bayt bayt aynı; A yeni kimlikli kayda bağlandı |

## 2. Paylaşılmayan kayıt ve uçtan uca hesap

Senaryo: .308, 175 gr, 790 m/s, sıfır 100 m, nişan yüksekliği 45 mm, kayıtlı G7 BC 0,243. Hava: 15 °C, 1013,25 hPa, nem %50. Atıcı 800 m'de grubu 9,84 mrad ile ortaya getiriyor.

Elle hesap (`tools/denetim_2026_10_15.py`, bağımsız çözücü):
- G7 0,243 ile 800 m düzeltmesi: 9,27 mrad.
- 9,84 mrad, G7 0,225 için gereken düzeltme (2 basamağa yuvarlanmış).
- Bu gözlemi veren BC (ikiye bölme ile): **0,2249**.

Uygulamada ölçülen zincir (yeni test `unshared record: …`, CI'da geçti):

| Adım | Beklenen | Sonuç |
|---|---|---|
| Kullanıcı girdisi | 800 m, 9,84 mrad, BC modu, Uygula | — |
| Kayıtlı değer | Aynı kimlik, ek kayıt yok, yalnız `bc` değişmiş | Öyle. BC 0,2249'a %1,5 içinde |
| Çözücü girdisi | Profilden çözülen mühimmat: G7, kayıtlı BC | Öyle |
| Çözücü sonucu | 800 m'de 9,84 mrad (±0,01) | Geçti |
| Hedef sayısı | Hedef → DOPE, 800 m satırı "Yükseklik MRAD" 9,84 (±0,02) | Geçti |

İkinci doğrulama (yeni test `second truing after the split …`): ayrılmış kayıt artık yalnız A'nın; ikinci doğrulama onu yerinde güncelliyor. Kayıt sayısı artmıyor (tüfek, eski mühimmat, yeni mühimmat). B eski kayda bağlı kalıyor. Hiçbir kayıt silinmiyor.

## 3. Etkileşimler (#312, #313), katalog, veri kaybı

- **#312 (açılışta kayıtlı Hava ile hesap):** Hava ve Pro ayarları profil kimliğine bağlı. #315 profil kimliğini değiştirmiyor, yalnız mühimmat kimliğini. Kayıtlı hava aynen uygulanıyor (kod). Hedef sayfası profilin mühimmat kimliğine göre yeniden kuruluyor; Araçlar'dan dönünce profiller ve kişisel katalog yeniden yükleniyor (`home_screen.dart` `_load`). Testte Hedef, kaydedilen profille açıldı ve doğrulanmış BC'yi kullandı.
- **#313 (Kopyala):** Yeni kayıt `manual_ammo_…` kimlikli, elle girilmiş. Kopyala onu da yeni kimlikle kopyalıyor (kod: `_copyPersonalRecords`). Profili Düzenle ve Hız Doğrulama aynı kuralı (`sharedRecordIdsOf`) kullanıyor.
- **Katalog kayıtları:** iki yolda da `ammo.userEntered` engeli aynen duruyor; katalog mühimmatına hiçbir şey yazılmıyor (kod). BC'li ateşli katalog mühimmatı olmadığından arayüzden ölçülemedi (#315 raporuyla aynı not).
- **Veri kaybı:** `_withAmmunition` profilin 16 alanının hepsini taşıyor (`RifleProfile` alanlarıyla tek tek karşılaştırıldı). Mühimmat kimliğine bağlı başka kayıt (kronograf, Pro ayarları vb.) yok (kod araması). Eski kayıt silinmiyor ve değişmiyor (test).
- **Gizli bayraklar:** #315 bayrak eklemiyor, bayraklı yola dokunmuyor. `PROFILE_BACKUP_BUTTONS` açıkken eski yedekten gelen paylaşılan kimliklerde de aynı kural çalışıyor (kod).

## 4. API anahtarı

- İzlenen dosyalarda `AIza…` biçiminde anahtar yok (yeni Python testi `tools/test_denetim_2026_10_15.py`, ayrıca `git grep`).
- #315 farkında anahtar ya da gizli değer yok.
- Anahtar yalnız `ios-testflight.yml` içinde `secrets.GOOGLE_MAPS_IOS_API_KEY` olarak geçiyor.

## Bulgular

| Önem | Yeni bulgu |
|---|---|
| Yüksek | Yok |
| Orta | Yok |
| Düşük | Yok |

Bulgu sayılmayan notlar (#315 raporunda zaten yazılı, sahibin kabul ettiği davranış):
- Yeni kayıt yazılıp profil kaydı başarısız olursa kullanılmayan bir mühimmat kaydı kalabilir (silme yok kuralı). Profil eski değerlerle kalır.
- Ayrılan kayıt eskisiyle aynı adı taşıyor; mühimmat listesinde iki aynı adlı kayıt görünür. #313'teki Kopyala ile aynı davranış.

Önceki raporlardaki açık orta/düşük bulgular (KUL-1, KUL-2, RUZ-1…3, MUH-1…5, PRF-1, PRF-3, PRF-4, PRF-5, ATM-2, ATM-3, KUL-3) #315 ile değişmedi.

## Testler

- `test/audit_2026_10_15/prf6_e2e_test.dart` (3 test, hepsi `skip`'siz, geçiyor):
  - `PRF-6 BC: Mühimmata uygula on a shared record leaves the other profile and the old record alone`
  - `unshared record: trued BC in place → solver input → Hedef number matches the hand calculation`
  - `second truing after the split updates the new record in place; no records pile up, none are deleted`
- `tools/denetim_2026_10_15.py` ve `tools/test_denetim_2026_10_15.py` (elle hesap + API anahtarı taraması).
- Yerel: `python3 tools/offline_dart_lint.py` → 0 sorun. `python3 -m unittest discover -s tools -p 'test_*.py'` → 751 test başarılı.

## CI

| Ne | Sonuç | Bağlantı |
|---|---|---|
| dart format (tek seferlik), ilk commit | başarılı; biçim commit'i geldi (`1f46fa5`) | https://github.com/sniperTurk/flutter-app/actions/runs/38686021914 |
| `flutter test test`, ilk deneme | düştü: yalnız yeni Hedef testi (test düzeneği: tema değişince yazı stili geçişi). Testteki sayfa değişimi düzeltildi | https://github.com/sniperTurk/flutter-app/actions/runs/38686024234 |
| Yalnız `test/audit_2026_10_15` | başarılı (3/3) | https://github.com/sniperTurk/flutter-app/actions/runs/38686935575 |
| `flutter test test` (bütün testler), son | çalışıyor (sonuç PR açıklamasında güncellenecek) | https://github.com/sniperTurk/flutter-app/actions/runs/38687058063 |
| dart format (tek seferlik), son | başarılı; değişiklik yok, commit gelmedi | https://github.com/sniperTurk/flutter-app/actions/runs/38687060486 |

TestFlight, Simulator ve App Store çalıştırılmadı.

---
_Generated by [Claude Code](https://claude.ai/code)_
