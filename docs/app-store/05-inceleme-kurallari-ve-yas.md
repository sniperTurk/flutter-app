# 05 · App Review kuralları (silah içeriği), yaş derecelendirmesi ve riskler

> Yalnızca Apple'ın resmî sayfaları kullanıldı (2026-10-11'de okundu).
> Alıntılar İngilizce asıl metinden; özetler Türkçe. Bu bir hukuki görüş
> değildir; nihai karar App Review'undur.

## 1. İlgili maddeler

| Madde | Asıl metin (kısaltılmış alıntı) | SNIPER TÜRK için anlamı |
|---|---|---|
| **1.1.3** | "Depictions that encourage illegal or reckless use of weapons and dangerous objects, or facilitate the purchase of firearms or ammunition." | Silahı yasa dışı/pervasız kullanmaya teşvik eden görsel ve metin yok; satın almaya aracılık yok. Kodda fiyat, sepet, satış bağlantısı yok; katalog kaynak URL'leri ekranda gösterilmiyor ve tıklanamıyor (`url_launcher`/webview bağımlılığı yok). **Uygun**, metinlerde de satış çağrışımı olmamalı. |
| **1.1.2** | "Realistic portrayals of people or animals being killed, maimed, tortured, or abused, or content that encourages violence." | Uygulamada insan/hayvan görseli yok; hedef görünümü soyut halka/retikül. Ekran görüntüleri ve açıklamada av hayvanı veya insan hedef **kullanılmamalı**. |
| **2.3.8** | "...select images that don't depict a gruesome death or a gun pointed at a specific character." | Ekran görüntüsü ve simgede bir kişiye/canlıya doğrultulmuş silah olmamalı. |
| **1.4 / 1.4.5** | "If your app behaves in a way that risks physical harm, we may reject it." / "...use their devices in a way that risks physical harm..." | Balistik sonuçlar yanlışsa fiziksel risk doğabilir. Açıklamada ve uygulamada "hesap yardımcısıdır, gerçek atışla doğrulayın" uyarısı var (Tablo ekranında da). **Korunmalı**; "en doğru", "kesin isabet" gibi doğrulanamayan iddia yazılmamalı. |
| **1.1.6** | "False information and features, including inaccurate device data..." | Pusula, su terazisi ve harita mesafesi gerçek sensör/veri kullanıyor. Doğruluk iddiası yazılmamalı. |
| **2.3 / 2.3.1(a)** | "...make sure all your app metadata, including privacy information, your app description, screenshots, and previews accurately reflect the app's core experience" / gizli özellik olmamalı | Arayüz yalnız Türkçe → İngilizce sayfada belirtilmeli. Google Maps derlemeye bağlı → gizlilik beyanı buna göre (02). |
| **2.3.3** | "Screenshots should show the app in use, and not merely the title art, login page, or splash screen." | Planda yalnızca kullanım ekranları var (06). |
| **2.3.6** | "Answer the age rating questions in App Store Connect honestly..." | Aşağıdaki yaş önerisi. |
| **2.3.7** | "App names must be limited to 30 characters." / alt başlıkta doğrulanamayan iddia yok | Öneriler 30 karakter içinde (01). |
| **5.1.1(i)** | "All apps must include a link to their privacy policy in the App Store Connect metadata field and within the app in an easily accessible manner." | **AÇIK RİSK:** uygulama içinde gizlilik politikası bağlantısı bulunamadı. Bkz. Riskler #1. |
| **5.1.1(ii)** | "Ensure your purpose strings clearly and completely describe your use of the data." | İzin metinlerinde eksikler var (04). |
| **5.1.1(iii)** | "...use the out-of-process picker or a share sheet rather than requesting full access..." | PHPicker ve paylaş sayfası kullanılıyor. **Uygun.** |
| **5.1.2(i)** | "You must clearly disclose where personal data will be shared with third parties..." | Politika MET Norway, Esri, Google, Nominatim'i adıyla yazmalı (03). |
| **5.1.5** | "Use Location Services in your app only when it is directly relevant to the features..." / "...explain the purpose in your app" | Konum yalnızca ilgili özelliklerde; amaç metni genişletilmeli (04). |
| **5.2** | "Laws differ in different countries and regions..." | Silah mevzuatı ülkeye göre değişir; yayın ülkeleri sahip tarafından seçilmeli. |

Not: Kurallarda ateşli silah *balistik hesaplayıcısını* doğrudan yasaklayan
veya özel izin isteyen bir madde **bulunmadı**. 5.3 ve 5.4'teki "lisans"
şartları kumar ve VPN içindir, bu uygulamaya uygulanmaz.

## 2. Yaş derecelendirmesi önerisi

