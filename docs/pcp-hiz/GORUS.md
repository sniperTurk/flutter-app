# PCP: tüp basıncı ve regülatör basıncı — görüş

Tarih: 2026-10-12 · Durum: öneri, onay bekliyor · Kod değişikliği: yok

Sahibin sorusu: "PCP'de tüp basıncına ve regülatör basıncına göre namlu çıkış
hızını hesaplamak istiyoruz. Tüp basıncını ve regülatör basıncını kullanıcıdan
veri olarak alalım mı? Bu formülde işimize yarar mı?"

## 1. Kısa cevap

İkisini de alalım. Ama "basınçtan hızı hesaplayan bir formül" için değil;
**kullanıcının kronografla ölçtüğü hızın hangi basınçta geçerli olduğunu
bilmek** ve **ölçülen değerler arasında ara değer bulmak** için.

| Veri | Alalım mı? | Nerede | Ne işe yarar |
|---|---|---|---|
| Regülatör basıncı | Evet, isteğe bağlı | Profil (yalnız PCP), bir kez | Tüp bu değerin altına inince "hız düşüyor" uyarısı; profildeki hızın geçerli olduğu sınır |
| Hız ölçüm basıncı | Evet, isteğe bağlı | Profil (yalnız PCP), namlu çıkış hızının yanında | Profildeki hızın hangi tüp basıncında ölçüldüğü; regülatörsüzde eğrinin ilk noktası |
| Basınç–hız ölçümleri | Evet, isteğe bağlı, 0–10 satır | Profil (yalnız PCP) | Regülatörsüzde basınca göre hız; regülatörlüde regülatör altındaki düşüş |
| Tüp basıncı (şu anki) | Evet, isteğe bağlı | Pro Ayarlar (yalnız PCP); Hedef yalnız gösterir | Bugünkü hızı seçmek ve uyarı vermek |
| Dolum basıncı, tüp hacmi, vana/çekiç ayarı | Hayır | — | Ölçümsüz formül güvenilir olmadığı için hızı hesaplamaya yetmez (bölüm 4) |

Ölçüm yoksa uygulama bugünkü gibi profildeki namlu çıkış hızını kullanır ve
basınçtan hız **uydurmaz**. Hiçbir alan doldurulmazsa davranış bugünküyle
birebir aynıdır (ayrı aç/kapa düğmesi yok; veri girilince etkin olur).

Sahibin eğilimine (ikisini de almak) katılıyorum; tek farkım şu: iki basınç
**tek başına** hız vermez. Hızı veren, kullanıcının o basınçlarda yaptığı
kronograf ölçümüdür. Bu yüzden iki basıncın yanına küçük, isteğe bağlı bir
"Basınç–hız ölçümleri" listesi öneriyorum.

## 2. Bilinenler ve kaynakları

Kaynak kuralı: yalnız üretici sitesi/kılavuzu, hakemli dergi veya resmi yayın
(patent, kamu kurumu). Forum, blog ve bayi sitesi kullanılmadı. ChairGun,
Strelok, Applied Ballistics vb. hiçbir yazılımın verisi veya formülü
kullanılmadı.

### 2.1 Regülatörlü PCP: hız sabit, tüp regülatör altına inince düşer

- Regülatör, sabit basınçta çalışan ikinci bir hava odası (plenum) kurar;
  güç çıkışı dolumun tamamı boyunca tutarlı kalır [K1].
- Ana tüp basıncı regülatörün çalışma basıncının altına inerse regülatör
  "fiilen devre dışı" kalır; bundan kaçınılmalıdır [K1].
- Regülatör çıkış basıncı ayarlanabilir; örnek bir üretici fabrika ayarını
  125 bar verir [K3]. Yani regülatör basıncı tüfekten tüfeğe değişir ve
  kullanıcıdan alınmalıdır; varsayılan konamaz.
- Regülatörlü tüfek ardışık atışlarda tutarlı hız verir, regülatörsüzde hız
  basınç düştükçe azalır [K8].

Doğrulama notu: sahibin verdiği Daystate sayfası [K1] iddiayı doğruluyor.
Sahibin verdiği ikinci kaynak (Pyramyd Air blogu) bir **bayi blogu** olduğu
için kaynak kuralı gereği kullanılmadı; yerine üretici kılavuzu [K2] ve
patent [K6] konuldu.

