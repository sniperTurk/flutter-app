# Hava Durumu başlıkları: Basınç Ölçer ve Rüzgâr

İstek (sahip, 2026-10-13 21:20, TestFlight ekran görüntüsü): "Basınç Ölçer, Rüzgâr boyutları profil sayfası (yeni) boyutlarında olsun. Basınç Ölçer Ö büyük olacak."

## Ne değişti

`lib/features/ballistics/ballistics_screen.dart`, Hava Durumu sayfası:

- Satır ~3292: `MenzilSectionHeader('Basınç ölçer', ...)` → `MenzilSectionHeader('Basınç Ölçer', size: 18, ...)`. Yazı "Basınç Ölçer" oldu (büyük Ö) ve başlık boyu 22'den 18'e indi.
- Satır ~3386: `MenzilSectionHeader('Rüzgâr', ...)` → `MenzilSectionHeader('Rüzgâr', size: 18, ...)`. Başlık boyu 22'den 18'e indi.
- Boşluklar (padding) aynı kaldı.
- `test/shot_settings_test.dart` ve `test/wind_observation_test.dart` içindeki iki yorum satırında eski yazı "Basınç Ölçer" olarak düzeltildi (yalnız yorum; test davranışı değişmedi).

## Neden

Profil özet sayfasındaki "Tüfek bilgileri / Dürbün bilgileri / Mühimmat bilgileri" başlıkları 18 boyunda (PR #266). Hava Durumu'ndaki iki başlık 22'de kaldığı için büyük görünüyordu. Şimdi ikisi de Profil başlıklarıyla aynı boyda.

## Bilerek değiştirilmeyenler

- Başka sayfaların başlıkları, alan adları ve Hava Durumu'nun en üstündeki kart (başlığı yok) değişmedi.
- `MenzilSectionHeader`'ın varsayılan boyu (22) değişmedi; yalnız bu iki başlığa `size: 18` verildi.
- Kullanım rehberindeki "Basınç ölçer: İstasyon basıncı ve İrtifa…" satırı (`tools/data_gen/generate_usage_guide.py`, `lib/features/guide/usage_guide_content.dart`, `docs/kullanim-rehberi/REHBER.md`) değiştirilmedi: başka bir sayfa ve istek yalnız bu iki başlık içindi. İstenirse ayrı bir küçük PR ile "Basınç Ölçer" yapılabilir.
- Aynı dosyaya dokunan açık PR'larla (fix/ruzgar-rehber, fix/yasla-sadece-hedef, feat/sistem-yazisi, fix/pro-alttan-sayfa) çakışmasın diye fark en küçük tutuldu (kod dosyasında 3 satır eklendi, 2 satır değişti).
- `integration_test/` içinde eski "Basınç ölçer" yazısını arayan bir yer yok (grep ile bakıldı).

## Hangi test kapsıyor

Yeni test: `test/hava_basliklar_test.dart`

- Profil özet sayfasını açar, "Tüfek bilgileri" başlığının yazı boyunu okur (18).
- Hava Durumu'nu açar; "Basınç Ölçer" ve "Rüzgâr" başlıklarının (MenzilSectionHeader içinde) yazı boyunun Profil başlığıyla aynı (18) olduğunu denetler.
- Eski "Basınç ölçer" yazısının sayfada olmadığını denetler.

## Doğrulama

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test OK.
- Bu ortamda Flutter SDK yok; `flutter test` / `flutter analyze` yerelde çalıştırılmadı. Bunlar GitHub Actions'ta çalıştırıldı:
CI_LINKS_PLACEHOLDER

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
