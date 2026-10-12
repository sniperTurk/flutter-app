# Diabolo saçma sürüklenme tablosu — bilimsel kaynak araştırması ve karşılaştırma

Tarih: 2026-10-12 · Zamanlanmış görev (sahibi çevrimdışı) · Dal: `feat/sacma-surukleme`

## Kısa sonuç

- Diabolo saçmanın Cd–Mach eğrisini PCP hız aralığında (≈ 200–330 m/s, Mach 0,58–0,97)
  **sayısal olarak ölçüp yeniden kullanıma izin veren** bilimsel kaynak **bulunamadı**.
  Hakemli ölçümler var, ama hepsi tek bir hızda (Mach ≈ 0,57–0,58) veya yalnızca grafikte.
- Görevdeki kural gereği ("Belirsizse EKLEME") **yeni tablo uygulamaya eklenmedi**.
  `lib/` altında hiçbir dosya değişmedi; G1/G7 (ve GA) sonuçları bit düzeyinde aynı.
- Önemli bulgu: mevcut GA tablosu PCP bölgesinde **G1'in yaklaşık 0,93 katı** (Mach 0,3–0,7
  arası oran 0,929–0,935; Mach 0,9'da 0,963). Yani GA, ses altında neredeyse ölçeklenmiş
  bir G1'dir. BC atışla/kronografla eşlendiğinde G1 ile GA arasındaki fark 100 m'ye kadar
  **en fazla 0,1 cm** (aşağıdaki tablolar).
- Aynı BC değeri girildiğinde G1, GA'ya göre 100 m'de 1,3–3,6 cm daha fazla düşüş ve
  2,2–5,0 cm daha fazla rüzgâr sürüklenmesi verir; bu farkın kaynağı eğrinin biçimi değil,
  ölçeğidir (BC_G1 ≈ BC_GA × 1,07).
- **Öneri:** GA'yı uygulamadan kaldırın; kayıtlı GA profillerini BC × 1,07 ile G1'e çevirin
  (seçenekler §5). Bilimsel bir ses altı Cd–Mach ölçümü yayımlanırsa yeniden değerlendirilir.

## 1. Bulunan kaynaklar ve değerlendirme