### 2.2 Regülatörsüz PCP: önce yükselen, ortada düz, sonra düşen eğri

- Hatsan kılavuzu (regülatörsüz model): "hız tüpteki en yüksek basınçta daha
  düşük başlar, sonra artmaya başlar; tüpte en uygun basınçta en yükseğe
  ulaşır; tüpteki basınç azaldıkça yeniden düşmeye başlar" [K2, s. 4].
- Aynı kılavuz: azami dolum basıncını aşmak hızı düşürür [K2, s. 6].
- Daystate: regülatörsüzde güç çıkışı bir tepeye yükselir, sonra dolum
  gerekinceye kadar düşer; vananın bıraktığı hava miktarı, arkasındaki
  basınç düştükçe değişir [K1].
- Nedeni (yüksek basınçta vananın zor açılması): vanayı kapalı tutan, haznedeki
  havanın vana başına bastırmasıdır; yüksek basınçta vanayı itmek için
  gereken darbe çok yüksektir; regülatörsüz tüfekte basınç düştükçe vana her
  atışta biraz daha fazla açılır [K6].

### 2.3 Saf fizik formülü (ölçümsüz) güvenilir değil

- Hakemli bir çalışmada basınçlı hava topunun çıkış hızı, ideal gazın hem
  adyabatik hem izotermal genleşme modeliyle hesaplanmış; ölçümlerle "büyük
  uyumsuzluk" görülmüştür. Uyum, ancak vananın akışını hesaba katan ve
  **ölçümlere uydurulan iki parametreli** bir modelle sağlanmıştır; hafif
  mermide model yüksek basınçta yine sapmıştır [K5].
- PCP'de hızı belirleyen vana açılma süresi ve açıklığı, çekiç yayı,
  transfer portu, plenum hacmi, saçmanın namluya oturması ve sürtünmesi gibi
  büyüklüklerin çoğu üretici tarafından yayımlanmaz ve tüfekten tüfeğe
  değişir [K1, K6]. Bunlar bilinmeden formül, ölçüme uydurulmuş parametre
  olmadan hız veremez.

Sonuç: "tüp basıncı ve regülatör basıncı → formül → hız" yolu bu uygulama
için **önerilmez**. Formüle girecek parametreleri bulmanın tek yolu zaten
kronograf ölçümü; ölçüm varsa doğrudan ölçülen hızı kullanmak hem daha basit
hem daha doğrudur.

### 2.4 Sıcaklık

- Gaz denklemi: p = ρ·R·T [K7]. Kapalı tüpte (ρ sabit) basınç mutlak
  sıcaklıkla orantılıdır. Örnek (ideal gaz yaklaşımı): 20 °C'de 200 bar
  gösteren tüp 0 °C'de yaklaşık 186 bar gösterir (201 × 273,15 / 293,15 − 1).
  200 bar düzeyinde hava ideal gazdan bir miktar sapar; sayı yaklaşıktır.
- Bir üretici rehberi "PCP tüfekler sıcaklıktan bağımsız olarak tutarlı
  basınç korur" der [K8]. Bu cümle CO2 ile karşılaştırma bağlamındadır;
  tüp basıncının sıcaklıkla değişmesi gaz denklemiyle [K7] çelişir, bu
  yüzden mutlak bir kural olarak alınmamalıdır.
- PCP hızının sıcaklıkla **ne kadar** değiştiğini veren bir üretici veya
  hakemli kaynak bulunamadı. Bu yüzden barut sıcaklığı gibi bir katsayı
  önerilmez; sayı uydurulmaz.

Uygulamaya etkisi:

1. Kullanıcı tüp basıncını **sahada manometreden okuduğu** için okunan değer
   o anki sıcaklığın etkisini zaten içerir. Soğukta tüp regülatör altına daha
   erken iner; uygulama bunu okunan değerden görür. Ek düzeltme gerekmez.
2. Sıcaklığın vana akışına doğrudan etkisi (büyüklüğü bilinmiyor) için
   öneri: "Hızı, atış yapacağınız sıcaklığa yakın bir günde ölçün" diye ⓘ
   metninde söylemek. Hesaba katsayı eklenmez.
