/// Short explanations behind the ⓘ button of every Profil field.
///
/// Project rule (owner, 2026-10-07): every value the user enters gets an
/// explanation. Keep them short, concrete and in Turkish; say where the value
/// can be found and give a typical example.
abstract final class ProfileFieldInfo {
  // Profil
  static const platform =
      'Tüfeğinizin türü. PCP Tüfek: basınçlı havayla saçma veya slug atan '
      'havalı tüfek. Ateşli Tüfek: barutlu fişek atan tüfek. Marka, kalibre '
      've mühimmat listeleri ile açıklamalar bu seçime göre değişir; '
      'tüfeğinizin belgesinde veya kutusunda yazar. Örnek: Hatsan Factor '
      'için PCP Tüfek.';

  // Tüfek
  static const rifleOrigin =
      'Tüfeğin üretildiği yer. Yerli: Türkiye\'de üretilen markalar '
      '(Hatsan, Kral Arms, Sarsılmaz, MKE, Ata Arms…). İthal: yurt dışı '
      'markaları (Tikka, Sako, Daystate, BSA…). Seçim Marka listesini '
      'süzer; Tümü hepsini gösterir.';
  static const caliber =
      'Namlunun iç çapı, milimetre olarak; listeden seçin. 4,50 mm (.177), '
      '5,50 mm (.22), 6,35 mm (.25), 7,62 mm (.30), 9,00 mm (.357) ve '
      'büyük çaplar. '
      'Mühimmatın kalibresi buradan alınır.';
  static const caliberFirearm =
      'Tüfeğinin kalibresi; listede merminin gerçek çapıyla yazılıdır. '
      'Kalibre namlunun üstünde ve mühimmat kutusunda yazar; örneğin .308 '
      'Win için 7,82 mm. Yalnızca listeden seçilir; fişeğin listede yoksa '
      'bize bildirin. Mühimmatın kalibresi buradan alınır.';
  static const bulletDiameter =
      'Fişeğiniz listede yoksa merminin çapını seçin. Çap mermi kutusunda '
      'veya üreticinin sitesinde inç olarak yazar; örneğin .308 Win için '
      '.308 in · 7,82 mm, .223 Rem için .224 in · 5,69 mm.';
  static const twistDirection =
      'Namlunun içindeki yivlerin dönüş yönü. Namluya arkadan bakarken yivler '
      'saat yönünde dönüyorsa Sağ, tersiyse Sol. Namluların çoğu sağdır.';
  static const twistRate =
      'Merminin namlu içinde bir tam tur dönmesi için gereken namlu uzunluğu, '
      'inç olarak. 1:16 = her 16 inçte bir tur; buraya 16 yazılır. Sayı '
      'küçüldükçe dönüş hızlanır. Namlu üreticisinin föyünde yazar.';

