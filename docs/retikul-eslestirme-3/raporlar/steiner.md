# Steiner — retikül raporu (okuma 2026-10-12)

## Eklenen kayıtlar (14 yeni + 1 düzeltme)
| id | ad | birim | ana kaynak |
|---|---|---|---|
| steiner-str-mil-mil | STR MIL | mil (FFP, tree, 0.2) | steiner-optics.com/reticles/str-mil, H6Xi kılavuzu |
| steiner-mhr-moa | MHR | moa (FFP, duplex) | H6Xi kılavuzu, /reticles/mhr-reticle |
| steiner-mhr-rfp-moa | MHR (RFP) | moa (SFP, duplex) | /reticles/mhr-rfp-reticle, H6Xi kılavuzu |
| steiner-msr2-mil | MSR2 | mil | /reticles/msr2, /reticles/msr2-mil, M5Xi sayfası, T6Xi kılavuzu |
| steiner-tremor-3-mil | Tremor 3 | mil (tree, 0.2) | /reticles/tremor-3 |
| steiner-p3tr-moa | P3TR | moa | Reticle Guide PDF, P4Xi kılavuzu |
| steiner-kc-1-mil-mil | KC-1 MIL | mil (hash, 0.5) | /reticles/kc-1-mil |
| steiner-scr-moa-moa | SCR MOA | moa | /reticles/scr-moa, T6Xi sayfası, Predator 8 kılavuzu |
| steiner-scr-2-mil | SCR 2 | mil | /reticles/scr-2 |
| steiner-e3-moa | E3 | moa | Predator 4 / Predator 8 kılavuzları |
| steiner-epredator-e3-illuminated-moa | ePredator E3 Illuminated | moa (ölçü yok; taret birimi) | /reticles/epredator-e3tm-illuminated |
| steiner-4ai-illuminated-moa | 4Ai Illuminated | moa (ölçü yok; taret birimi) | /reticles/4ai-illuminated, Reticle Guide |
| steiner-4a-i-mil | 4A-I | mil (cm/100 m) | steiner.de Ranger 4 kılavuzu |
| steiner-4a-i-fiber-dot-mil | 4A-I fiber dot | mil (cm/100 m) | steiner.de Ranger 6/8 sayfa ve kılavuzları |

Düzeltilen mevcut kayıt: `steiner-msr-mil` — yalnız `scopes` ([] -> M5Xi 3-15x50, M5Xi 5-25x56; /reticles/msr "MSR Products") ve `notes` (ek + kaynaklar) değişti.

## Dürbün düzeltmeleri (scope_changes.json, 2)
- M5Xi 5-25x56: "MSR2 / MSR [mil]" -> "MSR2 / MSR" (ürün sayfası: Compatible Reticles MSR2, MSR, H59).
- T6Xi 2.5-15x50 MRAD: "SCR [mil]" -> "SCR™ - MIL" (ürün sayfası). Anahtar SCR/mil -> mevcut `steiner-scr-mil` (Reticle Guide'daki MIL tabanlı SCR) ile eşleşir. Varsayım: kılavuzdaki "SCR" ile "SCR™ - MIL" aynı retikül (SCR sayfasında ürün listesi yok, SCR™-MIL sayfası açıklamasız).

## Kararlar
- **SCR MOA (birim-farki):** Steiner ayrı bir "SCR MOA" retikülü yayımlıyor (ayrı sayfa, MOA hash marks, Predator 8 4-32x56 ve T6Xi 2.5-15x50) -> MIL kaydı değiştirilmedi, yeni MOA kaydı eklendi. Predator 8 kılavuzundaki SCR harf tablosu (MOA, 32x) öğeye eşlenemediği için yalnız notta.
- **MSR2 / MSR2 - MIL:** Aynı anahtara (MSR2/mil) düşüyor; tek kayıt, beş dürbün. Birim MIL: T6Xi adı "MSR2 - MIL", M5Xi/M7Xi yalnız MRAD (çıkarım notta belirtildi).
- **4A-I (mil) ve 4Ai Illuminated (moa)** aynı ad anahtarı, farklı birim -> çakışma yok. steiner.de ölçüleri cm/100 m (=0.1 mrad) olduğu için mil.
- Tremor 3, SCR 2, 4A-I artık Steiner markasıyla kayıtlı (önceden yalnız başka markada vardı).
- Harfli ölçü tabloları (E3, MHR, 4A-I, SCR) metinde öğeye eşlenmediğinden sayısal alanlara yazılmadı; değerler notlarda.

## Okunamayan / sorunlu
- https://www.steiner-optics.com/reticles — CLIENT_ERROR (yerine /resources/reticle-guide kullanıldı).
- MSR2, MSR2 - MIL, SCR, SCR™ - MIL retikül sayfalarında açıklama metni yok (yalnız görsel).
- Simülasyon: bu marka için eksik retiküllerin tümü düzeltmelerle eşleşiyor.
