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
      'Rüzgârın NEREDEN estiği, atış yönüne göre derece. 0 = tam karşıdan '
      '(yüze), 90 = tam soldan, 180 = tam arkadan, 270 = tam sağdan. Saat '
      'kadranıyla: 9 yönü = 90°, 3 yönü = 270°. Soldan esen rüzgâr saçmayı '
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
}
