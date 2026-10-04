# V216 — Küresel üretici kaynak listesi

- `data/global_manufacturers.csv`: Kullanıcının sağladığı 25 firma/marka girdisi, Kral Arms'ın iki platforma ayrılmasıyla 26 platform-spesifik kayıt olarak eklendi.
- 5 üretici/platform kaydı resmi üretici kaynaklarıyla kontrol edildi: Hatsan PCP, Kral Arms PCP ve ateşli, AirForce PCP, FX PCP. Diğer 21 kayıt `user_supplied_unverified` olarak işaretlendi; bunlar üretici onaylı model/spec kayıtları olarak kullanılmamalıdır.
- ABD markalarının marka/üretici ayrımı, Umarex USA'nın üretim menşei ve tarihi modeller konusunda açıklayıcı notlar eklendi.
- `tools/test_global_manufacturers.py` benzersiz ID, platform ayrımı, kaynak zorunluluğu ve durum sözlüğünü denetler.
- Bu sürüm CSV üretici referans listesini ekler; doğrulanmamış modelleri mevcut `CatalogRepository.rifles` içine otomatik sokmaz. Uygulama içi üretici filtreleme henüz bağlı değildir.
- Gerçek Flutter/Xcode/Simulator/iPhone testleri bu ortamda çalıştırılmadı. G1/G7 fail-closed durumu değişmedi.
