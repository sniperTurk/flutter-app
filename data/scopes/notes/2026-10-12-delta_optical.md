# Delta Optical — tüfek dürbünleri (2026-10-12, 2. tur)

**Yeni kayıt: 8**
- Stryker HD 4.5-30x56 FFP
- Stryker HD 5-50x56 SFP
- Stryker HD 1-6x24
- Javelin 4.5-30x56 FFP
- Hornet 1-6x24 SFP
- Titanium 4-24x50 HD SFP
- Titanium HD 2.5-15x50
- Titanium HD 2.5-15x56 SF

## Erişim
- **deltaoptical.pl hâlâ açılmıyor.** Aşağıdaki adreslerin hepsi CLIENT_ERROR verdi:
  - https://deltaoptical.pl/en/
  - https://deltaoptical.pl/luneta-celownicza-delta-stryker-hd-4-5-30x56-ffp-dlr-1 (Lehçe yol, /en/ olmadan)
  - https://deltaoptical.pl/en/delta-javelin-4-5-30x56-ffp-smr-1
- https://w.deltaoptical.pl/... adresi **ROBOTS_DISALLOWED** verdi. Bu bir izin engeli olduğu için atlatılmaya çalışılmadı.
- https://deltaoptical.eu/en/ ve https://www.deltaoptical.eu/en/ adresleri http'ye 302 ile yönleniyor.
- **http://deltaoptical.eu/en/... doğrudan verilince açıldı.** Bütün veriler buradan alındı.
- **Uyarı:** deltaoptical.eu eski bir ihracat kataloğu gibi görünüyor. Fiyatlar zł0.00 veya zł100,000 gibi yer tutucu değerler. Listede Classic 3-9x40 ve Titanium 1.5-9x45 gibi eski modeller de var. Ürünlerin güncel olup olmadığı doğrulanamadı. Ürün sayfaları "In stock" diyor ve hiçbirinde "discontinued" yazmıyor.

## Eksikler ve çelişkiler
- **Stryker HD 5-50x56:** "One click 0.05 MIL" yazıyor, fakat aralık "100 / 50 MOA" olarak verilmiş. Bu çelişki yüzünden aralık null. Sayfada DLS-3 (MOA) retikülü de listeleniyor, ama MOA taretli sürüm ayrıca tanımlı değil; kayıt açılmadı.
- **Stryker HD 1-6x24 ve Hornet:** Sayfada tek bir aralık değeri var (80 MOA / 44 MRAD). Bu değer hem elevation hem windage alanına yazıldı.
- **Titanium 4-24x50:** Ağırlık sayfada yok.
- **Javelin:** Sayfa başlığı ve metadata yanlışlıkla "Titanium 3-24x56ED CCT" diyor. Spec değerleri Javelin ürün bloğundan alındı.
- **ZeroLock:** Yalnız Javelin'de sayfa zero-stop özelliğini anlatıyor, bu yüzden orada true. Stryker HD'lerde null.
- **Çekilmeyenler (bütçe):**
  - Titanium HD 2.5-10x56
  - Titanium HD 2.5-10x56 Di
  - Titanium HD 2.5-10x50
  - Titanium HD 1-6x24
  - Titanium 3-24x56ED CCT/OLT
  - Titanium 1.5-9x45
  - Titanium 4.5-14x44 FFP HFT
  - Titanium 4.5-30x50
  - Titanium 4-16x42 AO
  - Titanium 6-24x42 AO
  - Classic 3-9x40
  - Classic 3-12x56
- **Hariç tutulan:** HORNET Ultra Compact Magnifier 3x (magnifier).

## Kaynak URL'ler
- Listeler:
  - http://deltaoptical.eu/en/hunting/riflescopes.html
  - http://deltaoptical.eu/en/hunting/riflescopes905b.html?p=2 (22 ürünün tamamı listelendi)
- Ürün sayfaları: her kaydın source_url alanında (deltaoptical.eu).
- Üretici URL'lerini bulmak için WebSearch kullanıldı. Arama sonucundan değer alınmadı.
