# data/rifles — toplama notları

## 2026-10-11 ateşli tüfek turu (PR #76)

Kaynak kuralı: yalnızca üreticinin kendi sayfası, PDF kataloğu/föyü veya resmi basın bülteni.
Tahmin yok; bilinmeyen alan `null`. WebFetch istekleri tek tek, aralarında ~20 sn.

Erişim kısıtı: bu ortamda WebFetch yalnızca arama sonucunda (WebSearch) görünen URL'leri
açabiliyor. Üretici sitelerindeki çoğu model sayfası arama dizininde yok; bu yüzden bir
markada yalnızca aramada çıkan sayfalar alınabildi. Hiç 429 alınmadı.

Varsayımlar / dönüşümler:
- `magazine_capacity`: şarjör kapasitesi (hazne hariç; "4+1" → 4).
- mm cinsinden hatve inçe çevrildi (Anschütz, `mm/25.4`). lb/oz → kg, inç → mm çevrildi.
- Weatherby "Barrel OAL" sütunu 2" namlu frenini içeriyor; `barrel_length_mm` frensiz namlu.
- Föy namlu/ağırlığı kalibreye değil konfigürasyona (T3/T3 Mag, S/M) bağlıyorsa namlu ve
  ağırlık `null` bırakıldı (Tikka T3 Hunter Stainless, T3 Lite Adjustable, Sako A7 Synthetic).
- Barrett MRAD ve MRAD MK22 sayfalarında etiketsiz spec blokları var; yalnızca modele güvenle
  eşlenebilen bloklar alındı.
- Kale Kalıp kataloğu üreticinin PDF'i ama Kielce fuar sitesinde barındırılıyor.
- Zastava kaydı Zastava Arms USA (üreticinin ABD iştiraki) sayfasından.

