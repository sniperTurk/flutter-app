# 03 · Gizlilik politikası taslağı / Privacy policy draft

> TASLAK — yayına almadan önce uygulama sahibi okuyup onaylamalıdır; bu bir
> hukuki görüş değildir. Metin `main @ 835b956` kaynak koduna ve
> `ci/privacy-dump` gizlilik bildirimi dökümüne göre yazıldı
> (bkz. `02-gizlilik-etiketi.md`). `release/PRIVACY_POLICY_DRAFT.md`
> (2026-10-04) ve yayındaki sayfa bu metinle değiştirilmelidir; eski metinde
> Google Maps ve cihazda saklanan enlem eksik.
>
> `[[...]]` ile işaretli yerler sahip tarafından doldurulur. İletişim adresi
> eski taslaktaki adresle aynı bırakıldı.

---

# SNIPER TÜRK — Gizlilik Politikası

Son güncelleme: [[TARİH]] · Uygulama sürümü 1.0.0
Geliştirici: [[SAHİP ADI]] · İletişim: Sekerbirol76@gmail.com

## Kısaca

SNIPER TÜRK hesap istemez; reklam ve izleme (tracking) içermez. Sizi
tanımlayan bir veri bize gönderilmez. Bize yalnızca, siz "Gönder"e
bastığınızda, listede bulamadığınız mühimmat için yazdığınız metin gelir
(bölüm 6). Bazı araçlar çalışmak için üçüncü taraf servislerine istek
gönderir; bunlar aşağıda tek tek yazılıdır.

## 1. Cihazınızda saklanan veriler

Tüfek, dürbün ve mühimmat profilleriniz, ayarlarınız, kendi eklediğiniz
katalog girdileri, su terazisi kalibrasyonu ve atış ayarlarınız yalnızca
cihazınızda saklanır. Atış ayarlarına, sizin "konumdan doldur" seçtiğinizde,
Coriolis hesabı için **yaklaşık enlem** (iki ondalık, yaklaşık 1 km) ve ondan
hesaplanan yerel yerçekimi değeri de dahildir. Bu veriler bize veya üçüncü
taraflara gönderilmez. Uygulamayı silmek bu verileri siler.

## 2. Konum

Konum izni yalnızca uygulama açıkken ve yalnızca sizin başlattığınız
işlemlerde kullanılır; arka planda konum kullanılmaz:

- **Hava Durumu / Hava & Rüzgâr:** Konumunuz iki ondalığa (yaklaşık 1 km)
  yuvarlanarak Norveç Meteoroloji Enstitüsü'nün hava servisine (MET Norway,
  api.met.no) gönderilir ve o noktanın hava verisi alınır. Uygulama bu konumu
  saklamaz; gelen hava değerleri (sıcaklık, basınç, nem, rüzgâr) hesapta
  kullanılmak üzere ekrandaki alanlara doldurulur.
- **Coriolis ve yerel yerçekimi:** Konumdan enlem ve irtifa okunur, hesap
  cihazda yapılır. Yaklaşık enlem ve yerçekimi değeri cihazda saklanır
  (bkz. 1).
- **Haritadan mesafe:** Harita, açıldığında konumunuza getirilir. Seçtiğiniz
  nişancı ve hedef noktaları saklanmaz ve gönderilmez.
- **Özel konum için mesafe:** Hesap cihazda yapılır, konum gönderilmez.

Konum izni vermezseniz değerleri elle girebilirsiniz; diğer araçlar çalışır.
İzni istediğiniz zaman iPhone Ayarlar > Gizlilik ve Güvenlik > Konum
Servisleri bölümünden geri alabilirsiniz.

## 3. Harita ve yer arama (yalnızca "Haritadan mesafe")

- Harita görüntüsü, uygulamanın sürümüne göre **Esri** (ArcGIS World Imagery,
  server.arcgisonline.com) veya **Google Maps** üzerinden indirilir.
  Görüntülediğiniz bölge bu sağlayıcılara istek olarak gider ve sağlayıcı IP
  adresinizi görebilir.
