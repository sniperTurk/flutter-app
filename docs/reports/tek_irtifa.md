# Hava Durumu → İrtifa: tek kutu, tek düğme

İstek (sahip, 2026-10-16 07:08–07:34 İstanbul): "İrtifa telefondan al sağlıklı çalışmıyor" → en basit kural: BİR kutu ve BİR düğme.

## Ne değişti

- İrtifa kartındaki iki satır ("Haritadan irtifa" + "Haritadan", "Telefondan irtifa" + "Telefondan") silindi. Yerine tek satır geldi: kutu **İrtifa** (m) | düğme **İrtifa al**. Eski iki satırın kodu bayrakla gizlenmedi, silindi. Kartın "Sıfırla" düğmesi ve tarih satırı aynen duruyor.
- **İrtifa al** kuralı: önce haritadan zemin yüksekliği istenir (mevcut Google Elevation sağlayıcısı). Gelirse kutuya yazılır. Gelmezse (internet yok, anahtar yok, konum yok, hata) telefonun GPS irtifası istenir (mevcut PhoneAltitudeProvider, bugünkü 0–50 m dikey doğruluk kuralı aynen) ve o yazılır. İkisi de gelmezse kısa not: "İrtifa alınamadı, elle girin." Kutu o zaman olduğu gibi kalır. Ortalama alınmaz.
- Düğme durumu: başarılı alımdan sonra **İrtifa alındı** yazar, koyu mavi "alındı" görünümündedir (#1F5F7A dolgu, #2E7FA0 kenar, beyaz yazı). Sayfa yeniden açılınca da öyle gelir. Kutuya elle yazmak ya da Sıfırla bu durumu kaldırır.
- Kutu elle de yazılır; yazılan değer olduğu gibi kullanılır.
- "-0" düzeltildi: sıfıra yuvarlanan değer (ör. -0,3) "0" görünür; kayıttan gelen eksi sıfır da "0" olur. -0,6 ise "-1" kalır.
- İrtifa ⓘ metni sahibin sözüyle birebir değişti: "İrtifa; Atış yerinizin deniz seviyesinden yüksekliğidir. "İrtifa al" yüksekliği haritadan alır; internet yoksa telefonun GPS'inden alır. Elle de girebilirsiniz. Örnek: 100 m." Basınç Ölçer ⓘ değişmedi.
- Silinen ve artık kullanılmayan kod: ikinci kutu (`mapAltitude` denetleyicisi ve `BallisticsFieldKeys.mapAltitude`), "telefon yoksa harita" seçen `_altitudeCtl`, `_readPhoneAltitude`, `_readMapAltitude`, iki ayrı zaman alanı ve onların hata metinleri ("Harita irtifası bu derlemede yok…", "İnternet yok; harita irtifası alınamadı.", "Telefon irtifası alınamadı; hesapta haritadan gelen irtifa kullanılıyor." vb.).

Dosyalar: `lib/features/ballistics/hava_durumu_view.dart` (yalnız İrtifa kartı), `lib/features/ballistics/ballistics_screen.dart` (İrtifa durumu, kayıt, birim çevirme, sekmeler arası taşıma), `lib/features/ballistics/environment_field_info.dart` (yalnız `altitudeCard`), `lib/services/shot_settings_store.dart` (yeni `altSource` alanı).

## Nasıl

- Hesap: eskiden hesap "telefon kutusu doluysa o, değilse harita kutusu" değerini kullanıyordu. Şimdi aynı üç yerde tek İrtifa kutusu kullanılıyor: İstasyon basıncı boşken basınç tahmini (Denetim F1), basınç uyarısı ve Pro → Yerçekimi → Konumdan hesapla. İrtifanın nerede kullanıldığı değişmedi; yalnız değerin kaynağı değişti.
- Kayıt (eski kayıtlar silinmez):
  - Tek kutu, eski `weather.mapAltitude` anahtarında saklanır. Alındığı zaman eski `altMapAt` alanındadır. Yeni `altSource` alanı ("map", "phone" ya da "typed") yeni biçimi işaretler.
  - `altSource` olmayan eski kayıt: `mapAltitude` varsa kutuya o gelir (varsa `altMapAt` ile "alındı"), yoksa `altitude` (eski Telefondan irtifa ya da daha eski tek İrtifa) gelir (varsa `altPhoneAt` ile "alındı").
  - Eski kayıttaki telefon değeri (`weather.altitude`) ve zamanı (`altPhoneAt`) her kayıtta olduğu gibi yazılmaya devam eder, yani hiç silinmez. Yeni biçimde ise gösterilmez ve hesapta kullanılmaz.
- Telefonun sayfa açılınca yaptığı sessiz GPS ısınması aynen duruyor. "İrtifa al" haritadan sonuç alamazsa, hâlâ süren ısınmayı bekler; ikinci bir istek açmaz.

## Neden

Sahip iki satırı karışık buldu ve telefondan irtifanın sağlıklı çalışmadığını söyledi ("-0 m"). Tek kutu ve tek düğme ile kullanıcı hangi değerin hesaba girdiğini düşünmek zorunda kalmıyor. Harita zemin yüksekliği öncelikli, GPS ise yalnız yedek.

## Uç durumlar

- Harita konumu alınamazsa (izin yok, konum kapalı) harita adımı atlanır ve telefon denenir. İzin yoksa telefon isteği de alınamaz, not çıkar.
- Harita servisi hata fırlatırsa da telefona geçilir.
- İkisi de alınamazsa kutu değişmez. Önceden alınmış bir değer varsa "İrtifa alındı" durumu da korunur, çünkü kutudaki değer hâlâ o alımdan geliyor.
- Eski kayıtta harita 5, telefon 2 varsa kutuda 5 görünür. Telefon değeri 2 kayıtta korunur ama artık kullanılmaz.
- Eski kayıtta yalnız telefon 2 varsa kutuda 2 görünür.
- Yeni biçimde kutu Sıfırla ile boşaltılmışsa eski telefon değeri geri gelmez.
- Uygulama eski bir sürüme geri yüklenirse (iOS'ta olağan değil), eski sürüm saklanan eski telefon değerini haritanın önüne koyabilir. Bu, eski telefon değerini silmemenin bedelidir.
- `altSource` alanında bilinmeyen bir değer varsa eski kayıt gibi okunur.
- Sekme değişince (EnvironmentCarry) kutu, "alındı" zamanı ve kaynak taşınır.

## Bilerek yapılmayanlar

- İrtifanın hesapta kullanıldığı yerler ve kural (yalnız İstasyon basıncı boşken basınç tahmini) değişmedi.
- Basınç Ölçer ⓘ, Hava kartı, Rüzgâr bölümü ve sayfanın üstü değişmedi (o kısımlara dokunan açık işlerle çakışmasın diye).
- `lib/tools/ports/*`, `lib/tools/adapters/*` ve `lib/tools/tools_services.dart` içindeki eski "Telefondan/Haritadan" yorumları değiştirilmedi: fark yalnız İrtifa kartı ve onun durum/kayıt koduyla sınırlı kaldı. Sağlayıcıların kendisi değişmedi.
- Ortalama alma, iki değeri karşılaştırma ya da kaynak etiketi gösterme eklenmedi.
- Birleştirme (merge) yok, TestFlight yok.

## Testler

Yeni test dosyası `test/tek_irtifa_test.dart` (sahte sağlayıcılarla):

- Kartta tek satır var: İrtifa kutusu ve İrtifa al düğmesi yan yana. Eski kutu ve düğmeler yok. Sıfırla ve tarih satırı yerinde.
- Harita çalışırsa kutuya harita değeri yazılır, düğme "İrtifa alındı" olur ve koyu mavi renktedir (dolgu, kenar ve yazı rengi kontrol edildi).
- Harita şu beş durumda başarısız olursa telefon değeri yazılır: internet yok, anahtar yok, servis hatası, servis hata fırlatır, derlemede harita servisi yok.
- Harita için konum alınamazsa telefon değeri yazılır.
- İkisi de başarısız olursa "İrtifa alınamadı, elle girin." notu çıkar ve kutu değişmez. Kutu doluysa da boşsa da aynı.
- Başarısız ikinci denemede önceki değer korunur.
- Elle yazılan değer olduğu gibi kullanılır ve "alındı" durumunu kaldırır. Kayda `typed` olarak yazılır.
- Sıfırla kutuyu ve "alındı" durumunu temizler.
- Sayfa yeniden açılınca "İrtifa alındı" geri gelir.
- "-0" durumları: harita -0,3 → "0"; telefon -0,4 → "0", -0,6 → "-1"; kayıttaki -0,001 → "0".
- Eski kayıt (harita 5 + telefon 2) → kutuda 5. Yeni kayıtta telefon 2 ve zamanı korunur. Yeniden açılınca elle yazılan değer gelir.
- Eski kayıt (yalnız telefon 2) → kutuda 2 ve "alındı".
- Yeni biçimde boş kutu eski telefon değerini göstermez.
- Hesap, bağımsız ISA referanslarıyla kontrol edildi: basınç boşken kutudaki 1500 m kullanılır (1,0223 kg/m³). Kutu boşsa 1013,25 hPa kullanılır. Basınç 900 hPa doluysa İrtifa hesabı değiştirmez. Eski kayıttan gelen 1500 m de kullanılır.
- ⓘ metni sahibin sözüyle birebir aynı, başlıktaki ⓘ de bu metni açıyor.
- 320 ve 390 pt genişlikte, yazı ölçeği 1,3'te taşma yok. Düğme yazısı tek satır, kutu ve düğme yan yana.

Kaldırılan iki düğmeli arayüze göre güncellenen testler:

- `test/hava_sayfasi_test.dart` D grubu: Haritadan/Telefondan düğme testleri tek düğmeye çevrildi. "Telefon alınamadı, harita kullanılıyor" notu testi ve "Haritadan offline → kutu boşalır" testi silindi (o davranış artık yok). "İki irtifa ve iki zaman saklanır" testi "değer ve zaman saklanır" oldu. Hesap testi tek kutuya indi. E (yerleşim) grubu tek düğmeyle çalışıyor. B grubundaki `mapAltitude` yazımı kaldırıldı.
- `test/audit_2026_10_14b/atmosphere_altitude_audit_test.dart`: telefon/harita çiftleri tek değere indi. "İkisi dolu, telefon kazanır" ve "telefon boşken harita" testleri silindi; tek kutuda karşılıkları yok. Yerçekimi testleri tek kutuyla çalışıyor. ATM-2 koruması artık boş basınç kuralını Basınç Ölçer ⓘ içinde arıyor. Sebebi: sahip İrtifa ⓘ metnini birebir verdi ve bu kural o metinde yok. Kural Basınç Ölçer ⓘ'de ("Boşsa basınç İrtifa kartından tahmin edilir.") duruyor.
- `test/audit_2026_10_14b/weather_wind_elevation_audit_test.dart`: Lut Gölü (-430) testi tek düğmeyle çalışıyor. "Telefon reddedilince harita değeri kalır" testi "harita başarısız ve telefon reddedilince önceki değer kalır" oldu.
- `test/phone_pressure_test.dart`: ATM-2 testi yalnız Basınç Ölçer ⓘ'yi kontrol ediyor.
- `test/kutu_fikir4_test.dart`: iki kutu yerine tek "İrtifa" kutusu kontrol ediliyor.
- `test/temiz_tasarim_hedef_test.dart`: simgesiz düğmeler listesinde iki eski düğmenin yerini `environment-altitude-fetch` aldı.
- `tools/test_denetim_2026_10_14b_atm.py`: kod yolu korumaları tek kutuya göre güncellendi. `_altitudeCtl` ve `mapAltitude` denetleyicisi artık olmamalı. F1, uyarı ve yerçekimi `altitude` kutusunu kullanmalı. Kayıt `mapAltitude` anahtarına yazmalı. ATM-2 için İrtifa ⓘ'nin "İrtifa; " ile başlaması bekleniyor.

Yerel çalıştırmalar:

- `python3 tools/offline_dart_lint.py` → PASS (400 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'` → OK (868 test).
- Flutter SDK bu ortamda kurulamadı: Dart SDK indirmesi proxy tarafından 403 ile engellendi. Bu yüzden `flutter test`, `flutter analyze` ve `dart format` yerelde ÇALIŞMADI (BLOCKED). Sonuç için CI'ya bakılmalı.

## CI

CI_LINKS_PLACEHOLDER

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01MfGYBMryHrDDcX2QxDxoTD
