# Saat sayfası — üç tasarım seçeneği (2026-10-16)

Yalnız tasarım. `lib/`, `test/`, `ios/`, `garmin/` altında hiçbir şey değişmedi; kod ya da yeni bağımlılık yok.
Hepsi bir arada: [`index.html`](index.html). Canlı taslaklar: [`secenek-a.html`](secenek-a.html), [`secenek-b.html`](secenek-b.html), [`secenek-c.html`](secenek-c.html).

![Üç seçenek yan yana](png/yan-yana.png)

## Kısa özet (5 satır)

1. Saat, alt menüde Hedef ile Araçlar arasına giren 6. sayfa; başlığı "Saat".
2. Garmin ve Apple Watch aynı anda bağlanır; her yeni hesap bağlı saatlere kendiliğinden gider.
3. Tek gönderim düğmesi var: tamamsa "Hesap saate gönderildi" (koyu mavi, ✓), gönderilemezse "Hesabı saate gönder".
4. "Saatte görünenler"de 10 bilgi var: Kule klikleri ve Mesafe kilitli, diğer 8'i açılıp kapanır. "Saatten gelenler"de saatten gelen Mesafe ve Atış açısı durur.
5. Saati olmayan kullanıcı da ne kazanacağını görmeli; Pro üyelik geldiğinde kilit hiçbir şey kaydırılmadan eklenebilmeli.

## Hepsinde ortak

