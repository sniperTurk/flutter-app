# Üst çubuk: aktif profil düğmesi, tema düğmesi silindi (koyu tema)

Dal: `design/ust-cubuk` · Taslak PR: #331 · Birleştirilmedi, TestFlight yok.

## Sahibin kararı (2026-10-15, İstanbul)
- 12:43 "tasarımı koyu renk yapalım… giriş yap ekranına koyu tema açık tema ekleriz, yukarısı böyle daha güzel görünüyor"
- 12:44 "kullanılmayacak kodlar silinecek"
- 20:03 ayrı görevler. Referans: `design/clean-2026-10-15` README "Ek kararlar" ve `Profil.png` (birleştirilmedi).

## Ne yapıldı
- Her sekmenin üst çubuğu: solda sayfa başlığı (Profil'de "Sniper Türk", diğerlerinde sayfa adı; değişmedi), sağda tek düğme: **profil adı (kalın)** + kalibre (gri, ör. "6,35 mm") + ⌄.
- Düğmeye dokununca bugünkü profil listesi açılır (aynı açılır liste, aynı seçim davranışı, kayıt hatasında eski seçime dönüş aynen).
- Eski "Yeni Profil ⌄" kutusu (çubuğun ortasını dolduran) ve "Koyu/Açık" düğmesi kaldırıldı.
- Tema düğmesinin kodu silindi (bayrak yok): `MenzilBarButton`, `MenzilThemeController`, `MenzilThemeScope`.
- Uygulama her zaman koyu temayla açılır (`main.dart`: `themeMode: ThemeMode.dark`).
- Eski sürümün kaydettiği tema seçimi (`theme.dark` anahtarı) silinmedi; yalnızca artık okunmuyor ve yazılmıyor.

## Nasıl
- `lib/ui/menzil_widgets.dart`: `MenzilTopBar` artık yalnız başlık + profil düğmesi alır; düğme sağa yaslı, yalnız yazısı kadar geniş. Başlık yuvası eskisi gibi sabit genişlikte, bu yüzden düğme her sekmede aynı yerde durur.
- `lib/features/home/home_screen.dart`: düğme genişliği ad + kalibre ölçülerek hesaplanır (en fazla kalan alan kadar). Önce ad "…" ile kısalır; kalibre tam kalır. Kalibre katalogdaki tüfekten gelir: "6,35 mm".
- `lib/main.dart`, `lib/ui/menzil_theme.dart`: tema denetleyicisi ve kaydı okuyan kod silindi. Açık tema renkleri (`MenzilTheme.light`) duruyor: testler ve katalog hata ekranı kullanıyor, giriş ekranına gelecek seçim için de gerekli.

## Neden
Sahip koyu tasarımı ve sade üst çubuğu onayladı; Koyu/Açık seçimi ileride giriş ekranına gelecek.

## Uç durumlar
- **Profil yok:** düğmede "Profil seç" ⌄ yazar; dokununca bugünkü gibi Profil sekmesine gider (orada "Profil oluştur" var). Yüklenirken "…".
- **Uzun ad:** düğmenin içinde "…" ile kısalır; çubuktan taşmaz.
- **Katalogla eşleşmeyen profil:** kalibre bilinmiyorsa yalnız ad görünür.
- **Dokunma alanı:** düğme en az 44 pt yüksek (boş durumda en az 44 × 44).
- **Açılan liste:** düğme genişliğinde açılır (kutudan geniş değil); uzun adlar listede de "…" ile kısalır.

## Bilerek yapılmayan
- Profil sayfası, Hedef ve diğer sayfalarda hiçbir değişiklik yok (ayrı görevler).
- Kayıtlı tema verisi silinmedi.
- Katalog hata ekranının (`CatalogStartupErrorApp`) tema ayarı değiştirilmedi (görev dışı, yalnız bozuk katalogda görünür).
- Giriş ekranı ve oradaki Koyu/Açık seçimi bu görevde yok.

## Testler
Yeni `test/ust_cubuk_test.dart`:
- Hiçbir sekmede tema düğmesi ("Tema", "Koyu", "Açık") yok; profil düğmesi her sekmede var.
- Düğme ad (kalın) + "6,35 mm" (gri) + ⌄ gösterir, kısa ad kısalmaz, yükseklik ≥ 44 pt, sağ kenar boşluğu sol boşluğa eşit.
- Dokununca profil listesi açılır, "İki" seçilince düğme "İki" ve kalibresini gösterir.
- Profil yokken "Profil seç"; Hava Durumu'ndan dokununca Profil sekmesine döner; ≥ 44 × 44.
- 320 pt dar ekran, uzun ad, yazı 1.0x ve 1.3x: beş sekmede taşma yok, düğme yuvasının içinde, ad "…" ile kısalır.
- Eski kayıt `theme.dark = false` ("Açık") olsa da uygulama koyu açılır ve kayıt yerinde kalır.

Güncellenen eski test (yalnız kaldırılan düğmeyi soran satırlar):
- `test/top_bar_fixed_slot_test.dart`: "Tema" düğmesinin sağ kenarını ölçen satır, profil düğmesinin sağ kenarını ölçecek şekilde değişti ve "Tema" düğmesinin olmadığı da denetleniyor. Başka test değişmedi.

Yerel (Flutter SDK bu ortamda indirilemedi; yalnız çevrimdışı araçlar):
- `python3 tools/offline_dart_lint.py`: PASS (380 Dart dosyası, 0 sorun)
- `python3 -m unittest discover -s tools -p 'test_*.py'`: 842 test, OK

## CI
- Format (one-off format-fix): https://github.com/sniperTurk/flutter-app/actions/runs/38778139542 — değişiklik gerekmedi.
- Test tanılama (`files=test`): https://github.com/sniperTurk/flutter-app/actions/runs/38778378826
- Analiz tanılama: https://github.com/sniperTurk/flutter-app/actions/runs/38778381959
- iOS CI (`verify`, `dart-checks`, `wind-acceptance`): PR #331 kontrolleri.
- İlk turda `ekran_boyutu_test` 375/393 pt, 1.3x yazıda kalibrenin "6,35 mm" kesildiğini buldu (https://github.com/sniperTurk/flutter-app/actions/runs/38775692455). Düzeltildi: artık önce ad kısalır, kalibre tam kalır.
- Kesin sonuçlar (yeşil/kırmızı) PR açıklamasında; yalnız gerçekten yeşil biten iş "geçti" yazılır.

🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_017RkMzKXi6H1hWVBZLTDJdB
