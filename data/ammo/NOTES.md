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