  // Mühimmat
  static const ammoSource =
      'Fabrika fişeği: hazır alınan kutu fişek; marka ve modelini seçince '
      'ağırlık, BC ve namlu çıkış hızı üreticinin verisiyle dolar. El '
      'dolumu: kendi doldurduğunuz fişek; mermiyi seçersiniz, hızı '
      'kronografla ölçüp kendiniz yazarsınız.';
  static const ammoType =
      'Pellet: belli ve etek yapılı klasik havalı tüfek saçması. Slug: dolu '
      'gövdeli, mermi biçimli ağır saçma.';
  static const grain =
      'Bir saçmanın veya merminin ağırlığı, grain olarak (1 grain = 0,0648 g). '
      'Kutunun üstünde yazar. Örnek: 25,39 gr pellet, 33,95 gr slug.';
  static const ammoLength =
      'Saçmanın veya slug\'ın boyu, milimetre olarak. Kumpasla ucundan '
      'arkasına ölçülür ya da üreticinin sitesinde yazar. Boş '
      'bırakılabilir; girilirse yiv oranıyla dengesi kontrol edilir. '
      'Örnek: kumpasta 10,5 okunursa 10,5 yazın.';
  static const grainFirearm =
      'Merminin (çekirdeğin) ağırlığı, grain olarak (1 grain = 0,0648 g). '
      'Kutunun üstünde yazar. Örnek: .223 için 55 gr, .308 için 168 gr, '
      '6.5 Creedmoor için 140 gr.';
  // Elle girilen ateşli mühimmat (owner, 2026-10-14).
  static const ammoBrandPick =
      'Fişeğin veya merminin markası. Kutunun üstünde yazar. Listede '
      'uygulamanın bildiği tüm markalar var. Örnek: Federal, Hornady, Sellier '
      '& Bellot. Markanız listede yoksa en alttaki "Diğer"i seçip yazın.';
  static const ammoNothingListed =
      'Bu kalibre için listede henüz hazır ürün yok; bu yüzden mühimmat elle '
      'giriliyor. Ağırlık, BC ve hız kutuda veya üreticinin sitesinde yazar. '
      'Kendi doldurduğunuz fişekse Mühimmat türünde El dolumu seçin.';
  static const ammoBrandOther =
      'Listede olmayan markanın adı, kutunun üstünde yazdığı gibi. Örnek: '
      'kutuda "Atölye Fişek" yazıyorsa Atölye Fişek.';
  static const ammoModelTyped =
      'Fişeğin veya merminin model adı, kutunun üstünde yazdığı gibi. Aynı '
      'markanın başka mühimmatıyla karışmasın diye gerekli. Örnek: Gold '
      'Medal Sierra MatchKing, ELD Match.';
  static const grainPick =
      'Merminin (çekirdeğin) ağırlığı. Kutudaki gr değeridir; gram değil '
      '(1 gr = 0,0648 g, parantezde gram karşılığı var). Listede bu kalibre '
      'için üreticilerin verdiği ağırlıklar var. Örnek: .308 için 168 gr '
      '(10,9 g). Kutudaki değer listede yoksa "Listede yok"u seçip yazın.';
  static const grainTyped =
      'Kutudaki gr değeridir; gram değil. Kutunun yanındaki gram karşılığı '
      'size yardımcı olur: 168 gr = 10,9 g. Bu kalibre için mantıksız bir '
      'ağırlık kabul edilmez. Örnek: 175.';
  static const bc =
      'Balistik katsayı: merminin havayı ne kadar kolay yardığını gösteren '
      'sayı. Büyük BC = hızı daha iyi korur, daha az düşer, rüzgârdan daha az '
      'etkilenir. Tipik: pellet 0,02–0,04, slug 0,05–0,15 (G1). Kutuda veya '
      'üreticinin sitesinde yazar. Rüzgâr sapması bu değerle hesaplanır. '
      'Saçma ve slug G1 ile hesaplanır. Bilinmiyorsa boş bırakın; sonuç '
      'yaklaşık olur. Örnek: BC değerini 0,032 şeklinde girin.';
  static const scopeFilterUnit =
      'Dürbününüzü bulmak için kulenin birimi. MRAD: klik 0,1 mil. MOA: '
      'klik 1/4 MOA. SMOA: üretici "100 yardada 1/4 inç" diyorsa. Kulede ya '
      'da kutuda yazar. Listede yalnız bu markada olan birimler çıkar.';
  static const scopeFilterFocal =
      'Odak düzlemi. FFP: retikül büyütmeyle büyür. SFP: retikül hep aynı '
      'boyda kalır. Dürbünün adında ya da kutusunda FFP veya SFP yazar.';
  static const scopeFilterMag =
      'Dürbünün üstünde yazan büyütme aralığı. Örnek: 5-30x56 yazıyorsa '
      '5-30x seçin. Yalnız kalan dürbünlerdeki aralıklar çıkar.';
  static const scopeFilterTube =
      'Dürbün gövdesinin çapı, mm; dürbün ayağının ölçüsüdür. Kutuda ya da '
      'kılavuzda yazar. Örnek: 30, 34 veya 35 mm.';

