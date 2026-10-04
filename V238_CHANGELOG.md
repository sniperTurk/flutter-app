# V238

- Sight Height için gerçek kamera/galeri girişinin ilk production adaptörü eklendi (`image_picker`).
- Ön fotoğraf hizalama kanıtı olarak, yatay yan fotoğraf ise kullanıcı kontrollü dört noktalı ölçüm için kullanılabiliyor.
- Otomatik vision iddiası yoktur; kullanıcı referans ve optik/namlu ekseni noktalarını kendisi işaretler.
- Kamera/Fotoğraf Arşivi iOS kullanım açıklamaları deterministic Info.plist yapılandırmasına eklendi.
- Fotoğraf erişimi başarısız olduğunda mevcut elle piksel girişi kullanılmaya devam eder.
- Flutter/Xcode derlemesi bu ortamda doğrulanmadı; image_picker sürümü gerçek Flutter toolchain ile ayrıca doğrulanmalıdır.
