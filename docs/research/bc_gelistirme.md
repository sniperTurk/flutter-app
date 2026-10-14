# BC'si yayımlanmayan ateşli silah mühimmatına BC: tahmin yerine gerçek değer

Tarih: 2026-10-14 · Zamanlanmış görev (sahibi çevrimdışı) · Dal: `research/bc-gelistirme`

Kapsam: yalnızca araştırma. `lib/` ve `test/` değişmedi. Betikler `tools/research/`, veriler
`data/bc_gelistirme/` altında. Tüm değerler üreticinin kendi sayfası veya PDF'inden okundu.
Okuma tarihi her değerde 2026-10-14; kaynak adresi ve kısa alıntı her satırda
`data/bc_gelistirme/bc_less_mapping.csv` ve `velocity_tables.json` içinde.

---

## Türkçe özet (sade dil)

### Kısa cevap

1. **Kütüphanede BC'si boş ateşli silah kaydı sanıldığından az: 83 fabrika fişeği, 0 mermi.**
   `bullet_library.dart` içindeki 1.566 ateşli silah mermisinin hepsinin BC'si var. Sorun yalnız
   `factory_ammo_library.dart` içindeki 83 fişekte (Black Hills 24, Aguila 21, Winchester 15,
   Hornady 9, diğerleri 14).
2. **Tahmin yerine üreticinin kendi BC'sini geri hesaplamak mümkün ve neredeyse kusursuz.** Pek
   çok üretici BC'yi yazmıyor, ama sayfasında namlu ağzı, 100, 200… yarddaki **hız tablosunu**
   veriyor. Bu tablo üreticinin kendi BC'siyle hesaplanmış. Tablodaki hızları veren BC'yi
   bulduğumuzda üreticinin kullandığı BC'yi geri elde ediyoruz.
   - **Sınama:** BC'si yayımlanmış 16 fişekte aynı işlemi yaptık (12 Hornady, 3 Aguila, 1 Lapua).
     Geri hesaplanan BC, yayımlanan BC'den **tipik %0,2, en kötü onda birlik dilimde %0,5,
     en fazla %1,3** sapıyor.
   - Önceki aile tahmininde bu dilim %28 idi; hedefimiz %10'du.
3. **Kapsam: 83 fişeğin 36'sına üretici kaynaklı bir BC bulundu.**
   - **10'u yüksek güvenli:** Hornady 8, Lapua 1, Weatherby 1. Lapua ve Weatherby BC'yi başka bir
     sayfada zaten yazıyormuş.
   - **23'ü orta güvenli:** Aguila 18, Lapua 2, Hornady 1, Black Hills 1, Winchester 1.
     - Aguila tablosunda yalnız 2 nokta var.
     - Lapua'nın değeri katalog metninden okundu.
     - Black Hills ve Winchester'da merminin adı ve markası eşleşti.
   - **3'ü düşük güvenli:** Geco 2 (hızlar 5–10 m/s'ye yuvarlanmış), Aguila 1 (ağırlık uyuşmuyor).
4. **Kalan 47 fişekte gerçek değere ulaşmanın yolu atışla doğrulama.**
   - **Black Hills 23:** üretici ne BC ne hız tablosu veriyor. 20'sinde mermi markası da yok
     ("Dual Performance" mermisi kendi üretimi). 3'ünde Hornady adı geçiyor ama hangi Hornady
     mermisi olduğu belirsiz ya da merminin BC'si okunamıyor.
   - **Winchester rimfire 12:** sayfa "There is no ballistics data available at this time" diyor.
   - **MKE 2, Nosler 1:** BC yok.
   - **Proxy/onay engeli 8:** Norma 1, SWISS P 2, Winchester Power-Point 2, Aguila 2, RWS 1.
     RWS robots.txt ile kapalı; diğerlerinde erişim izni zamanında verilmedi, bu yüzden
     denenemedi. Sahip izin verirse bunların çoğu muhtemelen BC'li çıkar: SWISS P ve Norma
     başka ürünlerinde BC yayımlıyor.
   - **Uygulanamaz 1:** saçmalı fişek.
