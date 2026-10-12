# Arken Optics — rapor (2026-10-12)

**Eklenen yeni kayıt: 13**

## Mevcut MIL modellerinin MOA sürümleri (8)
- EP-5 GENII 5-25x56 FFP MOA (VPR MOA)
- EP-5 5-25x56 FFP MOA (VPR MOA)
- EP-5 GENII 7-35x56 FFP MOA (VPR MOA)
- EPL-4 4-16x44 FFP MOA (VPR MOA / VHR MOA)
- EPL-4 6-24x50 FFP MOA (VPR MOA / VHR MOA)
- LH-4 4-16x44 FFP MOA (VPR MOA)
- SH-4 GENII 4-16x50 FFP MOA (VPR MOA / VHR MOA)
- SH-4J GENII 6-24x50 FFP MOA (VPR MOA / VHR MOA)

## Yeni modeller (5)
- OUTRIDER 2-12x42 SFP (yalnız MOA; FDR / DLR)
- OUTRIDER 3-18x50 SFP (yalnız MOA; FDR / DLR)
- EP-8 1-8x28 FFP (MIL, KLGRID) ve EP-8 1-8x28 FFP MOA (KLBOX) — 2 kayıt
- LH-6 1-6x24 SFP (yalnız MOA; KLBOX) — arkenopticsusa.com koleksiyonunda "Sold out" işaretli, discontinued değil; arkenoptics.com'da listeli

## Görevde örnek verilen ama sitede OLMAYAN modeller
SH-4 GEN1 4-16x50, SH-4 6-24x50 (GEN1), LH-4 diğer büyütmeler, Halo, Zulus: iki resmi koleksiyon sayfasında (12'şer ürün, sayfalama yok) bulunmuyor → eklenmedi.

## Eksik / null bırakılan alanlar ve belirsizlikler
- Hiçbir sayfada SKU yok.
- SH-4 GENII 4-16x50 FFP MOA: windage_travel_moa = null (sayfa "10 MIL / 50 MOA" diyor; 10 MIL ≈ 34 MOA, çelişkili).
- LH-4 4-16x44 FFP MOA: zero_stop = null (arkenopticsusa.com "Zero Stop: No", arkenoptics.com "Arken Zero Stop" diyor).
- EP-5 GENII 5-25x56 MOA: windage 48 MOA, MIL değeri 12 MIL (≈41 MOA) ile tam örtüşmüyor; sayfadaki MOA değeri yazıldı, not düşüldü.
- Sabit paralakslı modellerde (OUTRIDER 2-12x42, EP-8, LH-6; 100 yd) parallax_min_m = null.
- OUTRIDER: ağırlık FDR (aydınlatmalı) sürümünden; DLR ağırlığı notta.
- EP-8 / LH-6 montajlı paket olarak satılıyor; ağırlığın montajı içerip içermediği belirtilmemiş.
- Retikül adları repodaki yazımla: "VPR MOA", "VHR MOA", "KLGRID", "KLBOX", "FDR", "DLR" (sayfada "VPR-MOA", "KLB-MOA", "KLG-MIL").
- Dönüşümler: in × 25.4, oz × 28.35, yd × 0.9144 (1 ondalık).

## Kaynaklar
- https://www.arkenopticsusa.com/collections/optics
- https://arkenoptics.com/collections/optics
- https://arkenoptics.com/products/lh-4-4-16x44-ffp-capped-tool-less-turrets-illum-vpr-vhr-30mm-tube
- Kayıtlardaki source_url'ler (arkenopticsusa.com/products/...): ep5-gii-5-25x56-..., ep-5-5-25x56-..., ep-5-7-35x56-gen-2-..., epl-4-4-16x44-..., epl-4-6-24x50-..., lh-4-4-16x44-..., sh-4-4-16x50-gen2-..., sh-4j-6-24x50-..., outrider-2-12x42-..., outrider-3-18x50-..., ep-8-1-8x28-..., lh-6-1-6x24-...
