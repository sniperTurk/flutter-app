# Google Maps faturalandırma kontrolü (Haritadan irtifa)

Tarih: 2026-10-15 (İstanbul saati)

## Ne
Sahibin sorusu: "ödeme yaptık, şu an aktif olması lazım, kontrol et".
Uygulamanın "Haritadan irtifa" isteğinin (`lib/tools/adapters/google_elevation_provider.dart`)
`GOOGLE_MAPS_IOS_API_KEY` anahtarıyla artık başarılı olup olmadığını görmek.

## Nasıl
`.github/workflows/maps-check.yml` eklendi (yalnız elle çalıştırma, `workflow_dispatch`, ubuntu-latest).
Uygulamayla aynı tek istek atılır:
`https://maps.googleapis.com/maps/api/elevation/json?locations=39.92,32.85&key=…`
başlık `X-Ios-Bundle-Identifier: com.sniperturk.sniperTurk`.
Loga yalnız şunlar yazılır: anahtar tanımlı mı (yes/no), HTTP kodu, JSON `status`,
`error_message`, OK ise yükseklik. Anahtar, anahtarlı URL ve ortam değişkenleri yazılmaz.
İş her zaman başarıyla biter (rapor amaçlı).

## Sonuç
**Henüz çalıştırılamadı (BLOCKED).** GitHub, `workflow_dispatch` ile çalıştırmaya yalnız
dosya varsayılan dalda (main) bulunduğunda izin veriyor; `ci/maps-check` dalında
çalıştırma isteği `404 Not Found` döndü. Bu yüzden faturalandırmanın aktif olup
olmadığı **doğrulanmadı**; OK denemez.

Gereken: PR birleştirildikten sonra Actions → "Maps billing check (Elevation API)" →
Run workflow (main). Sonuç bu dosyaya eklenecek.

## Sonucu okuma
- `status: OK` ve bir yükseklik → faturalandırma ve Elevation API çalışıyor.
- `REQUEST_DENIED` + mesajda "Billing" → o projede faturalandırma etkin değil.
  Cloud Console → Faturalandırma → Hesabı projeye bağla (Projeyi seç → Billing → Link a billing account).
- "API not enabled" / "not authorized to use this API" → Elevation API açılmalı.
  Cloud Console → API'ler ve Hizmetler → Kitaplık → "Elevation API" → Etkinleştir.
- "API key restrictions" / bundle ile ilgili mesaj → anahtar kısıtlaması (RUZ-3).
  Cloud Console → API'ler ve Hizmetler → Kimlik bilgileri → anahtar → Uygulama kısıtlamaları:
  iOS uygulamaları, paket kimliği `com.sniperturk.sniperTurk`; API kısıtlamalarında Elevation API seçili olmalı.

## Kontrol edilemeyen
Harita gösterimi (Maps SDK for iOS) CI'dan kontrol edilemez; TestFlight'ta kontrol edilir.