- Renkler, yazı boyları, köşe yarıçapları `lib/ui/menzil_theme.dart` ile aynı. Üst çubuk, kart, bölüm başlığı + ⓘ, kutu, düğme ve ⓘ alt sayfası `menzil_widgets.dart`, `hava_durumu_view.dart` ve `pro_info_sheet.dart` ile aynı.
- Düğme rolleri: çerçeveli düğme eylemdir ("Saati bağla", "Kaldır"); koyu mavi ve ✓ işaretli düğme tamamlanmış işi gösterir ("Hesap saate gönderildi"); beyaz dolu düğme yalnız alt sayfadaki "Kapat". Turuncu yalnız küçük vurguda kullanıldı: menü çizgisi, uyarı kenarı, "yanıt yok" yazısı ve saat yüzündeki Yukarı kliki.
- **Bilgi çipleri yeniden tasarlandı.** Açık çip koyu mavi zemin, beyaz dolu daire ve ✓. Kapalı çip kesik çizgili çerçeve ve boş gri halka. Kilitli çip (Kule klikleri, Mesafe) beyaz dairede kilit. Renk görmeyen biri de üç durumu ✓, boş halka ve kilitten ayırır. Çipler ikişer ikişer dizili ve 44 pt yüksek. 320 pt'de "Eski veri uyarısı" yazısı kutusunun içinde "Eski veri" olarak kısalır.
- Seçilen sekiz bilgi saat yüzündeki yerlerinden geliyor (`docs/saat-uygulamasi/taslak`): Profil adı, Açı değeri (4.7 MRAD), Rüzgâr hızı, Rüzgâr yönü (saat 3), Klik değeri (MRAD · 0.1/klik), Hesap saati (Güncellendi 14:32), Günün saati (14:33) ve Eski veri uyarısı. Hepsi `WatchSolution.toMap` içinde zaten var.
- ⓘ metinleri kısa ve Türkçe; her biri ne olduğunu, nerede bulunduğunu söyler ve örnek verir. Saat markası, Garmin adımları, Apple Watch adımları, Saate gönderim, Saatte görünenler ve Saatten gelenler için ayrı metin var. "Saati kullanmazsanız hiçbir ayarınız ve hesabınız değişmez." cümlesi yalnız ⓘ içinde geçer (Saatler / Saat markası / Garmin / Apple Watch / Saatten gelenler). Alanların altında açıklama yazısı yok.
- Saatler bölümünde sağda "isteğe bağlı" yazar (Pro'daki "Garmin saati" satırıyla aynı).
- **Alt menü 6 düğme:** 320 pt'de her düğmeye ~53 pt düşüyor; "Hava Durumu" sığmıyor ve 7 pt'ye kadar küçülüyor. Önerim etiketi **"Hava"** yapmak; sayfa başlığı "Hava Durumu" olarak kalır. Bkz. [`png/alt-menu-320.png`](png/alt-menu-320.png). Saat simgesi diğer simgelerle aynı 24'lük ızgarada, 2 pt çizgiyle çizildi.
- Apple Watch'un adı iPhone'dan okunamıyor (WatchConnectivity ad vermiyor). Bu yüzden listede "Apple Watch · bağlı" yazar; Garmin'in adı Garmin Connect'ten gelir ("Fenix 7").

## Kabul testi: "ilk kez kullanan biri 5 saniyede anlıyor mu?" (owner, 16:56)

Önceki taslakta saatin nereden bağlanacağı, düğmelerin ne yaptığı, rengin ne anlama geldiği ve ikinci saatin nereye ekleneceği anlaşılmadığı için bu turda üç seçenekte de şunlar değişti:

- **Boş sayfada yalnız tek iş var.** Saat bağlanmadan çipler, "Saatten gelenler" ve gönderim gösterilmiyor; devre dışı (soluk) bir düğme de yok. Sayfada tek düğme var: "Saati bağla". Üstünde düz Türkçe bir başlık ve cümle duruyor: "Saatinizi bağlayın: markayı seçip Saati bağla'ya dokunun."
- **Dokununca ne olacağı düğmeden önce yazıyor.** Garmin seçiliyse "Dokununca Garmin Connect açılır; saatinizi seçip buraya dönün." Apple Watch seçiliyse "Dokunun, sonra saatte SNIPER TÜRK'ü bir kez açın; saat burada kendiliğinden görünür." Bu cümle bir alanın altında değil, kartın kendi metni; Hava Durumu'ndaki "Hava hazır, sıra tüfekte" kartında olduğu gibi.
- **Dokunduktan sonraki ara durum çizildi** (`png/*-1b.png`). Apple Watch satırı "Apple Watch · bekleniyor" olur ve altında "Saatte SNIPER TÜRK'ü bir kez açın" yazar; yanında "Vazgeç" düğmesi var. Garmin'de bu adım Garmin Connect içinde geçiyor, dönünce saat doğrudan "bağlı" görünüyor.
- **Her saat satırı iki soruyu yanıtlıyor:** saat bağlı mı, hesap ona gitti mi. Örnekler: "Fenix 7 · bağlı / Garmin · son hesap 14:32'de gitti", "Fenix 7 · yanıt yok / son hesap gitmedi, saatte 14:20 hesabı var".
- **Gönderim düğmesinin altında kuralın kendisi yazıyor:** "Her yeni hesap kendiliğinden gider · son 14:32".
- **İkinci saat**, bağlı saatlerin hemen altında, ilk saatle aynı yerde ve aynı biçimde eklenir: A ve C'de "Saat markası | Başka saat bağla", B'de "Başka saat bağla" başlığı altında iki marka kutusu.
- **Marka ön seçimi:** iPhone eşli bir Apple Watch olup olmadığını (WatchConnectivity `isPaired`) ve Garmin Connect'in yüklü olup olmadığını bilebilir. Uygulama bulduğu markayı önceden seçer; ikisi de varsa ya da hiçbiri yoksa kutuda "Seçin" yazar ve "Saati bağla" önce marka listesini açar. Böylece elinde Apple Watch olan biri yanlışlıkla Garmin Connect'e gitmez. Bu, A ve C'deki açılır kutu için önemli; B'de iki marka zaten yan yana görünüyor.

**Düğme renkleri ne demek** (üç seçenekte aynı; diğer sayfalarla da aynı):

| Görünüş | Anlamı | Bu sayfadaki örnek |
|---|---|---|
| Çerçeveli, içi boş | Dokunursanız bir şey yapılır | Saati bağla, Başka saat bağla, Hesabı saate gönder, Kaldır, Vazgeç |
| Koyu mavi, ✓ işaretli | İş yapılmış, bir şey yapmanız gerekmiyor | Hesap saate gönderildi |
| Beyaz dolu | Sayfayı kapatır ya da başka sayfaya geçer | Kapat (ⓘ alt sayfası) |
| Turuncu ince kenar ya da yazı | Dikkat, bir şey yolunda değil | yanıt yok, gönderilemedi kartı |

### İlk kullanım — A (Bölüm kartları)

1. Sayfayı açınca tek bir kart görür: "Saatinizi bağlayın". Altında Saat markası kutusu ("Garmin" seçili) ve yanında "Saati bağla" düğmesi var.
2. Kartta, dokununca Garmin Connect'in açılacağı yazıyor. "Saati bağla"ya dokunur, Garmin Connect'te Fenix 7'yi seçip geri döner.
3. Kartta "Fenix 7 · bağlı / son hesap 14:32'de gitti" satırı belirir. Altında "Saate gönderim" bölümü ve koyu mavi "✓ Hesap saate gönderildi" düğmesi açılır.
4. İkinci saat için aynı kartın altındaki Saat markası kutusundan Apple Watch'u seçer ve "Başka saat bağla"ya dokunur. Satır önce "Apple Watch · bekleniyor" olur; saatte uygulamayı açınca "bağlı" olur.

### İlk kullanım — B (Önce saat listesi)

1. Sayfayı açınca iki saat yüzü ve "Klikler bileğinizde" yazısını görür; metin aşağıdan markanın seçileceğini söylüyor. Altta iki büyük kutu var: Garmin ve Apple Watch.
2. Elindeki saatin kutusuna dokunur. Altındaki cümle o markada ne olacağını söyler. Sonra tek düğme olan "Saati bağla"ya dokunur.
3. Sayfanın tepesinde "Saatlerim" listesi çıkar; saat kendi kartında "bağlı / son hesap … gitti" olarak durur. Altında "✓ Hesap saate gönderildi" düğmesi görünür.
4. İkinci saat için listenin altındaki "Başka saat bağla" bölümünde öbür markaya ve "Saati bağla"ya dokunur. Yeni saat listede ayrı bir kart olarak çıkar.

### İlk kullanım — C (Önce durum ve önizleme)

1. Sayfayı açınca "Örnek" etiketli bir saat yüzü görür: saatinde ne çıkacağı budur. Altında "Saatinizi bağlayın" başlığı, markanın seçilip "Saati bağla"ya dokunulacağını söyleyen cümle, Saat markası kutusu ve "Saati bağla" var.
2. Kartta dokununca ne olacağı yazıyor. Dokunur ve bağlar; Apple Watch'ta başlık "Apple Watch bekleniyor" olur.
3. Bağlanınca "Örnek" etiketi kalkar ve yüz gerçek hesabı gösterir. Başlık "Fenix 7 bağlı", altında "Son hesap 14:32'de saate gitti. Her yeni hesap kendiliğinden gider." ve "✓ Hesap saate gönderildi" yazar.
4. İkinci saat için aşağıdaki "Saatler" kartında Saat markası kutusundan öbür markayı seçer ve "Başka saat bağla"ya dokunur. Bağlanınca tepede iki yüz yan yana durur ve başlık "2 saat bağlı" olur.

### Dört soruyla öz denetim

| Soru | A | B | C |
|---|---|---|---|
| 1. Nereden bağlanır? | Geçer: boş sayfadaki tek düğme "Saati bağla", başlığı "Saatinizi bağlayın" | Geçer: tek düğme, marka kutuları üstünde | Geçer: tek düğme, örnek yüzün hemen altında |
| 2. Dokununca ne olur? | Geçer: düğmenin üstündeki cümle, markaya göre değişiyor | Geçer: aynı cümle | Geçer: aynı cümle; bekleme başlığı da var |
| 3. Saat bağlı mı, hesabı alıyor mu? | Geçer: satırda "bağlı / son hesap 14:32'de gitti" ve ✓ düğmesi | Geçer: her saatin kendi kartı, sorun o kartta | Geçer, en açık burada: tepede büyük durum yazısı ve saatin gösterdiği yüz |
| 4. İkinci saat nereye? | Geçer: aynı kartta "Başka saat bağla" | Geçer: listenin altında "Başka saat bağla" bölümü | Geçer: "Saatler" kartında "Başka saat bağla" |

Üç seçenek de dört soruyu geçtiği için hiçbiri çıkarılmadı. En zayıf nokta A ve C'deki açılır marka kutusu: Apple Watch'u olan biri kutunun Garmin'de durduğunu fark etmeyebilir. Yukarıdaki ön seçim kuralı bu riski kapatıyor; B'de bu risk hiç yok. Bu denetim benim değerlendirmem; gerçek bir kullanıcıyla 5 saniye testi yapılmadı. İstenirse seçilen seçenek bir kişiye telefonda gösterilip dört soru sorulabilir.

## Seçenek A — Bölüm kartları

**Fikir:** Hava Durumu'nun düzeninin aynısı. Başlık + ⓘ ve altında bir kart; sırasıyla Saatler, Saate gönderim, Saatte görünenler ve Saatten gelenler. Saat markası kutusu ile "Saati bağla" düğmesi, Basınç Ölçer'deki "İstasyon basıncı | Basınç al" gibi aynı satırda duruyor. Saat bağlanınca aynı düğmenin adı "Başka saat bağla" olur.

- Artıları: en tanıdık ve en sade seçenek; kodlaması en kolay, neredeyse hep mevcut parçalar kullanılıyor.
- Eksileri: saati olmayan kullanıcıya "ne kazanırım" diye bir şey göstermiyor, ilk açılış bir ayar sayfası gibi duruyor. Satın almaya en az teşvik eden seçenek bu.

## Seçenek B — Önce saat listesi

**Fikir:** Sayfa bağlı saatlerin listesiyle açılır ve her saat kendi kartında durur. Gönderim sorunu o saatin kartında görünür, gönderim düğmesi listenin hemen altındadır. Saat yokken tepede iki gerçek saat yüzü (Garmin yuvarlak ve Apple Watch) ile "Klikler bileğinizde" tanıtımı, altında iki büyük marka kutusu (Garmin | Apple Watch) ve "Saati bağla" var. Ayarlar ilk saat bağlanınca görünür. İkinci saat, listenin altındaki "Başka saat bağla" bölümünde aynı iki marka kutusuyla eklenir.

- Artıları: boş ekran satış yapıyor; hangi saatte sorun olduğu kartından hemen anlaşılıyor; marka seçimi tek dokunuş.
- Eksileri: bağlandıktan sonra tanıtım kayboluyor ve sayfa A'ya benziyor. Marka kutuları bağlıyken de sayfada yer kaplıyor; sayfa üçünün en uzunu.

## Seçenek C — Önce durum ve önizleme (önerilen)

**Fikir:** Sayfanın tepesinde saatin şu anda gösterdiği yüz durur; iki saat bağlıysa iki yüz yan yana. Altında büyük durum yazısı ("2 saat bağlı", "Fenix 7'ye gönderilemedi") ve tek gönderim düğmesi var. "Saatte görünenler"de bir bilgiyi kapatınca o bilgi önizlemeden de kalkar; örnek ekranlarda Rüzgâr yönü ve Günün saati kapalı. Saat yokken aynı yüz "Örnek" etiketiyle görünür, marka ve "Saati bağla" hemen altındadır.

- Artıları: saat olmadan da ne alınacağı en açık bu seçenekte görünüyor (satın almaya en çok teşvik eden). Durum ve tek düğme başparmağın ulaştığı yerde. Çip seçiminin sonucu anında görülüyor. Hata olunca kart turuncu kenar alıyor, sorunlu saatin yüzü kararıyor ve "Güncellendi 14:20" gösteriyor.
- Eksileri: saat yüzü önizlemesi yeni bir parça, kodlaması A'dan zor. Küçük yüzdeki yazılar okunmak için değil, tanınmak için; asıl okuma saatte yapılıyor.

## Karşılaştırma

| | A Bölüm kartları | B Önce liste | C Önce durum |
|---|---|---|---|
| Anlaşılırlık | İyi | İyi | **Çok iyi**: saatin ne göstereceği ekranda |
| Satın almaya teşvik | Zayıf | İyi (yalnız boşken) | **Çok iyi** (her durumda) |
| Diğer sayfalarla uyum | **Çok iyi** (Hava Durumu ile aynı) | İyi | İyi (kartlar ve düğmeler aynı, önizleme yeni) |
| Tek elle kullanım | Orta (gönderim ortada) | İyi | **Çok iyi** (durum + düğme üstte, tek kartta) |
| Kodlama zorluğu | **Kolay** | Orta | Orta–zor (önizleme parçası) |

## Önerim: C

Bu sayfanın işi, Pro'yu satın aldıracak özelliği göstermek. C hem saati olmayana hem saati olana aynı şeyi gösteriyor: bileğe gelecek olan ekranın kendisini. Saati olan için de sayfanın en önemli sorusu "son hesap saate gitti mi?". C bunu tepede tek cümle ve tek düğmeyle cevaplıyor. Aşağıdaki bölümler A ile aynı parçalar, yani diğer sayfalarla uyum korunuyor. Önizleme için saat ekranlarının tasarımı zaten hazır (`docs/saat-uygulamasi/taslak`); yeniden tasarlamak gerekmiyor, küçültülmüş hali kullanılıyor.

## Pro üyelik kilidi nereye takılır (şimdi rozet yok)

Hiçbir şey yer değiştirmeden iki yere takılabilir:

1. Saatler bölümünün sağındaki **"isteğe bağlı"** yazısı, ileride "Pro" rozeti olur.
2. **"Saati bağla" düğmesi**: üye olmayan dokunduğunda bağlantı akışı yerine üyelik alt sayfası açılır. Düğmenin yeri, adı ve şekli aynı kalır.

C'de önizleme ve çipler kilitliyken de görünmeye devam eder; satın almaya teşvik eden kısım da zaten bu.

## Gereken kayıt anahtarları (öneri)

Bugün kodda saat ile ilgili hiçbir kayıt anahtarı yok. Yeni anahtarlar sürüm ekiyle açılır; olmayan anahtar varsayılanı verir, bu yüzden eski kayıtlar sorunsuz yüklenir ve silinmez.

| Anahtar | İçerik | Yoksa |
|---|---|---|
| `watch.devices.v1` | Bağlı saatler: marka, kimlik, ad, eklenme ve son gönderim zamanı | Boş liste (ilk açılış) |
| `watch.fields.v1` | Kapalı bilgi çiplerinin kimlikleri (`profile`, `angle`, `wind`, `dir`, `click`, `calc`, `clock`, `stale`) | Hepsi açık; `clicks` ve `range` hiç saklanmaz, hep açık |
| `watch.lastSend.v1` | Son gönderim: zaman, sonuç (tamam / gönderilemedi), saat başına sonuç | Gönderim yok |
| `watch.received.range.v1` | Saatten gelen mesafe: değer, birim, zaman | "—", Henüz gelmedi |
| `watch.received.angle.v1` | Saatten gelen atış açısı: değer, zaman (park edilmiş PR #354) | "—", Henüz gelmedi |
| `watch.brand.last.v1` | Son seçilen saat markası | Garmin |

Garmin'in seçili saatleri Garmin Connect'te tutulur; `watch.devices.v1` yalnız ad ve son gönderim zamanını ekler. Bilinmeyen ya da eski bir çip kimliği sessizce atlanır.

## Tasarlanmayanlar

- Saat ekranlarının kendisi (ayrı tasarlandı), uygulama kodu ve testler.
- Garmin Connect'in kendi ekranları (uygulamamızın dışında) ve "Kaldır" onayı.
- Pro'daki "Garmin saati" satırının kaldırılması (Saat sayfası gelince o satır silinmeli; ayrı görev).
- Üyelik ekranı ve kilitli durumun görünümü.
- Açık tema ve büyük yazı boyutu denetimi.

## Dosyalar ve yeniden üretme

- `png/{a,b,c}-{1,1b,2,3,4}.png`: 1 ilk açılış, 1b Apple Watch seçilip "Saati bağla"ya dokunulduktan sonra (bekleniyor), 2 bir Garmin bağlı ve gönderildi, 3 Garmin + Apple Watch, 4 gönderilemedi.
- `png/{a,b,c}-320.png` 320 pt denetimi (3. durum); `png/{a,b,c}-bilgi.png` ⓘ alt sayfası (A: Garmin adımları, B: Apple Watch adımları, C: Saatte görünenler).
- `png/alt-menu-320.png` alt menü karşılaştırması; `png/yan-yana.png` üç seçenek yan yana.
- Görüntüler 390 pt genişlikte, 2× piksel yoğunluğunda (780 px). Uzun sayfalar 844 pt'den uzun çekildi, alt menü sayfanın sonunda. Yazı tipi iPhone'da sistem yazısı (SF); bu makinede onun yerine en yakın yazı olan Inter kullanıldı.
- Yeniden üretmek için: `node uret.mjs` (önceden kurulu Chromium + Playwright). Kaynaklar `kaynak/` klasöründe; `secenek-*.html` dosyaları tek parça olarak üretilir.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
