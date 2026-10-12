# Discovery Optics — retikül raporu (2026-10-12)

**Sonuç:** 0 kayıt, 0 dürbün düzeltmesi. `scope_changes.json` boş.

## Doldurulamayan retikül adları (35 dürbünün hepsi)
34 ürün sayfasının hepsi WebFetch ile okundu (ED-ELR Gen III sayfası MRAD ve MOA kayıtlarının ikisinin de kaynağı). Hiçbir sayfa retikül deseninin adını vermiyor:
- Başlık ve varyant adlarında yalnız odak düzlemi ve birim var (ör. "MS 6-24X44SFIR SFP-MOA-L", "ED-ELR GEN III 5-40X56SFIR FFP-MRAD-Z", "LHD 1-6X24SFIR SFP-1/2MOA-Fiber Reticle").
- Teknik özellik tablosunda "Reticle" satırı yok. Yalnız "Focal Plane", "Click Value" ve "Illumination" satırları var.
- Her sayfada aynı şablon "Reticle Simulator" bulunuyor: "MRAD Reticle" / "MOA Reticle" görselleri ve "FFP · Reticle" etiketi. Görsel dosya adları (HD_GEN_II_530-MRAD.svg, HD_GEN_530-MOA.svg) bütün ürünlerde aynı ve hiçbir yerde retikül adı olarak sunulmuyor, bu yüzden kullanılmadı.
- "SFIR", "AOAC", "SLT", "-Z" ve "-L" kodları tanımsız. Sayfalar bunları retikül adı olarak anmıyor.
- `allowed_domains=discoveryopt.com` ile yapılan aramalarda (VPR/VHR, reticle name, subtension chart) retikül sayfası veya föy çıkmadı.

Yan bulgular (düzeltme önerilmedi): LHD 8-32x50 sayfasının açıklaması "first focal plane (FFP)" diyor, spec satırı ve varyant ise SFP diyor. MS 3-9x50 sayfasının spec tablosunda model adı "MS 3-9X40/50IR" olarak geçiyor.

## Okunamayan
Yok.

## İkinci deneme — feat/discovery-retikul (2026-10-12)
Sahibin dürbünü öncelikli olarak yeniden incelendi. Kaynak yalnız
discoveryopt.com ve www.discoveryopt.com.

**HD GEN II 5-30x56 MRAD — katalogda var.** `lib-` kimliğiyle kütüphanede
görünmüyor çünkü aynı dürbün el ile doğrulanmış katalogda
`discovery-hd-gen2-5-30` ("HD GEN II 5–30×56 FFP-Z (MRAD)",
`lib/data/catalog_repository.dart`) olarak duruyor; üreteç PR #83 kuralıyla
çift kaydı atlıyor. El kaydının değerleri sayfayla birebir aynı: 5-30x, dış
objektif 67 mm, tüp 34 mm, 0,1 MRAD, 33/17 MRAD, 380 mm, 1080 g, FFP, zero
stop. Kimlik değiştirilmedi (kayıtlı profiller bu kimliği kullanıyor olabilir).
`data/scopes-discovery-3` dalında JSON kaydı düzeltildi: model adına MRAD,
`zero_stop: true`, paralaks 25 yd = 22,9 m; MOA kaydına paralaks 22,9 m.

Okunan sayfalar (2026-10-12):
- https://discoveryopt.com/products/hd-gen2-5-30x56 (ve `.json`): spec tablosu,
  varyantlar "HD GEN II 5-30X56SFIR SLT FFP-Z-MRAD" / "…-MOA".
- https://www.discoveryopt.com/HD-GEN-II-5-30X56SFIR-FFP-ZEROSTOP-Optics-Scopes.html: aynı içerik.
- https://discoveryopt.com/products/discoveryopt-hd-gen2-5-30x56-sfir-ffp-z-mrad-diameter-34mm-optics-scopes:
  WebFetch izin isteği zaman aşımına uğradı; arama sonucuna göre aynı ürün.
- https://discoveryopt.com/pages/faq: retikül bilgisi yok.

**Retikül kaydı eklenmedi (0 → 0).**
- Sayfalarda retikül adı yok. "SLT" yalnız varyant/görsel adında geçiyor
  ("SLT FFP-Z-MRAD", "SLT FFP IR-MIL"); sayfa bunu retikül adı olarak
  tanımlamıyor. Tahmin edilmedi.
- Hash aralığı, majorEvery, extent gibi ölçüler hiçbir metinde yok.
- Retikül görselleri (`HD_GEN_II_530-MRAD.svg`, `HD_GEN_530-MOA.svg`),
  "Spec Card" (`HD_GEN-II_5-30X56.webp`) ve "User Manual" (`User_Manual.webp`)
  bu ortamda okunamadı (WebFetch sunucu hatası; curl vekil sunucuda 403).
  PDF kılavuz bağlantısı yok.
- Ürün görselleri cdn.shopify.com'da; izinli alan adı dışında, kullanılmadı.
- discoveryopt.com/blogs sayfaları "blog" kuralı gereği kullanılmadı.
