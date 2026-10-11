# App Store yayın materyali — TASLAK (2026-10-11)

> Bu klasör yalnızca taslaktır. App Store Connect'e hiçbir şey gönderilmedi,
> hesap/form işlemi yapılmadı, kod ve `Info.plist` üreten araçlar
> değiştirilmedi. Kaynak: `main @ 835b956`.

| Dosya | İçerik |
|---|---|
| [01-magaza-metinleri.md](01-magaza-metinleri.md) | TR/EN ad, alt başlık, tanıtım metni, açıklama, anahtar kelimeler, Yenilikler, URL yer tutucuları |
| [02-gizlilik-etiketi.md](02-gizlilik-etiketi.md) | Koddan çıkarılan veri akışı ve App Privacy cevap taslağı |
| [03-gizlilik-politikasi.md](03-gizlilik-politikasi.md) | TR/EN gizlilik politikası taslağı |
| [04-info-plist-izinleri.md](04-info-plist-izinleri.md) | İzin açıklamaları denetimi, eksik/belirsiz olanlar, öneri metinleri |
| [05-inceleme-kurallari-ve-yas.md](05-inceleme-kurallari-ve-yas.md) | İlgili App Review maddeleri, yaş derecesi önerisi (13+), riskler, inceleme notu |
| [06-ekran-goruntusu-plani.md](06-ekran-goruntusu-plani.md) | 6.9" / 6.5" (+ zorunlu 6.3") ekran görüntüsü sırası ve başlıkları |
| `check_lengths.py` | 01'deki metinlerin karakter/bayt sınırlarını denetler: `python3 docs/app-store/check_lengths.py` |

## Öne çıkan bulgular

1. **Uygulama içinde gizlilik politikası bağlantısı yok** (5.1.1(i)) — kod
   değişikliği gerekir, sahip onayı bekliyor.
2. **Google Maps SDK** her derlemeye giriyor ve kendi gizlilik bildiriminde
   cihaz kimliği, kullanım, performans, çökme ve "diğer" veri topluyor
   (izleme yok). Mevcut gizlilik taslağı/etiket planı bunu içermiyor.
3. **Konum izin metni eksik:** harita, yerel yerçekimi ve özel konum
   hesaplayıcısı da konumu kullanıyor; Coriolis enlemi cihazda saklanıyor.
   Kamera (eğim ölçümü) ve hareket (atış açısı, eğim) metinleri de eksik.
4. **Yaş:** "Guns or Other Weapons = Frequent" → **13+**.
5. **Anahtar kelime sınırı 100 bayttır**; Türkçe harfler 2 bayt sayılır.
6. Mevcut sim ekran görüntüleri 6.3" boyutunda ve **test verisi + hata
   durumu** içeriyor; mağaza için yeniden çekim gerekli.

## Sahibin yapacakları (Claude yapmadı)

- Ad/alt başlık seçimi, destek ve pazarlama URL'lerinin belirlenmesi.
- Gizlilik politikasının onaylanıp yayındaki sayfanın güncellenmesi.
- App Store Connect'te App Privacy ve yaş anketinin girilmesi.
- Uygulama içi gizlilik bağlantısı ve izin metni düzeltmesi için ayrı kod PR'ına onay.
- Yayın arşivinde Xcode "Generate Privacy Report" ile 02'deki tablonun teyidi.
