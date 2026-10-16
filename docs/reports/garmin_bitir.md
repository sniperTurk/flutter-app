# Garmin iPhone köprüsü: bitirme (PR #228, 15.10.2026)

Sahibin kararı (15.10.2026 20:55, İstanbul): "çalışma devam etsin, bitsin, mümkün olan en kısa zamanda".
v1 TestFlight'ı etkilemez; köprü TestFlight ve iOS CI derlemesine eklenmedi.

## Ne yapıldı
- **Dal güncellendi:** `main` (66 commit) `feat/garmin-phone` dalına birleştirildi (merge, geçmiş yeniden yazılmadı). Çakışma çıkmadı; main'in davranışı aynen duruyor.
- **Araçlar'daki "Garmin saati" satırı yeni görünüme uyduruldu:** diğer araçlar gibi beyaz simge, gri-mavi zemin (`plainIcon`). Satırda girilen değer yok, bu yüzden ⓘ gerekmiyor; yazı sola dayalı.
- **Satır yazısı düzeltildi:** "1 saat bağlı" yerine "1 saat seçili". Sayı Garmin Connect'te seçilen saat sayısıdır; saat kapalıysa da sayılır, "bağlı" yanıltıcıydı.
- **Soğuk açılış düzeltmesi:** Uygulama kapalıyken Garmin Connect `sniperturk-ciq://` adresiyle geri açtığında köprü adresi işliyordu ama "işlemedim" (NO) diyordu. Flutter 3.47.2 kaynak kodunda bakıldı: bu durumda Flutter adresi bir de sayfa yolu olarak açmaya çalışır (derin bağlantı varsayılan olarak açık), uygulamada böyle bir sayfa yok, hata verip adresi iOS'a geri atar. Artık köprü kendi adresini işlediğinde YES diyor; başka adres yoksa NO, diğer eklentiler seçenekleri almaya devam ediyor.
- **Güvenlik düzeltmesi:** Başka bir uygulama ya da bir bağlantı `sniperturk-ciq://` adresini açarak kayıtlı saat listesini silebiliyor, Garmin kullanmayan birine Bluetooth izni sordurabiliyordu. Artık yalnızca "Garmin saati" satırına dokunduktan sonraki 15 dakika içinde gelen dönüş kabul ediliyor, istek bir kez kullanılıyor. Diğer adresler sessizce yok sayılıyor.

## Nasıl
- `lib/features/tools/garmin_pair_tile.dart`: `plainIcon: true`, yazı "saat seçili".
- `garmin/ios_runner/SniperTurkGarminBridge.m`:
  - `scene:willConnectToSession:options:` işlediği adres için YES döner.
  - `selectDevice` zamanı NSUserDefaults'a yazılır; `handleURL` bu zamanı kontrol etmeden SDK'yı başlatmaz ve listeye dokunmaz.
- `garmin/README.md`: 15 dakika kuralı eklendi.

## Neden
- Kod görünümü: tasarım kararı (15.10.2026, Araçlar: "Araç ikonları beyaz, gri-mavi zemin üzerinde").
- Soğuk açılış: PR açıklamasında açık kalan madde ("soğuk açılışta URL'nin geç kaydolan eklentiye iletilmesi"). Flutter 3.47.2 `FlutterSceneLifeCycle.mm` okundu: bağlantı seçenekleri saklanıyor ve eklenti geç kaydolsa da motor sahneye bağlanınca yeniden iletiliyor. Yani adres köprüye ulaşır. Eksik olan tek şey YES dönüşüydü.
- Güvenlik ve yazı düzeltmeleri: Code Review ve Security review bulguları (ikisi de düşük önemde).

