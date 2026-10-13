# iOS CI düzeltmesi (PR #267, dal `fix/ios-ci-pcp-marka`)

Tarih: 13 Ekim 2026

## Sonuç

`iOS CI / verify` işi yeşil oldu: çalıştırma 38425348799, commit f7f8c65.
Bu çalıştırmada "Boot iOS Simulator and run launch smoke test" adımı geçti.
Arkasından imzasız cihaz derlemesi, imzasız App Store arşivi, arşivin imzasız
olduğunun kontrolü ve gizlilik bildirimi (privacy manifest) kontrolü de geçti.
Uygulamanın davranışı değişmedi. Yalnızca entegrasyon testleri değişti.
TestFlight'a gönderilmedi, birleştirme (merge) yapılmadı.

## Ne bozuktu, neden

CI'da yalnızca `integration_test/app_launch_test.dart` çalışır. Test, temiz
kurulumda bir PCP profili oluşturur, kaydeder, sonra Hedef ekranını açar.
Arayüz 12–13 Ekim'de değişti, test bu değişikliklere uyarlanmamıştı. Test bu
yüzden art arda üç farklı yerde durdu. Her biri bir öncekinin arkasında
saklıydı.

1. **Satır 129 (eski main):** `choose('ammo-brand-select', 'Listede yok')`
   çağrısı `Bad state: No element` hatası verdi. Sebep: PCP mühimmatın
   Marka | Model listeleri 13 Ekim'de gizlendi
   (`_showPcpAmmoBrand = bool.fromEnvironment('PCP_AMMO_BRAND')`,
   `lib/features/profiles/profiles_screen.dart`). main'deki son altı iOS CI
   çalıştırması da tam bu satırda düştü: 38326017636, 38351688466,
   38354588675, 38368547951, 38387657012, 38402452893. PR #267'nin ilk
   commit'i (e8092b2) bunu düzeltmişti.
2. **Satır 137 (e8092b2):** `ensureVisible(find.byKey(Key('ammo-bc-model')))`
   çağrısı `Bad state: No element` hatası verdi (çalıştırma 38415028094).
   Sebep: PCP pelet ve slug her zaman G1 ile çözülür. "BC modeli" kutusu
   PCP'de hiç gösterilmez (`if (platform != WeaponPlatform.pcp)`,
   `profiles_screen.dart` yaklaşık satır 4098; `_bcModelForSave` PCP için
   `BallisticModel.g1` döndürür).
3. **Satır 193 (7d0b385):** `tap(find.text('Tablo').first)` çağrısı
   `Bad state: No element` hatası verdi (çalıştırma 38421850200). Sebep:
   Hedef'teki "Tek atış | Tablo" anahtarı 12 Ekim'den beri gizli
   (`_showShotModeSwitch = bool.fromEnvironment('SHOT_TABLE_SWITCH')`,
   `lib/features/home/home_screen.dart` satır 105–108, PR #240). Bu satıra
   daha önce hiç gelinmediği için hata 1 numaranın arkasında saklı kalmıştı.

## Ne değişti

- `integration_test/app_launch_test.dart`
  - PCP mühimmatta "BC modeli → G1" seçimi kaldırıldı. Yerine
    `expect(find.byKey(Key('ammo-bc-model')), findsNothing)` geldi. Böylece
    PCP'de bu kutunun çıkmadığı da test edilir.
  - "Tablo → DOPE oluştur → DataTable" adımları kaldırıldı. Yerine
    `find.text('Tablo')` ve `find.text('DOPE oluştur')` için `findsNothing`
    geldi. Böylece gizli anahtarın üretimde görünmediği test edilir.
- `integration_test/sim_screens_test.dart`
  - PCP'deki `choose('ammo-bc-model', 'G1')` satırı kaldırıldı (sebep 2 ile
    aynı).
  - `hedef_tablo` ekran görüntüsü adımı kaldırıldı (sebep 3 ile aynı). Bu
    adım kalsaydı tur `failures` listesine düşüp başarısız olurdu.
- `integration_test/sim_screens_paralaks_mpbr_test.dart`
  - PCP'deki `choose('ammo-bc-model', 'G1')` satırı kaldırıldı (sebep 2 ile
    aynı).

Son iki dosya `verify` işinde çalışmaz. Ekran görüntüsü iş akışlarında
(`sim-screens.yml`) çalışırlar. Aynı nedenle onlar da kırılırdı.

## Kontrol edilen ve sorun olmayanlar

