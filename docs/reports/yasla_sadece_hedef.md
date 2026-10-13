# Yazı hizalama: her yerde sola yaslı, yalnız Hedef sayfası iki yana yaslı

Sahip kararı (2026-10-13 20:25): "İki yana yaslamayı kaldır, çünkü artık
açıklamaları popup içine aldık; sadece Hedef sayfasında sağa sola yaslı olsun
yazılar."

Neden: simülatör ekran görüntüsünde Profil özetindeki değerler (ör.
"Element Optics Titan 5-25 × 56 FFP · MOA") iki satıra kayıyor ve kelimeler
arasında büyük boşluklar açılıyordu. Sebep, sayfa genelindeki "iki yana yasla"
varsayılanının değerlere de uygulanmasıydı.

## Değişen yerler

| Dosya / satır (yeni) | Önce | Sonra |
|---|---|---|
| `lib/ui/menzil_widgets.dart` 22-27, 38 | `MenzilPage` parametresi yoktu | Yeni `justify` parametresi (varsayılan `false`) |
| `lib/ui/menzil_widgets.dart` 51-54 | Sayfa geneli `DefaultTextStyle.merge(textAlign: TextAlign.justify)` | `textAlign: justify ? TextAlign.justify : TextAlign.start` (yani varsayılan sola yaslı) |
| `lib/ui/menzil_widgets.dart` 691-693 (`MenzilNotice` mesajı) | `TextAlign.justify` | `TextAlign.start` |
| `lib/ui/menzil_widgets.dart` 840-841, 847 (`MenzilInfoButton` ⓘ popup metni, resimli ve resimsiz) | `TextAlign.justify` | `TextAlign.start` |
| `lib/features/profiles/profiles_screen.dart` 252 ("Yedek geri yüklensin mi?" penceresi) | `TextAlign.justify` | `TextAlign.start` |
| `lib/features/home/empty_states.dart` 282-284 (Pro önizleme açıklaması) | `TextAlign.justify` | `TextAlign.start` |
| `lib/features/ballistics/ballistics_screen.dart` 3771-3773 (`_explain`, Pro açıklamaları) | `TextAlign.justify` | `TextAlign.start` |
| `lib/features/guide/usage_guide_screen.dart` 48-50 (Kullanım kılavuzu paragrafları) | `TextAlign.justify` | `TextAlign.start` |
| `lib/features/ballistics/ballistics_screen.dart` 2881-2882 (Atış Çözümü sayfası) | Sayfa varsayılanından iki yana yaslı | `MenzilPage(justify: true)` — değişmedi, artık açıkça istendi |
| `lib/features/ballistics/ballistics_screen.dart` 2888-2889 (Hedef sekmesinin DOPE modu) | Sayfa varsayılanından iki yana yaslı | `MenzilPage(justify: true)` |
| `lib/features/home/home_screen.dart` 570-571 (profil yokken Hedef önizlemesi) | Sayfa varsayılanından iki yana yaslı | `MenzilPage(justify: shot)` — yalnız Hedef önizlemesi yaslı, Pro önizlemesi sola yaslı |
| `lib/features/ballistics/scope_dial_view.dart` 779, 848-850 | `TextAlign.justify`, yorum "owner 2026-10-11" | `TextAlign.justify` kaldı; yorum yeni kurala göre güncellendi |

Eski kuralı (sahip 2026-10-11/12, "her paragraf iki yana yaslı") anan tüm
kod yorumları yeni kurala (sahip 2026-10-13: yalnız Hedef) çevrildi.
`CLAUDE.md` değiştirilmedi.

## Hedef sayfası yaslı kalmayı nasıl sürdürüyor

1. Dürbün altındaki açıklama paragrafı ("Kırmızı sayılar: …") ve "Hesap
   dökümü" satırları `scope_dial_view.dart` içinde zaten açıkça
   `TextAlign.justify` taşıyor; bunlar olduğu gibi kaldı.
2. Hedef sayfası, sayfa varsayılanına dayanan diğer paragraflar için kendi
   iki yana yaslı varsayılanını alıyor: `MenzilPage(justify: true)`. Bu,
   Atış Çözümü (`BallisticsView.shot`), Hedef sekmesinin DOPE modu
   (`BallisticsView.table`, üst çubukta da "Hedef" yazan mod) ve profil
   yokken gösterilen Hedef önizlemesi için verildi. Böylece Hedef sekmesinde
   önceki görünüm aynen korunuyor.

## Uç durumlar

- Tek satırlık etiketler, düğmeler ve değerler hizalamadan etkilenmez; iki
  yana yaslama yalnız kırılan çok satırlı metinde boşluk açar, son satır her
  zaman sola yaslıdır.
