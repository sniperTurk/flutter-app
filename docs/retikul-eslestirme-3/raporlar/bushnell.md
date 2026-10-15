# Bushnell — retikül raporu (okundu 2026-10-12)

Kaynak yalnız www.bushnell.com ürün sayfaları. Bushnell kılavuzları cdn.shopify.com'da, G5I kılavuzu vault.revelyst.com'da — izinli alan adı
olmadığından OKUNMADI (kural gereği; erişim hatası değil).

## Eklenen kayıtlar (8)
| id | ad | birim | kaynak |
|---|---|---|---|
| bushnell-g5i-mil | G5I | mil | match-pro-3-18x50-riflescope-g5i |
| bushnell-hybrid-dot-tree-moa | Hybrid Dot Tree | moa | r7-4-20x50 / r7-3-15x50 FFP MOA varyantları |
| bushnell-hybrid-dot-tree-mil | Hybrid Dot Tree | mil | r7-4-20x50 / r7-3-15x50 FFP MRAD varyantları |
| bushnell-holdover-moa | Holdover | moa | r7-4-20x50 / r7-3-15x50 SFP MOA varyantları |
| bushnell-holdover-mil | Holdover | mil | r7-3-15x50 SFP MRAD varyantı |
| bushnell-multi-x-moa | Multi-X (MultiX, Illuminated MultiX aynı anahtar) | moa | r7-1-8x24 MOA, r7-2-10x42 (+R5/R3 sayfaları) |
| bushnell-german-4-mil | German #4 | mil | r7-1-8x24 MRAD varyantı |
| bushnell-illuminated-dd2-qa-moa | Illuminated DD2-QA | moa | r5-1-6x24-riflescope-with-illuminated-dd2-qa |

Mevcut kayıtlarda değişiklik yok.

## Dürbün düzeltmeleri (scope_changes.json, 3)
"Dot-Hash Hybrid" -> "Hybrid Dot Tree": R7 4-20x50 FFP MRAD, R7 3-15x50 FFP MRAD, R7 3-15x50 FFP MOA. Üretici retikül adı
"FFP MRAD/MOA ... Hybrid Dot Tree Illuminated Reticle"; "Dot-Hash Hybrid" yalnız "Reticle, Scale" tip satırı. R7 4-20x50 FFP MOA zaten "Hybrid Dot Tree".

## Karar verilemeyen (kayıt yok)
- Illuminated DOA-LRH800 (R5): sayfa 'floating illuminated center dot with BDC drop points out to 800 Yards', '5/10 MPH wind holds' — birim yok.
- DOA Quick Ballistic, DOA Quick Ballistic Ext Eye-Relief (R3): 'drop points out to 600 with 5 MPH wind holds out to 500 yards' — birim yok.
- Drop Zone-22LR (DZ22) (R3): birim/ölçü yok.
Bunlar BDC retikül; taret birimi kuralı yalnız ölçeksiz duplex için olduğundan uygulanmadı. Birim bilgisi muhtemelen kılavuzlarda (cdn.shopify.com, yasak kaynak).

## Notlar
- R7 ürün sayfalarında varyant-retikül eşlemesi yok; her varyant URL'si açılınca ilgili retikül/ölçek satırı okundu.
- Hybrid Dot Tree family=tree yalnız addan çıkarım. G5I '1/10 MRAD intervals' bölgesi belirsiz -> hash_step null.
- Mevcut bushnell-g4p-mil vb. kayıtlar source_url olarak cdn.shopify.com kullanıyor (bu turun kaynak kuralına aykırı; değiştirilmedi, bilgi için).

## Okunamayanlar
Yok (bushnell.com sayfaları açıldı).
