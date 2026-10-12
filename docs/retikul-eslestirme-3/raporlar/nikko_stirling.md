# Nikko Stirling — retikül raporu (okuma: 2026-10-12)

## Eklenen kayıtlar (8)
| id | ad | birim | kaynak |
|---|---|---|---|
| nikko-stirling-4-plex-moa | 4 Plex | moa | Ultimax sayfası/kılavuzu (No. 4A, merkez nokta), Mountmaster SC 4x32 tablo; ölçü yok, birim taret |
| nikko-stirling-no-4-dot-moa | No.4 Dot | moa | Octa / Boar Eater / Diamond sayfaları; ölçü yok, birim taret |
| nikko-stirling-holdfast-moa | HOLDFAST | moa | Hold Fast Reticle Information PDF ("subtensions in MOA", 10x) |
| nikko-stirling-nato-moa | NATO | moa | Diamond Sportsman NATO PDF ("Unit: MOA", 10x/100yds) |
| nikko-stirling-hmd-t-mil | HMD-T | mil | Hornet ED kılavuzu (SFP, MIL, set @25x) |
| nikko-stirling-skeleton-hmd-nato-mil | Skeleton HMD NATO | mil | Diamond FFP sayfası + Reticle User Manual (FFP, mildot) |
| nikko-stirling-prr-mil | PRR | mil | Diamond FFP 34mm sayfası ("MIL-based PRR") + kılavuz |
| nikko-stirling-mrad-xtr-mil | MRAD XTR | mil | MRAD XTR Reticle User Manual (FFP, MRAD) |

Şemalardaki sayıların çoğu metinde öğelere bağlı değil. Bu yüzden geometri alanlarının çoğu null.

## Doldurulan / düzeltilen retikül adları (scope_changes.json, 13 dürbün)
- Mountmaster SC 4x32: "4 Plex, non-illuminated" → "4 Plex"
- Boar Eater 1-4x24, 1-6x24: "No.4 Dot (4 Dot extreme, ...)" → "No.4 Dot"
- Diamond LR 4-16x50 ve 6-24x50 HOLDFAST: → "HOLDFAST"
- Diamond Sportsman 10-50x60 NATO: → "NATO"
- Hornet ED 10-50x60: "HMD-T (illuminated, MIL based)" → "HMD-T"
- Diamond FFP / FFP 34mm Skeleton HMD (4 dürbün): → "Skeleton HMD NATO"
- Diamond FFP 34mm PRR (2 dürbün): → "PRR"

Adı zaten eşleşenler: Ultimax "4 Plex (illuminated)", Octa/Metor/Diamond "No.4 Dot (...)", "MRAD XTR, ...".

## Karar verilemeyenler (birim farkı: mil retikül, MOA taret)
- **Skeleton HMD (Diamond Long Range 4-16x50 / 6-24x50 HMD, ¼ MOA):** HMD PDF retikülü yalnız mil olarak veriyor (1 mil nokta aralığı, 0.5 mil ara işaret, 10x kalibre). MOA değeri yok, kayıt eklenmedi.
- **HMD ve Mil Dot (Diamond Sportsman 10-50x60 HMD/Mil Dot, 1/8 MOA):** Sayfada tablo "HMD / Nato", özellikler "Nato or Mil Dot reticle" diyor. Birim ve ölçü yok, iki retikülden hangisinin olduğu da belirsiz. Kayıt eklenmedi.
- **Half Mil Dot (HMD):** Panamax, Airking ve Mountmaster serileri, aydınlatmalı ve aydınlatmasız dört grup. Mountmaster Silver Crown "HMD (family feature list)" da bu gruba giriyor. Sayfalarda yalnız "Half Mil Dot reticle" yazıyor, taret ¼ MOA. Ad mil tabanlı retikül diyor, MOA ölçüsü yok. Kayıt eklenmedi.
- Mountmaster SC 6x40, 3-9x40, 4-12x40 ve 4x40 AO: Tablodaki retikül hücresi boş, yalnız "HMD reticles" özelliği var. Ad düzeltmesi önerilmedi.

## Okunamayan
Yok. Genel scopemanual_en.pdf retikül bilgisi içermiyor.
