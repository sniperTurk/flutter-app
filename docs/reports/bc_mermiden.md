# BC mermiden: BC'si boş kalan ateşli tüfek fişekleri

Tarih: 14.10.2026 (İstanbul) · Dal: `data/bc-mermiden` · Taslak PR, birleştirme yok, TestFlight yok.

Sahibin kararı: 13:53 "Ateşli tüfekler için benim derdim." 13:55 "Bulabilirsek sorun yok!
Kimsenin verisine ihtiyacımız yok ama ateşli tüfekler eksiksiz olmalı."

## Özet

- #296 birleştikten sonra `lib/data/factory_ammo_library.dart` içinde BC'si boş **53** ateşli
  tüfek fişeği vardı. Listeyi main'den çıkardım; sayı ve marka dağılımı görevdeki ile aynı.
- **14 fişeğe fişek üreticisinin kendi yazdığı BC eklendi:** Winchester 13, SWISS P 1.
- **Mermi üreticisinden: 0.** Adı geçen mermilerin hiçbirinin üretici BC'si bulunamadı. Hornady
  70 gr GMX artık satılmıyor; Hornady'nin 125 gr .308 CX diye bir bileşen mermisi yok; Nosler'ın
  50 gr FBHP Varmageddon diye bir bileşen mermisi yok.
- **39 fişek hâlâ BC'siz (bulunamadı).** Black Hills 23, Aguila 3, Geco 2, Lapua 2, MKE 2,
  Federal 1 (saçma fişeği), RWS 1, Nosler 1, Norma 1, Hornady 1, SWISS P 1, Winchester 1.
- **FA007 düzeltildi:** Aguila "22 Long Rifle Standard Velocity Lead Solid Point" 29 gr → 40 gr.
  Kaynak aguilaammo.com; satıra kaynak notu eklendi.
- Başka satır, hesap kodu ya da arayüz değişmedi. #296'nın doldurduğu 30 satıra dokunulmadı.

## Nasıl

- Her fişek için sıra şuydu:
  1. Fişek üreticisinin kendi BC'si: ürün sayfası, katalog PDF'i ya da bilgi föyü.
  2. Yoksa, üretici mermiyi adıyla yazıyorsa mermi üreticisinin BC'si.
  3. O da yoksa "bulunamadı".
- Yalnız üretici sitelerini okudum ve her sitede önce robots.txt'ye baktım. rws-ammunition.com
  robots.txt ile kapalı olduğu için açılmadı.
- Forum, blog, bayi değeri ve başka balistik uygulamalarının verisi kullanılmadı. Arama
  sonuçlarını yalnız üreticinin sayfasını bulmak için ipucu olarak kullandım.
- **Winchester:** ürün sayfaları "There is no ballistics data available at this time" diyor. BC'ler
  Winchester'ın kendi kataloglarındaki balistik tablolarının "B.C." sütununda basılı. Kataloglar
  winchester.com katalog bağlantısından açılan resmî flipbook'lar: 2020, 2025 ve 2026.
  - Okuma aracı tablo sütunlarını ayrı ayrı veriyor. Satırı bu yüzden sembol sırası, ağırlık,
    hız ve açıklama ile eşleştirdim.
  - Eşleştirmeyi, kütüphanede zaten BC'si olan Winchester satırlarıyla sınadım. Varmint LF 0,062,
    USA 36 gr 0,084, Silvertip/Varmint HE 0,090, 22 WMR V-MAX 0,095 ve 6.5 PRC AccuBond LR 0,625
    katalogda da aynı satıra düşüyor.
- **Model:** Winchester sütun başlığı yalnız "B.C." diyor, G1/G7 yazmıyor. Kütüphanenin
  kuralına uyarak G1 kabul ettim ve bunu not alanına yazdım.
- **SWISS P:** bilgi föyü G1 ve G7'yi birlikte veriyor. Kütüphanenin kuralına göre `bc` G1,
  `bcG7` G7 oldu.
- **Hız bantları:** `FactoryAmmo` sınıfında bant alanı yok, ve sınıfı değiştirmek kapsam dışı.
  SWISS P'nin bantlarını bu yüzden not alanına yazdım.

## Bulunanlar (14)

