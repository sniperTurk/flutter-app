# 01 · Mağaza metinleri (TASLAK)

> TASLAK — App Store Connect'e hiçbir şey girilmedi. Sahip okuyup seçtikten
> sonra elle girilir. Sınırlar Apple'ın resmî App Store Connect yardım
> sayfalarından alındı (aşağıda "Kaynaklar"). Karakter ve bayt sayıları
> `python3` ile sayıldı (bkz. dosya sonu).

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
gerçek deneyimini yansıtmalı) açısından risk oluşur. Aşağıdaki İngilizce
açıklamaya bu cümle eklendi.

---

## Türkçe (tr)

### Ad önerileri (≤ 30)

| # | Öneri | Karakter |
|---|---|---|
| A (önerilen) | `SNIPER TÜRK: Balistik` | 21 |
| B | `SNIPER TÜRK Balistik Hesap` | 26 |
| C | `Sniper Türk – Atış Çözümü` | 25 |

Not: cihazdaki görünen ad (`CFBundleDisplayName`) zaten `SNIPER TÜRK`;
mağaza adı ondan uzun olabilir. "Sniper" kelimesinin riski için bkz.
`05-inceleme-kurallari-ve-yas.md`.

### Alt başlık önerileri (≤ 30)

| # | Öneri | Karakter |
|---|---|---|
| A (önerilen) | `Tüfek ve PCP balistik çözüm` | 27 |
| B | `DOPE, rüzgâr, kule düzeltmesi` | 29 |
| C | `Ateşli ve havalı tüfek hesabı` | 29 |

### Tanıtım metni (≤ 170)

```
Profilini bir kez kur; hava, rüzgâr ve mesafeye göre kule klik değerini, retikül tutuşunu ve DOPE tablosunu tek ekranda gör. Hesap ve veriler cihazında kalır.
```

### Açıklama

```
SNIPER TÜRK, ateşli tüfek ve PCP havalı tüfek kullanan atıcılar için bir balistik hesap yardımcısıdır. Tüfek, dürbün ve mühimmat bilgilerini bir profilde toplar; ortam koşullarına göre mermi yolunu hesaplar ve sonucu dürbündeki kule ve retikül üzerinde gösterir.

PROFİL
• Ateşli tüfek ve PCP için ayrı profil
• Tüfek, dürbün, retikül ve mühimmatı listeden seçme; listede yoksa elle girme
• G1, G7, GA ve RA4 sürüklenme modelleri; isterseniz kendi .drg/.csv sürüklenme eğriniz
• Dürbün yüksekliği, sıfırlama mesafesi, yiv yönü ve yiv oranı

HAVA DURUMU VE RÜZGÂR
• Sıcaklık, basınç, nem ve irtifayı elle girin veya konumunuzdan hava servisi (MET Norway) verisiyle doldurun
• Rüzgâr hızı ve saat yönüne göre rüzgâr yönü

HEDEF GÖRÜNÜMÜ
• Mesafeye göre yukarı/aşağı ve sağ/sol düzeltme
• Kule klik değeri (MOA veya MIL) ve retikül üzerinde tutuş noktası
• FFP/SFP dürbünlerde büyütmeye göre retikül görünümü
• Balistik tablo ve PDF olarak paylaşılabilen DOPE kartı

PRO AYARLAR
• Atış açısı, Coriolis, yerel yerçekimi, spin drift, hareketli hedef
• Barut sıcaklığı, sıfır ofseti, kule ölçek katsayısı, dürbün ve tüfek eğimi
• İsabet olasılığı (WEZ)

ARAÇLAR
• Hız doğrulama: sahada gözlenen düşümle namlu hızını düzeltme
• Sight Height: dürbün eksen yüksekliğini ölçme veya yan fotoğraftan bulma
• Haritadan mesafe: uydu haritasında nişancı ve hedef seçip mesafe ve yön
• Pusula, su terazisi, vuruş olasılığı
• Hesaplayıcılar: stadyametrik mesafe, retikül (mil-dot), mesafedeki MOA, tıklama değeri doğrulama, iki hızdan balistik katsayı, enerji ve güç, hava laboratuvarı

GİZLİLİK
Hesap açmanız gerekmez. Reklam ve izleme yoktur. Profilleriniz ve ayarlarınız yalnızca cihazınızda saklanır. Ayrıntılar gizlilik politikasındadır.

ÖNEMLİ
SNIPER TÜRK bir hesap yardımcısıdır; sonuçlar gerçek atışla doğrulanmalıdır. Uygulama silah veya mühimmat satmaz, satışa aracılık etmez. Silah ve atışla ilgili tüm yasal düzenlemelere ve güvenlik kurallarına uymak kullanıcının sorumluluğundadır.
```

### Anahtar kelimeler (≤ 100 bayt)

Ad ve alt başlıktaki kelimeler (sniper, türk, balistik, tüfek, pcp, çözüm)
tekrar edilmedi; Apple bunları zaten aramaya katar.