  /// BC modeli ⓘ, both rifle types (owner, 2026-10-14 11:35/11:38): one
  /// line per model, the warning last. Firearms add [bcModelCustom] before
  /// the warning ([bcModelWithCustom]).
  static const _bcModelLines =
      'G1: Düz dipli, klasik mermi. Saçma ve slug BC\'leri de çoğunlukla '
      'buna göre verilir.\n'
      'G7: Uzun, sivri ve konik dipli (boat-tail) mermi.\n'
      'G2, G5, G6, G8, GI: Başka mermi şekilleri; az kullanılır.\n'
      'GS: Küre şekli (yuvarlak bilye).\n'
      'RA4: .22 LR rimfire.';
  static const bcModelWarning =
      'Uyarı: Yanlış eğri seçmek, hiç seçmemekten daha fazla hata yaratır. '
      'Üretici BC\'yi hangi modele göre veriyorsa onu seçin; bilmiyorsanız '
      'G1\'de bırakın.';
  static const bcModel = '$_bcModelLines\n\n$bcModelWarning';
  static const bcModelWithCustom =
      '$_bcModelLines\n$bcModelCustom\n\n$bcModelWarning';
  static const bcFirearm =
      'Balistik katsayı: merminin havayı ne kadar kolay yardığını gösteren '
      'sayı. Büyük BC = hızı daha iyi korur, daha az düşer, rüzgârdan daha az '
      'etkilenir. Tipik: G1 0,25–0,60; G7 0,12–0,30. Kutuda veya mermi '
      'üreticisinin sitesinde yazar. Rüzgâr sapması bu değerle hesaplanır. '
      'Örnek: BC değerini 0,324 şeklinde girin.';

  /// Added to the BC ⓘ of a listed factory round whose maker publishes no
  /// BC (2026-10-14). A typed BC sets BC modeli to G1 (owner, 2026-10-13);
  /// the text says so (MUH-5, owner, 2026-10-15).
  static const bcFactoryNoBc =
      'Bu fişek: Üretici BC yayımlamıyor. Kendi atışlarınızdan bulduğunuz '
      'BC\'yi girin. BC yazınca BC modeli kendiliğinden G1 olur; üretici BC\'yi '
      'G7 olarak veriyorsa BC modelini G7 yapın.';

  /// Added to the BC ⓘ when the listed factory round's BC comes from the
  /// same NATO standard bullet's official report (owner, 2026-10-12: "ⓘ
  /// alanında veriyi nasıl eklediğimizi açıkla; kullanıcı isterse
  /// değiştirsin"). [probable]: the maker does not name the standard; weight
  /// and type match.
  static String bcNatoStandard({
    required String brand,
    required String standard,
    required String report,
    bool probable = false,
  }) =>
      "$brand bu fişeğin BC'sini yayımlamıyor. Değer, "
      '${probable ? 'muhtemel eşdeğeri olan' : 'aynı'} NATO standart '
      'mermisinin ($standard) resmi test raporundan alındı ($report). Kendi '
      'tüfeğinizde fark olabilir; kutudaki ya da ölçtüğünüz değeri girebilir, '
      'Doğrulama ekranıyla düzeltebilirsiniz.';
  static const dragCurve =
      'Merminin kendi sürüklenme eğrisi: her Mach hızında havanın ne kadar '
      'frenlediği (Cd). Tek BC sayısından daha doğrudur; uzun menzilde ve ses '
      'hızına inerken fark eder. Lapua (.drg, QuickTARGET), Doppler radar ölçümü '
      'veya iki sütunlu CSV (Mach, Cd) yükleyin; örnek satır: 0,90 0,215. Çap '
      've ağırlık mühimmattan alınır.';
  static const bcModelCustom =
      'Özel eğri (Mach–Cd): merminin kendi eğrisi elinizdeyse (Lapua .drg, '
      'radar ölçümü) seçin; BC gerekmez.';

  static const bandSpeed =
      'İsteğe bağlı. BC hız düştükçe değişir (özellikle saçma ve slug). Hız '
      'bu değerin altına inince yandaki BC kullanılır; üstünde ana BC. '
      'Üretici bazen hız aralıklarıyla birden çok BC verir (ör. Sierra). '
      'Örnek: 800 fps altında 0,031.';
  static const bandSpeedFirearm =
      'İsteğe bağlı. BC hız düştükçe değişir. Hız bu değerin altına inince '
      'yandaki BC kullanılır; üstünde ana BC. Üretici bazen hız aralıklarıyla '
      'birden çok BC verir (ör. Sierra). Örnek: 1800 fps altında 0,450.';
  static const bandBc =
      'Hız, soldaki eşiğin altına düştüğünde kullanılacak BC (aynı model: '
      'G1/G7). Boş bırakırsanız tek BC kullanılır. Örnek: BC değerini '
      '0,310 şeklinde girin.';

