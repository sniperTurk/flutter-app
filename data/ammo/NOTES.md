# Fabrika fişek verisi — notlar (2026-10-10)

Kaynak kuralı: değerler yalnızca üreticinin kendi sitesinden / PDF kataloğundan okundu. Okunmayan değer yazılmadı (BC yoksa `null`); hızı olmayan kayıt yok. Hiçbir yaş onayı kutusu onaylanmadı.

## Sayılar (toplam 1173; 2026-10-11 çalıştırmasında +531)

| Dosya | Kayıt |
|---|---|
| federal.json | 196 |
| sellier_bellot.json | 152 |
| rws.json | 144 |
| winchester.json | 117 |
| norma.json | 111 |
| remington.json | 89 |
| black_hills.json | 88 |
| lapua.json | 58 |
| hornady.json | 58 |
| geco.json | 46 |
| sako.json | 30 |
| barnes.json | 20 |
| cci.json | 20 |
| swiss_p.json | 18 |
| mke.json | 12 |
| sierra.json | 8 |
| ppu.json | 3 |
| eley.json | 1 |
| nosler.json | 1 |
| berger.json | 1 |

## Eksik kalanlar ve nedenleri
- **WebFetch hız sınırı (HTTP 429):** paralel toplama sırasında proxy tüm alan adlarını ~30 dk engelledi; kurala uyup başka yolla çekilmedi. Remington, RWS, MKE hiç okunamadı; Sellier & Bellot, PPU, Nosler, Berger çok az okundu. Bir sonraki çalıştırmada bunlar sırayla (paralel değil) tekrar denenmeli.
- **Hornady:** ürün sayfalarında sayısal G1/G7 görünmüyor → 58 kaydın hepsinde BC `null`. static.hornady.media üzerindeki balistik tablo PDF'leri izin istemi zaman aşımına uğradığı için kullanılmadı.
- **Yaş kapısı:** Hornady, Barnes, Nosler sitelerinde "18+?" penceresi var; onaylanmadı. İçerik pencerenin arkasında sayfa metninde geldiği için okundu.
- **MKE:** sitedeki ürünler ağırlıkla askerî (7.62x51 M80 vb.); bunların ".308 Win" sayılıp sayılmayacağı sahibin kararı.

## Varsayımlar (kayıt `notes` alanında da yazılı)
- Etiketsiz "BC" değerleri (Winchester, Geco, Sako, PPU, Barnes) `g1_bc` olarak yazıldı. İstenmezse bu markalarda `g1_bc` null'lanabilir.
- m/s → fps (×3.28084), g → gr (×15.4324), mm → inç dönüşümleri notlarda belirtildi (Sako tamamen m/s).
- Federal ve Winchester test namlu boyu yayınlamıyor → `test_barrel_in` null. Federal `source_url` kategori listesi sayfasıdır.
- 8mm Mauser / 8x57 IS → "8x57 JS". 7.62x51 NATO yükleri hedef listede olmadığından dışarıda.
- Barnes: kartuş, Barnes'ın kendi CFR balistik PDF'indeki SKU satırı ile site listesinin eşleştirilmesiyle belirlendi (yöntem her kaydın notunda); iki satırda hıza göre karar verildi.
- Lapua 6.5 CM Naturalis (N316401): katalog ile ürün sayfası çelişiyor (815 vs 780 m/s, BC 0.472 vs 0.201); ürün sayfası kullanıldı. 0.201 şüpheli — kontrol edilmeli.
- Aynı özellikli paket varyantları tek kayıtta birleştirildi (diğer kodlar notta).

## 2026-10-11 çalıştırması (sıralı, istekler arası ~25 sn, 429 alınmadı)

Eklenenler: MKE 12, RWS 144, Remington 89, Black Hills 88, Sellier & Bellot +151, CCI 20, SWISS P 18, Sierra 8, ELEY 1.