Okuma tarihi hepsinde 14.10.2026. Kaynak türü: "Fişek üreticisi (katalog)" ya da "Fişek
üreticisi (bilgi föyü)".

| Marka | Ad | Kalibre | Ağırlık | BC + model | Kaynak türü | URL | Alıntı (≤15 kelime) |
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
| Winchester | Super-X Power-Point 129 gr (X651) | 6.5 Creedmoor | 129 gr | 0,324 G1* | Katalog 2026 s.32 | https://online.flippingbook.com/view/721179895/34/ | "X651 … 129 0.324" |
| Winchester | Power-Point 170 gr (X68W1) | 6.8 Western | 170 gr | 0,431 G1* | Katalog 2026 s.33 | https://online.flippingbook.com/view/721179895/35/ | "SBST68W X68W1 S68WBC … 170 0.550 / 170 0.431 / 175 0.682" |
| SWISS P | Target SX 8.4 g / 130 gr | 6.5 Creedmoor | 130 gr | 0,622 G1 + 0,308 G7 (ICAO) | Bilgi föyü | https://swiss-p.com/s/Sniper_factsheet_65-CM-Target-SX_hr-agss.pdf | "Ballistic Coefficient G1 / G7 0.622 / 0.308 (ICAO)" |

\* Üretici etiket vermiyor; G1 kabul edildi.

- Bu 14 değerin hepsi, Profil'deki BC uyarısının G1 aralığında kalıyor (SD/BC 0,32–4,6).
  Değerler 0,43 ile 1,16 arasında.
- **Mermi üreticisinden alınan:** 0.

## Bulunamayanlar (39) ve bakılan yerler

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

## FA007 ağırlık düzeltmesi

- Aguila ürün sayfası
  (https://www.aguilaammo.com/products/22-super-extra-long-rifle-standard-velocity-lead-solid-point,
  14.10.2026) bu ürünü "40 Grain" diye veriyor. Kütüphanedeki 29 gr, 22 Short'un ağırlığı.
- Satırın ağırlığı 40 gr yapıldı ve not alanına kaynak notu yazıldı.
- **Bilerek yapılmadı:** aynı sayfa namlu ağzı hızını 1130 fps veriyor; kütüphanede 1095 fps var.
  1095 de 22 Short'un hızı. Sahip yalnız ağırlığı onayladığı için hız değişmedi. Ayrı karar
  gerekiyor.

## Uç durumlar

1. **Winchester satır eşleştirmesi:** kataloglar BC'yi basıyor, ama okuma aracı tabloyu sütun
   sütun verdiği için satır eşleştirmesini ben yaptım.
   - **Güçlü olanlar:**
     - SUP22LR: iki 45 gr satırı da 0,141.
     - S22M2: WMR sırasındaki bilinen değerler tutuyor.
     - X651: 6.5 CM bloğunda tek 129 gr satırı.
     - X22LRH ve X22LRHSS1: hız ve komşu satırlar tutuyor.
     - Wildcat: açıklama ve üç 0,116 değeri.
   - **Orta güvenli olanlar:**
     - **M22 (0,125), X22LRSS1 (0,119), XHV22LR (0,105), X22LRPP/PP1 (0,098):** 2020
       kataloğunda sembol sırası bu beş satırda bir kayık. Değerleri hız sütunuyla eşleştirdim
       (1255 / 1280 / 1280 / 1300 / 1435 fps). 2025 kataloğundaki açıklama sırası da aynı sonucu
       veriyor.
     - **X68W1 (0,431):** 6.8 Western bloğunda üç 170 gr satırı var (0,633 / 0,550 / 0,431).
       Sembol sırası ile 5. çift X68W1'e düşüyor. Aynı sayfada 6.5 PRC bloğu bu sırayla AccuBond
       LR 0,625 ve Ballistic Silvertip 0,509 ile doğru eşleşiyor.
2. **X22LRPP1:** kütüphanede 1300 fps yazıyor, 2020 kataloğunda 1280 fps. Aynı 40 gr
   Power-Point mermisi olduğu ve iki Power-Point satırı da 0,098 olduğu için BC etkilenmiyor.
   Hız değişmedi.
