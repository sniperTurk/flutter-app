# Formül denetimi — 2026-10-13

Dal: `fix/formul-denetimi`. Önceki denetim: `docs/formul-denetimi-2026-10-11.md`
(bu denetim ona güvenmeden, baştan yapıldı).

## Kısa özet (sahip için)

**Ne kontrol edildi?** Uygulamanın hesap yapan bütün kodu: hava yoğunluğu ve
ses hızı, yerçekimi, mermi yörüngesi (düşüş, rüzgâr sapması, hız, uçuş
süresi), sürüklenme tabloları (G1/G7), eğim ve cant, Dünya dönüşü (Coriolis),
dönüş kararlılığı (Sg), spin drift, rüzgâr sıçraması, sıfır ofseti, kule
ölçeği, retikül tutuşları, MPBR, hız/BC doğrulama, isabet olasılığı (WEZ),
PCP basınç tablosu, barut sıcaklığı, birim dönüşümleri ve hesap makinesi.
Her formül bilimsel kaynakla (ICAO, NIST, WGS-84, McCoy, Miller, Litz,
Courtney & Miller) karşılaştırıldı. Başka balistik uygulamalarının sonuçları
kullanılmadı.

**Yörünge hesabı doğru mu?** Evet. Uygulamanın çözücüsünü, ayrı yazılmış iki
bağımsız hesapla karşılaştırdım (biri bu denetim için yeni yazıldı, öteki
depodaki eski referans). İstediğin dört mermide (.308 168 gr, 6.5 CM 140 gr,
6,35 mm 50 gr slug, .22 18 gr pellet) fark 0,001 mrad'ın altında; bir klik
0,1 mrad. Yani düşüş, rüzgâr, hız ve uçuş süresi hesapları doğru.

**Ne yanlıştı, ne düzeltildi?**

1. **Ses hızının altındaki mermilerde Sg biraz düşük çıkıyordu.** Miller
   formülündeki hız düzeltmesi ses hızının altında kullanılmamalı; formülün
   yazarları (Courtney & Miller 2012) "ses hızının altındaki bütün hızlarda
   ses hızındaki değer kullanılır" diyor. Uygulama PCP slug'ın kendi hızını
   kullanıyordu; Sg %4 (pellet hızında %7) düşük çıkıyordu. Düzeltildi.
   Etkisi küçük: 6,35 mm slug 300 m'de spin drift 17,4 → 17,9 cm.
   Ateşli tüfeklerde (ses üstü) hiçbir şey değişmedi.
2. **Diabolo pellet'e spin drift ve rüzgâr sıçraması uygulanıyordu.** Pellet
   dönerek değil, eteğinin havaya sürtünmesiyle düz uçar; Miller ve Litz
   formülleri dönerek uçan mermiler içindir. Uygulamanın kendi açıklaması da
   "PCP'de slug ile anlamlıdır" diyordu, ama Pro'da uzunluk yazılırsa pellet'e
   de uygulanıyordu (.22 pellet 100 m'de ~2,5 cm yanlış yan düzeltme; 10 mph
   yan rüzgârda ~1,4 cm yanlış dikey düzeltme). Artık pellet'te uygulanmıyor.
3. **Profil'de girilen mermi uzunluğu kullanılmıyordu.** Profil > Mühimmat'taki
   "Uzunluk" kaydediliyor ama kararlılık hesabı yalnız Pro'daki "Mermi
   uzunluğu" kutusuna bakıyordu. Artık Pro kutusu boşsa Profil'deki uzunluk
   kullanılıyor (Pro kutusu doluysa o geçerli). Ekranda değişiklik yok.

**Hata olmadığı anlaşılanlar:** atmosfer, yerçekimi, G1/G7 sürüklenme,
rüzgâr saati ve yönler, eğim/cant, Coriolis/Eötvös, sıfır ofseti, kule
ölçeği, retikül tutuşları, birimler (MOA / SMOA / MRAD, inHg, mph, °F),
Beaufort, MPBR, WEZ — hepsi doğru.

**Sürüklenme eğrisi doğrulaması (çok mesafeli) PCP'de tek bant:** Mach
bantları 1,2 / 1,5 / 2,0'da bölünüyor; PCP baştan sona Mach 1'in altında
uçtuğu için tek bir ölçek bulunuyor (BC doğrulamasıyla aynı sonuç). Hesap
yanlış değil, yalnız PCP için ek bilgi vermiyor. Ses altı bantlar eklemek yeni
ekran yazısı gerektirir; karar senin (aşağıda öneri var). Kod değişmedi.

