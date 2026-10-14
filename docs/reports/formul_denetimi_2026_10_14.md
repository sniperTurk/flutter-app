# Formül denetimi — 14 Ekim 2026

Dal: `audit/formul-2026-10-14` (main `237c14d`'den). Bu bir **denetim
raporudur**: `lib/` içinde hiçbir şey değiştirilmedi. Düzeltme kararı ana
oturumundur.

## Kısa özet (sade Türkçe)

- **Hatalı formül yok.** Kullanıcının girdiği değerden ekranda görünen sayıya
  giden bütün formüller (yörünge, sürüklenme tabloları, hava yoğunluğu, ses
  hızı, birimler, klik, Miller Sg, spin drift, rüzgâr sıçraması, Coriolis,
  eğim/yatma, barut sıcaklığı, PCP basınç tablosu, tahmini BC, WEZ, MPBR,
  paralaks, DOPE mesafeleri) bağımsız kaynaklarla karşılaştırıldı ve doğru
  çıktı.
- **Dün akşamdan beri birleşen değişiklikler (#264, #283, #284, #282, #262,
  #255, #272, #260, #243, #195) formülleri bozmadı.** Gizli bayraklar
  kapalıyken saklı Profil uzunluğu, Pro "Kalan tüp basıncı" ve Rüzgâr gözlemi
  hiçbir sonucu değiştirmiyor.
- Formül hatası olmayan ama **sahada yanlış sayı gösterebilecek 4 varsayım**
  ve **1 metin artığı** bulundu. En önemlisi: **Basınç kutusu boş, İrtifa
  dolu ise hesap deniz seviyesi basıncıyla (1013,25 hPa) yapılıyor**;
  1500 m'de .308 için 800 m'de ~80 cm (10 klik) hata.

| # | Bulgu | Durum | Önem | Sahadaki etki (örnek) |
|---|---|---|---|---|
| F1 | Basınç boş + İrtifa dolu → 1013,25 hPa kullanılır, irtifa yok sayılır | ? | **Yüksek** | .308, 1500 m: 300 m 2,4 cm · 500 m 14 cm (3 klik) · 800 m 80 cm (10 klik). PCP, 1000 m: 50 m 0,4 cm · 100 m 3,6 cm (4 klik) |
| F2 | Kule yolu: sıfırın kendi açısı yukarı yoldan düşülmüyor | ? | Orta | Yukarı yol .308'de ~13 klik, PCP saçmada ~38 klik fazla gösterilir; "Kule yetmez" uyarısı geç gelir |
| F3 | Regülatörsüz PCP + hız tablosu: sıfır profil hızıyla, atış tablo hızıyla | ? | Düşük–orta | 270 ↔ 255 m/s: 30 m sıfırda sıfır mesafesinde 0,8 cm, 50 m 1,3 cm, 100 m 2,6 cm |
| F4 | SFP retikül her zaman en yüksek büyütmede kalibre sayılıyor | ? | Düşük–orta | 4–16× / 10× kalibre, 16×'te: 4 çizgilik tutuş 4 değil 2,5 mrad → 50 m'de 7,5 cm |
| F5 | BC hesaplayıcı notu kaldırılan GA modelini öneriyor (#195 artığı) | ✗ (metin) | Düşük | Hesap etkisi yok; kullanıcıyı yanlış yönlendirir |

"?" = formül doğru, ama bir varsayım ya da iki değerin birleşimi bazı
durumlarda yanlış sonuç veriyor; kararı sahip verir.

## Yöntem

- **Bağımsız referans:** `tools/formul_denetimi_2026_10_14.py` (yalnız
  standart kütüphane). Uygulamanın Dart kodundan değil, yayımlanmış
  denklemlerden yazıldı. Hiçbir balistik program (ChairGun, Strelok, AB,
  QuickLOAD, GRT, JBM) referans alınmadı.
  - Yörünge: dünya (doğu-kuzey-yukarı) çerçevesinde nokta kütle, McCoy,
    *Modern Exterior Ballistics* (1999) böl. 4–5; Coriolis −2 Ω × v,
    Ω = ω (0, cos φ, sin φ). Uygulama dürbün çerçevesinde çözüyor; iki
    çerçevenin aynı sonucu vermesi eğim, yatma (cant), rüzgâr ve Coriolis
    dönüşümlerini sınar. RK4, 0,05 ms adım (uygulamanın 10 katı ince),
    Hermite ile menzil kesişimi, sekant ile sıfır.
  - Hava: ICAO Doc 7488/3 standart atmosfer; nemli hava yoğunluğu CIPM-2007
    (Picard ve ark., Metrologia 45 (2008) 149).
  - Kararlılık: Miller (Precision Shooting, Mart 2005), ses altı taban
    Courtney & Miller 2012 (arXiv:1410.5340); spin drift ve rüzgâr
    sıçraması Litz, *Applied Ballistics for Long-Range Shooting*.
  - Birimler: NIST SP 811 tanımları. Yerçekimi: WGS-84 Somigliana.
- İki bağımsız entegratör (bu araç ve 2026-10-13 aracı) .308'de 0,002 mrad
  içinde aynı (`tools/test_formul_denetimi_2026_10_14.py`).
- **Testler** `test/audit_2026_10_14/`:
  - `solver_3d_audit_test.dart`: çözücü ↔ referans, 10 durum (düz, rüzgâr,
    +30° eğim, +5° yatma, Coriolis doğu/kuzey, G7, saçma, saçma+rüzgâr,
    slug), tolerans 0,005 mrad / 0,5 ms; işaret kuralları.
  - `formulas_audit_test.dart`: kapalı formüller (aşağıdaki ✓ tablosu).
  - `findings_audit_test.dart`: F1–F5 için en küçük tekrar; beklenen
    davranışı anlatan testler `skip:` (CI yeşil kalır), yanlarında geçen
    kontrol testleri.

## Kontrol edilen formüller

| Alan | Formül / yol | Dosya | Durum |
|---|---|---|---|
| Yörünge | 3B nokta kütle, havaya göre hız, RK4 0,5 ms, sıfır açısı ikiye bölme | `core/aerodynamic_trajectory_solver.dart`, `rk4.dart` | ✓ (≤0,005 mrad) |
| Eğim | Menzil görüş hattı boyunca, sıfır düz | aynı | ✓ (+30°, 500 m: 3,3471 mrad) |
| Yatma (cant) | g ve rüzgâr dürbün eksenine döndürülür; saat yönü → sağa | aynı | ✓ (+5°, 500 m: −0,445 mrad) |
| Coriolis | −2 Ω × v; KY'de sağa, doğuya yüksek (Eötvös) | aynı | ✓ |
| Rüzgâr yönü | 0 karşı, 90 soldan, 270 sağdan; saat h ↔ 360−30h | `aerodynamic_trajectory_solver.dart`, `wind_clock.dart` | ✓ |
| Sürüklenme | a = ρ/2·v²·Cd(M)·(π/4)/(BC·703,07) | `reference_drag_model.dart` | ✓ |
| G1/G7 tabloları | BRL; G1(M1,0)=0,4805, tepe 0,6625 @ M1,40; G7(M1,0)=0,3803, tepe 0,4043 @ M1,05 | `standard_drag_tables.dart` | ✓ |
| Özel Cd eğrisi | BC yerine kesit yoğunluğu (form faktörü 1) | `drag_curve.dart` | ✓ |
| Çoklu BC | Eşik altındaki BC; Profil sırası doğru dönüşüyor | `ballistic_input.dart`, `profiles_screen.dart` | ✓ |
| Hava yoğunluğu | Magnus + ideal gaz, kuru + buhar | `atmosphere.dart` | ✓ (CIPM-2007'den en çok %0,074 fark) |
| Ses hızı | √(γ·P/ρ), 15 °C'de 340,29 m/s | `atmosphere.dart` | ✓ |
| İstasyon basıncı | ISA (1−2,25577e-5·h)^5,25588; sıcaklıklı hipsometrik | `tools/domain/field_calc.dart` | ✓ (1000 m: 898,75 hPa) |
| Yoğunluk irtifası, çiy noktası | ICAO; Magnus | `field_calc.dart` | ✓ |
| Yerel yerçekimi | WGS-84 Somigliana + serbest hava | `core/gravity.dart` | ✓ (45°: 9,80620) |
| Birimler | fps, mph, yd, inHg, °F, J↔ft·lbf, grain | `unit_system.dart`, `units.dart` | ✓ (tam tanımlar) |
| Açılar | 1 MOA = π/10,8 mrad; 1 SMOA = 1 in/100 yd = 1/3,6 mrad | `models/domain.dart` | ✓ |
| Klik | En yakın tam klik; ayak MOA aşağı yuvarlanır (20 MOA = 58 × 0,1 mrad) | `core/scope_dial.dart` | ✓ |
| Dürbün ayağı 0 MOA (#282) | 0 → 0 klik, yol değişmez | `ballistics_screen.dart:2784` | ✓ (bkz. F2) |
| FFP/SFP | SFP: kalibrasyon / büyütme | `scope_dial.dart` | ✓ (bkz. F4) |
| Sıfır ofseti, kule ölçeği | Açıya çevrilip her mesafede çıkarılır; klik / ölçek | `ballistics_screen.dart:760`, `:2726` | ✓ |
| Miller Sg (#264) | Ses altında ses hızı katsayısı; T ve P düzeltmesi | `core/stability.dart` | ✓ (.308: 2,381; slug 3,148) |
| Spin drift | 1,25·(Sg+1,2)·TOF^1,83 in; sağ yiv sağa; pellet yok | `ballistics_screen.dart:906` | ✓ |
| Rüzgâr sıçraması | Y = 0,01·Sg − 0,0024·L + 0,032 MOA/mph; sağ yivde sağdan rüzgâr yukarı | `ballistics_screen.dart:918` | ✓ |
| Mermi uzunluğu (#283) | Yalnız Pro kutusu; boşsa Sg ve spin drift yok | `ballistics_screen.dart:863` | ✓ |
| Kalan tüp basıncı (#284) | Bayrak kapalı: yalnız `profile.tubePressureBar` | `ballistics_screen.dart:817` | ✓ (bkz. F3) |
| PCP basınç tablosu | Doğrusal ara değer, uçlarda sabit; regülatör üstünde profil hızı | `core/pcp_pressure.dart` | ✓ |
| Tahmini G1 BC (#255/#262) | BC = SD / i, i: slug 0,825, pellet 2,06; yalnız kullanıcı PCP kaydı | `core/estimated_bc.dart` | ✓ |
| GA kaldırıldı (#195) | Model listesinde yok; eski 'ga' kaydı BC'siz okunur, tahmini G1 alır | `data/user_catalog.dart` | ✓ (bkz. F5 metin) |
| Rüzgâr gözlemi gizli (#272) | Seçim kutusu bayrak arkasında; rehber değer yazmıyor; yön zorunlu | `ballistics_screen.dart:579`, `:1680` | ✓ |
| Beaufort | WMO sınırları 0–7, boşluksuz | `core/beaufort.dart` | ✓ |
| Rüzgâr bölgeleri, payları | 1/3'lük bölgeler; % toplamı 100 | `ballistic_input.dart`, `wind_zone_shares.dart` | ✓ |
| Hava düğmeleri (#243/#260) | Hava servisi basınç yazmaz; telefon barometresi istasyon basıncı | `ballistics_screen.dart:1363`, `:1428` | ✓ (bkz. F1) |
| Barut sıcaklığı | v = v0·(1 + k/100·ΔT/15); mühimmat sıcaklığı önce | `core/powder_temperature.dart` | ✓ |
| Hız / BC doğrulama | Monoton ikiye bölme, ±%15 / ±%30 | `core/velocity_truing.dart` | ✓ |
| WEZ | Gauss kaynaklar, 5 atış ES = 3,067 σ, ± = 2 σ | `core/wez.dart` | ✓ |
| MPBR | Tepe = bölgenin yarısı; düz atış kuralı | `core/mpbr.dart` | ✓ |
| Paralaks, DOPE mesafeleri | Doğrusal ara değer; sıralı tekil | `parallax_range.dart`, `dope_ranges.dart` | ✓ |
| Retikül tutuşları | Çözücü noktaları arasında doğrusal | `reticle_holds.dart`, `scope_dial.dart` | ✓ |

Bilinçli basitleştirmeler (hata sayılmadı): sıfır ICAO standart havasında
çözülür (100 m sıfırda fark <0,01 mrad); spin drift Litz'in ampirik
formülüdür; tahmini BC'de liste kalibresi kullanılır (.22: 5,5 ↔ 5,52 mm,
BC'de %0,7).

## Bulgular (önem sırasıyla)

### F1 — Basınç boşken irtifa yok sayılıyor · ? · Yüksek

- **Yer:** `lib/features/ballistics/ballistics_screen.dart:1654`
  (`env(pressure, 1013.25, 29.92)`), uyarı `:1291` (basınç boşsa uyarı
  yok), metin `lib/features/ballistics/environment_field_info.dart:47`
  ("irtifa hesaba ayrıca girmez").
- **Ne yanlış:** Basınç kutusu boşsa 1013,25 hPa **istasyon basıncı**
  kabul ediliyor. İrtifa yazılmış olsa da kullanılmıyor ve hiçbir uyarı
  çıkmıyor. Hava Durumu boş başlıyor ve hava düğmesi basınç yazmıyor
  (#243), yani kullanıcı yalnız irtifayı girip bırakabilir.
- **Örnek:** 15 °C, nem %0, İrtifa 1500 m, Basınç boş → gösterilen yoğunluk
  1,2250 kg/m³. Beklenen (ICAO Doc 7488/3: 1500 m'de 845,56 hPa) 1,0223
  kg/m³, %20 fark. .308 168 gr G1 0,462, 2650 fps, sıfır 100 m:
  | Mesafe | Şimdiki | Beklenen | Fark |
  |---|---|---|---|
  | 300 m | 1,637 mrad | 1,556 mrad | 2,4 cm |
  | 500 m | 4,009 mrad | 3,729 mrad | 14 cm (3 klik) |
  | 800 m | 9,102 mrad | 8,102 mrad | 80 cm (10 klik) |
  PCP .22 G1 0,031, 280 m/s, sıfır 30 m, 1000 m irtifa: 50 m 0,4 cm,
  100 m 3,6 cm (0,36 mrad, ~4 klik). Mermi yüksek gider.
- **Önerilen düzeltme (metin):** Basınç boş ve İrtifa dolu ise ISA istasyon
  basıncı `FieldCalc.stationPressureHpa(1013.25, irtifa)` kullanılsın ve
  Atış'ta "basınç irtifadan tahmin edildi" yazsın; ya da en azından bu
  durumda `_pressureWarning` uyarı versin. İrtifa ⓘ metni buna göre
  güncellensin.
- **Risk:** Düşük; yalnız "basınç boş + irtifa dolu" durumu değişir.
  Yazılmış basınç her zaman öncelikli kalmalı.
- **Test:** `findings_audit_test.dart` "F1" (kontrol geçiyor, beklenen
  `skip`).

### F2 — Kule yukarı yolu sıfırın açısını saymıyor · ? · Orta

- **Yer:** `lib/features/ballistics/ballistics_screen.dart:2790`
  (`upClicks = min(halfUp + mountClicks, 2*halfUp)`), açıklama
  `lib/core/scope_dial.dart:222`; `scope_dial_view.dart` "Kule yetmez" ve
  ayak önerisi aynı varsayımı kullanıyor.
- **Ne yanlış:** 0 MOA ayakta sıfırın kulenin tam ortasında olduğu
  varsayılıyor. Oysa namlu görüş hattına göre sıfır açısı kadar yukarı
  bakmalı; sıfırlarken bu açı kadar YUKARI çevrilir (eğimli ayakların var
  olma nedeni budur). Gerçek yukarı yol = yarım yol − sıfır açısı + ayak.
- **Örnek (referans aracı, `finding_turret_zero_angle`):**
  - .308, 800 m/s, 45 mm, sıfır 100 m, Gazi 6–36 (26 mrad, 0,1 klik):
    şimdi 130 klik yukarı; beklenen ≈ 130 − 13 = 117.
  - PCP saçma 280 m/s, 50 mm, sıfır 30 m: sıfır açısı 3,77 mrad (38 klik
    0,1 mrad; 52 klik ¼ MOA). 15 mrad'lık bir dürbünde 75 yerine ~37 klik.
- **Sahada:** Uzak atışta kule "yeter" görünür ama dürbün durur; uyarı ve
  ayak önerisi bir kademe geç gelir. Gösterilen klik sayısı (gereken
  düzeltme) **değişmez**, yalnız sınır yanlış.
- **Önerilen düzeltme:** Çözücünün sıfır açısını (namlu−görüş hattı, mrad)
  dışarı verip `upClicks = min(halfUp + mount − zeroClicks, 2·halfUp)`,
  `downClicks = max(0, halfUp − mount + zeroClicks)`; `mountBlocksZero` da
  `mount − zero > halfUp` olsun. Ray/namlu toleransı bilinmediği için
  "yaklaşık" denmesi iyi olur.
- **Risk:** Orta; kule sınırları, otomatik çevirme kısıtı ve ayak önerileri
  değişir, ilgili testler güncellenmeli.
- **Test:** `findings_audit_test.dart` "F2" (kontrol geçiyor, beklenen `skip`).

### F3 — Regülatörsüz PCP: sıfır ve atış farklı hızla · ? · Düşük–orta

- **Yer:** `lib/features/ballistics/ballistics_screen.dart:1741–1742`
  (`vToday = _pcpVelocity(...)`, `vZero = vToday == v ? null : v`).
- **Ne yanlış:** #284 ile tüp basıncı artık Profil'de bir kez girilen sabit
  değer. Regülatörsüz tüfekte "Basınca göre hız" tablosu o basınçta profil
  hızından farklı bir hız veriyorsa atış tablo hızıyla, sıfır ise profil
  hızıyla çözülüyor. Sonuç: profil kendi sıfır mesafesinde bile sıfırda
  değil. (Pro'da "kalan basınç" varken bu mantıklıydı; artık basınç değişmiyor.)
- **Örnek:** .22 G1 0,031, sıfır 30 m, profil 270 m/s, tablo o basınçta
  255 m/s: sıfır mesafesinde (30 m) 0,26 mrad (0,8 cm), 50 m 1,3 cm, 100 m
  2,6 cm fark. Sıfır 100 m olsa sıfır mesafesinde 1,0 mrad.
- **Önerilen düzeltme:** Tablo hızı kullanılıyorsa sıfır da aynı hızla
  çözülsün (`vZero = null` PCP tablo yolunda), ya da tablo ile profil hızı
  çelişince Profil'de uyarı verilsin. Hangi hızın "doğru" olduğu sahip
  kararı.
- **Risk:** Düşük; yalnız regülatörsüz + tablo + tüp basıncı dolu profiller.
- **Test:** `findings_audit_test.dart` "F3" (kontrol geçiyor, beklenen `skip`).


### F4 — SFP kalibrasyon büyütmesi hep en yüksek büyütme · ? · Düşük–orta

- **Yer:** `lib/features/ballistics/scope_dial_view.dart:212`
  (`calibrationMag => maxMagnification ?? 1`).
- **Ne yanlış:** SFP retikülün hangi büyütmede doğru olduğu üretici
  belgesinde yazar; her dürbünde en yüksek büyütme değildir (bazı
  modellerde ör. 10× ya da 12×). Katalogda bu bilgi yok.
- **Örnek:** 4–16× SFP, 10×'te kalibre; dürbün görünümünde 16× seçili:
  uygulama 1 çizgi = 16/16 = 1 mrad der, gerçekte 10/16 = 0,625 mrad.
  4 çizgilik tutuş 2,5 mrad'dır → 50 m'de 7,5 cm, 100 m'de 15 cm.
  Yalnız büyütme seçildiğinde ve SFP dürbünde.
- **Önerilen düzeltme:** Dürbün kaydına "Retikül kalibrasyon büyütmesi"
  (boşsa en yüksek büyütme), ⓘ ile; katalogdaki SFP'ler için üretici
  değerleri doldurulsun.
- **Risk:** Düşük; FFP etkilenmez.
- **Test:** "F4" (kontrol geçiyor, beklenen `skip`).

### F5 — GA artığı metin · ✗ (metin) · Düşük

- **Yer:** `lib/features/tools/calculators_screen.dart:948`.
- **Ne yanlış:** "İki hızdan BC" notu "Diabolo saçmada GA, G1/G7'den daha
  uygundur" diyor; GA #195 ile kaldırıldı, saçmalar G1 ile hesaplanıyor.
- **Etki:** Hesap yok; kullanıcıyı olmayan bir modele yönlendirir.
- **Önerilen düzeltme:** Cümleyi "Saçma ve slug BC'leri G1'e göre
  yayımlanır" gibi bir metinle değiştirmek.
- **Risk:** Yok.

## Gizli bayraklar kapalıyken

| Saklı değer | Hesaba girer mi? | Kanıt |
|---|---|---|
| Profil > Mühimmat uzunluğu (`lengthMm`) | Hayır; Sg/spin drift yalnız Pro kutusu | `ballistics_screen.dart:863`; `lengthMm` başka hesapta yok (grep) |
| Pro "Kalan tüp basıncı" (`tubePressureText`) | Hayır (`PRO_TUBE_PRESSURE` kapalı) | `ballistics_screen.dart:820`; `test/pcp_pressure_ui_test.dart` |
| Rüzgâr gözlemi | Hayır; seçim kutusu yok, değer saklanmıyor | `ballistics_screen.dart:579–606` |

## Kontroller

Yerel:

- `python3 tools/offline_dart_lint.py` → PASS (328 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 740 test OK
- Flutter SDK: **ENGELLİ** — `storage.googleapis.com` vekil sunucuda
  reddedildi (403), Dart SDK indirilemedi; `flutter test` yerelde
  çalışmadı.

CI: aşağıdaki bölüm CI çalıştıktan sonra doldurulur.

---
_Generated by [Claude Code](https://claude.ai/code)_
