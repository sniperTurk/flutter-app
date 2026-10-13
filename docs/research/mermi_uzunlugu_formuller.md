# Mermi uzunluğu: hangi formüle girer, ne kazandırır?

Araştırma tarihi: 2026-10-13 · Dal: `research/mermi-uzunlugu` · Yalnız araştırma;
`lib/` ve `test/` değişmedi.

---

## 1. Sahibine kısa özet (Türkçe, sade dil)

**Soru:** "Saçma, slug ve mermi için uzunluk soruyoruz. Hesapta kullanmıyorsak
neden soruyoruz? Formüle nasıl girer, ne fayda sağlar?"

**Kısa cevap:** Uzunluk düşüşü (BC'yi) doğrudan değiştirmez. Uzunluğun asıl işi,
**slug'ın namludaki yiv adımıyla yeterince hızlı dönüp dönmediğini** (kararlılık,
*Sg*) hesaplamaktır. Bu tek sayıdan üç şey çıkar:

1. **Kararlılık uyarısı** — en önemli fayda. Uzun/ağır bir slug yavaş yivde
   takla atabilir (anahtar deliği). Uygulama bunu atıştan önce söyleyebilir.
   Bugün bu uyarı **yalnız ateşli silahta** gösteriliyor; PCP slug'da da
   gösterilmeli.
2. **Yiv adımı önerisi** — "Bu slug için en yavaş hangi yiv yeterli?" FX
   namlu değişikliği gibi kararlar için doğrudan işe yarar.
3. **Spin sapması ve rüzgâr sıçraması** — küçük düzeltmeler. Formüller ateşli
   silah mermilerinden türetildi; slug için **tahmin** sayılmalı.

**Saçma (diabolo) için uzunluk gerekmez.** Saçma, badminton topu gibi
"etekten" (sürüklenmeyle) dengelenir; Miller formülü ona uymaz. Saçmada uzunluk
kutusu kaldırılabilir veya yalnız bilgi alanı olarak kalabilir.

**Sahibinin slug'ı için rakamlar** (.25, 50 gr, 985 fps, BC G1 0,139 tahmini,
50 m sıfır, 15 °C / 1013 hPa — varsayımlar §B.7'de):

| Etki | 100 m | 300 m | 500 m | Not |
|---|---:|---:|---:|---|
| Düşüş (karşılaştırma için) | 26 cm | 5,3 m | 19,2 m | Nokta-kütle |
| 4 m/s yan rüzgâr sürüklemesi | 10 cm | 84 cm | 235 cm | Karşılaştırma için |
| **Spin sapması** (Sg 1,5–4) | 1–2,5 cm | 12–23 cm | 38–73 cm | Litz formülü, slug için doğrulanmamış |
| **Rüzgâr sıçraması** (4 m/s yan rüzgâr) | ~1–2 cm | 3–5 cm | 6–9 cm | Litz formülü, slug için doğrulanmamış |
| BC %9 düşük çıkarsa (marjinal Sg) | 0,4 cm | 16 cm | 88 cm | Eşik ve oran tartışmalı |
| **Takla atarsa** (Sg < 1) | — | — | — | Hedefi ıskalar; hiçbir formül düzeltemez |

**Yorum:** 100 m'de uzunluğun getirdiği düzeltme 1–2 cm, yani gruptan küçük.
300–500 m'de spin sapması onlarca santime çıkar ama aynı yönde sabit
kaldığı için sahada yan sıfırla da yakalanır. **Asıl kazanç uyarıdır:**
kararsız slug'ı atıştan önce yakalamak, metrelerce hatayı ve boşa giden
mühimmatı önler.

**Sahibinin FX 80 cm namlu sorusu:** 50 gr .25 slug, 985 fps'te Sg ≈ 1,5
için gereken **en yavaş** yiv adımı:

| Slug boyu | Sg 1,5 için en yavaş adım | 1:16'da Sg | 1:18'de Sg | 1:24'te Sg |
|---|---|---:|---:|---:|
| 8 mm | 1:29 | 5,1 | 4,0 | 2,3 |
| 9 mm | 1:26 | 3,9 | 3,1 | 1,7 |
| 10 mm | 1:23 | 3,0 | 2,4 | 1,3 |
| 11 mm | 1:20 | 2,4 | 1,9 | 1,1 |
| 12 mm | 1:18 | 1,9 | 1,5 | 0,85 |

