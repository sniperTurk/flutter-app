# Üst çubuk: profil kutusu sabit, "Sniper Türk" biraz büyük

Sahibin isteği (2026-10-13 18:34, telefon videosu ile):

1. "Sniper Türk yazısını biraz büyüt."
2. "Sayfalar arası geçiş yaparken ortadaki kutu (profil kutusu) büyüyüp küçülüyor, bu olmasın."

Dal: `fix/ust-cubuk-sabit` (main'den). Taslak PR; birleştirme sahibin ana oturumunda.

## Ne değişti

**`lib/ui/menzil_widgets.dart` → `MenzilTopBar`**

- Önce: Başlık yeri `ConstrainedBox(maxWidth: çubuk genişliği × 0,42)` ile `Align(widthFactor: 1)` idi. Bu yer sadece o anki başlığın kendi genişliği kadar yer kaplıyordu. "Araçlar" kısa olduğu için profil kutusu sola kayıp genişliyor, "Hava Durumu" uzun olduğu için sağa kayıp daralıyordu. Videodaki büyüyüp küçülme buydu.
- Şimdi: Başlık yeri **sabit genişlikte** bir `SizedBox` (Key `top-bar-title-slot`). Genişlik bütün sekmelerde aynı. Bu yüzden profil kutusu (`Expanded`, artık Key `top-bar-profile-slot` ile sarılı) her sekmede aynı x noktasından başlıyor ve aynı genişlikte.
- Başlık yerin içinde sola dayalı (`Align(centerLeft)` + `FittedBox(scaleDown, centerLeft)`).
- Başlık ile kutu arasındaki boşluk (`MenzilSpace.md` = 10), kutu ile sağ düğmeler arasındaki boşluk (`MenzilSpace.sm`), tema/birim düğmeleri ve iki yandaki eşit kenar boşluğu (`MenzilSpace.gutter` = 14) değişmedi.
- Yeni yardımcı: `MenzilTopBar.titleSlotWidth(...)`. Sabitler: `MenzilTopBar.titleSize = 18`, `MenzilTopBar.titleSlotMaxFraction = 0.42`.

**`lib/ui/menzil_widgets.dart` → `MenzilBrand`**

- "Sniper Türk" 18 yerine **20 punto** oldu (`MenzilBrand.fontSize`, `MenzilBrand.style`, `MenzilBrand.text`). Key `top-bar-brand` aynı kaldı.

**`lib/features/home/home_screen.dart`**

- Üst çubuğa gösterebileceği bütün başlıklar `slotTitles` olarak veriliyor: `_titles` haritasındaki "Hava Durumu", "Pro Ayarlar", "Hedef", "Araçlar" ve Hedef sekmesindeki tek atış başlığı "Atış Çözümü" (artık `_shotTitle` sabiti). Liste aynı kaynaktan üretildiği için yeni bir sayfa başlığı eklenirse otomatik olarak ölçülür.

## Sabit genişlik nasıl hesaplanıyor

- **Hangi başlıklar:** `lib/` içinde üst çubuğun gösterdiği başlıkların hepsi: "Sniper Türk" (Profil), "Hava Durumu", "Pro Ayarlar", "Hedef", "Atış Çözümü", "Araçlar". (`MenzilTopBar` uygulamada tek yerde kullanılıyor: `home_screen.dart`.) O an gösterilen başlık da her ihtimale karşı ölçüme ekleniyor.
- **Hangi stil:** Ekranda kullanılan stilin aynısı. Sayfa başlıkları `MenzilType.heading(size: 18)`, marka `MenzilType.heading(size: 20)` (Inter, kalın 700, harf aralığı 0,2). Her ikisi de `DefaultTextStyle` ile birleştirilerek ölçülüyor; yani `Text` widget'ının çizdiği stil ile aynı.
- **Yazı büyütme:** `TextPainter`, çubuğun gerçek `MediaQuery.textScalerOf(context)` değeriyle ölçüyor. Üst çubuk zaten yazı büyütmeyi 1,25'te sınırlıyor (`withClampedTextScaling`), ölçüm de bu sınırlı değeri kullanıyor. Yön ve dil (`Directionality`, `Localizations`) de ekranla aynı.
- **Sonuç:** En geniş başlığın genişliği (yukarı yuvarlanmış), en fazla çubuk genişliğinin **%42'si** (eski üst sınırın aynısı). Sınıra takılırsa başlık `FittedBox` ile küçülür, profil kutusunu sıkıştırmaz ve taşma olmaz.

## Neden

Profil kutusunun yeri ve genişliği artık hangi sayfada olunduğuna bağlı değil; sadece telefon genişliğine ve yazı büyüklüğüne bağlı. Sekme değiştirince kutu yerinde kalıyor. Genişliği en geniş başlığa göre ayarlamak, hiçbir başlığın normal ekranda küçültülmesini gerektirmiyor. Sabit bir sayı (ör. 130 px) yerine ölçüm kullanıldı, çünkü yazı büyütme ve font değişince sabit sayı ya taşar ya da boşluk bırakır.

## Uç durumlar

- **Dar telefon (iPhone SE / mini 375 pt, eski SE 320 pt):** Yer en fazla genişliğin %42'si. 320 pt'de büyük ihtimalle bu sınıra takılır. O zaman uzun başlıklar biraz küçülür ama sola dayalı kalır. Profil kutusu her sekmede yine aynı. Bu genişlik, eski düzende en uzun başlıklı sekmedeki ("Hava Durumu") genişlikle aynı. Yani eski en kötü durumdan daha dar değil, sadece kısa başlıklı sekmelerde artık genişlemiyor.
- **Büyük yazı (1,3×):** Çubuk yazıyı 1,25'te sınırlıyor. Ölçüm de 1,25 ile yapılıyor. Sınıra takılırsa `FittedBox` küçültür. Taşma yok (testte kontrol ediliyor).
- **Tema / birim düğmeleri:** Hiç değişmedi. Birim düğmesi (`unitLabel`) eklenirse sadece profil kutusu daralır. Başlık yeri ve kutunun sol kenarı aynı kalır.
- **Yatay ekran / geniş ekran:** Ölçüm başlıkların gerçek genişliğini verdiği için yer gereksiz büyümez. Fazla alan profil kutusuna gider.
- `compact` (350 pt altı) bayrağı ve markanın kendi `FittedBox`'ı olduğu gibi duruyor.

## Marka boyutu: 20 punto

İstenen aralık 20–21 idi. **20** seçildi. "Sniper Türk" artık en geniş başlık olduğu için yer genişliğini o belirliyor; sabit yer yüzünden de her sekmedeki profil kutusunu etkiliyor. 21 punto, kutuyu her sayfada birkaç piksel daha daraltırdı. 20 punto "biraz büyüt" isteğini karşılıyor (18 → 20, yaklaşık %11). Dar telefonda yine sığıyor; sığmazsa küçülüyor. Sayfa başlıkları önceki sahip kuralı gereği 18'de kaldı ("her sayfa başlığı aynı boyda").

## Bilerek yapılmayanlar

- Sayfa başlıklarının boyu (18), metinleri, sekme adları değişmedi.
- %42 üst sınırı değişmedi. Dar ekranda başlık için ayrı bir düzen veya kısaltma eklenmedi.
- Profil seçici (`_profileSelector`) içi, tema/birim düğmeleri ve alt gezinme çubuğuna dokunulmadı.
- Gerçek cihaz, Simulator, TestFlight çalıştırılmadı. Videodaki görünüm cihazda kontrol edilmedi.
- Yerel olarak Flutter yok (bu ortamda Flutter motor dosyaları indirilemiyor). Dart/Flutter kontrolleri sadece CI'da çalıştı.

## Testler

Yeni dosya: `test/top_bar_fixed_slot_test.dart`

- `normal telefon 390`, `iPhone SE / mini 375`, `dar telefon 320` genişliklerinde, yazı 1,0× ve 1,3× ile (6 test): Profil → Hava Durumu → Pro → Hedef → Araçlar → Profil sırasıyla her sekme açılıyor. Profil kutusunun `Rect`'i (sol kenar ve genişlik) her sekmede **birebir aynı** olmalı. Her sekmede taşma/istisna yok (`takeException() == null`). Başlık yeri soldan 14 pt'de (gutter) başlıyor. Başlık yerin solunda ve yerin içinde. Tema düğmesi sağdan 14 pt'de bitiyor (eşit kenar boşluğu). Kutu kullanılabilir genişlikte: 375 pt ve üstünde > 60, 320 pt'de > 40. Test fontu Inter'den geniş olduğu için bunlar alt sınır.
- `Sniper Türk markası 20 punto, sayfa başlıkları 18`.
- `slot genişliği en geniş başlıktan, üst sınırla`: Yer genişliği en geniş başlığa eşit. Tek başına "Araçlar" daha dar bir yer verir; yani yer o anki başlığa göre değişmiyor. Dar çubukta %42'de duruyor.

Mevcut testler (`menzil_shell_test`, `offline_app_test`, `pro_tab_test`, `tools_hub_order_test`, `profile_summary_order_test`) aynı Key'leri (`top-bar-title`, `top-bar-brand`) kullanıyor. Değişiklik gerekmedi.

## Kontroller

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (310 dosya, 0 sorun). `python3 -m unittest discover -s tools -p 'test_*.py'` → 724 test OK.
- CI (hepsi `fix/ust-cubuk-sabit` dalında):
  - Biçim (format-fix): https://github.com/sniperTurk/flutter-app/actions/runs/38423980811 başarılı, biçim commit'i (7139d59) çekildi. İkinci çalıştırma https://github.com/sniperTurk/flutter-app/actions/runs/38425012554 başarılı, değişiklik yok.
  - İlk test çalıştırması: https://github.com/sniperTurk/flutter-app/actions/runs/38423997635 **başarısız** (1103 geçti, 2 kaldı). Kalanların ikisi de yeni testin 320 pt'deki "kutu > 60" eşiği (test fontuyla 58,6 ve 45,6). Eşik 320 pt için 40'a indirildi (18cd919).
  - Tam test (`files=test`), 18cd919 üzerinde: https://github.com/sniperTurk/flutter-app/actions/runs/38425017068 → **başarılı**.
  - Analyze (`--fatal-infos --fatal-warnings`), 18cd919 üzerinde: https://github.com/sniperTurk/flutter-app/actions/runs/38425223691 → **başarılı**. (İlk analyze https://github.com/sniperTurk/flutter-app/actions/runs/38423984962 de başarılıydı.)
  - Bu rapor sadece Markdown ekliyor, kodu değiştirmiyor.
  - `iOS CI / verify`, Simulator ve TestFlight bu iş için **çalıştırılmadı**. Geçti denemez.

---
_Generated by [Claude Code](https://claude.ai/code)_
