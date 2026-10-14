# Ateşli tüfek: elle girilen mühimmat (2026-10-14)

Sahibin kararı (2026-10-14 09:26–09:30): "Mühimmat ekleyi sadece ateşli silah
için aç. Mühimmat verisi çok karışık. Kullanıcıdan girmesini istediğimiz tüm
verileri select (açılır liste) almalı, BC hariç. Ağırlığın doğru yazılması
çok önemli."

Dal: `fix/atesli-elle-muhimmat`. Taslak PR; birleştirmeyi sahibin ana oturumu
yapar. TestFlight yok.

## Ne değişti

Dosyalar:

- `lib/features/profiles/profiles_screen.dart` — yalnızca Mühimmat bölümü
  (tüfek bölümüne dokunulmadı).
- `lib/features/profiles/profile_field_info.dart` — yeni ⓘ metinleri; Barut
  katsayısı ve Hız ölçüm sıcaklığı metinlerinde "yazın" → "seçin".
- `test/atesli_elle_muhimmat_test.dart` — yeni widget testleri.
- `test/support/rifle_form.dart` — `openAmmoManual` yardımcısı; `fillAmmoForm`
  ateşli tüfekte bağlantıyı, "Diğer"i ve Ağırlık "Listede yok"u kullanıyor.
- `test/profile_editor_fail_closed_test.dart`,
  `test/powder_temperature_profile_test.dart` — yeni akışa göre güncellendi.
