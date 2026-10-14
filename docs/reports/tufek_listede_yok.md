# Tüfek: "Aradığın tüfek listede yok mu?" bağlantısı

Sahip kararı (2026-10-14 09:23, Profil Oluştur/Düzenle): "Tüfek için aç, ateşli ve PCP olarak."
Dürbün için PR #269'da yapılanın aynısı, yalnız Tüfek Marka | Model için yapıldı.

## Ne değişti

- Dosya: `lib/features/profiles/profiles_screen.dart`, `_rifleNameFields()`.
- Tüfek Marka listesindeki "Listede yok" maddesi gizlendi, silinmedi. Yeni bayrak:
  `bool.fromEnvironment('RIFLE_LISTEDE_YOK')`, varsayılan kapalı
  (`--dart-define=RIFLE_LISTEDE_YOK=true` ile geri gelir).
- Marka | Model satırının altına, tam genişlik bir satırda, sola hizalı bir bağlantı eklendi:
  anahtar `Key('rifle-not-listed')`, yazı "Aradığın tüfek listede yok mu?".
  Dürbündeki `scope-not-listed` ile aynı bileşen (`TextButton`) ve aynı stil.
- Yeni yardımcı `_openRifleManual()`: eski "Listede yok" seçiminin yaptığının aynısını yapar.
  Gizli "Listede yok" maddesi (bayrak açılırsa) de bu yardımcıyı çağırır.

## Bağlantı nasıl çalışıyor

- Tüfek listeden seçilirken (yazarak giriş açık değilken) ve Marka listesi boş değilken görünür.
  Ateşli ve PCP için aynı.
- Dokununca: `_rifleManual = true`, Marka ve Model temizlenir, `_clearRifleChoice()` listeden gelen
  kalibre/varyant seçimini boşaltır, `_keepAmmoInCaliber` kuralı eskisi gibi çalışır
  (kalibre değiştiyse listeden seçilmiş mühimmat gider, yazılmış mühimmat kalır).
- Yazarak girilen Marka ve Model kutuları boş açılır; bağlantı kaybolur.
  Altta mevcut "Listeden seç" (`rifle-back-to-list`) geri dönüş yolu aynen çalışır; dönünce bağlantı yeniden görünür.

## Neden

Sahip, dürbünde olduğu gibi tüfekte de "Listede yok" maddesinin uzun listenin sonunda kaybolmasını
istemiyor; yazarak girişin açık bir bağlantıdan açılmasını istiyor. Kural "gizle, silme": madde bayrakla saklı.

## Kenar durumlar

- Boş Marka listesi: yazılı kutular zaten gösteriliyor; bağlantı ve "Listeden seç" görünmez (değişmedi).
- Düzenleme, yazılmış tüfek: kayıtlı profil eskisi gibi yazarak giriş modunda açılır
  (`_rifleManual = !known`); bağlantı görünmez, "Listeden seç" görünür.
- Ateşli/PCP geçişi: mevcut mantık değişmedi. Listeden seçilmiş tüfek giderek bağlantı yeniden görünür;
  yazılmış tüfek yazarak giriş modunda kalır, bağlantı görünmez.
- Yazılmış tüfekten sonra kalibre değişikliği: Kalibre listesi ve `_keepAmmoInCaliber` kuralı aynen çalışır;
  seçilen kalibre yazılmış tüfekte kalır.

## Bilerek değiştirilmeyenler

- Mühimmat bölümü (Marka listesindeki "Listede yok" maddesi dahil).
- Kalibre listesi ve "Fişeğim listede yok" maddesi, Mermi çapı, Yiv oranı, Yiv yönü, Sight height,
  Namlu çıkış hızı, `_velocityCaliberRow`, ⓘ metinleri, satır düzeni.
- Dürbün formu ve diğer sayfalar.
- Yazılmış tüfekler eskisi gibi yalnız kullanıcıda kalır.

## Testler

- Yeni: `test/rifle_not_listed_test.dart` (Ateşli ve PCP):
  - Marka listesinde "Listede yok" yok; `rifle-not-listed` yeni formda Model'in altında, solda; `scope-not-listed` duruyor.
  - Bağlantı boş Marka/Model kutularını açar, bağlantı kaybolur; "Listeden seç" ile geri gelir.
  - Kayıtlı yazılmış tüfek düzenlemede yazarak giriş modunda açılır.
  - PCP: listeden seçilmiş tüfek (Hatsan Hercules) ve kalibresi bağlantıyla gider; sonra seçilen kalibre kalır.
  - Ateşli: Tikka T3x TACT A1 ve listeden seçilmiş mühimmat, bağlantıyla eskisi gibi temizlenir.
  - Ateşli: Mühimmat Marka listesinde "Listede yok" hâlâ var.
  - PCP: yazılmış tüfek kaydedilir ve tekrar açılınca yazarak giriş modunda gelir.
- Güncellenen: `test/support/rifle_form.dart` (yeni `openRifleManual`), `test/profile_lists_test.dart`,
  `integration_test/sim_screens_test.dart`, `integration_test/sim_screens_paralaks_mpbr_test.dart`,
  `integration_test/app_launch_test.dart` (rifle "Listede yok" adımları bağlantıya çevrildi).

## Doğrulama

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test OK.
- Yerel Flutter SDK kurulamadı (Flutter arşiv indirmesi proxy tarafından 403 ile engellendi): yerel
  `flutter analyze` / `flutter test` ÇALIŞMADI (BLOCKED). Doğrulama CI'da yapıldı:
- CI çalıştırmaları (hepsi `fix/tufek-listede-yok`, commit `1d87dae`; doğrulandı):
  - Format: https://github.com/sniperTurk/flutter-app/actions/runs/38524354344 → başarılı, "0 changed"
    (ilk format çalıştırması https://github.com/sniperTurk/flutter-app/actions/runs/38522463223
    `e081adf` format commit'ini üretti).
  - Analyze (`--fatal-infos --fatal-warnings`): https://github.com/sniperTurk/flutter-app/actions/runs/38524987490 → başarılı.
  - Test (`test` klasörünün tamamı): https://github.com/sniperTurk/flutter-app/actions/runs/38524351574 → başarılı.
  - Önceki test çalıştırması https://github.com/sniperTurk/flutter-app/actions/runs/38522709933 (`e081adf`) yeni
    testte 1 hata verdi ("Ateşli: a listed rifle and its listed ammunition go": mühimmat önerisi bulunamadı).
    Test, mühimmatı El dolumu > Hornady > 168 gr ELD Match listesinden seçecek şekilde düzeltildi; uygulama kodu değişmedi.
- Çalışmayanlar: integration_test (Simulator), iOS CI, cihaz, TestFlight. Bunlar başarılı sayılmaz.
- Dal güncel `main` (237c14d) üzerinde; yeniden temellendirme gerekmedi.

---
_Generated by [Claude Code](https://claude.ai/code)_
