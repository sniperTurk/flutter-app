# M2 – Menzil tasarım sayfalarının Flutter'a uygulanması (V362 tabanı: V361 + M1 Rev2)

Referans: `menzil_sayfa_tasarimlari(3).zip` (yalnızca referans). Çözücü, `validation/acceptance.json`
(SHA 1d861282…7c67927d), click yasağı, V352/V353 Atış/Tablo KİLİTLİ davranışı ve production G1/G7 kapısı DEĞİŞMEDİ.

## Değişenler
- **Sight Height**: iki bağımsız yöntem. (1) Fiziksel ölçüm: namlu iç yarıçapı + namlu üst cidar + ÖN uçtaki
  dürbün–namlu boşluğu + objektif DIŞ yarıçapı (3,18+5,80+21,40+32,00 = 62,38 → 62,4 mm). (2) Fotoğraf: "Fotoğraf çek"
  ve "Galeriden seç"; yatay yan fotoğraf; objektif ön üst kenar, ön alt kenar, namlu ağzı merkezi. İki yöntem birbirinin
  ön koşulu değildir. Moderatör/susturucu uyarısı, ince ayar okları, VoiceOver metinleri, profile uygulamadan önce
  eski → yeni önizleme ve onay korundu. Qwen Vision yalnızca bu sayfada, isteğe bağlı ve bağlı değil.
- **İşaretleme sayfası**: tasarımdaki 3 çip, dokun/sürükle yerleştirme, ince ayar (Wrap), Sıfırla / Hesapla.
- **Su Terazisi**: daire + X yatay tüp + Y dikey tüp aynı anda; sıvı alanları tamamen yeşil (`levelLiquid`),
  0,01° gösterim çözünürlüğü, "Referansı bu konuma ayarla" + "Temizle".
- **Galeri güvenliği**: `image_picker` yalnızca `lib/tools/adapters/image_picker_photo_picker.dart` içinde,
  tek fotoğraf, `requestFullMetadata: false`, bellek içi, geçici kopya silinir. Info.plist'e Türkçe
  `NSPhotoLibraryUsageDescription` eklendi; `NSPhotoLibraryAddUsageDescription` (yazma) yasak kalmaya devam eder.
- Ekipman çizimleri tasarım SVG'lerinden Dart'a çevrildi (`sight_height_art.dart`, `MenzilArt` paleti).
- Araç sayfalarında ölçülen değerler Türkçe ondalık virgülle gösterilir (Atış/Tablo/Ortam/Profil nokta biçimini korur).
- Hava & Rüzgâr: ayraç tasarıma uyduruldu ("·"); durum/kaynak metinleri zaten tasarımla uyumluydu.

## Sözleşme testlerinde yapılan (gerekçeli) değişiklikler
`image_picker` ve foto-kütüphanesi yasakları, yalnızca Sight Height galeri seçimi için daraltılarak gevşetildi
(v271, v274, dual-lineage, M1 kapsam testleri); yeni `test_m2_design_contract.py` sınırı kod düzeyinde sabitler.

## Bilinçli sapmalar / doğrulanamayanlar
- Tasarım notundaki "iPhone yönü gerçek kuzeydir" iddiası uygulanmadı (gerçek/manyetik kuzey iddia edilmez).
- `pubspec.lock` image_picker sonrası yeniden üretilmeli (yalnızca pinned Flutter 3.47.2 Actions'ta).
- Su Terazisi kabarcık yön işareti, EXIF yönü, kamera/galeri davranışı, 390 pt görünümü fiziksel iPhone olmadan DOĞRULANMADI.
