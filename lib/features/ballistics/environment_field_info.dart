/// Short explanations behind the ⓘ button of every Hava Durumu / Atış field.
///
/// Project rule (owner, 2026-10-07): every value the user enters gets an
/// explanation. Keep them short, concrete and in Turkish; say where the value
/// can be found and give a typical example.
abstract final class EnvironmentFieldInfo {
  static const temperature =
      'Atış yerindeki hava sıcaklığı. Sıcak hava daha seyrektir; saçma daha '
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
  static const windDirection =
      'Rüzgârın NEREDEN estiğini seçin. Hedef 0° (saat 12) yönünde; açı saat '
      'yönünde artar: 90° (saat 3) = sağdan, 180° (saat 6) = arkadan, 270° '
      '(saat 9) = soldan. 45°, 135°, 225°, 315° ara yönlerdir. ChairGun, '
      'Strelok ve Kestrel de böyle kullanır. Soldan esen rüzgâr saçmayı '
      'sağa taşır.';
  static const ranges =
      'Tabloda görmek istediğiniz mesafeler, virgülle ayrılmış. Örnek: '
      '10, 20, 30, 40, 50.';
  static const shotRange =
      'Hedefe olan mesafe. Telemetre (lazer mesafe ölçer) ile ölçün veya '
      '"Haritadan" ile seçin. Örnek: 45 m.';
  static const incline =
      'Tüfek eğimi: hedefe bakış çizgisinin yatayla yaptığı açı. Yukarı '
      'atışta +, aşağı atışta −. Yokuşta saçma daha az düşer; yukarı ve aşağı '
      'atışta düz atıştan daha az yükseltme gerekir. Mesafe, telemetrenin '
      'ölçtüğü eğik mesafedir. "Kamerayla ölç" ile telefonun arka kamerasını '
      'hedefe çevirerek ölçün. Örnek: −15°.';
  static const cant =
      'Dürbün eğimi: dürbünün dikey çizgisinin tam dikeyden sağa veya sola '
      'yatma açısı. Sağa (saat 3 yönüne) yatık +, sola −. Yatık dürbünde '
      'saçma yatık tarafa ve biraz aşağı gider; uygulama kule kliklerini '
      'buna göre düzeltir. Telefonu dürbüne dayayıp "Telefonla ölç" ile '
      'ölçebilirsiniz. Örnek: 3°.';
  static const coriolis =
      'Dünyanın dönüşü uçuştaki saçmayı çok az saptırır: kuzey yarımkürede '
      'sağa, doğuya atışta biraz yukarı, batıya atışta biraz aşağı. Uzun '
      'uçuş süresinde (uzun mesafe) önem kazanır; havalı tüfekte 100 m\'de '
      'milimetre düzeyindedir. Açıkken uygulama enlem ve atış yönüne göre '
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
      'Kulenin yazdığı kadar çevirmeyebilir. Kule testi: dürbünü 10 mrad '
      '(ya da 30 MOA) yukarı çevirip 100 m\'de ızgaralı hedefte gerçek kaymayı '
      'ölçün; gerçek / yazan oranını girin. Örnek: gerçek 9,8 mrad ise 0,98. '
      'Boş bırakırsanız 1 (düzeltme yok). Klikler bu katsayıya göre ayarlanır.';
  static const windMax =
      'Rüzgâr sabit değilse en yüksek hızını girin. Hedef sayfası yan '
      'düzeltmeyi Hava Durumu\'ndaki rüzgârdan bu hıza kadar bir aralık olarak '
      'gösterir. Örnek: rüzgâr 2–4 m/s arası ise burada 4.';
  static const targetSpeed =
      'Hedefin yürüyüş/koşu hızı, m/s. Uygulama uçuş süresine göre ne kadar '
      'önüne nişan alınacağını gösterir. Örnek: yürüyen hayvan ~1 m/s, '
      'tırıs ~3 m/s.';
  static const targetDirection =
      'Hedefin hangi yöne hareket ettiği: önüne, yani gittiği yöne nişan '
      'alınır.';
}
