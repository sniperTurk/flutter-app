# Mermi uzunluğu sınırı 150 mm (D17D-1)

Sahip, 2026-10-17 17:42 (İstanbul): "çıkart" (denetim PR #386, bulgu D17D-1, ORTA: profil kutusu 60 mm'de kesiyordu, hesap 100 mm'ye kadar alıyordu).
Sahip, 2026-10-17 18:10 (İstanbul): "Uzun menzil atan silahların mermileri uzun olabiliyor ama ben tam rakamı bilmiyorum. 150 mm yap sınırı."

## Ne
Mermi uzunluğu üst sınırı her yerde 150 mm. Profil → Mühimmat → Mermi uzunluğu kutusu 1–150 mm kabul ediyor (önce 1–60, bu PR'ın ilk halinde 1–100). Hesap da aynı sınırı kullanıyor: 0'dan büyük, en çok 150 mm. Böylece kutunun kaydettiği her uzunluk hesapta kullanılır; kutu ile hesap birbirini tutar.

## Nasıl
Sınırın uygulandığı yerler (kodda `lengthMm` / `bulletLength` / `ammoLength` arandı, 60 ve 100 sınırlarına bakıldı):

1. `lib/features/profiles/profile_editor.dart` `_lengthError`: `_rangeError(ammoLength, 1, 100)` → `_rangeError(ammoLength, 1, 150)`. Alt sınır 1 mm aynı.
2. `lib/features/ballistics/ballistics_screen.dart` `_bulletLengthMm`: `v > 0 && v <= 100` → `v > 0 && v <= 150`. Alt sınır (0'dan büyük) aynı. Bu tek getter hem profildeki uzunluğu hem eski sürümün Pro'ya yazdığı uzunluğu (`bulletLength`) süzer; Sg, spin drift ve rüzgâr sıçraması buradan beslenir.

Başka sınır yok, değişmedi:
- `lib/core/stability.dart` (Miller Sg, `lengthCalibers`): sınır yok, yalnız formül.
- `lib/services/manual_catalog_store.dart`: `lengthMm` yalnız "sayı, sonlu, 0'dan büyük" diye denetlenir, üst sınır yok.
- `lib/data/user_catalog.dart`, `ProfileCodec`, `ShotSettingsStore`: uzunluğu olduğu gibi okur/yazar, kısmaz.
- Araçlar (`lib/features/tools/`) ve `tools/` Python: mermi uzunluğu sınırı yok (bulunan "0–100" metinleri nem için).
- Eski Pro Mermi uzunluğu kutusu ekranda artık yok; değeri yalnız yukarıdaki getter'dan okunur.

## Neden
Sahip uzun menzil mermilerinin tam boyunu bilmiyor; 150 mm bilinen uzun mermileri rahatça kapsar. Profil kutusu ile hesap aynı sınırı kullanmazsa kaydedilen değer sessizce yok sayılırdı.

## Uç durumlar
- 150,1 ve 999: Kaydet/Güncelle kapalı, kutunun altında bugünkü biçimde hata: "1–150 arasında bir değer girin."
- 0 ve 0,5: yine reddedilir (alt sınır değişmedi). Boş: yine isteğe bağlı.
- 150 tam: kabul edilir ve hesapta kullanılır.
- 31,2 gibi eski değerler aynen kaydedilir ve aynı sayıyı verir; kayıtlı veri değişmez.
- Eski sürümde Pro'ya 100 ile 150 mm arası yazılmış bir değer varsa (o kutu 100 mm'ye kadar alıyordu, bu yüzden pratikte yok) artık hesapta kullanılır; 150 mm üstü (elle düzenlenmiş kayıt) hâlâ kullanılmaz, uzunluk yokmuş gibi spin drift hesaplanmaz.
- Çok uzun mermide Miller Sg çok küçülür (ör. 7,62 mm, 168 gr, 1:10, 150 mm ≈ 0,02); formül değişmedi, sonuç formülün verdiğidir.

## Bilerek yapılmayan
ⓘ metni, etiket, düzen, formül ve alt sınırlar değişmedi. Görsel değişiklik yok (yalnız hata metnindeki sayı 100 → 150), bu yüzden ekran görüntüsü yok.

## Testler
- `test/mermi_uzunlugu_profil_test.dart`:
  - "1–150 mm dışı kaydı engeller": 150,1 / 999 / 0,5 / 0 → Güncelle kapalı ve "1–150 arasında bir değer girin." görünür; 1 / 31,2 / 60 / 62 / 70 / 100 / 120 / 150 → açık, hata yok.
  - Editörde 62, 100, 120, 150 ve 31,2 mm kaydedilir (`lengthMm` aynen).
  - Hesap: profil 62, 100, 120, 150 mm ile spin drift satırı çıkar, sonuç eski Pro'daki aynı değerle aynı sayıdır; 31 → 62 → 100 → 120 → 150 sırasıyla gerekli sağ düzeltme kesin artar (uzun mermi daha az kararlı, spin drift küçülür). Ayrıca farkların oranı Miller'in uzunluk terimi 1 / (l·(1+l²)) ile birebir karşılaştırılır (Sg'nin uzunlukla formülün dediği gibi değiştiğinin kanıtı; tolerans %0,01).
  - Yeni: 150,1 ve 999 (eski Pro kaydı) ve profilde 150,1 → hesapta kullanılmaz; 150 kullanılır.
- `test/audit_2026_10_17d/mermi_uzunlugu_denetim_test.dart` "D17D-1": değişmedi, 62 mm kaydı ve hesapta kullanımı doğrular; yeni sınırla da geçmesi beklenir.
- Hiçbir test zayıflatılmadı veya silinmedi; eski testlerdeki tüm değerler duruyor, yalnız 100 sınırına ait beklentiler 150'ye taşındı.
- Yerel: `python3 tools/offline_dart_lint.py` PASS (434 dosya, 0 sorun); `python3 -m unittest discover -s tools -p 'test_*.py'` 915 test OK (1 skip, önceden de vardı). Flutter SDK bu ortamda yok; Flutter testleri yalnız CI'da çalışır.

## CI linkleri
Commit d20e027 üzerinde:
- iOS CI (`verify` success, `dart-checks` success, `wind-acceptance` success; `ios-simulator` atlandı, otomatik değil): https://github.com/sniperTurk/flutter-app/actions/runs/39044292355
- Test diag (`flutter test test`, tümü): success — https://github.com/sniperTurk/flutter-app/actions/runs/39044297219
- Analyze diag: success — https://github.com/sniperTurk/flutter-app/actions/runs/39044299432
- Dart format fix: success, biçim değişikliği gerekmedi — https://github.com/sniperTurk/flutter-app/actions/runs/39044295374

Bu commit yalnız raporu günceller (CI linkleri); kodu değiştirmez.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
