# Schmidt & Bender collection report (accessed 2026-10-12)

## Pages read (WebFetch)
- https://www.schmidtundbender.de/ and https://www.schmidtundbender.de/en/
- Category listings (only worked with `?p=1`): /Jagd/?p=1 (also /Jagd/?p=2 and ?order=name-desc&p=1), /Sport/?p=1, /Defence/?p=1, /en/Hunting/?p=1, /en/Competition/?p=1
- Products: 1-8x24-Exos, 1.5-8x42-Stratos, 2.5-10x56-Klassik, 3-12x42-Klassik, 3-12x50-Klassik, detail/77b13f4b9f4e496d8bf0656d843b5ce3 (3-12x50 Zenith), 3-18x42-Meta-1-BE/158-xxx-xxx-x, 3-18x42-Meta, 4-16x50-Klassik, 10-60x56-CM-II-High-Performance, en/10-60x56-CM-II-High-Performance-1.-FP/160-xxx-xxx, 6-36x56-CM-II-High-Performance and /16A-xxx-xxx, 1-8x24-PM-II-ShortDot-Dual-CC, 3-12x50-PM-II, 3-20x50-PM-II-Ultra-Short, 3-27x56-PM-II-High-Power, 5-20x50-PM-II-Ultra-Short, 5-25x56-PM-II, 5-45x56-PM-II-High-Power, detail/1f98ef957e4e4979afcd647916c721a8 (6-36x56 PM II High Performance)
- https://www.schmidtundbender.de/en/Learn-More/Turrets-Defence-Competition/ (turret abbreviations; ZC = Zero Click, no zero stop described)
- 2026 catalog PDF (DE): https://assets.schmidtundbender.de/media/a5/1f/38/1790781138/S_B_Katalog_2026-V08-DE-LoRes.pdf (2nd try; used for windage travel and 10-60 1.FP mrad data)

## Failures
- https://www.schmidtundbender.de/Jagd/, /Sport/, /Defence/, /en/Hunting/ (without query): "There was an error while fetching" (retried; worked with `?p=1`)
- https://www.schmidtundbender.de/Wissenswertes/Tuerme-Defence-Sport/: fetch error (English equivalent used)
- Catalog PDF first attempt: permission request timed out (second attempt succeeded)

## Models skipped / not found
- Polar T96, Summit, PM II LP/MTC, older Ultra Short / ShortDot variants: not listed in any current category, so treated as not current.
- 1.5-8x42 Stratos: included, but the page has no click/travel/length/weight data and the catalog extract did not include it, so those fields are null.
- 10-60x56 CM II 1. FP: has its own listing URL, but it rendered the default 2nd-FP variant. The record is built from the variant options and catalog data; weight is null because only a range is given.

## Frequently missing / caveats
- Windage travel: product pages show only a number with no unit (e.g. 210, 197, 155). All windage values come from the catalog's ±X figures, doubled to a total, and each case is noted.
- zero_stop: never stated anywhere (null for all). 'ZC' means Zero Click.
- Hunting scopes: cm/100m converted to mrad (÷10).
- Fixed-parallax scopes (100 m): parallax_min_m is null.
- Variant tech data shown on pages are for the default selected configuration. Other turret options are described in the notes.
