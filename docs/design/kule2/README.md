# Kule tasarımı 2 – ChairGun ölçüsü, bizim görünüşümüz (yalnızca tasarım)

Bu PR yalnızca tasarım içerir: uygulama kodu, ses, hesap ve başka sayfalar değişmedi.
Figma dosyası: **Sniper Türk – Kule** → https://www.figma.com/design/hbvWW1ogOg8HAYe8FZMDz5

## ChairGun'dan alınan oranlar ve bizdeki ölçüler

Yalnızca ölçü ve yerleşim alındı (ChairGun'un çizimi, yazısı ve görselleri alınmadı). Renkler `MenzilColors.dark`'tan.

- ChairGun: retikül Ø 398 pt, kule 199 × 60 pt → **uzunluk = 0,50 × retikül çapı, kalınlık = 0,30 × uzunluk**, iki kule aynı boy.
- Bizim retikül dairesi (gerçek ekran görüntüsünden ölçüldü): 390 pt telefonda **Ø 326 pt** (kare 334), 320 pt telefonda **Ø 256 pt**. k = 326/398 = 0,819 ve 256/398 = 0,643.

| | 390 pt | 320 pt |
|---|---|---|
| ChairGun oranıyla kule | 163 × 49 pt | 128 × 38 pt |
| Uygulanan kule (üst ve yan aynı) | **163 × 49 pt** | **160 × 44 pt** |
| Ok dokunma alanı (tamburun içinde, iki uçta) | 44 × 49 pt | 44 × 44 pt |
| Üst kule yeri | x 113,5–276,5, y 120–169; dikey çizginin tam üstünde | x 80–240, y 124–168 |
| Kule ayağı (koyu yamuk, kuleyi daireye bağlar) | 49 pt yüksek, üstte 197 pt, altta 82 pt | 39 pt yüksek, üstte 186 pt, altta 80 pt |
| Yan kule yeri | x 309–358 (sağ kenarı dairenin sağ kenarında), y 300–463 (ortası yatay çizgide) | x 244–288, y 255–415 |
| L-R düğmesi (48 pt yuvarlak) | üst kulenin sağında aynı satırda, x 314 (kuleyle arası 37 pt) | x 252 (arası 12 pt) |
| Göz düğmesi (48 × 48) | sol üstte L-R'nin simetriği, x 28 | x 20 |

**320 pt'de ChairGun oranı yetmiyor:** 128 × 38 pt'lik kulede kalınlık 38 pt < 44 pt, uzunlukta da iki ok hücresinden sonra 128 − 2×44 = 40 pt kalıyor; üç değer (önceki / şimdiki / sonraki) sığmıyor. En küçük çözüm: kalınlık en az 44 pt, uzunluk en az 2×44 + 72 = 160 pt → **160 × 44 pt** (retikülün 0,62'si). 390 pt'de ChairGun oranı olduğu gibi yetiyor.

Göz düğmesi bugün retikülün sol üst köşesinde; ChairGun'daki gibi kulelerin satırına, sol üste alındı (yer değişikliği budur). Hiçbir düğme kuleyle çakışmıyor.

## Kötü örneklerde (PR #405) yanlış olan

Kuleler retiküle göre oransızdı: üst kule dairenin üstünde kendi başına duran bir kutuydu, yan kule dairenin içinde yüzüyordu, iki kule farklı boydaydı ve oklar tamburun dışındaydı ya da kutunun kenarına sıkışmıştı. Beş seçenek aslında yalnızca kaplama farkıydı; 320 pt'de yazılar kesiliyordu ("10", "2R" üst üste).
Bu çalışmada ölçüler retikül çapından hesaplandı, üst kule bir ayakla daireye bağlandı, iki kule aynı boyda, oklar tamburun içinde iki uçta 44 pt hücrede; Figma'da her kulenin yazıları çakışma ve taşma için kontrol edildi.

## Üç seçenek (ölçü ve yer üçünde de aynı)

1. **Silindir** – Tambur uçlarda koyu, ortada açık (silindir gölgesi); oklar ince "‹ ›" işaretleri; şimdiki değer 16 pt, komşular 10 pt.
2. **Mat, halkalı ok** – Düz `surface2` rengi, ince çerçeve; oklar halka içinde (dokunulacak yer belli); şimdiki değer 18 pt, komşular 10 pt.
3. **Tırtıllı, büyük rakam** – Güçlü silindir gölgesi, ok hücrelerinde ince tırtıl çizgileri, ayakta yatay oluklar; oklar dolu üçgen; şimdiki değer 20 pt, komşular 9 pt.

Ortak: `← U  MOA  D →` üst satır, ortada önceki / **şimdiki** / sonraki değer, altta çentikler ve ortada yukarı bakan kırmızımsı işaret (`danger` #FF8A80). Yan kulede çentikler solda, işaret solda sağa bakıyor, değerler çentiklerin yanında, birim sağda dikey, uçlarda `↑ R` ve `L ↓`.

## Görseller

- Genel bakış (bugünkü kule + üç seçenek): [secenekler.png](secenekler.png)
- Seçenek 1: [390](secenek_1_390.png) · [320](secenek_1_320.png)
- Seçenek 2: [390](secenek_2_390.png) · [320](secenek_2_320.png)
- Seçenek 3: [390](secenek_3_390.png) · [320](secenek_3_320.png)

## Bilinmesi gerekenler (yapılamayan / farklı yapılan)

- **Taban ekran görüntüsü Figma'ya konamadı:** bu ortamdan Figma'ya görsel yükleme adresi (mcp.figma.com) engelli (403). Bu yüzden Hedef sayfası Figma'da düzenlenebilir katmanlarla yeniden çizildi; tüm ölçüler gerçek ekran görüntüsünden alındı: `ci/sim-screens` dalı `latest/01_bugun_390.png` ve `latest/02_bugun_320.png` (çalıştırma 39064769437, iPhone 16e, main 53100e0'daki kule). Şu anki `latest/` klasöründe Hedef görüntüsü yoktu; bu görüntü aynı klasörün son Hedef çekimi olduğu için sim-screens yeniden çalıştırılmadı.
- Uygulamanın yazı tipi SF Pro; bulut Figma'da SF Pro yok, yerine ölçüsü çok yakın **Inter** kullanıldı.
- Uyarı kutusu metni Figma'da kısaltıldı (sekme çubuğunun altında kalıyor).
- PNG'ler Figma çerçevelerinin 3× ekran görüntüsüdür (1170 × 2532 ve 960 × 1704). `secenekler.png`'deki "Bugün" sütunu gerçek simülatör görüntüsüdür.
- Figma Starter planının MCP çağrı sınırı doldu: dosyada dışa aktarım için açılmış 6 geçici "EXPORT …" kopyası (aşağıda, y = 4000) silinemedi ve çerçeve başlıkları eklenemedi; elle silinebilir.
- Komşu değerler 9–10 pt; bu ChairGun oranının sonucu (tambur 49 / 44 pt kalın).
- Uygulama kodu değişmediği için test, CI, Simulator veya TestFlight çalıştırılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
