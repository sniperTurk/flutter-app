# PCP saçma (diabolo) ve slug: en doğru yörünge nasıl hesaplanır?

Tarih: 2026-10-12 · Zamanlanmış görev (sahibi çevrimdışı) · Dal: `research/hassas-hesap`
Yalnız araştırma: `lib/` ve `test/` değişmedi.

Kaynak kuralı: yalnız üretici sitesi ve bilimsel/akademik/devlet kaynağı. Forum, blog, bayi,
YouTube ve başka balistik uygulamalarının verisi (ChairGun, Strelok, Applied Ballistics,
QuickLOAD, GRT, JBM) kullanılmadı. JSB'nin resmî sitesi robots.txt ile otomatik erişime kapalı
olduğu için **okunmadı**. Kaynak numaraları ([S1] …) en alttaki tabloda.

Örnek sayıların hepsi depodaki referans çözücüyle (`tools/formula_reference.py`, noktasal kütle,
uygulamadaki G1/G7 tabloları) hesaplandı. Senaryo: sahibin atışı. 6,35 mm (.249"), 50 gr slug,
985 fps (300,2 m/s; 15 °C'de Mach 0,88), sıfır 100 m, nişan yüksekliği 60 mm, ICAO hava
(15 °C, 1013,25 hPa), 4 m/s tam yan rüzgâr. Slug için yayımlanmış bir BC olmadığından
**varsayım olarak G1 BC 0,14** alındı. Mutlak sayılar bu varsayıma bağlı. Farklar ve
duyarlılıklar ise yöntemleri karşılaştırmak için kullanılabilir.

---

## Türkçe özet

### Kısa cevap

1. **500 m'de en çok hata nereden gelir?** Önem sırasıyla: rüzgâr, mesafe, sürüklenme
   eğrisinin biçimi/BC, hava yoğunluğu, namlu çıkış hızı. Spin sapması ve Coriolis bunların
   yanında küçük kalır. Sahibin slugu 500 m'de ses hızının yarısına (Mach 0,51) kadar yavaşlar ve
   havada 2,25 s kalır. Bu yüzden küçük hatalar büyür (§B.6 tablosu).
2. **G1 mi, G7 mi, GA mı?** Slug için sayısal Cd–Mach eğrisi yayımlayan ne üretici ne de
   bilimsel kaynak bulundu. Saçma (diabolo) için de bulunamadı. GA, G1'in yaklaşık 0,93 katı
   (önceki rapor `docs/sacma-surukleme/RAPOR.md`), bu yüzden kaldırıldı. **Tek BC'yle hangi
   modelin seçildiğinin önemi kısa mesafede azdır, uzak mesafede büyüktür.** BC'leri 100 m'deki
   hız aynı olacak şekilde eşlenmiş G1 ve G7, 300 m'de 7 cm, **500 m'de 92 cm** farklı düşüş
   verir. Doğru biçimi bugün hiçbir kaynak söylemiyor. Bu yüzden 500 m için çözüm, eğriyi
   **uzak mesafede atışla doğrulamaktır**.
3. **BC bilinmiyorsa:** (a) kronografla iki mesafede hız ölçülür (namlu ağzı ve 50/100 m),
   BC çözülür. Beklenen belirsizlik %2–4'tür, ama bu BC yalnız Mach 0,88–0,77 aralığında
   geçerlidir. (b) 200/300/400–500 m'de düşüş ölçülür ve eğri bu mesafelere uydurulur. 500 m için
   asıl doğru sonucu (b) verir.
4. **Ağırlık + uzunluk + kalibreden BC çıkar mı?** Güvenilir biçimde çıkmaz. Kesit yoğunluğu
   (SD) doğru hesaplanır, ama biçim katsayısı (i) uç şekline, oyuk tabana ve hıza bağlıdır.
   H&N'nin kendi yayımladığı BC'lerden çıkan i değerleri aynı ürün ailesinde **0,57 ile 0,97
   arasında** dağılıyor (§B.3). SD'den tahmin, en fazla "başlangıç değeri" olabilir: ±%20 BC
   hatası, 500 m'de yaklaşık ±1,5 m düşüş hatası demektir. Uzunluk, BC için değil, **kararlılık
   (Miller Sg) uyarısı** için işe yarar.
5. **Hız:** Namlu çıkış hızı kronografla ve en az 10 atışla ölçülmeli. Ortalama ve SD girilmeli.
   ±5 fps fark 500 m'de ±12,5 cm düşüş farkı yapar. 3 fps SD, 500 m'de yaklaşık 7,5 cm dikey
   saçılma ekler. PCP'de sıcaklık için yayımlanmış bir katsayı yok. Hız, atış yapılacak
   sıcaklığa yakın bir günde ölçülmeli (`docs/pcp-hiz/GORUS.md`).
6. **Diabolo saçma:** Saçma hem kuyruğunun sürüklenmesiyle (ağırlık merkezi basınç merkezinin
   önünde) hem dönüyle kararlı uçar [S9]. Tipik uçuş hızı Mach 0,5–0,8'dir (≈ 560–890 fps)
   [S9]. G1'de Cd, Mach 0,8'den (893 fps) sonra hızla yükselir: Mach 0,7'den 0,9'a +%58. Bir CFD
   çalışmasında Mach 1,0 ile çıkan 4,5 mm saçmalar 25 m'de Mach 0,66–0,71'e düşüyor [S11]. Yani
   ses hızına yakın atmak, menzil kazandırmadan sürüklenmeyi artırır. "900–950 fps üstünde
   kararsızlık" için sayısal eşik veren bir üretici veya hakemli kaynak **bulunamadı**. Air Arms
   yalnızca "yüksek güçlü tüfeklerde çok hafif saçmalar daha az kararlı olabilir" diyor [S14].
7. **Rüzgâr:** Sapma = rüzgâr × (uçuş süresi − mesafe / namlu hızı). Bu, noktasal kütle
   modelinin tam sonucudur ve çözücüyle birebir doğrulandı (§B.5). 100 m'de 4 m/s yan rüzgârda
   .22 saçma 37 cm, slug 10 cm sapar.

### Uygulama için öneri (etkiye göre sıralı)

| # | Ne | Zorunlu mu | Neden / etkisi (500 m, sahibin slugu) |
|---|---|---|---|
| 1 | **Rüzgâr** (atış anında) | Atış sırasında | 4 m/s → 234 cm. 0,5 m/s hata → yaklaşık 29 cm |
| 2 | **Mesafe** (telemetre) | Atış sırasında | 1 m hata → 9,5 cm düşüş (300 m'de 4,2 cm) |
| 3 | **Uzak mesafe doğrulaması** ("BC'yi atışla bul", ≥ 3 mesafe) | 150 m üstü için şiddetle önerilir | Model biçimi 92 cm, BC ±%5 ise ±40–45 cm |
| 4 | **Hava** (sıcaklık, basınç) | Zorunlu (uygulamada var) | 0 °C'de +85 cm, 900 hPa'da −95 cm |
| 5 | **Namlu çıkış hızı** (kronograf ortalaması, ≥ 10 atış) | Zorunlu | ±5 fps → ±12,5 cm |
| 6 | **Hız SD'si** | İsteğe bağlı | Beklenen dikey saçılma: 1 m/s SD → yaklaşık 8 cm |
| 7 | **BC** | İsteğe bağlı, boşsa G1 | Boşsa yalnız başlangıç değeridir. 6. ve 3. adımla bulunur |
| 8 | **Ağırlık** | Zorunlu | SD hesabı ve kararlılık |
| 9 | **Uzunluk** | Slug için isteğe bağlı | Yalnız Miller Sg uyarısı (Sg < 1,3) |
| 10 | Tip (slug / saçma) | Zorunlu | Model ve uyarıları seçer (aşağıda) |
| 11 | Yiv adımı (tüfekten) | Slug için isteğe bağlı | Sg uyarısı |

**Model seçimi:**

- **Saçma:** G1, üreticinin verdiği BC ile. Kaynağı belirsiz bir "saçma eğrisi" eklenmemeli
  (önceki rapor). Spin sapması uygulanmamalı (aşağıda).
- **Slug:** G1 varsayılan kalsın. Ama ekranda "BC atışla doğrulanmadı; 150 m üstü tahmindir"
  uyarısı gösterilmeli. Kullanıcının kendi Doppler eğrisi varsa mevcut "özel eğri" alanı
  kullanılır.

**Uygulamadaki çok mesafeli doğrulama için bulgu:** `lib/core/drag_band_truing.dart`'ta bant
sınırları `[1,2; 1,5; 2,0]` Mach. PCP'nin tüm uçuşu Mach 1,2 altında kaldığı için üç mesafe
girilse bile **tek bant** uydurulur. Bu, tek BC düzeltmesiyle aynı şeydir; eğrinin biçimi
düzelmez. PCP için ses altı bant sınırları (örneğin Mach 0,6 ve 0,75) önerilir. Bunlar sahibin
slugunun 100–500 m arasını iki-üç parçaya böler. Ayrıca `maxChangeFraction = 0,20`, SD'den
tahmin edilmiş bir başlangıç BC'si için dar kalabilir. Bu PR kodu **değiştirmez**. Karar sahibin.

**"BC'yi atışla bul" iş akışı (öneri):**

1. **Hava:** O günün sıcaklığı ve basıncı (uygulamada var).
2. **Hız:** Kronograf namlunun 2–3 m önünde. En az 10 atış. Ortalama ve SD kaydedilir
   (Courtney: 10 atış çoğu durumda ortalama için ≈ %1 SEM verir [S3]).
3. **(İsteğe bağlı) İki kronograf noktası:** Kronograf 50 m'ye (güvenliyse 100 m'ye) taşınır.
   Aradaki mesafe **şeritmetreyle** ölçülür, telemetreyle değil [S3]. En az 10 atış daha
   yapılır. Uygulama BC'yi çözer (formül §B.2). Hız kaybı %5–20 olmalı [S3]. 50 m'de kayıp %6,9,
   100 m'de %12,5'tir. Tek kronograf taşındığı için iki ortalamanın SEM'i birleşir.
4. **Düşüş:** 200, 300 ve 400 veya 500 m. Her mesafede 5 atışlık grup, grup merkezinin
   nişandan farkı (mrad) ölçülür. Önce hız doğrulanır (kısa mesafe), sonra uzak düşüşler girilir.
5. **Kontrol:** Ara bir mesafede (örneğin 350 m) tahmin ve atış karşılaştırılır.

Not: Dürbün kliklerinin gerçek değeri doğrulanmadıysa klik hatası BC hatası gibi görünür.
Uzak mesafe doğrulamasından önce klik değeri bir kez ölçülmelidir.

---

## English details

### B.1 Drag models: what exists and how good G1 is

**What is published.**

| Projectile | Published by manufacturers | Published in science | Notes |
|---|---|---|---|
| Diabolo pellets | Single BC, no model or velocity stated (H&N [S12]; Air Arms page gives no BC [S14]; JSB not read, robots.txt) | Wind-tunnel Cd at one Mach only, ≈ 0.58 (Ladommatos [S9], [S10]). CFD at M 0.7/1.0/1.3, graphs only (Rafeie [S11]). Free-flight G1 BCs at 480–790 ft/s (Courtney [S3]) | No Cd–Mach curve covering Mach 0.6–1.0 with reuse permission (see `docs/sacma-surukleme/RAPOR.md`) |
| Slugs | Single BC, no model or velocity (H&N Slug HP: .177 10 gr 0.08, 13 gr 0.084, 20 gr 0.094; .22 23 gr 0.094; .25 36 gr 0.105 [S12]). FX Halo: "much higher BC", no number [S13] | **None found** | Turkish custom makers publish no BC (owner) |
| Analogue: .22 LR lead bullet | — | McCoy BRL-MR-3877: spark-range aero data at Mach 0.77–1.03, CD0 in figures only [S8] | Closest public aero data to a lead slug at PCP speeds |

**GA / GA2.** These "airgun" curves come from airgun ballistics software (excluded source
class). The app removed GA on 2026-10-12. Below Mach 0.7, GA is ≈ 0.93 × G1, so with a trued
BC it gave no accuracy gain (≤ 0.1 cm difference to 100 m, `docs/sacma-surukleme/RAPOR.md`).
No GA2 table was found in a primary source.

**G1 vs G7 in the PCP Mach range** (app tables, PCHIP):

| Mach | ≈ fps (15 °C) | Cd G1 | Cd G7 | G7/G1 |
|---:|---:|---:|---:|---:|
| 0.5 | 558 | 0.2032 | 0.1194 | 0.588 |
| 0.6 | 670 | 0.2034 | 0.1194 | 0.587 |
| 0.7 | 781 | 0.2165 | 0.1202 | 0.555 |
| 0.8 | 893 | 0.2546 | 0.1242 | 0.488 |
| 0.85 | 949 | 0.2901 | 0.1306 | 0.450 |
| 0.9 | 1005 | 0.3415 | 0.1464 | 0.429 |
| 0.95 | 1060 | 0.4084 | 0.2054 | 0.503 |
| 1.0 | 1116 | 0.4805 | 0.3803 | 0.791 |

A BC only scales the curve, so only the *shape* (the ratio column) affects the result once the
BC is trued. From Mach 0.5 to 0.9, G1 rises by 68 % and G7 by 23 %. A projectile launched at
Mach 0.88 that slows to Mach 0.5 crosses this whole region, so the choice of shape matters.

**How much (owner scenario).** G7 BC chosen so the velocity at 100 m equals the G1 solution
(this is what a chronograph-trued BC does):

| Range m | 100 | 200 | 300 | 400 | 500 | 600 |
|---|---:|---:|---:|---:|---:|---:|
| G7 − G1 drop, cm | 0.0 | +0.5 | +7.0 | +31.3 | **+91.6** | +215.0 |
| G7 − G1 wind, cm | +0.3 | −0.9 | −5.7 | −16.0 | −33.2 | −58.9 |

The same comparison with the G7 BC matched to the **drop at 300 m** gives +11.4 cm at 400 m,
+46.5 cm at 500 m and +124.9 cm at 600 m. Even a trued single BC leaves a shape uncertainty of
about half a metre at 500 m. Multi-range truing (B.6) removes it.

**Which shape is closer for a slug?** No measurement says. By geometry, a flat-base, blunt-nosed
slug is closer to the G1 standard projectile (flat base, short ogive) than to G7 (boat-tail,
long ogive) [S1]. That argument is weak, because hollow points and hollow bases change the flow.
The Doppler study [S4] found G7 BC nearly velocity-constant for *boat-tail* rifle bullets
(208 gr ELD: G7 0.348 at 2888 ft/s, 0.337 at 1353 ft/s) and recommends measuring "drag more
directly throughout the velocity region of interest" for long-range work. It contains no
slugs.

**Transonic notes (1000–1125 fps, Mach 0.9–1.0).** In the .22 LR analogue [S8]: round-to-round
drag scatter was about 2 % (σ 0.005). Bullet designs of the same calibre differed by 8–13 % in
drag over Mach 0.80–0.975. Pitch damping was statistically zero at transonic and subsonic speed.
A slow-arm yaw limit cycle of about 1.8° formed near 50 m and added about 2 % drag. Launching a
slug at Mach ≥ 0.95 therefore puts it on the steepest part of every curve and adds yaw-dependent
drag that no G-model contains. The owner's 985 fps (Mach 0.88) is below that region.

### B.2 Unknown BC: deriving it from measurements

**Definitions** [S1]:

- Sectional density `SD = m_gr / (7000 · d_in²)` (lb/in²).
- Form factor `i = Cd_projectile(M) / Cd_G(M)`.
- `BC_G = SD / i`.
- Point-mass deceleration with a G-model:

```
dv/dt = − ρ · v² · π · Cd_G(M) / (8 · BC_SI),     BC_SI = BC[lb/in²] × 703.0696 kg/m²
```

The last line follows from `a = ρ v² A Cd / (2m)`, `A = π d²/4`, `Cd = i · Cd_G`. It is the
same law the app integrates.

**Method 1 – two chronograph velocities (near/far)** [S3]. Courtney et al. use
`Cd = m (v_i² − v_f²) / (x · A · v̄² · ρ)` over the interval x. In BC form, with Cd_G taken at the
mean Mach of the interval:

```
BC ≈ π · ρ · Cd_G(M̄) · x / (8 · 703.0696 · ln(v0 / vx))
```

Check against the full solver (owner scenario, true BC 0.140): x = 50 m gives 0.13997 and
x = 100 m gives 0.13992. For production, solve BC by bisection on the full trajectory, as the
solver already does for zeroing. That removes the mean-Mach approximation.

Error budget [S3]:

- Use a separation that gives 5–20 % velocity loss (≈ 10 % is a good compromise).
- Drag error ≈ 10 × relative velocity error.
- Relative error between the two readings matters more than absolute accuracy.
- A 1 % separation error gives a 1 % drag error. Use a tape, not a laser rangefinder.
- 10 shots per string reach about 1 % SEM in many cases.
- A 10 mph headwind over 100 yd adds ≈ 0.6 %.

Owner numbers:

| Separation | Velocity loss | Far-velocity error 0.25 % (0.75 m/s) | 0.5 % (1.5 m/s) |
|---|---:|---:|---:|
| 50 m | 6.9 % | BC −3.9 % | BC −7.6 % |
| 100 m | 12.5 % | BC −2.4 % | BC −4.7 % |

One chronograph moved between stations means two independent means. With 0.9 m/s (3 fps) SD and
10 shots each, the difference has SEM ≈ 0.41 m/s. That is about ±2.1 % BC at 50 m and ±1.3 % at
100 m. The Caldwell's accuracy specification could not be read from the manufacturer's site
(fetch failed). The table therefore shows 0.25 % and 0.5 % as parameters, not as Caldwell
values.

**Method 2 – time of flight.** About twice the uncertainty of near/far for the same instrument
accuracy [S3]. Not recommended with an optical chronograph.

**Method 3 – drop at known ranges (truing).** Fit BC (or a per-band scale) so that predicted
elevation matches the group centres. Sensitivity in the owner scenario: BC ±5 % moves the drop
by −6.8/+7.6 cm at 300 m and −39.6/+44.8 cm at 500 m. At 300 m, a 3 cm uncertainty in the group
centre therefore pins BC to about ±2 %, but only after MV is known. ±5 fps MV also moves the drop
3.4 cm at 300 m, which is the same size as a 2.4 % BC error. **Order: MV first, then far drops.**

**Scope of each method.** Methods 1 and 2 measure drag over Mach 0.88→0.77 only. Method 3 at
200–500 m covers Mach 0.69→0.51, where the owner actually shoots. For > 300 m, Method 3 is the
only one of the three that measures the relevant Mach range.

### B.3 Weight + length + calibre: what they can and cannot give

- **SD** is exact: the owner's 50 gr .249 slug has SD 0.1152 lb/in².
- **Form factor from published H&N BCs** (i = SD/BC; model and velocity not stated by H&N [S12]):

| H&N product | SD | Published BC | Implied i |
|---|---:|---:|---:|
| Slug HP .177 10 gr (6 mm long) | 0.0456 | 0.08 | 0.57 |
| Slug HP .177 13 gr (6 mm) | 0.0593 | 0.084 | 0.71 |
| Slug HP .177 20 gr (8.4 mm) | 0.0912 | 0.094 | 0.97 |
| Slug HP .22 23 gr (7.1 mm) | 0.0698 | 0.094 | 0.74 |
| Slug HP II .25 36 gr (8.3 mm) | 0.0829 | 0.105 | 0.79 |

  Within one product family, i spans 0.57–0.97, and the longer slug has the *worse* form
  factor. Either the published numbers come from different velocities or methods, or form factor
  cannot be transferred between products. With i = 0.7–1.0, the owner's slug would be
  BC 0.115–0.165 (G1). That is ±18 %, or roughly ±0.75–0.9 m of drop at 500 m (B.6, scaled).
  **Use it only as a starting value flagged "estimated".**
- **Semi-empirical prediction.** BRL's MC DRAG [S19] predicts Cd from geometry over Mach 0.5–5.
  It needs nose length, ogive radius, meplat, boat-tail and band dimensions, and it does not
  model diabolo skirts or hollow bases (`docs/sacma-surukleme/RAPOR.md`). It does not fit a
  simplified form.
- **Gyroscopic stability (Miller)** [S6], [S7]:

```
Sg = 30 m / (t² d³ L (1 + L²)) × (V/2800)^(1/3) × ((T_F + 460)/519) × (29.92 / P_inHg)
```

  Here m is in gr, d in in, t and L in calibres, and V in ft/s. The rule assumes uniform
  density. Courtney and Miller show that it fails for plastic-tipped bullets: replacing L by
  the metal length in `(1+L²)` restores accuracy [S6]. A hollow base or deep hollow point
  breaks the same assumption. The velocity factor was fitted to rifle bullets. Its behaviour
  near and below the speed of sound is not documented in [S6]. Thresholds: Sg < 1.0
  tumbles. BC loss begins at or below Sg ≈ 1.25, and > 1.3 is "probably ample margin" [S5]. In
  the .22 LR analogue, Sg 1.5 at Mach 0.97 was sufficient in all weather and Sg 1.25 was too low
  in cold air [S8]. Owner examples (50 gr, 985 fps, ICAO): 9 mm long slug at 1:18" twist
  Sg 3.05, at 1:22" Sg 2.04, at 1:30" Sg 1.10. 10 mm at 1:22" gives Sg 1.59. **Use length for a
  warning (Sg < 1.3: "keyholing risk, test at 50 m"), not for BC.**
- **Pellets:** the diabolo is stabilised aerodynamically (centre of mass ahead of centre of
  pressure) *and* by spin [S9]. The Miller rule does not apply. Pellets do not need a length
  input.

### B.4 Velocity

- **Mean MV** drives the solution. Owner scenario: ±5 fps → ±12.5 cm at 500 m, ±10 fps →
  ±25 cm.
- **SD/ES:** vertical spread from velocity ≈ |∂drop/∂v| × σv ≈ 8.2 cm per m/s at 500 m.
  3 fps SD gives ≈ 7.5 cm vertical SD from velocity alone. Record SD from the same 10+ shot
  string and show the expected vertical spread at the target range. ES grows with sample size;
  SD is the stable statistic [S3: SEM ∝ 1/√n].
- **Regulator / temperature:** a regulated PCP holds velocity while the tube stays above the
  regulator set-point; velocity drops below it [K1 in `docs/pcp-hiz/GORUS.md`]. Tube pressure
  scales with absolute temperature (p = ρRT) [K7 there]. No manufacturer or peer-reviewed
  PCP velocity-vs-temperature coefficient was found, so none should be invented. Measure MV on a
  day near the shooting temperature. The app already follows this.
- **Air density** (not PCP velocity, but large): 0 °C instead of 15 °C → +17.9 cm at 300 m and
  +84.8 cm at 500 m. 900 hPa instead of 1013 hPa → −17.8 / −94.7 cm. Station pressure and
  temperature are mandatory inputs at this range.

### B.5 Diabolo-specific effects

- **Drag at high velocity.** Typical pellet flight is Mach 0.5–0.8 [S9]. The CFD study [S11]:
  4.5 mm pellets launched at Mach 1.0 fall to Mach 0.66–0.71 within 25 m, and at Mach 1.3 to
  Mach 0.74–0.80. "The pressure drag force increases as Mach number rises." Pushing a pellet
  toward Mach 1 mostly buys drag.
- **Instability above ~900–950 fps.** No manufacturer or peer-reviewed source with a numerical
  threshold was found. Air Arms (qualitative): "In high-power rifles, very light pellets may
  become less stable" [S14]. H&N gives minimum and recommended *energy* per product (e.g. .25
  36 gr slug: at least 40 J, 60–90 J recommended), not maximum velocity [S12]. **Recommendation:**
  show an informational note above Mach 0.85 (≈ 950 fps at 15 °C) for pellets, stating that the
  G1 Cd rises steeply there. Do not show a hard limit.
- **Spin drift.** The yaw-of-repose theory (Lieske & Reiter, BRL 1314 [S2]) was derived for
  spin-stabilised, dynamically stable shells. A drag-stabilised diabolo does not fit it, and no
  pellet spin-drift measurement was found. **Do not apply spin drift to pellets.** For slugs,
  treat any spin-drift value as an estimate and let windage truing absorb it. (The app's current
  spin-drift fit comes from rifle bullets in a reference outside the allowed source class. It
  was not evaluated here.)
- **Wind.** For any point-mass trajectory: drift = W · (t − x / v0) (lag time). This was
  verified in the solver with ratio 1.000 for all three loads below. At 4 m/s full value:

| Load (G1) | 50 m | 100 m |
|---|---:|---:|
| .22 18.13 gr pellet, BC 0.035, 290 m/s | 9.2 cm | 36.7 cm |
| .25 25.4 gr pellet, BC 0.045, 280 m/s | 7.0 cm | 28.1 cm |
| .25 50 gr slug, BC 0.14, 300 m/s | 2.5 cm | 9.7 cm |

### B.6 Owner scenario: baseline and error ranking

Baseline (G1 BC 0.14 assumed, 985 fps, zero 100 m, 4 m/s full-value wind):

| Range m | Drop cm (mrad) | Wind cm | v m/s | Mach | TOF s |
|---:|---:|---:|---:|---:|---:|
| 100 | 0.0 (0.00) | 9.7 | 262.8 | 0.77 | 0.357 |
| 200 | 136.2 (6.81) | 37.6 | 235.4 | 0.69 | 0.760 |
| 300 | 449.8 (14.99) | 83.4 | 212.6 | 0.62 | 1.208 |
| 400 | 981.3 (24.53) | 148.2 | 192.7 | 0.57 | 1.703 |
| 500 | 1778.5 (35.57) | 233.6 | 174.9 | 0.51 | 2.250 |
| 600 | 2899.3 (48.32) | 342.0 | 158.9 | 0.47 | 2.854 |

Sensitivity at 500 m (drop unless noted):

| Error | Effect at 500 m |
|---|---:|
| Wind 0.5 m/s (of 4 m/s) | ≈ 29 cm lateral (linear in W) |
| Range 1 m | 9.5 cm |
| Drag shape G1↔G7 (BC matched at 100 m) | 92 cm |
| Drag shape G1↔G7 (BC matched by drop at 300 m) | 47 cm |
| BC −5 % / +5 % | +44.8 / −39.6 cm (wind +13.2 / −11.7 cm) |
| Air 0 °C vs 15 °C | +85 cm |
| Pressure 900 vs 1013 hPa | −95 cm |
| MV ±5 fps | ±12.5 cm |
| MV SD 3 fps | ≈ 7.5 cm vertical SD |

### B.7 Recommendation for the app

**Inputs**

- Required: type (slug/pellet), weight, MV (chronograph mean). Calibre comes from the rifle.
  Conditions (temperature, pressure) are taken at the shot.
- Optional: BC (empty → G1 with an "estimated" flag and a start value), MV SD, length (slugs:
  Sg warning only), twist (from the rifle).
- Do not add a pellet drag table or GA again unless a reusable Cd–Mach measurement covering
  Mach 0.5–1.0 is published.

**Model**

- Pellet: G1 + manufacturer BC. No spin drift. Informational note above Mach 0.85.
- Slug: G1 by default. Warn "untrued above 150 m" until truing exists. The existing
  custom-curve field is for the user's own Doppler data.

**"BC'yi atışla bul"**

1. MV (≥ 10 shots, mean + SD).
2. Optional near/far chronograph BC (tape-measured 50–100 m), solved on the full trajectory.
3. ≥ 3 far ranges (e.g. 200/300/400–500 m), fitted with **subsonic band edges for PCP**
   (e.g. Mach 0.6 and 0.75 instead of the firearm edges 1.2/1.5/2.0 now in
   `drag_band_truing.dart`). Reconsider `maxChangeFraction` 0.20 when the start BC is only an SD
   estimate.
4. Verify at an intermediate range.

**Not recommended**

- BC from SD × guessed form factor as a final value.
- A PCP temperature coefficient.
- Miller Sg for pellets.

### B.8 Limits of this study

- The numbers are from the point-mass reference solver with the app's G1/G7 tables. The BC 0.14
  is an assumption. Coriolis, spin drift and aerodynamic jump were not included.
- The G1/G7 tables in the app state their provenance as BRL tables downloaded from JBM's site
  (`lib/core/standard_drag_tables.dart`). That file was not changed or re-sourced here.
- Not read: JSB official site (robots.txt), Caldwell product page (fetch error), McCoy's book
  (offline reference; [S1] claims are textbook-standard definitions).

## Source table

Accessed 2026-10-12.

| # | Source | Type | Used for |
|---|---|---|---|
| S1 | R. L. McCoy, *Modern Exterior Ballistics*, Schiffer, 1999, ISBN 0-7643-0720-7 (book, not fetched) | Textbook | BC / form-factor / SD definitions, G1/G7 standard projectile shapes, point-mass and lag-time wind |
| S2 | R. F. Lieske, M. L. Reiter, "Equations of Motion for a Modified Point Mass Trajectory", BRL Report 1314, 1966 — https://apps.dtic.mil/sti/pdfs/AD0485869.pdf ("Distribution of this document is unlimited") | US Army BRL | Yaw-of-repose / spin drift scope (spin-stabilised shells) |
| S3 | E. Courtney, A. Courtney, M. Courtney, "Methods for Accurate Free Flight Measurement of Drag Coefficients", arXiv:1503.05504 — https://arxiv.org/pdf/1503.05504 | Scientific preprint | Near/far formula, error budget, 5–20 % loss, tape vs rangefinder, 10 shots ≈ 1 % SEM, TOF ≈ 2× uncertainty, pellet G1 BCs |
| S4 | E. Courtney, C. Morris, M. Courtney, "Accurate Measurements of Free Flight Drag Coefficients with Amateur Doppler Radar", arXiv:1608.06500 — https://arxiv.org/pdf/1608.06500 | Scientific preprint | G7 vs G1 velocity dependence (boat-tails), "measure drag throughout the velocity region" |
| S5 | E. R. Courtney, M. W. Courtney, "Aerodynamic Drag and Gyroscopic Stability", arXiv:1309.5039 — https://arxiv.org/pdf/1309.5039 | Scientific preprint | BC loss at Sg ≤ 1.25, Sg > 1.3 margin |
| S6 | M. Courtney, D. Miller, "A Stability Formula for Plastic-Tipped Bullets, Part 1", arXiv:1410.5340 — https://arxiv.org/pdf/1410.5340 | Scientific preprint | Miller rule with velocity/atmosphere corrections; uniform-density assumption and its failure |
| S7 | D. Miller, "A New Rule for Estimating Rifling Twist", *Precision Shooting*, March 2005 (cited via S6; original not fetched) | Original publication | Miller twist rule |
| S8 | R. L. McCoy, "Aerodynamic Characteristics of Caliber .22 Long Rifle Match Ammunition", BRL-MR-3877, 1990 — https://apps.dtic.mil/sti/pdfs/ADA229713.pdf ("Approved for public release") | US Army BRL | Lead projectile at Mach 0.77–1.03: Sg 1.5 / 1.25, 2 % drag scatter, 8–13 % design spread, zero pitch damping, 1.8° limit cycle (+2 % drag) |
| S9 | N. Ladommatos, "Influence of air rifle pellet geometry on aerodynamic drag", Proc. IMechE P (2019), doi:10.1177/1754337119831107 — accepted text https://discovery.ucl.ac.uk/id/eprint/10072258 | Peer-reviewed | Diabolo stabilisation (CM ahead of CP + spin), typical Ma 0.5–0.8, Cd at Ma 0.58 |
| S10 | N. Ladommatos, "Drag coefficients of air rifle pellets with wide range of geometries", Proc. IMechE C (2021), doi:10.1177/0954406221991190 | Peer-reviewed (abstract) | Cd 0.36–0.78, small change 120→200 m/s |
| S11 | M. Rafeie, A. R. Teymourtash, "Aerodynamic and dynamic analyses of three common 4.5 mm-caliber pellets in a transonic flow", Scientia Iranica B 23(4), 2016 — https://scientiairanica.sharif.edu/article_3924.html | Peer-reviewed (CFD) | Mach at 25 m from M0 1.0 / 1.3; pressure drag rises with Mach |
| S12 | H&N Sport product pages: Slug HP .177 10 gr https://hn-sport.de/en/node/816 · 13 gr https://hn-sport.de/en/node/793 · 20 gr https://hn-sport.de/en/node/795 · .22 23 gr https://hn-sport.de/en/node/754 · Slug HP II .25 36 gr https://www.hn-sport.de/en/node/767 · Baracuda Match .22 https://www.hn-sport.de/en/node/31 | Manufacturer | Published BCs (no model, no velocity), lengths, energy recommendations |
| S13 | FX Airguns, FX Halo — https://www.fxairguns.com/accessories/ammunition/fx-halo/ | Manufacturer | No numeric BC published |
| S14 | Air Arms, "Air Arms pellets: built for accuracy" — https://www.air-arms.co.uk/learning-centre/air-arms-pellets-built-for-accuracy-trusted-by-shooters | Manufacturer | "very light pellets may become less stable" in high-power rifles; no BC |
| S15 | `docs/pcp-hiz/GORUS.md` sources K1 (Daystate), K5 (Rohrbach et al., Am. J. Phys. 80, 24 (2012)), K7 (NASA GRC) | Manufacturer / peer-reviewed / government (earlier repo research) | Regulator behaviour, no published temperature coefficient |
| S16 | `docs/sacma-surukleme/RAPOR.md` (earlier repo research) | Repo | GA ≈ 0.93·G1, no reusable pellet Cd curve |
| S17 | `tools/formula_reference.py` (repo reference solver) | Repo | All numeric tables in this document |
| S18 | JSB Match Diabolo official site https://www.jsb-match-diabolo.com/ | Manufacturer | **Not read**: robots.txt disallows automated access |
| S19 | R. L. McCoy, "MC DRAG – A Computer Program for Estimating the Drag Coefficients of Projectiles", ARBRL-TR-02293, 1981 — https://apps.dtic.mil/sti/pdfs/ADA098110.pdf (via S16) | US Army BRL | Geometry-based Cd prediction; inputs required |
