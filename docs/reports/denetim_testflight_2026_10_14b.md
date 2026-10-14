# TestFlight öncesi uçtan uca hesap denetimi — 2026-10-14b

**Yüksek bulgu: 2**

**Karar: TestFlight başlamamalı.** İki yüksek bulgu açık (ATM-1, PRF-2). İkisinin de kökü önceki TestFlight'tan (237c14d) eski, ama CLAUDE.md kuralına göre yüksek bulgu açıkken TestFlight başlatılmaz. ATM-1'in etkisini #295 (F1) büyüttü.

- Tarih: 14.10.2026, İstanbul. Sahip 19:05'te "Kontrol başlat." dedi.
- Dal: `audit/testflight-2026-10-14b`. main'den, 7eb1416'dan açıldı; sonraki commit'ler dahil değil.
- Kapsam: 237c14d..7eb1416 arasında birleşen #289, #291, #295, #296, #298, #304, #305, #306, #307, #308.
- Tür: yalnız rapor ve test. `lib/` değişmedi; düzeltme yapılmadı, her düzeltme ayrı görev.

## Özet

| Önem | Sayı | Bulgular |
|---|---|---|
| Yüksek | 2 | ATM-1, PRF-2 |
| Orta | 10 | KUL-1, KUL-2, RUZ-1, RUZ-2, RUZ-3 (şüphe), MUH-1, MUH-2, PRF-1, PRF-3, PRF-4 |
| Düşük | 7 | KUL-3, ATM-2, ATM-3, MUH-3, MUH-4, MUH-5, PRF-5 |

- RUZ-3 dışındaki 18 bulgunun toplam 20 testi var. Testler `skip` ile kapatıldı, takım yeşil kalıyor.
- `skip` kaldırılınca bu 20 testin hepsi CI'da gerçekten düştü; düşme nedeni hep bulgudaki fark oldu, test hatası değil (aşağıda "Testler").
- RUZ-3 çevrimdışı test edilemez; canlı bir istek gerekir.

## Değişiklik başına tablo

