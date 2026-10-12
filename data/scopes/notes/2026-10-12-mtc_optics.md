# MTC Optics: dürbün veri raporu (2026-10-12)

**Eklenen: 18 kayıt**
- Viper Pro: 3-18x50, 5-30x50, 3-18x50 Tactical, 5-30x50 Tactical (MOA)
- Viper Connect: 3-12x32 (MOA), 4-16x32 (MRAD)
- MambaLite: 3-12x42, 4-16x42 (MOA)
- Mamba UltraLite: 3-10x40 PA, 3-10x40 sabit paralaks (MOA)
- Copperhead F2: 3-12x44, 4-16x44 (MRAD)
- King Cobra: 4-16x50 F1, 6-24x50 F1, 4-16x50 F2, 6-24x50 F2, 8-32x50 F1 (MRAD; 8-32 için 0.05 mrad klik)
- SWAT Prismatic 10x30 'Atom' (MRAD, büyütmeli prizmatik dürbün)

## Kaynaklar
- https://mtcoptics.com/ (menü), https://mtcoptics.com/riflescopes/ (kategori)
- Ürün sayfaları: /viper-pro/, /viper-connect/, /viper-connect-4-16x32/, /mambalite/, /mamba-ultralite/, /copperhead-f2/, /king-cobra-f1/, /king-cobra-4-16-x-50-f1/, /king-cobra-4-16x50-f2/, /king-cobra-6-24-x-50-f2/, /king-cobra-8-32-x-50-f1/, /swat-prismatic-10x30-atom/

## Eklenmeyenler
- **Cobra F1 4-16x50** (https://mtcoptics.com/cobra-f1/): sayfa var (2021) ama güncel menüde ve kategoride yok, güncel olduğu teyit edilemedi. Bu yüzden eklenmedi. Sayfadaki değerler: FFP, 30 mm, 1 cm@100 m klik, 140 cm@100 m, paralaks 15 m, 344 mm, 834 g.
- **SWAT Prismatic 12x50 'Mini'**: yalnız metinde anılıyor, sayfa açılamadı (fetch hatası).
- **Taipan:** yalnız eski site arşivinde (old.mtcoptics.com), güncel değil. **Rapier** dürbün değil, lazer mesafe ölçer.

## Sorunlar / eksik alanlar
- **Klik birimi:** MOA modellerde `1/4″ @ 100 yards` yazıyor; MOA aralıkları ve tur başına MOA değerleriyle tutarlı olduğu için 0.25 moa girildi. Mil modellerde `1cm @100m` yazıyor ve açıklama MIL diyor, 0.1 mrad girildi. Birkaç sayfada çelişkili ikinci bir değer var (ör. 0.73 cm, "1cm" ile "1/4″" birlikte); ayrıntı notlarda.
- **Taret aralığı:** çoğu sayfada tek bir "Max turret adjustment" değeri var. Bu değer elevation alanına yazıldı, windage null bırakıldı. Değer cm@100m olarak verildiyse mrad'a çevrildi (116 cm = 11.6 mrad).
- **Paralaks:** spec tablosu genelde "10m" diyor, özellik listesi "10 yards". Spec tablosundaki değer kullanıldı ve çelişki notlara yazıldı. Viper Connect 3-12x32 spec tablosu "10yds" diyor, 9.1 m girildi.
- **Zero stop:** hiçbir sayfada yok, null. Viper Pro Tactical ağırlıkları ayrı verilmiş; diğer değerleri standart modelin tablosundan alındı.
