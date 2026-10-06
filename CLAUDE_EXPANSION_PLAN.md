# SNIPER TÜRK — BALİSTİK PLATFORMU MASTER GELİŞTİRME PLANI

## 1. Amaç

Bu doküman, mevcut `sniperTurk/flutter-app` projesini sıfırdan yazmadan, mevcut mimariyi ve doğrulama altyapısını koruyarak profesyonel bir balistik hesaplama ve simülasyon platformuna dönüştürmek için Claude Code'a uygulanacak ana geliştirme planıdır.

Bu proje yalnızca PCP uygulaması değildir.

Hedef platform:

- Ateşli tüfek balistiği
- PCP / havalı tüfek balistiği
- Mermi/proje kütlesi ve aerodinamik verileri
- Dış balistik hesaplama
- Atmosfer ve çevre koşulları
- Rüzgâr ve 3B hareket modeli
- Sıfırlama ve nişangâh geometrisi
- Optik/dürbün verileri
- Yörünge ve DOPE tabloları
- Balistik profil yönetimi
- Grafikler ve hesaplama karşılaştırmaları
- Genişletilebilir ürün/veri tabanı
- Veri içe/dışa aktarma
- Bağımsız solver doğrulaması
- Profesyonel Flutter kullanıcı arayüzü

Archery/yay sistemi bu projenin kapsamı değildir.

---

## 2. Temel Kural: Mevcut Projeyi Korumak

Claude Code:

- Projeyi yeniden oluşturmayacak.
- Flutter projesini regenerate etmeyecek.
- Mevcut çalışan özellikleri gereksiz yere taşımayacak.
- Mevcut CI ve doğrulama kapılarını kaldırmayacak.
- `CLAUDE.md` içindeki repository kurallarını öncelikli kabul edecek.
- `pubspec.lock` dosyasını gereksiz yere değiştirmeyecek.
- Çalıştırılmamış test veya CI sonucunu başarılı olarak raporlamayacak.
- Mevcut üretim güvenlik/doğrulama kapılarını bypass etmeyecek.

Öncelik: mevcut sistemi koru -> ölç -> doğrula -> genişlet.

---

# 3. Açık Kaynak Referansların Kullanım Amacı

Aşağıdaki projeler doğrudan kopyalanmayacak; algoritma, veri modeli, test yaklaşımı ve mimari fikirler için referans olarak incelenecektir.

### Ballistics Lab / bclibc
https://github.com/ballistics-lab/bclibc

İncelenecek konular:

- 3-DOF balistik model
- sayısal integrasyon
- drag modeli
- atmosfer
- Coriolis
- spin drift
- yörünge çözümü
- fiziksel model ayrıştırması

### dart-bclibc
https://github.com/ballistics-lab/dart-bclibc

İncelenecek konular:

- Dart tarafındaki fizik API tasarımı
- birim yönetimi
- veri modelleri
- Flutter/Dart entegrasyonu
- platform bağımsız solver yaklaşımı

### py-ballisticcalc
https://github.com/o-murphy/py-ballisticcalc

İncelenecek konular:

- solver mimarisi
- projectile / weapon / atmosphere ayrımı
- drag modelleri
- BC ve drag-function yaklaşımı
- trajectory sonuçları
- birim dönüşümleri
- referans hesaplama

### eBalistyka
https://github.com/o-murphy/ebalistyka

İncelenecek konular:

- profil yaklaşımı
- mühimmat/ekipman verisi
- trajectory tabloları
- çevre parametreleri
- grafikler
- reticle/optik gösterimleri
- import/export
- kullanıcı akışı

### BallisticCalculator1
https://github.com/gehtsoft-usa/BallisticCalculator1

İncelenecek konular:

- 3-DOF hesaplama
- drag ve atmosfer
- ölçü/birim soyutlaması
- trajectory sonuç modeli
- custom drag
- persistence
- test mimarisi

### Lisans kuralı

Her repository için:

1. LICENSE dosyasını incele.
2. Transitive dependency lisanslarını incele.
3. Kod/asset/UI/marka kopyalama yapma.
4. Lisans gerekliliklerini ihlal etme.
5. Gerekirse clean-room yeniden implementasyon yap.
6. Harici sayısal veri kullanılıyorsa provenance kaydı tut.

