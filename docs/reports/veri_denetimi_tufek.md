# Tüfek kütüphanesi veri denetimi (lib/data/rifle_library.dart)

Tarih: 14.10.2026 (İstanbul). Dal: `audit/veri-tufek`. Yalnız denetim: `lib/` değişmedi. Denetim turu: 1.

## Kısa özet

- Kütüphanede **4924 satır** var (4018 ateşli, 906 PCP), 86 marka, 908 kaynak adresi.
- Üretici kaynağı okunabilen satır: **2070 / 4924** (%42). Geri kalanı **ERİŞİLEMEDİ**: bu çalışmada web arama kotası (tur başına 200 arama, tüm alt ajanlar ortak) bitti ve üretici siteleri HTTP 429 (hız sınırı) döndü; değer tahmin edilmedi, başka yoldan (arşiv, bayi, curl) alınmadı.
- Toplam **24861** alan denetimi kaydedildi: OK 9696, HATALI 5, ŞÜPHELİ 214, ERİŞİLEMEDİ 14946.
- Okunabilen denetimlerde doğru oranı: **%97.8** (OK / (OK+HATALI+ŞÜPHELİ)).
- İç tutarlılık (internet gerektirmeyen) denetimi tüm 4924 satırda yapıldı: tüm kalibre adları `cartridges.dart` listesinde var, çaplar birebir uyuşuyor, birebir kopya satır yok, birim hatası (mm↔inç) görünmüyor.

### Alan bazında sonuç (okunabilen kaynaklar)

| Alan | OK | HATALI | ŞÜPHELİ | ERİŞİLEMEDİ |
|---|---|---|---|---|
| Model adı | 2054 | 0 | 16 | 2854 |
| Kalibre | 2014 | 5 | 47 | 2858 |
| Yiv adımı | 1990 | 0 | 57 | 2877 |
| Yiv yönü | 43 | 0 | 25 | 173 |
| Namlu boyu | 1997 | 0 | 69 | 2858 |
| Yerli/İthal | 1598 | 0 | 0 | 3326 |

### En önemli bulgular ve hesaba etkisi

- **Yanlış kalibre (HATALI):** Üreticinin o modelde hiç sunmadığı kalibreler listede. Kullanıcı bu satırı seçerse var olmayan bir tüfek/kalibre eşleşmesi kurulur; çap, yiv ve namlu varsayılanları yanlış modele dayanır. (Sabatti Rover Alaskan .338 Win Mag, Rover Shooter 6.5 PRC, Rover Varmint Syn 6.5 PRC, Saphire E.R. 8x57 JS, Hatsan Blitz 4.50 mm.)
- **Eksik yiv adımı (ŞÜPHELİ):** MKE KN-12 (1:12 / 1:10), Savage 110 Elite Precision (4 kalibre), Kral Ridgepoint 6.5 CM (1:10), Umarex Gauntlet Limited (1:26). Yiv boş kalınca uygulama standart yive düşer; gerçek yiv farklıysa jiroskopik kararlılık (Sg) ve spin sapması (spin drift) yanlış hesaplanır, uzak mesafede yatay sapma hatası doğar.
- **Kaynaksız yiv adımı (ŞÜPHELİ):** Sabatti Saphire E.R. (8 satır), Steyr SSG 08 .243 / SSG 08 A1, Barrett MRAD Covert / REC10, MKE KNT-76, Mossberg 7mm-08 (1:9.5, eski bülten 1:10) ve Patriot Predator .400 Legend / .450 BM (üreticinin kendi sayfaları çelişkili). Yanlışsa etkisi yine Sg ve spin sapmasıdır.
- **Varyant/ad karışıklığı (ŞÜPHELİ):** Winchester "Model 70 Extreme Weather" satırları Extreme Tungsten MB sayfasından; Sauer "101 Classic" 6.5 CM / 8.5x55 satırları Elegance sayfasından; Derya "TM22 Metal" adı katalogda yok; Christensen CA-15 G2 / CA5five6 ve Seekins HIT PRO M3 üreticide ".223 Wylde", kütüphanede "5.56x45 NATO".
- **Yerli/İthal:** AirMaks Arms (160 PCP satırı) Yerli listesinde yok; Türk markası olduğu düşünülüyor ama üretici sayfası okunamadığı için doğrulanamadı (ŞÜPHELİ).
- Ruger Gen II / Mini Thirty ve Steyr SSG satırlarında yön "sağ" yazılı ama okunan üretici sayfası yön vermiyor (ŞÜPHELİ; Ruger özellik sayfalarında "RH" var, okunabilenler doğrulandı).

## Tüm HATALI ve ŞÜPHELİ kayıtlar (önerilen düzeltme ve kaynakla)

Satır numaraları `lib/data/rifle_library.dart` içindedir. Aynı not taşıyan ardışık satırlar birleştirildi. Düzeltmeler sahibin onayı sonrası ayrı görevde yapılacak.

