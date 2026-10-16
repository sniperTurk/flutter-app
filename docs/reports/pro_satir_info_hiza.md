# Pro Ayarlar: ⓘ başlığın hemen yanında, değerler tek sütunda

Dal: `design/pro-satir-info-hiza` · Taslak PR: #358 · Tarih: 16 Ekim 2026 (İstanbul)

## Ne

Sahibin 16 Ekim 2026, 07:59–08:08 kararı ("Bu sayfada infolar bence çok düzensiz duruyor", "Sayfa başlıkları da açılır menüleri açıyor... Kullanıcı infoları boş sanabilir", sonra "Tamam yap"):

- Pro Ayarlar'daki altı açılır satır (Açı, Rüzgâr düzeltmesi, Coriolis, Yerçekimi, Hareketli hedef, Tüfek düzeltmeleri) artık şu sırada: **[başlık][ⓘ][boşluk][değer][⌄]**.
- ⓘ, başlık yazısının bittiği yerden 8 pt sonra durur. Başlık uzun ya da kısa olsun, ortaya kaymaz.
- Değerler ("düz", "kapalı", "en çok 5 m/s" …) ve ⌄ okları kartın sağ kenarında, bütün satırlarda aynı sütunda.
- 390 pt ekranda altı başlığın hepsi tek satır. "Rüzgâr düzeltmesi", "Hareketli hedef" ve "Tüfek düzeltmeleri" artık iki satıra kaymıyor, bu yüzden kartlar biraz alçaldı.
- ⓘ'nin kendi dokunma alanı var: 44×44 pt. Başlık yazısının üstüne binmez. Bu alana dokunmak yalnız açıklama sayfasını açar, kutuyu açıp kapatmaz.
- Satırın geri kalanı kutuyu eskisi gibi açıp kapatır: başlık, aradaki boşluk, değer ve ok.
- Garmin saati satırının ⓘ'si de aynı biçimde, başlığın hemen yanında. Bu satıra yalnız ⓘ kuralı uygulandı (aşağıda "Bilerek yapılmayan").

## Nasıl

- Yeni dosya `lib/features/ballistics/pro_row_header.dart`:
  - `ProRowHeader` satırı çizer. Başlığın tek satırdaki genişliğini ölçer ve başlığa gerektiği kadar yer verir. Kalan yer değere gider.
  - Yer yetmezse önce değer "…" ile kısalır, en fazla ilk harfi ve "…" kalana kadar. Başlık ancak o da yetmezse alt satıra geçer.
  - Başlık iki satıra geçse bile kutusu en uzun satırda biter, böylece ⓘ yine yazının hemen yanında kalır.
  - `proRowInfoButton` ⓘ'yi 44×44 pt'lik bir kutuya koyar. Simge kutunun sol kenarından 8 pt içeride durur.
- `MenzilInfoButton`'a iki isteğe bağlı ayar eklendi: `alignment` ve `padding`. Varsayılanları eskisiyle aynı, bu yüzden diğer sayfalardaki ⓘ'ler değişmedi.
- `MenzilToolTile`: başlığın yanında ⓘ varsa (yalnız Garmin satırında var), iki satıra kayan başlık en uzun satırında biter.
- `pro_ayarlar_view.dart`: `_proBox` başlık satırı `ProRowHeader` ile yapıldı. Kart, renkler, yazı tipi, sıra, metinler, `pro-box-*` / `pro-section-*` / `pro-info-*` / `pro-summary-*` anahtarları ve özet yazıları aynı kaldı.

## Neden

- **ⓘ'nin yeri:** Eskiden başlık ile değer satırı yarı yarıya paylaşıyordu. Bu yüzden uzun başlıklar iki satıra kayıyor, ⓘ satırın ortasında kalıyordu.
- **Değerlerin hizası:** Değerler sağa yaslı değildi, her satırda başka yerden başlıyordu.
- **Dokunma:** ⓘ'nin dokunma alanı yazının sol tarafına 2 pt taşıyordu. Simge de alanın ortasında olduğu için ⓘ'ye basmak isteyen kullanıcı kolayca başlığa basıp kutuyu açabiliyordu.
- **Yeni düzen:** Simge, başlığın bittiği yerden hemen sonra başlayan 44 pt'lik alanın solunda. Alanın sağ tarafı da ⓘ'ye ait, böylece hedef büyük.

## Uç durumlar

- **320 pt ekran ve yazı büyütme ×1,3:** Taşma yok. Önce değer kısalır ("k…"). Başlık yalnız değer ilk harfine inse de sığmıyorsa iki satır olur, ⓘ yine yazının hemen yanında kalır.
- **Kutu açıkken:** Değer gizlenir ama yeri ayrılmış kalır. Böylece kutu açılıp kapanırken başlık bir satırdan iki satıra zıplamaz (bu, kod incelemesinde bulundu ve düzeltildi).
- **iOS "Kalın yazı" ayarı:** Ölçüm bunu hesaba katar.
- **ⓘ ile kutunun içindeki ⓘ'ler:** Kutu içindeki alan ⓘ'leri değişmedi; aynı alttan açılan sayfayı açmaya devam ederler.

