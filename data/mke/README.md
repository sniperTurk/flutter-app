# MKE tüfek ve tüfek fişeği verisi

Kaynak: yalnızca mke.gov.tr ürün sayfaları ve MKE katalog PDF'leri
(01 Small Arms, 02 Precision Rifles, 03 Small Arms Ammunition). Toplama: 2026-10-10.

Kararlar:
- `bullet_diameter_mm` / `bullet_diameter_in`: MKE hiçbir üründe mermi çapı yayınlamıyor → null.
- `twist_rate_in`: Yalnızca KANS 308 (sayfa, "1/12"), KNT-76 ve Bora-12 (katalog 1/12") ve KNT-859 (katalog 1/10") için var.
  "Yiv Set Sayısı" yiv adedidir, hatve değildir.
- `twist_direction`: Katalogdaki "Groove N (Right)" satırlarından.
- `overall_length_mm`: İki değer varsa dipçik açık / uzun değer.
- Fişek hızları MKE'de çoğunlukla 23.7 m'de ölçülür (namlu ağzı değil); değer `muzzle_velocity_fps`'e çevrilip not düşüldü.
  `test_barrel` hiçbir üründe yayınlanmıyor.
- G7 BC hiçbir üründe yok. G1 BC yalnızca SS109, 5.56 izli, M80, M61, M62 sayfalarında var.
- Ürün sayfası ile katalog çeliştiğinde ürün sayfası esas alındı; fark `notes`'ta.
- Erişilemeyen sayfalar (G3, T-50, Kaan 717, TLS-571, HK33 /15) → katalog kullanıldı. TLS-571 ve MPT-55C/M/K1/K2
  katalog blokları modele güvenle eşlenemediği için alınmadı.
- Kapsam dışı: tabanca/MP5/AP5/T-94, 5.7×28, 9 mm vb. tabanca fişekleri, 20 mm ve üstü, büzmeli (manevra) fişekler,
  bombaatar, top, havan, döner namlulu sistemler.
