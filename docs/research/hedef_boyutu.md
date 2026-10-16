# Araştırma: Hedef boyutu (Saha sayfası fikri)

Tarih: 16.10.2026, 15:26 (İstanbul). Görev: sahibin 16.10.2026 15:17–15:18 tarihli "Araştır bunu." isteği.
Kapsam: yalnız araştırma. `lib/`, `test/`, `ios/`, `garmin/` altında değişiklik yok.

> Araç notu: Bu çalışmada Exa ve Firecrawl araçları oturumda yoktu (araç listesinde bulunmadı, `firecrawl` komutu kurulu değildi).
> Arama için WebSearch, sayfa okumak için WebFetch kullanıldı. Her kaynağın robots.txt dosyası okunup kontrol edildi.

## Özet

- **Wrist Dope'ta hedef boyutu ne işe yarıyor?** Uygulamanın kendi sayfalarına göre üç işe yarıyor: (1) ilk atışta isabet olasılığı, (2) av için "etik atış / son balistik" kontrolü, (3) seçili hedefin saat kadranında ve mesafe kartında görünmesi. Hedef listesinin içeriğini ve boyutlarını depoya almadık; CLAUDE.md bunu yasaklıyor.
- **Bizim kodda hedef boyutu bugün zaten hesapta kullanılıyor.** Beş yerde var, hepsi tek bir **daire çapı** ya da **tek bir uzunluk**:
  1. Balistik → Pro Ayarlar "Hedef çapı": WEZ isabet olasılığına giriyor ve Hedef sayfasındaki dürbün görüntüsüne halka olarak çiziliyor.
  2. Araçlar → İsabet Olasılığı.
  3. Avcı Sıfırı (MPBR): hazır listeden seçiliyor.
  4. Stadyametrik mesafe ölçer.
  5. Retikül hesabı.
  Eksik olanlar: dikdörtgen hedef (genişlik × yükseklik), hazır hedef listesi, enerji/etik eşiği.
- **Resmi kaynak durumu**:
  - Atış sporu kurumları (IPSC, ISSF) hedef ölçülerini kendi kurallarında veriyor. Ancak bu çalışmada sayıları metin olarak çıkaramadım: IPSC'de ölçüler çizimlerde, ISSF kural kitabı ise açılamadı.
  - Okuduğum resmi av kurumu eğitim materyalleri (Texas TPWD, New Jersey, Massachusetts, Colorado CPW) hayati bölgeyi **organlarla veya oranla** tarif ediyor, **santimetre vermiyor**.
  - Türkiye'de (Tarım ve Orman Bakanlığı DKMP, MEB) hayvan için hayati bölge ölçüsü veren resmi bir kaynak bulamadım.
- **Önerim**: Bugün ek bir liste gerekmiyor. Liste yapılacaksa en temiz yol (b) seçeneği: yalnız ölçüsü resmi kuralda yazan standart hedefler. Bunun için ölçüleri kural kitaplarının çizimlerinden elle okumak gerekiyor. Hayvan listesi (c) için şu an resmi ve sayısal bir kaynak yok.

---

## 1. Wrist Dope'ta hedef boyutu ne için kullanılıyor (yalnız kendi açık sayfalarından)

Kaynaklar:

- App Store sayfası: https://apps.apple.com/app/id6755347134 (geliştirici: Musket Holdings, LLC)
- Kendi sitesi: https://wristdope.com

Her ikisi de 16.10.2026'da okundu ve robots.txt izin veriyor (aşağıya bakın).

| Kullanım | Kanıt (≤15 kelime alıntı) | URL |
|---|---|---|
| İlk atış isabet olasılığı | "Configure target size, rifle precision, velocity spread, and wind confidence to estimate first-round hit probability." | https://wristdope.com |
| İsabet yüzdesini neyin belirlediği | "Lock a target for a real first-round-hit percentage from your velocity SD, group size, and wind call" | https://apps.apple.com/app/id6755347134 |
| Etik atış / son balistik kontrolü | "compare retained energy and impact velocity with your configured terminal thresholds." | https://wristdope.com |
| Etik atış kontrolü (sürüm 1.9 notu) | "Know if it's an ethical shot." | https://apps.apple.com/app/id6755347134 |
| Hazır hedefler (sürüm 1.5 notu, yalnız varlığı) | "New target presets: ground squirrel, prairie dog, rabbit, groundhog, fox, …" | https://apps.apple.com/app/id6755347134 |
| Saat kadranında / mesafe kartında hedef | "TARGET: your selected target and bearing" | https://apps.apple.com/app/id6755347134 |

