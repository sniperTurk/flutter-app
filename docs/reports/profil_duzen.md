# Profil düzeni: her giriş yolu son tasarımla açılır

Sahip kararları (14 Ekim 2026, İstanbul, Profil Oluştur / Profili Düzenle):

- 16:56 "Sayfalar son yaptığımız düzenleme ile açılsın; bir şey ekleyip çıkardığımızda yaptığımız işler bozulmasın."
- 17:00–17:02 üç düzeltme (Model kutusu, eksik listesi, Barut katsayısı).
- 17:12 "Önce uygulama istediğimiz şekline gelsin, sonra bakacağız. Şimdilik bir şeyleri silip hata yapmak istemiyoruz."

**Hiçbir şey silinmedi.** Gizli bayrakların hiçbiri (SCOPE_LISTEDE_YOK, RIFLE_LISTEDE_YOK, AMMO_LISTEDE_YOK,
AMMO_BC_BANDS_TYPED, PCP_AMMO_BRAND, PROFILE_AMMO_LENGTH, …) değişmedi; eski kod yolları duruyor.
Kayıtlı kullanıcı verisi hiçbir yolda değiştirilmiyor (aşağıda "Eşleşme kuralları").
Hesap, katalog verisi ve diğer sayfalar değişmedi.

## Değişen dosyalar

- `lib/features/profiles/profile_catalog_match.dart` (yeni): kayıtlı Tüfek / Dürbün'ü listelerde toleranslı bulan kurallar.
- `lib/features/profiles/profiles_screen.dart`: açılışta eşleşme (eski tam eşleşme kuralı aynen ilk sırada), eksik listesi, Model kutuları, Barut katsayısı etiketi.
- `lib/ui/menzil_widgets.dart`: `MenzilSelect`'e isteğe bağlı `wrapSelected` (varsayılan kapalı; yalnız Dürbün ve Tüfek Model kullanıyor).
- `test/profil_duzen_koruma_test.dart` (yeni): koruma testleri.

## 1. Giriş yolları: önce / şimdi

