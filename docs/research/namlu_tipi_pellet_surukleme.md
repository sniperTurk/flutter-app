# Namlu tipi (slug / saçma namlusu) ve diabolo saçmanın sürüklenme modeli

Tarih: 2026-10-13 · Zamanlanmış görev (sahibi çevrimdışı) · Dal: `research/namlu-tipi`
**Yalnızca araştırma.** `lib/` ve `test/` değişmedi.

Kaynak kuralı: yalnız üretici resmî sayfaları ve kılavuzları, bilimsel, akademik ve devlet
kaynakları. Forum, blog, bayi, YouTube ve başka balistik uygulamalarının verisi (ChairGun,
Strelok, Applied Ballistics, QuickLOAD, GRT, JBM) kullanılmadı. Robots.txt'nin kapattığı
sayfalar okunmadı: JSB, Weihrauch'un iki sayfası, scientiairanica.sharif.edu ve
mme.modares.ac.ir. Kaynak numaraları ([N1] …) en alttaki tabloda. Tablolardaki "hesap"
satırları burada, depodaki formülle (`tools/formula_reference.py`: Miller Sg, G1/G7/GS
tabloları) hesaplandı.

---

## Türkçe özet (sahibi için)

### Soru A: Saçma (diabolo) için G1'den iyi bir model var mı?

**Kısa cevap: Yok.** Diabolo saçma için PCP hızlarını (Mach 0,6–0,9, yaklaşık 700–1000 fps)
kapsayan, **ölçülmüş** bir Cd–Mach eğrisi yayımlayan ne üretici ne de bilimsel kaynak
bulundu.

- **Bilimsel ölçümler tek hızda.** Rüzgâr tüneli ölçümleri Mach 0,58'de (≈ 200 m/s ≈ 650 fps)
  yapıldı [N20]. 120–200 m/s arasında Cd neredeyse değişmiyor [N21]. 700 fps'in üstü
  **hiç ölçülmemiş.**
- **Tek kaynak bilgisayar benzetimi (CFD).** Mach 0,7 / 1,0 / 1,3'te yapıldı, değerler yalnız
  grafikte veriliyor ve basınç sürüklenmesinin Mach ile arttığını söylüyor [N22].
- **GA / GA2 bilimsel bir model değil.** Balistik programlarından ve forumlardan geliyor.
  Tanımlayan bir makale ya da üretici belgesi bulunamadı. (GA, 2026-10-12'de uygulamadan
  zaten kaldırıldı.)
- **Üreticiler (H&N vb.) tek bir BC veriyor.** Ne modeli ne de hangi hızda ölçüldüğünü
  yazıyorlar [N16].

**G1'in hatası ne kadar?** Gerçek eğri ölçülmediği için kesin hata söylenemez. Ancak
"doğru eğri G1 olmasaydı ne olurdu?" sorusu hesaplanabilir. Bunun için BC'yi 50 m'de
eşledik (kronografla ya da 50 m atışla BC bulununca olan budur) ve iki uç biçim denedik:
düz Cd (ölçümlere göre) ve küre eğrisi (daha dik).

| Saçma, hız | 100 m düşüş farkı | 150 m düşüş farkı | 150 m rüzgâr farkı (4 m/s) |
|---|---:|---:|---:|
| .177 8,44 gr, 800 fps | ≈ 1–2 cm | 2–19 cm | 0–17 cm |
| .177 8,44 gr, 950 fps | ≈ 0–3 cm | 8–27 cm | 9–22 cm |
| .22 18,13 gr, 800–950 fps | ≈ 0–1,5 cm | 1–12 cm | 0–13 cm |
| .25 25,4 gr, 800–950 fps | ≈ 0–1 cm | 0–8 cm | 0–9 cm |

Karşılaştırma için: **BC'deki %10'luk bir hata** 100 m'de 2–10 cm, 150 m'de 8–62 cm düşüş
farkı yapar. Bu tabloyu üç şekilde okuyabilirsiniz:

1. **50–100 m'de G1 yeterli.** Biçim hatası birkaç santimdir. Asıl hata BC'nin kendisinden
   gelir.
2. **900 fps üstü ve 150 m'de biçim önemli hâle gelir,** özellikle hafif .177'de. Saçma bu
   hızda ses hızına yaklaşır. G1'in Cd'si orada hızla yükselir, ama saçmanınki ölçülmedi.
3. **Öneri:** saçmada G1 kalsın. BC (ve gerekirse eğri) **atışla düzeltilsin**: 50 m'de BC,
   100 ve 150 m'de kontrol. 100 m üstü sonuç ve 900 fps üstü hız "tahmini" diye etiketlensin.

### Soru B: Namlu slug namlusu mu? Neden önemli?

**Slug namlusunu saçma namlusundan ne ayırır? (üreticilerin söyledikleri)**