Resmî tabloya göre (Age ratings values and definitions):
- **9+**: "Infrequent guns or other weapons"
- **13+**: "Frequent guns or other weapons", "Infrequent realistic violence"
- **18+**: "Frequent realistic violence"
- Tanım: "Guns or Other Weapons: References to or depictions of guns,
  weapons, or objects that may cause bodily harm."

Uygulamanın tamamı tüfek, mühimmat ve dürbün üzerine; silah referansı
sürekli. Bu yüzden "Guns or Other Weapons" için **Frequent** seçilmesi dürüst
cevaptır → sonuç **13+**.

Önerilen anket cevapları:

| Soru grubu | Cevap |
|---|---|
| Guns or Other Weapons | **Frequent** |
| Realistic Violence | None (insan/hayvana zarar tasviri yok) |
| Cartoon or Fantasy Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity, Horror, Mature/Suggestive, Sexual Content, Nudity | None |
| Alcohol, Tobacco, Drug Use | None |
| Medical or Treatment Information / Health & Wellness | None |
| Simulated Gambling, Contests, Loot Boxes | None |
| Unrestricted Web Access | No (webview/tarayıcı yok) |
| User-Generated Content, Messaging/Chat, Social Media | No |
| Advertising | No |
| Parental Controls / Age Assurance | No |

**Öneri: 13+ (anket sonucu).** Sahip isterse daha yüksek bir yaş sınırı
tercih edebilir; App Store Connect'te daha yüksek derece seçme seçeneğinin
varlığı bu çalışmada resmî kaynaktan **doğrulanmadı**, girişte kontrol
edilmeli. Türkiye'de ateşli silah ruhsatı yetişkinlere verildiği için
sahibin yerel beklentiye göre değerlendirmesi önerilir.

## 3. Riskler (önem sırasıyla)

1. **Uygulama içi gizlilik bağlantısı yok (5.1.1(i)) — YÜKSEK.** Kural
   bağlantının uygulama içinde de kolay erişilebilir olmasını istiyor.
   Öneri (ayrı bir kod PR'ı, sahip onayıyla): Profil veya Araçlar
   sekmesine "Gizlilik politikası" satırı. `url_launcher` yoksa metnin
   kendisi uygulama içinde gösterilebilir.
2. **Gizlilik beyanı ile gerçek davranış uyuşmazlığı (2.3, 5.1.2) — YÜKSEK.**
   Google Maps SDK beyanları etikette ve politikada yok; yayındaki politika
   eski (02, 03).
3. **Eksik izin metinleri (5.1.1(ii)) — ORTA.** Konum harita için de
   isteniyor, kamera eğim ölçümünde de açılıyor; metinler bunu söylemiyor (04).
4. **"Sniper" kelimesi — ORTA/BELİRSİZ.** Kurallarda yasak bir kelime değil;
   ancak 1.1.3 açısından inceleyici dikkatini çekebilir. Ad, açıklama ve
   görsellerde yalnızca spor/av atıcılığı ve hesap yardımcısı çerçevesi
   korunmalı; askerî/insan hedef çağrışımı olmamalı. Ret gelirse yedek ad
   önerisi: `Türk Balistik Hesap` (19 karakter). Marka/ticari ad uygunluğu
   ayrıca sahipçe kontrol edilmeli.
5. **Fiziksel zarar algısı (1.4) — ORTA.** Uyarı metinleri korunmalı; inceleme
   notunda uygulamanın hesap yardımcısı olduğu, silah/mühimmat satmadığı ve
   yasal uyumun kullanıcıda olduğu belirtilmeli.
6. **Dil (2.3) — DÜŞÜK.** Arayüz Türkçe; İngilizce açıklamada yazıldı.
7. **Ülke seçimi (5.2) — DÜŞÜK/SAHİP.** Silah içeriği bazı ülkelerde yerel
   kurallara tabi olabilir; yayın ülkeleri sahip tarafından seçilmeli.

## 4. App Review notu taslağı (Notes alanı için)

```
SNIPER TÜRK is a ballistic calculator for sport and hunting shooters (centerfire rifles and PCP air rifles). It computes bullet trajectory and scope corrections from user-entered rifle, ammunition and weather data. It does not sell, advertise or link to the sale of firearms or ammunition, and contains no depictions of violence. No account or login is required. The interface is in Turkish.

How to test: open the Profil tab, tap "Yeni profil", pick a rifle and ammunition from the lists and save. Then open the Hedef tab to see turret clicks and the reticle view. Location (optional) is used for weather (Hava Durumu), Coriolis/local gravity and to centre the map in Araçlar > Haritadan mesafe.
```

## Kaynaklar

- App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- Age ratings values and definitions: https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions
- Set an app age rating: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/
