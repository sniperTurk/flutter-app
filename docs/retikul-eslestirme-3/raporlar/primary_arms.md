# Primary Arms — retikül raporu (okuma 2026-10-12)

## Eklenen kayıtlar (10)
| id | ad | birim | ana kaynak |
|---|---|---|---|
| primary-arms-acss-nova-fiber-wire-mil | ACSS Nova Fiber Wire | mil (hash 0.5, büyük 2, alt 5 MIL) | ACSS NOVA kılavuzları 1-6x24 / 1-8x24 / 2-12x40 / 1-10x28 |
| primary-arms-acss-nova-5-56-308-fiber-wire-mil | ACSS Nova 5.56/.308 Fiber Wire | mil | 1-6x24 ACSS NOVA 5.56/.308 kılavuzu |
| primary-arms-acss-aurora-5-56-308-yard-mil | ACSS Aurora 5.56/.308 Yard | mil (ölçü yok; taret birimi) | Aurora 5.56/.308 Yards kılavuzu |
| primary-arms-acss-aurora-5-56-308-meter-mil | ACSS Aurora 5.56/.308 Meter | mil (ölçü yok; taret birimi) | Aurora 5.56 Meters kılavuzu |
| primary-arms-acss-aurora-7-62x39-300-blk-yard-mil | ACSS Aurora 7.62x39/.300 BLK Yard | mil (ölçü yok; taret birimi) | Aurora 7.62 Yards kılavuzu |
| primary-arms-acss-raptor-5-56-308-yard-g2-mil | ACSS Raptor 5.56/.308 Yard G2 | mil | PLxC 1.5-12x36 Raptor G2 kılavuzu |
| primary-arms-acss-hud-dmr-308-mil | ACSS HUD DMR 308 | mil | HUD DMR .308 kılavuzu (4-16x44) |
| primary-arms-acss-22lr-g2-moa | ACSS 22LR G2 | moa (ölçü yok; taret birimi) | ACSS 22LR G2 kılavuzu |
| primary-arms-duplex-dot-moa | Duplex Dot | moa (duplex; ölçü yok; taret birimi) | CLx 1-6x24 ürün föyü |
| primary-arms-acss-22lr-moa | ACSS 22LR | moa | PA6X32-22LR kılavuzu + ürün sayfası "Reticle Type MOA" |

Tüm kaynaklar www.primaryarms.com (core/media/media.nl kılavuzları dahil).

## Dürbün düzeltmeleri (scope_changes.json, 1)
- SLx Compact 4-16x44 FFP: "ACSS HUD DMR 308/223" -> "ACSS HUD DMR 308" (HUD DMR 4-16x44 ürün sayfası spec "ACSS HUD DMR 308", açıklama "The ACSS® HUD DMR .308 reticle"; sayfa başlığı 308/223 yazsa da aynı retikül). SLx 3-18x50 Gen II "ACSS HUD DMR 308" ile tek kayıt.

## birim-farki / karar verilemeyen
- **ACSS Griffin M10S (SLx 1-10x28 SFP, turret=moa):** Ürün sayfası taret "1/2 MOA", 40 MOA; retikül tipi "MRAD", "MIL subtensions". Mevcut `primary-arms-acss-griffin-m10s-mil` kaydı (Griffin M10S kılavuzu MIL ızgara) doğru; MOA sürümü üretici tarafından yayımlanmıyor. Kayıt eklenmedi/değiştirilmedi -> birim-farki üretici gerçeği (MOA taretli dürbünde MIL retikül); eşleştirici kuralı gereği eşleşmez.
- **ACSS Nova Fiber Wire (SLx 1-10x28 SFP, turret=moa):** Aynı durum — 1-10x28 NOVA kılavuzu "MIL subtensions"; MOA kaydı uydurulmadı. Bu dürbün dışındaki 3 MRAD dürbün yeni MIL kaydıyla eşleşiyor.
- ACSS Raptor G2 ürün sayfası "Reticle Type MOA" yazıyor, kılavuz "This reticle features MIL (Milliradian) stadia" -> kılavuz esas alındı (notta).
- Aurora (3 varyant), 22LR G2, Duplex Dot: üretici açısal ölçü vermiyor; birim dürbün tareti (notlarda "ölçü yok; birim taret birimi").

## Okunamayan
- https://www.primaryarms.com/primary-arms-slx-1-6x24mm-sfp-rifle-scope-gen-4-illuminated-acss-nova-fiber-wire-reticle — 2 denemede de izin isteği zaman aşımı (PROVENANCE_REQUIRED); bilgi aynı sitedeki kılavuz PDF'lerinden alındı.
- PLxC 1.5-12x36 "MANUAL 1" (id=31332455) ve 1.5-12x36 FFP RDB föyü retikül ölçüsü içermiyor.