### Kayıt bazında dikkat
- **MKE:** askerî fişekler (5.56 NATO, 7.62x51 NATO, 7.62x54R, 7.62x39, 8.59x70 → `.338 Lapua Mag`). Sitedeki hız çoğunlukla **V23.7 m (78 ft)** — namlu ağzı değil; `muzzle_velocity_fps` alanına bu değer yazıldı ve her kayıt notunda belirtildi. Sahibi isterse ayrı alan/etiket. 8.59x70 sayfasında fişek ağırlığı (~21.8 g) mermi ağırlığıyla çelişiyor (site hatası olabilir). 12.7x99 sayfaları açılamadı. Sivil (av) tüfek fişeği sitede yok.
- **RWS:** av fişekleri RWS 2025 kataloğu metninden (rws-technology.com indirme sayfası); metin 8x68 S bölümünde kesiliyor → 8x68 S, 9.3x62 (Short Rifle dışı), 9.3x74 R, .375 vb. eksik. BC etiketsiz → G1 varsayıldı. Target Elite Plus ve .22 LR ürün sayfalarından. .338 LM TEP 300 gr sayfası hata verdi.
- **Remington:** rifle listesinin sayfalaması sunucu tarafında çalışmıyor; kalibre sayfaları (.308, .30-06, 6.5 CM, .223, .243, .270, .300 WM, 7mm RM, 7mm-08, .300 WSM) + ana listenin 1. sayfası okundu. .223 sayfasında 21 üründen 18'i. Rimfire sayfası açılamadı. Test namlusu yayınlanmıyor.
- **Black Hills:** BC ve ürün kodu yayınlanmıyor (null); hız + test namlusu var.
- **Sellier & Bellot:** seri listeleri G1 ve G7'yi etiketli veriyor; test namlusu listede yok (null). Mevcut 7.62x54R FMJ kaydı tekrar eklenmedi.
- **CCI:** .22 LR sayfasında 36 üründen ilk 18'i (sayfalama yok); BC yalnızca Standard Velocity ürün sayfasında. Hunter Series 40 gr LFN'in 1050 fps varyantı (2R40LFN), aynı marka+model+kalibre+ağırlık kuralı nedeniyle eklenmedi.
- **SWISS P:** BC "(ICAO)" etiketli, sürüklenme modeli yok → G1 varsayıldı. .308 AP ve .338 Styx Action sayfalarında başlık/mermi ağırlığı çelişiyor → eklenmedi. LR-1 (sport) = Target (aynı değerler).
- **Sierra:** fabrika fişeği ürün sayfası mermi kataloğuna yönleniyor (seri muhtemelen bırakılmış); değerler ammo kategori sayfasındaki açıklama metninden. Hızı yazılmayan 4 ürün eklenmedi.
- **ELEY:** yalnızca tenex; site hızı aralık veriyor (1040–1085 fps) → kayıtta orta nokta, notta aralık.

### Okunamayan / bırakılan markalar
WebFetch, arama sonuçlarında veya önceden okunan sayfada görünmeyen URL'ler için izin istiyor; zamanlanmış çalıştırmada onaylayan olmadığı için istek düşüyor (PROVENANCE). Üst üste 3 engelde marka bırakıldı:
- **Fiocchi, Prvi Partizan (eksikler), Igman, Wolf, Aguila, Berger, Nosler:** resmi site aramada çıkmadı / doğrudan URL izin zaman aşımı.
- **Hirtenberger, Tula/Barnaul, SK:** aramada resmi ürün/föy sayfası bulunamadı (yalnızca mağazalar; kural gereği kullanılmadı).
- **ZQI:** üretici değil, ABD ithalatçısı (Zenith Quest International); ürünler MKE üretimi → MKE kayıtları yeterli.
- **Kinetic:** bu adla resmi tüfek fişeği üreticisi bulunamadı; sahibin hangi markayı kastettiği netleşmeli.
- **Yavaşçalar / Zuber:** tüfek (yivli) fişeği ürettiğine dair resmi kaynak bulunamadı (av/tabanca fişeği).
- **Lapua rimfire:** zaten 8 kayıt vardı; ek yapılmadı.

## 2026-10-11 (2) — Berger, PPU, Fiocchi, GECO eksikleri

Sahibin ChatGPT araştırması (data/owner-research: docs/owner-research/chatgpt-ammo-1.md) yalnızca ipucu olarak kullanıldı; her değer üreticinin kendi sayfasından/kataloğundan okundu.

| Dosya | Eklenen | Kaynak |
|---|---|---|
| berger.json | +33 (toplam 34) | bergerbullets.com fişek ürün sayfaları (mermi "lines-and-designs" sayfaları değil) |
| ppu.json | +70 (toplam 73) | ppu-usa.com Standard / Metric / Match / Supreme kalibre sayfaları |
| fiocchi.json | +49 (yeni) | fiocchi.com/en ürün sayfaları; Cat. Generale 2024 ile karşılaştırıldı |
| geco.json | +25 (toplam 71) | GECO Magalogue EN 2026 PDF (resmi indirme sayfasında); mevcut 46 tekrar edilmedi |

