# Dürbün kataloğu — toplama notları (2026-10-10, zamanlanmış çalıştırma)

## Durum: ENGELLENDİ (kısmi)
- Hedef 300+ kayıttı; bu çalıştırmada **1 kayıt** doğrulanabildi (`hawke.json`).
- Neden: Bulut ortamında `curl` ile dış ağ kurum politikası gereği kapalı (CONNECT 403).
  WebFetch çalışıyor ama ilk birkaç sayfadan sonra fetch proxy'si tüm üretici
  sitelerine **HTTP 429 (rate limit)** döndü ve ~20 dakikalık beklemelerden sonra da açılmadı.
- Kural gereği (sadece üretici sitesi, tahmin yok) arama sonucu başlıklarından veya
  mağaza sitelerinden (optics-trade/elitek vb.) veri ALINMADI.

## Kararlar
- `hawke.json` Sidewinder 30 FFP 6-24x56 Half Mil: min paralaks iki ayrı okumada tutarsız
  geldi (biri "9 m / 10 yd – ∞", diğeri "Side Focus", mesafe yok) → `null` bırakıldı.
- Kayıtlara ek olarak `notes` alanı eklendi (dönüşümler/şüpheler için).

## Yeniden denemek için üretici URL'leri (aramada bulundu, okunamadı)
Sayfaları paralel değil, tek tek ve aralıklı çekin.

- Hawke: us.hawkeoptics.com/riflescopes.html, /frontier-30-ffp-5-25x56-mil-pro.html,
  /frontier-30-ffp-5-25x56-moa-hunter.html, /frontier-34-ffp-5-30x56-moa-pro-ext.html,
  /airmax-30-compact-sf-riflescopes.html, /airmax-riflescopes-std.html;
  www.hawkeoptics.com/frontier-30-sf-5-30x56-mil-pro.html
- Vector Optics: vectoroptics.com/rifle-scopes, .../Forester-1-5x24-Fiber-rifle-scope-SCOC-54.html,
  .../Continental-x6-2-12x44-CTR-Rifle-Scope-SCFF-67.html, .../Sentinel-4-16x50-GenII-Rifle-Scope-SCOL-59.html
- Athlon: athlonoptics.com/product-category/rifle-scopes/, /product/argos-btr-gen2-10-40x56-blr-sfp-moa/,
  /product/cronus-btr-gen2-uhd-4-5-29x56-aprs6-ffp-ir-mil/
- Discovery: discoveryopt.com/products/hd-3-12x44-ffp-mpvo, /products/ht-4-16x44, /products/lht-3-12x42,
  /products/discoveryopt-hd-gen2-4-24x50sfir-ffp-mrad-z-l-diameter-34mm-optics-scopes
- Arken: arkenoptics.com/collections/optics, /products/sh-4-4-16x50-gen2-ffp-illuminated-reticle-with-zero-stop-34mm-tube
- Vortex: vortexoptics.com/optics/riflescopes/diamondback.html, /vortex-diamondback-tactical-6-24x50-ffp-riflescope.html,
  /viper-pst-gen-ii-3-15x44-ffp-ebr-2c-mrad.html
- Leupold: leupold.com/shop/riflescopes/series/mark-5hd-rifle-scopes, /mark-5hd-5-25x56-m5c3-ffp-tmr-riflescope
- Nightforce: nightforceoptics.com/riflescopes/atacr/atacr-5-25x56-f1 (+ 1-8x24, 4-16x42, 4-20x50 F1; F2 sürümleri)
- Bushnell: bushnell.com/collections/precision-scopes, /products/match-pro-ed-3-18x50-riflescope
- Sightron: sightron.com/products/siii-long-range-8-32x56, /products/siii-precision-long-range-6-24x50-zero-stop
- Element: element-optics.com/product/helix-ffp/, global.element-optics.com/product/helix-4-16x44-ffp/
- MTC: mtcoptics.com/riflescopes/, /viper-pro/
- UTG/Leapers: leapers.com/products/scopes/utg/accushot.html, /products-utg-scp3-u416aoiew.html
- Nikko Stirling: nikkostirling.com/products/rifle-scopes/diamond-ffp-34mm/nsffp3453056mrad