- `Material` içeren kartlar (ör. kılavuz kartı) sayfanın `DefaultTextStyle`
  hizasını sıfırlar; bu yüzden açık `textAlign` verilen yerler açıkça
  `TextAlign.start` yapıldı, sadece varsayılanı kaldırmakla yetinilmedi.
- `MenzilNotice` uyarıları Hedef sayfasında görünse bile artık sola yaslı
  (açık `TextAlign.start`). Talimat buna izin veriyordu ("kalabilir");
  uyarı kutusu sayfa paragrafı değil, popuplarla aynı görünsün diye bu tercih
  edildi. Hedef'teki uyarıların da yaslı olması istenirse tek satırlık bir
  değişiklikle yapılabilir.
- ⓘ popuplar Hedef sayfasından açılsa bile sola yaslı (popuplar yaslanmaz).
- Sağdan sola dillerde `TextAlign.start` doğru tarafa yaslar (`left` yerine
  `start` bu yüzden seçildi).

## Bilerek değiştirilmeyenler

- Ortalı metinler (`TextAlign.center`: boş durum mesajları, düğme altı
  yazıları vb.) dokunulmadı.
- Hedef sayfasındaki iki açık `TextAlign.justify` (scope_dial_view.dart 779
  ve 850) korundu.
- Hiçbir renk, boyut, aralık veya başka görsel ayar değişmedi.
- `CLAUDE.md` değişmedi.

## PR fix/pro-aciklama-popup ile olası çakışma

O PR Pro açıklamalarını (`ballistics_screen.dart` `_explain`, ayrıca
`empty_states.dart` Pro önizlemesi) popup içine taşıyor. Bu PR aynı satırlarda
`TextAlign.justify` → `TextAlign.start` ve yorum değişikliği yapıyor; hangisi
önce birleşirse diğerinde bu satırlarda metin çakışması çıkabilir. Çözüm:
popup gövdesi de sola yaslı olmalı. Popup `MenzilInfoButton` kullanıyorsa bu
PR ile zaten `TextAlign.start` olur; kendi `AlertDialog`'unu kuruyorsa gövde
metnine `textAlign: TextAlign.start` verilmeli (ya da hiç `justify`
verilmemeli).

## Testler

- Yeni: `test/yasla_sadece_hedef_test.dart`
  - Profil özetindeki (Dürbün kartı, `profile-summary-scope`) tüm değer
    metinleri ekrana `TextAlign.start` ile çiziliyor; Profil sayfasının
    `MenzilPage.justify` değeri `false`.
  - Hedef (Atış Çözümü) sayfasının `MenzilPage.justify` değeri `true`;
    "Kırmızı sayılar" paragrafı ve "Hesap dökümü" satırları `justify`.
  - `MenzilNotice` mesajı normal sayfada da yaslı sayfada da `start`.
  - `MenzilPage` varsayılanı `start`, `justify: true` ile `justify`.
  - ⓘ popup metni (resimli ve resimsiz) `start`, yaslı bir sayfadan açılsa
    bile.
- Güncellendi: `test/usage_guide_test.dart` — uzun paragraflar artık
  `TextAlign.start` bekleniyor.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (310 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` → 724 test OK.
  Bu ortamda Flutter SDK yok; `flutter test`/`analyze` yalnız CI'da çalıştı.

## CI çalıştırmaları

Hepsi `fix/yasla-sadece-hedef` dalının `afe6102` commit'i üzerinde çalıştı
(bu raporu ekleyen sonraki commit yalnız Markdown içerir).

- Format (`format-fix.yml`, 375209577): başarılı, biçim değişikliği gerekmedi,
  dala commit itilmedi —
  https://github.com/sniperTurk/flutter-app/actions/runs/38439055213
- Analyze (`analyze-diag.yml`, `--fatal-infos --fatal-warnings`): başarılı,
  0 bulgu — https://github.com/sniperTurk/flutter-app/actions/runs/38439058707
- Testler (`test-diag.yml`, `files=test`, tüm test klasörü): başarılı (çıkış
  kodu 0). Aynı saniyelerde başka bir oturum da aynı iş akışını tetiklediği
  için koşu numarası kesin eşleştirilemedi; benimki şu ikisinden biri ve
  ikisi de yeşil:
  https://github.com/sniperTurk/flutter-app/actions/runs/38439557183 ,
  https://github.com/sniperTurk/flutter-app/actions/runs/38439566450
- iOS CI / Simulator / cihaz / TestFlight: çalıştırılmadı (istenmedi).

---
_Generated by [Claude Code](https://claude.ai/code)_
