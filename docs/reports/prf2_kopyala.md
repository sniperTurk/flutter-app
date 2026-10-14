# PRF-2: Kopyala artık bağımsız kopya yapıyor

Dal: `fix/prf2-kopyala` (#311 birleştikten sonraki güncel main'den). Bulgu: ön TestFlight denetimi PRF-2 (yüksek), PR #310, `docs/reports/denetim_testflight_2026_10_14b.md`.

## Sorun ve sebebi

- Profiller → ⋯ → **Kopyala**, yeni profile asıl profilin **aynı** tüfek, mühimmat ve dürbün kayıt kimliklerini veriyordu.
- Profili Düzenle, elle girilmiş (listede olmayan) bir kaydı kaydederken **aynı kimliğin üstüne** yazıyordu.
- Sonuç: kopyada BC 0,1 → 0,12 yapılınca asıl profilin BC'si de 0,12 oluyordu; asıl profilin düşüş ve rüzgâr sayıları değişiyor, eski BC kayboluyordu.

## Düzeltme

1. **Kopyala** (`_duplicate`): kopyanın elle girilmiş tüfek, mühimmat ve dürbün kayıtları **yeni kimlikle** kopyalanıyor (kayıttaki her alan aynen, yalnız kimlik yeni). Liste (katalog) kayıtları salt okunur; kopya onların katalog kimliğini aynen kullanıyor. Kayıtlar yazılamazsa kopya oluşturulmuyor ve bugünkü "Profil kopyalanamadı. Mevcut kayıtlar korunuyor." uyarısı çıkıyor.
2. **Profili Düzenle** (`_rifleEntry` / `_ammoEntry` / `_scopeEntry`): elle girilmiş bir kayıt **başka bir profilde de kullanılıyorsa**, Güncelle (ya da yeni profilde Kaydet) onu yerinde değiştirmiyor; düzenlenen profil için yeni kimlikle yazıyor. Kaydı yalnız bu profil kullanıyorsa bugünkü gibi yerinde güncelleniyor.

Kopya adı ("… (kopya)"), ⋯ menüsü (#309), sayfa düzeni ve hesap değişmedi. Hiçbir şey silinmedi; yeni gizli bayrak yok.

## Kayıtlı veriye etkisi

- Mevcut kayıtlar açılışta değiştirilmiyor, taşınmıyor, silinmiyor.
- Bu düzeltmeden önce yapılmış kopyalar (ya da aynı kaydı paylaşan eski profiller) bugünkü gibi çalışmaya devam ediyor. Bunlardan biri **ilk kez Güncelle ile kaydedilince** ayrılıyor: düzenlenen profil kendi kaydını alıyor, diğer profil eski kaydı ve eski değerleriyle kalıyor.
- Ayrıldıktan sonra o profilin kaydı yalnız ona ait; sonraki düzenlemeler yerinde güncelleniyor.

## Uç durumlar

- Paylaşılan kayıtlı bir profilde hiçbir şey değiştirmeden Güncelle'ye basmak da ayırır (değerler aynı kalır, yalnız yeni kimlikli bir kayıt yazılır).
- Kopya silinince asıl profil ve kayıtları yerinde kalır. Kopyanın kayıtları da kişisel katalogda kalır (bugün profil silmek kayıt silmiyor; bu değişmedi).
- Profilin gösterdiği kayıt kişisel katalogda yoksa (silinmiş/eksik kimlik) Kopyala o kimliği aynen taşır; yerine başka kayıt koymaz.
- **Yapılmayan:** Atış Doğrulama (Truing) aracının "Mühimmata kaydet" düğmesi mühimmat kaydını yine yerinde günceller. Yeni kopyalar artık kayıt paylaşmadığı için bu kopyaları etkilemez; ama düzeltmeden önce kayıt paylaşan iki eski profilden birinde kullanılırsa diğeri de değişir. İstenmediği için dokunulmadı; ayrı görev olabilir.

## Testler

Yeni dosya `test/audit_2026_10_14b/prf2_kopyala_test.dart`:

- Denetimin PRF-2 testi (#310 dalından) **skip'siz** kopyalandı: eski usul (aynı kimlikli) kopyada BC 0,12 → asıl profil 0,1 kalıyor.
- Kopyala → elle girilmiş üç kayıt yeni kimlikte, kopyanın tüm hesap girdileri asılla aynı; kopyada BC 0,12 → asıl profilin tüm hesap girdileri ve kaydı değişmedi.
- Kopyala → kopyada tüfek Model ve dürbün Marka (elle girilmiş) değişti → asıl profil aynı.
- Katalog dürbünü olan profil kopyalanınca katalog kimliği aynen kalıyor; katalog için kişisel kayıt yazılmıyor.
- Aynı elle girilmiş mühimmatı paylaşan iki eski profil: biri düzenlenince diğeri aynı; ayrılan profilin sonraki düzenlemesi yerinde güncelleniyor.
- Kaydı yalnız bir profil kullanıyorsa yerinde güncelleniyor (kimlik aynı).
- Kaydet → yeniden aç: kopya 0,12, asıl 0,1 gösteriyor; değiştirmeden Güncelle değerleri korur.
- Kopya silinince asıl profil ve kayıtları aynen kalıyor.

Yerel (bu ortamda Flutter SDK indirilemedi, Flutter testleri yalnız CI'da koşar):

- `python3 tools/offline_dart_lint.py` → 0 sorun
- `python3 -m unittest discover -s tools -p 'test_*.py'` → 743 test geçti

## CI

Kod commit'i `1fb0eb9` üzerinde:

- Biçim (dart format): değişiklik gerekmedi — https://github.com/sniperTurk/flutter-app/actions/runs/38612208492 (ilk biçim commit'i `c286476`: https://github.com/sniperTurk/flutter-app/actions/runs/38608990669)
- Testler (`test` klasörünün tamamı, `profil_duzen_koruma_test.dart` dahil): başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38613101750
- Analiz (`--fatal-infos --fatal-warnings`): başarılı — https://github.com/sniperTurk/flutter-app/actions/runs/38613106694
- İlk test koşusu (`c286476`) 3 testte kırmızıydı ve düzeltildi: Kopyala, kişisel kaydı olmayan profilde de kişisel kataloğu okumaya çalışıyordu (iki eski Kopyala testi); yeni gidiş-dönüş testi editörün hız yuvarlamasını (285 → 284,988 m/s) hesaba katmıyordu — https://github.com/sniperTurk/flutter-app/actions/runs/38609375206

PR'ın kendi kontrolleri (`verify`, `dart-checks`, `wind-acceptance`) PR sayfasında.

## Birleştirme

Sonuç PR yorumunda ve PR açıklamasında.

iOS CI, Simulator, TestFlight ve App Store çalıştırılmadı.
