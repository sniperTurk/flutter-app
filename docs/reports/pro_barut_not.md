# Pro barut notu — Tüfek düzeltmeleri

Dal: `fix/pro-barut-not` (main @ 8cc3aab'dan) · Taslak PR (birleştirilmedi, TestFlight yok).

## Mermi uzunluğu profile, Mühimmat sıcaklığı bölümü (17.10 11:41)

### Sahibin kararı (İstanbul, 17.10.2026 11:34–11:41, çizim üzerinden)
- Mermi uzunluğu merminin özelliği: Pro'dan Profil → Mühimmat'a ("al bunu oraya"; 13.10 23:32 "Profilden çıkartın" kararını geri alır).
- Mühimmat sıcaklığı Pro'da ayrı bir bölüm ("muhımmat sıcaklıgını ıcın ayrı bır kutu alan ac dıgerlerı ıle karısması"); kutunun üstünde etiket yok (B seçeneği: başlık söylüyor, kutuda yalnız °C).
- Mühimmat kartındaki yer onaylandı ("muhımmat ekleme alanı okey").

### Ne yapıldı
1. **Profil → Mühimmat:** "Mermi uzunluğu" (mm) ateşli silahta ve PCP'de, **BC modeli | Mermi uzunluğu** aynı satırda (BC modeli solda). Kayıtlı alan aynı (`lengthMm`, `ammoLength` denetleyicisi). İsteğe bağlı (boş bırakılabilir), 1–60 mm aralık kontrolü aynı (aralık dışıysa kaydetmek için eksik listesinde "Mermi uzunluğu" çıkar). ⓘ metni (ateşli ve PCP tek metin) sahibin metni harfi harfine.
2. **Bayrak silindi:** `PROFILE_AMMO_LENGTH` (`_showProfileAmmoLength`) ve ölü dalları silindi: editördeki gizli kutu, "Listeye dön" kontrolü, PCP Tip satırı dalı, kayıt dalı. Profil özetindeki (yalnız bayrak açıkken görünen) "Uzunluk" satırı da bu bayrağın ölü dalıydı; bugünkü görünüm korunsun diye silindi (özet değişmedi).
3. **Pro → Tüfek düzeltmeleri:** Mermi uzunluğu ve Mühimmat sıcaklığı çıktı. Bölümde yalnız Gerçek / yazan, Yukarı + / aşağı − | Sağ + / sol −. Mevcut "Profilde yiv yönü veya yiv oranı yok; spin drift hesaplanamaz." uyarısı **bu bölümde kaldı** (spin drift bu bölümün ⓘ'sinde anlatılıyor; metin ve koşul aynı). Başlık ⓘ sayfasındaki "Kutular" listesinden de iki kutu çıktı; Ne?/Neden?/Nasıl? açıklamaları (spin drift, barut sıcaklığı dahil) değişmedi.
4. **Yeni bölüm "Mühimmat sıcaklığı"** Tüfek düzeltmeleri'nin hemen altında, yalnız ateşli silahta (PCP'de yok). Diğer bölümlerle aynı açılır kart (`_proBox`, id `ammo-temp`). Başlık ⓘ'si mevcut `EnvironmentFieldInfo.ammoTemperature` metnini tek paragraf olarak açar (Garmin satırıyla aynı yöntem). İçinde: Mühimmat sıcaklığı kutusu (aynı anahtar `env-ammo-temp`, `ammoTempCtl`, kayıt `ammoTemp`/`ammoTempText`, birim °C/°F) **etiketsiz ve ⓘ'siz**, yarım genişlik (iki sütunlu satırın sol sütunu), altında onaylı not (`pro-powder-source`, üç metin değişmedi). Notun altındaki "Bugünkü hız: …" satırı (varsa) notla birlikte bu bölüme geldi; metni ve koşulu aynı.
5. **Açık/kapalı ve özet:** diğer bölümler gibi kapalı başlar, aynı anda tek bölüm açık (sahibin 09.10 kuralı). Kapalıyken özet: boşsa "kapalı", değer girilmişse "1 ayar açık" — bu değer 16.10'dan beri Tüfek düzeltmeleri özetinde tam bu sözlerle sayılıyordu; yeni metin uydurmamak için aynı sözler kullanıldı. Tüfek düzeltmeleri artık bu değeri saymıyor.
6. **Hesap:** spin drift / Sg, profildeki mühimmatın uzunluğunu kullanır. Profilde uzunluk yoksa eski sürümde Pro → Mermi uzunluğu'na yazılmış değer kullanılır (kayıt anahtarı `bulletLength`, silinmedi; ekranda kutusu yok ama yüklenir ve aynen geri kaydedilir). Aralık kontrolü aynı (0–100 mm; dışı = yok). Pellet yine hariç.

### Eski Pro değeri: genel mi, profile özel mi?
**Profile özel.** `ShotSettingsStore` her profili ayrı anahtarda tutar (`sniper_turk.shot_settings.<profilId>`, alan `bulletLength`). Bir profilde Pro'ya yazılmış uzunluk yalnız o profilin hesabında kullanılır.

### Nasıl
- `lib/features/profiles/profile_editor.dart`, `profile_editor_ammo.dart`, `profile_field_info.dart`, `profile_summary.dart`: bayrak ve dalları silindi; BC modeli ile Mermi uzunluğu kendi tam genişlik ızgarasında (`ammo-bc-model-length-row`), böylece önlerinde ne olursa olsun aynı satırda kalırlar (Tüp | Regülatör satırıyla aynı yöntem).
- `lib/features/ballistics/pro_ayarlar_view.dart`: Tüfek düzeltmeleri sadeleşti, yeni bölüm eklendi; `_proBox`'a tek paragraf ⓘ için `infoText` eklendi.
- `lib/ui/menzil_widgets.dart`: `MenzilInput`'a `showLabel` (varsayılan `true`) eklendi; `false` iken kompakt kutunun üstünde etiket çizilmez, VoiceOver yine "Mühimmat sıcaklığı (°C)" okur. Başka hiçbir kutuda davranış değişmedi.
- `lib/features/ballistics/ballistics_screen.dart`: yalnız `_bulletLengthMm` (önce profil, sonra eski Pro değeri).

### Neden
Uzunluk merminin özelliği (profile/mühimmata ait); Mühimmat sıcaklığı diğer düzeltmelerle karışmasın diye ayrı bölümde.

### Uç durumlar
- **Mevcut kullanıcıların sayıları değişmez:** Profilde uzunluğu olmayan herkes (ateşli silahta hiç yazılamıyordu) eski Pro değeriyle aynı sonucu alır; aynı uzunluk profilden gelse de sonuç birebir aynı (test: Pro 31 mm = Profil 31 mm, dönüş ve spin drift notu eşit).
- **İstisna (bilgi):** 13.10 23:32'den önce PCP Mühimmat'ta Uzunluk yazmış kullanıcının bu değeri kayıtlıydı ama gizliydi ve hesaba girmiyordu. Artık Profil'de görünür ve hesaba girer; aynı profilde Pro'da farklı bir değer varsa profil değeri kazanır. Sahibin "hesap profil uzunluğunu kullanır" kuralının doğal sonucu; sayısı değişebilecek tek durum budur.
- **Eski Pro değeri ekranda görünmez:** profil uzunluğu boşken kullanılır; kullanıcı Profil'e uzunluk yazınca o kullanılır. Eski değeri tamamen kapatmanın tek yolu Profil'e uzunluk yazmaktır (kayıt silinmez, kural gereği).
- **Listeden mermi seçmek** uzunluğu doldurmaz (görev dışı); farklı mermi seçilince önceki yazılı uzunluk kutuda kalır (Pro'daki eski kutu da mermiden bağımsızdı).
- **PCP, main'deki düzen:** main'de PCP satırları "Tip | Ağırlık, BC | BC modeli" idi. BC modeli | Mermi uzunluğu satırı için BC tek başına bir satırda kalıyor (Tip | Ağırlık · BC · BC modeli | Mermi uzunluğu). #368 birleşince düzen "Ağırlık | BC · BC modeli | Uzunluk" olacak; o zaman BC yalnız kalmaz.
- **Birim yeri:** main'de Profil kutularının birimi etiket satırında, kutunun sağ üstünde (tüm Profil alanları gibi). #368 birimleri kutunun içine alıyor; `MenzilInput(unit: 'mm')` kullanıldığı için #368 ile birlikte "mm" kendiliğinden kutunun içine girer. Testim birimin bu alana ait olduğunu (alanın içinde) ölçüyor; kutunun içinde olduğunu #368 sonrası kontrol etmek gerek.
- **Dar ekran / büyük yazı:** iki sütun yer yoksa (320 pt + 1,3) BC modeli üstte, Mermi uzunluğu altta; taşma yok. Pro'da Mühimmat sıcaklığı kutusu iki sütunlu satırın sol yarısında; 320 pt'de tek sütuna düşer (Yukarı | Sağ gibi), tam genişlik olur.
- **Etiket kırılması (ekranda görülen):** 390 pt'de "Mermi uzunluğu" etiketi, sağdaki "mm" ve ⓘ yüzünden iki satıra kırılıyor; kutuların üst kenarı yine aynı (SIMRECT: ikisi de 385,0). #368'de birim kutuya girince etiket tek satıra sığmalı.

### Bilerek yapılmayan
- #368'in düzeni (birim kutuda, ⓘ etiket satırının sağında, PCP En düşük | En yüksek) uygulanmadı; #368 birleşmedi (main hâlâ 8cc3aab). Çakışma beklenen yer: `profile_editor_ammo.dart` Mühimmat kartı ve `menzil_widgets.dart` (`MenzilInput` yapıcısı). Sonra birleşen tarafın BC modeli | Mermi uzunluğu'nu kendi kartına taşıması gerekir.
- Tüfek düzeltmeleri ⓘ'sindeki "Barut sıcaklığı" açıklaması (Ne?/Neden?/Nasıl?) yerinde bırakıldı; sahip isterse yeni bölümün ⓘ'sine taşınabilir (soru).
- Başka alan, metin, sıra, varsayılan, bayrak ya da hesap değişmedi. TestFlight yok, birleştirme yok.

### Testler
Yeni: `test/mermi_uzunlugu_profil_test.dart` — gerçek Profil ekranı: ateşli (düzenle) ve PCP (yeni) için BC modeli | Mermi uzunluğu aynı üst kenar (±0,5 pt), BC modeli solda, birim mm, etiket "Mermi uzunluğu", ⓘ metni harfi harfine, alan altında yardım metni yok; kaydet/aç gidiş-dönüş (31,2 → `lengthMm: 31.2` → kutuda tekrar 31.2; boşaltınca `lengthMm` yazılmaz); 70 mm kaydı engeller, 60 mm geçer; 320 pt + 1,3 taşma yok (ateşli ve PCP); hesap: eski Pro 31 mm = Profil 31 mm (Hedef dönüşü ve spin drift notu birebir), Profil 31 + eski Pro 38 → Profil kazanır, eski Pro 38 tek başına farklı, ikisi yoksa spin drift yok; eski `bulletLength` kaydı silinmiyor.
`test/muhimmat_sicakligi_bolum_test.dart` — yeni bölüm Tüfek düzeltmeleri'nin hemen altında, başlık "Mühimmat sıcaklığı", kutu etiketsiz (`menzil-compact-label` yok), ⓘ yok, birim °C kutunun içinde, sol yarı genişlik, onaylı not altta; başlık ⓘ'si `EnvironmentFieldInfo.ammoTemperature` metnini açıyor; Tüfek düzeltmeleri'nde yalnız 3 kutu ve ⓘ "Kutular"ı yalnız bu üçü; PCP'de bölüm de Mermi uzunluğu da yok; özet "1 ayar açık" yeni bölümde, Tüfek "kapalı"; kayıtlı değer yükleniyor ve aynı sonucu veriyor; 320/390 pt + 1,3 taşma yok.
Eski düzeni/bayrağı doğrulayan ve güncellenen testler (zayıflatılmadı; aynı şeyi yeni yerde ölçüyorlar):
- `test/uzunluk_sadece_pro_test.dart` (eski PCP profil: kutu artık var ve 10.5 gösteriyor, kayıt korunuyor; özet hâlâ Uzunluk satırı göstermiyor)
- `test/formul_denetimi_2026_10_13_test.dart` (spin drift: "yalnız Pro" kuralı yerine "Profil, yoksa eski Pro"; pellet hariç aynen)
- `test/flight_warnings_wiring_test.dart` (Sg uyarıları profil uzunluğuyla; eski Pro değeri yalnız profil boşken)
- `test/pro_new_effects_test.dart`, `test/spin_powder_test.dart` (uzunluk profilden), `integration_test/wez_tour.dart` + `test/wez_tour_smoke_test.dart` (tur uzunluğu profilden veriyor)
- `test/profile_lists_test.dart`, `test/bc_modeli_secim_test.dart` (PCP: BC, sonra BC modeli | Mermi uzunluğu), `test/profile_editor_fail_closed_test.dart` (PCP'de uzunluk yazılır, ateşliye geçince silinir, kutu ateşlide de var)
- `test/pro_info_popup_test.dart` (Tüfek "Kutular": üç kutu), `test/pro_tufek_ozet_sayim_test.dart` (Mühimmat sıcaklığı artık Tüfek özetinde sayılmıyor), `test/ammo_temperature_test.dart` (kutuda etiket yok, başlıkta var), `test/pro_barut_not_test.dart` (320 pt kutu sütunu), `test/garmin_pro_ayarlar_test.dart` (ateşlide son bölüm artık Mühimmat sıcaklığı), `test/pro_satir_info_hiza_test.dart` (yeni bölüm de ⓘ hizası testine eklendi), `test/support/pro_sections.dart`
- Python: `tools/test_denetim_2026_10_14b_prf.py`, `tools/test_formul_denetimi_2026_10_13.py` (kaynak kontrolü yeni kurala), `tools/test_denetim_2026_10_14c.py` (bayrak listesi), `tools/test_denetim_2026_10_15b_guvenlik.py` (bayrak sayısı alt sınırı 14 → 13: bir bayrak silindi; diğer kontroller aynı).
- Ekran turları: `integration_test/pro_barut_not_screens_test.dart` (yeni kareler), `chrono_screens_test.dart`, `duzeltmeler_16_10_screens_test.dart` (yeni bölümü açıyor).
Yerel: `python3 tools/offline_dart_lint.py` → PASS (422 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlandı). Flutter SDK yerelde kurulamadı (Dart SDK indirmesi proxy'de 403); Flutter testleri yalnız CI'da.


### Ekran görüntüleri
Simülatör: iPhone 16e (390 pt), `sim-screens` run [39026830000](https://github.com/sniperTurk/flutter-app/actions/runs/39026830000), tur `integration_test/pro_barut_not_screens_test.dart`, çıkış kodu 0, 6 kare, adım hatası yok. Uygulama kodu 47fd52c ile aynı (sonraki commit'ler yalnız rapor).
Ölçülen kutular (SIMRECT, pt): Profil ateşli BC modeli 28–190 / Mermi uzunluğu 200–362, ikisinin üst kenarı 396,7; PCP aynı (396,7). Pro ateşli: Tüfek düzeltmeleri'nde Mermi uzunluğu yok; Mühimmat sıcaklığı bölümü Tüfek düzeltmeleri'nin hemen altında (Tüfek kartı bitişi + 8 pt), kutu 28–190 (sol yarı). Pro PCP: Mühimmat sıcaklığı bölümü yok.

| Profil → Mühimmat, ateşli (dolu) | Profil → Mühimmat, PCP | Pro, Tüfek düzeltmeleri açık |
|---|---|---|
| ![](https://raw.githubusercontent.com/sniperTurk/flutter-app/9ac570ab7f98c3e65be3a9a4c4ea34b71ca6bf0d/latest/01_profil_muhimmat_atesli.png) | ![](https://raw.githubusercontent.com/sniperTurk/flutter-app/9ac570ab7f98c3e65be3a9a4c4ea34b71ca6bf0d/latest/02_profil_muhimmat_pcp.png) | ![](https://raw.githubusercontent.com/sniperTurk/flutter-app/9ac570ab7f98c3e65be3a9a4c4ea34b71ca6bf0d/latest/03_pro_atesli_tufek.png) |

| Pro, Mühimmat sıcaklığı açık (not 1) | Pro, Mühimmat sıcaklığı açık (not 2) | Pro, PCP |
|---|---|---|
| ![](https://raw.githubusercontent.com/sniperTurk/flutter-app/9ac570ab7f98c3e65be3a9a4c4ea34b71ca6bf0d/latest/04_pro_atesli_muhimmat_not1.png) | ![](https://raw.githubusercontent.com/sniperTurk/flutter-app/9ac570ab7f98c3e65be3a9a4c4ea34b71ca6bf0d/latest/05_pro_atesli_muhimmat_not2.png) | ![](https://raw.githubusercontent.com/sniperTurk/flutter-app/9ac570ab7f98c3e65be3a9a4c4ea34b71ca6bf0d/latest/06_pro_pcp.png) |

Ekranda görülen ve dürüstçe not edilen farklar:
- **BC yalnız kalıyor:** ateşli "Listede yok" (elle) mühimmatta Kutudaki ağırlık tam satır olduğundan BC tek başına bir satırda, altında BC modeli | Mermi uzunluğu. PCP'de de (Tip | Ağırlık · BC · BC modeli | Mermi uzunluğu). Listeden seçilen ateşli mühimmatta Ağırlık | BC yan yana kalır. Bu, "BC modeli solda" kararının main düzenindeki sonucu; #368 PCP'de Ağırlık | BC yapıyor.
- **Etiket iki satır:** "Mermi uzunluğu" etiketi sağdaki "mm" ve ⓘ yüzünden iki satıra kırılıyor (Regülatör basıncı / Hız ölçüm sıcaklığı gibi); kutular yine aynı hizada. Birim kutunun içine #368 ile girecek.
- Onaylı çizimin PNG'si bu oturumda yoktu; karşılaştırma sahibin 11:34–11:41 sözlerine göre yapıldı.

### CI
- iOS CI (PR) kod commit'i 8bf68d8'de (uygulama kodu 47fd52c ile aynı, yalnız rapor eklendi): [run 39025082963](https://github.com/sniperTurk/flutter-app/actions/runs/39025082963) — `verify` success, `dart-checks` success, `wind-acceptance` success, `ios-simulator` atlandı (isteğe bağlı iş). Bu rapor commit'i yeni bir iOS CI çalıştırır; sonucu PR'ın Checks sekmesinde.
- test-diag, tüm `test` (47fd52c): [39023117479](https://github.com/sniperTurk/flutter-app/actions/runs/39023117479) success. Değişen 17 test dosyası tek tek de çalıştırıldı (ad18f33), hepsi success (ör. `mermi_uzunlugu_profil_test.dart` [39021809066](https://github.com/sniperTurk/flutter-app/actions/runs/39021809066), `muhimmat_sicakligi_bolum_test.dart` [39021810691](https://github.com/sniperTurk/flutter-app/actions/runs/39021810691)); `wez_tour_smoke_test.dart` (47fd52c) [39023116043](https://github.com/sniperTurk/flutter-app/actions/runs/39023116043) success.
- Ara bulgular ve düzeltmeleri: ilk tam koşuda `bc_modeli_secim_test` (eski PCP BC | BC modeli satırı), `pro_info_popup_test` (ⓘ sayfasının son kutusu) ve `wez_tour_smoke_test` (tur ekranı yeniden açınca 600 m kurulumu kayboluyordu) kırıldı; üçü yeni düzene göre güncellendi, hiçbir test zayıflatılmadı.
- analyze-diag (ad18f33): [39022302337](https://github.com/sniperTurk/flutter-app/actions/runs/39022302337) success. 
- format-fix (375209577): [39019762105](https://github.com/sniperTurk/flutter-app/actions/runs/39019762105) biçim commit'i 34718a1'i itti; sonraki [39022303667](https://github.com/sniperTurk/flutter-app/actions/runs/39022303667) değişiklik gerekmedi.
- Code Review + Security review: [PR yorumu](https://github.com/sniperTurk/flutter-app/pull/379#issuecomment-6233014764) (engelleyici bulgu yok).
- Birleştirme ve TestFlight yapılmadı.

---

# Önceki adım: barut notu (17.10 10:35)

## Sahibin kararı (İstanbul, 17.10.2026 10:28–10:35, TestFlight 112, Pro Ayarlar → Tüfek düzeltmeleri açık)
- "Mermi uzunluğu ve mühimmat sıcaklığı yan yana olacak."
- "İsteğe bağlıyı sil."
- Eski not için: "ben bile anlamadım … bu bilgi notunu değiştir"; yeni metinler için: "Yeni açıklama metin daha doğru ifade ediyor".

## Ne yapıldı
1. **Mermi uzunluğu | Mühimmat sıcaklığı yan yana.** Ateşli silahta iki kutu aynı satırda: Mermi uzunluğu solda, Mühimmat sıcaklığı sağda. "Yukarı + / aşağı −" | "Sağ + / sol −" satırıyla aynı iki kutulu satır (`MenzilFieldGrid`), aynı sütun genişlikleri. Birimler kutunun içinde (mm, °C; ABD birimlerinde °F, önceki gibi). Kutularda ⓘ yok (Pro açılır bölüm istisnası); açıklamalar bölüm başlığındaki ⓘ sayfasında, değişmedi.
2. **"isteğe bağlı" silindi.** Mühimmat sıcaklığı yanındaki yazı ve onun yerleşim kodu silindi; testlerdeki ilgili beklentiler de silindi/değiştirildi. Başlık ⓘ metni "isteğe bağlı" içermiyordu, dokunulmadı.
3. **Barut notu yeni metin** (`pro-powder-source`), sahibin onayladığı metinler harfi harfine, sayı biçimi aynı (`n(k)`, `n(t0)`):
   - Katsayı ya da hız ölçüm sıcaklığı yoksa: "Mühimmat sıcaklığının hesaba girmesi için Profil → Mühimmat'ta Barut katsayısı ve Hız ölçüm sıcaklığı kutularını doldurun. Bu iki kutu boşsa buraya yazılan sıcaklık hesabı değiştirmez."
   - İkisi de profilde: "Hesapta kullanılan: Barut katsayısı %1,5 / 15 °C, Hız ölçüm sıcaklığı 20 °C. Değiştirmek için Profil → Mühimmat."
   - İkisi de eski sürümde Pro'da girilmiş: "Hesapta kullanılan: Barut katsayısı %1,2 / 15 °C, Hız ölçüm sıcaklığı 21 °C. Bu değerler eski sürümde burada girilmişti; artık Profil → Mühimmat'ta değiştirilir."

## Nasıl
- Yalnız `lib/features/ballistics/pro_ayarlar_view.dart` (uygulama kodu). Mermi uzunluğu kutusu küçük bir yardımcıya (`_bulletLengthInput()`) alındı; aynı anahtar (`pro-bullet-length`), denetleyici, etiket, birim. Ateşli silahta `MenzilFieldGrid(key: 'pro-ammo-temp-row', [Mermi uzunluğu, Mühimmat sıcaklığı])`; PCP'de Mermi uzunluğu eskisi gibi tek başına tam satır.
- Mühimmat sıcaklığı kutusu aynı: anahtar `env-ammo-temp`, denetleyici `ammoTempCtl`, kayıt `ammoTemp`/`ammoTempText`, birim, klavye. Satır anahtarı `pro-ammo-temp-row` korundu (eski ekran görüntüsü turu da çalışsın diye).
- "Profilde yiv yönü veya yiv oranı yok" uyarısı eskiden Mermi uzunluğu ile Mühimmat sıcaklığı arasındaydı; iki kutu artık aynı satırda olduğu için uyarı satırın altına geldi (aynı koşul, aynı metin).
- `lib/ui/menzil_widgets.dart`'a dokunulmadı (PR #368 ile çakışmasın diye). `pro_ayarlar_view.dart` diff'i yalnız bu bölümde.

## Neden
Sahip TestFlight 112'de iki kutunun alt alta ve "isteğe bağlı" yazısının gereksiz durduğunu, notun anlaşılmadığını söyledi; yeni metinleri onayladı.

## Uç durumlar
- **PCP:** Mühimmat sıcaklığı ve barut notu yok (önceki gibi). Mermi uzunluğu bugünkü gibi tam satır (Gerçek / yazan kutusuyla aynı en). Böylece PCP düzeni hiç değişmedi.
- **Dar ekran / büyük yazı:** `MenzilFieldGrid`, Yukarı | Sağ satırıyla aynı kuralı uygular: sütun başına yer yetmezse (genişlik / yazı ölçeği < 300) iki kutu alt alta iner. 320 pt + 1,3 yazı ölçeğinde iki satır da alt alta iner, taşma yok (test). 320 pt + 1,0'da Mermi | Mühimmat satırı Yukarı | Sağ satırıyla aynı davranır (test).
- **"Eksik" koşulu:** kod `k == null || t0 == null` koşulunu kullanıyor, değiştirmedim. Yalnız profilde biri varsa ve eski Pro kayıtlarında ikisi varsa eski kayıt kullanılır (değişmedi). Etiketler `Barut katsayısı` ve `Hız ölçüm sıcaklığı` `lib/features/profiles/profile_editor_ammo_extra.dart`'ta (görev metnindeki `profile_editor_ammo.dart` değil); metinle aynı.
- **Bilgi (değiştirilmedi, kararı sahibin):** hesap (`PowderTemperature.factor`) katsayı |k| > 10 ya da hız ölçüm sıcaklığı −50…60 °C dışındaysa düzeltme yapmaz; bu durumda not yine "Hesapta kullanılan: …" der. Profil düzenleyici bu aralık dışını kabul ediyorsa ayrı görev olabilir. Katsayı 0 ise hız değişmez, not yine değerleri gösterir.
- **Kayıtlı veri:** kayıt anahtarları değişmedi; eski kayıtlı Mühimmat sıcaklığı ve eski Pro barut değerleri açılır (testler).

## Bilerek yapılmayan
- Hesap, varsayılan, bayrak, kayıt anahtarı, başka sayfa, başlık ⓘ metinleri, `EnvironmentFieldInfo.ammoTemperature` metni değişmedi.
- `lib/ui/menzil_widgets.dart` değişmedi.

## Testler
- `test/muhimmat_sicakligi_bolum_test.dart` (güncellendi): gerçek Pro sayfası, Tüfek düzeltmeleri açık, 390 pt: Mermi uzunluğu ve Mühimmat sıcaklığı aynı üst kenar (±0,5 pt), Mermi solda, sütunlar Yukarı | Sağ ile aynı (sol kenar ve en ±0,5 pt), satır Yukarı | Sağ'ın altında ve notun üstünde; "isteğe bağlı" yok; birimler mm ve °C; kutularda ⓘ yok, başlık ⓘ sayfasında Mühimmat sıcaklığı satırı. PCP: Mühimmat sıcaklığı yok, Mermi uzunluğu tam satır, not yok. 320 ve 390 pt, yazı ölçeği 1,3: taşma yok. Silinen tek test: "320 pt, yazı ölçeği 2: isteğe bağlı kesilmez" (silinen yazıya aitti).
- `test/pro_barut_not_test.dart` (yeni): üç not metni harfi harfine (eksik: ikisi boş / yalnız katsayı / yalnız sıcaklık; profilden; eski sürüm kaydından), eski metinler yok, 320 pt + 1,3'te not taşmıyor, 320 pt + 1,0 satır davranışı.
- `test/pro_barut_not_sayi_test.dart` (yeni): sabit bir ateşli silah profili (800 m/s, 1,5 %/15 °C, 20 °C), hava 15 °C, 600 m'de Hedef'in gereken üst açısı. Aynı test önce main @ 8cc3aab üzerinde çalıştırıldı (test-diag run [39014771706](https://github.com/sniperTurk/flutter-app/actions/runs/39014771706)), sayılar test içine yazıldı; dalda aynı sayılar 1e-9 hassasiyetle bekleniyor:
  - katsayılı, mühimmat boş: 5,603925379378539 mil; "Bugünkü hız: 2612 fps"
  - katsayılı, mühimmat 35 °C: 5,315103568534314 mil; "Bugünkü hız: 2664 fps" (800 × (1 + 0,015) = 812 m/s)
  - katsayısız, boş ve 35 °C: ikisi de 5,529980691211749 mil, "Bugünkü hız" yok.
- `test/support/pro_sections.dart`: silinen `pro-ammo-temp-optional` anahtarı çıkarıldı.
- `integration_test/pro_barut_not_screens_test.dart` (yeni): simülatör ekran turu.
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (421 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 915 test OK (1 atlandı).
- Yerelde Flutter SDK kurulamadı (Dart SDK indirmesi proxy'de 403): Flutter testleri yalnız CI'da çalıştı.

## Ekran görüntüsü
Simülatör: iPhone 16e (390 pt), iOS 26.2, `sim-screens` run [39014730169](https://github.com/sniperTurk/flutter-app/actions/runs/39014730169), tur `integration_test/pro_barut_not_screens_test.dart`, çıkış kodu 0. Uygulama kodu 82056a2 (sonraki commit yalnız test + rapor). Ölçülen kutular (SIMRECT, pt): ateşli silahta Mermi uzunluğu 28–190, Mühimmat sıcaklığı 200–362, ikisinin de üst kenarı aynı (474,4); PCP'de Mermi uzunluğu 28–362 (tam satır).

| Ateşli, not 1 (katsayı yok) | Ateşli, not 2 (profilden) | PCP |
|---|---|---|
| ![not1](https://raw.githubusercontent.com/sniperTurk/flutter-app/1d3c07914be92596a97f26c95b82f245189a1aa4/latest/01_pro_atesli_not1.png) | ![not2](https://raw.githubusercontent.com/sniperTurk/flutter-app/1d3c07914be92596a97f26c95b82f245189a1aa4/latest/02_pro_atesli_not2.png) | ![pcp](https://raw.githubusercontent.com/sniperTurk/flutter-app/1d3c07914be92596a97f26c95b82f245189a1aa4/latest/03_pro_pcp.png) |

Ekranda görülen: Mermi uzunluğu (mm) | Mühimmat sıcaklığı (°C) Yukarı | Sağ satırıyla aynı hizada; "isteğe bağlı" yok; not metni onaylı metinle aynı. PCP'de düzen önceki gibi (yiv bilgisi olmayan katalog tüfeğinde spin drift uyarısı, önceki gibi). Onaylı ayrı bir çizim yok; karşılaştırma sahibin TestFlight 112 ekran görüntüsündeki sözlerine göre.

## CI
Son kod commit'i 27df26b; sonraki commit'ler yalnız bu raporu değiştirir. iOS CI PR'ın son commit'inde de çalışır; sonucu PR'ın Checks sekmesinde. 27df26b sonuçları:
- iOS CI (PR): [run 39014931793](https://github.com/sniperTurk/flutter-app/actions/runs/39014931793) — `verify` success, `dart-checks` success, `wind-acceptance` success, `ios-simulator` atlandı (isteğe bağlı iş).
- test-diag (tüm `test`): [39014926238](https://github.com/sniperTurk/flutter-app/actions/runs/39014926238) success. İlk commit 82056a2'de de: [39014727322](https://github.com/sniperTurk/flutter-app/actions/runs/39014727322) success.
- analyze-diag: [39014927900](https://github.com/sniperTurk/flutter-app/actions/runs/39014927900) success.
- format-fix (375209577): [39014924729](https://github.com/sniperTurk/flutter-app/actions/runs/39014924729) — biçim değişikliği gerekmedi.
- Code Review + Security review: PR yorumunda (engelleyici bulgu yok).
- TestFlight çalıştırılmadı.

## Not
- Sayı karşılaştırması için açılan geçici dal `tmp/pro-barut-sayi-main` silinemedi (bu oturumdan dal silme izni yok); güvenle silinebilir.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01Q1U1eLrKmxvYnPejPENnsy
