# Profil kartı ikinci satırı: Tüfek markası, kalibre adı

Sahibin kararı: 17.10.2026 18:59 (İstanbul), "aç görevi". Profil sekmesi →
Profiller listesindeki her kartın gri ikinci satırı.

## Ne yapıldı

- İkinci satır artık yalnız **"Tüfek markası, kalibre adı"**:
  örn. "Accuracy International, .308 Win", "ATA Arms, .308 Win".
- Sıfır mesafesi, namlu çıkış hızı (fps) ve BC bu satırdan kaldırıldı.
- Satır **her zaman tek satır**: uzun adlarda sonu "…" ile kesilir
  ("Accuracy International, .338-378 Weatherby Mag" gibi).
- Yazı tipi ve rengi aynı (caption, ink2), sola yaslı; kart boyu başka
  bakımdan değişmedi.

## Nasıl

- `lib/features/profiles/profiles_screen.dart` → `profileListSummary`
  yeniden yazıldı, açıklaması yeni kurala göre güncellendi.
- Kalibre adı, profil düzenleme ekranının kayıtlı tüfek için gösterdiği adla
  aynı yoldan bulunur: önce `RiflePickerScreen.cartridgeName(rifle)`;
  tüfek listedeki bir tüfekse (aynı Marka + Model, ya da eski adlar için
  editörün kullandığı `ProfileCatalogMatch.rifle`), editör gibi listedeki
  varyantın kalibre adı kullanılır.
- Ad bulunamazsa (listede olmayan / elle yazılmış kalibre, PCP tüfekler)
  tüfeğin mm değeri 2 ondalık ve virgülle yazılır: "7,82 mm", "6,35 mm".
- Marka, editörün gösterdiği yazımla (liste yazımı) gelir.
- Kartın gri satırı küçük bir `ProfileRowSummary` widget'ına taşındı
  (`maxLines: 1`, `TextOverflow.ellipsis`); widget testinin en uzun adı
  gerçek kart genişliğinde ölçebilmesi için.

## Neden

Sahip kartta tüfeği tanımak için marka ve kalibreyi görmek istiyor; sıfır,
hız ve BC zaten aşağıdaki özet kartlarında var. Kalibre adı, kullanıcının
editörde gördüğü adla aynı olsun diye editörün yolu izlendi.

## Kenar durumlar

- **Liste tüfeği, modelinde kalibre yazmıyor** ("AT-X LE"):
  `cartridgeName` tek başına ad bulamaz; editör gibi liste varyantından
  ".308 Win" gelir. Sadece `cartridgeName` kullanılsaydı sahibin örneği
  "Accuracy International, 7,82 mm" çıkardı. Bu yüzden editörün varyant
  adımı da izlendi (yeni bir özellik değil, editördeki adın aynısı).
- **PCP tüfek**: kalibre adı yok → "Hatsan, 6,35 mm".
- **Marka boş** (eski kayıt): yalnız kalibre, başta virgül yok → "7,82 mm".
- **Tüfek kataloğda bulunamıyor**: satır boş kalır, kartta yalnız profil
  adı görünür (önceden de böyleydi); çökme yok, başta virgül yok.
- Kayıtlı veri değişmez; eski profiller açılır ve satırlarını gösterir.
  Satır yalnız okunur, hesaba girmez.

## Bilerek yapılmayanlar

- İlk satır (profil adı + Aktif), üst bar, alttaki özet kartları,
  Profiller başlığı / Profil ekle düğmesi (ayrı görev:
  `fix/profil-ekle-kucuk`) değişmedi.
- `cartridgeName` listesine yeni kalibre eklenmedi.

## Testler

- Yeni: `test/profil_kart_marka_kalibre_test.dart`
  - katalog tüfeği → "ATA Arms, .308 Win"
  - liste tüfeği (AT-X LE) → "Accuracy International, .308 Win"
  - listede olmayan kalibre → "Accuracy International, 7,82 mm"
  - PCP → "Hatsan, 6,35 mm"
  - marka boş → "7,82 mm"; bulunamayan tüfek → "" (çökme yok, virgül yok)
  - satırda sıfır / fps / BC yok
  - widget: `maxLines` 1, ellipsis, sola yaslı; 320 pt ve yazı ölçeği
    1.25'te "Accuracy International, .338-378 Weatherby Mag" gerçek kart
    genişliğinde tek satır, "…" ile kesik, taşma yok.
- Değiştirilen (bu işin bilerek değiştirdiği eski metin beklentileri):
  - `test/profiller_ustte_test.dart`: `profileListSummary` grubu ve
    "cards show the summary line" beklentileri yeni metne çevrildi;
    "BC without a drag model" testi silindi (satırda artık BC yok).
  - `test/pcp_muhimmat_tasarim_test.dart`: "summary shows its velocity"
    → satırda fps olmadığını kontrol ediyor.
- TDD: testler önce tek başına gönderildi ve kırmızıydı
  (test-diag 39047871785), uygulamadan sonra yeşil (test-diag 39048159903).

## Doğrulama

- `tools/claude_bootstrap_and_verify.sh`: **BLOCKED** — bu bulut ortamında
  Flutter SDK'nın Dart indirmesi (storage.googleapis.com) vekil sunucu
  tarafından engellendi (403). Yerel `flutter analyze` / `flutter test`
  çalışmadı; doğrulama GitHub Actions'ta yapıldı.
- Yerel: `python3 tools/offline_dart_lint.py` PASS;
  `python3 -m unittest discover -s tools -p 'test_*.py'` 915 test OK.

## CI ve ekran görüntüleri

- iOS CI (00155fc): verify, dart-checks, wind-acceptance başarılı:
  https://github.com/sniperTurk/flutter-app/actions/runs/39048667515
- Simülatör (sim-screens run 39059264965, ci/sim-screens 42d2c111):
  - Profil, kayıtlı profil:
    https://raw.githubusercontent.com/sniperTurk/flutter-app/42d2c111/latest/32_profil_kayitli.png
  - Kaydırılmış:
    https://raw.githubusercontent.com/sniperTurk/flutter-app/42d2c111/latest/33_profil_kayitli_2.png
- Görülen: kartın ikinci satırı "Test Marka, 6,35 mm" (ekran turunun elle
  yazılmış PCP tüfeği → marka + mm), tek satır; sıfır / fps / BC yok. İlk
  satır (Profil + Aktif), üst bar, Profil ekle ve alttaki özet kartları
  değişmedi. Bu tur yalnız bir PCP profili kaydediyor; katalog adı
  (".308 Win" gibi) ve 320 pt görünümü simülatörde yok, widget testleriyle
  ölçüldü.
