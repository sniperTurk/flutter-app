# Ö2 Gözlemle rüzgâr seçimi ve bölge payları — tasarım ve plan

> Kaynak: `docs/yeni-hesaplar-2026-10-11.md` (PR #153), öneri Ö2.
> Yürütme: tek oturum (native), TDD; sahibi yokken varsayımlar aşağıda.

## Tasarım (sınırlı değişiklik)

1. **Rüzgâr gözlemi** — Hava Durumu > Rüzgâr kartında, Rüzgâr hızı | Rüzgâr
   yönü satırının ÜSTÜNDE tam satır `MenzilSelect<int>` (`hint: 'Seçiniz'`,
   ⓘ zorunlu). Öğeler kara üzerindeki Beaufort 0–7 tanımları (Türkçe).
   Kapalı kutuda kısa ad (`selectedLabels`). Seçilince:
   - Rüzgâr hızı ← sınıfın orta değeri (birim m/s ya da mph, 1 ondalık),
   - En yüksek rüzgâr ← sınıfın üst sınırı; `_windMaxAuto = false`
     (seçilen değer kullanıcı değeri sayılır, kaydedilir).
   - Kullanıcı Rüzgâr hızını elle yazarsa liste "Seçiniz"e döner.
   Rüzgâr düzeltmesi kutusunun düzeni (kutu, açıklama, iki bölge kutusu,
   açıklama) DEĞİŞMEZ.
2. **Yükseklik** — Beaufort hızları 10 m yükseklik içindir (WMO-No. 8).
   Atıcı yüksekliğine düzeltme katsayısı UYGULANMAZ: logaritmik profilin
   katsayısı arazinin pürüzlülüğüne bağlı ve atıcı bunu bilemez; tek bir
   sabit katsayıyı gerekçelendiren resmi kaynak yok. Sadece ⓘ'de uyarılır.
3. **Bölge payları** — `lib/core/wind_zone_shares.dart`:
   `WindZoneShares.compute(BallisticInput base, double rangeM)` →
   `WindZoneShares?` (`nearPct`, `midPct`, `farPct`; tamsayı, toplam 100).
   Her bölgeye ayrı 1 m/s tam yan rüzgâr (diğerleri 0), mevcut çözücü
   (`BallisticEngine`) ve `WindZones`; Coriolis ve cant yok (yalnız rüzgâr,
   `ReticleHolds.crosswindForMil` ile aynı). Toplam sapma ≈ 0 ise `null`.
   Hedef > Tek atış notlarında tek satır:
   `Rüzgâr etkisi: yakın %45 · orta %37 · uzak %18` (anahtar
   `shot-wind-zone-shares`). Yalnız sürüklenme modunda.

## Varsayımlar (sahibi onay veremedi)

- Liste 0–7 (Sakin … Fırtınamsı); 8+ atış için anlamsız.
- Sakin sınıfı orta değeri 0,1 m/s, üst 0,2 m/s (WMO 0–0,2).
- Orta değer = (alt + üst) / 2, 1 ondalığa yuvarlanır.
- Seçimin kendisi kaydedilmez; yazdığı Rüzgâr hızı / En yüksek rüzgâr kaydedilir.

## Görevler

1. `lib/core/beaufort.dart` + `test/beaufort_test.dart`: sınıf sınırları,
   orta değerler (0,1/0,9/2,5/4,4/6,7/9,4/12,3/15,5), sıralı ve bitişik.
2. `lib/core/wind_zone_shares.dart` + `test/wind_zone_shares_test.dart`:
   T1 (.308, 175 gr, G7 0,243, 790 m/s, 45 mm, sıfır 100 m) 800 m'de
   %45/%37/%18 (±2); toplam 100; yakın > orta > uzak; boşsa null.
3. UI + `test/wind_observation_ui_test.dart`: liste ⓘ'li, "Seçiniz";
   seçince iki kutu dolar; Hedef satırı görünür.
4. Doğrulama: offline lint, Python, test-diag, analyze-diag, format,
   sim-screens (en fazla 1 kez).

## İnceleme odağı

- mph biriminde seçim → değerler mph'ye çevrilmeli.
- Seçimden sonra elle yazılan rüzgâr korunmalı (canlı hava verisi ezmemeli).
- Sıfır mesafesine çok yakın atışta payların bölünmesi (toplam ~0 → null).
- PCP (düşük hız) için de paylar hesaplanmalı.
