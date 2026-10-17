# Dürbün girişi: liste sırası, tam listeler, 8 satırlık açılır liste

Dal: `fix/durbun-girisi-tasarim` · Taslak PR #367 · Birleştirme yok, TestFlight yok.

## 2. tur — sahip kararları 16.10.2026 22:14–22:49 (İstanbul)

### Ne yapıldı

**A) Listeden seçim yolu** (Marka → Birim | Odak düzlemi → Tüp | Büyütme → Model → Üst kule | Dürbün ayağı → Retikül) onaylı haliyle kaldı. Seçilen filtre değeri (MOA, FFP) normal yazı renginde; "Seçiniz" gri. Widget testi rengi ölçüyor; Simulator görüntüsü aşağıda.

**B) Elle giriş ("Aradığın dürbün listede yok mu?")** yeni sırada, her satırda iki kutu:

1. Dürbün markası | Dürbün modeli
2. Dürbün birimi | Odak düzlemi
3. Minimum büyütme | Maksimum büyütme
4. Mercek çapı | Klik değeri
5. Üst kule klik sayısı | Dürbün ayağı
6. Retikül
7. "Dürbün: …" satırı, sonra "Listeden seç"

"Kaydetmek için eksik" de bu sırayla yazıyor. "Maksimum büyütme" 390 pt'de artık tek satır; ad değişmedi (aşağıda "Nasıl").

**C) Listeler tamamlandı** (yalnız uygulamanın üretici kaynaklı dürbün kataloğundan; web'e çıkılmadı):

- **Minimum büyütme** 37 değer. Yeni eklenenler: 0,75 · 1,1 · 1,2 · 1,6 · 1,7 · 1,75 · 1,8 · 2,3 · 2,4 · 2,75 · 2,8 · 2,9 · 3,3 · 3,6 · 4,8 · 6,25 · 6,5 · 12,5 · 14 · 15 · 36 · 45.
- **Maksimum büyütme** 44 değer. Yeni eklenenler: 1 · 2,75 · 3 · 4,5 · 5,5 · 6,5 · 12,8 · 13,3 · 13,5 · 22 · 26 · 29 · 34 · 55 · 64.
- **Mercek çapı** 27 değer. Yeni eklenenler: 15 · 16 · 18 · 22 · 26 · 35 · 48 mm.
- Üç liste de kodda tek kaynaktan kuruluyor: eski değerler + katalogdaki her değer, küçükten büyüğe, her biri bir kez. Kataloğa yeni bir dürbün eklenince değeri listeye kendiliğinden gelir. Ondalık virgülle yazılıyor (2,75x).
- **Retikül (elle giriş)**: katalogdaki her retikül adı (yaklaşık 650 ad). Ad bir kez yazılıyor; harf büyüklüğü farklı iki yazım tek ad sayılıyor. Önce 5 genel desen geliyor, sonra adlar A–Z.
  - Dürbün birimi seçilince liste süzülüyor. Adı birimini söylüyorsa ("… MOA", "… MIL", "-MRAD") ona göre süzülüyor. Söylemiyorsa katalogda o adı taşıyan dürbünlerin birimine bakılıyor; hepsi aynı birimdeyse ona göre süzülüyor. Birimi bilinmeyen ad her iki birimde de kalıyor.
  - Genel desenler eskisi gibi birime göre listede kalıyor.
  - Birim seçilmeden her şey listeleniyor.
  - Seçili retikül birim değişince silinmiyor (14.10 kuralı).
- **Dürbün ayağı**: yalnız MOA. 0–60 arası 5'er MOA, ayrıca bugünkü 90. Yeni eklenenler: 5 · 25 · 35 · 50 · 55. MRAD ayak eklenmedi. Kayıt denetimi (ProfileInput, profil okuma) aynı listeyi kullanıyor.
- **Klik değeri** değerleri değişmedi.

**Retikülün Hedef'te çizimi (eşleme):**

- Katalog dürbünü (listeden seçilen): değişmedi. Markasının üretici çizimi varsa o, yoksa genel desen.
- Elle girilen dürbün:
  - Seçilen adın üretici çizimi varsa o çizim kullanılıyor. Çizim, katalogda o adı taşıyan dürbünler üzerinden aranıyor ve hepsi aynı tek çizime çıkıyorsa kullanılıyor.
  - Adın çizimi yoksa ya da çizim belirsizse (iki farklı çizime çıkıyorsa), dürbün biriminin genel deseni kullanılıyor (`Reticles.forName`):
    - adında MIL-DOT geçerse Mil-Dot,
    - DUPLEX/HUNT/VFD geçerse Duplex,
    - MIL birimde VPR/TOR/PRS/TREE/H59/APR geçerse Christmas tree (MIL),
    - aksi halde birime göre MIL çizgili ya da MOA çizgili.
  - Yazılan markası bir katalog markasıysa, o markanın kendi sonucu korunuyor; başka bir üreticinin çizimi kullanılmıyor.
  - Her durumda kaydedilen ve gösterilen ad, seçilen addır.

**D) Açılır listeler (bütün uygulamada, tek yerde: `MenzilSelect`):**

- Liste en fazla **8 satır** yüksekliğinde açılıyor. Uzun liste içinde kayıyor; kaydırma çubuğu sürekli görünüyor.
- Kısa liste yalnız satırları kadar yüksek (Odak düzlemi: 3 satır).
- Seçili değer, liste açılınca görünür yerde duruyor. Seçim aşağıdaysa 4. satır civarına geliyor.
- Küçük ekranda 8 satır kutu ile ekran/klavye kenarı arasına sığmazsa, sığan kadar tam satır gösteriliyor.
- Liste kutudan geniş değil (kural aynı).

