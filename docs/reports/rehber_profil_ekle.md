# Kullanım rehberi: "Yeni profil" yerine "Profil ekle"

## Ne
Kullanım rehberinin "İlk profil" bölümündeki 1. madde, uygulamanın bugünkü haline uyduruldu.

- Eski: `1. Profil sayfasında "Profil oluştur"a dokun. Sonraki profiller için "Yeni profil" kullanılır.`
- Yeni: `1. Profil sayfasında "Profil oluştur"a dokun. Sonraki profiller için Profiller listesinin başındaki "Profil ekle" kullanılır.`

## Nasıl
Metin tek kaynaktan üretiliyor: `tools/data_gen/generate_usage_guide.py`. Cümle orada değiştirildi, betik çalıştırıldı; `lib/features/guide/usage_guide_content.dart` ve `docs/kullanim-rehberi/REHBER.md` aynı satırla güncellendi. Üç dosya senkron.

## Neden
Onaylı tasarımda (docs/design/clean-2026-10-15/README.md "Ek kararlar") üst çubuktaki "Yeni Profil" düğmesi kaldırıldı (PR #331), yerine Profil sayfasındaki Profiller listesinin başlığına "Profil ekle" kondu (PR #329). Düğme adları koddan kontrol edildi: ilk profil için karşılama sayfasında "Profil oluştur" (`lib/features/home/empty_states.dart`), sonrakiler için "Profil ekle" (`lib/features/profiles/profiles_screen.dart`).

## Uç durumlar
- Rehberde kaldırılan "Koyu"/tema düğmesinden söz eden başka cümle yok (aranıp bulunmadı); bu yüzden başka metin değişmedi.
- Rehber dışındaki yerler (ör. boş liste kartındaki "Yeni profil ile ilk profilinizi oluşturun." yazısı, tek başına açılan Profiller ekranındaki "Yeni profil" ipuçlu artı düğmesi) bu görevin kapsamında değil; dokunulmadı.

## Bilerek yapılmayan
Başka metin, kod ya da ekran değişikliği yok. Birleştirme ve TestFlight yok.

## Testler
- `test/usage_guide_test.dart`: yeni test — rehberde "Yeni profil", "Koyu" ve "tema" geçmiyor; "İlk profil"in 1. maddesi "Profil oluştur" ve "Profil ekle"yi anıyor.
- `tools/test_usage_guide_sync.py`: yeni test — Dart metninde ve REHBER.md'de "yeni profil" yok, "Profil ekle" var.
- Eski metni bekleyen bir test yoktu.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (387 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 843 test OK. Bu ortamda Flutter SDK yok; Dart testleri yalnız CI'da koşar.

## CI
Commit `0771d03` üzerinde (gerçekten çalıştı, sonuçlar check-run'lardan okundu):
- iOS CI / `verify`: success — https://github.com/sniperTurk/flutter-app/actions/runs/38794233410/job/116631525068
- iOS CI / `dart-checks`: success — https://github.com/sniperTurk/flutter-app/actions/runs/38794233410/job/116626320960
- iOS CI / `wind-acceptance`: success — https://github.com/sniperTurk/flutter-app/actions/runs/38794233410/job/116626321261
- iOS CI / `ios-simulator`: skipped (iş akışı bu PR'da çalıştırmadı; Simulator derlemesi geçti denemez)
- One-off dart format fix: success, format değişikliği gerekmedi (dal başı değişmedi) — https://github.com/sniperTurk/flutter-app/actions/runs/38794204276
- One-off test diagnostic (`files=test`): success — https://github.com/sniperTurk/flutter-app/actions/runs/38794207058

TestFlight, App Store ve cihaz testi çalıştırılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
