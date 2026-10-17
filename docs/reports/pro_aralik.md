# Pro Ayarlar aralıkları

Dal: `fix/pro-aralik` (main @ 53100e0 üzerine rebase edildi, sonra main'in #404 düzeltmesi birleştirildi: 19bfac7; ilk hali 2101b3f'dan) · Taslak PR #399 (birleştirilmedi, TestFlight yok).

## Sahibin kararı (İstanbul, 17.10.2026, TestFlight 113, ekran görüntüsü 20:54)
20:55 "Bu sayfadaki aralık mesafelerini düzelteceğiz", 20:58 "20 pt yap", 20:59 "açılır olanları 60 yap", 21:01 "tamam böyle düzenle".
1. "Atış mesafesi" kartı: kartın üst kenarı → "Atış mesafesi" yazısının üstü ≈44 pt → **20 pt**.
2. Açılır kutu başlıkları (Açı, Rüzgâr düzeltmesi, Coriolis, Yerçekimi, Hareketli hedef, Tüfek düzeltmeleri) kapalıyken ≈74 pt → **60 pt**.
3. Kartlar arası boşluk ≈9 pt, değişmedi.

## Ne yapıldı
- **Atış mesafesi kartı:** yazının üstü artık kartın üst kenarından **20 pt** aşağıda (main: 42,4 pt; test ölçümü). Yazı, kutu, "Haritadan ölç" (PCP'de "Paralakstan" da) ve aralarındaki boşluklar aynı. Kart sayfada aynı yerde duruyor (sayfanın üstü → kart 10 pt, main ile aynı). Kartın alt boşluğu aynı (14 pt).
- **Açılır kutular:** kapalı kutu kartı **60 pt** (main: 76 pt; test ölçümü). Başlık, ⓘ, özet ("düz", "kapalı", "açık" …) ve ok dikeyde ortada. Başlığın tamamı (60 pt) dokunma alanı (main'de 48 pt'lik iç şerit). Mühimmat sıcaklığı kutusu (yalnız ateşli) da aynı açılır kart olduğu için o da 60 pt.
- **Kartlar arası boşluk:** 8 pt (+ 1 pt kenar çizgisi ≈ ekranda 9 pt), değişmedi.

## Nasıl
Yalnız `lib/features/ballistics/pro_ayarlar_view.dart` değişti (paylaşılan bileşenlere dokunulmadı).
- **Boşluk nereden geliyordu:** kompakt kutunun etiket satırı (`_CompactLabel`, `lib/ui/menzil_widgets.dart`) ⓘ'nin 44 pt dokunma alanı kadar yüksek ve yazı bu satırın altında. Kartın 14 pt iç boşluğu + 44 − 15,6 = 28,4 pt boş satır payı = 42,4 pt. Boş satır/başlık yoktu; boşluk bu ⓘ satırıydı.
- **Çözüm:** kartın zemini içeriğin arkasına ayrı çiziliyor (Stack). İçerik, yazı kart kenarından 20 pt aşağıda olacak şekilde yerleşiyor. ⓘ'nin 44 × 44 pt dokunma alanının üst kısmı (normal yazı boyunda 8,4 pt, ×1,3'te 3,7 pt) kart kenarının biraz üstüne, sayfanın üst boşluğuna taşıyor ve orada da dokunulabiliyor. Sayfanın üst boşluğu aynı miktar azaltıldı, böylece kart yerinden oynamadı. ⓘ simgesi kartın içinde, yazının ortasıyla aynı hizada (eskisi gibi).
- **Açılır kutu:** kartın üst/alt iç boşluğu kaldırıldı; başlığın kendisi en az 60 pt (8 pt üst/alt + 44 pt satır), içindekiler ortalı. Açıkken içerik altında yine 14 pt.

## Neden
Sahibin ekran görüntüsündeki ölçülere göre sayfa daha sıkı; ⓘ'nin 44 pt dokunma alanı (Apple kuralı ve mevcut test) korunarak.

