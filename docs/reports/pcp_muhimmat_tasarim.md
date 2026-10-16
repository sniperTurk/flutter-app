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

🤖 Generated with [Claude Code](https://claude.com/claude-code)
