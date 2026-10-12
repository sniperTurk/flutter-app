# Nightforce — dürbün verisi (2026-10-12)

**Yeni kayıt: 57** (31 ürün sayfası; MOA+MRAD sunulan modellerde birim başına ayrı kayıt, adın sonuna " MRAD"/" MOA" eklendi).

## Eklenen modeller
- **ATACR (8 model / 16 kayıt):** 1-8x24 F1, 4-16x42 F1, 4-16x50 F2, 4-20x50 F1, 5-25x56 F2, 5-25x56 F1, 7-35x56 F2, 7-35x56 F1 (hepsi MRAD + MOA)
- **NX8 (6 model / 12 kayıt):** 1-8x24 F1, 1-8x24 F1 Capped, 2.5-20x50 F2, 2.5-20x50 F1, 4-32x50 F2, 4-32x50 F1 (hepsi MRAD + MOA)
- **NX6 (10 model / 14 kayıt):** 1-6x24 (MOA), 1-6x24 F1 (MRAD), 2-12x42 (MOA), 2-12x42 F1, 3-18x50 (MOA), 3-18x50 F1, 4-24x50 (MOA), 5-30x56 F1, 6-36x56 (MOA), 6-36x56 F1 (F1'ler MRAD + MOA)
- **NXS (5 model / 6 kayıt):** 2.5-10x42 (MRAD + MOA), 3.5-15x50, 5.5-22x50, 5.5-22x56, 8-32x56 (yalnız MOA)
- **SHV (4 model / 5 kayıt):** 3-10x42, 4-14x50 F1 (MRAD + MOA), 4-14x56, 5-20x56
- **Competition / Benchrest (4 model / 4 kayıt):** Competition 15-55x52, Competition Service Rifle 4.5x24, NF 12-42x56, NF 8-32x56 (yalnız MOA)

## Kapsam dışı bırakılanlar
- Limited Run: ATACR 1-8x24 F1 Green Anodized (renk farkı), ATACR 1-8x24 F1 S-VPS Kit ve 7-35x56 F1 P-VPS Kit (aynı dürbünün kit hâli). Ayrı kayıt açılmadı.
- Hiçbir sayfa "discontinued" değildi.

## Eksik bırakılan alanlar / belirsizlikler
- **objective_mm:** Nightforce teknik tablosunda objektif satırı yok; değer üreticinin ürün adından alındı (her kaydın notunda yazıyor).
- **NXS 3.5-15x50, 5.5-22x50, 5.5-22x56, 8-32x56:** iç ayar aralığı sayfada yok, elevation/windage null.
- **NXS 2.5-10x42:** elevation yalnız ürün açıklamasında (100 MOA / 29 MRAD); windage null.
- **NX8 1-8x24 F1 Capped:** ayar aralığı sayfada yok, null.
- **NX8 1-8x24 F1:** sayfada iki ağırlık var (capped 490 g / ZeroStop 499 g) ve elevation özelliği "Capped, finger-adjustable, or ZeroStop" yazıyor. Bu yüzden weight_g ve zero_stop null.
- **SHV 4-14x50 F1:** elevation tabloda 26 MRAD, açıklamada 27 MRAD yazıyor. Değerler çeliştiği için elevation_travel_mrad null (MOA değeri 90 MOA kullanıldı).
- **SHV 4-14x56 / 5-20x56:** aydınlatmasız ağırlık kullanıldı, aydınlatmalı ağırlık notta.
- **zero_stop:** yalnız "Elevation Feature: ZeroStop™" yazan sayfalarda true. ZeroHold™ (ATACR 4-16x42 F1), ZeroSet™ (SHV) ve FieldSet™ (NX6) sayfalarında "ZeroStop" ifadesi geçmediği için null. Capped sürümlerde de null.
- **Paralaks:** sayfadaki metre değeri kullanıldı. NXS sayfalarında yalnız yard vardı, çevrildi (25 yd → 22.9 m, 50 yd → 45.7 m). Sabit paralakslı dürbünlerde null.
- **Retikül adları:** repodaki yazım kullanıldı ("MOAR™ F1" → "MOAR", "MIL-C™ F1" → "MIL-C", "Horus TREMOR3™" → "Horus TREMOR3" vb.). Repoda karşılığı olmayan iki ad üreticinin yazımıyla bırakıldı: "MOAR-T Dualscale" (ATACR 7-35x56 F2 MOA) ve "SR-2" (Competition SR 4.5x24).
- NX6 sayfalarında SKU alanı boş.

## Kaynaklar (hepsi nightforceoptics.com)
- Liste sayfaları: https://www.nightforceoptics.com/riflescopes ve https://www.nightforceoptics.com/riflescopes?page=2 (toplam 40 ürün)
- Ürün sayfaları: her kaydın `source_url` alanında (https://www.nightforceoptics.com/riflescopes/atacr/…, /nx8/…, /products/nx6/…, /nxs/…, /shv/…, /competition-and-benchrest/…)
- Okunamayan sayfa yok. Toplam 33 WebFetch.
