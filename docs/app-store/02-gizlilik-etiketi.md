# 02 · App Privacy ("Privacy Nutrition Label") cevap taslağı

> TASLAK — App Store Connect'e girilmedi. Her satır kaynak koddaki bir yere
> veya derlenen uygulamadaki bir gizlilik bildirimine (privacy manifest)
> dayanır. Kodla uyuşmayan iddia yazılmadı.

## 1. Koddan çıkarılan gerçek veri akışı (main @ 835b956)

| Veri / izin | Nerede | Cihazdan çıkıyor mu? | Nereye | Saklama |
|---|---|---|---|---|
| Konum (GPS, düşük doğruluk `LocationAccuracy.low`) | `lib/tools/adapters/geolocator_location_provider.dart` | Hava için: **evet**, enlem/boylam **2 ondalığa (~1 km)** yuvarlanır (`WeatherPolicy.roundCoordinate`) | `api.met.no` (MET Norway) | Uygulamada yalnızca bellek önbelleği (`_cache`, `Expires`'a kadar) |
| Konum → Coriolis enlemi | `ballistics_screen.dart` `_latitudeFromGps` | Hayır | — | Enlem 2 ondalık metin olarak **cihazda** saklanır (`shot_settings_store.dart` `latitude`) |
| Konum → yerel yerçekimi | `ballistics_screen.dart` (Gravity.at) | Hayır | — | Hesaplanan yerçekimi değeri cihazda saklanır (`gravity`) |
| Konum → Haritadan mesafe (ekran açılınca haritayı konuma getirir) | `map_distance_screen.dart` `_locate()` | Dolaylı: görüntülenen harita bölgesinin karoları istenir | Esri `server.arcgisonline.com` **veya** Google Maps SDK (derleme `GOOGLE_MAPS_ENABLED=true` ise) | Uygulama saklamaz |
| Konum → "Özel konum için mesafe" | `calculators_screen.dart` | Hayır | — | Saklanmaz |
| Yer arama metni | `lib/tools/adapters/nominatim_place_search.dart` | Evet, yalnızca arama düğmesine basınca | `nominatim.openstreetmap.org` | Uygulama saklamaz |
| Kamera (Sight Height, tüfek eğimi ölçümü) | `camera_plugin_service.dart`, `incline_measure_screen.dart` | Hayır | — | Fotoğraf bellekte işlenir, kaydedilmez |
| Galeriden tek fotoğraf (PHPicker) | `image_picker_photo_picker.dart` | Hayır | — | Kaydedilmez |
| İvmeölçer (su terazisi, atış açısı, dürbün eğimi) | `sensors_plus_tilt_provider.dart` | Hayır | — | Su terazisi kalibrasyonu cihazda (`level_calibration_preferences.dart`) |
| Pusula yönü | `flutter_compass_heading_provider.dart` | Hayır | — | Saklanmaz |
| Profiller, ayarlar, kullanıcı katalog girdileri | `lib/services/*_store.dart` (SharedPreferences / UserDefaults) | Hayır | — | Cihazda |
| Sürüklenme eğrisi dosyası (.drg/.csv) | `drag_curve_field.dart` (`file_selector`) | Hayır | — | Profil içinde cihazda |
| DOPE kartı PDF | `ballistics_screen.dart` `Printing.sharePdf` | Yalnızca kullanıcı paylaş sayfasında bir hedef seçerse | Kullanıcının seçtiği uygulama | — |
| Elle girilen dürbünün teknik değerleri (marka, model, birim, odak düzlemi, büyütme, mercek çapı, klik değeri, üst kule klik sayısı, retikül) | `lib/tools/adapters/cloudflare_product_report_service.dart` (2026-10-17) | Evet, yalnızca listede olmayan dürbün elle girilip profil kaydedilince, değerler değişmedikçe bir kez. Profil adı, konum, cihaz kimliği, kişisel veri **yok** (`kurulumKimligi: null`) | Sahibin Cloudflare servisi (`sniper-turk-urun-kutusu…workers.dev/urun`) → özel depo `sniperTurk/kullanici-urunleri` | Sunucuda saklanır (ürün kataloğunu geliştirmek için); cihazda yalnızca dönen kayıt kimliği ve değerlerin özeti (hash) |
| Analitik, reklam, çökme raporu, hesap | **Uygulamanın kendi kodunda yok** | — | — | — |

Ağ isteği yapan Dart kodu: `met_no_weather_provider.dart`,
`nominatim_place_search.dart`, `google_elevation_provider.dart` ve
`cloudflare_product_report_service.dart` (`grep -rl "package:http" lib`).
Harita karolarını `flutter_map` / Google Maps SDK indirir. Uygulamanın tek
sunucu uç noktası, elle girilen dürbünlerin gönderildiği Cloudflare
servisidir; kişiyle ilişkilendirilen veri almaz.

## 2. Üçüncü taraf SDK gizlilik bildirimleri (Xcode derlemesinden)

Kaynak: `ci/privacy-dump` dalı, `out/privacy.txt` (2026-10-10 simülatör
derlemesi). Toplanan veri bildiren **tek** bileşen Google Maps:

| Bileşen | Bildirilen veri | Kullanıcıya bağlı | İzleme | Amaç |
|---|---|---|---|---|
| `GoogleMaps.bundle` (Google Maps SDK) | Crash Data | Hayır | Hayır | Analytics |
| | Device ID | **Evet** | Hayır | Analytics, App Functionality |
| | Other Data Types | **Evet** | Hayır | Analytics |
| | Performance Data | Hayır | Hayır | Analytics |
| | Product Interaction | Hayır | Hayır | Analytics |
| `google_maps_flutter_ios` eklentisi | Crash Data, Device ID, Performance Data, Product Interaction (bağlı değil) ve **User ID (bağlı)** | — | Hayır | Analytics (+App Functionality) |
| `Runner/PrivacyInfo.xcprivacy` (uygulamanın kendisi) | Coarse Location | Hayır | Hayır | App Functionality |
| camera, geolocator, image_picker, sensors_plus, shared_preferences, package_info_plus, Flutter | Toplanan veri yok | — | — | — |

Önemli: Google Maps SDK, Maps anahtarı olmadan derlense de (Esri haritası
kullanılan derlemede) pod olarak uygulamaya **girer**. Bu dökümde Google Maps
bundle'ı derlenen `Runner.app` içinde görünüyor. Dolayısıyla etiket Google
Maps'in beyanlarını içermelidir. Kesin liste için yayın arşivinde Xcode →
Organizer → arşiv → **Generate Privacy Report** çalıştırılıp bu tabloyla
karşılaştırılmalı (bu ortamda Mac yok; çalıştırılmadı).

## 3. Önerilen App Store Connect cevapları

**"Do you or your third-party partners collect data from this app?" → Yes**

### Data Used to Track You
- **Yok.** Hiçbir bileşen izleme (tracking) beyan etmiyor; reklam kimliği
  (IDFA) kullanılmıyor, `NSUserTrackingUsageDescription` yok.

### Data Linked to You (Google Maps SDK beyanlarından)

| Kategori → Tür | Amaç | Kaynak |
|---|---|---|
| Identifiers → Device ID | Analytics, App Functionality | Google Maps SDK |
| Identifiers → User ID | Analytics | `google_maps_flutter_ios` bildirimi |
| Other Data → Other Data Types | Analytics | Google Maps SDK |

### Data Not Linked to You

| Kategori → Tür | Amaç | Kaynak |
|---|---|---|
| Location → Coarse Location | App Functionality | Hava verisi için api.met.no'ya ~1 km yuvarlanmış konum (sahip kararı 2026-10-06; `release/RELEASE_CHECKLIST.md`) |
| Diagnostics → Crash Data | Analytics | Google Maps SDK |
| Diagnostics → Performance Data | Analytics | Google Maps SDK |
| Usage Data → Product Interaction | Analytics | Google Maps SDK |
| User Content → Other User Content | App Functionality | Elle girilen dürbünün teknik değerleri, Cloudflare servisine (2026-10-17); kişisel veri yok, kullanıcıya bağlanmaz |

Gerekçeler:
- Apple'ın tanımında "Coarse Location", üç ondalıktan **düşük** çözünürlüklü
  konumdur; MET Norway'e giden değer iki ondalıktır → Coarse. Precise
  Location **beyan edilmez**: hassas konum hiçbir yere gönderilmiyor.
- Harita karo istekleri ve Nominatim aramaları, isteği o anda karşılamak için
  yapılır ve uygulama sahibi bunlara erişmez. Apple'ın "collect" tanımı
  isteğin gerçek zamanlı karşılanmasından uzun süre erişilen veriyi kapsar.
  Bu yüzden ayrıca "Search History" beyan edilmedi. **Sahip kararı:** daha
  temkinli olmak isterseniz Nominatim'e giden arama metni için "Usage Data →
  Search History — App Functionality, bağlı değil" eklenebilir. Gereğinden
  fazla beyan, eksik beyandan daha az risklidir.
- Google Maps SDK'nın pod olarak her derlemeye girdiği şuradan çıkıyor:
  `pubspec.yaml`'da `google_maps_flutter` koşulsuz bağımlılık;
  `GOOGLE_MAPS_ENABLED` yalnızca hangi harita bileşeninin gösterileceğini seçer.
- Profiller ve ayarlar cihazdan çıkmadığı için toplanan veri sayılmaz.

### Alternatif: Google Maps tamamen çıkarılırsa

`google_maps_flutter` bağımlılığı kaldırılırsa (yalnız Esri) etiket şu hale
iner: **Data Not Linked to You → Location → Coarse Location (App
Functionality)**. Diğer her şey "toplanmıyor" olur. Bu karar sahibindir;
bu PR kodu değiştirmez.

## 4. Mevcut beyanlarla uyuşmazlıklar (düzeltilmesi önerilir)

1. `release/PRIVACY_POLICY_DRAFT.md` ve yayındaki gizlilik sayfası Google
   Maps'ten hiç söz etmiyor; harita yalnızca Esri olarak anlatılıyor.
   TestFlight derlemeleri Maps anahtarı varken Google Maps kullanıyor
   (`.github/workflows/ios-testflight.yml`, `GOOGLE_MAPS_ENABLED`).
2. Aynı taslak "Konum uygulamada kalıcı olarak saklanmaz" diyor. Kod,
   Coriolis için GPS'ten alınan enlemi (2 ondalık) ve ondan türeyen yerel
   yerçekimini **cihazda** saklıyor. Cihazdan çıkmadığı için etiketi
   etkilemez, ama metin düzeltilmeli (yeni taslak: `03-gizlilik-politikasi.md`).
3. `release/RELEASE_CHECKLIST.md` App Privacy için yalnızca Coarse
   Location'ı planlıyor; Google Maps SDK beyanları eksik.
4. Uygulama içinde gizlilik politikasına bağlantı **bulunamadı**
   (`lib/` içinde "gizlilik/privacy/politika" bağlantısı yok). Kural 5.1.1(i)
   bağlantının hem App Store Connect'te hem uygulama içinde kolay erişilebilir
   olmasını istiyor. Bkz. `05-inceleme-kurallari-ve-yas.md`.

## Kaynaklar

- App privacy details on the App Store: https://developer.apple.com/app-store/app-privacy-details/
- App Review Guidelines 5.1.1, 5.1.2: https://developer.apple.com/app-store/review/guidelines/
