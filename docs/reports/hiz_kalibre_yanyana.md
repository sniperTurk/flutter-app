# Namlu çıkış hızı | Kalibre yan yana (fix/hiz-kalibre-yanyana)

Sahip isteği (2026-10-13 19:32, TestFlight ekran görüntüsü, Profil Oluştur > Tüfek, PCP Hatsan Hercules):
"Namlu çıkış hızı, Kalibre tek sütun olmasın, her satır 2 kutu olsun."

## Ne değişti

Tüfek kartında "Namlu çıkış hızı" ve "Kalibre" artık tek satırda: hız solda, kalibre sağda. Bu, PCP Tüfek ve Ateşli Tüfek için aynı.

Marka ve Model eskisi gibi kendi tam satırlarında kalıyor. Formun geri kalanının sırası değişmedi: Mermi çapı ("Fişeğim listede yok" seçilince), Namlu yiv yönü | Yiv oranı, Sight height | Mesafe birimi, Sıfırlama mesafesi.

Dosyalar ve kodlar:

- `lib/features/profiles/profiles_screen.dart`
  - Yeni metot `_velocityCaliberRow()`. Eskiden alt alta duran iki `MenzilFullWidth` (hız ve kalibre) yerine tek bir `MenzilFullWidth` içinde `MenzilFieldPair` döndürüyor.
  - Anahtarlar aynı kaldı: `profile-velocity-fps` (hız), `rifle-caliber` (kalibre). Satırın kendisine yeni anahtar verildi: `rifle-velocity-caliber-row`.
  - `_caliberItems` yerine `_caliberChoices` geldi. Her kalibre seçeneği için liste öğesi, kapalı kutuda gösterilecek tam yazı ve kısa yazı birlikte tutuluyor.
  - Yeni `_shortCartridge()`: uzun fişek adlarının bilinen kısa biçimini veriyor ("Weatherby" → "Wby", "Ackley Improved" → "AI", ".30-06 Springfield" → ".30-06").
  - ⓘ yazıları aynı: `ProfileFieldInfo.velocity` / `velocityFirearm`, `caliber` / `caliberFirearm`. Doğrulama da aynı: `_velocityError`, `_caliberError`, `_keepAmmoInCaliber`.
- `lib/ui/menzil_widgets.dart`
  - Yeni `MenzilFieldPair`: iki alanı her genişlikte ve her yazı boyutunda yan yana koyuyor (`Row`, iki `Expanded`, aralık `MenzilSpace.md`). Bu aralık, formun diğer iki sütunlu satırlarındaki aralıkla aynı.
  - Yeni `MenzilFitText`: yazıyı tek satırda tutuyor. Sığmazsa yalnızca gerektiği kadar küçültüyor (`FittedBox`, `BoxFit.scaleDown`), hiç taşmıyor ve "…" ile kesmiyor. Tam yazı %80'in altına küçülmek zorunda kalırsa kısa yazıyı gösteriyor. Ölçüm yerleşimden sonra yapılıyor (`MenzilWrapText` ile aynı yöntem), `LayoutBuilder` kullanılmıyor; bu yüzden diyaloglar bozulmuyor. VoiceOver her zaman tam yazıyı okuyor.
  - `MenzilSelect` üç yeni isteğe bağlı parametre aldı:
    - `fitSelected`: kapalı kutuda seçim ve "Seçiniz" için `MenzilFitText` kullanılıyor.
    - `shortSelectedLabels`: kısa yazılar.
    - `minMenuWidth`: kutu yarım genişlikte olsa da açılan liste en az bu kadar geniş. Kalibre için 260 pt veriliyor; bu, eski tam genişlikteki kutudaki liste genişliğiyle aynı. Liste ekran dışına taşmıyor, Flutter onu ekran içine kaydırıyor.

  Bu parametreleri yalnızca Kalibre kullanıyor. Başka hiçbir kutunun davranışı değişmedi.

## Satır nasıl kuruluyor

`MenzilFieldGrid` dar ekranda (genişlik < 300) veya büyük yazıda (genişlik / ölçek < 300) tek sütuna düşüyor. Sahibin isteği bu satırın her koşulda iki kutu olması olduğu için satır, ızgaranın içinde tam satır olarak (`MenzilFullWidth`) duruyor. İkiye bölme işini kendisi (`MenzilFieldPair`) yapıyor.

Normal genişlikte iki kutu, alttaki "Namlu yiv yönü | Yiv oranı" sütunlarıyla aynı hizada.

