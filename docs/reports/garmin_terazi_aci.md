# Garmin saati: atış terazisi ve açı

Dal: `feat/garmin-terazi-aci` · Taslak PR (birleştirmeyi ana oturum yapar).

## Ne

Sahibin isteği (2026-10-16 01:06–01:25, İstanbul): "Sadece klik değil açı,
rüzgâr yönü gibi özellikleri de olması lazım" ve "Açıyı. Saat tüfeğe
Picatinny ayağa bir aparat ile takılıyor; bu şekilde atış terazisi ve açıyı
hesaplıyor." Rüzgâr hızı ve yönü saate zaten gidiyordu; eksik olan açıydı.

- **Saat (Monkey C):** yeni "Terazi" ekranı. Ana ekranda **Aşağı** tuşu
  açar. Yatıklığı (0,1°, bir terazi çizgisi; |yatıklık| ≤ 0,5° iken "düz")
  ve atış açısını (+ yukarı / − aşağı, 0,1°) gösterir. Düz olunca bir kez
  kısa titreşim verir. **Sıfırla** ile aparat payı sıfırlanır. **Başlat**
  ("Açıyı gönder") açıyı telefona yollar. Ana çözüm ekranında artık
  "Açı +12.5°" satırı da var.
- **Telefon (Dart):** saatten gelen `setAngle` geçerliyse Pro Ayarlar'daki
  Açı (Tüfek eğimi) olur, hesap yenilenir, yeni çözüm saate döner. Saate
  giden mesaja `angle` alanı eklendi. Garmin satırının ⓘ metnine bir cümle
  eklendi.
- **Apple Watch:** değişiklik yok.

## Nasıl

**Saat**
- `garmin/source/Level.mc` (yeni, saf hesap): ivmeölçer okuması (milli-g;
  saat dururken yukarıyı gösterir; x saat 3, y saat 12, z ekrandan dışarı)
  yerçekimi yönüne çevrilir, tüfeğin eksenlerinde (sağ, yukarı, geri)
  yazılır:
  - yatıklık = atan2(sağ, −yukarı)
  - açı = atan2(geri, √(sağ² + yukarı²))

  Böylece önce eğim, sonra namlu çevresinde yatıklık ayrı ayrı çıkar;
  biri ötekine karışmaz (±60° içinde tam olarak).
  Takma şekli: **Dik** (varsayılan; ekran atıcıya bakar, saat 12 yukarı)
  veya **Ekran yukarı** (saat 12 namluya doğru). Saklama: `levelMount`,
  `levelOffsets` (uygulama deposu).
- `garmin/source/LevelView.mc` (yeni): 0,1 sn'de bir `Sensor.getInfo().accel`
  okunur. Bazı saatler ivmeölçeri ancak dinleyici kaydedilince açtığı için
  `Sensor.registerSensorDataListener` de kaydedilir; `getInfo` boş dönerse
  dinleyicinin son örneği kullanılır. Değerler telefondaki Su Terazisi'yle
  aynı biçimde birinci derece alçak geçiren süzgeçten geçer
  (k = 1 − e^(−0,1/0,25) ≈ 0,33).
  - Titreşim: düz olunca bir kez `Attention.vibrate` (50 %, 150 ms); yalnız
    `Attention has :vibrate` ve saatin titreşim ayarı açıksa. Saatin ses
    ayarı açıksa bir kısa tuş sesi (`TONE_KEY`) de çalar.
  - Sıfırla: Aşağı > Sıfırla > "Tüfek düz ve yatay mı?" onayı; o anki
    yatıklık ve açı 0 olur.
  - Açıyı gönder: `Communications.transmit({"type" => "setAngle",
    "value" => <derece, 1 ondalık>})`; tek mesaj, sürekli akış yok. Durum
    satırı: "Gönderiliyor", "Açı gönderildi", "Telefona ulaşılamadı".
- `Solution.mc`: isteğe bağlı `angle` okunur. `MainView.mc`: rüzgâr
  satırının altında "Açı …" satırı; Aşağı tuşu Terazi'yi açar.
  `Format.mc`: `deg`, `signedDeg`.
- `manifest.xml`: `<iq:uses-permission id="Sensor"/>` eklendi. Garmin'in
  Connect IQ API belgesinde Toybox.Sensor modülü "Requires Permission:
  Sensor" diyor. Ürün listesi değişmedi.

**Telefon**
- `lib/services/watch/watch_bridge.dart`: `angleRequests`; yalnız
  `type == "setAngle"`, sayı, sonlu ve |değer| ≤ 60° olanlar geçer, 0,1°'ye
  yuvarlanır.
- `lib/features/ballistics/ballistics_screen.dart`: `_onWatchAngle`, elle
  girilen açı gibi `_setAngles(incline: …)` çağırır (aynı durum, aynı
  kayıt, aynı hesap; yeni hesap kodu yok). Saate giden çözüme
  `angle: _inclineDeg` eklendi.
- `lib/services/watch/watch_solution.dart`: isteğe bağlı `angle` (1
  ondalık, "−0.0" olmaz). `watchSchemaVersion` 1'de kaldı: alan isteğe
  bağlı; eski Garmin uygulaması ve Apple Watch bilmedikleri alanı okumaz.
- `lib/features/ballistics/pro_section_info.dart` (Garmin ⓘ), eklenen
  cümle: "Raya bir aparatla takılan saat atış terazisi olur (düz olunca
  titreşimle uyarır) ve atış açısını ölçer; saatte "Açıyı gönder" bu açıyı
  hesaba koyar." Metnin kalanı aynı.

## Neden

Saat tüfeğe takılıyken yatıklık ve açı, atıcı nişandan ayrılmadan
okunur. Açı telefonda elle girilen Açı ile aynı yoldan girdiği için hesap
tek yerde kalır; saat yine hesap yapmaz, yalnızca ölçer ve gösterir.

