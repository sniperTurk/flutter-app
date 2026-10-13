# BC tahmini: mermi tipi ve uç şekline göre (13 Ekim 2026)

Sahip notu: [bc_tip_gruplari.md](bc_tip_gruplari.md). Veri: `data/bullet_shape/`,
betik: `tools/data_gen/bullet_shape.py`. `lib/` dosyalarına dokunulmadı.

## Özet (sade dille)

**Ne yapıldı.** Kütüphanedeki 3897 kaydın (1813 fabrika fişeği, 1566 ateşli mermi çekirdeği,
518 PCP saçma/slug) her biri için mermi yapısı (kurşun çekirdek / bağlı çekirdek / partition /
tam bakır / FMJ / maç), uç şekli (plastik uç, sivri yumuşak uç, boş uç, küt, yuvarlak…) ve taban
(boat-tail / düz taban) yalnızca **üreticinin kendi sitesinden ve kataloğundan** toplandı
(496 sayfa/PDF, hepsi 13.10.2026'da okundu). Fişeklerde üretici çekirdeğin adını veriyorsa
(ör. "Hornady ELD-X", "Nosler Partition") o da yazıldı. Sayfa söylemiyorsa alan **boş** kaldı;
tahmin yapılmadı.

**Ne kadar dolduruldu.** Yapı 2807 kayıtta, uç şekli 2615, taban 1367, fişeklerde çekirdek adı
739 / 1813. Üçü birden 883 kayıtta var. En çok boş kalan alan taban: birçok üretici aynı serinin
hem boat-tail hem düz tabanlı modelini yapıyor ve sayfada modele göre yazmıyor.

**Sonuç: uç şekli BC tahminini belirgin iyileştiriyor (ateşli).** Her markayı dışarıda bırakıp
diğer markaların verisiyle tahmin edince (hile yok):

| Ateşli mermi çekirdekleri (1545 kayıt) | Hataların yarısı | %75'i | %90'ı |
|---|---|---|---|
| Şimdiki genel katsayı | %17 | %35 | %79 |
| Tip + uç şekli + taban grupları | **%13** | **%25** | **%42** |
| — yalnız üç alanı da bilinen 197 kayıt | **%8** | %14 | **%19** |

| Fabrika fişekleri (1365 kayıt, BC'si G1) | Yarısı | %75'i | %90'ı |
|---|---|---|---|
| Şimdiki genel katsayı | %16 | %28 | %55 |
| Gruplar | **%12** | **%23** | **%39** |
| — üç alanı da bilinen 237 kayıt | **%7** | %11 | **%15** |

- En kötü durumlar (%90 dilimi) neredeyse yarıya iniyor: %79 → %42. Büyük hatalar artık
  "boş uçlu bakır mermiye plastik uçlu katsayısı verildi" gibi uç şekli karışmasından gelmiyor.
- Hornady için, Hornady verisi hiç kullanılmadan: %16 / %77 → %11 / %40. Sahip notundaki
  "aynı aileye göre" yöntem (%8 / %35) hâlâ biraz daha iyi; yani karar sırası doğru:
  önce aynı mermi/aile, yoksa uç şekli grubu, en son genel katsayı.
- Yalnız yapı bilinip uç şekli bilinmeyince (ör. "FMJ", "bakır") kazanç yok denecek kadar az
  (%90'ı %62). Kural için **uç şekli şart**.
- **PCP'de kazanç yok.** Slug: %14 / %28 → %14 / %29. Pellet: %19 / %46 → %19 / %52 (pellet
  verisinin 44/45'i H&N; marka dışarıda bırakılamadı, kayıt dışarıda bırakıldı). Slug'ların
  çoğu "hollow point" ve NSA'nın "dish base" tabanı listede yok. PCP için şimdiki katsayılar
  (slug 0,825, pellet 2,06) kalmalı.

**Önerilen kural (lib/core/estimated_bc.dart için, sonra):** BC = SD / i. i şu sırayla seçilir:
yapı × uç × taban grubu → uç × taban → yalnız uç → (yalnız yapı ya da genel katsayı: önerilmez,
"tahmini" ve geniş hata uyarısıyla). Grup en az 5 kayıt ve 2 üreticiden olmalı. Tablo aşağıda (B).

**Doldurulacak kayıtlar.** Üreticinin BC vermediği 347 kayıttan 109'una bir grup değer
verebiliyor; bunların **48'i önerilen** (ateşli, uç şekli bilinen) seviyede. Liste aşağıda (C),
hepsi "tahmini" etiketli; `lib/`'e yazılmadı. Kalan 238 kaydın (çoğu PCP pellet) uç şekli ya da
yapısı üreticide yazmıyor.

**Kaynak kuralları.** Yalnız üretici siteleri/PDF'leri; bayi, forum, YouTube, başka balistik
uygulaması kullanılmadı. Her alanın yanında kaynak adresi, okuma tarihi ve kısa alıntı var.
robots.txt her alan adında önce okundu; JSB ve rws-ammunition.com atlandı. swiss-p.com
robots.txt ile kapalı (SWISS P boş). Okunamayan robots.txt'ler (dosya yok/hata) "kısıt yok"
sayıldı: rws-technology.com, mybullet.com.tr, apps.dtic.mil, sellier-bellot.cz (S&B'de bir ürün
sayfası robots.txt denemesinden önce okundu; sonraki denemelerde dosya hata verdi).

**Dikkat edilecek yorumlar** (ayrıntı her `rules/*.json` dosyasının `note` alanında):
- `polymer_tip` = "uçlu mermi" (sentetik uç). Hornady Heat Shield / Flex Tip ve Swift
  "Signature Black Tip" sayfada "polymer" demeden uç olarak geçiyor; bu değere kondu. Hornady
  A-Tip (alüminyum uç) boş bırakıldı.
- `soft_point` = üretici "soft point" diyor ama sivri/yuvarlak demiyor (ayrı grup; i 0,709).
- Maç mermisinde üretici "hollow point" diyorsa analizde "open tip match" ile aynı gruba alındı
  (veride üreticinin sözü korunuyor).
- Prvi Partizan katalogu düz "HP" mermiyi yarışma mermisi diye tanımlıyor → `match` (1 kayıt).
- ABD Ordusu M855: DTIC belgesindeki "Copper Jacket (FMJ)" çizimi M855'e sayfa düzeninden
  bağlandı (G7 kaydı, analize girmiyor).
- Barnes ve Cutting Edge için üreticinin kendi sitesindeki blog yazısı ve kendi teknik föyü
  (Shopify CDN'de barınan PDF) kullanıldı; üçüncü taraf blog değil.

**Sınırlar.** Fabrika fişeklerinin çoğu BC'yi çekirdek üreticisinden alıyor; aynı mermi
farklı markalarda tekrar ediyor. Bu yüzden fişekte "marka" yerine çekirdek üreticisi dışarıda
bırakıldı. Tahminde kalibre ve ağırlık etkisi (aynı grupta hafif mermide i yükseliyor) henüz
yok; grupların çeyrekler arası aralığı (±%5–8) kalan hatanın çoğu.

---

## A. Data layout and method (English)

- `data/bullet_shape/rules/<brand>.json` — hand-collected: sources (url, read date, title),
  product-line families (regex on the record name, with fields + verbatim quote + source id)
  and per-record entries.
- `data/bullet_shape/<brand>.json` — generated by `bullet_shape.py expand`: one entry per
  library record, keyed `brand|name` (+`|item` for bullets with an item number, `|cartridge` for
  factory cartridges, `@<cal> mm` when a PCP name repeats across calibres). Every field is
  `{value, source_url, read_date, evidence, quote}` or `null`.
  - `evidence: maker_page` — the cartridge/bullet maker's page states it;
    `component_maker_page` — the named component bullet's maker states it;
    `product_name` — an explicit word in the maker's product name as stored with the record's
    source URL (e.g. "BTHP", "Round Nose", "FMJ"; `read_date` null: read when the record was
    collected). "SP" alone gives `soft_point`, never a shape.
- `data/bullet_shape/estimated_bc_candidates.json` — task 3 list (`bullet_shape.py candidates`).
- Commands: `expand`, `check` (exit 1 if generated files are stale), `coverage <brand> -v`,
  `join [out]`, `analyze`, `table`, `candidates`.
- Enums — construction: `cup_and_core bonded partition monolithic_copper fmj match
  lead_free_other` (PCP `lead_slug lead_pellet lead_free_slug lead_free_pellet`); tip:
  `polymer_tip spitzer_soft_point semi_spitzer round_nose flat_nose hollow_point open_tip_match
  fmj_pointed fmj_round soft_point` (PCP adds `pointed wadcutter`); base: `boat_tail flat_base
  hollow_base`.
- Estimator: i = SD / BC(G1), SD = grain / (7000 d²). Only maker G1 BCs are used. Groups need
  ≥ 5 records from ≥ 2 bullet makers. Fallback order c×t×b → t×b → t → c → global; c×t (no
  base) was tested and was worse than t×b / t, so it is not used. Cross-validation: leave one
  bullet maker out (factory records are held out by the component bullet's maker).

### Coverage by brand

| Brand | Records | Construction | Tip shape | Base | Component bullet (factory) | Sources read |
|---|---|---|---|---|---|---|
| Hornady | 365 | 348 | 337 | 155 | 115/124 | 36 |
| Federal | 243 | 196 | 193 | 88 | 166/235 | 29 |
| Barnes | 223 | 213 | 161 | 197 | 47/47 | 17 |
| RWS | 213 | 87 | 18 | 25 | 0/149 | 1 |
| Peregrine | 206 | 206 | 31 | 0 | 0/0 | 7 |
| Sierra | 202 | 101 | 193 | 131 | 8/8 | 15 |
| Nosler | 197 | 180 | 195 | 187 | 37/37 | 72 |
| Sellier & Bellot | 152 | 107 | 113 | 40 | 22/152 | 7 |
| Winchester | 150 | 88 | 107 | 40 | 11/150 | 14 |
| Berger | 147 | 82 | 15 | 147 | 34/34 | 46 |
| Norma | 145 | 132 | 129 | 59 | 81/144 | 19 |
| Woodleigh | 125 | 125 | 101 | 0 | 0/0 | 4 |
| Lapua | 121 | 97 | 65 | 49 | 0/66 | 12 |
| NSA | 117 | 117 | 117 | 40 | 0/0 | 6 |
| Remington | 113 | 98 | 97 | 27 | 24/113 | 13 |
| H&N | 96 | 25 | 49 | 2 | 0/0 | 15 |
| Speer | 96 | 46 | 92 | 16 | 0/0 | 14 |
| Weatherby | 94 | 86 | 68 | 32 | 94/94 | 29 |
| Zan Projectiles | 89 | 1 | 22 | 13 | 0/0 | 4 |
| Black Hills | 88 | 80 | 65 | 28 | 74/88 | 20 |
| Prvi Partizan | 75 | 23 | 55 | 37 | 0/75 | 1 |
| Cutting Edge Bullets | 71 | 71 | 49 | 1 | 0/0 | 4 |
| Geco | 71 | 39 | 43 | 0 | 0/71 | 7 |
| Swift | 70 | 59 | 35 | 0 | 0/0 | 4 |
| Fiocchi | 53 | 20 | 40 | 14 | 12/53 | 8 |
| Hatsan | 48 | 13 | 36 | 0 | 0/0 | 8 |
| Magtech | 35 | 12 | 18 | 6 | 2/35 | 2 |
| Gamo | 32 | 32 | 28 | 0 | 0/0 | 18 |
| CCI | 30 | 4 | 27 | 0 | 6/30 | 9 |
| Sako | 30 | 23 | 19 | 14 | 0/30 | 11 |
| Spoton | 30 | 0 | 4 | 0 | 0/0 | 0 |
| Aguila | 29 | 9 | 14 | 6 | 0/29 | 1 |
| SWISS P | 18 | 1 | 0 | 0 | 0/18 | 0 |
| Crosman | 17 | 14 | 17 | 0 | 0/0 | 9 |
| Hammer Bullets | 16 | 16 | 16 | 0 | 0/0 | 2 |
| Diana | 14 | 14 | 7 | 0 | 0/0 | 6 |
| Warner | 14 | 14 | 0 | 0 | 0/0 | 3 |
| SkyPellets | 12 | 0 | 12 | 0 | 0/0 | 8 |
| Air Arms | 11 | 11 | 11 | 0 | 0/0 | 1 |
| PMC | 11 | 9 | 4 | 5 | 2/11 | 3 |
| MKE | 7 | 1 | 0 | 0 | 0/7 | 1 |
| My Bullet | 7 | 3 | 7 | 5 | 0/0 | 2 |
| SIG Sauer | 4 | 3 | 0 | 0 | 2/4 | 2 |
| Blaser | 3 | 0 | 3 | 3 | 0/3 | 1 |
| Barrett | 2 | 0 | 0 | 0 | 2/2 | 2 |
| CheyTac | 2 | 0 | 0 | 0 | 0/2 | 0 |
| ABD Ordusu | 1 | 1 | 0 | 0 | 0/1 | 1 |
| ELEY | 1 | 0 | 1 | 0 | 0/1 | 1 |
| FX | 1 | 0 | 1 | 0 | 0/0 | 1 |
| **Total** | 3897 | 2807 | 2615 | 1367 | 739/1813 | 496 |


## B. Group form-factor table (G1) — for lib/core/estimated_bc.dart later

Firearm = bullets + cartridges pooled. Use the first level that exists for a record. PCP groups are listed for completeness only (no gain in CV).

### firearm 

| Level | Group | Records | Makers | i (G1) | IQR |
|---|---|---|---|---|---|
| c×t×b | match × open_tip_match × boat_tail | 151 | 12 | 0.519 | 0.483–0.568 |
| c×t×b | bonded × polymer_tip × boat_tail | 117 | 6 | 0.523 | 0.482–0.553 |
| c×t×b | cup_and_core × polymer_tip × boat_tail | 113 | 4 | 0.535 | 0.507–0.559 |
| c×t×b | monolithic_copper × polymer_tip × boat_tail | 104 | 6 | 0.570 | 0.532–0.598 |
| c×t×b | monolithic_copper × hollow_point × flat_base | 45 | 2 | 0.831 | 0.729–0.854 |
| c×t×b | cup_and_core × spitzer_soft_point × boat_tail | 7 | 2 | 0.620 | 0.594–0.627 |
| c×t×b | cup_and_core × hollow_point × flat_base | 7 | 2 | 0.744 | 0.722–0.811 |
| t×b | polymer_tip × boat_tail | 375 | 11 | 0.536 | 0.503–0.569 |
| t×b | open_tip_match × boat_tail | 151 | 12 | 0.519 | 0.483–0.568 |
| t×b | hollow_point × boat_tail | 59 | 7 | 0.643 | 0.590–0.663 |
| t×b | hollow_point × flat_base | 55 | 4 | 0.831 | 0.732–0.856 |
| t×b | spitzer_soft_point × flat_base | 47 | 2 | 0.630 | 0.602–0.653 |
| t×b | spitzer_soft_point × boat_tail | 38 | 5 | 0.608 | 0.572–0.622 |
| t×b | soft_point × boat_tail | 24 | 3 | 0.561 | 0.542–0.598 |
| t×b | flat_nose × flat_base | 24 | 3 | 1.007 | 0.898–1.162 |
| t×b | polymer_tip × flat_base | 23 | 2 | 0.555 | 0.527–0.606 |
| t×b | round_nose × flat_base | 6 | 2 | 1.129 | 1.084–1.145 |
| t | polymer_tip | 711 | 14 | 0.546 | 0.511–0.585 |
| t | hollow_point | 346 | 19 | 0.727 | 0.604–0.875 |
| t | soft_point | 284 | 16 | 0.709 | 0.630–0.846 |
| t | open_tip_match | 180 | 14 | 0.527 | 0.485–0.573 |
| t | flat_nose | 169 | 13 | 1.034 | 0.872–1.143 |
| t | spitzer_soft_point | 164 | 9 | 0.635 | 0.600–0.708 |
| t | round_nose | 103 | 13 | 0.999 | 0.913–1.122 |
| t | semi_spitzer | 11 | 5 | 0.702 | 0.672–0.787 |
| c | monolithic_copper | 626 | 16 | 0.587 | 0.520–0.742 |
| c | cup_and_core | 491 | 12 | 0.634 | 0.545–0.768 |
| c | bonded | 451 | 14 | 0.715 | 0.546–0.915 |
| c | match | 373 | 16 | 0.493 | 0.458–0.538 |
| c | fmj | 154 | 16 | 0.679 | 0.562–0.976 |
| c | lead_free_other | 85 | 10 | 0.685 | 0.608–0.938 |

### pcp slug

| Level | Group | Records | Makers | i (G1) | IQR |
|---|---|---|---|---|---|
| t×b | hollow_point × hollow_base | 6 | 2 | 0.953 | 0.930–0.998 |
| t | hollow_point | 155 | 3 | 0.864 | 0.731–0.940 |
| c | lead_slug | 126 | 2 | 0.877 | 0.773–0.945 |

### pcp pellet

| Level | Group | Records | Makers | i (G1) | IQR |
|---|---|---|---|---|---|
| c | lead_free_pellet | 6 | 2 | 1.565 | 1.350–1.788 |

## Cross-validation results

Group used when it has ≥ 5 records from ≥ 2 bullet makers outside the held-out maker; order c×t×b → t×b → t → c → global.

### Firearm component bullets (bullet_library)

| Method | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| Global form factor | 1545 | 17 % | 35 % | 79 % |
| Shape groups → fallback | 1545 | 13 % | 25 % | 42 % |
| … records a shape group covered: groups | 1476 | 12 % | 26 % | 41 % |
| … same records: global | 1476 | 17 % | 36 % | 80 % |
| … records with all three fields: groups | 197 | 8 % | 14 % | 19 % |
| … same records: global | 197 | 11 % | 18 % | 22 % |

By level used:

| Level | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| c×t×b | 197 | 8 % | 14 % | 19 % |
| t×b | 197 | 14 % | 25 % | 38 % |
| t | 661 | 13 % | 28 % | 43 % |
| c | 421 | 14 % | 29 % | 62 % |
| global | 69 | 19 % | 23 % | 50 % |

Hornady subset (owner baseline: no family 15 % / 71 %, same family 8 % / 35 %):

| Method | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| Hornady, global (other makers) | 241 | 16 % | 27 % | 77 % |
| Hornady, shape groups (other makers) | 241 | 11 % | 19 % | 40 % |

### Firearm factory cartridges with a maker G1 BC (held out by bullet maker)

| Method | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| Global form factor | 1365 | 16 % | 28 % | 55 % |
| Shape groups → fallback | 1365 | 12 % | 23 % | 39 % |
| … records a shape group covered: groups | 1163 | 12 % | 21 % | 36 % |
| … same records: global | 1163 | 16 % | 28 % | 56 % |
| … records with all three fields: groups | 237 | 7 % | 11 % | 15 % |
| … same records: global | 237 | 17 % | 22 % | 27 % |

By level used:

| Level | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| c×t×b | 237 | 7 % | 11 % | 15 % |
| t×b | 38 | 11 % | 30 % | 47 % |
| t | 635 | 14 % | 23 % | 36 % |
| c | 253 | 16 % | 28 % | 54 % |
| global | 202 | 19 % | 32 % | 48 % |

### Firearm, bullets + cartridges pooled

| Method | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| Global form factor | 2910 | 18 % | 34 % | 66 % |
| Shape groups → fallback | 2910 | 13 % | 24 % | 42 % |
| … records a shape group covered: groups | 2639 | 12 % | 22 % | 40 % |
| … same records: global | 2639 | 17 % | 34 % | 68 % |
| … records with all three fields: groups | 485 | 7 % | 12 % | 17 % |
| … same records: global | 485 | 14 % | 20 % | 24 % |

By level used:

| Level | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| c×t×b | 485 | 7 % | 12 % | 17 % |
| t×b | 241 | 11 % | 24 % | 38 % |
| t | 1242 | 14 % | 27 % | 43 % |
| c | 671 | 16 % | 26 % | 55 % |
| global | 271 | 20 % | 33 % | 55 % |

### PCP slug

| Method | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| Global form factor | 209 | 14 % | 21 % | 28 % |
| Shape groups → fallback | 209 | 14 % | 21 % | 29 % |
| … records a shape group covered: groups | 155 | 15 % | 22 % | 28 % |
| … same records: global | 155 | 15 % | 22 % | 28 % |

By level used:

| Level | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| t | 155 | 15 % | 22 % | 28 % |
| global | 54 | 10 % | 19 % | 40 % |

### PCP pellet — leave-one-RECORD-out (too few makers for LOBO; optimistic)

| Method | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| Global form factor | 45 | 19 % | 29 % | 46 % |
| Shape groups → fallback | 45 | 19 % | 29 % | 52 % |
| … records a shape group covered: groups | 15 | 17 % | 27 % | 52 % |
| … same records: global | 15 | 18 % | 33 % | 46 % |

By level used:

| Level | Records | Median | 75 % | 90 % |
|---|---|---|---|---|
| t | 9 | 12 % | 22 % | 41 % |
| c | 6 | 24 % | 35 % | 49 % |
| global | 30 | 19 % | 29 % | 43 % |

### Per-group error (firearm, pooled; records whose full group was used)

| Construction × tip × base | Records | Makers | i (median) | i IQR | LOBO median | 75 % | 90 % |
|---|---|---|---|---|---|---|---|
| match × open_tip_match × boat_tail | 151 | 12 | 0.519 | 0.483–0.568 | 9 % | 13 % | 20 % |
| bonded × polymer_tip × boat_tail | 117 | 6 | 0.523 | 0.482–0.553 | 7 % | 10 % | 13 % |
| cup_and_core × polymer_tip × boat_tail | 113 | 4 | 0.535 | 0.507–0.559 | 5 % | 11 % | 17 % |
| monolithic_copper × polymer_tip × boat_tail | 104 | 6 | 0.570 | 0.532–0.598 | 7 % | 11 % | 14 % |
| monolithic_copper × hollow_point × flat_base | 45 | 2 | 0.831 | 0.729–0.854 | – | – | – |
| cup_and_core × spitzer_soft_point × boat_tail | 7 | 2 | 0.620 | 0.594–0.627 | – | – | – |
| cup_and_core × hollow_point × flat_base | 7 | 2 | 0.744 | 0.722–0.811 | – | – | – |

“–”: the group has only 2 bullet makers, so with one held out it falls below the 2-maker rule and its records are predicted by a lower level in CV.

## C. Records whose BC this rule would fill (tahmini)

From `data/bullet_shape/estimated_bc_candidates.json`; nothing written to `lib/`. BC = SD / i, G1.

#### C1. Önerilen (ateşli, uç şekli bilinen grup) — 48 kayıt

| Marka | Ad | Kalibre | gr | Grup (seviye) | i | BC G1 (tahmini) |
|---|---|---|---|---|---|---|
| Aguila | Jacketed Hollow Point | .17 HMR | 20 | hollow_point (t) | 0.727 | 0.133 tahmini |
| Hornady | Varmint Express Rimfire 17 gr V-MAX | .17 HMR | 17 | polymer_tip (t) | 0.546 | 0.15 tahmini |
| Hornady | Varmint Express Rimfire 20 gr HP XTP | .17 HMR | 20 | hollow_point (t) | 0.727 | 0.133 tahmini |
| Aguila | 22 Long Rifle Interceptor Copper-Plated Hollow Point | .22 LR | 40 | hollow_point (t) | 0.727 | 0.157 tahmini |
| Aguila | 22 Long Rifle Subsonic Lead Hollow Point | .22 LR | 38 | hollow_point (t) | 0.727 | 0.149 tahmini |
| Aguila | 22 Long Rifle SuperMaximum Copper-Plated Hollow Point | .22 LR | 30 | hollow_point (t) | 0.727 | 0.117 tahmini |
| Geco | GECO RIFLE .22 2,6g | .22 LR | 40 | round_nose (t) | 0.999 | 0.114 tahmini |
| Geco | GECO SEMI-AUTO .22 2,6g | .22 LR | 40 | round_nose (t) | 0.999 | 0.114 tahmini |
| Winchester | M22 40 gr Black Copper Plated Round Nose | .22 LR | 40 | round_nose (t) | 0.999 | 0.114 tahmini |
| Winchester | M22 Subsonic 45 gr Black Copper Plated Round Nose | .22 LR | 45 | round_nose (t) | 0.999 | 0.128 tahmini |
| Winchester | Super Suppressed 45 gr Black Copper Plated Round Nose | .22 LR | 45 | round_nose (t) | 0.999 | 0.128 tahmini |
| Winchester | Super X 37 gr Hollow Point Copper Plated | .22 LR | 37 | hollow_point (t) | 0.727 | 0.145 tahmini |
| Winchester | Super X 40 gr Lead Round Nose Copper Plated | .22 LR | 40 | round_nose (t) | 0.999 | 0.114 tahmini |
| Winchester | Super X 40 gr Power-Point Hollow Point Copper Plated | .22 LR | 40 | hollow_point (t) | 0.727 | 0.157 tahmini |
| Winchester | Super X 40 gr Power-Point HP Copper Plated | .22 LR | 40 | hollow_point (t) | 0.727 | 0.157 tahmini |
| Winchester | Super X Super Speed 37 gr Hollow Point Copper Plated | .22 LR | 37 | hollow_point (t) | 0.727 | 0.145 tahmini |
| Winchester | Super X Super Speed 40 gr Round Nose Copper Plated | .22 LR | 40 | round_nose (t) | 0.999 | 0.114 tahmini |
| Winchester | Varmint HV 40 gr Hyper Velocity Hollow Point Copper Plated | .22 LR | 40 | hollow_point (t) | 0.727 | 0.157 tahmini |
| Aguila | 22 Win Mag Semi-Jacketed Soft Point | .22 WMR | 40 | soft_point (t) | 0.709 | 0.161 tahmini |
| Hornady | 30 gr V-MAX Varmint Express Rimfire | .22 WMR | 30 | polymer_tip (t) | 0.546 | 0.157 tahmini |
| Winchester | Varmint HV 22 Win Mag 30 gr JHP | .22 WMR | 30 | hollow_point (t) | 0.727 | 0.117 tahmini |
| Winchester | Varmint HV 22 Win Mag 30 gr V-MAX | .22 WMR | 30 | polymer_tip (t) | 0.546 | 0.157 tahmini |
| Nosler | 50gr FBHP NoslerCustom Ammunition | .222 Rem Mag | 50 | cup_and_core × hollow_point × flat_base (c×t×b) | 0.744 | 0.191 tahmini |
| Black Hills | Black Hills 52 gr Match HP | .223 Rem | 52 | open_tip_match (t) | 0.527 | 0.28 tahmini |
| Black Hills | Black Hills 55 gr Soft Point | .223 Rem | 55 | soft_point (t) | 0.709 | 0.22 tahmini |
| Black Hills | Black Hills 60 gr Soft Point | .223 Rem | 60 | soft_point (t) | 0.709 | 0.24 tahmini |
| Black Hills | Black Hills 68 gr Heavy Match HP | .223 Rem | 68 | open_tip_match (t) | 0.527 | 0.366 tahmini |
| Black Hills | Black Hills 75 gr Heavy Match HP | .223 Rem | 75 | open_tip_match (t) | 0.527 | 0.404 tahmini |
| Black Hills | Black Hills 77 gr Open Tip Match | .223 Rem | 77 | open_tip_match (t) | 0.527 | 0.415 tahmini |
| Lapua | Lapua 4.5 g (69 gr) Scenar | .223 Rem | 69 | match × open_tip_match × boat_tail (c×t×b) | 0.519 | 0.377 tahmini |
| Norma | Norma Whitetail 55 gr | .223 Rem | 55 | soft_point (t) | 0.709 | 0.22 tahmini |
| Weatherby | 240 Weatherby Magnum 72 gr Hammer Custom | .240 Weatherby Mag | 72 | hollow_point (t) | 0.727 | 0.24 tahmini |
| Lapua | Lapua 6.5 g (100 gr) Soft Point | .243 Win | 100 | soft_point (t) | 0.709 | 0.341 tahmini |
| Aguila | 30-06 SPRG 150 Grain Soft Point | .30-06 Springfield | 150 | soft_point (t) | 0.709 | 0.319 tahmini |
| Black Hills | Black Hills Gold 168 gr Hornady Match Hollow Point | .30-06 Springfield | 168 | match × open_tip_match × boat_tail (c×t×b) | 0.519 | 0.488 tahmini |
| Black Hills | Black Hills 125 gr Open Tip Match | .300 Blackout | 125 | open_tip_match (t) | 0.527 | 0.358 tahmini |
| Black Hills | Black Hills 220 gr Open Tip Match | .300 Blackout | 220 | open_tip_match (t) | 0.527 | 0.63 tahmini |
| Black Hills | Black Hills 190 gr Match Hollow Point | .300 Win Mag | 190 | open_tip_match (t) | 0.527 | 0.544 tahmini |
| Black Hills | Black Hills 168 gr Match Hollow Point | .308 Win | 168 | open_tip_match (t) | 0.527 | 0.481 tahmini |
| Black Hills | Black Hills 175 gr Match Hollow Point | .308 Win | 175 | open_tip_match (t) | 0.527 | 0.501 tahmini |
| Black Hills | Black Hills Gold 125 gr Hornady CX | .308 Win | 125 | polymer_tip (t) | 0.546 | 0.345 tahmini |
| Hornady | 170 gr MonoFlex Black | .338 ARC | 170 | polymer_tip (t) | 0.546 | 0.389 tahmini |
| Hornady | 175 gr HP Match BLACK | .338 ARC | 175 | open_tip_match (t) | 0.527 | 0.415 tahmini |
| Hornady | 215 gr FTX Black | .338 ARC | 215 | polymer_tip (t) | 0.546 | 0.492 tahmini |
| Hornady | 210 gr InterLock American Whitetail | .400 Legend | 210 | soft_point (t) | 0.709 | 0.264 tahmini |
| Black Hills | Black Hills 69 gr Open Tip Match | 5.56x45 NATO | 69 | open_tip_match (t) | 0.527 | 0.372 tahmini |
| Black Hills | Black Hills 77 gr Open Tip Match | 5.56x45 NATO | 77 | open_tip_match (t) | 0.527 | 0.415 tahmini |
| Hornady | American Gunner 123 gr HP Match | 7.62x39 | 123 | open_tip_match (t) | 0.527 | 0.343 tahmini |

#### C2. Önerilmeyen (yalnız yapı grubu ya da PCP — genel tahminden iyi değil) — 61 kayıt

| Marka | Ad | Kalibre | gr | Grup (seviye) | i | BC G1 (tahmini) |
|---|---|---|---|---|---|---|
| Aguila | 223 REM 55 Grain Full Metal Jacket | .223 Rem | 55 | fmj (c) | 0.679 | 0.23 tahmini |
| Black Hills | Black Hills 36 gr Varmint Grenade | .223 Rem | 36 | lead_free_other (c) | 0.685 | 0.149 tahmini |
| Black Hills | Black Hills 55 gr Full Metal Jacket | .223 Rem | 55 | fmj (c) | 0.679 | 0.23 tahmini |
| Lapua | Lapua 5.8 g (90 gr) FMJ | .243 Win | 90 | fmj (c) | 0.679 | 0.321 tahmini |
| Aguila | 110 Grain Full Metal Jacket | .30 Carbine | 110 | fmj (c) | 0.679 | 0.244 tahmini |
| Aguila | 300 AAC Blackout 150 Grain Full Metal Jacket | .300 Blackout | 150 | fmj (c) | 0.679 | 0.333 tahmini |
| Black Hills | Black Hills 115 gr Dual Performance (monolithic copper) | .300 Blackout | 115 | monolithic_copper (c) | 0.587 | 0.295 tahmini |
| Black Hills | Black Hills 198 gr Dual Performance (monolithic copper) | .300 Blackout | 198 | monolithic_copper (c) | 0.587 | 0.508 tahmini |
| Aguila | 308 WIN 150 Grain Full Metal Jacket Boat Tail | .308 Win | 150 | fmj (c) | 0.679 | 0.333 tahmini |
| Black Hills | Black Hills Gold 152 gr Dual Performance | .308 Win | 152 | monolithic_copper (c) | 0.587 | 0.39 tahmini |
| Hornady | (Subsonic) 285 gr FMJ Frontier | .338 ARC | 285 | fmj (c) | 0.679 | 0.524 tahmini |
| MKE | 8.59×70 Solid Fişek | .338 Lapua Mag | 240.7 | lead_free_other (c) | 0.685 | 0.439 tahmini |
| Aguila | 5.56 x 45mm 55 Grain Full Metal Jacket Boat Tail | 5.56x45 NATO | 55 | fmj (c) | 0.679 | 0.23 tahmini |
| Aguila | 5.56 x 45mm 62 Grain Full Metal Jacket Boat Tail | 5.56x45 NATO | 62 | fmj (c) | 0.679 | 0.259 tahmini |
| Aguila | 5.56 x 45mm NATO 55 Grain FMJ | 5.56x45 NATO | 55 | fmj (c) | 0.679 | 0.23 tahmini |
| Black Hills | Black Hills 62 gr Dual Performance (monolithic copper) | 5.56x45 NATO | 62 | monolithic_copper (c) | 0.587 | 0.3 tahmini |
| Aguila | 140 Grain Full Metal Jacket Boat Tail | 6.5 Creedmoor | 140 | fmj (c) | 0.679 | 0.422 tahmini |
| Black Hills | Black Hills Gold 130 gr Dual Performance | 6.5 Creedmoor | 130 | monolithic_copper (c) | 0.587 | 0.453 tahmini |
| Black Hills | Black Hills Gold 90 gr Dual Performance | 6mm ARC | 90 | monolithic_copper (c) | 0.587 | 0.371 tahmini |
| Aguila | 7.62 x 51mm 150 Grain Full Metal Jacket Boat Tail | 7.62x51 NATO | 150 | fmj (c) | 0.679 | 0.333 tahmini |
| Hatsan | Vortex Big Bore Supreme Flat Point Slug .45 180 gr | 11.43 mm | 180 | lead_slug (c) | 0.877 | 0.145 tahmini |
| Hatsan | Vortex Big Bore Supreme Hollow Point Slug .45 295 gr | 11.43 mm | 295 | hollow_point (t) | 0.864 | 0.241 tahmini |
| Hatsan | Vortex Big Bore Supreme Flat Point Slug .45 525 gr | 11.43 mm | 525 | lead_slug (c) | 0.877 | 0.422 tahmini |
| Hatsan | Vortex Big Bore Supreme Hollow Point Slug .50 520 gr | 12.7 mm | 520 | hollow_point (t) | 0.864 | 0.344 tahmini |
| Hatsan | Vortex Big Bore Supreme Hollow Point Slug .50 550 gr | 12.7 mm | 550 | hollow_point (t) | 0.864 | 0.364 tahmini |
| My Bullet | 5.5mm 22 Grain Hollow Point Slug | 5.5 mm | 22 | hollow_point (t) | 0.864 | 0.078 tahmini |
| My Bullet | 5.5mm 30 Grain Hollow Point Slug | 5.5 mm | 30 | hollow_point (t) | 0.864 | 0.106 tahmini |
| My Bullet | 5.5mm 38 Grain Hollow Point Slug | 5.5 mm | 38 | hollow_point (t) | 0.864 | 0.134 tahmini |
| My Bullet | 6.35mm 32 Grain Hollow Point Slug | 6.35 mm | 32 | hollow_point (t) | 0.864 | 0.085 tahmini |
| My Bullet | 6.35mm 38 Grain Hollow Point Slug | 6.35 mm | 38 | hollow_point (t) | 0.864 | 0.1 tahmini |
| My Bullet | 6.35mm 45 Grain Hollow Point Slug | 6.35 mm | 45 | hollow_point (t) | 0.864 | 0.119 tahmini |
| My Bullet | 6.35mm 60 Grain Hollow Point Slug | 6.35 mm | 60 | hollow_point (t) | 0.864 | 0.159 tahmini |
| NSA | NSA .300 59.5 gr HP DB Slug | 7.62 mm | 59.5 | hollow_point (t) | 0.864 | 0.109 tahmini |
| NSA | NSA .457 265 gr HP DB Slug | 11.43 mm | 265 | hollow_point (t) | 0.864 | 0.21 tahmini |
| NSA | NSA .257 75 gr HP DB Slug | 6.35 mm | 75 | hollow_point (t) | 0.864 | 0.188 tahmini |
| NSA | NSA .257 65 gr HP DB Slug | 6.35 mm | 65 | hollow_point (t) | 0.864 | 0.163 tahmini |
| Zan Projectiles | ZAN .177 22 gr HP Slug | 4.5 mm | 22 | hollow_point × hollow_base (t×b) | 0.953 | 0.105 tahmini |
| Zan Projectiles | ZAN .177 24 gr HP Slug | 4.5 mm | 24 | hollow_point × hollow_base (t×b) | 0.953 | 0.115 tahmini |
| Zan Projectiles | ZAN .357 81 gr HP Slug | 9 mm | 81 | hollow_point (t) | 0.864 | 0.105 tahmini |
| Zan Projectiles | ZAN .357 90 gr HP Slug | 9 mm | 90 | hollow_point (t) | 0.864 | 0.117 tahmini |
| Zan Projectiles | ZAN .357 100 gr HP Slug | 9 mm | 100 | hollow_point (t) | 0.864 | 0.13 tahmini |
| Zan Projectiles | ZAN .357 112 gr HP Slug | 9 mm | 112 | hollow_point (t) | 0.864 | 0.145 tahmini |
| Zan Projectiles | ZAN .357 125 gr HP Slug | 9 mm | 125 | hollow_point (t) | 0.864 | 0.162 tahmini |
| Zan Projectiles | ZAN .457 285 gr Slug | 11.43 mm | 285 | hollow_point (t) | 0.864 | 0.226 tahmini |
| Zan Projectiles | ZAN .510 320 gr HP Slug | 12.7 mm | 320 | hollow_point (t) | 0.864 | 0.203 tahmini |
| Zan Projectiles | ZAN .510 350 gr HP Slug | 12.7 mm | 350 | hollow_point (t) | 0.864 | 0.222 tahmini |
| Hatsan | Apolo Slug HP 32 gr | 5.5 mm | 32 | hollow_point (t) | 0.864 | 0.113 tahmini |
| Crosman | Red Flight Penetrator .22 16.7 gr | 5.5 mm | 16.7 | lead_free_pellet (c) | 1.565 | 0.033 tahmini |
| Crosman | Fast Flight Penetrator .177 5.4 gr | 4.5 mm | 5.4 | lead_free_pellet (c) | 1.565 | 0.016 tahmini |
| Crosman | Gold Flight Penetrator .177 8.5 gr | 4.5 mm | 8.5 | lead_free_pellet (c) | 1.565 | 0.025 tahmini |
| Gamo | Lethal 5.56 gr | 4.5 mm | 5.56 | lead_free_pellet (c) | 1.565 | 0.016 tahmini |
| Gamo | PBA Bullet 7.1 gr | 4.5 mm | 7.1 | lead_free_pellet (c) | 1.565 | 0.021 tahmini |
| Gamo | PBA Bullet 14.4 gr | 5.5 mm | 14.4 | lead_free_pellet (c) | 1.565 | 0.028 tahmini |
| Gamo | Luxor Cu 5.2 gr | 4.5 mm | 5.2 | lead_free_pellet (c) | 1.565 | 0.015 tahmini |
| Gamo | Luxor Cu 9.9 gr | 5.5 mm | 9.9 | lead_free_pellet (c) | 1.565 | 0.019 tahmini |
| Gamo | PBA Raptor 5.1 gr | 4.5 mm | 5.1 | lead_free_pellet (c) | 1.565 | 0.015 tahmini |
| Gamo | PBA Raptor 9.8 gr | 5.5 mm | 9.8 | lead_free_pellet (c) | 1.565 | 0.019 tahmini |
| Gamo | Match Lead Free 5.1 gr | 4.5 mm | 5.1 | lead_free_pellet (c) | 1.565 | 0.015 tahmini |
| Gamo | PBA Platinum 5.1 gr | 4.5 mm | 5.1 | lead_free_pellet (c) | 1.565 | 0.015 tahmini |
| Gamo | PBA Platinum 9.7 gr | 5.5 mm | 9.7 | lead_free_pellet (c) | 1.565 | 0.019 tahmini |
| H&N | Match Green 5.25 gr | 4.5 mm | 5.25 | lead_free_pellet (c) | 1.565 | 0.015 tahmini |

## D. Source list (manufacturers' own pages / PDFs; all read 2026-10-13)


**ABD Ordusu** — DTIC ADA549416 (US Army M855A1 EPR Media Day). apps.dtic.mil/robots.txt returned a fetch error twice. Legacy M855 diagram lists 'Steel Penetrator / Lead Slug / Copper Jacket (FMJ)' (M855 vs M855A1 attribution from layout; table: M855 slug lead). Tip/base not stated.

- [M855A1 Enhanced Performance Round (EPR) Media Day](https://apps.dtic.mil/sti/tr/pdf/ADA549416.pdf) (2026-10-13)

**Aguila** — Read the Aguila 2023 catalogue PDF (content.aguilaammo.com) and the 308 Win 150 gr SP product page; www.aguilaammo.com/robots.txt returned a fetch error. The catalogue states only what the product names already say (Soft Point, FMJ BT, Round Nose, Hollow Point); 'solid point' and lead/copper-plated rimfire bullets have no matching enum; no maker, base or tip geometry otherwise stated -> no rules added.

- [Aguila catalogue 2023](https://content.aguilaammo.com/uploads/Aguila_Catalog2023_5489a2e44d.pdf) (2026-10-13)

**Air Arms** — 2026-10-13: robots.txt read (resources.air-arms.co.uk; page allowed). Read the pellet range page: range-wide 'Crafted from high-grade lead alloys' -> lead_pellet for all; per-pellet 'Shape:' Domed (Express, Field, Field Plus Heavy), Pointed (Diabolo Hunter), Wadcutter (Match Flathead, Training Match). Base/skirt not stated.

- [Air Arms pellets](https://resources.air-arms.co.uk/airarmspellets) (2026-10-13)

**Barnes** — Read barnesbullets.com (robots.txt checked; www. host fetch permission timed out, non-www used) product pages, bullet-material pages, the Barnes hunting-bullet blog article and the CFR ballistics chart; Sierra TGK pages for Harvest Collection. Barnes product/family pages never spell out BT/FB/FN/RN, so base/tip mostly come from name words. Not stated: LRX tip (only 'some' LRX tipped), TAC-TX tip ('larger tip', material not given), Match Burner tip, TTSX/TSX base (both BT and FB exist), Pro-Hunter shape (varies per Sierra item), XFB construction, TGK construction. barnesbullets.com/catalog/ fetch failed (client error).

- [How To Pick The Best Hunting Bullet For You (Barnes)](https://barnesbullets.com/blog/how-to-pick-the-best-hunting-bullet-for-you/) (2026-10-13)
- [Bullet material: 100% Copper (lists TSX, TTSX, LRX, TAC-TX)](https://barnesbullets.com/bullets/bullet-material/100-copper/) (2026-10-13)
- [0.308 30 CAL TTSX BT](https://barnesbullets.com/0-308-30-cal-ttsx-bt/) (2026-10-13)
- [0.308 30 CAL TSX BT](https://barnesbullets.com/0-308-30-cal-tsx-bt/) (2026-10-13)
- [0.308 300 ACC BLK TAC-TX 110 GR FB](https://barnesbullets.com/0-308-300-acc-blk-tac-tx-110-gr-fb/) (2026-10-13)
- [0.264 6.5mm Match Burner BT](https://barnesbullets.com/0-264-6-5mm-match-burner-bt/) (2026-10-13)
- [0.224 22 CAL Varmint Grenade FB](https://barnesbullets.com/0-224-22-cal-varmint-grenade-fb/) (2026-10-13)
- [0.243 6MM Varminator HP FB](https://barnesbullets.com/0-243-6mm-varminator-hp-fb/) (2026-10-13)
- [0.510 50-110 WIN Barnes Original FN FB](https://barnesbullets.com/0-510-50-110-win-barnes-original-fn-fb/) (2026-10-13)
- [Bullet material: Solid Brass (lists Banded Solid only)](https://barnesbullets.com/bullets/bullet-material/solid-brass/) (2026-10-13)
- [Ammunition product family VOR-TX LR](https://barnesbullets.com/ammunition/product-family/vor-tx-lr/) (2026-10-13)
- [Barnes centerfire rifle ballistics chart (Bullet Style column)](https://barnesbullets.com/content/Barnes-Ballistics-Charts/CFR-Imperial.pdf) (2026-10-13)
- [Harvest Collection .308 WIN 165gr](https://barnesbullets.com/harvest-collection-308win/) (2026-10-13)
- [Harvest Collection 350 Legend 155gr Pro-Hunter](https://barnesbullets.com/harvest-collection-350-legend-155gr-pro-hunter/) (2026-10-13)
- [Sierra 22 CAL 69 GR Tipped GameKing](https://sierrabullets.com/22-cal-69-gr-tipped-gameking-tgk/) (2026-10-13)
- [Sierra 6MM 90 GR Tipped GameKing](https://sierrabullets.com/6mm-90-gr-tipped-gameking-tgk/) (2026-10-13)
- [Sierra 30 CAL 165 GR Tipped GameKing](https://sierrabullets.com/30-cal-165-gr-tipped-gameking-tgk/) (2026-10-13)

**Barrett** — barrett.net robots.txt checked. Pages name the component bullets only; construction/tip/base not described.

- [Barrett .416 Barrett ammunition](https://barrett.net/products/accessories/ammunition/416barrett/) (2026-10-13)
- [Barrett .50 BMG ammunition](https://barrett.net/products/accessories/ammunition/50bmg/) (2026-10-13)

**Berger** — Read 2026-10-13 from bergerbullets.com only (robots.txt: Disallow empty). Base for component bullets from the Bullet Reference Charts table (Boat Tail column: FB or boat-tail length), 4 bullets not in the chart from their product pages (Base Style). Line pages: Target, VLD Target, Hybrid Target, LR Hybrid Target, OTM Tactical, Varmint, VLD Hunting, Classic Hunter, Elite Hunter; 2025 catalog PDF checked. All 34 ammunition pages read (bullet named + Boat Tail feature section; 4 LRHT pages give no base, base taken from the named LRHT bullet row of the chart). Empty on purpose: construction of hunting/varmint lines (pages name only the J4 copper jacket, never the core metal); tip shape of all non-OTM lines (no hollow point/open tip stated; LRHT only mentions MRT meplat). 300 Norma Mag 215 gr page sits in the OTM Tactical line and names a "215gr Hybrid" bullet.

- [Bullet Reference Charts](https://bergerbullets.com/information/lines-and-designs/bullet-reference-charts/) (2026-10-13)
- [Target bullets (line page)](https://bergerbullets.com/information/lines-and-designs/target-bullets/) (2026-10-13)
- [VLD Target bullets (line page)](https://bergerbullets.com/information/lines-and-designs/vld-target-bullets/) (2026-10-13)
- [30 Cal 185 gr Hybrid Target (product page)](https://bergerbullets.com/product/30-caliber-185-grain-hybrid-target/) (2026-10-13)
- [LR Hybrid Target bullets (line page)](https://bergerbullets.com/information/lines-and-designs/long-range-hybrid-target-bullets/) (2026-10-13)
- [OTM Tactical bullets (line page)](https://bergerbullets.com/information/lines-and-designs/otm-tactical-bullets/) (2026-10-13)
- [375 Cal 379 gr ELR Match Solid (product page)](https://bergerbullets.com/product/375-caliber-379-grain-elr-match-solid-bullets/) (2026-10-13)
- [375 Cal 407 gr ELR Match Solid (product page)](https://bergerbullets.com/product/375-caliber-407-grain-elr-match-solid-bullets/) (2026-10-13)
- [270 Caliber 170 gr Elite Hunter (product page)](https://bergerbullets.com/product/270-caliber-170-grain-elite-hunter/) (2026-10-13)
- [30 Caliber 217 gr Elite Hunter (product page)](https://bergerbullets.com/product/30-caliber-217-grain-elite-hunter-rifle-bullet/) (2026-10-13)
- [22 Caliber 69 gr BT Target (product page)](https://bergerbullets.com/product/22-caliber-69-grain-bt-target-rifle-bullet/) (2026-10-13)
- [6mm 120 gr Long Range Hybrid Target (product page)](https://bergerbullets.com/product/6-mm-120-grain-long-range-hybrid-target-rifle-bullet/) (2026-10-13)
- [223 Remington 69 Grain OTM Tactical Rifle Ammunition (product page)](https://bergerbullets.com/product/223-remington-69-grain-otm-rifle-ammunition/) (2026-10-13)
- [223 Remington 73 Grain Boat Tail Target Rifle Ammunition (product page)](https://bergerbullets.com/product/223-remington-73-grain-boat-tail-target/) (2026-10-13)
- [223 Remington 77 Grain OTM Tactical Rifle Ammunition (product page)](https://bergerbullets.com/product/223-remington-77-grain-otm-tactical/) (2026-10-13)
- [260 Remington 130 Grain Hybrid OTM Tactical Rifle Ammunition (product page)](https://bergerbullets.com/product/260-remington-130gr-hybrid-otm-tactical/) (2026-10-13)
- [300 Norma Magnum 215 Grain Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/300-norma-magnum-215gr-hybrid-target/) (2026-10-13)
- [300 Norma Magnum 230 Grain Hybrid OTM Tactical Rifle Ammunition (product page)](https://bergerbullets.com/product/300-norma-magnum-230gr-hybrid-otm-tactical/) (2026-10-13)
- [300 Norma Magnum 245 Grain Long Range Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/300-norma-magnum-245gr-long-range-hybrid-target-rifle-ammunition/) (2026-10-13)
- [215 Grain Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/300-prc-215-grain-hybrid-target-rifle-ammunition/) (2026-10-13)
- [217 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/300-prc-217-grain-elite-hunter-rifle-ammunition/) (2026-10-13)
- [245 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/300-prc-245gr-elite-hunter-rifle-ammunition/) (2026-10-13)
- [300 Winchester Magnum 168 Grain Classic Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/300-winchester-magnum-168gr-classic-hunter/) (2026-10-13)
- [300 Winchester Magnum 185 Grain Classic Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/300-winchester-magnum-185gr-classic-hunter/) (2026-10-13)
- [308 Winchester 168 Grain Classic Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/308-winchester-168gr-classic-hunter/) (2026-10-13)
- [308 Winchester 175 Grain OTM Tactical Rifle Ammunition (product page)](https://bergerbullets.com/product/308-winchester-175gr-otm-tactical/) (2026-10-13)
- [308 Winchester 185 Grain Classic Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/308-winchester-185gr-classic-hunter/) (2026-10-13)
- [308 Winchester 185 Grain Juggernaut OTM Tactical Rifle Ammunition (product page)](https://bergerbullets.com/product/308-winchester-185gr-juggernaut-otm-tactical/) (2026-10-13)
- [338 Lapua Magnum 300 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/338-lapua-magnum-300gr-elite-hunter/) (2026-10-13)
- [338 Lapua Magnum 300 Grain Hybrid OTM Tactical Rifle Ammunition (product page)](https://bergerbullets.com/product/338-lapua-magnum-300gr-hybrid-otm-tactical/) (2026-10-13)
- [6.5 mm Creedmoor 130 Grain Hybrid OTM Tactical Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-mm-creedmoor-130gr-hybrid-otm-tactical/) (2026-10-13)
- [6.5 mm Creedmoor 135 Grain Classic Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-mm-creedmoor-135gr-classic-hunter/) (2026-10-13)
- [6.5 mm Creedmoor 140 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-mm-creedmoor-140gr-elite-hunter-rifle-ammunition/) (2026-10-13)
- [6.5 mm Creedmoor 140 Grain Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-mm-creedmoor-140gr-hybrid-target/) (2026-10-13)
- [6.5 mm Creedmoor 144 Grain Long Range Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-mm-creedmoor-144gr-long-range-hybrid-target/) (2026-10-13)
- [6.5 mm Creedmoor 153.5 Grain Long Range Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-mm-creedmoor-153-5gr-long-range-hybrid-target/) (2026-10-13)
- [6.5 mm Creedmoor 156 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-mm-creedmoor-156-grain-elite-hunter/) (2026-10-13)
- [140 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-prc-140gr-elite-hunter-rifle-ammunition/) (2026-10-13)
- [153.5 Grain Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-prc-153-5-grain-hybrid-target-rifle-ammunition/) (2026-10-13)
- [156 Grain Extreme Outer Limits (EOL) Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/6-5-prc-156-grain-extreme-outer-limits-eol-elite-hunter-rifle-ammunition/) (2026-10-13)
- [6 mm Creedmoor 105 Grain Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/6-mm-creedmoor-105gr-hybrid-target/) (2026-10-13)
- [6 mm Creedmoor 108 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/6-mm-creedmoor-108gr-elite-hunter-rifle-ammunition/) (2026-10-13)
- [6 mm Creedmoor 109 Grain Long Range Hybrid Target Rifle Ammunition (product page)](https://bergerbullets.com/product/6-mm-creedmoor-109gr-long-range-hybrid-target/) (2026-10-13)
- [6 mm Creedmoor 95 Grain Classic Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/6-mm-creedmoor-95gr-classic-hunter/) (2026-10-13)
- [175 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/7mm-prc-175-gr-elite-hunter-rifle-ammunition/) (2026-10-13)
- [195 Grain Elite Hunter Rifle Ammunition (product page)](https://bergerbullets.com/product/7mm-prc-195-gr-elite-hunter-rifle-ammunition/) (2026-10-13)

**Black Hills** — Black Hills shop/category pages read: they give only bullet names (plus a Dual Performance line text), no tip/base descriptions. Construction/tip/base come from Hornady, Barnes and Sierra own pages. Left empty: Black Hills generic Match HP / Heavy Match HP / OTM / Soft Point / FMJ bases, CX/TSX/TAC-TX/V-MAX bases (makers list BT and FB variants or do not state), V-MAX construction, GMX fields (no Hornady GMX page anymore), Dual Performance tip.

- [Black Hills Gold ammunition](https://www.black-hills.com/product-category/bh-gold-ammo/) (2026-10-13)
- [Black Hills .223 Remington (with related rifle products)](https://www.black-hills.com/shop/new-rifle-ammo/223-remington/) (2026-10-13)
- [Sierra 22 cal 69 gr HPBT MatchKing](https://sierrabullets.com/22-cal-69-gr-hpbt-matchking-smk/) (2026-10-13)
- [Sierra 338 cal 250 gr HPBT MatchKing](https://sierrabullets.com/338-cal-250-gr-hpbt-matchking-smk/) (2026-10-13)
- [Sierra 338 cal 300 gr HPBT MatchKing](https://sierrabullets.com/338-cal-300-gr-hpbt-matchking-smk/) (2026-10-13)
- [Sierra 30 cal 168 gr Tipped MatchKing](https://sierrabullets.com/30-cal-168-gr-tipped-matchking-tmk/) (2026-10-13)
- [Sierra Tipped MatchKing family](https://sierrabullets.com/bullets/product-family/tipped-matchking/) (2026-10-13)
- [Hornady ELD-X bullets](https://www.hornady.com/bullets/eld-x) (2026-10-13)
- [Hornady ELD Match bullets](https://www.hornady.com/bullets/eld-match) (2026-10-13)
- [Hornady CX bullets](https://www.hornady.com/bullets/cx) (2026-10-13)
- [Hornady SST bullets](https://www.hornady.com/bullets/sst-(super-shock-tip)) (2026-10-13)
- [Hornady DGX Bonded bullets](https://www.hornady.com/bullets/dgx-bonded) (2026-10-13)
- [Hornady DGS bullets](https://www.hornady.com/bullets/dgs-dangerous-game-solid) (2026-10-13)
- [Hornady V-MAX bullets](https://www.hornady.com/bullets/v-max) (2026-10-13)
- [Hornady Match bullets](https://www.hornady.com/bullets/match) (2026-10-13)
- [Barnes 30 cal TTSX BT](https://barnesbullets.com/0-308-30-cal-ttsx-bt/) (2026-10-13)
- [Barnes 30 cal TSX BT](https://barnesbullets.com/0-308-30-cal-tsx-bt/) (2026-10-13)
- [Barnes 300 BLK TAC-TX 110 gr FB](https://barnesbullets.com/0-308-300-acc-blk-tac-tx-110-gr-fb/) (2026-10-13)
- [Barnes 22 cal Varmint Grenade FB](https://barnesbullets.com/0-224-22-cal-varmint-grenade-fb/) (2026-10-13)
- [Barnes 22 cal MPG 55 gr FB](https://barnesbullets.com/0-224-22-cal-mpg-55-gr-fb/) (2026-10-13)

**Blaser** — 2026-10-13: blaser.de robots.txt disallows URLs with '?', so the ballistics PDF was read without its query string; it has no CDC description. Blaser ammunition page read for CDC: lead-free, polymer tip, boattail. Construction left empty (page says only 'lead-free expanding bullet', not copper/monolithic in body text). No component bullet name stated.

- [Blaser ammunition - Blaser CDC](https://www.blaser.de/en/products/blaser-ammunition/blaser-cdc-the-accurate-copper-bullet-made-by-barnes) (2026-10-13)

**CCI** — Read 2026-10-13: cci-ammunition.com robots.txt (product pages allowed), product pages of V-Max, VNT, TNT Green (17 HMR + 22 WMR), TNT 17 HMR, A17, 2026 catalog PDF; Speer TNT Green component page for construction. Most rimfire tip shapes come from product-name words. Not stated: A17 'Varmint Tip' material, TNT component maker, construction of lead/copper-plated rimfire bullets (no fitting enum), bases. Quiet-22 Semi-Auto: catalog says both 'RN' and 'Soft Point' - left to name.

- [CCI V-Max 17 HMR](https://www.cci-ammunition.com/rimfire/cci/v-max/6-49.html) (2026-10-13)
- [CCI V-Max 22 WMR](https://www.cci-ammunition.com/rimfire/cci/v-max/6-73.html) (2026-10-13)
- [CCI VNT 17 HMR](https://www.cci-ammunition.com/rimfire/cci/vnt/6-959CC.html) (2026-10-13)
- [CCI VNT 22 WMR](https://www.cci-ammunition.com/rimfire/cci/vnt/6-929CC.html) (2026-10-13)
- [CCI TNT Green 17 HMR](https://www.cci-ammunition.com/rimfire/cci/tnt-green/6-951.html) (2026-10-13)
- [CCI TNT Green 22 WMR](https://www.cci-ammunition.com/rimfire/cci/tnt-green/6-60.html) (2026-10-13)
- [Speer TNT Green component bullet](https://www.speer.com/bullets/rifle-bullets/tnt-green-bullet/19-1021.html) (2026-10-13)
- [CCI 2026 catalog](https://www.cci-ammunition.com/on/demandware.static/-/Library-Sites-VistaCCISharedLibrary/default/v91e820dd9e99e25799a98c3df74baf9b44b130a9/pdfDocuments/catalog/CC313_Catalog-2026_WEB.pdf) (2026-10-13)
- [CCI A17](https://www.cci-ammunition.com/rimfire/cci/a17/6-949CC.html) (2026-10-13)

**CheyTac** — no page read; only product-name words. Note: cheytac.com robots.txt checked. Pages only say 'Copper Nickel Alloy bullet' (.375) / 'Match Grade Copper Alloy Bullet' (.408), 'Balanced Flight Projectile'; monolithic/tip/base not stated, left empty.

**Crosman** — 2026-10-13: robots.txt read (product paths and uploads allowed). All 10 product pages + 2026-27 catalog PDF read. Spec 'Material: Lead' for Hollow Point, Domed, Piranha, Pointed, Destroyer, Wadcutter. Penetrators 'Lead Free Pointed Polymer Belted' / catalog 'pointed, lead-free'. Destroyer 'Shape: Pointed'. Not stated: Premier Copper Domed material (only copper coating), Domed Ultra Heavy material, Challenger material (Prop 65 only). No base stated.

- [Crosman Hollow Point Pellet](https://www.crosman.com/product/crosman-hollow-point-pellet/) (2026-10-13)
- [Crosman Domed Pellets](https://www.crosman.com/product/crosman-domed-pellets/) (2026-10-13)
- [Crosman Piranha Hollow Point Pellet](https://www.crosman.com/product/crosman-piranha-hollow-point-pellet/) (2026-10-13)
- [Crosman Red Flight Penetrator .22](https://www.crosman.com/product/crosman-red-flight-penetrator-22/) (2026-10-13)
- [Crosman Fast Flight Penetrator .177](https://www.crosman.com/product/crosman-fast-flight-penetrator-177/) (2026-10-13)
- [Crosman 2026-27 Catalog](https://www.crosman.com/wp-content/uploads/2026/03/2026_27_Crosman_Catalog.pdf) (2026-10-13)
- [Crosman Pointed Pellets](https://www.crosman.com/product/crosman-pointed-pellets/) (2026-10-13)
- [Crosman Destroyer Pellets](https://www.crosman.com/product/crosman-destroyer-pellets/) (2026-10-13)
- [Crosman Wadcutter Pellet .177](https://www.crosman.com/product/crosman-wadcutter-pellet-177/) (2026-10-13)

**Cutting Edge Bullets** — Read 2026-10-13: TechDataSheets2026.pdf (cdn.shopify.com, robots ok) and cuttingedgebullets.com blog/collection/product pages (robots ok). All lines solid copper lead-free -> monolithic_copper; MTAC is a non-expanding target bullet -> match. Tip: LAZER 'expanding hollow point' (tip material not stated, so hollow_point), MTH 'hollow point counterpart'; MTAC nose not stated. Base not stated for any line (only FB Raptor, not in records, is flat base). 'MAX'/'GEN2'/'SINGLE FEED' suffixes not explained, so MAXIMUS-line text was not applied to MAX records.

- [Tech Data Sheets 2026](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) (2026-10-13)
- [Our Bullet Lines](https://cuttingedgebullets.com/blogs/news/our-bullet-lines) (2026-10-13)
- [Our OG Solid Copper Bullet Line: MTAC & MTH](https://cuttingedgebullets.com/blogs/news/our-og-solid-copper-bullet-line-mtac-mth) (2026-10-13)
- [LAZER collection](https://cuttingedgebullets.com/collections/lazer) (2026-10-13)

**Diana** — 2026-10-13: robots.txt read (product paths allowed). All 6 product pages read: each lists 'Material: Blei' (Stitch Copper 'Blei, verkupfert') -> lead_pellet. Point/Stitch Copper 'präzise Spitzkugel' -> pointed; Sport 'Geriffeltes Flachkopf-Diabolo' -> flat_nose. High Power / Hunters Mate head shape and all bases not stated.

- [DIANA DOMED XXL Diabolos](https://www.diana-airguns.de/DIANA-DOMED-XXL-Diabolos/44405001) (2026-10-13)
- [DIANA High Power Diabolos](https://www.diana-airguns.de/DIANA-High-Power-Diabolos/44800006) (2026-10-13)
- [DIANA Hunters Mate Diabolos](https://www.diana-airguns.de/DIANA-Hunters-Mate-Diabolos/44403006) (2026-10-13)
- [DIANA Point Diabolos](https://www.diana-airguns.de/DIANA-Point-Diabolos/44600005) (2026-10-13)
- [DIANA Sport Diabolos](https://www.diana-airguns.de/DIANA-Sport-Diabolos/44400005) (2026-10-13)
- [DIANA Stitch Copper Diabolos](https://www.diana-airguns.de/DIANA-Stitch-Copper-Diabolos/44403009) (2026-10-13)

**ELEY** — eley.co.uk robots.txt allows all. tenex page states flat nose; construction/base not stated.

- [ELEY tenex](https://eley.co.uk/eley-tenex) (2026-10-13)

**Federal** — federalpremium.com product pages read (robots ok) per line; component maker pages: hornady.com (ELD-X, V-MAX), swiftbullets.com/pages/partners (Scirocco boat tail). shop.barnesbullets.com robots-disallowed; nosler.com/partition fetch error. Base not stated for Fusion, Power-Shok, Partition, TSX, LRX, A-Frame, Berger Hybrid Hunter, CenterStrike, AE; tip shape not stated for Power-Shok/Fusion beyond 'soft point', Partition, A-Frame, Woodleigh (concave nose + polymer cap) left empty. Rimfire/AE/Training lines: pages give no construction detail beyond names.

- [Terminal Ascent 270 Win 136 gr](https://www.federalpremium.com/rifle/terminal-ascent/11-P270TA1.html) (2026-10-13)
- [Terminal Ascent line page](https://www.federalpremium.com/terminal-ascent.html) (2026-10-13)
- [Trophy Bonded Tip 308 Win 180 gr](https://www.federalpremium.com/rifle/trophy-bonded-tip/11-P308TT1.html) (2026-10-13)
- [Trophy Bonded Tip component .338 200 gr](https://www.federalpremium.com/reloading/bullets/trophy-bonded-tip-component-bullet/11-PB338TT200.html) (2026-10-13)
- [Trophy Copper 308 Win 150 gr](https://www.federalpremium.com/rifle/trophy-copper/11-P308TC3.html) (2026-10-13)
- [Fusion Rifle 308 Win 150 gr](https://www.federalpremium.com/rifle/fusion/11-F308FS1.html) (2026-10-13)
- [Fusion Tipped Rifle 308 Win 180 gr](https://www.federalpremium.com/rifle/fusion-tipped-rifle/11-F308TFS3.html) (2026-10-13)
- [Federal Subsonic 308 Win 190 gr Fusion Tipped](https://www.federalpremium.com/rifle/federal-subsonic/11-F308TF3SUB.html) (2026-10-13)
- [Power-Shok Rifle 308 Win 150 gr](https://www.federalpremium.com/rifle/power-shok/11-308A.html) (2026-10-13)
- [Power-Shok Copper Rifle 308 Win 150 gr](https://www.federalpremium.com/rifle/power-shok-copper-rifle/11-308150LFA.html) (2026-10-13)
- [Nosler Partition 308 Win 150 gr](https://www.federalpremium.com/rifle/nosler-partition/11-P308S.html) (2026-10-13)
- [Barnes TSX 300 Win Mag 180 gr](https://www.federalpremium.com/rifle/barnes-tsx/11-P300WP.html) (2026-10-13)
- [Barnes LRX 7mm Rem Mag 145 gr](https://www.federalpremium.com/rifle/barnes-lrx/11-P7RLRX2.html) (2026-10-13)
- [Berger Hybrid Hunter 6.5 Creedmoor 135 gr](https://www.federalpremium.com/rifle/berger-hybrid-hunter/11-P65CRDBCH1.html) (2026-10-13)
- [Berger Elite Hunter 7mm PRC 195 gr](https://www.federalpremium.com/rifle/berger-elite-hunter/11-P7PRCEH1.html) (2026-10-13)
- [Federal ELD-X 6.5 Creedmoor](https://www.federalpremium.com/rifle/eld-x/11-P65CRDELDX1.html) (2026-10-13)
- [Hornady ELD-X bullets](https://www.hornady.com/bullets/eld-x) (2026-10-13)
- [Hornady V-MAX bullets](https://www.hornady.com/bullets/v-max) (2026-10-13)
- [Varmint & Predator 243 Win 75 gr Hornady V-Max](https://www.federalpremium.com/rifle/varmint-and-predator-2/11-V243VM75.html) (2026-10-13)
- [Swift Scirocco II 270 Win 130 gr](https://www.federalpremium.com/rifle/swift-scirocco-ii/11-P270SS1.html) (2026-10-13)
- [Swift: partners loading A-Frame & Scirocco](https://www.swiftbullets.com/pages/partners) (2026-10-13)
- [Safari Swift A-Frame 375 H&H 300 gr](https://www.federalpremium.com/rifle/safari-swift-a-frame/11-P375SA.html) (2026-10-13)
- [Safari Trophy Bonded Bear Claw 375 H&H](https://www.federalpremium.com/rifle/safari-trophy-bonded-bear-claw/11-P375T1.html) (2026-10-13)
- [Safari Trophy Bonded Sledgehammer Solid 375 H&H 300 gr](https://www.federalpremium.com/rifle/safari-trophy-bonded-sledgehammer-solid/11-P375T2.html) (2026-10-13)
- [Safari Woodleigh Hydro Solid 375 H&H 300 gr](https://www.federalpremium.com/rifle/safari-woodleigh-hydro-solid/11-P375WH.html) (2026-10-13)
- [Gold Medal Sierra MatchKing 308 Win](https://www.federalpremium.com/rifle/gold-medal/gold-medal-sierra-matchking/11-GM308M2.html) (2026-10-13)
- [Gold Medal Sierra Tipped MatchKing 6.5 Creedmoor +Peak 153 gr](https://www.federalpremium.com/rifle/gold-medal-sierra-tipped-matchking/11-GM65CRDPKTMK1.html) (2026-10-13)
- [Gold Medal CenterStrike 308 Win 168 gr](https://www.federalpremium.com/rifle/gold-medal/gold-medal-centerstrike/11-GM308OTM1.html) (2026-10-13)
- [Gold Medal Berger 223 Rem 73 gr BT Target](https://www.federalpremium.com/rifle/gold-medal/gold-medal-berger/11-GM223BH73.html) (2026-10-13)

**Fiocchi** — fiocchi.com product pages (bullet type field only), 2025 hunting catalogue PDF, fiocchiusa.com product pages and Sierra MatchKing page read. Left empty: SE Freccia Nera construction (rifle text says only 'Solid Expansive lead free', copper stated only in the shotgun section), all EPN/SP construction and bases, rimfire 'copper-plated' bullets (no enum), GameKing construction, Exacta 140 HPBT maker/construction (page does not name Sierra).

- [Fiocchi Performance .223 Rem 55 gr EPN](https://fiocchi.com/en/705635.html) (2026-10-13)
- [Fiocchi hunting catalogue 2025](https://fiocchi.com/pub/static/frontend/bs_mazia/bs_mazia2/it_IT/media/catalogs/Cat-CACCIA-02-2025-web.pdf) (2026-10-13)
- [Fiocchi Classic .223 Rem 45 gr Duty ZP FRG](https://fiocchi.com/en/745582.html) (2026-10-13)
- [Fiocchi Classic .223 Rem 50 gr FMJHP](https://fiocchi.com/en/705559.html) (2026-10-13)
- [Fiocchi Classic .300 Blackout 147 gr FMC](https://fiocchi.com/en/703009.html) (2026-10-13)
- [Fiocchi Exacta .308 Win 168 gr HPBT Sierra MatchKing](https://fiocchi.com/en/709890.html) (2026-10-13)
- [Fiocchi Field Dynamics Big Game .350 Legend 180 gr FSP](https://www.fiocchiusa.com/centerfire-rifle/field-dynamics/field-dynamics-big-game/33-350LB.html) (2026-10-13)
- [Sierra 22 cal 69 gr HPBT MatchKing](https://sierrabullets.com/22-cal-69-gr-hpbt-matchking-smk/) (2026-10-13)

**FX** — 2026-10-13: robots.txt fetched (empty). Read FX Halo page: 'massive hollow point' -> hollow_point. Material and base not stated.

- [FX Halo](https://www.fxairguns.com/accessories/ammunition/fx-halo/) (2026-10-13)

**Gamo** — 2026-10-13: robots.txt read (gamousa.com; /product/ allowed). All 18 product pages read; construction from spec 'Material: Lead' / 'Non-Lead'. Tips stated per page (polymer tip, round nose/domed tip, spire point, flat-nose wadcutter, pyramid tip, pointed head, pointed hollow point). Rocket tip ('Hardened steel tip') and Whisper tip not mapped. No base stated (only 'long skirt').

- [Red Fire Polymer Tip Pellets](https://gamousa.com/product/red-fire-pellets-22-cal/) (2026-10-13)
- [Gamo Hunter .22 Lead Pellets](https://gamousa.com/product/hunter-22-cal/) (2026-10-13)
- [Rocket Steel Tip Pellets](https://gamousa.com/product/rocket-pellets-22-cal/) (2026-10-13)
- [Magnum Pointed Tip Pellets](https://gamousa.com/product/magnum-22-cal/) (2026-10-13)
- [Match Flat Nose Pellets](https://gamousa.com/product/match-pellets-22-cal/) (2026-10-13)
- [Lethal Steel Domed Tip Pellets](https://gamousa.com/product/lethal-177-cal-qty/) (2026-10-13)
- [PBA Bullet Domed Tip Pellets](https://gamousa.com/product/pba-bullet-pellets-22-cal/) (2026-10-13)
- [TS-10 / TS-22 Pellets](https://gamousa.com/product/ts-10-22-pellets/) (2026-10-13)
- [Luxor Cu Pyramid Shaped Pellets](https://gamousa.com/product/luxor-cu-sharp-pyramid-shaped-pellet-22/) (2026-10-13)
- [Whisper Heavy Weight Quiet Pellets](https://gamousa.com/product/whisper-pellet-high-weight-quiet-pellet-22-cal-qty-100-blister/) (2026-10-13)
- [PBA Raptor Domed Tip Pellets](https://gamousa.com/product/pba-raptor-pellets-22-cal/) (2026-10-13)
- [Match Lead Free Pellets](https://gamousa.com/product/match-lead-free-177-cal/) (2026-10-13)
- [PBA Platinum Domed Tip Pellets](https://gamousa.com/product/pba-platinum-pellets-22cal/) (2026-10-13)
- [G-Hammer Heavy Weight Pellets](https://gamousa.com/product/g-hammer-heavy-weight-pellet-177-cal/) (2026-10-13)
- [Pro Magnum Domed Tip Pellets](https://gamousa.com/product/pro-magnum-pellets-25-cal/) (2026-10-13)
- [Blue Bomber Pellets .22 Hard Polymer Tip](https://gamousa.com/product/blue-bomber-pellets-22/) (2026-10-13)
- [AccuTek Swarm 10X Hollow Point Pellet](https://gamousa.com/product/swarm-10x-hollow-point-pellet-22-250/) (2026-10-13)
- [Tomahawk Hollow Point Pellets](https://gamousa.com/product/tomahawk-22-cal-pellet-ammunition/) (2026-10-13)

**Geco** — 2026-10-13: geco-ammunition.com robots.txt only disallows /private/ (crawl-delay 5). Read GECO line pages (Plus product page, Express, DTX, Star, Zero, Target HP, rimfire Rifle/Semi-Auto) and the 2026 EN Magalogue PDF. Rimfire tip from spec 'Bullet type: LRN'. Not stated anywhere: bases for every line, Express/DTX construction and tip, Star jacketed or monolithic, Target HP match status, component bullet names.

- [GECO .270 Win PLUS 9.7g](https://geco-ammunition.com/en/ammunition/products-overview/centrefire-rifle-cartridges/geco-plus/geco-270-win-plus-97g) (2026-10-13)
- [GECO Magalogue EN 2026](https://geco-ammunition.com/resources/user_upload/GECO_Magalogue_EN_2026_low-res.pdf) (2026-10-13)
- [GECO STAR](https://geco-ammunition.com/en/ammunition/products-overview/centrefire-rifle-cartridges/geco-star) (2026-10-13)
- [GECO ZERO](https://geco-ammunition.com/en/ammunition/products-overview/centrefire-rifle-cartridges/geco-zero) (2026-10-13)
- [GECO TARGET HP](https://geco-ammunition.com/en/ammunition/products-overview/centrefire-rifle-cartridges/geco-target-hp) (2026-10-13)
- [GECO RIFLE .22 lr](https://geco-ammunition.com/en/ammunition/products-overview/rimfire-cartridges/geco-rifle) (2026-10-13)
- [GECO SEMI-AUTO .22 lr](https://geco-ammunition.com/en/ammunition/products-overview/rimfire-cartridges/geco-semi-auto) (2026-10-13)

**Hammer Bullets** — Read 2026-10-13 from hammerbullets.com (robots.txt allows product and info pages): home, /hammer-hunter, /about-our-bullets/, one product page. Construction from brand-wide statement (all Hammer bullets solid copper, lead free). Hammer Hunter: 1.5mm hollow point. Base (boat tail/flat) not stated for Hammer Hunter; product page gives no shape details.

- [About our bullets](https://hammerbullets.com/about-our-bullets/) (2026-10-13)
- [Hammer Hunter](https://hammerbullets.com/hammer-hunter) (2026-10-13)

**H&N** — 2026-10-13: robots.txt read (product paths allowed). ~35 product pages read. Stated: Heavy Slug 'hollow point design with a large meplat combined with soft lead'; Grizzly hollow point + hollow base; GreenLine (Baracuda/FTT/Match Green) lead-free tin alloy; Power/Coppa 'encapsulating the lead core'; Hunter/Hunter Extreme/Crow Magnum hollow point; Hammer round head; Spike/Coppa-Spitzkugel pointed. Not stated (empty): Baracuda/Match/FT/8/15/18, FTT, Slug HP / HP II, Precision Slug, Hornet, Terminator ('tapered tip'), Rabbit Magnum II ('torpedo'), Silver Point, Spitzkugel, Finale Match, Match, Sport, Econ II, Plinking; 'special alloy' not mapped. No base stated except Grizzly.

- [Heavy Slug 36 gr .22](https://www.hn-sport.de/en/air-gun-hunting/heavy-slug-36-gr) (2026-10-13)
- [Heavy Slug 40 gr .25](https://www.hn-sport.de/en/air-gun-hunting/heavy-slug-25-40-gr) (2026-10-13)
- [Grizzly .25](https://www.hn-sport.de/en/air-gun-hunting/grizzly-25) (2026-10-13)
- [Grizzly .35](https://www.hn-sport.de/en/air-gun-hunting/grizzly-35) (2026-10-13)
- [Baracuda Green .22](https://www.hn-sport.de/en/air-gun-hunting/baracuda-green-22) (2026-10-13)
- [Field Target Trophy Green .22](https://www.hn-sport.de/en/air-gun-hunting/field-target-trophy-green-22) (2026-10-13)
- [Match Green .177](https://www.hn-sport.de/en/target-shooting/match-green-177) (2026-10-13)
- [Baracuda Power .22](https://www.hn-sport.de/en/air-gun-hunting/baracuda-power-22) (2026-10-13)
- [Field Target Trophy Power .22](https://www.hn-sport.de/en/air-gun-hunting/field-target-trophy-power-22) (2026-10-13)
- [Coppa-Spitzkugel .22](https://www.hn-sport.de/en/action-shooting/coppa-spitzkugel-22) (2026-10-13)
- [Spike .22](https://www.hn-sport.de/en/action-shooting/spike-22) (2026-10-13)
- [Hammer .22](https://www.hn-sport.de/en/action-shooting/hammer-22) (2026-10-13)
- [Baracuda Hunter .22](https://www.hn-sport.de/en/air-gun-hunting/baracuda-hunter-22) (2026-10-13)
- [Baracuda Hunter Extreme .22](https://www.hn-sport.de/en/air-gun-hunting/baracuda-hunter-extreme-22) (2026-10-13)
- [Crow Magnum .22](https://www.hn-sport.de/en/air-gun-hunting/crow-magnum-22) (2026-10-13)

**Hatsan** — 2026-10-13: robots.txt read (hatsan.com.tr, hatsanairgunsusa.com; product paths allowed). Read hatsan.com.tr/en/pellets (Pointed Head only) and 15 hatsanairgunsusa product pages. Stated: Pointed Head lead; Vortex Strike domed + lead; Big Bore Supreme 'Heavier lead pellets'; Air Boss Match / Champion 'Pellet Shape: Flat' -> flat_nose; Domed Hollow 'Domed Hollow Point' -> hollow_point; Magnum 'Pointed'. Not stated: Apolo Slug, Hunter, Monster, Destroyer, Conic ('Conic shape' not mapped); material on Apolo pages only a Prop 65 image. No base stated anywhere.

- [Hatsan pellets](https://hatsan.com.tr/en/pellets/) (2026-10-13)
- [Vortex STRIKE Pellets](https://hatsanairgunsusa.com/product/vortex-strike-pellets/) (2026-10-13)
- [Vortex Big Bore Supreme Pellets](https://hatsanairgunsusa.com/product/vortex-big-bore-supreme-pellets/) (2026-10-13)
- [Apolo Air Boss Match Competition](https://hatsanairgunsusa.com/product/apolo-air-boss-match-competition/) (2026-10-13)
- [Apolo Air Boss Match Competition Air Pistol](https://hatsanairgunsusa.com/product/apolo-air-boss-match-competition-air-pistol/) (2026-10-13)
- [Apolo Champion](https://hatsanairgunsusa.com/product/apolo-champion/) (2026-10-13)
- [Apolo Domed Hollow](https://hatsanairgunsusa.com/product/apolo-domed-hollow/) (2026-10-13)
- [Apolo Magnum](https://hatsanairgunsusa.com/product/apolo-magnum/) (2026-10-13)

**Hornady** — Read 2026-10-13 from hornady.com only (robots.txt allows /bullets and /ammunition). Line pages: ELD Match, ELD-X, ELD-VT, A-Tip Match, A-MAX, CX, ECX, MonoFlex, NTX, V-MAX, SST, InterLock, FTX, Sub-X, DGS, DGX Bonded, Match, AeroMatch, XTP, Varmint; product pages for records without a line word in the name. Empty on purpose: A-Tip tip (aluminium tip, no enum value); A-MAX tip/construction (page says only 'sharp pointed tip'); V-MAX base (line has both boattail and flat base); Varmint line tip/base ('Primarily' spire point / flat base, not per product); InterLock/FTX/CX/ECX/MonoFlex/Sub-X/XTP/NTX/ELD-VT base not stated; XTP construction not stated (lead not named); FMJ base/nose not stated; Traditional & FMJ (.224 55 HP, .257 60 FP, .308 125 HP) not stated. Flex Tip (FTX/MonoFlex/Sub-X) and Heat Shield (ELD) mapped to polymer_tip; DGS 'Solid' with copper-clad steel jacket over lead core mapped to fmj. Factory cartridge pages mostly give no bullet details; line-page facts applied via the bullet line named in the cartridge name; component_bullet from the cartridge name. Not readable: /bullets/rifle/30-cal-308-110-gr-sp (JavaScript wall twice); ammunition line page precision-hunter (fetch error). .51 750 gr A-MAX URL now shows the A-Tip Match 750 gr page; only A-MAX line base used.

- [ELD Match bullets](https://www.hornady.com/bullets/eld-match) (2026-10-13)
- [ELD-X bullets](https://www.hornady.com/bullets/eld-x) (2026-10-13)
- [ELD-VT bullets](https://www.hornady.com/eld-vt) (2026-10-13)
- [A-Tip Match bullets](https://www.hornady.com/bullets/a-tip-match) (2026-10-13)
- [A-MAX bullets](https://www.hornady.com/bullets/a-max) (2026-10-13)
- [CX bullets](https://www.hornady.com/bullets/cx) (2026-10-13)
- [ECX bullets](https://www.hornady.com/bullets/ecx) (2026-10-13)
- [MonoFlex bullets](https://www.hornady.com/bullets/monoflex) (2026-10-13)
- [NTX bullets](https://www.hornady.com/bullets/ntx) (2026-10-13)
- [V-MAX bullets](https://www.hornady.com/bullets/v-max) (2026-10-13)
- [SST bullets](https://www.hornady.com/bullets/sst-(super-shock-tip)) (2026-10-13)
- [InterLock bullets](https://www.hornady.com/bullets/interlock) (2026-10-13)
- [FTX bullets](https://www.hornady.com/bullets/ftx) (2026-10-13)
- [Sub-X bullets](https://www.hornady.com/bullets/sub-x) (2026-10-13)
- [DGS bullets](https://www.hornady.com/bullets/dgs-dangerous-game-solid) (2026-10-13)
- [DGX Bonded bullets](https://www.hornady.com/bullets/dgx-bonded) (2026-10-13)
- [505 Cal .505 525 gr DGX (DGX line text)](https://www.hornady.com/bullets/rifle/505-cal-505-525-gr-dgx-505-gibbs) (2026-10-13)
- [Match bullets](https://www.hornady.com/bullets/match) (2026-10-13)
- [AeroMatch bullets](https://www.hornady.com/bullets/aeromatch) (2026-10-13)
- [XTP bullets](https://www.hornady.com/bullets/xtp) (2026-10-13)
- [Varmint bullets](https://www.hornady.com/bullets/varmint) (2026-10-13)
- [22 Cal .224 45 gr HP Bee (Varmint line)](https://www.hornady.com/bullets/rifle/22-cal-224-45-gr-hp-bee) (2026-10-13)
- [22 Cal .224 45 gr Hornet (Varmint line)](https://www.hornady.com/bullets/rifle/22-cal-224-45-gr-hornet) (2026-10-13)
- [22 Cal .224 60 gr SP (Varmint line)](https://www.hornady.com/bullets/rifle/22-cal-224-60-gr-sp) (2026-10-13)
- [22 Cal .224 50 gr SP SX (Varmint line)](https://www.hornady.com/bullets/rifle/22-cal-224-50-gr-sp-sx) (2026-10-13)
- [22 Cal .224 55 gr SP SX (Varmint line)](https://www.hornady.com/bullets/rifle/22-cal-224-55-gr-sp-sx) (2026-10-13)
- [6mm .243 87 gr BTHP (Varmint line)](https://www.hornady.com/bullets/rifle/6mm-243-87-gr-bthp) (2026-10-13)
- [45 Cal .458 300 gr HP (InterLock line)](https://www.hornady.com/bullets/rifle/45-cal-458-300-gr-hp) (2026-10-13)
- [7.62 Cal .310 123 gr SP (InterLock line)](https://www.hornady.com/bullets/rifle/7-62-cal-310-123-gr-sp) (2026-10-13)
- [35 Cal .355 170 gr InterLock](https://www.hornady.com/bullets/rifle/35-cal-.355-170-gr-sp) (2026-10-13)
- [45 Cal .452 245 gr InterLock](https://www.hornady.com/bullets/rifle/45-cal-.452-245-gr-sp) (2026-10-13)
- [270 Cal .277 110 gr BTHP with Cannelure (Match line)](https://www.hornady.com/bullets/rifle/270-6-8mm-277-110-gr-bthp-with-cannelure) (2026-10-13)
- [22 Cal .224 53 gr HP Match](https://www.hornady.com/bullets/rifle/22-cal-224-53-gr-hp-match) (2026-10-13)
- [6.5 Creedmoor 143 gr ELD-X Precision Hunter](https://www.hornady.com/ammunition/rifle/6-5-creedmoor-143-gr-eld-x-precision-hunter) (2026-10-13)
- [308 Win 150 gr InterLock SP American Whitetail](https://www.hornady.com/ammunition/rifle/308-win-150-gr-interlock-sp-american-whitetail) (2026-10-13)
- [308 Win 165 gr CX Outfitter](https://www.hornady.com/ammunition/rifle/308-win-165-gr.-cx-outfitter) (2026-10-13)

**Lapua** — Read lapua.com robots.txt (only /wp-admin/ disallowed), 2024 catalogue PDF and product pages. Scenar/Scenar-L/MaxRange/TRX/Mega/Lock Base/Naturalis lines filled from line text. Not stated on maker pages: AP/API cartridges (only 'Armor Piercing'), rimfire .22 LR (Center-X, Midas+ etc.: no bullet design), Scenar-L base, Mega tip shape/base, Naturalis tip, factory 'Open Tip' 8x57/9.3x62 lines. Initial fetches hit PROVENANCE_REQUIRED, succeeded on retry.

- [Lapua product catalog 2024](https://www.lapua.com/wp-content/uploads/2024/02/Lapua_Catalog_2024.pdf) (2026-10-13)
- [Scenar OTM GB422](https://www.lapua.com/product/30-scenar-bullet-gb422-1085-g-167-gr-otm/) (2026-10-13)
- [Scenar-L OTM GB550](https://www.lapua.com/product/30-scenar-l-bullet-gb550-113-g-175-gr-otm/) (2026-10-13)
- [6.5x47 Scenar-L 136 gr cartridge](https://www.lapua.com/product/6-5x47-open-tip-match-cartridge-lapua-scenar-l-88g-136gr-4316016/) (2026-10-13)
- [MaxRange Target OTM GB582](https://www.lapua.com/product/6-5-mm-175-gr-maxrange-target-bullet-otm-gb582/) (2026-10-13)
- [6.5 Creedmoor MaxRT OTM 144 gr cartridge](https://www.lapua.com/product/6-5-creedmoor-9-3-g-144-grains-maxrt-otm-cartridge/) (2026-10-13)
- [TRX hunting bullet N585](https://www.lapua.com/product/9-7-g-150-gr-trx-hunting-bullet-n585/) (2026-10-13)
- [6.5 Creedmoor TRX 120 gr cartridge](https://www.lapua.com/product/6-5-creedmoor-7-8-g-120-grains-trx/) (2026-10-13)
- [Mega SP E415](https://www.lapua.com/product/30-cal-mega-hunting-bullet-e415-120-g-185-gr-sp/) (2026-10-13)
- [Lock Base FMJBT B476](https://www.lapua.com/product/30-cal-lock-base-bullet-b476-110-g-170-gr-fmjbt/) (2026-10-13)
- [Cutting Edge G477](https://www.lapua.com/product/30-cal-cutting-edge-bullet-g477-65-g-100-gr-hp/) (2026-10-13)
- [Open Tip G580](https://www.lapua.com/product/30-cal-open-tip-bullet-g580-65-g-100-gr-ot/) (2026-10-13)

**Magtech** — Read the 2026 catalogue PDF and the 308 Win 168 gr HPBT Sniper product page. Hunt/Tactical/Subsonic lines give no bullet construction, tip or base text; abbreviations (PSP, JSP, HPBT...) are not expanded in the catalogue. Ball/Solid 50 BMG and NATO Ball loads have no description -> empty.

- [Magtech 2026 catalogue](https://magtechammunition.com/wp-content/uploads/2025/12/Magtech-2026-Catalogue.pdf) (2026-10-13)
- [308 Win 168gr HPBT Sniper](https://magtechammunition.com/products/ammunition/308-win-168gr-hpbt-sniper/) (2026-10-13)

**MKE** — mke.gov.tr robots.txt allows. Product pages give only 'Mermi Malzemesi' (e.g. 'Tombak, Kurşun Çekirdek'); FMJ/tip/base not stated, so ball/tracer/AP left empty. 8.59x70 Solid: material 'Pirinç' (brass) -> lead_free_other.

- [8.59x70 Solid Fişek](https://www.mke.gov.tr/Urunler/859-mm-x-70-Solid-Fisek/150) (2026-10-13)

**My Bullet** — 2026-10-13: robots.txt could not be fetched (CLIENT_ERROR twice; treated as absent). Read urunler-55.php and urunler-635.php. Base: 'düz taban' (flat base) stated for 5.5 22/38 gr and 6.35 32/45/60 gr; 5.5 30 gr and 6.35 38 gr say 'oval taban' (no enum) -> empty. Construction: 5.5 page 'tel kurşun' (lead wire) -> lead_slug; 6.35 page states no material. HP from name.

- [My Bullet 5.5 mm](https://mybullet.com.tr/urunler-55.php) (2026-10-13)
- [My Bullet 6.35 mm](https://mybullet.com.tr/urunler-635.php) (2026-10-13)

**Norma** — 2026-10-13: Norma line pages (Oryx, Oryx Silencer, Tipstrike, Tipstrike Silencer, Ecostrike, Ecostrike Silencer, Bondstrike, Whitetail, Vulkan, Evostrike, ODIN, Jaktmatch, Golden Target, Diamond Line, Plastic Point, African PH, African PH Solids, VerminXtreme) and several product pages read. robots.txt allows all. Vulkan tip from Bullet Description 'SP' on all 7 Vulkan product pages. Empty: Norma Solid (page contradicts itself: brass alloy vs steel-jacketed), TAC-22 (no bullet data; one fetch failed), Vermin Xtreme Tipped (page says 'Tipped SP' and 'hollow point' - conflicting), Vulkan/Oryx/Tipstrike/Evostrike/Whitetail/Plastic Point base and Plastic Point construction not stated. Some fetches needed retries (permission timeouts / CLIENT_ERROR).

- [Norma Oryx line](https://www.norma-ammunition.com/products/hunting/norma-oryx) (2026-10-13)
- [Norma Oryx .243 Win 100gr](https://www.norma-ammunition.com/products/hunting/norma-oryx/norma-oryx-243-winchester-100gr---20160332) (2026-10-13)
- [Norma Oryx Silencer Series](https://www.norma-ammunition.com/products/hunting/norma-oryx-silencer-series) (2026-10-13)
- [Norma Tipstrike line](https://www.norma-ammunition.com/products/hunting/norma-tipstrike) (2026-10-13)
- [Norma Tipstrike Silencer Series](https://www.norma-ammunition.com/products/hunting/norma-tipstrike-silencer-series) (2026-10-13)
- [Norma Ecostrike line](https://www.norma-ammunition.com/products/hunting/norma-ecostrike) (2026-10-13)
- [Norma Ecostrike Silencer Series](https://www.norma-ammunition.com/products/hunting/norma-ecostrike-silencer-series) (2026-10-13)
- [Norma Bondstrike line](https://www.norma-ammunition.com/products/hunting/norma-bondstrike) (2026-10-13)
- [Norma Whitetail line](https://www.norma-ammunition.com/products/hunting/norma-whitetail) (2026-10-13)
- [Norma Vulkan line](https://www.norma-ammunition.com/products/hunting/norma-vulkan) (2026-10-13)
- [Norma Vulkan .30-06 180gr (Bullet Description SP; same on all Vulkan product pages)](https://www.norma-ammunition.com/products/hunting/norma-vulkan/norma-vulkan-30-06-springfield-180gr---20176592) (2026-10-13)
- [Norma Evostrike line](https://www.norma-ammunition.com/products/hunting/norma-evostrike) (2026-10-13)
- [Norma ODIN line](https://www.norma-ammunition.com/products/hunting/norma-odin) (2026-10-13)
- [Norma Jaktmatch line](https://www.norma-ammunition.com/products/hunting/norma-jaktmatch) (2026-10-13)
- [Norma Golden Target line](https://www.norma-ammunition.com/products/shooting/norma-golden-target) (2026-10-13)
- [Norma Diamond Line](https://www.norma-ammunition.com/products/shooting/norma-diamond-line) (2026-10-13)
- [Norma Plastic Point line](https://www.norma-ammunition.com/products/hunting/norma-plastic-point) (2026-10-13)
- [Norma African PH (Woodleigh)](https://www.norma-ammunition.com/products/hunting/norma-african-ph) (2026-10-13)
- [Norma VerminXtreme line](https://www.norma-ammunition.com/products/hunting/norma-verminxtreme) (2026-10-13)

**Nosler** — Read 2026-10-13 from nosler.com only (robots.txt empty = no restrictions). Line pages: Partition, AccuBond, AccuBond LR, Ballistic Tip Hunting/Varmint/Lead Free, Ballistic Silvertip, Expansion Tip, Custom Competition, RDF, Varmageddon, Solid, Solid Base; all 33 Partition, 5 Solid and 3 Solid Base component product pages (Bullet Base/Bullet Profile spec fields); most factory pages (Loaded with ... sentence, Bullet Type/Profile). Also checked the 2026 product guide PDF (no extra base data). Empty on purpose: Ballistic Tip Varmint construction (core not named); Solid construction (only "lead-free alloy", metal not named); Partition PPT tip (Protected Point, no enum); Bonded Solid Base tip/base (protected point, base shape not stated); factory Partition/Solid base (cartridge pages give no base). Partition tip = per-product Bullet Profile (Spitzer -> spitzer_soft_point). Factory line facts come from the Nosler line pages (same maker). Fetch error once: 458 Cal 300gr Ballistic Tip Hunting product page (line page covers it).

- [Partition bullets (line page)](https://www.nosler.com/products/bullets/product-line/partitionr.html) (2026-10-13)
- [AccuBond bullets (line page)](https://www.nosler.com/products/bullets/product-line/accubond.html) (2026-10-13)
- [AccuBond Long Range bullets (line page)](https://www.nosler.com/products/bullets/product-line/accubondr-long-range.html) (2026-10-13)
- [Ballistic Tip Hunting bullets (line page)](https://www.nosler.com/products/bullets/product-line/ballistic-tipr-hunting.html) (2026-10-13)
- [Ballistic Tip Varmint bullets (line page)](https://www.nosler.com/products/bullets/product-line/ballistic-tipr-varmint.html) (2026-10-13)
- [Ballistic Tip Lead Free bullets (line page)](https://www.nosler.com/products/bullets/product-line/ballistic-tipr-lead-free.html) (2026-10-13)
- [Ballistic Silvertip bullets (line page)](https://www.nosler.com/products/bullets/product-line/ballisticr-silver-tip.html) (2026-10-13)
- [Expansion Tip bullets (line page)](https://www.nosler.com/products/bullets/product-line/expansion-tipr.html) (2026-10-13)
- [Custom Competition bullets (line page)](https://www.nosler.com/products/bullets/product-line/custom-competitionr.html) (2026-10-13)
- [RDF bullets (line page)](https://www.nosler.com/products/bullets/product-line/rdfr.html) (2026-10-13)
- [Varmageddon bullets (line page)](https://www.nosler.com/products/bullets/product-line/varmageddonr.html) (2026-10-13)
- [Solid bullets (line page)](https://www.nosler.com/products/bullets/product-line/solidtm.html) (2026-10-13)
- [Solid Base bullets (line page)](https://www.nosler.com/products/bullets/product-line/solid-base-bullet-components.html) (2026-10-13)
- [22 Cal 64gr Bonded Solid Base (product page)](https://www.nosler.com/22-caliber-64gr-bonded-solid-base-100ct-blem.html) (2026-10-13)
- [30 Cal 150gr RN Ballistic Silvertip (product page)](https://www.nosler.com/30-caliber-150gr-rn-ballistic-silvertip-50ct.html) (2026-10-13)
- [222 Rem Mag 50gr Ballistic Tip Varmint NoslerCustom](https://www.nosler.com/222-remington-magnum-50gr-ballistic-tip-varmint-noslercustom-ammunition.html) (2026-10-13)
- [222 Rem Mag 50gr FBHP NoslerCustom](https://www.nosler.com/223-remington-55gr-ballistic-tip-varmint-ammunition-4.html) (2026-10-13)
- [257 Rob +P 110gr AccuBond Trophy Grade](https://www.nosler.com/257-rob-p-110gr-accubond-trophy-grade-ammunition.html) (2026-10-13)
- [270 Wby Mag 150gr AccuBond Long Range Trophy Grade](https://www.nosler.com/270-wby-mag-150gr-accubond-long-range-trophy-grade-ammunition.html) (2026-10-13)
- [28 Nosler 150gr Expansion Tip](https://www.nosler.com/28-nosler-150gr-expansion-tip-ammunition.html) (2026-10-13)
- [28 Nosler 160gr Ballistic Tip Hunting](https://www.nosler.com/28-nosler-160gr-accubond-trophy-grade-ammunition-1.html) (2026-10-13)
- [28 Nosler 168gr Custom Competition Match Grade](https://www.nosler.com/28-nosler-168gr-custom-competition-match-grade-ammunition.html) (2026-10-13)
- [470 NE 500gr Solid Safari](https://www.nosler.com/470-nitro-express-500gr-solid-safari-ammunition.html) (2026-10-13)
- [270 Caliber 130gr Partition (product page)](https://www.nosler.com/270-caliber-130gr-partition-50ct.html) (2026-10-13)
- [30 Caliber 170gr RN Partition (product page)](https://www.nosler.com/30-caliber-170gr-rn-partition-50ct.html) (2026-10-13)
- [8mm 200gr Partition (product page)](https://www.nosler.com/8mm-200gr-partition-50ct.html) (2026-10-13)
- [6mm 85gr Partition (product page)](https://www.nosler.com/6mm-85gr-partition-50ct.html) (2026-10-13)
- [6mm 95gr Partition (product page)](https://www.nosler.com/6mm-95gr-partition-50ct.html) (2026-10-13)
- [6mm 100gr Partition (product page)](https://www.nosler.com/6mm-100gr-partition-50ct.html) (2026-10-13)
- [25 Caliber 100gr Partition (product page)](https://www.nosler.com/25-caliber-100gr-partition-50ct.html) (2026-10-13)
- [25 Caliber 115gr Partition (product page)](https://www.nosler.com/25-caliber-115gr-partition-50ct.html) (2026-10-13)
- [25 Caliber 120gr Partition (product page)](https://www.nosler.com/25-caliber-120gr-partition-50ct.html) (2026-10-13)
- [6.5mm 100gr Partition (product page)](https://www.nosler.com/6-5mm-100gr-partition-50ct.html) (2026-10-13)
- [6.5mm 125gr Partition (product page)](https://www.nosler.com/6-5mm-125gr-partition-50ct.html) (2026-10-13)
- [6.5mm 140gr Partition (product page)](https://www.nosler.com/6-5mm-140gr-partition-50ct.html) (2026-10-13)
- [270 Caliber 140gr Partition (product page)](https://www.nosler.com/270-caliber-140gr-partition-50ct.html) (2026-10-13)
- [270 Caliber 150gr Partition (product page)](https://www.nosler.com/270-caliber-150gr-partition-50ct.html) (2026-10-13)
- [270 Caliber 160gr Partition (product page)](https://www.nosler.com/270-caliber-160gr-partition-50ct.html) (2026-10-13)
- [7mm 140gr Partition (product page)](https://www.nosler.com/7mm-140gr-partition-50ct.html) (2026-10-13)
- [7mm 150gr Partition (product page)](https://www.nosler.com/7mm-150gr-partition-50ct.html) (2026-10-13)
- [7mm 160gr Partition (product page)](https://www.nosler.com/7mm-160gr-partition-50ct.html) (2026-10-13)
- [7mm 175gr Partition (product page)](https://www.nosler.com/7mm-175gr-partition-50ct.html) (2026-10-13)
- [30 Caliber 150gr Partition (product page)](https://www.nosler.com/30-caliber-150gr-partition-50ct.html) (2026-10-13)
- [30 Caliber 165gr Partition (product page)](https://www.nosler.com/30-caliber-165gr-partition-50ct.html) (2026-10-13)
- [30 Caliber 180gr Partition (product page)](https://www.nosler.com/30-caliber-180gr-partition-50ct.html) (2026-10-13)
- [30 Caliber 180gr PPT Partition (product page)](https://www.nosler.com/30-caliber-180gr-ppt-partition-50ct.html) (2026-10-13)
- [30 Caliber 200gr Partition (product page)](https://www.nosler.com/30-caliber-200gr-partition-50ct.html) (2026-10-13)
- [30 Caliber 220gr Partition (product page)](https://www.nosler.com/30-caliber-220gr-partition-50ct.html) (2026-10-13)
- [338 Caliber 210gr Partition (product page)](https://www.nosler.com/338-caliber-210gr-partition-50ct.html) (2026-10-13)
- [338 Caliber 225gr Partition (product page)](https://www.nosler.com/338-caliber-225gr-partition-50ct.html) (2026-10-13)
- [338 Caliber 250gr Partition (product page)](https://www.nosler.com/338-caliber-250gr-partition-50ct.html) (2026-10-13)
- [35 Caliber 225gr Partition (product page)](https://www.nosler.com/35-caliber-225gr-partition-50ct.html) (2026-10-13)
- [35 Caliber 250gr Partition (product page)](https://www.nosler.com/35-caliber-250gr-partition-50ct.html) (2026-10-13)
- [9.3mm 286gr Partition (product page)](https://www.nosler.com/9-3mm-286gr-partition-50ct.html) (2026-10-13)
- [375 Caliber 260gr Partition (product page)](https://www.nosler.com/375-caliber-260gr-partition-50ct.html) (2026-10-13)
- [375 Caliber 300gr Partition (product page)](https://www.nosler.com/375-caliber-300gr-partition-50ct.html) (2026-10-13)
- [9.3mm 286gr Solid (product page)](https://www.nosler.com/9-3mm-286gr-solid-25ct.html) (2026-10-13)
- [375 Caliber 260gr Solid (product page)](https://www.nosler.com/375-caliber-260gr-solid-25ct.html) (2026-10-13)
- [375 Caliber 300gr Solid (product page)](https://www.nosler.com/375-caliber-300gr-solid-25ct.html) (2026-10-13)
- [416 Caliber 400gr Solid (product page)](https://www.nosler.com/416-caliber-400gr-solid-25ct.html) (2026-10-13)
- [458 Caliber 500gr Solid (product page)](https://www.nosler.com/458-caliber-500gr-solid-25ct.html) (2026-10-13)
- [6mm 100gr Solid Base (product page)](https://www.nosler.com/6mm-100gr-solid-base.html) (2026-10-13)
- [6.5mm 140gr Solid Base (product page)](https://www.nosler.com/6-5mm-140gr-solid-base-factory-seconds.html) (2026-10-13)
- [7mm 140gr Solid Base (product page)](https://www.nosler.com/7mm-140gr-solid-base.html) (2026-10-13)
- [160gr Partition Trophy Grade Ammunition - RMEF .28 Nosler (product page)](https://www.nosler.com/28-nosler-160gr-partition-trophy-grade-ammunition.html) (2026-10-13)
- [160gr Partition Trophy Grade Ammunition .280 Ackley Improved (product page)](https://www.nosler.com/280-ackley-improved-160gr-partition-trophy-grade-ammunition.html) (2026-10-13)
- [165 Partition Trophy Grade Ammunition .300 RUM (product page)](https://www.nosler.com/300-rum-165-partition-trophy-grade-ammunition.html) (2026-10-13)
- [180gr Trophy Grade Partition Ammunition .300 RUM (product page)](https://www.nosler.com/300-rum-180gr-trophy-grade-partition-ammunition.html) (2026-10-13)
- [210gr Partition Trophy Grade Ammunition - RMEF .338 Win Mag (product page)](https://www.nosler.com/338-win-mag-210gr-partition-trophy-grade-ammunition-1.html) (2026-10-13)
- [250gr Partition Trophy Grade Ammunition .338 Win Mag (product page)](https://www.nosler.com/338-win-mag-250gr-partition-trophy-grade-ammunition.html) (2026-10-13)
- [416 Remington Mag 400gr Partition Trophy Grade Ammunition .416 Rem Mag (product page)](https://www.nosler.com/416-remington-mag-400gr-partition-trophy-grade-ammunition.html) (2026-10-13)
- [416 Remington Mag 400gr Trophy Grade-Safari Partition Ammunition .416 Rem Mag (product page)](https://www.nosler.com/416-remington-mag-400gr-trophy-grade-safari-partition-ammunition.html) (2026-10-13)

**NSA** — 2026-10-13: robots.txt read (products/ allowed; first 2 attempts PROVENANCE_REQUIRED, 3rd ok). Product pages read: 240gr, 31.2gr, 28.5gr, 265gr TC, 75gr .257, 110gr .35. Every page: 'swaged from soft lead' -> lead_slug (all records). Nose HP comes from the name. NSA 'DB' = 'dish base' (page: 'hollow point nose with a dish base'); base enum has no dish base, so DB records keep base empty (not mapped to hollow_base). FB = flat base comes from the name. Conflicts: 28.5gr and .257 75gr pages say both 'dish base' and 'flat base'; 265gr 'Truncated Cone' page still says hollow point nose.

- [45 cal 240 gr slugs](https://nielsenspecialtyammo.com/products/240-grains-swaged-hollow-point) (2026-10-13)
- [22 cal 31.2 gr slugs](https://nielsenspecialtyammo.com/products/31-2-grain-300-count-22-cal-slug-nsa) (2026-10-13)
- [22 cal 28.5 gr slugs](https://nielsenspecialtyammo.com/products/28-5-grain-325-count-22-cal-slug-nsa) (2026-10-13)
- [.45 cal 265 gr Truncated Cone](https://nielsenspecialtyammo.com/products/45-cal-265-grain-truncated-cone-50ct-0-44-rd) (2026-10-13)
- [.257 75 gr slugs](https://nielsenspecialtyammo.com/products/75-grain-257-flat-base-hollow-point) (2026-10-13)
- [35 cal 110 gr slugs](https://nielsenspecialtyammo.com/products/110-gr-hp-fb-35-cal) (2026-10-13)

**Peregrine** — Read 2026-10-13 from peregrinebullets.com (robots.txt allows /bullets, /about-us, /wp-content/uploads PDF). Construction: reload-data PDF says all Peregrine bullets are gilding-metal monolithics; Glider = target bullet -> match; Brass Backup (brass monolithic) mapped to monolithic_copper (copper alloy). Tip: only Backup/Brass Backup state a large meplat -> flat_nose. PlainsMaster/BushMaster 'plunging tip/initiator' has no enum value; VLR5, Glider, Subsonic, Rex tip not stated. Base not stated on any line page or store page. Store page /store/308-plainsmaster/ gives no construction details.

- [Peregrine Comprehensive Reload Data](https://peregrinebullets.com/wp-content/uploads/2023/11/Peregrine-Comprehensive-Reload-Data-Draft-Rev12-9.pdf) (2026-10-13)
- [About Us](https://peregrinebullets.com/about-us/) (2026-10-13)
- [Glider](https://peregrinebullets.com/bullets/glider/) (2026-10-13)
- [Backup](https://peregrinebullets.com/bullets/backup/) (2026-10-13)
- [Brass Backup](https://peregrinebullets.com/bullets/brass-backup/) (2026-10-13)
- [Subsonic](https://peregrinebullets.com/bullets/subsonic/) (2026-10-13)
- [REX](https://peregrinebullets.com/bullets/rex/) (2026-10-13)

**PMC** — Read pmcammo.com product pages (robots.txt allows /product/). Pages give only bullet-type abbreviations (FMJ-BT, PSP, SP, OTM), already in the names. X-TAC Match page names Sierra Bullets for the .223/.308 loads (bullet model not named); 50 cal Solid Brass stated as match grade. No tip/base text otherwise.

- [X-TAC Match 223 Remington](https://pmcammo.com/product/x-tac-match-223xm/) (2026-10-13)
- [X-TAC Match 308 Winchester](https://pmcammo.com/product/x-tac-match-308xm/) (2026-10-13)
- [X-TAC Match 50 Caliber](https://pmcammo.com/product/x-tac-match-50xm/) (2026-10-13)

**Prvi Partizan** — Bullet-type legend and descriptions read from the PPU 2023 catalogue PDF (prvipartizan.com). ppu-usa.com product pages list only abbreviations (no descriptions). Supreme 'SMK' is not expanded and Sierra is not named on PPU pages/PDF -> component_bullet empty. Construction of SP/PSP not stated beyond 'lead nose' -> empty. .375 H&H 300 gr FMJ left without tip (FMJ shape not confirmed for that load).

- [PPU catalogue 2023 (bullet types)](https://prvipartizan.com/download/PPU_2023.pdf) (2026-10-13)

**Remington** — remington.com product pages read 2026-10-13 (robots ok; WebFetch PROVENANCE_REQUIRED on first 3 tries, then ok). Component maker pages: speer.com (Impact boat tail), sierrabullets.com MatchKing family (HPBT names). Not stated: base for Core-Lokt, Core-Lokt Tipped, CuT, AccuTip(-V), Core-Lokt Copper, UMC, Subsonic; CuT tip ('precision tip', polymer not said); Premier AccuTip (Power Port tip, brass jacket) left empty; UMC/Subsonic construction not stated.

- [Core-Lokt 308 Win 150 gr PSP](https://www.remington.com/rifle/shop-by-caliber/shop-all-calibers/29-27842.html) (2026-10-13)
- [Core-Lokt Tipped 308 Win 150 gr](https://www.remington.com/rifle/core-lokt-tipped/29-29039.html) (2026-10-13)
- [Core-Lokt Tipped Lever Gun 30-30 150 gr](https://www.remington.com/rifle/core-lokt-tipped-lever-gun/29-R21428.html) (2026-10-13)
- [Core-Lokt Copper 270 Win 130 gr](https://www.remington.com/rifle/core-lokt-copper/29-R27855.html) (2026-10-13)
- [Hypersonic Bonded 270 Win 140 gr](https://www.remington.com/rifle/hypersonic-bonded/29-28955.html) (2026-10-13)
- [Premier CuT 308 Win 150 gr](https://www.remington.com/rifle/premier-cut/29-R22344.html) (2026-10-13)
- [Premier Long Range 308 Win 172 gr](https://www.remington.com/rifle/premier-long-range/29-R21345.html) (2026-10-13)
- [Premier Scirocco 308 Win 165 gr](https://www.remington.com/rifle/premier-scirocco/29-29332.html) (2026-10-13)
- [Premier Match 308 Win 168 gr](https://www.remington.com/rifle/premier-match/29-21485.html) (2026-10-13)
- [Premier AccuTip-V 223 Rem 55 gr](https://www.remington.com/rifle/premier-accutip-v/29-29192.html) (2026-10-13)
- [Premier Magnum Rimfire 22 WMR 33 gr AccuTip-V](https://www.remington.com/rimfire/magnum-rimfire/29-21184.html) (2026-10-13)
- [Speer: The Best Bonded Bullets (Impact)](https://www.speer.com/speer-stories/bonding-benefits.html) (2026-10-13)
- [Sierra MatchKing product family](https://sierrabullets.com/bullets/product-family/matchking/) (2026-10-13)

**RWS** — 2026-10-13: rws-technology.com robots.txt could not be fetched (CLIENT_ERROR after 4 tries; the homepage loads, so the file is probably missing). Only the 2025 hunting/sport catalogue download page was read; quotes are German. rws-ammunition.com skipped per brief, so Target Elite Plus, rimfire and all 44 PCP pellets stay empty (not in the catalogue text). Not stated: HIT/EVO/EVO GREEN/Speed Tip tip material (Twin-Compression/Rapid-X/Speed-Tip, no 'polymer'), V-Tail/torpedo tails, DK/ID/UNI construction class, and whether 'MJ' = Match Jagd.

- [RWS Katalog Jagd und Sportschießen 2025](https://www.rws-technology.com/de/downloads/download-detail/rws-katalog-jagd-und-sportschiessen-2025) (2026-10-13)

**Sako** — sako.global robots.txt allows all. Read each line page (Gamehead, Gamehead Pro, Gamehead Varmint RX, Hammerhead, Super Hammerhead, Powerhead Blade, Blade Pro, Blade Solid, Speedhead, TRG Precision/Sport/Defense). TRG Defense: nothing stated. Not stated: Gamehead Pro construction/base, Speedhead tip/base, Hammerhead base, Powerhead Blade/Blade Pro/Solid tip & base (Blade Solid .223 is 'un-tipped'), Varmint RX construction. No component bullet makers named.

- [Sako Gamehead](https://www.sako.global/ammunition/gamehead) (2026-10-13)
- [Sako Gamehead Pro](https://www.sako.global/ammunition/gamehead-pro) (2026-10-13)
- [Sako Gamehead Varmint RX](https://www.sako.global/ammunition/gamehead-varmint-rx) (2026-10-13)
- [Sako Hammerhead](https://www.sako.global/ammunition/hammerhead) (2026-10-13)
- [Sako Super Hammerhead](https://www.sako.global/ammunition/super-hammerhead) (2026-10-13)
- [Sako Powerhead Blade](https://www.sako.global/ammunition/powerhead-blade) (2026-10-13)
- [Sako Powerhead Blade Pro](https://www.sako.global/ammunition/powerhead-blade-pro) (2026-10-13)
- [Sako Powerhead Blade Solid](https://www.sako.global/ammunition/powerhead-blade-solid) (2026-10-13)
- [Sako Speedhead](https://www.sako.global/ammunition/speedhead) (2026-10-13)
- [Sako TRG Precision](https://www.sako.global/ammunition/trg-precision) (2026-10-13)
- [Sako TRG Sport](https://www.sako.global/ammunition/trg-sport) (2026-10-13)

**Sellier & Bellot** — Read sellier-bellot.cz line (category) pages for SP, SPCE, HPC, PTS, eXergy Blue, Sierra, Target (Match), FMJ plus sample detail pages. robots.txt could not be fetched (fetch error); only public product pages were read. eXergy Edge line/detail pages give no bullet description (type 'EDGE' only) -> empty. FMJ/Target pages add nothing beyond the product-name words. No tip shape stated for SP/FMJ; no base stated except eXergy Blue, Sierra SBT, HPBT.

- [Rifle ammunition SP](https://www.sellier-bellot.cz/en-us/products/rifle-ammunition/rifle-ammunition-sp/) (2026-10-13)
- [Rifle ammunition SPCE](https://www.sellier-bellot.cz/en-us/products/rifle-ammunition/rifle-ammunition-spce/) (2026-10-13)
- [Rifle ammunition HPC](https://www.sellier-bellot.cz/en-us/products/rifle-ammunition/rifle-ammunition-hpc/) (2026-10-13)
- [Hunting rifle ammunition with PTS bullets](https://www.sellier-bellot.cz/en-us/products/rifle-ammunition/hunting-rifle-ammunition-with-pts-bullets/) (2026-10-13)
- [17 Hornet V-MAX 20 gr](https://www.sellier-bellot.cz/en-us/products/rifle-ammunition/hunting-rifle-ammunition-with-pts-bullets/detail/115) (2026-10-13)
- [Rifle ammunition with eXergy Blue bullets](https://www.sellier-bellot.cz/en-us/products/rifle-ammunition/rifle-ammunition-with-exergy-blue-bullets/) (2026-10-13)
- [Rifle hunting ammunition with Sierra bullets](https://www.sellier-bellot.cz/en-us/products/rifle-ammunition/rifle-hunting-ammunition-with-sierra-bullets/) (2026-10-13)

**Sierra** — Read 2026-10-13: sierrabullets.com robots.txt (product pages allowed), Bullet 101 line descriptions, ammo category page, MatchKing family page (product list only, no line text), product pages of MKX/SGK/TMK/TGK and all 12 Tipped VarmintKing (polymer tip stated on each). Not stated, left empty: MatchKing/TMK base ('majority'/'all but one' boat tail), TGK base, GameKing/Pro-Hunter/VarmintKing construction, MatchKing X construction, Prairie Enemy tip/base. 'CN' not used (Sierra Bullet 101 defines it as closed nose, ambiguous with cannelure). FMJBT tip shape not stated.

- [Sierra Bullet Selection (Bullet 101)](https://sierrabullets.com/bullet-101/) (2026-10-13)
- [Sierra ammunition (GameChanger, Prairie Enemy)](https://www.sierrabullets.com/product-category/ammo/) (2026-10-13)
- [6.5mm 130 gr Tipped MatchKing](https://www.sierrabullets.com/6-5mm-130-gr-tipped-matchking-tmk/) (2026-10-13)
- [6mm 55 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/6mm-55-gr-tipped-varmintking-tvk/) (2026-10-13)
- [22 Cal 55 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/22-cal-55-gr-tipped-varmintking-tvk/) (2026-10-13)
- [25 Cal 70 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/25-cal-70-gr-tipped-varmintking-tvk/) (2026-10-13)
- [20 Cal 36 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/20-cal-36-gr-tipped-varmintking-tvk/) (2026-10-13)
- [6mm 70 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/6mm-70-gr-tipped-varmintking-tvk/) (2026-10-13)
- [20 Cal 39 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/20-cal-39-gr-tipped-varmintking-tvk/) (2026-10-13)
- [22 Cal 69 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/22-cal-69-gr-tipped-varmintking-tvk/) (2026-10-13)
- [20 Cal 32 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/20-cal-32-gr-tipped-varmintking-tvk/) (2026-10-13)
- [22 Cal 50 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/22-cal-50-gr-tipped-varmintking-tvk/) (2026-10-13)
- [25 Cal 90 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/25-cal-90-gr-tipped-varmintking-tvk/) (2026-10-13)
- [22 Cal 40 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/22-cal-40-gr-tipped-varmintking-tvk/) (2026-10-13)
- [6.5mm 105 gr Tipped VarmintKing TVK](https://www.sierrabullets.com/6-5mm-105-gr-tipped-varmintking-tvk/) (2026-10-13)

**SIG Sauer** — sigsauer.com robots.txt checked (product .html pages allowed). Hybrid Hunter names Nosler AccuBond bonded core; Hybrid Match names Sierra MatchKing HPBT (HPBT not expanded, so tip/base left empty). Elite Ball: only FMJ (from name). 6.8x51 Hybrid Ball: page says 'Solid Copper' but also 'Lead Free: No' -> contradictory, left empty.

- [277 SIG Fury 150 gr Hybrid Hunter](https://www.sigsauer.com/277-sig-fury-150-hybrid-hunter.html) (2026-10-13)
- [277 SIG Fury 155 gr Hybrid Match](https://www.sigsauer.com/277-sig-fury-hybrid-match.html) (2026-10-13)

**SkyPellets** — 2026-10-13: robots.txt read (nothing disallowed). Read 45-dome-light and all 8 Flat/Point pages: Flat 'Yassı saçma kurşunlar' -> flat_nose, Point 'Sivri uçlu saçma kurşunlar' -> pointed; Dome from name. Material ('yüksek kaliteli malzemeler') and base not stated.

- [4,5 Flat Light](https://skypellets.com/tr/45-flat-light) (2026-10-13)
- [4,5 Flat Heavy](https://skypellets.com/tr/45-flat-heavy) (2026-10-13)
- [5,5 Flat Light](https://skypellets.com/tr/55-flat-light) (2026-10-13)
- [5,5 Flat Heavy](https://skypellets.com/tr/55-flat-heavy) (2026-10-13)
- [4,5 Point Light](https://skypellets.com/tr/45-point-light) (2026-10-13)
- [4,5 Point Heavy](https://skypellets.com/tr/45-point-heavy) (2026-10-13)
- [5,5 Point Light](https://skypellets.com/tr/55-point-light) (2026-10-13)
- [5,5 Point Heavy](https://skypellets.com/tr/55-point-heavy) (2026-10-13)

**Speer** — Read 2026-10-13: speer.com robots.txt (product/category pages allowed); line listing pages (Bullet Style per product) and product pages for Boat-Tail, Gold Dot (2 pages, bonded), Grand Slam, Hot-Cor (all 29 styles from listing pages 1-2, construction text on 2211/2223), Target Match (both), TNT, TNT Green, Varmint SP (all 6 say Spitzer tip), Varmint HP, JHP, SP Flat Nose. Not stated: base of Gold Dot/Grand Slam/Hot-Cor/TNT/Varmint/TMJ; construction of Boat-Tail, Grand Slam, TNT, Varmint lines; nose shape of Boat-Tail/Grand Slam/Gold Dot (only 'Soft Point'). .257 100 gr Varmint Hollow Point (1407) is listed by Speer as 'Jacketed Soft Point' - conflicts with name, tip cleared.

- [Speer Boat-Tail rifle bullets](https://www.speer.com/bullets/rifle-bullets/boat-tail-rifle-bullet/) (2026-10-13)
- [Speer Gold Dot rifle component bullets](https://www.speer.com/bullets/rifle-bullets/gold-dot-rifle-component-bullet/) (2026-10-13)
- [Gold Dot Rifle .308 168 gr](https://www.speer.com/bullets/rifle-bullets/gold-dot-rifle-component-bullet/19-308168GDB.html) (2026-10-13)
- [Speer Grand Slam rifle bullets](https://www.speer.com/bullets/rifle-bullets/grand-slam-rifle-bullet/) (2026-10-13)
- [Speer Hot-Cor rifle bullets (1-18)](https://www.speer.com/bullets/rifle-bullets/hot-cor-rifle-bullet/?start=0&sz=18) (2026-10-13)
- [Speer Hot-Cor rifle bullets (19-29)](https://www.speer.com/bullets/rifle-bullets/hot-cor-rifle-bullet/?start=18&sz=18) (2026-10-13)
- [Hot-Cor .308 200 gr](https://www.speer.com/bullets/rifle-bullets/hot-cor-rifle-bullet/19-2211.html) (2026-10-13)
- [Target Match .308 168 gr](https://www.speer.com/bullets/rifle-bullets/target-match-rifle-bullet/19-2040.html) (2026-10-13)
- [Target Match .224 52 gr](https://www.speer.com/bullets/rifle-bullets/target-match-rifle-bullet/19-1036.html) (2026-10-13)
- [TNT .284 110 gr](https://www.speer.com/bullets/rifle-bullets/tnt-bullet/19-1616.html) (2026-10-13)
- [Speer TNT bullets](https://www.speer.com/bullets/rifle-bullets/tnt-bullet/) (2026-10-13)
- [TNT Green .224 30 gr](https://www.speer.com/bullets/rifle-bullets/tnt-green-bullet/19-1021.html) (2026-10-13)
- [Varmint Soft Point .224 70 gr (same text on 1047/1024/1029/1017/1023)](https://www.speer.com/bullets/rifle-bullets/varmint-soft-point-bullet/19-1053.html) (2026-10-13)
- [Speer Varmint Hollow Point bullets](https://www.speer.com/bullets/rifle-bullets/varmint-hollow-point-bullet/) (2026-10-13)

**Spoton** — no page read; only product-name words. Note: 2026-10-13: robots.txt read (only /wp-admin/ disallowed). Read spoton.com.tr pages Match, Falcon, Mercur, Crow, Hunter, Upper Cut, Solid, Excel: only generic boilerplate ('genellikle kurşun veya alaşımlı' = usually lead or alloy, hedged, not product-specific); no head shape or base stated. Nothing filled beyond name words; remaining pages (same template) not read.

**Swift** — Read swiftbullets.com (robots.txt checked) home page and the A-Frame, Zephyr, Scirocco collection pages and sample product pages. Product pages give only profile codes (BTS, AF/SS) without explanation, so base and nose shape stay empty except name words (RN/FN/HP). Scirocco II tip = 'Signature Black Tip' (maker does not say polymer; mapped to polymer_tip as the only tipped value); Scirocco construction and all bases not stated.

- [Swift Bullet Company home page](https://swiftbullets.com/) (2026-10-13)
- [A-Frame rifle bullets collection](https://swiftbullets.com/collections/a-frame-rifle-bullets) (2026-10-13)
- [Zephyr long range hunting bullets collection](https://swiftbullets.com/collections/zephyr-long-range-hunting-bullets) (2026-10-13)
- [Scirocco rifle bullets collection](https://swiftbullets.com/collections/scirocco-rifle-bullets) (2026-10-13)

**SWISS P** — no page read; only product-name words. Note: swiss-p.com: robots.txt fetch failed (client error) twice; www.swiss-p.com returned ROBOTS_DISALLOWED. Nothing read from the maker site; all fields stay empty (name_words only).

**Warner** — Read 2026-10-13 from warner-tool.com (robots.txt allows /product and /flat-line-bullets). Flat Line line page and product pages: CNC-turned monolithic copper solids. Nose/tip and base (boat tail/flat) not stated on line page, .416 550gr or .30 155.5gr PALMA pages; PALMA/FTR variants not explained.

- [WTC Flat Line Bullets](https://www.warner-tool.com/flat-line-bullets/) (2026-10-13)
- [.416 550gr Flat Line Bullet](https://www.warner-tool.com/product/416-550gr-flat-line/) (2026-10-13)
- [.30 155.5gr Flat Line Palma](https://www.warner-tool.com/product/30-155gr-flat-line-palma/) (2026-10-13)

**Weatherby** — Weatherby store pages (cartridge pages repeat the same per-bullet text), ballistics chart page and 2021 chart PDF read; component lines from Hornady, Barnes, Nosler, Swift, Hammer, Berger own pages. Not stated anywhere (left empty): Scirocco tip material ('signature black tips'), Partition/Elite Hunter/VLD tip, InterBond fields, DGS construction, most bases (TTSX/TSX/InterLock/Hammer/Scirocco/A-Frame). Barnes family pages list BT and FB variants, so no line-wide base. First WebFetch attempts on weatherby.com timed out on permission, a retry worked.

- [Weatherby ballistics charts](https://weatherby.com/ammunition-org/ballistics-charts/) (2026-10-13)
- [Weatherby ballistic chart PDF (legend)](https://weatherby.com/wp-content/uploads/2019/09/BALLISTIC-CHART-4-5-21-MSv2.pdf) (2026-10-13)
- [Weatherby 25 RPM ammunition](https://weatherby.com/store/25-weatherby-rpm/) (2026-10-13)
- [Weatherby 7mm Wby Mag ammunition](https://weatherby.com/store/7mm-weatherby-magnum/) (2026-10-13)
- [Weatherby 300 Wby Mag ammunition](https://weatherby.com/store/300-weatherby-magnum/) (2026-10-13)
- [Weatherby 6.5-300 Wby Mag ammunition](https://weatherby.com/store/6-5-300-weatherby-magnum/) (2026-10-13)
- [Weatherby 257 Wby Mag ammunition](https://weatherby.com/store/257-weatherby-magnum/) (2026-10-13)
- [Weatherby 280 Ackley Improved ammunition](https://weatherby.com/store/280-ackley-improved/) (2026-10-13)
- [Nosler AccuBond line](https://www.nosler.com/products/bullets/product-line/accubond.html) (2026-10-13)
- [Nosler Ballistic Tip Hunting line](https://www.nosler.com/products/bullets/product-line/ballistic-tipr-hunting.html) (2026-10-13)
- [Swift Bullet Company](https://www.swiftbullets.com/) (2026-10-13)
- [Hammer Bullets](https://hammerbullets.com/) (2026-10-13)
- [Berger 25 cal 133 gr Elite Hunter](https://bergerbullets.com/product/25-caliber-133-grain-elite-hunter/) (2026-10-13)
- [Berger 6.5 mm 156 gr Elite Hunter](https://bergerbullets.com/product/6-5-mm-156-grain-elite-hunter/) (2026-10-13)
- [Berger 7 mm 168 gr Classic Hunter](https://bergerbullets.com/product/7-mm-168-grain-classic-hunter/) (2026-10-13)
- [Berger 7 mm 180 gr VLD Hunting](https://bergerbullets.com/product/7-mm-180-grain-very-low-drag-vld-hunting/) (2026-10-13)
- [Hornady ELD-X bullets](https://www.hornady.com/bullets/eld-x) (2026-10-13)
- [Hornady ELD Match bullets](https://www.hornady.com/bullets/eld-match) (2026-10-13)
- [Hornady CX bullets](https://www.hornady.com/bullets/cx) (2026-10-13)
- [Hornady SST bullets](https://www.hornady.com/bullets/sst-(super-shock-tip)) (2026-10-13)
- [Hornady DGX Bonded bullets](https://www.hornady.com/bullets/dgx-bonded) (2026-10-13)
- [Hornady DGS bullets](https://www.hornady.com/bullets/dgs-dangerous-game-solid) (2026-10-13)
- [Hornady V-MAX bullets](https://www.hornady.com/bullets/v-max) (2026-10-13)
- [Hornady Match bullets](https://www.hornady.com/bullets/match) (2026-10-13)
- [Barnes 30 cal TTSX BT](https://barnesbullets.com/0-308-30-cal-ttsx-bt/) (2026-10-13)
- [Barnes 30 cal TSX BT](https://barnesbullets.com/0-308-30-cal-tsx-bt/) (2026-10-13)
- [Barnes 300 BLK TAC-TX 110 gr FB](https://barnesbullets.com/0-308-300-acc-blk-tac-tx-110-gr-fb/) (2026-10-13)
- [Barnes 22 cal Varmint Grenade FB](https://barnesbullets.com/0-224-22-cal-varmint-grenade-fb/) (2026-10-13)
- [Barnes 22 cal MPG 55 gr FB](https://barnesbullets.com/0-224-22-cal-mpg-55-gr-fb/) (2026-10-13)

**Winchester** — winchester.com line/product pages read 2026-10-13 (robots ok; WebFetch PROVENANCE_REQUIRED on first 3 tries, succeeded on 4th). Nosler AccuBond LR page for base. Power-Point line/product pages state no construction/tip/base (only 350 Legend page: notching + lead core). Not stated: base for DSXP, Power Max Bonded, Expedition, Varmint X, Defender; Super-X, USA, Super Suppressed and most rimfire construction; AccuBond CT base; Match tip left to name words.

- [Ballistic Silvertip line](https://winchester.com/Products/Ammunition/Rifle/Ballistic-Silvertip) (2026-10-13)
- [Deer Season XP line](https://winchester.com/Products/Ammunition/Rifle/Deer-Season-XP) (2026-10-13)
- [Copper Impact line](https://winchester.com/Products/Ammunition/Rifle/Copper-Impact) (2026-10-13)
- [Expedition Big Game line](https://winchester.com/Products/Ammunition/Rifle/Expedition-Big-Game) (2026-10-13)
- [Match line](https://winchester.com/Products/Ammunition/Rifle/Match) (2026-10-13)
- [Varmint X line](https://winchester.com/Products/Ammunition/Rifle/Varmint-X) (2026-10-13)
- [Varmint X Lead Free 22-250](https://winchester.com/Products/Ammunition/Rifle/Varmint-X-Lead-Free/X22250PLF) (2026-10-13)
- [Varmint X Lead Free 17 WSM](https://winchester.com/Products/Ammunition/Rimfire/Varmint-X-Lead-Free/X17W15PLF) (2026-10-13)
- [Power Max Bonded line](https://winchester.com/Products/Ammunition/Rifle/Power-Max-Bonded) (2026-10-13)
- [Defender 223 Rem Split Core](https://winchester.com/Products/Ammunition/Rifle/Defender/S223RPDB) (2026-10-13)
- [Varmint HV 22 WMR V-MAX](https://winchester.com/Products/Ammunition/Rimfire/Varmint-HV/S22M2PT) (2026-10-13)
- [Varmint LF 22 LR Tin HP](https://winchester.com/Products/Ammunition/Rimfire/Varmint-LF/X22LRHLF) (2026-10-13)
- [350 Legend cartridge page](https://winchester.com/350-Legend.) (2026-10-13)
- [Nosler AccuBond Long Range 6.5mm 142 gr](https://www.nosler.com/6-5mm-142gr-accubond-long-range-100ct.html) (2026-10-13)

**Woodleigh** — Read 2026-10-13 from woodleighbullets.com.au (Joomla robots.txt, /products and /images/downloads allowed). Weldcore = lead fused to gilding-metal jacket -> bonded. FMJ = steel-jacketed solids -> fmj. Nose from 2020 catalogue key: RN SN round nose, FN SN flat nose, PP SN 'small flat nose' -> flat_nose. FMJ nose shape and all bases (flat/boat tail) not stated; FMJ base only 'rolled back 90 degrees'. 'Heavy Duty' not defined. Bullet-list pages give no construction text.

- [Weldcore Soft Nose](https://www.woodleighbullets.com.au/products/weldcore-soft-nose) (2026-10-13)
- [Full Metal Jacket](https://www.woodleighbullets.com.au/products/full-metal-jacket) (2026-10-13)
- [Protected Point](https://www.woodleighbullets.com.au/products/protected-point) (2026-10-13)
- [Woodleigh Catalogue 2020](https://www.woodleighbullets.com.au/images/downloads/woodleigh_bullets_2020_catalogue.pdf) (2026-10-13)

**Zan Projectiles** — 2026-10-13: robots.txt read (/shop/ allowed). All 21 source pages read. Stated: .177 slugs 'deep hollow point' + 'shallow hollow base'; .457 slugs deep hollow point + Boat Tail; ELR Hyper Line 'round nose and boat tail profile'; Lead Free .30 pellets lead-free. Not stated: .20/.22/.25/.30 slugs, Hyper Line (.177/.22/.30/.357, only a 'Hollow point' shop category), ELR ('lead or alternative alloys' = not specific), Fat Boy, BR50/BR100. .25 page lists '44 grain BT' undefined -> not used. ZAN .22 ELR 35.5 gr source URL now shows the 33 gr ELR HP product -> left empty.

- [.177 / 4.5mm slugs](https://zanprojectiles.com/shop/17-4-5mm-slugs/) (2026-10-13)
- [.457 / 11,6mm Slug](https://zanprojectiles.com/shop/457-126mm-slug/) (2026-10-13)
- [ELR Hyper Line Slugs](https://zanprojectiles.com/shop/217-caliber-407-grain-elr-hyper-line-slugs/) (2026-10-13)
- [Lead Free .30 Pellets](https://zanprojectiles.com/shop/lead-free-30-pellets/) (2026-10-13)
