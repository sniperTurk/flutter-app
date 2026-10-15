# Açılan liste kutu genişliğinde (MenzilSelect)

Sahip bildirimi (2026-10-13 19:29, TestFlight, Profil Oluştur > Dürbün >
Vector Optics > Model): açılan liste kutudan dar (kutunun yaklaşık 2/3'ü,
sola yaslı), uzun satırlar çok küçük yazılıyor. İstek: "daha büyük açılsın
ama kutudan dışarı çıkmasın".

## Liste neden dardı (kesin sebep)

Uygulamadaki bütün liste kutuları tek bir bileşenden gelir:
`MenzilSelect` (`lib/ui/menzil_widgets.dart`). İçinde Flutter'ın
`DropdownButton`'ı var. Üç şey üst üste geliyordu:

1. **260 pt sınırı.** `menuWidth: math.min(_boxWidth!, 260)` yazılıydı
   (2026-10-11'deki "sağa sola çok açılıyor" şikâyeti için). Telefonda tam
   genişlikteki kutu yaklaşık 358 pt; liste 260 pt'de kalıyordu, yani
   kutunun yaklaşık %73'ü. Ekran görüntüsündeki "2/3" budur.
2. **Sola kayma.** Flutter, hizalanmamış (`alignedDropdown: false`) listede
   düğmenin dikdörtgenini solda 16 pt, sağda 24 pt genişletip listeyi
   bunun sol kenarına koyar. Liste bu yüzden kutunun sol kenarından
   yaklaşık 12 pt dışarıda başlıyordu (ekranın kenarına dayanınca orada
   kesiliyordu).
3. **Çerçeve boşluğu.** Temadaki `OutlineInputBorder`'ın `gapPadding`
   değeri (4 pt) Material 3'te içeriğin iki yanında boşluk bırakıyor;
   düğme kutudan her iki yanda 4 pt dardı. Liste düğmeye göre
   konumlandığı için bu da kenarları kaydırıyordu.

Liste 260 pt'ye sabitlenince satırın içindeki yazı alanı 260 − 32 = 228
pt kalıyordu. Dürbün model satırları `FittedBox` ile tek satıra
sığdırıldığından, uzun satır bu dar alana sığmak için çok küçülüyordu.

## Ne değişti

Yalnızca `lib/ui/menzil_widgets.dart` içindeki `MenzilSelect`
değişti. Bütün liste kutuları (Marka, Model, Kalibre ve diğer bütün
`MenzilSelect`'ler) bu değişiklikten yararlanır.
`profiles_screen.dart` dosyasına hiç dokunulmadı.

- `menuWidth` (260 pt sınırı) ve kutu genişliğini kare sonrası ölçen
  `_boxWidth` / `_measure` kaldırıldı.
- `DropdownButton`, `ButtonTheme(alignedDropdown: true)` içine alındı.
  Hizalı modda Flutter listeyi düğmenin kendi dikdörtgenine koyar
  (ek kenar boşluğu yok). `menuWidth` verilmeyince liste genişliği,
  düğmenin genişliğine eşit olur.
- Kutunun `InputDecoration`'ında bütün çerçeveler (`border`,
  `enabledBorder`, `focusedBorder`, `errorBorder`,
  `focusedErrorBorder`, `disabledBorder`) temadan alınıp
  `gapPadding: 0` ile kullanılıyor (`_noGap`). Böylece düğme kutunun tam
  sol ve sağ kenarına kadar uzanır. Çizgi, renk ve köşe yarıçapı aynı
  kaldı; bu kutularda yüzen etiket olmadığı için boşluğun görünür bir
  işlevi yoktu.
- Hizalı mod, düğmenin içinde yazıdan önce 16 pt, oktan sonra 4 pt boşluk
  ekler. Bunu dengelemek için düğmenin kendi boşluğu sol 0, sağ 12 yapıldı
  (önceden iki yanda 12'ydi, üstüne çerçevenin 4 pt'si ekleniyordu).
  Böylece kapalı kutuda yazı yine kutunun 16 pt içinden başlar, ok yine
  sağ kenardan 16 pt içeride biter. Yazı için kalan alan da öncekiyle
  aynıdır.

## Genişlik nasıl belirleniyor

Ölçüm veya sabit sayı kullanılmıyor. Liste açılırken Flutter düğmenin
ekrandaki dikdörtgenini alır. Düğme artık kutunun tam kenarlarında
olduğu için, liste kutunun sol kenarında başlar ve genişliği kutununkine
eşit olur. Liste kutudan hiçbir zaman geniş değildir.

## Uç durumlar

- **Yarım genişlikteki kutular (iki kutu yan yana):** Her liste kendi
  kutusunun genişliğinde açılır (yaklaşık 173 pt). Sağdaki kutunun
  listesi sağdaki kutunun altında açılır, soldakininki soldakinin.
- **Çok uzun satırlar:** Kapalı kutu yine tek satırdır ve sonu "…" ile
  kesilir. Açık listede `FittedBox` kullanan satırlar (dürbün model
  satırı) tek satırda kalır. Yazı ancak tam kutu genişliğine sığmazsa
  küçülür. Tam genişlikteki kutuda yazı alanı 228 pt'den yaklaşık
  326 pt'ye çıktı (yaklaşık %43 daha geniş). `FittedBox` kullanmayan
  satırlar eskisi gibi kırılır, artık daha geniş alanda.
- **Büyük yazı (erişilebilirlik):** Liste yine kutunun kenarlarında
  kalır. Bu durum testte 1,6 kat yazı boyutuyla denendi.
- **Ekran kenarına yakın menüler:** Kutu ekranın içinde olduğu için liste
  de içinde kalır. Önceki sürümde liste kutunun 12 pt solundan
  başlıyordu; ekranın sol kenarına yakın kutularda Flutter onu ekrana
  geri itiyordu. Bu kayma artık yok. Sağdan sola yazı yönünde de Flutter
  listeyi düğmenin sağ kenarına göre koyar, sonuç yine kutunun
  kenarlarıdır.
- **"Seçiniz" ilk satırı, açılış yönü:** Değişmedi. Liste hâlâ aşağıya
  doğru ve ilk satırından başlayarak açılır (`value: null`). En fazla
  300 pt yüksekliktedir. "Seçiniz" listenin ilk satırıdır.
- **Klavye ve ekran okuyucu:** Anlamsal etiket (`Semantics label`),
  odak ve dokunma alanı aynı. Bütün kutu yine listeyi açar. Okunan metin
  değişmedi.

## Bilerek yapılmayanlar

- `DropdownMenu` (M3) bileşenine geçilmedi. Bu geçiş arama alanı, yazı
  girişi ve odak davranışını değiştirirdi. Değişiklik en küçük tutuldu.
- `profiles_screen.dart` (dürbün formu, `_scopeModelLine`) değişmedi.
  Açık PR `feat/durbun-form-sade` ile çakışma olmaz.
- Liste satırlarının yazı boyutu (15 pt), iç boşluğu (16 pt) ve en
  yüksekliği (300 pt) değişmedi.
- Kapalı kutunun görünümü değiştirilmedi.

## Test

`test/select_menu_width_test.dart` (yeni):

- Tam genişlikteki kutu: açık listenin sol ve sağ kenarı kutununkiyle
  aynı (±1 px), kutudan dışarı taşmıyor. İlk satır "Seçiniz". Uzun dürbün
  satırı eski 260 pt'lik listedekinden daha az küçülüyor. Kısa satır
  normal boyutta.
- Yan yana iki yarım kutu: her listenin kenarları kendi kutusununkiyle
  aynı.
- Büyük yazı (1,6 kat): üç listenin de kenarları kutularıyla aynı.
- Kapalı kutu: yazı kutunun 16 pt içinden başlıyor, ok kenardan 16 pt
  içeride bitiyor (eskisiyle aynı). Seçim yapılınca seçilen değer de aynı
  yerde gösteriliyor.

## Yerel kontroller

- `python3 tools/offline_dart_lint.py` → PASS (310 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 724 test, OK
- Bu ortamda Flutter SDK kurulamadı (motor indirmesi engellendi). Bu
  yüzden `tools/claude_flutter_verify.sh` burada çalıştırılmadı;
  Flutter kontrolleri aşağıdaki CI koşularında yapıldı.

## CI koşuları

- Format (one-off dart format fix): [run 38433635282](https://github.com/sniperTurk/flutter-app/actions/runs/38433635282) → başarılı, `4a38bda` biçim commit'ini itti
- Test, yalnızca yeni test (`1f9b804`): [run 38433638584](https://github.com/sniperTurk/flutter-app/actions/runs/38433638584) → başarılı
- Son kod commit'i `c678a76` (bu raporun ilk hali dahil):
  - Format: [run 38434866146](https://github.com/sniperTurk/flutter-app/actions/runs/38434866146) → başarılı, değişiklik gerekmedi (312 dosya, 0 değişti)
  - Analiz (`flutter analyze --fatal-infos --fatal-warnings`): [run 38434874836](https://github.com/sniperTurk/flutter-app/actions/runs/38434874836) → başarılı, sorun yok
  - Bütün test paketi (`flutter test test`): [run 38434870802](https://github.com/sniperTurk/flutter-app/actions/runs/38434870802) → başarılı
- Bu koşulardan sonraki tek commit yalnızca bu rapora CI bağlantılarını
  ekler; kod değişmedi.

iOS CI, Simulator, cihaz, TestFlight: çalıştırılmadı.

---
_Generated by [Claude Code](https://claude.ai/code)_
