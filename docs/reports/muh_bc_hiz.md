# Mühimmat: BC modeli, FA007 hızı, eski "ga" kaydı (MUH-1, MUH-2, MUH-3, MUH-5)

Sahibin kararı: 15.10.2026 20:47 (İstanbul), "düzeltmek için görev aç". Bulgular `docs/reports/denetim_testflight_2026_10_14b.md` raporundan.

## Ne yapıldı

### MUH-1: Listeden seçilen fabrika fişeğinde G1↔G7 değişimi
- **Önce:** Winchester 6.5 CM X651 seçilince BC 0,324 (G1) dolar. BC modeli G7 yapılınca 0,324 kutuda kalıyor, G7 olarak kaydediliyordu. Uyarı da çıkmıyordu.
- **Şimdi:** Listeden seçilmiş, üretici BC'si olan bir fabrika fişeğinde BC modeli değişince:
  - Yeni model üreticinin modeliyse üreticinin BC'si yazılır.
  - G7 seçildiyse ve kayıtta üreticinin G7 BC'si varsa (`FactoryAmmo.bcG7`) o yazılır.
  - Öbür durumlarda BC kutusu boşaltılır; kullanıcı kendisi girer.
  - Öbür eğrinin sayısı hiç kalmaz.
- **Örnekler:** X651 → G7: kutu boş; G1'e dönünce 0,324. Lapua 69 gr Scenar (.223) → G7: 0,171; G1'e dönünce 0,341.
- **Nasıl:** `profile_editor_ammo.dart` içinde BC modeli `onChanged` artık `_factoryBcForModel()` çağırıyor. Model gerçekten değiştiyse çalışır. Yalnız Ateşli Tüfek + Fabrika fişeği + listeden seçilmiş fişek için.

### MUH-2: FA007 namlu hızı
- Aguila 22 LR Standard Velocity Lead Solid Point: 1095 fps → **1130 fps**.
- 1095 fps 22 Short'un hızıydı. 40 gr ağırlığın alındığı üretici sayfası 1130 fps diyor.
- Kaynak: https://www.aguilaammo.com/products/22-super-extra-long-rifle-standard-velocity-lead-solid-point (okuma 14.10.2026, "0 yd: 1130 / 100 yd: 981 fps"; depoda `data/bc_gelistirme/bc_less_mapping.csv`).
- Kaynak, satırın üstüne yorum olarak ve satırın notuna yazıldı.

### MUH-3: Eski kayıtta bilinmeyen BC modeli
- **Önce:** kayıtta bilinmeyen bir model yazısı (ör. 12.10.2026'da kaldırılan "ga") BC'yi sessizce düşürüyordu. PCP'de tahmini G1 BC kullanılıyordu.
- **Şimdi:** bilinmeyen model yazısı yüklenirken G1 kabul edilir; kayıtlı BC sayısı aynen kalır. Kayıtlı veri değiştirilmez.
- Yer: `lib/data/user_catalog.dart`.

### MUH-5: BC'siz fabrika fişeğinde BC ⓘ metni
- Kural aynı kaldı: BC yazılınca model kendiliğinden G1 olur (sahip kuralı 13.10.2026).
- Yalnız ⓘ metni değişti: "Bu fişek: Üretici BC yayımlamıyor. Kendi atışlarınızdan bulduğunuz BC'yi girin. BC yazınca BC modeli kendiliğinden G1 olur; üretici BC'yi G7 olarak veriyorsa BC modelini G7 yapın."
- Metin `ProfileFieldInfo.bcFactoryNoBc` içinde.

## Uç durumlar
- Elle girilen (Listede yok) fişekte, El dolumu mermide ve PCP'de davranış değişmedi.
- "Özel eğri"ye geçip G1'e dönmek BC'yi değiştirmez (model aynı kaldı).
- Kayıtlı profil açılınca BC olduğu gibi gelir; yalnız kullanıcı modeli değiştirirse yeni kural çalışır.
- Üreticinin yalnız G7 verdiği fişekte (ör. Lapua Scenar-L) G1 seçilince kutu boşalır.
- Kayıtta model hiç yoksa (boş) BC eskisi gibi bağlanmaz; yalnız dolu ama bilinmeyen model G1 olur.

## Bilerek yapılmayanlar
- El dolumu mermi listesindeki (bullet library) mermilerde G1↔G7 değişimi: görev fabrika fişeğini istedi.
- MUH-4 (FA056 2750/2760 fps): görevde yok.
- Uygulama metinleri ve hesap dışında başka değişiklik yok.

## Testler
- `test/audit_2026_10_14b/ammo_bc_audit_test.dart`:
  - MUH-1, MUH-2, MUH-3 testlerinin `skip`'i kaldırıldı.
  - MUH-1'e: X651 G7'de kutu boş, G1'e dönünce 0,324. Yeni: Lapua G7 0,171 / G1 0,341.
  - Yeni: "ga" kayıtlı eski profil BC'siyle G1 olarak yüklenir.
  - MUH-5 testi sahibin kararına göre yeniden yazıldı: ⓘ "kendiliğinden G1" ve "G7" diyor, BC yazınca model G1.
  - X651 koruma testi değişmedi.
- `test/audit_2026_10_14/formulas_audit_test.dart`: "#195 eski GA kaydı BC'sini kaybeder" testi eski davranışı koruyordu; sahibin kararına göre "BC'sini G1 olarak korur" yapıldı.
- `test/fisek_bc_yok_notu_test.dart`: beklenen ⓘ metni yeni metne bağlandı.
- `tools/test_denetim_2026_10_14b_muh.py`: FA007 hızı beklentisi 1130 fps.

## Doğrulama
- Yerel: `python3 tools/offline_dart_lint.py` geçti (387 dosya, 0 sorun). `python3 -m unittest discover -s tools -p 'test_*.py'` geçti (842 test).
- Yerelde Flutter kurulamadı (Dart SDK indirmesi ağ politikasında 403). Flutter testleri yalnız CI'da çalıştı.
- CI: aşağıda.

## CI
Bu rapor commit'iyle birlikte son commit'te çalışan iş sonuçları ve bağlantıları PR açıklamasındadır (rapor dosyası CI'dan önce yazıldı).

---
🤖 Generated with [Claude Code](https://claude.com/claude-code)

https://claude.ai/code/session_01Sk7upeHxSsYw2Z9gQcgx9m
