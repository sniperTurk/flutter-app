# Temiz tasarım — onaylı karar listesi (owner, 2026-10-15)

Bu klasördeki `.dc.html` dosyaları ve `.png` görüntüleri sahibin sayfa sayfa onayladığı tasarımdır.
PNG'ler 390 pt genişlikte, 2x çözünürlükte çizildi. Örnek değerler yalnızca görsel içindir;
uygulamanın hesap ve davranışı değişmez.

## Genel kurallar (tüm sayfalar)
- Renkler: zemin #0B1620, kart #122330, çizgi #27425A, yazı #E7EFF3, ikinci yazı #9CB1C0,
  ana düğme #F5B031 (yalnız "Profil oluştur" gibi ana eylem), bağlantı #4CC3E8, uyarı #FF8A80.
  Turuncu #E8590C yalnız rüzgâr saati kadranındaki seçili saat ve oktadır.
- Düğmeler turuncu olmaz ve simgesizdir (Sıfırla, Basınç al, Telefondan, Haritadan al …).
- Veri alınan düğme: dolgu koyu mavi #1F5F7A, çerçeve #2E7FA0, yazı beyaz; yazı "… alındı" olur
  (ör. "Haritadan alındı", "Düzeltme alındı"). Sayfaya sonradan dönülünce de bu hâlde kalır.
  Yalnız "Hava verisi alındı" düğmesinde ✓ işareti vardır.
- Her seçim kutusu başlangıçta "Seçiniz" gösterir; yazı kutuları boş gelir.
- Açılan liste her zaman kutunun altından, 4 px boşlukla açılır ve tam kutu genişliğindedir.
- Her satırda iki kutu; Marka, Model ve Kalibre tek satır (tam genişlik). Yazılar sola dayalı.
  Kutu altında açıklama yok, hepsi ⓘ içinde. Etiketlerde parantez yok.

## Profil
- Sayfa başlığı "Sniper Türk".

## Profil Oluştur (Tüfek / Dürbün / Mühimmat / Ek mühimmat bilgileri)
- Tüfek: Marka (tek satır), Model (tek satır), Kalibre (tek satır, eski hâli), sonra çiftler.
- Dürbün: "Üst kule klik sayısı | Dürbün ayağı" aynı satırda (Dürbün ayağı sağda).
- Dürbün marka değişince tüm dürbün filtreleri temizlenir (Birim, Odak düzlemi, Tüp, Büyütme,
  Model, Retikül → "Seçiniz"). Kod bunu zaten yapıyor; aynen korunmalı.
- Mühimmat ayrı kart. "Ek mühimmat bilgileri" kendi başlığı ve kendi kartı olan ayrı bölüm;
  başlık satırında "isteğe bağlı" yazısı ve ⓘ sağ uçta. Kapalı gelmez. Eşik altı BC kutusu birimsiz.

## Hava Durumu
- Üst kart başlığı "Hava", alttaki özet kartı "Hava özeti".
- Rüzgâr başlığının ⓘ'si "Rüzgâr tahmini nasıl yapılır?" metnini taşır; ayrı bağlantı kaldırıldı.
- Düğmelerde simge yok; alınan düğmeler koyu mavi (yukarıdaki kural).

## Pro Ayarlar
- Alınan düğme ("Düzeltme alındı") koyu mavi; turuncu değil.

## Hedef
- Sayfa başlığı "Hedef".
- "Kuleleri kur" | "Kuleleri sıfırla" tek satır, yazı ikinci satıra kaymaz.
- Üst kule tamburu retikülün dikey çizgisi üzerinde ortalı: düzen
  `[boş 48] [‹ 28] [tambur 1fr] [› 28] [L-R 48]`; etiketler "← U  MOA  D →", değerler 2U · 0 · 2D
  (yönler doğrulandı: U solda, D sağda).
- Yan (rüzgâr) kule: dikey, R yukarı / L aşağı, sıfırı retikülün yatay çizgisinde.
  Yukarı/aşağı okları kule kutusunun DIŞINDA (üstte ve altta), kutusuz, yalnız işaret
  (beyaz ok, ince koyu kenar). Kule kutusu uzun ve ince (yaklaşık 74 × 224 pt), tombul değil.
- Pro'dan mesafe ile Hedef'e gelince kuleler çözüme kurulu gelir ve yan kule açık gelir
  (mevcut davranış, değişmez). "L-R" yan kuleyi açar/kapar.
- "FFP · MOA · 21x" retikülün içinde.
- "Hesap dökümü" açılır kapanır satır (varsayılan kapalı).

## Araçlar
- Araç ikonları beyaz (#E7EFF3) gri-mavi zemin (#1B3245) üzerinde; amber değil.