**Kararlılık uyarısı yalnız ateşli tüfekte:** bu Ö5 planındaki bilinçli
karar ("Ateşli"). Pellet için doğru (Sg anlamsız). Slug için uyarı
gösterilebilir ama "BC %3 düşer" kuralı tüfek mermilerinden ölçülmüş; slug'a
taşınması kaynakla desteklenmiyor. Karar senin; kod değişmedi.

**Ne silindi?** Hiçbir yerden çağrılmayan 11 parça kod (liste aşağıda):
kullanılmayan bir açıklama metni, bir köşe yuvarlaklığı sabiti, bir hız
biçimlendirici, üç su terazisi fonksiyonu vb. Uygulamanın davranışı aynı.
Gizlediğin özellikler (SHOT_TABLE_SWITCH, WELCOME_RESTORE, PCP_AMMO_BRAND,
GOOGLE_MAPS_ENABLED) **silinmedi**. Eski "Kütüphaneden seç" ekranı ve
kullanılmayan kalın DejaVu yazı tipi dosyası da aday; dosya silme izni bu
çalışmada verilmediği için silinmedi, senin kararına bırakıldı.

**Belirsiz kalanlar:** slug'larda spin drift (Litz formülü ses üstü tüfek
mermilerinden çıkarılmış; ses altı slug için yayımlanmış daha iyi bir formül
yok, sonuç yaklaşık), GA tablosunun kaynağı, BC'nin hangi standart havaya
göre yayımlandığı (üretici verisi).

---

## English details

### 1. Method

* Every formula in `lib/core/`, the formula code in
  `lib/features/ballistics/ballistics_screen.dart` and
  `lib/tools/domain/field_calc.dart` was read and written down (section 2),
  then compared with the primary reference.
* Numerical check: `tools/formul_denetimi_2026_10_13.py` — a new point-mass
  solver written from McCoy ch. 5 equations, **not** from the app's code:
  range (x) as the independent variable, classical RK4 with 0.02 m steps,
  drag through the form factor i = SD/BC with the bullet's mass and
  diameter, ICAO dry air computed from first principles, secant zeroing.
  The app integrates in time (0.5 ms RK4), interpolates linearly to each
  range and zeroes by bisection.
* Third route: the existing `tools/formula_reference.py` (adaptive
  Dormand–Prince 5(4), separate code) on the same inputs.
* A faithful Python port of the app's own algorithm (scratch only) was used
  to set the Dart test tolerances.
* No Flutter/Dart SDK is available in this environment (the SDK download host
  is blocked). Dart tests run in CI (`test-diag.yml`).

### 2. Formula register

