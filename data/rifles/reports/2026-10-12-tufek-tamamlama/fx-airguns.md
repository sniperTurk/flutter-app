# FX Airguns (İsveç) — veri toplama raporu

## Neden seçildi
FX Airguns, Türkiye'de en yaygın üst segment PCP markalarından biri (Impact, Crown, Dreamline, Wildcat, Panthera). Mevcut `fx-airguns.json` boştu (`[]`).

## Sonuç
- **43 kayıt** eklendi: 10 model × resmi yapılandırıcıdaki kalibreler. Namlu uzunluğu bilinmediği için her kayıt bir kalibreyi temsil ediyor.
  - Impact M4: 4.5 / 5.5 / 6.35 / 7.62 / 9.0 mm
  - Crown MKII: 4.5 / 5.5 / 6.35 / 7.62 mm
  - Dreamline: 4.5 / 5.5 / 6.35 / 7.62 mm (220 cc, 230 bar)
  - Wildcat MKIII: 4.5 / 5.5 / 6.35 / 7.62 mm
  - Panthera MKII: 4.5 / 5.5 / 6.35 / 7.62 mm
  - Dynamic MKII: 4.5 / 5.5 / 6.35 / 7.62 / 9.0 mm
  - King: 4.5 / 5.5 / 6.35 / 7.62 / 9.0 mm (250 bar, kılavuzdan)
  - Leopard (tüp): 4.5 / 5.5 / 6.35 / 7.62 mm
  - Leopard Bottle: 4.5 / 5.5 / 6.35 / 7.62 mm (890 cc)
  - DRS MKII Classic: 4.5 / 5.5 / 6.35 / 7.62 mm

## Önemli kısıt
fxairguns.com (Umbraco), varyant bazındaki teknik tabloyu (namlu uzunluğu, toplam boy, ağırlık, şarjör, enerji, atış sayısı) yalnızca JavaScript yapılandırıcısıyla yüklüyor. Statik HTML'de "No matching variant found" yazıyor. Karşılaştırma sayfası (/comparison/) da boş geliyor. curl üretici alan adına kapalı (proxy 403), web.archive.org da engelli. Kılavuz PDF'lerinde (Impact M4, Crown MKII, Dreamline, Wildcat MKIII, Panthera/Dynamic/King, eski Impact) teknik tablo yok; yalnızca boş "kendi ayarlarınız" şablonları ve basınç sınırları var.
Bu yüzden namlu uzunluğu, ağırlık, boy, şarjör, enerji, hız ve yiv **tüm kayıtlarda null**. Tahmin yapılmadı. Bayi ve dergi değerleri kullanılmadı.

## Bulunamayan veya eklenmeyen modeller
- Impact M3, Maverick, Streamline, Indy, Bobcat, Boss, Typhoon, Wildcat MkIV, Dreamline alt sürümleri: güncel resmi menüde yok. Legacy sayfalarında da spesifikasyon tablosu JS'e bağlı, bu yüzden eklenmedi.
- DRS MKII Tactical ve Pro: sayfalar bütçe nedeniyle açılmadı.
- Yiv oranı: FX yalnızca "STX Superior / Smooth Twist" liner adını veriyor, sayısal değer yok.
- Panthera MKII ve Dynamic MKII sayfalarındaki "200+ ft/lbs potansiyel" bir pazarlama ifadesi, kalibreye bağlı değil. energy_j null bırakıldı.

## Kaynaklar (tamamı resmi)
- https://www.fxairguns.com/rifles/
- https://www.fxairguns.com/comparison/
- https://www.fxairguns.com/rifles/fx-impact-m4/
- https://www.fxairguns.com/media/qlkcvvrf/fx-impact-m4.pdf
- https://www.fxairguns.com/rifles/fx-crown-mkii/
- https://www.fxairguns.com/media/edzn4fkp/fx-crown-mkii-2023.pdf
- https://www.fxairguns.com/rifles/fx-dreamline/
- https://www.fxairguns.com/media/dccduptp/fx-dreamline-2020.pdf
- https://www.fxairguns.com/rifles/fx-wildcat-mkiii/
- https://www.fxairguns.com/media/xcdm0viq/fx-wildcat-mkiii-2020.pdf
- https://www.fxairguns.com/rifles/fx-panthera-mkii/
- https://www.fxairguns.com/rifles/fx-dynamic-mkii/
- https://www.fxairguns.com/rifles/fx-king/
- https://www.fxairguns.com/media/1oeet50f/fx-panthera-2023-3.pdf
- https://www.fxairguns.com/rifles/fx-leopard/
- https://www.fxairguns.com/rifles/fx-drs-mkii-classic/
- https://www.fxairguns.com/legacy-rifles/fx-panthera/
- https://www.fxairguns.com/legacy-rifles/fx-drs-tactical/
- https://www.fxairguns.com/accessories/barrels/barrel-kits/
- https://fxairguns.com/wp-content/uploads/2019/02/Fx_impact_manual_ok.pdf

## Öneri
Gerçek bir tarayıcıyla (JS çalıştırarak) yapılandırıcıdan "Specifications" ya da "data sheet" çıktısı alınırsa namlu, boy, ağırlık, şarjör ve enerji değerleri resmi kaynaktan doldurulabilir.