## 2026-10-10 evening — collected through the owner's Chrome (manufacturer sites only)
| File | Records | Source |
|---|---|---|
| vector_optics.json | 142 | vectoroptics.com product spec tables (3 product pages returned a server error) |
| athlon.json | 120 | athlonoptics.com product pages (no adjustment travel published) |
| vortex.json | 66 | vortexoptics.com embedded spec data, one record per reticle variant |
| barska.json | 49 | shop.barska.com "Detailed Specifications" |
| kahles.json | 16 | kahles.at technical data (travel m/100 m → mrad) |
| element_optics.json | 37 | global.element-optics.com spec tables; MRAD and MOA versions as separate records (2026-10-11) |
| arken_optics.json | 8 | arkenopticsusa.com specifications (MIL version) |
| discovery_optics.json | 36 | discoveryopt.com technical specifications |
| gazi_sniper.json | 11 | gazisniper.com.tr product pages (Gazi Sniper, MewLite); 13 pages publish specs only as images |
Unit rule: travel fields are named *_mrad or *_moa after the turret unit.

## 2026-10-11 — Vortex completed against vortexoptics.com (scheduled run)
- Current riflescope lineup read from the family category pages on vortexoptics.com
  (razor, viper, strike-eagle, venom, diamondback, crossfire, golden-eagle, amg, triumph;
  cross-checked with the use-case category pages): 47 product pages (+2 Venom bundles, not scopes).
- 28 product pages were already in `vortex.json` (66 reticle-variant records); the 19 missing
  product pages were added (one record each — every one of them shows a single SKU): 66 → 85 records.
- New records carry `"accessed": "2026-10-11"` (read date) and the SKU in `notes`.
- `parallax_min_m` is filled only for adjustable parallax (yards × 0.9144); fixed-parallax scopes stay null
  and the fixed distance is in `notes`. `zero_stop` is true only where the page names a RevStop/RZR zero
  system (stated as an inference in `notes`), otherwise null.
- Not used: the `?p=` listing pages and the vortexoptics.widen.net PDFs (robots.txt disallows them).
- Crossfire II 2-7x32 is listed among riflescopes but sold as a crossbow scope (noted in its record).
## 2026-10-11 — Element Optics tamamlama (zamanlanmış çalıştırma, yalnız üretici sitesi)
- Kaynak: global.element-optics.com tüfek dürbünü listesi (2 sayfa, 22 ürün) ve her ürün sayfası;
  eksik değerler için yalnız üreticinin kılavuz PDF'leri (WebFetch ile okundu; curl CONNECT 403).
- 19 → 37 kayıt. Yeni modeller: Immersive Series 10x40, Immersive Series 14x50, HYPR-7.
  Yeni MOA sürümleri: Helix 4-16 FFP, Helix 6-24 FFP/SFP, Helix Gen 2 4-16 FFP, 6-24 FFP/SFP,
  Helix HDLR 2-16 SFP, Titan 5-25 / 3-18, Nexus Gen 2 4-25, Nexus 5-20, Theos 6-36, Immersive 5x30/10x40/14x50.
- Mevcut 19 kayıttaki sayılar sayfalarla yeniden karşılaştırıldı, hepsi aynı. Kayıt adları (ve
  dolayısıyla uygulama kimlikleri) değiştirilmedi; MRAD kayıtlarına MOA kaydı "… MOA" adıyla eklendi.
  Adlar üreticideki başlıklarla aynı (yalnız büyük/küçük harf ve × → x farkı).
- reticle alanı ürün sayfasındaki "Reticle Options" listesinden, birime göre; birden çok retikül " / " ile.
- zero_stop ve parallax_min_m (metre sütunu) dolduruldu; sayfa yarda verdiyse veya "FIXED" ise null.
- Eklenmeyenler: Theos 2-10 MOA (sayfada MOA model seçeneği/klik/kule yok, kılavuz yalnız MRAD);
  HYPR-7 klik değeri yok (dijital taret) → click_value null, uygulama listesine girmez.
