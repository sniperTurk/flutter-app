# Formül denetimi — 2026-10-11

Kapsam: `lib/core/`, `lib/features/ballistics/` ve hesapta kullanılan
`lib/tools/domain/` formülleri. Her formül yayımlanmış bir standart veya
bilimsel kaynakla karşılaştırıldı. Başka balistik uygulamalarının çıktı ya da
veri tabloları referans olarak **kullanılmadı**.

## Yöntem

* **Bağımsız referans:** `tools/formula_reference.py` (yalnız Python standart
  kütüphanesi). Uygulamadan bilerek farklı bir yoldan hesaplar:
  * hava yoğunluğu **CIPM-2007** (uygulama: Magnus + ideal gaz karışımı),
  * ses hızı nemli havanın kendi ısı kapasitesi oranıyla (uygulama: γ = 1,4),
  * sürüklenme ivmesi mermi kütlesi ve çapından form faktörüyle
    (uygulama: π/(8·BC)),
  * Cd tablosu **PCHIP** (monoton kübik) enterpolasyonu (uygulama: doğrusal),
  * yörünge **dünya çerçevesinde** (yerçekimi dik, rüzgâr yatay, Dünya dönüşü
    doğu-kuzey-yukarı bileşenlerinden), uyarlamalı **Dormand–Prince 5(4)**;
    sonuç eğik ve cant'lı dürbün eksenlerine izdüşürülür (uygulama: dürbün
    çerçevesinde sabit adımlı RK4).
* **Dart testleri:** `test/formula_reference_vectors_test.dart` uygulamanın
  gerçek motorunu (`BallisticEngine`) 15 senaryoda referansla karşılaştırır:
  * *aynı model* (referans, uygulamanın hava modeli ve doğrusal Cd ile):
    yükseliş/yan ±0,005 mrad, hız ±0,05 m/s, uçuş süresi ±0,2 ms. Yalnız
    integratör, eksen dönüşümleri ve birimler farklıdır; işaret/eksen hatası
    geçemez.
  * *bağımsız model:* yükseliş ±max(0,03 mrad; %0,5), yan ±max(0,03 mrad; %1),
    hız/uçuş süresi %0,5, enerji %1. Bu, bir klikten (0,1 mrad) çok küçüktür.
  * atmosfer (10 nokta), yerçekimi (9 nokta), ICAO basınç/yoğunluk irtifası
    (6 nokta), NIST birim tanımları ve **uç girdiler** (−60/+60 °C, 300/1100
    hPa, %100 nem, 59,9 m/s rüzgâr, ±90° eğim, 180° cant, 1500 m/s): her mesafe
    ya sonlu bir değer ya da "ulaşılamıyor" olarak dönmeli; NaN/Infinity yok.
* **Python testleri:** `tools/test_formula_reference.py` referansın kendisini
  yayımlanmış değerlere bağlar (ICAO tablosu, WGS-84 kutup/ekvator, ISA ses
  hızı, sürtünmesiz parabol, sabit Cd'de üstel hız kaybı, sürtünmesiz Coriolis
  ±%2), Dart dosyasındaki vektörlerin elle değiştirilmediğini, Miller/Litz
  katsayılarının kaynakla aynı kaldığını ve N atışlık grup ES/σ katsayılarını
  Monte Carlo ile doğrular.
* Mevcut `tools/formula_audit.py` (`formula-audit.yml`): G1…RA4 tablolarını
  py-ballisticcalc'ın BRL kopyasıyla, birimleri pint ile, mesafe/yönü WGS-84
  jeodezikle karşılaştırır.

