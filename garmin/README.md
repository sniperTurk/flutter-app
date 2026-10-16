# Garmin Connect IQ saat uygulaması

Telefondaki Atış çözümünü Garmin saatte gösteren Connect IQ "watch-app"
(Monkey C). Balistik hesap yapmaz; yalnızca telefonun gönderdiğini gösterir.
Saatten mesafe değiştirme isteği gönderir (yukarı/aşağı tuşları, Başlat).

## Derleme ve simülatör durumu (2026-10-12)

Sahibin Windows bilgisayarında Connect IQ SDK 9.2.0 ile derlendi ve
simülatörde fenix7'de çalıştırıldı (`tools/build-windows.ps1 -Device fenix7`,
ardından `monkeydo build\sniperturk.prg fenix7`):

- `main` (af936fd): derleme başarılı; simülatörün Phone App Message
  özelliğiyle gönderilen örnek mesaj (aşağıda 6. madde) ekranda doğru
  göründü, "Veri eski" uyarısı kalktı.
- `feat/garmin-phone`: derleme başarılı; iPhone köprüsünün gönderdiği biçim
  (`"ok":1`) kabul edildi, ekran yeni değerlerle güncellendi.

Denenmedi: gerçek saat; yukarı/aşağı tuşlarıyla telefona giden mesafe
isteği (simülatörde karşı tarafta telefon yok); manifest'teki diğer cihazlar.

CI'da Connect IQ SDK yok; repo'daki otomatik kontrol yalnızca
`tools/test_garmin_project_contract.py` (manifest izinleri, uygulama kimliği
biçimi, mesaj şeması alanları, yazı kuralları). Monkey C sözdizimini
doğrulamaz; saat kodu değişince Windows'ta yeniden derlenmelidir.

## Atış terazisi ve açı (2026-10-16, derlenmedi)

Saat tüfeğin rayına bir aparatla takılınca atış terazisi olur
(`source/Level.mc`, `source/LevelView.mc`). Ana ekranda **Aşağı** tuşu
açar; telefon çözümü olmadan da çalışır.

- Takma şekli (Aşağı > Takma şekli): **Dik** (varsayılan; ekran atıcıya
  bakar, saat 12 yukarı) veya **Ekran yukarı** (saat 12 namluya doğru).
  Takma şekli değişince sıfır farkı silinir; yeniden Sıfırla gerekir.
- Yatıklık (0,1°, çizgi; |yatıklık| ≤ 0,5° "düz") ve atış açısı
  (+ yukarı / − aşağı, 0,1°) ivmeölçerden `atan2` ile hesaplanır; ikisi
  birbirine karışmaz (`tools/test_garmin_level_math.py`, ±60°).
- Düz olunca bir kez kısa titreşim (saatin titreşim ayarı açıksa) ve ses
  açıksa kısa tuş sesi; düzden 0,8°'den fazla çıkıp yeniden düzelince
  yine bir kez.
- **Sıfırla** (Aşağı > Sıfırla > onay): tüfek düz ve yatayken o anki
  yatıklık ve açı 0 olur, saatte saklanır (aparat toleransı).
- **Başlat**: "Açıyı gönder"; telefona tek mesaj
  `{"type":"setAngle","value":<derece, 1 ondalık>}`. Telefon ±60° dışını
  ve sayı olmayanı yok sayar; geçerli açı Pro Ayarlar Açı'ya yazılır, yeniden
  hesaplanır ve yeni çözüm saate döner (ana ekranda "Açı +12.5°").
- Manifest'e `Sensor` izni eklendi (Toybox.Sensor bu izni ister).
- Mesaj şeması v1 kaldı: `angle` isteğe bağlı yeni alan; eski saat
  uygulamaları onu okumaz.

## Sahibinin yapması gerekenler

1. Garmin Developer hesabı (https://developer.garmin.com, 18 yaş şartı) —
   yalnızca Connect IQ Store'a yüklemek için gerekir.
2. SDK Manager'ı indir, Connect IQ Developer Agreement'ı oku ve kabul et,
   en güncel SDK'yı ve hedef cihazları (manifest'teki ürün listesi) indir.
