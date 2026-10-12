# Vector Optics — retikül raporu (okundu 2026-10-12)

Kapsam (görev): birim-farki kayıtları (German #4, G4 Fiber, Fiber Center Dot) + retikül adı boş 2 dürbün.
Kaynak: yalnız www.vectoroptics.com.

## Eklenen retikül kaydı
Yok. Hiçbir birim-farki retikülü için üretici MRAD/MIL tanımlı bir retikül vermiyor (aşağıda).

## Doldurulan retikül adları (scope_changes.json)
| Dürbün | Yeni ad | Eşleşen mevcut kayıt | Kanıt |
|---|---|---|---|
| Veyron Plus 10x30 Zero (SCOM-46) | MPR-V10 | vector-optics-mpr-v10-mil (kayıt zaten SCOM-46'yı listeliyor) | Ürün sayfası: "MPR-V10 Subtension 0.18 MIL center dot"; indirme: "MPR-V10 SFP Reticle User Manual" |
| Continental 1-10x24i ED Fiber (SCOC-47) | VCO-7 MIL | vector-optics-vco-7-mil (kayıt zaten SCOC-47 sayfasından) | Ürün sayfası: "VCO-7MIL Fiber Center Dot Design" |
Her iki ad, repo eşleştiricisinin (tools/reticle_match_audit.py, MRAD taret) kopyasında doğru kayda eşleşti.

## Birim-farki kararları — KARAR VERİLEMEDİ (MRAD kaydı eklenmedi)
Tüm ilgili dürbünler SFP ve taretleri MIL (1/10 veya 1/5 MIL); mevcut kayıtlar MOA.

1. **G4 Fiber / G4, Fiber / German #4, Fiber / German #4 Fiber Center Dot** (Grizzly SCOM-53, SCOM-49, SCOM-48, SCOL-67, SCOC-50; Veyron GenII SCOL-73)
   - SCOM-49 ve SCOC-50 sayfalarındaki "German #4 Fiber Reticle Single Page" PDF'si (…/20250208/c4d8be0a….pdf) başlığı **"German #4 fIBER MOA SFP RETICLE"**, **"Setting: MOA"**. Aynı belgenin daha yeni sürümü (…/20250514/f645ad93….pdf): "German #4 fIBER MOA SFP RETICLE FOR CONTINENTAL & GRIZZLY", "Setting: MOA".
   - Belgede MOA tablosunun yanında "MIL" ve "CM/100M" tabloları da var (MOA değerlerinin çevrimi; ör. 0.9 MOA ↔ 0.26 MIL). Sütunlar (A–D) ve büyütme satırları tanımlı değil.
   - SCOM-53 ve SCOM-48 sayfalarının retikül indirmesi "German #4 & VECNS-G4F (MOA)" (…/20241218/1a771397….pdf).
   - Sonuç: üretici retikülü MOA retikülü olarak tanımlıyor; ayrı bir MIL retikül sürümü yok. Yalnız çevrim tablosu var. MRAD kaydı eklenmedi → sahibin kararı: MIL taretli bu dürbünlerin MOA retikül kaydına bağlanması (birim kuralı istisnası) mı, yoksa eşleşmesiz kalması mı.
   - Veyron SCOL-73 kullanım kılavuzu (…/20261010/b6a1d75d….pdf) 2 denemede de okunamadı (WebFetch CLIENT_ERROR).
2. **Fiber Center Dot Reticle** (Forester SCOC-55, SCOC-54; 1/5 MIL)
   - Ürün sayfaları ölçü/birim vermiyor ("Fiber-optic center dot with 6 brightness levels"); SCOC-54/55 ve genel Forester kılavuzlarında retikül bölümü yok (yalnız dış bağlantı/QR). Reticle-Collection'da bu ad yok. → karar verilemedi.
3. **German #4** (Paragon 3-15x44 1in Zero-Stop, SCOM-T37; 1/10 MIL)
   - Retikül belgesi "German #4 & VPA-2 (MIL) & VEPG-TMIL (MIL)" (…/20231030/69dcde77….pdf): "(MIL)" etiketi yalnız VPA-2 ve VEPG-TMIL'de, German #4'te birim yok; metin içeriği yalnız adlar. → karar verilemedi.
   - Dikkat: aynı sayfanın Retikül bölümü "VEPG-T MIL"e bağlanıyor, spec tablosu "German #4" diyor. Sayfa içi tutarsızlık; dürbün düzeltmesi önerilmedi (üretici açıkça tek bir ad söylemiyor).

## Okunamayan URL'ler
- https://www.vectoroptics.com/public/uploads/files/20261010/b6a1d75d1b0c2a420ee7930d2b5ad3e3.pdf — WebFetch CLIENT_ERROR (2 deneme).
- Grizzly genel kılavuzu (…/20250314/11ce009f….pdf) okundu ama yalnız garanti metni çıktı; Forester genel kılavuzu (…/20231024/8f374578….pdf) yalnız tek satır metin verdi.