---

# 4. Hedef Mimari

Mevcut Flutter mimarisi korunacak.

Önerilen mantıksal katmanlar:

UI
-> Feature/Application
-> Domain Models
-> Ballistic Engine
-> Numerical Engine
-> Reference Data / Persistence

Fizik motoru Flutter widget'larına bağımlı olmayacak.

Önerilen domain sınırları:

- `core/units`
- `core/physics`
- `core/numerics`
- `core/ballistics`
- `core/environment`
- `core/validation`
- `models/ammunition`
- `models/rifle`
- `models/optic`
- `models/profile`
- `models/trajectory`
- `data/catalog`
- `data/persistence`
- `services/ballistics`
- `services/import_export`
- `features/ballistics`
- `features/profiles`
- `features/catalog`
- `features/trajectory`
- `features/environment`
- `features/optics`
- `features/charts`

Dosyaları yalnızca gerçek mimari ihtiyacı varsa taşı.

---

# 5. BALİSTİK MOTORUNUN GELİŞTİRİLMESİ

Bu projenin birinci önceliğidir.

Mevcut solver tamamen incelenmeden yeni solver yazılmayacak.

Hedef:

- deterministic hesaplama
- SI tabanlı internal units
- açık solver interface
- değiştirilebilir drag modelleri
- değiştirilebilir integrator
- trajectory result modeli
- hata/validasyon modeli
- referans vektörleri

## 5.1 Solver katmanı

Örnek kavramsal API:

- BallisticSolver
- SolverConfiguration
- SolverInput
- SolverResult
- TrajectoryPoint
- DragModel
- AtmosphereModel
- Integrator

Solver Flutter UI'dan bağımsız olmalı.

## 5.2 Sayısal integrasyon

Desteklenecek yapı:

- RK4
- gerektiğinde daha sonra farklı integrator
- timestep kontrolü
- deterministik sonuç
- yakınsama testleri

Timestep küçültüldüğünde çözümün beklenen şekilde yakınsaması test edilecek.

## 5.3 Drag

Hedef:

- G1
- G7
- ileride genişletilebilir drag function
- Mach tabanlı interpolation
- custom drag table

G1/G7 üretim özelliği ancak bağımsız referanslarla doğrulandıktan sonra production'a açılabilir.

Doğrulama başarısızsa özellik experimental kalacaktır.

---

# 6. MÜHİMMAT / PROJECTILE VERİ MODELİ

Mühimmat sistemi tek bir string alanından ibaret olmayacak.

Projectile modelinde ihtiyaç oldukça:

- üretici
- model
- varyant
- çap
- kütle
- uzunluk
- nominal BC
- BC sistemi
- drag modeli
- drag coefficient / drag table referansı
- velocity range
- kaynak
- provenance
- doğrulama durumu
- veri sürümü

bulunabilecek.

Her veri kaynağı açıkça belirtilmeli.

Yanlış veya doğrulanmamış katalog verisi production solver'a sessizce sokulmayacak.

---

# 7. TÜFEK / PCP PLATFORM SİSTEMİ

Platform seçimi korunacak ve genişletilecek.

Her platform için ayrı veri modeli:

- firearm
- PCP
- gerekiyorsa diğer uygun balistik platformlar

Platforma özel metadata ile ortak ballistic input birbirinden ayrılmalı.

Amaç:

- aynı solver altyapısını paylaşmak
- platforma özel katalogları ayırmak
- yanlış ürün/kalibre eşleşmesini önlemek
- profile içinde platform bilgisini saklamak

---

# 8. OPTİK / DÜRBÜN SİSTEMİ

Optics sistemi bağımsız domain olarak geliştirilecek.

Optic modelinde:

- üretici
- model
- büyütme
- objektif çapı
- tube bilgisi
- reticle
- adjustment unit
- click value
- adjustment range
- focal plane
- kaynak/provenance

gibi alanlar gerektiğinde desteklenebilecek.

Optik verisi trajectory hesabına yalnızca doğrulanmış matematiksel ilişki üzerinden bağlanacak.

---

# 9. ATMOSFER VE ÇEVRE MOTORU

Atmosphere modeli ballistic solver'dan ayrılacak.

Desteklenmesi hedeflenen parametreler:

