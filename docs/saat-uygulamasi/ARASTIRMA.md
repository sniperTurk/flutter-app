# Saat uygulaması araştırması (2026-10-11)

Amaç: atıcı sahada telefonu çıkarmadan bileğinden kule düzeltmesini görsün.
Balistik hesap telefonda kalır; saat yalnızca telefonun hesapladığı sonucu
gösterir (tek doğru kaynak).

Kaynak kuralı: yalnızca developer.apple.com, developer.garmin.com,
docs.flutter.dev ve pub.dev resmi paket sayfaları. Bir sayfanın metni
alınamadıysa (JavaScript ile yüklenen sayfalar) bu açıkça yazıldı ve o bilgi
"doğrulanmalı" diye işaretlendi.

## 1. Apple Watch (watchOS + WatchConnectivity)

### Yol

1. Mevcut iOS projesine bir watchOS hedefi eklenir: Xcode'da "Add a target →
   watchOS → App → Watch app for Existing iOS App" [A1]. Bugünkü şablon tek
   hedefli SwiftUI saat uygulamasıdır.
2. Saat uygulamasının bundle id'si iOS uygulamasının bundle id'sinden
   türetilir: `com.sniperturk.sniperTurk` → `com.sniperturk.sniperTurk.watchkitapp` [A3].
3. Saat uygulamasının Info.plist'indeki `WKCompanionAppBundleIdentifier`
   değeri iOS uygulamasının `CFBundleIdentifier`'ı ile aynı olmalıdır [A2].
4. Veri aktarımı WatchConnectivity ile yapılır [A4, A5]:
   - `WCSession.isSupported()` → `delegate` ata → `activate()`; etkinleşme
     eşzamansızdır, sonucu `session(_:activationDidCompleteWith:error:)` bildirir.
   - iOS tarafında `sessionDidBecomeInactive` ve `sessionDidDeactivate`
     zorunludur; ikincisinde `activate()` yeniden çağrılır (saat değişimi).
   - `isPaired`, `isWatchAppInstalled` (yalnızca iOS) ve `isReachable`
     ile durum okunur.
5. Hangi aktarım? [A5]
   - `updateApplicationContext(_:)`: yalnızca en son durum tutulur, önceki
     bekleyen değerin üstüne yazar. Saat uygulaması kapalıyken de bir sonraki
     açılışta teslim edilir. **Çözüm verisi için doğru seçim bu.**
   - `sendMessage(_:replyHandler:errorHandler:)`: anında, iki taraf da
     erişilebilirken. Saatten "mesafeyi değiştir" isteği için kullanılır;
     saatten gönderilen mesaj, erişilebilirse iOS uygulamasını uyandırır.
   - `transferUserInfo(_:)`: sıralı ve garantili kuyruk; burada gerek yok.
   - Sözlükler property-list türlerinden oluşmalı ve küçük olmalıdır.
6. Flutter tarafı: Dart ile Swift arasında `MethodChannel` [F1]. Flutter
   3.41+ şablonu `UISceneDelegate` yaşam döngüsünü kullanır; kanal
   `didInitializeImplicitFlutterEngine` içinde, `engineBridge` üzerinden
   kaydedilmelidir (`didFinishLaunchingWithOptions` içinde `window` nil
   olabilir). Kanal çağrıları iOS'ta ana iş parçacığında yapılır;
   arka plandan gelen WCSession geri çağrıları `DispatchQueue.main.async`
   ile ana iş parçacığına taşınır [F1].
7. Hazır pub paketi: `watch_connectivity` [P1] — yayıncı rexios.dev
   (doğrulanmış), BSD-3-Clause, Android ve iOS, 0.2.10. `sendMessage`,
   `updateApplicationContext`, `messageStream`, `contextStream`, `isPaired`,
   `isReachable` sunar. **Bu prototipte kullanılmadı**: yeni bir bağımlılık
   `pubspec.lock`'u değiştirir (bu repo lockfile kaymasını hata sayar ve
   provenance kaydı tutar) ve yalnızca birkaç satırlık Swift'in yerine geçer.
   Kendi küçük kanalımız (`sniper_turk/watch`) hem test edilebilir hem de
   bağımlılık eklemez. İleride paket tercih edilirse Dart arayüzü aynı kalır
   (`WatchTransport` arkasına yeni bir uygulama yazılır).

### Simülatör ve test sınırı

- Apple'ın resmi WatchConnectivity örneği "fiziksel iPhone ve Apple Watch ile
  test edin" der [A5]. Yani simülatör derlemesi kodun **derlendiğini** kanıtlar;
  telefondan saate gerçek aktarım ancak gerçek cihaz çiftiyle doğrulanır.
  Sahibinde saat olmadığı için bu adım açık kalır.
- watchOS uygulaması kullanıcı bileğini indirdiğinde askıya alınır; Xcode'dan
  çalıştırmak bu davranışı değiştirir [A5].

### Hesap, lisans ve imzalama

- Apple Developer Program üyeliği (mevcut; TestFlight zaten çalışıyor).
- Saat uygulaması için ayrı bir App ID gerekir:
  `com.sniperturk.sniperTurk.watchkitapp` [A3]. Her hedef için ekip (team)
  atanır, Xcode otomatik imzalama ile profil üretir [A5].
- App Group yalnızca saat ile bir widget/komplikasyon veri paylaşacaksa
  gerekir [A5]; bu prototipte yok.
- Saat uygulaması iOS uygulamasının içine gömülür ("Embed Watch Content")
  ve aynı arşivle TestFlight'a gider. **Bu, mevcut TestFlight imzalamasını
  etkiler** (ikinci bundle id, ikinci profil, export seçenekleri ve repo'daki
  imzalı IPA kimlik denetimleri). Bu yüzden prototipte saat hedefi Runner'a
  gömülmedi; ayrı bir Xcode projesi olarak derlenir. Adım listesi
  [IMZALAMA-ADIMLARI.md](IMZALAMA-ADIMLARI.md) dosyasındadır.