Yani **1:16 ve 1:18, 12 mm'ye kadar her 50 gr .25 slug için kararlı**; 1:24
ve daha yavaş adımlar 10 mm'den uzun slug'larda sınırda/kararsız. Slug boyu
**kumpasla ölçülmeli**; liner'ın adımı FX tarafından yayımlanmadığı için
satıcıdan veya ölçümle doğrulanmalı (önceki araştırma).

**Uzunluk BC'yi tahmin etmeye yarar mı?** Pek yaramaz. 149 slug için (NSA,
H&N, Zan resmî sayfaları) ölçtük: uzunluk eklemek, tahmini BC'nin tipik
hatasını %12,6'dan %8,2'ye indiriyor, ama en kötü %10'luk dilimde hâlâ
±%18–19. Başka bir markaya taşındığında hata %7–40. Yani BC kutusu boşsa
uzunluk küçük bir iyileştirme sağlar; **kronograf veya iki mesafede atışla
ölçülen BC'nin yerini tutmaz.**

**Öneri (sıra önemli):**

1. Profil > Mühimmat'taki `Uzunluk` değerini atış ekranının Miller hesabına
   bağla (Pro kutusu boşsa oradan al). Böylece kullanıcı bir kez girer.
2. **Kararlılık uyarısını PCP slug'da da göster** (saçmada değil):
   "Sg 0,9 — Kararsız: slug takla atabilir. Daha hızlı yiv veya daha kısa slug."
3. Saçmada spin sapması ve rüzgâr sıçramasını **kapat** (formül uymaz).
4. Profil'de yiv adımı varsa "Bu slug için en yavaş uygun yiv: 1:23" satırı.
5. BC'yi kararlılığa göre otomatik düşürme — **yapma** (eşik ve oran
   kaynaklar arasında tutarsız). Yalnız uyarıda söyle.
6. Uzunluğa dayalı BC tahmini: isteğe bağlı, küçük fayda; yapılırsa yine
   "tahmini" etiketiyle.

---

## 2. English details

### Research limitations of this run

- This was an unattended scheduled run. `WebFetch` needs an interactive
  permission that nobody answered, so **no new web page was read in this run**.
  Every external fact below comes from sources already read and recorded in
  earlier repo research (`docs/research/pellet_slug_hassas_hesap.md` on
  `research/hassas-hesap`, `docs/research/modifiye_tufek_fx_namlu.md` on
  `research/modifiye-tufek`, both accessed 2026-10-12), or is cited from a book
  that was not fetched (marked **not fetched**). `WebSearch` was used only to
  locate titles/URLs; search snippets were not used as evidence.
- The manufacturer BC/length data set is the repo's `lib/data/bullet_library.dart`,
  generated from manufacturers' pages; each row keeps its `sourceUrl`. Rows were
  not re-read today.
- All numeric tables are computed here with the repo's reference solver
  `tools/formula_reference.py` and the scripts listed in §B.8.

### B.1 Gyroscopic stability: Miller rule

**Formula** (Miller 2005 [S7], as given with velocity and atmosphere
corrections by Courtney & Miller [S6]; the same expression as
`Stability.millerSg` in `lib/core/stability.dart`):

```
Sg = 30·m / ( t² · d³ · l · (1 + l²) )  ·  (V/2800)^(1/3)  ·  (T_F + 460)/519  ·  29.92/P_inHg
```

m = mass (gr), d = diameter (in), t = twist (calibres = twist_in / d),
l = length (calibres = length_in / d), V = velocity (ft/s), T_F = °F, P = inHg.

**Applicability**

