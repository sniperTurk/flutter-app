/// Short explanations behind the ⓘ button of every Hava Durumu / Atış field.
///
/// Project rule (owner, 2026-10-07): every value the user enters gets an
/// explanation. Keep them short, concrete and in Turkish; say where the value
/// can be found and give a typical example.
abstract final class EnvironmentFieldInfo {
  // Texts that name the projectile come in two versions: "saçma" for PCP
  // and "mermi" for a firearm (owner, 2026-10-11). Use the `…For` helpers
  // with the selected platform.
  static String temperatureFor({required bool firearm}) =>
      firearm ? temperatureFirearm : temperature;
  static String windSpeedFor({required bool firearm}) =>
      firearm ? windSpeedFirearm : windSpeed;
  static String inclineFor({required bool firearm}) =>
      firearm ? inclineFirearm : incline;
  static String cantFor({required bool firearm}) =>
      firearm ? cantFirearm : cant;
  static String coriolisFor({required bool firearm}) =>
      firearm ? coriolisFirearm : coriolis;

  static const temperature =
      'Atış yerindeki hava sıcaklığı. Sıcak hava daha seyrektir; saçma daha '
      'az yavaşlar ve daha az düşer. Telefonun hava durumu veya bir '
      'termometre yeterlidir. Örnek: 18 °C.';
  static const temperatureFirearm =
      'Atış yerindeki hava sıcaklığı. Sıcak hava daha seyrektir; mermi daha '
      'az yavaşlar ve daha az düşer. Telefonun hava durumu veya bir '
      'termometre yeterlidir. Örnek: 18 °C.';
  static const ammoTemperature =
      'Fişeğin kendi sıcaklığı. Güneşte veya araçta bekleyen fişek havadan '
      '10–20 °C sıcak olabilir. Profilde barut sıcaklık katsayısı varsa hız '
      'bu sıcaklıkla düzeltilir; katsayı yoksa etkisi yoktur. Fişek kutusuna '
      'konan bir termometreyle ölçün. Boşsa hava sıcaklığı kullanılır. '
      'Örnek: 32 °C.';
  static const pressure =
      'Bulunduğunuz yerde ölçülen gerçek (istasyon) hava basıncı. Hava '
      'durumu uygulamalarının çoğu deniz seviyesine indirgenmiş basıncı '
      '(QNH, ~1013 hPa) verir; yüksek yerde bu değer hesabı bozar (1000 m '
      'irtifada gerçek basınç ~900 hPa). Barometreli telefonda "Basıncı '
      'telefondan al" düğmesi gerçek basıncı okur; araç içinde veya klimalı '
      'odada değil, açık havada basın. Ya da Kestrel, barometre veya '
      'Araçlar > hesaplayıcılar ile deniz seviyesinden istasyon basıncına '
      'çevirin. Örnek: 1000 m irtifada 900 hPa.';
  /// Basınç Ölçer card: ONE ⓘ right of the title (owner exception,
  /// 2026-10-14; no ⓘ in the box).
  static const barometerCard =
      'İstasyon basıncı: bulunduğunuz yerdeki gerçek hava basıncı, '
      'telefonun basınç sensöründen alınır. Hava durumu uygulamalarındaki '
      'deniz seviyesi basıncı değildir. Örnek: 998,4 hPa.';

