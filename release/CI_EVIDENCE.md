# CI kanıt kaydı (V370, commit ee52657)

Bu dosya yalnızca GitHub Actions'ta gerçekten çalışmış koşuları gösterir
(repo: sniperTurk/flutter-app, runner macos-15, Flutter 3.47.2 / Dart 3.13.2).
Yerel ortamda Flutter SDK yoktur; aşağıdaki sonuçlar bağımsız doğrulanabilir
koşu numaralarıdır (Actions sekmesinde `runs/<id>`).

| Koşu | Workflow | Commit | Sonuç |
|---|---|---|---|
| 37200232749 | CI diagnostics (tam zincir, hata sonrası devam eder) | ee52657 | pub get 0, format check 0, analyze 0 ("No issues found"), flutter test 0 (219 test, "All tests passed!") |
| 37200428070 | bootstrap-lockfile (ilk hatada durur) | ee52657 | success: format + analyze + flutter test + lockfile provenance |

Ham günlükler: dal `ci/diagnostics-main` → `ci-logs/{status.txt,analyze.log,test.log}`
(her tanı koşusunda üzerine yazılır; kalıcı kanıt koşu numarasıdır).

Lockfile: `pubspec.lock` sha256 `ccd06706fe686ead5cb1ea45e69d63d0160b7abc4247e9d9f53c8286f0b31277`
(koşu 37194580026, format+analyze+test geçtikten sonra, tools/verify_lockfile_provenance.py OK).

## Çalıştırılmadı / geçmedi (dürüst durum)
- iOS CI (`ios-ci.yml`): Python 575, gate, lockfile, bağımsız G1/G7 vektörleri,
  Dart karşılaştırması, format, analyze, testler, iOS iskeleti GEÇTİ; "App Store
  source preflight" adımında DURDU: `PRIVACY_POLICY_URL` ve `METNO_CONTACT` GitHub
  değişkenleri tanımlı değil. Simulator, imzasız arşiv, IPA: ÇALIŞMADI.
- Gerçek iPhone, signing, TestFlight, App Store: ÇALIŞMADI.
- Üretim G1/G7 kapısı KAPALI; `validation/acceptance.json` değişmedi.

## V371 (PR #1 `review/profile-catalog-dialog-fixes`, merge `8833001`)

PR'ın kendi gövdesindeki kanıt tablosu (bu depo dışında ayrı bir oturumda
üretildi, burada tekrar çalıştırılmadı — sadece PR metninden aktarılıyor):

| Koşu | Workflow | Commit | Sonuç |
|---|---|---|---|
| 37203196834 | iOS CI / verify | `0091510` | format, analyze, tüm testler, iOS iskeleti GEÇTİ; App Store preflight `PRIVACY_POLICY_URL` eksikliğinde durdu |
| — | CI diagnostics | `0091510` | format diff yok, analyze temiz, 249/249 test |
| — | iOS CI / ios-simulator | `0091510` | Simulator debug build GEÇTİ; launch/integration smoke log alınamadığı için KALDI |
| — | wind-acceptance | `0091510` | rüzgârsız 20/20, rüzgârlı 25/25 GEÇTİ; zarf köşelerinden 1 vaka referans üretemedi |

PR gövdesi "Taslak. Birleştirilmeyecek: yeşil doğrulama yok." notu taşıyor;
buna karşın `8833001` ile `main`'e birleşmiş durumda. Bu çelişki burada
çözülmedi/yorumlanmadı — sadece olduğu gibi kayda geçirildi. Ayrıntı:
`V371_CHANGELOG.md`.

## PR #3 (`feature/wind-click-elevation-unlock-and-hit-probability`, inceleme sürüyor)

Bu sandbox'ta Flutter SDK yok; yalnızca offline Python araçları (586 test,
`offline_dart_lint.py` 116 dosya/0 sorun, production gate KAPALI doğrulaması)
çalıştırıldı. Gerçek `dart format`/`flutter analyze`/`flutter test`/iOS
Simulator sonucu için PR #3'ün kendi GitHub Actions koşusuna bakılmalı; bu
dosyaya o koşu tamamlandığında ayrı bir satır olarak eklenecektir.