| Satır | Marka / Model | Alan | Kütüphane | Üretici | Durum | Öneri / not | Kaynak |
|---|---|---|---|---|---|---|---|
| 4667 | Hatsan / Blitz | Kalibre | 4.50 mm (.177) | .22 / .25 / .30 (4.5 mm yok) | HATALI | Satırı gizle (silme): üretici bu kalibreyi sunmuyor. Üretici Blitz için 4.5 mm (.177) kalibre vermiyor; satır kaldırılmalı/gizlenmeli. | https://hatsan.com.tr/urun/blitz-bp/ |
| 2431 | Sabatti / Rover Alaskan | Kalibre | .338 Win Mag | listede yok | HATALI | Satırı gizle (silme): üretici bu kalibreyi sunmuyor. .338 Win Mag Rover Alaskan kalibre listesinde yok | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2468 | Sabatti / Rover Shooter | Kalibre | 6.5 PRC | listede yok | HATALI | Satırı gizle (silme): üretici bu kalibreyi sunmuyor. 6.5 PRC Rover Shooter için 2024 katalogda yok | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2475 | Sabatti / Rover Varmint Syn | Kalibre | 6.5 PRC | listede yok | HATALI | Satırı gizle (silme): üretici bu kalibreyi sunmuyor. 6.5 PRC Rover Varmint Syn listesinde yok (Rover Varmint'te var) | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2498 | Sabatti / Saphire E.R. | Kalibre | 8x57 JS | listede yok | HATALI | Satırı gizle (silme): üretici bu kalibreyi sunmuyor. 8x57 JS Saphire E.R. kalibre listesinde yok | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 4091 | AirMaks Arms / Caiman | tutarlılık:origin | İthal |  | ŞÜPHELİ | AirMaks Arms: alan adı/üretici Türk markası görünüyor ama Yerli listesinde (_domesticBrands) yok; üretim yeri doğrulanmalı (tüm 160 satır) | iç denetim |
| 96–97 (2) | Anschütz / 1782 Classic | tutarlılık:twistRateIn | 8.66 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:8.66); üretici değeri değil olabilir | iç denetim |
| 98–100 (3) | Anschütz / 1782 Classic | tutarlılık:twistRateIn | 9.45 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:9.45); üretici değeri değil olabilir | iç denetim |
| 101–102 (2) | Anschütz / 1782 Classic | tutarlılık:twistRateIn | 14.17 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:14.17); üretici değeri değil olabilir | iç denetim |
| 114–115 (2) | Anschütz / 1782 Slim Line | tutarlılık:twistRateIn | 8.66 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:8.66); üretici değeri değil olabilir | iç denetim |
| 116–118 (3) | Anschütz / 1782 Slim Line | tutarlılık:twistRateIn | 9.45 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:9.45); üretici değeri değil olabilir | iç denetim |
| 119–120 (2) | Anschütz / 1782 Slim Line | tutarlılık:twistRateIn | 14.17 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:14.17); üretici değeri değil olabilir | iç denetim |
| 4331 | BSA / R12 CLX | Model adı | R12 CLX | BSA R12 SE / R12 CLX | ŞÜPHELİ | Üretici sayfasında başlık R12 CLX, ana başlık R12 SE; değerler uyuşuyor | https://bsaguns.co.uk/air-rifles/pcp-airguns/r12-clx/ |
| 400 | Barrett / MRAD Covert | Yiv adımı | 8.0 |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. üretici sayfası yiv adımı vermiyor; kütüphane değeri kaynaksız | https://barrett.net/wp-content/uploads/2026/01/BARRETT-2026-Product-Catalog-Digital-LR.pdf |
| 417 | Barrett / REC10 | Yiv adımı | 10.0 |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. üretici sayfası yiv adımı vermiyor; kütüphane değeri kaynaksız | https://barrett.net/wp-content/uploads/2026/01/BARRETT-2026-Product-Catalog-Digital-LR.pdf |
| 420 | Barrett / REC7 DI | Namlu boyu | 260.0 | 406 | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. 2026 kataloğunda REC7 DI yalnız 16"; 260 mm (10,25") varyantı doğrulanamadı. | https://barrett.net/wp-content/uploads/2026/01/BARRETT-2026-Product-Catalog-Digital-LR.pdf |
| 422 | Barrett / REC7 DI | Namlu boyu | 457.0 | 406 | ŞÜPHELİ | 2026 kataloğunda 457 mm (18") yok; 1:7.7 yiv de üreticide görünmüyor. | https://barrett.net/wp-content/uploads/2026/01/BARRETT-2026-Product-Catalog-Digital-LR.pdf |
| 422 | Barrett / REC7 DI | Yiv adımı | 7.7 | 7.0 | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. Katalog yalnız 1:7 veriyor; 7.7 doğrulanamadı. | https://barrett.net/wp-content/uploads/2026/01/BARRETT-2026-Product-Catalog-Digital-LR.pdf |
| 497 | Bergara / B-14 Hunter | tutarlılık:twistRateIn | 10.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [10.0, 12.0] | iç denetim |
| 498 | Bergara / B-14 Hunter | tutarlılık:twistRateIn | 12.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [10.0, 12.0] | iç denetim |
| 546 | Bergara / B-14 Sporter | tutarlılık:twistRateIn | 8.66 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:8.66); üretici değeri değil olabilir | iç denetim |
| 623 | Bergara / B-14 Timber | tutarlılık:twistRateIn | 8.66 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:8.66); üretici değeri değil olabilir | iç denetim |
| 746 | Blaser / K95 | tutarlılık:twistRateIn | 17.72 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:17.72); üretici değeri değil olabilir | iç denetim |
| 748 | Blaser / K95 | tutarlılık:twistRateIn | 10.63 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:10.63); üretici değeri değil olabilir | iç denetim |
| 751–758 (3) | Blaser / K95 | tutarlılık:twistRateIn | 8.66 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:8.66); üretici değeri değil olabilir | iç denetim |
| 752–753 (2) | Blaser / K95 | tutarlılık:twistRateIn | 7.87 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:7.87); üretici değeri değil olabilir | iç denetim |
| 760 | Blaser / K95 | tutarlılık:twistRateIn | 9.45 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:9.45); üretici değeri değil olabilir | iç denetim |
| 762 | Blaser / K95 | tutarlılık:twistRateIn | 14.17 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:14.17); üretici değeri değil olabilir | iç denetim |
| 808 | Blaser / R8 | tutarlılık:twistRateIn | 17.72 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:17.72); üretici değeri değil olabilir | iç denetim |
| 813–824 (4) | Blaser / R8 | tutarlılık:twistRateIn | 8.66 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:8.66); üretici değeri değil olabilir | iç denetim |
| 815–816 (2) | Blaser / R8 | tutarlılık:twistRateIn | 10.63 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:10.63); üretici değeri değil olabilir | iç denetim |
| 828–830 (3) | Blaser / R8 | tutarlılık:twistRateIn | 9.45 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:9.45); üretici değeri değil olabilir | iç denetim |
| 833–834 (2) | Blaser / R8 | tutarlılık:twistRateIn | 14.17 |  | ŞÜPHELİ | C.I.P./SAAMI standart değeriyle birebir aynı (1:14.17); üretici değeri değil olabilir | iç denetim |
| 968 | Cadex / CDX-50 Tremor 1016 mm | tutarlılık:barrelLengthMm | 1016.0 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 969 | Cadex / CDX-50SS Tremor | tutarlılık:barrelLengthMm | 1016.0 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 991 | Cadex / CDX-R7 CRBN | tutarlılık:twistRateIn | 9.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 9.0] | iç denetim |
| 992 | Cadex / CDX-R7 CRBN | tutarlılık:twistRateIn | 8.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 9.0] | iç denetim |
| 1099 | Christensen Arms / CA-15 G2 | Kalibre | 5.56x45 NATO | .223 Wylde | ŞÜPHELİ | Üretici hazneyi .223 Wylde olarak veriyor; kütüphanede 5.56x45 NATO yazılı. Wylde hem .223 Rem hem 5.56 atar. | https://christensenarms.com/product/ca-15-g2/ |
| 1101 | Christensen Arms / CA5five6 FFT | Kalibre | 5.56x45 NATO | .223 Wylde | ŞÜPHELİ | Üretici hazneyi .223 Wylde olarak veriyor; kütüphanede 5.56x45 NATO yazılı. Wylde hem .223 Rem hem 5.56 atar. | https://christensenarms.com/product/ca5five6-fft/ |
| 1323 | Derya / TM22 Metal 12 | Model adı | TM22 Metal 12 | TM22-A-12/16/18 C101 ("Metal" adı yok) | ŞÜPHELİ | Model adı katalogda bulunamadı; değerler (1:16" RH, uzunluk) uyumlu. | https://deryaarms.com/catalogs/rifle-catalog/Derya_Arms_Rifle_2026.pdf |
| 1324 | Derya / TM22 Metal 16 | Model adı | TM22 Metal 16 | TM22-A-12/16/18 C101 ("Metal" adı yok) | ŞÜPHELİ | Model adı katalogda bulunamadı; değerler (1:16" RH, uzunluk) uyumlu. | https://deryaarms.com/catalogs/rifle-catalog/Derya_Arms_Rifle_2026.pdf |
| 1325 | Derya / TM22 Metal 18 | Model adı | TM22 Metal 18 | TM22-A-12/16/18 C101 ("Metal" adı yok) | ŞÜPHELİ | Model adı katalogda bulunamadı; değerler (1:16" RH, uzunluk) uyumlu. | https://deryaarms.com/catalogs/rifle-catalog/Derya_Arms_Rifle_2026.pdf |
| 4579–4585 (4) | Evanix / Sniper | Namlu boyu |  | 500~550mm | ŞÜPHELİ | Kütüphanede namlu boş; üretici aralık veriyor (varyanta göre), tek değer seçilemez. | http://www.evanix.com/bbs/board.php?bo_table=SL&wr_id=1 |
| 4581–4583 (3) | Evanix / Sniper | Namlu boyu |  | 400~480mm | ŞÜPHELİ | Kütüphanede namlu boş; üretici aralık veriyor (varyanta göre), tek değer seçilemez. | http://www.evanix.com/bbs/board.php?bo_table=SL&wr_id=1 |
| 4667 | Hatsan / Blitz | Namlu boyu | 585.0 |  | ŞÜPHELİ | üretici sayfası bu kalibre için namlu boyu vermiyor | https://hatsan.com.tr/urun/blitz-bp/ |
| 4685–4686 (2) | Hatsan / Factor BP | Namlu boyu | 584.0 | 23" tablo / 32" açıklama | ŞÜPHELİ | Üretici sayfası kendi içinde çelişkili (tablo 23", metin 32"); 584 mm tabloyla uyumlu. | https://hatsanairgunsusa.com/product/factor-bp/ |
| 1471 | Henry / H6 Big Boy Carbine | Yiv adımı | 18.0 | 18 (ürün sayfası) / 16 (media-kit) | ŞÜPHELİ | Ürün sayfası 1:18 diyor (kütüphane ile aynı); Henry media-kit teknik sayfası aynı SKU için 1:16 yazıyor. Üretici kaynakları çelişiyor. | https://www.henryusa.com/firearm/h6-big-boy-rifle-carbine/ |
| 1639 | Kale Kalıp / KCR556 PDW | tutarlılık:barrelLengthMm | 190.0 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 1646 | Kale Kalıp / KNG-C5 PDW | tutarlılık:barrelLengthMm | 190.0 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 4761–4763 (3) | Kral Arms / Empire XS | Namlu boyu |  | 33 cm (sayfada 22.8 in ile çelişkili) | ŞÜPHELİ | Kütüphanede namlu boş; üretici 33 cm yazıyor ama inç değeri çelişkili | https://www.kralarms.com/empire-xs/ |
| 1737 | Kral Arms / Ridgepoint Synthetic | Yiv adımı |  | 1:10 inch (model geneli) | ŞÜPHELİ | Üretici modele tek yiv oranı veriyor (kalibre ayrımı yok); 6.5 CM satırında null | https://www.kralarms.com/3590-2/ |
| 1740 | Kral Arms / Ridgepoint Walnut | Yiv adımı |  | 1:10 inch (model geneli) | ŞÜPHELİ | Üretici modele tek yiv oranı veriyor (kalibre ayrımı yok); 6.5 CM satırında null | https://www.kralarms.com/kr308/ |
| 2003 | MKE / KN-12 (7.62×51) | Yiv adımı |  | 12 | ŞÜPHELİ | Üretici değerini ekle: 12. kütüphanede eksik (boş); Kütüphanede yiv adımı boş; katalog 1:12 veriyor | https://www.mke.gov.tr/Content/D_Dosya/ckResim/Programlar/01-MKE-KATALOG-SMALL%20ARMS.pdf |
| 2004 | MKE / KN-12 (8.59×70) | Yiv adımı |  | 10 | ŞÜPHELİ | Üretici değerini ekle: 10. kütüphanede eksik (boş); Kütüphanede yiv adımı boş; katalog 1:10 veriyor | https://www.mke.gov.tr/Content/D_Dosya/ckResim/Programlar/01-MKE-KATALOG-SMALL%20ARMS.pdf |
| 2005 | MKE / KNT-76 | Yiv adımı | 12.0 |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. Katalog metninde KNT-76 yiv adımı yok; kütüphanedeki 12 doğrulanamadı | https://www.mke.gov.tr/Content/D_Dosya/ckResim/Programlar/01-MKE-KATALOG-SMALL%20ARMS.pdf |
| 2001 | MKE / Kaan 717 | Namlu boyu | 315.0 | 315 mm veya 406 mm | ŞÜPHELİ | KAAN 717 yakınında iki 7.62 bloğu var; 315 mm muhtemel ama PDF metni belirsiz | https://www.mke.gov.tr/Content/D_Dosya/ckResim/Programlar/01-MKE-KATALOG-SMALL%20ARMS.pdf |
| 2010 | MKE / MKE-739K A1 | Namlu boyu | 279.4 | 279.4 / 368.3 mm | ŞÜPHELİ | 739K ve 739M uzunlukları katalogda var ama hangisinin hangi modele ait olduğu metinden net değil | https://www.mke.gov.tr/Content/D_Dosya/ckResim/Programlar/01-MKE-KATALOG-SMALL%20ARMS.pdf |
| 2011 | MKE / MKE-739M A1 | Namlu boyu | 368.3 | 279.4 / 368.3 mm | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. 739K/739M ataması metinden doğrulanamadı | https://www.mke.gov.tr/Content/D_Dosya/ckResim/Programlar/01-MKE-KATALOG-SMALL%20ARMS.pdf |
| 2017 | MKE / MT12-QCB | Namlu boyu | 1143.0 | 1143 mm veya 1656 mm | ŞÜPHELİ | Katalogda iki değer var; 1656 mm toplam silah boyu olabilir, 1143 muhtemelen namlu | https://www.mke.gov.tr/Content/D_Dosya/ckResim/Programlar/01-MKE-KATALOG-SMALL%20ARMS.pdf |
| 2017 | MKE / MT12-QCB | tutarlılık:barrelLengthMm | 1143.0 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 2028 | Mossberg / Patriot Carbine | Namlu boyu | 419.0 | 16.25" (413 mm) | ŞÜPHELİ | Bülten tablosu 28229 için 16.5" diyor ama metin ve mossberg.com seri listesi 16.25" (413 mm) gösteriyor; 413 mm daha olası. | https://resources.mossberg.com/hubfs/press_releases/Mossberg%20Introduces%20Suppressor%20Ready%20Patriot%20Carbine%20Rifles%20PR%201-6-2025%20FINAL%20(002).pdf |
| 2045 | Mossberg / Patriot Predator | Yiv adımı | 10.0 | 1:10" (28263 sayfası); 1:16 (28175 sayfası ve 2024 bülteni) | ŞÜPHELİ | Kütüphane üretici sayfasıyla aynı (10) ama aynı kalibre Synthetic ve 400 Legend bülteni 1:16 diyor; üretici sayfası çelişkili. | https://www.mossberg.com/mossberg-patriot-predator-28263.html |
| 2047 | Mossberg / Patriot Predator | Yiv adımı | 24.0 | okunamadı; ikiz SKU 28251 sayfası 1:10" | ŞÜPHELİ | 28252 yivi okunamadı. Aynı modelin Cerakote ikizi 28251'de üretici 1:10 yazıyor, diğer tüm 450 BM SKU'ları 1:24; üretici sayfasında hata olabilir, 1:24 kütüphan | https://www.mossberg.com/firearms/rifles/mossberg-patriot/patriot-predator.html |
| 2056 | Mossberg / Patriot Super Bantam | Yiv adımı | 9.5 | 2015 bülteni: Super Bantam 7mm-08 1:10 | ŞÜPHELİ | Güncel SKU sayfası okunamadı; eski 2015 üretici bülteni 1:10 veriyor, kütüphanede 9.5. Bülten özet tablosu tek yiv yazıyor, doğrulama gerekli. | https://www.mossberg.com/firearms/rifles/mossberg-patriot/patriot-bantam.html |
| 2062 | Mossberg / Patriot Synthetic | Model adı | Patriot Synthetic | Patriot Long Action (2015 bülteni) | ŞÜPHELİ | Bülten model ailesi düzeyinde. | https://resources.mossberg.com/hubfs/press_releases/Mossberg-Patriot-PR-1-5-2015-FINAL.pdf |
| 2064 | Mossberg / Patriot Synthetic | Model adı | Patriot Synthetic | Patriot Short Action (2015 bülteni) | ŞÜPHELİ | Bülten model ailesi düzeyinde. | https://resources.mossberg.com/hubfs/press_releases/Mossberg-Patriot-PR-1-5-2015-FINAL.pdf |
| 2071 | Mossberg / Patriot Synthetic | Model adı | Patriot Synthetic | Patriot Short Action (2015 bülteni) | ŞÜPHELİ | Bülten model ailesi düzeyinde, SKU 27851 değil. | https://resources.mossberg.com/hubfs/press_releases/Mossberg-Patriot-PR-1-5-2015-FINAL.pdf |
| 2071 | Mossberg / Patriot Synthetic | Yiv adımı | 9.5 | 1:10 (2015 bülteni) | ŞÜPHELİ | Kütüphane 9.5; eski bülten 1:10. Bülten 22-250 için de 1:10 diyor (güncel sayfa 1:14), güvenilirliği düşük; SKU sayfası kontrol edilmeli. | https://resources.mossberg.com/hubfs/press_releases/Mossberg-Patriot-PR-1-5-2015-FINAL.pdf |
| 2073–2085 (2) | Mossberg / Patriot Walnut | Model adı | Patriot Walnut | Patriot Short Action (2015 bülteni) | ŞÜPHELİ | Bülten model ailesi düzeyinde. | https://resources.mossberg.com/hubfs/press_releases/Mossberg-Patriot-PR-1-5-2015-FINAL.pdf |
| 2078 | Mossberg / Patriot Walnut | Model adı | Patriot Walnut | Patriot Scoped Combo (2015 bülteni) | ŞÜPHELİ | Bülten model ailesi düzeyinde; kütüphanede 'Patriot Walnut' adıyla. | https://resources.mossberg.com/hubfs/press_releases/Mossberg-Patriot-PR-1-5-2015-FINAL.pdf |
| 2085 | Mossberg / Patriot Walnut | Yiv adımı | 9.5 | 1:10 (2015 bülteni) | ŞÜPHELİ | Kütüphane 9.5; eski bülten 1:10. SKU sayfası kontrol edilmeli. | https://resources.mossberg.com/hubfs/press_releases/Mossberg-Patriot-PR-1-5-2015-FINAL.pdf |
| 2315–2317 (3) | Ruger / American Rifle Gen II Scout | Yiv yönü | right |  | ŞÜPHELİ | üretici yön belirtmiyor | https://ruger.com/products/americanRifleScoutGenII/models.html |
| 2318–2332 (11) | Ruger / American Rifle Gen II Standard | Yiv yönü | right |  | ŞÜPHELİ | üretici yön belirtmiyor | https://ruger.com/products/americanRifleGenII/models.html |
| 2370–2371 (2) | Ruger / Mini Thirty | Yiv yönü | right |  | ŞÜPHELİ | üretici yön belirtmiyor | https://ruger.com/products/miniThirty/models.html |
| 2419–2422 (4) | Sabatti / Classic 92 Express | Kalibre | .30 R Blaser, .30-06 Springfield, 8x57 IRS, 9.3x74 R |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. Katalog Classic 92 Express kalibrelerini listelemiyor; doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2419–2422 (3) | Sabatti / Classic 92 Express | Yiv adımı |  |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. kalibre sayfada doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2423–2426 (4) | Sabatti / Express 190 | Kalibre | .30 R Blaser, .30-06 Springfield, 8x57 IRS, 9.3x74 R |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. Katalog Express 190 kalibrelerini listelemiyor; doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2423–2426 (3) | Sabatti / Express 190 | Yiv adımı |  |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. kalibre sayfada doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2439–2447 (9) | Sabatti / Rover Hunter | Namlu boyu |  | [508, 559, 610] | ŞÜPHELİ | Üretici değerini ekle: [508, 559, 610]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2448 | Sabatti / Rover Left Hand | Namlu boyu |  | [460, 510, 559, 600, 610, 650] | ŞÜPHELİ | Üretici değerini ekle: [460, 510, 559, 600, 610, 650]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2449 | Sabatti / Rover Left Hand | Namlu boyu |  | [450, 460, 508, 510, 559, 610, 650, 660, 711] | ŞÜPHELİ | Üretici değerini ekle: [450, 460, 508, 510, 559, 610, 650, 660, 711]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2450 | Sabatti / Rover Left Hand | Namlu boyu |  |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. kalibre sayfada doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2448–2450 (3) | Sabatti / Rover Left Hand | Kalibre | .30-06 Springfield, .308 Win, 8x57 JS |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. Katalog Rover Left Hand kalibrelerini listelemiyor; doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2450 | Sabatti / Rover Left Hand | Yiv adımı |  |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. kalibre sayfada doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2499–2507 (9) | Sabatti / SKL-20 | Kalibre | .243 Win, .270 Win, .30-06 Springfield, .300 Win Mag, .308 Win, 6.5x57 R, 7x57 R, 7x65 R, 8x57 IRS |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. Katalog SKL-20 kalibrelerini listelemiyor; doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2499–2507 (6) | Sabatti / SKL-20 | Yiv adımı |  |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. kalibre sayfada doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2512 | Sabatti / ST-18 | Namlu boyu |  | [450, 460, 508, 510, 559, 610, 650, 660, 711] | ŞÜPHELİ | Üretici değerini ekle: [450, 460, 508, 510, 559, 610, 650, 660, 711]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2513 | Sabatti / ST-18 | Namlu boyu |  | [460, 508, 510, 610, 660, 711] | ŞÜPHELİ | Üretici değerini ekle: [460, 508, 510, 610, 660, 711]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2514 | Sabatti / ST-18 | Namlu boyu |  | [508, 610, 660, 711] | ŞÜPHELİ | Üretici değerini ekle: [508, 610, 660, 711]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2515 | Sabatti / ST-18 | Namlu boyu |  | [508, 610, 660] | ŞÜPHELİ | Üretici değerini ekle: [508, 610, 660]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2481–2489 (9) | Sabatti / Saphire | Namlu boyu |  |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. kalibre sayfada doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2481–2489 (9) | Sabatti / Saphire | Kalibre | .243 Win, .270 Win, .30-06 Springfield, .300 Win Mag, .308 Win, 6.5 Creedmoor, 6.5x55 Swedish, 7mm Rem Mag, 8x57 JS |  | ŞÜPHELİ | üretici sayfasında bu kalibre için bilgi bulunamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2481–2489 (9) | Sabatti / Saphire | Yiv adımı |  |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. kalibre sayfada doğrulanamadı | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2490–2498 (9) | Sabatti / Saphire E.R. | Namlu boyu |  | [610, 650] | ŞÜPHELİ | Üretici değerini ekle: [610, 650]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2490 | Sabatti / Saphire E.R. | Yiv adımı | 10.0 |  | ŞÜPHELİ | Kütüphanedeki yiv adımı üretici kataloğunda yok; kaynak gösterilemiyor | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2491–2493 (3) | Sabatti / Saphire E.R. | Yiv adımı | 11.0 |  | ŞÜPHELİ | Kütüphanedeki yiv adımı üretici kataloğunda yok; kaynak gösterilemiyor | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2494–2495 (2) | Sabatti / Saphire E.R. | Yiv adımı | 8.0 |  | ŞÜPHELİ | Kütüphanedeki yiv adımı üretici kataloğunda yok; kaynak gösterilemiyor | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2496–2497 (2) | Sabatti / Saphire E.R. | Yiv adımı | 8.25 |  | ŞÜPHELİ | Kütüphanedeki yiv adımı üretici kataloğunda yok; kaynak gösterilemiyor | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2498 | Sabatti / Saphire E.R. | Yiv adımı | 9.5 |  | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. üretici sayfası yiv adımı vermiyor; kütüphane değeri kaynaksız | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2526–2532 (7) | Sabatti / Tactical EVO | Namlu boyu |  | [660, 711] | ŞÜPHELİ | Üretici değerini ekle: [660, 711]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2533–2539 (7) | Sabatti / Tactical EVO US | Namlu boyu |  | [559, 660] | ŞÜPHELİ | Üretici değerini ekle: [559, 660]. kütüphanede eksik | https://www.sabatti.it/storage/app/media/Catalogo%20e%20Listino/Sabatti%20Catalog%202024%20EN_web.pdf |
| 2565 | Sako / 85 Hunter | tutarlılık:twistRateIn | 8.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 12.0] | iç denetim |
| 2566 | Sako / 85 Hunter | tutarlılık:twistRateIn | 12.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 12.0] | iç denetim |
| 2675 | Sarsılmaz / SAR 56 | tutarlılık:barrelLengthMm | 190.0 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 2721 | Sauer / 101 Classic | Model adı | 101 Classic | 101 Classic sayfasında bu kalibre yok | ŞÜPHELİ | Satır '101 Classic' adlı ama kaynak Elegance sayfası; 101 Classic üretici sayfası 6.5 Creedmoor listelemiyor | https://www.sauer.de/sauer-101-elegance/ |
| 2725 | Sauer / 101 Classic | Model adı | 101 Classic | 101 Classic sayfasında bu kalibre yok | ŞÜPHELİ | Satır '101 Classic' adlı ama kaynak Elegance sayfası; 101 Classic üretici sayfası 8.5x55 Blaser listelemiyor | https://www.sauer.de/sauer-101-elegance/ |
| 2803 | Savage / 110 Elite Precision | Yiv adımı |  | 1:8.5" | ŞÜPHELİ | Kütüphanede twist boş; üretici SKU sayfası 1:8.5" veriyor, doldurulabilir. | https://savagearms.com/firearms/model/110-elite-precision; SKU 57561/57559/57557/57558 sayfaları |
| 2804 | Savage / 110 Elite Precision | Yiv adımı |  | 1:10" | ŞÜPHELİ | Kütüphanede twist boş; üretici SKU sayfası 1:10" veriyor, doldurulabilir. | https://savagearms.com/firearms/model/110-elite-precision; SKU 57561/57559/57557/57558 sayfaları |
| 2807 | Savage / 110 Elite Precision | Yiv adımı |  | 1:8" | ŞÜPHELİ | Kütüphanede twist boş; üretici SKU sayfası 1:8" veriyor, doldurulabilir. | https://savagearms.com/firearms/model/110-elite-precision; SKU 57561/57559/57557/57558 sayfaları |
| 2808 | Savage / 110 Elite Precision | Yiv adımı |  | 1:7.5" | ŞÜPHELİ | Kütüphanede twist boş; üretici SKU sayfası 1:7.5" veriyor, doldurulabilir. | https://savagearms.com/firearms/model/110-elite-precision; SKU 57561/57559/57557/57558 sayfaları |
| 3016 | Seekins Precision / Havak HIT PRO M3 | Kalibre | 5.56x45 NATO | .223 Wylde | ŞÜPHELİ | Üretici bu modelde '5.56' değil '.223 Wylde' yazıyor; kalibre adı kontrol edilmeli | https://www.seekinsprecision.com/rifles/hit-pro-m3 |
| 3174–3180 (7) | Steyr / SSG 08 | Yiv yönü | right |  | ŞÜPHELİ | üretici yön belirtmiyor | https://www.steyr-arms.com/en/sporting-rifles/ssg-08/ |
| 3174–3175 (2) | Steyr / SSG 08 | Yiv adımı | 10.0 | yok | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. .243 Win için üretici yiv adımı vermiyor; 10" doğrulanamadı. | https://www.steyr-arms.com/en/sporting-rifles/ssg-08/ |
| 3181–3182 (2) | Steyr / SSG 08 A1 | Yiv yönü | right |  | ŞÜPHELİ | üretici yön belirtmiyor | https://www.steyr-arms.com/en/sporting-rifles/ssg-08-a1/ |
| 3181 | Steyr / SSG 08 A1 | Yiv adımı | 12.0 | yok | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. SSG 08 A1 sayfası yiv adımı vermiyor; 12" sağ değeri bu sayfayla doğrulanamadı (SSG 08 sayfasında .308 iç | https://www.steyr-arms.com/en/sporting-rifles/ssg-08-a1/ |
| 3182 | Steyr / SSG 08 A1 | Yiv adımı | 12.0 | yok | ŞÜPHELİ | Aynı: SSG 08 A1 sayfasında yiv adımı ve yönü yok. | https://www.steyr-arms.com/en/sporting-rifles/ssg-08-a1/ |
| 3189 | Steyr / SSG M1 A2 | Namlu boyu | 686.0 |  | ŞÜPHELİ | üretici sayfası bu kalibre için namlu boyu vermiyor | https://www.steyr-arms.com/en/military-law-enforcement/sniper-and-marksman-rifles/ssg-m1-a2/ |
| 3189 | Steyr / SSG M1 A2 | Kalibre | .338 Norma Mag | .338 Norma Mag. yalnızca metinde geçiyor, tabloda yok | ŞÜPHELİ | Gövde metni .338 Norma Magnum'dan söz ediyor ama teknik tabloda yok; 686 mm namlu üreticide görünmüyor. | https://www.steyr-arms.com/en/military-law-enforcement/sniper-and-marksman-rifles/ssg-m1-a2/ |
| 4916 | Stoeger / XM1 PCP | tutarlılık:origin | İthal |  | ŞÜPHELİ | Stoeger: Stoeger tüfekleri Türkiye üretimi olabilir; Yerli listesinde yok; model bazında doğrulanmalı (tüm 2 satır) | iç denetim |
| 3220 | Tikka / T3 Lite Adjustable | tutarlılık:twistRateIn | 8.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 12.0] | iç denetim |
| 3221 | Tikka / T3 Lite Adjustable | tutarlılık:twistRateIn | 12.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 12.0] | iç denetim |
| 3247–3249 (2) | Tikka / T3x Sporter | tutarlılık:twistRateIn | 8.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 12.0] | iç denetim |
| 3248–3250 (2) | Tikka / T3x Sporter | tutarlılık:twistRateIn | 12.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 12.0] | iç denetim |
| 3258 | Tikka / T3x Super Varmint | tutarlılık:twistRateIn | 8.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 14.0] | iç denetim |
| 3259 | Tikka / T3x Super Varmint | tutarlılık:twistRateIn | 14.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 14.0] | iç denetim |
| 3283 | Tikka / T3x Superlite Stainless | tutarlılık:twistRateIn | 8.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 12.0] | iç denetim |
| 3284 | Tikka / T3x Superlite Stainless | tutarlılık:twistRateIn | 12.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 12.0] | iç denetim |
| 4920 | Umarex / Gauntlet Limited | Yiv adımı |  | 1:26 | ŞÜPHELİ | Kütüphanede hatve boş; üretici 1:26 veriyor, eklenebilir | https://www.umarexusa.com/2280311 |
| 4922 | Umarex / Gauntlet Limited | Yiv adımı |  | 1:26 | ŞÜPHELİ | Kütüphanede hatve boş; üretici 1:26 veriyor, eklenebilir | https://www.umarexusa.com/gauntlet-limited-30-cal-pcp-air-rifle-2280313 |
| 3331 | Utaş Arms / Yarı Otomatik Tüfek | tutarlılık:barrelLengthMm | 190.5 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 3339 | Utaş Arms / Çek Bırak Tüfek | tutarlılık:barrelLengthMm | 190.5 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 3369–3371 (2) | Victrix / Gladio | tutarlılık:twistRateIn | 10.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [10.0, 11.0] | iç denetim |
| 3370–3372 (2) | Victrix / Gladio | tutarlılık:twistRateIn | 11.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [10.0, 11.0] | iç denetim |
| 3373–3375 (2) | Victrix / Gladio | tutarlılık:twistRateIn | 8.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 8.5] | iç denetim |
| 3374–3376 (2) | Victrix / Gladio | tutarlılık:twistRateIn | 8.5 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [8.0, 8.5] | iç denetim |
| 3401 | Victrix / Target MKII | tutarlılık:twistRateIn | 10.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [9.5, 10.0] | iç denetim |
| 3402 | Victrix / Target MKII | tutarlılık:twistRateIn | 9.5 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [9.5, 10.0] | iç denetim |
| 3404–3406 (2) | Victrix / Target MKII | tutarlılık:twistRateIn | 7.5 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [7.5, 8.5] | iç denetim |
| 3405–3407 (2) | Victrix / Target MKII | tutarlılık:twistRateIn | 8.5 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [7.5, 8.5] | iç denetim |
| 3411 | Victrix / Target MKII .308 Match | tutarlılık:twistRateIn | 10.0 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [9.5, 10.0] | iç denetim |
| 3412 | Victrix / Target MKII .308 Match | tutarlılık:twistRateIn | 9.5 |  | ŞÜPHELİ | aynı marka/model/kalibre/namlu için farklı yiv: [9.5, 10.0] | iç denetim |
| 3482 | Weatherby / Mark V Backcountry 2.0 Ti | Yiv adımı | 7.5 | 1-10 (table) / 1:7.5 (note) | ŞÜPHELİ | Teknik tabloda 1-10, sayfa notu 1:7.5 diyor; kütüphane 7.5 (not ile uyumlu). | https://weatherby.com/store/mark-v-backcountry-2-0-ti/ |
| 3488 | Weatherby / Mark V Backcountry 2.0 Ti .240 Wby Mag | Yiv adımı | 7.5 | 1-10 (table) / 1:7.5 (note) | ŞÜPHELİ | Teknik tabloda 1-10, sayfa notu 1:7.5 diyor; kütüphane 7.5 (not ile uyumlu). | https://weatherby.com/store/mark-v-backcountry-2-0-ti/ |
| 3863–3867 (4) | Winchester / Model 70 Extreme Weather | Model adı | Model 70 Extreme Weather | Model 70 Extreme Tungsten MB | ŞÜPHELİ | Kaynak sayfa Extreme Tungsten MB; satır adı Extreme Weather. 6.8 Western Extreme Weather SS sayfasında yok. | https://www.winchesterguns.com/products/rifles/model-70/model-70-extreme-tungsten.html |
| 3946 | Zastava / M12M 1007 mm | tutarlılık:barrelLengthMm | 1007.0 |  | ŞÜPHELİ | namlu boyu olağan dışı | iç denetim |
| 4001–4014 (14) | Zastava / M808 | Kalibre | .22-250 Rem, .243 Win, .25-06 Rem, .270 Win, .30-06 Springfield, .308 Win, 6.5x55 Swedish, 6.5x57, 6mm Rem, 7mm-08 Rem, 7x57 Mauser, 7x64, 8x57 JS, 9.3x62 | kalibre belirtilmemiş | ŞÜPHELİ | Kaynak bulunana kadar değeri gözden geçir / boş bırak. Üretici M808 sayfasında kalibre listesi yok; 650 mm namlu doğrulandı, kalibre kaynaksız | https://zastava-arms.rs/en/hunting-rifle-m808/ |

