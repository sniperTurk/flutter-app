# BC mermiden: BC'si boş kalan ateşli tüfek fişekleri

Tarih: 14.10.2026 (İstanbul) · Dal: `data/bc-mermiden` · PR #304 (taslak). Birleştirme ve
TestFlight yok.

Sahibin kararları:
- 13:53 "Ateşli tüfekler için benim derdim."
- 13:55 "Bulabilirsek sorun yok! Kimsenin verisine ihtiyacımız yok ama ateşli tüfekler eksiksiz
  olmalı."
- **15:16:** kalan 52 BC'siz fişek **boş kalacak**. Tahmin yok, başka kaynak yok.

## Özet

- #296 birleştikten sonra BC'si boş ateşli tüfek fişeği sayısı **53** idi.
- Bu PR **yalnız iki satırı** değiştiriyor:
  1. **Winchester 6.5 Creedmoor Super-X Power-Point 129 gr (X651):** BC 0,324 G1, üreticinin 2026
     kataloğundan. `bcSource`, `bcSourceUrl` ve not var.
  2. **FA007 Aguila 22 LR Standard Velocity Lead Solid Point:** ağırlık 29 → 40 gr, kaynak notuyla.
- **Kalan 52 fişek boş kaldı** (sahibin 15:16 kararı). Hiçbir tahmin ya da başka kaynak eklenmedi.
- Fişek üreticisinden 1 BC, mermi üreticisinden 0 BC.
- #296'nın main'deki 30 değeri aynen duruyor. Hesap kodu ve arayüz değişmedi.

## Çakışma çözümü

- Bu dal, #296 ve #298 birleşmeden önceki main'den açılmıştı. Bu yüzden
  `lib/data/factory_ammo_library.dart` dosyasında çakışma vardı.
- Güncel main (`f09270a`) dala birleştirildi (merge commit, geçmiş yeniden yazılmadı).
- Çözümde dosya main'deki haliyle alındı. Üstüne yalnız bu PR'ın iki satırı uygulandı.
- `git diff origin/main -- lib/data/factory_ammo_library.dart` yalnız 2 satır gösteriyor: X651 ve
  FA007. #296'nın 30 satırının hiçbiri değişmedi.
- **Sahibin 15:16 kararına uyum:** önceki bir takip çalıştırması 13 fişeğe daha üretici BC'si
  eklemişti (Winchester 12, SWISS P 1). Bu çalıştırmada o 13 satır main'deki boş hallerine
  döndürüldü. Bulunan değerler yalnız bilgi için aşağıda listeleniyor; uygulamada yoklar.

## Değişen satırlar

| Marka | Ad | Kalibre | Ağırlık | BC + model | Kaynak türü | URL | Okuma | Alıntı |
|---|---|---|---|---|---|---|---|---|
| Winchester | Super-X Power-Point 129 gr (X651) | 6.5 Creedmoor | 129 gr | 0,324 G1 (etiketsiz, G1 kabul) | Fişek üreticisi, katalog 2026 s.32 | https://online.flippingbook.com/view/721179895/34/ | 14.10.2026 | "X651 … 129 0.324" |
| Aguila | 22 LR Standard Velocity LSP (FA007) | .22 LR | 29 → 40 gr | BC yok | Fişek üreticisi, ürün sayfası | https://www.aguilaammo.com/products/22-super-extra-long-rifle-standard-velocity-lead-solid-point | 14.10.2026 | "40 Grain" |

- X651 satır eşleştirmesi: 6.5 CM bloğunda 14 sembol var ve X651 8. sırada. 8. ağırlık/BC çifti
  "129 0.324". Bu blokta başka 129 gr satırı yok.
- Komşu satırlar kütüphanedeki değerlerle tutuyor: AccuBond LR 142 gr 0,625, Ballistic Silvertip
  0,509, Match 140 gr 0,580.
- Kesit yoğunluğu/BC = 0,815; Profil BC uyarısının G1 aralığında (0,32–4,6).

## Boş kalan 52 fişek

Hepsi sahibin 15:16 kararıyla boş kaldı. Tablo, nelere bakıldığını gösteriyor.

### Bulundu ama uygulanmadı (13, bilgi için)

