# 01 · Mağaza metinleri

> TASLAK — App Store Connect'e hiçbir şey girilmedi; sahip elle girer.
> Ad ve alt başlık **sahip tarafından seçildi (2026-10-14, 10:26–10:30
> İstanbul)**. Açıklama, tanıtım metni ve anahtar kelimeler `main @ 69e8a0e`
> (2026-10-14) uygulamasına göre yeniden yazıldı; önceki taslak `835b956`
> içindi. Sınırlar Apple'ın resmî App Store Connect yardım sayfalarından
> alındı (aşağıda "Kaynaklar"). Sayılar `python3 docs/app-store/check_lengths.py`
> ile denetlenir.

## Sınırlar (resmî)

| Alan | Sınır | Not |
|---|---|---|
| Ad (Name) | 2–30 karakter | Mağazada benzersiz olmalı |
| Alt başlık (Subtitle) | 30 karakter | Doğrulanamayan iddia yok, başka uygulamaya atıf yok (2.3.7) |
| Tanıtım metni (Promotional Text) | 170 karakter | Sürüm göndermeden değiştirilebilir |
| Açıklama (Description) | 4000 karakter | |
| Anahtar kelimeler (Keywords) | **100 bayt** | Karakter değil bayt: ü, ş, ğ, ı, ç, ö, â UTF-8'de 2 bayttır |
| Yenilikler (What's New) | 4000 karakter | İlk sürümde App Store Connect bu alanı istemeyebilir; yine de hazır |
| Destek / Pazarlama URL | tam URL, protokol dahil | Destek URL zorunlu, pazarlama URL isteğe bağlı |

## Uygulama dili hakkında önemli not

Uygulamanın arayüzü yalnızca **Türkçe**. İngilizce sayfa yayınlanacaksa
açıklamada bunu açıkça söylemek gerekir; yoksa 2.3 (meta veri, uygulamanın
gerçek deneyimini yansıtmalı) açısından risk oluşur. İngilizce açıklamada bu
cümle var.

---

## Türkçe (tr)

### Ad önerileri (≤ 30)

| # | Öneri | Karakter | Durum |
|---|---|---|---|
| **Seçilen** | `Sniper Türk: Balistik` | 21 | SEÇİLDİ — sahip, 2026-10-14 |
| A | `SNIPER TÜRK: Balistik` | 21 | seçilmedi (aynı ad, büyük harfle) |
| B | `SNIPER TÜRK Balistik Hesap` | 26 | seçilmedi |
| C | `Sniper Türk – Atış Çözümü` | 25 | seçilmedi |

Not: cihazdaki görünen ad (`CFBundleDisplayName`) `SNIPER TÜRK` olarak
kalır; mağaza adı ondan farklı olabilir. "Sniper" kelimesinin riski için bkz.
`05-inceleme-kurallari-ve-yas.md`.

### Alt başlık önerileri (≤ 30)

| # | Öneri | Karakter | Durum |
|---|---|---|---|
| **Seçilen** | `Ateşli ve PCP Tüfekler İçin` | 27 | SEÇİLDİ — sahip, 2026-10-14 |
| A | `Tüfek ve PCP balistik çözüm` | 27 | seçilmedi |
| B | `DOPE, rüzgâr, kule düzeltmesi` | 29 | seçilmedi |
| C | `Ateşli ve havalı tüfek hesabı` | 29 | seçilmedi |

### Tanıtım metni (≤ 170)

```
Tüfeğini, dürbününü ve mühimmatını listeden seç; hava ve mesafeye göre kule kliklerini ve retikül tutuşunu tek ekranda gör. Hesap istemez, profillerin cihazında kalır.
```

### Açıklama

```
Sniper Türk, ateşli tüfek ve PCP havalı tüfek kullanan atıcılar için bir balistik hesap yardımcısıdır. Tüfek, dürbün ve mühimmat bilgilerini bir profilde toplar; hava koşullarına göre mermi yolunu hesaplar ve sonucu dürbündeki kule klikleri ve retikül üzerinde gösterir. Uygulamanın dili Türkçedir.

PROFİL
• Ateşli tüfek ve PCP için ayrı profiller
• Tüfek marka, model ve kalibresi, dürbün, retikül ve mühimmat listeden seçilir; aradığınız listede yoksa elle girilir
• Ateşli tüfekte G1, G2, G5, G6, G7, G8, GI ve RA4; PCP'de G1, G7 ve GS sürüklenme modelleri. Saçmalar (pellet) G1 ile hesaplanır
• İsterseniz merminin kendi Mach–Cd eğrisi (.drg/.csv)
• Her kutunun yanındaki ⓘ, değerin ne olduğunu, nereden bulunacağını ve tipik bir örneği anlatır
• Profilleri dosya olarak yedekleme ve geri yükleme (iCloud Drive, Google Drive veya Dosyalar)

HAVA DURUMU
• Sıcaklık, nem ve rüzgâr hızı konumdan hava servisiyle (MET Norway) ya da elle
• Basınç telefonun barometresinden, irtifa GPS'ten
• Rüzgâr yönü saat kadranında seçilir; "Rüzgâr tahmini nasıl yapılır?" rehberi

PRO
• Açı (telefon kamerasıyla eğim ölçümü), dürbün eğimi, rüzgâr düzeltmesi
• Coriolis, yerel yerçekimi, hareketli hedef, isabet olasılığı (WEZ)
• Sıfır ofseti, kule ölçek katsayısı, mermi uzunluğuyla spin drift
• Her ayarın açıklaması alttan açılan sayfada: Ne? Neden önemli? Nasıl?

HEDEF
• Seçilen mesafe için yukarı/aşağı ve sağ/sol kule klikleri (MOA veya MRAD)
• Retikül üzerinde tutuş noktası; FFP/SFP dürbünde büyütmeye göre
• Hesap dökümü: düşüş ve yan sapmanın hangi etkilerden geldiği
• PDF olarak paylaşılabilen DOPE kartı

ARAÇLAR
• Hız Doğrulama ve Kronograf: namlu hızını sahada düzeltme, hız serisi (ortalama, SD, ES)
• Sight Height: dürbün eksen yüksekliğini ölçme veya yan fotoğraftan bulma
• Haritadan mesafe: uydu haritasında nişancı ve hedef seçip mesafe ve yön
• Hava & Rüzgâr, Pusula, Su Terazisi, İsabet Olasılığı
• Paralaks Mesafesi (PCP) ve Avcı Sıfırı
• Atış Öncesi Kontrol, Sıfır Grubu, Atış Günlüğü
• Hesaplayıcılar: stadyametrik mesafe, retikül, mesafedeki MOA, klik değeri doğrulama, iki hızdan balistik katsayı, enerji ve güç, hava laboratuvarı, birim dönüştürücüler
• Kullanım rehberi

GİZLİLİK
Hesap açmanız gerekmez. Reklam ve izleme yoktur. Profilleriniz ve ayarlarınız yalnızca cihazınızda saklanır. Harita için Google Maps SDK kullanılır. Ayrıntılar uygulamadaki Gizlilik politikası sayfasındadır.

ÖNEMLİ
Sniper Türk bir hesap yardımcısıdır; sonuçlar gerçek atışla doğrulanmalıdır. Uygulama silah veya mühimmat satmaz, satışa aracılık etmez. Silah ve atışla ilgili tüm yasal düzenlemelere ve güvenlik kurallarına uymak kullanıcının sorumluluğundadır.
```

### Anahtar kelimeler (≤ 100 bayt)

Ad ve alt başlıktaki kelimeler (sniper, türk, balistik, ateşli, ve, pcp,
tüfekler, için) tekrar edilmedi; Apple bunları zaten aramaya katar
(`check_lengths.py` bunu denetler).

```
dope,dürbün,retikül,rüzgar,kule,klik,moa,mil,menzil,atış,mermi,havalı,coriolis,avcı,saçma
```

### Yenilikler (1.0.0)

```
İlk sürüm.
• Ateşli tüfek ve PCP profilleri, listeden seçilen tüfek, dürbün ve mühimmat
• Hava ve rüzgâra göre kule klikleri ve retikül tutuşu
• Pro: açı, Coriolis, yerel yerçekimi, spin drift, hareketli hedef, isabet olasılığı
• PDF DOPE kartı ve profil yedekleme
• Araçlar: hız doğrulama, kronograf, Sight Height, haritadan mesafe, pusula, su terazisi
```

---

## English (en-US)

### Name options (≤ 30)

| # | Option | Chars | Status |
|---|---|---|---|
| **Chosen** | `Sniper Türk: Ballistics` | 23 | CHOSEN — translation of the owner's TR choice (2026-10-14); owner confirms |
| A | `SNIPER TÜRK: Ballistics` | 23 | not chosen |
| B | `SNIPER TÜRK Ballistic Solver` | 28 | not chosen |

### Subtitle options (≤ 30)

| # | Option | Chars | Status |
|---|---|---|---|
| **Chosen** | `For Firearms and PCP Rifles` | 27 | CHOSEN — translation of the owner's TR choice (2026-10-14); owner confirms |
| A | `Rifle & PCP ballistic solver` | 28 | not chosen |
| B | `DOPE, wind and turret clicks` | 28 | not chosen |

### Promotional text (≤ 170)

```
Pick your rifle, scope and ammo from built-in lists and see turret clicks and reticle holds for the weather and range. No account; profiles stay on your device.
```

### Description

```
Sniper Türk is a ballistic calculator for shooters who use centerfire rifles and PCP air rifles. It keeps your rifle, scope and ammunition in one profile, computes the trajectory for the current weather and shows the result as turret clicks and a hold point on your reticle.

Language: the app's interface is in Turkish only.

PROFILES
• Separate profiles for firearms and PCP air rifles
• Pick rifle make, model and caliber, scope, reticle and ammunition from built-in lists; type them in when yours is not listed
• G1, G2, G5, G6, G7, G8, GI and RA4 drag models for firearms; G1, G7 and GS for PCP. Pellets are calculated with G1
• Optionally the bullet's own Mach–Cd drag curve (.drg/.csv)
• An ⓘ next to every field explains the value, where to find it and a typical example
• Back up and restore profiles as a file (iCloud Drive, Google Drive or Files)

WEATHER
• Temperature, humidity and wind speed from a weather service (MET Norway) for your location, or typed in
• Pressure from the phone's barometer, altitude from GPS
• Clock-face wind direction and a short guide to estimating wind

PRO
• Shot angle (measured with the phone camera), scope cant, wind bracket
• Coriolis, local gravity, moving target, hit probability (WEZ)
• Zero offset, turret scale factor, spin drift from bullet length
• Every setting explained in a bottom sheet: what, why it matters, how

TARGET
• Elevation and windage turret clicks (MOA or MRAD) for the chosen range
• Hold point on the reticle, magnification-aware for FFP and SFP scopes
• Breakdown of which effects make up drop and drift
• DOPE card you can share as PDF

TOOLS
• Velocity truing and chronograph strings (average, SD, ES)
• Sight height: measure it or derive it from a side photo
• Distance from map: pick shooter and target on a satellite map
• Weather & wind, compass, level, hit probability
• Parallax range (PCP) and maximum point-blank range
• Pre-shot checklist, zero group, shot journal
• Calculators: stadiametric range, reticle, MOA at distance, click value check, BC from two velocities, energy and power, air lab, unit converters
• Usage guide

PRIVACY
No account needed. No ads, no tracking. Your profiles and settings are stored only on your device. The map uses the Google Maps SDK. Details are in the privacy policy inside the app.

IMPORTANT
Sniper Türk is a calculation aid; always confirm results with live fire. The app does not sell or broker firearms or ammunition. You are responsible for following all firearm laws and safety rules that apply to you.
```

### Keywords (≤ 100 bytes)

Words in the chosen name and subtitle (sniper, türk, ballistics, for,
firearms, and, pcp, rifles) are not repeated.

```
dope,scope,reticle,wind,turret,click,moa,mil,range,shooting,bullet,airgun,coriolis,hunting,pellet
```

### What's New (1.0.0)

```
First release.
• Firearm and PCP profiles with rifle, scope and ammo picked from lists
• Turret clicks and reticle holds for weather and wind
• Pro: shot angle, Coriolis, local gravity, spin drift, moving target, hit probability
• PDF DOPE card and profile backup
• Tools: velocity truing, chronograph, sight height, distance from map, compass, level
```

---

## URL yer tutucuları (sahip doldurur)

| Alan | Değer | Durum |
|---|---|---|
| Destek URL (zorunlu) | `https://<DESTEK_ALAN_ADI>/destek` | **YER TUTUCU** |
| Pazarlama URL (isteğe bağlı) | `https://<PAZARLAMA_ALAN_ADI>/` | **YER TUTUCU** |
| Gizlilik politikası URL (zorunlu) | Depo değişkeni `PRIVACY_POLICY_URL` ile aynı | Var (CI ön kontrolü geçiyor); içerik `03-gizlilik-politikasi.md`'ye göre güncellenmeli. Uygulama içinde göstermek için derlemede `--dart-define=PRIVACY_POLICY_URL=…` verilebilir |
| Telif (Copyright) | `2026 <SAHİP ADI>` | **YER TUTUCU** |

## Doğrulama

```
python3 docs/app-store/check_lengths.py
```

Komut her metin bloğunun sınırını, ad/alt başlık karakter sayılarını ve
anahtar kelimelerin seçilen ad/alt başlıktaki kelimeleri tekrar etmediğini
denetler; sınır aşımı varsa hata koduyla biter. Çıktı
`docs/reports/gizlilik_magaza.md` raporundadır.

## Kaynaklar

- App information (Ad 30, Alt başlık 30): https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- Platform version information (Tanıtım 170, Açıklama 4000, Anahtar kelime 100 bayt, Yenilikler 4000, URL'ler): https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- App Review Guidelines 2.3, 2.3.7: https://developer.apple.com/app-store/review/guidelines/
