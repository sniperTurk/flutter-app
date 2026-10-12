# Hatsan — eksik PCP modelleri (ek)

**Neden:** Hatsan (İzmir) Türkiye'nin en büyük havalı silah üreticisi; mevcut hatsan.json'da bu modeller yoktu.

**Eklenen kayıt:** 36
- Blitz 4.5/5.5/6.35/7.62 mm (4)
- Hercules (düz) 4.5/5.5/6.35/7.62/9.0/11.43 mm (6)
- Galatian 4.5/5.5/6.35 ve Galatian Carbine 4.5/5.5/6.35 (6)
- Galatian 5 Auto / 6 Auto / Tact Auto × 3 kalibre (9)
- Barrage 4.5/5.5 (2)
- AT44 (tek atış) ve AT44-10 × 3 kalibre (6)
- Jet II 4.5/5.5/6.35 (3; PCP tabanca/karabina, dipçikli)

**Kaynaklar (resmi kılavuz/sayfa):**
- https://hatsanairgunsusa.com/wp-content/uploads/2021/03/Blitz-Manual_V21.3.pdf
- https://hatsan.com.tr/tr/urun/blitz-bp-2/ (4.5 mm şarjör)
- https://hatsanairgunsusa.com/wp-content/uploads/2018/12/Hercules_Manual_EN.pdf
- https://hatsanairgunsusa.com/wp-content/uploads/2021/03/Hatsan-Galatian-Manual_V21.3.pdf
- https://hatsanairgunsusa.com/wp-content/uploads/2018/12/Galatian_Auto_Series_Manual_EN.pdf
- https://hatsanairgunsusa.com/wp-content/uploads/2021/03/BARRAGE-BULLMASTER-Manual_V21.3.pdf
- https://hatsanairgunsusa.com/wp-content/uploads/2021/03/AT-44-44-10-EN_V21.3.pdf
- https://hatsanairgunsusa.com/product/jet-ii/

**Eksikler / notlar:**
- hatsanairgunsusa.com/product/blitz-full-auto-pcp ve hatsan.com.tr ürün sayfalarındaki "Tech. Specs." sekmeleri boş geldi (JS); kılavuzlar kullanıldı.
- Big-bore kalibreler şartnameye göre "9.0 mm" / "11.43 mm" yazıldı; mevcut hatsan.json ".35"/".45" kullanıyor — birleştirirken tutarlılık kontrol edilmeli.
- Regülatör basıncı ve hatve hiçbir kılavuzda yok → null. Hercules 11.43 mm şarjör, Barrage tüp hacmi, AT44 tüp/enerji, Blitz 4.5 mm hız/enerji yok.
- Jet II ağırlığı çelişkili (2.4/3.4/3.9 lb) → null.
- Nova Star: resmi sayfa boş, PCP olduğu doğrulanamadı (yaylı/EN14 olabilir) → eklenmedi. Galatian II, AT44 Long/Tact/W/S, AT44-PA, Galatian Auto II/III ve Sortie (tabanca) eklenmedi.
