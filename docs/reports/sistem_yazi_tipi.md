# Sistem yazı tipi (PR #128'in yerine)

Sahibin kararı (15.10.2026 20:53, İstanbul): PR #128 "Yazı karakteri: sistem yazısı (iOS'ta San Francisco)" yetişirse bu sürüme girsin.

## Ne

- PR #128'in amacı (uygulamada sistem yazısı, iOS'ta San Francisco) **zaten main'de**. 13.10.2026'da birleşen PR #277 ("Yazı: iPhone sistem yazısı (San Francisco), Inter yerine") bunu yaptı.
- Bu yüzden bu PR uygulama koduna dokunmaz. Yalnız istenen küçük testi ve bu raporu ekler.
- PR #128 kapatılır, bu PR'a bağlantı verilir.

## Nasıl

- #128 eski bir geçmişe dayanıyor: main yeniden yazıldığı için ortak ata yok (`git merge-base` boş). Birleştirme ya da rebase mümkün değil.
- #128'in değişikliği (`MenzilType.family = null`) bugünkü main'e uygulanırsa #277'nin daha iyi çözümünü geri alırdı. #277, boyuta göre SF Pro Text (20 pt altı) ve SF Pro Display (20 pt ve üstü) seçiyor.
- Bu yüzden `feat/sistem-yazi-karakteri-2` dalı main'den açıldı ve yalnız şu dosyalar eklendi:
  - `test/sistem_yazi_tipi_test.dart`: açık ve koyu temada metin rollerinin sistem yazısı adlarını (`CupertinoSystemText` / `CupertinoSystemDisplay`) kullandığını kontrol eder. pubspec `fonts:` altında paketlenen hiçbir yazıya (bugün Inter, Oswald) düşmediğini ve yedek yazı listesi olmadığını da kontrol eder.
  - Bu rapor.

## Neden

- Sahibin istediği "yalnız yazı karakteri değişsin" sonucu main'de zaten var. Aynı işi ikinci kez yapmak boş ya da geriye giden bir değişiklik olurdu.
- Boyutlar, kalınlıklar, tabular rakamlar (Hedef'teki büyük canlı sayılar) ve yerleşim değişmedi. Kod değişmediği için 390 pt ekranda yeni bir taşma da olamaz. Bunları zaten `test/sistem_yazisi_test.dart` ve `test/ekran_boyutu_test.dart` kontrol ediyor.

## Uç durumlar

- Android'de ve Linux CI'da SF yok. Bu adlar platformun varsayılan yazısına düşer. Testler genişlik için Inter dosyalarını diskten okuyup SF yerine kullanıyor.
- DOPE kartı PDF'i Oswald ile kalır. PDF'e yazı dosyası gömmek gerekir ve SF'nin lisansı buna izin vermez.
- Kayıtlı kullanıcı verisine dokunulmadı.

## Bilerek yapılmayan

- **Kullanılmayan yazı dosyalarının silinmesi bu PR'da yok.** Uygulama ekranları Inter'i ve Oswald'ın Light / SemiBold / Bold kalınlıklarını kullanmıyor. Inter dosyaları yalnız testlerde, diskten okunuyor. DOPE PDF'i yalnız Oswald-Regular ile Oswald-Medium'u kullanıyor. Bunları silmek için `pubspec.yaml` değişmeli. O zaman `lockfile-provenance.txt` içindeki `pubspec_sha256` de yeniden üretilmeli. Bu oturumda sabitlenmiş Flutter SDK indirilemedi (proxy 403). Bu kayıt dosyasını elle değiştirmek de bu oturumda izinli değildi. Bu yüzden silme ayrı bir görev olarak yapılmalı: pubspec'te `Inter` ve `Oswald` font aileleri kaldırılır, Oswald-Regular/Medium `assets:` altına alınır, Oswald-Light/SemiBold/Bold silinir ve kayıt dosyası araçla yeniden üretilir.
- Tema düğmesi, koyu tasarım ve başka sayfalara dokunulmadı. PR #228'e dokunulmadı.

## Testler

- Yeni: `test/sistem_yazi_tipi_test.dart`.
- Yerel: `python3 tools/offline_dart_lint.py` geçti (380 Dart dosyası, 0 sorun). `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (842 test).
- Yerel `flutter test` / `flutter analyze` çalıştırılamadı (BLOCKED): Flutter 3.47.2'nin Dart SDK indirmesi proxy'de 403 aldı. Sonuç için aşağıdaki CI işleri esas alınır.

## CI bağlantıları

(CI sonuçları PR açıklamasında güncellenir.)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
