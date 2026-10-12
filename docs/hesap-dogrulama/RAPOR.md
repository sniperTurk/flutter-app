# Hesap doğrulaması: çözücü ve üretici balistik tabloları (2026-10-12)

Bu rapor, uygulamanın balistik çözücüsünü (`BallisticEngine.solve` →
`AerodynamicTrajectorySolver`, G1/G7, RK4, adım 0,5 ms) üreticilerin
**kendi sitelerinde** yayımladığı tablolarla karşılaştırır. Kaynak olarak
yalnızca üretici kullanıldı. ChairGun, Strelok, Applied Ballistics,
QuickLOAD, GRT ve JBM çıktısı kullanılmadı; forum, blog ve bayi sayfası da
kullanılmadı.

Test dosyası `test/uretici_tablo_dogrulama_test.dart`. Bu dosya 25 fişeği
çözücüye verir ve farkları aşağıdaki toleranslarla denetler.

## Kısa sonuç

- **25 fişek** incelendi: Hornady 8, Federal 6, Lapua 5, Berger 3, Norma 3.
  Kalibreler .308 Win, 6.5 Creedmoor, .223 Rem, .300 Win Mag, 7.62x39 ve
  .338 Lapua Mag.
- **600 m'ye kadar** çözücü ile üretici tablosu arasındaki en büyük yörünge
  farkı **0,037 mrad**. Bu, bir dürbün klikinin (0,1 mrad) üçte birinden
  küçüktür; 500 yd'de yaklaşık 1,7 cm eder. Hız farkı en çok %1,3, yan rüzgâr
  farkı en çok 0,13 mrad.
- **600–1000 m** (yalnız Lapua) arasında yörünge farkı en çok 0,16 mrad,
  rüzgâr farkı en çok 0,24 mrad, hız farkı en çok %2,7.
- **1000 m ötesinde** (ses hızına yaklaşma bölgesi) fark büyüyor: Lapua .338
  300 gr için 1500 m'de 0,75 mrad. Nedeni, Lapua'nın kendi Doppler ölçümlü
  sürüklenme eğrisini kullanması; uygulama ise standart G7 eğrisini kullanıyor.
- **Çözücüde hata bulunmadı.** Bu yüzden ayrı bir düzeltme commit'i yok.
  Farkların hepsi yuvarlama, belirtilmemiş atmosfer ve üreticinin sürüklenme
  modeliyle açıklanıyor (aşağıda ayrıntılı).
- **Kaynak verisinde bir tutarsızlık bulundu.** Lapua .338 LM 300 gr
  (4318013) tablosunun "600 m sıfır" satırı, aynı sayfadaki 100 m ve 300 m
  sıfır satırlarıyla çelişiyor (1500 m'de 718 mm). Bu satır teste alınmadı.
- **PCP slug/saçma:** Üreticilerden (H&N, JSB/Schulz, FX, Daystate, NSA)
  hiçbiri sitesinde hazır hesaplanmış bir yörünge tablosu yayımlamıyor. Var
  olan yalnızca etkileşimli hesaplayıcılar ve BC değerleri. Bu yüzden PCP
  karşılaştırması **yapılamadı**. Ayrıntı aşağıda.
- **MKE:** Tablo yayımlamıyor. Yalnız tekil değerler var; örneğin 7.62x51 M80
  için "Hız (23,7 m) 838 ± 9,1 m/s, BC 0,45 (G1)".

## Yöntem

1. Her fişeğin tablosu üreticinin ürün sayfasından okundu. Mümkün olanlar iki
   kez okunarak çapraz denetlendi (ürün sayfası ve katalog PDF'i ya da iki
   ayrı okuma). Hiçbir değer tahminle tamamlanmadı ya da enterpolasyonla
   üretilmedi.
2. Tablodaki koşullar çözücüye aynen verildi: namlu hızı, BC (üreticinin
   verdiği tek değer), nişan yüksekliği, sıfır mesafesi ve rüzgâr hızı.
   Rüzgâr tam yandan, soldan (saat 9) verildi.
3. Yörünge farkı hesabı: `Fark = uygulama − üretici`, nişan hattına göre ve
   "+ yukarı" işaretiyle. Fark, mesafeye bölünerek açıya çevrildi:
   1 mrad = mesafe/1000; 1 MOA = 0,2909 mrad.
   - Fark **negatifse**, uygulama mermiyi üreticiden **daha aşağıda**
     gösteriyor.
   - Rüzgâr için **pozitif fark**, uygulamanın **daha fazla** sürüklenme
     hesapladığı anlamına gelir.
4. Atmosfer: Hiçbir üretici sayfasında atmosfer yazmıyor (Berger yalnız
   "sea level conditions" diyor). Bu yüzden test ICAO standardını kullanır:
   15 °C, 1013,25 hPa, %0 nem. Bu aynı zamanda uygulamanın sıfırlama
   ortamının varsayılanı. Atmosfere duyarlılık ayrı bir tabloda verildi.
5. Tablolardaki sayılar, `lib/core/aerodynamic_trajectory_solver.dart`
   çözücüsünün satır satır Python'a aktarılmış bir kopyasıyla hesaplandı.
   Bu kopya aynı G1/G7 tablolarını `standard_drag_tables.dart` dosyasından
   okur. Kopya ve üretici verisi `tools/uretici_tablo_karsilastirma.py`
   dosyasındadır; rapordaki sayılar bu betikle yeniden üretilebilir. Dart testi ise asıl Dart kodunu çalıştırır, aynı toleranslarla.

### Toleranslar ve gerekçesi

| Mesafe | Yörünge | Hız | Yan rüzgâr |
|---|---|---|---|
| ≤ 600 m | 0,10 mrad | %1,5 | 0,15 mrad |
| 600–1000 m | 0,20 mrad | %3 | 0,30 mrad |

- **Açısal tolerans:** Dürbüne girilen düzeltme bir açıdır. 0,1 mrad bir
  kliktir. İlk atışta isabet için hedeflenen hata, 600 m içinde bir klikten
  azdır.
- **Yayımlanan değerler yuvarlanmış:** yörünge 0,1 inç veya 1 mm, hız 1 fps
  veya 1 m/s, rüzgâr 0,1 inç veya 1 mm. Örneğin Hornady'nin 0,1 inçlik
  yuvarlaması 100 yd'de tek başına ±0,014 mrad eder.
- **Atmosfer belirtilmemiş:** ICAO yerine Army Standard Metro seçmek, 500
  yd'de hızı yaklaşık %0,7 değiştirir (aşağıdaki tablo).
- **Sürüklenme modeli farkı:** Üreticiler kendi modelini kullanıyor. Lapua ve
  Hornady Doppler ölçümüne dayanan eğriler kullanıyor; uygulama standart
  G1/G7 eğrisi ve tek bir BC kullanıyor. Bu fark ses hızına yaklaştıkça
  büyür. Bu yüzden 600 m ötesinin toleransı iki katıdır. 1000 m ötesi teste
  alınmadı; farkları burada gösteriliyor.

## Kaynaklar ve tablo koşulları

Tüm sayfalar 2026-10-12 tarihinde okundu.

**Hornady**: ürün sayfaları ve 2022 Standard Ballistics Chart (PDF). BC
değerleri hornady.com/bc sayfasından alındı.

- Tablo: namlu ağzından 500 yd'ye kadar, 100 yd aralıklarla.
- Namlu 24" (.300 WM 178 gr için 26").
- **Belirtilmeyenler:** nişan yüksekliği, sıfır mesafesi, atmosfer, rüzgâr.
  Tablo namlu ağzında −1,5 ve 200 yd'de 0 gösteriyor; bu yüzden **1,5"
  nişan yüksekliği ve 200 yd sıfır** varsayıldı. Bu bir çıkarımdır,
  Hornady'nin yazılı ifadesi değildir.
- Rüzgâr sürüklenmesi yayımlanmıyor.
- BC: Hornady üç Mach değerinde BC veriyor (M2,25 / M2,0 / M1,75). Testte
  karşılaştırma esası olarak verilen M2,25 değeri (G7) kullanıldı. Üç bantlı
  sonuç ayrı tabloda.
- Kullanılan sayfalar:
  - H1: https://www.hornady.com/ammunition/rifle/308-win-168-gr-eld-match
  - H2: https://www.hornady.com/ammunition/rifle/308-win-178-gr-eld-x-precision-hunter
  - H3: https://www.hornady.com/ammunition/rifle/6-5-creedmoor-140-gr-eld-match
  - H4 ve H7: 2022 Standard Ballistics Chart, https://static.hornady.media/presscenter/docs/1410998060-2022-Standard-Ballistics-Chart.pdf
  - H5: https://www.hornady.com/ammunition/rifle/223-rem-73-gr-eld-match
  - H6: https://www.hornady.com/ammunition/rifle/300-win-mag-178gr-eld-x
  - H8: https://www.hornady.com/ammunition/rifle/338-lapua-285-gr-eld-match
  - BC: https://www.hornady.com/bc

