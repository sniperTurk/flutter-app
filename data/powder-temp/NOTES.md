# Barut sıcaklık hassasiyeti — veri notları (2026-10-10, otomatik çalışma)

## Sonuç
- **Hiçbir üretici sayfasında sayısal katsayı veya sıcaklık–hız tablosu bulunamadı.**
  Okunan tüm sayfalar yalnızca nitel ifade içeriyor ("temperature insensitive" vb.).
  Bu yüzden tüm `coef_percent_per_15c` ve `points` alanları `null`.
- Uygulama birimi: `lib/core/powder_temperature.dart` → k = %/15 °C (Strelok).
  Çevrilecek sayısal değer olmadığı için dönüşüm yapılmadı; ham ifade `raw` alanında.
- Dönüşüm formülü (ileride sayı bulunursa):
  k = (v2 − v1) / v_ref / (T2 − T1 [°C]) × 15 × 100.
  fps/°F verilirse: k = (fps/°F) × 1.8 × 15 / v_ref[fps] × 100.

## Kararlar
- Vihtavuori N570: sayfa −20 °C altında ağır yüklerde kullanımı önermiyor; bu bir
  hız aralığı değil, kullanım alt sınırı olduğu için `temp_range_c` = null bırakıldı
  (bilgi `raw` içinde).
- Hornady Superformance: −20 °F…+140 °F test aralığı → [-29, 60] °C (yuvarlatıldı).
- `factory_ammo.json` kayıtlarına şemada olmayan `raw` ve `temp_range_c` alanları
  eklendi (ham değeri saklama isteği gereği).
- Lapua Polar Biathlon ("dondurucu koşullar için tasarlandı") hassasiyet ifadesi
  olmadığından alınmadı. Lapua 2018 haber yazısı ürün sayfasının tekrarı olduğu için alınmadı.
- Ürün sayfası alıntıları WebFetch özetleyicisi üzerinden okundu; kelimesi kelimesine
  doğruluk için sayfadan bir kez kontrol edilmesi önerilir.
- Forum, mağaza yorumu (ör. H4895 sayfasındaki müşteri yorumları) ve uygulama verisi alınmadı.

## Okunamayan kaynaklar (WebFetch HTTP 429 hız sınırı / izin zaman aşımı)
Sayısal veri bulma olasılığı en yüksek olanlar — yeniden denenmeli:
- https://www.reload-swiss.com/Reload%20Swiss/Produkte/RS62/RS62-EN.pdf (ve diğer RSxx PDF'leri)
- https://explosia.cz/wp-content/uploads/2025/07/Explosia_kat-Propellants-2023_en.pdf (Lovex)
- https://www.alliantpowder.com/downloads/RL16_Initial_Loads.pdf
- https://www.alliantpowder.com/products/powder/reloder16.aspx
- https://www.reloadswiss.com/
- https://vihtavuori.com/powder/vihtavuori-n565-rifle-powder/ , .../n555-rifle-powder/
- https://shop.hodgdon.com/imr-enduron-4451/ , https://shop.hodgdon.com/hodgdon-h1000/
- https://hodgdonpowderco.com/hodgdon/ (Extreme seri); ns.hodgdon.com robots.txt ile engelli
- https://www.hornady.com/ammunition/rifle/6.5-creedmoor-140-gr-eld-match

## Hiç ulaşılamayan/aranamayan
Alliant (tüm ürünler), Ramshot/Accurate (westernpowders.com), Nobel Sport/Vectan,
Somchem/PMP, MKE, Norma barut ürün sayfaları (203-B, 204, MRP, 217), Sako/Norma/RWS/
Geco/S&B fişek ürün sayfaları, Hornady/Federal katalog PDF'leri.
Okunup sıcaklık bilgisi olmayanlar: Norma URP ve barut genel sayfası, Lapua 2022/2023/2025
katalogları, Sako TRG Precision, Federal Gold Medal Berger/CenterStrike, Federal Terminal Ascent,
Norma soğuk hava Academy yazısı (test anlatılıyor ama hız sonuçları yok).
