# Modifiye tüfek: FX namlu, namlu boyu, yiv adımı ve kararlılık

Araştırma notu — 2026-10-12. **Yalnızca araştırma**; `lib/` ve `test/` değişmedi.
Kaynak kuralı: yalnızca üretici sayfaları (fxairguns.com, Hatsan / Hatsan USA)
ve akademik yayınlar (arXiv, hakemli dergiler). Forum, blog, bayi, YouTube ve
başka balistik uygulamalarının verisi kullanılmadı. Her değer için kaynak
URL'si aşağıdaki İngilizce tabloda (S1…S14) var. Robots.txt: fxairguns.com
boş/izinli; hatsan.com.tr yalnızca `/wp-admin/`, sepet ve WooCommerce
klasörlerini kapatıyor — okunan sayfalar bunların dışında.

Bağlam: Hatsan Hercules PCP, 6.35 mm (.25), stok namlu yerine FX 80 cm namlu,
~50 gr slug, ~985 fps; hedef >1000 fps ve 500 m üstü.

---

## Türkçe özet

### 1. FX'in resmî olarak yayımladığı bilgiler (S1–S7)

- **STX (Smooth Twist X)**: dış gövde (housing) + değiştirilebilir iç namlu
  (liner) sistemi. FX kılavuzu, liner değiştirerek "farklı yiv adımları elde
  etmek" için tasarlandığını söylüyor (S6b).
- **Üç liner ailesi** (S2):
  - **Superior** — "hem klasik saçma hem hafif slug" için çok yönlü.
  - **Superior Heavy** — "ağır saçma ve yüksek BC'li slug'ları
    kararlı kılmak için optimize; uzun menzil hassas atış için".
  - **Superior Slug** — "yalnızca slug atmak için; slug kararlılığı ve
    isabeti için optimize yiv adımı ve yiv profili".
- **Uzunluklar**: liner sayfası filtrelerinde 300, 380, 395, 500, 600, 700,
  **800 mm**; namlu kiti filtrelerinde 500/600/700/800 mm (S2, S3).
- **Yiv adımları**: liner sayfasının filtrelerinde **1:16, 1:18, 1:24, 1:25,
  1:28, 1:40** (inç başına tur) yer alıyor (S2). **Ancak hangi liner/kalibre/
  uzunluğun hangi adıma sahip olduğu sayfanın statik metninde yok** (varyant
  tablosu boş geliyor) ve parça şemalarında da adım yazmıyor (S4, S5). Yani
  .25 Superior Heavy 800 mm'nin adımını FX kaynağından **doğrulayamadık**.
  Sahibi adımı liner/ambalaj üzerindeki işaretten veya yetkili FX
  bayisinden teyit etmeli ve uygulamaya elle girmeli.
- **Parça şemaları** (S4, S5): .25 için 380 / 500 mm "Superior",
  600 / 700 mm "Superior Heavy" liner'lar listeleniyor. Panthera 600 ve 700
  standart olarak Superior Heavy, Panthera 500 Superior kullanıyor (S7).
- **Namlu kitleri** yalnızca FX tüfekleri için (Impact M4; Dynamic MKII,
  Panthera MKII, King; DRS) ve tüfek boyuna eşleşmiş plenum / hava tüpü ile
  geliyor (S3). **Hatsan Hercules için FX kiti yayımlanmamış**; bu yüzden
  Hercules'e takılan FX namlu, üreticinin test ettiği bir kombinasyon değil.
- **İsabet / grup iddiası**: FX hiçbir sayfada sayısal grup (MOA, mm)
  vermiyor; yalnızca "üstün isabet" gibi pazarlama ifadeleri var (S1, S2,
  S8). FX Impact M4 kılavuzu açıkça: **"Daha yüksek güç daha iyi isabet
  demek değildir."** ve diabolo saçma için 840–940 fps civarını öneriyor (S6).
- **Ağırlık–liner ilişkisi**: Impact M4 kılavuzu: standart liner "esas
  olarak saçma ve hibrit slug içindir"; ağır mühimmatta o amaca yapılmış
  liner daha iyi sonuç verir (S6).

### 2. Namlu boyu ↔ hız/verim ve yiv adımı ↔ kararlılık

