# PCP tüfek ve mühimmat kartları, birimler kutunun içinde

İstek: sahip, 16.10.2026 20:49–21:04 (İstanbul). Onaylanan çizim aşağıdaki düzen, birimler kutunun içinde. PR #368, dal `fix/pcp-muhimmat-tasarim`. Önceki görev a12c814'te yarıda kalmıştı. Bu çalışma o dalın üstüne yapıldı; yeni kararlara uyan kısımlar tutuldu, uymayanlar değiştirildi.

## Ne değişti

### Tüfek kartı (`profile_editor_rifle.dart`)

Marka, Model ve "Aradığın tüfek listede yok mu?" bugünkü gibi duruyor. Altındaki satırlar, her satırda iki kutu:

| | PCP | Ateşli |
|---|---|---|
| 1 | Kalibre \| Namlu çıkış hızı | Kalibre \| Namlu çıkış hızı |
| 2 | Yiv oranı \| Namlu yiv yönü | Yiv oranı \| Namlu yiv yönü |
| 3 | Tüp basıncı \| Regülatör basıncı | Sıfırlama mesafesi \| Mesafe birimi |
| 4 | Sıfırlama mesafesi \| Mesafe birimi | Sight height (tek başına, son satır) |
| 5 | Sight height (tek başına, son satır) | |

- **Namlu çıkış hızı** PCP'de de Tüfek kartında kaldı. Önceki görev bu kutuyu kaldırmıştı, geri geldi. Bugünkü gibi zorunlu. PCP'de ⓘ metni `ProfileFieldInfo.velocity`, ateşli tüfekte `velocityFirearm`.
- **Tüp basıncı | Regülatör basıncı** Mühimmat kartından Tüfek kartına taşındı (yalnız PCP). Birimleri bar, ikisi de isteğe bağlı. Kayıt anahtarları aynı (`tubePressureBar`, `pressureBar`), bu yüzden eski kayıtlı değerler yine açılıyor. Kodda not var: "owner 2026-10-16: kept for future regulator use; not in the formula". İki ⓘ metni sahibin verdiği metinle harfi harfine aynı. Regülatör metnine "Tüfeğinizde regülatör yoksa bu kutuyu boş bırakın." cümlesi eklendi.
- Etiketler değişmedi; "Sight height" adı korundu.
- "Kaydetmek için eksik" listesi de kutuların yeni sırasına göre sayıyor.

### Mühimmat kartı, PCP (`profile_editor_ammo.dart`)

Önceki görevin onaylı tasarımı korundu:

1. Tip | Marka
2. Model
3. "Aradığın mühimmat listede yok mu?"
4. Ağırlık | BC
5. BC modeli (Uzunluk bugünkü gibi gizli)
6. En düşük namlu çıkış hızı | En yüksek namlu çıkış hızı (fps)

Değişenler:

- Tüp ve Regülatör basıncı bu karttan çıktı. "Basınca göre hız" tablosu silinmiş olarak kaldı.
- En düşük ve En yüksek hız artık **isteğe bağlı**. ⓘ metinleri önceki görevdeki onaylı metinler (17:18–18:02); hiçbiri "zorunlu" demiyor. Testle kontrol ediliyor.
- Kartın kutuları kompakt kalıyor (Hava Durumu kutusu gibi; birim ve ⓘ kutunun içinde). Sahip bu tasarımı 2026-10-16'da onayladı.

### Hesapta kullanılan hız

Kod artık tek bir yerden okuyor: `RifleProfile.velocityMps`.

- En düşük ve En yüksek ikisi de girildiyse hız ikisinin ortalaması. Örnek: 830 ve 860 → 845 fps.
- İkisi de boşsa Tüfek kartındaki Namlu çıkış hızı kullanılıyor. Örnek: 950 fps.
- Yalnız biri girildiyse yine Tüfek kartındaki hız kullanılıyor. Boş kutuda "En düşük ve en yüksek hızın ikisini de girin." hatası çıkıyor.
  - **Seçim: kayıt yapılmıyor.** Güncelle ya da Kaydet kapalı kalıyor ve "Kaydetmek için eksik" boş kutunun adını söylüyor. Neden: uygulamadaki öteki çift alan (Barut sıcaklığı: katsayı ve sıcaklık) da böyle çalışıyor.
  - Hata, öteki kutuya yazılır yazılmaz görünüyor; Kaydet'e basmak gerekmiyor.
- En düşük > En yüksek ise Türkçe hata çıkıyor: "En düşük hızdan küçük olamaz."

Kayıt şöyle tutuluyor:

- `muzzleVelocityMps`, Tüfek kartındaki değer. Anahtarı bugünküyle aynı.
- Çift ayrı anahtarlarda: `pcpMinVelocityMps`, `pcpMaxVelocityMps`.

Bu hızı kullanan yerler:

- Hedef (sıfır ve atış); saat paketi, isabet olasılığı ve DOPE da Hedef'in hızından geliyor.
- Hız Doğrulama'nın üç modu.
- MPBR.
- Tüp ve Regülatör basıncı hiçbir hesaba girmiyor.

### Eski PCP profilleri

Eski profiller kayıtlı Namlu çıkış hızıyla açılıyor ve eskisi gibi hesaplanıyor. "Namlu çıkış hızlarını girin" boş durumu (Hedef, Hız Doğrulama, Profil özeti, liste satırı) kaldırıldı.

### Hız Doğrulama (KUL-10)

Sayfa, Hedef'in kullandığı hızı kullanıyor (ortalama ya da Tüfek kartındaki hız). Sayfadaki kartta da bu hız yazıyor.

- Çift girilmiş PCP'de hız modu ortalamayı doğruluyor ama profile yazmıyor. "Profile uygula" kapalı ve ⓘ'si nedenini söylüyor.
- Çift yoksa main'deki gibi çalışıyor: kullanıcı onaylarsa Tüfek kartındaki hız güncelleniyor.
- BC ve Sürüklenme eğrisi modları da aynı hızla çözüyor. KUL-10 böylece kapandı.

### Birimler kutunun içinde (`lib/ui/menzil_widgets.dart`)

Ortak `MenzilInput` değişti:

- Birim artık etiket satırında değil, kutunun içinde sağda.
- ⓘ etiket satırının sağında kalıyor.
- Yazılan değer birimin olduğu yerde bitiyor; uzun bir değer birimin altına girmiyor.
- Yiv oranı kutusunda "inç" yazıyor.

Bu değişiklik `MenzilInput`'un birim gösterdiği her sayfaya geçiyor. Hava Durumu ve Pro zaten kompakt kutu kullanıyordu; orada birim önceden de kutunun içindeydi. `MenzilSelect` (liste kutuları) değişmedi.

### Önceki görevden tutulanlar

