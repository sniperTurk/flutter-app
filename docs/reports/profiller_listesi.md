# Profiller listesi ve Ek mühimmat bilgileri (fix/profiller-listesi)

Sahip kararları (2026-10-14, İstanbul saati):

- 17:33–17:44, Profil sekmesi → "Profiller" listesi (onaylı taslak B):
  "Aşağıda yazan profiller kısmı çok karışık. Düzenle, sil profilin sağına
  gelebilir…", "Yedekle Geri yükle bölümü … buradan kaldır", menü satırları
  itmesin, satırdan "3050 fps · Sıfır 100 m" kalksın, "Profil ekle"
  "Profiller" başlığının sağına, "Kopyala, sil, düzenle üç noktanın içinde
  olsa", "B okey".
- 18:07–18:20, Profil Oluştur / Profili Düzenle → Mühimmat: "Mühimmat
  verisi çok uzuyor … ayrı bir bölüm olsun", "Ek mühimmat bilgileri …
  isteğe bağlı yazsın ama kapalı gelmesin; başlığın ⓘ'si olsun", "Uzun
  metin daha güzel".

Dal, #308 (fix/profil-duzen) ve #306 (fix/bc-modeli-secim) birleştikten
sonraki güncel `main` üzerinden açıldı; ikisi de bu iş başladığında zaten
birleşmişti.

**Hiçbir şey silinmedi.** Yedekle / Geri yükle gizlendi (bayrak), yedek ve
geri yükleme kodu ile kayıtlı veriler aynen duruyor. Taşınan Mühimmat
kutularının davranışı, doğrulaması, kayıt anahtarları ve hesaba etkisi
değişmedi.

## Bölüm 1 — Profiller listesi

Dosya: `lib/features/profiles/profiles_screen.dart`

- **Başlık satırı:** solda "Profiller" ve altında "N kayıtlı profil";
  aynı satırın sağında amber **"Profil ekle"** (+ simgesi, eskisiyle aynı
  iş: yeni profil formunu açar). Düğme 148 pt genişliğinde; büyük yazı
  boyutunda sığmazsa yazı küçülür, ikinci satıra kaymaz.
- **Listenin altındaki Profil ekle | Kopyala | Sil satırı kaldırıldı.**
- **Her satır:** durum noktası, profil adı (aktif olanda "Aktif") ve sağda
  yalnız bir **"⋯"** düğmesi (Icons.more_horiz, 48×48 pt dokunma alanı).
  Hız · Sıfır alt satırı kaldırıldı. Satıra dokunmak profili aktif yapar
  (eskisi gibi). Uzun ad en çok iki satır yazılır, sonra "…" ile kısalır;
  "⋯" hiçbir zaman ekrandan taşmaz.
- **"⋯" menüsü:** satırın hemen altında açılan küçük bir açılır menü
  (üstte duran katman; satırlar yerinden oynamaz). Sırası:
  1. **Düzenle** (kalem) — o profili Profili Düzenle'de açar.
  2. **Kopyala** (content_copy) — eskisiyle aynı kopyalama ("… (kopya)").
  3. **Sil** (çöp kutusu, kırmızı) — eskisiyle aynı silme akışı.
  Yazılar sola yaslı; menü içeriği kadar geniş.
- **Silme onayı:** başlık **"Profil silinsin mi?"**, düğmeler **İptal** /
  **Sil** (önceden "Profili sil?" / "Vazgeç" / "Profili sil"). Aynı onay
  sola kaydırarak silmede de kullanılır; kaydırarak silme olduğu gibi
  duruyor.
- **Yedekle / Geri yükle ve ⓘ'si gizlendi, silinmedi:**
  `bool.fromEnvironment('PROFILE_BACKUP_BUTTONS')`, varsayılan kapalı.
  Açmak için: `--dart-define=PROFILE_BACKUP_BUTTONS=true`. Testler için
  `ProfilesScreen.debugShowBackupButtons` (yalnız test) eklendi. İlk açılış
  (hiç profil yokken) karşılama ekranındaki "Yedekten geri yükle"
  dokunulmadı; o liste değil.