## Uç durumlar
- **Büyük yazı (×1,3) ve 320 pt:** yazı yine 20 pt, kapalı kutular 60 pt, taşma yok. 320 pt + ×1,3'te bir başlık iki satıra kırılırsa o kutu 60 pt'den uzun olur (ortalı kalır, dokunma alanı yine tüm başlık).
- **Küçük yazı (iOS "xSmall", yaklaşık ×0,82–0,89):** ⓘ'nin taşan kısmı sayfanın 10 pt üst boşluğundan büyük olur; kart bu durumda ≈1 pt aşağı kayar. Yazı–kart kenarı yine 20 pt.
- **Açık kutu:** başlık açıkken de 60 pt (main'de 14 + 48 = 62). Bu yüzden açık kutuda başlık kart kenarına 8 pt (main 14 pt) ve içerik 2 pt daha yukarıda başlıyor; içeriğin kendisi (kutular, düğmeler, aralıklar, alt 14 pt) aynı. Sahip açık başlığın da 62 pt kalmasını isterse ayrı küçük iş.
- **Hata yazısı** (ör. 999999 m) kutunun altında, kartın içinde kalıyor.
- **Bakım notu:** sayfa, `_CompactLabel`'ın "satır = max(44, yazı satırı), yazı altta" kuralını hesapta kullanıyor; o bileşen değişirse `test/pro_aralik_test.dart` yakalar (×1,0 ve ×1,3).

## Bilerek yapılmayan
- Başka sayfa, metin, etiket, ⓘ, açık bölüm içeriği değişmedi. Paylaşılan `MenzilInput` / `_CompactLabel` / `MenzilCard` değişmedi (Hava Durumu etkilenmez).
- Garmin saati satırı (yalnız köprülü sürümlerde, açılır kutu değil) değişmedi.
- Birleştirme yok, TestFlight yok.

## Testler
- **Yeni:** `test/pro_aralik_test.dart` (gerçek Pro Ayarlar sayfası, ±0,5 pt):
  - 390 pt ×1,0, 320 pt ×1,0, 390 pt ×1,3: kart üstü → "Atış mesafesi" yazısı üstü = 20; sayfa üstü → kart = 10 (main ile aynı); 7 kapalı kutunun her biri 60; başlığın dokunma alanı = kart yüksekliği (≥ 44); kartlar arası = 8; başlık, ⓘ, özet, ok dikeyde ortada.
  - 320 pt ×1,3 + uzun özet ("… ayar açık", Tüfek düzeltmeleri): taşma yok, kutular ≥ 60, tüm başlık dokunulabilir, ortalı; yazı yine 20.
  - ×1,0 ve ×1,3: Atış mesafesi ⓘ 44 × 44, kutunun üstünde, simgesi kartın içinde; dokunma alanının en üstüne (kart kenarının üstü) dokununca açıklama açılıyor; yazı → kutu 5 pt (aynı).
  - 60 pt başlığın üst ve alt kenarına yakın dokunuş kutuyu açıp kapıyor; açık kutunun alt boşluğu 14 pt (aynı).
  - Hata yazısı kartın içinde.
  - **Önce kırmızı (main'de):** aynı test main kodu üzerinde çalıştırıldı: 4 test kırmızı (yazı 42,375 / ×1,3'te 38,0; kutu 76), 4 test yeşil (ⓘ, aç/kapa, hata yazısı: zaten doğru olanlar korunuyor) — [test-diag 39057197764](https://github.com/sniperTurk/flutter-app/actions/runs/39057197764). Geçici dal `tmp/pro-aralik-red` silinemedi (silme isteği bağlantıda reddedildi); diğer `tmp/` dalları gibi duruyor, silinebilir.
- **Değiştirilen eski test yok.** Hiçbir test zayıflatılmadı; `test/kutu_fikir4_test.dart` (ⓘ 44 × 44, kutunun üstünde) olduğu gibi geçiyor.
- **Ekran turu:** `integration_test/sim_screens_pro_aralik_test.dart` (390 ve 320 pt kapalı, 390 pt Hareketli hedef açık; ölçüleri SIMMEASURE satırı olarak yazar; ölçüm doğrulamaz, yalnız fotoğraf ve ölçü).
- **Yerel:** `python3 tools/offline_dart_lint.py` → PASS (434 Dart dosyası, 0 sorun). `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlandı). Bu makinede Flutter yok (storage.googleapis.com engelli), Flutter testleri CI'da.
- **İnceleme:** Code Review eklentisi taslak PR'ları incelemiyor (ilk adımda durur). Yerine ayrı bir inceleme ajanı diff'i hata ve güvenlik için okudu: yüksek/orta bulgu yok; düşük bulgular yukarıdaki uç durumlarda (küçük yazıda ≈1 pt kayma, açık başlık 60/62, paylaşılan bileşen kuralının kopyası, ekran turunun doğrulama yapmaması). Güvenlik: diff'te giriş, kayıt, ağ, izin veya gizli bilgi yok. Taslak "hazır" yapılınca Code Review / Security review eklentileri yeniden çalıştırılmalı.

## Ekran görüntüleri
Simülatör koşusu [39075298648](https://github.com/sniperTurk/flutter-app/actions/runs/39075298648) (iPhone 17 Pro, iOS 26.2; sayfa 390 ve 320 pt genişlikte çizildi; çıkış kodu 0). Görüntüler `ci/sim-screens` dalında, commit [1a55968](https://github.com/sniperTurk/flutter-app/tree/1a55968ac4653bec9b0589a630a39b694e4d8f0a/latest) (README'deki "Source … @ 6ccbed0" satırı iş akışının main sha'sını yazıyor; çizilen dal `fix/pro-aralik`).
- [01 — 390 pt, tüm kutular kapalı](https://raw.githubusercontent.com/sniperTurk/flutter-app/1a55968ac4653bec9b0589a630a39b694e4d8f0a/latest/01_pro_aralik_390_kapali.png)
- [02 — 320 pt, tüm kutular kapalı](https://raw.githubusercontent.com/sniperTurk/flutter-app/1a55968ac4653bec9b0589a630a39b694e4d8f0a/latest/02_pro_aralik_320_kapali.png)
- [03 — 390 pt, Hareketli hedef açık](https://raw.githubusercontent.com/sniperTurk/flutter-app/1a55968ac4653bec9b0589a630a39b694e4d8f0a/latest/03_pro_aralik_390_target_acik.png)

Simülatörde ölçülen (SIMMEASURE, gerçek iOS yazı tipi):
| | 390 pt | 320 pt |
|---|---|---|
| Kart üstü → "Atış mesafesi" yazısı | 20,0 | 20,0 |
| Kapalı kutu yüksekliği (7 kutunun her biri) | 60,0 | 60,0 |
| Başlık dokunma alanı | 60,0 | 60,0 |
| Kartlar arası | 8,0 | 8,0 |

Onaylı değerlerden görünen farklar (dürüst liste):
- Onaylı değerlerle fark yok: 20 / 60 / 8 (+1 pt çizgi ≈ 9) pt.
- 320 pt'de özetler kısalıyor: Rüzgâr düzeltmesi "ka…", Tüfek düzeltmeleri "ka…", Mühimmat sıcaklığı "k…". Bu bu PR'dan değil: başlık satırının genişlik kuralı (`ProRowHeader`: önce özet kısalır, başlık tek satır kalır) değişmedi ve satırın yatay genişliği aynı (kartın sol/sağ 14 pt boşluğu korunuyor), bu yüzden main'de de aynı kısalma beklenir; main'in 320 pt görüntüsü bu koşuda çekilmedi.
- 320 pt görüntüsünde sağdaki siyah alan, sayfanın 320 pt'lik bir çerçevede çizilmesinden (telefon 402 pt); uygulamanın parçası değil.
- 03'te sayfa açık kutuya kaydırılmış; en üstte Rüzgâr kartının alt kenarı görünüyor (beklenen).
- Atış mesafesi ⓘ simgesi yazının ortasıyla aynı hizada, kartın içinde; kartın üstünde boş satır yok.

## CI bağlantıları
**Güncel head 19bfac7 (main'in #404 düzeltmesi birleştirildi): YEŞİL.** iOS CI [39072355628](https://github.com/sniperTurk/flutter-app/actions/runs/39072355628): **verify ✅**, **dart-checks ✅** (biçim, analiz, tüm testler, Python, G1/G7), **wind-acceptance ✅**, ios-simulator atlandı (iş akışı kuralı).

Önceki durum (geçmiş): rebase sonrası head 3b0bf09 / ffc9872'de dart-checks kırmızıydı ([39064600443](https://github.com/sniperTurk/flutter-app/actions/runs/39064600443)); sebep main'in kendisinin derlenmemesiydi (#389 + #395, `profile_editor_rifle.dart`), #404 ile giderildi.

**Rebase öncesi (kod commit'i 3a3a083, main 2101b3f üzerinde): YEŞİL.**
- iOS CI [39057619000](https://github.com/sniperTurk/flutter-app/actions/runs/39057619000): verify ✅, dart-checks ✅ (biçim, `flutter analyze --fatal-infos --fatal-warnings`, tüm birim/widget testleri, Python takımı, G1/G7 kapısı), wind-acceptance ✅, ios-simulator atlandı (iş akışı kuralı).
- test-diag `files=test` [39057728667](https://github.com/sniperTurk/flutter-app/actions/runs/39057728667): ✅
- analyze-diag [39057619872](https://github.com/sniperTurk/flutter-app/actions/runs/39057619872): ✅
- format-fix (375209577) [39057191061](https://github.com/sniperTurk/flutter-app/actions/runs/39057191061) (1 biçim commit'i) ve [39057529183](https://github.com/sniperTurk/flutter-app/actions/runs/39057529183) (değişiklik yok).
- Kırmızı kontrol (main kodu + yeni test): [39057197764](https://github.com/sniperTurk/flutter-app/actions/runs/39057197764) ❌ beklendiği gibi.

Rebase'de çakışma olmadı; bu PR'ın değiştirdiği dosyalarda main'den gelen tek değişiklik `pro_ayarlar_view.dart`'ta `muzzleVelocityMps` → `velocityMps` (#388), korundu.

— Claude Code
