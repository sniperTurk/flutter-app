/// Short explanations behind the ⓘ button of every Profil field.
///
/// Project rule (owner, 2026-10-07): every value the user enters gets an
/// explanation. Keep them short, concrete and in Turkish; say where the value
/// can be found and give a typical example.
abstract final class ProfileFieldInfo {
  // Tüfek
  static const caliber =
      'Namlunun iç çapı, milimetre olarak; listeden seçin. 4,50 mm (.177), '
      '5,50 mm (.22), 6,35 mm (.25), 7,62 mm (.30), 9,00 mm (.357). '
      'Mühimmatın kalibresi buradan alınır.';
  static const caliberFirearm =
      'Merminin çapı, milimetre olarak; listeden seçin. 5,56 mm (.223 Rem / '
      '5.56 NATO), 6,17 mm (.243 Win), 6,5 mm (6.5 Creedmoor), 7,62 mm '
      '(.308 Win / 7.62 NATO / .300 Win Mag), 8,59 mm (.338 Lapua Mag). '
      'Mühimmatın kalibresi buradan alınır.';
  static const twistDirection =
      'Namlunun içindeki yivlerin dönüş yönü. Namluya arkadan bakarken yivler '
      'saat yönünde dönüyorsa Sağ, tersiyse Sol. Namluların çoğu sağdır.';
  static const twistRate =
      'Merminin namlu içinde bir tam tur dönmesi için gereken namlu uzunluğu, '
      'inç olarak. 1:16 = her 16 inçte bir tur; buraya 16 yazılır. Sayı '
      'küçüldükçe dönüş hızlanır. Namlu üreticisinin föyünde yazar.';

  // Mühimmat
  static const ammoType =
      'Pellet: belli ve etek yapılı klasik havalı tüfek saçması. Slug: dolu '
      'gövdeli, mermi biçimli ağır saçma.';
  static const grain =
      'Bir saçmanın veya merminin ağırlığı, grain olarak (1 grain = 0,0648 g). '
      'Kutunun üstünde yazar. Örnek: 25,39 gr pellet, 33,95 gr slug.';
  static const grainFirearm =
      'Merminin (çekirdeğin) ağırlığı, grain olarak (1 grain = 0,0648 g). '
      'Kutunun üstünde yazar. Örnek: .223 için 55 gr, .308 için 168 gr, '
      '6.5 Creedmoor için 140 gr.';
  static const bc =
      'Balistik katsayı: merminin havayı ne kadar kolay yardığını gösteren '
      'sayı. Büyük BC = hızı daha iyi korur, daha az düşer, rüzgârdan daha az '
      'etkilenir. Tipik: pellet 0,02–0,04, slug 0,05–0,15 (G1). Kutuda veya '
      'üreticinin sitesinde yazar. Rüzgâr sapması bu değerle hesaplanır.';
  static const bcModel =
      'BC sayısının hangi standart mermi şekline göre verildiği. G1: küt uçlu '
      'klasik şekil; havalı tüfek saçması ve slug için neredeyse her zaman G1 '
      'verilir. G7: uzun, sivri uzun menzil mermisi. Aynı mermide G7 değeri '
      'G1\'in yaklaşık yarısıdır; yanlış model hesabı ciddi saptırır. Emin '
      'değilseniz G1 seçin.';
  static const bcFirearm =
      'Balistik katsayı: merminin havayı ne kadar kolay yardığını gösteren '
      'sayı. Büyük BC = hızı daha iyi korur, daha az düşer, rüzgârdan daha az '
      'etkilenir. Tipik: G1 0,25–0,60; G7 0,12–0,30. Kutuda veya mermi '
      'üreticisinin sitesinde yazar. Rüzgâr sapması bu değerle hesaplanır.';
  static const bcModelFirearm =
      'BC sayısının hangi standart mermi şekline göre verildiği. G1: klasik '
      'av mermisi şekli. G7: uzun, sivri, arka tarafı daralan (boat-tail) '
      'uzun menzil mermisi; bu mermilerde G7 daha doğrudur. Aynı mermide G7 '
      'değeri G1\'in yaklaşık yarısıdır; yanlış model hesabı ciddi saptırır. '
      'Üretici hangisini veriyorsa onu seçin.';

  // Dürbün
  static const focalPlane =
      'FFP (ön odak düzlemi): retikül büyütmeyle birlikte büyür; çizgi '
      'aralıkları her büyütmede doğrudur. SFP (arka odak düzlemi): retikül '
      'sabit görünür; aralıklar yalnız belirli bir büyütmede (genelde en '
      'yüksek) doğrudur. Dürbünün adında veya föyünde yazar.';
  static const minMag =
      'Dürbünün en düşük büyütmesi. 6-24x56 bir dürbün için 6.';
  static const maxMag =
      'Dürbünün en yüksek büyütmesi. 6-24x56 bir dürbün için 24.';
  static const objective =
      'Ön (objektif) merceğin çapı, milimetre olarak. 6-24x56 bir dürbün için '
      '56.';
  static const scopeUnit =
      'Kulelerin ve retikülün açı birimi: MRAD (mil), MOA veya SMOA. '
      'Kulenin üstünde veya dürbünün föyünde yazar. "1/4 IN @ 100 YDS" '
      'yazıyorsa SMOA seçin (100 yard\'da 1 inç; MOA\'dan %4,5 küçük). Bir '
      'klik buna göre alınır: MRAD\'da 0,1, MOA ve SMOA\'da 1/4.';
  static const sightHeight =
      'Sight height: dürbünün merkez ekseni ile namlunun merkez ekseni '
      'arasındaki dikey mesafe, milimetre olarak. Mermi namludan bu kadar '
      'aşağıdan çıkar ve önce yükselerek nişan çizgisini keser; bu yüzden '
      'yakın ve uzak mesafedeki düşüş hesabını doğrudan etkiler. Örnek: '
      'havalı tüfekte 45–70 mm. Ölçmek için altındaki "Sight height nasıl '
      'ölçülür?" bağlantısına bakın.';
  static const elevationTravel =
      'Üst kuleyi en alttan en üste çevirince toplam kaç klik döndüğü. '
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
      '= 4 klik (60 MOA = 240 klik); 0,1 mrad dürbünde 30 MOA ≈ 87 klik. '
      'Ayak dürbünün yüksekliğini de değiştirir; Sight height\'ı yeniden '
      'ölçün.';

  // Atış değerleri
  static const velocity =
      'Merminin namludan çıktığı andaki hızı, fps (feet/saniye) olarak. En '
      'doğrusu kronografla birkaç atış ölçüp ortalamasını girmektir. '
      'Örnek: 900 fps ≈ 274 m/s (1 m/s = 3,28 fps).';
  static const zero =
      'Dürbünü sıfırladığınız mesafe: bu mesafede nişan noktası ile vuruş '
      'noktası çakışır. "Mesafe birimi"nde seçtiğiniz birimle (metre veya '
      'yard) girin. Örnek: havalı tüfekte 25–40 m.';
  static const distanceUnit =
      'Mesafelerin birimi: metre veya yard (1 yard = 0,9144 m). Yard '
      'seçilirse sıfırlama mesafesi, Hedef sayfası, dürbün içindeki mesafe '
      'sayıları ve tablo yard ile gösterilir. Dürbününüzün odak düğmesi '
      'yard ile yazılıysa yard seçin.';
}