| Projectile | Miller meaningful? | Basis |
|---|---|---|
| Solid lead slug, flat or slightly hollow base | **Yes, approximate.** Rule assumes uniform density and a "normal" rifle-bullet shape. | [S6], [S7] |
| Hollow-point / hollow-base slug | **Approximate only.** Uniform-density assumption is broken. Courtney & Miller showed for plastic tips that using the *metal* length in `(1+l²)` restores accuracy [S6]; no validated correction for hollow cavities was found, and Courtney & Courtney state there is no Sg formula for hollow-point bullets [S13]. Label the result "yaklaşık". | [S6], [S13] |
| Diabolo pellet | **No.** The diabolo is stabilised aerodynamically (centre of mass ahead of centre of pressure, the skirt adds drag at the rear) as well as by spin [S9]. Miller's rule is a gyroscopic criterion for spin-stabilised bodies whose CP is ahead of the CG; an Sg value for a diabolo has no established meaning. | [S9] |

**Velocity factor below Mach 1.** Courtney & Miller: below the speed of sound
the velocity correction takes its value at the speed of sound [S6]. At 985 fps
this raises Sg by ~4 % relative to using the real V (the app uses the real V,
i.e. errs on the safe side). Courtney & Courtney also note the formulas
*underestimate* stability in the subsonic/transonic region [S13]. Sg also grows
downrange because spin decays more slowly than velocity (McCoy [S1], not
fetched), so muzzle Sg is the worst case.

**Thresholds**

| Sg | Meaning | Source |
|---|---|---|
| < 1.0 | Gyroscopically unstable; tumbling. Tumbling may start between 0.95 and 1.05 because the formula is ~5 % accurate. | [S5], [S13] |
| 1.0 – ~1.3 | Flies, but with more yaw; drag rises / BC drops "significantly" at or below ~1.25–1.3. | [S5] |
| > 1.3 | "Probably ample margin" (Courtney & Courtney). | [S5] |
| 1.4 – 2.0 | Recommended range (Miller, as reported in [S6]). | [S6], [S7] |
| 1.5 vs 1.25 | Lead .22 LR at Mach 0.77–1.03 (the closest public analogue to a lead slug): Sg 1.5 was adequate in all weather, 1.25 too low in cold air. | [S8] |

The app's current classes (`unstable < 1.0`, `marginal < 1.5`, `stable ≥ 1.5`)
are consistent with these sources. 1.5 is the conservative choice and matches
the BRL .22 LR evidence for a lead projectile at similar Mach numbers.

### B.2 Effects on the trajectory that an app can compute

**(a) Stability warning.** Needs only Sg. No trajectory change; highest value
(see §B.6). Currently `_flightWarnings` returns nothing unless `_isFirearm`.

**(b) Spin drift (Litz).**

```
SD_in = 1.25 · (Sg + 1.2) · TOF^1.83
```

Litz, *Applied Ballistics for Long Range Shooting* (2009), eq. 10.1 [S20,
**not fetched**; citation as recorded in `tools/formula_reference.py`]. It is an
empirical fit to rifle-bullet trajectories computed with a modified point-mass
/ 6-DoF model. The underlying physics (yaw of repose) is from Lieske & Reiter,
BRL 1314 [S2], derived for spin-stabilised, dynamically stable projectiles.
For a subsonic slug the TOF at 500 m (~2.25 s) and the low velocity are outside
anything the fit is documented for; no measured slug or pellet spin drift was
found in the allowed source class. **Use for slugs as an estimate, never for
pellets.**

**(c) Aerodynamic jump (Litz).**

```
Y_MOA per mph crosswind = 0.01·Sg − 0.0024·l + 0.032        (l in calibres)
```

Litz (2009), ch. 10 [S20, **not fetched**]. This is the one place length enters
*besides* Sg. The theory (crosswind at the muzzle → initial yaw → vertical
"jump" for a spinning projectile) is in McCoy [S1, not fetched]. Same caveat:
fitted on rifle bullets.

**(d) Marginal stability and lower effective BC.**

- Litz's statement that BC falls when Sg < 1.5 is the basis of the app's
  `bcLossPercentPerTenth = 3.0` (3 % per 0.1 Sg below 1.5). The original is in
  Litz's books (*Applied Ballistics for Long Range Shooting*, *Modern
  Advancements in Long Range Shooting*, 2014) and a Berger Bullets page by
  Litz [S21] — **none of them was read in this run or in earlier repo
  research**, so the 3 %/0.1 figure is **unverified** here.
