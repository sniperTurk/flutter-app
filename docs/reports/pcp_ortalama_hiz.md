# PCP hız: En düşük | En yüksek girilirse ortalamayla hesap

Dal: `feat/pcp-ortalama-hiz` · Draft PR #388 · birleştirilmedi, TestFlight başlatılmadı.

## Ne
- **PCP, ikisi de girili ve geçerli:** her hesap En düşük ile En yüksek namlu çıkış hızının ortalamasını kullanır. Örnek: 830 ve 860 fps girilirse hesap 845 fps ile yapılır. Hesap yolları: Hedef, DOPE kartı/PDF, Pro (bugünkü hız satırı), Hız Doğrulama, MPBR.
- **İkisi de boş:** hesap Tüfek kartındaki Namlu çıkış hızıyla yapılır.
- **Yalnız biri girili:** boş kutunun altında "En düşük ve en yüksek hızın ikisini de girin." yazar. Kaydet kapanır ve kutu "Kaydetmek için eksik" satırında listelenir.
- **Ters girilmiş (En düşük > En yüksek):** En yüksek kutusunun altında "En düşük hızdan küçük olamaz." yazar ve Kaydet kapanır. Bu, #368'deki metnin aynısıdır. Kayıt katmanındaki (ProfileInput) metin "En düşük namlu çıkış hızı en yüksek hızdan büyük olamaz." olarak kalır.
- **Birim:** iki kutu da Tüfek'teki Namlu çıkış hızı gibi her zaman fps'dir (kutunun içinde sağda) ve m/s olarak kaydedilir. Geçerli aralık aynıdır: 100–4900 fps.
- **Ateşli tüfek:** değişmedi. ProfileInput bu iki değeri ateşlide düşürür, `velocityMps` de Namlu çıkış hızına eşit kalır.

## Nasıl
- #368'in "Hız şimdilik Tüfek kartından" (954701b4) değişikliği ve onun simülatör adımı (c49ebfd4) geri alındı. Böylece #368'in ilk uygulaması geri geldi:
  - `RifleProfile.velocityMps` ve `hasPcpVelocityRange`,
  - ProfileInput'ta ikisi ya da hiçbiri kuralı,
  - editörde boş kutu uyarısı ve kayıt engeli,
  - Hedef/MPBR/Hız Doğrulama'nın `velocityMps` okuması.
- Ardından bugünkü main'e göre üç düzeltme yapıldı:
  - `pro_ayarlar_view.dart`: "Bugünkü hız" satırı da `velocityMps` okur.
  - `profile_codec.dart`: 17.10 sürümünde yalnız bir hızla kaydedilmiş profiller açılmaya devam eder. Kayıtlı veri silinmez.
  - `tool_support.dart`: tek değerli eski bir profilde araçlar (Kronograf, Hız Doğrulama) çalışmaya devam eder ve o değeri olduğu gibi taşır.
- Araçlar: ikisi girili bir PCP'de Kronograf ya da Hız Doğrulama'dan tek bir hızı "profile uygula", Tüfek kartına yazılacağı için hiçbir şeyi değiştirmez. Bu yazım reddedilir ve #368'deki mevcut hata metni gösterilir: "PCP'de hesap, Profil > Mühimmat'taki en düşük ve en yüksek hızın ortalamasıyla yapılıyor; buradan tek bir hız yazılmaz." Ret onay penceresinden ÖNCE olur (Code Review bulgusu, 4e530dcc).

## Neden
- Sahibin 16.10.2026 20:56 kararı: "En düşük / En yüksek zorunlu alan olmayacak; bu değerler girilmezse Tüfek girişteki namlu çıkış hızı ile hesaplama yapılacak."
- 17.10 13:15: "Testleri arka planda yapacaksın, sanki yeni özellik ekliyor gibi; testler başarılı olunca yükleyeceksin."
- 17.10 17:44: "yap".