## Bilerek yapılmayan

- Açıklama metinleri, özet yazıları, hesaplar ve diğer sayfalar değişmedi. Yeni satır yok.
- **Garmin satırında değer/ok sütunu:** Bu satır açılır kutu değil. Sağında "isteğe bağlı" ve > oku var, ⌄ yok. Yalnız ⓘ kuralı uygulandı. Sağ taraf eski haliyle (liste satırı) kaldı.
- **ⓘ'ye basınca çıkan halka:** Basılı tutunca çıkan yuvarlak gölge 44 pt alanın ortasında çiziliyor, simgenin yaklaşık 5 pt sağında. Bu yalnız görünüşle ilgili, değiştirilmedi.
- **Ekran görüntüsü:**
  - Bu depoda golden (ekran görüntüsü karşılaştırmalı) test yok.
  - Bu oturumda Flutter SDK indirilemedi: storage.googleapis.com proxy'de kapalı.
  - Bu yüzden önce/sonra ekran görüntüsü eklenemedi. Ölçüler aşağıdaki widget testleriyle doğrulandı.
- **Merge ve TestFlight:** Merge yapılmadı, TestFlight başlatılmadı.

## Testler

Yeni dosya: `test/pro_satir_info_hiza_test.dart`.

Test yazı tipi her harfi kare çizer. Bu yüzden testte iPhone'un SF yazısı yerine Inter yüklenir (`ekran_boyutu_test.dart` ile aynı yöntem).

- **390 pt:**
  - Her satırda ⓘ simgesi başlığın sağ kenarı + 8 pt'de (±1 pt). Garmin satırı da dahil.
  - ⓘ alanı ≥44×44 pt ve başlık yazısıyla kesişmiyor.
  - Altı başlığın hepsi tek satır.
  - Değerlerin sağ kenarı aynı (±0,5 pt), okların sağ kenarı aynı (±0,5 pt).
- **320 pt ×1,0, 390 pt ×1,3 ve 320 pt ×1,3:**
  - Taşma yok, ⓘ başlığın hemen yanında, değerler tek sütunda.
  - Bir başlık iki satıra geçtiyse, değer ilk harf + "…" olsa bile sığmadığı doğrulanır.
  - Kutu açılınca başlığın yüksekliği değişmez.
- **Dokunma:**
  - ⓘ ortasına ve ⓘ alanının kenarına yakın bir noktaya (merkezden +18 pt) dokunmak açıklama sayfasını açar, kutu kapalı kalır.
  - Başlığa, aradaki boşluğa, değere ve oka dokunmak kutuyu açar.
  - Garmin ⓘ'si Garmin Connect'i açmaz.
- **Mevcut testler:** Hiçbiri değiştirilmedi, hiçbiri gevşetilmedi.

**Yerel:**

- `python3 tools/offline_dart_lint.py`: PASS (401 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 868 test, OK.
- `flutter test` yerelde çalıştırılamadı: Flutter SDK indirilemedi.

## CI bağlantıları

- **Format (format-fix):** başarılı, değişiklik gerekmedi. https://github.com/sniperTurk/flutter-app/actions/runs/38854935012
- **Analyze (analyze-diag):**
  - İlk commit: başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38855182989
  - Son commit: başarılı. https://github.com/sniperTurk/flutter-app/actions/runs/38857827170
- **Tüm testler (test-diag, `files=test`), ilk commit:** 2101 geçti, 1 kaldı.
  - Kalan test yeni testti: test yazı tipiyle "Rüzgâr düzeltmesi" sığmadı. Inter yüklenerek düzeltildi.
  - https://github.com/sniperTurk/flutter-app/actions/runs/38855181428
- **Hedefli testler, son commit:** başarılı.
  - Dosyalar: yeni test, `pro_info_popup_test`, `pro_tab_test`, `garmin_pro_ayarlar_test`, `garmin_link_test`.
  - https://github.com/sniperTurk/flutter-app/actions/runs/38857825591
- **iOS CI** (`dart-checks`, `wind-acceptance`, `verify`): sonuçlar PR'daki check'lerde. Yeşil olmadan yeşil denmez.

## Kod incelemesi ve güvenlik incelemesi

- **Kod incelemesi:** Yüksek ya da orta önemde bulgu yok. Düşük önemli bulgu (kutu açılınca başlık yüksekliğinin değişmesi) düzeltildi. "Değer önce kısalır" kuralı için test eklendi. Halka görünüşü ve RTL notu yukarıda.
- **Güvenlik incelemesi:** Bulgu yok. Yalnız yerleşim değişikliği: yeni giriş, kayıt, ağ ya da veri yok.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
