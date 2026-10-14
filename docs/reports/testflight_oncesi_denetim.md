# TestFlight öncesi denetim kuralı (CLAUDE.md)

**Tarih:** 2026-10-14 (İstanbul)
**Dal:** `docs/testflight-oncesi-denetim` (main'den, 6c36885)
**Tür:** Yalnızca belge. Uygulama kodu değişmedi.

## Ne eklendi
`CLAUDE.md` içindeki "## Working preferences (owner, 2026-10-14)" bölümünün sonuna iki madde eklendi:

1. Her TestFlight derlemesinden önce, bir önceki TestFlight'tan beri birleştirilen tüm değişiklikleri kapsayan uçtan uca hesap denetimi yapılır (kullanıcının girdiği değer → ekranda görünen sayı). Bağımsız kaynaklarla karşılaştırılır (asla başka bir balistik uygulama değil), gizli bayrak yolları ve değişikliklerin birbirine etkisi (boş alanlar, varsayılanlar, taşınan alanlar) kontrol edilir. Denetim yalnızca rapor verir; düzeltmeler ayrı görevlere gider. Yüksek önemde açık bulgu varken TestFlight başlatılmaz.
2. Denetim bulgularının `test/audit_*/` altındaki testleri gerileme koruması olarak test takımında kalır; düzeltilen bulgunun `skip:` testi açılır ve geçmek zorundadır.

Başka hiçbir bölüm değişmedi.

## Neden
2026-10-14 denetimi (#292), ayrı ayrı test edilmiş değişikliklerin birbirini etkilemesinden doğan sorunlar buldu (ör. #243 boş hava sayfası + 1013.25 varsayılan basınç; #284 dürbün tüpü basıncının Profil'e taşınması). Sahip 2026-10-14 10:42'de "ekle" dedi.

## Yerel kontroller
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 740 test, OK.
- `python3 tools/offline_dart_lint.py`: PASS, 329 Dart dosyası, 0 sorun.
- Araç testlerinden ikisi `CLAUDE.md` okuyor (`test_claude_flutter_verify_wiring.py`, `test_claude_bootstrap_and_verify_wiring.py`), ama yalnızca başka bölümlerdeki metinleri arıyor; ekleme bunları etkilemiyor, düzeltme gerekmedi.

## Yapılmayanlar
- Flutter analiz/test, iOS CI, Simulator, TestFlight çalıştırılmadı (belge değişikliği). CI sonucu PR üzerinde görülecek; burada geçti denmiyor.
- Birleştirme yapılmadı; taslak PR.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
