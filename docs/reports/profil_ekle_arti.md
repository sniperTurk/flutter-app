# Profil ekle: + işareti 1 harf sağa, yazı hemen yanında

İstek (sahip, 14.10.2026 08:45): "Profil ekle ve + işaretinin arasındaki boşluğu kapat ama yapışmasınlar, + işaretini soldan sağa 1 karakter al."

Bu karar, 13.10 tarihli "yazı kaymasın" isteğinin yerine geçti. O istek için yapılan çözüm (`iconShift`: yalnız + işaretini kaydırma, yazıyı yerinde tutma) bu PR'dan çıkarıldı. Telefonlarda + işaretine yer kalmadığı için o çözüm neredeyse hiç kayma vermiyordu (iPhone 15'te 0,6 pt).

## Kısa sonuç

- + işareti, main'deki yerinden **8 pt sağa** geldi. Bu, düğmenin yazı boyunda yaklaşık 1 harf.
- "Profil ekle" yazısı artık düğmenin ortasında durmuyor. + işaretinin hemen arkasından, **5 pt boşlukla** başlıyor. İkisi birlikte, düğmenin sol tarafında tek bir grup gibi duruyor. Yapışmıyorlar.
- Yazı tek satır. Sığarsa yanındaki düğmelerle aynı boyda kalıyor. Sığmazsa (önceden olduğu gibi) yalnız sığacak kadar küçülüyor.
- Kopyala, Sil, Yedekle, Geri yükle ve Hava/Basınç düğmeleri değişmedi.

## Ne değişti

- `lib/ui/menzil_widgets.dart`: `MenzilPrimaryButton`'a `iconLead` ayarı eklendi (varsayılan 0). 0 iken düğme main'deki ile birebir aynı çizilir. 0'dan büyükse düğmenin içi şöyle dizilir: sol boşluk 2 pt, `iconLead` kadar ek boşluk, + işareti (20 pt), 5 pt ara (`iconLabelGap`), yazı. Sağ boşluk 14 pt aynı kaldı.
- `lib/features/profiles/profiles_screen.dart`: yalnız "Profil ekle" düğmesine `iconLead: 8` eklendi (bir satır ve bir yorum).
- Önceki çözümün `iconShift` ayarı, ölçme kodu ve `Transform` kaydırması tamamen kaldırıldı.
- `test/profil_ekle_arti_test.dart`: yeni düzene göre yeniden yazıldı.

## Önce / sonra (düğmenin sol kenarından, pt)

| | main (önce) | bu PR (sonra) |
|---|---|---|
| + işaretinin sol kenarı | 2 | **10** (+8) |
| + işaretinin sağ kenarı | 22 | **30** |
| + ile yazı arası boşluk | 2 ile 11 arası (yazı ortalandığı için ekrana göre değişiyor) | **5** (her ekranda aynı) |
| Yazının sol kenarı | 24 ile 33 arası (ortalanmış) | **35** |
| Yazıya kalan genişlik | düğme − 38 | düğme − 49 |

Telefonlara göre hesap (yazı genişlikleri, dünkü CI ölçümünde Inter yazı tipiyle bulunan değerler; telefondaki SF yazı tipi buna yakın ama birebir aynı değil):