## Uç durumlar
- Kullanıcı satıra dokunur, Garmin Connect'te 15 dakikadan uzun bekler: dönüş yok sayılır, satır eski sayıyı gösterir. Satıra yeniden dokunmak yeter.
- Garmin Connect açıkken uygulama kapanırsa: istek zamanı kalıcı olarak saklandığı için soğuk açılışta da dönüş kabul edilir.
- Köprüsüz derleme (TestFlight dahil): satır hiç görünmez ve yer kaplamaz, Garmin kanalı sessizce "yok" der. Apple Watch kanalı eskisi gibi çalışır.
- `ok` değeri saate 1/0 sayı olarak gider. Saat Boolean, sayı (0 = hayır) ve Char kabul eder; eksik ya da yazı ise mesajı reddeder.

## Yapılmayan (bilerek)
- Connect IQ SDK ve Swift paketi indirilmedi, `garmin-sim.yml` çalıştırılmadı ve PR'a `garmin-sim` etiketi eklenmedi. İndirmek Garmin lisansını kabul etmek demek. Bu yüzden Objective-C köprüsü bu turda derlenmedi: son değişiklikler (YES dönüşü, 15 dakika kuralı) derleyiciden geçmedi.
- Köprü `ios-testflight.yml` ve `ios-ci.yml`'e eklenmedi.
- Gerçek iPhone, Garmin Connect ve saatle deneme yapılmadı; cihaz testi yok.
- İnceleme notları, değiştirilmedi:
  - İş akışında eylemler sürüm etiketine bağlı, commit'e değil. Depodaki diğer iş akışları da böyle.
  - `garmin-sim.yml` fork'tan gelen PR'da yanlış dalı çeker. Yalnızca sahibin kendi dallarıyla kullanılıyor.
  - Saat listesini saklama hatası sessizce geçiliyor (kayıt dosyası yazılamazsa bildirim yok).

## Testler
- `test/garmin_link_test.dart`:
  - Yeni test: satırın simgesi beyaz, zemini gri-mavi.
  - Yazı beklentileri "saat seçili" oldu.
  - Diğer testler aynen duruyor.
- `tools/test_configure_ios_garmin_bridge.py`: 3 yeni sözleşme testi.
  - Soğuk açılışta kendi adresini sahiplenme.
  - `ok` değeri: telefonda 1/0'a çevrilir, saatte Boolean/sayı/Char kabul edilir.
  - İstenmemiş adres listeyi değiştiremez; kontrol SDK başlatılmadan önce yapılır.
- Yerel:
  - `python3 tools/offline_dart_lint.py`: 381 Dart dosyası, 0 sorun.
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: geçti.

## CI linkleri
- Biçim düzeltme (format-fix, f8207b9; değişiklik gerekmedi): https://github.com/sniperTurk/flutter-app/actions/runs/38784149611
- Test (test-diag, `files=test`, f8207b9): başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38784631639
- Analiz (analyze-diag, f8207b9): başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38784635379
- iOS CI (f8207b9): `wind-acceptance` ve `dart-checks` başarılı, `verify` bu rapor yazılırken sıradaydı. https://github.com/sniperTurk/flutter-app/actions/runs/38784158752
- iOS CI, bu raporun commit'i (son hâl): sonuç PR açıklamasında.

## Sahibin yapacakları
1. Garmin lisansını kabul etmek (Connect IQ SDK ve Connect IQ Mobile SDK indirilirken).
2. Garmin geliştirici hesabı açmak.
3. Saat uygulamasını Connect IQ Store'a yüklemek (kendi Garmin hesabıyla, kendi imza anahtarıyla).
4. Lisans kabul edildikten sonra `garmin-sim` iş akışını çalıştırmak (PR'a `garmin-sim` etiketi eklenerek) ve köprünün bu son hâliyle derlendiğini görmek.
5. Gerçek iPhone ve Garmin saatle denemek: saat seçimi (uygulama açıkken ve kapalıyken), çözümün saate gitmesi, saatten mesafe isteği.
6. Köprünün TestFlight derlemesine eklenmesine onay vermek (ayrı iş; şu an eklenmedi).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01QFqAoT4AyJcUu1GzhGkRm7
