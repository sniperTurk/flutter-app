# Schmidt & Bender — retikül raporu (okuma: 2026-10-12)

## Eklenen kayıtlar (10)
| id | ad | birim | kaynak |
|---|---|---|---|
| schmidt-bender-fd7-mil | FD7 | mil | S&B Katalog 2026 EN (assets.schmidtundbender.de); duplex, kırmızı nokta; 1. BE'de direkler arası 140 cm/100 m (ortak kayıt olduğu için posts_start null) |
| schmidt-bender-cqb2-mil | CQB2 | mil | Katalog: "fine lines with 0.5 mrad markings", hash_step 0.5 |
| schmidt-bender-l3-mil | L3 | mil | Katalog: aydınlatmalı merkez nokta (birim taret biriminden) |
| schmidt-bender-p3l-mil | P3L | mil | Katalog: mil-dot, "dot to dot is precisely 1 mrad" |
| schmidt-bender-p3-mil | P3 | mil | Katalog: mil-dot (aralık sayıyla verilmemiş, hash_step null) |
| schmidt-bender-sbx-s-mil | SBX-S | mil | Katalog: "identical to the SBX reticle except for the wind hold points" |
| schmidt-bender-lp7-mil | LP7 | mil | Katalog: post-and-crosshair + aydınlatmalı nokta (birim taret biriminden) |
| schmidt-bender-m1fl-mil | M1FL | mil | 10-60x56 CM II 1. FP sayfası: "illuminated mrad-based reticle" |
| schmidt-bender-m2f-2moa-moa | M2F-2MOA | moa | 10-60x56 CM II sayfası: "unbeleuchtetes MOA-Absehen in der 2. Bildebene" |
| schmidt-bender-lrr-mil-mil | LRR-MIL | mil | 5-45x56 PM II HP sayfası; birim yalnız üretici adındaki "MIL"den |

## Düzeltilen mevcut kayıtlar (aynı id, tam dosya)
- **schmidt-bender-msr2-ffp-3-27x56:** `name` "MSR2 (3-27x56 PM II High Power)" → "MSR2" oldu. Eski ad dürbünlerdeki "MSR2" anahtarına düşmüyordu. `scopes` listesine MSR2'yi seçenek olarak listeleyen 6 dürbün eklendi. `notes` alanına düzeltme notu eklendi. Geometri alanları zaten null.
- **schmidt-bender-sbx-ffp-3-18x42:** `name` "SBX (3-18x42 META)" → "SBX" oldu. `scopes` listesine "3-18x42 Meta (1. BE) SBX-S FFP 0.1 mrad" eklendi. `notes` alanına ek yapıldı.

## Karar verilemeyenler (kayıt yok)
- **GR²ID, P5FL, TR²ID, TREMOR5, P4FL, MDR-T6:** Ürün sayfaları retikülü yalnız adı ve görseliyle veriyor. Katalogdaki P4FL metninde birim ya da ölçü yok. Bu retiküllerin ölçü veya birimini veren üretici metni okunamadı. Retikül veri föyleri yalnız ZIP arşivinde ("Data sheets reticle.zip"), WebFetch ile açılamıyor.
- **TREMOR3 (baska-marka):** S&B sayfaları yalnız ad ve görsel veriyor. S&B adına ölçülü kaynak bulunamadı.
- Katalog metni (89.010 karakter) "RETICLES: DEFENCE & COMPETITION" bölümünde P3L'de kesiliyor. Defence retiküllerinin (MSR2, TREMOR3/5, GR²ID, TR²ID, P5FL, M1FL, LRR, MDR-T6) açıklamaları okunamadı.

## Dürbün düzeltmesi
Yok (scope_changes.json boş).

## Okunamayan URL'ler (WebFetch CLIENT_ERROR, en fazla 2 deneme)
- https://www.schmidtundbender.de/Wissenswertes/Absehen/
- https://www.schmidtundbender.de/en/Learn-More/Reticle/ (2 deneme)
- https://www.schmidtundbender.de/Wissenswertes/Downloads/
- https://www.schmidtundbender.de/en/downloads/data-sheets/category/413-a7-fein.html
- https://www.schmidtundbender.de/5-25x56-PM-II-LP-P4FL-1cm-cw-DT-II-MTC-LT-ST-II-ZC-LT/689-911-972-L8-I6
- phocadownload föy denemeleri (Schmidt-Bender-Datasheet-P4FL-FFP-5-25x56-PMII.PDF/.pdf, klasör listesi)
- ZIP arşivleri (Data sheets reticle.zip, Data sheets.zip): içerik WebFetch ile okunamaz.
