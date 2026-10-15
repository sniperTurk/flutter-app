# Sightmark — tüfek dürbünleri (2026-10-12)

**Yeni kayıt: 19** (sightmark.com Rifle Scopes koleksiyonundaki 22 ürün sayfasından. Aynı model ve aynı birimde yalnız retikülü farklı olan ürünler birleştirildi: Presidio 3-18x50 LR2/MR2, Presidio 1-6x24 HDR/CR1, Core HX 3-9x40 VHR 350 Legend/450 Bushmaster.)

## Eklenen modeller
Presidio 5-30x56 LR2 FFP, Presidio 3-18x50 FFP (LR2 / MR2), Presidio 5-30x56 HDR2, Presidio 2.5-15x50 HDR-2, Presidio 1-6x24 SFP (HDR / CR1), Presidio 1-10x26 CRED-10, Pinnacle 1-6x24 FFP, Latitude 6.25-25x56 FFP, Latitude 6.25-25x56 SFP, Latitude 8-32x60 SFP, Core TX 4x32 AR-223 BDC, Core TX 1-4x24 SFP, Core 2.0 TX 1-4x24 SFP, Core 2.0 TX 4-16x44 SFP, Core 2.0 HX 4-16x50 SFP, Core 2.0 HX 3-12x56 SFP, Core 2.0 HX 3-9x40 SFP, Core HX 3-9x40 VHR SFP, Strikon VMP 1-4x22.

Sayfada "Sold out" görünenler de eklendi, çünkü hiçbirinde "discontinued" yazmıyor: Presidio 3-18x50 MR2, Presidio 2.5-15x50, Latitude 6.25-25x56 SFP, Core TX 4x32, Core TX 1-4x24, Strikon VMP.

## Boş bırakılan / çelişkili alanlar
- **Presidio 5-30x56 LR2**: objective_mm = null. Spec tablosunda 50 mm, ürün adında 56 yazıyor.
- **Core 2.0 TX 4-16x44**: click_value = null. Key Features "1 MRAD", Specifications ".1 MRAD" diyor.
- **Core TX 4x32 ve Core TX 1-4x24**: taret aralığı null. Sayfada birimsiz "120" yazıyor.
- **Sabit paralaks (100 yd/m)**: parallax_min_m = null. Presidio 1-6x24, Pinnacle, Core TX/2.0 TX 1-4x24, Core 2.0 HX 3-9x40, Core HX VHR, Strikon.
- **zero_stop**: Yalnız sayfa açıkça söylüyorsa true/false yazıldı. Presidio ve Latitude için "built-in zero stops" veya "Zero-stop elevation dial", CRED-10 için "Yes", Strikon için "No". Diğerleri null.
- **Strikon VMP 1-4x22**: Tüpsüz prizmatik değişken büyütmeli nişangah, tube_mm = null. Ağırlık 530 g montaj dahil.
- **Core HX 3-9x40 VHR**: 450 Bushmaster sayfasının spec sekmesi okunamadı. Sayısal değerler 350 Legend sayfasından alındı.
- **Retikül adları**: Repodaki yazım kullanıldı: "Latitude PRS", "Latitude F-Class", "HDR2", "HDR", "MR2", "LR2", "TMD", "Duplex".

## Kapsam dışı / bulunamayan
- **Citadel ve Rapid serileri**: Sitenin güncel Rifle Scopes koleksiyonunda (22 ürün) yoklar. `/collections/citadel` adresi genel riflescopes listesine yönleniyor. Citadel yalnız blog yazılarında geçiyor (blog yasak kaynak). Bu yüzden eklenmedi.
- Hariç tutulanlar: Wraith/Shade (dijital, termal), red dot/Ultra Shot/Volta, büyüteçler, spotting scope ve dürbünler (binocular).
- **products.json** çıktısı yarıda kesildi (5 ürün okunabildi). Liste HTML sayfalarından çıkarıldı (`?page=1..4`).

## Kaynaklar
- https://www.sightmark.com/collections/riflescopes (?page=1..4)
- https://www.sightmark.com/collections/citadel
- Ürün sayfaları: kayıtlardaki `source_url` ve notes alanlarında; ek sayfalar: presidio-3-18x50-mr2-ffp, presidio-1-6x24-cr1-sfp, core-hx-3-9x40vhr-venison-hunter-riflecope-450-bushmaster-reticle
