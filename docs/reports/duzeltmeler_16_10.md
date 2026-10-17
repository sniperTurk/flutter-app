# Düzeltmeler 16.10.2026 — kod

Dal: `fix/duzeltmeler-16-10` · Taslak PR #370 (birleştirilmedi, TestFlight yok).
Güncel main'e (eee7673: #369 kule klik sayımı, #372 "Hava" başlığı silindi, #373 Pro kutularında ⓘ yok, #371 yan kule konumu) yeniden dayandırıldı (rebase, 17.10.2026). Çakışma çıkmadı; main'deki kararlar korundu.
Tasarım: PR #366, `design/duzeltmeler-16-10` dalı, `docs/design/duzeltmeler-2026-10-16/README.md` + `png/`.

## Sahibin kararı (İstanbul)
- 16.10.2026 20:06 tasarım PR #366 için: "onayladım". "Sonra" çizimleri ve README'nin "Dokunulacak kod" bölümleri uygulandı.
- 20:07, 5. madde değişti: "Profil seçici select diğer selectler gibi açılacak." #366'daki özel kart/gölge/sarı ✓ liste yapılmadı; uygulamadaki her açılır kutunun (MenzilSelect) listesi kullanıldı.
- 21:17 (#373, main'de): Pro'da açılan bölümlerdeki kutuların kendi ⓘ'su yok; açıklamaları bölüm başlığının ⓘ sayfasında. Bu PR'ın Pro'ya taşıdığı Mühimmat sıcaklığı kutusu da buna uyar.
- Açık sorular: Hedef klik satırı kaydırıcının altında tek satır; Pro "N ayar açık" özeti girilen Mühimmat sıcaklığını sayar; liste köşesi diğer select'lerle aynı.

## Ne yapıldı
1. **Profil ekle:** sabit 148 pt genişlik kalktı (`SizedBox(width: _addButtonWidth)` silindi). Düğme yazısı kadar geniş, iki yanda 16 pt dolgu (`MenzilPrimaryButton(expand: false)`). Yükseklik, sarı renk ve yeri (Profiller satırının sağ ucu) aynı.
2+3. **Mühimmat sıcaklığı:** Hava Durumu'ndaki bölüm silindi (başlık, ⓘ, "isteğe bağlı", kart). Aynı kutu Pro Ayarlar > Tüfek düzeltmeleri içinde, Mermi uzunluğu'nun altında ve barut katsayısı yazısının üstünde: kutu satırın sol yarısında, "isteğe bağlı" sağ yarısında, kutunun ortasıyla aynı hizada. Yalnız ateşli silahta. Kutunun içinde ⓘ yok (#373); aynı açıklama metni (`EnvironmentFieldInfo.ammoTemperature`, kelimesi kelimesine aynı) Tüfek düzeltmeleri başlığındaki ⓘ'nin alttan açılan sayfasında "Mühimmat sıcaklığı" satırı olarak duruyor (`ProInfoField`). "isteğe bağlı" yazısının yüksekliği en az kutu kadar; çok büyük yazıda iki satıra inerse kutu uzar, yazı kesilmez. Kutu kapalıyken "N ayar açık" özeti girilmiş bir değeri sayar.
4+6. **Hedef:** #330'un büyük "Üst kule / Yan kule" satırı kalktı. Yerine kaydırıcının hemen altında tek satır: `▌Üst kule 39 klik yukarı   ▌Yan kule 4 klik sağ`. Sayılar 15 pt yarı kalın (eşit genişlikte rakam), yazılar 12,5 pt gri, sarı ve mavi sol çizgi aynı. Satır hiç iki satıra inmez; dar ekranda yazı küçülür (`FittedBox`). Rüzgâr yoksa "Yan kule 0 klik rüzgâr yok". Üst boşluk 6 → 2 pt.
5. **Üst çubuk profil seçici:** düğmenin kendisi değişmedi. Dokununca açılan liste, uygulamadaki her MenzilSelect listesiyle aynı yoldan açılır: aynı açılış (`_MenzilMenuRoute`), aynı yerleşim (`_MenzilMenuLayout`: düğmenin 4 pt altında, düğme eninde), aynı yüzey rengi, çerçeve, köşe, satır yüksekliği, yazı ve açılış animasyonu. Seçili satır işareti yok (diğer select'lerde de yok). Her satırda profil adı ve kalibresi, Profil > Kalibre listesindeki gibi: ad solda, 12 pt kalibre aynı satırın sağ ucunda (Kalibre listesindeki mm gibi); sığmazsa ad alt satıra iner ve kalibre altına geçer, hiçbir şey "…" ile kesilmez.

## Nasıl
- `lib/ui/menzil_widgets.dart`: MenzilSelect'in liste açma kodu yeni, küçük ve herkese açık `MenzilSelectMenu<T>` sınıfına taşındı (`closeKeyboard`, `show`, `close`, `metricsChanged`). MenzilSelect bunu kullanıyor; davranışı aynı (klavye önce kapanır, yer yoksa sayfa yukarı kayar, dönme/pencere değişince liste kapanır). Rota, yerleşim ve liste çizimi (`_MenzilMenuRoute`, `_MenzilMenuLayout`, `_DropdownMenu`) özel kaldı ve tek yerde.
- `lib/features/home/home_screen.dart`: düğmeyi çizen `DropdownButtonFormField` aynen duruyor (yerel `field` değişkeninde; `tools/test_v299_no_deprecated_dropdown_value.py` anahtar satırını tek satır olarak arıyor) (düğme piksel piksel aynı kalsın diye), yalnız dokunuşu artık o almıyor (`AbsorbPointer`); üstteki dokunma `MenzilSelectMenu.show` ile listeyi açar. Seçim `_choose` ile, kayıt hatasında eskisi gibi önceki profile döner. VoiceOver: tek düğme, adı "Aktif tüfek profili", değeri "Ateşli 308 7,62 mm"; çift dokunuş aynı listeyi açar.
- `lib/features/profiles/profiles_screen.dart`: sabit genişlik ve sabiti silindi, `expand: false`. Çok büyük iOS yazı boyunda düğme satırın en fazla yarısını alır ve yazı tek satırda küçülür (aşağıda "Uç durumlar").
- `lib/features/ballistics/hava_durumu_view.dart`: bölüm silindi. `pro_ayarlar_view.dart`: satır (kutu `info:` olmadan), `ProInfoField`, özet sayımı eklendi. Kayıt anahtarı (`ammoTemp` / `ammoTempText`), denetleyici (`ammoTempCtl`), kutu anahtarı (`env-ammo-temp`), birim (°C; ABD birimlerinde °F, önceki gibi) ve hesap değişmedi.
- `lib/features/ballistics/scope_results.dart` (`TurretSolutionRow.build`) ve `hedef_view.dart` (üst boşluk). Anahtarlar (`hedef-turret-solution`, `hedef-solution-elevation`, `-windage`), sayılar (`requiredUp` / `requiredRight`) ve VoiceOver cümlesi ("Üst kule 39 klik, 3,9 MRAD yukarı") aynı. Dürbünün altındaki "Kule: … (… MRAD)" satırı duruyor; o satır kulede kurulu olanı gösterir, "Kuleleri kur"dan sonra gereken değerle aynıdır (tasarım README'deki gibi). Gereken açı kurulmadan önce yalnız VoiceOver'da okunur.

## Neden
Sahibin TestFlight 110 incelemesindeki 6 madde ve onaylanan tasarım. Liste için sahibin 20:07 sözü: diğer select'lerle aynı açılsın. Mühimmat sıcaklığı kutusunda ⓘ olmaması için sahibin 21:17 kararı (#373): "zaten başlıklarda info var".

## Uç durumlar
- **Kayıtlı Mühimmat sıcaklığı:** eski sürümde Hava Durumu'nda girilen değer aynı anahtardan Pro'daki kutuya yüklenir ve hesaba aynen girer (test: main'den okunan sayılarla birebir eşit).
- **PCP:** Mühimmat sıcaklığı hiçbir sayfada yok (önceki gibi).
- **Boş Mühimmat sıcaklığı:** hava sıcaklığı kullanılır (önceki gibi).
- **Profil ekle, çok büyük yazı:** düğme yazı kadar büyür ama satırın en fazla yarısı kadar; ondan sonra yazı tek satırda küçülür. Bu sınır olmadan iPhone 15 ve ×2 yazıda Profil satırı 5 pt taşıyordu (`menzil_layout_extremes_test`). Normal ve ×1,3 yazıda sınıra ulaşılmaz.
- **Profil listesi, kısa aktif ad:** liste düğmeden geniş olamaz (CLAUDE.md), bu yüzden "bbbbb" aktifken liste dar olur; uzun adlar kesilmez, birkaç satıra iner (UST-1). Uzun liste kaydırılır.
- **Profil listesi, klavye açıkken:** önce klavye kapanır, sonra liste açılır (diğer select'ler gibi).
- **"isteğe bağlı", 320 pt ve ×2 yazı:** iki satıra iner, satır uzar, kesilmez (inceleme bulgusu üzerine düzeltildi).
- **Hedef, 320 pt ve ×1,3:** klik satırı iki satıra inmez, taşmaz; yazı biraz küçülür.
- **Hedef, 0 klik:** yön yazılmaz ("Üst kule 0 klik"); rüzgâr girilmemişse "Yan kule 0 klik rüzgâr yok".

## Bilerek yapılmayan
- #366'daki 5. madde çizimi (kart, 16 pt köşe, gölge, sarı ✓, sarımsı satır): sahip 20:07'de değiştirdi.
- Hesap, formül, kayıt anahtarı, ⓘ metinleri değişmedi. Hava Durumu'nun diğer bölümleri, Hedef'te dürbün, kuleler, L-R, "Kuleleri kur/sıfırla", DOPE PDF değişmedi.
- `profile_editor_scope.dart` ve `profile_editor_ammo.dart`'a dokunulmadı (başka görevler).
- Üst çubuktaki düğmenin kendisi (genişlik, ad kısaltma, kalibre) değişmedi.
- Yeni bağımlılık yok.

## Testler
Yeni `test/duzeltmeler_16_10_test.dart` (Inter yazı tipiyle, iPhone güvenli alan boşluklarıyla):
- Profil ekle: 320 ve 390 pt, ×1,0 ve ×1,3: eni < 148, yazı tam boyutta ve tek satır, iki yanda 16 ± 0,5 pt, yükseklik 46–48, sağ uçta; ×2'de taşma yok.
- Mühimmat sıcaklığı: kayıtlı "35" ve "" Pro'daki kutuya yüklenir; 600 m üst kule `requiredUp` main'deki sayılarla **birebir** eşit (5,245725605337864 ve 5,529980691211749 MRAD; main e7b29bf üzerinde aynı adımlarla okundu); Pro'da yazınca da aynı.
- Hedef: 390×844'te kaydırma yok, klik satırı kaydırıcının ≤ 2,5 pt altında, 22 pt yüksek, dürbünün tamamı alt menünün üstünde; 34 pt sayı yok. 320 pt ×1,0 / ×1,3 satır tek satır, ekran içinde.
- Profil listesi: açılan listenin rotası `_MenzilMenuRoute` (MenzilSelect'inkiyle aynı), yüzey rengi, gölge, çerçeve/köşe, yazı boyu/ağırlığı/rengi ve satır yüksekliği açılmış bir MenzilSelect ile **eşit**; liste düğmenin 4 pt altında, solu düğmeyle aynı, eni ≤ düğme eni; satırlarda ad + "6,35 mm"; seçim aktif profili değiştirir. Uzun adlar (390, 320, 320 ×1,3): tam yazılır, "…" yok, satırlar üst üste binmez, alt satıra dokunmak o profili seçer. VoiceOver: tek düğme, ad + değer, çift dokunuş aynı listeyi açar.

Güncellenen testler (gevşetilmedi; yeni yerleşime göre):
- `muhimmat_sicakligi_bolum_test.dart`: Hava Durumu'nda yok; Pro Tüfek düzeltmeleri'nde yeri (Mermi uzunluğu ile barut yazısı arası, sol yarı / sağ yarı, aynı hiza); kutuda ve satırda ⓘ yok (`info` boş, `MenzilInfoButton` yok); başlık ⓘ sayfasında "Mühimmat sıcaklığı" bir kez ve metni `EnvironmentFieldInfo.ammoTemperature` ile birebir aynı; PCP'de yok, özet sayımı, kayıtlı değer, 320/390 ×1,3 taşma yok; yeni: 320 pt ×2 yazıda "isteğe bağlı" satırları kadar yüksek ve kesilmiyor.
- `ammo_temperature_test.dart`: aynı hesap testleri kutu Pro'da iken.
- `pro_tufek_ozet_sayim_test.dart`: Mühimmat sıcaklığı girilince "3 ayar açık", silinince "kapalı".
- `pro_info_popup_test.dart` (#373 sürümü): ateşli silahta Tüfek düzeltmeleri başlık sayfasının alan listesine "Mühimmat sıcaklığı" eklendi; #373'ün "açık bölümde hiçbir kutuda ⓘ yok" kontrolü bu kutuyu da kapsıyor ve geçiyor.
- `hedef_sonuc_ustte_test.dart`: tek satır metni, VoiceOver cümlesi (aynı), renkler, 12,5 / 15 pt.
- `scope_dial_drag_test.dart`, `scope_dial_view_test.dart`: "klik sol / klik yukarı" artık iki yerde (klik satırı ve dürbün altı); ikisi ayrı ayrı aranıyor.
- `audit_2026_10_15b/hedef_split_audit_test.dart`: ok düğmelerinin 44 pt kontrolü dikdörtgen farkı yerine kutunun kendi boyutuyla yapılıyor (aşağıda kayan nokta 43,99999999999994 veriyordu; eşik aynı 44).
- `integration_test/chrono_screens_test.dart`: Mühimmat sıcaklığı adımı Pro'ya taşındı.
- `integration_test/duzeltmeler_16_10_screens_test.dart` (ekran turu): başlık ⓘ sayfasının görüntüsü eklendi; 390 pt karelerinin donmaması için tur başında piksel oranı iki kez değiştiriliyor; her kare 10 sn tutuluyor; profil seçimi açık listedeki satıra dokunuyor.
- `test/support/pro_sections.dart`: `env-ammo-temp` Tüfek düzeltmeleri kutusunda.

Yerel (rebase sonrası): `python3 tools/offline_dart_lint.py` → PASS (413 Dart dosyası, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlandı). Bu ortamda Flutter SDK indirilemedi (storage.googleapis.com engelli); `flutter analyze` / `flutter test` / `dart format` yalnız CI'da çalıştı (aşağıda).

## Ekran görüntüleri (tasarımla yan yana)
iOS Simulator, iPhone 17 Pro / iOS 26.2, `sim-screens` iş akışı, tur `integration_test/duzeltmeler_16_10_screens_test.dart`. Uygulama 390 pt ve 320 pt genişlikte çizildi (Simulator penceresi aynı, yalnız piksel oranı değişti; yükseklik pencereden: 390 × 848 ve 320 × 696 pt). Solda onaylanan tasarım (`design/duzeltmeler-16-10`, `docs/design/duzeltmeler-2026-10-16/png/*-sonra*.png`), sağda uygulama.

- 390 pt ve 320 pt'nin ilk 17 karesi: çalışma [38985574098](https://github.com/sniperTurk/flutter-app/actions/runs/38985574098), dal ucu `0acf9f4` (güncel main üstünde), 20 adımın hepsi geçti (`flutter test exit: 0`).
- 320 pt Pro başlık sayfası, Hedef ve Kalibre listesi: aynı çalışmada bu üç kare bir adım geç çekildi (bir sonraki ekranı gösteriyordu), bu yüzden bir önceki çalışmadan [38984305294](https://github.com/sniperTurk/flutter-app/actions/runs/38984305294) alındı: dal ucu `4575d71`, #371 main'e girmeden önceki uç. Bu PR'ın kodu iki uçta aynı; tek fark #371'in yan kule konumu (bu karede yan kule birkaç pt solda görünür). Ölçülen dikdörtgenler (SIMRECT) iki çalışmada birebir aynı.
- Ham görüntüler: `ci/sim-screens` dalı, commit `53862f2` ve `88ac134`, klasör `latest/`.

**Profil (Profil ekle)**
![Profil 390](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/profil_390.png?raw=true)
![Profil 320](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/profil_320.png?raw=true)

**Pro Ayarlar > Tüfek düzeltmeleri açık, sağda başlık ⓘ sayfası**
![Pro 390](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/pro_390.png?raw=true)
![Pro 320](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/pro_320.png?raw=true)

**Hava Durumu (üst kısım)**
![Hava 390](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/hava_390.png?raw=true)
![Hava 320](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/hava_320.png?raw=true)

**Hedef (tüm ekran)**
![Hedef 390](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/hedef_390.png?raw=true)
![Hedef 320](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/hedef_320.png?raw=true)

**Üst çubuk profil listesi, açılmış bir standart select (Profil Oluştur > Kalibre) ile yan yana**
![Liste 390](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/secici_390.png?raw=true)
![Liste 320](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/secici_320.png?raw=true)

**Profil listesi, kısa ve uzun aktif ad (tasarımla)**
![Kısa 390](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/secici_kisa_390.png?raw=true)
![Kısa 320](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/secici_kisa_320.png?raw=true)
![Uzun 390](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/secici_uzun_390.png?raw=true)
![Uzun 320](https://github.com/sniperTurk/flutter-app/blob/fix/duzeltmeler-16-10/docs/reports/duzeltmeler_16_10/secici_uzun_320.png?raw=true)

### Görülen farklar (tasarım ↔ uygulama)
Her ekranda: tasarımdaki örnek veriler (profil adları, 7,82 mm, kutulardaki 18 / 55 / 1013,2 / 31,2 gibi değerler, 300 m) uygulamada yok; tur kendi deneme profillerini (Ateşli 308, Tikka T3x… ana namlu, bbbbb; 7,62 mm) ve boş kutuları kullanıyor. Durum çubuğu Simulator'ünki.

- **Profil:** Profil ekle yazı kadar geniş (108 pt; 390'da x 268–376, 320'de x 198–306), sağ uçta, sarı, 48 pt yüksek; tasarımla aynı. Görünür düzen farkı yok.
- **Pro Ayarlar:** Mühimmat sıcaklığı, Mermi uzunluğu'nun altında, kutu sol yarıda, "isteğe bağlı" sağda, kutuyla aynı hizada (tasarımla aynı). Farklar: (1) tasarımda her kutunun içinde ⓘ var, uygulamada hiçbir kutuda yok; bu #373 sahip kararı (tasarımdan sonra). Mühimmat sıcaklığının açıklaması başlık ⓘ sayfasında görülüyor (sağdaki kare). (2) Tasarımdaki "Hava Durumu'ndan taşındı" kesik çerçeve ve etiketi yalnız tasarım notu, uygulamada yok. (3) Tasarımdaki "Bugünkü hız: 2629 fps (profil 2640 fps)" satırı uygulamada yok; bu satırı bu PR değiştirmedi, turda sıcaklık girilmediği için çıkmıyor. (4) Uygulamada altta "Hedef'e geç" düğmesi görünüyor (main'de zaten var; tasarım karesi oraya kadar inmiyor).
- **Hava Durumu:** Mühimmat sıcaklığı bölümü yok (tasarımla aynı). Fark: tasarımda kartın üstünde "Hava" başlığı var, uygulamada yok; bu #372 sahip kararı (tasarımdan sonra).
- **Hedef:** büyük klik satırı yok; kaydırıcının 2 pt altında tek satır (22 pt yüksek), sarı ve mavi sol çizgili. 390 pt'de dürbünün tamamı alt menünün üstünde, kaydırma yok (dürbün alt kenarı 716, alt menü üstü 754 pt). Farklar: (1) tur 100 m'de (sıfır mesafesi) olduğu için "Üst kule 0 klik / Yan kule 0 klik rüzgâr yok" yazıyor; tasarım 300 m'de "39 klik yukarı / 4 klik sağ" gösteriyor. (2) Sağdaki "Yan kule 0 klik rüzgâr yok" yazısı soldakinden görünür biçimde küçük: satırın yarısına sığmadığı için tek satırda kalsın diye küçülüyor (`FittedBox`); tasarımda iki yarı aynı boyda. Rüzgâr girilince yazı kısalır ("4 klik sağ") ve bu küçülme azalır ya da kalkar. (3) 320 pt'de (696 pt yükseklik) dürbünün alt kısmı alt menünün arkasında kalıyor (dürbün alt kenarı 635, alt menü üstü 608 pt); tasarımın 320 çizimi de dürbünü alttan kesik gösteriyor.
- **Profil listesi:** #366'nın kartı, gölgesi, sarı ✓ işareti ve kalın yazısı yok; sahip 20:07'de "diğer selectler gibi açılacak" dedi. Liste, yandaki Kalibre listesiyle aynı yüzey, çerçeve, köşe, yazı ve satır yüksekliğiyle açılıyor; ad solda, kalibre sağda (Kalibre listesindeki mm gibi). Liste düğmenin 4 pt altında, düğmeyle aynı genişlikte (390: x 172–376; kısa adda düğme 175 pt, uzun adda 227 pt). Farklar: (1) seçili satır işaretli değil (diğer select'lerde de değil). (2) 320 pt'de liste 157 pt dar olduğundan "Ateşli 308" satırında da kalibre adın altına iniyor; tasarımda yanında. (3) Uzun ad tasarımda "…" ile kesilmiş, uygulamada kesilmeden alt satıra iniyor (CLAUDE.md: kesilmez, sarar). (4) Liste açıkken "Profil ekle" düğmesinin üstünü örtüyor (diğer select listeleri de altındakini örter).

## Kod incelemesi ve güvenlik incelemesi
Rebase sonrası fark (`main...fix/duzeltmeler-16-10`) üzerinde yapıldı; sonuç PR'a yorum olarak yazıldı.
- Kod incelemesi: tek bulgu (düşük): 320 pt ve ×2 yazıda "isteğe bağlı" sabit 46 pt kutuda ikinci satırı kesiliyordu. Düzeltildi (en az 46 pt, gerekirse uzar) ve test eklendi. Kayıtlı değerlerin yüklenmesi, hesap, profil listesinin boş liste / seçim sürerken / döndürme durumları, ⓘ kuralı, ölü kod ve test gevşetme denetlendi; sorun yok.
- Güvenlik incelemesi: bulgu yok (kayıt biçimi, ayrıştırma, ağ, günlük değişmedi; profil adı yalnız `Text` ve VoiceOver değeri olarak gösteriliyor).

## CI
Kod içeren son commit `0acf9f4` (güncel main eee7673 üstünde), iOS CI çalışması [38985570886](https://github.com/sniperTurk/flutter-app/actions/runs/38985570886):
- `dart-checks`: başarılı ([iş](https://github.com/sniperTurk/flutter-app/actions/runs/38985570886/job/117256201626)): biçim, `flutter analyze`, tüm birim ve widget testleri.
- `wind-acceptance`: başarılı ([iş](https://github.com/sniperTurk/flutter-app/actions/runs/38985570886/job/117256201339)).
- `verify`: başarılı ([iş](https://github.com/sniperTurk/flutter-app/actions/runs/38985570886/job/117260267519)): Python regresyon takımı, G1/G7 kapısı, bağımsız çözücü karşılaştırması, iOS Simulator derlemesi ve açılış duman testi, imzasız cihaz derlemesi ve App Store arşivi.

Rebase'den önceki uç `26b0169` üzerinde de üçü başarılıydı: [38965299625](https://github.com/sniperTurk/flutter-app/actions/runs/38965299625). Bu rapor ve görüntülerin eklendiği son commit yalnız belge ve PNG içeriyor; onun CI sonucu PR'ın Checks sekmesinde. Simulator, TestFlight, cihaz, imzalama denenmedi; yalnız yukarıdaki ekran turu Simulator'de çalıştı.

## Notlar
- Önceki oturumda bir başkasının bekleyen "Simulator screenshots" çalışması (38941387154) o oturumun başlattığı çalışma yüzünden iptal olmuştu; sahibi yeniden başlatmalı. Bu oturumda hiçbir çalışma iptal edilmedi; bu oturumun bir çalışması (38967011983) başka bir oturumun gönderdiği çalışma yüzünden iptal oldu.
- Ekran turunun ilk denemesinde (38976003488) 390 pt karelerinin hepsi aynı Profil karesini gösterdi; ikinci denemenin ilk koşusunda uygulama açılış ekranında kaldı ("No tests ran", altyapı), tekrarında profil seçimi adımları satırı bulamadı. Tur düzeltildi; kullanılan görüntüler yukarıdaki iki başarılı çalışmadan.
- Sayıları main'den okumak için daha önce açılan geçici `probe/ammo-golden-16-10` dalı GitHub'da duruyor; bu ortamdan dal silme izni yok, silinebilir.

---
_Generated by [Claude Code](https://claude.ai/code)_
