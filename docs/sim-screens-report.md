# iOS simülatörle uygulamayı inceleme: rapor (2026-10-11)

## Kısaca

- **Ücretsiz yol kuruldu ve çalışıyor.** GitHub'ın Mac bilgisayarında bir iPhone 17 Pro simülatörü açılıyor. Claude uygulamayı kurup sayfaları kendisi geziyor ve **39 ekran görüntüsü** alıyor. Bir tur yaklaşık 14 dakika sürüyor. Depo herkese açık olduğu için ücret yok. Claude bu turu sizin yardımınız olmadan istediği zaman başlatabilir.
- **Ücretli öneri: Appetize.io.** Uygulama tarayıcıda her an açık duran bir simülatörde çalışır. Hazırlığı yapıldı; sizin bir anahtar eklemeniz yeterli. Önce **ücretsiz planla** başlayın, yetmezse **Starter** plana geçin. Pricing sayfasında Starter **59 $/ay** görünüyor (yıllık 708 $). Ücretsiz planda ayda 30 dakika var. Starter'da ayda 500 dakika var, aşan her dakika 0,06 $.

## 1) Ücretsiz yedek: çalışıyor

- **Nasıl çalışır:** `Simulator screenshots` iş akışı (`.github/workflows/sim-screens.yml`) her turda şunları yapar:
  - simülatörü açar,
  - uygulamayı kurar,
  - konum iznini önceden verir, böylece izin penceresi ekranı kapatmaz (konum Ankara olarak ayarlanır),
  - şu sayfaları gezer: Profil karşılama, Hava Durumu, Pro Ayarlar, Hedef, Araçlar, Hesaplayıcılar, Profil Oluştur (PCP ve Ateşli),
  - deneme profilini kaydedip Hava Durumu, Pro Ayarlar, Hedef ve Tablo sayfalarını dolu hâliyle tekrar gezer.

  Uzun sayfalar ekran ekran aşağı kaydırılarak çekilir.