Etiket satırı ⓘ düğmesi nedeniyle her zaman 44 pt yüksekliğinde. Bu yüzden "Namlu çıkış hızı" dar kutuda iki satıra düşse bile iki kutunun giriş alanları aynı yükseklikte başlıyor. Test bunu ±1 px ile denetliyor.

## Neden

TestFlight ekranında hız ve kalibre ayrı ayrı tam satır kaplıyordu. Sahip "her satır 2 kutu" istedi. Bu iki değer tüfek başına birlikte girildiği için yan yana durmaları ekranı da kısaltıyor.

## Kenar durumları

- **Uzun kalibre adları** (".338-378 Weatherby Mag", ".300 Win Mag", "6.5 Creedmoor", ".30-06 Springfield"): Kapalı kutuda tek satır. Önce tam ad küçültülerek sığdırılıyor. Ad %80'in altına küçülecekse kısa biçim gösteriliyor (".338-378 Wby Mag", ".30-06") ve o da gerekirse küçültülüyor. Taşma yok, "…" yok. Açılan listede tam adlar ve mm değerleri aynen duruyor.
- **Model listesinden kalibre** (ör. Tikka T3x ".308 Win · 20 in namlu · 1:11"): Kapalı kutuda sığmazsa yalnızca fişek adı görünüyor. Namlu boyu ve yiv oranı listede yazılı, yiv oranı ayrıca "Yiv oranı" kutusuna doluyor.
- **"Fişeğim listede yok"**: Yarım kutuda sığmazsa "Listede yok" görünüyor. Bu seçenekte çıkan "Mermi çapı" kutusu eskisi gibi alttaki kendi tam satırında kalıyor.
- **Kayıtlı ama listede olmayan çap** ("6.12 mm (kayıtlı)"): Sığmazsa "6.12 mm" görünüyor.
- **Hiçbir şey seçilmediğinde**: "Seçiniz" de aynı şekilde sığdırılıyor.
- **Dar telefon**:
  - iPhone SE (375 pt) ve 320 pt'lik ilk SE'de de iki kutu yan yana, taşma yok.
  - 320 pt ve yazı ×1.3'te uzun fişek adı oldukça küçülüyor ama tek satırda ve okunur kalıyor.
- **Büyük yazı (×1.3)**:
  - Satır yine iki kutu.
  - "Namlu çıkış hızı" etiketi gerekirse iki satıra iniyor (inceltilerek, mevcut `MenzilWrapText` davranışı).
  - Bu ölçekte formun diğer satırları `MenzilFieldGrid` kuralı gereği eskisi gibi tek sütuna düşüyor. Yalnızca bu satır iki kutu.
- **Hata yazısı**: Hız aralık dışındaysa ("100–4900 arasında bir değer girin.") yazı sol kutunun içinde, gerekirse alt satıra kayarak görünüyor ve sağ kutuya taşmıyor. Kalibre kutusu yerinden oynamıyor.
- **Açılan liste**: Yarım kutu yüzünden liste daralmasın diye Kalibre listesi 260 pt genişliğinde kalıyor (eski hâli). İlk denemede liste kutuyla birlikte daralmıştı ve ×1.3'te mm sütunu 1–2 px taşıyordu; bu düzeltildi.

## CLAUDE.md'deki kuralın aşılması

CLAUDE.md'de "UI rule: select over typing, two boxes per row (owner, 2026-10-11)" bölümünde şu cümle var: "Kalibre and similar long single values take a full row."

Bu değişiklik, sahibin 2026-10-13 tarihli açık kararıyla bu kuralı Kalibre için aşıyor: Kalibre artık yarım genişlikte, Namlu çıkış hızının yanında. İstek üzerine CLAUDE.md değiştirilmedi. Sahip uygun görürse o cümleyi güncellemeli.

## Bilerek yapılmayanlar

