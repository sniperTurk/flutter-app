# App Store yayın materyali — TASLAK (2026-10-11, güncelleme 2026-10-14)

> Bu klasör yalnızca taslaktır. App Store Connect'e hiçbir şey gönderilmedi,
> hesap/form işlemi yapılmadı, `Info.plist` üreten araçlar değiştirilmedi.
> İlk kaynak `main @ 835b956`; 2026-10-14'te `fix/gizlilik-magaza` ile
> `main @ 69e8a0e`'ye göre güncellendi (ad/alt başlık sahip seçimi, Google
> Maps SDK beyanı, uygulama içi gizlilik sayfası). Rapor:
> `docs/reports/gizlilik_magaza.md`.

| Dosya | İçerik |
|---|---|
| [01-magaza-metinleri.md](01-magaza-metinleri.md) | TR/EN ad, alt başlık, tanıtım metni, açıklama, anahtar kelimeler, Yenilikler, URL yer tutucuları |
| [02-gizlilik-etiketi.md](02-gizlilik-etiketi.md) | Koddan çıkarılan veri akışı ve App Privacy cevap taslağı |
| [03-gizlilik-politikasi.md](03-gizlilik-politikasi.md) | TR/EN gizlilik politikası; TR metin uygulamadaki Araçlar > Gizlilik politikası sayfasının tek kaynağı (`tools/data_gen/generate_privacy_policy.py`) |
| [04-info-plist-izinleri.md](04-info-plist-izinleri.md) | İzin açıklamaları denetimi, eksik/belirsiz olanlar, öneri metinleri |
| [05-inceleme-kurallari-ve-yas.md](05-inceleme-kurallari-ve-yas.md) | İlgili App Review maddeleri, yaş derecesi önerisi (13+), riskler, inceleme notu |
| [06-ekran-goruntusu-plani.md](06-ekran-goruntusu-plani.md) | 6.9" / 6.5" (+ zorunlu 6.3") ekran görüntüsü sırası ve başlıkları |
| `check_lengths.py` | 01'deki metinlerin karakter/bayt sınırlarını ve anahtar kelimelerin seçilen ad/alt başlığı tekrar etmediğini denetler: `python3 docs/app-store/check_lengths.py` |

## Öne çıkan bulgular

1. ~~Uygulama içinde gizlilik politikası bağlantısı yok (5.1.1(i))~~ —
   **YAPILDI (bu PR, `fix/gizlilik-magaza`):** Araçlar > Gizlilik politikası
   (Kullanım rehberi'nin altında), Türkçe metin uygulamada gömülü,
   çevrimdışı açılır. `PRIVACY_POLICY_URL` derlemede verilirse adres metin
   olarak görünür; url açma paketi olmadığı için "Web'de aç" düğmesi yok.
2. **Google Maps SDK** her derlemeye giriyor; Google'ın SDK ile yayımladığı
   gizlilik bildirimine göre cihaz kimliği ve "diğer veri" (bağlı), çökme,
   performans, ürün etkileşimi (bağlı değil) topluyor, izleme yok. 02 ve 03
   artık bunu içeriyor (kaynak: Google'ın resmî sayfası, okunma 2026-10-14).
3. **Ad ve alt başlık seçildi** (sahip, 2026-10-14): `Sniper Türk: Balistik`
   / `Ateşli ve PCP Tüfekler İçin`. Açıklama, tanıtım metni ve anahtar
   kelimeler güncel uygulamaya göre yeniden yazıldı (GA modeli, Tablo
   görünümü, Rüzgâr gözlemi gibi artık olmayan şeyler çıkarıldı).
4. **Konum ve kamera izin metni hâlâ eksik** (04): harita, yerel yerçekimi
   ve "Basıncı telefondan al" irtifası konum metninde yok; kamera metni
   "yalnızca Sight Height" diyor ama "Kamerayla ölç" de kullanıyor. Kod
   değişikliği gerekir (`tools/configure_ios_info_plist.py`), ayrı onay.
5. **Yaş:** "Guns or Other Weapons = Frequent" → **13+**.
6. **Anahtar kelime sınırı 100 bayttır**; Türkçe harfler 2 bayt sayılır
   (TR 98/100, EN 97/100).
7. Mevcut sim ekran görüntüleri eski düzen, **test verisi + hata durumu**
   içeriyor ve Tablo görünümü artık açılmıyor; mağaza için yeniden çekim
   gerekli (06).

## Sahibin yapacakları (Claude yapmadı)

- Yayındaki gizlilik sayfasını (`PRIVACY_POLICY_URL`) `03` metniyle
  değiştirmek; istenirse aynı adresi derlemede
  `--dart-define=PRIVACY_POLICY_URL=…` ile vermek.
- Destek URL'si (zorunlu), isteğe bağlı pazarlama URL'si ve telif satırı.
- App Store Connect'te App Privacy formunu 02'deki tabloya göre doldurmak.
- Yaş anketi: Guns or Other Weapons = Frequent → 13+.
- EN ad/alt başlık çevirisini onaylamak (`Sniper Türk: Ballistics` /
  `For Firearms and PCP Rifles`).
- Ekran görüntülerini 06'ya göre yeniden çekmek (6.9" ve 6.3").
- İzin metni düzeltmesi (04) için ayrı kod PR'ına onay.
- Yayın arşivinde Xcode "Generate Privacy Report" ile 02'deki tabloyu
  teyit etmek (`share_plus` bildirimi dökümde yok).
