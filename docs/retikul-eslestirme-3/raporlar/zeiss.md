# Zeiss — retikül raporu (okuma: 2026-10-12)

## Eklenen kayıtlar (8)
| id | ad | birim | kaynak |
|---|---|---|---|
| zeiss-6-moa | #6 | moa | V3 "Plex-style #6" föyü (MOA) + V6 #6 föyü (in/cm) |
| zeiss-60-moa | #60 | moa | #60 föyü (V4 tablosu yalnız in/cm) |
| zeiss-20-moa | #20 | moa | #20 föyü (V4 tablosu yalnız in/cm) |
| zeiss-zmoai-t30-moa | ZMOAi-T30 | moa | ZMOAi-T30 (#64) föyü |
| zeiss-zmoai-1-moa | ZMOAi-1 | moa | ZMOAi-1 (#93) föyü |
| zeiss-xrr-moa | XRR | moa | V3 XRR #84 föyü + V3 sayfası |
| zeiss-shr-moa | SHR | moa | V3 SHR #87 föyü + V3 sayfası |
| zeiss-shri-moa | SHRi | moa | V3 SHRi #87 föyü + V3 sayfası |

Föy URL'leri her kaydın `source_url`/`notes` alanında.

## Birim farkı kararları (#43 / #6 / #60)
- **#6 (MOA taretli V6 3-18x50, V3 2.5-8x35, V3 3.5-10x42):** Zeiss V3 föyü ölçüleri MOA veriyor (A 0.30, B 1.50, C açıklık 24.00 MOA). V6 föyü ise yalnız in/100 yd ve cm/100 m veriyor. MOA kaydı eklendi. V3 ve V6 açıklıkları farklı ve kayıt üç dürbünde ortak olduğundan posts_start, line_width ve post_width null bırakıldı. V3 değerleri yalnız notlarda. cm'den MOA'ya dönüşüm yapılmadı.
- **#60 (Conquest V4 3-12x56 / 4-16x44 / 6-24x50, ¼ MOA):** Föy ölçüleri yalnız cm/100 m ve in/100 yd olarak veriyor. Talimat gereği MOA kaydı eklendi: duplex, center_dot=true, sayısal alanların hepsi null, notta "ölçü yok; birim taret birimi" yazıyor. Dönüşüm yapılmadı.
- **#43 (Conquest V6 5-30x50, ¼ MOA):** Kayıt EKLENMEDİ. Zeiss bu retikülü yalnız mrad olarak tanımlıyor: "Dots 10 cm apart at 100 m; 1 mrad between dots". Bu ifade V6 sayfasında ve #43 föyünde geçiyor. MOA değeri hiçbir yerde verilmiyor. Retikül gerçekten mil tabanlı. MOA kaydı ya yanlış olurdu ya da tüm sayısal alanları boş kalırdı. Uyumsuzluk gerçek: mil retikül, MOA taret. Mevcut zeiss-43 (mil) kaydı geçerli.
- **#20 (kayit-yok, V4 3-12x56 / 4-16x44, ¼ MOA):** Mevcut "Z-Plex #20" (mil) kaydının anahtarı ZPLEX20, dürbündeki "#20" (anahtar 20) ile eşleşmiyor. Föy yalnız in/cm verdiği için "#20" adıyla MOA kaydı eklendi; sayısal alanlar null.

## Notlar / çelişkiler
- ZMOAi-1 föyü 4-16x50'yi "bu modelde mevcut değil" olarak işaretliyor. Conquest V4 ürün sayfası ise ZMOAi-1'i 4-16x50 için de listeliyor. scopes, dürbün kayıtlarına göre ikisini de içeriyor.
- ZMOAi-1 föyünde 24x sütununda C balk açıklığı 40 MOA. Mevcut ZMOA-1 kaydı aynı #93 için 20 MOA yazıyor; kontrol edilmeli. Yeni kayıtta posts_start=20, açıklığın yarısından çıkarım.
- Mevcut #60 ve Z-Plex #20 (mil) kayıtlarının scopes listesinde MOA taretli V4 modelleri de var. Bunlara dokunulmadı.

## Dürbün düzeltmesi
Yok (scope_changes.json boş).

## Okunamayan
Yok. Tüm Zeiss sayfaları ve PDF'leri WebFetch ile okundu.