## Uç durumlar
- **Eski PCP profili (basınç tablosu olan, iki hız yok):** Tüfek'teki Namlu çıkış hızıyla hesaplanır. Tablo silinmez, okunmaz da.
- **17.10 sürümünde yalnız biri girilmiş kayıtlı profil:** açılır ve Tüfek hızıyla hesaplanır. Düzenle açılınca boş kutuda uyarı çıkar; ikincisi girilmeden Güncelle kapalıdır.
- **Bozuk ya da elle değiştirilmiş kayıt:** ters çift bozuk kayıt sayılır (eskisi gibi). NaN, sonsuz, 0 ya da aşırı büyük değer kabul edilmez.
- **İkisi eşit (ör. 845/845):** ortalama 845'tir.
- **Platform PCP'den ateşliye çevrilirse:** iki hız kaydedilmez.

## Bilerek yapılmayan
- Hiçbir ⓘ metni, etiket, kutu yeri ya da birim yeri değişmedi. `profile_field_info.dart`'ta yalnız bir kod yorumu değişti.
- #368'in ilk halindeki Hız Doğrulama düzeni geri getirilmedi: ortalama notu, kapalı "uygula" düğmesi ve onun ⓘ'si (yeni düzen istenmedi). Düğme main'deki gibi durur; basınca yukarıdaki hata metni çıkar.
- Profil listesi ve profil özeti Tüfek kartının kendi "Namlu çıkış hızı" değerini göstermeye devam eder. Bu, o alanın değeridir; hesap hızı değildir.
- 320 pt Profili Düzenle'de Ağırlık "21.14" (nokta) görünür, 390 pt yeni profilde "21,14" (virgül). Bu fark main'de de var; bu işin kapsamı dışında, dokunulmadı.

## Testler
- **Eklenen ya da genişletilen:**
  - `test/pcp_muhimmat_tasarim_test.dart`:
    - 830/860 (Tüfek 950) → Hedef `requiredUp`, Tüfek'i 845 olan profille aynı (1e-9 içinde).
    - İkisi boş → Tüfek 950.
    - Yalnız 830 → Tüfek 950.
    - Yalnız biri → uyarı ve "Kaydetmek için eksik".
    - Ters → hata.
    - Kaydet/aç gidiş-dönüş, codec.
    - Hız Doğrulama 845'i gösterir ve yazmaz.
    - **Yeni:** 320 pt × 1.3 ve 390 pt'de uyarı ve ters hata metni taşmaz, satır sırası korunur.
  - `test/chrono_screen_test.dart` (yeni): ikisi girili PCP'de Kronograf onay sormadan reddeder, profil değişmez.
  - `test/audit_2026_10_17e/pcp_ortalama_hiz_audit_test.dart` (yeni denetim testi): aşağıdaki denetim bölümüne bakın.
- **Kural tersine döndüğü için güncellenen (zayıflatılmadı, beklenen değer değişti):**
  - `test/audit_2026_10_14b/turret_zero_cleanup_audit_test.dart` (KUL-2): ortalama 255 m/s → 837 fps gösterilir, yazım reddedilir.
  - `test/audit_2026_10_15c/kul10_pcp_hiz_test.dart`: Hedef hızı 255 m/s artık ortalamadan gelir.
  - `test/pcp_pressure_profile_test.dart`: araç tek hız yazmaz, diğer güncellemeler çifti korur.