Senaryolar: .22 PCP 18,13 gr G1 0,035 270 m/s (15–100 m; 20 °C, −10 °C,
+40 °C + saat 3'ten 4 m/s, −30° eğim); .308 175 gr G7 0,243 2600 fps
(100–1000 m; ICAO, +40 °C/800 hPa, −10 °C, saat 9'dan 10 m/s + Coriolis 39° K
doğuya, +30°/−45°/+60° eğim, 5° cant, Coriolis 35° G kuzeye); 6.5 Creedmoor
140 gr G7 0,315 2710 fps (saat 2'den 5 m/s; 3000 m irtifa 0 °C/700 hPa).
MOA ve MRAD dürbün birim dönüşümleri ayrıca test edildi.

## Sonuç özeti

| | Sayı |
|---|---|
| Kontrol edilen formül | 38 |
| DOĞRU | 31 |
| SAPMA (ihmal edilebilir, belgelendi) | 6 |
| DOĞRULANAMADI (yayımlanmış standart yok) | 1 |
| HATALI | 0 |

**Hatalı formül bulunmadı; hesap koduna düzeltme yapılmadı.** En büyük model
farkı 1000 m'de 0,011 mrad (1,1 cm) — 0,1 mrad klikin %11'i.

## Formüller

Kısaltmalar: D = DOĞRU, S = SAPMA, ? = DOĞRULANAMADI.

### Sürüklenme ve yörünge

| # | Formül | Kodda | Referans | Sonuç |
|---|---|---|---|---|
| 1 | G1/G7 (G2, G5, G6, G8, GI, GS, RA4) Cd–Mach tabloları | `lib/core/standard_drag_tables.dart` | BRL standart sürüklenme fonksiyonları; McCoy, *Modern Exterior Ballistics* (1999) böl. 4 | D — `formula-audit.yml` py-ballisticcalc'ın BRL kopyasıyla birebir |
| 2 | Cd enterpolasyonu (doğrusal, uçlarda sabit) | `drag_table.dart` | Fritsch–Carlson PCHIP (SIAM J. Numer. Anal. 17, 1980) | S — en çok 0,0074 mrad (.22 PCP 100 m: 0,07 cm) |
| 3 | BC → ivme: a = ½ρ·Cd·(π/4)·v²/BC, 1 lb/in² = 703,0696 kg/m² | `reference_drag_model.dart` | McCoy böl. 4 (a = ρ·S·i·Cd_G·v²/2m), NIST lb/in | D (birebir; bağımsız form-faktör yolu) |
| 4 | Havaya göre bağıl hız ile 3B sürüklenme | `aerodynamic_trajectory_solver.dart` `_derivative` | McCoy böl. 5 nokta-kütle denklemleri | D |
| 5 | RK4, sabit 0,5 ms adım, mesafede doğrusal ara değer | `rk4.dart`, solver | Dormand–Prince 5(4), bağıl tolerans 1e-10 | D — aynı modelde ≤0,005 mrad |
| 6 | Sıfırlama (dürbün yüksekliği, açı ikiye bölme) | solver `_zeroAngle`, `_initialState` | Bağımsız sekant çözümü; sürtünmesiz kapalı form | D |
| 7 | Sıfır her zaman ICAO 15 °C/1013,25 hPa/%0'da çözülür | `ballistic_input.dart` `zeroEnvironment` | Varsayım | S — .308 +40 °C/800 hPa: 0,012 mrad; PCP 40 °C: 0,03 mrad |
| 8 | Vakum taban çözücü (eğim/cant dahil) | `ballistic_engine.dart` `vacuumDope` | Kapalı form parabol | D |
| 9 | Hız (3B), enerji ½mv², uçuş süresi | solver, `BallisticEngine.energyJ` | Tanım; 1 gr = 64,79891 mg (NIST) | D |

### Atmosfer

| # | Formül | Kodda | Referans | Sonuç |
|---|---|---|---|---|
| 10 | Doymuş buhar basıncı 6,112·exp(17,62T/(243,12+T)) | `atmosphere.dart` | WMO-No. 8 (2018) Ek 4.B (Magnus/Sonntag) | D |
| 11 | Nemli hava yoğunluğu (Rd 287,05, Rv 461,495) | `atmosphere.dart` | CIPM-2007, Picard vd., *Metrologia* 45 (2008) 149 | S — −%0,02…−%0,09; 1000 m'de ≤0,011 mrad |
| 12 | Ses hızı √(1,4·p/ρ) ve Mach | `atmosphere.dart` | İdeal nemli hava γ_karışım | S — 50 °C/%90'da +%0,33; 1000 m'de ≤0,016 mrad (1,6 cm) |
| 13 | İstasyon basıncı (QNH, ISA) p₀(1−2,25577e-5·h)^5,25588 | `field_calc.dart` | ICAO Doc 7488/3 | S — h jeopotansiyel alınıyor; 2000 m'de 0,06 hPa |
| 14 | İstasyon basıncı (MSLP, hipsometrik, ortalama sütun sıcaklığı) | `field_calc.dart` | WMO-No. 8 Ek 3.A | D |
| 15 | Yoğunluk irtifası 44330,77·(1−(ρ/1,225)^0,234969) | `field_calc.dart` | ICAO Doc 7488 ters çözüm | D — ≤0,01 m |
| 16 | Çiy noktası (Magnus tersi) | `field_calc.dart` | Buck (1981/1996) sayısal ters | D — ≤0,03 °C |
| 17 | Yerçekimi: WGS-84 Somigliana + serbest hava | `gravity.dart` | NIMA TR8350.2 denk. 4-1, 4-3 | D — ≤2e-7 m/s² |

### Rüzgâr, açı, Dünya dönüşü

| # | Formül | Kodda | Referans | Sonuç |
|---|---|---|---|---|
| 18 | Saat → açı: h ↦ (360 − 30h) mod 360; 0° karşıdan, 90° soldan | `wind_clock.dart` | Saat yüzü tanımı; dünya çerçevesi referansı | D |
| 19 | Rüzgâr vektörü, havaya bağıl sürüklenme (yan sapma) | solver | McCoy böl. 5 | D — 10 m/s soldan, 1000 m: −8,00 mrad (sağa) |
| 20 | Rüzgâr bölgeleri (yolun 1/3'leri) | `ballistic_input.dart` `WindZones` | Tanım | D |
| 21 | Eğim: tam çözüm (yerçekimi dürbün çerçevesinde) | solver `_frameFor` | Dünya çerçevesi referansı | D — rifleman kuralından iyi: .308 −45° 600 m'de kural 0,45 mrad (27 cm) az verir |
| 22 | Cant (saat yönü +) | solver | Dünya çerçevesi referansı | D — 5°, 1000 m: 1,35 mrad sağa |
| 23 | Coriolis yatay ve dikey (Eötvös), enlem/azimut | solver `_frameFor`, `_derivative` | ENU'dan Ω; McCoy böl. 10; sürtünmesiz Ω·sinλ·X·t (±%2) | D |
| 24 | Coriolis sıfırda yok sayılır | solver | Varsayım | D (100 m sıfırda < 1 mm) |

### Jiroskopik etkiler

| # | Formül | Kodda | Referans | Sonuç |
|---|---|---|---|---|
| 25 | Miller kararlılık Sg = 30m/(t²d³l(1+l²))·(v/2800)^⅓·(T+460)/519·29,92/P | `ballistics_screen.dart` `_stability` | Miller, *Precision Shooting*, Mart 2005; Litz, *Applied Ballistics* böl. 10 | D (katsayılar kaynakla aynı) |
| 26 | Spin drift = 1,25(Sg+1,2)·t^1,83 inç | `_spinDriftMrad` | Litz (2009) denk. 10.1 | D — .308 175 gr 1:10: Sg 2,40, 1000 m'de 42,8 cm sağa |
| 27 | Aerodinamik sıçrama 0,01Sg − 0,0024L + 0,032 MOA/mph; sağ yiv + sağdan rüzgâr = yukarı | `_aeroJumpMrad` | Litz (2009) böl. 10; açısal momentum türetmesi | D |

### Hız, olasılık, birim

| # | Formül | Kodda | Referans | Sonuç |
|---|---|---|---|---|
| 28 | Barut sıcaklığı v = v₀(1 + k/100·ΔT/15) | `powder_temperature.dart` | Doğrusal duyarlılık tanımı | D (barut sıcaklığı = hava sıcaklığı varsayımı) |
| 29 | Grup σ = ES/k(N), k(5) = 3,067 | `wez.dart`, `hit_probability.dart` | k(2) = √π; Monte Carlo 20 000 grup (±%1,2) | D |
| 30 | İsabet: Rayleigh 1−exp(−R²/2σ²) ve WEZ Monte Carlo | `hit_probability.dart`, `wez.dart` | Rayleigh dağılımı; 200 000 örnek | D |
| 31 | En az bir isabet 1−(1−p)ⁿ | `wez.dart` | Bağımsız denemeler için binom | D (bağımsızlık varsayımı belgeli) |
| 32 | mrad/MOA/SMOA, m/yd, fps, gr/g, inHg/hPa, mph, ft·lbf, °F | `units.dart`, `unit_system.dart`, `domain.dart`, `field_calc.dart` | NIST SP 811 (2008) Ek B | D — birebir |
| 33 | Klik sayısı, kule ölçek katsayısı, sıfır ofseti açısı | `scope_dial.dart`, ekran | Tanım | D |
| 34 | Retikül tutuşları (holdover, SFP alt-açısı kal./büyütme) | `scope_dial.dart`, `reticle_holds.dart` | Optik tanım | D |
| 35 | Dürbün ayağı MOA → klik (aşağı yuvarlama) | `ScopeDialMath.mountCantClicks` | 1 MOA = π/10800 rad | D — 20 MOA, ¼ MOA: 80; 30 MOA, 0,1 mrad: 87 |
| 36 | Hız/BC doğrulama (ikiye bölme), iki hızdan BC, kesit yoğunluğu | `velocity_truing.dart`, `field_calc.dart`, `drag_curve.dart` | Tanım; py-ballisticcalc RK4 (formula-audit) | D |
| 37 | Haversine mesafe, ilk kerteriz, hareketli hedef önü v·t | `field_calc.dart`, ekran | WGS-84 jeodezik (formula-audit) | D |
| 38 | GA (diabolo saçma) Cd tablosu | `standard_drag_tables.dart` `ga` | Yayımlanmış standart yok (forum dışa aktarımı) | ? |

## Notlar ve öneriler (kod değişikliği yok)

1. **GA tablosu** yayımlanmış bir standart değildir; kaynağı bir forumda
   paylaşılan, başka bir uygulamadan dışa aktarılmış veridir (kodda
   "UNVERIFIED" diye işaretli). Bağımsız bir referansla doğrulanamaz. PCP
   kullanıcılarına G1 (yayımlanmış BRL) önerilebilir; GA'nın kalıp kalmayacağı
   sahibin kararıdır.
2. **BC atmosfer referansı:** motor BC'yi gerçek yoğunlukla kullanır
   (ICAO'ya göre verilmiş BC; Litz/Applied Ballistics ve py-ballisticcalc ile
   aynı). "Army Standard Metro"ya göre yayımlanmış eski BC'ler bunlardan
   birkaç yüzde farklı olabilir; bu formül değil veri sözleşmesidir.
3. **Spin drift DOPE kartında yok:** Atış ekranındaki kule klikleri spin
   drift'i içerir, DOPE kartının rüzgâr sütunu yalnız rüzgârdır. Kartın
   notlarında belirtilmesi değerlendirilebilir (UI kuralları gereği
   değiştirilmedi).
4. **Miller/Litz** yaklaşık formüllerdir: plastik uçlu/çok uzun mermilerde
   Miller kararlılığı düşük tahmin edebilir (Litz böl. 10).
5. Ses hızında nem için γ'nın karışımdan hesaplanması (madde 12) sıcak-nemli
   havada 1000 m'de ≤1,6 cm kazandırır; donmuş py-ballisticcalc kabul
   vektörlerini değiştireceği için yapılmadı.

## Kaynaklar

* BRL/Ingalls G-fonksiyonları — McCoy, R. L., *Modern Exterior Ballistics*,
  Schiffer, 1999; tablolar: https://jbmballistics.com/downloads/mcg1.txt ,
  https://jbmballistics.com/downloads/mcg7.txt (yalnız standart Cd verisi)
* CIPM-2007 — Picard vd., *Metrologia* 45 (2008) 149–155,
  https://doi.org/10.1088/0026-1394/45/2/004
* ICAO Doc 7488/3 *Manual of the ICAO Standard Atmosphere*, 1993
* WMO-No. 8 *Guide to Instruments and Methods of Observation*, 2018,
  https://library.wmo.int/idurl/4/41650
* Buck, A. L., *J. Appl. Meteor.* 20 (1981) 1527,
  https://doi.org/10.1175/1520-0450(1981)020<1527:NEFCVP>2.0.CO;2
* NIMA TR8350.2 *WGS 84*, 3. baskı, 2000,
  https://earth-info.nga.mil/php/download.php?file=coord-wgs84
* NIST SP 811 (2008) Ek B, https://www.nist.gov/pml/special-publication-811
* Miller, D., "A New Rule for Estimating Rifling Twist", *Precision
  Shooting*, Mart 2005
* Litz, B., *Applied Ballistics for Long Range Shooting*, 2009 (böl. 10
  spin drift ve aerodinamik sıçrama, böl. 12 Coriolis); aerodinamik sıçrama
  yönü tartışması: https://forum.accurateshooter.com/threads/aerodynamic-jump.3939113
* Fritsch, F. N.; Carlson, R. E., *SIAM J. Numer. Anal.* 17 (1980) 238,
  https://doi.org/10.1137/0717021
* Dormand, J. R.; Prince, P. J., *J. Comput. Appl. Math.* 6 (1980) 19,
  https://doi.org/10.1016/0771-050X(80)90013-3

## Yeniden üretme

```bash
python3 tools/formula_reference.py               # senaryo tablosu
python3 tools/formula_reference.py --write-dart  # Dart vektörlerini yenile
python3 -m unittest tools.test_formula_reference
flutter test test/formula_reference_vectors_test.dart
```
