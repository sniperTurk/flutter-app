# KUL-1 düzeltmesi: sıfır açısı kulenin yarım yolundan büyükken kule yolu

Sahip kararı: 2026-10-15 20:47 (İstanbul), "düzeltmek için görev aç".
Bulgu: `docs/reports/denetim_testflight_2026_10_14b.md`, KUL-1 (orta).

## Ne

Hedef sayfasındaki kule simülasyonunda, sıfır açısı kulenin yarım yolundan
büyük olduğunda:

- Aşağı yol kulenin tamamından uzun çıkıyordu (ör. 72 kliklik kulede yukarı 0,
  aşağı 77).
- "Sıfırlanamaz" uyarısı yoktu.
- Ayak önerisi yaklaşık 5 klik küçük çıkıyordu.

Şimdi:

- Aşağı yol en çok kulenin tamamı (2 × yarım yol). Yukarı + aşağı hiçbir zaman
  kulenin tamamını geçmez.
- Sıfır açısı − ayak > yarım yol olduğunda ayrı bir kırmızı not çıkıyor:
  "Bu dürbünle tüfek sıfırlanamaz: sıfır için kuleyi yaklaşık N klik yukarı
  çevirmek gerekir, kulenin yukarı yolu H klik. …"
- "Kule yetmez" mesajındaki ayak önerisi kırpılmamış yukarı yoldan
  (yarım + ayak − sıfır açısı, eksi olabilir) hesaplanıyor.
- Hedef'teki gereken klik sayısı değişmedi.

## Nasıl

- `lib/features/ballistics/ballistics_screen.dart`: `downClicks` artık
  `max(0, min(yarım − ayak + sıfır, 2·yarım))`. `upClicks` aynı kaldı.
- `lib/features/ballistics/scope_dial_view.dart`:
  - Yeni `zeroAngleBlocksZero` (yol biliniyor ve `sıfır − ayak > yarım`).
  - Yeni not, anahtarı `ScopeDialKeys.zeroAngleNote`. Var olan
    `mountBlocksZero` notu (ayak çok büyük) aynen duruyor.
  - `_travelMessage`: eksik klik `gereken − (yarım + ayak − sıfır)` ile
    hesaplanıyor; eskiden ekranda gösterilen (0'a kırpılmış) yukarı yol
    kullanılıyordu.
- `scope_turrets.dart` değişmedi.

## Neden

Kule fiziksel olarak 2 × yarım yoldan fazla dönemez. Sıfır açısı yarım yoldan
büyükse dürbün o tüfekte sıfırlanamaz; bunu kullanıcıya açıkça söylemek
gerekir. Ayak önerisi, kulenin gerçekte kaç klik eksik kaldığını (yukarı yol
eksi değer) hesaba katmazsa yetmeyen bir ayak önerir.

## Uç durumlar

- Normal durum (sıfır yarım yolun içinde, ayak yok veya uygun ayak): yukarı +
  aşağı = kulenin tamamı, not yok, sayılar eskisiyle aynı.
- Ayak çok büyük (ayak − sıfır > yarım): eski `mountBlocksZero` notu, yeni not
  çıkmaz. İkisi aynı anda çıkamaz.
- Kule yolu bilinmiyorsa (katalogda yok): hiçbir not çıkmaz, sınır uydurulmaz
  (eskisi gibi).
- Ayak kırpılmamış değerle hesaplandığı için önerilen ayak "sıfırlanabilen en
  büyük ayak" sınırını aşarsa "Hiçbir dürbün ayağı yetmez" mesajı çıkar
  (eskisi gibi).
- "Kuleleri kur" (otomatik çevirme) kırpılmış sınırlar içinde kalır.

## Bilerek yapılmayan

- Sıfırlanamaz durumda "Kule yetmez" mesajı gizlenmedi: yukarı yol gerçekten
  0 olduğu için doğru; artık doğru ayak önerisini veriyor.
- `scope_turrets.dart` düzeni (başka görev).
- Gereken klik hesabı değiştirilmedi.

## Testler

- `test/audit_2026_10_14b/turret_zero_cleanup_audit_test.dart`:
  - KUL-1 testi (`… up + down never exceed the whole travel`) `skip:`
    kaldırıldı.
  - Tekrar vakası (Hatsan Hercules 635, 270 m/s, sıfır 25 m, 60 mm; Steiner
    Ranger 4 4-16x56, 7,2 mrad, 0,1 klik): yukarı 0, aşağı 72, sıfırlanamaz
    notu (41 klik / 36 klik), ayak notu yok; ayak önerisi elle hesapla
    (gereken − 36 + 41 klik, 1 mrad = 10,8/π MOA) eşleşiyor.
  - Normal vaka 1: aynı tüfek + Ranger 4, 20 MOA ayak (58 klik): yukarı 53,
    aşağı 19, not yok.
  - Normal vaka 2: Gazi 6-36: not yok, yukarı + aşağı = kulenin tamamı.
  - Gereken klik kule sınırından bağımsız (Ranger 4 ve Gazi'de aynı açı).
- `tools/test_v372_interactive_scope_dial.py`: eski kırpılmamış aşağı yol
  formülünü arayan kaynak kontrolü yeni (kırpılmış) formüle güncellendi; test
  zayıflatılmadı, daha sıkı.
- Yerel: `python3 tools/offline_dart_lint.py` PASS (379 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` OK (842 test).
- Flutter SDK bu ortama kurulamadı (Google arşivi 403); Dart testleri yalnız
  CI'da çalıştı.

## CI

Rebase öncesi baş commit `c05439df` (kod + CI'nın format commit'i), hepsi
gerçekten çalıştı ve yeşil:

- Format düzeltme (format-fix): başarılı, test dosyasına format commit'i itti
  (`c05439df`).
- iOS CI, `c05439df` üzerinde (run 38782473646):
  - `verify`: success —
    https://github.com/sniperTurk/flutter-app/actions/runs/38782473646/job/116591527568
  - `dart-checks`: success —
    https://github.com/sniperTurk/flutter-app/actions/runs/38782473646/job/116585944327
  - `wind-acceptance`: success —
    https://github.com/sniperTurk/flutter-app/actions/runs/38782473646/job/116585943626
- test-diag (files=test): success — https://github.com/sniperTurk/flutter-app/actions/runs/38782145074
- analyze-diag: success — https://github.com/sniperTurk/flutter-app/actions/runs/38782148941

Not: ilk commit `c38af370` üzerindeki `dart-checks` format yüzünden düştü;
format commit'inden sonra yeşil. Sonra dal main'e (`44285f13`) rebase edildi;
rebase sonrası baş commit'in sonuçları PR'daki check'lerde görünür.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
