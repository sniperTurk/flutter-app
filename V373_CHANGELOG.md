# V373 — uygulama Profil sekmesinde açılır; Profil en solda

Kaynak: `main` @ `b48e522`. Solver, katalog, `validation/*` ve üretim kapısı
değişmedi.

## Üretim kodu
- `lib/features/home/home_screen.dart`: alt sekme sırası Profil, Atış, Tablo,
  Ortam, Araçlar; başlangıç sekmesi Profil. Atış/Tablo/Ortam aynı çalışma
  alanını paylaşmaya devam eder (IndexedStack: 0 Profil, 1 çalışma alanı,
  2 Araçlar). Profil yokken "Profil oluştur"/"Profile git" yine Profil'e götürür.

## Testler
- Kabuk testleri yeni sırayı ve Profil'in en solda olduğunu doğrular; Atış'a
  bağlı testler önce Atış sekmesine geçer. Başlangıçta görünmeyen (offstage)
  çalışma alanını okuyan kontroller `skipOffstage: false` kullanır.
- `integration_test/app_launch_test.dart`: yeni sekme sırası.

## ÇALIŞTIRILMADI / DOĞRULANMADI
- Bu sandbox'ta Flutter yok; sonuç PR'ın iOS CI koşusundadır.

## Ek (PR #11): dört sekme, Hava Durumu öne
- Alt menü: Profil · Hava Durumu · Atış · Araçlar. "Ortam" sekmesinin adı
  "Hava Durumu" oldu ve Profil'in hemen yanına alındı (atıştan önce koşullar).
- Tablo artık ayrı sekme değil: Atış sekmesinin üstünde "Tek atış | Tablo"
  geçişi var (seçim sekmeler arasında korunur). Her yarı 44 pt dokunma alanı.
- Hava Durumu sekmesinde "Konumdan canlı hava verisi" düğmesi Araçlar'daki
  Hava & Rüzgâr ekranını doğrudan açar. Servis verisi girdilere otomatik
  kopyalanmaz (önceki politika korunur).
- Ayarlar ve boş-sonuç metinlerindeki "Ortam" ifadeleri güncellendi.
