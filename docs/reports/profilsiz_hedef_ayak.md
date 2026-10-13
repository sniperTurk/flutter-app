# Profilsiz Hedef ve Dürbün ayağı 0 MOA

Sahip kararı: 2026-10-13 23:21 (simülatör ekran turu, `ci/sim-screens`, `latest/`).
Dal: `fix/profilsiz-hedef-ayak` (taslak PR, birleştirme yok, TestFlight yok).

## Bulgu 1 — Profil yokken Hedef sayfası hesap gösteriyordu

**Asıl neden.** `lib/features/home/home_screen.dart` içindeki `_ballisticsTab`, hiç profil yokken (`profile == null && saved.isEmpty`) Hedef sekmesinde `ShotPreview` gösteriyor. `ShotPreview` (`lib/features/home/empty_states.dart`, `_ShotPreviewState`) kendi içinde sabit bir örnek .308 yükü tanımlıyordu (`_input`: 800 m/s, 168 gr, BC 0,462 G1, sıfır 100 m, nişangâh yüksekliği 45 mm, 3 m/s yan rüzgâr). `initState` → `_solve()` bu yükle `BallisticEngine().solve` çalıştırıyor, `ReticleHolds.sample` ile retikül tutuş sayılarını üretiyor ve sonucu gerçek `ScopeDialView`'a (`requiredUp`, `requiredRight`, `samples`, `windMpsPerUnit`) veriyordu. Ekrandaki 300 m, retikül sayıları, "Kule: 0 klik…", "Vuruş noktası: 48,9 cm aşağı · 15,6 cm sağ" ve "Hesap dökümü" bu örnek yükten geliyordu. `ballistics_screen.dart` ve `scope_dial_view.dart` bu durumda kullanılmıyor: `BallisticsScreen` profil `null` iken zaten hesap yapmıyor (Hava Durumu hariç kilitli mesaj gösteriyor).

**Ne değişti.** `ShotPreview` içine `showSample` bayrağı eklendi (`--dart-define=SHOT_SAMPLE_PREVIEW=true`, varsayılan kapalı). Kapalıyken:

- `initState` hiçbir şey hesaplamaz (motor, tutuş örnekleri, rüzgâr çarpanı çalışmaz).
- `build` yalnızca mevcut boş durum kartını (`_SloganCard`: "Tahmin yok, hesap var." + açıklama + "Profil oluştur") döndürür.

Örnek kod silinmedi, bayrağın arkasına gizlendi ("gizle, silme" kuralı).

**Seçimim: dekoratif retikül yok.** Mevcut önizlemede retikül süs değildi; gerçek `ScopeDialView` idi ve sayılar, kuleler, vuruş noktası onun parçasıydı. Sayısız bir retikül için yeni bir görünüm yazmak gerekecekti; diff'i küçük tutmak ve "çözüm gibi görünen" hiçbir şey bırakmamak için Hedef sayfasında yalnız kart kaldı. Mesafe, kaydırıcı ve ±1/±5 düğmeleri de gösterilmiyor.

**Şimdi nasıl çalışıyor.** Profil yok → Hedef: üst çubuk "Atış Çözümü / Hedef", altında yalnız "Tahmin yok, hesap var." kartı ve "Profil oluştur" düğmesi (Profil sekmesinde yeni profil formunu açar). Sayfada hiç rakam yok.

**Kenar durumlar.**

- *Hedef kullanılırken profil silinirse:* Silme Profil sekmesinde yapılır; ardından `_load` profilleri yeniden okur, `active` `null` olur ve Hedef'e dönüldüğünde yalnız boş durum kartı görünür. Eski `BallisticsScreen` profil değerleriyle anahtarlandığı için ekrandan kalkar; eski çözüm ekranda kalmaz.
- *Profilsizden yeni profile geçiş:* Profil kaydedilince `_load` aktif profili seçer, `_ballisticsTab` artık `ShotPreview` yerine profil değerleriyle anahtarlı yeni `BallisticsScreen` kurar; çözüm gerçek profilden hesaplanır. Örnek yükten hiçbir değer taşınmaz (örnek hiç hesaplanmadığı için).
- *Profiller var ama aktif profil yok / katalogla eşleşmiyor:* Bu dal (`profile == null || resolution == null`) değişmedi; zaten hesap yapmıyor, "Balistik / DOPE" kilitli kutusu ve "Profile git" gösteriyor. `_load` profil varsa her zaman birini aktif seçtiği için bu durum pratikte yalnız katalog uyuşmazlığında görülür.
- *Pro sayfası:* `ProPreview` hesap yapmıyor (yalnız kapalı kutular ve açıklamalar); değişmedi.