- **Berger:** sayfalarda G1 ve G7 birlikte var → üretici G7'yi seçer. Test namlusu sayfada yazılı (20/24/26"). 4 sayfada hız yok → eklenmedi: .30-06 168 gr (URL "165gr" diyor) ve 185 gr Classic Hunter, .300 WSM 185 gr Classic Hunter, .338 Norma Mag 300 gr Hybrid OTM. .223 69 gr OTM ve .300 Norma Mag 245 gr LRHT sayfalarında namlu yok (null). 6.5 PRC 153.5 gr: başlık "Hybrid Target", tablo "Elite Hunter".
- **PPU:** sayfalar yalnızca "Ballistic Coeficient" yazıyor, G1/G7 yok → yeni kayıtlarda `g1_bc`/`g7_bc` null, ham değer notta. Mevcut 3 adet 7.62x39 kaydı (G1 varsayımıyla) değiştirilmedi; sahibin kararı. Listedeki ama uygulamanın Kalibre listesinde olmayan kalibreler (6.5x52 Carcano, 6.5x54 MS, 7.5x54 French, 7.65x53, 7.92x33 Kurz, 8x50 R Lebel, 8x56 RS, 6mm Rem) okunmadı.
- **Fiocchi:** ürün sayfalarında "Ballistic coefficient g1" ve (bazı ürünlerde) "G7 Litz" etiketli. Hız "Bocca" = namlu ağzı (m/s → fps). Test namlusu yayınlanmıyor. Katalogdaki Exacta SOLID (70A00x) satırları sitede yok ve PDF metni bozuk okundu → eklenmedi. 2 "SHELL" (boş kovan) ürünü dışarıda.
- **GECO:** katalog BC'si etiketsiz ("BC value = Ballistic coefficient") → yeni 25 kayıtta BC null (ham değer notta). Mevcut 46 kayıt eski kuralla G1 varsayımlı; değiştirilmedi. V0 namlu ağzı. Sahibin verdiği 2024 PDF bağlantısı açılmadı (izin zaman aşımı); resmi indirme sayfasındaki 2026 kataloğu kullanıldı.
- Hız hepsinde namlu ağzında verildi → muzzle_from dönüşümü gerekmedi.

