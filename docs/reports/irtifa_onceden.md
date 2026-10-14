# İrtifa önceden alınır (Hava Durumu açılınca)

Tarih: 14.10.2026 (İstanbul) · Dal: `fix/irtifa-onceden` · Taslak PR, birleştirme ana oturumda.

## Sahibin sözü

- 14:05 "Basınç alınınca irtifa neden gelmiyor, dün geliyordu."
- 14:07 "3 defa bastım, geldi."
- 14:13 "Uygulama açıldığında istesek veriyi, basınç al dediğinde alınan veriyi yazsak nasıl olur?"
- 14:15 "Hava Durumu sayfası açılınca al."

## Neden oluyordu

"Basıncı telefondan al" düğmesi irtifayı, düğmeye basıldığı anda başlayan tek bir konum isteğinden alıyordu (8 saniye sınır). Konum isteği "düşük doğruluk" ile yapılıyor ve dikey doğruluğu 0–50 m arasında olmayan irtifa atılıyor. Telefonun GPS'i soğukken 8 saniyede kullanılabilir irtifa gelmiyor; bu yüzden ilk basışlarda basınç yazılıyor, İrtifa boş kalıyordu ("irtifa alınamadı, elle girin"). Birkaç basıştan sonra GPS ısındığı için irtifa geliyordu.

## Ne değişti

1. Hava Durumu sayfası görünür olunca arka planda tek, sessiz bir konum isteği başlar (ısınma). Ekranda yazı, dönen simge ya da yeni bir öğe yoktur.
2. Bu istek yalnız kendisi için "yüksek doğruluk" ister (irtifa için uygun GPS konumu). Diğer konum kullanan yerler (hava verisi, Coriolis, harita, yerçekimi) eskisi gibi düşük doğrulukla çalışır: konum sağlayıcısına isteğe bağlı bir parametre eklendi, varsayılan değişmedi. Süre sınırı sağlayıcının 15 saniyesidir.
3. Kullanılabilir irtifa (dikey doğruluk 0–50 m, bugünkü kural) geldiyse, değeri ve saati yalnız bellekte tutulur. Diske yazılmaz, profile kaydedilmez, uygulama kapanınca gider.
4. "Basıncı telefondan al":
   - Basınç bugünkü gibi yazılır (Basınç mantığı değişmedi).
   - İrtifa: ısınmadan gelen değer en çok 10 dakikalıksa o yazılır, yeni istek yapılmaz.
   - Değer yoksa ya da 10 dakikadan eskiyse bugünkü istek yapılır (8 saniye).
   - Isınma isteği basış anında hâlâ sürüyorsa, ona en çok 8 saniyenin kalanı kadar beklenir. "Kalan" ısınmanın başladığı andan sayılır: sayfa açıldıktan 3 saniye sonra basılırsa en çok 5 saniye beklenir. 8 saniye zaten dolmuşsa bugünkü istek yapılır.
   - Durum yazısı bugünküyle aynı: "Basınç telefondan alındı: … · irtifa GPS'ten … m." ya da "… · irtifa alınamadı, elle girin."

## Isınma ne zaman çalışır

- Hava Durumu sayfası ilk açıldığında (sekme ilk kez görünür olunca).
- Sayfa yeniden görünür olduğunda, son ısınma 10 dakikadan önce başladıysa bir kez daha. 10 dakika dolmadıysa yeni istek yapılmaz.
- Uygulama arka plandan dönüp Hava Durumu yeniden görünür olduğunda da aynı 10 dakika kuralı geçerlidir.
- Profil sekmesi ya da Araçlar açıkken (Hava Durumu görünmezken) ısınma çalışmaz.
- Değer, ana ekrandaki çalışma alanları arasında ortaktır (profil değişse de bellekteki irtifa kullanılır). Konum aynı yer olduğu için bu doğrudur; 10 dakika sınırı yine geçerlidir.

## İzin davranışı