3. Barut sıcaklığı düzeltmesi (lib/core/powder_temperature.dart) yalnız
   ateşli tüfekte kalır; PCP'de açılmaz.

### 2.5 Uyarı fikri üreticide de var

Elektronik vanalı, regülatörsüz bir Daystate modelinde ekranda "Low
Pressure" uyarısı çıkar ve bu uyarının basıncı kalibreye, enerjiye ve güç
ayarına bağlıdır [K4, s. 11]. Yani uyarı eşiği tüfeğe özgüdür; uygulama sabit
bir eşik değil, kullanıcının girdiği regülatör basıncını ve ölçümlerini
kullanmalıdır.

## 3. Varsayımlar (sahibi yokken verdiğim cevaplar)

1. Basınç birimi bar (Türkiye'de manometreler çoğunlukla bar). psi gösterimi
   ileride birim tercihine bağlanabilir; bu turun konusu değil.
2. Tüp basıncı (şu anki) sık değişmez (birkaç atışta bir okunur). Bu yüzden
   giriş kutusu Pro Ayarlar'da, Hedef ekranı yalnız durumu ve uyarıyı
   gösterir. Hedef'e giriş kutusu istenirse aynı değer paylaşılabilir.
3. Eski profillerdeki `pressureBar` değeri, 2026-10-09 öncesinde "Regülatör
   basıncı" olarak soruluyordu (profiles_screen.dart'taki kayıt notu). Bu
   değer yeni "Regülatör basıncı" kutusuna gelir; kullanıcı bir kez onaylar
   (bölüm 5.3).
4. Hedef ve Pro'da ölçüm aralığı dışına **uzatma (ekstrapolasyon) yapılmaz**.
5. "Yaklaşıyor" uyarısı için bir eşik gerekir. Önerim: tüp basıncı
   regülatör basıncının %10 üstüne inince. Bu bir **arayüz eşiğidir**, fizik
   değeri değildir ve hızı değiştirmez; sahibi değiştirebilir.

## 4. Değerlendirilen yollar

- **A — Önerilen: iki basınç + isteğe bağlı ölçüm listesi.** Hız her zaman
  kullanıcının ölçümünden gelir; basınçlar ölçümün geçerli olduğu aralığı ve
  uyarıları belirler. Az veri girene bugünkü davranış, çok veri girene
  basınca göre hız.
- **B — Yalnız regülatör basıncı + tüp basıncı, ölçüm listesi yok.** Uyarı
  verir ama regülatörsüz tüfekte ve regülatör altında hız hiç değişmez.
  Basit; ancak sahibin "hız hesaplamak" hedefini karşılamaz.
- **C — Fizik formülü (ölçümsüz).** Reddedildi: bölüm 2.3. Varsayılan vana
  ve hacim değerleri uydurmak gerekir; bu, projenin "uydurma varsayılan yok"
  ilkesine aykırıdır.

## 5. Önerilen veri modeli

### 5.1 Profil (yalnız PCP)

```text
RifleProfile
  pressureBar              double?   // ANLAMI: Regülatör basıncı (bar). Eski anahtar korunur.
  pcpVelocityPressureBar   double?   // Hız ölçüm basıncı: muzzleVelocityMps ölçülürken manometre (bar)
  pcpVelocityPoints        List<{pressureBar: double, velocityMps: double}>  // 0–10 satır
```

Kurallar (doğrulama):

- Hepsi isteğe bağlı. Basınçlar 0 < p ≤ ProductionLimits.maxPcpPressureBar
  (500), hızlar 0 < v ≤ maxMuzzleVelocityMps.
- Ölçüm satırlarında aynı basınç iki kez olamaz; en çok 10 satır.
- Regülatör basıncı girilmişse ölçüm satırlarının basıncı regülatör
  basıncından küçük olmalı (üstündeki hız zaten profildeki hızdır).
- Hız ölçüm basıncı regülatör basıncından küçükse kayıt engellenmez; uyarı
  gösterilir: "Hız regülatör basıncının altında ölçülmüş görünüyor."
- **Ateşli tüfek profilinde bu üç alandan biri doluysa profil reddedilir**
  (profile_catalog_integrity.dart'taki bugünkü `pressureBar` kuralının
  genişletilmesi). Ateşli tüfek profil formu bu alanları hiç oluşturmaz.

### 5.2 Atış ayarları (profil başına, yalnız PCP)

```text
ShotSettings (lib/services/shot_settings_store.dart)
  pcpTubePressureBar  double?   // Pro Ayarlar > Tüp basıncı; uygulama kapanınca korunur
```

Platform ateşli tüfekse bu değer okunmaz, yazılmaz, gösterilmez.

### 5.3 Eski profillerle uyum

- JSON'da `pressureBar` aynı anahtar ve aynı sınırlarla kalır; anlamı
  "Regülatör basıncı" olarak belgelenir. Göç (migration) yok.
- Yeni anahtarlar yoksa: hız ölçüm basıncı boş, ölçüm listesi boş. Bozuk
  değer sessizce null'a çevrilmez, profil reddedilir (bugünkü
  profile_codec.dart davranışıyla aynı).
