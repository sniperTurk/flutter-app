# SNIPER TÜRK V1 — release checklist (V369)

## A — BLOCKER (V1 release yapılamaz)
1. `pubspec.lock` + `lockfile-provenance.txt` yok: yalnız pinned Flutter 3.47.2 Actions (bootstrap-lockfile) çıktısı kabul edilir; image_picker eklendiği için yeniden üretilmeli. **Sahip: workflow çalıştırıp URL + iki SHA-256 gönder.**
2. `dart format` / `flutter analyze --fatal-infos --fatal-warnings` / `flutter test` / `integration_test` bir kez gerçekten çalışmadı (hepsi NOT RUN). V366–V369 Dart değişiklikleri derlenmedi; derleme/format hatası çıkma ihtimali gerçek.
3. Repository variable `METNO_CONTACT` (gerçek e-posta/https) ayarlanmadan release build CI'da durur (V369 `validate_metno_contact.py`). Verilmezse Hava & Rüzgâr release'te çalışmaz (fail-closed).
4. Repository variable `PRIVACY_POLICY_URL` (mevcut CI kapısı) ve yayında bir gizlilik sayfası.
5. Gerçek iOS release/ipa build (CI macos-15) — NOT RUN.

## B — RELEASE ÖNCESİ
1. OWNER DECISION REQUIRED — App Privacy: konum, uygulama dışına (api.met.no, üçüncü taraf) gönderiliyor; 4 ondalık ≈ 11 m (hassas konum sınıfı olabilir). `PrivacyInfo.xcprivacy` şu an `NSPrivacyCollectedDataTypes` boş; App Store Connect beyanı ve manifest kararı sahibe ait (uydurulmadı).
2. OWNER DECISION REQUIRED — Primary+backup ikisi bozukken kullanıcı kurtarma UX'i (`release/PROFILE_RECOVERY_DESIGN.md`); kod bilerek değiştirilmedi.
3. Eksik Flutter testleri (yazılı ama çalıştırılmadı): profil editörü fail-closed widget testi, quarantine testleri. Yazılmayanlar: Weather timer/resume, camera init-failure/cleanup, orientation lifecycle, Level reference/reset widget testleri (fake'ler `test/support/tool_fakes.dart` içinde mevcut).
4. `IOS_DEVELOPMENT_TEAM` variable ve imzalama/export (sahip Apple hesabı).
5. App Store metadata (ekran görüntüleri, açıklama, yaş derecesi — silah/balistik içerik incelemesi) — sahip.

## C — FİZİKSEL CİHAZDA DOĞRULANACAK (şu an NOT VERIFIED)
Pusula kuzey referansı (iOS trueHeading + konum güncellemesi yok → geçersiz olabilir), Su Terazisi X/Y işareti ve referans, kamera (izin/ret/yaşam döngüsü/eski cihaz), galeri EXIF yönü, landscape/kısa landscape, VoiceOver, 390 pt, Hava resume/stale. Adım adım: `release/DEVICE_ACCEPTANCE_PLAN.md`.

## D — V1 SONRASI / OPTIONAL
Kullanılmayan `UserCatalogStore` (üretimde bağlı değil), RifleProfile ==/hashCode, pubspec Dart tabanı 3.8→daha sıkı, kullanıcı özel mühimmat/katalog kaydı özelliği, G1/G7 kapısı (gerçek acceptance kanıtı gelene kadar KAPALI).

## Değişmeyenler
G1/G7 gate KAPALI; `validation/acceptance.json` SHA 1d861282…7c67927d; Atış/Tablo KİLİTLİ; click yasağı.
