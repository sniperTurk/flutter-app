# V374 — Profil sayfası düzenlemeleri (başlangıç ekranı)

Kaynak: `main` @ `232ee4f`. Solver, katalog, `validation/*`, üretim kapısı ve
kayıtlı profil biçimi değişmedi.

## Üretim kodu (`lib/features/profiles/profiles_screen.dart`, `home_screen.dart`)
- Aktif profil özeti artık sayfanın en üstünde; profil listesi altında.
- Özetin altında "Hava Durumu'na geç" düğmesi (yalnız kabukta) — akış:
  Profil → Hava Durumu → Atış.
- Liste satırında "Zero" yerine "Sıfır".
- Liste satırı ve özet, Ayarlar'daki birim sistemine uyar (emperyal: fps, yd).
  Profil SI olarak saklanmaya devam eder; yalnız gösterim çevrilir.
- Eskimiş not ("V1 vakum temel hesapta BC kullanılmaz") düzeltildi: BC ve
  G1/G7 modeli varsa Atış sürüklenme çözücüsünü kullanır (PR #5), yoksa vakum
  temel hesap çalışır.

## Testler
- Yeni: `test/profile_page_test.dart` (birimler, Türkçe etiket, sıra, not,
  devam düğmesi, kabukta Hava Durumu'na geçiş).
