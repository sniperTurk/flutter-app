# Hava Durumu: üst karttaki "Hava" başlığı silindi

Kod değişikliği PR #372 ile main'e alındı (sahibin ana oturumu birleştirdi, 16.10.2026 22:37 İstanbul, commit b1746492). Bu rapor ve bir test yorum satırı düzeltmesi, birleştirmeden sonra hazırlandığı için ayrı taslak PR ile geliyor.

Sahibin kararı (16.10.2026 21:10, İstanbul): "Hava Durumu sayfası 'Hava' ifadesini sil, zaten yukarıda Hava Durumu yazıyor."

## Ne yapıldı
- Hava Durumu sayfasında en üst kartın üstündeki **"Hava"** başlığı silindi (`MenzilSectionHeader('Hava', key: Key('environment-weather-header'))`, 15.10.2026'da eklenmişti). Gizlenmedi, koddan silindi (CLAUDE.md: kaldırılan özellik silinir).
- Altındaki kart aynen duruyor: Sıcaklık, Bağıl nem kutuları ve "Hava verisi al" / "Sıfırla" düğmeleri değişmedi.
- Kart artık sayfanın ilk öğesi. Üst çubuğun **10 pt** altında başlıyor (`MenzilPage` üst boşluğu, `MenzilSpace.md`). Pro Ayarlar sayfasındaki ilk kart da aynı 10 pt ile başlıyor. Başka bir boşluk eklenmedi.
- Diğer başlıklar (Basınç Ölçer, İrtifa, Rüzgâr, Hava özeti) yerinde. Hedef sayfasındaki hesap dökümündeki / DOPE'taki "Hava" satırı (`ballistics_screen.dart` ~2611) bu iş değil; dokunulmadı.

## Nasıl
- `lib/features/ballistics/hava_durumu_view.dart`: yalnız başlık widget'ı ve onun yorumu silindi, yerine kısa bir açıklama yorumu kondu. Başka satıra dokunulmadı (Mühimmat sıcaklığı bloğu, ~250–301, diğer görevin alanı; değişmedi).
- Testler güncellendi (aşağıda).

## Neden
Üst çubukta zaten "Hava Durumu" yazıyor; hemen altında bir de "Hava" başlığı tekrar ediyordu.

## Uç durumlar
- Profil yokken açılan Hava Durumu sayfası aynı listeyi kullanıyor: orada da "Hava" başlığı yok; turuncu "Hava hazır, sıra tüfekte" kartı ve altındaki boşluk aynı.
- Ateşli tüfek profilinde Mühimmat sıcaklığı bölümü, Hava kartının altında aynen duruyor.
- Dar ekran (320 pt) ve 390 × 844: kart üst çubuğun hemen altında, Sıcaklık ve Bağıl nem kutuları ekranda (alt menünün üstünde), taşma yok.
- Kayıtlı veri etkilenmedi (yalnız bir başlık yazısı kalktı).

## Bilerek yapılmayan
- "Hava özeti" başlığı ve hesap dökümündeki "Hava" satırı değiştirilmedi.
- `_atmosphereResult` içindeki "like the other Hava Durumu cards" yorumu değiştirilmedi (Basınç Ölçer / İrtifa / Rüzgâr başlıklı olduğu için hâlâ doğru; dosyada başka satıra dokunmama kuralı).
- Birleştirme, TestFlight yok. PR taslak.

## Testler
- `test/hava_basligi_sil_test.dart` (yeni, gerçek uygulama kabuğu `HomeScreen`, aktif profil): 390 × 844 ve 320 × 568 pt'de
  - `environment-weather-header` yok, sayfada yalnız "Hava" yazan hiçbir yazı yok;
  - üst çubuk başlığı (`top-bar-title`) "Hava Durumu";
  - Basınç Ölçer, İrtifa, Rüzgâr başlıkları duruyor;
  - ilk kart (Sıcaklık'ı içeren `MenzilCard`) üst çubuğun alt kenarından 10 pt (±0,5) aşağıda başlıyor;
  - Sıcaklık ve Bağıl nem kutuları alt menünün üstünde, kaydırmadan görünüyor; hata/taşma yok.
- `test/temiz_tasarim_hedef_test.dart`: eski "'Hava' başlığı üst kartın üstünde" testi, başlığın **yok** olduğunu doğrulayacak şekilde değişti (`findsNothing`; sayfada "Hava" yazısı `findsOneWidget` → `findsNothing`). "Hava özeti" başlığı, boyutu (18) ve özet kartının "Hava" tekrar etmemesi kontrolleri aynen kaldı. Dosya başındaki açıklama yorumu güncellendi. Başka hiçbir test zayıflatılmadı.
- Yerel: `python3 tools/offline_dart_lint.py` geçti (407 Dart dosyası, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (915 test, 1 atlanan — önceden de atlanıyordu). Bu ortamda Flutter SDK indirilemedi (storage.googleapis.com ağ engeli), `flutter test` yerelde çalışmadı; Flutter testleri CI'da çalıştı.

## Ekran görüntüleri (önce / sonra)
Gerçek uygulama, iOS Simulator (iPhone 17 Pro, iOS 26.2), `sim-screens` iş akışı, kayıtlı PCP profiliyle Hava Durumu sekmesi:
- Önce (main e7b29bf, başlık var): https://raw.githubusercontent.com/sniperTurk/flutter-app/525a32ec001ee8c66e5a675b226ff7f3784c65cc/latest/01_hava_durumu_390.png — çalıştırma https://github.com/sniperTurk/flutter-app/actions/runs/38964150151 (başarılı)
- Sonra (bu değişiklik, başlık yok): https://raw.githubusercontent.com/sniperTurk/flutter-app/20c08ea443c6bcda63c9ec21af50631bde17d5a3/latest/01_hava_durumu_390.png — çalıştırma https://github.com/sniperTurk/flutter-app/actions/runs/38972635526 (başarılı)

![Önce](https://raw.githubusercontent.com/sniperTurk/flutter-app/525a32ec001ee8c66e5a675b226ff7f3784c65cc/latest/01_hava_durumu_390.png)
![Sonra](https://raw.githubusercontent.com/sniperTurk/flutter-app/20c08ea443c6bcda63c9ec21af50631bde17d5a3/latest/01_hava_durumu_390.png)

Sonra görüntüsünde üst çubuğun altında doğrudan Sıcaklık | Bağıl nem kartı başlıyor; "Basınç Ölçer" ve "İrtifa" başlıkları duruyor.

Dürüst not: Görüntüler Simulator'ın gerçek genişliğinde, **402 pt** (iPhone 17 Pro). Tur, uygulamayı 390 ve 320 pt genişliğe daraltmayı denedi, ama cihazda bu daraltma etkili olmadı (iki dosya aynı çıktı; dosya adındaki "390" yanıltıcı). 390 × 844 ve 320 pt ölçüleri widget testinde (`test/hava_basligi_sil_test.dart`) doğrulandı, ekran görüntüsüyle değil. Görüntüler için kullanılan tur dosyası PR'a eklenmedi; yalnız geçici `ci/hava-basligi-once` / `ci/hava-basligi-sonra` dallarında çalıştı. Bu iki geçici dal silinemedi (bu ortamda dal silme izni yok, HTTP 403); main'e etkisi yok, sahibin oturumu silebilir.

## CI
PR #372 son commit'i (9a1b2a59, main'e alınan içerik):
- iOS CI `dart-checks` (format, `flutter analyze --fatal-infos --fatal-warnings`, tüm `flutter test`, offline Python paketi, G1/G7): **başarılı** — https://github.com/sniperTurk/flutter-app/actions/runs/38947408109/job/117129917418
- iOS CI `wind-acceptance`: **başarılı** — https://github.com/sniperTurk/flutter-app/actions/runs/38947408109/job/117129918057
- iOS CI `verify` (macOS): **başarılı** — https://github.com/sniperTurk/flutter-app/actions/runs/38947408109/job/117136839044
- Format düzeltme (dart format, CI commit'i dala eklendi): https://github.com/sniperTurk/flutter-app/actions/runs/38947277028
- `test-diag` / `analyze-diag` tetiklendi; ancak aynı anda başka görevler de aynı iş akışlarını başlattığı için (girdi dalı API'de görünmüyor) hangi çalıştırmanın bu dala ait olduğu kesin belirlenemedi; bu yüzden onların sonucu kanıt olarak verilmiyor. Aynı kontrolleri `dart-checks` PR üzerinde çalıştırdı ve geçti.
- Bu rapor PR'ının kontrolleri PR sayfasında.

## İncelemeler
- Code Review (5 paralel inceleyici: CLAUDE.md, hata taraması, git geçmişi, önceki PR yorumları, kod yorumları): sorun yok; eskimiş bir test dosyası başlık yorumu düzeltildi. https://github.com/sniperTurk/flutter-app/pull/372#issuecomment-6223299266
- Security review: bulgu yok (ağ, kayıt, izin, bağımlılık, workflow değişikliği yok).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01HjYLowPq217oKJ8MCpkQy1