- **İlk sonuç:** [PR #93'te](https://github.com/sniperTurk/flutter-app/actions/runs/38126427648) tur **başarılı** bitti. Her adım geçti ve 39 PNG alındı.
- **Ekran görüntülerinin yeri:** `ci/sim-screens` dalındaki `latest/` klasörü. Dalın `README.md` dosyasında her resmin bağlantısı var. Örnek: `https://raw.githubusercontent.com/sniperTurk/flutter-app/ci/sim-screens/latest/01_profil_karsilama.png`
- **Claude nasıl kullanır:**
  - Bu PR birleştirilince Claude iş akışını başlatır (Actions → Simulator screenshots → Run workflow). İstediği dalı (`ref`) veya kendi yazdığı başka bir gezinti testini (`test`) seçebilir.
  - Tur bitince resimleri `ci/sim-screens` dalından okur.
  - Bu PR'da da iş akışı, kendi dosyaları her değiştiğinde kendiliğinden çalışır.
- **Sınır:** bu yol sürekli açık bir simülatör değildir. Her istek yaklaşık 14 dakikalık bir turdur. Turda neye dokunulacağı testte yazılıdır, Claude gerekirse bu testi değiştirir.

## 2) Ücretli seçenekler (yalnızca resmî sayfalardan)

| Servis | En ucuz uygun plan | Ücretsiz kota | İmzasız simülatör derlemesi | Claude dokunup ekran görüntüsü alabilir mi | Oturum sınırı |
|---|---|---|---|---|---|
| **Appetize.io** | Starter 59 $/ay (yıllık 708 $) | Ayda 30 dk | **Evet**, kabul ettiği tek biçim bu (.app'in zip'i) | Evet: JS/Playwright SDK ile tap, swipe, screenshot. Flutter desteğini açıkça yazıyor | Boşta kalma süresi 30 sn ile 2 saat arası ayarlanabilir |
| Sauce Labs | Virtual Device Cloud 149 $/ay (yıllık ödeme) ya da 199 $ aylık | 28 gün, 60 dk | Evet (simülatörde .app zip) | Evet (Appium) | En çok 3 saat, boşta en çok 1000 sn |
| BrowserStack | App Automate 199 $/ay (yıllık ödeme) | 100 dk | **Hayır**: gerçek cihaz, imzalı .ipa | Evet (Appium) | En çok 2 saat, boşta 90 sn |
| AWS Device Farm | Dakikası 0,17 $ ya da 250 $/ay sınırsız | Bir kerelik 1000 dk | **Hayır**: imzalı cihaz .ipa | Evet (Appium) | En çok 150 dk, boşta 5 dk |
| Firebase Test Lab | Fiziksel cihazda saati 5 $ | Günde 5 test | **Hayır**: cihaz XCTest paketi | **Hayır**, yalnız toplu test çalıştırır. iOS desteği 30.09.2027'de kapanıyor | Test başına 45 dk |
| LambdaTest (yeni adı TestMu AI) | Virtual Automation 139 $/ay (yıllık ödeme) | 100 dk (ömür boyu) | iOS simülatörü beta aşamasında, satış ekibinden istenmesi gerekiyor | Evet (Appium) | Resmî sayfada bulunamadı |

**Neden Appetize:**
- En ucuz seçenek.
- İmza gerektirmeyen tek kolay yol: `flutter build ios --simulator` çıktısını doğrudan alıyor.
- CI'dan tek bir istekle yeni sürüm yüklenebiliyor.
- Flutter ekranlarını tanıdığını resmî olarak yazıyor.

**Doğrulanamayan nokta:** Appetize'in ücretsiz planında API ile yükleme ve otomasyon yapılıp yapılamadığı resmî sayfalarda açıkça yazmıyor.

Kaynaklar: appetize.io/pricing, docs.appetize.io (REST API, iOS yükleme, JS SDK, API tokens), browserstack.com/pricing, saucelabs.com/pricing, aws.amazon.com/device-farm/pricing, firebase.google.com/docs/test-lab, testmuai.com/pricing.

## 3) Appetize hazırlığı (bu PR'da)

- **Ne yapar:** `.github/workflows/appetize-upload.yml`, main'e her birleştirmeden ve her başarılı TestFlight çalışmasından sonra simülatör sürümünü derleyip Appetize'e yükler. Hep aynı uygulamanın yerine yükler, yani bağlantı değişmez.
- **Anahtar yoksa:** Linux üzerinde yalnızca uyarı verip durur. Mac makinesi hiç açılmaz.
- **Google Maps:** bu sürümde kapalıdır (Esri haritası kullanılır). Maps anahtarı TestFlight dışına çıkmaz.

## 4) Sahibinin yapacakları (Appetize için)

1. https://appetize.io adresinden hesap açın ve **Free** planla başlayın. Kart bilgisini yalnızca siz girersiniz. Dakika yetmezse **Starter** (59 $/ay) planına geçin.
2. Appetize'de **Organization → API Tokens → Generate API Token** yolunu izleyip bir anahtar üretin ve kopyalayın.
3. GitHub'da şu adımları izleyin:
   - **sniperTurk/flutter-app → Settings → Secrets and variables → Actions → New repository secret**
   - Name: `APPETIZE_API_TOKEN`
   - Secret: kopyaladığınız anahtar
   - **Add secret**'e basın.
4. Bu PR'ı birleştirin. Sonra **Actions → Appetize upload → Run workflow**'a basın. Çalışmanın özetinde `https://appetize.io/app/...` bağlantısı çıkar. Uygulamayı bu bağlantıdan tarayıcıda açabilirsiniz.
5. (İsteğe bağlı) Claude'un Appetize'i doğrudan kullanabilmesi için şunlar gerekli:
   - Claude ayarlarında (Admin settings → Capabilities → ağ erişimi) `appetize.io`, `api.appetize.io` ve `js.appetize.io` adreslerine izin verin. Bu ortamdan Appetize'e şu an erişim kapalı (denendi, engellendi).
   - Claude GitHub'daki gizli anahtarı okuyamaz. Bu yüzden Appetize'e Claude'un erişimi ya bir GitHub iş akışı üzerinden olur ya da uygulamayı "public run" yaparak olur.

## Durum özeti

| İş | Durum |
|---|---|
| Ücretsiz simülatör turu (`sim-screens.yml`) | **PASS**: [çalışma 38126427648](https://github.com/sniperTurk/flutter-app/actions/runs/38126427648), 39 PNG, `ci/sim-screens` dalında |
| Appetize yükleme (`appetize-upload.yml`) | **ÇALIŞTIRILMADI**: `APPETIZE_API_TOKEN` henüz yok |
| Appetize'e bu ortamdan erişim | **BLOCKED**: ağ izni yok (proxy 403) |