**E) Yeni profilde her kutu "Seçiniz":**

- Dürbün kartındaki her açılır kutu "Seçiniz" ile başlıyor; her listenin ilk satırı "Seçiniz". Bu, iki yolda da Marka, filtreler, Model, Dürbün birimi, Odak düzlemi, büyütmeler, Mercek çapı, Klik değeri, Dürbün ayağı ve Retikül için geçerli.
- Klik değeri artık yeni profilde gizli bir 0,1 MRAD ile başlamıyor.
- Üst kule klik sayısı boş başlıyor.
- "Seçiniz" satırına dönmek kutuyu yeniden boşaltıyor.
- Elle girişte "Kaydetmek için eksik" boş her zorunlu kutuyu sırayla adlandırıyor: Marka, Dürbün modeli, Dürbün birimi, Odak düzlemi, Min. büyütme, Maks. büyütme, Mercek çapı, Klik değeri, Dürbün ayağı.
- Profili Düzenle kayıtlı değerleri gösteriyor.

### Nasıl

- `lib/features/profiles/profile_editor.dart`:
  - `_minMagOptions`, `_maxMagOptions` ve `_objectiveOptions` eski sabit değerler ile katalog değerlerinin birleşimi (`_withCatalog`). Katalog = `CatalogRepository.scopes` içindeki kullanıcıya ait olmayan kayıtlar.
  - `_catalogReticles` ve `_typedReticleNames` elle girişin retikül listesini kuruyor.
  - Yeni profilde `scopeClick` boş başlıyor.
  - Eski elle giriş kaydında listede olmayan büyütme, mercek çapı ya da klik değeri açılışta boşaltılıyor. Klik boşaltılırsa, o klikle sayılmış Üst kule klik sayısı da boşaltılıyor; yoksa yeni klikle başka bir kule boyu kaydedilirdi (Code Review bulgusu).
  - "Kaydetmek için eksik" kartın sırasına göre dizildi.
  - Minimum büyütme alt sınırı listedeki en küçük değer (0,75).
- `lib/features/profiles/profile_editor_scope.dart`:
  - Kart yeni sırada.
  - Her açılır kutu `hint: 'Seçiniz'` ve başında boş değerli bir "Seçiniz" satırı taşıyor.
  - Dürbün birimi, Odak düzlemi, Dürbün ayağı ve Retikül ayrı küçük yöntemlere taşındı.
  - Birim "Seçiniz"e dönerse Klik değeri temizleniyor.
  - Model "Seçiniz"e dönerse kayıt ve retikül temizleniyor.
  - Eski `_genericFitsUnit` silindi; yerini `_typedReticleNames` aldı.
- `lib/core/production_limits.dart`: `mountCantOptionsMoa` = 0, 5, …, 60, 90.
- `lib/ui/menzil_widgets.dart`:
  - `MenzilSelect.menuRows = 8` ve `menuHeightFor`. Eski 300 pt üst sınır (`menuMaxHeight`) silindi.
  - Açılan listeye `selectedIndex` gidiyor. Satır boyu sabitse kaydırma hesapla ayarlanıyor; satır boyu değişkense (Model listesi) ilk kareden sonra `ensureVisible` kullanılıyor.
  - Kaydırma çubuğu `thumbVisibility: true`.
  - Kendi "Seçiniz" satırı olan listede kapalı kutu bu yazıyı bir kez gösteriyor; ipucu kopyası yok.
  - Etiket satırı (`_LabelWithInfo`) artık Row değil, Stack. ⓘ'nin yeri ve 48 pt dokunma alanı aynı. Etiket, ⓘ düğmesinin boş sol kısmının altına uzanabiliyor; yalnız ikon ve önündeki 4 pt boş kalıyor. Bu, bütün uygulamada etiketlere yaklaşık 15 pt yer açıyor. Hiçbir etiket adı değişmedi.
- `lib/data/reticle_catalog.dart`: `forScope(typed: true)` ve `_ofCatalogScopes` (sonucu önbellekte tutuluyor). `ballistics_screen.dart` elle girilen dürbün için `typed: scope.userEntered` veriyor.
- `.github/workflows/sim-screens.yml`:
  - İsteğe bağlı `device` girişi eklendi (ör. "iPhone 16e", 390 pt). Boş bırakılırsa eskisi gibi en yeni Pro seçiliyor.
  - Cihaz yoksa en yeni iOS sürümünde oluşturuluyor.
  - Girdi kabuğa yalnız `env` ile ve tırnak içinde gidiyor.
- Serena bu oturumda **yoktu**. Listelerin her kullanımı `grep` ile bulundu:
  - `mountCantOptionsMoa`: `profile_editor_scope.dart`, `profile_input.dart`, `profile_codec.dart`, `scope_dial_view.dart` ve test referans kopyası `test/app_store_reference`. Referans kopyası değiştirilmedi; App Store yapı 59'un dondurulmuş kopyası.
  - `_minMagOptions`, `_maxMagOptions`, `_objectiveOptions`: yalnız `profile_editor*.dart`.
  - `menuMaxHeight`: yalnız `menzil_widgets.dart`.

### Neden

Sahip elle girişte aradığı büyütme, mercek ve retikül değerlerini bulamıyordu. Açılır listeler de farklı boylarda açılıyordu. Kararlar 22:14–22:49 arası verildi.