- **Ateşli golden sayıları:** dokunulmadı; tüm suite geçti.
- **Silinen test:** yok.
- **Yerel:**
  - `python3 tools/offline_dart_lint.py`: PASS (434 Dart dosyası, 0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'`: 915 test, OK (1 skip).

## Ekran görüntüleri (simülatör, iPhone 16e, 390 pt; sim-screens run 39042886554, commit 972aca78)
- **PCP Mühimmat, ikisi dolu (830 | 860):** [05_pcp_muhimmat_390.png](pcp_ortalama_hiz/05_pcp_muhimmat_390.png).
- **PCP Mühimmat, yalnız En düşük 830:**
  - [04_pcp_muhimmat_tek_hiz_390_alt.png](pcp_ortalama_hiz/04_pcp_muhimmat_tek_hiz_390_alt.png): kırmızı çerçeve, "En düşük ve en yüksek hızın ikisini de girin.", "Kaydetmek için eksik: … Mühimmat: En yüksek namlu çıkış hızı", Kaydet kapalı.
  - [03 (üst kısım)](pcp_ortalama_hiz/03_pcp_muhimmat_tek_hiz_390.png).
- **Hedef, 830/860 kayıtlı (Tüfek 950):**
  - [14_hedef_390.png](pcp_ortalama_hiz/14_hedef_390.png): 100 m'de "Üst kule 84 klik yukarı".
  - [16_hedef_390_3.png](pcp_ortalama_hiz/16_hedef_390_3.png): Uçuş süresi 0,471 s, Düşüş 61,0 cm, Hız 178 m/s, Namlu Mach 0,756.
- **320 pt, Profili Düzenle (kaydet → aç):** [19](pcp_ortalama_hiz/19_pcp_muhimmat_320.png), [20](pcp_ortalama_hiz/20_pcp_muhimmat_320_alt.png): 830 ve 860 geri geldi, taşma yok.

Not: c49ebfd4'ün geri alınmasıyla Dürbün seçimi yine 830/860'tan sonra yapılır. Bu yüzden ekranda "Kaydetmek için eksik" Dürbün'ü de sayar. Bu yalnız çekim sırasıdır.

## Denetim (TestFlight öncesi uçtan uca hesap denetimi, bu değişiklik)

**YÜKSEK bulgu: yok**

- **Referanslar, uygulamanın Dart kodundan bağımsız:**
  - Ortalama elle hesaplandı.
  - Düzeltmeler `tools/formula_reference.py` ile hesaplandı: CIPM-2007 hava, PCHIP sürüklenme tablosu, Dormand–Prince entegratörü; yayımlanmış formüllerden yazılmıştır.
  - Başka balistik uygulama kullanılmadı.

| # | Girdi | Elle hesap | Kullanılan hız | Ekranda / uygulamada | Bağımsız referans | Sonuç |
|---|---|---|---|---|---|---|
| A | Tüfek 950, En düşük 830, En yüksek 860 fps; H&N Baracuda Match 21,14 gr, G1 0,039, sıfır 30 m, 50 mm, 100 m | (830 + 860) / 2 = 1690 / 2 = **845 fps** = 257,56 m/s | 845 fps | Hedef (simülatör): 84 klik (¼ MOA) = 21 MOA, 61,0 cm; Hız 178 m/s; 0,471 s; Mach 0,756 | 845 fps, 15 °C / 1013,25 hPa / %50: 20,95 MOA → 84 klik; 178,6 m/s; 0,471 s; Mach 0,756. (950 fps olsaydı 66 klik, Mach 0,85) | Uyuşuyor |
| B | Tüfek 950, iki kutu boş; 18 gr, G1 0,031, sıfır 30 m, 50 mm | ortalama yok → **950 fps** | 950 fps | Çözücü (denetim testi): 50 m / 100 m düzeltmesi | 0,9054 / 5,3710 mrad | Uyuşuyor (tolerans max(0,03 mrad, %0,5)) |
| C | Tüfek 950, yalnız En düşük 830 | kayıt engellenir; eski tek değerli kayıt → **950 fps** | 950 fps | Kaydet kapalı, uyarı metni; yüklenen eski kayıt 950 fps ile çözülür | 0,9054 / 5,3710 mrad | Uyuşuyor |

A durumunun çözücü düzeyi de testte ölçüldü: 18 gr G1 0,031, 845 fps → 1,2517 / 6,7532 mrad. Test: `test/audit_2026_10_17e/pcp_ortalama_hiz_audit_test.dart`.

- **Gizli bayrak yolları:** yok. Hız seçimi tek bir getter'da (`RifleProfile.velocityMps`). Basınç tablosu ve Tüp/Regülatör basıncı formüle girmez; testle ölçüldü.
- **Etkileşimler:** boş alan, varsayılan değer ve yer değiştiren alan kontrol edildi:
  - Hedef'in başlangıç hızı `velocityMps`'tir.
  - Barut sıcaklığı yalnız ateşlide uygulanır; PCP'de bugünkü hız = ortalama.
  - Ana sayfa anahtarı iki hızı da izler, değişince Hedef yenilenir.

| Bulgu | Önem | Durum |
|---|---|---|
| D1. Hız Doğrulama/Kronograf "Profile uygula" ikisi girili PCP'de önce onay soruyor, sonra reddediyordu | ORTA | Düzeltildi (4e530dcc), testli |
| D2. Profil özeti/listesi Tüfek kartının hızını gösteriyor, hesap ortalamayı kullanıyor | DÜŞÜK (bilgi) | Değiştirilmedi (düzen değişikliği istenmedi); sahip isterse ayrı görev |
| D3. Hedef ekranında hız yalnız Mach/menzil hızıyla görünür, "845 fps" yazan bir satır yok (Hız Doğrulama ve DOPE/PDF "Hız: 845 fps" gösterir) | DÜŞÜK (bilgi) | Değiştirilmedi |

## Code Review ve Security review
- **PR yorumu:** https://github.com/sniperTurk/flutter-app/pull/388#issuecomment-6235525569
- **Code Review:** 1 bulgu (D1), düzeltildi.
- **Security review:** yüksek ya da orta bulgu yok.

## CI
- **iOS CI** (PR, kod commit'i 4e530dcc), run https://github.com/sniperTurk/flutter-app/actions/runs/39043793709:
  - 1. deneme:
    - `dart-checks`: success.
    - `wind-acceptance`: success.
    - `verify`: **failure**, https://github.com/sniperTurk/flutter-app/actions/runs/39043793709/job/117431461837. Uygulama derlendi ve simülatörde açıldı (`com.sniperturk.sniperTurk: 29917`). Ama `app_launch_test` VM servisine bağlanmadan iki kez asılı kaldı ve adım 25 dakikada zaman aşımına uğradı; hiçbir test gövdesi çalışmadı. Bu, iş akışının kendi açıklamasındaki bilinen simülatör asılmasıdır; aynı uygulama sim-screens'te tam entegrasyon turunu geçti. Kurallara göre bir kez yeniden çalıştırıldı.
  - 2. deneme (yeniden çalıştırma):
    - `verify`: **success**, https://github.com/sniperTurk/flutter-app/actions/runs/39043793709/job/117438574393
    - `dart-checks`: **success**, https://github.com/sniperTurk/flutter-app/actions/runs/39043793709/job/117438594947
    - `wind-acceptance`: **success**, https://github.com/sniperTurk/flutter-app/actions/runs/39043793709/job/117438574895
- **Not:** dalın son commit'i yalnız rapor ve ekran görüntülerini (docs/) ekler. iOS CI docs değişikliğinde çalışmaz (paths-ignore); yukarıdaki sonuçlar kodun son hali olan 4e530dcc içindir.
- **test-diag (`files=test`):**
  - 4e530dcc: success, https://github.com/sniperTurk/flutter-app/actions/runs/39043844525
  - 972aca78: success, https://github.com/sniperTurk/flutter-app/actions/runs/39042882969
- **analyze-diag:**
  - 4e530dcc: success, https://github.com/sniperTurk/flutter-app/actions/runs/39043845967
  - 972aca78: success, https://github.com/sniperTurk/flutter-app/actions/runs/39042884763
- **format-fix (375209577):** success. İlk itiş biçimlendirildi (9ef0ca27); sonraki iki itişte değişiklik çıkmadı. Run'lar:
  - https://github.com/sniperTurk/flutter-app/actions/runs/39042707156
  - https://github.com/sniperTurk/flutter-app/actions/runs/39042813051
  - https://github.com/sniperTurk/flutter-app/actions/runs/39043789689
- **sim-screens:** success, https://github.com/sniperTurk/flutter-app/actions/runs/39042886554
- **Main:** 2101b3fe'de; görev süresince ilerlemedi, rebase gerekmedi.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01FjYc4m4oXoo4NtgJCCALei
