# Retikül eşleştirme 3 — çalışma durumu (2026-10-12)

Başlangıç: main bc88399, `python3 tools/reticle_match_audit.py`.

## Kaynak kuralı
Yalnız dürbün kaydının `sourceDocument` alan adındaki üretici sayfası/PDF'i
(ve aynı alan adının alt alan adları). Bayi, forum, blog, balistik yazılım
verisi kullanılmaz. Üretici vermediyse alan null.

## Delta Optical
`https://www.deltaoptical.pl/` 2026-10-12'de bir kez daha denendi:
WebFetch `ROBOTS_DISALLOWED` (site robots.txt ile otomatik okumayı
yasaklıyor); bulut ortamında doğrudan bağlantı (curl) vekil sunucuda
`CONNECT 403`. Dolaylı yol denenmedi. Titanium ve Classic retikülleri
eklenmedi.

## Marka marka önce/sonra

| Marka | Dürbün | Önce eşleşen | Sonra eşleşen | Fark | Sonra çizilir |
|---|---:|---:|---:|---:|---:|
| Athlon | 146 | 75 | 146 | +71 | 101 |
| Barska | 56 | 0 | 33 | +33 | 2 |
| Burris | 39 | 8 | 34 | +26 | 14 |
| Bushnell | 21 | 1 | 13 | +12 | 1 |
| Delta Optical | 8 | 0 | 0 | +0 | 0 |
| Discovery Optics | 35 | 0 | 0 | +0 | 0 |
| Element Optics | 30 | 29 | 29 | +0 | 24 |
| GPO | 11 | 0 | 6 | +6 | 0 |
| Gamo | 11 | 0 | 5 | +5 | 5 |
| Gazi Sniper | 2 | 0 | 0 | +0 | 0 |
| Hawke | 97 | 6 | 40 | +34 | 5 |
| Integrix | 7 | 0 | 7 | +7 | 5 |
| Kahles | 15 | 2 | 14 | +12 | 0 |
| Konus | 37 | 0 | 22 | +22 | 18 |
| Leupold | 63 | 25 | 58 | +33 | 36 |
| MTC Optics | 18 | 0 | 9 | +9 | 0 |
| Meopta | 16 | 0 | 11 | +11 | 0 |
| MewLite | 8 | 0 | 0 | +0 | 0 |
| Nightforce | 57 | 35 | 57 | +22 | 41 |
| Nikko Stirling | 71 | 0 | 28 | +28 | 17 |
| Primary Arms | 12 | 3 | 11 | +8 | 5 |
| Schmidt & Bender | 19 | 0 | 10 | +10 | 3 |
| Sig Sauer | 21 | 0 | 19 | +19 | 4 |
| Sightmark | 16 | 9 | 16 | +7 | 7 |
| Sightron | 40 | 0 | 39 | +39 | 14 |
| Steiner | 40 | 0 | 39 | +39 | 24 |
| Swarovski | 24 | 0 | 0 | +0 | 0 |
| UTG | 15 | 0 | 3 | +3 | 2 |
| Vector Optics | 145 | 103 | 105 | +2 | 49 |
| Vortex | 85 | 85 | 85 | +0 | 0 |
| Zeiss | 29 | 17 | 28 | +11 | 21 |
| **Toplam** | 1209 | 413 | 882 | +469 | 405 |

Ayrıntılı son tablo: `python3 tools/reticle_match_audit.py`. Kalan adlar: `kalan-eslesmeyenler.md`. Marka raporları: `raporlar/`.

## Karar verilemeyenler (tahmin edilmedi)

