# Athlon: missing variants report (accessed 2026-10-12)

Output: athlon_new.json has 33 new records. None of them repeats a source_url in ex/athlon.json (120 records), and none matches an existing series+mag+reticle+unit. The existing file was not modified.

## Method
- The rifle-scopes category page (https://athlonoptics.com/product-category/rifle-scopes/) has no product grid of its own. It lists 17 series sub-category tiles. I read all 17 sub-category grids, none of which is paginated.
- The breadcrumb on a linked variant page led to the Discontinued Rifle Scopes category (https://athlonoptics.com/product-category/discontinued-products/dis-riflescopes/): 29 products, not paginated, none of them in the existing file.
- I spot-checked "Available Reticles" variant links on 3 current product pages (MIDAS HMR GEN2 2.5-15x50 APLR-H2, NEOS HMR 6-18x50 Center-X, TALOS HMR 6-24x50 APLR-H2). Every link matched the series grids. Each discontinued page I read also had its variant links checked, and all of them point to pages in this set.

## Pages read
Category grids: rifle-scopes, cronus-btr-gen2-uhd, ares-etr-gen2-..., athlon-optics-rifle-scopes-ares-btr-gen3-hd, ares-hlr, midas-tac-gen2-hd, midas-hmr-gen2, midas-btr-gen2-riflescope, athlon-optics-rifle-scopes-helos-btr-gen2, athlon-riflescope-helos-btr, heras-spr, argos-btr-gen3, athlon-argos-hmr, athlon-optics-rifle-scopes-talos-btr-gen2, talos-hmr, neos-hmr, athlon-optics-rifle-scopes-talos, athlon-optics-rifle-scopes-neos, discontinued-products/dis-riflescopes.
Product pages: all 33 source_urls in the output plus the 3 spot-checked pages. I also read the athlonoptics.com spec-sheet PDF linked from each product page; each record's notes gives that PDF's URL.

## New records
- Current lineup (4): TALOS HMR 1x24 Center-X; HELOS BTR 1-4.5x24 ATSR3; TALOS BTR GEN2 10x42 AAGR1 MOA; TALOS BTR GEN2 10x42 APRS2A MIL.
- Discontinued (29): MIDAS HMR HD 2.5-15x50 (AHMR, BDC 600A); ARGOS BTR GEN2 (1-8x24 ATSR5, 6-24x50 APMR/APLR2, 8-34x56 APMR/APLR2, 10-40x56 BLR); MIDAS TAC HD (4-16x44 APRS2, 6-24x50 APRS2/APRS3/APLR4, 5-25x56 APRS3/APRS6/APLR4); ARES BTR GEN2 HD (2.5-15x50 APRS5/APLR4, 4.5-27x50 APRS5/APLR3/APLR4); ARES ETR UHD Gen1 (1-10x24 ATMR3/ATMR2, 3-18x50 APRS6/APLR6, 4.5-30x56 APRS1/APRS6/APLR2/APLR5, 15-60x56 BLR1). The notes of every one of these records say "DISCONTINUED".
- Name collisions that are not duplicates: ARES ETR UHD (Gen1) 1-10x24 ATMR2/ATMR3 and MIDAS HMR HD 2.5-15x50 BDC 600A share mag and reticle with existing ARES ETR GEN2 UHD and MIDAS HMR GEN2 records. They are earlier generations, with their own SKUs and pages.

## Failures
None. Every fetch succeeded (no 429s).

## Existing records with dead pages
None found. All 120 existing source_urls are linked from the live series grids. I did not re-fetch them one by one, so a 404 cannot be fully excluded, but nothing points to one.

## Skipped
- Thermal scopes and clip-ons, binoculars, spotting scopes, red dots and prisms (MIDAS/TALOS EDC, FLARE, M3/M5, etc.), rangefinders and accessories: not riflescopes.

## Data issues and fields often missing
- Discontinued product pages have no spec table, so their values come from the spec-sheet PDF on athlonoptics.com that the page links.
- Length: product pages give "Length". Spec sheets only give an unlabeled L1 dimension, which I used as overall length (noted in each record).
- Conflicts that I set to null:
  - TALOS HMR 1x24 weight (page 11 oz vs sheet 16 oz).
  - ARGOS BTR GEN2 1-8x24 zero stop (page says there is one, the sheet says capped turrets).
  - ARES ETR UHD 3-18x50 APLR6 click value (printed "0.1 MOA" with 25 MOA per rotation).
  - Both MIDAS HMR HD 2.5-15x50 records: their sheets list Power 4.5-27X, so I did not trust any table value. Tube, click, travel, length, weight and zero stop are null. The BDC 600A record also has a null click unit.
- Parallax: I set parallax_min_m to null for fixed-parallax scopes (TALOS HMR 1x24, ARGOS BTR GEN2 1-8x24, ARES ETR UHD 1-10x24 x2) and put the fixed distance in notes.
