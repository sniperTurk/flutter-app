# Profil: dürbün kaydı ve tüfek eşleştirme düzeltmeleri (PRF-1, PRF-3, PRF-4, PRF-5)

Sahip kararı: 2026-10-15 20:47 (İstanbul), "düzeltmek için görev aç". Bulgular: `docs/reports/denetim_testflight_2026_10_14b.md`.

Dal: `fix/prf-durbun-eslestirme` (main 9104632 üzerinde). Taslak PR; birleştirme yok, TestFlight yok.

## Ne değişti

### PRF-1: Güncelle yan kule yolunu artık silmiyor
- Katalog dürbünlü profilde Güncelle'ye basınca kayda yan kule yolu (`windageRangeMrad`) da yazılıyor.
- Üreticinin "en az" diye verdiği yol işaretleri (`elevationRangeIsLowerBound`, `windageRangeIsLowerBound`) de yazılıyor.
- Hedef'teki yan tambur sınırı ve yan "Kule yetmez" uyarısı kalıyor.
- Örnek: Arken SH-4 GENII 4-16x50 FFP, yan yol 10 mrad. Önce: Güncelle sonrası boş. Şimdi: 10 mrad.

### PRF-3: profil birimi farklıysa dürbünün kendi birimi korunuyor
- Listeden seçili dürbünde kayıt, dürbünün kendi birimini ve klik değerini alıyor; profil biriminden bağımsız.
- Örnek: MRAD 0,1 dürbün, profil birimi MOA. Önce: dürbün MOA 0,25 olarak kaydediliyordu, sonraki açılışta MOA modeline eşleşiyor, Retikül "Seçiniz" oluyordu. Şimdi: MRAD 0,1 kalıyor ve aynı modelle açılıyor.
- Profilin kendi birimi (MOA) değişmiyor. Hedef'teki klik boyu önce de sonra da aynı.

### PRF-4: eşleştirici yazılmış tüfeği başka ürüne çevirmiyor
- `profile_catalog_match.dart` `rifle()`: önce tam ad eşleşmesi aranıyor, kalibre ondan sonra bakılıyor.
- Tam ad yoksa eşleşme yok; profil yazılmış kutularla açılıyor, değerler kalıyor.
- Örnek: "HATSAN / Hercules Bully", 6,35 mm. Önce: "Hatsan / Hercules" olarak açılıyordu. Şimdi: başka bir ürün olarak açılmıyor.
- Tam ad varsa kalibre listede olmasa da o model seçiliyor (ör. Hercules Bully 7,62).
- Büyük-küçük harf, boşluk ve marka adının modelde tekrarı eşleşmeyi bozmuyor ("TIKKA / T3X Tact A1" → "Tikka / T3x TACT A1" yine bulunuyor).

### PRF-5: Türkçe İ/i ve I/ı
- Eşleştirici, noktalı ve noktasız i'yi aynı harf sayıyor.
- "SARSILMAZ" = "Sarsılmaz", "TIKKA" = "Tikka", "İSTANBUL" = "istanbul".

### Kaynak belgesi (denetimde not edilen şüphe)
- Önce: Güncelle sonrası katalog dürbününün kaynağı "Kişisel kayıt; üretici doğrulaması yok" oluyordu. Retikül, ürün kodu bu kaynaktan bulunuyor.
- Şimdi: listeden seçili dürbünde üreticinin kaynak belgesi (`sourceDocument`) kayıtta kalıyor. Elle girilmiş dürbünde kaynak eskisi gibi "Kişisel kayıt".

## Nasıl
- `lib/features/profiles/profile_editor.dart`:
  - Yeni alan `_scopeOwn`. Profili Düzenle açılırken kayıtlı dürbün, listeden yeni model seçilince o katalog kaydı.
  - `_scopeEntry`: liste modunda birim, klik, yan yol, yol işaretleri ve kaynak bu kayıttan yazılıyor. Kayıtta bir değer yoksa liste kaydından tamamlanıyor.
  - Hoşgörülü eşleşmede (eski adla kaydedilmiş dürbün) yalnız kayıtlı değerler kullanılıyor; listeden değer eklenmiyor. Bu, #308'in "kayıtlı değerler değişmez" kuralı.
  - Yükseliş yolu işareti yalnız yol değişmediyse (yarım klik içinde) kalıyor. Kullanıcı yolu değiştirirse "en az" işareti düşüyor.
- `lib/features/profiles/profile_editor_scope.dart`: `_applyScope` `_scopeOwn`'u seçilen kayda eşitliyor (1 satır).
- `lib/data/user_catalog.dart`: kişisel dürbün kaydı okunurken iki yol işareti (yalnız ilgili yol varsa) ve `sourceDocument` (boş değilse, en çok 1000 karakter) okunuyor. Yoksa eskisi gibi "Kişisel kayıt".
- `lib/features/profiles/profile_catalog_match.dart`: `fold()` (Türkçe büyük-küçük harf), `rifle()` içinde önce tam ad.

