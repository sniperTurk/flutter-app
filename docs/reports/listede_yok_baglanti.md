# Profil: Tüfek ve Mühimmat için "… listede yok mu?" bağlantısı

Sahip kararı (2026-10-14 09:16 İstanbul, Profil Oluştur/Düzenle formu): "Olmayan dürbünü ekleme… bunun aynısını tüfekler için de yapalım" + "ikisi için de görev aç". Dürbün için PR #269'da yapılanın aynısı Tüfek ve Mühimmat Marka | Model için yapıldı.

## Ne değişti

- `lib/features/profiles/profiles_screen.dart`
  - **Tüfek** (`_rifleNameFields`): Marka listesindeki "Listede yok" maddesi gizlendi (silinmedi). Yeni bayrak: `bool.fromEnvironment('RIFLE_LISTEDE_YOK')`, varsayılan kapalı (`_showRifleListedeYok`).
  - Tüfek Marka | Model satırının altına bağlantı eklendi: Key `rifle-not-listed`, metin "Aradığın tüfek listede yok mu?".
  - Yeni yöntem `_openRifleManual()`: eski "Listede yok" seçiminin yaptığının aynısı (Model temizlenir, `_clearRifleChoice()`, `_keepAmmoInCaliber(before)`, `_rifleManual = true`, Marka temizlenir). Gizli madde de (bayrak açılırsa) bu yöntemi çağırır.
  - **Mühimmat** (`_ammoNameFields`): Marka listesindeki "Listede yok" maddesi gizlendi. Yeni bayrak: `bool.fromEnvironment('AMMO_LISTEDE_YOK')`, varsayılan kapalı (`_showAmmoListedeYok`).
  - Mühimmat Marka | Model satırının altına bağlantı eklendi: Key `ammo-not-listed`, metin "Aradığın mühimmat listede yok mu?".
  - Yeni yöntem `_openAmmoManual()`: `_clearAmmo(); _ammoManual = true;` (eski "Listede yok" ile aynı).
- `test/listede_yok_baglanti_test.dart` (yeni widget testleri).
- `test/support/rifle_form.dart`: `fillRifleForm` / `fillAmmoForm` artık "Listede yok" seçmek yerine bağlantıya dokunur; yeni ortak yardımcı `tapNotListed(tester, key)` (`openScopeManual` da bunu kullanır).
- `test/profile_lists_test.dart`, `test/profile_editor_fail_closed_test.dart`: "Listede yok" seçimi bağlantıya dokunmaya çevrildi.
- `integration_test/sim_screens_test.dart`, `integration_test/sim_screens_paralaks_mpbr_test.dart`, `integration_test/app_launch_test.dart`: Tüfek Marka listesinden "Listede yok" seçen adımlar `rifle-not-listed` bağlantısını kullanır (Simülatörde alt çubuk bağlantıyı örtebildiği için, dürbün bağlantısında olduğu gibi `onPressed` doğrudan çağrılır).

## Bağlantılar nasıl çalışır

- Görünüm dürbün bağlantısının aynısı: tam genişlikte ayrı bir satır (`MenzilFullWidth`), içinde sola hizalı (`Alignment.centerLeft`) bir `TextButton`. Alan altı yardım metni değildir; iki kutu bir satır kuralı bozulmaz.
- **Tüfek**: bağlantı yalnız tüfek listeden seçilirken görünür (yazı kipinde değilken ve Marka listesinde en az bir marka varken). Dokununca yazı kutuları (`rifle-brand`, `rifle-model`) boş açılır, bağlantı kaybolur; yerine mevcut "Listeden seç" (`rifle-back-to-list`) görünür.
- **Mühimmat**: bağlantı yalnız Mühimmat Marka listesi gösterilirken görünür. Dokununca `ammo-brand` / `ammo-model` boş açılır, bağlantı kaybolur; mevcut "Listeye dön" (`ammo-back-to-list`) görünür.

## Neden

