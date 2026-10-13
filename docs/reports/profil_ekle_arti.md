# Profil ekle: + işareti sağa, yazı yerinde

İstek (sahip, 13.10.2026 23:52): "Profil ekle + işareti 2 karakter sağa alır mısın ama yazı kaymasın."

## Kısa sonuç

- "Profil ekle" yazısı hiç kıpırdamıyor. Yeri, boyu ve tek satırı aynı kalıyor (test ±0,5 pt ile ölçüyor).
- Yalnız + işareti sağa kayıyor. Hedef 15 pt, yani bu yazı boyunda yaklaşık 2 harf.
- **Ancak telefonlarda 2 harflik yer yok.** Yazı + ile arasında en fazla birkaç puanlık boşluk bırakıyor. İsteğe uygun olarak + işareti, yazıyla arasında en az 4 pt boşluk kalacak kadar kayıyor. Ölçülen değerler aşağıdaki tabloda.

## Ne değişti

- `lib/ui/menzil_widgets.dart`: `MenzilPrimaryButton`'a yeni bir ayar eklendi: `iconShift`. Varsayılanı 0'dır ve 0 iken düğme eskisiyle birebir aynı çizilir. Ayar yalnız + işaretini sağa iter. Kayma, işaret ile yazı arasında en az 4 pt (`minIconGap`) kalacak şekilde kısaltılır.
- `lib/features/profiles/profiles_screen.dart`: yalnız "Profil ekle" düğmesine `iconShift: 15` eklendi. Bu dosyada değişen tek satır bu (ve bir yorum).
- `test/profil_ekle_arti_test.dart`: yeni test.

## + işareti nasıl kayıyor, yazı neden kaymıyor

Düğmenin içi eskisi gibi dizilir: sol boşluk 2 pt, + işareti 20 pt, ara 2 pt, kalan yerin ortasında yazı, sağ boşluk 14 pt. Yazı sığmazsa küçülür.

Yeni ayar bu dizilişe dokunmaz. + işareti, dizilişteki yerinde kalır ama **yalnız çizilirken** sağa kaydırılarak gösterilir (`Transform.translate`). Diziliş değişmediği için yazının yeri de değişmez.

Kayma miktarı çizimden önce hesaplanır. Düğmenin genişliği ve yazının kendi genişliği (aynı yazı tipi, boyut ve büyük yazı ayarıyla) ölçülür. Bunlardan yazının sol kenarı bulunur. Kayma = en çok 15 pt, ama "yazının sol kenarı − işaretin sağ kenarı − 4 pt" değerini geçmez. Yer yoksa kayma 0 olur.

## Ölçülen değerler (pt)

CI'da ölçüldü. Yazı tipi olarak telefondaki SF yerine genişliği ona yakın olan Inter kullanıldı (diğer testlerdeki gibi). Sayfa kenar boşluğu 14 pt, üç düğme yan yana.

| Ekran genişliği | Yazı büyüklüğü | Düğme | Önceki boşluk (+ → yazı) | + kayması | Sonraki boşluk | Yazının sol kenarı |
|---|---|---|---|---|---|---|
| 320 (dar telefon) | 1,0 | 92,0 | 2,0 | **0** | 2,0 | 38,00 (değişmedi) |
| 375 (iPhone SE) | 1,0 | 110,3 | 2,0 | **0** | 2,0 | 38,00 (değişmedi) |
| 393 (iPhone 15/16) | 1,0 | 116,3 | 4,6 | **0,6** | 4,0 | 40,63 (değişmedi) |
| 430 (Pro Max) | 1,0 | 128,7 | 10,8 | **6,8** | 4,0 | 46,80 (değişmedi) |
| 700 (iPad gibi geniş) | 1,0 | 218,7 | 55,8 | **15,0** | 40,8 | 91,80 (değişmedi) |
| 320 / 375 / 393 / 430 | 1,3 | 92–129 | 2,0 | **0** | 2,0 | değişmedi |
| 700 | 1,3 | 218,7 | 44,8 | **15,0** | 29,8 | 80,84 (değişmedi) |

Açık ve koyu temada değerler aynı. Tema yalnız rengi değiştiriyor.

**Sonuç:** Çoğu telefonda yazı, düğmede kendine kalan yeri zaten dolduruyor; 375 pt ve altında küçülerek sığıyor. Yazı yerinde kalırsa + işaretinin gidebileceği yer yok. iPhone 15'te kayma 0,6 pt, yani gözle görülmez. Pro Max'te 6,8 pt (yaklaşık 1 harf). Tam 2 harf (15 pt) yalnız iPad gibi geniş ekranlarda oluyor.

## Neden bu yol