- `test/rifle_not_listed_test.dart` (#289'dan) — "Ateşli: Mühimmat Marka keeps
  its "Listede yok" item" testi bu kararla ters döndü: artık maddenin olmadığını
  ve `ammo-not-listed` bağlantısının olduğunu kontrol ediyor.
- Bu rapor.

Yeni anahtarlar (Key): `ammo-not-listed` (bağlantı), `ammo-brand-pick` (elle
girişte Marka listesi), `ammo-grain-select` (Ağırlık listesi),
`ammo-grain-need-caliber` (Kalibre yokken uyarı), `ammo-typed-summary` (özet
satırı). Eski anahtarlar korunuyor: `ammo-brand` (Diğer'den sonra yazılan
marka), `ammo-model`, `ammo-grain` (Listede yok'tan sonra yazılan grain),
`ammo-bc`, `ammo-bc-model`, `ammo-back-to-list`, `profile-powder-coef`,
`profile-powder-temp` (artık açılır liste).

Bayraklar (varsayılan kapalı, "gizle, silme"):

- `AMMO_LISTEDE_YOK` — ateşli tüfekte mühimmat Marka listesindeki "Listede
  yok" maddesi. Kapalıyken madde görünmez; elle giriş bağlantıdan açılır.
- `AMMO_BC_BANDS_TYPED` — elle girilen ateşli mühimmatta "Hıza göre BC"
  kutuları.

## Giriş bağlantısı

Ateşli tüfekte, mühimmat listeden seçilirken (liste boş değilken) Marka |
Model satırının altında sola dayalı, tam genişlikte "Aradığın mühimmat listede
yok mu?" bağlantısı var (dürbündeki `scope-not-listed` gibi). Dokununca
mühimmat alanları boşalır ve elle giriş açılır. "Listeye dön" eskisi gibi
çalışıyor. PCP'de bağlantı yok.

## Elle girişte kutular ve listelerin kaynağı

Kutular mümkün olan yerde iki kutu bir satır (istisnalar "Satır düzeni"
notunda), her birinde Türkçe ⓘ var, listeler "Seçiniz" ile başlıyor,
etiketlerde parantez yok, kutu altında yardım metni yok.

| Kutu | Tür | Liste nereden geliyor |
|---|---|---|
| Mühimmat türü | Liste | Değişmedi: Fabrika fişeği / El dolumu |
| Marka | Liste | `factory_ammo_library.dart` ile `bullet_library.dart`'ın ateşli kısmındaki tüm markalar, sıralı; en sonda "Diğer". **37 marka** (fabrika fişeğinde 30, mermi kütüphanesinde 16, birleşim 37). "Diğer" seçilince Marka yazma kutusu çıkar (gerekli). |
| Model | Yazı | Gerekli (aynı markanın başka mühimmatıyla karışmasın). |
| Ağırlık | Liste | Seçili Kalibrenin fabrika fişekleri (fişek adı biliniyorsa o fişek, bilinmiyorsa çap) + aynı çaptaki ateşli kütüphane mermileri; tekrarsız, küçükten büyüğe, "168 gr (10,9 g)" biçiminde. En sonda "Listede yok". |
| BC | Yazı | Tek elle yazılan sayı; aralık kontrolü ve mantıksız BC uyarısı aynen duruyor. |
| BC modeli | Liste | G1 / G7, "Seçiniz" ile başlar, gerekli. |
| Barut katsayısı | Liste, isteğe bağlı | 0,25 / 0,5 / 0,75 / 1 / 1,25 / 1,5 / 2 / 2,5 / 3 (%/15 °C). Hepsi mevcut ±10 aralığında. |
| Hız ölçüm sıcaklığı | Liste, isteğe bağlı | −10, −5, 0, 5, 10, 15, 21, 25, 30, 35, 40 °C. Hepsi mevcut −50…60 aralığında. |

Ağırlık listesinin örnek sayıları (yeni profilde Kalibre listeden seçilince):

- .308 Win: **69** ağırlık, 100–250 gr (30'u .308 Win fabrika fişeklerinden).
- 6.5 Creedmoor: **40** ağırlık, 90–160 gr.
- .223 Rem: **48** ağırlık, 30–95 gr.

Barut kutuları listeden seçilen (listelenmiş) mühimmatta da aynı liste;
form tutarlı. Listede "Seçiniz" maddesi kutuyu yeniden boşaltır (boş = sıcaklık
düzeltmesi yok). Kutulardan yalnız biri doluysa doğrulama bugünkü gibi
("Katsayıyı da girin." / "Sıcaklığı da girin.").

## Ağırlık hataları nasıl önleniyor, neden

Sahip: "Ağırlığın doğru yazılması çok önemli." En sık hata gram ile grain'in
karışması (10,9 g ↔ 168 gr) ve yanlış kalibrenin ağırlığı.

1. Ağırlık serbest yazılmıyor; Kalibreye ait üretici ağırlıkları listeden
   seçiliyor ve her maddede gram karşılığı yazıyor ("168 gr (10,9 g)").
2. Listede yoksa "Listede yok" → yazma kutusu açılıyor; kutunun birim
   alanında gram karşılığı canlı görünüyor ("gr = 11,2 g"). Kabul aralığı:
   o çaptaki veri ağırlıklarının en küçüğünün 0,8 katı ile en büyüğünün 1,25
   katı arası (.308 Win: 80–312,5 gr). O çap için veri yoksa kesit yoğunluğu
   0,08–0,45 lb/in² (grain / (7000 · d²), d inç). Dışındaysa: "Bu ağırlık bu
   kalibre için mantıklı değil. Kutudaki değeri kontrol edin." ve Kaydet
   kapalı. Örnek: .308 için 11 yazılırsa (gram sanılarak) reddedilir.
3. Kalibre seçilmeden ağırlık listesi yerine "Ağırlık listesi kalibreye göre
   gelir. Önce Tüfek bölümünde Kalibre seçin." uyarısı çıkıyor (serbest yazma
   yok).
4. Kalibre sonradan değişirse seçili ağırlık yeni kalibrenin listesinde yoksa
   kutu "Seçiniz"e döner, "Ağırlığı listeden seçin." hatası verir ve Kaydet
   altındaki eksik listesinde "Ağırlık" görünür. Eski ağırlık sessizce
   kullanılmaz. (Tüfek kodu değiştirilmedi; bu doğrulamayla çözüldü.)

## Satır düzeni hakkında not (karar sahibin)

Main'e bugün eklenen kural (#287) "her satırda iki kutu" diyor. Elle girişte
iki yerde satırda tek kutu var:

- Ağırlık listesi kendi satırında; "Listede yok" seçilince yazılan grain kutusu
  da kendi satırında. İkisi yan yana denendi: yarım genişlikte "Kutudaki
  ağırlık" etiketi, gram karşılığı ("gr = 11,2 g") ve ⓘ sığmadı, CI'da taşma
  hatası verdi (run 38525688473). Gram karşılığını görünür tutmak için tam
  satıra alındı.
- "Diğer" seçilmediğinde Model tam satır (listeden seçimdeki mevcut düzen gibi).

İstenirse sonraki adımda Ağırlık | BC yan yana alınabilir (o zaman BC modeli
tek kalır) ya da gram karşılığı kısaltılabilir; burada karar verilmedi.

## Özet satırı

Elle girilen ateşli mühimmat bloğunun en altında, Marka, Model, Ağırlık, BC ve
BC modeli geçerli olunca salt okunur kart: "Federal Gold Medal · .308 Win ·
168 gr (10,9 g) · BC 0,462 G1". Örnekteki biçimden farkı: marka ile birlikte
Model de yazılıyor (aynı markanın iki fişeği karışmasın diye). Kalibrenin fişek
adı bilinmiyorsa çap yazılır ("7,82 mm").

## Uç durumlar

- **Kalibre yok:** yukarıda (3). Bağlantı yine görünür, çünkü Fabrika
  fişeği Kalibresiz tüm listeyi gösterir.
- **Elle girişten sonra Kalibre değişimi:** yukarıda (4). Yazılmış ağırlık
  ("Listede yok") yeni kalibrenin aralığına göre yeniden kontrol edilir.
- **Düzenleme (Profili Düzenle):** elle girilmiş ateşli mühimmatlı profil elle
  girişte açılır; marka listede yoksa "Diğer" + yazılı marka, ağırlık listede
  yoksa "Listede yok" + yazılı değer geri gelir. Model boş kaydedilmiş eski
  bir kayıt varsa Model artık gerekli olduğu için Güncelle'den önce
  doldurulmalı.
- **BC modeli:** elle girişte BC yazınca G1 artık kendiliğinden seçilmiyor
  (liste "Seçiniz" ile başlamalı ve bilinçli seçilmeli). Listeden seçilen
  mühimmatta bu davranış aynen sürüyor. Eski bir elle kayıtta G1/G7 dışında bir
  model (ör. G2) ya da özel eğri varsa listede "(kayıtlı)" olarak gösterilir
  ve korunur.
- **Listede olmayan eski barut değerleri:** ör. 0,8 %/15 °C veya 20 °C
  kayıtlı profilde listede "0,8 (kayıtlı)" / "20 (kayıtlı)" olarak görünür ve
  Güncelle'de aynen saklanır. Üreticinin verdiği bir değer listede yoksa
  "(üretici)" yazar (`FactoryPowderTempLibrary` bugün boş).
- **Hıza göre BC olan eski elle kayıt:** kutular gizli ama kayıtlı eşikler
  silinmiyor; Güncelle'de kayda aynen yazılıyor ve hesapta eskisi gibi
  kullanılıyor (mühimmat kaydındaki `bcBands` → `BallisticInput`). Yeni elle
  girişte eşik girilemiyor. Listeden seçilen ve verisinde eşik olan mermiler
  eşiklerini kullanmaya devam ediyor.
- **Fabrika fişeği / El dolumu:** elle girişte kutular aynı; Mühimmat türü
  değiştirilirse (bugünkü gibi) mühimmat alanları boşalır ve liste döner.
  Seçili Kalibre için listede hiç ürün yoksa elle giriş kendiliğinden açılır
  (bağlantı ve "Listeye dön" yok) ve Marka ⓘ'si nedenini söyler.

## Bilerek değiştirilmeyenler

- **PCP Mühimmat:** aynen (Tip | Ağırlık | BC; Marka/Model yok, bağlantı yok,
  barut kutuları yok).
- **Tüfek bölümü:** dokunulmadı. Paralel görev `fix/tufek-listede-yok`
  main'e girdi (#289); bu dal güncel main üstüne yeniden kuruldu, tek çakışma
  Ağırlık kutusunun bir yorum satırındaydı (#291 kod temizliği).
- **Listeden seçilen mühimmat akışı:** Marka/Model listeleri, ağırlık/BC/hız
  doldurma, eşikler, BC'den otomatik G1 aynen. Tek fark: Barut kutuları artık
  liste ve Marka listesinde "Listede yok" maddesi yok (bağlantı var).
- Kalibre, Namlu çıkış hızı (Tüfek bölümü) ve Mermi uzunluğu (yalnız Pro)
  burada sorulmuyor.

## Hangi test neyi kapsıyor

`test/atesli_elle_muhimmat_test.dart`:

- "firearm: link under Marka | Model, no "Listede yok" item" — bağlantı, konumu,
  gizli madde, El dolumu, "Listeye dön".
- "PCP: no link, Mühimmat unchanged" — PCP aynen.
- "typed firearm round: lists, typed Model and BC, no bands" — Marka listesi
  ve "Diğer", yazılı Model, .308 Win ağırlıkları "gr (g)" ile, "Listede yok" →
  aralık hatası, gram birimi, BC yazılı, BC modeli ve barut "Seçiniz", barut
  maddeleri, eşikler gizli, özet satırı metni.
- "without a Kalibre Ağırlık is a notice" — Kalibre yok; 6.5 Creedmoor listesi.
- "a weight of another Kalibre is not taken silently" — kalibre değişimi.
- "save + reopen keeps every typed value" — Kaydet + yeniden aç.
- "an older typed profile keeps off-list values and its bands" — "(kayıtlı)"
  barut değerleri, gizli ama korunan eşikler.
- "listed firearm round: list flow unchanged" — listeden seçim.

`test/powder_temperature_profile_test.dart` barut listelerini,
`test/profile_editor_fail_closed_test.dart` bağlantı + "Diğer" akışını
kapsıyor. `integration_test` adımları PCP ile ilerlediği için mühimmat
"Listede yok" adımı yoktu; değişiklik gerekmedi.

## Doğrulama

Yerel (Flutter SDK bu ortamda indirilemedi; storage.googleapis.com proxy'de
engelli): `python3 tools/offline_dart_lint.py` PASS,
`python3 -m unittest discover -s tools -p 'test_*.py'` 732 test OK.

CI (yalnızca gerçekten çalışanlar):

Her çalıştırmanın hangi commit'i aldığı iş kaydındaki `git log -1` satırından
doğrulandı (başka oturumlar da aynı iş akışlarını tetikliyor).

- **Son kod commit'i `1353464`** (main #295 üstüne, biçimlendirme dahil):
  tüm testler https://github.com/sniperTurk/flutter-app/actions/runs/38536763343
  — **başarılı**; `flutter analyze --fatal-infos --fatal-warnings`
  https://github.com/sniperTurk/flutter-app/actions/runs/38536767152 —
  **başarılı**. (Sonraki commit'ler yalnız bu rapor.)
- Tüm testler (`flutter test test`), commit `d716f8c` (main #295 üstüne):
  https://github.com/sniperTurk/flutter-app/actions/runs/38535128911 —
  **başarılı**.
- `flutter analyze --fatal-infos --fatal-warnings`, commit `d716f8c`:
  https://github.com/sniperTurk/flutter-app/actions/runs/38535131974 —
  **başarılı**.
- Biçimlendirme (one-off dart format fix) yalnızca
  `test/rifle_not_listed_test.dart`'ta satır kırdı (commit `df213eb`).
- Önceki kırmızı: ilk tam çalıştırmada yeni testlerden ikisi, yarım genişlikteki
  elle ağırlık kutusunun taşması yüzünden düştü (kutu kendi satırına alındı);
  main'e #289 eklenince onun "Mühimmat Marka keeps its Listede yok item" testi
  bu kararla çeliştiği için düştü (test yeni karara göre çevrildi).
- PR iş akışı (`.github/workflows/ios-ci.yml`), PR başı `1951ce7`
  (kod `1353464` ile aynı, üstüne yalnız rapor):
  https://github.com/sniperTurk/flutter-app/actions/runs/38538247449 —
  `verify` **başarılı**, `dart-checks` **başarılı**, `wind-acceptance`
  **başarılı**; `ios-simulator` **atlandı** (skipped), yani Simulator derlemesi
  çalışmadı. Cihaz, imzalama, TestFlight: çalıştırılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
