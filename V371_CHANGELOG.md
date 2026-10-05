# V371 — profil/katalog/manuel-diyalog kurtarma gerilemesi düzeltmesi (PR #1)

Kaynak: V370. Birleştirilen PR: `review/profile-catalog-dialog-fixes`
(base `2fc27a3`, head `1873b6c`, merge `8833001`). Bu dosya daha önce
eksikti; kod ve testler V370'den sonra zaten bu sürümdeydi — bu, o boşluğu
kapatıyor.

## Kök neden ve düzeltme
`PersistentProfileStore` (ve aynı desenle `ManualCatalogStore`,
`UserCatalogStore`) yazma işlemlerini statik bir `Future` zinciriyle sıraya
koyuyordu. Future dinleyicileri, future'ın oluşturulduğu zone üzerinden
tetiklenir; o zone bittiğinde kuyruktaki sıradaki işlem hiç başlamıyordu
(CI izinde `enqueue#7` var, `start#7` yok — HomeScreen kurtarma testinde
yakalandı).

Düzeltme: `lib/services/serial_mutation_lock.dart` — zone'dan bağımsız bir
seri kilit. `test/serial_mutation_lock_test.dart` hatayı deterministik
olarak yeniden üretip doğruluyor (bir "endable zone" ile).

## Üretim kodu değişiklikleri
- Profil düzenleyici artık kişisel (manuel) katalog kayıtlarını da
  `CatalogRepository.allRifles/allAmmunition/allScopes` üzerinden gösteriyor
  — V370'in "bilinen eksik" notu olan katalog↔profil bağlantısı bu PR'da
  çözüldü.
- `lib/features/catalog/manual_catalog_dialog.dart`: diyalog yaşam döngüsü
  düzeltmeleri (async boşluk/`mounted` koruması).
- `lib/features/home/home_screen.dart`: aktif profil geri alma (rollback)
  mantığı.
- `lib/data/profile_catalog_integrity.dart` (yeni): profil↔katalog bütünlük
  kontrolü.

## Doğrulama altyapısı
- `validation/wind_acceptance.json`, `validation/envelope_acceptance.json`
  (yeni): deneysel G1/G7 çözücü için ayrı rüzgâr ve "önerilen zarf" kabul
  kümeleri. Her ikisi de üretim kapısını AÇMIYOR; `acceptance.json`'daki
  rüzgârsız politika değişmedi.
- `tools/generate_wind_reference_vectors.py`,
  `tools/compare_wind_reference_vectors.dart`: rüzgâr referans vektörü
  üretimi/karşılaştırması hazırlığı (henüz üretim kapısına bağlı değil).

## Testler
- Yeni: `test/serial_mutation_lock_test.dart`, `test/home_recovery_test.dart`,
  `test/home_active_profile_test.dart`,
  `tools/test_v371_manual_catalog_profiles_and_dialog.py` (8/8 geçti — bu
  oturumda doğrulandı).
- Değişen: `test/profile_recovery_test.dart`, `test/manual_catalog_dialog_test.dart`,
  `test/user_catalog_test.dart`, `test/menzil_shell_test.dart`,
  `test/menzil_layout_extremes_test.dart`.

## PR #1'in kendi kanıt tablosu (özet)
| Commit | Koşum | Sonuç |
|---|---|---|
| `0091510` | iOS CI / verify (37203196834) | format, analyze, **tüm testler**, iOS iskeleti GEÇTİ; App Store preflight `PRIVACY_POLICY_URL` eksikliğinde durdu |
| `0091510` | CI diagnostics | format diff yok, analyze temiz, **249/249 test** |
| `0091510` | iOS CI / ios-simulator | Simulator debug build GEÇTİ; launch/integration smoke log alınamadığı için KALDI |
| `0091510` | wind-acceptance | rüzgârsız 20/20, rüzgârlı 25/25 GEÇTİ; zarf köşelerinden 1 vaka referans üretemedi |

PR gövdesinde "Taslak, birleştirilmeyecek" notu vardı; buna rağmen `8833001`
ile `main`'e birleştirilmiş durumda — bu çelişki repo sahibine ait bir karar,
bu değişiklikte yeniden yorumlanmadı.

## Bilinen eksik (bu sürümde DEĞİL)
- `PRIVACY_POLICY_URL`, `METNO_CONTACT` hâlâ tanımsız (bkz. `release/RELEASE_CHECKLIST.md`).
- Rüzgâr/zarf kabul kümeleri üretim kapısını açmıyor; G1/G7 üretim kapısı KAPALI.
- Fiziksel iPhone, signing, TestFlight, App Store: ÇALIŞTIRILMADI.