- The peer-reviewed-style evidence that *was* read [S5] places the onset of
  significant BC loss lower, at Sg ≈ 1.25–1.3, with tumbling at 0.95–1.05.
  BRL [S8] reports for lead .22 LR a ~2 % drag increase from a 1.8° limit cycle.
- **Applicability to airgun slugs:** no source measured BC versus Sg for airgun
  slugs. The mechanism (more yaw → more drag) is generic; the numbers are not
  transferable.
- **Recommendation:** keep the current behaviour — show the possible BC loss as a
  warning, never lower the solver's BC automatically.

### B.3 Does length help estimate BC when none is published?

Data: every PCP slug row in `lib/data/bullet_library.dart` that has both a
published G1 BC and a published length: **149 slugs** — NSA 113
(nielsenspecialtyammo.com), H&N 33 (hn-sport.de), Zan 3 (zanprojectiles.com).
FX publishes no numeric BC [S13b]; JSB's site was not read (robots.txt,
[S18]). Manufacturers do not state the velocity or method of their BCs [S12].

Form factor `i = SD / BC_G1`, SD = gr / (7000·d²) [S1].

| Set | n | Pearson r(i, L/D) | Spearman ρ | median i (IQR) |
|---|---:|---:|---:|---|
| All | 149 | 0.56 | 0.65 | 0.85 (0.73–0.94) |
| NSA | 113 | 0.65 | 0.73 | 0.88 (0.78–0.95) |
| H&N | 33 | 0.83 | 0.81 | 0.77 (0.71–0.82) |
| .25 (6.35 mm) only | 30 | 0.57 | — | — |

**Longer slugs have a *larger* (worse) form factor in the published data**:
published BC grows more slowly than SD. Best fit (log-linear, all 149):

```
BC_G1 ≈ 1.476 · SD^1.006 · (L/D)^-0.495
```

i.e. BC ≈ 1.48·SD/√(L/D).

Leave-one-out accuracy (|predicted/published − 1|):

| Method | median | 90th pct | RMS |
|---|---:|---:|---:|
| Current app: constant i = 0.825 (`EstimatedBc`) | 12.6 % | 22.2 % | 15.2 % |
| BC ∝ SD^k (weight & calibre only, fitted) | 8.5 % | 22.1 % | — |
| BC = f(SD, L/D) (with length) | 8.2 % | 19.0 % | 12.4 % |

Leave-one-brand-out (bias when the maker is not in the fit): H&N −6 %
(constant i: −11 %), NSA +13 % (+12 %), Zan −40 % (−31 %; Zan "ELR" slugs
have far higher BCs than their SD suggests).

**Honest reading:** most of the improvement over the current constant comes from
not assuming BC ∝ SD; length adds only a small further gain (90th-percentile
error 22 % → 19 %). Maker-to-maker differences (±10–40 %) dominate. For the
owner's 50 gr .25 slug the length model gives BC 0.149 (8 mm) … 0.121 (12 mm)
against 0.139 from the constant; that difference is −58 … +134 cm of drop at
500 m (§B.7). A length-based estimate is a modest refinement of a value that
must still be labelled "tahmini" and replaced by a measured BC.

### B.4 Twist recommendation

Miller solved for twist (Sg ∝ 1/t²):

```
t_cal = sqrt( 30·m·f_V·f_A / (Sg_target · d³ · l · (1 + l²)) ),   twist_in = t_cal · d
```

Owner case: 50 gr, d = 0.25 in, 985 fps, 59 °F, 29.92 inHg. Slowest twist
(inches per turn) for a target Sg; first value uses the real V, second the
speed-of-sound V per [S6]:

| Length | Sg 1.3 | **Sg 1.5** | Sg 2.0 |
|---|---|---|---|
| 8 mm | 31.6 / 32.3 | **29.4 / 30.1** | 25.5 / 26.0 |
| 9 mm | 27.6 / 28.2 | **25.7 / 26.3** | 22.3 / 22.8 |
| 10 mm | 24.4 / 24.9 | **22.7 / 23.2** | 19.7 / 20.1 |
| 11 mm | 21.7 / 22.1 | **20.2 / 20.6** | 17.5 / 17.8 |
| 12 mm | 19.4 / 19.8 | **18.1 / 18.5** | 15.7 / 16.0 |

