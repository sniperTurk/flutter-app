# V375 — tüfek bilgileri kullanıcı tarafından girilir; Profil'de "Menzil" yok

Kaynak: `main` @ `d63559c`. Solver, `validation/*` ve üretim kapısı değişmedi.
Katalogdaki tüfek kayıtları silinmedi (eski profiller ve Katalog ekranı için
duruyor) ama profil düzenleyicisi artık tüfek seçtirmiyor.

## Neden
Sahip kararı (2026-10-07): katalogdaki tüfek ve mühimmat verilerinin çoğu
hatalı; bu veriler kullanıcı tarafından elle girilecek. İlk adım tüfek.

## Üretim kodu
- Profil düzenleyicisinde "Tüfek" bölümü: Marka*, Model*, Kalibre (mm)*,
  Namlu uzunluğu (mm)*, Namlu yiv yönü (Sağ/Sol)*, Yiv oranı (1:N inç)*.
  Hepsi zorunlu; aralık dışı değerler alan altında hata gösterir ve kaydı
  engeller (kalibre 2–20 mm, namlu 50–1500 mm, yiv 3–80 inç).
- Kaydet: önce profil değerleri doğrulanır, sonra tüfek kişisel kayıt olarak
  (`ManualCatalogStore`, `kind: rifle`) yazılır ve profil ona bağlanır. Mevcut
  kişisel tüfek yerinde güncellenir; eski katalog tüfeği olan profil
  düzenlenince değerler forma ön-doldurulur ve kaydedilince kişisel kayda
  dönüşür. Yazma başarısızsa profil kaydedilmez.
- Mühimmat listesi girilen kalibre ve platforma göre süzülür (henüz katalog;
  mühimmat alanları ayrıca gelecek).
- `Rifle`: `twistDirection`, `twistRateIn`. Kişisel kayıt eşlemesi ve
  `ManualCatalogStore` doğrulaması (yiv yönü right/left, yiv oranı pozitif).
  Katalog ekranında kayıt düzenlenince yiv bilgisi korunur.
- Aktif profil özeti yiv yönü ve oranını gösterir.
- Profil sekmesinde üst çubuktaki "Menzil" markası gizlenir (diğer sekmelerde
  durur).
- Yiv bilgisi şimdilik yalnız bilgi amaçlıdır; nokta-kütle çözücü spin
  sapmasını modellemez.

## Testler
- `test/support/rifle_form.dart` (form doldurma yardımcısı).
- Kabuk: Profil'de "Menzil" yok, Atış'ta var; yeni profil tüfek girilmeden
  kaydedilemez, girilince kişisel kayıt tüm değerlerle oluşur.
- Fail-closed: eski katalog tüfeği ön-doldurulur, yiv girilmeden Güncelle
  kapalı; aralık dışı değerler hata verir.
- Python sözleşmeleri (v299, v368) yeni davranışa göre güncellendi.
