# Kahles — retikül raporu (2026-10-12)

**Sonuç:** 5 yeni kayıt, 2 düzeltilmiş kayıt, 13 dürbün düzeltmesi (retikül adı boş olan 13 dürbünün hepsi dolduruldu).

## Eklenen kayıtlar (`reticles/`)
| id | ad | birim | kaynak |
|---|---|---|---|
| kahles-4-dot-mil | 4-Dot | mil | verwaltung.kahles.at/.../Dokumente/4-Dot.pdf |
| kahles-g4b-mil | G4B | mil | .../Dokumente/G4B.pdf |
| kahles-3gr-mil | 3GR | mil | .../2026_all_FW/3GR_K18i-2.PDF (ayrıca 3GR_K18i.PDF, 3GR_K16i.pdf) |
| kahles-ipsc-mil | IPSC | mil | .../2026_all_FW/IPSC_K18i.PDF |
| kahles-sm1-mil | SM1 | mil | .../2026_all_FW/SM1_K16i.pdf |

- Föyler yalnız harf etiketli (A–I) ölçüler veriyor. Harflerin hangi öğeye ait olduğu yalnız çizimde görülüyor, bu yüzden bu kayıtların hepsinde `family` ve geometri alanları null.
- 4-Dot, G4B ve IPSC föylerinde açısal birim yok, ölçüler yalnız cm/100 m. Bu kayıtlarda `unit` dürbünün taret birimi (mil) ve notes'ta bu açıkça yazılı. 3GR ve SM1 föyleri "Mil" etiketi taşıyor.
- 3GR için üç föy var (K18i-2, K18i, K16i) ve bir ölçüde farklılar (K18i-2'de 8m/1m, K18i'de 6,4m/0,8m). Ad anahtarı aynı ve geometri zaten null olduğu için tek kayıt yapıldı. Farklar notes'ta yazılı.

## Düzeltilen mevcut kayıtlar (aynı id, tam dosya)
- `kahles-moak-k1050`: `name` "MOAK (K1050)" → "MOAK". `notes` alanına düzeltme notu eklendi.
- `kahles-moak-plus-k864`: `name` "MOAK+ (K864)" → "MOAK+". `notes` alanına düzeltme notu eklendi.
- Neden: parantez içindeki model adı anahtara katılıyordu ("MOAKK1050"), bu yüzden üretici adı "MOAK" / "MOAK+" eşleşmiyordu. Diğer alanlar değişmedi.

## Doldurulan retikül adları (`scope_changes.json`)
Ürün sayfalarındaki "RETICLES / SUBTENSIONS" bölümünden alındı:
- Helia 1.6-8x42i, Helia 2-10x50i, Helia 3 3-10x50i → "4-Dot"
- Helia 2.4-12x56i, Helia 3.5-18x50i, Helia 3 4-12x44i → "4-Dot / G4B"
- K864 → "MOAK+"; K1050 → "MOAK"
- K328i Refined → "SKMR4+ / SKMR+ / MSR2/Ki"; K318i Refined → "SKMR4 / MSR2/Ki"
- K18i 2 → "3GR"; K18i → "3GR / IPSC"; K16i → "3GR / SM1 / SI1"

Eşleşme simülasyonu (mevcut kütüphane + bu çıktı): 13 dürbünün 12'si "eslesti".

## Birim farkı
- **K16i / SI1:** SI1 föyündeki bütün açısal değerler MOA (15/10/5/1 MOA). Mevcut `kahles-si1-k16i` kaydı moa olarak doğru. K16i'nin tareti ise ".1 MRAD", bu yüzden bu seçenek "birim-farki" olarak kalıyor (durum "kismi"). Bu üreticinin kendi tercihi; mil kaydı oluşturulmadı.
- Not: G4B föyünde K16i sütunu var, ama güncel K16i sayfası G4B'yi seçenek olarak listelemiyor.

## Okunamayan
Yok. Bütün sayfalar ve PDF'ler okundu.