- Google Maps kullanılan sürümlerde Google Maps SDK, Google'ın kendi
  beyanına göre cihaz tanımlayıcısı, kullanım (ürün etkileşimi), performans
  ve çökme verisi ile diğer bazı verileri **analiz ve hizmetin çalışması**
  amacıyla toplayabilir. Bu veriler reklam veya izleme için kullanılmaz
  (Google'ın beyanı). Bu verilere biz erişmeyiz. Google Gizlilik Politikası:
  https://policies.google.com/privacy
- "Yerleri ara" kutusuna yazdığınız metin, yalnızca arama düğmesine
  bastığınızda OpenStreetMap Nominatim servisine (nominatim.openstreetmap.org)
  gönderilir; yazarken hiçbir şey gönderilmez.

## 4. Kamera ve fotoğraflar

Kamera yalnızca **Sight Height** (dürbün yüksekliği) ve **tüfek eğimi
ölçümü** ekranlarında kullanılır. Galeriden yalnızca sizin seçtiğiniz tek
fotoğraf alınır (sistem fotoğraf seçicisi). Fotoğraflar cihazın belleğinde
işlenir; kaydedilmez, fotoğraf kitaplığınıza yazılmaz ve cihazdan çıkmaz.
Uygulama ses kaydetmez.

## 5. Hareket sensörü ve pusula

Su terazisi, atış açısı, dürbün eğimi ve pusula araçları cihaz sensörlerini
yalnızca ekranda göstermek ve hesap yapmak için okur. Sensör verisi
gönderilmez; yalnızca su terazisi kalibrasyon değeri cihazda saklanır.

## 6. Dosyalar ve paylaşım

Kendi sürüklenme eğrisi dosyanızı (.drg/.csv) seçerseniz dosya cihazda
okunur ve profilinizde saklanır. DOPE kartı PDF'i, yalnızca siz paylaş
sayfasında bir hedef seçerseniz o hedefe gider.

**"Aradığın mühimmat listede yok mu?"** (Profil → Mühimmat): Bu pencereye
yazdığınız metin (marka, model, ağırlık), tüfek türü (PCP / ateşli),
Tüfek bölümündeki kalibre ve uygulama sürümü, yalnızca siz **Gönder**'e
bastığınızda bize ait Cloudflare servisine
(sniper-turk-urun-kutusu.sekerbirol76.workers.dev) gönderilir ve ürün
kataloğunu geliştirmek için saklanır. Konum, profil bilgisi, cihaz kimliği
veya kişisel veri gönderilmez. Gönder'e basmazsanız hiçbir şey gönderilmez;
gönderim profilinizi değiştirmez. Metne kişisel bilgi yazmayın.

## 7. Üçüncü taraflar

Yukarıda adı geçen servisler (MET Norway, Esri, Google, OpenStreetMap
Nominatim; mühimmat bildirimi için Cloudflare) yalnızca ilgili özelliği
çalıştırmak için kullanılır ve kendi gizlilik koşulları geçerlidir. Uygulamada reklam ağı, analiz aracı veya veri
satışı yoktur. [[SAHİP ONAYI: Apple 5.1.1(i), verinin paylaşıldığı üçüncü
tarafların bu politikadakiyle aynı veya eşit koruma sağladığının teyit
edilmesini istiyor. Bu cümlenin hukuki uygunluğunu sahip değerlendirmelidir.]]

## 8. Çocuklar

Uygulama çocuklara yönelik değildir ve bilerek çocuklardan veri toplamaz.

## 9. Saklama, silme ve onayın geri alınması

Bizde sizinle ilişkilendirilmiş veri tutulmaz; silinecek bir hesap yoktur.
Cihazdaki verileri uygulamayı silerek kaldırabilirsiniz. Konum, kamera ve
fotoğraf izinlerini iPhone Ayarlar'dan istediğiniz zaman geri alabilirsiniz.
Google'ın topladığı veriler için Google'ın gizlilik araçları geçerlidir.

## 10. Balistik uyarısı

Uygulama bir hesap yardımcısıdır; sonuçlar gerçek atışla doğrulanmalıdır.

## 11. Değişiklikler ve iletişim

Bu politika değişirse güncel tarih bu sayfada yazılır.
Sorularınız için: Sekerbirol76@gmail.com

---

# SNIPER TÜRK — Privacy Policy

Last updated: [[DATE]] · App version 1.0.0
Developer: [[OWNER NAME]] · Contact: Sekerbirol76@gmail.com

## In short

SNIPER TÜRK needs no account and contains no advertising or tracking. It
sends no data that identifies you to us. The only thing we receive is the
text you write about ammunition you did not find in the lists, when you tap
"Gönder" (section 6). Some tools contact third-party services to work; each
one is listed below.

## 1. Data stored on your device

Your rifle, scope and ammunition profiles, settings, your own catalog
entries, level calibration and shot settings are stored only on your device.
When you choose "fill from location", shot settings also include an
**approximate latitude** (two decimals, about 1 km) for Coriolis and the
local gravity value derived from it. None of this is sent to us or to third
parties. Deleting the app deletes it.

## 2. Location

Location is used only while the app is open and only for actions you start;
it is never used in the background:

- **Weather / Weather & Wind:** your location, rounded to two decimals (about
  1 km), is sent to the Norwegian Meteorological Institute (MET Norway,
  api.met.no) to fetch the weather for that point. The app does not store
  this location; the returned weather values (temperature, pressure,
  humidity, wind) are filled into the on-screen fields for the calculation.
- **Coriolis and local gravity:** latitude and altitude are read from your
  location and the calculation runs on the device. The approximate latitude
  and gravity value are stored on the device (see 1).
- **Distance from map:** the map opens centred on your location. The shooter
  and target points you pick are neither stored nor sent.
- **Distance for a custom location:** calculated on the device; your location
  is not sent.

Without location permission you can type the values in; other tools keep
working. You can revoke permission at any time in iPhone Settings > Privacy
& Security > Location Services.

## 3. Map and place search ("Distance from map" only)

- Map imagery is downloaded, depending on the app build, from **Esri**
  (ArcGIS World Imagery, server.arcgisonline.com) or **Google Maps**. The area
  you view is requested from that provider, which can see your IP address.
- In builds that use Google Maps, the Google Maps SDK may, according to
  Google's own declaration, collect a device identifier, product interaction,
  performance and crash data and certain other data for **analytics and
  service operation**. Google declares that this data is not used for
  advertising or tracking. We do not have access to it. Google Privacy
  Policy: https://policies.google.com/privacy
- Text typed in the place search box is sent to the OpenStreetMap Nominatim
  service (nominatim.openstreetmap.org) only when you press search, never while
  typing.

## 4. Camera and photos

The camera is used only on the **Sight Height** and **rifle incline
measurement** screens. From your library the app receives only the single
photo you pick (system photo picker). Photos are processed in device memory,
are not saved, are not written to your library and do not leave the device.
The app does not record audio.

## 5. Motion sensors and compass

Level, shot angle, scope cant and compass read device sensors only to display
values and calculate. Sensor data is not sent; only the level calibration
value is stored on the device.

## 6. Files and sharing

If you pick your own drag curve file (.drg/.csv) it is read on the device and
stored in your profile. The DOPE card PDF goes only to the destination you
choose in the share sheet.

**"Aradığın mühimmat listede yok mu?"** (Profile → Ammunition): the text you
type in this window (brand, model, weight), the gun type (PCP / firearm), the
caliber shown in the Rifle section and the app version are sent to our
Cloudflare service (sniper-turk-urun-kutusu.sekerbirol76.workers.dev) only
when you tap **Gönder** (Send), and stored to improve the product catalog. No
location, profile data, device identifier or personal data is sent. Nothing
is sent unless you tap Send, and sending does not change your profile. Do not
write personal information in the text.

## 7. Third parties

The services named above (MET Norway, Esri, Google, OpenStreetMap Nominatim;
Cloudflare for the ammunition report) are used only to run the related
feature, and their own privacy terms apply.
There are no ad networks, analytics tools or data sales in the app.
[[OWNER APPROVAL: Apple guideline 5.1.1(i) asks the policy to confirm that
third parties with access to user data provide the same or equal protection.
The owner should review the legal wording of this sentence.]]

## 8. Children

The app is not directed at children and does not knowingly collect data from
children.

## 9. Retention, deletion and withdrawing consent

We hold no data linked to you, so there is no account to delete. Remove
on-device data by deleting the app. Location, camera and photo permissions
can be withdrawn at any time in iPhone Settings. Google's privacy tools apply
to data collected by Google.

## 10. Ballistics notice

The app is a calculation aid; always confirm results with live fire.

## 11. Changes and contact

If this policy changes, the new date is shown on this page.
Questions: Sekerbirol76@gmail.com
