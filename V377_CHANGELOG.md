# V377 — dürbün elle girilir, PCP regülatör basıncı, profil verisi diğer sayfalarda kilitli

Kaynak: `main` @ `11ea70f`. Solver, `validation/*` ve üretim kapısı değişmedi.

## Sahip istekleri (2026-10-07)
- Profil sayfasında dürbün: marka, FFP/SFP, minimum büyütme, maksimum büyütme,
  mercek çapı ayrı ayrı alınır, tek satırda "6-24x56 FFP" gibi gösterilir.
  Sıfırlama mesafesi ve dürbün yüksekliği (sight height) aynı sayfada.
- FFP/SFP seçimi Atış'taki dürbün görselinde aynen kullanılır.
- PCP tüfekte regülatör basıncı sorulur.
- Profil'de alınan bilgiler diğer sayfalarda otomatik dolu açılır ve orada
  değiştirilemez (hesap zinciri bozulmasın).

## Üretim kodu
- Profil düzenleyici "Dürbün" bölümü: Dürbün markası*, Odak düzlemi
  (FFP/SFP)*, Minimum büyütme*, Maksimum büyütme* (min'den küçük olamaz),
  Mercek çapı (mm)*, Dürbün birimi (MRAD/MOA), Klik değeri* (varsayılan
  0,1 MRAD / 0,25 MOA), Dürbün yüksekliği. Altında tek satır gösterim.
  Katalogdan dürbün seçimi kaldırıldı; eski katalog dürbünü forma ön-dolar.
- Kayıt: tüfekle birlikte dürbün de kişisel kayıt olarak yazılır (`kind:
  scope`, `minMag`, `maxMag`, `focal`); profil ikisine bağlanır.
- Atış: dürbün görseli kişisel kayıttaki FFP/SFP ve büyütme aralığını kullanır
  (#12 görseli; mevcut büyütme Atış'ta aralık içinde seçilir).
- Tüfek formu: PCP için "Regülatör basıncı (bar)" zorunlu (10–500).
- Hava Durumu > Atış girdileri (çıkış hızı, ağırlık, sıfır, dürbün yüksekliği)
  profilden dolu gelir ve kilitlidir; değişiklik Profil'den yapılır.
- Aktif profil özeti: regülatör, büyütme, odak düzlemi.

## Testler
- Form yardımcıları: `fillScopeForm`, regülatör alanı.
- Kabuk: dürbün girilmeden kaydedilemez; tek satır gösterim; kayıtlar tüm
  değerlerle oluşur; Hava Durumu'nda profil alanları kilitli.
- Fail-closed: katalog dürbünü ön-dolar; regülatör zorunlu; max < min reddi.
- Python sözleşmesi v368 güncellendi.
