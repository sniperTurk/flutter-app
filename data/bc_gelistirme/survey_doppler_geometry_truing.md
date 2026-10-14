# Survey: getting a real BC for bullets/factory loads without a published BC

Read date for every source: **2026-10-14** (WebFetch/WebSearch only). Quotes are verbatim and 25 words or fewer. Some quotes come from WebFetch's extraction of the page, so the exact wording should be spot-checked before it is quoted in the app.
Prior repo findings (data/drag-curves/INDEX.md) were not redone. Not fetched: rws-ammunition.com and JSB (blocked by robots.txt). No forums, blogs, dealers or ballistic-app data were used. accurateshooter.com search hits were ignored.

---

## 1. Manufacturer Doppler / drag data and how BCs are measured

| Maker | What is published | How it is measured (maker's words) | Format |
|---|---|---|---|
| Hornady | G1 and G7 BCs at Mach 2.25, 2.0 and 1.75 for ELD Match, ELD-X, A-Tip and ELD-VT. The 4DOF drag curves exist only inside the calculator. | FAQ: "All ballistic coefficients (BCs) were determined using Doppler radar by measuring bullet velocity as a function of distance" (https://www.hornady.com/support/faqs/how-can-you-claim-such-high-bcs). /bc: "Hornady BC values have been corrected back to International Civil Aviation Organization (ICAO) Standard Atmosphere" (https://www.hornady.com/bc). External ballistics page: "Our ELD-X® and ELD® Match bullets are measured with Doppler radar at extended distances." Older bullets: "Ballistic coefficients for all Hornady Bullets were determined by computer calculations" (https://www.hornady.com/team-hornady/ballistic-information/ballistic-resources/external-ballistics) | HTML tables (/bc). Ammo product pages show **no BC**, only a velocity table. |
| Lapua | G1 and G7 per bullet and cartridge. A QTU Doppler package is offered (see INDEX.md). | Catalog 2024: "For ultimate accuracy and precision, Lapua uses radar based data for all tactical projectile ballistics." (https://www.lapua.com/wp-content/uploads/2024/02/Lapua_Catalog_2024.pdf). QTU brochure: "extremely accurate Doppler radar measurements of bullet trajectories." (https://www.lapua.com/wp-content/uploads/2019/03/QTU-Lapua-Edition.pdf). Product pages do not mention Doppler. | HTML product pages and a PDF catalog. |
| Berger | G1, G7 and G7 form factor for each bullet. | "Berger Bullets uses live fire, doppler radar test data fired at long range to measure BC." and "we advertise the average BC from 3000 fps to 1500 fps." (https://bergerbullets.com/nobsbc/variation-in-bc-with-velocity/). Product page: "Doppler Radar verified with less than 1% BC variation." (https://bergerbullets.com/product/6-5-mm-144-grain-long-range-hybrid-target/) | HTML spec table. |
| Sierra | G1 BCs in velocity bands. Above 1200 fps and below 900 fps each have their own value; the transonic band uses an average. | Firing tests: "requires simultaneous measurement of muzzle velocity and time of flight to a measured range, for each round fired." Three screens and two chronographs, with the downrange screen at about 150 ft for rifles. "we believe that the total error in the measured ballistic coefficient is no larger than two percent." (https://www.sierrabullets.com/exterior-ballistics/4-3-how-the-ballistic-coefficient-is-measured-by-firing-tests/). The bands come from https://www.sierrabullets.com/exterior-ballistics/4-5-ballistic-coefficient-variations-with-muzzle-velocity-near-the-speed-of-sound/ | Product-page spec and ballistics tabs load dynamically and could not be read with WebFetch. |
| Nosler | G1 and G7 listed on product pages. | Method not stated on https://www.nosler.com/accubond-long-range-bullet. | HTML. |
| Barnes | G1 is given in the product text, e.g. "an impressive G1 ballistic coefficient of .486" (https://barnesbullets.com/vor-tx-rifle-tsx-28-nosler-162-gr-bt/). | Not stated on the maker's site. The Doppler claims found were on a blog and were not used. | Spec and ballistics tabs are dynamic and could not be read. Ballistics-chart PDFs exist (see §5). |
| Norma | A single G1 BC per load, e.g. "0.373 G1" for Whitetail 6.5 CM 140 gr. | Not stated. The FAQ has no BC method (https://www.norma-ammunition.com/en-us/faq/ballistics). | HTML product pages. |
| Sako | One BC per load, model not labeled, e.g. 0.526 on TRG Precision. | Not stated, no Doppler mentioned (https://www.sako.global/ammunition/trg-precision). | HTML. |
| SWISS P (RUAG/Beretta) | The factsheet gives G1 **and** G7 BCs **and** a drag coefficient at three velocities. Example from .308 Tactical: 820 m/s G1 0.3032 / G7 0.1569 / Cd 0.4783; 340 m/s 0.2173 / 0.1737 / Cd 0.5233; 200 m/s 0.2729 / 0.1582 / Cd 0.2183. Reference "15 °C, 1013.25 hPa, 0% humidity". | Method not stated (no Doppler mention). | PDF factsheet: https://www.swiss-p.com/images/content/products/Factsheets/SWISS-P_factsheet_308WinTactical_web.pdf, which redirects (302) to the maker's own Squarespace file host https://static1.squarespace.com/static/665d8685c4bf3a55ab1aae71/t/67a3782a958eff15f3a2a113/1738766379416/Sniper_factsheet_308+Win+Tactical_hr.pdf. The product page lists only "0.4893 ICAO" for Target 168 gr (https://swiss-p.com/en/sniper/p/308-win-swiss-p-target-10-9-g-168-gr). |
| Federal | G1 and G7 on Gold Medal pages, e.g. GM308M ".462" / G7 ".224". | Not stated (https://www.federalpremium.com/rifle/gold-medal/gold-medal-sierra-matchking/11-GM308M.html). | HTML. |
| RWS | Not fetched because robots.txt blocks it. | — | — |

---

## 2. Geometry publication usable for McDrag-type prediction

McDrag inputs are length, nose length, headshape/ogive radius ratio, meplat diameter, boat-tail length and angle, base diameter and band diameter (see §3).

| Maker | Geometry fields published | Source / quote |
|---|---|---|
| **Berger** | **OAL, Base to Ogive, Nose Length, Bearing Surface, Boat Tail Length**, Ogive Style and G7 form factor. There is **no meplat, ogive radius or boat-tail angle**. | 6.5 mm 144 gr LRHT: "OAL 1.413", "Base to Ogive 0.724", "Nose Length 0.742", "Bearing Surface 0.469", "Boat Tail Length 0.188" (https://bergerbullets.com/product/6-5-mm-144-grain-long-range-hybrid-target/). Litz on what drives drag: "Only the nose length, nose profile, meplat diameter, boat tail angle and boat tail length dictate" (https://bergerbullets.com/form-factors-a-useful-analysis-tool/). |
| Hammer | **Length only**. The BC is labeled as estimated. | "Bullet length is 1.407″" and "G7-BC=.227 estimated" (https://hammerbullets.com/product/308-cal-166gr-hammer-hunter/) |
| Lapua | **No length** on bullet pages or in the 2024 catalog. Diameter and weight only. | GB550 page: BC G1 "0.490", G7 "0.247", no length (https://www.lapua.com/product/30-scenar-l-bullet-gb550-113-g-175-gr-otm/). The catalog has no drawings (https://www.lapua.com/wp-content/uploads/2024/02/Lapua_Catalog_2024.pdf). |
| Sierra | A qualitative ogive description only, e.g. "A sleek 27 caliber elongated ogive". The spec tab is dynamic and could not be read. | https://sierrabullets.com/6-5mm-150-gr-hpbt-cn-matchking-smk/ |
| Hornady | No length on the ELD Match line page. Per-bullet pages were not checked. | https://www.hornady.com/bullets/eld-match |
| Barnes, Nosler | No geometry seen. The Barnes tabs are dynamic. | (pages above) |
| Cutting Edge | A "Technical Data Sheets" PDF is linked from https://cuttingedgebullets.com/pages/reloading-resources (https://cdn.shopify.com/s/files/1/0838/7185/8986/files/Tech_Data_Sheets_2026.pdf). **BLOCKED**: the permission request for this URL got no answer, so the fields are unknown. | — |

Conclusion: only Berger publishes enough dimensions to come close to a McDrag input deck, and even Berger leaves out the meplat diameter, ogive radius and boat-tail angle. Those would have to be assumed.

---

## 3. Literature: accuracy of geometry-based drag prediction

- **MC DRAG**: McCoy, R. L., *"MC DRAG" – A Computer Program for Estimating the Drag Coefficients of Projectiles*, BRL Technical Report ARBRL-TR-02293, Feb 1981 (https://apps.dtic.mil/sti/pdfs/ADA098110.pdf). This is the documented successor of the 1974 BRL MR 2385, which was not located or fetched.
  - "estimates drag coefficient to within 3% error" at supersonic speeds. "11% error at transonic speeds". "6% error at subsonic speeds". These are given as one-sigma figures.
  - Transonic error "grows to a maximum of 11% at M = 0.95."
  - "The largest errors at transonic speeds occur for boattailed projectiles."
  - Valid "over a Mach number range of 0.5 to 5 and a projectile diameter range of 4 to 400 millimetres." Boat-tail correlation "valid for boattail lengths up to 1.5 calibers."
  - A hemispherical nose "is too blunt for the program to give reasonable accuracy."
- **NSWC Aeroprediction code**: Moore and McInville, *Nonlinear Aeroprediction Methodology for Roll Positions 0 and 45 Degrees*, NSWCDD, about 1995–96 (https://apps.dtic.mil/sti/pdfs/ADA318705.pdf): "average accuracy levels of ±10 percent on normal and axial force coefficients". "Exceptions to this are at subsonic Mach number and high angle of attack". This is for missile-type bodies, not small arms.
- **PRODAS / DATCOM**: no primary source giving a numerical small-arms Cd accuracy was found. Leśnik et al. 2022 (Problems of Mechatronics 13(3), https://yadda.icm.edu.pl/baztech/element/bwmeta1.element.baztech-3b8a4347-9d61-4272-adc9-81634cb3c7a0/c/99_112_Lesnik.pdf) used PRODAS 3.5 for 7.62×51 but gives no error figures and says the results "require verification during actual shooting exercises."
- **Measured small-arms reference**: McCoy, *The Aerodynamic Characteristics of 7.62mm Match Bullets*, BRL-MR-3733, 1988 (https://apps.dtic.mil/sti/tr/pdf/ADA205633.pdf). It is spark-range measured and makes no prediction comparison.
- **Maker statements**: Sierra says BC is "not really a predictable parameter" and that "Ballistic Coefficients Must Be Determined by Firing Tests" (https://www.sierrabullets.com/exterior-ballistics/4-4-lessons-learned-from-ballistic-coefficient-measurements/). Berger/Litz, quoted in §2, say drag depends on nose length and profile, meplat, and boat-tail angle and length.

Implication: a G7 BC predicted from geometry carries about 3% (1σ) Cd error above Mach 1.2 and up to 11% transonic. With assumed meplat and boat-tail angle it will be worse.

---

## 4. Truing: measurement uncertainty and maker guidance

- **Sierra, two-chronograph time of flight**: "total error in the measured ballistic coefficient is no larger than two percent". The muzzle chronometer error is "no worse than one part in 5000" and the distance tolerance is "1/16 inch, or one part in 2000" (Sierra 4.3, URL in §1). The downrange screen is at about 150 ft, so this is a short-baseline method.
- **Courtney, Morris and Courtney, amateur Doppler (LabRadar)** (arXiv:1608.06500 preprint, https://arxiv.org/pdf/1608.06500): "drag coefficients can be determined with an accuracy of 1% or better" when signal-to-noise is adequate. Optical chronographs give "an accuracy of 1-2%". It found a "measured G1BC (0.264) significantly lower than the value claimed by Hornady (0.290)" for the 53 gr V-MAX. Winchester's published trajectory "corresponds to a G1BC of 0.206" against 0.187 measured, which bears directly on back-solving in §5.
- **Courtney et al., two optical chronographs 91.44 m apart** (arXiv:1510.07336 preprint, https://arxiv.org/pdf/1510.07336): "The uncertainties in the mean values of each supersonic drag coefficient were under 2%". After cross-calibration, "variations between chronographs were reduced to 0.1%."
- **Oehler M35 manual**: "To measure ballistic coefficients, use one M35P at the muzzle and a second one downrange." "a spacing of at least 4 feet is preferred and 8 feet is still better." It also says to verify both systems side by side first (https://oehler-research.com/wp-content/uploads/2017/11/M35-Instr-2015-PC.pdf). The spec page says "4.0 MHz oscillator for 0.25 microsecond time resolution". Its table gives a single-shot error of about 3 fps at 4000 fps with 8 ft spacing (https://oehler-research.com/specifications/). **The Oehler System 89 page (https://oehler-research.com/system-89/) currently serves gambling-spam content and was ignored as compromised.**
- **LabRadar FAQ**: "LabRadar has an accuracy of 0.1%." It "will typically measure the velocity of a 7.62 mm projectile from muzzle up to 100 yards." (https://mylabradar.com/faq/)
- **Garmin Xero C1 manual**: rifle "+/- 0.1% of the target velocity". Bow, pistol and air rifle "+/- 0.4% of the target velocity". (https://www8.garmin.com/manuals/webhelp/GUID-76BF3BAE-91A9-4BF6-9196-26F824CA8CAD/EN-US/GUID-37BB8707-08A8-43E9-885E-7A3E9C55E7F8.html)
- **Hornady 4DOF truing from drop**: "Adjust the Axial Form Factor number either up to drop, or down to elevate the trajectory". Shoot at the longest distance where you still get reliable impacts (https://www.hornady.com/team-hornady/ballistic-information/ballistic-resources/4dof-instructions).
- **Rough error propagation (my own arithmetic, not from a source)**: two chronographs, each ±0.1%, about 100 m apart, with a velocity loss of about 8% gives σ(ΔV)/ΔV ≈ 1.8%, so the BC error is about 2% per shot. That fits the 1–2% reported above. Truing from drop at long range is limited by the muzzle-velocity standard deviation and by measurement error in drop and conditions, and **no maker gives a numerical uncertainty for drop-based truing**.

---

## 5. Back-solving the BC from the maker's own downrange-velocity tables

### Who publishes downrange velocities (maker pages checked 2026-10-14)

| Maker | Downrange velocity table? | BC printed? | Example / URL |
|---|---|---|---|
| **Hornady** (ammo) | **YES**, muzzle and 100–500 yd, 24" test barrel | **No BC on ammo pages** | 223 Rem 55 gr HP American Gunner: 3240/2802/2405/2042/1713/1429 fps (https://www.hornady.com/ammunition/rifle/223-rem-55-gr-hp-american-gunner). FAQ: "You'll see a tab called "Ballistics" at the top of each specific product page." (https://www.hornady.com/support/faqs/where-can-i-find-ballistics-information) |
| **Lapua** | **YES**, 0–1000 m and 0–1000 yd (product pages and catalog pp. 50–57) | G1 + G7 | 6.5 CM 123 gr Scenar: 850/792/736/681/532/444/362 m/s (https://www.lapua.com/product/6-5-creedmoor-open-tip-match-cartridge-scenar-8g-123gr-4316060/) |
| **Norma** | **YES**, V0–V300 (m and yd) | G1 | Whitetail 6.5 CM 140: "V100 731 m/s", "V300 585 m/s" (https://www.norma-ammunition.com/en-gb/products/dedicated-hunting/centerfire-rifle/norma-whitetail/norma-whitetail-65-creedmoor-140-gr---20166492) |
| **GECO** | **YES**, V0–V300 every 50 m/yd | single BC | GECO Plus .30-06 11.0 g: V0 835, V100 728, V300 539 m/s, BC 0.274 (https://geco-ammunition.com/en/ammunition/products-overview/centrefire-rifle-cartridges/geco-plus/geco-30-06-plus-110g). PDF datasheets also exist. |
| **SWISS P** | **YES** in the factsheet PDF (0–600 m/yd every 50). **NO** on the product page. | G1 + G7 + Cd at 3 velocities | .308 Tactical factsheet (URL §1) |
| **Weatherby** | **YES**, muzzle–500 yd | G1 | 300 Wby Mag TTSX 180: 3232/3025/…/2285 fps, ".484" (https://weatherby.com/store/300-weatherby-magnum/). Chart: https://weatherby.com/ammunition-org/ballistics-charts/ |
| Federal | YES, muzzle–500 yd | G1 + G7 | GM308M 2650/2460/2277/2103/1936/1778 (URL §1) |
| Barnes | YES in ballistics-chart PDFs (handgun: muzzle, 15, 25, 50 yd, plus a "COEFFICIENT" column) | yes | https://barnesbullets.com/content/Barnes-Ballistics-Charts/CF-P&R-Imperial.pdf |
| **Aguila** | **Partial**: muzzle and 100 yd only | No | 22 LR HV: 1255 → 1036 fps (https://www.aguilaammo.com/products/22-super-extra-long-rifle-high-velocity-copper-plated-solid-point) |
| **Black Hills** | **NO**, a single velocity from a 24" barrel | No | https://www.black-hills.com/shop/new-rifle-ammo/308-winchester-match/ , https://www.black-hills.com/shop/new-rifle-ammo/223-remington/ |
| **Winchester rimfire** | **NO**: "There is no ballistics data available at this time." Muzzle velocity and energy only. The site points to an online calculator. | No | https://winchester.com/Products/Ammunition/Rimfire/Super-X/X22LRH , https://winchester.com/en/Products/Ammunition/Rimfire/Varmint-HV |
| **MKE** | **NO**, one velocity at 23.7 m, e.g. 7.62×51 M80 "Velocity, m/s (23,7 m) 838 ± 9,1", M118 "784" | No | https://www.mke.gov.tr/Content/D_Dosya/ckResim/Programlar/03-MKE-KATALOG-SMALL%20ARMS%20AMMUNITION.pdf |
| Sako | No (BC and muzzle velocity only) | yes | https://www.sako.global/ammunition/trg-precision |

### Back-solve check (own computation with the repo's BRL G1/G7 tables, 1-D velocity decay, RK4)

| Load | Published | Back-solved BC (Army Std Metro / ICAO) at near → far distance | Reading |
|---|---|---|---|
| Federal GM308M | G1 .462 | ASM .463 / .462 / .462 | Table computed from the published G1 under Army Standard Metro. |
| Federal GM65CRDBH130 | G1 .560 | ASM .559 / .560 | Same. |
| Weatherby 300 TTSX 180 | G1 .484 | ASM .484 / .485 | Same. |
| GECO .30-06 Plus | .274 | ASM .274 / .275 | Same. |
| Norma Whitetail 6.5 CM | G1 .373 | ICAO .375 / .372 | About the published value, ICAO. |
| Lapua 6.5 CM 123 Scenar | G7 .263 | G7 ICAO .266 / .263 / .263 (to 1000 m). The G1 fit drifts from .530 to .492. | Computed from G7 under ICAO. |
| SWISS P .308 Tactical | G1 .303 / G7 .157 | G1 ICAO .299 / .303 / .305. G7 drifts .150 → .165. | Neither G function fits exactly, consistent with a Cd-curve-based table. |
| Hornady 223 55 HP AG | none | G1 ASM .223 / .224 (100 → 500 yd) | Recovers Hornady's internal G1. |
| Hornady 30-06 180 SST Superformance | none | G1 ASM .481 / .481 | Same. |
| Aguila 22 LR HV | none | G1 ASM .156 (one point) | The drag model cannot be confirmed from a single point. |

**Key caveat:** the tables are almost certainly **computed** from the maker's own BC rather than measured downrange. Back-solving returns exactly the published BC to ±0.001 for Federal, Weatherby and GECO. So a back-solve **recovers the maker's own BC** (useful when it is not printed: Hornady ammo, Aguila), and it also recovers the maker's drag model and atmosphere. It is **not independent evidence**. Courtney et al. found Winchester's published trajectory implied G1 0.206 against 0.187 measured (§4). A back-solved BC deserves the same "maker value" trust level as a printed BC. It is not a "measured" value.
