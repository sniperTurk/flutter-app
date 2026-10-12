# Athlon — retikül raporu (okuma 2026-10-12)

Kaynak: yalnız athlonoptics.com (ürün sayfaları ve /wp-content/uploads, /storage altındaki retikül föyü PDF'leri).
Föylerdeki A1–D3 etiketli tablo değerleri metinde öğelere bağlanmadığı için hiçbir kayıtta kullanılmadı.

## Eklenen kayıtlar (22)
| id | ad | birim | family | not |
|---|---|---|---|---|
| athlon-optics-ahmr2-ffp-ir-moa | AHMR2 FFP IR MOA | moa | tree | birim-farki çözümü; ayrı MOA föyü |
| athlon-optics-center-x-moa | Center-X | moa | duplex | Talos HMR, Neos HMR (+Turret), Talos, Neos |
| athlon-optics-bdc17-moa | BDC17 | moa | null | föyde birim yok; birim taret birimi |
| athlon-optics-bdc-600-moa | BDC 600 | moa | null | BDC600 / BDC 600 yazımları aynı anahtar |
| athlon-optics-aplr-h2-moa | APLR-H2 | moa | hash | hash_step 2, extent_v_up 10 |
| athlon-optics-bdc-250-muzzleloader-moa | BDC 250 Muzzleloader | moa | null | 3 dürbün düzeltmesiyle |
| athlon-optics-bdc-22-rimfire-moa | BDC 22 Rimfire | moa | null | 2 dürbün düzeltmesiyle |
| athlon-optics-bdc-500-moa | BDC 500 | moa | null | |
| athlon-optics-bdc-250-shotgun-moa | BDC 250 Shotgun | moa | null | 1 dürbün düzeltmesiyle |
| athlon-optics-bdc-300-straightwall-moa | BDC 300 Straightwall | moa | null | |
| athlon-optics-mil-dot-mil | Mil-Dot | mil | mildot | föy "SUBTENSIONS IN MIL" |
| athlon-optics-ahmc1-moa | AHMC1 | moa | duplex | merkez nokta, yüzen |
| athlon-optics-bdc-600a-moa | BDC 600A | moa | null | |
| athlon-optics-ahmc1-fiber-dot-moa | AHMC1 Fiber Dot | moa | duplex | fiber merkez nokta |
| athlon-optics-atmr2-ffp-ir-moa | ATMR2 FFP IR MOA | moa | null | 1.2 MOA merkez nokta |
| athlon-optics-atmr6-sfp-ir-moa | ATMR6 SFP IR MOA | moa | null | 2 MOA merkez nokta, 4x |
| athlon-optics-cb100-sfp-ir-moa | CB100 SFP IR MOA | moa | null | arbalet |
| athlon-optics-atmr4-sfp-ir-moa | ATMR4 SFP IR MOA | moa | null | 10x |
| athlon-optics-atsr4-sfp-ir-moa | ATSR4 SFP IR MOA | moa | tree | 1.4 MOA nokta, 6x |
| athlon-optics-atsr5-sfp-ir-moa | ATSR5 SFP IR MOA | moa | tree | 1.4 MOA nokta, 8x |
| athlon-optics-atsr2-sfp-ir-moa | ATSR2 SFP IR MOA | moa | tree | boş adlı Cronus dürbünü için |
| athlon-optics-blr1-sfp-ir-moa | BLR1 SFP IR MOA | moa | hash | 0.5 MOA adım, 0.09 yüzen nokta, çizgi 0.018 |

Kaynak URL'leri her kaydın `source_url` ve `notes` alanında. Eksik listesindeki 66 dürbünün tamamı ve boş adlı 5 dürbün, `tools/reticle_match_audit.py` eşleştiricisiyle (önerilen düzeltmeler uygulanınca) bir kayda düşüyor.

## Dürbün düzeltmeleri (scope_changes.json, 13)
- TURRET CENTER-X → Center-X (2; föy "THE ATHLON® CENTER X RETICLE", TURRET dürbünün taret seçeneği)
- BDC250S SHOTGUN → BDC 250 Shotgun (1)
- BDC22 → BDC 22 Rimfire (2)
- BDC250M MUZZLELOADER / BDC250MMUZZLELOADER / BDC 250 → BDC 250 Muzzleloader (3)
- Boş retikül adları: APLR11, ABLR4, APRS11 (2), ATSR2 (Cronus). APLR11/ABLR4/APRS11 mevcut kayıtlara düşer; ATSR2 için yeni kayıt eklendi.

## Birim-farki / belirsiz kararları
- AHMR2 (HELOS BTR GEN2 2-12x42, MOA taret): üretici ayrı bir MOA retikül föyü yayımlıyor
  (Athlon-AHMR2-FFP-IR-MOA-Reticle-Manual-Helos-BTR-GEN2.pdf). Mevcut athlon-optics-ahmr2-ffp-ir-mil kaydı doğru, yalnız MIL;
  dürbün yanlış eşlenmemeli. Yeni MOA kaydı eklendi; mevcut kayıt değiştirilmedi.
- Mil-Dot / MILDOT (baska-marka): Athlon'un kendi MIL-DOT föyleri var; Athlon kaydı eklendi (mil).

## Dikkat / tutarsızlıklar
- TALOS 6-24x50 BDC 600 IR: ürün sayfası URL'si "…-ahmr-sfp-moa", "Available Reticles" kısmında ATMR1 SFP IR MIL; başlık ve bağlı föy BDC 600 IR. Kayıt föye göre.
- ARGOS BTR GEN3 10-40x56: açıklamada "the BLR SFP MOA reticle" yazıyor; başlık ve föy ABLR4 → ABLR4 seçildi.
- TALOS HMR 1x24 CENTER-X: Center-X föyü yalnız 3-12x50 ve 4-16x56 için referans büyütme veriyor; 1x24 föyde anılmıyor.
- Neos HMR föylerinin çoğunda birim yazmıyor; birim aynı adlı eski Neos/Talos föylerinden ("SUBTENSIONS IN MOA") ve MOA taretten alındı. BDC17'de hiçbir föyde birim yok (birim taret birimi).
- family seçimi föydeki tarife dayanıyor (duplex: kalın direkten ince artıya; tree: merkez altında düşüş + rüzgâr noktaları). Geometri tarif edilmeyen BDC'lerde family null.

## Okunamayanlar
- https://athlonoptics.com/wp-content/uploads/2026/03/Neos-HMR-BDC17-Reticle-Manual.pdf — ilk denemede sunucu hatası (SERVER_ERROR), 2. denemede okundu.
- https://athlonoptics.com/wp-content/uploads/2026/03/Neos-HMR-BDC250S-IR-Reticle-Manual.pdf — ilk denemede proxy 504 zaman aşımı, 2. denemede okundu.
- Kalıcı okunamayan URL yok. Okunmayan (gerek görülmeyen) sayfalar: eski Talos 3-12x40 MILDOT, Talos 3-12x40 BDC 600 IR, Neos 3-9x40 BDC 22, Neos 3-9x40/6-18x44 CENTER X, NEOS 4-12x40 BDC 500 ürün sayfaları (aynı ürün ailesinin föyleri okundu).
