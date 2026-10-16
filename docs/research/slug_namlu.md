# Slug ve namlu: namlunun atışa etkisi, formüle nasıl girer?

Tarih: 2026-10-16 (İstanbul) · Zamanlanmış görev (sahibi çevrimdışı) · Dal: `research/slug-namlu`
**Yalnızca araştırma.** `lib/`, `test/`, `ios/`, `garmin/` değişmedi.

Bu rapor `namlu_tipi_pellet_surukleme.md` (2026-10-13, kaynaklar [N…]) ve
`pellet_slug_hassas_hesap.md` (2026-10-12, kaynaklar [S…]) üzerine kurulur. Orada kurulanlar
tekrarlanmaz. Yeni kaynaklar [K1 …] en alttaki tabloda. Alıntılar kaynağın kendi dilinde,
en çok 15 kelime. Okuma tarihi hepsinde 2026-10-16.

**Araç notu:** Bu ortamda Exa ve Firecrawl araçları **yoktu** (MCP bağlı değil, API anahtarı
yok). Arama ve okuma, aynı kaynak kurallarıyla WebSearch/WebFetch ile yapıldı. fxairguns.com'un
JavaScript ile yüklenen liner tablosunu tarayıcıyla açma denemesi ağ vekilinde engellendi
(ERR_TUNNEL_CONNECTION_FAILED).

**robots.txt:** Atlananlar: aeaairgun.com (bugün robots ile kapalı; önceki raporun [N9] AEA
alıntısı bugün yeniden okunmadı, bu rapor ona yeni bir şey eklemiyor), jsb-match.com,
weihrauch-sport.de. nielsenspecialtyammo.com ve ataman-guns.com okunmadı (izin isteği zaman
aşımı). fxairguns.com robots.txt boş döndü; lothar-walther.de/.com robots.txt alınamadı (hata,
yasak değil). Ayrıntı en altta.

---

## Özet (sahibi için)

1. **FX liner yiv adımları hâlâ bilinmiyor.** FX'in hiçbir sayfası, kılavuzu, parça listesi
   ya da patenti "şu liner = şu adım" demiyor. Liner sayfasındaki ürün tablosu boş geliyor
   ("No matching variants found"); yalnızca filtre değerleri var (1:16, 1:18, 1:24, 1:25, 1:28,
   1:40). Üstelik FX'in kendi PDF'leri **aynı parça numarasına** bir yerde "Superior", başka
   yerde "Superior Heavy" diyor [K1–K3]. Sonuç: adım, **liner üzerindeki işaretten** okunmalı
   ya da FX'e sorulmalı. Uygulamaya FX adımı yazılmamalı.
2. **Diğer üreticiler de slug namlusunun adımını yazmıyor** (Daystate, Brocock, Hatsan, Air
   Arms, Kral, Reximex, Edgun, Umarex). Yeni sayılar yalnızca Lothar Walther'den: .30 namlu
   **16"**, .177 poligon choke'lu namlu **36" (915 mm)**, diğerleri 17,7" [K5, K6]. Crosman 66
   için 1:16 [K15].
3. **Choke'un slug'a sayısal etkisi: kabul edilen hiçbir kaynakta ölçüm yok.** Ne üretici
   (grup, hız kaybı) ne de akademik çalışma slug veya saçma için sayı veriyor. En yakın ölçüm
   ordu raporu: kurşun değil, **ceketli 7,62 mm** mermi, namlu ucuna takılan dar bir parça ile
   [K20]. Bore'dan %1 dar: hız −%1,4, dağılım yaklaşık 1,3–1,7 kat. %3,4 dar: hız −%3,8,
   dağılım >1 mil. Bu sayılar slug'a **aktarılamaz** (farklı malzeme, hız, choke biçimi).
   Fiziksel olarak kaynaklar şunu söylüyor: choke mermiyi **biraz inceltir ve uzatır**
   (patent [K21]); av tüfeği slug'ının oyuk tabanı "choke'tan geçerken sıkışabilsin" diye
   yapılmış [K22].