| Kaynak | Yöntem | Hız / Mach | Saçma | Belirsizlik | Lisans / yeniden kullanım | Karar |
|---|---|---|---|---|---|---|
| Ladommatos N. "Influence of air rifle pellet geometry on aerodynamic drag", Proc. IMechE Part P (2019/2021), doi:10.1177/1754337119831107 — UCL kabul edilmiş metin: https://discovery.ucl.ac.uk/id/eprint/10072258 | Düşük türbülanslı açık rüzgâr tüneli, yük hücresi + yüzey basıncı; saçma sabit, dönmüyor | Tek nokta: Mach 0,58 (≈ 200 m/s), Re ≈ 54 000 | 4,5 mm gerçek boy: küre, kubbe, düz, konik, oyuk başlı | Yük hücresi Cd hatası %4,2, tekrarlanabilirlik %1,3 | "Green open access"; kabul edilmiş metin "yayıncının şart ve koşulları altında" yeniden kullanılabilir; CC lisansı yok | Tek Mach noktası → eğri kurulamaz. Olgu olarak rapora alındı: kubbe başlı Cd 0,422; düz 0,561; konik 0,668; oyuk 0,714; küre 0,510 (Tablo 3) |
| Ladommatos N. "Drag coefficients of air rifle pellets with wide range of geometries", Proc. IMechE Part C (2021), doi:10.1177/0954406221991190 | Aynı rüzgâr tüneli | 200 m/s (Mach 0,57); üç saçmada 120–200 m/s | 31 saçma, çoğu 4,5 mm | Özette yok | Abonelikli, "© IMechE 2021"; CC yok | Sayısal tablo okunamadı. Özetten olgu: Cd 0,36–0,78 aralığında; 120→200 m/s hız artışı Cd'yi "çok az" etkiliyor |
| Rafeie M., Teymourtash A.R. "Aerodynamic and dynamic analyses of three common 4.5 mm-caliber pellets in a transonic flow", Scientia Iranica B 23(4) 2016, https://scientiairanica.sharif.edu/article_3924.html | **Hesaplamalı** (2-B eksenel simetrik Navier–Stokes, Jameson); kendi deneyi yok | Ses altı–üstü (M 0,7 / 1,0 / 1,3 gösteriliyor) | 4,5 mm wadcutter, sivri, yuvarlak burun (marka yok) | Belirtilmemiş | "© 2016 Sharif University of Technology. All rights reserved." | Ölçüm değil; Cd yalnızca grafikte; tüm hakları saklı → EKLENMEDİ |
| Courtney E., Courtney A., Courtney M. "Methods for Accurate Free Flight Measurement of Drag Coefficients", arXiv:1503.05504 | İki kronograf, serbest uçuş (iş-enerji) | ≈ 480–790 ft/s (Mach 0,43–0,71) | 4,5 mm Crosman/Daisy saçmaları, BB | BC için SEM verilmiş | arXiv; açık lisans ibaresi yok | Saçma Cd'si yalnızca grafikte; tablo yalnızca G1 BC → eğri kurulamaz |
| Courtney E., Morris C., Courtney M. "Accurate Measurements of Free Flight Drag Coefficients with Amateur Doppler Radar", arXiv:1608.06500 | LabRadar Doppler | BB: Mach 0,3–0,5 | **Saçma yok** (yalnız çelik BB ve mermiler) | SEM | Açık lisans ibaresi yok | Diabolo içermiyor |
| McCoy R.L. "MC DRAG", BRL ARBRL-TR-02293 (1981), https://apps.dtic.mil/sti/pdfs/ADA098110.pdf | Yarı ampirik tahmin programı | Mach 0,5–5 | Saçma/etekli gövde yok | Ses altı ≈ %6 | Açık yayın | Diabolo geometrisini kapsamıyor → kullanılmadı |
| Frank M. ve ark., Int. J. Legal Med. 127 (2013) doi:10.1007/s00414-013-0904-x; Int. J. Legal Med. (2016) doi:10.1007/s00414-016-1415-3 | Adli balistik hız ölçümü | — | 4,5 mm saçmalar | — | Abonelikli (Springer) | 2013: Cd/BC verisi yok. 2016 makale sayfası hız sınırı (HTTP 429) nedeniyle **okunamadı**; ayrıca abonelikli |

Aranan ama bulunamayanlar: diabolo saçma için devlet/askerî açık rapor (DTIC), üniversite
Doppler/kıvılcım menzili ölçümü, saçma üreticisinin kendi yayımladığı Cd–Mach ölçümü
(JSB, H&N, RWS, FX, Air Arms, Hatsan — yalnızca tek BC yayımlıyorlar).
Yasak kaynaklar (ChairGun, Strelok, AB, JBM, QuickLOAD, GRT, forum, blog, bayi, dergi
köşe yazıları) taranmadı/kullanılmadı.

## 2. Neden tablo kurulmadı

1. **Kapsam:** PCP saçması namludan Mach 0,8–0,95 ile çıkar; bu bölgede Cd hızla değişir.
   Hakemli ölçümlerin hepsi Mach ≤ 0,58'de. Mach 0,6–1,0 arasını doldurmak tahmin olur.
2. **Yöntem:** Rüzgâr tüneli verisi dönmeyen, sabit saçmadan; serbest uçuşta yalpa ve dönme
   Cd'yi değiştirebilir. Tek noktadan eğri biçimi çıkmaz.
3. **Lisans:** Hiçbirinde açık (CC-BY/CC0) lisans yok. Tek sayılar olgu olarak alıntılanabilir,
   ama eğri kurmaya yetmiyor.
