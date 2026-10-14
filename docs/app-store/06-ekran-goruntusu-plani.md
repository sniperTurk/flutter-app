# 06 · Ekran görüntüsü planı

> Plan; yeni Mac/simülatör çalıştırması **yapılmadı**. 2026-10-14'te
> `main @ 69e8a0e` ekran adlarına göre güncellendi: Hedef'teki
> "Tek atış | Tablo" seçici gizli (`SHOT_TABLE_SWITCH`, 2026-10-12), Tablo
> görünümü normal derlemede açılmıyor; Hava Durumu'nda Rüzgâr gözlemi gizli
> (#272); Pro açıklamaları alttan açılan sayfada (#279); Araçlar'a
> Gizlilik politikası eklendi (bu PR). Referans:
> `ci/sim-screens` dalı `latest/*.png` (çalışma 38169066737,
> `feat/retikul-eslestirme @ 783ba73`, iPhone 17 Pro / iOS 26.2, 40 PNG).

## 1. Boyutlar (resmî)

| Apple adı | Eski adı | Kabul edilen dikey boyutlar | Zorunlu mu? | Simülatör |
|---|---|---|---|---|
| iPhone with Dynamic Island (large display) | **6.9"** | 1320×2868, 1290×2796, 1260×2736 | Hayır | iPhone 17 Pro Max → 1320×2868 |
| iPhone with Face ID (large display) | **6.5"** | 1284×2778, 1242×2688 | Yalnızca 6.9" yüklenmezse | iPhone 11 Pro Max / XS Max → 1242×2688 |
| iPhone with Dynamic Island (medium display) | 6.3" | 1206×2622, 1179×2556 | **Evet, en az 1** | iPhone 17 Pro → 1206×2622 |

- Biçim: `.png`/`.jpg`/`.jpeg`, **alfa kanalı olamaz**. Mevcut
  `ci/sim-screens` PNG'leri **RGBA** → yüklemeden önce RGB'ye çevrilmeli
  (ör. `python3 -c "from PIL import Image; Image.open('a.png').convert('RGB').save('a.png')"`).
- Boyut başına 1–10 görsel. Uygulama yalnız iPhone (`TARGETED_DEVICE_FAMILY = 1`),
  iPad görseli gerekmez.
- Öneri: **6.9" (1320×2868) + 6.3" (1206×2622)** setleri, ikisi de doğal
  simülatör çekimi. 6.9" yüklendiği için 6.5" zorunlu değil; istenirse
  iPhone 11 Pro Max simülatöründe doğal çekilmeli. Ölçekleme önerilmez:
  1206×2622 → 1320×2868 büyütme bulanıklaştırır; 6.9 → 6.5 en-boy oranı
  farklı (0,4603 / 0,4622), kırpma gerekir.
- Mevcut `ci/sim-screens` görselleri 1206×2622 → **6.3" (zorunlu) yuvasının
  boyutuna zaten uygun**, ama içerikleri mağazaya hazır değil (bkz. 3).

## 2. Sıra, ekran ve kısa başlık

Başlıklar görselin üstünde metin bandı olarak eklenebilir (2.3.3 metin
katmanına izin verir). Kısa tutuldu (≤ 32 karakter).

| Sıra | Ekran (sekme) | Referans (`latest/`) | TR başlık | EN başlık |
|---|---|---|---|---|
| 1 | Hedef: dürbün retikülü, tutuş noktası ve kule klikleri (Tek atış) | `38_hedef_atis.png`, `39_hedef_atis_2.png` | Kule klik ve retikül tutuşu | Turret clicks and reticle hold |
| 2 | Hedef: aşağı kaydırılmış — Hesap dökümü ve "DOPE kartını paylaş (PDF)" | **Yok** — yeniden çekilmeli (eski `40_hedef_tablo.png` artık açılmayan Tablo görünümü) | Hesap dökümü ve PDF DOPE kartı | Breakdown and PDF DOPE card |
| 3 | Hava Durumu: Sıcaklık, nem, basınç, irtifa ve rüzgâr saati dolu ("Rüzgâr tahmini nasıl yapılır?" bağlantısı görünür) | `32_hava_durumu.png`, `33_hava_durumu_2.png` (eski; Rüzgâr gözlemi içeriyorsa yeniden çekilmeli) | Hava ve rüzgâr konumundan | Weather and wind in one tap |
| 4 | Profil: aktif profil özeti (Tüfek, Dürbün, Mühimmat kartları) | `30_profil_kayitli.png` (eski düzen; yeniden çekilmeli) | Tüfek, dürbün, mühimmat | Rifle, scope and ammo profile |
| 5 | Profil oluştur: listeden seçim (Marka / Model / Kalibre, ⓘ'ler) | `18_profil_olustur_atesli.png` (eski; yeniden çekilmeli) | Listeden seç, her kutuda ⓘ | Pick from lists, ⓘ on every field |
| 6 | Pro: Coriolis, yerçekimi, hareketli hedef dolu; isteğe bağlı açık bir ⓘ alt sayfası | `36_pro_ayarlar.png` (eski; yeniden çekilmeli) | Coriolis, yerçekimi, spin | Coriolis, gravity, spin drift |
| 7 | Araçlar listesi | `07_araclar.png` (eski; artık Gizlilik politikası satırı da var) | Hız doğrulama ve saha araçları | Truing and field tools |
| 8 | Haritadan mesafe (uydu haritası, iki nokta, mesafe/yön) | **Yok** — sim turunda çekilmemiş | Haritadan mesafe ve yön | Distance and bearing from map |
| 9 | Hesaplayıcılar | `09_hesaplayicilar.png` | Mesafe, MOA, BC, enerji | Range, MOA, BC, energy |

İlk üç görsel arama sonuçlarında görünür; en güçlü ekranlar (retikül,
DOPE kartı, hava) bu yüzden başta.

## 3. Mevcut referans görsellerdeki sorunlar (yeniden çekim gerekir)

1. **Test verisi görünüyor:** "Test Marka", "Test Model", "Test Mühimmat
   Slug", "Yeni Profil". Gerçekçi bir örnek profil gerekli (listeden seçilmiş
   tüfek ve mühimmat, anlamlı profil adı, ör. "Örnek .308").
2. **Hata durumu:** `38_hedef_atis.png` "Değerler hesaplanamadı. Profil ve Hava
   Durumu değerlerini kontrol edin." gösteriyor ve kule "hesaplama bekleniyor";
   `40_hedef_tablo.png` altta "Rüzgâr yönünü girin" bildirimi var (Tablo
   görünümü 2026-10-12'den beri normal derlemede açılmıyor). Neden:
   turda **rüzgâr yönü** girilmemiş. Mağaza turunda rüzgâr yönü (ör. saat 3)
   ve mesafe (ör. 300 m) girilmeli ki retikülde tutuş noktası görünsün.
3. **Dosya adı / içerik kayması:** bazı adlar içeriği tutmuyor (ör.
   `01_profil_karsilama.png` Hava Durumu, `02_hava_durumu_bos.png` Pro Ayarlar,
   `37_pro_ayarlar_2.png` Hedef gösteriyor). Plan görsel içeriğe göre yapıldı;
   tur testindeki adlandırma ayrıca düzeltilmeli.
4. **Harita görseli yok:** tur Haritadan mesafe ekranını çekmiyor. Esri
   karoları ağdan iner; çekim sırasında atıf yazısı ("Esri, Maxar, Earthstar
   Geographics") görünür kalmalı. Google Maps'li derlemede çekilirse Google
   logosu/atfı kırpılmamalı.
5. **Alfa kanalı:** PNG'ler RGBA (bkz. 1).
6. **Üçüncü taraf markalar:** dürbün/tüfek marka adları (ör. "Element
   Optics") ekranda görünüyor. İşlevsel veri olarak sorun değil; ama mağaza
   görsellerinde öne çıkarılmaması, mümkünse az görünür bir örnek seçilmesi
   önerilir.
7. **Kurallara uygun görsel:** insan/hayvan hedefi, kişiye doğrultulmuş
   silah yok (1.1.2, 2.3.8). Mevcut ekranlar bu açıdan uygun.

## 4. Sonraki çekim için öneri (sahip onayı sonrası, ayrı iş)

- `integration_test/` altında mağazaya özel bir tur (ör. `store_screens_test.dart`):
  örnek profili listeden seçerek kaydet → Hava Durumu'nu doldur (rüzgâr hızı
  ve yönü dahil) → Pro'da Coriolis/yerçekimi doldur → Hedef'te 300 m →
  aşağı kaydırıp Hesap dökümü / DOPE kartı →
  Haritadan mesafe (iki nokta) → Araçlar → Hesaplayıcılar.
- Aynı turu iki simülatörde çalıştır: iPhone 17 Pro Max (6.9") ve iPhone 17
  Pro (6.3"); istenirse iPhone 11 Pro Max (6.5").
- Çıktıyı RGB'ye çevir, boyutları doğrula (`1320×2868`, `1206×2622`), başlık
  bandını ekleyip boyutu koru.
- Bu PR bunların hiçbirini çalıştırmaz.

## Kaynaklar

- Screenshot specifications: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- App Review Guidelines 2.3.3, 2.3.8, 1.1.2: https://developer.apple.com/app-store/review/guidelines/