Sonuç: Hedef boyutu **isabet olasılığı** ve **etik atış kontrolü** için kullanılıyor. Seçilen hedef ayrıca **kadranda ve mesafe kartında** gösteriliyor.

Bilinmeyenler:

- Boyutun **retikülde tutma çizimine** ya da **boyuttan mesafe ölçmeye** girip girmediği açık sayfalarda yazmıyor.
- İsabet modelinin hedefi dikdörtgen mi, daire mi saydığı da yazmıyor.

Bilerek yapılmayan:

- Hedef listesindeki adlar ve ölçüler depoya alınmadı. Görevde geçen "sincap 5×10 cm" gibi değerler de alınmadı.
- Sitenin el kitabı (`/manual`) ve "nerd-stuff" sayfası okunmadı, çünkü yukarıdaki fikir düzeyi yetiyor.

## 2. Bizim kodda hedef boyutunu kim kullanıyor (salt okuma)

Hepsi **daire çapı** (isabet testi `x² + y² ≤ R²`) ya da **tek bir uzunluk**. Birim cm; Balistik ekranında inç de var. Değeri kullanıcı elle yazıyor; MPBR'de hazır listeden seçiyor.

| Özellik | Dosya | Girdi | Hesaba girişi |
|---|---|---|---|
| Balistik → Pro Ayarlar "Hedef çapı" (WEZ isabet olasılığı) | `lib/features/ballistics/ballistics_screen.dart` (`_hitProbability`, ~2695–2800; boyut 2789–2798), `lib/features/ballistics/pro_ayarlar_view.dart`, `lib/core/wez.dart` (`targetRadiusMrad`, `simulate`) | `targetSizeCtl`, boşsa 10 cm / 4 in. `ShotSettings.targetSizeText` olarak kaydediliyor (`lib/services/shot_settings_store.dart`) | R = (çap/2) mesafede mrad'a çevriliyor. Grup, SD, mesafe hatası, BC hatası ve rüzgâr kaynaklarıyla 1000 atışlık Monte Carlo yapılıyor. Seri isabet: `Wez.seriesHitProbability` |
| Hedef sayfası dürbün çizimi | `lib/features/ballistics/scope_dial_view.dart`, `scope_reticle.dart` (`targetRadiusPx`), `scope_workings.dart` | Aynı çap (`_targetDiameterM`) | Hedef, gerçek açısal boyutunda **daire halka** olarak çiziliyor |
| Araçlar → İsabet Olasılığı | `lib/features/tools/hit_probability_screen.dart`, `lib/tools/domain/hit_probability.dart` | "Hedef çapı" cm, grup MOA, atış sayısı, mesafe | P = 1 − exp(−R²/2σ²). Ayrıca %80 isabet için en uzak mesafe hesaplanıyor |
| Avcı Sıfırı / MPBR | `lib/features/tools/mpbr_screen.dart`, `lib/core/mpbr.dart` (`zoneDiametersCm = [2.5, 4, 10, 15, 20]`) | "Hedef bölge çapı" listeden seçiliyor | Yörüngenin ±çap/2 içinde kaldığı en uzun mesafe aranıyor |
| Stadyametrik mesafe ölçer | `lib/features/tools/calculators_screen.dart` (Stadia), `lib/tools/domain/field_calc.dart` (`distanceFromAngle`) | "Hedefin gerçek boyu" (tek uzunluk) | mesafe = boy / tan(okunan mil veya MOA) |
| Retikül hesabı | `lib/features/tools/reticle_screen.dart`, `field_calc.dart` (`milOfSize`) | "Hedef boyu" cm | Hedefin mil karşılığı FFP/SFP'ye göre retikül mil'ine çevriliyor ve daire olarak çiziliyor |

Bugün **olmayanlar**:

- **Dikdörtgen hedef yok.** Genişlik × yükseklik hiçbir hesapta yok. Bir "Saha" listesi 13×15 cm gibi dikdörtgen ölçü verse bile, bugünkü hesaplar bunun yalnız tek bir çapını kullanabilir.
- **Hedef veya hayvan listesi yok.** Ekranlar arasında ortak bir "seçili hedef" de yok; her ekranın kendi alanı var.
- **Enerji/etik eşik kontrolü yok.** Mesafedeki enerji (`TrajectoryPoint.energyJ`) yalnız sayı olarak gösteriliyor. Enerji hesaplayıcısındaki "Hedef enerji" istenen bir enerji değeri; hedefin boyutuyla ilgisi yok.