| PR | Ne kontrol edildi | Bağımsız kaynak | Sonuç |
|---|---|---|---|
| #295 F1 (basınç irtifadan) | Basınç boş + İrtifa → ISA istasyon basıncı → hava yoğunluğu → Hedef. Yazılan basınç önceliği, ikisi boş, "Basınç irtifadan tahmin edildi." notu, aşırı irtifa | ICAO standart atmosfer (P = 1013,25·(1 − 2,25577e-5·h)^5,25588; US-1976 sabitlerinden kuruldu), kuru hava P/(R·T), CIPM-2007 nemli hava (Python) | Formül doğru (−400…5000 m arası fark ≤ 0,01 hPa; yoğunluk farkı ≤ 2e-5). **ATM-1:** kayıtlı İrtifa uygulama açılışında hesaba girmiyor |
| #295 F2 (kule yolunda sıfır açısı) | Sıfır açısının büyüklüğü ve işareti, sıfır günü hızı, ICAO sıfır havası; yukarı/aşağı yol formülü; MRAD/MOA klik; ayak önerisi | Elle hesap: vakum kapalı formül ve BRL G1 tablosuyla RK4 nokta-kütle çözücü (Python) | Açı doğru (.308 G1 0,462: 1,2601 mrad; vakum PCP: 4,0815 mrad). Rapor tablosundaki 6 satır aynen çıktı. **KUL-1:** sıfır açısı yarım yoldan büyükse yol taşıyor |
| #295 F3 (PCP tablo hızıyla sıfır) | Regülatörsüz PCP: sıfır ve atış aynı tablo hızı; boş, tek noktalı tablo; regülatörlü PCP | Kod izleme + Hedef'te sıfır mesafesinde düzeltme ≈ 0 | Doğru. **KUL-2:** Doğrulama (truing) bu yolda etkisiz. **KUL-3:** gizli bayrakta Profil tüp basıncına geri düşmüyor |
| #295 F5 (GA metni) | Metin ile formül uyumu | Kod | Doğru; lib/ içinde "GA" kalmadı |
| #291 (temizlik) | `lib/` içindeki her parça: silinen kodun çağıranı var mı, birleşen yardımcılar birebir aynı mı | Kod karşılaştırması (lib/, test/, integration_test/, tools/) | Davranış aynı; bulgu yok |
| #289 (Tüfek "Listede yok" gizli) | `RIFLE_LISTEDE_YOK` kapalı/açık; eski elle girilmiş tüfekli profil yükleniyor ve aynı hesaplıyor | Kod + widget testi (100 m'de sıfırda, sıfır açısı 13 klik) | Doğru |
| #298 (elle ateşli mühimmat) | Ağırlık gr → kayıt → kg (0,06479891 g/gr) → enerji; BC virgülü; BC modeli; barut listeleri; `AMMO_LISTEDE_YOK`, `AMMO_BC_BANDS_TYPED`, `PCP_AMMO_BRAND` | Birim tanımı, elle hesap | Doğru. G1 boyutlu BC ile G7 seçilince uyarı çıkıyor |
| #306 (PCP'de BC modeli, G1 varsayılan) | Model → sürükleme tablosu eşlemesi (9 değer); modeli kayıtsız eski kayıtlar; 237c14d ile 7eb1416 öncesi/sonrası sonuç | G1/G7 tablo çapa Cd değerleri, kod karşılaştırması | Eski kullanıcının sayısı değişmiyor. **MUH-3** (eski, düşük) |
| #296 / #304 (fabrika BC'leri, X651, FA007) | 11 satırın BC'si üreticinin hız tablosundan ayrı yöntemle yeniden çözüldü; ağırlık, hız, G1/G7 etiketi | Kendi 2-B zaman integralli nokta-kütle çözücü, Army Standard Metro havası, ses hızı 1116,45 ft/s; yöntem 5 basılı G1 BC'yi %3 içinde buluyor. Kaynak: depodaki üretici tabloları (`data/bc_gelistirme/velocity_tables.json`) | 11 satırın hepsi %0,8 içinde. X651 0,324 G1 makul (biçim katsayısı 0,816). **MUH-1, MUH-2, MUH-4** |
| #305 (BC ⓘ notu) | Not yalnız BC gerçekten yokken görünüyor mu; BC'siz fişek sessizce varsayılan BC alıyor mu | Kod + widget testi | Ateşli fişek BC'siz kaydedilemiyor; sessiz varsayılan yok. **MUH-5** (düşük) |
| #307 Hava Durumu kartı | Hava alımı yalnız Sıcaklık, Bağıl nem ve Rüzgâr hızı yazıyor mu (basınç, irtifa, rüzgâr yönü yazmamalı); 30 dk tazelik; `WIND_OBSERVATION` | Kod + widget testi | Doğru |
| #307 Basınç Ölçer + İrtifa kartı | Basınç al irtifa yazmıyor; etkin irtifa = telefon, yoksa harita; F1, yerçekimi ve basınç uyarısı etkin irtifayı kullanıyor; iki Sıfırla; eski tek İrtifa taşınması; yeniden açılışta kayıt | ISA; GRS80 normal yerçekimi + serbest hava düzeltmesi (3,086e-6 /m) | Doğru (yerçekimi farkı ≤ 2e-5 m/s²). Bütün durumlar test edildi (aşağıda) |
| #307 Rüzgâr düzeltmesi | En çok rüzgâr yalnız rüzgâr aralığı satırını ve WEZ'i besliyor, dürbün yan klikini asla etkilemiyor; ×1,5; elle yazılan değere dokunulmuyor; yeniden açılış | Kod + widget testi: aynı girdi, En çok rüzgâr var ve yok → yan klik aynı; aralık uçları = rüzgâr ve rüzgâr×1,5 klikleri | Yan klik etkilenmiyor. **RUZ-1, RUZ-2** |
| #307 Google Elevation | Ayrıştırma; −430 m (Ölü Deniz) ile 8849 m arası; hatalı durumlar; yeniden deneme; anahtarsız istek gitmiyor | Kod + birim testi | Doğru. **RUZ-3** (şüphe) |
| #307 anahtar | Elevation/Maps anahtarı depoda var mı | Çalışma ağacında ve **tüm git geçmişinde** (1687 commit) `AIza…` taraması; iş akışlarında anahtar yalnız `secrets` içinden geliyor | Anahtar yok; yalnız `ios-testflight.yml` içinde `secrets.GOOGLE_MAPS_IOS_API_KEY` olarak geçiyor, yazdırılmıyor |
| #308 (eski profillerin yeniden eşleşmesi) | Eski profil JSON → düzenleyici → Güncelle → çözücü girdisi; ateşli, PCP, elle girilmiş ve silinmiş katalog kimliği; belirsiz eşleşme; Barut katsayısı anlamı | Elle hesap (2600 fps, 10 °C, 1,5 → 25 °C'de 2639 fps); Python'a taşınmış eşleştirici gerçek tüfek kütüphanesinde | Hesap değerleri korunuyor (yalnız gösterim yuvarlaması: hızda ≤ 0,015 m/s). **PRF-1, PRF-3, PRF-4, PRF-5.** Kopyala'da **PRF-2** |

