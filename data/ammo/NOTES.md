# Fabrika fişek verisi — notlar (2026-10-10)

Kaynak kuralı: değerler yalnızca üreticinin kendi sitesinden / PDF kataloğundan okundu. Okunmayan değer yazılmadı (BC yoksa `null`); hızı olmayan kayıt yok. Hiçbir yaş onayı kutusu onaylanmadı.

## Sayılar (toplam 642)

| Dosya | Kayıt |
|---|---|
| federal.json | 196 |
| winchester.json | 117 |
| norma.json | 111 |
| hornady.json | 58 |
| lapua.json | 58 |
| geco.json | 46 |
| sako.json | 30 |
| barnes.json | 20 |
| ppu.json | 3 |
| berger.json | 1 |
| nosler.json | 1 |
| sellier_bellot.json | 1 |
| remington / rws / mke | 0 (dosya yok) |

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
