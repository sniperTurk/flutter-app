# Sniper Türk — isabet ve tekrarlanabilirlik için geliştirme önerileri (2026-10-11)

Yalnız araştırma ve plan; uygulama kodu değiştirilmedi. Taban: `main` @ 3a0e645.

## 0. Yöntem ve verilen kararlar

Görev "sahibine soru sorma, kararlarını rapora yaz" dediği için brainstorming
adımlarındaki onay noktaları yerine kararlar burada yazılı:

| # | Karar | Gerekçe |
|---|-------|---------|
| K1 | İş "mimari ölçekli plan" olarak sınıflandı; çıktı tek belge (`docs/yeni-hesaplar-2026-10-11.md`), ayrı spec/plan dosyası yok. | Görev çıktı yolunu sabitliyor; writing-plans formatı bölüm 6'da. |
| K2 | Öneriler kaba sayısal hata bütçesiyle sıralandı (bölüm 2). Sayılar uygulamanın çözücüsünden değil, bu rapor için yazılmış bağımsız küçük bir nokta-kütle hesaplayıcıdan geldi (Ek A). | Etki tahmini uygulamadaki olası bir hatayı kopyalamasın. Sürüklenme tabloları depodaki `standard_drag_tables.dart` (BRL/JBM) değerleri. |
| K3 | "Sıfırlama günü hava koşulları" önerisi elendi. | Hesap: 100 m sıfırda, ICAO yerine Erzurum havasıyla (5 °C, 815 hPa) sıfırlamak 1000 m'de bile < 1 cm fark ediyor (bölüm 2.1). Sıfır günü hızı zaten ayrı tutuluyor. |
| K4 | Uygulanacak ilk 3 öneri: Ö1 mühimmat sıcaklığı, Ö2 gözlemle rüzgâr seçimi, Ö3 kronograf serisi. | En yüksek etki/zorluk oranı; üçü de mevcut çözücüyü değiştirmeden mevcut akışa takılıyor. |
| K5 | Başka balistik uygulamalarının kodu, tablosu veya mermi kütüphanesi kaynak gösterilmedi ve kopyalanması önerilmedi. Veriler yalnız üretici belgeleri, bilimsel yayınlar ve kamu malı BRL tablolarından. | Görev koşulu. |
| K6 | Etki birimi: cm ve 0,1 mrad klik (1 klik ≈ 0,1 mrad; 800 m'de 1 klik = 8 cm). MOA kulelerde 1/4 MOA ≈ 0,073 mrad. | Uygulamanın varsayılanı MRAD. |

Örnek silahlar (bütün tablolarda aynı):

- T1 .308 Win, 175 gr, G7 BC 0,243, 790 m/s, sight height 45 mm, sıfır 100 m.
- T2 6.5 Creedmoor, 140 gr, G7 BC 0,315, 820 m/s, 45 mm, 100 m.
- P1 PCP .22 diabolo saçma 18 gr, G1 BC 0,031, 275 m/s, 50 mm, sıfır 30 m.
- P2 PCP .22 slug 25 gr, G1 BC 0,090, 290 m/s, 50 mm, 30 m.

## 1. Kodda doğrulanan mevcut durum (özet)

- `AerodynamicTrajectorySolver`: 3-B RK4 (adım 0,5 ms), hava kütlesine göre
  bağıl hızla sürüklenme, G1/G2/G5/G6/G7/G8/GI/GS/RA4/GA tabloları, çoklu BC
  bandı, özel Cd eğrisi, eğim/cant dönüşümü, tam vektör Coriolis (Eötvös
  dahil), konuma göre yerçekimi, rüzgâr bölgeleri (üçte bir).
- Sıfır açısı her zaman ICAO havasında (15 °C, 1013,25 hPa, %0 nem)
  çözülüyor (`ballistic_input.dart:183`); sıfır günü hızı ayrı
  (`zeroMuzzleVelocityMps`).
- Barut sıcaklığı: doğrusal `v = v0·(1 + k/100·(T−T0)/15)`; `T` olarak hava
  sıcaklığı kullanılıyor (`ballistics_screen.dart:1154`). Mühimmatın kendi
  sıcaklığı için ayrı girdi yok.
- Spin drift (Litz) ve rüzgâr sıçraması (Litz) ekranda, Miller Sg ile;
  mermi uzunluğu elle giriliyor. Sg için düşük kararlılık uyarısı ya da
  BC düzeltmesi yok.
- WEZ: grup, SD, mesafe, BC ve rüzgâr belirsizliği Gauss kaynakları; 1000
  örnekli Monte Carlo. "En az bir isabet" bağımsız atış varsayıyor (kodda
  üst tahmin olarak not edilmiş).
- Doğrulama araçları: hız doğrulama ve BC doğrulama (tek mesafe), tık
  doğrulama, kule ölçeği, sıfır kaçıklığı.
- Basınç: hava servisi istasyon basıncını kullanıyor, ⓘ QNH uyarısı var;
  telefon barometresi kullanılmıyor.
- PCP: `pressureBar`/`regulatorBar` alanları var; hızın dolum basıncına ve
  atış sırasına bağlılığı modellenmiyor. GA tablosu kodda "UNVERIFIED".

## 2. Hata bütçesi: neyi düzeltmek kaç cm kazandırır

### 2.1 Ateşli tüfek (T1 / T2), dikey sapma cm (+ = yukarı)

| Hata kaynağı | 300 m | 600 m | 800 m | 1000 m |
|---|---|---|---|---|
| T1 hız +10 m/s | 2 | 11 | 24 | 46 |
| T2 hız +10 m/s | 2 | 9 | 18 | 32 |
| T1 hava sıcaklığı +10 °C | 0,4 | 4,5 | 14 | 36 |
| T1 basınç −10 hPa | 0,1 | 1,7 | 5,3 | 14 |
| T1 1000 m'de QNH (1013) yerine gerçek 900 hPa | — | 19 | 57 | — |
| T1 BC −%5 | −1 | −9 | −29 | −75 |
| T2 BC −%5 | −0,5 | −5 | −16 | −38 |
| T1 mesafe ±10 m | — | ±15 | ±27 | — |
| T1 sıfır ICAO yerine Erzurum havasında | 0,2 | 0,5 | 0,6 | 0,8 |

Yatay, 1 m/s tam değer yan rüzgâr: T1 5 / 23 / 46 / 80 cm; T2 4 / 16 / 30 /
51 cm. T1'de 800 m'de 1 m/s rüzgârın etkisinin %45'i ilk üçte birlik yoldan,
%37'si ortadan, yalnız %18'i hedef tarafından geliyor.

### 2.2 PCP (P1 / P2), cm

| Hata kaynağı | 30 m | 50 m | 75 m | 100 m |
|---|---|---|---|---|
| P1 düşüm (sıfır 30 m) | 0 | 5,2 | 24 | 59 |
| P1 hız +10 m/s | 0,4 | 1,2 | 2,8 | 5,3 |
| P1 BC −%10 | −0,1 | −0,4 | −1,4 | −3,8 |
| P1 mesafe ±5 m | — | ±2,3 | ±5,3 | — |
| P1 1 m/s yan rüzgâr | 0,9 | 2,5 | 5,8 | 10,5 |
| P2 1 m/s yan rüzgâr | 0,3 | 0,9 | 2,0 | 3,6 |
| Sight height +5 mm | 0 | 0,3 | 0,7 | 1,2 |

Sonuç: ateşli tüfekte hata bütçesini rüzgâr, hız (sıcaklık ve SD) ve BC/
sürüklenme modeli domine ediyor. PCP'de rüzgâr ve mesafe; 2,5 cm'lik
öldürme bölgesinde 50 m'de 5 m mesafe hatası tek başına ıska demek.

## 3. Öneriler

Her öneri: ne işe yarar · isabete etkisi · ek girdi · zorluk · kaynak.

### Ö1 — Mühimmat sıcaklığı ayrı girdi (ateşli tüfek)
- Ne işe yarar: barut sıcaklık düzeltmesi bugün hava sıcaklığıyla yapılıyor.
  Güneşte, sıcak araçta ya da sıcak namluda bekleyen fişek havadan 10–20 °C
  sıcak olur. Hız düzeltmesi fişeğin sıcaklığıyla yapılmalı.
- Etki: k = %1,5/15 °C (fabrika fişeklerinde sık görülen mertebe), 15 °C
  fark → T1 +11,9 m/s → 800 m'de ≈ 28 cm ≈ 3,5 klik; 1000 m'de ≈ 55 cm.
  300 m'de ≈ 2,6 cm.
- Ek girdi: "Mühimmat sıcaklığı" °C (boşsa hava sıcaklığı kullanılır).
- Zorluk: düşük (1 alan, mevcut `PowderTemperature.factor` aynen kalır).
- Kaynak: Litz, B. *Modern Advancements in Long Range Shooting*, Vol. 1,
  Applied Ballistics, 2014 (barut sıcaklığı ve hız testleri); Hodgdon,
  "Extreme Powders temperature sensitivity" teknik bilgi sayfası
  (https://hodgdon.com); McCoy, R. *Modern Exterior Ballistics*, Schiffer,
  1999 (hız–sıcaklık duyarlılığı kavramı).

### Ö2 — Gözlemle rüzgâr seçimi ve rüzgâr belirsizliği
- Ne işe yarar: atıcıların çoğunun anemometresi yok; rüzgâr hızı "tahmin"
  yazılıyor. Kara üzerindeki Beaufort tanımları (duman, yaprak, dal, toz)
  Türkçe bir listeden seçilir; uygulama sınıfın orta değerini Rüzgâr
  hızına, üst sınırını En yüksek rüzgâra yazar. WEZ rüzgâr belirsizliği
  böylece gerçek bir aralıktan gelir. Ek olarak Hedef ekranında rüzgârın
  yol boyunca hangi bölümünün ne kadar etkili olduğu yüzde olarak gösterilir
  (yakın rüzgâr en önemli: T1 800 m'de %45 / %37 / %18).
- Etki: rüzgâr en büyük kaynak; 1 m/s hata T1'de 600 m 23 cm, 800 m 46 cm;
  P1'de 50 m 2,5 cm, 75 m 5,8 cm. Kaba tahmin hatası (ör. 3 yerine 6 m/s)
  800 m'de 1,4 m'lik ıskadır; gözlem listesi bunu bir Beaufort sınıfının
  genişliğine (≈ ±1–1,5 m/s) indirir. Bölge yüzdeleri atıcının bakacağı
  yeri doğru seçmesini sağlar.
- Ek girdi: Rüzgâr gözlemi (liste). Yazı yok.
- Zorluk: düşük–orta.
- Kaynak: WMO, *Manual on Codes / Guide to Meteorological Instruments and
  Methods of Observation* (WMO-No. 8), Beaufort ölçeği
  (https://library.wmo.int); MeteoSwiss Beaufort tablosu
  (https://www.meteoswiss.admin.ch/dam/jcr:c1064242-4a6e-4df2-8d21-96e68d1def7a/Beaufort_Tabelle_en.pdf);
  Litz, B. *Accuracy and Precision for Long Range Shooting*, Applied
  Ballistics, 2012 (WEZ ve rüzgâr belirsizliğinin baskınlığı); McCoy 1999
  bölüm 5 (rüzgâr sapması, "lag" formülü: sapma yolun başındaki rüzgâra
  daha duyarlı).

### Ö3 — Kronograf serisi: ortalama hız, SD, ES; barut katsayısını ölçümden bulma; PCP atış dizisi
- Ne işe yarar: profil hızı tek sayı. Atıcı kronograf hızlarını alt alta
  girer; uygulama ortalama, SD, ES ve n'yi hesaplar, ortalamayı profile,
  SD'yi WEZ'e aktarır. Farklı sıcaklıklarda kaydedilmiş en az iki seriden
  barut katsayısı (k, T0) en küçük kareler ile bulunur. PCP'de seri atış
  sırasıyla girildiği için hızın dizide düşmesi (regülatör dışı / dolum
  basıncı) eğim olarak raporlanır: "ilk 10 atışta hız 12 m/s düştü".
- Etki: hız hatası 10 m/s → T1 800 m 24 cm (3 klik). SD 5 m/s → T1 800 m
  dikey σ ≈ 12 cm. P1'de 20 m/s'lik dizi ES'i → 50 m ±1,2 cm, 75 m ±2,8 cm.
  Ölçülmüş k ile Ö1'in kazancı güvenilir hale gelir.
- Ek girdi: hız listesi, ölçüm günündeki mühimmat sıcaklığı, hız birimi
  (liste: m/s | fps).
- Zorluk: orta.
- Kaynak: Litz 2012 (SD/ES'in dikey dağılıma katkısı); Courtney, M. &
  Courtney, A., "Accurate Measurements of Free Flight Drag Coefficients with
  Amateur Doppler Radar", arXiv:1608.06500 (https://arxiv.org/abs/1608.06500)
  — kronograf/radar ölçüm belirsizliği; NIST/SEMATECH *e-Handbook of
  Statistical Methods*, örnek standart sapma ve doğrusal regresyon
  (https://www.itl.nist.gov/div898/handbook/).

### Ö4 — İstasyon basıncını iPhone barometresinden almak
- Ne işe yarar: internet yokken bile gerçek istasyon basıncı. Core Motion
  `CMAltimeter` / `CMAltitudeData.pressure` (kPa) cihazın barometresini
  verir; QNH karışıklığı tamamen ortadan kalkar.
- Etki: 1000 m irtifada QNH yazılırsa T1 800 m'de 57 cm (7 klik); 10 hPa
  hata 800 m'de 5 cm, 1000 m'de 14 cm.
- Ek girdi: yok ("Basıncı telefondan al" düğmesi).
- Zorluk: orta (iOS platform kanalı + izin metni; telefonun içi/ cebi
  sıcaklığı basıncı etkilemez, ancak araç içi/klima farkı uyarısı gerekir).
- Kaynak: Apple Developer, CMAltimeter
  (https://developer.apple.com/documentation/coremotion/cmaltimeter),
  CMAltitudeData.pressure
  (https://developer.apple.com/documentation/coremotion/cmaltitudedata/pressure);
  ICAO Doc 7488 *Manual of the ICAO Standard Atmosphere* (QNH / istasyon
  basıncı ilişkisi).

### Ö5 — Kararlılık kontrolü: Sg uyarısı, düşük Sg'de BC azaltması, transonik uyarısı
- Ne işe yarar: Sg zaten hesaplanıyor. Sg < 1,0 → "mermi kararsız, bu
  yiv/hız ile kullanmayın"; 1,0–1,5 → "BC katalog değerinin altında
  kalabilir"; mermi hedefte Mach 1,2'nin altına iniyorsa "transonik:
  düşüm belirsizliği artar, hız/BC doğrulaması yapın". Sg'yi menzil
  boyunca (hız azaldıkça Sg artar) değil namlu ağzında ve en soğuk/yoğun
  hava için hesaplamak doğru kontrol noktasıdır.
- Etki: BC %5 düşükse T1 800 m'de 29 cm, 1000 m'de 75 cm. Litz'in atış
  testlerinde Sg 1,5'in altına indikçe BC'nin birkaç yüzde düştüğü
  gösterilmiş (oran tablo olarak kaynakta; uygulamaya alınmadan önce o
  tablodan doğrulanmalı).
- Ek girdi: mermi uzunluğu (mevcut). Öneri: `bullet_library.dart`'a üretici
  belgelerinden mermi uzunluğu eklenirse elle giriş kalkar.
- Zorluk: düşük.
- Kaynak: Miller, D. "A New Rule for Estimating Rifling Twist", *Precision
  Shooting*, Mart 2005; Litz, *Modern Advancements…* Vol. 1, "Stability and
  BC" bölümü; Berger Bullets, Litz "Bullet stability and BC"
  (https://bergerbullets.com/?p=5677); McCoy 1999 bölüm 10 (jiroskopik
  kararlılık).

### Ö6 — Çok mesafeli doğrulama (Mach'a bağlı sürüklenme ölçeği)
- Ne işe yarar: bugün hız ya da BC tek mesafede doğrulanıyor. Tek BC,
  özellikle transonikte, gerçek Cd eğrisini temsil etmez. Önerilen akış:
  (1) hız yakın/orta mesafede (süpersonik bölge) doğrulanır, (2) uzak
  mesafelerdeki gözlemlerden Mach bantlarına göre Cd ölçek katsayıları
  (ör. M > 2, 1,5–2, 1,2–1,5, < 1,2) bulunur ve özel Cd eğrisi olarak
  kaydedilir. Mevcut `DragCurve`/`dragTable` yolu kullanılır.
- Etki: 800 m ötesinde %3–5'lik sürüklenme hatası T1'de 1000 m'de 45–75 cm;
  doğru veriyle birkaç cm'ye iner.
- Ek girdi: her mesafe için gözlenen düzeltme (mevcut doğrulama ekranı gibi),
  en az 3 mesafe.
- Zorluk: orta–yüksek (çok değişkenli uydurma, aşırı uyum koruması).
- Kaynak: McCoy 1999 bölüm 4–7 (Cd–Mach eğrisi, form faktörü);
  Courtney & Courtney, "The Truth About Ballistic Coefficients",
  arXiv:0705.0389 (https://arxiv.org/abs/0705.0389) — tek BC'nin hıza bağlı
  değişimi; arXiv:1608.06500 (Doppler ile Cd ölçümü).

### Ö7 — Avcı sıfırı / en uzun tutuşsuz menzil (MPBR)
- Ne işe yarar: mesafe ölçülemeyen avda (yaban domuzu, tilki) ilk atış.
  Hedef bölge çapı seçilir; uygulama bu bölgede kalan en uzun menzili ve
  bunu sağlayan sıfır mesafesini hesaplar.
- Etki: T1, 15 cm hayati bölge: sıfır 200 m → 10–230 m arasında tutuş
  gerekmez. P1, 2,5 cm öldürme bölgesi: sıfır 16 m → 11–44 m; P2 4 cm:
  sıfır 50 m → 9–57 m.
- Ek girdi: hedef bölge çapı (liste: 2,5 / 4 / 10 / 15 / 20 cm).
- Zorluk: düşük (mevcut çözücüyle tarama).
- Kaynak: McCoy 1999 bölüm 2 (düz ateş yörüngesi); Carlucci & Jacobson,
  *Ballistics: Theory and Design of Guns and Ammunition*, CRC Press, 3. bs.
  2018, dış balistik bölümü.

### Ö8 — PCP: paralaks tekerleğiyle mesafe tablosu
- Ne işe yarar: yüksek büyütmeli PCP dürbünlerinde paralaks (yan
  odak) ayarı mesafeyi birkaç metre içinde verir. Atıcı bilinen
  mesafelerde tekerlek işaretini kaydeder; sahada işareti listeden seçer,
  uygulama mesafeyi ara değerleyip kullanır.
- Etki: P1'de mesafe hatası ±5 m'den ±2 m'ye inerse 50 m'de ±2,3 → ±0,9 cm,
  75 m'de ±5,3 → ±2,1 cm.
- Ek girdi: kalibrasyon çiftleri (tekerlek işareti, mesafe).
- Zorluk: düşük–orta.
- Kaynak: optik alan derinliği ve paralaks: Hecht, E. *Optics*, 5. bs.,
  Pearson 2017 (ince mercek, odak ve görüntü düzlemi); dürbün üreticisi
  kullanım kılavuzları (paralaks ayarı).

### Ö9 — Atış günlüğü ve soğuk namlu kaçıklığı
- Ne işe yarar: her atış oturumunda tarih, mesafe, verilen düzeltme, gözlenen
  vuruş kaçıklığı, ilk atış mı, susturucu takılı mı kaydedilir. Soğuk/temiz
  namlunun ilk atışının ortalama kaçıklığı (ör. 0,5 MOA yukarı) ilk atışa
  ayrı bir sıfır kaçıklığı olarak uygulanır. Kayıtlar Ö6 için veri olur.
- Etki: tipik 0,5 MOA ilk atış kayması 300 m 4,4 cm, 600 m 8,7 cm; "ilk
  atışta isabet" hedefi için doğrudan.
- Ek girdi: oturum kayıtları.
- Zorluk: orta.
- Kaynak: Litz 2012 (soğuk namlu ve sistematik kaymalar); NIST e-Handbook
  (ortalama ve güven aralığı).

### Ö10 — Sıfır grubunun merkezi ve gereken atış sayısı
- Ne işe yarar: sıfır kaçıklığı bugün elle yazılıyor. Hedef üzerine
  dokunarak vuruşlar işaretlenir; grup merkezi, σ ve merkezin belirsizliği
  (σ/√n) hesaplanır; "merkez belirsizliği X klikten büyük, 2 atış daha" der.
- Etki: σ = 0,1 mrad (≈ 1 MOA'lık 5'li grup) tüfekte 3 atışla merkez hatası
  0,058 mrad → 800 m'de 4,6 cm; 10 atışla 2,5 cm. PCP'de σ daha büyük
  olduğundan etki orantılı artar.
- Ek girdi: dokunulan vuruş noktaları.
- Zorluk: orta.
- Kaynak: Grubbs, F. "Statistical Measures of Accuracy for Riflemen and
  Missile Engineers", 1964; NIST e-Handbook.

### Ö11 — Atış öncesi kontrol listesi
- Ne işe yarar: kule doğru yöne/doğru tura çevrildi mi, paralaks ayarlı
  mı, su terazisi, birim (MRAD/MOA), SFP'de büyütme doğru mu, profil doğru
  mu. Kaba hatalar (yanlış tur, yanlış birim) ıskanın en sık sebebidir ve
  hiçbir model bunları düzeltemez.
- Etki: kaba hatalarda tam ıska (ör. 1 tur = 10 mrad = 800 m'de 8 m)
  önlenir; olasılık temelli, cm ile ifade edilemez.
- Ek girdi: yok (işaret kutuları).
- Zorluk: düşük.
- Kaynak: Litz 2012; insan hatası ve kontrol listeleri: Gawande, A. *The
  Checklist Manifesto*, 2009.

### Ö12 — WEZ'de ortak ve atıştan atışa hataların ayrılması
- Ne işe yarar: mesafe, rüzgâr ve BC hatası bir seri içinde bütün atışlar
  için aynıdır; grup ve SD her atışta değişir. "En az bir isabet" bu ayrımla
  hesaplanırsa 3–5 atış için gerçekçi sonuç çıkar (bugünkü formül iyimser).
- Etki: isabet olasılığı göstergesinin dürüstlüğü; cm kazancı değil, karar
  kalitesi (atış yapıp yapmama, yaklaşma).
- Ek girdi: yok.
- Zorluk: düşük–orta (`Wez.simulate` iç döngüsü iki katmanlı).
- Kaynak: Litz 2012 (WEZ yöntemi); Monte Carlo: Metropolis & Ulam,
  "The Monte Carlo Method", *J. Amer. Stat. Assoc.* 44 (1949).

### Ö13 — Doğrulama altyapısı (PCP GA tablosu dahil)
- Ne işe yarar: (a) iki kronografla (yakın ve uzak) ölçülen hızlardan BC
  hesabı zaten Hesaplayıcılar'da; bunun PCP saçmalarında GA tablosunu
  doğrulamak için saha protokolü olarak yazılması; (b) gerçek atış
  günlüklerinden (Ö9) üretilen anonim olmayan, sahibin kendi verisiyle
  regresyon fikstürleri; (c) her sürümde duyarlılık testleri (hız +1 m/s
  → düzeltme işareti ve büyüklüğü bölüm 2 ile uyumlu mu).
- Etki: modeldeki gizli hataların sahaya çıkmadan yakalanması.
- Zorluk: orta.
- Kaynak: Courtney & Courtney arXiv:1608.06500; UCL, "Influence of air rifle
  pellet …" (https://discovery.ucl.ac.uk/id/eprint/10072258/) — diabolo
  saçmada sürüklenmenin hıza güçlü bağlılığı.

### Elenen / ertelenen
- Sıfırlama günü hava koşulları (K3): < 1 cm, gereksiz girdi.
- Dikey rüzgâr ve eğimli arazi akışı: ölçülemeyen girdi; etkisi rüzgâr
  belirsizliğine dahil edilebilir.
- Bluetooth lazer mesafe ölçer / hava ölçer entegrasyonu: üretici SDK'ları
  kapalı ve lisanslı; ayrı iş olarak değerlendirilmeli.

## 4. Öncelik tablosu

Etki 1–5 (bölüm 2 sayılarına göre), zorluk 1–5 (1 = kolay). Puan = etki /
zorluk.

| Sıra | Öneri | Platform | Etki | Zorluk | Puan |
|---|---|---|---|---|---|
| 1 | Ö1 Mühimmat sıcaklığı | Ateşli | 4 | 1 | 4,0 |
| 2 | Ö2 Gözlemle rüzgâr + bölge payları | İkisi | 5 | 2 | 2,5 |
| 3 | Ö7 MPBR / avcı sıfırı | İkisi | 3 | 1 | 3,0 |
| 4 | Ö5 Kararlılık ve transonik uyarısı | Ateşli | 3 | 1 | 3,0 |
| 5 | Ö11 Kontrol listesi | İkisi | 3 | 1 | 3,0 |
| 6 | Ö3 Kronograf serisi | İkisi | 4 | 2 | 2,0 |
| 7 | Ö8 Paralaks mesafe tablosu | PCP | 3 | 2 | 1,5 |
| 8 | Ö12 WEZ ortak hata | İkisi | 2 | 2 | 1,0 |
| 9 | Ö4 iPhone barometresi | İkisi | 3 | 3 | 1,0 |
| 10 | Ö9 Atış günlüğü / soğuk namlu | İkisi | 3 | 3 | 1,0 |
| 11 | Ö6 Çok mesafeli doğrulama | Ateşli | 4 | 4 | 1,0 |
| 12 | Ö13 Doğrulama altyapısı | İkisi | 3 | 3 | 1,0 |
| 13 | Ö10 Sıfır grubu merkezi | İkisi | 2 | 3 | 0,7 |

Uygulama sırası puandan biraz sapıyor (K4): Ö3, Ö7/Ö5/Ö11'in önüne alındı;
çünkü Ö1'in barut katsayısı ve WEZ'in SD'si ancak ölçülmüş veriyle
güvenilir, Ö6/Ö9/Ö13 de Ö3'ün ürettiği veriye dayanıyor. Ö7, Ö5 ve Ö11
küçük oldukları için ilk üçten hemen sonra tek bir sürümde toplanabilir.

## 5. Arayüz önerisi (sahibin UI kurallarına göre)

Ortak kurallar: liste seçimi yazmaya tercih; her girilen değerin ⓘ
açıklaması `info:` ile; alan altında yardım yazısı yok; etiketlerde
parantez yok; kalın yazı yok; kutu içinde örnek değer (`hintText`) yok;
iki kutu yan yana; metinler Türkçe; "Sight height" İngilizce kalır.

- Ö1 — Hava Durumu, ateşli tüfekte: `Sıcaklık | Mühimmat sıcaklığı` aynı
  satırda (MenzilInput, birim °C/°F). PCP'de ikinci kutu yok, satırda
  Sıcaklık yanında mevcut sıradaki alan kalır. ⓘ: "Fişeğin kendi sıcaklığı.
  Güneşte veya araçta bekleyen fişek havadan 10–20 °C sıcak olabilir; hız bu
  sıcaklıkla düzeltilir. Fişek kutusuna dokunarak veya bir termometreyle
  ölçün. Boş bırakılırsa hava sıcaklığı kullanılır. Örnek: 32 °C."
- Ö2 — Hava Durumu, Rüzgâr hızı satırının üstünde tam satır `Rüzgâr gözlemi`
  (MenzilSelect, `hint: 'Seçiniz'`, öğe metinleri uzun olduğundan tam satır;
  kapalı kutuda `selectedLabels` ile kısa ad: "Sakin", "Çok hafif", "Hafif",
  "Orta", "Orta-kuvvetli", "Kuvvetli", "Çok kuvvetli"). Açık listede tanım:
  "Hafif: yapraklar hışırdar, yüzde hissedilir". Seçince Rüzgâr hızı ve En
  yüksek rüzgâr dolar; atıcı yine elle değiştirebilir. ⓘ: "Anemometre yoksa
  rüzgârı çevreden okuyun: duman, yaprak, dal, toz. Seçtiğiniz sınıfın orta
  değeri Rüzgâr hızına, üst değeri En yüksek rüzgâra yazılır. Örnek: dallar
  sürekli sallanıyorsa Orta." Hedef ekranında rüzgâr satırında sonuç olarak
  (yardım yazısı değil): "Rüzgâr etkisi: yakın %45 · orta %37 · uzak %18".
- Ö3 — Araçlar > `Kronograf` (yeni kart). Satırlar: `Profil` tam satır
  (liste); `Hız birimi | Mühimmat sıcaklığı` (liste | sayı); `Hızlar` çok
  satırlı kutu, her satıra bir hız (sayı girişi kaçınılmaz; ölçüm
  değeri listeden seçilemez). Sonuç kartı: Ortalama, SD, ES, Atış sayısı,
  PCP'de Dizi eğimi. Düğmeler: "Profile hız olarak aktar", "SD'yi WEZ'e
  aktar", iki farklı sıcaklıkta kayıt varsa "Barut katsayısını hesapla".
  ⓘ metinleri `lib/features/tools/chrono_field_info.dart` içinde.
- Ö7 — Pro Ayarlar veya Araçlar: `Hedef bölge çapı` liste (2,5 / 4 / 10 /
  15 / 20 cm) tam satır; sonuç "Sıfır 200 m: 10–230 m arası tutuşsuz".
- Ö5 — yeni girdi yok; Hedef'teki mevcut uyarı alanında tek satır.

## 6. İlk 3 öneri için uygulama planları (writing-plans formatı)

---

# Ö1 Mühimmat sıcaklığı Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Barut sıcaklık düzeltmesini hava sıcaklığı yerine (girildiyse) mühimmat sıcaklığıyla yapmak.

**Architecture:** `PowderTemperature`'a tek bir saf fonksiyon eklenir; Atış ve Hız Doğrulama aynı fonksiyonu kullanır. Değer profil başına `ShotSettings`'te saklanır. Çözücü değişmez.

**Tech Stack:** Flutter/Dart, shared_preferences, flutter_test.

**Spec:** bu belge, Ö1 ve bölüm 5.

## Global Constraints
- Yalnız `WeaponPlatform.firearm`; PCP'de alan görünmez ve değer kullanılmaz.
- Boş alan = hava sıcaklığı (bugünkü davranış birebir korunur).
- Kabul aralığı `PowderTemperature.minTempC`..`maxTempC` (−50..60 °C); dışı = hava sıcaklığı.
- UI kuralları bölüm 5; ⓘ metni bölüm 5'teki Ö1 metni.
- Doğrulama: `tools/claude_flutter_verify.sh` (CLAUDE.md).

## Review Focus
- °F seçili profilde girilen değer °C'ye çevrilmeden faktöre giderse hız yanlış olur → test.
- Virgüllü ondalık ("32,5") okunmalı → test.
- Profil değişince önceki profilin mühimmat sıcaklığı taşınmamalı → test.
- Barut katsayısı yokken alan dolu olsa bile hız değişmemeli → test.
- Hız Doğrulama ile Atış aynı hızı göstermeli (çift düzeltme yok) → test.

### Task 1: Saf fonksiyon

**Files:**
- Modify: `lib/core/powder_temperature.dart`
- Test: `test/powder_temperature_profile_test.dart`

**Interfaces:**
- Produces: `static double PowderTemperature.effectiveTempC({required double airC, double? ammoC})`

- [ ] Step 1: Test yaz:
```dart
test('ammo temperature replaces air temperature when valid', () {
  expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: 33), 33);
  expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: null), 18);
  expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: 75), 18);
  expect(PowderTemperature.effectiveTempC(airC: 18, ammoC: double.nan), 18);
});
```
- [ ] Step 2: `flutter test test/powder_temperature_profile_test.dart` → FAIL (tanımsız).
- [ ] Step 3: Fonksiyonu yaz (geçerli aralıktaysa `ammoC`, değilse `airC`).
- [ ] Step 4: Aynı komut → PASS.
- [ ] Step 5: Commit `feat: mühimmat sıcaklığı için effectiveTempC`.

### Task 2: Saklama

**Files:**
- Modify: `lib/services/shot_settings_store.dart`
- Test: `test/shot_settings_test.dart`

**Interfaces:**
- Produces: `ShotSettings.ammoTempText` (String, varsayılan `''`, JSON anahtarı `'ammoTemp'`).

- [ ] Step 1: Test: `ShotSettings(ammoTempText: '32,5')` → `toJson` → `fromJson` aynı metni verir; anahtarı olmayan eski JSON `''` verir.
- [ ] Step 2: Çalıştır → FAIL.
- [ ] Step 3: Alanı ekle (diğer `…Text` alanlarıyla aynı kalıp).
- [ ] Step 4: PASS.
- [ ] Step 5: Commit.

### Task 3: Atış ekranı ve Hız Doğrulama

**Files:**
- Modify: `lib/features/ballistics/ballistics_screen.dart` (`_powderAdjusted` çağrısı ~1154, Sıcaklık satırı ~2510, `_saveShotSettings`/yükleme)
- Modify: `lib/features/ballistics/environment_field_info.dart` (`static const ammoTemperature`)
- Modify: `lib/features/tools/truing_screen.dart` (~211–220: `todayTempC` yerine `effectiveTempC`)
- Test: `test/ballistics_environment_wiring_test.dart`, `test/truing_screen_test.dart`

**Interfaces:**
- Consumes: `PowderTemperature.effectiveTempC`, `ShotSettings.ammoTempText`.

- [ ] Step 1: Widget testleri:
  - ateşli profil + k=1,5, T0=21: hava 21 °C, mühimmat 36 °C → hesaplanan hız `v0·1.015` (±0,05 m/s);
  - aynı profil PCP olarak → `find.byKey(Key('env-ammo-temp'))` yok;
  - °F profilinde 97 °F → 36,1 °C ile aynı hız;
  - katsayı yokken alan 36 → hız `v0`;
  - truing ekranında aynı girdilerle temel hız Atış ile eşit.
- [ ] Step 2: Çalıştır → FAIL.
- [ ] Step 3: `ammoTempCtl` (Key `env-ammo-temp`), Sıcaklık ile aynı `Row`'da; birim çevirisi Sıcaklık alanıyla aynı yardımcıdan; `_powderAdjusted(v, PowderTemperature.effectiveTempC(airC: temp, ammoC: ammo))`; ⓘ `EnvironmentFieldInfo.ammoTemperature`. DOPE kartında "Mühimmat" sıcaklığı satırı (girildiyse).
- [ ] Step 4: `flutter test` ilgili dosyalar → PASS; ardından `tools/claude_flutter_verify.sh`.
- [ ] Step 5: Commit.

---

# Ö2 Gözlemle rüzgâr seçimi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Beaufort kara tanımlarından rüzgâr hızı ve belirsizliği doldurmak; Hedef'te rüzgârın yol bölümlerine göre payını göstermek.

**Architecture:** `lib/core/wind_observation.dart` saf veri + fonksiyonlar; pay hesabı mevcut `WindZones` ile çözücüyü üç kez çalıştırır (yeni fizik yok). UI yalnız mevcut kontrolleri doldurur.

**Tech Stack:** Flutter/Dart, flutter_test.

**Spec:** bu belge, Ö2 ve bölüm 5.

## Global Constraints
- Sınıflar ve sınırlar (m/s, 10 m yükseklik, WMO): 0: 0–0,2; 1: 0,3–1,5; 2: 1,6–3,3; 3: 3,4–5,4; 4: 5,5–7,9; 5: 8,0–10,7; 6: 10,8–13,8. Yalnız 0–6 (daha kuvvetli rüzgârda uzun atış önerilmez).
- Atış yerinde yer seviyesi rüzgârı 10 m değerinden düşüktür; ⓘ bunu söyler, uygulama düzeltme katsayısı uydurmaz.
- Orta değer = (alt + üst) / 2, yalnız Sakin için 0; En yüksek rüzgâr = üst; sigma = (üst − alt) / 4 (aralık ≈ ±2σ, `Wez.sigmaOfPlusMinus` ile aynı kural).
- Elle girilen Rüzgâr hızı her zaman önceliklidir; gözlem seçimi yalnız seçildiği anda doldurur.
- UI kuralları bölüm 5.

## Review Focus
- mph profili: dolan değer mph'e çevrilmeli → test.
- "Sakin" seçilince Rüzgâr hızı 0,1 değil 0 olmalı ve En yüksek rüzgâr 0,2 → test.
- Atıcı seçimden sonra Rüzgâr hızını elle değiştirirse gözlem seçimi "Seçiniz"e dönmeli (yanlış etiket kalmamalı) → test.
- Vakum (BC'siz) modda bölge payları gösterilmemeli → test.
- Bölge payları toplamı %100 (yuvarlama ±1) → test.

### Task 1: Veri modeli

**Files:**
- Create: `lib/core/wind_observation.dart`
- Test: `test/wind_observation_test.dart`

**Interfaces:**
- Produces: `enum WindObservation { calm, lightAir, lightBreeze, gentleBreeze, moderateBreeze, freshBreeze, strongBreeze }` ve extension: `double get minMps`, `double get maxMps`, `double get midMps`, `double get sigmaMps`, `String get shortLabel`, `String get description`.

- [ ] Step 1: Testler: sınırlar Global Constraints ile birebir; ardışık sınıflar arasında boşluk ≤ 0,1 m/s; `midMps` aralık içinde; hiçbir etikette `(` yok; `shortLabel` listesi bölüm 5'teki yedi ad.
- [ ] Step 2: FAIL.
- [ ] Step 3: Yaz. `description` Türkçe kara tanımı (ör. lightBreeze: "Yüzde hissedilir, yapraklar hışırdar").
- [ ] Step 4: PASS.
- [ ] Step 5: Commit.

### Task 2: Bölge payları

**Files:**
- Modify: `lib/core/wind_observation.dart`
- Test: `test/wind_observation_test.dart`

**Interfaces:**
- Consumes: `BallisticInput`, `WindZones`, `BallisticEngine.solve`.
- Produces: `({double near, double mid, double far})? windShareByThird(BallisticInput input, double rangeM)` — 1 m/s tam yan rüzgârı (90°) yalnız bir bölgede uygulayıp her bölgenin yatay sapmasını toplam üçe böler; çözülemezse veya BC yoksa null.

- [ ] Step 1: Test: T1 girdisiyle (bölüm 0) 800 m'de `near ≈ 0.45`, `mid ≈ 0.37`, `far ≈ 0.18` (±0,04); toplam 1 ± 1e-9; `near > far`; BC'siz girdide null.
- [ ] Step 2: FAIL.
- [ ] Step 3: Yaz. Yakın bölge için çevre rüzgârı 1 m/s, `WindZones(rangeM, midMps: 0, farMps: 0)`; orta için çevre 0, mid 1, far 0; uzak için çevre 0, mid 0, far 1.
- [ ] Step 4: PASS.
- [ ] Step 5: Commit.

### Task 3: Arayüz

**Files:**
- Modify: `lib/features/ballistics/ballistics_screen.dart` (Rüzgâr hızı satırı ~2578, `_autoWindMax`, Hedef rüzgâr satırı)
- Modify: `lib/features/ballistics/environment_field_info.dart` (`windObservation`)
- Modify: `lib/services/shot_settings_store.dart` (`windObservation` enum adı, JSON `'windObs'`)
- Test: `test/ballistics_environment_wiring_test.dart`, `test/shot_settings_test.dart`

**Interfaces:**
- Consumes: Task 1–2.

- [ ] Step 1: Widget testleri: "Hafif" seçimi → Rüzgâr hızı "2,5" (m/s) / "5,5" (mph), En yüksek rüzgâr "3,3"/"7,4"; elle değişim → seçim null; Hedef'te `find.textContaining('Rüzgâr etkisi')` ateşli BC'li profilde var, vakumda yok; ayar kaydı/yüklemesi.
- [ ] Step 2: FAIL.
- [ ] Step 3: MenzilSelect (Key `env-wind-obs`, `hint: 'Seçiniz'`, `selectedLabels: shortLabel`), seçimde `wind.text` ve `windMaxCtl.text` doldur, `_windMaxAuto = false`. Hedef'te pay satırı `_shotCache` ile önbellekli.
- [ ] Step 4: PASS + `tools/claude_flutter_verify.sh`.
- [ ] Step 5: Commit.

---

# Ö3 Kronograf serisi Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Kronograf hızlarından ortalama/SD/ES/dizi eğimi; profile ve WEZ'e aktarım; çok seriden barut katsayısı.

**Architecture:** Saf hesap `lib/core/velocity_series.dart`; oturumlar profil başına `lib/services/chrono_store.dart` (SharedPreferences, `ShotSettingsStore` kalıbı); yeni ekran `lib/features/tools/chrono_screen.dart`. Profil yazımı mevcut profil kaydetme yolundan.

**Tech Stack:** Flutter/Dart, shared_preferences, flutter_test.

**Spec:** bu belge, Ö3 ve bölüm 5.

## Global Constraints
- Ayırıcılar: satır sonu, boşluk, `;`. Virgül ondalık işaretidir ("812,4").
- Geçerli hız: 50–1500 m/s (`ProductionLimits` ile uyumlu); dışı reddedilir ve hangi satır olduğu söylenir.
- SD örnek standart sapmasıdır (n − 1); n < 3 iken SD gösterilmez ("en az 3 atış").
- Barut katsayısı uydurma: en az 2 farklı sıcaklıkta seri, sıcaklık açıklığı ≥ 10 °C; sonuç `|k| ≤ PowderTemperature.maxCoef`, aksi halde reddedilir. T0 = serilerin ağırlıklı ortalama sıcaklığı; k = eğim·15/v(T0)·100.
- PCP dizi eğimi: atış sırasına göre doğrusal regresyon eğimi (m/s/atış); yalnız PCP'de ve n ≥ 5 iken gösterilir.
- Profil hızı aktarılırken barut sıcaklığı varsa ortalama hız profilin referans sıcaklığına geri çevrilir (çift düzeltme yok).
- UI kuralları bölüm 5.

## Review Focus
- fps girilip m/s profile aktarılırsa çeviri atlanmamalı → test.
- Aynı sıcaklıkta iki seri ile katsayı istenirse açık ret mesajı → test.
- Boş satır / sondaki boşluk hata sayılmamalı → test.
- Profil silinince oturumlar yetim kalmamalı (store `deleteProfile`) → test.
- PCP'de barut katsayısı düğmesi görünmemeli → test.

### Task 1: Seri istatistiği

**Files:**
- Create: `lib/core/velocity_series.dart`
- Test: `test/velocity_series_test.dart`

**Interfaces:**
- Produces: `class VelocitySeries { final List<double> mps; int get n; double get mean; double? get sd; double get es; double? get slopePerShot; static VelocitySeries parse(String text, {required bool fps}); }` ve `class VelocitySeriesFormatException implements Exception { final int line; }`.

- [ ] Step 1: Testler: `parse('800\n805\n795', fps:false)` → mean 800, sd 5, es 10; `parse('2625;2641', fps:true)` → m/s'e çevrilmiş; `'812,4 811,6'` → iki değer; `'800\nabc'` → `line == 2`; n=2 → sd null; artan dizi `[280,279,278,277,276]` → slope −1.
- [ ] Step 2: FAIL.
- [ ] Step 3: Yaz.
- [ ] Step 4: PASS.
- [ ] Step 5: Commit.

### Task 2: Barut katsayısı uydurma

**Files:**
- Modify: `lib/core/velocity_series.dart`
- Test: `test/velocity_series_test.dart`

**Interfaces:**
- Produces: `({double coefPercentPer15C, double referenceC, double v0Mps})? fitPowderCoefficient(List<({double tempC, double meanMps, int n})> sessions)`; koşullar sağlanmazsa null.

- [ ] Step 1: Test: (5 °C, 790), (35 °C, 814) → k ≈ 1,50 %/15 °C, T0 20, v0 802 (±0,05); tek sıcaklık → null; açıklık 8 °C → null; k 12 çıkan veri → null.
- [ ] Step 2: FAIL.
- [ ] Step 3: n ağırlıklı en küçük kareler.
- [ ] Step 4: PASS.
- [ ] Step 5: Commit.

### Task 3: Oturum deposu

**Files:**
- Create: `lib/services/chrono_store.dart`
- Test: `test/chrono_store_test.dart`

**Interfaces:**
- Produces: `class ChronoSession { DateTime date; double tempC; List<double> mps; }`, `class ChronoStore { Future<List<ChronoSession>> load(String profileId); Future<void> add(String profileId, ChronoSession s); Future<void> deleteProfile(String profileId); }` — anahtar `'sniper_turk.chrono.$profileId'`.

- [ ] Step 1: Test: ekle → yükle aynı; bozuk JSON → boş liste; `deleteProfile` → anahtar yok (`SharedPreferences.setMockInitialValues`).
- [ ] Step 2: FAIL. Step 3: Yaz. Step 4: PASS. Step 5: Commit.

### Task 4: Kronograf ekranı ve aktarımlar

**Files:**
- Create: `lib/features/tools/chrono_screen.dart`, `lib/features/tools/chrono_field_info.dart`
- Modify: `lib/features/tools/tools_screen.dart` (kart "Kronograf", alt yazı "Hız serisi: ortalama, SD, ES; profile ve WEZ'e aktarım"), profil silme akışında `ChronoStore.deleteProfile`
- Test: `test/tools_screens_test.dart`, `test/tools_hub_order_test.dart`

**Interfaces:**
- Consumes: Task 1–3, `PowderTemperature.factor`, mevcut profil kaydetme ve `ShotSettings.sdText`.

- [ ] Step 1: Widget testleri: üç hız girince Ortalama/SD/ES kartı; "Profile hız olarak aktar" profil hızını (barut düzeltmesi geri alınmış) yazar; "SD'yi WEZ'e aktar" `ShotSettings.sdText`'e fps olarak yazar (mevcut alan fps); PCP profilinde katsayı düğmesi yok, n ≥ 5'te "Dizi eğimi" var; fps→m/s aktarımı; araç listesinde yeni kartın sırası.
- [ ] Step 2: FAIL.
- [ ] Step 3: Yaz; bütün alanlarda `info:` (`ChronoFieldInfo`), `helperText`/`hintText` yok, etiketlerde parantez yok.
- [ ] Step 4: PASS + `tools/claude_flutter_verify.sh`.
- [ ] Step 5: Commit.

---

Plan self-review: her Global Constraint bir teste bağlandı; tür adları
(`effectiveTempC`, `ammoTempText`, `WindObservation`, `windShareByThird`,
`VelocitySeries`, `fitPowderCoefficient`, `ChronoStore`) görevler arasında
tutarlı; hiçbir görev çözücüyü değiştirmiyor. Uygulama yöntemi seçimi
sahibe bırakıldı (öneri: üç plan birbirinden bağımsız, her biri tek
oturumda "Native" yürütülebilir; Ö3 dört görevli ve profil yazdığı için
"Subagent-driven" daha güvenli).

## 7. Doğrulama durumu (bu rapor için)

- Kod değişmediği için `tools/claude_flutter_verify.sh` çalıştırılmadı;
  CI'nin bu belge için anlamı yok.
- Bölüm 2 sayıları Ek A'daki bağımsız betikle üretildi (RK4, 0,5 ms,
  depodaki G1/G7 tabloları, nemli hava yoğunluğu). Uygulamanın çözücüsüyle
  karşılaştırılmadı; planlardaki test toleransları (ör. bölge payları ±0,04)
  bu yüzden geniş tutuldu ve uygulama sırasında uygulamanın kendi çözücüsüyle
  yeniden ölçülmeli.
- Ö5'teki Sg–BC ilişkisinin sayısal tablosu kaynaktan doğrulanmadan
  uygulamaya alınmamalı.

## Kaynakça

- McCoy, R. L. *Modern Exterior Ballistics*. Schiffer, 1999 (2. bs. 2012).
- Litz, B. *Applied Ballistics for Long Range Shooting*, 3. bs., 2015.
- Litz, B. *Accuracy and Precision for Long Range Shooting*, 2012.
- Litz, B. *Modern Advancements in Long Range Shooting*, Vol. 1, 2014.
- Carlucci, D. & Jacobson, S. *Ballistics: Theory and Design of Guns and Ammunition*, 3. bs., CRC, 2018.
- Miller, D. "A New Rule for Estimating Rifling Twist", *Precision Shooting*, 2005.
- Courtney, M. & Courtney, A. "The Truth About Ballistic Coefficients", arXiv:0705.0389 — https://arxiv.org/abs/0705.0389
- Courtney, M. et al. "Accurate Measurements of Free Flight Drag Coefficients with Amateur Doppler Radar", arXiv:1608.06500 — https://arxiv.org/abs/1608.06500
- Berger Bullets / Litz, bullet stability and BC — https://bergerbullets.com/?p=5677
- UCL Discovery, air rifle pellet aerodynamics — https://discovery.ucl.ac.uk/id/eprint/10072258/
- WMO-No. 8, *Guide to Instruments and Methods of Observation* — https://library.wmo.int
- MeteoSwiss Beaufort table — https://www.meteoswiss.admin.ch/dam/jcr:c1064242-4a6e-4df2-8d21-96e68d1def7a/Beaufort_Tabelle_en.pdf
- Apple CMAltimeter — https://developer.apple.com/documentation/coremotion/cmaltimeter
- Apple CMAltitudeData.pressure — https://developer.apple.com/documentation/coremotion/cmaltitudedata/pressure
- ICAO Doc 7488, *Manual of the ICAO Standard Atmosphere*.
- NIST/SEMATECH e-Handbook of Statistical Methods — https://www.itl.nist.gov/div898/handbook/
- Grubbs, F. E. "Statistical Measures of Accuracy for Riflemen and Missile Engineers", 1964.
- Hecht, E. *Optics*, 5. bs., Pearson, 2017.
- Gawande, A. *The Checklist Manifesto*, 2009.

## Ek A — Etki tahmini için kullanılan bağımsız hesap

Bu rapor için yazıldı; uygulamaya eklenmesi önerilmiyor. Nokta-kütle,
RK4 (dt = 0,5 ms), sürüklenme `a = ½·ρ·Cd(M)·(π/4)·v²/BC_SI`,
`BC_SI = BC·703,07 kg/m²`, Cd tabloları `lib/core/standard_drag_tables.dart`
içinden okunur, nem Magnus formülü, ses hızı `√(1,4·P/ρ)`. Sıfır açısı
ikiye bölme ile bulunur. Yan rüzgâr hava kütlesine göre bağıl hızla girer.
Bölüm 2'deki her satır: aynı girdiyle iki çözüm, tek değişkeni değiştirerek,
farkın hedef mesafesindeki cm karşılığı. Sıfır, "hız" ve "BC" satırlarında
sıfır nominal değerle sabit tutuldu (tüfek nominalde sıfırlanmış, atış günü
değer farklı).
