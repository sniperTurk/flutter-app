# Mühimmat tamamlama — notlar (2026-10-12)

Kaynak kuralı: değerler yalnızca üreticinin kendi resmi sitesinden / kataloğundan / teknik föyünden
okundu. Bayi, mağaza, forum, blog kullanılmadı; ChairGun, Strelok, Applied Ballistics, QuickLOAD, GRT,
JBM verisi kopyalanmadı. Bulunamayan değer `null`; nedeni kaydın `notes` alanında. Her kaydın
`source_url` alanı değerin okunduğu sayfa/PDF'tir. Erişim yalnız WebFetch/WebSearch; bir sayfa
okunamadıysa başka yolla (curl, arşiv, ayna) çekilmedi.

Mevcut durumun dökümü: [ENVANTER.md](ENVANTER.md).

BC işi: ayrı görev (feat/bc-tamamlama, data/ammo-bc, data/bullets-bc, data/mke-bc; PR #157–#161)
mevcut kayıtların BC'lerini tamamladı ve main'e alındı. Burada mevcut kayıtların BC'sine
dokunulmadı; BC yalnızca yeni eklenen kayıtlar için, üretici yayımlıyorsa yazıldı.

## Dosyalar

| Dosya | Şema | Kayıt | BC'li | Not |
|---|---|---|---|---|
| ammo/pmc.json | data/ammo | 11 | 11 (etiketsiz → G1) | 3 kayıtta test namlusu belirsiz (sayfada 16 ve 24 in birlikte) |
| ammo/magtech.json | data/ammo | 35 | 35 (etiketsiz → G1) | 2026 kataloğu; bazı BC'ler G1 için olağandışı düşük (ör. .308 168 gr HPBT 0,246) — katalog ve ürün sayfasında böyle; değiştirilmedi |
| ammo/aguila.json | data/ammo | 31 | 0 | Aguila BC ve test namlusu yayımlamıyor |
| bullets-firearm/cutting_edge.json | data/bullets-firearm | 156 | 71 | 2026 Teknik Föy (PDF). '(A.B.)' etiketli BC'ler kullanılmadı (aşağıda); uygulamaya yalnız BC'li 71 kayıt girer |
| bullets-firearm/hammer.json | data/bullets-firearm | 16 | 16 | Ürün sayfaları; BC'ler üreticinin "estimated" / "calculated from shot drops" değerleri |
| bullets-pcp/spoton.json | data/bullets-pcp | 30 | 0 | Türk üretici (Mersin); BC, uzunluk, kafa çapı yayımlanmıyor |

## Üretici seçimi ve nedeni

Öncelik: Türkiye'de üretilen → Türkiye'de satılan → dünyada yaygın.

| Üretici | Ülke | Neden seçildi | Sonuç |
|---|---|---|---|
| Spoton | TR | Türkiye'de üretim (2011, Mersin) PCP saçma | 30 kayıt |
| Hatsan | TR | Türkiye'de üretim (İzmir) PCP saçma/slug | Ürünlerin hepsi data/bullets-pcp'de zaten var (15) — yeni kayıt yok; BC'siz oldukları için uygulamada görünmüyorlardı → uygulama PR'ı bunları da listeye alıyor |
| My Bullet | TR | Türk slug üreticisi | Aynı durum: 7 ürün data/bullets-pcp'de var, yeni ürün yok |
| MKE | TR | Devlet mühimmat üreticisi | mke.gov.tr/Urunler HTTP 429 (proxy); sivil/av fişeği kontrol edilemedi |
| ZSR Patlayıcı | TR | Türkiye'de tüfek fişeği üretimi (5.56 / 7.62) | zsr.com.tr HTTP 429; okunamadı |
| Yavaşçalar (YAF) | TR | Türk fişek üreticisi | yaf.com.tr HTTP 429; okunamadı (tabanca fişeği ağırlıklı) |
| Sarsılmaz | TR | Türk silah/mühimmat | Mühimmat sayfası bulunamadı |
| Turaç, Özkursan, Arsan, Atak | TR | Türk fişek üreticileri (av fişeği ağırlıklı) | Proxy 429 sürdüğü için denenemedi |
| İnce Mehmet, EB Solid, Shock Slugs, Beta Solid / Hawk Slug | TR | Türk slug markaları | Resmi site bulunamadı; tahmin edilen alan adları robots.txt ile kapalı ve sahipliği doğrulanamadı |
| Kral Arms / Öztay | TR | Türk PCP üreticisi | Resmi sitede saçma/slug ürünü yok; oztay.com.tr ilgisiz siteye yönleniyor |
| PMC (Poongsan) | KR/US | Dünyada yaygın tüfek fişeği | 11 kayıt |
| Magtech (CBC) | BR | Dünyada yaygın; S&B ile aynı grup | 35 kayıt |
| Aguila | MX | Dünyada yaygın (rimfire dahil) | 31 kayıt |
| Hirtenberger | AT | Türkiye'de satılan Avrupa markası | hirtenberger-ammo.com robots.txt ile otomatik erişime kapalı |
| Igman, Browning, Barnaul, Armscor, Underwood, Lehigh Defense | – | Dünyada yaygın | HTTP 429 (proxy); okunamadı |
| Tula/Wolf, Mesko, Norinco, Brenneke, Hevi-Shot, Steyr | – | Dünyada yaygın | Proxy 429 sürdüğü için denenemedi. Nammo'nun sivil tüfek fişeği Lapua/Norma/Sako markalarıyla zaten listede |
| Cutting Edge Bullets | US | Monolitik çekirdek; teknik föyü BC veriyor | 156 kayıt |
| Hammer Bullets | US | Monolitik av çekirdeği | 16 kayıt (yaklaşık 280 ürün sayfası daha var; 429 nedeniyle okunamadı) |
| Badlands, GS Custom, PPU (çekirdek), Matrix | – | Çekirdek üreticisi | 429 / denenemedi |
| JSB, FX, Air Venturi, Daystate | CZ/SE/US/GB | Dünyada en yaygın PCP saçma/slug | HTTP 429 (proxy); JSB siteleri önceki çalıştırmada robots.txt ile kapalıydı |
| Altaros, Griffin, Wildman, Predator Polymag, Gamo, Apolo, COAL, Snowpeak, QYS | – | PCP saçma/slug | Proxy 429 sürdüğü için denenemedi |

## Verilen kararlar

- **Applied Ballistics BC'leri:** Cutting Edge föyü bazı BC'leri "(A.B.)" etiketiyle veriyor (Applied
  Ballistics LLC ölçümü). Görev kuralı Applied Ballistics verisini yasakladığı için bu değerler
  yazılmadı. Aynı satırda Oehler 89 ölçümü varsa (üreticinin kendi ölçümü) o kullanıldı; A.B. etiketi
  92 kayıtta var; bunların 77'sinde başka değer olmadığı için BC boş (7 kayıtta föyde zaten BC yok/TBD → toplam 85 BC'siz). Ham değerler `notes` alanında duruyor.