Sonuç: Hedef boyutu **bugün hesapta kullanılabiliyor**, ama yalnız tek bir daire çapı olarak (isabet olasılığı, dürbün halkası, MPBR, mesafe ölçme). Bir listeden seçilen hedef işe yarayacaksa iki şeyden biri gerekir:

- (i) seçilen hedeften tek bir çap türetip mevcut "Hedef çapı" alanlarına aktarmak, ya da
- (ii) WEZ ve İsabet Olasılığı motorlarına dikdörtgen isabet testi (|x| ≤ G/2, |y| ≤ Y/2) eklemek. WEZ kaynaklarında σx ve σy zaten ayrı tutuluyor.

Etik atış kontrolü için ise hayvan başına resmi bir enerji/hız eşiği gerekir. Bu eşik şu an yok ve CLAUDE.md'ye göre kaynağı resmi olmalı.

Not (düzeltme önerisi değil): Yardım metinlerinde örnek hayvan ölçüleri geçiyor ve bunların bir kaynağı yok:

- `environment_field_info.dart`: "tavşan 5 cm, karaca 15 cm"
- `mpbr_screen.dart`: "domuz 15 cm, küçük av 2,5 cm"
- `calculators_screen.dart`: "tavşan ~20 cm, karga ~45 cm"

Bunlar örnek olarak yazılmış. Bir hedef listesi kurulursa aynı kaynak kuralına tabi olurlar.

## 3. Bağımsız ve yetkili kaynaklar

Kural: Karma kaynaklardan ölçü tablosu derlenmedi. Her kaynak için yalnız ne verdiği ve sayfadan doğrudan okunabilen örnekler yazıldı. Tüm sayfalar 16.10.2026'da okundu.

### 3a. Standart hedefler (atış sporu kurumları)

**IPSC: Handgun Competition Rules, Ocak 2024 baskısı**

- URL: https://www.ipsc.org/wp-content/uploads/2023/12/IPSC-Handgun-Competition-Rules-Jan-2024-Edition-Final-27-Dec-2023.pdf
- Ne veriyor:
  - Kağıt hedef ölçüleri: Ek B2 "IPSC Target" (s. 48) ve B3 "IPSC Mini Target" (s. 49).
  - Çelik hedef ölçüleri: C2 "IPSC Poppers" (s. 51) ve C3 "IPSC Metal Plates" (s. 52).
  - Kural 4.1.1: yalnız "Appendices B and C" ölçülerine tam uyan hedefler onaylı sayılır.
- Metinden okunan örnekler:
  - Kural 4.2.2: puansız kenar "0.5 cm (Mini Targets 0.3 cm)".
  - Kural 4.3.3.1: "Metal plates of various sizes may be used (see Appendix C3)."
  - Asıl bölge ölçüleri (A/C/D bölgeleri, plaka çapları) eklerde **çizim olarak** veriliyor. Metin çıkarımında görünmedi; s. 48–52'den elle okunmalı. Bu nedenle bu raporda bölge ölçüsü yazılmadı.
- Lisans: "Copyright © 2023 International Practical Shooting Confederation". Ölçülerin (olgu) kullanılması ile kural metninin veya çizimin kopyalanması ayrı şeyler. Çizim kopyalanmamalı; liste için IPSC'den yazılı izin istemek en güvenli yol.
- robots.txt: `https://www.ipsc.org/robots.txt` → `*` için yalnız `/wp-admin/` yasak. `/wp-content/uploads/` serbest. ✔

**ISSF: Official Statutes, Rules and Regulations, 2026 baskısı**

- URL: https://backoffice.issf-sports.org/getfile.aspx?mod=docf&pane=1&inst=455&file=ISSF-Rule-Book-2026-Edition-2025-First-Print-12-2025-Effective-1-January-2026.pdf
- Ne veriyor: 10 m havalı tüfek, 50 m tüfek ve 25 m tabanca hedeflerinin halka çapları (Kural 6.3.4).
- Durum: Bu çalışmada dosya **açılamadı** (getirme hatası). Değer yazılmadı.
- Okunan ilgili belge: "ISSF Rules for Paper Target Scoring" (2022): https://backoffice.issf-sports.org/getfile.aspx?mod=docf&pane=1&inst=31&iist=29&file=ISSF-Rules-for-Paper-Target-Scoring.pdf
  - Halka çapları için Kural 6.3.4'e gönderme yapıyor ("shall be as described in Rule 6.3.4").
  - Yalnız ölçüm aletlerinin çaplarını veriyor. Örnek: Kural 1.4.7, 10 m havalı tüfek dış ölçer "5.50mm". Bu bir halka çapı değil.