4. **Biçim, ölçek değil, önemli:** Uygulamada BC ile birlikte yalnızca Cd(Mach) eğrisinin
   *biçimi* sonucu belirler. Ladommatos'un mutlak Cd'leri (0,42–0,71) GA/G1 ölçeğinden farklı
   (0,19–0,20); bu, BC ile emilir. Elimizdeki tek biçim bilgisi "120–200 m/s arası Cd neredeyse
   sabit" — bu da G1 ve GA'nın (Mach 0,35→0,58 arası ≈ %6 düşüş) biçimiyle aynı büyüklükte bir
   fark; aşağıdaki "Sabit Cd" duyarlılık sütunu bunun etkisini gösterir.

## 3. Mevcut GA ile G1'in biçim karşılaştırması

| Mach | GA Cd | G1 Cd | GA / G1 |
|---:|---:|---:|---:|
| 0,30 | 0,207 | 0,2214 | 0,935 |
| 0,40 | 0,196 | 0,2104 | 0,932 |
| 0,50 | 0,189 | 0,2032 | 0,930 |
| 0,58 | 0,189 | 0,2026 | 0,933 |
| 0,70 | 0,202 | 0,2165 | 0,933 |
| 0,80 | 0,241 | 0,2546 | 0,947 |
| 0,90 | 0,329 | 0,3415 | 0,963 |

(PCHIP ara değer, `tools/formula_reference.py` ile.) GA ses altında G1'in sabit bir katı;
Mach 0,8 üstünde oran biraz artıyor (GA ses geçişine biraz daha erken yükseliyor).

## 4. Karşılaştırma: 10–100 m düşüş ve rüzgâr sürüklenmesi (cm)

Üretim: `python3 tools/sacma_surukleme_karsilastirma.py` (aynı denklemler: ICAO hava, düz atış,
Coriolis yok). Testler bu bloğun aşağıya birebir gömüldüğünü denetler.

- **GA düşüş / sürüklenme:** mevcut GA tablosu, verilen BC ile.
- **G1−GA:** aynı BC ile G1 (yeni varsayılan) eksi GA.
- **G1 eşlenmiş−GA:** G1 BC'si, 50 m'deki hız GA ile aynı olacak şekilde ayarlandı (kullanıcı BC'yi
  kronografla ölçtüğünde olan budur).
- **Sabit Cd−GA:** yalnızca **duyarlılık** senaryosu, uygulamaya eklenecek bir tablo değil: Cd tüm
  Mach'larda GA'nın Mach 0,58'deki değerine sabit (Ladommatos 2021'in "hız Cd'yi az etkiliyor"
  gözlemi, ölçülmemiş bölgeye uzatılmış hâli). Eğri biçiminin ne kadar önemli olabileceğinin üst
  sınırına yakın bir örnek.

<!-- sacma_surukleme_karsilastirma.py: başlangıç -->

.177 / 4,5 mm, 8,44 gr, 280 m/s — BC 0,021, sıfır 30 m, nişan 50 mm, rüzgâr 4 m/s soldan, G1 eşlenmiş BC 0,0225