Profil formundaki her anahtar ve metin `lib/` ile tek tek karşılaştırıldı.
Hepsi mevcut ve test sırasıyla uyumlu:

- `profile-platform`, `rifle-brand-select` ("Listede yok"), `rifle-brand`,
  `rifle-model`, `rifle-caliber` ("6.35 mm (.25)", `Cartridges.pcp`),
  `rifle-twist-rate`, `rifle-twist-direction`.
- `ammo-type` ("Slug"), `ammo-grain`, `ammo-bc`.
- `profile-velocity-fps`: Namlu çıkış hızı artık tüfeğin Marka/Model'inin
  altında. Test anahtarla bulduğu için yerinin değişmesi sorun değil.
- `profile-distance-unit`, `profile-zero`, `scope-sight-height`.
- `scope-brand-select` → "Listede yok", `scope-brand`, `scope-min-mag`,
  `scope-max-mag`, `scope-objective`, `scope-unit`, `scope-click`,
  `scope-mount` ("Normal (0 MOA)"), `scope-focal-plane`.
- Dürbün filtre kutuları (Birim/Odak/Tüp/Büyütme) yalnızca listeden bir
  marka seçilince çıkar. "Listede yok" yolunda yoktur, testi etkilemez.
- Kayıt doğrulaması (`_missing`, `_ammoValid`): PCP'de Marka, Uzunluk ve
  basınç alanları isteğe bağlı. "BC modeli" PCP'de kendiliğinden G1 olur.
- Kayıttan sonraki kontroller ("Yeni Profil", Hedef'te "Tahmin yok, hesap
  var." yok, "(KİLİTLİ)" yok, `scope-impact-text` var) çalıştırma
  38421850200'de geçti. Başlık değişikliği ("Atış Çözümü") test edilen bir
  metin değil.
- Diğer turlar (`chrono`, `barometre`, `kontrol_gunluk`, `wez_tour`) profili
  SharedPreferences'a doğrudan yazar, profil formundan geçmez.
  `usage_guide` profil oluşturmaz.
- `ios-ci-diagnostics` artifact'ı bu ortamdan indirilemedi (blob deposu
  403 verdi). Bunun yerine işlerin günlükleri GitHub API'sinden okundu.
  Hata satırları yukarıdaki bilgiler bu günlüklerden alındı.
- Bu ortamda Flutter SDK ve macOS yok. `tools/claude_flutter_verify.sh` ve
  `dart format` burada çalıştırılamadı. Biçim kontrolü CI'daki `dart-checks`
  işinde yapıldı ve geçti.

## Uygulama hatası var mı?

Kod hatası bulunmadı. Uygulamanın davranışı değiştirilmedi. Sahibinin
kararını gerektiren iki not:

- "Tek atış | Tablo" gizli olduğu için üretimde **DOPE tablosuna arayüzden
  ulaşan bir yol yok**. Kod duruyor (`BallisticsView.table`), yalnızca
  `--dart-define=SHOT_TABLE_SWITCH=true` ile açılıyor. iOS üzerinde DOPE
  tablosu artık entegrasyon testiyle sınanmıyor. Birim testleri
  (`test/ballistics_drag_mode_test.dart`) tabloyu hâlâ sınıyor.
- `docs/app-store/06-ekran-goruntusu-plani.md` hâlâ `40_hedef_tablo.png`
  ekran görüntüsünü ("Hedef → Tablo") planlıyor. Anahtar gizli kaldıkça bu
  ekran görüntüsü üretilemez.

## CI çalıştırmaları

| Commit | Çalıştırma | `verify` sonucu |
|---|---|---|
| 1964035 (main) | https://github.com/sniperTurk/flutter-app/actions/runs/38402452893 | Başarısız: satır 129, `ammo-brand-select` |
| e8092b2 | https://github.com/sniperTurk/flutter-app/actions/runs/38415028094 | Başarısız: satır 137, `ammo-bc-model` |
| 7d0b385 | https://github.com/sniperTurk/flutter-app/actions/runs/38421850200 | Başarısız: satır 193, `Tablo` |
| f7f8c65 | https://github.com/sniperTurk/flutter-app/actions/runs/38425348799 | **Başarılı.** `wind-acceptance` ve `dart-checks` da başarılı. `ios-simulator` işi atlandı (skipped). |

Bu rapor dosyası ayrı bir commit ile eklendi. O commit'in CI sonucu PR
sayfasında görünür.

---
_Generated by [Claude Code](https://claude.ai/code)_
