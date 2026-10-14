# Hava sayfası: tarih satırları, Basınç Ölçer ⓘ, yeni İrtifa kartı, Rüzgâr düzeltmesi otomatik

Bu PR, #302'nin (`fix/hava-verisi-tazelik`, 554f0e0: alınma zamanı kaydı ve
30 dakikalık tazelik) **yerine geçer**. Dal #302'nin ucundan açıldı, güncel
main bu dala birleştirildi. #302'ye dokunulmadı; #302'nin 30 dakika kuralı
aynen duruyor, yalnız etiketleri sahibin 14.10.2026 kararına göre değişti.

Sahip kararı: 14.10.2026, İstanbul (onaylı taslak:
https://claude.ai/artifact/YAfwRy4yNeHUVM5Q43y71e ; metin esastır).
Tarih biçimi her yerde sayısal: "14.10.2026 14:36" (24 saat, telefonun yerel
saati), ay adı yok.

## A. Hava Durumu kartı

**Ne:**
- Hava düğmesi artık **tam genişlik**, tek satır:
  - taze (≤ 30 dk): turuncu "✓ Hava verisi alındı",
  - eski (> 30 dk, saat bilinmiyor ya da saat ileride): normal "⟳ Veriyi yenile",
  - hiç alınmadı: bugünkü yazı ("Konumdan canlı hava verisi al"; Sıfırla
    sonrası "Tekrar canlı konum verisi al").
- Düğmenin altında **tek satır**, sayfa ilk açıldığında da yerinde (kayma
  yok): solda tarih, sağda "Sıfırla" (diğer düğmelerle aynı boyda).
  - Hiç alınmadıysa: bugünün tarihi "14.10.2026".
  - Alındıysa: alınma tarihi ve saati "14.10.2026 11:20".
  - Kayıttan geri gelen eski bir alım: kendi tarihi ve saati.
- #302'nin "· HH:mm" ve "eski · Yenile" yazıları kaldırıldı. "Alındı:" /
  "Son alınma:" yok, düğmenin altına ek satır eklenmedi.
- Kutulardaki ⓘ'ler aynen duruyor.
- **Rüzgâr yönü kadranı** (`wind_clock_picker.dart`):
  - kadranın hemen üstünde küçük, sola yaslı "Rüzgâr yönü" başlığı,
  - seçili saat dairesi ve ok `MenzilColors.stateOrange` (alındı
    düğmeleriyle aynı turuncu), seçili rakam beyaz,
  - kadranın altında **tek satır**: solda "Saat 3 yönünde", sağda yönün
    girildiği tarih ve saat. Yön yokken sol boş, sağda bugünün tarihi.
    İkisi de tek satır kalır (sığmazsa küçülür, alt satıra geçmez).
  - Saat, kadrana dokununca ya da kutuya yazınca kaydedilir ve hava
    durumuyla birlikte saklanır (`windDirAt`). Hava verisi rüzgâr yönünü
    yazmadığı için (bugünkü kural: "Rüzgâr yönünü siz seçin") hava alımı
    bu saati değiştirmez.

**Nasıl:** `ballistics_screen.dart` içinde ortak `_dateResetRow` (tarih |
Sıfırla) ve `_boxButtonRow` (kutu | düğme) eklendi. Tarih yazısı
`lib/features/ballistics/fetch_date_text.dart` ile biçimlenir. Saat
kaynağı #302'deki gibi `ToolsServices.clock`.

**Neden:** Sahip, düğmenin ne zaman alındığını tek bakışta görmek ve
sayfanın açılışta kaymamasını istedi.

## B. Pro → Rüzgâr düzeltmesi

- Satır: "En çok rüzgâr" kutusu | düğme. Düğme boşken "Düzeltme al",
  doluyken turuncu "Düzeltme alındı" (simgesiz, tek satır).
- Altında her zaman görünen tarih | Sıfırla satırı (aynı kural).
  "Hava verisinden:" satırı yok.
- **Otomatik güncelleme:** Hava verisi alımı Rüzgâr hızını değiştirirse ve
  kutu "Düzeltme al" ile dolmuşsa, En çok rüzgâr kendiliğinden
  Rüzgâr hızı × 1,5 olur (bugünkü oran). "Rüzgâr değişti · Yenile" gibi bir
  soru çıkmaz. **Elle yazılmış değer hiç değiştirilmez.** Boş kutu (hiç
  basılmamış ya da Sıfırlanmış) da boş kalır; yalnız düğmenin yazdığı
  değer takip edilir.
- Hesap değişmedi: dürbün yan düzeltmesini Rüzgâr hızı belirler; En çok
  rüzgâr yalnız Hedef sayfasındaki rüzgâr aralığı satırını ve WEZ rüzgâr
  belirsizliğini besler.
- ⓘ metni yeni düğme adına ve otomatik güncellemeye göre düzeltildi.

## C. Basınç Ölçer kartı

- Başlık "Basınç Ölçer", başlığın hemen sağında **tek ⓘ**; kutunun içinde ⓘ
  yok. ⓘ metni sahibin verdiği metin: "İstasyon basıncı: bulunduğunuz
  yerdeki gerçek hava basıncı, telefonun basınç sensöründen alınır. Hava
  durumu uygulamalarındaki deniz seviyesi basıncı değildir. Örnek: 998,4
  hPa."
- Satır 1: "İstasyon basıncı" kutusu | "Basınç al" (simge bugünkü gibi
  `Icons.speed`). Taze (≤ 30 dk) turuncu "✓ Basınç alındı", eski
  "⟳ Basıncı yenile" (tek satır).
- **Bu düğme artık İrtifa yazmaz.** (Eskiden aynı dokunuşta GPS irtifası
  da yazılıyordu.)
- Satır 2: tarih | Sıfırla (A'daki kural). Sıfırla yalnız basıncı boşaltır.
- Başarılı okumadan sonra çıkan "Basınç telefondan alındı: … hPa" notu
  kaldırıldı (turuncu düğme ve tarih satırı bunu söylüyor). Hata notları
  aynen duruyor.

## D. Yeni İrtifa kartı (Basınç Ölçer'in altında)

- Başlık "İrtifa" (Basınç Ölçer gibi 18), başlığın sağında **tek ⓘ**,
  kutularda ⓘ yok. ⓘ metni sahibin verdiği metin.
- **Satır 1:** "Haritadan irtifa" kutusu (m/ft) | "Haritadan" düğmesi
  (`Icons.terrain`); alınınca turuncu "Haritadan alındı", simgesiz.
  - Kaynak: Google Maps Elevation API,
    `https://maps.googleapis.com/maps/api/elevation/json?locations=<lat>,<lng>&key=<key>`,
    telefonun o anki konumu (5 ondalık, yaklaşık 1 m).
  - Anahtar: TestFlight iş akışı artık mevcut Google Maps iOS anahtarını
    `--dart-define=GOOGLE_MAPS_IOS_API_KEY=…` olarak geçiriyor (gizli
    değişkenden; depoya anahtar yazılmadı, bir Python testi `AIza…`
    dizgisinin depoda olmadığını denetler). İstek
    `X-Ios-Bundle-Identifier: com.sniperturk.sniperTurk` başlığını taşır.
  - Anahtar yok / internet yok / hata: kutu boş, kısa not ("Harita irtifası
    bu derlemede yok; irtifayı elle girin.", "İnternet yok; harita irtifası
    alınamadı." ya da "Harita irtifası alınamadı; irtifayı elle girin.").
    Anahtar yoksa hiçbir istek gönderilmez.
  - Yalnız geçici hatalarda (zaman aşımı, HTTP 5xx/429, OVER_QUERY_LIMIT,
    UNKNOWN_ERROR) 2 sn ve 5 sn sonra hızlı yeniden deneme; izin
    reddi/403/çevrimdışı tekrar denenmez.
- **Satır 2:** "Telefondan irtifa" kutusu | "Telefondan" düğmesi
  (`Icons.my_location`); alınınca turuncu "Telefondan alındı", simgesiz.
  - Hava Durumu sayfası açılınca arka planda **tek bir sessiz GPS isteği**
    başlar (düğmeye basılmış gibi, yüksek doğrulukla), ama hiçbir şey
    yazılmaz ve gösterilmez. Konum izni daha önce verilmemişse bu istek
    hiç başlamaz; iOS izin penceresini sessiz istek açmaz, düğme bugünkü
    gibi sorar.
  - "Telefondan"a basınca (GPS ısınmış olduğu için) taze okuma hemen
    yazılır; kullanıcı tek işlem görür. Isınma isteği hâlâ sürüyorsa yeni
    istek açılmaz, o isteğin sonucu yazılır.
  - 0–50 m dikey doğruluk kuralı aynen geçerli.
  - Sayfa kapanınca ya da uygulama arka plana geçince ısınma isteği
    bırakılır (sonucu yok sayılır).
  - Telefon kullanılabilir irtifa vermezse kutu boşalır ve kısa not:
    harita değeri varsa "Telefon irtifası alınamadı; hesapta haritadan
    gelen irtifa kullanılıyor.", yoksa "İrtifa alınamadı, elle girin."
  - `GeolocatorLocationProvider` isteğe bağlı `accuracy` aldı; varsayılan
    (düşük doğruluk) değişmedi, diğer çağıranlar aynı. Yüksek doğruluk
    yalnız bu istek için (`GeolocatorLocationProvider.highAccuracy`).
- **Satır 3:** tarih | Sıfırla, her zaman görünür. Tarih iki irtifa
  alımının en yenisidir. Sıfırla iki kutuyu da boşaltır.
- İrtifa düğmeleri, kutu elle değiştirilene ya da Sıfırlanana kadar
  turuncu kalır (30 dakika kuralı yok).
- **Hesap:** etkin irtifa = Telefondan irtifa doluysa o, değilse Haritadan
  irtifa. Eskiden İrtifa'nın kullanıldığı her yerde bu kullanılır: Basınç
  boşken basıncın irtifadan tahmini (Denetim F1), yerçekimi hesabı
  (Pro → Yerçekimi → Konumdan hesapla) ve basınç uygunluk uyarısı.
  Elle yazılan değerler kullanıcınındır (`_userEdited` kuralları).
- **Kayıt:** iki irtifa ve alınma saatleri hava durumuyla birlikte
  saklanır (`weather.altitude` = Telefondan, `weather.mapAltitude` =
  Haritadan, `altPhoneAt`, `altMapAt`). Eski kayıttaki tek İrtifa değeri
  Telefondan irtifa olarak geri gelir (anahtar aynı kaldığı için ayrıca
  dönüştürme gerekmez); saati olmadığı için düğme turuncu açılmaz.

## E. Düzen

- Her satırda iki öğe: kutu | düğme, tarih | Sıfırla. Kutu | düğme
  satırları 320 pt ve 1,3 yazı ölçeğinde de yan yana kalır.
- Metin sola yaslı; alanların altında yardım yazısı yok (yalnız yukarıdaki
  durum notları); etiketlerde parantez yok.
- Tarih yazıları hiç alt satıra geçmez (gerekirse küçülür).
- Başlıktaki tek ⓘ için ortak `MenzilSectionHeader`'a isteğe bağlı
  `titleTrailing` eklendi (başlığın hemen sağına konur). Verilmeyince
  başlık eskisi gibi çizilir; başka sayfalar etkilenmez.
- Başka sayfaya dokunulmadı. Not: eski "Balistik / DOPE" alt sayfası
  (`BallisticsView.all`) Hava Durumu ile aynı giriş bölümünü kullandığı
  için yeni İrtifa kartı orada da görünür.

## F. Sahip istisnası

CLAUDE.md "her girilen değere ⓘ" kuralına sahibin 14.10.2026 istisnası:
**yalnız Basınç Ölçer ve İrtifa kartlarında** kutu başına ⓘ yerine
başlıkta tek ⓘ var. Diğer kartlarda kutu ⓘ'leri aynen duruyor.

## Gizlilik notu (Elevation API)

"Haritadan"a basıldığında telefonun o anki enlem ve boylamı (5 ondalık)
Google'a gönderilir; yalnız zemin yüksekliği geri alınır. Uygulama konumu
saklamaz, yalnız irtifa değerini ve alınma saatini cihazda saklar. Sayfa
açılışındaki sessiz GPS isteği cihaz içinde kalır, hiçbir yere gönderilmez.

Gizlilik politikasına eklenmesi önerilen satır (gizlilik belgeleri PR #294'e
ait olduğu için bu PR onları **düzenlemedi**):

> İrtifa → "Haritadan" düğmesine bastığınızda cihazınızın o anki konumu
> (enlem ve boylam) zemin yüksekliğini almak için Google Maps Elevation
> API'ye gönderilir. Bu istek yalnız düğmeye bastığınızda yapılır;
> uygulama konumunuzu saklamaz. Google'ın gizlilik politikası geçerlidir:
> https://policies.google.com/privacy

## Maliyet

Elevation API, Google Maps Platform'da "Pro" SKU'dur: ayda 5.000 istek
ücretsiz; sonrası Google fiyat listesine göre ücretlidir. İstek yalnız
düğmeye basınca yapılır (sayfa açılışında harita isteği yok); hızlı yeniden
denemeler yalnız geçici hatalarda ve en çok 2 kez.

## Uç durumlar

- Gece yarısı: tarih satırı sayfa yeniden çizildikçe (her etkileşimde,
  uygulamaya geri dönüşte, 30 dk zamanlayıcısında) bugüne göre yazılır.
- Telefon saati geri alınırsa: #302 kuralı, eski sayılır; tarih satırı
  kaydedilen alım saatini gösterir.
- Hava alımı başarısız: saat değişmez, değerler kalır, hata notu bugünkü gibi.
- Konum izni yok: sessiz istek başlamaz; "Haritadan" "Konum izni yok;
  irtifayı elle girin." der.
- İki irtifa da boş: hesap 0 m (standart atmosfer), bugünkü gibi.
- Telefon irtifası alınamadığında eski telefon değeri silinir, böylece
  hesap harita değerine geçer (sahibin "kutu boş" kuralı).
- Birim (m/ft) değişince iki irtifa kutusu da çevrilir.
- Sekmeler arası geçişte (EnvironmentCarry) iki irtifa, saatleri ve rüzgâr
  yönü saati taşınır; rüzgâr yönü yalnız aynı profilde taşınır (bugünkü
  kural).
- Hava alımı sonrası çıkan bilgi notu (MET Norway CC BY 4.0 kaynak adı
  içerdiği için) kaldırılmadı; yalnız "Basıncı telefondan al" sözü yeni
  düğme adlarına göre düzeltildi.

## Bilerek yapılmayanlar

- Rüzgâr düzeltmesi için "⟳ Düzeltme al" eski durumu eklenmedi (karar
  metninde "gösterebilir" diye isteğe bağlıydı; En çok rüzgâr zaten her
  yeni rüzgârla kendiliğinden güncelleniyor).
- Kart sırası değiştirilmedi: Hava Durumu (Sıcaklık, Bağıl nem, hava
  düğmesi), Basınç Ölçer, **İrtifa (yeni)**, Rüzgâr. Taslaktaki 4. ekran
  rüzgârı aynı kartta çiziyordu; metin "Hava Durumu kartı" ve taslağın
  "(değişmedi)" notu esas alındı.
- Geolocator isteği gerçek anlamda iptal edilemiyor: sayfa kapanınca ya da
  arka planda sonucu yok sayılır; GPS en geç eklentinin 15 sn sınırında
  durur.
- Gizlilik belgeleri (PR #294) düzenlenmedi.
- TestFlight başlatılmadı, PR birleştirilmedi.

## Testler

- Yeni: `test/hava_sayfasi_test.dart` (sahte saat, sahte HTTP, sahte konum):
  - A: taze/eski etiketler, tek satır "Veriyi yenile", alım öncesi/sonrası
    tarih satırı, satırın yerinde kalması, geri yüklenen eski alımın kendi
    tarihi; kadran başlığı, stateOrange seçim, beyaz rakam, "Saat 3
    yönünde" + saat, yazılan saat, yeniden açılışta kayıt.
  - B: Düzeltme al/alındı, yeni rüzgârla otomatik güncelleme, elle yazılan
    değerin korunması, boş kutunun boş kalması.
  - C: tek başlık ⓘ ve metni, "Basınç al" İrtifa'ya dokunmaz, eski
    "Basıncı yenile", Sıfırla yalnız basınç.
  - D: sayfa açılınca tek sessiz istek ve kutu değişmez; ısınmadan sonra
    dokunuş hemen yazar; ısınma sürerken dokunuş ikinci istek açmaz; izin
    yoksa istek/izin penceresi yok; sayfa kapanınca/arka planda ısınma
    bırakılır; telefon irtifası yoksa doğru not; Haritadan sahte servisle;
    Sıfırla iki kutuyu boşaltır; kayıt ve yeniden açılış; eski tek İrtifa
    göçü; basınç uyarısı ve F1 hesabı etkin irtifayı (telefon, yoksa
    harita) kullanır.
  - E: 320 pt, 1,3 ölçek, taşma yok, tarihler tek satır, kutu | düğme yan
    yana.
  - Google Elevation adaptörü (MockClient): anahtar ve
    `X-Ios-Bundle-Identifier` başlığı, anahtarsız istek gönderilmemesi,
    2 sn/5 sn yeniden deneme, 403/REQUEST_DENIED/çevrimdışı tekrar
    denenmez, okunamayan değerler.
- #302'nin `test/hava_verisi_tazelik_test.dart` testleri yeni etiketlere
  ve tarih satırına göre güncellendi (30 dk kuralı aynen sınanıyor).
- Etiket ve davranış değişikliği nedeniyle güncellenen testler:
  `fetch_reset_buttons_test`, `kutu_fikir4_test`, `wind_clock_test`,
  `phone_pressure_test`, `weather_filled_state_test` (yazılan İrtifa artık
  basınç düğmesini griye çevirmez), `shot_settings_test`,
  `pro_info_popup_test`, `hava_basliklar_test` (İrtifa başlığı da 18).
- Python: `tools/test_elevation_key_wiring.py` (anahtar yalnız gizli
  değişkenden, depoda anahtar yok); `test_m1_tools_scope_contract.py`
  izinli adaptör listesine yeni adaptör eklendi.

Yerel (bu ortamda Flutter SDK indirilemedi: storage.googleapis.com proxy
tarafından engelli, bu yüzden Dart testleri yalnız CI'da koştu):
- `python3 tools/offline_dart_lint.py`: PASS
- `python3 -m unittest discover -s tools -p 'test_*.py'`: OK

## CI

Hepsi `fix/hava-sayfasi` dalında koştu.

- Biçim (format-fix, 375209577):
  [38575514071](https://github.com/sniperTurk/flutter-app/actions/runs/38575514071)
  biçim commit'i ekledi (1dc035d), çekildi;
  [38575751538](https://github.com/sniperTurk/flutter-app/actions/runs/38575751538)
  7661fac üzerinde değişiklik gerekmedi.
- Analiz (`flutter analyze --fatal-infos --fatal-warnings`):
  [38575964720](https://github.com/sniperTurk/flutter-app/actions/runs/38575964720)
  **başarılı** (7661fac).
- Tüm testler (`flutter test test`):
  [38575960171](https://github.com/sniperTurk/flutter-app/actions/runs/38575960171)
  **başarılı** (7661fac). Önceki tam koşu
  [38574710265](https://github.com/sniperTurk/flutter-app/actions/runs/38574710265)
  `hava_basliklar_test` içinde Basınç Ölçer başlığını bulamadığı için
  kırmızıydı; başlık yeniden `MenzilSectionHeader` yapıldı ve test İrtifa
  başlığını da kapsayacak şekilde genişletildi.
- Hedefli testler (13 dosya):
  [38575185837](https://github.com/sniperTurk/flutter-app/actions/runs/38575185837)
  başarılı.
- PR'ın iOS CI koşusu
  [38577334249](https://github.com/sniperTurk/flutter-app/actions/runs/38577334249)
  (b31bb14; kod 7661fac ile aynı, sonrası yalnız rapor): `dart-checks`
  **başarılı**, `wind-acceptance` **başarılı**, `iOS CI / verify`
  **başarılı**. `ios-simulator` işi bu PR'da atlandı (koşmadı); Simulator,
  cihaz ve TestFlight denenmedi.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
