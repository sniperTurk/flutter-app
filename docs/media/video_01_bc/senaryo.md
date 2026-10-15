# Video 01 — "BC nedir, neden bu kadar önemli?"

Sniper Türk Instagram / YouTube tanıtım ve eğitim videosu, örnek bölüm.

- Süre: 44 sn (30 fps, 1320 kare)
- Çıktılar: dikey 1080×1920, yatay 1920×1080; altyazılı ve altyazısız
- Ses: müzik yok. Yalnızca açılışta ve kapanışta kısa özgün jingle + kodla üretilmiş doğal efektler (motor, kapı, bot, rüzgâr, hava sesi, dürbün kulesi tıkı)
- Seslendirme: yok. Karakter "konuşurken" altyazı akar; dudak senkronu yok, konuşma sırasında anlatım görsellerine geçilir. Altyazısız sürüm ileride ses kaydı eklemek için temiz bırakıldı.
- Mekân: Orta Anadolu platosu, gün batımı (altın saat) → kapanışta mavi saat
- Bilgi kaynağı: uygulamanın kendi ⓘ metinleri (`lib/features/profiles/profile_field_info.dart`: `bc`, `bcFirearm`, `bcModel`) ve genel fizik. Başka balistik uygulamalardan veri kullanılmadı.

## Karakter

Özgün, kurgusal bir sporcu atıcı (gerçek bir kişiye benzemez). Yaklaşık 40 yaş, oval yüz, kısa koyu kahve saç, şakaklarda kır, kısa düzgün sakal, çenede kır leke, ela-kahve gözler.
Kıyafet (bu video): kömür gri teknik pantolon, birkaç ton açık arduvaz gri gömlek (düğmeleri açık), koyu antrasit tişört, gri-kahve deri bot. Logo ve marka yok.
Referans: `karakter_referans.png`.

## Sahne düzeni

Atış masası üzerinde çift ayaklı (bipod) dürbünlü tüfek, namlu boş vadiye dönük. Masanın bir yanında mesafe ölçer, el dürbünü, fişek kutusu, not defteri (DOPE), eldiven, termos, avcı çantası; masa kenarında tripod üstünde gözlem dürbünü. Yanda açık çadır, yerde ekipman çantası, masanın solunda ve sağında birer katlanır sandalye. Hiçbir üründe marka, logo ya da tanınır gerçek ürün tasarımı yok.

## Çekim listesi

