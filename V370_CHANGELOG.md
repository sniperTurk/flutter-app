# V370 — gerçek Flutter 3.47.2 zincirinin bulduğu hataların düzeltilmesi

Kaynak: V369. Yeni özellik/tasarım yok. Düzeltmeler yalnızca GitHub Actions'ta
(macOS, Flutter 3.47.2 / Dart 3.13.2) gerçekten çalışan derleyici, analyzer ve
testlerin gösterdiği hatalardır.

## Üretim kodu değişiklikleri
- `MenzilToolTile`: ListTile kendi `Material` katmanına alındı (ink assertion).
- Yeni profil varsayılan tüfeği: kataloğunda mühimmatı olan ilk tüfek (öncekinde
  varsayılanlar kaydedilemiyordu). Düzenleme modu hâlâ sessizce bir şey seçmez.
- `catalog_screen.dart`: BuildContext async boşluk uyarıları giderildi.
- Kullanılmayan `_ammo`, `const` ve gereksiz cast/interpolation temizliği.
- `dart format` + 70 `curly_braces` düzeltmesi (SDK aracıyla uygulandı).
- **Kurtarma (kullanıcı eylemiyle)**: ana+yedek profil kaydı bozuksa Profil
  ekranında "Kayıtları kurtar": (1) ham veriyi göster/kopyala (salt okunur),
  (2) "Boş başla": iki bozuk kayıt ayrı anahtarlara kopyalanır, geri okuma ile
  doğrulanır, ancak sonra boş liste yazılır; okunabilir depoda reddeder.
  Paylaşma sistemi paylaşım sayfası yerine panoya kopyalama olarak yapıldı
  (yeni bağımlılık eklenmedi).

- **Düzeltme (inceleme bulgusu, doğrulandı):** Ana ekranın hata kartı sekmeleri
  gizlediği için Profil sekmesindeki "Kayıtları kurtar"a ulaşılamıyordu. Düğme
  artık Ana ekran hata kartında da var; Ana ekran üzerinden uçtan uca test eklendi.

## Araç / CI
- `pubspec.lock` + `lockfile-provenance.txt`: sabitlenmiş Flutter 3.47.2 Actions
  koşusundan, format+analyze+test geçtikten sonra. sha256 `ccd06706fe686ead5cb1ea45e69d63d0160b7abc4247e9d9f53c8286f0b31277`.
- `generate_reference_vectors.py`: py-ballisticcalc 2.2.10 API (`get_at('distance', …)`, `Pressure.hPa`).
- iOS CI: scipy/numpy sabitlendi; gate doğrulayıcı biçimden bağımsız.
- `ci-diagnostics.yml` (yalnız tanı; sürüm artefaktı değildir).

## Testler (gerçek CI)
- Flutter: 219 test geçti (Kronograf uygula 5, profil kurtarma 3 + Ana ekran kurtarma 1 test dahil). Kanıt: release/CI_EVIDENCE.md (koşu numaraları).
- Python: 575 test geçti. G1/G7 gate KAPALI. `acceptance.json` değişmedi.

## Bilinen eksik (bu pakette DEĞİL)
- Manuel katalog kayıtları profillere bağlı değil (yalnız Katalog ekranında). Ayrı
  oturumda açılan taslak PR #1 (`review/profile-catalog-dialog-fixes`) bunu ele
  alıyor; main'e birleştirilmedi, çakışma çözümü ve inceleme gerekir.

## ÇALIŞTIRILMADI / DOĞRULANMADI
- iOS CI "App Store preflight" ve sonrası (PRIVACY_POLICY_URL yok), Simulator, IPA.
- Gerçek iPhone, signing, TestFlight, App Store.
- Bozuk-yazma başarısızlığı (quarantine yazımı hata verirse) testi: SharedPreferences
  yazma hatası taklidi yok, test edilmedi.
