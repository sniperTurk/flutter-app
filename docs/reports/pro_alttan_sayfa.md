# Pro Ayarlar: açıklama alttan açılan sayfada, tek bilgi kaynağı

Sahip kararları (2026-10-13 20:09, 20:28):

1. Pro açıklaması ortada bir pencere değil, **alttan açılan sayfa** olsun.
2. **Tek bilgi kaynağı** ("iki bilgi olmaz kafa karıştırır"): bir kutunun
   başlığındaki ⓘ de, o kutunun içindeki her alanın ⓘ'si de aynı sayfayı
   açsın.
3. Popup yazıları sola yaslı olsun, iki yana yaslı değil.

## Ne değişti

- Pro Ayarlar'da kutu başlığının yanındaki ⓘ'ye dokununca artık ortada
  `AlertDialog` değil, alttan bir sayfa (bottom sheet) açılıyor. Pro sayfası
  arkada karartılmış olarak görünmeye devam ediyor.
- Sayfanın içinde: en üstte kutunun adı (ör. "Hareketli hedef"); altında
  kutunun açıklamaları; her açıklamada **Ne?**, **Neden önemli?**,
  **Nasıl?** ayrı paragraflar (sorular kalın, aralarında boşluk). "Nasıl?"
  içindeki "•" ile başlayan adımlar ayrı madde satırları olarak, asılı
  girintiyle gösteriliyor.
- Açıklamaların altında ince bir çizgi ve **Kutular** bölümü: o kutudaki her
  alan, kalın etiketi ve kendi ⓘ yazısıyla ("Grup çapı: …") listeleniyor.
- Kutunun içindeki bir alanın ⓘ'sine dokununca (ör. "Grup çapı") eski küçük
  pencere yerine **aynı sayfa** açılıyor; o alanın satırı açık mavi zeminli
  ve solunda mavi bir çizgiyle vurgulanıyor ve sayfa kendiliğinden o satıra
  kayıyor.
- En altta, başparmak bölgesinde, tam genişlikte **Kapat** düğmesi.
- Bütün yazılar sola yaslı.
- Hiçbir yazı değişmedi: açıklamalar (`ProSectionInfo`) ve alan ⓘ yazıları
  (`EnvironmentFieldInfo`) kelimesi kelimesine aynı.

## Sayfa nasıl kuruluyor

- Yeni dosya `lib/features/ballistics/pro_info_sheet.dart`:
  - `showProInfoSheet(...)`: `showModalBottomSheet` ile açar.
    `isScrollControlled: true`, `useSafeArea: true`, `showDragHandle: true`
    (üstte tutma çubuğu), `enableDrag: true` (aşağı kaydırınca kapanır),
    en çok ekran yüksekliğinin %85'i, üst köşeler 20 yarıçapla yuvarlak,
    zemin rengi temanın `surface` rengi.
  - `ProInfoSheet`: başlık (sabit) + kayan gövde (`SingleChildScrollView`,
    anahtar `pro-info-scroll`) + sabit "Kapat" (anahtar `pro-info-close`).
    Sayfanın anahtarı `pro-info-sheet`.
  - `ProInfoEntry` (açıklama + isteğe bağlı not; eski `_ProInfo` sınıfının
    yerine) ve `ProInfoField` (alan etiketi + ⓘ yazısı).
  - `ProInfoFieldEntry`: "Kutular" satırı; `highlighted` ise açık mavi zemin
    (`cyanSoft`) ve solda mavi çizgi (`cyan`). Anahtar `pro-info-field-<sıra>`.