### Uç durumlar

- **Eski kayıtlar (sahip istisnası 22:24):**
  - Elle girilmiş eski bir dürbünün büyütme, mercek çapı ya da klik değeri listede yoksa, o kutu "Seçiniz" açılıyor. Kutu zorunlu olduğundan Güncelle kapalı kalıyor ve eksik listesinde adı yazıyor.
  - Göç kodu yok. Kayıtlı profil, kullanıcı yeniden seçip kaydedene kadar değişmiyor; hesap o profil için eskisi gibi kayıtlı değerle yapılıyor.
  - Retikül bu kurala girmiyor: kayıtlı retikül her zaman listede ve seçili kalıyor (14.10 kuralı).
  - Katalog (liste) dürbünlerinin değerleri gizli ve kayıttan geliyor; onlara dokunulmadı.
- **Kule önerisi:** Hedef'teki "listeden: … MOA" önerisi artık 5 MOA adımlı listeden seçiliyor. Örneğin 22 MOA gerekirse eskiden 30, şimdi 25 MOA öneriliyor. Bu sahibin listesinin doğal sonucu; hesap sayısı değişmedi.
- **Uzun retikül listesi:** yaklaşık 650 ad. Liste kaydırılıyor; birim seçilince yaklaşık yarıya iniyor.
- **Değişken boylu satırlar:** satırı iki satıra sarılabilen listelerde (Model), seçim çok aşağıdaysa ilk açılışta görünmeyebilir. Seçili satır henüz çizilmemişse `ensureVisible` çalışamıyor. Model listesi markaya göre süzüldüğü için kısa; pratikte görülmedi.
- **Dar ekran ve büyük yazı:** 320 pt ve yazı ölçeği 1,3'te kart tek sütun oluyor. Taşma yok, liste kutudan geniş değil (testte).

### Bilerek yapılmayan

- Hesap değişikliği yok. Aynı değerlerle sonuçlar aynı; çözücü dosyalarına dokunulmadı.
- MRAD dürbün ayağı eklenmedi (sahip, 22:49).
- Klik değeri listesi değişmedi.
- Web araştırması yapılmadı; hiçbir siteye girilmedi.
- Eski rapor `docs/reports/liste_genislik.md` 300 pt'lik liste yüksekliğinden söz ediyor. O dönemin raporu olduğu için değiştirilmedi.
- Retikül zorunlu yapılmadı; hesap onu kullanmıyor.

### Testler

Yeni test dosyası `test/durbun_listeleri_test.dart`, gerçek Profil ekranında çalışıyor:

- **Listeler:**
  - Minimum büyütme, Maksimum büyütme ve Mercek çapı listesi gerçekten kaydırılarak sonuna kadar okunuyor. Katalogdaki her değer listede; liste sıralı, her değer bir kez, eski değerler de duruyor.
  - 0,75x, 2,75x, 12,8x ve 15 mm seçilip saklanıyor.
- **Retikül:**
  - Katalogdaki her ad listede, her biri bir kez.
  - MRAD seçilince adı MOA diyenler yok, MIL diyenler var; MOA'da tersi.
  - Son ad liste içinde kaydırılarak seçiliyor; APR-2D MOA da seçiliyor.
- **Dürbün ayağı:** liste "Seçiniz" + 0–60/5 + 90. MRAD yok. 25 MOA seçiliyor ve kutuda "25 MOA" yazıyor.
- **Açılır liste, 390×844:**
  - Uzun listede tam 8 satır görünüyor; yükseklik 8 satır + boşluk.
  - Kaydırma çubuğu açık, liste kutudan geniş değil, kutunun altında ve ekranda.
  - Odak düzlemi listesi 3 satır, kaymıyor.
- **Seçili satır:** 55x ve 1x seçiliyken liste açılınca seçili satır görünür satırların arasında.
- **Küçük ekran:** 390×500'de tam satırlar ve ekran içinde.
- **320 pt × 1,3:** Minimum büyütme, Retikül ve Dürbün ayağı listeleri açılıyor; taşma yok.
- **Yeni profil:**
  - Liste yolunda 8 kutu, elle girişte 8 kutu "Seçiniz" gösteriyor; her listenin ilk satırı "Seçiniz".
  - "Seçiniz" gri; seçilen MOA/FFP normal yazı renginde.
  - Eksik listesi sırası tam metinle sınanıyor.
- **Etiketler:** iPhone yazısı yerine paketteki Inter yükleniyor. 390 pt'de 10 etiket tek satır ("Maksimum büyütme" dahil). ⓘ eski yerinde (kutunun sağından 24 pt); etiket ikonun altına girmiyor.
- **Eski kayıt (uçtan uca):** profil önce ekrandan kaydediliyor. Sonra dürbün kaydı eski bir sürümün yazacağı gibi 1,3x ve 0,2 MRAD klik ile değiştiriliyor.
  - Profili Düzenle'de Minimum büyütme ve Klik değeri "Seçiniz"; Üst kule klik sayısı boş; diğer değerler ve retikül duruyor.
  - Güncelle kapalı. Yeniden seçilince kaydediliyor (1x, 0,1 MRAD).
- **Hedef çizimi:**
  - Çizimi olan bir katalog adı, elle girilen "Benim Optik" dürbününde o çizimle ve kendi adıyla çiziliyor.
  - Çizimi olmayan ad MRAD'da MIL, MOA'da MOA genel desenle çiziliyor.