| Giriş yolu | Önce | Şimdi |
|---|---|---|
| Yeni profil | Son tasarım (Marka → filtreler → Model → Dürbün ayağı \| Üst kule → Retikül → "Dürbün: …" → bağlantı) | Aynı (değişmedi; testle sabitlendi) |
| Düzenle: listeden seçilmiş, bugünkü adla kayıtlı dürbün/tüfek | Liste modunda, filtreler gizli | Aynı |
| Düzenle: 13 Ekim katalog güncellemesinden (#235) önce kaydedilmiş dürbün (seri adı farklı yazılmış, ör. "Arken SH-4 Gen II") | Tam ad tutmadığı için **yazarak giriş** kutularıyla açılıyordu (sahibin gördüğü fark) | **Liste modunda** açılır: Marka ve Model seçili, filtreler ve 5 kayıt kutusu gizli, Retikül kayıtlı değerde |
| Düzenle: eski adla kaydedilmiş tüfek (ör. "TIKKA / T3X Tact A1") ve yerleşik "HATSAN / Hercules" | Yazarak giriş kutularıyla açılıyordu | **Liste modunda** açılır: Marka/Model seçili, Üretim dolu (Yerli/İthal), kalibre ve yiv kayıttaki gibi |
| Düzenle: yerleşik katalog dürbünü (kimliği doğrudan katalog kaydı) | Liste modunda açılıyordu, ama Güncelle'den sonra marka seri adı olmadan kaydedildiği için **bir sonraki açılışta yazarak girişe düşüyordu** | Marka kutusu yeni seçimdeki gibi "Marka Seri" ile dolar; Güncelle → yeniden aç yine liste modunda |
| Düzenle: hiçbir listede olmayan yazılı dürbün/tüfek | Yazarak giriş, kayıtlı değerler dolu, "Listeden seç" | Aynı |
| Kopyala | Kopya aynı kayıtları gösterdiği için asılla aynı yoldan açılır (eski kayıtta yazarak giriş) | Asılla aynı yoldan açılır: eski kayıt da liste modunda |
| Kaydı silinmiş (kimliği hiçbir kayda çıkmayan) dürbün/tüfek | Uyarı + boş kutular, sessizce başka kayıt seçilmez | Aynı (bilerek değişmedi) |

Profili Düzenle'de katalog dürbününün filtreleri Marka değişene kadar gizli kalır (sahip, 13 Ekim) — korundu.

## Eşleşme kuralları

Önce eski **tam** kural çalışır (değişmedi). Yalnız o bir şey bulamazsa toleranslı kural devreye girer.

**Dürbün** (kayıtlı yazılı kayıt → katalog kaydı):

1. Marka: harf ve rakamlar karşılaştırılır ("GaziSniper" = "Gazi Sniper"); ya kayıtlı marka katalog markasıyla başlar ya da ilk kelimeler aynıdır ("Arken …" = "Arken Optics").
2. Seri / model kelimeleri: büyütme yazısı (5-25x56) ve FFP/SFP çıkarılır; kayıtlı kelimelerin en az yarısı katalog adında bulunmalı (bitişik yazım da sayılır: "Gen II" ↔ "GENII").
3. Sayılar tutmalı: Min/Maks büyütme aynı, Mercek çapı aynı (±0,5 mm), Odak düzlemi aynı (ikisinde de varsa), Dürbün birimi aynı.
4. Sıralama: en çok kelime tutan, sonra kayıtlı retikülü olan, sonra en az fazla kelimesi olan. İki **farklı model** eşit çıkarsa eşleşme yok sayılır → yazarak giriş (hiçbir şey sessizce seçilmez). Kayıtta hiç seri kelimesi yoksa yalnız tek bir model sayılara uyuyorsa eşleşir.

**Tüfek** (kayıtlı Marka/Model → kütüphane Marka/Model):

1. Marka aynı kural.
2. Model: büyük/küçük harf ve boşluk farkı yok sayılır; ya biri ötekinin bütün kelimelerini içerir ya da kelimelerin çoğu ortaktır.
3. Kayıtlı kalibreyi taşıyan model öne alınır; tam ad eşleşmesi önce gelir. Eşitlik → eşleşme yok → yazarak giriş.

**Veri korunur:** toleranslı eşleşmede kayıtlı dürbünün markası, büyütmeleri, mercek çapı, odak düzlemi, klik değeri ve retikülü olduğu gibi kalır; yalnız kayıtta **boş** olan bir değer katalog kaydından doldurulur. Tüfekte yalnız Marka ve Model yazısı listedeki yazılışı alır (kimlik yazısı); kalibre, yiv oranı ve yiv yönü kayıttaki gibi kalır. Hesaba giren hiçbir değer değişmez.

## 2. Dürbün Model ve Tüfek Model kutuları

- Önce: Dürbün Model kutusunda uzun model yazısı küçülerek tek satıra sığdırılıyordu (`FittedBox`); Tüfek Model "…" ile kesiliyordu.
- Şimdi: seçilen yazı normal boyutta (15) kalır, alt satırlara geçer, kutu uzar. `MenzilSelect(wrapSelected: true)`: yazıyı kutu kendisi çizer, liste düğmesi üstünde kalır; kutunun her yerine dokunmak listeyi açar, ok her zamanki yerinde.
- Açık listede Dürbün Model maddeleri de artık küçülmez: Mühimmat Model gibi iki satıra kadar normal boyut (`maxLines: 2`).
- Kısa model (ör. "T3x UPR") tek satırda, kutu diğerleriyle aynı yükseklikte.
- Not: `main`'deki Mühimmat Model kutusu kapalıyken tek satır ve uzun adı "…" ile gösteriyor. Görevde "Mühimmat'ta başka hiçbir şeye dokunma" dendiği için ona dokunulmadı; Dürbün ve Tüfek Model sahibin tarif ettiği şekilde (küçülmez, alt satıra geçer, kutu uzar) yapıldı. Mühimmat Model'in de aynı olması istenirse ayrı görev.

## 3. "Kaydetmek için eksik"

- Önce: katalog dürbünü henüz seçilmemişken "Dürbün: Marka, Min. büyütme, Maks. büyütme, Mercek çapı, Odak düzlemi, Dürbün birimi, Dürbün ayağı, Klik değeri" — ekranda olmayan kutular.
- Şimdi yalnız ekrandaki kutular: Marka seçilmemişse "Dürbün: Marka, Model, Dürbün ayağı"; Marka seçilip Model seçilmemişse "Dürbün: Model, Dürbün ayağı"; Dürbün ayağı da seçiliyse "Dürbün: Model".
- Katalog kaydında eksik olan bir değerin kutusu görününce (ör. Gamo'da Odak düzlemi) o kutu listede adıyla yer alır.
- Yazılı dürbünde (bağlantıdan) kutuların hepsi görünür, hepsi listelenir; Klik değeri yalnız yazılı dürbünde.
- Tüfek: `main`'de gizli Tüfek kutusu yok; listedeki her ad ekrandaki bir kutuya karşılık geliyor. Test bunu her durumda kontrol ediyor; ileride bir Tüfek kutusu gizlenip listede kalırsa test düşer.

## 4. Mühimmat → Barut katsayısı

- "%/15 °C" birimi etiketin yanından kaldırıldı (açıklama ⓘ metninde: "hava 15 °C ısındığında namlu çıkış hızının yüzde kaç arttığı"). Etiket tek satır kalır.
- "Hız ölçüm sıcaklığı °C" aynen duruyor. Mühimmat'ta başka hiçbir şey değişmedi (#306 açık).

## 5. Koruma testleri: `test/profil_duzen_koruma_test.dart`

Eski kayıt JSON örnekleri (13 Ekim öncesi yazılışlar): TIKKA / "T3X Tact A1", "Arken SH-4 Gen II" 4-16x50 FFP MRAD + VPR-MIL,
listede olmayan "Atölyem Optik" ve "Atölyem / Özel Yapım"; profil `ProfileCodec` JSON'undan okunuyor.

Her giriş yolu için Dürbün ve Tüfek kartındaki kutular **sırası ve aynı satırdaki eşleri** ile karşılaştırılıyor (ör. "Dürbün ayağı | Üst kule klik sayısı", "Namlu çıkış hızı | Kalibre"):

- Yeni profil: Marka öncesi, Marka sonrası filtreler (Birim | Odak, Tüp | Büyütme) → Model, katalog seçimi (5 kutu gizli), bağlantı → yazılı giriş → "Listeden seç" geri; Tüfek bağlantısı ve geri dönüş.
- Düzenle: katalog dürbün (gazi-6-36) + yerleşik HATSAN/Hercules → liste modu, Üretim Yerli; Marka değişince filtreler geri.
- Düzenle: 13 Ekim öncesi JSON → liste modu, Marka/Model/Retikül seçili, Üretim İthal, eksik yok.
- Güncelle → yeniden aç (eski kayıt): düzen aynı, kayıtlı değerler (marka yazısı, büyütme, mercek, odak, klik, retikül, kalibre, yiv, hız) korunuyor.
- Güncelle → yeniden aç (yerleşik katalog dürbün kimliği): yine liste modunda.
- Düzenle: listede olmayan yazılı kayıtlar → yazılı giriş, değerler dolu, "Listeden seç".
- Kopyala: kopya asılla aynı düzende.
- Eşleşme kuralları (saf testler): eski adlı Arken bulunur; listede olmayan dürbün bulunmaz; farklı büyütme eşleşmez.
- Eksik listesi: her durumda listedeki her Tüfek/Dürbün adı ekrandaki bir kutuya karşılık gelmeli; gizli 5 kutu ve Klik değeri katalog modunda yazılmaz.
- Model kutuları: uzun Dürbün Model ("ED-ELR Gen III 5-40x56 SFIR FFP Zero Stop MOA") ve Tüfek Model ("Mark V Backcountry 2.0 Carbon 6.5-300 Wby Mag") yazı boyutu 15, küçültme yok, kesilme yok, birden çok satır, kutu uzuyor; kısa model tek satır.
- Barut katsayısı: birim yok, "Hız ölçüm sıcaklığı" °C ile, ⓘ var.

Bu kararlardan biri sessizce geri alınırsa bu testler düşer.

## Kenar durumlar

- İki farklı katalog modeli eşit uyuyorsa (ör. aynı seri, IR olan/olmayan, retikül bilinmiyor) seçim yapılmaz; yazılı giriş, kayıtlı değerlerle.
- Birimi farklı (MOA kayıt / MRAD katalog) veya büyütmesi/mercek çapı farklı kayıt eşleşmez.
- Kayıtlı retikül modelin retikülleri arasında yoksa Retikül "Seçiniz" görünür ama kayıtlı retikül silinmez; kullanıcı seçmedikçe aynen kaydedilir.
- Profilin açı birimi dürbünün biriminden farklıysa davranış eskisi gibi (değişmedi).
- Toleranslı eşleşen eski dürbün Güncelle ile kaydedilince marka yazısı eski hâliyle kalır; her açılışta aynı kural aynı sonucu verir.

## Yapılmayanlar / sahibe sorular

- Tüfek Marka ve Model `main`'de iki ayrı tam satır; CLAUDE.md "Marka | Model yan yana" diyor. Görev düzen değişikliği istemediği için dokunulmadı; test bugünkü düzeni sabitliyor. Yan yana istenirse ayrı görev.
- Mühimmat Model kutusunun kapalı hâli (tek satır, "…") değişmedi (yukarıda).
- `test/ekran_boyutu_test.dart` içindeki "Barut katsayısı 375 pt'de kesik" açık-bulgu muafiyeti duruyor (yalnız izin veriyor, zorlamıyor); birim kalktığı için artık gerekmeyebilir, sahip isterse kaldırılır.
- Hesap, katalog verisi, diğer sayfalar, gizli bayraklar: dokunulmadı. TestFlight yok, birleştirme yok.

## Doğrulama

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (336 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → 740 test OK.
- Bu ortamda Flutter SDK indirilemedi (proxy 403); `flutter analyze` / `flutter test` yerelde ÇALIŞMADI. Doğrulama CI'da:

Hepsi `fix/profil-duzen` dalında, kod commit'i `a68fc11` üzerinde:

- Format (One-off dart format fix): BAŞARILI, değişiklik yok — https://github.com/sniperTurk/flutter-app/actions/runs/38582195359
  (ilk format çalıştırması https://github.com/sniperTurk/flutter-app/actions/runs/38580712208 `b99e19d` biçim commit'ini üretti).
- Testler (`flutter test test`, bütün klasör): BAŞARILI — https://github.com/sniperTurk/flutter-app/actions/runs/38582190475
- Analyze (`--fatal-infos --fatal-warnings`): BAŞARILI — https://github.com/sniperTurk/flutter-app/actions/runs/38582760848
- Önceki test çalıştırması https://github.com/sniperTurk/flutter-app/actions/runs/38580961873 (`b99e19d`) 1 hata verdi:
  `test/reticle_test.dart` "Dürbün Marka then Model fills the scope" — Dürbün Model listesinin maddeleri satır yüksekliği serbest
  (`itemHeight: null`) olunca uzun Vector Optics listesi test yardımcısının kaydırma sınırını aştı. Liste maddeleri Mühimmat Model gibi
  iki satır ve sabit yükseklik yapıldı (`a68fc11`); test değiştirilmedi.
- PR'ın kendi iOS CI'ı: sonucu PR üzerinde; burada başarılı diye yazılmadı. Simulator, cihaz, imzalama, TestFlight, App Store: ÇALIŞTIRILMADI.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