  // Dürbün
  static const focalPlane =
      'FFP (ön odak düzlemi): retikül büyütmeyle birlikte büyür; çizgi '
      'aralıkları her büyütmede doğrudur. SFP (arka odak düzlemi): retikül '
      'sabit görünür; aralıklar yalnız belirli bir büyütmede (genelde en '
      'yüksek) doğrudur. Dürbünün adında veya föyünde yazar.';
  static const minMag =
      'Dürbünün en düşük büyütmesi; listeden seçin. Dürbünün adında, '
      'gövdesinde veya kutusunda yazar: 6-24x56 bir dürbün için 6x, '
      '3-9x40 için 3x. Sabit büyütmeli dürbünde (10x42) Minimum ve '
      'Maksimum aynıdır.';
  static const maxMag =
      'Dürbünün en yüksek büyütmesi; listeden seçin. Dürbünün adında, '
      'gövdesinde veya kutusunda yazar: 6-24x56 bir dürbün için 24x, '
      '3-9x40 için 9x. Minimum büyütmeden küçük olamaz.';
  static const objective =
      'Ön (objektif) merceğin çapı, milimetre olarak; listeden seçin. '
      'Dürbünün adında "x"ten sonraki sayıdır: 6-24x56 için 56 mm, 3-9x40 '
      'için 40 mm.';
  static const clickValue =
      'Üst kuleyi bir klik çevirince nişanın ne kadar kaydığı. Kulenin '
      'üstünde veya dürbünün föyünde yazar ("1 click = 0.1 MRAD", '
      '"1/4 MOA"). En yaygını MRAD dürbünde 0,1 MRAD, MOA dürbünde 1/4 MOA; '
      'hassas dürbünlerde 0,05 MRAD veya 1/8 MOA olur. Önce Dürbün birimini '
      'seçin; liste ona göre dolar.';
  static const scopeUnit =
      'Kulelerin ve retikülün açı birimi: MRAD (mil), MOA veya SMOA. '
      'Kulenin üstünde veya dürbünün föyünde yazar. "1/4 IN @ 100 YDS" '
      'yazıyorsa SMOA seçin (100 yard\'da 1 inç; MOA\'dan %4,5 küçük). Listeden '
      'seçilen dürbünde klik buna göre alınır: MRAD\'da 0,1, MOA ve '
      'SMOA\'da 1/4; listede olmayan dürbünde Klik değerini ayrıca seçersiniz.';
  static const sightHeight =
      'Sight height: dürbünün merkez ekseni ile namlunun merkez ekseni '
      'arasındaki dikey mesafe, milimetre olarak. Mermi namludan bu kadar '
      'aşağıdan çıkar ve önce yükselerek nişan çizgisini keser; bu yüzden '
      'yakın ve uzak mesafedeki düşüş hesabını doğrudan etkiler. Örnek: '
      'havalı tüfekte 45–70 mm. Merkezden merkeze ölçülür: namlunun üst '
      'yüzeyinden değil, namlu deliğinin merkezinden. Adım adım ölçüm için: '
      'Araçlar → Sight Height.';
  static const sightHeightFirearm =
      'Sight height: dürbünün merkez ekseni ile namlunun merkez ekseni '
      'arasındaki dikey mesafe, milimetre olarak. Mermi namludan bu kadar '
      'aşağıdan çıkar ve önce yükselerek nişan çizgisini keser; bu yüzden '
      'yakın ve uzak mesafedeki düşüş hesabını doğrudan etkiler. Örnek: '
      'ateşli tüfekte 38–60 mm. Merkezden merkeze ölçülür: namlunun üst '
      'yüzeyinden değil, namlu deliğinin merkezinden. Adım adım ölçüm için: '
      'Araçlar → Sight Height.';
  static const reticle =
      'Dürbünün içindeki çizgi deseni. Adı dürbünün kutusunda, kullanım '
      'kılavuzunda veya üreticinin ürün sayfasında yazar. Örnek: APR-2D MOA, '
      'VPR-MIL. Bazı dürbünler birden çok retikülle satılır; listede '
      'sizinkini seçin. Seçtiğiniz retikül Hedef ekranında dürbüne özel '
      'çizilir; kaydı yoksa genel çizgili desen görünür. Bilmiyorsanız MIL '
      'dürbünde "MIL çizgili", MOA dürbünde "MOA çizgili" seçin. İsteğe '
      'bağlı.';
  static const elevationTravel =
      'Üst kuleyi en alttan en üste çevirince toplam kaç klik döndüğü; '
      'sayı olarak yazılır. Örnek: 0,1 MRAD klikli 30 MRAD\'lık kule için 300. '
      'Kutuda yazar ya da kuleyi çevirip sayarsınız. Uzak atışta kule '
      'yetmezse uygulama bunu söyler. Bilmiyorsanız boş bırakın; hesap '
      'yine çalışır.';
  static const mountCant =
      'Dürbün ayağının (montaj rayı veya ayarlı No Limit ayak) dürbüne '
      'verdiği eğim, MOA olarak. Normal düz ayakta "Normal (0 MOA)" seçin. '
      'Ayağın üstünde veya kutusunda yazar; listedeki her seçeneğin yanında '
      'dürbününüzde kazandırdığı klik hazır yazılıdır. Ayak '
      'mermi düşüşünü azaltmaz: tüfeği ayakla yeniden sıfırladığınızda '
      'kulede yukarı doğru bu kadar ek yer açar. 1/4 MOA dürbünde her 1 MOA '
      '= 4 klik (60 MOA = 240 klik); 0,1 MRAD dürbünde 30 MOA ≈ 87 klik. '
      'Ayak dürbünün yüksekliğini de değiştirir; Sight height\'ı yeniden '
      'ölçün.';