Bu değerler üreticinin kendi kataloğunda ya da bilgi föyünde basılı. Sahibin 15:16 kararı
nedeniyle uygulamaya eklenmedi. Sahip isterse ayrı bir görevle eklenebilir.

| Marka | Ad | Kalibre | Ağırlık | Basılı BC | Kaynak | URL | Alıntı |
|---|---|---|---|---|---|---|---|
| Winchester | M22 40 gr Black Copper Plated Round Nose (S22LRT) | .22 LR | 40 gr | 0,125 G1* | Katalog 2025 s.39 | https://online.flippingbook.com/view/616451212/41/ | "40 … 0.125 … RN Black Copper Plated" |
| Winchester | Super Suppressed 45 gr BCP RN (SUP22LR) | .22 LR | 45 gr | 0,141 G1* | Katalog 2025 s.39 | https://online.flippingbook.com/view/616451212/41/ | "45 45 … 0.141 0.141" (iki 45 gr satırı) |
| Winchester | Super X 37 gr HP Copper Plated (X22LRH) | .22 LR | 37 gr | 0,107 G1* | Katalog 2020 s.31 | https://online.flippingbook.com/view/7964/33/ | "X22LRH … 0.107 … 1280" |
| Winchester | Super X 40 gr LRN Copper Plated (X22LR) | .22 LR | 40 gr | 0,116 G1* | Katalog 2020 s.31 | https://online.flippingbook.com/view/7964/33/ | "XT22LR X22LR WW22LR WW22LRB … 0.116 0.116 0.116 0.116" |
| Winchester | Super X 40 gr Power-Point HP (X22LRPP) | .22 LR | 40 gr | 0,098 G1* | Katalog 2020 s.31 | https://online.flippingbook.com/view/7964/33/ | "0.098 0.098 … 1280 1280" |
| Winchester | Super X 40 gr Power-Point HP (X22LRPP1) | .22 LR | 40 gr | 0,098 G1* | Katalog 2020 s.31 | https://online.flippingbook.com/view/7964/33/ | "0.098 0.098 … 1280 1280" |
| Winchester | Super X Super Speed 37 gr HP (X22LRHSS1) | .22 LR | 37 gr | 0,111 G1* | Katalog 2020 s.31 | https://online.flippingbook.com/view/7964/33/ | "X22LRHSS1 … 0.111 … 1330" |
| Winchester | Super X Super Speed 40 gr RN (X22LRSS1) | .22 LR | 40 gr | 0,119 G1* | Katalog 2020 s.31 | https://online.flippingbook.com/view/7964/33/ | "0.119 … 1300 … Plated Round Nose" |
| Winchester | Varmint HV 40 gr HP (XHV22LR) | .22 LR | 40 gr | 0,105 G1* | Katalog 2020 s.31 | https://online.flippingbook.com/view/7964/33/ | "0.105 … 1435" |
| Winchester | Wildcat 40 gr DynaPoint (WW22LR/B) | .22 LR | 40 gr | 0,116 G1* | Katalog 2025 s.39 | https://online.flippingbook.com/view/616451212/41/ | "Plated Dynapoint … 0.116" |
| Winchester | Varmint HV 22 WMR 30 gr JHP (S22M2) | .22 WMR | 30 gr | 0,089 G1* | Katalog 2025 s.39 | https://online.flippingbook.com/view/616451212/41/ | "S22M2 JHP 0.089 … 2250" |
| Winchester | Power-Point 170 gr (X68W1) | 6.8 Western | 170 gr | 0,431 G1* | Katalog 2026 s.33 | https://online.flippingbook.com/view/721179895/35/ | "SBST68W X68W1 S68WBC … 170 0.550 / 170 0.431 / 175 0.682" |
| SWISS P | Target SX 8.4 g / 130 gr | 6.5 Creedmoor | 130 gr | 0,622 G1 + 0,308 G7 (ICAO) | Bilgi föyü | https://swiss-p.com/s/Sniper_factsheet_65-CM-Target-SX_hr-agss.pdf | "Ballistic Coefficient G1 / G7 0.622 / 0.308 (ICAO)" |
\* Üretici etiket vermiyor. Winchester satırlarının bir kısmı, katalog tablosu sütun sütun okunduğu
için hız/açıklama ile eşleştirildi; bu satırlar orta güvenli.

