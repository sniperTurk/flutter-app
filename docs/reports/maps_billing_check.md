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
**OK — faturalandırma ve Elevation API çalışıyor.**

Çalıştırma: [Actions run 38785522797](https://github.com/sniperTurk/flutter-app/actions/runs/38785522797)
(main, 2026-10-15 21:25 İstanbul). Log çıktısı:

```
secret_set: yes
http_code: 200
status: OK
error_message: -
elevation_m: 868.9695434570312
```

Anahtar tanımlı, istek uygulamadaki paket kimliği başlığıyla kabul edildi, Ankara
(39.92, 32.85) için yükseklik ≈ 869 m döndü. Sahibin Cloud Console'da yapması gereken bir adım yok.

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
