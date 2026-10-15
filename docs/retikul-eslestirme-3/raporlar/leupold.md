# Leupold — retikül raporu (okundu 2026-10-12)

Kaynak yalnız www.leupold.com (retikül sayfaları, ürün sayfaları, /media/binaryanvil/reticle/*.pdf föyleri).

## Eklenen kayıtlar (23)
| id | ad | birim | kaynak |
|---|---|---|---|
| leupold-pr1-moa-ffp-moa | PR1-MOA FFP | moa | /reticle/pr1-moa-ffp/ + FFP_PR1-MOA_1.pdf |
| leupold-illum-pr1-moa-moa | Illum. PR1-MOA | moa | /reticle/pr1-moa-illum-ffp/ + föy |
| leupold-illum-pr1-mil-mil | Illum. PR1-MIL | mil | /reticle/pr1-mil-illum-ffp/ + föy |
| leupold-illum-tmr-mil | Illum. TMR (FFP, TMR (Mk) Illum.) | mil | /reticle/tmr-mk-illum-ffp/ + föy |
| leupold-tmr-illum-sfp-mil | TMR Illum. SFP | mil | Mark 4HD 2.5-10x42 M5C3 SFP ürün sayfası + Illum._TMR.pdf |
| leupold-illum-cmr-mil-mil | Illum. CMR-Mil | mil | /reticle/CMR-MIL-Illum-FFP/ + föy |
| leupold-h59-mil | H59 | mil | /reticle/h59/ |
| leupold-illum-tremor-3-mil | Illum. Tremor 3 | mil | /reticle/tremor-3-illum-ffp/ |
| leupold-illum-gunwerks-rh1-moa-moa | Illum. Gunwerks RH1 MOA | moa | /reticle/RH1-MOA-Illum-FFP/ + föy |
| leupold-tmoa-plus-moa | TMOA Plus | moa | /reticle/tmoa-plus/ + föy |
| leupold-illum-pr2-mil-mil | Illum. PR2-MIL | mil | ürün sayfası ...-ffp-illum-pr2-mil |
| leupold-illum-pr3-mil-mil | Illum. PR3-MIL | mil | ürün sayfası ...-ffp-illum-pr3-mil |
| leupold-illum-pr2-moa-moa | Illum. PR2-MOA | moa | ürün sayfası ...-ffp-illum-pr2-moa |
| leupold-hpr-1-moa | HPR-1 | moa | /reticle/hpr-1/ + föy |
| leupold-illum-firedot-tmr-mil | Illum. FireDot TMR | mil | /reticle/fire-dot-tmr-illum/ + föy |
| leupold-illum-firedot-4-fine-mil | Illum. FireDot 4 Fine | mil (taret birimi) | /reticle/firedot-4-fine-illum/ + föy |
| leupold-illum-firedot-twilight-hunter-moa | Illum. FireDot Twilight Hunter | moa | /reticle/firedot-twilight-hunter-illum/ + föy |
| leupold-htmr-mil | HTMR (HTMR-MIL de bu anahtara düşer) | mil | /reticle/htmr/ + föy |
| leupold-ultimateslam-moa | UltimateSlam | moa | /reticle/ultimateslam/ + föy |
| leupold-rimfire-moa-moa | Rimfire MOA | moa | /reticle/rimfire-moa/ + föy |
| leupold-illum-tmoa-moa | Illum. TMOA | moa | /reticle/tmoa-illum/ + föy |
| leupold-illum-firedot-boone-crockett-moa | Illum. FireDot Boone & Crockett | moa | /reticle/firedot-illum-boone-crockett/ + föy |
| leupold-illum-cm-r2-moa | Illum. CM-R2 | moa | /reticle/cm-r2-illum/ + ürün sayfası + föy |

Kayıt adları dürbün kayıtlarındaki yazımla (ör. "Illum. PR1-MOA") aynı anahtara düşecek şekilde seçildi; üreticinin retikül sayfası adı (ör. "PR1-MOA Illum. FFP") notlarda.
Mevcut kayıtlarda değişiklik yok.

## PR1-MOA birim-farki kararı
Neden: marka yalnız `leupold-pr1-mil-ffp` (PR1-MIL FFP, mil) kaydına sahipti; "PR1-MOA" adı MOA taretli (M1C3) dürbünlerde geçiyor.
Leupold ayrı bir MOA retikülü yayımlıyor: https://www.leupold.com/reticle/pr1-moa-ffp/ ("PR1-MOA FFP Reticle"; 'MOA based grid', '1 MOA increments',
'40 MOA of measurement in each direction', 'Front (first) focal plane'), föy FFP_PR1-MOA_1.pdf (Mark 4HD, Mark 5HD; ince 0.15 / orta 0.5 / kalın 1.0 MOA).
Karar: yeni kayıt `leupold-pr1-moa-ffp-moa` (unit moa, hash_step 1.0, extent_h/v_up/v_down 40, family null — PR1-MIL ile tutarlı). Anahtar (PR1, moa)
dört dürbünle eşleşir: Mark 5HD 2-10x30 / 3.6-18x44 / 5-25x56 M1C3 FFP, Mark 4HD 2.5-10x42 M1C3 FFP. Mil kaydı değiştirilmedi.

## Dürbün düzeltmesi (scope_changes.json, 1)
- Mark 4HD 2.5-10x42 M5C3 SFP: "Illum. TMR" -> "TMR Illum. SFP". Ürün sayfası SFP ve "Detailed reticle info: TMR Illum. SFP" diyor; aynı "Illum. TMR"
  adı FFP dürbünlerde başka bir retikül (TMR (Mk) Illum. FFP). Düzeltme uygulanmazsa bu SFP dürbün FFP `Illum. TMR` kaydıyla eşleşir.

## Karar verilemeyen
- Illum. FireDot BDC (Mark 4HD 1-4.5x24 SFP, MOA taret): BİRİM-FARKI. Ürün sayfası "Reticle: Illum. FireDot Bullet Drop", tek föy
  (Illum_FireDot_BDC_Reticle_Spec_Sheet.pdf) "Mark 3HD" için ve tüm değerler MIL; MOA sürümü yok. Kayıt oluşturulmadı.

## Çıkarım içeren alanlar (notlarda işaretli)
TMOA Plus ve Illum. TMOA extent_h=10 ('each side' yatay); FireDot 4 Fine ve Twilight Hunter family=duplex; H59 / Illum. Tremor 3 family=tree;
FireDot 4 Fine unit=mil (föy yalnız 'UNITS: MOA' yazıyor, sayı yok; Metric dürbünler mrad taretli -> taret birimi kuralı).

## Okunamayanlar
- https://www.leupold.com/reticle/TMR Illum. SFP/, /reticle/Illum. FFP PR2-Mil/, /reticle/Illum. FFP PR2-MOA/, /reticle/Illum. FFP PR3-Mil/
  (boşluklu adresler; hem ham hem %20 kodlu deneme "Shop By Reticle" liste sayfasına düştü). Yerine ürün sayfaları kullanıldı.
- Illum. PR2/PR3 ürün sayfalarında föy PDF yok (yalnız JPEG).
- Illum._TMR.pdf ve Illum_FireDot_Boone_Crockett.pdf / Illum_CM-R2.pdf: araç tam metni vermedi, yalnız değer listesi/özet; değer-etiket eşlemesi yapılmadı.
