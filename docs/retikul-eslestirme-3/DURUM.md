# Retikül eşleştirme 3 — çalışma durumu (2026-10-12)

Başlangıç: main bc88399, `python3 tools/reticle_match_audit.py`.

## Kaynak kuralı
Yalnız dürbün kaydının `sourceDocument` alan adındaki üretici sayfası/PDF'i
(ve aynı alan adının alt alan adları). Bayi, forum, blog, balistik yazılım
verisi kullanılmaz. Üretici vermediyse alan null.

## Delta Optical
`https://www.deltaoptical.pl/` 2026-10-12'de bir kez daha denendi:
WebFetch `ROBOTS_DISALLOWED` (site robots.txt ile otomatik okumayı
yasaklıyor); bulut ortamında doğrudan bağlantı (curl) vekil sunucuda
`CONNECT 403`. Dolaylı yol denenmedi. Titanium ve Classic retikülleri
eklenmedi.

## Başlangıç tablosu
| Marka | toplam | eslesti | cizilir | eslesmedi | kismi | retikul-yok | kayit-yok | baska-marka | birim-farki | belirsiz |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Arken Optics | 15 | 15 | 7 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Athlon | 146 | 75 | 72 | 71 | 0 | 5 | 61 | 4 | 1 | 0 |
| Barska | 56 | 0 | 0 | 56 | 0 | 0 | 33 | 23 | 0 | 0 |
| Burris | 39 | 8 | 6 | 31 | 5 | 0 | 46 | 1 | 0 | 0 |
| Bushnell | 21 | 1 | 0 | 20 | 1 | 0 | 26 | 1 | 0 | 0 |
| Delta Optical | 8 | 0 | 0 | 8 | 0 | 0 | 17 | 0 | 0 | 0 |
| Discovery Optics | 35 | 0 | 0 | 35 | 0 | 35 | 0 | 0 | 0 | 0 |
| Element Optics | 30 | 29 | 24 | 1 | 0 | 0 | 1 | 0 | 0 | 0 |
| GPO | 11 | 0 | 0 | 11 | 0 | 0 | 13 | 0 | 0 | 0 |
| Gamo | 11 | 0 | 0 | 11 | 0 | 1 | 7 | 3 | 0 | 0 |
| Gazi Sniper | 2 | 0 | 0 | 2 | 0 | 2 | 0 | 0 | 0 | 0 |
| Hawke | 97 | 6 | 2 | 91 | 0 | 0 | 97 | 18 | 4 | 5 |
| Integrix | 7 | 0 | 0 | 7 | 0 | 0 | 7 | 0 | 0 | 0 |
| Kahles | 15 | 2 | 0 | 13 | 0 | 13 | 0 | 0 | 0 | 0 |
| Konus | 37 | 0 | 0 | 37 | 0 | 1 | 31 | 5 | 0 | 0 |
| Leupold | 63 | 25 | 25 | 38 | 20 | 0 | 48 | 0 | 4 | 0 |
| MTC Optics | 18 | 0 | 0 | 18 | 0 | 0 | 19 | 0 | 0 | 0 |
| Meopta | 16 | 0 | 0 | 16 | 0 | 5 | 17 | 0 | 0 | 0 |
| MewLite | 8 | 0 | 0 | 8 | 0 | 8 | 0 | 0 | 0 | 0 |
| Nightforce | 57 | 35 | 20 | 22 | 15 | 0 | 2 | 0 | 0 | 20 |
| Nikko Stirling | 71 | 0 | 0 | 71 | 0 | 0 | 71 | 1 | 0 | 0 |
| Primary Arms | 12 | 3 | 3 | 9 | 3 | 0 | 14 | 0 | 1 | 0 |
| Schmidt & Bender | 19 | 0 | 0 | 19 | 0 | 0 | 38 | 5 | 0 | 0 |
| Sig Sauer | 21 | 0 | 0 | 21 | 0 | 3 | 25 | 0 | 0 | 0 |
| Sightmark | 16 | 9 | 7 | 7 | 1 | 0 | 8 | 0 | 0 | 0 |
| Sightron | 40 | 0 | 0 | 40 | 0 | 0 | 47 | 8 | 0 | 0 |
| Steiner | 40 | 0 | 0 | 40 | 0 | 0 | 32 | 10 | 2 | 0 |
| Swarovski | 24 | 0 | 0 | 24 | 0 | 0 | 38 | 13 | 0 | 0 |
| UTG | 15 | 0 | 0 | 15 | 0 | 0 | 15 | 0 | 0 | 0 |
| Vector Optics | 145 | 103 | 49 | 42 | 0 | 2 | 30 | 1 | 9 | 0 |
| Vortex | 85 | 85 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| Zeiss | 29 | 17 | 15 | 12 | 5 | 0 | 19 | 0 | 7 | 0 |
| **Toplam** | 1209 | 413 | 230 | 796 | 50 | 75 | 762 | 93 | 28 | 25 |