- Lisans: "© ISSF".
- robots.txt: `https://backoffice.issf-sports.org/robots.txt` → `*` için `/bin/`, `/App_Themes/`, `/documents/`, `/flash/` yasak. `getfile.aspx` serbest. ✔

**IDPA**

- Resmi kural kitabına ait bir sayfa bulunamadı. Aramada yalnız resmi olmayan kopya siteler çıktı ve bunlar kullanılmadı.
- Değer yok.

### 3b. Av hayvanı hayati bölge (resmi av eğitimi materyali)

Okunan resmi kaynakların **hiçbiri santimetre veya inç cinsinden hayati bölge ölçüsü vermiyor**:

**Texas Parks & Wildlife Department: Hunter Education, "Shots to the Vital Areas"**

- URL: https://tpwd.texas.gov/education/hunter-education/online-course/hunting-skills-1/vital-areas
- Ölçü yok, yalnız oran var: "come up one third of the way into the body."
- robots.txt: `/education/` yasak değil. ✔

**New Jersey Fish & Wildlife: hunter education, Bölüm 4**

- URL: https://nj.gov/dep/fgw/pdf/hunted/chapter_4.pdf
- Ölçü yok, yalnız benzetme var: "smaller then the size of pie plate."
- robots.txt: `/dep/fgw/` yasak değil. ✔

**Massachusetts: Basic Hunter Education, Lesson 16 "Judgment & Shot Placement" (eğitmen kılavuzu, 2017)**

- URL: https://www.mass.gov/doc/lesson-16-judgment-and-shot-placement/download
- Hayati bölge organlarla tarif ediliyor ("the heart, lungs, liver, and major blood vessels"), ölçü yok.
- robots.txt: yalnız `/doc/courts-dwnld-*` yasak. ✔

**Colorado Parks and Wildlife: "Hunter Sight In and Practice Tips"**

- URL: https://cpw.state.co.us/Documents/Hunting/HunterEd/Hunter-Sight-In-Practice-Tips.pdf
- Geyik (elk) hayati bölgesi yalnız çizimle gösteriliyor, ölçü yok.
- robots.txt: `/Documents/` yasak değil. ✔

**University of Arkansas Cooperative Extension: FSA9106 "Laws and Regulations Governing Feral Hogs in Arkansas"**

- URL: https://www.uaex.uada.edu/publications/pdf/FSA-9106.pdf
- Domuz için atış bölgesi veya vücut ölçüsü yok; yalnız tuzak ölçüleri var.

Lisans notu: ABD eyalet yayınlarında genel bir yeniden kullanım izni yazılı değil. Ölçü verilseydi bile alıntı ve atıfla sınırlı kalmak gerekirdi.

### 3c. Türkiye resmi kaynakları

**Tarım ve Orman Bakanlığı, DKMP: 2023–2024 Av Yılı Av Turizmi Uygulama Talimatı, Ek Karar-1**

- URL: https://www.tarimorman.gov.tr/DKMP/Belgeler/AV%20YÖNETİMİ%20DAİRESİ/2023-2024%20AV%20YILI%20AV%20TURİZMİ%20UYGULAMA%20TALİMATI%20EK%20KARAR-1.pdf
- Hayati bölge veya vücut ölçüsü **yok**. Yalnız kupa (boynuz) ölçme kuralları var. Örnekler:
  - IX.3(i): "Boynuz ölçümünde, 0,5 cm ve yukarısı 1 cm"
  - IX.4(c): "100 cm'nin altındaki her iki boynuzu kırık olan tekedir"
- robots.txt: `/DKMP/` yasak değil. ✔

**Avcı Eğitimi ve Avcılık Belgesi Verilmesi Usul ve Esasları Hakkında Yönetmelik**

- URL (FAO kopyası): https://faolex.fao.org/docs/pdf/tur90485.pdf
- Eğitim programını DKMP ve MEB'in birlikte hazırladığı yazıyor (md. 15). Bir "atış eğitimi" dersi var (md. 19).
- Ders içeriği ve hedef ölçüsü yönetmelikte **yok**. Program metninin kendisi açıkta bulunamadı.

**MEB Hayat Boyu Öğrenme: Spor Atıcılık Kurs Programı (16–25 yaş, 2017)**

- URL: https://ookgm.meb.gov.tr/meb_iys_dosyalar/2023_02/13171334_AtYcYlYk_16-25_YaY.pdf
- Hedef ölçüsü **yok**.
- robots.txt: `*` için kural yok, serbest. ✔

**Bakanlık kütüphanesi kataloğu**

- URL: https://kutuphane.tarimorman.gov.tr/vufind/Record/5061/Similar
- Avcı eğitimi kitabı listelenmiyor; yalnız "Hunting in Turkey" (1990, 2021) gibi genel kitaplar var.

