# Barska: riflescopes missing from ex/barska.json (accessed 2026-10-12)

## Pages read (WebFetch only, shop.barska.com)
- https://shop.barska.com/collections/rifle-scopes (pages 1-4; 56 products in total, no page 5)
- https://shop.barska.com/products/4x32-crossbow-reticle-contour-rifle-scope (AC12182)
- https://shop.barska.com/products/4x32-crossbow-contour-rifle-scope-mossy-oak%C2%AE-break-up%C2%AE-camo (AC12185)
- https://shop.barska.com/products/4x32mm-plinker-22-silver-finish-rifle-scope-with-rings-by-barska (AC10040)
- https://shop.barska.com/products/4x15mm-rimfire-scope-by-barska (AC10000)
- https://shop.barska.com/products/4x20mm-rimfire-scope-by-barska (AC10730)
- https://shop.barska.com/products/3-9x40mm-colorado-30-30-rifle-scope-with-rings-by-barska (CO11492)
- https://shop.barska.com/products/3-9x40mm-colorado-30-30-silver-rifle-scope-with-rings-by-barska (CO11538)

## Result
- 56 products in the collection. All 49 existing source_urls are among them, so 7 are missing and were added as new records.
- Existing records whose page no longer exists (404): none. All 49 existing URLs are still listed in the live collection. Their product pages were not re-fetched one by one.

## Failures
- None.

## Skipped
- None of the 56 are red dots, laser sights, rings or accessories. The two "Trending Items" sidebar products (backpack, lock box) are not riflescopes and are outside the grid.
- Included with a caveat: the 2 Contour Crossbow scopes (AC12182/AC12185). They are titled "Rifle Scope" and have 1/4 MOA turrets, but the reticle is for crossbows. Each is flagged in its notes.

## Fields often missing
- windage travel: the pages give only "Max Elevation Adjustment" (all 7 are null)
- elevation travel: shown as "-" on 3 of 7 pages
- parallax_min_m: none adjustable with a stated distance (all null). The Colorado scopes are fixed "Parallax Free at 100 yds".
- zero_stop: never stated

## Page inconsistencies
- Colorado CO11492/CO11538: the title says 30/30 but the spec table says Duplex. The spec value is used.
- Rimfire 4x15/4x20: each description names the other model's objective size. The spec values are used.
- Crossbow: the features text says "internal" turrets and the spec says "External". The spec also lists a rheostat although Illumination = None.