Gizli bayraklar: `WIND_OBSERVATION`, `PRO_TUBE_PRESSURE`, `SCOPE_LISTEDE_YOK`, `RIFLE_LISTEDE_YOK`, `AMMO_BC_BANDS_TYPED`, `AMMO_LISTEDE_YOK`, `PCP_AMMO_BRAND`, `PROFILE_AMMO_LENGTH`, `GOOGLE_MAPS_ENABLED`.
- Hepsi `bool.fromEnvironment` ile okunuyor ve varsayılan kapalı.
- Kapalıyken arayüz gizleniyor, kayıtlı veri korunuyor.
- `PROFILE_AMMO_LENGTH`: kayıtlı uzunluk saklanıyor, hesapta yalnız Pro → Mermi uzunluğu kullanılıyor (sahip kararı).
- `AMMO_BC_BANDS_TYPED` kapalıyken kayıtlı bantlar kullanılmaya devam ediyor.
- Açık yollar koddan okunarak kontrol edildi; test bayrak açamıyor. Açık yolda tek sorun **KUL-3**.

İmparatorluk birimleri (ft, inHg, mph) bu derlemede açılamıyor; `SettingsStore.loadMetric()` her zaman metrik döndürüyor. O yollar yalnız koddan okundu.

#307 etkileşim durumlarının hepsi widget testiyle doğrulandı (15 °C, nem %0):

| Durum | Hava yoğunluğu (kg/m³) | Not |
|---|---|---|
| Basınç boş, irtifa yok | 1,2250 | |
| Telefon 1500 m | 1,0223 | |
| Yalnız harita 300 m | 1,1821 | |
| Telefon 1500 + harita 300 | 1,0223 | telefon kazanıyor |
| Basınç 900 hPa yazılı | 1,0881 | |
| Basınç al 998,4 + İrtifa 1500 | 1,2071 | irtifa ikinci kez sayılmıyor |
| İrtifa Sıfırla | 1,2250 | not kalkıyor |
| Basınç Sıfırla | 1,0223 | |
| Eski tek İrtifa kaydı | 1,0223 | Telefondan irtifa olarak geliyor |
| Kayıtlı harita irtifası | 1,0223 | düğme turuncu açılıyor |

## Bulgular

### ATM-1 — Yüksek: kayıtlı Hava Durumu, uygulama açılışında Hedef hesabına girmiyor

- **Yer:**
  - `lib/features/ballistics/ballistics_screen.dart`: `_loadShotSettings` (yaklaşık 321–381) ve ilk otomatik hesap (`addPostFrameCallback`, yaklaşık 1219).
  - `lib/features/home/home_screen.dart:108`: çalışma alanı `BallisticsView.shot` ile kuruluyor.
- **Ne oluyor:**
  - İlk hesap, kayıtlı ayarlar diskten gelmeden önce çalışıyor.
  - Ayarlar gelince kutulara yazılıyor ve önbellek siliniyor, ama yeniden hesap yapılmıyor (`_basis` eski kalıyor).
  - Uygulama Profil sekmesinde açılıp Hedef'e geçilince görünüm "shot → shot" kalıyor. Bu yüzden `didUpdateWidget` de hesaplamıyor.
- **Tekrar:**
  1. Hava Durumu'nda 15 °C, nem %0, Telefondan irtifa 1500 m girin, Basınç boş kalsın.
  2. Uygulamayı kapatıp açın ve Hedef'e geçin.
  3. Hedef deniz seviyesi havasıyla hesaplıyor: yoğunluk 1,2211, olması gereken 1,0223. "Basınç irtifadan tahmin edildi." notu da yok.