- 2026-10-09 ile bu özellik arasında kaydedilmiş PCP profillerinde
  `pressureBar` boştur; bir şey değişmez.
- Eski `pressureBar` dolu ise Profil formunda kutu dolu gelir ve bir kez
  bilgi gösterilir: "Önceki sürümde girdiğiniz regülatör basıncı yüklendi;
  kontrol edip kaydedin."
- Ateşli tüfek profilleri: bugün `pressureBar` taşıyamazlar
  (bütünlük kuralı); yeni alanlar da aynı kurala girer. Ateşli tüfek JSON'u
  değişmez.

## 6. Hesap akışı (pseudo-kod)

```text
// Tek giriş noktası; Hedef, Pro, DOPE ve Hız Doğrulama aynı yolu kullanır.
double todayVelocity(profile, platform, todayTempC, shotSettings):
    if platform == firearm:
        // DEĞİŞMEZ: bugünkü barut sıcaklığı yolu birebir aynı kalır.
        return profile.muzzleVelocityMps * PowderTemperature.factor(...)
    // platform == pcp
    return PcpVelocity.resolve(
        v0     = profile.muzzleVelocityMps,
        reg    = profile.pressureBar,
        v0Bar  = profile.pcpVelocityPressureBar,
        points = profile.pcpVelocityPoints,
        tube   = shotSettings.pcpTubePressureBar,
    ).velocity

PcpVelocity.resolve(v0, reg, v0Bar, points, tube) -> (velocity, status):
    if tube == null:                       return (v0, NO_TUBE)          // bugünkü davranış
    if reg != null:                                                      // regülatörlü
        if tube >= reg:
            return (v0, tube < reg * 1.10 ? NEAR_REG : REGULATED)
        // regülatör altında: (reg, v0) noktası + regülatör altındaki ölçümler
        curve = sort([(reg, v0)] + points)
        if curve.length >= 2 and min(curve.p) <= tube:
            return (interpolate(curve, tube), BELOW_REG_MEASURED)
        return (v0, BELOW_REG_UNKNOWN)                                    // hız uydurulmaz
    // regülatörsüz (veya regülatör bilinmiyor)
    curve = sort(points + (v0Bar != null ? [(v0Bar, v0)] : []))
    if curve.length < 2:                   return (v0, NO_CURVE)
    if tube < min(curve.p) or tube > max(curve.p):
                                           return (v0, OUTSIDE_CURVE)     // uzatma yok
    return (interpolate(curve, tube), CURVE_MEASURED)

interpolate: ardışık iki ölçüm noktası arasında doğrusal ara değer.
```

`(reg, v0)` noktası şu kabule dayanır: tüp tam regülatör basıncındayken
regülatör hâlâ çalışır, yani hız profildeki düz bölgedeki hızdır [K1]. Bu,
regülatör altındaki ilk ölçümle birleşince düşüşü iki ölçüm arasında
doğrusal kabul eder; daha çok ölçüm daha iyi eğri verir.

### 6.1 Uyarılar (Hedef ve Pro, yalnız PCP)

