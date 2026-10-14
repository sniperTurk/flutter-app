# 03 · Gizlilik politikası / Privacy policy

> TASLAK — yayına almadan önce uygulama sahibi okuyup onaylamalıdır; bu bir
> hukuki görüş değildir. Metin `main @ 237c14d` (2026-10-14) kaynak koduna,
> Google'ın Maps SDK for iOS gizlilik bildirimine ve `ci/privacy-dump`
> dökümüne göre yazıldı (bkz. `02-gizlilik-etiketi.md`).
>
> **Türkçe metin uygulamanın içinde de gösterilir** (Araçlar > Gizlilik
> politikası). İşaretler arasındaki bölüm tek kaynaktır:
> `python3 tools/data_gen/generate_privacy_policy.py` bu bölümden
> `lib/features/guide/privacy_policy_content.dart` dosyasını üretir,
> `tools/test_privacy_policy_sync.py` ikisinin aynı olduğunu denetler. Metni
> değiştirirseniz üreteci çalıştırın. Bu bölümde kalın yazı, bağlantı biçimi
> veya `[[...]]` yer tutucusu kullanılmaz (uygulamada düz metin olarak
> görünür).
>
> Sahip için açık noktalar (politika metnine girmez):
> - Yayındaki web sayfası (`PRIVACY_POLICY_URL` depo değişkeni) bu metinle
>   değiştirilmeli; eski metinde Google Maps SDK, barometre, profil yedeği ve
>   cihazda saklanan enlem yok.
> - Geliştirici adı istenirse "İletişim" satırına eklenebilir.
> - 5.1.1(i), verinin paylaşıldığı üçüncü tarafların aynı veya eşit koruma
>   sağladığının teyit edilmesini istiyor. Bölüm 7 bunu servislerin kendi
>   koşullarına bağlıyor; hukuki uygunluğunu sahip değerlendirmelidir.

---

<!-- uygulama-metni:başla -->
# SNIPER TÜRK — Gizlilik Politikası

Son güncelleme: 14 Ekim 2026 · Uygulama sürümü 1.0.0 · İletişim: Sekerbirol76@gmail.com

## Kısaca

SNIPER TÜRK hesap istemez; reklam ve izleme (tracking) içermez. Uygulamanın
bize ait bir sunucusu yoktur; profilleriniz ve ayarlarınız bize gönderilmez.
Bazı özellikler çalışmak için üçüncü taraf servislerine istek gönderir ve
uygulamada Google Maps SDK bulunur. Bunların hepsi aşağıda tek tek yazılıdır.

## 1. Cihazınızda saklanan veriler

Tüfek, dürbün ve mühimmat profilleriniz, ayarlarınız, kendi eklediğiniz
katalog girdileri, Hava Durumu ve Pro sayfalarına girdiğiniz değerler,
kronograf serileri, atış günlüğü, paralaks işaretleri ve su terazisi
kalibrasyonu yalnızca cihazınızda saklanır.

Pro sayfasında "Konumdan al" veya "Konumdan hesapla" düğmesine basarsanız
Coriolis için yaklaşık enlem (iki ondalık, yaklaşık 1 km) ve ondan hesaplanan
yerel yerçekimi değeri de cihazda saklanır. "Basıncı telefondan al" ile gelen
irtifa da Hava Durumu değerleriyle birlikte cihazda kalır.

Bu veriler bize veya üçüncü taraflara gönderilmez. Uygulamayı silmek bu
verileri siler.

## 2. Konum

Konum izni yalnızca uygulama açıkken ve yalnızca sizin başlattığınız
işlemlerde kullanılır; arka planda konum kullanılmaz.

- Hava verisi: Hava Durumu sayfasında konumdan hava verisi aldığınızda veya
  Araçlar > Hava & Rüzgâr sayfasını açtığınızda konumunuz iki ondalığa
  (yaklaşık 1 km) yuvarlanarak Norveç Meteoroloji Enstitüsü'nün hava
  servisine (MET Norway, api.met.no) gönderilir. Uygulama bu konumu
  saklamaz; gelen hava değerleri ekranda gösterilir veya kutulara
  doldurulur.

- Basınç ve irtifa: "Basıncı telefondan al" düğmesi aynı dokunuşta
  konumdan irtifayı okur. İrtifa hiçbir yere gönderilmez.

- Coriolis ve yerel yerçekimi (Pro): enlem ve irtifa konumdan okunur, hesap
  cihazda yapılır (bkz. 1).

- Haritadan mesafe: harita açıldığında konumunuza getirilir. Seçtiğiniz
  nişancı ve hedef noktaları saklanmaz ve bize gönderilmez.

- Özel konum için mesafe (Hesaplayıcılar): hesap cihazda yapılır, konum
  gönderilmez.