- CLAUDE.md düzenlenmedi.
- Dürbün bölümüne dokunulmadı (`feat/durbun-form-sade` PR'ı değiştiriyor).
- Kimlik "Üretim" kutusuna dokunulmadı (`fix/uretim-duzenle` PR'ı).
- Marka ve Model satırları değişmedi.
- Formun diğer satırlarının dar ekranda / büyük yazıda tek sütuna düşme kuralı (`MenzilFieldGrid`) değiştirilmedi. "Her satır 2 kutu" isteği bu PR'da yalnızca hız | kalibre satırı için uygulandı. Formun tamamı için istenirse ayrı bir iş.
- Kalibre için yeni bir hata yazısı eklenmedi. Doğrulama eskisi gibi "Kaydetmek için eksik" listesinden yapılıyor.
- Merge, TestFlight, iOS Simulator ve integration_test çalıştırılmadı.

## Testler

- Yeni `test/velocity_caliber_row_test.dart`:
  - PCP (Hatsan Hercules, "11.43 mm (.45)") ve Ateşli Tüfek (".338-378 Weatherby Mag") için 430 pt, 375 pt (iPhone SE) ve 320 pt genişliklerde, yazı ×1.0 ve ×1.3 ile çalışıyor.
  - Hız ve kalibrenin aynı satırda olduğunu denetliyor: üst kenar ±1 px, `hız.right < kalibre.left`, eşit genişlik. Giriş kutularının aynı yükseklikte başladığını ve Marka/Model'in tam satırda kaldığını da denetliyor.
  - Kapalı kutudaki kalibre yazısının tek satır olduğunu, "…" ile kesilmediğini, kutunun içinde kaldığını ve kısa yazının yalnızca gerekince kullanıldığını denetliyor.
  - Hız hata yazısının sol kutuda kaldığını denetliyor.
  - "Fişeğim listede yok" + Mermi çapı akışını denetliyor.
  - Hiçbir durumda taşma (RenderFlex overflow) olmadığını denetliyor.
  - Not: test yazı tipi her harfi 1 em genişliğinde çiziyor, iPhone yazı tipinden çok daha geniş. Bu yüzden testteki küçültme en kötü durum. Testte yazı boyutu için alt sınır denetlenmiyor.
- `test/profile_lists_test.dart`: eski "hız kalibrenin üstünde" denetimi "aynı satırda, hız solda" olarak güncellendi (PCP ve fabrika fişeği testleri).
- `test/profile_editor_fail_closed_test.dart`: ".30-06 Springfield" seçildikten sonra kapalı kutuda tam ad ya da ".30-06" kabul ediliyor (390 pt'de test yazı tipiyle kısa biçim çıkıyor).
- `integration_test/app_launch_test.dart`, `sim_screens_test.dart` ve `sim_screens_paralaks_mpbr_test.dart`:
  - Bu dosyalar alanları `rifle-caliber` ve `profile-velocity-fps` anahtarlarıyla buluyor. Anahtarlar değişmediği için alanları hâlâ bulmaları gerekir. Kalibre listesinde seçimi `find.text(...).last` ile yapıyorlar; bu da açık listedeki öğeyi seçiyor.
  - Bu testler simülatör gerektirdiği için bu çalışmada koşturulmadı.

## Doğrulama

Yerel (bulut oturumu, Flutter SDK indirilemedi: storage.googleapis.com proxy 403):

- `python3 tools/offline_dart_lint.py` → PASS (310 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 724 test OK
- `tools/claude_flutter_verify.sh` → BLOCKED (sabitlenmiş Flutter SDK bu ortamda kurulamadı)

CI (GitHub Actions, `fix/hiz-kalibre-yanyana` dalı):

- Format (dart format, commit'i çekildi):
  - https://github.com/sniperTurk/flutter-app/actions/runs/38432249191 (başarılı)
  - https://github.com/sniperTurk/flutter-app/actions/runs/38435207982 (başarılı)
  - https://github.com/sniperTurk/flutter-app/actions/runs/38437141136 (başarılı, değişiklik yok)
- Analyze (`--fatal-infos --fatal-warnings`):
  - https://github.com/sniperTurk/flutter-app/actions/runs/38432633097 (başarılı)
  - https://github.com/sniperTurk/flutter-app/actions/runs/38435438694 (başarılı)
  - https://github.com/sniperTurk/flutter-app/actions/runs/38437393939 (başarılı, son kod commit'i `ba0a64e`)
- Test (`flutter test test`):
  - https://github.com/sniperTurk/flutter-app/actions/runs/38432630236 (başarısız: testteki `RenderParagraph` araması ve fail-closed testindeki tam ad beklentisi; düzeltildi)
  - https://github.com/sniperTurk/flutter-app/actions/runs/38435434885 (başarısız: yarım kutuda liste daralıp ×1.3'te 1–2 px taşma ve uzun listede son öğeye kaydırma; düzeltildi)
  - https://github.com/sniperTurk/flutter-app/actions/runs/38437390561 (başarılı: tüm `test/` klasörü, son kod commit'i `ba0a64e`)
- Bu raporu ekleyen commit yalnızca `docs/` değiştiriyor; kodda değişiklik yok.
- iOS CI / Simulator / TestFlight: çalıştırılmadı.

---
_Generated by [Claude Code](https://claude.ai/code)_
