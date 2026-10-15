# KUL-2: Hız Doğrulama, regülatörsüz PCP'de tablo hızı

Sahip kararı: 2026-10-15 20:47 (İstanbul), "düzeltmek için görev aç". Bulgu KUL-2 (orta), `docs/reports/denetim_testflight_2026_10_14b.md`.

## Ne değişti

- Regülatörsüz PCP'de Profil'deki "Basınca göre hız" tablosu kullanılabiliyorsa (en az 2 nokta ve Tüp basıncı girili), Hedef hızı tablodan alıyor; Namlu çıkış hızı hesaba girmiyor.
- Bu durumda Hız Doğrulama artık hızı profile yazmıyor.
- Sayfada, "Namlu çıkış hızı" seçiliyken şu uyarı çıkıyor: "Bu tüfekte hız, Profil > Mühimmat'taki "Basınca göre hız" tablosundan, Tüp basıncına göre geliyor; Namlu çıkış hızı hesaba girmiyor. Bu yüzden doğrulanan hız profile yazılmaz. Hızı düzeltmek için tablodaki hızları kronografla ölçüp Profil'de güncelleyin."
- Sonuçtaki "Doğrulanmış hızı profile uygula" düğmesi kapalı. Yanındaki ⓘ nedenini ve ne yapılacağını söylüyor (örnek: 200 bar 886 fps, 120 bar 837 fps).
- Kullanıcı artık "Doğrulanmış hız profile uygulandı" mesajını bu durumda görmüyor; profil değişmiyor.

## Nasıl

- Yalnız `lib/features/tools/truing_screen.dart` değişti.
- Yeni `_velocityFromPcpTable` kontrolü Hedef'teki kuralın aynısı (`pcpTableAtProfilePressure`): PCP, `PcpPressure.velocity(...)` sonucu tablodan geliyor ve regülatör devre dışı değil, gizli `PRO_TUBE_PRESSURE` kapalı.
- `_apply` bu durumda hiçbir şey yazmadan dönüyor (düğme kapalı olsa da ikinci koruma).
- Metinler `TruingFieldInfo.pcpTable` ve `TruingFieldInfo.pcpTableApply` içinde.

## Neden

Hedef bu tüfekte tablo hızını kullandığı için, doğrulanan hızı Namlu çıkış hızına yazmak hiçbir sonucu değiştirmiyordu; kullanıcı ise "uygulandı" görüyordu. Sahip daha küçük ve dürüst çözümü seçti: yazma, açıkça söyle.

## Uç durumlar

- Tablo tek noktalı (kullanılamaz): eskisi gibi, hız profile yazılıyor (test var).
- Regülatörlü PCP, tüp regülatörün üstünde: eskisi gibi yazılıyor (test var).
- Regülatörlü PCP, tüp regülatörün altında: Hedef sıfırı profil hızıyla yapıyor, eskisi gibi yazılıyor.
- Tüp basıncı boş: tablo kullanılmıyor, eskisi gibi yazılıyor.
- Ateşli silah: değişiklik yok.
- Kayıtlı veri silinmiyor; profil, tablo ve hız olduğu gibi kalıyor.

## Bilerek yapılmayan

- Hesap kısmı değişmedi: "Hızı hesapla" yine profil hızından başlayıp sonucu gösteriyor; yalnız yazma kapalı.
- BC ve Sürüklenme eğrisi doğrulaması bu PCP'de de profil hızıyla çözülüyor; görev "diğer yollar değişmesin" dediği için dokunulmadı.
- Tabloyu ölçekleyen (büyük) çözüm yapılmadı; sahip küçük çözümü seçti.

## Testler

`test/audit_2026_10_14b/turret_zero_cleanup_audit_test.dart`:
- KUL-2 testi `skip` kaldırıldı ve yeni davranışı ölçüyor: uyarı görünüyor, düğme kapalı, ⓘ var ve "düğme kapalı" diyor, onay penceresi açılmıyor, "uygulandı" yok, profil hızı 270 m/s ve tablo 2 nokta olarak kalıyor.
- Yeni: tek noktalı tabloda ve regülatörlü PCP'de (tüp regülatörün üstünde) düğme açık; tek noktalıda hız yazılıyor (≈240 m/s).
- Koruma testi `design guard: with a usable table …` olduğu gibi duruyor.

## Doğrulama

- Yerel: `python3 tools/offline_dart_lint.py` geçti (379 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (842 test).
- Yerel Flutter çalıştırılamadı: SDK indirme ağ (403) tarafından engellendi; Flutter testleri yalnız CI'da koştu.
- CI: aşağıda.

## CI

Kod `fee4107` commit'inde (format iş akışının commit'i dahil); sonraki commit'ler yalnız bu rapor.

- Format (`format-fix.yml`): başarılı, bir format commit'i ekledi. https://github.com/sniperTurk/flutter-app/actions/runs/38781335527
- Test tanısı (`test-diag.yml`, `files=test`): başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38781823969
- Analiz tanısı (`analyze-diag.yml`): başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38781827199
- iOS CI, `0a8bda6` (kod + rapor), run https://github.com/sniperTurk/flutter-app/actions/runs/38784326768 :
  - `dart-checks` (format, analyze, tüm testler, Python takımı, G1/G7): başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38784326768/job/116592457264
  - `wind-acceptance`: başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38784326768/job/116592456993
  - `verify` (macOS): başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38784326768/job/116598545466
  - `ios-simulator`: atlandı (yalnız elle istenince koşar).
- Not: `fee4107` üzerindeki ilk iOS CI koşusu, rapor commit'i yeni koşu başlatınca iptal oldu (aynı PR, `cancel-in-progress`). Bu son rapor güncellemesi de yeni bir koşu başlatır; sonucu PR'daki kontrollerde görünür.

Draft PR; birleştirme ve TestFlight yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
