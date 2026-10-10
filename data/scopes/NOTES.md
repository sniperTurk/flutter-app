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
