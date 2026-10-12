/// ⓘ texts of the Kronograf page (owner rule, 2026-10-07: every entered
/// value says what it is, where to find it and gives an example).
abstract final class ChronoFieldInfo {
  static const unit =
      'Kronografınızın gösterdiği hız birimi. Cihazın ayarında yazar; çoğu '
      'kronograf fps gösterir. Örnek: fps.';
  static const ammoTemperature =
      'Seriyi attığınız andaki fişeğin sıcaklığı. Fişek kutusuna konan bir '
      'termometreyle ölçün. Profilde barut katsayısı varsa hız bu sıcaklığa '
      'göre profile çevrilir; farklı sıcaklıklarda kaydedilen seriler barut '
      'katsayısını verir. Örnek: 32 °C.';
  static const velocities =
      'Kronografın her atışta gösterdiği hız, atış sırasıyla, her satıra '
      'bir hız. En az 3 atış gerekir; 10 atış daha güvenilirdir. Ondalık için '
      'virgül kullanın. Örnek: 2631, alt satıra 2618.';
}
