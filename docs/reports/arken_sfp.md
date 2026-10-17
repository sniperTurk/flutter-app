# Arken Optics SFP dürbünleri (OUTRIDER 2-12x42, OUTRIDER 3-18x50, LH-6 1-6x24)

Sahip, 2026-10-17 17:59–18:01 (İstanbul): Dürbün → Arken Optics → MRAD yalnız FFP gösteriyor (doğru; Arken MRAD SFP dürbün listelemiyor). Üç Arken SFP dürbünün katalogda olmadığı düşünüldü. Sahip: "ekle".

## Önemli bulgu: üç kayıt zaten katalogdaydı

`lib/data/scope_library.dart` dosyasında üç kayıt da **2026-10-15'ten beri (#318) vardı**:

- `lib-arken-optics-outrider-2-12x42-sfp`: OUTRIDER 2-12x42 SFP
- `lib-arken-optics-outrider-3-18x50-sfp`: OUTRIDER 3-18x50 SFP
- `lib-arken-optics-lh-6-1-6x24-sfp`: LH-6 1-6x24 SFP

Son TestFlight (main 2101b3f) de bunları içeriyor. Uygulamada Arken Optics → **MOA** → SFP seçilince listede görünmeleri gerekir; MRAD seçilince görünmemeleri doğrudur (üçü de yalnız MOA). İkinci bir kopya eklemedim, çünkü aynı dürbün listede iki kez çıkardı. Bunun yerine şunları yaptım:

1. Her değeri bugün üretici sayfalarından ve kılavuzdan yeniden okudum; hepsi kayıttakiyle aynı çıktı.
2. Okuma tarihini 2026-10-17 yaptım.
3. Listenin bu üç modeli gerçekten verdiğini test ve simülatör görüntüsüyle kanıtlıyorum.

## Ne değişti

