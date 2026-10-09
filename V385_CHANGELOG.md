# V385 — App Store uyarısı ITMS-90683 (konum izin metni)

Kaynak: `main` @ `6ab3003`.

- Apple, Build 49 yüklemesinde `NSLocationAlwaysAndWhenInUseUsageDescription`
  anahtarının eksik olduğunu bildirdi (ITMS-90683, uyarı). Sebep: geolocator
  eklentisinin ikili kodu "her zaman konum" API'sine referans veriyor;
  uygulama bu izni hiç istemiyor.
- `tools/configure_ios_info_plist.py`: anahtar dürüst bir Türkçe metinle
  eklendi — konum yalnızca Hava & Rüzgâr ekranı açıkken kullanılır, arka
  planda kullanılmaz, saklanmaz. Çalışma anında yalnızca "kullanırken" izni
  istenir (`Geolocator.requestPermission`); davranış değişmedi.
- Testler: anahtarın varlığı ve "arka planda konum kullanmaz" ifadesi
  doğrulanır; eski `NSLocationAlwaysUsageDescription` ve fotoğraf
  kitaplığına yazma izni hâlâ yasak.