Konum izni vermezseniz değerleri elle girebilirsiniz. İzni istediğiniz zaman
iPhone Ayarlar > Gizlilik ve Güvenlik > Konum Servisleri bölümünden geri
alabilirsiniz.

## 3. Harita, Google Maps SDK ve yer arama

- Haritadan mesafe ekranındaki uydu görüntüsü, uygulamanın sürümüne göre
  Esri (ArcGIS World Imagery, server.arcgisonline.com) veya Google Maps
  üzerinden indirilir. Görüntülediğiniz bölge bu sağlayıcıya istek olarak
  gider ve sağlayıcı IP adresinizi görebilir.

- Uygulama Google Maps SDK for iOS'u içerir. Google'ın bu SDK ile yayımladığı
  gizlilik bildirimine göre SDK; cihaz kimliğini (sizinle ilişkili; analiz ve
  uygulamanın çalışması için), diğer veri türlerini (sizinle ilişkili; analiz
  için) ve çökme verisi, performans verisi ile ürün etkileşimini (sizinle
  ilişkili değil; analiz için) toplar. Google Maps'i uygulamaya bağlayan
  Flutter eklentisinin bildirimi ayrıca kullanıcı kimliğini (sizinle
  ilişkili; analiz için) sayar. Google'ın beyanına göre bu veriler izleme
  (tracking) için kullanılmaz. Bu verilere biz erişmeyiz. Google Gizlilik
  Politikası: policies.google.com/privacy

- Yer arama kutusuna yazdığınız metin, yalnızca arama düğmesine bastığınızda
  OpenStreetMap Nominatim servisine (nominatim.openstreetmap.org)
  gönderilir; yazarken hiçbir şey gönderilmez.

## 4. Kamera ve fotoğraflar

Kamera yalnızca Sight Height ekranında ve Pro sayfasındaki "Kamerayla ölç"
(tüfek eğimi) ekranında kullanılır. Sight Height için galeriden yalnızca
sizin seçtiğiniz tek fotoğraf alınır (sistem fotoğraf seçicisi). Fotoğraflar
cihazın belleğinde işlenir; kaydedilmez, fotoğraf kitaplığınıza yazılmaz ve
cihazdan çıkmaz. Uygulama ses kaydetmez.

## 5. Hareket sensörleri, barometre ve pusula

Su Terazisi, Pro sayfasındaki eğim ölçümleri ve Pusula, cihaz sensörlerini
yalnızca ekranda göstermek ve hesap yapmak için okur. Barometre yalnızca Hava
Durumu sayfasında "Basıncı telefondan al" düğmesine bastığınızda bir kez
okunur ve değer basınç kutusuna yazılır. Sensör verisi cihazdan çıkmaz;
yalnızca su terazisi kalibrasyonu ve kutulara yazılan değerler cihazda
saklanır.

## 6. Dosyalar, yedek ve paylaşım

- Kendi sürüklenme eğrinizi (.drg/.csv) seçerseniz dosya cihazda okunur ve
  profilinizde saklanır.

- Profil sayfasındaki Yedekle, profillerinizi ve kişisel katalog
  girdilerinizi tek bir dosyaya yazar ve iOS paylaşım ekranına verir; dosya
  yalnızca sizin seçtiğiniz yere (ör. Dosyalar, iCloud Drive, Google Drive)
  gider. Geri yükle, sizin seçtiğiniz yedek dosyasını cihazda okur.

- DOPE kartı PDF'i, yalnızca paylaşım ekranında sizin seçtiğiniz hedefe
  gider.

## 7. Üçüncü taraflar

Yukarıda adı geçen servisler (MET Norway, Esri, Google, OpenStreetMap
Nominatim) yalnızca ilgili özelliği çalıştırmak için kullanılır ve kendi
gizlilik koşulları geçerlidir. Uygulamada reklam ağı ve bize ait bir analiz
aracı yoktur; veri satılmaz.

## 8. Çocuklar

Uygulama çocuklara yönelik değildir ve bilerek çocuklardan veri toplamaz.

## 9. Saklama, silme ve izinlerin geri alınması

Bizde sizinle ilişkilendirilmiş veri tutulmaz; silinecek bir hesap yoktur.
Cihazdaki verileri uygulamayı silerek kaldırabilirsiniz. Konum, kamera,
fotoğraf ve hareket izinlerini iPhone Ayarlar'dan istediğiniz zaman geri
alabilirsiniz. Google'ın topladığı veriler için Google'ın gizlilik araçları
geçerlidir.

## 10. Balistik uyarısı

Uygulama bir hesap yardımcısıdır; sonuçlar gerçek atışla doğrulanmalıdır.

## 11. Değişiklikler ve iletişim

Bu politika değişirse yeni tarih bu sayfada yazılır. Sorularınız için:
Sekerbirol76@gmail.com
<!-- uygulama-metni:bitti -->

---

# SNIPER TÜRK — Privacy Policy

