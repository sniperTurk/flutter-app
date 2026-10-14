# Çalışma kuralları CLAUDE.md'ye yazıldı

Sahip onayı: 2026-10-14 08:54 (İstanbul), "Ok".

## Ne yapıldı
Yalnız `CLAUDE.md` değişti (bu rapor dosyası hariç). Uygulama kodu ve testler değişmedi.

1. **Yeni bölüm (dosyanın sonu):** `## Working preferences (owner, 2026-10-14)`. Sahibin verdiği 9 madde, sözcükleri değiştirilmeden eklendi: Türkçe ve kısa yanıt, İstanbul saati; "bekle" = dur, eylem için "başla/yap/görev aç/yükle"; istenmeyen hiçbir şeyi ekleme; ana oturum kod yazmaz, her kod değişikliği taslak PR + Türkçe rapor; kaldırılan özellik silinmez, `bool.fromEnvironment('FLAG')` ile gizlenir, kayıtlı veri korunur; ürün verisi yalnız üreticiden, başka balistik uygulamalardan veri yok, robots.txt'ye uy; hesabın kullanmadığı alan eklenmez; metin her yerde sola yaslı (yalnız Hedef iki yana), açılan liste kutudan geniş değil; yalnız gerçekten çalışan CI/Simulator/TestFlight/App Store "geçti" diye bildirilir.

2. **Kalibre cümlesi düzeltildi** (`## UI rule: select over typing, two boxes per row (owner, 2026-10-11)` bölümünde).

   Önce:
   > Keep two boxes per row (Marka | Model side by side); Kalibre and similar long single values take a full row.

   Sonra:
   > Keep two boxes per row (Marka | Model side by side); every row holds two boxes, Kalibre included (e.g. Namlu çıkış hızı | Kalibre share a row); a long selected value wraps or is shortened inside its box.

## Neden
- Yeni bölüm: sahibin kalıcı çalışma tercihleri her oturumda ve her Superpowers görevinde okunsun diye (task-observer kalıbı).
- Kalibre cümlesi: eski metin, sahibin sonraki kararıyla çelişiyordu (2026-10-13 19:32: "Namlu çıkış hızı Kalibre tek sütun olmasın. Her satır 2 kutu olsun"). Bu karar main'de `lib/features/profiles/profiles_screen.dart` içinde `_velocityCaliberRow()` olarak zaten var.

## Bilerek değiştirilmeyen
- CLAUDE.md'nin diğer bölümleri (doğrulama, bootstrap, lockfile, CI, Dart formatı, ⓘ kuralı) aynen kaldı.
- 2026-10-11 bölümünün geri kalanı (MenzilSelect, kütüphane dosyaları, "Listede yok", alan altında yardım metni yok, etiketlerde parantez yok) aynen kaldı; yalnız aynı paragrafın satır kırılımı yeniden düzenlendi.
- Uygulama kodu, testler, araçlar değişmedi.

## Yerel kontroller
- `python3 tools/offline_dart_lint.py` → `OFFLINE DART LINT PASS: 325 Dart files, 0 issues`
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test, OK
- CLAUDE.md'yi okuyan testler (`tools/test_claude_flutter_verify_wiring.py`, `tools/test_claude_bootstrap_and_verify_wiring.py`) → 8 test, OK. Aradıkları metinler (`tools/claude_flutter_verify.sh`, "Never report CI, Simulator, device, signing, TestFlight, or App Store upload as passed" vb.) hâlâ dosyada.
- `test/` altında CLAUDE.md okuyan test yok.
- Flutter CI çalıştırılmadı (yalnız belge değişikliği). PR'da otomatik CI çalışırsa sonucu PR'daki check'lerde görünür; burada "geçti" denmiyor.

Taslak PR; birleştirme ve TestFlight yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
