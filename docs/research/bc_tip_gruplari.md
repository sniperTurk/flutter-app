# BC: tip ve uç şekline göre gruplar (sahip notu, 13 Ekim 2026)

Kaynak: `lib/data/bullet_library.dart` ve `lib/data/factory_ammo_library.dart` içindeki
üretici BC'leri (G1). Hesap: biçim katsayısı i = SD / BC, SD = grain / (7000 · d²).

## Genel tahmin doğruluğu (tüm kütüphane)
| Grup | Kayıt | Hataların yarısı | %75'i | %90'ı |
|---|---|---|---|---|
| Ateşli mermi | 1545 | %16 | %35 | %79 |
| PCP slug | 209 | %13 | %18 | %23 |
| PCP pellet | 45 | %18 | %29 | %39 |

Tahmini BC hatasının düşüşe etkisi (100 m sıfır):
- Ateşli .277 130 gr 3000 fps, %16: 300 m 2–3 cm, 500 m 10–16 cm
- PCP 6,35 mm 50 gr slug 985 fps, %13: 300 m 17–22 cm, 500 m 95–130 cm

## Aile bilgisi hatayı yarıya indiriyor (Hornady, birini dışarıda bırakarak test)
| Yöntem | Yarısı | %90'ı |
|---|---|---|
| Aileye bakmadan | %15 | %71 |
| Aynı aileye göre | %8 | %35 |

Hornady aile biçim katsayıları (G1): ELD Match 0,465 · ELD-X 0,476 · ELD-VT 0,460 · A-TIP 0,438 ·
SST 0,546 · BTHP 0,553 · CX 0,555 · V-MAX 0,560 · FMJ 0,644 · SP 0,666 · InterLock 0,708 ·
FTX 0,743 · HP 0,827 · MonoFlex 0,844 (2 kayıt) · Sub-X 0,980.

## .270 Win · 7,04 mm · 130 gr fabrika fişekleri, tipe göre (en yakın yüzdeler)
| Tip | Ortalama G1 | Marka farkı |
|---|---|---|
| Plastik uçlu / sivri (9 fişek) | 0,448 | hepsi ±%3 içinde |
| Klasik yumuşak uçlu (12) | 0,359 | +%14 … −%37 (uç şekli adda yok) |
| Bakır / kurşunsuz (10) | 0,379 | +%21 … −%24 |
| Sivri bakır (7) | 0,37–0,42 (Trophy Copper 0,459) | çoğu ±%6 |
| Boş uçlu bakır (2) | 0,287 | 0 |
| Ağır av | 1 fişek (Partition 0,416) | karşılaştırılamaz |

Aynı malzemede uç şekli farkı: boş uçlu bakır 0,287 ↔ sivri bakır 0,37–0,46 (%40'a kadar).

## .277 130 gr mermiler (21 mermi, 11 marka)
- Plastik uçlu / sivri: 0,43–0,49
- Klasik yumuşak uçlu: 0,37–0,41
- Bakır: 0,37–0,46
- Ağır av (küt uç): 0,32–0,35
- Hornady: SST 0,460 (grup ort. +%3), InterLock 0,409 (Woodleigh ile aynı), CX 0,403 (Barnes TTSX +%3, TSX +%8)

## Karar
Tahmin kuralı: önce birebir aynı mermi (çap + ağırlık + aile), yoksa aynı marka + aynı aile,
yoksa aynı tip + uç şekli grubu, en son genel tahmin. Her durumda ekranda "tahmini".
Eksik: fişeklerin çoğunda uç şekli adda yazmıyor; üretici sayfalarından toplanacak.