- **Boş liste:** "Henüz kayıtlı profil yok…" yazısı aynı; başlıkta "Profil
  ekle" yine var.
- Artık kullanılmayan iç yardımcı `_zeroText` (yalnız silinen alt satır
  kullanıyordu) analiz uyarısı vermesin diye kaldırıldı; aynı değeri
  üreten `_zeroValue` duruyor.

## Bölüm 2 — Ek mühimmat bilgileri

Dosyalar: `lib/features/profiles/profiles_screen.dart`,
`lib/features/profiles/profile_field_info.dart`

- Mühimmat bölümünün sonuna yeni alt bölüm: **"Ek mühimmat bilgileri"**,
  yanında küçük soluk **"isteğe bağlı"**, sağında **tek ⓘ**. Sola yaslı,
  **her zaman açık** (katlanmaz, ok simgesi yok).
- İçine taşınan kutular (sırasıyla, davranışları aynı):
  1. **Barut katsayısı | Hız ölçüm sıcaklığı** (aynı satır; Barut
     katsayısı etiketi birimsiz, #308'deki gibi).
  2. **Hıza göre BC** başlığı ve **1. eşik hızı | Eşik altı BC**,
     **2. eşik hızı | Eşik altı BC** — kendi ⓘ'leri ve gizleme koşulları
     aynen (PCP'de yok, Özel eğri seçiliyken yok, elle yazılan ateşli
     fişekte `AMMO_BC_BANDS_TYPED` bayrağına bağlı; bayrağa dokunulmadı).
- Alt bölüm, Özel eğri kutusunun hemen altında; kırmızı "Mühimmat tipini ve
  BC modelini seçin" uyarısı ile Kaydet'in üstündeki salt okunur özet
  satırı (sahip 2026-10-14 kararı gereği Kaydet'e yakın) en altta kaldı.
- Başlık yalnız içinde kutu olduğunda görünür (ateşli silah; PCP'de bu
  kutular hiç olmadığı için başlık da yok).
- ⓘ metni (`ProfileFieldInfo.ammoExtra`), birebir:

  > Nedir?
  > Barut katsayısı, hız ölçüm sıcaklığı ve hıza göre BC; hesabı inceltmek
  > için girilen ek mühimmat bilgileridir. Boş bırakılabilir, profil yine
  > kaydedilir.
  >
  > Neden önemli?
  > Hava sıcaklığı değişince namlu çıkış hızı da değişir; mermi
  > yavaşladıkça BC düşer. Bu bilgileri girerseniz uzak mesafede düşüş ve
  > rüzgâr sapması daha doğru hesaplanır.

- Kutuların kendi ⓘ'leri duruyor; kutu altı yardım yazısı yok; etiketlerde
  parantez yok; satır başına iki kutu.

## Uç durumlar

- **Boş kutular kaydı engellemez**, "Kaydetmek için eksik" listesinde
  çıkmaz (testle doğrulandı). Yarım veya aralık dışı bir değer yazılırsa
  doğrulama eskisi gibi çalışır (örn. katsayı var, sıcaklık yok → "Sıcaklığı
  da girin."); görev "doğrulama değişmesin" dediği için bu korundu. Sahip
  isterse ayrı görevle değiştirilir.
- Eski kayıtlı profil (barut katsayısı 0,8 / 20 °C ve 3 bantlı BC'li elle
  yazılmış fişek) açılıp Güncelle'ye basılınca değerler aynen kalır;
  bantlar (gizli olsalar da) kayıtta durur.
- Aktif profil "⋯ → Sil" ile silinirse kaydırarak silmedekiyle aynı yol
  çalışır (liste ve üst ekran yenilenir).
- Kopya, eski "Kopyala" düğmesiyle aynı alanları taşır (değişiklik yok).
- 320 pt genişlik ve ×1,3 yazı boyutunda taşma yok; "⋯", "Profil ekle" ve
  menü satırları ≥ 44 pt.

## Yapılmayanlar

- Profil formunun geri kalanı, özet kartları, hesap, katalog verisi, diğer
  sayfalar ve mevcut gizli bayraklar değişmedi.
- Yedekle / Geri yükle'nin kullanıcı profil sayfasına taşınması (sahip:
  "o sayfa yapıldığında") bu işte yok.
- Kaydırarak silme kaldırılmadı (istenmedi).
- TestFlight yok, birleştirme yok (taslak PR).

## Testler

- Yeni: `test/profiller_listesi_test.dart` — Profil ekle başlık satırında
  "Profiller"in sağında ve formu açıyor; satırlarda hız/sıfır yok ve tek
  "⋯" var; menü sırası Düzenle, Kopyala, Sil ve açılınca satır konumları
  önce/sonra aynı; Düzenle o profili açıyor; Kopyala çoğaltıyor; Sil önce
  "Profil silinsin mi?" (İptal / Sil) soruyor sonra siliyor; alttaki düğme
  satırı yok; Yedekle / Geri yükle varsayılan gizli, bayrakla görünür; boş
  liste; 320 pt ×1,0 / ×1,3 uzun adla taşma yok.
- `test/profil_duzen_koruma_test.dart` yeni grup "Mühimmat: Ek mühimmat
  bilgileri": başlık + "isteğe bağlı" + tek ⓘ ve ⓘ metni birebir; açılır
  pencere sola yaslı; ok yok; yeni profilde ilk karede açık; kutular başlık
  altında istenen sırada ve yalnız bir kez; Profili Düzenle'de eski JSON
  (barut katsayısı + BC bantları) kaydet → yeniden aç gidiş-dönüş; boş
  kutularla kayıt; 320 pt ×1,0 / ×1,3 taşma yok.
- Yeni menüye uyarlanan mevcut testler: `menzil_shell_test`,
  `profile_backup_test` (bayrak açık), `profilsiz_hedef_ayak_test`,
  `ekran_boyutu_test`, `profil_duzen_koruma_test` (Kopyala),
  `profile_page_test` (Düzenle; satırda "fps • Sıfır" artık yok, değerler
  özet kutularında).
- Yerel: `python3 tools/offline_dart_lint.py` → GEÇTİ (345 dosya, 0 sorun);
  `python3 -m unittest discover -s tools -p 'test_*.py'` → GEÇTİ (743 test).
- Yerel Flutter **ENGELLİ**: sabit Flutter 3.47.2 indirilemedi
  (storage.googleapis.com proxy'de 403). Bu yüzden `flutter analyze`,
  `flutter test` ve `tools/claude_flutter_verify.sh` yerelde çalışmadı;
  sonuçlar yalnız aşağıdaki CI koşularından.

## CI

Hepsi `fix/profiller-listesi` dalında, `ff16ba9` (biçimlendirme commit'i)
üzerinde koştu:

- Biçimlendirme (One-off dart format fix): **başarılı** —
  https://github.com/sniperTurk/flutter-app/actions/runs/38591811142 .
  İki test dosyasında satır kırma düzeltmesi yaptı (`ff16ba9`), dala
  çekildi.
- `flutter analyze --fatal-infos --fatal-warnings` (analyze-diag):
  **başarılı** — https://github.com/sniperTurk/flutter-app/actions/runs/38592188986
- `flutter test` tüm `test/` (test-diag): **başarılı** (çıkış kodu 0) —
  https://github.com/sniperTurk/flutter-app/actions/runs/38592185278 .
  Koşudaki "KESIK…" / `truing_drag_band_test` / `scope_mount_cant_test`
  notları geçen testlerin yazdırdığı tanı satırları; aynıları `main`
  üzerindeki önceki koşuda da var (38582190475), bu işle ilgisi yok.
- Bu rapor commit'i yalnız belge ekler; kodu değiştirmez.
- PR #309 üzerindeki iOS CI (`3f1be50`): **verify başarılı**, dart-checks
  başarılı, wind-acceptance başarılı; ios-simulator işi **atlandı**
  (koşmadı) — https://github.com/sniperTurk/flutter-app/actions/runs/38593397148
- Simulator, TestFlight, App Store: **koşmadı**.

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_016ytMrd8BUbacJSghGGejxP
