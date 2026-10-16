# Hava Durumu: üst karttaki "Hava" başlığı silindi

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
EKRAN_GORUNTULERI

## CI
CI_LINKLERI

## İncelemeler
- Code Review (5 paralel inceleyici: CLAUDE.md, hata taraması, git geçmişi, önceki PR yorumları, kod yorumları): sorun yok; eskimiş bir test dosyası başlık yorumu düzeltildi. https://github.com/sniperTurk/flutter-app/pull/372#issuecomment-6223299266
- Security review: bulgu yok (ağ, kayıt, izin, bağımlılık, workflow değişikliği yok).

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01HjYLowPq217oKJ8MCpkQy1