3. Visual Studio Code + Monkey C eklentisi (Garmin'in resmi eklentisi).
4. Geliştirici anahtarı üret (Monkey C eklentisi "Generate a Developer Key"
   veya openssl ile RSA 4096 DER). **Anahtarı repo'ya koyma.**
5. Derle ve simülatörde çalıştır:
   `monkeyc -f garmin/monkey.jungle -d fenix7 -o build/sniperturk.prg -y <anahtar.der>`
   ardından `connectiq` simülatörü ve `monkeydo build/sniperturk.prg fenix7`.
6. Simülatörde telefon mesajı denemesi: simülatörün telefon mesajı
   özelliğiyle şu sözlüğü gönder (şema v1):
   `{"v":1,"ok":true,"profile":"Tikka T3x .308","at":<ms>,"range":600,"rangeUnit":"m","rangeStep":10,"up":47,"right":6,"upAngle":4.7,"rightAngle":0.6,"unit":"MRAD","click":0.1,"windSpeed":3.0,"windUnit":"m/s","windClock":3,"angle":12.5}`
7. Manifest'teki ürün kimliklerini SDK'daki cihaz listesiyle karşılaştır;
   yuvarlak ekranlı hedef cihazlar seçildi, liste örnektir.
8. Mağaza: Connect IQ Store'a yükleme sahibinin Garmin hesabıyla yapılır.

## Telefon tarafı (iPhone köprüsü, isteğe bağlı)

iPhone'dan Garmin'e veri Garmin'in Connect IQ Mobile SDK'sı ile gider
(Swift paketi https://github.com/garmin/connectiq-companion-app-sdk-ios,
sabit commit; SDK'yı indirmek Garmin lisansını kabul etmektir).

- `ios_runner/SniperTurkGarminBridge.{h,m}`: `sniper_turk/garmin` kanalı.
  `publish(map)` bağlı saatlere gönderir, `selectDevice` Garmin Connect'i
  açar, saatten gelen `setRange` Dart'a `fromWatch` olarak iletilir.
- Dart: `WatchBridge` çözümü hem Apple Watch hem Garmin kanalına yollar
  (`MultiWatchTransport`). Araçlar'daki "Garmin saati" satırı yalnızca
  köprülü derlemede görünür; saati Garmin Connect'te seçtirir.
- İskelete yalnızca `tools/configure_ios_garmin_bridge.py` + `.rb` ile,
  elle tetiklenen `.github/workflows/garmin-sim.yml` içinde eklenir
  (Info.plist: `sniperturk-ciq` adresi, `gcm-ciq` sorgusu, Bluetooth
  açıklaması; `-ObjC`). TestFlight derlemesi bu köprüyü içermez.
- Telefonda Garmin Connect uygulaması kurulu olmalı; saat bir kez Garmin
  Connect üzerinden seçilir, liste telefonda saklanır.
- Connect IQ SDK'sı tembel başlar: Bluetooth izni yalnızca saklı bir saat
  listesi varsa, "Garmin saati" satırına dokunulunca veya Garmin Connect
  uygulamayı geri açınca sorulur. Garmin kullanmayan hiç sorulmaz.
- Garmin Connect dönüşü uygulama kapalıyken de (soğuk açılış, UIScene veya
  klasik iskelet) işlenir. Seçili saat sayısı `sniper_turk/garmin/devices`
  olay kanalıyla Araçlar'daki satıra hemen yansır. Yalnızca "Garmin saati"
  satırına dokunduktan sonraki 15 dakika içinde gelen dönüş kabul edilir;
  başka bir uygulamanın açtığı `sniperturk-ciq://` adresi saat listesini
  değiştirmez.
- `publish` YES: çözüm en az bir bağlı saate gönderilmek üzere verildi
  (ulaştı demek değil). Mesaj geçicidir (`isTransient`), saatte birikmez;
  `ok` saate 1/0 sayı olarak gider.
