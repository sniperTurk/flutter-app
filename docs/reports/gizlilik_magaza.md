# Gizlilik politikası ve mağaza metinleri (fix/gizlilik-magaza)

Sahip kararı: 2026-10-14, 10:26–10:30 (İstanbul) — App Store yayınına
hazırlık. Ad "Sniper Türk: Balistik", alt başlık "Ateşli ve PCP Tüfekler
İçin". "görev aç".

Bu PR taslaktır (draft). Birleştirilmedi, TestFlight başlatılmadı, App Store
Connect'e hiçbir şey gönderilmedi.

## 1. Uygulama içi gizlilik politikası (App Review 5.1.1(i))

**Nerede:** Araçlar sekmesi → listenin en altında, "Kullanım rehberi"nin
hemen altında **"Gizlilik politikası"** satırı (alt yazı: "Hangi veri
cihazda kalır, hangisi nereye gider"). Araçlar ana sekme olduğu için tek
dokunuşla açılır.

**Neden burası:** Araçlar'ın sonunda zaten bilgi amaçlı "Kullanım rehberi"
ve "SNIPER TÜRK • V1" alt yazısı var; uygulamanın "hakkında" bölümüne en
yakın yer burası. Profil sayfasının alt bölümü açık PR'larla (#285 "Profil
ekle" satırı, tüfek/mühimmat formları) çakışma riski taşıdığı için
seçilmedi.

**Nasıl çalışır:**
- Satır `PrivacyPolicyScreen` sayfasını açar (`lib/features/guide/privacy_policy_screen.dart`).
  Düzen Kullanım rehberi ile aynı: `MenzilPage`, her bölüm bir kart, sola
  yaslı metin, iPhone sistem yazısı, kalın yazı yok.
- Metin uygulamanın içinde gömülüdür; internet olmadan açılır.
- Tek kaynak `docs/app-store/03-gizlilik-politikasi.md` içindeki Türkçe
  bölümdür. `python3 tools/data_gen/generate_privacy_policy.py` bu bölümden
  `lib/features/guide/privacy_policy_content.dart` dosyasını üretir;
  `tools/test_privacy_policy_sync.py` ikisinin aynı olduğunu denetler.
- `privacyPolicyUrl = String.fromEnvironment('PRIVACY_POLICY_URL')`, boş
  varsayılan. **"Web'de aç" düğmesi eklenmedi:** uygulamada bağlantı açan
  bir yöntem yok (`url_launcher` vb. paket yok) ve görev yeni paket
  eklemeyi yasaklıyor. Adres verilirse sayfanın altında yalnızca
  seçilebilir metin olarak "Web adresi: …" görünür.

**Bilerek yapılmayan:** Profil sayfası, tüfek/mühimmat formları ve "Profil
ekle" satırı değişmedi. `Info.plist` izin metinleri değişmedi (ayrı onay).

## 2. Gizlilik belgeleri (02, 03)

**03-gizlilik-politikasi.md (TR/EN)** — yeniden yazıldı, kodla
karşılaştırıldı (`grep`):
- Eklendi: Google Maps SDK'nın topladığı veriler (Google'ın bildirimine
  göre), barometre ("Basıncı telefondan al" bir kez okur), bu düğmenin GPS
  irtifası, Pro'daki "Kamerayla ölç" kamerası, Profil yedeği (Yedekle /
  Geri yükle, `share_plus` + `file_selector`), kronograf, atış günlüğü,
  paralaks işaretleri (cihazda).
- MET Norway: konum 2 ondalığa (~1 km) yuvarlanıp gönderilir, saklanmaz
  (`WeatherPolicy.roundCoordinate`, bellek önbelleği).
- `[[...]]` yer tutucuları politika metninden çıkarıldı (uygulamada
  görünmesin diye); sahibin dolduracakları dosyanın başındaki nota taşındı.
  Tarih: 14 Ekim 2026.

**02-gizlilik-etiketi.md** — `main @ 237c14d` ile yeniden doğrulandı:
veri akışı tablosuna barometre, GPS irtifası, profil yedeği, "Kamerayla
ölç", pusula eklendi; Google kaynağı resmî sayfa ile verildi; Apple Watch
köprüsünün yayın derlemesinde olmadığı not edildi; uyuşmazlık listesi
"durum" listesine çevrildi (uygulama içi bağlantı: yapıldı).

**Google Maps kaynakları (yalnız üretici):**
- Google, "Maps SDK for iOS — Apple App Store Privacy Details",
  https://developers.google.com/maps/documentation/ios-sdk/apple-privacy-policy ,
  okunma 2026-10-14 (sayfada "Last updated 2026-08-25 UTC"). Alıntı:
  "Google Maps Platform SDKs' privacy manifests disclose data that is always
  collected and collected by default."
