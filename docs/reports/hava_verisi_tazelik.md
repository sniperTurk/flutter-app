# Hava verisi tazeliği: "alındı" yalnız 30 dakika turuncu

Sahibin bildirimi (2026-10-14 11:50, TestFlight): "Uygulamayı güncelledim,
Hava Durumu'na girdim, 'Hava verisi alındı' turuncu ama tuşa bastım başka
veriler geldi." Onay 11:53: "Görev aç, güzel düzeltme — ama doğru
çalışırsa."

## Neden oluyordu

`lib/features/ballistics/ballistics_screen.dart` içinde düğmenin turuncu
olması yalnız `_weatherFilled` bayrağına bağlıydı. Bu bayrak #240 ile
profilin kayıtlı hava durumuyla birlikte saklanıyor, ama verinin **ne
zaman** alındığı saklanmıyordu. Bu yüzden saatler, günler önce alınmış
veri de "Hava verisi alındı" diye turuncu görünüyordu. "Basınç alındı"
(`_pressureFilled`) için de aynısı geçerliydi.

## Ne değişti

- `lib/services/shot_settings_store.dart`: `ShotSettings` iki yeni alan
  aldı: `weatherFetchedAtMs` (JSON anahtarı `weatherGpsAt`) ve
  `pressureFetchedAtMs` (`pressurePhoneAt`). İkisi de alımın UTC epoch
  milisaniyesi. Eski kayıtlarda bu alan yok; o zaman değer `null` olur ve
  veri **eski** sayılır. Bozuk değer (yazı, 0, negatif, kesirli, NaN) da
  `null` olur.
- `lib/features/ballistics/ballistics_screen.dart`:
  - "Konumdan canlı hava verisi al" başarılı olunca, "Basıncı telefondan al"
    başarılı olunca o anın saati saklanır. Değerler aynı geldiyse de
    (kutudaki yazı değişmese de) yeni saat kaydedilir.
  - Sekmeler arasında taşıyan `EnvironmentCarry` da bu iki saati taşır;
    sekme değiştirmek eski veriyi yeni göstermez.
  - Saat kaynağı mevcut `Clock` soyutlaması (`ToolsServices.clock`).
    Testler `TestClock` ile zamanı ileri/geri alır.

## Tazelik nasıl hesaplanıyor

- Taze = `0 ≤ şimdi − alım zamanı ≤ 30 dakika`. Tam 30. dakika hâlâ taze,
  30 dakika 1 saniye eski.
- Alım zamanı gelecekteyse (telefonun saati geri alındıysa), veri eski
  sayılır.
- Hava düğmesi turuncu olmak için ayrıca eski koşulu korur: Sıcaklık ve
  Bağıl nem boş değil ve kullanıcı bunları elle değiştirmedi.
- Sayfa açıkken: en yakın 30 dakika sınırına tek bir `Timer` kurulur. Sınır
  geçince sayfa yeniden çizilir, sonraki sınır için yeni zamanlayıcı
  kurulur. Zamanlayıcı `dispose` içinde iptal edilir.
- Uygulama arka plandan dönünce (`WidgetsBindingObserver`, `resumed`)
  tazelik hemen yeniden hesaplanır. Sahibin durumu buydu: güncellemeden
  sonra geri dönmek.

## Etiketler

| Durum | Hava düğmesi | Basınç düğmesi |
|---|---|---|
| Taze (≤ 30 dk) | turuncu, ✓, "Hava verisi alındı · 11:20" | turuncu, ✓, "Basınç alındı · 11:20" |
| Eski (> 30 dk, saat yok, saat ileride) | normal, ↻, "Hava verisi eski · Yenile" | normal, ↻, "Basınç eski · Yenile" |
| Hiç alınmadı / elle değiştirildi | "Konumdan canlı hava verisi al" | "Basıncı telefondan al" |
| Sıfırla sonrası | "Tekrar canlı konum verisi al" (eskisi gibi) | "Basıncı telefondan al" (eskisi gibi) |

Saat, telefonun yerel saatiyle 24 saat düzeninde gösterilir (İstanbul'da
"11:20"). Turuncu yazı tek satırdır; sığmazsa bugünkü gibi küçülür. Eski
durumdaki düğmeye basınca veri bugünkü gibi yeniden alınır. Kutulardaki
değerler, yenilenene ya da elle değiştirilene kadar **silinmez**.

## Uç durumlar

- **Yeniden başlatma:** Saat kayıtla birlikte saklanır. 10 dakika sonra
  açılırsa "alındı · 11:20" görünür, saatler sonra açılırsa "eski".
- **Eski kayıt (saat alanı yok):** "eski · Yenile". Değerler yerinde kalır.
- **Saat değişikliği:** Telefon saati geri alınırsa (alım zamanı ileride
  kalırsa) "eski" görünür. İleri alınırsa doğal olarak 30 dakika geçmiş
  olur ve yine "eski" görünür.