4. **Namlu boyu → hız:** Üretici tabloları güç **üst sınırı** veriyor, aynı mermiyle ölçüm
   değil. Daystate 600 → 711 mm: enerji +%8–10, aynı mermi varsayılırsa hız yaklaşık +%4–5
   [K7]. PCP için yayımlanmış bir "boy → hız" formülü yok. **Ölçülen hız** tek doğru girdi.
5. **Slug çapı:** Zan: "FX liners prefer diameter .217" [K12]. H&N ve Zan çapı "namlu
   profiline göre" seçtiriyor (.217/.218/.219) ama sayısal bir kural vermiyor [K10–K13].
   Poligon/klasik yiv, geçiş (transition) ve namlu ağzı (crown) için slug'a özel sayı yok.
6. **Formüle ne girer?**
   - **Yiv adımı** → Miller Sg → kararlılık uyarısı, spin sapması, aerodinamik sıçrama
     (zaten var). Yeni alan gerekmez.
   - **Namlu boyu, choke, yiv profili, slug çapı, crown** → formüle **doğrudan giremez**.
     Etkileri yalnızca **ölçülen hız** (En düşük / En yüksek kutularının ortalaması) ve
     **ölçülen grup çapı** (isabet olasılığı) üzerinden girer. Bu yüzden bunlar için **form
     alanı önerilmez** (sahibin kuralı). Önceki rapordaki "Choke: Var/Yok/Bilmiyorum" ve
     "Namlu boyu" seçimleri hesapta kullanılamadığı için bu kurala göre **eklenmemeli**.
7. **Bilinmeyenler:** FX adım eşlemesi, choke'un slug'daki sayısal etkisi, PCP boy–hız ilişkisi,
   slug çapının hız/isabete etkisi, poligon yivin kurşunda etkisi, crown hasarının sayısal
   etkisi.

---

## 1. Yiv adımı: üretici, ürün, kalibre

| Üretici | Ürün | Kalibre | Adım | Choke | Kaynak |
|---|---|---|---|---|---|
| FX | STX Superior / Superior Heavy / Superior Slug liner | .177–.35 | **yazılmamış**; filtrede 1:16, 1:18, 1:24, 1:25, 1:28, 1:40 | yazılmamış | K1: "specific rifling and twist rates to ensure maximum precision" |
| FX | Panthera 500 / 600–700 | — | yazılmamış | yazılmamış | K2: "utilize the FX Superior Heavy STX barrel liner as standard" |
| FX | Dynamic / Panthera MKII liner tablosu | .177–.30, 300–700 mm | yazılmamış | yazılmamış | K3 (parça numaraları, adım yok) |
| FX | STX sistemi genel | — | — | — | K4: "to allow for different twist rates and other bore specifications" |
| Lothar Walther | Airgun blank, klasik, choke'lu | .177 / .20 / .22 / .25 | **17,7" (450 mm)** | var, miktar yok | K5 |
| Lothar Walther | Airgun blank, klasik, choke'lu | **.30** | **16"** | var | K5 |
| Lothar Walther | Poligon, choke'lu | .177 | 450 mm ve **915 mm (36")** | var | K6: "(Polygon, Choke)" |
| Lothar Walther | Poligon, choke'lu | .22 / .25 | 450 mm | var | K6 |
| Daystate | Wolf serisi 711 mm slug namlusu | .177–.30 | yazılmamış | yazılmamış | K7: "Only 711mm (28in) barrels are suitable for slug projectiles." |
| Daystate | Delta Wolf UK | — | sayı yok | — | K8: "a twist rate more suitable for lower velocities" |
| Brocock | BRK Ghost HP 28" | .177–.30 | yazılmamış | yazılmamış | K9: "28” barrel is available to shoot slugs OR pellets (not both)" |
| Hatsan | Factor Sniper Long, 30" | .22–.35 | yazılmamış | var, miktar yok | K16: "Precision rifled and choked barrel" |
| Kral | Puncher serisi | — | yazılmamış | var | K17: "Kral-built choked, rifled barrel." |
| Air Arms | S510 | .177–.25 | yazılmamış (Lothar Walther namlu) | yazılmamış | K18 |
| Reximex | Daystar | .177–.25 | yazılmamış | yazılmamış | K19 |
| Crosman | 66 (saçma tüfeği, karşılaştırma) | .177 | **1:16**, 10 yiv, sağ | — | K15: "Right Hand twist, 1 in 16 inches" |
| Crosman | Benjamin Bulldog .357 | .357 | 1:14 (önceki rapor N15) | — | N15 |