```
dope,dürbün,retikül,rüzgar,kule,klik,moa,mil,menzil,atış,mermi,havalı,coriolis,avcı
```

### Yenilikler (1.0.0)

```
İlk sürüm.
• Ateşli tüfek ve PCP profilleri
• Hava ve rüzgâra göre kule ve retikül düzeltmesi
• Balistik tablo ve PDF DOPE kartı
• Pro ayarlar: Coriolis, yerel yerçekimi, spin drift, hareketli hedef
• Araçlar: hız doğrulama, Sight Height, haritadan mesafe, pusula, su terazisi
```

---

## English (en-US)

### Name options (≤ 30)

| # | Option | Chars |
|---|---|---|
| A (recommended) | `SNIPER TÜRK: Ballistics` | 23 |
| B | `SNIPER TÜRK Ballistic Solver` | 28 |

### Subtitle options (≤ 30)

| # | Option | Chars |
|---|---|---|
| A (recommended) | `Rifle & PCP ballistic solver` | 28 |
| B | `DOPE, wind and turret clicks` | 28 |

### Promotional text (≤ 170)

```
Set up your rifle once and see turret clicks, reticle holds and a DOPE table for the current weather, wind and range. Your data stays on your device.
```

### Description

```
SNIPER TÜRK is a ballistic calculator for shooters who use centerfire rifles and PCP air rifles. It keeps your rifle, scope and ammunition in one profile, computes the trajectory for the current conditions and shows the result on your scope's turrets and reticle.

Language: the app's interface is in Turkish.

PROFILES
• Separate profiles for firearms and PCP air rifles
• Pick rifle, scope, reticle and ammunition from built-in lists, or type them in
• G1, G7, GA and RA4 drag models, or load your own .drg/.csv drag curve
• Sight height, zero range, twist direction and twist rate

WEATHER AND WIND
• Enter temperature, pressure, humidity and altitude, or fill them from a weather service (MET Norway) for your location
• Wind speed and clock-face wind direction

TARGET VIEW
• Elevation and windage correction for the chosen range
• Turret clicks (MOA or MIL) and the hold point on the reticle
• Magnification-aware reticle view for FFP and SFP scopes
• Ballistic table and a DOPE card you can share as PDF

PRO SETTINGS
• Shot angle, Coriolis, local gravity, spin drift, moving target
• Powder temperature, zero offset, turret scale factor, scope and rifle cant
• Hit probability (WEZ)

TOOLS
• Velocity truing from observed drop
• Sight height: measure it or derive it from a side photo
• Distance from map: pick shooter and target on a satellite map
• Compass, level, hit probability
• Calculators: stadiametric range, mil-dot reticle, MOA at distance, click value check, BC from two velocities, energy and power, air lab

PRIVACY
No account needed. No ads, no tracking. Your profiles and settings are stored only on your device. See the privacy policy for details.

IMPORTANT
SNIPER TÜRK is a calculation aid; always confirm results with live fire. The app does not sell or broker firearms or ammunition. You are responsible for following all firearm laws and safety rules that apply to you.
```

### Keywords (≤ 100 bytes)

```
dope,scope,reticle,wind,turret,click,moa,mil,range,shooting,bullet,airgun,coriolis,hunting,long
```

### What's New (1.0.0)

```
First release.
• Firearm and PCP profiles
• Turret and reticle correction for weather and wind
• Ballistic table and PDF DOPE card
• Pro settings: Coriolis, local gravity, spin drift, moving target
• Tools: velocity truing, sight height, distance from map, compass, level
```

---

## URL yer tutucuları (sahip doldurur)

| Alan | Değer | Durum |
|---|---|---|
| Destek URL (zorunlu) | `https://<DESTEK_ALAN_ADI>/destek` | **YER TUTUCU** |
| Pazarlama URL (isteğe bağlı) | `https://<PAZARLAMA_ALAN_ADI>/` | **YER TUTUCU** |
| Gizlilik politikası URL (zorunlu) | Depo değişkeni `PRIVACY_POLICY_URL` ile aynı | Var (CI ön kontrolü geçiyor); içerik `03-gizlilik-politikasi.md`'ye göre güncellenmeli |
| Telif (Copyright) | `2026 <SAHİP ADI>` | **YER TUTUCU** |

## Doğrulama

Sayılar şu komutla üretildi (bu dosyadaki kod bloklarından):

```
python3 docs/app-store/check_lengths.py
```

Çıktısı bu PR'ın açıklamasındadır. Ayrıca kendi başınıza
çalıştırabilirsiniz; sınır aşımı varsa komut hata koduyla biter.

## Kaynaklar

- App information (Ad 30, Alt başlık 30): https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- Platform version information (Tanıtım 170, Açıklama 4000, Anahtar kelime 100 bayt, Yenilikler 4000, URL'ler): https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- App Review Guidelines 2.3, 2.3.7: https://developer.apple.com/app-store/review/guidelines/
