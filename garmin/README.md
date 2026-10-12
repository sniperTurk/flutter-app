# Garmin Connect IQ prototipi (DERLENMEDİ)

Telefondaki Atış çözümünü Garmin saatte gösteren Connect IQ "watch-app"
(Monkey C). Balistik hesap yapmaz; yalnızca telefonun gönderdiğini gösterir.
Saatten mesafe değiştirme isteği gönderir (yukarı/aşağı tuşları, Başlat).

## Neden derlenmedi

Connect IQ SDK yalnızca SDK Manager ile indirilir ve resmi sayfa şöyle der:
"By downloading any of the following SDKs, you accept our license agreement."
(https://developer.garmin.com/connect-iq/sdk/). İndirmek lisansı kabul etmek
demektir; bu oturumda lisans kabul edilmedi, Garmin hesabı açılmadı. Bu
yüzden kod hiç derlenmedi ve simülatörde çalıştırılmadı. Derleme hataları
olabilir; ilk derlemede düzeltilmesi beklenir.

Repo'daki tek otomatik kontrol `tools/test_garmin_project_contract.py`:
manifest izinleri, uygulama kimliği biçimi, mesaj şeması alanları ve yazı
kuralları (kalın yazı tipi yok). Monkey C sözdizimini doğrulamaz.

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
   `{"v":1,"ok":true,"profile":"Tikka T3x .308","at":<ms>,"range":600,"rangeUnit":"m","rangeStep":10,"up":47,"right":6,"upAngle":4.7,"rightAngle":0.6,"unit":"MRAD","click":0.1,"windSpeed":3.0,"windUnit":"m/s","windClock":3}`
7. Manifest'teki ürün kimliklerini SDK'daki cihaz listesiyle karşılaştır;
   yuvarlak ekranlı hedef cihazlar seçildi, liste örnektir.
8. Mağaza: Connect IQ Store'a yükleme sahibinin Garmin hesabıyla yapılır.

## Telefon tarafı (henüz yazılmadı)

iPhone'dan Garmin'e veri, Garmin'in iOS "Connect IQ Mobile SDK"sı ile gider
(https://developer.garmin.com/connect-iq/core-topics/mobile-sdk-for-ios/ —
sayfa metni bu oturumda alınamadı, adımlar SDK belgesinden doğrulanmalı):

- Telefonda Garmin Connect Mobile uygulaması kurulu olmalı.
- SDK bir iOS framework'üdür; Runner'a eklenir (bu, iOS imzalamasını ve
  TestFlight denetimlerini etkiler; ayrı PR).
- Cihaz seçimi Garmin Connect Mobile'a yönlendirilerek yapılır (URL şeması;
  Info.plist'e sorgu şeması eklenir).
- Uygulama, `manifest.xml`'deki kimlikle (`4dde1aef12b64a15b5a6209c2c5944b0`)
  bulunur ve aynı şema v1 sözlüğü gönderilir.
- Dart tarafı değişmez: `feat/apple-watch` dalındaki `WatchBridge` aynı
  `sniper_turk/watch` kanalına yazar; iOS köprüsü mesajı hem WatchConnectivity'ye
  hem Connect IQ'ya iletecek şekilde genişletilir.
