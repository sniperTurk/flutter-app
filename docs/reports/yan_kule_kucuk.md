# Yan kule küçük (Hedef)

Sahibin kararı (2026-10-15 12:52): "sağ kuleyi biraz küçültsek oklar yine aynı yerinde kalsa". 12:53: kırmızı işaret kutunun içinde olsun. Referans: `design/clean-2026-10-15` dalı, README "Ek kararlar" ve Hedef.png (dal birleştirilmedi).

## Ne yapıldı
- Hedef sayfasındaki yan (rüzgâr) kule kutusu 74 × 224 pt'den **66 × 180 pt**'ye küçüldü (390 pt telefonda, 334 pt retikülde). Retikül büyüyüp küçüldükçe kutu da eskisi gibi orantılı büyüyüp küçülür.
- **Oklar yerinde kaldı.** ↑ ve ↓ okların merkezi, dokunma alanı (74 × 30 pt) ve oktan oka toplam boy (296 pt) main ile aynı. Kutu iki okun arasında ortalandı: oklarla kutu arası 6 pt'den 28 pt'ye çıktı, kutu sağ kenardan 4 pt içeride.
- Kutunun ortası (sıfır) retikülün yatay çizgisinde kaldı.
- **Kırmızı işaret kutunun içinde.** Önceden kutunun kenarına (sol kenar, 1 pt çerçevenin üstü) yapışıktı. Şimdi kenardan 5 pt içeride, ucu sıfır çizgisini gösteriyor. Boyutu aynı (11 × 14 pt).

## Nasıl
- Yalnız `lib/features/ballistics/scope_turrets.dart` değişti. Kule sütunu 74 pt genişlikte kaldı (oklar bu genişlikte); kutu bu sütunun içinde 66 pt genişlikte ortalanıyor; kutu ile ok arası boşluk 28 pt.
- İşaretin yeri tek bir yerde tanımlı: `SideTurretPointer.rect(...)`. Çizim de testler de bunu kullanıyor.

## Neden
Sahip, yan kulenin biraz küçülmesini ama okların yerinin değişmemesini istedi; işaretin kenara değmemesini istedi.

## Uç durumlar
- 320 pt dar ekran ve yazı ölçeği 1.3: taşma yok; kutu retikülle orantılı küçülüyor; "2R", "0", "2L", "↑R", "L↓" yazıları kutuya sığıyor; "0" yazısı işarete değmiyor. Kule içindeki yazılar sistem yazı ölçeğiyle büyümüyor (önceden de böyleydi).
- Kule kapalıyken ("L-R") hiçbir şey değişmiyor; açılış/kapanış kayması aynı.
- Davranış değişmedi: oklar, sürükleme, VoiceOver adımları, "Kuleleri kur / sıfırla" aynı.

## Bilerek yapılmayan
- Görev metni işaretin "sağ kenara" değdiğini söylüyordu; kodda işaret kutunun **sol** kenarındaydı (çizgiler de solda). İşaretin tarafı değiştirilmedi (davranış/tasarım değişmesin diye); yalnız kenardan içeri alındı. Referans tasarımdaki gibi sağa taşınması istenirse ayrı görev olmalı.
- Kutunun içi (yazı yerleşimi, "MOA" satırı vb.) referans tasarıma göre yeniden düzenlenmedi; görev yalnız boyut ve işaretti.
- Üst kule, retikül ve diğer sayfalara dokunulmadı. Birleştirme, TestFlight yok.

## Testler
- `test/yan_kule_oklar_test.dart` (yeni): okların merkezi, dokunma alanı (74 × 30 pt) ve toplam boyu (296 pt) main ölçüsüyle karşılaştırır; 390×844, 390×2400, 430, 320 pt (×1.3). **Önce/sonra ölçüm:** bu dosya önce kod değişmeden (yalnız test, commit d5ca7d9) CI'da çalıştırıldı ve geçti; aynı dosya değişiklikten sonra da geçiyor.
- `test/yan_kule_kucuk_test.dart` (yeni): 390 pt'de kutu 66 × 180 pt (±1); her boyutta kutu retikülle orantılı (±0,5); sıfır yatay çizgide (±0,5); kutu okların arasında ortalı; işaret kutunun içinde, her kenardan en az 3 pt; çizimdeki kırmızı yol işaretin yerinde; 320 pt ve ×1.3'te taşma yok, yazılar sığıyor.
- `test/temiz_tasarim_hedef_test.dart`: eski 74 × 224 beklentisi yeni karara göre 66 × 180 yapıldı; kutunun sağ kenarı artık retikül kenarından 4 pt içeride.
- Yerel: `python3 tools/offline_dart_lint.py` geçti (381 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (842 test). Bu ortamda Flutter SDK motoru indirilemedi (ağ engeli), `flutter test` yerelde çalışmadı; testler CI'da çalıştı.

## CI
- Önce ölçümü (yalnız ok testi, kod değişmeden): https://github.com/sniperTurk/flutter-app/actions/runs/38774832260 — başarılı.
- Format (dart format, CI commit'i dala eklendi): https://github.com/sniperTurk/flutter-app/actions/runs/38775390677 — başarılı.
- Tüm testler (`test`): https://github.com/sniperTurk/flutter-app/actions/runs/38775747474 — başarılı.
- Analyze: https://github.com/sniperTurk/flutter-app/actions/runs/38775750984 — **başarısız** (yeni iki testte `prefer_const_constructors` bilgi uyarısı); düzeltildi, yeniden çalıştırma sonucu PR açıklamasında.
- PR kontrolleri (`verify`, `dart-checks`, `wind-acceptance`): PR açıklamasında güncellenir.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
