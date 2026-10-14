# BC modeli seçimi — PCP'de seçilebilir, iki platformda ⓘ açıklama

Sahip kararları: 2026-10-14 11:35 ve 11:38 (İstanbul), Profil Oluştur/Düzenle → Mühimmat → "BC modeli".
Dal: `fix/bc-modeli-secim` (main'den; #298 "Ateşli elle mühimmat" birleşmişti, davranışı korundu). Taslak PR; birleştirme yok, TestFlight yok.

## 1. Ne yapıldı

### PCP (saçma ve slug)
- **BC modeli kutusu artık görünüyor** (Key `ammo-bc-model`). Eskiden gizliydi ve kayıtta her zaman G1 yazılıyordu.
- **Liste:** G1, G7, G2, G5, G6, G8, GI, GS, RA4. Dokuzunun da tablosu `lib/core/standard_drag_tables.dart` içinde var.
- **Varsayılan G1 seçili**, "Seçiniz" değil. Yeni PCP profilde ve model bilinmeyen her durumda G1 seçili gelir.
- **Kayıt:** seçilen model kaydedilir; zorla G1 yazan kod kaldırıldı. Kutuya dokunulmazsa G1 kaydedilir. Eski PCP profillerde G1 kayıtlı olduğu için G1 kalırlar.
- **Yerleşim:** iki kutu yan yana kuralına göre satırlar şöyle oldu:
  - Tip | Ağırlık
  - BC | BC modeli
  - Eskiden Tip tek başına bir satırdı, Ağırlık | BC yan yanaydı. BC | BC modeli yan yana gelsin diye Tip, Ağırlık'ın yanına geçti; alanlar aynı.
  - BC'nin "olağan dışı" uyarısı PCP'de BC | BC modeli satırının altına alındı, iki kutu ayrılmasın diye.
  - Gizli `PROFILE_AMMO_LENGTH` açıksa düzen: Tip tek satır, Ağırlık | Uzunluk, BC | BC modeli.
- **Boş BC (tahmini BC yolu, #255):**
  - BC boş bırakılınca tahmin her zaman G1 BC ile yapılır; bu değişmedi.
  - Kullanıcı başka bir model (ör. G7) seçip BC'yi boş bıraktıysa seçimi kayıtta saklanır ve Profil'i yeniden açınca yine G7 görünür.
  - Hesap yine G1 tahminiyle yapılır. Balistik sayfasındaki mevcut "tahmini G1 BC" notunun sonuna şu cümle eklenir: "Seçtiğiniz G7 modeli BC olmadan kullanılamaz; tahmin G1 ile yapıldı."
  - Bunun için `Ammunition`'a, çözücüye hiç girmeyen bir `modelWithoutBc` alanı eklendi.

### Ateşli tüfek
- **Davranış değişmedi.** Kutu, liste (G1, G2, G5, G6, G7, G8, GI, RA4, Özel eğri), "Seçiniz" başlangıcı, elle girilen fişekte G1/G7 ve özel eğri olduğu gibi kaldı.
- **Değişen tek şey ⓘ metni.** Aşağıdaki açıklama popup'ı geldi; özel eğri notu uyarının hemen üstündedir.

### ⓘ popup metni
İki platformda aynı; diğer Profil ⓘ'leri gibi ortada açılır ve metin sola dayalıdır:

```
G1: Düz dipli, klasik mermi. Saçma ve slug BC'leri de çoğunlukla buna göre verilir.
G7: Uzun, sivri ve konik dipli (boat-tail) mermi.
G2, G5, G6, G8, GI: Başka mermi şekilleri; az kullanılır.
GS: Küre şekli (yuvarlak bilye).
RA4: .22 LR rimfire.

Uyarı: Yanlış eğri seçmek, hiç seçmemekten daha fazla hata yaratır. Üretici BC'yi hangi modele göre veriyorsa onu seçin; bilmiyorsanız G1'de bırakın.
```

- Ateşli tüfekte uyarıdan önce bir satır daha var: "Özel eğri (Mach–Cd): merminin kendi eğrisi elinizdeyse (Lapua .drg, radar ölçümü) seçin; BC gerekmez."
- Metinler `lib/features/profiles/profile_field_info.dart` dosyasında:
  - `bcModel`: PCP metni.
  - `bcModelWithCustom`: ateşli tüfek metni.
  - `bcModelWarning`: uyarı satırı.
  - `bcModelCustom`: özel eğri notu.
  - Eski `bcModelFirearm` metni bu tek metne birleştirildi.

## 2. Seçilen model formüle giriyor mu? (sahibin açık talebi)

Seçimden hesaba kadar her adım koddan izlendi:

1. **Profil kaydı:** `bcModel` alanı `_bcModelForSave` değerinden yazılır. PCP'de bu değer seçilen model, seçim yoksa G1'dir.
2. **`UserCatalog`:** `bcModel` → `Ammunition.ballisticModel`. BC boşsa model `modelWithoutBc` alanına gider; çözücüye verilmez, çünkü BC'siz bir model hesapta kullanılamaz.
3. **`ballistics_screen.dart`:** `model = useBc ? ammo!.ballisticModel : null` → `BallisticInput(ballisticModel: model)` → `_ShotBasis.ballisticModel`.
4. **Çözücü:** `AerodynamicTrajectorySolver.solve` ve `zeroAngleRad` → `input.dragTable ?? StandardDragTables.forModel(model)`. `forModel` dokuz modelin her birini kendi tablosuna eşler; varsayılan dal yok.
5. **Hesabı yeniden kuran yollar — hepsi modeli taşıyor:**
   - `BallisticInput.withRanges`, `withMuzzleVelocity` ve `withBallisticCoefficient`.
   - `_ShotBasis.input(...)`. Atış, rüzgâr aralığı, yerçekimi etkisi, BC ölçeği ve WEZ hesapları bunun üzerinden gider.
   - `reticle_holds.dart` (2 yer) ve `wind_zone_shares.dart`.
   - `drag_band_truing.dart`:
     - `ownCurve`, seçilen modelin tablosunu kullanır.
     - `_withCurve`, çözücüye her zaman açık bir `dragTable` verir; oradaki "G1" yalnızca saklama etiketidir.
   - `mpbr_screen.dart` ve `truing_screen.dart`, `ammo.ballisticModel`'i doğrudan aktarır.
6. **Sonuç: sessiz bir G1/G7 geri düşüşü bulunmadı.**
   - Tek bilinçli G1 durumu, BC boşken tahmini BC'dir (`EstimatedBc.fill`) ve not bunu artık açıkça söylüyor.
   - `DragSafety` PCP'de G7 seçilince mevcut bilgi notunu gösterir ("Havalı silah mermileri için yayımlanan BC değerleri çoğunlukla G1…"). Bu not hesabı değiştirmez.

### Bağımsız referansla sayısal kontrol
- **Referans:** `tools/bc_modeli_referans.py`, 2026-10-14 formül denetimindeki dünya çerçeveli nokta-kütle çözücüsünü kullanır (`tools/formul_denetimi_2026_10_14.py`, McCoy denklemleri). Uygulamanın Dart kodundan ve başka bir balistik programdan bağımsızdır.
- **Atışlar:** aynı atış, aynı BC ile dokuz modelde ayrı ayrı çözüldü.
  - PCP: .25 slug, 290 m/s, BC 0,110, 3 m/s yan rüzgâr; 100 ve 150 m.
  - Ateşli: .308, 2650 fps, BC 0,462, 10 mph yan rüzgâr; 300 ve 600 m.
- **Sonuç:** uygulama her modelde referansla 0,005 mrad / 0,5 ms içinde uyuşmalı.
- **Ayırt etme:** birbirine en yakın iki model bile en uzak mesafede 0,022 mrad (PCP, G1–GI) ve 0,034 mrad (ateşli, G2–G7) farklı. Bu yüzden bir model sessizce başka bir tabloyla hesaplansaydı test geçemezdi.

## 3. Sürüklenme tablolarının değer değer kontrolü

**Sonuç: dokuz tablonun hiçbiri bağımsız birincil kaynakla karşılaştırılamadı. Durum: DOĞRULANMADI.** Hiçbir değer için "doğru" ya da "yanlış" demiyorum, çünkü karşılaştırma yapılamadı.

| Model | Dosyadaki nokta | Birincil kaynakla karşılaştırma |
|---|---|---|
| G1 | 79 | DOĞRULANMADI — erişilebilir birincil kaynak yok |
| G2 | 85 | DOĞRULANMADI |
| G5 | 76 | DOĞRULANMADI |
| G6 | 79 | DOĞRULANMADI |
| G7 | 84 | DOĞRULANMADI |
| G8 | 78 | DOĞRULANMADI |
| GI | 81 | DOĞRULANMADI |
| GS | 81 | DOĞRULANMADI |
| RA4 | 87 | DOĞRULANMADI |

**Denenenler (okuma tarihi 2026-10-14):**
- **DTIC'teki BRL raporları:** hiçbirinde standart G fonksiyonunun Mach–Cd tablosu yok; yalnızca grafik ya da tek bir merminin verisi var. İncelenenler: BRL MR 1167 (AD0209134), MR 1144 (AD0162924), Rapor 603 (AD0492607), BRL-MR-3768 (ADA209510), Rapor 620 (AD0800469), BRLH 120-1-73 (ADA955370), BRL-MR-3810 (ADA219106), MR 1833 (AD0815788), Rapor 188 (AD0702561), MR 564 "Table of Form Factors" (AD0802080; tablo hıza göre ve tarama okunmuyor), Rapor 478 (AD0491936; "the tabulated G5 drag function" diyor ama tabloyu vermiyor), Rapor 132, TN 1041, MR 2071, Rapor 1337, MR 1065, ARBRL-MR-03041, ADA556105.
- **ADA224217:** indirilemedi; izin zaman aşımı oldu.
- **HathiTrust:** "Exterior Ballistic Tables Based on Numerical Integration" (1924) açılamadı. Bu cilt G1'i hıza göre G(v) olarak verir, Mach–Cd olarak değil.
- **McCoy, "Modern Exterior Ballistics" (1999):** çevrim içi yok; telifli tarama kullanılmadı.
- **NATO STANAG 4355 ekleri:** kamuya açık değil.
- **RA4 (İngiliz 1929 yasası):** erişilebilir bir Ordnance Board belgesi bulunamadı.
- **Yasak listede olduğu için kullanılmayanlar:** JBM, Applied Ballistics, py-ballisticcalc ve benzeri hesap programları, forumlar.

**Önemli bulgu:** dosyanın kendi kaynak notu, değerlerin JBM Ballistics (`mcg1.txt`, `mcg7.txt`, `ra4.txt`) ve py-ballisticcalc'tan alındığını söylüyor. İkisi de sahibin yasak kaynak listesinde. BRL kökenli oldukları yazıyor ama birincil belgeyle gösterilmiş değil. Bu iş kapsamında tabloları değiştirmedim.

**Öneri (ayrı görev):** BRL tabloları ya da McCoy 1999 kütüphane veya ödünç yoluyla temin edilip elle aktarılabilir. Ardından şu adımlar tekrar çalıştırılabilir:
1. Dosyadaki tabloları CSV'ye döken karşılaştırma betiği oturum not alanında (scratchpad) hazır.
2. Kaynak tablolar `source_tables/<model>.csv` olarak eklenir.
3. Betik yeniden çalıştırılır.

**Dosya içi denetim (doğrulama sayılmaz):**
- Dokuz tabloda da Mach değerleri düzgün artıyor.
- G1'de Mach 0,65 noktası yok (0,60'tan 0,70'e atlıyor).
- G7'de Mach 1,45 noktası yok.

## 4. Uç durumlar
- **Eski PCP profiller:** G1 kayıtlı; açılınca G1 seçili, hesap aynı.
- **Eski PCP profil, BC boş:**
  - Önceden model `null` okunuyordu.
  - Şimdi kayıttaki `bcModel` (G1) `modelWithoutBc` olarak okunuyor; kutuda G1 görünür.
  - Hesap yine tahmini G1.
- **Listeden seçilen ürünler:** kütüphanedeki 518 PCP kaydının hepsi G1; seçilince G1 gelir. Listede G7 ile verilen PCP ürünü yok. Ateşli tüfekte G7'li ürünler (ör. Hornady ELD Match) eskisi gibi G7 gelir.
- **Özel eğri:**
  - Ateşli tüfekte değişmedi.
  - PCP listesinde "Özel eğri" seçeneği yok. Ancak kayıtlı bir PCP eğrisi varsa kaybolmasın diye "Özel eğri (kayıtlı)" olarak listede gösterilir.
- **Boş PCP BC:** tahmin her zaman G1. G1 dışında bir model seçildiyse not bunu söyler.
- **BC olağan dışı uyarısı:** yalnızca G1 ve G7 için aralık tanımlı.
  - Ateşli: G1 ve G7.
  - PCP: yalnızca G1. PCP'de G7 ve diğer modellerde bu uyarı çıkmaz.
  - Değişmedi; yeni modeller için üreticiden gelen bir aralık yok.
- **Gizli `PCP_AMMO_BRAND` bayrağı açılırsa:** Marka | Tip ve Model satırlarından sonra Ağırlık | BC yan yana kalır, BC modeli tek başına bir satıra düşer. Bayrak kapalı olduğu için kullanıcı bunu görmez; açılırsa düzenin elden geçirilmesi gerekir.

## 5. Yapılmayanlar
- Tablo değerleri değiştirilmedi (bkz. 3).
- MPBR ve Hız Doğrulama ekranları BC'si boş PCP mühimmatta tahmini BC kullanmıyor. Bu konu bu işten önce de böyleydi ve kapsam dışı; yalnızca not ediyorum.
- Diğer Profil alanlarına ve diğer sayfalara dokunulmadı.

## 6. Testler
- **Yeni dosya `test/bc_modeli_secim_test.dart`:**
  - 18 referans testi: 9 model × 2 atış, uygulama ile bağımsız referans karşılaştırılıyor.
  - "Model değişince sonuç değişir" testi: her model çifti için en uzak mesafede fark 0,015 mrad'dan büyük olmalı.
  - Her modelin kendi tablosu olduğu; `withRanges`, `withMuzzleVelocity` ve `withBallisticCoefficient` kopyalarının modeli koruduğu; Cd eğrisi düzeltmesinin seçilen modelden başladığı.
  - PCP:
    - Kutu görünür, G1 seçili ve dokuz seçenek var.
    - BC | BC modeli ile Tip | Ağırlık yan yana.
    - ⓘ ortada açılır, sola dayalıdır, satır satır beklenen metin çıkar ve uyarı en sondadır.
    - G7 kaydedilir, yeniden açılır ve hesapta kullanılır.
    - Kutuya dokunmayınca G1 kaydedilir.
    - BC boş + G7 seçilince seçim saklanır, tahmin G1 ile yapılır ve not bunu söyler.
    - Eski G1 profil G1 kalır.
  - Ateşli: seçenekler ve "Seçiniz" başlangıcı aynı, ⓘ yeni metin.
  - Balistik: G1 ve G7 farklı DOPE verir; not metinleri doğru.
- **Güncellenen testler (PCP'de kutu artık görünüyor):**
  - `test/atesli_elle_muhimmat_test.dart`
  - `test/profile_editor_fail_closed_test.dart` (ⓘ listesine "BC modeli" eklendi)
  - `test/profile_lists_test.dart` (PCP satır düzeni)
  - `test/support/rifle_form.dart` (açıklama)
- **Yerelde çalıştırılanlar:**
  - `python3 tools/offline_dart_lint.py` → GEÇTİ (0 sorun).
  - `python3 -m unittest discover -s tools -p 'test_*.py'` → 740 test GEÇTİ.
- **Flutter testleri ve analyzer:** yerelde Flutter SDK yok; yalnızca CI'da çalıştı (bkz. 7).

## 7. CI
Hepsi `fix/bc-modeli-secim` dalında, `aba9a6b` commit'i üzerinde çalıştı:
- **Dart format:** https://github.com/sniperTurk/flutter-app/actions/runs/38564776350 — başarılı. Biçim düzeltmesini `aba9a6b` olarak commit'ledi; yalnızca yeni test dosyasında değişiklik vardı.
- **`flutter analyze --fatal-infos --fatal-warnings`:** https://github.com/sniperTurk/flutter-app/actions/runs/38564988121 — YEŞİL.
- **`flutter test test` (tüm test klasörü):** https://github.com/sniperTurk/flutter-app/actions/runs/38564984744 — YEŞİL.
- **iOS CI / Simulator / TestFlight:** bu işte çalıştırılmadı; sonuç bildirmiyorum.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)
