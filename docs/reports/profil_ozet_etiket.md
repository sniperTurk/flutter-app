# Profil özeti: başlıklar kaldırıldı, Marka/Model etiketleri

Sahip isteği (2026-10-17 06:08, onay 06:08): Profil sayfasındaki üç özet kartın başlıkları kaldırılsın, kartların ilk satırı adını taşısın.

## Ne
- "Tüfek bilgileri", "Dürbün bilgileri", "Mühimmat bilgileri" başlıkları silindi.
- Kartların ilk satır etiketi "Marka / Model" yerine: **Tüfek Marka/Model**, **Dürbün Marka/Model**, **Mühimmat Marka/Model**.
- Başka metin, değer, sıra, kart veya alan değişmedi.

## Nasıl
- Yalnızca `lib/features/profiles/profile_summary.dart`: üç `MenzilSectionHeader` silindi; Dürbün ve Mühimmat kartlarının önüne `SizedBox(height: MenzilSpace.lg)` kondu.
- Kartlar arası boşluk **14 pt** (`MenzilSpace.lg`): profil listesi ile ilk kart arasındaki boşlukla aynı.

## Neden
Kartın ne olduğu artık ilk satırda yazıyor; ayrı başlık tekrar oluyordu.

## Uç durumlar
- Tüfek veya mühimmat kaydı bulunamazsa o kartta Marka/Model satırı zaten çıkmıyordu; böyle kalıyor (kart diğer satırlarla görünür).
- Kayıtlı kullanıcı verisine dokunulmadı; yalnızca ekran metni değişti.

## Testler
- Yeni `test/profil_ozet_etiket_test.dart` (gerçek Profil sayfası, tüfek+dürbün+mühimmatlı profil): başlıklar yok, "Marka / Model" yok, üç yeni etiket kendi kartında ve ilk satırda, kartlar arası 14 pt; 390 pt ×1.0 ve **320 pt ×1.3** taşma yok.
- Güncellendi: `profile_summary_order_test` (sıra yeni etiketlerle, başlıkların yokluğu eklendi), `profiller_ustte_test` (konum karşılaştırması yeni etiketle), `hava_basliklar_test` (Hava Durumu başlıkları 18 pt; Profil başlığı artık yok, 18 sabit karşılaştırılıyor).
- Yerel: `python3 tools/offline_dart_lint.py` → PASS (415 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` → OK (1 atlanan). Yerelde Flutter SDK yok; Flutter testleri CI'da koştu.

## Ekran görüntüsü (Simulator, iPhone 17 Pro, iOS 26.2, 390 pt)
- [Üç kart birlikte](https://github.com/sniperTurk/flutter-app/blob/54346cf1d8bc7394ff0abb0b73760d60b4a7acf5/latest/02_profil_390_durbun.png)
- [Liste + kartlar](https://github.com/sniperTurk/flutter-app/blob/54346cf1d8bc7394ff0abb0b73760d60b4a7acf5/latest/03_profil_390_muhimmat.png)
- [Tüfek kartı](https://github.com/sniperTurk/flutter-app/blob/54346cf1d8bc7394ff0abb0b73760d60b4a7acf5/latest/01_profil_390_tufek.png)

Simulator ekran görüntüsü iş akışı: https://github.com/sniperTurk/flutter-app/actions/runs/38999267137 (başarılı, 3 görüntü, 0 hata)

## CI linkleri
- iOS CI (verify, dart-checks, wind-acceptance başarılı; ios-simulator atlandı): https://github.com/sniperTurk/flutter-app/actions/runs/38998388785
- Test tanılama (tüm `test/`): https://github.com/sniperTurk/flutter-app/actions/runs/38998104602 (başarılı)
- Analyze tanılama: https://github.com/sniperTurk/flutter-app/actions/runs/38998106180 (başarılı)
- Dart format: https://github.com/sniperTurk/flutter-app/actions/runs/38998103228 (başarılı, değişiklik gerekmedi)

## Yapılmayanlar
- TestFlight yok; birleştirme yok (taslak PR).
- PR #367 henüz birleşmedi; main değişmedi, rebase gerekmedi. #367 önce birleşirse çakışma bu dosyada çıkabilir.