**Federal** (Gold Medal ve Power-Shok ürün sayfaları):

- Sayfadaki ifade: "Sights 1.5 inches above bore line"; rüzgâr "Wind Drift
  in Inches (at 10 mph)".
- "Long Range" tablosu 200 yd'de sıfırlanıyor (sıfır hücresi yalnız simgeyle
  gösteriliyor). "Average Range" tablosu 100 yd'de sıfırlanıyor. İkisi de
  test edildi.
- Atmosfer ve namlu uzunluğu yazılmıyor. Sayfada önce G1 BC veriliyor;
  testte G1 kullanıldı.
- Kullanılan sayfalar:
  - F1: https://www.federalpremium.com/rifle/gold-medal/gold-medal-sierra-matchking/11-GM308M2.html
  - F2: https://www.federalpremium.com/rifle/gold-medal/gold-medal-berger/11-GM65CRDBH130.html
  - F3: https://www.federalpremium.com/rifle/gold-medal/gold-medal-sierra-matchking/11-GM223M.html
  - F4: https://www.federalpremium.com/rifle/gold-medal/gold-medal-sierra-matchking/11-GM300WM.html
  - F5: https://www.federalpremium.com/rifle/gold-medal/gold-medal-sierra-matchking/11-GM338LM2.html
  - F6: https://www.federalpremium.com/rifle/power-shok/11-76239B.html. 7.62x39 Fusion sayfası artık açılmıyor, onun yerine bu ürün kullanıldı.

**Lapua** (ürün sayfaları, metrik tablo):

- Sayfadaki ifade: "scope 40 mm above bore line", "sidewind 4 m/s". Sıfır
  mesafeleri 100, 300 ve 600 m; tablo 1500 m'ye kadar.
- Sayfada G1 ve G7 BC ikisi de veriliyor; testte G7 kullanıldı. Atmosfer
  yazmıyor.
- L4 için ürün özelliklerinde 890 m/s yazıyor, tablonun 0 m satırında ise
  905 m/s var. Tablo 905 m/s ile hesaplanmış olduğu için 905 kullanıldı.
- Kullanılan sayfalar:
  - L1: https://lapua.com/product/6-5-creedmoor-open-tip-match-target-cartridge-scenar-l88g-136gr-4316063
  - L2: https://www.lapua.com/product/308-win-target-cartridge-scenar-open-tip-match-12g-185gr-4317523/
  - L3: https://www.lapua.com/product/308-win-10-85-g-167-gr-scenar/
  - L4: https://www.lapua.com/product/338-lapua-mag-tactical-target-cartridge-scenar-162g-250gr-4318017/
  - L5: https://www.lapua.com/product/338-lapua-mag-tactical-target-cartridge-scenar-194g-300gr-4318013/

**Berger** (fişek ürün sayfaları):

- Sayfadaki ifade: "Performance based on a 26″ barrel and sea level
  conditions."
- Sıfır mesafesi yazmıyor; düşüş 200 yd'de 0, bu yüzden 200 yd sıfır
  varsayıldı. Nişan yüksekliği de yazmıyor; **1,5" varsayıldı**.
- Rüzgâr verisi yok. Testte G7 kullanıldı.
- Kullanılan sayfalar:
  - B1: https://bergerbullets.com/product/6-5-mm-creedmoor-140gr-hybrid-target/
  - B2: https://bergerbullets.com/product/308-winchester-185gr-juggernaut-otm-tactical/
  - B3: https://bergerbullets.com/product/338-lapua-magnum-300gr-hybrid-otm-tactical/

**Norma** (Bondstrike ürün sayfaları):

- Sayfadaki ifade: "Sight height is 40mm/1.6in". Testte 100 m sıfır
  satırının 50, 80, 150, 200 ve 300 m değerleri kullanıldı.
- Yalnız G1 BC veriliyor. Atmosfer yazmıyor.
- Rüzgâr sürüklenmesinin hangi rüzgâr hızıyla hesaplandığı yazmadığı için
  rüzgâr testi yapılmadı.
- Kullanılan sayfalar:
  - N1: https://www.norma-ammunition.com/products/hunting/norma-bondstrike/norma-bondstrike-308-winchester-180gr---20176412
  - N2: https://www.norma-ammunition.com/en-gb/products/dedicated-hunting/centerfire-rifle/norma-bondstrike/norma-bondstrike-65-creedmoor-143gr---20166402
  - N3: https://www.norma-ammunition.com/en-gb/products/dedicated-hunting/centerfire-rifle/norma-bondstrike/norma-bondstrike-300-winchester-magnum-180gr---20176332

**Kullanılmayan veya bulunamayan kaynaklar:**

- **Sako:** sako.global sayfalarında yalnız namlu hızı ve BC var, tablo yok.
  Tablo içeren resmî bir katalog PDF'i bulunamadı.
- **Sierra:** Sierra fişeğinin (Prairie Enemy) sayfasında tablo yalnız resim
  olarak var ve okunamadı.
- **Hornady 7.62x39 123 gr SST:** Hornady bu fişek için BC yayımlamıyor,
  bu yüzden çözücüye verilemedi.
