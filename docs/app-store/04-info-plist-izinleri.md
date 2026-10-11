# 04 · Info.plist izin açıklamaları denetimi

> Yalnızca inceleme; bu PR `tools/configure_ios_info_plist.py`'yi
> **değiştirmez**. `ios/` klasörü depoda yok; derlemede
> `tools/bootstrap_ios_scaffold.sh` oluşturur ve izin metinlerini
> `tools/configure_ios_info_plist.py` yazar. Öneriler kabul edilirse metin
> orada (ve `tools/test_configure_ios_info_plist.py` testinde) değişmelidir.

Kural dayanağı: 5.1.1(ii) "Ensure your purpose strings clearly and completely
describe your use of the data." ve 5.1.5 (konum kullanım amacını açıklayın).

## Özet tablo

| Anahtar | Mevcut metin özeti | Kodda gerçek kullanım | Durum |
|---|---|---|---|
| `NSLocationWhenInUseUsageDescription` | Hava verisi ve Coriolis enlemi; "kalıcı olarak saklanmaz" | Hava (api.met.no), Coriolis enlemi, **yerel yerçekimi**, **Haritadan mesafe** (açılışta konuma gider), **Özel konum için mesafe** | **EKSİK + BELİRSİZ** |
| `NSLocationAlwaysAndWhenInUseUsageDescription` | Arka planda kullanılmaz | Uygulama yalnız when-in-use izni istiyor (`Geolocator.requestPermission`) | Uygun (ITMS-90683 için gerekli) |
| `NSCameraUsageDescription` | Yalnızca Sight Height | Sight Height **ve tüfek eğimi ölçümü** (`incline_measure_screen.dart` arka kamerayı açar) | **EKSİK** |
| `NSPhotoLibraryUsageDescription` | Seçilen tek fotoğraf, Sight Height | PHPicker, `requestFullMetadata: false` | Uygun |
| `NSMotionUsageDescription` | Yalnızca Su Terazisi | Su Terazisi **ve** atış açısı / tüfek eğimi ölçümü / dürbün eğimi (`sensors_plus` ivmeölçer) | **EKSİK** ("yalnızca" yanlış) |
| `NSMicrophoneUsageDescription` | Ses kaydetmez; kamera bileşeni gereği | `enableAudio: false` | Uygun (dürüst) |
| `NSPhotoLibraryAddUsageDescription` | Kaldırılmış | Kitaplığa yazma yok | Uygun |
| `NSUserTrackingUsageDescription` | Yok | İzleme yok | Uygun (eklenmemeli) |
| Pusula | Anahtar gerekmez | `flutter_compass` yön verisi izinsiz okunur | Uygun |
| Dosya seçici / paylaş | Anahtar gerekmez | Sistem belge seçici ve paylaş sayfası | Uygun |

## Ayrıntılar ve öneri metinleri

### 1. `NSLocationWhenInUseUsageDescription` — EKSİK ve BELİRSİZ

Sorunlar:
- Haritadan mesafe ekranı açılınca konumu ister (`map_distance_screen.dart`
  `initState → _locate()`); metin bunu söylemiyor. İnceleyici izin penceresini
  büyük olasılıkla harita ekranında görecek.
- Yerel yerçekimi (Pro) ve "Özel konum için mesafe" hesaplayıcısı da konumu
  kullanıyor.
- "Konum kalıcı olarak saklanmaz" ifadesi tam doğru değil: GPS'ten alınan
  Coriolis enlemi (2 ondalık) ve yerçekimi değeri cihazda saklanıyor
  (`shot_settings_store.dart`). Cihazdan çıkmıyor, ama ifade düzeltilmeli.

Öneri (TR, uygulama dili):

> Konumunuz yalnızca uygulama açıkken kullanılır: bulunduğunuz yerin hava
> verisini almak (yaklaşık konum MET Norway'e gönderilir), Coriolis ve yerel
> yerçekimi için enlemi doldurmak ve haritayı bulunduğunuz yere getirmek için.
> Konum bize gönderilmez.

### 2. `NSCameraUsageDescription` — EKSİK

Öneri:

> Kamera, Sight Height ekranında dürbün yüksekliğini ölçmek ve tüfek eğimi
> ölçümünde hedefi görmek için kullanılır. Görüntüler kaydedilmez ve cihazdan
> çıkmaz.

### 3. `NSMotionUsageDescription` — EKSİK

Not: ham ivmeölçer okuması iOS'ta izin penceresi açmaz; metin yine de doğru
olmalı.

> Hareket sensörü; su terazisi, atış açısı ve dürbün/tüfek eğimini göstermek
> için kullanılır. Veri cihazdan çıkmaz.

### 4. Dil / yerelleştirme — BELİRSİZ

Tüm izin metinleri Türkçe ve `InfoPlist.strings` yerelleştirmesi yok.
İngilizce mağaza sayfası açılırsa İngilizce cihazdaki inceleyici izin
pencerelerini Türkçe görür. Bu tek başına ret sebebi olarak yazılı değil;
ama inceleme notuna "Uygulama arayüzü Türkçedir" yazılması ve/veya
`en.lproj/InfoPlist.strings` eklenmesi önerilir. İngilizce karşılıklar:

- Location: "Your location is used only while the app is open: to fetch
  weather for where you are (an approximate location is sent to MET Norway),
  to fill latitude for Coriolis and local gravity, and to centre the map on
  you. Your location is never sent to us."
- Camera: "The camera is used to measure sight height and to view the target
  during rifle incline measurement. Images are not saved and never leave the
  device."
- Photos: "Only the single photo you pick is used for the Sight Height
  measurement. It is not saved and never leaves the device."
- Motion: "Motion sensors show level, shot angle and scope/rifle cant. Data
  never leaves the device."
- Microphone: "The app never records audio. This text exists because the
  camera component requires it."

### 5. Kontrol edilemeyenler

- Derlenen gerçek `Info.plist` bu ortamda yok (Mac çalıştırılmadı). Yukarıdaki
  tablo `tools/configure_ios_info_plist.py` içindeki sabitlere dayanır.
  Arşivden sonra `plutil -p Runner.app/Info.plist` ile teyit edilmelidir.