Sonuç: Yaban domuzu, tilki, tavşan, karga ve çakal için **ölçü veren resmi bir Türk kaynağı bulunamadı**. DKMP'nin avcı eğitimi kurs kitabı açıkta değil. Bakanlıktan (DKMP Av Yönetimi Dairesi) istenebilir.

## 4. Sahip için seçenekler

| Seçenek | Ne olur | Ne gerekir |
|---|---|---|
| **(a) Hedef listesi yok** | "Saha" sayfası hedefi bugünkü gibi tek bir "Hedef çapı" kutusuyla alır, ⓘ açıklaması olur. | Ek kaynak gerekmez. Bugünkü hesaplar zaten bunu kullanıyor. |
| **(b) Yalnız standart hedefler (resmi kural ölçüleri)** | Liste yalnız IPSC/ISSF gibi kurallarda ölçüsü yazan hedeflerden oluşur. | IPSC ek çizimlerinden (s. 48–52) ve ISSF Kural 6.3.4'ten ölçüleri elle okuyup kaynak, tarih ve alıntıyla kaydetmek; IPSC/ISSF telif durumunu sormak. Hedefler dikdörtgen veya çok bölgeli olduğu için iki yol var: ya hesaba dikdörtgen isabet eklenir, ya da hedef tek bir çapa indirilir. |
| **(c) Hayvan listesi (resmi kaynaklardan)** | Saha'da "domuz, tilki…" seçilir. | Bugün ölçü veren resmi bir kaynak yok (3b, 3c). Önce DKMP'den veya bir üniversite yaban hayatı bölümünden yazılı ölçü elde edilmeli. Etik atış kontrolü istenirse hayvan başına resmi enerji/hız eşiği de gerekir; o eşik de şu an yok. |

Gerçek seçim **(a) ile (b) arasında**. (c) seçeneği bugün kaynak kuralını karşılamıyor.

## Kaynaklar

Tümü 16.10.2026'da okundu.

- Wrist Dope, App Store: https://apps.apple.com/app/id6755347134
- Wrist Dope, kendi sitesi: https://wristdope.com
- IPSC Handgun Competition Rules, Ocak 2024: https://www.ipsc.org/wp-content/uploads/2023/12/IPSC-Handgun-Competition-Rules-Jan-2024-Edition-Final-27-Dec-2023.pdf
- ISSF Rule Book 2026 (açılamadı): https://backoffice.issf-sports.org/getfile.aspx?mod=docf&pane=1&inst=455&file=ISSF-Rule-Book-2026-Edition-2025-First-Print-12-2025-Effective-1-January-2026.pdf
- ISSF Rules for Paper Target Scoring: https://backoffice.issf-sports.org/getfile.aspx?mod=docf&pane=1&inst=31&iist=29&file=ISSF-Rules-for-Paper-Target-Scoring.pdf
- TPWD, Shots to the Vital Areas: https://tpwd.texas.gov/education/hunter-education/online-course/hunting-skills-1/vital-areas
- NJ Fish & Wildlife, Chapter 4: https://nj.gov/dep/fgw/pdf/hunted/chapter_4.pdf
- Massachusetts, Lesson 16: https://www.mass.gov/doc/lesson-16-judgment-and-shot-placement/download
- Colorado Parks and Wildlife, Hunter Sight In and Practice Tips: https://cpw.state.co.us/Documents/Hunting/HunterEd/Hunter-Sight-In-Practice-Tips.pdf
- University of Arkansas, FSA9106: https://www.uaex.uada.edu/publications/pdf/FSA-9106.pdf
- Tarım ve Orman Bakanlığı DKMP, Av Turizmi Uygulama Talimatı Ek Karar-1: https://www.tarimorman.gov.tr/DKMP/Belgeler/AV%20YÖNETİMİ%20DAİRESİ/2023-2024%20AV%20YILI%20AV%20TURİZMİ%20UYGULAMA%20TALİMATI%20EK%20KARAR-1.pdf
- Avcı Eğitimi Yönetmeliği (FAOLEX): https://faolex.fao.org/docs/pdf/tur90485.pdf
- MEB Spor Atıcılık Kurs Programı: https://ookgm.meb.gov.tr/meb_iys_dosyalar/2023_02/13171334_AtYcYlYk_16-25_YaY.pdf
- Bakanlık kütüphane kataloğu: https://kutuphane.tarimorman.gov.tr/vufind/Record/5061/Similar

---
_Generated by [Claude Code](https://claude.ai/code)_