| Menzil m | GA düşüş cm | G1−GA cm | G1 eşlenmiş−GA cm | Sabit Cd−GA cm | GA sürüklenme cm | G1−GA cm | G1 eşlenmiş−GA cm | Sabit Cd−GA cm |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 1,8 | 0,0 | 0,0 | +0,1 | 0,6 | 0,0 | 0,0 | -0,1 |
| 20 | 0,1 | 0,0 | 0,0 | +0,1 | 2,3 | +0,1 | 0,0 | -0,4 |
| 30 | 0,0 | 0,0 | 0,0 | 0,0 | 5,1 | +0,3 | 0,0 | -0,9 |
| 40 | 1,9 | +0,1 | 0,0 | -0,2 | 9,0 | +0,6 | -0,1 | -1,4 |
| 50 | 5,9 | +0,2 | 0,0 | -0,4 | 14,1 | +1,0 | -0,1 | -1,9 |
| 60 | 12,3 | +0,5 | 0,0 | -0,9 | 20,5 | +1,5 | -0,1 | -2,5 |
| 70 | 21,6 | +0,9 | 0,0 | -1,4 | 28,1 | +2,1 | -0,1 | -3,1 |
| 80 | 34,0 | +1,5 | 0,0 | -2,2 | 37,1 | +2,9 | 0,0 | -3,7 |
| 90 | 49,9 | +2,4 | 0,0 | -3,1 | 47,7 | +3,8 | 0,0 | -4,4 |
| 100 | 69,8 | +3,6 | 0,0 | -4,2 | 59,8 | +5,0 | 0,0 | -5,1 |

.22 / 5,5 mm, 18,13 gr, 270 m/s — BC 0,035, sıfır 30 m, nişan 50 mm, rüzgâr 4 m/s soldan, G1 eşlenmiş BC 0,0374

| Menzil m | GA düşüş cm | G1−GA cm | G1 eşlenmiş−GA cm | Sabit Cd−GA cm | GA sürüklenme cm | G1−GA cm | G1 eşlenmiş−GA cm | Sabit Cd−GA cm |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 1,8 | 0,0 | 0,0 | 0,0 | 0,3 | 0,0 | 0,0 | -0,1 |
| 20 | 0,1 | 0,0 | 0,0 | 0,0 | 1,4 | +0,1 | 0,0 | -0,2 |
| 30 | 0,0 | 0,0 | 0,0 | 0,0 | 3,0 | +0,2 | 0,0 | -0,5 |
| 40 | 1,6 | 0,0 | 0,0 | -0,1 | 5,4 | +0,3 | 0,0 | -0,8 |
| 50 | 5,1 | +0,1 | 0,0 | -0,2 | 8,4 | +0,6 | 0,0 | -1,1 |
| 60 | 10,6 | +0,3 | 0,0 | -0,5 | 12,1 | +0,8 | 0,0 | -1,4 |
| 70 | 18,4 | +0,5 | 0,0 | -0,8 | 16,5 | +1,2 | 0,0 | -1,8 |
| 80 | 28,4 | +0,8 | 0,0 | -1,2 | 21,6 | +1,6 | 0,0 | -2,2 |
| 90 | 41,0 | +1,2 | 0,0 | -1,7 | 27,5 | +2,0 | 0,0 | -2,6 |
| 100 | 56,3 | +1,7 | 0,0 | -2,3 | 34,1 | +2,6 | 0,0 | -3,0 |

.22 / 5,5 mm, 18,13 gr, 300 m/s — BC 0,035, sıfır 30 m, nişan 50 mm, rüzgâr 4 m/s soldan, G1 eşlenmiş BC 0,0371

| Menzil m | GA düşüş cm | G1−GA cm | G1 eşlenmiş−GA cm | Sabit Cd−GA cm | GA sürüklenme cm | G1−GA cm | G1 eşlenmiş−GA cm | Sabit Cd−GA cm |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 10 | 2,1 | 0,0 | 0,0 | +0,1 | 0,4 | 0,0 | 0,0 | -0,1 |
| 20 | 0,4 | 0,0 | 0,0 | +0,1 | 1,5 | +0,1 | 0,0 | -0,5 |
| 30 | 0,0 | 0,0 | 0,0 | 0,0 | 3,3 | +0,2 | 0,0 | -1,0 |
| 40 | 1,1 | 0,0 | 0,0 | -0,2 | 5,8 | +0,3 | 0,0 | -1,7 |
| 50 | 3,8 | +0,1 | 0,0 | -0,5 | 8,9 | +0,5 | 0,0 | -2,4 |
| 60 | 8,2 | +0,2 | 0,0 | -0,9 | 12,7 | +0,7 | 0,0 | -3,2 |
| 70 | 14,5 | +0,3 | 0,0 | -1,6 | 17,2 | +1,0 | 0,0 | -4,0 |
| 80 | 22,9 | +0,6 | 0,0 | -2,4 | 22,4 | +1,3 | 0,0 | -4,9 |
| 90 | 33,4 | +0,9 | 0,0 | -3,4 | 28,3 | +1,7 | 0,0 | -5,9 |
| 100 | 46,2 | +1,3 | 0,0 | -4,7 | 34,8 | +2,2 | +0,1 | -6,9 |