- **Gece yarısı:** 23:50'de alınan veri 00:10'da hâlâ "alındı · 23:50",
  00:21'de "eski". Hesap epoch milisaniyeyle yapıldığı için gün değişimi
  etkilemez.
- **Elle değiştirilen değer:** Eski kural aynen geçerli. Sıcaklık ya da
  Bağıl nem yazılınca hava düğmesi turuncu olmaz; Basınç ya da İrtifa
  yazılınca basınç düğmesi turuncu olmaz.
- **Sıfırla:** Davranışı değişmedi (kutuları boşaltır, "Veriler
  sıfırlandı" görünür).
- **Çevrimdışı:** Yenileme başarısız olursa saat değişmez, düğme "eski ·
  Yenile" olarak kalır, değerler yerinde durur, hata notu bugünkü gibi
  gösterilir.
- **İki düğme:** Her birinin saati ayrıdır; biri eskiyince diğeri taze
  kalabilir.

## Bilerek değiştirilmeyenler

- Hangi değerlerin çekildiği, MET Norway çağrısı, telefondan basınç okuma
  mantığı, F1 irtifadan basınç mantığı (#295) ve diğer sayfalar.
- Hedef/Atış: Kodda "hava verisi alındı" ya da "güncel" diyen bir yazı
  yok. Bu yüzden orada değişiklik yapılmadı.
- Düğmenin altındaki bilgi notu ("Hava verisi konumdan dolduruldu (…,
  HH:mm)") yalnız o oturumda alım yapılınca çıkıyor ve zaten saati
  içeriyor. Dokunulmadı.

## Testler

- Yeni dosya `test/hava_verisi_tazelik_test.dart` (sahte saatle):
  - Kayıt: saat alanları kaydedilip geri okunuyor; eksik ya da bozuk saat
    `null` oluyor.
  - Hava: 11:20'de alım → turuncu "Hava verisi alındı · 11:20" (tek satır,
    ✓); +29 dk hâlâ turuncu; +31 dk sayfanın kendi zamanlayıcısıyla
    (dokunmadan) "Hava verisi eski · Yenile", ↻ simgesi, değerler aynı;
    düğmeye basınca yeniden alınıyor ve "· 11:51" turuncu.
  - Tam 30 dk taze, 30 dk 1 sn eski.
  - Yeniden başlatma: saat kaydediliyor; 10 dk sonra turuncu, 3 saat sonra
    eski.
  - Saatsiz eski kayıt → eski. 10 dk önceki kayıt → turuncu "· 11:10".
  - Saat geri alınmış (kayıtta gelecek zaman) → eski. Sayfa açıkken saat
    geri alınıp uygulamaya dönülünce → eski.
  - Sıcaklık yazılınca turuncu değil.
  - Arka plandan 31 dk sonra dönüş: dönmeden önce ekran değişmiyor,
    dönünce dokunmadan "eski" oluyor.
  - Gece yarısı (23:50 → 00:10 taze, 00:21 eski).
  - Sıfırla davranışı aynı. Çevrimdışı yenileme "eski"yi ve değerleri
    koruyor.
  - Sayfa kapanınca zamanlayıcı kalmıyor (flutter_test bekleyen Timer'ı
    hata sayar).
  - Basınç için aynı set: alım, +29, +31, yeniden okuma, yeniden başlatma,
    saatsiz kayıt, gelecek saat, elle Basınç, arka plandan dönüş. Ayrıca
    iki düğmenin ayrı saatleri.
  - Dar ekran (320 pt) ve yazı ölçeği 1.3'te taşma yok; "alındı · HH:mm"
    tek satır.
  - Ana ekranda sekme geçişi (Hava Durumu → Hedef → geri) saati koruyor;
    35 dk sonra "eski".
- Güncellenen testler: `test/fetch_reset_buttons_test.dart` ve
  `test/kutu_fikir4_test.dart` artık "· 11:20" ekli yazıyı bekliyor
  (sahte saat yerel 11:20).
- `integration_test/sim_screens_test.dart` ve
  `integration_test/barometre_screens_test.dart` bu yazıları aramıyor;
  değişiklik gerekmedi.
- Yerel: `python3 tools/offline_dart_lint.py` geçti (332 dosya, 0 sorun).
  `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (740 test).
  Bu ortamda Flutter SDK yok (ağ erişimi kapalı), Dart testleri yalnız
  CI'da koştu.

## CI

CI_SONUCLARI

iOS CI / verify, Simulator ve TestFlight bu işte **koşturulmadı**; geçti
denmez.

---
_Generated by [Claude Code](https://claude.ai/code)_
