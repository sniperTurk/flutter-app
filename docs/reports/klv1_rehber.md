# KLV-1: Kullanım rehberinde eski düğme adı

Dal: `fix/klv1-rehber` · Taslak PR · Birleştirme yok, TestFlight yok.

## Ne yapıldı
Kullanım rehberi (Araçlar > Kullanım rehberi), Hedef ekranındaki düğmeyi hâlâ eski adıyla, "Çözümü kulelere kur" diye anlatıyordu. Düğmenin adı #317 ile "Kuleleri kur" oldu. Rehberdeki cümle artık "\"Kuleleri kur\"a dokun, sonra dürbündeki kuleleri aynı yönde aynı sayıda klik çevir." diyor.

## Nasıl
- `tools/data_gen/generate_usage_guide.py` içindeki metin düzeltildi.
- Üretici yeniden çalıştırıldı (`python3 tools/data_gen/generate_usage_guide.py`); iki çıktısı birlikte güncellendi:
  - `lib/features/guide/usage_guide_content.dart` (uygulamadaki rehber)
  - `docs/kullanim-rehberi/REHBER.md` (aynı rehberin metin hâli; `tools/test_usage_guide_sync.py` ikisini karşılaştırır)

## Neden
Sahibin kararı, 2026-10-15 20:03 İstanbul: "her iş için ayrı görev". KLV-1 (düşük önem) ayrı görev olarak düzeltildi.

## Repo taraması
`grep -rn "kulelere kur" lib tools` sonucu:
- Rehber metni (düzeltildi).
- `lib/features/ballistics/scope_turrets.dart:55` ve `lib/ui/menzil_widgets.dart:2388` (yorum): "Çözüm kulelere kuruldu". Bu eski düğme adı değil; düğmeye basıldıktan sonra görünen "kuruldu" durum yazısı. Bu yüzden değiştirilmedi.
- Eski raporlara (`docs/reports/` vb.) dokunulmadı.

## Uç durumlar
- Rehber metni ile REHBER.md aynı kalmalı; ikisi üreticiden birlikte üretildi, eşitlik testi geçiyor.
- Rehberdeki diğer düğme adları ("Kule sınırına kuruldu", "Kuleleri sıfırla") düğmedeki yazılarla zaten aynı.

## Bilerek yapılmayan
- "Çözüm kulelere kuruldu" durum yazısı değiştirilmedi (görev kapsamı dışında).
- Başka metin, düzen veya hesap değişikliği yok.

## Testler
- Yeni: `test/audit_2026_10_15/klv1_usage_guide_test.dart`
  - rehber "Çözümü kulelere kur" içermez;
  - rehber "\"Kuleleri kur\"" içerir;
  - Hedef düğmesinin kaynağında `'Kuleleri kur'` yazısı hâlâ var;
  - REHBER.md de aynı: eski adı içermez, yeni adı içerir.
- Yerel:
  - `python3 tools/offline_dart_lint.py`: GEÇTİ (380 Dart dosyası, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: GEÇTİ (842 test).
  - Bu ortamda Flutter SDK yok; `flutter test` yerelde çalıştırılmadı (CI'da çalışır).

## CI
- Format (One-off dart format fix): [run 38774681224](https://github.com/sniperTurk/flutter-app/actions/runs/38774681224) — başarılı, değişiklik gerekmedi.
- Test tanılama (test-diag, files=test): [run 38774687516](https://github.com/sniperTurk/flutter-app/actions/runs/38774687516) — başarılı.
- iOS CI, `3e13ef0` (kod + rapor taslağı) üzerinde: [run 38774927929](https://github.com/sniperTurk/flutter-app/actions/runs/38774927929)
  - `verify`: başarılı
  - `dart-checks`: başarılı
  - `wind-acceptance`: başarılı
  - `ios-simulator`: atlandı (bu iş akışında çalışmadı; geçti sayılmaz)
- Bu satırları ekleyen son commit yalnız bu rapor dosyasını değiştirir; onun CI sonucu PR sayfasındaki check'lerdedir.
- Simulator, cihaz, TestFlight, App Store: çalıştırılmadı.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
