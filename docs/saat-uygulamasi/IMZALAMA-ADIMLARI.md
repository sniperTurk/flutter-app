# Apple Watch: sahibinin yapacağı hesap ve imzalama adımları

Bu adımlar sahibinin Apple Developer hesabında yapılır. Claude hesaba
girmedi, App ID/profil oluşturmadı, TestFlight'a bir şey göndermedi.

Şu anki durum: saat uygulaması ayrı bir Xcode projesi olarak (XcodeGen)
yalnızca simülatör için, imzasız derlenir. iPhone uygulamasına gömülmedi;
mevcut TestFlight akışı (`ios-testflight.yml`) ve imzalı IPA denetimleri
değişmedi.

## 1. App ID (developer.apple.com → Certificates, Identifiers & Profiles)

1. Identifiers → "+" → App IDs → App.
2. Bundle ID (Explicit): `com.sniperturk.sniperTurk.watchkitapp`
   (iOS uygulamasının bundle id'si + `.watchkitapp`; Apple'ın kuralı).
3. Ek capability gerekmiyor (App Group yalnızca komplikasyon/widget eklenirse).

Not: TestFlight iş akışı App Store Connect API anahtarı ve bulut tarafından
yönetilen otomatik imzalama kullanıyor. Otomatik imzalama yeni bundle id'yi
kendisi kaydedebilir; yine de App ID'yi elle açmak hatayı erkenden gösterir.

## 2. Saat uygulamasını iPhone uygulamasına gömme (ayrı PR, sahibi onaylayınca)

1. `tools/bootstrap_ios_scaffold.sh` sonrasına (yeni bir yapılandırıcı ile)
   saat hedefini Runner projesine ekle: hedef türü watchOS App, bundle id
   yukarıdaki, `WKCompanionAppBundleIdentifier = com.sniperturk.sniperTurk`,
   Runner'da "Embed Watch Content" aşaması.
2. Köprüyü kalıcı yap: `tools/configure_ios_watch_bridge.py` ve `.rb`
   bootstrap'a eklenir (şu an yalnızca `watch-sim.yml` çalıştırıyor).
3. Repo'daki imza denetimlerini güncelle: `tools/verify_signed_app_store_ipa.py`,
   `tools/verify_ios_archive_signing_state.py`, export seçenekleri
   (`tools/export_signed_app_store_ipa.sh`) ikinci bir bundle id ve profil
   görecek; testleri (`test_v31x_*`) buna göre genişletilmeli.
4. Saat uygulaması için simge (AppIcon, watchOS boyutları) eklenmeli;
   App Store yüklemesi simgesiz kabul etmez.
5. App Store Connect: saat uygulaması iOS uygulamasıyla aynı kayıtta
   yayımlanır; Apple Watch ekran görüntüleri istenir.

## 3. Gerçek cihazda doğrulama (sahibinde saat yok)

Apple'ın WatchConnectivity örneği gerçek iPhone + Apple Watch ile test
edilmesini söyler. Simülatör derlemesi yalnızca derlenebildiğini kanıtlar.
Saat edinilince kontrol listesi:

- [ ] Saat uygulaması kurulu, telefonda Atış açık → saatte aynı klik.
- [ ] Telefonda mesafe değişince saat 1–2 sn içinde güncellenir.
- [ ] Saatten mesafe → telefon yeni çözümü gönderir (telefon ekranı açıkken).
- [ ] Telefon ekranı kilitliyken saatten mesafe: telefon uygulaması yeniden
      çizilene kadar yeni çözüm gitmez (bilinen sınır, aşağıya bkz.).
- [ ] 2 dakika sonra "Veri eski" uyarısı.

Bilinen sınır: kule düzeltmesi Atış ekranının kendisinde hesaplanıyor
(hesap koduna dokunulmadı). Bu yüzden telefon uygulaması ön planda ve Atış
sekmesi açıkken saat güncel kalır.
