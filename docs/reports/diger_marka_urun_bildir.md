# Mühimmat: "Diğer marka" ve "Aradığın mühimmat listede yok mu?" bildirimi (2026-10-17)

Sahibin kararları (2026-10-17, İstanbul, TestFlight 113, Profil Oluştur →
Mühimmat):

- 21:26 "Diğer marka seçeneği olsun, mühimmat kataloğumuz çok eksik.
  Kullanıcı diğer seçerse otomatik gelen Model kısmı dolu gelmesin."
- 21:29 "Model yine select … kalibre 6.35 seçtiyse yazsın, ağırlığı kullanıcı
  manuel girsin." 21:30 dolu, kapalı kutu. 21:31 "select işaretini kaldır",
  "dolu gelecek kutu". 21:33 PCP ve ateşli ("tabii ki"). 21:53 Model kutusu:
  "Diğer marka model 6,35".
- 21:33–21:51 "Aradığın mühimmat listede yok mu?" tek kutulu bir pencere
  açar; yazılan metin Cloudflare kutumuza gider, profili değiştirmez.
  Bağlantı Mühimmat kartının en altında. 21:51 "tamam görevi aç".

Dal: `feat/diger-marka-urun-bildir`. Taslak PR; birleştirmeyi sahibin ana
oturumu yapar. TestFlight yok.

## Ne

**A) "Diğer marka"**

- Mühimmat **Marka** listesinin son maddesi "Diğer marka": PCP (pellet ve
  slug) ve ateşli (Fabrika fişeği ve El dolumu). Tek bir "diğer" yolu kaldı.
- Seçilince: katalogdan hiçbir değer gelmez (Model, Ağırlık, BC, Mermi
  uzunluğu boş; daha önce seçili bir katalog mühimmatının değerleri
  silinir). PCP'de Tip, ateşlide Mühimmat türü yerinde kalır.
- **Model** tam genişlikte, dolu, açılmayan kutu: ok işareti yok, dokununca
  liste veya klavye açılmaz. Metin "Diğer marka model <kalibre>":
  PCP 6,35 mm → "Diğer marka model 6,35", 5,50 mm → "Diğer marka model
  5,50"; ateşli → "Diğer marka model .308 Win"; yalnız çap (fişek adı yok) →
  sayı, birimsiz ("Diğer marka model 7,82"); kalibre yoksa "Diğer marka
  model". Kalibre değişince metin de değişir.
- Ağırlık (gr), BC, BC modeli, Mermi uzunluğu, PCP En düşük / En yüksek hız
  kullanıcı tarafından yazılır; doğrulama bugünkü elle girişle aynı (ateşlide
  kalibreye göre mantıklı ağırlık aralığı, gram karşılığı birim alanında; BC
  modeli G1/G7, "Seçiniz"den; PCP'de BC boş bırakılabilir, BC modeli G1).
- Kayıt: bugünkü kişisel mühimmat kaydıyla (yeni veri modeli yok). Marka
  "Diğer marka", Model "Diğer marka model 6,35". Profil özetinde "Mühimmat
  Marka/Model" satırı "Diğer marka model 6,35" gösterir (marka bir kez).
- Silinenler (bayrakla gizlenmedi, koddan silindi): ateşli elle girişteki
  "tüm markalar + Diğer" listesi ve yazılan Marka/Model kutuları, ateşli
  "Ağırlık listesi + Listede yok", "Kalibre seçin" uyarısı, "Listeye dön"
  ve onay penceresi, PCP yazılan Marka | Model kutuları, `AMMO_LISTEDE_YOK`
  bayrağı ve Marka listesindeki gizli "Listede yok" maddesi, bağlantının
  eski "elle girişi aç" davranışı.
- ⓘ metinleri (profile_field_info.dart): `ammoBrandPick` (ateşli Marka,
  artık listede ⓘ olarak görünür), `pcpAmmoBrand`, `ammoNothingListed`
  "Diğer marka"yı anlatıyor. Kullanılmayan `ammoBrandOther`,
  `pcpAmmoBrandTyped`, `pcpAmmoModelTyped`, `ammoModelTyped`, `grainPick`
  silindi.

**B) "Aradığın mühimmat listede yok mu?"**

- Bağlantı Mühimmat kartının **son** öğesi, tüm kutuların altında, sola
  yaslı, tam genişlik (PCP ve ateşli, liste ve Diğer marka durumunda).
