# Profil Oluştur: kutulara ölçü birimi

Sahibin isteği (2026-10-15 22:54, İstanbul): "Ölçü birimi girilecek kutuların içine: Tüfek bölümü — Sight height … mm, Sıfırlama mesafesi … m, Namlu çıkış hızı … fps; Mühimmat bölümü — Ağırlık … gr; Hıza göre BC kutularına da ölçü birimi gir."

## Ne yapıldı

| Kutu | Birim | Kodun okuduğu birim |
|---|---|---|
| Sight height | mm | `sightHeightMm` olarak saklanır |
| Sıfırlama mesafesi | Mesafe birimi Metre ise `m`, Yard ise `yd` | yazılan değer seçili birimden metreye çevrilir |
| Namlu çıkış hızı | fps | `UnitSystem.fpsToMps` ile m/s'ye çevrilir |
| Ağırlık (elle yazılan) | gr | grain olarak saklanır |
| 1. ve 2. eşik hızı | fps | `UnitSystem.fpsToMps` ile m/s'ye çevrilir |
| Eşik altı BC | birim yok | BC'nin birimi yok |

Değişiklik yalnız `unit:` satırları (3 dosya, 7 satır) ve yeni test dosyası.

## Nasıl

- `profile_editor_rifle.dart`: Sight height `unit: 'mm'`, Namlu çıkış hızı `unit: 'fps'`, Sıfırlama mesafesi `unit: distanceUnit.symbol`.
- `profile_editor_ammo.dart`: elle yazılan Ağırlık kutusu (`ammo-grain`) `unit: 'gr'`.
- `profile_editor_ammo_extra.dart`: `{n}. eşik hızı` `unit: 'fps'`.

## Neden

- Sıfırlama mesafesinde birim, kodun hesapta kullandığı `distanceUnit`'ten alınır. Mesafe birimi henüz "Seçiniz" iken kod değeri metre olarak okur (`distanceUnit` başlangıçta Metre). Bu yüzden o durumda `m` görünür. Kaydetmek için Mesafe birimi yine zorunlu.
- Yard seçilince kutudaki değer yarda çevrilir ve birim `yd` olur. Metre seçilince değer metreye döner, birim `m` olur.

## Önemli not: birimin yeri

Profil sayfasındaki kutular kompakt kutu değil. Bu kutularda `unit:` kutunun **içinde** görünmez; kutunun hemen üstünde, etiket satırının sağında görünür. Profil'deki eski birimler de (bar, °C, mm) böyle duruyor. Birimi kutunun içine almak ancak kutu türünü değiştirerek (`compact: true`, Hava Durumu gibi) ya da `MenzilInput`'u değiştirerek olur. Bu da görevin "yalnız `unit:` satırları" sınırının dışında kalıyor. Ayrıca `kutu_fikir4` regresyon testi Profil'de "birim kutunun içinde değil" diye kontrol ediyor. Bu yüzden bu PR'da birim etiket satırında. Kutunun içine alınması isteniyorsa sahibin kararı ve ayrı bir görev gerekiyor.

## Uç durumlar

- Yeni profil, Mesafe birimi "Seçiniz": `m` (kod metre okuyor).
- Kayıtlı yard profili açılınca: `yd`.
- Ateşli tüfekte listeden seçilen Ağırlık bir seçim listesi; birimi zaten her satırda ("168 gr (10,9 g)"). "Listede yok" ile açılan "Kutudaki ağırlık" kutusunda `gr = … g` birimi zaten vardı; değişmedi.
- Dar ekran (320 pt) ve yazı ölçeği 1.3: birim kutunun genişliği içinde kalıyor, taşma yok (testte denetleniyor).

## Bilerek yapılmayan

- Birimi kutunun içine taşımak (yukarıdaki not).
- Eşik altı BC ve BC kutularına birim eklenmedi.
- Hesap, kayıt biçimi ve kayıtlı veri değişmedi. Etiketlerde parantez yok.

## Testler

`test/profil_kutu_birimleri_test.dart`:
- Sight height `mm`, Sıfırlama mesafesi `m` (Mesafe birimi Seçiniz iken), Namlu çıkış hızı `fps`.
- Yard seçilince `yd`, Metre seçilince `m`.
- Elle yazılan Ağırlık `gr`; 1. ve 2. eşik hızı `fps`; Eşik altı BC birimsiz.
- 320 ve 390 pt, yazı ölçeği 1.0 ve 1.3, 4 haneli değerle: taşma yok, birim kutunun genişliği içinde.

Yerel:
- `python3 tools/offline_dart_lint.py`: PASS (388 dosya, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 842 test OK
- Bu ortamda Flutter SDK indirilemedi (ağ engelli). `flutter test` ve `flutter analyze` yerelde çalışmadı, CI'da çalıştırıldı.

## CI

- Format (format-fix): https://github.com/sniperTurk/flutter-app/actions/runs/38798320662 — başarılı, format commit'i dala eklendi.
- iOS CI, `b818387` (ilk hâli): verify başarılı https://github.com/sniperTurk/flutter-app/actions/runs/38798998250/job/116648976972 , dart-checks (format, `flutter analyze --fatal-infos --fatal-warnings`, tüm `flutter test`) başarılı https://github.com/sniperTurk/flutter-app/actions/runs/38798998250/job/116642802422 , wind-acceptance başarılı https://github.com/sniperTurk/flutter-app/actions/runs/38798998250/job/116642801719
- iOS CI, `662c23a` (main'e ilk rebase sonrası): verify başarılı https://github.com/sniperTurk/flutter-app/actions/runs/38805427569/job/116671731854 , dart-checks ve wind-acceptance başarılı https://github.com/sniperTurk/flutter-app/actions/runs/38805427569
- Main yeniden ilerlediği için dal bir kez daha main'e rebase edildi (bu commit). Son başın CI sonuçları PR açıklamasında.
- test-diag / analyze-diag: dispatch edildi, ancak aynı anda başka dallar da bu iş akışlarını çalıştırdığı ve günlükler bu ortamdan indirilemediği için hangi çalıştırmanın bu dala ait olduğu kesin doğrulanamadı. Bu yüzden onlar kanıt olarak sayılmadı; aynı denetimleri dart-checks yapıyor.
- Code Review ve Security review: bulgu yok.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
