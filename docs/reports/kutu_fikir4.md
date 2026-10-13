# Kutu "Fikir 4": Hava Durumu ve Pro Ayarlar'da küçük kutular

İstek (sahip, 2026-10-13 20:00–20:03, "Fikir 4"): Hava Durumu ve Pro Ayarlar sayfalarında kutular çok büyük görünüyor, etiket ile kutu arasında çok boşluk var. Yalnız bu iki sayfa değişecek; Profil (Profil Oluştur/Düzenle), Hedef ve Araçlar bugünkü gibi kalacak.

Başlama koşulu: fix/ruzgar-rehber (#272), fix/pro-aciklama-popup (#274) ve fix/liste-genislik (#273) PR'ları main'e birleşmişti (`merged_at` dolu). İş başladıktan sonra main'e #275, #278 ve #279 da girdi; dal bunlarla birleştirildi (çakışma yalnız `lib/ui/menzil_widgets.dart` içindeydi, iki taraf da korundu).

## Ne değişti

- `lib/ui/menzil_widgets.dart`
  - Yeni `MenzilCompactFields` (InheritedWidget). Altındaki `MenzilInput` ve `MenzilSelect` "kompakt" görünüme geçer.
  - `MenzilInput` ve `MenzilSelect`'e isteğe bağlı `compact` parametresi eklendi. Boş bırakılırsa (varsayılan) üstteki `MenzilCompactFields`'a bakar; yoksa eski görünüm.
  - Kompakt görünümde:
    - Etiket kutunun üstünde, küçük yazı (12,5 pt), etiket ile kutu arası 5 pt. 44 pt'lik etiket satırı ve görünmez yer tutucu ⓘ yok.
    - Etiket tek satır. Sığmazsa kesilmez, gerektiği kadar küçülür. Etiket yuvasının yüksekliği sabit kalır, bu yüzden yan yana iki kutu her zaman aynı hizada başlar.
    - Birim (°C, %, hPa, m, m/s, saat, …) kutunun içinde, değerin sağında.
    - ⓘ kutunun içinde, sağ kenarda. Dokunma alanı 44 × 44 pt (kutu yüksekliği kadar). Bugünkü açıklamayı açar: Hava Durumu'nda popup, Pro kutularında #279 ile gelen alttan açılan sayfa. Alana odaklanmaz, klavye açılmaz.
    - Liste kutusunda (`MenzilSelect`) ⓘ ok işaretinin solunda durur. ⓘ'ye dokunmak listeyi açmaz; kutunun geri kalanı ve ok listeyi açmaya devam eder.
    - Kutu yüksekliği 44 pt. Hata yazısı yine kutunun altında.
- `lib/ui/menzil_theme.dart`: `MenzilSpace.compactControl = 44` ve `MenzilSpace.compactLabelGap = 5` eklendi. `MenzilSpace.control = 46` değişmedi.
- `lib/features/ballistics/ballistics_screen.dart`
  - Hava Durumu sayfası (profilli `BallisticsView.environment` ve profilsiz Hava Durumu) ile Pro Ayarlar sayfası (`BallisticsView.pro`) `MenzilCompactFields` ile sarıldı.
  - Turuncu "tamam" düğme yazıları kısaldı: "Konumdan canlı hava verisi alındı" → "Hava verisi alındı", "Basınç telefondan alındı" → "Basınç alındı". Bu iki yazı tek satır (`maxLabelLines: 1`). Boşta görünen yazılar ("Konumdan canlı hava verisi al", "Tekrar canlı konum verisi al", "Basıncı telefondan al") değişmedi.
  - "Basınç telefondan alındı: 912,4 hPa." bildirim yazısı değişmedi. Bu bir düğme değil, durum bildirimi.
- Testler: yeni `test/kutu_fikir4_test.dart`. `test/fetch_reset_buttons_test.dart` yeni düğme yazılarına göre güncellendi.

## Sadece Hava Durumu ve Pro'da olması nasıl sağlandı

- Ortak bileşenlerin varsayılanı değişmedi. Kompakt görünüm yalnız `MenzilCompactFields` altında ya da `compact: true` verilince açılır.
- `MenzilCompactFields` yalnız üç yerde var: profilli Hava Durumu, profilsiz Hava Durumu ve Pro Ayarlar sayfasının gövdesi.
- Profil, Hedef, Araçlar ve tam "Balistik / DOPE" ekranı bu kapsamın dışında; bugünkü gibi kalırlar.
- Pro'dan açılan pencereler (ör. mesafe/açı girişi) kendi sayfalarında açılır. InheritedWidget oraya geçmediği için onlar da eski görünümde kalır.
- Regresyon testi: Profil formundaki "Tüp basıncı" kutusu ve "Tür" liste kutusu eski düzende kalmalı (aşağıdaki "Hangi test kapsıyor" bölümüne bakın).

## Ölçümler (pt)

Flutter test motorunda ölçüldü (aynı tema, yazı ölçeği 1,0, "Sıcaklık °C ⓘ" kutusu). Test motoru kendi test yazı tipini kullanır. iPhone'daki San Francisco ile değerler bir iki pt farklı olabilir, ama oranlar aynıdır.

| | Önce (Profil'de hâlâ böyle) | Sonra (Hava Durumu, Pro) |
|---|---|---|
| Etiket yazısının altı → kutu üstü | 21,0 | 5,0 |
| Etiket satırı (alanın üstü → kutu üstü) | 53,0 | 20,6 |
| Kutu yüksekliği | 49,0 | 44,0 |
| Bir alanın toplam yüksekliği (alt boşluk dahil) | 112,0 | 74,6 |

İki kutulu her satır yaklaşık 37 pt kısaldı. Ölçümün eski/yeni karşılaştırması `test/kutu_fikir4_test.dart` içindeki "measure: regular vs compact box" testinde. Sayılar tek seferlik bir ölçüm koşusundan okundu (aşağıda).

## Apple HIG dokunma alanı kontrolü

- ⓘ: `MenzilInfoButton` en az 44 × 44 pt, kutunun içinde ve kutu yüksekliği kadar. Testte her alan için genişlik ≥ 44 ve yükseklik ≥ 44 denetleniyor.
- Kutu: 44 pt (HIG alt sınırı). Yazı büyüdükçe kutu da büyür, hiçbir zaman 44'ün altına düşmez.
- Liste kutusu: 44 pt. ⓘ (44 × 44) ve ok aynı satırda; ok listeyi açar.

## Kenar durumlar

- **Hata yazıları:** Kutunun altında kalır, kutu 44 pt olarak kalır. Test: Pro'da "Atış mesafesi"ne 999999 yazılır; hata yazısı kutunun altında, ⓘ hâlâ 44 pt ve kutunun üstüyle hizalı.
- **Uzun etiketler:** Tek satır, gerektiği kadar küçülür (en çok %60'a kadar). Kesilmez ve "…" olmaz. Yan yana kutular hizalı kalır.
  - Bilerek seçilen bir karar: eski görünümde uzun etiket iki satıra iniyor ve komşu kutuyla hizası bozuluyordu.
- **Liste kutuları:** Pro'daki "Yönü" ve "Atış sayısı" (ve gizli "Rüzgâr gözlemi") 44 pt. ⓘ okun solunda ve listeyi açmaz. Açılan listenin genişliği #273'teki gibi kutu kadar.
- **Büyük yazı:** Dar telefon (320 × 568) ve yazı ölçeği 1,3 ile Hava Durumu ve Pro sayfası baştan sona kaydırıldı, taşma yok. Pro'da Rüzgâr, Hareketli hedef ve Tüfek düzeltmeleri kutuları açıldı.
  - Bu boyutta form zaten tek sütuna geçiyor (`MenzilFieldGrid`).
  - Yazı büyüyüp 44 pt'ye sığmadığında kutu kendiliğinden büyür; 1,3 ölçekteki kutu yüksekliği ayrıca ölçülmedi.
- **Koyu tema:** Renkler `MenzilColors`'tan gelir (birim `ink2`, ⓘ `ink2`). Testte koyu temada kutu 44 pt, ⓘ kutunun içinde ve taşma yok.
- **VoiceOver:**
  - Alanın okunan adı aynı kaldı: etiket + birim, ör. "Sıcaklık (°C)". Kutunun içindeki birim yazısı ayrıca okunmaz (iki kez söylenmesin diye).
  - ⓘ ayrı bir düğme olarak kalır ("Bilgi: Sıcaklık").
  - Liste kutularının okunan adı değişmedi.
- **Anahtarlar, doğrulama, davranış:** Alan anahtarları (`BallisticsFieldKeys.*`, `pro-*`, `env-ammo-temp`), hata kuralları ve `onChanged` davranışları değişmedi.

## Bilerek yapılmayanlar

- Profil (Oluştur/Düzenle), Hedef, Araçlar ve "Balistik / DOPE" ekranları değişmedi. `MenzilSpace.control` (46) değişmedi.
- Pro'da kutu başlıklarındaki ⓘ ve alttan açılan açıklama sayfası (#279) değişmedi; yalnız alanların ⓘ'si kutunun içine taşındı.
- Mesafe ve açı girişi pencereleri (dialog) eski görünümde kaldı.
- Düğme yazılarında yalnız istenen iki "tamam" yazısı değişti. Boşta görünen yazılar test genişliğinde ve iPhone SE'de en çok iki satır; yeni yazı uydurulmadı.
- `integration_test/` değişmedi. Oradaki Hava Durumu ve Pro adımları alanları anahtar ve `enterText` ile buluyor; etiket yazıları ve anahtarlar aynı. Simülatör testleri bu işte çalıştırılmadı.
- TestFlight ve birleştirme (merge) yapılmadı; PR taslak (draft).

## Hangi test kapsıyor

`test/kutu_fikir4_test.dart`:

- Hava Durumu: Sıcaklık, Bağıl nem, İstasyon basıncı, İrtifa, Rüzgâr hızı ve Rüzgâr yönü için şunlar denetlenir:
  - etiket → kutu ≤ 8 pt
  - kutu 44 pt
  - ⓘ kutunun içinde ve ≥ 44 × 44
  - birim kutunun içinde, ⓘ'nin hemen solunda
- Hava Durumu: yan yana kutuların ve etiket yuvalarının hizası (üç satır).
- Hava Durumu: ⓘ popup'ı açar, alan odaklanmaz; kutuya dokununca alan odaklanır.
- Hava Durumu: VoiceOver adı "Sıcaklık (°C)", ⓘ'nin ipucu (tooltip) yerinde.
- Hava Durumu: "Hava verisi alındı" ve "Basınç alındı" yazıları tek satır; eski yazılar yok; boşta görünen yazılar aynı.
- Hava Durumu ve Pro: dar telefon + yazı ölçeği 1,3, baştan sona kaydırma, taşma yok.
- Hava Durumu: koyu tema.
- Pro: Atış mesafesi, Hedef hızı ve BC hatası için aynı ölçüler denetlenir. Kutudaki alanın ⓘ'si alttan açılan sayfayı açar, alan odaklanmaz.
- Pro: Atış mesafesinde hata yazısı kutunun altında.
- Pro: "Atış sayısı" liste kutusu için şunlar denetlenir:
  - kutu 44 pt
  - ⓘ okun solunda
  - ⓘ listeyi açmaz, açıklama sayfasını açar
  - oka dokununca liste açılır
- Ölçüm: eski ve kompakt kutu aynı temada karşılaştırılır.
- Regresyon: Profil formundaki "Tüp basıncı" kutusu için şunlar denetlenir:
  - ⓘ etiket satırında, kutunun içinde değil
  - etiket satırı ≥ 44
  - kutu ≥ 46
  - birim kutunun içinde değil
  - Profil "Tür" liste kutusunda ⓘ kutunun içinde değil
  - `MenzilSpace.control == 46`

`test/fetch_reset_buttons_test.dart`: yeni düğme yazılarına göre güncellendi.

## Doğrulama ve CI

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test OK.
- Bu ortamda Flutter SDK indirilemedi (Flutter motoru indirmesi ağ politikasınca engellendi). `flutter test` ve `flutter analyze` yerelde çalışmadı; GitHub Actions'ta çalıştırıldı.
- Son kod commit'i `da04163` üzerinde:
  - Format (`format-fix.yml`): yeşil, değişiklik gerekmedi — https://github.com/sniperTurk/flutter-app/actions/runs/38455070082
  - Testler (`test-diag.yml`, `files=test`, tüm test klasörü): yeşil — https://github.com/sniperTurk/flutter-app/actions/runs/38455389999
  - Analiz (`analyze-diag.yml`, `--fatal-infos --fatal-warnings`): yeşil — https://github.com/sniperTurk/flutter-app/actions/runs/38455393429
- Ara koşular (düzeltildi):
  - İlk analiz, kullanılmayan bir parametre için uyardı.
  - İlk test koşularında kendi yeni testlerimde 44,0 ile 43,99999 farkı ve uzun etiketin iki satıra inmesi yakalandı. Uzun etiket sorunu bu yüzden tek satır, sabit yuvalı etiketle çözüldü.
- Ölçüm koşusu (yalnız sayıları okumak için, geçici `tmp/fikir4-olcum` dalında tek test dosyası): https://github.com/sniperTurk/flutter-app/actions/runs/38455099489. Bu dal birleştirilmeyecek; silinmesi gerekiyor (bu ortamdan dal silme engellendi).
- Bu commit'ten sonra yalnız bu rapor eklendi (Dart kodu değişmedi).
- iOS CI, Simülatör, cihaz ve TestFlight bu işte çalıştırılmadı.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
