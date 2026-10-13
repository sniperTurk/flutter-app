# Hava Durumu başlıkları: Basınç Ölçer ve Rüzgâr

İstek (sahip, 2026-10-13 21:20, TestFlight ekran görüntüsü): "Basınç Ölçer, Rüzgâr boyutları profil sayfası (yeni) boyutlarında olsun. Basınç Ölçer Ö büyük olacak."

## Ne değişti

`lib/features/ballistics/ballistics_screen.dart`, Hava Durumu sayfası:

- Satır ~3292: `MenzilSectionHeader('Basınç ölçer', ...)` → `MenzilSectionHeader('Basınç Ölçer', size: 18, ...)`. Yazı "Basınç Ölçer" oldu (büyük Ö) ve başlık boyu 22'den 18'e indi.
- Satır ~3386: `MenzilSectionHeader('Rüzgâr', ...)` → `MenzilSectionHeader('Rüzgâr', size: 18, ...)`. Başlık boyu 22'den 18'e indi.
- Boşluklar (padding) aynı kaldı.
- `test/shot_settings_test.dart` içindeki bir yorum satırında eski yazı "Basınç Ölçer" olarak düzeltildi (yalnız yorum; test davranışı değişmedi). Eski yazıyı `find.text` ile arayan başka test yoktu.

## Neden

Profil özet sayfasındaki "Tüfek bilgileri / Dürbün bilgileri / Mühimmat bilgileri" başlıkları 18 boyunda (PR #266). Hava Durumu'ndaki iki başlık 22'de kaldığı için büyük görünüyordu. Şimdi ikisi de Profil başlıklarıyla aynı boyda.

## Bilerek değiştirilmeyenler

- Başka sayfaların başlıkları, alan adları ve Hava Durumu'nun en üstündeki kart (başlığı yok) değişmedi.
- `MenzilSectionHeader`'ın varsayılan boyu (22) değişmedi; yalnız bu iki başlığa `size: 18` verildi.
- Kullanım rehberindeki "Basınç ölçer: İstasyon basıncı ve İrtifa…" satırı (`tools/data_gen/generate_usage_guide.py`, `lib/features/guide/usage_guide_content.dart`, `docs/kullanim-rehberi/REHBER.md`) değiştirilmedi: başka bir sayfa ve istek yalnız bu iki başlık içindi. İstenirse ayrı bir küçük PR ile "Basınç Ölçer" yapılabilir.
- Aynı dosyaya dokunan açık PR'larla (fix/ruzgar-rehber, fix/yasla-sadece-hedef, feat/sistem-yazisi, fix/pro-alttan-sayfa) çakışmasın diye fark en küçük tutuldu (kod dosyasında 3 satır eklendi, 2 satır değişti). Dal, en güncel main ile (#276, #277, #280) birleştirildi; çakışma yalnız `test/wind_observation_test.dart` yorumundaydı, main'in hâli alındı.
- `integration_test/` içinde eski "Basınç ölçer" yazısını arayan bir yer yok (grep ile bakıldı).

## Hangi test kapsıyor

Yeni test: `test/hava_basliklar_test.dart`

- Profil özet sayfasını açar, "Tüfek bilgileri" başlığının yazı boyunu okur (18).
- Hava Durumu'nu açar; "Basınç Ölçer" ve "Rüzgâr" başlıklarının (MenzilSectionHeader içinde) yazı boyunun Profil başlığıyla aynı (18) olduğunu denetler.
- Eski "Basınç ölçer" yazısının sayfada olmadığını denetler.

## Doğrulama

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test OK.
- Bu ortamda Flutter SDK yok; `flutter test` / `flutter analyze` yerelde çalıştırılmadı. Bunlar GitHub Actions'ta çalıştırıldı:
  - Format (`format-fix.yml`): yeşil, değişiklik gerekmedi ("No formatting changes needed") — https://github.com/sniperTurk/flutter-app/actions/runs/38446934217
  - Testler (`test-diag.yml`, `files=test`, tüm test klasörü): yeşil — https://github.com/sniperTurk/flutter-app/actions/runs/38448460368
  - Analiz (`analyze-diag.yml`): yeşil — https://github.com/sniperTurk/flutter-app/actions/runs/38448463220
  - Önceki test koşusu (main birleştirmeden önce) 2 testte kırmızıydı: `test/pro_info_popup_test.dart` popup'ın iki yana yaslı olmasını bekliyordu; bu, #276'dan sonra main'de de kırmızıydı ve #280 ile main'de düzeltildi. Main dala birleştirilince yeşile döndü. Bu PR'ın değişikliğiyle ilgisi yoktu — https://github.com/sniperTurk/flutter-app/actions/runs/38447207758
- Not: Aynı anda başka oturumlar da bu iş akışlarını `ref: main` ile tetiklediği için koşular tetikleme zamanına göre eşleştirildi (format koşusunun günlüğünde `push origin HEAD:fix/hava-basliklar` görünüyor).
- iOS CI / Simulator / TestFlight bu iş kapsamında çalıştırılmadı; geçti denmiyor.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