- **Etkisi** (#295 raporundaki örneklere göre):
  - .308 800 m'de yaklaşık 10 klik.
  - PCP .22 100 m'de yaklaşık 4 klik.
  - Kayıtlı sıcaklık, nem ve basınç da aynı şekilde hesaba girmiyor.
  - Hava Durumu ya da Pro sayfasına bir kez gidip gelince düzeliyor.
- **Köken:** 237c14d'de de var; o zaman irtifa basınç boşken hesaba girmediği için etkisi daha küçüktü. #295 F1'den sonra İrtifa kullananlarda büyüdü.
- **Önerilen düzeltme (uygulanmadı):** `_loadShotSettings` sonunda, kayıt geri yazıldıktan sonra, profil varsa `_quietSolve()` çağrılsın.
- **Testler:**
  - `ATM-1 … Hava yoğunluğu after a restart matches the restored boxes`
  - `ATM-1 … Hedef opened directly shows the F1 note for the restored İrtifa`
  - Python: `test_atm1_saved_weather_is_solved_after_it_is_restored` (`expectedFailure`).

### PRF-2 — Yüksek: Kopyala bağımsız kopya değil; kopyayı düzenlemek asıl profili değiştiriyor

- **Yer:** `lib/features/profiles/profiles_screen.dart:284` (`_duplicate`) ve `_rifleEntry` / `_ammoEntry` / `_scopeEntry` (yaklaşık 3230, 3253, 3285).
- **Ne oluyor:**
  - Kopya aynı tüfek, mühimmat ve dürbün kayıt kimliklerini taşıyor.
  - Elle girilmiş (`userEntered`) kaydı düzenleyince aynı kimliğin üstüne yazılıyor.
- **Tekrar:**
  1. Elle mühimmatlı PCP profilinde BC 0,1 olsun. Kopyala'ya basın.
  2. Kopyada BC'yi 0,12 yapıp Güncelle'ye basın.
  3. Asıl profilin BC'si de 0,12 oldu (CI'da ölçülen: beklenen 0,1, çıkan 0,12). Asıl profilin düşüş ve rüzgâr sayıları değişiyor, eski BC kayboluyor.
- **Köken:** 237c14d'de de var; bu dönemdeki değişikliklerden gelmiyor.
- **Önerilen düzeltme (uygulanmadı):** Kopyala elle girilmiş kayıtları yeni kimlikle kopyalasın, ya da düzenleyici kayıt başka bir profilde de kullanılıyorsa yeni kimlik yazsın.
- **Test:** `PRF-2: Kopyala is an independent copy …`

### KUL-1 — Orta: sıfır açısı kulenin yarım yolundan büyükse yol hesabı taşıyor (#295 F2)

- **Yer:** `ballistics_screen.dart` yaklaşık 3317–3322 (`upClicks`/`downClicks`), `scope_dial_view.dart:318` (`mountBlocksZero`) ve `_travelMessage`.
- **Tekrar:**
  - Katalog PCP: Hatsan Hercules 635, 270 m/s, sıfır 25 m, nişan yüksekliği 60 mm.
  - Dürbün: Steiner Ranger 4 4-16x56, toplam yol 7,2 mrad, klik 0,1. Yarım yol 36 klik, sıfır açısı 41 klik.
  - Ekranda yukarı 0, aşağı 77 klik. Kulenin tamamı 72 klik.
  - "Sıfırlanamaz" uyarısı yok. Her yukarı düzeltmede "Kule yetmez" çıkıyor. Ayak önerisi yaklaşık 5 klik küçük.
  - Hedef'teki gereken klik değişmiyor.
- **Önerilen düzeltme:**
  - Aşağı yol `2·yarım` ile sınırlansın.
  - `sıfır − ayak > yarım` için ayrı "sıfırlanamaz" notu olsun.
  - Ayak önerisi kırpılmamış değerden hesaplansın.
- **Test:** `KUL-1 … up + down never exceed the whole travel`. Kaldırınca 77 > 72 ile düştü.

### KUL-2 — Orta: regülatörsüz PCP'de (kullanılabilir tabloyla) Doğrulama etkisiz

- **Yer:** `lib/features/tools/truing_screen.dart` yaklaşık 262–266 ve 581.
- **Ne oluyor:**
  - Doğrulama, profil hızıyla çözüp sonucu Profil'in Namlu çıkış hızına yazıyor.
  - #295 F3'ten sonra Hedef bu yolda tablo hızını kullanıyor; Profil hızı hesaba girmiyor.
  - Kullanıcı "Doğrulanmış hız profile uygulandı" görüyor, ama hiçbir sayı değişmiyor.