| Area | Code | Implemented formula | Reference | Verdict |
|---|---|---|---|---|
| Saturation vapour pressure | `atmosphere.dart` | 6.112·exp(17.62T/(243.12+T)) hPa | WMO-No. 8 (2018) Annex 4.B (Magnus/Sonntag) | OK |
| Moist-air density | `atmosphere.dart` | (p−e)/(R_d T) + e/(R_v T), R_d 287.05, R_v 461.495 | CIPM-2007 (Picard et al., Metrologia 45, 2008): −0.02…−0.09 % | OK (deviation negligible) |
| Speed of sound / Mach | `atmosphere.dart` | √(1.4·p/ρ) | ISA: 340.29 m/s at 15 °C (ICAO Doc 7488/3) | OK |
| Gravity | `gravity.dart` | Somigliana, WGS-84 constants, free-air (3.087691e-6 − 4.3977e-9 sin²φ)h + 7.2125e-13 h² | NIMA TR8350.2 eq. 4-1, 4-3 | OK |
| Drag deceleration | `reference_drag_model.dart` | a = ½ρ·Cd_G(M)·(π/4)·v²/(BC·703.0696 kg/m²) | McCoy ch. 4 (a = ρ S i Cd_G v²/2m); NIST lb/in² | OK |
| Cd lookup | `drag_table.dart`, `standard_drag_tables.dart` | linear in Mach, end values held | BRL G1/G7 tables | OK (PCHIP differs ≤0.11 mrad at 300 m for the 0.03 BC pellet, see 3.2) |
| Equations of motion, wind | `aerodynamic_trajectory_solver.dart` | drag along air-relative velocity; 0° headwind, 90° from the left (+z) | McCoy ch. 5 | OK |
| Incline/cant | solver `_frameFor` | g = (−g sinθ, −g cosθ cosφ, +g cosθ sinφ); air rotated the same way | rotation of the world frame (checked by hand: forward×up = right, right-handed) | OK |
| Coriolis/Eötvös | solver | Ω = ω(cosλ cosA, sinλ, −cosλ sinA), a = −2Ω×v, rotated into the scope frame | standard rotating-frame term; McCoy ch. 10 | OK |
| Zero | solver `_zeroAngle` | bisection on launch angle, zero-day velocity and ICAO zero air, level | definition | OK |
| Vacuum baseline | `ballistic_engine.dart` | closed-form parabola, exact low root | kinematics | OK |
| Energy | engine | ½mv², 1 gr = 64.79891 mg | NIST SP 811 | OK |
| Miller Sg | `stability.dart` | 30m/(t²d³l(1+l²))·(v/2800)^⅓·(T+460)/519·29.92/P | Miller 2005; **Courtney & Miller 2012: factor frozen below the speed of sound** | **FIXED** (3.1) |
| Spin drift | screen `_spinDriftMrad` | 1.25(Sg+1.2)·TOF^1.83 in, right twist → right | Litz, *Applied Ballistics for Long Range Shooting* (2009) eq. 10.1 | OK for spin-stabilised bullets; **pellets now excluded** (3.1) |
| Aerodynamic jump | screen `_aeroJumpMrad` | (0.01 Sg − 0.0024 L + 0.032) MOA/mph; right twist, wind from the right → up | Litz (2009) ch. 10 | OK; pellets excluded |
| Wind clock | `wind_clock.dart` | h → (360 − 30h) mod 360 | clock-face definition | OK |
| Wind zones | `ballistic_input.dart` `WindZones` | thirds of the path | definition | OK |
| Zone shares | `wind_zone_shares.dart` | drift from 1 m/s in each third / total | linear superposition (McCoy ch. 5 lag rule) | OK |
| Zero offset | screen `_zeroOffsetMrad` | atan(offset/zero range) | geometry | OK, sign: group high/right → subtract |
| Turret scale | screen | clicks = correction / (click · scale) | definition (real/marked travel) | OK |
| Hold samples | screen `_holdSamplesFor`, `reticle_holds.dart`, `scope_dial.dart` | mark m where correction − offset = scale·dialled + m; SFP subtension = calib mag / mag | optics definition | OK |
| Angular units | `domain.dart` `AngularUnit` | MOA = π/10.8 mrad; SMOA = 1000/3600 mrad | 1 MOA = π/10800 rad; SMOA = 1 in/100 yd = 1/3600 rad | OK |
| Mount cant | `scope_dial.dart` | floor(true MOA in turret unit / click) | definition | OK |
| Velocity / BC truing | `velocity_truing.dart` | bisection on v (±15 %) or BC (±30 %) | monotonic root finding | OK |
| Multi-range drag truing | `drag_band_truing.dart` | Tikhonov-regularised Gauss–Newton on Mach-band Cd scales | McCoy ch. 4–7 | OK; PCP collapses to one band (3.3) |
| MPBR | `mpbr.dart` | zero scan + bisection, linear crossings | definition | OK |
| WEZ | `wez.dart` | Box–Muller Monte Carlo; σ = ES/3.067 (n=5); 1−(1−p)ⁿ | circular normal; Grubbs | OK |
| PCP pressure | `pcp_pressure.dart` | piecewise-linear table, regulator bypass below set pressure | definition (no default curve) | OK |
| Powder temperature | `powder_temperature.dart` | v = v₀(1 + k/100·ΔT/15) | linear sensitivity definition | OK |
| Estimated BC (PCP) | `estimated_bc.dart` | BC = SD/i, SD = gr/(7000 d²) | McCoy ch. 4 | OK (form factors are catalogue medians, labelled "tahmini") |
| Parallax table | `parallax_range.dart` | linear between recorded marks, no extrapolation | definition | OK |
| Beaufort | `beaufort.dart` | WMO force 0–7 limits | WMO-No. 8 ch. 5 | OK |
| Units | `units.dart`, `unit_system.dart`, `field_calc.dart` converters | ft, yd, in, fps, mph, knot, inHg (33.8638866667 hPa), psi, mmHg, lbf·ft, oz, lb, °F | NIST SP 811 App. B | OK |
| Station pressure | `field_calc.dart` | ISA p₀(1 − 2.25577e-5 h)^5.25588; hypsometric with mean column T | ICAO Doc 7488/3; WMO-No. 8 Annex 3.A | OK |
| Density altitude, dew point | `field_calc.dart` | 44330.77(1 − (ρ/1.225)^0.234969); Magnus inverse | ICAO; Magnus | OK |
| Haversine, bearing | `field_calc.dart` | R = 6 371 008.8 m | IUGG mean radius | OK |
| Power factor, momentum | `field_calc.dart` | gr·fps/1000; m·v | IPSC definition | OK |

