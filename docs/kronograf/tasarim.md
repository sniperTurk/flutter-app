# Kronograf serisi (Ö3) ve Mühimmat sıcaklığı (Ö1) — tasarım

Tarih: 2026-10-12 · Dal: `feat/kronograf` · Kaynak: PR #153
(`docs/yeni-hesaplar-2026-10-11.md`, Ö3, Ö1, bölüm 5–6).

## Amaç

İlk atışta isabet için namlu hızının ölçülmüş olması gerekir. Atıcı kronograf
hızlarını girer; uygulama ortalama, SD, ES ve n'yi hesaplar; ortalamayı
profile, SD'yi WEZ'e (Pro > "Hız farkı (SD)") onayla aktarır. Farklı
sıcaklıklarda kaydedilen serilerden barut sıcaklık katsayısı (k, T0) ölçülür.
Bu katsayı varsa Hava Durumu'ndaki Mühimmat sıcaklığı hızı düzeltir.

## Ana oturumun düzeltmesi (bağlayıcı)

Ö1'in etkisi barut tipine çok bağlıdır (kararlı barut ~0,14 fps/°F → .308
800 m'de 15 °C farkla ~3 cm; duyarlı barut 1,5–2 fps/°F → ~28 cm). Fabrika
fişeklerinin çoğu katsayı yayımlamaz. Bu yüzden:

- Önce Ö3 (katsayıyı ölçümden bulmak), sonra Ö1.
- Katsayı yoksa düzeltme uygulanmaz. Uydurma varsayılan katsayı YOK
  (`PowderTemperature.factor` k = null iken 1 döndürür; aynen kalır).

## Sahip yok: verdiğim kararlar (varsayımlar)

1. Kronograf, Araçlar'a yeni kart olarak gelir (anahtar `tool-chrono`).
   Eski ses tabanlı Kronograf 2026-10-09'da kaldırılmıştı; bu, sahibin
   "raporun tamamı geliştirilsin" isteğiyle gelen, elle girişli yeni sayfadır.
   Eski `tool-chronograph` anahtarı geri gelmez.
2. Sayfa aktif profille çalışır (Hız Doğrulama ile aynı); profil seçimi
   Profil sekmesinde yapılır. Ayrı profil listesi eklenmez (YAGNI).
3. Satırlar: `Hız birimi | Mühimmat sıcaklığı` (ateşli); PCP'de yalnız
   `Hız birimi` (PCP'de barut yok; PCP sıcaklık/basınç işi paralel görevde).
   `Hızlar` tam satır, çok satırlı; her satıra bir hız.
4. Ayırıcılar: satır sonu, boşluk, `;`. Virgül ondalıktır ("812,4").
   Geçerli hız 50–1500 m/s; dışı/okunamayan satır numarasıyla reddedilir.
5. SD örnek standart sapmasıdır (n − 1; NIST/SEMATECH e-Handbook 1.3.5.6).
   n < 3 iken SD gösterilmez ve aktarılamaz. ES = en büyük − en küçük.
6. Profile hız aktarımı: profil hızı, katsayının ölçüm sıcaklığındaki hızdır.
   Profilde katsayı varsa ortalama `PowderTemperature.factor` ile ölçüm
   sıcaklığına geri çevrilir; bunun için Mühimmat sıcaklığı zorunludur
   (boşsa açık uyarı, yazım yok). Katsayı yoksa ortalama olduğu gibi yazılır.
   Profil hızı daima fps gösterilir (sahip kuralı).
7. SD aktarımı `ShotSettings.sdText`'e fps olarak (mevcut alan fps) yazılır;
   diğer Pro ayarları korunur.
8. Barut katsayısı: ateşli tüfekte "Seriyi kaydet" (n ≥ 3 ve Mühimmat
   sıcaklığı dolu) seriyi profil başına saklar. En az iki seri, sıcaklık
   açıklığı ≥ 10 °C ise n ağırlıklı en küçük karelerle doğru uydurulur
   (NIST/SEMATECH 4.1.4.1, ağırlıklı EKK 4.1.4.3): eğim b (m/s/°C);
   T0 = ağırlıklı ortalama sıcaklık; v0 = T0'daki hız (ağırlıklı ortalama);
   k = b·15/v0·100 (%/15 °C). |k| > `PowderTemperature.maxCoef` reddedilir.
   "Katsayıyı profile aktar" k, T0 ve v0'ı birlikte yazar (tutarlılık için;
   onay penceresi eski → yeni gösterir).
