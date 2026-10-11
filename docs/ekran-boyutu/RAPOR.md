# Ekran boyutu denetimi (2026-10-11)

Dal: `fix/ekran-boyutu`. Amaç: taşan yazı, kesilen kutu, üst üste binen öğe,
kaydırılamayan alan ve RenderFlex overflow aramak.

> Not: Denetim sırasında main'de yazı tipi Oswald'dan **Inter**'e geçti
> (#173). Tarama ikisiyle de yapıldı; aşağıdaki "Inter" sütunu güncel
> durumdur. Görevdeki "font Oswald kalır" kuralı main'deki bu karara göre
> uygulanmadı: yazı tipine dokunulmadı.

## Nasıl ölçüldü

- `test/ekran_boyutu_test.dart` (Linux widget testi, Mac kuyruğu kullanılmadı).
  Her boyutta Profil, Hava Durumu, Pro, Hedef (Tek atış ve Tablo + DOPE),
  Araçlar sekmeleri, Araçlar'daki 8 aracın her biri ve Profil formu (yeni ve
  düzenle) açılır; her sayfa sonuna kadar kaydırılır.
- Boyutlar: küçük **iPhone SE 2/3 375x667**, normal **iPhone 15/16 393x852**,
  büyük **iPad 820x1180** ve **iPad Pro 13 1032x1376**. Telefonlarda yazı
  1.0x ve 1.3x (iOS büyük yazı) denendi.
