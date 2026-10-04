# M1 inceleme raporu — hatalar, nedenleri ve düzeltmeler (2026-10-03)

Girdi: `sniper_turk_m1_dual_lineage_merged_20261003.zip`. Bu paket V360 değildir.
Balistik solver, acceptance zinciri, toleranslar, doğrulama politikası ve
production G1/G7 gate değişmedi. Gate **CLOSED**.

## Hatalar ve düzeltmeler

| # | Önem | Hata | Neden | Düzeltme |
|---|---|---|---|---|
| 1 | Yüksek | Python zinciri kırmızı (V323 testinde ERROR) | ZIP, `build/ios/archive/v323-unsafe.xcarchive` artefaktını içeriyordu. Bu artefakt aslında bir symlink; ZIP'e gerçek klasör olarak girmiş. Test aynı yolda geçici symlink kurmak isterken klasörle karşılaşıp çöküyor. PRE-V352 notları build artefaktlarının paketlenmemesini zaten istiyordu. | `build/` paketten çıkarıldı. Gerçek `.xcarchive` klasörünü yakalayan bir sözleşme eklendi. |
| 2 | Kritik | Su Terazisi sensörden ilk okumada çöküyor | X/Y kartları kaydırılabilir sayfada `Row(crossAxisAlignment: stretch)` içindeydi. Kaydırma görünümü dikeyde sınırsızdır; `stretch` çocuklara sonsuz yükseklik dayatır ve "BoxConstraints forces an infinite height" hatası oluşur. Mevcut responsive testi ekranı verisiz açtığı için hatayı görmüyordu. | Satır `IntrinsicHeight` ile sınırlandı. Responsive teste okuma verilen bir terazi senaryosu eklendi. |
| 3 | Yüksek | Pusula sahte yön gösterebilir (ör. 359°) | flutter_compass 0.8.1 iOS'ta `trueHeading` gönderiyor (eklenti kaynağında doğrulandı). iOS gerçek kuzeyi hesaplayamadığında bu değer −1 olur. Adaptör −1'i normalize edip 359° yapıyordu. Yatay konumda eklenti değere ±90° eklediği için hata gizlenebiliyordu. | Eksi değer artık yeni `noReference` nedeniyle "yön hesaplanamadı" olarak bildiriliyor ve açıklayıcı mesaj gösteriliyor. Pusula açıkken ekran dikeye kilitleniyor. Kuzey notu "iPhone'da gerçek kuzey" olarak düzeltildi. |
| 4 | Orta | Pusula yanlış olarak "sensör yok" diyordu | Adaptör `heading == null` durumunu `noSensor` olarak işliyordu. Sensör yokluğu ise ayrıca `events == null` ile sinyalleniyor. | `null` artık `noData` olarak işleniyor. |
| 5 | Yüksek | Telefon hareketsizken pusula birkaç saniyede kayboluyor | iOS heading olayını yalnız yön 0,1°'den fazla değiştiğinde gönderir. Controller 4 sn'lik "veri yok" zamanlayıcısını her okumadan sonra yeniden kuruyor ve süre dolunca geçerli yönü siliyordu. | Zamanlayıcı yalnız ilk okuma gelene kadar çalışıyor; son geçerli yön korunuyor. |
| 6 | Orta | Yön kısaltmaları İngilizce (N, NE, E…) | `cardinal16` ve kadran etiketleri İngilizceydi. Türkçe arayüzde ve VoiceOver'da ("E yönü") yanlış. Hava'daki rüzgâr yönü de etkileniyordu. | 16 Türkçe kısaltma (K, KKD, KD, DKD, D, …) ve kadranda K/D/G/B, KD/GD/GB/KB kullanılıyor. Testler güncellendi. |
| 7 | Orta | `flutter analyze --fatal-infos` hatası | Kadranda `Map.forEach` ile fonksiyon literali kullanılmıştı (`avoid_function_literals_in_foreach_calls`). | `for` döngüsüne çevrildi. |
| 8 | Yüksek | Araçlar, geçersiz profil kaydedebiliyor | Kronograf ve Sight Height `RifleProfile`'ı doğrulama olmadan doğrudan kaydediyordu. Kronograf 2000 m/s'ye kadar kabul ederken profil sınırı 1500 m/s. Kayıt yolu sınır denetlemiyor, yalnız okuma denetliyor. Sonuç: geçersiz kayıt sonrasında ana profil verisi okunamaz hale gelip yedeğe düşülüyordu. | Tüm araç yazımları, profil editörünün kullandığı `ProfileInput.validate` üzerinden geçiyor (`ToolProfileUpdate`). Kronograf sınırı `ProductionLimits.maxMuzzleVelocityMps` oldu. |
| 9 | Yüksek | Profil güncellemesi Atış/Tablo'ya yansımıyor | Araçlar profile kendi store'larıyla yazıyor, kabuk ise haberdar edilmiyordu. Örneğin yeni dürbün yüksekliği kaydedildikten sonra Atış, uygulama yeniden açılana kadar eski değerle hesap yapıyordu. | Bir araçtan dönülünce kabuk profilleri yeniden yüklüyor (`onProfilesChanged: _load`). |
| 10 | Orta | Sight Height'ta iki proje kararı eksikti | "Namlu ağzında moderatör/susturucu/alev gizleyen olmamalı" uyarısı ve "eğimli montajda ön objektif referansı" yönlendirmesi yoktu. Bu yöntemde namlu ağzının merkezi işaretlendiği için takılı bir cihaz ölçümü doğrudan bozar. | İki uyarı eklendi. İşaretleme talimatları "objektifin ÖN ucu" ve "cihaz takılı olmamalı" olarak netleştirildi. |
| 11 | Orta | Dikey yan fotoğraf kabul ediliyor | Çekim ekranı yataya kilitleniyor ama kamera fiziksel cihaz yönüne göre çekiyor. Dikey tutulan telefon dikey fotoğraf üretiyordu. | İşaretleme ekranı dikey görüntüyü reddediyor ve yeniden çekmeyi istiyor. |
| 12 | Düşük | Kronograf'ta PCP basıncı yoktu | Brief'teki "PCP'de basınç bar bilgisi" maddesi uygulanmamıştı. | PCP için isteğe bağlı başlangıç/bitiş basıncı alanları eklendi; toplam ve atış başına düşüş gösteriliyor. Değerler profile yazılmıyor. |
| 13 | Orta | Hava özelliği hiçbir derlemede çalışmıyor | MET Norway User-Agent'ı `CONTACT_REQUIRED` yer tutucusundaydı. Etkinleştirmek için kod değişikliği gerekiyordu. | İletişim bilgisi artık `--dart-define=METNO_CONTACT=...` ile verilebiliyor. Verilmezse eski kapalı-kalma davranışı aynen korunuyor. |

