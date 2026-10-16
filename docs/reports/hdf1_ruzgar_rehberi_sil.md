# HDF-1: Rüzgâr rehberi bağlantısı silindi

Dal: `fix/hdf1-ruzgar-rehberi-sil` (main'den, #335 birleştikten sonra). Taslak PR; birleştirme ve TestFlight yok.

## Ne
- Hava Durumu sayfasında artık kullanılmayan "Rüzgâr tahmini nasıl yapılır?" bağlantısı koddan silindi.
- `WIND_GUIDE_LINK` bayrağı silindi. Bu bağlantıyı geri açmanın bir yolu artık yok.
- Rüzgâr başlığındaki ⓘ aynen duruyor: dokununca "Rüzgârı gözle tahmin et" penceresi, 6 satır ve Kapat düğmesi açılır. Metin değişmedi.

## Nasıl
- `lib/features/ballistics/ballistics_screen.dart`: `_showWindGuideLink` (`bool.fromEnvironment('WIND_GUIDE_LINK')`) silindi. `WIND_OBSERVATION` açıklamasındaki "kartın altındaki bağlantı" sözü "Rüzgâr ⓘ" olarak düzeltildi (yalnız yorum).
- `lib/features/ballistics/hava_durumu_view.dart`: Rüzgâr kartı ile "Pro Ayarlar'a geç" arasındaki gizli `WindGuideLink` satırı ve yorumu silindi. ⓘ yanındaki yorum güncellendi.
- `lib/features/ballistics/wind_guide.dart`: yalnız bu bağlantı için olan `WindGuideLink` sınıfı (Key `wind-guide-link`) silindi. `WindGuide` (başlık, satırlar, pencere) ve `WindGuideLines` kaldı; ⓘ bunları kullanıyor. `linkLabel` metni ⓘ'nin ipucu ve VoiceOver etiketi olduğu için kaldı; yorumu buna göre düzeltildi.
- Depo tamamı tarandı (lib, test, tools, .github): bayrağı veren bir derleme ya da iş akışı yoktu; başka ekran veya metin bu bağlantıya bağlı değildi.

## Neden
- Sahibin kuralı (2026-10-15): kaldırılan ya da kullanılmayan özellik koddan silinir, bayrağın arkasına saklanmaz.
- Denetim bulgusu HDF-1 (düşük, `docs/reports/denetim_testflight_2026_10_15b.md`, PR #333).

## Uç durumlar
- Kayıtlı kullanıcı verisi yok: bağlantı hiçbir şey kaydetmiyordu, hiçbir kutuya değer yazmıyordu. Hiçbir sayı değişmez.
- TestFlight derlemesi bu bayrağı hiç vermiyordu; görünen ekran aynı kalır.
- Rüzgâr ⓘ metrik (m/s) ve imperial (mph) için aynı satırları gösterir.

## Bilerek yapılmayan
- Rüzgâr ⓘ metni, başlığı ve görünüşü değişmedi.
- `WIND_OBSERVATION` (Rüzgâr gözlemi) bayrağına dokunulmadı; bu görevin kapsamında değil.
- Eski raporlardaki (`ruzgar_rehber.md`, `temiz_tasarim_hedef.md`) tarihî anlatım değiştirilmedi.
- HDF-1 denetim testleri (`test/audit_2026_10_15b/hedef_split_audit_test.dart`, `tools/test_denetim_2026_10_15b_hedef.py`, `tools/test_denetim_2026_10_15b_guvenlik.py`) PR #333'te ve #333 henüz main'de değil. Bu yüzden bu dalda atlanmış (skip) HDF-1 testi yok; açılacak test yok. **Dikkat:** #333 bu PR'dan sonra birleşirse, orada bayrağın var olmasını bekleyen testler (`WIND_GUIDE_LINK` varsayılan kapalı, ortam okuması sayısı 16) güncellenmeli, HDF-1/FLG-1 `skip`'leri kaldırılmalı. #333'ün dosyalarına bu PR'da dokunulmadı.

## Testler
- `test/wind_guide_test.dart`: "imperial popup shows mph" testi silinen `WindGuideLink` yerine pencereyi doğrudan `WindGuide.show(metric: false)` ile açıyor; aynı 6 mph satırını ve m/s olmadığını denetliyor (zayıflatılmadı). Bağlantının görünmediğini, ⓘ'nin Rüzgâr başlığında olduğunu ve pencereyi açtığını denetleyen testler aynen duruyor; yalnız yorumları güncellendi.
- `test/temiz_tasarim_hedef_test.dart`: değişmedi (bağlantının olmadığını ve ⓘ'nin rehberi açtığını zaten denetliyor).
- Yeni `tools/test_hdf1_ruzgar_rehberi_sil.py` (5 test): `lib/` altında `WIND_GUIDE_LINK`, `WindGuideLink`, `'wind-guide-link'`, `_showWindGuideLink` yok; `.github` ve `tools` betikleri bayrağı vermiyor; Rüzgâr ⓘ hâlâ `WindGuide.linkLabel` ipucuyla `WindGuide.show` açıyor; rehber metni ve satırları duruyor. Eski kodda 2 testi kırmızı, yeni kodda yeşil (denendi).
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (399 dosya, 0 sorun). `python3 -m unittest discover -s tools -p 'test_*.py'` → 873 test OK. Bu ortamda Flutter yok; Flutter testleri yalnız CI'da çalıştı.

## CI bağlantıları
- Format (One-off dart format fix): https://github.com/sniperTurk/flutter-app/actions/runs/38853114680 — success, düzeltme commit'i gerekmedi.
- Analyze (One-off analyze diagnostic): https://github.com/sniperTurk/flutter-app/actions/runs/38853119622 — success.
- Test (One-off test diagnostic, files=test): https://github.com/sniperTurk/flutter-app/actions/runs/38853117401 — CI_TEST_SONUCU
- PR denetimleri (`verify`, `dart-checks`, `wind-acceptance`): CI_PR_SONUCU

🤖 Generated with [Claude Code](https://claude.com/claude-code)
