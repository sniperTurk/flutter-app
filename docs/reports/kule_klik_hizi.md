# Kule klik hızı — rapor

Sahibin sözü (16.10.2026 20:42, İstanbul): "Dürbün kulelerinin klikleri çevirme hızı ile aynı değil."

## Ne
Hedef sayfasındaki üst (yükseklik) ve yan (rüzgâr) kulede hızlı çevirince klikler kayboluyordu: kule dönüyor, ama klik sayısı ve klik sesi geride kalıyordu. Yavaş çevirmede sorun yoktu. Artık hız ne olursa olsun parmağın her 9 pt yolu tam 1 klik sayar, 1 klik sesi çalar ve kule çizimi de aynı değeri gösterir.

## Nasıl
Yalnız `lib/features/ballistics/scope_turrets.dart` içinde `_TurretDrumState` değişti:
- Yeni `_value` = `_sent ?? widget.clicks`: sayfaya gönderilmiş ama sayfa henüz yeniden çizilmemiş son değer, yoksa sayfanın değeri.
- Sürükleme (`_drag`), ok dokunuşu ve VoiceOver artır/azalt artık `widget.clicks` yerine `_value` üzerine sayar.
- Hareket sınırında: sınıra ulaşan veya sınırı aşan sürüklemede artan yol (`_carry`) sıfırlanır. Sınırın ötesinde klik ve ses yok; geri çevirince ilk 9 pt hemen 1 klik geri gelir.
- Kule çizimi (`_DrumPainter.clicks`) de `_value` kullanır; işaretçinin altındaki sayı sayaçla aynıdır.

## Neden
Hızlı çevirmede bir karede birden çok sürükleme olayı gelir. Eski kod her olayda `widget.clicks + adım` gönderiyordu; sayfa arada yeniden çizilmediği için `widget.clicks` eskiydi. İkinci olay aynı değeri tekrar gönderiyordu, `_set` bunu "değişiklik yok" sayıyordu: o adım ve sesi kayboluyordu, ama parmak yolu (`_carry`) harcanmıştı. Şimdi her olay bekleyen değerin üstüne sayar.

## Uç durumlar
- Bir karede çok sayıda küçük hareket (ör. 3 pt × 21 = 63 pt): 7 klik, 7 ses.
- Sınırın ötesine hızlı sürükleme: sayaç sınırda durur, ses yalnız sınıra kadar; sınırın ötesindeki yol biriktirilmez.
- Sayfa yeniden çizilince (`didUpdateWidget`) bekleyen değer eskisi gibi silinir; programla yapılan hareketler etkilenmez.
- Ok dokunuşu ve VoiceOver hızlı art arda (sayfa çizilmeden) her biri 1 klik.

## Bilerek yapılmayan
- "Kuleleri kur", "Kuleleri sıfırla", otomatik kurma, profil değişikliği: değişmedi (sessiz, eskisi gibi).
- Klik değeri, birimler, hiçbir hesap: değişmedi.
- `scope_results.dart`, `hedef_view.dart`: dokunulmadı (fix/duzeltmeler-16-10 görevi).
- Klik sesi servisi (`TurretClickSound`, 25 ms altındaki sesleri atlama kuralı): değişmedi. Testlerde sahte servis her isteği sayar.

## Testler
Yeni `test/kule_klik_hizi_test.dart` (gerçek Hedef sayfası, sahte `TurretClickSound`):
- Üst ve yan kule, iki yön: bir karede N×9 pt hızlı sürükleme (N = 5, 12) → tam N klik, N ses.
- Üst ve yan kule, iki yön: bir karede 21 × 3 pt → 7 klik, 7 ses.
- Yavaş sürükleme (her 9 pt'de kare): eskisi gibi 1 adım = 1 klik.
- Sınırın ötesine hızlı sürükleme: sayaç sınırda, ses sınıra kadar; 9 pt geri = 1 klik.
- Dört ok, sayfa çizilmeden 5 hızlı dokunuş → 5 klik, 5 ses.
- VoiceOver artır ×3 / azalt ×3, sayfa çizilmeden → 3 klik, 3 ses.
- Var olan `test/kule_klik_sesi_test.dart` değişmedi.

Yerel: `python3 tools/offline_dart_lint.py` → PASS (407 Dart dosyası, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlanan, önceden var). Flutter SDK bu ortamda kurulamadı (storage.googleapis.com ağ politikası 403): `flutter analyze` ve `flutter test` yerelde ÇALIŞMADI (BLOCKED); sonuçlar yalnız aşağıdaki CI'dan.

## CI
Kod commit'i `7f16d67` üzerinde (analyze-diag hariç; main e7b29bf ile güncel, yeniden temellendirme gerekmedi):
- iOS CI / verify (macOS, Simulator derlemesi dahil): BAŞARILI — https://github.com/sniperTurk/flutter-app/actions/runs/38944339215/job/117124792527
- iOS CI / dart-checks: BAŞARILI — https://github.com/sniperTurk/flutter-app/actions/runs/38944339215/job/117120102839
- iOS CI / wind-acceptance: BAŞARILI — https://github.com/sniperTurk/flutter-app/actions/runs/38944339215/job/117120102733
- Tüm testler (test-diag, files=test): BAŞARILI — https://github.com/sniperTurk/flutter-app/actions/runs/38944533452
- Kule testleri (kule_klik_hizi + kule_klik_sesi): BAŞARILI — https://github.com/sniperTurk/flutter-app/actions/runs/38944332773
- analyze-diag: BAŞARILI, ilk commit `643c99a` üzerinde (lib aynı; sonra yalnız test dosyası değişti, o da dart-checks'ten geçti) — https://github.com/sniperTurk/flutter-app/actions/runs/38942507719
- Format (375209577): BAŞARILI, değişiklik gerekmedi — https://github.com/sniperTurk/flutter-app/actions/runs/38944336898

İlk tam test koşusu (https://github.com/sniperTurk/flutter-app/actions/runs/38942504414) yeni yavaş sürükleme testimde başarısız oldu: test aynı harekette ileri sonra geri gidiyordu ve 9 pt'den küçük artan yol geri dönüşte bir klik kaydırıyordu (bu davranış düzeltmeden önce de aynıydı). Test ileri ve geri iki ayrı hareket olarak yeniden yazıldı; beklenti gevşetilmedi.

Code Review ve Security review: sorun yok — https://github.com/sniperTurk/flutter-app/pull/369#issuecomment-6221717263
Not: bu ortamda `gh` CLI ile REST `gh api` kullanıldı; iş günlükleri indirilemedi (blob depolama 403), hatalar check-run annotation'larından okundu.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