### Güncelleme (sahibin kararı, 2026-10-11)
Sahip, etiketsiz BC'lerin G1 kabul edilmesini onayladı: yeni 70 PPU ve 25 GECO kaydında `g1_bc` = üreticinin yazdığı değer. Her kayıt notunda: "Üretici BC'yi G1/G7 etiketi olmadan veriyor; sahibin kararıyla (2026-10-11) G1 kabul edildi. BC değerinin farklı olduğunu düşünüyorsanız değiştirebilirsiniz." Dayanak: değerlerin büyüklüğü G1 aralığında; PPU Supreme (Sierra mermisi) değerleri Sierra'nın G1 değerleriyle aynı görünüyor.
Sierra teyidi: PPU Supreme (Sierra MatchKing) değerleri 0.301 (#1380 69 gr), 0.462 (#2200 168 gr), 0.587 (#2650 250 gr) Sierra 2025 katalog posteriyle (sierrabullets.com/content/2025-sierra-bullets-catalog-poster.pdf) birebir aynı; Sierra'nın G7 değerleri (0.167 / 0.224 / 0.295) farklı → bu değerler G1.

## 2026-10-11 (3) — fabrika fişeği olmayan kalibreler

Hedef: `lib/data/rifle_library.dart`'ta tüfeği olup `factory_ammo_library.dart`'ta fişeği olmayan
77 kalibre (633 tüfek). Yalnız üretici sayfaları / üretici PDF'leri; bayi sonuçları yalnız URL ipucu.
Hiçbir yaş kapısı onaylanmadı; 429 alınmadı. **+393 kayıt**, 64 kalibre kapandı.

| Dosya | Eklenen | Kaynak |
|---|---|---|
| weatherby.json (yeni) | 94 | weatherby.com güncel balistik tablosu (G1 etiketli; test namlusu yok → null); 15 eski Nosler mermili yük 2021 resmi PDF'ten (26" namlu, BC etiketsiz → G1) |
| hornady.json | +66 | hornady.com ürün sayfaları (BC yayınlanmıyor → null; uygulama BC'yi mermi tablosundan alır); .17 WSM 2022 Hornady balistik tablosu PDF |
| federal.json | +39 | federalpremium.com ürün hattı listeleri (BC etiketsiz → G1; "G7 BC" etiketliler g7) |
| nosler.json | +36 | nosler.com ürün sayfaları (test namlusu var; BC yalnız 1 sayfada) |
| winchester.json | +33 | winchester.com ürün hattı listeleri (BC etiketsiz → G1; rimfire BC yok) |
| norma.json | +33 | norma-ammunition.com (G1 etiketli; namlu "zeroed with 610/660 mm barrel" cümlesinden, notta) |
| barnes.json | +27 | Barnes CFR-Imperial.pdf (SKU satırı; BC etiketsiz → G1) |
| remington.json | +24 | remington.com ürün sayfaları, 2024/2026 katalog |
| cci.json | +10 | cci-ammunition.com (.22 WMR) |
| lapua.json | +8 | lapua.com (G1+G7, test namlusu) |
| rws.json | +6 | rws-ammunition.com (8x68 S; g→gr, m/s→fps, 650 mm namlu) |
| fiocchi.json | +4 | fiocchiusa.com |
| sig_sauer.json (yeni) | 4 | sigsauer.com (.277 SIG Fury, G1) |
| blaser.json (yeni) | 3 | blaser.de "Blaser CDC" balistik PDF (BC etiketsiz → G1) |
| ppu.json | +2 | prvipartizan.com PPU 2023 katalog (6mm Rem) |
| barrett.json (yeni) | 2 | barrett.net (.416 Barrett, .50 BMG; G1+G7) |
| cheytac.json (yeni) | 2 | cheytac.com (.375 / .408 CheyTac; "Velocity" mesafesiz → namlu ağzı sayıldı) |

Dışarıda bırakılanlar: hızı yayınlanmayan ürünler (Hornady 22 CM 65 gr CX, Winchester 6.8 Western
175 gr LR, Remington .300 RUM Core-Lokt Tipped, Nosler 350/400 Legend, 6 NoslerCustom, Barnes Reserve
6.8 Western/.257 Wby/6.5-284); tabanca namlusundan ölçülen savunma yükleri (Hornady 22 WMR Critical
Defense 1.875", Federal 22 WMR Punch 2"); PPU askerî 12.7x99 / 12.7x108 (yalnız V25).

Kontrol edilmesi gerekenler (kayıt notlarında da yazılı):
- Weatherby .240 72 gr Hammer: BC "320 (G1)" ondalıksız basılmış → null.
- Weatherby .416 350 gr TTSX: güncel tablo .444, 2021 PDF .345 → güncel kullanıldı.
- Norma .500 NE 3": 640 m/s ile 2150 f/s uyuşmuyor → 2150 fps yazıldı.
- RWS 8x68 S Driven Hunt BC 0.152 düşük görünüyor; olduğu gibi yazıldı.
- CheyTac .375: sayfa hem .988 hem .980 diyor (.988 alındı); hız "approx.".
- Federal ve Barnes "500 Nitro Express" → `.500 NE 3"` eşlendi.
- Bazı Federal/Remington/Norma yükleri "Currently Unavailable / Discontinued 2026" — veri hâlâ yayında, notta işaretli.

Hâlâ fabrika fişeği bulunamayan 13 kalibre: .338 Blaser Mag, .375 Blaser Mag (Blaser Magnum
hattının veri sayfası yok), 9.3x66 Sako (sako.global listeleri "Show more" arkasında, okunamadı),
6x47 Lapua, 25x47 Lapua (Lapua yalnız kovan), 6 Dasher, 6 BRA, 6mm PPC (yalnız kovan/el dolumu),
.375 EnABELR, 6x62 R Frères, 8x75 RS, 12.7x99 NATO (S&B "2027", MKE ve PPU yalnız V23.7/V25),
12.7x108 (PPU yalnız V25). Kynoch'un resmi sitesi yok (alan adı başka siteye yönleniyor).

## BC tamamlama (2026-10-11)
BC'si boş 341 kayıt yeniden tarandı; 236'sına üretici kaynağından BC yazıldı, 105'i null kaldı. Her kaydın `notes` alanına BC değeri, model, (varsa) hız bantları, kaynak URL ve erişim tarihi eklendi; bulunamayanlara neden yazıldı.
- **Hornady (111/124):** hornady.com/bc (G1+G7, Mach 2.25/2.0/1.75 bantları notta) ve Hornady 2026 katalog tabloları (fabrika "G1 BC" sütunu; diğerlerinde ürün başlığındaki aynı Hornady mermisinin bileşen tablosu). Model etiketsiz sütunlar (SST, InterLock, V-MAX, FTX…) G1 kabul edildi. Bulunamayan 13: rimfire (yayımlanmıyor), .338 ARC 4, American Gunner 2, 400 Legend InterLock, 25 CM 112 CX ("TBD").
- **Nosler (35/36):** Nosler bileşen mermi sayfaları (ürün adı aynı mermiyi veriyor); 3 kayıt 2021 katalogdan (etiketsiz → G1). .222 Rem Mag 50gr FBHP: aynı mermi Nosler'de yok.
- **Black Hills (32/88):** black-hills.com BC yayımlamıyor; BC yalnızca Black Hills'in adını verdiği mermi üreticisinden (Barnes yükleme PDF'leri, hornady.com/bc). Mermi adı verilmeyen 20 kayıt null; Sierra (10) ve Hornady CX/SST/V-MAX/GMX/Match HP (25) sayfaları BC'yi betikle yüklediği için erişilemedi.
- **CCI (20/20), Federal (18/19):** her ürünün kendi sayfasındaki "Ballistic Coefficient" satırı (etiketsiz → G1). Federal Small Game #12 shot: "N/A".
- **Winchester (18/33):** Winchester 2026 kataloğu (winchester.com'dan bağlı resmi flipbook) "B.C." sütunu, etiketsiz → G1. Satır eşleşmesi kesin olmayan 15 kayıt null bırakıldı (tahmin yazılmadı).
- **Lapua (1/5):** 7.62x39 FMJ → katalogdaki S405 mermi kodu ve Lapua S405 sayfası. **Norma (1/2):** Oryx 8,5x55 Blaser 230 gr → Norma Oryx .338 230 gr bileşen sayfası.
- Null kalanlar: Geco 3, RWS 1, SWISS P 2 (föy PDF robots.txt ile kapalı), Weatherby 1 (sayfada "320 (G1)" ondalık noktası yok — düzeltme tahmin olacağından yazılmadı), MKE 7 (MKE BC yayımlamıyor).

## BC tamamlama 3 (2026-10-12)
Uygulamada BC'si boş kalan fabrika fişekleri yeniden tarandı (yalnız fişek üreticisinin veya
fişeğin adını verdiği mermi üreticisinin resmi sitesi). Her yeni değerde kaynak URL ve erişim
tarihi kayıt notunda; bulunamayanlara "BC araması 3" nedeni eklendi. Tahmin yok.
- **Black Hills (5):** fişek sayfasının adını verdiği Hornady V-MAX (.224 40/50/60 gr, 6mm 58 gr) —
  Hornady 2026 katalog V-MAX tablosu (https://static.hornady.media/site/hflipbook/inc/html/92.html);
  etiketsiz → G1 kabul edildi. Hornady GMX 70, CX 125 .308, "Match Hollow Point" 168 bulunamadı/belirsiz.
- **Geco (1):** GECO STAR .270 Win 8,4 g → GECO 2026 katalog 'BALLISTIC DATA' BC 0,227
  (etiketsiz → G1; katalogdaki 300 m hızı G1 ile uyumlu, G7 ile değil).
- Null kalanlar: Hornady 9 (rimfire, .338 ARC, American Gunner, 400 Legend, 25 CM CX "TBD"),
  Winchester 15 (flipbook metninde sembol–BC eşleşmesi kanıtlanamadı), Lapua 3, Geco 2 (.22 LR),
  SWISS P 2, Norma 1, Nosler 1, Weatherby 1 ("320 (G1)" ondalıksız), RWS 1, Federal 1 (saçma).
- Aguila kayıtları bu dalda değil, uygulama deposunda (data/muhimmat/ammo/aguila.json): 8 av
  fişeği Aguila'nın 'Ballistic Information' PDF'inden (G1 etiketli).