## Uç durumlar

- Sayı olmayan, NaN, sonsuz, |açı| > 60° → telefonda yok sayılır. Saat de
  60°'nin dışını göndermez ("Açı 60° dışında").
- Sensör verisi yoksa → "Sensör bekleniyor"; Sıfırla ve gönder "Sensör
  verisi yok" der.
- Sınırda titreyen ölçüm sürekli titreşim yapmasın diye titreşim, yatıklık
  0,8°'yi geçip yeniden 0,5° içine girince tekrar verilir ("düz" yazısı
  yine 0,5°'de değişir).
- Takma şekli değişince eski sıfır farkı silinir; ekranda "Takma değişti:
  Sıfırla" ve Sıfırla yapılana kadar "Önce Sıfırla" yazar.
- Atış ekranı açık değilken açı gelirse Açı yine kaydedilir; saat, mesafe
  isteğindeki gibi "Çözüm yok" görür. Hedef açılınca yeni çözüm gider.
- Saatte ondalık ayırıcı nokta (12.5°), mevcut saat ekranıyla (4.7 MRAD)
  aynı.
- Tüfek dike yakın tutulursa (|açı| 90°'ye yakın) yatıklık tanımsızlaşır;
  zaten ±60° dışı gönderilmez.

## Bilerek yapılmayan

- Connect IQ SDK indirilmedi, `garmin-sim.yml` çalıştırılmadı (Garmin
  lisansı, sahibin adımı). **Saat kodu derlenmedi, simülatörde ve gerçek
  saatte denenmedi.**
- Sürekli açı akışı yok; yalnız "Açıyı gönder".
- Yatıklık telefona gönderilmiyor (istenmedi); yalnız saatte gösteriliyor.
- Apple Watch, iOS köprüsü (`SniperTurkGarminBridge.m` her mesajı zaten
  `fromWatch` ile iletiyor) ve TestFlight değişmedi.
- Başka bir uygulamanın tasarımı, metni ya da verisi kullanılmadı. API
  bilgisi yalnız Garmin'in Connect IQ API belgelerinden (Toybox.Sensor,
  Sensor.Info, AccelerometerData, Attention, VibeProfile, System.DeviceSettings,
  Math; 2026-10-16'da okundu).

## Testler

- Python `tools/test_garmin_level_math.py` (yeni): Level.mc formülünün
  Python eşi. Yerçekimi (0,−1,0) → 0/0; 10° yatık → 10/~0; namlu 15° yukarı
  → ~0/15; birlikte 10°/15° → ikisi de 0,1° içinde; ±60° ızgarada (5°
  adım, iki takma şekli) yatıklık ve açı birbirinden bağımsız; ölçek
  (980–1020 milli-g) sonucu değiştirmez; süzgeç katsayısı telefon
  formülüyle aynı; Monkey C satırları Python eşiyle aynı; mesaj biçimi
  `{"type" => "setAngle", "value" => v}`; tek titreşim çağrısı, ayara bağlı.
- Python `tools/test_garmin_project_contract.py`: izinler artık
  `["Communications", "Sensor"]` (izin eklendiği için beklenti güncellendi);
  şema alanlarına `angle`; ürün listesi değişmedi testi; Terazi ana
  ekrandan açılıyor ve `setAngle` gönderiyor.
- Dart `test/watch_bridge_test.dart`: `angle` 1 ondalık, "−0.0" yok; açı
  verilmezse alan yok; çözüm yoksa açı yok; açı değişince içerik yeni;
  `angleRequests`: 12.5, −60, −3, 12.54→12.5 geçer; NaN, sonsuz, 90, 60.01,
  metin, null, true geçmez; açı mesafe sanılmaz. Eski testler aynen duruyor.
- Dart `test/watch_screen_wiring_test.dart`: sahte köprüyle setAngle 12.5 →
  yeni çözüm `angle` 12.5 ile gider, `upAngle` değişir; NaN/90/−90/metin/null
  hiçbir şeyi değiştirmez; sonraki mesafe isteğinin çözümü de 12.5 taşır.
  setRange testi değişmedi.
- Dart `test/garmin_pro_ayarlar_test.dart`: ⓘ metni beklentisine yeni
  cümle eklendi.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (399 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` → 878 test OK.
  Bu ortamda Flutter SDK yok; Dart testleri CI'da koşar.

## CI

CI_SONUCLARI_BURAYA

## Sahibin yapacakları

1. Windows'ta SDK ile derle: `tools/build-windows.ps1 -Device fenix7`,
   ardından `monkeydo build\sniperturk.prg fenix7`. Derleme hatası olursa
   bu dala yeni görev.
2. Simülatörde ana ekranda Aşağı → Terazi; simülatörün ivmeölçer ayarıyla
   yatıklık/açı değişiyor mu, düz olunca titreşim bir kez mi bak.
3. Saati aparatla raya **dik** tak (ekran sana bakar, saat 12 yukarı).
   Tüfeği düz ve yatay koy, Aşağı > Sıfırla > onay.
4. Gerçek cihazda: tüfeği sağa yatırınca "sağ", sola "sol" yazıyor mu;
   namlu yukarıda açı + mı; Başlat ile açı telefonda Pro Ayarlar Açı'ya
   geliyor ve saatteki çözüm yenileniyor mu. Yönlerden biri ters çıkarsa
   (Garmin belgesi eksen yönlerini yazmıyor) bildir; tek satırlık düzeltme.
5. Garmin köprülü iOS derlemesi `garmin-sim.yml` ile (sahibin adımı).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01LEyE2M2ZJG8DKtUwkAAzmo