Muzzle Sg at the FX filter twists [S16] (plus 1:20, 1:22) (real V):

| Length | 1:16 | 1:18 | 1:20 | 1:22 | 1:24 | 1:28 |
|---|---:|---:|---:|---:|---:|---:|
| 8 mm | 5.08 | 4.01 | 3.25 | 2.68 | 2.26 | 1.66 |
| 9 mm | 3.88 | 3.07 | 2.48 | 2.05 | 1.72 | 1.27 |
| 10 mm | 3.02 | 2.39 | 1.93 | 1.60 | 1.34 | 0.99 |
| 11 mm | 2.39 | 1.89 | 1.53 | 1.26 | 1.06 | 0.78 |
| 12 mm | 1.92 | 1.51 | 1.23 | 1.01 | 0.85 | 0.63 |

1:16 gives Sg ≥ 1.9 for every 50 gr .25 slug up to 12 mm; 1:18 ≥ 1.5. Very high
Sg is not harmful in itself in Miller's framework; the recommended band is
1.4–2.0 [S6], and higher values only increase spin drift (Litz). This does not
say anything about group size, which depends on the slug and barrel; it only
says the slug will not be under-stabilised. FX does not publish the twist per
liner, so the owner's actual twist must be confirmed (FX research note).

### B.5 Where length should feed in the app

| Use | Formula | Input from | Projectile types | Show to user (Turkish) |
|---|---|---|---|---|
| Stability class | Miller [S6] | `Ammunition.lengthMm` (Profil), fallback to Pro "Mermi uzunluğu" | firearm bullet, PCP slug | `Sg 2,4 — Kararlı` / `Sg 1,2 — Sınırda: sapma ve düşüş artabilir; 50 m'de kâğıda atıp anahtar deliği kontrol edin` / `Sg 0,9 — Kararsız: takla atabilir. Daha hızlı yiv veya daha kısa slug.` For hollow slugs add `(oyuk uçlu: yaklaşık)` |
| Slowest adequate twist | Miller inverted (§B.4) | length, weight, calibre, MV, air | bullet, slug | `Bu slug için en yavaş uygun yiv: 1:23" (Sg 1,5)` |
| Spin drift | Litz [S20] | Sg, TOF, twist direction | bullet; slug labelled `tahmini` | already exists; disable for pellets |
| Aerodynamic jump | Litz [S20] | Sg, l, crosswind | bullet; slug `tahmini` | already exists; disable for pellets |
| BC loss | — | Sg | — | warning text only (current behaviour); no automatic BC change |
| BC estimate | §B.3 log model | SD, L/D | slug, BC empty | optional; keep `tahmini` |
| Pellet length | none | — | pellet | not needed; may stay as a record field |

Concrete gaps found in the code (`lib/features/ballistics/ballistics_screen.dart`):

1. `_muzzleSg` reads only `bulletLengthCtl` (Pro box); `Ammunition.lengthMm` from
   Profil is never used, so a value the user already entered is ignored.
2. `_flightWarnings` returns early when `!_isFirearm`, so a PCP slug never gets
   the unstable/marginal notice even when Sg is computable.
3. `_stability` (spin drift and aero jump) does not check `AmmunitionType`, so a
   pellet with a length typed in the Pro box receives a Litz spin drift and jump
   that do not apply to a diabolo [S9].
4. The Miller velocity factor uses the real subsonic V; per [S6] it should use
   the speed-of-sound value below Mach 1 (≈ +4 % Sg at 985 fps). Safe-side
   difference; owner's decision.

### B.6 Why the warning matters more than the corrections

An under-stabilised slug yaws or tumbles; its drag is not described by any BC and
the shot cannot be corrected in the solver. Sources: tumbling at Sg 0.95–1.05,
significant drag rise below ~1.25–1.3 [S5]; lead .22 LR at similar Mach needed
Sg ≈ 1.5 in cold air [S8]. Cold air raises density and lowers Sg (Miller
atmosphere term), so a slug that is marginal at 15 °C can fail at 0 °C:
the 0 °C / 1013 hPa factor is (32+460)/519 = 0.948, i.e. −5 % Sg.

### B.7 Owner scenario: computed magnitudes

