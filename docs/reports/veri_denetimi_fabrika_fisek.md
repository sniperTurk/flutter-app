# Veri denetimi: fabrika fişeği kütüphanesi (`lib/data/factory_ammo_library.dart`)

Tarih: 14 Ekim 2026 (İstanbul). Dal: `audit/veri-fabrika-fisek`. Yalnız denetim: `lib/` değişmedi.

## Özet (sade Türkçe)

- **Kayıt sayısı:** 1813 fabrika fişeği (961 farklı kaynak adresi, 30 marka).
- **Üretici kaynağına karşı kontrol edilen:** **29 kayıt** (%1,6), hepsi Aguila. Her kayıtta 7 alan bakıldı (ad, kalibre, ağırlık, hız, test namlusu, BC, BC modeli): 203 kontrol.
  - OK: 184 kontrol (%90,6). Kayıt bazında: 20 kayıt tamamen doğru, 1 kayıt HATALI, 8 kayıt ŞÜPHELİ.
- **Kalan 1784 kayıt üretici kaynağına karşı kontrol EDİLEMEDİ (ERİŞİLEMEDİ).** Sebep: bu oturumda web sayfası okuma aracı (WebFetch) ilk ~30 sayfadan sonra her istekte **HTTP 429 (hız sınırı)** döndü; yaklaşık 30 dakika içinde bekleyerek dört kez daha denedim, sınır kalkmadı. Doğrudan bağlantı (curl/python) bu ortamda üretici sitelerine kapalı (vekil sunucu 403). Bu kayıtlar CSV'de tek tek ERİŞİLEMEDİ olarak duruyor; **"doğru" sayılmadı**. İş, sınır kalkınca aynı dalda devam edecek şekilde hazır (aşağıda "Kalan iş").
- **İç tutarlılık kontrolü: 1813 kaydın hepsi** (kaynağa bakmadan, dosyanın kendi içinde). 67 kayıt ŞÜPHELİ işaretlendi, 1746 kayıt temiz. Ayrıntı aşağıda.

### Alan bazında yanlış sayısı (kontrol edilen 29 kayıtta)
| Alan | OK | HATALI | ŞÜPHELİ |
|---|---|---|---|
| Ad / ürün eşleşmesi | 28 | 1 | 0 |
| Kalibre | 29 | 0 | 0 |
| Mermi ağırlığı (gr) | 28 | 1 | 0 |
| Namlu çıkış hızı (fps) | 28 | 1 | 0 |
| Test namlusu | 29 | 0 | 0 |
| BC | 21 | 0 | 8 |
| BC modeli (G1/G7) | 21 | 0 | 8 |

### En ciddi hatalar ve hesaba etkisi
1. **Satır 77, Aguila "22 Long Rifle Standard Velocity Lead Solid Point": 29 gr / 1095 fps yazılmış, üretici 40 gr / 1130 fps diyor.** 29 gr / 1095 fps, katalogda aynı blokta duran Aguila **22 Short** ürününe ait (komşu satır karışması). Etki (örnek BC 0,12 G1, 50 m sıfır, nişan yüksekliği 40 mm, ICAO hava; uygulamanın referans çözücüsü `tools/formula_reference.py`): 100 m'de düşüş düzeltmesi 2,33 yerine 2,21 mrad (**≈1,2 cm fark**), 150 m'de 5,25 yerine 5,01 mrad (**≈3,5 cm**); 100 m'de enerji 72 J yerine 102 J olmalı (**%30 düşük gösteriliyor**).
2. **Aguila 8 tüfek fişeğinde BC'nin üretici kaynağı yok** (satır 183, 326, 422, 674, 770, 875, 1321, 1591). Kütüphanede G1 BC var (ör. .308 Win 150 gr SP için 0,338), ama Aguila'nın ürün sayfaları ve 2023 kataloğu BC yayımlamıyor. Değer yanlış demiyoruz; üreticiden geldiği gösterilemiyor. Kural gereği (yalnız üretici verisi) sahibin kararı gerekiyor: ya üreticiden kaynak bulunur ya BC boş bırakılır.

