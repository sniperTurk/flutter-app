# V381 — balistik ve dürbün denetimi

Kaynak: `main` @ `1509aa4`. Solver, drag tabloları ve kapılar değişmedi.
Ayrıntılı bulgular: `AUDIT_2026-10-08.md` (geçici; uygulama bitince silinecek).

- Rüzgâr kartı sapma yönünü ve kule yönünü yazar:
  "Sapma 4,2 cm sağa · 3 klik L (sola)".
- Dürbün görünümüne nişan noktasında Ø10 cm halka hedef, gerçek açısal
  boyutunda: büyütme artınca büyür, mesafe artınca küçülür (FFP ve SFP).
  `ScopeDialMath.angleAtRange` eklendi.
- Atış/Hava Durumu'nda namlu çıkış hızı her birim sisteminde fps.
- Hava Durumu ve mesafe alanlarına ⓘ açıklamaları
  (`environment_field_info.dart`); rüzgâr yönü ve irtifa yardım metinleri
  netleştirildi; "Dürbün eksen yüksekliği" → "Sight height".
- Test: `test/ballistic_audit_test.dart`.
