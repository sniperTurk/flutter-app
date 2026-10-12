# Sightmark — retikül raporu (okuma 2026-10-12)

## Eklenen kayıtlar (7)
| id | ad | birim | ana kaynak |
|---|---|---|---|
| sightmark-cr1-moa | CR1 | moa | Presidio Series kılavuzu |
| sightmark-cred-10-mil | CRED-10 | mil (ölçeksiz; taret birimi) | Presidio 1-10x26 ürün sayfası |
| sightmark-ar-223-moa | AR-223 | moa | Core TX kılavuzu |
| sightmark-ar-556-moa | AR 556 | moa | CORE 2.0 TX kılavuzu |
| sightmark-350-legend-vhr-moa | 350 Legend VHR | moa (ölçü yok; taret birimi) | Core HX VHR 350 Legend ürün sayfası |
| sightmark-450-bushmaster-bdc-moa | 450 Bushmaster BDC | moa (ölçü yok; taret birimi) | Core HX VHR 450 Bushmaster ürün sayfası + kılavuz |
| sightmark-crf-4-mil-mil | CRF-4 MIL | mil | Strikon VMP ürün sayfası + spec föyü |

Kılavuz PDF'leri ürün sayfalarında cdn.shopify.com bağlantısıyla veriliyor (yasak kaynak). Aynı dosyalar üreticinin kendi alan adındaki `https://www.sightmark.com/cdn/shop/files/<dosya>.pdf` yolundan okundu ve kaynak olarak bu adresler yazıldı.

## Dürbün düzeltmeleri
Yok (scope_changes.json boş liste).

## Kararlar
- **CRED-10:** Üretici yalnız "3 MOA dot" diyor, ölçek yok; taret 1/10 MIL. Ölçeksiz SFP nokta retikülü için birim taret birimi (mil) alındı; notta açıkça yazıyor. İsterseniz MOA yapılabilir ama o zaman MIL taretli dürbünle eşleşmez.
- **CR1:** "5 MOA increments" yatay alt çizgi; ızgara ailesi seçilmedi (dikey eksende yanlış çizim olurdu), değer notta.
- **350 Legend VHR / 450 Bushmaster BDC:** Aynı dürbünün iki SKU'su; retikül özel ölçüsü yok. 450BM sayfasından bağlı kılavuz yalnız genel VHR'yi anlatıyor; değerleri notta, kayda yazılmadı.

## Okunamayan
- https://support.sightmark.com/hc/en-us/articles/360061224551-Sightmark-Product-Manual-Download — ROBOTS_DISALLOWED (yeniden denenmedi). CRED-10 ve 350 Legend VHR kılavuzu bu yüzden bulunamadı.
- Strikon VMP kılavuzu (SM23001 ... Manual_PRINT_Rev5.pdf) — metin katmanı yok.
- İlk paralel denemede 5 ürün sayfası izin isteği zaman aşımına uğradı (PROVENANCE_REQUIRED); tek tek yeniden denendi ve okundu.