  /// İrtifa card: ONE ⓘ right of the title (owner exception, 2026-10-14).
  static const altitudeCard =
      'Bulunduğunuz yerin deniz seviyesinden yüksekliği. Haritadan: Google '
      'haritadan zemin yüksekliği, internet ister. Telefondan: GPS ölçümü, '
      'açık havada daha doğrudur. Telefon irtifası varsa hesap onu kullanır; '
      'yoksa harita irtifası kullanılır. Örnek: 126 m.';
  static const humidity =
      'Bağıl nem, yüzde olarak (0–100). Etkisi küçüktür: nemli hava biraz '
      'daha hafiftir. Hava durumunda yazar. Örnek: %60.';
  static const altitude =
      'Atış yerinin deniz seviyesinden yüksekliği. Basınç boşsa basınç '
      'irtifadan tahmin edilir (standart atmosfer). Basınç doluysa irtifa '
      'hesaba ayrıca girmez; ölçülen basınç irtifayı zaten içerir. Telefonda '
      'veya haritada yazar. Örnek: 1000 m.';
  static const windSpeed =
      'Rüzgârın hızı. Anemometre (ör. Kestrel) ile atış yerinde ölçmek en '
      'doğrusudur. Yan rüzgâr saçmayı yana taşır; sapma BC ile hesaplanır. '
      'Örnek: 3 m/s.';
  static const windSpeedFirearm =
      'Rüzgârın hızı. Anemometre (ör. Kestrel) ile atış yerinde ölçmek en '
      'doğrusudur. Yan rüzgâr mermiyi yana taşır; sapma BC ile hesaplanır. '
      'Örnek: 3 m/s.';
  static const windDirection =
      'Rüzgârın NEREDEN estiği, saat olarak (1–12). Kutunun altındaki '
      'kadranda rüzgârın geldiği saate dokunun; değer kutuya girilir. '
      'Hedefe dönün: hedef saat '
      '12, sağınız saat 3, arkanız saat 6, solunuz saat 9. Hava durumu '
      'rüzgâr yönünü pusulaya göre verir, atış yönünüzü bilmez; bu yüzden '
      'bu değeri siz girin. Örnek: soldan esiyorsa 9, sağ önden esiyorsa 1 '
      'veya 2.';
  static const ranges =
      'Tabloda görmek istediğiniz mesafeler, virgülle ayrılmış. Örnek: '
      '10, 20, 30, 40, 50.';
  static const shotRange =
      'Hedefe olan mesafe. Telemetre (lazer mesafe ölçer) ile ölçün veya '
      '"Haritadan ölç" ile seçin. Örnek: 45 m.';
  static const gravity =
      'Bulunduğunuz yerdeki yerçekimi, m/s². "Konumdan hesapla" enleminizden '
      've irtifanızdan hesaplar; elle de yazabilirsiniz. Türkiye\'de yaklaşık 9,80; '
      'örneğin Ankara (900 m) 9,7988. Kapalıyken standart 9,80665 kullanılır.';
  static const proShotRange =
      'Ateş edeceğiniz hedefin uzaklığı. Telemetre (lazer mesafe ölçer) ile '
      'ölçün ya da bilmiyorsanız "Haritadan ölç"e dokunup haritada kendi '
      'yerinizi ve hedefin yerini işaretleyin. Hedef ekranı bu mesafeyle açılır ve dürbün '
      'kurulmuş gelir. Boş bırakırsanız Hedef 100 m (yard biriminde 100 yd) '
      'ile açılır. Örnek: 85 m.';
  static const incline =
      'Tüfek eğimi: hedefe bakış çizgisinin yatayla yaptığı açı. Yukarı '
      'atışta +, aşağı atışta −. Yokuşta saçma daha az düşer; yukarı ve aşağı '
      'atışta düz atıştan daha az yükseltme gerekir. Mesafe, telemetrenin '
      'ölçtüğü eğik mesafedir. "Kamerayla ölç" ile telefonun arka kamerasını '
      'hedefe çevirerek ölçün. Örnek: −15°.';
  static const inclineFirearm =
      'Tüfek eğimi: hedefe bakış çizgisinin yatayla yaptığı açı. Yukarı '
      'atışta +, aşağı atışta −. Yokuşta mermi daha az düşer; yukarı ve aşağı '
      'atışta düz atıştan daha az yükseltme gerekir. Mesafe, telemetrenin '
      'ölçtüğü eğik mesafedir. "Kamerayla ölç" ile telefonun arka kamerasını '
      'hedefe çevirerek ölçün. Örnek: −15°.';
  static const cant =
      'Dürbün eğimi: dürbünün dikey çizgisinin tam dikeyden sağa veya sola '
      'yatma açısı. Sağa (saat 3 yönüne) yatık +, sola −. Yatık dürbünde '
      'saçma yatık tarafa ve biraz aşağı gider; uygulama kule kliklerini '
      'buna göre düzeltir. Telefonu dürbüne dayayıp "Telefonla ölç" ile '
      'ölçebilirsiniz. Örnek: 3°.';
  static const cantFirearm =
      'Dürbün eğimi: dürbünün dikey çizgisinin tam dikeyden sağa veya sola '
      'yatma açısı. Sağa (saat 3 yönüne) yatık +, sola −. Yatık dürbünde '
      'mermi yatık tarafa ve biraz aşağı gider; uygulama kule kliklerini '
      'buna göre düzeltir. Telefonu dürbüne dayayıp "Telefonla ölç" ile '
      'ölçebilirsiniz. Örnek: 3°.';
  static const coriolis =
      'Dünyanın dönüşü uçuştaki saçmayı çok az saptırır: kuzey yarımkürede '
      'sağa, doğuya atışta biraz yukarı, batıya atışta biraz aşağı. Uzun '
      'uçuş süresinde (uzun mesafe) önem kazanır; havalı tüfekte 100 m\'de '
      'milimetre düzeyindedir. Açıkken uygulama enlem ve atış yönüne göre '
      'hesaplar ve kule kliklerine ekler.';
  static const coriolisFirearm =
      'Dünyanın dönüşü uçuştaki mermiyi çok az saptırır: kuzey yarımkürede '
      'sağa, doğuya atışta biraz yukarı, batıya atışta biraz aşağı. Uzun '
      'uçuş süresinde (uzun mesafe) önem kazanır. Açıkken uygulama enlem ve '
      'atış yönüne göre '
      'hesaplar ve kule kliklerine ekler.';
  static const latitude =
      'Bulunduğunuz yerin enlemi, derece. Kuzey yarımküre +, güney −. '
      'Türkiye için yaklaşık 36–42. "Konumdan al" telefonun konumunu '
      'kullanır. Örnek: 39,9 (Ankara).';
  static const azimuth =
      'Hedefe atış yönü, kuzeyden saat yönünde derece: kuzey 0, doğu 90, '
      'güney 180, batı 270. "Pusuladan al" için telefonu hedefe doğru '
      'tutun. Birkaç derecelik hata Coriolis sonucunu fark edilir '
      'değiştirmez. Örnek: 135.';
  static const tubePressure =
      'Şu an tüpte kalan basınç, bar; tüfeğin manometresinden okuyun. '
      'Regülatörlü tüfekte regülatör basıncının üstündeyse hız değişmez, '
      'altındaysa uyarı çıkar. Profil > Mühimmat\'ta basınca göre hız '
      'ölçümleri varsa hız onlardan bulunur. Boş bırakırsanız profil hızı '
      'kullanılır. Yalnızca PCP. Örnek: 160.';
  static const turretScale =
      'Kulenin yazdığı kadar çevirmeyebilir. Kule testi: dürbünü 10 MRAD '
      '(ya da 30 MOA) yukarı çevirip 100 m\'de ızgaralı hedefte gerçek kaymayı '
      'ölçün; gerçek / yazan oranını girin. Örnek: gerçek 9,8 MRAD ise 0,98. '
      'Boş bırakırsanız 1 (düzeltme yok). Klikler bu katsayıya göre ayarlanır.';
  static const windMax =
      'Rüzgârın sert estiği (hamle) andaki hızı. "Düzeltme al" Hava '
      'Durumu\'ndaki rüzgâr hızı × 1,5 yazar (karada tipik hamle oranı); hava '
      'verisi yeni rüzgâr getirince kendiliğinden güncellenir. Kendi '
      'ölçtüğünüz değeri de yazabilirsiniz, o değiştirilmez. Boşsa aralık '
      'gösterilmez. '
      'Hedef sayfası yan düzeltmeyi bu aralıkta gösterir. Örnek: rüzgâr '
      '2 m/s ise 3.';
  static const windObservation =
      'Anemometre yoksa rüzgârı çevreden okuyun: duman, yaprak, dal, toz. '
      'Listedeki tarifler Beaufort ölçeğinin kara tanımlarıdır (WMO, '
      'MeteoSwiss). Seçtiğiniz sınıfın orta değeri Rüzgâr hızına, üst '
      'değeri En yüksek rüzgâra yazılır; ikisini de elle değiştirebilirsiniz. '
      'Dikkat: bu hızlar açık arazide 10 m yükseklik içindir. Atıcının '
      'durduğu 1–2 m yükseklikte rüzgâr genellikle daha zayıftır; uygulama '
      'bunu düzeltmez, gerekirse değeri elle küçültün. Örnek: yapraklar ve '
      'ince dallar durmadan kıpırdıyorsa Orta, 4,4 m/s.';
  static const windMid =
      'Hedefe giden yolun ortasındaki rüzgârın tahmini hızı. Yapraklara, '
      'çimene veya bayraklara bakarak tahmin edin. Örnek: 3 m/s. Boşsa sizin '
      'yanınızdaki rüzgâr kullanılır.';
  static const windFar =
      'Hedefin yanındaki rüzgârın tahmini hızı. Örnek: 4 m/s. Boşsa yol '
      'ortasındaki (o da boşsa sizin yanınızdaki) rüzgâr kullanılır.';
  static const zeroUp =
      'Sıfır mesafesinde grubun ortası artıdan kaç cm yukarıda (+) veya '
      'aşağıda (−). Örnek: 0,5 ya da -0,3.';
  static const zeroRight =
      'Sıfır mesafesinde grubun ortası artıdan kaç cm sağda (+) veya solda '
      '(−). Örnek: 0,4 ya da -0,2.';
  static const group =
      'Sıfır mesafesinde 5 atışlık grubun en uzak iki deliği arası, cm. '
      'Örnek: 25 m\'de 1,2 cm.';
  static const sd =
      'Hız farkı (SD), fps: kronograf cihazının 5–10 atış sonrası gösterdiği '
      'standart sapma. Örnek: 4 fps. Bilmiyorsanız boş bırakın.';
  static const targetSize =
      'Vurmak istediğiniz alanın çapı, cm. Kâğıt hedefte halkanın, avda hayati '
      'bölgenin çapı. Boş bırakırsanız 10 cm. Örnek: tavşan 5 cm, karaca 15 cm.';
  static const rangeError =
      'Mesafeyi ne kadar yanlış ölçebileceğiniz, ±. Lazer mesafe ölçerde '
      'genelde ±1 m; göz kararında daha fazla. Boş bırakırsanız ±1.';
  static const bcError =
      'BC değerinden ne kadar emin olduğunuz, ± %. Üretici değeri için %3–5; '
      'kendiniz doğruladıysanız %1–2. Boş bırakırsanız hesaba katılmaz.';
  static const wezShotCount =
      'Hedefe kaç atış yapmayı düşündüğünüz. 1 atışta yalnız ilk atış '
      'isabet olasılığı görünür; daha fazlasında Hedef ekranı bu kadar '
      'atışta en az bir isabet şansını da gösterir. Grup ve hız farkı her '
      'atışta değişir; mesafe, rüzgâr ve BC hatası düzeltilmeden atılan '
      'bütün atışlarda aynı kalır, bu yüzden tekrar atmak şansı sanıldığı '
      'kadar artırmaz. Örnek: avda 1, hedef atışında 3 veya 5.';
  static const targetSpeed =
      'Hedefin yürüyüş/koşu hızı, m/s. Uygulama uçuş süresine göre ne kadar '
      'önüne nişan alınacağını gösterir. Örnek: yürüyen hayvan ~1 m/s, '
      'tırıs ~3 m/s.';
  static const bulletLength =
      'Merminin (slug\'ın) burundan tabana uzunluğu, milimetre olarak. '
      'Kumpasla ölçün. Dönüş kararlılığı ve spin drift buna göre hesaplanır. '
      'Boşsa hesaplanmaz. '
      'Örnek: .25 slug ~10 mm, .308 168 gr ~31 mm.';
  static const targetDirection =
      'Hedefin hangi yöne hareket ettiği: önüne, yani gittiği yöne nişan '
      'alınır.';
}