## Değişen dosyalar

- **Pakette:** `build/` kaldırıldı.
- **Kod:**
  - `lib/features/tools/level_screen.dart`
  - `compass_screen.dart`
  - `sight_height_screen.dart`
  - `chronograph_screen.dart`
  - `tools_screen.dart`
  - `weather_screen.dart`
  - `tool_support.dart`
  - `lib/features/home/home_screen.dart`
  - `lib/tools/adapters/flutter_compass_heading_provider.dart`
  - `lib/tools/ports/heading_provider.dart`
  - `lib/tools/state/compass_controller.dart`
  - `lib/tools/domain/compass_math.dart`
  - `lib/tools/domain/chronograph_stats.dart`
  - `lib/tools/config/tools_config.dart`
- **Testler:**
  - `test/tools_domain_test.dart`
  - `test/tools_screens_test.dart`
  - Yeni: `tools/test_m1_review_fixes.py` (13 sözleşme)

## Doğrulama

| Kontrol | Sonuç |
|---|---|
| Python zinciri (`unittest discover -s tools`) | **519/519 OK** (öncesi: 506 test, 1 ERROR) |
| Offline Dart lint | PASS, 97 dosya, 0 sorun |
| Production gate | **CLOSED** |
| İsimli parametre/deprecation denetimi (Flutter 3.47.2, camera 0.12.1, http, geolocator, sensors_plus, flutter_compass kaynaklarına karşı) | 0 sorun |
| Kullanılmayan import ve proje içi statik üye denetimi | 0 sorun |
| `dart format`, `flutter analyze`, `flutter test`, iOS build, Simulator, fiziksel iPhone | **ÇALIŞTIRILMADI**. Dart SDK ve pub.dev bu ortamda erişilemiyor. Dart testleri ve düzeltmeler derleyiciyle doğrulanmadı. |

## Açık noktalar

- **flutter_compass ile iOS pusulası:** Apple belgelerine göre `trueHeading`, ancak aynı location manager'da konum güncellemeleri açıksa geçerlidir; eklenti bunu başlatmıyor. iPhone'da pusula sürekli "yön hesaplanamadı" gösterebilir. Uygulama artık sahte değer göstermiyor, ama özelliğin gerçekten çalışıp çalışmadığı fiziksel cihazda denenmeli. Çalışmazsa `magneticHeading` kullanan bir eklenti veya küçük bir native köprü gerekir.
- **Doğrulanmayan ölçüm ayrıntıları:** Terazi işaret yönü, pusula yönü ve Sight Height ölçek/perspektif hatası fiziksel cihazda doğrulanmadı.
- **Hava:** Release derlemesinde `METNO_CONTACT` verilmezse kapalı kalır.
- **Lockfile:** `pubspec.lock` yok. Pinned Flutter ile `tools/claude_bootstrap_and_verify.sh` çalıştırılmalı.
