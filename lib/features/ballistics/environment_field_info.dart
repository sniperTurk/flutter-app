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
  static const pressure =
      'Bulunduğunuz yerde ölçülen gerçek (istasyon) hava basıncı. Hava '
      'durumu uygulamalarının çoğu deniz seviyesine indirgenmiş basıncı '
      '(QNH, ~1013 hPa) verir; yüksek yerde bu değer hesabı bozar (1000 m '
      'irtifada gerçek basınç ~900 hPa). Kestrel, barometre veya Araçlar > '
      'hesaplayıcılar ile deniz seviyesinden istasyon basıncına çevirin.';
  static const humidity =
      'Bağıl nem, yüzde olarak (0–100). Etkisi küçüktür: nemli hava biraz '
      'daha hafiftir. Hava durumunda yazar. Örnek: %60.';
  static const altitude =
      'Atış yerinin deniz seviyesinden yüksekliği. Bilgi amaçlı kaydedilir; '
      'hesap istasyon basıncını kullanır, irtifa hesaba ayrıca girmez. '
      'Basıncı doğru girdiyseniz irtifa zaten içindedir.';
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
  static const turretScale =
      'Kulenin yazdığı kadar çevirmeyebilir. Kule testi: dürbünü 10 MRAD '
      '(ya da 30 MOA) yukarı çevirip 100 m\'de ızgaralı hedefte gerçek kaymayı '
      'ölçün; gerçek / yazan oranını girin. Örnek: gerçek 9,8 MRAD ise 0,98. '
      'Boş bırakırsanız 1 (düzeltme yok). Klikler bu katsayıya göre ayarlanır.';
  static const windMax =
      'Rüzgârın sert estiği (hamle) andaki hızı. Otomatik doldurulur: Hava '
      'Durumu\'ndaki rüzgâr hızı × 1,5 (karada tipik hamle oranı). Kendi '
      'ölçtüğünüz değeri yazabilirsiniz. Silerseniz aralık gösterilmez; '
      '"Otomatik doldur" yeniden otomatik yapar. '
      'Hedef sayfası yan düzeltmeyi bu aralıkta gösterir. Örnek: rüzgâr '
      '2 m/s ise 3.';
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
      'atışta en az bir isabet şansını da gösterir. Atışlar birbirinden '
      'bağımsız sayılır; mesafe veya rüzgâr hatası düzeltilmeden tekrar '
      'atarsanız gerçek şans biraz daha düşüktür. Örnek: avda 1, hedef '
      'atışında 3 veya 5.';
  static const targetSpeed =
      'Hedefin yürüyüş/koşu hızı, m/s. Uygulama uçuş süresine göre ne kadar '
      'önüne nişan alınacağını gösterir. Örnek: yürüyen hayvan ~1 m/s, '
      'tırıs ~3 m/s.';
  static const spinDrift =
      'Dönen mermi uçarken yivin döndüğü yöne doğru yana kayar (sağ yivde '
      'sağa). Etki uçuş süresiyle büyür; slug ve ateşli tüfekte uzun '
      'mesafede önemlidir. Litz formülüyle yaklaşık hesaplanır; diabolo '
      'pellet için geçerli değildir. Yiv yönü ve yiv oranı profilden alınır.';
  static const bulletLength =
      'Merminin (slug\'ın) burundan tabana uzunluğu, milimetre olarak. '
      'Kumpasla ölçün. Dönüş kararlılığı ve spin drift buna göre hesaplanır. '
      'Örnek: .25 slug ~10 mm, .308 168 gr ~31 mm.';
  static const targetDirection =
      'Hedefin hangi yöne hareket ettiği: önüne, yani gittiği yöne nişan '
      'alınır.';
}