- sıcaklık
- basınç
- bağıl nem
- yoğunluk
- rakım
- yerçekimi
- rüzgâr

Atmosfer modeli:

- standard atmosphere
- custom atmosphere

olarak genişletilebilir.

Yoğunluk hesabı deterministic olmalı.

Tüm çevresel parametreler solver input'una açıkça dahil edilmeli.

---

# 10. RÜZGÂR VE 3B BALİSTİK

Mevcut 2B yaklaşım yeterli görülmeyecek.

Hedef domain:

- x
- y
- z
- vx
- vy
- vz

ve bunlara bağlı kuvvetlerin açık modellenmesi.

Rüzgâr:

- yön
- hız
- mümkün olduğunda farklı mesafe katmanları

ile temsil edilebilir.

3B solver devreye alınmadan önce:

- koordinat sistemi
- işaret konvansiyonu
- referans eksenleri
- dönüşümler

dokümante edilmelidir.

---

# 11. ZERO / SIGHT GEOMETRY

Sıfırlama sistemi solver ile UI arasında dağınık hesaplanmayacak.

Ayrı bir model:

- zero distance
- sight height
- scope axis / bore axis ilişkisi
- sight geometry
- trajectory reference

tutmalı.

Zero hesabı regression testleriyle korunmalı.

---

# 12. TRAJECTORY / DOPE SİSTEMİ

Trajectory sonucu yalnızca tek bir son değer olmayacak.

Mesafe boyunca tablo üretilebilecek.

Örnek sonuç alanları:

- distance
- time
- velocity
- energy
- drop
- trajectory
- wind effect
- remaining state
- model status

Kullanıcı farklı mesafe çözünürlükleri seçebilmeli.

Tablo ile grafik aynı trajectory result kaynağını kullanmalı.

---

# 13. BALİSTİK PROFİL SİSTEMİ

Tek tek input girmek yerine kalıcı ballistic profile modeli geliştirilecek.

Bir profil:

- platform
- projectile/ammunition
- optic
- zero
- environment
- solver configuration
- units
- notes
- model version
- catalog references

ile ilişkili olabilir.

Profil verisi versioned persistence ile saklanacak.

---

# 14. HESAPLAMA KARŞILAŞTIRMA SİSTEMİ

Aynı input ile:

- farklı solver
- farklı drag modeli
- farklı integrator
- farklı timestep
- farklı atmosphere

karşılaştırılabilmeli.

Amaç:

- solver doğrulama
- regression
- hata analizi
- kullanıcıya model farklarını gösterme

Bir sonuç referansla eşleşmiyorsa beklenen değeri değiştirmek yerine farkın nedeni araştırılmalı.

---

# 15. VERİ TABANI VE KATALOG

Mevcut katalog yapısı genişletilecek.

Katalog kategorileri:

- rifles
- PCP
- ammunition
- projectiles
- optics
- reticles
- environmental presets
- ballistic models

Her kayıt:

- source
- source URL
- source date
- verification state
- schema version

bilgisine sahip olabilmeli.

Katalog verisi ile kullanıcı profili birbirine karıştırılmayacak.

---

# 16. IMPORT / EXPORT

Versioned JSON ana format olacak.

Desteklenmesi hedeflenen:

- profile export
- profile import
- trajectory export
- catalog data import
- CSV trajectory export

İleride rapor çıktısı eklenebilir.

Import sırasında:

- schema validation
- version validation
- numeric validation
- provenance validation

uygulanmalı.

Geçersiz dosya sessizce kabul edilmeyecek.

---

# 17. GRAFİK VE VERİ GÖRSELLEŞTİRME

Grafikler gerçek solver sonuçlarından beslenecek.

Hedef grafikler:

- trajectory
- drop
- velocity
- energy
- time
- wind effect
- model comparison
- convergence/error

Grafik widget'ları hesaplama yapmayacak.

Chart layer yalnızca sonuç modelini görselleştirecek.

---

# 18. PROFESYONEL BALİSTİK ARAYÜZ

Ana kullanıcı akışı gereksiz eğitim/lab ekranları etrafında tasarlanmayacak.

Ana yapı:

