# Askeri fişek verisi — notlar (2026-10-10)

`military.json`: 11 kayıt. Her değer yalnızca kaydın `source_url` adresinde (ya da notta adı geçen ikinci resmî kaynakta) okunmuştur. Okunmayan değer `null` bırakıldı.

## Kararlar

- **23.7 m hızı ≠ namlu çıkış hızı.** MKE hızları namludan 23.7 m (78 ft) uzakta ölçülmüş. Bunlar `muzzle_velocity_fps` alanına yazılmadı; iki ek alana yazıldı: `range_velocity_fps` ve `range_velocity_distance_m`. Uygulama bu değerleri hız olarak kullanacaksa namlu ağzına geri hesaplaması gerekir.
- **Birim çevirme:** g × 15.4323584 = gr ve m/s × 3.2808399 = fps, 0.1 hassasiyetle. Kaynaktaki asıl değer her kaydın `notes` alanında duruyor.
- **`bullet_diameter_in`:** Hiçbir kaynak çap vermiyor. Nominal kalibre yazıldı (0.224 / 0.308 / 0.338 / 0.510).
- **M855 / M855A1:** Hızlar M16 tüfeğine ait (`test_barrel_in`: 20). M4 hızları notlarda.
- **Mk 262 Mod 1:** Black Hills'in ticari Mod 1-C değerleri kullanıldı.
- **.338 Lapua:** Askeri tip adı olan bir match fişeği bulunamadı. Lapua 250 gr Scenar eklendi; Nammo bu fişeğin özel kuvvetlerde kullanıldığını yazıyor.
- İzli, zırh delici, yanıcı ve büzmeli fişekler (M61, M62, M8, M17, API vb.) kapsam dışı tutuldu. Talimat yalnızca ball/match türlerini ve M2 AP'yi istiyordu.

## Bulunamayanlar (JSON'a eklenmedi)

| Fişek | Neden |
|---|---|
| M118LR, M118 Special Ball (ABD), M80 (ABD), M193 (ABD), M2 AP (.50) | TM 43-0001-27 erişilebilen kopyaları (bulletpicker, armimilitari, koreanwaronline) PDF metninde yalnızca 8. bölüme kadar okunabildi; 5.56 / 7.62 / .50 bölümleri (9–11) okunamadı. armypubs.army.mil robots nedeniyle erişilemedi. Not: bu TM hızları zaten 78 ft'te veriyor. |
| Mk 318 Mod 0 | Üreticinin (Federal) sitesinde değer yok; resmî açık belge bulunamadı. |
| 7.62×39 M43 / 57-N-231, 7.62×54R 57-N-323S / 7N1 | Üretici ya da resmî açık kaynak okunamadı. |
| MKE 7.62×54 Normal, MKE 7.62×39 Çelik Çekirdekli, MKE 12.7×99 M33, MKE 12.7×99 M2 AP, MKE 12.7×99 Solid Keskin Nişancı | Ürün sayfaları var (adresleri aşağıda), ama bu çalışmada getirme izni zaman aşımına uğradı ve okunamadı. |

Okunamayan MKE sayfaları (bir sonraki çalışmada denenmeli):

- https://www.mke.gov.tr/Urunler/762-mm-x-54-Fisek-Normal/155
- https://www.mke.gov.tr/Urunler/762-mm-x-39-Fisek-Celik-Cekirdekli/153
- https://www.mke.gov.tr/Urunler/127-mm-x-99-50-cal-Fisek-M33/137
- https://www.mke.gov.tr/Urunler/127-mm-x-99-Fisek-M2-AP/134
- https://www.mke.gov.tr/Urunler/127mmx99-50-Cal-Fisek-Solid-Keskin-Nisanci/135
