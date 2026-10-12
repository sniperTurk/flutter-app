# Sig Sauer — retikül raporu (okuma 2026-10-12)

## Eklenen kayıtlar (16)
| id | ad | birim | ana kaynak |
|---|---|---|---|
| sig-sauer-dwlr6-mil | DWLR6 | mil | TANGO6T kılavuzu (tango6t-7401308-R06.pdf) |
| sig-sauer-dwlr-556-mil | DWLR-556 | mil | TANGO6T kılavuzu |
| sig-sauer-762-extended-range-mil | 762 Extended Range | mil | TANGO6T kılavuzu |
| sig-sauer-hellfire-fl-6-mil | HELLFIRE FL-6 | mil | TANGO6T kılavuzu |
| sig-sauer-hellfire-m855a1-mil | HELLFIRE M855A1 | mil | TANGO6T kılavuzu |
| sig-sauer-hellfire-moa-milling-moa | HELLFIRE MOA Milling | moa | TANGO6T kılavuzu |
| sig-sauer-5-56-7-62-horseshoe-dot-moa | 5.56/7.62 Horseshoe Dot | moa | TANGO6T kılavuzu ("Subtensions in MOA") |
| sig-sauer-mrad-milling-mil | MRAD Milling | mil | TANGO6 4-24 sayfası, Tango6-Manual.pdf |
| sig-sauer-mrad-dev-l-mil | MRAD DEV-L | mil | TANGO6 4-24 sayfası, Tango6-Manual.pdf |
| sig-sauer-mrad-milling-2-0-mil | MRAD Milling 2.0 | mil | BRAVO6T ve TANGO-DMR kılavuzları |
| sig-sauer-mrad-dev-l-2-0-mil | MRAD DEV-L 2.0 | mil | BRAVO6T ve TANGO-DMR kılavuzları |
| sig-sauer-moa-milling-2-0-moa | MOA Milling 2.0 | moa | TANGO-DMR kılavuzu |
| sig-sauer-moa-dev-l-2-0-moa | MOA DEV-L 2.0 | moa | TANGO-DMR kılavuzu |
| sig-sauer-quadplex-moa | Quadplex | moa (duplex) | WHISKEY4 kılavuzu + ürün sayfaları |
| sig-sauer-bdc-1-moa | BDC-1 | moa | WHISKEY4 kılavuzu + ürün sayfaları |
| sig-sauer-moa-milling-hunter-2-0-moa | MOA Milling Hunter 2.0 | moa | WHISKEY4 kılavuzu + ürün sayfası |

Sig kılavuzlarındaki ölçü çizimleri metin katmanında konumsuz sayı dizisi olarak geliyor; hiçbir sayı öğeye eşlenmedi, hash_step vb. null (değerler notlarda).

## Doldurulan / düzeltilen retikül adları (scope_changes.json, 5)
- TANGO-DMR 5-30X56MM (FFP) [boştu] -> "MRAD Milling 2.0 / MRAD DEV-L 2.0" (DMR kılavuzu 9.1/9.6 notları).
- TANGO-DMR 5-30X56MM (FFP) MOA [boştu] -> "MOA Milling 2.0 / MOA DEV-L 2.0" (DMR kılavuzu 9.3/9.5).
- TANGO6 5-30X56MM (FFP) [boştu] -> "MRAD Milling / MRAD DEV-L" (ürün sayfası ad vermiyor; ondan bağlı Tango6-Manual.pdf teknik tablosu 5-30x56 için MOA/MRAD Milling ve MOA/MRAD DEV-L listeliyor; 3-18/4-24 blokları aynı dört retikülü taşıdığı için MRAD taret -> MRAD olanlar). Kanıt kılavuz tablosu; tablo metni sütunsuz geliyor, bu yüzden gözden geçirilmeli.
- WHISKEY4 2.5-10X42MM ILLUMINATED (SFP): "HELLFIRE Quadplex" -> "Quadplex" (ürün sayfası teknik tablo "Reticle: Quadplex"; HELLFIRE aydınlatma sistemi adı).
- WHISKEY4 3-12X44MM EXPOSED ZERO STOP, ILLUMINATED (SFP): "BDC-1 Hellfire" -> "BDC-1" (sayfa: "Simplified second focal BDC-1 reticle"); aydınlatmasız "BDC1" aynı anahtar.

## Karar verilemeyen
- **5.56/7.62 Horseshoe Dot (TANGO6T FFP, MRAD taret):** Üretici kılavuzu retikülü açıkça MOA ile veriyor ("556/762 HORSESHOE DOT SUBTENSIONS — Subtensions in MOA", "100 Yard Zero"; Tango6 kılavuzu da ".5 MOA"). Kayıt MOA olarak eklendi; dürbün MRAD taretli olduğundan eşleşme **birim-farki** olarak kalıyor. Kayıt MIL'e çevrilmedi (uydurma olurdu).

## Okunamayan / sorunlu
- https://www.sigsauer.com/tango6t-1-6x24-mm.html — ilk denemede izin isteği zaman aşımı (PROVENANCE_REQUIRED); 2. denemede okundu.
- TANGO6 5-30x56 ve TANGO-DMR ürün sayfalarında retikül adı yok (yalnız görsel).
