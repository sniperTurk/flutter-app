# Ekran boyutu denetimi (2026-10-11)

Dal: `fix/ekran-boyutu`. Amaç: taşan yazı, kesilen kutu, üst üste binen öğe,
kaydırılamayan alan ve RenderFlex overflow aramak.

## Nasıl ölçüldü

- `test/ekran_boyutu_test.dart` (Linux widget testi, Mac kuyruğu kullanılmadı).
  Her boyutta Profil, Hava Durumu, Pro, Hedef (Tek atış ve Tablo + DOPE),
  Araçlar sekmeleri, Araçlar'daki 8 aracın her biri ve Profil formu (yeni ve
  düzenle) açılır; her sayfa sonuna kadar kaydırılır.
- Boyutlar: küçük **iPhone SE 2/3 375x667**, normal **iPhone 15/16 393x852**,
  büyük **iPad 820x1180** ve **iPad Pro 13 1032x1376**. Telefonlarda yazı
  1.0x ve 1.3x (iOS büyük yazı) denendi.
- Golden yok. Yakalanan: her RenderFlex overflow / çizim hatası ve Oswald
  yazının `…` ile kesildiği her yer (`didExceedMaxLines`). Bunlar testi
  kırar; bilerek kesilen iki metin hariç (aşağıda).
- Testte gömülü Oswald yazı tipi yüklenir. Flutter'ın varsayılan test yazı
  tipi her harfi kare çizer (Oswald'dan ~2 kat geniş); onunla ilk taramada
  çıkan kesik başlıklar ve harita taşması cihazda olmayan yanlış alarmlardır
  (aşağıda "Yalnız test yazı tipinde" bölümü).
- Görsel kontrol: mevcut simülatör turu (iPhone 17 Pro, 402 pt) ekran
  görüntüleri incelendi; düzeltmelerden sonra sim-screens bir kez çalıştırıldı.

Uygulama yalnız iPhone için yayınlanıyor (`TARGETED_DEVICE_FAMILY = 1`); iPad
boyutları yine de denendi.

## Bulgular

| # | Ekran | Boyut | Sorun | Durum |
|---|-------|-------|-------|-------|
| 1 | Profil formu (Ateşli Tüfek), Mühimmat | 375, 393 (1.0x) | "Barut sıcaklık katsayısı" etiketi birim (%/15 °C) ve ⓘ ile aynı satırda iki satıra sığmıyor, "Barut sıcaklık katsa…" diye kesiliyor. Ölçüm: 2 x 53 pt alan / 111 pt metin (375), 2 x 62 / 111 (393). 402 pt'de sığıyor. | **Düzeltildi**: etiket "Barut katsayısı". Tam ad ⓘ metninin başında duruyor. İki kutu yan yana kaldı. |
| 2 | Alt menü (her sekme) | 375 ve 393, büyük iOS yazısı | Alt menü yazısı 1.2x'e sınırlı; bu ölçekte "Hava Durumu" 76 pt, sekme genişliği 71 pt (375) / 75 pt (393): "Hava Duru…". | **Düzeltildi**: etiket gerekirse `FittedBox` ile biraz küçülür. Varsayılan yazı boyutunda görünüm değişmez. |
| 3 | Profil formu alt çubuğu | Tüm boyutlar | "Kaydetmek için eksik: …" listesi 3 satırla sınırlı; yeni profilde liste uzun (Oswald ile 4–5 satır), sonu "…" ile kesiliyor (ör. Mühimmat alanları görünmüyor). | **Değiştirilmedi** (bilerek 3 satır). Öneri: kesik kalırsa sona "+N alan" yazmak ya da yalnız bölüm adlarını saymak. Sahibinin kararı. |
| 4 | Profil formu, kapalı seçim kutuları (ör. Tür: "Ateşli Tüfek") | 375, 393 | Kapalı seçim kutusundaki yazı Oswald değil, sistem yazı tipi (DropdownButton temanın yazı ailesini almıyor). Bu yüzden testte gerçek genişlik ölçülemiyor. 375'te metin alanı 98 pt; "Ateşli Tüfek" sistem yazısıyla ~80 pt, sığıyor. | **Değiştirilmedi.** Gözlem: "font Oswald kalır" kuralıyla tutarsızlık olabilir; değiştirmek tüm seçim kutularının görünümünü değiştirir, sahibinin onayı gerekir. |

Başka sonuç yok: 4 boyutun hiçbirinde, 1.0x ve 1.3x yazıda RenderFlex
overflow ya da çizim hatası çıkmadı; her sayfanın ana kaydırma alanı sonuna
kadar kaydırılabildi; iPad boyutlarında kesik ya da taşma yok.

### Yalnız test yazı tipinde (cihazda yok)

Varsayılan test yazı tipiyle çıkan, Oswald ile kaybolan uyarılar:

- Araçlar > Haritadan mesafe: Esri kaynak satırı (flutter_map
  `SimpleAttributionWidget`) 375/393 pt'de 326–344 px taşıyor görünüyordu.
  Oswald ile taşma yok.
- Alt sayfa başlıkları ("Hız Doğrulama", "Hava & Rüzgâr", "Konum için mesafe",
  "Hesaplayıcılar", "Vuruş Olasılığı", "Sight Height"), alt menü "Hava
  Durumu"/"Araçlar" (1.0x), Hava Durumu etiketleri ("Rüzgâr hızı", "Rüzgâr
  yönü", "Yol ortası", "İstasyon basıncı"), Vuruş Olasılığı etiketleri: Oswald
  ile hepsi sığıyor.

## Düzeltmeler (ayrı commit'ler)

1. `Profil: 'Barut katsayısı' etiketi küçük/normal iPhone'da kesilmez`
2. `Alt menü: büyük iOS yazısında 'Hava Durumu' kesilmez, hafifçe küçülür`

Kurallar korundu: Oswald, "Sight height" İngilizce, su terazisine dokunulmadı,
kutu altında yardım yazısı yok, etiketlerde parantez yok, kalın yazı
eklenmedi, iki kutu yan yana düzeni aynı.

## Tekrar çalıştırma

```
gh workflow run test-diag.yml --ref main -f branch=fix/ekran-boyutu -f files=test/ekran_boyutu_test.dart
```

Test bulguları `EKRAN_BULGU|…` / `EKRAN_KESIK|…` satırları ve sonda
`Which: <tür>|<ekran>|<metin>|<boyut alan/gereken>` özetiyle yazar.
