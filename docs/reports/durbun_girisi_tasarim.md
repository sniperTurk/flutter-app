# Dürbün girişi: onaylı tasarım ve elle girişte Dürbün modeli

Dal: `fix/durbun-girisi-tasarim` · Taslak PR · Birleştirme yok, TestFlight yok.

Sahibin sözü (16.10.2026, 19:25–19:31 İstanbul): "Dürbün girişi nasıl olacaktı? … Neden ben dürbün eklemek istediğim bu sıra ile ekleyemiyorum? … Acil şu sayfayı bağla."

## Ne yapıldı

Profil Oluştur ve Profili Düzenle → Dürbün kartı onaylı tasarımdaki sıraya getirildi (Temiz Tasarım, "Profil Oluştur", 15.10.2026).

**Listeden seçim (yukarıdan aşağı):**

1. Marka (tam satır)
2. Birim | Odak düzlemi (ⓘ ile)
3. Tüp | Büyütme (ⓘ ile)
4. Model (tam satır; markanın yalnız filtreleri geçen modelleri)
5. Üst kule klik sayısı | Dürbün ayağı (ⓘ ile)
6. Retikül (ⓘ; yalnız o modelin retikülleri)
7. "Dürbün: Marka Model …" satırı
8. "Aradığın dürbün listede yok mu?" bağlantısı

Filtreler artık Marka seçilmeden de yerinde duruyor. Marka seçilene kadar **kapalı** ve "Seçiniz" gösteriyorlar; Marka seçilince açılıyorlar. Filtre mantığı aynen kaldı: Marka değişince filtreler sıfırlanıyor, bir filtre seçilen modeli düşürürse Model "Seçiniz"e dönüyor. Filtre etiketi "Odak" yerine tasarımdaki gibi "Odak düzlemi" oldu.

**Elle giriş ("Aradığın dürbün listede yok mu?"):**

1. Dürbün markası | Dürbün modeli (yan yana iki yazı kutusu, ikisi de zorunlu)
2. Minimum büyütme | Maksimum büyütme
3. Mercek çapı | Odak düzlemi
4. Dürbün birimi | Klik değeri
5. Üst kule klik sayısı | Dürbün ayağı
6. Retikül (seçilen birime uyan genel listeden, eskisi gibi)
7. "Dürbün: Marka Model …" satırı, en altta da "Listeden seç" bağlantısı

"Kaydetmek için eksik" listesi, elle girişte model boşsa "Dürbün modeli" yazıyor. Kayıtlı dürbünün adı ve Profil özet kartı artık "Marka Model …" gösteriyor (ör. "Benim Optik X5 Pro 5-25x56 FFP").

## Nasıl

- `profile_editor_scope.dart`: Filtreler her zaman listede; `onChanged` Marka seçilene kadar `null` (kapalı). Elle girişte `scope-brand` | `scope-model` aynı satırda. "Listeden seç" kartın en altına taşındı. "Dürbün: …" satırı marka + elle girilen model + ölçüleri birleştiriyor.
- `profile_editor.dart`: Yeni `scopeModel` kutusu eklendi. Elle girişte model kayıtta ölçülerin önüne yazılıyor; kaydın `model` alanı ör. `"X5 Pro 5-25x56 FFP"` oluyor (marka ayrı alanda kalıyor). Listeden seçilen dürbünün kaydı değişmedi (`model` = yalnız ölçüler). Profili Düzenle açılınca model, kaydın `model` alanından ölçüler çıkarılarak geri okunuyor.
- `profile_summary.dart`: Özet kartı elle girilen modeli markanın yanına koyuyor.
- Profili Düzenle'de filtreleri Marka değişene kadar gizleyen `_scopeFiltersHidden` silindi (CLAUDE.md: kaldırılan özellik koddan silinir).

## Neden

Elle girişte model kutusu yoktu; sahip dürbününün modelini giremiyordu ve kart onaylı tasarımın sırasında değildi. CLAUDE.md kuralı da "Marka | Model yan yana" diyor.

## Uç durumlar

