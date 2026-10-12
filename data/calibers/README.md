# Kalibre verisi (data/kalibre-tamamlama, 2026-10-11)

`cartridge_specs.json`: her kalibre için standart ölçüler ve kaynak URL'leri.
`cip_tdcc_index.json`: C.I.P. TDCC açık listesinin tamamı (672 satır; ad, sekme, föy URL'si, Pmax).

## 1. Envanter (önceki durum)

Uygulamadaki kalibre şeması yalnızca **ad + mermi çapı (mm)** idi (`Cartridges.firearm`,
`Cartridges.pcp`). 145 ateşli ve 8 PCP kalibresinin hepsinde çap doluydu; kovan boyu,
toplam fişek boyu, maks. basınç, yiv oranı ve çekirdek ağırlığı alanları **şemada hiç yoktu**
(yani 145/145 boş). Bu dal bu alanları ayrı bir kayıtta (`cartridge_specs.json`) ekler;
mevcut ad ve çap değerleri değiştirilmedi.

## 2. Listelerde kullanılıp kalibre listesinde olmayanlar

Üretici (generate_profile_lists.py, "skipped"):
- `8x57 JR` — Sellier & Bellot fabrika fişeği (eklendi; C.I.P. "8 x 57 IR", föyde "8 x 57 JR")
- `10.3x60 R` — Blaser R8 / K95 tüfekleri (eklendi; C.I.P. Tab II)
- PCP `11.60 mm` — Kral Arms Magestic (eklendi: `11.60 mm (.45)`, Kral'ın resmî sayfası)
- PCP `.62` — Hatsan PileDriver: **eklenmedi**; Hatsan'ın hiçbir resmî sayfası .62 için birimli mm çap vermiyor (TR sayfasında yalnızca birimsiz "15,8" başlığı var), uydurmamak için boş bırakıldı.

Çekirdek kütüphanesi kalibre adıyla değil çapla bağlı; eksik ad yok.

## 3. Kendi seçtiğim yeni kalibreler (neden)

| Kalibre | Neden |
|---|---|
| 5.45x39 | AK-74 ailesi; Türkiye'de ithal/askerî fazlası tüfeklerde yaygın |
| 7.65x53 Arg | Osmanlı/Türk Mauser 1890/1893 fişeği; Türkiye'de tarihî tüfeklerde hâlâ kullanılıyor |
| 7mm WSM, 7mm Rem SAUM, .300 Rem SAUM | PRS/uzun menzil hassas atışta yaygın kısa magnumlar |
| 7mm RUM | .300 RUM listede vardı; aynı ailenin uzun menzil 7 mm'si |
| .284 Win | F-Class ve uzun menzil hedef atışının klasik fişeği |
| .300 H&H Mag | Avrupa/Türkiye büyük av tüfeklerinde klasik |
| .300 Savage | Kaldıraçlı/av tüfeklerinde yaygın, C.I.P. standardı var |

Hepsi C.I.P. TDCC'de kayıtlı; mermi çapı C.I.P. föyündeki Z (yiv dibi çapı) değeridir
(uygulamadaki mevcut kuralla aynı: .308 Win → 7.82).

## 4. Doluluk (ateşli, 156 kalibre)

| Alan | Dolu |
|---|---|
| Mermi çapı mm / inç | 156 / 156 (inç = mm / 25,4) |
| Kovan boyu (C.I.P. L3 / SAAMI) | 144 |
| Maks. fişek boyu (C.I.P. L6 / SAAMI COL) | 141 |
| Pmax (C.I.P., bar) | 137 |
| MAP (SAAMI, psi) | 13 |
| Yiv adımı (C.I.P. u / SAAMI / üretici) | 145 |
| Yiv dibi çapı Z, bore F, yiv sayısı N | 136 |
| Çekirdek ağırlık aralığı (SAAMI referans yük) | 4 (diğerleri uygulamada fabrika fişeği listesinden türetilir) |

## 5. Bulunamayanlar ve nedenleri

- **7.62x51 NATO, 5.56x45 NATO, 12.7x99 NATO**: NATO STANAG belgeleri kamuya açık değil; C.I.P./SAAMI'de bu adla yok.
- **25x47 Lapua, 6x47 Lapua, 6 BRA, .375 EnABELR**: wildcat/özel fişekler; C.I.P., SAAMI veya üretici resmî föyü yok (.375 EnABELR için yalnızca Applied Ballistics sayfası var; kural gereği kullanılmadı).
- **.22 Creedmoor, .277 SIG Fury**: SAAMI duyurusundan yalnızca MAP alındı; SAAMI çizim PDF'i iki denemede de açılmadı.
- **.280 Ackley Improved, .416 Weatherby Mag**: yalnızca üretici yiv adımı (Nosler test namlusu / Weatherby tüfek föyü); SAAMI tablosu okunamadı.
- **6.5 Grendel**: C.I.P. föyünün metni etiketlerden ayrık çıktı; yalnızca listedeki Pmax (4050 bar) alındı.
- **SAAMI Z299.4 (merkez ateşli tüfek, 2025)**: PDF, erişim aracı tarafından 8. sayfada kesiliyor; basınç/hız tablosu (s. 11–28) ve test namlusu föyleri okunamadı. Bu yüzden MAP (psi) yalnızca rimfire ve SAAMI'nin ayrı yayımladığı yeni fişek çizimlerinde var.
- **Çekirdek ağırlık aralığı**: C.I.P. föylerinde yok; SAAMI yalnızca rimfire tablosundan okundu.
- **Ağ kısıtı**: oturumun kabuk ağı saami.org ve cip-bobp.org'a kapalıydı; tüm değerler WebFetch ile föylerden okundu. 6,5 Creedmoor ve 6 mm PPC föyleri elle ikinci kez kontrol edildi.

## 6. Dikkat (değiştirilmedi, sahibin kararı)

- `6.5x52 R`: C.I.P. föyü Z 6.55 / G1 6.58 mm; uygulamada 6.71 mm (bu fişek .25-35 Win karşılığı, 6,53 mm sınıfı mermi kullanır).
- `9.3x72 R`: C.I.P. G1 9.57 mm; uygulamada 9.30.
- `6mm PPC`: C.I.P. föyündeki referans yiv adımı u = 551 mm (1:21,7"); föyde böyle yazıyor, aynen alındı.
- `.22 LR`: C.I.P. Z 5.58 mm, G1 5.72 mm; uygulamada 5.69.

## 7. Kaynaklar

- C.I.P. TDCC açık listesi: https://bobp.cip-bobp.org/en/tdcc_public (her kalibrenin föy URL'si `sources` alanında)
- ANSI/SAAMI Z299.1 Rimfire (2026): https://saami.org/wp-content/uploads/2026/05/SAAMI-Z299.1-R2026-Rimfire-FINAL-Approved-2026-05-08.pdf
- SAAMI cartridge & chamber drawings: https://saami.org/technical-information/cartridge-chamber-drawings/
- Üretici: weatherby.com, nosler.com, hatsan.com.tr, hatsanairgunsusa.com, kralarms.com, hn-sport.de, umarexusa.com (kayıt başına `sources`)

## 8. Tam tablo

| Kalibre | Çap mm | Çap in | Kovan mm | Maks. fişek mm | Pmax bar | MAP psi | Yiv 1:in | Çekirdek gr | Standart |
|---|---|---|---|---|---|---|---|---|---|
| .308 Win | 7.82 | 0.3079 | 51.18 | 71.12 | 4150 |  | 12.01 |  | C.I.P. |
| 7.62x51 NATO | 7.82 | 0.3079 |  |  |  |  |  |  | — |
| 6.5 Creedmoor | 6.71 | 0.2642 | 48.77 | 71.76 | 4350 |  | 7.99 |  | C.I.P. |
| .223 Rem | 5.7 | 0.2244 | 44.7 | 57.4 | 4300 |  | 12.01 |  | C.I.P. |
| 5.56x45 NATO | 5.7 | 0.2244 |  |  |  |  |  |  | — |
| .30-06 Springfield | 7.82 | 0.3079 | 63.35 | 84.84 | 4050 |  | 10 |  | C.I.P. |
| 7.62x39 | 7.92 | 0.3118 | 38.7 | 56 | 3550 |  | 9.45 |  | C.I.P. |
| .300 Win Mag | 7.82 | 0.3079 | 66.55 | 84.84 | 4300 |  | 10 |  | C.I.P. |
| .338 Lapua Mag | 8.59 | 0.3382 | 69.2 | 93.5 | 4200 |  | 10 |  | C.I.P. |
| .22 LR | 5.69 | 0.224 | 15.57 | 25.4 | 1700 | 24000 | 15.98 | 25–42 | C.I.P. |
| 12.7x108 | 12.98 | 0.511 | 108 | 147 | 3050 |  | 14.96 |  | C.I.P. |
| 12.7x99 NATO | 12.95 | 0.5098 |  |  |  |  |  |  | — |
| .17 HMR | 4.37 | 0.172 | 27.03 | 34.67 | 1800 | 26000 | 9.02 | 15.5–20 | C.I.P. |
| .17 Hornet | 4.37 | 0.172 | 34.29 | 43.69 | 3700 |  | 8.98 |  | C.I.P. |
| .17 WSM | 4.37 | 0.172 | 30.48 | 40.39 | 2200 | 33000 | 9.02 | 20–25 | C.I.P. |
| .204 Ruger | 5.18 | 0.2039 | 46.99 | 57.4 | 4050 |  | 12.01 |  | C.I.P. |
| .22 ARC | 5.7 | 0.2244 | 38.74 | 57.4 | 4050 |  | 7 |  | C.I.P. |
| .22 Creedmoor | 5.7 | 0.2244 |  |  |  | 62000 |  |  | SAAMI |
| .22 Hornet | 5.69 | 0.224 | 35.64 | 43.76 | 3000 |  | 15.98 |  | C.I.P. |
| .22 WMR | 5.69 | 0.224 | 26.8 | 34.29 | 1600 | 24000 | 15.98 | 28–50 | C.I.P. |
| .22-250 Rem | 5.7 | 0.2244 | 48.46 | 59.69 | 4050 |  | 14.02 |  | C.I.P. |
| .222 Rem | 5.7 | 0.2244 | 43.18 | 54.1 | 3700 |  | 14.02 |  | C.I.P. |
| .222 Rem Mag | 5.7 | 0.2244 | 46.99 | 57.91 | 4050 |  | 14.02 |  | C.I.P. |
| .224 Valkyrie | 5.7 | 0.2244 | 40.64 | 57.4 | 3890 |  | 7 |  | C.I.P. |
| .240 Weatherby Mag | 6.17 | 0.2429 | 63.5 | 78.74 | 4400 |  | 10 |  | C.I.P. |
| .243 Win | 6.17 | 0.2429 | 51.94 | 68.83 | 4150 |  | 10 |  | C.I.P. |
| .25 Creedmoor | 6.53 | 0.2571 | 48.77 | 71.76 |  | 62000 | 7.5 |  | SAAMI |
| .25 Weatherby RPM | 6.53 | 0.2571 | 60.96 | 84.84 |  | 65000 | 7.5 |  | SAAMI |
| .25-06 Rem | 6.53 | 0.2571 | 63.35 | 82.55 | 4400 |  | 10 |  | C.I.P. |
| .257 Roberts | 6.53 | 0.2571 | 56.72 | 70.49 | 3550 |  | 10 |  | C.I.P. |
| .257 Weatherby Mag | 6.53 | 0.2571 | 64.74 | 81.51 | 4400 |  | 10 |  | C.I.P. |
| 25x47 Lapua | 6.53 | 0.2571 |  |  |  |  |  |  | — |
| .260 Rem | 6.71 | 0.2642 | 51.69 | 71.12 | 4150 |  | 9.02 |  | C.I.P. |
| .264 Win Mag | 6.71 | 0.2642 | 63.5 | 84.84 | 4300 |  | 9.02 |  | C.I.P. |
| .270 Weatherby Mag | 7.04 | 0.2772 | 64.74 | 83.69 | 4400 |  | 10 |  | C.I.P. |
| .270 Win | 7.04 | 0.2772 | 64.52 | 84.84 | 4300 |  | 10 |  | C.I.P. |
| .270 WSM | 7.04 | 0.2772 | 53.34 | 72.64 | 4400 |  | 10 |  | C.I.P. |
| .277 SIG Fury | 7.04 | 0.2772 |  |  |  | 80000 |  |  | SAAMI |
| .28 Nosler | 7.21 | 0.2839 | 65.79 | 84.84 | 4400 |  | 9 |  | C.I.P. |
| .280 Ackley Improved | 7.21 | 0.2839 |  |  |  |  | 9 |  | SAAMI |
| .280 Rem | 7.21 | 0.2839 | 64.52 | 84.58 | 4050 |  | 10 |  | C.I.P. |
| .30 Carbine | 7.82 | 0.3079 | 32.77 | 42.67 | 3200 |  | 20 |  | C.I.P. |
| .30 R Blaser | 7.82 | 0.3079 | 68 | 95 | 4050 |  | 12.01 |  | C.I.P. |
| .30-30 Win | 7.82 | 0.3079 | 51.8 | 64.77 | 3200 |  | 12.01 |  | C.I.P. |
| .30-378 Weatherby Mag | 7.82 | 0.3079 | 73.99 | 95.25 | 4400 |  | 10 |  | C.I.P. |
| .300 Blackout | 7.82 | 0.3079 | 34.75 | 57.4 | 3900 |  | 8 |  | C.I.P. |
| .300 Blaser Mag | 7.82 | 0.3079 | 64.2 | 84.84 | 4200 |  | 11 |  | C.I.P. |
| .300 Norma Mag | 7.82 | 0.3079 | 63.3 | 93.5 | 4400 |  | 9.02 |  | C.I.P. |
| .300 PRC | 7.82 | 0.3079 | 65.53 | 93.98 | 4400 |  | 8.5 |  | C.I.P. |
| .300 RUM | 7.82 | 0.3079 | 72.39 | 91.44 | 4400 |  | 10 |  | C.I.P. |
| .300 Weatherby Mag | 7.82 | 0.3079 | 71.75 | 90.42 | 4400 |  | 10 |  | C.I.P. |
| .300 WSM | 7.82 | 0.3079 | 53.34 | 72.64 | 4400 |  | 10 |  | C.I.P. |
| .303 British | 7.92 | 0.3118 | 56.44 | 78.11 | 3650 |  | 10 |  | C.I.P. |
| .338 ARC | 8.59 | 0.3382 | 33.02 | 57.4 | 4050 |  | 8 |  | C.I.P. |
| .338 Blaser Mag | 8.59 | 0.3382 | 63.7 | 84.84 | 4200 |  | 12 |  | C.I.P. |
| .338 Federal | 8.59 | 0.3382 | 51.18 | 71.63 | 4150 |  | 10 |  | C.I.P. |
| .338 Norma Mag | 8.59 | 0.3382 | 63.3 | 93.5 | 4400 |  | 9.25 |  | C.I.P. |
| .338 Weatherby RPM | 8.59 | 0.3382 | 65.278 |  |  | 65000 |  |  | SAAMI |
| .338 Win Mag | 8.59 | 0.3382 | 63.5 | 84.84 | 4300 |  | 10 |  | C.I.P. |
| .338-378 Weatherby Mag | 8.59 | 0.3382 | 73.99 | 95.58 | 4400 |  | 10 |  | C.I.P. |
| .340 Weatherby Mag | 8.59 | 0.3382 | 71.76 | 93.35 | 4400 |  | 10 |  | C.I.P. |
| .35 Whelen | 9.09 | 0.3579 | 63.35 | 84.84 | 4000 |  | 16 |  | C.I.P. |
| .350 Legend | 9.02 | 0.3551 | 43.43 | 57.4 | 4300 |  | 16 |  | C.I.P. |
| .358 Win | 9.09 | 0.3579 | 51.18 | 70.61 | 4050 |  | 12.01 |  | C.I.P. |
| .375 Blaser Mag | 9.53 | 0.3752 | 71.7 | 92 | 4200 |  | 14 |  | C.I.P. |
| .375 CheyTac | 9.53 | 0.3752 | 76.91 | 113.4 | 4400 |  | 13 |  | C.I.P. |
| .375 EnABELR | 9.53 | 0.3752 |  |  |  |  |  |  | — |
| .375 H&H Mag | 9.53 | 0.3752 | 72.39 | 91.44 | 4300 |  | 12.01 |  | C.I.P. |
| .375 Ruger | 9.53 | 0.3752 | 65.53 | 84.84 | 4275 |  | 12.01 |  | C.I.P. |
| .375 Swiss P | 9.53 | 0.3752 | 69.85 | 93.5 | 4200 |  | 12 |  | C.I.P. |
| .378 Weatherby Mag | 9.53 | 0.3752 | 73.99 | 92.84 | 4400 |  | 12.01 |  | C.I.P. |
| .38-55 Win | 9.59 | 0.3776 | 52.96 | 63.75 | 2400 |  | 17.99 |  | C.I.P. |
| .400 Legend | 10.16 | 0.4 | 41.91 | 57.4 | 3180 |  | 16 |  | C.I.P. |
| .404 Jeffery | 10.74 | 0.4228 | 73.02 | 89.66 | 3650 |  | 16.54 |  | C.I.P. |
| .408 CheyTac | 10.36 | 0.4079 | 77.21 | 115.5 | 4400 |  | 13 |  | C.I.P. |
| .416 Barrett | 10.57 | 0.4161 | 83.06 | 125.73 | 4400 |  | 12 |  | C.I.P. |
| .416 Rem Mag | 10.57 | 0.4161 | 72.39 | 91.44 | 4300 |  | 14.02 |  | C.I.P. |
| .416 Rigby | 10.57 | 0.4161 | 73.66 | 95.25 | 3250 |  | 16.54 |  | C.I.P. |
| .416 Ruger | 10.57 | 0.4161 | 65.53 | 84.84 | 4300 |  | 14.02 |  | C.I.P. |
| .416 Weatherby Mag | 10.57 | 0.4161 |  |  |  |  | 14 |  | Üretici |
| .45-70 Govt | 11.63 | 0.4579 | 53.47 | 64.77 | 2200 |  | 20 |  | C.I.P. |
| .450 Bushmaster | 11.48 | 0.452 | 43.18 | 57.4 | 2700 |  | 24 |  | C.I.P. |
| .450 Marlin | 11.63 | 0.4579 | 53.34 | 64.76 | 3300 |  | 20 |  | C.I.P. |
| .450 Rigby | 11.63 | 0.4579 | 73.5 | 95.25 | 4000 |  | 16.54 |  | C.I.P. |
| .450/.400 NE 3" | 10.44 | 0.411 | 76.2 | 95.25 | 2800 |  | 15 |  | C.I.P. |
| .458 Lott | 11.63 | 0.4579 | 71.12 | 91.44 | 4300 |  | 10 |  | C.I.P. |
| .458 Win Mag | 11.63 | 0.4579 | 63.5 | 84.84 | 4300 |  | 14.02 |  | C.I.P. |
| .460 Weatherby Mag | 11.63 | 0.4579 | 73.99 | 95.25 | 4400 |  | 15.98 |  | C.I.P. |
| .470 NE | 12.07 | 0.4752 | 82.55 | 101.09 | 2700 |  | 20.98 |  | C.I.P. |
| 5.6x50 R Mag | 5.7 | 0.2244 | 50 | 61 | 3400 |  | 13.78 |  | C.I.P. |
| 5.6x52 R | 5.77 | 0.2272 | 52 | 63.75 | 3300 |  | 10.63 |  | C.I.P. |
| 5.6x57 | 5.7 | 0.2244 | 56.7 | 69 | 4400 |  | 9.84 |  | C.I.P. |
| .50 BMG | 12.95 | 0.5098 | 99.31 | 138.43 | 3700 |  | 15 |  | C.I.P. |
| .500 Jeffery | 12.95 | 0.5098 | 69.85 | 88.09 | 3300 |  | 20 |  | C.I.P. |
| .500 NE 3" | 12.95 | 0.5098 | 76.2 | 95.25 | 2800 |  | 15 |  | C.I.P. |
| .500/.416 NE | 10.57 | 0.4161 | 82.55 | 101.09 | 3150 |  | 16.54 |  | C.I.P. |
| 6 BRA | 6.17 | 0.2429 |  |  |  |  |  |  | — |
| 6 Dasher | 6.17 | 0.2429 | 39.24 | 60 | 4400 |  | 7.75 |  | C.I.P. |
| 6.5 Grendel | 6.71 | 0.2642 |  |  | 4050 |  |  |  | C.I.P. |
| 6.5 PRC | 6.71 | 0.2642 | 51.56 | 75.06 | 4400 |  | 7.99 |  | C.I.P. |
| 6.5 Weatherby RPM | 6.71 | 0.2642 | 65.278 |  |  | 65000 | 8 |  | SAAMI |
| 6.5-284 Norma | 6.71 | 0.2642 | 55.12 | 82 | 4100 |  | 9 |  | C.I.P. |
| 6.5-300 Weatherby Mag | 6.71 | 0.2642 | 71.755 |  |  |  | 8 |  | Üretici |
| 6.5x47 Lapua | 6.71 | 0.2642 | 47 | 71 | 4350 |  | 7.87 |  | C.I.P. |
| 6.5x52 R | 6.71 | 0.2642 | 52 | 64.5 | 2450 |  | 10.24 |  | C.I.P. |
| 6.5x55 Swedish | 6.71 | 0.2642 | 55 | 80 | 3800 |  | 8.66 |  | C.I.P. |
| 6.5x57 | 6.71 | 0.2642 | 56.7 | 82 | 3900 |  | 7.87 |  | C.I.P. |
| 6.5x57 R | 6.71 | 0.2642 | 56.7 | 82 | 3300 |  | 7.87 |  | C.I.P. |
| 6.5x65 R RWS | 6.71 | 0.2642 | 65 | 85 | 3800 |  | 7.87 |  | C.I.P. |
| 6.5x68 | 6.71 | 0.2642 | 67.5 | 86.5 | 4400 |  | 9.84 |  | C.I.P. |
| 6.8 Rem SPC | 7.04 | 0.2772 | 42.84 | 57.4 | 4050 |  | 10 |  | C.I.P. |
| 6.8 Western | 7.04 | 0.2772 | 51.31 | 75.06 | 4400 |  | 8 |  | C.I.P. |
| 6mm ARC | 6.17 | 0.2429 | 37.85 | 57.4 | 3800 |  | 7.52 |  | C.I.P. |
| 6mm BR Norma | 6.17 | 0.2429 | 39.62 | 62 | 4050 |  | 8 |  | C.I.P. |
| 6mm Creedmoor | 6.17 | 0.2429 | 48.77 | 71.12 | 4350 |  | 7.52 |  | C.I.P. |
| 6mm GT | 6.17 | 0.2429 | 43.82 | 67.06 |  | 62000 | 7.5 |  | SAAMI |
| 6mm PPC | 6.17 | 0.2429 | 38.18 | 55.7 | 4050 |  | 21.69 |  | C.I.P. |
| 6mm Rem | 6.17 | 0.2429 | 56.72 | 71.76 | 4300 |  | 9 |  | C.I.P. |
| 6x47 Lapua | 6.17 | 0.2429 |  |  |  |  |  |  | — |
| 6x62 R Frères | 6.17 | 0.2429 | 61.75 | 82 | 4300 |  | 10.24 |  | C.I.P. |
| 6XC | 6.17 | 0.2429 | 48.3 | 70 | 4400 |  | 8 |  | C.I.P. |
| 7.5x55 Swiss | 7.82 | 0.3079 | 55.6 | 77.7 | 3800 |  | 10.63 |  | C.I.P. |
| 7.62x54R | 7.92 | 0.3118 | 53.72 | 77.16 | 3900 |  | 9.45 |  | C.I.P. |
| 7mm Backcountry | 7.21 | 0.2839 | 61.39 | 84.84 |  | 80000 | 8 |  | SAAMI |
| 7mm Blaser Mag | 7.21 | 0.2839 | 59.7 | 80 | 4200 |  | 10 |  | C.I.P. |
| 7mm PRC | 7.21 | 0.2839 | 57.91 | 84.84 | 4400 |  | 8 |  | C.I.P. |
| 7mm Rem Mag | 7.21 | 0.2839 | 63.5 | 83.57 | 4300 |  | 9.49 |  | C.I.P. |
| 7mm Weatherby Mag | 7.21 | 0.2839 | 64.74 | 85.34 | 4400 |  | 10 |  | C.I.P. |
| 7mm-08 Rem | 7.21 | 0.2839 | 51.69 | 71.12 | 4150 |  | 9.49 |  | C.I.P. |
| 7x57 Mauser | 7.24 | 0.285 | 57 | 78 | 3900 |  | 8.66 |  | C.I.P. |
| 7x57 R | 7.24 | 0.285 | 57 | 78 | 3400 |  | 8.66 |  | C.I.P. |
| 7x64 | 7.21 | 0.2839 | 64 | 84 | 4150 |  | 8.66 |  | C.I.P. |
| 7x65 R | 7.21 | 0.2839 | 65 | 83.6 | 3800 |  | 8.66 |  | C.I.P. |
| 8.5x55 Blaser | 8.59 | 0.3382 | 54.7 | 75.84 | 4300 |  | 12 |  | C.I.P. |
| 8.6 Blackout | 8.59 | 0.3382 | 42.8 | 71.37 |  | 62000 | 6 |  | SAAMI |
| 8x57 IRS | 8.22 | 0.3236 | 57 | 82 | 3300 |  | 9.45 |  | C.I.P. |
| 8x57 JRS | 8.22 | 0.3236 | 57 | 82 | 3300 |  | 9.45 |  | C.I.P. |
| 8x57 JS | 8.22 | 0.3236 | 57 | 82 | 3900 |  | 9.45 |  | C.I.P. |
| 8x64 S | 8.22 | 0.3236 | 64 | 87.5 | 4050 |  | 9.45 |  | C.I.P. |
| 8x68 S | 8.22 | 0.3236 | 67.5 | 87 | 4400 |  | 11.02 |  | C.I.P. |
| 8x75 RS | 8.22 | 0.3236 | 74.6 | 96 | 3800 |  | 9.45 |  | C.I.P. |
| 9.3x62 | 9.3 | 0.3661 | 62 | 83.6 | 3900 |  | 14.17 |  | C.I.P. |
| 9.3x66 Sako | 9.3 | 0.3661 | 66 | 85 | 4150 |  | 14.17 |  | C.I.P. |
| 9.3x72 R | 9.3 | 0.3661 | 72 | 86 | 2000 |  | 16.54 |  | C.I.P. |
| 9.3x74 R | 9.3 | 0.3661 | 74.7 | 96.5 | 3400 |  | 14.17 |  | C.I.P. |
| 8x57 JR **(yeni)** | 8.07 | 0.3177 | 57 | 82 | 3200 |  | 9.45 |  | C.I.P. |
| 10.3x60 R **(yeni)** | 10.49 | 0.413 | 60.8 | 85 | 2700 |  | 17.72 |  | C.I.P. |
| 5.45x39 **(yeni)** | 5.6 | 0.2205 | 39.82 | 57 | 3550 |  | 7.68 |  | C.I.P. |
| 7.65x53 Arg **(yeni)** | 7.92 | 0.3118 | 53.6 | 76 | 3900 |  | 11.02 |  | C.I.P. |
| 7mm WSM **(yeni)** | 7.21 | 0.2839 | 53.34 | 72.64 | 4400 |  | 9.49 |  | C.I.P. |
| 7mm Rem SAUM **(yeni)** | 7.21 | 0.2839 | 51.69 | 71.76 | 4400 |  | 10 |  | C.I.P. |
| 7mm RUM **(yeni)** | 7.21 | 0.2839 | 72.39 | 91.44 | 4400 |  | 9.5 |  | C.I.P. |
| .300 Rem SAUM **(yeni)** | 7.82 | 0.3079 | 51.18 | 71.76 | 4400 |  | 10 |  | C.I.P. |
| .284 Win **(yeni)** | 7.19 | 0.2831 | 55.12 | 71.12 | 4400 |  | 10 |  | C.I.P. |
| .300 H&H Mag **(yeni)** | 7.82 | 0.3079 | 72.39 | 91.44 | 4300 |  | 10 |  | C.I.P. |
| .300 Savage **(yeni)** | 7.82 | 0.3079 | 47.52 | 66.04 | 3650 |  | 12.01 |  | C.I.P. |
| 4.50 mm (.177) | 4.5 | 0.1772 |  |  |  |  |  |  | Üretici |
| 5.00 mm (.20) | 5 | 0.1969 |  |  |  |  |  |  | Üretici |
| 5.50 mm (.22) | 5.5 | 0.2165 |  |  |  |  |  |  | Üretici |
| 6.35 mm (.25) | 6.35 | 0.25 |  |  |  |  |  |  | Üretici |
| 7.62 mm (.30) | 7.62 | 0.3 |  |  |  |  |  |  | Üretici |
| 9.00 mm (.357) | 9 | 0.3543 |  |  |  |  |  |  | Üretici |
| 11.43 mm (.45) | 11.43 | 0.45 |  |  |  |  |  |  | Üretici |
| 11.60 mm (.45) **(yeni)** | 11.6 | 0.4567 |  |  |  |  |  |  | Üretici |
| 12.70 mm (.50) | 12.7 | 0.5 |  |  |  |  |  |  | Üretici |