- **Cutting Edge G7:** Ham metin yalnız G1 veriyorsa G7 yazılmadı (kaynağı belirsiz).
- **Etiketsiz BC:** PMC ve Magtech BC'nin sürükleme modelini yazmıyor → sahip kuralıyla G1; uygulama
  BC ⓘ notunda bunu söylüyor.
- **Spoton türü:** Sayfalar yalnız "havalı tüfek mermisi" diyor; hepsi `pellet` yazıldı. "Çap" alanında
  iki değer (ör. "5,50 / 5,52 MM") olduğunda hangisinin kafa çapı olduğu belirsiz → `head_size_mm` boş.
- **Hatsan .62 slug'lar** (15,75 mm) PCP kalibre listesinde olmadığından listeye alınmaz.
- **Ad yazımı:** Magtech ürün adlarında "55gr" → "55 gr" (liste etiketi biçimi); değer değişmedi.
- **Askerî zırh delici (M855 / green tip "LAP")** kayıtları alınmadı.

## Mevcut kayıtlarda boş kalan (BC dışı) alanlar

- **Test namlu boyu:** Federal ve Winchester yayımlamıyor (data/ammo NOTES). Remington, CCI, Fiocchi,
  PPU, Sako, Weatherby, S&B için ürün sayfaları/kataloglar bu çalıştırmada proxy 429 nedeniyle
  yeniden okunamadı; değer yazılmadı.
- **Mermi uzunluğu (Hornady, Sierra, Speer, Swift, Peregrine, RWS):** aynı nedenle yeniden okunamadı.
- **PCP BC'leri (RWS, Air Arms, Crosman, Hatsan, My Bullet, FX):** üretici yayımlamıyor (data/bullets-pcp
  NOTLAR, 2026-10-11 taraması). Uygulama PR'ı bu kayıtları BC'siz olarak listeye alır; BC kutusu boş
  gelir, ⓘ notu "üretici BC yayımlamıyor" der.

## Sonraki çalıştırma için

Proxy sınırı kalkınca sırayla (paralel değil): ZSR, MKE (sivil ürünler), JSB, FX, Air Venturi,
Daystate, Igman, Browning, Hammer'ın kalan sayfaları, Lehigh; ardından test namlusu (Remington,
Fiocchi, PPU, Sako, Weatherby) ve mermi uzunluğu (Sierra, Hornady, Speer).
