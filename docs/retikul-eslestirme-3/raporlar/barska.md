# Barska — retikül raporu (okuma 2026-10-12)

Kaynak: yalnız shop.barska.com ürün sayfaları. Barska kullanım kılavuzu PDF'leri cdn.shopify.com üzerinde
(üçüncü taraf CDN) olduğu için kural gereği okunmadı; ürün sayfalarında hiçbir retikül ölçüsü (aralık, uzanım, nokta boyu) yok.
Bu yüzden tüm kayıtlarda sayısal alanlar null.

## Eklenen kayıtlar (10)
| id | ad | birim | family | dürbün |
|---|---|---|---|---|
| barska-hrs-moa | HRS MOA | moa (adda) | hash ("grid reticle") | 2 |
| barska-trace-moa | Trace MOA | moa (adda) | hash ("grid layout") | 4 |
| barska-hrs-223-bdc-moa | HRS .223 BDC | moa* | null | 1 |
| barska-3g-moa | 3G | moa* | null | 2 |
| barska-30-30-moa | 30/30 | moa* | null | 17 |
| barska-easy-shot-moa | Easy Shot | moa* | null | 1 |
| barska-4a-moa | 4A | moa* | null | 1 |
| barska-4a-mil-plex-moa | 4A, Mil-Plex | moa* | null | 1 |
| barska-crossbow-moa | Crossbow | moa* | null | 2 |
| barska-duplex-moa | Duplex | moa* | duplex | 2 |

\* Üretici ölçü vermiyor; birim taret birimi (sayfada Click Value MOA) — notes'ta belirtildi.
30/30 için family null bırakıldı: sayfa yalnız "standard crosshair grid alignment" diyor, direk yapısını tarif etmiyor.

## Dürbün düzeltmeleri (scope_changes.json, 1)
- 4-16x40mm Varmint IR: "Mil Dot" → "Mil-Dot" (sayfa özellik listesinde "Mil-Dot"; "Mil Dot" yazımı eşleştiricide MIL'i birim sayıp anahtarı "DOT"a düşürüyor).

## Karar verilemeyenler
- **Mil-Dot (21 dürbün) ve Trace Mil-Dot (1)**: retikül adı mil diyor, taretler MOA (1/4, 1/8, 1/2 MOA); Barska hiçbir sayfada
  nokta aralığı ya da birim vermiyor. MOA birimli kayıt retikülün ölçeğini yanlış gösterir, mil birimli kayıt eşleştiricinin taret kuralına takılır.
  Ölçü kaynağı (kılavuz) yalnız cdn.shopify.com'da. Kayıt oluşturulmadı; lider karar vermeli.
- **"MOA" (4-16x50mm LEVEL IR)**: sayfa retikülü yalnız "MOA" ve "advanced illuminated grid reticle" diye adlandırıyor. Ad anahtarı boş
  (yalnız birim sözcüğü), kayıt eşleşemez. Aynı Level serisinin 1.5-6x44 modeli "HRS MOA" diyor ama bu sayfa HRS demiyor; düzeltme önerilmedi.

## Duplex notu
- 3-9x40mm Colorado 30/30 halkalı (siyah ve gümüş) dürbünlerinin model adında 30/30 geçiyor ama sayfanın retikül satırı "Duplex"; kayıt sayfaya göre "Duplex".

## Okunamayanlar
- İlk 4 ürün sayfası (level-1-5-6x44mm-ir-moa, level-4-16x50mm-ir-moa, 1-6x-24mm-level-hd-ffp, 1-4x-24mm-level-hd) ilk denemede
  izin isteği zaman aşımı (PROVENANCE_REQUIRED); 2. denemede okundu.
- Tüm kılavuz PDF'leri (cdn.shopify.com/s/files/1/0743/9102/8034/...) kural gereği okunmadı.
- Okunmayan (gerek görülmeyen) dürbün sayfaları: 30/30 grubunun 16'sı, Mil-Dot grubunun 18'i, Trace MOA Varmint 5-20x50 ve 10-40x60 V2, Point Black 6-24x40, gümüş Colorado; adlar girdi listesinden.
