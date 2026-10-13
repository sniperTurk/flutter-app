# Tahmini BC'nin hatası nasıl düşürülür?

Tarih: 2026-10-13 · Zamanlanmış görev (sahibi çevrimdışı) · Dal: `research/tahmini-bc-hata`

Kapsam: yalnızca araştırma ve prototip analiz. `lib/` ve `test/` değişmedi. Analiz betikleri
`tools/research/` altında, tam çıktıları `docs/research/tahmini_bc_hata_cikti.txt` içinde.

---

## Türkçe özet (mühendis olmayan okuyucu için)

### Kısa cevap

1. **Tek bir ortalama sayı yerine merminin "ailesine" bakmak hatayı yarıya indiriyor (ateşli
   silah).** Ürün adındaki kelimeler (ELD, VLD, A-Tip, Match, BTHP → uzun menzil; SP, RN, FN, FMJ →
   küt burun) mermi biçimini büyük ölçüde ele veriyor. Bu kuralla ateşli silah mermisinde tipik hata
   **%17'den %8'e**, en kötü onda birlik dilim **%79'dan %28'e** iniyor. Hiç bilinmeyen yeni bir
   marka gibi sınandı (her markayı tek tek dışarıda bırakarak). Kullanıcıdan hiçbir şey istemez.
2. **PCP slug'da formülle iyileştirme sınırlı.** Markalar BC'yi farklı yöntemlerle yayımladığı
   için, bir markadan öğrenilen kural başka markaya taşınmıyor. "ELR" kelimesi (uzun menzil,
   arkası daralan slug) ve uzunluk biliniyorsa uzunluk/çap oranı hatayı **%14'ten %11'e**
   indiriyor; en kötü dilim %28 → %23. Bu küçük bir kazanç; 500 m'de hâlâ ~1 m hata demek.
3. **Diabolo saçmada** aile kuralı (kubbe, sivri, oyuk/geniş, kurşunsuz) hatayı **%20'den %17'ye**
   indiriyor, ama elimizde yalnızca H&N verisi var. Yeni bir markada bu sayı doğrulanamıyor.
4. **Daha karmaşık yöntemler (en yakın komşu, makine öğrenmesi, regresyon) yeni markalarda basit
   aile tablosundan iyi değil.** Aynı markanın içinde iyi görünüyorlar, ama bu ezber; yeni markada
   kazanç kayboluyor. Basit tablo hem daha anlaşılır hem daha güvenilir.
5. **Bilimsel geometri yöntemleri (BRL McDRAG, PRODAS vb.)** burun boyu, ogive yarıçapı, uç
   düzlüğü, arka daralma gibi ölçüler istiyor. Üreticiler bunları yayımlamıyor. Tam ölçüyle bile
   ses altında ±%6, ses hızına yakın bölgede ±%11 hata veriyorlar (slug tam bu bölgede uçuyor).
   **Uygulamaya uygun değil.**
6. **Asıl büyük kazanç atışla doğrulamada.** Formül ne kadar iyi olursa olsun, üreticinin kendi
   yayımladığı BC'ler bile ölçümden **%5–25** sapabiliyor (ABD Hava Kuvvetleri Akademisi
   ölçümleri). %5'in altına yalnızca ölçüm iner:
   - **Kronografla iki hız** (namlu ağzında ve 50/100 m'de, 10'ar atış, mesafe şeritmetreyle):
     BC belirsizliği ateşli silahta ~**%2**, slug'da ~**%2–3**. 30–45 dakikalık iş.
   - **Uzak mesafede düşüş** (grubun ortası): ateşli silahta 500 m'de ~**%6**, slug'da 300 m'de
     ~**%5**. Ateşli silahta 300 m ve altı BC'yi ölçmeye yetmiyor (sıfır hatası baskın).
   - **Slug için önemli uyarı:** yakın mesafede (50 m) ölçülen BC, slug'ın gerçek sürüklenme
     eğrisi G1'den farklıysa 500 m'de **0,5–2 m** yanıltabilir. Slug'da 300 m üstüne çıkılacaksa
     **mutlaka o mesafelerde atışla doğrulama** gerekir.
7. **Uygulamadaki mevcut BC doğrulama sınırı (±%30) tahmini BC için dar.** Bugünkü tek-sayı
   tahmininde ateşli silah mermilerinin **%30'unda**, aile tablosuyla %8'inde gerçek BC bu sınırın
   dışında; kullanıcı doğru atış verse bile doğrulama reddedilir.

### Yöntem karşılaştırması (sade tablo)

Hata = |tahmini BC / üreticinin BC'si − 1|. "Tipik" = ortanca; "4'te 3" = %75'lik dilim;
"10'da 9" = %90'lık dilim. Ateşli silah ve slug sayıları **"yeni marka" sınamasıdır** (her marka
sırayla dışarıda). Saçmada tek marka olduğu için 10 katlı çapraz doğrulama.

