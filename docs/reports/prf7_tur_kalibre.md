# PRF-7 / PRF-8: Tür seçimi Kalibre'yi değiştirmesin

Sahibin kararı: 2026-10-15 20:03 (İstanbul), "yapılacak her iş için ayrı ayrı görev aç". Kaynak: TestFlight öncesi denetim (2026-10-15b), bulgular PRF-7 (orta) ve PRF-8 (düşük).

## Ne

- **PRF-7:** Yeni profilde önce Kalibre ".300 Win Mag", sonra Tür "Ateşli Tüfek" seçilince Kalibre sessizce ".308 Win" oluyordu; Fabrika fişeği listesi de bütün 7,82 mm fişeklere genişliyordu. Artık Kalibre ".300 Win Mag" kalıyor, liste yalnız .300 Win Mag fişeklerini gösteriyor.
- **PRF-8:** El dolumu Hornady .321 (8,15 mm) mermi seçilip sonra Tür seçilince Kalibre boşalıyordu. Artık 8,15 mm kalıyor.

## Nasıl

`lib/features/profiles/profile_editor.dart`, Tür kutusunun `onChanged` kısmı:

- Önce: Tür **değişmese bile** (yeni profil zaten Ateşli Tüfek ile başlıyor) seçili fişek adı (`_cartridge`) siliniyor, Kalibre çapa göre yeniden eşleniyordu. Aynı çaptaki ilk fişek (7,82 mm → .308 Win) kazanıyordu. Listede olmayan bir çap (8,15 mm) ise siliniyordu.
- Şimdi: Kalibre'ye yalnız Tür **gerçekten değişince** dokunuluyor. Tür aynıysa Kalibre olduğu gibi (fişek adıyla) kalıyor.
- Tür değişince (Ateşli ↔ PCP) eski davranış aynen duruyor: Ateşli fişek adları PCP listesinde yok, PCP mm değerlerinin (4,5 … 18,29) hiçbiri Ateşli listesinde bir fişek çapı değil. Yani diğer türün kalibresi her durumda temizleniyor; çapa göre "ilk fişek" eşlemesi oluşmuyor.
- Fabrika fişeği listesi zaten seçili fişek adına göre süzülüyordu (`_factoryHere`: `a.cartridge == _cartridge`). Fişek adı artık silinmediği için liste o fişeğe özgü kalıyor; bu dosyada değişiklik gerekmedi.

## Neden

Hata, Tür aynı kalsa da çalışan iki satırdı (`_cartridge = null` ve çapa göre Kalibre silme). Bunları "Tür değişti" bloğunun içine almak en küçük ve güvenli düzeltme.

## Uç durumlar

- Yeni profil, Tür en son seçiliyor: Kalibre ve Mühimmat aynen kalıyor.
- Tür Ateşli → PCP: fişek adı ve 7,82 mm gibi Ateşli çapı temizleniyor (eskisi gibi), mühimmat da temizleniyor (eskisi gibi).
- Tür PCP → Ateşli: PCP mm değeri temizleniyor (eskisi gibi).
- "Fişeğim listede yok" ile çap seçildiyse ve Tür aynıysa, çap seçimi kalıyor.
- Kayıtlı veri anahtarı değişmedi. Eski profil düzenleme akışı değişmedi (açılışta `initState` aynı).

## Bilerek yapılmayan

- PRF-8 notundaki "8,15 mm listeden yeniden seçilemiyor" kısmı (Kalibre listesine yeni çap eklemek) bu görevin kapsamında değil; dokunulmadı.
- PCP kalibreleri için tam tarama testi yazılmadı: görev 168 Ateşli fişeği kapsıyor ve yeni profilde PCP kalibresi Tür'den önce seçilemiyor.
- Başka sayfa, alan veya metin değişmedi.

## Testler

- `test/audit_2026_10_15b/profil_tur_audit_test.dart`: denetim dalındaki dosya (audit/testflight-2026-10-15b-taslak) getirildi; PRF-7 testinin `skip: true`'su kaldırıldı, PRF-8 testi de skip'siz. İkisi de gerçek dokunuşlarla (listeyi açıp seçerek) çalışıyor. Eski profil "Güncelle" koruma testi aynen duruyor.
- `test/prf7_tur_kalibre_test.dart` (yeni): `lib/data/cartridges.dart`'taki 168 Ateşli fişeğin her biri, iki sırada (Tür → Kalibre ve Kalibre → Tür), yeni profilde:
  - Kalibre kutusunda seçili değer tam olarak o fişek adı,
  - Mühimmat türü "Fabrika fişeği" seçildikten sonra da aynı,
  - Fabrika fişeği Marka listesi = o fişeğin fabrika mühimmatı olan markalar; her markanın Model sayısı = o marka + o fişek adındaki kayıt sayısı (çapa göre genişleme olsaydı sayı tutmazdı),
  - fabrika mühimmatı olmayan fişekte liste yok, elle giriş açık.
  Toplam 336 widget testi + listenin 168 benzersiz addan oluştuğunu doğrulayan 1 test.
- Var olan testlerin hiçbiri değiştirilmedi veya zayıflatılmadı.

Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 842 test OK. Bu ortamda Flutter SDK indirilemedi (storage.googleapis.com ağ izni yok), `flutter test` yerelde ÇALIŞMADI; sonuçlar aşağıdaki CI koşularından.

## CI

- Format (one-off dart format fix): https://github.com/sniperTurk/flutter-app/actions/runs/38775122318 — başarılı; test dosyasında 1 satırlık biçim düzeltmesi dala eklendi.
- Analyze (analyze-diag): https://github.com/sniperTurk/flutter-app/actions/runs/38775284038 — başarılı.
- Tüm testler (test-diag, files=test): https://github.com/sniperTurk/flutter-app/actions/runs/38775279944 — başarılı (çıkış kodu 0).
- iOS CI, rapor öncesi kod commit'i aff5ccb üzerinde (https://github.com/sniperTurk/flutter-app/actions/runs/38776546953): `dart-checks` başarılı, `wind-acceptance` başarılı, `verify` başarılı; `ios-simulator` atlandı (yalnız elle çalışıyor).
- Bu rapor güncellemesinden sonraki son commit'in CI sonucu PR açıklamasının sonunda yazılı.
- Simulator, cihaz, TestFlight, App Store: çalıştırılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
