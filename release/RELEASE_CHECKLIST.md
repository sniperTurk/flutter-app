# SNIPER TÜRK V1 — release checklist (V371 taban + PR #3 incelemede)

Bu dosya daha önce V369'u referans alıyor ve `flutter analyze`/`flutter
test`'in hiç çalışmadığını söylüyordu; bu, `release/CI_EVIDENCE.md`'nin V370
için zaten belgelediği gerçek CI koşularıyla çelişiyordu. Aşağıdaki liste o
çelişkiyi gideriyor; davranış/kod değişmedi.

## A — BLOCKER (V1 release yapılamaz)
1. ~~`pubspec.lock` + `lockfile-provenance.txt` yok~~ **ÇÖZÜLDÜ** — her ikisi de `main`'de committed (`lockfile_sha256 ccd06706…`, bkz. `lockfile-provenance.txt`), pinned Flutter 3.47.2 Actions koşusundan (`release/CI_EVIDENCE.md`).
2. ~~`dart format` / `flutter analyze` / `flutter test` hiç çalışmadı~~ **V370/V371 tabanı için ÇÖZÜLDÜ** — gerçek CI'da (macOS, Flutter 3.47.2/Dart 3.13.2) format temiz, analyze "No issues found", 219 (V370) / 249 (PR #1 head `0091510`) test geçti (bkz. `release/CI_EVIDENCE.md`, PR #1 kanıt tablosu). **Not:** bu, bu taban için geçerli; üzerine eklenen M1 + V354 + Vuruş Olasılığı çalışması (PR #3, `feature/wind-click-elevation-unlock-and-hit-probability`) için ayrı, kendi CI koşusu izleniyor — bu sandbox'ta Flutter SDK olmadığından yalnızca offline Python araçlarıyla doğrulandı, `dart format`/`analyze`/`test` sonucu PR #3'ün kendi CI koşusuna bakılmalı.
3. Repository variable `METNO_CONTACT` (gerçek e-posta/https) ayarlanmadan release build CI'da durur (V369 `validate_metno_contact.py`). Verilmezse Hava & Rüzgâr release'te çalışmaz (fail-closed). **ÇÖZÜLDÜ** — variable tanımlı ve CI doğrulaması (`validate_metno_contact.py`) geçti.
4. Repository variable `PRIVACY_POLICY_URL` ve yayında gizlilik sayfası. **ÇÖZÜLDÜ** — CI ön kontrolü ve canlı sayfa kontrolü geçti.
5. Gerçek iOS release/ipa build (CI macos-15) — **Hâlâ NOT RUN** (App Store preflight adımı 3–4 maddeleri yüzünden duruyor).

## B — RELEASE ÖNCESİ
1. App Privacy — sahip kararı verildi (2026-10-06): konum api.met.no'ya 2 ondalığa (~1 km) yuvarlanarak gönderilir; `PrivacyInfo.xcprivacy` `CoarseLocation` (bağlı değil, izleme yok, AppFunctionality) beyan eder. **AÇIK (sahip):** App Store Connect > App Privacy'de aynı beyanın girilmesi.
2. OWNER DECISION REQUIRED — Primary+backup ikisi bozukken kullanıcı kurtarma UX'i (`release/PROFILE_RECOVERY_DESIGN.md`); kod bilerek değiştirilmedi.
3. Eksik Flutter testleri — **V372 ile YAZILDI** (`test/tools_lifecycle_test.dart`): Hava yaş zamanlayıcısı ve ön plana dönüş, kamera açılış hatası ve oturum temizliği (sayfa kapanınca / açılış bitmeden kapanınca), ekran yönü kilidi ve geri alınması (Su Terazisi, Pusula, yan fotoğraf), Su Terazisi referans ayarla/temizle/kilitle. Sonuç: PR'ın kendi iOS CI koşusu (bu sandbox'ta Flutter yok). Profil editörü fail-closed ve quarantine testleri V370 CI'ında çalıştı (`release/CI_EVIDENCE.md`).
4. `IOS_DEVELOPMENT_TEAM` variable ve imzalama/export (sahip Apple hesabı).
5. App Store metadata (ekran görüntüleri, açıklama, yaş derecesi — silah/balistik içerik incelemesi) — sahip.

## C — FİZİKSEL CİHAZDA DOĞRULANACAK (şu an NOT VERIFIED)
Pusula kuzey referansı (iOS trueHeading + konum güncellemesi yok → geçersiz olabilir), Su Terazisi X/Y işareti ve referans, kamera (izin/ret/yaşam döngüsü/eski cihaz), galeri EXIF yönü, landscape/kısa landscape, VoiceOver, 390 pt, Hava resume/stale. Adım adım: `release/DEVICE_ACCEPTANCE_PLAN.md`.

## D — V1 SONRASI / OPTIONAL
Kullanılmayan `UserCatalogStore` (üretimde bağlı değil), RifleProfile ==/hashCode, pubspec Dart tabanı 3.8→daha sıkı, kullanıcı özel mühimmat/katalog kaydı özelliği, G1/G7 kapısı (gerçek acceptance kanıtı gelene kadar KAPALI).

## Değişmeyenler
G1/G7: PR #5 (`4cd5faf`) BC+model isteklerini aerodinamik çözücüye yönlendirdi; kapı CI'daki py-ballisticcalc referans karşılaştırmasıyla yapısal olarak korunuyor (`tools/verify_production_gate.py`). Aşağıdaki eski satır PR #5 öncesi durumdur:
G1/G7 gate KAPALI; `validation/acceptance.json` SHA 1d861282…7c67927d; Atış/Tablo KİLİTLİ; click yasağı (V354 ile sadece Yükseklik/elevation vakum trigonometrisi kilidi açıldı — Rüzgâr hâlâ KİLİTLİ, bkz. PR #3).

## V1 kapsamı netliği (karışıklığı önlemek için)
Kronograf, Sight Height, Pusula ve Su Terazisi bir noktada (V271) V1
kapsamından çıkarılmış, sonra **M1**'de (`M1_CHANGELOG.md`) kasıtlı ve
belgelenmiş bir kararla V1 kapsamına geri alınmıştır. Bu dört aracın şu an
üründe görünmesi bir gerileme/hata DEĞİLDİR; M1'den sonraki gerçek V1
kapsamı budur.
