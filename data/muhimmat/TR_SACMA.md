# Türkiye'de satılan PCP saçma/slug — resmi kaynak taraması (2026-10-12)

Görev: Türkiye'de satılan PCP saçma ve slug'ları `lib/data/bullet_library.dart` (PCP) kütüphanesine
eklemek. Değerler yalnız her markanın kendi resmi sitesinden; satıcı sitelerinden yalnız marka/model adı
(ipucu) alındı. Durum: çalışma sürüyor.

## İpucu kaynakları (değer kaynağı değil)

- https://www.izmiravmarket.com/kategori/pellet-sacma — robots.txt `/kategori/*?*` (sayfalama dahil
  sorgulu kategori adresleri) yasak; yalnız 1. sayfa, marka site haritası ve JSB marka sayfası okundu.
  Hatsan, Skypellets, Shock, Hunthink marka sayfaları HTTP 429 (proxy) verdi; tekrar denenmedi.
- https://www.hatsanstore.com/635-mm-pelletler-pmk34 — okunamadı (sunucu hatası).