## Neden
- Sahip kararı ve #308'in "kayıtlı veri korunur" sözü: Güncelle'ye bir şey değiştirmeden basmak dürbün verisini değiştirmemeli, tüfeğin adını başka ürüne çevirmemeli.

## Uç durumlar
- Eski profiller: yeni anahtarlar isteğe bağlı. Anahtarı olmayan eski kayıt eskisi gibi okunuyor. Var olan anahtarların adı ve anlamı değişmedi.
- Bu düzeltmeden önce Güncelle ile MOA'ya çevrilmiş bir dürbün kopyası kendi kaydıyla kalıyor (kayıtlı veri değiştirilmiyor). Aynı modelle eşleşiyorsa sonraki Güncelle eksik yan yolu ve kaynağı katalogdan tamamlıyor.
- Elle girilmiş ("Listede yok") dürbün: davranış aynı; yan yol sorulmuyor ve yazılmıyor.
- Profil birimi değişince Üst kule klik sayısı eskisi gibi profil biriminde gösteriliyor ve mrad olarak kaydediliyor.
- PRF-4 sonrası: adı listedekinden farklı yazılmış eski tüfekler (tam ad değil, yalnız benzer) artık listeye eşleşmiyor; yazılmış kutularla, değerleriyle açılıyor. Sahibin istediği kural bu.

## Bilerek yapılmayan
- Yan kule yolu için yeni form alanı yok.
- Mühimmat tarafına dokunulmadı (`fix/muh-bc-hiz` ile çakışma yok).
- Hedef/Balistik hesabı değişmedi.

## Testler
- `test/audit_2026_10_14b/profile_match_audit_test.dart`:
  - PRF-1, PRF-3, PRF-4, PRF-5 testlerinin `skip`'i kaldırıldı; hiçbir beklenti gevşetilmedi.
  - Yeni: katalog dürbününün kaynağı ve yan yolu iki kez Güncelle sonrası kalıyor; elle girilmiş dürbün kişisel kaynakla kalıyor; MOA profilde MRAD katalog dürbünü MRAD 0,1 ve yan yol 10 mrad olarak kalıyor, Hedef klik boyu aynı; tam ad kalibreden önce, tam ad yoksa eşleşme yok; Türkçe harf katlama (İ/i, I/ı).
- `tools/test_denetim_2026_10_14b_prf.py`: Python eşleştirici kopyası yeni kurallara uyarlandı. Hatayı belgeleyen kaynak kontrolleri düzeltilmiş duruma çevrildi (PRF-2'de yapıldığı gibi). Yeni: tam ad / kalibre, tam ad yoksa eşleşme yok.
- Yerel:
  - `python3 tools/offline_dart_lint.py`: PASS, 387 Dart dosyası, 0 sorun.
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: 845 test, OK.
- Bu ortamda Flutter SDK yok; Dart testleri yalnız CI'da çalıştı.

## CI

Dal iki kez main'in üstüne alındı (rebase); main'den gelen değişiklikler bu PR'ın dosyalarına dokunmuyor. Aşağıdaki tablo main bc3039d üzerindeki 2e5db4a başı içindir. Son rebase (main 67e75de) yalnız main'i ilerletti, kod aynı; son başın CI sonucu PR sayfasındadır.

| İş | Sonuç | Bağlantı |
|---|---|---|
| Dart format düzeltme (format-fix), ilk tur | başarılı; format commit'ini üretti, dala çekildi | https://github.com/sniperTurk/flutter-app/actions/runs/38794885503 |
| Dart format düzeltme, rebase sonrası | başarılı; değişiklik yok | https://github.com/sniperTurk/flutter-app/actions/runs/38810916262 |
| `flutter analyze` (analyze-diag), rebase sonrası | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38811035097 |
| Bütün test takımı, `files=test` (test-diag), rebase sonrası | başarılı (çıkış kodu 0) | https://github.com/sniperTurk/flutter-app/actions/runs/38811031766 |
| iOS CI `dart-checks` (2e5db4a) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38810922663/job/116683632488 |
| iOS CI `wind-acceptance` (2e5db4a) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38810922663/job/116683632169 |
| iOS CI `verify` (2e5db4a) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38810922663/job/116689722733 |
| iOS CI `ios-simulator` | atlandı (iş akışı bu dalda çalıştırmıyor); Simulator derlemesi yapılmadı | https://github.com/sniperTurk/flutter-app/actions/runs/38810922663/job/116683635298 |

Rebase öncesi aynı kodda (70d3de4) analyze, test-diag, dart-checks, wind-acceptance ve verify de başarılıydı: https://github.com/sniperTurk/flutter-app/actions/runs/38795065539.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