Notlar:

- **FX parça numaraları çelişkili:** Art. 19965 (.22 500 mm) ve 19976 (.25 500 mm) bir PDF'te
  "Superior", Panthera PDF'inde "Superior Heavy". 20369 (.30 500 mm) için de aynı çelişki var.
  19966/19967 (600 mm) bir PDF'te "Superior", X-Barrel PDF'inde "Pellet A" [K2, K3]. Yani parça
  numarasından liner tipi bile kesin çıkmıyor.
- FX Halo: başlık "Any Liner, Any Twist Rate"; sayı yok (önceki N14).
- Daystate'in bayi rehberi PDF'i (daystate.com üzerinde) 17" ve 23" Delta/Red Wolf'u da
  "Suitable for slugs" diye işaretliyor. Bu, kit sayfasındaki "yalnız 711 mm" ile çelişiyor
  [K7, K8b].
- Huben, Ataman, Taipan, Steyr, Edgun, Umarex: resmî adım bulunamadı.

**Sahibin tüfeği için:** Lothar Walther'in standart 17,7"'ı ile önceki raporun tablosu
(1:18 sütunu) neredeyse aynıdır: 50 gr .25 slug 11 mm boya kadar kararlı. FX 80 cm liner'ın
adımı hâlâ işaretten okunmalı.

## 2. Choke ve slug

**Sayısal ölçüm var mı?** Slug ya da saçma için: **yok.** Üreticiler yalnız nitel konuşuyor
(önceki N6, N8, N9). Akademik ve patent taramasında kurşun mermi + choke için ölçüm bulunamadı.
Bulunanlar başka mermi türünde:

| Kaynak | Ne ölçüldü | Sayılar | Slug'a aktarılır mı? |
|---|---|---|---|
| K20 ARL-TR-6557 (ABD Ordusu, 2013), M240B 7,62 mm, **ceketli** | Namlu ucuna ~3" yivsiz, daraltılmış parça (bore ≈ 0,308") | 0,305" (−%1): 2778 vs 2818 ft/s (−%1,4); dağılım 0,36×0,40 vs 0,21×0,32 mil. 0,2975" (−%3,4): 2711 ft/s (≈ −100 ft/s); dağılım ">1 mil" (5 atış). Mermiler sağlam çıktı | **Hayır.** Malzeme, hız ve choke biçimi farklı. Yalnız yön gösterir: daralma büyüdükçe hız düşer, dağılım artar |
| K21 US 4,660,312 (patent) | Yivli namluda ağız tarafında yivsiz, oluk çapından 0,0006–0,0008" dar bölüm | Ölçüm yok. "projectile will be squeezed down slightly in diameter and elongated" | Fiziksel mekanizma: incelme + uzama |
| K23 US 4,527,348 (patent) | .30-06'da kalibre altı "hizalama" bölümü | Hız: 2654/2661, 2631/2627, 2716/2730 ft/s (fark yok); grup yok | Küçük daralma hızı ölçülebilir değiştirmeyebilir |
| K22 Killam, FBI Crime Lab Digest 1991 (av tüfeği slug) | Tarihçe + kendi denemesi | Choke sayısı yok. Brenneke oyuğu "to allow for swaging as the slug passes through the choke"; en iyi açık choke, en kötü tam choke (grup ölçüsü yok) | Nitel: sıkı choke slug'da kötü; oyuk taban sıkışmayı karşılar |

**Choke'un slug'a fiziksel etkisi (kaynaklara göre):**

- Mermiyi ağızda **inceltir ve uzatır** (sıvama, "swaging") [K21, K22].
- Sıkı choke'ta "flier" (gruptan kaçan atış), simetrik olmayan sıvamaya bağlanıyor. Bu, K22'de
  bir kişinin görüşü, ölçüm değil.
- Eteksiz slug'da sıkışmayı karşılayacak etek yok. Oyuk taban (av tüfeği slug'ında) sıkışmayı
  kolaylaştırmak için var [K22]. Havalı slug'da taban/etek ile choke arasında ölçüm yok.