### 3. Findings

#### 3.1 Confirmed and fixed

**(a) Miller Sg below Mach 1 — confirmed, fixed.** Courtney, M. W. &
Miller, D. G., "A Stability Formula for Plastic-Tipped Bullets: Part 1",
*Precision Shooting*, Jan 2012 (arXiv:1410.5340) state that the velocity
correction (v/2800)^⅓ "for all velocities below the velocity of sound has the
value at the velocity of sound". `Stability.millerSg` used the actual
velocity. Fix: v ← max(v, c(T)), c = √(1.4·287.05·T_K) (dry air; 340.29 m/s
at 15 °C). Supersonic loads are bit-for-bit unchanged.

| Case (15 °C, 1013.25 hPa) | Sg before | Sg after |
|---|---|---|
| 6.35 mm 50 gr slug, 10 mm, 1:17, 985 fps | 2.6742 | 2.7882 (+4.3 %) |
| .22 18 gr pellet, 6.5 mm, 1:18, 900 fps | 1.8614 | 2.0000 (+7.4 %) (pellet now excluded anyway) |
| .308 168 gr, 1.215 in, 1:10, 2650 fps | 2.4590 | 2.4590 |

Effect on slug spin drift: 100 m 1.87 → 1.93 cm, 300 m 17.42 → 17.93 cm.

**(b) Litz spin drift / aerodynamic jump on subsonic PCP — partly
confirmed.** Diabolo pellets are drag-stabilised, so the gyroscopic Miller
rule and Litz's fits (derived for spin-stabilised rifle bullets) do not
apply; the app's own PCP note already restricts spin drift to slugs, but the
code applied it to pellets once a length was typed (≈2.5 cm sideways at
100 m and ≈0.048 MOA/mph vertical for a .22 18 gr pellet). Fixed:
`_stability` returns null for `AmmunitionType.pellet`. For slugs the Litz
formula is kept: it is an empirical fit to supersonic bullets (Litz 2009
ch. 10) and no peer-reviewed subsonic alternative exists; the yaw-of-repose
derivation (McCoy ch. 10/12) needs aerodynamic coefficients that are not
published for slugs. Listed as uncertain (section 5).