  // Atış değerleri
  static const velocity =
      'Merminin namludan çıktığı andaki hızı, fps (feet/saniye) olarak. En '
      'doğrusu kronografla birkaç atış ölçüp ortalamasını girmektir. '
      'Örnek: 900 fps ≈ 274 m/s (1 m/s = 3,28 fps).';
  static const velocityFirearm =
      'Merminin namludan çıktığı andaki hızı, fps (feet/saniye) olarak. '
      'Fabrika fişeği seçince üreticinin hızı yazılır; bu hız uzun bir test '
      'namlusunda ölçülür (çoğunlukla 24 inç), sizin namlunuzda farklı '
      'olabilir. Kronografla ölçtüyseniz kendi değerinizi yazın. Örnek: '
      '.308 Win 168 gr için 2650 fps.';
  static const powderCoef =
      'Barut sıcaklık katsayısı: hava 15 °C ısındığında namlu çıkış hızının '
      'yüzde kaç arttığı. Atış hesabı hızı Hava Durumu\'ndaki sıcaklığa göre '
      'bununla düzeltir. Fişek ve barut üreticileri çoğunlukla sayı vermez, '
      'yalnızca "sıcaklığa duyarsız" yazar; en doğrusu aynı fişeği soğuk ve '
      'sıcak bir günde kronografla ölçmektir. Örnek: 10 °C\'de 2600 fps, '
      '25 °C\'de 2639 fps ölçtüyseniz 1,5 seçin. Fabrika fişeğinde üretici '
      'sayı veriyorsa kendiliğinden dolar. Bilmiyorsanız "Seçiniz"de '
      'bırakın; hız sıcaklığa göre düzeltilmez. '
      'Yalnızca ateşli tüfek.';
  static const powderTemp =
      'Namlu çıkış hızını kronografla ölçtüğünüz günkü hava sıcaklığı, °C. '
      'Üreticinin hızını kullanıyorsanız üreticinin belirttiği test '
      'sıcaklığını seçin; çoğu üretici 21 °C kullanır. Hız bu sıcaklıktan '
      'bugünkü sıcaklığa göre düzeltilir. Katsayıyla birlikte seçilir. '
      'Örnek: 21.';
  static const zero =
      'Dürbünü sıfırladığınız mesafe: bu mesafede nişan noktası ile vuruş '
      'noktası çakışır. "Mesafe birimi"nde seçtiğiniz birimle (metre veya '
      'yard) girin. Örnek: havalı tüfekte 25–40 m.';
  static const zeroFirearm =
      'Dürbünü sıfırladığınız mesafe: bu mesafede nişan noktası ile vuruş '
      'noktası çakışır. "Mesafe birimi"nde seçtiğiniz birimle (metre veya '
      'yard) girin. Örnek: ateşli tüfekte çoğunlukla 100 m (veya 100 yard).';
  static const distanceUnit =
      'Mesafelerin birimi: metre veya yard (1 yard = 0,9144 m). Yard '
      'seçilirse sıfırlama mesafesi, Hedef sayfası, dürbün içindeki mesafe '
      'sayıları ve tablo yard ile gösterilir. Dürbününüzün odak düğmesi '
      'yard ile yazılıysa yard seçin.';