- **Tekrar:** tablo 120 bar → 255 m/s ve 200 bar → 270 m/s, tüp 120 bar, sıfır 30 m. Profil hızı 270'ten 240'a değişince Hedef'te 100 m düzeltmesi aynı kalıyor.
- **Önerilen düzeltme:** Doğrulama tablo hızına göre çözsün (ör. tabloyu ölçeklesin), ya da bu durumda uygulanamayacağını söylesin. Hangisi, sahibin kararı.
- **Testler:** `KUL-2 … truing knows the PCP table` (atlanmış) ve geçen koruma testi `design guard: with a usable table …`.

### RUZ-1 — Orta: hava alımı rüzgârı 0 getirince eski En çok rüzgâr (×1,5) kalıyor (#307)

- **Yer:** `ballistics_screen.dart` 598–613 (`_putWindMaxFromWind`, `w <= 0` için erken dönüyor).
- **Tekrar:**
  1. Hava alımı 5,0 m/s getirsin; Pro → Düzeltme al: kutuda 7,5.
  2. Yeni hava alımı 0,0 m/s getirsin.
  3. Kutu 7,5 ve turuncu "Düzeltme alındı" kalıyor.
  4. Hedef "Rüzgâr 0,0–7,5 m/s" aralığını gösteriyor, WEZ de 7,5'luk belirsizlik ekliyor. Yan klik doğru.
- **Önerilen düzeltme:** düğmeyle dolmuş kutu, rüzgâr ≤ 0 olunca boşalsın.
- **Test:** `RUZ-1 … a 0 m/s fetch does not leave the old × 1.5 value (7.5) orange`

### RUZ-2 — Orta: rüzgâr elle değişince ya da Sıfırlanınca En çok rüzgâr eski kalıyor (#307)

- **Yer:** rüzgâr kutusunun `onChanged`'i (yaklaşık 4101–4113) ve `_resetWeather` (1355–1374).
- **Tekrar:** hava 5 m/s → Düzeltme al (7,5) → Rüzgâr hızına elle 8 yazın.
  - Kutu 7,5 ve turuncu kalıyor.
  - 7,5 < 8 olduğu için Hedef'teki aralık satırı ve WEZ rüzgâr kaynağı sessizce kayboluyor.
  - Hava Durumu Sıfırla da aynı sonucu veriyor.
- **Not:** yazılı tarif güncellemeyi yalnız hava alımına bağlıyor; bu yüzden sahibin kararı gerekiyor.
- **Önerilen düzeltme:** elle yazılan ya da sıfırlanan rüzgâr da düğmeyle dolmuş kutuyu güncellesin, ya da işaret kalksın (turuncu olmasın).
- **Testler:** `RUZ-2 … typed wind 8 …` ve `RUZ-2 … Hava Durumu Sıfırla …`

### RUZ-3 — Orta, şüphe (yaklaşık %70): Elevation isteği iOS anahtarıyla reddedilebilir (#307)

- **Yer:** `lib/tools/adapters/google_elevation_provider.dart`.
- **Ne oluyor:**
  - Elevation bir web servisi API'si.
  - İstek, Maps **iOS** anahtarıyla ve `X-Ios-Bundle-Identifier` başlığıyla gidiyor.
  - Google'ın API güvenlik rehberi, platform kısıtı olan bir anahtarın başka platformda kullanılamayacağını söylüyor: https://developers.google.com/maps/api-security-best-practices
  - Anahtar iOS uygulamalarına kısıtlıysa, TestFlight'ta her "Haritadan" isteği REQUEST_DENIED alır: kutu boş kalır, "Harita irtifası alınamadı" görünür.
- **Etkisi:** yanlış sayı yok; özellik çalışmaz.
- **Önerilen adım:** gerçek anahtarla tek bir canlı istek, ya da Cloud Console'da anahtarın kısıtlarına bakmak. Bu denetimde çalıştırılmadı, test yok.

### MUH-1 — Orta (sınırda yüksek): G1↔G7 değişince üreticinin BC'si öbür eğride kullanılıyor

- **Yer:** `lib/features/profiles/profiles_screen.dart` 4664–4671 (BC modeli `onChanged`) ve 3058–3093 (makullük kontrolü).
- **Tekrar:**
  1. Winchester 6.5 CM X651'i seçin (BC 0,324, G1).
  2. BC modelini G7 yapın.
  3. BC 0,324 kalıyor ve uyarı çıkmıyor (biçim katsayısı 0,816, G7 bandının içinde). G7 0,324 olarak kaydediliyor.