Sahip dürbünde uyguladığı düzeni (#269) Tüfek ve Mühimmat için de istedi: "Listede yok" uzun listenin sonunda kayboluyordu; bağlantı her zaman görünür ve ne işe yaradığını söyler. Madde "gizle, silme" kuralıyla bayrak arkasına alındı.

## Uç durumlar

- **Boş marka listesi**: Tüfek listesi boşsa veya Mühimmat listesi bu kalibre için boşsa yazı kutuları zaten açıktır (`_rifleManual || brands.isEmpty`, `_ammoManual || empty`); bağlantı bu dallarda hiç çizilmez.
- **Düzenleme, elle yazılmış tüfek/mühimmat**: Açılış mantığı değişmedi (`_rifleManual = !known`, `_ammoManual = !inFactory && !inLibrary`). Profil yazı kipinde açılır, kayıtlı değerler kutularda durur, bağlantı görünmez; "Listeden seç" / "Listeye dön" ile listeye dönülür, dönünce bağlantı yeniden görünür.
- **Tür değişimi (PCP / Ateşli)**: Mühimmat temizlenir (`_clearAmmo()` `_ammoManual`'ı da kapatır), yani liste ve bağlantı geri gelir. Elle yazılmış tüfek önceki gibi yazı kipinde kalır; listeden seçilmiş tüfek temizlenir ve bağlantı görünür kalır. Bu davranış değişmedi.
- **PCP mühimmat**: PCP'de Mühimmat Marka | Model şu an gizli (`PCP_AMMO_BRAND` kapalı, 2026-10-13). Marka listesi olmadığı için bağlantı da yoktur. Bayrak açılırsa aynı kod yolu (`_ammoNameFields`) PCP'de de bağlantıyı gösterir.
- **Yazılmış tüfekten sonra Kalibre değişimi**: Tüfek yazı kipinde kalır, yazılan Marka korunur; mühimmatın kalibreye göre tutulması (`_keepAmmoInCaliber`) değişmedi.
- **Yazılan değerler yereldir**: Elle girilen tüfek/mühimmat yalnız kullanıcının kaydına gider; paylaşılan listelere (rifle_library, factory_ammo_library, bullet_library) dokunulmadı.

## Bilerek değiştirilmeyenler

- Kalibre listesindeki "Fişeğim listede yok" maddesi (mermi çapına göre kalibre) yerinde.
- Dürbün formu ve bağlantısı (`scope-not-listed`).
- Yazı kipindeki diğer alanlar (Yiv oranı, Yiv yönü, Sight height, Namlu çıkış hızı, Kalibre, Tip, Ağırlık, BC alanları ve ⓘ açıklamaları).
- Diğer sayfalar.

## Hangi test neyi kapsar (`test/listede_yok_baglanti_test.dart`)

- `Ateşli` / `PCP: rifle Marka has no "Listede yok"; the link types`: Tüfek Marka listesinde madde yok; yeni formda `rifle-not-listed` görünür ve metni doğru; dokununca Marka/Model yazı kutuları boş, bağlantı yok, "Listeden seç" var.
- `Ateşli: ammo Marka has no "Listede yok"; the link types`: Mühimmat için aynısı; Tür PCP→Ateşli değişince liste ve bağlantı geri gelir.
- `PCP: no ammo Marka list (PCP_AMMO_BRAND off), so no link`.
- `typed rifle keeps its typed mode after a Kalibre change`.
- `Kalibre keeps "Fişeğim listede yok"`.
- `the scope link still opens the typed scope`.
- `Profili Düzenle: a typed rifle and ammunition open in typed mode` (geri dönüş yolu dahil).
- Mevcut testler (`profile_lists_test`, `profile_editor_fail_closed_test`, `profile_origin_edit_test`, `scope_form_sade_test` ve `fillRifleForm` / `fillAmmoForm` kullanan bütün testler) bağlantı üzerinden geçer.

## Doğrulama

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (326 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test OK.
- Bu ortamda Flutter SDK yok; `tools/claude_flutter_verify.sh` yerelde çalıştırılmadı (BLOCKED: SDK yok). Flutter doğrulaması aşağıdaki GitHub Actions koşularıyla yapıldı.
- CI (dal `fix/listede-yok-baglanti`):
  - Biçim (dart format): https://github.com/sniperTurk/flutter-app/actions/runs/38521605372 → success (format commit'i `9c30aed` dala çekildi).
  - `flutter test` (bütün `test/`): https://github.com/sniperTurk/flutter-app/actions/runs/38521695476 → success (çıkış kodu 0). Notlardaki "KESIK" ve yığın satırları geçen testlerin yazdırdığı çıktılardır; iş çıkış koduyla başarılı bitti.
  - `flutter analyze`: https://github.com/sniperTurk/flutter-app/actions/runs/38521698416 → success.
- PR #288 üzerinde `iOS CI` (commit `51098a7`): https://github.com/sniperTurk/flutter-app/actions/runs/38522412275 → `verify`, `dart-checks`, `wind-acceptance` success; `ios-simulator` işi **atlandı (skipped)**, yani Simülatör derlemesi ve integration_test koşmadı; geçti denmez. TestFlight yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