| Durum | Ton | Metin |
|---|---|---|
| NEAR_REG | uyarı | "Tüp basıncı regülatör basıncına yaklaştı. Birkaç atış sonra hız düşmeye başlar; tüpü doldurun." |
| BELOW_REG_MEASURED | uyarı | "Tüp regülatör basıncının altında. Hız, ölçümlerinizden hesaplandı: 837 fps." |
| BELOW_REG_UNKNOWN | tehlike | "Tüp regülatör basıncının altında; hız düşer ama ne kadar düştüğü ölçülmedi. Hesap profildeki hızı kullanıyor, isabet aşağı kayabilir. Tüpü doldurun." |
| OUTSIDE_CURVE | uyarı | "Tüp basıncı ölçtüğünüz aralığın dışında; hesap profildeki hızı kullanıyor." |
| NO_CURVE, NO_TUBE, REGULATED, CURVE_MEASURED | — | Uyarı yok; Pro'da yalnız "Bugünkü hız" satırı |

Uyarı metinleri bir sonraki görevde son hâlini alır.

### 6.2 Ateşli tüfeğe etkisizlik (nasıl güvenceye alınır)

1. Arayüz: yeni kutular yalnız `platform == WeaponPlatform.pcp` iken
   oluşturulur (bugünkü barut sıcaklığı satırının tam tersi koşulu).
   Ateşli tüfekle açılan Profil, Pro ve Hedef ekranlarında **hiç
   görünmezler**.
2. Veri: ateşli tüfek profilinde bu alanlar doluysa profil bütünlük kontrolü
   reddeder; codec ateşli tüfek için bu anahtarları yazmaz.
3. Hesap: `todayVelocity` platform ateşli tüfekse PCP yoluna hiç girmez.
4. Testler: (a) ateşli tüfek profiliyle Profil/Pro/Hedef'te yeni anahtarların
   bulunmadığını doğrulayan widget testleri; (b) aynı ateşli tüfek girdisiyle
   çözücü çıktısının bu değişiklikten önce ve sonra birebir aynı olduğunu
   gösteren altın test; (c) PCP alanı taşıyan ateşli tüfek JSON'unun
   reddedildiği codec/bütünlük testi.

## 7. Yapılmayacaklar

- Basınçtan fizik formülüyle hız hesabı.
- Tüfek modeline göre varsayılan regülatör basıncı veya varsayılan eğri.
- Kalan atış sayısı tahmini (atış başına basınç düşüşü ölçülmeden yapılamaz;
  istenirse ayrı konu).
- PCP için sıcaklık katsayısı.

## 8. Taslaklar

`docs/pcp-hiz/taslak/` altında (SVG kaynak, PNG önizleme):

- `01-profil-pcp.svg/png` — Profil > Mühimmat kartı, PCP: yeni satır
  "Hız ölçüm basıncı | Regülatör basıncı" ve "Basınç–hız ölçümleri" listesi;
  önerilen ⓘ metinleri yanında.
- `02-profil-atesli-karsilastirma.svg/png` — aynı kart ateşli tüfekte
  (bugünkü hâliyle aynı, barut sıcaklığı satırı) ve PCP'de yan yana.
- `03-pro-pcp.svg/png` — Pro Ayarlar > Tüp basıncı bölümü, PCP:
  "Tüp basıncı | Bugünkü hız" satırı; Bugünkü hız giriş değil, hesaplanan
  değerdir.
- `04-hedef-pcp.svg/png` — Hedef, PCP: durum satırı ve dört uyarı durumu.
- `05-pro-hedef-atesli.svg/png` — Pro ve Hedef, ateşli tüfek: yeni hiçbir
  şey yok.

Taslak kuralları: her alanda ⓘ; kutu altında yardım yazısı yok; etiketlerde
parantez yok; kutularda örnek değer yok; kalın yazı yok; liste kutuları
"Seçiniz" ile başlar; satırda iki kutu; "Sight height" İngilizce kalır (bu
taslaklarda o alan görünmüyor, Tüfek kartında değişmeden durur); ayrı
aç/kapa düğmesi yok. SVG'ler yazı tipini depodaki
`assets/fonts/Oswald-Regular.ttf` dosyasından yükler; PNG'ler aynı
SVG'lerin Chromium ile alınmış görüntüsüdür.