**Bilerek yapılmayanlar.** Sayısız dekoratif retikül eklenmedi. `ProPreview`, Hava Durumu'nun profilsiz hâli ve `BallisticsScreen` değişmedi. `integration_test/sim_screens_test.dart` değişmedi: `hedef_bos` adımı yalnız Hedef sekmesini açıp ekran görüntüsü alıyor, herhangi bir metin veya anahtar beklemiyor; artık yalnız kartın görüntüsünü alacak.

**Testler.**

- `test/profilsiz_hedef_ayak_test.dart`
  - "Hedef without a profile shows only the empty state, no solution numbers": `ScopeDialView`, retikül, "Vuruş noktası", "Hesap dökümü", "Kule:", "Kırmızı sayılar", mesafe ve kaydırıcı yok; "Tahmin yok, hesap var." ve "Profil oluştur" var; sayfada hiç rakam yok.
  - "the profile is deleted while Hedef was used": profil varken Hedef çözüm gösterir, Profil'de silinir, Hedef'e dönünce yalnız boş durum.
  - "with a profile the Hedef solution still appears": profil varken `ScopeDialView`, vuruş noktası ve Hesap dökümü görünür.
- `test/ballistics_profile_gate_test.dart`: profilsiz Hedef beklentisi güncellendi (örnek mesafe ve `ScopeDialView` artık yok).
- Profilli çözümün mevcut testleri (`yasla_sadece_hedef_test.dart`, `scope_dial_view_test.dart` vb.) değişmeden geçti.

## Bulgu 2 — Dürbün ayağı 0 MOA özette "Yok" görünüyordu

**Asıl neden.** `lib/features/profiles/profiles_screen.dart`, `_ActiveProfileDetails` → "Dürbün bilgileri" kartı: `profile.mountCantMoa > 0 ? _trimNum(...) : 'Yok'`. 0 değeri (formda "Normal (0 MOA)", kapalı kutuda "0 MOA") özel olarak "Yok" yazdırılıyordu.

**Ne değişti.** Kutu artık `mountCantSummary(double? moa)` ile kuruluyor: değer varsa `"<sayı>" + "MOA"` (formdaki kapalı kutuyla aynı: "0 MOA", "15 MOA", "30 MOA"), değer yoksa (`null`, sonsuz veya negatif) "—".

**Şimdi nasıl çalışıyor.** Normal ayak seçilen profilde özet "Dürbün ayağı: 0 MOA" gösterir; 15 MOA ayakta "15 MOA".

**Kenar durumlar.**

- *Alan yokken kaydedilmiş eski profiller:* `RifleProfile.mountCantMoa` boş olamayan bir `double` ve `profile_codec.dart` alan eksikse bunu bilerek 0 (normal ayak) olarak okuyor; hesap motoru da 0 kullanıyor. Bu yüzden eski profiller özette "0 MOA" gösterir; bu, hesapta gerçekten kullanılan değerdir. Modelde "ayarlanmamış" durumu olmadığından "—" bugün yalnız `mountCantSummary(null)` için geçerli (ileride alan boş bırakılabilir yapılırsa hazır).
- *Formda seçimi silmek:* Form kaydetmeden önce Dürbün ayağını zorunlu tutuyor (`_mountCantSet`); bu davranış değişmedi.

**Bilerek yapılmayanlar.** `mountCantMoa` boş olabilir (`double?`) yapılmadı: model, codec, motor ve birçok ekranı etkileyen büyük bir değişiklik olurdu ve eski profillerde 0 zaten doğru değer.

**Testler.** `test/profilsiz_hedef_ayak_test.dart`: "0 MOA mount" ve "15 MOA mount" (Profil özetinde Dürbün kartında "0 MOA"/"15 MOA" var, "Yok" yok); "tile text: 0 / 15 / 30 MOA and "—" when unset" (`mountCantSummary`).

## Doğrulama

- `python3 tools/offline_dart_lint.py`: PASS (324 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 732 test, OK.
- Yerel `flutter`: ENGELLİ — bu ortamda Dart SDK indirmesi (storage.googleapis.com) vekil sunucuda 403 ile reddedildi; `tools/claude_flutter_verify.sh` çalıştırılamadı. Bu nedenle Flutter doğrulaması yalnız aşağıdaki CI çalıştırmalarına dayanır.
- CI (dal başı `0d74d28`, kod değişikliklerinin tamamı):
  - Biçim (format-fix): başarılı, bir biçim commit'i ekledi — https://github.com/sniperTurk/flutter-app/actions/runs/38462618669
  - `flutter analyze --fatal-infos --fatal-warnings` (analyze-diag): başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38463005080
  - `flutter test test` (test-diag): başarılı, tüm testler — https://github.com/sniperTurk/flutter-app/actions/runs/38463001568
- Bu raporun commit'i yalnız `docs/` dosyası ekler; kodu değiştirmez.
- `iOS CI / verify`, simülatör ekran turu, cihaz, imzalama ve TestFlight bu iş için çalıştırılmadı; geçti denemez.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