Güncellenen testler (beklentiler yeni sahip kararlarına göre; hiçbiri silinmedi ya da atlanmadı):

- `durbun_girisi_tasarim_test.dart`: elle giriş satır sırası (±0,5 pt) yeni düzende. Model listesinin ilk satırı "Seçiniz".
- `profil_duzen_koruma_test.dart`:
  - `_scopeTypedLayout` yeni sırada.
  - Retikül grubunda genel desenler eskisi gibi tam liste olarak sınanıyor (5 / MRAD 4 / MOA 2). Seçili retikülün birimle silinmediği de sınanıyor.
  - Listenin "Seçiniz" ile başladığı ek olarak sınanıyor.
- `profile_lists_test.dart`: yan yana çiftler Dürbün birimi | Odak düzlemi ve Mercek çapı | Klik değeri.
- `scope_mount_cant_test.dart`:
  - Ayak listesi 0–60/5 + 90. 25 ve 55 artık geçerli. Geçersiz örnek 25 yerine 27; 27 hâlâ reddediliyor.
  - Yeni profilde klik değeri olmadığından, tıklama kazancı 0,1 MRAD seçilen bir elle girişte sınanıyor.
- `temiz_tasarim_profil_test.dart`: Model listesinde 0. satır "Seçiniz", ilk model 1. satır.
- `test/support/rifle_form.dart` (`chooseInSelect`): liste seçili satırda açıldığı için aranan satır yoksa liste önce başa alınıyor; aşağı arama 20 yerine 60 adım.

Yerel:

- `python3 tools/offline_dart_lint.py`: PASS (412 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'`: OK (915 test, 1 atlanan; main'de de atlanıyor)
- Flutter SDK bu ortama indirilemedi (indirme sunucusu engelli). Flutter testleri yalnız CI'da koştu.

### Ekran görüntüleri

