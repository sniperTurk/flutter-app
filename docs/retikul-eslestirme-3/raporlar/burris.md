# Burris — retikül raporu (okundu 2026-10-12)

Kaynak yalnız www.burrisoptics.com (retikül sayfaları /reticles/*, ürün sayfaları, kullanıcı kılavuzu PDF'leri).

## Eklenen kayıtlar (15)
| id | ad | birim | kaynak |
|---|---|---|---|
| burris-scr-2-xtr-ps-mil | SCR 2 XTR PS | mil | /reticles/scr-2tm-xtr-ps-reticle + XTR PS kılavuzu |
| burris-horus-tremor5-mil | Horus TREMOR5 | mil | /reticles/horus-tremor5 |
| burris-ballistic-e3-moa | Ballistic E3 (Illuminated dahil) | moa | /reticles/ballistic-e3tm, /reticles/ballistic-e3 + Signature HD kılavuzu |
| burris-fine-plex-moa | Fine Plex | moa | /reticles/fine-plex + Signature HD kılavuzu |
| burris-6-5-creedmoor-moa | 6.5 Creedmoor | moa | /reticles/65-creedmoor + Signature HD kılavuzu |
| burris-plex-moa | Plex | moa | /reticles/plex + Signature HD kılavuzu |
| burris-rc-moa-moa | RC-MOA | moa | /reticles/rc-moa, /reticles/rc-moa-0 |
| burris-3pw-moa-moa | 3PW-MOA | moa | /reticles/3pw-moa, /reticles/3pw-moa-0 |
| burris-fiber-dot-plex-moa | Fiber Dot Plex | moa (taret birimi; ölçü yok) | /reticles/fiber-dot-plex |
| burris-rct-moa-moa | RCT-MOA | moa | /reticles/rct-moa + ürün sayfası |
| burris-c4-wind-moa-illuminated-moa | C4 Wind MOA Illuminated | moa | /reticles/c4-wind-moa-illuminated |
| burris-wind-ret-illuminated-moa | Wind Ret-Illuminated | moa | /reticles/wind-ret-illuminated |
| burris-wind-ret-moa | Wind Ret | moa | /reticles/wind-ret |
| burris-heavy-plex-moa | Heavy Plex | moa (taret birimi; ölçü yok) | /reticles/heavy-plex |
| burris-3p-4-moa | 3P#4 | moa (taret birimi; ölçü yok) | /reticles/3p4 |

"Ballistic E3" ve "Ballistic E3 Illuminated" eşleştiricide aynı anahtar (ILLUMINATED atılır); iki üretici sayfasının metni ve kılavuz tablosu aynı
olduğundan tek kayıt. "6.5 Creedmoor" Signature HD'de FFP, Fullfield IV'te RFP (aynı ad, tek kayıt; notta belirtildi).
Mevcut kayıtlarda değişiklik yok. Dürbün düzeltmesi yok (scope_changes.json boş).

## Karar verilemeyen (kayıt yok)
- Ballistic Plex E1 MV (Fullfield E1 6.5-20x50mm, MOA taret): BİRİM-FARKI. Fullfield E1 kılavuzu tablo başlığı "Reticle Subtensions (in Mils)".
- X96 (Eliminator 5, MOA taret): BİRİM-FARKI. Eliminator 5 kılavuzu "At full magnification the dots are MILs spaced at one MIL apart."
- Ballistic 5X (RT-6 1-6x24mm, 1/2 MOA taret): BİRİM-FARKI. Retikül sayfası "Versatile tactical reticle with milliradian measurements."
  (RT-6 ürün sayfası ayrıca "Ballistic AR mil reticle" diyor.)
- X177 Eliminator 6 Reticle: birim yazılı değil (sayfa "1/5 MOA precision", kılavuz "1/6 MOA accuracy" — yalnız doğruluk ifadesi, retikül ölçüsü değil).
- Plex 350 Legend Ballistics: sayfada ve Fullfield E1 kılavuzunda birim/ölçü yok; BDC retikül olduğundan taret birimi kuralı uygulanmadı.

## Çıkarım içeren alanlar
Plex/Fine Plex/Heavy Plex/Fiber Dot Plex/3P#4 family=duplex (adlardan/tanımdan); Horus TREMOR5 family=tree; C4 Wind extent_h=10 ('each side', rüzgâr ekseni).

## Okunamayanlar
Yok (tüm istenen sayfalar açıldı). Veracity ve Fullfield kılavuzları ölçü tablosu içermiyor ("For detailed reticle subtentions visit our website").