| # | Zaman | Görüntü | Kamera / hareket | Ekrandaki yazı | Altyazı | Ses |
|---|---|---|---|---|---|---|
| 1 | 0:00–0:03,5 | Geniş plan: arazi aracı toprak yoldan atış alanına geliyor, arkasında toz bulutu; önde masa ve çadırın köşesi | Siyahtan açılış, ışık sızması, yavaş itme (push-in) araca doğru, toz parçacıkları | — | — | Jingle başlar; yaklaşan motor, lastik altında çakıl |
| 2 | 0:03,5–0:06,5 | Yakın plan: sürücü kapısı açık, bot toprağa basıyor, toz kalkıyor | Bot yere değince küçük kamera sarsıntısı, hafif geri çekilme | **BC NEDİR, NEDEN BU KADAR ÖNEMLİ?** | — | Kapı mandalı ve gıcırtı, bot + çakıl, hava esintisi |
| 3 | 0:06,5–0:10,5 | Orta-geniş plan: karakter tüfeğin yanında, masa ve tüm ekipman | Karaktere doğru yavaş itme | **Tahmin yok, hesap var.** | — | Rüzgâr, alçak vuruş |
| 4 | 0:10,5–0:13,5 | Yakın plan: karakter kameraya konuşuyor | Çok yavaş itme | — | Selam! Bugün tek bir sayıyı konuşalım: BC. | Rüzgâr |
| 5 | 0:13,5–0:18 | Anlatım grafiği: "BC — Balistik Katsayı", mermi etrafında akan hava çizgileri | Panel kayarak gelir | BC · Balistik Katsayı · Mermi havayı ne kadar kolay yarıyor? | BC, yani balistik katsayı. / Merminin havayı ne kadar kolay yardığını gösteren sayı. | Geçiş "vuşu" |
| 6 | 0:18–0:25 | İki mermi yan yana (düşük BC: kısa, küt; yüksek BC: uzun, sivri, konik dipli). Aynı hızla çıkarlar; düşük BC hızını daha çabuk kaybeder. Sonra yörünge çizimi (düşük BC daha çok düşer) ve rüzgârlı hedef (yüksek BC merkeze daha yakın) | Çizgiler çizilerek gelir | Düşük BC – Yüksek BC · Hızını daha iyi korur · Rüzgârda daha az sapar · Uzakta daha az düşer · "Temsilî gösterim" | İki mermiyi aynı hızla gönderelim. / BC'si büyük olan hızını daha iyi korur, / rüzgârda daha az sapar, uzakta daha az düşer. | Mermilerin hava sesi (silah sesi yok), rozetlerde kule tıkı |
| 7 | 0:25–0:29 | Makro: markasız karton fişek kutusu, yanında defter, el dürbünü, mesafe ölçer | Yavaş itme | BC nerede yazar? · Fişek kutusu · Üreticinin kataloğu / sitesi · etiket "BC · G1 / G7" | Bu sayı fişek kutusunda ya da üreticinin kataloğunda veya sitesinde yazar. | Yumuşak geçiş, tıklar |
| 8 | 0:29–0:33 | Grafik: G1 (düz dipli klasik mermi) ve G7 (uzun, sivri, konik dipli) silüetleri | Kartlar sırayla gelir | BC modeli: G1 mi G7 mi? | Yanında modeli de yazar: G1 ya da G7. / Üretici hangisini yazıyorsa onu seçin. | Tıklar |
| 9 | 0:33–0:38 | Gerçek uygulama ekranı (iOS Simulator, Ateşli tüfek profili, Profil Oluştur › Mühimmat) telefon çerçevesinde; form aşağı kaydırılır, "BC" ve "BC modeli" kutuları vurgulanır | 2.5D: telefon eğik gelir, düzleşir, form kayar, kutulara yakınlaşır; çevre kararır | Profil Oluştur › Mühimmat · BC: Kutuda yazan sayı · BC modeli: Kutuda yazan model: G1 ya da G7 | Sniper Türk'te Profil Oluştur › Mühimmat bölümünü açın, / BC ve BC modeli kutularına yazın. | Geçiş, iki kule tıkı |
| 10 | 0:38–0:40,5 | Karaktere dönüş, yakın plan | Yavaş geri çekilme | — | Gerisini uygulama hesaplar. | Rüzgâr |
| 11 | 0:40,5–0:44 | Mavi saatte boş atış alanı, çadırda fener ışığı | Çapraz geçiş, çok yavaş itme, sonda siyaha iniş | Uygulama simgesi · **SNIPER TÜRK** · Tahmin yok, hesap var. · App Store'da | — | Jingle tekrarı (çözülen son nota), parıltı |

## Doğruluk notları

- "Büyük BC = hızı daha iyi korur, daha az düşer, rüzgârdan daha az etkilenir": `profile_field_info.dart` → `bc` / `bcFirearm`.
- "Kutuda veya üreticinin sitesinde yazar": aynı metin.
- G1 = düz dipli klasik mermi, G7 = uzun, sivri, konik dipli (boat-tail): `bcModel`. "Üretici BC'yi hangi modele göre veriyorsa onu seçin": `bcModelWarning`.
- Uygulamadaki yer: gerçek ekran görüntüleri, `ci/sim-screens` dalı `latest/22_profil_olustur_atesli_4.png` ve `latest/23_profil_olustur_atesli_5.png` (Ateşli tüfek profili, Mühimmat bölümü). İki görüntü, ölçülen kaydırma farkında (1532 px, piksel eşleşmesi) üst üste eklendi; böylece form cihazdaki gibi kaydırılabiliyor. Ekrandaki hiçbir şey çizilmedi; yalnızca vurgu çerçevesi ve karartma eklendi.
- Yörünge ve hedef çizimleri sayısal değildir; ekranda "Temsilî gösterim" yazar.
- Dil: avcılık / sportif atıcılık dili; şiddet, silah satışı ve silah sesi yok.