Simulator turu `integration_test/sim_screens_durbun_test.dart`, `sim-screens` iş akışı, [run 38968499423](https://github.com/sniperTurk/flutter-app/actions/runs/38968499423). Çıkış kodu 0; her adım geçti.

- Cihaz: **iPhone 16e / iOS 26.2**. Ekran 1170 px = **390 pt**.
  - Bunun için iş akışına isteğe bağlı `device` girişi eklendi; boş bırakılınca eski davranış sürüyor.
  - İlk denemem ([run 38963978029](https://github.com/sniperTurk/flutter-app/actions/runs/38963978029)), başka bir oturumun kuyruğa aldığı tur yüzünden iptal oldu; ikinci deneme çalıştı.
- Uygulama kodu: `e79f9ce`. Bu son kod commit'i; bu rapor yalnız belge.
- Görüntüler `ci/sim-screens` dalında `6240197` commit'inde.

**Elle giriş**

- [01](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/01_durbun_elle_bos.png?raw=true): Boş kart, üstü. Sıra: Dürbün markası | Dürbün modeli, Dürbün birimi | Odak düzlemi, Minimum | Maksimum büyütme, Mercek çapı | Klik değeri, Üst kule klik sayısı | Dürbün ayağı.
  - Her açılır kutu "Seçiniz", yazı kutuları boş.
  - "Maksimum büyütme" tek satırda.
  - Alttaki eksik listesi kartın sırasıyla yazıyor.
- [02](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/02_durbun_elle_bos_alt.png?raw=true): Kartın altı. Retikül "Seçiniz", "Dürbün: —", "Listeden seç".
- [03](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/03_liste_minimum_buyutme.png?raw=true): Minimum büyütme açık.
  - 8 satır görünüyor: Seçiniz, 0,75x, 1x, 1,1x, 1,2x, 1,5x, 1,6x, 1,7x.
  - Sağda kaydırma çubuğu var; liste kutu genişliğinde.
- [04](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/04_liste_durbun_ayagi.png?raw=true): Dürbün ayağı açık (0,1 MRAD seçiliyken).
  - Seçiniz, Normal (0 MOA), 5 MOA · +14 klik, 10 MOA · +29, 15 · +43, 20 · +58, 25 · +72, 30 MOA · +87 klik: 8 satır.
  - Kaydırma çubuğu var; 35–60 ve 90 aşağıda.
- [05](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/05_liste_retikul.png?raw=true): Retikül açık (MRAD).
  - Seçiniz, Christmas tree (MIL), MIL çizgili, Mil-Dot, Duplex, sonra katalog adları (#43, #54, #60 …): 8 satır.
  - Kaydırma çubuğu ince; liste uzun.
- [06](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/06_durbun_elle_dolu.png?raw=true) ve [07](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/07_durbun_elle_dolu_alt.png?raw=true): Dolu hali.
  - Benim Optik | X5 Pro, MRAD | FFP, 5x | 25x, 56 mm | 0,1 MRAD, 200 | 0 MOA.
  - Retikül Mil-Dot; "Dürbün: Benim Optik X5 Pro 5-25x56 FFP".
- [08](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/08_profil_ozet_elle.png?raw=true) ve [09](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/09_profil_ozet_elle_2.png?raw=true): Kayıttan sonra Profil sayfası; dürbün bilgileri doğru.
- [10](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/10_durbun_elle_duzenle.png?raw=true) ve [11](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/11_durbun_elle_duzenle_alt.png?raw=true): Profili Düzenle; kayıtlı her değer yerinde.

**Listeden seçim**

- [12](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/12_durbun_liste_bos.png?raw=true) ve [13](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/13_durbun_liste_bos_alt.png?raw=true): Marka seçilmeden.
  - Marka, Birim, Odak düzlemi, Tüp, Büyütme, Model, Dürbün ayağı, Retikül: hepsi "Seçiniz".
  - Eksik listesi: "Dürbün: Marka, Model, Dürbün ayağı".
- [14](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/14_durbun_liste_dolu.png?raw=true) ve [15](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/15_durbun_liste_dolu_alt.png?raw=true): Element Optics; Birim **MOA**, Odak düzlemi **FFP**; Model Titan 5-25x56 FFP MOA; 360 | 0 MOA; APR-2D MOA.
  - Seçili MOA ve FFP normal yazı renginde. Pikselle ölçüldü: "Element Optics" yazısıyla aynı (231, 239, 243).
  - Seçilmeyen Tüp ve Büyütme "Seçiniz" gri (156, 177, 192).
  - Bu, 1. turdaki 11. görüntüde görülen gri sorununun düzeldiğini gösteriyor.
- [16](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/16_durbun_liste_duzenle.png?raw=true) ve [17](https://github.com/sniperTurk/flutter-app/blob/624019755f7ab4abd80e4409b5db00e2df7e9b1c/latest/17_durbun_liste_duzenle_alt.png?raw=true): Profili Düzenle. Filtreler "Seçiniz"de, Model, ayak, üst kule ve retikül korunmuş.

**Görünen farklar ve dikkat edilecekler (dürüstçe)**

- Açık liste, altındaki kutuların üstüne açılıyor (03, 04, 05). Liste kutunun altında ve kutu genişliğinde; bu daha önce de böyleydi.
- 05'te liste ekranın altındaki Kaydet çubuğunun hemen üstünde bitiyor. 8 satır sığdığı için kısaltılmadı.
- 16–17'de (Profili Düzenle, liste yolu) filtreler "Seçiniz" gösteriyor. Bu 1. turdan beri böyle: düzenlemede filtreler boş başlıyor, model korunuyor.
- Mühimmat kartında Profili Düzenle'de Ağırlık "33.95", BC "0.08" noktalı görünüyor (16–17); Profil Oluştur'da virgüllü. Bu daha önceden var olan bir durum; bu işin kapsamı dışında, dokunulmadı.
- Onaylı çizimle (Temiz Tasarım, Profil Oluştur) karşılaştırma: Liste yolunun sırası aynı. Elle girişin sırası sahibin 22:14–22:49 sözüyle aynı; onaylı çizim bu turdan önceki sıradaydı.
- 320 pt görüntüsü bu turda Simulator'da alınmadı. 320 pt ve yazı ölçeği 1,3 widget testlerinde sınanıyor.

### CI

Son kod commit'i `e79f9ce`. Bu rapor yalnız belge; iOS CI belge değişikliğinde kendiliğinden çalışmıyor, bu yüzden aşağıdaki işler elle başlatıldı.

- `iOS CI` (elle başlatıldı) [run 38968523491](https://github.com/sniperTurk/flutter-app/actions/runs/38968523491):
  - `verify` **success**. Simulator'da açılış testi, imzasız cihaz yapısı ve App Store arşivi dahil.
  - `dart-checks` **success**. Biçim, analiz, bütün birim ve widget testleri.
  - `wind-acceptance` **success**.
  - `ios-simulator` atlandı (iş akışı ayarı).
- `flutter test` bütün paket, test-diag [run 38968526756](https://github.com/sniperTurk/flutter-app/actions/runs/38968526756): **success**
- `flutter analyze`, analyze-diag [run 38968529388](https://github.com/sniperTurk/flutter-app/actions/runs/38968529388): **success**
- Biçim, format-fix [run 38964589267](https://github.com/sniperTurk/flutter-app/actions/runs/38964589267): **success**. Yalnız bir test dosyasında biçim düzeltildi ve `e79f9ce` olarak eklendi.
- Simulator turu, 390 pt, [run 38968499423](https://github.com/sniperTurk/flutter-app/actions/runs/38968499423): **success**
- PR'ın kendi iOS CI çalışmaları:
  - `70923c9` üzerindeki çalışma biçim adımında kırmızıydı; biçim düzeltmesi `e79f9ce`'de.
  - `e79f9ce`'nin PR çalışması bot commit'i olduğu için "onay bekliyor" durumunda kaldı.
  - Aynı commit yukarıdaki elle başlatılan çalışmada yeşil.
- [Code Review ve Security review](https://github.com/sniperTurk/flutter-app/pull/367#issuecomment-6225578162):
  - 3 ajan çalıştı. Gerçek 2 hata ve 1 eski yorum düzeltildi (`70923c9`).
  - Güvenlik sorunu bulunmadı.

TestFlight, gerçek cihaz, imzalama ve App Store çalıştırılmadı.

---

## 1. tur (16.10.2026 19:25–19:31) — geçmiş

Aşağıdaki bölüm ilk turun raporudur. Elle girişin satır sırası 2. turda değişti (yukarıda); geri kalanı geçerli.

Dal: `fix/durbun-girisi-tasarim` · Taslak PR · Birleştirme yok, TestFlight yok.

Sahibin sözü (16.10.2026, 19:25–19:31 İstanbul): "Dürbün girişi nasıl olacaktı? … Neden ben dürbün eklemek istediğim bu sıra ile ekleyemiyorum? … Acil şu sayfayı bağla."

### Ne yapıldı

Profil Oluştur ve Profili Düzenle → Dürbün kartı onaylı tasarımdaki sıraya getirildi (Temiz Tasarım, "Profil Oluştur", 15.10.2026).

**Listeden seçim (yukarıdan aşağı):**

1. Marka (tam satır)
2. Birim | Odak düzlemi (ⓘ ile)
3. Tüp | Büyütme (ⓘ ile)
4. Model (tam satır; markanın yalnız filtreleri geçen modelleri)
5. Üst kule klik sayısı | Dürbün ayağı (ⓘ ile)
6. Retikül (ⓘ; yalnız o modelin retikülleri)
7. "Dürbün: Marka Model …" satırı
8. "Aradığın dürbün listede yok mu?" bağlantısı

Filtreler artık Marka seçilmeden de yerinde duruyor. Marka seçilene kadar **kapalı** ve "Seçiniz" gösteriyorlar; Marka seçilince açılıyorlar. Filtre mantığı aynen kaldı: Marka değişince filtreler sıfırlanıyor, bir filtre seçilen modeli düşürürse Model "Seçiniz"e dönüyor. Filtre etiketi "Odak" yerine tasarımdaki gibi "Odak düzlemi" oldu.

**Elle giriş ("Aradığın dürbün listede yok mu?"):**

1. Dürbün markası | Dürbün modeli (yan yana iki yazı kutusu, ikisi de zorunlu)
2. Minimum büyütme | Maksimum büyütme
3. Mercek çapı | Odak düzlemi
4. Dürbün birimi | Klik değeri
5. Üst kule klik sayısı | Dürbün ayağı
6. Retikül (seçilen birime uyan genel listeden, eskisi gibi)
7. "Dürbün: Marka Model …" satırı, en altta da "Listeden seç" bağlantısı

"Kaydetmek için eksik" listesi, elle girişte model boşsa "Dürbün modeli" yazıyor. Kayıtlı dürbünün adı ve Profil özet kartı artık "Marka Model …" gösteriyor (ör. "Benim Optik X5 Pro 5-25x56 FFP").

### Nasıl

- `profile_editor_scope.dart`: Filtreler her zaman listede; `onChanged` Marka seçilene kadar `null` (kapalı). Elle girişte `scope-brand` | `scope-model` aynı satırda. "Listeden seç" kartın en altına taşındı. "Dürbün: …" satırı marka + elle girilen model + ölçüleri birleştiriyor.
- `profile_editor.dart`: Yeni `scopeModel` kutusu eklendi. Elle girişte model kayıtta ölçülerin önüne yazılıyor; kaydın `model` alanı ör. `"X5 Pro 5-25x56 FFP"` oluyor (marka ayrı alanda kalıyor). Listeden seçilen dürbünün kaydı değişmedi (`model` = yalnız ölçüler). Profili Düzenle açılınca model, kaydın `model` alanından ölçüler çıkarılarak geri okunuyor.
- `profile_summary.dart`: Özet kartı elle girilen modeli markanın yanına koyuyor.
- Profili Düzenle'de filtreleri Marka değişene kadar gizleyen `_scopeFiltersHidden` silindi (CLAUDE.md: kaldırılan özellik koddan silinir).
- Modeli olan bir elle giriş kaydı, Profili Düzenle'de artık katalog kaydıyla eşleştirilmiyor. Marka + seri ve ölçüler bir katalog kaydıyla aynı olsa da elle giriş olarak açılıyor; yoksa bir sonraki kayıtta model düşerdi (Code Review bulgusu).
- `lib/ui/menzil_widgets.dart` (tek yer): Listede "Seçiniz" satırı olan kutularda (filtreler gibi) seçilen değer kapalı kutu gibi gri görünüyordu. Simulator görüntüsünde fark edildi: MOA/FFP seçili filtreler kapalı sanılıyordu. Açık kutuda seçilen değer artık normal yazı renginde; kapalı (onChanged yok) kutu gri kalıyor.

### Neden

Elle girişte model kutusu yoktu; sahip dürbününün modelini giremiyordu ve kart onaylı tasarımın sırasında değildi. CLAUDE.md kuralı da "Marka | Model yan yana" diyor.

### Uç durumlar

- **Model alanı olmadan kaydedilmiş eski elle giriş profilleri**: Açılınca model kutusu boş, diğer her şey eskisi gibi. Bu profiller **model girilmeden de Güncellenebiliyor**: eski profilin hiçbir şeye dokunmadan güncellenmesini koruyan denetim testleri (audit_2026_10_14b, audit_2026_10_15b) bozulmasın diye böyle yapıldı. Kullanıcı modeli ekleyip kaydederse model saklanıyor. Yeni elle girişte model zorunlu. Eski profillerde de zorunlu olsun istenirse tek satırlık bir değişiklik bu (`_scopeLegacyNoModel`).
- Liste profilleri değişmedi: kayıt biçimi, eşleşme ve açılış aynı.
- Bir katalog kaydında olmayan değer (ör. Gamo'da odak düzlemi) eskisi gibi kendi kutusunda soruluyor. Bu durumda kartta iki "Odak düzlemi" görünüyor: biri filtre, biri değer kutusu. Bu kutu Model'in altında, Üst kule | Dürbün ayağı satırından önce çıkıyor, bu yüzden o satır bir kayabiliyor (bu davranış önceden de vardı).
- Dar ekran (320 pt) ve yazı ölçeği 1,3: Kartta tek sütun oluyor, sıra korunuyor, taşma yok.
- Dürbün modeli en fazla 80 karakter. Ayrıca model + boşluk + ölçüler 100 karakteri geçerse hata veriyor; mağaza bu sınırın üstünü reddediyor.
- Katalog listesi boşsa (pratikte olmaz) elle giriş kaydı da modeliyle açılıyor; bu durumda da eski kayıt modelsiz güncellenebiliyor.
- Özet kartı, katalogda olduğu gibi MOA/MRAD/MIL/SMOA kelimelerini isimden çıkarıyor. Modelin içinde bu kelimeler varsa özette görünmez.

### Bilerek yapılmayan

- Hesap değişikliği yok. Klik değeri, birim, FFP/SFP, üst kule ve dürbün ayağı çözücüye eskisi gibi gidiyor.
- Dürbün markası ve Dürbün modeline ⓘ eklenmedi. CLAUDE.md marka/model gibi kimlik alanlarını muaf tutuyor; tasarımda da ⓘ yok. Kaynak denetim aracındaki kimlik listesine `Dürbün modeli` eklendi (`tools/denetim_2026_10_15b_profil.py`).
- Tüfek, Mühimmat ve diğer sayfalara dokunulmadı.
- Görsel olarak yeni bir tasarım dili kurulmadı; Frontend Design kuralları onaylı Temiz Tasarım ve mevcut Menzil bileşenleriyle uygulandı.

### Testler

Yeni dosya `test/durbun_girisi_tasarim_test.dart`, gerçek Profil ekranında çalışıyor:

- **Liste yolu**: Marka seçilmeden filtrelerin kapalı olduğu sınanıyor. Sonra Element Optics → Birim MOA → Odak düzlemi FFP seçiliyor; Model listesinin yalnız MOA+FFP modelleri gösterdiği doğrulanıyor. Titan 3-18x50 → Retikül APR-2D MOA → Kaydet → Profili Düzenle'de aynı marka, model, retikül, ayak ve "Dürbün:" satırı görünüyor.
- **Elle giriş yolu**: Kutular sırayla dolduruluyor → Kaydet → kayıtta `brand` "Benim Optik", `model` "X5 Pro 5-25x56 FFP" → özet kartında "Benim Optik X5 Pro 5-25x56 FFP" → Profili Düzenle'de model "X5 Pro" kalıyor → Güncelle sonrası kayıt aynı.
- **Sıra**, dikey konuma göre sınanıyor: aynı satırdaki kutuların üst kenarı ±0,5 pt içinde, soldan sağa diziliyor; satırlar yukarıdan aşağı. ⓘ'ler, etiketler ve "Kaydetmek için eksik"teki "Dürbün modeli" de sınanıyor.
- **Eski elle giriş profili**: Model kutusu boş açılıyor, diğer değerler aynı, eksik listesinde yok.
- **Katalogla aynı ölçülü, modeli olan elle giriş**: Liste moduna geçmiyor, model ("Benim") korunuyor.
- **320 / 390 pt × yazı ölçeği 1,0 / 1,3**: Taşma yok, sıra korunuyor, kutular kartın içinde, açılan liste kutudan geniş değil.

Güncellenen testler (yeni sahip kararına göre beklentileri değişti; hiçbiri silinmedi veya atlanmadı):

- `test/profil_duzen_koruma_test.dart`: Liste düzeni artık filtrelerle başlıyor (Profil Oluştur ve Profili Düzenle aynı). Elle giriş düzeni yeni sırada. "Dürbün modeli" eksik listesinde ve kutu eşlemesinde. Eski elle giriş profilinin boş modelle açıldığı sınanıyor.
- `test/scope_form_sade_test.dart`: "Profili Düzenle filtreleri gizler" (13.10 kuralı) yerine "Profili Düzenle filtreleri gösterir" sınanıyor. Gamo'daki ⓘ kontrolü artık değer kutusunun kendi ⓘ'sine bakıyor.
- `test/profile_editor_fail_closed_test.dart`: Gizli değer kutularının ⓘ'si yok kontrolü artık Odak düzlemi filtresinin kendi ⓘ'sini saymıyor. Elle girişte her kutunun ⓘ'si var kontrolü aynen duruyor.
- `test/support/rifle_form.dart` (`fillScopeForm` artık modeli de giriyor), `test/menzil_shell_test.dart` (beklenen satır "Test Optik X1 6-24x56 FFP"), `integration_test/app_launch_test.dart` (model giriliyor).

Yerel:

- `python3 tools/offline_dart_lint.py`: PASS (408 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'`: OK (915 test, 1 atlanan; atlanan main'de de atlanıyor)
- Bu ortamda Flutter SDK indirilemedi (Flutter'ın indirme sunucusuna erişim engelli). Bu yüzden `flutter test` yerelde çalışmadı; Flutter testleri yalnız CI'da koştu.

### Ekran görüntüleri

Simulator turu `integration_test/sim_screens_durbun_test.dart` çalıştırıldı (`.github/workflows/sim-screens.yml`, [run 38937057437](https://github.com/sniperTurk/flutter-app/actions/runs/38937057437), çıkış kodu 0, her adım geçti). Görüntüler `ci/sim-screens` dalında `d0ecf8d` commit'inde duruyor.

- Cihaz: **iPhone 17 Pro / iOS 26.2**. İş akışı en yeni iPhone Pro'yu seçiyor; bu cihazın genişliği 402 pt. İş akışında 390 pt cihaz seçeneği yok. 390 pt ve 320 pt genişlik widget testlerinde sınandı.
- Uygulama kodu: `7abb3a3`. Code Review düzeltmeleri (`4a87dc1`) bundan sonra geldi; ekranın düzeni o commit'te değişmedi. Bu görüntülerde seçili MOA/FFP filtresi henüz eski gri renkte görünüyor (aşağıda).

Görüntülerde ne görünüyor:

**Elle giriş**

- [01](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/01_durbun_elle_bos.png?raw=true): Boş elle giriş, kartın üstü. Sıra: Dürbün markası | Dürbün modeli, Minimum | Maksimum büyütme, Mercek çapı | Odak düzlemi. Hepsi "Seçiniz" ya da boş; klavye, tüfek alanından açık kalmış.
- [02](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/02_durbun_elle_bos_alt.png?raw=true): Kartın altı. Üst kule klik sayısı | Dürbün ayağı, Retikül, "Dürbün: —", en altta "Listeden seç".
- [03](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/03_durbun_elle_dolu.png?raw=true): Dolu hali, üstü. Benim Optik | X5 Pro, 5x | 25x, 56 mm | FFP, MRAD | 0,1 MRAD, 200 | 0 MOA.
- [04](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/04_durbun_elle_dolu_alt.png?raw=true): Dolu hali, altı. Retikül Mil-Dot; "Dürbün: Benim Optik X5 Pro 5-25x56 FFP"; "Listeden seç".
- [05](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/05_profil_ozet_elle.png?raw=true) ve [06](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/06_profil_ozet_elle_2.png?raw=true): Kayıttan sonra Profil sayfası. Dürbün bilgileri → Marka / Model: "Benim Optik X5 Pro 5-25 x 56 FFP · MRAD", Retikül Mil-Dot, Dürbün üst kule 200 klik.
- [07](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/07_durbun_elle_duzenle.png?raw=true): Profili Düzenle. Dürbün markası "Benim Optik", Dürbün modeli "X5 Pro" ve diğer değerler korunmuş.

**Listeden seçim**

- [11](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/11_durbun_liste_dolu.png?raw=true): Kartın üstü. Marka Element Optics; Birim MOA | Odak düzlemi FFP; Tüp | Büyütme "Seçiniz"; Model "Titan 5-25x56 FFP MOA"; Üst kule 360 | 0 MOA. Seçili MOA ve FFP burada gri görünüyor; düzeltme `4a87dc1`'de.
- [12](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/12_durbun_liste_dolu_alt.png?raw=true): Kartın altı. Retikül APR-2D MOA; "Dürbün: Element Optics Titan MOA 5-25x56 FFP"; "Aradığın dürbün listede yok mu?".
- [13](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/13_durbun_liste_duzenle.png?raw=true) ve [14](https://github.com/sniperTurk/flutter-app/blob/d0ecf8d431f17df29cff9adf6c6eb1809feea18f/latest/14_durbun_liste_duzenle_alt.png?raw=true): Profili Düzenle. Aynı sıra; filtreler yerinde, "Seçiniz"; Model, Retikül, ayak ve üst kule korunmuş.

**Olmayanlar ve sorunlar**

- **Marka seçilmeden boş liste kartının görüntüsü yok.** Tur bu adıma görüntü işaretini koydu, ama Simulator görüntüsü geç alındı. 08–11 aynı kare çıktı (dolu liste kartı). Kapalı filtreler widget testinde sınanıyor; görüntüsü bu turda yok.
- Sondaki düzeltmelerle (`4a87dc1`) turu yeniden çalıştırma denemem iki kez iptal oldu. sim-screens iş akışında aynı anda yalnız bir çalışma bekleyebiliyor ve başka bir oturumun kuyruğa aldığı çalışma benimkinin yerini aldı. Bu yüzden son commit'in Simulator görüntüsü yok.


### CI

Son kod commit'i `4a87dc1` (bu rapor yalnız belge; iOS CI belge değişikliğinde çalışmıyor):

- `iOS CI` [run 38940995177](https://github.com/sniperTurk/flutter-app/actions/runs/38940995177):
  - `verify` **success**
  - `dart-checks` **success**
  - `wind-acceptance` **success**
  - `ios-simulator` atlandı (iş akışı ayarı)
- `flutter test` tüm paket, test-diag [run 38941380039](https://github.com/sniperTurk/flutter-app/actions/runs/38941380039): **success**
- `flutter analyze`, analyze-diag [run 38941383917](https://github.com/sniperTurk/flutter-app/actions/runs/38941383917): **success**
- Biçim, format-fix [run 38941000095](https://github.com/sniperTurk/flutter-app/actions/runs/38941000095): **success**, değişiklik gerekmedi.
- Simulator turu [run 38937057437](https://github.com/sniperTurk/flutter-app/actions/runs/38937057437) (`7abb3a3`): **success**
- Code Review: 3 ajan (CLAUDE.md + hata, yorumlar + geçmiş, güvenlik).
  - Gerçek bulunan 3 hata düzeltildi: modelli elle kayıt katalogla eşleşince modelin düşmesi, boş katalogda modelin okunmaması, 100 karakter sınırı.
  - Özette modeldeki "3-12x56" gibi ölçü kalıplarının silinmesi bilerek bırakıldı: ölçüler özette zaten ayrıca yazıyor.
- Security review: sorun bulunmadı.

TestFlight, Simulator dışı cihaz, imzalama ve App Store çalıştırılmadı.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01VZG31ceEzwDsgFQrehFCFG