**Namlu boyu (üretici):** FX Impact M4 kılavuzu (S6):
- "Kısa namlular uzun namlulardan daha yüksek basınç ister."
- Regülatörü "hedeflediğiniz hız için mümkün olan en düşük basınca" ayarlayın.
- Kalibre, liner veya mühimmat değişince güç ayarı yeniden yapılmalı.
- Yüksek çekiç yayı gerilimi + düşük regülatör basıncı = yüksek hava tüketimi.

**Namlu boyu (fizik):** Rohrbach, Buresh, Madsen (S10) basınçlı hava topu
için çıkış hızını namlu boyu L'nin fonksiyonu olarak veriyor (adyabatik):

`v = sqrt( (2/m) · [ P0·V0/(γ−1) · (1 − (V0/(A·L+V0))^(γ−1)) − A·L·Patm − L·f ] )`

(γ = 7/5, A namlu kesiti, V0 hazne hacmi, f sürtünme). Uzun namlu gazın daha
fazla genleşme işi yapmasına izin verir, ama kazanç `A·L / V0` oranıyla
azalarak artar; sürtünme ve atmosfer terimi L ile doğrusal büyür. Aynı
makale, valf modellenmeden ne adyabatik ne izotermal modelin ölçülen hızı
doğru tahmin ettiğini ve **namludaki basıncın hazne basıncıyla aynı
olmadığını** söylüyor — PCP'de valfin açık kalma süresi (dwell) tam da bu
etkidir. Sonuç: 585 → 800 mm'nin ne kadar hız kazandıracağı formülle
güvenilir tahmin edilemez; **kronografla ölçülen hız esas alınmalı.**

