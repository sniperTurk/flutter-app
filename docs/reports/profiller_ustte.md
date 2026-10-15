# Profiller listesi en üstte

Sahip kararı: 2026-10-15 12:49 "profilleri yukarı al, içi böyle yazılı olsun"; görev 20:03. Referans: `design/clean-2026-10-15` dalı, README "Ek kararlar", Profil.png / Profil.dc.html (o dal birleştirilmedi).

## Ne yapıldı

- Profil sayfasında "Profiller" listesi sayfanın en üstüne alındı. Tüfek, Dürbün, Mühimmat özetleri ve "Hava Durumu'na geç" artık listenin altında.
- Başlık satırı: solda "Profiller", sağda amber "Profil ekle" düğmesi. Düğmede ikon ve "+" yok, yalnız yazı var.
- "N kayıtlı profil" alt satırı kaldırıldı.
- Her profil kartı: profil adı, aktif profilde yanında amber "Aktif" yazısı. Altında tek özet satırı:
  `kalibre, sıfır N m|yd, hız, BC x G1|G7`, örneğin `6,35 mm, sıfır 25 m, 900 fps, BC 0,08 G1`.
- Aktif kartın solunda 4 pt amber çizgi var. Eski nokta ve aktif karttaki 2 pt beyaz çerçeve kaldırıldı; bütün kartlarda ince çerçeve aynı.
- ⋯ menüsü sağda kaldı (dokunma alanı en az 44 pt). Düzenle, Kopyala ve Sil aynı şekilde çalışıyor.
- Yazılar sola hizalı.

## Nasıl

- `lib/features/profiles/profiles_screen.dart`: liste ve başlık bloğu `_ActiveProfileDetails`'ın üstüne taşındı. Gizli Yedekle / Geri yükle satırı (PROFILE_BACKUP_BUTTONS) listenin hemen altında kaldı. `_ProfileRow` yeniden çizildi.
- Özet satırı yeni `profileListSummary(RifleProfile)` fonksiyonundan geliyor:
  - Kalibre: profilin tüfeğinden (`6,35 mm`), Tüfek özetiyle aynı yazım.
  - Sıfır: profilin kendi mesafe biriminde (`25 m` ya da `100,0 yd`), Tüfek özetindeki "Sıfırlama mesafesi" ile aynı yazım.
  - Hız: Profil sayfasının birimi olan fps (`_ProfileUnits`).
  - BC: profilin mühimmatından; model biliniyorsa yanına `G1` / `G7` eklenir.
  - Değeri olmayan parça yazılmaz (tüfek bulunamazsa kalibre, BC yoksa BC kısmı).
- Ekran okuyucu: kart etiketi aynı kaldı ("Aktif profil X" / "Profil X"), özet satırı değer olarak okunuyor.
- Profil düzenleme dosyalarına (`profile_editor*.dart`) dokunulmadı.

## Neden

Sahip, profiller sayfanın en üstünde olsun ve her kartta profilin özeti yazsın istedi (Profil.png).

## Uç durumlar

- Yard profili: sıfır yd olarak yazılıyor (`sıfır 100,0 yd`).
- BC'si olmayan mühimmat: `6,35 mm, sıfır 25 m, 900 fps`. BC var ama model yoksa yalnız `BC 0,08`.
- Katalogda olmayan tüfek: kalibre kısmı yazılmıyor.
- 320 pt genişlik, 1,3× yazı boyutu: taşma yok. Uzun özet en çok 2 satıra kırılıyor, gerekirse "…" ile kısalıyor; ⋯ ekranda kalıyor.

## Yapılmayanlar

- Veri ve kayıt anahtarı değişmedi. Hiçbir kayıtlı değer silinmedi.
- Hız için m/s seçeneği yok: profilde hız birimi alanı bulunmuyor. Profil sayfası hızı her zaman fps gösteriyor, özet satırı da öyle.
- `MenzilPrimaryButton.iconLead` artık hiçbir sayfada kullanılmıyor. Kaldırılması gerekir ama `lib/ui/menzil_widgets.dart` bu görevin kapsamı dışında olduğu için dokunulmadı; ayrı bir görev olmalı.
- Üst çubuk, Hedef ve diğer "Ek kararlar" maddeleri başka görevlerde.

## Testler

- Yeni: `test/profiller_ustte_test.dart`
  - Liste Tüfek bölümünün üstünde.
  - Başlık düzeni, ikonsuz amber "Profil ekle".
  - Metrik, yard ve BC'siz profillerin özet satırları, kartta ve fonksiyonda.
  - Aktif kartın 4 pt amber çizgisi.
  - ⋯ menüsü açılıyor.
  - 320 pt'de, 1× ve 1,3× yazı boyutunda taşma yok.
- Güncellenen eski testler (sahibin yeni kararıyla çelişen beklentiler değişti, hiçbir kontrol gevşetilmedi):
  - `test/profiller_listesi_test.dart`: "+" ikonu ve "N kayıtlı profil" yerine, ikonun ve bu satırın olmadığı kontrol ediliyor. Silme testi sayaç yerine kartın kalktığını kontrol ediyor.
  - `test/profile_page_test.dart`: "özet listeden önce" testi ters çevrildi: artık liste özetten önce olmalı.
  - `test/profil_ekle_arti_test.dart`: Profil sayfasında "Profil ekle" ikonsuz; hiçbir sayfa `iconLead` kullanmıyor. Düğmenin kendi `iconLead` düzeni testleri aynen duruyor.
- Yerel:
  - `python3 tools/offline_dart_lint.py`: PASS (380 dosya, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: 842 test OK.
- Flutter SDK bu ortama kurulamadı (storage.googleapis.com vekil sunucuda 403). Bu yüzden `flutter test`, `flutter analyze` ve `dart format` yerelde ÇALIŞMADI (BLOCKED). Sonuçları aşağıdaki CI koşularında.

## CI

Sonuçlar PR açıklamasında ve aşağıda; yalnız gerçekten yeşil biten koşu yeşil olarak yazılır.

Commit `5e8d616` üzerinde `iOS CI` koşusu 38777143724:
- `verify`: başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38777143724/job/116572042427
- `dart-checks`: başarılı (biçim, analiz, testler). https://github.com/sniperTurk/flutter-app/actions/runs/38777143724/job/116567621579
- `wind-acceptance`: başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38777143724/job/116567621936
- `ios-simulator`: atlandı (yalnız elle çalışıyor).

Ek tanı koşuları (`analyze-diag`, `test-diag`): bu dala gönderildi, ikisi de başarılı bitti (38777135822, 38777132735). Bu iki koşu `main` adıyla göründüğü ve aynı anda başka görevler de koşu açtığı için, hangi koşunun bu dala ait olduğu zaman damgasından eşleştirildi. Asıl kanıt yukarıdaki PR koşusu.

Önceki koşularda iki sorun çıktı ve düzeltildi:
- `prefer_const_constructors` analiz uyarısı.
- `test/profile_page_test.dart` testinin eski sırayı beklemesi.

Biçim düzeltmesini CI'daki format iş akışı yaptı (commit `306ce35`). Bot commit'inin CI koşusu onay bekliyordu, API ile onaylandı.

Birleştirme yapılmadı, TestFlight başlatılmadı. Simulator dışında cihaz, imzalama ve TestFlight adımları çalışmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
