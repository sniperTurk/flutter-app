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