- Isınma iOS konum izni penceresini hiçbir zaman açmaz. İzin henüz verilmediyse ısınma sessizce atlanır (GPS'e hiç gidilmez).
- Düğme bugünkü gibi davranır: izin yoksa izni sorabilir.
- Info.plist metni kontrol edildi (`tools/configure_ios_info_plist.py`, `NSLocationWhenInUseUsageDescription`): "Konumunuz yalnızca uygulama açıkken, bulunduğunuz yerin hava verisini almak (Hava Durumu) ve Coriolis için enlemi doldurmak amacıyla kullanılır. Konum kalıcı olarak saklanmaz." Isınma yalnız uygulama açıkken, Hava Durumu sayfası için çalışır ve konumu saklamaz; bu yüzden metin bu kullanımı kapsıyor. Metin değiştirilmedi. Not: metin "irtifa" kelimesini ayrıca anmıyor; düğme dünden beri aynı metinle GPS irtifası alıyordu, bu değişiklik yeni bir amaç eklemiyor.

## Uç durumlar

- **İç mekân / irtifa gelmedi:** Isınma kullanılabilir irtifa vermezse bellekte bir şey tutulmaz; düğme bugünkü gibi kendi isteğini yapar.
- **10 dakikadan fazla yer değiştirme:** 10 dakikadan eski değer kullanılmaz; düğme yeni istek yapar. 10 dakikanın içinde araçla uzun yol gidilirse eski yerin irtifası yazılabilir; sınır sahibin istediği 10 dakikadır.
- **Elle yazılan İrtifa:** Düğme beklerken kullanıcı İrtifa'ya yazarsa, gelen GPS değeri yazılanın üstüne yazılmaz (bu durumda durum yazısında irtifa kısmı yer almaz). Isınma kutuya hiçbir zaman kendisi yazmaz; yalnız düğmeye basılınca kullanılır.
- **Sıfırla:** Değişmedi. Basınç ve İrtifa boşalır; bir sonraki basışta 10 dakikadan yeni ısınma değeri yine yazılır.
- **Çevrimdışı:** GPS internet istemez; ısınma ve düğme internetsiz de çalışır. Hava verisi doldurma bu değişiklikten etkilenmez.
- **Arka plan:** Uygulama arka plana geçince süren ısınma iptal edilir, cevabı sonradan gelse de yok sayılır. Sayfa yeniden görünür olunca yeniden istenir.
- **Sayfa kapanınca (dispose):** Süren istek bırakılır; bekleyen sayaç ya da iş kalmaz.
- **Saat geri alınırsa:** Gelecekte görünen bir değer kullanılmaz; düğme yeni istek yapar.

## Bilerek yapılmayanlar

- Google Elevation ya da başka bir yeni irtifa kaynağı eklenmedi (istenmedi).
- İrtifa diske/profile kaydedilmedi; yalnız bellekte.
- Arka planda sürekli konum güncellemesi yapılmadı (sahip 14:10: "kafa karıştırır").
- Basınç mantığı, F1 basınçtan irtifa (#295), hava verisi doldurma (açık PR #302 aynı dosyada), diğer sayfalar ve Info.plist metinleri değiştirilmedi. Değişiklik `ballistics_screen.dart` içinde küçük ve yerel tutuldu (`_readPhonePressure`, yeni ısınma bölümü, initState/didUpdateWidget/dispose'a birer satır, `EnvironmentCarry` içinde bellek alanı).
- Düğmenin 8 saniyelik sınırı ve sağlayıcının 15 saniyesi değiştirilmedi.

## Değişen dosyalar

- `lib/tools/ports/location_provider.dart`: `current({precise = false, askPermission = true})`.
- `lib/tools/adapters/geolocator_location_provider.dart`: `precise` → yalnız o istek için `LocationAccuracy.high`; `askPermission: false` → izin penceresi açılmaz.
- `lib/features/ballistics/ballistics_screen.dart`: ısınma, düğmede ısınma değerinin kullanımı, elle yazılan İrtifa koruması.
- `test/support/tool_fakes.dart`: sahte konum sağlayıcısı çağrıları, izin ve bekletmeyi kaydeder.
- `test/irtifa_onceden_test.dart`: yeni testler.

## Testler (`test/irtifa_onceden_test.dart`, sahte konum + sahte saat)

- Hava Durumu açılınca tek, sessiz, yüksek doğruluklu istek başlar; ekranda yazı/simge yok.
- 3 saniye sonra basış: basınç ve ısınma irtifası (900 m) hemen yazılır; ikinci istek yok.
- Isınma 10 dakikadan eski: basışta yeni istek, onun değeri yazılır.
- Isınma irtifasız: basış bugünkü gibi istek yapar.
- İzin yok: ısınma GPS'e gitmez, izin penceresi açmaz; düğme bugünkü gibi izin sorar.
- Süren ısınma 8 saniyenin kalanı kadar beklenir; süre dolarsa "irtifa alınamadı, elle girin".
- Elle yazılan İrtifa üstüne yazılmaz (basış sırasında ve sonraki ısınmada).
- Sıfırla bugünkü gibi; sonraki basış yine doldurur.
- Sayfa 10 dakikadan sonra yeniden görünür: bir yeni ısınma; daha önce: yok.
- Gizli sekmede (IndexedStack) ısınma yok; sekme açılınca başlar.
- Arka plan: süren ısınma bırakılır, cevabı yok sayılır; bekleyen sayaç yok.
- Dispose: bekleyen sayaç/iş yok.

## Yerel kontroller

- `python3 tools/offline_dart_lint.py`: GEÇTİ (332 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: GEÇTİ (740 test).
- Bu ortamda Flutter SDK kurulamadı (Flutter motor indirmesi ağ kuralıyla engellendi): yerel `flutter analyze` / `flutter test` / `tools/claude_flutter_verify.sh` ÇALIŞMADI (BLOCKED). Analiz ve testler aşağıdaki CI çalıştırmalarında koştu.

## CI

- Biçim (dart format): https://github.com/sniperTurk/flutter-app/actions/runs/38556447863 — başarılı; biçim commit'i (`00b370f`) dala çekildi.
- Testler (`flutter test test`, tüm klasör, `00b370f`): https://github.com/sniperTurk/flutter-app/actions/runs/38556556854 — başarılı (adım çıkış kodu 0). Notlardaki "KESIK" ve yığın satırları main'deki başarılı çalıştırmada da aynen var (testlerin kendi tanı çıktısı).
- Analiz (`flutter analyze --fatal-infos --fatal-warnings`, `00b370f`): https://github.com/sniperTurk/flutter-app/actions/runs/38556562343 — başarılı.
- iOS CI (PR #303, rapor commit'i): https://github.com/sniperTurk/flutter-app/actions/runs/38557694970 — `verify`, `dart-checks`, `wind-acceptance` başarılı. `ios-simulator` işi atlandı (skipped): Simulator derlemesi çalışmadı, geçti denemez.
- TestFlight: çalıştırılmadı.

Taslak PR. Birleştirme yok, TestFlight yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