**(e) Profil bullet length not used — confirmed, fixed.**
`Ammunition.lengthMm` (Profil > Mühimmat, PCP, documented "used for the
stability check") never reached `_muzzleSg`. New getter `_bulletLengthMm`:
the Pro box when typed, else the profile length; 0–100 mm. The old
`_parsed(bulletLengthCtl)!` force-unwrap is gone.

#### 3.2 Numerical verification (ICAO 15 °C, 1013.25 hPa, 0 % RH; 10 mph full-value crosswind from 9 o'clock)

Inputs: .308 and 6.5 CM zero 100 m, sight height 38.1 mm; slug zero 50 m,
pellet zero 30 m, sight height 50 mm. Elevation + = dial up; drift + = to the
right; windage mrad is the app's `windMrad` (+ = dial right).

Independent reference (`python3 tools/formul_denetimi_2026_10_13.py`):

| Load | Range m | Drop cm | Elev mrad | Drift cm | Windage mrad | v m/s (fps) | TOF s |
|---|---|---|---|---|---|---|---|
| .308 168 gr G1 0.462 2650 fps | 100 | 0.00 | 0.000 | 2.35 | −0.235 | 743.4 (2439) | 0.1291 |
| | 300 | 49.12 | 1.637 | 22.98 | −0.766 | 623.7 (2046) | 0.4228 |
| | 500 | 200.45 | 4.009 | 69.93 | −1.399 | 516.3 (1694) | 0.7755 |
| 6.5 CM 140 gr G7 0.315 2710 fps | 100 | 0.00 | 0.000 | 1.66 | −0.166 | 777.7 (2551) | 0.1248 |
| | 300 | 43.25 | 1.442 | 15.85 | −0.528 | 685.8 (2250) | 0.3987 |
| | 500 | 170.45 | 3.409 | 46.94 | −0.939 | 600.6 (1971) | 0.7103 |
| 6.35 mm 50 gr slug G1 0.139 985 fps | 50 | 0.00 | 0.000 | 2.82 | −0.565 | 279.4 (917) | 0.1729 |
| | 100 | 26.40 | 2.640 | 10.96 | −1.096 | 262.6 (861) | 0.3576 |
| | 200 | 190.22 | 9.511 | 42.32 | −2.116 | 235.1 (771) | 0.7608 |
| | 300 | 532.14 | 17.736 | 93.97 | −3.132 | 212.0 (696) | 1.2094 |
| .22 18 gr pellet G1 0.03 900 fps | 50 | 5.35 | 1.070 | 11.70 | −2.340 | 212.7 (698) | 0.2084 |
| | 100 | 60.72 | 6.072 | 48.49 | −4.849 | 168.8 (554) | 0.4730 |
| | 200 | 488.01 | 24.396 | 224.94 | −11.247 | 104.4 (343) | 1.2321 |
| | 300 | 1907.83 | 63.509 | 625.46 | −20.846 | 63.1 (207) | 2.4924 |

Agreement between routes (largest absolute difference over all 14 points):

| Comparison | Elev mrad | Windage mrad | v m/s | TOF ms |
|---|---|---|---|---|
| App algorithm (Python port) vs reference | 1e-5 | 1e-5 | <1e-4 | <1e-4 |
| `formula_reference.py` DP45, same model | <1e-5 | <1e-5 | <1e-4 | <1e-4 |
| `formula_reference.py` PCHIP Cd + CIPM air (model variant) | 0.115 (pellet 300 m; ≤0.007 elsewhere ≤100 m) | 0.033 | 0.15 | 2.2 |

Hand check, Didion lag rule D = W(TOF − R/V₀) (McCoy eq. 5.33): .308 500 m
4.4704·(0.7755 − 500/807.72) = 69.96 cm vs 69.93 cm; pellet 100 m 48.5 cm vs
48.49 cm. All 14 points within 0.5 % (pinned in the Python test).

Pinned in `test/formul_denetimi_2026_10_13_test.dart` (production
`BallisticEngine` vs the table: ±0.005 mrad, ±0.02 m/s, ±0.1 ms) and
`tools/test_formul_denetimi_2026_10_13.py` (routes agree, Dart vectors equal
the script output, Miller floor values, source contracts).

#### 3.3 Reviewed, not changed

* **(c) `drag_band_truing.dart` band edges 1.2/1.5/2.0 — confirmed as a
  limitation, not a calculation error.** A PCP shot (Mach ≈ 0.55–0.9) only
  resolves band 0 ("Mach 1,2 altı"), so the fit is one uniform Cd scale
  (equivalent to BC truing with the Tikhonov prior). The result is labelled
  correctly (other bands "not fitted"). Suggestion for the owner: a subsonic
  band set for all-subsonic flights (e.g. edges 0.7/0.8/0.9, where the G1 Cd
  rises from 0.217 to 0.342). That needs new band labels (UI wording), so it
  is left for a decision.
* **(d) Stability/transonic notices only on firearms — by design** (Ö5 plan,
  `docs/yeni-hesaplar-2026-10-11.md`, platform "Ateşli"). Correct for
  pellets. For slugs a Sg < 1 warning would be supportable, but the "−3 % BC
  per 0.1 Sg" text comes from Litz's rifle-bullet tests; owner decision.
* Speed of sound uses γ = 1.4 with moist density (≤ +0.33 % at 50 °C/90 %);
  zero always solved in ICAO air; BC used with actual density (ICAO-referenced
  BC convention). Same as the 2026-10-11 audit; negligible.

### 4. Deletions (Part B)

All found by full-repo reference counts (lib, test, integration_test, tools,
garmin, watch, .github) and re-checked by grep; none is referenced anywhere.
Behaviour unchanged; Python suite (732 tests) and offline Dart lint pass.

| Removed | File | Reason |
|---|---|---|
| `ProfileFieldInfo.caliberOther` | `lib/features/profiles/profile_field_info.dart` | text constant, 0 references |
| `EnvironmentFieldInfo.spinDrift` | `lib/features/ballistics/environment_field_info.dart` | text constant, 0 references (the UI uses `ProSectionInfo.spinDrift`) |
| `MenzilRadius.hold` | `lib/ui/menzil_theme.dart` | 0 references |
| `ToolFormat.velocity` | `lib/features/tools/tool_support.dart` | 0 references |
| `UserCatalogStore.rifle/.ammunition/.scope` (+ now-unused `domain.dart` import) | `lib/services/user_catalog_store.dart` | static mappers never called; `UserCatalog` builds the records |
| `LevelController.setAutoMode`, `cancelCalibrationCapture`, `clearAllCalibration` | `lib/tools/state/level_controller.dart` | 0 references |
| `GravityFilter.isAdaptive` getter | `lib/tools/domain/tilt_math.dart` | 0 references |
| `ColdBoreSummary.correctionRightMrad` | `lib/tools/domain/cold_bore.dart` | 0 references |

Candidates **not** deleted:

| Candidate | Why kept |
|---|---|
| `lib/features/profiles/bullet_library_screen.dart` (+ 2 widget tests in `test/bullet_library_test.dart`) | unreachable from `main.dart`; file deletion was not permitted in this unattended run — owner decision |
| `assets/fonts/DejaVuSans-Bold.ttf` (pubspec asset) | never loaded (the PDF uses `DejaVuSans.ttf`); same reason |
| `lib/data/cartridge_specs.dart` | test-only, but it is a sourced data catalogue (C.I.P./SAAMI); data catalogue rule |
| `StandardDragTables` source-name/URL constants | unused in code but they are the table provenance |
| `_coriolisOn`, `_spinDriftOn`, `_gravityOn` (`= true`) in `ballistics_screen.dart` | make the "kapalı" branches unreachable; the values are still written to `ShotSettings` (saved format, read by `truing_screen.dart`). Simplifying needs analyzer access; listed for a follow-up |
| `PressureKind.station`, `VisionAssist` path, `Oswald` light/semibold/bold fonts | not provably dead without the SDK, or tied to a reserved port |
| Test-only helpers (`Wez.atLeastOneHit`, `solveNoWind`, `ReticleHolds.marks`, `MemoryProfileStore`, …) | used by tests / test doubles |
| Hidden features: `SHOT_TABLE_SWITCH`, `WELCOME_RESTORE`, `PCP_AMMO_BRAND`, `GOOGLE_MAPS_ENABLED`, `METNO_CONTACT` | hidden on purpose (owner rule) |

### 5. Remaining uncertainty

1. Spin drift and aerodynamic jump for subsonic slugs: Litz's fits are
   empirical for supersonic bullets; magnitude for slugs is approximate.
2. GA table provenance (forum export, marked UNVERIFIED in code).
3. Published BCs may refer to Army Standard Metro rather than ICAO (a few %);
   a data question, not a formula one.
4. Dart tests could not be run here; CI result is reported in the PR.

### 6. References

* ICAO Doc 7488/3, *Manual of the ICAO Standard Atmosphere*, 1993.
* Picard, A. et al., "Revised formula for the density of moist air
  (CIPM-2007)", *Metrologia* 45 (2008) 149, https://doi.org/10.1088/0026-1394/45/2/004
* WMO-No. 8, *Guide to Instruments and Methods of Observation*, 2018,
  https://library.wmo.int/idurl/4/41650
* NIMA TR8350.2, *Department of Defense World Geodetic System 1984*, 3rd ed., 2000.
* NIST SP 811 (2008), Appendix B, https://www.nist.gov/pml/special-publication-811
* McCoy, R. L., *Modern Exterior Ballistics*, Schiffer, 1999 (ch. 4 drag and
  form factor, ch. 5 point-mass equations and lag rule, ch. 10 gyroscopic
  stability).
* BRL G1/G7 drag functions (as stored in `lib/core/standard_drag_tables.dart`).
* Miller, D. G., "A New Rule for Estimating Rifling Twist", *Precision
  Shooting*, March 2005.
* Courtney, M. W. & Miller, D. G., "A Stability Formula for Plastic-Tipped
  Bullets: Part 1", *Precision Shooting*, Jan 2012, arXiv:1410.5340,
  https://arxiv.org/abs/1410.5340 (subsonic velocity factor).
* Litz, B., *Applied Ballistics for Long Range Shooting*, 2009, ch. 10 (spin
  drift eq. 10.1, aerodynamic jump).
* Dormand, J. R. & Prince, P. J., *J. Comput. Appl. Math.* 6 (1980) 19
  (used by `tools/formula_reference.py`).

### 7. Reproduce

```bash
python3 tools/formul_denetimi_2026_10_13.py            # table above
python3 tools/formul_denetimi_2026_10_13.py --dart     # Dart vectors
python3 -m unittest tools.test_formul_denetimi_2026_10_13
flutter test test/formul_denetimi_2026_10_13_test.dart test/stability_test.dart
```