## Erişilemeyen kaynaklar

Marka başına okunamayan satır sayısı (okunamayan / toplam): Bergara 258/258, Savage 173/204, AirMaks Arms 160/160, Cadex 126/142, Sako 124/124, Tikka 115/115, Blaser 101/101, Ruger 87/123, İstanbul Silah 72/72, Daystate 71/71, Krieghoff 68/68, MasterPiece Arms 65/65, Anschütz 59/59, Sauer 55/101, Keppeler 54/54, Merkel 54/54, Weatherby 51/437, Howa 50/50, Proof Research 49/49, Benelli 46/46, FX Airguns 43/43, Accuracy International 42/42, CZ 42/42, Cometa 42/42, PGM Précision 36/36, AEA 35/35, Haenel 32/56, Remington 32/60, Rößler 32/32, Franchi 31/31, Mauser 31/31, Evanix 28/79, Kimber 27/27, Brocock 27/27, Niksan Defence 27/27, Reximex 27/27, Lithgow Arms 26/26, Kral Arms 25/53, Nosler 25/25, Aselkon Arms 24/24, Kuzey Arms 24/36, Diana 22/22, Snowpeak 22/33, Mossberg 19/64, Unique Alpine 19/19, Huğlu 18/18, Verney-Carron 18/18, Air Arms 18/18, Gamo 17/17, Utaş Arms 16/16, Hatsan 15/110, Desert Tech 14/14, Effecto 12/14, Ekol 12/12, Kale Kalıp 11/11, Marlin 11/11, Sig Sauer 11/27, Benjamin 11/11, Sabatti 10/128, Weihrauch 9/9, Daniel Defense 8/8, Heym 8/8, Retay 8/8, Sarsılmaz 8/8, Beretta 7/7, EDgun 7/7, Balıklı 6/24, Umarex 6/13, Walther 4/4, Art Tech 3/3, MKE 3/26, Crosman 2/2, Stoeger 2/2, Barrett 1/41.