Last updated: 14 October 2026 · App version 1.0.0 · Contact: Sekerbirol76@gmail.com

(The app's interface is in Turkish; the Turkish text above is the one shown
inside the app.)

## In short

SNIPER TÜRK needs no account and contains no advertising or tracking. The app
has no server of ours; your profiles and settings are not sent to us. Some
features contact third-party services to work, and the app includes the
Google Maps SDK. Each of these is listed below.

## 1. Data stored on your device

Your rifle, scope and ammunition profiles, settings, your own catalog
entries, the values you enter on the Hava Durumu (weather) and Pro pages,
chronograph strings, shot journal, parallax marks and level calibration are
stored only on your device.

If you press "Konumdan al" or "Konumdan hesapla" on the Pro page, an
approximate latitude (two decimals, about 1 km) for Coriolis and the local
gravity value derived from it are also stored on the device. The altitude
filled by "Basıncı telefondan al" stays on the device with the weather
values.

None of this is sent to us or to third parties. Deleting the app deletes it.

## 2. Location

Location is used only while the app is open and only for actions you start;
it is never used in the background.

- Weather: when you fetch weather from your location on the Hava Durumu page,
  or open Araçlar > Hava & Rüzgâr, your location, rounded to two decimals
  (about 1 km), is sent to the Norwegian Meteorological Institute's weather
  service (MET Norway, api.met.no). The app does not store this location;
  the returned values are shown or filled into the fields.
- Pressure and altitude: "Basıncı telefondan al" also reads the altitude from
  your location on the same tap. The altitude is not sent anywhere.
- Coriolis and local gravity (Pro): latitude and altitude are read from your
  location and the calculation runs on the device (see 1).
- Distance from map: the map opens centred on your location. The shooter and
  target points you pick are neither stored nor sent to us.
- Distance for a custom location (calculators): calculated on the device;
  your location is not sent.

Without location permission you can type the values in. You can revoke
permission at any time in iPhone Settings > Privacy & Security > Location
Services.

## 3. Map, Google Maps SDK and place search

- The satellite imagery on the distance-from-map screen is downloaded,
  depending on the app build, from Esri (ArcGIS World Imagery,
  server.arcgisonline.com) or Google Maps. The area you view is requested
  from that provider, which can see your IP address.
- The app includes the Google Maps SDK for iOS. According to the privacy
  manifest Google publishes with this SDK, it collects a device ID (linked to
  you; analytics and app functionality), other data types (linked to you;
  analytics), and crash data, performance data and product interaction (not
  linked to you; analytics). The manifest of the Flutter plugin that connects
  Google Maps to the app also lists a user ID (linked to you; analytics).
  Google declares that this data is not used for tracking. We have no access
  to it. Google Privacy Policy: https://policies.google.com/privacy
- Text typed in the place search box is sent to the OpenStreetMap Nominatim
  service (nominatim.openstreetmap.org) only when you press search, never
  while typing.

## 4. Camera and photos

The camera is used only on the Sight Height screen and on the "Kamerayla ölç"
(rifle incline) screen of the Pro page. For Sight Height the app receives
only the single photo you pick from your library (system photo picker).
Photos are processed in device memory, are not saved, are not written to
your library and do not leave the device. The app does not record audio.

## 5. Motion sensors, barometer and compass

The level, the incline and cant measurements on the Pro page and the compass
read device sensors only to display values and calculate. The barometer is
read once, only when you press "Basıncı telefondan al" on the Hava Durumu
page, and the value is written into the pressure field. Sensor data does not
leave the device; only the level calibration and the values written into
fields are stored on the device.

## 6. Files, backup and sharing

- If you pick your own drag curve file (.drg/.csv) it is read on the device
  and stored in your profile.
- Yedekle (backup) on the Profil page writes your profiles and personal
  catalog entries into one file and hands it to the iOS share sheet; the file
  goes only where you choose (e.g. Files, iCloud Drive, Google Drive). Geri
  yükle (restore) reads the backup file you pick, on the device.
- The DOPE card PDF goes only to the destination you choose in the share
  sheet.

## 7. Third parties

The services named above (MET Norway, Esri, Google, OpenStreetMap Nominatim)
are used only to run the related feature, and their own privacy terms apply.
There are no ad networks and no analytics tool of ours in the app; no data
is sold.

## 8. Children

The app is not directed at children and does not knowingly collect data from
children.

## 9. Retention, deletion and withdrawing permissions

We hold no data linked to you, so there is no account to delete. Remove
on-device data by deleting the app. Location, camera, photo and motion
permissions can be withdrawn at any time in iPhone Settings. Google's
privacy tools apply to data collected by Google.

## 10. Ballistics notice

The app is a calculation aid; always confirm results with live fire.

## 11. Changes and contact

If this policy changes, the new date is shown on this page.
Questions: Sekerbirol76@gmail.com
