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
- Modeli olan bir elle giriş kaydı, Profili Düzenle'de artık katalog kaydıyla eşleştirilmiyor. Marka + seri ve ölçüler bir katalog kaydıyla aynı olsa da elle giriş olarak açılıyor; yoksa bir sonraki kayıtta model düşerdi (Code Review bulgusu).
- `lib/ui/menzil_widgets.dart` (tek yer): Listede "Seçiniz" satırı olan kutularda (filtreler gibi) seçilen değer kapalı kutu gibi gri görünüyordu. Simulator görüntüsünde fark edildi: MOA/FFP seçili filtreler kapalı sanılıyordu. Açık kutuda seçilen değer artık normal yazı renginde; kapalı (onChanged yok) kutu gri kalıyor.

## Neden

Elle girişte model kutusu yoktu; sahip dürbününün modelini giremiyordu ve kart onaylı tasarımın sırasında değildi. CLAUDE.md kuralı da "Marka | Model yan yana" diyor.

## Uç durumlar

- **Model alanı olmadan kaydedilmiş eski elle giriş profilleri**: Açılınca model kutusu boş, diğer her şey eskisi gibi. Bu profiller **model girilmeden de Güncellenebiliyor**: eski profilin hiçbir şeye dokunmadan güncellenmesini koruyan denetim testleri (audit_2026_10_14b, audit_2026_10_15b) bozulmasın diye böyle yapıldı. Kullanıcı modeli ekleyip kaydederse model saklanıyor. Yeni elle girişte model zorunlu. Eski profillerde de zorunlu olsun istenirse tek satırlık bir değişiklik bu (`_scopeLegacyNoModel`).
- Liste profilleri değişmedi: kayıt biçimi, eşleşme ve açılış aynı.
- Bir katalog kaydında olmayan değer (ör. Gamo'da odak düzlemi) eskisi gibi kendi kutusunda soruluyor. Bu durumda kartta iki "Odak düzlemi" görünüyor: biri filtre, biri değer kutusu. Bu kutu Model'in altında, Üst kule | Dürbün ayağı satırından önce çıkıyor, bu yüzden o satır bir kayabiliyor (bu davranış önceden de vardı).
- Dar ekran (320 pt) ve yazı ölçeği 1,3: Kartta tek sütun oluyor, sıra korunuyor, taşma yok.
- Dürbün modeli en fazla 80 karakter. Ayrıca model + boşluk + ölçüler 100 karakteri geçerse hata veriyor; mağaza bu sınırın üstünü reddediyor.
- Katalog listesi boşsa (pratikte olmaz) elle giriş kaydı da modeliyle açılıyor; bu durumda da eski kayıt modelsiz güncellenebiliyor.
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
- **Katalogla aynı ölçülü, modeli olan elle giriş**: Liste moduna geçmiyor, model ("Benim") korunuyor.
- **320 / 390 pt × yazı ölçeği 1,0 / 1,3**: Taşma yok, sıra korunuyor, kutular kartın içinde, açılan liste kutudan geniş değil.

Güncellenen testler (yeni sahip kararına göre beklentileri değişti; hiçbiri silinmedi veya atlanmadı):

- `test/profil_duzen_koruma_test.dart`: Liste düzeni artık filtrelerle başlıyor (Profil Oluştur ve Profili Düzenle aynı). Elle giriş düzeni yeni sırada. "Dürbün modeli" eksik listesinde ve kutu eşlemesinde. Eski elle giriş profilinin boş modelle açıldığı sınanıyor.
- `test/scope_form_sade_test.dart`: "Profili Düzenle filtreleri gizler" (13.10 kuralı) yerine "Profili Düzenle filtreleri gösterir" sınanıyor. Gamo'daki ⓘ kontrolü artık değer kutusunun kendi ⓘ'sine bakıyor.
- `test/profile_editor_fail_closed_test.dart`: Gizli değer kutularının ⓘ'si yok kontrolü artık Odak düzlemi filtresinin kendi ⓘ'sini saymıyor. Elle girişte her kutunun ⓘ'si var kontrolü aynen duruyor.
- `test/support/rifle_form.dart` (`fillScopeForm` artık modeli de giriyor), `test/menzil_shell_test.dart` (beklenen satır "Test Optik X1 6-24x56 FFP"), `integration_test/app_launch_test.dart` (model giriliyor).

Yerel:

- `python3 tools/offline_dart_lint.py`: PASS (408 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'`: OK (915 test, 1 atlanan; atlanan main'de de atlanıyor)
- Bu ortamda Flutter SDK indirilemedi (Flutter'ın indirme sunucusuna erişim engelli). Bu yüzden `flutter test` yerelde çalışmadı; Flutter testleri yalnız CI'da koştu.

## Ekran görüntüleri

Simulator turu `integration_test/sim_screens_durbun_test.dart` çalıştırıldı (`.github/workflows/sim-screens.yml`, [run 38937057437](https://github.com/sniperTurk/flutter-app/actions/runs/38937057437), çıkış kodu 0, her adım geçti). Görüntüler `ci/sim-screens` dalında `d0ecf8d` commit'inde duruyor.

- Cihaz: **iPhone 17 Pro / iOS 26.2**. İş akışı en yeni iPhone Pro'yu seçiyor; bu cihazın genişliği 402 pt. İş akışında 390 pt cihaz seçeneği yok. 390 pt ve 320 pt genişlik widget testlerinde sınandı.
- Uygulama kodu: `7abb3a3`. Code Review düzeltmeleri (`4a87dc1`) bundan sonra geldi; ekranın düzeni o commit'te değişmedi. Bu görüntülerde seçili MOA/FFP filtresi henüz eski gri renkte görünüyor (aşağıda).

Görüntülerde ne görünüyor:

**Elle giriş**

- [01](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/01_durbun_elle_bos.png?raw=true): Boş elle giriş, kartın üstü. Sıra: Dürbün markası | Dürbün modeli, Minimum | Maksimum büyütme, Mercek çapı | Odak düzlemi. Hepsi "Seçiniz" ya da boş; klavye, tüfek alanından açık kalmış.
- [02](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/02_durbun_elle_bos_alt.png?raw=true): Kartın altı. Üst kule klik sayısı | Dürbün ayağı, Retikül, "Dürbün: —", en altta "Listeden seç".
- [03](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/03_durbun_elle_dolu.png?raw=true): Dolu hali, üstü. Benim Optik | X5 Pro, 5x | 25x, 56 mm | FFP, MRAD | 0,1 MRAD, 200 | 0 MOA.
- [04](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/04_durbun_elle_dolu_alt.png?raw=true): Dolu hali, altı. Retikül Mil-Dot; "Dürbün: Benim Optik X5 Pro 5-25x56 FFP"; "Listeden seç".
- [05](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/05_profil_ozet_elle.png?raw=true) ve [06](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/06_profil_ozet_elle_2.png?raw=true): Kayıttan sonra Profil sayfası. Dürbün bilgileri → Marka / Model: "Benim Optik X5 Pro 5-25 x 56 FFP · MRAD", Retikül Mil-Dot, Dürbün üst kule 200 klik.
- [07](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/07_durbun_elle_duzenle.png?raw=true): Profili Düzenle. Dürbün markası "Benim Optik", Dürbün modeli "X5 Pro" ve diğer değerler korunmuş.

**Listeden seçim**

- [11](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/11_durbun_liste_dolu.png?raw=true): Kartın üstü. Marka Element Optics; Birim MOA | Odak düzlemi FFP; Tüp | Büyütme "Seçiniz"; Model "Titan 5-25x56 FFP MOA"; Üst kule 360 | 0 MOA. Seçili MOA ve FFP burada gri görünüyor; düzeltme `4a87dc1`'de.
- [12](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/12_durbun_liste_dolu_alt.png?raw=true): Kartın altı. Retikül APR-2D MOA; "Dürbün: Element Optics Titan MOA 5-25x56 FFP"; "Aradığın dürbün listede yok mu?".
- [13](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/13_durbun_liste_duzenle.png?raw=true) ve [14](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/14_durbun_liste_duzenle_alt.png?raw=true): Profili Düzenle. Aynı sıra; filtreler yerinde, "Seçiniz"; Model, Retikül, ayak ve üst kule korunmuş.

**Olmayanlar ve sorunlar**

- **Marka seçilmeden boş liste kartının görüntüsü yok.** Tur bu adıma görüntü işaretini koydu, ama Simulator görüntüsü geç alındı. 08–11 aynı kare çıktı (dolu liste kartı). Kapalı filtreler widget testinde sınanıyor; görüntüsü bu turda yok.
- Sondaki düzeltmelerle (`4a87dc1`) turu yeniden çalıştırma denemem iki kez iptal oldu. sim-screens iş akışında aynı anda yalnız bir çalışma bekleyebiliyor ve başka bir oturumun kuyruğa aldığı çalışma benimkinin yerini aldı. Bu yüzden son commit'in Simulator görüntüsü yok.


## CI

Son kod commit'i `4a87dc1` (bu rapor yalnız belge; iOS CI belge değişikliğinde çalışmıyor):

- `iOS CI` [run 38940995177](https://github.com/sniperTurk/flutter-app/actions/runs/38940995177):
  - `verify` **success**
  - `dart-checks` **success**
  - `wind-acceptance` **success**
  - `ios-simulator` atlandı (iş akışı ayarı)
- `flutter test` tüm paket, test-diag [run 38941380039](https://github.com/sniperTurk/flutter-app/actions/runs/38941380039): **success**
- `flutter analyze`, analyze-diag [run 38941383917](https://github.com/sniperTurk/flutter-app/actions/runs/38941383917): **success**
- Biçim, format-fix [run 38941000095](https://github.com/sniperTurk/flutter-app/actions/runs/38941000095): **success**, değişiklik gerekmedi.
- Simulator turu [run 38937057437](https://github.com/sniperTurk/flutter-app/actions/runs/38937057437) (`7abb3a3`): **success**
- Code Review: 3 ajan (CLAUDE.md + hata, yorumlar + geçmiş, güvenlik).
  - Gerçek bulunan 3 hata düzeltildi: modelli elle kayıt katalogla eşleşince modelin düşmesi, boş katalogda modelin okunmaması, 100 karakter sınırı.
  - Özette modeldeki "3-12x56" gibi ölçü kalıplarının silinmesi bilerek bırakıldı: ölçüler özette zaten ayrıca yazıyor.
- Security review: sorun bulunmadı.

TestFlight, Simulator dışı cihaz, imzalama ve App Store çalıştırılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01QtovsXdVyf4tUvteAngmB9