- Google'ın SDK ile dağıttığı gizlilik bildirimi:
  `GoogleMaps.bundle/PrivacyInfo.xcprivacy` (GoogleMaps pod'u) — Crash Data
  (bağlı değil), Device ID (bağlı; Analytics + App Functionality), Other Data
  Types (bağlı), Performance Data ve Product Interaction (bağlı değil);
  izleme yok. Dosya içeriği `ci/privacy-dump` dalı `out/privacy.txt`
  (2026-10-10 macOS derlemesi). `google_maps_flutter_ios` 2.18.6 bildirimi
  ayrıca User ID (bağlı) sayar.
- Google sayfası veri türlerini tablo olarak vermiyor, bildirime
  yönlendiriyor; bu yüzden türler bildirim dosyasından alındı.

## 3. Mağaza metinleri (01)

| Alan | Önce (835b956 taslağı, önerilen) | Sonra (bu PR) |
|---|---|---|
| Ad (TR) | `SNIPER TÜRK: Balistik` — 21 karakter | `Sniper Türk: Balistik` — 21 karakter, **sahip seçimi 2026-10-14** |
| Alt başlık (TR) | `Tüfek ve PCP balistik çözüm` — 27 karakter | `Ateşli ve PCP Tüfekler İçin` — 27 karakter, **sahip seçimi 2026-10-14** |
| Anahtar kelimeler (TR) | `dope,dürbün,retikül,rüzgar,kule,klik,moa,mil,menzil,atış,mermi,havalı,coriolis,avcı` — 91 bayt | `dope,dürbün,retikül,rüzgar,kule,klik,moa,mil,menzil,atış,mermi,havalı,coriolis,avcı,saçma` — **98/100 bayt** |
| Ad (EN) | `SNIPER TÜRK: Ballistics` — 23 | `Sniper Türk: Ballistics` — 23 (TR seçimin çevirisi, sahip onayı bekliyor) |
| Alt başlık (EN) | `Rifle & PCP ballistic solver` — 28 | `For Firearms and PCP Rifles` — 27 (çeviri, sahip onayı bekliyor) |
| Anahtar kelimeler (EN) | `dope,scope,reticle,wind,turret,click,moa,mil,range,shooting,bullet,airgun,coriolis,hunting,long` — 95 bayt | `dope,scope,reticle,wind,turret,click,moa,mil,range,shooting,bullet,airgun,coriolis,hunting,pellet` — **97/100 bayt** |

Diğer seçenekler tabloda "seçilmedi / not chosen" olarak duruyor. Anahtar
kelimeler ad ve alt başlıktaki kelimeleri (sniper, türk, balistik, ateşli,
ve, pcp, tüfekler, için) tekrar etmiyor; `check_lengths.py` artık bunu da
denetliyor ("tüfek" kelimesi "tüfekler"den ayrı bir biçim olduğu hâlde
temkinli olmak için eklenmedi).

**Çıkarılan eskimiş iddialar:**
- "GA" sürüklenme modeli (#195'te kaldırıldı; saçmalar G1 ile hesaplanır).
- "Balistik tablo" / Hedef → Tablo görünümü ("Tek atış | Tablo" seçici
  2026-10-12'den beri gizli, `SHOT_TABLE_SWITCH`). DOPE kartı PDF kaldı.
- "Hesap ve veriler cihazında kalır" (Google Maps SDK veri topladığı için
  doğru değil) → "profillerin cihazında kalır".
- "Tıklama", "vuruş olasılığı" gibi eski adlar güncel ekran adlarına çevrildi.

**Eklenen güncel özellikler:** G1/G2/G5/G6/G7/G8/GI/RA4 ve kendi Mach–Cd
eğrisi (ateşli), PCP her zaman G1 (bkz. "İnceleme düzeltmesi"); her kutuda ⓘ; listeden seçim ve "listede yok" ile elle giriş; profil
yedekleme; barometre ve GPS irtifası; "Rüzgâr tahmini nasıl yapılır?"
rehberi; Pro açıklamaları alttan açılan sayfada; rüzgâr düzeltmesi; Hesap
dökümü; Kronograf, Paralaks Mesafesi (PCP), Avcı Sıfırı, Atış Öncesi
Kontrol, Sıfır Grubu, Atış Günlüğü, Kullanım rehberi. İngilizce metinde
"arayüz yalnızca Türkçe" notu duruyor.

`check_lengths.py` çıktısı (2026-10-14, inceleme düzeltmesinden sonra):

```
OK  Tanıtım metni (≤ 170): 167/170 chars
OK  Açıklama: 2656/4000 chars
OK  Anahtar kelimeler (≤ 100 bayt): 98/100 bytes
OK  Yenilikler (1.0.0): 353/4000 chars
OK  Promotional text (≤ 170): 160/170 chars
OK  Description: 2537/4000 chars
OK  Keywords (≤ 100 bytes): 97/100 bytes
OK  What's New (1.0.0): 350/4000 chars
OK  Türkçe (tr) keywords repeat no name/subtitle word
OK  English (en-US) keywords repeat no name/subtitle word
ALL OK
```

**06-ekran-goruntusu-plani.md:** 2. görsel "Hedef → Tablo" yerine "Hedef:
Hesap dökümü ve DOPE kartını paylaş (PDF)"; eski görsellerin yeniden
çekilmesi gerektiği işaretlendi. **05:** 5.1.1(i) "çözüldü"; inceleme notuna
gizlilik sayfasının yeri eklendi. **README:** "Öne çıkan bulgular"
güncellendi.

## İnceleme düzeltmesi (2026-10-14, ana oturum incelemesi sonrası)

**Bulgu:** açıklama (TR ve EN) PCP için "G1, G7 ve GS" modelleri diyordu.
Bu yanlıştı. main'de PCP saçma ve slug **her zaman G1** ile hesaplanır
(sahip kararı 2026-10-12): `profiles_screen.dart` içinde
`_bcModelForSave => platform == WeaponPlatform.pcp ? BallisticModel.g1 : ammoBcModel`,
ve "BC modeli" kutusu `if (platform != WeaponPlatform.pcp)` ile PCP'de hiç
gösterilmez. Kendi Mach–Cd eğrisi ("Özel eğri (Mach–Cd)") yalnız bu kutudan
seçildiği için PCP'de yoktur, yalnız ateşli tüfekte vardır.

**Düzeltme (`01-magaza-metinleri.md`):**

| | Önce | Sonra |
|---|---|---|
| TR | "Ateşli tüfekte G1, G2, G5, G6, G7, G8, GI ve RA4; PCP'de G1, G7 ve GS sürüklenme modelleri. Saçmalar (pellet) G1 ile hesaplanır" + "İsterseniz merminin kendi Mach–Cd eğrisi (.drg/.csv)" | "Ateşli tüfekte G1, G2, G5, G6, G7, G8, GI ve RA4 sürüklenme modelleri ya da merminin kendi Mach–Cd eğrisi (.drg/.csv)" + "PCP saçma ve slug her zaman G1 ile hesaplanır" |
| EN | "…; G1, G7 and GS for PCP. Pellets are calculated with G1" + "Optionally the bullet's own Mach–Cd drag curve" | "…RA4 drag models for firearms, or the bullet's own Mach–Cd drag curve (.drg/.csv)" + "PCP pellets and slugs are always calculated with G1" |
| TR/EN gizlilik satırı | "Harita için Google Maps SDK kullanılır" / "The map uses the Google Maps SDK" | "Harita görüntüsü Google Maps SDK veya Esri'den gelir" / "Map imagery comes from the Google Maps SDK or Esri" — Google haritası yalnız `GOOGLE_MAPS_ENABLED=true` derlemede gösterilir (`map_distance_screen.dart`), yoksa Esri |

Uygulama içi gizlilik metninde ve kullanım rehberinde model iddiası yok;
değişmedi.

**Diğer iddiaların yeniden doğrulaması (main @ 47b7ab0, `grep`):**
- Ateşli BC modeli listesi `_bcModelChoices`: G1, G2, G5, G6, G7, G8,
  GI (Ingalls), RA4 + "Özel eğri (Mach–Cd)" — kutu ateşli tüfekte görünür.
- Araçlar: listedeki 15 araç `tools_screen.dart`'ta bayraksız görünür;
  Paralaks Mesafesi yalnız PCP profilinde (metinde "(PCP)" yazıyor).
- Hesaplayıcılar: stadyametrik, retikül (mil-dot), mesafe, özel konum,
  mesafedeki MOA, klik değeri doğrulama, 2 hızdan BC, enerji ve güç, hava
  laboratuvarı, birim dönüştürücüler — hepsi görünür.
- Pro: Açı + "Kamerayla ölç", Dürbün eğimi, Rüzgâr düzeltmesi, Coriolis,
  Yerel yerçekimi, Hareketli hedef, İsabet olasılığı (WEZ), Kule ölçek
  katsayısı, Sıfır ofseti, Mermi uzunluğu / spin drift; açıklamalar alttan
  sayfada — hepsi bayraksız.
- Hava Durumu: MET Norway sıcaklık, nem, rüzgâr hızı doldurur;
  "Basıncı telefondan al" barometre + GPS irtifası; "Rüzgâr tahmini nasıl
  yapılır?" bağlantısı. Rüzgâr gözlemi `WIND_OBSERVATION` ile gizli —
  metinde yok.
- Hedef: "Hesap dökümü" her çözümde görünür; "DOPE kartını paylaş (PDF)";
  Tablo görünümü `SHOT_TABLE_SWITCH` ile gizli — metinde yok.
- Profil: "Yedekle" / "Geri yükle" Profil sayfasında görünür (karşılama
  ekranındaki geri yükleme `WELCOME_RESTORE` ile gizli; metin yalnız
  Profil'deki düğmeyi anlatıyor).
- Tüfek/dürbün "Listede yok" gizli, ama "Aradığın … listede yok mu?"
  bağlantısı elle girişi açar — "listede yoksa elle girilir" doğru.

`check_lengths.py`: ALL OK (TR açıklama 2656/4000, EN 2537/4000; diğer
sayılar değişmedi).

Dal yeniden yazılmadı: "rebase" yerine güncel main (`47b7ab0`, #295)
birleştirme commit'iyle alındı (`b550ae2`), böylece zorla itme gerekmedi;
çakışma yoktu. Yerel: lint PASS (334 dosya, 0 sorun), Python testleri OK,
`check_lengths.py` ALL OK.

CI, baş `0ea4ef5` (işler `ref: fix/gizlilik-magaza` ile checkout eder):

| İş | Sonuç | Bağlantı |
|---|---|---|
| Dart format | Başarılı — değişiklik yok, commit itilmedi | https://github.com/sniperTurk/flutter-app/actions/runs/38535023120 |
| Testler (tüm `test/`) | Başarılı (çıkış kodu 0) | https://github.com/sniperTurk/flutter-app/actions/runs/38535026195 |
| Analiz (`--fatal-infos --fatal-warnings`) | Başarılı (çıkış kodu 0) | https://github.com/sniperTurk/flutter-app/actions/runs/38535029798 |

Bu tabloyu ekleyen commit yalnız bu rapor dosyasını değiştirir.

## 4. Sahibin yapması gerekenler

1. Gizlilik politikasını web'de yayınlamak: yayındaki `PRIVACY_POLICY_URL`
   sayfasını `03` metniyle değiştirmek (eski metinde Google Maps SDK,
   barometre, profil yedeği yok). İstenirse aynı adresi derlemede
   `--dart-define=PRIVACY_POLICY_URL=…` ile vermek (uygulamada metin olarak
   görünür).
2. Destek URL'si (zorunlu), isteğe bağlı pazarlama URL'si, telif satırı.
3. App Store Connect → App Privacy formu: `02` §3 tablosu (Device ID, User
   ID, Other Data bağlı; Coarse Location, Crash, Performance, Product
   Interaction bağlı değil; izleme yok).
4. Yaş anketi: Guns or Other Weapons = Frequent → **13+**.
5. Ekran görüntüleri: `06`'ya göre yeniden çekim (6.9" + 6.3").
6. EN ad/alt başlık çevirisini onaylamak.
7. İzin metinleri (`04`) için ayrı kod PR'ına onay.
8. Yayın arşivinde Xcode "Generate Privacy Report" ile `02`'yi teyit.

## 5. Testler

- `test/gizlilik_politikasi_test.dart` (widget):
  - Araçlar sekmesinden "Gizlilik politikası" satırı görünür, Kullanım
    rehberi'nin altında; dokununca sayfa açılır, başlık "SNIPER TÜRK —
    Gizlilik Politikası" ve bilinen cümle ("Uygulama bir hesap
    yardımcısıdır; sonuçlar gerçek atışla doğrulanmalıdır.") görünür.
  - URL boşken "Web'de aç" ve web adresi yok; URL verilince yalnız metin.
  - 60 karakterden uzun her paragraf sola yaslı, sistem yazısı, kalın değil.
  - 320 pt genişlik + yazı ölçeği 1,3: taşma yok, kartlar ekranda.
- `tools/test_privacy_policy_sync.py`: uygulama metni = 03'teki Türkçe
  bölüm; tüm veri akışları adıyla geçiyor; işaretleme/yer tutucu yok;
  `PRIVACY_POLICY_URL` sabiti ve Araçlar girişi var; `url_launcher` yok.
- `tools/test_v271_removed_feature_scope.py`: Araçlar 16 satır,
  `tool-privacy-policy` dahil.

Yerel (Flutter SDK yok, bu ortamda Dart çalışmaz):
- `python3 tools/offline_dart_lint.py` → PASS (0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'` → OK
- `python3 docs/app-store/check_lengths.py` → ALL OK
- `python3 tools/app_store_preflight.py --privacy-url https://example.org/gizlilik`
  → **BLOCKED**: "iOS scaffold is absent" (iOS iskeleti yalnız macOS CI'da
  üretilir; çevrimdışı tam çalışmıyor). Gizlilik URL'si verilmezse ayrıca
  "privacy policy URL is not configured".

## 6. CI

Hepsi `fix/gizlilik-magaza` dalında çalıştı (iş günlüğünde checkout
`ref: fix/gizlilik-magaza` görülüyor):

| İş | Commit | Sonuç | Bağlantı |
|---|---|---|---|
| Dart format (375209577) | `fe758c4` | Başarılı — "Formatted 330 files (0 changed)", commit gerekmedi | https://github.com/sniperTurk/flutter-app/actions/runs/38530518245 |
| Testler (`test-diag.yml`, `files=test`, tüm test klasörü) | `c9e2422` | Başarılı — `flutter test` çıkış kodu 0 (yeni `gizlilik_politikasi_test.dart` dahil). Görünen "Which: KESIK…" ve yığın satırları geçen testlerin tanı çıktısıdır, hata değil | https://github.com/sniperTurk/flutter-app/actions/runs/38530828157 |
| Analiz (`analyze-diag.yml`, `--fatal-infos --fatal-warnings`) | `c9e2422` | Başarılı — çıkış kodu 0 | https://github.com/sniperTurk/flutter-app/actions/runs/38530831430 |

`c9e2422` = kod commit'i + `main @ 69e8a0e` birleştirmesi. Sonraki
commit'ler yalnız belge (`docs/`, `check_lengths.py`) ve Dart kodunu
değiştirmez. Son başa (head) göre yeniden çalıştırılan işler aşağıda.

Son baş `70c9e89` (yalnız belge değişikliği sonrası) için yeniden:

| İş | Commit | Sonuç | Bağlantı |
|---|---|---|---|
| Dart format | `70c9e89` | Başarılı — değişiklik yok, commit itilmedi | https://github.com/sniperTurk/flutter-app/actions/runs/38531401672 |
| Testler (tüm `test/`) | `70c9e89` | Başarılı (çıkış kodu 0) | https://github.com/sniperTurk/flutter-app/actions/runs/38531404441 |
| Analiz | `70c9e89` | Başarılı (çıkış kodu 0) | https://github.com/sniperTurk/flutter-app/actions/runs/38531407658 |

Bu satırı ekleyen commit de yalnız bu rapor dosyasını değiştirir.

**Takip çalışması (2026-10-14 11:13 İstanbul):** görev ikinci kez çalıştı.
PR #294 zaten açık olduğu için yeni dal/PR açılmadı; aynı dal kullanıldı.
`main @ 64bc3cd` (#290 araştırma, #293 CLAUDE.md) çakışmasız birleştirildi
(`daac985`); uygulama kodunda değişiklik yok. İstenen her madde yeniden
kontrol edildi: `url_launcher`/`launchUrl` gibi bağlantı açma yöntemi hâlâ
yok (o yüzden "Web'de aç" yok); `generate_privacy_policy.py` yeniden
çalıştırıldı, uygulama metni 03 ile aynı; açık PR #295 ve #296 bu PR'ın
dosyalarına dokunmuyor. Yerel: lint PASS (333 dosya, 0 sorun), Python
testleri OK (744), `check_lengths.py` ALL OK.

Baş `daac985` için CI (işler `ref: fix/gizlilik-magaza` ile checkout eder):

| İş | Sonuç | Bağlantı |
|---|---|---|
| Dart format | Başarılı — değişiklik yok, commit itilmedi (dal başı `daac985` kaldı) | https://github.com/sniperTurk/flutter-app/actions/runs/38533751488 |
| Testler (tüm `test/`) | Başarılı (çıkış kodu 0; "failure" görünen ek açıklamalar geçen testlerin tanı yığınlarıdır) | https://github.com/sniperTurk/flutter-app/actions/runs/38533754594 |
| Analiz (`--fatal-infos --fatal-warnings`) | Başarılı (çıkış kodu 0) | https://github.com/sniperTurk/flutter-app/actions/runs/38533757564 |

iOS Simulator derlemesi, TestFlight ve App Store işlemleri **çalıştırılmadı**.

---
_Generated by [Claude Code](https://claude.ai/code)_
