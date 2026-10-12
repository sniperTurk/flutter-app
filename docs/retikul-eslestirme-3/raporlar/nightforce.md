# Nightforce — retikül raporu (2026-10-12)

**Sonuç:** 2 yeni kayıt, 2 düzeltilmiş kayıt, 0 dürbün düzeltmesi. Eksik 3 adın üçü de çözüldü. Simülasyonda bütün Nightforce dürbünleri "eslesti".

## Eklenen kayıtlar
- **nightforce-moar-t-dualscale-moa — "MOAR-T Dualscale" (moa):**
  - Dürbün: ATACR 7-35x56mm F2.
  - Kaynak: nightforceoptics.com/reticles/moar-t-dual-scale. Sayfa: 2x2 MOA yüzen artı, 1 MOA işaretler, 10/20 MOA rakamlar, 17.5x'te dual scale.
  - Alanlar: `family`=hash, `hash_step`=1, `numbers_every`=10, `floating_center`=true. `center_dot`, uzanımlar ve `posts_start` null. İndirme sayfasında ayrı föy yok.
- **nightforce-sr-2-moa — "SR-2" (moa):**
  - Kaynak: NFO_SR_Reticles_20170920_0.pdf.
  - Föy SR-2 için A–M etiketli MOA değerleri veriyor (A 22 … M 102). Eşleme yalnız çizimde olduğu için `family` ve geometri null.
  - Scopes: "Competition SR Fixed 4.5x24mm" ve kütüphanedeki yazım "Competition Service Rifle 4.5x24mm".

## Düzeltilen kayıtlar ("MOAR | belirsiz" çözümü)
"MOAR" adı iki kayıtta (F1 ve SFP) aynı anahtara düşüyordu. Kayıtların `scopes` girdileri ("ATACR 4-16x42 F1", "NXS 2.5-10x" gibi) dürbün modellerindeki "mm" yazımı yüzünden `names_scope` ile eşleşmiyordu.
- **nightforce-moar (F1):** Yalnız `scopes` ve `notes` değişti.
  - Yeni scopes: ATACR 4-16x42mm F1, 4-20x50mm F1, 5-25x56mm F1, 7-35x56mm F1, B.E.A.S.T. 5-25x56mm F1, NX8 2.5-20x50mm F1, NX8 4-32x50mm F1, SHV 4-14x50mm F1.
  - Kanıt: ürün sayfalarında "MOAR™ F1" ve "Focal Plane: First".
- **nightforce-moar-sfp:** `scopes`, `source_url` ve `notes` değişti.
  - Yeni scopes: ATACR 4-16x50mm F2, ATACR 5-25x56mm F2, NX6 2-12x42mm / 3-18x50mm / 4-24x50mm, NXS 2.5-10x42mm / 3.5-15x50mm / 5.5-22x50mm / 5.5-22x56mm / 8-32x56mm, SHV 3-10x42mm / 4-14x56mm / 5-20x56mm.
  - `source_url` güncel föye çevrildi: content/files/products/MOAR-Reticle-Sheet-2026.pdf. Bu föy NX6 ve "ATACR 16" satırlarını içeriyor.
  - NXS 5.5-22 / 8-32 ve SHV listesi eski SFP föyüne dayanıyor (önceki okuma).
- Geometri alanlarına dokunulmadı.

## Okunamayan
Yok.