| Tür | Yöntem | Tipik | 4'te 3 | 10'da 9 | 300 m düşüş hatası (tipik / 10'da 9) | 500 m (tipik / 10'da 9) |
|---|---|---:|---:|---:|---:|---:|
| Ateşli (.277 130 gr, 3000 fps) | Bugünkü tek sayı (i = 0,582) | %17 | %35 | %79 | 2,1 / 4,7 cm | 13 / 28 cm |
| Ateşli | **Aile × kesit yoğunluğu tablosu** | **%8** | **%16** | **%28** | **0,9 / 2,8 cm** | **6 / 18 cm** |
| Ateşli | İki hız (kronograf, 100 m) | ~%1,2 | ~%2 | ~%3 | 0,1 / 0,3 cm | 0,8 / 2 cm |
| Ateşli | 500 m'de düşüşle doğrulama | ~%4 | ~%7 | ~%10 | 0,4 / 1,1 cm | 3 / 7 cm |
| PCP slug (6,35 mm 50 gr, 985 fps) | Bugünkü tek sayı (i = 0,825) | %14 | %21 | %28 | 20 / 38 cm | 119 / 230 cm |
| PCP slug | **"ELR" + uzunluk/çap** | **%11** | **%19** | **%23** | **16 / 34 cm** | **92 / 208 cm** |
| PCP slug | İki hız (kronograf, 50 m) | ~%2 | ~%4 | ~%5 | 3,5 / 9 cm (+ eğri hatası 14–23 cm) | 20 / 50 cm (+ eğri hatası 1,4–2,2 m) |
| PCP slug | 300 m'de düşüşle doğrulama | ~%3 | ~%5 | ~%7,5 | 4 / 10 cm | 24 / 60 cm (+ eğri hatası 0,5–0,8 m) |
| PCP saçma (H&N) | Bugünkü tek sayı (i = 2,06) | %20 | %30 | %46 | — | — |
| PCP saçma (H&N) | **Aile (kubbe/sivri/oyuk/kurşunsuz)** | **%17** | **%23** | **%34** | — | — |