- Golden yok. Yakalanan: her RenderFlex overflow / çizim hatası ve uygulama
  yazısının `…` ile kesildiği her yer (`didExceedMaxLines`). Bunlar testi
  kırar; bilerek kesilen iki metin ve sahibinin kararını bekleyen bir bulgu
  (#5) hariç.
- Testte uygulamanın gömülü yazı tipi (`MenzilType.family`, şu an Inter)
  yüklenir. Flutter'ın varsayılan test yazı tipi her harfi kare çizer; onunla
  çıkan uyarılar cihazda olmayan yanlış alarmlardır ("Yalnız test yazı
  tipinde" bölümü).
- Görsel kontrol: simülatör turu (iPhone 17 Pro, 402 pt) görüntüleri
  incelendi; sim-screens bu dal için bir kez çalıştırıldı (Oswald döneminde).

Uygulama yalnız iPhone için yayınlanıyor (`TARGETED_DEVICE_FAMILY = 1`); iPad
boyutları yine de denendi: kesik ya da taşma yok.

## Bulgular

| # | Ekran | Boyut | Sorun | Durum |
|---|-------|-------|-------|-------|
| 1 | Profil formu (Ateşli Tüfek), Mühimmat | 375, 393 (1.0x) | "Barut sıcaklık katsayısı" birim (%/15 °C) ve ⓘ yanında iki satıra sığmıyor, "…katsa…" diye kesiliyordu. Oswald: 2×53 / 111 pt (375), 2×62 / 111 (393). | **Düzeltildi**: etiket "Barut katsayısı" (tam ad ⓘ metninin başında). Inter ile 393'te sığıyor; 375 için #5. |
| 2 | Alt menü (her sekme) | 375, 393, büyük iOS yazısı | Alt menü yazısı 1.2x'e sınırlı; bu ölçekte "Hava Durumu" sekmeye sığmıyor: "Hava Duru…". | **Düzeltildi**: etiket gerekirse `FittedBox` ile biraz küçülür; varsayılan boyutta görünüm aynı. |
| 3 | Araçlar > Haritadan mesafe | 375, 393, 1.3x (Inter) | Esri kaynak satırı (flutter_map `SimpleAttributionWidget`) 393 pt'de 58 px **RenderFlex overflow**. | **Düzeltildi**: satır normal yazı boyutunda sabit (`withClampedTextScaling` 1.0); varsayılan boyutta görünüm aynı. |
| 4 | Vuruş Olasılığı sonuç kutusu; "Konum için mesafe" başlığı | 375, 393, 1.3x (Inter) | "%80 için maks. menzil" (152/171 pt) ve 375'te başlık (281/294 pt) "…" ile kesiliyor. | **Düzeltildi**: değer satırındaki `FittedBox` deseni etikete ve alt sayfa başlığına uygulandı; varsayılan boyutta görünüm aynı. |
| 5 | Profil formu, "Barut katsayısı" | 375 (1.0x, Inter) | Inter daha geniş: "katsayısı" tek başına 48 pt alana sığmıyor (48/90 pt). 393'te sığıyor. | **Açık, sahibinin kararı.** Her çözüm görünümü değiştirir ve simülatör 402 pt'de olduğu için önce/sonra görüntüsü çekilemez. Seçenekler: (a) sığmayan etiketi biraz küçültmek (genel, yalnız kesilen etiketlerde), (b) birimi "%" yapmak (açıklama ⓘ'de), (c) bu iki kutuyu tam satıra almak (iki kutu kuralına aykırı). Testte bilinen açık bulgu olarak listeli. |
| 6 | Profil formu alt çubuğu | Tüm boyutlar | "Kaydetmek için eksik: …" listesi 3 satırla sınırlı; yeni profilde liste uzun (Inter ile ~5 satır), sonu "…" ile kesiliyor. | **Değiştirilmedi** (bilerek 3 satır). Öneri: kesik kalırsa sona "+N alan" yazmak ya da yalnız bölüm adlarını saymak. |
| 7 | Kapalı seçim kutuları (ör. Tür: "Ateşli Tüfek") | 375, 393 | Kutudaki seçili yazı uygulama yazı tipinde değil, sistem yazı tipinde (DropdownButton temanın yazı ailesini almıyor); testte ölçülemiyor. 375'te alan 98 pt; "Ateşli Tüfek" sistem yazısıyla ~80 pt, sığıyor. | **Değiştirilmedi.** Yazı tipi tutarlılığı için sahibinin kararı. |

Başka sonuç yok: 4 boyutun hiçbirinde, 1.0x ve 1.3x yazıda başka RenderFlex
overflow ya da çizim hatası çıkmadı; her sayfanın ana kaydırma alanı sonuna
kadar kaydırılabildi.

### Yalnız test yazı tipinde (cihazda yok)

Varsayılan test yazı tipiyle çıkan, gerçek yazı tipiyle kaybolan uyarılar:
Haritadan mesafe kaynak satırının 1.0x'te 326–344 px taşması; alt sayfa
başlıkları ("Hız Doğrulama", "Hava & Rüzgâr", "Hesaplayıcılar", "Vuruş
Olasılığı", "Sight Height"); 1.0x alt menü "Hava Durumu"/"Araçlar"; Hava
Durumu etiketleri ("Rüzgâr hızı", "Rüzgâr yönü", "Yol ortası", "İstasyon
basıncı").

## Düzeltmeler (ayrı commit'ler)

1. `Profil: 'Barut katsayısı' etiketi küçük/normal iPhone'da kesilmez`
2. `Alt menü: büyük iOS yazısında 'Hava Durumu' kesilmez, hafifçe küçülür`
3. `Haritadan mesafe: büyük iOS yazısında kaynak satırı taşmaz`
4. `Büyük iOS yazısı: sonuç kutusu etiketi ve alt sayfa başlığı kesilmez, hafifçe küçülür`

Kurallar korundu: yazı tipine dokunulmadı, "Sight height" İngilizce, su
terazisine dokunulmadı, kutu altında yardım yazısı yok, etiketlerde parantez
yok, kalın yazı eklenmedi, iki kutu yan yana düzeni aynı. 2–4 yalnız büyük
iOS yazısında görünür; varsayılan boyuttaki ekran görüntüsünde fark yoktur.

## Tekrar çalıştırma

```
gh workflow run test-diag.yml --ref main -f branch=fix/ekran-boyutu -f files=test/ekran_boyutu_test.dart
```

Test bulguları `EKRAN_BULGU|…` / `EKRAN_KESIK|…` satırları ve sonda
`Which: <tür>|<ekran>|<metin>|<boyut alan/gereken>` özetiyle yazar.