**Birim farkı — üretici retikülü öbür birimde tanımlıyor (41 ad):**
- UTG Mil-Dot (9 MOA taretli dürbün; üretici "1 milli-radian").
- MTC SCB2, AMD (10 MOA taretli dürbün; üretici mil tabanlı).
- Hawke AMX (1" Airmax, MOA taret; Hawke "mil tabanlı" diyor); Hawke Mil Dot / Mil Dot IR / Half Mil Dot (adı mil, taret MOA).
- Vector Optics German #4 / G4 Fiber / Fiber Center Dot (MRAD taret; üretici yalnız MOA veriyor ya da birim yok). Paragon SCOM-T37 sayfası kendiyle çelişiyor (German #4 ↔ VEPG-T MIL).
- Zeiss #43 (V6 5-30x50 MOA; Zeiss yalnız mrad veriyor).
- Primary Arms ACSS Griffin M10S ve ACSS Nova Fiber Wire (SLx 1-10x28: 1/2 MOA taret, MIL retikül).
- Sig Sauer 5.56/7.62 Horseshoe Dot (TANGO6T MRAD taret; kılavuz "Subtensions in MOA").
- Sightron Mil-Dot (S1 4-12x40 G2 MOA taret; ölçüler "in Mils").
- Kahles SI1 (K16i MRAD; Kahles MOA veriyor).
- Barska Mil-Dot (21) / Trace Mil-Dot: adı mil, taret MOA, birim yazılmamış → kayıt açılmadı.

**Belirsiz (25 → 0):** Hawke AMX IR / FFP AMX IR ve Nightforce MOAR kayıtlarının üretici dürbün listeleri kütüphanedeki model yazımına göre düzeltildi.

**Birimi/ölçüsü yazılmayan, kayıt açılmayan adlar:** Hawke LR2 FD, LR Dot, L4A FD, SR Pro II, Marksman/Rimfire çeşitleri ve diğerleri; Burris X177, Plex 350 Legend Ballistics; Bushnell DOA ailesi, DZ22; GPO G4i ailesi; UTG BG4 BDC, PRO 5-Step, 130 Hunter; Konus Ballistic Circle, Balistico, Advanced ballistic, Aim-Pro; Gamo Mil Dot (sayfalar çelişkili); Schmidt & Bender GR²ID, P5FL, TR²ID, P4FL, MDR-T6, TREMOR3/5 (föyler yalnız ZIP içinde). Hawke "FFP MOA" ve Barska "MOA" adlarının anahtarı boş (yalnız birim sözcüğü) — eşleşemez.

**Boş retikül adı kalan 53 dürbün:**
- Discovery Optics 35: 34 ürün sayfası okundu; hiçbirinde retikül adı yok (yalnız "SFP-MOA" vb.).
- MewLite 8, Gazi Sniper 2: gazisniper.com.tr okunamadı (PROVENANCE_REQUIRED izin hatası).
- Meopta 5: katalog tablosu metin olarak okunurken sütunlar kayıyor; seçenek dürbüne bağlanamadı.
- Konus EL-30 6-24x50 (10 değiştirilebilir retikül), Gamo 3-9X50 Illuminated (tip yazmıyor), Sig Sauer TANGO6 5-30x56 (kılavuz tablosu karışık okunuyor; tahmin edilmedi).

**Bilerek uygulanmayan öneriler:** Steiner T6Xi "SCR [mil]" → "SCR™ - MIL" (aynı retikül olduğu sayfada yazmıyor), Konus F30 "Modified 1/2 Mil dot" (kanıt başka dürbünün sayfası), Leupold FireDot 4 Fine MIL kaydı (föy "UNITS: MOA" diyor).

**Birim yalnız taretten alınan kayıtlar** (üretici ölçü/birim vermiyor; bütün ölçek alanları null, yalnız ad eşleşmesi için; notlarda yazılı): ölçeksiz duplex/plex retiküller (Konus, Gamo, Hawke 30/30 Duplex, Zeiss #60/#20 vb.) ile Athlon BDC17, Kahles 4-Dot/G4B/IPSC, Meopta, Primary Arms Aurora/22LR G2/Duplex Dot, Sightmark CRED-10.

## Okunamayan siteler / belgeler
- deltaoptical.pl: ROBOTS_DISALLOWED (WebFetch), CONNECT 403 (curl). Dolaylı yol denenmedi.
- gazisniper.com.tr: PROVENANCE_REQUIRED (MewLite, Gazi Sniper).
- Hawke: us.hawkeoptics.com/hawke/reticles/*.svg ROBOTS_DISALLOWED; reticles.hawkeoptics.com, reticle.hawkeoptics.com, docs.hawkeoptics.com CLIENT_ERROR. Reticle Booklet docs.google.com'da (izinli değil).
- Schmidt & Bender: Absehen/Reticle/Downloads sayfaları CLIENT_ERROR; föyler ZIP içinde.
- Swarovski: retikül föyleri yalnız ctfassets.net CDN'de (izinli alan değil) → 0 kayıt.
- Sightron, Bushnell, Barska: ayrıntılı föyler cdn.shopify.com'da (izinli değil); Bushnell G5I kılavuzu vault.revelyst.com'da.
- support.sightmark.com: ROBOTS_DISALLOWED. steiner-optics.com/reticles: CLIENT_ERROR.
- Meopta retikül föyleri ve leapers.com Mil-Dot föyü: yalnız görsel, metin yok.
- Vector Optics Veyron kılavuz PDF'i: 2 denemede hata.

## Üretim
```
python3 tools/data_gen/generate_reticles.py
python3 tools/data_gen/generate_scope_library.py --branch origin/data/scopes --branch origin/data/scopes-retikul-3 --read-date 2026-10-12
python3 tools/reticle_match_audit.py --write-fixture
```
Dürbün adı düzeltmeleri `data/scopes-retikul-3` veri dalında (73 kayıt). O dal
`data/scopes`'a birleşince varsayılan `generate_scope_library.py --check` de
aynı çıktıyı verir.