1. Platform
2. Profil
3. Mühimmat
4. Optik
5. Çevre
6. Balistik hesap
7. Trajectory / DOPE
8. Grafik
9. Karşılaştırma
10. Katalog
11. Ayarlar

UI teknik ama sade olmalı.

Öncelikler:

- hızlı input
- net validation
- okunabilir tablo
- hızlı profil seçimi
- açık model durumu
- açık validation status
- mobil ekranlara uygun responsive tasarım
- dark/light theme

---

# 19. VERİ KALİTESİ VE PROVENANCE

Bu proje için veri kalitesi kod kalitesi kadar önemlidir.

Her dış veri için:

- kaynak
- lisans
- tarih
- veri sürümü
- doğrulama durumu

takip edilmeli.

Özellikle:

- BC
- drag tables
- projectile dimensions
- optic specifications
- product catalog

için provenance zorunlu hale getirilmeli.

---

# 20. BAĞIMSIZ DOĞRULAMA

Mevcut py-ballisticcalc doğrulama hattı korunacak ve geliştirilecek.

Doğrulama modeli:

SNIPER TÜRK
vs
Independent Reference

Karşılaştırılacak:

- trajectory
- velocity
- time
- drop
- energy
- diğer model çıktıları

Toleranslar önceden belirlenmeli.

Başarısız test:

- production gate'i açmaz
- expected değeri değiştirmez
- solver farkının araştırılmasını başlatır

---

# 21. TEST VE VALIDASYON

Her yeni fizik özelliği için:

### Unit tests

- input validation
- unit conversion
- edge cases
- numerical invariants

### Regression tests

- frozen scenarios
- deterministic output
- convergence
- known reference values

### Integration tests

- profile -> solver
- catalog -> profile
- environment -> solver
- trajectory -> chart

### Cross implementation tests

Bağımsız solver ile karşılaştırma.

### UI tests

- input validation
- profile loading
- navigation
- result rendering

---

# 22. PERFORMANS

Uzun hesaplamalar Flutter UI isolate'ını bloklamamalı.

Gerekirse:

- isolate
- background computation
- deterministic caching

kullanılmalı.

Cache key bütün model etkileyen girdileri içermeli.

Örneğin:

- projectile
- velocity
- zero
- atmosphere
- wind
- solver version
- drag model
- timestep

değiştiğinde eski sonuç yanlışlıkla kullanılmamalı.

---

# 23. UNIT SİSTEMİ

Internal calculation için canonical SI units kullanılmalı.

UI seviyesinde:

- metric
- imperial

desteklenebilir.

Birim dönüşümleri tek bir merkezi unit layer'da yapılmalı.

Physics/domain sınıflarında dağınık dönüşüm kodu yazılmamalı.

---

# 24. GELİŞTİRME FAZLARI

## Phase 0 — Repository Audit

Önce yalnızca analiz.

Claude:

- CLAUDE.md oku
- README oku
- mevcut solver'ı incele
- modelleri incele
- catalog yapısını incele
- persistence yapısını incele
- testleri incele
- CI'ı incele
- production/experimental gate'leri listele

Çıktı:

- architecture map
- dependency map
- physics map
- data map
- test map
- risk listesi

Kod değişikliği yapma.

---

## Phase 1 — Ballistic Engine Hardening

Öncelik:

- solver interface
- trajectory result model
- units
- drag abstraction
- atmosphere abstraction
- integrator abstraction
- deterministic regression suite

Mevcut production gate korunacak.

---

## Phase 2 — G1/G7 ve Drag Validation

- reference drag data
- interpolation
- BC conversion
- G1/G7 solver
- convergence
- independent reference comparison

Validation geçmeden production'a açma.

---

## Phase 3 — Projectile + Platform + Profile

- ammunition/projectile models
- firearm/PCP models
- profile model
- persistence
- catalog relations

---

## Phase 4 — Atmosphere + Wind + 3D

- atmosphere
- density
- wind
- 3D state
- coordinate transformations
- regression vectors

---

## Phase 5 — Zero + Optics + Trajectory/DOPE

- sight geometry
- zero
- optic model
- trajectory table
- DOPE-style result presentation

---

## Phase 6 — Professional UI

- profile workflow
- ballistic calculator screen
- environment screen
- trajectory screen
- chart screen
- comparison screen
- catalog screens

