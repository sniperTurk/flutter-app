# Türkiye online mağazalarında satılan tüfek dürbünleri: marka, model ve retikül listesi

**Tarih:** 2026-10-11
**Kapsam:** Optik tüfek dürbünleri, LPVO ve prizma dürbünler. Termal, gece görüş, red-dot/reflex, magnifier, el dürbünü ve montaj ürünleri hariç tutuldu.

## 1. Yöntem

- Araçlar: yalnız WebSearch (tüm sitelerde ve `allowed_domains` ile mağaza bazında) ve WebFetch (kategori, marka ve etiket sayfaları). curl veya python kullanılmadı.
- **Kural notu:** Mağazalardan yalnız "bu ürün satışta/listede" bilgisi alındı: marka, model adı ve **ürün başlığında geçen** retikül adı. Mağazadaki ölçü, teknik değer, fiyat veya açıklama metni kullanılmadı ve kaydedilmedi. Model adındaki büyütme/objektif ibaresi (ör. "4-12x40") yalnız model kimliği olarak tutuldu.
- "Retikül" sütunu ürün başlığındaki ifadeyi aynen taşır. Başlıkta retikül yoksa "belirtilmemiş" yazıldı. "FFP/SFP", "IR", "SFIR", "MOA/MRAD" gibi etiketler başlıkta retikül adı yerinde geçtiği için olduğu gibi aktarıldı. **Bunlar gerçek retikül adı değildir** (bkz. bölüm 4 notu).