### İç tutarlılık bulguları (1813 kaydın hepsi; kaynağa bakılmadan)
Araç: `tools/research/fabrika_fisek_ic_denetim.py`. Bunlar "yanlış" değil, "önce buna bak" işaretleri:
- **BC_UYARI (18 kayıt):** BC/ağırlık oranı uygulamanın kendi uyarı sınırının (`_bcPlausibilityWarning`: G7 için 0,63–1,8) dışında; yani kullanıcı bu fişeği seçince profil sayfası "BC şüpheli" uyarısı gösterir. 18'i de Sellier & Bellot SP/FMJ (G7 etiketli; ör. satır 1647 7mm Rem Mag 140 gr SP G7 0,115 → biçim katsayısı 2,16).
- **BC_MODEL (6 kayıt):** değer etikete uymuyor olabilir: satır 1203 Barrett .416 500 gr A-Tip G7 0,492 (G7 için çok yüksek, G1 olabilir); satır 193, 238, 262, 296, 1312 (40–45 gr hafif/frangible mermilerde G1 ≈0,10).
- **AD_AGIRLIK (1 kayıt):** satır 1816 Geco STAR 9,3x62 "16,2g" adında 16,2 g = 250 gr, alan 255 gr.
- **MV_BIRIM (3):** satır 698, 699 (Black Hills .300 BLK 198/220 gr, 1050 fps), 710 (Remington UMC .300 BLK 220 gr OTFB, 940 fps): adda "Subsonic" yazmıyor; hız ses altı. Büyük olasılıkla doğru (ses altı yük), kontrol edilmeli.
- **MV_SAPMA (26):** aynı fişekte benzer ağırlıktakilerden %12'den fazla farklı hız. Satır 77 burada da yakalanıyor (−%30). Çoğu rimfire özel yük (Quiet-22, Velocitor, Interceptor) ve 8x57 JS'nin ABD düşük basınçlı yükleri; büyük olasılıkla doğru.
- **SD_ARALIK (8), NAMLU (7):** hafif .17/.22 rimfire mermileri ve .50 BMG'nin 32–45 inç namluları; olağan, kontrol önceliği düşük.
- Birebir kopya satır, aynı fişekte farklı çap, aynı ad farklı değer: **yok**.
- BC_OLAGANDISI (58): yalnız öncelik notu, ŞÜPHELİ sayılmadı.

## HATALI / ŞÜPHELİ tablosu (önerilen düzeltme + kaynak)