- `data/scopes/arken_optics.json`: üç kayıtta `accessed` 2026-10-17 oldu ve notlar güncellendi. Hiçbir sayı değişmedi.
- `lib/data/scope_library.dart`: yalnız bu üç satır değişti. Değerler aynı kaldı; yalnız `sourceDocument` "… official manufacturer page, read 2026-10-17" oldu. Üretici betiğini (`tools/data_gen/generate_scope_library.py`) bütün dosya için çalıştırmadım. Betik bu ağaçta zaten dosyayla uyuşmuyor (Athlon'da 74 satır, ör. retikül adları); tamamını üretmek kapsam dışı değişiklik getirirdi. Bu yüzden betiğin bu üç kayıt için ürettiği satırları birebir aldım.
- `lib/data/reticle_library.dart`: **değişmedi.** FDR, DLR ve KLBOX bağlantıları zaten çalışıyor: `ReticleCatalog.find` OUTRIDER'larda `arken-fdr-moa` / `arken-dlr-moa`, LH-6'da `arken-klbox-moa` kaydını buluyor. Bunu yeni test ve mevcut `test/reticle_scope_match_test.dart` doğruluyor. KLBOX kaydının `scopes` listesinde "LH-6 1-6x24 SFP LPVO" yazıyor; eşleşme ad ve birim üzerinden yapıldığı için ad düzeltmesi gerekmedi.
- Hiçbir arayüz ya da hesap kodu değişmedi. Başka marka da yok.

## Kayıtlar ve kaynaklar (okuma: 2026-10-17)

MOA → mrad dönüşümü mevcut MOA kayıtlarıyla aynı: × π/10,8, iki ondalık. İnç × 25,4 = mm; ons × 28,35 = g.

### 1. OUTRIDER 2-12x42 SFP

Kaynak: https://www.arkenopticsusa.com/products/outrider-2-12x42-sfp-illuminated-fdr-non-illuminated-dlr-30mm-tube

| Alan | Değer | Üretici alıntısı |
|---|---|---|
| Büyütme | 2–12 | "Magnification: 2-12x" |
| Objektif | 42 mm | "Objective Lens Diameter: 42 mm" |
| Tüp | 30 mm | "Tube Size: 30 mm" |
| Odak | SFP (`firstFocalPlane:false`) | "Focal Plane: SFP (Second Focal Plane)" |
| Klik | 0,25 MOA | "Turret Adj.: 0.25 MOA" (tur: "15 MOA") |
| Yükseliş | 26,18 mrad | "Elevation Adj. Range: 90 MOA" |
| Yan | 23,27 mrad | "Windage Adj. Range: 80 MOA" |
| Uzunluk | 307,3 mm | "Length: 12.1 in" |
| Ağırlık | 674,7 g (FDR) | "Weight: DLR 22.4 oz / FDR 23.8 oz" |
| Zero stop | false | "Zero Stop: No" |
| Retikül | FDR / DLR | "Reticle: FDR / DLR" |

### 2. OUTRIDER 3-18x50 SFP

Kaynak: https://www.arkenopticsusa.com/products/outrider-3-18x50-sfp-illuminated-fdr-non-illuminated-dlr-30mm-tube

| Alan | Değer | Üretici alıntısı |
|---|---|---|
| Büyütme | 3–18 | "Magnification: 3-18x" |
| Objektif | 50 mm | "Objective Lens Diameter: 50 mm" |
| Tüp | 30 mm | "Tube Size: 30 mm" |
| Odak | SFP | "Focal Plane: SFP (Second Focal Plane)" |
| Klik | 0,25 MOA | "Turret Adj.: 0.25 MOA" (tur: "15 MOA") |
| Yükseliş | 16,29 mrad | "Elevation Adj. Range: 56 MOA" |
| Yan | 13,96 mrad | "Windage Adj. Range: 48 MOA" |
| Uzunluk | 365,8 mm | "Length: 14.4 in" |
| Ağırlık | 827,8 g (FDR) | "Weight: DLR 28.2 oz / FDR 29.2 oz" |
| Zero stop | false | "Zero Stop: No" |
| Retikül | FDR / DLR | "Reticle: FDR / DLR" |

İki OUTRIDER'da da diğer Arken kayıtlarındaki gibi tek kayıt ve FDR (aydınlatmalı) ağırlığı kullanıldı. DLR ağırlığı notta duruyor.

### 3. LH-6 1-6x24 SFP (yalnız MOA)

Kaynaklar:
- `sourceDocument`: https://www.arkenopticsusa.com/products/lh-6-1-6x24-sfp-lpvo-illum-klbox-30mm-tube. Kayıttaki her değeri bu sayfa açıkça yazıyor.
- Karşılaştırma için: https://arkenoptics.com/products/lh-6-1-6x24-sfp-lpvo-illum-klbox-30mm-tube ve kılavuz https://documents.arkenopticsusa.com/view/426599322

| Alan | Değer | Üretici alıntısı |
|---|---|---|
| Büyütme | 1–6 | "Magnification: 1-6x"; kılavuz "1X-6X" |
| Objektif | 24 mm | "Objective Lens Diameter: 24 mm"; kılavuz "24mm" |
| Tüp | 30 mm | "Tube Size: 30 mm"; kılavuz "30mm" |
| Odak | SFP | "Focal Plane: SFP (Second Focal Plane)"; kılavuz aynı |
| Klik | 0,25 MOA | "Turret Adj.: 0.25 MOA"; kılavuz "1/4 MOA" |
| Tur | 25 MOA | "Adj. Per Revolution: 25 MOA"; kılavuz "25 MOA" |
| Yükseliş | 52,36 mrad | "Elevation Adj. Range: 180 MOA"; kılavuz "180 MOA" |
| Yan | 52,36 mrad | "Windage Adj. Range: 180 MOA"; kılavuz "180 MOA" |
| Uzunluk | 269,2 mm | "Length: 10.6 in"; kılavuz 10.64'' (uyumlu) |
| Ağırlık | 572,7 g | "Weight: 20.2 oz"; kılavuz "20.16 oz." (uyumlu) |
| Zero stop | false | "Zero Stop: No" (arkenoptics.com ve kılavuz bundan söz etmiyor) |
| Retikül | KLBOX | kılavuz "BDC Style - KLBOX"; arkenoptics.com "BDC (Bullet Drop Compensator) - KLBOX" |

**Sayfalar arasındaki tutarsızlıklar:**
- **Klik birimi:** arkenoptics.com "Turret Adjustment: 0.1 MIL / 0.25 MOA" diyor. Ama sayfada tek varyant var ("KL BOX"). arkenopticsusa.com "0.25 MOA" ve "KLB-MOA", kılavuz "1/4 MOA" ve "25 MOA" tur diyor. Üretici açıkça bir MIL sürümü sunmadığı için **MIL LH-6 eklenmedi.**
- **Ağırlık:** arkenopticsusa.com "20.2 oz" ve kılavuz "20.16 oz." uyumlu; yalnız arkenoptics.com "20.6 oz" diyor. Kayıttaki 20.2 oz (572,7 g) korundu, aykırı değer notta. Ağırlık hesapta kullanılmıyor.
- Kılavuzun ilk satırı "Welcome to the ARKEN OPTICS LH-4 Product Manual." diyor; başlık ve tablo LH-6. Bu bir yazım hatası.

## Boş bırakılan alanlar

- Yeni boş alan yok. Uygulamanın dürbün kaydında paralaks alanı yok; veri dosyasında `parallax_min_m`, sabit paralakslı OUTRIDER 2-12x42 ve LH-6'da (100 yd) mevcut kurala göre null.

## Testler

- Yeni `test/arken_sfp_katalog_test.dart`:
  - Katalog: Arken SFP kayıtları tam olarak bu üç model. Büyütme, objektif, tüp, 0,25 MOA klik, MOA→mrad aralıklar, zero stop, retikül listesi (FDR, DLR / KLBOX) ve 2026-10-17 kaynağı doğru. Her retikül adı Arken MOA çizim kaydını buluyor. LH-6 ağırlığı 572,7 g. Arken'de MRAD SFP kaydı yok.
  - Gerçek Profil ekranında Marka Arken Optics → Birim MOA → Odak SFP:
    - Tüp listesi [30 mm].
    - Büyütme listesi [1-6x, 2-12x, 3-18x].
    - Model listesinde tam bu üç model var.
    - Her model seçilince Retikül listesi doğru (OUTRIDER: FDR, DLR; LH-6: KLBOX) ve "Dürbün:" satırında "2-12x42 SFP" / "3-18x50 SFP" / "1-6x24 SFP" görünüyor.
  - Arken Optics → MRAD: Odak düzlemi listesi yalnız FFP; modellerin hiçbiri SFP değil.
- Yerel:
  - `python3 tools/offline_dart_lint.py`: PASS, 435 dosya, 0 sorun.
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: 915 test OK (1 skip). Veri ve kaynak denetimleri de bunun içinde.
- Bu ortamda Flutter SDK motoru indirilemiyor (storage.googleapis.com engelli). Bu yüzden Dart testleri ve biçim denetimi yalnız CI'da çalışır; sonuçlar "CI" bölümünde.

## Ekran görüntüsü

`integration_test/arken_sfp_screens_test.dart` (sim-screens, iPhone 16e, 390 pt) şu ekranları çekiyor:
- Arken Optics / MOA / SFP, model listesi açık
- OUTRIDER 2-12x42 seçili, Retikül listesi açık
- Arken / MRAD, Odak düzlemi listesi açık

Görüntüler PR'a yorum olarak eklenir.

## CI

PR açıklamasında ve PR yorumlarında güncellenir. Çalışmayan ya da kırmızı biten hiçbir iş yeşil diye bildirilmez.

## Bilerek yapılmayan

- İkinci (yinelenen) kayıt eklenmedi.
- MIL LH-6 eklenmedi.
- Başka marka, arayüz ya da hesap değişikliği yapılmadı.
- `scope_library.dart` bütünüyle yeniden üretilmedi.
- TestFlight başlatılmadı, birleştirme yapılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01KLFrpgBvwx8qwqxV2SkYuH
