# Kule okları: dokunma alanı 44 pt, sıfır hizası (Hedef)

Sahibin kararları (2026-10-15, İstanbul):
- 22:29, HDF-2 (`docs/reports/denetim_testflight_2026_10_15b.md`, PR #333): "görünüş aynı, alan büyük". Oklar aynı görünür, yalnız görünmez dokunma alanı 44 × 44 pt olur.
- 22:31: "44 olması sağda LR tuşunun biraz üstüne geliyor, sorun olur mu". Kural: ok alanı L-R'nin ya da başka bir düğmenin üstüne asla gelmez; boş tarafa ya da tambura doğru büyür.
- 22:29: "sağ kule sıfır çizgi ile hizalı değil".

## Ne yapıldı
- **Oklar aynı.** ‹ › ˄ ˅ işaretleri aynı yerde, aynı boyda, kutusuz. Görünen hiçbir şey 1 pt bile kaymadı (testte ±0,5 pt ölçülüyor).
- **Dokunma alanı büyüdü** (görünmez):

| Ok | Önce | Şimdi |
|---|---|---|
| Üst ‹ › (her ekranda) | 28 × 78 pt | **44 × 78 pt** (eski 78 pt yükseklik korundu, 44 × 44'ü içerir) |
| Yan ˄ ˅, 390 pt | 74 × 30 pt | **74 × 44 pt** |
| Yan ˄ ˅, 430 pt | 83 × 34 pt | **83 × 44 pt** |
| Yan ˄ ˅, 320 pt | 58 × 24 pt | **58 × 44 pt** |

- **L-R'ye taşmıyor.** Sağ üst okun alanı tambura doğru (sola) büyüdü; sağ kenarı eskisi gibi L-R'nin 4 pt solunda bitiyor. Sol üst ok da tambura doğru (sağa) büyüdü. L-R'nin sol kenarının 1 pt içine dokunmak L-R'yi çalıştırıyor, oku değil.
- **Yan oklar** kutuya doğru büyüdü (˄ aşağı, ˅ yukarı), ok ile kutu arasındaki boşluğa. Kutunun içine girmiyor. 320 pt'de bile 44 pt sığıyor (retikül 264 pt; sığma sınırı 254 pt).
- **Sıfır hizası: kodda değişiklik gerekmedi.** Uygulamada yan kulenin "0" yazısı, sıfır çizgisi ve kırmızı işaret zaten retikülün yatay çizgisinde; 2R / 2L tam simetrik. Üst kulenin "0" yazısı ve işareti dikey çizgide. Bunu yeni test boyadığı yerden ölçüyor (aşağıda) ve 320 / 390 / 430 pt, yazı ×1.0 / ×1.3'te ±0,5 pt içinde geçti.
  - Görülen kayma tasarım resminde (`design/clean-2026-10-15`, `Hedef.png`): orada yan kule yazıları HTML'de `space-between` ile diziliyor ve "0" çizginin yaklaşık 5 pt üstünde. Uygulama yazıları çizgiden konumluyor (`_DrumPainter`: değer v, ortadan `(v − klik) × 9 pt`).
  - Not: kule kuruluyken (ör. "Kuleleri kur" sonrası 16 L) "0" bilerek çizgiden kayar; çizgideki değer kurulu klik olur. Bu davranış değişmedi.

## Nasıl
- Yalnız `lib/features/ballistics/scope_turrets.dart` değişti (`_TurretDrumState.build`). Retikül dosyasına dokunulmadı.
- Görünen ok (`glyph`) ile dokunma alanı (`hit`) ayrıldı. Görünen düzen eskisiyle aynı Row/Column; dokunma alanları bunun üstüne `Positioned` olarak konuyor.
- Her alan iki parçalı: okun eski hücresi (çekirdek) + tambura doğru şerit. İkisi de aynı oku adımlıyor; uzun basınca aynı ipucu çıkıyor. Üst kulede şerit tamburun üstüne geldiği için tambur orada da sürüklenebiliyor (sürükleme şeride de bağlandı).
- Alan boyları: `minTap = 44`; üstte genişlik `max(28, min(44, tambur genişliği / 2))`, yanda yükseklik `max(30·k, min(44, 30·k + 28·k))`.

## Neden
Apple'ın 44 pt en küçük dokunma boyutu (HDF-2). Sahip görünüşün değişmemesini, alanın L-R'yi kapmamasını istedi.

## Uç durumlar
- 320 pt ve yazı ×1.3: taşma yok; alanlar 44 pt; L-R ile çakışma yok.
- Üst ok şeridinde (tamburun ok tarafındaki ilk ~12 pt, 4 pt boşluk dahil 16 pt) dokunmak artık oku adımlar; önceden orada dokunmak bir şey yapmazdı. Sürükleme orada da aynen çalışır.
- **Yan ok şeridi retikülün üstünde (karar sahibe):** ok ile kutu arasındaki boşluk retikülün sağ kenarının üstünde. Retikülde tek dokunuşla çalışan bir düğme yok; yalnız çift dokunma (yakınlaştırmayı sıfırla) ve iki parmakla yakınlaştırma var. 390 pt'de 74 × 14 pt'lik (320 pt'de 58 × 20 pt) bu iki şeritte çift dokunma/iki parmak hareketi artık başlamaz; retikülün geri kalanında aynen çalışır. Retikül "dokunulan düğme" sayılırsa yan oklar en fazla 30·k pt (390 pt'de 30 pt, 320 pt'de 23,7 pt) olabilir; o zaman şerit kaldırılır, ayrı küçük iş.
- Yakınlaştırma açıkken retikülün sağ üstünde çıkan "N× ✕" düğmesi önceden de üst yan okun (˄) alanının altına biraz giriyordu. Bu PR ˄ alanını yukarı değil aşağı büyüttüğü için bu çakışmayı büyütmedi; çözülmesi istenirse ayrı iş (retikül dosyası).
- Davranış aynı: adım yönleri, klik sınırları, VoiceOver adımları (kaydırıcı eylemleri), "Kuleleri kur / sıfırla", L-R açma/kapama kayması.

## Bilerek yapılmayan
- Yan kule yazılarının yeri değiştirilmedi: zaten çizgiden konumlu ve çizgide (test kanıtı).
- Üst kule değiştirilmedi (doğruydu).
- `test/audit_2026_10_15b/hedef_split_audit_test.dart` içindeki HDF-2 testi main'de yok; yalnız birleşmemiş PR #333'te. O dosyaya dokunulmadı (başka PR). Aynı ölçümü (ipucu alanı ≥ 44 × 44, 320 pt) bu PR'ın testleri yapıyor; #333 birleşince o testteki `skip: true` kaldırılabilir, bu kodla geçmesi beklenir (o dosya bu dalda çalıştırılmadı).
- Hedef sonuç alanı (#330'un dosyaları `hedef_view.dart`, `scope_results.dart`), retikül, diğer sayfalar: dokunulmadı. Birleştirme ve TestFlight yok.

## Testler
- Yeni `test/kule_ok_alani_sifir_hizasi_test.dart` (320 / 390 / 430 pt × yazı 1.0 / 1.3):
  - (a) alan boyları (üst 44 × 78, yan 74·k × 44); okun ortasına, alanın merkezine ve dört köşesinin 1 pt içine dokunmak oku 1 klik adımlıyor;
  - (b) alanlar L-R, göz düğmesi, "Kuleleri kur", "Kuleleri sıfırla", büyütme satırı ile kesişmiyor; üst alanlar retikülle, yan alanlar kutuyla kesişmiyor; L-R sol kenar + 1 pt dokunuşu L-R'yi açıp kapıyor, kule klikleri değişmiyor;
  - (c) ok işaretleri main'deki yerinde (±0,5 pt), 24 pt (yan okta main'deki gibi en çok 30·k pt);
  - (d) yan kule "0" yazısının ortası, sıfır çizgisi ve boyanan kırmızı işaret yatay çizgide (±0,5 pt); 2R / 2L simetrik;
  - (e) üst kule "0" yazısı ve kırmızı işaret dikey çizgide (±0,5 pt);
  - (f) taşma yok (320×568 ×1.3, 390×844, 430×932 ×1.3);
  - ayrıca üst ok şeridinden başlayan sürükleme tamburu çeviriyor.
- Güncellenen eski beklentiler (eski 28 pt / 30 pt dokunma alanını yazıyordu; kayma değil, alan boyu):
  - `test/yan_kule_oklar_test.dart`: alan yüksekliği 30·k → 44 pt; ok merkezi artık ipucu alanından değil ok işaretinden ölçülüyor (yeri aynı, ±0,5 pt). Toplam boy 296·k aynı.
  - `test/temiz_tasarim_hedef_test.dart` (üst kule satırı): alan genişliği 28 → 44 pt; ok merkezleri işaretten (tambur kenarından 14 pt); "2U · 0 · 2D sığar" kontrolü 28 pt ok sütunlarıyla hesaplanıyor (aynı anlam).
  - `test/yan_kule_kucuk_test.dart` değişmedi, geçiyor.
- Yerel: `python3 tools/offline_dart_lint.py` → 388 Dart dosyası, 0 sorun. `python3 -m unittest discover -s tools -p 'test_*.py'` → 842 test başarılı. Bu ortamda Flutter motoru indirilemedi (ağ engeli, HTTP 403); Dart testleri yalnız CI'da çalıştı.

## CI
- Format (dart format, CI commit'i dala eklendi): https://github.com/sniperTurk/flutter-app/actions/runs/38797006046 — başarılı.
- Analyze, ilk: https://github.com/sniperTurk/flutter-app/actions/runs/38797127348 — başarılı.
- Tüm testler, ilk: https://github.com/sniperTurk/flutter-app/actions/runs/38797122469 — **başarısız**: yalnız yeni testte, 320 pt'de yan ok işaretinin 24 pt beklenmesi (main'de de 23,7 pt, hücre 30·k). Test düzeltildi.
- Kule testleri (yeni + eski kule dosyaları), ikinci: https://github.com/sniperTurk/flutter-app/actions/runs/38798751985 — **başarısız**: ×1.3'te sayfa ekrandan uzun, dokunulan nokta ekran dışındaydı (test hatası). Dokunmadan önce alan görünür yapıldı.
- Kule testleri, üçüncü: https://github.com/sniperTurk/flutter-app/actions/runs/38798953616 — başarılı.
- Son tur, head `6edf373`:
  - Format: https://github.com/sniperTurk/flutter-app/actions/runs/38799190118 — başarılı, değişiklik yok.
  - Tüm testler (`test`): https://github.com/sniperTurk/flutter-app/actions/runs/38799204798 — başarılı.
  - Analyze: https://github.com/sniperTurk/flutter-app/actions/runs/38799208633 — başarılı.
- PR #349 kontrolleri, head `7e3a243` (iOS CI run https://github.com/sniperTurk/flutter-app/actions/runs/38800714752): `verify` başarılı, `dart-checks` başarılı, `wind-acceptance` başarılı (`ios-simulator` atlandı, iş akışı böyle).
- Code Review ve Security review PR'da çalıştı: bulgu yok (https://github.com/sniperTurk/flutter-app/pull/349#issuecomment-6201444577).

## Ekran görüntüleri (iPhone Simulator)
- Önce (main): https://github.com/sniperTurk/flutter-app/blob/74e9910f1997319eb1559e4f95040f29ee82d786/latest/41_hedef_atis.png (run https://github.com/sniperTurk/flutter-app/actions/runs/38799030266)
- Sonra (bu dal): https://github.com/sniperTurk/flutter-app/blob/7bf6896bea6ce23416e9f3cb2db4420d212d7304/latest/41_hedef_atis.png (run https://github.com/sniperTurk/flutter-app/actions/runs/38799039827; commit başlığında görünen `9104632` iş akışının kendi sha'sı, derlenen kod bu dal)
- Kule kartı + retikül bölgesi iki görüntüde piksel piksel aynı (fark yok) — oklar görünüşte değişmedi.
- Simulator 402 pt genişlikte (390 değil). Tur yan kuleyi açmıyor: tur `pro_tup_basinci` adımında düşüyor (main'de de aynı, bu PR'dan değil), bu yüzden Pro → Hedef otomatik kurma ve yan kule görüntüsü yok. Yan kulenin hizası widget testleriyle ölçüldü.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
