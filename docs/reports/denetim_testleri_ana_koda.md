# Denetim testleri ana koda (#310, #314, #316)

Tarih: 15.10.2026, İstanbul saati. Dal: `test/denetim-testleri` (main `d86dfff`'den açıldı). PR: #319.

## Ne yapıldı

Birleşmemiş üç denetim PR'ının yalnız kendi dosyaları main'e alındı. Dallar toptan birleştirilmedi. `lib/` hiç değişmedi.

## Hangi dosyalar alındı

- **#310** (`audit/testflight-2026-10-14b`):
  - `docs/reports/denetim_testflight_2026_10_14b.md`
  - `test/audit_2026_10_14b/ammo_bc_audit_test.dart`
  - `test/audit_2026_10_14b/atmosphere_altitude_audit_test.dart`
  - `test/audit_2026_10_14b/profile_match_audit_test.dart`
  - `test/audit_2026_10_14b/turret_zero_cleanup_audit_test.dart`
  - `test/audit_2026_10_14b/weather_wind_elevation_audit_test.dart`
  - `tools/test_denetim_2026_10_14b_atm.py`, `_kul.py`, `_muh.py`, `_prf.py`, `_ruz.py`
- **#314** (`audit/testflight-2026-10-14c`):
  - `docs/reports/denetim_testflight_2026_10_14c.md`
  - `test/audit_2026_10_14c/kopyala_old_firearm_audit_test.dart`
  - `tools/test_denetim_2026_10_14c.py`
  - `test/audit_2026_10_14c/truing_shared_record_audit_test.dart` **alınmadı**: main'deki sürüm daha yeni (#315 ile PRF-6 testi `skip` olmadan açılmış). Daldaki sürüm aynı testi `skip: true` ile tutuyor. main'inki kaldı.
- **#316** (`audit/testflight-2026-10-15`):
  - `docs/reports/denetim_testflight_2026_10_15.md`
  - `test/audit_2026_10_15/prf6_e2e_test.dart`
  - `tools/denetim_2026_10_15.py`, `tools/test_denetim_2026_10_15.py`

Dosya listesi her dalın main'den ayrıldığı noktaya göre `git diff` ile çıkarıldı. Üç dal da yalnız bu dosyaları ekliyor. Main'de zaten bulunan `atm1_restart_solve_test.dart` ve `prf2_kopyala_test.dart` (#312, #313) değişmedi. İçe aktarma (import) ya da yol düzeltmesi gerekmedi.

## Açılan bulgu testleri (düzeldi, geçmeli)

| Bulgu | Düzelten PR | Ne değişti |
|---|---|---|
| ATM-1 | #312 | `atmosphere_altitude_audit_test.dart` içindeki iki ATM-1 testinin `skip:` satırı kaldırıldı. `tools/test_denetim_2026_10_14b_atm.py` içindeki ATM-1 testinin `@unittest.expectedFailure` işareti kaldırıldı (main'de artık geçiyordu). |
| PRF-2 | #313 | `profile_match_audit_test.dart` içindeki PRF-2 testinin `skip:` kaldırıldı. |
| PRF-6 | #315 | Alınan dosyalarda PRF-6 için `skip` yok. `prf6_e2e_test.dart` zaten açık yazılmış; main'deki `truing_shared_record_audit_test.dart` da açık. |

**Bir test, import dışında değişti:** `tools/test_denetim_2026_10_14b_prf.py` içindeki `test_prf2_copy_and_editor_reuse_record_ids`, PRF-2 hatasının kodda *var olduğunu* yazıyordu (Kopyala eski kayıt kimliklerini kullanıyor). #313 düzeltince main'de kırıldı. Test gevşetilmedi; tersine çevrildi: artık Kopyala'nın yeni kimlikleri (`ids.rifleId` …) kullandığını ve eski `p.rifleId` … satırlarının kalmadığını denetliyor. Davranış koruması asıl olarak Dart PRF-2 testlerinde.

Hiçbir "düzeldi" testi main'de kırılmadı. "FAILS ON MAIN" notu gerekmedi. **Yeni yüksek bulgu yok.**

## Hâlâ `skip` olanlar (açık bulgular)

Hepsi #310 (14b) raporundan. Testler `skip:` ile ve bulgu kimliğiyle duruyor.

| Bulgu | Önem | Test dosyası |
|---|---|---|
| KUL-1 | Orta | `turret_zero_cleanup_audit_test.dart` |
| KUL-2 | Orta | `turret_zero_cleanup_audit_test.dart` |
| KUL-3 | Düşük | `turret_zero_cleanup_audit_test.dart` |
| RUZ-1 | Orta | `weather_wind_elevation_audit_test.dart` |
| RUZ-2 | Orta | `weather_wind_elevation_audit_test.dart` (2 test) |
| RUZ-3 | Orta (şüphe) | test yok, yalnız raporda |
| MUH-1 | Orta | `ammo_bc_audit_test.dart` |
| MUH-2 | Orta | `ammo_bc_audit_test.dart` (sahip kararı bekliyor, #304) |
| MUH-3 | Düşük | `ammo_bc_audit_test.dart` |
| MUH-4 | Düşük | `ammo_bc_audit_test.dart` |
| MUH-5 | Düşük | `ammo_bc_audit_test.dart` |
| PRF-1 | Orta | `profile_match_audit_test.dart` |
| PRF-3 | Orta | `profile_match_audit_test.dart` |
| PRF-4 | Orta | `profile_match_audit_test.dart` |
| PRF-5 | Düşük | `profile_match_audit_test.dart` |
| ATM-2 | Düşük | `atmosphere_altitude_audit_test.dart` |
| ATM-3 | Düşük | `atmosphere_altitude_audit_test.dart` |

14c ve 15 denetimlerinde yeni orta/düşük bulgu yok.

## Yerel denetim

- `python3 tools/offline_dart_lint.py`: geçti (357 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: alınan dosyalarla ilk koşuda 1 hata (PRF-2 belge testi) ve 1 beklenmedik başarı (ATM-1) çıktı; yukarıdaki iki düzeltmeden sonra denetim dosyaları (94 test) geçti.
- Flutter SDK bu ortamda yok; Dart testleri yalnız CI'da çalıştı.

## CI

Hepsi `b1db5c7` (iki test commit'i, bu rapordan önce) üzerinde koştu:

- Biçim (format) düzeltme iş akışı: [run 38701638807](https://github.com/sniperTurk/flutter-app/actions/runs/38701638807) — başarılı, değişiklik yazmadı (dalda yeni commit yok).
- Analiz: [run 38701641280](https://github.com/sniperTurk/flutter-app/actions/runs/38701641280) — başarılı.
- Yalnız denetim klasörleri (`test/audit_2026_10_14b`, `_14c`, `_15`): [run 38701643990](https://github.com/sniperTurk/flutter-app/actions/runs/38701643990) — başarılı.
- Bütün `test` klasörü: [run 38702348527](https://github.com/sniperTurk/flutter-app/actions/runs/38702348527) — başarılı.
- PR denetimleri (iOS CI): [run 38701642322](https://github.com/sniperTurk/flutter-app/actions/runs/38701642322) — `dart-checks` ve `wind-acceptance` başarılı, `ios-simulator` atlandı (skipped).

Bu rapor commit'iyle PR denetimleri yeniden koşar. Birleştirme yalnız son commit üzerinde `verify`, `dart-checks` ve `wind-acceptance` başarılı biterse yapılır; sonuç PR açıklamasında.

## Sorunlar

- `gh` komut satırı bu ortamda giriş yapamadı; GitHub işleri GitHub bağlantısı (REST) ile yapıldı.

## Birleştirme sonucu

Koşul: son commit üzerinde `verify`, `dart-checks`, `wind-acceptance` başarılı, çakışma yok. Koşul sağlanırsa PR hazır olarak işaretlenip squash ile birleştirilir; ardından #310, #314, #316 kapatılır (dallar silinmez) ve #317, #318'e not yazılır. Gerçek sonuç PR açıklamasının sonunda yazılı. TestFlight başlatılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
