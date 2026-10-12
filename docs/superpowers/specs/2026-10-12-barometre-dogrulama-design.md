# Ö4 barometre, Ö6 çok mesafeli doğrulama, Ö13 doğrulama altyapısı — tasarım

Kaynak: `docs/yeni-hesaplar-2026-10-11.md` (PR #153, dal `docs/yeni-hesaplar`),
Ö4, Ö6, Ö13 ve bölüm 2 tabloları. Taban: `main` @ 7801ae3.

## 0. Sınıflandırma ve kararlar

Görev mimari ölçekli (yeni platform verisi + yeni uydurma alt sistemi). Sahibi
yok; brainstorming onay noktalarındaki cevaplar burada yazılı (K = karar,
V = varsayım).

| # | Karar / varsayım | Gerekçe |
|---|---|---|
| K1 | Barometre `sensors_plus` 7.1.1'in `barometerEventStream()` ile okunur; ayrı Swift kodu yazılmaz. | Paket zaten bağımlılıkta (Su Terazisi). iOS tarafı `CMAltimeter.startRelativeAltitudeUpdates` ve `CMAltitudeData.pressure × 10` (kPa → hPa) kullanıyor (paket kaynağı `FPPStreamHandlerPlus.swift`, sürüm 7.1.1 incelendi). Yani istenen Core Motion yolu, plugin'in kendi platform kanalıyla. Yeni Swift dosyası iskelet/TestFlight akışına dokunmayı gerektirirdi; risk ve fayda yok. |
| K2 | Okuma yalnız "Basıncı telefondan al" düğmesine basınca başlar; ilk geçerli örnek (300–1100 hPa) alınır, akış hemen kapatılır, 3 sn içinde gelmezse "okunamadı". Hava Durumu'nun otomatik doldurması barometreye dokunmaz. | Sahibi kuralı. |
| K3 | Okunan basınç Basınç kutusuna yazılır ve kullanıcı girdisi sayılır (sonraki otomatik hava doldurması üstüne yazmaz; "Konumdan canlı hava verisi al" yine yazar). | Telefonun ölçtüğü istasyon basıncıdır; servisten gelen dönüştürülmüş değerden daha doğrudur. |
| K4 | `NSMotionUsageDescription` metni barometreyi de anlatacak şekilde güncellenir (yeni anahtar yok). | `CMAltimeter` Hareket ve Fitness iznini kullanır; metin gerçek kullanımı söylemeli. |
| K5 | Ö6 yeni bir seçenek olarak mevcut Hız Doğrulama sayfasına eklenir: "Doğrulanacak değer" listesine `Sürüklenme eğrisi`. Ayrı sayfa yok. | Görev: mevcut doğrulama ekranı temel alınır. |
| K6 | Mach bantları: `< 1,2`, `1,2–1,5`, `1,5–2`, `> 2`. `> 2` bandı uydurulmaz (1,0 kalır). | Rapor Ö6 bantları. Mach 2 üstü namlu ağzına yakın uçuştur; o bölgenin etkisi hız doğrulamasının alanı (önce hız yakın/orta mesafede doğrulanır). İkisini birlikte uydurmak hız ile sürüklenmeyi birbirine karıştırır. |
| K7 | Ölçek katsayısı band içinde sabit, sınırlarda ±0,05 Mach doğrusal geçiş. Yeni eğri = mermi Cd'si × k(Mach). | Basamaksız eğri; `DragTable` doğrusal aradeğerlemeyle tam temsil edilir. |
| K8 | G1/G7 mühimmatta mermi Cd'si = standart Cd × SD / BC (SD kalibre ve ağırlıktan). Bu dönüşüm k = 1'de sonucu birebir korur. Özel eğrili mühimmatta eğrinin kendisi kullanılır. Çoklu BC'li mühimmat reddedilir. | Kayıt biçimi `DragCurve`: BC alanında SD, Cd 0–2. Çoklu BC hıza bağlı, Mach'a çevirmek havaya bağlı olur. |
| K9 | Aşırı uyum koruması: (a) en az 3 mesafe, hepsi sıfırdan uzak ve farklı; (b) serbest bant sayısı ≤ mesafe − 1; (c) yalnız etkisi ölçülebilen bantlar serbest (%10 değişim en az 0,05 mrad); (d) ölçek 1'e doğru Tikhonov cezası (gözlem σ 0,05 mrad, ölçek σ %5); (e) |k − 1| > %20 reddedilir; (f) uyum sonrası kalan fark 0,15 mrad'ı aşarsa uyarı. | McCoy 1999 bölüm 4–7 (Cd–Mach); Courtney & Courtney arXiv:0705.0389 (tek BC'nin hıza bağlı değişimi). Python ön denemesi: 3–5 mesafeyle bilinen bir eğri bozulmasında kalan fark < 0,02 mrad. |
| K10 | Eğri yalnız kişisel (kullanıcının girdiği) mühimmat kaydına, eski → yeni onayıyla yazılır; katalog kaydı değiştirilmez. | BC doğrulamasındaki kural. |
| K11 | Ö13 duyarlılık testleri `test/hesap_duyarlilik_test.dart`: uygulamanın çözücüsüyle hız +1 m/s, BC −%5, 1 m/s yan rüzgâr (ve Ö4 için basınç −10 hPa) etkisinin işareti ve büyüklüğü raporun 2.1/2.2 tablolarıyla karşılaştırılır; tolerans max(%15, 0,3 cm). | Rapor değerleri bağımsız betikle üretildi; depodaki `tools/formula_reference.py` ile yeniden hesaplandı, fark < %3. |
| K12 | GA saha protokolü `docs/ga-saha-dogrulama-protokolu.md`: iki kronografla BC, Hesaplayıcılar'daki mevcut iki-hız BC hesabıyla. | Rapor Ö13 (a). |
| V1 | Paralel dallar: `test/hesap-kapsami` (#174 birleşti) nitel özdeşlik test ediyor, sayısal tablo karşılaştırması yok; `denetim/formuller` bağımsız referans vektörleri; `denetim/hesap-dogrulama` dalı yok. Bu iş onları tekrar etmez. | Dallar incelendi. |
| V2 | Uygulama yazı karakteri `main`'de Inter (pubspec, 2026-10-12). Yeni widget'lar mevcut `MenzilType`'ı kullanır, font değiştirilmez; taslaklar görev kuralı gereği Oswald ile çizildi. | Çakışma çıkarmamak. |

## 1. Ö4 — Basıncı telefondan al

- Port `lib/tools/ports/pressure_sensor.dart`: `Future<PressureReading>`
  (`PressureRead(hpa)` | `PressureUnavailable()`).
- Adaptör `lib/tools/adapters/sensors_plus_pressure_sensor.dart`: dinlemeye
  yalnız `read()` çağrısında başlar; ilk geçerli örnek, 3 sn zaman aşımı, her
  hata → `PressureUnavailable`.
- `ToolsServices.pressure` (isteğe bağlı, varsayılan üretim adaptörü).
- Hava Durumu: "Konumdan canlı hava verisi al" düğmesinin altında
  `MenzilSecondaryButton` "Basıncı telefondan al" (anahtar
  `environment-phone-pressure`). Sonuç satırı mevcut bildirim kutusunda:
  "Basınç telefondan alındı: 912,4 hPa." / "Basınç okunamadı; elle girin."
- Basınç ⓘ metnine düğme cümlesi ve örnek eklenir.

## 2. Ö6 — Sürüklenme eğrisi, çok mesafe

Çekirdek `lib/core/drag_band_truing.dart`:

```
DragBandTruing.solve(base, observations, sectionalDensity) → DragBandResult
  bands: [MachBandScale(label, min, max, scale, fitted)]
  observations: [(rangeM, observedMrad, beforeMrad, afterMrad)]
  curve: List<DragSample>, sectionalDensity
```

Gauss–Newton (sayısal türev, %1 adım, en çok 8 yineleme); her değerlendirme
tüm mesafeler için tek çözüm. Sıfır her adayda yeniden çözülür (tüfekteki
gibi). Hatalar `DragTruingFailure` (Türkçe mesaj): az mesafe, sıfıra yakın
mesafe, aynı mesafe, çoklu BC, ölçülebilir bant yok, sınır dışı değişim,
ulaşılamayan mesafe.

Ekran: mod `Sürüklenme eğrisi` seçilince Gözlem bölümünde 3 satır
`Mesafe N | Düzeltme N`; "Mesafe ekle" düğmesi en çok 6 satıra kadar. Sonuç:
bant başına değişim (%; uydurulmayan bant "değişmedi"), mesafe başına önce /
sonra fark, "Sürüklenme eğrisini mühimmata kaydet".

## 3. Ö13

- Duyarlılık testi (K11), T1/T2/P1/P2 örnek silahları.
- Saha protokolü (K12).

## 4. Değişmeyecekler

Çözücü, sıfır mantığı, mevcut hız/BC doğrulaması, mevcut profil/mühimmat
biçimi, iOS iskelet betikleri (Info.plist metni dışında), TestFlight iş akışı.
Yeni girdi verilmedikçe hiçbir DOPE değeri değişmez.
