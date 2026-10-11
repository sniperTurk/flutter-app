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