**Stok namlu uyuşmazlığı:** Hatsan'ın resmî Hercules kılavuzu namlu boyunu
**585 mm (23")** veriyor; .25 için azami 365 m/s (1200 fps), 87 J; hazne
2×500 cc, dolum azami 250 bar; yiv adımı ve regülatör belirtilmemiş (S11).
Sahibinin "~70 cm stok" bilgisi bu kaynakla uyuşmuyor; farklı bir sürüm
olabilir — uygulamaya stok boy elle girilmeli. Uygulamanın kütüphanesi de
585 mm kullanıyor (`lib/data/rifle_library.dart`).

**Enerji kontrolü:** 50 gr @ 985 fps = **107.7 ft·lb ≈ 146 J**; 1000 fps'te
111 ft·lb. Bu, Hatsan'ın .25 için yayımladığı 87 J azami değerin çok
üstünde. (E[ft·lb] = m[gr]·v[fps]² / 450 240.) Ülkenizdeki enerji sınırı ve
tüfeğin basınç sınırları sahibinin sorumluluğundadır.

**Yiv adımı ↔ kararlılık (Miller kuralı):** Miller, *Precision Shooting*,
Mart 2005, s. 43–48; formül Courtney & Miller'da aktarılmış (S12):

`Sg = 30·m / ( t² · d³ · l · (1 + l²) ) · (V/2800)^(1/3) · ((T_F+460)/519) · (29.92/P_inHg)`

- m: grain, d: çap (inç), t: yiv adımı **kalibre** cinsinden (adım_inç / d),
  l: mermi boyu **kalibre** cinsinden (boy_inç / d), V: fps.
- Eşikler (S12, S13): Sg > 1.0 teoride kararlı; **Sg < 1.3'te sürüklenme
  belirgin artar** (BC düşer); uzmanlar **1.4–2.0** öneriyor; formülün
  doğruluğu ~%5, bu yüzden takla atma Sg 0.95–1.05 arasında başlayabilir.
- **Ses altı hız:** Courtney & Miller: "bu düzeltme çarpanı ses hızının
  altındaki tüm hızlar için ses hızındaki değeri alır" (S12). Yani ses altı
  slug'da V yerine ses hızı (~1120 fps) kullanılmalı. Uygulamanın
  `Stability.millerSg` fonksiyonu gerçek V'yi kullanıyor; 985 fps'te çarpan
  0.706 yerine 0.737 olmalı → Sg ~%4 düşük (güvenli tarafta) hesaplanıyor.
  Ayrıca Courtney & Courtney, iki formülün de **ses altı ve transonik
  bölgede kararlılığı olduğundan düşük tahmin ettiğini** belirtiyor (S13).
  Bu bir kod değişikliği önerisi değil, sahibine karar notu.
- **Uygulanabilirlik sınırı:** Miller kuralı katı/çekirdekli mermiler için
  türetildi; oyuk uçlu (hollow point) mermiler için uygun bir Sg formülü
  yok (S13). Çoğu PCP slug'ı oyuk uçlu veya düz/oyuk tabanlı olduğundan
  sonuç **yaklaşık** kabul edilmeli ve sahada doğrulanmalı.

**Örnek: 50 gr .25 slug, 985 fps, standart hava (59 °F, 29.92 inHg).**
Hücrede `gerçek V / ses hızı ile` Sg. Boy kumpasla ölçülmeli.

| Slug boyu | 1:16 | 1:18 | 1:24 | 1:25 | 1:28 |
|---|---|---|---|---|---|
| 8 mm  | 5.08 / 5.30 | 4.01 / 4.19 | 2.26 / 2.35 | 2.08 / 2.17 | 1.66 / 1.73 |
| 9 mm  | 3.88 / 4.05 | 3.07 / 3.20 | 1.72 / 1.80 | 1.59 / 1.66 | 1.27 / 1.32 |
| 10 mm | 3.02 / 3.15 | 2.39 / 2.49 | 1.34 / 1.40 | 1.24 / 1.29 | 0.99 / 1.03 |
| 11 mm | 2.39 / 2.49 | 1.89 / 1.97 | 1.06 / 1.11 | 0.98 / 1.02 | 0.78 / 0.81 |
| 12 mm | 1.92 / 2.00 | 1.51 / 1.58 | 0.85 / 0.89 | 0.78 / 0.82 | 0.63 / 0.65 |

Okuma: 50 gr'lık uzun (≥10 mm) bir .25 slug, 1:24–1:28 gibi yavaş adımlarda
1.3 sınırının altına iner; 1:16–1:18 gibi hızlı adımlar rahat kararlı kalır.
Adımlar FX filtresindeki değerlerdir; hangisinin sahibinin liner'ında
olduğu doğrulanmalıdır.

**Sürüklenme (şekil):** Ladommatos (S14), 4.5 mm saçmalarda Ma ≈ 0.58'de
Cd: küre 0.510, dome 0.422, flat 0.561, cone 0.668, cavity 0.714; dome
saçmanın kuyruğu kaldırılınca Cd 0.730'a çıkıyor (taban sürüklenmesi).
Ölçüm dönme içermiyor. Slug'lar için bu tür akademik Cd verisi bulunamadı.

### 3. Uygulamanın saklaması / hesaplaması önerilenler

Mevcut durum: `Rifle` modelinde `barrelLengthMm`, `barrelType`,
`twistRateIn`, `twistDirection`, `regulatorBar` var; `RifleProfile`'da
namlu çıkış hızı ve basınç–hız tablosu var; mermi boyu yalnızca atış
ayarında (`ShotSettings.bulletLengthText`), mühimmat kaydında değil;
`Stability.millerSg` ve kararsız/marjinal uyarısı zaten mevcut.

Önerilen alanlar (taslak, kod yazılmadı):

| Alan | Tür | Neden / kaynak |
|---|---|---|
| `modified` | bool | Stok verisinin artık geçerli olmadığını işaretler; üretici hız/enerji değerleri gizlenir veya "stok" diye etiketlenir (S11). |
| `stockBarrelLengthMm` | double? | Değişiklik öncesi boy (Hercules: 585 mm, S11). |
| `barrelLengthMm` | double? (var) | Takılı namlu boyu, ör. 800. |
| `barrelMake` | MenzilSelect | "FX", "Hatsan (stok)", "Listede yok". |
| `linerFamily` | enum | Superior / Superior Heavy / Superior Slug / diğer (S2). |
| `twistRateIn` + `twistSource` | double? + enum | Adım ve nereden geldiği: üretici işareti / bayi / kullanıcı ölçümü. FX adımı yayımlamadığı için kaynak önemli (S2). |
| `ammo.lengthMm` | double? (mühimmatta) | Miller için gerekli; atış ayarı yerine mühimmatta tutulursa her profil kullanır (S12). |
| `ammo.tipType` | enum | solid / hollow point / hibrit; HP'de "Sg yaklaşık" uyarısı (S13). |
| Kronograf oturumu | liste | tarih, n, ortalama, SD, ES, sıcaklık, regülatör/tüp basıncı. Namlu değişince hız formülle değil ölçümle girilir (S6, S10). |
| Grup kaydı | liste | mesafe, atış sayısı, grup (mm/MOA), mühimmat, liner. FX sayısal grup iddiası yayımlamıyor (S1, S8). |
| `notes` | metin | Serbest not (ör. "FX 800 mm Superior Heavy, bayi X taktı"). |

Hesaplamalar:
1. **Sg (Miller)** — mevcut formül; girdi: ağırlık, çap, `ammo.lengthMm`,
   `twistRateIn`, ölçülen V, sıcaklık, basınç (S12). Eşikler: <1.0
   kararsız, 1.0–1.3 marjinal (BC kaybı), 1.3–1.4 sınırda, 1.4–2.0 önerilen
   (S12, S13). Ses altı için V yerine ses hızı (S12) — sahibinin kararı.
2. **Enerji** — `E_J = 0.5 · m_kg · v²`; `E_ftlb = gr · fps² / 450 240`.
   Stok azami enerji (S11) ile karşılaştırma bilgisi.
3. **Önerilen en hızlı / en yavaş adım** — Miller'ı t için çözerek
   hedef Sg (ör. 1.4) için gereken azami adım:
   `t_kal = sqrt( 30·m·fV·fA / (Sg_hedef · d³ · l · (1+l²)) )`,
   `adım_inç = t_kal · d` (fV, fA: hız ve hava düzeltmeleri). Liner seçimi
   öncesi "bu slug hangi adımı ister?" sorusunu yanıtlar.
4. **Hız tahmini yok** — namlu boyu değişince hızı tahmin etmek yerine
   kronograf zorunlu; S10 basit modellerin gerçek valfli sistemi tahmin
   edemediğini gösteriyor.

### Açık noktalar

- FX .25 liner'larının (özellikle 800 mm) yiv adımı üretici metninde yok.
- Hatsan Hercules stok yiv adımı yayımlanmamış (S11).
- Sahibinin slug marka/model ve boyu bilinmiyor; Sg tablosu örnek.
- Sahibinin "~70 cm stok namlu" bilgisi Hatsan'ın resmî 585 mm değeriyle uyuşmuyor.

---

## Source table (English)

| ID | Value(s) used | Source | URL |
|---|---|---|---|
| S1 | STX system: interchangeable liners; Superior Liner System "optimizing barrel performance for different projectile types"; Solid / Bull barrel kits; calibers 177/22/25/30/35; no numeric accuracy claims | FX Airguns — The FX STX Barrel System | https://www.fxairguns.com/accessories/barrels/ |
| S2 | Liner families Superior / Superior Heavy / Superior Slug and their projectile descriptions; length filter 300/380/395/500/600/700/800 mm; twist filter 1:16, 1:18, 1:24, 1:25, 1:28, 1:40; per-variant twist not in static text | FX Airguns — Liners | https://www.fxairguns.com/accessories/barrels/liners/ |
| S3 | Barrel kits for Impact M4, Dynamic MKII/Panthera MKII/King, DRS; lengths 500/600/700/800 mm; plenum / air tube matched to barrel length; no Hatsan kit | FX Airguns — Barrel Kits | https://www.fxairguns.com/accessories/barrels/barrel-kits/ |
| S4 | Parts: STX Liner .25 380 mm Superior (21040), .25 500 mm Superior (19976), .25 600 mm Superior Heavy (20861); no twist listed | FX Dynamic/Panthera MKII barrel system schematic (PDF) | https://www.fxairguns.com/media/rrepycjd/dynamix-panthera-mkii-barrel-system.pdf |
| S5 | Parts: Liner .25 500/600/700 mm Superior Heavy (19976, 20861, 20659); no twist listed | FX Panthera barrel schematic (PDF, 2023-03-17) | https://www.fxairguns.com/media/5z4nwfee/fx-panthera-barrel.pdf |
| S6 | "Shorter barrels require higher pressure than longer barrels"; regulator at lowest pressure for target velocity; "Higher power does not mean better accuracy"; pellets ~840–940 ft/s; standard liner "mainly for pellets and hybrid slugs"; P/S transfer ports; reg max 170 bar; hammer spring vs air use | FX Impact M4 Owner's Manual (PDF) | https://www.fxairguns.com/media/qlkcvvrf/fx-impact-m4.pdf |
| S6b | STX allows "changeable core barrel liner to obtain various twist rates"; tuned with JSB pellets; reg max 160 bar | FX Dreamline Owner's Manual (PDF) | https://www.fxairguns.com/media/dccduptp/fx-dreamline-2020.pdf |
| S7 | Panthera 600 & 700 use Superior Heavy STX liner as standard; Panthera 500 uses Superior (pellets and light slugs); "dedicated slug rifle" | FX Panthera (legacy) | https://www.fxairguns.com/legacy-rifles/fx-panthera/ |
| S8 | Crown MKII: Superlight STX; calibers .177/.22/.25/.30; no twist or numeric accuracy given | FX Crown MKII | https://www.fxairguns.com/rifles/fx-crown-mkii/ |
| S9 | HALO slug performs from 30 cal Superior and Superior Slug liners | FX HALO | https://www.fxairguns.com/accessories/ammunition/fx-halo/ |
| S10 | Adiabatic/isothermal exit-velocity vs barrel length equations (γ = 7/5); neither model predicts measured velocity without valve modelling; barrel pressure ≠ reservoir pressure | Rohrbach, Buresh, Madsen (Wabash College), "The exit velocity of a compressed air cannon", arXiv:1106.2803 | https://arxiv.org/pdf/1106.2803 |
| S11 | Hatsan Hercules: barrel 585 mm (23"); OAL 1230 mm; 2×500 cc; max fill 250 bar; .25: 365 m/s (1200 fps), 87 J, 13-shot magazine; twist and regulator not stated | Hatsan Hercules Owner's Manual (EN, PDF, Hatsan USA) | https://hatsanairgunsusa.com/wp-content/uploads/2018/12/Hercules_Manual_EN.pdf |
| S11b | Hercules .25: 13-shot magazine (other specs in tabs not in static text) | Hatsan official product page | https://hatsan.com.tr/urun/hercules-en/ |
| S12 | Miller rule Sg formula and units; original citation Miller, Precision Shooting, Mar 2005, pp. 43–48; velocity factor below speed of sound takes its value at the speed of sound; Sg < 1.3 drag increase; recommended 1.4–2.0; valid for solid / solid-core bullets | Courtney & Miller, "A Stability Formula for Plastic-Tipped Bullets, Part 1" (Precision Shooting, Jan 2012), arXiv:1410.5340 | https://arxiv.org/pdf/1410.5340 |
| S13 | Formulas underestimate stability in subsonic/transonic region; no Sg formula for hollow points; accuracy ~5 % | Courtney & Courtney, "Gyroscopic Stability of Open Tipped Match Style Rifle Bullets", arXiv:1401.4187 | https://arxiv.org/pdf/1401.4187 |
| S13b | BC drops significantly below Sg 1.3; tumbling likely between Sg 0.95 and 1.05; "keeping predicted stability above Sg = 1.30 is probably ample margin" | Courtney & Courtney, "Aerodynamic Drag and Gyroscopic Stability", arXiv:1309.5039 | https://arxiv.org/pdf/1309.5039 |
| S14 | 4.5 mm pellet Cd at Ma ≈ 0.58: sphere 0.510, dome 0.422, flat 0.561, cone 0.668, cavity 0.714; dome without tail 0.730 | Ladommatos, "Influence of air rifle pellet geometry on aerodynamic drag", Proc. IMechE Part P, 2019, DOI 10.1177/1754337119831107 | https://discovery.ucl.ac.uk/id/eprint/10072258/1/Influence%20of%20air%20rifle%20pellet...pdf |

Derived (computed here, not sourced): Sg table (Python, formula S12, 50 gr,
d = 0.25 in, 985 fps and 1120 fps); energy 50 gr @ 985 fps = 107.7 ft·lb
(146 J); velocity factors (985/2800)^(1/3) = 0.706, (1120/2800)^(1/3) = 0.737.

Not found / not verifiable from allowed sources: twist rate per FX .25 liner
and length; Hatsan Hercules stock twist; manufacturer group-size claims;
academic drag data for airgun slugs.
