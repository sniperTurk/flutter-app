# V217 — Küresel dürbün markaları kaynak listesi

- `data/global_scope_brands.csv`: Kullanıcının sağladığı 21 dürbün markasını ayrı, benzersiz ID'li CSV kayıtlarına dönüştürür. Mevcut `CatalogRepository.scopes` model kayıtları korunmuştur; marka referans kayıtları teknik özellikleri doğrulanmış model kayıtları değildir.
- Swarovski Optik, March/DEON ve EOTECH için resmî üretici kaynakları kontrol edilmiştir. Diğer 18 marka `user_supplied_unverified` olarak tutulur. Ülke sütunu merkez/marka menşeidir, tüm ürünlerin imalat ülkesi değildir.
- `tools/test_global_scope_brands.py`: 21 kayıt, benzersiz ID, zorunlu alanlar, kaynak bağlantıları ve doğrulama statülerini test eder.
- Bu aşamada uygulama içi marka filtresi bağlanmamıştır; model bazlı FFP/SFP, MRAD/MOA ve optik özellikleri yalnızca resmî model kaynaklarıyla eklenmelidir.
- G1/G7 production gate CLOSED kalır. Gerçek Flutter, iOS Simulator ve fiziksel iPhone testleri çalıştırılmamıştır.