| Ekran | Düğme | Önce: yazının yeri | Sonra: yazının yeri | Yazı boyu |
|---|---|---|---|---|
| 320 pt (dar) | 92,0 | 24 (küçülmüş, 54 pt'ye sığdırılmış) | 35 | küçülüyor, 43 pt'ye sığdırılıyor |
| 375 pt (iPhone SE) | 110,3 | 24 (küçülmüş, 72 pt'ye sığdırılmış) | 35 | küçülüyor, 61 pt'ye sığdırılıyor |
| 393 pt (iPhone 15/16) | 116,3 | 26,6 (tam boy, ~73 pt) | 35 | biraz küçülüyor (~%92), 67 pt'ye sığdırılıyor |
| 430 pt (Pro Max) | 128,7 | 32,8 (tam boy) | 35 | tam boy |
| 700 pt (iPad gibi) | 218,7 | 77,8 (tam boy) | 35 | tam boy |

Not: + işareti 8 pt sağa geldiği ve yazı ondan 5 pt sonra başladığı için yazıya kalan yer 11 pt azaldı. Bu yüzden dar telefonlarda ve iPhone 15'te yazı önceye göre biraz daha küçük görünür. Pro Max ve daha geniş ekranlarda yazı tam boyda kalır. Yazının küçülmesi istenmezse sağdaki 14 pt boşluk azaltılabilir. Bu PR'da o boşluğa dokunulmadı, çünkü istekte yoktu.

## Neden bu yol

- İstenen düzen basit: + işareti biraz içeride, yazı hemen arkasında. Bunun en sade yolu, işaret ile yazıyı sabit boşluklarla yan yana dizmek. Önceki çözümdeki ölçme ve kaydırma kodu gerekmiyor.
- Ayar yalnız bu düğmede açık. Diğer bütün `MenzilPrimaryButton` kullanımlarında `iconLead` 0 olduğu için eski kod yolu hiç değişmeden çalışıyor.
- 5 pt boşluk, istenen 4–6 pt aralığının ortası. + simgesinin çizgisi kendi kutusunun biraz içinde bittiği için gözle görülen boşluk 5 pt'den biraz fazla olur. Bu sayede yapışık görünmez.

## Kenar durumlar

- **Dar telefon (320 pt):** yazı tek satırda kalıyor ve sığacak kadar küçülüyor. Taşma yok. Test bunu hem düğme satırında hem gerçek Profil sayfasında denetliyor.
- **Büyük yazı (1,3×):** yazı küçülerek tek satıra sığıyor. + işaretinin yeri ve 5 pt boşluk değişmiyor. Taşma yok.
- **Açık / koyu tema:** yalnız renk değişiyor, ölçüler aynı. İkisi de test ediliyor.
- **iOS "Kalın yazı":** yazı daha geniş olursa yalnız biraz daha küçülür. Yerleşim değişmez.

## Bilerek değiştirilmeyenler

- Düğmenin sol (2 pt) ve sağ (14 pt) iç boşlukları, yüksekliği, rengi ve + simgesinin boyu (20 pt).
- Yazının "tek satır, sığmazsa küçül" kuralı.
- Kopyala, Sil, Yedekle, Geri yükle, Hava Durumu'na geç ve Hava/Basınç düğmeleri.

## Hangi test neyi denetliyor

`test/profil_ekle_arti_test.dart`:

- Profil sayfasındaki düğme satırı (Profil ekle | Kopyala | Sil). Ekran genişliği 320 / 375 / 393 / 430 / 700 pt, yazı büyüklüğü 1,0× ve 1,3×, açık ve koyu tema (20 durum). Her durumda önce main düzeni (`iconLead: 0`), sonra yeni düzen (`iconLead: 8`) çiziliyor:
  - main'de + işaretinin sol kenarı düğme solu + 2 pt.
  - Yeni düzende + işareti main'e göre 8 pt (±0,5) sağda. Boyu ve yüksekliği aynı.
  - + işaretinin sağ kenarı ile yazının sol kenarı arası 4 ile 6 pt arasında (5 ± 0,5). Yani yapışık değiller.
  - Yazı tek satırda ve düğmenin içinde. Sığıyorsa tam boyda. Sığmıyorsa tam kalan yer kadar küçülmüş.
  - Profil ekle düğmesinin kendisi, Kopyala ve Sil düğmeleri ve yazıları hiç değişmemiş. Taşma ya da hata yok.
- `iconLead:` ayarı kodda yalnız `profiles_screen.dart` içinde ve tek yerde kullanılıyor.
- Gerçek Profil sayfası 320 pt genişlikte, 1,0× ve 1,3× yazıyla, koyu temada: taşma yok, "Profil ekle" düğmesinde `iconLead` 8, + işareti düğme solu + 10 pt'de, + ile yazı arası 4–6 pt.

## Yerel denetimler

- `python3 tools/offline_dart_lint.py`: GEÇTİ (326 Dart dosyası, 0 sorun).
- `python3 -m unittest discover -s tools -p 'test_*.py'`: GEÇTİ (732 test).
- Bu ortamda Flutter SDK kurulamadı (Google arşiv sunucusu 403 verdi). Flutter testleri ve analiz yalnız CI'da çalıştı.

## CI çalışmaları

Kodun son hâli eb5d15a için (bu commit'ten sonra yalnız bu rapor değişti):

- Biçimlendirme (format-fix): https://github.com/sniperTurk/flutter-app/actions/runs/38520243712 (başarılı; biçim commit'i eb5d15a dala alındı).
- Tüm testler (test-diag, files=test): https://github.com/sniperTurk/flutter-app/actions/runs/38520449815 (başarılı).
- Yeni test dosyası tek başına (test-diag): https://github.com/sniperTurk/flutter-app/actions/runs/38520454653 (başarılı).
- Analiz (analyze-diag): https://github.com/sniperTurk/flutter-app/actions/runs/38520452050 (başarılı).

Önceki deneme (f26f8c3 / b8aacca): yeni testin düğme satırı durumları kaldı. Sebep uygulamada değil, testin kendisindeydi: test, düğme satırını yüksekliği sınırlı bir alana koymuştu. main düzenindeki `Center` bu alanı doldurduğu için düğme çok uzun çıkıyordu ve + işaretinin yüksekliği karşılaştırılamıyordu. Test satırı, Profil sekmesindeki gibi kaydırılan bir sayfaya alındı ve sonra geçti. Kalan çalışma: https://github.com/sniperTurk/flutter-app/actions/runs/38519325038, analiz o turda da başarılıydı: https://github.com/sniperTurk/flutter-app/actions/runs/38519327078.

iOS CI / Simulator / TestFlight bu iş için ayrıca çalıştırılmadı. TestFlight'a gönderilmedi. Birleştirme yapılmadı. PR taslak olarak açık.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
