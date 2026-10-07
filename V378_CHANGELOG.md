# V378 — mühimmat elle girilir (BC + G1/G7); rüzgâr sapması hesaplanır

Kaynak: `main` @ `ef007b3`. Solver, `validation/*` ve üretim kapısı değişmedi.

## Sorun
Rüzgâr "KİLİTLİ" görünüyordu: katalogdaki hiçbir mühimmatta BC yok, bu yüzden
Atış her zaman vakum temel hesaba düşüyordu. Vakum modelinde hava direnci
olmadığı için rüzgâr sapması fiziksel olarak hesaplanamaz.

## Çözüm
- Profil düzenleyicide "Mühimmat" bölümü (tüfek ve dürbün gibi elle):
  Marka*, Model*, Tip* (PCP: Diabolo/Slug; ateşli: mermi), Ağırlık
  (grain)*, BC* (0,005–1,5), BC modeli* (G1/G7). Kalibre tüfekten alınır.
  Katalogdan mühimmat seçimi kaldırıldı; eski kayıt forma ön-dolar.
- Kişisel standart mühimmat artık G1/G7 modeliyle BC taşır
  (`UserCatalog`), böylece Atış doğrulanmış sürüklenme çözücüsünü kullanır
  ve rüzgâr açısını hesaplar (rüzgâr kabul kümesi CI'da çalışıyor).
- Atış > Rüzgâr kartı: "Sapma X cm" (emperyalde in) + klik.
- DOPE tablosu (sürüklenme modu): "Rüzgâr sapması cm/in" sütunu.
  Sapma = menzil × tan(rüzgâr açısı); açı çözücünün yanal konumundan gelir.

## Testler
- Drag: 4 m/s yan rüzgârda sapma sütunu, açı×menzil ile tutarlı ve
  menzille artıyor.
- Form yardımcısı `fillAmmoForm`; kabuk, fail-closed, kişisel katalog ve
  entegrasyon testleri güncellendi. Python sözleşmeleri v299, v368, v371.
