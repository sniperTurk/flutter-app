/// Gizlilik politikası text (Araçlar > Gizlilik politikası).
///
/// GENERATED from the Turkish policy in
/// docs/app-store/03-gizlilik-politikasi.md by
/// tools/data_gen/generate_privacy_policy.py; do not edit by hand
/// (tools/test_privacy_policy_sync.py compares the two). The text is
/// built into the app so the policy opens offline (App Review
/// 5.1.1(i)).
class PrivacyPolicySection {
  final String title;
  final List<String> paragraphs;

  const PrivacyPolicySection(this.title, this.paragraphs);
}

abstract final class PrivacyPolicyContent {
  static const String heading = 'SNIPER TÜRK — Gizlilik Politikası';

  static const String updated =
      'Son güncelleme: 14 Ekim 2026 · Uygulama sürümü 1.0.0 · İletişim: '
      'Sekerbirol76@gmail.com';

  static const List<PrivacyPolicySection> sections = [
    PrivacyPolicySection('Kısaca', [
      'SNIPER TÜRK hesap istemez; reklam ve izleme (tracking) içermez. '
          'Uygulamanın bize ait bir sunucusu yoktur; profilleriniz ve ayarlarınız '
          'bize gönderilmez. Bazı özellikler çalışmak için üçüncü taraf '
          'servislerine istek gönderir ve uygulamada Google Maps SDK bulunur. '
          'Bunların hepsi aşağıda tek tek yazılıdır.',
    ]),
    PrivacyPolicySection('1. Cihazınızda saklanan veriler', [
      'Tüfek, dürbün ve mühimmat profilleriniz, ayarlarınız, kendi eklediğiniz'
          ' katalog girdileri, Hava Durumu ve Pro sayfalarına girdiğiniz değerler,'
          ' kronograf serileri, atış günlüğü, paralaks işaretleri ve su terazisi '
          'kalibrasyonu yalnızca cihazınızda saklanır.',
      'Pro sayfasında "Konumdan al" veya "Konumdan hesapla" düğmesine '
          'basarsanız Coriolis için yaklaşık enlem (iki ondalık, yaklaşık 1 km) ve'
          ' ondan hesaplanan yerel yerçekimi değeri de cihazda saklanır. "Basıncı '
          'telefondan al" ile gelen irtifa da Hava Durumu değerleriyle birlikte '
          'cihazda kalır.',
      'Bu veriler bize veya üçüncü taraflara gönderilmez. Uygulamayı silmek bu'
          ' verileri siler.',
    ]),
    PrivacyPolicySection('2. Konum', [
      'Konum izni yalnızca uygulama açıkken ve yalnızca sizin başlattığınız '
          'işlemlerde kullanılır; arka planda konum kullanılmaz.',
      '• Hava verisi: Hava Durumu sayfasında konumdan hava verisi aldığınızda '
          'veya Araçlar > Hava & Rüzgâr sayfasını açtığınızda konumunuz iki '
          'ondalığa (yaklaşık 1 km) yuvarlanarak Norveç Meteoroloji Enstitüsü\'nün'
          ' hava servisine (MET Norway, api.met.no) gönderilir. Uygulama bu konumu'
          ' saklamaz; gelen hava değerleri ekranda gösterilir veya kutulara '
          'doldurulur.',
      '• Basınç ve irtifa: "Basıncı telefondan al" düğmesi aynı dokunuşta '
          'konumdan irtifayı okur. İrtifa hiçbir yere gönderilmez.',
      '• Coriolis ve yerel yerçekimi (Pro): enlem ve irtifa konumdan okunur, '
          'hesap cihazda yapılır (bkz. 1).',
      '• Haritadan mesafe: harita açıldığında konumunuza getirilir. Seçtiğiniz'
          ' nişancı ve hedef noktaları saklanmaz ve bize gönderilmez.',
      '• Özel konum için mesafe (Hesaplayıcılar): hesap cihazda yapılır, konum'
          ' gönderilmez.',
      'Konum izni vermezseniz değerleri elle girebilirsiniz. İzni istediğiniz '
          'zaman iPhone Ayarlar > Gizlilik ve Güvenlik > Konum Servisleri '
          'bölümünden geri alabilirsiniz.',
    ]),
    PrivacyPolicySection('3. Harita, Google Maps SDK ve yer arama', [
      '• Haritadan mesafe ekranındaki uydu görüntüsü, uygulamanın sürümüne '
          'göre Esri (ArcGIS World Imagery, server.arcgisonline.com) veya Google '
          'Maps üzerinden indirilir. Görüntülediğiniz bölge bu sağlayıcıya istek '
          'olarak gider ve sağlayıcı IP adresinizi görebilir.',
      '• Uygulama Google Maps SDK for iOS\'u içerir. Google\'ın bu SDK ile '
          'yayımladığı gizlilik bildirimine göre SDK; cihaz kimliğini (sizinle '
          'ilişkili; analiz ve uygulamanın çalışması için), diğer veri türlerini '
          '(sizinle ilişkili; analiz için) ve çökme verisi, performans verisi ile '
          'ürün etkileşimini (sizinle ilişkili değil; analiz için) toplar. Google '
          'Maps\'i uygulamaya bağlayan Flutter eklentisinin bildirimi ayrıca '
          'kullanıcı kimliğini (sizinle ilişkili; analiz için) sayar. Google\'ın '
          'beyanına göre bu veriler izleme (tracking) için kullanılmaz. Bu '
          'verilere biz erişmeyiz. Google Gizlilik Politikası: '
          'policies.google.com/privacy',
      '• Yer arama kutusuna yazdığınız metin, yalnızca arama düğmesine '
          'bastığınızda OpenStreetMap Nominatim servisine '
          '(nominatim.openstreetmap.org) gönderilir; yazarken hiçbir şey '
          'gönderilmez.',
    ]),
    PrivacyPolicySection('4. Kamera ve fotoğraflar', [
      'Kamera yalnızca Sight Height ekranında ve Pro sayfasındaki "Kamerayla '
          'ölç" (tüfek eğimi) ekranında kullanılır. Sight Height için galeriden '
          'yalnızca sizin seçtiğiniz tek fotoğraf alınır (sistem fotoğraf '
          'seçicisi). Fotoğraflar cihazın belleğinde işlenir; kaydedilmez, '
          'fotoğraf kitaplığınıza yazılmaz ve cihazdan çıkmaz. Uygulama ses '
          'kaydetmez.',
    ]),
    PrivacyPolicySection('5. Hareket sensörleri, barometre ve pusula', [
      'Su Terazisi, Pro sayfasındaki eğim ölçümleri ve Pusula, cihaz '
          'sensörlerini yalnızca ekranda göstermek ve hesap yapmak için okur. '
          'Barometre yalnızca Hava Durumu sayfasında "Basıncı telefondan al" '
          'düğmesine bastığınızda bir kez okunur ve değer basınç kutusuna yazılır.'
          ' Sensör verisi cihazdan çıkmaz; yalnızca su terazisi kalibrasyonu ve '
          'kutulara yazılan değerler cihazda saklanır.',
    ]),
    PrivacyPolicySection('6. Dosyalar, yedek ve paylaşım', [
      '• Kendi sürüklenme eğrinizi (.drg/.csv) seçerseniz dosya cihazda okunur'
          ' ve profilinizde saklanır.',
      '• Profil sayfasındaki Yedekle, profillerinizi ve kişisel katalog '
          'girdilerinizi tek bir dosyaya yazar ve iOS paylaşım ekranına verir; '
          'dosya yalnızca sizin seçtiğiniz yere (ör. Dosyalar, iCloud Drive, '
          'Google Drive) gider. Geri yükle, sizin seçtiğiniz yedek dosyasını '
          'cihazda okur.',
      '• DOPE kartı PDF\'i, yalnızca paylaşım ekranında sizin seçtiğiniz '
          'hedefe gider.',
    ]),
    PrivacyPolicySection('7. Üçüncü taraflar', [
      'Yukarıda adı geçen servisler (MET Norway, Esri, Google, OpenStreetMap '
          'Nominatim) yalnızca ilgili özelliği çalıştırmak için kullanılır ve '
          'kendi gizlilik koşulları geçerlidir. Uygulamada reklam ağı ve bize ait '
          'bir analiz aracı yoktur; veri satılmaz.',
    ]),
    PrivacyPolicySection('8. Çocuklar', [
      'Uygulama çocuklara yönelik değildir ve bilerek çocuklardan veri '
          'toplamaz.',
    ]),
    PrivacyPolicySection('9. Saklama, silme ve izinlerin geri alınması', [
      'Bizde sizinle ilişkilendirilmiş veri tutulmaz; silinecek bir hesap '
          'yoktur. Cihazdaki verileri uygulamayı silerek kaldırabilirsiniz. Konum,'
          ' kamera, fotoğraf ve hareket izinlerini iPhone Ayarlar\'dan istediğiniz'
          ' zaman geri alabilirsiniz. Google\'ın topladığı veriler için Google\'ın'
          ' gizlilik araçları geçerlidir.',
    ]),
    PrivacyPolicySection('10. Balistik uyarısı', [
      'Uygulama bir hesap yardımcısıdır; sonuçlar gerçek atışla '
          'doğrulanmalıdır.',
    ]),
    PrivacyPolicySection('11. Değişiklikler ve iletişim', [
      'Bu politika değişirse yeni tarih bu sayfada yazılır. Sorularınız için: '
          'Sekerbirol76@gmail.com',
    ]),
  ];
}
