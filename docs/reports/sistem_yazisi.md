# Sistem yazısı: Inter yerine iPhone yazısı (San Francisco)

Sahip kararı (2026-10-13 20:19): uygulamanın bütün sayfalarında Inter bırakıldı, iPhone'un kendi yazısı (San Francisco, SF) kullanılıyor. Rakamların "seyrek" görünmesinin sebebi olan sabit genişlikli rakamlar (tabular) artık yalnız canlı değişen değerlerde var.

Dal: `feat/sistem-yazisi` (main'den). Taslak PR, birleştirme yok, TestFlight yok.

## Ne değişti

- `lib/ui/menzil_theme.dart` — `MenzilType`:
  - `family = 'Inter'` kalktı. Yerine `textFamily = 'CupertinoSystemText'` (SF Pro Text) ve `displayFamily = 'CupertinoSystemDisplay'` (SF Pro Display) geldi. `familyFor(boyut)` 20 punto altında Text, 20 ve üstünde Display seçer.
  - `family` adı silinmedi: açık PR'lar derlenmeye devam etsin diye artık `textFamily`'yi gösteriyor.
  - Dar yazı yedek listesi `numericFallback` (Barlow Condensed, Roboto Condensed, Arial Narrow) tamamen kaldırıldı.
  - `display()` ve `number()` artık varsayılan olarak normal (orantılı) rakam kullanıyor. Sabit genişlik için `live: true` verilir ya da `MenzilType.tabular` eklenir.
  - `display` harf aralığı -1'den -0,5'e çekildi (SF Display büyük boyda zaten sıkı). `heading` içindeki +0,2 aralık kaldırıldı.
- Tema (`MenzilTheme`): `fontFamily: Inter` kalktı. Yerine `typography: Typography.material2021(platform: TargetPlatform.iOS)` geldi. Böylece bütün Material yazı rolleri (başlık, gövde, etiket) SF Text/Display alıyor. Düğme, sekme, snackbar, tablo ve ipucu yazılarındaki elle yazılmış `fontFamily` değerleri `MenzilType.textFamily` oldu (hepsi 20 puntonun altında).
- Elle yazılmış aile adları: `scope_dial_view.dart` (4 çizim yeri) ve `wind_clock_picker.dart` artık `MenzilType.familyFor(size)` kullanıyor. `lib/` içinde `'Oswald'` geçen bir ekran stili yoktu. Oswald yalnız PDF'te kullanılıyor (aşağıya bakın).
- Sabit genişlikli rakam kalkan yerler (durağan değerler):
  - Profil özet kartları (`MenzilMetricCard`), DOPE tablosu (`dataTextStyle`)
  - Form kutuları (`MenzilInput`), Hava sonucu kartı (`ballistics_screen`)
  - Rüzgâr saati rakamları, isabet yüzdesi, Sight height sonuçları, Hava Durumu rüzgâr değeri, ±1 düğme yazıları
- Eski açıklamalardaki "condensed" (dar yazı) sözleri düzeltildi (`menzil_widgets.dart`, 3 yorum satırı).

## iOS'ta sistem yazısı nasıl seçiliyor

SF uygulamaya gömülemez, yazıyı iOS kendisi verir. Flutter'da bunun için iki vekil ad var (Flutter 3.47.2 kaynağında `TextStyle.fontFamily` açıklamasında yazar):

- `CupertinoSystemText`: SF Pro Text. 20 puntonun altı için tasarlanmıştır, harfleri biraz daha açıktır.
- `CupertinoSystemDisplay`: SF Pro Display. 20 punto ve üstü içindir. Motor bu adı iOS'un büyük sistem yazısı olarak kaydeder.

`MenzilType.familyFor` bu eşiği (20 pt, Apple'ın eşiği) uygular. Böylece her boyut doğru optik çizimle gelir. Android ve Linux testlerinde bu iki ad bulunamaz ve varsayılan yazıya düşer; uygulama yalnız iPhone için.

## Seçilen kalınlıklar

- Başlıklar (`heading`) ve büyük değerler (`display`): w700, yani kalın.
- Değerler (`number`): varsayılan w600'den w500'e (orta) indi. SF'de yarı kalın rakamlar ağır duruyordu; sahibin istediği "değer orta" kalınlığı bu.
- Etiketler (`label`, `caption`): w400 (normal). Gövde (`body`) ve birim (`unit`): w500, değişmedi.
- Profil özetindeki değerler sahibin önceki kararıyla (2026-10-11) zaten w400 idi. Bu PR o kararı değiştirmedi.
- Kalınlıkların SF'de dengeli olup olmadığı yalnız kodla denetlendi. Gerçek iPhone'da gözle bakılmadı (aşağıya bakın).

## Sabit genişlikli rakam nerede kaldı ve neden

Yalnız canlı değişen ve titrememesi gereken sayılarda kaldı:

- Hedef: atış mesafesi göstergesi (±1/±10 ve basılı tutunca canlı değişir). Boş durum sayfasındaki mesafe adımlayıcı da aynı.
- Atış Çözümü (dürbün): "Kule: … klik" satırı, isabet satırı (kule sürüklenirken canlı değişir), büyütme değeri, kule tamburu rakamları, retikül üzerindeki tutma ve rüzgâr sayıları.
- Canlı sensör değerleri: Pusula derecesi, Su terazisi, Dürbün yatıklığı (cant), Tüfek eğimi ölçümü (72 punto açı).

Bunlarda sayı değişince genişlik değişirse yazı sağa sola kayar. Sabit genişlik bunu önler. Uygulamada sayaç (timer) gösterimi yok.

## Inter ve Oswald dosyaları

- Saklandı, silinmedi. Dosyalar `assets/fonts` içinde, `pubspec.yaml` girişleri yerinde. Yanlarına "2026-10-13'ten beri ekranlarda kullanılmıyor" notu yazıldı.
- Inter ekranlarda kullanılmıyor. Testler onu SF'nin genişlik yerine geçeni olarak kullanıyor (aşağıya bakın).
- Oswald hâlâ DOPE kartı PDF'inde gömülü (`ballistics_screen.dart` → `dope_card.dart`, `assets/fonts/Oswald-*.ttf`). Bu yüzden kaldırılamaz, ekranlarda kullanılmıyor.
- `pubspec.yaml`'de yalnız yorum değişti. Kural gereği `lockfile-provenance.txt` içindeki pubspec SHA-256 değeri `tools/write_lockfile_provenance.py` ile yenilendi. `pubspec.lock` değişmedi; Inter'e geçen #173'te de böyle yapılmıştı.

## Özel durumlar

- **Türkçe harfler (ğ ş ı İ ç ö ü):** SF bütün Türkçe harfleri içerir. Yedek yazı listesi kaldırıldığı için harf başka bir yazıya düşmüyor. Testte bir Türkçe satırın sistem yazısıyla dizildiği denetlendi. Harf şekillerini yalnız gerçek iPhone gösterebilir.
- **Büyük yazı (1,3×) ve dar telefon (375 pt):**
  - SF Linux CI'da yok. Bu yüzden testler, saklanan Inter dosyalarını iki SF adı altında yükleyip genişliği onunla ölçüyor. Inter, SF Pro Text'e yakın genişlikte; ölçüm yaklaşık, birebir değil.
  - Mevcut ekran taraması (`test/ekran_boyutu_test.dart`) artık SF adlarıyla yazılan yazıları ölçüyor. Yeni testte ayrıca beş sekme 375 pt ve 1,3× büyüklükte hem açık hem koyu temada taşmasız geçiyor.
  - Bilinen açık bulgu ("Barut katsayısı", 375 pt 1,0×) eskisi gibi listede duruyor.
- **Koyu tema:** Yazı ailesi temadan bağımsız. Açık ve koyu temanın ikisi de aynı SF rollerini alıyor; testte ikisi de denetleniyor.
- **PDF (`dope_card.dart`):** Değişmedi. PDF kendi gömülü yazısını (Oswald + DejaVu) kullanıyor ve hiç `MenzilType` kullanmıyordu.

## Bilerek yapılmayanlar

- Harf aralığı Apple'ın boyuta göre değişen tablosuna (tracking) göre ayarlanmadı. Text stilleri SF'nin varsayılan aralığıyla kaldı. İstenirse ayrı bir işte, iPhone'da bakılarak yapılmalı.
- Ana bilgisayarda Flutter SDK olmadığı için gerçek iPhone'da veya Simülatörde gözle bakılmadı. iOS CI (macOS) koşturulmadı.
- `drag_curve_field`, pusula kadranı, retikül ekranı gibi `fontFamily` vermeyen çizimlere dokunulmadı. Onlar zaten motorun varsayılanı olan sistem yazısını kullanıyordu.
- Inter ve Oswald dosyaları silinmedi (saklama kuralı).
- Eski PR #128 (`feat/sistem-yazi-karakteri`) yalnız fikir için okundu. O PR `fontFamily: null` kullanıyordu ve tabular rakamları her yerde bırakıyordu. Bu iş güncel main üzerine sıfırdan yapıldı. **#128 kapatılabilir.**

## Hangi test neyi kapsıyor

Yeni test dosyası `test/sistem_yazisi_test.dart`:

- MenzilType stillerinde Inter/Oswald yok, yedek yazı yok, boyuta göre doğru SF adı var. Stiller varsayılan olarak orantılı rakam kullanıyor; `live: true` sabit genişlik veriyor. Kalınlıklar: başlık w700, değer w500, etiket w400.
- Tema: açık ve koyu temada bütün yazı rolleri, düğme ve kutu etiketi SF adlarını kullanıyor.
- Profil özet kartlarındaki hiçbir yazıda sabit genişlikli rakam yok.
- Hedef / Atış Çözümü: isabet satırı, "Kule:" satırı ve atış mesafesi göstergesi sabit genişlikli rakamı koruyor.
- Profil, Hava Durumu, Pro, Hedef ve Araçlar sekmeleri 375 pt ve 1,3× yazıda, açık ve koyu temada taşmıyor.
- Türkçe harfler sistem yazısıyla diziliyor.

Güncellenen testler:

- `test/ekran_boyutu_test.dart`: Inter dosyalarını SF adlarıyla yüklüyor; kesik yazı denetimi iki SF adını tanıyor.
- `test/usage_guide_test.dart`: `MenzilType.family` yerine `MenzilType.textFamily` bekliyor.

## Yerelde ve CI'da koşanlar

- Yerelde:
  - `python3 tools/offline_dart_lint.py`: PASS (314 Dart dosyası, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: 724 test, OK. İlk koşuda provenance testi pubspec yorumu yüzünden düştü; SHA yenilenince geçti.
- CI (hepsi `feat/sistem-yazisi`, commit `329ab3a`; dalın bu dalı checkout ettiği loglarda doğrulandı):
  - Biçim düzeltme: https://github.com/sniperTurk/flutter-app/actions/runs/38439142128 (başarılı, `e7061a5` biçim commit'i alındı).
  - `flutter test test`: https://github.com/sniperTurk/flutter-app/actions/runs/38440621378 (başarılı; çıkış kodu 0).
  - `flutter analyze --fatal-infos --fatal-warnings`: https://github.com/sniperTurk/flutter-app/actions/runs/38440626519 (başarılı; tek uyarı satırı `flutter pub get`'in "pub outdated" notu).
- `integration_test/*` dosyalarında yazı ailesi ya da tabular denetimi yok. Bu yüzden değişiklik gerekmedi. iOS CI (Simülatör) bu iş için koşturulmadı ve geçti denemez.
- Bu rapor commit'i yalnız belge ekliyor; Dart kodu `329ab3a` ile aynı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