## 2. Garmin (Connect IQ, Monkey C)

### Yol

1. Saat tarafı bir Connect IQ "watch-app" (Monkey C). Telefondan gelen
   mesajlar `Toybox.Communications.registerForPhoneAppMessages(method)` ile
   alınır; geri çağrı bir `PhoneAppMessage` alır [G2]. Mesajın içeriği
   `Message.data` alanındadır (API 1.3.0+) [G3].
2. Saatten telefona `Communications.transmit(content, options, listener)`
   ile gönderilir; `content` sayı, metin, boolean, dizi veya sözlük olabilir;
   `listener` bir `ConnectionListener`'dır [G2].
3. Manifest'te `Communications` izni gerekir [G2].
4. Telefon tarafı: iOS için "Connect IQ Mobile SDK" (resmi sayfa: "Mobile SDK
   for iOS" [G4]). **Bu sayfanın metni JavaScript ile yüklendiği için
   alınamadı.** Genel bilgi (doğrulanmalı): SDK bir iOS framework'üdür;
   telefonda Garmin Connect Mobile uygulaması kurulu olmalıdır; cihaz seçimi
   Garmin Connect Mobile'a URL şeması ile yönlendirerek yapılır; uygulama
   saat uygulamasının manifest'teki UUID'si ile bulunur ve mesaj gönderilir.
   Bu adımlar sahibinin SDK'yı indirmesinden sonra resmi sayfadan teyit
   edilmelidir.

### Hesap, lisans ve imzalama

- SDK yalnızca "SDK Manager" ile indirilir. Resmi sayfa: "By downloading any
  of the following SDKs, you accept our license agreement." [G1]. Yani
  **indirme = Connect IQ Developer Agreement'ı kabul etmek.**
- Garmin Developer Account için kayıt gerekir ve en az 18 yaş şartı vardır
  (uygulama yayımlamak için) [G1].
- Bu nedenle bu oturumda SDK indirilmedi, lisans kabul edilmedi, hesap
  açılmadı. Garmin kodu yazıldı ancak **derlenmedi**. Sahibinin adımları
  `garmin/README.md` dosyasında (feat/garmin dalı).
- Monkey C derlemesi bir "developer key" ile imzalanır (yerelde üretilen
  özel anahtar; resmi "Getting Started" sayfasının metni alınamadı,
  doğrulanmalı). Bu anahtar repo'ya konmaz.

## 3. Saatte ne gösterilecek (öneri ve gerekçe)

| Alan | Neden |
|---|---|
| Aktif profil adı | Yanlış tüfek/fişek profiliyle atış en sık hata; ilk satırda görünmeli. |
| Hedef mesafesi + birim (m/yd) | Düzeltme mesafeye bağlı; saat hangi mesafe için olduğunu göstermezse sayı anlamsız. |
| Yukarı/aşağı kule kliki (↑/↓) | Asıl bilgi; en büyük yazı. |
| Sağ/sol kule kliki (→/←) | Asıl bilgi; ikinci büyük yazı. |
| Birim (MRAD/MOA) ve klik değeri | Kule birimi profilden gelir; telefondakiyle karışmasın. |
| Rüzgâr düzeltmesi | Rüzgâr hızı ve saat yönü, sağ/sol klikin hangi rüzgârla hesaplandığını söyler. |
| Son güncelleme saati | Eski veriyle atışı önler; 2 dakikadan eskiyse "eski" uyarısı. |
| Saatten mesafe değiştirme | Apple'da Digital Crown, Garmin'de yukarı/aşağı tuşları. Saat yalnızca yeni mesafeyi **ister**; hesabı telefon yapar ve sonucu geri gönderir. Telefona ulaşılamazsa saat eski sonucu "bekleniyor" diye işaretler, kendi hesap yapmaz. |

Gösterilmeyenler (bilerek): tutuş (holdover), WEZ, hız/enerji, atmosfer
ayrıntısı. Saat ekranı küçük; atıcının o anda ihtiyacı kule kliki.

Metin kuralları: Türkçe, kalın yazı yok, sade. "Sight height" İngilizce kalır
(saatte gösterilmiyor).

## Kaynaklar

- [A1] Setting up a watchOS project — https://developer.apple.com/documentation/watchos-apps/setting-up-a-watchos-project
- [A2] WKCompanionAppBundleIdentifier — https://developer.apple.com/documentation/bundleresources/information-property-list/wkcompanionappbundleidentifier
- [A3] Transferring data with Watch Connectivity (bundle id kuralı, imzalama, App Group) — https://developer.apple.com/documentation/watchconnectivity/transferring-data-with-watch-connectivity
- [A4] WCSession — https://developer.apple.com/documentation/watchconnectivity/wcsession (sayfa metni JavaScript ile yüklendi; özet [A5] ve framework sayfasıyla teyit edildi)
- [A5] Watch Connectivity — https://developer.apple.com/documentation/watchconnectivity ve [A3]
- [F1] Platform channels — https://docs.flutter.dev/platform-integration/platform-channels
- [P1] watch_connectivity — https://pub.dev/packages/watch_connectivity
- [G1] Connect IQ SDK — https://developer.garmin.com/connect-iq/sdk/
- [G2] Toybox.Communications — https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications.html
- [G3] Toybox.Communications.Message — https://developer.garmin.com/connect-iq/api-docs/Toybox/Communications/Message.html
- [G4] Mobile SDK for iOS — https://developer.garmin.com/connect-iq/core-topics/mobile-sdk-for-ios/ (metin alınamadı)