### Bulunamadı (39)

| Marka | Ad | Kalibre | Neye bakıldı / ne yazıyor |
|---|---|---|---|
| Black Hills | 52 gr Match HP | .223 Rem | Ürün sayfası mermi markası ve BC vermiyor. Site haritası, sözlük ve "ammunition" sayfasında da yok. Medya kiti şifreli. |
| Black Hills | 55 gr FMJ | .223 Rem | Aynı; genel ad, marka yok, BC yok |
| Black Hills | 55 gr Soft Point | .223 Rem | Aynı |
| Black Hills | 60 gr Soft Point | .223 Rem | Aynı |
| Black Hills | 68 gr Heavy Match HP | .223 Rem | Aynı; marka yazılmıyor, ağırlıktan tahmin edilmedi |
| Black Hills | 75 gr Heavy Match HP | .223 Rem | Aynı |
| Black Hills | 77 gr Open Tip Match | .223 Rem | Sayfa "77 Gr. Open Tip Match (OTM)" diyor. Sierra adı yalnız ayrı bir Reman ürününde geçiyor; aktarılmadı. |
| Black Hills | 62 gr Dual Performance | 5.56x45 | Black Hills'in kendi bakır mermisi; BC yayımlanmıyor |
| Black Hills | 69 gr Open Tip Match | 5.56x45 | Aynı sayfadaki "69 Gr. Sierra TMK" ayrı ürün; bu OTM'nin markası yok |
| Black Hills | 70 gr Hornady GMX | 5.56x45 | Mermi belli ("70 Gr. Hornady GMX™"). Ama Hornady sitesinde 70 gr GMX'in BC'si yok; mermi artık satılmıyor. CX'in BC'si yerine konmadı. |
| Black Hills | 77 gr Open Tip Match | 5.56x45 | "77 Gr. Sierra TMK" ayrı ürün; bu OTM'nin markası yok |
| Black Hills | Gold 168 gr Hornady Match Hollow Point | .30-06 | Marka Hornady, ama hat belli değil (BTHP Match / AeroMatch); Hornady sayfasında BC görünmüyor |
| Black Hills | 115 gr Dual Performance | .300 BLK | Kendi mermisi; BC yok |
| Black Hills | 125 gr Open Tip Match | .300 BLK | "125 Gr. Sierra TMK" ayrı ürün; marka yok |
| Black Hills | 198 gr Dual Performance | .300 BLK | Kendi mermisi; BC yok |
| Black Hills | 220 gr Open Tip Match | .300 BLK | Marka yok, BC yok |
| Black Hills | 190 gr Match Hollow Point | .300 Win Mag | Marka yok, BC yok |
| Black Hills | 168 gr Match Hollow Point | .308 Win | Marka yok, BC yok |
| Black Hills | 175 gr Match Hollow Point | .308 Win | "175 Gr. Sierra TMK" ayrı ürün; marka yok |
| Black Hills | Gold 125 gr Hornady CX | .308 Win | Mermi belli ("125 Gr. Hornady CX™"), ama hornady.com'da 125 gr .308 CX bileşeni ve BC'si yok |
| Black Hills | Gold 152 gr Dual Performance | .308 Win | Kendi mermisi; BC yok |
| Black Hills | Gold 130 gr Dual Performance | 6.5 CM | Kendi mermisi; BC yok |
| Black Hills | Gold 90 gr Dual Performance | 6mm ARC | Kendi mermisi; BC yok |
| Winchester | M22 Subsonic 45 gr BCP RN | .22 LR | Güncel rimfire listesinde ve 2020/2025 kataloglarında böyle bir ürün yok. Super Suppressed 45 gr ayrı ürün olduğu için onun değeri aktarılmadı. |
| Aguila | 17 HMR 20 gr JHP | .17 HMR | Ürün sayfası ve 2023 kataloğu BC vermiyor (katalogda BC sütunu yok) |
| Aguila | 22 LR Standard Velocity LSP (FA007) | .22 LR | BC yok; ağırlık düzeltildi (aşağıda) |
| Aguila | 223 REM 55 gr FMJ | .223 Rem | Ürün sayfası ve katalog BC vermiyor |
| Federal | Small Game 25 gr #12 Shot | .22 LR | Saçma fişeği. Federal "Ballistic Coefficient N/A" yazıyor. |
| Geco | GECO RIFLE .22 2,6 g | .22 LR | Ürün sayfasında BC yok. Veri föyü bağlantısı okuma aracının URL sınırını aştığı için okunamadı. |
| Geco | GECO SEMI-AUTO .22 2,6 g | .22 LR | Aynı |
| RWS | Long Range Match | .22 LR | rws-ammunition.com robots.txt ile kapalı. rws-technology.com'un robots.txt'si okunamadığı için katalog açılmadı. |
| Nosler | 50 gr FBHP NoslerCustom | .222 Rem Mag | Ürün sayfası (SKU 02025) BC vermiyor ve mermiyi "Varmageddon 50gr FBHP" diye yazıyor. Nosler'ın Varmageddon bileşen listesinde 50 gr FBHP yok. |
| Norma | Whitetail 55 gr | .223 Rem | Ürün sayfası yalnız hız veriyor, BC yok; mermi "soft-point", hat adı yok |
| Lapua | 5.8 g (90 gr) FMJ | .243 Win | Lapua ürün sayfası ve 2024 kataloğu "BC G1 – BC G7 –" diyor |
| Lapua | 6.5 g (100 gr) SP | .243 Win | Yalnız katalog hız tablosunda var; BC sütunu yok, ürün sayfası yok |
| Hornady | 338 ARC 285 gr FMJ Frontier (Subsonic) | .338 ARC | Ürün sayfasında BC/G1/G7 yok, yalnız hız tablosu var. Mermi adı verilmiyor. |
| MKE | 8.59×70 Fişek (Normal) | .338 LM | Ürün sayfası ve Küçük Silah Mühimmatı kataloğu BC vermiyor |
| MKE | 8.59×70 Solid Fişek | .338 LM | Aynı |
| SWISS P | LR-1 9.3 g | 6.5 CM | Ürün sayfasında BC yok. SWISS P 2026-27 kataloğu "DATI BALISTICI NON DISPONIBILI", G1/G7 "TBD" diyor. |

