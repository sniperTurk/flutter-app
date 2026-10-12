# NATO standart mermi BC'si — MKE ve askerî fişekler (2026-10-12)

Sahibinin kararı (2026-10-12 07:25): "MKE çok büyük olasılıkla NATO standartlarında mermi
üretiyor. NATO verilerini kullan; ⓘ alanında veriyi nasıl eklediğimizi açıkla; kullanıcı
isterse değiştirsin."

`nato_bc.json`: `data/mke/ammo.json` (18) ve `data/ammo-military/military.json` (8) içinde
BC'si boş **26 kaydın tamamı**, her biri için eşleme kararıyla.

| Alan | Anlamı |
|---|---|
| `dataset`, `record` | Kaynak dosya (`mke` → `product`, `ammo-military` → `designation`). |
| `nato_standard` | Karşılık gelen NATO standart mermisi; yoksa `null`. |
| `match` | `kesin`: MKE/üretici sayfası M-kodunu ya da STANAG'ı adıyla veriyor. `muhtemel`: ad vermiyor ama ağırlık + tip birebir. `yok`: karşılık yok. |
| `match_reason` | Gerekçe. |
| `bc`, `bc_model` | Resmî rapordan alınan/hesaplanan BC ve G7/G1. |
| `bc_source` | `nato-standard` (uygulamadaki işaret). |
| `bc_method` | Değerin rapordan nasıl çıkarıldığı (hesap adımlarıyla). |
| `source_title`, `source_url`, `source_page` | Resmî rapor adı/numarası, adresi, tablo/sayfa. |
| `license`, `license_note` | Kullanım koşulu (ABD hükümeti yayını: kamu malı, açık dağıtım). |
| `status` | `uygulandı`, `kaynak-okunamadı` (eşleşme var, rapor bu çalışmada açılamadı) veya `eşlenemez`. |

Kaynak kuralı: yalnız resmî, kamuya açık raporlar (ARL/BRL — DTIC, NATO açık yayınları, devlet
balistik raporları). Forum, blog, bayi, ChairGun/Strelok/Applied Ballistics/JBM/QuickLOAD/GRT
kullanılmadı.

## Sonuç

- **Uygulandı (1):** ABD Ordusu M855 → G7 0,154, ARL-TR-5182 Tablo 8'den hesaplandı
  (`bc_method`). Ölçüm kaydı main'de: `data/drag-curves/measured/arl-tr-5182-m855.json`.
- **Eşleşme kesin, rapor okunamadı (11):** MKE M193, MKE M118, MKE 12.7×99 M8 / M17 / M33 /
  M2 AP / M8 Keskin Nişancı / M20, askerî listedeki MKE M118 ve M193 kopyaları, Barrett M33.
  `apps.dtic.mil` bu çalışmada erişilemedi (bash: vekil sunucu CONNECT 403; WebFetch: 429).
  BC uydurulmadı, boş kaldı; aday raporlar `candidate_sources` alanında.
- **Eşlenemez (14):** 5.56 polimer uçlu, 7.62×51 Subsonic, 7.62×54R (2), 7.62×39, 8.59×70 (4),
  12.7×99 Solid Keskin Nişancı, M855A1, M80A1, Mk 316, Mk 262 — nedenler kayıtlarda.
- `muhtemel` eşleşme yok: ağırlık + tipe dayalı ama adı verilmeyen bir kayıt kalmadı; adı
  verilmeyen kayıtların (polimer uç, subsonic, solid) NATO karşılığı yok.

MKE'nin kendi G1 BC'sini yayımladığı kayıtlar (SS109, L110, M80, M61, M62) bu dosyada yok;
onların değeri değişmez.