- `lib/features/ballistics/ballistics_screen.dart`:
  - `_proBox(...)`: yeni `fields` parametresi (kutudaki alanlar). Başlık
    ⓘ'si (`pro-info-<kutu>`, ipucu "Açıklama: <başlık>") artık
    `showProInfoSheet` çağırıyor.
  - Kutunun içeriği bir `MenzilInfoScope` ile sarıldı (aşağıya bakın).
  - Her kutuya alan listesi verildi (Açı: Tüfek eğimi, Dürbün eğimi; Rüzgâr:
    Rüzgâr hızı × 1,5, Yol ortası, Hedefte; Coriolis: Enlem, Atış yönü;
    Yerçekimi: Yerçekimi; Hareketli hedef: Hedef hızı, Yönü, Grup çapı, Hız
    farkı, Hedef çapı, Mesafe hatası, BC hatası, Atış sayısı; Tüfek
    düzeltmeleri: Gerçek / yazan, Yukarı + / aşağı −, Sağ + / sol −, Mermi
    uzunluğu, PCP'de Kalan tüp basıncı). Koşullar sayfadaki alanlarla aynı.
  - Eski popup gövdesi `_proInfoBody` ve `_explain` ile `_ProInfo` sınıfı
    kaldırıldı: başka hiçbir yerde kullanılmıyorlardı (kullanılmayan özel
    metot analizde uyarı verir ve `--fatal-warnings` CI'yı kırar). Gizle-silme
    kuralı başka yerden çağrılan kod için; bu kodu çağıran yer kalmadı.
- `lib/ui/menzil_widgets.dart`:
  - `MenzilInfoButton`: isteğe bağlı `onPressed` (verilirse pencere yerine o
    çalışır). `body`, `tooltip`, `closeLabel` duruyor (gizle-silme).
  - Yeni `MenzilInfoScope` (InheritedWidget): altındaki alan ⓘ'lerine
    "yazını başka yerde göster" diyebilir. Kapsam yoksa veya kapsam "bu benim
    değil" derse eski pencere açılır.

## Alan ⓘ'si kutusunu ve vurgusunu nasıl buluyor

1. Alan ⓘ'si (`MenzilInput` / `MenzilSelect` / Açı kutucukları) dokunulunca
   yukarıda bir `MenzilInfoScope` var mı diye bakar. Yalnızca açık bir Pro
   kutusunun içinde vardır.
2. Kapsam, ⓘ'nin başlığını (alan etiketi) ve yazısını kutunun `fields`
   listesinde arar: önce etiket + yazı birlikte, bulamazsa yalnız yazı.
3. Bulursa o kutunun sayfasını o satır vurgulu açar ve `true` döner; bulamazsa
   `false` döner ve eski pencere açılır (hiçbir ⓘ sessiz kalmaz).
4. Sayfa açıldıktan sonraki ilk karede `Scrollable.ensureVisible` vurgulu
   satırı görünür alana (üstten ~%20) kaydırır.

## Neden

- Alttan açılan sayfa telefonda daha rahat okunuyor, başparmakla kapatılıyor
  ve arkadaki Pro sayfası kaybolmuyor.
- Önceden bir kutuda iki ayrı bilgi vardı (kutu ⓘ'sinde uzun açıklama, alan
  ⓘ'lerinde kısa açıklama). Sahip "iki bilgi olmaz kafa karıştırır" dedi:
  artık kutunun her ⓘ'si aynı tek sayfayı açıyor; kısa alan yazıları da
  o sayfanın "Kutular" bölümünde duruyor.

## Uç durumlar

- **Alanı olmayan kutu:** Alan listesi boşsa "Kutular" başlığı ve çizgi hiç
  çizilmez. (Şu an Coriolis ve Yerçekimi her zaman açık olduğundan her
  kutunun alanı var; kapatılabilir hâle gelirse liste kendiliğinden boşalır.)
- **Kutunun dışındaki alanlar:** "Atış mesafesi" bir kutuda değil; onun ⓘ'si
  eski pencereyi açar. Kutu içindeki ama listede olmayan bir ⓘ (ör. ileride
  ⓘ'li bir uyarı) da eski pencereye düşer.
- **Çok uzun yazılar:** Gövde kayar; başlık ve "Kapat" sabit kalır. Sayfa
  ekranın %85'inden uzun olmaz.
- **Notlar:** PCP'de spin drift notu (anahtar `pro-spin-pcp-note`, turuncu)
  Tüfek düzeltmeleri sayfasında, spin açıklamasının altında. Ateşli tüfekte
  yok. Barut sıcaklığı yalnız ateşli tüfekte, tüp basıncı yalnız PCP'de.
- **Büyük yazı:** 320×568 ekran ve yazı ölçeği 1,3'te taşma yok; uzun
  sayfalar sonuna kadar kayıyor; vurgulu son alan görünür alana geliyor.
- **Koyu tema:** Sayfa zemini `surface`, paragraflar `ink2`, vurgu
  `cyanSoft`/`cyan`: hepsi temanın kendi renkleri.
- **VoiceOver:** Kutu ⓘ'si kendi düğmesi ("Açıklama: <başlık>"), başlık ve
  "Kutular" başlık (header) olarak işaretli, vurgulu satır "seçili"
  (selected), "Kapat" bir düğme. Tutma çubuğu Flutter'ın kendi erişilebilir
  kapatma eylemini taşır.
- **Aynı başlık iki kez yazılmaz:** Açıklamanın adı sayfa başlığıyla aynıysa
  (Coriolis, Hareketli hedef) tekrar yazılmaz (sahip kuralı 2026-10-12).

## Bilerek yapılmayanlar

- Profil, Hava Durumu, Hedef, Araçlar sayfalarındaki alan ⓘ'leri
  değişmedi; eski pencereyi açmaya devam ediyor.
- Açıklama ve alan yazılarının hiçbiri değiştirilmedi.
- `MenzilInfoButton` içindeki pencerenin hizası bu PR'da değiştirilmedi;
  o `fix/yasla-sadece-hedef`'in (#276) işiydi.
- Hava Durumu rüzgâr rehberi (`fix/ruzgar-rehber`) ve yazı tipi
  (`feat/sistem-yazisi`) ile ilgili hiçbir şeye dokunulmadı.
- Birleştirme (merge) ve TestFlight yapılmadı; PR taslak.

## Diğer PR'larla çakışma

- Bu PR açıkken `fix/yasla-sadece-hedef` (#276), `fix/ruzgar-rehber` (#272)
  ve `feat/sistem-yazisi` (#277) main'e birleşti. main bu dala birleştirildi
  (merge commit, geçmiş yeniden yazılmadı).
- Tek çakışma: #276'nın `_explain` içindeki `TextAlign.start` değişikliği.
  Bu PR `_explain`'i kaldırdığı için çakışma `_explain` silinmiş hâliyle
  çözüldü; yeni sayfa zaten sola yaslı, yani #276'nın amacı korunuyor.
- `MenzilInfoButton` penceresinde #276'nın hizası (sola yaslı) aynen duruyor;
  bu PR yalnız `onPressed` ve kapsam kontrolünü ekledi.

## Testler

- `test/pro_info_popup_test.dart` (yeniden yazıldı):
  - açılan hiçbir kutuda satır içi açıklama yok (ateşli / PCP);
  - her kutu ⓘ'si bottom sheet açar (AlertDialog değil): başlık, Ne? /
    Neden önemli? / Nasıl? ayrı ve kalın, madde satırları, "Kutular"
    listesi kelimesi kelimesine, her şey sola yaslı, vurgu yok; Kapat kapatır;
  - her alan ⓘ'si (her kutudaki her alan) aynı sayfayı açar, yalnız o satır
    vurgulu ve görünür alanda;
  - aşağı kaydırma (fling) kapatır; tutma çubuğu, sürükleme, yuvarlak köşe;
  - VoiceOver: ⓘ düğmesi, "Kapat" düğmesi;
  - 320×568, yazı ×1,3: taşma yok, sayfa ≤ %85, Kapat ekranda, uzun sayfalar
    kayar, PCP'de son alan (Kalan tüp basıncı) vurgulu ve görünür;
  - koyu tema renkleri;
  - "Atış mesafesi" (kutu dışı) ve Hava Durumu "Bağıl nem" ⓘ'leri eski
    pencereyi açar;
  - Hedef sayfası açıklamalarını korur.
- `test/pro_new_effects_test.dart`: Tüfek ⓘ'si artık `pro-info-sheet` açar.
- `test/pro_tab_test.dart`: değişmeden geçer ("Kapat" metni aynı).

## Doğrulama

- Yerel: `python3 tools/offline_dart_lint.py` → PASS (0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` → 732 test OK.
- Yerel Flutter: **BLOCKED** — bu ortamda Flutter motoru indirilemedi
  (storage.googleapis.com proxy 403). `flutter test/analyze` yalnız CI'da
  çalıştı.
- CI çalıştırmaları: aşağıda.

CI_RUNS_PLACEHOLDER

🤖 Generated with [Claude Code](https://claude.com/claude-code)