Eklenen (yeni ateşli kayıt): Weatherby 161, Tikka 41, Sako 38, Anschütz 36,
Barrett 35, Accuracy International 34, Cadex 30, Haenel 28, Ruger 20 (Ranch Gen II, hatvesiz),
Savage 19, Mossberg 13, Kale Kalıp 11, Henry 4, Springfield Armory 3, Franchi 2,
Sarsılmaz 1, Zastava 1. Toplam 477 (440'ında hatve var).

Eksik kalan markalar ve nedenleri:
- İstanbul Silah (Monza): üretici sayfası aramada çıkmadı (yalnızca blog/fuar sayfaları).
- Huğlu (OVIS G2): kategori sayfasında kalibre yok; ürün sayfaları aramada yok.
- Kral Arms, Ata Arms, Akdaş, Armsan, Dağlı, Hatsan, Asil Arms, Torun, Safir Arms, Uzkon,
  Derya, Kanuni: yeni ateşli tüfek (yivli) modeli bulunamadı; çoğu av tüfeği/tabanca
  üreticisi (Safir T serisi yivsiz AR tipi av tüfeği). Ata Turqua zaten vardı.
- MKE: data/mke dalında var, tekrar çekilmedi. MKE ile ilişkili Kale Kalıp eklendi;
  Sarsılmaz MPT 76 SH zaten vardı.
- Desert Tech, Kimber, Proof Research, MPA, Benelli, Merkel, Heym, Marlin, Bergara (yeni
  modeller), CZ, Howa: aramada yalnızca mağaza/inceleme sayfaları çıktı, üretici spec
  sayfasına ulaşılamadı.
- Beretta BRX1: resmi sayfanın spec tablosu boş ("-").
- Ruger (Hawkeye LRT, Mini-14, SFAR vb.): model/spec sayfaları aramada yok; Ranch Gen II
  tablosunda hatve yok.
- Savage, Mossberg, Weatherby, Springfield, Henry: yalnızca aramada çıkan SKU/model
  sayfaları alındı; diğer varyantlar eksik.

## 2026-10-11 yerli yivli tüfek turu

Kaynak kuralı aynı: yalnızca üreticinin kendi sitesi/kataloğu. Bulunmayan değer `null`,
notes'ta "resmi kaynakta belirtilmemiş".

Eklenen (323 kayıt):
- İstanbul Silah (monza_katalog.pdf): Monza Varmint (ağır namlu, 22 mm), Monza X Tactical,
  Monza X Hunter — 6 kalibre × 51/56/61 cm = 54. Katalogda hatve yok → `twist_rate_in` null.
  Monza X Thumbhole: sitede "yakında", teknik veri yok → eklenmedi.
- ATA Arms (ataarms.com ürün sayfaları): Turqua Walnut/Synthetic/XT Walnut 47/51/56 cm,
  Turqua PT 47/51/56/66 cm (PT XL), yeni modeller Adjustable, Monte Carlo, Thumbhole,
  Walnut Fonex, Laminated Tungsten, Camo (6 kalibre × 4 namlu) = 213. Hatve sayfadaki
  kalibre tablosundan; ağırlık/toplam uzunluk yalnız 61 cm için verilmiş, diğerleri null
  (Walnut S/M/L ağırlığı TR "Turqua Ahşap" sayfasından). "XL" yalnız PT için var (66 cm).
- Huğlu (huglu.com.tr ürün sayfaları): OVIS G2 Ahşap, Sentetik, AL (66 cm), Long Range
  Ahşap (61 cm) × 4 kalibre = 16. AL ve Long Range sayfalarında tek "1:10 INCH" var;
  .308 dışı kalibrelerde hatve null. "Ovis Tactical / Ovis Hunter" adlı model sitede yok.
- Balıklı (balikliarms.com): BLK 300/308/3006 ve Combo 22/223/308/3006/3030 × 51/56/61 cm
  = 24. Combo sayfalarında hatve yok → null. Combo 9.19 ve 357 (tabanca kalibresi) atlandı.
- Utaş Arms (utasarms.com): .223 Rem ve .308 Win tüfek, yarı otomatik ve çek bırak = 16.
  "XTR-223 / XTR-308" adı resmi sitede geçmiyor. 9 mm tüfek (9x19) kalibre listesinde
  olmadığı için eklenmedi.

Eklenemeyen:
- Art Tech (arttechdefense.com): site robots.txt ile otomatik erişimi yasaklıyor; Prima,
  Prima SP/XP verisi alınamadı.
- Sarsılmaz: sivil yivli tüfek yok (Spor Tüfekleri 12 GA av tüfekleri). SAR 308 ve
  SAR 308 Versiyon 2: resmi ürün sayfası, teknik föy ve 2025 katalog üçü de 7.62x39 mm
  yazıyor → mevcut kayıt doğru, değiştirilmedi.

## 2026-10-11 ithal tüfek turu 1 (sahibinin ChatGPT ipucu listesi doğrulandı)

İpucu: `docs/owner-research/chatgpt-rifles-1.md` (data/owner-research). Kaynak değil; her değer
üreticide teyit edildi.

- CZ +37: CZ 600 Trail/Range/Ergo/Alpha/Lux → CZ'nin kendi deposundaki "CZ 600 Series technical
  data" PDF'i (czfirearms.com/en-us/manuals'tan bağlı); CZ 600 American, Ergo 7.62x39, Trail .300 BLK
  → czub.cz ürün sayfaları. Hatve inç ("1:9 / 6" = 1:9", 6 yiv). Yiv yönü yayımlanmamış.
- Ruger +2: Precision Rifle 18103 (6.5 CM 26") ve 18109 (6mm GT 26") resmi spec sayfaları.
- Eklenmedi: CZ 600+ (American/Alpha/Lux/Range/MDT Grey/MDT Deep Bronze/Carbine) — czfirearms.com
  sayfalarında tablo yalnızca görsel; czub.cz MDT sayfaları yok. Bir bayi sitesinde CZ'nin 600+
  broşürü var, ama resmi alan adında olmadığı ve MDT satırlarında hatveler kalibrelerle çelişik
  göründüğü için kullanılmadı. CZ 600 Lux 7.62x39, American .300 Win Mag: resmi CZ 600 tablolarında yok.
- Accuracy International AT-X MIL .308: sayfa "1:8/1:10" diyor, namluya eşlemiyor → değişmedi.