- **Bağımsız hesap** (sıfır 100 m):
  - 600 m: 4,41 mrad gösterilir, doğrusu 6,17 mrad.
  - 800 m: 6,78 gösterilir, doğrusu 10,86 mrad.
  - Tersi de oluyor: G7 BC'li fişekte G1 seçmek.
- **Neden yüksek değil:** kullanıcının modeli bilerek değiştirmesi gerekiyor, ve ⓘ yanlış eğri konusunda uyarıyor.
- **Önerilen düzeltme:** listeden seçilmiş, üretici BC'si dolu fişekte model değişince BC temizlensin ya da uyarı çıksın. G7 seçilince varsa `FactoryAmmo.bcG7` kullanılsın.
- **Testler:** `MUH-1 … switching to G7 does not keep the G1 number silently` ve geçen koruma testi `guard: picking X651 fills 129 gr, BC 0,324, G1, 2820 fps`.

### MUH-2 — Orta (bilinen, sahip kararı bekliyor): FA007 namlu hızı yanlış

- **Yer:** `lib/data/factory_ammo_library.dart:85`.
- **Ne oluyor:**
  - Ağırlık 40 gr'a düzeltildi, ama hız 1095 fps kaldı; bu .22 Short değeri.
  - 40 gr'ın alındığı üretici sayfası 1130 fps diyor. #304 raporu bunu "sahip kararı bekliyor" diye yazmış.
- **Etkisi:** 100 m'de 0,12 mrad, 150 m'de 0,23 mrad.
- **Önerilen düzeltme:** sahip onaylarsa 1130 fps.
- **Test:** `MUH-2 … FA007 velocity is the maker page figure (1130 fps)`

### PRF-1 — Orta: katalog dürbününde Güncelle yan kule yolunu siliyor

- **Yer:** `profiles_screen.dart` `_scopeEntry` (yaklaşık 3279). Kayıtta `windageRangeMrad` ve yol alt sınırı işaretleri yazılmıyor.
- **Tekrar:**
  - Katalog dürbünlü profil: Arken SH-4 GENII 4-16x50 FFP, yükseliş 36 mrad, yan 10 mrad.
  - Hiçbir şeyi değiştirmeden Güncelle'ye basın.
  - Yan yol null oluyor (CI'da ölçülen: beklenen 10, çıkan null).
  - Hedef'teki yan tambur sınırı (50 klik) ve yan "Kule yetmez" uyarısı kayboluyor. Klik sayıları değişmiyor.
- **Köken:** 237c14d'de de aynı.
- **Önerilen düzeltme:** `_scopeRecord?.windageRangeMrad` ve sınır işaretleri kayda yazılsın.
- **Test:** `PRF-1 … keeps its windage travel`

### PRF-3 — Orta: profil birimi dürbün biriminden farklıysa Güncelle dürbünü değiştiriyor (#308)

- **Tekrar:**
  - Eski profil: elle girilmiş MRAD 0,1 Arken dürbün; #308 bunu katalogla eşleştiriyor. Profil birimi MOA.
  - Güncelle'ye basınca dürbün MOA 0,25 olarak kaydediliyor (CI'da ölçülen: beklenen mrad, çıkan moa).
  - Sonraki açılışta MOA modeliyle eşleşiyor, Retikül "Seçiniz" oluyor.
- **Etkisi:** Hedef'teki klik boyu önce de sonra da 0,25 MOA; sayı değişmiyor. Ama kayıtlı dürbün verisi değişiyor; bu #308 raporundaki "veri korunur" sözüne aykırı.
- **Önerilen düzeltme:** liste modunda dürbünün kendi birimi ve kliki profil biriminden bağımsız tutulsun.
- **Testler:** `PRF-3 …` ve geçen kontrol testi (klik boyu aynı).

### PRF-4 — Orta (kimlik verisi, hesap değil): eşleştirme modeli başka ürüne çevirebiliyor (#308)

- **Yer:** `lib/features/profiles/profile_catalog_match.dart`, `rifle()`.
- **Tekrar:**
  - Elle girilmiş "HATSAN / Hercules Bully", 6,35 mm. Kütüphanede Bully yalnız .30/.357/.45 kalibrede var.
  - Profil "Hatsan / Hercules" olarak açılıyor; Güncelle kaydın adını değiştiriyor.
  - Kalibre ve yiv korunuyor.
- **Önerilen düzeltme:** tam ad eşleşmesi kalibre havuzundan önce gelsin, yoksa eşleşme olmasın.
- **Test:** `PRF-4: "HATSAN / Hercules Bully" .25 is not renamed "Hercules"`