<!-- sacma_surukleme_karsilastirma.py: bitiş -->

Okuma: aynı BC'de G1, GA'dan biraz daha fazla düşüş/sürüklenme verir (100 m'de en çok +3,6 cm
düşüş, +5,0 cm sürüklenme, .177 hafif saçmada). BC eşlendiğinde fark ≤ 0,1 cm — yani GA'nın
sağladığı bir doğruluk kazancı yok; tek etkisi BC'nin ölçeği. Düz Cd varsayımı ise ters yönde
(daha az düşüş) 2–7 cm fark verir; bu bölgenin gerçekten ölçülmemiş olması, herhangi bir
"saçma tablosunun" G1'den daha doğru olduğunu iddia etmeyi bugün olanaksız kılıyor.

## 5. Sahip için karar seçenekleri (GA)

Bu PR GA'ya dokunmaz. Seçenekler ve etkileri:

| Seçenek | Ne olur | Kayıtlı GA profilleri |
|---|---|---|
| **A. GA'yı kaldır (öneri)** | `BallisticModel.ga`, tablo, "GA saçma" liste seçenekleri ve `gaUnverified` uyarısı kaldırılır; forum kaynaklı veri uygulamadan çıkar. | Kayıtta `bcModel: "ga"` olan profil şu an `user_catalog.dart` `_ballisticModel` ile **null** modele düşer → BC modeli boş kalır ve profil hesaplanamaz (fail-closed). Bu yüzden kaldırma, bir **göç** ile yapılmalı: okurken `ga` → `g1` ve BC × 1,07 (§3 oranı, 0,933⁻¹), kullanıcıya bir kez "GA kaldırıldı, BC G1'e çevrildi, atışla doğrulayın" notu. 100 m'de fark ≤ 0,1 cm (eşlenmiş sütun). |
| B. GA'yı kaldır, göç yok | Kod en basit. | GA profilleri BC modelsiz kalır, kullanıcı yeniden seçmek zorunda; yanlış BC ile G1 seçerse 100 m'de 1–4 cm fark. Önerilmez. |
| C. GA'yı bırak | Hiçbir sonuç değişmez. | Etkilenmez. Ama kaynak kuralına aykırılık sürer; uyarı metni zaten "Strelok'tan alınan kopya" diyor. |
| D. Bilimsel tablo bekle | Şimdilik C; Mach 0,5–1,0'ı kapsayan açık lisanslı ölçüm çıkınca yeni model eklenir. | Etkilenmez. |

Not: G1/G7 ve diğer BRL tabloları bu seçeneklerin hiçbirinde değişmez.

## 6. Uygulamaya etkisi (bu PR)

- `lib/` değişmedi → ekran, G1/G7/GA sonuçları aynı; ekran görüntüsü gerekmedi.
- Eklenenler: bu rapor, `tools/sacma_surukleme_karsilastirma.py` (karşılaştırma),
  `tools/test_sacma_surukleme_karsilastirma.py` (7 test), plan
  `docs/superpowers/plans/2026-10-12-sacma-surukleme.md`.
- Görevdeki "font Oswald": ana dalda #173 ile yazı karakteri Inter; bu işte UI değişmediği için
  dokunulmadı.

Kaynaklara erişim tarihi: 2026-10-12.