---

## Phase 7 — Import / Export / Catalog

- JSON schema
- profile import/export
- trajectory CSV
- catalog provenance
- migrations

---

## Phase 8 — Performance + Production Hardening

- isolate/background calculation
- caching
- memory/performance profiling
- test coverage
- accessibility
- localization
- CI
- iOS build
- App Store preflight

---

# 25. CLAUDE CODE UYGULAMA PROTOKOLÜ

Her görevde şu sırayı izle:

1. Repository durumunu kontrol et.
2. İlgili mevcut dosyaları oku.
3. Mevcut davranışı ve testleri belirle.
4. Yeni değişikliğin hangi katmana ait olduğunu belirle.
5. Küçük ve geri alınabilir bir değişiklik yap.
6. Test ekle.
7. Formatla.
8. Repository'nin gerçek verification komutunu çalıştır.
9. Sonucu raporla.
10. Sonraki faza geçmeden önce mevcut gate'lerin korunduğunu kontrol et.

Claude tüm roadmap'i tek committe uygulamaya çalışmayacak.

---

# 26. KESİN OLARAK YAPILMAYACAKLAR

- Projeyi sıfırdan oluşturmak
- Mevcut solver'ı gereksiz yere silmek
- Validation gate'lerini kaldırmak
- Doğrulanmamış G1/G7 sonuçlarını production'a açmak
- Kaynağı belirsiz BC/drag verisi eklemek
- UI içine fizik hesabı gömmek
- Fizik motorunu Flutter widget'larına bağlamak
- Test toleranslarını başarısız sonucu geçirmek için gevşetmek
- Harici projenin UI/branding/assets kopyalamak
- Archery özellikleri eklemek
- Eğitim/lesson/lab özelliklerini ana ürün mimarisinin merkezine koymak
- Gerçek dünyadaki silah kullanımını optimize etmeye yönelik operasyonel yönlendirme eklemek

---

# 27. DEFINITION OF DONE

Bir özellik tamamlanmış sayılmaz; şu şartların tamamı sağlanmalıdır:

- Kod mevcut mimariye entegre
- Domain/UI ayrımı korunmuş
- Unit testleri mevcut
- Regression testleri mevcut
- Gerekliyse bağımsız referans karşılaştırması mevcut
- Veri provenance mevcut
- Production gate korunmuş
- Persistence schema uyumlu
- Import/export gerekiyorsa versioned
- UI validation mevcut
- Flutter verification çalıştırılmış
- Sonuçlar gerçek komut çıktılarıyla raporlanmış
- Dokümantasyon güncellenmiş

---

# 28. CLAUDE'A İLK TALİMAT

Bu dokümanı okuyunca bütün sistemi bir kerede geliştirmeye başlama.

İlk görev yalnızca mevcut repository üzerinde kapsamlı teknik audit yapmaktır.

Audit sonunda özellikle şu sorular cevaplanmalıdır:

1. Mevcut ballistic solver'ın gerçek sınırı nedir?
2. Hangi G1/G7 parçaları production, hangileri experimental?
3. Mevcut projectile/ammunition modelinin eksikleri nelerdir?
4. Firearm ve PCP modelleri nerede ayrılıyor?
5. Optic modeli ne kadar genişletilebilir?
6. Atmosphere ve wind modellerinin mevcut durumu nedir?
7. Zero/sight geometry nerede uygulanıyor?
8. Trajectory sonucu hangi model üzerinden UI'a gidiyor?
9. Persistence schema nasıl genişletilmeli?
10. Catalog provenance nerede tutuluyor?
11. py-ballisticcalc validation hattı nasıl geliştirilmeli?
12. Hangi dosyalar Phase 1'de değişecek?
13. Hangi testler yeni reference vectors gerektiriyor?
14. Hangi production gates şu anda kapalı?

Audit tamamlandıktan sonra yalnızca **Phase 1 — Ballistic Engine Hardening** için uygulanabilir, dosya bazlı bir plan çıkar.

Kod yazmadan önce mevcut sistemi bozmayacak en küçük değişiklik setini belirle.

Bu proje bir eğitim/lab uygulaması olarak değil, doğrulanabilir bir **balistik hesaplama ve simülasyon platformu** olarak geliştirilecektir.
