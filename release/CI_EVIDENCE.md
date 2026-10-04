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