  static const backup =
      'Yedekle: tüm profillerinizi ve kendi girdiğiniz tüfek, mühimmat ve '
      'dürbün kayıtlarını tek dosyaya kaydeder. Açılan ekranda Dosyalar\'a '
      'Kaydet ile iCloud Drive\'ı ya da Google Drive\'ı seçin. Telefon '
      'değişince Geri yükle ile aynı dosyayı seçin; hiçbir profil silinmez. '
      'Hesap veya şifre gerekmez.';

  // PCP tüp ve regülatör basıncı (owner, 2026-10-12). Yalnızca PCP.
  static const tubePressure =
      'Tüpü doldurduğunuz basınç, bar. Dolum sonrası manometreden okuyun ya '
      'da kılavuzdaki en yüksek dolum basıncını yazın. Basınca göre hız '
      'ölçümleri varsa hız bu basınca göre bulunur. Bilmiyorsanız boş '
      'bırakın. Örnek: 250.';
  static const regulatorPressure =
      'Regülatörün vanaya verdiği sabit basınç, bar. Kılavuzda ya da '
      'regülatör manometresinde yazar. Tüp bu basıncın üstündeyken hız '
      'sabittir; altına inince regülatör devre dışı kalır ve hız düşer. '
      'Regülatörsüz tüfekte boş bırakın: boş kutu "regülatör yok" demektir '
      '(ayrı bir seçim yok). Tüp basıncından küçük olmalı. Örnek: 150.';
  static const pvBar =
      'Kronografla hız ölçtüğünüz andaki tüp basıncı, bar (manometreden). '
      'Her satır bir ölçümdür: basınç ve o basınçta ölçtüğünüz hız. En az '
      'iki satır girilirse, Pro\'da yazdığınız kalan tüp basıncındaki hız '
      'bu ölçümlerin arasından bulunur; ölçümlerin dışında en yakın ölçüm '
      'kullanılır. Boş bırakırsanız profil hızı kullanılır. Örnek: 180.';
  static const pvFps =
      'O basınçta kronografla ölçtüğünüz namlu çıkış hızı, fps. Birkaç '
      'atışın ortalamasını yazın. Basınçla birlikte girilir. Örnek: 870.';

  // Mühimmat → Ek mühimmat bilgileri başlığının ⓘ'si (owner, 2026-10-14
  // 18:07–18:20: "Nedir?" / "Neden önemli?", uzun metin).
  static const ammoExtra =
      'Nedir?\n'
      'Barut katsayısı, hız ölçüm sıcaklığı ve hıza göre BC; hesabı '
      'inceltmek için girilen ek mühimmat bilgileridir. Boş bırakılabilir, '
      'profil yine kaydedilir.\n'
      '\n'
      'Neden önemli?\n'
      'Hava sıcaklığı değişince namlu çıkış hızı da değişir; mermi '
      'yavaşladıkça BC düşer. Bu bilgileri girerseniz uzak mesafede düşüş ve '
      'rüzgâr sapması daha doğru hesaplanır.';
}