### Düşük önemdeki bulgular

- **KUL-3:** gizli `PRO_TUBE_PRESSURE` açıkken Pro'daki tüp basıncı kutusu boşsa Profil tüp basıncına geri düşülmüyor. Tablo yok sayılıyor, profil hızı kullanılıyor.
  - Yer: `ballistics_screen.dart` 870–872.
  - Öneri: `_parsed(tubePressureCtl) ?? p?.tubePressureBar`.
  - Bayrak kapalıyken etkisi yok.
- **ATM-2:** F1 kuralını anlatan tek metin (`EnvironmentFieldInfo.altitude`: "Basınç boşsa … tahmin edilir") artık hiçbir yerde kullanılmıyor. İrtifa kartı ⓘ'si de Basınç Ölçer ⓘ'si de irtifanın yalnız basınç boşken kullanıldığını söylemiyor. Metin sahibin kararı.
- **ATM-3:** `EnvironmentFieldInfo.pressure` (Araçlar → Doğrulama sayfası) hâlâ "Basıncı telefondan al" düğmesinden söz ediyor. #307 düğmenin adını "Basınç al" yaptı; Doğrulama sayfasında böyle bir düğme yok. Düzeltilirken `test/phone_pressure_test.dart:218` de güncellenmeli.
- **MUH-3:** kayıtta bilinmeyen bir BC modeli yazısı (ör. 2026-10-12'de kaldırılan "ga") BC'yi sessizce düşürüyor.
  - PCP'de "BC girilmediği için tahmini G1 BC" yazıyor, bu doğru değil; ateşli silahta yalnız yerçekimi hesabına düşüyor.
  - #306'dan önce de aynı.
  - Yer: `lib/data/user_catalog.dart` 148–149.
- **MUH-4:** FA056'nın hızı 2750 fps (katalog PDF), BC'si ise 2760 fps ile başlayan ürün sayfası tablosundan çözülmüş. İkisi de üreticinin kendi verisi; fark %0,4.
- **MUH-5:** BC'siz fabrika fişeğinde #305 ⓘ'si "BC modelini de seçin" diyor, ama BC yazınca model kendiliğinden G1 oluyor (sahip kuralı, 2026-10-13). Kullanıcının ölçtüğü bir G7 sayısı G1 olarak çalışabilir. Hangi kural geçerli, sahibin kararı.
- **PRF-5:** eşleştirici `toLowerCase` kullandığı için "SARSILMAZ" ile "Sarsılmaz" (ı/i) eşleşmiyor. Profil elle girilmiş modda açılıyor; değerler korunuyor.

## Not edilen ama bulgu sayılmayanlar

- Başarısız bir "Telefondan" ya da "Haritadan" alımı, elle yazılmış değer dahil kutuyu boşaltıyor. Sahibin "kutu boş" kuralı böyle; hesap öbür kutuya ya da 0 m'ye düşüyor ve not çıkıyor. Sahibin teyidi iyi olur.
- "Konumdan hesapla" ile bulunan yerçekimi, irtifa sonradan değişince yenilenmiyor. Fark 1000 m başına en çok yaklaşık %0,03.
- Rüzgâr bölgeleri girilmiş ve Rüzgâr hızı 0 iken aralık satırı bölgeleri değil düz En çok rüzgârı kullanıyor. #307'den eski.
- 18 Sellier & Bellot yumuşak uçlu satırı G7 etiketli, ama biçim katsayıları 1,81–2,33; profildeki G7 bandının (0,63–1,8) dışında. Seçilince yanlış bir "BC çok düşük" uyarısı çıkabilir, ya da etiket yanlış olabilir. Kapsam dışı, incelenmedi.
- Güncelle'den sonra katalog dürbününün `sourceDocument`'ı kullanıcınınki oluyor. Bu, retikülün ürün kodu ile bulunmasını engelleyebilir. Düşük güvenle şüphe; test edilmedi.

## Testler

Yeni dosyalar:
- `test/audit_2026_10_14b/atmosphere_altitude_audit_test.dart`: F1 ve #307 İrtifa zinciri, Sıfırla, kayıt taşıma, yerçekimi; ATM-1/2/3.
- `test/audit_2026_10_14b/weather_wind_elevation_audit_test.dart`: En çok rüzgâr → yalnız aralık ve WEZ; ×1,5; yeniden açılış; hava alımının yazdıkları; Elevation ayrıştırma; RUZ-1/2.
- `test/audit_2026_10_14b/turret_zero_cleanup_audit_test.dart`: F2 açısı ve yol, F3 hız kaynağı, F5, #289; KUL-1/2/3.
- `test/audit_2026_10_14b/ammo_bc_audit_test.dart`: model → tablo, eski kayıtlar, fabrika BC'lerinin bağımsız kontrolü, X651, FA007, gr → kütle; MUH-1…5.
- `test/audit_2026_10_14b/profile_match_audit_test.dart`: yeniden eşleşmede değerlerin korunması (ateşli, PCP, elle girilmiş, silinmiş kimlik), belirsiz eşleşme, Barut katsayısı; PRF-1…5.
- `tools/test_denetim_2026_10_14b_{atm,ruz,kul,muh,prf}.py`: bağımsız el hesapları (ISA, CIPM-2007, GRS80, vakum ve G1 nokta-kütle sıfır açısı, BC yeniden çözümü), anahtar taraması, kaynak kodu korumaları.

Durum:
- Bulgu testleri `skip` ile kapalı. `testWidgets` yalnız `bool` kabul ettiği için oralarda `skip: true` ve yanında `// ID:` yorumu var; test adı da bulgu kimliğini taşıyor. `test()` içindekiler `skip: 'ID: …'`.
- Doğrulanmış davranışları koruyan testler açık.
- Bir bulgu düzeltilince testi açılmalı ve geçmeli (CLAUDE.md).
- Skip kanıtı: ayrı, geçici `audit/probe-14b` dalında bütün `skip`'ler kaldırıldı.
  - Bulgu testlerinin hepsi beklenen sayı farkıyla düştü (bulgulardaki "CI'da ölçülen" değerler buradan).
  - ATM-1'in üçüncü testi o turda düşmedi, çünkü sıfır mesafesinde klik farkı ölçülemiyordu. Hatayı göstermediği için çıkarıldı.
  - Geçici `audit/probe-14b` dalı silinemedi (bu ortamdan dal silme isteği reddedildi). Sahip silebilir; PR'a dahil değil.

Yerel sonuçlar:
- `python3 tools/offline_dart_lint.py`: PASS, 349 Dart dosyası, 0 sorun.
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 822 test, OK (beklenen başarısızlık 1: ATM-1).

## CI

Hepsi bu dalda (`audit/testflight-2026-10-14b`), son kod commit'i 672a1dd üzerinde. Ondan sonra yalnız bu rapor eklendi.

| İş | Sonuç | Bağlantı |
|---|---|---|
| Dart format düzeltme (format-fix) | başarılı; 672a1dd commit'ini üretti, dala çekildi | https://github.com/sniperTurk/flutter-app/actions/runs/38599699405 |
| `flutter analyze --fatal-infos --fatal-warnings` (analyze-diag) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38600108815 |
| Bütün test takımı, `files=test` (test-diag) | başarılı (çıkış kodu 0) | https://github.com/sniperTurk/flutter-app/actions/runs/38600113959 |
| Yalnız denetim testleri (test-diag) | başarılı: 66 geçti, 21 atlandı (ATM-1'in sonradan çıkarılan testi dahil) | https://github.com/sniperTurk/flutter-app/actions/runs/38598865495 |
| `skip` kaldırılmış kanıt turu (`audit/probe-14b`) | beklendiği gibi başarısız: bulgu testleri düştü | https://github.com/sniperTurk/flutter-app/actions/runs/38598869200 |

- İlk analyze ve test turları (38597943816, 38597933692), `testWidgets` içinde yazı `skip` kullanıldığı için derleme hatası verdi; düzeltildi.
- iOS CI (`iOS CI / verify`), Simulator ve TestFlight çalıştırılmadı; geçti denmiyor.

## Yapılmayanlar

- `lib/` içinde hiçbir düzeltme yapılmadı.
- TestFlight, Simulator ve iOS CI çalıştırılmadı.
- Birleştirme yapılmadı; PR taslak.
- Üretici sitelerine yeniden bakılamadı (WebFetch izni zaman aşımına uğradı). BC kontrolü, depoya daha önce kaydedilmiş üretici tablolarıyla yapıldı.
- Gerçek GPS ve gerçek Google Elevation isteği denenmedi (RUZ-3).

🤖 Generated with [Claude Code](https://claude.com/claude-code)
