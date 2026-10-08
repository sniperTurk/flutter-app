/// Short explanations behind the ⓘ button of every Profil field.
///
/// Project rule (owner, 2026-10-07): every value the user enters gets an
/// explanation. Keep them short, concrete and in Turkish; say where the value
/// can be found and give a typical example.
abstract final class ProfileFieldInfo {
  // Tüfek
  static const caliber =
      'Namlunun iç çapı, milimetre olarak. Örnek: 5,5 mm (.22), '
      '6,35 mm (.25), 7,62 mm (.30). Mühimmatın kalibresi buradan alınır.';
  static const barrelLength =
      'Namlunun arka ucundan namlu ağzına kadar uzunluğu, santimetre olarak. '
      'Susturucu veya moderatör dahil değildir. Tüfeğin teknik föyünde yazar.';
  static const twistDirection =
      'Namlunun içindeki yivlerin dönüş yönü. Namluya arkadan bakarken yivler '
      'saat yönünde dönüyorsa Sağ, tersiyse Sol. Namluların çoğu sağdır.';
  static const twistRate =
      'Merminin namlu içinde bir tam tur dönmesi için gereken namlu uzunluğu, '
      'inç olarak. 1:16 = her 16 inçte bir tur; buraya 16 yazılır. Sayı '
      'küçüldükçe dönüş hızlanır. Namlu üreticisinin föyünde yazar.';
  static const regulator =
      'PCP regülatörünün namluya gönderdiği sabit çalışma basıncı, bar olarak. '
      'Tüp dolum basıncı değildir. Tüfeğin föyünde veya regülatör ayarında '
      'yazar; örnek: 110–140 bar.';

  // Mühimmat
  static const ammoType =
      'Pellet: belli ve etek yapılı klasik havalı tüfek saçması. Slug: dolu '
      'gövdeli, mermi biçimli ağır saçma. Ateşli tüfekte mermi seçilir.';
  static const grain =
      'Bir saçmanın veya merminin ağırlığı, grain olarak (1 grain = 0,0648 g). '
      'Kutunun üstünde yazar. Örnek: 25,39 gr pellet, 33,95 gr slug.';
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
      'Kulelerin ve retikülün açı birimi: MRAD (mil) veya MOA. Kulenin '
      'üstünde veya dürbünün föyünde yazar.';
  static const click =
      'Kuleyi bir klik çevirince vuruş noktasının kaydığı açı. MRAD '
      'dürbünlerde genelde 0,1; MOA dürbünlerde genelde 1/4 = 0,25. Kulenin '
      'üstünde yazar.';
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
  static const windageTravel =
      'Rüzgâr kulesinin (sağ kule) toplam ayar aralığı, dürbün biriminde. '
      'Föyde "Total windage adjustment" diye yazar; çoğu dürbünde yükseklik '
      'aralığıyla aynıdır. Örnek: 60 MOA veya 17 MRAD. Boş bırakılabilir.';
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
      'noktası çakışır. Örnek: havalı tüfekte 25–40 m.';
}