- "Basınca göre hız" tablosu silinmiş olarak kaldı. Silinenler: profil satırları, `PcpPressure` hesabı, Hedef'teki ve Hız Doğrulama'daki tablo yolu.
- Gizli `PRO_TUBE_PRESSURE` yolu silinmiş olarak kaldı (Pro'daki "Kalan tüp basıncı").
- Gizli `PCP_AMMO_BRAND` bayrağı silinmiş olarak kaldı. PCP'de Marka ve Model hep görünüyor.
- Hedef'teki "Regülatör devre dışı" uyarısı da silinmiş olarak kaldı. Bu uyarı, silinen tüp/regülatör hız hesabının parçasıydı; basınçlar artık hesaba girmiyor.
- Kayıtlı veri silinmedi:
  - Eski bir profilde tablo varsa hâlâ okunuyor ve kaydedince aynen geri yazılıyor; hiçbir hesap onu okumuyor.
  - Pro'da eskiden girilmiş tüp basıncı da kayıtta aynen kalıyor.

## Nasıl

- `RifleProfile.velocityMps`: çift geçerliyse (ikisi var ve en düşük ≤ en yüksek) ortalamayı, değilse `muzzleVelocityMps`'i döndürüyor. Hedef'in hız kutusu, Hız Doğrulama ve MPBR bunu okuyor.
- `ProfileInput.validate`:
  - Tüfek kartındaki hızı her zaman okuyor.
  - Çift için kurallar: ikisi birlikte girilmeli, en düşük ≤ en yüksek olmalı, aralık 100–4900 fps.
  - Ateşli tüfekte çifti hiç almıyor.
- Codec: çift eski profillerde yok ve boş okunuyor. Varsa sayı, sonlu, > 0 ve ≤ 1500 m/s olmalı; ikisi birlikte olmalı ve en düşük ≤ en yüksek olmalı. Bunun dışı bozuk kayıt sayılıyor.
- Bütünlük kontrolü: çifti taşıyan ateşli tüfek profili bozuk sayılıyor.
- Araçların profil güncellemesi çifti aynen taşıyor. Çift girilmiş bir PCP'ye tek bir hız yazmaya çalışırsa Türkçe bir hatayla duruyor, çünkü yazılan hız hesabı değiştirmezdi.
- Tasarım: Frontend Design yönergesi açıldı. Yeni görsel dil eklenmedi; uygulamanın kendi kutuları kullanıldı. Birim, kutunun `suffixIcon`'u olarak çiziliyor; boyutu birimin boyu kadar, kutunun 46 pt yüksekliği değişmiyor.

## Neden

Sahibin 16.10.2026 20:49–21:04 kararları:

- Onaylanan çizim.
- Namlu çıkış hızı Tüfek kartında kalır.
- En düşük ve En yüksek hız isteğe bağlı; ikisi girilirse ortalama kullanılır.
- Basınçlar Tüfek kartına geçer ve hesaba girmez.
- Birimler kutunun içinde: "sağda onayladığım şeklidir".

## Uç durumlar

- **Yalnız bir hız girildiyse:** boş kutuda hata var, kayıt yok. Profilde eski kayıtlı durum geçerli kalıyor; hesap Tüfek kartındaki hızla devam ediyor.
- **Kayıtta yarım çift ya da en düşük > en yüksek varsa:** bu ancak elle bozulmuş veriyle olabilir. Codec böyle bir kaydı bozuk sayıyor. Programın içinde böyle bir profil kurulursa hesap Tüfek kartındaki hızı kullanıyor; testi var.
- **Tüp ve Regülatör basıncı girildiyse:** sonuç değişmiyor (test 1e-12).
- **Kalibre yarım kutuda:** uzun bir kalibre adı kutunun içinde alt satıra geçiyor ve kutu büyüyor. Yanındaki Namlu çıkış hızı kutusu üstten hizalı kalıyor.
- **Dar ekran:** 320 pt'de kartın iç genişliği 300 pt'nin altında kalıyor. Uygulamanın ortak kuralı (`MenzilFieldGrid`) gereği her kutu kendi satırına iniyor ama sıra aynı kalıyor. Taşma yok; yazı ölçeği 1.3'te de yok.
- **Ateşli tüfek:** Tüp ve Regülatör kutuları yok. Hesap değişmedi: Hedef altın sayıları (`test/core/hedef_golden_numbers_test.dart`) aynen geçiyor.

## Bilerek yapılmayanlar

- **Kronograf:** "Seri ortalaması profile uygula" çift girilmiş bir PCP'de onay penceresinden sonra Türkçe hatayla duruyor ve profile hiçbir şey yazmıyor. Sayfadaki kart Tüfek kartındaki hızı gösteriyor. İstekte Kronograf yoktu; değiştirilmedi. Code Review'da da not edildi (eşik altında).
- Profil özeti ve liste satırı "Namlu çıkış hızı" olarak Tüfek kartındaki değeri gösteriyor (main'deki gibi). Ortalama burada gösterilmiyor; istenmedi.
- Mühimmat kartındaki ⓘ'ler önceki görevin onaylı kompakt tasarımında kaldı: kutunun içinde. Tüfek kartında ⓘ etiket satırında.
- `ProfileCatalogIntegrity` çiftin aralığını ayrıca kontrol etmiyor; kayıt yolu (codec, `ProfileInput`) kontrol ediyor. Security review'da "düşük" olarak not edildi.
- Taşıma kodu yok; gerek de yok, eski profiller olduğu gibi çalışıyor.
- PR #363'teki KUL-10 testi silinen tabloya göre yazılmıştı ve `skip`'li. Aynı senaryo bu PR'da tablosuz ve atlanmadan duruyor: `test/audit_2026_10_15c/kul10_pcp_hiz_test.dart`. #363 birleşecekse oradaki `skip`'li KUL-10 testi bu dosyayla değiştirilmeli. #363'ün dosyasına dokunulmadı, çakışma olmasın diye.
- Birleştirme yok, TestFlight yok.

## Testler

### Yeni ya da yeniden yazılan

**`test/pcp_muhimmat_tasarim_test.dart`** (yeniden yazıldı):

- Tüfek kartının sırası dikey konumla, PCP ve Ateşli için, 390 ve 320 pt'de, yazı ölçeği 1.0 ve 1.3'te:
  - İki sütunda kutular yan yana, tek sütunda alt alta.
  - Sight height en sonda ve tam genişlikte.
  - Taşma yok.
- Tüp ve Regülatör Tüfek kartında; Mühimmat kartında yoklar.
- Mühimmat PCP sırası, aynı dört ölçüde. "Basınca göre hız" yok.
- Birim kutunun içinde:
  - Kontrol edilen kutular: fps, inç, bar, bar, m, mm.
  - Birim kutunun dikdörtgeninin içinde ve sağ yarısında.
  - Uzun değerin yazı alanı birimin solunda bitiyor.
  - Birim etiket satırında yok; ⓘ etiket satırında.
  - 390 ve 320 pt, 1.3 ölçekte.
- Etiketler 390 pt'de tek satır: Sıfırlama mesafesi, Namlu çıkış hızı, Regülatör basıncı.
- ⓘ metinleri harfi harfine aynı. Hız ⓘ'leri "zorunlu" demiyor.
- Editör:
  - Çift boşken eksik yok.
  - Yalnız En düşük girilince En yüksek kutusunda hata çıkıyor ve kayıt yok. Tersi de aynı.
  - En düşük > En yüksek hatası; 100–4900 fps aralığı.
- Kaydet:
  - 950 + 830/860 girildi → kayıtta 950, 830, 860 ve hesap hızı 845.
  - 950 + boş → çift yok ve hesap hızı 950.
  - Profili Düzenle'de bütün değerler kendi kutusunda geri geliyor.
- Hedef:
  - 830/860 (Tüfek 950) ile 845'in sonucu 1e-9'a kadar aynı.
  - Boş ile 950 aynı.
  - Yalnız En düşük 830 ile 950 aynı.
  - 845 ile 950'nin sonucu birbirinden farklı.
- Hız Doğrulama:
  - 830/860 → kartta "845 fps"; doğrulanan hız 845; uygula kapalı; profil değişmiyor.
  - Boş ve yalnız En düşük → kartta "950 fps"; doğrulanan hız 950; uygula açık.
- Eski PCP profili (yeni anahtarlar olmadan JSON):
  - 885.8 fps ile açılıyor; çift kutuları boş; eksik yok; boş durum yazısı yok.
  - Hedef'in sonucu main'dekiyle birebir aynı (aşağıya bakın).

**Eski profilin main'deki sonucu nasıl ölçüldü:** main'in (e7b29bf) üstüne yalnız yazdıran bir test koyan geçici bir dal açıldı (`tmp/pcp-eski-golden-main`). Test-diag run 38947080076 değeri 6.142636207799528 olarak verdi. Bu dalın testi aynı değeri bekliyor. Geçici dal silinemedi: bu ortamdan dal silmeye izin yok (git push --delete bağlantıyı kesti, REST 403). Dal `tmp/pcp-eski-golden-main` hâlâ duruyor ve birleştirilmemeli; silinmesi sahibe kaldı.

**`test/audit_2026_10_15c/kul10_pcp_hiz_test.dart`** (yeni, `skip` yok): KUL-10'un sayıları aynı. Hedef 255 m/s ile çözüyor (çift 250/260, Tüfek kartında 270); 18 gr; G1 0,031; sıfır 30 m; doğrulama 100 m'de. Uygulanan BC ≈ 0,031 çıkıyor ve Hedef'in hızıyla gözlemi 0,05 mrad içinde geri veriyor. Elle kontrol: 255 m/s'de 6,89 mrad.

### Kurala göre güncellenenler

Hiçbiri gevşetilmedi; değişen kural yazıldı.

- `test/velocity_caliber_row_test.dart`, `test/profil_duzen_koruma_test.dart`, `test/profile_lists_test.dart`, `test/temiz_tasarim_profil_test.dart`: Tüfek kartının yeni satırları (Kalibre | Namlu çıkış hızı …). Koruma testi PCP için ayrı bir düzen bekliyor ve "eksik" sırasına Basınç'ı ekledi.
- `test/kutu_fikir4_test.dart`: Profil kutusu 44 pt etiket satırı ve 46 pt kutu olarak kaldı. Artık birimin kutunun içinde olduğunu kontrol ediyor (önceden kutunun içinde olmadığını kontrol ediyordu).
- `test/audit_2026_10_14b/turret_zero_cleanup_audit_test.dart`:
  - F3 testi "tüp regülatörün altında → hız düşer" artık "sıfırda kalır" bekliyor (basınç hesapta yok).
  - Tasarım koruması tersine döndü: Namlu çıkış hızı hesaba giriyor, kayıtlı tablo girmiyor.
  - Yeni koruma: çift varsa ortalama giriyor.
  - KUL-2: çift varsa uygula kapalı. Tablo kayıtlı ama çift yoksa hız main'deki gibi yazılıyor ve tablo silinmiyor.
- `test/pcp_pressure_ui_test.dart`, `test/pcp_pressure_profile_test.dart`: tablo satırlarının olmadığını kontrol ediyorlar. Basınç ve kayıtlı tablo sonucu değiştirmiyor. Çiftli PCP'de araç tek bir hız yazmıyor.
- `test/profile_page_test.dart`, `test/profile_editor_fail_closed_test.dart`, `test/bc_modeli_secim_test.dart`, `test/atesli_elle_muhimmat_test.dart`, `test/user_catalog_test.dart`: PCP Marka/Model görünüyor; ⓘ listesine çift eklendi.
- `test/support/rifle_form.dart`: `fillPcpVelocities` yardımcısı eklendi.
- Python: `tools/test_denetim_2026_10_14b_prf.py`, `test_denetim_2026_10_14c.py`, `test_denetim_2026_10_15b_guvenlik.py`: silinen bayraklar listeden çıktı (önceki görevden).

Önceki görev 100'den fazla test profiline `pcpMin/MaxVelocityMps` eklemişti. Bunlar main'deki hâline döndü. Yani eski PCP profilleri hiç değiştirilmemiş testlerle de main'deki sayıları veriyor.

### Silinen testler

Hepsi silinen özelliklerle birlikte gitti:

- `test/pcp_pressure_test.dart` (bütün dosya, `PcpPressure`).
- `test/audit_2026_10_14/formulas_audit_test.dart`: iki `PcpPressure` testi.
- `test/profile_lists_test.dart`: "PCP mühimmat: Marka yok" (gizli bayrak silindi).
- `test/audit_2026_10_14b/turret_zero_cleanup_audit_test.dart`: KUL-3. Silinen `PRO_TUBE_PRESSURE` kaynak metnine bakıyordu ve zaten `skip`'liydi.
- `integration_test/sim_screens_test.dart`: `pro_tup_basinci` adımı (Pro kutusu silindi).

### Yerel çalıştırmalar

- `python3 tools/offline_dart_lint.py` → PASS (408 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'` → OK (915 test, 1 atlanan; atlanan test önceden de atlanıyordu).
- Flutter SDK bu ortamda kurulamadı: Dart SDK indirmesi proxy'de 403 aldı (storage.googleapis.com). `flutter test`, `flutter analyze` ve `dart format` yerelde **çalışmadı (BLOCKED)**; yalnız CI'da çalıştı.

## Ekran görüntüleri

Simülatör turu: `integration_test/sim_screens_pcp_kartlar_test.dart`, iş akışı sim-screens.
- Koşu: https://github.com/sniperTurk/flutter-app/actions/runs/38968207435
- Cihaz: iPhone 17 Pro, iOS 26.2.
- Sonuç: flutter test çıkış kodu 0, 27 ekran görüntüsü.

Görüntüler, `ci/sim-screens` dalının a96550a commit'inde kalıcı olarak duruyor.

390 ve 320 pt nasıl çekildi: uygulama, Simülatör ekranının solunda 390 ya da 320 pt genişliğinde bir kutuda çiziliyor; uygulamanın kendi ekran ölçüsü de 390 / 320 pt. Ekranın sağında kalan kısım siyah.

İlk deneme (koşu 38964065412) geçersizdi. O denemede genişlik `tester.view` ile değiştirilmişti. Simülatör ekranı ilk kareden sonra hiç güncellenmedi; bütün görüntüler açılış ekranını gösteriyordu. Ayrıca iki adım da düştü. Tur düzeltildi ve tekrar çalıştırıldı.

| Ekran | 390 pt | 320 pt |
|---|---|---|
| PCP Tüfek kartı | [01_pcp_tufek_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/01_pcp_tufek_390.png), [02_pcp_tufek_390_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/02_pcp_tufek_390_alt.png) | [17_pcp_tufek_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/17_pcp_tufek_320.png), [18_pcp_tufek_320_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/18_pcp_tufek_320_alt.png) |
| PCP Mühimmat kartı | [05_pcp_muhimmat_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/05_pcp_muhimmat_390.png), [06_pcp_muhimmat_390_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/06_pcp_muhimmat_390_alt.png) | [19_pcp_muhimmat_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/19_pcp_muhimmat_320.png), [20_pcp_muhimmat_320_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/20_pcp_muhimmat_320_alt.png) |
| PCP Mühimmat, yalnız En düşük girili | [03_pcp_muhimmat_tek_hiz_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/03_pcp_muhimmat_tek_hiz_390.png), [04_pcp_muhimmat_tek_hiz_390_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/04_pcp_muhimmat_tek_hiz_390_alt.png) | |
| Ateşli Tüfek kartı | [07_atesli_tufek_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/07_atesli_tufek_390.png), [08_atesli_tufek_390_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/08_atesli_tufek_390_alt.png) | [21_atesli_tufek_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/21_atesli_tufek_320.png), [22_atesli_tufek_320_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/22_atesli_tufek_320_alt.png) |
| Hava Durumu | [09_hava_durumu_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/09_hava_durumu_390.png) | [23_hava_durumu_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/23_hava_durumu_320.png) |
| Pro | [12_pro_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/12_pro_390.png) | [26_pro_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/26_pro_320.png) |
| Hedef (845 fps ortalamayla) | [14_hedef_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/a96550a4656c2105792622665de9fd4588903c4a/latest/14_hedef_390.png) | |

### Onaylı çizimden görünen farklar

1. **320 pt'de satırlar iki kutulu değil.** Kartın iç genişliği 300 pt'nin altına düşüyor. Ortak düzen kuralı (`MenzilFieldGrid`) gereği her kutu kendi satırına iniyor: Kalibre, Namlu çıkış hızı, Yiv oranı … alt alta. Sıra çizimdeki gibi. Bu kural bütün uygulamada geçerli; bu PR'da değiştirilmedi.
2. **390 pt'de Kalibre iki satır.** "5.50 mm (.22)" yarım kutuya sığmıyor ve alt satıra geçiyor; Kalibre kutusu yanındaki Namlu çıkış hızı kutusundan uzun görünüyor. İki kutunun üstleri hizalı.
3. **ⓘ iki ayrı biçimde.** Mühimmat kartında ⓘ kutunun içinde (önceki görevin onaylı kompakt kutusu). Tüfek kartında ⓘ etiket satırında (C maddesi). İki kart yan yana bakılınca farklı görünüyor.
4. **Hava Durumu ve Pro'da görünür bir değişiklik yok.** Bu iki sayfa zaten kompakt kutu kullanıyordu; birim önceden de kutunun içindeydi. Görüntüler bunu göstermek için çekildi. Değişikliğin görüldüğü yer Profil Oluştur ve Düzenle'deki kutular (fps, inç, bar, m, mm).
5. **320 pt'de uzun metinler kısalıyor.** Mühimmat Model kutusunda "Baracuda Match .22 cal. · 21.…" kısaltılıyor. "Aradığın mühimmat listede yok mu?" iki satıra iniyor.
6. **Ondalık ayırıcı farklı.** Profil Oluştur'da listeden gelen Ağırlık ve BC virgüllü ("21,14", "0,039"); Profili Düzenle'de noktalı ("21.14", "0.039"). Bu fark main'de de var; bu PR'da değiştirilmedi.
7. **Ekranın sağ tarafı siyah.** 390 ve 320 pt görüntülerinde uygulama ekranın solunda duruyor (yukarıdaki yöntem yüzünden).

## Rebase 17.10

main ilerlediği için PR çakışıyordu. main'deki yeni iki commit (#371 yan kule, #370 Düzeltmeler 16.10) bu dala birleştirildi (merge commit 7569163; geçmiş yeniden yazılmadı, zorla gönderim yok). #369, #372 ve #373 zaten dalın tabanındaydı.

Sonra #367 (Dürbün girişi: liste sırası, 8 satırlık açılır liste, Dürbün modeli zorunlu) main'e girdi (2231591). O da birleştirildi (merge commit 9412125); çakışma çıkmadı. Ortak dosyalarda (`menzil_widgets.dart`, `profile_editor.dart`, test yardımcıları) iki tarafın değişikliği de duruyor. En son #377 (Profil özeti etiketleri, 8cc3aab) geldi; o da çakışmasız birleştirildi (a96bb9b).

- **Tek çakışma `pro_ayarlar_view.dart`'ta.** main (#370) Mühimmat sıcaklığı kutusunu Hava Durumu'ndan Pro → Tüfek düzeltmeleri'ne taşıdı; bu PR aynı yerdeki "Kalan tüp basıncı" kutusunu siliyordu. İkisi birden tutuldu: Mühimmat sıcaklığı kutusu, sayımı ("N ayar açık") ve başlık ⓘ'sindeki metni main'deki gibi duruyor; Kalan tüp basıncı silinmiş olarak kaldı.
- **main'in kararları korundu.** Mühimmat sıcaklığı Pro'da, ateşli silahta; kutunun içinde ⓘ yok (#373 kuralı), metni bölüm başlığının ⓘ'sinde. Hedef tıklama satırı, Profil ekle eni, üst çubuktaki profil seçici main'deki gibi.
- **Birim kutunun içinde.** Bu PR'ın ortak `MenzilInput` değişikliği (birim kutunun içinde sağda) taşınan Mühimmat sıcaklığı kutusuna da kendiliğinden uygulanıyor: "°C" / "°F" kutunun içinde sağda, kutuda ⓘ yok. Ek kod gerekmedi.
- **Bu PR'ın amacı değişmedi.** PCP Tüfek ve Mühimmat satırları, hız seçimi (ortalama / Tüfek kartı hızı / tek değer uyarısı), "Basınca göre hız" yok, KUL-10 testi atlanmadan çalışıyor. Hesapta başka değişiklik yok, test gevşetilmedi.
- **Eski regülatörsüz PCP profilleri.** main'de regülatörsüz bir PCP profilinde basınca göre hız tablosu varsa hız, profildeki tüp basıncına göre tablodan bulunuyordu. Bu PR'la tablo silindiği için bu profiller artık Tüfek kartındaki Namlu çıkış hızını kullanıyor. Kayıtlı tablo silinmiyor; eski kayıtlar açılmaya devam ediyor, yalnız hesaba girmiyor.

### Yerel

- `python3 tools/offline_dart_lint.py`: 415 dosya, 0 sorun.
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 915 test, başarılı (1 atlanan: PRE-1 denetim bulgusu, main'de de atlanıyor, bu PR'la ilgisi yok).

### CI (son kod commit'i a96bb9b: main 8cc3aab + bu PR)

| İş | Sonuç | Bağlantı |
|---|---|---|
| iOS CI / verify | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39005415703/job/117319991658 |
| iOS CI / dart-checks | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39005415703/job/117316819692 |
| iOS CI / wind-acceptance | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39005415703/job/117316819551 |
| iOS CI / ios-simulator | atlandı (iş akışı bu olayda çalıştırmıyor) | aynı koşu |
| test-diag (`files=test`, bütün testler) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39005414044 |
| analyze-diag | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39005415413 |
| format-fix (375209577) | başarılı, değişiklik yok | https://github.com/sniperTurk/flutter-app/actions/runs/39005412570 |

Ara koşular: 7569163'te (yalnız #370/#371 birleştirilmiş) verify, dart-checks, wind-acceptance, test-diag ve analyze-diag başarılıydı (iOS CI 38996922629, test-diag 38996980913). 9e646fd'de (#367 sonrası) test-diag 39002317054 ve dart-checks bir testte düştü; neden ve düzeltme "Rebase'te düzeltilen test"te. Düzeltmeden sonra 8d4bffc'de test-diag başarılı (39004823160).

İlk iOS CI koşusu 03:04'te (UTC) main'de başlayan TestFlight tarafından iptal edildi (TestFlight macOS koşularını boşaltıyor); aynı koşu yeniden çalıştırıldı ve yukarıdaki sonuçlar o yeniden koşunun. İki simülatör turu da başka görevlerin tur istekleriyle sıradan düştü; yeniden istendi.

### Ekran görüntüleri (rebase sonrası)

İki simülatör turu (iPhone 17 Pro, sim-screens iş akışı). İkisinde de flutter test çıkış kodu 0.

- **PCP kartları:** `integration_test/sim_screens_pcp_kartlar_test.dart`, koşu https://github.com/sniperTurk/flutter-app/actions/runs/39002763951 (04:44 UTC'de başladı; dal o an 9e646fd'deydi, yani #367 birleştirilmiş hâli). 27 görüntü, `ci/sim-screens` 3c3e6a9. (README'de "@ 2231591" yazıyor: iş akışı, elle başlatılan koşuda main'in commit'ini yazıyor; çekilen dal fix/pcp-muhimmat-tasarim.)
- **Pro → Tüfek düzeltmeleri (Mühimmat sıcaklığı):** main'deki `integration_test/duzeltmeler_16_10_screens_test.dart`, koşu https://github.com/sniperTurk/flutter-app/actions/runs/39000252045 (dal 7569163'teyken, #367 ve #377'den önce). 20 görüntü, `ci/sim-screens` 05f63d8. #367 ve #377 bu kutuya dokunmuyor; bu tur yeniden çekilmedi.

| Ekran | 390 pt | 320 pt |
|---|---|---|
| PCP Tüfek kartı | [01_pcp_tufek_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/01_pcp_tufek_390.png), [02_pcp_tufek_390_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/02_pcp_tufek_390_alt.png) | [17_pcp_tufek_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/17_pcp_tufek_320.png), [18_pcp_tufek_320_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/18_pcp_tufek_320_alt.png) |
| PCP Mühimmat kartı | [05_pcp_muhimmat_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/05_pcp_muhimmat_390.png), [06_pcp_muhimmat_390_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/06_pcp_muhimmat_390_alt.png) | [19_pcp_muhimmat_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/19_pcp_muhimmat_320.png), [20_pcp_muhimmat_320_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/20_pcp_muhimmat_320_alt.png) |
| PCP Mühimmat, yalnız En düşük girili | [03_pcp_muhimmat_tek_hiz_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/03_pcp_muhimmat_tek_hiz_390.png), [04_pcp_muhimmat_tek_hiz_390_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/04_pcp_muhimmat_tek_hiz_390_alt.png) | |
| Ateşli Tüfek kartı | [07_atesli_tufek_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/07_atesli_tufek_390.png), [08_atesli_tufek_390_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/08_atesli_tufek_390_alt.png) | [21_atesli_tufek_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/21_atesli_tufek_320.png), [22_atesli_tufek_320_alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/22_atesli_tufek_320_alt.png) |
| Pro → Tüfek düzeltmeleri, Mühimmat sıcaklığı | [07_pro_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/05f63d8852b093635f40c34c0f8a353a15fbd3cc/latest/07_pro_390.png), ⓘ sayfası [08_pro_bilgi_390](https://raw.githubusercontent.com/sniperTurk/flutter-app/05f63d8852b093635f40c34c0f8a353a15fbd3cc/latest/08_pro_bilgi_390.png) | [17_pro_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/05f63d8852b093635f40c34c0f8a353a15fbd3cc/latest/17_pro_320.png), ⓘ sayfası [18_pro_bilgi_320](https://raw.githubusercontent.com/sniperTurk/flutter-app/05f63d8852b093635f40c34c0f8a353a15fbd3cc/latest/18_pro_bilgi_320.png) |

Görülen (onaylı çizimle karşılaştırma):

- PCP Tüfek: Kalibre | Namlu çıkış hızı · Yiv oranı | Namlu yiv yönü · Tüp basıncı | Regülatör basıncı · Sıfırlama mesafesi | Mesafe birimi · Sight height. Birimler (fps, inç, bar, m, mm) kutunun içinde sağda. Etiketler 390 pt'de tek satır.
- PCP Mühimmat: En düşük | En yüksek namlu çıkış hızı yan yana, "fps" kutunun içinde. "Basınca göre hız" yok.
- Pro → Tüfek düzeltmeleri: Mühimmat sıcaklığı kutusu solda, "°C" kutunun içinde sağda, kutuda ⓘ yok, sağında "isteğe bağlı". Metni bölüm başlığının ⓘ sayfasında. Kalan tüp basıncı yok.
- Farklar, önceki bölümdekiyle aynı ve dürüstçe: 320 pt'de satırlar tek kutuya iniyor (ortak `MenzilFieldGrid` kuralı; Pro'da Yukarı / Sağ da alt alta); 390 pt'de Kalibre "5.50 mm (.22)" iki satır; Mühimmat kartında ⓘ kutunun içinde, Tüfek kartında etiket satırında; 320 pt'de Model ve "Aradığın mühimmat listede yok mu?" kısalıyor / iki satır; Profil Oluştur'da virgül, Düzenle'de nokta; ekranın sağı siyah (dar genişlik yöntemi).

### Rebase'te düzeltilen test

`test/pcp_muhimmat_tasarim_test.dart` "labels fit on one line at 390 pt" #367'den sonra düştü (test-diag 39002317054, dart-checks da). Neden: test yazı tipinde her harf 12,5 pt geniş; bu etiketler orada hiç tek satıra sığmıyor. Test, etiketleri "Yiv oranı" ile karşılaştırıyordu ve eskiden dördü de iki satır olduğu için geçiyordu (geçici dallarda ölçüldü: önce 114 pt genişlik, dördü 32 pt yükseklik; #367'den sonra 125 pt, Yiv oranı 16 pt, ötekiler 32 pt). Yani test tek satırı hiç ölçmüyordu. Düzeltme: test, `durbun_listeleri_test.dart`'taki gibi uygulamanın Inter yazı tipini yüklüyor ve her etiketin (Yiv oranı dahil) tek satır olduğunu doğrudan ölçüyor. Test gevşetilmedi; önceki hâlinden sıkı. Uygulama kodu değişmedi. Simülatörde de dördü tek satır (02_pcp_tufek_390_alt).

Ölçüm için açılan geçici dallar (`diag/pcp-label-1017`, `diag/pcp-label-old`) bu oturumdan silinemedi (vekil sunucu dal silmeye izin vermiyor); birleştirilmeyecekler, silinebilirler.

## CI

Aşağıdaki koşular rebase sonrası commit **7a7ac21** üzerinde (main f46ab8f'in üstünde). Sonra gelen a1a5006 yalnız simülatör turunu düzeltiyor; bu raporun commit'i ise yalnız bu dosyayı değiştiriyor. Son commit'in (HEAD) CI sonuçları, raporu yeniden değiştirmemek için PR açıklamasında. Önceki 8 commit tek commit'te toplandı. Rebase'te tek çakışma `pro_ayarlar_view.dart`'taydı: #373 silinen `_pcpPressureProFields`'i değiştirmişti; fonksiyon silinmiş olarak bırakıldı.

| İş | Sonuç | Bağlantı |
|---|---|---|
| iOS CI / verify | başarılı (7a7ac21) | https://github.com/sniperTurk/flutter-app/actions/runs/38957814565/job/117170753189 |
| iOS CI / dart-checks | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38957814565/job/117165007855 |
| iOS CI / wind-acceptance | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38957814565/job/117165007645 |
| iOS CI / ios-simulator | atlandı (iş akışı bu olayda çalıştırmıyor) | aynı koşu |
| test-diag (`files=test`, bütün testler) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38958183988 |
| analyze-diag | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/38958186264 |
| format-fix (375209577) | başarılı, değişiklik yok (kod zaten biçimli) | https://github.com/sniperTurk/flutter-app/actions/runs/38957820241 |
| main'deki eski PCP değeri (geçici dal) | bilerek düşen tek test, değer okundu | https://github.com/sniperTurk/flutter-app/actions/runs/38947080076 |

Ara koşular (rebase öncesi):
- test-diag 38947664929: 1 test düştü, `profile_lists_test` "Fabrika fişeği": hız kutusunun eski yerini bekliyordu. Yeni kurala göre düzeltildi; sonraki koşu (38949816043) başarılı.
- 18:45 ve 19:07'de başlayan iOS CI `verify` ve simülatör turu 19:39'da iptal edildi. Aynı anda main'de TestFlight koşusu başladı ve macOS koşuları iptal edildi; bu iptallerin bu PR'la ilgisi yok.

Code Review ve Security review yapıldı: https://github.com/sniperTurk/flutter-app/pull/368#issuecomment-6222636244. Eşiği geçen bulgu yok. Eşik altındaki iki not "Bilerek yapılmayanlar"da.

## ⓘ etiket satırının sağında (17.10)

İstek: sahip, 17.10.2026 11:18–11:21 (İstanbul). #368 ile TestFlight 112 yan yana gösterildi. Sahip: "Hayır fps bar kutu içi, infolar sağ üst". Plan onaylandı ("Aç").

### Ne

- **ⓘ kutunun içinden çıktı.** Artık etiket satırının sağ ucunda duruyor, kutunun sağ üstünde. TestFlight 112 ve main'deki yeriyle aynı.
  - Bu, ortak `MenzilInput` ve `MenzilSelect`'in kompakt düzeninde değişti (`MenzilCompactFields`). Kompakt düzeni şu sayfalar kullanıyor: PCP Mühimmat kartı, Hava Durumu ve Pro Ayarlar'daki Atış mesafesi.
  - Normal düzende ⓘ zaten etiket satırının sağındaydı. Profil Tüfek, Dürbün ve Ateşli Mühimmat kartları değişmedi. Bu ekran görüntüleri öncekilerle bayt bayt aynı.
- **Birimler kutunun içinde kaldı** (fps, bar, gr, mm, m, °C, %, m/s, saat, hPa…). Kutunun sağ kenarında duruyorlar. Etiket satırında birim yok.
- **Normal `MenzilSelect`'in birimi de kutunun içine alındı, okun soluna.** Bu birim önceden etiket satırındaydı. Bu iki kutuyu etkiliyor:
  - Profil → Ek mühimmat bilgileri → Hız ölçüm sıcaklığı (°C)
  - Araçlar → Sıfır Grubu → Kare boyu (cm). Burada kapalı kutu yalnız sayıyı gösteriyor ("1  cm ▾"), böylece "cm" iki kez yazılmıyor. Açılan listede yine "1 cm" yazıyor.
- **Pro Ayarlar bölüm kutularında ⓘ yok** (sahibin istisnası). Açıklamaları bölüm başlığının ⓘ'sinde kalmaya devam ediyor.
- **Hava Durumu'nda hiçbir ⓘ silinmedi.** Yalnız yerleri değişti:
  - Sıcaklık, Bağıl nem, Rüzgâr hızı ve Rüzgâr yönü ⓘ'leri etiket satırının sağına taşındı.
  - Rüzgâr başlığının ⓘ'si yerinde duruyor.
  - Rüzgâr gözlemi ⓘ'si de korunuyor; o kutu bayrakla gizli olduğu sürece görünmüyor.
- Şunlar değişmedi: etiket metinleri, kutuların sırası, her satırda iki kutu kuralı, değerler, kayıt anahtarları ve hesaplar.

### Nasıl

- `lib/ui/menzil_widgets.dart`, `_CompactLabel`: kutunun hemen üstündeki küçük etiket artık ⓘ'yi de taşıyor.
  - Satır, ⓘ'nin dokunma alanı kadar yüksek: 44 pt.
  - Etiket satırın altında; kutuyla arası önceki gibi 5 pt.
  - ⓘ simgesinin ortası etiket yazısının ortasına hizalı.
  - ⓘ'nin dokunma alanı 44 pt genişlikte ve sağ kenarı kutunun sağ kenarında.
  - Etiket ⓘ'nin altına girmesin diye sağda 37 pt boş kalıyor. Normal düzende de aynı.
- `_CompactTrailing` artık yalnız birimi gösteriyor (liste kutusunda birim ve ok). Kutu 44 pt yüksekliğini koruyor.
- `MenzilCompactFields.reserveInfo` (varsayılan: açık): ⓘ'si olmayan bir kutu da aynı satır yüksekliğini tutuyor. Böylece yan yana iki kutu aynı hizada başlıyor.
  - Pro Ayarlar ve Hava Durumu'nda kapalı. Orada ⓘ'li ve ⓘ'siz kutu yan yana gelmiyor; bu sayede ⓘ'siz kutular (Pro bölüm kutuları, İstasyon basıncı, İrtifa) eskisi gibi sıkı kalıyor.
- `MenzilSelect`, normal düzen: etiket satırına birim verilmiyor. Birim, okla birlikte kutunun içinde çiziliyor (`menzil-select-unit`).
- VoiceOver:
  - ⓘ'nin etiketi hâlâ "Bilgi: <etiket>".
  - Alanın etiketi hâlâ "<etiket> (<birim>)".
  - Kutudaki birim yazısı ayrıca okunmuyor; birim zaten alanın etiketinde okunuyor.
- Frontend Design eklentisi kullanıldı. Yeni bir görsel dil eklenmedi; uygulamanın kendi ⓘ yeri ve ölçüleri kullanıldı.

### Neden

Sahip ⓘ'yi kutunun sağ üstünde, birimi kutunun içinde istedi. TestFlight 112'deki yer bu.

### Uç durumlar

- **Kart uzadı.** Kompakt satırda ⓘ'nin 44 pt dokunma alanı etiket satırını yükseltiyor. Bu yüzden PCP Mühimmat kartı ve Hava Durumu'nun Sıcaklık/Rüzgâr satırları uzadı, her satır yaklaşık 20 pt.
  - Etiket ile kutu arasındaki 5 pt değişmedi. Boşluk etiketin üstünde açılıyor.
- **Uzun etiketler küçülüyor.** Etiketlere sağda 37 pt yer ayrıldığı için uzun etiketler biraz daha küçük yazılıyor. Yine tek satır kalıyorlar, taşmıyor, "…" çıkmıyor. Örnek: 390 pt'de "En düşük namlu çıkış hızı".
- **Dar ekranda tek sütun.** 320 pt'de, yazı büyüklüğü 1,3'te ve dar ekranlarda satırlar eskisi gibi tek sütuna iniyor. Bu, ortak `MenzilFieldGrid` kuralı; değişmedi.
- **Birimli `wrapSelected` kutusu yok.** `wrapSelected` (kayan uzun seçim) kullanan bir liste kutusunun birimi yok. Birimli böyle bir kutu eklenirse uzun yazı birimin altına girebilir. Bugün böyle bir kutu yok.
- **Sağdan sola diller.** `PositionedDirectional` kullanıldığı için ⓘ bu dillerde sol üstte duruyor.

### Testler

- Yeni: `test/info_etiket_satiri_test.dart`. 390 pt, 320 pt ve 320 pt + yazı 1,3 için kontrol edilenler:
  - **Alanlar:**
    - PCP Mühimmat: Tip, Marka, Ağırlık, BC, BC modeli, En düşük, En yüksek.
    - PCP Tüfek: Kalibre, Namlu çıkış hızı, Tüp basıncı, Regülatör basıncı.
    - Hava Durumu: Sıcaklık, Bağıl nem, Rüzgâr hızı, Rüzgâr yönü.
  - **Her alanda ⓘ:**
    - kutunun dışında ve üstünde;
    - sağ kenarı kutunun sağ kenarına 1 pt'den yakın;
    - ortası etiket satırında ve etiket yazısının hizasında;
    - dokunma alanı en az 44×44 pt; "Bilgi: …" etiketi var;
    - etiket ⓘ'nin altına girmiyor.
  - **Birim:** kutunun içinde, sağ yarıda.
  - **Hizalama:** yan yana kutular aynı yükseklikte.
  - **Ayrıca:**
    - Ateşli Tüfek kartı da aynı düzende.
    - ⓘ açıklamayı açıyor, alana odaklanmıyor.
    - Pro bölüm kutularında (Hedef hızı, BC hatası, Atış sayısı) ⓘ yok.
    - Pro'da 320 pt + 1,3'te taşma yok.
- Kurala göre güncellenenler: eski "ⓘ kutunun içinde" kontrolleri tersine çevrildi; hiçbiri gevşetilmedi.
  - `test/kutu_fikir4_test.dart`:
    - ⓘ etiket satırının sağında, kutuda değil.
    - Birim kutunun sağında.
    - Hata yazısı kutunun altında; kutu yine 44 pt (artık birimin 44 pt'lik parçasıyla ölçülüyor).
  - `test/pcp_muhimmat_tasarim_test.dart`: kompakt kutuda ⓘ kutunun üstünde ve sağa hizalı.
  - `test/profil_duzen_koruma_test.dart`: Hız ölçüm sıcaklığının °C'si etiket satırında değil, kutunun içinde. Konumu ölçülüyor.
- #368'in hesap testleri değişmedi ve geçiyor: hız ortalaması 830/860 → 845, Tüfek kartına düşüş, tek hız uyarısı, KUL-10.
- `tools/test_denetim_2026_10_15b_pre.py` (`unit: 'cm'` regresyon koruması) bir ara düştü. Neden: Kare boyu'ndan birimi kaldırmıştım. Birim geri kondu; çift "cm" kapalı kutuda kısa metinle çözüldü. Test gevşetilmedi.

### Yerel

- `python3 tools/offline_dart_lint.py`: PASS, 426 Dart dosyası, 0 sorun (main birleştirildikten sonra).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 915 test, OK (1 atlandı; bilerek atlanan PRE-1). Bu koşu 3ea4bf6'da yapıldı. Kare boyu düzeltmesinden sonra düşen modül (`tools.test_denetim_2026_10_15b_pre`) yerelde yeniden çalıştı: OK.
- Bu ortamda Flutter SDK kurulamadı. Dart SDK indirmesi vekil sunucuda 403 verdi. Bu yüzden widget testleri yalnız CI'da çalıştı.

### Ekran görüntüleri

Simülatör turu: `integration_test/sim_screens_pcp_kartlar_test.dart`, iPhone 17 Pro, sim-screens iş akışı.

- Yeni koşu: https://github.com/sniperTurk/flutter-app/actions/runs/39022132218. Dal bf51f0a'daydı; flutter test çıkış kodu 0, 27 görüntü. Görüntüler `ci/sim-screens` b1333ba'da. README "@ 8cc3aab" yazıyor; çekilen dal fix/pcp-muhimmat-tasarim.
- Önceki koşu (39017853853) uygulama açılış ekranında takıldı. Hiçbir test başlamadı, zaman aşımına uğradı.
- Bir koşu da (39020270842) sıradayken başka bir koşu yüzünden iptal oldu. sim-screens iş akışında aynı anda yalnız bir koşu sırada bekleyebiliyor.

Önceki #368 görüntüleri `ci/sim-screens` 3c3e6a9'da; yeniler b1333ba'da. Sol sütun önceki, sağ sütun yeni:

| Ekran | Önceki #368 (3c3e6a9) | Yeni (b1333ba) |
|---|---|---|
| PCP Tüfek kartı 390 | [01](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/01_pcp_tufek_390.png) | [01](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/01_pcp_tufek_390.png), [02 alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/02_pcp_tufek_390_alt.png) |
| PCP Tüfek kartı 320 | [17](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/17_pcp_tufek_320.png) | [17](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/17_pcp_tufek_320.png) |
| PCP Mühimmat kartı (dolu) 390 | [05](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/05_pcp_muhimmat_390.png), [06 alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/06_pcp_muhimmat_390_alt.png) | [05](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/05_pcp_muhimmat_390.png), [06 alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/06_pcp_muhimmat_390_alt.png) |
| PCP Mühimmat kartı 320 | [19](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/19_pcp_muhimmat_320.png), [20 alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/20_pcp_muhimmat_320_alt.png) | [19](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/19_pcp_muhimmat_320.png), [20 alt](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/20_pcp_muhimmat_320_alt.png) |
| Ateşli Tüfek kartı 390 | [07](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/07_atesli_tufek_390.png) | [07](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/07_atesli_tufek_390.png) |
| Hava Durumu üstü 390 | [09](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/09_hava_durumu_390.png) | [09](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/09_hava_durumu_390.png), [10](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/10_hava_durumu_390_2.png) |
| Hava Durumu üstü 320 | [23](https://raw.githubusercontent.com/sniperTurk/flutter-app/3c3e6a90a585275d2c3c59508e9b67bcf6113e27/latest/23_hava_durumu_320.png) | [23](https://raw.githubusercontent.com/sniperTurk/flutter-app/b1333bad5273d79035a000535846f1e3224437cf/latest/23_hava_durumu_320.png) |

Görünen farkların hepsi:

1. **PCP Mühimmat:** Tip, Marka, Ağırlık, BC, BC modeli, En düşük ve En yüksek'in ⓘ'si kutudan çıktı; etiket satırının sağ ucunda, kutunun sağ kenarı hizasında. "gr" ve "fps" kutunun sağında kaldı ve artık kutunun en sağına yaslı; önceden ⓘ'nin solundaydı.
2. **PCP Mühimmat kartı uzadı.** Her kutu satırı yaklaşık 20 pt uzun; boşluk etiketin üstünde. 390 pt'de kartın sonu (En düşük | En yüksek) aşağı kaydı. Etiket ile kutu arası aynı.
3. **Hız etiketleri küçüldü.** 390 pt'de "En düşük namlu çıkış hızı" ve "En yüksek namlu çıkış hızı" biraz daha küçük yazıyla tek satırda; sağda ⓘ'ye yer ayrıldı.
4. **Hava Durumu:** Sıcaklık ve Bağıl nem'in ⓘ'si etiket satırının sağında; °C ve % kutunun en sağında. Bu satır biraz uzadı, alttaki kartlar aşağı kaydı. Rüzgâr hızı ve Rüzgâr yönü de aynı biçimde, ikinci görüntüde (10).
5. **Değişmeyenler:** İstasyon basıncı ve İrtifa (ⓘ'leri kart başlığında) aynı sıkılıkta.
6. **Tüfek kartları değişmedi.** PCP Tüfek 390/320 ve Ateşli Tüfek 390 görüntüleri öncekilerle bayt bayt aynı; zaten normal düzendeydiler.
7. **320 pt'de tek sütun:** Mühimmat satırları eskisi gibi tek sütun. Ekranın sağı, dar genişlik yöntemi yüzünden siyah.

### CI (bf51f0a: main 8cc3aab + bu PR)

| İş | Sonuç | Bağlantı |
|---|---|---|
| iOS CI / verify | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39020745687/job/117365174564 |
| iOS CI / dart-checks | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39020745687/job/117361882803 |
| iOS CI / wind-acceptance | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39020745687/job/117361882587 |
| iOS CI / ios-simulator | atlandı (iş akışı bu olayda çalıştırmıyor) | aynı koşu |
| test-diag (`files=test`, bütün testler) | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39020742911 |
| analyze-diag | başarılı | https://github.com/sniperTurk/flutter-app/actions/runs/39020744708 |
| format-fix (375209577) | başarılı; test dosyalarında 3 biçim düzeltmesi yaptı (266ea24) | https://github.com/sniperTurk/flutter-app/actions/runs/39017828682 |
| Simülatör turu | başarılı, 27 görüntü | https://github.com/sniperTurk/flutter-app/actions/runs/39022132218 |

Ara koşular:

- **3ea4bf6 (dart-checks düştü):** biçim yüzündendi; format-fix düzeltti.
- **ddc3f8f (dart-checks düştü):** Kare boyu `unit: 'cm'` regresyon koruması düştü; bf51f0a'da düzeltildi.
- **266ea24 (iOS CI bekledi):** format-fix bot commit'inde iOS CI "action_required" durumunda kaldı.

Bu rapor commit'inde main (#380 DEN17B-1, #381 Hedefin yönü) birleştirildi; çakışma olmadı. Bu commit'in CI sonuçları PR açıklamasında.


## Hız şimdilik Tüfek kartından (17.10)

Sahip, 17.10.2026 13:14–13:21 (İstanbul): "Kutuları koy, aç; namlu çıkış hızından yapsın hesaplamayı." · "Testleri arka planda yapacaksın, sanki yeni özellik ekliyor gibi; testler başarılı olunca yükleyeceksin." · ⓘ için: "şu an bir kullanıcı yok ki".

Bu bölüm, yukarıdaki "Hesapta kullanılan hız" bölümünün yerini alır. Ortalama (830/860 → 845) bu PR'da yok; daha sonra ayrı ve tam test edilmiş bir özellik olarak gelecek.

### Ne

- **Hesapta kullanılan hız:** Her hesap PCP'de de Tüfek kartındaki Namlu çıkış hızıyla yapılır. En düşük ve En yüksek ne girilmiş olursa olsun sonuç değişmez. Bu, Hedef, DOPE, Pro, Hız Doğrulama, MPBR, kronograf, PDF ve saat için geçerli.
- **Kutular duruyor:** En düşük | En yüksek namlu çıkış hızı kutuları yerinde. Gösterilir, kaydedilir ve Profili Düzenle'de geri gelir. Anahtarlar aynı: `pcpMinVelocityMps` ve `pcpMaxVelocityMps`.
- **Uyarı kalktı:** "En düşük ve en yüksek hızın ikisini de girin." uyarısı ve kaydı engellemesi silindi. İki kutu da isteğe bağlı. Biri, ikisi ya da hiçbiri girilse de profil kaydedilir.
- **Değişmeyenler:** ⓘ metinleri, düzen, etiketler, sıra ve birimler değişmedi. "Basınca göre hız" silinmiş hâliyle kalıyor: eski tablolu PCP profilleri Tüfek kartındaki hızla hesaplanır.

### Nasıl

- **Ortalama silindi.** `RifleProfile.velocityMps` ve `hasPcpVelocityRange` koddan silindi; bayrakla gizlenmedi. Hedef (`ballistics_screen.dart`), Hız Doğrulama (`truing_screen.dart`) ve MPBR (`mpbr_screen.dart`) yeniden `muzzleVelocityMps` okuyor.
- **Hız Doğrulama eskisi gibi.** Ortalamaya ait bilgi kutusu, kapalı "profile uygula" düğmesi ve onun ⓘ'si silindi. Bunlar yalnız ortalama varken görünüyordu. Artık PCP'de de doğrulanan hız, onay sonrası Tüfek kartındaki hıza yazılır, ateşli tüfekteki gibi.
- **Araçlar hız yazabiliyor.** `ToolProfileUpdate`'teki "PCP'de tek hız yazılmaz" engeli silindi. Kronograf ve Hız Doğrulama yeniden Namlu çıkış hızını yazabiliyor; En düşük ve En yüksek olduğu gibi korunuyor.
- **Her kutu tek başına geçerli.** `ProfileInput`, `ProfileCodec` ve editör her kutuyu ayrı ayrı kabul ediyor. Aralık kuralı aynı: 100–4900 fps. İkisi birlikte girilmişse "En düşük hızdan küçük olamaz." kuralı duruyor. Kaydedilmiş bir çiftte en düşük değer en yüksekten büyükse kayıt bozuk sayılıyor.

### Neden

Sahip, hesabın şimdilik Tüfek kartındaki hızla yapılmasını istedi. Ortalama, ayrı bir özellik olarak sonra eklenecek. Tek kutu uyarısı da ortalamaya aitti; ortalamayla birlikte kalktı.

### Uç durumlar

- **Yalnız biri girilmiş:** Uyarı çıkmaz, Kaydet açık kalır. Değer kaydedilir ve geri yüklenir.
- **İkisi de girilmiş, En düşük > En yüksek:** Eskisi gibi hata verir ve kayıt beklemeye alınır.
- **Eski PCP profili:** Hem pressure-table'lı olanlar hem de kutuları hiç olmayanlar Tüfek kartındaki hızla hesaplanır. Kayıtlı veri silinmez.
- **ⓘ metni ile hesap arasındaki fark (bilerek değiştirilmedi):** En düşük ve En yüksek kutularının ⓘ'si hâlâ "Değerler doğru girilmediğinde hesaplanan klikler ve isabet tahmini yanlış çıkar" diyor. Bu değerler şimdilik hesaba girmiyor. Sahip ⓘ metinlerinin değişmemesini istedi.
- **Eski sürüme dönüş:** Bu sürümde yalnız bir hızı kaydedilmiş bir PCP profili, eski bir TestFlight sürümünde (çift isteyen eski okuyucu) açılmaz. Profil karantinaya alınır; veri silinmez. Bu sürüm eski kayıtları sorunsuz okur.

### Testler

**Değiştirilen testler:**

- **`test/pcp_muhimmat_tasarim_test.dart`:** Ortalama ve uyarı testleri silindi; yerine şunlar geldi:
  - PCP, Tüfek 900 fps, En düşük 830 / En yüksek 860: Hedef sonucu, ikisi boşken alınan 900 fps sonucuyla birebir aynı (`requiredUp`). Yalnız En düşük ya da yalnız En yüksek girildiğinde de aynı. 845 fps sonucundan 0,1'den fazla ayrılıyor, yani ortalama kullanılmıyor.
  - Yalnız biri girildiğinde uyarı yok ve eksik listesi boş. 830/860, yalnız 830, yalnız 860 ve ikisi boş için kaydet, kodlayıcıyla oku ve Profili Düzenle'de kutulara geri gelme testleri var.
  - `ProfileInput`: her kutu tek başına geçerli; ters çift hata verir; ateşli tüfekte kutular yok sayılır.
  - Codec: tek değer gidip geliyor; ters çift bozuk kayıt sayılıyor.
  - Hız Doğrulama 830/860, boş ve yalnız 830 için: "Namlu çıkış hızı: 900 fps" yazıyor, 900 doğrulanıyor, "profile uygula" açık.
- **`test/audit_2026_10_15c/kul10_pcp_hiz_test.dart` (KUL-10):** Sayılar aynı. Tüfek 255 m/s, Hedef'in hızı. En düşük 265 / En yüksek 275 m/s; ortalamaları 270 m/s ve kullanılmamalı. Hız Doğrulama'nın BC'si 255 m/s'de çözülüyor.
- **`test/audit_2026_10_14b/turret_zero_cleanup_audit_test.dart`:**
  - "Ortalama girer" koruması tersine çevrildi: En düşük | En yüksek varken de Namlu çıkış hızı giriyor.
  - "Truing PCP ortalamasını bilir, düğme kapalı" testi değişti. Yeni hâli: hız doğrulanıp yazılıyor, En düşük, En yüksek ve kayıtlı tablo korunuyor.
  - Silinen anahtara (`truing-pcp-mean`) bakan iki satır kaldırıldı.
- **`test/pcp_pressure_profile_test.dart`:** "Araç PCP'de tek hız yazmaz" testi değişti. Yeni hâli: araç Namlu çıkış hızını yazıyor, En düşük ve En yüksek korunuyor.
- **`integration_test/sim_screens_pcp_kartlar_test.dart`:**
  - Dürbün önce dolduruluyor; böylece yalnız En düşük girildiğinde Kaydet'in açık olduğu ölçülüp çekilebiliyor (yeni görüntü `pcp_tek_hiz_kaydet_390`).
  - Uyarının olmadığı da kontrol ediliyor.

**Değişmeyenler:**

- Ateşli tüfek golden sayılarına ve formül testlerine dokunulmadı.
- Eski PCP golden testi (`_oldPcpGoldenOnMain`) aynı.
- Testler gevşetilmedi. Silinen tek şey ortalama ve uyarı doğrulamaları; bu değişiklik onları bilerek kaldırıyor.

**Yerel:**

- `python3 tools/offline_dart_lint.py`: PASS, 426 dosya, 0 sorun.
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 915 test, OK (1 atlandı).
- Flutter SDK bu ortamda yok; Flutter testleri CI'da koştu.

### Ekran görüntüleri ve CI

Ekran görüntüleri (390 pt) ve CI bağlantıları PR açıklamasında. Yalnız gerçekten başarılı biten işler "başarılı" yazılır.

### Gözden geçirme (Code Review + Security)

Ayrı bir inceleme ajanı diff'i okudu. Kalan hiçbir hesap yolu En düşük ya da En yüksek okumuyor. Kayıt ve yükleme tek değerle doğru çalışıyor. Güvenlik açısından yeni bir sorun yok: bozuk JSON eskisi kadar sıkı reddediliyor.

Bulgular:

- ⓘ metni ile hesap arasındaki fark (yukarıda); sahip kararı.
- Eski sürüme dönüş (yukarıda).
- Eskimiş üç kod yorumu vardı; düzeltildi.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
