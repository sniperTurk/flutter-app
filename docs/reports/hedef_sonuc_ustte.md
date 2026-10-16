# Hedef: sonuç en üstte

Sahibin kararı (2026-10-15 12:50): "Hedef'te sonuç en üstte… çok haklısın".
Tasarım: `design/clean-2026-10-15` dalı, README "Ek kararlar" ve `Hedef.png`.

## Ne yapıldı
- Hedef sayfasında mesafe seçicinin (−5 −1 [mesafe] +1 +5 ve kaydırıcı) hemen altına, retikül kartının üstüne iki sütunlu bir sonuç satırı eklendi.
- Sol sütun: "Üst kule", altında büyük "N klik", altında "X MOA yukarı" / "X MRAD aşağı".
- Sağ sütun: "Yan kule", altında büyük "N klik", altında "X MOA sağ" / "sol"; rüzgâr girilmemişse ve 0 klikse "rüzgâr yok".
- Solda 3 pt çizgi: Üst kule amber, Yan kule camgöbeği (koyu temada #F5B031 ve #4CC3E8; temanın kendi renkleri).
- Büyük sayı 34 pt kalın, eşit genişlikte rakam (mesafe değişince titremez). Dar ekranda veya büyük yazıda sütuna sığmazsa küçülür, taşmaz.
- VoiceOver her sütunu tek cümle okur: "Üst kule 55 klik, 13,8 MOA yukarı", "Yan kule 0 klik, rüzgâr yok".

## Nasıl
- Sayılar yeniden hesaplanmaz. Hedef sayfası dürbün görünümünü (`_scopeDial`) bir kez kurar; satır, bu görünümün zaten taşıdığı gereken çözümü (`requiredUp`, `requiredRight`), profilin klik değerini ve birimini okur. "Kuleleri kur" düğmesi de aynı sayılarla kurar.
- Klik sayısı mevcut `ScopeDialMath.clicksFor` ile bulunur (aynı yuvarlama).
- Değişen dosyalar: `lib/features/ballistics/hedef_view.dart` (yerleşim), `lib/features/ballistics/scope_results.dart` (yeni `TurretSolutionRow`), yeni test `test/hedef_sonuc_ustte_test.dart`, bu rapor.

## Neden
- Atıcı sayfayı açınca ilk bakışta kuleye ne kuracağını görür; retikül ve kuleler altta kalır.
- Satır kurulu kuleyi değil, bu mesafede GEREKEN çözümü gösterir; kule elle çevrilse de değişmez.

## Uç durumlar
- Açı 0,0 yazılıyorsa yön kelimesi yazılmaz ("0,0 MOA").
- Rüzgâr girilmiş ama yan düzeltme 0 klikse "rüzgâr yok" yerine "0,0 MOA" yazar (rüzgâr var ama bu mesafede klik gerektirmiyor).
- Spin sürüklenmesi veya sıfır ofseti yüzünden rüzgâr olmadan da yan düzeltme çıkarsa sayı ve yön gösterilir.
- Çözüm kule sınırının ötesindeyse satır gereken klikleri gösterir; "Kuleleri kur" sınıra kadar kurar ve mevcut sınır uyarısı eksik klikleri söyler (değişmedi).
- Çözüm yoksa (değer üretilemedi) veya dürbünün klik değeri katalogda yoksa satır gösterilmez; mevcut uyarı görünür.
- Vakum modunda (BC yok) rüzgâr modellenmez; yan kule 0 ve mevcut kırmızı uyarı yerinde.
- Yard profilinde de aynı satır; açı birimi profilin birimidir.

## Bilerek yapılmayanlar
- Hesap değişmedi. `scope_turrets.dart` (başka görev) ve düğme ikonlarına (başka görev) dokunulmadı.
- Eski "Kule: … · …" okuma satırı ve vuruş noktası retikül kartında aynen duruyor.
- Açık tema renkleri için ayrı karar yok; temanın amber/camgöbeği renkleri kullanıldı.

## Testler
- Yeni `test/hedef_sonuc_ustte_test.dart`:
  - satır kaydırıcının altında, retikül kartının ve retikülün üstünde; iki sütun yan yana;
  - metrik MOA, metrik MRAD ve yard profilinde sayılar dürbün görünümünün gereken çözümüne eşit; "Kuleleri kur" aynı klikleri kurar;
  - kuleler sıfırlanınca satır değişmez (kurulu değil, gereken çözüm);
  - 0 rüzgârda "rüzgâr yok";
  - mesafe +20 değişince sayılar yeni çözüme güncellenir;
  - VoiceOver etiketleri; amber/camgöbeği 3 pt çizgi, 34 pt eşit genişlikte rakam;
  - 320 pt ekran ve yazı ölçeği 1,3'te taşma yok.
- Mevcut testler (`test/core/hedef_golden_numbers_test.dart` dahil) değiştirilmedi.
- Yerel: `python3 tools/offline_dart_lint.py` geçti (380 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (842 test).
- Bu ortamda Flutter SDK indirilemedi (storage.googleapis.com engelli); `flutter test` / `flutter analyze` yalnız CI'da çalıştı.

## CI
Son kod commit'i `edb0f62` üzerinde:
- iOS CI `verify` (macOS): geçti — https://github.com/sniperTurk/flutter-app/actions/runs/38776612779/job/116570561903
- `dart-checks` (format, `flutter analyze`, birim ve widget testleri): geçti — https://github.com/sniperTurk/flutter-app/actions/runs/38776612779/job/116565789993
- `wind-acceptance`: geçti — https://github.com/sniperTurk/flutter-app/actions/runs/38776612779/job/116565789378
- `ios-simulator`: atlandı (iş akışı bu PR'da çalıştırmıyor; Simulator derlemesi yapılmadı).
- analyze-diag: geçti — https://github.com/sniperTurk/flutter-app/actions/runs/38776611676
- test-diag (`test` klasörünün tamamı): geçti — https://github.com/sniperTurk/flutter-app/actions/runs/38776615053
- İlk commit'te `analyze` tek bir `prefer_const_constructors` bilgisiyle kırmızıydı (yeni testte); `edb0f62` ile düzeltildi.
- Format: format-fix iş akışı (375209577) testi biçimlendirip `236e1e4` commit'ini ekledi.
- TestFlight çalıştırılmadı; birleştirme yapılmadı.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
