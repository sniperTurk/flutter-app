# Veri denetimi: mermi ve saçma kütüphanesi (`lib/data/bullet_library.dart`)

Tarih: 14.10.2026 (İstanbul). Bu iş yalnızca bir denetim. `lib/` altında hiçbir dosya değişmedi. Düzeltmeleri sahip onaylarsa ayrı bir görevde yapılacak.

Çıktılar:
- Satır satır kayıt: `data/veri_denetimi/mermi.csv`. Her satır bir kayıt ve bir alan için: satır no, marka, ad, alan, kütüphane değeri, üretici değeri, durum, URL, okuma tarihi, en fazla 15 kelimelik alıntı.
- İç tutarlılık betiği: `tools/veri_denetimi_mermi.py`. Kütüphaneyi yalnızca okur.

## Özet

- **Kayıt sayısı: 2084.** Ateşli silah mermisi 1566, PCP saçma/slug 518. Bunlar için **8224 alan kontrolü** yapıldı.
- **Alan sonuçları:**
  - OK: 7331 (%89,1)
  - HATALI: 16
  - ŞÜPHELİ: 236
  - ERİŞİLEMEDİ: 641
- **Okunabilen alanlarda doğruluk %96,7.** 7583 alan okunabildi, 7331'i OK.
- **Kayıt sonuçları:**
  - 1371 kaydın (%65,8) tüm alanları üreticiyle aynı.
  - 15 kayıtta en az bir HATALI alan var.
  - 199 kayıtta en kötü durum ŞÜPHELİ.
  - 499 kayıtta en az bir alan okunamadı. Bunların 223'ünde hiçbir alan okunamadı.

### Alana göre sonuç

| Alan | OK | HATALI | ŞÜPHELİ | ERİŞİLEMEDİ |
|---|---|---|---|---|
| Ağırlık (weight) | 1849 | 0 | 2 | 225 |
| Çap (diameter) | 1763 | 3 | 12 | 1 |
| BC G1 (bc_g1) | 1548 | 11 | 87 | 91 |
| BC G7 (bc_g7) | 395 | 1 | 49 | 134 |
| Hız bantları (bc_bands) | 49 | 0 | 0 | 0 |
| Formun BC modeli (bc_form) | 0 | 0 | 42 | 0 |
| Uzunluk (length) | 684 | 0 | 2 | 182 |
| Ad / ürün eşleşmesi (name) | 1043 | 1 | 42 | 8 |

**Ağırlıkta hata bulunmadı.** Aguila örneğindeki gibi bir gram/grain karışıklığına mermi kütüphanesinde rastlanmadı. Hataların çoğu BC değerinde.

### En önemli hatalar ve hesaba etkisi

Etki, depodaki referans çözücüyle (`tools/formula_reference.py`) hesaplandı. Varsayımlar: G1 modeli, 100 m sıfır, ICAO hava, 4 m/s yan rüzgâr, belirtilen tipik namlu çıkış hızı. Tablodaki sayılar, uygulamanın kütüphane değeriyle verdiği düzeltmenin, üretici değeriyle verilmesi gerekenden ne kadar farklı olduğudur.