- **Norma Golden Target:** sıfır tablosu sayfada eksik gösteriliyor.
- **Lapua imperial tablolar:** bazı satırlar sayfada bozuk (ör. "-82 -82
  -209"). Yalnız metrik tablolar kullanıldı.

## Özet tablo (ICAO atmosfer, testteki model)

| # | Fişek | Model (BC) | Yörünge en büyük fark ≤600 m (mrad) | Yörünge en büyük fark 600–1000 m (mrad) | Hız en büyük fark (%) | Rüzgâr en büyük fark (mrad) | Diğer model: yörünge en büyük fark, tüm satırlar (mrad) |
|---|---|---|---|---|---|---|---|
| H1 | Hornady .308 Win 168 gr ELD Match (80966) | G7 0.263 | 0.016 | — | 0.70 | — | G1: 0.016 |
| H2 | Hornady .308 Win 178 gr ELD-X Precision Hunter (80994) | G7 0.278 | 0.020 | — | 0.70 | — | G1: 0.021 |
| H3 | Hornady 6.5 Creedmoor 140 gr ELD Match (81500) | G7 0.326 | 0.034 | — | 1.32 | — | G1: 0.032 |
| H4 | Hornady 6.5 Creedmoor 143 gr ELD-X Precision Hunter (81499) | G7 0.314 | 0.008 | — | 0.34 | — | G1: 0.010 |
| H5 | Hornady .223 Rem 73 gr ELD Match (80269) | G7 0.2 | 0.028 | — | 1.09 | — | G1: 0.028 |
| H6 | Hornady .300 Win Mag 178 gr ELD-X Precision Hunter (82041) | G7 0.278 | 0.006 | — | 0.50 | — | G1: 0.011 |
| H7 | Hornady .300 Win Mag 200 gr ELD-X Precision Hunter (82002) | G7 0.301 | 0.013 | — | 0.64 | — | G1: 0.017 |
| H8 | Hornady .338 Lapua Mag 285 gr ELD Match (82300) | G7 0.417 | 0.012 | — | 0.41 | — | G1: 0.012 |
| F1 | Federal .308 Win 175 gr SMK Gold Medal (GM308M2) | G1 0.505 | 0.027 | — | 0.60 | 0.034 | G7: 0.045 |
| F2 | Federal 6.5 Creedmoor 130 gr Berger Hybrid Gold Medal (GM65CRDBH130) | G1 0.56 | 0.009 | — | 0.58 | 0.016 | G7: 0.007 |
| F3 | Federal .223 Rem 69 gr SMK Gold Medal (GM223M) | G1 0.301 | 0.021 | — | 1.13 | 0.033 | G7: 0.146 |
| F4 | Federal .300 Win Mag 190 gr SMK Gold Medal (GM300WM) | G1 0.533 | 0.013 | — | 0.60 | 0.013 | G7: 0.013 |
| F5 | Federal .338 Lapua Mag 300 gr SMK Gold Medal (GM338LM2) | G1 0.768 | 0.018 | — | 0.40 | 0.021 | G7: 0.018 |
| F6 | Federal 7.62x39 123 gr JSP Power-Shok (76239B) | G1 0.274 | 0.030 | — | 1.06 | 0.058 | — |
| L1 | Lapua 6.5 Creedmoor 136 gr Scenar-L (4316063) | G7 0.274 | 0.018 | 0.047 | 2.00 | 0.239 | G1: 0.119 |
| L2 | Lapua .308 Win 185 gr Scenar GB432 (4317523) | G7 0.242 | 0.037 | 0.085 | 1.90 | 0.121 | G1: 0.054 |
| L3 | Lapua .308 Win 167 gr Scenar GB422 (4317515) | G7 0.223 | 0.036 | 0.027 | 0.48 | 0.071 | G1: 0.089 |
| L4 | Lapua .338 Lapua Mag 250 gr Scenar GB488 (4318017) | G7 0.322 | 0.034 | 0.071 | 0.31 | 0.195 | G1: 0.265 |
| L5 | Lapua .338 Lapua Mag 300 gr Scenar GB528 (4318013) | G7 0.368 | 0.036 | 0.159 | 2.71 | 0.194 | G1: 0.786 |
| B1 | Berger 6.5 Creedmoor 140 gr Hybrid Target (31011) | G7 0.311 | 0.001 | — | 0.08 | — | G1: 0.009 |
| B2 | Berger .308 Win 185 gr Juggernaut OTM Tactical (60050) | G7 0.283 | 0.002 | — | 0.07 | — | G1: 0.012 |
| B3 | Berger .338 Lapua Mag 300 gr Hybrid OTM Tactical (81110) | G7 0.421 | 0.003 | — | 0.08 | — | G1: 0.008 |
| N1 | Norma .308 Win 180 gr Bondstrike (20176412) | G1 0.615 | 0.008 | — | 0.29 | — | — |
| N2 | Norma 6.5 Creedmoor 143 gr Bondstrike (20166402) | G1 0.629 | 0.007 | — | 0.10 | — | — |
| N3 | Norma .300 Win Mag 180 gr Bondstrike (20176332) | G1 0.615 | 0.007 | — | 0.33 | — | — |

## Atmosfer duyarlılığı: ICAO mı, Army Standard Metro mu?

Üreticiler atmosferi yazmadığı için, her tablo iki standart atmosferle
yeniden hesaplandı (yalnız 600 m'ye kadar):

- **ICAO:** 15 °C, 1013,25 hPa, %0 nem.
- **Army Standard Metro (ASM):** 59 °F, 29,53 inHg, %78 nem. Hava yoğunluğu
  ICAO'dan yaklaşık %2 düşük.

Hangi atmosferin daha iyi uyduğuna bakılarak üreticinin tabloyu hangi
atmosferle hesapladığı tahmin edilebilir:

| Fişek | ICAO: yörünge en büyük fark (mrad) | ICAO: hız en büyük fark (%) | ASM: yörünge en büyük fark (mrad) | ASM: hız en büyük fark (%) | Daha iyi uyan |
|---|---|---|---|---|---|
| H1 Hornady | 0.016 | 0.70 | 0.006 | 0.05 | ASM |
| H2 Hornady | 0.020 | 0.70 | 0.007 | 0.08 | ASM |
| H3 Hornady | 0.034 | 1.32 | 0.048 | 1.83 | ICAO |
| H4 Hornady | 0.008 | 0.34 | 0.006 | 0.19 | ASM |
| H5 Hornady | 0.028 | 1.09 | 0.003 | 0.21 | ASM |
| H6 Hornady | 0.006 | 0.50 | 0.008 | 0.07 | ASM |
| H7 Hornady | 0.013 | 0.64 | 0.009 | 0.10 | ASM |
| H8 Hornady | 0.012 | 0.41 | 0.012 | 0.04 | ASM |
| F1 Federal | 0.027 | 0.60 | 0.011 | 0.08 | ASM |
| F2 Federal | 0.009 | 0.58 | 0.007 | 0.02 | ASM |
| F3 Federal | 0.021 | 1.13 | 0.021 | 0.08 | ASM |
| F4 Federal | 0.009 | 0.60 | 0.006 | 0.02 | ASM |
| F5 Federal | 0.009 | 0.40 | 0.013 | 0.03 | ASM |
| F6 Federal | 0.030 | 1.06 | 0.049 | 0.04 | ASM |
| L1 Lapua | 0.018 | 0.60 | 0.052 | 1.46 | ICAO |
| L2 Lapua | 0.037 | 0.41 | 0.018 | 0.66 | ICAO |
| L3 Lapua | 0.032 | 0.48 | 0.019 | 1.62 | ICAO |
| L4 Lapua | 0.034 | 0.19 | 0.013 | 0.48 | ICAO |
| L5 Lapua | 0.036 | 1.16 | 0.014 | 0.57 | ASM |
| B1 Berger | 0.001 | 0.08 | 0.007 | 0.33 | ICAO |
| B2 Berger | 0.002 | 0.07 | 0.009 | 0.40 | ICAO |
| B3 Berger | 0.003 | 0.08 | 0.003 | 0.22 | ICAO |
| N1 Norma | 0.008 | 0.29 | 0.008 | 0.06 | ASM |
| N2 Norma | 0.007 | 0.10 | 0.007 | 0.40 | ICAO |
| N3 Norma | 0.007 | 0.33 | 0.007 | 0.04 | ASM |

**Sonuç:**

- Hornady (H3 hariç) ve Federal tablolarının tümü ASM ile daha iyi örtüşüyor; hız
  farkı %0,2'nin altına iniyor. Bu tablolar büyük olasılıkla ASM ile
  hesaplanmış.
- Berger ("sea level") ve Lapua tabloları ICAO ile daha iyi uyuyor.
- **Pratik anlamı:** Yayımlanmış bir tablo ile atış alanındaki gerçek hava
  arasındaki yoğunluk farkı 500 yd'de yaklaşık %0,7 hız ve 0,02 mrad
  düşüş eder. Uygulama, kullanıcının girdiği gerçek sıcaklık, basınç ve
  nemi kullandığı için bu fark sahada otomatik olarak düzelir. Bu bir hata
  değildir.

## Hornady çok bantlı BC (M2,25 / M2,0 / M1,75)

Uygulamanın "çoklu BC" özelliği (`bcBands`) basamaklı çalışır: hız eşiği
geçilince bir sonraki BC'ye geçilir. Hornady'nin üç BC'si bu özelliğe hız
eşikleriyle verildi: ≥2512 fps, ≥2232 fps, altı. Sonuç:

| Fişek | G7 tek BC: yörünge en büyük fark (mrad) | G7 3 bant: yörünge en büyük fark (mrad) | G7 tek BC: hız en büyük fark (%) | G7 3 bant: hız en büyük fark (%) |
|---|---|---|---|---|
| H1 .308 Win 168 gr ELD Match (80966) | 0.016 | 0.029 | 0.70 | 1.70 |
| H2 .308 Win 178 gr ELD-X Precision Hunter (80994) | 0.020 | 0.036 | 0.70 | 1.44 |
| H3 6.5 Creedmoor 140 gr ELD Match (81500) | 0.034 | 0.027 | 1.32 | 0.62 |
| H4 6.5 Creedmoor 143 gr ELD-X Precision Hunter (81499) | 0.008 | 0.023 | 0.34 | 1.50 |
| H5 .223 Rem 73 gr ELD Match (80269) | 0.028 | 0.052 | 1.09 | 2.51 |
| H6 .300 Win Mag 178 gr ELD-X Precision Hunter (82041) | 0.006 | 0.008 | 0.50 | 0.82 |
| H7 .300 Win Mag 200 gr ELD-X Precision Hunter (82002) | 0.013 | 0.017 | 0.64 | 1.06 |
| H8 .338 Lapua Mag 285 gr ELD Match (82300) | 0.012 | 0.012 | 0.41 | 0.69 |

Bu fişeklerin çoğunda (8'in 6'sında) üç bantlı giriş, Hornady'nin kendi
tablosuna tek M2,25 BC'sinden **daha az** uyuyor. Fark en çok 0,05 mrad, yani
yarım klik. Bunun iki nedeni var:

- Hornady'nin tablosu büyük olasılıkla tek BC ile hesaplanıyor.
- Basamaklı geçiş, düşük BC'yi eşiğin hemen altında tam olarak devreye
  sokuyor.

Bu bir hata değildir. Yine de öneri olarak not edilir: bantlar arasında
doğrusal geçiş (enterpolasyon) yapılması, Hornady'nin "Mach değerindeki BC"
tanımına daha yakın olur. Çözücünün davranışı bu PR'da **değiştirilmedi**.

## Farkların olası nedenleri

1. **Yuvarlama.** Hornady ve Federal yörüngeyi 0,1 inç, Lapua 1 mm, hızı
   1 fps veya 1 m/s'ye yuvarlıyor. 100 yd'deki ±0,007 mrad'lık farkların
   tamamı bu yuvarlamanın içinde.
2. **Belirtilmemiş atmosfer.** Yukarıdaki tabloda görüldüğü gibi, hızdaki
   sistematik −%0,5…−%1,1 fark ASM ile neredeyse tamamen kayboluyor.
3. **Sürüklenme modeli.**
   - Lapua tabloları Lapua'nın Doppler ölçümlü kendi sürüklenme eğrisiyle
     hesaplanıyor. Uygulama ise standart G7 eğrisi ve tek bir BC kullanıyor.
   - Mermi ses hızına yaklaştıkça (Mach ≈ 1,2'nin altı) bu iki eğri
     birbirinden ayrılıyor:
     - L5 için 1000 m'de −0,16 mrad, 1500 m'de −0,75 mrad. Ses hızı yakınında
       G7 eğrisi, Lapua'nın bu mermi için kullandığı eğriden daha fazla
       sürüklenme veriyor.
       Uygulamadaki hız Lapua'nınkinden %5,7 daha düşük.
     - L1'de yön ters: uygulama rüzgâr sürüklenmesini 1000 m'de 0,24 mrad
       daha az hesaplıyor.
   - Sapmanın yönü mermiye göre değişiyor. Bu, kodda sistematik bir hata
     olmadığını, farkın tek BC'li G modelinin sınırından geldiğini gösterir.
   - Uygulamanın bu iş için var olan çözümleri "Özel eğri" (`dragTable`,
     merminin kendi Cd–Mach eğrisi) ve uzak mesafede BC/hız düzeltmesidir
     (truing).
4. **G1 mi, G7 mi.**
   - Federal .223 69 gr SMK (F3): G7 BC ile 500 yd'de fark +0,15 mrad, G1 ile
     0,02 mrad. Federal tablosu G1 ile hesaplanmış.
   - Lapua'da tersi geçerli: G7 daha iyi uyuyor.
   - Kullanıcı, üreticinin tabloda kullandığı modeli seçerse tabloyu yeniden
     elde eder.
5. **Varsayılan nişan yüksekliği.** Berger yazmıyor; 1,5" varsayıldı. 0,1"
   fark 400 yd'de yaklaşık 0,2" düşüş eder. Gözlenen fark (≤0,003 mrad) bu
   belirsizliğin çok altında.
6. **Kaynak verisi hatası.**
   - Lapua 4318013'ün "600 m sıfır" satırı, aynı tablonun 100 m ve 300 m
     satırlarıyla çelişiyor. Diğer satırlardan beklenen ile yayımlanan
     arasındaki fark: 100 m'de −14 mm, 1500 m'de +718 mm.
   - Diğer Lapua tablolarında bu fark en çok 7 mm. Bu satır teste
     alınmadı (¹ ile işaretli).
   - Lapua 4318017'nin ürün özelliklerinde 890 m/s yazarken tablosu 905
     m/s ile başlıyor.

## Ek çapraz kontrol: ana oturumun bağımsız hesabı (2026-10-12)

Ana oturum, bu çalışmadan bağımsız bir nokta-kütle hesabı yaptı. Koşullar:
.308 Win 175 gr, G7 0,243, 790 m/s, 100 m sıfır. Bu hesapla 800 m'de düşüş
≈ 743 cm bulundu. Nişan yüksekliği bildirilmedi.

Aynı koşullarla çözücünün sonucu:

| Nişan yüksekliği | 800 m düşüş (cm) | 743 cm'den fark (mrad) |
|---|---|---|
| 38,1 mm (1,5") | 748,1 | 0,06 |
| 40 mm | 746,7 | 0,05 |
| 45 mm | 743,2 | 0,00 |
| 50 mm | 739,7 | −0,04 |

Hesaplar ICAO atmosferle yapıldı. Çözücüye göre 800 m'de hız 374 m/s,
uçuş süresi 1,47 s.

Nişan yüksekliği hangisi olursa olsun, iki hesap arasındaki fark 0,06
mrad'ı geçmiyor. Bu bir klikten azdır, yani iki hesap tutarlı. Bu kontrol
bir üretici tablosu değildir; teste eklenmedi.

## Çözücü hakkında sonuç

600 m'ye kadar, üreticiler arasında en kötü durumda fark 0,037 mrad. Bu
klikin üçte biri; 600 m'de 2,2 cm eder. Tek BC'li G1/G7 modelinin
gerektirdiği her durumda çözücü üretici tablolarını yeniden üretiyor:

- yörünge, sıfır mesafesi değişimi (100, 200, 300 ve 600 m sıfır), hız ve
  enerji (enerji = ½·m·v², hızdan türüyor);
- 10 mph (Federal) ve 4 m/s (Lapua) yan rüzgâr.

Düzeltilmesi gereken bir çözücü hatası **bulunmadı**. Bu nedenle ayrı bir
düzeltme commit'i önerilmedi. Öneri niteliğindeki iki not:

- çok bantlı BC'de bantlar arasında enterpolasyon;
- 1000 m ötesi için kullanıcıya "Özel eğri" ya da truing önerilmesi.

İkisi de davranış değişikliği olduğu için sahibin kararına bırakıldı.

## Ayrıntılı tablolar

Testteki modelle (ICAO atmosfer). Son sütun diğer G modeliyle yapılan
hesabın farkıdır. ¹ işaretli satırlar kaynakta tutarsız olduğu için teste
alınmadı. Lapua'nın 1000 m ötesi satırları teste alınmadı; burada
gösteriliyor.

#### H1 — Hornady .308 Win 168 gr ELD Match (80966) (G7 0.263)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +2 | +1.98 | −0.1 | −0.007 | −0.023 | 2530 / 2527 | −0.12 | −0.007 |
| 200 yd | 200 | +0 | +0.00 | +0.0 | +0.000 | +0.000 | 2366 / 2360 | −0.25 | +0.000 |
| 200 yd | 300 | -8.2 | -8.23 | −0.1 | −0.002 | −0.008 | 2209 / 2200 | −0.41 | −0.002 |
| 200 yd | 400 | -23.5 | -23.65 | −0.4 | −0.010 | −0.035 | 2057 / 2046 | −0.52 | −0.010 |
| 200 yd | 500 | -47.1 | -47.39 | −0.7 | −0.016 | −0.055 | 1912 / 1899 | −0.70 | −0.016 |

#### H2 — Hornady .308 Win 178 gr ELD-X Precision Hunter (80994) (G7 0.278)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +2.2 | +2.17 | −0.1 | −0.007 | −0.024 | 2443 / 2439 | −0.14 | −0.007 |
| 200 yd | 200 | +0 | +0.00 | +0.0 | +0.000 | +0.000 | 2291 / 2285 | −0.28 | −0.000 |
| 200 yd | 300 | -8.8 | -8.84 | −0.1 | −0.004 | −0.014 | 2145 / 2136 | −0.43 | −0.004 |
| 200 yd | 400 | -25.2 | -25.32 | −0.3 | −0.008 | −0.028 | 2004 / 1993 | −0.56 | −0.009 |
| 200 yd | 500 | -50.2 | -50.56 | −0.9 | −0.020 | −0.069 | 1868 / 1855 | −0.70 | −0.021 |

#### H3 — Hornady 6.5 Creedmoor 140 gr ELD Match (81500) (G7 0.326)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.9 | +1.88 | −0.0 | −0.004 | −0.015 | 2564 / 2570 | +0.22 | −0.004 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2422 / 2433 | +0.47 | −0.000 |
| 200 yd | 300 | -7.8 | -7.76 | +0.1 | +0.004 | +0.013 | 2285 / 2301 | +0.70 | +0.003 |
| 200 yd | 400 | -22.3 | -22.09 | +0.5 | +0.014 | +0.050 | 2152 / 2173 | +0.99 | +0.013 |
| 200 yd | 500 | -44.4 | -43.79 | +1.5 | +0.034 | +0.117 | 2023 / 2050 | +1.32 | +0.032 |

#### H4 — Hornady 6.5 Creedmoor 143 gr ELD-X Precision Hunter (81499) (G7 0.314)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.9 | +1.92 | +0.0 | +0.004 | +0.015 | 2556 / 2555 | −0.05 | +0.005 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2417 / 2414 | −0.14 | +0.000 |
| 200 yd | 300 | -7.9 | -7.89 | +0.0 | +0.001 | +0.004 | 2282 / 2277 | −0.21 | +0.001 |
| 200 yd | 400 | -22.4 | -22.49 | −0.2 | −0.006 | −0.021 | 2151 / 2145 | −0.26 | −0.007 |
| 200 yd | 500 | -44.5 | -44.65 | −0.4 | −0.008 | −0.028 | 2025 / 2018 | −0.34 | −0.010 |

#### H5 — Hornady .223 Rem 73 gr ELD Match (80269) (G7 0.2)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.9 | +1.91 | +0.0 | +0.003 | +0.010 | 2563 / 2560 | −0.13 | +0.003 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2348 / 2340 | −0.34 | +0.000 |
| 200 yd | 300 | -8.2 | -8.28 | −0.2 | −0.007 | −0.025 | 2143 / 2132 | −0.52 | −0.007 |
| 200 yd | 400 | -24 | -24.23 | −0.6 | −0.016 | −0.055 | 1949 / 1935 | −0.74 | −0.016 |
| 200 yd | 500 | -49 | -49.50 | −1.3 | −0.028 | −0.096 | 1766 / 1747 | −1.09 | −0.028 |

#### H6 — Hornady .300 Win Mag 178 gr ELD-X Precision Hunter (82041) (G7 0.278)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.5 | +1.49 | −0.0 | −0.003 | −0.011 | 2789 / 2788 | −0.03 | −0.002 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2625 / 2621 | −0.13 | +0.000 |
| 200 yd | 300 | -6.6 | -6.55 | +0.1 | +0.004 | +0.015 | 2467 / 2460 | −0.28 | +0.003 |
| 200 yd | 400 | -18.8 | -18.86 | −0.1 | −0.004 | −0.013 | 2314 / 2305 | −0.40 | −0.007 |
| 200 yd | 500 | -37.6 | -37.71 | −0.3 | −0.006 | −0.022 | 2166 / 2155 | −0.50 | −0.011 |

#### H7 — Hornady .300 Win Mag 200 gr ELD-X Precision Hunter (82002) (G7 0.301)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.6 | +1.63 | +0.1 | +0.008 | +0.028 | 2707 / 2704 | −0.12 | +0.009 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2558 / 2552 | −0.23 | −0.000 |
| 200 yd | 300 | -6.9 | -6.97 | −0.2 | −0.007 | −0.023 | 2414 / 2405 | −0.36 | −0.008 |
| 200 yd | 400 | -19.9 | -19.96 | −0.2 | −0.004 | −0.014 | 2274 / 2263 | −0.47 | −0.006 |
| 200 yd | 500 | -39.5 | -39.74 | −0.6 | −0.013 | −0.046 | 2140 / 2126 | −0.64 | −0.017 |

#### H8 — Hornady .338 Lapua Mag 285 gr ELD Match (82300) (G7 0.417)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.8 | +1.76 | −0.1 | −0.012 | −0.042 | 2636 / 2634 | −0.07 | −0.012 |
| 200 yd | 200 | +0 | +0.00 | +0.0 | +0.000 | +0.000 | 2530 / 2526 | −0.17 | −0.000 |
| 200 yd | 300 | -7.2 | -7.21 | −0.0 | −0.001 | −0.002 | 2426 / 2420 | −0.25 | −0.001 |
| 200 yd | 400 | -20.3 | -20.35 | −0.1 | −0.004 | −0.012 | 2324 / 2316 | −0.32 | −0.004 |
| 200 yd | 500 | -39.8 | -39.98 | −0.5 | −0.010 | −0.034 | 2225 / 2216 | −0.41 | −0.010 |

#### F1 — Federal .308 Win 175 gr SMK Gold Medal (GM308M2) (G1 0.505)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G7 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +2.2 | +2.21 | +0.0 | +0.003 | +0.011 | 2427 / 2425 | −0.09 | +0.005 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2262 / 2256 | −0.25 | −0.000 |
| 200 yd | 300 | -9.1 | -9.05 | +0.1 | +0.005 | +0.016 | 2102 / 2095 | −0.35 | +0.001 |
| 200 yd | 400 | -25.8 | -26.04 | −0.6 | −0.017 | −0.057 | 1949 / 1940 | −0.48 | −0.026 |
| 200 yd | 500 | -51.8 | -52.29 | −1.2 | −0.027 | −0.093 | 1803 / 1792 | −0.60 | −0.045 |
| 100 yd | 50 | -0.1 | -0.06 | +0.1 | +0.022 | +0.074 | — | — | +0.022 |
| 100 yd | 200 | -4.4 | -4.42 | −0.1 | −0.003 | −0.011 | — | — | −0.005 |
| 100 yd | 300 | -15.7 | -15.68 | +0.0 | +0.001 | +0.005 | — | — | −0.004 |

Yan rüzgâr (4.47 m/s, tam yan), 200 yd sıfır:

| Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | G7 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 0.6 | 0.7 | +0.3 | +0.034 | +0.116 | +0.037 |
| 200 | 2.9 | 3.0 | +0.2 | +0.012 | +0.042 | +0.020 |
| 300 | 6.9 | 7.0 | +0.2 | +0.006 | +0.022 | +0.018 |
| 400 | 12.5 | 12.9 | +0.9 | +0.025 | +0.085 | +0.041 |
| 500 | 20.3 | 20.9 | +1.4 | +0.032 | +0.109 | +0.054 |

#### F2 — Federal 6.5 Creedmoor 130 gr Berger Hybrid Gold Medal (GM65CRDBH130) (G1 0.56)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G7 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.6 | +1.63 | +0.1 | +0.007 | +0.024 | 2709 / 2707 | −0.09 | +0.005 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2550 / 2545 | −0.21 | −0.000 |
| 200 yd | 300 | -6.9 | -7.00 | −0.3 | −0.009 | −0.032 | 2396 / 2388 | −0.32 | −0.006 |
| 200 yd | 400 | -20 | -20.10 | −0.3 | −0.007 | −0.024 | 2247 / 2237 | −0.43 | +0.001 |
| 200 yd | 500 | -40 | -40.16 | −0.4 | −0.009 | −0.030 | 2104 / 2092 | −0.58 | +0.007 |
| 100 yd | 50 | -0.2 | -0.19 | +0.0 | +0.005 | +0.016 | — | — | +0.004 |
| 100 yd | 200 | -3.2 | -3.25 | −0.1 | −0.007 | −0.024 | — | — | −0.005 |
| 100 yd | 300 | -11.8 | -11.88 | −0.2 | −0.007 | −0.024 | — | — | −0.001 |

Yan rüzgâr (4.47 m/s, tam yan), 200 yd sıfır:

| Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | G7 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 0.6 | 0.6 | −0.1 | −0.010 | −0.035 | −0.015 |
| 200 | 2.3 | 2.3 | +0.0 | +0.002 | +0.008 | −0.006 |
| 300 | 5.2 | 5.4 | +0.4 | +0.016 | +0.054 | +0.004 |
| 400 | 9.7 | 9.8 | +0.4 | +0.010 | +0.035 | −0.006 |
| 500 | 15.7 | 15.9 | +0.5 | +0.011 | +0.036 | −0.011 |

#### F3 — Federal .223 Rem 69 gr SMK Gold Medal (GM223M) (G1 0.301)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G7 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.7 | +1.76 | +0.2 | +0.017 | +0.059 | 2642 / 2637 | −0.20 | +0.003 |
| 200 yd | 200 | +0 | +0.00 | +0.0 | +0.000 | +0.000 | 2353 / 2344 | −0.37 | −0.000 |
| 200 yd | 300 | -8.1 | -8.12 | −0.1 | −0.002 | −0.007 | 2084 / 2071 | −0.64 | +0.027 |
| 200 yd | 400 | -24.1 | -24.40 | −0.8 | −0.021 | −0.072 | 1832 / 1817 | −0.82 | +0.059 |
| 200 yd | 500 | -51 | -51.28 | −0.7 | −0.016 | −0.054 | 1604 / 1586 | −1.13 | +0.146 |
| 100 yd | 50 | -0.2 | -0.19 | +0.0 | +0.005 | +0.016 | — | — | +0.001 |
| 100 yd | 200 | -3.5 | -3.52 | −0.1 | −0.003 | −0.012 | — | — | +0.011 |
| 100 yd | 300 | -13.3 | -13.41 | −0.3 | −0.010 | −0.035 | — | — | +0.034 |

Yan rüzgâr (4.47 m/s, tam yan), 200 yd sıfır:

| Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | G7 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 1 | 1.0 | +0.1 | +0.010 | +0.035 | −0.018 |
| 200 | 4.3 | 4.4 | +0.2 | +0.011 | +0.037 | −0.048 |
| 300 | 10.3 | 10.4 | +0.4 | +0.013 | +0.046 | −0.084 |
| 400 | 19.3 | 19.8 | +1.2 | +0.033 | +0.113 | −0.112 |
| 500 | 32.4 | 33.0 | +1.5 | +0.033 | +0.114 | −0.168 |

#### F4 — Federal .300 Win Mag 190 gr SMK Gold Medal (GM300WM) (G1 0.533)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G7 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.6 | +1.60 | −0.0 | −0.001 | −0.002 | 2725 / 2722 | −0.10 | −0.003 |
| 200 yd | 200 | +0 | +0.00 | +0.0 | +0.000 | +0.000 | 2557 / 2552 | −0.21 | −0.000 |
| 200 yd | 300 | -6.9 | -6.94 | −0.1 | −0.004 | −0.014 | 2395 / 2387 | −0.33 | +0.001 |
| 200 yd | 400 | -19.9 | -20.00 | −0.2 | −0.007 | −0.023 | 2239 / 2229 | −0.45 | +0.005 |
| 200 yd | 500 | -39.9 | -40.06 | −0.4 | −0.009 | −0.031 | 2089 / 2076 | −0.60 | +0.013 |
| 100 yd | 50 | -0.2 | -0.20 | +0.0 | +0.000 | +0.000 | — | — | −0.001 |
| 100 yd | 200 | -3.2 | -3.20 | +0.0 | +0.001 | +0.002 | — | — | +0.003 |
| 100 yd | 300 | -11.6 | -11.74 | −0.4 | −0.013 | −0.044 | — | — | −0.005 |

Yan rüzgâr (4.47 m/s, tam yan), 200 yd sıfır:

| Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | G7 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 0.6 | 0.6 | −0.0 | −0.004 | −0.014 | −0.010 |
| 200 | 2.4 | 2.4 | +0.0 | +0.002 | +0.006 | −0.009 |
| 300 | 5.5 | 5.6 | +0.3 | +0.009 | +0.032 | −0.008 |
| 400 | 10.1 | 10.3 | +0.5 | +0.013 | +0.044 | −0.010 |
| 500 | 16.4 | 16.6 | +0.6 | +0.012 | +0.042 | −0.018 |

#### F5 — Federal .338 Lapua Mag 300 gr SMK Gold Medal (GM338LM2) (G1 0.768)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G7 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +2.1 | +2.11 | +0.0 | +0.004 | +0.012 | 2466 / 2465 | −0.06 | +0.004 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2355 / 2352 | −0.13 | +0.000 |
| 200 yd | 300 | -8.5 | -8.40 | +0.3 | +0.009 | +0.032 | 2248 / 2242 | −0.25 | +0.009 |
| 200 yd | 400 | -23.8 | -23.72 | +0.2 | +0.006 | +0.020 | 2143 / 2136 | −0.34 | +0.006 |
| 200 yd | 500 | -46.6 | -46.66 | −0.2 | −0.003 | −0.011 | 2040 / 2032 | −0.40 | −0.003 |
| 100 yd | 50 | -0.1 | -0.07 | +0.1 | +0.018 | +0.063 | — | — | +0.018 |
| 100 yd | 200 | -4.2 | -4.23 | −0.1 | −0.004 | −0.012 | — | — | −0.004 |
| 100 yd | 300 | -14.7 | -14.74 | −0.1 | −0.004 | −0.012 | — | — | −0.003 |

Yan rüzgâr (4.47 m/s, tam yan), 200 yd sıfır:

| Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | G7 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 0.4 | 0.5 | +0.2 | +0.021 | +0.071 | +0.020 |
| 200 | 1.8 | 1.9 | +0.4 | +0.019 | +0.067 | +0.019 |
| 300 | 4.3 | 4.5 | +0.4 | +0.015 | +0.053 | +0.015 |
| 400 | 8 | 8.1 | +0.3 | +0.009 | +0.031 | +0.008 |
| 500 | 12.8 | 13.0 | +0.5 | +0.012 | +0.040 | +0.010 |

#### F6 — Federal 7.62x39 123 gr JSP Power-Shok (76239B) (G1 0.274)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) |
|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +3.4 | +3.42 | +0.0 | +0.005 | +0.016 | 2055 / 2050 | −0.24 |
| 200 yd | 200 | +0 | +0.00 | +0.0 | +0.000 | +0.000 | 1783 / 1774 | −0.49 |
| 200 yd | 300 | -14.5 | -14.55 | −0.1 | −0.004 | −0.015 | 1539 / 1527 | −0.79 |
| 200 yd | 400 | -43.9 | -44.11 | −0.5 | −0.015 | −0.051 | 1329 / 1316 | −1.00 |
| 200 yd | 500 | -93.3 | -93.84 | −1.4 | −0.030 | −0.103 | 1164 / 1152 | −1.06 |
| 100 yd | 50 | +0.2 | +0.15 | −0.1 | −0.027 | −0.093 | — | — |
| 100 yd | 200 | -6.7 | -6.83 | −0.3 | −0.019 | −0.064 | — | — |
| 100 yd | 300 | -24.6 | -24.80 | −0.5 | −0.018 | −0.063 | — | — |

Yan rüzgâr (4.47 m/s, tam yan), 200 yd sıfır:

| Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) |
|---|---|---|---|---|---|
| 100 | 1.6 | 1.6 | −0.0 | −0.003 | −0.010 |
| 200 | 6.7 | 6.8 | +0.3 | +0.016 | +0.054 |
| 300 | 16.2 | 16.4 | +0.6 | +0.023 | +0.079 |
| 400 | 30.7 | 31.3 | +1.5 | +0.041 | +0.141 |
| 500 | 50.8 | 51.8 | +2.7 | +0.058 | +0.200 |

#### L1 — Lapua 6.5 Creedmoor 136 gr Scenar-L (4316063) (G7 0.274)

| Sıfır | Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (m/s) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 100 m | 100 | +0 | -0 | −0.0 | −0.000 | −0.000 | 780 / 779 | −0.10 | −0.000 |
| 100 m | 200 | -122 | -122 | +0.0 | +0.001 | +0.003 | 725 / 726 | +0.08 | +0.001 |
| 100 m | 300 | -430 | -430 | −0.0 | −0.001 | −0.004 | 673 / 674 | +0.16 | −0.001 |
| 100 m | 600 | -2814 | -2803 | +1.1 | +0.018 | +0.062 | 529 / 532 | +0.60 | +0.018 |
| 100 m | 800 | -6087 | -6053 | +3.4 | +0.042 | +0.145 | 446 / 446 | +0.03 | +0.050 |
| 100 m | 1000 | -11351 | -11304 | +4.7 | +0.047 | +0.162 | 375 / 367 | −2.00 | +0.119 |
| 300 m | 100 | +143 | +143 | +0.0 | +0.004 | +0.015 | — | — | +0.004 |
| 300 m | 200 | +165 | +165 | +0.0 | +0.000 | +0.001 | — | — | +0.000 |
| 300 m | 600 | -1953 | -1942 | +1.1 | +0.018 | +0.060 | — | — | +0.018 |
| 300 m | 800 | -4939 | -4906 | +3.3 | +0.042 | +0.143 | — | — | +0.049 |
| 300 m | 1000 | -9916 | -9870 | +4.6 | +0.046 | +0.160 | — | — | +0.118 |
| 600 m | 100 | +469 | +467 | −0.2 | −0.018 | −0.062 | — | — | −0.018 |
| 600 m | 200 | +816 | +813 | −0.3 | −0.017 | −0.059 | — | — | −0.017 |
| 600 m | 300 | +976 | +971 | −0.5 | −0.016 | −0.054 | — | — | −0.016 |
| 600 m | 800 | -2335 | -2316 | +1.9 | +0.024 | +0.082 | — | — | +0.032 |
| 600 m | 1000 | -6661 | -6632 | +2.9 | +0.029 | +0.099 | — | — | +0.100 |

Yan rüzgâr (4.00 m/s, tam yan), 100 m sıfır:

| Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | G1 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 19 | 16.9 | −0.2 | −0.021 | −0.074 | −0.021 |
| 200 | 76 | 69.8 | −0.6 | −0.031 | −0.107 | −0.031 |
| 300 | 179 | 162.7 | −1.6 | −0.054 | −0.186 | −0.054 |
| 600 | 807 | 729.3 | −7.8 | −0.129 | −0.445 | −0.130 |
| 800 | 1564 | 1413.0 | −15.1 | −0.189 | −0.649 | −0.200 |
| 1000 | 2671 | 2431.8 | −23.9 | −0.239 | −0.822 | −0.300 |

#### L2 — Lapua .308 Win 185 gr Scenar GB432 (4317523) (G7 0.242)

| Sıfır | Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (m/s) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 100 m | 100 | +0 | +0 | +0.0 | +0.000 | +0.000 | 697 / 695 | −0.22 | −0.000 |
| 100 m | 200 | -162 | -163 | −0.1 | −0.007 | −0.023 | 640 / 639 | −0.18 | −0.006 |
| 100 m | 300 | -563 | -568 | −0.5 | −0.015 | −0.053 | 585 / 585 | −0.02 | −0.015 |
| 100 m | 600 | -3735 | -3757 | −2.2 | −0.037 | −0.127 | 438 / 436 | −0.41 | −0.021 |
| 100 m | 800 | -8288 | -8356 | −6.8 | −0.085 | −0.293 | 356 / 349 | −1.90 | +0.039 |
| 300 m | 100 | +188 | +189 | +0.1 | +0.012 | +0.042 | — | — | +0.011 |
| 300 m | 200 | +214 | +215 | +0.1 | +0.006 | +0.019 | — | — | +0.005 |
| 300 m | 600 | -2609 | -2622 | −1.3 | −0.022 | −0.074 | — | — | −0.007 |
| 300 m | 800 | -6787 | -6842 | −5.5 | −0.069 | −0.238 | — | — | +0.054 |

Yan rüzgâr (4.00 m/s, tam yan), 100 m sıfır:

| Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | G1 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 21 | 22.2 | +0.1 | +0.012 | +0.042 | +0.012 |
| 200 | 88 | 92.6 | +0.5 | +0.023 | +0.078 | +0.022 |
| 300 | 207 | 217.2 | +1.0 | +0.034 | +0.116 | +0.033 |
| 600 | 963 | 1002.5 | +3.9 | +0.066 | +0.226 | +0.045 |
| 800 | 1898 | 1994.5 | +9.6 | +0.121 | +0.415 | +0.018 |

#### L3 — Lapua .308 Win 167 gr Scenar GB422 (4317515) (G7 0.223)

| Sıfır | Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (m/s) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 100 m | 100 | +0 | +0 | +0.0 | +0.000 | +0.000 | 754 / 752 | −0.21 | +0.000 |
| 100 m | 200 | -132 | -134 | −0.2 | −0.009 | −0.030 | 690 / 688 | −0.27 | −0.008 |
| 100 m | 300 | -470 | -475 | −0.5 | −0.018 | −0.061 | 628 / 627 | −0.13 | −0.015 |
| 100 m | 600 | -3212 | -3231 | −1.9 | −0.032 | −0.111 | 459 / 461 | +0.48 | −0.012 |
| 100 m | 800 | -7258 | -7280 | −2.2 | −0.027 | −0.094 | 364 / 364 | −0.02 | +0.076 |
| 300 m | 100 | +157 | +158 | +0.1 | +0.014 | +0.049 | — | — | +0.011 |
| 300 m | 200 | +181 | +183 | +0.2 | +0.011 | +0.036 | — | — | +0.009 |
| 300 m | 600 | -2271 | -2281 | −1.0 | −0.016 | −0.056 | — | — | +0.001 |
| 300 m | 800 | -6003 | -6012 | −0.9 | −0.012 | −0.041 | — | — | +0.089 |
| 600 m | 100 | +535 | +539 | +0.4 | +0.036 | +0.123 | — | — | +0.015 |
| 600 m | 200 | +938 | +943 | +0.5 | +0.027 | +0.093 | — | — | +0.007 |
| 600 m | 300 | +1135 | +1140 | +0.5 | +0.018 | +0.062 | — | — | +0.000 |
| 600 m | 800 | -2975 | -2972 | +0.3 | +0.004 | +0.014 | — | — | +0.087 |

Yan rüzgâr (4.00 m/s, tam yan), 100 m sıfır:

| Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | G1 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 20 | 21.4 | +0.1 | +0.014 | +0.049 | +0.013 |
| 200 | 85 | 89.6 | +0.5 | +0.023 | +0.078 | +0.020 |
| 300 | 200 | 210.7 | +1.1 | +0.036 | +0.122 | +0.031 |
| 600 | 946 | 977.6 | +3.2 | +0.053 | +0.181 | +0.033 |
| 800 | 1899 | 1955.7 | +5.7 | +0.071 | +0.244 | −0.014 |

#### L4 — Lapua .338 Lapua Mag 250 gr Scenar GB488 (4318017) (G7 0.322)

| Sıfır | Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (m/s) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 100 m | 100 | +0 | -0 | −0.0 | −0.000 | −0.000 | 856 / 855 | −0.06 | +0.000 |
| 100 m | 200 | -93 | -94 | −0.1 | −0.006 | −0.021 | 808 / 807 | −0.09 | −0.006 |
| 100 m | 300 | -336 | -339 | −0.3 | −0.010 | −0.035 | 762 / 761 | −0.19 | −0.010 |
| 100 m | 600 | -2164 | -2185 | −2.1 | −0.034 | −0.118 | 631 / 630 | −0.18 | −0.027 |
| 100 m | 800 | -4570 | -4611 | −4.1 | −0.052 | −0.178 | 551 / 550 | −0.14 | −0.032 |
| 100 m | 1000 | -8274 | -8345 | −7.1 | −0.071 | −0.244 | 477 / 476 | −0.31 | −0.027 |
| 100 m | 1200 | -13721 | -13832 | −11.1 | −0.092 | −0.317 | 409 / 406 | −0.81 | +0.012 |
| 100 m | 1500 | -26585 | -26869 | −28.4 | −0.189 | −0.651 | 328 / 322 | −1.72 | +0.243 |
| 300 m | 100 | +112 | +113 | +0.1 | +0.010 | +0.035 | — | — | +0.010 |
| 300 m | 200 | +131 | +132 | +0.1 | +0.004 | +0.015 | — | — | +0.004 |
| 300 m | 600 | -1493 | -1507 | −1.4 | −0.023 | −0.077 | — | — | −0.015 |
| 300 m | 800 | -3674 | -3707 | −3.3 | −0.042 | −0.143 | — | — | −0.022 |
| 300 m | 1000 | -7155 | -7215 | −6.0 | −0.060 | −0.205 | — | — | −0.016 |
| 300 m | 1200 | -12377 | -12475 | −9.8 | −0.082 | −0.281 | — | — | +0.022 |
| 300 m | 1500 | -24904 | -25174 | −27.0 | −0.180 | −0.618 | — | — | +0.252 |
| 600 m | 100 | +361 | +364 | +0.3 | +0.031 | +0.107 | — | — | +0.023 |
| 600 m | 200 | +628 | +634 | +0.6 | +0.030 | +0.104 | — | — | +0.022 |
| 600 m | 300 | +746 | +753 | +0.7 | +0.024 | +0.083 | — | — | +0.017 |
| 600 m | 800 | -1684 | -1699 | −1.5 | −0.018 | −0.063 | — | — | −0.006 |
| 600 m | 1000 | -4667 | -4704 | −3.7 | −0.037 | −0.127 | — | — | −0.001 |
| 600 m | 1200 | -9390 | -9462 | −7.2 | −0.060 | −0.207 | — | — | +0.036 |
| 600 m | 1500 | -21168 | -21408 | −24.0 | −0.160 | −0.549 | — | — | +0.265 |

Yan rüzgâr (4.00 m/s, tam yan), 100 m sıfır:

| Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | G1 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 12 | 12.6 | +0.1 | +0.006 | +0.021 | +0.006 |
| 200 | 48 | 52.0 | +0.4 | +0.020 | +0.068 | +0.020 |
| 300 | 112 | 120.5 | +0.8 | +0.028 | +0.097 | +0.027 |
| 600 | 495 | 528.8 | +3.4 | +0.056 | +0.194 | +0.048 |
| 800 | 944 | 1003.9 | +6.0 | +0.075 | +0.257 | +0.061 |
| 1000 | 1489 | 1683.9 | +19.5 | +0.195 | +0.670 | +0.170 |
| 1200 | 2489 | 2621.9 | +13.3 | +0.111 | +0.381 | +0.056 |
| 1500 | 4392 | 4655.1 | +26.3 | +0.175 | +0.603 | −0.001 |

#### L5 — Lapua .338 Lapua Mag 300 gr Scenar GB528 (4318013) (G7 0.368)

| Sıfır | Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (m/s) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 100 m | 100 | +0 | -0 | −0.0 | −0.000 | −0.000 | 780 / 779 | −0.17 | −0.000 |
| 100 m | 200 | -122 | -122 | +0.0 | +0.000 | +0.002 | 741 / 739 | −0.33 | +0.001 |
| 100 m | 300 | -422 | -424 | −0.2 | −0.006 | −0.021 | 703 / 700 | −0.48 | −0.005 |
| 100 m | 600 | -2609 | -2631 | −2.2 | −0.036 | −0.125 | 597 / 590 | −1.16 | −0.028 |
| 100 m | 800 | -5404 | -5469 | −6.5 | −0.081 | −0.277 | 532 / 522 | −1.82 | −0.065 |
| 100 m | 1000 | -9595 | -9754 | −15.9 | −0.159 | −0.548 | 471 / 458 | −2.71 | −0.124 |
| 100 m | 1200 | -15565 | -15924 | −35.9 | −0.300 | −1.030 | 416 / 398 | −4.33 | −0.207 |
| 100 m | 1500 | -29006 | -30125 | −111.9 | −0.746 | −2.565 | 344 / 324 | −5.69 | −0.336 |
| 300 m | 100 | +141 | +141 | +0.0 | +0.003 | +0.009 | — | — | +0.001 |
| 300 m | 200 | +160 | +161 | +0.1 | +0.003 | +0.011 | — | — | +0.002 |
| 300 m | 600 | -1765 | -1783 | −1.8 | −0.030 | −0.104 | — | — | −0.024 |
| 300 m | 800 | -4278 | -4338 | −6.0 | −0.075 | −0.259 | — | — | −0.061 |
| 300 m | 1000 | -8188 | -8342 | −15.4 | −0.154 | −0.528 | — | — | −0.120 |
| 300 m | 1200 | -13876 | -14229 | −35.3 | −0.294 | −1.012 | — | — | −0.203 |
| 300 m | 1500 | -26894 | -28006 | −111.2 | −0.741 | −2.549 | — | — | −0.332 |
| 600 m ¹ | 100 | +421 | +438 | +1.7 | +0.175 | +0.601 | — | — | +0.167 |
| 600 m ¹ | 200 | +725 | +755 | +3.0 | +0.150 | +0.516 | — | — | +0.143 |
| 600 m ¹ | 300 | +855 | +892 | +3.7 | +0.122 | +0.419 | — | — | +0.116 |
| 600 m ¹ | 800 | -1865 | -1961 | −9.6 | −0.120 | −0.412 | — | — | −0.112 |
| 600 m ¹ | 1000 | -5082 | -5370 | −28.8 | −0.288 | −0.990 | — | — | −0.260 |
| 600 m ¹ | 1200 | -10021 | -10663 | −64.2 | −0.535 | −1.840 | — | — | −0.450 |
| 600 m ¹ | 1500 | -21766 | -23549 | −178.3 | −1.189 | −4.086 | — | — | −0.786 |

Yan rüzgâr (4.00 m/s, tam yan), 100 m sıfır:

| Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | G1 fark (mrad) |
|---|---|---|---|---|---|---|
| 100 | 12 | 12.8 | +0.1 | +0.008 | +0.027 | +0.007 |
| 200 | 47 | 52.4 | +0.5 | +0.027 | +0.093 | +0.026 |
| 300 | 109 | 121.1 | +1.2 | +0.040 | +0.139 | +0.038 |
| 600 | 469 | 525.8 | +5.7 | +0.095 | +0.325 | +0.089 |
| 800 | 880 | 991.2 | +11.1 | +0.139 | +0.478 | +0.130 |
| 1000 | 1457 | 1651.0 | +19.4 | +0.194 | +0.667 | +0.173 |
| 1200 | 2245 | 2549.7 | +30.5 | +0.254 | +0.873 | +0.203 |
| 1500 | 3852 | 4459.1 | +60.7 | +0.405 | +1.391 | +0.239 |

#### B1 — Berger 6.5 Creedmoor 140 gr Hybrid Target (31011) (G7 0.311)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.82 | +1.82 | −0.0 | −0.000 | −0.000 | 2602 / 2602 | −0.01 | +0.002 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2459 / 2458 | −0.04 | +0.000 |
| 200 yd | 300 | -7.58 | -7.58 | +0.0 | +0.000 | +0.000 | 2320 / 2319 | −0.05 | −0.003 |
| 200 yd | 400 | -21.61 | -21.63 | −0.1 | −0.001 | −0.005 | 2186 / 2184 | −0.08 | −0.009 |

#### B2 — Berger .308 Win 185 gr Juggernaut OTM Tactical (60050) (G7 0.283)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +2.15 | +2.15 | −0.0 | −0.000 | −0.001 | 2450 / 2450 | −0.00 | +0.002 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2298 / 2298 | −0.02 | −0.000 |
| 200 yd | 300 | -8.73 | -8.74 | −0.0 | −0.001 | −0.004 | 2152 / 2151 | −0.06 | −0.005 |
| 200 yd | 400 | -24.98 | -25.01 | −0.1 | −0.002 | −0.008 | 2011 / 2010 | −0.07 | −0.012 |

#### B3 — Berger .338 Lapua Mag 300 gr Hybrid OTM Tactical (81110) (G7 0.421)

| Sıfır | Mesafe (yd) | Yayımlanan (inç) | Uygulama (inç) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (fps) | Hız farkı (%) | G1 fark (mrad) |
|---|---|---|---|---|---|---|---|---|---|
| 200 yd | 100 | +1.78 | +1.79 | +0.0 | +0.003 | +0.011 | 2616 / 2616 | −0.01 | +0.004 |
| 200 yd | 200 | +0 | -0.00 | −0.0 | −0.000 | −0.000 | 2509 / 2509 | −0.01 | −0.000 |
| 200 yd | 300 | -7.3 | -7.32 | −0.0 | −0.002 | −0.005 | 2405 / 2404 | −0.04 | −0.004 |
| 200 yd | 400 | -20.6 | -20.65 | −0.1 | −0.003 | −0.012 | 2304 / 2302 | −0.08 | −0.008 |

#### N1 — Norma .308 Win 180 gr Bondstrike (20176412) (G1 0.615)

| Sıfır | Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (m/s) | Hız farkı (%) |
|---|---|---|---|---|---|---|---|---|
| 100 m | 50 | +0 | +0 | +0.0 | +0.008 | +0.026 | — | — |
| 100 m | 80 | +5 | +5 | +0.0 | +0.003 | +0.009 | — | — |
| 100 m | 100 | +0 | -0 | −0.0 | −0.000 | −0.000 | 752 / 752 | −0.04 |
| 100 m | 150 | -44 | -44 | +0.0 | +0.001 | +0.005 | — | — |
| 100 m | 200 | -133 | -134 | −0.1 | −0.004 | −0.014 | 707 / 705 | −0.28 |
| 100 m | 300 | -464 | -465 | −0.1 | −0.004 | −0.015 | 662 / 660 | −0.29 |

#### N2 — Norma 6.5 Creedmoor 143 gr Bondstrike (20166402) (G1 0.629)

| Sıfır | Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (m/s) | Hız farkı (%) |
|---|---|---|---|---|---|---|---|---|
| 100 m | 50 | -1 | -1 | −0.0 | −0.007 | −0.023 | — | — |
| 100 m | 80 | +4 | +4 | +0.0 | +0.001 | +0.004 | — | — |
| 100 m | 100 | +0 | -0 | −0.0 | −0.000 | −0.000 | 786 / 787 | +0.07 |
| 100 m | 150 | -38 | -38 | −0.0 | −0.002 | −0.007 | — | — |
| 100 m | 200 | -118 | -119 | −0.1 | −0.004 | −0.013 | 739 / 740 | +0.10 |
| 100 m | 300 | -415 | -417 | −0.2 | −0.007 | −0.023 | 694 / 695 | +0.08 |

#### N3 — Norma .300 Win Mag 180 gr Bondstrike (20176332) (G1 0.615)

| Sıfır | Mesafe (m) | Yayımlanan (mm) | Uygulama (mm) | Fark (cm) | Fark (mrad) | Fark (MOA) | Hız yay./uyg. (m/s) | Hız farkı (%) |
|---|---|---|---|---|---|---|---|---|
| 100 m | 50 | -5 | -5 | −0.0 | −0.006 | −0.020 | — | — |
| 100 m | 80 | +1 | +2 | +0.1 | +0.007 | +0.023 | — | — |
| 100 m | 100 | +0 | -0 | −0.0 | −0.000 | −0.000 | 887 / 886 | −0.07 |
| 100 m | 150 | -26 | -26 | +0.0 | +0.000 | +0.002 | — | — |
| 100 m | 200 | -85 | -85 | +0.0 | +0.000 | +0.000 | 837 / 835 | −0.25 |
| 100 m | 300 | -310 | -311 | −0.1 | −0.003 | −0.010 | 788 / 785 | −0.33 |