100 m sıfırda 100 m'deki düşüş farkı tanım gereği 0'dır. Saçma için örnek atış verilmedi (saçmalar
genelde 100 m altında kullanılır). Doğrulama satırlarındaki yüzdeler ölçüm belirsizliğidir
(§B.2–B.3'teki 1 standart sapmadan; tipik = 0,67σ, 4'te 3 = 1,15σ, 10'da 9 = 1,64σ). "Eğri hatası": slug'ın gerçek sürüklenme eğrisi G1 yerine G7 ya
da sabit Cd gibi davransaydı kalacak hata (§B.3.4); ölçülmüş değil, olası sınır.

### Öneri (kullanıcı emeği başına kazanca göre sıralı)

| Sıra | Ne | Kullanıcı emeği | Kazanç |
|---:|---|---|---|
| 1 | Tahmini BC'yi ürün adındaki kelimelerle **aileye göre** seç (ateşli: 5 aile × 6 kesit yoğunluğu bandı; slug: "ELR" + uzunluk/çap; saçma: 4 aile). Tablolar §A.5'te hazır. | Yok | Ateşli: tipik %17 → %8, 10'da 9 %79 → %28. Slug: %14 → %11. Saçma: %20 → %17 |
| 2 | Tahmini BC'nin yanında **belirsizliği** göster ve 150 m (slug) / 300 m (ateşli) üstünde doğrulama iste. | Yok | Kullanıcı yanılmaz; hata kaybolmaz ama görünür olur |
| 3 | Tahmini BC için doğrulama sınırını **±%30'dan ±%60'a** genişlet (yalnız BC "tahmini" iken). | Yok | Bugün ateşli tahminlerin %30'u, slug'ların %6'sı doğrulanamıyor |
| 4 | **"İki hızdan BC"** aracı: kronograf namlu ağzında 10 atış, sonra 50 m (slug) / 100 m (ateşli) 10 atış, mesafe şeritmetreyle. | 30–45 dk | BC belirsizliği %2–3; slug'da 200 m'ye, ateşlide 500 m'ye kadar yeterli |
| 5 | **Uzak mesafe düşüşüyle doğrulama** (mevcut "BC doğrulama"): slug 300 m, ateşli 500 m, 10 atışlık grubun merkezi, mesafe telemetreyle. | 1 atış seansı | Slug'da 300 m üstü için **zorunlu**; BC belirsizliği %5–6 |
| 6 | Slug için çok mesafeli doğrulamaya **ses altı bantlar** ekle (bugünkü bantlar Mach 1,2 altını tek bant sayıyor; PCP'de tüm uçuş bu bantta). | 3 mesafe | Eğri hatasını (0,5–2 m @ 500 m) giderir; ayrı geliştirme gerekir |
| — | Geometri tabanlı tahmin (McDRAG/PRODAS), makine öğrenmesi | — | **Önerilmez:** veri yok / yeni markada kazanç yok |

### Uygulamanın göstereceği Türkçe metinler (öneri)

Rozet (BC kutusunun yanında; yüzde = "4'te 3" sınırı, yukarı yuvarlanmış):

- Ateşli, aile tablosu: **"Tahmini BC (±%16) — 300 m üstünde atışla doğrulayın"**
- Slug: **"Tahmini BC (±%20) — 150 m üstünde atışla doğrulayın"**
- Saçma: **"Tahmini BC (±%25) — 50 m üstünde atışla doğrulayın"**
- Aile tablosu uygulanana kadar (bugünkü tek sayı): ateşli **"Tahmini BC (±%35) — 300 m üstünde atışla doğrulayın"**, slug **"Tahmini BC (±%21) — 150 m üstünde atışla doğrulayın"**

Uyarı kutusu (`ballistics-bc-estimated` metninin yerine; sayılar örnek 50 gr .25 slug için,
uygulamada BC'den ve atış mesafesinden hesaplanır):

> BC girilmediği için tahmini G1 BC 0,140 kullanılıyor (ağırlık, kalibre ve mermi türünden).
> 4 üründen 3'ünde gerçek BC bu değerin ±%20'si içinde. 300 m'de bu, 25–35 cm düşüş farkı
> demek. Kronografla iki hız ölçün ya da uzak mesafede atışla doğrulayın.

ⓘ açıklaması (BC alanı; kısa, Türkçe, ne/nerede/örnek):

> Tahmini BC: Üretici BC yayımlamadığında ağırlık, kalibre ve ürün adındaki tür (ör. ELR, HP,
> kubbe) ile hesaplanır. Gerçek değer ±%20 sapabilir. Doğrulamak için: Araçlar › Doğrulama.
> Örnek: 50 gr .25 slug → 0,140.

"İki hızdan BC" aracı yönergesi:

> 1. Kronografı namlu ağzından 3–5 m öne koyun, 10 atış yapın.
> 2. Aynı kronografı 50 m'ye (slug) ya da 100 m'ye (tüfek) taşıyın. Mesafeyi şeritmetreyle ölçün.
> 3. Aynı ayarla 10 atış daha yapın. İki ortalamayı girin.
> Kronografı korumak için hedefi hemen arkasına koyun ve sensörlerin üstünden nişan alın.

Doğrulama reddi (sınır dışı) için:

> Gözlem, tahmini BC'den %30'dan fazla farklı. Tahmini BC'de bu olağan; ama önce namlu hızını ve
> sıfırı kontrol edin. Yine de uyuşmuyorsa iki hızdan BC ölçün.

---

## English details

### A. Better estimators from the repository's own data

#### A.1 Data and validation design

- Training/target data: manufacturer-published G1 BCs in `lib/data/bullet_library.dart`
  (parsed by `tools/research/bc_data.py`): firearm n = 1545 (16 brands), PCP slug n = 209
  (H&N 35, NSA 113, Zan 61), PCP pellet n = 45 (H&N 44, Zan 1). Length is known for 665 firearm
  bullets and 149 slugs, 1 pellet. `catalog_repository.dart` has no BCs (names/weights only), so it
  cannot be used to train or test.
- External check (firearm only): 654 distinct factory-ammo G1 BCs from
  `lib/data/factory_ammo_library.dart` whose (diameter, weight, BC) does not occur in the bullet
  library (rows marked `bcFromBullet` or NATO-standard excluded). Models are trained on the bullet
  library and scored on these.
- Every estimator predicts the G1 form factor `i = SD / BC`, `SD = m_gr / (7000 d_in²)` (McCoy
  [S1]), so `BC_est = SD / i_est`. Error = `|BC_est / BC_pub − 1|`; percentiles use linear
  interpolation (the owner's pellet p90 of 39 % vs. our 45.3 % in-sample is a percentile
  convention difference on n = 45).
- **k-fold:** 10 folds × 5 shuffles, folds grouped by (brand, diameter, weight) so twist and
  diameter variants of one bullet are never on both sides of a split.
- **LOBO (leave-one-brand-out):** the whole brand is unseen. This is the honest number for the
  app's use case: the BC-less records in the library are mostly brands with no published BC at
  all (RWS 44, Hatsan 48, Gamo 32, Spoton 30, Crosman 17, Diana 14, SkyPellets 12, Air Arms 11,
  My Bullet 7 …).
- Families come from words in the product name (`FIREARM_FAMILIES`, `SLUG_FAMILIES`,
  `PELLET_FAMILIES` in `bc_estimator_cv.py`), grouped by McCoy's drag shape classes [S1]:
  `vld_match` (VLD/hybrid/ELD Match/A-Tip/Scenar/Elite Hunter/SMK/TMK/OTM/HPBT/Match/Target/LRX/
  ELR …), `tipped_bt` (ELD-X/AccuBond/Ballistic Tip/SST/TTSX/V-Max/CX …), `bt` (BT/Boat-Tail/
  GameKing/FMJBT …), `fb_spitzer` (the rest: SP/InterLock/Partition/A-Frame/FB …) and `blunt`
  (RN/FN/FTX/revolver/subsonic/solid/FMJ non-BT …).
- **Honesty caveat:** the keyword lists were written after reading the product names, and revised
  once after looking at the worst LOBO cases (Berger "ELR Match Solid", Barnes "Banded Solid BT
  Bore Rider" and Cutting Edge "Lazer" were classed as blunt; Woodleigh "FMJ" round-nose solids
  as spitzers). That revision improved LOBO (median 8.7 → 8.4 %, p90 32 → 28 %) but slightly
  worsened the untouched factory-ammo check (median 13.4 → 14.1 %, p90 43 → 45 %). Expect real
  new-brand performance between the LOBO and the factory-ammo numbers.
- **The target itself is noisy.** Published BCs differ from free-flight measurements by −10.5 %
  to +44.8 % (USAF Academy two-chronograph tests of 27 bullet/rifle pairs, most overstated by
  5–25 % [S6]; Courtney & Courtney found most overstated by 5–25 % [S5]). No estimator trained on
  published BCs can be more accurate than the published BCs are.

#### A.2 Firearm bullets (n = 1545)

| Method | k-fold med / p75 / p90 | LOBO med / p75 / p90 | Factory-ammo external med / p75 / p90 |
|---|---|---|---|
| M0 global median i = 0.582 (current) | 16.4 / 34.6 / 79.1 % | 17.4 / 35.3 / 79.1 % | 19.5 / 46.5 / 74.6 % |
| M1 family median i | 8.4 / 16.7 / 30.3 % | 9.0 / 16.9 / 31.2 % | 15.1 / 27.1 / 49.0 % |
| M2 calibre × SD band | 11.4 / 22.9 / 45.2 % | 12.0 / 24.2 / 47.9 % | — |
| **M1+2 family × SD band** | **7.8 / 14.8 / 27.3 %** | **8.4 / 15.9 / 28.3 %** | **14.1 / 25.4 / 45.4 %** |
| M3 L/d regression (L known; else M0) | 13.9 / 26.7 / 65.4 % | 14.7 / 27.6 / 66.7 % | — |
| M4 brand median (k-fold only) | 13.0 / 24.4 / 67.5 % | n/a | — |
| M4b brand × family (k-fold only) | 7.9 / 15.8 / 27.0 % | n/a | — |
| M5 k-NN (k = 7; d, SD, family, L/d) | 5.6 / 11.7 / 20.6 % | 10.0 / 17.7 / 32.3 % | 18.0 / 39.7 / 66.6 % |
| M6 ridge on ln i (d, SD, family, flags, L/d) | 8.6 / 15.9 / 25.3 % | 11.5 / 19.6 / 30.3 % | 14.7 / 28.2 / 49.0 % |
| M6b ridge + brand (k-fold only) | 8.7 / 15.4 / 23.6 % | n/a | — |
| M7 gradient-boosted trees | 6.3 / 12.0 / 19.3 % | 9.6 / 18.4 / 30.8 % | — |

Length-known subset (n = 665), LOBO: M0 18.7 / 36.1 / 75.2 %; M1 9.3 / 16.8 / 31.7 %; M3 (L/d
only) 11.7 / 20.0 / 37.4 %; ridge without L/d 11.2 / 20.4 / 37.3 %; ridge with L/d
9.5 / 18.3 / 30.3 %. **Length adds little once the family is known** (it mostly re-encodes the
family), so it does not justify asking the user for a length.

Findings: (1) the family keyword carries almost all of the gain; (2) brand adds nothing beyond
family; (3) k-NN and boosted trees look best in k-fold because sibling products of the same line
sit in both folds, and lose that edge on an unseen brand and on the factory set; (4) the remaining
tail is dominated by products whose name does not reveal the shape (Hornady ECX, Lapua Naturalis,
wadcutters, bonded tips at big calibres) and by brands whose published BCs are systematically
different (LOBO median by brand: Warner 44 %, Speer 15 %, Barnes 11 %, Hornady 8 %, Berger 3.6 %).

#### A.3 PCP slugs (n = 209)

| Method | k-fold med / p75 / p90 | LOBO med / p75 / p90 (bias) |
|---|---|---|
| M0 global median i = 0.825 (current) | 12.8 / 18.0 / 23.3 % | 13.9 / 20.7 / 27.9 % (+2.9 %) |
| M1 family (ELR/heavy/HP-DB/HP-FB/plain) | 10.5 / 18.6 / 24.1 % | 14.1 / 22.8 / 28.9 % (+7.7 %) |
| M2 calibre × SD band | 4.8 / 12.7 / 24.6 % | 13.6 / 23.0 / 37.0 % |
| M3 L/d regression (L known; else M0) | 9.3 / 14.1 / 21.3 % | 12.0 / 20.3 / 25.9 % |
| M5 k-NN | 5.1 / 9.6 / 17.8 % | 17.4 / 26.6 / 34.4 % (+11.1 %) |
| M6 ridge | 7.9 / 12.5 / 19.6 % | 25.2 / 34.8 / 59.6 % |
| M7 boosted trees | 3.5 / 7.7 / 17.0 % | 15.7 / 28.1 / 40.5 % |
| S1 "ELR" keyword vs. rest | 11.6 / 17.3 / 20.6 % | 14.0 / 20.1 / 26.1 % |
| **S2 "ELR" keyword, else L/d regression** | **9.1 / 13.0 / 18.3 %** | **10.9 / 19.2 / 22.9 %** (+1.9 %) |

Findings: (1) the three brands differ systematically (median i: H&N 0.769, NSA 0.879, Zan 0.783),
so anything learnt inside a brand fails on another brand — flexible models (k-NN, ridge, trees)
are worse than the current single number under LOBO; (2) the only robust signals are the "ELR"
keyword (Zan ELR boat-tail slugs, i ≈ 0.47; the current single number under-estimates their BC by
30–51 %) and L/d; (3) the fitted L/d relation is `ln i = −0.379 + 0.524 ln(L/d)` (n = 147,
L/d 1.07–2.41): *longer slugs get a worse form factor*. That is the opposite of rifle-bullet
physics and is best read as how these makers publish BCs (velocity/method not stated, see
`docs/research/pellet_slug_hassas_hesap.md` B.3), not as aerodynamics. The ELR rule rests on 9
Zan products only and could not be validated on another brand.

#### A.4 PCP pellets (n = 45, k-fold only)

| Method | k-fold med / p75 / p90 |
|---|---|
| M0 global median i = 2.06 (current) | 19.7 / 29.7 / 45.8 % |
| **M1 family (dome 1.90 / pointed 2.80 / wide-HP 2.46 / lead-free 1.57)** | **16.6 / 23.2 / 34.3 %** |
| M1+2 family × SD band | 16.7 / 22.0 / 36.4 % |
| M5 k-NN | 17.4 / 26.6 / 39.8 % |
| M6 ridge | 16.7 / 25.4 / 37.6 % |
| M7 boosted trees | 16.2 / 26.0 / 38.9 % |

With one brand (H&N, BC model and velocity unstated by the maker) nothing can be said about a new
brand; the family medians are physically plausible (pointed and wadcutter/hollow heads have more
drag; Ladommatos measured Cd 0.42 domed vs. 0.56–0.71 flat/conical/hollow at Mach 0.58 [S10]),
which is the only argument for using them elsewhere.

#### A.5 Ready tables (fitted on all rows; for a later implementation)

Firearm `i` by family × SD band (SD band edges 0.18 / 0.22 / 0.26 / 0.30 / 0.34 lb/in²; a cell
with < 3 rows falls back to the family median):

| Family (median i) | SD < 0.18 | 0.18–0.22 | 0.22–0.26 | 0.26–0.30 | 0.30–0.34 | ≥ 0.34 |
|---|---:|---:|---:|---:|---:|---:|
| vld_match (0.494) | 0.630 | 0.540 | 0.500 | 0.491 | 0.472 | 0.447 |
| tipped_bt (0.540) | 0.570 | 0.545 | 0.538 | 0.533 | 0.499 | 0.521 |
| bt (0.607) | 0.601 | 0.611 | 0.606 | 0.600 | 0.580 | (0.607) |
| fb_spitzer (0.678) | 0.723 | 0.655 | 0.654 | 0.664 | 0.763 | 0.787 |
| blunt (1.046) | 0.981 | 1.042 | 0.983 | 0.980 | 1.088 | 1.099 |

Slug: "ELR" in the name → i = 0.468; else if length known → `i = exp(−0.379) · (L/d)^0.524`
(clamp L/d to 1.07–2.41); else i = 0.846 (median of non-ELR rows). Pellet: pointed 2.80, wide
hollow/wadcutter 2.46, lead-free 1.57, dome/other 1.90. Keyword lists: `tools/research/bc_estimator_cv.py`.

#### A.6 Drop error that these BC errors cause

Signed LOBO errors of every held-out projectile applied to the example loads (100 m zero, ICAO,
point-mass G1, repository reference solver `tools/formula_reference.py`;
`tools/research/bc_drop_distribution.py`). Loads: .277 130 gr G1 0.44 (median of the 29 .277
125–135 gr bullets in the library), 3000 fps, 45 mm sight height; 6.35 mm 50 gr slug G1 0.140
(= SD 0.1143 / 0.825), 985 fps, 50 mm sight height.

| Load | Method | 200 m med / p75 / p90 | 300 m | 500 m |
|---|---|---|---|---|
| .277 130 gr | M0 (current) | 0.5 / 0.8 / 1.1 cm | 2.1 / 3.6 / 4.7 cm | 13.1 / 22.2 / 28.1 cm |
| .277 130 gr | M1+2 family × SD | 0.2 / 0.4 / 0.6 cm | 0.9 / 1.7 / 2.8 cm | 5.6 / 10.8 / 17.8 cm |
| slug 50 gr | M0 (current) | 4.8 / 6.9 / 9.0 cm | 20.1 / 28.8 / 38.0 cm | 119 / 166 / 230 cm |
| slug 50 gr | S2 ELR + L/d | 3.6 / 5.8 / 8.1 cm | 15.5 / 24.5 / 34.4 cm | 92 / 140 / 208 cm |

At 100 m the difference is 0 by construction (zero range). Symmetric look-up for a given error:
`tools/research/bc_error_drop_cm.py` (e.g. firearm 16 %: 1.4–2.1 cm at 300 m, 8.9–13.6 cm at
500 m; slug 13 %: 16–22 cm at 300 m, 94–130 cm at 500 m — the first value is for an
over-estimated BC, the second for an under-estimated one).

### B. Published semi-empirical methods and shot-based truing

#### B.1 Geometry-based drag prediction

| Method | Inputs | Range / accuracy | Usable with maker data? |
|---|---|---|---|
| BRL **MC DRAG** (McCoy 1981) [S2] | reference diameter; total length; nose length; head-shape parameter R_T/R (cone 0 … tangent ogive 1); boat-tail length; base diameter; meplat diameter; rotating-band diameter; CG position; boundary-layer option (laminar/turbulent) | Mach 0.5–5, 4–400 mm; 1-σ error vs. BRL free-flight data **3 % supersonic, up to 11 % transonic (max near Mach 0.95, worst for boat-tails), 6 % subsonic** | **No.** Makers publish at most total length (665/1545 firearm, 149/209 slugs in the repo); nose length, ogive radius, meplat and boat-tail are not published. Does not model hollow points, diabolo skirts or hollow/dished bases. PCP slugs fly at Mach 0.5–0.9, i.e. in its 6–11 % band even with full geometry. |
| PRODAS, AP98/AP02 (Aeroprediction), Missile DATCOM | Full outer contour; empirical/component build-up databases | ARL: "good predictions only when the design falls within the existing database" [S3]; AP98 under-predicted .50-cal CD0 where CFD was ≈ 5 % high [S4]; FFI: PRODAS drag "significantly smaller" than CFD/radar for 7.62 mm NM258 supersonic [S7]; empirical methods called "the least accurate" of four approaches [S8] | **No.** Commercial/government codes, same contour inputs as MC DRAG; no public accuracy figures for small-arms subsonic drag. A 2024 Brno thesis applied PRODAS V3 to a diabolo pellet and derived its own drag law from measurements [S9] (results not readable from the abstract page). |
| CFD (RANS) | Full CAD geometry | ≈ 5 % vs. range data for .50 cal at Mach 2.7 [S4] | No (needs CAD, hours per case) |
| Airgun pellets: wind tunnel | — | Ladommatos: Cd at Mach 0.58 only, by head shape [S10][S11] | Gives shape *ranking* (used in A.4), not a curve |

Conclusion: none of the geometry methods is usable with what manufacturers publish, and even
with full geometry their subsonic/transonic error (6–11 %) is no better than the family table's
median error. They are not worth implementing.

#### B.2 Truing with two chronograph velocities

Point-mass drag with a G-function (McCoy [S1]): `dv/dx = −ρ π Cd_G(M) v / (8 BC_SI)`,
`BC_SI = 703.0696 · BC[lb/in²]`. With Cd_G taken at the mean Mach of the interval:

```
BC ≈ ρ · π · Cd_G(M̄) · x / (8 · 703.0696 · ln(v0 / vx))
```

Courtney et al. use the equivalent drag-coefficient form `Cd = m (v_i² − v_f²) / (x A v̄² ρ)`
[S12]. For production, solve BC by bisection on the full trajectory (as the solver does for
zeroing); the script does this.

Error budget (one chronograph moved from the muzzle to x; `tools/research/bc_truing_error.py`):

```
σ_BC/BC ≈ √((σ_v0/v0)² + (σ_vx/vx)²) / ln(v0/vx)  ⊕  σ_x/x
```

- Relative velocity errors are amplified by `1/ln(v0/vx)`: ≈ 12× at 8 % velocity loss, ≈ 6× at
  15 %. Courtney: BC error ≈ 10× velocity error; choose a separation giving 5–20 % velocity loss,
  ≈ 10 % being a good compromise; 1 % separation error = 1 % BC error; 10 shots give ≈ 1 % SEM in
  many cases; near/far has about half the uncertainty of near-velocity + time-of-flight [S12].
- **A common chronograph scale error cancels** (same instrument at both stations): a 0.5 % scale
  error changes the fitted BC by only −0.16 % (firearm) / +1.1–1.3 % (slug, because G1 changes
  steeply near Mach 0.85). So the Caldwell's absolute accuracy, which could not be read from a
  manufacturer source (only dealer pages), matters little; its shot-to-shot repeatability does.

Assumptions (stated, not measured): per-shot SD 3 m/s (firearm) / 1.5 m/s (PCP), 10 shots per
station, tape ±0.1 m, rangefinder ±1 m.

| Load | x | Velocity loss | σ_BC (tape) | σ_BC (rangefinder) |
|---|---:|---:|---:|---:|
| .277 130 gr, 3000 fps | 100 m | 8.0 % | 1.8 % | 2.1 % |
| | 200 m | 15.5 % | 0.95 % | 1.1 % |
| | 300 m | 22.7 % | 0.65 % | 0.73 % |
| slug 50 gr, 985 fps | 50 m | 6.9 % | 3.3 % | 3.9 % |
| | 100 m | 12.5 % | 1.8 % | 2.1 % |

Residual drop error from σ_BC: firearm 1.8 % → ≈ 0.2 cm at 300 m, 1.4 cm at 500 m; slug
3.3 % → ≈ 5 cm at 300 m, ≈ 28 cm at 500 m — **plus the drag-shape error of B.3.4 for the slug**.

#### B.3 Truing with drop at long range

Fit BC so the predicted elevation correction at range R equals the observed group centre (the
app's `BallisticCoefficientTruing`, after `MuzzleVelocityTruing`). 1-σ inputs: group centre =
per-shot vertical SD (0.15 mrad firearm, 0.25 mrad PCP) / √10; MV = SEM ⊕ 0.5 % chronograph
scale (here it does *not* cancel); range ±1 m (rangefinder); zero ±0.05 mrad; sight height ±2 mm.

| Load | R | +10 % BC moves | σ_BC | largest term | residual σ at 300 m / 500 m |
|---|---:|---:|---:|---|---|
| .277 130 gr | 200 m | 0.01 mrad | 83 % | zero 77 % | (not usable) |
| | 300 m | 0.03 mrad | 22 % | zero 17 %, group 11 % | 1.8 / 11.3 cm |
| | 400 m | 0.07 mrad | 10.5 % | zero 7 %, group 6 % | 1.0 / 6.2 cm |
| | 500 m | 0.12 mrad | 6.2 % | zero 3.9 %, group 3.4 %, MV 3.3 % | 0.6 / 3.9 cm |
| slug 50 gr | 150 m | 0.06 mrad | 21 % | MV 13 %, group 10 % | 24 / 139 cm |
| | 200 m | 0.15 mrad | 9.8 % | MV 7 % | 13 / 73 cm |
| | 300 m | 0.43 mrad | 4.6 % | MV 3.7 % | 6.2 / 36 cm |

Order matters: velocity first (it is half of the error budget at the BC range), then the far
drop. For the firearm, drop truing below ≈ 400 m cannot resolve BC (the app already refuses when
10 % BC moves less than 0.05 mrad, `minSensitivityMrad`), and the two-chronograph method at 100 m
is three times more precise than drop truing at 500 m.

##### B.3.4 Drag-shape error (why the slug needs far-range truing)

A G1 BC fitted from near data is only right where it was fitted if the projectile's real Cd(Mach)
has a different shape. Bounding test (noise-free data; the "truth" follows another law, BC chosen
to match the velocity at x):

| Load | Truth | (a) fit from velocities at x → error 300 / 500 m | (b) fit from drop at 300 m → error 500 m |
|---|---|---|---|
| .277 130 gr (all supersonic) | G7 | 0.0 / 0.5 cm (x = 100 m) | 0.2 cm |
| slug 50 gr (Mach 0.88 → 0.5) | G7 | 14 / 139 cm (x = 50 m) | 54 cm |
| slug 50 gr | constant Cd | 23 / 220 cm (x = 50 m) | 80 cm |

The constant-Cd bound reflects Ladommatos' observation that pellet Cd changes "very little"
between 120 and 200 m/s [S11]; no reusable Cd–Mach measurement of an airgun slug was found
(`docs/sacma-surukleme/RAPOR.md`). The nearest public analogue, McCoy's .22 LR spark-range data,
covers Mach 0.77–1.03 only [S13]. So for a slug **beyond ~300 m, only drop observations at those
ranges** pin the trajectory. The app's multi-range truing (`DragBandTruing`) cannot do it today:
its band edges are Mach 1.2/1.5/2.0, so a PCP flight lies in one band and reduces to a single BC
scale; its ±20 % limit also blocks 26 % (current) / 14 % (S2) of slug estimates.

#### B.4 Interaction with the app's truing limits

Share of held-out projectiles whose published BC lies outside the truing window around the
estimate (LOBO, `bc_drop_distribution.py`):

| | needs > 30 % (`BallisticCoefficientTruing`) | needs > 20 % (`DragBandTruing`) |
|---|---:|---:|
| firearm, M0 (current) | 30.2 % | 48.5 % |
| firearm, M1+2 | 8.2 % | 17.0 % |
| slug, M0 (current) | 6.7 % | 25.8 % |
| slug, S2 | 6.2 % | 13.9 % |

(The app estimates BCs only for PCP today; firearm rows show what would happen if it extended.)

### C. Recommendation (ranked by error reduction per user effort)

1. **Family-aware estimate (no user effort).** Firearm: family × SD table (A.5): LOBO median
   17 → 8 %, p90 79 → 28 %; 500 m p90 drop 28 → 18 cm. Slug: "ELR" keyword + L/d when length is
   known: 14 → 11 %, p90 28 → 23 %. Pellet: family medians: 20 → 17 % (H&N only).
2. **Show the uncertainty** (p75 of the method) and the range above which truing is required:
   slug 150 m (13 % error already ≈ 4–5 cm at 200 m and 16–22 cm at 300 m), firearm 300 m.
3. **Widen the BC-truing window to ±60 % when the BC is estimated** (keep ±30 % for published BCs),
   and keep the sensitivity guard. Otherwise truing is refused exactly when it is needed.
4. **Two-velocity BC tool** (chronograph at muzzle and at 50 m PCP / 100 m firearm, 10 shots each,
   tape): σ_BC ≈ 2–3 %. Best value per effort for firearms (better than 500 m drop truing).
   Minimum procedure: 2 × 10 shots, one tape measurement, temperature/pressure from the app.
5. **Far-drop truing** at ≥ 400–500 m (firearm) or 300 m (slug), 10-shot group centres, after
   velocity truing. For slugs it is required beyond ~200–300 m because of B.3.4.
6. **Later (code change):** subsonic bands for PCP multi-range truing (e.g. edges at Mach 0.6 /
   0.75 / 0.9) so 3 far observations fix the slug's drag shape; its ±20 % limit should also widen
   for estimated BCs.
7. **Not recommended:** geometry codes (B.1), k-NN/ML models (no gain on unseen brands), asking the
   user for bullet length (≈ no gain once the family is known; slugs: small gain, already used
   when the library has it).

### D. Limits

- Targets are published BCs, themselves 5–25 % off reality for many bullets [S5][S6]; pellet and
  slug makers do not state the velocity or method behind their BC.
- Pellet results come from one brand; slug LOBO uses only three brands; the ELR rule comes from
  one brand.
- Keyword rules were written with knowledge of the names (A.1); the factory-ammo check is the
  least biased firearm figure (median 14 %, p90 45 %).
- Truing error budgets use stated assumptions (shot SD, group SD, zero error), linearised; the
  Caldwell Ballistic Precision accuracy specification could not be read from a manufacturer page
  (only dealer listings, excluded by the source rules).
- Drag-shape bounds (G7, constant Cd) for the slug are plausible extremes, not measurements.
- Not read: McCoy's book (cited for standard definitions only), the PRODAS/AP manuals
  (commercial), the full Brno thesis text.

## Source table

Accessed 2026-10-13.

| # | Source | Type | Used for |
|---|---|---|---|
| S1 | R. L. McCoy, *Modern Exterior Ballistics*, Schiffer, 1999, ISBN 0-7643-0720-7 (not fetched) | Textbook | SD, form factor, BC = SD/i, G-function point-mass law |
| S2 | R. L. McCoy, "MC DRAG – A Computer Program for Estimating the Drag Coefficients of Projectiles", ARBRL-TR-02293, US Army BRL, 1981 — https://apps.dtic.mil/sti/pdfs/ADA098110.pdf | US Army report (public release) | MC DRAG inputs, Mach 0.5–5, 4–400 mm, 1-σ 3 % / 11 % / 6 % |
| S3 | P. Weinacht, "Virtual Wind Tunnel Experiments for Small Caliber Ammunition Aerodynamic Characterization", US ARL, NDIA Small Arms Symposium 2006 — https://ndia.dtic.mil/wp-content/uploads/2006/smallarms/weinacht.pdf | US Army (slides) | PRODAS/AP02/Missile DATCOM as fast-design codes; good only within their database |
| S4 | S. I. Silton, "Navier-Stokes Computations for a Spinning Projectile From Subsonic to Supersonic Speeds", ARL-TR-2850, 2002 — https://apps.dtic.mil/sti/pdfs/ADA407616.pdf | US Army report | AP98 under-predicts CD0; CFD 0.2935/0.2964 vs. range 0.279 at Mach 2.7 |
| S5 | M. Courtney, A. Courtney, "The Truth About Ballistic Coefficients", arXiv:0705.0389 (2007) — https://arxiv.org/abs/0705.0389 | Scientific preprint | Most published BCs overstated by 5–25 % |
| S6 | A. Halloran, C. Huntsman, C. Demers, M. Courtney, "More Inaccurate Specifications of Ballistic Coefficients", USAF Academy, 2012 — https://apps.dtic.mil/sti/pdfs/ADA555975.pdf | US Air Force Academy report | Published vs. measured G1 BC, −10.5 % … +44.8 %; two-chronograph method, 0.3 % chronographs, 4–6 shots |
| S7 | J. F. Moxnes et al., "CFD modelling of aerodynamic coefficients of projectiles moving at subsonic and supersonic speed", FFI-RAPPORT 24/01928, 2024 — https://ffi-publikasjoner.archive.knowledgearc.net/bitstream/handle/20.500.12242/3382/24-01928.pdf | Norwegian Defence Research Establishment | PRODAS drag "significantly smaller" than CFD/radar supersonic (7.62 mm) |
| S8 | J. Kokes, M. Costello, J. Sahu, "Generating an aerodynamic model for projectile flight simulation using unsteady time accurate CFD results", WIT Trans. Model. Simul. 45 (2007), doi:10.2495/CBAL070041 — https://www.camm.gatech.edu/images/0/01/Kokes_2007_GeneratingAeroModel.pdf | Peer-reviewed | Empirical codes (DATCOM, PRODAS, AP98) = catalogs by geometric features; least accurate of four methods |
| S9 | T. Melichar, *Vnější balistika projektilů pro plynové zbraně*, thesis, Brno University of Technology, 2024 — https://dspace.vut.cz/items/26785c42-81ea-4410-9c83-e92233d7109e | Academic thesis (abstract) | PRODAS V3 applied to a diabolo; measured drag law "JSBE" |
| S10 | N. Ladommatos, "Influence of air rifle pellet geometry on aerodynamic drag", Proc. IMechE P (2019), doi:10.1177/1754337119831107 — https://discovery.ucl.ac.uk/id/eprint/10072258 (via `docs/sacma-surukleme/RAPOR.md`) | Peer-reviewed | Cd by head shape at Mach 0.58 |
| S11 | N. Ladommatos, "Drag coefficients of air rifle pellets with wide range of geometries", Proc. IMechE C (2021), doi:10.1177/0954406221991190 (abstract, via `docs/sacma-surukleme/RAPOR.md`) | Peer-reviewed | Cd 0.36–0.78; little change 120 → 200 m/s |
| S12 | E. Courtney, A. Courtney, M. Courtney, "Methods for Accurate Free Flight Measurement of Drag Coefficients", arXiv:1503.05504 — https://arxiv.org/pdf/1503.05504 | Scientific preprint | Near/far formula, ≈10× error amplification, 5–20 % loss, 1 % per 1 % separation, 10 shots ≈ 1 % SEM, TOF ≈ 2× worse |
| S13 | R. L. McCoy, "Aerodynamic Characteristics of Caliber .22 Long Rifle Match Ammunition", BRL-MR-3877, 1990 — https://apps.dtic.mil/sti/pdfs/ADA229713.pdf (via `docs/research/pellet_slug_hassas_hesap.md`, branch `research/hassas-hesap`) | US Army report | Lead projectile aero data at Mach 0.77–1.03 only |
| S14 | E. Courtney, C. Morris, M. Courtney, "Accurate Radar Measurements of Drag Coefficients in Free Flight", arXiv:1811.05797 — https://arxiv.org/abs/1811.05797 | Scientific preprint | ≈ 1 % Cd with a consumer Doppler radar over 15 m (alternative to two chronographs) |
| D1 | `lib/data/bullet_library.dart`, `lib/data/factory_ammo_library.dart` (manufacturer-published values, each row with its source URL) | Repo data | All estimator training/test data |
| D2 | `tools/formula_reference.py` (repo reference solver, G1/G7 tables from `lib/core/standard_drag_tables.dart`) | Repo | All drop and truing numbers |
| D3 | `lib/core/estimated_bc.dart`, `velocity_truing.dart`, `drag_band_truing.dart`, `lib/features/ballistics/ballistics_screen.dart` | Repo | Current estimate (i = 0.825/2.06), truing limits ±30 %/±20 %, band edges, current Turkish notice |

Not used (source rules): forums, blogs, dealers (all Caldwell specification hits were dealer
pages), YouTube, and data from other ballistics apps.

## Reproduce

```bash
python3 -I tools/research/bc_estimator_cv.py --json /tmp/cv.json   # ~6 min (A.2–A.5)
python3 -I tools/research/bc_drop_distribution.py                  # A.6, B.4
python3 -I tools/research/bc_error_drop_cm.py 0.13 0.16            # drop for given errors
python3 -I tools/research/bc_truing_error.py                       # B.2–B.3.4
```

Requires Python 3.10+, numpy, scikit-learn (only for M7).