### Üretici kaynağına karşı
| Satır | Marka / ürün | Alan | Kütüphane | Üretici | Durum | Öneri | Kaynak |
|---|---|---|---|---|---|---|---|
| 77 | Aguila 22 LR Standard Velocity Lead Solid Point | ad | 22 LR SV LSP | değerler 22 Short'a ait | HATALI | ağırlık/hızı 22 LR değerleriyle değiştir | [aguilaammo.com](https://www.aguilaammo.com/products/22-super-extra-long-rifle-standard-velocity-lead-solid-point) "40 Grain" |
| 77 | 〃 | ağırlık | 29 gr | 40 gr | HATALI | 40 | 〃 |
| 77 | 〃 | hız | 1095 fps | 1130 fps | HATALI | 1130 | 〃 "Muzzle 1130" |
| 183 | Aguila 22-250 Rem 60 gr SP | BC / model | 0,264 G1 | yayımlanmıyor | ŞÜPHELİ | üretici kaynağı bulunmazsa BC boş | [aguilaammo.com](https://www.aguilaammo.com/products/22-250-rem-60-gr-soft-point) |
| 326 | Aguila .243 Win 100 gr BTSP | BC / model | 0,405 G1 | yayımlanmıyor | ŞÜPHELİ | 〃 | aguilaammo.com ürün sayfası |
| 422 | Aguila .270 Win 130 gr SP | BC / model | 0,409 G1 | yayımlanmıyor | ŞÜPHELİ | 〃 | 〃 |
| 674 | Aguila .30-30 Win 150 gr RN | BC / model | 0,186 G1 | yayımlanmıyor | ŞÜPHELİ | 〃 | 〃 |
| 770 | Aguila .300 Win Mag 180 gr SP | BC / model | 0,425 G1 | yayımlanmıyor | ŞÜPHELİ | 〃 | 〃 |
| 875 | Aguila .308 Win 150 gr SP | BC / model | 0,338 G1 | yayımlanmıyor | ŞÜPHELİ | 〃 | 〃 |
| 1321 | Aguila 6.5 Creedmoor 129 gr SP | BC / model | 0,445 G1 | yayımlanmıyor | ŞÜPHELİ | 〃 | 〃 |
| 1591 | Aguila 7mm Rem Mag 139 gr SP | BC / model | 0,392 G1 | yayımlanmıyor | ŞÜPHELİ | 〃 | 〃 |

Her satırın tam URL'si, okuma tarihi ve kısa alıntısı `data/veri_denetimi/fabrika_fisek.csv` içinde.

### İç tutarlılıktan (üretici kaynağıyla doğrulanmadı; öneri = kaynakta bakılacak alan)
Tam liste CSV'de `field = ic_tutarlilik`, `status = ŞÜPHELİ` (67 kayıt). Öncelikli olanlar:
| Satır | Marka / ürün | Bulgu | Bakılacak |
|---|---|---|---|
| 1203 | Barrett .416 Barrett Hornady 500 gr A-Tip | G7 0,492 (G7 için çok yüksek) | BC etiketi G1 mi |
| 1647, 1694, 1706, 1727, 1743 | S&B 140 gr SP (7mm RM, 7x57, 7x57 R, 7x64, 7x65 R) | G7 0,115, biçim katsayısı 2,1 | BC değeri / etiketi |
| 477, 478, 526, 527, 655, 680, 1047, 1470, 1748, 1838, 1839, 1844, 73 | S&B SP/FMJ | G7 BC'si uygulamanın uyarı sınırında/dışında | BC değeri / etiketi |
| 193, 1312 | RWS HIT 2,6 g (.222 Rem, 5.6x50 R Mag) | G1 0,107–0,108, 40 gr monolitik için düşük | BC etiketi |
| 238, 262, 296 | Fiocchi 45 gr, Magtech 42 gr frangible, Sako Blade Solid 40 gr | G1 ≈0,10 | BC etiketi |
| 1816 | Geco STAR 9,3x62 16,2 g | adda 250 gr, alanda 255 gr | ağırlık |
| 698, 699, 710 | Black Hills / Remington .300 BLK | 940–1050 fps, adda "subsonic" yok | hız |

## Nasıl yapıldı
1. `tools/research/fabrika_fisek_ic_denetim.py` dosyayı ayrıştırır (1813 kayıt) ve kaynağa bakmadan kontrol eder: ad içindeki ağırlık ↔ grain alanı (g/gr çevirisiyle), kesitsel yoğunluk aralığı, BC/ağırlık biçim katsayısı (uygulamadaki `_bcPlausibilityWarning` sınırları + kütüphanenin %1–97 dilimi), aynı fişekte benzer ağırlıkta hız sapması, m/s gibi duran hızlar, test namlusu aralığı, aynı fişekte farklı çap, birebir kopya ve aynı ad farklı değer.
2. Kayıtlar kaynak adresine göre 42 parti halinde gruplandı; her parti için üretici sayfası okunup 7 alan karşılaştırılacaktı. Kurallar: yalnız üretici sayfası/PDF'i; bayi, forum, blog ve başka balistik uygulama verisi yok; robots.txt'ye uyuldu (rws-ammunition.com ve JSB hiç okunmadı). Pilot parti (Aguila + küçük markalar) çalıştı; Aguila'nın 29 kaydı okundu, sonra okuma aracı hız sınırına takıldı.
3. `tools/research/fabrika_fisek_denetim_csv.py` sonuçları ve iç kontrolleri `data/veri_denetimi/fabrika_fisek.csv` dosyasına yazar: her kayıt için 7 alan satırı + 1 iç tutarlılık satırı (1813 × 8 = 14504 satır). Okunmamış her alan açıkça ERİŞİLEMEDİ.

## Uç durumlar / dikkat
- Aguila BC'leri "yanlış" değil "kaynaksız" olarak işaretlendi; değerin kendisi makul.
- İç kontrol bayrakları yanlış alarm verebilir (ses altı yükler, rimfire özel yükler). Bunlar yalnız öncelik içindir.
- Üretici sayfasını güncellediyse güncel üretici değeri esas alınacak (kural gereği).

## Bilerek yapılmayan
- `lib/data/` dahil hiçbir uygulama dosyası değişmedi; düzeltmeler sahibin onayını bekliyor.
- Üretici sayfası okunamayan 1784 kayıt için tahmin, hafızadan değer, bayi/forum değeri **kullanılmadı**.
- Birleştirme (merge) ve TestFlight yok.

## Kalan iş
- WebFetch hız sınırı kalkınca kalan 41 parti (Federal, Sellier & Bellot, Winchester, RWS katalog, Norma, Hornady, Remington, Weatherby, Black Hills, PPU, Geco, Lapua, Fiocchi, Barnes, Nosler, Magtech, Berger, CCI, Sako, SWISS P, PMC, Sierra, MKE, SIG, Blaser, CheyTac, Barrett, ELEY, M855) aynı yöntemle okunup bu CSV ve rapor güncellenecek. Öncelik: iç tutarlılık ŞÜPHELİ olan 67 kayıt.

## Testler (yerel)
- `python3 -m unittest discover -s tools -p 'test_*.py'`
- `python3 tools/offline_dart_lint.py`
Sonuçlar PR açıklamasında. Bu PR Dart kodu değiştirmediği için Flutter/iOS CI'ı bu değişiklikle ilgili bir şey ölçmez; CI sonucu ayrıca belirtilmiştir.
