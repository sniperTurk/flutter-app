# Swarovski dürbün raporu (2026-10-12)

**Eklenen kayıt: 10** (kısmi — WebFetch 429 hız sınırı nedeniyle tamamlanamadı)

- Z8i / Z8i+ (8): Z8i+ 5-40x56 P, Z8i+ 1-8x24, Z8i 2.3-18x56 P, Z8i 2-16x50 P, Z8i 3.5-28x50 P, Z8i 1.7-13.3x42 P, Z8i+ 0.75-6x20, Z8i 1-8x24
- Z6i (2): Z6i 4-24x56 P BT, Z6i 2.5-15x50 P (BT seçeneği notta)

## Dönüşümler / eksikler
- Klik "10 mm/100 m" (0.36 in/100 yds) = 1 cm/100 m → click_unit "mrad", 0.1. Ayar aralığı "m/100 m" → ×10 mrad.
- Odak düzlemi hiçbir ürün sayfasında yazmıyor → focal null (tümü).
- zero_stop sayfalarda açık değil → null.
- Sayfaların teknik tablosunda etiket/değer hizası kaymış; değerler birimlerine göre eşleştirildi (notlarda).
- Ağırlık çelişkili/eşleşmesiz → null: Z8i+ 5-40x56 P (890 g tablo vs 850 g açıklama), Z8i+ 1-8x24 (599/620 g), Z8i+ 0.75-6x20 (590/615 g).
- Paralaks sayfada yok → null: Z8i+ 1-8x24, Z8i+ 0.75-6x20, Z8i 1-8x24.
- Z8i+ 1-8x24 ve 0.75-6x20'de ayar tek değer "2 / 72" → yükseliş=yan=20 mrad kabul edildi (notta).
- Retikül adları sayfadaki gibi (4A-I, 4A-IF, BRX-I, 4W-I, LD-I, BRT-I, D-I). Repoda Swarovski retikül listesi verilmedi.

## Okunamayan / yapılamayan (HTTP 429, proxy "bu sayfayı tekrar çekme" dedi)
- https://www.swarovskioptik.com/int/en/hunting/products/rifle-scopes/z6-i/z6i-1-7-10x42/z6i-1-7-10x42-ii
- https://www.swarovskioptik.com/int/en/hunting/products/rifle-scopes/z6-i/z6i-1-6x24/z6i-1-6x24-ii
- https://www.swarovskioptik.com/int/en/hunting/products/rifle-scopes?family=x5i (X5(i) listesi)
- Çekilmeye sıra gelmeyenler: Z6i 2.5-15x56 P, dS 4-24x50 P (Gen III), Z5 3.5-18x44 P (+BT), Z5+/Z5i+ 2-10x42, 3.5-18x50, 5-25x56 (BT ve BT'siz), Z3 3-10x42, Z3 4-12x50 (+BT), X5(i) serisi. Liste sayfası "32 products" diyor, 30'u görüldü.
- tM35 termal → kapsam dışı.

## Kaynaklar
- https://www.swarovskioptik.com/int/en/hunting/products/rifle-scopes (liste). İlk denenen https://www.swarovskioptik.com/int/en/hunting/products/riflescopes fetch hatası verdi.
- Ürün sayfaları: kayıtların source_url alanında (8 Z8i + 2 Z6i sayfası).