- **Yiv adımı.** FX üç namlu iç borusu (liner) satıyor:
  - "Superior": saçma ve hafif slug için.
  - "Superior Heavy": ağır saçma ve yüksek BC'li slug için.
  - "Superior Slug": yalnızca slug için, "optimize edilmiş yiv adımı ve yiv profili" ile.

  FX hangi liner'ın hangi adımda olduğunu **yazmıyor**. Filtrede yalnızca 1:16, 1:18, 1:24,
  1:25, 1:28 ve 1:40 değerleri görünüyor [N1].
- **Choke (namlu ucunda daralma).** AEA'nın açıklaması [N9]:
  - Sert choke hafif diabolo saçmada iyi, slug'da kötü sonuç verir.
  - Kademeli, hafif choke iki tipe de uyabilir.
  - AEA'nın en üst namlularında choke hiç yok.

  Daystate ve Brocock, Juggernaut slug'ları için "choke'suz ya da hafif choke'lu namluya
  uygun" diyor [N6, N8]. Hatsan namlularını "precision rifled, choked" olarak tanıtıyor
  [N10, N11]. Hatsan BullMaster sayfası "slug ve eteksiz mermiler düzgün beslenmez"
  diyor [N11].
- **Namlu boyu.** Daystate ve Brocock: "Slug için yalnızca 711 mm (28") namlular uygundur"
  [N5, N7]. Ayrıca slug barrel ayrı bir seçenek olarak satılıyor.
- **Güç ayarı.** FX, slug için ağır çekiç ve valfi daha uzun açık tutan "Slug Power Kit"
  satıyor. Impact M4 kılavuzunda transfer portu "P = saçma, S = slug" diye ayrılmış
  [N2, N4]. Yani slug için yalnız namlu değil, ayar da değişiyor.
