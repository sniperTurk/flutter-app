# Bu paket ile yapılan düzeltmeler (denetim sonrası)

Bu ZIP, `SNIPER_TURK_V1_v78.zip` üzerine, bağımsız denetim raporunda (bkz. sohbet geçmişi)
onay verilen bulgular için yapılan **yalnızca statik kod düzeltmelerini** içerir.
**Hiçbir komut çalıştırılamadı** (bu ortamda flutter/dart toolchain yok, ağ kapalı) —
aşağıdaki değişikliklerin hiçbiri `flutter analyze`/`flutter test` ile doğrulanmadı.
Gerçek bir Flutter ortamında bu iki komutu ilk iş olarak çalıştırmanız gerekir.

## Düzeltilen dosyalar

### 1. `lib/features/ballistics/ballistics_screen.dart`
- **Gerçek bir null-safety hatası düzeltildi.** Orijinal dosyada `v` (namlu hızı,
  tipi `double?`) iki noktada `!` işareti olmadan `double` bekleyen parametrelere
  geçiriliyordu (`Atmosphere.machNumber(velocityMps:v,...)` ve
  `BallisticInput(muzzleVelocityMps:v,...)`), diğer tüm alanlar (`g!`, `z!`, `s!`
  vb.) doğru şekilde unwrap edilmişken. Bu **büyük ihtimalle `dart analyze`'da
  derleme hatası** olarak çıkardı; ilk denetimde toolchain olmadığı için
  yakalanamamıştı. Düzeltme: tüm sayısal alanlar null-kontrolünden sonra tek
  seferde non-nullable yerel değişkenlere bağlanıyor (`rawVelocity!` → `v`),
  böylece hem hata giderildi hem de aynı sınıf hatanın tekrarlanma riski azaldı.
- Dosya, önceki 2620 karakterlik tek satırdan çıkarılıp standart, okunabilir
  Dart biçimine getirildi. Mantık değiştirilmedi (whitespace-duyarsız diff ile
  doğrulandı); yalnızca yardımcı fonksiyon `f` → `_field` olarak yeniden
  adlandırıldı ve yerel değişkenler (`v,g,z,s,w,wd,temp,pres,hum,alt`) açık
  isimlerle (`rawVelocity`, `rawGrain`, ...) ayrıştırıldı.

### 2. `lib/features/profiles/profiles_screen.dart`
- Önceki 1669 karakterlik tek satırdan çıkarılıp standart Dart biçimine
  getirildi. Mantıkta hiçbir değişiklik yok (whitespace-duyarsız diff ile
  doğrulandı) — yalnızca biçimlendirme.

### 3. `lib/core/drag_table.dart`
- Docstring güncellendi. Eskisi "G1/G7 coefficient rows are intentionally NOT
  bundled here" diyordu; ama `standard_drag_tables.dart` bunları zaten
  bundle ediyor (v65'ten beri). Yorum artık gerçek durumu yansıtıyor.

### 4-7. Dört test dosyası gerçek widget testine dönüştürüldü
`test/accessibility_wiring_test.dart`, `test/ballistics_profile_gate_test.dart`,
`test/ballistics_environment_wiring_test.dart`, `test/ballistics_screen_wiring_test.dart`

Bunların hepsi eskiden **kaynak dosyayı `File(...).readAsStringSync()` ile okuyup
belirli bir string'in var olup olmadığını kontrol ediyordu** — widget hiç
render edilmiyordu. Bu, denetim raporunun "test kendi implementasyonunu
tekrar ederek sahte güven oluşturuyor mu?" sorusuna verdiği MEDIUM-HIGH bulguydu.
Ayrıca bu testler, `ballistics_screen.dart`'ın yeniden biçimlendirilmesiyle
(yukarıdaki 1. madde) zaten kırılacaktı, çünkü aradıkları tam string kalıpları
(`temperatureC:temp!` gibi) artık dosyada yok.

Şimdi bu 4 dosya gerçek `testWidgets` testleri: widget'ı `pumpWidget` ile
render ediyor, gerçek `TextField`/`DropdownButtonFormField`/buton etkileşimi
yapıyor, `tester.getSemantics(...)` ile gerçek semantics ağacını okuyor, ve
görüntülenen hava yoğunluğu değerinin sıcaklık/basınç/nem değiştikçe fiziksel
olarak doğru yönde değiştiğini doğruluyor (ör. sıcaklık artınca yoğunluk düşer).

## Bu pakette DÜZELTİLMEYEN, denetim raporunda kalan açık maddeler

Bunlar kapsam dışı bırakıldı çünkü ya veri uydurmayı gerektirirdi ya da bu
ortamda (araç/ağ erişimi olmadan) doğrulanamazdı. Denetim raporundaki
öncelik sırasına göre:

- **iOS scaffold hâlâ yok** (Info.plist, signing, AppIcon, Bundle ID). Bunu
  eklemek gerçek bir Apple Developer hesabı/signing kararı gerektirir, kod
  düzeltmesi değildir.
- **G1/G7 balistik motorunun bağımsız harici referansla (ör. py-ballisticcalc)
  doğrulanması yapılmadı** — bu ortamda ağ/paket kurulumu mümkün değil. Motor
  hâlâ production'a kapalı tutuluyor (doğru davranış).
- **`pubspec.lock` eklenmedi** — `flutter pub get` çalıştırılamadığı için
  gerçek, tutarlı bir lock dosyası üretilemez; sahte bir dosya yazmak yanıltıcı
  olur.
- **Kaynaksız 3 katalog kaydı** (`airmaks-krait-635`, `aea-challenger-pro-635`,
  ve manuel şablonlar) UI'da ayrı bir "placeholder" rozetiyle işaretlenmedi —
  bu bir veri modeli/UI tasarım kararı gerektiriyor, veri uydurmadan
  yapılabilir ama bu geçişte önceliklendirilmedi.
- **Light tema desteği eklenmedi** (`ThemeData.dark()` hâlâ tek tema) — LOW
  öncelikli, bilinçli olarak bu geçişe dahil edilmedi.
- **`home_screen.dart`** hâlâ uzun satırlar içeriyor (en uzun ~1000 karakter
  civarı) ama denetimde CRITICAL/HIGH olarak işaretlenen iki dosya (ballistics/
  profiles) kadar okunamaz değildi; bu geçişte dokunulmadı.
- **`flutter analyze` / `dart format` / `flutter test` hiçbiri çalıştırılamadı.**
  Bu, teslim etmeden önce mutlaka gerçek bir Flutter ortamında yapılması
  gereken bir adımdır — özellikle yukarıdaki null-safety düzeltmesinin
  gerçekten derlendiğini ve yeni testlerin gerçekten geçtiğini doğrulamak için.