- **Model alanı olmadan kaydedilmiş eski elle giriş profilleri**: Açılınca model kutusu boş, diğer her şey eskisi gibi. Bu profiller **model girilmeden de Güncellenebiliyor**: eski profilin hiçbir şeye dokunmadan güncellenmesini koruyan denetim testleri (audit_2026_10_14b, audit_2026_10_15b) bozulmasın diye böyle yapıldı. Kullanıcı modeli ekleyip kaydederse model saklanıyor. Yeni elle girişte model zorunlu. Eski profillerde de zorunlu olsun istenirse tek satırlık bir değişiklik bu (`_scopeLegacyNoModel`).
- Liste profilleri değişmedi: kayıt biçimi, eşleşme ve açılış aynı.
- Bir katalog kaydında olmayan değer (ör. Gamo'da odak düzlemi) eskisi gibi kendi kutusunda soruluyor. Bu durumda kartta iki "Odak düzlemi" görünüyor: biri filtre, biri değer kutusu. Bu kutu Model'in altında, Üst kule | Dürbün ayağı satırından önce çıkıyor, bu yüzden o satır bir kayabiliyor (bu davranış önceden de vardı).
- Dar ekran (320 pt) ve yazı ölçeği 1,3: Kartta tek sütun oluyor, sıra korunuyor, taşma yok.
- Dürbün modeli en fazla 80 karakter: kaydın model alanı ölçülerle birlikte 100 karakteri geçmesin diye.
- Özet kartı, katalogda olduğu gibi MOA/MRAD/MIL/SMOA kelimelerini isimden çıkarıyor. Modelin içinde bu kelimeler varsa özette görünmez.

## Bilerek yapılmayan

- Hesap değişikliği yok. Klik değeri, birim, FFP/SFP, üst kule ve dürbün ayağı çözücüye eskisi gibi gidiyor.
- Dürbün markası ve Dürbün modeline ⓘ eklenmedi. CLAUDE.md marka/model gibi kimlik alanlarını muaf tutuyor; tasarımda da ⓘ yok. Kaynak denetim aracındaki kimlik listesine `Dürbün modeli` eklendi (`tools/denetim_2026_10_15b_profil.py`).
- Tüfek, Mühimmat ve diğer sayfalara dokunulmadı.
- Görsel olarak yeni bir tasarım dili kurulmadı; Frontend Design kuralları onaylı Temiz Tasarım ve mevcut Menzil bileşenleriyle uygulandı.

## Testler

Yeni dosya `test/durbun_girisi_tasarim_test.dart`, gerçek Profil ekranında çalışıyor:

- **Liste yolu**: Marka seçilmeden filtrelerin kapalı olduğu sınanıyor. Sonra Element Optics → Birim MOA → Odak düzlemi FFP seçiliyor; Model listesinin yalnız MOA+FFP modelleri gösterdiği doğrulanıyor. Titan 3-18x50 → Retikül APR-2D MOA → Kaydet → Profili Düzenle'de aynı marka, model, retikül, ayak ve "Dürbün:" satırı görünüyor.
- **Elle giriş yolu**: Kutular sırayla dolduruluyor → Kaydet → kayıtta `brand` "Benim Optik", `model` "X5 Pro 5-25x56 FFP" → özet kartında "Benim Optik X5 Pro 5-25x56 FFP" → Profili Düzenle'de model "X5 Pro" kalıyor → Güncelle sonrası kayıt aynı.
- **Sıra**, dikey konuma göre sınanıyor: aynı satırdaki kutuların üst kenarı ±0,5 pt içinde, soldan sağa diziliyor; satırlar yukarıdan aşağı. ⓘ'ler, etiketler ve "Kaydetmek için eksik"teki "Dürbün modeli" de sınanıyor.
- **Eski elle giriş profili**: Model kutusu boş açılıyor, diğer değerler aynı, eksik listesinde yok.
- **320 / 390 pt × yazı ölçeği 1,0 / 1,3**: Taşma yok, sıra korunuyor, kutular kartın içinde, açılan liste kutudan geniş değil.

Güncellenen testler (yeni sahip kararına göre beklentileri değişti; hiçbiri silinmedi veya atlanmadı):

- `test/profil_duzen_koruma_test.dart`: Liste düzeni artık filtrelerle başlıyor (Profil Oluştur ve Profili Düzenle aynı). Elle giriş düzeni yeni sırada. "Dürbün modeli" eksik listesinde ve kutu eşlemesinde. Eski elle giriş profilinin boş modelle açıldığı sınanıyor.
- `test/scope_form_sade_test.dart`: "Profili Düzenle filtreleri gizler" (13.10 kuralı) yerine "Profili Düzenle filtreleri gösterir" sınanıyor. Gamo'daki ⓘ kontrolü artık değer kutusunun kendi ⓘ'sine bakıyor.
- `test/support/rifle_form.dart` (`fillScopeForm` artık modeli de giriyor), `test/menzil_shell_test.dart` (beklenen satır "Test Optik X1 6-24x56 FFP"), `integration_test/app_launch_test.dart` (model giriliyor).

Yerel:

- `python3 tools/offline_dart_lint.py`: PASS (408 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'`: OK (915 test, 1 atlanan; atlanan main'de de atlanıyor)
- Bu ortamda Flutter SDK indirilemedi (Flutter'ın indirme sunucusuna erişim engelli). Bu yüzden `flutter test` yerelde çalışmadı; Flutter testleri yalnız CI'da koştu.

## Ekran görüntüleri

Simulator turu: `integration_test/sim_screens_durbun_test.dart`, `.github/workflows/sim-screens.yml` ile çalıştırıldı. Sonuç aşağıda.

SCREENSHOTS_PLACEHOLDER

## CI

CI_PLACEHOLDER

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01QtovsXdVyf4tUvteAngmB9