9. Kayıtlı seriler listelenir; her biri kullanıcı tarafından silinebilir
   (yanlış seri katsayıyı bozmasın). Profil silinince serileri de silinir.
10. PCP dizi eğimi: atış sırasına göre doğrusal regresyon eğimi
    (m/s/atış), yalnız PCP ve n ≥ 5. Sonuç satırı "Dizi eğimi" ve toplam
    düşüş ("ilk N atışta hız X m/s düştü" eşdeğeri: eğim × (n − 1)).
11. Ö1: yalnız ateşli tüfekte Hava Durumu > Atmosfer'de
    `Sıcaklık | Mühimmat sıcaklığı` aynı satırda; ardından
    `İstasyon basıncı | Bağıl nem`, `İrtifa`. PCP'de satırlar bugünkü gibi.
    Değer profil başına `ShotSettings.ammoTempText` (JSON `ammoTemp`) olarak
    saklanır. Boş/okunamaz/−50..60 °C dışı → hava sıcaklığı (bugünkü
    davranış). Birim Sıcaklık ile aynı (°C/°F).
12. Hız Doğrulama sayfası değişmez (kendi hava alanları var; Atış'ın
    kayıtlı mühimmat sıcaklığını oradan okumak eski değer taşıyabilir).
    Bu bilinçli bir sınır olarak PR'da yazılır.

## Birimler

- `lib/core/velocity_series.dart` (saf): `VelocitySeries.parse`, istatistik,
  `slopePerShot`, `fitPowderCoefficient`.
- `lib/services/chrono_store.dart`: `ChronoSession`, `ChronoStore`
  (SharedPreferences, anahtar `sniper_turk.chrono.<profilId>`, bozuk veri →
  boş liste).
- `lib/features/tools/chrono_field_info.dart`: ⓘ metinleri.
- `lib/features/tools/chrono_screen.dart`: sayfa.
- `PowderTemperature.effectiveTempC` (yeni saf fonksiyon) ve
  `ShotSettings.ammoTempText`; `ballistics_screen.dart`'ta tek alan.
- `ToolProfileUpdate.apply`'a isteğe bağlı k / T0 (aynı doğrulamadan geçer).

## UI kuralları

Kısa Türkçe; her girilen değerde ⓘ; kutu altında yardım yazısı, kutu içinde
örnek değer (hintText), etikette parantez, kalın yazı yok; liste kutuları
"Seçiniz" ile başlar; iki kutu yan yana; Oswald; ayrı aç/kapa düğmesi yok.
`MenzilInput`'a çok satır için isteğe bağlı `minLines`/`maxLines` eklenir
(varsayılan 1, mevcut kullanım değişmez).

## Test

- Saf: parse (ayırıcılar, virgül, hatalı satır numarası, birim), mean/SD/ES,
  n < 3 → SD yok, eğim, katsayı uydurma (örnek 5 °C 790 / 35 °C 814 →
  k ≈ 1,496, T0 20, v0 802), tek sıcaklık / dar açıklık / aşırı k → null,
  `effectiveTempC`.
- Depo: ekle/yükle, bozuk JSON, profil silme.
- Widget: istatistik kartı; profile aktarım (katsayılı/katsayısız, fps/m/s);
  SD aktarımı; PCP'de katsayı yok, eğim var; Araçlar'da kart.
- Ö1: ateşli profilde alan var, PCP'de yok; katsayılı profilde mühimmat
  sıcaklığı hızı değiştirir; alan boşken ve katsayı yokken sonuçlar
  değişmez (DOPE tablosu birebir aynı); ayar kaydı/yüklemesi.