| Satır | Mermi | Alan | Kütüphane → Üretici | Etki |
|---|---|---|---|---|
| 664 | Sierra 22 Cal 69 gr HPBT MatchKing (#1380), 2900 fps | G1 | 0,341 → 0,301 (−%12) | 600 m'de düşüş 0,56 mrad (33 cm), 800 m'de 1,34 mrad (108 cm) eksik. Rüzgâr düzeltmesi 800 m'de 0,56 mrad (45 cm) eksik. |
| 814 | Sierra 270 Cal 175 gr Tipped GameKing (#4475), 2650 fps | G1 | 0,633 → 0,560 (−%12) | 800 m'de düşüş 0,50 mrad (40 cm), rüzgâr 0,26 mrad (21 cm) eksik. |
| 875 | Barnes .423 400 gr Banded Solid (404 Jeffery), 2150 fps | G1 | 0,261 → 0,236 (−%10) | 400 m'de düşüş 0,43 mrad (17 cm) eksik. |
| 843 | Barnes .510 535 gr Banded Solid (500 Jeffery), 2350 fps | G1 | 0,238 → 0,215 (−%10) | 400 m'de düşüş 0,43 mrad (17 cm) eksik. Kaynak 2008 tarihli bir PDF. |
| 620 | Hornady .257 95 gr ELD-VT, 3100 fps | G1 | 0,433 → 0,453 (+%5) | 800 m'de düşüş 0,21 mrad (17 cm) fazla. |
| 862 | Barnes .264 120 gr Match Burner, 2900 fps | G1 | 0,476 → 0,460 (−%3) | 800 m'de 0,17 mrad (14 cm). |
| 811 | Sierra 270 Cal 135 gr SMK (#1833), 2950 fps | G1 | 0,505 → 0,488 (−%3) | 800 m'de 0,14 mrad (12 cm). |

Diğer HATALI bulgular küçük:
- Hornady .243 80 gr ELD-VT: 0,41 → 0,405 G1 ve 0,206 → 0,202 G7.
- Hornady .458 250 gr MonoFlex: 0,175 → 0,182.
- Sierra 35 Cal 155 gr Pro-Hunter: 0,176 → 0,182.
- Sierra 6.5mm 120 gr TGK: 0,466 → 0,482.
- H&N .22 ve .177 saçmalarında üç çap değeri, üreticinin baş ölçüsü yerine nominal kalibre ile yazılmış. Örnek: 5,588 mm yazıyor, üretici 5,51–5,52 mm diyor.
- Hammer'da bir ürün adı eskimiş: 125 gr yazıyor, üretici şimdi 124 gr diyor. Ağırlık alanı zaten 124.

### ŞÜPHELİ bulguların başlıcaları

- **Zan Projectiles, 59 BC değeri.** Zan hiçbir sayfasında BC yayımlamıyor: ya hiç yok ya da "TBA" yazıyor. Kütüphanedeki 0,048–0,458 arası G1 değerlerinin bir üretici kaynağı yok. Düz ürün ile Hyper Line eşlerinde birebir aynı olmaları, bir satırdan diğerine kopyalandıklarını gösteriyor. Öneri: bu BC'leri boşaltmak.
- **Hornady G7 eksikleri.** 26 kayıtta üretici G7 yayımlıyor ama kütüphanede yok: CX, AeroMatch, ELD-VT. 12 kayıtta form G1 kullanıyor. CX 112 gr için üretici "TBD" diyor, kütüphanede ise 0,524 / 0,264 var.
- **G7 yayımlanıyor ama form G1 kullanıyor:**
  - Cutting Edge: 16 kayıt.
  - Nosler: 13 kayıt.
  - Barnes: 5 kayıtta G7 eksik.
- **Barnes Banded Solid BC'leri.** Load-data PDF'leriyle farklı. En büyük fark .458 450/500 gr'da: kütüphane 0,267/0,301, PDF 0,362/0,394. Barnes'ın kaynakları kendi içinde de çelişiyor. Örnek: 416 Rem Mag PDF'inde 0,217, 416 Rigby PDF'inde 0,364. Güncel bir Barnes kaynağıyla teyit gerekiyor.
- **Sierra.** Satır 631 (4682) ile satır 677 (MKX 9380), başka satırların BC'leriyle birebir aynı ve kaynakları yok. Komşu satırdan kopyalanmış olabilirler.
- **Peregrine Glider.** 3 kayıtta G1 eksik. Üreticide aynı ada sahip iki .308 166 gr satırı var.
- **NSA.** 24 slug'da üretici sayfası düz taban (FB) ile çanak tabanı (DB) arasında kendi içinde çelişiyor. Satır 1929 aslında "Truncated Cone".
- **Diğerleri:**
  - Lapua E471 ağırlığı: 155 / 156 gr.
  - Crosman Ultra Heavy .22: 2025 kataloğunda 19 gr, kütüphanede 22 gr.
  - Hammer'da 4 ürünün adındaki gram ile sayfadaki ağırlık farklı. Üretici kendi içinde çelişiyor; grain alanı sayfadaki ağırlıkla aynı.

### Erişilemeyenler ve nedenleri

| Neden | Etkilenen |
|---|---|
| robots.txt izin vermiyor (rws-ammunition.com) | RWS'in 64 kaydının tamamı. Kayıtta "erişilemedi" yazıyor; başka yoldan denenmedi. |
| Proxy hız sınırı (HTTP 429), iki tur denendi | Swift 51, Speer 56 (BC ve ağırlık), Diana 14, Air Arms 11, My Bullet 7, FX 1, Hornady ECX ile birkaç ürün (13), Barnes ve Sierra'da birkaç ürün |
| Değer yalnızca JavaScript sekmesinde, statik kaynak yok | Sierra'nın 132 G7 değeri, Barnes'ın 175 mermi uzunluğu |

JSB kütüphanede yok. Bu kayıtlar, hız sınırı kalktığında aynı yöntemle yeni bir çalışmada denenebilir.

### İç tutarlılık kontrolleri

`tools/veri_denetimi_mermi.py checks` ile bütün dosya tarandı ve 100 bulgu çıktı. Bulgular önceliklendirmede kullanıldı, sonra her biri üreticiyle karşılaştırıldı. Taranan konular:
- kesit yoğunluğu,
- form faktörü (SD/BC),
- addaki ağırlık ve kalibre,
- kalibre ile çap farkı,
- birebir aynı satırlar,
- aynı ailede ağırlık artarken BC'nin düşmesi.

Sonuç:
- **Gerçek sorun çıkanlar:**
  - Hammer'da addaki ve alandaki ağırlık farkı (5 kayıt).
  - Zan'da birebir aynı BC'ler.
  - Sierra'da 631 ve 677.
- **Üretici değeriyle doğrulananlar:** Berger, Woodleigh, Lapua, Peregrine ve H&N'deki "aynı değer" eşleri. Üretici gerçekten aynı değeri yayımlıyor.
- **Mermi tipinden kaynaklananlar:** Nosler 220 gr Partition, Peregrine BushMaster gibi ailede BC düşüşleri. Daha küt burunlu mermilerin değeri, hata değil.
- **Betik hatası:** Nosler 6.8mm. Betik düzeltildi.

### Yöntem ve sınırlar

- **Kaynaklar.** Yalnızca üreticinin kendi sitesi, kataloğu ya da PDF'i kullanıldı. Bayi, forum ve başka balistik uygulama kaynağı kullanılmadı.
- **Okuma yöntemi.** Sayfalar WebFetch ile okundu. Bu araç sayfayı bir modelle özetliyor. Bu yüzden CSV'deki alıntıların bir kısmı birebir sayfa metni değil, tablo satırının aktarımı. Bu satırlar alıntı sütununda belirtildi.
- **Okuma tarihi:** 14.10.2026.
- **HATALI değerler düzeltilmeden önce** bir kez de PDF ya da sayfa görselinden elle teyit edilmeli. Hornady CX G7 değerleri, katalogdaki karışık sütun metninden G1/G7 oranıyla eşlendi; bunlar mutlaka görselden teyit edilmeli.
- **Hornady hız bantları.** Kütüphanedeki 2372 ve 2093 fps sınırları Hornady'nin Mach 2,25 / 2,0 / 1,75 noktalarının orta değerleri. Değerler aynı, eşikler ise tasarım tercihi. Bunlar OK sayıldı.
- **İstenmediği için yapılmayanlar:**
  - Kütüphanede olmayan üretici ürünleri eklenmedi.
  - Warner 1416–1418 için üreticinin G1 değerleri (1,310 / 1,200 / 1,103) yalnızca not edildi; o turda bu alan kapsam dışıydı.

## Tüm HATALI bulgular ve önerilen düzeltmeler

| Satır | Marka | Ad | Alan | Kütüphane | Üretici | Önerilen düzeltme | Kaynak |
|---|---|---|---|---|---|---|---|
| 394 | H&N | Baracuda Match .22 cal. | diameter | 5.588 mm | 5.51 mm / 5.52 mm | çap 5,52 mm (üretici baş ölçüsü 5,51–5,52) | [link](https://www.hn-sport.de/en/air-gun-hunting-target-shooting/baracuda-match-22) |
| 399 | H&N | Baracuda 8 .177 cal. | diameter | 4.521 mm | 4.51 mm | çap 4,51 mm | [link](https://www.hn-sport.de/en/air-gun-hunting-target-shooting/baracuda-8-177) |
| 409 | H&N | Field Target Trophy .22 cal. | diameter | 5.588 mm | 5.53 mm / 5.54 mm / 5.55 mm | çap 5,53 mm (üretici 5,53–5,55; baş ölçüsüne göre ayrı satır da olabilir) | [link](https://www.hn-sport.de/en/air-gun-hunting-target-shooting/field-target-trophy-22) |
| 553 | Hornady | .458 250 gr MonoFlex | bc_g1 | 0.175 | .182 G1 | bc_g1 = .182 G1 | [link](https://static.hornady.media/site/hflipbook/inc/html/95.html) |
| 603 | Hornady | .243 80 gr ELD-VT | bc_g1 | 0.41 | .405 G1 | bc_g1 = .405 G1 | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 603 | Hornady | .243 80 gr ELD-VT | bc_g7 | 0.206 | .202 G7 | bc_g7 = .202 G7 | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 620 | Hornady | .257 95 gr ELD-VT | bc_g1 | 0.433 | .453 G1 | bc_g1 = .453 G1 | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 664 | Sierra | 22 Cal 69 gr HPBT MatchKing SMK | bc_g1 | 0.341 G1 | 0.301 (G1, catalog B.C.) | bc_g1 = 0.301 (G1, catalog B.C.) | [link](https://sierrabullets.com/content/2025-sierra-bullets-catalog-poster.pdf) |
| 769 | Sierra | 35 Cal 155 gr FN Pro-Hunter | bc_g1 | 0.176 G1 | .182 G1 | bc_g1 = .182 G1 | [link](https://sierrabullets.com/content/2025-sierra-bullets-catalog-poster.pdf) |
| 811 | Sierra | 270 Cal 135 gr HPBT MatchKing SMK | bc_g1 | 0.505 G1 | .488 G1 | bc_g1 = .488 G1 | [link](https://sierrabullets.com/content/2025-sierra-bullets-catalog-poster.pdf) |
| 812 | Sierra | 6.5mm 120 gr Tipped GameKing TGK | bc_g1 | 0.466 G1 | .482 G1 | bc_g1 = .482 G1 | [link](https://sierrabullets.com/content/2025-sierra-bullets-catalog-poster.pdf) |
| 814 | Sierra | 270 Cal 175 gr Tipped GameKing TGK | bc_g1 | 0.633 G1 | .560 G1 | bc_g1 = .560 G1 | [link](https://sierrabullets.com/content/2025-sierra-bullets-catalog-poster.pdf) |
| 843 | Barnes | .510 535 gr Banded Solid RN | bc_g1 | 0.238 G1 | 0.215 G1 | 0,215 (kaynak 2008 tarihli PDF; güncel Barnes kaynağıyla teyit) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/510/500Jeffery.pdf) |
| 862 | Barnes | .264 120 gr Match Burner BT | bc_g1 | 0.476 G1 | 0.460 G1 | bc_g1 = 0.460 G1 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/264/6.5-Creedmoor.pdf) |
| 875 | Barnes | .422 400 gr Banded Solid RN | bc_g1 | 0.261 G1 | 0.236 G1 | bc_g1 = 0.236 G1 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/423/404JefferyWeb.pdf) |
| 1842 | Hammer Bullets | .264 Cal-125 gr Hammer Hunter® | name | .264 Cal-125 gr Hammer Hunter® | .264 Cal-124gr Hammer Hunter® | ad ".264 Cal-124 gr Hammer Hunter®" (SKU 26124HH; ağırlık 124 gr zaten doğru) | [link](https://hammerbullets.com/product/264-cal-125gr-hammer-hunter/) |

## Tüm ŞÜPHELİ bulgular

| Satır | Marka | Ad | Alan | Kütüphane | Üretici | Önerilen düzeltme | Kaynak |
|---|---|---|---|---|---|---|---|
| 89 | Berger | 30 Caliber 175 gr VLD Target | name | 30 Caliber 175 gr VLD Target | DISCONTINUED (üretici sayfası); 2026 kataloğunda yok | üretici "DISCONTINUED": gizleme kararı sahipte; değerler doğru | [link](https://bergerbullets.com/product/30-caliber-175-grain-very-low-drag-vld-target/) |
| 197 | Berger | 30 Caliber 217 gr Elite Hunter | bc_g1 | 0.695 | 0.695 G1 (ürün sayfası + 2025 katalog); 0.702 G1 (2026 katalog) | değişiklik yok (ürün sayfası = kütüphane; 2026 katalog farklı) | [link](https://bergerbullets.com/product/30-caliber-217-grain-elite-hunter-rifle-bullet/) |
| 197 | Berger | 30 Caliber 217 gr Elite Hunter | bc_g7 | 0.356 | 0.356 G7 (ürün sayfası + 2025 katalog); 0.347 G7 (2026 katalog) | değişiklik yok (aynı neden) | [link](https://bergerbullets.com/product/30-caliber-217-grain-elite-hunter-rifle-bullet/) |
| 200 | Berger | 270 Caliber 150 gr Hybrid Target | bc_g1 | 0.552 | 0.552 G1 (ürün sayfası); 0.580 G1 (2025 katalog); 0.566 G1 (2026 katalog) | değişiklik yok (üreticinin 3 kaynağı farklı) | [link](https://bergerbullets.com/product/270-caliber-150-grain-hybrid-target-rifle-bullet/) |
| 200 | Berger | 270 Caliber 150 gr Hybrid Target | bc_g7 | 0.283 | 0.283 G7 (ürün sayfası); 0.297 G7 (2025 katalog); 0.282 G7 (2026 katalog) | değişiklik yok | [link](https://bergerbullets.com/product/270-caliber-150-grain-hybrid-target-rifle-bullet/) |
| 200 | Berger | 270 Caliber 150 gr Hybrid Target | length | 34.06 | 1.341 in = 34.06 mm (ürün sayfası); 1.384 in (2025 katalog) | değişiklik yok | [link](https://bergerbullets.com/product/270-caliber-150-grain-hybrid-target-rifle-bullet/) |
| 215 | Lapua | Mega SP E471 | weight | 155.0 gr | 156 gr (başlık/katalog) / 155 gr (tablo) | 156 gr (10,1 g = 155,9 gr; başlık ve katalog 156) | [link](https://www.lapua.com/product/65-mm-mega-bullet-e471/) |
| 232 | Lapua | Center-X .22 LR (rimfire cartridge) | diameter | 5.69 mm | yayınlanmamış | değişiklik yok; Lapua .22 LR çap yayımlamıyor | [link](https://www.lapua.com/product/22-lr-lapua-center-x-rimfire-ammo/) |
| 233 | Lapua | Midas+ .22 LR (rimfire cartridge) | diameter | 5.69 mm | yayınlanmamış | değişiklik yok; Lapua .22 LR çap yayımlamıyor | [link](https://www.lapua.com/product/22-lr-lapua-midas-plus-rimfire-ammo/) |
| 365 | Nosler | 6.5mm 142gr AccuBond Long Range | bc_form | 0.625 g1 | 0.315 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 370 | Nosler | 22 Caliber 70gr RDF | bc_form | 0.416 g1 | 0.211 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 371 | Nosler | 6mm 105gr RDF | bc_form | 0.571 g1 | 0.280 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 372 | Nosler | 6.5mm 140gr RDF | bc_form | 0.658 g1 | 0.330 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 373 | Nosler | 30 Caliber 175gr RDF | bc_form | 0.536 g1 | 0.270 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 374 | Nosler | 338 Caliber 265gr AccuBond Long Range | bc_form | 0.732 g1 | 0.369 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 379 | Nosler | 6.5mm 130gr RDF | bc_form | 0.615 g1 | 0.307 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 380 | Nosler | 22 Caliber 85gr RDF | bc_form | 0.498 g1 | 0.245 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 381 | Nosler | 7mm 185gr RDF | bc_form | 0.719 g1 | 0.357 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 383 | Nosler | 22 Caliber 77gr RDF | bc_form | 0.454 g1 | 0.228 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 384 | Nosler | 30 Caliber 168gr RDF | bc_form | 0.505 g1 | 0.253 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 386 | Nosler | 22 Caliber 70gr AccuBond SP | length | 24.51 mm | 0.965 in (24.51 mm) product page; 0.985 in (25.02 mm) 2026 catalog | değişiklik yok (ürün sayfası 0,965"; katalog 0,985") | [link](https://www.nosler.com/22-caliber-70gr-accubond-sp-50ct.html) |
| 388 | Nosler | 338 Caliber 300gr AccuBond Long Range | bc_form | 0.785 g1 | 0.394 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 389 | Nosler | 6.5mm 150gr AccuBond Long Range | bc_form | 0.634 g1 | 0.319 G7 (maker publishes G1 and G7) | model g7 yap (üretici G7 yayımlıyor) | [link](https://www.nosler.com/media/binaryanvil/media_library/2026-Catalog-Layout_Web.pdf) |
| 415 | H&N | Slug HP 21 gr .22 cal. | diameter | 5.588 mm | 5.512 mm / 5.537 mm | baş ölçüsüne göre ayrı satır (ör. 5,512 / 5,537 mm) ya da nominal kalsın | [link](https://www.hn-sport.de/en/air-gun-hunting/slug-HP-22-21gr) |
| 416 | H&N | Slug HP II 25 gr .22 cal. | diameter | 5.588 mm | 5.512 mm / 5.537 mm | baş ölçüsüne göre ayrı satır (ör. 5,512 / 5,537 mm) ya da nominal kalsın | [link](https://www.hn-sport.de/en/air-gun-hunting/slug-HP-22-25gr) |
| 417 | H&N | Slug HP II 27 gr .22 cal. | diameter | 5.588 mm | 5.512 mm / 5.537 mm | baş ölçüsüne göre ayrı satır (ör. 5,512 / 5,537 mm) ya da nominal kalsın | [link](https://www.hn-sport.de/en/air-gun-hunting/slug-HP-22-27gr) |
| 418 | H&N | Slug HP II 30 gr .22 cal. | diameter | 5.588 mm | 5.512 mm / 5.537 mm / 5.563 mm | baş ölçüsüne göre ayrı satır (ör. 5,512 / 5,537 mm) ya da nominal kalsın | [link](https://www.hn-sport.de/en/air-gun-hunting/slug-HP-22-30gr) |
| 424 | H&N | Slug HP II 30 gr .25 cal. | diameter | 6.35 mm | 6.337 mm / 6.363 mm | baş ölçüsüne göre ayrı satır (ör. 5,512 / 5,537 mm) ya da nominal kalsın | [link](https://www.hn-sport.de/en/air-gun-hunting/slug-HP-25-30gr) |
| 425 | H&N | Slug HP II 32 gr .25 cal. | diameter | 6.35 mm | 6.337 mm / 6.363 mm | baş ölçüsüne göre ayrı satır (ör. 5,512 / 5,537 mm) ya da nominal kalsın | [link](https://www.hn-sport.de/en/air-gun-hunting/slug-HP-25-32gr) |
| 426 | H&N | Slug HP II 34 gr .25 cal. | diameter | 6.35 mm | 6.337 mm / 6.363 mm | baş ölçüsüne göre ayrı satır (ör. 5,512 / 5,537 mm) ya da nominal kalsın | [link](https://www.hn-sport.de/en/air-gun-hunting/slug-HP-25-34gr) |
| 513 | Hornady | .308 208 gr BTHP Match | bc_g7 | 0.311 G7 | yayımlanmamış (katalog yalnız G1) | Hornady kaynağı bulunamazsa g7 boş; G1 0,620 kalsın | [link](https://static.hornady.media/site/hflipbook/inc/html/80.html) |
| 554 | Hornady | .51 750 gr A-MAX | name | .51 750 gr A-MAX | 50 Cal .510 750 gr A-Tip Match | ürün "50 Cal .510 750 gr A-Tip Match" olarak yenilenmiş görünüyor; BC teyidi sonra | [link](https://www.hornady.com/bullets/rifle/50-cal-510-750-gr-a-max) |
| 573 | Hornady | .243 90 gr CX | bc_g7 |  | .210 G7 (eksik) | g7 ekle .210 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 575 | Hornady | .264 120 gr CX | bc_g7 |  | .215 G7 (eksik) | g7 ekle .215 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 576 | Hornady | .264 130 gr CX | bc_g7 |  | .246 G7 (eksik) | g7 ekle .246 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 577 | Hornady | .277 130 gr CX | bc_g7 |  | .203 G7 (eksik) | g7 ekle .203 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 578 | Hornady | .284 139 gr CX | bc_g7 |  | .216 G7 (eksik) | g7 ekle .216 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 579 | Hornady | .284 150 gr CX | bc_g7 |  | .229 G7 (eksik) | g7 ekle .229 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 581 | Hornady | .308 165 gr CX | bc_g7 |  | .221 G7 (eksik) | g7 ekle .221 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 582 | Hornady | .308 180 gr CX | bc_g7 |  | .236 G7 (eksik) | g7 ekle .236 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 584 | Hornady | .338 185 gr CX | bc_g7 |  | .205 G7 (eksik) | g7 ekle .205 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 585 | Hornady | .338 225 gr CX | bc_g7 |  | .247 G7 (eksik) | g7 ekle .247 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 586 | Hornady | .375 250 gr CX | bc_g7 |  | .203 G7 (eksik) | g7 ekle .203 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 587 | Hornady | .224 50 gr ECX | bc_g1 | 0.164 | .164 G1 = CX 50 gr (22402) | ECX 50 gr BC’si CX 50 gr ile aynı; ECX kaynağı okunamadı, teyit et | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 599 | Hornady | .284 160 gr CX | bc_g7 |  | .300 G7 (eksik) | g7 ekle .300 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 600 | Hornady | .308 150 gr CX | bc_g7 |  | .210 G7 (eksik) | g7 ekle .210 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 602 | Hornady | .224 62 gr ELD-VT | bc_form | g1 0.395 | .199 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 603 | Hornady | .243 80 gr ELD-VT | bc_form | g1 0.41 | .202 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 604 | Hornady | .264 100 gr ELD-VT | bc_form | g1 0.448 | .226 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 605 | Hornady | .308 174 gr ELD-VT | bc_form | g1 0.573 | .289 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 607 | Hornady | .224 69 gr HPBT AeroMatch | bc_form | g1 0.315 | .159 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 607 | Hornady | .224 69 gr HPBT AeroMatch | bc_g7 |  | .159 G7 (eksik) | g7 ekle: .159 | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 608 | Hornady | .224 77 gr HPBT AeroMatch | bc_form | g1 0.355 | .179 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 608 | Hornady | .224 77 gr HPBT AeroMatch | bc_g7 |  | .179 G7 (eksik) | g7 ekle: .179 | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 609 | Hornady | .243 105 gr AeroMatch | bc_form | g1 0.536 | .275 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 609 | Hornady | .243 105 gr AeroMatch | bc_g7 |  | .275 G7 (eksik) | g7 ekle: .275 | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 610 | Hornady | .264 140 gr AeroMatch | bc_form | g1 0.608 | .305 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 610 | Hornady | .264 140 gr AeroMatch | bc_g7 |  | .305 G7 (eksik) | g7 ekle: .305 | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 611 | Hornady | .308 168 gr HPBT AeroMatch | bc_form | g1 0.44 | .221 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 611 | Hornady | .308 168 gr HPBT AeroMatch | bc_g7 |  | .221 G7 (eksik) | g7 ekle: .221 | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 612 | Hornady | .308 175 gr HPBT AeroMatch | bc_form | g1 0.485 | .242 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 612 | Hornady | .308 175 gr HPBT AeroMatch | bc_g7 |  | .242 G7 (eksik) | g7 ekle: .242 | [link](https://static.hornady.media/site/hflipbook/inc/html/79.html) |
| 614 | Hornady | .264 90 gr CX | bc_g7 |  | .179 G7 (eksik) | g7 ekle .179 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 615 | Hornady | .224 65 gr CX | bc_g7 |  | .184 G7 (eksik) | g7 ekle .184 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 616 | Hornady | .257 112 gr CX | bc_g1 | 0.524 | TBD | üretici "TBD": g1 boş bırak (kaynağı yok) | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 616 | Hornady | .257 112 gr CX | bc_g7 | 0.264 | TBD | üretici "TBD": g7 boş bırak | [link](https://static.hornady.media/site/hflipbook/inc/html/84.html) |
| 617 | Hornady | .338 240 gr CX | bc_g7 |  | .308 G7 (eksik) | g7 ekle .308 (katalog sütunu G1/G7 oranıyla eşlendi; görselden teyit) | [link](https://static.hornady.media/site/hflipbook/inc/html/85.html) |
| 618 | Hornady | .224 69 gr ELD-VT | bc_form | g1 0.424 | .214 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 618 | Hornady | .224 69 gr ELD-VT | bc_g7 |  | .214 G7 (eksik) | g7 ekle: .214 | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 620 | Hornady | .257 95 gr ELD-VT | bc_form | g1 0.433 | .228 G7 | model g7 yap (üretici G7 yayımlıyor) | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 620 | Hornady | .257 95 gr ELD-VT | bc_g7 |  | .228 G7 (eksik) | g7 ekle: .228 | [link](https://static.hornady.media/site/hflipbook/inc/html/78.html) |
| 631 | Sierra | 30 Cal 180 gr Tipped GameKing TGK | bc_g1 | 0.543 G1 | not published on page; poster: #4680 180 TGK .515, #4681 .543 | 4682’nin BC’si 4681T (satır 638) ile aynı; ürün sayfasından teyit et | [link](https://sierrabullets.com/content/2025-sierra-bullets-catalog-poster.pdf) |
| 631 | Sierra | 30 Cal 180 gr Tipped GameKing TGK | name | 30 Cal 180 gr Tipped GameKing TGK | 30 CAL 180 GR TIPPED GAMEKING (TGK) (SKU 4682) | 4682 ile 4681T değerleri karışmış olabilir; teyit | [link](https://www.sierrabullets.com/30-cal-180-gr-tipped-gameking-tgk/) |
| 677 | Sierra | 22 Cal 77 gr HPBT MatchKing X MKX KTZX | bc_g1 | 0.372 G1 | not published (MKX 9380 not on poster) | MKX 9380 değerleri SMK 9377 (satır 716) ile aynı; kaynak yok, teyit et | [link](https://www.sierrabullets.com/22-cal-77-gr-hpbt-matchking-x-mkx-ktzx/) |
| 818 | Barnes | .264 130 gr TSX BT | name | item 31140 | part 30248 | ürün kodu 30248 (31140 değil) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/264/6.5-Creedmoor.pdf) |
| 835 | Barnes | .416 350 gr Banded Solid RN | bc_g1 | 0.217 G1 | 0.217 G1 | 416 Rem Mag PDF 0,217 / 416 Rigby PDF 0,364: üreticiye sor; şimdilik değişiklik yok | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/416/416-Rem-Mag.pdf) |
| 835 | Barnes | .416 350 gr Banded Solid RN | bc_g1 | 0.217 G1 | 0.364 G1 (416 Rigby PDF) | 416 Rem Mag PDF 0,217 / 416 Rigby PDF 0,364: üreticiye sor; şimdilik değişiklik yok | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/416/416RigbyWeb.pdf) |
| 836 | Barnes | .416 400 gr Banded Solid RN | bc_g1 | 0.261 G1 | 0.388 G1 | iki PDF 0,388 diyor; yuvarlak burun için yüksek: teyit sonrası 0,388 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/416/416-Rem-Mag.pdf) |
| 836 | Barnes | .416 400 gr Banded Solid RN | bc_g1 | 0.261 G1 | 0.388 G1 (416 Rigby PDF) | iki PDF 0,388 diyor; yuvarlak burun için yüksek: teyit sonrası 0,388 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/416/416RigbyWeb.pdf) |
| 845 | Barnes | .410 400 gr TSX FB | name | .410 400 gr TSX FB | not in 450-400 load data (Banded Solid 400 gr only) | 400 gr TSX FB üretici verisinde bulunamadı; teyit | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/410/450-400NitroExpress3Web.pdf) |
| 846 | Barnes | .358 180 gr TTSX FB | name | TTSX FB (180 gr, item 30459) | TTSX BT (part 30459) | ad "TTSX BT" (30459) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/358/35-Whelen.pdf) |
| 870 | Barnes | .224 62 gr TSX BT | bc_g1 | 0.296 G1 | 0.296 G1 (22 Creedmoor PDF) | 22 Creedmoor PDF ile aynı (0,296); eski 223 PDF 0,287: değişiklik yok | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/22-creedmoor.pdf) |
| 870 | Barnes | .224 62 gr TSX BT | bc_g1 | 0.296 G1 | 0.287 G1 (223 Rem PDF) | 22 Creedmoor PDF ile aynı (0,296); eski 223 PDF 0,287: değişiklik yok | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/223RemingtonWeb.pdf) |
| 871 | Barnes | .224 70 gr TSX BT | bc_g1 | 0.323 G1 | 0.323 G1 (22 Creedmoor PDF) | 22 Creedmoor PDF ile aynı (0,323); eski 223 PDF 0,314: değişiklik yok | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/22-creedmoor.pdf) |
| 871 | Barnes | .224 70 gr TSX BT | bc_g1 | 0.323 G1 | 0.314 G1 (223 Rem PDF) | 22 Creedmoor PDF ile aynı (0,323); eski 223 PDF 0,314: değişiklik yok | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/223RemingtonWeb.pdf) |
| 880 | Barnes | .224 70 gr TAC-TX BT | bc_form | g1 0.432 | g7 0.211 published | model g7 yap (üretici G7 yayımlıyor) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/22-creedmoor.pdf) |
| 880 | Barnes | .224 70 gr TAC-TX BT | bc_g7 | null | 0.211 G7 | g7 ekle: 0.211 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/22-creedmoor.pdf) |
| 892 | Barnes | .458 300 gr TSX FB | bc_g1 | 0.234 G1 | 0.230 G1 (45-70 TSX FB 300 gr; item may differ) | 45-70 PDF 0,230; aynı ürün mü teyit | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/458/45-70RugerNo1.pdf) |
| 893 | Barnes | .458 350 gr TSX FB | bc_g1 | 0.278 G1 | 0.271 G1 (45-70 TSX FB 350 gr; item may differ) | 45-70 PDF 0,271; aynı ürün mü teyit | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/458/45-70RugerNo1.pdf) |
| 915 | Barnes | .224 77 gr LRX BT | bc_g7 |  | 0.193 G7 (eksik) | g7 ekle: 0.193 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/22-creedmoor.pdf) |
| 916 | Barnes | .510 647 gr TSX FB | bc_g1 | 0.572 G1 | 0.563 G1 (style TSX BT, 2008 data) | 2008 PDF 0,563; güncel ürünle teyit | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/510/50BMG1.pdf) |
| 916 | Barnes | .510 647 gr TSX FB | name | .510 647 gr TSX FB | 647 gr TSX BT | üretici verisinde "TSX BT"; ürün sayfasıyla teyit | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/510/50BMG1.pdf) |
| 939 | Barnes | .348 250 gr Barnes Original FN FB | bc_g1 | 0.342 G1 | 0.327 G1 | 0,327 (348 Win PDF) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/348/348WinchesterWeb.pdf) |
| 941 | Barnes | .224 65 gr LRX BT | bc_g7 |  | 0.203 G7 (eksik) | g7 ekle: 0.203 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/22-creedmoor.pdf) |
| 942 | Barnes | .458 450 gr Banded Solid RN | bc_g1 | 0.267 | 0.362 G1 | load-data 0,362: güncel ürün sayfasıyla teyit sonrası | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/458/458WinchesterMagnum.pdf) |
| 943 | Barnes | .458 500 gr Banded Solid RN | bc_g1 | 0.301 | 0.394 G1 | load-data 0,394: teyit sonrası | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/458/458WinchesterMagnum.pdf) |
| 947 | Barnes | .224 69 gr Match Burner BT | bc_g7 |  | 0.168 G7 (eksik) | g7 ekle: 0.168 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/22-creedmoor.pdf) |
| 948 | Barnes | .224 77 gr Match Burner BT | bc_g7 |  | 0.176 G7 (eksik) | g7 ekle: 0.176 | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/224/22-creedmoor.pdf) |
| 957 | Barnes | .510 750 gr Banded Solid BT Bore Rider | name | .510 750 gr Banded Solid BT Bore Rider | 750 gr LRS | üretici verisinde "750 gr LRS"; teyit | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/510/50BMG1.pdf) |
| 963 | Barnes | .504 525 gr Banded Solid RN | bc_g1 | 0.267 | 0.226 G1 | 0,226 (teyit sonrası) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/505/505-Gibbs.pdf) |
| 967 | Barnes | .411 300 gr TSX FB | bc_g1 | 0.281 G1 | 0.280 G1 | 0,280 (yuvarlama farkı) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/411/405WinchesterWeb.pdf) |
| 973 | Barnes | .366 250 gr Banded Solid RN | bc_g1 | 0.214 | 0.222 G1 | 0,222 (teyit sonrası) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/366/9-3x62mmWeb.pdf) |
| 974 | Barnes | .366 286 gr Banded Solid RN | bc_g1 | 0.247 | 0.258 G1 | 0,258 (teyit sonrası) | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/366/9-3x62mmWeb.pdf) |
| 979 | Barnes | .243 68 gr Match Burner FB | name | .243 68 gr Match Burner FB | 68 gr Match Burner BT | üretici verisinde "Match Burner BT"; teyit | [link](https://barnesbullets.com/content/barnes-loaddata/rifle/243/243-Winchester.pdf) |
| 1031 | Speer | .308 150 gr Hot-Cor | name | .308 150 gr Hot-Cor (2011) | 2011 = .308 150 gr BC .255; 2023 = .308 150 gr BC .389 | iki farklı ürün (2011 / 2023): ada ürün kodu ekle | [link](https://www.speer.com/bullets/rifle-bullets/hot-cor-rifle-bullet/) |
| 1043 | Speer | .308 150 gr Hot-Cor | name | .308 150 gr Hot-Cor (2023) | 2011 = .308 150 gr BC .255; 2023 = .308 150 gr BC .389 | iki farklı ürün: ada ürün kodu ekle | [link](https://www.speer.com/bullets/rifle-bullets/hot-cor-rifle-bullet/) |
| 1204 | Peregrine | Backup Solid .323 200 gr | name | Backup Solid .323 200 gr | Backup .323 200 gr / 0.285 G1 identical to BushMaster .323 200 gr (line 1175); other Backup rows are heavier than BushMaster twins | üreticinin yayımladığı gibi; üretici kopya hatası olabilir, değişiklik yok | [link](https://peregrinebullets.com/bullets/backup/) |
| 1252 | Peregrine | Glider .308 166 gr | name | Glider .308 166 gr | maker table has two .308 166 gr Glider rows: 0.618/0.308 and 0.605/0.302 | üreticide iki .308 166 gr Glider satırı (0,618 / 0,605): hangisi, sahip karar versin | [link](https://peregrinebullets.com/bullets/glider/) |
| 1266 | Peregrine | Glider .375 420 gr | bc_g1 |  | 1.03 G1: eksik | g1 1,03 ekle | [link](https://peregrinebullets.com/bullets/glider/) |
| 1272 | Peregrine | Glider .416 550 gr | bc_g1 |  | 1.023 G1: eksik | g1 1,023 ekle | [link](https://peregrinebullets.com/bullets/glider/) |
| 1273 | Peregrine | Glider .416 555 gr | bc_g1 |  | 1.023 G1: eksik | g1 1,023 ekle | [link](https://peregrinebullets.com/bullets/glider/) |
| 1274 | Peregrine | Glider .509 750 gr | bc_g1 |  | 0.1043 G1 as printed (likely typo for 1.043): eksik | üretici "0.1043" basmış (yazım hatası olası): g1 boş kalsın | [link](https://peregrinebullets.com/bullets/glider/) |
| 1569 | H&N | Grizzly .35 82 gr | diameter | 9.0 mm | .35 cal. nominal (8.89 mm); no head size published | üretici yalnız ".35 cal." diyor (8,89 mm); karar sahipte | [link](https://www.hn-sport.de/en/air-gun-hunting/grizzly-35) |
| 1590 | NSA | NSA .457 265 gr HP FB Slug | name | NSA .457 265 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/265-grains-hollow-point) |
| 1591 | NSA | NSA .454 265 gr HP FB Slug | name | NSA .454 265 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/265-grains-hollow-point) |
| 1592 | NSA | NSA .452 265 gr HP FB Slug | name | NSA .452 265 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/265-grains-hollow-point) |
| 1593 | NSA | NSA .457 290 gr HP DB Slug | name | NSA .457 290 gr HP DB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/swaged-hollow-point) |
| 1594 | NSA | NSA .454 290 gr HP DB Slug | name | NSA .454 290 gr HP DB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/swaged-hollow-point) |
| 1595 | NSA | NSA .452 290 gr HP DB Slug | name | NSA .452 290 gr HP DB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/swaged-hollow-point) |
| 1673 | NSA | NSA .358 125 gr HP FB Slug | name | NSA .358 125 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/125-gr-hp-fb-35-cal) |
| 1674 | NSA | NSA .357 125 gr HP FB Slug | name | NSA .357 125 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/125-gr-hp-fb-35-cal) |
| 1675 | NSA | NSA .356 125 gr HP FB Slug | name | NSA .356 125 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/125-gr-hp-fb-35-cal) |
| 1679 | NSA | NSA .358 108 gr HP FB Slug | name | NSA .358 108 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/105-gr-hp-fb-35-cal) |
| 1680 | NSA | NSA .357 108 gr HP FB Slug | name | NSA .357 108 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/105-gr-hp-fb-35-cal) |
| 1681 | NSA | NSA .356 108 gr HP FB Slug | name | NSA .356 108 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/105-gr-hp-fb-35-cal) |
| 1682 | NSA | NSA .358 93 gr HP FB Slug | name | NSA .358 93 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/93-gr-hp-fb-35-cal) |
| 1683 | NSA | NSA .357 93 gr HP FB Slug | name | NSA .357 93 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/93-gr-hp-fb-35-cal) |
| 1684 | NSA | NSA .356 93 gr HP FB Slug | name | NSA .356 93 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/93-gr-hp-fb-35-cal) |
| 1685 | NSA | NSA .358 79 gr HP FB Slug | name | NSA .358 79 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/79-gr-hp-fb-35-cal) |
| 1686 | NSA | NSA .357 79 gr HP FB Slug | name | NSA .357 79 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/79-gr-hp-fb-35-cal) |
| 1687 | NSA | NSA .356 79 gr HP FB Slug | name | NSA .356 79 gr HP FB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/79-gr-hp-fb-35-cal) |
| 1693 | NSA | NSA .250 55.5 gr HP DB Slug | name | NSA .250 55.5 gr HP DB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/55-5-gr-hp-fb-25-cal-nsa) |
| 1695 | NSA | NSA .250 43.5 gr HP DB Slug | name | NSA .250 43.5 gr HP DB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/43-5-gr-hp-fb-25-cal) |
| 1696 | NSA | NSA .254 43.5 gr HP DB Slug | name | NSA .254 43.5 gr HP DB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/43-5-gr-hp-fb-25-cal) |
| 1702 | Zan Projectiles | ZAN .22 Hyper Line 20 gr Slug .217 | bc_g1 | 0.07 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1703 | Zan Projectiles | ZAN Lead Free .30 37 gr Pellet | name | ZAN Lead Free .30 37 gr Pellet | Lead Free .30 Pellets — no restock | üretici kurşunsuz saçmayı yeniden stoklamayacak: gizleme kararı sahipte | [link](https://zanprojectiles.com/shop/lead-free-30-pellets/) |
| 1704 | Zan Projectiles | ZAN .177 10 gr HP Slug | bc_g1 | 0.048 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/17-4-5mm-slugs/) |
| 1705 | Zan Projectiles | ZAN .177 13 gr HP Slug | bc_g1 | 0.068 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/17-4-5mm-slugs/) |
| 1706 | Zan Projectiles | ZAN .177 16 gr HP Slug | bc_g1 | 0.072 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/17-4-5mm-slugs/) |
| 1707 | Zan Projectiles | ZAN .177 20 gr HP Slug | bc_g1 | 0.095 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/17-4-5mm-slugs/) |
| 1708 | Zan Projectiles | ZAN .22 20 gr Slug .217 | bc_g1 | 0.07 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1709 | Zan Projectiles | ZAN .22 20 gr Slug .218 | bc_g1 | 0.07 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1710 | Zan Projectiles | ZAN .22 22 gr Slug .219 | bc_g1 | 0.075 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1711 | Zan Projectiles | ZAN .22 23 gr Slug .217 | bc_g1 | 0.075 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1712 | Zan Projectiles | ZAN .22 23 gr Slug .218 | bc_g1 | 0.075 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1713 | Zan Projectiles | ZAN .22 25.5 gr Slug .217 | bc_g1 | 0.082 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1714 | Zan Projectiles | ZAN .22 25.5 gr Slug .218 | bc_g1 | 0.082 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1715 | Zan Projectiles | ZAN .22 28 gr Slug .217 | bc_g1 | 0.09 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1716 | Zan Projectiles | ZAN .22 28 gr Slug .218 | bc_g1 | 0.09 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1717 | Zan Projectiles | ZAN .22 28 gr Slug .219 | bc_g1 | 0.09 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1718 | Zan Projectiles | ZAN .22 36 gr Slug .217 | bc_g1 | 0.115 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1719 | Zan Projectiles | ZAN .22 36 gr Slug .218 | bc_g1 | 0.115 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-slugs/) |
| 1720 | Zan Projectiles | ZAN .25 26.5 gr MKII Slug .250 | bc_g1 | 0.088 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1721 | Zan Projectiles | ZAN .25 28 gr Slug .250 | bc_g1 | 0.091 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1722 | Zan Projectiles | ZAN .25 30 gr Slug .250 | bc_g1 | 0.094 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1723 | Zan Projectiles | ZAN .25 33 gr Slug .250 | bc_g1 | 0.098 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1724 | Zan Projectiles | ZAN .25 33 gr Slug .253 | bc_g1 | 0.097 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1725 | Zan Projectiles | ZAN .25 35 gr Slug .250 | bc_g1 | 0.103 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1726 | Zan Projectiles | ZAN .25 37 gr Slug .250 | bc_g1 | 0.108 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1727 | Zan Projectiles | ZAN .25 38 gr Slug .253 | bc_g1 | 0.104 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1728 | Zan Projectiles | ZAN .25 41 gr Slug .250 | bc_g1 | 0.119 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1729 | Zan Projectiles | ZAN .25 45 gr Slug .250 | bc_g1 | 0.138 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-slugs/) |
| 1730 | Zan Projectiles | ZAN .30 45.5 gr Slug .300 | bc_g1 | 0.107 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/30-slugs/) |
| 1731 | Zan Projectiles | ZAN .30 49 gr Slug .300 | bc_g1 | 0.117 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/30-slugs/) |
| 1732 | Zan Projectiles | ZAN .30 54 gr Slug .300 | bc_g1 | 0.123 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/30-slugs/) |
| 1733 | Zan Projectiles | ZAN .30 59 gr Slug .300 | bc_g1 | 0.125 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/30-slugs/) |
| 1734 | Zan Projectiles | ZAN .30 63 gr Slug .300 | bc_g1 | 0.13 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/30-slugs/) |
| 1735 | Zan Projectiles | ZAN .30 68 gr Slug .300 | bc_g1 | 0.134 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/30-slugs/) |
| 1736 | Zan Projectiles | ZAN .457 380 gr Slug | bc_g1 | 0.385 | TBA (yayınlanmamış) | üretici "BC = TBA": g1 boş | [link](https://zanprojectiles.com/shop/457-126mm-slug/) |
| 1737 | Zan Projectiles | ZAN .457 388 gr Slug | bc_g1 | 0.458 | TBA (yayınlanmamış) | üretici "BC = TBA": g1 boş | [link](https://zanprojectiles.com/shop/457-126mm-slug/) |
| 1738 | Zan Projectiles | ZAN .22 ELR 35.5 gr Slug | bc_g1 | 0.21 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-elr-slugs/) |
| 1739 | Zan Projectiles | ZAN .22 ELR Hyper Line 34.6 gr Slug .217 | bc_g1 | 0.258 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/217-caliber-407-grain-elr-hyper-line-slugs/) |
| 1740 | Zan Projectiles | ZAN .22 ELR Hyper Line 34.6 gr Slug .218 | bc_g1 | 0.258 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/217-caliber-407-grain-elr-hyper-line-slugs/) |
| 1741 | Zan Projectiles | ZAN .22 ELR Hyper Line 40.7 gr Slug .217 | bc_g1 | 0.273 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/217-caliber-407-grain-elr-hyper-line-slugs/) |
| 1742 | Zan Projectiles | ZAN .22 ELR Hyper Line 40.7 gr Slug .218 | bc_g1 | 0.273 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/217-caliber-407-grain-elr-hyper-line-slugs/) |
| 1743 | Zan Projectiles | ZAN .25 ELR 46.9 gr Slug | bc_g1 | 0.229 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-elr-slugs/) |
| 1744 | Zan Projectiles | ZAN .25 ELR 61.3 gr Slug | bc_g1 | 0.271 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/25-elr-slugs/) |
| 1745 | Zan Projectiles | ZAN .22 Hyper Line 20 gr Slug .218 | bc_g1 | 0.07 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1746 | Zan Projectiles | ZAN .22 Hyper Line 23 gr Slug .217 | bc_g1 | 0.075 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1747 | Zan Projectiles | ZAN .22 Hyper Line 23 gr Slug .218 | bc_g1 | 0.075 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1748 | Zan Projectiles | ZAN .22 Hyper Line 30.5 gr Slug .217 | bc_g1 | 0.133 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1749 | Zan Projectiles | ZAN .22 Hyper Line 30.5 gr Slug .218 | bc_g1 | 0.133 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1750 | Zan Projectiles | ZAN .22 Hyper Line 33 gr Slug .217 | bc_g1 | 0.136 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1751 | Zan Projectiles | ZAN .22 Hyper Line 33 gr Slug .218 | bc_g1 | 0.136 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1752 | Zan Projectiles | ZAN .22 Hyper Line 36 gr Slug .217 | bc_g1 | 0.135 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1753 | Zan Projectiles | ZAN .22 Hyper Line 36 gr Slug .218 | bc_g1 | 0.135 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1754 | Zan Projectiles | ZAN .22 Hyper Line 40 gr Slug .217 | bc_g1 | 0.138 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1755 | Zan Projectiles | ZAN .22 Hyper Line 40 gr Slug .218 | bc_g1 | 0.138 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/22-hyper-line-slugs/) |
| 1756 | Zan Projectiles | ZAN .177 Hyper Line 10 gr Slug | bc_g1 | 0.065 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/177-4-5mm-hyper-line-slugs/) |
| 1757 | Zan Projectiles | ZAN .177 Hyper Line 13 gr Slug | bc_g1 | 0.08 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/177-4-5mm-hyper-line-slugs/) |
| 1758 | Zan Projectiles | ZAN .177 Hyper Line 16 gr Slug | bc_g1 | 0.087 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/177-4-5mm-hyper-line-slugs/) |
| 1759 | Zan Projectiles | ZAN .177 Hyper Line 20 gr Slug | bc_g1 | 0.095 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/177-4-5mm-hyper-line-slugs/) |
| 1760 | Zan Projectiles | ZAN .30 Hyper Line 58 gr Slug | bc_g1 | 0.129 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/30-hyper-line-slugs/) |
| 1761 | Zan Projectiles | ZAN .30 Hyper Line 68 gr Slug | bc_g1 | 0.134 | yayınlanmamış | Zan BC yayımlamıyor: g1/bc boş bırak | [link](https://zanprojectiles.com/shop/30-hyper-line-slugs/) |
| 1765 | Cutting Edge Bullets | MTH (Match/Tactical/Hunting) .224 78 gr MAX | bc_form | g1 | maker publishes G7 0.218 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1765 | Cutting Edge Bullets | MTH (Match/Tactical/Hunting) .224 78 gr MAX | bc_g7 | null | eksik: 0.218 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1773 | Cutting Edge Bullets | MTH (Match/Tactical/Hunting) .277 120 gr | bc_form | g1 | maker publishes G7 0.21 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1773 | Cutting Edge Bullets | MTH (Match/Tactical/Hunting) .277 120 gr | bc_g7 | null | eksik: 0.21 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1774 | Cutting Edge Bullets | MTH (Match/Tactical/Hunting) .277 130 gr | bc_form | g1 | maker publishes G7 0.228 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1774 | Cutting Edge Bullets | MTH (Match/Tactical/Hunting) .277 130 gr | bc_g7 | null | eksik: 0.228 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1779 | Cutting Edge Bullets | MTH (Match/Tactical/Hunting) .284 180 gr MAX | bc_form | g1 | maker publishes G7 0.326 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1779 | Cutting Edge Bullets | MTH (Match/Tactical/Hunting) .284 180 gr MAX | bc_g7 | null | eksik: 0.326 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1796 | Cutting Edge Bullets | MTAC (Match/Tactical) .224 79 gr MAX | bc_form | g1 | maker publishes G7 0.226 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1796 | Cutting Edge Bullets | MTAC (Match/Tactical) .224 79 gr MAX | bc_g7 | null | eksik: 0.226 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1816 | Cutting Edge Bullets | Lazer Tipped Hollow Point .264 125 gr | bc_form | g1 | maker publishes G7 0.269 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1816 | Cutting Edge Bullets | Lazer Tipped Hollow Point .264 125 gr | bc_g7 | null | eksik: 0.269 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1817 | Cutting Edge Bullets | Lazer Tipped Hollow Point .277 115 gr | bc_form | g1 | maker publishes G7 0.218 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1817 | Cutting Edge Bullets | Lazer Tipped Hollow Point .277 115 gr | bc_g7 | null | eksik: 0.218 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1818 | Cutting Edge Bullets | Lazer Tipped Hollow Point .277 150 gr MAX | bc_form | g1 | maker publishes G7 0.288 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1818 | Cutting Edge Bullets | Lazer Tipped Hollow Point .277 150 gr MAX | bc_g7 | null | eksik: 0.288 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1819 | Cutting Edge Bullets | Lazer Tipped Hollow Point .284 145 gr MAX | bc_form | g1 | maker publishes G7 0.272 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1819 | Cutting Edge Bullets | Lazer Tipped Hollow Point .284 145 gr MAX | bc_g7 | null | eksik: 0.272 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1821 | Cutting Edge Bullets | Lazer Tipped Hollow Point .284 185 gr MAX | bc_form | g1 | maker publishes G7 0.333 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1821 | Cutting Edge Bullets | Lazer Tipped Hollow Point .284 185 gr MAX | bc_g7 | null | eksik: 0.333 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1822 | Cutting Edge Bullets | Lazer Tipped Hollow Point .308 165 gr GEN2 | bc_form | g1 | maker publishes G7 0.236 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1822 | Cutting Edge Bullets | Lazer Tipped Hollow Point .308 165 gr GEN2 | bc_g7 | null | eksik: 0.236 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1823 | Cutting Edge Bullets | Lazer Tipped Hollow Point .308 180 gr MAX GEN2 | bc_form | g1 | maker publishes G7 0.265 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1823 | Cutting Edge Bullets | Lazer Tipped Hollow Point .308 180 gr MAX GEN2 | bc_g7 | null | eksik: 0.265 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1825 | Cutting Edge Bullets | Lazer Tipped Hollow Point .308 220 gr MAX GEN2 | bc_form | g1 | maker publishes G7 0.323 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1825 | Cutting Edge Bullets | Lazer Tipped Hollow Point .308 220 gr MAX GEN2 | bc_g7 | null | eksik: 0.323 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1826 | Cutting Edge Bullets | Lazer Tipped Hollow Point .308 230 gr MAX GEN2 | bc_form | g1 | maker publishes G7 0.339 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1826 | Cutting Edge Bullets | Lazer Tipped Hollow Point .308 230 gr MAX GEN2 | bc_g7 | null | eksik: 0.339 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1829 | Cutting Edge Bullets | Lazer Tipped Hollow Point .338 275 gr MAX GEN2 | bc_form | g1 | maker publishes G7 0.394 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1829 | Cutting Edge Bullets | Lazer Tipped Hollow Point .338 275 gr MAX GEN2 | bc_g7 | null | eksik: 0.394 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1831 | Cutting Edge Bullets | Lazer Tipped Hollow Point .458 700 gr MAX | bc_form | g1 | maker publishes G7 0.574 | model g7 yap (üretici G7 yayımlıyor) | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1831 | Cutting Edge Bullets | Lazer Tipped Hollow Point .458 700 gr MAX | bc_g7 | null | eksik: 0.574 G7 | g7 ekle: eksik: | [link](https://cdn.shopify.com/s/files/1/0838/7185/8986/files/TechDataSheets2026.pdf?v=1791473847) |
| 1833 | Hammer Bullets | .308 Cal-181 gr Hammer Hunter® | name | .308 Cal-181 gr Hammer Hunter® | .308 Cal-181gr Hammer Hunter® (stated weight 180 gr) | üretici adı 181, sayfa 180 gr diyor: grain 180 kalsın | [link](https://hammerbullets.com/product/308-cal-181gr-hammer-hunter/) |
| 1834 | Hammer Bullets | .264 Cal-131 gr Hammer Hunter® | name | .264 Cal-131 gr Hammer Hunter® | .264 Cal-131gr Hammer Hunter® (stated weight 132 gr) | üretici 131/132 çelişkili: grain 132 kalsın | [link](https://hammerbullets.com/product/264-cal-131gr-hammer-hunter/) |
| 1841 | Hammer Bullets | .264 Cal-110 gr Hammer Hunter® | name | .264 Cal-110 gr Hammer Hunter® | .264 Cal-110gr Hammer Hunter® (stated weight 107 gr) | üretici 110/107 çelişkili: grain 107 kalsın | [link](https://hammerbullets.com/product/264-cal-110gr-hammer-hunter/) |
| 1843 | Hammer Bullets | .264 Cal-137 gr Hammer Hunter® | name | .264 Cal-137 gr Hammer Hunter® | .264 Cal-137gr Hammer Hunter® (stated weight 139 gr) | üretici 137/139 çelişkili: grain 139 kalsın | [link](https://hammerbullets.com/product/264-cal-137gr-hammer-hunter-50/) |
| 1894 | Crosman | Domed Ultra Heavy .22 22 gr | weight | 22 gr | 19 gr | 2025 katalog 19 gr; 2026 katalog okunamadı: teyit sonrası 19 gr | [link](https://www.crosman.com/wp-content/uploads/2025/02/BCTC25_Crosman-compressed.pdf) |
| 1929 | NSA | NSA .457 265 gr HP DB Slug | name | NSA .457 265 gr HP DB Slug | .45 Cal 265 grain Truncated Cone HP DB (.457) | ad "NSA .457 265 gr HP TC DB Slug" (Truncated Cone) | [link](https://nielsenspecialtyammo.com/products/45-cal-265-grain-truncated-cone-50ct-0-44-rd) |
| 1930 | NSA | NSA .257 75 gr HP DB Slug | name | NSA .257 75 gr HP DB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/75-grain-257-flat-base-hollow-point) |
| 1931 | NSA | NSA .257 65 gr HP DB Slug | name | NSA .257 65 gr HP DB Slug | base type ambiguous on maker page | değişiklik yok; üretici sayfası FB/DB çelişkili | [link](https://nielsenspecialtyammo.com/products/65-grain-257-flat-base-hollow-point) |
| 1998 | Zan Projectiles | ZAN .357 Hyper Line 100 gr Slug | diameter | 9 mm | yok (nominal .357 = 9.068 mm; Zan .357 HP: 9,07 mm) | çap 9,068 mm (.357) | [link](https://zanprojectiles.com/shop/357-hyper-line-slugs/) |
| 1999 | Zan Projectiles | ZAN .357 Hyper Line 125 gr Slug | diameter | 9 mm | yok (nominal .357 = 9.068 mm; Zan .357 HP: 9,07 mm) | çap 9,068 mm (.357) | [link](https://zanprojectiles.com/shop/357-hyper-line-slugs/) |

## Erişilemeyen kayıtlar

Tam liste `data/veri_denetimi/mermi.csv` içinde, `status = ERİŞİLEMEDİ` olan satırlarda (641 satır).