3. **X22LR:** güncel ürün sayfası 1150 fps diyor, kütüphanede 1255 fps var. BC (0,116) iki
   okumada da aynı. Hız değişmedi.
4. **G1 / G7:**
   - Winchester etiket vermiyor; G1 kabul edildi ve notta yazıyor.
   - SWISS P G1 ve G7'yi birlikte, ICAO atmosferinde veriyor. `bc` G1 0,622, `bcG7` 0,308.
   - SWISS P'nin G1 bantları çok değişiyor (875 m/s 0,6219, 340 m/s 0,3806, 200 m/s 0,5359).
     G7 daha sabit (0,3081 / 0,3012 / 0,3134). Bantlar notta duruyor.
5. **Rimfire:** 12 Winchester .22 LR / WMR değeri, kütüphanedeki diğer Winchester rimfire
   satırları gibi etiketsiz G1. Ses altı ve ses civarı hızlarda tek bir G1 değeri yaklaşık bir
   sayıdır.
6. **Mermi kimliği belirsiz olanlar:** "Match HP", "OTM", "Soft Point" gibi genel adlar ağırlıktan
   tahmin edilmedi. Black Hills aynı sayfada Sierra'lı ürünleri ayrıca satıyor, bu yüzden genel adlı
   olanların aynı mermi olduğu varsayılamaz.
7. **Var olan test:** `test/factory_ammo_bc_backsolve_test.dart` FA007'nin 29 gr ve notsuz
   kalmasını bekliyordu. İki satırı değişti: 40 gr ve FA007 için not beklentisi. Başka
   beklentisi değişmedi.

## Bilerek yapılmayanlar

- Hız tablosundan geri hesap yapılmadı; bu görevde yalnız basılı BC kullanıldı.
- `FactoryAmmo` sınıfına bant alanı eklenmedi.
- Hız düzeltmeleri yapılmadı: FA007 1095→1130, X22LR, X22LRPP1.
- Black Hills'e e-posta yazılmadı.
- Hesap kodu ve arayüz değişmedi.

## Testler

- Yeni test: `test/factory_ammo_bc_mermiden_test.dart`.
  - 14 satırın her birinde BC > 0, model G1, `bcSource: 'printed'`, https kaynak URL'si ve
    14.10.2026 notu var.
  - Winchester notlarında "G1 kabul edildi" yazıyor.
  - SWISS P için G7 0,308 ve "ICAO" notu var.
  - Profil BC uyarısıyla aynı kesit yoğunluğu aralığından (G1 0,32–4,6) geçiyorlar.
  - FA007 40 gr.
  - BC'siz 39 satır kalıyor ve hepsinde model boş.
- Yerel:
  - `python3 tools/offline_dart_lint.py`: PASS (334 Dart dosyası, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: 740 test OK.
- Flutter SDK bu ortamda yok; `flutter test` yerelde çalışmadı.
- CI: aşağıda.
- Not: bu dal önceki bir çalıştırmada eski main'den açılmıştı (PR #304, yalnız X651 ve FA007). main
  (#296, #298) birleştirildi ve tüm iş bu çalıştırmada yeniden yapıldı; PR farkı yalnız bu dört dosya.

## CI

Hepsi `fa5acf6` commit'inde çalıştı (veri ve test commit'i; bu rapor commit'i yalnız belge).

- Format (`375209577`): **başarılı**, "Formatted 336 files (0 changed)", format commit'i gerekmedi.
  https://github.com/sniperTurk/flutter-app/actions/runs/38575174089
- Test (`test-diag.yml`, `files=test`): **başarılı** (`flutter test` çıkış kodu 0). Görünen
  "error" notları testlerin kendi tanı çıktısı (KESIK tablosu, beklenen hata yığınları), başarısız
  test değil.
  https://github.com/sniperTurk/flutter-app/actions/runs/38575503012
- Analyze (`analyze-diag.yml`, `--fatal-infos --fatal-warnings`): **başarılı** (çıkış kodu 0;
  tek not `flutter pub outdated` ipucu).
  https://github.com/sniperTurk/flutter-app/actions/runs/38575507895
- iOS CI / Simulator / TestFlight: çalıştırılmadı.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