Assumptions (not measured): .25 slug 50 gr, d = 0.249 in, MV 985 fps
(300.2 m/s), G1 BC 0.139 (the app's estimate, SD 0.1152 / 0.825), zero 50 m,
sight height 50 mm, 15 °C, 1013.25 hPa, 0 % RH, no incline. Solver:
`tools/formula_reference.py` (point mass, G1, CIPM-2007 air density).

| Range | TOF | V | Drop below LOS | 4 m/s full crosswind |
|---:|---:|---:|---:|---:|
| 100 m | 0.358 s | 262.6 m/s | 26.4 cm | 9.8 cm |
| 300 m | 1.209 s | 212.2 m/s | 532 cm | 84.0 cm |
| 500 m | 2.254 s | 174.3 m/s | 1920 cm | 235.4 cm |

Litz spin drift (cm) at muzzle Sg 1.5 / 2.5 / 4.0: 100 m 1.3 / 1.8 / 2.5;
300 m 12.1 / 16.6 / 23.4; 500 m 37.9 / 52.0 / 73.1.

Litz aero jump with a 4 m/s (8.95 mph) crosswind: Sg 1.5, 10 mm: 0.39 MOA →
1.1 / 3.4 / 5.6 cm; Sg 2.5, 10 mm: 0.48 MOA → 1.4 / 4.2 / 6.9 cm; Sg 4.0, 9 mm:
0.61 MOA → 1.8 / 5.4 / 8.9 cm (100 / 300 / 500 m).

Drop change if the effective BC were lower (e.g. marginal stability):
−3 % → +0.1 / +4.9 / +27 cm; −9 % → +0.4 / +15.7 / +88 cm; −15 % → +0.7 /
+28 / +160 cm. Length-model BC 0.121 (12 mm) instead of 0.139: +0.6 / +24 /
+134 cm; 0.149 (8 mm): −0.3 / −10.5 / −58 cm.

**Benefit in cm, summarised:** at 100 m length-dependent corrections are
≤ 2–3 cm. At 300 m spin drift is 12–23 cm (one-directional, so also absorbed
by windage truing), jump 3–5 cm per 4 m/s of crosswind. At 500 m spin drift is
38–73 cm and jump 6–9 cm, both on an unvalidated extrapolation for a subsonic
slug. The decisive benefit is binary: avoiding an unstable load.

### B.8 Reproduction

Scripts (in the session scratchpad, not committed): parse PCP rows from
`lib/data/bullet_library.dart`; compute i, L/D, correlations, leave-one-out and
leave-one-brand-out errors with numpy/scipy; owner tables with
`formula_reference.miller_sg`, `litz_spin_drift_in`, `litz_aero_jump_moa_per_mph`
and `solve`. The formulas are the ones quoted above; anyone can rerun them
from the repo.

### B.9 Open points for the owner

- Owner's slug make/model and measured length are unknown; tables cover 8–12 mm.
- The 3 %/0.1-Sg BC loss constant in `Stability` is not verified against a
  source read in this repo; [S5] suggests a lower threshold (~1.25–1.3).
- Whether to switch the subsonic velocity factor to the speed-of-sound value [S6].

---

## 3. Sources

Accessed in earlier repo research on 2026-10-12 unless marked; none re-fetched
in this run (see "Research limitations").

| # | Source | Type | Used for |
|---|---|---|---|
| S1 | R. L. McCoy, *Modern Exterior Ballistics*, Schiffer, 1999, ISBN 0-7643-0720-7 (**not fetched**) | Textbook | SD/BC/form-factor definitions; yaw of repose, aerodynamic jump theory; spin decay |
| S2 | R. F. Lieske, M. L. Reiter, "Equations of Motion for a Modified Point Mass Trajectory", BRL Report 1314, 1966 — https://apps.dtic.mil/sti/pdfs/AD0485869.pdf | US Army BRL | Yaw-of-repose / spin-drift scope (spin-stabilised shells) |
| S5 | E. R. Courtney, M. W. Courtney, "Aerodynamic Drag and Gyroscopic Stability", arXiv:1309.5039 — https://arxiv.org/pdf/1309.5039 | Scientific preprint | BC loss at Sg ≤ ~1.25–1.3; tumbling 0.95–1.05; Sg > 1.3 "probably ample margin" |
| S6 | M. Courtney, D. Miller, "A Stability Formula for Plastic-Tipped Bullets, Part 1", *Precision Shooting* Jan 2012, arXiv:1410.5340 — https://arxiv.org/pdf/1410.5340 | Scientific preprint | Miller formula with velocity and atmosphere corrections; subsonic velocity factor; 1.4–2.0 recommendation; uniform-density assumption, metal-length fix |
| S7 | D. Miller, "A New Rule for Estimating Rifling Twist", *Precision Shooting*, March 2005, pp. 43–48 (cited via S6; **not fetched**) | Original publication | Miller twist rule |
| S8 | R. L. McCoy, "Aerodynamic Characteristics of Caliber .22 Long Rifle Match Ammunition", BRL-MR-3877, 1990 — https://apps.dtic.mil/sti/pdfs/ADA229713.pdf | US Army BRL | Lead projectile Mach 0.77–1.03: Sg 1.5 adequate, 1.25 too low in cold; ~2 % drag from limit cycle |
| S9 | N. Ladommatos, "Influence of air rifle pellet geometry on aerodynamic drag", Proc. IMechE Part P, 2019, doi:10.1177/1754337119831107 — https://discovery.ucl.ac.uk/id/eprint/10072258 | Peer-reviewed | Diabolo stabilised by CM ahead of CP plus spin |
| S12 | H&N Sport official product pages (e.g. https://www.hn-sport.de/en/node/767) | Manufacturer | Published slug BCs and lengths; no velocity/method stated |
| S13 | E. Courtney, M. Courtney, "Gyroscopic Stability of Open Tipped Match Style Rifle Bullets", arXiv:1401.4187 — https://arxiv.org/pdf/1401.4187 | Scientific preprint | No Sg formula for hollow points; formulas underestimate subsonic/transonic stability; ~5 % accuracy |
| S13b | FX Airguns, FX Halo — https://www.fxairguns.com/accessories/ammunition/fx-halo/ | Manufacturer | No numeric BC published |
| S14 | Nielsen Specialty Ammo official product pages (e.g. https://nielsenspecialtyammo.com/products/240-grains-swaged-hollow-point), via `lib/data/bullet_library.dart` `sourceUrl` | Manufacturer | 113 slug BC + length rows |
| S15 | Zan Projectiles official product pages (e.g. https://zanprojectiles.com/shop/25-caliber-45-3-grain-elr-hollow-point-slugs/), via `bullet_library.dart` | Manufacturer | 3 slug BC + length rows |
| S16 | FX Airguns, Liners — https://www.fxairguns.com/accessories/barrels/liners/ (via `research/modifiye-tufek`) | Manufacturer | Twist filter values 1:16, 1:18, 1:24, 1:25, 1:28, 1:40; per-liner twist not stated |
| S18 | JSB Match Diabolo — https://www.jsb-match-diabolo.com/ | Manufacturer | **Not read**: robots.txt disallows automated access |
| S20 | B. Litz, *Applied Ballistics for Long Range Shooting*, 2009, ch. 10 (eq. 10.1 spin drift; aerodynamic jump) (**not fetched**; citation as recorded in `tools/formula_reference.py`) | Book | Spin-drift and aero-jump formulas |
| S21 | B. Litz, "Twist rate stability calculator (updated)", Berger Bullets — https://bergerbullets.com/twist-rate-stability-calculator-updated/ and *Modern Advancements in Long Range Shooting*, 2014 (**not read**; located by search only) | Manufacturer page / book | Claimed origin of BC reduction below Sg 1.5 — unverified here |
| R1 | `lib/core/stability.dart`, `lib/core/estimated_bc.dart`, `lib/features/ballistics/ballistics_screen.dart`, `tools/formula_reference.py`, `lib/data/bullet_library.dart` | Repo | Current app behaviour, solver, data set |

**Derived here (not from a source):** all correlations, fits and cross-validation
errors (§B.3); all Sg, twist, TOF, drop, wind, spin-drift, jump and BC-sensitivity
numbers (§1, §B.4, §B.7).