Not: Sahibin isteği üzerine taslaklarda Oswald yazı tipi kullanıldı. Kodda
2026-10-12 tarihli bir kayıt, uygulama yazı tipinin Oswald'dan Inter'e
geçtiğini söylüyor (lib/ui/menzil_theme.dart). Uygulamada hangisinin
kullanılacağına sahibi karar vermeli.

## 9. Kaynaklar

- [K1] Daystate Ltd., Nigel Allen, "Regulated PCP vs Unregulated", 2018-07-11.
  https://daystate.com/?p=1423
- [K2] Hatsan, "Airmax Manual V21.3", kullanım kılavuzu, s. 3–6.
  https://hatsanairgunsusa.com/wp-content/uploads/2021/03/Airmax-Manual_V21.3.pdf
- [K3] Hatsan USA, "Hatsan PCP Regulator" ürün sayfası (çıkış basıncı
  ayarlanabilir, fabrika ayarı 125 bar).
  https://hatsanairgunsusa.com/product/hatsan-pcp-regulator
- [K4] Daystate Ltd., "Red Wolf RW GP A5 Handbook 2024", s. 4 ve 11.
  https://daystate.com/wp-content/uploads/2024/07/RED-WOLF-RW-GP-A5-Handbook-2024.pdf
- [K5] Z. J. Rohrbach, T. R. Buresh, M. J. Madsen, "Modeling the exit velocity
  of a compressed air cannon", American Journal of Physics 80, 24–26 (2012),
  doi:10.1119/1.3644253 (ön baskı: arXiv:1106.2803).
- [K6] H. F. du Plessis, "Valve assembly for a pre-charged pneumatic airgun",
  ABD patenti US 12,247,802 B2, 2025-03-11.
  https://patents.google.com/patent/US12247802
- [K7] NASA Glenn Research Center, "Equation of State".
  https://www.grc.nasa.gov/www/k-12/airplane/eqstat.html
- [K8] Umarex USA, "A Complete Guide to PCP Airguns: Everything You Need to
  Know", 2025-04-06.
  https://www.umarexusa.com/a-complete-guide-to-pcp-airguns-everything-you-need-to-know

Kullanılmayan: Pyramyd Air blogu "about-pcps-and-tuning-part-one" (bayi
blogu; kaynak kuralı dışında).

## 10. #178 (feat/pcp-basinc) incelemesi

İncelenen: #178 başı `9eb0dc4`. Yalnız okundu, kod değiştirilmedi.

### Uygun olanlar

- Temel yaklaşım bu görüşle aynı: formül ve varsayılan yok; hız
  kullanıcının kronograf ölçümünden (`PcpPressure.interpolate`) geliyor;
  ölçüm yoksa profildeki hız kullanılıyor (bölüm 2.3, [K5]).
- Regülatörlü tüfekte tüp ≥ regülatör → profildeki hız; altına inince uyarı
  ([K1]).
- Boş regülatör kutusu = regülatörsüz; ayrı aç/kapa yok. `pressureBar` aynı
  anahtarla regülatör basıncı olarak kalıyor; eski profiller okunuyor.
- Ateşli tüfek: alanlar yalnız `platform == pcp` iken var, bütünlük kuralı
  ateşli profilde PCP verisini reddediyor, ateşli çözümün değişmediğini
  gösteren UI testi var. Sıfır, profildeki hızla çözülüyor (`vZero`).

### Düzeltilmesi önerilenler (önem sırasıyla)

1. **Ölçüm aralığı dışında uç değer, uyarısız.**
   `PcpPressure.interpolate` en düşük ölçümün altında en düşük ölçümün hızını
   döndürüyor. Regülatörsüz tüfekte basınç düşmeye devam ettikçe hız da düşer
   ([K2, s. 4]). Uygulama ise ölçülmemiş bir hızı varsayıyor: hız olduğundan
   yüksek alınıyor ve atış sessizce aşağı vuruyor. Bu, "uydurma yok"
   ilkesiyle çelişiyor.
   Öneri: aralık dışına uzatma yapılmasın. Profildeki hız kullanılsın ve
   "ölçtüğünüz aralığın dışında" uyarısı gösterilsin (bölüm 6.1
   OUTSIDE_CURVE). En azından uç değer kullanılırken uyarı çıkmalı.