- Yazının yerine kesin olarak dokunmamanın en güvenli yolu, dizilişi hiç değiştirmemek ve yalnız işaretin çizildiği yeri kaydırmak.
- Yeni ayar yalnız "Profil ekle" düğmesinde açık. Kopyala, Sil, Yedekle, Geri yükle, Hava Durumu'na geç ve Hava/Basınç düğmeleri değişmiyor. Diğer `MenzilPrimaryButton` kullanımlarında ayar 0 olduğu için eski kod yolu birebir çalışıyor.
- Sabit 15 pt kaydırmak telefonlarda + işaretini yazının üstüne bindirirdi. Bu yüzden kayma her ekranda yere göre ayarlanıyor.

## Kenar durumlar

- **Dar telefon (320 pt):** kayma 0. Taşma yok, + yazıya binmiyor.
- **Büyük yazı (1,3×):** yazı küçülerek tek satıra sığıyor, kayma 0. Taşma yok.
- **Açık / koyu tema:** ölçüler aynı. İkisi de test ediliyor.
- **iOS "Kalın yazı":** yazı genişliği kalın yazıyla ölçülüyor. Kalın yazı daha geniş olduğu için kayma azalır, bindirme olmaz.

## Bilerek değiştirilmeyenler

- Yazının yeri, boyu, küçülme kuralı ve tek satır kuralı.
- Düğmenin iç boşlukları (sol 2 / sağ 14 / ara 2). Bunlar değişseydi yazı da kayardı.
- Diğer bütün düğmeler.

## Sahibin karar vermesi gereken seçenekler

1. **+ çizgisini ölçü almak:** + simgesinin görünen çizgisi, 20 pt'lik kutusunun sağ kenarından yaklaşık 4 pt içeride biter. Kuralı kutunun değil, görünen + çizgisinin yazıya en az 4 pt uzak olması diye değiştirirsek kayma iPhone 15'te yaklaşık 4,8 pt, Pro Max'te yaklaşık 11 pt olur. Bu PR'da kutu ölçüsü kullanıldı (istekteki test kuralı: icon.right + 4 ≤ text.left).
2. **Tam 2 harf istenirse:** yazının da biraz sağa gitmesi ya da sağ boşluğun (14 pt) azalması gerekir. "Yazı kaymasın" isteği yüzünden bu PR'da yapılmadı.

## Hangi test neyi denetliyor

`test/profil_ekle_arti_test.dart`:

- 320 / 375 / 393 / 430 / 700 pt genişlikte, 1,0× ve 1,3× yazı büyüklüğünde, açık ve koyu temada (20 durum):
  - Yazının yeri önce düzenden hesaplanıyor: düğme solu + 2 + 22 + (kalan yer − yazı genişliği) / 2. Önceki ve sonraki ölçüm bu değere ±0,5 pt içinde eşit olmalı.
  - + işareti tam hesaplanan kadar kaymalı. Kayma varsa işaretin sağ kenarı + 4 pt, yazının sol kenarını geçmemeli. Kayma yoksa işaret ile yazı arasındaki boşluk aynı kalmalı.
  - Kopyala ve Sil düğmeleri ve yazıları hiç değişmemeli. Taşma ya da hata olmamalı.
- `iconShift:` ayarı kodda yalnız `profiles_screen.dart` içinde ve tek yerde kullanılmalı.
- Gerçek Profil sayfası 320 pt genişlikte, 1,0× ve 1,3× yazıyla, koyu temada: taşma yok, "Profil ekle" düğmesinde `iconShift` 15, + yazıya binmiyor.

## Yerel denetimler

- `python3 tools/offline_dart_lint.py`: GEÇTİ (326 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: GEÇTİ (732 test).
- Bu ortamda Flutter SDK kurulamadı: Google'ın arşiv sunucusuna erişim engellendi (403). Bu yüzden Flutter testleri ve analiz yalnız CI'da çalıştırıldı.

## CI çalışmaları

- Biçimlendirme (format-fix): https://github.com/sniperTurk/flutter-app/actions/runs/38472045996 (başarılı; commit dala alındı).
- Analiz (analyze-diag): https://github.com/sniperTurk/flutter-app/actions/runs/38473016156 (başarılı).
- Yeni test (test-diag, tek dosya): https://github.com/sniperTurk/flutter-app/actions/runs/38473013277 (başarılı).
- Ölçüm çıktısı için geçici çalışma (değerleri tabloya almak içindi; geçici satır geri alındı): https://github.com/sniperTurk/flutter-app/actions/runs/38473986891 (başarılı).
- Son commit için tüm testler (test-diag, files=test) ve analiz: PR açıklamasında eklenecek.

TestFlight'a gönderilmedi. Birleştirme yapılmadı. PR taslak olarak açık.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
