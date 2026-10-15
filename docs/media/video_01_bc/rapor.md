# Video 01 "BC nedir?" — rapor

Tarih: 15.10.2026 (İstanbul saati). Bu görev uygulamanın koduna dokunmadı; yalnızca `docs/media/video_01_bc/` altına dosya eklendi.

## Ne yapıldı

44 saniyelik örnek bir tanıtım/eğitim videosu hazırlandı. Konusu "BC nedir, neden bu kadar önemli?".

**Video dosyaları** (her biri 50 MB'tan küçük; boyutlar aşağıda):

| Dosya | Format | Altyazı |
|---|---|---|
| `video_01_bc_dikey.mp4` | 1080×1920 | Altyazılı |
| `video_01_bc_dikey_altyazisiz.mp4` | 1080×1920 | Altyazısız |
| `video_01_bc_yatay.mp4` | 1920×1080 | Altyazılı |
| `video_01_bc_yatay_altyazisiz.mp4` | 1920×1080 | Altyazısız |

**Diğer dosyalar:**

- `altyazi.srt`: Türkçe altyazı dosyası. YouTube'a ayrı altyazı olarak yüklenebilir.
- `senaryo.md`: Senaryo ve çekim listesi.
- `storyboard.png`: 11 planın tek sayfalık özeti.
- `karakter_referans.png`: Karakter referans sayfası.

**Videonun akışı:**

1. Arazi aracı toz kaldırarak gelir. Bot toprağa basar ve başlık görünür.
2. Karakter tüfeğin yanında durur. Slogan görünür: "Tahmin yok, hesap var."
3. Kamera yakın plana geçer ve karakter altyazıyla "konuşur". Bu sırada sırasıyla şunlar anlatılır:
   - BC'nin tanımı
   - Düşük ve yüksek BC'li iki merminin karşılaştırması: hız kaybı, düşme ve rüzgâr sapması
   - BC'nin nerede yazdığı
   - G1 ve G7
   - Uygulamada nereye girileceği. Gerçek ekran gösterilir, "BC" ve "BC modeli" kutuları vurgulanır.
4. Karaktere geri dönülür.
5. Mavi saatte kapanış: uygulama simgesi, "SNIPER TÜRK", slogan ve "App Store'da".

**Bilgilerin kaynağı:**

- Bilgiler uygulamanın kendi ⓘ metinlerinden alındı: `profile_field_info.dart` içindeki `bc`, `bcFirearm`, `bcModel` ve `bcModelWarning`. Bunlara genel fizik eklendi.
- Başka balistik uygulamalardan hiçbir veri kullanılmadı.
- Karşılaştırma çizimleri sayısal değildir. Ekranda "Temsilî gösterim" yazar.

## Kullanılan araçlar

- **Figma `generate_image` (gpt-image-2.5 modeli):**
  - Bütün fotogerçekçi kareler bununla üretildi: araç, bot, sahne, yakın planlar, fişek kutusu, kapanış ve karakter referansı.
  - Tamamı "Sniper Türk – Video 01 BC görselleri" adlı Figma dosyasında duruyor.
  - **Maliyet:** Bu özellik Figma AI kredisi harcıyor. Toplam yaklaşık 23 üretim yapıldı. Denemeler ve sonradan düzeltmeler de bu sayıya dahil.
- **video-shotcraft becerisi:** Kurgunun kuralları buradan alındı: iş akışı, 2.5D kamera hareketi, ritim, ses tasarımı ve bağımsız son kontrol.
- **Remotion kurulamadı.** Bu oturumun ağı npm paket sunucusuna kapalıydı, Remotion da npm'den kuruluyor.
  - Aynı yöntem doğrudan kuruldu: video kare kare HTML/CSS/JS olarak tanımlandı, Chromium (Playwright) her kareyi çizdi, ffmpeg bunları birleştirdi.
  - Bu yöntemde her kare yalnızca kendi numarasına bağlıdır. Rastgelelik sabit tohumla üretilir. Aynı kod her seferinde aynı videoyu verir.
- **Ses Python'da (numpy/scipy) sıfırdan sentezlendi.** Hiçbir hazır ses dosyası ya da müzik kullanılmadı.
  - Jingle: özgün dört notalı motif. Telli çalgı benzeri vuruş, yumuşak bir ses halısı ve alçak bir "bum"dan oluşuyor.
  - Efektler: motor, çakıl, kapı mandalı, bot adımı, rüzgâr, hava "vuşu" ve dürbün kulesi tıkı.
  - Silah sesi yok.
- **Uygulama ekranı:** `ci/sim-screens` dalındaki gerçek iOS Simulator görüntüleri kullanıldı (`latest/22` ve `latest/23`, Ateşli tüfek profili, Mühimmat bölümü).
  - İki görüntü, ölçülen kaydırma farkında birleştirildi (1532 px, piksel piksel eşleşiyor). Böylece form, cihazdaki gibi aşağı kayıyor.
  - Ekrana çizim eklenmedi. Yalnızca vurgu çerçevesi ve karartma var.
- **Bağımsız kontrol:** Videoyu üretmeyen ayrı bir inceleme ajanı kare kare inceledi. Bulduğu düzeltilebilir noktaların hepsi düzeltildi; liste aşağıda.

## Kare kare kontrolde bulunan ve düzeltilenler

- **Dikey altyazı ve slogan Instagram/YouTube düğmelerinin altında kalıyordu.** Yukarı alındı; altyazı artık çerçevenin alt %25'inin üstünde. Dikey grafikler buna göre yeniden yerleştirildi.
- **Başlıkta satır aralığı dardı.** "Ö" ve "İ" noktaları üst satıra değiyordu. Satır aralığı açıldı.
- **Araç tanınmış bir elektrikli kamyoneti andırıyordu.** Ayrıca karlı dağlar ve çiçekli ağaçlar sonraki planlarla mevsim uyumsuzluğu yaratıyordu. İlk plan yeniden üretildi: genel bir arazi aracı, yaz sonu, kar ve çiçek yok.
- **Yakın planlarda yüz, sahnedeki yüzden belirgin farklıydı.** Dikey yakın planda karakter kameraya da bakmıyordu. İki yakın plan yeniden üretildi; karakter artık kameraya bakarak konuşuyor ve arka planda göl ile çadır var.
- **Uygulama ekranının altında kırmızı bir uyarı görünüyordu:** "Kaydetmek için eksik…". Bu, tanıtımda hata durumu gösteriyordu. O şerit koyu bir bantla örtüldü.
- **Yörünge etiketleri kendi eğrilerinin üstüne biniyordu.** Etiketler eğrilerin dışına alındı.
- **Hız çubukları abartılıydı.** Mermi neredeyse duruyormuş gibi görünüyordu; ölçek yumuşatıldı.
- **Rüzgâr hedefindeki isabetler hem sağa hem aşağı kaymıştı.** Bu, düşmeyi rüzgârla karıştırıyordu. İsabetler yalnızca yana kaydırıldı.
- **"vs"** yerine "–" yazıldı.
- **Altyazılar yeniden yazıldı:**
  - "fişek kutusunda ya da üreticinin kataloğunda veya sitesinde yazar"
  - "Yanında modeli de yazar: G1 ya da G7"
- **Kart metni değişti:** "Mermi kutusu" yerine "Fişek kutusu" yazıldı.
- **Ses:**
  - Anlatım bölümündeki rüzgâr sesi yükseltildi; telefonda boş duyuluyordu.
  - Mermilerin hava sesi, mermilerin çıkış anına çekildi.

## Dürüst sınırlar

- **Dudak senkronu yok.** Seslendirme de yok. Karakter "konuşurken" yüzü sabit bir karedir ve kamera yavaşça hareket eder. Konuşma sırasında anlatım grafiklerine geçiliyor.
- **Bütün sahneler hareketsiz fotoğraflardır.** Hareket kamera itme/çekme, sarsıntı, toz ve ışık parçacıklarıyla veriliyor.
  - Araç gerçekten ilerlemiyor. Bot da gerçekten adım atmıyor; tek kare üstüne toz bulutu eklendi.
  - Gerçek derinlik ayrımı yapılmadı. Ön planla arka plan ayrı ayrı kaymıyor; bu, tam bir 2.5D değil.
- **Yüz birebir aynı değil, "aynı kişi tipi".** Figma'nın görsel aracı yalnızca yazıyla çalışıyor; referans fotoğraf veremiyoruz. Bu yüzden yüz her karede aynı tarifle istendi. Sonuç birbirine çok yakın ama birebir aynı yüz değil; karşılaştırması `karakter_referans.png` içinde.
- **Dikey ve yatay sürümler ayrı üretilmiş karelerden oluşuyor.** Kompozisyon her formata göre ayrı kuruldu. Bu yüzden iki sürümde masa düzeni ve yüz küçük farklar taşıyor.
- **Kapanış sahnesindeki masa ve sandalyeler ana sahnedekilerden biraz farklı.** Mavi saat karesi ayrı üretildi.
- **Araç markasız ve genel bir tasarım.** Yine de her arazi aracı uzaktan bazı gerçek modellere benzeyebilir. İstenirse araç tamamen silüete indirilebilir.
- **Ses yükseklik dengesi:** Ortalama yaklaşık −18 LUFS, tepe −1,2 dBFS (kırpılma yok). Jingle'daki "bum"lar tepeyi belirlediği için ortalama Instagram'ın tipik seviyesinden biraz düşük. Müzik olmadığı için bu bilinçli bir tercih.
- **Uygulamada gözüme çarpan bir nokta:** Formun uyarı metninde İngilizce "Sight height" geçiyor. Videoda örtüldü, uygulamada değiştirilmedi. Ayrı bir görev açmak isterseniz not olarak bırakıyorum.
- **Başlık, slogan ve kapanış yazıları ortalandı.** Sinema/fragman dili bu yüzden seçildi. Uygulamadaki "metin sola hizalı" kuralı videoya uygulanmadı; anlatım kartlarındaki metinler sola hizalı. İsterseniz başlıklar da sola alınabilir.
- **Videonun kaynak kodu depoya eklenmedi.** Bu, istenen dosyalar arasında değildi. Kaynak kod sahne çizimi, ses sentezi ve render betiğinden oluşuyor. Ses kaydı eklemek ya da metin değiştirmek için gerekirse ayrıca eklenebilir.

## Sizin karar vermeniz gerekenler

1. **Görsel dil ve karakter:** Bu yüz ve bu kıyafet seri için tamam mı? Sonraki videolarda yüz aynı tarifle istenir, kıyafet ve mekân değişir.
2. **Seslendirme:** Kendi sesinizle kaydedecek misiniz? Altyazısız sürümler ve `altyazi.srt` buna hazır. Kaydı gönderirseniz ses, aynı zaman çizelgesine yerleştirilir.
3. **Kaynak kodu:** Videonun kaynak kodu (kare çizimi, ses sentezi, render) depoya eklensin mi? Eklenirse sonraki videolar aynı altyapıyla daha hızlı çıkar.
4. **Başlıkların hizası:** Ortada mı kalsın, sola mı alınsın?
5. **Paylaşım:** Instagram için dikey, YouTube için yatay sürüm önerilir. YouTube'da altyazısız sürüm ile `altyazi.srt` birlikte de kullanılabilir.