2. **Regülatör altında eğrinin üst ucu bağlanmamış.**
   `velocity()` regülatör altında yalnız tablo noktalarını kullanıyor.
   Örnek: regülatör 150 bar, profil hızı 900 fps, tablo 120→860 ve
   100→820, tüp 140. Uç değer kuralıyla sonuç 860 fps; oysa 140 bar,
   150 bar (900) ile 120 bar (860) arasında kalır. Ayrıca tabloda regülatör
   altında tek bir ölçüm varsa, `minPoints = 2` yüzünden o ölçüm hiç
   kullanılmıyor.
   Öneri: (regülatör basıncı, profil hızı) noktası tabloya eklensin (bölüm
   6). Regülatör basıncında regülatör hâlâ çalışır, hız düz bölgededir
   [K1].
3. **Profildeki "Tüp basıncı" ile Pro'daki "Kalan tüp basıncı" karışabilir.**
   Profildeki kutu dolum basıncı. Hesapta yalnız "kalan > dolum" uyarısında
   ve "regülatör < tüp" doğrulamasında kullanılıyor. Etiket "Dolum
   basıncı" olursa iki kutu karışmaz.
   Daha yararlı seçenek: kutu "Hız ölçüm basıncı" olsun, yani profildeki
   hızın ölçüldüğü basınç. Böylece profildeki hız regülatörsüz eğrinin bir
   noktası olur ve tek ölçümle iki noktalı eğri kurulabilir (bölüm 5.1).
   Sahibin kararı.
4. **Kaynak kuralı.** `lib/core/pcp_pressure.dart` açıklaması ve PR metni
   Pyramyd Air blogunu (bayi) gösteriyor. Yerine Hatsan kılavuzu [K2, s. 4]
   ve patent [K6] konmalı.
5. **Pro açıklamasındaki sayılar varsayımsız.** Metin şöyle: "Hız 10 m/s
   düşerse 50 m'de yaklaşık 1,2 cm, 75 m'de 2,8 cm aşağı vurur". Bu sayılar
   saçmaya, BC'ye, hıza ve sıfırlama mesafesine bağlı; metinde hangi saçma
   için hesaplandığı yazmıyor ve PR'a göre "ana oturumun hesabı". İki seçenek
   var: varsayımlar ⓘ içinde yazılsın (saçma, hız, sıfır), ya da sayı
   kaldırılıp "aşağı vurursun" denilsin.
6. **"Yaklaşıyor" uyarısı yok.** Uyarı ancak tüp regülatör altına inince
   çıkıyor. Atıcı dolumu önceden bilsin diye regülatör basıncının biraz
   üstünde bir uyarı önerilir. %10 bir arayüz eşiği önerisidir, hızı
   değiştirmez (bölüm 3/5).
7. **Hız Doğrulama ile etkileşim (iki tasarımda da açık).** Hız Doğrulama
   tüp basıncını hesaba katmıyor. Kullanıcı tüp regülatör altındayken hızı
   doğrularsa, düşük hız profildeki hız olarak kaydedilir; tüp dolunca hesap
   yanlış olur.
   Öneri: PCP'de tüp basıncı regülatör altındaysa Hız Doğrulama bunu
   uyarsın. Ya da doğrulanan hız, profildeki hız yerine o basınçta bir
   ölçüm noktası olarak kaydedilsin. Sahibin kararı.
8. **Küçük:** Pro'da "Kalan tüp basıncı" tek başına bir satırda. Satırda iki
   kutu kuralı için yanına "Bugünkü hız" çıktı kutusu konabilir (taslak 03).
   Bugünkü "Kullanılan hız: … fps" satırı bir sonuç satırı olarak kalabilir.

### Sonuç

#178 doğru yönde ve bu görüşle büyük ölçüde örtüşüyor. Önerim: sıfırdan
başlamak yerine #178 üzerinde 1, 2 ve 4 numaralı maddeler düzeltilsin. 3, 5,
6 ve 7 numaralı maddeler sahibinin kararına sunulsun. Bu durumda
`docs/superpowers/plans/2026-10-12-pcp-hiz.md` ayrı bir uygulama olarak
değil, #178 için bir denetim listesi olarak kullanılmalı.
