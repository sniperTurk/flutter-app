# 02 · App Privacy ("Privacy Nutrition Label") cevap taslağı

> TASLAK — App Store Connect'e girilmedi. Her satır kaynak koddaki bir yere
> veya üreticinin yayımladığı bir gizlilik bildirimine dayanır. Kodla
> uyuşmayan iddia yazılmadı. Güncelleme: 2026-10-14, `main @ 237c14d`
> (önceki taslak `835b956`).

## 1. Koddan çıkarılan gerçek veri akışı (main @ 237c14d)

Her satır 2026-10-14'te `grep` ile yeniden doğrulandı.

| Veri / izin | Nerede | Cihazdan çıkıyor mu? | Nereye | Saklama |
|---|---|---|---|---|
| Konum → hava verisi (Hava Durumu sekmesi, Araçlar > Hava & Rüzgâr) | `ballistics_screen.dart` (`services.location.current()` → hava), `tools/state/weather_controller.dart` | **Evet**: enlem/boylam **2 ondalığa (~1 km)** yuvarlanır (`WeatherPolicy.roundCoordinate`, `met_no_weather_provider.dart`) | `api.met.no` (MET Norway) | Konum saklanmaz; yalnızca bellek önbelleği (`_cache`, `Expires`'a kadar). Gelen sıcaklık/nem/rüzgâr kutulara yazılır ve Hava Durumu değerleri olarak cihazda kalır |
| Konum → irtifa ("Basıncı telefondan al", #243) | `ballistics_screen.dart` `_readPhonePressure` (GPS `altitudeM`) | Hayır | — | İrtifa kutusuna yazılır, cihazda |
| Konum → Coriolis enlemi ("Konumdan al") | `ballistics_screen.dart` `_latitudeFromGps` | Hayır | — | Enlem 2 ondalık metin olarak **cihazda** (`shot_settings_store.dart` `latitudeText`) |
| Konum → yerel yerçekimi ("Konumdan hesapla") | `ballistics_screen.dart` `_gravityFromLocation` | Hayır | — | Yerçekimi değeri cihazda (`gravityText`) |
| Konum → Haritadan mesafe (açılışta haritayı konuma getirir) | `map_distance_screen.dart` `_locate()` | Dolaylı: görüntülenen bölgenin karoları istenir | Esri `server.arcgisonline.com` **veya** Google Maps (derleme `GOOGLE_MAPS_ENABLED=true` ise) | Uygulama saklamaz |
| Konum → "Özel konum için mesafe" | `calculators_screen.dart` `_locate()` | Hayır | — | Saklanmaz |
| Yer arama metni | `tools/adapters/nominatim_place_search.dart` | Evet, yalnızca arama düğmesine basınca | `nominatim.openstreetmap.org` | Uygulama saklamaz |
| Kamera (Sight Height; Pro > Açı "Kamerayla ölç") | `sight_height_screen.dart`, `incline_measure_screen.dart` | Hayır | — | Bellekte işlenir, kaydedilmez |
| Galeriden tek fotoğraf (PHPicker) | `tools/adapters/image_picker_photo_picker.dart` (yalnız Sight Height) | Hayır | — | Kaydedilmez |
| Barometre ("Basıncı telefondan al", #229) | `tools/adapters/sensors_plus_pressure_sensor.dart` | Hayır | — | Basınç kutusuna yazılır, cihazda |
| İvmeölçer (Su Terazisi, tüfek eğimi, dürbün eğimi "Telefonla ölç") | `level_screen.dart`, `incline_measure_screen.dart`, `scope_cant_screen.dart` | Hayır | — | Su terazisi kalibrasyonu cihazda (`level_calibration_preferences.dart`) |
| Pusula (Pusula, Pro "Pusuladan al") | `compass_screen.dart`, `ballistics_screen.dart` | Hayır | — | Atış yönü kutusu cihazda |
| Profiller, ayarlar, kişisel katalog, kronograf, atış günlüğü, paralaks işaretleri | `lib/services/*_store.dart` (SharedPreferences / UserDefaults) | Hayır | — | Cihazda |
| Profil yedeği ("Yedekle" / "Geri yükle", #218) | `profiles/profile_backup_actions.dart` (`share_plus`, `file_selector`) | Yalnızca kullanıcı paylaş sayfasında bir hedef seçerse | Kullanıcının seçtiği yer (Dosyalar, iCloud Drive, Google Drive…) | Uygulama kopya tutmaz |
| Sürüklenme eğrisi dosyası (.drg/.csv) | `profiles/drag_curve_field.dart` (`file_selector`) | Hayır | — | Profil içinde cihazda |
| DOPE kartı PDF | `ballistics_screen.dart` `_shareDopeCard` (`printing`) | Yalnızca kullanıcı paylaş sayfasında bir hedef seçerse | Kullanıcının seçtiği uygulama | — |
| Analitik, reklam, çökme raporu, hesap | **Uygulamanın kendi kodunda yok** (`pubspec.yaml`'da analitik/reklam paketi yok) | — | — | — |

Ağ isteği yapan Dart kodu yalnızca iki adaptör: `met_no_weather_provider.dart`
ve `nominatim_place_search.dart`. Harita karolarını `flutter_map` / Google
Maps SDK indirir. Uygulamanın kendi sunucusu yok. Apple Watch köprüsü
(`lib/services/watch/`) yalnızca elle tetiklenen `watch-sim.yml` iskeletinde
bağlanır; yayın derlemesinde yerel tarafı yok ve cihaz dışına veri
göndermez, bu yüzden politikaya yazılmadı.

## 2. Google Maps SDK for iOS — üreticinin beyanı

**Resmî Google sayfası** (okunma: 2026-10-14, sayfada "Last updated
2026-08-25 UTC"):
https://developers.google.com/maps/documentation/ios-sdk/apple-privacy-policy

Kısa alıntılar:

> "Google Maps Platform SDKs' privacy manifests disclose data that is always
> collected and collected by default."

> "It is your responsibility to ensure your privacy nutrition labels are
> accurate based on your app's actual usage of SDKs."

Yani Google, toplanan veri türlerini web sayfasında tablo olarak değil,
**SDK ile birlikte dağıttığı gizlilik bildiriminde** (`PrivacyInfo.xcprivacy`)
yayımlıyor. Bu bildirim Google'ın kendi dosyasıdır; değeri buradan aldık.
Kaynak: `GoogleMaps` pod'unun
`Maps/Resources/GoogleMapsResources/GoogleMaps.bundle/PrivacyInfo.xcprivacy`
dosyası, `ci/privacy-dump` dalı `out/privacy.txt` (2026-10-10 macOS
derlemesi, `bee961d`). Aynı dosya derlenen `Runner.app` içinde de var.

| Bileşen (üretici) | Bildirilen veri | Kullanıcıya bağlı | İzleme | Amaç |
|---|---|---|---|---|
| `GoogleMaps.bundle` — Google Maps SDK for iOS (Google) | Crash Data | Hayır | Hayır | Analytics |
| | Device ID | **Evet** | Hayır | Analytics, App Functionality |
| | Other Data Types | **Evet** | Hayır | Analytics |
| | Performance Data | Hayır | Hayır | Analytics |
| | Product Interaction | Hayır | Hayır | Analytics |
| `google_maps_flutter_ios` 2.18.6 (Flutter ekibi, Google) | Crash Data, Device ID, Performance Data, Product Interaction (bağlı değil) ve **User ID (bağlı)** | — | Hayır | Analytics (+ Device ID için App Functionality) |
| `Runner/PrivacyInfo.xcprivacy` (uygulamanın kendisi) | Coarse Location | Hayır | Hayır | App Functionality |
| camera, geolocator, image_picker, sensors_plus, shared_preferences, package_info_plus, Flutter | Toplanan veri yok | — | — | — |

Notlar:
- Google Maps SDK pod olarak **her derlemeye girer**: `pubspec.yaml`'da
  `google_maps_flutter` koşulsuz bağımlılık; `GOOGLE_MAPS_ENABLED` yalnızca
  hangi harita bileşeninin gösterileceğini seçer
  (`map_distance_screen.dart`). Bu yüzden etiket Google Maps beyanlarını
  içermelidir.
- Döküm `share_plus` (#218, 2026-10-12'de eklendi) ve `printing`,
  `file_selector_ios`, `flutter_compass` bildirimlerini göstermiyor (döküm
  daha eski / bu paketler bildirim taşımıyor olabilir). **Doğrulanmadı.**
  Yayın arşivinde Xcode → Organizer → arşiv → **Generate Privacy Report**
  çalıştırılıp bu tabloyla karşılaştırılmalı (bu ortamda Mac yok).

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

Gerekçeler:
- Apple'ın tanımında "Coarse Location", üç ondalıktan **düşük** çözünürlüklü
  konumdur; MET Norway'e giden değer iki ondalıktır → Coarse. Precise
  Location **beyan edilmez**: hassas konum hiçbir yere gönderilmiyor
  (irtifa, Coriolis enlemi ve yerçekimi cihazda kalır).
- MET Norway konumu saklamadığımız, yalnızca isteği karşılamak için
  gönderdiğimiz hâlde Coarse Location beyan edilir: sahip 2026-10-06'da bu
  temkinli seçimi yaptı.
- Harita karo istekleri ve Nominatim aramaları isteği o anda karşılamak
  için yapılır ve uygulama sahibi bunlara erişmez; bu yüzden ayrıca "Search
  History" beyan edilmedi. **Sahip kararı:** daha temkinli olmak isterseniz
  "Usage Data → Search History — App Functionality, bağlı değil"
  eklenebilir.
- Barometre, ivmeölçer, pusula, kamera ve fotoğraf verisi cihazdan çıkmaz →
  toplanan veri sayılmaz. Profil yedeği yalnızca kullanıcının seçtiği yere
  gider, geliştirici erişmez → toplanan veri sayılmaz.

### Alternatif: Google Maps tamamen çıkarılırsa

`google_maps_flutter` bağımlılığı kaldırılırsa (yalnız Esri) etiket şu hale
iner: **Data Not Linked to You → Location → Coarse Location (App
Functionality)**. Bu karar sahibindir; bu PR bağımlılığı değiştirmez.

## 4. Durum (2026-10-14)

1. **Uygulama içi gizlilik bağlantısı — YAPILDI (bu PR):** Araçlar >
   Gizlilik politikası, metin uygulamada gömülü (`03-gizlilik-politikasi.md`
   ile aynı).
2. **Yayındaki gizlilik sayfası eski — SAHİP:** `PRIVACY_POLICY_URL`
   sayfası Google Maps SDK, barometre, profil yedeği ve cihazda saklanan
   enlemden söz etmiyor; `03` metniyle değiştirilmeli.
3. **`release/RELEASE_CHECKLIST.md` App Privacy planı** yalnızca Coarse
   Location içeriyor; App Store Connect'e yukarıdaki tablo girilmeli —
   SAHİP.
4. **İzin metinleri** (`tools/configure_ios_info_plist.py`): konum metni hâlâ
   haritayı, yerel yerçekimini ve "Basıncı telefondan al" irtifasını
   söylemiyor ve "kalıcı olarak saklanmaz" diyor; kamera metni hâlâ
   "yalnızca Sight Height". Bkz. `04-info-plist-izinleri.md`. Bu PR bu
   dosyayı değiştirmez (kapsam dışı); ayrı kod PR'ı için sahip onayı gerekir.

## Kaynaklar

- Google, Maps SDK for iOS — Apple App Store Privacy Details (okunma 2026-10-14): https://developers.google.com/maps/documentation/ios-sdk/apple-privacy-policy
- Google Gizlilik Politikası: https://policies.google.com/privacy
- Apple, App privacy details on the App Store: https://developer.apple.com/app-store/app-privacy-details/
- Apple, App Review Guidelines 5.1.1, 5.1.2: https://developer.apple.com/app-store/review/guidelines/