5. **"Bileşen eşleştirme" (Black Hills → Hornady/Sierra vb.) beklenenden az işe yarıyor.**
   - Black Hills 24 fişeğin yalnız 4'ünde mermi markası yazıyor ve bunlardan yalnız 1'inin BC'si
     okunabildi (Barnes Varmint Grenade). Gerisi:
     - Hornady GMX artık satılmıyor.
     - 125 gr CX bileşen olarak yok.
     - "Hornady Match HP" üç farklı mermiye karşılık gelebiliyor.
   - Kütüphanedeki 239 fişekte, adı geçen bileşen merminin BC'si fişeğin kendi BC'sinden tipik
     %0, onda birlik dilimde **%3,7** sapıyor. Ancak hat adı tam değilse (ör. "GameKing" ↔
     "Tipped GameKing") sapma %25'e çıkıyor.
   - Yani bu yöntem yalnız hat adı birebir yazıyorsa güvenli.
6. **Üreticinin Doppler verisi ve geometriden hesap bu 83 fişeğin hiçbirini kapsamıyor.**
   - Hornady'nin 4DOF eğrileri yalnız kendi hesaplayıcısında.
   - Lapua'nın Doppler paketinin indirilmesi engelli ve şartları kısıtlayıcı.
   - Warner şartları kopyalamayı yasaklıyor.
   - Geometri yalnız Berger'de kısmen var; McDRAG'ın kendi hatası ses üstünde %3, ses civarında
     %11 (1σ).
7. **Atışla doğrulama en doğru yol, ama kullanıcı emeği istiyor.**
   - **Tek Doppler radarla** (ör. LabRadar) aynı atışın namlu ağzı ve 100 m hızı ile BC
     belirsizliği **%1–1,5**.
   - **İki ayrı kronografla** %1,6–4. .22 LR'de %8; rimfire için uygun değil.
   - **500 m'de düşüşle** %1,3–3,5. **300 m'de düşüşle** %7–17; tek başına yetmez.

### Hedef p90 ≤ %10 tutturulabilir mi?

**Evet, 36 fişekte**, ama "tahmin" olarak değil, "üreticinin değeri" olarak:

- **Geri hesaplama:** üreticinin kendi BC'sine karşı p90 %0,5.
- **Ortak sınır:** üreticinin BC'si de gerçeğe göre %5–10 hatalı olabilir. Örnek: Hornady 53 gr
  V-MAX yayımlanan 0,290, bağımsız ölçüm 0,264. Bu hata kütüphanedeki tüm BC'li kayıtlarda zaten
  var ve yeni bir hata getirmiyor.
- **Kalan 47 fişek:** sahip izin verirse bunların 6'sı daha (SWISS P 2, Norma 1, Winchester
  Power-Point 2, Aguila .223 1) aynı yolla denenebilir. Geri kalan ~40 fişekte p90 ≤ %10'un tek
  yolu kullanıcının atışla doğrulamasıdır. **Tahmin formülleriyle bu hedefe ulaşılamaz.**

### Öneri (hata → kapsam → emek sırasıyla)