| Kısa ad | Mağaza | Okunan sayfa(lar) |
|---|---|---|
| BM | balistikmarket.com | `/tufek-durbunleri` s.1–2 (157 ürünün 60'ı), `/nutrek-optics`, `/nightforce-optics`, `/primary-arms`, `/vortex-optics`, `/tufek-durbunleri-ve-aksesuarlari?sort=p.price&order=DESC&page=4` ve site içi arama başlıkları |
| İAM | izmiravmarket.com | `/kategori/tufek-durbunu` (417 ürün; yalnız ilk 12 okunabildi), `/marka/hawke`, `/marka/vector-optics` ve site içi arama başlıkları |
| BZK | bozkurtav.com | Kategori sayfası (`/tufek-durbunleri-pmk790`) açılmadı; yalnız arama sonucu ürün başlıkları kullanıldı |
| AKSU | aksuav.com.tr | `/kategori/tufek-durbunleri` (172 ürünün ilk 8'i), `/kategori/victoptics-tufek-durbunleri`, `/kategori/huglu-optics`, `/kategori/hawke` ve arama başlıkları |
| ZIG | ziganaoutdoor.com | `/kategori/tufek-durbunleri-1` (167 ürünün ilk 40'ı), `/marka/vector-optics`, `/marka/sig-sauer`, `/marka/vortex` |
| OD | outdoordunyasi.com.tr | `/marka/hawke` |
| ATK | atakansilah.com | `/kategori/optik` |
| EMKA | emkaav.com | `/tufek-durbunleri-pmk74` (ilk 15) |
| KS | kampseti.com | `/kategori/tufek-durbunleri` (156 ürünün ilk 28'i) |
| KLAS | klasav.com | `/kategori/havali-tufek-durbunu` (111 ürünün 1. sayfası) |
| AVCI | avcimarket.com | `/optik-elektronik/tufek-durbunleri` (13 ürünün tamamı) |
| DM | durbunmarket.com | `/Silah-tufek-durbunu` (8 ürünün tamamı) |

**Kısıtlar (dürüst not):**
- Pagination neredeyse hiçbir sitede WebFetch ile çalışmadı:
  - BM'de `?page=3–6` sürekli 1. veya 2. sayfayı döndürdü.
  - İAM'de `?tp=`, `?page=` ve `?sayfa=` robots.txt ile yasak.
  - KS ve ZIG'de `?tp=2` yine 1. sayfayı döndürdü.
  Eksik sayfalar site içi aramayla kısmen tamamlandı. Liste bu yüzden **kapsamlı ama tam değil**. Özellikle İAM (417 ürün), AKSU (172), ZIG (167), KS (156) ve BM'nin 61–157 arası ürünleri kısmi.
- AKSU'nun `/kategori/t-eagle-optics`, `/athlon-optics`, `/sniper-optic`, `/swampdeer-optics` ve `/konus` sayfaları HTTP 429 (oran sınırı) veya hata verdi, tekrar denenmedi. Bu markalar yalnız arama başlıklarından alındı.
- bozkurtav.com, akakce.com ve balistikmarket.com'un köksüz URL'leri ilk denemede açılmadı. avmarketim, kaplanav, avcilikmarket ve silahdukkanim için arama motorunda hiç sonuç çıkmadı (alan adı bulunamadı veya indekslenmemiş).
- İAM marka filtresinde görünen ama başlığı okunamayan markalar (yalnız sayım): Kahles (3), Leupold (1), Crimson Trace (10), Burris (7), Firefield (5), Truglo (1), Tasco (1), Leapers (1), Stoeger (2), Umarex (2), Crosman (1), Specprecision (2), Sniper (3), Teagle (3). Bu filtre red-dot dahil "dürbün" kategorisinin tamamını sayıyor olabilir.

## 2. Marka bazında tablo

### Vortex Optics
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Crossfire HD 1-4x24 SFP | Dead-Hold 2A BDC (MOA) | BM, ZIG |
| Crossfire HD 1.5-5.5x32 SFP Scout | Dead-Hold 2A BDC (MOA) | BM |
| Crossfire HD 2-7x32 SFP | Dead-Hold 2A BDC (MOA) / Illuminated Dead-Hold | BM, BZK, AKSU |
| Crossfire HD 3-9x40 SFP | Dead-Hold 2A BDC (MOA) | BM |
| Crossfire HD 4-12x44 SFP | Dead-Hold 2A BDC (MOA) | BM |
| Crossfire HD 6-18x50 SFP | Dead-Hold 2A BDC (MOA) | BM, BZK |
| Crossfire II 4-16x50 AO | Dead-Hold BDC (MOA) | BZK |
| Strike Eagle 1-6x24 SFP | AR-BDC3 (MOA) | BM |
| Strike Eagle 1-8x24 SFP | AR-BDC3 | BM, ZIG |
| Strike Eagle 1-8x24 FFP | EBR-8 (MOA) | BM, ZIG |
| Strike Eagle 1-8x24 | belirtilmemiş | AKSU |
| Strike Eagle 1-10x24 FFP | EBR-8 BDC (MOA) | BZK |
| Strike Eagle 1-10x24 FFP | EBR-8 BDC (MRAD) | BZK, ZIG |
| Strike Eagle 3-18x44 FFP | EBR-7C (MRAD) | ZIG |
| Strike Eagle 5-25x56 FFP | EBR-7C (MOA) | BZK |
| Strike Eagle 5-25x56 FFP | belirtilmemiş | AKSU |
| Venom 1-6x24 SFP | AR-BDC3 (MOA) | BM |
| Venom 3-15x44 FFP | EBR-7C (MRAD) | ZIG |
| Venom 5-25x56 FFP | EBR-7C (MRAD) | BM, ZIG, AKSU (AKSU başlığında retikül yok) |
| Diamondback Tactical 4-16x44 FFP | EBR-2C (MRAD) | ZIG |
| Diamondback Tactical 6-24x50 FFP | EBR-2C (MRAD) | BM, ZIG |
| Viper 6.5-20x50 PA | Mil Dot (MOA) | BM |
| Viper HS 2.5-10x44 | Dead-Hold BDC (MOA) | BM |
| Viper HST 6-24x50 | VMR-1 (MRAD) | BM |
| Viper HD 5-25x50 FFP | VMR-4 (MRAD) | BM, AKSU |
| Viper PST Gen II 2-10x32 FFP | EBR-4 (MRAD) | BM |
| Viper PST Gen II 3-15x44 FFP | EBR-7C (MRAD) | BM |
| Viper PST Gen II 5-25x50 FFP | EBR-7C (MRAD) | BM, AKSU (AKSU başlığında retikül yok) |
| Razor HD AMG 6-24x50 FFP | EBR-7B (MRAD) | BM |
| Razor HD Gen II-E 1-6x24 | VMR-2 (MRAD) | BM |
| Razor HD Gen II 4.5-27x56 FFP | Horus H59 | BZK |
| Razor HD Gen III 6-36x56 FFP | belirtilmemiş | AKSU |
| Razor HD LHT 3-15x50 | G4i BDC (MRAD) | BM |
| Spitfire 3x Prism | belirtilmemiş | İAM |

### Hawke
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Vantage 4x32 | Mil Dot | BZK |
| Vantage 2-7x32 | 30/30 IR | OD |
| Vantage 2-7x32 AO | Mil Dot | İAM |
| Vantage 3-9x40 | Mil Dot | OD |
| Vantage 3-9x40 AO IR | Mil Dot | İAM |
| Vantage 3-9x50 AO IR | Mil Dot | BZK, OD |
| Vantage 4-12x40 AO | Mil Dot | İAM |
| Vantage 4-16x44 SF | 1/2 Mil Dot | İAM |
| Vantage 6-24x44 SF | 1/2 Mil Dot | İAM |
| Vantage 4-16x50 AO IR | Mil Dot | İAM |
| Vantage 4-16x50 AO IR | Rimfire .17 HMR 16x | İAM |
| Vantage 6-24x50 AO IR | Mil Dot | İAM |
| Vantage 30mm WE FFP 4-16x50 IR SF | 1/2 Mil Dot (MRAD) | İAM |
| Vantage 30mm WE SFP 4-16x50 IR SF | 10x 1/2 Mil Dot (MRAD) | İAM |
| Vantage 30mm WE SFP 6-24x50 IR SF | 10x 1/2 Mil Dot (MRAD) | İAM |
| Panorama 2-7x32 IR | 10x Half-Mil Dot | İAM |
| Panorama 4-12x40 AO | 10x 1/2 Mil Dot | İAM, OD |
| Airmax 30mm FFP 4-16x50 SF | AMX IR | İAM |
| Airmax 30mm FFP 6-24x50 SF | AMX IR | İAM |
| Endurance 30mm SFP 4-16x50 | .223/.308 16x | İAM |
| Endurance 5-15x50 | Mil Dot | OD |
| Endurance 2.5-10x50 30mm | 30/30 | OD |
| Endurance LER 2-7x32 IR | 30/30 | OD |
| Endurance LER 3-9x40 IR | 30/30 | OD |
| Endurance LER 4-12x42 IR | 30/30 | OD |
| Sidewinder 30mm SFP 4.5-14x44 | 10x 1/2 Mil Dot + Half Mil | İAM |
| Sidewinder 30mm FFP 4-16x50 SF | Half Mil | İAM |
| Sidewinder 6-24x56 30mm | 20x 1/2 Mil Dot | İAM |
| Sidewinder ED 10-50x60 | TMX | BZK |
| 6.5-20x42 SF IR (eski seri) | Mil Dot | İAM |
| Frontier 30 SF 5-30x50 | TMX | OD |
| Frontier 30 1-6x24 | Circle Dot | İAM |
| Frontier 30 SFP FD 1-10x24 | belirtilmemiş | AKSU (stok yok) |

### Vector Optics (Paragon dahil)
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Continental x6 4-24x56 FFP 34mm | MBR | İAM |
| Continental x6 3-18x50 Hunting | CDM | ZIG |
| Continental x6 1.5-9x42 SFP Hunting (SCOM-23) | belirtilmemiş | ZIG |
| Continental X8 4-32x56 SFP ED Tactical | belirtilmemiş | İAM |
| Continental 4-24x56 FFP 34mm (SCFF-29) | belirtilmemiş | İAM |
| Continental 5-30x56 FFP 34mm (SCFF-30) | belirtilmemiş | İAM |
| Everest 3-18x50 SFP Gen II (SCOL-06II) | belirtilmemiş | İAM, KS, AKSU |
| Aston 3-18x44 SFP (SCOL-23) | belirtilmemiş | İAM |
| Grizzly 3-18x56 HD (SCOL-67) | belirtilmemiş | İAM |
| Sentinel 6-24x50 FFP (SCFF-57) | belirtilmemiş | İAM |
| Sentinel Gen II 6-24x50 SFP (SCOL-60) | belirtilmemiş | İAM |
| Sentinel 6-24x50 E-SF (SCOL-14) | belirtilmemiş | İAM |
| Forester JR Power 3-9x40 SFP | belirtilmemiş | İAM |
| Veyron 3-12x44 SFP (SCOM-24) | belirtilmemiş | İAM |
| Veyron 4-16x44 IR FFP | belirtilmemiş | İAM |
| Veyron 6-24x44 FFP (SCFF-23) | belirtilmemiş | İAM |
| Hugo 6-24x50 GT SFP (SCOL-32) | belirtilmemiş | İAM |
| Taurus 1-6x24 FFP (SCFF-27) | belirtilmemiş | İAM |
| Taurus 4-24x50 FFP (SCFF-17) | belirtilmemiş | İAM |
| Taurus 6-24x50 HD FFP | MIL | AKSU |
| Taurus Gen II 3-24x56 ED FFP | belirtilmemiş | AKSU |
| Tauron 5-30x56 Gen II FFP (SCFF-66) | belirtilmemiş | İAM |
| Tauron 5-25x56 HD FFP | MIL PRS | AKSU |
| Tauron Gen II 5-40x56 ED FFP | MIL | AKSU |
| Tauron 4-24x50 Gen II FFP | belirtilmemiş | AKSU |
| Tourex 6-24x50 FFP (SCFF-19) | belirtilmemiş | İAM |
| Monarch 8-32x56 FFP (SCFF-06) | belirtilmemiş | İAM |
| Mustang Gen II 1-4x24 FFP | belirtilmemiş | İAM |
| Orion Pro Max 3-18x50 HD SFP (SCOL-57) | belirtilmemiş | İAM |
| Orion Pro Max 6-24x50 HD SFP | belirtilmemiş | AKSU |
| Orion Pro Max 6-24x50 HD FFP | MOA | AKSU |
| Paragon Gen2 3-15x50 SFP (SCOM-25) | belirtilmemiş | ZIG |
| Paragon 6-30x56 | belirtilmemiş | ZIG |
| Paragon 1x16 Micro Prism | belirtilmemiş | İAM, ZIG |
| Paragon 3x18 Micro Prism (SCPS-M03) | belirtilmemiş | İAM (tükendi) |

### Element Optics
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Helix 4-16x44 FFP | APR-1C (MRAD) | BM, ZIG |
| Helix 4-16x44 FFP | APR-2D (MRAD) | BM, AKSU |
| Helix 6-24x50 SFP | APR-1C (MRAD) | BM |
| Helix Gen 2 4-16x44 FFP | APR-1C (MRAD) | BM |
| Helix Gen 2 6-24x50 FFP | APR-2D (MRAD) | BM, EMKA |
| Helix Gen 2 6-24x50 FFP | APR-1C (MRAD) | ZIG |
| Helix HD 2-16x50 SFP | RAPTR-1 (MRAD) | BM, ZIG |
| Helix HD Compact 2-12x42 SFP | RAPTR-1 (MOA) | ZIG |
| Helix HDLR 2-16x50 SFP | APR-1C (MRAD) | BM, ZIG |
| Iris 3-9x40 SFP | Duplex (MOA) | BM, ZIG |
| Iris 4-12x44 SFP | RAPTR-1S (MOA) | BM, ZIG |
| Nexus 5-20x50 FFP | APR-1C (MRAD) | BM |
| Theos 2-10x42 FFP | MPR-1C (MRAD) | BM |
| Theos 6-36x56 FFP | APR-2D (MRAD) | BM |
| Titan 3-18x50 FFP | APR-2D (MRAD) | BM, AKSU |
| Titan 5-25x56 FFP | APR-1C (MRAD) | BM, EMKA |
| Titan 5-25x56 FFP | APR-2D (MRAD) | BM |
| HYPR-7 7x50 Prism | Hibrit Balistik | BM |
| Immersive 5x30 Prismatic | LPR-1D (BDC, MRAD) | EMKA, ZIG |
| Immersive 14x50 Prismatic | APR-1C (MRAD) | EMKA |

### Discovery Optics / Discoveryopt
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| VT-Z 6-24x50 SF FFP | belirtilmemiş ("SF FFP (MOA)") | BM, ZIG, KS, KLAS |
| ED-ELR Gen II 5-40x56 FFP | belirtilmemiş ("SFIR FFP (MRAD)") | BM, ZIG |
| ED-PRS Gen II 5-25x56 FFP | belirtilmemiş ("SFIR FFP (MRAD)") | BM, ZIG |
| HD Gen II 5-30x56 FFP | belirtilmemiş ("SFIR FFP (MRAD)") | BM, ZIG |
| XED 6-36x56 FFP | belirtilmemiş ("SFIR FFP (MRAD)") | BM, ZIG |
| LHD 1-6x24 SFP | belirtilmemiş ("SFIR SFP (MOA)") | BM, ZIG |
| MS 6-24x42 AOAC SFP | belirtilmemiş ("(MOA)") | BM |

### Barska
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Sniper GX2 6-24x50 IR | Mil Dot | İAM, BZK |
| Sniper GX2 10-40x50 IR | Mil Dot | BZK, KS, KLAS |
| Sniper GX2 4-16x50 IR | Mil Dot | KLAS |
| Varmint 6-24x50 AO | Mil Dot | BZK, KLAS |
| Contour 4x32 IR | Mil Dot | KLAS |
| Benchmark 4-16x50 | Mil-Dot | KLAS |
| Blackhawk 6-24x50 AO IR | belirtilmemiş | KLAS |
| Plinker-22 4x32 | 30/30 | KS, KLAS |
| Sight 4x20 M-16 base | 30/30 | İAM, ATK |
| Hornet 3-9x40 | belirtilmemiş | KS |

### Bushnell
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Elite Tactical XRS3 6-36x56 FFP | G5I (MRAD) | BM |
| Match Pro 5-30x56 FFP | G5I (MRAD) | BM |
| R7 ED 4-20x50 FFP | Hybrid Dot Tree (MRAD) | BM |
| Engage 3-12x56 | Alman No. 4 (German #4), aydınlatmalı | KLAS |
| Engage 3-9x50 | belirtilmemiş | KLAS |
| 3-9x32 .22 Rimfire | belirtilmemiş | İAM |
| Trophy XLT 3-12x56 | 4A / A4 aydınlatmalı | DM |
| Elite 3500 4-12x40 | belirtilmemiş | DM |
| Elite 4500 4-16x40 | belirtilmemiş | DM |
| Elite Tactical DMR II 3.5-21x50 | belirtilmemiş | DM |
| Elite Tactical LRS 10x40 | belirtilmemiş | DM |
| Elite Tactical LRS 4.5-30x50 | belirtilmemiş | DM |

### Victoptics (Vector Optics alt markası)
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| S4 6-24x50 SFP (OPSL-17) | belirtilmemiş | İAM, AKSU |
| S4 6-24x50 FFP | belirtilmemiş | AKSU |
| S4 6-24x50 SFP Coyote FDE | belirtilmemiş | AKSU (tükendi) |
| S4 3-12x40 SFP | belirtilmemiş | AKSU |
| S4 4-16x44 SFP Coyote | belirtilmemiş | AKSU |
| S4 4-16x44 FFP | belirtilmemiş | AKSU (tükendi) |
| S4 1.5-6x28 IR SFP | belirtilmemiş | İAM, AKSU |
| S6 1-6x24 SFP / LPVO (OPSL-22) | belirtilmemiş | İAM, AKSU |
| S6 1-6x24 Coyote FDE LPVO | belirtilmemiş | İAM, AKSU |
| S6 1-6x24i Fiber LPVO (OPSL-33 / OPSL133) | belirtilmemiş | İAM |
| S10 1-10x24 LPVO SFP | belirtilmemiş | AKSU |
| S10 1-10x24i Fiber LPVO SFP | belirtilmemiş | AKSU |
| X4 1-4x20 IR SFP | belirtilmemiş | İAM |
| SVD Dragunov 4x24 FFP IR (OPSL-34) | belirtilmemiş (SVD tipi) | İAM |
| SCB 2-5x24 IR | CROSSB (arbalet) | ZIG |

### Arken Optics
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| EP-5 Gen2 5-25x56 FFP | TOR (MRAD) | BM, EMKA |
| EP-5 Gen2 5-25x56 FFP | VPR (MRAD) | BM, EMKA |
| EP-5 Gen2 7-35x56 FFP | TOR (MRAD) | BM, EMKA |
| EP-5 Gen2 7-35x56 FFP | VPR (MRAD) | BM, EMKA, ZIG |
| EP-8 1-8x28 FFP | KLGRID (MRAD) | BM, EMKA |
| LH-4 4-16x44 FFP | VPR (MRAD) | BM, EMKA |
| LH-4 6-24x50 FFP | VPR (MRAD) | BM, EMKA |
| LH-6 1-6x24 SFP | KLBOX (MOA) | BM |
| Outrider 2-12x42 SFP | DLR (MOA) | BM |
| Outrider 2-12x42 SFP | FDR (MOA) | BM |
| SH-4 Gen2 4-16x50 FFP | VHR (MRAD) | BM |
| SH-4 Gen2 4-16x50 FFP | VPR (MRAD) | BM |

### Nutrek Optics
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Blackiron 2.5-10x50 SFP IR | belirtilmemiş ("(MOA)") | BM, ZIG |
| Blackiron 3-18x50 SFP IR | belirtilmemiş | ZIG |
| Blackiron 6-24x50 SFP IR | BDC Tree (MRAD) | BM, ZIG (ZIG başlığında retikül yok) |
| Silvermark 4.5-27x56 FFP IR | BDC Tree (MRAD) | BM, EMKA, ZIG |
| Coppertag 5-25x56 FFP IR | belirtilmemiş | ZIG |
| Reaper 1-6x24 IR (SFP/FFP) | belirtilmemiş ("(MOA)") | BM, EMKA, ZIG |
| Reaper 1-8x24 FFP IR | belirtilmemiş | ZIG |
| Reaper 1-10x24 SFP IR | belirtilmemiş ("(MOA)") | BM, ZIG |

### Meopta (yalnız BM)
| Model | Retikül (başlıkta) |
|---|---|
| MeoHunter R5 3-15x50 FFP | RD BDC3 (MRAD) |
| MeoHunter R5 3-15x50 SFP | RD 4C (MRAD) |
| MeoHunter R5 3-15x50 SFP | RD BDC3 (MRAD) |
| MeoHunter R5 4-20x50 SFP | RD BDC3 (MRAD) |
| MeoHunter R5 5-25x56 FFP | RD BDC3 (MRAD) |
| MeoPro R5 2-10x42 SFP | Z-Plus (MRAD) |
| MeoPro R6 1-6x24 SFP | RD 4C (MOA) |
| MeoPro R6 1-6x24 SFP | RD K-Dot 2 (MOA) |
| MeoPro R6 2.5-15x44 SFP | RD 4C (MRAD) |
| MeoPro R6 3-18x50 FFP | RD 1 (MRAD) |
| MeoPro R6 3-18x50 SFP | RD 4C (MRAD) |
| MeoPro R6 3-18x56 SFP | RD 4C (MRAD) |

### 3E (yerli, yalnız BM)
| Model | Retikül (başlıkta) |
|---|---|
| AVCI 4x prizma | 5.56mm & 2 MOA R1x |
| AVCI 1x-4x | 7.62mm |
| KESKİN 1-8x30 LPVO FFP | belirtilmemiş ("(MRAD)") |
| KESKİN 3-12x50 FFP | EMR-M15C (MRAD) |
| KESKİN 5-25x56 FFP | EMR-M25D (MRAD) |
| KESKİN 5-25x56 Ultra Short FFP | EMR-M10C (MRAD) |
| KESKİN 5-25x56 Ultra Short FFP | EMR-M25D (MRAD) |

### GPO
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Centuri 4-16x44i FFP | HSi-CQB (MRAD) | BM |
| Spectra 5x 3-15x56i FFP | G4i Fiber (MRAD) | BM |
| Spectra 6x 2-12x50i SFP | G4i Fiber (MRAD) | BM |
| Spectra 8x 1.6-13x44i SFP | G4i Fiber (MRAD) | BM |
| Spectra 4x 2.5-10x44i | belirtilmemiş | AKSU |

### Sig Sauer
| Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|
| Buckmasters 3-9x40 SFP | BDC | ATK |
| Buckmasters 3-9x50 SFP | BDC | ATK |
| Whiskey4 3-12x44 SFP | Hellfire Quadplex | ATK |
| Tango-MSR 1-8x24 | belirtilmemiş | İAM |
| Tango-MSR 5-30x56 | belirtilmemiş | İAM |
| Tango4 1-4x24 | belirtilmemiş | ZIG |

### Diğer premium / taktik markalar
| Marka | Model | Retikül (başlıkta) | Mağaza |
|---|---|---|---|
| Nightforce | ATACR 7-35x56 F1 FFP | MIL-C (MRAD) | BM |
| Zero Compromise (ZCO) | ZC527 5-27x56 FFP | MPCT2 0.1 MIL, aydınlatmalı | İAM |
| Zero Compromise (ZCO) | ZC527 5-27x56 FFP | MPCT1X | İAM |
| Zero Compromise (ZCO) | ZC840 8-40x56 | belirtilmemiş | İAM |
| U.S. Optics | TS-20X 2.5-20x50 FFP | GENIIXR (MRAD) | BM |
| U.S. Optics | TS-6X 1-6x24 SFP | Kırmızı Tek Nokta / Simple Crosshair (2 MOA) | BM |
| U.S. Optics | TS-8X 1-8x24 SFP | Kırmızı Tek Nokta (2 MOA) | BM |
| DNT Optics | TheOne 7-35x56 FFP | TOR (MRAD) | BM |
| Riton Optics | 7 Conquer 4-32x56 FFP | PSR (MRAD) | BM |
| Primary Arms | SLx 1-6x24 SFP Gen III | ACSS-5.56/5.45/.308 (aydınlatmalı) | BM (stok yok) |
| Primary Arms | SLx 1-8x24 SFP | ACSS-5.56/5.45/.308 (aydınlatmalı) | BM (stok yok) |
| Athlon | Midas TAC 5-25x56 FFP | APRS3 (MIL) | AKSU |
| Athlon | Neos 4-12x40 | BDC 22 Rimfire | AKSU |
| Sightmark | Citadel 3-18x50 FFP | LR2 | İAM |
| Nikon | Prostaff 3-9x50 | NP (Nikoplex) | İAM |
| Tasco | World Class 4-16x40 | belirtilmemiş | DM |

### Ekonomik / havalı tüfek segmenti
| Marka | Model | Retikül (başlıkta) | Mağaza(lar) |
|---|---|---|---|
| BSA | Stealth Tactical STS 4-16x44 IR | Mil-Dot | BZK |
| BSA | 6-24x50 | Mil-Dot | KS, KLAS |
| Gamo | 4x32 WR ışıklı | belirtilmemiş | BZK |
| ASG | Strike 4x32 | belirtilmemiş | BZK |
| ASG | 3-9x50 / Strike 3-9x50E | belirtilmemiş | KS |
| Comet | 4x20 | belirtilmemiş | KS, KLAS, EMKA |
| Comet | 4x32 Taktikal ışıklı | belirtilmemiş | ATK |
| Comet | 3-9x32 / 3-9x40 / 3-9x40 EG | belirtilmemiş | KS, KLAS |
| Comet | 4-16x50 / 6-24x50 ışıklı | belirtilmemiş | KS, KLAS |
| Spike | 4x32 ışıklı taktik | belirtilmemiş | ATK, AVCI |
| Spike | 2.5-10x40E / 3-9x32EG | belirtilmemiş | AVCI |
| Spike | 2-6x28 | "Hedef çizgili" (genel ifade) | KS, KLAS |
| Spike | 6-24x50 AOE | belirtilmemiş | KS |
| Nikula / TR-Nikula | 3-9x40E, 3-9x50, 3-9x50E, 3-9x32E, 3.5-10x40, 4x32, 2-6x28, 4-16x50 AOEG, 8-32x50 AOEG | belirtilmemiş | AVCI, KS, KLAS |
| Optima | 3-12x44 AOE, 3-9x32, 4x20 | belirtilmemiş | KS, KLAS |
| Eyebre | 3-9x50 EG, 6-24x50 AOEG | belirtilmemiş | ATK |
| Square | 3-9x50, 5-20x50, 4-14x44 IR, 3-9x44 IR | belirtilmemiş | ZIG |
| Firefield | Barrage 2.5-10x40 | belirtilmemiş | EMKA |
| Huğlu Optics | S4 3-12x40 SFP, 3-18x50 SFP Gen II, S6 1-6x24 LPVO SFP | belirtilmemiş | AKSU |
| T-Eagle | SR 3-9x40 IR, SK 5-25x50 FFP IR, MR 6-24x50 SF FFP | belirtilmemiş | AKSU |
| Swampdeer | GT Pro 1-5x24 IR, TD HD 3-9x40 IR | belirtilmemiş | AKSU |
| Markasız | 4x28, 4x20, 4x32, 3-9x32, 3-7x20, 3-7x28, 3-9x40EG | belirtilmemiş | AVCI |

## 3. Marka özet sayımı (öncelik sırası)

Sıralama önce mağaza sayısına, sonra model sayısına göredir. Sayılar yalnız bu çalışmada okunabilen başlıklara dayanır ve gerçek katalogun alt sınırıdır.

| # | Marka | Model (benzersiz) | Mağaza | Mağazalar |
|---|---|---|---|---|
| 1 | Vortex Optics | 34 | 5 | BM, BZK, AKSU, ZIG, İAM |
| 2 | Barska | 10 | 5 | İAM, ATK, BZK, KS, KLAS |
| 3 | Hawke | 33 | 4 | İAM, BZK, OD, AKSU |
| 4 | Vector Optics (+Paragon) | 35 | 4 | İAM, ZIG, AKSU, KS |
| 5 | Element Optics | 20 | 4 | BM, EMKA, ZIG, AKSU |
| 6 | Bushnell | 12 | 4 | BM, KLAS, İAM, DM |
| 7 | Comet | ~8 | 4 | ATK, KS, KLAS, EMKA |
| 8 | Discovery Optics | 7 | 4 | BM, ZIG, KS, KLAS |
| 9 | Spike | ~7 | 4 | ATK, AVCI, KS, KLAS |
| 10 | Victoptics | 15 | 3 | İAM, AKSU, ZIG |
| 11 | Arken Optics | 12 | 3 | BM, EMKA, ZIG |
| 12 | Nikula / TR-Nikula | ~9 | 3 | AVCI, KS, KLAS |
| 13 | Nutrek Optics | 8 | 3 | BM, EMKA, ZIG |
| 14 | Sig Sauer | 6 | 3 | ATK, İAM, ZIG |
| 15 | BSA | 2 | 3 | BZK, KS, KLAS |
| 16 | GPO | 5 | 2 | BM, AKSU |
| 17 | ASG | 3 | 2 | BZK, KS |
| 18 | Optima | 3 | 2 | KS, KLAS |
| 19 | Meopta | 12 | 1 | BM |
| 20 | 3E (yerli) | 7 | 1 | BM |
| 21 | Square | 4 | 1 | ZIG |
| 22 | Zero Compromise | 3 | 1 | İAM (+ filtrede 13 ürün) |
| 23 | U.S. Optics | 3 | 1 | BM |
| 24 | Huğlu Optics | 3 | 1 | AKSU |
| 25 | T-Eagle | 3 | 1 | AKSU (+ İAM filtresi "TEAGLE" 3) |
| 26 | Athlon | 2 | 1 | AKSU |
| 27 | Primary Arms | 2 | 1 | BM (stok yok) |
| 28 | Swampdeer | 2 | 1 | AKSU |
| 29 | Eyebre | 2 | 1 | ATK |
| 30 | Nightforce, DNT, Riton, Sightmark, Nikon, Gamo, Firefield, Tasco | 1'er | 1 | çeşitli |

İAM marka filtresine göre (başlıklar okunmadan) en büyük stoklar: Vector Optics 163, Hawke 41, Victoptics 38, Barska 19, Sig Sauer 17, Sightmark 17, Bushnell 13, Nikon 13, ZCO 13. Bu sayılar Vector, Hawke ve Victoptics'in TR'deki ağırlığını doğruluyor.

## 4. Satılan benzersiz retikül adları (marka — retikül)

**Not:** Discovery, Nutrek ve Victoptics başlıklarında retikül adı yok. Başlıkta geçen "SFIR", "FFP", "IR" gibi ifadeler özellik etiketidir (yan odak, aydınlatma, odak düzlemi), retikül adı değildir. Aşağıda istenen biçim için ayrı işaretlendi.

**Vortex**
- Vortex — Dead-Hold 2A BDC (MOA)
- Vortex — Dead-Hold BDC (MOA)
- Vortex — AR-BDC3 (MOA)
- Vortex — EBR-8 (MOA)
- Vortex — EBR-8 BDC (MOA)
- Vortex — EBR-8 BDC (MRAD)
- Vortex — EBR-7C (MRAD)
- Vortex — EBR-7C (MOA)
- Vortex — EBR-7B (MRAD)
- Vortex — EBR-4 (MRAD)
- Vortex — EBR-2C (MRAD)
- Vortex — VMR-1 (MRAD)
- Vortex — VMR-2 (MRAD)
- Vortex — VMR-4 (MRAD)
- Vortex — Mil Dot (MOA)
- Vortex — G4i BDC (MRAD)
- Vortex — Horus H59

**Hawke**
- Hawke — Mil Dot
- Hawke — 1/2 Mil Dot
- Hawke — 10x 1/2 Mil Dot (MRAD)
- Hawke — 10x Half-Mil Dot
- Hawke — 20x 1/2 Mil Dot
- Hawke — Half Mil
- Hawke — AMX (IR)
- Hawke — TMX
- Hawke — 30/30
- Hawke — .223/.308 16x
- Hawke — Rimfire .17 HMR 16x
- Hawke — Circle Dot

**Vector Optics**
- Vector — MBR
- Vector — CDM
- Vector — MIL (Tauron/Taurus)
- Vector — MIL PRS (Tauron)
- Vector — MOA (Orion Pro Max FFP)
- Diğer Vector modellerinde başlıkta retikül yok.

**Element Optics**
- Element — APR-1C (MRAD)
- Element — APR-2D (MRAD)
- Element — RAPTR-1 (MRAD)
- Element — RAPTR-1 (MOA)
- Element — RAPTR-1S (MOA)
- Element — MPR-1C (MRAD)
- Element — Duplex (MOA)
- Element — LPR-1D (BDC, MRAD)
- Element — Hibrit Balistik (HYPR-7)

**Arken Optics**
- Arken — VPR (MRAD)
- Arken — TOR (MRAD)
- Arken — VHR (MRAD)
- Arken — KLGRID (MRAD)
- Arken — KLBOX (MOA)
- Arken — DLR (MOA)
- Arken — FDR (MOA)

**Meopta**
- Meopta — RD BDC3 (MRAD)
- Meopta — RD 4C (MRAD)
- Meopta — RD 4C (MOA)
- Meopta — RD K-Dot 2 (MOA)
- Meopta — RD 1 (MRAD)
- Meopta — Z-Plus (MRAD)

**3E**
- 3E — EMR-M10C (MRAD)
- 3E — EMR-M15C (MRAD)
- 3E — EMR-M25D (MRAD)
- 3E — 5.56mm & 2 MOA R1x
- 3E — 7.62mm (AVCI 1-4x)

**GPO**
- GPO — G4i Fiber (MRAD)
- GPO — HSi-CQB (MRAD)

**Bushnell**
- Bushnell — G5I (MRAD)
- Bushnell — Hybrid Dot Tree (MRAD)
- Bushnell — German No. 4 / Alman No. 4
- Bushnell — 4A (A4) aydınlatmalı

**Barska**
- Barska — Mil Dot
- Barska — 30/30

**BSA**
- BSA — Mil-Dot

**Sig Sauer**
- Sig Sauer — BDC (Buckmasters)
- Sig Sauer — Hellfire Quadplex

**Diğer markalar**
- Nightforce — MIL-C (MRAD)
- Zero Compromise — MPCT2 (0.1 MIL)
- Zero Compromise — MPCT1X
- U.S. Optics — GENIIXR (MRAD)
- U.S. Optics — Simple Crosshair / Kırmızı tek nokta (2 MOA)
- DNT — TOR (MRAD)
- Riton — PSR (MRAD)
- Primary Arms — ACSS-5.56/5.45/.308
- Athlon — APRS3 (MIL)
- Athlon — BDC 22 Rimfire
- Sightmark — LR2
- Nikon — NP (Nikoplex)
- Victoptics — CROSSB (arbalet)

**Retikül adı olmayan başlık etiketleri**
- Discovery — SFIR FFP (MRAD)
- Discovery — SFIR SFP (MOA)
- Discovery — SF FFP (MOA)
- Discovery — AOAC SFP (MOA)
- Nutrek — BDC Tree (MRAD). Bu gerçek bir retikül adıdır (Blackiron 6-24, Silvermark).
- Nutrek — diğer modellerde başlıkta yalnız "IR / (MOA)" var, retikül adı belirtilmemiş.

## 5. Retikül önceliği ve 3. tur (TR) sonucu — data/reticles-tr-oncelik

Öncelik = TR'de satıldığı mağaza/model sayısı × bizdeki kaydın eksikliği. Vortex atlandı (açık PR #138, Vortex 3. tur). Ölçüler YALNIZ üretici kaynağından; mağaza, forum, başka uygulama verisi kullanılmadı.

| Sıra | Marka | TR'de satılan retikül(ler) | Bu tur |
|---|---|---|---|
| 1 | Hawke | Mil Dot, 10x Half Mil Dot, Half Mil (10x/20x), FFP Half Mil Dot, AMX, Mil Pro | 4 yeni kayıt (ad/birim/kapsam/odak düzlemi büyütmesi), Mil Dot kapsamı +15 model; sayısal ölçüler: üretici SVG/föyleri robots.txt ile kapalı → null |
| 2 | Vector Optics | MBR, CDM, MIL, MOA; Veyron, Paragon, Forester, Matiz, Hugo, Continental | VPA-2 MIL yeni; VOI/VOW-10BDC, MPR-V10/V5, German #4, VECON CDM, VFD-2 Vector 3. turda (#144) zaten eklendi → o sürüm korundu |
| 3 | Element Optics | APR-1C/2D, RAPTR, MPR-1C, LPR-1D | RAPTR-1S MOA ve LPR-1D MRAD Element 3. turda (#141) zaten eklendi → o sürüm korundu |
| 4 | Bushnell | Deploy, G4P, Drop Zone, Multi-X, German #4 | Drop Zone-22 LR yeni; Multi-X/German #4/DOA QBR üreticide ölçü yok |
| 5 | Discovery | (başlıkta retikül adı yok) | Üretici retikül adı/ölçü vermiyor → kayıt açılmadı |
| 6 | Arken | VPR, TOR, VHR, KLGRID, KLBOX, DLR, FDR | Yeni değer yok (kılavuz PDF metin katmanı boş/konumsuz) |
| 7 | Athlon | APRS3, BDC 22 | BDC22 SFP MOA yeni; APRS3 not güncellemesi |
| 8 | Sig Sauer | Quadplex/Hellfire, BDC | Quadplex, BDC-1, Buckmasters BDC yeni |
| 9 | Barska, BSA | Mil Dot, 30/30 | Barska 30/30 (posts_start 4x'te), Barska Mil Dot, BSA Mil-Dot yeni |
| 10 | Meopta | RD BDC3, RD 4C, K-Dot 2, Z-Plus | MRAD-1 RD, MRAD RD yeni (ad/birim/kapsam); diğerlerinin birimi kaynakta yok → açılmadı |
| 11 | Riton, GPO, DNT | PSR, G4i, HSi-CQB, TOR | 5 yeni kayıt (ad/birim/kapsam) |
| — | Nikon NP, ZCO MPCT, U.S. Optics GEN II XR, 3E EMR | | Üretici kaynağı yok/robots engelli/birim yok → açılmadı |

İnceleme sırasında çıkarılanlar (tahmin yok kuralı): Hawke 30/30 Duplex, 30/30 Centre Cross, Circle Dot, Marksman .223/.308, Rimfire .17 HMR ve Element Duplex — birim yalnız taret klik değerinden çıkarılmıştı; (Vector/Element çakışan kayıtlarda #141/#144 sürümü esas alındı.)