- **Önemli bulgu: yiv adımı tek başına "saçma namlusu" demek değil.** Lothar Walther'in
  standart havalı tüfek namlu adımı **450 mm (1:17,7")** [N12, N13]. Kütüphanemizdeki
  rakamlar da bunu destekliyor: Effecto 1:17,7, Aselkon 1:15, Evanix 1:19. Bu tüfekler saçma
  için satılıyor, ama yivleri slug için de hızlı. Yani "saçma namlusu = 1:24–1:28" kuralı
  **genel bir kural değil**. FX'in filtresindeki 1:24–1:28 değerleri bu kuralın tek dayanağı.

**Saçma namlusunda slug atınca ne olur?**

- **Yiv yavaşsa slug yeterince dönmez.** Kararlılık sayısı Sg (Miller formülü) 1,3 altına
  düşünce BC belirgin azalır. 1,0 civarında mermi yalpalar ve yan girer (keyhole) [N23, N24].
- **Sizin slug'ınız için hesap** (.25, 50 gr, 985 fps, 15 °C, 1013 hPa):

| Slug boyu | 1:16 | 1:18 | 1:24 | 1:28 |
|---|---:|---:|---:|---:|
| 9 mm | 3,86 ✅ | 3,05 ✅ | 1,72 ✅ | 1,26 ⚠️ |
| 10 mm | 3,00 ✅ | 2,37 ✅ | 1,33 ⚠️ | **0,98 ❌** |
| 11 mm | 2,37 ✅ | 1,87 ✅ | **1,05 ⚠️/❌** | **0,77 ❌** |

  ✅ Sg ≥ 1,5 · ⚠️ 1,0–1,5 (uygulamanın sınırları) · ❌ < 1,0.
- **Okuma:** 1:16–1:18'de sorun yok. 1:24'te uzun slug sınırda kalır. 1:28'de 10 mm ve üstü
  slug **takla atabilir**. Bu durumda hesap sonucu (düşüş, rüzgâr) **anlamsızdır**: mermi
  hesaplanan yolu izlemez.
- **Choke'lu namlu:** Sert bir choke slug'ı sıkıştırır. Üreticiler bunu yalnızca "slug'da
  kötü" diye anlatıyor [N9]. Kaç cm dağılım yaptığına dair sayı yayımlanmamış.
- **Hollow point slug'lar için not:** Miller formülü dolu mermiler için çıkarıldı. Oyuk uçlu
  slug'da sonuç yaklaşıktır [N25, N26].

**Slug namlusunda saçma atınca ne olur?**

- Saçma büyük ölçüde **eteği sayesinde** kararlı uçar: ağırlık merkezi basınç merkezinin
  önündedir. Dönme bunu destekler [N20]. Bu yüzden hızlı yivde "takla" beklenmez.
- Choke'suz slug namlusu hafif saçmada daha az isabetli olabilir [N9]. Hızlı yivin saçmayı
  "aşırı döndürmesi" ile ilgili ölçüm bulunamadı.
- **Uygulamada:** yalnızca bilgi notu gösterilsin, hesap engellenmesin.

### Uygulama namlu tipini nasıl öğrensin? (en az hata ile)

İlke: kullanıcı yazmaz, listeden seçer. Veri kütüphaneden gelir.

1. **Kütüphaneden çıkar (varsayılan).**
   - Tüfeğin yiv adımı (`twistRateIn`) varsa onu kullan. Şu an yalnız 112 PCP satırında var
     (Aselkon, Effecto, Evanix).
   - Namlu açıklaması (`barrelType`) varsa onu kullan: "choked", "non-choked",
     "FX Superior Heavy STX" gibi.
   - Üretici namluyu adıyla "slug" diye satıyorsa (Daystate/Brocock "711 mm SLUG", FX
     "Superior Slug") tip **Slug**.
2. **Profil'de yeni seçim: "Namlu tipi"** (MenzilSelect, ⓘ açıklamalı). Seçenekler:
   - "Saçma namlusu"
   - "Slug namlusu"
   - "Her ikisi (karma)"
   - "Bilmiyorum"

   Kütüphane biliyorsa kutu dolu ve "kütüphaneden" gelir. Bilmiyorsa "Bilmiyorum" seçili
   kalır.
3. **"Namlu değiştirildi" seçeneği.** Örnek: sizin Hercules + FX 80 cm. Seçilince şu listeler
   açılır:
   - **Namlu markası:** FX, Lothar Walther, Hatsan (orijinal), Listede yok.
   - **Liner:** Superior, Superior Heavy, Superior Slug.
   - **Yiv adımı:** 1:16, 1:18, 1:24, 1:25, 1:28, 1:40, Bilmiyorum.
   - **Choke:** Var, Yok, Bilmiyorum.
   - **Namlu boyu:** 300 … 800 mm.

   FX adımı yayımlamadığı için adım **liner üzerindeki işaretten** seçilir. Seçilmezse
   "Bilmiyorum" kalır. Stok tüfeğin kütüphane verisi (yiv, boy, choke) bu durumda kullanılmaz.
4. **Mühimmat uzunluğu kütüphaneden gelir.** 257 PCP slug satırının 153'ünde uzunluk var.

**Kural seti (öneri; kod yazılmadı):**

| Durum | Ne gösterilir |
|---|---|
| Slug + Sg < 1,0 | 🔴 Kırmızı uyarı. Sonuç tablosu soluk ve "Güvenilmez" etiketli |
| Slug + 1,0 ≤ Sg < 1,5 | 🟠 Mevcut "Kararlılık sınırda" uyarısı (değişmez) |
| Slug + yiv adımı bilinmiyor | 🟠 "Kararlılık hesaplanamadı" |
| Slug + namlu tipi "Saçma namlusu" | 🟠 Sg iyi çıksa da uyarı, çünkü choke/profil slug'a uygun olmayabilir |
| Slug + namlu "choked" (kütüphaneden) | 🟡 Bilgi notu |
| Saçma + namlu tipi "Slug namlusu" | 🟡 Bilgi notu, hesap normal |
| Saçma + hız > 900 fps veya mesafe > 100 m | 🟡 "G1 tahmini" notu |
| Slug veya saçma, BC atışla doğrulandı | Uyarılar kalır, "tahmini" etiketi kalkar |

BC **kendiliğinden düşürülmez** (mevcut politika, `stability.dart`). Dağılımı büyütmek
için sayısal bir model kaynakta yok, bu yüzden sayı uydurulmaz. Sadece uyarı gösterilir.

**Önerilen Türkçe metinler** (kısa mesaj + ⓘ):

- 🔴 *Mesaj:* "Slug bu namluda kararsız: Sg {sg}. Sonuçlar güvenilmez."
  *ⓘ:* "Yiv adımı bu slug için yavaş. Slug yeterince dönmez, yalpalar ve yan girebilir.
  Hesaplanan düşüş ve rüzgâr sapması bu durumda geçerli değildir. Daha kısa ya da hafif bir
  slug seçin veya slug namlusu kullanın. Örnek: 50 gr 10 mm .25 slug, 1:28 yivde Sg 0,98."
- 🟠 *Mesaj:* "Yiv adımı bilinmiyor: slug kararlılığı hesaplanamadı."
  *ⓘ:* "Slug'ın düzgün uçması namlunun yiv adımına bağlıdır. Adımı tüfeğin kılavuzundan
  veya namlu/liner üzerindeki işaretten bulup Profil'de seçin (ör. 1:18). Seçilene kadar
  sonuçlar kontrol edilmemiş sayılır."
- 🟠 *Mesaj:* "Saçma namlusunda slug: isabet ve BC düşebilir."
  *ⓘ:* "Bu namlu üreticisince saçma için yapılmış. Choke'lu namlu slug'ı sıkıştırabilir.
  Üreticiler slug için choke'suz ya da hafif choke'lu namlu öneriyor. 50 m'de kâğıda atıp
  delikler yuvarlak mı bakın ve BC'yi atışla doğrulayın."
- 🟡 *Mesaj:* "Slug namlusunda saçma: isabeti atışla kontrol edin."
  *ⓘ:* "Saçma eteği sayesinde dengede uçar, hızlı yivde takla atmaz. Ama choke'suz namluda
  hafif saçmalar daha az isabetli olabilir. Hesap normal yapılır."
- 🟡 *Mesaj:* "Saçma için G1 tahmini: 100 m üstünü atışla doğrulayın."
  *ⓘ:* "Diabolo saçmanın sürüklenme eğrisi PCP hızlarında ölçülmemiştir. Uygulama G1
  kullanır. 100 m'ye kadar fark birkaç santimdir. 150 m'de ve 900 fps üstünde 10–25 cm'ye
  çıkabilir. BC'yi 50 m'de, sonucu 100 ve 150 m'de atışla kontrol edin."
- ⓘ **Namlu tipi** (Profil): "Slug namlusu slug için yapılmış namludur. Yivi hızlıdır
  (genelde 1:16–1:18) ve choke'u yoktur ya da hafiftir. Üretici bunu ürün adında yazar, ör.
  'Superior Slug' ya da '711 mm SLUG'. Bilmiyorsanız 'Bilmiyorum' seçin."
- ⓘ **Yiv adımı** (değiştirilmiş namlu): "Merminin bir tam tur dönmesi için gereken namlu
  uzunluğu, inç olarak. Namlu veya liner üzerinde ya da kutusunda yazar. Örnek: 1:18 = 18
  inçte bir tur. Küçük sayı daha hızlı döndürür."
- ⓘ **Choke**: "Namlunun ağız ucundaki hafif daralmadır. Saçmada isabeti artırabilir,
  slug'ı ise sıkıştırır. Üretici sayfasında 'choked' ya da 'choke'suz' diye yazar."

### Sizin tüfeğiniz için (Hercules + FX 80 cm)

- Hatsan Hercules'in stok namlusu "precision rifled, choked" ve yiv adımı yayımlanmamış [N10].
- FX 800 mm liner'ın adımı FX metninde yok [N1].
- FX'in .25 parça şemalarında 600/700 mm uzunluklar "Superior Heavy" liner [N3]. Bu, 800 mm
  için de benzer olabilir, **ama doğrulanmadı**. Liner üzerindeki işaret okunmalı.
- **Adım 1:16–1:18 çıkarsa** 50 gr slug'ınız 11 mm boya kadar rahat kararlıdır.
- **Adım 1:24 çıkarsa** 10 mm'nin üstü sınırdadır.
- **Adım 1:25 / 1:28 çıkarsa** 10 mm'lik slug takla riski taşır.

---

## English details

### 1. Slug barrel vs pellet barrel: what manufacturers publish

| Maker | What it says | Src |
|---|---|---|
| FX | Liner families: Superior "for both traditional pellets and lighter slugs"; Superior Heavy "optimized for stabilizing both heavy pellets and high-BC slugs"; Superior Slug "specifically designed to shoot slugs only … optimized twist rate and rifling profile". Twist filter 1:16, 1:18, 1:24, 1:25, 1:28, 1:40; no twist per liner/calibre in static text; no choke or material statement | N1 |
| FX | Impact M4 manual: standard liner "mainly for pellets and hybrid slugs"; transfer port "P = pellet, S = slug" | N2 |
| FX | Panthera 600/700 use Superior Heavy as standard; Panthera 500 Superior "shoots both pellets and light weight slugs"; .25 parts lists 600/700 mm Superior Heavy | N3 |
| FX | Slug Power Kit: hammer-weight spacers + lighter valve return spring so the valve "stays open slightly longer" for heavier slugs | N4 |
| FX | Halo slug "performs flawlessly out of our existing 30cal Superior and Superior Slug liners" | N14 |
| Daystate | Calibre-change kits: "Only 711mm (28in) barrels are suitable for Slug Projectiles"; Blackwolf "optional 711mm slug barrel"; Delta Wolf UK version "twist rate more suitable for lower velocities" (no number) | N5 |
| Daystate | Juggernaut slugs "particularly suited to unchoked (or lightly-choked) barrels, such as our 23″/600mm polygon A.R.T barrel" | N6 |
| Brocock | BRK Ghost: "Only 711mm (28in) barrels are suitable for Slug Projectiles"; dedicated 28″ slug barrel for HP model | N7 |
| Brocock | Juggernaut: "unchoked (or lightly-choked) barrels" | N8 |
| AEA | "Seriously chocked barrel is good at shooting the lighter type of diabolo … SLUG pellets are worse"; progressive choke ≈ 0.001 in over ~10 in "better compatible with two kinds"; top barrels "totally without any chocks" | N9 |
| Hatsan | Hercules manual: barrel 585 mm, twist not stated; product pages "precision rifled and choked" | N10 |
| Hatsan | BullMaster: "Slugs or other non-skirted rounds will not cycle properly" | N11 |
| Lothar Walther | Airgun blanks: standard / polygon, with or without choke; twists 356, 406, 450, 508, 762, 915 mm; most blanks 450 mm (17.7″); 4.5 mm choked blank: bore 4.46 / groove 4.62 mm, 12 grooves, choke 0.04 mm, C35 steel; stainless LW6 choked blanks .177/.22/.25 at 450 mm. No "slug" category | N12, N13 |
| Crosman | Benjamin Bulldog .357: 1:14 RH, 6 lands/grooves | N15 |
| H&N | Slugs come in several diameters "to accommodate different barrel profiles"; energy minimum/recommendation; no twist or choke advice | N16 |
| Zan | .177 slugs "suiting most .177 barrels"; no twist/choke requirement found on official pages | N17 |
| Weihrauch | HW 110 manual: "use only high quality Diabolo / waisted pellets" | N18 |
| App library | PCP twist values present only for Aselkon (15″), Effecto (17.7″), Evanix (19″): 112 of 906 PCP rows | N19 |

**Conclusions.**

- No manufacturer publishes a numerical "pellet barrel 1:xx vs slug barrel 1:yy" pair.
- The published distinguishing features are:
  - the product name or variant (FX "Superior Slug", Daystate/Brocock "711 mm SLUG");
  - choke (none or light for slugs);
  - length (Daystate/Brocock: 711 mm);
  - power tune (FX slug kit, slug port).
- The common pellet twist is about 17.7″ (Lothar Walther 450 mm), which is already fast
  enough for many slugs. Twist alone therefore cannot classify a barrel. Choke and the maker's
  label matter as much.
- Not found: rifling depth, land/groove shape for slug versus pellet, liner material, FX twist
  per liner, Hatsan or Kral twist rates, and official Huben, Kral slug-barrel, Reximex, Ataman,
  Edgun or Taipan statements.

### 2. Physics and what the app should do

**Slug in a slow-twist (pellet) barrel.**

- Sg < 1.0 tumbles. The BC falls significantly below Sg 1.3, and Sg > 1.3 is "probably ample
  margin" [N23, N24]. The app uses 1.0 and 1.5 (`lib/core/stability.dart`).
- The Miller rule assumes uniform density and solid bullets. It underestimates open-tip
  stability [N25, N26], so for hollow-point slugs it is conservative but approximate.
- Owner slug: .25 (d = 0.249 in), 50 gr, 985 fps, 59 °F, 29.92 inHg. Sg computed with
  `tools/formula_reference.miller_sg`, at the actual V / at V = 1116 fps (speed of sound,
  per N25's note that the velocity factor below the speed of sound takes its sonic value):

| Length | 1:16 | 1:18 | 1:24 | 1:28 |
|---|---:|---:|---:|---:|
| 9 mm | 3.86 / 4.02 | 3.05 / 3.18 | 1.72 / 1.79 | 1.26 / 1.31 |
| 10 mm | 3.00 / 3.13 | 2.37 / 2.47 | 1.33 / 1.39 | 0.98 / 1.02 |
| 11 mm | 2.37 / 2.47 | 1.87 / 1.95 | 1.05 / 1.10 | 0.77 / 0.81 |

  Slowest twist for Sg 1.5 (Sg 1.3): 9 mm 1:25.7 (1:27.6); 10 mm 1:22.6 (1:24.3); 11 mm 1:20.1
  (1:21.6).
- Published H&N slugs (lengths from H&N [N16]; V assumed):

| Slug | V | 1:16 | 1:17.7 | 1:18 | 1:24 | 1:28 |
|---|---:|---:|---:|---:|---:|---:|
| H&N Slug HP .22 21 gr, 6.7 mm | 900 | 2.59 | 2.12 | 2.05 | 1.15 | 0.85 |
| H&N Slug HP II .25 36 gr, 8.3 mm | 950 | 3.31 | 2.70 | 2.61 | 1.47 | 1.08 |
| H&N Slug HP .177 20 gr, 8.4 mm | 950 | 1.10 | 0.90 | 0.87 | 0.49 | 0.36 |

  The long .177 20 gr slug is marginal even at 1:16. Length per calibre matters more than
  weight.
- **Choke.** AEA states choke hurts slugs [N9]. Daystate and Brocock recommend unchoked or
  lightly choked barrels [N6, N8]. No academic source quantifying choke swaging of lead
  projectiles or the dispersion it causes was found. Report it qualitatively only.

**Pellet in a fast-twist (slug) barrel.**

- The diabolo has its centre of mass ahead of its centre of pressure (drag-stabilised), and
  spin from the rifling adds gyroscopic stability [N20]. Miller's rule does not apply to
  pellets (earlier repo research, `pellet_slug_hassas_hesap.md` B.3).
- No source on pellet over-spin was found. AEA suggests that unchoked barrels suit light
  diabolos less [N9]. Show this as information only.

**Effect on output.**

- Do not alter BC or the trajectory automatically.
- Gate the *presentation*:
  - Sg < 1.0 for a slug → mark the whole solution "Güvenilmez".
  - Unknown twist → "not checked".
  - Pellet-only barrel with a slug → caution, even when Sg ≥ 1.5, because choke and profile
    are not in Sg.
- There is no sourced dispersion model, so no numerical dispersion increase is added.

### 3. Learning the barrel type with the least error-prone input

Proposed data, as a draft. No code was written.

- `Rifle.barrelKind` enum: `pellet`, `slug`, `hybrid`, `unknown`. It is derived from the
  library:
  - The name or variant contains "Slug" → `slug`. Examples: FX Superior Slug, Daystate and
    Brocock 711 mm SLUG.
  - "Superior Heavy" or "Superior" → `hybrid` [N1, N3].
  - Hatsan "precision rifled, choked" → `pellet` (BullMaster statement [N11]; maker labels its
    barrels choked [N10]).
  - Everything else → `unknown`.
- `Rifle.choke` enum: `yes`, `no`, `unknown`. It is parsed from the existing `barrelType`
  strings ("choked", "non-choked").
- `twistRateIn` comes from the library. Otherwise it is picked from a list. Free typing is
  allowed only after "Listede yok".
- "Namlu değiştirildi" (modified barrel):
  - Barrel make list: FX, Lothar Walther, original, Listede yok.
  - FX liner list: Superior, Superior Heavy, Superior Slug.
  - Twist list: the FX filter values [N1] plus 1:17.7 [N12] and "Bilmiyorum".
  - Choke list: var / yok / bilmiyorum.
  - Length list: the FX lengths 300–800 mm [N1].
  - The stock library twist, choke and length are then ignored.
- Ammo length comes from `bullet_library.dart`: 153 of 257 PCP slugs have `lengthMm`. If it
  is missing, the Sg check reports "not checked" instead of guessing.

The rule table and the Turkish texts are in the Turkish section above.

### 4. Item A: drag data for diabolo pellets

| Source | Method | Range | Numbers |
|---|---|---|---|
| Ladommatos 2019 [N20] | Wind tunnel, non-spinning, 4.5 mm | Ma ≈ 0.58 only | Cd: dome 0.422, flat 0.561, cone 0.668, cavity 0.714, sphere 0.510 |
| Ladommatos 2021 [N21] | Wind tunnel, 31 pellets | 200 m/s; three pellets at 120–200 m/s | Cd 0.36–0.78; speed changes Cd "very little" |
| Rafeie & Teymourtash 2016 [N22] | 2-D CFD, 4.5 mm | M 0.7 / 1.0 / 1.3 | Graphs only; pressure drag rises with Mach (full text robots-disallowed, not re-read) |
| Courtney et al. [N27] | Free-flight chronographs | 480–790 ft/s | G1 BCs only |
| Courtney et al. [N28] | Doppler | — | BBs and bullets, no pellets |
| Shuttlecock literature (Aston, WSU) | Wind tunnel / free flight | < Mach 0.3 | Incompressible, not usable for Mach 0.6–0.9 |
| GA / GA2 | — | — | Only in ballistics apps and forums; no primary definition found |

**Conclusion.** No measured Cd–Mach curve for diabolo pellets exists for about Mach 0.5–0.9 in
allowed sources. A better model than G1 cannot be justified today.

**Size of possible G1 shape error** (computed). The setup:

- Flat fire, ICAO air, zero 40 m, sight 50 mm, 4 m/s full-value wind.
- Each alternative's BC is matched to G1's time of flight to 50 m.
- The alternatives are a flat Cd (G1's Cd at Ma 0.58, extending N21's "nearly constant") and
  the BRL sphere table GS (steeper rise).
- G7, also tried, falls almost exactly on the flat case.
- Values are the alternative minus G1, in cm; + means more drop or drift.

| Load | MV fps (Mach) | Drop 100 m flat / GS | Drop 150 m flat / GS | Wind 150 m flat / GS | BC −10 % drop 100 / 150 m |
|---|---|---:|---:|---:|---:|
| .177 8.44 gr BC 0.021 | 700 (0.63) | −0.6 / −2.0 | −10.0 / −22.7 | −8.4 / −17.3 | +10.5 / +61.6 |
| | 800 (0.72) | +0.7 / −1.8 | +2.3 / −19.4 | +0.3 / −16.7 | +7.9 / +45.8 |
| | 900 (0.81) | +2.3 / −1.0 | +17.0 / −12.5 | +12.9 / −12.5 | +6.4 / +36.5 |
| | 950 (0.85) | +3.4 / −0.3 | +26.7 / −7.5 | +21.6 / −8.5 | +5.9 / +33.5 |
| .22 18.13 gr BC 0.035 | 700 (0.63) | 0.0 / −0.6 | −0.6 / −5.1 | −0.9 / −4.9 | +4.3 / +20.5 |
| | 800 (0.72) | +0.5 / −0.5 | +3.1 / −4.6 | +2.8 / −5.0 | +3.3 / +15.6 |
| | 900 (0.81) | +1.1 / 0.0 | +8.1 / −1.4 | +8.5 / −2.2 | +2.8 / +12.7 |
| | 950 (0.85) | +1.5 / +0.3 | +11.7 / +1.0 | +12.8 / +0.3 | +2.6 / +11.8 |
| .25 25.4 gr BC 0.045 | 700 (0.63) | +0.1 / −0.3 | +0.1 / −2.7 | −0.1 / −2.8 | +3.0 / +13.4 |
| | 800 (0.72) | +0.3 / −0.3 | +2.3 / −2.4 | +2.3 / −2.8 | +2.3 / +10.3 |
| | 900 (0.81) | +0.7 / +0.1 | +5.4 / −0.1 | +6.2 / −0.5 | +2.0 / +8.5 |
| | 950 (0.85) | +1.0 / +0.3 | +7.7 / +1.6 | +9.3 / +1.4 | +1.8 / +7.9 |

Cd (app tables) for reference:

| Mach | G1 | G7 | GS |
|---|---:|---:|---:|
| 0.5 | 0.2032 | 0.1194 | 0.4970 |
| 0.6 | 0.2034 | 0.1194 | 0.5260 |
| 0.7 | 0.2165 | 0.1202 | 0.5920 |
| 0.8 | 0.2546 | 0.1242 | 0.6610 |
| 0.9 | 0.3415 | 0.1464 | 0.7370 |

These are sensitivity brackets, not errors against a measured truth.

- **Up to 100 m:** the shape effect is ≤ 3.4 cm in drop and ≤ 5.7 cm in wind (.177 at
  950 fps), and ≤ 1.5 cm for .22 and .25. The BC uncertainty dominates.
- **At 150 m with MV ≥ 900 fps:** the shape effect reaches 8–27 cm.

Recommendation:

1. Keep G1 with the maker's BC.
2. True the BC at 50 m (chronograph near/far or drop), then verify at 100 and 150 m.
3. Label results beyond 100 m, or with MV above 900 fps, as "G1 tahmini".
4. Do not add GA/GA2 or a pellet table until a measured Mach 0.5–0.9 curve with reuse
   permission is published.

---

## Source table

Accessed 2026-10-13 unless noted. "robots" means robots.txt was respected: either read
directly, or enforced by the fetch tool, which refused disallowed pages.

| # | Source | Type | URL |
|---|---|---|---|
| N1 | FX Airguns — Liners (Superior / Superior Heavy / Superior Slug; twist and length filters) | Manufacturer | https://www.fxairguns.com/accessories/barrels/liners/ |
| N2 | FX Impact M4 Owner's Manual (PDF) | Manufacturer manual | https://www.fxairguns.com/media/qlkcvvrf/fx-impact-m4.pdf |
| N3 | FX Panthera (legacy) page; FX Panthera barrel schematic (PDF) | Manufacturer | https://www.fxairguns.com/legacy-rifles/fx-panthera/ · https://www.fxairguns.com/media/5z4nwfee/fx-panthera-barrel.pdf |
| N4 | FX Slug Power Kits | Manufacturer | https://www.fxairguns.com/accessories/accessories/slug-power-kits/ |
| N5 | Daystate barrel calibre-changing kit; Blackwolf; Blackwolf barrel kit; Delta Wolf | Manufacturer | https://daystate.com/product/barrel-caliber-changing-kit/ · https://daystate.com/rifles/blackwolf/ · https://daystate.com/daystate-blackwolf-barrel-caliber-changing-kit/ · https://daystate.com/rifles/delta-wolf/ |
| N6 | Daystate — Rangemaster Juggernaut | Manufacturer | https://daystate.com/product/juggernaut-pellet/ |
| N7 | Brocock BRK Ghost calibre kit; BRK Ghost | Manufacturer | https://brocock.co.uk/product/brk-ghost-barrel-caliber-changing-kit/ · https://brocock.co.uk/brocock-brk-ghost/ |
| N8 | Brocock — Rangemaster Juggernaut slugs | Manufacturer | https://brocock.co.uk/product/rangemaster-juggernaut-airgun-slugs/ |
| N9 | AEA — Barrel technology | Manufacturer | https://www.aeaairgun.com/Technology/Barrel |
| N10 | Hatsan Hercules Owner's Manual (PDF, Hatsan USA); Hatsan Factor RC page | Manufacturer | https://hatsanairgunsusa.com/wp-content/uploads/2018/12/Hercules_Manual_EN.pdf · https://hatsanairgunsusa.com/product/factor-rc/ |
| N11 | Hatsan BullMaster | Manufacturer | https://hatsanairgunsusa.com/product/bullmaster/ |
| N12 | Lothar Walther — airgun barrel blanks (categories, twist filter) | Barrel manufacturer | https://www.lothar-walther.de/en/barrel-blank/airgun/ |
| N13 | Lothar Walther — LLC-45-14-605 choked 4.5 mm blank; stainless choked blanks | Barrel manufacturer | https://www.lothar-walther.de/en/airgun-blank-choked-4-5mmluft-177air-choke-twist-450-mm-od-14-mm-l-605-mm-precision-steel-tube-c35/llc-45-14-605 · https://www.lothar-walther.de/en/barrel-blank/airgun/stainless/choked/ |
| N14 | FX Halo | Manufacturer | https://www.fxairguns.com/accessories/ammunition/fx-halo/ |
| N15 | Crosman support — Benjamin Bulldog .357 barrel specs | Manufacturer | https://support.crosman.com/hc/en-us/articles/204248930-What-are-the-barrel-specifications-of-the-Benjamin-Bulldog-357 |
| N16 | H&N Slug HP .22 21 gr; Slug HP II .22 30 gr; Slug HP II .25 36 gr; Slug HP .177 20 gr | Manufacturer | https://www.hn-sport.de/en/air-gun-hunting/slug-HP-22-21gr · https://www.hn-sport.de/en/air-gun-hunting/slug-HP-22-30gr · https://www.hn-sport.de/en/node/767 · https://hn-sport.de/en/node/795 (last two via earlier repo research, 2026-10-12) |
| N17 | Zan Projectiles — .177 slugs | Manufacturer | https://zanprojectiles.com/shop/17-4-5mm-slugs/ |
| N18 | Weihrauch HW 110 manual (PDF) | Manufacturer manual | https://www.weihrauch-sport.de/wp-content/uploads/2024/05/HW-110-de-engl.-fr.-03-2024-1.pdf |
| N19 | `lib/data/rifle_library.dart` (each row carries its maker URL) | Repo | — |
| N20 | Ladommatos N., "Influence of air rifle pellet geometry on aerodynamic drag", Proc. IMechE Part P, 2019, doi:10.1177/1754337119831107 | Peer-reviewed | https://discovery.ucl.ac.uk/id/eprint/10072258 |
| N21 | Ladommatos N., "Drag coefficients of air rifle pellets with wide range of geometries", Proc. IMechE Part C, 2021, doi:10.1177/0954406221991190 (abstract) | Peer-reviewed | https://doi.org/10.1177/0954406221991190 |
| N22 | Rafeie M., Teymourtash A.R., "Aerodynamic and dynamic analyses of three common 4.5 mm-caliber pellets in a transonic flow", Scientia Iranica B 23(4), 2016 (cited from earlier repo research; domain robots-disallowed today) | Peer-reviewed (CFD) | https://scientiairanica.sharif.edu/article_3924.html |
| N23 | Courtney E.R., Courtney M.W., "Aerodynamic Drag and Gyroscopic Stability", arXiv:1309.5039 | Scientific preprint | https://arxiv.org/pdf/1309.5039 |
| N24 | McCoy R.L., "Aerodynamic Characteristics of Caliber .22 Long Rifle Match Ammunition", BRL-MR-3877, 1990 (via earlier repo research) | US Army BRL | https://apps.dtic.mil/sti/pdfs/ADA229713.pdf |
| N25 | Courtney M., Miller D., "A Stability Formula for Plastic-Tipped Bullets, Part 1", arXiv:1410.5340 (Miller rule; original: Miller, *Precision Shooting*, Mar 2005) | Scientific preprint | https://arxiv.org/pdf/1410.5340 |
| N26 | Courtney E., Courtney M., "Gyroscopic Stability of Open Tipped Match Style Rifle Bullets", arXiv:1401.4187 | Scientific preprint | https://arxiv.org/abs/1401.4187 |
| N27 | Courtney E., Courtney A., Courtney M., "Methods for Accurate Free Flight Measurement of Drag Coefficients", arXiv:1503.05504 | Scientific preprint | https://arxiv.org/pdf/1503.05504 |
| N28 | Courtney E., Morris C., Courtney M., "Accurate Measurements of Free Flight Drag Coefficients with Amateur Doppler Radar", arXiv:1608.06500 | Scientific preprint | https://arxiv.org/pdf/1608.06500 |
| N29 | `tools/formula_reference.py` (Miller Sg; G1/G7/GS tables from `lib/core/standard_drag_tables.dart`) | Repo | — |

**Not read or not found:**

- JSB official site (robots.txt).
- Two Weihrauch pages (robots).
- Scientia Iranica and Modares PDFs (robots).
- Springer doi:10.1007/s00414-016-1415-3 (HTTP 429).
- Some Lothar Walther detail pages and DTIC reports (fetch errors).
- Official twist or choke data for Kral, Huben, Reximex, Ataman, Edgun, Taipan and Umarex.
- FX twist per liner.
- Hatsan twist.
- Any academic source on choke swaging or pellet over-spin.