## FA007 notu

- Aguila sayfası bu ürünün hızını 1130 fps veriyor; kütüphanede 1095 fps var, bu da 22 Short'un
  hızı.
- Sahip yalnız ağırlığı onayladığı için hız değişmedi. Ayrı karar gerekiyor.

## Uç durumlar

- **G1 / G7:** Winchester katalogları sütuna yalnız "B.C." yazıyor. Kütüphanenin kuralına göre G1
  kabul edildi ve bu notta yazıyor.
- **Rimfire / saçma:** Federal #12 saçma fişeği için üretici "Ballistic Coefficient N/A" diyor;
  zaten boş kalmalı.
- **Mermi kimliği belirsiz:** Black Hills'in genel adlı mermileri ("Match HP", "OTM", "Soft
  Point") ağırlıktan tahmin edilmedi.
- **Var olan test:** `test/factory_ammo_bc_backsolve_test.dart` FA007'nin 29 gr ve notsuz
  kalmasını bekliyordu. İki satırı değişti: 40 gr ve FA007 için not beklentisi.

## Bilerek yapılmayanlar

- Kalan 52 fişeğe BC eklenmedi (sahibin 15:16 kararı). Bulunan 13 değer de dahil.
- Hız düzeltmesi yapılmadı (FA007 1095 → 1130).
- Hesap kodu, arayüz ve başka satırlar değişmedi.

## Testler

- `test/factory_ammo_bc_mermiden_test.dart`:
  - X651: BC 0,324 > 0, model G1, `bcSource: 'printed'`, https kaynak URL'si, 14.10.2026 notu,
    "G1 kabul edildi" notu, kesit yoğunluğu aralığı.
  - FA007: 40 gr ve not.
  - Kalan 52 fişekte BC, model ve `bcSource` boş.
- Yerel:
  - `python3 tools/offline_dart_lint.py`: PASS (334 Dart dosyası, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: OK.
- Flutter SDK bu ortamda yok; `flutter test` yalnız CI'da çalıştı.

## CI

CI_PLACEHOLDER

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