- Choke miktarı: Lothar Walther .177 için 0,04 mm (önceki N13, çapın ≈ %0,9'u). Bugün başka
  üretici miktar yazmıyor.

**Sonuç:** Choke'un slug'daki etkisi için **formüle girecek bir sayı yok.** Uydurulmamalı.

## 3. Diğer namlu etkenleri (yalnız kaynaklı sayılar)

### 3.1 Namlu boyu → hız

Üretici tabloları **en yüksek enerji** veriyor (aynı mermiyle kontrollü test değil):

| Üretici | Boy | .177 | .22 | .25 | .30 | Kaynak |
|---|---|---:|---:|---:|---:|---|
| Daystate Alpha/Delta Wolf | 430 mm | 20 | 45 | – | – | K7 (ft-lb) |
| | 600 mm | 34 | 71 | 75 | 105 | |
| | 711 mm | 37 | 78 | 81 | 115 | |
| Brocock BRK Ghost | 17" | 14–18 | 25–45 | – | – | K9 (ft-lb) |
| | 23" | 26–31 | 49–65 | 56–70 | 70–95 | |
| | 28" | 45 | 80 | 90 | 105 | |

Daystate: "The factory may set the muzzle energy lower than stated here to improve accuracy."

Hesap (aynı mermi varsayımıyla, v ∝ √E): Daystate 600 → 711 mm: .177 +%4,3, .22 +%4,8,
.25 +%3,9, .30 +%4,7 hız. 430 → 600 mm: .177 +%30, .22 +%26. **Bunlar ayar sınırlarıdır**,
ölçülmüş hız farkı değil.

Hatsan Factor kılavuzu [K16b]: Factor 585 mm .25 970 fps; Factor Sniper Long 760 mm .25
1075 fps, ama farklı mühimmatla (Sniper S/L test yükleri slug, Factor'ünki belirtilmemiş).
Kılavuz: "Velocity results may vary as much as 20%". Aynı yükle boy karşılaştırması değil.

Akademik: Greenslade & Bolton-King (Forensic Sci. Int. 2018) [K24], **yaylı** tüfeklerde
namluyu 15"'ten 7"'ye kesmenin hızı "considerably and consistently" düşürdüğünü ölçtü; ama
"the direction of muzzle velocity change could not be predicted by air rifle calibre, brand or
model". PCP için hakemli bir boy–hız çalışması bulunamadı.

### 3.2 Yiv profili (poligon / klasik)

- Silva-Rivera ve ark. 2021 [K25], 9×19 mm **ceketli**, sonlu eleman + ölçüm: "similar velocity
  and pressure parameters are achieved in the two types of barrels". Mermi dış deformasyonu
  poligonda 0,178 mm, klasikte 0,025 mm.
- Kurşun ya da havalı mermi için poligon/klasik ölçüm **yok.** Daystate Juggernaut'u
  "polygon A.R.T" namluya uygun buluyor (önceki N6), sayı yok.

### 3.3 Slug çapı ve namlu iç çapı

| Üretici | Ne diyor | Kaynak |
|---|---|---|
| Zan | .22 Hyper Line .217/.218; "FX liners prefer diameter .217" | K12 |
| Zan | .22 slug .217/.218/.219, "different internal geometry and sizing" için | K11 |
| Zan | .25: .250/.253; .30: .300/.303 | K11 |
| H&N | Slug HP II .22: .217, .218, .219; "To accommodate different barrel profiles and power levels" | K10 |
| H&N | Slug HP II .25: .2495 / .2505 | K10b |
| Hatsan USA | Apolo slug: "In order to adapt to different barrel profiles and power levels" | K13 |

- Hiçbir üretici "şu oluk çapına şu slug" diye sayısal kural vermiyor (Zan'ın FX cümlesi tek
  istisna). Lothar Walther 5,5/6,35/7,62 için iç/oluk çapı listede yok.
- Akademik: kurşun merminin oluktan büyük/küçük olmasının hız veya isabete etkisi için ölçüm
  bulunamadı. Yiv girişi (forcing cone) uzunluğu sıvama kuvvetini düşürüyor (67,4 kN → 53,7 kN,
  ceketli olmayan, pres deneyi) [K26]; havalı slug'a aktarılamaz.

### 3.4 Namlu ağzı (crown) ve namlu içi yalpalama

- M16 ölçümleri [K27]: ağızdan 1/16" içerideki çap ile ln(dağılım) arasında r = 0,84. Ağız
  aşınması dağılımı artırıyor. Doğrudan "crown hasarı" ölçümü değil.
- Havalı tüfek veya kurşun mermi için crown → dağılım sayısı **yok.**

### 3.5 Yiv adımı ve dağılım (kararlılık)

- McCoy BRL-MR-3877 (.22 LR, kurşun, ≈ 1090 fps, 1:16) [önceki S8/N24, bugün ek bilgi]:
  aerodinamik sıçrama gruplarda eğiklik yapıyor: 50 m'de "one click adjustment in elevation for
  every four clicks made on windage". Ses altı kurşun mermide sıçrama **gerçek ve ölçülmüş.**
- Piddington BRL MR-1943 [K28] (5,56 ceketli): 1:14 adımda Sg −65 °F'ta ≈ 0,85, dağılım
  ≈ 2,4 mil; 1:12'de (Sg yüksek) 0,6 mil. **Düşük Sg dağılımı 4 kat artırdı.** Kurşun slug için
  benzer ölçüm yok; ama uygulamanın Sg < 1,0 "güvenilmez" uyarısını destekler.
- "Aşırı dönme" (çok hızlı adım) cezası için kurşun ses altı mermide ölçüm yok.

## 4. Uygulamada formüle nasıl girer?

| Etken | Formüle girer mi? | Nasıl | Öneri |
|---|---|---|---|
| Yiv adımı | **Evet** | `lib/core/stability.dart`: Miller Sg → kararlılık sınıfı, spin sapması, aerodinamik sıçrama | Mevcut yeterli. Liste değerlerine üretici kaynaklı 1:14 (Bulldog), 1:16 (LW .30, Crosman), 1:17,7 (LW), 1:36 (LW poligon .177) eklenebilir; FX değerleri filtre değeri olarak, liner'a bağlanmadan. Bilinmiyorsa "Bilmiyorum" → Sg hesaplanmaz |
| Namlu boyu | Hayır (doğrudan) | Ölçülen hıza yansır | Alan önerilmez. Boy → hız formülü kaynakta yok |
| Choke | Hayır | Ölçülen hız ve grup çapına yansır | Alan önerilmez (hesap kullanamaz). Önceki rapordaki choke seçimi bu kurala göre çıkarılmalı. En fazla ⓘ metninde nitel not |
| Yiv profili (poligon) | Hayır | Grup çapı | Alan önerilmez |
| Slug çapı (.217/.218) | Hayır | Hız ve grup çapı | Alan önerilmez; mühimmat kütüphanesindeki ürün adı yeterli |
| Crown / geçiş | Hayır | Grup çapı | Alan önerilmez |
| Hız | **Evet** | PCP "En düşük / En yüksek namlu çıkış hızı" ortalaması (not: bu kutular `main`'de bulunamadı; tarif edildiği gibi varsayıldı) | Hız tüfek+namlu+slug ile **aynı gün** ölçülmeli. Choke ve boy etkisi burada yakalanır |
| Grup çapı | **Evet** | İsabet olasılığı ("Grup çapı" → sigma) | Namlunun choke/çap/crown etkisinin **tek** sayısal girişi. Aynı namlu + slug ile ölçülmeli |
| Sg < 1,0 | Uyarı | Sonucu "Güvenilmez" işaretle | K28 ve S5 ile destekli; dağılıma sayı eklenmez |

Hız aralığı (En yüksek − En düşük) dikey saçılmaya çevrilebilir (önceki rapor B.4: 500 m'de
1 m/s ≈ 8 cm). Bu yeni bir istek değildir; yalnız mümkün olduğu not edilir, karar sahibin.

## 5. Açık sorular

1. FX liner → adım eşlemesi (Superior / Heavy / Slug, kalibre ve boya göre). Yol: liner
   üzerindeki işaret, FX teknik destek, ya da JS tabloyu açabilen bir tarayıcı (bu ortamda
   ağ engeli vardı).
2. Daystate/Brocock 711 mm slug namlusunun adımı; Delta Wolf UK adım sayısı.
3. Hatsan, Kral, Reximex, Air Arms adım ve choke miktarları.
4. Choke'un slug'da sayısal etkisi (hız, grup). Kabul edilen kaynakta yok; ancak kendi
   ölçümle (aynı tüfek, choke'lu/choke'suz namlu, aynı slug, kronograf + 5×5 grup) çıkar.
5. Slug çapı (.217/.218) ile hız ve grup ilişkisi.
6. Poligon / klasik yivin kurşun slug'a etkisi.
7. PCP'de namlu boyu → hız (aynı slug, aynı ayar).
8. Uygulamanın spin sapması ve sıçrama formülleri tüfek mermisinden türetilmiş; kurşun slug
   için doğrulanmadı (önceki rapor B.5).
9. McCoy'un 50 m'de "1 yükseklik / 4 yan klik" oranı, uygulamanın sıçrama hesabıyla bir
   regresyon testi olarak karşılaştırılabilir (ayrı görev).

---

## Kaynaklar

Hepsi 2026-10-16'da okundu. Alıntılar WebFetch özetinden alındı; PDF'lerin bazıları OCR'lı.

| # | Kaynak | Tür | URL |
|---|---|---|---|
| K1 | FX Airguns — Liners | Üretici | https://www.fxairguns.com/accessories/barrels/liners/ |
| K2 | FX Panthera (legacy) sayfası; Panthera barrel PDF | Üretici | https://www.fxairguns.com/legacy-rifles/fx-panthera/ · https://www.fxairguns.com/media/5z4nwfee/fx-panthera-barrel.pdf |
| K3 | FX Dynamic/Panthera MKII barrel system PDF; Superlight tube kit PDF; X-Barrel PDF | Üretici | https://www.fxairguns.com/media/rrepycjd/dynamix-panthera-mkii-barrel-system.pdf · https://www.fxairguns.com/media/cpmnbsdy/tube-kit-superlight.pdf · https://www.fxairguns.com/media/f0ebt3d2/fx-x-barrel.pdf |
| K4 | FX Dreamline 2020 kılavuzu | Üretici | https://www.fxairguns.com/media/dccduptp/fx-dreamline-2020.pdf |
| K5 | Lothar Walther — airgun barrels listesi | Namlu üreticisi | https://lothar-walther.com/blank-barrel/airgun-barrels/ |
| K6 | Lothar Walther — polygon profile with choke | Namlu üreticisi | https://www.lothar-walther.de/en/barrel-blank/airgun/polygon-profile-with-choke/ |
| K7 | Daystate Blackwolf kit; Alpha Wolf; Delta Wolf | Üretici | https://daystate.com/product/daystate-blackwolf-barrel-caliber-changing-kit/ · https://daystate.com/rifles/alpha-wolf/ · https://daystate.com/rifles/delta-wolf/ |
| K8 | Daystate Delta Wolf | Üretici | https://daystate.com/rifles/delta-wolf/ |
| K8b | Daystate bayi rehberi PDF | Üretici | https://daystate.com/wp-content/uploads/2022/05/GUIDE-YOUR-CUSTOMER-TO-THE-%E2%80%98RIGHT-DAYSTATE.pdf |
| K9 | Brocock BRK Ghost el kitabı; BRK Ghost sayfası | Üretici | https://brocock.co.uk/Handbooks/BRK-GhostHandbook.pdf · https://brocock.co.uk/brocock-brk-ghost/ |
| K10 | H&N Slug HP II .22 | Mühimmat üreticisi | https://www.hn-sport.de/en/air-gun-hunting/slug-HP-22-30gr |
| K10b | H&N Slug HP II .25 | Mühimmat üreticisi | https://www.hn-sport.de/en/air-gun-hunting/slug-HP-25-30gr |
| K11 | Zan .22 slugs (ve .25/.30 ürün sayfaları) | Mühimmat üreticisi | https://zanprojectiles.com/shop/22-slugs/ |
| K12 | Zan .22 Hyper Line | Mühimmat üreticisi | https://zanprojectiles.com/shop/22-hyper-line-slugs/ |
| K13 | Hatsan USA Apolo slug | Üretici | https://hatsanairgunsusa.com/ (Apolo Slug ürün sayfası) |
| K15 | Crosman SSS (66 namlusu) | Üretici | https://www.crosman.com/faqs/ |
| K16 | Hatsan Factor Sniper Long | Üretici | https://hatsanairgunsusa.com/product/factor-sniper-long/ |
| K16b | Hatsan Factor serisi kılavuzu | Üretici kılavuzu | https://hatsanairgunsusa.com/wp-content/uploads/2026/06/FACTOR-SERIES-USER-MANUALDIAGRAMS.pdf |
| K17 | Kral 2022 Air Rifle Catalogue | Üretici | https://kralarms.com/wp-content/uploads/2023/02/2022-Air-Rifle-Catalogue.pdf |
| K18 | Air Arms S510 | Üretici | https://www.air-arms.co.uk/product/s510 |
| K19 | Reximex Daystar | Üretici | https://reximex.com/airgun/pcp-airgun/daystar/ |
| K20 | de Rosset W.S., Montgomery J.S., "Examination of a Wear-Reducing Muzzle Device", ARL-TR-6557, 2013 | ABD Ordusu (ARL) | https://apps.dtic.mil/sti/pdfs/ADA583936.pdf |
| K21 | A'Costa A., US 4,660,312, "Rifled gun barrel having smooth bore section", 1987 | Patent | https://patents.google.com/patent/US4660312 |
| K22 | Killam E.W., "Historical Development of Shotgun Rifled Slugs…", Crime Laboratory Digest 18(2), FBI, 1991 | Devlet | https://www.ojp.gov/pdffiles1/Digitization/132229NCJRS.pdf |
| K23 | Brennan D.C., US 4,527,348, "Gun barrel", 1985 | Patent | https://patents.google.com/patent/US4527348 |
| K24 | Greenslade K., Bolton-King R., Forensic Science International 2018, doi:10.1016/j.forsciint.2018.11.004 (yazar ön baskısı) | Hakemli | https://eprints.staffs.ac.uk/4848/3/FSI%20Air%20Rifle%20Modification%20PreProof%2016th%20Nov%202018.pdf |
| K25 | Silva-Rivera U.S. ve ark., "Internal ballistics of polygonal and grooved barrels", Science Progress 104(2), 2021, doi:10.1177/00368504211016954 | Hakemli | https://ipn.elsevierpure.com/en/publications/internal-ballistics-of-polygonal-and-grooved-barrels-a-comparativ |
| K26 | Yang L., Cheng Y., "Study on the influence of the slope-angle to the bullet projectile", AMEII 2016 | Konferans | https://www.atlantis-press.com/article/25854683.pdf |
| K27 | Bonash R.C., "Analysis of M16 Rifle Dispersion and Dimensional Data", 1970 | ABD Ordusu | https://apps.dtic.mil/sti/pdfs/AD0716608.pdf |
| K28 | Piddington M.J., BRL MR-1943, 1968 (M193, 1:12 vs 1:14) | ABD Ordusu (BRL) | https://apps.dtic.mil/sti/pdfs/AD0844934.pdf |
| N…, S… | Önceki iki rapor | Repo | `docs/research/namlu_tipi_pellet_surukleme.md`, `docs/research/pellet_slug_hassas_hesap.md` |

**Okunmayan / atlanan:**

- robots.txt ile kapalı: aeaairgun.com, jsb-match.com, weihrauch-sport.de.
- İzin isteği zaman aşımı: nielsenspecialtyammo.com, ataman-guns.com, FX Impact M3/Impact barrel
  kit PDF'leri.
- Hata: FX liner-replacement PDF, lothar-walther robots.txt, bazı DTIC ve Springer sayfaları
  (429), PMC (reCAPTCHA).
- FX liner tablosu JavaScript ile yükleniyor; tarayıcı denemesi ağ vekilinde engellendi.
- Bulunamadı: Huben, Ataman, Taipan resmî sayfaları; FX adımı için patent.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
