# Sightron — retikül raporu (okundu 2026-10-12)

Kaynak: yalnız sightron.com ürün sayfaları (28 sayfa, hepsi okundu). Ayrıntılı retikül PDF'leri ve ölçülü görseller
cdn.shopify.com üzerinde → kural gereği OKUNMADI. Sayfalardaki ölçü tabloları yalnız A, B, C… sütun harfi taşıyor
(anlamları tanımsız), bu yüzden değerler alanlara yazılmadı, notlara aynen aktarıldı. Sayısal alanlar yalnız metinde
açıkça yazanlardan dolduruldu (ör. "hash marks at .2 MIL spacing" → hash_step 0.2).

## Eklenen kayıtlar (27) — reticles/
| id | ad | birim | family | hash_step | not |
|---|---|---|---|---|---|
| sightron-lrm-mil | LRM | mil | hash | 0.2 | FFP, yüzen merkez nokta |
| sightron-mh-6-mil | MH-6 | mil | hash | 0.2 | FFP, yüzen merkez nokta |
| sightron-mh-h-mil | MH-H | mil | hash | 0.2 | FFP, yüzen merkez nokta |
| sightron-mh-7-mil | MH-7 | mil | hash | 0.2 | FFP, merkez artı |
| sightron-mh-5-mil | MH-5 | mil | null | 0.2 | SFP |
| sightron-mh-4-mil | MH-4 | mil | hash | null | FFP, center_dot=false ("solid crosshair … instead of the traditional dot") |
| sightron-mh-2-mil | MH-2 | mil | hash | 0.5 | FFP, center_dot=false |
| sightron-mil-hash-mil | Mil-Hash | mil | hash | 0.5 | SFP |
| sightron-mh-ft-mil | MH-FT | mil | null | null | SFP |
| sightron-moa-2-moa | MOA-2 | moa | hash | 2 | SFP; "MOA-2 @24x" (SIII LR 8-32x56) |
| sightron-moa-h-moa | MOA-H | moa | hash | 2 | PLR FFP 6-24x50'de FFP, diğerlerinde SFP |
| sightron-moa-5-moa | MOA-5 | moa | hash | 2 | FFP |
| sightron-moa-8-moa | MOA-8 | moa | hash | null | FFP ("hash marks 1 and 2 MOA" belirsiz) |
| sightron-moa-3-moa | MOA-3 | moa | null | null | FFP (S-TAC FFP) / SFP (S-TAC 3-16x42) |
| sightron-moa-7-moa | MOA-7 | moa | null | null | SFP, tarif yok |
| sightron-moa-bd-moa | MOA-BD | moa | null | null | SFP, bracket dot |
| sightron-moa-ftd-moa | MOA-FTD | moa | null | null | SFP; ölçü yok, birim taret birimi |
| sightron-moa-2ft-moa | MOA-2FT | moa | null | null | SFP |
| sightron-moa-20-moa | MOA-20 | moa | null | null | SFP, tarif yok |
| sightron-target-dot-1-moa | Target Dot .1 | moa | null | null | .1 MOA merkez nokta |
| sightron-target-dot-125-moa | Target Dot .125 | moa | null | null | 1/8 MOA merkez nokta |
| sightron-fine-cross-hair-moa | Fine Cross Hair | moa | null | null | ince artı |
| sightron-ir4a-moa | IR4A | moa | null | null | tarif yok |
| sightron-hhr-moa | HHR | moa | null | null | Hunter Holdover, tarif yok |
| sightron-duplex-moa | Duplex | moa | duplex | — | 7 dürbün |
| sightron-silhouette-moa | Silhouette | moa | null | null | tarif metni genel duplex metni → family null |
| sightron-mil-dot-mil | Mil-Dot | mil | mildot | null | **birim uyuşmazlığı, aşağıda** |

Adlar IR soneksiz yazıldı (eşleştirici IR'yi atar; "MOA-2" ve "MOA-2 IR" aynı anahtar). Repo eşleştiricisinin
scratchpad kopyasında (tools/reticle_match_audit.py) Sightron 40 dürbünün 39'u eşleşti.

## Doldurulan retikül adları
Yok (boş retikül adlı Sightron dürbünü yok). scope_changes.json boş.

## Karar verilemeyen / dikkat
- **Mil-Dot (S1 4-12x40 G2)**: taret "1/4 MOA", üretici ölçüleri "Mil-Dot Measured in Mils" → kayıt unit=mil. Birim kuralı
  gereği MOA taretli dürbünle eşleşmez (audit: birim-farki). MOA kaydı üretmek üreticinin söylemediği bir birim olurdu; karar sahibin.
- **MOA-H, MOA-3**: aynı ad hem FFP hem SFP dürbünlerde; tek kayıt, notta belirtildi.
- **MOA-7 (S6 5-30x56 ED)**: sayfadaki talimat PDF adı "MOA-8_Reticle_Instructions" — sayfa içi tutarsızlık; kayıt spec tablosundaki MOA-7 adıyla.
- **HHR (S1 4-12x40 G2)**: tablo başlığı hatalı olarak "Duplex Measured in MOA" yazıyor.
- MOA-BD, MOA-FTD ve Mil-Hash sayfalarda "Coming Soon".

## Okunamayan
- Hiçbir sightron.com sayfasında hata yok. cdn.shopify.com PDF/görselleri kural gereği okunmadı (izinli alan değil).
