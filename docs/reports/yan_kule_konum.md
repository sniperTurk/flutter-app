# Yan kule konum (Hedef)

Sahibin isteği (2026-10-16 21:08–21:09, TestFlight 110, 390 pt iPhone, Hedef sayfası): "Sağ kulenin sağ tarafında dürbün beyazlığı var … Kuleyi biraz sağa al."

## Ne yapıldı
- Hedef sayfasındaki dikey yan (rüzgâr) kule, kutusu ve okları birlikte, **4·k pt sağa** alındı. k = retikül genişliği / 334: 390 pt telefonda (334 pt retikül) 4 pt, 320 pt telefonda yaklaşık 3 pt.
- Kutunun sağ kenarı artık retikül karesinin sağ kenarında, yani dürbün dairesinin dış kenarının üstünde. Kutunun sağında dairenin beyazı görünmüyor.
- Değişmeyenler:
  - Kutu boyu (390 pt'de 66 × 180 pt).
  - Oklar ve dokunma alanları (en az 44 pt).
  - Sıfırın yatay çizgide olması.
  - Kayarak gelme animasyonu.
  - L-R düğmesi.
  - Klik sayımı. #369'un `_sent ?? widget.clicks` mantığına dokunulmadı.
- Kule kartın ve ekranın içinde kalıyor. Retikülün merkezini ve rakamlarını eskisinden fazla örtmüyor; kutu sağa gittiği için 4·k pt daha az örtüyor.

## Nasıl
- Uygulama kodunda yalnız `lib/features/ballistics/scope_turrets.dart` (`_TurretBarState`) değişti:
  - Kule sütunu `right: 0` yerine `right: -columnInset` ile konumlanıyor.
  - `columnInset = (sideColumnWidth − sideBoxWidth) / 2 · k`, yani (74 − 66) / 2 = 4 pt × k.
- Sütunun retikül karesinin dışına taşan 4·k pt'lik kısmı boş kenar payı. Kare `Clip.hardEdge` ile kırpıldığı için bu pay kartın üstüne çizilmiyor ve dokunmaya kapalı. Kutu ve okların dokunulan kısmı karenin içinde kalıyor.
- Dal güncel main'in (f46ab8f; #369, #372, #373 dahil) üstüne yeniden kuruldu (rebase). Çakışma çıkmadı; #369'un klik sayımı aynen duruyor.

## Neden
- Kutu 74·k pt'lik sütunun ortasındaydı, iki yanında 4·k pt boşluk vardı. Sağdaki bu boşluktan dürbün dairesinin beyaz kenarı görünüyordu. Sütunu boşluk kadar sağa almak beyazlığı kapatıyor; boyut, oklar ve davranış değişmiyor.
- **CI hatasının kökü:** 29f442f'te `dart-checks`, `dart format --set-exit-if-changed` adımında düştü ([iş 117152657907](https://github.com/sniperTurk/flutter-app/actions/runs/38954150297/job/117152657907): "Changed test/yan_kule_konum_test.dart"). Nedeni şuydu: 29f442f bir test adını iki parçalı string'e böldü, ve bu commit format-fix commit'inden sonra geldi. Test adı tek string yapıldı, uzun yorum satırları sarıldı. Test mantığı değişmedi; hiçbir test atlanmadı, silinmedi, gevşetilmedi. Ardından repo'nun format-fix iş akışı çalıştırıldı: "Formatted 413 files (0 changed)" ([koşu](https://github.com/sniperTurk/flutter-app/actions/runs/38963878578)).

## Uç durumlar
- **320 pt dar ekran ve yazı ölçeği ×1.3:**
  - Taşma yok.
  - Kutu retikülle orantılı küçülüyor.
  - Okların karede kalan dokunma genişliği en dar retikülde (254 pt) yaklaşık 53 pt, yani 44 pt'nin üstünde.
- **Okların retikül kenarından 1 pt içerisi:** dokununca kule adım atıyor.
- **L-R:** kule yine sağdan kayarak geliyor ve gidiyor. Kapalıyken hiçbir şey değişmiyor.
- **Sütunun kare dışındaki boş payı:** çizilmiyor ve dokunulmuyor (kare kırpıyor). Kutunun ve okların tamamı karenin içinde.
- **430 pt geniş ekran:** kutunun sağında beyazlık yok; kart ve ekran içinde.

## Bilerek yapılmayan
- Kutunun boyu, iç yazıları, okların biçimi ve üst kule değiştirilmedi. Görev yalnız konumdu.
- Retikül, dürbün dairesi ve diğer sayfalara dokunulmadı.
- Birleştirme (merge) ve TestFlight yapılmadı.

## Testler
- **`test/yan_kule_konum_test.dart` (yeni).** Denenen boyutlar: 390×844 (×1.0 ve ×1.3), 320×568 (×1.0 ve ×1.3), 430×932. Her boyutta:
  - Kutunun yuvarlak köşeleri dahil, kutunun yüksekliği boyunca her satırda (0,5 pt adımla) kutu, dürbün dairesinin dış kenarı kadar ya da daha sağa uzanıyor: sağında beyazlık yok.
  - Kutu retikül kenarında, aynı boyda, sıfırı çizgide; kart ve ekran içinde.
  - Kutu retikül merkezinden 60·k pt'den daha uzakta.
  - İki ok da kuleyi adımlıyor, retikül kenarının 1 pt içinden de.
  - L-R ile kayarak gelip gidiyor.
  - Retikül karesi `Clip.hardEdge` ile kırpıyor.
- **Eski geometriyi sabitleyen testler yeni karara göre güncellendi** (gevşetilmedi, değerleri değişti):
  - `test/scope_dial_view_test.dart`: sütun sağı retikül + 4·k, kutu sağı retikül kenarında.
  - `test/temiz_tasarim_hedef_test.dart`: kutu sağı retikül kenarında (önceden 4·k içerideydi).
  - `test/yan_kule_oklar_test.dart`: ok merkezleri retikül kenarından 33·k (önceden 37·k).
  - `test/kule_ok_alani_sifir_hizasi_test.dart`: sütun 4·k dışarıda; karede kalan dokunma genişliği ≥ 44 pt; dokunma denemesi karenin içindeki kısımda.
- **`integration_test/yan_kule_konum_screens_test.dart`:** gerçek uygulamayla Hedef sayfasının 390 ve 320 pt ekran görüntüsü turu.
- **Yerel:**
  - `python3 tools/offline_dart_lint.py`: geçti (411 Dart dosyası, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: geçti (915 test, 1 atlanan).
  - Bu ortamda Flutter SDK yok; Flutter testleri CI'da çalıştı.

## Ekran görüntüleri (önce / sonra)
Gerçek uygulama, iPhone 17 Pro Simulator, iOS 26.2. Ekran görüntüsü iş akışı (`sim-screens.yml`) ve `integration_test/yan_kule_konum_screens_test.dart` kullanıldı. 320 pt görüntüde uygulama, Simulator ekranının ortasında 320 × 568 pt'lik bir çerçevede çiziliyor.

- **Önce (güncel main f46ab8f + yalnız tur testi, dal `tmp/yan-kule-konum-once`):** [koşu 38970991373](https://github.com/sniperTurk/flutter-app/actions/runs/38970991373), çıkış 0.
  - [390 pt](https://github.com/sniperTurk/flutter-app/blob/e2e27785f0e700e424e1e60862e96be7a05e034b/latest/01_hedef_yan_kule_390.png?raw=true)
  - [320 pt](https://github.com/sniperTurk/flutter-app/blob/e2e27785f0e700e424e1e60862e96be7a05e034b/latest/02_hedef_yan_kule_320.png?raw=true)
- **Sonra (bu dal):** [koşu 38973887077](https://github.com/sniperTurk/flutter-app/actions/runs/38973887077), çıkış 0.
  - [390 pt](https://github.com/sniperTurk/flutter-app/blob/af169a9fcb47f29300b7eb033de3fc3fa4d91306/latest/01_hedef_yan_kule_390.png?raw=true)
  - [320 pt](https://github.com/sniperTurk/flutter-app/blob/af169a9fcb47f29300b7eb033de3fc3fa4d91306/latest/02_hedef_yan_kule_320.png?raw=true)

| | 390 pt | 320 pt |
|---|---|---|
| Önce | ![önce 390](https://github.com/sniperTurk/flutter-app/blob/e2e27785f0e700e424e1e60862e96be7a05e034b/latest/01_hedef_yan_kule_390.png?raw=true) | ![önce 320](https://github.com/sniperTurk/flutter-app/blob/e2e27785f0e700e424e1e60862e96be7a05e034b/latest/02_hedef_yan_kule_320.png?raw=true) |
| Sonra | ![sonra 390](https://github.com/sniperTurk/flutter-app/blob/af169a9fcb47f29300b7eb033de3fc3fa4d91306/latest/01_hedef_yan_kule_390.png?raw=true) | ![sonra 320](https://github.com/sniperTurk/flutter-app/blob/af169a9fcb47f29300b7eb033de3fc3fa4d91306/latest/02_hedef_yan_kule_320.png?raw=true) |

Görünen farkların hepsi şunlar:
- **Kutunun sağındaki beyazlık:**
  - Önce: 390 pt'de, sıfır çizgisi hizasında kutunun sağında dürbün dairesinin ince beyaz kenarı görünüyor. 320 pt'de daha ince bir beyaz şerit var.
  - Sonra: iki genişlikte de kutunun sağında beyazlık yok.
- **Konum:** kutu ve ↑/↓ okları birlikte 390 pt'de yaklaşık 4 pt, 320 pt'de yaklaşık 3 pt sağa kaydı. Kutunun solunda yatay retikül çizgisinin biraz daha fazlası görünüyor.
- **Değişmeyenler:** kutu boyu, yazılar, sıfır işareti ve çizgi hizası, üst kule, L-R düğmesi, mesafe rakamları ve sayfanın geri kalanı.
- **Main'de de olan, bu görevin konusu olmayan durum (değiştirilmedi):** kutunun üstündeki "↑R" ile "2R" ve altındaki "L↓" ile "2L" yazıları üst üste biniyor. 320 pt'de "2R"/"2L" kutunun kenarında kesiliyor.

Not: "Önce" koşusunu sıraya koyduğum anda (21:40:52 UTC), başka bir oturumun 1 saniye önce sıraya koyduğu sim-screens koşusu 83 (38970989374), iş akışının "tek bekleyen" kuralı yüzünden iptal oldu. Göndermeden önce sırada bekleyen koşu yoktu. "Sonra" koşusu boş sırada gönderildi ve hiçbir koşunun yerini almadı.

## CI
- `iOS CI` (392a7a7, kod commit'i): https://github.com/sniperTurk/flutter-app/actions/runs/38964444741
  - `verify`: başarılı.
  - `dart-checks`: başarılı. Format, analyze, birim ve widget testleri, Python seti ve G1/G7 kapısı dahil.
  - `wind-acceptance`: başarılı.
- Tüm testler (`test-diag`, `files=test`, af40474): https://github.com/sniperTurk/flutter-app/actions/runs/38964165172. Başarılı.
- Analyze (`analyze-diag`, `--fatal-infos --fatal-warnings`, af40474): https://github.com/sniperTurk/flutter-app/actions/runs/38964168962. Başarılı.
- Format düzeltme iş akışı (af40474): https://github.com/sniperTurk/flutter-app/actions/runs/38963878578. 0 dosya değişti.
- af40474 ile 392a7a7 arasındaki tek fark ekran turu testinin sonundaki 30 sn bekleme. Bu, aynı dalda çalışan önceki görev oturumunun eklediği, yalnız `integration_test/` içinde bir değişiklik.

## İnceleme
- Code Review ve Security review: sorun bulunmadı ([PR yorumu](https://github.com/sniperTurk/flutter-app/pull/371#issuecomment-6224338858)).