- Dokununca pencere: başlık "Aradığın mühimmat listede yok mu?", metin
  birebir sahibin metni, tek kutu "Marka, model, ağırlık" (kutunun içinde
  "örn. H&N Slug HP 50 gr", altında yardım metni yok), en çok 200 karakter,
  düğmeler "Vazgeç" | "Gönder". Boşken (yalnız boşluk dahil) Gönder kapalı;
  gönderim sürerken de kapalı (çift gönderim yok).
- Gönder → HTTPS POST
  `https://sniper-turk-urun-kutusu.sekerbirol76.workers.dev/urun`,
  `Content-Type: application/json`, gövde:
  `{"tur":"muhimmat","platform":"ios","uygulamaSurumu":"1.0.0+<derleme>","kurulumKimligi":null,"alanlar":{"metin":…,"silah":"pcp|atesli","kalibre":…,"okunanAgirlikGr":…,"okunanBirim":"gr|g|null"}}`.
  `metin` kullanıcının yazdığının aynısı. `kalibre` Tüfek kartındaki
  Kalibre kutusunun metni ("6.35 mm (.25)", ".308 Win"), yoksa null.
  `okunanAgirlikGr`: son "sayı + birim" (virgül veya nokta): "g", "gram" →
  grama göre ×15,4323584 grain; "gr", "gr.", "grain", "grn" → grain; birim
  yoksa/bilinmiyorsa null. Okunamaması gönderimi engellemez.
- Başarı (201 + `ok:true`) → pencere kapanır, "Teşekkürler, bilgin bize
  ulaştı." Hata, bağlantı yok veya 10 sn zaman aşımı → pencerede "Şu an
  gönderilemedi. İnternet bağlantını kontrol edip tekrar dene."; yazı
  kalır, tekrar denenebilir. Gönderim profili hiç değiştirmez.
- Ağ kodu port/adaptör arkasında: `lib/tools/ports/product_report.dart`,
  `lib/tools/adapters/cloudflare_product_report.dart`, gövde ve ağırlık
  okuma `lib/features/profiles/ammo_report.dart`, pencere
  `lib/features/profiles/ammo_report_dialog.dart`; `ToolsServices`
  üzerinden verilir, testler sahte (`TestProductReport`) kullanır. URL sabit
  (gizli değil). Konum, profil bilgisi, cihaz kimliği gönderilmez.
- `uygulamaSurumu`: "1.0.0+<TestFlight derleme numarası>".
  `ios-testflight.yml`'e `--dart-define=APP_BUILD_NUMBER="${GITHUB_RUN_NUMBER}"`
  eklendi (TestFlight'ın gösterdiği numaranın aynısı). Diğer derlemelerde
  "1.0.0+dev".

**C) Gizlilik**: `docs/app-store/03-gizlilik-politikasi.md` (TR + EN):
"Kısaca" bölümü ve bölüm 6'ya bildirim paragrafı, üçüncü taraflara
Cloudflare. `docs/app-store/02-gizlilik-etiketi.md`: veri akışı tablosuna
satır, "Data Not Linked to You → User Content → Other User Content (App
Functionality)" önerisi.

## Nasıl

- Durum tek bayrakta: `_ammoOther` (eski `_ammoManual`, `_ammoBrandOther`,
  `_grainOther` silindi). Model metni ve salt okunur kutu her `_update`
  sonrasında `_syncOtherAmmoModel` ile kalibreye göre güncellenir; kayıtta
  da aynı metin yazılır.
- `MenzilInput`'a `readOnly` eklendi (klavye, imleç, seçim yok; görünüm
  aynı).

## Neden

Katalog eksik; kullanıcı listede olmayan mühimmatla da profil kurabilmeli,
ama yazılan ürün adları hatalı olduğu için ad yerine sabit "Diğer marka
model <kalibre>" yazılıyor. Eksik ürünü bize bildirmek için bağlantı ayrı bir
pencere oldu; ürün sonra üreticinin verisiyle kataloğa eklenecek.

## Uç durumlar

- **Eski kayıtlar** (2026-10-17 öncesi elle girilmiş, listede olmayan
  mühimmat): "Diğer marka" durumunda açılır, Model kutusunda kayıtlı
  "Marka Model" yazar (örn. "Eski Marka Eski Fişek"); değerler ve kayıtlı
  BC basamakları korunur, Güncelle markayı ve modeli değiştirmez. En az
  şaşırtan seçenek buydu: veri değişmiyor, kullanıcı kendi yazdığı adı
  görüyor. Marka seçilmeden kaydedilmiş eski PCP mühimmatı ("Özel yapım")
  da böyle açılır.
- Diğer marka'dan listedeki bir markaya dönülürse Model listesi geri gelir;
  yazılmış ağırlık/BC model seçilince üzerine yazılır.