Bunlar bir sonraki denetim turunda (yeni arama kotasıyla) yeniden denenecek; Sabatti ürün sayfaları robots.txt ile kapalı olduğu için yalnız Sabatti 2024 kataloğu (PDF) kullanıldı.

## Yöntem

- 908 kaynak adresi 20 gruba bölündü, paralel alt ajanlar her adres için önce web araması (üretici alan adıyla sınırlı), sonra üretici sayfasını okudu. Yalnız üretici siteleri/PDF kataloglar kullanıldı; bayi, forum, blog ve başka balistik uygulama verisi kullanılmadı.
- Kaynak adresi açılamazsa üreticinin aynı modele ait güncel sayfası okundu (CSV `url` sütununda okunan adres var).
- Karşılaştırma kuralları: yiv adımı ±%1,2 (en az ±0,06 inç; mm→inç dönüşüm yuvarlaması), namlu boyu ±4 mm. Kütüphanede boş ama üreticide var → ŞÜPHELİ (eksik); kütüphanede var ama üreticide yok → ŞÜPHELİ (kaynaksız); farklı → HATALI.
- Yerli/İthal: `profiles_screen.dart` içindeki `_domesticBrands` listesi, üreticinin kendi adres/üretim yeri ifadesiyle karşılaştırıldı; ifade okunamadıysa ERİŞİLEMEDİ.
- Kütüphanede PCP regülatör/tüp basıncı ya da hız alanı yok; üretici sayfasında görülen değerler bilgi olarak CSV'de `pcp_basinc_hiz` alanında tutuldu.
- Tüm kayıtlar: `data/veri_denetimi/tufek.csv` (satır, marka, model, alan, kütüphane değeri, üretici değeri, durum, URL, okuma tarihi, ≤15 kelime alıntı, not).

## Yapılmayanlar

- `lib/` ve `lib/data/` değiştirilmedi; düzeltmeler sahibin onayını bekliyor.
- Erişilemeyen kaynaklar için değer tahmin edilmedi; CI, Simulator, TestFlight çalıştırılmadı (kod değişikliği yok).
