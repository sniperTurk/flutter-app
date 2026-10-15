# Meopta — retikül raporu (2026-10-12)

**Sonuç:** 8 yeni kayıt (eksik 8 ad/birim çifti), 0 dürbün düzeltmesi.

## Eklenen kayıtlar (`reticles/`)
| id | ad | birim | dürbünler |
|---|---|---|---|
| meopta-4c-mil | 4C | mil | MeoHunter R5 3-15x50 / 4-20x50 SFP RD |
| meopta-4c-moa | 4C | moa | MeoPro R6 1-6x24, 2.5-15x44, 3-18x56, 4.5-27x50 SFP RD |
| meopta-bdc-3-mil | BDC 3 | mil | MeoHunter R5 3-15x50 / 4-20x50 SFP RD |
| meopta-bdc-3-moa | BDC 3 | moa | MeoPro R6 1-6x24 / 3-18x56 SFP RD |
| meopta-z-plex-moa | Z-Plex | moa | MeoPro R5 2-10x42, R6 2.5-15x44 / 3-18x50 SFP |
| meopta-z-plus-moa | Z-Plus | moa | MeoPro R5 2-10x42 SFP |
| meopta-k-dot-2-moa | K-Dot 2 | moa | MeoPro R6 1-6x24 SFP RD |
| meopta-mrad-1-rd-mil | MRAD 1 RD | mil | MeoPro R6 3-18x50 / 4.5-27x50 FFP RD |

Kaynaklar: meoptasportsoptics.eu/files/reticle/reticle-*.pdf, MeoHunter_R5_EN.pdf, MeoPro_R6_EN.pdf, katalog_2026_EN.pdf ve katalog_2025_EN.pdf.

- **Geometri yok:** Üretici retikül föyleri (reticle-4C.pdf, reticle-BDC-3.pdf, reticle-KDot-2.pdf, reticle-MRad1-RD.pdf, reticle-ZPlex.pdf, reticle-ZPlus.pdf) yalnız görsel içeriyor. WebFetch "empty or contains no machine-readable text" döndü. Bu yüzden 8 kaydın hepsinde `family` ve geometri alanları null. Kayıtlar eşleşmeyi sağlar, çizim genel ızgarayla yapılır.
- **Birim kararları:**
  - MeoHunter R5 kılavuzu ölçü tablolarını yalnız cm/100m ve mRad ile veriyor, bu yüzden 4C/BDC 3 için mil kaydı.
  - MeoPro R5/R6 SFP dürbünlerde üretici açısal ölçü yayımlamıyor. Bu kayıtlarda `unit` taret birimi (moa) ve notes'ta "ölçü yok; birim taret birimi" yazılı.
  - MRAD 1 RD adında MRAD geçiyor ve taret MRAD, bu yüzden mil.
- **MeoHunter R5 tabloları:** Kılavuzdaki mRad tabloları ("Applies at 6x", "Applies at 7x / all magnifications") metin çıkarımında hiçbir retikül adına bağlanamadı. Bu yüzden kayıtlara geometri olarak girilmedi.

## Karar verilemeyen retikül adları (5 dürbün)
- **MeoHunter R5 3-15x50 FFP RD ve 5-25x56 FFP RD:** Kılavuz matrisi "4C BDC3" sütunlu ve FFP satırlarında tek "•" var. Metin çıkarımında sütun hizası kayboluyor, hangi retikül olduğu okunamıyor. Katalog (EN 2026/2025) ve DE kılavuz da modeli açıkça bağlamıyor.
- **MeoPro R5 3-15x44 SFP, 4-20x44 SFP ve 4-20x50 SFP RD:** Katalog retikül listesi "Z PLEX, BDC 3, Z PLUS". Dipnotlar yalnız 2-10x42 satırlarını bağlıyor ("* with Z-PLUS reticle", "** with Z-PLEX reticle"). Bu üç model için açık eşleme yok.
- meoptasportsoptics.eu'da ürün sayfası bulunamadı. Site yalnız katalog ve kılavuz sunuyor ve `allowed_domains` ile yapılan aramalarda ürün sayfası çıkmadı.

## Okunamayan
- Retikül föyü PDF'leri (yukarıdaki 6 dosya): metin katmanı yok, yalnız görsel.
- Katalog ve kılavuz tabloları: PDF metin çıkarımında sütun hizası bozuk. Okundular ama model–retikül eşlemesi çıkarılamadı.
