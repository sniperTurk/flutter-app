# v248 — Pusula ve Su Terazisi

- Ana ekrana profilden bağımsız iki ayrı araç eklendi.
- Pusula: cihazın manyetik başlık akışı, yön göstergesi, sensör/izin hata durumu, kalibrasyon uyarısı.
- Su terazisi: ivmeölçerden çift eksenli eğim, kabarcık göstergesi, ±1° düz göstergesi ve oturumluk sıfırlama.
- flutter_compass ve sensors_plus bağımlılıkları eklendi.
- iOS Runner/Info.plist bu kaynak paketinde bulunmuyor: gerçek iOS projesi oluşturulurken NSLocationWhenInUseUsageDescription ve gerekli konum izni akışı eklenmeli. Pusula iOS'ta izin ve donanım gerektirir.
- Flutter SDK bulunmayan ortamda flutter pub get/analyze/test ve fiziksel sensör testleri çalıştırılamadı.