| Sıra | Yöntem | Kapsam (83 içinden) | Hata (yayımlanan BC'ye göre) | Sahip / kullanıcı emeği |
|---:|---|---:|---|---|
| 1 | Üretici başka sayfada BC yazıyor, kopyala | 2 | %0 | Yok |
| 2 | **Üreticinin hız tablosundan BC'yi geri hesapla** | 31 (+1 çapraz) | tipik %0,2, p90 %0,5, en fazla %1,3 | Yok (veri hazır) |
| 3 | Adı geçen bileşen mermi (hat adı birebir) | 1 | tipik %0, p90 %3,7 (hat adı tam değilse %25'e kadar) | Yok |
| 4 | Atışla doğrulama: Doppler radar, aynı atış, 0 + 100 m | Her fişek | σ %1–1,5 | 20–30 dk, radar gerekir |
| 5 | Atışla doğrulama: 500 m+ düşüş | Her fişek | σ %1,3–3,5 | 1 atış seansı, 500 m atış yeri |
| 6 | Atışla doğrulama: iki ayrı kronograf | Her fişek (rimfire hariç) | σ %1,6–4 | 30–45 dk, 2 cihaz |
| — | Aile/uç şekli tahmini | Hepsi | tipik %8, p90 %28 (fişekte %45) | **Reddedildi** |
| — | Geometriden hesap (McDRAG) | 0 | %3–11 (1σ, tam geometriyle) | **Önerilmez:** veri yok |
| — | Üretici Doppler eğrisi | 0 | — | **Önerilmez:** erişim/lisans |

### Sahibin karar vermesi gerekenler

1. **Geri hesaplanan BC uygulamaya girsin mi?**
   - Girerse nasıl etiketlensin? Öneri: "Üreticinin hız tablosundan hesaplandı (G1)". Mevcut
     "Üretici BC'yi G1/G7 etiketi olmadan veriyor" notu gibi bir not olur.
   - Yalnız yüksek güvenliler mi, yoksa orta güvenliler de mi?
2. **Aguila'nın tablosunda yalnız iki nokta var (namlu ağzı ve 100 yd).** Bazı çiftlerde (HP/SP)
   tablolar birebir aynı. Bu, Aguila'nın aynı BC'yi iki ürün için kullandığı anlamına gelir. Kabul
   mü? Aguila'nın BC'li 3 fişeğinde geri hesap %0,1 içinde tuttu.
3. **Engellenen 6 sayfa için erişim izni.** aguilaammo.com .223 sayfası, norma-ammunition.com,
   swiss-p.com, winchester.com Power-Point. RWS robots.txt ile kapalı ve öyle kalacak.
4. **Kalan ~40 fişek için ne yapılsın?**
   - **(a)** Listede BC'siz kalsın ve "Atışla doğrula" akışı açılsın (öneri §D).
   - **(b)** Bu fişekler listeden çıkarılsın.
   - **(c)** Black Hills'e e-posta ile mermi markası ve BC sorulsun. Sahip daha önce Lapua ve
     Warner yazışmalarını iptal etmişti, bu yüzden karar sahibin.
5. **FA007 (Aguila Standard Velocity) kütüphanede 29 gr yazıyor; Aguila sayfası 40 gr diyor.**
   Kütüphane satırı düzeltilmeli mi? Bu, uygulama verisinde bir değişiklik olur ve ayrı bir görev
   gerektirir.

---

## English detail

### A. Inventory

`tools/research/bc_gelistirme_inventory.py` parses the two Dart libraries (read-only) into
`data/bc_gelistirme/inventory_*.csv`.

| Library | Rows | Firearm rows | BC-less firearm rows |
|---|---:|---:|---:|
| `factory_ammo_library.dart` | 1,813 | 1,813 | **83** |
| `bullet_library.dart` | 2,084 | 1,566 | **0** |

BC-less loads by brand: Black Hills 24, Aguila 21, Winchester 15, Hornady 9, Lapua 3, Geco 2, MKE 2,
SWISS P 2, Federal 1, Nosler 1, Norma 1, RWS 1, Weatherby 1. IDs `FA001…FA083` follow file order,
with the same numbering in every CSV.

### B. Methods, coverage and validated error

Error is |BC_method / BC_published − 1|. "Validated" means it was measured on items that do have a
published BC. Nothing is fitted per brand, so every brand is an out-of-sample test. That is
leave-one-brand-out by construction; per-brand figures are shown.

| # | Method | Coverage of 83 | Median | p90 | Max | Validation set | Effort | Main risks |
|---:|---|---:|---:|---:|---:|---|---|---|
| 1 | Maker prints the BC on another page or in a catalogue | 2 | 0 | 0 | 0 | — | none | none |
| 2 | **Back-solve the BC from the maker's own downrange-velocity table** (G1, Army Standard Metro) | 31 + 1 cross-maker | 0.19 % | 0.53 % | 1.32 % | Hornady n=12 (16"/20"/24" barrels, rimfire, subsonic, G1 and G7 lines) | none | Recovers the maker's number, not a measurement. 2-point tables (Aguila). Rounded tables (Geco). Wrong atmosphere gives a 1.8 % bias (ICAO vs ASM). |
| 2′ | (same, other brands) | — | 0.09 % | 0.10 % | 0.10 % | Aguila n=3 (2-point tables) | | |
| 2″ | (same) | — | 0.5 % | — | — | Lapua n=1 (100–300 m G1 vs published 0.341; the 600 m point gives −2.4 %) | | catalogue text reconstruction |
| 2‴ | (same, survey) | — | ≤0.3 % | — | — | Federal 2, Weatherby 1, GECO 1, Norma 1 (survey §5) | | |
| 3 | Named component bullet, same maker/line/weight/calibre | 1 (+3 ambiguous, 1 without a maker BC) | 0.00 % | 3.71 % | 25.6 % | 239 factory loads with their own BC that name a component (`component_match_validation.csv`) | none | Line-name ambiguity. Discontinued bullets. Ammo makers sometimes print a different (velocity-band) BC. |
| 4 | Truing: one Doppler radar, muzzle + 100 m of the same shot, 10 shots | all | — | σ 0.8–1.5 % | — | error propagation (§D) | 20–30 min + radar | the user needs a radar that reports downrange velocity |
| 5 | Truing: group-centre drop at ≥500 m | all | — | σ 1.3–3.5 % | — | error propagation (§D) | one range session | 300 m gives σ 7–17 %; MV and atmosphere must be right |
| 6 | Truing: two separate chronographs 100 m apart | all except rimfire | — | σ 1.6–4 % (22 LR: 8 %) | — | error propagation (§D) | 30–45 min, 2 devices | MV spread dominates |
| — | Family / tip-shape estimate (earlier work, REJECTED) | all | 8 % | 28 % (factory 45 %) | 79 % | `tahmini_bc_hata.md` | none | — |
| — | McDRAG-type geometry prediction | 0 | Cd 1σ 3 % supersonic / 11 % transonic / 6 % subsonic, with full geometry | | | ARBRL-TR-02293 (1981) | high | No BC-less maker publishes geometry. Berger lacks meplat, ogive radius and boat-tail angle. |
| — | Maker Doppler curves | 0 | — | | | — | — | Hornady 4DOF only in-calculator; Lapua QTU download blocked and terms restrictive; Warner terms forbid reuse (`data/drag-curves/INDEX.md`) |

The p90 of the factory-load family estimate (45 %) is quoted from the owner's decision note; the
other family figures are from `tahmini_bc_hata.md`.

#### B.1 Why back-solving works

Maker ballistics tables are computed, not shot. Applying the solver to loads that do print a BC
returns the printed value to within rounding:

- Hornady: 12/12 within 1.3 %, and 11/12 within 0.6 %.
- Aguila: 3/3 within 0.1 %.
- Federal, Weatherby and GECO: ±0.001 (survey).

Per-distance BCs are flat. G1 drift over 100–500 yd is 0.1–0.4 % for supersonic Hornady loads. That
shows the tables were generated with G1 under Army Standard Metro, even for Hornady's ELD/CX lines:
the back-solved G1 for 6.5 CM 147 ELD-M is 0.701 against Hornady's bullet G1 of 0.697.

Atmosphere matters. The same tables read as ICAO give +1.7–3.0 %. Lapua and Norma appear to use
ICAO (survey). Each brand's atmosphere must therefore be fixed once from its own BC-printing items,
as done here.

Independent cross-check: the Hornady .17 HMR 17 gr V-MAX back-solve (0.1251) equals the BC that
CCI, Federal and Winchester print for loads with the same V-MAX bullet (0.125). Those are in the
library and were not used in the solve.

The limits are the same as for any printed BC:

- A back-solved value is exactly as good as the maker's own BC.
- Courtney et al. (arXiv 1608.06500, survey §4) measured Hornady 53 gr V-MAX at G1 0.264 against a
  published 0.290. They also found that Winchester's published trajectory implies G1 0.206 against
  0.187 measured.

So this method reaches parity with the existing library. It is not truth.

#### B.2 Component matching

The validation covers 239 one-bullet matches among factory loads that print their own BC:

| Ammo brand | n | median | p90 | max |
|---|---:|---:|---:|---:|
| all | 239 | 0.00 % | 3.71 % | 25.6 % |
| Weatherby | 60 | 0.00 % | 0.00 % | 7.3 % |
| Federal | 49 | 0.00 % | 1.15 % | 12.6 % |
| Barnes | 35 | 0.00 % | 2.51 % | 25.6 % |
| Lapua | 26 | 0.00 % | 0.00 % | 0.00 % |
| Berger | 20 | 0.00 % | 0.00 % | 2.6 % |
| Remington | 12 | 2.97 % | 4.39 % | 7.4 % |
| Sellier & Bellot | 9 | 3.90 % | 16.1 % | 16.1 % |
| Winchester | 9 | 0.00 % | 3.71 % | 3.7 % |
| Hornady | 8 | 0.00 % | 5.90 % | 5.9 % |
| Sierra | 6 | 1.26 % | 25.6 % | 25.6 % |

The large differences are:

- Ammo makers printing a different BC for the same bullet, e.g. a 90 gr Tipped GameKing load at
  0.39 against 0.49 on the bullet page; S&B's GameKing G7 0.218 against 0.253.
- Generic line names ("TSX" BT vs FB).

Component matching is safe only when maker, line, weight and calibre are all written by the ammo
maker.

### C. Result per BC-less load (`data/bc_gelistirme/bc_less_mapping.csv`)

Counts:

| Status | n | Meaning |
|---|---:|---|
| maker_bc_found | 2 | the maker prints the BC elsewhere (Lapua cartridge page, Weatherby chart) |
| maker_table_backsolve | 31 | the BC was back-solved from the maker's own velocity table |
| linked / linked_cross_maker | 2 | Barnes Varmint Grenade (named on Black Hills' .22-250 page); Winchester 22 WMR "V-MAX" via Hornady's own 30 gr V-MAX table |
| ambiguous | 3 | FA049 Black Hills "Hornady Match HP" 168 (0.450 / 0.440 / 0.523); FA059 "Hornady CX" 125 (no 125 gr CX component); FA007 Aguila weight mismatch |
| linked_no_bc | 1 | FA073 Black Hills 70 gr Hornady GMX (bullet discontinued) |
| no_link | 35 | Black Hills 20 (generic names; Dual Performance = Black Hills' own bullet); Winchester rimfire 12 ("There is no ballistics data available at this time"); MKE 2; Nosler 1 |
| blocked | 8 | permission timed out: Aguila .223 55 FMJ, Norma Whitetail .223, SWISS P ×2, Winchester Power-Point ×2. Aguila 17 HMR page has a malformed row. RWS is robots.txt disallowed. |
| not_applicable | 1 | Federal #12 shot |

By confidence, among the 36 with a value: high 10, medium 23, low 3.

Confidence rules:

- **High:** the maker's own number, either printed or back-solved from a table with 3 or more points
  from a validated brand with drift ≤ 2 %.
- **Medium:** a 2-point table, catalogue text reconstruction, a cross-maker component link, or G1
  drift > 2 %.
- **Low:** a rounded metric table with drift > 4 %, or a weight mismatch.

| ID | Brand | Load | Cartridge | BC | Conf. | Route | Source (read 2026-10-14) |
|---|---|---|---|---|---|---|---|
| FA002 | Hornady | Varmint Express 17 gr V-MAX #83170 | .17 HMR | 0.125 G1 | high | table 2550/1902/1379 fps (0/100/200 yd) | hornady.com/ammunition/rimfire/17-hmr-17-gr-v-max |
| FA003 | Hornady | Varmint Express 20 gr XTP #83172 | .17 HMR | 0.125 G1 | high | 2375/1755/1274 | …/17-hmr-20-gr-xtp |
| FA029 | Hornady | 30 gr V-MAX #83202 | .22 WMR | 0.095 G1 | high | 2200/1454/1026 | …/22-wmr-30-gr-v-max |
| FA031 | Winchester | Varmint HV 30 gr V-MAX | .22 WMR | 0.095 G1 | medium | Hornady V-MAX table (FA029) | same |
| FA061 | Hornady | 285 gr FMJ Frontier (subsonic) #FR430 | .338 ARC | 0.647 G1 | medium | 1050…906 (0–500 yd), drift 3.6 % | …/338-arc-285-gr-fmj-frontier |
| FA062 | Hornady | 170 gr MonoFlex Black #82273 | .338 ARC | 0.309 G1 | high | 2075…1117 | …/338-arc-170-gr-monoflex-black |
| FA063 | Hornady | 175 gr HP Match Black #82271 | .338 ARC | 0.385 G1 | high | 2075…1242 | …/338-arc-175-gr-hp-match-black |
| FA064 | Hornady | 215 gr FTX Black #82274 | .338 ARC | 0.371 G1 | high | 1900…1131 | …/338-arc-215-gr-ftx-black |
| FA067 | Hornady | 210 gr InterLock AW #82461 | .400 Legend | 0.198 G1 | high | 2200…945 | …/400-legend-210-gr-interlock-american-whitetail |
| FA082 | Hornady | American Gunner 123 gr HP Match #80786 | 7.62x39 | 0.272 G1 | high | 2350…1159 | …/7.62-x-39mm-123-gr-hp-match-american-gunner |
| FA042 | Lapua | 4.5 g 69 gr Scenar-L 4315015 | .223 Rem | 0.341 G1 / 0.171 G7 | high | printed: "BC G1 0.341 / BC G7 0.171" | lapua.com/product/223-rem-target-cartridge-scenar-l-45g-69gr-4315015/ |
| FA044 | Weatherby | 72 gr Hammer Custom M24072HCB | .240 Wby Mag | 0.320 G1 | high | printed: "M24072HCB \| 320 (G1)" | weatherby.com/ammunition-org/ballistics-charts/ |
| FA045 | Lapua | 5.8 g 90 gr FMJ 4316052 | .243 Win | 0.344 G1 | medium | catalogue 885/796/712/634/434 m/s (0/100/200/300/600 m) | Lapua_Catalog_2024.pdf p.50–57 |
| FA046 | Lapua | 6.5 g 100 gr SP 4316056 | .243 Win | 0.361 G1 | medium | 910/823/742/665 m/s | same |
| FA034 | Black Hills | 36 gr Varmint Grenade | .223 Rem | 0.149 G1 | medium | Barnes: "36-grain Varmint Grenade … Ballistic Coefficient .149" | barnesbullets.com/…/223RemingtonWeb.pdf |
| FA004/005 | Aguila | Interceptor HP / SP 40 gr | .22 LR | 0.140 G1 | medium | 1470/1130 fps (0/100 yd), identical on both pages | aguilaammo.com/products/22-interceptor-… |
| FA006 | Aguila | Sniper Subsonic 60 gr | .22 LR | 0.139 G1 | medium | 950/848 | …/22-sniper-subsonic-… |
| FA007 | Aguila | Standard Velocity LSP (library 29 gr; page 40 gr) | .22 LR | 0.170 G1 | low | 1130/981 | …/22-super-extra-long-rifle-standard-velocity-… |
| FA008 | Aguila | Subsonic LHP 38 gr | .22 LR | 0.111 G1 | medium | 1024/873 | …/22-subsonic-hollow-point |
| FA009 | Aguila | Subsonic LSP 40 gr | .22 LR | 0.158 G1 | medium | 1025/911 | …/22-subsonic-solid-point-… |
| FA010/011 | Aguila | SuperMaximum HP / SP 30 gr | .22 LR | 0.110 G1 | medium | 1700/1190, identical on both pages | …/22-supermaximum-… |
| FA012 | Aguila | Target Competition 40 gr | .22 LR | 0.168 G1 | medium | 1080/951 | …/22-target-competition-… |
| FA028 | Aguila | 22 WMR SJSP 40 gr | .22 WMR | 0.150 G1 | medium | 1875/1433 | …/22-win-mag-high-velocity-semi-jacketed-soft-point |
| FA047 | Aguila | 110 gr FMJ | .30 Carbine | 0.127 G1 | medium | 1990/1451 | …/30-carbine-full-metal-jacket |
| FA048 | Aguila | 150 gr SP | .30-06 | 0.339 G1 | medium | 2900/2628 | …/30-06-sprg-150-gr-soft-point |
| FA050 | Aguila | 150 gr FMJ | .300 BLK | 0.303 G1 | medium | 1960/1721 | …/300-aac-blackout-full-metal-jacket |
| FA056/083 | Aguila | 150 gr FMJBT | .308 Win / 7.62x51 | 0.323 G1 | medium | 2760/2484, identical pages | …/308-win-full-metal-jacket-boat-tail, …/7.62-x-51mm-… |
| FA068 | Aguila | 55 gr FMJBT (bulk-pack page) | 5.56x45 | 0.301 G1 | medium | 3260/2929 | …/5.56-x-45mm-full-metal-jacket-boat-tail-bulk-pack |
| FA069 | Aguila | 62 gr FMJBT | 5.56x45 | 0.284 G1 | medium | 3150/2809 | …/5.56-x-45mm-full-metal-jacket-boat-tail |
| FA070 | Aguila | NATO 55 gr FMJ | 5.56x45 | 0.252 G1 | medium | 3164/2781 | …/5-56-x-45mm-nato-55-grain-full-metal-jacket |
| FA075 | Aguila | 140 gr FMJBT | 6.5 CM | 0.500 G1 | medium | 2600/2426 | …/6.5-creedmoor-full-metal-jacket-boat-tail |
| FA014 | Geco | GECO RIFLE .22 2,6 g | .22 LR | 0.135 G1 | low | 330/300/280 m/s (0/50/100 m) | geco-ammunition.com/…/geco-rifle |
| FA015 | Geco | GECO SEMI-AUTO .22 2,6 g | .22 LR | 0.150 G1 | low | 350/315/294 m/s | …/geco-semi-auto |

Full precision, per-distance BCs, G7/ICAO equivalents and drift are in `backsolve_results.csv`.
Each table's verbatim figures, URL and read date are in `velocity_tables.json`. The component and
no-link evidence, with quotes and the failed URLs, is in `agent_component_search_*.json`.

Caveats on the medium and low rows:

1. **Aguila:**
   - The tables have two points only, so the drag model cannot be identified. The value reproduces
     Aguila's own 100 yd figures exactly. Further out it follows G1, as Aguila's own BC-printing
     loads do.
   - HP and SP twins share a table, so Aguila evidently uses one BC for both.
2. **Lapua catalogue:** the table was extracted from PDF text by the fetch tool, which warned that
   the layout was scrambled. Verify it against the printed p.50–57 before use. The same extraction
   for 4315015 matches Lapua's printed G1 0.341 within 0.5 % (100–300 m).
3. **Geco rimfire:** velocities are rounded to 5–10 m/s, giving ±1.3 % from rounding alone, and the
   two segments disagree by 4–7 %.
4. **FA061 (subsonic, 1050 fps):** G1 drift is 3.6 %. The Hornady subsonic validation items show a
   similar drift (1.1–1.3 %) but still land within 0.5 %.

### D. Truing as the main path for the remaining ~40 loads

Linear error propagation is in `tools/research/bc_truing_sigma.py` (G1, ASM, 10 shots). Assumptions:

- MV SD 4.5 m/s.
- Chronograph ±0.1 %, per maker specs: LabRadar "accuracy of 0.1%"; Garmin Xero C1 "+/- 0.1%" for
  rifle.
- Downrange radar reading ±0.2 %.
- Tape ±0.5 m.
- Drop read ±1.5 cm.
- Range ±1 m.

| Load | Doppler, same shot, 0 + 100 m | Two separate chronographs, 0 + 100 m | Drop @300 m | @500 m | @800 m |
|---|---:|---:|---:|---:|---:|
| .308 168 gr (G1 0.45, 800 m/s) | 1.2 % | 3.2 % | 10.7 % | 2.4 % | 0.9 % |
| 6.5 CM 140 gr (0.58, 820 m/s) | 1.5 % | 4.0 % | 16.7 % | 3.5 % | 1.3 % |
| .223 55 gr (0.25, 990 m/s) | 0.8 % | 1.6 % | 7.5 % | 1.3 % | 0.5 % |
| .22 LR 40 gr (0.14, 330 m/s, 50 m) | 1.5 % | 8.4 % | — | — | — |

These are consistent with Sierra's "total error … no larger than two percent" for two-chronograph
time of flight and with Courtney's 1–2 % (survey §4). Drop-based σ excludes errors in the atmosphere
and in mean MV beyond ±1 m/s, so treat it as a lower bound.

**Suggested flow** (text only; Turkish UI per CLAUDE.md, with an ⓘ on every value):

1. On a factory load with no BC, the profile shows "BC yok — üretici yayımlamıyor" with a button
   "BC'yi atışla bul".
2. The user picks a method. Each step's values get an ⓘ saying what the value is, where to find it
   and a typical example.
   - **Radar** (recommended): 10 shots. Enter the mean velocity at the muzzle and at 100 m; for
     .22 LR, at 50 m. Both come from the same radar.
   - **Two chronographs:** 10 shots each. Enter the two means and the measured distance between
     them.
   - **Long-range drop:** muzzle velocity (10 shots), zero distance, range (rangefinder), and the
     group-centre correction in MIL/MOA. Allowed only at ≥500 m for centrefire, because 300 m gives
     σ 7–17 %.
3. The app solves the BC with the existing G1 solver and shows the result with its σ, e.g. "0,312 ±
   %1,5". It saves the value with the label "Atışla bulundu (tarih)". The ±30 % plausibility check
   uses the back-solved or family value as a reference only. It never blocks.
4. Until trued, the load can be used only up to the distance where a ±10 % BC error stays under 1
   MOA. That is roughly 300 m for centrefire and 100 m for rimfire. Beyond that the app asks for
   truing. This is an owner decision.

### E. Other credible methods considered

- **Writing to makers** for the bullet or BC (Black Hills: 21 loads). This could reach real
  numbers, but the owner cancelled earlier maker correspondence (Lapua/Warner), so it is the
  owner's call.
- **NATO-standard mapping** (`bcSource: 'nato-standard'`, already in the app for one load). Aguila
  5.56 62 gr FMJBT and 7.62x51 150 gr FMJBT do not name M855 or M80, so this would be "probable"
  only. The maker's table back-solve is better evidence and is already available.
- **Dealer listings:** not used for values (rules).

### F. Reproduce

```bash
python3 tools/research/bc_gelistirme_inventory.py        # inventory CSVs
python3 tools/research/bc_backsolve.py                   # ~1 min; backsolve_results.csv + validation
python3 tools/research/bc_component_match_validation.py  # component-match validation
python3 tools/research/bc_gelistirme_mapping.py          # bc_less_mapping.csv + counts
cd tools/research && python3 bc_truing_sigma.py         # truing sigma (~10 min)
```

### G. Rules followed / limits

- Values come only from maker sites and PDFs (hornady.com, aguilaammo.com, lapua.com, weatherby.com,
  barnesbullets.com, geco-ammunition.com, black-hills.com, winchester.com, mke.gov.tr,
  nosler.com).
- No forums, blogs or dealers. No ballistic-app data. The G1/G7 tables are the app's own
  `standard_drag_tables.dart` (BRL functions).
- Literature is cited only for method accuracy: DTIC ARBRL-TR-02293, arXiv preprints, maker
  technical pages.
- RWS and JSB were not fetched (robots.txt). Pages whose permission prompt timed out were not
  retried or worked around; they are listed as blocked.
- The Oehler System 89 page currently serves spam and was ignored.
- The background survey with quotes is `data/bc_gelistirme/survey_doppler_geometry_truing.md`.
  Some of its quotes are WebFetch extractions; spot-check them before quoting them in the app.
