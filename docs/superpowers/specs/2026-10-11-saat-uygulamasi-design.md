# Saat uygulaması (Apple Watch + Garmin) — tasarım

Tarih: 2026-10-11. Sahibi oturumda yoktu; sorular aşağıda varsayım olarak
cevaplandı. Her varsayım PR açıklamasında da listelenir, sahibi düzeltebilir.

## Amaç ve başarı ölçütü

Atıcı sahada telefonu çıkarmadan, bileğinden o anki kule düzeltmesini görür.
Başarı: telefondaki Atış sekmesinin gösterdiği yukarı/aşağı ve sağ/sol klik
saatte aynı sayıyla görünür; saat hesap yapmaz.

## Varsayımlar (sahibi yokken verilen kararlar)

1. Saat yalnızca gösterir; mesafe değiştirme saatten **istek** olarak gelir,
   telefon hesaplar ve sonucu geri gönderir (tek doğru kaynak).
2. Gösterilen klik sayısı Atış sekmesindeki "gerekli" kliktir (sıfır ofseti,
   aerodinamik sıçrama, spin drift ve kule ölçek katsayısı dahil); kule
   hareket sınırı nedeniyle kırpılmaz. Telefon sınır uyarısını zaten gösterir.
3. Çözüm yoksa (profil yok, geçersiz girdi) saat "Çözüm yok — telefonda
   hesaplayın" gösterir; eski sayıyı göstermez.
4. Veri 2 dakikadan eskiyse saat sayıları sönük gösterir ve "Veri eski"
   uyarısı verir (sahada koşullar değişir).
5. Mesafe adımı: ateşli silah 10, havalı 5 (m veya yd, profilin birimi).
6. Yeni pub bağımlılığı eklenmez (lockfile/provenance kuralları); kendi
   `MethodChannel`'ımız kullanılır.
7. Saat hedefi Runner'a gömülmez (TestFlight imzalaması korunur). watchOS
   uygulaması ayrı bir Xcode projesi (XcodeGen) olarak derlenir.
8. Uygulama yalnızca iOS; Android'de kanal hiç yanıt vermez, köprü sessizdir.

## Bileşenler

### Dart (telefon)

- `lib/services/watch/watch_solution.dart`: değişmez değer sınıfı
  `WatchSolution` ve `toMessage()` (yalnızca property-list ve Monkey C
  uyumlu türler: String, int, double, bool). Alanlar: `v` (şema sürümü 1),
  `ok`, `profile`, `range`, `rangeUnit`, `rangeStep`, `up` (klik, + yukarı),
  `right` (klik, + sağ), `upAngle`, `rightAngle`, `unit` (MRAD/MOA),
  `click`, `windSpeed`, `windUnit`, `windClock`, `at` (epoch ms).
- `lib/services/watch/watch_bridge.dart`: `WatchBridge` + `WatchTransport`
  arayüzü + `MethodChannelWatchTransport` (`sniper_turk/watch`).
  - `publish(WatchSolution)`: aynı içerik (zaman hariç) tekrar gönderilmez.
  - Native taraf yoksa (`MissingPluginException`) veya hata verirse
    (`PlatformException`) sessizce hiçbir şey yapmaz; bir kez yoksa sonraki
    çağrılar kanala hiç gitmez.
  - `rangeRequests`: saatten gelen mesafe istekleri (`setRange`), yalnızca
    1…üst sınır arası tam sayılar geçer.
- `BallisticsScreen` (yalnızca `shot`/`all` görünümü): `_scopeDial` zaten
  hesapladığı gerekli klikleri bir kare sonrası `WatchBridge`'e verir;
  `rangeRequests` dinlenir ve `_setShotDisplay` çağrılır. Hesap kodu
  değişmez.

### iOS Runner (telefon, native)

- `watch/ios_runner/SniperTurkWatchBridge.swift`: `FlutterPlugin`.
  `publish` → `WCSession.updateApplicationContext`; saatten gelen
  `sendMessage(["type":"setRange","value":N])` → Dart'a `setRange`.
  Saat eşlenmemişse/uygulama kurulu değilse sessizce `false` döner.
- `tools/configure_ios_watch_bridge.py` + `.rb`: oluşturulan iskelete dosyayı
  ekler ve `AppDelegate`'te `GeneratedPluginRegistrant.register(with: X)`
  satırının hemen ardına kayıt satırını koyar (Flutter'ın iki şablonu da).
  **Yalnızca** elle tetiklenen `watch-sim.yml` çalıştırır; TestFlight ve
  iOS CI iskeleti değişmez.

### watchOS uygulaması

- `watch/WatchCore` (Swift Package, watchOS 10 / macOS 13): mesaj çözümü,
  biçimlendirme (Türkçe metin), eskime kuralı, mesafe adımı. `swift test`.
- `watch/SniperTurkWatch` (XcodeGen `project.yml`): SwiftUI uygulaması,
  `WCSession` deposu, ana ekran, mesafe ekranı (Digital Crown).
  Bundle id `com.sniperturk.sniperTurk.watchkitapp`,
  `WKCompanionAppBundleIdentifier = com.sniperturk.sniperTurk`.

### Garmin (ayrı dal)

- `garmin/` Connect IQ watch-app: `manifest.xml` (Communications izni),
  `monkey.jungle`, `source/*.mc`, `resources/`. Aynı mesaj şeması.
  SDK lisansı gerektirdiği için derlenmez; README sahibinin adımlarını
  listeler.

## Veri akışı

Telefon: girdi → çözüm (mevcut motor) → Atış ekranı → `WatchSolution` →
`WatchBridge.publish` → kanal → `updateApplicationContext` → saat.
Saat: Crown ile mesafe → `sendMessage(setRange)` → kanal → `rangeRequests`
→ `_setShotDisplay` → yeni çözüm → saat.

## Hata durumları

- Native yok / saat yok / uygulama kurulu değil: sessiz, hiçbir şey yapma.
- Saatten geçersiz mesafe: yok sayılır (telefon kendi sınırına kırpar).
- Saat telefona ulaşamaz: mesafe ekranı "Telefona ulaşılamadı" der,
  sayıyı değiştirmez.

## Test

- Dart: `WatchSolution` (mesaj alanları, sıfıra yuvarlanan eksi, çözüm yok),
  `WatchBridge` (sahte taşıyıcı: tekrar gönderilmez, native yokken sessiz,
  geçersiz mesafe süzülür), kanal ile `MissingPluginException` testi.
- Python: AppDelegate yamasının iki şablonda da çalışması, tekrarda değişmemesi.
- Swift: `WatchCore` birim testleri (macOS runner'da `swift test`).
- Derleme: watchOS simülatörü (en fazla 2 deneme), Runner + köprü iOS
  simülatörü (aynı iş).
- Doğrulanamayan: gerçek cihaz çiftinde aktarım (sahibinde saat yok).