- Fabrika fişeğinden gelen namlu çıkış hızı ve barut değerleri Tüfek/Ek
  mühimmat kartında olduğu için Diğer marka seçince silinmez (bugünkü elle
  giriş de silmiyordu).
- Kalibresinde listede ürün olmayan tüfek: Marka listesinde yalnız "Diğer
  marka" vardır; ⓘ nedenini söyler (`ammoNothingListed`).
- Çok uzun kartuş adı tek satıra sığmazsa Model kutusunda kayar (metin kutusu
  "…" ile kısaltamaz).

## Bilerek yapılmayan

- Tüfek ve dürbün "listede yok" akışları, katalog, hesap, diğer sayfalar,
  worker ve `sniperTurk/kullanici-urunleri` deposu değişmedi.
- Pencere kutusunda ⓘ yok: açıklama pencerenin kendi metni (sahibin
  çizimi). Ağırlık okuma yalnız gönderilen bilgiye eklenir, uygulamada
  kullanılmaz.
- Testlerden ve CI'dan gerçek worker'a istek atılmadı; simülatör turunda da
  Gönder'e basılmaz (Vazgeç). Uçtan uca kontrol ana oturumda TestFlight'ta.

## Testler

- Yeni: `test/diger_marka_test.dart` (Diğer marka son madde PCP/ateşli,
  Model metni 6,35 / 5,50 / .308 Win / kalibresiz, ok yok, dokununca liste
  yok, katalog değeri gelmiyor, kayıt ve yeniden açma, özet kartı, eski
  ateşli ve PCP kayıtlar, bağlantı kartın son öğesi 390/320 pt × 1,0/1,3,
  pencere metinleri birebir, Gönder boşken kapalı, 200 karakter, sahte
  servise giden JSON "50gr"→50, "3,24 g"→≈50,0, "3.24 gram"→≈50,0, "50
  grain"→50, "abc"→null, başarı/hata mesajları, tekrar deneme, çift gönderim
  yok, 320 pt × 1,3 taşma yok, hesap eşitliği) ve `test/ammo_report_test.dart`
  (ağırlık okuma, JSON, worker sınırları, adaptör: HTTPS POST, 201, hata,
  çevrimdışı, 10 sn zaman aşımı).
- Hesap: Diğer marka ile .308 Win, 168 gr, BC 0,462 G1, 31,2 mm, 2650 fps
  kaydı, aynı değerlerle eski elle giriş kaydıyla aynı çözücü sonucunu verir
  (100/300/600/1000 m; düzeltme, düşüş, rüzgâr, hız birebir eşit).
  [[HESAP_SAYILARI]] Ateşli altın sayılar (`test/core/hedef_golden_numbers_test.dart`)
  değişmedi (dosyaya dokunulmadı; CI'da geçti).
- Silinen özelliğe ait olduğu için yeniden yazılan/kaldırılan testler:
  `test/atesli_elle_muhimmat_test.dart` (Diğer listesi, Ağırlık listesi,
  Kalibre uyarısı, Listeye dön testleri silindi; BC/barut/özet ve liste
  akışı testleri kaldı), `pcp_muhimmat_tasarim_test.dart` (bağlantı satırı
  en alta; "yazılan Marka | Model" testi Diğer marka testine dönüştü).
  Yolu değişen (iddiaları aynı) testler: `audit_2026_10_14b/ammo_bc_audit_test.dart`,
  `audit_2026_10_15b/profil_split_audit_test.dart`, `bc_info_ornek_test.dart`,
  `tur_zorunlu_test.dart`, `profile_editor_fail_closed_test.dart`,
  `prf7_tur_kalibre_test.dart` (listesiz kalibrede yalnız "Diğer marka"),
  `user_catalog_test.dart`, `rifle_not_listed_test.dart`, `support/rifle_form.dart`.
- Python: `AMMO_LISTEDE_YOK` bayrak listelerinden çıkarıldı (bayrak silindi),
  bayrak sayısı alt sınırı 10 → 9; yeni adaptör izinli ağ dosyalarına,
  `APP_BUILD_NUMBER` izinli TestFlight define'larına eklendi (sayı, UI
  bayrağı değil).
- Yerel: `python3 tools/offline_dart_lint.py` PASS; `python3 -m unittest
  discover -s tools -p 'test_*.py'` OK (915, 1 atlanan). Bu ortamda Flutter
  SDK indirilemedi (storage.googleapis.com engelli); Dart testleri CI'da.

## Ekran görüntüleri

[[EKRANLAR]]

## CI bağlantıları

[[CI]]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
